local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CharacterData = require(Shared:WaitForChild("CharacterData"))
local Utils = require(Shared:WaitForChild("Utils"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local abilityRemote = remotes:WaitForChild("AbilityEvent")
local updateHUDRemote = remotes:WaitForChild("UpdateHUD")
local addScoreBindable = remotes:WaitForChild("AddScore")
local getCharBindable = remotes:WaitForChild("GetPlayerCharacter")
local isRoundActiveBindable = remotes:WaitForChild("IsRoundActive")

-- Helper functions
local function addScore(player, amount)
	addScoreBindable:Invoke(player, amount)
end

local function getPlayerCharacter(player)
	return getCharBindable:Invoke(player)
end

local function isRoundActive()
	return isRoundActiveBindable:Invoke()
end

local function getPlayerRoot(player)
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

-- =============================
-- WOLF ABILITIES
-- =============================
local wolfCatchCooldowns = {} -- [player] = tick

local function handleWolfCatchPig(wolfPlayer, pigPlayer)
	if not isRoundActive() then return end
	if getPlayerCharacter(wolfPlayer) ~= "Wolf" then return end
	if getPlayerCharacter(pigPlayer) ~= "Pig" then return end

	-- Check cooldown
	local now = tick()
	if wolfCatchCooldowns[wolfPlayer] and now - wolfCatchCooldowns[wolfPlayer] < GameConfig.Wolf.CatchCooldown then
		return
	end
	wolfCatchCooldowns[wolfPlayer] = now

	-- Score for wolf
	addScore(wolfPlayer, GameConfig.Scoring.Wolf.CatchPig)
	updateHUDRemote:FireClient(wolfPlayer, "AbilityFeedback", {Message = "Caught a pig! +50"})

	-- Respawn pig after delay
	local pigChar = pigPlayer.Character
	if pigChar then
		local humanoid = pigChar:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0 -- Triggers respawn
		end
	end

	updateHUDRemote:FireClient(pigPlayer, "AbilityFeedback", {Message = "Caught by the wolf!"})
end

-- Detect wolf touching pig players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1)
		if getPlayerCharacter(player) ~= "Wolf" then return end

		local root = character:WaitForChild("HumanoidRootPart")
		root.Touched:Connect(function(hit)
			local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
			if hitPlayer and hitPlayer ~= player then
				handleWolfCatchPig(player, hitPlayer)
			end
		end)
	end)
end)

