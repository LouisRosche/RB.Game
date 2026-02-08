--[[
	GrowthService.luau
	Ticks plant growth on a 1-second interval and handles planting seeds.
	When a plant completes growth, a mutation rarity is rolled and the
	plot transitions to the "Ready" state.
]]

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared.Config)
local Ingredients = require(Shared.Ingredients)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local GrowthService = {}

---------------------------------------------------------------------------
-- Internal state
---------------------------------------------------------------------------
local tickAccumulator = 0
local TICK_INTERVAL = 1 -- seconds between growth checks

---------------------------------------------------------------------------
-- Mutation roll
---------------------------------------------------------------------------

--- Walk through MUTATION_TIERS and return the rarity name that was rolled.
function GrowthService.rollMutation(): string
	local roll = math.random()
	local cumulative = 0
	for _, tier in Config.MUTATION_TIERS do
		cumulative += tier.chance
		if roll <= cumulative then
			return tier.name
		end
	end
	return Config.MUTATION_TIERS[1].name
end

---------------------------------------------------------------------------
-- Growth tick
---------------------------------------------------------------------------

local function onHeartbeat(dt: number)
	tickAccumulator += dt
	if tickAccumulator < TICK_INTERVAL then return end
	tickAccumulator -= TICK_INTERVAL

	local now = os.time()
	local Players = game:GetService("Players")

	for _, player in Players:GetPlayers() do
		local data = DataService.getData(player)
		if not data then continue end

		local changed = false
		for plotIndex, plot in data.Plots do
			if plot.State ~= "Growing" then continue end
			if not plot.PlantedAt or not plot.GrowthDuration then continue end

			local elapsed = now - plot.PlantedAt
			if elapsed >= plot.GrowthDuration then
				-- Growth complete — roll rarity
				plot.State = "Ready"
				plot.Rarity = GrowthService.rollMutation()
				changed = true

				PlotService.updatePlotVisual(player, plotIndex)

				local info = Ingredients[plot.IngredientId]
				local displayName = if info then info.displayName else plot.IngredientId
				DataService.notify(player, "Your " .. displayName .. " is ready to harvest! (" .. plot.Rarity .. ")")
			end
		end

		if changed then
			DataService.syncToClient(player)
		end
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function GrowthService.init()
	RunService.Heartbeat:Connect(onHeartbeat)
end

--- Plant a seed in a player's plot. Validates inputs and deducts gold.
function GrowthService.plantSeed(player: Player, plotIndex: number, ingredientId: string)
	local data = DataService.getData(player)
	if not data then return end

	-- Validate ingredient exists
	local ingredientDef = Ingredients[ingredientId]
	if not ingredientDef then return end

	-- Validate plot index
	local plot = data.Plots[plotIndex]
	if not plot then return end
	if plot.State ~= "Empty" then
		DataService.notify(player, "That plot is not empty!")
		return
	end

	-- Check gold
	if data.Gold < ingredientDef.seedCost then
		DataService.notify(player, "Not enough gold! Need " .. ingredientDef.seedCost .. "g")
		return
	end

	-- Deduct gold and plant
	data.Gold -= ingredientDef.seedCost
	plot.State = "Growing"
	plot.IngredientId = ingredientId
	plot.PlantedAt = os.time()
	plot.GrowthDuration = ingredientDef.growthTime

	PlotService.updatePlotVisual(player, plotIndex)
	DataService.syncToClient(player)
	DataService.notify(player, "Planted " .. ingredientDef.displayName .. "! Growing for " .. ingredientDef.growthTime .. "s")
end

return GrowthService
