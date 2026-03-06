--[[
	DataService.luau
	Manages per-player data using ProfileService for session locking,
	automatic saves, and schema reconciliation.

	SETUP — ProfileService is a required dependency:
	  1. Download ProfileService.luau from:
	     https://github.com/MadStudioRoblox/ProfileService/releases
	  2. Place the ModuleScript at: ServerStorage > Vendor > ProfileService
	     (Rojo source path: roblox/src/server/Vendor/ProfileService.luau)
	  3. ProfileService auto-saves every 30 s and on profile:Release().
	     DataService.saveData() forces an immediate save for edge cases.

	WHY ProfileService OVER RAW DataStoreService:
	  - Session locking: prevents data corruption when the same player
	    joins two servers simultaneously (e.g., during server migration)
	  - ListenToRelease: gracefully handles profile theft so the client
	    is kicked rather than silently losing progress
	  - Reconcile: fills missing keys added in newer schema versions
	  - AddUserId: links the DataStore key to the UserId for GDPR
	    right-to-erasure requests via Roblox support
]]

local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared   = ReplicatedStorage:WaitForChild("Shared")
local Config   = require(Shared.Config)
local Network  = require(Shared.Network)

-- ProfileService from MadStudioRoblox
-- https://github.com/MadStudioRoblox/ProfileService
local ProfileService = require(
	ServerStorage:WaitForChild("Vendor"):WaitForChild("ProfileService")
)

local DataService = {}

---------------------------------------------------------------------------
-- Data template — ProfileService uses this as the canonical schema.
-- New keys added here are automatically added to existing profiles via
-- profile:Reconcile() in onPlayerAdded.
---------------------------------------------------------------------------
local DATA_TEMPLATE: { [string]: any } = {
	Gold         = Config.STARTING_GOLD,
	LabLevel     = 1,
	CauldronLevel = 1,
	Plots        = {},   -- populated dynamically; see reconcilePlots()
	Seeds        = {},   -- purchased seeds awaiting planting: { {Id} }
	Ingredients  = {},   -- harvested: { {Id, Rarity} }
	Potions      = {},   -- brewed: { {Id, DisplayName, Value} }
	DiscoveredRecipes = {},  -- set of recipe IDs player has personally brewed
	Stats = {
		TotalGoldEarned = 0,
		PotionsBrewed   = 0,
		TotalDiscoveries = 0,
	},
}

---------------------------------------------------------------------------
-- ProfileStore (version suffix allows schema resets without wiping old data)
---------------------------------------------------------------------------
local ProfileStore = ProfileService.GetProfileStore("PlayerData_v2", DATA_TEMPLATE)

-- Active profiles: userId -> Profile
local profiles: { [number]: any } = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Roll a mutation rarity. Defined here to avoid a circular dependency
--- with GrowthService (both need the same roll on offline completion).
local function rollMutation(): string
	local roll = math.random()
	local cumulative = 0
	for _, tier in Config.MUTATION_TIERS do
		cumulative += tier.chance
		if roll <= cumulative then
			return tier.name
		end
	end
	return Config.MUTATION_TIERS[1].name
end

--- Ensure the Plots array has the correct number of entries for the
--- player's saved LabLevel. ProfileService:Reconcile() handles scalar
--- keys but cannot reconstruct a variable-length array.
local function reconcilePlots(data: { [string]: any })
	local level = data.LabLevel or 1
	local levelDef = Config.LAB_LEVELS[level]
	if not levelDef then return end

	for i = 1, levelDef.plots do
		if not data.Plots[i] then
			data.Plots[i] = { State = "Empty" }
		end
	end
end

--- Complete any growth that occurred while the player was offline.
local function processOfflineGrowth(data: { [string]: any })
	if not Config.OFFLINE_GROWTH then return end

	local now = os.time()
	for _, plot in data.Plots do
		if plot.State == "Growing" and plot.PlantedAt and plot.GrowthDuration then
			if now - plot.PlantedAt >= plot.GrowthDuration then
				plot.State = "Ready"
				plot.Rarity = rollMutation()
			end
		end
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function DataService.init()
	-- ProfileStore is ready at require time; nothing else to set up.
end

function DataService.onPlayerAdded(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if not profile then
		-- DataStore is down or the session lock timed out.
		-- Kicking is the safest response: lets the player retry cleanly
		-- rather than playing with blank/unsaved data.
		player:Kick(
			"[Alchemy Academy] Could not load your save data — the DataStore service " ..
			"may be experiencing issues. Please rejoin in a moment."
		)
		return
	end

	-- Link this profile key to the player's UserId so Roblox can fulfil
	-- GDPR right-to-erasure requests if needed.
	profile:AddUserId(player.UserId)

	-- Fill in any keys added since the player last played.
	profile:Reconcile()

	-- If this profile is claimed by another server (e.g. a second join
	-- before the first server registered the leave), kick gracefully.
	profile:ListenToRelease(function()
		profiles[player.UserId] = nil
		player:Kick(
			"[Alchemy Academy] Your session was opened on another server. Please rejoin."
		)
	end)

	-- Guard: player might have left during the async DataStore call.
	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	profiles[player.UserId] = profile

	-- Ensure Plots matches the saved LabLevel
	reconcilePlots(profile.Data)

	-- Complete any offline growth
	processOfflineGrowth(profile.Data)
end

function DataService.onPlayerRemoving(player: Player)
	local profile = profiles[player.UserId]
	if profile then
		-- Release triggers a final save and removes the session lock,
		-- allowing the player's next server to load the profile.
		profile:Release()
		profiles[player.UserId] = nil
	end
end

--- Returns the mutable data table for a player, or nil if not yet loaded.
function DataService.getData(player: Player): { [string]: any }?
	local profile = profiles[player.UserId]
	return if profile then profile.Data else nil
end

--- Force an immediate save. ProfileService auto-saves every ~30 s;
--- call this before high-stakes operations (e.g. large upgrades).
function DataService.saveData(player: Player)
	local profile = profiles[player.UserId]
	if profile then
		profile:Save()
	end
end

--- Push the full authoritative state to the client.
function DataService.syncToClient(player: Player)
	local data = DataService.getData(player)
	if not data then return end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end

	local syncRemote = remotes:FindFirstChild(Network.StateSync)
	if syncRemote then
		syncRemote:FireClient(player, data)
	end
end

--- Send a one-off notification message to the client.
function DataService.notify(player: Player, message: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end

	local notifRemote = remotes:FindFirstChild(Network.Notification)
	if notifRemote then
		notifRemote:FireClient(player, message)
	end
end

return DataService
