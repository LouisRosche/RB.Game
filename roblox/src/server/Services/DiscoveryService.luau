--[[
	DiscoveryService.luau
	Tracks recipe discoveries within a server session and broadcasts
	first-discovery announcements to all players.

	Educational design intent:
	  - Discovery is celebrated openly, not hoarded
	  - First discovery within the current server is announced server-wide
	  - Players who already know a recipe get a quieter "You already know this!"
	  - No competitive pressure: all players can discover every recipe
	  - Persistent across sessions via DataService.DiscoveredRecipes

	Anti-dark-pattern:
	  - No "exclusive" discoveries that block other players
	  - No time-limited discovery bonuses that create FOMO
	  - Celebration is joyful but not excessive or disruptive
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared.Network)
local Recipes = require(Shared.Recipes)

local DataService = require(script.Parent.DataService)

local DiscoveryService = {}

---------------------------------------------------------------------------
-- Session-level first-discovery tracking (reset on server restart)
-- Stores recipeId -> playerName of who discovered it first this session
---------------------------------------------------------------------------
local sessionFirstDiscoveries: { [string]: string } = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Returns the Remotes folder, or nil if not ready yet.
local function getRemotes(): Folder?
	return ReplicatedStorage:FindFirstChild("Remotes")
end

--- Broadcasts a message to all connected players.
local function broadcastToAll(message: string, highlightColor: Color3?)
	local remotes = getRemotes()
	if not remotes then return end
	local notifRemote = remotes:FindFirstChild(Network.Notification)
	if not notifRemote then return end

	for _, player in Players:GetPlayers() do
		notifRemote:FireClient(player, message, highlightColor)
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Called by BrewingService after a successful brew.
--- Handles first-discovery logic and persistence.
--- Returns true if this was the player's personal first discovery.
function DiscoveryService.onRecipeBrewed(player: Player, recipeId: string): boolean
	local data = DataService.getData(player)
	if not data then return false end

	-- Ensure the DiscoveredRecipes set exists (schema migration safety)
	if not data.DiscoveredRecipes then
		data.DiscoveredRecipes = {}
	end

	local alreadyKnown = data.DiscoveredRecipes[recipeId] == true
	if alreadyKnown then
		return false -- not a new personal discovery
	end

	-- Mark as discovered in persistent data
	data.DiscoveredRecipes[recipeId] = true

	-- Get recipe info for announcement (O(1) via Recipes.BY_ID)
	local recipe = Recipes.BY_ID[recipeId]
	local recipeName = recipe and recipe.displayName or recipeId

	-- Check if this is the server-session first discovery
	local isSessionFirst = sessionFirstDiscoveries[recipeId] == nil
	if isSessionFirst then
		sessionFirstDiscoveries[recipeId] = player.DisplayName

		-- Announce to the whole server with joy!
		broadcastToAll(
			player.DisplayName .. " just discovered " .. recipeName .. " for the first time this session! Amazing!",
			Color3.fromRGB(255, 220, 80)
		)
	else
		-- Personal first discovery, but not server-first: notify only this player
		local firstDiscoverer = sessionFirstDiscoveries[recipeId]
		DataService.notify(
			player,
			"New recipe discovered: " .. recipeName .. "! (First found this session by " .. firstDiscoverer .. ")"
		)
	end

	-- Fire the RecipeDiscovered event to the discovering player's client
	-- so the UI can trigger a celebration effect
	local remotes = getRemotes()
	if remotes then
		local discoveryRemote = remotes:FindFirstChild(Network.RecipeDiscovered)
		if discoveryRemote then
			discoveryRemote:FireClient(player, recipeId, recipeName, isSessionFirst)
		end
	end

	return true
end

--- Returns whether a player has already discovered a given recipe.
function DiscoveryService.hasDiscovered(player: Player, recipeId: string): boolean
	local data = DataService.getData(player)
	if not data or not data.DiscoveredRecipes then return false end
	return data.DiscoveredRecipes[recipeId] == true
end

--- Returns the count of recipes a player has discovered.
function DiscoveryService.getDiscoveryCount(player: Player): number
	local data = DataService.getData(player)
	if not data or not data.DiscoveredRecipes then return 0 end
	local count = 0
	for _ in data.DiscoveredRecipes do
		count += 1
	end
	return count
end

-- Cache the total recipe count (constant after module load)
local cachedTotalRecipes: number = 0
for _ in Recipes.Map do
	cachedTotalRecipes += 1
end

--- Returns the total number of discoverable recipes.
function DiscoveryService.getTotalRecipeCount(): number
	return cachedTotalRecipes
end

return DiscoveryService
