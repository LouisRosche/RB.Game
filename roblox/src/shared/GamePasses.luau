--[[
	GamePasses.luau
	Defines all Roblox Game Passes available in Alchemy Academy.

	Design philosophy:
	  - All passes are CONVENIENCE or COSMETIC only — no gameplay advantage
	    that prevents progress without paying
	  - Every benefit a pass provides can also be achieved through normal play
	    (Speed Brew = same end-game as grinding Cauldron upgrades; just faster)
	  - Prices are intentional: individual passes < bundle equivalent

	SETUP — before launch:
	  1. Create each pass in Creator Hub → Monetization → Passes.
	  2. Replace the placeholder PASS_ID values with the real numeric IDs.
	  3. MonetizationService.checkPassesOnJoin() uses UserOwnsGamePassAsync
	     to verify ownership and write flags to the player's profile.

	Pass benefit flags are stored in profile.Data.OwnedPasses (set of pass IDs).
	GamePasses.hasPass(data, passId) is the canonical check used by all services.
]]

local GamePasses = {}

---------------------------------------------------------------------------
-- Pass IDs  (replace placeholders before launch)
---------------------------------------------------------------------------

--- 2× brewing speed on all cauldron tiers.
--- Normal max brew time = 10 s; with pass = 5 s at Basic, 2 s at Silver.
GamePasses.SPEED_BREW    = 11111001  -- ⚠ replace with real Game Pass ID

--- Plots auto-harvest into the ingredient bag when they mature.
--- Player still needs to be in-game (not a true idle mechanic — avoids FOMO).
GamePasses.AUTO_HARVEST  = 11111002  -- ⚠ replace with real Game Pass ID

--- VIP bundle: exclusive Celestial Lab theme pre-unlocked, golden chat tag,
--- and a permanent "VIP" nameplate above the lab entrance sign.
GamePasses.VIP           = 11111003  -- ⚠ replace with real Game Pass ID

---------------------------------------------------------------------------
-- Display metadata (used by shop UI and confirmation prompts)
---------------------------------------------------------------------------

export type GamePassDef = {
	id:          number,
	name:        string,
	price:       number,  -- Robux (informational — actual price set in Creator Hub)
	description: string,
	benefits:    { string },  -- bullet list shown in purchase UI
}

GamePasses.DEFS: { GamePassDef } = {
	{
		id          = GamePasses.SPEED_BREW,
		name        = "Speed Brew",
		price       = 199,
		description = "Your cauldron brews potions at 2× speed — permanently.",
		benefits    = {
			"Basic cauldron: 10 s → 5 s",
			"Copper cauldron: 7 s → 3.5 s",
			"Silver cauldron: 4 s → 2 s",
			"Stacks with cauldron upgrades",
		},
	},
	{
		id          = GamePasses.AUTO_HARVEST,
		name        = "Auto-Harvest",
		price       = 299,
		description = "Mature plants harvest themselves into your bag while you're active.",
		benefits    = {
			"No more clicking each plot",
			"Rarity rolls still apply",
			"Inventory cap still enforced (brew first!)",
			"Works on all current and future plots",
		},
	},
	{
		id          = GamePasses.VIP,
		name        = "VIP Alchemist",
		price       = 99,
		description = "Show your status with exclusive cosmetics and a golden tag.",
		benefits    = {
			"Celestial Lab theme (always unlocked)",
			"Gold [VIP] chat tag",
			"Glowing nameplate above your lab",
			"Early access to future VIP-only cosmetics",
		},
	},
}

--- Lookup by pass ID.
GamePasses.BY_ID: { [number]: GamePassDef } = {}
for _, def in GamePasses.DEFS do
	GamePasses.BY_ID[def.id] = def
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Returns true if the given player data table shows ownership of passId.
--- MonetizationService writes pass IDs into data.OwnedPasses on join.
function GamePasses.hasPass(data: { [string]: any }, passId: number): boolean
	if not data.OwnedPasses then return false end
	return data.OwnedPasses[tostring(passId)] == true
end

return GamePasses
