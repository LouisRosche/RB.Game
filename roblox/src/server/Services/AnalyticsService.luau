--[[
	AnalyticsService.luau
	Tracks player behaviour for the Phase 1 go/no-go decision AND ongoing
	data-driven iteration.

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
	    1. Session start          (new vs returning player)
	    2. First seed planted     (tutorial entry)
	    3. First harvest          (saw growth loop complete)
	    4. First brew             (discovered the crafting system)
	    5. First sell             (completed the core loop)
	    6. Session end            (duration + economy snapshot)

	  ADDITIONAL EVENTS for rapid iteration:
	    - SeedPurchased           (which ingredients players buy)
	    - RarityRolled            (verify RNG fairness at scale)
	    - InventoryFull           (hit cap — balancing signal)
	    - TutorialStep            (per-step completion for onboarding tuning)
	    - TutorialSkipped         (how many skip and at which step)
	    - ShopOpened              (UI engagement)
	    - JournalOpened           (educational content engagement)
	    - GamePassPrompted        (monetization funnel: showed prompt)
	    - GamePassPurchased       (monetization funnel: completed purchase)
	    - CosmeticPurchased       (monetization: cosmetic conversion)
	    - EssenceSnapshot         (economy health on session end)
	    - SeasonalSeedPurchased   (seasonal content engagement)

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

	-- Log whether this is a first-ever session (for new-player funnel).
	-- TutorialCompleted is false by default and set true after the tutorial,
	-- making it the cleanest proxy for "player has played before".
	local data = DataService.getData(player)
	local isNewPlayer = data and data.TutorialCompleted == false
	fireEvent(player, "SessionStart", if isNewPlayer then 1 else 0)
end

--- Called when a player leaves. Logs session duration and economy snapshot.
function AnalyticsService.onSessionEnd(player: Player)
	local userId = player.UserId
	local startTime = sessionStart[userId]
	if startTime then
		local durationSeconds = math.floor(tick() - startTime)
		fireEvent(player, "SessionDuration", durationSeconds)
	end

	-- Economy snapshot: log Essence balance so we can detect inflation/deflation
	local data = DataService.getData(player)
	if data then
		fireEvent(player, "EssenceSnapshot", data.Essence or 0)
		fireEvent(player, "LabLevelSnapshot", data.LabLevel or 1)
		fireEvent(player, "CauldronLevelSnapshot", data.CauldronLevel or 1)
		local discoveryCount = 0
		if data.DiscoveredRecipes then
			for _ in data.DiscoveredRecipes do
				discoveryCount += 1
			end
		end
		fireEvent(player, "DiscoverySnapshot", discoveryCount)
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

--- Called after a seed is purchased from the shop.
function AnalyticsService.onSeedPurchased(player: Player, ingredientId: string, cost: number)
	-- Hash ingredient name to a number for event tracking
	-- Use string.byte sum as a cheap numeric identifier
	local idHash = 0
	for i = 1, #ingredientId do
		idHash += string.byte(ingredientId, i)
	end
	fireEvent(player, "SeedPurchased", idHash)
	fireEvent(player, "SeedCost", cost)
end

--- Called after a harvest completes.
--- Fires "FunnelHarvest" once per session (first harvest only).
--- Also logs rarity for RNG fairness verification.
function AnalyticsService.onHarvest(player: Player, ingredientId: string, rarity: string)
	if not getFlag(player, "harvested") then
		setFlag(player, "harvested")
		fireEvent(player, "FunnelHarvest", 1)
	end

	-- Log rarity tier as numeric index for distribution analysis
	local rarityIndex = ({ Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 })[rarity] or 0
	fireEvent(player, "RarityRolled", rarityIndex)
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

--- Called after a potion is sold.
--- Fires "FunnelSell" once per session for core loop completion tracking.
function AnalyticsService.onSell(player: Player, value: number)
	if not getFlag(player, "sold") then
		setFlag(player, "sold")
		fireEvent(player, "FunnelSell", 1)
	end
	fireEvent(player, "SellValue", value)
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

--- Called when a player hits an inventory cap.
--- capType: "Seeds", "Ingredients", or "Potions"
function AnalyticsService.onInventoryFull(player: Player, capType: string)
	local capIndex = ({ Seeds = 1, Ingredients = 2, Potions = 3 })[capType] or 0
	fireEvent(player, "InventoryFull", capIndex)
end

--- Called when a tutorial step is completed.
function AnalyticsService.onTutorialStep(player: Player, step: number)
	fireEvent(player, "TutorialStep", step)
end

--- Called when a player skips the tutorial.
function AnalyticsService.onTutorialSkipped(player: Player, atStep: number)
	fireEvent(player, "TutorialSkipped", atStep)
end

--- Called when a game pass purchase prompt is shown.
function AnalyticsService.onGamePassPrompted(player: Player, passId: number)
	fireEvent(player, "GamePassPrompted", passId)
end

--- Called when a game pass purchase completes.
function AnalyticsService.onGamePassPurchased(player: Player, passId: number)
	fireEvent(player, "GamePassPurchased", passId)
end

--- Called when a cosmetic is purchased via Developer Product.
function AnalyticsService.onCosmeticPurchased(player: Player, cosmeticId: string, price: number)
	fireEvent(player, "CosmeticPurchased", price)
end

--- Called when a seasonal seed is purchased.
function AnalyticsService.onSeasonalPurchased(player: Player, ingredientId: string, cost: number)
	fireEvent(player, "SeasonalSeedPurchased", cost)
end

return AnalyticsService
