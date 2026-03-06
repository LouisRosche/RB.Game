--[[
	Main.server.luau
	Single server entry point for Potion Lab.
	Creates all RemoteEvents, initialises services, and routes incoming
	client requests to the appropriate service handlers.
]]

---------------------------------------------------------------------------
-- Services
---------------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------------
-- Shared modules (ReplicatedStorage.Shared)
---------------------------------------------------------------------------
local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Network     = require(Shared.Network)
local Ingredients = require(Shared.Ingredients)

---------------------------------------------------------------------------
-- Server service modules (ServerScriptService.Server.Services)
---------------------------------------------------------------------------
local Services          = script.Parent.Services
local DataService       = require(Services.DataService)
local PlotService       = require(Services.PlotService)
local GrowthService     = require(Services.GrowthService)
local BrewingService    = require(Services.BrewingService)
local EconomyService    = require(Services.EconomyService)
local DiscoveryService  = require(Services.DiscoveryService)
local AnalyticsService  = require(Services.AnalyticsService)
local LeaderboardService = require(Services.LeaderboardService)

---------------------------------------------------------------------------
-- Seed the PRNG once so mutation rolls are non-deterministic across servers
---------------------------------------------------------------------------
math.randomseed(os.time())

---------------------------------------------------------------------------
-- Helper — resolve ingredient display name safely
-- (defined before any use below)
---------------------------------------------------------------------------
local function ingredientId_toDisplayName(id: string): string
	local info = Ingredients[id]
	return if info then info.displayName else id
end

---------------------------------------------------------------------------
-- Rate limiting
-- Prevents clients from spamming RemoteEvents to exploit the economy.
-- Each player gets one allowed call per event per COOLDOWN window.
---------------------------------------------------------------------------
local RATE_COOLDOWN: { [string]: number } = {
	[Network.BuySeed]        = 0.3,
	[Network.PlantSeed]      = 0.3,
	[Network.Harvest]        = 0.3,
	[Network.BrewPotion]     = 0.5,
	[Network.SellPotion]     = 0.3,
	[Network.UpgradeLab]     = 1.0,
	[Network.UpgradeCauldron] = 1.0,
}

-- lastFire[userId][eventName] = tick()
local lastFire: { [number]: { [string]: number } } = {}

local function isRateLimited(player: Player, eventName: string): boolean
	local userId = player.UserId
	local cooldown = RATE_COOLDOWN[eventName]
	if not cooldown then return false end

	local now = tick()
	if not lastFire[userId] then
		lastFire[userId] = {}
	end

	local last = lastFire[userId][eventName] or 0
	if now - last < cooldown then
		return true -- too fast, ignore
	end

	lastFire[userId][eventName] = now
	return false
end

---------------------------------------------------------------------------
-- Create Remotes folder & RemoteEvent instances
---------------------------------------------------------------------------
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local remotes: { [string]: RemoteEvent } = {}

for _, eventName in Network.getAllEventNames() do
	local remote = Instance.new("RemoteEvent")
	remote.Name = eventName
	remote.Parent = remotesFolder
	remotes[eventName] = remote
end

---------------------------------------------------------------------------
-- Initialise services (order matters — DataService before PlotService)
---------------------------------------------------------------------------
DataService.init()
PlotService.init()
GrowthService.init()
AnalyticsService.init()
LeaderboardService.init()
-- BrewingService, EconomyService, DiscoveryService are stateless; no init required.

---------------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	DataService.onPlayerAdded(player)
	PlotService.createLab(player)
	AnalyticsService.onSessionStart(player)

	-- Send the initial full state to the client once everything is ready
	DataService.syncToClient(player)
end

