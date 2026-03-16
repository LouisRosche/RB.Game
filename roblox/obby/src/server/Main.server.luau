--[[
	Obby Server — Main.server.luau
	Single server script (Single-Script Architecture).

	Systems:
	  1. Checkpoint save/load (DataStoreService)
	  2. Coin collection (server-authoritative)
	  3. Skip-stage Developer Product (50 R$)
	  4. VIP Game Pass (200 R$ — speed boost, double coins, chat tag)
	  5. Fastest-completion leaderboard
	  6. Cross-promotion prompt after world 1

	Workspace requirements (build in Studio):
	  - Folder "Checkpoints" with Parts. Each Part needs attribute CheckpointNumber (int).
	  - Folder "Coins" with Parts. Each Part needs attribute CoinValue (int, default 1).
	    The server tracks which coins each player collected so duplicates are impossible.
]]

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local DataStoreService     = game:GetService("DataStoreService")
local MarketplaceService   = game:GetService("MarketplaceService")
local TeleportService      = game:GetService("TeleportService")
local ChatService          = game:GetService("Chat") -- legacy; tag via TextChatService below
local RunService           = game:GetService("RunService")
local TextChatService      = game:GetService("TextChatService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

--------------------------------------------------------------------------------
-- DataStores
--------------------------------------------------------------------------------
local checkpointStore = DataStoreService:GetDataStore("ObbyCheckpoints_v1")
local coinsStore      = DataStoreService:GetDataStore("ObbyCoins_v1")
local bestTimeStore   = DataStoreService:GetDataStore("ObbyBestTimes_v1")

--------------------------------------------------------------------------------
-- Remotes — created once by the server
--------------------------------------------------------------------------------
local remotes: { [string]: RemoteEvent } = {}
for key, name in Config.REMOTES do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	remotes[key] = remote
end

--------------------------------------------------------------------------------
-- Per-player state
--------------------------------------------------------------------------------
type PlayerState = {
	checkpoint: number,
	coins: number,
	bestTime: number,         -- 0 = not yet completed
	startTick: number,        -- os.clock() when they first move from checkpoint 1
	timerRunning: boolean,
	deaths: number,
	collectedCoins: { [string]: boolean },  -- coin instance names already picked up
	isVIP: boolean,
}

local playerStates: { [Player]: PlayerState } = {}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function key(player: Player): string
	return tostring(player.UserId)
end

local function safeGetAsync(store, k: string): any
	local ok, result = pcall(store.GetAsync, store, k)
	if ok then
		return result
	end
	warn("DataStore GetAsync failed for", k, result)
	return nil
end

local function safeSetAsync(store, k: string, v: any)
	local ok, err = pcall(store.SetAsync, store, k, v)
	if not ok then
		warn("DataStore SetAsync failed for", k, err)
	end
end

local function getCheckpointPart(num: number): BasePart?
	local folder = workspace:FindFirstChild("Checkpoints")
	if not folder then return nil end
	for _, part in folder:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute("CheckpointNumber") == num then
			return part
		end
	end
	return nil
end

local function hasVIPPass(player: Player): boolean
	if Config.VIP_GAME_PASS_ID == 0 then return false end
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, Config.VIP_GAME_PASS_ID)
	return ok and owns
end

--------------------------------------------------------------------------------
-- VIP chat tag (TextChatService)
--------------------------------------------------------------------------------
local function applyVIPChatTag(player: Player)
	-- Works with the new TextChatService system
	pcall(function()
		local textChat = TextChatService:FindFirstChild("TextChannels")
		if not textChat then return end
		-- Tags are applied via TextChatCommand or via attributes on the player
		-- Simplest cross-compatible approach: set an attribute the client reads
		player:SetAttribute("VIPChatTag", true)
	end)
end

