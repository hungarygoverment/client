-- LocalScript (StarterPlayerScripts)

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

local flying = false
local flySpeed = 60
local aimEnabled = false
local aiming = false
local exited = false

------------------------------------------------------------
-- UI CREATION
------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "HL_UI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,240,0,330)
frame.Position = UDim2.new(0,20,0,20)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60,60,60)
stroke.Thickness = 1
stroke.Parent = frame

------------------------------------------------------------
-- VISIBLE TOP BAR + EXIT BUTTON
------------------------------------------------------------

local dragBar = Instance.new("Frame")
dragBar.Size = UDim2.new(1, 0, 0, 30)
dragBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dragBar.BorderSizePixel = 0
dragBar.Parent = frame

local dragBarCorner = Instance.new("UICorner")
dragBarCorner.CornerRadius = UDim.new(0, 12)
dragBarCorner.Parent = dragBar

local dragBarStroke = Instance.new("UIStroke")
dragBarStroke.Color = Color3.fromRGB(80, 80, 80)
dragBarStroke.Thickness = 1
dragBarStroke.Parent = dragBar

-- EXIT BUTTON (X)
local exitBtn = Instance.new("TextButton")
exitBtn.Size = UDim2.new(0, 30, 0, 30)
exitBtn.Position = UDim2.new(1, -35, 0, 0)
exitBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
exitBtn.Text = "X"
exitBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
exitBtn.Font = Enum.Font.GothamBold
exitBtn.TextSize = 20
exitBtn.BorderSizePixel = 0
exitBtn.Parent = dragBar

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 8)
exitCorner.Parent = exitBtn

exitBtn.MouseEnter:Connect(function()
    if exited then return end
    exitBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end)

exitBtn.MouseLeave:Connect(function()
    if exited then return end
    exitBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
end)

exitBtn.MouseButton1Click:Connect(function()
    if exited then return end
    exited = true

    enabled = false
    removeHighlights()

    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = 16
    end

    stopFly()
    aimEnabled = false
    aiming = false

    gui:Destroy()
    script:Destroy()
end)

------------------------------------------------------------
-- DRAG LOGIC (dragBar only)
------------------------------------------------------------

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
-- BUTTON STYLE FUNCTION
------------------------------------------------------------

local function styleButton(btn)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.TextColor3 = Color3.fromRGB(230,230,230)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(70,70,70)
    s.Thickness = 1
    s.Parent = btn

    btn.MouseEnter:Connect(function()
        if exited then return end
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    end)

    btn.MouseLeave:Connect(function()
        if exited then return end
        btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    end)
end

------------------------------------------------------------
-- BUTTONS
------------------------------------------------------------

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0,220,0,32)
toggleBtn.Position = UDim2.new(0,10,0,40)
toggleBtn.Text = "Highlight: OFF"
toggleBtn.Parent = frame
styleButton(toggleBtn)

local deleteBtn = Instance.new("TextButton")
deleteBtn.Size = UDim2.new(0,220,0,32)
deleteBtn.Position = UDim2.new(0,10,0,80)
deleteBtn.Text = "DELETE ALL / EXIT"
deleteBtn.Parent = frame
styleButton(deleteBtn)

------------------------------------------------------------
-- HOTKEY SETTINGS UI
------------------------------------------------------------

local flyKeyLabel = Instance.new("TextLabel")
flyKeyLabel.Size = UDim2.new(0,220,0,20)
flyKeyLabel.Position = UDim2.new(0,10,0,120)
flyKeyLabel.Text = "Fly Key: F"
flyKeyLabel.BackgroundTransparency = 1
flyKeyLabel.TextColor3 = Color3.fromRGB(200,200,200)
flyKeyLabel.Font = Enum.Font.Gotham
flyKeyLabel.TextSize = 14
flyKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
flyKeyLabel.Parent = frame

local flyKeyBtn = Instance.new("TextButton")
flyKeyBtn.Size = UDim2.new(0,220,0,28)
flyKeyBtn.Position = UDim2.new(0,10,0,145)
flyKeyBtn.Text = "Set Fly Key"
flyKeyBtn.Parent = frame
styleButton(flyKeyBtn)

local aimKeyLabel = Instance.new("TextLabel")
aimKeyLabel.Size = UDim2.new(0,220,0,20)
aimKeyLabel.Position = UDim2.new(0,10,0,180)
aimKeyLabel.Text = "Aim Toggle Key: G"
aimKeyLabel.BackgroundTransparency = 1
aimKeyLabel.TextColor3 = Color3.fromRGB(200,200,200)
aimKeyLabel.Font = Enum.Font.Gotham
aimKeyLabel.TextSize = 14
aimKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
aimKeyLabel.Parent = frame

