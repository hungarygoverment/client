------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local camera = workspace.CurrentCamera

local highlights = {}
local enabled = false
local speedValue = 16

local flyKey = Enum.KeyCode.F
local aimToggleKey = Enum.KeyCode.G
local runKey = Enum.KeyCode.LeftControl

local flying = false
local flySpeed = 60
local aimEnabled = false
local aiming = false
local exited = false

local aimTarget = "Head"
local runMode = "Hold"

------------------------------------------------------------
-- FUNCTIONS MUST BE ABOVE UI
------------------------------------------------------------

local function addHighlight(player)
    if not enabled or exited then return end
    if player == lp then return end
    if not player.Character then return end

    if highlights[player] then
        highlights[player]:Destroy()
    end

    local h = Instance.new("Highlight")
    h.FillColor = Color3.fromRGB(255,0,0)
    h.FillTransparency = 0.5
    h.Adornee = player.Character
    h.Parent = player.Character

    highlights[player] = h
end

local function removeHighlights()
    for player, h in pairs(highlights) do
        if h then h:Destroy() end
        highlights[player] = nil
    end
end

local function noclipOn()
    local char = lp.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

local function noclipOff()
    local char = lp.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end

local function stopFly()
    flying = false
    noclipOff()

    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        for _, obj in ipairs(char.HumanoidRootPart:GetChildren()) do
            if obj:IsA("BodyVelocity") then obj:Destroy() end
        end
    end
end

local function startFly()
    flying = true
    noclipOn()

    local char = lp.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    bv.Parent = root

    while flying and not exited do
        task.wait()

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end

        local move = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then move += root.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= root.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= root.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += root.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end

        bv.Velocity = move * flySpeed
    end

    bv:Destroy()
end

------------------------------------------------------------
-- APPLE UI (CENTERED)
------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "HL_UI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui", 5)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 700)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0) -- PERFECT CENTER
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.BorderSizePixel = 0
frame.Parent = gui
frame.BackgroundTransparency = 1

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 22)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(60, 60, 60)
frameStroke.Thickness = 1
frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
frameStroke.Parent = frame

task.spawn(function()
    for i = 1, 15 do
        frame.BackgroundTransparency = 1 - (i / 15)
        task.wait(0.02)
    end
end)

------------------------------------------------------------
-- DRAG BAR
------------------------------------------------------------

local dragBar = Instance.new("Frame")
dragBar.Size = UDim2.new(1, 0, 0, 55)
dragBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
dragBar.BorderSizePixel = 0
dragBar.Parent = frame

local dragCorner = Instance.new("UICorner")
dragCorner.CornerRadius = UDim.new(0, 22)
dragCorner.Parent = dragBar

local dragStroke = Instance.new("UIStroke")
dragStroke.Color = Color3.fromRGB(70, 70, 70)
dragStroke.Thickness = 1
dragStroke.Parent = dragBar

local Title = Instance.new("TextLabel")
Title.Parent = dragBar
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "laszi’s Control Center"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true

local draggingUI = false
local dragStart
local startPos

