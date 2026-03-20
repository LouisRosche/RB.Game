--[[
	StringsTests.luau
	Tests for roblox/src/shared/Strings.luau

	Validates:
	  - All exported values are non-empty strings
	  - Placeholder syntax {key} is well-formed (no unclosed braces)
	  - Rarity harvest messages exist for every mutation tier name
	  - Odds display strings exist for every mutation tier name
	  - Legal compliance strings are present
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

local Strings = requireShared("Strings")
local Config  = requireShared("Config")

local Tests = {}

---------------------------------------------------------------------------
-- Basic structure
---------------------------------------------------------------------------

function Tests.test_all_values_are_non_empty_strings(t)
	local count = 0
	for key, value in Strings do
		if type(value) == "string" then
			count += 1
			t:assertTrue(#value > 0, key .. " is non-empty")
		end
	end
	t:assertTrue(count >= 30, "at least 30 string constants exist (got " .. count .. ")")
end

function Tests.test_no_nil_values(t)
	-- Catch typos where a key was defined but assigned nil
	local expectedKeys = {
		"GOLD", "SHOP", "INVENTORY", "BREW", "SELL", "CLOSE", "PLANT", "HARVEST",
		"PURCHASED_ITEM", "PLANTED_ITEM", "BREWED_POTION", "SOLD_POTION",
		"NOT_ENOUGH_GOLD", "NO_EMPTY_PLOTS", "INVENTORY_FULL",
		"REFUND_NOTICE", "EXTERNAL_LINK_BLOCKED",
	}
	for _, key in expectedKeys do
		t:assertNotNil(Strings[key], "Strings." .. key .. " exists")
	end
end

---------------------------------------------------------------------------
-- Placeholder syntax validation
---------------------------------------------------------------------------

function Tests.test_placeholders_are_well_formed(t)
	for key, value in Strings do
		if type(value) ~= "string" then continue end

		-- Count open and close braces — they should be equal
		local opens = 0
		local closes = 0
		for _ in string.gmatch(value, "{") do opens += 1 end
		for _ in string.gmatch(value, "}") do closes += 1 end
		t:assertEqual(opens, closes, key .. " has balanced braces (open=" .. opens .. ", close=" .. closes .. ")")

		-- Every { should eventually be closed by } on the same nesting level
		-- (no nested braces allowed in our simple template system)
		local depth = 0
		for i = 1, #value do
			local ch = string.sub(value, i, i)
			if ch == "{" then
				depth += 1
				t:assertTrue(depth <= 1, key .. " has no nested braces at position " .. i)
			elseif ch == "}" then
				depth -= 1
				t:assertTrue(depth >= 0, key .. " has no stray closing brace at position " .. i)
			end
		end
		t:assertEqual(depth, 0, key .. " all braces closed")
	end
end

function Tests.test_placeholder_names_are_alphanumeric(t)
	for key, value in Strings do
		if type(value) ~= "string" then continue end
		-- Extract all {placeholder} names and validate they contain only a-z, A-Z, 0-9, _
		for placeholder in string.gmatch(value, "{([^}]+)}") do
			local valid = string.match(placeholder, "^[%a%d_]+$") ~= nil
			t:assertTrue(valid, key .. " placeholder {" .. placeholder .. "} is alphanumeric")
		end
	end
end

---------------------------------------------------------------------------
-- Rarity-related strings exist for every mutation tier
---------------------------------------------------------------------------

function Tests.test_harvest_messages_exist_for_all_rarities(t)
	for _, tier in Config.MUTATION_TIERS do
		local key = "HARVESTED_" .. string.upper(tier.name)
		t:assertNotNil(Strings[key], "Strings." .. key .. " exists for rarity " .. tier.name)
	end
end

function Tests.test_odds_strings_exist_for_all_rarities(t)
	for _, tier in Config.MUTATION_TIERS do
		local key = "ODDS_" .. string.upper(tier.name)
		t:assertNotNil(Strings[key], "Strings." .. key .. " exists for rarity " .. tier.name)
	end
end

function Tests.test_odds_strings_contain_correct_percentages(t)
	for _, tier in Config.MUTATION_TIERS do
		local key = "ODDS_" .. string.upper(tier.name)
		local value = Strings[key]
		if not value then continue end
		-- Odds string should contain the percentage matching Config
		local expectedPct = tostring(math.floor(tier.chance * 100))
		t:assertTrue(
			string.find(value, expectedPct) ~= nil,
			key .. " should contain '" .. expectedPct .. "%%' (got: " .. value .. ")"
		)
	end
end

function Tests.test_odds_strings_contain_correct_multipliers(t)
	for _, tier in Config.MUTATION_TIERS do
		local key = "ODDS_" .. string.upper(tier.name)
		local value = Strings[key]
		if not value then continue end
		local expectedMult = tostring(tier.multiplier)
		t:assertTrue(
			string.find(value, expectedMult) ~= nil,
			key .. " should contain multiplier '" .. expectedMult .. "' (got: " .. value .. ")"
		)
	end
end

---------------------------------------------------------------------------
-- Legal compliance strings
---------------------------------------------------------------------------

function Tests.test_refund_notice_contains_required_elements(t)
	local notice = Strings.REFUND_NOTICE
	t:assertNotNil(notice, "REFUND_NOTICE exists")
	if not notice then return end
	t:assertTrue(string.find(notice, "final") ~= nil, "REFUND_NOTICE mentions 'final'")
	t:assertTrue(string.find(notice, "Roblox") ~= nil, "REFUND_NOTICE mentions 'Roblox'")
	t:assertTrue(string.find(notice, "support") ~= nil or string.find(notice, "Support") ~= nil,
		"REFUND_NOTICE mentions support")
end

function Tests.test_privacy_policy_link_exists(t)
	t:assertNotNil(Strings.PRIVACY_POLICY_LINK, "PRIVACY_POLICY_LINK exists")
end

function Tests.test_terms_of_service_link_exists(t)
	t:assertNotNil(Strings.TERMS_OF_SERVICE_LINK, "TERMS_OF_SERVICE_LINK exists")
end

function Tests.test_external_link_blocked_exists(t)
	t:assertNotNil(Strings.EXTERNAL_LINK_BLOCKED, "EXTERNAL_LINK_BLOCKED exists")
end

---------------------------------------------------------------------------
-- Journal tab labels
---------------------------------------------------------------------------

function Tests.test_journal_tab_labels_exist(t)
	local tabs = { "TAB_BASICS", "TAB_INGREDIENTS", "TAB_RECIPES", "TAB_ODDS", "TAB_FUN_FACTS" }
	for _, key in tabs do
		t:assertNotNil(Strings[key], "Strings." .. key .. " exists")
	end
end

return Tests
