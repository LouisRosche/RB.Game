--[[
	EconomyTests.luau
	Tests for economy-related shared modules:
	  - Config.luau    (prices, upgrade scaling, mutation tiers)
	  - GamePasses.luau (pass definitions, hasPass helper)
	  - Cosmetics.luau  (item definitions, categories, defaults)
]]

local Config    = require(script.Parent.Parent:FindFirstChild("src") and script.Parent.Parent.src.shared.Config or game.ServerScriptService:FindFirstChild("src") and game.ServerScriptService.src.shared.Config or script.Parent.Parent.Parent.src.shared.Config)
local GamePasses = require(script.Parent.Parent:FindFirstChild("src") and script.Parent.Parent.src.shared.GamePasses or game.ServerScriptService:FindFirstChild("src") and game.ServerScriptService.src.shared.GamePasses or script.Parent.Parent.Parent.src.shared.GamePasses)
local Cosmetics  = require(script.Parent.Parent:FindFirstChild("src") and script.Parent.Parent.src.shared.Cosmetics or game.ServerScriptService:FindFirstChild("src") and game.ServerScriptService.src.shared.Cosmetics or script.Parent.Parent.Parent.src.shared.Cosmetics)
local Ingredients = require(script.Parent.Parent:FindFirstChild("src") and script.Parent.Parent.src.shared.Ingredients or game.ServerScriptService:FindFirstChild("src") and game.ServerScriptService.src.shared.Ingredients or script.Parent.Parent.Parent.src.shared.Ingredients)

local Tests = {}

---------------------------------------------------------------------------
-- Config: Starting values
---------------------------------------------------------------------------

function Tests.test_starting_essence_is_positive(t)
	t:assertPositive(Config.STARTING_ESSENCE, "STARTING_ESSENCE")
end

---------------------------------------------------------------------------
-- Config: Lab levels
---------------------------------------------------------------------------

function Tests.test_lab_level_count(t)
	local count = 0
	for _ in Config.LAB_LEVELS do count += 1 end
	t:assertEqual(count, Config.MAX_LAB_LEVEL, "lab level count == MAX_LAB_LEVEL")
end

function Tests.test_lab_level_costs_are_non_negative(t)
	for i, level in Config.LAB_LEVELS do
		t:assertType(level.cost, "number", "lab level " .. i .. " cost type")
		t:assertTrue(level.cost >= 0, "lab level " .. i .. " cost >= 0")
	end
end

function Tests.test_lab_level_costs_increase(t)
	for i = 2, Config.MAX_LAB_LEVEL do
		local prev = Config.LAB_LEVELS[i - 1].cost
		local curr = Config.LAB_LEVELS[i].cost
		t:assertTrue(curr > prev, "lab level " .. i .. " cost > level " .. (i - 1))
	end
end

function Tests.test_lab_level_plots_increase(t)
	for i = 2, Config.MAX_LAB_LEVEL do
		local prev = Config.LAB_LEVELS[i - 1].plots
		local curr = Config.LAB_LEVELS[i].plots
		t:assertTrue(curr > prev, "lab level " .. i .. " plots > level " .. (i - 1))
	end
end

function Tests.test_lab_level_1_is_free(t)
	t:assertEqual(Config.LAB_LEVELS[1].cost, 0, "lab level 1 cost")
end

