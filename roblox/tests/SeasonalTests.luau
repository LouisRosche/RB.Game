--[[
	SeasonalTests.luau
	Tests for roblox/src/shared/SeasonalContent.luau

	Validates:
	  - Season date ranges don't overlap
	  - Seasonal ingredients have valid fields
	  - Seasonal recipes reference ingredients that actually exist
	  - Lookup tables are correctly populated
]]

local function requireShared(name: string)
	-- Try relative path first (tests/ is sibling to src/)
	local root = script.Parent.Parent
	local shared = root:FindFirstChild("src") and root.src:FindFirstChild("shared")
	if shared then
		local mod = shared:FindFirstChild(name)
		if mod then return require(mod) end
	end
	-- Fallback: ServerScriptService layout
	local sss = game:GetService("ServerScriptService")
	local server = sss:FindFirstChild("Server") or sss:FindFirstChild("src")
	if server then
		local s2 = server:FindFirstChild("shared") or server.Parent:FindFirstChild("Shared")
		if s2 then
			local mod = s2:FindFirstChild(name)
			if mod then return require(mod) end
		end
	end
	-- Last resort: ReplicatedStorage.Shared
	local rs = game:GetService("ReplicatedStorage")
	local rsShared = rs:FindFirstChild("Shared")
	if rsShared then
		local mod = rsShared:FindFirstChild(name)
		if mod then return require(mod) end
	end
	error("[Test] Could not find shared module: " .. name)
end

local SeasonalContent = requireShared("SeasonalContent")
local Ingredients     = requireShared("Ingredients")

local Tests = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Converts a month+day pair into a day-of-year number (non-leap year).
--- For date range overlap checking purposes only.
local MONTH_DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function toDayOfYear(month: number, day: number): number
	local total = 0
	for m = 1, month - 1 do
		total += MONTH_DAYS[m]
	end
	return total + day
end

--- Returns true if two date ranges (which may wrap around year boundary) overlap.
local function rangesOverlap(
	s1Month: number, s1Day: number, e1Month: number, e1Day: number,
	s2Month: number, s2Day: number, e2Month: number, e2Day: number
): boolean
	-- Convert to day-of-year
	local s1 = toDayOfYear(s1Month, s1Day)
	local e1 = toDayOfYear(e1Month, e1Day)
	local s2 = toDayOfYear(s2Month, s2Day)
	local e2 = toDayOfYear(e2Month, e2Day)

	-- Expand ranges that wrap past Dec 31 into a 730-day space
	local ranges1 = {}
	local ranges2 = {}

	if s1 <= e1 then
		-- Normal range within one year
		table.insert(ranges1, { s1, e1 })
	else
		-- Wraps: e.g. Dec 25 -> Jan 8: treat as two segments
		table.insert(ranges1, { s1, 365 })
		table.insert(ranges1, { 1, e1 })
	end

	if s2 <= e2 then
		table.insert(ranges2, { s2, e2 })
	else
		table.insert(ranges2, { s2, 365 })
		table.insert(ranges2, { 1, e2 })
	end

	-- Check if any segment pair overlaps
	for _, r1 in ranges1 do
		for _, r2 in ranges2 do
			if r1[1] <= r2[2] and r2[1] <= r1[2] then
				return true
			end
		end
	end

	return false
end

---------------------------------------------------------------------------
-- Event structure tests
---------------------------------------------------------------------------

