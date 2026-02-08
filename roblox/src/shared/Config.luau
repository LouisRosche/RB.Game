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

--- Gold awarded to every new player on first join.
Config.STARTING_GOLD = 100

--- Maximum lab upgrade level a player can reach.
Config.MAX_LAB_LEVEL = 3

--- Maximum cauldron upgrade level a player can reach.
Config.MAX_CAULDRON_LEVEL = 3

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
	[1] = { name = "Starter",     plots = 2, cost = 0 },
	[2] = { name = "Apprentice",  plots = 4, cost = 500 },
	[3] = { name = "Alchemist",   plots = 6, cost = 2000 },
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
	[1] = { name = "Basic",  brewTime = 10, valueBonus = 1.0,  cost = 0 },
	[2] = { name = "Copper", brewTime = 7,  valueBonus = 1.1,  cost = 300 },
	[3] = { name = "Silver", brewTime = 4,  valueBonus = 1.25, cost = 1500 },
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
Config.OFFLINE_GROWTH = true

return Config