--------------------------------------------------------------------------------
-- VIP speed boost
--------------------------------------------------------------------------------
local function applyVIPSpeedBoost(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 + Config.VIP_SPEED_BOOST
	end
end

--------------------------------------------------------------------------------
-- Leaderboard (in-memory + ordered DataStore)
--------------------------------------------------------------------------------
local leaderboardStore = DataStoreService:GetOrderedDataStore("ObbyFastestTimes_v1")

local function updateLeaderboard(player: Player, timeSeconds: number)
	-- OrderedDataStore only supports integers; store centiseconds
	local centis = math.floor(timeSeconds * 100)
	pcall(leaderboardStore.SetAsync, leaderboardStore, key(player), centis)
end

local function getLeaderboardEntries(): { { name: string, time: number } }
	local entries = {}
	local ok, pages = pcall(leaderboardStore.GetSortedAsync, leaderboardStore, true, Config.LEADERBOARD_MAX_ENTRIES)
	if not ok or not pages then return entries end
	local page = pages:GetCurrentPage()
	for _, entry in page do
		table.insert(entries, {
			name = "Player_" .. entry.key,  -- resolve display name below
			userId = tonumber(entry.key) or 0,
			time = entry.value / 100,
		})
	end
	-- Resolve display names
	for _, e in entries do
		if e.userId > 0 then
			local nameOk, displayName = pcall(Players.GetNameFromUserIdAsync, Players, e.userId)
			if nameOk and displayName then
				e.name = displayName
			end
		end
	end
	return entries
end

--------------------------------------------------------------------------------
-- Coin collection (server-authoritative)
--------------------------------------------------------------------------------
local function setupCoins()
	local folder = workspace:FindFirstChild("Coins")
	if not folder then
		-- Create an empty folder so the game still runs without coins placed yet
		local f = Instance.new("Folder")
		f.Name = "Coins"
		f.Parent = workspace
		return
	end

	for _, coin in folder:GetChildren() do
		if coin:IsA("BasePart") then
			coin.Touched:Connect(function(hit: BasePart)
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end

				local state = playerStates[player]
				if not state then return end

				local coinId = coin.Name .. "_" .. tostring(coin:GetAttribute("CoinValue") or 1)
				-- Prevent double-collect
				if state.collectedCoins[coin.Name] then return end
				state.collectedCoins[coin.Name] = true

				local value = (coin:GetAttribute("CoinValue") or Config.COIN_BASE_VALUE) :: number
				if state.isVIP then
					value = value * Config.VIP_COIN_MULTIPLIER
				end
				state.coins += value

				-- Hide the coin for this player only (server can't do per-player visibility
				-- without streaming tricks, so we just fire the client to hide it)
				remotes.CoinCollected:FireClient(player, coin.Name, state.coins)
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- Checkpoint system
--------------------------------------------------------------------------------
local function onCheckpointTouched(part: BasePart, player: Player)
	local num = part:GetAttribute("CheckpointNumber") :: number?
	if not num then return end

	local state = playerStates[player]
	if not state then return end

	-- Start timer on first non-spawn checkpoint
	if num >= 2 and not state.timerRunning then
		state.startTick = os.clock()
		state.timerRunning = true
	end

	if num <= state.checkpoint then return end

	state.checkpoint = num

	-- Save to DataStore (fire-and-forget)
	task.spawn(safeSetAsync, checkpointStore, key(player), num)

	remotes.CheckpointReached:FireClient(player, num, Config.TOTAL_STAGES)

	-- Completion
	if num >= Config.FINISH_CHECKPOINT then
		state.timerRunning = false
		local elapsed = os.clock() - state.startTick
		if state.bestTime == 0 or elapsed < state.bestTime then
			state.bestTime = elapsed
			task.spawn(safeSetAsync, bestTimeStore, key(player), elapsed)
			task.spawn(updateLeaderboard, player, elapsed)
		end

		-- Sync final stats
		remotes.StatsSync:FireClient(player, {
			checkpoint = state.checkpoint,
			coins = state.coins,
			bestTime = state.bestTime,
			deaths = state.deaths,
			completed = true,
			elapsed = elapsed,
		})

		-- Cross-promotion prompt
		task.delay(3, function()
			if player.Parent then -- still connected
				remotes.CrossPromo:FireClient(player)
			end
		end)
	end
end

local function wireCheckpoints()
	local folder = workspace:WaitForChild("Checkpoints", 30)
	if not folder then
		warn("Obby: 'Checkpoints' folder not found in Workspace — create it in Studio.")
		return
	end
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") then
			child.Touched:Connect(function(hit: BasePart)
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if player then
					onCheckpointTouched(child, player)
				end
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- Respawn at saved checkpoint
--------------------------------------------------------------------------------
local function respawnAtCheckpoint(character: Model, player: Player)
	local state = playerStates[player]
	if not state or state.checkpoint <= 1 then return end

	local part = getCheckpointPart(state.checkpoint)
	if not part then return end

	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if hrp then
		task.wait(0.1)
		hrp.CFrame = part.CFrame + Vector3.new(0, Config.RESPAWN_Y_OFFSET, 0)
	end
end

--------------------------------------------------------------------------------
-- Death tracking
--------------------------------------------------------------------------------
local function onCharacterAdded(character: Model, player: Player)
	respawnAtCheckpoint(character, player)

	-- VIP speed boost
	local state = playerStates[player]
	if state and state.isVIP then
		applyVIPSpeedBoost(character)
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			if state then
				state.deaths += 1
				remotes.PlayerDied:FireClient(player, state.deaths)
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- Skip-stage Developer Product
--------------------------------------------------------------------------------
local function processSkipStage(player: Player): boolean
	local state = playerStates[player]
	if not state then return false end

	local nextStage = state.checkpoint + 1
	if nextStage > Config.TOTAL_STAGES then return false end -- already at end

	state.checkpoint = nextStage
	task.spawn(safeSetAsync, checkpointStore, key(player), nextStage)

	-- Teleport player to the new checkpoint
	local character = player.Character
	if character then
		local part = getCheckpointPart(nextStage)
		if part then
			local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				hrp.CFrame = part.CFrame + Vector3.new(0, Config.RESPAWN_Y_OFFSET, 0)
			end
		end
	end

	remotes.CheckpointReached:FireClient(player, nextStage, Config.TOTAL_STAGES)
	remotes.PurchaseResult:FireClient(player, "skip", true, nextStage)
	return true
end

-- MarketplaceService callbacks
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == Config.SKIP_STAGE_PRODUCT_ID then
		local success = processSkipStage(player)
		if success then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Client-requested skip (opens the purchase prompt)
remotes.RequestSkip.OnServerEvent:Connect(function(player: Player)
	if Config.SKIP_STAGE_PRODUCT_ID == 0 then
		warn("Skip-stage product ID not configured")
		return
	end
	MarketplaceService:PromptProductPurchase(player, Config.SKIP_STAGE_PRODUCT_ID)
end)

-- VIP game pass purchase callback
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if gamePassId == Config.VIP_GAME_PASS_ID and purchased then
		local state = playerStates[player]
		if state then
			state.isVIP = true
			if player.Character then
				applyVIPSpeedBoost(player.Character)
			end
			applyVIPChatTag(player)
			remotes.PurchaseResult:FireClient(player, "vip", true)
		end
	end
end)

--------------------------------------------------------------------------------
-- Player lifecycle
--------------------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	-- Load saved data
	local savedCheckpoint = safeGetAsync(checkpointStore, key(player)) or 0
	local savedCoins      = safeGetAsync(coinsStore, key(player)) or 0
	local savedBestTime   = safeGetAsync(bestTimeStore, key(player)) or 0
	local vip             = hasVIPPass(player)

	playerStates[player] = {
		checkpoint     = savedCheckpoint,
		coins          = savedCoins,
		bestTime       = savedBestTime,
		startTick      = os.clock(),
		timerRunning   = false,
		deaths         = 0,
		collectedCoins = {},
		isVIP          = vip,
	}

	if vip then
		applyVIPChatTag(player)
	end

	-- Send initial state to client
	task.defer(function()
		if player.Parent then
			remotes.StatsSync:FireClient(player, {
				checkpoint = savedCheckpoint,
				coins = savedCoins,
				bestTime = savedBestTime,
				deaths = 0,
				completed = false,
				isVIP = vip,
			})
		end
	end)

	-- leaderstats (visible in player list)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stageStat = Instance.new("IntValue")
	stageStat.Name = "Stage"
	stageStat.Value = savedCheckpoint
	stageStat.Parent = leaderstats

	local coinStat = Instance.new("IntValue")
	coinStat.Name = "Coins"
	coinStat.Value = savedCoins
	coinStat.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)

	-- If character already loaded
	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

local function onPlayerRemoving(player: Player)
	local state = playerStates[player]
	if state then
		-- Save all data
		task.spawn(safeSetAsync, checkpointStore, key(player), state.checkpoint)
		task.spawn(safeSetAsync, coinsStore, key(player), state.coins)
		if state.bestTime > 0 then
			task.spawn(safeSetAsync, bestTimeStore, key(player), state.bestTime)
		end
	end
	playerStates[player] = nil
end

-- Keep leaderstats in sync
RunService.Heartbeat:Connect(function()
	for player, state in playerStates do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local stageStat = leaderstats:FindFirstChild("Stage")
			if stageStat then stageStat.Value = state.checkpoint end
			local coinStat = leaderstats:FindFirstChild("Coins")
			if coinStat then coinStat.Value = state.coins end
		end
	end
end)

--------------------------------------------------------------------------------
-- Cross-promotion teleport (called by client via remote)
--------------------------------------------------------------------------------
-- We reuse CrossPromo remote: client fires it back to request teleport
remotes.CrossPromo.OnServerEvent:Connect(function(player: Player)
	if Config.ALCHEMY_ACADEMY_PLACE_ID == 0 then
		warn("Cross-promo place ID not configured")
		return
	end
	pcall(TeleportService.Teleport, TeleportService, Config.ALCHEMY_ACADEMY_PLACE_ID, player)
end)

--------------------------------------------------------------------------------
-- Boot
--------------------------------------------------------------------------------
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

wireCheckpoints()
setupCoins()

print("[Obby Server] Initialized — stages:", Config.TOTAL_STAGES)
