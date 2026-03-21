--[[
	DataIntegrityTests.luau
	Cross-module data integrity validation.

	Catches bugs where one module's data references another module's data
	that doesn't exist (e.g., a recipe referencing a deleted ingredient,
	a cosmetic default pointing to a removed ID, etc.).

	Also validates invariants that span multiple modules.
]]

local function requireShared(name: string)
	local root = script.Parent.Parent
	local shared = root:FindFirstChild("src") and root.src:FindFirstChild("shared")
	if shared then
		local mod = shared:FindFirstChild(name)
		if mod then return require(mod) end
	end
	local sss = game:GetService("ServerScriptService")
	local server = sss:FindFirstChild("Server") or sss:FindFirstChild("src")
	if server then
		local s2 = server:FindFirstChild("shared") or server.Parent:FindFirstChild("Shared")
		if s2 then
			local mod = s2:FindFirstChild(name)
			if mod then return require(mod) end
		end
	end
	local rs = game:GetService("ReplicatedStorage")
	local rsShared = rs:FindFirstChild("Shared")
	if rsShared then
		local mod = rsShared:FindFirstChild(name)
		if mod then return require(mod) end
	end
	error("[Test] Could not find shared module: " .. name)
end

local Config          = requireShared("Config")
local Ingredients     = requireShared("Ingredients")
local Recipes         = requireShared("Recipes")
local Cosmetics       = requireShared("Cosmetics")
local GamePasses      = requireShared("GamePasses")
local Journal         = requireShared("Journal")
local Network         = requireShared("Network")
local Strings         = requireShared("Strings")
local SeasonalContent = requireShared("SeasonalContent")

local Tests = {}

-- Known base ingredient IDs
local BASE_IDS = { "Moonpetal", "Fireroot", "Shadowmoss", "Starbloom" }

---------------------------------------------------------------------------
-- Recipe ↔ Ingredient cross-references
---------------------------------------------------------------------------

function Tests.test_all_recipe_keys_use_valid_ingredients(t)
	local ingredientSet: { [string]: boolean } = {}
	for _, id in BASE_IDS do ingredientSet[id] = true end

	for key, _ in Recipes.Map do
		-- Keys are formatted as "IngredientA+IngredientB"
		local a, b = string.match(key, "^(.+)%+(.+)$")
		t:assertNotNil(a, "recipe key '" .. key .. "' has valid + format")
		if a and b then
			t:assertTrue(ingredientSet[a], "recipe key ingredient '" .. a .. "' exists in Ingredients")
			t:assertTrue(ingredientSet[b], "recipe key ingredient '" .. b .. "' exists in Ingredients")
		end
	end
end

function Tests.test_all_ingredient_pairs_have_recipes(t)
	-- With 4 ingredients, we should have C(4,2) + 4 = 10 recipes
	-- (6 cross-combos + 4 same-ingredient combos)
	local expectedCount = 0
	for i = 1, #BASE_IDS do
		for j = i, #BASE_IDS do
			expectedCount += 1
			local a = BASE_IDS[i]
			local b = BASE_IDS[j]
			-- Keys are alphabetically sorted
			local key
			if a <= b then
				key = a .. "+" .. b
			else
				key = b .. "+" .. a
			end
			t:assertNotNil(Recipes.Map[key], "recipe for " .. key .. " exists")
		end
	end
	t:assertEqual(expectedCount, 10, "expected 10 ingredient pair combos")
end

---------------------------------------------------------------------------
-- Recipe ↔ Journal cross-references
---------------------------------------------------------------------------

function Tests.test_every_recipe_has_journal_note(t)
	for _, recipe in Recipes.Map do
		t:assertNotNil(
			Journal.RecipeNotes[recipe.id],
			"recipe " .. recipe.id .. " has Journal.RecipeNotes entry"
		)
	end
end

function Tests.test_every_ingredient_has_journal_note(t)
	for _, id in BASE_IDS do
		t:assertNotNil(
			Journal.IngredientNotes[id],
			"ingredient " .. id .. " has Journal.IngredientNotes entry"
		)
	end
end

---------------------------------------------------------------------------
-- Config ↔ Strings cross-references
---------------------------------------------------------------------------

function Tests.test_every_mutation_tier_has_harvest_string(t)
	for _, tier in Config.MUTATION_TIERS do
		local key = "HARVESTED_" .. string.upper(tier.name)
		t:assertNotNil(Strings[key], "Strings." .. key .. " exists for tier " .. tier.name)
	end
end

function Tests.test_every_mutation_tier_has_odds_string(t)
	for _, tier in Config.MUTATION_TIERS do
		local key = "ODDS_" .. string.upper(tier.name)
		t:assertNotNil(Strings[key], "Strings." .. key .. " exists for tier " .. tier.name)
	end
end

function Tests.test_every_mutation_tier_has_journal_rarity_note(t)
	for _, tier in Config.MUTATION_TIERS do
		t:assertNotNil(
			Journal.RarityNotes[tier.name],
			"Journal.RarityNotes[" .. tier.name .. "] exists"
		)
	end
end

---------------------------------------------------------------------------
-- Cosmetics ↔ GamePasses cross-references
---------------------------------------------------------------------------

function Tests.test_vip_pass_celestial_theme_exists_in_cosmetics(t)
	-- VIP pass promises "Celestial Lab theme" — verify that cosmetic exists
	local found = Cosmetics.BY_ID["theme_celestial"]
	t:assertNotNil(found, "theme_celestial cosmetic exists (referenced by VIP pass)")
	if found then
		t:assertEqual(found.category, "LabTheme", "theme_celestial is a LabTheme")
	end
