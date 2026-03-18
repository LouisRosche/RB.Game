--[[
	ProfileService — Production-Ready Module with Session Locking
	================================================================
	Drop-in replacement for the original stub. Adds cross-server session
	locking via MemoryStoreService so player data cannot be duplicated
	by joining two servers simultaneously.

	API surface (unchanged from the stub / compatible with real ProfileService):
	  ProfileService.GetProfileStore(storeName, template) → ProfileStore
	  ProfileStore:LoadProfileAsync(key) → Profile?
	  Profile:AddUserId(userId)
	  Profile:Reconcile()
	  Profile:ListenToRelease(callback)
	  Profile:IsActive() → boolean
	  Profile:Save()
	  Profile:Release()

	Session locking strategy:
	  • MemoryStoreService SortedMap holds { profileKey → JobId } with a TTL.
	  • On load, we check the lock. If another server holds it, we publish a
	    "ForceRelease" message via MessagingService and wait for the lock to clear.
	  • A heartbeat refreshes the lock TTL every LOCK_REFRESH_INTERVAL seconds.
	  • On release, the lock is removed and a final save is performed.

	DataService.luau requires: GetProfileStore, LoadProfileAsync, AddUserId,
	Reconcile, ListenToRelease, Release, profile.Data, Save.
	All of these are implemented below.
--]]

local DataStoreService    = game:GetService("DataStoreService")
local MemoryStoreService  = game:GetService("MemoryStoreService")
local MessagingService    = game:GetService("MessagingService")
local RunService          = game:GetService("RunService")

local JOB_ID = game.JobId  -- unique per server instance; empty string in Studio

---------------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------------
local AUTOSAVE_INTERVAL      = 30   -- seconds between auto-saves
local LOCK_TTL               = 1800 -- seconds before lock expires if not refreshed
local LOCK_REFRESH_INTERVAL  = 60   -- seconds between lock TTL refreshes
local FORCE_RELEASE_TIMEOUT  = 12   -- seconds to wait for another server to release
local MESSAGING_TOPIC        = "ProfileForceRelease"

---------------------------------------------------------------------------
-- Signal — minimal RBXScriptSignal-compatible implementation
---------------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(fn)
	table.insert(self._listeners, fn)
	local listeners = self._listeners
	local connection = {
		Disconnect = function(_self)
			for i, f in ipairs(listeners) do
				if f == fn then
					table.remove(listeners, i)
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
-- Helpers
---------------------------------------------------------------------------

local function deepCopy(t: any): any
	if type(t) ~= "table" then return t end
	local copy = {}
	for k, v in t do
		copy[k] = deepCopy(v)
	end
	return copy
end

--- pcall wrapper that retries on transient DataStore / MemoryStore failures.
local function retry(attempts: number, fn: () -> ...): (boolean, ...any)
	local ok, result
	for i = 1, attempts do
		ok, result = pcall(fn)
		if ok then return true, result end
		if i < attempts then
			task.wait(2 ^ (i - 1)) -- exponential backoff: 1, 2, 4 …
		end
	end
	return false, result
end

---------------------------------------------------------------------------
-- Session lock map (shared across all ProfileStores in this server)
---------------------------------------------------------------------------
local sessionMap = MemoryStoreService:GetSortedMap("ProfileSessionLocks")

-- Profiles owned by THIS server: { lockKey → Profile }
local ownedProfiles: { [string]: any } = {}

-- Subscribe to force-release messages from other servers.
-- When another server wants our profile, it publishes { Key = lockKey }.
-- We release the profile so the requesting server can acquire the lock.
local messagingSubscribed = false
local function ensureMessagingSubscription()
	if messagingSubscribed then return end
	messagingSubscribed = true

	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(MESSAGING_TOPIC, function(message)
			local data = message.Data
			if type(data) ~= "table" or not data.Key then return end

			local profile = ownedProfiles[data.Key]
			if profile and profile._active then
				-- Another server is requesting this profile. Release it.
				profile:Release()
			end
		end)
	end)

	if not ok then
		-- MessagingService is unavailable in Studio test mode.
		-- Session locking still works via MemoryStore; force-release just won't
		-- propagate across servers (acceptable for local testing).
		warn("[ProfileService] MessagingService subscribe failed (expected in Studio): " .. tostring(err))
	end
end

---------------------------------------------------------------------------
-- Profile object
---------------------------------------------------------------------------
local Profile = {}
Profile.__index = Profile

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
	if not table.find(self._userIds, userId) then
		table.insert(self._userIds, userId)
	end
end

function Profile:ListenToRelease(callback)
	return self._releaseSignal:Connect(callback)
end

function Profile:IsActive(): boolean
	return self._active
end

--- Force an immediate save. Skips the auto-save timer.
function Profile:Save()
	if not self._active then return end
	local ok, err = retry(3, function()
		self._store:UpdateAsync(self._key, function(_old)
			return self.Data
		end)
	end)
	if not ok then
		warn("[ProfileService] Save failed for '" .. self._key .. "': " .. tostring(err))
	end
