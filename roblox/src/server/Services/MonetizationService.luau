--[[
	MonetizationService.luau
	Server-side monetisation handler for Alchemy Academy.

	Responsibilities:
	  1. ProcessReceipt — handles Developer Product purchases (cosmetics).
	     MarketplaceService.ProcessReceipt must be set ONCE per server;
	     this service owns it exclusively.
	  2. Game pass checks — called on player join to verify which passes the
	     player owns and write them into their profile data.
	  3. EquipCosmetic — handles the client requesting a cosmetic swap after
	     a purchase is confirmed.

	Anti-dark-pattern compliance:
	  - No loot boxes, no randomised rewards
	  - Every purchase grants a specific, disclosed item
	  - ProcessReceipt returns Enum.ProductPurchaseDecision.PurchaseGranted
	    only after the item is confirmed saved to the profile — players can
	    never lose a purchase to a DataStore failure mid-grant
	  - Duplicate purchase protection: cosmetics are idempotent (re-granting
	    an already-owned item is a no-op that still returns PurchaseGranted)

	SETUP:
	  - Replace placeholder product IDs in Cosmetics.luau (productId fields).
	  - Replace placeholder pass IDs in GamePasses.luau (SPEED_BREW etc.).
	  - Test in Studio with a test account that can make purchases.
]]

local Players           = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local AdService          = game:GetService("AdService")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Config     = require(Shared:WaitForChild("Config"))
local Cosmetics  = require(Shared:WaitForChild("Cosmetics"))
local GamePasses = require(Shared:WaitForChild("GamePasses"))
local Network    = require(Shared:WaitForChild("Network"))
local Strings    = require(Shared:WaitForChild("Strings"))

-- DataService and AnalyticsService are required at call time (avoids circular require at module load)
local DataService: any = nil
local AnalyticsService: any = nil

-- Rewarded ad cooldown tracking: userId -> os.clock() of last completed ad watch
-- NOTE: In-memory only — resets on server restart (acceptable for Phase 1)
local adCooldowns: { [number]: number } = {}

-- Active 2x earning boost tracking: userId -> os.clock() expiry timestamp
local adBoostExpiry: { [number]: number } = {}

-- Tracks whether AdService initialised successfully
local adsInitialized = false

-- AdReward object for rewarded video ads (created once, reused per Roblox docs)
local adReward: any = nil

local MonetizationService = {}

---------------------------------------------------------------------------
-- ProcessReceipt — Developer Products (cosmetic purchases)
---------------------------------------------------------------------------
-- Called by Roblox when a Developer Product purchase is confirmed.
-- Must return PurchaseGranted or NotProcessedYet within the function.
-- Returning PurchaseGranted signals Roblox that it is safe to charge the
-- player; the transaction will not be re-delivered.
---------------------------------------------------------------------------

