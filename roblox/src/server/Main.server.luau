--[[
	Main.server.luau
	Single server entry point for Alchemy Academy.
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
local Config      = require(Shared.Config)
local Ingredients = require(Shared.Ingredients)
local Strings     = require(Shared.Strings)

---------------------------------------------------------------------------
-- Server service modules (ServerScriptService.Server.Services)
---------------------------------------------------------------------------
local Services             = script.Parent.Services
local DataService          = require(Services.DataService)
local PlotService          = require(Services.PlotService)
local GrowthService        = require(Services.GrowthService)
local BrewingService       = require(Services.BrewingService)
local EconomyService       = require(Services.EconomyService)
local DiscoveryService     = require(Services.DiscoveryService)
local AnalyticsService     = require(Services.AnalyticsService)
local LeaderboardService   = require(Services.LeaderboardService)
local MonetizationService  = require(Services.MonetizationService)
local SeasonalService      = require(Services.SeasonalService)

---------------------------------------------------------------------------
-- Harvest rarity → Strings template map (module-level constant; avoids
-- rebuilding the table on every harvest event)
---------------------------------------------------------------------------
local RARITY_HARVEST_STRINGS = {
	Common    = Strings.HARVESTED_COMMON,
	Uncommon  = Strings.HARVESTED_UNCOMMON,
	Rare      = Strings.HARVESTED_RARE,
	Epic      = Strings.HARVESTED_EPIC,
	Legendary = Strings.HARVESTED_LEGENDARY,
}

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
	[Network.SellAll]        = 1.0,
	[Network.UpgradeLab]     = 1.0,
	[Network.UpgradeCauldron] = 1.0,
	[Network.RequestAdReward] = 2.0,
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
MonetizationService.init(DataService, AnalyticsService)
SeasonalService.init(DataService)
EconomyService.init(MonetizationService)
-- BrewingService, DiscoveryService are stateless; no init required.

---------------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	DataService.onPlayerAdded(player)
	PlotService.createLab(player)
	AnalyticsService.onSessionStart(player)

	-- Check game pass ownership async so it doesn't block join
	MonetizationService.checkPassesOnJoin(player)

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
	-- Allow base ingredients OR active seasonal ingredients
	if not Ingredients[ingredientId] and not SeasonalService.getActiveIngredient(ingredientId) then
		return -- reject unknown IDs
	end
	local cost, isSeasonal = EconomyService.buySeed(player, ingredientId)
	if cost then
		if isSeasonal then
			AnalyticsService.onSeasonalPurchased(player, ingredientId, cost)
		else
			AnalyticsService.onSeedPurchased(player, ingredientId, cost)
		end
	end
end)

-- PlantSeed: player plants a seed (from inventory or buy-and-plant in one step)
remotes[Network.PlantSeed].OnServerEvent:Connect(function(player: Player, plotIndex: number, ingredientId: string)
	if isRateLimited(player, Network.PlantSeed) then return end
	if typeof(plotIndex) ~= "number" then return end
	if typeof(ingredientId) ~= "string" then return end
	-- Allow base ingredients OR active seasonal ingredients
	if not Ingredients[ingredientId] and not SeasonalService.getActiveIngredient(ingredientId) then
		return -- reject unknown IDs
	end
	plotIndex = math.floor(plotIndex)
	if plotIndex < 1 then return end
	GrowthService.plantSeed(player, plotIndex, ingredientId)
	AnalyticsService.onSeedPlanted(player, ingredientId)
end)

-- Harvest: player harvests a ready plant
remotes[Network.Harvest].OnServerEvent:Connect(function(player: Player, plotIndex: number)
	if isRateLimited(player, Network.Harvest) then return end
	if typeof(plotIndex) ~= "number" then return end
	plotIndex = math.floor(plotIndex)
	if plotIndex < 1 then return end

	local data = DataService.getData(player)
	if not data then return end
	if plotIndex > #data.Plots then return end

	local plot = data.Plots[plotIndex]
	if not plot or plot.State ~= "Ready" then return end

	-- Enforce ingredient inventory cap (protects DataStore size)
	if #data.Ingredients >= Config.MAX_INGREDIENTS then
		DataService.notify(player, "Ingredient bag full (" .. Config.MAX_INGREDIENTS .. " max)! Brew some potions first.")
		return
	end

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

	-- Notify the client so it can play localised particle burst
	remotes[Network.HarvestEffect]:FireClient(player, plotIndex, entry.Rarity)

	local displayName = ingredientId_toDisplayName(entry.Id)
	local rarity = entry.Rarity

	local template = RARITY_HARVEST_STRINGS[rarity] or ("Harvested {item}! (" .. rarity .. ")")
	local message = string.gsub(template, "{item}", displayName)
	remotes[Network.Notification]:FireClient(player, message)
end)

-- BrewPotion: player brews from two ingredients
remotes[Network.BrewPotion].OnServerEvent:Connect(function(player: Player, idx1: number, idx2: number)
	if isRateLimited(player, Network.BrewPotion) then return end
	if typeof(idx1) ~= "number" or typeof(idx2) ~= "number" then return end
	idx1 = math.floor(idx1)
	idx2 = math.floor(idx2)
	if idx1 < 1 or idx2 < 1 then return end
	local brewed = BrewingService.brewPotion(player, idx1, idx2)
	if brewed then
		AnalyticsService.onPotion(player, brewed.recipeId, brewed.value)
		if brewed.isNewDiscovery then
			AnalyticsService.onDiscovery(player, brewed.recipeId, brewed.discoveryCount)
		end
		-- Trigger cauldron particle burst on the brewing client
		remotes[Network.BrewEffect]:FireClient(player)
	end
end)

-- SellPotion: player sells a potion
remotes[Network.SellPotion].OnServerEvent:Connect(function(player: Player, potionIndex: number)
	if isRateLimited(player, Network.SellPotion) then return end
	if typeof(potionIndex) ~= "number" then return end
	potionIndex = math.floor(potionIndex)
	if potionIndex < 1 then return end

	-- Capture value before sell for analytics
	local data = DataService.getData(player)
	local potionValue = 0
	if data and data.Potions and data.Potions[potionIndex] then
		potionValue = data.Potions[potionIndex].Value or 0
	end

	EconomyService.sellPotion(player, potionIndex)

	if potionValue > 0 then
		AnalyticsService.onSell(player, potionValue)
	end
end)

-- SellAll: player sells all potions at once
remotes[Network.SellAll].OnServerEvent:Connect(function(player: Player)
	if isRateLimited(player, Network.SellAll) then return end
	local totalValue = EconomyService.sellAll(player)
	if totalValue > 0 then
		AnalyticsService.onSell(player, totalValue)
	end
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

-- TutorialComplete: player finished (or skipped) the first-session tutorial.
-- Mark the flag so the tutorial is not shown again on future sessions.
remotes[Network.TutorialComplete].OnServerEvent:Connect(function(player: Player)
	local data = DataService.getData(player)
	if data and not data.TutorialCompleted then
		data.TutorialCompleted = true
		-- ProfileService auto-saves every ~30 s; no explicit save needed here.
	end
end)

-- EquipCosmetic: player swaps which cosmetic is active in a given category.
-- Server validates ownership; if valid, updates ActiveCosmetic and syncs state.
remotes[Network.EquipCosmetic].OnServerEvent:Connect(function(player: Player, cosmeticId: string)
	if typeof(cosmeticId) ~= "string" then return end
	MonetizationService.equipCosmetic(player, cosmeticId)
end)

-- VerifyGamePass: client fires after a purchase prompt is dismissed to ask
-- the server to re-check ownership. Server calls UserOwnsGamePassAsync (async).
remotes[Network.VerifyGamePass].OnServerEvent:Connect(function(player: Player, passId: number)
	if typeof(passId) ~= "number" then return end
	MonetizationService.checkPassesOnJoin(player)  -- re-verifies all passes
end)

-- RequestAdReward: player opted in to watch a rewarded video ad.
-- Server handles the entire flow — cooldown check, ad prompt via AdService,
-- and reward grant only after verified ad completion.
remotes[Network.RequestAdReward].OnServerEvent:Connect(function(player: Player)
	if isRateLimited(player, Network.RequestAdReward) then return end
	MonetizationService.handleAdRewardRequest(player)
end)