dragBar.InputBegan:Connect(function(input)
    if exited then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingUI = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

dragBar.InputEnded:Connect(function(input)
    if exited then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingUI = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if exited then return end
    if draggingUI and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

------------------------------------------------------------
-- SECTION CREATOR
------------------------------------------------------------

local function createSection(titleText, order, height)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -30, 0, height)
    section.Position = UDim2.new(0, 15, 0, 70 + (order * (height + 10)))
    section.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    section.BorderSizePixel = 0
    section.Parent = frame

    local secCorner = Instance.new("UICorner")
    secCorner.CornerRadius = UDim.new(0, 16)
    secCorner.Parent = section

    local secStroke = Instance.new("UIStroke")
    secStroke.Color = Color3.fromRGB(55, 55, 55)
    secStroke.Thickness = 1
    secStroke.Parent = section

    local title = Instance.new("TextLabel")
    title.Parent = section
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left

    return section
end

------------------------------------------------------------
-- SECTIONS
------------------------------------------------------------

local secVisual = createSection("Visuals", 0, 130)
local secFly    = createSection("Fly System", 1, 130)
local secAim    = createSection("Aim Assist", 2, 160)
local secRun    = createSection("Run System", 3, 210)

------------------------------------------------------------
-- BUTTON CREATOR
------------------------------------------------------------

local function createButton(parent, text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 34)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Text = text
    btn.Parent = parent
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(70, 70, 70)
    s.Thickness = 1
    s.Parent = btn

    btn.MouseEnter:Connect(function()
        if exited then return end
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end)

    btn.MouseLeave:Connect(function()
        if exited then return end
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)

    return btn
end

------------------------------------------------------------
-- VISUALS SECTION
------------------------------------------------------------

local highlightBtn = createButton(secVisual, "Highlight: OFF", 45)
local deleteBtn    = createButton(secVisual, "DELETE ALL / EXIT", 85)

------------------------------------------------------------
-- FLY SECTION
------------------------------------------------------------

local flyKeyLabel = Instance.new("TextLabel")
flyKeyLabel.Size = UDim2.new(1, -20, 0, 20)
flyKeyLabel.Position = UDim2.new(0, 10, 0, 45)
flyKeyLabel.Text = "Fly Key: " .. flyKey.Name
flyKeyLabel.BackgroundTransparency = 1
flyKeyLabel.TextColor3 = Color3.fromRGB(200,200,200)
flyKeyLabel.Font = Enum.Font.Gotham
flyKeyLabel.TextSize = 14
flyKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
flyKeyLabel.Parent = secFly

local flyKeyBtn = createButton(secFly, "Set Fly Key", 75)

------------------------------------------------------------
-- AIM SECTION
------------------------------------------------------------

local aimKeyLabel = Instance.new("TextLabel")
aimKeyLabel.Size = UDim2.new(1, -20, 0, 20)
aimKeyLabel.Position = UDim2.new(0, 10, 0, 45)
aimKeyLabel.Text = "Aim Toggle Key: " .. aimToggleKey.Name
aimKeyLabel.BackgroundTransparency = 1
aimKeyLabel.TextColor3 = Color3.fromRGB(200,200,200)
aimKeyLabel.Font = Enum.Font.Gotham
aimKeyLabel.TextSize = 14
aimKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
aimKeyLabel.Parent = secAim

local aimKeyBtn = createButton(secAim, "Set Aim Key", 75)
local aimTargetBtn = createButton(secAim, "Aim Target: HEAD", 115)

------------------------------------------------------------
-- RUN SECTION
------------------------------------------------------------

local runKeyLabel = Instance.new("TextLabel")
runKeyLabel.Size = UDim2.new(1, -20, 0, 20)
runKeyLabel.Position = UDim2.new(0, 10, 0, 45)
runKeyLabel.Text = "Run Key: " .. runKey.Name
runKeyLabel.BackgroundTransparency = 1
runKeyLabel.TextColor3 = Color3.fromRGB(200,200,200)
runKeyLabel.Font = Enum.Font.Gotham
runKeyLabel.TextSize = 14
runKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
runKeyLabel.Parent = secRun

local runKeyBtn = createButton(secRun, "Set Run Key", 75)
local runModeBtn = createButton(secRun, "Run Mode: HOLD", 115)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 155)
speedLabel.Text = "Run Speed: " .. speedValue
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(200,200,200)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = secRun

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(1, -20, 0, 12)
speedSlider.Position = UDim2.new(0, 10, 0, 180)
speedSlider.BackgroundColor3 = Color3.fromRGB(40,40,40)
speedSlider.BorderSizePixel = 0
speedSlider.Parent = secRun

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 6)
sliderCorner.Parent = speedSlider

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(speedValue/100, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0,120,255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = speedSlider

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(0, 6)
sliderFillCorner.Parent = sliderFill

------------------------------------------------------------
-- DELETE BUTTON (FIXED)
------------------------------------------------------------

deleteBtn.MouseButton1Click:Connect(function()
    if exited then return end
    exited = true

    enabled = false
    highlightBtn.Text = "Highlight: OFF"
    removeHighlights()

    local hum = lp.Character and lp.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = 16 end

    stopFly()

    aimEnabled = false
    aiming = false

    if gui then gui:Destroy() end
    pcall(function() script:Destroy() end)
end)

------------------------------------------------------------
-- HIGHLIGHT BUTTON
------------------------------------------------------------

highlightBtn.MouseButton1Click:Connect(function()
    if exited then return end
    enabled = not enabled
    highlightBtn.Text = enabled and "Highlight: ON" or "Highlight: OFF"

    if enabled then
        for _,player in ipairs(Players:GetPlayers()) do
            if player ~= lp then addHighlight(player) end
        end
    else
        removeHighlights()
    end
end)

------------------------------------------------------------
-- AIM ASSIST
------------------------------------------------------------

local function getClosestTargetToCursor()
    local mousePos = UIS:GetMouseLocation()
    local closestPlayer = nil
    local bestScore = math.huge

    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local partName = aimTarget == "Head" and "Head" or "HumanoidRootPart"

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild(partName) then

            local part = player.Character[partName]
            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)

            if onScreen then
                local cursorDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                local worldDist = (root.Position - part.Position).Magnitude
                local score = cursorDist + (worldDist * 0.25)

                if score < bestScore then
                    bestScore = score
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