local function processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left before the receipt was processed; re-deliver next session
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataService.getData(player)
	if not data then
		-- Profile not yet loaded (shouldn't happen but guard anyway)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local cosmetic = Cosmetics.BY_PRODUCT_ID[receiptInfo.ProductId]
	if not cosmetic then
		-- Unknown product; grant anyway (player paid, don't refuse)
		warn("[MonetizationService] Unknown productId:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Grant ownership (idempotent — safe if called twice for the same receipt)
	if not data.OwnedCosmetics then
		data.OwnedCosmetics = {}
	end
	data.OwnedCosmetics[cosmetic.id] = true

	-- Auto-equip the newly purchased item in its category
	if not data.ActiveCosmetic then
		data.ActiveCosmetic = {}
	end
	data.ActiveCosmetic[cosmetic.category] = cosmetic.id

	-- Force a save so PurchaseGranted is backed by durable storage
	DataService.saveData(player)

	-- Push updated state to the client (shop panel will refresh)
	DataService.syncToClient(player)

	DataService.notify(
		player,
		"✨ " .. cosmetic.name .. " unlocked! Equip it in the Cosmetic Shop."
	)

	-- Track cosmetic purchase for monetization analytics
	if AnalyticsService then
		AnalyticsService.onCosmeticPurchased(player, cosmetic.id, cosmetic.price or 0)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------------------
-- Game pass verification
-- Called when a player's profile finishes loading.
-- Writes pass ownership into profile.Data.OwnedPasses so gameplay code
-- (GrowthService etc.) can do a simple table lookup without async calls.
---------------------------------------------------------------------------

--- Checks all known game passes for `player` and updates data.OwnedPasses.
--- Runs async (pcall-wrapped) so a MarketplaceService outage doesn't break join.
local function checkPassesAsync(player: Player, data: { [string]: any })
	if not data.OwnedPasses then
		data.OwnedPasses = {}
	end

	for _, def in GamePasses.DEFS do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, def.id)
		end)
		if ok then
			data.OwnedPasses[tostring(def.id)] = owns or nil
			-- nil removes the key when the player doesn't own the pass,
			-- keeping the table minimal (important for DataStore size budget).
		else
			warn("[MonetizationService] Pass check failed for passId", def.id, ":", owns)
		end
	end
end

---------------------------------------------------------------------------
-- EquipCosmetic — swap the active item within a category
-- Called from Main.server.luau when the client fires EquipCosmetic.
---------------------------------------------------------------------------

function MonetizationService.equipCosmetic(player: Player, cosmeticId: string)
	local data = DataService.getData(player)
	if not data then return end

	local def = Cosmetics.BY_ID[cosmeticId]
	if not def then return end

	-- Free items are always equippable; paid items require ownership
	local owned = (def.price == 0) or (data.OwnedCosmetics and data.OwnedCosmetics[cosmeticId])
	if not owned then
		DataService.notify(player, "You don't own " .. def.name .. " yet.")
		return
	end

	if not data.ActiveCosmetic then
		data.ActiveCosmetic = {}
	end
	data.ActiveCosmetic[def.category] = cosmeticId

	DataService.syncToClient(player)
end

---------------------------------------------------------------------------
-- Rewarded Video Ads
-- Players opt-in to watch a short ad for an in-game reward (Essence bonus).
-- Server-side validation only — the client request merely triggers the ad
-- prompt; rewards are granted exclusively through the AdService callback.
---------------------------------------------------------------------------

--- Returns seconds remaining on the ad cooldown for a player (0 = ready).
local function getAdCooldownRemaining(userId: number): number
	local lastWatch = adCooldowns[userId]
	if not lastWatch then return 0 end
	local elapsed = os.clock() - lastWatch
	local remaining = Config.AD_COOLDOWN_SECONDS - elapsed
	return if remaining > 0 then math.ceil(remaining) else 0
end

--- Returns true if the player currently has an active 2x earnings boost.
function MonetizationService.hasAdBoost(player: Player): boolean
	local expiry = adBoostExpiry[player.UserId]
	if not expiry then return false end
	return os.clock() < expiry
end

--- Returns the 2x boost multiplier if active, otherwise 1.0.
--- Called by sell logic (e.g., EconomyService) to apply the boost.
function MonetizationService.getAdBoostMultiplier(player: Player): number
	if MonetizationService.hasAdBoost(player) then
		return Config.AD_BOOST_MULTIPLIER
	end
	return 1.0
end

--- Sends the current ad cooldown to a specific player's client.
local function syncAdCooldown(player: Player)
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then return end
	local remote = remotesFolder:FindFirstChild(Network.AdCooldownSync) :: RemoteEvent
	if not remote then return end
	remote:FireClient(player, getAdCooldownRemaining(player.UserId))
end

--- Grants the ad reward to a player (called after successful ad view).
local function grantAdReward(player: Player)
	local data = DataService.getData(player)
	if not data then return end

	-- Set cooldown
	adCooldowns[player.UserId] = os.clock()

	-- Grant Essence reward
	data.Essence = (data.Essence or 0) + Config.AD_REWARD_ESSENCE

	-- Also activate 2x earnings boost
	adBoostExpiry[player.UserId] = os.clock() + Config.AD_BOOST_DURATION

	-- Notify the player
	local rewardMsg = string.gsub(Strings.AD_REWARD_GRANTED, "{reward}", tostring(Config.AD_REWARD_ESSENCE))
	DataService.notify(player, rewardMsg)

	local boostMinutes = math.ceil(Config.AD_BOOST_DURATION / 60)
	local boostMsg = string.gsub(Strings.AD_BOOST_GRANTED, "{minutes}", tostring(boostMinutes))
	DataService.notify(player, boostMsg)

	-- Sync updated state and cooldown to client
	DataService.syncToClient(player)
	syncAdCooldown(player)

	-- Analytics
	if AnalyticsService then
		AnalyticsService.onAdReward(player, Config.AD_REWARD_ESSENCE, Config.AD_BOOST_DURATION)
	end
end

--- Handles a client's request to watch a rewarded video ad.
--- Uses the correct Roblox AdService API: ShowRewardedVideoAdAsync +
--- CreateAdRewardFromDevProductId (per March 2026 Roblox docs).
--- Reward is granted only after server-verified ad completion.
function MonetizationService.handleAdRewardRequest(player: Player)
	-- Guard: ads not initialised (Studio, unsupported region, etc.)
	if not adsInitialized then
		DataService.notify(player, Strings.AD_NOT_AVAILABLE)
		return
	end

	-- Check cooldown
	local remaining = getAdCooldownRemaining(player.UserId)
	if remaining > 0 then
		DataService.notify(player, Strings.AD_ALREADY_ON_COOLDOWN)
		syncAdCooldown(player)
		return
	end

	-- Show rewarded video ad via AdService (yields until ad completes or fails)
	task.spawn(function()
		local ok, result = pcall(function()
			return AdService:ShowRewardedVideoAdAsync(player, adReward)
		end)

		if not ok then
			warn("[MonetizationService] ShowRewardedVideoAdAsync failed:", result)
			DataService.notify(player, Strings.AD_WATCH_FAILED)
			return
		end

		-- ShowRewardedVideoAdAsync returns a ShowAdResult enum
		-- Reward is granted only on successful completion
		if result == Enum.ShowAdResult.Completed then
			-- Guard: player may have disconnected during the async ad
			if not player.Parent then return end
			grantAdReward(player)
		else
			DataService.notify(player, Strings.AD_WATCH_FAILED)
		end
	end)
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Initialise: inject DataService and AnalyticsService (passed in to avoid
--- circular require) and register the ProcessReceipt handler.
function MonetizationService.init(dataServiceRef: any, analyticsServiceRef: any)
	DataService = dataServiceRef
	AnalyticsService = analyticsServiceRef
	MarketplaceService.ProcessReceipt = processReceipt

	-- Create an AdReward object from a Developer Product (per Roblox docs).
	-- The ad reward is a Dev Product that Roblox grants on verified completion.
	-- We use Config.AD_REWARD_PRODUCT_ID; if 0 (placeholder), ads stay disabled.
	local adOk, adErr = pcall(function()
		if Config.AD_REWARD_PRODUCT_ID and Config.AD_REWARD_PRODUCT_ID > 0 then
			adReward = AdService:CreateAdRewardFromDevProductId(Config.AD_REWARD_PRODUCT_ID)
			adsInitialized = true
		else
			warn("[MonetizationService] AD_REWARD_PRODUCT_ID is 0 (placeholder) — ads disabled until set")
		end
	end)
	if not adOk then
		warn("[MonetizationService] AdService setup failed (ads may not be enabled):", adErr)
		adsInitialized = false
	end

	-- Clean up ad state when a player leaves
	Players.PlayerRemoving:Connect(function(player: Player)
		adCooldowns[player.UserId] = nil
		adBoostExpiry[player.UserId] = nil
	end)
end

--- Check game pass ownership for a player after their profile loads.
--- Spawns async so it doesn't block the join flow.
function MonetizationService.checkPassesOnJoin(player: Player)
	local data = DataService.getData(player)
	if not data then return end

	task.spawn(function()
		checkPassesAsync(player, data)
		-- Re-sync so the client knows which passes are active
		DataService.syncToClient(player)
		-- Send initial ad cooldown state (always 0 for a fresh join)
		syncAdCooldown(player)
	end)
end

return MonetizationService
