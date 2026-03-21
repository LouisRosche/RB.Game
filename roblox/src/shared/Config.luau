--[[
	Config.luau
	Single source of truth for ALL game balance constants.
	Every tunable number lives here so designers can adjust the game
	from one place without hunting through gameplay code.
]]

local Config = {}

--============================================================================--
-- Starting values
--============================================================================--

--- Essence awarded to every new player on first join.
--- Enough to buy several cheap seeds and experience the loop, but NOT enough
--- to immediately unlock expensive ingredients. Scarcity teaches the value
--- of Essence and motivates the first few brew-sell cycles.
Config.STARTING_ESSENCE = 50

--- Maximum lab upgrade level a player can reach.
Config.MAX_LAB_LEVEL = 5

--- Maximum cauldron upgrade level a player can reach.
Config.MAX_CAULDRON_LEVEL = 5

--============================================================================--
-- Lab levels
-- Each level unlocks additional garden plots for planting ingredients.
--============================================================================--

export type LabLevelDef = {
	name: string,
	plots: number,
	cost: number,
}

Config.LAB_LEVELS: { [number]: LabLevelDef } = {
	[1] = { name = "Starter",       plots = 2, cost = 0 },
	[2] = { name = "Apprentice",    plots = 3, cost = 750 },
	[3] = { name = "Alchemist",     plots = 4, cost = 3000 },
	[4] = { name = "Master",        plots = 5, cost = 10000 },
	[5] = { name = "Grand Master",  plots = 6, cost = 30000 },
}

--============================================================================--
-- Cauldron levels
-- Higher-tier cauldrons brew faster and increase potion sell value.
--============================================================================--

export type CauldronLevelDef = {
	name: string,
	brewTime: number,
	valueBonus: number,
	cost: number,
}

Config.CAULDRON_LEVELS: { [number]: CauldronLevelDef } = {
	[1] = { name = "Basic",     brewTime = 12, valueBonus = 1.0,  cost = 0 },
	[2] = { name = "Copper",    brewTime = 10, valueBonus = 1.1,  cost = 500 },
	[3] = { name = "Silver",    brewTime = 8,  valueBonus = 1.2,  cost = 2500 },
	[4] = { name = "Gold",      brewTime = 6,  valueBonus = 1.35, cost = 8000 },
	[5] = { name = "Legendary", brewTime = 4,  valueBonus = 1.5,  cost = 25000 },
}

--============================================================================--
-- Mutation tiers
-- When a plant is harvested it rolls a rarity tier that multiplies value.
-- The chances must sum to 1.0. Ordered from most to least common.
--============================================================================--

export type MutationTierDef = {
	name: string,
	chance: number,
	multiplier: number,
	color: Color3,
}

Config.MUTATION_TIERS: { MutationTierDef } = {
	{ name = "Common",    chance = 0.60, multiplier = 1,  color = Color3.fromRGB(200, 200, 200) },
	{ name = "Uncommon",  chance = 0.25, multiplier = 2,  color = Color3.fromRGB(0, 200, 0) },
	{ name = "Rare",      chance = 0.10, multiplier = 5,  color = Color3.fromRGB(0, 100, 255) },
	{ name = "Epic",      chance = 0.04, multiplier = 15, color = Color3.fromRGB(160, 0, 255) },
	{ name = "Legendary", chance = 0.01, multiplier = 50, color = Color3.fromRGB(255, 215, 0) },
}

--============================================================================--
-- Plot layout
-- Controls the spatial arrangement of player lab instances in the world.
--============================================================================--

--- Studs between the centres of adjacent garden plots within a lab.
Config.PLOT_SPACING = 8

--- Physical size of each garden plot part.
Config.PLOT_SIZE = Vector3.new(5, 1, 5)

--- Studs between the origins of different player labs so they don't overlap.
Config.LAB_OFFSET = 50

--============================================================================--
-- Growth
--============================================================================--

--- When true, planted ingredients continue to grow while the player is offline.
--- Always true — no FOMO mechanics around growth timers.
Config.OFFLINE_GROWTH = true

--============================================================================--
-- Educational / anti-dark-pattern settings
--============================================================================--

--- When true, mutation odds are shown transparently in the journal.
--- Players always know the exact probability of each rarity.
Config.SHOW_MUTATION_ODDS = true

--- When true, a recipe discovery celebration effect plays on the client.
Config.CELEBRATE_DISCOVERIES = true

--- Maximum notification stack height before oldest are discarded.
--- Keeps the screen readable without suppressing important messages.
Config.MAX_NOTIFICATIONS = 5

--- How long (seconds) each notification stays before fading out.
--- Long enough to read, short enough to not clutter the screen.
Config.NOTIFICATION_DURATION = 4

--============================================================================--
-- Inventory caps
-- Roblox DataStore keys have a 4 MB serialised limit. Uncapped inventory
-- arrays are the most common cause of silent data corruption.
-- These limits are generous for normal play while preventing runaway growth.
--============================================================================--

--- Maximum harvested ingredients held before harvest is blocked.
--- Players must brew before picking more plants.
Config.MAX_INGREDIENTS = 30

--- Maximum brewed potions held before brewing is blocked.
--- Players must sell before brewing more potions.
Config.MAX_POTIONS = 20

--- Maximum pre-purchased seeds awaiting planting.
Config.MAX_SEEDS = 12

--- Hard cap on Essence balance. Prevents integer overflow / economy inflation.
--- 10 million is ~100x the cost of maxing every upgrade; generous but bounded.
Config.MAX_ESSENCE = 10_000_000

--============================================================================--
-- Phase 2: Monetisation
--============================================================================--

--- Multiplier applied to brew time when the player owns the Speed Brew game pass.
--- 0.5 = 2× faster (brew time halved). Change here to tune the pass value.
Config.SPEED_BREW_MULTIPLIER = 0.5

--- When true, GrowthService will auto-harvest mature plots for players who
--- own the Auto-Harvest game pass (adds to ingredients, still respects cap).
Config.AUTO_HARVEST_ENABLED = true

--- Chat tag prefix shown for VIP pass owners. Set to "" to disable.
Config.VIP_CHAT_TAG = "[VIP] "

--============================================================================--
-- Rewarded Video Ads
-- Players opt-in to watch a short ad in exchange for in-game rewards.
-- Monetises the ~95% of players who never spend Robux.
--============================================================================--

--- Essence bonus awarded after watching a rewarded video ad.
Config.AD_REWARD_ESSENCE = 50

--- Cooldown in seconds between rewarded ad watches (per player).
--- 600 = 10 minutes.
Config.AD_COOLDOWN_SECONDS = 600

--- Duration in seconds for the 2x earnings boost option (alternative reward).
--- 300 = 5 minutes.
Config.AD_BOOST_DURATION = 300

--- Multiplier applied to potion sell value during the 2x boost window.
Config.AD_BOOST_MULTIPLIER = 2.0

--- Developer Product ID used as the AdReward for rewarded video ads.
--- Create this product in Creator Dashboard (price doesn't matter — Roblox
--- handles reward delivery internally). Set to 0 to disable ads.
Config.AD_REWARD_PRODUCT_ID = 0  -- PLACEHOLDER: replace with real ID

return Config
