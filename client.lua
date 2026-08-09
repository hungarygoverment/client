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

------------------------------------------------------------
-- GUI CREATION
------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "AltUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(330, 500)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(55, 55, 65)
mainStroke.Thickness = 1
mainStroke.Parent = main

------------------------------------------------------------
-- MINIMIZED SQUIRCLE IMAGE LOGO
------------------------------------------------------------

local minLogo = Instance.new("ImageLabel")
minLogo.Name = "MinLogo"
minLogo.Size = UDim2.fromScale(0.7, 0.7)
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
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "laszi's"
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -70, 0, 24)
subtitle.Position = UDim2.fromOffset(15, 29)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Premium Liquid Gold"
subtitle.TextColor3 = Color3.fromRGB(148, 113, 39)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(28, 28)
minBtn.Position = UDim2.new(1, -38, 0, 12)
minBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 39)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 12
minBtn.AutoButtonColor = false
minBtn.BorderSizePixel = 0
minBtn.Parent = header

local minBtnCorner = Instance.new("UICorner")
minBtnCorner.CornerRadius = UDim.new(0, 7)
minBtnCorner.Parent = minBtn

local minBtnStroke = Instance.new("UIStroke")
minBtnStroke.Color = Color3.fromRGB(55, 55, 65)
minBtnStroke.Thickness = 1
minBtnStroke.Parent = minBtn

minBtn.MouseEnter:Connect(function()
	if exited or minimized then return end
	minBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 51)
end)

minBtn.MouseLeave:Connect(function()
	if exited or minimized then return end
	minBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 39)
end)

------------------------------------------------------------
-- SCROLL AREA & HELPERS
------------------------------------------------------------

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -67)
scroll.Position = UDim2.fromOffset(10, 57)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 80)
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main

local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0, 12)
padding.Parent = scroll

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

------------------------------------------------------------
-- BOUNDS CLAMPING
------------------------------------------------------------

local function getClampedPosition(targetSize)
	local viewport = camera.ViewportSize
	local screenPadding = 12

	local halfW = targetSize.X / 2
	local halfH = targetSize.Y / 2

	local currentCenter = main.AbsolutePosition + (main.AbsoluteSize / 2)

	local clampedX = math.clamp(currentCenter.X, halfW + screenPadding, viewport.X - halfW - screenPadding)
	local clampedY = math.clamp(currentCenter.Y, halfH + screenPadding, viewport.Y - halfH - screenPadding)

	return UDim2.fromOffset(clampedX, clampedY)
end

------------------------------------------------------------
-- MINIMIZE / EXPAND LOGIC
------------------------------------------------------------

local function toggleMinimize()
	if exited then return end
	minimized = not minimized

	if minimized then
		-- Hide contents
		scroll.Visible = false
		header.BackgroundTransparency = 1
		title.Visible = false
		subtitle.Visible = false
		minBtn.Visible = false

		-- Tween to 1:1 Squircle
		TweenService:Create(
			main,
			TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(56, 56) }
		):Play()

		minLogo.Visible = true
	else
		minLogo.Visible = false

		-- Calculate target position so expanding always fits cleanly inside screen
		local targetPos = getClampedPosition(Vector2.new(330, 500))

		-- Tween back to full size and auto-adjust position
		local tween = TweenService:Create(
			main,
			TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				Size = UDim2.fromOffset(330, 500),
				Position = targetPos
			}
		)
		tween:Play()

		task.delay(0.15, function()
			if not minimized and not exited then
				scroll.Visible = true
				header.BackgroundTransparency = 0
				title.Visible = true
				subtitle.Visible = true
				minBtn.Visible = true
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
		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

------------------------------------------------------------
-- UI BUILDER HELPERS
------------------------------------------------------------

local function createSection(titleText)
	local section = Instance.new("Frame")
	section.BackgroundColor3 = Color3.fromRGB(23, 23, 28)
	section.BorderSizePixel = 0
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.Size = UDim2.new(1, -4, 0, 0)
	section.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = section

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 55)
	stroke.Thickness = 1
	stroke.Parent = section

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -20, 0, 0)
	content.Position = UDim2.fromOffset(10, 10)
	content.BackgroundTransparency = 1
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.Parent = section

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 7)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content

	local heading = Instance.new("TextLabel")
	heading.Size = UDim2.new(1, 0, 0, 24)
	heading.BackgroundTransparency = 1
	heading.Text = titleText
	heading.TextColor3 = Color3.fromRGB(230, 230, 235)
	heading.Font = Enum.Font.GothamBold
	heading.TextSize = 13
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.LayoutOrder = 0
	heading.Parent = content

	return content
