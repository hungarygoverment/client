-- LocalScript (StarterPlayerScripts)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- STATE & CONFIG
------------------------------------------------------------

local Config = {
	RunKey = Enum.KeyCode.LeftControl,
	FlyKey = Enum.KeyCode.F,
	AimKey = Enum.KeyCode.G,

	RunMode = "Hold", -- "Hold" or "Toggle"
	RunSpeed = 16,
	AimTarget = "Head", -- "Head" or "Torso"
	AimVisibility = "Every", -- "Every" or "Only Visible"
	AimFOV = 150, -- Maximum pixel distance from cursor for Aim ONLY

	-- ESP Toggles
	ShowChams = true,
	ShowNames = true,
	ShowHealth = true,
	HighlightVisibility = "Every", -- "Every" or "Only Visible"
}

local highlights = {}
local highlightEnabled = false
local flying = false
local flySpeed = 60
local aimToggleState = false -- Master switch toggle (Aim Key)
local aiming = false         -- Active aim locking state (Right Click)
local running = false
local exited = false
local minimized = false

-- INDEPENDENT POSITIONS
local savedMenuPos = UDim2.fromScale(0.5, 0.5)      -- Default center for full menu
local savedSquirclePos = UDim2.fromScale(0.5, 0.5)  -- Default position for minimized icon

------------------------------------------------------------
-- GUI CREATION (REDESIGNED LUXURY DARK THEME)
------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "LiquidGoldUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.fromOffset(360, 540)
main.Position = savedMenuPos
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(13, 13, 15)
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

------------------------------------------------------------
-- MINIMIZED SQUIRCLE IMAGE LOGO
------------------------------------------------------------

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

------------------------------------------------------------
-- HEADER & DRAGGING
------------------------------------------------------------

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
title.Text = "LIQUID GOLD"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -90, 0, 16)
subtitle.Position = UDim2.fromOffset(30, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "PREMIUM UTILITY PANEL"
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

minBtn.MouseEnter:Connect(function()
	if exited or minimized then return end
	TweenService:Create(minBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

minBtn.MouseLeave:Connect(function()
	if exited or minimized then return end
	TweenService:Create(minBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 32), TextColor3 = Color3.fromRGB(160, 160, 180)}):Play()
end)

------------------------------------------------------------
-- PINNED EXIT BUTTON (FOOTER)
------------------------------------------------------------

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

exitButton.MouseEnter:Connect(function()
	if exited or minimized then return end
	TweenService:Create(exitButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 22, 28), TextColor3 = Color3.fromRGB(255, 110, 120)}):Play()
end)

exitButton.MouseLeave:Connect(function()
	if exited or minimized then return end
	TweenService:Create(exitButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(32, 18, 22), TextColor3 = Color3.fromRGB(240, 80, 90)}):Play()
end)

------------------------------------------------------------
-- SCROLL AREA & HELPERS
------------------------------------------------------------

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
-- MINIMIZE / EXPAND LOGIC
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

------------------------------------------------------------
-- DRAGGING LOGIC
------------------------------------------------------------

local dragging = false
local dragStart
local startPosition

