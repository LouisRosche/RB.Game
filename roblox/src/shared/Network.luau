--[[
	Network.luau
	Defines all RemoteEvent name constants used for client-server communication.
	The server creates these RemoteEvents at runtime inside ReplicatedStorage.Remotes.
]]

local Network = {}

--============================================================================--
-- Client -> Server events
--============================================================================--

--- Player requests to purchase a seed from the shop.
Network.BuySeed = "BuySeed"

--- Player requests to plant a seed on an available plot.
Network.PlantSeed = "PlantSeed"

--- Player requests to harvest a mature plant from a plot.
Network.Harvest = "Harvest"

--- Player requests to brew a potion from two harvested ingredients.
Network.BrewPotion = "BrewPotion"

--- Player requests to sell a brewed potion for Essence.
Network.SellPotion = "SellPotion"

--- Player requests to upgrade their lab to the next level.
Network.UpgradeLab = "UpgradeLab"

--- Player requests to upgrade their cauldron to the next level.
Network.UpgradeCauldron = "UpgradeCauldron"

--- Player equips an owned cosmetic item. Payload: cosmeticId (string).
--- Server validates ownership before applying; state syncs back on success.
Network.EquipCosmetic = "EquipCosmetic"

--- Client notifies server to re-verify a game pass after a purchase prompt.
--- Payload: passId (number). Server calls UserOwnsGamePassAsync and updates OwnedPasses.
Network.VerifyGamePass = "VerifyGamePass"

--============================================================================--
-- Server -> Client events
--============================================================================--

--- Server pushes the authoritative player state to the client.
Network.StateSync = "StateSync"

--- Server sends a notification message to the client UI.
Network.Notification = "Notification"

--- Server notifies a client that they discovered a new recipe for the first time.
--- Payload: recipeId (string), recipeName (string), isSessionFirst (boolean)
Network.RecipeDiscovered = "RecipeDiscovered"

--- Client requests the discovery summary (count of recipes found vs total).
--- Server responds via StateSync (already includes DiscoveredRecipes in data).
Network.RequestDiscoverySummary = "RequestDiscoverySummary"

--- Client notifies server that the player has completed the first-session tutorial.
--- Server saves TutorialCompleted = true to prevent showing it again.
Network.TutorialComplete = "TutorialComplete"

--- Server broadcasts the top-N leaderboard entries to all clients.
--- Payload: array of { rank: number, name: string, score: number }
Network.LeaderboardUpdate = "LeaderboardUpdate"

--- Server notifies the harvesting client of the exact plot and rarity so the
--- client can play a localised particle burst. Payload: plotIndex (number), rarity (string).
Network.HarvestEffect = "HarvestEffect"

--- Server notifies the brewing client that their brew completed so the client
--- can play a cauldron particle burst. No payload.
Network.BrewEffect = "BrewEffect"

--- Server broadcasts seasonal event state to all clients (on start and on change).
--- Payload: eventId (string|nil), eventName (string|nil), bannerText (string|nil).
--- nil values mean no event is currently active.
Network.SeasonalUpdate = "SeasonalUpdate"

--============================================================================--
-- Helpers
--============================================================================--

--- Returns an array of all event name strings (useful for bulk RemoteEvent creation).
function Network.getAllEventNames(): { string }
	return {
		-- Client -> Server
		Network.BuySeed,
		Network.PlantSeed,
		Network.Harvest,
		Network.BrewPotion,
		Network.SellPotion,
		Network.UpgradeLab,
		Network.UpgradeCauldron,
		Network.RequestDiscoverySummary,
		Network.TutorialComplete,
		Network.EquipCosmetic,
		Network.VerifyGamePass,
		-- Server -> Client
		Network.StateSync,
		Network.Notification,
		Network.RecipeDiscovered,
		Network.LeaderboardUpdate,
		Network.HarvestEffect,
		Network.BrewEffect,
		Network.SeasonalUpdate,
	}
end

return Network
