--[[
	Config — Shared constants for the obby.
	Referenced by both server and client scripts.

	IMPORTANT: Replace all placeholder IDs before publishing.
	- Game pass / product IDs come from the Creator Dashboard after you create them.
	- Cross-promo place ID is the Alchemy Academy experience's root place.
]]

local Config = {}

--------------------------------------------------------------------------------
-- World / Stage layout
--------------------------------------------------------------------------------
Config.TOTAL_STAGES        = 40       -- checkpoints in world 1
Config.WORLDS              = 1        -- ship world 1 first; add more later
Config.FINISH_CHECKPOINT   = Config.TOTAL_STAGES

--------------------------------------------------------------------------------
-- Coins
--------------------------------------------------------------------------------
Config.COIN_BASE_VALUE     = 1        -- coins per basic pickup
Config.VIP_COIN_MULTIPLIER = 2        -- VIP players earn double

--------------------------------------------------------------------------------
-- Monetization — placeholder IDs (set in Creator Dashboard)
--------------------------------------------------------------------------------
Config.SKIP_STAGE_PRODUCT_ID   = 0    -- Developer Product: 50 Robux consumable
Config.VIP_GAME_PASS_ID        = 0    -- Game Pass: 200 Robux
Config.SKIP_STAGE_PRICE_ROBUX  = 50
Config.VIP_PASS_PRICE_ROBUX    = 200

--------------------------------------------------------------------------------
-- Cross-promotion
--------------------------------------------------------------------------------
Config.ALCHEMY_ACADEMY_PLACE_ID = 0   -- replace with real place ID
Config.CROSS_PROMO_MESSAGE       = "You beat World 1! Try Alchemy Academy — our full tycoon game!"

--------------------------------------------------------------------------------
-- Leaderboard
--------------------------------------------------------------------------------
Config.LEADERBOARD_MAX_ENTRIES = 10   -- top-N fastest times shown

--------------------------------------------------------------------------------
-- VIP perks
--------------------------------------------------------------------------------
Config.VIP_SPEED_BOOST     = 20       -- WalkSpeed = 16 + 20 = 36
Config.VIP_CHAT_TAG_TEXT   = "[VIP]"
Config.VIP_CHAT_TAG_COLOR  = Color3.fromRGB(255, 215, 0) -- gold

--------------------------------------------------------------------------------
-- Respawn
--------------------------------------------------------------------------------
Config.RESPAWN_Y_OFFSET    = 5        -- studs above checkpoint part

--------------------------------------------------------------------------------
-- Remote names (created by server, awaited by client)
--------------------------------------------------------------------------------
Config.REMOTES = {
	CheckpointReached  = "ObbyCheckpointReached",
	CoinCollected      = "ObbyCoinCollected",
	TimerSync          = "ObbyTimerSync",
	PlayerDied         = "ObbyPlayerDied",
	CrossPromo         = "ObbyCrossPromo",
	RequestSkip        = "ObbyRequestSkip",
	PurchaseResult     = "ObbyPurchaseResult",
	StatsSync          = "ObbyStatsSync",
}

return Config