end

local function createButton(parent, text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 34)
	button.BackgroundColor3 = Color3.fromRGB(32, 32, 39)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(225, 225, 230)
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 12
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(55, 55, 65)
	stroke.Thickness = 1
	stroke.Parent = button

	button.MouseEnter:Connect(function()
		if exited then return end
		button.BackgroundColor3 = Color3.fromRGB(42, 42, 51)
	end)

	button.MouseLeave:Connect(function()
		if exited then return end
		button.BackgroundColor3 = Color3.fromRGB(32, 32, 39)
	end)

	return button
end

local function createLabel(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(160, 160, 175)
	label.Font = Enum.Font.Gotham
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	return label
end

------------------------------------------------------------
-- HIGHLIGHT MECHANICS
------------------------------------------------------------

local function addHighlight(targetPlayer)
	if not highlightEnabled or exited then return end
	if targetPlayer == player then return end
	if not targetPlayer.Character then return end

	if highlights[targetPlayer] then
		highlights[targetPlayer]:Destroy()
	end

	local h = Instance.new("Highlight")
	h.FillColor = Color3.fromRGB(255, 0, 0)
	h.FillTransparency = 0.5
	h.Adornee = targetPlayer.Character
	h.Parent = targetPlayer.Character

	highlights[targetPlayer] = h
end

local function removeHighlights()
	for p, h in pairs(highlights) do
		if h then h:Destroy() end
		highlights[p] = nil
	end
end

local highlightSection = createSection("HIGHLIGHT")
local highlightButton = createButton(highlightSection, "Highlight: OFF")

highlightButton.MouseButton1Click:Connect(function()
	if exited then return end
	highlightEnabled = not highlightEnabled

	if highlightEnabled then
		highlightButton.Text = "Highlight: ON"
		highlightButton.TextColor3 = Color3.fromRGB(80, 180, 255)
		for _, p in ipairs(Players:GetPlayers()) do
			addHighlight(p)
		end
	else
		highlightButton.Text = "Highlight: OFF"
		highlightButton.TextColor3 = Color3.fromRGB(225, 225, 230)
		removeHighlights()
	end
end)

------------------------------------------------------------
-- FLY MECHANICS
------------------------------------------------------------

local flySection = createSection("FLY")
local flyKeyLabel = createLabel(flySection, "Fly Key: " .. Config.FlyKey.Name)
local flyKeyButton = createButton(flySection, "Change Fly Key")
local flyStatus = createButton(flySection, "Fly: OFF")

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
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
end

local function stopFly()
	flying = false
	flyStatus.Text = "Fly: OFF"
	flyStatus.TextColor3 = Color3.fromRGB(225, 225, 230)
	noclipOff()

	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		for _, obj in ipairs(char.HumanoidRootPart:GetChildren()) do
			if obj:IsA("BodyVelocity") then
				obj:Destroy()
			end
		end
	end
end

local function startFly()
	flying = true
	flyStatus.Text = "Fly: ON"
	flyStatus.TextColor3 = Color3.fromRGB(80, 180, 255)
	noclipOn()

	local char = player.Character
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Velocity = Vector3.zero
	bv.Parent = root

	task.spawn(function()
		while flying and not exited do
			task.wait()
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end

			local move = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then move += root.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then move -= root.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then move -= root.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then move += root.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end

			bv.Velocity = move * flySpeed
		end
		bv:Destroy()
	end)
end

local function toggleFly()
	if flying then stopFly() else startFly() end
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
		if exited then connection:Disconnect() return end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			Config.FlyKey = input.KeyCode
			flyKeyLabel.Text = "Fly Key: " .. Config.FlyKey.Name
			flyKeyButton.Text = "Change Fly Key"
			connection:Disconnect()
		end
	end)
end)

------------------------------------------------------------
-- AIM MECHANICS
------------------------------------------------------------

local aimSection = createSection("AIM")
local aimKeyLabel = createLabel(aimSection, "Aim Toggle Key: " .. Config.AimKey.Name)
local aimKeyButton = createButton(aimSection, "Change Aim Key")
local aimTargetButton = createButton(aimSection, "Aim Target: HEAD")
local aimStatus = createButton(aimSection, "Aim System: OFF")

