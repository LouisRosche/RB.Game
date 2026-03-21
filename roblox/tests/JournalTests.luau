--[[
	JournalTests.luau
	Tests for roblox/src/shared/Journal.luau

	Validates:
	  - Every base ingredient has a science note in the Journal
	  - Every recipe has an alchemy note in the Journal
	  - Rarity notes exist for every mutation tier
	  - HowToPlay and FunFacts arrays are populated with non-empty strings
	  - No dangling references (Journal keys that don't match any ingredient/recipe)
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

local Journal     = requireShared("Journal")
local Ingredients = requireShared("Ingredients")
local Recipes     = requireShared("Recipes")
local Config      = requireShared("Config")

local Tests = {}

-- Known base ingredient IDs
local BASE_INGREDIENT_IDS = { "Moonpetal", "Fireroot", "Shadowmoss", "Starbloom" }

---------------------------------------------------------------------------
-- Ingredient notes
---------------------------------------------------------------------------

function Tests.test_every_ingredient_has_science_note(t)
	for _, id in BASE_INGREDIENT_IDS do
		local note = Journal.IngredientNotes[id]
		t:assertNotNil(note, "Journal.IngredientNotes[" .. id .. "] exists")
		if note then
			t:assertType(note, "string", id .. " note type")
			t:assertTrue(#note > 20, id .. " note is substantive (>20 chars)")
		end
	end
end

function Tests.test_ingredient_notes_reference_only_known_ingredients(t)
	for id, _ in Journal.IngredientNotes do
		local exists = false
		for _, knownId in BASE_INGREDIENT_IDS do
			if id == knownId then
				exists = true
				break
			end
		end
		t:assertTrue(exists, "Journal.IngredientNotes key '" .. id .. "' matches a known ingredient")
	end
end

function Tests.test_ingredient_note_count_matches(t)
	local count = 0
	for _ in Journal.IngredientNotes do count += 1 end
	t:assertEqual(count, #BASE_INGREDIENT_IDS, "IngredientNotes count == base ingredient count")
end

---------------------------------------------------------------------------
-- Recipe notes
---------------------------------------------------------------------------

function Tests.test_every_recipe_has_alchemy_note(t)
	for _, recipe in Recipes.Map do
		local note = Journal.RecipeNotes[recipe.id]
		t:assertNotNil(note, "Journal.RecipeNotes[" .. recipe.id .. "] exists")
		if note then
			t:assertType(note, "string", recipe.id .. " note type")
			t:assertTrue(#note > 20, recipe.id .. " note is substantive (>20 chars)")
		end
	end
end

function Tests.test_recipe_notes_reference_only_known_recipes(t)
	-- Build set of known recipe IDs
	local knownIds: { [string]: boolean } = {}
	for _, recipe in Recipes.Map do
		knownIds[recipe.id] = true
	end

	for id, _ in Journal.RecipeNotes do
		t:assertTrue(knownIds[id], "Journal.RecipeNotes key '" .. id .. "' matches a known recipe")
	end
end

function Tests.test_recipe_note_count_matches(t)
	local noteCount = 0
	for _ in Journal.RecipeNotes do noteCount += 1 end

	local recipeCount = 0
	for _ in Recipes.Map do recipeCount += 1 end

	t:assertEqual(noteCount, recipeCount, "RecipeNotes count == recipe count")
end

---------------------------------------------------------------------------
-- Rarity notes
---------------------------------------------------------------------------

function Tests.test_rarity_notes_exist_for_all_tiers(t)
	for _, tier in Config.MUTATION_TIERS do
		local note = Journal.RarityNotes[tier.name]
		t:assertNotNil(note, "Journal.RarityNotes[" .. tier.name .. "] exists")
		if note then
			t:assertType(note, "string", tier.name .. " rarity note type")
			t:assertTrue(#note > 10, tier.name .. " rarity note is substantive")
		end
	end
end

function Tests.test_rarity_note_count_matches_tier_count(t)
	local noteCount = 0
	for _ in Journal.RarityNotes do noteCount += 1 end
	t:assertEqual(noteCount, #Config.MUTATION_TIERS, "RarityNotes count == mutation tier count")
end

---------------------------------------------------------------------------
-- HowToPlay
---------------------------------------------------------------------------

function Tests.test_how_to_play_is_populated(t)
	t:assertType(Journal.HowToPlay, "table", "HowToPlay type")
	t:assertTrue(#Journal.HowToPlay >= 3, "HowToPlay has at least 3 entries")
end

function Tests.test_how_to_play_entries_are_non_empty_strings(t)
	for i, entry in Journal.HowToPlay do
		t:assertType(entry, "string", "HowToPlay[" .. i .. "] type")
		t:assertTrue(#entry > 0, "HowToPlay[" .. i .. "] non-empty")
	end
end

---------------------------------------------------------------------------
-- FunFacts
---------------------------------------------------------------------------

function Tests.test_fun_facts_is_populated(t)
	t:assertType(Journal.FunFacts, "table", "FunFacts type")
	t:assertTrue(#Journal.FunFacts >= 5, "FunFacts has at least 5 entries")
end

function Tests.test_fun_facts_entries_are_non_empty_strings(t)
	for i, entry in Journal.FunFacts do
		t:assertType(entry, "string", "FunFacts[" .. i .. "] type")
		t:assertTrue(#entry > 0, "FunFacts[" .. i .. "] non-empty")
	end
end

function Tests.test_fun_facts_are_unique(t)
	local seen: { [string]: boolean } = {}
	for _, fact in Journal.FunFacts do
		t:assertNil(seen[fact], "duplicate fun fact: " .. string.sub(fact, 1, 40) .. "...")
		seen[fact] = true
	end
end

return Tests