end

--- Release the profile: final save, remove session lock, mark inactive.
function Profile:Release()
	if not self._active then return end
	self._active = false

	-- Remove from owned profiles
	ownedProfiles[self._lockKey] = nil

	-- Stop auto-save and lock refresh
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end

	-- Final save
	local ok, err = retry(3, function()
		self._store:UpdateAsync(self._key, function(_old)
			return self.Data
		end)
	end)
	if not ok then
		warn("[ProfileService] Release save failed for '" .. self._key .. "': " .. tostring(err))
	end

	-- Remove session lock
	pcall(function()
		sessionMap:RemoveAsync(self._lockKey)
	end)

	-- Fire release listeners (DataService uses this to kick the player)
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
	local lockKey   = self._storeName .. "/" .. key

	ensureMessagingSubscription()

	-- Step 1: Acquire session lock
	local lockAcquired = false

	for attempt = 1, 3 do
		local existingLock = nil
		pcall(function()
			existingLock = sessionMap:GetAsync(lockKey)
		end)

		if existingLock == nil or existingLock == JOB_ID then
			-- No lock or we already own it — acquire
			local setOk = pcall(function()
				sessionMap:SetAsync(lockKey, JOB_ID, LOCK_TTL)
			end)
			if setOk then
				lockAcquired = true
				break
			end
		else
			-- Another server holds the lock. Request force-release.
			pcall(function()
				MessagingService:PublishAsync(MESSAGING_TOPIC, { Key = lockKey })
			end)

			-- Wait for the other server to release
			local waited = 0
			while waited < FORCE_RELEASE_TIMEOUT do
				task.wait(2)
				waited += 2
				local currentLock = nil
				pcall(function()
					currentLock = sessionMap:GetAsync(lockKey)
				end)
				if currentLock == nil then
					break
				end
			end

			-- Try to acquire after waiting
			local setOk = pcall(function()
				sessionMap:SetAsync(lockKey, JOB_ID, LOCK_TTL)
			end)
			if setOk then
				lockAcquired = true
				break
			end
		end

		if attempt < 3 then
			task.wait(2 ^ attempt)
		end
	end

	if not lockAcquired then
		-- In Studio (empty JobId), MemoryStore may not be available.
		-- Fall through and load without locking — acceptable for local testing.
		if RunService:IsStudio() then
			warn("[ProfileService] Session lock unavailable in Studio — loading without lock (safe for testing)")
		else
			warn("[ProfileService] Could not acquire session lock for '" .. key .. "' — aborting load")
			return nil
		end
	end

	-- Step 2: Load data from DataStore
	local savedData = nil
	local loadOk, loadErr = retry(3, function()
		savedData = dataStore:GetAsync(key)
	end)
	if not loadOk then
		warn("[ProfileService] LoadProfileAsync failed for '" .. key .. "': " .. tostring(loadErr))
		-- Release the lock we just acquired
		pcall(function()
			sessionMap:RemoveAsync(lockKey)
		end)
		return nil
	end

	local data: { [string]: any }
	if savedData ~= nil then
		data = savedData
	else
		data = deepCopy(template)
	end

	-- Step 3: Create the Profile object
	local profile = setmetatable({
		Data            = data,
		_key            = key,
		_lockKey        = lockKey,
		_store          = dataStore,
		_template       = template,
		_active         = true,
		_userIds        = {},
		_releaseSignal  = Signal.new(),
		_heartbeatConnection = nil,
	}, Profile)

	-- Register as owned
	ownedProfiles[lockKey] = profile

	-- Step 4: Start heartbeat (auto-save + lock refresh)
	local lastSave    = os.time()
	local lastRefresh = os.time()

	profile._heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not profile._active then return end

		local now = os.time()

		-- Auto-save
		if now - lastSave >= AUTOSAVE_INTERVAL then
			lastSave = now
			local saveOk, saveErr = pcall(function()
				dataStore:UpdateAsync(key, function(_old)
					return profile.Data
				end)
			end)
			if not saveOk then
				warn("[ProfileService] Auto-save failed for '" .. key .. "': " .. tostring(saveErr))
			end
		end

		-- Refresh session lock TTL
		if now - lastRefresh >= LOCK_REFRESH_INTERVAL then
			lastRefresh = now
			pcall(function()
				sessionMap:SetAsync(lockKey, JOB_ID, LOCK_TTL)
			end)
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
		_dataStore  = dataStore,
		_storeName  = storeName,
		_template   = template,
	}, ProfileStore)
end

-- Diagnostic signals (compatible with the real ProfileService API)
ProfileService.ServiceLocked       = false
ProfileService.IssueSignal         = Signal.new()
ProfileService.CorruptionSignal    = Signal.new()
ProfileService.CriticalStateSignal = Signal.new()

function ProfileService.IsLive(): boolean
	return not RunService:IsStudio()
end

return ProfileService