end

function Tests.test_cosmetic_defaults_all_exist(t)
	for category, id in Cosmetics.DEFAULTS do
		local def = Cosmetics.BY_ID[id]
		t:assertNotNil(def, "default cosmetic '" .. id .. "' for " .. category .. " exists")
		if def then
			t:assertEqual(def.category, category, "default '" .. id .. "' category matches")
			t:assertEqual(def.price, 0, "default '" .. id .. "' is free")
		end
	end
end

function Tests.test_cosmetic_product_ids_are_unique(t)
	local seen: { [number]: string } = {}
	for _, def in Cosmetics.ALL do
		if def.productId ~= 0 then
			if seen[def.productId] then
				t:fail("duplicate productId " .. def.productId .. " used by " .. seen[def.productId] .. " and " .. def.id)
			end
			seen[def.productId] = def.id
		end
	end
end

function Tests.test_game_pass_ids_dont_collide_with_cosmetic_product_ids(t)
	local cosmeticProductIds: { [number]: boolean } = {}
	for _, def in Cosmetics.ALL do
		if def.productId ~= 0 then
			cosmeticProductIds[def.productId] = true
		end
	end

	for _, def in GamePasses.DEFS do
		t:assertFalse(
			cosmeticProductIds[def.id],
			"game pass id " .. def.id .. " (" .. def.name .. ") must not collide with any cosmetic productId"
		)
	end
end

---------------------------------------------------------------------------
-- Economy balance invariants
---------------------------------------------------------------------------

function Tests.test_starting_essence_can_buy_cheapest_seed(t)
	-- New players should be able to afford at least one seed immediately
	local cheapest = math.huge
	for _, id in BASE_IDS do
		local def = Ingredients[id]
		if def and def.seedCost < cheapest then
			cheapest = def.seedCost
		end
	end
	t:assertTrue(
		Config.STARTING_ESSENCE >= cheapest,
		"STARTING_ESSENCE (" .. Config.STARTING_ESSENCE .. ") >= cheapest seed (" .. cheapest .. ")"
	)
end

function Tests.test_starting_essence_cannot_buy_most_expensive_ingredient(t)
	-- Scarcity design: starting essence shouldn't buy the top ingredient
	local mostExpensive = 0
	for _, id in BASE_IDS do
		local def = Ingredients[id]
		if def and def.seedCost > mostExpensive then
			mostExpensive = def.seedCost
		end
	end
	t:assertTrue(
		Config.STARTING_ESSENCE < mostExpensive,
		"STARTING_ESSENCE (" .. Config.STARTING_ESSENCE .. ") < most expensive seed (" .. mostExpensive .. ")"
	)
end

function Tests.test_ingredient_value_exceeds_seed_cost(t)
	-- Every ingredient should be profitable at minimum (Common rarity)
	-- to prevent dead-end loops where players can't progress
	for _, id in BASE_IDS do
		local def = Ingredients[id]
		if not def then continue end
		t:assertTrue(
			def.baseValue > def.seedCost,
			id .. " baseValue (" .. def.baseValue .. ") > seedCost (" .. def.seedCost .. ") — planting must be profitable"
		)
	end
end

function Tests.test_speed_brew_multiplier_is_between_0_and_1(t)
	t:assertTrue(Config.SPEED_BREW_MULTIPLIER > 0, "SPEED_BREW_MULTIPLIER > 0")
	t:assertTrue(Config.SPEED_BREW_MULTIPLIER < 1, "SPEED_BREW_MULTIPLIER < 1 (makes brewing faster)")
end

function Tests.test_ad_reward_is_meaningful_but_not_broken(t)
	-- Ad reward should be noticeable but not game-breaking
	t:assertTrue(Config.AD_REWARD_ESSENCE >= 10, "AD_REWARD_ESSENCE >= 10 (meaningful)")
	t:assertTrue(Config.AD_REWARD_ESSENCE <= 500, "AD_REWARD_ESSENCE <= 500 (not game-breaking)")
end

function Tests.test_ad_cooldown_prevents_spam(t)
	t:assertTrue(Config.AD_COOLDOWN_SECONDS >= 60, "AD_COOLDOWN_SECONDS >= 60 (prevents spam)")
end

---------------------------------------------------------------------------
-- Network ↔ Module consistency
---------------------------------------------------------------------------

function Tests.test_all_network_events_are_strings(t)
	local names = Network.getAllEventNames()
	for _, name in names do
		t:assertType(name, "string", "event name type")
		t:assertTrue(#name > 0, "event name non-empty")
	end
end

---------------------------------------------------------------------------
-- Seasonal ↔ Base data isolation
---------------------------------------------------------------------------

function Tests.test_seasonal_ingredients_dont_collide_with_base(t)
	local baseSet: { [string]: boolean } = {}
	for _, id in BASE_IDS do baseSet[id] = true end

	for _, event in SeasonalContent.EVENTS do
		for _, ing in event.ingredients do
			t:assertFalse(baseSet[ing.id], "seasonal ingredient '" .. ing.id .. "' must not match a base ingredient")
		end
	end
end

function Tests.test_seasonal_recipes_dont_collide_with_base_recipes(t)
	local baseRecipeIds: { [string]: boolean } = {}
	for _, recipe in Recipes.Map do
		baseRecipeIds[recipe.id] = true
	end

	for _, event in SeasonalContent.EVENTS do
		for _, recipe in event.recipes do
			t:assertFalse(baseRecipeIds[recipe.id], "seasonal recipe '" .. recipe.id .. "' must not match a base recipe")
		end
	end
end

return Tests
