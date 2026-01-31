local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CharacterData = require(Shared:WaitForChild("CharacterData"))

-- RemoteEvents
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local selectCharacterRemote = Instance.new("RemoteEvent")
selectCharacterRemote.Name = "SelectCharacter"
selectCharacterRemote.Parent = remotes

local abilityRemote = Instance.new("RemoteEvent")
abilityRemote.Name = "AbilityEvent"
abilityRemote.Parent = remotes

local updateHUDRemote = Instance.new("RemoteEvent")
updateHUDRemote.Name = "UpdateHUD"
updateHUDRemote.Parent = remotes

local roundInfoRemote = Instance.new("RemoteEvent")
roundInfoRemote.Name = "RoundInfo"
roundInfoRemote.Parent = remotes

local characterSlotsRemote = Instance.new("RemoteEvent")
characterSlotsRemote.Name = "CharacterSlots"
characterSlotsRemote.Parent = remotes

local showCharacterSelectRemote = Instance.new("RemoteEvent")
showCharacterSelectRemote.Name = "ShowCharacterSelect"
showCharacterSelectRemote.Parent = remotes

-- Game state
local gameState = {
	currentRound = 0,
	roundActive = false,
	roundTimeLeft = 0,
	playerCharacters = {}, -- [player] = characterName
	playerScores = {}, -- [player] = score
	characterSlots = {}, -- [characterName] = count of players using it
}

-- Initialize character slots
for name in pairs(CharacterData.Characters) do
	gameState.characterSlots[name] = 0
end

