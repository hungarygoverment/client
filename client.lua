-- LocalScript (StarterPlayerScripts / Client Engine)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- CONFIGURATION & GLOBAL STATE
------------------------------------------------------------

local Config = {
	-- Keybinds
	RunKey = Enum.KeyCode.LeftControl,
	FlyKey = Enum.KeyCode.Comma,
	AimKey = Enum.KeyCode.G,
	ClickTPKey = Enum.KeyCode.LeftAlt,

	-- Combat / Aimbot
	AimTarget = "Head",          -- "Head" or "Torso"
	AimVisibility = "Every",     -- "Every" or "Only Visible"
	AimFOV = 150,                -- Maximum pixel radius from cursor
	AimSmoothing = 1,            -- 1 = Instant Snap, lower (e.g. 0.2) = Smooth Lerp

	-- Movement
	RunMode = "Hold",            -- "Hold" or "Toggle"
	RunSpeed = 32,
	InfJump = false,
	ClickTP = false,

	-- Visuals & ESP
	ShowChams = true,
	ShowNames = true,
	ShowHealth = true,
	HighlightVisibility = "Every", -- "Every" or "Only Visible"
	HighlightColor = Color3.fromRGB(226, 183, 20), -- Default Gold
	RainbowESP = false,

	-- World / Environment
	Fullbright = false,
	RemoveFog = false,
}

local highlights = {}
local connections = {}
local highlightEnabled = false
local flying = false
local flyNoclip = false          -- Option: Phasing through walls while flying
local flySpeed = 60
local aimToggleState = false
local aiming = false
local running = false
local exited = false
local minimized = false
local sliderDragging = false

-- Color Presets
local colorPresets = {
	{ Name = "GOLD", Color = Color3.fromRGB(226, 183, 20) },
	{ Name = "CYAN", Color = Color3.fromRGB(0, 225, 255) },
	{ Name = "RED", Color = Color3.fromRGB(255, 50, 60) },
	{ Name = "GREEN", Color = Color3.fromRGB(0, 255, 120) },
	{ Name = "PURPLE", Color = Color3.fromRGB(180, 70, 255) },
	{ Name = "WHITE", Color = Color3.fromRGB(255, 255, 255) },
}
local currentColorIdx = 1

-- Independent Position Tracker for Minimize State
local savedMenuPos = UDim2.fromScale(0.5, 0.5)
local savedSquirclePos = UDim2.fromScale(0.5, 0.5)

------------------------------------------------------------
-- LIGHTING BACKUP & ENVIRONMENT MANAGERS
------------------------------------------------------------

local defaultLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
}

local originalAtmospheres = {}
for _, v in ipairs(Lighting:GetChildren()) do
	if v:IsA("Atmosphere") then
		table.insert(originalAtmospheres, v)
	end
end

local function applyFullbright()
	if Config.Fullbright then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	else
		Lighting.Brightness = defaultLighting.Brightness
		Lighting.ClockTime = defaultLighting.ClockTime
		Lighting.GlobalShadows = defaultLighting.GlobalShadows
		Lighting.Ambient = defaultLighting.Ambient
		Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
	end
end

local function applyRemoveFog()
	if Config.RemoveFog then
		Lighting.FogStart = 0
		Lighting.FogEnd = 1e6
		for _, atm in ipairs(Lighting:GetChildren()) do
			if atm:IsA("Atmosphere") then
				atm.Parent = nil
			end
		end
	else
		Lighting.FogStart = defaultLighting.FogStart
		Lighting.FogEnd = defaultLighting.FogEnd
		for _, atm in ipairs(originalAtmospheres) do
			if atm and atm.Parent == nil then
				atm.Parent = Lighting
			end
		end
	end
end

------------------------------------------------------------
-- GUI CREATION (LUXURY DARK THEME)
------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "LiquidGoldHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.fromOffset(300, 450)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(13, 13, 15)
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(226, 183, 20)
mainStroke.Transparency = 0.65
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- Dynamic FOV Circle UI
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(226, 183, 20)
fovStroke.Transparency = 0.4
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle

-- Opening Animation
TweenService:Create(
	main,
	TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	{
		Size = UDim2.fromOffset(360, 540),
		BackgroundTransparency = 0
	}
):Play()

