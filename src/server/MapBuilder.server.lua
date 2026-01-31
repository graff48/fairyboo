local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local MapBuilder = {}
local mapFolder = Instance.new("Folder")
mapFolder.Name = "Map"
mapFolder.Parent = workspace

-- Colors
local COLORS = {
	Grass = BrickColor.new("Bright green"),
	Path = BrickColor.new("Sand yellow"),
	Straw = BrickColor.new("Brick yellow"),
	Wood = BrickColor.new("Brown"),
	Brick = BrickColor.new("Bright red"),
	Roof = BrickColor.new("Dark orange"),
	Stone = BrickColor.new("Medium stone grey"),
	Water = BrickColor.new("Bright blue"),
	Leaves = BrickColor.new("Forest green"),
	Trunk = BrickColor.new("Reddish brown"),
	Gold = BrickColor.new("Bright yellow"),
	Door = BrickColor.new("Brown"),
}

local function createGround()
	local ground = Utils.CreatePart({
		Name = "Ground",
		Size = Vector3.new(500, 1, 600),
		Position = Vector3.new(0, -0.5, -70),
		BrickColor = COLORS.Grass,
		Material = Enum.Material.Grass,
		Parent = mapFolder,
	})
	return ground
end

local function createPath(from, to, width)
	local mid = (from + to) / 2
	local direction = to - from
	local length = direction.Magnitude

	local path = Utils.CreatePart({
		Name = "Path",
		Size = Vector3.new(width or 8, 0.2, length),
		Position = Vector3.new(mid.X, 0.1, mid.Z),
		BrickColor = COLORS.Path,
		Material = Enum.Material.Sand,
		Parent = mapFolder,
	})

	-- Rotate path to face the right direction
	path.CFrame = CFrame.new(mid + Vector3.new(0, 0.1, 0), to + Vector3.new(0, 0.1, 0))
		* CFrame.new(0, 0, -length / 2)
	path.CFrame = CFrame.new(mid + Vector3.new(0, 0.1, 0))
	-- Simple approach: only handle axis-aligned or use lookAt
	if math.abs(direction.X) > math.abs(direction.Z) then
		path.Size = Vector3.new(length, 0.2, width or 8)
	else
		path.Size = Vector3.new(width or 8, 0.2, length)
	end
	path.Position = Vector3.new(mid.X, 0.1, mid.Z)

	return path
end

