--[[
	ProfileService — Compatibility Stub
	====================================
	This is a LIGHTWEIGHT STUB for development/Studio testing only.
	It implements the same API surface as the real MadStudioRoblox ProfileService
	but uses a simpler DataStore backend (no cross-server session locking).

	IMPORTANT — Before shipping to production:
	  1. Delete this file.
	  2. Download the real ProfileService from:
	     https://github.com/MadStudioRoblox/ProfileService/releases
	  3. Place it here as ProfileService.luau
	  4. Update INSTALL.md pinned version field.

	The real ProfileService adds:
	  • Cross-server session locks (prevents duplicate-join data corruption)
	  • Profile:ListenToRelease() triggered by external force-loads
	  • IssueSignal / CorruptionSignal for DevEx-ready error monitoring
	  • Batched auto-save splitting across players to avoid rate limits

	DataService.luau uses: GetProfileStore, LoadProfileAsync, AddUserId,
	Reconcile, ListenToRelease, Release, profile.Data, Save.
	All of these are implemented below.

	Pinned version: STUB — replace with real ProfileService before launch
--]]

local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")

---------------------------------------------------------------------------
-- Signal — minimal version of RBXScriptSignal used for ListenToRelease
---------------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(fn)
	table.insert(self._listeners, fn)
	local connection = {
		Disconnect = function(self_conn)
			for i, f in ipairs(self._listeners) do
				if f == fn then
					table.remove(self._listeners, i)
					break
				end
			end
		end,
	}
	return connection
end

function Signal:Fire(...)
	for _, fn in self._listeners do
		task.spawn(fn, ...)
	end
end

---------------------------------------------------------------------------
-- Profile object
---------------------------------------------------------------------------
local Profile = {}
Profile.__index = Profile

local AUTOSAVE_INTERVAL = 30 -- seconds

local function deepCopy(t: any): any
	if type(t) ~= "table" then return t end
	local copy = {}
	for k, v in t do
		copy[k] = deepCopy(v)
	end
	return copy
end

--- Fills in missing keys from the template into profile.Data (non-destructive).
function Profile:Reconcile()
	local function fill(target, template)
		for k, v in template do
			if target[k] == nil then
				target[k] = deepCopy(v)
			elseif type(target[k]) == "table" and type(v) == "table" then
				fill(target[k], v)
			end
		end
	end
	fill(self.Data, self._template)
end

function Profile:AddUserId(userId: number)
	-- Store for GDPR tracking. Real ProfileService sends this to RobloxMetaData.
	if not table.find(self._userIds, userId) then
		table.insert(self._userIds, userId)
	end
end

function Profile:ListenToRelease(callback)
	return self._releaseSignal:Connect(callback)
end

function Profile:IsActive()
	return self._active
end

--- Force an immediate save. Skips the auto-save timer.
function Profile:Save()
	if not self._active then return end
	local ok, err = pcall(function()
		self._store:SetAsync(self._key, self.Data)
	end)
	if not ok then
		warn("[ProfileService Stub] Save failed for key '" .. self._key .. "': " .. tostring(err))
	end
end

--- Release the profile: final save + mark inactive.
--- ListenToRelease callbacks fire here (mirrors real ProfileService behaviour
--- for the case where the server shuts down gracefully).
function Profile:Release()
	if not self._active then return end
	self._active = false

	-- Cancel the auto-save loop
	if self._autosaveConnection then
		self._autosaveConnection:Disconnect()
		self._autosaveConnection = nil
	end

	-- Final save
	local ok, err = pcall(function()
		self._store:SetAsync(self._key, self.Data)
	end)
	if not ok then
		warn("[ProfileService Stub] Release save failed for key '" .. self._key .. "': " .. tostring(err))
	end

	self._releaseSignal:Fire()
end

---------------------------------------------------------------------------
-- ProfileStore object
---------------------------------------------------------------------------
local ProfileStore = {}
ProfileStore.__index = ProfileStore

function ProfileStore:LoadProfileAsync(key: string): any?
	local dataStore = self._dataStore
	local template  = self._template

	-- Load from DataStore
	local savedData = nil
	local ok, err = pcall(function()
		savedData = dataStore:GetAsync(key)
	end)
	if not ok then
		warn("[ProfileService Stub] LoadProfileAsync failed for key '" .. key .. "': " .. tostring(err))
		return nil
	end

	local data: { [string]: any }
	if savedData ~= nil then
		data = savedData
	else
		data = deepCopy(template)
	end

	local profile = setmetatable({
		Data           = data,
		_key           = key,
		_store         = dataStore,
		_template      = template,
		_active        = true,
		_userIds       = {},
		_releaseSignal = Signal.new(),
		_autosaveConnection = nil,
	}, Profile)

	-- Auto-save loop
	local lastSave = os.time()
	profile._autosaveConnection = RunService.Heartbeat:Connect(function()
		if not profile._active then return end
		if os.time() - lastSave >= AUTOSAVE_INTERVAL then
			lastSave = os.time()
			local saveOk, saveErr = pcall(function()
				dataStore:SetAsync(key, profile.Data)
			end)
			if not saveOk then
				warn("[ProfileService Stub] Auto-save failed for key '" .. key .. "': " .. tostring(saveErr))
			end
		end
	end)

	return profile
end

---------------------------------------------------------------------------
-- ProfileService module
---------------------------------------------------------------------------
local ProfileService = {}

function ProfileService.GetProfileStore(storeName: string, template: { [string]: any })
	local dataStore = DataStoreService:GetDataStore(storeName)
	return setmetatable({
		_dataStore = dataStore,
		_template  = template,
	}, ProfileStore)
end

-- These signals exist on the real ProfileService; stub them so any code
-- that checks them doesn't error.
ProfileService.ServiceLocked        = false
ProfileService.IssueSignal          = Signal.new()
ProfileService.CorruptionSignal     = Signal.new()
ProfileService.CriticalStateSignal  = Signal.new()

function ProfileService.IsLive()
	return not RunService:IsStudio()
end

return ProfileService
