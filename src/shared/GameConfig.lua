local GameConfig = {}

-- Round settings
GameConfig.ROUND_DURATION = 300 -- 5 minutes
GameConfig.INTERMISSION_DURATION = 15
GameConfig.MIN_PLAYERS_TO_START = 1

-- Scoring
GameConfig.Scoring = {
	Wolf = {
		CatchPig = 50,
		BlowHouse = 30,
	},
	Pig = {
		RepairHouse = 20,
		PassiveInHouse = 10, -- per second while wolf is nearby
		BuildBarricade = 15,
	},
	RedRidingHood = {
		CompleteTrip = 100,
		SpeedBonusMax = 50, -- bonus for fast trips
		BasketCollectible = 15,
	},
	Goldilocks = {
		JustRightItem = 40,
	},
	Jack = {
		GoldenItem = 30,
		EscapeGiantBonus = 20,
	},
}

-- Wolf settings
GameConfig.Wolf = {
	SpeedMultiplier = 1.3,
	BlowChannelTime = 3, -- seconds to blow down a house
	PigRespawnTime = 5,
	CatchCooldown = 2,
}

-- Pig settings
GameConfig.Pig = {
	RepairChannelTime = 2,
	BarricadeHealth = 3, -- hits from wolf to destroy
	PassiveScoreRadius = 60, -- studs; wolf must be within this range
}

-- Red Riding Hood settings
GameConfig.RedRidingHood = {
	SpeedBonusTimeThreshold = 30, -- seconds for max speed bonus
	BasketSpawnInterval = 20,
	CaughtPenaltyTime = 3, -- seconds frozen when caught
}

-- Goldilocks settings
GameConfig.Goldilocks = {
	ItemSets = {"Porridge", "Chair", "Bed"},
	BearReturnInterval = 45,
	BearPatrolDuration = 15,
	HideSpotCount = 3,
	BearMoveSpeed = 12, -- studs per second for smooth movement
	BearRoamRadius = 80, -- how far bears wander from their house
	BearDetectionRadius = 10, -- catch Goldilocks within this range
	BearTouchCooldown = 3, -- seconds before same player can be penalized again
}

-- Bear definitions (sizes and colors for the family)
GameConfig.Bears = {
	{Name = "Papa Bear", Size = Vector3.new(5, 7, 4), Color = BrickColor.new("Reddish brown"), HeadSize = 2.5, TouchPenalty = 60},
	{Name = "Mama Bear", Size = Vector3.new(4, 5.5, 3), Color = BrickColor.new("Brown"), HeadSize = 2, TouchPenalty = 40},
	{Name = "Baby Bear", Size = Vector3.new(2.5, 3.5, 2), Color = BrickColor.new("Nougat"), HeadSize = 1.5, TouchPenalty = 20},
}

-- Wolf NPC settings (forest roaming wolf)
GameConfig.WolfNPC = {
	MoveSpeed = 14,
	RoamRadius = 100,
	DetectionRadius = 5,
	TouchPenalty = 75,
	TouchCooldown = 3,
}

-- Wolf NPC model definition
GameConfig.WolfNPCDef = {
	Name = "Forest Wolf",
	Size = Vector3.new(3, 2.5, 5),
	Color = BrickColor.new("Dark grey"),
	HeadSize = 1.5,
}

-- Jack settings
GameConfig.Jack = {
	GoldenItems = {"Egg", "Harp", "Coin", "Coin", "Coin"},
	ItemRespawnTime = 30,
	GiantPatrolSpeed = 16,
	GiantDetectionRadius = 25,
}

-- Flamethrower settings
GameConfig.Flamethrower = {
	PickupRadius = 8,
	NPCPickupRadius = 6,
	FlameRange = 40,
	FlameWidth = 8,
	FlameLifetime = 1.5,
	NPCSmokeTime = 30,
	NPCFireDelay = 2,
	NPCFireRange = 25,
	SpawnLocations = {
		Vector3.new(-80, 1, -45),   -- Near StrawHouse
		Vector3.new(0, 1, -65),     -- Near StickHouse
		Vector3.new(80, 1, -45),    -- Near BrickHouse
		Vector3.new(-30, 1, 80),    -- Forest area 1
		Vector3.new(30, 1, 80),     -- Forest area 2
		Vector3.new(0, 1, 120),     -- Deep forest
		Vector3.new(-120, 1, 85),   -- Near RedHouse
		Vector3.new(120, 1, 85),    -- Near GrandmaHouse
	},
}

-- Character max slots
GameConfig.MaxSlots = {
	Wolf = 1,
	Pig = 3,
	RedRidingHood = 2,
	Goldilocks = 2,
	Jack = 2,
}

-- Map positions (Vector3 offsets from origin)
GameConfig.MapPositions = {
	VillageCenter = Vector3.new(0, 0, 0),
	StrawHouse = Vector3.new(-80, 0, -60),
	StickHouse = Vector3.new(0, 0, -80),
	BrickHouse = Vector3.new(80, 0, -60),
	ForestPath = Vector3.new(0, 0, 100),
	RedHouse = Vector3.new(-120, 0, 100),
	GrandmaHouse = Vector3.new(120, 0, 100),
	BearsHouse = Vector3.new(0, 0, -160),
	BeanstalkField = Vector3.new(0, 0, -240),
}

return GameConfig
