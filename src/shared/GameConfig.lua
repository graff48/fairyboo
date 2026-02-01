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
}

-- Bear definitions (sizes and colors for the family)
GameConfig.Bears = {
	{Name = "Papa Bear", Size = Vector3.new(5, 7, 4), Color = BrickColor.new("Reddish brown"), HeadSize = 2.5},
	{Name = "Mama Bear", Size = Vector3.new(4, 5.5, 3), Color = BrickColor.new("Brown"), HeadSize = 2},
	{Name = "Baby Bear", Size = Vector3.new(2.5, 3.5, 2), Color = BrickColor.new("Nougat"), HeadSize = 1.5},
}

-- Jack settings
GameConfig.Jack = {
	GoldenItems = {"Egg", "Harp", "Coin", "Coin", "Coin"},
	ItemRespawnTime = 30,
	GiantPatrolSpeed = 16,
	GiantDetectionRadius = 25,
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
