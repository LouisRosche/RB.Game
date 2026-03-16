--[[
	RecipeTests.luau
	Tests for roblox/src/shared/Recipes.luau

	Validates:
	  - All 10 recipe keys resolve to valid definitions
	  - lookup() returns the correct recipe regardless of argument order
	  - Unknown ingredient combos return nil
	  - calculateValue() produces expected outputs for known inputs
]]

local Recipes     = require(script.Parent.Parent:FindFirstChild("src") and script.Parent.Parent.src.shared.Recipes or game.ServerScriptService:FindFirstChild("src") and game.ServerScriptService.src.shared.Recipes or script.Parent.Parent.Parent.src.shared.Recipes)
local Config      = require(script.Parent.Parent:FindFirstChild("src") and script.Parent.Parent.src.shared.Config or game.ServerScriptService:FindFirstChild("src") and game.ServerScriptService.src.shared.Config or script.Parent.Parent.Parent.src.shared.Config)

local Tests = {}

---------------------------------------------------------------------------
-- Data: all expected recipe keys and their potion IDs
---------------------------------------------------------------------------

local EXPECTED_RECIPES = {
	-- Same-ingredient brews (4)
	{ key = "Moonpetal+Moonpetal",    id = "LunarElixir",     baseValue = 25 },
	{ key = "Fireroot+Fireroot",      id = "BlazingTonic",    baseValue = 35 },
	{ key = "Shadowmoss+Shadowmoss",  id = "VoidEssence",     baseValue = 50 },
	{ key = "Starbloom+Starbloom",    id = "CelestialBrew",   baseValue = 75 },
	-- Cross-ingredient brews (6)
	{ key = "Fireroot+Moonpetal",     id = "TwilightPotion",  baseValue = 30 },
	{ key = "Moonpetal+Shadowmoss",   id = "PhantomDraught",  baseValue = 40 },
	{ key = "Moonpetal+Starbloom",    id = "AstralSerum",     baseValue = 50 },
	{ key = "Fireroot+Shadowmoss",    id = "InfernalMix",     baseValue = 45 },
	{ key = "Fireroot+Starbloom",     id = "SolarNectar",     baseValue = 55 },
	{ key = "Shadowmoss+Starbloom",   id = "EclipseTincture", baseValue = 65 },
}

---------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------

--- Verify the recipe map contains exactly 10 entries.
function Tests.test_recipe_count(t)
	local count = 0
	for _ in Recipes.Map do
		count += 1
	end
	t:assertEqual(count, 10, "recipe count")
end

--- Every expected recipe key exists and has the correct id.
function Tests.test_all_recipes_exist_with_correct_id(t)
	for _, entry in EXPECTED_RECIPES do
		local recipe = Recipes.Map[entry.key]
		t:assertNotNil(recipe, "recipe for key " .. entry.key)
		if recipe then
			t:assertEqual(recipe.id, entry.id, entry.key .. " id")
		end
	end
end

