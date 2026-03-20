--[[
	NetworkTests.luau
	Tests for roblox/src/shared/Network.luau

	Validates:
	  - All event name constants are unique non-empty strings
	  - getAllEventNames() returns every constant defined in the module
	  - No duplicate event names
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

local Network = requireShared("Network")

local Tests = {}

---------------------------------------------------------------------------
-- Event name constants
---------------------------------------------------------------------------

--- Collect all string-valued fields (event names) from the module.
local function getEventConstants(): { [string]: string }
	local constants = {}
	for key, value in Network do
		if type(value) == "string" then
			constants[key] = value
		end
	end
	return constants
end

function Tests.test_event_constants_are_non_empty_strings(t)
	local constants = getEventConstants()
	local count = 0
	for key, value in constants do
		count += 1
		t:assertType(value, "string", key .. " type")
		t:assertTrue(#value > 0, key .. " non-empty")
	end
	t:assertTrue(count > 0, "at least one event constant exists")
end

function Tests.test_event_constant_values_are_unique(t)
	local constants = getEventConstants()
	local seen: { [string]: string } = {}
	for key, value in constants do
		if seen[value] then
			t:fail("duplicate event name '" .. value .. "' used by both " .. seen[value] .. " and " .. key)
		end
		seen[value] = key
	end
end

function Tests.test_event_names_match_field_names(t)
	-- Convention: Network.Foo = "Foo" (field name == string value)
	local constants = getEventConstants()
	for key, value in constants do
		t:assertEqual(key, value, key .. " field name matches string value")
	end
end

---------------------------------------------------------------------------
-- getAllEventNames()
---------------------------------------------------------------------------

function Tests.test_get_all_event_names_returns_table(t)
	local names = Network.getAllEventNames()
	t:assertType(names, "table", "getAllEventNames returns table")
	t:assertTrue(#names > 0, "getAllEventNames is non-empty")
end

function Tests.test_get_all_event_names_contains_all_constants(t)
	local constants = getEventConstants()
	local names = Network.getAllEventNames()

	-- Build a set of names returned by the helper
	local nameSet: { [string]: boolean } = {}
	for _, name in names do
		nameSet[name] = true
	end

	-- Every constant value should appear in the helper's output
	for key, value in constants do
		t:assertTrue(nameSet[value], key .. " = '" .. value .. "' is in getAllEventNames()")
	end
end

function Tests.test_get_all_event_names_has_no_extras(t)
	local constants = getEventConstants()
	local names = Network.getAllEventNames()

	-- Build a set of constant values
	local constSet: { [string]: boolean } = {}
	for _, value in constants do
		constSet[value] = true
	end

	-- Every entry in getAllEventNames should be a known constant
	for _, name in names do
		t:assertTrue(constSet[name], "'" .. name .. "' in getAllEventNames() is a known constant")
	end
end

function Tests.test_get_all_event_names_has_no_duplicates(t)
	local names = Network.getAllEventNames()
	local seen: { [string]: boolean } = {}
	for _, name in names do
		t:assertNil(seen[name], "duplicate in getAllEventNames: " .. name)
		seen[name] = true
	end
end

---------------------------------------------------------------------------
-- Known event count (catches accidental deletions or additions
-- without updating getAllEventNames)
---------------------------------------------------------------------------

function Tests.test_event_count_matches(t)
	local constants = getEventConstants()
	local constCount = 0
	for _ in constants do constCount += 1 end

	local names = Network.getAllEventNames()
	t:assertEqual(#names, constCount, "getAllEventNames count == constant count")
end

return Tests