-- Leaderboard
local function setupLeaderboard(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local score = Instance.new("IntValue")
	score.Name = "Score"
	score.Value = 0
	score.Parent = leaderstats

	local character = Instance.new("StringValue")
	character.Name = "Character"
	character.Value = "None"
	character.Parent = leaderstats
end

local function getScore(player)
	return gameState.playerScores[player] or 0
end

local function addScore(player, amount)
	if not gameState.roundActive then return end
	gameState.playerScores[player] = getScore(player) + amount

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Score.Value = gameState.playerScores[player]
	end

	updateHUDRemote:FireClient(player, "ScoreUpdate", {
		Score = gameState.playerScores[player],
		Delta = amount,
	})
end

local function getPlayerCharacter(player)
	return gameState.playerCharacters[player]
end

local function removeCostume(player)
	local character = player.Character
	if not character then return end

	-- Remove costume-tagged accessory parts
	for _, child in ipairs(character:GetDescendants()) do
		if child:IsA("BasePart") and child:GetAttribute("Costume") then
			child:Destroy()
		end
	end

	-- Remove custom BodyColors so default can return
	local bc = character:FindFirstChildOfClass("BodyColors")
	if bc and bc:GetAttribute("Costume") then
		bc:Destroy()
	end
end

local function applyCostume(player)
	local charName = gameState.playerCharacters[player]
	if not charName then return end
	local charData = CharacterData.GetCharacter(charName)
	if not charData then return end

	local character = player.Character
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Clean any existing costume first
	removeCostume(player)

	-- Remove existing clothing so body color shows
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
			item:Destroy()
		end
	end

	-- Remove existing BodyColors and apply character color
	local existingBC = character:FindFirstChildOfClass("BodyColors")
	if existingBC then
		existingBC:Destroy()
	end

	local bodyColor = BrickColor.new(charData.BodyColor)
	local bc = Instance.new("BodyColors")
	bc:SetAttribute("Costume", true)
	bc.HeadColor = bodyColor
	bc.LeftArmColor = bodyColor
	bc.RightArmColor = bodyColor
	bc.TorsoColor = bodyColor
	bc.LeftLegColor = bodyColor
	bc.RightLegColor = bodyColor
	bc.Parent = character

	-- Build accessory parts and weld to head
	if charData.Accessories then
		for _, acc in ipairs(charData.Accessories) do
			local part = Instance.new("Part")
			part.Name = acc.Name
			part.Size = acc.Size
			part.Color = acc.Color
			part.Material = Enum.Material.SmoothPlastic
			part.CanCollide = false
			part.Massless = true
			part:SetAttribute("Costume", true)

			if acc.Shape then
				part.Shape = acc.Shape
			end

			-- Position relative to head then weld
			part.CFrame = head.CFrame * acc.Offset

			local weld = Instance.new("Weld")
			weld.Part0 = head
			weld.Part1 = part
			weld.C0 = acc.Offset
			weld.Parent = part

			part.Parent = character
		end
	end
end

local function broadcastSlots()
	characterSlotsRemote:FireAllClients(gameState.characterSlots)
end

local function assignCharacter(player, characterName)
	local charData = CharacterData.GetCharacter(characterName)
	if not charData then return false end

	local maxSlots = GameConfig.MaxSlots[characterName]
	if gameState.characterSlots[characterName] >= maxSlots then
		return false
	end

	-- Remove old character if any
	local oldChar = gameState.playerCharacters[player]
	if oldChar then
		gameState.characterSlots[oldChar] = math.max(0, gameState.characterSlots[oldChar] - 1)
	end

	gameState.playerCharacters[player] = characterName
	gameState.characterSlots[characterName] = gameState.characterSlots[characterName] + 1
	gameState.playerScores[player] = 0

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Score.Value = 0
		leaderstats.Character.Value = charData.DisplayName
	end

	-- Apply character speed
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = charData.WalkSpeed
	end

	-- Apply costume (body color + accessories)
	applyCostume(player)

	broadcastSlots()
	return true
end

-- Teleport player to character-appropriate spawn
local function teleportToSpawn(player)
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local charName = gameState.playerCharacters[player]
	local map = workspace:FindFirstChild("Map")
	if not map then return end

	local spawnPos = GameConfig.MapPositions.VillageCenter + Vector3.new(0, 5, 15)

	if charName == "Wolf" then
		spawnPos = GameConfig.MapPositions.ForestPath + Vector3.new(0, 5, 0)
	elseif charName == "Pig" then
		-- Randomize among pig houses
		local houses = {"StrawHouse", "StickHouse", "BrickHouse"}
		local chosen = houses[math.random(#houses)]
		spawnPos = GameConfig.MapPositions[chosen] + Vector3.new(0, 5, 8)
	elseif charName == "RedRidingHood" then
		spawnPos = GameConfig.MapPositions.RedHouse + Vector3.new(0, 5, 8)
	elseif charName == "Goldilocks" then
		spawnPos = GameConfig.MapPositions.BearsHouse + Vector3.new(0, 5, 12)
	elseif charName == "Jack" then
		spawnPos = GameConfig.MapPositions.BeanstalkField + Vector3.new(0, 5, 10)
	end

	root.CFrame = CFrame.new(spawnPos)
end

-- Round system
local function startRound()
	gameState.currentRound = gameState.currentRound + 1
	gameState.roundActive = true
	gameState.roundTimeLeft = GameConfig.ROUND_DURATION

	-- Reset scores
	for player in pairs(gameState.playerScores) do
		gameState.playerScores[player] = 0
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			leaderstats.Score.Value = 0
		end
	end

	-- Teleport players
	for _, player in ipairs(Players:GetPlayers()) do
		if gameState.playerCharacters[player] then
			teleportToSpawn(player)
		end
	end

	roundInfoRemote:FireAllClients("RoundStart", {
		Round = gameState.currentRound,
		Duration = GameConfig.ROUND_DURATION,
	})

	print("[GameManager] Round " .. gameState.currentRound .. " started!")
end

local function endRound()
	gameState.roundActive = false

	-- Collect scores
	local scores = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(scores, {
			Name = player.Name,
			Character = gameState.playerCharacters[player] or "None",
			Score = getScore(player),
		})
	end

	table.sort(scores, function(a, b) return a.Score > b.Score end)

	roundInfoRemote:FireAllClients("RoundEnd", {
		Round = gameState.currentRound,
		Scores = scores,
	})

	print("[GameManager] Round " .. gameState.currentRound .. " ended!")
end

local function intermission()
	roundInfoRemote:FireAllClients("Intermission", {
		Duration = GameConfig.INTERMISSION_DURATION,
	})

	-- Show character select during intermission
	for _, player in ipairs(Players:GetPlayers()) do
		showCharacterSelectRemote:FireClient(player)
	end

	wait(GameConfig.INTERMISSION_DURATION)
end

-- Player connections
Players.PlayerAdded:Connect(function(player)
	setupLeaderboard(player)
	gameState.playerScores[player] = 0

	player.CharacterAdded:Connect(function(character)
		-- Apply character stats and costume if already selected
		local charName = gameState.playerCharacters[player]
		if charName then
			local charData = CharacterData.GetCharacter(charName)
			if charData then
				local humanoid = character:WaitForChild("Humanoid")
				humanoid.WalkSpeed = charData.WalkSpeed
			end
			-- Wait for character to fully load before applying costume
			wait(0.5)
			applyCostume(player)
			teleportToSpawn(player)
		end
	end)

	-- Show character select screen
	wait(1)
	showCharacterSelectRemote:FireClient(player)
	broadcastSlots()
end)

Players.PlayerRemoving:Connect(function(player)
	local charName = gameState.playerCharacters[player]
	if charName then
		gameState.characterSlots[charName] = math.max(0, gameState.characterSlots[charName] - 1)
		broadcastSlots()
	end

	gameState.playerCharacters[player] = nil
	gameState.playerScores[player] = nil
end)

-- Handle character selection
selectCharacterRemote.OnServerEvent:Connect(function(player, characterName)
	local success = assignCharacter(player, characterName)
	if success then
		print("[GameManager] " .. player.Name .. " selected " .. characterName)
		-- Re-apply walk speed
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local charData = CharacterData.GetCharacter(characterName)
			if humanoid and charData then
				humanoid.WalkSpeed = charData.WalkSpeed
			end
		end
		teleportToSpawn(player)
	else
		-- Notify client that selection failed
		updateHUDRemote:FireClient(player, "SelectionFailed", {Character = characterName})
	end
end)

-- Initialize the API bindable
local apiBindable = Instance.new("BindableFunction")
apiBindable.Name = "AddScore"
apiBindable.OnInvoke = function(player, amount)
	addScore(player, amount)
end
apiBindable.Parent = remotes

local getCharBindable = Instance.new("BindableFunction")
getCharBindable.Name = "GetPlayerCharacter"
getCharBindable.OnInvoke = function(player)
	return getPlayerCharacter(player)
end
getCharBindable.Parent = remotes

local isRoundActiveBindable = Instance.new("BindableFunction")
isRoundActiveBindable.Name = "IsRoundActive"
isRoundActiveBindable.OnInvoke = function()
	return gameState.roundActive
end
isRoundActiveBindable.Parent = remotes

-- Round timer tick (runs inside game loop below)

-- Main game loop
spawn(function()
	-- Wait for map to build
	wait(3)

	local firstRound = true

	while true do
		-- Wait for minimum players
		while #Players:GetPlayers() < GameConfig.MIN_PLAYERS_TO_START do
			roundInfoRemote:FireAllClients("WaitingForPlayers", {
				Current = #Players:GetPlayers(),
				Required = GameConfig.MIN_PLAYERS_TO_START,
			})
			wait(3)
		end

		if firstRound then
			-- On first round, wait for at least one player to pick a character
			roundInfoRemote:FireAllClients("Intermission", {
				Duration = 0,
			})
			while true do
				local anySelected = false
				for _, p in ipairs(Players:GetPlayers()) do
					if gameState.playerCharacters[p] then
						anySelected = true
						break
					end
				end
				if anySelected then break end
				wait(0.5)
			end
			-- Brief countdown after first selection
			wait(3)
			firstRound = false
		else
			intermission()
		end

		print("[GameManager] Starting round...")
		startRound()
		print("[GameManager] Round active: " .. tostring(gameState.roundActive) .. ", time: " .. gameState.roundTimeLeft)

		-- Round timer
		while gameState.roundActive do
			wait(1)
			gameState.roundTimeLeft = gameState.roundTimeLeft - 1

			print("[GameManager] Timer: " .. gameState.roundTimeLeft)
			roundInfoRemote:FireAllClients("TimeUpdate", {
				TimeLeft = gameState.roundTimeLeft,
			})

			if gameState.roundTimeLeft <= 0 then
				endRound()
			end
		end

		wait(5) -- Show scores for 5 seconds
	end
end)

print("[GameManager] Initialized!")