local function startDrag(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPosition = main.Position
	end
end

header.InputBegan:Connect(function(input)
	if not minimized then startDrag(input) end
end)

main.InputBegan:Connect(function(input)
	if minimized then startDrag(input) end
end)

main.InputEnded:Connect(function(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and minimized then
		local delta = (input.Position - dragStart).Magnitude
		if delta < 5 then
			toggleMinimize()
		end
	end
end)

header.InputEnded:Connect(function(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if exited then return end
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		local newPos = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
		main.Position = newPos

		if minimized then
			savedSquirclePos = newPos
		else
			savedMenuPos = newPos
		end
	end
end)

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
-- VISIBILITY HELPERS
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

	local ignoreList = {}
	if player.Character then
		table.insert(ignoreList, player.Character)
	end
	raycastParams.FilterDescendantsInstances = ignoreList

	local result = workspace:Raycast(origin, direction, raycastParams)

	if result then
		return result.Instance:IsDescendantOf(part.Parent)
	end

	return true
end

------------------------------------------------------------
-- HIGHLIGHT, NAMETAG & HEALTHBAR MECHANICS
------------------------------------------------------------

local function checkHighlightValidity(targetPlayer)
	if targetPlayer == player or not targetPlayer.Character then 
		return false 
	end

	local part = getTargetPart(targetPlayer.Character)
	if not part then 
		return false 
	end

	if Config.HighlightVisibility == "Every" then
		return true
	end

	return isPartVisible(part)
end

local function applyESPVisibility(data)
	if not data then return end

	-- Chams (Outline Highlight) Toggle
	if data.Highlight then
		data.Highlight.Enabled = Config.ShowChams
	end

	-- Billboard Tags Toggles & Dynamic Sizing
	if data.Nametag then
		local showName = Config.ShowNames
		local showHealth = Config.ShowHealth

		data.Nametag.Enabled = showName or showHealth

		if showName and showHealth then
			data.Nametag.Size = UDim2.new(0, 160, 0, 45)
			if data.NameLabel then 
				data.NameLabel.Visible = true 
				data.NameLabel.Position = UDim2.new(0, 0, 0, 0)
			end
			if data.HealthBg then 
				data.HealthBg.Visible = true 
				data.HealthBg.Position = UDim2.new(0, 0, 0, 22)
			end
		elseif showName then
			data.Nametag.Size = UDim2.new(0, 160, 0, 20)
			if data.NameLabel then 
				data.NameLabel.Visible = true 
				data.NameLabel.Position = UDim2.new(0, 0, 0, 0)
			end
			if data.HealthBg then data.HealthBg.Visible = false end
		elseif showHealth then
			data.Nametag.Size = UDim2.new(0, 160, 0, 12)
			if data.NameLabel then data.NameLabel.Visible = false end
			if data.HealthBg then 
				data.HealthBg.Visible = true 
				data.HealthBg.Position = UDim2.new(0, 0, 0, 0)
			end
		end
	end
end

local function addHighlight(targetPlayer)
	if exited or not targetPlayer.Character then return end

	-- Clean up existing instances if present
	if highlights[targetPlayer] then
		if highlights[targetPlayer].Conn then highlights[targetPlayer].Conn:Disconnect() end
		if highlights[targetPlayer].Highlight then highlights[targetPlayer].Highlight:Destroy() end
		if highlights[targetPlayer].Nametag then highlights[targetPlayer].Nametag:Destroy() end
	end

	local char = targetPlayer.Character
	local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")

	-- Highlight Object
	local h = Instance.new("Highlight")
	h.FillColor = Color3.fromRGB(226, 183, 20)
	h.OutlineColor = Color3.fromRGB(255, 255, 255)
	h.FillTransparency = 0.5
	h.Adornee = char
	h.Parent = char

	-- BillboardGui Container
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_NameTag"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 160, 0, 45)
	billboard.StudsOffset = Vector3.new(0, 3.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = char

	-- Name Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.Parent = billboard

	-- Health Bar Background
	local healthBg = Instance.new("Frame")
	healthBg.Size = UDim2.new(1, 0, 0, 8)
	healthBg.Position = UDim2.new(0, 0, 0, 22)
	healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = billboard

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 4)
	bgCorner.Parent = healthBg

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = Color3.fromRGB(10, 10, 15)
	bgStroke.Thickness = 1
	bgStroke.Parent = healthBg

	-- Active Health Fill Bar
	local healthFill = Instance.new("Frame")
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = healthFill

	-- Health Text Readout
	local healthText = Instance.new("TextLabel")
	healthText.Size = UDim2.fromScale(1, 1)
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.TextStrokeTransparency = 0.5
	healthText.Font = Enum.Font.GothamSemibold
	healthText.TextSize = 9
	healthText.Parent = healthBg

	-- Dynamic Health Updates
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
	local healthConn = nil
	if hum then
		healthConn = hum.HealthChanged:Connect(updateHealthDisplay)
	end

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
		if typeof(data) == "table" then
			applyESPVisibility(data)
		end
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

------------------------------------------------------------
-- HIGHLIGHT SECTION UI & BUTTONS
------------------------------------------------------------

local highlightSection = createSection("Visuals & ESP")
local highlightButton = createButton(highlightSection, "ESP Master Toggle: OFF")
local chamsButton = createButton(highlightSection, "Chams (Glow): ON")
local namesButton = createButton(highlightSection, "Name Tags: ON")
local healthBtn = createButton(highlightSection, "Health Bars: ON")
local highlightVisibilityButton = createButton(highlightSection, "ESP Visibility: EVERY")

-- Main Master ESP Toggle
highlightButton.MouseButton1Click:Connect(function()
	if exited then return end
	highlightEnabled = not highlightEnabled

	if highlightEnabled then
		highlightButton.Text = "ESP Master Toggle: ON"
		highlightButton.TextColor3 = Color3.fromRGB(226, 183, 20)
	else
		highlightButton.Text = "ESP Master Toggle: OFF"
		highlightButton.TextColor3 = Color3.fromRGB(210, 210, 225)
		removeHighlights()
	end
end)

-- Chams Toggle
chamsButton.MouseButton1Click:Connect(function()
	if exited then return end
	Config.ShowChams = not Config.ShowChams
	chamsButton.Text = Config.ShowChams and "Chams (Glow): ON" or "Chams (Glow): OFF"
	chamsButton.TextColor3 = Config.ShowChams and Color3.fromRGB(210, 210, 225) or Color3.fromRGB(120, 120, 135)
	refreshAllESPVisuals()
end)

-- Names Toggle
namesButton.MouseButton1Click:Connect(function()
	if exited then return end
	Config.ShowNames = not Config.ShowNames
	namesButton.Text = Config.ShowNames and "Name Tags: ON" or "Name Tags: OFF"
	namesButton.TextColor3 = Config.ShowNames and Color3.fromRGB(210, 210, 225) or Color3.fromRGB(120, 120, 135)
	refreshAllESPVisuals()
end)

-- Health Bar Toggle
healthBtn.MouseButton1Click:Connect(function()
	if exited then return end
	Config.ShowHealth = not Config.ShowHealth
	healthBtn.Text = Config.ShowHealth and "Health Bars: ON" or "Health Bars: OFF"
	healthBtn.TextColor3 = Config.ShowHealth and Color3.fromRGB(210, 210, 225) or Color3.fromRGB(120, 120, 135)
	refreshAllESPVisuals()
end)

-- Visibility Check Toggle
highlightVisibilityButton.MouseButton1Click:Connect(function()
	if exited then return end
	if Config.HighlightVisibility == "Every" then
		Config.HighlightVisibility = "Only Visible"
		highlightVisibilityButton.Text = "ESP Visibility: ONLY VISIBLE"
	else
		Config.HighlightVisibility = "Every"
		highlightVisibilityButton.Text = "ESP Visibility: EVERY"
	end
end)

------------------------------------------------------------
-- FLY MECHANICS
------------------------------------------------------------

local flySection = createSection("Flight Capabilities")
local flyKeyLabel = createLabel(flySection, "Fly Keybind: [" .. Config.FlyKey.Name .. "]")
local flyKeyButton = createButton(flySection, "Change Fly Key")
local flyStatus = createButton(flySection, "Flight System: OFF")

local flyConnection = nil

local function noclipOn()
	local char = player.Character
	if not char then return end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local function noclipOff()
	local char = player.Character
	if not char then return end

	local mainParts = {
		"HumanoidRootPart",
		"Torso",
		"UpperTorso",
		"LowerTorso",
		"Head"
	}

	for _, partName in ipairs(mainParts) do
		local part = char:FindFirstChild(partName)

		if part and part:IsA("BasePart") then
			part.CanCollide = true
		end
	end

	local hum = char:FindFirstChildOfClass("Humanoid")

	if hum then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function stopFly()
	flying = false

	flyStatus.Text = "Flight System: OFF"
	flyStatus.TextColor3 = Color3.fromRGB(210, 210, 225)

	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	local char = player.Character

	if char then
		local root = char:FindFirstChild("HumanoidRootPart")

		if root then
			for _, obj in ipairs(root:GetChildren()) do
				if obj:IsA("BodyVelocity") then
					obj:Destroy()
				end
			end
		end
	end

	noclipOff()
end

local function startFly()
	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	flying = true

	flyStatus.Text = "Flight System: ON"
	flyStatus.TextColor3 = Color3.fromRGB(226, 183, 20)

	local bv = Instance.new("BodyVelocity")

	bv.MaxForce = Vector3.new(
		1e6,
		1e6,
		1e6
	)

	bv.Velocity = Vector3.zero
	bv.Parent = root

	flyConnection = RS.Stepped:Connect(function()
		if not flying or exited then
			stopFly()
			return
		end

		if not root.Parent then
			stopFly()
			return
		end

		noclipOn()

		local move = Vector3.zero

		if UIS:IsKeyDown(Enum.KeyCode.W) then
			move += camera.CFrame.LookVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.S) then
			move -= camera.CFrame.LookVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.A) then
			move -= camera.CFrame.RightVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.D) then
			move += camera.CFrame.RightVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			move += Vector3.new(0, 1, 0)
		end

		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			move -= Vector3.new(0, 1, 0)
		end

		if move.Magnitude > 0 then
			move = move.Unit
		end

		bv.Velocity = move * flySpeed
	end)
