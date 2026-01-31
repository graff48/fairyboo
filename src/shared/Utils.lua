local Utils = {}

function Utils.CreatePart(properties)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	for key, value in pairs(properties or {}) do
		part[key] = value
	end

	return part
end

function Utils.CreateModel(name, parent)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Utils.WeldParts(part1, part2)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part1
	weld.Part1 = part2
	weld.Parent = part1
	return weld
end

function Utils.DistanceBetween(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

function Utils.CreateBillboardGui(parent, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 200, 0, 50)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	gui.Parent = parent
	return gui
end

function Utils.CreateTag(instance, tagName)
	local tag = Instance.new("BoolValue")
	tag.Name = tagName
	tag.Value = true
	tag.Parent = instance
	return tag
end

function Utils.HasTag(instance, tagName)
	local tag = instance:FindFirstChild(tagName)
	return tag ~= nil and tag.Value == true
end

function Utils.FormatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

function Utils.CreateProximityPrompt(parent, actionText, holdDuration, maxDistance)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText or "Interact"
	prompt.HoldDuration = holdDuration or 0
	prompt.MaxActivationDistance = maxDistance or 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

return Utils
