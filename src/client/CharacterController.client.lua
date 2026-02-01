local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CharacterData = require(Shared:WaitForChild("CharacterData"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local abilityRemote = remotes:WaitForChild("AbilityEvent")
local showCharacterSelectRemote = remotes:WaitForChild("ShowCharacterSelect")

-- Track current character for client-side hints
local currentCharacter = nil

-- Listen for character assignment changes via leaderstats
player:WaitForChild("leaderstats"):WaitForChild("Character").Changed:Connect(function(value)
	for charName, charData in pairs(CharacterData.Characters) do
		if charData.DisplayName == value then
			currentCharacter = charName
			break
		end
	end
end)

-- Keybind: Tab to open character select
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Tab then
		-- Request character select screen
		local gui = player.PlayerGui:FindFirstChild("CharacterSelectGui")
		if gui then
			local mainFrame = gui:FindFirstChild("MainFrame")
			if mainFrame then
				mainFrame.Visible = not mainFrame.Visible
			end
		end
	end
end)

-- Client-side ability hints (visual feedback for channeling, etc.)
local isChanneling = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not currentCharacter then return end

	-- E key abilities are handled by ProximityPrompts on the server
	-- F key abilities (Pig barricade, Goldilocks hide) are also ProximityPrompt-based

	-- Mouse click (MB1) to fire flamethrower
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		abilityRemote:FireServer("UseFlamethrower")
	end

	-- Additional client-side feedback could be added here
	-- For example, showing a channel bar when holding E
end)

-- Visual indicator for Wolf speed boost
spawn(function()
	while true do
		wait(0.5)
		if currentCharacter == "Wolf" then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					-- Ensure wolf speed is maintained
					local charData = CharacterData.GetCharacter("Wolf")
					if charData and humanoid.WalkSpeed ~= charData.WalkSpeed then
						-- Speed will be set by server, this is just monitoring
					end
				end
			end
		end
	end
end)

print("[CharacterController] Initialized!")
