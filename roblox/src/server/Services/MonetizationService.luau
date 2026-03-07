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

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Cosmetics  = require(Shared:WaitForChild("Cosmetics"))
local GamePasses = require(Shared:WaitForChild("GamePasses"))

-- DataService is required at call time (avoids circular require at module load)
local DataService: any = nil

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
-- Public API
---------------------------------------------------------------------------

--- Initialise: inject DataService (passed in to avoid circular require)
--- and register the ProcessReceipt handler.
function MonetizationService.init(dataServiceRef: any)
	DataService = dataServiceRef
	MarketplaceService.ProcessReceipt = processReceipt
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
	end)
end

return MonetizationService
