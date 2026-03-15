--[[
	EconomyService.luau
	Handles all Essence transactions: buying seeds, selling potions,
	upgrading lab and cauldron levels.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared.Config)
local Ingredients = require(Shared.Ingredients)

local DataService      = require(script.Parent.DataService)
local PlotService      = require(script.Parent.PlotService)
local SeasonalService  = require(script.Parent.SeasonalService)

local EconomyService = {}

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Purchase a seed and add it to the player's seed inventory.
--- Supports both base ingredients and active seasonal ingredients.
--- Actual planting is a separate step via GrowthService (PlantSeed remote).
function EconomyService.buySeed(player: Player, ingredientId: string)
	local data = DataService.getData(player)
	if not data then return end

	-- Check base ingredients first, then seasonal
	local def = Ingredients[ingredientId]
	local isSeasonal = false
	if not def then
		local seasonalDef = SeasonalService.getActiveIngredient(ingredientId)
		if seasonalDef then
			-- Adapt seasonal ingredient to match base ingredient shape
			def = {
				displayName = seasonalDef.displayName,
				seedCost = seasonalDef.seedCost,
				baseValue = seasonalDef.baseValue,
				growthTime = seasonalDef.growthTime,
			}
			isSeasonal = true
		end
	end

	if not def then return end

	if data.Essence < def.seedCost then
		DataService.notify(player, "Not enough Essence! Need " .. def.seedCost .. " Essence")
		return
	end

	if #data.Seeds >= Config.MAX_SEEDS then
		DataService.notify(player, "Seed pouch full (" .. Config.MAX_SEEDS .. " max)! Plant some seeds first.")
		return
	end

	data.Essence -= def.seedCost
	-- Track the purchased seed so GrowthService can consume it on plant
	table.insert(data.Seeds, { Id = ingredientId })
	DataService.syncToClient(player)

	local label = if isSeasonal then "SEASONAL " else ""
	DataService.notify(player, "Purchased " .. label .. def.displayName .. " seed!")

	return def.seedCost, isSeasonal
end

--- Sell a potion from the player's inventory for its Essence value.
function EconomyService.sellPotion(player: Player, potionIndex: number)
	local data = DataService.getData(player)
	if not data then return end

	local potion = data.Potions[potionIndex]
	if not potion then
		DataService.notify(player, "Invalid potion!")
		return
	end

	local value = potion.Value or 0
	data.Essence += value
	data.Stats.TotalEssenceEarned += value

	local displayName = potion.DisplayName or potion.Id
	table.remove(data.Potions, potionIndex)

	DataService.syncToClient(player)
	DataService.notify(player, "Sold " .. displayName .. " for " .. value .. " Essence!")
end

--- Sell all potions at once. Returns total value earned.
function EconomyService.sellAll(player: Player): number
	local data = DataService.getData(player)
	if not data then return 0 end

	if #data.Potions == 0 then
		DataService.notify(player, "No potions to sell!")
		return 0
	end

	local totalValue = 0
	local count = #data.Potions
	for _, potion in data.Potions do
		totalValue += (potion.Value or 0)
	end

	data.Essence += totalValue
	data.Stats.TotalEssenceEarned += totalValue
	data.Potions = {}

	DataService.syncToClient(player)
	DataService.notify(player, "Sold " .. count .. " potions for " .. totalValue .. " Essence!")

	return totalValue
end

--- Upgrade the player's lab to the next level, adding more plots.
function EconomyService.upgradeLab(player: Player)
	local data = DataService.getData(player)
	if not data then return end

	local currentLevel = data.LabLevel
	if currentLevel >= Config.MAX_LAB_LEVEL then
		DataService.notify(player, "Lab is already at max level!")
		return
	end

	local nextLevel = currentLevel + 1
	local nextDef = Config.LAB_LEVELS[nextLevel]
	if not nextDef then return end

	if data.Essence < nextDef.cost then
		DataService.notify(player, "Not enough Essence! Need " .. nextDef.cost .. " Essence")
		return
	end

	-- Deduct Essence and upgrade
	data.Essence -= nextDef.cost
	data.LabLevel = nextLevel

	-- Add new empty plots for the additional slots
	local currentPlots = #data.Plots
	local newPlots = nextDef.plots
	for i = currentPlots + 1, newPlots do
		data.Plots[i] = { State = "Empty" }
	end

	-- Tell PlotService to create the new physical plot parts
	PlotService.upgradeLab(player)

	DataService.syncToClient(player)
	DataService.notify(player, "Lab upgraded to " .. nextDef.name .. "! Now have " .. newPlots .. " plots")
	return nextLevel
end

--- Upgrade the player's cauldron to the next level.
function EconomyService.upgradeCauldron(player: Player)
	local data = DataService.getData(player)
	if not data then return end

	local currentLevel = data.CauldronLevel
	if currentLevel >= Config.MAX_CAULDRON_LEVEL then
		DataService.notify(player, "Cauldron is already at max level!")
		return
	end

	local nextLevel = currentLevel + 1
	local nextDef = Config.CAULDRON_LEVELS[nextLevel]
	if not nextDef then return end

	if data.Essence < nextDef.cost then
		DataService.notify(player, "Not enough Essence! Need " .. nextDef.cost .. " Essence")
		return
	end

	-- Deduct Essence and upgrade
	data.Essence -= nextDef.cost
	data.CauldronLevel = nextLevel

	DataService.syncToClient(player)
	DataService.notify(player, "Cauldron upgraded to " .. nextDef.name .. "! Brews " .. nextDef.brewTime .. "s, +" .. math.floor((nextDef.valueBonus - 1) * 100) .. "% value")
	return nextLevel
end

return EconomyService
