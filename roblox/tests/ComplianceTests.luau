--[[
	ComplianceTests.luau
	In-Studio tests that enforce legal compliance, monetization ethics,
	data privacy, and anti-dark-pattern invariants.

	These tests validate the same properties as scripts/validate-compliance.sh
	but at runtime with access to the actual Luau module data structures,
	enabling deeper structural checks that static bash analysis cannot cover.

	Categories:
	  1. Monetization ethics (no pay-to-win, no loot boxes)
	  2. Anti-dark-pattern enforcement (transparency, free defaults, no FOMO)
	  3. Data privacy (no PII, data minimization)
	  4. Economy fairness (progression accessible to free players)
	  5. Child safety (COPPA/CARU compliance invariants)
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
local Cosmetics   = requireShared("Cosmetics")
local GamePasses  = requireShared("GamePasses")
local Ingredients = requireShared("Ingredients")

local Tests = {}

local BASE_IDS = { "Moonpetal", "Fireroot", "Shadowmoss", "Starbloom" }

---------------------------------------------------------------------------
-- 1. Monetization ethics — no pay-to-win
---------------------------------------------------------------------------

function Tests.test_no_cosmetic_provides_gameplay_advantage(t)
	-- Cosmetic preview tables must not contain gameplay-affecting keys
	local BANNED_KEYS = {
		damage = true, health = true, speed = true, multiplier = true,
		boost = true, xp = true, experience = true, attack = true,
		defense = true, armour = true, armor = true,
	}
	for _, def in Cosmetics.ALL do
		if def.preview then
			for key, _ in def.preview do
				t:assertFalse(
					BANNED_KEYS[string.lower(key)],
					def.id .. " preview contains banned gameplay key '" .. key .. "'"
				)
			end
		end
	end
end

function Tests.test_game_passes_are_convenience_only(t)
	-- All game pass prices must be reasonable (not whale-bait)
	for _, def in GamePasses.DEFS do
		t:assertTrue(
			def.price <= 1000,
			def.name .. " price (" .. def.price .. " R$) must be <= 1000 R$ (anti-whale)"
		)
	end
end

function Tests.test_speed_brew_halves_time_not_eliminates(t)
	-- The speed brew multiplier must reduce time, not eliminate it
	t:assertTrue(Config.SPEED_BREW_MULTIPLIER > 0, "SPEED_BREW_MULTIPLIER > 0 (time not eliminated)")
	t:assertTrue(Config.SPEED_BREW_MULTIPLIER < 1, "SPEED_BREW_MULTIPLIER < 1 (time reduced)")
	-- Even with speed brew, brew time must remain >= 1 second at all levels
	for i, level in Config.CAULDRON_LEVELS do
		local boosted = level.brewTime * Config.SPEED_BREW_MULTIPLIER
		t:assertTrue(
			boosted >= 1,
			"Cauldron " .. i .. " boosted brew time (" .. boosted .. "s) >= 1s minimum"
		)
	end
end

function Tests.test_no_exclusive_progression_locked_behind_passes(t)
	-- All lab and cauldron upgrades must be purchasable with Essence (free currency)
	for i, level in Config.LAB_LEVELS do
		t:assertType(level.cost, "number", "lab level " .. i .. " cost is numeric (Essence)")
		t:assertTrue(level.cost >= 0, "lab level " .. i .. " cost is non-negative")
	end
	for i, level in Config.CAULDRON_LEVELS do
		t:assertType(level.cost, "number", "cauldron level " .. i .. " cost is numeric (Essence)")
		t:assertTrue(level.cost >= 0, "cauldron level " .. i .. " cost is non-negative")
	end
end

---------------------------------------------------------------------------
-- 2. Anti-dark-pattern enforcement
---------------------------------------------------------------------------

function Tests.test_every_cosmetic_category_has_free_default(t)
	local categories = { "LabTheme", "CauldronTint", "HarvestParticles" }
	for _, category in categories do
		local items = Cosmetics.getCategory(category)
		local freeCount = 0
		for _, def in items do
			if def.price == 0 then
				freeCount += 1
			end
		end
		t:assertTrue(freeCount >= 1, category .. " has at least 1 free item (got " .. freeCount .. ")")
	end
end

function Tests.test_cosmetic_defaults_are_free(t)
	for category, id in Cosmetics.DEFAULTS do
		local def = Cosmetics.BY_ID[id]
		t:assertNotNil(def, "default " .. category .. " '" .. id .. "' exists")
		if def then
			t:assertEqual(def.price, 0, "default " .. category .. " is free (price = 0)")
		end
	end
end

function Tests.test_mutation_odds_are_transparent(t)
	t:assertTrue(Config.SHOW_MUTATION_ODDS == true, "SHOW_MUTATION_ODDS must be true")
end

function Tests.test_mutation_odds_are_deterministic_not_randomized_purchases(t)
	-- Mutation tiers are fixed probabilities, not purchasable luck boosts
	local totalChance = 0
	for _, tier in Config.MUTATION_TIERS do
		t:assertType(tier.chance, "number", tier.name .. " chance is a number")
		t:assertTrue(tier.chance > 0, tier.name .. " chance > 0")
		t:assertTrue(tier.chance <= 1, tier.name .. " chance <= 1")
		totalChance += tier.chance
	end
	t:assertTrue(
		math.abs(totalChance - 1.0) < 0.001,
		"mutation tier chances sum to 1.0 (got " .. totalChance .. ")"
	)
end

function Tests.test_offline_growth_prevents_fomo(t)
	t:assertTrue(Config.OFFLINE_GROWTH == true, "OFFLINE_GROWTH must be true (no FOMO)")
end

function Tests.test_no_cosmetic_uses_limited_time_pressure(t)
	-- Cosmetics should not have expiry dates or limited availability flags
	for _, def in Cosmetics.ALL do
		-- Check the definition table for time-pressure fields
		local rawDef = def :: any
		t:assertNil(rawDef.expiresAt, def.id .. " must not have expiresAt field")
		t:assertNil(rawDef.limitedEdition, def.id .. " must not have limitedEdition field")
		t:assertNil(rawDef.remainingStock, def.id .. " must not have remainingStock field")
	end
end

function Tests.test_all_cosmetic_prices_are_transparent(t)
	for _, def in Cosmetics.ALL do
		t:assertType(def.price, "number", def.id .. " price is a number")
		t:assertTrue(def.price >= 0, def.id .. " price >= 0 (no hidden costs)")
		-- Max price sanity: no single cosmetic should cost more than 500 R$
		t:assertTrue(
			def.price <= 500,
			def.id .. " price (" .. def.price .. " R$) <= 500 R$ maximum"
		)
	end
end

---------------------------------------------------------------------------
-- 3. Data privacy invariants
---------------------------------------------------------------------------

function Tests.test_no_pii_in_cosmetic_definitions(t)
	-- Cosmetic definitions should not store any player-identifying information
	for _, def in Cosmetics.ALL do
		local rawDef = def :: any
		t:assertNil(rawDef.email, def.id .. " must not have email field")
		t:assertNil(rawDef.phone, def.id .. " must not have phone field")
		t:assertNil(rawDef.address, def.id .. " must not have address field")
		t:assertNil(rawDef.realName, def.id .. " must not have realName field")
	end
end

function Tests.test_analytics_events_contain_no_pii_fields(t)
	-- Network events should not contain PII-sounding names
	local Network = requireShared("Network")
	local PII_PATTERNS = { "email", "phone", "address", "realName", "birthday", "deviceId", "ipAddress" }
	local names = Network.getAllEventNames()
	for _, name in names do
		for _, pii in PII_PATTERNS do
			t:assertFalse(
				string.find(string.lower(name), string.lower(pii)) ~= nil,
				"Network event '" .. name .. "' must not contain PII pattern '" .. pii .. "'"
			)
		end
	end
end

---------------------------------------------------------------------------
-- 4. Economy fairness — free players can progress fully
---------------------------------------------------------------------------

function Tests.test_free_player_can_reach_max_lab_level(t)
	-- Verify the upgrade chain is achievable: each level's cost must be
	-- reachable by a player who farms efficiently at the previous level.
	-- Simplification: just verify costs are finite and non-astronomical.
	local totalCost = 0
	for i = 1, Config.MAX_LAB_LEVEL do
		totalCost += Config.LAB_LEVELS[i].cost
	end
	t:assertTrue(totalCost > 0, "total lab upgrade cost is positive")
	t:assertTrue(
		totalCost < 1000000,
		"total lab upgrade cost (" .. totalCost .. ") is achievable (< 1M Essence)"
	)
end

function Tests.test_free_player_can_reach_max_cauldron_level(t)
	local totalCost = 0
	for i = 1, Config.MAX_CAULDRON_LEVEL do
		totalCost += Config.CAULDRON_LEVELS[i].cost
	end
	t:assertTrue(totalCost > 0, "total cauldron upgrade cost is positive")
	t:assertTrue(
		totalCost < 1000000,
		"total cauldron upgrade cost (" .. totalCost .. ") is achievable (< 1M Essence)"
	)
end

function Tests.test_every_ingredient_is_profitable_for_free_players(t)
	-- At minimum rarity (Common, multiplier=1), selling ingredients must
	-- cover the seed cost. Otherwise free players hit dead ends.
	for _, id in BASE_IDS do
		local def = Ingredients[id]
		if not def then continue end
		t:assertTrue(
			def.baseValue > def.seedCost,
			id .. " baseValue (" .. def.baseValue .. ") > seedCost (" .. def.seedCost .. ")"
		)
	end
end

function Tests.test_starting_essence_allows_immediate_gameplay(t)
	-- New player must be able to buy at least one seed
	local cheapestSeed = math.huge
	for _, id in BASE_IDS do
		local def = Ingredients[id]
		if def and def.seedCost < cheapestSeed then
			cheapestSeed = def.seedCost
		end
	end
	t:assertTrue(
		Config.STARTING_ESSENCE >= cheapestSeed,
		"STARTING_ESSENCE (" .. Config.STARTING_ESSENCE .. ") >= cheapest seed (" .. cheapestSeed .. ")"
	)
end

---------------------------------------------------------------------------
-- 5. Child safety (COPPA/CARU compliance invariants)
---------------------------------------------------------------------------

function Tests.test_ad_cooldown_prevents_child_ad_spam(t)
	-- CARU guideline: ads should not be shown too frequently to children
	t:assertTrue(
		Config.AD_COOLDOWN_SECONDS >= 60,
		"AD_COOLDOWN_SECONDS (" .. Config.AD_COOLDOWN_SECONDS .. ") >= 60s (CARU minimum)"
	)
end

function Tests.test_ad_reward_not_game_breaking(t)
	-- Ad reward should not be so large it pressures children into watching ads
	t:assertTrue(
		Config.AD_REWARD_ESSENCE <= 500,
		"AD_REWARD_ESSENCE (" .. Config.AD_REWARD_ESSENCE .. ") <= 500 (not excessive)"
	)
	t:assertTrue(
		Config.AD_REWARD_ESSENCE >= 10,
		"AD_REWARD_ESSENCE (" .. Config.AD_REWARD_ESSENCE .. ") >= 10 (meaningful reward)"
	)
end

function Tests.test_ad_boost_multiplier_is_bounded(t)
	-- 2x boost is reasonable; anything higher pressures ad viewing
	t:assertTrue(
		Config.AD_BOOST_MULTIPLIER <= 3.0,
		"AD_BOOST_MULTIPLIER (" .. Config.AD_BOOST_MULTIPLIER .. ") <= 3.0"
	)
	t:assertTrue(
		Config.AD_BOOST_MULTIPLIER >= 1.0,
		"AD_BOOST_MULTIPLIER (" .. Config.AD_BOOST_MULTIPLIER .. ") >= 1.0"
	)
end

function Tests.test_ad_boost_duration_is_reasonable(t)
	-- Boost duration should be short enough that players don't feel obligated
	t:assertTrue(
		Config.AD_BOOST_DURATION <= 600,
		"AD_BOOST_DURATION (" .. Config.AD_BOOST_DURATION .. "s) <= 600s (10 min max)"
	)
end

function Tests.test_notification_limits_prevent_screen_clutter(t)
	-- Too many notifications = manipulative UX for children
	t:assertTrue(
		Config.MAX_NOTIFICATIONS <= 10,
		"MAX_NOTIFICATIONS (" .. Config.MAX_NOTIFICATIONS .. ") <= 10"
	)
	t:assertTrue(
		Config.MAX_NOTIFICATIONS >= 1,
		"MAX_NOTIFICATIONS (" .. Config.MAX_NOTIFICATIONS .. ") >= 1"
	)
end

function Tests.test_inventory_caps_prevent_data_bloat(t)
	-- DataStore has 4 MB limit; unbounded arrays = silent data loss
	t:assertTrue(Config.MAX_INGREDIENTS <= 100, "MAX_INGREDIENTS <= 100")
	t:assertTrue(Config.MAX_POTIONS <= 100, "MAX_POTIONS <= 100")
	t:assertTrue(Config.MAX_SEEDS <= 50, "MAX_SEEDS <= 50")
end

function Tests.test_game_pass_count_is_bounded(t)
	-- CARU guidance: don't overwhelm children with too many purchase options
	t:assertTrue(
		#GamePasses.DEFS <= 10,
		"game pass count (" .. #GamePasses.DEFS .. ") <= 10 (manageable for young players)"
	)
end

function Tests.test_cosmetic_count_is_reasonable(t)
	-- Reasonable catalog size for age 8–16 target audience
	t:assertTrue(
		#Cosmetics.ALL <= 50,
		"total cosmetics (" .. #Cosmetics.ALL .. ") <= 50 (not overwhelming)"
	)
end

return Tests