-- Minimized Logo Squircle
local minLogo = Instance.new("ImageLabel")
minLogo.Name = "MinLogo"
minLogo.Size = UDim2.fromScale(0.65, 0.65)
minLogo.Position = UDim2.fromScale(0.5, 0.5)
minLogo.AnchorPoint = Vector2.new(0.5, 0.5)
minLogo.BackgroundTransparency = 1
minLogo.Image = "rbxassetid://83324832224423"
minLogo.ScaleType = Enum.ScaleType.Fit
minLogo.Visible = false
minLogo.Parent = main

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local brandIcon = Instance.new("Frame")
brandIcon.Size = UDim2.fromOffset(6, 24)
brandIcon.Position = UDim2.fromOffset(16, 17)
brandIcon.BackgroundColor3 = Color3.fromRGB(226, 183, 20)
brandIcon.BorderSizePixel = 0
brandIcon.Parent = header

local brandIconCorner = Instance.new("UICorner")
brandIconCorner.CornerRadius = UDim.new(1, 0)
brandIconCorner.Parent = brandIcon

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 0, 20)
title.Position = UDim2.fromOffset(30, 12)
title.BackgroundTransparency = 1
title.Text = "Premium Liquid Gold"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -90, 0, 16)
subtitle.Position = UDim2.fromOffset(30, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Script by: laszi"
subtitle.TextColor3 = Color3.fromRGB(226, 183, 20)
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(28, 28)
minBtn.Position = UDim2.new(1, -40, 0, 15)
minBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 12
minBtn.AutoButtonColor = false
minBtn.BorderSizePixel = 0
minBtn.Parent = header

local minBtnCorner = Instance.new("UICorner")
minBtnCorner.CornerRadius = UDim.new(0, 8)
minBtnCorner.Parent = minBtn

local minBtnStroke = Instance.new("UIStroke")
minBtnStroke.Color = Color3.fromRGB(40, 40, 50)
minBtnStroke.Thickness = 1
minBtnStroke.Parent = minBtn

-- Exit / Terminate Button
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.new(1, -28, 0, 38)
exitButton.Position = UDim2.new(0, 14, 1, -50)
exitButton.BackgroundColor3 = Color3.fromRGB(32, 18, 22)
exitButton.Text = "TERMINATE & UNLOAD"
exitButton.TextColor3 = Color3.fromRGB(240, 80, 90)
exitButton.Font = Enum.Font.GothamBold
exitButton.TextSize = 11
exitButton.AutoButtonColor = false
exitButton.BorderSizePixel = 0
exitButton.Parent = main

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 8)
exitCorner.Parent = exitButton

local exitStroke = Instance.new("UIStroke")
exitStroke.Color = Color3.fromRGB(70, 25, 35)
exitStroke.Thickness = 1
exitStroke.Parent = exitButton

-- Scroll Area
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -122)
scroll.Position = UDim2.fromOffset(10, 64)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(226, 183, 20)
scroll.ScrollBarImageTransparency = 0.5
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 4)
padding.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 12)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

------------------------------------------------------------
-- MINIMIZE & DRAGGING LOGIC
------------------------------------------------------------

local function toggleMinimize()
	if exited then return end
	minimized = not minimized

	if minimized then
		savedMenuPos = main.Position
		scroll.Visible = false
		header.BackgroundTransparency = 1
		headerFix.Visible = false
		brandIcon.Visible = false
		title.Visible = false
		subtitle.Visible = false
		minBtn.Visible = false
		exitButton.Visible = false

		TweenService:Create(
			main,
			TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				Size = UDim2.fromOffset(58, 58),
				Position = savedSquirclePos
			}
		):Play()

		minLogo.Visible = true
	else
		savedSquirclePos = main.Position
		minLogo.Visible = false

		local tween = TweenService:Create(
			main,
			TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				Size = UDim2.fromOffset(360, 540),
				Position = savedMenuPos
			}
		)
		tween:Play()

		task.delay(0.15, function()
			if not minimized and not exited then
				scroll.Visible = true
				header.BackgroundTransparency = 0
				headerFix.Visible = true
				brandIcon.Visible = true
				title.Visible = true
				subtitle.Visible = true
				minBtn.Visible = true
				exitButton.Visible = true
			end
		end)
	end
end

minBtn.MouseButton1Click:Connect(toggleMinimize)

local dragging = false
local dragStart, startPosition

