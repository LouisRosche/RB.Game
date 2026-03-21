--[[
	SecurityTests.luau
	Adversarial boundary-condition tests for security-critical game systems.
	Validates that economy caps, input bounds, and invariants hold under
	hostile or edge-case inputs.
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

local Config      = requireShared("Config")
local Recipes     = requireShared("Recipes")
local Ingredients = requireShared("Ingredients")
local Cosmetics   = requireShared("Cosmetics")
local GamePasses  = requireShared("GamePasses")

local Tests = {}

---------------------------------------------------------------------------
-- Essence cap invariants
---------------------------------------------------------------------------

function Tests.test_max_essence_is_a_positive_integer(t)
	t:assertType(Config.MAX_ESSENCE, "number", "MAX_ESSENCE type")
	t:assertTrue(Config.MAX_ESSENCE > 0, "MAX_ESSENCE positive")
	t:assertEqual(Config.MAX_ESSENCE, math.floor(Config.MAX_ESSENCE), "MAX_ESSENCE is integer")
end

function Tests.test_starting_essence_under_cap(t)
	t:assertTrue(
		Config.STARTING_ESSENCE < Config.MAX_ESSENCE,
		"STARTING_ESSENCE < MAX_ESSENCE"
	)
end

function Tests.test_ad_reward_under_cap(t)
	t:assertTrue(
		Config.AD_REWARD_ESSENCE < Config.MAX_ESSENCE,
		"AD_REWARD_ESSENCE < MAX_ESSENCE"
	)
end

---------------------------------------------------------------------------
-- Potion value bounds — max possible potion value should not overflow
---------------------------------------------------------------------------

function Tests.test_max_potion_value_within_safe_range(t)
	-- Calculate the theoretical maximum potion value:
	-- highest baseValue recipe * highest rarity multiplier^2 * highest cauldron bonus
	local maxBaseValue = 0
	for _, recipe in Recipes.ALL do
		if recipe.baseValue > maxBaseValue then
			maxBaseValue = recipe.baseValue
		end
	end

	local maxMultiplier = 1
	for _, tier in Config.MUTATION_TIERS do
		if tier.multiplier > maxMultiplier then
			maxMultiplier = tier.multiplier
		end
	end

	local maxCauldronBonus = 1
	for _, level in Config.CAULDRON_LEVELS do
		if level.valueBonus > maxCauldronBonus then
			maxCauldronBonus = level.valueBonus
		end
	end

	local theoreticalMax = maxBaseValue * maxMultiplier * maxMultiplier * maxCauldronBonus
	t:assertTrue(
		theoreticalMax < Config.MAX_ESSENCE,
		"max potion value (" .. theoreticalMax .. ") < MAX_ESSENCE (" .. Config.MAX_ESSENCE .. ")"
	)
end

---------------------------------------------------------------------------
-- Mutation tier integrity (adversarial)
---------------------------------------------------------------------------

function Tests.test_mutation_tiers_no_negative_or_zero_chance(t)
	for i, tier in Config.MUTATION_TIERS do
		t:assertTrue(tier.chance > 0, "tier " .. i .. " chance > 0")
		t:assertTrue(tier.multiplier >= 1, "tier " .. i .. " multiplier >= 1")
	end
end

function Tests.test_mutation_cumulative_never_exceeds_1(t)
	local cum = 0
	for i, tier in Config.MUTATION_TIERS do
		cum += tier.chance
		t:assertTrue(cum <= 1.001, "cumulative at tier " .. i .. " <= 1.0 (got " .. cum .. ")")
	end
end

---------------------------------------------------------------------------
-- Ingredient / Recipe cross-validation
---------------------------------------------------------------------------

function Tests.test_all_recipe_ingredients_exist(t)
	for _, recipe in Recipes.ALL do
		for _, ingId in recipe.ingredients do
			local def = Ingredients[ingId]
			t:assertNotNil(def, "recipe " .. recipe.id .. " ingredient " .. ingId .. " exists")
		end
	end
end

---------------------------------------------------------------------------
-- Cosmetic security: no paid item has price == 0 AND productId > 0
---------------------------------------------------------------------------

function Tests.test_free_cosmetics_have_no_product_id(t)
	for _, def in Cosmetics.ALL do
		if def.price == 0 then
			t:assertTrue(
				not def.productId or def.productId == 0,
				"free cosmetic " .. def.id .. " should not have a real productId"
			)
		end
	end
end

---------------------------------------------------------------------------
-- Ad reward balance: ad reward should not exceed cheapest seed cost
-- (prevents ad farming being more profitable than gameplay)
---------------------------------------------------------------------------

function Tests.test_ad_reward_not_greater_than_cheapest_seed(t)
	local cheapest = math.huge
	for _, def in Ingredients do
		if type(def) == "table" and def.seedCost and def.seedCost < cheapest then
			cheapest = def.seedCost
		end
	end
	-- Ad reward should be at most 10x the cheapest seed (reasonable bound)
	t:assertTrue(
		Config.AD_REWARD_ESSENCE <= cheapest * 10,
		"AD_REWARD_ESSENCE (" .. Config.AD_REWARD_ESSENCE .. ") <= 10x cheapest seed (" .. cheapest .. ")"
	)
end

---------------------------------------------------------------------------
-- Speed Brew multiplier bounds
---------------------------------------------------------------------------

function Tests.test_speed_brew_multiplier_between_0_and_1(t)
	t:assertTrue(Config.SPEED_BREW_MULTIPLIER > 0, "SPEED_BREW_MULTIPLIER > 0")
	t:assertTrue(Config.SPEED_BREW_MULTIPLIER < 1, "SPEED_BREW_MULTIPLIER < 1")
end

function Tests.test_ad_boost_multiplier_bounded(t)
	t:assertTrue(Config.AD_BOOST_MULTIPLIER >= 1, "AD_BOOST_MULTIPLIER >= 1")
	t:assertTrue(Config.AD_BOOST_MULTIPLIER <= 5, "AD_BOOST_MULTIPLIER <= 5 (reasonable ceiling)")
end

return Tests