end

local function toggleFly()
	if flying then
		stopFly()
	else
		startFly()
	end
end

flyStatus.MouseButton1Click:Connect(function()
	if exited then return end

	toggleFly()
end)

flyKeyButton.MouseButton1Click:Connect(function()
	if exited then return end

	flyKeyButton.Text = "Press a key..."

	local connection

	connection = UIS.InputBegan:Connect(function(input)
		if exited then
			connection:Disconnect()
			return
		end

		if input.KeyCode ~= Enum.KeyCode.Unknown then
			Config.FlyKey = input.KeyCode

			flyKeyLabel.Text = "Fly Keybind: [" .. Config.FlyKey.Name .. "]"
			flyKeyButton.Text = "Change Fly Key"

			connection:Disconnect()
		end
	end)
end)

------------------------------------------------------------
-- AIM MECHANICS
------------------------------------------------------------

local function checkAimTargetValidity(targetPlayer)
	if targetPlayer == player or not targetPlayer.Character then 
		return false, nil, 0 
	end

	local part = getTargetPart(targetPlayer.Character)
	if not part then 
		return false, nil, 0 
	end

	local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
	if not onScreen then 
		return false, nil, 0 
	end

	local mousePos = UIS:GetMouseLocation()
	local cursorDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

	if cursorDist > Config.AimFOV then
		return false, nil, 0
	end

	if Config.AimVisibility == "Only Visible" and not isPartVisible(part) then
		return false, nil, 0
	end

	return true, part, cursorDist
