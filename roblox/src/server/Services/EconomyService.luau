--[[
	EconomyService.luau
	Handles all gold transactions: buying seeds, selling potions,
	upgrading lab and cauldron levels.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared.Config)
local Ingredients = require(Shared.Ingredients)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local EconomyService = {}

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Purchase a seed. Deducts gold only; actual planting is via GrowthService.
--- This is called from the BuySeed remote when buying into inventory.
function EconomyService.buySeed(player: Player, ingredientId: string)
	local data = DataService.getData(player)
	if not data then return end

	local def = Ingredients[ingredientId]
	if not def then return end

	if data.Gold < def.seedCost then
		DataService.notify(player, "Not enough gold! Need " .. def.seedCost .. "g")
		return
	end

	data.Gold -= def.seedCost
	DataService.syncToClient(player)
	DataService.notify(player, "Purchased " .. def.displayName .. " seed!")
end

--- Sell a potion from the player's inventory for its gold value.
function EconomyService.sellPotion(player: Player, potionIndex: number)
	local data = DataService.getData(player)
	if not data then return end

	local potion = data.Potions[potionIndex]
	if not potion then
		DataService.notify(player, "Invalid potion!")
		return
	end

	local value = potion.Value or 0
	data.Gold += value
	data.Stats.TotalGoldEarned += value

	local displayName = potion.DisplayName or potion.Id
	table.remove(data.Potions, potionIndex)

	DataService.syncToClient(player)
	DataService.notify(player, "Sold " .. displayName .. " for " .. value .. " gold!")
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

	if data.Gold < nextDef.cost then
		DataService.notify(player, "Not enough gold! Need " .. nextDef.cost .. "g")
		return
	end

	-- Deduct gold and upgrade
	data.Gold -= nextDef.cost
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

	if data.Gold < nextDef.cost then
		DataService.notify(player, "Not enough gold! Need " .. nextDef.cost .. "g")
		return
	end

	-- Deduct gold and upgrade
	data.Gold -= nextDef.cost
	data.CauldronLevel = nextLevel

	DataService.syncToClient(player)
	DataService.notify(player, "Cauldron upgraded to " .. nextDef.name .. "! Brews " .. nextDef.brewTime .. "s, +" .. math.floor((nextDef.valueBonus - 1) * 100) .. "% value")
end

return EconomyService