RS.RenderStepped:Connect(function()
    if exited then return end
    if aiming and aimEnabled then
        local target = getClosestTargetToCursor()
        if target and target.Character then
            local partName = aimTarget == "Head" and "Head" or "HumanoidRootPart"
            local part = target.Character:FindFirstChild(partName)
            if part then
                camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
            end
        end
    end
end)

UIS.InputBegan:Connect(function(input)
    if exited then return end
    if input.KeyCode == aimToggleKey then
        aimEnabled = not aimEnabled
        if aimEnabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            aiming = true
        end
    end
end)

UIS.InputBegan:Connect(function(input)
    if exited then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and aimEnabled then
        aiming = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if exited then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

------------------------------------------------------------
-- RUN SYSTEM
------------------------------------------------------------

runKeyBtn.MouseButton1Click:Connect(function()
    if exited then return end
    runKeyLabel.Text = "Run Key: " .. runKey.Name

runKeyBtn.MouseButton1Click:Connect(function()
    if exited then return end
    runKeyLabel.Text = "Run Key: ..."
    local conn
    conn = UIS.InputBegan:Connect(function(input)
        if exited then conn:Disconnect() return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            runKey = input.KeyCode
            runKeyLabel.Text = "Run Key: " .. runKey.Name
            conn:Disconnect()
        end
    end)
end)

------------------------------------------------------------
-- RUN MODE BUTTON
------------------------------------------------------------

runModeBtn.MouseButton1Click:Connect(function()
    if exited then return end
    if runMode == "Hold" then
        runMode = "Toggle"
        runModeBtn.Text = "Run Mode: TOGGLE"
    else
        runMode = "Hold"
        runModeBtn.Text = "Run Mode: HOLD"
    end
end)

------------------------------------------------------------
-- RUN KEY INPUT
------------------------------------------------------------

UIS.InputBegan:Connect(function(input)
    if exited then return end

    if input.KeyCode == runKey then
        local hum = lp.Character and lp.Character:FindFirstChild("Humanoid")
        if not hum then return end

        if runMode == "Hold" then
            running = true
            hum.WalkSpeed = speedValue
        else
            running = not running
            hum.WalkSpeed = running and speedValue or 16
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if exited then return end

    if input.KeyCode == runKey and runMode == "Hold" then
        running = false
        local hum = lp.Character and lp.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)

------------------------------------------------------------
-- RUN SPEED SLIDER
------------------------------------------------------------

local draggingSlider = false

speedSlider.InputBegan:Connect(function(input)
    if exited then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if exited then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if exited then return end
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then

        local relX = math.clamp(
            (input.Position.X - speedSlider.AbsolutePosition.X) / speedSlider.AbsoluteSize.X,
            0, 1
        )

        sliderFill.Size = UDim2.new(relX, 0, 1, 0)

        speedValue = math.floor(relX * 100)
        speedLabel.Text = "Run Speed: " .. speedValue

        local hum = lp.Character and lp.Character:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = running and speedValue or 16
        end
    end
end)

------------------------------------------------------------
-- PLAYER SETUP
------------------------------------------------------------

local function setupPlayer(player)
    player.CharacterAdded:Connect(function(char)
        if exited then return end
        task.wait(0.1)

        if enabled then addHighlight(player) end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