local aimKeyBtn = Instance.new("TextButton")
aimKeyBtn.Size = UDim2.new(0,220,0,28)
aimKeyBtn.Position = UDim2.new(0,10,0,205)
aimKeyBtn.Text = "Set Aim Key"
aimKeyBtn.Parent = frame
styleButton(aimKeyBtn)

------------------------------------------------------------
-- SPEED SLIDER
------------------------------------------------------------

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0,220,0,20)
speedLabel.Position = UDim2.new(0,10,0,240)
speedLabel.Text = "Speed: 16"
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(200,200,200)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = frame

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(0,220,0,10)
speedSlider.Position = UDim2.new(0,10,0,265)
speedSlider.BackgroundColor3 = Color3.fromRGB(40,40,40)
speedSlider.BorderSizePixel = 0
speedSlider.Parent = frame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0,6)
sliderCorner.Parent = speedSlider

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(speedValue/100,0,1,0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0,120,255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = speedSlider

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(0,6)
sliderFillCorner.Parent = sliderFill

------------------------------------------------------------
-- SLIDER DRAGGING
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

        sliderFill.Size = UDim2.new(relX,0,1,0)
        speedValue = math.floor(relX * 100)
        speedLabel.Text = "Speed: " .. speedValue

        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = speedValue
        end
    end
end)

------------------------------------------------------------
-- HOTKEY SETTING LOGIC
------------------------------------------------------------

flyKeyBtn.MouseButton1Click:Connect(function()
    if exited then return end
    flyKeyLabel.Text = "Fly Key: ..."
    local conn
    conn = UIS.InputBegan:Connect(function(input)
        if exited then conn:Disconnect() return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            flyKey = input.KeyCode
            flyKeyLabel.Text = "Fly Key: " .. input.KeyCode.Name
            conn:Disconnect()
        end
    end)
end)

aimKeyBtn.MouseButton1Click:Connect(function()
    if exited then return end
    aimKeyLabel.Text = "Aim Toggle Key: ..."
    local conn
    conn = UIS.InputBegan:Connect(function(input)
        if exited then conn:Disconnect() return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            aimToggleKey = input.KeyCode
            aimKeyLabel.Text = "Aim Toggle Key: " .. input.KeyCode.Name
            conn:Disconnect()
        end
    end)
end)

------------------------------------------------------------
-- HIGHLIGHT SYSTEM
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

toggleBtn.MouseButton1Click:Connect(function()
    if exited then return end
    enabled = not enabled

    if enabled then
        toggleBtn.Text = "Highlight: ON"
        for _,player in ipairs(Players:GetPlayers()) do
            addHighlight(player)
        end
    else
        toggleBtn.Text = "Highlight: OFF"
        removeHighlights()
    end
end)

------------------------------------------------------------
-- FLY SYSTEM
------------------------------------------------------------

local function stopFly()
    flying = false
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        for _,obj in ipairs(lp.Character.HumanoidRootPart:GetChildren()) do
            if obj:IsA("BodyVelocity") then
                obj:Destroy()
            end
        end
    end
end

local function startFly()
    flying = true

    local char = lp.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = root

    while flying and not exited do
        task.wait()

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

UIS.InputBegan:Connect(function(input)
    if exited then return end
    if input.KeyCode == flyKey then
        if flying then stopFly() else startFly() end
    end
end)

------------------------------------------------------------
-- AIM ASSIST
------------------------------------------------------------

local function getClosestHeadToCursor()
    local mousePos = UIS:GetMouseLocation()
    local closestPlayer = nil
    local closestDist = math.huge

    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < closestDist then
                    closestDist = dist
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
        local target = getClosestHeadToCursor()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
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
-- DELETE EVERYTHING + DESTROY SCRIPT
------------------------------------------------------------

deleteBtn.MouseButton1Click:Connect(function()
    if exited then return end
    exited = true

    enabled = false
    toggleBtn.Text = "Highlight: OFF"
    removeHighlights()

    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = 16
    end

    stopFly()

    aimEnabled = false
    aiming = false

    gui:Destroy()
    script:Destroy()
end)

------------------------------------------------------------
-- PLAYER SETUP
------------------------------------------------------------

local function setupPlayer(player)
    player.CharacterAdded:Connect(function(char)
        if exited then return end
        task.wait(0.1)

        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = speedValue end

        if enabled then addHighlight(player) end
    end)
end

for _,player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
