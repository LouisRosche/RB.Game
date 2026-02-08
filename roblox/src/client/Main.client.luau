--[[
	Main.client.luau
	Single client entry point for Potion Lab (Single-Script Architecture).
	Waits for all required services, wires up RemoteEvents, initialises
	controllers, and keeps a local cache of the authoritative player state.
]]

---------------------------------------------------------------------------
-- Roblox services
---------------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------------
-- Wait for the game to be ready
---------------------------------------------------------------------------
local localPlayer = Players.LocalPlayer
localPlayer:WaitForChild("PlayerGui")

---------------------------------------------------------------------------
-- Wait for replicated folders
---------------------------------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shared  = ReplicatedStorage:WaitForChild("Shared")

---------------------------------------------------------------------------
-- Shared modules
---------------------------------------------------------------------------
local Network     = require(Shared:WaitForChild("Network"))
local Config      = require(Shared:WaitForChild("Config"))
local Ingredients = require(Shared:WaitForChild("Ingredients"))
local Recipes     = require(Shared:WaitForChild("Recipes"))
local Strings     = require(Shared:WaitForChild("Strings"))

---------------------------------------------------------------------------
-- Client controllers
---------------------------------------------------------------------------
local Controllers          = script.Parent:WaitForChild("Controllers")
local UIController         = require(Controllers:WaitForChild("UIController"))
local InteractionController = require(Controllers:WaitForChild("InteractionController"))

---------------------------------------------------------------------------
-- Local state cache — updated every time the server sends a StateSync
---------------------------------------------------------------------------
local playerState: { [string]: any } = {}

--- Returns the current cached player state. Controllers can read this to
--- make decisions without needing their own copy.
local function getState(): { [string]: any }
	return playerState
end

---------------------------------------------------------------------------
-- Remote event references
---------------------------------------------------------------------------
local stateSyncRemote   = Remotes:WaitForChild(Network.StateSync) :: RemoteEvent
local notificationRemote = Remotes:WaitForChild(Network.Notification) :: RemoteEvent

---------------------------------------------------------------------------
-- StateSync handler — server pushes full state to the client
---------------------------------------------------------------------------
stateSyncRemote.OnClientEvent:Connect(function(newState: { [string]: any })
	playerState = newState
	UIController.updateState(newState)
end)

---------------------------------------------------------------------------
-- Notification handler — server pushes one-off messages
---------------------------------------------------------------------------
notificationRemote.OnClientEvent:Connect(function(message: string, color: Color3?)
	UIController.showNotification(message, color)
end)

---------------------------------------------------------------------------
-- Initialise controllers
---------------------------------------------------------------------------
-- UIController needs the state accessor and the Remotes folder so it can
-- fire client-to-server events from button callbacks.
UIController.init(playerState, Remotes)

-- InteractionController needs UIController (to open panels) and the state
-- accessor (to check plot states).
InteractionController.init(UIController, getState, Remotes)

print("[PotionLab] Client initialised")