local function startDrag(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPosition = main.Position
	end
end

header.InputBegan:Connect(function(input) if not minimized then startDrag(input) end end)
main.InputBegan:Connect(function(input) if minimized then startDrag(input) end end)

main.InputEnded:Connect(function(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and minimized then
		if (input.Position - dragStart).Magnitude < 5 then
			toggleMinimize()
		end
	end
end)

header.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

table.insert(connections, UIS.InputChanged:Connect(function(input)
	if exited then return end
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		local newPos = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + delta.X,
			startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
		)
		main.Position = newPos
		if minimized then savedSquirclePos = newPos else savedMenuPos = newPos end
	end
end))

------------------------------------------------------------
-- UI BUILDER HELPERS
------------------------------------------------------------

local function createSection(titleText)
	local section = Instance.new("Frame")
	section.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	section.BorderSizePixel = 0
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.Size = UDim2.new(1, -2, 0, 0)
	section.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = section

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(32, 32, 40)
	stroke.Thickness = 1
	stroke.Parent = section

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -20, 0, 0)
	content.Position = UDim2.fromOffset(10, 10)
	content.BackgroundTransparency = 1
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.Parent = section

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content

	local heading = Instance.new("TextLabel")
	heading.Size = UDim2.new(1, 0, 0, 18)
	heading.BackgroundTransparency = 1
	heading.Text = string.upper(titleText)
	heading.TextColor3 = Color3.fromRGB(226, 183, 20)
	heading.Font = Enum.Font.GothamBold
	heading.TextSize = 10
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.LayoutOrder = 0
	heading.Parent = content

	return content
end

local function createButton(parent, text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 32)
	button.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(210, 210, 225)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 11
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(38, 38, 48)
	stroke.Thickness = 1
	stroke.Parent = button

	button.MouseEnter:Connect(function()
		if exited then return end
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(32, 32, 42)}):Play()
	end)

	button.MouseLeave:Connect(function()
		if exited then return end
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24, 24, 30)}):Play()
	end)

	return button
end

local function createLabel(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(150, 150, 168)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	return label
end

------------------------------------------------------------
-- VISUALS & ESP MECHANICS
------------------------------------------------------------

local function getTargetPart(char)
	if not char then return nil end
	if Config.AimTarget == "Head" then
		return char:FindFirstChild("Head")
	else
		return char:FindFirstChild("UpperTorso") 
			or char:FindFirstChild("Torso") 
			or char:FindFirstChild("HumanoidRootPart")
	end
end

local function isPartVisible(part)
	if not part then return false end
	local origin = camera.CFrame.Position
	local targetPos = part.Position
	local direction = targetPos - origin

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if player.Character then
		raycastParams.FilterDescendantsInstances = {player.Character}
	end

	local result = workspace:Raycast(origin, direction, raycastParams)
	return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function checkHighlightValidity(targetPlayer)
	if targetPlayer == player or not targetPlayer.Character then return false end
	local part = getTargetPart(targetPlayer.Character)
	if not part then return false end

	if Config.HighlightVisibility == "Every" then return true end
	return isPartVisible(part)
end

local function applyESPVisibility(data)
	if not data then return end
	if data.Highlight then data.Highlight.Enabled = Config.ShowChams end

	if data.Nametag then
		local showName = Config.ShowNames
		local showHealth = Config.ShowHealth
		data.Nametag.Enabled = showName or showHealth

		if showName and showHealth then
			data.Nametag.Size = UDim2.new(0, 160, 0, 45)
			if data.NameLabel then data.NameLabel.Visible = true data.NameLabel.Position = UDim2.new(0, 0, 0, 0) end
			if data.HealthBg then data.HealthBg.Visible = true data.HealthBg.Position = UDim2.new(0, 0, 0, 22) end
		elseif showName then
			data.Nametag.Size = UDim2.new(0, 160, 0, 20)
			if data.NameLabel then data.NameLabel.Visible = true data.NameLabel.Position = UDim2.new(0, 0, 0, 0) end
			if data.HealthBg then data.HealthBg.Visible = false end
		elseif showHealth then
			data.Nametag.Size = UDim2.new(0, 160, 0, 12)
			if data.NameLabel then data.NameLabel.Visible = false end
			if data.HealthBg then data.HealthBg.Visible = true data.HealthBg.Position = UDim2.new(0, 0, 0, 0) end
		end
	end
end

local function addHighlight(targetPlayer)
	if exited or not targetPlayer.Character then return end

	if highlights[targetPlayer] then
		if highlights[targetPlayer].Conn then highlights[targetPlayer].Conn:Disconnect() end
		if highlights[targetPlayer].Highlight then highlights[targetPlayer].Highlight:Destroy() end
		if highlights[targetPlayer].Nametag then highlights[targetPlayer].Nametag:Destroy() end
	end

	local char = targetPlayer.Character
	local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")

	local h = Instance.new("Highlight")
	h.FillColor = Config.HighlightColor
	h.OutlineColor = Color3.fromRGB(255, 255, 255)
	h.FillTransparency = 0.5
	h.Adornee = char
	h.Parent = char

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_NameTag"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 160, 0, 45)
	billboard.StudsOffset = Vector3.new(0, 3.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = char

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.Parent = billboard

	local healthBg = Instance.new("Frame")
	healthBg.Size = UDim2.new(1, 0, 0, 8)
	healthBg.Position = UDim2.new(0, 0, 0, 22)
	healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = billboard

	local bgCorner = Instance.new("UICorner") bgCorner.CornerRadius = UDim.new(0, 4) bgCorner.Parent = healthBg
	local bgStroke = Instance.new("UIStroke") bgStroke.Color = Color3.fromRGB(10, 10, 15) bgStroke.Thickness = 1 bgStroke.Parent = healthBg

	local healthFill = Instance.new("Frame")
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBg

	local fillCorner = Instance.new("UICorner") fillCorner.CornerRadius = UDim.new(0, 4) fillCorner.Parent = healthFill

	local healthText = Instance.new("TextLabel")
	healthText.Size = UDim2.fromScale(1, 1)
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.TextStrokeTransparency = 0.5
	healthText.Font = Enum.Font.GothamSemibold
	healthText.TextSize = 9
	healthText.Parent = healthBg

	local function updateHealthDisplay()
		if not hum or hum.MaxHealth <= 0 then return end
		local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		healthFill.Size = UDim2.fromScale(ratio, 1)
		healthText.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)

		if ratio > 0.5 then
			healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 120):Lerp(Color3.fromRGB(255, 210, 0), (1 - ratio) * 2)
		else
			healthFill.BackgroundColor3 = Color3.fromRGB(255, 210, 0):Lerp(Color3.fromRGB(255, 50, 50), (0.5 - ratio) * 2)
		end
	end

	updateHealthDisplay()
	local healthConn = hum and hum.HealthChanged:Connect(updateHealthDisplay)

	local data = {
		Highlight = h,
		Nametag = billboard,
		NameLabel = nameLabel,
		HealthBg = healthBg,
		Conn = healthConn
	}

	highlights[targetPlayer] = data
	applyESPVisibility(data)
