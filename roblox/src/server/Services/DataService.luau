--[[
	DataService.luau
	Manages per-player data: loading, saving, template defaults, and
	authoritative state sync to the client.
	Uses DataStoreService directly for the vertical slice.
	Upgrade to ProfileService for production.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared.Config)
local Ingredients = require(Shared.Ingredients)
local Network     = require(Shared.Network)

local DataService = {}

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local playerData: { [number]: { [string]: any } } = {}
local dataStore = nil -- set in init()

---------------------------------------------------------------------------
-- Data template — new players get a deep copy of this
---------------------------------------------------------------------------
local function getTemplate(): { [string]: any }
	-- Build the initial plots array based on lab level 1
	local plots = {}
	for i = 1, Config.LAB_LEVELS[1].plots do
		plots[i] = { State = "Empty" }
	end

	return {
		Gold = Config.STARTING_GOLD,
		LabLevel = 1,
		CauldronLevel = 1,
		Plots = plots,
		Ingredients = {},  -- harvested ingredients: { {Id, Rarity}, ... }
		Potions = {},      -- brewed potions: { {Id, DisplayName, Value}, ... }
		Stats = {
			TotalGoldEarned = 0,
			PotionsBrewed = 0,
		},
	}
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Deep-copy a table (one level of nesting is enough for our template).
local function deepCopy(original: { [string]: any }): { [string]: any }
	local copy = {}
	for k, v in original do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

--- Fill in any keys from the template that are missing in saved data.
--- Protects against schema changes between versions.
local function reconcile(saved: { [string]: any }, template: { [string]: any })
	for k, v in template do
		if saved[k] == nil then
			if type(v) == "table" then
				saved[k] = deepCopy(v)
			else
				saved[k] = v
			end
		elseif type(v) == "table" and type(saved[k]) == "table" then
			reconcile(saved[k], v)
		end
	end
end

--- Roll a mutation rarity (duplicated here to avoid circular dependency
--- with GrowthService). Reads Config.MUTATION_TIERS directly.
local function rollMutation(): string
	local roll = math.random()
	local cumulative = 0
	for _, tier in Config.MUTATION_TIERS do
		cumulative += tier.chance
		if roll <= cumulative then
			return tier.name
		end
	end
	return Config.MUTATION_TIERS[1].name -- fallback to Common
end

--- Process offline growth for any plots that were still growing when the
--- player last left.  Completes growth and rolls mutations as needed.
local function processOfflineGrowth(data: { [string]: any })
	if not Config.OFFLINE_GROWTH then return end

	local now = os.time()
	for _, plot in data.Plots do
		if plot.State == "Growing" and plot.PlantedAt and plot.GrowthDuration then
			local elapsed = now - plot.PlantedAt
			if elapsed >= plot.GrowthDuration then
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
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("PotionLabData_v1")
	end)
	if ok then
		dataStore = store
	else
		warn("[DataService] Failed to get DataStore — data will NOT persist:", store)
	end
end

function DataService.onPlayerAdded(player: Player)
	local userId = player.UserId
	local template = getTemplate()
	local data = nil

	if dataStore then
		local ok, saved = pcall(function()
			return dataStore:GetAsync("player_" .. tostring(userId))
		end)
		if ok and saved then
			reconcile(saved, template)
			data = saved
		elseif not ok then
			warn("[DataService] Load failed for", userId, saved)
		end
	end

	if not data then
		data = deepCopy(template)
	end

	processOfflineGrowth(data)
	playerData[userId] = data
end

function DataService.onPlayerRemoving(player: Player)
	local userId = player.UserId
	local data = playerData[userId]
	if not data then return end

	DataService.saveData(player)
	playerData[userId] = nil
end

function DataService.getData(player: Player): { [string]: any }?
	return playerData[player.UserId]
end

function DataService.saveData(player: Player)
	if not dataStore then return end
	local data = playerData[player.UserId]
	if not data then return end

	local ok, err = pcall(function()
		dataStore:SetAsync("player_" .. tostring(player.UserId), data)
	end)
	if not ok then
		warn("[DataService] Save failed for", player.UserId, err)
	end
end

--- Push the full authoritative state to the client.
function DataService.syncToClient(player: Player)
	local data = playerData[player.UserId]
	if not data then return end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end

	local syncRemote = remotes:FindFirstChild(Network.StateSync)
	if syncRemote then
		syncRemote:FireClient(player, data)
	end
end

--- Send a notification message to the client.
function DataService.notify(player: Player, message: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end

	local notifRemote = remotes:FindFirstChild(Network.Notification)
	if notifRemote then
		notifRemote:FireClient(player, message)
	end
end

return DataService