local function createTree(position, parent)
	local treeModel = Utils.CreateModel("Tree", parent or mapFolder)

	local trunk = Utils.CreatePart({
		Name = "Trunk",
		Size = Vector3.new(2, 10, 2),
		Position = position + Vector3.new(0, 5, 0),
		BrickColor = COLORS.Trunk,
		Material = Enum.Material.Wood,
		Shape = Enum.PartType.Cylinder,
		Parent = treeModel,
	})
	trunk.CFrame = CFrame.new(position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Size = Vector3.new(10, 2, 2)

	local leaves = Utils.CreatePart({
		Name = "Leaves",
		Size = Vector3.new(8, 8, 8),
		Position = position + Vector3.new(0, 12, 0),
		BrickColor = COLORS.Leaves,
		Material = Enum.Material.Grass,
		Shape = Enum.PartType.Ball,
		Parent = treeModel,
	})

	return treeModel
end

local function createHouse(position, name, material, wallColor, destructible)
	local houseModel = Utils.CreateModel(name, mapFolder)

	local wallHeight = 10
	local wallThickness = 1
	local houseWidth = 16
	local houseDepth = 14

	-- Floor
	Utils.CreatePart({
		Name = "Floor",
		Size = Vector3.new(houseWidth, 0.5, houseDepth),
		Position = position + Vector3.new(0, 0.25, 0),
		BrickColor = wallColor,
		Material = material,
		Parent = houseModel,
	})

	-- Back wall
	Utils.CreatePart({
		Name = "BackWall",
		Size = Vector3.new(houseWidth, wallHeight, wallThickness),
		Position = position + Vector3.new(0, wallHeight / 2, -houseDepth / 2),
		BrickColor = wallColor,
		Material = material,
		Parent = houseModel,
	})

	-- Left wall
	Utils.CreatePart({
		Name = "LeftWall",
		Size = Vector3.new(wallThickness, wallHeight, houseDepth),
		Position = position + Vector3.new(-houseWidth / 2, wallHeight / 2, 0),
		BrickColor = wallColor,
		Material = material,
		Parent = houseModel,
	})

	-- Right wall
	Utils.CreatePart({
		Name = "RightWall",
		Size = Vector3.new(wallThickness, wallHeight, houseDepth),
		Position = position + Vector3.new(houseWidth / 2, wallHeight / 2, 0),
		BrickColor = wallColor,
		Material = material,
		Parent = houseModel,
	})

	-- Front wall with door gap
	local doorWidth = 5
	local sideWidth = (houseWidth - doorWidth) / 2

	Utils.CreatePart({
		Name = "FrontWallLeft",
		Size = Vector3.new(sideWidth, wallHeight, wallThickness),
		Position = position + Vector3.new(-(doorWidth / 2 + sideWidth / 2), wallHeight / 2, houseDepth / 2),
		BrickColor = wallColor,
		Material = material,
		Parent = houseModel,
	})

	Utils.CreatePart({
		Name = "FrontWallRight",
		Size = Vector3.new(sideWidth, wallHeight, wallThickness),
		Position = position + Vector3.new(doorWidth / 2 + sideWidth / 2, wallHeight / 2, houseDepth / 2),
		BrickColor = wallColor,
		Material = material,
		Parent = houseModel,
	})

	-- Above door
	Utils.CreatePart({
		Name = "FrontWallTop",
		Size = Vector3.new(doorWidth, wallHeight - 7, wallThickness),
		Position = position + Vector3.new(0, wallHeight - (wallHeight - 7) / 2, houseDepth / 2),
		BrickColor = wallColor,
		Material = material,
		Parent = houseModel,
	})

	-- Roof (two angled parts)
	local roofOverhang = 2
	local roofWidth = houseWidth / 2 + roofOverhang
	local roofAngle = math.rad(30)

	local roofLeft = Utils.CreatePart({
		Name = "RoofLeft",
		Size = Vector3.new(roofWidth / math.cos(roofAngle), 0.5, houseDepth + roofOverhang),
		BrickColor = COLORS.Roof,
		Material = Enum.Material.Wood,
		Parent = houseModel,
	})
	roofLeft.CFrame = CFrame.new(position + Vector3.new(-roofWidth / 2 * 0.5, wallHeight + 2, 0))
		* CFrame.Angles(0, 0, roofAngle)

	local roofRight = Utils.CreatePart({
		Name = "RoofRight",
		Size = Vector3.new(roofWidth / math.cos(roofAngle), 0.5, houseDepth + roofOverhang),
		BrickColor = COLORS.Roof,
		Material = Enum.Material.Wood,
		Parent = houseModel,
	})
	roofRight.CFrame = CFrame.new(position + Vector3.new(roofWidth / 2 * 0.5, wallHeight + 2, 0))
		* CFrame.Angles(0, 0, -roofAngle)

	-- Tags
	Utils.CreateTag(houseModel, "House")
	if destructible then
		Utils.CreateTag(houseModel, "Destructible")
	end

	-- Label
	Utils.CreateBillboardGui(
		houseModel:FindFirstChild("Floor"),
		name,
		wallColor.Color
	)

	-- Spawn point inside the house
	local spawn = Utils.CreatePart({
		Name = "SpawnPoint",
		Size = Vector3.new(4, 0.2, 4),
		Position = position + Vector3.new(0, 0.6, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = houseModel,
	})

	return houseModel
end

local function createStrawHouse()
	local pos = GameConfig.MapPositions.StrawHouse
	local house = createHouse(pos, "StrawHouse", Enum.Material.Sand, COLORS.Straw, true)
	Utils.CreateTag(house, "StrawHouse")

	-- Blow prompt for wolf
	local blowPrompt = Utils.CreateProximityPrompt(
		house:FindFirstChild("Floor"),
		"Huff and Puff",
		GameConfig.Wolf.BlowChannelTime,
		15
	)
	blowPrompt.Name = "BlowPrompt"
	blowPrompt.Enabled = true

	-- Repair prompt for pigs
	local repairPrompt = Utils.CreateProximityPrompt(
		house:FindFirstChild("FrontWallLeft"),
		"Repair House",
		GameConfig.Pig.RepairChannelTime,
		10
	)
	repairPrompt.Name = "RepairPrompt"
	repairPrompt.Enabled = false -- enabled when house is destroyed

	return house
end

local function createStickHouse()
	local pos = GameConfig.MapPositions.StickHouse
	local house = createHouse(pos, "StickHouse", Enum.Material.WoodPlanks, COLORS.Wood, true)
	Utils.CreateTag(house, "StickHouse")

	local blowPrompt = Utils.CreateProximityPrompt(
		house:FindFirstChild("Floor"),
		"Huff and Puff",
		GameConfig.Wolf.BlowChannelTime,
		15
	)
	blowPrompt.Name = "BlowPrompt"
	blowPrompt.Enabled = true

	local repairPrompt = Utils.CreateProximityPrompt(
		house:FindFirstChild("FrontWallLeft"),
		"Repair House",
		GameConfig.Pig.RepairChannelTime,
		10
	)
	repairPrompt.Name = "RepairPrompt"
	repairPrompt.Enabled = false

	return house
end

local function createBrickHouse()
	local pos = GameConfig.MapPositions.BrickHouse
	local house = createHouse(pos, "BrickHouse", Enum.Material.Brick, COLORS.Brick, false)
	Utils.CreateTag(house, "BrickHouse")
	return house
end

local function createVillageCenter()
	local pos = GameConfig.MapPositions.VillageCenter
	local village = Utils.CreateModel("VillageCenter", mapFolder)

	-- Central platform
	Utils.CreatePart({
		Name = "Platform",
		Size = Vector3.new(30, 0.5, 30),
		Position = pos + Vector3.new(0, 0.25, 0),
		BrickColor = COLORS.Stone,
		Material = Enum.Material.Cobblestone,
		Parent = village,
	})

	-- Fountain in center
	local fountain = Utils.CreatePart({
		Name = "FountainBase",
		Size = Vector3.new(8, 2, 8),
		Position = pos + Vector3.new(0, 1, 0),
		BrickColor = COLORS.Stone,
		Material = Enum.Material.Concrete,
		Shape = Enum.PartType.Cylinder,
		Parent = village,
	})
	fountain.CFrame = CFrame.new(pos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	fountain.Size = Vector3.new(2, 8, 8)

	Utils.CreatePart({
		Name = "FountainWater",
		Size = Vector3.new(6, 0.5, 6),
		Position = pos + Vector3.new(0, 2.25, 0),
		BrickColor = COLORS.Water,
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		Parent = village,
	})

	Utils.CreateBillboardGui(fountain, "Village Center", Color3.new(1, 1, 1))

	return village
end

local function createForest()
	local forestModel = Utils.CreateModel("Forest", mapFolder)
	local pos = GameConfig.MapPositions.ForestPath

	-- Forest path ground
	createPath(
		GameConfig.MapPositions.RedHouse,
		GameConfig.MapPositions.GrandmaHouse,
		10
	)

	-- Trees along the forest path
	local treePositions = {
		pos + Vector3.new(-15, 0, -20),
		pos + Vector3.new(15, 0, -20),
		pos + Vector3.new(-20, 0, 0),
		pos + Vector3.new(20, 0, 0),
		pos + Vector3.new(-15, 0, 20),
		pos + Vector3.new(15, 0, 20),
		pos + Vector3.new(-25, 0, -10),
		pos + Vector3.new(25, 0, -10),
		pos + Vector3.new(-25, 0, 10),
		pos + Vector3.new(25, 0, 10),
		pos + Vector3.new(-30, 0, 0),
		pos + Vector3.new(30, 0, 0),
		pos + Vector3.new(-10, 0, -30),
		pos + Vector3.new(10, 0, -30),
		pos + Vector3.new(-10, 0, 30),
		pos + Vector3.new(10, 0, 30),
	}

	for _, treePos in ipairs(treePositions) do
		createTree(treePos, forestModel)
	end

	-- Basket spawn points along the path
	local basketSpawns = {
		pos + Vector3.new(-5, 1, -15),
		pos + Vector3.new(5, 1, 0),
		pos + Vector3.new(-5, 1, 15),
		pos + Vector3.new(8, 1, -8),
		pos + Vector3.new(-8, 1, 8),
	}

	for i, spawnPos in ipairs(basketSpawns) do
		local spawn = Utils.CreatePart({
			Name = "BasketSpawn_" .. i,
			Size = Vector3.new(2, 0.2, 2),
			Position = spawnPos,
			Transparency = 1,
			CanCollide = false,
			Parent = forestModel,
		})
		Utils.CreateTag(spawn, "BasketSpawn")
	end

	return forestModel
end

local function createRedHouse()
	local pos = GameConfig.MapPositions.RedHouse
	local house = Utils.CreateModel("RedHouse", mapFolder)

	-- Simple cottage
	Utils.CreatePart({
		Name = "Floor",
		Size = Vector3.new(12, 0.5, 12),
		Position = pos + Vector3.new(0, 0.25, 0),
		BrickColor = BrickColor.new("Brown"),
		Material = Enum.Material.WoodPlanks,
		Parent = house,
	})

	Utils.CreatePart({
		Name = "Walls",
		Size = Vector3.new(12, 8, 12),
		Position = pos + Vector3.new(0, 4.5, 0),
		BrickColor = BrickColor.new("Bright red"),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.3,
		Parent = house,
	})

	Utils.CreatePart({
		Name = "Roof",
		Size = Vector3.new(14, 1, 14),
		Position = pos + Vector3.new(0, 9, 0),
		BrickColor = COLORS.Roof,
		Material = Enum.Material.Wood,
		Parent = house,
	})

	Utils.CreateTag(house, "RedHouse")
	Utils.CreateTag(house, "TripStart")
	Utils.CreateBillboardGui(house:FindFirstChild("Roof"), "Red's House", Color3.new(1, 0, 0))

	-- Spawn point
	Utils.CreatePart({
		Name = "SpawnPoint",
		Size = Vector3.new(4, 0.2, 4),
		Position = pos + Vector3.new(0, 0.6, 6),
		Transparency = 1,
		CanCollide = false,
		Parent = house,
	})

	return house
end

local function createGrandmaHouse()
	local pos = GameConfig.MapPositions.GrandmaHouse
	local house = Utils.CreateModel("GrandmaHouse", mapFolder)

	Utils.CreatePart({
		Name = "Floor",
		Size = Vector3.new(14, 0.5, 14),
		Position = pos + Vector3.new(0, 0.25, 0),
		BrickColor = BrickColor.new("Nougat"),
		Material = Enum.Material.WoodPlanks,
		Parent = house,
	})

	Utils.CreatePart({
		Name = "Walls",
		Size = Vector3.new(14, 8, 14),
		Position = pos + Vector3.new(0, 4.5, 0),
		BrickColor = BrickColor.new("Nougat"),
		Material = Enum.Material.WoodPlanks,
		Transparency = 0.3,
		Parent = house,
	})

	Utils.CreatePart({
		Name = "Roof",
		Size = Vector3.new(16, 1, 16),
		Position = pos + Vector3.new(0, 9, 0),
		BrickColor = BrickColor.new("Dark stone grey"),
		Material = Enum.Material.Slate,
		Parent = house,
	})

	Utils.CreateTag(house, "GrandmaHouse")
	Utils.CreateTag(house, "TripEnd")
	Utils.CreateBillboardGui(house:FindFirstChild("Roof"), "Grandma's House", Color3.new(0.8, 0.5, 0.3))

	-- Touch detector for trip completion
	local detector = Utils.CreatePart({
		Name = "TripDetector",
		Size = Vector3.new(14, 10, 14),
		Position = pos + Vector3.new(0, 5, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = house,
	})
	Utils.CreateTag(detector, "TripEndZone")

	return house
end

local function createBearsHouse()
	local pos = GameConfig.MapPositions.BearsHouse
	local house = Utils.CreateModel("BearsHouse", mapFolder)

	-- Larger cottage for bears
	Utils.CreatePart({
		Name = "Floor",
		Size = Vector3.new(24, 0.5, 20),
		Position = pos + Vector3.new(0, 0.25, 0),
		BrickColor = BrickColor.new("Brown"),
		Material = Enum.Material.WoodPlanks,
		Parent = house,
	})

	-- Walls (semi-transparent so players can see inside)
	for _, wallData in ipairs({
		{Name = "BackWall", Size = Vector3.new(24, 10, 1), Offset = Vector3.new(0, 5.5, -10)},
		{Name = "LeftWall", Size = Vector3.new(1, 10, 20), Offset = Vector3.new(-12, 5.5, 0)},
		{Name = "RightWall", Size = Vector3.new(1, 10, 20), Offset = Vector3.new(12, 5.5, 0)},
		{Name = "FrontWallLeft", Size = Vector3.new(8, 10, 1), Offset = Vector3.new(-8, 5.5, 10)},
		{Name = "FrontWallRight", Size = Vector3.new(8, 10, 1), Offset = Vector3.new(8, 5.5, 10)},
	}) do
		Utils.CreatePart({
			Name = wallData.Name,
			Size = wallData.Size,
			Position = pos + wallData.Offset,
			BrickColor = BrickColor.new("Nougat"),
			Material = Enum.Material.WoodPlanks,
			Parent = house,
		})
	end

	Utils.CreatePart({
		Name = "Roof",
		Size = Vector3.new(26, 1, 22),
		Position = pos + Vector3.new(0, 11, 0),
		BrickColor = COLORS.Roof,
		Material = Enum.Material.Wood,
		Parent = house,
	})

	-- Three porridge bowls
	local porridgePositions = {
		{Offset = Vector3.new(-6, 1.5, -4), Label = "Papa's Porridge", Tag = "Porridge_TooHot"},
		{Offset = Vector3.new(0, 1, -4), Label = "Mama's Porridge", Tag = "Porridge_TooCold"},
		{Offset = Vector3.new(6, 0.8, -4), Label = "Baby's Porridge", Tag = "Porridge_JustRight"},
	}

	for _, data in ipairs(porridgePositions) do
		local bowl = Utils.CreatePart({
			Name = data.Tag,
			Size = Vector3.new(2, 1, 2),
			Position = pos + data.Offset,
			BrickColor = BrickColor.new("Institutional white"),
			Material = Enum.Material.SmoothPlastic,
			Shape = Enum.PartType.Cylinder,
			Parent = house,
		})
		bowl.CFrame = CFrame.new(pos + data.Offset) * CFrame.Angles(0, 0, math.rad(90))
		bowl.Size = Vector3.new(1, 2, 2)
		Utils.CreateTag(bowl, "GoldilocksItem")
		Utils.CreateTag(bowl, data.Tag)
		Utils.CreateProximityPrompt(bowl, data.Label, 0, 6)
	end

	-- Three chairs
	local chairPositions = {
		{Offset = Vector3.new(-6, 1.5, 2), Label = "Papa's Chair", Tag = "Chair_TooBig"},
		{Offset = Vector3.new(0, 1.2, 2), Label = "Mama's Chair", Tag = "Chair_TooSmall"},
		{Offset = Vector3.new(6, 1, 2), Label = "Baby's Chair", Tag = "Chair_JustRight"},
	}

	for _, data in ipairs(chairPositions) do
		local chair = Utils.CreatePart({
			Name = data.Tag,
			Size = Vector3.new(3, 3, 3),
			Position = pos + data.Offset,
			BrickColor = BrickColor.new("Brown"),
			Material = Enum.Material.Wood,
			Parent = house,
		})
		Utils.CreateTag(chair, "GoldilocksItem")
		Utils.CreateTag(chair, data.Tag)
		Utils.CreateProximityPrompt(chair, data.Label, 0, 6)
	end

	-- Three beds
	local bedPositions = {
		{Offset = Vector3.new(-6, 1, 6), Label = "Papa's Bed", Tag = "Bed_TooHard"},
		{Offset = Vector3.new(0, 0.8, 6), Label = "Mama's Bed", Tag = "Bed_TooSoft"},
		{Offset = Vector3.new(6, 0.6, 6), Label = "Baby's Bed", Tag = "Bed_JustRight"},
	}

	for _, data in ipairs(bedPositions) do
		local bed = Utils.CreatePart({
			Name = data.Tag,
			Size = Vector3.new(4, 1.5, 6),
			Position = pos + data.Offset,
			BrickColor = BrickColor.new("Bright blue"),
			Material = Enum.Material.Fabric,
			Parent = house,
		})
		Utils.CreateTag(bed, "GoldilocksItem")
		Utils.CreateTag(bed, data.Tag)
		Utils.CreateProximityPrompt(bed, data.Label, 0, 6)
	end

	-- Hide spots
	for i = 1, GameConfig.Goldilocks.HideSpotCount do
		local hideSpot = Utils.CreatePart({
			Name = "HideSpot_" .. i,
			Size = Vector3.new(3, 4, 3),
			Position = pos + Vector3.new(-10 + (i - 1) * 10, 2, -8),
			BrickColor = BrickColor.new("Brown"),
			Material = Enum.Material.Wood,
			Transparency = 0.5,
			Parent = house,
		})
		Utils.CreateTag(hideSpot, "HideSpot")
		Utils.CreateProximityPrompt(hideSpot, "Hide", 0, 6)
	end

	Utils.CreateTag(house, "BearsHouse")
	Utils.CreateBillboardGui(house:FindFirstChild("Roof"), "Bears' House", Color3.new(0.6, 0.4, 0.2))

	-- Bear patrol path markers
	local patrolPoints = {
		pos + Vector3.new(-8, 0.5, 0),
		pos + Vector3.new(8, 0.5, 0),
		pos + Vector3.new(0, 0.5, -6),
		pos + Vector3.new(0, 0.5, 6),
	}

	local patrolFolder = Instance.new("Folder")
	patrolFolder.Name = "BearPatrolPoints"
	patrolFolder.Parent = house

	for i, point in ipairs(patrolPoints) do
		local marker = Utils.CreatePart({
			Name = "PatrolPoint_" .. i,
			Size = Vector3.new(1, 1, 1),
			Position = point,
			Transparency = 1,
			CanCollide = false,
			Parent = patrolFolder,
		})
	end

	return house
end

local function createBeanstalkField()
	local pos = GameConfig.MapPositions.BeanstalkField
	local field = Utils.CreateModel("BeanstalkField", mapFolder)

	-- Field ground
	Utils.CreatePart({
		Name = "FieldGround",
		Size = Vector3.new(40, 0.5, 40),
		Position = pos + Vector3.new(0, 0.25, 0),
		BrickColor = BrickColor.new("Earth green"),
		Material = Enum.Material.Grass,
		Parent = field,
	})

	-- Beanstalk (tall climbable structure)
	local stalkHeight = 120
	local stalkSegments = 12

	for i = 1, stalkSegments do
		local segHeight = stalkHeight / stalkSegments
		local yPos = (i - 1) * segHeight + segHeight / 2
		local twist = math.sin(i * 0.8) * 3

		local stalk = Utils.CreatePart({
			Name = "BeanstalkSegment_" .. i,
			Size = Vector3.new(3, segHeight + 1, 3),
			Position = pos + Vector3.new(twist, yPos, 0),
			BrickColor = COLORS.Leaves,
			Material = Enum.Material.Grass,
			Parent = field,
		})
		Utils.CreateTag(stalk, "Climbable")

		-- Leaf platforms for climbing (every other segment)
		if i % 2 == 0 then
			local leaf = Utils.CreatePart({
				Name = "LeafPlatform_" .. i,
				Size = Vector3.new(8, 1, 6),
				Position = pos + Vector3.new(twist + (i % 4 == 0 and 5 or -5), yPos, 0),
				BrickColor = COLORS.Leaves,
				Material = Enum.Material.Grass,
				Parent = field,
			})
			Utils.CreateTag(leaf, "Climbable")
		end
	end

	-- Cloud platform at the top
	local cloudHeight = stalkHeight + 5
	local cloud = Utils.CreatePart({
		Name = "CloudPlatform",
		Size = Vector3.new(60, 3, 60),
		Position = pos + Vector3.new(0, cloudHeight, 0),
		BrickColor = BrickColor.new("White"),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.2,
		Parent = field,
	})

	-- Golden items on the cloud
	local goldenItemPositions = {
		{Offset = Vector3.new(-15, cloudHeight + 3, -10), Name = "GoldenEgg", Label = "Golden Egg"},
		{Offset = Vector3.new(15, cloudHeight + 3, -10), Name = "GoldenHarp", Label = "Golden Harp"},
		{Offset = Vector3.new(-10, cloudHeight + 3, 15), Name = "GoldenCoin1", Label = "Golden Coin"},
		{Offset = Vector3.new(10, cloudHeight + 3, 15), Name = "GoldenCoin2", Label = "Golden Coin"},
		{Offset = Vector3.new(0, cloudHeight + 3, 0), Name = "GoldenCoin3", Label = "Golden Coin"},
	}

	for _, data in ipairs(goldenItemPositions) do
		local item = Utils.CreatePart({
			Name = data.Name,
			Size = Vector3.new(3, 3, 3),
			Position = pos + data.Offset,
			BrickColor = COLORS.Gold,
			Material = Enum.Material.Neon,
			Shape = Enum.PartType.Ball,
			Parent = field,
		})
		Utils.CreateTag(item, "GoldenItem")
		Utils.CreateProximityPrompt(item, "Collect " .. data.Label, 0, 8)
	end

	-- Giant patrol area markers
	local giantPatrol = Instance.new("Folder")
	giantPatrol.Name = "GiantPatrolPoints"
	giantPatrol.Parent = field

	local giantPatrolPositions = {
		pos + Vector3.new(-20, cloudHeight + 2, -20),
		pos + Vector3.new(20, cloudHeight + 2, -20),
		pos + Vector3.new(20, cloudHeight + 2, 20),
		pos + Vector3.new(-20, cloudHeight + 2, 20),
	}

	for i, gPos in ipairs(giantPatrolPositions) do
		Utils.CreatePart({
			Name = "GiantPatrol_" .. i,
			Size = Vector3.new(1, 1, 1),
			Position = gPos,
			Transparency = 1,
			CanCollide = false,
			Parent = giantPatrol,
		})
	end

	Utils.CreateTag(field, "BeanstalkField")
	Utils.CreateBillboardGui(field:FindFirstChild("FieldGround"), "Beanstalk Field", Color3.new(0.3, 0.8, 0.3))

	return field
end

-- Create all paths connecting locations
local function createPaths()
	local positions = GameConfig.MapPositions

	-- Village to houses
	createPath(positions.VillageCenter, positions.StrawHouse, 6)
	createPath(positions.VillageCenter, positions.StickHouse, 6)
	createPath(positions.VillageCenter, positions.BrickHouse, 6)

	-- Village to forest
	createPath(positions.VillageCenter, positions.ForestPath, 6)

	-- Houses area to Bears' house
	createPath(positions.StickHouse, positions.BearsHouse, 6)

	-- Bears' house to beanstalk
	createPath(positions.BearsHouse, positions.BeanstalkField, 6)
end

-- Build the entire map
local function buildMap()
	print("[MapBuilder] Building FairyBoo map...")

	createGround()
	createVillageCenter()
	createPaths()
	createStrawHouse()
	createStickHouse()
	createBrickHouse()
	createForest()
	createRedHouse()
	createGrandmaHouse()
	createBearsHouse()
	createBeanstalkField()

	-- Add spawn location at village center
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "MainSpawn"
	spawnLocation.Size = Vector3.new(12, 1, 12)
	spawnLocation.Position = GameConfig.MapPositions.VillageCenter + Vector3.new(0, 0.5, 15)
	spawnLocation.BrickColor = COLORS.Stone
	spawnLocation.Material = Enum.Material.Cobblestone
	spawnLocation.TopSurface = Enum.SurfaceType.Smooth
	spawnLocation.Anchored = true
	spawnLocation.Parent = mapFolder

	print("[MapBuilder] Map build complete!")
end

buildMap()