--- Every recipe has a non-empty displayName.
function Tests.test_all_recipes_have_display_name(t)
	for key, recipe in Recipes.Map do
		t:assertType(recipe.displayName, "string", key .. " displayName type")
		t:assertTrue(#recipe.displayName > 0, key .. " displayName non-empty")
	end
end

--- Every recipe has a positive baseValue.
function Tests.test_all_recipes_have_positive_base_value(t)
	for key, recipe in Recipes.Map do
		t:assertPositive(recipe.baseValue, key .. " baseValue")
	end
end

--- Every recipe has a scienceHook string.
function Tests.test_all_recipes_have_science_hook(t)
	for key, recipe in Recipes.Map do
		t:assertType(recipe.scienceHook, "string", key .. " scienceHook type")
		t:assertTrue(#recipe.scienceHook > 0, key .. " scienceHook non-empty")
	end
end

--- baseValue matches the expected hardcoded values.
function Tests.test_base_values_match(t)
	for _, entry in EXPECTED_RECIPES do
		local recipe = Recipes.Map[entry.key]
		if recipe then
			t:assertEqual(recipe.baseValue, entry.baseValue, entry.key .. " baseValue")
		end
	end
end

---------------------------------------------------------------------------
-- lookup() tests
---------------------------------------------------------------------------

--- lookup() returns the correct recipe when ingredients are in alphabetical order.
function Tests.test_lookup_alphabetical_order(t)
	local recipe = Recipes.lookup("Fireroot", "Moonpetal")
	t:assertNotNil(recipe, "Fireroot+Moonpetal lookup")
	if recipe then
		t:assertEqual(recipe.id, "TwilightPotion", "lookup id")
	end
end

--- lookup() returns the correct recipe when ingredients are in reverse order.
function Tests.test_lookup_reverse_order(t)
	local recipe = Recipes.lookup("Moonpetal", "Fireroot")
	t:assertNotNil(recipe, "Moonpetal+Fireroot reverse lookup")
	if recipe then
		t:assertEqual(recipe.id, "TwilightPotion", "reverse lookup id")
	end
end

--- Order independence: every cross-ingredient recipe should be found with
--- either argument order.
function Tests.test_lookup_order_independence_all_cross(t)
	local crossRecipes = {
		{ "Fireroot",   "Moonpetal",   "TwilightPotion"  },
		{ "Moonpetal",  "Shadowmoss",  "PhantomDraught"  },
		{ "Moonpetal",  "Starbloom",   "AstralSerum"     },
		{ "Fireroot",   "Shadowmoss",  "InfernalMix"     },
		{ "Fireroot",   "Starbloom",   "SolarNectar"     },
		{ "Shadowmoss", "Starbloom",   "EclipseTincture" },
	}

	for _, combo in crossRecipes do
		local a, b, expectedId = combo[1], combo[2], combo[3]
		-- Forward
		local r1 = Recipes.lookup(a, b)
		t:assertNotNil(r1, a .. "+" .. b .. " forward")
		if r1 then t:assertEqual(r1.id, expectedId, a .. "+" .. b .. " forward id") end
		-- Reverse
		local r2 = Recipes.lookup(b, a)
		t:assertNotNil(r2, b .. "+" .. a .. " reverse")
		if r2 then t:assertEqual(r2.id, expectedId, b .. "+" .. a .. " reverse id") end
	end
end

--- Same-ingredient lookups work correctly.
function Tests.test_lookup_same_ingredient(t)
	local recipe = Recipes.lookup("Shadowmoss", "Shadowmoss")
	t:assertNotNil(recipe, "Shadowmoss+Shadowmoss lookup")
	if recipe then
		t:assertEqual(recipe.id, "VoidEssence", "same-ingredient id")
	end
end

--- Unknown combos return nil.
function Tests.test_lookup_unknown_combo_returns_nil(t)
	t:assertNil(Recipes.lookup("Moonpetal", "FakeHerb"), "unknown ingredient")
	t:assertNil(Recipes.lookup("Nothing", "Nowhere"), "both unknown")
	t:assertNil(Recipes.lookup("", ""), "empty strings")
end

---------------------------------------------------------------------------
-- calculateValue() tests
---------------------------------------------------------------------------

--- Base case: Common rarity (index 1, mult=1), Basic cauldron (level 1, bonus=1.0).
--- Value should equal the recipe's baseValue exactly.
function Tests.test_calculate_value_base_case(t)
	local recipe = Recipes.Map["Moonpetal+Moonpetal"]  -- baseValue = 25
	local value = Recipes.calculateValue(recipe, 1, 1, 1)
	-- Common mult=1, Common mult=1, Basic bonus=1.0 => 25 * 1 * 1 * 1.0 = 25
	t:assertEqual(value, 25, "base case value")
end

--- Uncommon rarity (index 2, mult=2) on both ingredients, Basic cauldron.
function Tests.test_calculate_value_uncommon_both(t)
	local recipe = Recipes.Map["Moonpetal+Moonpetal"]  -- baseValue = 25
	local value = Recipes.calculateValue(recipe, 2, 2, 1)
	-- 25 * 2 * 2 * 1.0 = 100
	t:assertEqual(value, 100, "uncommon both value")
end

--- Mixed rarity: Common + Rare, Gold cauldron (level 4, bonus=1.35).
function Tests.test_calculate_value_mixed_rarity_gold_cauldron(t)
	local recipe = Recipes.Map["Fireroot+Moonpetal"]  -- baseValue = 30
	local value = Recipes.calculateValue(recipe, 1, 3, 4)
	-- 30 * 1 * 5 * 1.35 = 202.5 => floor = 202
	t:assertEqual(value, 202, "mixed rarity gold cauldron")
end

--- Legendary rarity (index 5, mult=50) on one ingredient, Legendary cauldron (level 5, bonus=1.5).
function Tests.test_calculate_value_legendary_legendary(t)
	local recipe = Recipes.Map["Starbloom+Starbloom"]  -- baseValue = 75
	local value = Recipes.calculateValue(recipe, 5, 1, 5)
	-- 75 * 50 * 1 * 1.5 = 5625
	t:assertEqual(value, 5625, "legendary ingredient + legendary cauldron")
end

--- Both Legendary rarity, Legendary cauldron — maximum possible value.
function Tests.test_calculate_value_max_possible(t)
	local recipe = Recipes.Map["Starbloom+Starbloom"]  -- baseValue = 75 (highest)
	local value = Recipes.calculateValue(recipe, 5, 5, 5)
	-- 75 * 50 * 50 * 1.5 = 281250
	t:assertEqual(value, 281250, "max possible value")
end

--- Invalid rarity index falls back to multiplier 1 (default path).
function Tests.test_calculate_value_invalid_rarity_defaults(t)
	local recipe = Recipes.Map["Moonpetal+Moonpetal"]  -- baseValue = 25
	local value = Recipes.calculateValue(recipe, 99, 1, 1)
	-- tier[99] is nil => mult defaults to 1; 25 * 1 * 1 * 1.0 = 25
	t:assertEqual(value, 25, "invalid rarity defaults to 1")
end

--- Invalid cauldron level falls back to bonus 1.0 (default path).
function Tests.test_calculate_value_invalid_cauldron_defaults(t)
	local recipe = Recipes.Map["Moonpetal+Moonpetal"]  -- baseValue = 25
	local value = Recipes.calculateValue(recipe, 1, 1, 99)
	-- cauldron[99] is nil => bonus defaults to 1.0; 25 * 1 * 1 * 1.0 = 25
	t:assertEqual(value, 25, "invalid cauldron defaults to 1.0")
end

--- calculateValue always returns an integer (math.floor).
function Tests.test_calculate_value_returns_integer(t)
	-- Pick a combo that produces a fractional intermediate: 30 * 1 * 5 * 1.35 = 202.5
	local recipe = Recipes.Map["Fireroot+Moonpetal"]
	local value = Recipes.calculateValue(recipe, 1, 3, 4)
	t:assertEqual(value, math.floor(value), "value is integer")
end

return Tests
