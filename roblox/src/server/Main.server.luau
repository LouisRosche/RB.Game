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
local ServerScriptService = game:GetService("ServerScriptService")

---------------------------------------------------------------------------
-- Shared modules (ReplicatedStorage.Shared)
---------------------------------------------------------------------------
local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Network     = require(Shared.Network)
local Config      = require(Shared.Config)
local Ingredients = require(Shared.Ingredients)
local Recipes     = require(Shared.Recipes)

---------------------------------------------------------------------------
-- Server service modules (ServerScriptService.Server.Services)
---------------------------------------------------------------------------
local Services        = script.Parent.Services
local DataService     = require(Services.DataService)
local PlotService     = require(Services.PlotService)
local GrowthService   = require(Services.GrowthService)
local BrewingService  = require(Services.BrewingService)
local EconomyService  = require(Services.EconomyService)

---------------------------------------------------------------------------
-- Seed the PRNG once so mutation rolls are non-deterministic across servers
---------------------------------------------------------------------------
math.randomseed(os.time())

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
-- BrewingService and EconomyService are stateless; no init required.

---------------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	DataService.onPlayerAdded(player)
	PlotService.createLab(player)

	-- Send the initial full state to the client once everything is ready
	DataService.syncToClient(player)
end

local function onPlayerRemoving(player: Player)
	PlotService.destroyLab(player)
	DataService.onPlayerRemoving(player)
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
-- BuySeed: player wants to purchase a seed (gold deduction only)
remotes[Network.BuySeed].OnServerEvent:Connect(function(player: Player, ingredientId: string)
	if typeof(ingredientId) ~= "string" then return end
	EconomyService.buySeed(player, ingredientId)
end)

-- PlantSeed: player wants to plant a seed on a specific plot
remotes[Network.PlantSeed].OnServerEvent:Connect(function(player: Player, plotIndex: number, ingredientId: string)
	if typeof(plotIndex) ~= "number" then return end
	if typeof(ingredientId) ~= "string" then return end
	plotIndex = math.floor(plotIndex)
	GrowthService.plantSeed(player, plotIndex, ingredientId)
end)

-- Harvest: player wants to harvest a ready plant
remotes[Network.Harvest].OnServerEvent:Connect(function(player: Player, plotIndex: number)
	if typeof(plotIndex) ~= "number" then return end
	plotIndex = math.floor(plotIndex)

	local data = DataService.getData(player)
	if not data then return end

	local plot = data.Plots[plotIndex]
	if not plot or plot.State ~= "Ready" then return end

	-- Move harvested ingredient into inventory with rolled rarity
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
	DataService.syncToClient(player)

	local displayName = ingredientId_toDisplayName(entry.Id)
	local notifRemote = ReplicatedStorage.Remotes:FindFirstChild(Network.Notification)
	if notifRemote then
		notifRemote:FireClient(player, "Harvested " .. displayName .. " (" .. entry.Rarity .. ")!")
	end
end)

-- BrewPotion: player wants to brew from two ingredients
remotes[Network.BrewPotion].OnServerEvent:Connect(function(player: Player, idx1: number, idx2: number)
	if typeof(idx1) ~= "number" or typeof(idx2) ~= "number" then return end
	idx1 = math.floor(idx1)
	idx2 = math.floor(idx2)
	BrewingService.brewPotion(player, idx1, idx2)
end)

-- SellPotion: player wants to sell a potion
remotes[Network.SellPotion].OnServerEvent:Connect(function(player: Player, potionIndex: number)
	if typeof(potionIndex) ~= "number" then return end
	potionIndex = math.floor(potionIndex)
	EconomyService.sellPotion(player, potionIndex)
end)

-- UpgradeLab: player wants to upgrade their lab
remotes[Network.UpgradeLab].OnServerEvent:Connect(function(player: Player)
	EconomyService.upgradeLab(player)
end)

-- UpgradeCauldron: player wants to upgrade their cauldron
remotes[Network.UpgradeCauldron].OnServerEvent:Connect(function(player: Player)
	EconomyService.upgradeCauldron(player)
end)

---------------------------------------------------------------------------
-- Helper — resolve ingredient display name safely
---------------------------------------------------------------------------
function ingredientId_toDisplayName(id: string): string
	local info = Ingredients[id]
	if info then
		return info.displayName
	end
	return id
end
