--[[
	LeaderboardService.luau
	Global leaderboard tracking total Essence earned, lifetime.

	WHY THIS MATTERS FOR RETENTION:
	  Social competition is one of the strongest D7+ retention drivers on Roblox.
	  Seeing your name on a board gives players a reason to return even after
	  the core loop feels familiar. GDD explicitly lists leaderboards as a
	  social mechanic.

	IMPLEMENTATION:
	  Uses an OrderedDataStore (Roblox's built-in sorted key-value store).
	  Scores are the player's all-time TotalGoldEarned stat.

	  Top-N entries are fetched periodically and broadcast to all clients via
	  a RemoteEvent so the UI can display them without polling.

	  Score updates happen:
	    1. When a player leaves (final save)
	    2. Every LEADERBOARD_UPDATE_INTERVAL seconds for online players

	DISPLAY:
	  UIController should listen to the LeaderboardUpdate RemoteEvent and
	  render the data in a side panel or the Journal. The payload is an
	  array of { rank, name, score } tables, sorted rank 1 = highest.
]]

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared   = ReplicatedStorage:WaitForChild("Shared")
local Network  = require(Shared.Network)
local DataService = require(script.Parent.DataService)

local LeaderboardService = {}

---------------------------------------------------------------------------
-- Config
---------------------------------------------------------------------------

local TOP_N                      = 10    -- number of entries to show
local LEADERBOARD_UPDATE_INTERVAL = 60   -- seconds between periodic refreshes

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local orderedStore = nil   -- OrderedDataStore; set in init()

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function getStore()
	if orderedStore then return orderedStore end
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore("Leaderboard_TotalEssence_v1")
	end)
	if ok then
		orderedStore = store
	else
		warn("[LeaderboardService] Could not open OrderedDataStore:", err)
	end
	return orderedStore
end

--- Submit a player's TotalEssenceEarned score to the ordered store.
local function submitScore(player: Player)
	local store = getStore()
	if not store then return end

	local data = DataService.getData(player)
	if not data or not data.Stats then return end

	local score = data.Stats.TotalEssenceEarned or 0
	if score <= 0 then return end

	local ok, err = pcall(function()
		store:SetAsync(tostring(player.UserId), score)
	end)
	if not ok then
		warn("[LeaderboardService] SetAsync failed for", player.UserId, err)
	end
end

--- Fetch the top N scores and return a ranked array.
--- Returns: { { rank, name, score }, ... } or nil on failure.
local function fetchTopN(): { { rank: number, name: string, score: number } }?
	local store = getStore()
	if not store then return nil end

	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, TOP_N) -- descending
	end)
	if not ok then
		warn("[LeaderboardService] GetSortedAsync failed:", pages)
		return nil
	end

	local entries = {}
	local rank = 0
	local currentPage = pages:GetCurrentPage()
	for _, entry in currentPage do
		rank += 1
		local userId = tonumber(entry.key)
		local score  = entry.value

		-- Resolve display name; falls back to numeric ID if the API call fails
		local displayName = tostring(userId)
		if userId then
			local nameOk, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameOk and name then
				displayName = name
			end
		end

		table.insert(entries, { rank = rank, name = displayName, score = score })
	end

	return entries
end

--- Broadcast the current top-N to all connected players.
--- The LeaderboardUpdate RemoteEvent is created by Main.server.luau via
--- Network.getAllEventNames() — we just look it up here.
local function broadcast()
	local entries = fetchTopN()
	if not entries then return end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end

	local remote = remotes:FindFirstChild(Network.LeaderboardUpdate)
	if not remote then return end

	(remote :: RemoteEvent):FireAllClients(entries)
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function LeaderboardService.init()
	-- Periodic refresh loop
	task.spawn(function()
		while true do
			task.wait(LEADERBOARD_UPDATE_INTERVAL)
			-- Update scores for all online players, then broadcast
			for _, player in Players:GetPlayers() do
				submitScore(player)
			end
			broadcast()
		end
	end)

	-- Initial broadcast once everything is ready
	task.delay(5, broadcast)
end

--- Submit final score and trigger a fresh broadcast when a player leaves.
function LeaderboardService.onPlayerRemoving(player: Player)
	submitScore(player)
	-- Small delay so DataService has time to flush; broadcast after
	task.delay(2, broadcast)
end

--- Manually request a fresh broadcast (e.g. after a big milestone).
function LeaderboardService.refresh()
	broadcast()
end

return LeaderboardService
