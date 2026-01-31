local CharacterData = {}

CharacterData.Characters = {
	Wolf = {
		DisplayName = "Big Bad Wolf",
		Description = "Catch pigs and blow down houses!",
		Color = BrickColor.new("Dark stone grey"),
		WalkSpeed = 20, -- faster than default 16
		Abilities = {
			{Name = "Huff and Puff", Key = "E", Type = "Channel", Duration = 3},
		},
	},
	Pig = {
		DisplayName = "Three Little Pigs",
		Description = "Build houses and survive the wolf!",
		Color = BrickColor.new("Pink"),
		WalkSpeed = 16,
		Abilities = {
			{Name = "Repair", Key = "E", Type = "Channel", Duration = 2},
			{Name = "Barricade", Key = "F", Type = "Instant", Cooldown = 10},
		},
	},
	RedRidingHood = {
		DisplayName = "Little Red Riding Hood",
		Description = "Deliver goodies to Grandma through the forest!",
		Color = BrickColor.new("Bright red"),
		WalkSpeed = 16,
		Abilities = {},
	},
	Goldilocks = {
		DisplayName = "Goldilocks",
		Description = "Find the 'just right' items in the Bears' house!",
		Color = BrickColor.new("Bright yellow"),
		WalkSpeed = 16,
		Abilities = {
			{Name = "Interact", Key = "E", Type = "Instant", Cooldown = 1},
			{Name = "Hide", Key = "F", Type = "Instant", Cooldown = 5},
		},
	},
	Jack = {
		DisplayName = "Jack",
		Description = "Climb the beanstalk and steal golden treasures!",
		Color = BrickColor.new("Bright green"),
		WalkSpeed = 16,
		Abilities = {
			{Name = "Climb", Key = "E", Type = "Toggle"},
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