end

local function removeHighlights()
	for p, data in pairs(highlights) do
		if typeof(data) == "table" then
			if data.Conn then data.Conn:Disconnect() end
			if data.Highlight then data.Highlight:Destroy() end
			if data.Nametag then data.Nametag:Destroy() end
		end
		highlights[p] = nil
	end
end

local function refreshAllESPVisuals()
	for _, data in pairs(highlights) do
		if typeof(data) == "table" then applyESPVisibility(data) end
	end
end

local function updateHighlights()
	if not highlightEnabled or exited then
		removeHighlights()
		return
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			if checkHighlightValidity(p) then
				local entry = highlights[p]
				if not entry or (entry.Highlight and entry.Highlight.Parent ~= p.Character) then
					addHighlight(p)
				end
			else
				if highlights[p] then
					if highlights[p].Conn then highlights[p].Conn:Disconnect() end
					if highlights[p].Highlight then highlights[p].Highlight:Destroy() end
					if highlights[p].Nametag then highlights[p].Nametag:Destroy() end
					highlights[p] = nil
				end
			end
		end
	end
end

-- Visuals Section UI
local highlightSection = createSection("Visuals & ESP")
local highlightButton = createButton(highlightSection, "ESP Master Toggle: OFF")
local chamsButton = createButton(highlightSection, "Chams (Glow): ON")
local namesButton = createButton(highlightSection, "Name Tags: ON")
local healthBtn = createButton(highlightSection, "Health Bars: ON")
local colorPresetBtn = createButton(highlightSection, "ESP Color: GOLD")
local rainbowBtn = createButton(highlightSection, "Rainbow ESP: OFF")
local highlightVisibilityButton = createButton(highlightSection, "ESP Visibility: EVERY")

highlightButton.MouseButton1Click:Connect(function()
	if exited then return end
	highlightEnabled = not highlightEnabled
	highlightButton.Text = highlightEnabled and "ESP Master Toggle: ON" or "ESP Master Toggle: OFF"
	highlightButton.TextColor3 = highlightEnabled and Color3.fromRGB(226, 183, 20) or Color3.fromRGB(210, 210, 225)
	if not highlightEnabled then removeHighlights() end
end)

