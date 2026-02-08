--[[
	InteractionController.luau
	Handles player interaction with 3D world objects via ProximityPromptService.
	Routes prompt activations to the appropriate UIController panel or
	fires RemoteEvents directly (e.g. harvesting a ready plot).

	Expected world layout (created by the server):
	  - Each garden plot has a ProximityPrompt with an IntValue attribute
	    "PlotIndex" on its parent, or the prompt is named "Plot_<index>".
	  - The cauldron model has a ProximityPrompt named "CauldronPrompt".
	  - The sell station has a ProximityPrompt named "SellPrompt".
	  - The upgrade/shop station has a ProximityPrompt named "ShopPrompt".
]]

---------------------------------------------------------------------------
-- Services
---------------------------------------------------------------------------
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage      = game:GetService("ReplicatedStorage")
local Players                = game:GetService("Players")

---------------------------------------------------------------------------
-- Shared modules
---------------------------------------------------------------------------
local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

---------------------------------------------------------------------------
-- Module
---------------------------------------------------------------------------
local InteractionController = {}

-- References set during init
local uiController: any = nil
local getStateFn: (() -> { [string]: any }) = nil :: any
local remotes: Folder = nil :: any
local localPlayer: Player = Players.LocalPlayer

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Attempts to extract a plot index from a ProximityPrompt or its parent.
--- Returns the 1-based plot index, or nil if this is not a plot prompt.
local function getPlotIndex(prompt: ProximityPrompt): number?
	local parent = prompt.Parent

	-- Method 1: IntValue attribute on the prompt's parent part
	if parent then
		local attr = parent:GetAttribute("PlotIndex")
		if typeof(attr) == "number" then
			return math.floor(attr)
		end
	end

	-- Method 2: Prompt or parent named "Plot_<index>"
	local nameToCheck = prompt.Name
	local match = string.match(nameToCheck, "Plot_(%d+)")
	if match then
		return tonumber(match)
	end
	if parent then
		match = string.match(parent.Name, "Plot_(%d+)")
		if match then
			return tonumber(match)
		end
	end

	return nil
end

--- Returns the current state of a given plot from the cached player state.
local function getPlotState(plotIndex: number): { State: string, IngredientId: string?, PlantedAt: number?, GrowthDuration: number?, Rarity: string? }?
	local state = getStateFn()
	if not state or not state.Plots then return nil end
	return state.Plots[plotIndex]
end

--- Fires a RemoteEvent to the server by name.
local function fireRemote(eventName: string, ...: any)
	local remote = remotes:FindFirstChild(eventName)
	if remote then
		(remote :: RemoteEvent):FireServer(...)
	end
end

---------------------------------------------------------------------------
-- Prompt handler
---------------------------------------------------------------------------

local function onPromptTriggered(prompt: ProximityPrompt, triggeringPlayer: Player)
	-- Only handle prompts triggered by the local player
	if triggeringPlayer ~= localPlayer then return end

	local promptName = prompt.Name
	local parentName = prompt.Parent and prompt.Parent.Name or ""

	-- Plot interaction
	local plotIndex = getPlotIndex(prompt)
	if plotIndex then
		local plotState = getPlotState(plotIndex)
		if not plotState or plotState.State == "Empty" then
			-- Empty plot -> open the seed selection panel
			uiController.openSeedPanel(plotIndex)
		elseif plotState.State == "Ready" then
			-- Fully grown -> harvest immediately
			fireRemote(Network.Harvest, plotIndex)
		end
		-- "Growing" state -> do nothing (plant is still growing)
		return
	end

	-- Cauldron interaction
	if promptName == "CauldronPrompt" or parentName == "Cauldron" then
		uiController.openBrewPanel()
		return
	end

	-- Sell station interaction
	if promptName == "SellPrompt" or parentName == "SellStation" then
		uiController.openSellPanel()
		return
	end

	-- Shop / Upgrade station interaction
	if promptName == "ShopPrompt" or parentName == "Shop" or parentName == "UpgradeStation" then
		uiController.openUpgradePanel()
		return
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Initialises the InteractionController.
--- @param uiCtrl       Reference to UIController so we can open panels.
--- @param getState     Function that returns the current cached player state.
--- @param remotesFolder The Remotes folder in ReplicatedStorage.
function InteractionController.init(uiCtrl: any, getState: () -> { [string]: any }, remotesFolder: Folder)
	uiController = uiCtrl
	getStateFn = getState
	remotes = remotesFolder

	-- Listen for all ProximityPrompt triggers via the service-level event.
	-- This automatically catches prompts on any object in the workspace.
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
end

--- Returns the current state of a specific plot (convenience for other code).
function InteractionController.getPlotState(plotIndex: number)
	return getPlotState(plotIndex)
end

return InteractionController
