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
-- UI CREATION (centered + smooth animation)
------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "HL_UI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = lp:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,240,0,400)
frame.Position = UDim2.new(0.5, -120, 0.5, -165) -- centered
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Parent = gui
frame.BackgroundTransparency = 1 -- start invisible

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60,60,60)
stroke.Thickness = 1
stroke.Parent = frame

------------------------------------------------------------
-- SMOOTH LOAD-IN ANIMATION
------------------------------------------------------------

task.spawn(function()
    -- fade in
    for i = 1, 15 do
        frame.BackgroundTransparency = 1 - (i / 15)
        task.wait(0.02)
    end

    -- slide up slightly
    local startPos = frame.Position
    for i = 1, 12 do
        frame.Position = startPos + UDim2.new(0, 0, 0, -12 + i)
        task.wait(0.02)
    end
end)

------------------------------------------------------------
-- DRAG BAR + TITLE
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

local Title = Instance.new("TextLabel")
Title.Parent = dragBar
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "laszi's"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.TextStrokeTransparency = 0.4


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
-- RUN KEY UI
------------------------------------------------------------

local runKey = Enum.KeyCode.LeftControl
local running = false

local runKeyLabel = Instance.new("TextLabel")
runKeyLabel.Size = UDim2.new(0,220,0,20)
runKeyLabel.Position = UDim2.new(0,10,0,235)
runKeyLabel.Text = "Run Key: LeftControl"
runKeyLabel.BackgroundTransparency = 1
runKeyLabel.TextColor3 = Color3.fromRGB(200,200,200)
runKeyLabel.Font = Enum.Font.Gotham
runKeyLabel.TextSize = 14
runKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
runKeyLabel.Parent = frame

local runKeyBtn = Instance.new("TextButton")
runKeyBtn.Size = UDim2.new(0,220,0,28)
runKeyBtn.Position = UDim2.new(0,10,0,260)
runKeyBtn.Text = "Set Run Key"
runKeyBtn.Parent = frame
styleButton(runKeyBtn)

------------------------------------------------------------
-- RUN MODE SWITCH (Hold / Toggle)
------------------------------------------------------------

local runMode = "Hold"  -- default
local runModeBtn = Instance.new("TextButton")
runModeBtn.Size = UDim2.new(0,220,0,28)
runModeBtn.Position = UDim2.new(0,10,0,290)
runModeBtn.Text = "Run Mode: HOLD"
runModeBtn.Parent = frame
styleButton(runModeBtn)

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
-- RUN SPEED SLIDER
------------------------------------------------------------

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0,220,0,20)
speedLabel.Position = UDim2.new(0,10,0,295)
speedLabel.Text = "Run Speed: " .. speedValue
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(200,200,200)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = frame

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(0,220,0,10)
speedSlider.Position = UDim2.new(0,10,0,320)
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
        speedLabel.Text = "Run Speed: " .. speedValue

        local hum = lp.Character and lp.Character:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = running and speedValue or 16
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

runKeyBtn.MouseButton1Click:Connect(function()
    if exited then return end
    runKeyLabel.Text = "Run Key: ..."
    local conn
    conn = UIS.InputBegan:Connect(function(input)
        if exited then conn:Disconnect() return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            runKey = input.KeyCode
            runKeyLabel.Text = "Run Key: " .. input.KeyCode.Name
            conn:Disconnect()
        end
    end)
end)

------------------------------------------------------------
-- RUN HOTKEY BEHAVIOR (Hold / Toggle)
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

local function noclipOn()
    local char = lp.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function noclipOff()
    local char = lp.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end


local function stopFly()
    flying = false
    noclipOff()

    local char = lp.Character
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

        -- keep noclip active (some games re-enable collisions)
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
    local bestScore = math.huge

    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                -- 2D cursor distance
                local cursorDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                -- 3D world distance (distance from YOU)
                local worldDist = (root.Position - head.Position).Magnitude

                -- Combined score
                -- Lower score = better target
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

        if enabled then addHighlight(player) end
    end)
end

for _,player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