chamsButton.MouseButton1Click:Connect(function()
	if exited then return end
	Config.ShowChams = not Config.ShowChams
	chamsButton.Text = Config.ShowChams and "Chams (Glow): ON" or "Chams (Glow): OFF"
	refreshAllESPVisuals()
end)

namesButton.MouseButton1Click:Connect(function()
	if exited then return end
	Config.ShowNames = not Config.ShowNames
	namesButton.Text = Config.ShowNames and "Name Tags: ON" or "Name Tags: OFF"
	refreshAllESPVisuals()
end)

healthBtn.MouseButton1Click:Connect(function()
	if exited then return end
	Config.ShowHealth = not Config.ShowHealth
	healthBtn.Text = Config.ShowHealth and "Health Bars: ON" or "Health Bars: OFF"
	refreshAllESPVisuals()
end)

colorPresetBtn.MouseButton1Click:Connect(function()
	if exited or Config.RainbowESP then return end
	currentColorIdx = (currentColorIdx % #colorPresets) + 1
	local preset = colorPresets[currentColorIdx]
	Config.HighlightColor = preset.Color
	colorPresetBtn.Text = "ESP Color: " .. preset.Name
end)

rainbowBtn.MouseButton1Click:Connect(function()
	if exited then return end
	Config.RainbowESP = not Config.RainbowESP
	rainbowBtn.Text = Config.RainbowESP and "Rainbow ESP: ON" or "Rainbow ESP: OFF"
	rainbowBtn.TextColor3 = Config.RainbowESP and Color3.fromRGB(226, 183, 20) or Color3.fromRGB(210, 210, 225)
end)

highlightVisibilityButton.MouseButton1Click:Connect(function()
	if exited then return end
	Config.HighlightVisibility = Config.HighlightVisibility == "Every" and "Only Visible" or "Every"
	highlightVisibilityButton.Text = "ESP Visibility: " .. string.upper(Config.HighlightVisibility)
end)

------------------------------------------------------------
-- COMBAT & AIMBOT
------------------------------------------------------------

local function checkAimTargetValidity(targetPlayer)
	if targetPlayer == player or not targetPlayer.Character then return false, nil, 0 end
	local part = getTargetPart(targetPlayer.Character)
	if not part then return false, nil, 0 end

	local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
	if not onScreen then return false, nil, 0 end

	local mousePos = UIS:GetMouseLocation()
	local cursorDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

	if cursorDist > Config.AimFOV then return false, nil, 0 end
	if Config.AimVisibility == "Only Visible" and not isPartVisible(part) then return false, nil, 0 end

	return true, part, cursorDist
end

local function getClosestTargetToCursor()
	local closestPlayer = nil
	local bestScore = math.huge
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	for _, p in ipairs(Players:GetPlayers()) do
		local valid, part, cursorDist = checkAimTargetValidity(p)
		if valid then
			local worldDist = (root.Position - part.Position).Magnitude
			local score = cursorDist + (worldDist * 0.25)
			if score < bestScore then
				bestScore = score
				closestPlayer = p
			end
		end
	end

	return closestPlayer
end

local aimSection = createSection("Combat & Aimbot")
local aimKeyLabel = createLabel(aimSection, "Aim Toggle Key: [" .. Config.AimKey.Name .. "]")
local aimKeyButton = createButton(aimSection, "Change Aim Key")
local aimTargetButton = createButton(aimSection, "Aim Target: HEAD")
local aimVisibilityButton = createButton(aimSection, "Aim Visibility: EVERY")
local aimStatus = createButton(aimSection, "Aim Lock System: OFF")

local function updateAimUI()
	aimStatus.Text = aimToggleState and "Aim Lock System: ON" or "Aim Lock System: OFF"
	aimStatus.TextColor3 = aimToggleState and Color3.fromRGB(226, 183, 20) or Color3.fromRGB(210, 210, 225)
	fovCircle.Visible = aimToggleState
end

aimStatus.MouseButton1Click:Connect(function()
	if exited then return end
	aimToggleState = not aimToggleState
	aiming = aimToggleState and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	updateAimUI()
end)

aimKeyButton.MouseButton1Click:Connect(function()
	if exited then return end
	aimKeyButton.Text = "Press a key..."
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if exited then conn:Disconnect() return end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			Config.AimKey = input.KeyCode
			aimKeyLabel.Text = "Aim Toggle Key: [" .. Config.AimKey.Name .. "]"
			aimKeyButton.Text = "Change Aim Key"
			conn:Disconnect()
		end
	end)
end)

