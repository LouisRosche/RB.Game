--[[
	AnalyticsService.luau
	Tracks player behaviour for the Phase 1 go/no-go decision.

	Targets from the execution playbook:
	  D1 retention >= 20%  (return visit within 24 hours)
	  D7 retention >= 8%   (return visit within 7 days)
	  Session length 8-15 min target

	HOW TO MEASURE D1/D7:
	  Roblox's built-in Analytics dashboard (Creator Hub → Analytics) tracks
	  D1 / D7 / D30 automatically from session data.  You do NOT need to
	  implement retention math yourself — just ensure sessions are being
	  created (they are, as long as players join the game).

	  This service fires CUSTOM EVENTS on top of the built-in session data so
	  you can see WHERE players drop off in the funnel:
	    1. Session start
	    2. First seed planted  (tutorial entry)
	    3. First harvest       (saw growth loop complete)
	    4. First brew          (discovered the crafting system)
	    5. Session end         (with duration)

	  Access custom events in Creator Hub → Analytics → Events.

	DEVELOPER NOTE:
	  game:GetService("AnalyticsService") is a Roblox engine service available
	  from Luau on the server.  It requires the game to be published (not Studio
	  solo play) for events to appear in the dashboard.  In Studio they are
	  silently discarded — this is expected behaviour.
]]

local Players          = game:GetService("Players")
local RbxAnalytics     = game:GetService("AnalyticsService")
local DataService      = require(script.Parent.DataService)

local AnalyticsService = {}

---------------------------------------------------------------------------
-- Session tracking (in-memory; discarded on server shutdown, which is fine)
---------------------------------------------------------------------------

-- sessionStart[userId] = tick() at join time
local sessionStart: { [number]: number } = {}

-- Flags to detect "first time ever" funnel events per session.
-- We only fire the funnel event ONCE per session to keep data clean.
local sessionFlags: { [number]: { [string]: boolean } } = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function getFlag(player: Player, flag: string): boolean
	local userId = player.UserId
	if not sessionFlags[userId] then return false end
	return sessionFlags[userId][flag] == true
end

local function setFlag(player: Player, flag: string)
	local userId = player.UserId
	if not sessionFlags[userId] then
		sessionFlags[userId] = {}
	end
	sessionFlags[userId][flag] = true
end

--- Fire a custom analytics event safely.
--- eventName must be <= 40 chars, value must be a number or nil.
local function fireEvent(player: Player, eventName: string, value: number?)
	local ok, err = pcall(function()
		if value ~= nil then
			RbxAnalytics:LogCustomEvent(player, eventName, value)
		else
			RbxAnalytics:LogCustomEvent(player, eventName, 0)
		end
	end)
	if not ok then
		-- Silently ignore in Studio; warn in live game for debugging
		warn("[AnalyticsService] LogCustomEvent failed for", eventName, ":", err)
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function AnalyticsService.init()
	-- Nothing to initialise; Roblox AnalyticsService is ready at script start.
end

--- Called when a player joins. Starts session timer.
function AnalyticsService.onSessionStart(player: Player)
	local userId = player.UserId
	sessionStart[userId] = tick()
	sessionFlags[userId] = {}

	-- Log whether this player has ever played before (for new-player funnel)
	local data = DataService.getData(player)
	local isNewPlayer = data and data.Stats and data.Stats.PotionsBrewed == 0
	fireEvent(player, "SessionStart", if isNewPlayer then 1 else 0)
end

--- Called when a player leaves. Logs session duration and updates leaderboard.
function AnalyticsService.onSessionEnd(player: Player)
	local userId = player.UserId
	local startTime = sessionStart[userId]
	if startTime then
		local durationSeconds = math.floor(tick() - startTime)
		fireEvent(player, "SessionDuration", durationSeconds)
	end
	sessionStart[userId] = nil
	sessionFlags[userId] = nil
end

--- Called after a seed is successfully planted.
--- Fires "FunnelPlant" once per session (first plant only).
function AnalyticsService.onSeedPlanted(player: Player, ingredientId: string)
	if not getFlag(player, "planted") then
		setFlag(player, "planted")
		fireEvent(player, "FunnelPlant", 1)
	end
end

--- Called after a harvest completes.
--- Fires "FunnelHarvest" once per session (first harvest only).
function AnalyticsService.onHarvest(player: Player, ingredientId: string, rarity: string)
	if not getFlag(player, "harvested") then
		setFlag(player, "harvested")
		fireEvent(player, "FunnelHarvest", 1)
	end
end

--- Called after a potion is brewed.
--- Fires "FunnelBrew" once per session and logs the potion value.
function AnalyticsService.onPotion(player: Player, recipeId: string, value: number)
	if not getFlag(player, "brewed") then
		setFlag(player, "brewed")
		fireEvent(player, "FunnelBrew", 1)
	end
	fireEvent(player, "PotionValue", value)
end

--- Called after a recipe discovery (first time a recipe is brewed by this player).
function AnalyticsService.onDiscovery(player: Player, recipeId: string, discoveryCount: number)
	fireEvent(player, "Discovery", discoveryCount)
end

--- Called after an upgrade (lab or cauldron).
function AnalyticsService.onUpgrade(player: Player, upgradeType: string, newLevel: number)
	-- upgradeType: "Lab" or "Cauldron"
	fireEvent(player, "Upgrade_" .. upgradeType, newLevel)
end

return AnalyticsService