local function onPlayerRemoving(player: Player)
	AnalyticsService.onSessionEnd(player)
	LeaderboardService.onPlayerRemoving(player)
	PlotService.destroyLab(player)
	DataService.onPlayerRemoving(player)
	lastFire[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players who joined before this script ran (studio / late loading)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

---------------------------------------------------------------------------
-- RemoteEvent handlers — route to services
---------------------------------------------------------------------------

-- BuySeed: player purchases a seed into their seed inventory
remotes[Network.BuySeed].OnServerEvent:Connect(function(player: Player, ingredientId: string)
	if isRateLimited(player, Network.BuySeed) then return end
	if typeof(ingredientId) ~= "string" then return end
	EconomyService.buySeed(player, ingredientId)
end)

-- PlantSeed: player plants a seed (from inventory or buy-and-plant in one step)
remotes[Network.PlantSeed].OnServerEvent:Connect(function(player: Player, plotIndex: number, ingredientId: string)
	if isRateLimited(player, Network.PlantSeed) then return end
	if typeof(plotIndex) ~= "number" then return end
	if typeof(ingredientId) ~= "string" then return end
	plotIndex = math.floor(plotIndex)
	GrowthService.plantSeed(player, plotIndex, ingredientId)
	AnalyticsService.onSeedPlanted(player, ingredientId)
end)

-- Harvest: player harvests a ready plant
remotes[Network.Harvest].OnServerEvent:Connect(function(player: Player, plotIndex: number)
	if isRateLimited(player, Network.Harvest) then return end
	if typeof(plotIndex) ~= "number" then return end
	plotIndex = math.floor(plotIndex)

	local data = DataService.getData(player)
	if not data then return end

	local plot = data.Plots[plotIndex]
	if not plot or plot.State ~= "Ready" then return end

	local entry = {
		Id = plot.IngredientId,
		Rarity = plot.Rarity or "Common",
	}
	table.insert(data.Ingredients, entry)

	-- Reset plot to empty
	plot.State = "Empty"
	plot.IngredientId = nil
	plot.PlantedAt = nil
	plot.GrowthDuration = nil
	plot.Rarity = nil

	PlotService.updatePlotVisual(player, plotIndex)
	AnalyticsService.onHarvest(player, entry.Id, entry.Rarity)
	DataService.syncToClient(player)

	local displayName = ingredientId_toDisplayName(entry.Id)
	local rarity = entry.Rarity

	local rarityMessages = {
		Common    = "Harvested " .. displayName .. "! A healthy Common specimen.",
		Uncommon  = "Harvested " .. displayName .. "! Uncommon — ideal growing conditions.",
		Rare      = "Harvested " .. displayName .. "! Rare — something special happened here!",
		Epic      = "Harvested " .. displayName .. "! Epic — extraordinary growth conditions!",
		Legendary = "Harvested " .. displayName .. "! LEGENDARY — a once-in-a-generation specimen!",
	}
	local message = rarityMessages[rarity] or ("Harvested " .. displayName .. "! (" .. rarity .. ")")

	local notifRemote = ReplicatedStorage.Remotes:FindFirstChild(Network.Notification)
	if notifRemote then
		notifRemote:FireClient(player, message)
	end
end)

-- BrewPotion: player brews from two ingredients
remotes[Network.BrewPotion].OnServerEvent:Connect(function(player: Player, idx1: number, idx2: number)
	if isRateLimited(player, Network.BrewPotion) then return end
	if typeof(idx1) ~= "number" or typeof(idx2) ~= "number" then return end
	idx1 = math.floor(idx1)
	idx2 = math.floor(idx2)
	local brewed = BrewingService.brewPotion(player, idx1, idx2)
	if brewed then
		AnalyticsService.onPotion(player, brewed.recipeId, brewed.value)
		if brewed.isNewDiscovery then
			AnalyticsService.onDiscovery(player, brewed.recipeId, brewed.discoveryCount)
		end
	end
end)

-- SellPotion: player sells a potion
remotes[Network.SellPotion].OnServerEvent:Connect(function(player: Player, potionIndex: number)
	if isRateLimited(player, Network.SellPotion) then return end
	if typeof(potionIndex) ~= "number" then return end
	potionIndex = math.floor(potionIndex)
	EconomyService.sellPotion(player, potionIndex)
end)

-- UpgradeLab: player upgrades their lab
remotes[Network.UpgradeLab].OnServerEvent:Connect(function(player: Player)
	if isRateLimited(player, Network.UpgradeLab) then return end
	local newLevel = EconomyService.upgradeLab(player)
	if newLevel then
		AnalyticsService.onUpgrade(player, "Lab", newLevel)
	end
end)

-- UpgradeCauldron: player upgrades their cauldron
remotes[Network.UpgradeCauldron].OnServerEvent:Connect(function(player: Player)
	if isRateLimited(player, Network.UpgradeCauldron) then return end
	local newLevel = EconomyService.upgradeCauldron(player)
	if newLevel then
		AnalyticsService.onUpgrade(player, "Cauldron", newLevel)
	end
end)

-- RequestDiscoverySummary: client requests up-to-date discovery data.
-- The full DiscoveredRecipes set is already in StateSync; this just
-- triggers a fresh push without requiring a separate data payload.
remotes[Network.RequestDiscoverySummary].OnServerEvent:Connect(function(player: Player)
	DataService.syncToClient(player)
end)
