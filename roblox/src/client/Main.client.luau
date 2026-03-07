--[[
	Main.client.luau
	Single client entry point for Alchemy Academy (Single-Script Architecture).
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
local Controllers           = script.Parent:WaitForChild("Controllers")
local UIController          = require(Controllers:WaitForChild("UIController"))
local InteractionController = require(Controllers:WaitForChild("InteractionController"))
local SoundController       = require(Controllers:WaitForChild("SoundController"))
local TutorialController    = require(Controllers:WaitForChild("TutorialController"))
local LightingController    = require(Controllers:WaitForChild("LightingController"))
local ParticleController    = require(Controllers:WaitForChild("ParticleController"))

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
	TutorialController.onStateChanged(newState)
end)

---------------------------------------------------------------------------
-- Notification handler — server pushes one-off messages
---------------------------------------------------------------------------
notificationRemote.OnClientEvent:Connect(function(message: string, color: Color3?)
	UIController.showNotification(message, color)
	SoundController.onNotification()
end)

---------------------------------------------------------------------------
-- Recipe discovery handler — server notifies of a first-time brew
---------------------------------------------------------------------------
local recipeDiscoveredRemote = Remotes:WaitForChild(Network.RecipeDiscovered) :: RemoteEvent
recipeDiscoveredRemote.OnClientEvent:Connect(function(recipeId: string, recipeName: string, isSessionFirst: boolean)
	UIController.onRecipeDiscovered(recipeId, recipeName, isSessionFirst)
	SoundController.onDiscovery()
	ParticleController.onDiscovery()
end)

---------------------------------------------------------------------------
-- Harvest particle effect — server sends plot + rarity for burst
---------------------------------------------------------------------------
local harvestEffectRemote = Remotes:WaitForChild(Network.HarvestEffect) :: RemoteEvent
harvestEffectRemote.OnClientEvent:Connect(function(plotIndex: number, rarity: string)
	ParticleController.onHarvest(plotIndex, rarity)
end)

---------------------------------------------------------------------------
-- Brew complete particle effect
---------------------------------------------------------------------------
local brewEffectRemote = Remotes:WaitForChild(Network.BrewEffect) :: RemoteEvent
brewEffectRemote.OnClientEvent:Connect(function()
	ParticleController.onBrewComplete()
end)

---------------------------------------------------------------------------
-- Leaderboard handler — server pushes top-N rankings periodically
---------------------------------------------------------------------------
local leaderboardRemote = Remotes:WaitForChild(Network.LeaderboardUpdate) :: RemoteEvent
leaderboardRemote.OnClientEvent:Connect(function(entries: { { rank: number, name: string, score: number } })
	UIController.updateLeaderboard(entries)
end)

---------------------------------------------------------------------------
-- Initialise controllers
---------------------------------------------------------------------------
-- UIController needs the state accessor, Remotes, and SoundController
-- so button callbacks can play the correct SFX on action confirmation.
UIController.init(playerState, Remotes, SoundController)

-- InteractionController needs UIController (to open panels), the state
-- accessor (to check plot states), and SoundController for audio feedback.
InteractionController.init(UIController, getState, Remotes, SoundController)

-- SoundController starts background music and prepares the SFX pool.
SoundController.init()

-- TutorialController detects new players and shows the onboarding overlay.
-- Must be initialised after UIController (which creates PlayerGui.AlchemyAcademyUI).
TutorialController.init(Remotes)

-- LightingController applies Sprint 3 visual polish (bloom, atmosphere, colour grade).
LightingController.init()

-- ParticleController starts the cauldron idle bubbles and prepares burst helpers.
-- Must be called after the lab model exists in the workspace (it waits internally).
ParticleController.init()

-- Wire performance-mode controllers into the settings panel so the player can
-- disable visual effects on low-end devices.
UIController.setPerformanceControllers(LightingController, ParticleController)

---------------------------------------------------------------------------
-- Game Pass purchase detection
-- When a PromptGamePassPurchase dialog is dismissed, ask the server to
-- re-verify pass ownership. Server calls UserOwnsGamePassAsync (never trust
-- the client alone) and updates OwnedPasses in the profile.
---------------------------------------------------------------------------
local MarketplaceService = game:GetService("MarketplaceService")
local verifyPassRemote = Remotes:WaitForChild(Network.VerifyGamePass) :: RemoteEvent

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(
	_player: Player,
	passId: number,
	_purchased: boolean
)
	-- Fire regardless of whether purchased = true so the server can sync
	-- the definitive ownership state back to this client.
	verifyPassRemote:FireServer(passId)
end)

print("[AlchemyAcademy] Client initialised — welcome to the lab!")
