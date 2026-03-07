--[[
	GrowthService.luau
	Ticks plant growth on a 1-second interval and handles planting seeds.
	When a plant completes growth, a mutation rarity is rolled and the
	plot transitions to the "Ready" state.
]]

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
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
				plot.Rarity = DataService.rollMutation()
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

--- Plant a seed in a player's plot.
--- Consumes a pre-purchased seed from the Seeds inventory if available (BuySeed flow).
--- Falls back to buy-and-plant in one step so PlantSeed works without a prior BuySeed.
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

	-- Check whether a pre-purchased seed exists in inventory (BuySeed was called first)
	local seedIndex = nil
	if data.Seeds then
		for i, seed in data.Seeds do
			if seed.Id == ingredientId then
				seedIndex = i
				break
			end
		end
	end

	if seedIndex then
		-- Consume the pre-purchased seed; Essence was already deducted at buy time
		table.remove(data.Seeds, seedIndex)
	else
		-- Direct plant: deduct Essence now (no prior BuySeed required)
		if data.Gold < ingredientDef.seedCost then
			DataService.notify(player, "Not enough Essence! Need " .. ingredientDef.seedCost .. " Essence")
			return
		end
		data.Gold -= ingredientDef.seedCost
	end

	plot.State = "Growing"
	plot.IngredientId = ingredientId
	plot.PlantedAt = os.time()
	plot.GrowthDuration = ingredientDef.growthTime

	PlotService.updatePlotVisual(player, plotIndex)
	DataService.syncToClient(player)
	DataService.notify(player, "Planted " .. ingredientDef.displayName .. "! Growing for " .. ingredientDef.growthTime .. "s")
end

return GrowthService
