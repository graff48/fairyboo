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
	print("[CharacterAbilities] addScore called for " .. player.Name .. ": +" .. amount)
	addScoreBindable:Invoke(player, amount)
end

local function getPlayerCharacter(player)
	local char = getCharBindable:Invoke(player)
	return char
end

local function isRoundActive()
	local active = isRoundActiveBindable:Invoke()
	return active
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

	-- Bear family NPCs
	local housePos = GameConfig.MapPositions.BearsHouse
	local bearActive = false -- true when bears are inside the house
	local bearBodies = {}
	local bearTouchCooldowns = {} -- [player][bearIndex] = tick()

	-- Create bear models
	for i, bearDef in ipairs(GameConfig.Bears) do
		local bearModel = Utils.CreateModel(bearDef.Name, map)

		-- Body
		local body = Utils.CreatePart({
			Name = "Body",
			Size = bearDef.Size,
			Position = housePos + Vector3.new(-20 + (i - 1) * 20, bearDef.Size.Y / 2, 25),
			BrickColor = bearDef.Color,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = true,
			Parent = bearModel,
		})

		-- Head
		local head = Utils.CreatePart({
			Name = "Head",
			Size = Vector3.new(bearDef.HeadSize, bearDef.HeadSize, bearDef.HeadSize),
			Position = body.Position + Vector3.new(0, bearDef.Size.Y / 2 + bearDef.HeadSize / 2, -bearDef.Size.Z / 2 + 0.5),
			BrickColor = bearDef.Color,
			Material = Enum.Material.SmoothPlastic,
			Shape = Enum.PartType.Ball,
			CanCollide = false,
			Parent = bearModel,
		})

		-- Ears
		for _, side in ipairs({-1, 1}) do
			Utils.CreatePart({
				Name = "Ear",
				Size = Vector3.new(bearDef.HeadSize * 0.4, bearDef.HeadSize * 0.4, bearDef.HeadSize * 0.3),
				Position = head.Position + Vector3.new(side * bearDef.HeadSize * 0.5, bearDef.HeadSize * 0.35, 0),
				BrickColor = bearDef.Color,
				Material = Enum.Material.SmoothPlastic,
				Shape = Enum.PartType.Ball,
				CanCollide = false,
				Parent = bearModel,
			})
		end

		-- Snout
		Utils.CreatePart({
			Name = "Snout",
			Size = Vector3.new(bearDef.HeadSize * 0.5, bearDef.HeadSize * 0.35, bearDef.HeadSize * 0.4),
			Position = head.Position + Vector3.new(0, -bearDef.HeadSize * 0.15, -bearDef.HeadSize * 0.45),
			BrickColor = BrickColor.new("Nougat"),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = bearModel,
		})

		-- Legs (4 legs)
		for _, offset in ipairs({
			Vector3.new(-bearDef.Size.X * 0.3, 0, -bearDef.Size.Z * 0.25),
			Vector3.new(bearDef.Size.X * 0.3, 0, -bearDef.Size.Z * 0.25),
			Vector3.new(-bearDef.Size.X * 0.3, 0, bearDef.Size.Z * 0.25),
			Vector3.new(bearDef.Size.X * 0.3, 0, bearDef.Size.Z * 0.25),
		}) do
			Utils.CreatePart({
				Name = "Leg",
				Size = Vector3.new(bearDef.Size.X * 0.25, bearDef.Size.Y * 0.3, bearDef.Size.Z * 0.25),
				Position = body.Position + offset + Vector3.new(0, -bearDef.Size.Y * 0.5 - bearDef.Size.Y * 0.1, 0),
				BrickColor = bearDef.Color,
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				Parent = bearModel,
			})
		end

		Utils.CreateBillboardGui(head, bearDef.Name, Color3.fromRGB(180, 120, 60))

		table.insert(bearBodies, {
			Model = bearModel,
			Body = body,
			Def = bearDef,
		})
	end

	-- Move all parts of a bear model to a new position smoothly
	local function moveBear(bear, targetPos, dt)
		local body = bear.Body
		local currentPos = body.Position
		local direction = targetPos - currentPos
		local flatDirection = Vector3.new(direction.X, 0, direction.Z)
		local dist = flatDirection.Magnitude

		if dist < 1 then return true end -- arrived

		local moveSpeed = GameConfig.Goldilocks.BearMoveSpeed * dt
		local step = flatDirection.Unit * math.min(moveSpeed, dist)
		local newPos = currentPos + step

		-- Calculate offset from body to move all parts together
		local delta = newPos - currentPos
		for _, part in ipairs(bear.Model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Position = part.Position + delta
			end
		end

		-- Face movement direction
		local lookTarget = currentPos + flatDirection
		local lookCFrame = CFrame.lookAt(body.Position, Vector3.new(lookTarget.X, body.Position.Y, lookTarget.Z))
		-- We just move parts, no CFrame rotation for simplicity with multi-part models

		return false -- not arrived yet
	end

	-- Pick a random roam target near the house or around the map
	local function getRandomRoamTarget(isReturning)
		if isReturning then
			-- Go back inside the house
			return housePos + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
		end

		-- Roam around the map near the Bears' House area
		local roamRadius = GameConfig.Goldilocks.BearRoamRadius
		local roamTargets = {
			-- Near the house
			housePos + Vector3.new(math.random(-20, 20), 0, math.random(15, 30)),
			-- Toward village
			housePos + Vector3.new(math.random(-30, 30), 0, math.random(40, roamRadius)),
			-- Garden area
			housePos + Vector3.new(math.random(-roamRadius, roamRadius), 0, math.random(-20, 20)),
			-- Near the path
			GameConfig.MapPositions.VillageCenter + Vector3.new(math.random(-20, 20), 0, math.random(-40, -20)),
		}
		return roamTargets[math.random(#roamTargets)]
	end

	-- Each bear gets its own roam loop
	for i, bear in ipairs(bearBodies) do
		spawn(function()
			local target = getRandomRoamTarget(false)
			local groundY = bear.Def.Size.Y / 2
			target = Vector3.new(target.X, groundY, target.Z)

			local timeSinceRoamStart = 0
			local isHome = false
			local homeTimer = 0

			while true do
				local dt = wait(0.1)
				if not isRoundActive() then continue end

				-- Move toward current target
				local arrived = moveBear(bear, target, dt)

				if arrived then
					-- Idle briefly before picking new target
					wait(math.random(2, 5))

					if bearActive then
						-- Bears are home cycle: roam inside the house
						if not isHome then
							target = housePos + Vector3.new(math.random(-6, 6), groundY, math.random(-6, 6))
							isHome = true
						else
							-- Roam within house
							target = housePos + Vector3.new(math.random(-8, 8), groundY, math.random(-6, 6))
						end
					else
						isHome = false
						target = getRandomRoamTarget(false)
						target = Vector3.new(target.X, groundY, target.Z)
					end
				end

				-- Check for players nearby
				for _, player in ipairs(Players:GetPlayers()) do
					local root = getPlayerRoot(player)
					if not root then continue end

					local dist = Utils.DistanceBetween(root.Position, bear.Body.Position)
					if dist < GameConfig.Goldilocks.BearDetectionRadius then
						-- Goldilocks gets kicked out when bears are home
						if bearActive and getPlayerCharacter(player) == "Goldilocks" then
							root.CFrame = CFrame.new(housePos + Vector3.new(0, 5, 20))
							updateHUDRemote:FireClient(player, "AbilityFeedback", {
								Message = bear.Def.Name .. " found you! Kicked out!",
							})
						end

						-- Point penalty for any non-bear player on touch
						local now = tick()
						if not bearTouchCooldowns[player] then
							bearTouchCooldowns[player] = {}
						end
						local lastHit = bearTouchCooldowns[player][i]
						if not lastHit or now - lastHit >= GameConfig.Goldilocks.BearTouchCooldown then
							bearTouchCooldowns[player][i] = now
							local penalty = bear.Def.TouchPenalty
							addScore(player, -penalty)
							updateHUDRemote:FireClient(player, "AbilityFeedback", {
								Message = bear.Def.Name .. " got you! -" .. penalty .. " points",
							})
						end
					end
				end
			end
		end)
	end

	-- Bear home/away cycle: bears periodically return to the house
	spawn(function()
		while true do
			-- Bears are out roaming
			wait(GameConfig.Goldilocks.BearReturnInterval)
			if not isRoundActive() then continue end

			-- Bears coming home
			bearActive = true
			print("[Bears] The bears are coming home!")

			for _, player in ipairs(Players:GetPlayers()) do
				if getPlayerCharacter(player) == "Goldilocks" then
					updateHUDRemote:FireClient(player, "AbilityFeedback", {
						Message = "The bears are coming home! Hide!",
					})
				end
			end

			-- Move all bears toward the house
			for _, bear in ipairs(bearBodies) do
				local groundY = bear.Def.Size.Y / 2
				-- The roam loops will pick house-interior targets since bearActive is true
			end

			-- Stay home for patrol duration
			wait(GameConfig.Goldilocks.BearPatrolDuration)

			-- Bears leave again
			bearActive = false
			print("[Bears] The bears are leaving again.")

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

	-- Clean up bear touch cooldowns when players leave
	Players.PlayerRemoving:Connect(function(player)
		bearTouchCooldowns[player] = nil
	end)
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
-- FOREST WOLF NPC
-- =============================
spawn(function()
	wait(5) -- Wait for map
	local map = workspace:WaitForChild("Map")

	local wolfDef = GameConfig.WolfNPCDef
	local wolfConfig = GameConfig.WolfNPC
	local forestPos = GameConfig.MapPositions.ForestPath

	-- Build wolf model
	local wolfModel = Utils.CreateModel(wolfDef.Name, map)

	local wolfBody = Utils.CreatePart({
		Name = "Body",
		Size = wolfDef.Size,
		Position = forestPos + Vector3.new(0, wolfDef.Size.Y / 2, 0),
		BrickColor = wolfDef.Color,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
		Parent = wolfModel,
	})

	-- Head
	local wolfHead = Utils.CreatePart({
		Name = "Head",
		Size = Vector3.new(wolfDef.HeadSize, wolfDef.HeadSize, wolfDef.HeadSize),
		Position = wolfBody.Position + Vector3.new(0, wolfDef.Size.Y / 2 + wolfDef.HeadSize / 2, -wolfDef.Size.Z / 2 + 0.5),
		BrickColor = wolfDef.Color,
		Material = Enum.Material.SmoothPlastic,
		Shape = Enum.PartType.Ball,
		CanCollide = false,
		Parent = wolfModel,
	})

	-- Pointed ears
	for _, side in ipairs({-1, 1}) do
		Utils.CreatePart({
			Name = "Ear",
			Size = Vector3.new(wolfDef.HeadSize * 0.25, wolfDef.HeadSize * 0.5, wolfDef.HeadSize * 0.2),
			Position = wolfHead.Position + Vector3.new(side * wolfDef.HeadSize * 0.4, wolfDef.HeadSize * 0.45, 0),
			BrickColor = wolfDef.Color,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = wolfModel,
		})
	end

	-- Snout
	Utils.CreatePart({
		Name = "Snout",
		Size = Vector3.new(wolfDef.HeadSize * 0.4, wolfDef.HeadSize * 0.3, wolfDef.HeadSize * 0.5),
		Position = wolfHead.Position + Vector3.new(0, -wolfDef.HeadSize * 0.15, -wolfDef.HeadSize * 0.5),
		BrickColor = BrickColor.new("Medium grey"),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = wolfModel,
	})

	-- Tail
	Utils.CreatePart({
		Name = "Tail",
		Size = Vector3.new(0.4, 0.4, 2),
		Position = wolfBody.Position + Vector3.new(0, wolfDef.Size.Y * 0.2, wolfDef.Size.Z / 2 + 1),
		BrickColor = wolfDef.Color,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = wolfModel,
	})

	-- Four legs
	for _, offset in ipairs({
		Vector3.new(-wolfDef.Size.X * 0.3, 0, -wolfDef.Size.Z * 0.25),
		Vector3.new(wolfDef.Size.X * 0.3, 0, -wolfDef.Size.Z * 0.25),
		Vector3.new(-wolfDef.Size.X * 0.3, 0, wolfDef.Size.Z * 0.25),
		Vector3.new(wolfDef.Size.X * 0.3, 0, wolfDef.Size.Z * 0.25),
	}) do
		Utils.CreatePart({
			Name = "Leg",
			Size = Vector3.new(wolfDef.Size.X * 0.2, wolfDef.Size.Y * 0.4, wolfDef.Size.Z * 0.15),
			Position = wolfBody.Position + offset + Vector3.new(0, -wolfDef.Size.Y * 0.5 - wolfDef.Size.Y * 0.15, 0),
			BrickColor = wolfDef.Color,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = wolfModel,
		})
	end

	Utils.CreateBillboardGui(wolfHead, wolfDef.Name, Color3.fromRGB(100, 100, 100))

	local wolf = {
		Model = wolfModel,
		Body = wolfBody,
	}

	-- Move wolf smoothly (same pattern as moveBear)
	local function moveWolf(targetPos, dt)
		local body = wolf.Body
		local currentPos = body.Position
		local direction = targetPos - currentPos
		local flatDirection = Vector3.new(direction.X, 0, direction.Z)
		local dist = flatDirection.Magnitude

		if dist < 1 then return true end -- arrived

		local moveSpeed = wolfConfig.MoveSpeed * dt
		local step = flatDirection.Unit * math.min(moveSpeed, dist)
		local delta = Vector3.new(step.X, 0, step.Z)

		for _, part in ipairs(wolf.Model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Position = part.Position + delta
			end
		end

		return false
	end

	-- Pick a random roam target in the forest area
	local function getWolfRoamTarget()
		local roamRadius = wolfConfig.RoamRadius
		local targets = {
			-- Near ForestPath
			forestPos + Vector3.new(math.random(-40, 40), 0, math.random(-30, 30)),
			-- Toward RedHouse corridor
			GameConfig.MapPositions.RedHouse + Vector3.new(math.random(-20, 20), 0, math.random(-30, 30)),
			-- Toward VillageCenter
			GameConfig.MapPositions.VillageCenter + Vector3.new(math.random(-30, 30), 0, math.random(20, 60)),
			-- Wide forest roam
			forestPos + Vector3.new(math.random(-roamRadius, roamRadius), 0, math.random(-roamRadius / 2, roamRadius / 2)),
		}
		return targets[math.random(#targets)]
	end

	-- Cooldown table for wolf NPC touches
	local wolfNPCCooldowns = {} -- [player] = tick()

	-- Roam loop
	spawn(function()
		local groundY = wolfDef.Size.Y / 2
		local target = getWolfRoamTarget()
		target = Vector3.new(target.X, groundY, target.Z)

		while true do
			local dt = wait(0.1)
			if not isRoundActive() then continue end

			local arrived = moveWolf(target, dt)

			if arrived then
				wait(math.random(1, 3))
				target = getWolfRoamTarget()
				target = Vector3.new(target.X, groundY, target.Z)
			end

			-- Player detection
			local now = tick()
			for _, player in ipairs(Players:GetPlayers()) do
				-- Skip wolf player characters
				if getPlayerCharacter(player) == "Wolf" then continue end

				local root = getPlayerRoot(player)
				if not root then continue end

				local dist = Utils.DistanceBetween(root.Position, wolf.Body.Position)
				if dist < wolfConfig.DetectionRadius then
					-- Check cooldown
					if wolfNPCCooldowns[player] and now - wolfNPCCooldowns[player] < wolfConfig.TouchCooldown then
						continue
					end
					wolfNPCCooldowns[player] = now

					addScore(player, -wolfConfig.TouchPenalty)
					updateHUDRemote:FireClient(player, "AbilityFeedback", {
						Message = "The Forest Wolf got you! -" .. wolfConfig.TouchPenalty .. " points",
					})
				end
			end
		end
	end)

	-- Clean up cooldowns when players leave
	Players.PlayerRemoving:Connect(function(player)
		wolfNPCCooldowns[player] = nil
	end)

	print("[CharacterAbilities] Forest Wolf NPC spawned!")
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