function Tests.test_events_exist(t)
	t:assertTrue(#SeasonalContent.EVENTS > 0, "at least one seasonal event exists")
end

function Tests.test_events_have_required_fields(t)
	for _, event in SeasonalContent.EVENTS do
		t:assertType(event.id, "string", event.id .. " id type")
		t:assertType(event.name, "string", event.id .. " name type")
		t:assertTrue(#event.name > 0, event.id .. " name non-empty")
		t:assertType(event.description, "string", event.id .. " description type")
		t:assertType(event.startMonth, "number", event.id .. " startMonth type")
		t:assertType(event.startDay, "number", event.id .. " startDay type")
		t:assertType(event.endMonth, "number", event.id .. " endMonth type")
		t:assertType(event.endDay, "number", event.id .. " endDay type")
		t:assertType(event.shopBannerText, "string", event.id .. " shopBannerText type")
	end
end

function Tests.test_events_have_valid_date_values(t)
	for _, event in SeasonalContent.EVENTS do
		t:assertTrue(event.startMonth >= 1 and event.startMonth <= 12,
			event.id .. " startMonth in 1-12")
		t:assertTrue(event.startDay >= 1 and event.startDay <= 31,
			event.id .. " startDay in 1-31")
		t:assertTrue(event.endMonth >= 1 and event.endMonth <= 12,
			event.id .. " endMonth in 1-12")
		t:assertTrue(event.endDay >= 1 and event.endDay <= 31,
			event.id .. " endDay in 1-31")
	end
end

function Tests.test_event_ids_are_unique(t)
	local seen = {}
	for _, event in SeasonalContent.EVENTS do
		t:assertNil(seen[event.id], "duplicate event id: " .. event.id)
		seen[event.id] = true
	end
end

---------------------------------------------------------------------------
-- Date range overlap
---------------------------------------------------------------------------

function Tests.test_season_date_ranges_do_not_overlap(t)
	local events = SeasonalContent.EVENTS
	for i = 1, #events do
		for j = i + 1, #events do
			local a = events[i]
			local b = events[j]
			local overlap = rangesOverlap(
				a.startMonth, a.startDay, a.endMonth, a.endDay,
				b.startMonth, b.startDay, b.endMonth, b.endDay
			)
			t:assertFalse(overlap, a.id .. " and " .. b.id .. " date ranges must not overlap")
		end
	end
end

---------------------------------------------------------------------------
-- Seasonal ingredients
---------------------------------------------------------------------------

function Tests.test_seasonal_ingredients_exist(t)
	for _, event in SeasonalContent.EVENTS do
		t:assertTrue(#event.ingredients > 0, event.id .. " has ingredients")
	end
end

function Tests.test_seasonal_ingredients_have_valid_fields(t)
	for _, event in SeasonalContent.EVENTS do
		for _, ing in event.ingredients do
			t:assertType(ing.id, "string", event.id .. "/" .. ing.id .. " id type")
			t:assertTrue(#ing.id > 0, event.id .. "/" .. ing.id .. " id non-empty")
			t:assertType(ing.displayName, "string", ing.id .. " displayName type")
			t:assertTrue(#ing.displayName > 0, ing.id .. " displayName non-empty")
			t:assertPositive(ing.seedCost, ing.id .. " seedCost")
			t:assertPositive(ing.growthTime, ing.id .. " growthTime")
			t:assertPositive(ing.baseValue, ing.id .. " baseValue")
			t:assertType(ing.scienceFact, "string", ing.id .. " scienceFact type")
			t:assertTrue(#ing.scienceFact > 0, ing.id .. " scienceFact non-empty")
		end
	end
end

function Tests.test_seasonal_ingredient_ids_unique_across_events(t)
	local seen = {}
	for _, event in SeasonalContent.EVENTS do
		for _, ing in event.ingredients do
			t:assertNil(seen[ing.id], "duplicate seasonal ingredient id: " .. ing.id)
			seen[ing.id] = true
		end
	end
end

function Tests.test_seasonal_ingredient_ids_dont_collide_with_base(t)
	local baseIds = { "Moonpetal", "Fireroot", "Shadowmoss", "Starbloom" }
	local baseSet = {}
	for _, id in baseIds do baseSet[id] = true end

	for _, event in SeasonalContent.EVENTS do
		for _, ing in event.ingredients do
			t:assertFalse(baseSet[ing.id], ing.id .. " must not collide with base ingredient")
		end
	end
end

function Tests.test_ingredient_by_id_lookup_populated(t)
	for _, event in SeasonalContent.EVENTS do
		for _, ing in event.ingredients do
			local found = SeasonalContent.INGREDIENT_BY_ID[ing.id]
			t:assertNotNil(found, "INGREDIENT_BY_ID[" .. ing.id .. "]")
			if found then
				t:assertEqual(found.displayName, ing.displayName, ing.id .. " lookup matches")
			end
		end
	end
end

---------------------------------------------------------------------------
-- Seasonal recipes
---------------------------------------------------------------------------

function Tests.test_seasonal_recipes_exist(t)
	for _, event in SeasonalContent.EVENTS do
		t:assertTrue(#event.recipes > 0, event.id .. " has recipes")
	end
end

function Tests.test_seasonal_recipes_have_valid_fields(t)
	for _, event in SeasonalContent.EVENTS do
		for _, recipe in event.recipes do
			t:assertType(recipe.id, "string", recipe.id .. " id type")
			t:assertTrue(#recipe.id > 0, recipe.id .. " id non-empty")
			t:assertType(recipe.displayName, "string", recipe.id .. " displayName type")
			t:assertTrue(#recipe.displayName > 0, recipe.id .. " displayName non-empty")
			t:assertPositive(recipe.baseValue, recipe.id .. " baseValue")
			t:assertType(recipe.description, "string", recipe.id .. " description type")
			t:assertType(recipe.scienceFact, "string", recipe.id .. " scienceFact type")
		end
	end
end

function Tests.test_seasonal_recipes_have_exactly_two_ingredients(t)
	for _, event in SeasonalContent.EVENTS do
		for _, recipe in event.recipes do
			t:assertType(recipe.ingredients, "table", recipe.id .. " ingredients type")
			t:assertEqual(#recipe.ingredients, 2, recipe.id .. " has exactly 2 ingredients")
		end
	end
end

function Tests.test_seasonal_recipes_reference_existing_ingredients(t)
	-- Build a set of all known ingredient IDs (base + seasonal)
	local allIngredientIds = {}
	-- Base ingredients
	for _, id in { "Moonpetal", "Fireroot", "Shadowmoss", "Starbloom" } do
		-- Use lowercase for seasonal ingredient ids which use snake_case
		allIngredientIds[id] = true
		allIngredientIds[string.lower(id)] = true
	end
	-- Seasonal ingredients
	for _, event in SeasonalContent.EVENTS do
		for _, ing in event.ingredients do
			allIngredientIds[ing.id] = true
		end
	end

	-- Check every recipe ingredient reference
	for _, event in SeasonalContent.EVENTS do
		for _, recipe in event.recipes do
			for _, ingId in recipe.ingredients do
				t:assertTrue(
					allIngredientIds[ingId],
					recipe.id .. " references ingredient '" .. ingId .. "' which must exist"
				)
			end
		end
	end
end

function Tests.test_seasonal_recipe_ids_unique_across_events(t)
	local seen = {}
	for _, event in SeasonalContent.EVENTS do
		for _, recipe in event.recipes do
			t:assertNil(seen[recipe.id], "duplicate seasonal recipe id: " .. recipe.id)
			seen[recipe.id] = true
		end
	end
end

function Tests.test_recipe_by_id_lookup_populated(t)
	for _, event in SeasonalContent.EVENTS do
		for _, recipe in event.recipes do
			local found = SeasonalContent.RECIPE_BY_ID[recipe.id]
			t:assertNotNil(found, "RECIPE_BY_ID[" .. recipe.id .. "]")
			if found then
				t:assertEqual(found.displayName, recipe.displayName, recipe.id .. " lookup matches")
			end
		end
	end
end

function Tests.test_by_id_event_lookup_populated(t)
	for _, event in SeasonalContent.EVENTS do
		local found = SeasonalContent.BY_ID[event.id]
		t:assertNotNil(found, "BY_ID[" .. event.id .. "]")
		if found then
			t:assertEqual(found.name, event.name, event.id .. " event lookup matches")
		end
	end
end

return Tests