end

local aimSection = createSection("Combat & Aimbot")
local aimKeyLabel = createLabel(aimSection, "Aim Toggle Key: [" .. Config.AimKey.Name .. "]")
local aimKeyButton = createButton(aimSection, "Change Aim Key")
local aimTargetButton = createButton(aimSection, "Aim Target: HEAD")
local aimVisibilityButton = createButton(aimSection, "Aim Visibility: EVERY")
local aimStatus = createButton(aimSection, "Aim Lock System: OFF")

local function updateAimUI()
	if aimToggleState then
		aimStatus.Text = "Aim Lock System: ON"
		aimStatus.TextColor3 = Color3.fromRGB(226, 183, 20)
	else
		aimStatus.Text = "Aim Lock System: OFF"
		aimStatus.TextColor3 = Color3.fromRGB(210, 210, 225)
	end
end

aimStatus.MouseButton1Click:Connect(function()
	if exited then return end
	aimToggleState = not aimToggleState
	if aimToggleState then
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			aiming = true
		end
	else
		aiming = false
	end
	updateAimUI()
end)

aimKeyButton.MouseButton1Click:Connect(function()
	if exited then return end
	aimKeyButton.Text = "Press a key..."

	local connection
	connection = UIS.InputBegan:Connect(function(input)
		if exited then connection:Disconnect() return end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			Config.AimKey = input.KeyCode
			aimKeyLabel.Text = "Aim Toggle Key: [" .. Config.AimKey.Name .. "]"
			aimKeyButton.Text = "Change Aim Key"
			connection:Disconnect()
		end
	end)
end)

aimTargetButton.MouseButton1Click:Connect(function()
	if exited then return end
	if Config.AimTarget == "Head" then
		Config.AimTarget = "Torso"
		aimTargetButton.Text = "Aim Target: TORSO"
	else
		Config.AimTarget = "Head"
		aimTargetButton.Text = "Aim Target: HEAD"
	end
end)