local function updateAimUI()
	if aimToggleState then
		aimStatus.Text = "Aim System: ON"
		aimStatus.TextColor3 = Color3.fromRGB(80, 180, 255)
	else
		aimStatus.Text = "Aim System: OFF"
		aimStatus.TextColor3 = Color3.fromRGB(225, 225, 230)
	end
end

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
			aimKeyLabel.Text = "Aim Toggle Key: " .. Config.AimKey.Name
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

local function getClosestTargetToCursor()
	local mousePos = UIS:GetMouseLocation()
	local closestPlayer = nil
	local bestScore = math.huge

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local part = getTargetPart(p.Character)

			if part then
				local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)

				if onScreen then
					local cursorDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					local worldDist = (root.Position - part.Position).Magnitude
					local score = cursorDist + (worldDist * 0.25)

					if score < bestScore then
						bestScore = score
						closestPlayer = p
					end
				end
			end
		end
	end

	return closestPlayer
end

RS.RenderStepped:Connect(function()
	if exited then return end
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

local runSection = createSection("RUN")
local runKeyLabel = createLabel(runSection, "Run Key: " .. Config.RunKey.Name)
local runKeyButton = createButton(runSection, "Change Run Key")
local runModeButton = createButton(runSection, "Run Mode: HOLD")
local speedLabel = createLabel(runSection, "Run Speed: " .. Config.RunSpeed)

local slider = Instance.new("Frame")
slider.Size = UDim2.new(1, 0, 0, 8)
slider.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
slider.BorderSizePixel = 0
slider.Parent = runSection

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = slider

local fill = Instance.new("Frame")
fill.Size = UDim2.new(Config.RunSpeed / 100, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
fill.BorderSizePixel = 0
fill.Parent = slider

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

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

slider.InputBegan:Connect(function(input)
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
			runKeyLabel.Text = "Run Key: " .. Config.RunKey.Name
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

RS.Stepped:Connect(function()
	if exited then return end
	if running then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.WalkSpeed ~= Config.RunSpeed then
			hum.WalkSpeed = Config.RunSpeed
		end
	end
end)

------------------------------------------------------------
-- INPUT LISTENER (HOTKEYS & AIM BUTTON)
------------------------------------------------------------

UIS.InputBegan:Connect(function(input)
	if exited then return end

	-- Fly Key
	if input.KeyCode == Config.FlyKey then
		toggleFly()
	end

	-- Aim Key
	if input.KeyCode == Config.AimKey then
		aimToggleState = not aimToggleState
		if aimToggleState then
			if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				aiming = true
			end
		else
			aiming = false
		end
		updateAimUI()
	end

	-- Aim Hold
	if input.UserInputType == Enum.UserInputType.MouseButton2 and aimToggleState then
		aiming = true
	end

	-- Run Key
	if input.KeyCode == Config.RunKey then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		if Config.RunMode == "Hold" then
			running = true
			hum.WalkSpeed = Config.RunSpeed
		else
			running = not running
			hum.WalkSpeed = running and Config.RunSpeed or 16
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
-- PLAYER & RESPAWN SETUP
------------------------------------------------------------

local function setupPlayer(p)
	p.CharacterAdded:Connect(function()
		if exited then return end
		task.wait(0.1)
		if highlightEnabled then
			addHighlight(p)
		end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	setupPlayer(p)
end
Players.PlayerAdded:Connect(setupPlayer)

------------------------------------------------------------
-- EXIT / CLEANUP
------------------------------------------------------------

local exitButton = createButton(scroll, "DELETE UI / EXIT")
exitButton.BackgroundColor3 = Color3.fromRGB(55, 28, 32)

exitButton.MouseButton1Click:Connect(function()
	if exited then return end
	exited = true

	running = false
	highlightEnabled = false
	removeHighlights()

	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
	end

	stopFly()
	aimToggleState = false
	aiming = false

	local tween = TweenService:Create(
		main,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.fromOffset(300, 0),
			BackgroundTransparency = 1
		}
	)

	tween:Play()
	tween.Completed:Connect(function()
		gui:Destroy()
		script:Destroy()
	end)
end)

------------------------------------------------------------
-- LOAD ANIMATION
------------------------------------------------------------

main.Size = UDim2.fromOffset(330, 0)
TweenService:Create(
	main,
	TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	{ Size = UDim2.fromOffset(330, 500) }
):Play()
