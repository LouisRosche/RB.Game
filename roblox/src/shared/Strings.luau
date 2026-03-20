--[[
	Strings.luau
	All player-facing text lives here. No string literals should be hardcoded
	in UI or gameplay code -- always reference this module instead.

	Dynamic values use {placeholder} syntax. At display time the UI code
	performs string.gsub(template, "{key}", value) to fill them in.

	This flat table structure makes future i18n / localisation straightforward:
	swap the table or merge an override table per locale.

	Design philosophy:
	  - Celebratory, not pressuring
	  - Transparent (show odds, show what's happening)
	  - Educational (plant curiosity, not anxiety)
	  - Joyful, warm, encouraging
]]

local Strings = {}

--============================================================================--
-- UI labels (buttons, headers, tabs)
--============================================================================--

Strings.GOLD              = "Essence"          -- renamed from "Gold" for thematic fit
Strings.SHOP              = "Shop"
Strings.INVENTORY         = "Inventory"
Strings.BREW              = "Brew Potion"
Strings.SELL              = "Sell"
Strings.UPGRADE_LAB       = "Expand Lab"
Strings.UPGRADE_CAULDRON  = "Upgrade Cauldron"
Strings.CLOSE             = "Close"
Strings.PLANT             = "Plant"
Strings.HARVEST           = "Harvest"
Strings.JOURNAL           = "Alchemist's Journal"

-- Journal tabs
Strings.TAB_BASICS        = "How to Play"
Strings.TAB_INGREDIENTS   = "Ingredients"
Strings.TAB_RECIPES       = "Recipes"
Strings.TAB_ODDS          = "Odds & Fairness"
Strings.TAB_FUN_FACTS     = "Fun Facts"

--============================================================================--
-- Notification messages — celebratory, not pressuring
--============================================================================--

-- Positive outcomes
Strings.PURCHASED_ITEM    = "You got a {item} seed! Ready to plant."
Strings.PLANTED_ITEM      = "Planted {item}! It'll grow even while you're away."
Strings.BREWED_POTION     = "You brewed {potion}! Worth {value} Essence."
Strings.SOLD_POTION       = "Sold {potion} for {value} Essence!"
Strings.LAB_UPGRADED      = "Lab expanded to {level}! {plots} growing plots now."
Strings.CAULDRON_UPGRADED = "Cauldron upgraded to {level}! Brews {time}s faster."

-- Harvest notifications (educational framing of rarity)
Strings.HARVESTED_COMMON    = "Harvested {item}! A healthy Common specimen."
Strings.HARVESTED_UNCOMMON  = "Harvested {item}! Uncommon — ideal growing conditions."
Strings.HARVESTED_RARE      = "Harvested {item}! Rare — something special happened here!"
Strings.HARVESTED_EPIC      = "Harvested {item}! Epic — extraordinary conditions produced this."
Strings.HARVESTED_LEGENDARY = "Harvested {item}! LEGENDARY — a once-in-a-generation specimen!"

-- Error messages (helpful, not blame-y)
Strings.NOT_ENOUGH_GOLD       = "You need {amount} more Essence for that. Keep brewing!"
Strings.NO_EMPTY_PLOTS        = "All plots are in use. Harvest something first, or expand your lab!"
Strings.INVENTORY_FULL        = "Inventory is full — brew or sell some potions to make room."
Strings.PLOT_NOT_EMPTY        = "That plot is busy growing something."

-- Discovery messages
Strings.NEW_DISCOVERY         = "NEW DISCOVERY: {potion}! You figured out this recipe yourself!"
Strings.KNOWN_RECIPE          = "You brewed {potion} again. A classic!"
Strings.DISCOVERY_COUNT       = "Recipes discovered: {count} / {total}"

--============================================================================--
-- Descriptive labels (stats, tooltips)
--============================================================================--

Strings.LEVEL_LABEL       = "Level {level}"
Strings.COST_LABEL        = "Cost: {cost} Essence"
Strings.VALUE_LABEL       = "Value: {value} Essence"
Strings.GROWTH_LABEL      = "Grows in: {time}s"
Strings.SEED_COST_LABEL   = "Seed: {cost} Essence"
Strings.BREW_TIME_LABEL   = "Brew time: {time}s"
Strings.BONUS_LABEL       = "Value bonus: +{bonus}%"

--============================================================================--
-- Empty / placeholder states
--============================================================================--

Strings.NO_INGREDIENTS      = "No ingredients yet. Plant some seeds!"
Strings.NO_POTIONS          = "No potions yet. Try brewing some ingredients."
Strings.SELECT_TO_BREW      = "Select 2 ingredients to see the result"
Strings.UNKNOWN_RECIPE      = "No known reaction for this pair — interesting!"

--============================================================================--
-- Journal content
--============================================================================--

Strings.JOURNAL_WELCOME     = "Welcome, young alchemist! This journal tracks everything you discover. Every potion hides a real science secret — tap any recipe to learn more."
Strings.JOURNAL_ODDS_HEADER = "These are the true odds of each ingredient rarity. Nothing is hidden from you."
Strings.JOURNAL_ODDS_NOTE   = "Rarity is determined by a fair random roll at harvest. The server never adjusts these odds based on anything else."

-- Odds display (shown as percentage strings)
Strings.ODDS_COMMON         = "Common     60% chance  (×1 value)"
Strings.ODDS_UNCOMMON       = "Uncommon   25% chance  (×2 value)"
Strings.ODDS_RARE           = "Rare       10% chance  (×5 value)"
Strings.ODDS_EPIC           = "Epic        4% chance  (×15 value)"
Strings.ODDS_LEGENDARY      = "Legendary   1% chance  (×50 value)"

Strings.JOURNAL_FACTS_HEADER = "Did You Know?"

-- Plant readiness (informational, not urgent)
Strings.PLANT_READY         = "Your {item} is ready to harvest whenever you like!"

-- Offline growth (reassuring)
Strings.OFFLINE_GROWTH_MSG  = "Your plants kept growing while you were away. No rush — they'll wait for you."

--============================================================================--
-- Upgrade panel
--============================================================================--

Strings.MAX_LAB_LEVEL       = "Your lab is fully expanded! You've unlocked everything."
Strings.MAX_CAULDRON_LEVEL  = "Your cauldron is at its finest. Master alchemist equipment!"
Strings.UPGRADE_PREVIEW_LAB      = "+{plots} more growing plots → {name}"
Strings.UPGRADE_PREVIEW_CAULDRON = "{time}s brew time, +{bonus}% value → {name}"

--============================================================================--
-- Rewarded Video Ads — opt-in, celebratory, never pressuring
--============================================================================--

Strings.AD_WATCH_BUTTON           = "Watch Ad for Reward"
Strings.AD_WATCH_PROMPT           = "Watch a short video for {reward} bonus Essence!"
Strings.AD_COOLDOWN               = "Ad reward cooldown: {minutes}m {seconds}s"
Strings.AD_COOLDOWN_SHORT         = "{minutes}m {seconds}s"
Strings.AD_REWARD_GRANTED         = "Thanks for watching! +{reward} Essence bonus!"
Strings.AD_BOOST_GRANTED          = "2x Earnings activated for {minutes} minutes! Brew and sell now!"
Strings.AD_NOT_AVAILABLE          = "Video ads aren't available for you right now."
Strings.AD_ALREADY_ON_COOLDOWN    = "You've recently watched an ad. Try again in a few minutes!"
Strings.AD_WATCH_FAILED           = "Something went wrong with the ad. No worries — try again later!"

--============================================================================--
-- Legal / compliance
--============================================================================--

Strings.REFUND_NOTICE             = "All purchases are final. Prices shown in Robux. For billing issues, contact Roblox Support at roblox.com/support."
Strings.EXTERNAL_LINK_BLOCKED     = "External links are not available in your region."
Strings.PRIVACY_POLICY_LINK       = "Privacy Policy: alchemyacademy.game/privacy"
Strings.TERMS_OF_SERVICE_LINK     = "Terms of Service: alchemyacademy.game/terms"

return Strings