aimVisibilityButton.MouseButton1Click:Connect(function()
	if exited then return end
	if Config.AimVisibility == "Every" then
		Config.AimVisibility = "Only Visible"
		aimVisibilityButton.Text = "Aim Visibility: ONLY VISIBLE"
	else
		Config.AimVisibility = "Every"
		aimVisibilityButton.Text = "Aim Visibility: EVERY"
	end
end)

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

RS.RenderStepped:Connect(function()
	if exited then return end

	if highlightEnabled then
		updateHighlights()
	end

	if aimToggleState and aiming then
		local target = getClosestTargetToCursor()
		if target and target.Character then
			local part = getTargetPart(target.Character)

			if part then
				camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
			end
		end
	end
end)

------------------------------------------------------------
-- RUN MECHANICS & PERSISTENT WALK SPEED
------------------------------------------------------------

local runSection = createSection("Movement Speed")
local runKeyLabel = createLabel(runSection, "Run Keybind: [" .. Config.RunKey.Name .. "]")
local runKeyButton = createButton(runSection, "Change Run Key")
local runModeButton = createButton(runSection, "Run Mode: HOLD")
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

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = slider

local fill = Instance.new("Frame")
fill.Size = UDim2.new(Config.RunSpeed / 100, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(226, 183, 20)
fill.BorderSizePixel = 0
fill.Parent = slider

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local thumb = Instance.new("Frame")
thumb.Size = UDim2.fromOffset(14, 14)
thumb.Position = UDim2.new(1, 0, 0.5, 0)
thumb.AnchorPoint = Vector2.new(0.5, 0.5)
thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
thumb.BorderSizePixel = 0
thumb.Parent = fill

local thumbCorner = Instance.new("UICorner")
thumbCorner.CornerRadius = UDim.new(1, 0)
thumbCorner.Parent = thumb

local sliderDragging = false

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

sliderContainer.InputBegan:Connect(function(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliderDragging = true
		updateSlider(input.Position.X)
	end
end)

UIS.InputChanged:Connect(function(input)
	if exited then return end
	if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		updateSlider(input.Position.X)
	end
end)

UIS.InputEnded:Connect(function(input)
	if exited then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliderDragging = false
	end
end)

runKeyButton.MouseButton1Click:Connect(function()
	if exited then return end
	runKeyButton.Text = "Press a key..."

	local connection
	connection = UIS.InputBegan:Connect(function(input)
		if exited then connection:Disconnect() return end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			Config.RunKey = input.KeyCode
			runKeyLabel.Text = "Run Keybind: [" .. Config.RunKey.Name .. "]"
			runKeyButton.Text = "Change Run Key"
			connection:Disconnect()
		end
	end)
end)

runModeButton.MouseButton1Click:Connect(function()
	if exited then return end
	if Config.RunMode == "Hold" then
		Config.RunMode = "Toggle"
		runModeButton.Text = "Run Mode: TOGGLE"
	else
		Config.RunMode = "Hold"
		runModeButton.Text = "Run Mode: HOLD"
	end
end)

------------------------------------------------------------
-- KEYBOARD & MOUSE INPUT CONTROLLERS
------------------------------------------------------------

UIS.InputBegan:Connect(function(input, gameProcessed)
	if exited or gameProcessed then return end

	-- Fly Activation Key
	if input.KeyCode == Config.FlyKey then
		toggleFly()
	end

	-- Aim System Master Switch Key
	if input.KeyCode == Config.AimKey then
		aimToggleState = not aimToggleState
		updateAimUI()
	end

	-- Active Aim Lock Mouse Button
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if aimToggleState then
			aiming = true
		end
	end

	-- Run Activation Key
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
end)

UIS.InputEnded:Connect(function(input)
	if exited then return end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = false
	end

	if input.KeyCode == Config.RunKey and Config.RunMode == "Hold" then
		running = false
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 16 end
	end
end)

------------------------------------------------------------
-- DESTROY / EXIT CLEANUP
------------------------------------------------------------

exitButton.MouseButton1Click:Connect(function()
	exited = true
	stopFly()
	removeHighlights()

	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 16 end

	gui:Destroy()
end)
