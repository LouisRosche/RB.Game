--[[
	PublishPracticeObby — Client
	Displays a "Checkpoint X / N" HUD label.
	Change TOTAL_CHECKPOINTS to match however many checkpoint parts you built.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TOTAL_CHECKPOINTS = 10 -- change to match your obby

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Build HUD
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ObbyHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 54)
frame.Position = UDim2.new(0.5, -110, 0, 16)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.35
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "Checkpoint: 0 / " .. TOTAL_CHECKPOINTS
label.Parent = frame

-- Listen for checkpoint events from the server
local CheckpointReached = ReplicatedStorage:WaitForChild("CheckpointReached") :: RemoteEvent

CheckpointReached.OnClientEvent:Connect(function(num: number)
	if num >= TOTAL_CHECKPOINTS then
		label.Text = "Course Complete! \u{1F389}"
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
	else
		label.Text = "Checkpoint: " .. num .. " / " .. TOTAL_CHECKPOINTS
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)