aimTargetButton.MouseButton1Click:Connect(function()
	if exited then return end
	Config.AimTarget = Config.AimTarget == "Head" and "Torso" or "Head"
	aimTargetButton.Text = "Aim Target: " .. string.upper(Config.AimTarget)
end)

aimVisibilityButton.MouseButton1Click:Connect(function()
	if exited then return end
	Config.AimVisibility = Config.AimVisibility == "Every" and "Only Visible" or "Every"
	aimVisibilityButton.Text = "Aim Visibility: " .. string.upper(Config.AimVisibility)
end)

------------------------------------------------------------
-- MOVEMENT & SPEED SLIDER
------------------------------------------------------------

local runSection = createSection("Movement & Speed")
local runKeyLabel = createLabel(runSection, "Run Keybind: [" .. Config.RunKey.Name .. "]")
local runKeyButton = createButton(runSection, "Change Run Key")
local runModeButton = createButton(runSection, "Run Mode: " .. string.upper(Config.RunMode))
local speedLabel = createLabel(runSection, "Run Speed: " .. Config.RunSpeed)

local sliderContainer = Instance.new("Frame")
sliderContainer.Size = UDim2.new(1, 0, 0, 16)
sliderContainer.BackgroundTransparency = 1
sliderContainer.Parent = runSection

local slider = Instance.new("Frame")
slider.Size = UDim2.new(1, 0, 0, 6)
slider.Position = UDim2.new(0, 0, 0.5, -3)
slider.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
slider.BorderSizePixel = 0
slider.Parent = sliderContainer

local sliderCorner = Instance.new("UICorner") sliderCorner.CornerRadius = UDim.new(1, 0) sliderCorner.Parent = slider

