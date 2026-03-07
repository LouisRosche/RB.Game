--[[
	SeasonalService.luau
	Manages time-limited seasonal events for Alchemy Academy.

	Responsibilities:
	  1. Determine which (if any) seasonal event is currently active based
	     on the real-world calendar date (os.date UTC).
	  2. Expose the active event's ingredients so the seed shop can list them.
	  3. Expose the active event's recipes so BrewingService can match them.
	  4. Broadcast `SeasonalUpdate` to all clients when the active event
	     changes (server restart or midnight rollover).

	Integration points:
	  - EconomyService.buySeed: check getActiveIngredient(id) in addition to
	    base Ingredients table for valid purchasable seeds.
	  - BrewingService.brewPotion: check getActiveRecipe(id_a, id_b) in
	    addition to base Recipes table.
	  - GrowthService.plantSeed: reads growth time from getActiveIngredient.
	  - UIController (client): receives SeasonalUpdate and adds seasonal seeds
	    to the shop panel with a "SEASONAL" badge.

	Time: Server uses os.date("*t", os.time()) — UTC by default in Roblox.
	Studio testing: set SeasonalContent.FORCE_ACTIVE to an event id.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared           = ReplicatedStorage:WaitForChild("Shared")
local SeasonalContent  = require(Shared:WaitForChild("SeasonalContent"))

-- DataService injected via init() to avoid circular require
local DataService: any = nil

local SeasonalService = {}

---------------------------------------------------------------------------
-- Internal state
---------------------------------------------------------------------------

local activeEvent: typeof(SeasonalContent.EVENTS[1])? = nil
local activeIngredientIndex: { [string]: typeof(SeasonalContent.EVENTS[1].ingredients[1]) } = {}
local activeRecipeLookup: { [string]: string } = {}  -- "id_a+id_b" → recipe id

---------------------------------------------------------------------------
-- Calendar helpers
---------------------------------------------------------------------------

--- Returns {month, day} for the current UTC time.
local function currentDate(): (number, number)
	local t = os.date("*t", os.time()) :: any
	return t.month :: number, t.mday :: number
end

--- Returns true if (month, day) falls in [startMonth/startDay, endMonth/endDay].
--- Handles year wrap-around (e.g. Dec 25 – Jan 8).
local function isInWindow(
	month: number, day: number,
	startMonth: number, startDay: number,
	endMonth: number,   endDay: number
): boolean
	local startOrd = startMonth * 100 + startDay
	local endOrd   = endMonth   * 100 + endDay
	local nowOrd   = month      * 100 + day

	if startOrd <= endOrd then
		-- Normal window (same year)
		return nowOrd >= startOrd and nowOrd <= endOrd
	else
		-- Year-wrap window (e.g. Dec 25 – Jan 8)
		return nowOrd >= startOrd or nowOrd <= endOrd
	end
end

--- Scan all events and return the first one active right now, or nil.
local function findActiveEvent(): typeof(SeasonalContent.EVENTS[1])?
	-- Debug override for Studio testing
	if SeasonalContent.FORCE_ACTIVE then
		return SeasonalContent.BY_ID[SeasonalContent.FORCE_ACTIVE]
	end

	local month, day = currentDate()
	for _, event in SeasonalContent.EVENTS do
		if isInWindow(month, day, event.startMonth, event.startDay, event.endMonth, event.endDay) then
			return event
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- Index building
---------------------------------------------------------------------------

local function buildIndex(event: typeof(SeasonalContent.EVENTS[1])?)
	activeIngredientIndex = {}
	activeRecipeLookup = {}

	if not event then return end

	-- Index ingredients
	for _, ing in event.ingredients do
		activeIngredientIndex[ing.id] = ing
	end

	-- Index recipes (key = sorted pair of ingredient ids)
	for _, recipe in event.recipes do
		local ids = { recipe.ingredients[1], recipe.ingredients[2] }
		table.sort(ids)
		local key = ids[1] .. "+" .. ids[2]
		activeRecipeLookup[key] = recipe.id
	end
end

---------------------------------------------------------------------------
-- Broadcast
---------------------------------------------------------------------------

local function broadcast()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local remote = remotes:FindFirstChild("SeasonalUpdate")
	if not remote then return end

	if activeEvent then
		(remote :: RemoteEvent):FireAllClients(activeEvent.id, activeEvent.name, activeEvent.shopBannerText)
	else
		(remote :: RemoteEvent):FireAllClients(nil, nil, nil)
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function SeasonalService.init(dataServiceRef: any)
	DataService = dataServiceRef

	-- Determine the event active at server start
	activeEvent = findActiveEvent()
	buildIndex(activeEvent)

	-- Re-check every 10 minutes in case the event window opens or closes
	-- while the server is running (midnight rollover)
	task.spawn(function()
		while true do
			task.wait(600)
			local newEvent = findActiveEvent()
			if newEvent ~= activeEvent then
				activeEvent = newEvent
				buildIndex(activeEvent)
				broadcast()
			end
		end
	end)
end

--- Returns the active seasonal event, or nil if none is running.
function SeasonalService.getActiveEvent(): typeof(SeasonalContent.EVENTS[1])?
	return activeEvent
end

--- Returns the active ingredient definition for the given id, or nil.
function SeasonalService.getActiveIngredient(id: string): typeof(SeasonalContent.EVENTS[1].ingredients[1])?
	return activeIngredientIndex[id]
end

--- Returns the active recipe for a pair of ingredient ids (order-independent), or nil.
function SeasonalService.lookupActiveRecipe(idA: string, idB: string): typeof(SeasonalContent.EVENTS[1].recipes[1])?
	if not activeEvent then return nil end

	local ids = { idA, idB }
	table.sort(ids)
	local key = ids[1] .. "+" .. ids[2]
	local recipeId = activeRecipeLookup[key]
	if not recipeId then return nil end

	return SeasonalContent.RECIPE_BY_ID[recipeId]
end

--- Returns the payload the client needs to render the seasonal shop section.
--- Call on player join and on SeasonalUpdate.
function SeasonalService.getClientPayload(): { any }
	if not activeEvent then return {} end
	return {
		eventId      = activeEvent.id,
		eventName    = activeEvent.name,
		bannerText   = activeEvent.shopBannerText,
		ingredients  = activeEvent.ingredients,
		recipeIds    = (function()
			local ids: { string } = {}
			for _, r in activeEvent.recipes do
				table.insert(ids, r.id)
			end
			return ids
		end)(),
	}
end

return SeasonalService