function Tests.test_lab_levels_have_names(t)
	for i, level in Config.LAB_LEVELS do
		t:assertType(level.name, "string", "lab level " .. i .. " name type")
		t:assertTrue(#level.name > 0, "lab level " .. i .. " name non-empty")
	end
end

---------------------------------------------------------------------------
-- Config: Cauldron levels
---------------------------------------------------------------------------

function Tests.test_cauldron_level_count(t)
	local count = 0
	for _ in Config.CAULDRON_LEVELS do count += 1 end
	t:assertEqual(count, Config.MAX_CAULDRON_LEVEL, "cauldron level count == MAX_CAULDRON_LEVEL")
end

function Tests.test_cauldron_costs_are_non_negative(t)
	for i, level in Config.CAULDRON_LEVELS do
		t:assertType(level.cost, "number", "cauldron " .. i .. " cost type")
		t:assertTrue(level.cost >= 0, "cauldron " .. i .. " cost >= 0")
	end
end

function Tests.test_cauldron_costs_increase(t)
	for i = 2, Config.MAX_CAULDRON_LEVEL do
		local prev = Config.CAULDRON_LEVELS[i - 1].cost
		local curr = Config.CAULDRON_LEVELS[i].cost
		t:assertTrue(curr > prev, "cauldron " .. i .. " cost > cauldron " .. (i - 1))
	end
end

function Tests.test_cauldron_brew_times_decrease(t)
	for i = 2, Config.MAX_CAULDRON_LEVEL do
		local prev = Config.CAULDRON_LEVELS[i - 1].brewTime
		local curr = Config.CAULDRON_LEVELS[i].brewTime
		t:assertTrue(curr < prev, "cauldron " .. i .. " brewTime < cauldron " .. (i - 1))
	end
end

function Tests.test_cauldron_value_bonuses_increase(t)
	for i = 2, Config.MAX_CAULDRON_LEVEL do
		local prev = Config.CAULDRON_LEVELS[i - 1].valueBonus
		local curr = Config.CAULDRON_LEVELS[i].valueBonus
		t:assertTrue(curr > prev, "cauldron " .. i .. " valueBonus > cauldron " .. (i - 1))
	end
end

function Tests.test_cauldron_level_1_is_free(t)
	t:assertEqual(Config.CAULDRON_LEVELS[1].cost, 0, "cauldron level 1 cost")
end

function Tests.test_cauldron_brew_times_are_positive(t)
	for i, level in Config.CAULDRON_LEVELS do
		t:assertPositive(level.brewTime, "cauldron " .. i .. " brewTime")
	end
end

function Tests.test_cauldron_value_bonuses_are_at_least_1(t)
	for i, level in Config.CAULDRON_LEVELS do
		t:assertTrue(level.valueBonus >= 1.0, "cauldron " .. i .. " valueBonus >= 1.0")
	end
end

---------------------------------------------------------------------------
-- Config: Mutation tiers
---------------------------------------------------------------------------

function Tests.test_mutation_tier_chances_sum_to_1(t)
	local sum = 0
	for _, tier in Config.MUTATION_TIERS do
		sum += tier.chance
	end
	-- Allow floating-point tolerance
	t:assertTrue(math.abs(sum - 1.0) < 0.001, "mutation tier chances sum to 1.0 (got " .. sum .. ")")
end

function Tests.test_mutation_tier_multipliers_are_positive(t)
	for i, tier in ipairs(Config.MUTATION_TIERS) do
		t:assertPositive(tier.multiplier, "mutation tier " .. i .. " multiplier")
	end
end

function Tests.test_mutation_tier_chances_are_positive(t)
	for i, tier in ipairs(Config.MUTATION_TIERS) do
		t:assertPositive(tier.chance, "mutation tier " .. i .. " chance")
	end
end

function Tests.test_mutation_tiers_ordered_by_decreasing_chance(t)
	for i = 2, #Config.MUTATION_TIERS do
		local prev = Config.MUTATION_TIERS[i - 1].chance
		local curr = Config.MUTATION_TIERS[i].chance
		t:assertTrue(curr <= prev, "tier " .. i .. " chance <= tier " .. (i - 1))
	end
end

function Tests.test_mutation_tiers_ordered_by_increasing_multiplier(t)
	for i = 2, #Config.MUTATION_TIERS do
		local prev = Config.MUTATION_TIERS[i - 1].multiplier
		local curr = Config.MUTATION_TIERS[i].multiplier
		t:assertTrue(curr > prev, "tier " .. i .. " multiplier > tier " .. (i - 1))
	end
end

function Tests.test_mutation_tiers_have_names(t)
	for i, tier in ipairs(Config.MUTATION_TIERS) do
		t:assertType(tier.name, "string", "tier " .. i .. " name type")
		t:assertTrue(#tier.name > 0, "tier " .. i .. " name non-empty")
	end
end

---------------------------------------------------------------------------
-- Config: Inventory caps
---------------------------------------------------------------------------

function Tests.test_inventory_caps_are_positive(t)
	t:assertPositive(Config.MAX_INGREDIENTS, "MAX_INGREDIENTS")
	t:assertPositive(Config.MAX_POTIONS, "MAX_POTIONS")
	t:assertPositive(Config.MAX_SEEDS, "MAX_SEEDS")
end

---------------------------------------------------------------------------
-- Ingredients: prices and values
---------------------------------------------------------------------------

local INGREDIENT_IDS = { "Moonpetal", "Fireroot", "Shadowmoss", "Starbloom" }

function Tests.test_ingredient_seed_costs_are_positive(t)
	for _, id in INGREDIENT_IDS do
		local def = Ingredients[id]
		t:assertNotNil(def, id .. " exists")
		if def then
			t:assertPositive(def.seedCost, id .. " seedCost")
		end
	end
end

function Tests.test_ingredient_base_values_are_positive(t)
	for _, id in INGREDIENT_IDS do
		local def = Ingredients[id]
		if def then
			t:assertPositive(def.baseValue, id .. " baseValue")
		end
	end
end

function Tests.test_ingredient_growth_times_are_positive(t)
	for _, id in INGREDIENT_IDS do
		local def = Ingredients[id]
		if def then
			t:assertPositive(def.growthTime, id .. " growthTime")
		end
	end
end

function Tests.test_ingredient_seed_costs_scale_with_tier(t)
	-- Costs should increase: Moonpetal < Fireroot < Shadowmoss < Starbloom
	for i = 2, #INGREDIENT_IDS do
		local prev = Ingredients[INGREDIENT_IDS[i - 1]].seedCost
		local curr = Ingredients[INGREDIENT_IDS[i]].seedCost
		t:assertTrue(curr > prev, INGREDIENT_IDS[i] .. " seedCost > " .. INGREDIENT_IDS[i - 1])
	end
end

---------------------------------------------------------------------------
-- GamePasses
---------------------------------------------------------------------------

function Tests.test_game_pass_defs_count(t)
	t:assertEqual(#GamePasses.DEFS, 3, "game pass count")
end

function Tests.test_game_pass_defs_well_formed(t)
	for _, def in GamePasses.DEFS do
		t:assertType(def.id, "number", def.name .. " id type")
		t:assertPositive(def.id, def.name .. " id positive")
		t:assertType(def.name, "string", def.name .. " name type")
		t:assertTrue(#def.name > 0, def.name .. " name non-empty")
		t:assertType(def.price, "number", def.name .. " price type")
		t:assertPositive(def.price, def.name .. " price positive")
		t:assertType(def.description, "string", def.name .. " description type")
		t:assertTrue(#def.description > 0, def.name .. " description non-empty")
		t:assertType(def.benefits, "table", def.name .. " benefits type")
		t:assertTrue(#def.benefits > 0, def.name .. " has benefits")
	end
end

function Tests.test_game_pass_by_id_lookup(t)
	for _, def in GamePasses.DEFS do
		local found = GamePasses.BY_ID[def.id]
		t:assertNotNil(found, "BY_ID[" .. def.id .. "]")
		if found then
			t:assertEqual(found.name, def.name, "BY_ID lookup name matches")
		end
	end
end

function Tests.test_game_pass_ids_are_unique(t)
	local seen = {}
	for _, def in GamePasses.DEFS do
		t:assertNil(seen[def.id], "duplicate pass id " .. def.id)
		seen[def.id] = true
	end
end

function Tests.test_has_pass_returns_true_when_owned(t)
	local data = { OwnedPasses = { [tostring(GamePasses.SPEED_BREW)] = true } }
	t:assertTrue(GamePasses.hasPass(data, GamePasses.SPEED_BREW), "hasPass owned")
end

function Tests.test_has_pass_returns_false_when_not_owned(t)
	local data = { OwnedPasses = {} }
	t:assertFalse(GamePasses.hasPass(data, GamePasses.SPEED_BREW), "hasPass not owned")
end

function Tests.test_has_pass_returns_false_when_no_passes_table(t)
	local data = {}
	t:assertFalse(GamePasses.hasPass(data, GamePasses.SPEED_BREW), "hasPass no table")
end

---------------------------------------------------------------------------
-- Cosmetics
---------------------------------------------------------------------------

function Tests.test_cosmetics_all_is_populated(t)
	t:assertTrue(#Cosmetics.ALL > 0, "Cosmetics.ALL has items")
end

function Tests.test_cosmetics_have_valid_categories(t)
	local validCategories = { LabTheme = true, CauldronTint = true, HarvestParticles = true }
	for _, def in Cosmetics.ALL do
		t:assertTrue(validCategories[def.category], def.id .. " has valid category: " .. tostring(def.category))
	end
end

function Tests.test_cosmetics_have_non_negative_prices(t)
	for _, def in Cosmetics.ALL do
		t:assertType(def.price, "number", def.id .. " price type")
		t:assertTrue(def.price >= 0, def.id .. " price >= 0")
	end
end

function Tests.test_cosmetics_have_unique_ids(t)
	local seen = {}
	for _, def in Cosmetics.ALL do
		t:assertNil(seen[def.id], "duplicate cosmetic id: " .. def.id)
		seen[def.id] = true
	end
end

function Tests.test_cosmetics_by_id_lookup(t)
	for _, def in Cosmetics.ALL do
		local found = Cosmetics.BY_ID[def.id]
		t:assertNotNil(found, "BY_ID[" .. def.id .. "]")
		if found then
			t:assertEqual(found.name, def.name, "BY_ID name matches for " .. def.id)
		end
	end
end

function Tests.test_cosmetics_have_names_and_descriptions(t)
	for _, def in Cosmetics.ALL do
		t:assertType(def.name, "string", def.id .. " name type")
		t:assertTrue(#def.name > 0, def.id .. " name non-empty")
		t:assertType(def.description, "string", def.id .. " description type")
		t:assertTrue(#def.description > 0, def.id .. " description non-empty")
	end
end

function Tests.test_cosmetics_defaults_reference_existing_ids(t)
	for category, id in Cosmetics.DEFAULTS do
		local found = Cosmetics.BY_ID[id]
		t:assertNotNil(found, "default " .. category .. " = " .. id .. " exists")
		if found then
			t:assertEqual(found.category, category, "default " .. id .. " matches category")
		end
	end
end

function Tests.test_cosmetics_each_category_has_free_item(t)
	for _, category in { "LabTheme", "CauldronTint", "HarvestParticles" } do
		local items = Cosmetics.getCategory(category)
		local hasFree = false
		for _, def in items do
			if def.price == 0 then
				hasFree = true
				break
			end
		end
		t:assertTrue(hasFree, category .. " has at least one free item")
	end
end

function Tests.test_cosmetics_paid_items_have_product_ids(t)
	for _, def in Cosmetics.ALL do
		if def.price > 0 then
			t:assertPositive(def.productId, def.id .. " paid item has productId")
		end
	end
end

return Tests
