--[[
	Strings.luau
	All player-facing text lives here. No string literals should be hardcoded
	in UI or gameplay code -- always reference this module instead.

	Dynamic values use {placeholder} syntax. At display time the UI code
	performs string.gsub(template, "{key}", value) to fill them in.

	This flat table structure makes future i18n / localisation straightforward:
	swap the table or merge an override table per locale.
]]

local Strings = {}

--============================================================================--
-- UI labels (buttons, headers, tabs)
--============================================================================--

Strings.GOLD              = "Gold"
Strings.SHOP              = "Shop"
Strings.INVENTORY         = "Inventory"
Strings.BREW              = "Brew"
Strings.SELL              = "Sell"
Strings.UPGRADE_LAB       = "Upgrade Lab"
Strings.UPGRADE_CAULDRON  = "Upgrade Cauldron"
Strings.CLOSE             = "Close"
Strings.PLANT             = "Plant"
Strings.HARVEST           = "Harvest"

--============================================================================--
-- Notification messages
--============================================================================--

Strings.PURCHASED_ITEM         = "Purchased {item}!"
Strings.PLANTED_ITEM           = "Planted {item}!"
Strings.HARVESTED_ITEM         = "Harvested {rarity} {item}!"
Strings.BREWED_POTION          = "Brewed {potion}! Worth {value} gold"
Strings.SOLD_POTION            = "Sold {potion} for {value} gold!"
Strings.NOT_ENOUGH_GOLD        = "Not enough gold!"
Strings.NO_EMPTY_PLOTS         = "No empty plots!"
Strings.INVENTORY_FULL         = "Inventory full!"
Strings.LAB_UPGRADED           = "Lab upgraded to {level}!"
Strings.CAULDRON_UPGRADED      = "Cauldron upgraded to {level}!"

--============================================================================--
-- Descriptive labels (stats, tooltips)
--============================================================================--

Strings.LEVEL_LABEL       = "Level {level}"
Strings.COST_LABEL        = "Cost: {cost}"
Strings.VALUE_LABEL       = "Value: {value}"
Strings.GROWTH_LABEL      = "Growth: {time}s"
Strings.SEED_COST_LABEL   = "Seed Cost: {cost}"

--============================================================================--
-- Empty / placeholder states
--============================================================================--

Strings.NO_INGREDIENTS    = "No ingredients"
Strings.NO_POTIONS        = "No potions"
Strings.SELECT_TO_BREW    = "Select 2 ingredients to brew"

return Strings
