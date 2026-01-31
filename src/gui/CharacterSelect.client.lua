local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterData = require(Shared:WaitForChild("CharacterData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local selectCharacterRemote = remotes:WaitForChild("SelectCharacter")
local characterSlotsRemote = remotes:WaitForChild("CharacterSlots")
local showCharacterSelectRemote = remotes:WaitForChild("ShowCharacterSelect")

-- Current slot data
local currentSlots = {}

-- Create the GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CharacterSelectGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 60)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "FairyBoo - Choose Your Character"
title.TextColor3 = Color3.fromRGB(255, 215, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Character cards container
local cardsFrame = Instance.new("Frame")
cardsFrame.Name = "CardsFrame"
cardsFrame.Size = UDim2.new(0.95, 0, 0.75, 0)
cardsFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
cardsFrame.BackgroundTransparency = 1
cardsFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = cardsFrame

-- Character card buttons
local cardButtons = {}

local characterOrder = {"Wolf", "Pig", "RedRidingHood", "Goldilocks", "Jack"}

for _, charName in ipairs(characterOrder) do
	local charData = CharacterData.GetCharacter(charName)
	if not charData then continue end

	local maxSlots = GameConfig.MaxSlots[charName]

	local card = Instance.new("TextButton")
	card.Name = charName .. "Card"
	card.Size = UDim2.new(0.18, 0, 1, 0)
	card.BackgroundColor3 = charData.Color.Color
	card.BackgroundTransparency = 0.3
	card.BorderSizePixel = 0
	card.Text = ""
	card.AutoButtonColor = true
	card.Parent = cardsFrame

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Character name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0.9, 0, 0, 30)
	nameLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = charData.DisplayName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
	descLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = charData.Description
	descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.Parent = card

	-- Abilities
	local abilitiesText = ""
	for _, ability in ipairs(charData.Abilities) do
		abilitiesText = abilitiesText .. "[" .. ability.Key .. "] " .. ability.Name .. "\n"
	end
	if abilitiesText == "" then
		abilitiesText = "No special abilities"
	end

	local abilityLabel = Instance.new("TextLabel")
	abilityLabel.Name = "AbilityLabel"
	abilityLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
	abilityLabel.Position = UDim2.new(0.05, 0, 0.52, 0)
	abilityLabel.BackgroundTransparency = 1
	abilityLabel.Text = abilitiesText
	abilityLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
	abilityLabel.TextScaled = true
	abilityLabel.TextWrapped = true
	abilityLabel.Font = Enum.Font.GothamMedium
	abilityLabel.Parent = card

	-- Slots indicator
	local slotsLabel = Instance.new("TextLabel")
	slotsLabel.Name = "SlotsLabel"
	slotsLabel.Size = UDim2.new(0.9, 0, 0, 25)
	slotsLabel.Position = UDim2.new(0.05, 0, 0.82, 0)
	slotsLabel.BackgroundTransparency = 1
	slotsLabel.Text = "Slots: 0/" .. maxSlots
	slotsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	slotsLabel.TextScaled = true
	slotsLabel.Font = Enum.Font.GothamMedium
	slotsLabel.Parent = card

	-- Select button
	local selectBtn = Instance.new("TextButton")
	selectBtn.Name = "SelectButton"
	selectBtn.Size = UDim2.new(0.8, 0, 0, 30)
	selectBtn.Position = UDim2.new(0.1, 0, 0.9, -5)
	selectBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	selectBtn.Text = "Select"
	selectBtn.TextColor3 = Color3.new(1, 1, 1)
	selectBtn.TextScaled = true
	selectBtn.Font = Enum.Font.GothamBold
	selectBtn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = selectBtn

	selectBtn.MouseButton1Click:Connect(function()
		selectCharacterRemote:FireServer(charName)
		mainFrame.Visible = false
	end)

	cardButtons[charName] = {
		Card = card,
		SlotsLabel = slotsLabel,
		SelectButton = selectBtn,
		MaxSlots = maxSlots,
	}
end

-- Update slots display
local function updateSlots(slots)
	currentSlots = slots or currentSlots

	for charName, buttonData in pairs(cardButtons) do
		local used = currentSlots[charName] or 0
		local max = buttonData.MaxSlots
		buttonData.SlotsLabel.Text = "Slots: " .. used .. "/" .. max

		if used >= max then
			buttonData.SlotsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			buttonData.SelectButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			buttonData.SelectButton.Text = "Full"
		else
			buttonData.SlotsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
			buttonData.SelectButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
			buttonData.SelectButton.Text = "Select"
		end
	end
end

-- Listen for slot updates
characterSlotsRemote.OnClientEvent:Connect(function(slots)
	updateSlots(slots)
end)

-- Listen for show character select
showCharacterSelectRemote.OnClientEvent:Connect(function()
	mainFrame.Visible = true
end)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)
