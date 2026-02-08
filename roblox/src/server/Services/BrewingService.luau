--[[
	BrewingService.luau
	Handles combining two harvested ingredients into a potion at the
	cauldron. Looks up the recipe, calculates value from rarity
	multipliers and cauldron bonus, and updates player inventory.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Config  = require(Shared.Config)
local Recipes = require(Shared.Recipes)

local DataService = require(script.Parent.DataService)

local BrewingService = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Find the index of a rarity name in Config.MUTATION_TIERS.
--- Returns 1 (Common) as fallback if not found.
local function getRarityIndex(rarityName: string): number
	for i, tier in Config.MUTATION_TIERS do
		if tier.name == rarityName then
			return i
		end
	end
	return 1
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Brew a potion from two ingredients in the player's inventory.
--- @param player  The player requesting the brew
--- @param idx1    First ingredient inventory index (1-based)
--- @param idx2    Second ingredient inventory index (1-based)
function BrewingService.brewPotion(player: Player, idx1: number, idx2: number)
	local data = DataService.getData(player)
	if not data then return end

	-- Validate: different indices
	if idx1 == idx2 then
		DataService.notify(player, "Select two different ingredients!")
		return
	end

	-- Validate: both indices exist
	local inv = data.Ingredients
	if not inv[idx1] or not inv[idx2] then
		DataService.notify(player, "Invalid ingredient selection!")
		return
	end

	local ingredient1 = inv[idx1]
	local ingredient2 = inv[idx2]

	-- Look up recipe
	local recipe = Recipes.lookup(ingredient1.Id, ingredient2.Id)
	if not recipe then
		DataService.notify(player, "These ingredients can't be combined!")
		return
	end

	-- Calculate potion value
	local rarityIdx1 = getRarityIndex(ingredient1.Rarity)
	local rarityIdx2 = getRarityIndex(ingredient2.Rarity)
	local potionValue = Recipes.calculateValue(recipe, rarityIdx1, rarityIdx2, data.CauldronLevel)

	-- Remove ingredients from inventory (remove HIGHER index first to
	-- avoid shifting the lower index)
	local highIdx = math.max(idx1, idx2)
	local lowIdx = math.min(idx1, idx2)
	table.remove(inv, highIdx)
	table.remove(inv, lowIdx)

	-- Add potion to inventory
	table.insert(data.Potions, {
		Id = recipe.id,
		DisplayName = recipe.displayName,
		Value = potionValue,
	})

	-- Update stats
	data.Stats.PotionsBrewed += 1

	DataService.syncToClient(player)
	DataService.notify(player, "Brewed " .. recipe.displayName .. "! Worth " .. potionValue .. " gold")
end

return BrewingService
