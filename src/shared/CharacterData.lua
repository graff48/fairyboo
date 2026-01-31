local CharacterData = {}

CharacterData.Characters = {
	Wolf = {
		DisplayName = "Big Bad Wolf",
		Description = "Catch pigs and blow down houses!",
		Color = BrickColor.new("Dark stone grey"),
		BodyColor = Color3.fromRGB(90, 90, 90),
		WalkSpeed = 20, -- faster than default 16
		Abilities = {
			{Name = "Huff and Puff", Key = "E", Type = "Channel", Duration = 3},
		},
		Accessories = {
			{ -- Left ear
				Name = "WolfEarL",
				Size = Vector3.new(0.4, 0.7, 0.3),
				Offset = CFrame.new(-0.45, 0.85, 0),
				Color = Color3.fromRGB(70, 70, 70),
			},
			{ -- Right ear
				Name = "WolfEarR",
				Size = Vector3.new(0.4, 0.7, 0.3),
				Offset = CFrame.new(0.45, 0.85, 0),
				Color = Color3.fromRGB(70, 70, 70),
			},
		},
	},
	Pig = {
		DisplayName = "Three Little Pigs",
		Description = "Build houses and survive the wolf!",
		Color = BrickColor.new("Pink"),
		BodyColor = Color3.fromRGB(255, 182, 193),
		WalkSpeed = 16,
		Abilities = {
			{Name = "Repair", Key = "E", Type = "Channel", Duration = 2},
			{Name = "Barricade", Key = "F", Type = "Instant", Cooldown = 10},
		},
		Accessories = {
			{ -- Pig nose
				Name = "PigNose",
				Size = Vector3.new(0.5, 0.35, 0.3),
				Offset = CFrame.new(0, -0.1, -0.75),
				Color = Color3.fromRGB(255, 140, 160),
				Shape = Enum.PartType.Cylinder,
			},
			{ -- Left ear
				Name = "PigEarL",
				Size = Vector3.new(0.45, 0.4, 0.15),
				Offset = CFrame.new(-0.4, 0.7, 0.1),
				Color = Color3.fromRGB(255, 150, 170),
			},
			{ -- Right ear
				Name = "PigEarR",
				Size = Vector3.new(0.45, 0.4, 0.15),
				Offset = CFrame.new(0.4, 0.7, 0.1),
				Color = Color3.fromRGB(255, 150, 170),
			},
		},
	},
	RedRidingHood = {
		DisplayName = "Little Red Riding Hood",
		Description = "Deliver goodies to Grandma through the forest!",
		Color = BrickColor.new("Bright red"),
		BodyColor = Color3.fromRGB(200, 40, 40),
		WalkSpeed = 16,
		Abilities = {},
		Accessories = {
			{ -- Hood
				Name = "Hood",
				Size = Vector3.new(1.4, 0.8, 1.4),
				Offset = CFrame.new(0, 0.55, 0.1),
				Color = Color3.fromRGB(180, 20, 20),
			},
			{ -- Hood drape (back)
				Name = "HoodDrape",
				Size = Vector3.new(1.2, 1.0, 0.25),
				Offset = CFrame.new(0, -0.1, 0.7),
				Color = Color3.fromRGB(170, 15, 15),
			},
		},
	},
	Goldilocks = {
		DisplayName = "Goldilocks",
		Description = "Find the 'just right' items in the Bears' house!",
		Color = BrickColor.new("Bright yellow"),
		BodyColor = Color3.fromRGB(245, 220, 130),
		WalkSpeed = 16,
		Abilities = {
			{Name = "Interact", Key = "E", Type = "Instant", Cooldown = 1},
			{Name = "Hide", Key = "F", Type = "Instant", Cooldown = 5},
		},
		Accessories = {
			{ -- Left curl
				Name = "CurlL",
				Size = Vector3.new(0.35, 0.9, 0.5),
				Offset = CFrame.new(-0.65, 0.0, 0),
				Color = Color3.fromRGB(240, 200, 50),
				Shape = Enum.PartType.Cylinder,
			},
			{ -- Right curl
				Name = "CurlR",
				Size = Vector3.new(0.35, 0.9, 0.5),
				Offset = CFrame.new(0.65, 0.0, 0),
				Color = Color3.fromRGB(240, 200, 50),
				Shape = Enum.PartType.Cylinder,
			},
			{ -- Top hair
				Name = "HairTop",
				Size = Vector3.new(1.15, 0.3, 1.15),
				Offset = CFrame.new(0, 0.7, 0),
				Color = Color3.fromRGB(240, 200, 50),
			},
		},
	},
	Jack = {
		DisplayName = "Jack",
		Description = "Climb the beanstalk and steal golden treasures!",
		Color = BrickColor.new("Bright green"),
		BodyColor = Color3.fromRGB(80, 160, 60),
		WalkSpeed = 16,
		Abilities = {
			{Name = "Climb", Key = "E", Type = "Toggle"},
		},
		Accessories = {
			{ -- Cap
				Name = "Cap",
				Size = Vector3.new(1.1, 0.35, 1.1),
				Offset = CFrame.new(0, 0.65, 0),
				Color = Color3.fromRGB(60, 130, 40),
			},
			{ -- Cap brim
				Name = "CapBrim",
				Size = Vector3.new(1.3, 0.1, 0.6),
				Offset = CFrame.new(0, 0.5, -0.45),
				Color = Color3.fromRGB(50, 120, 35),
			},
		},
	},
}

function CharacterData.GetCharacter(name)
	return CharacterData.Characters[name]
end

function CharacterData.GetAllNames()
	local names = {}
	for name in pairs(CharacterData.Characters) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return CharacterData
