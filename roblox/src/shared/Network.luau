--[[
	Network.luau
	Defines all RemoteEvent name constants used for client-server communication.
	The server creates these RemoteEvents at runtime inside ReplicatedStorage.Remotes.
]]

local Network = {}

--- Path where the server creates RemoteEvent instances at runtime.
Network.REMOTES_FOLDER = "ReplicatedStorage.Remotes"

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

--- Player requests to sell a brewed potion for gold.
Network.SellPotion = "SellPotion"

--- Player requests to upgrade their lab to the next level.
Network.UpgradeLab = "UpgradeLab"

--- Player requests to upgrade their cauldron to the next level.
Network.UpgradeCauldron = "UpgradeCauldron"

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
		-- Server -> Client
		Network.StateSync,
		Network.Notification,
		Network.RecipeDiscovered,
	}
end

return Network
