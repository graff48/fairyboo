local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateHUDRemote = remotes:WaitForChild("UpdateHUD")
local roundInfoRemote = remotes:WaitForChild("RoundInfo")

-- Create HUD ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Top bar (timer + round info)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0.3, 0, 0, 40)
topBar.Position = UDim2.new(0.35, 0, 0, 10)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0.5, 0, 1, 0)
timerLabel.Position = UDim2.new(0, 0, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "5:00"
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = topBar

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundLabel"
roundLabel.Size = UDim2.new(0.5, 0, 1, 0)
roundLabel.Position = UDim2.new(0.5, 0, 0, 0)
roundLabel.BackgroundTransparency = 1
roundLabel.Text = "Round 0"
roundLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
roundLabel.TextScaled = true
roundLabel.Font = Enum.Font.GothamBold
roundLabel.Parent = topBar

-- Score display
local scoreFrame = Instance.new("Frame")
scoreFrame.Name = "ScoreFrame"
scoreFrame.Size = UDim2.new(0, 200, 0, 50)
scoreFrame.Position = UDim2.new(1, -210, 0, 10)
scoreFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
scoreFrame.BackgroundTransparency = 0.3
scoreFrame.BorderSizePixel = 0
scoreFrame.Parent = screenGui

local scoreCorner = Instance.new("UICorner")
scoreCorner.CornerRadius = UDim.new(0, 8)
scoreCorner.Parent = scoreFrame

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(1, -10, 1, 0)
scoreLabel.Position = UDim2.new(0, 5, 0, 0)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = "Score: 0"
scoreLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
scoreLabel.TextScaled = true
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
scoreLabel.Parent = scoreFrame

-- Ability feedback (center-bottom)
local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name = "FeedbackLabel"
feedbackLabel.Size = UDim2.new(0.5, 0, 0, 40)
feedbackLabel.Position = UDim2.new(0.25, 0, 0.8, 0)
feedbackLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
feedbackLabel.BackgroundTransparency = 0.5
feedbackLabel.BorderSizePixel = 0
feedbackLabel.Text = ""
feedbackLabel.TextColor3 = Color3.new(1, 1, 1)
feedbackLabel.TextScaled = true
feedbackLabel.Font = Enum.Font.GothamMedium
feedbackLabel.Visible = false
feedbackLabel.Parent = screenGui

local feedbackCorner = Instance.new("UICorner")
feedbackCorner.CornerRadius = UDim.new(0, 8)
feedbackCorner.Parent = feedbackLabel

-- Status message (center, big text for round start/end)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0.6, 0, 0.15, 0)
statusLabel.Position = UDim2.new(0.2, 0, 0.35, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextStrokeTransparency = 0.5
statusLabel.Visible = false
statusLabel.Parent = screenGui

-- Round end scoreboard
local scoreboardFrame = Instance.new("Frame")
scoreboardFrame.Name = "Scoreboard"
scoreboardFrame.Size = UDim2.new(0.5, 0, 0.6, 0)
scoreboardFrame.Position = UDim2.new(0.25, 0, 0.2, 0)
scoreboardFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
scoreboardFrame.BackgroundTransparency = 0.1
scoreboardFrame.BorderSizePixel = 0
scoreboardFrame.Visible = false
scoreboardFrame.Parent = screenGui

local scoreboardCorner = Instance.new("UICorner")
scoreboardCorner.CornerRadius = UDim.new(0, 12)
scoreboardCorner.Parent = scoreboardFrame

local scoreboardTitle = Instance.new("TextLabel")
scoreboardTitle.Name = "Title"
scoreboardTitle.Size = UDim2.new(1, 0, 0, 40)
scoreboardTitle.Position = UDim2.new(0, 0, 0, 5)
scoreboardTitle.BackgroundTransparency = 1
scoreboardTitle.Text = "Round Results"
scoreboardTitle.TextColor3 = Color3.fromRGB(255, 215, 100)
scoreboardTitle.TextScaled = true
scoreboardTitle.Font = Enum.Font.GothamBold
scoreboardTitle.Parent = scoreboardFrame

local scoreboardList = Instance.new("Frame")
scoreboardList.Name = "List"
scoreboardList.Size = UDim2.new(0.9, 0, 0.8, 0)
scoreboardList.Position = UDim2.new(0.05, 0, 0.15, 0)
scoreboardList.BackgroundTransparency = 1
scoreboardList.Parent = scoreboardFrame

local scoreboardLayout = Instance.new("UIListLayout")
scoreboardLayout.Padding = UDim.new(0, 4)
scoreboardLayout.Parent = scoreboardList

-- Feedback display coroutine
local feedbackQueue = {}
local feedbackActive = false

local function showFeedback(message)
	feedbackLabel.Text = message
	feedbackLabel.Visible = true

	delay(2.5, function()
		if feedbackLabel.Text == message then
			feedbackLabel.Visible = false
		end
	end)
end

local function showStatus(message, duration)
	statusLabel.Text = message
	statusLabel.Visible = true

	delay(duration or 3, function()
		if statusLabel.Text == message then
			statusLabel.Visible = false
		end
	end)
end

local function showScoreboard(scores)
	-- Clear old entries
	for _, child in ipairs(scoreboardList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	for i, data in ipairs(scores) do
		local entry = Instance.new("TextLabel")
		entry.Name = "Entry_" .. i
		entry.Size = UDim2.new(1, 0, 0, 30)
		entry.BackgroundTransparency = 0.7
		entry.BackgroundColor3 = i == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(60, 60, 80)
		entry.Text = string.format("#%d  %s (%s) - %d pts", i, data.Name, data.Character, data.Score)
		entry.TextColor3 = Color3.new(1, 1, 1)
		entry.TextScaled = true
		entry.Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
		entry.Parent = scoreboardList

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 4)
		entryCorner.Parent = entry
	end

	scoreboardFrame.Visible = true

	delay(8, function()
		scoreboardFrame.Visible = false
	end)
end

-- Event handlers
updateHUDRemote.OnClientEvent:Connect(function(eventType, data)
	if eventType == "ScoreUpdate" then
		scoreLabel.Text = "Score: " .. tostring(data.Score)
		if data.Delta > 0 then
			showFeedback("+" .. data.Delta)
		end
	elseif eventType == "AbilityFeedback" then
		showFeedback(data.Message)
	elseif eventType == "SelectionFailed" then
		showFeedback("Cannot select " .. (data.Character or "character") .. " - slots full!")
	end
end)

roundInfoRemote.OnClientEvent:Connect(function(eventType, data)
	if eventType == "RoundStart" then
		roundLabel.Text = "Round " .. data.Round
		timerLabel.Text = Utils.FormatTime(data.Duration)
		scoreLabel.Text = "Score: 0"
		scoreboardFrame.Visible = false
		showStatus("Round " .. data.Round .. " Start!", 3)
	elseif eventType == "RoundEnd" then
		showStatus("Round Over!", 3)
		if data.Scores then
			showScoreboard(data.Scores)
		end
	elseif eventType == "TimeUpdate" then
		timerLabel.Text = Utils.FormatTime(data.TimeLeft)
		if data.TimeLeft <= 10 then
			timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		else
			timerLabel.TextColor3 = Color3.new(1, 1, 1)
		end
	elseif eventType == "Intermission" then
		showStatus("Intermission - Choose your character!", data.Duration)
	elseif eventType == "WaitingForPlayers" then
		showStatus("Waiting for players... (" .. data.Current .. "/" .. data.Required .. ")", 2)
	end
end)
