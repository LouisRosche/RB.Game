--[[
	PublishPracticeObby — Server
	Purpose: checkpoint respawn for a simple obstacle course.

	Workspace setup (build in Roblox Studio):
	  - Create a Folder named "Checkpoints" in Workspace
	  - Add Part children to it; name them "Checkpoint1", "Checkpoint2", etc.
	  - Set a NumberValue attribute called "CheckpointNumber" on each part
	    (1 = spawn, 2 = first real checkpoint, …, N = finish)
	  - Set Transparency = 0.5, CanCollide = false, Anchored = true on each
	  - Set BrickColor to a bright colour so players can see them
	  - Total checkpoints: change TOTAL_CHECKPOINTS in the client script to match
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent: server → client, tells the client which checkpoint was reached
local CheckpointReached = Instance.new("RemoteEvent")
CheckpointReached.Name = "CheckpointReached"
CheckpointReached.Parent = ReplicatedStorage

-- Highest checkpoint number each player has touched
local playerBest: { [Player]: number } = {}

local function onCheckpointTouched(part: BasePart, player: Player)
	local num = part:GetAttribute("CheckpointNumber") :: number?
	if not num then
		return
	end
	local best = playerBest[player] or 0
	if num > best then
		playerBest[player] = num
		CheckpointReached:FireClient(player, num)
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

local function respawnAtCheckpoint(character: Model, player: Player)
	local best = playerBest[player] or 0
	if best <= 1 then
		return -- let the default spawn handle it
	end
	local folder = workspace:FindFirstChild("Checkpoints")
	if not folder then
		return
	end
	for _, part in folder:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute("CheckpointNumber") == best then
			local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
			if hrp then
				task.wait(0.1) -- let the physics settle
				hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
			end
			return
		end
	end
end

local function onPlayerAdded(player: Player)
	playerBest[player] = 0
	player.CharacterAdded:Connect(function(character: Model)
		respawnAtCheckpoint(character, player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player: Player)
	playerBest[player] = nil
end)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

wireCheckpoints()
