--[[
	Ingredients.luau
	Defines every plantable ingredient in the game.
	Keyed by a stable string ID used throughout server and client code.
]]

local Ingredients = {}

--============================================================================--
-- Type definition
--============================================================================--

export type IngredientDef = {
	displayName: string,
	growthTime: number,   -- seconds until the plant is fully grown
	seedCost: number,     -- gold cost to purchase one seed
	baseValue: number,    -- base gold value before rarity multipliers
	color: Color3,        -- representative colour for UI / 3D visuals
	description: string,  -- flavour text shown in the shop and tooltips
}

--============================================================================--
-- Ingredient definitions (keyed by ingredient ID)
--============================================================================--

Ingredients.Moonpetal: IngredientDef = {
	displayName = "Moonpetal",
	growthTime = 30,
	seedCost = 5,
	baseValue = 10,
	color = Color3.fromRGB(100, 150, 255),
	description = "A luminous blue flower that blooms under moonlight",
}

Ingredients.Fireroot: IngredientDef = {
	displayName = "Fireroot",
	growthTime = 45,
	seedCost = 10,
	baseValue = 15,
	color = Color3.fromRGB(255, 80, 30),
	description = "A smoldering root that radiates warmth",
}

Ingredients.Shadowmoss: IngredientDef = {
	displayName = "Shadowmoss",
	growthTime = 60,
	seedCost = 20,
	baseValue = 20,
	color = Color3.fromRGB(140, 50, 200),
	description = "A dark moss that thrives in the absence of light",
}

Ingredients.Starbloom: IngredientDef = {
	displayName = "Starbloom",
	growthTime = 90,
	seedCost = 40,
	baseValue = 30,
	color = Color3.fromRGB(255, 220, 50),
	description = "A radiant blossom infused with starlight",
}

--============================================================================--
-- Helpers
--============================================================================--

--- Returns all ingredients as an ordered array sorted by seedCost ascending.
--- Useful for rendering the shop UI in a consistent order.
function Ingredients.getList(): { { id: string, def: IngredientDef } }
	local list: { { id: string, def: IngredientDef } } = {}

	for id, def in Ingredients do
		-- Skip non-ingredient entries (functions, etc.)
		if type(def) == "table" and (def :: any).seedCost ~= nil then
			table.insert(list, { id = id, def = def :: IngredientDef })
		end
	end

	table.sort(list, function(a, b)
		return a.def.seedCost < b.def.seedCost
	end)

	return list
end

return Ingredients
