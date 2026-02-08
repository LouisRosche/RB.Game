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
		-- Server -> Client
		Network.StateSync,
		Network.Notification,
	}
end

return Network