-- Wolf blow down house
local function handleWolfBlowHouse(player, house)
	if not isRoundActive() then return end
	if getPlayerCharacter(player) ~= "Wolf" then return end

	local houseName = house.Name
	if not (Utils.HasTag(house, "Destructible")) then
		updateHUDRemote:FireClient(player, "AbilityFeedback", {Message = "This house is too strong!"})
		return
	end

	-- Check if house is already destroyed
	if Utils.HasTag(house, "Destroyed") then
		updateHUDRemote:FireClient(player, "AbilityFeedback", {Message = "Already destroyed!"})
		return
	end

	-- Destroy the house (make walls transparent/non-collidable)
	for _, part in ipairs(house:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Floor" and part.Name ~= "SpawnPoint" then
			part.Transparency = 0.8
			part.CanCollide = false
		end
	end

	Utils.CreateTag(house, "Destroyed")

	-- Enable repair prompt
	local repairPrompt = house:FindFirstChild("RepairPrompt", true)
	if repairPrompt then
		repairPrompt.Enabled = true
	end

	-- Disable blow prompt
	local blowPrompt = house:FindFirstChild("BlowPrompt", true)
	if blowPrompt then
		blowPrompt.Enabled = false
	end

	addScore(player, GameConfig.Scoring.Wolf.BlowHouse)
	updateHUDRemote:FireClient(player, "AbilityFeedback", {Message = "House blown down! +30"})
end

-- =============================
-- PIG ABILITIES
-- =============================
local function handlePigRepairHouse(player, house)
	if not isRoundActive() then return end
	if getPlayerCharacter(player) ~= "Pig" then return end

	if not Utils.HasTag(house, "Destroyed") then return end

	-- Repair the house
	for _, part in ipairs(house:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Floor" and part.Name ~= "SpawnPoint" then
			part.Transparency = 0
			part.CanCollide = true
		end
	end

	-- Remove destroyed tag
	local destroyedTag = house:FindFirstChild("Destroyed")
	if destroyedTag then
		destroyedTag:Destroy()
	end

	-- Toggle prompts
	local repairPrompt = house:FindFirstChild("RepairPrompt", true)
	if repairPrompt then
		repairPrompt.Enabled = false
	end

	local blowPrompt = house:FindFirstChild("BlowPrompt", true)
	if blowPrompt then
		blowPrompt.Enabled = true
	end

	addScore(player, GameConfig.Scoring.Pig.RepairHouse)
	updateHUDRemote:FireClient(player, "AbilityFeedback", {Message = "House repaired! +20"})
end

-- Pig passive scoring: earn points while in a house when wolf is nearby
spawn(function()
	while true do
		wait(1)
		if not isRoundActive() then continue end

		-- Find wolf players
		local wolfPositions = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if getPlayerCharacter(player) == "Wolf" then
				local root = getPlayerRoot(player)
				if root then
					table.insert(wolfPositions, root.Position)
				end
			end
		end

		if #wolfPositions == 0 then continue end

		-- Check pig players
		for _, player in ipairs(Players:GetPlayers()) do
			if getPlayerCharacter(player) == "Pig" then
				local root = getPlayerRoot(player)
				if not root then continue end

				-- Check if pig is inside a house
				local map = workspace:FindFirstChild("Map")
				if not map then continue end

				for _, house in ipairs({"StrawHouse", "StickHouse", "BrickHouse"}) do
					local houseModel = map:FindFirstChild(house)
					if houseModel and not Utils.HasTag(houseModel, "Destroyed") then
						local housePos = GameConfig.MapPositions[house]
						local distToHouse = Utils.DistanceBetween(root.Position, housePos)

						if distToHouse < 12 then -- Inside house radius
							-- Check if wolf is nearby
							for _, wolfPos in ipairs(wolfPositions) do
								if Utils.DistanceBetween(wolfPos, housePos) < GameConfig.Pig.PassiveScoreRadius then
									addScore(player, GameConfig.Scoring.Pig.PassiveInHouse)
									updateHUDRemote:FireClient(player, "AbilityFeedback", {
										Message = "Safe in house while wolf lurks! +10",
									})
									break
								end
							end
							break
						end
					end
				end
			end
		end
	end
end)

-- =============================
-- RED RIDING HOOD ABILITIES
-- =============================
local redTripState = {} -- [player] = {startTime, hasStarted}

-- Detect Red starting a trip (entering Red's House area)
spawn(function()
	while true do
		wait(0.5)
		if not isRoundActive() then continue end

		for _, player in ipairs(Players:GetPlayers()) do
			if getPlayerCharacter(player) == "RedRidingHood" then
				local root = getPlayerRoot(player)
				if not root then continue end

				local redHousePos = GameConfig.MapPositions.RedHouse
				local grandmaPos = GameConfig.MapPositions.GrandmaHouse
				local distToRedHouse = Utils.DistanceBetween(root.Position, redHousePos)
				local distToGrandma = Utils.DistanceBetween(root.Position, grandmaPos)

				-- Start trip when near Red's house
				if distToRedHouse < 15 then
					if not redTripState[player] or not redTripState[player].hasStarted then
						redTripState[player] = {startTime = tick(), hasStarted = true}
						updateHUDRemote:FireClient(player, "AbilityFeedback", {
							Message = "Trip started! Head to Grandma's house!",
						})
					end
				end

				-- Complete trip when reaching Grandma's house
				if distToGrandma < 15 and redTripState[player] and redTripState[player].hasStarted then
					local tripTime = tick() - redTripState[player].startTime
					local baseScore = GameConfig.Scoring.RedRidingHood.CompleteTrip

					-- Speed bonus
					local speedBonus = 0
					if tripTime < GameConfig.RedRidingHood.SpeedBonusTimeThreshold then
						local ratio = 1 - (tripTime / GameConfig.RedRidingHood.SpeedBonusTimeThreshold)
						speedBonus = math.floor(GameConfig.Scoring.RedRidingHood.SpeedBonusMax * ratio)
					end

					addScore(player, baseScore + speedBonus)

					local msg = "Trip complete! +" .. baseScore
					if speedBonus > 0 then
						msg = msg .. " (Speed bonus: +" .. speedBonus .. ")"
					end
					updateHUDRemote:FireClient(player, "AbilityFeedback", {Message = msg})

					redTripState[player] = nil

					-- Teleport back to Red's house
					root.CFrame = CFrame.new(redHousePos + Vector3.new(0, 5, 8))
				end

				-- Check if wolf catches Red in forest
				if redTripState[player] and redTripState[player].hasStarted then
					local forestPos = GameConfig.MapPositions.ForestPath
					local distToForest = Utils.DistanceBetween(root.Position, forestPos)

					if distToForest < 40 then -- In forest area
						for _, otherPlayer in ipairs(Players:GetPlayers()) do
							if getPlayerCharacter(otherPlayer) == "Wolf" then
								local wolfRoot = getPlayerRoot(otherPlayer)
								if wolfRoot then
									local distToWolf = Utils.DistanceBetween(root.Position, wolfRoot.Position)
									if distToWolf < 6 then
										-- Caught! Send back to start
										redTripState[player] = nil
										root.CFrame = CFrame.new(redHousePos + Vector3.new(0, 5, 8))
										updateHUDRemote:FireClient(player, "AbilityFeedback", {
											Message = "Caught by the wolf! Sent back to start.",
										})
										break
									end
								end
							end
						end
					end
				end
			end
		end
	end
end)

-- Basket collectibles for Red
spawn(function()
	wait(5) -- Wait for map
	local map = workspace:WaitForChild("Map")
	local forest = map:WaitForChild("Forest")

	local function spawnBasket(spawnPoint)
		local basket = Utils.CreatePart({
			Name = "Basket",
			Size = Vector3.new(2, 2, 2),
			Position = spawnPoint.Position + Vector3.new(0, 1, 0),
			BrickColor = BrickColor.new("Brown"),
			Material = Enum.Material.WoodPlanks,
			Parent = forest,
		})
		Utils.CreateTag(basket, "Basket")

		local prompt = Utils.CreateProximityPrompt(basket, "Collect Basket", 0, 8)
		prompt.Triggered:Connect(function(player)
			if getPlayerCharacter(player) == "RedRidingHood" and isRoundActive() then
				addScore(player, GameConfig.Scoring.RedRidingHood.BasketCollectible)
				updateHUDRemote:FireClient(player, "AbilityFeedback", {
					Message = "Basket collected! +15",
				})
				basket:Destroy()

				-- Respawn after delay
				delay(GameConfig.RedRidingHood.BasketSpawnInterval, function()
					if spawnPoint and spawnPoint.Parent then
						spawnBasket(spawnPoint)
					end
				end)
			end
		end)
	end

	for _, child in ipairs(forest:GetChildren()) do
		if Utils.HasTag(child, "BasketSpawn") then
			spawnBasket(child)
		end
	end
end)

-- =============================
-- GOLDILOCKS ABILITIES
-- =============================
local goldilocksProgress = {} -- [player] = {triedWrong = {Porridge=bool, Chair=bool, Bed=bool}, found = {}}

local function initGoldilocksProgress(player)
	goldilocksProgress[player] = {
		triedWrong = {Porridge = false, Chair = false, Bed = false},
		found = {},
	}
end

spawn(function()
	wait(5) -- Wait for map
	local map = workspace:WaitForChild("Map")
	local bearsHouse = map:WaitForChild("BearsHouse")

	-- Setup interaction for each Goldilocks item
	for _, child in ipairs(bearsHouse:GetDescendants()) do
		if child:IsA("ProximityPrompt") and child.Parent and Utils.HasTag(child.Parent, "GoldilocksItem") then
			local item = child.Parent
			local itemName = item.Name

			child.Triggered:Connect(function(player)
				if getPlayerCharacter(player) ~= "Goldilocks" then return end
				if not isRoundActive() then return end

				if not goldilocksProgress[player] then
					initGoldilocksProgress(player)
				end

				local progress = goldilocksProgress[player]

				-- Determine item category and whether it's "just right"
				local category = nil
				local isJustRight = false

				if string.find(itemName, "Porridge") then
					category = "Porridge"
					isJustRight = string.find(itemName, "JustRight") ~= nil
				elseif string.find(itemName, "Chair") then
					category = "Chair"
					isJustRight = string.find(itemName, "JustRight") ~= nil
				elseif string.find(itemName, "Bed") then
					category = "Bed"
					isJustRight = string.find(itemName, "JustRight") ~= nil
				end

				if not category then return end

				-- Already found this category's "just right"?
				if progress.found[category] then
					updateHUDRemote:FireClient(player, "AbilityFeedback", {
						Message = "Already found the right " .. category .. "!",
					})
					return
				end

				if isJustRight then
					-- Must have tried a wrong one first
					if not progress.triedWrong[category] then
						updateHUDRemote:FireClient(player, "AbilityFeedback", {
							Message = "Try the other " .. string.lower(category) .. "s first!",
						})
						return
					end

					-- Found just right!
					progress.found[category] = true
					addScore(player, GameConfig.Scoring.Goldilocks.JustRightItem)
					updateHUDRemote:FireClient(player, "AbilityFeedback", {
						Message = "This " .. string.lower(category) .. " is just right! +40",
					})
				else
					-- Tried a wrong one
					progress.triedWrong[category] = true
					local feedback = {
						Porridge_TooHot = "Too hot!",
						Porridge_TooCold = "Too cold!",
						Chair_TooBig = "Too big!",
						Chair_TooSmall = "Too small!",
						Bed_TooHard = "Too hard!",
						Bed_TooSoft = "Too soft!",
					}
					updateHUDRemote:FireClient(player, "AbilityFeedback", {
						Message = feedback[itemName] or "Not quite right...",
					})
				end
			end)
		end
	end

	-- Bear patrol NPC
	local bearModel = Utils.CreateModel("Bear", bearsHouse)
	local bearBody = Utils.CreatePart({
		Name = "BearBody",
		Size = Vector3.new(4, 6, 3),
		Position = GameConfig.MapPositions.BearsHouse + Vector3.new(0, 50, 0), -- Start hidden above
		BrickColor = BrickColor.new("Brown"),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
		Parent = bearModel,
	})
	Utils.CreateBillboardGui(bearBody, "Papa Bear", Color3.new(0.5, 0.3, 0.1))

	local bearActive = false
	local bearPatrolPoints = {}
	local patrolFolder = bearsHouse:FindFirstChild("BearPatrolPoints")
	if patrolFolder then
		for _, point in ipairs(patrolFolder:GetChildren()) do
			table.insert(bearPatrolPoints, point.Position)
		end
	end

	-- Bear patrol cycle
	spawn(function()
		while true do
			wait(GameConfig.Goldilocks.BearReturnInterval)
			if not isRoundActive() then continue end

			-- Bear appears
			bearActive = true
			local housePos = GameConfig.MapPositions.BearsHouse

			-- Announce bear return
			for _, player in ipairs(Players:GetPlayers()) do
				if getPlayerCharacter(player) == "Goldilocks" then
					updateHUDRemote:FireClient(player, "AbilityFeedback", {
						Message = "The bears are coming home! Hide!",
					})
				end
			end

			-- Patrol
			for i = 1, #bearPatrolPoints * 2 do
				if not isRoundActive() then break end
				local target = bearPatrolPoints[((i - 1) % #bearPatrolPoints) + 1]
				bearBody.Position = target + Vector3.new(0, 3, 0)

				-- Check if any Goldilocks is nearby and not hidden
				for _, player in ipairs(Players:GetPlayers()) do
					if getPlayerCharacter(player) == "Goldilocks" then
						local root = getPlayerRoot(player)
						if root then
							local dist = Utils.DistanceBetween(root.Position, bearBody.Position)
							if dist < 10 then
								-- Caught! Teleport out
								root.CFrame = CFrame.new(housePos + Vector3.new(0, 5, 15))
								updateHUDRemote:FireClient(player, "AbilityFeedback", {
									Message = "The bears found you! Kicked out!",
								})
							end
						end
					end
				end

				wait(GameConfig.Goldilocks.BearPatrolDuration / (#bearPatrolPoints * 2))
			end

			-- Bear leaves
			bearBody.Position = housePos + Vector3.new(0, 50, 0)
			bearActive = false

			for _, player in ipairs(Players:GetPlayers()) do
				if getPlayerCharacter(player) == "Goldilocks" then
					updateHUDRemote:FireClient(player, "AbilityFeedback", {
						Message = "The bears left. It's safe to explore!",
					})
				end
			end
		end
	end)

	-- Hide spot interaction
	for _, child in ipairs(bearsHouse:GetDescendants()) do
		if Utils.HasTag(child, "HideSpot") then
			local prompt = child:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					if getPlayerCharacter(player) ~= "Goldilocks" then return end
					if not bearActive then
						updateHUDRemote:FireClient(player, "AbilityFeedback", {
							Message = "No need to hide right now.",
						})
						return
					end

					-- Hide the player (make transparent briefly)
					local character = player.Character
					if character then
						for _, part in ipairs(character:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Transparency = 1
							end
						end

						updateHUDRemote:FireClient(player, "AbilityFeedback", {
							Message = "Hiding from the bears...",
						})

						wait(GameConfig.Goldilocks.BearPatrolDuration)

						for _, part in ipairs(character:GetDescendants()) do
							if part:IsA("BasePart") then
								if part.Name == "HumanoidRootPart" then
									part.Transparency = 1 -- HRP is always invisible
								else
									part.Transparency = 0
								end
							end
						end
					end
				end)
			end
		end
	end
end)

-- =============================
-- JACK ABILITIES
-- =============================
spawn(function()
	wait(5) -- Wait for map
	local map = workspace:WaitForChild("Map")
	local beanstalkField = map:WaitForChild("BeanstalkField")

	-- Golden item collection
	for _, child in ipairs(beanstalkField:GetDescendants()) do
		if Utils.HasTag(child, "GoldenItem") and child:IsA("BasePart") then
			local prompt = child:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				local originalPos = child.Position

				prompt.Triggered:Connect(function(player)
					if getPlayerCharacter(player) ~= "Jack" then return end
					if not isRoundActive() then return end

					addScore(player, GameConfig.Scoring.Jack.GoldenItem)
					updateHUDRemote:FireClient(player, "AbilityFeedback", {
						Message = "Golden item collected! +30",
					})

					-- Hide item
					child.Transparency = 1
					child.CanCollide = false
					prompt.Enabled = false

					-- Respawn after timer
					delay(GameConfig.Jack.ItemRespawnTime, function()
						if child and child.Parent then
							child.Transparency = 0
							child.CanCollide = true
							child.Position = originalPos
							prompt.Enabled = true
						end
					end)
				end)
			end
		end
	end

	-- Giant NPC
	local giantModel = Utils.CreateModel("Giant", beanstalkField)
	local giantBody = Utils.CreatePart({
		Name = "GiantBody",
		Size = Vector3.new(8, 14, 6),
		Position = GameConfig.MapPositions.BeanstalkField + Vector3.new(0, 200, 0), -- Hidden initially
		BrickColor = BrickColor.new("Dark stone grey"),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
		Parent = giantModel,
	})
	Utils.CreateBillboardGui(giantBody, "Fe Fi Fo Fum!", Color3.new(1, 0, 0))

	local giantPatrolPoints = {}
	local patrolFolder = beanstalkField:FindFirstChild("GiantPatrolPoints")
	if patrolFolder then
		for _, point in ipairs(patrolFolder:GetChildren()) do
			table.insert(giantPatrolPoints, point.Position)
		end
	end

	-- Giant patrol loop
	local cloudHeight = 120 + 5 -- Match MapBuilder's cloud height
	spawn(function()
		wait(10) -- Initial delay

		while true do
			if not isRoundActive() or #giantPatrolPoints == 0 then
				wait(2)
				continue
			end

			-- Patrol on cloud
			for i = 1, #giantPatrolPoints do
				if not isRoundActive() then break end

				local target = giantPatrolPoints[i]
				giantBody.Position = target + Vector3.new(0, 7, 0)

				-- Check for Jack players nearby
				for _, player in ipairs(Players:GetPlayers()) do
					if getPlayerCharacter(player) == "Jack" then
						local root = getPlayerRoot(player)
						if root then
							local dist = Utils.DistanceBetween(root.Position, giantBody.Position)
							if dist < GameConfig.Jack.GiantDetectionRadius then
								-- Caught! Drop back down
								local fieldPos = GameConfig.MapPositions.BeanstalkField
								root.CFrame = CFrame.new(fieldPos + Vector3.new(0, 5, 10))

								addScore(player, GameConfig.Scoring.Jack.EscapeGiantBonus) -- Partial credit
								updateHUDRemote:FireClient(player, "AbilityFeedback", {
									Message = "The giant caught you! Dropped back down.",
								})
							end
						end
					end
				end

				wait(3) -- Time at each patrol point
			end

			wait(2) -- Brief pause between patrol cycles
		end
	end)
end)

-- =============================
-- PROXIMITY PROMPT HANDLERS (Wolf blow / Pig repair)
-- =============================
spawn(function()
	wait(5) -- Wait for map
	local map = workspace:WaitForChild("Map")

	-- Setup blow prompts for wolf
	for _, houseName in ipairs({"StrawHouse", "StickHouse"}) do
		local house = map:FindFirstChild(houseName)
		if house then
			local blowPrompt = house:FindFirstChild("BlowPrompt", true)
			if blowPrompt then
				blowPrompt.Triggered:Connect(function(player)
					handleWolfBlowHouse(player, house)
				end)
			end

			local repairPrompt = house:FindFirstChild("RepairPrompt", true)
			if repairPrompt then
				repairPrompt.Triggered:Connect(function(player)
					handlePigRepairHouse(player, house)
				end)
			end
		end
	end
end)

-- Clean up on player leaving
Players.PlayerRemoving:Connect(function(player)
	wolfCatchCooldowns[player] = nil
	redTripState[player] = nil
	goldilocksProgress[player] = nil
end)

-- Reset Goldilocks progress on new round
remotes:WaitForChild("RoundInfo").OnClientEvent = nil -- Server doesn't listen to client events on this

-- Listen for round resets via roundActive changing
spawn(function()
	local wasActive = false
	while true do
		wait(1)
		local active = isRoundActive()
		if active and not wasActive then
			-- New round started, reset character-specific state
			for _, player in ipairs(Players:GetPlayers()) do
				if getPlayerCharacter(player) == "Goldilocks" then
					initGoldilocksProgress(player)
				end
				redTripState[player] = nil
			end
			wolfCatchCooldowns = {}
		end
		wasActive = active
	end
end)

print("[CharacterAbilities] Initialized!")