local fill = Instance.new("Frame")
fill.Size = UDim2.new(Config.RunSpeed / 100, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(226, 183, 20)
fill.BorderSizePixel = 0
fill.Parent = slider

local fillCorner = Instance.new("UICorner") fillCorner.CornerRadius = UDim.new(1, 0) fillCorner.Parent = fill

local thumb = Instance.new("Frame")
thumb.Size = UDim2.fromOffset(14, 14)
thumb.Position = UDim2.new(1, 0, 0.5, 0)
thumb.AnchorPoint = Vector2.new(0.5, 0.5)
thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
thumb.BorderSizePixel = 0
thumb.Parent = fill

local thumbCorner = Instance.new("UICorner") thumbCorner.CornerRadius = UDim.new(1, 0) thumbCorner.Parent = thumb

local function updateSlider(x)
	local relative = math.clamp((x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
	Config.RunSpeed = math.max(1, math.floor(relative * 100))
	fill.Size = UDim2.new(Config.RunSpeed / 100, 0, 1, 0)
	speedLabel.Text = "Run Speed: " .. Config.RunSpeed

	if running then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = Config.RunSpeed end
	end
end

table.insert(connections, sliderContainer.InputBegan:Connect(function(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliderDragging = true
		updateSlider(input.Position.X)
	end
end))

table.insert(connections, UIS.InputChanged:Connect(function(input)
	if exited then return end
	if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		updateSlider(input.Position.X)
	end
end))

table.insert(connections, UIS.InputEnded:Connect(function(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = false end
end))

runKeyButton.MouseButton1Click:Connect(function()
	if exited then return end
	runKeyButton.Text = "Press a key..."
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if exited then conn:Disconnect() return end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			Config.RunKey = input.KeyCode
			runKeyLabel.Text = "Run Keybind: [" .. Config.RunKey.Name .. "]"
			runKeyButton.Text = "Change Run Key"
			conn:Disconnect()
		end
	end)
end)

runModeButton.MouseButton1Click:Connect(function()
	if exited then return end
	Config.RunMode = Config.RunMode == "Hold" and "Toggle" or "Hold"
	runModeButton.Text = "Run Mode: " .. string.upper(Config.RunMode)
end)

local infJumpBtn = createButton(runSection, "Infinite Jump: OFF")
local clickTpBtn = createButton(runSection, "Click TP (Alt+LClick): OFF")

infJumpBtn.MouseButton1Click:Connect(function()
	if exited then return end
	Config.InfJump = not Config.InfJump
	infJumpBtn.Text = Config.InfJump and "Infinite Jump: ON" or "Infinite Jump: OFF"
	infJumpBtn.TextColor3 = Config.InfJump and Color3.fromRGB(226, 183, 20) or Color3.fromRGB(210, 210, 225)
end)

clickTpBtn.MouseButton1Click:Connect(function()
	if exited then return end
	Config.ClickTP = not Config.ClickTP
	clickTpBtn.Text = Config.ClickTP and "Click TP (Alt+LClick): ON" or "Click TP (Alt+LClick): OFF"
	clickTpBtn.TextColor3 = Config.ClickTP and Color3.fromRGB(226, 183, 20) or Color3.fromRGB(210, 210, 225)
end)

-- Infinite Jump Request
table.insert(connections, UIS.JumpRequest:Connect(function()
	if Config.InfJump and not exited then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end))

------------------------------------------------------------
-- FLIGHT & NOCLIP ENGINE
------------------------------------------------------------

local flySection = createSection("Flight Capabilities")
local flyKeyLabel = createLabel(flySection, "Fly Keybind: [" .. Config.FlyKey.Name .. "]")
local flyKeyButton = createButton(flySection, "Change Fly Key")
local flyStatus = createButton(flySection, "Flight System: OFF")
local noclipButton = createButton(flySection, "Fly Noclip: OFF")
local flyConnection = nil

local function resetCollisions()
	local char = player.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = true end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

local function stopFly()
	flying = false
	flyStatus.Text = "Flight System: OFF"
	flyStatus.TextColor3 = Color3.fromRGB(210, 210, 225)

	if flyConnection then flyConnection:Disconnect() flyConnection = nil end

	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if root then
			for _, obj in ipairs(root:GetChildren()) do
				if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then obj:Destroy() end
			end
		end
		if hum then hum.PlatformStand = false end
	end
	resetCollisions()
end

local function startFly()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	flying = true
	flyStatus.Text = "Flight System: ON"
	flyStatus.TextColor3 = Color3.fromRGB(226, 183, 20)
	hum.PlatformStand = true

	local bv = Instance.new("BodyVelocity")
	bv.Name = "FlyVelocity"
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.zero
	bv.Parent = root

	local bg = Instance.new("BodyGyro")
	bg.Name = "FlyGyro"
	bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bg.CFrame = root.CFrame
	bg.Parent = root

	flyConnection = RS.Stepped:Connect(function()
		if not flying or exited or not root.Parent then stopFly() return end

		-- Noclip applied strictly when active during flight
		if flyNoclip and player.Character then
			for _, part in ipairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end

		local move = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
		if UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end

		if move.Magnitude > 0 then move = move.Unit * flySpeed end
		bv.Velocity = move
		bg.CFrame = camera.CFrame
	end)
end

local function toggleFly()
	if flying then stopFly() else startFly() end
end

flyStatus.MouseButton1Click:Connect(function() if not exited then toggleFly() end end)

noclipButton.MouseButton1Click:Connect(function()
	if exited then return end
	flyNoclip = not flyNoclip
	noclipButton.Text = flyNoclip and "Fly Noclip: ON" or "Fly Noclip: OFF"
	noclipButton.TextColor3 = flyNoclip and Color3.fromRGB(226, 183, 20) or Color3.fromRGB(210, 210, 225)
	
	-- Restore collisions immediately if Noclip is turned off mid-flight
	if not flyNoclip and flying then
		resetCollisions()
	end
end)

flyKeyButton.MouseButton1Click:Connect(function()
	if exited then return end
	flyKeyButton.Text = "Press a key..."
	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if exited then conn:Disconnect() return end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			Config.FlyKey = input.KeyCode
			flyKeyLabel.Text = "Fly Keybind: [" .. Config.FlyKey.Name .. "]"
			flyKeyButton.Text = "Change Fly Key"
			conn:Disconnect()
		end
	end)
end)

------------------------------------------------------------
-- WORLD & ENVIRONMENT
------------------------------------------------------------

local worldSection = createSection("World & Environment")
local fullbrightBtn = createButton(worldSection, "Fullbright: OFF")
local noFogBtn = createButton(worldSection, "Remove Fog: OFF")

fullbrightBtn.MouseButton1Click:Connect(function()
	if exited then return end
	Config.Fullbright = not Config.Fullbright
	fullbrightBtn.Text = Config.Fullbright and "Fullbright: ON" or "Fullbright: OFF"
	fullbrightBtn.TextColor3 = Config.Fullbright and Color3.fromRGB(226, 183, 20) or Color3.fromRGB(210, 210, 225)
	applyFullbright()
end)

noFogBtn.MouseButton1Click:Connect(function()
	if exited then return end
	Config.RemoveFog = not Config.RemoveFog
	noFogBtn.Text = Config.RemoveFog and "Remove Fog: ON" or "Remove Fog: OFF"
	noFogBtn.TextColor3 = Config.RemoveFog and Color3.fromRGB(226, 183, 20) or Color3.fromRGB(210, 210, 225)
	applyRemoveFog()
end)

------------------------------------------------------------
-- INPUT CONTROLLERS
------------------------------------------------------------

table.insert(connections, UIS.InputBegan:Connect(function(input, gpe)
	if exited then return end

	-- Click Teleport Activation
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if Config.ClickTP and UIS:IsKeyDown(Config.ClickTPKey) then
			local mouse = player:GetMouse()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and mouse.Hit then
				root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3.5, 0))
			end
		end
	end

	if gpe then return end

	-- Fly Key
	if input.KeyCode == Config.FlyKey then toggleFly() return end

	-- Aim Key
	if input.KeyCode == Config.AimKey then
		aimToggleState = not aimToggleState
		aiming = aimToggleState and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		updateAimUI()
		return
	end

	-- RMB Aim
	if input.UserInputType == Enum.UserInputType.MouseButton2 and aimToggleState then
		aiming = true
		return
	end

	-- Speed Run
	if input.KeyCode == Config.RunKey then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if Config.RunMode == "Hold" then
			running = true
			if hum then hum.WalkSpeed = Config.RunSpeed end
		else
			running = not running
			if hum then hum.WalkSpeed = running and Config.RunSpeed or 16 end
		end
	end
end))

table.insert(connections, UIS.InputEnded:Connect(function(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end
	if input.KeyCode == Config.RunKey and Config.RunMode == "Hold" then
		running = false
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 16 end
	end
end))

------------------------------------------------------------
-- MAIN RENDER TICK LOOP
------------------------------------------------------------

local hue = 0

table.insert(connections, RS.RenderStepped:Connect(function(dt)
	if exited then return end

	-- Rainbow Spectrum Cycle
	if Config.RainbowESP then
		hue = (hue + (dt * 0.2)) % 1
		Config.HighlightColor = Color3.fromHSV(hue, 1, 1)
	end

	-- Dynamically Update Highlight Colors
	for _, data in pairs(highlights) do
		if typeof(data) == "table" and data.Highlight then
			data.Highlight.FillColor = Config.HighlightColor
		end
	end

	-- Update ESP Positions
	updateHighlights()

	-- FOV Circle Follow
	if fovCircle and aimToggleState then
		local mousePos = UIS:GetMouseLocation()
		fovCircle.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
	end

	-- Aimbot Camera Lock
	if aimToggleState and aiming then
		local target = getClosestTargetToCursor()
		if target and target.Character then
			local part = getTargetPart(target.Character)
			if part then
				local targetCFrame = CFrame.lookAt(camera.CFrame.Position, part.Position)
				if Config.AimSmoothing >= 1 then
					camera.CFrame = targetCFrame
				else
					camera.CFrame = camera.CFrame:Lerp(targetCFrame, Config.AimSmoothing)
				end
			end
		end
	end
end))

------------------------------------------------------------
-- RESPAWN HANDLER
------------------------------------------------------------

table.insert(connections, player.CharacterAdded:Connect(function(newChar)
	task.wait(0.2)
	local hum = newChar:WaitForChild("Humanoid", 3)
	if hum and running then
		hum.WalkSpeed = Config.RunSpeed
	end
end))

------------------------------------------------------------
-- TERMINATE & UNLOAD CLEANUP LOGIC
------------------------------------------------------------

exitButton.MouseButton1Click:Connect(function()
	if exited then return end
	exited = true

	-- Disconnect Event Handlers
	for _, conn in ipairs(connections) do
		if conn then conn:Disconnect() end
	end

	-- Restore Game / Character States
	stopFly()
	removeHighlights()
	Config.Fullbright = false
	Config.RemoveFog = false
	applyFullbright()
	applyRemoveFog()

	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 16 end

	-- Animate UI Exit and Destroy
	local exitTween = TweenService:Create(
		main,
		TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		{
			Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1
		}
	)
	exitTween:Play()
	exitTween.Completed:Connect(function()
		gui:Destroy()
	end)
end)
