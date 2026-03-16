--[[
	TestRunner.server.luau
	Minimal test runner for Alchemy Academy shared modules.

	Place this Script in ServerScriptService (or TestService).
	It discovers every child/descendant ModuleScript whose name ends with
	"Tests", requires it, and calls each test_* function in the returned table.

	Assertion helpers are passed to each test via a context table so test
	modules stay dependency-free.
]]

---------------------------------------------------------------------------
-- Assertion helpers
---------------------------------------------------------------------------

local Context = {}
Context.__index = Context

function Context.new(testName: string)
	local self = setmetatable({}, Context)
	self._name = testName
	self._failed = false
	self._messages = {}
	return self
end

function Context:fail(msg: string)
	self._failed = true
	table.insert(self._messages, msg)
end

--- Assert that `got` equals `expected` (strict equality).
function Context:assertEqual(got: any, expected: any, label: string?)
	if got ~= expected then
		local tag = if label then label .. ": " else ""
		self:fail(tag .. "expected " .. tostring(expected) .. ", got " .. tostring(got))
	end
end

--- Assert that `value` is truthy.
function Context:assertTrue(value: any, label: string?)
	if not value then
		local tag = if label then label .. ": " else ""
		self:fail(tag .. "expected truthy, got " .. tostring(value))
	end
end

--- Assert that `value` is falsy (nil or false).
function Context:assertFalse(value: any, label: string?)
	if value then
		local tag = if label then label .. ": " else ""
		self:fail(tag .. "expected falsy, got " .. tostring(value))
	end
end

--- Assert that `value` is nil.
function Context:assertNil(value: any, label: string?)
	if value ~= nil then
		local tag = if label then label .. ": " else ""
		self:fail(tag .. "expected nil, got " .. tostring(value))
	end
end

--- Assert that `value` is not nil.
function Context:assertNotNil(value: any, label: string?)
	if value == nil then
		local tag = if label then label .. ": " else ""
		self:fail(tag .. "expected non-nil value")
	end
end

--- Assert `value` is a number greater than 0.
function Context:assertPositive(value: any, label: string?)
	if type(value) ~= "number" or value <= 0 then
		local tag = if label then label .. ": " else ""
		self:fail(tag .. "expected positive number, got " .. tostring(value))
	end
end

--- Assert `value` has the given type (as returned by `type()`).
function Context:assertType(value: any, expectedType: string, label: string?)
	if type(value) ~= expectedType then
		local tag = if label then label .. ": " else ""
		self:fail(tag .. "expected type " .. expectedType .. ", got " .. type(value))
	end
end

---------------------------------------------------------------------------
-- Runner
---------------------------------------------------------------------------

local passCount  = 0
local failCount  = 0
local errorCount = 0

local function runModule(moduleScript: ModuleScript)
	local ok, tests = pcall(require, moduleScript)
	if not ok then
		errorCount += 1
		warn("[TESTS] ERROR requiring " .. moduleScript.Name .. ": " .. tostring(tests))
		return
	end

	if type(tests) ~= "table" then
		errorCount += 1
		warn("[TESTS] " .. moduleScript.Name .. " did not return a table")
		return
	end

	print("\n[TESTS] === " .. moduleScript.Name .. " ===")

	-- Collect and sort keys for deterministic ordering
	local keys = {}
	for k, v in tests do
		if type(k) == "string" and type(v) == "function" and k:sub(1, 5) == "test_" then
			table.insert(keys, k)
		end
	end
	table.sort(keys)

	for _, key in keys do
		local ctx = Context.new(key)
		local ran, err = pcall(tests[key], ctx)

		if not ran then
			failCount += 1
			warn("  FAIL  " .. key .. "  (runtime error: " .. tostring(err) .. ")")
		elseif ctx._failed then
			failCount += 1
			for _, msg in ctx._messages do
				warn("  FAIL  " .. key .. "  — " .. msg)
			end
		else
			passCount += 1
			print("  PASS  " .. key)
		end
	end
end

---------------------------------------------------------------------------
-- Discovery
---------------------------------------------------------------------------

print("\n========================================")
print("  Alchemy Academy — Test Runner")
print("========================================")

-- Find all descendant ModuleScripts whose name ends with "Tests"
for _, child in script:GetDescendants() do
	if child:IsA("ModuleScript") and child.Name:match("Tests$") then
		runModule(child)
	end
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------

local total = passCount + failCount + errorCount
print("\n========================================")
if failCount == 0 and errorCount == 0 then
	print("  ALL PASSED: " .. passCount .. "/" .. total)
else
	warn("  PASSED: " .. passCount .. "  |  FAILED: " .. failCount .. "  |  ERRORS: " .. errorCount)
end
print("========================================\n")
