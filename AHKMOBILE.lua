--SACRED AHK VERSION 9.5 | open source / disfruten el codigo 

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- Estado
local SoruInfinitoEnabled = false
local SoruAimbotEnabled = false
local soruMaxDist = 2000
local AimlockPlayerEnabled = false
local AimlockNpcEnabled = false
local SilentAimPlayersEnabled = false
local SilentAimNPCsEnabled = false
local PlayerWidgetActive = false
local NpcWidgetActive = false
local SelectedSoruTarget = "Nearest"
local maxRange = 1000
local PlayersPosition = nil
local NPCPosition = nil

-- Limpiar UIs antiguas
for _, old in ipairs(playerGui:GetChildren()) do
    if old.Name:match("SacredUI") then old:Destroy() end
end

-- ============================================================
-- FAST ATTACK
-- ============================================================
local RegisterHit, RegisterAttack
local FastAttackEnabled = false
local FastAttackRange = 2000
local FastAttackRunning = false

spawn(function()
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == "RE/RegisterHit" then RegisterHit = v end
        if v:IsA("RemoteEvent") and v.Name == "RE/RegisterAttack" then RegisterAttack = v end
    end
end)

local function AttackMultipleTargets(targets)
    if not RegisterHit or not RegisterAttack then return end
    pcall(function()
        if not targets or #targets == 0 then return end
        local allTargets = {}
        for _, char in pairs(targets) do
            local head = char:FindFirstChild("Head")
            if head then table.insert(allTargets, {char, head}) end
        end
        if #allTargets == 0 then return end
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(allTargets[1][2], allTargets)
    end)
end

local function StartFastAttack()
    if FastAttackRunning then return end
    FastAttackRunning = true
    spawn(function()
        while FastAttackEnabled do
            RunService.Stepped:Wait()
            local myChar = player.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                local targets = {}
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= player and p.Character then
                        local hum = p.Character:FindFirstChild("Humanoid")
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                            table.insert(targets, p.Character)
                        end
                    end
                end
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, npc in pairs(enemies:GetChildren()) do
                        local hum = npc:FindFirstChild("Humanoid")
                        local hrp = npc:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                            table.insert(targets, npc)
                        end
                    end
                end
                if #targets > 0 then AttackMultipleTargets(targets) end
            end
        end
        FastAttackRunning = false
    end)
end

-- ============================================================
-- WALK SPEED
-- ============================================================
local WalkSpeedEnabled = false
local WalkSpeedValue = 16

spawn(function()
    while true do
        wait(0.05)
        if WalkSpeedEnabled then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= WalkSpeedValue then hum.WalkSpeed = WalkSpeedValue end
        end
    end
end)

-- ============================================================
-- DASH DISTANCE
-- ============================================================
local DashEnabled = false
local DashLengthDist = 1
local DashRunning = false

local function startDashLoop()
    if DashRunning then return end
    DashRunning = true
    spawn(function()
        while DashEnabled do
            wait(0.1)
            pcall(function()
                local char = player.Character
                if char then
                    if char:GetAttribute("DashLength") ~= DashLengthDist then char:SetAttribute("DashLength", DashLengthDist) end
                    if char:GetAttribute("DashLengthAir") ~= DashLengthDist then char:SetAttribute("DashLengthAir", DashLengthDist) end
                end
            end)
        end
        DashRunning = false
    end)
end

local function stopDashLoop()
    DashEnabled = false
    pcall(function()
        local char = player.Character
        if char then
            char:SetAttribute("DashLength", 1)
            char:SetAttribute("DashLengthAir", 1)
        end
    end)
end

-- ============================================================
-- NOCLIP
-- ============================================================
local NoclipEnabled = false
local NoclipConn = nil

local function SetNoclip(state)
    NoclipEnabled = state
    if state then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = player.Character
            if char and NoclipEnabled then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

player.CharacterAdded:Connect(function()
    if NoclipEnabled then wait(0.5); SetNoclip(true) end
end)

-- ============================================================
-- INFINITE JUMP
-- ============================================================
local InfiniteJumpEnabled = false

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ============================================================
-- WALK ON WATER
-- ============================================================
local WalkOnWaterEnabled = false

spawn(function()
    local waterPart = Instance.new("Part")
    waterPart.Size = Vector3.new(200, 1, 200)
    waterPart.Transparency = 1
    waterPart.Anchored = true
    waterPart.CanCollide = false
    waterPart.Name = "SacredWaterPlatform"
    waterPart.Parent = workspace
    while true do
        wait(0.05)
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if WalkOnWaterEnabled and hrp then
            if hrp.Position.Y >= 9.5 then
                waterPart.Position = Vector3.new(hrp.Position.X, 9.2, hrp.Position.Z)
                waterPart.CanCollide = true
            else
                waterPart.CanCollide = false
            end
        else
            waterPart.CanCollide = false
        end
    end
end)

-- ============================================================
-- SMART AUTO V4
-- ============================================================
local SmartAutoV4Enabled = false

spawn(function()
    while true do
        wait(1)
        if SmartAutoV4Enabled then
            pcall(function()
                local char = player.Character
                if char and char:GetAttribute("RaceEnergy") and char:GetAttribute("RaceEnergy") >= 100 then
                    local awakening = player.Backpack:FindFirstChild("Awakening")
                    if awakening and awakening:FindFirstChild("RemoteFunction") then
                        awakening.RemoteFunction:InvokeServer(true)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local ESPEnabled = false
local ESPObjects = {}

local function CreateESP(target)
    if not target:FindFirstChild("Head") then return end
    local existing = target.Head:FindFirstChild("SacredESP")
    if existing then existing:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SacredESP"
    billboard.Adornee = target.Head
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = target.Head
    local label = Instance.new("TextLabel", billboard)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = target.Name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.new(0, 1, 1)
    label.TextStrokeTransparency = 0
    table.insert(ESPObjects, billboard)
end

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    ESPObjects = {}
end

local function UpdateESP()
    ClearESP()
    if not ESPEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then CreateESP(p.Character) end
    end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, npc in pairs(enemies:GetChildren()) do CreateESP(npc) end
    end
end

spawn(function()
    while true do
        wait(5)
        if ESPEnabled then UpdateESP() end
    end
end)

-- ============================================================
-- SORU INFINITO
-- ============================================================
local function enforceSoru(char)
    if not char then return end
    if SoruInfinitoEnabled then char:SetAttribute("FlashstepCooldown", 1) end
    char.AttributeChanged:Connect(function(attr)
        if attr == "FlashstepCooldown" and SoruInfinitoEnabled and char:GetAttribute("FlashstepCooldown") ~= 1 then
            char:SetAttribute("FlashstepCooldown", 1)
        end
    end)
end

player.CharacterAdded:Connect(enforceSoru)
if player.Character then enforceSoru(player.Character) end

spawn(function()
    while true do
        wait(0.5)
        if SoruInfinitoEnabled and player.Character then
            pcall(function() player.Character:SetAttribute("FlashstepCooldown", 1) end)
        end
    end
end)

-- ============================================================
-- TARGET HELPERS
-- ============================================================
local function getClosestPlayer()
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local closest, closestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - myHrp.Position).Magnitude
                if dist < closestDist and dist < maxRange then
                    closestDist = dist
                    closest = p.Character
                end
            end
        end
    end
    return closest
end

local function getClosestNPC()
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local container = workspace:FindFirstChild("Enemies") or workspace
    local closest, closestDist = nil, math.huge
    for _, npc in pairs(container:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(npc) then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (npc.HumanoidRootPart.Position - myHrp.Position).Magnitude
                if dist < closestDist and dist < maxRange then
                    closestDist = dist
                    closest = npc
                end
            end
        end
    end
    return closest
end

-- ============================================================
-- AIMLOCK + SILENT AIM POSITIONS (RenderStepped)
-- ============================================================
RunService.RenderStepped:Connect(function()
    PlayersPosition = SilentAimPlayersEnabled and (getClosestPlayer() and getClosestPlayer().HumanoidRootPart.Position) or nil
    NPCPosition = SilentAimNPCsEnabled and (getClosestNPC() and getClosestNPC().HumanoidRootPart.Position) or nil

    if PlayerWidgetActive and AimlockPlayerEnabled then
        local t = getClosestPlayer()
        if t and t:FindFirstChild("HumanoidRootPart") then
            camera.CFrame = CFrame.new(camera.CFrame.Position, t.HumanoidRootPart.Position)
        end
    end
    if NpcWidgetActive and AimlockNpcEnabled then
        local t = getClosestNPC()
        if t and t:FindFirstChild("HumanoidRootPart") then
            camera.CFrame = CFrame.new(camera.CFrame.Position, t.HumanoidRootPart.Position)
        end
    end
end)

-- ============================================================
-- METAMETHODS (Silent Aim + Soru Aimbot) con protección
-- ============================================================
local ok, mt = pcall(getrawmetatable, game)
if ok and mt then
    local oldIndex = mt.__index
    local oldNamecall = mt.__namecall
    local function isCaller()
        if checkcaller then return checkcaller() end
        return false
    end
    local success, _ = pcall(setreadonly, mt, false)
    if success then
        mt.__index = function(self, key)
            if not isCaller() and self == mouse and (key == "Hit" or key == "Target") then
                if SoruAimbotEnabled then
                    local targetName = SelectedSoruTarget
                    if targetName == "Nearest" then
                        local cl = getClosestPlayer()
                        local p = cl and Players:GetPlayerFromCharacter(cl)
                        targetName = p and p.Name or nil
                    end
                    if targetName then
                        local tObj = Players:FindFirstChild(targetName)
                        local eHRP = tObj and tObj.Character and tObj.Character:FindFirstChild("HumanoidRootPart")
                        if eHRP then
                            local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            if myHRP and (myHRP.Position - eHRP.Position).Magnitude <= soruMaxDist then
                                if key == "Hit" then return CFrame.new(eHRP.Position) end
                                if key == "Target" then return eHRP end
                            end
                        end
                    end
                end
                if SilentAimPlayersEnabled or SilentAimNPCsEnabled then
                    local activePos = PlayersPosition or NPCPosition
                    if activePos then
                        if key == "Hit" then return CFrame.new(activePos) end
                        if key == "Target" then return workspace:FindFirstChild("HumanoidRootPart") end
                    end
                end
            end
            return oldIndex(self, key)
        end

        mt.__namecall = function(self, ...)
            local args = {...}
            local method = getnamecallmethod():lower()
            if not isCaller() and (method == "fireserver" or method == "invokeserver") then
                local activePos = PlayersPosition or NPCPosition
                if activePos then
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "Vector3" then args[i] = activePos
                        elseif typeof(arg) == "CFrame" then args[i] = CFrame.new(activePos)
                        end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end
        pcall(setreadonly, mt, true)
    end
end

-- ============================================================
-- INTERFAZ VISUAL
-- ============================================================
local THEMES = {
    ["Neon Purple"] = Color3.fromRGB(170, 0, 255),
    ["Electric Blue"] = Color3.fromRGB(0, 150, 255),
    ["Crimson Red"] = Color3.fromRGB(255, 0, 50),
    ["Toxic Green"] = Color3.fromRGB(0, 255, 100),
}
local currentThemeColor = THEMES["Neon Purple"]
local COLORS = {
    Background = Color3.fromRGB(10, 8, 14),
    PanelBG = Color3.fromRGB(16, 12, 22),
    TextWhite = Color3.fromRGB(255, 255, 255),
    TextGray = Color3.fromRGB(140, 140, 145),
    ToggleOff = Color3.fromRGB(26, 20, 32),
}
local themeStrokes, themeTexts, themeFrames = {}, {}, {}

-- GUIs
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "SacredUI_UltimateUI"
screenGui.ResetOnSpawn = false

local toggleIconGui = Instance.new("ScreenGui", playerGui)
toggleIconGui.Name = "SacredUI_ToggleIcon"
toggleIconGui.ResetOnSpawn = false

local playerWidgetGui = Instance.new("ScreenGui", playerGui)
playerWidgetGui.Name = "SacredUI_PlayerWidget"
playerWidgetGui.ResetOnSpawn = false

local npcWidgetGui = Instance.new("ScreenGui", playerGui)
npcWidgetGui.Name = "SacredUI_NpcWidget"
npcWidgetGui.ResetOnSpawn = false

-- Widgets flotantes
local function makeWidget(parent, pos)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 115, 0, 36)
    btn.Position = pos
    btn.BackgroundColor3 = COLORS.ToggleOff
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = COLORS.TextWhite
    btn.TextSize = 10
    btn.Visible = false
    btn.Active = true
    btn.Draggable = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local sk = Instance.new("UIStroke", btn)
    sk.Color = currentThemeColor; sk.Thickness = 1.2
    table.insert(themeStrokes, sk)
    return btn
end

local PlayerWidgetBtn = makeWidget(playerWidgetGui, UDim2.new(0.82, 0, 0.20, 0))
PlayerWidgetBtn.Text = "🔓 PLAYER: OFF"
local NpcWidgetBtn = makeWidget(npcWidgetGui, UDim2.new(0.82, 0, 0.27, 0))
NpcWidgetBtn.Text = "🔓 NPC: OFF"

local function updateWidgetsVisuals()
    PlayerWidgetBtn.Visible = PlayerWidgetActive
    PlayerWidgetBtn.BackgroundColor3 = AimlockPlayerEnabled and currentThemeColor or COLORS.ToggleOff
    PlayerWidgetBtn.Text = AimlockPlayerEnabled and "🔒 PLAYER: ON" or "🔓 PLAYER: OFF"
    NpcWidgetBtn.Visible = NpcWidgetActive
    NpcWidgetBtn.BackgroundColor3 = AimlockNpcEnabled and currentThemeColor or COLORS.ToggleOff
    NpcWidgetBtn.Text = AimlockNpcEnabled and "🔒 NPC: ON" or "🔓 NPC: OFF"
end

PlayerWidgetBtn.MouseButton1Click:Connect(function() AimlockPlayerEnabled = not AimlockPlayerEnabled; updateWidgetsVisuals() end)
NpcWidgetBtn.MouseButton1Click:Connect(function() AimlockNpcEnabled = not AimlockNpcEnabled; updateWidgetsVisuals() end)

-- Marco principal
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 460, 0, 280)
mainFrame.Position = UDim2.new(0.5, -230, 0.5, -140)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.ClipsDescendants = false
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 1.5; mainStroke.Color = currentThemeColor
table.insert(themeStrokes, mainStroke)

-- Efecto lluvia
local rainContainer = Instance.new("Frame", mainFrame)
rainContainer.Size = UDim2.new(1, 0, 1, 0)
rainContainer.BackgroundTransparency = 1
rainContainer.ClipsDescendants = true
Instance.new("UICorner", rainContainer).CornerRadius = UDim.new(0, 10)

local function createRainDrop()
    if not mainFrame.Visible then return end
    local drop = Instance.new("Frame", rainContainer)
    drop.Name = "RainDrop"
    drop.Size = UDim2.new(0, 2, 0, math.random(8, 16))
    drop.Position = UDim2.new(math.random(0, 100) / 100, 0, -0.1, 0)
    drop.BackgroundColor3 = currentThemeColor
    drop.BackgroundTransparency = math.random(5, 7) / 10
    drop.BorderSizePixel = 0
    table.insert(themeFrames, drop)
    local tween = TweenService:Create(drop, TweenInfo.new(math.random(10, 20) / 10, Enum.EasingStyle.Linear), {
        Position = UDim2.new(drop.Position.X.Scale - 0.04, 0, 1.1, 0)
    })
    tween:Play()
    tween.Completed:Connect(function()
        local idx = table.find(themeFrames, drop)
        if idx then table.remove(themeFrames, idx) end
        drop:Destroy()
    end)
end

spawn(function()
    while true do wait(0.05); pcall(createRainDrop) end
end)

local function centerAndMaximizeUI()
    mainFrame.Visible = true
    TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -230, 0.5, -140)
    }):Play()
end

-- Botón abrir (minimizado)
local openButton = Instance.new("TextButton", toggleIconGui)
openButton.Size = UDim2.new(0, 42, 0, 42)
openButton.Position = UDim2.new(0, 15, 0, 15)
openButton.BackgroundColor3 = COLORS.Background
openButton.Text = "AHK"  -- Cambiado de "BBG" a "AHK"
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 10
openButton.TextColor3 = currentThemeColor
openButton.Visible = false
openButton.Active = true
openButton.Draggable = true
Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 6)
local openStroke = Instance.new("UIStroke", openButton)
openStroke.Thickness = 1.2; openStroke.Color = currentThemeColor
table.insert(themeTexts, openButton)
table.insert(themeStrokes, openStroke)

openButton.MouseButton1Click:Connect(function()
    openButton.Visible = false
    centerAndMaximizeUI()
end)

-- Controles de ventana
local controlsContainer = Instance.new("Frame", mainFrame)
controlsContainer.Size = UDim2.new(0, 50, 0, 25)
controlsContainer.Position = UDim2.new(1, -60, 0, 12)
controlsContainer.BackgroundTransparency = 1

local function createTopControl(text, xOff, color, cb)
    local btn = Instance.new("TextButton", controlsContainer)
    btn.Size = UDim2.new(0, 20, 0, 20)
    btn.Position = UDim2.new(0, xOff, 0, 2)
    btn.BackgroundColor3 = COLORS.PanelBG
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = color
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(cb)
end

createTopControl("-", 0, COLORS.TextGray, function()
    mainFrame.Visible = false
    openButton.Visible = true
end)
createTopControl("X", 26, Color3.fromRGB(255, 75, 75), function()
    screenGui:Destroy(); toggleIconGui:Destroy()
    playerWidgetGui:Destroy(); npcWidgetGui:Destroy()
    ClearESP()
end)

-- Sidebar
local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 115, 1, 0)
sidebar.BackgroundTransparency = 1

local mainTitle = Instance.new("TextLabel", sidebar)
mainTitle.Text = "SACRED AHK"  -- Cambiado de "Sacred" a "SACRED AHK"
mainTitle.Font = Enum.Font.GothamBold
mainTitle.TextSize = 13
mainTitle.TextColor3 = currentThemeColor
mainTitle.Size = UDim2.new(1, 0, 0, 20)
mainTitle.Position = UDim2.new(0, 14, 0, 14)
mainTitle.BackgroundTransparency = 1
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
table.insert(themeTexts, mainTitle)

-- Contenedor de páginas
local PagesContainer = Instance.new("Frame", mainFrame)
PagesContainer.Size = UDim2.new(0, 320, 1, -55)
PagesContainer.Position = UDim2.new(0, 125, 0, 45)
PagesContainer.BackgroundTransparency = 1
PagesContainer.ClipsDescendants = false

local function createScrollingPage()
    local sf = Instance.new("ScrollingFrame", PagesContainer)
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.Visible = false
    local layout = Instance.new("UIListLayout", sf)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return sf
end

local CombatPage = createScrollingPage()
local GlitchesPage = createScrollingPage()
local CamLockPage = createScrollingPage()
local SoruPage = createScrollingPage()
CombatPage.Visible = true

-- Panel derecho (lista de jugadores para Soru)
local RightPanel = Instance.new("Frame", mainFrame)
RightPanel.Size = UDim2.new(0, 160, 1, -55)
RightPanel.Position = UDim2.new(0, 295, 0, 45)
RightPanel.BackgroundColor3 = COLORS.PanelBG
RightPanel.Visible = false
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8)

local ListScroll = Instance.new("ScrollingFrame", RightPanel)
ListScroll.Size = UDim2.new(1, -10, 1, -30)
ListScroll.Position = UDim2.new(0, 5, 0, 24)
ListScroll.BackgroundTransparency = 1
ListScroll.BorderSizePixel = 0
ListScroll.ScrollBarThickness = 3
ListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", ListScroll).Padding = UDim.new(0, 4)

local DropLabel = Instance.new("TextButton", ListScroll)
DropLabel.Name = "DropLabel"
DropLabel.Size = UDim2.new(1, 0, 0, 24)
DropLabel.BackgroundColor3 = COLORS.Background
DropLabel.Text = "🎯 Selector: Nearest"
DropLabel.Font = Enum.Font.GothamBold
DropLabel.TextColor3 = currentThemeColor
DropLabel.TextSize = 8.5
Instance.new("UICorner", DropLabel).CornerRadius = UDim.new(0, 4)
table.insert(themeTexts, DropLabel)

-- Pestañas de navegación
local categories = {
    { name = "Combat Main", page = CombatPage, y = 50 },
    { name = "Glitches", page = GlitchesPage, y = 74 },
    { name = "Cam Lock", page = CamLockPage, y = 98 },
    { name = "Soru Engine", page = SoruPage, y = 122 },
}

local activeTabBtn = nil
for _, cat in ipairs(categories) do
    local btn = Instance.new("TextButton", sidebar)
    btn.Text = cat.name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 9.5
    btn.TextColor3 = (cat.page == CombatPage) and currentThemeColor or COLORS.TextGray
    btn.Size = UDim2.new(1, -15, 0, 20)
    btn.Position = UDim2.new(0, 15, 0, cat.y)
    btn.BackgroundTransparency = 1
    btn.TextXAlignment = Enum.TextXAlignment.Left

    if cat.page == CombatPage then
        activeTabBtn = btn
        table.insert(themeTexts, btn)
    end

    btn.MouseButton1Click:Connect(function()
        if activeTabBtn then
            activeTabBtn.TextColor3 = COLORS.TextGray
            local idx = table.find(themeTexts, activeTabBtn)
            if idx then table.remove(themeTexts, idx) end
        end
        activeTabBtn = btn
        table.insert(themeTexts, btn)
        btn.TextColor3 = currentThemeColor
        CombatPage.Visible = false; GlitchesPage.Visible = false
        CamLockPage.Visible = false; SoruPage.Visible = false
        cat.page.Visible = true
        if cat.name == "Soru Engine" then
            RightPanel.Visible = true
            PagesContainer.Size = UDim2.new(0, 165, 1, -55)
        else
            RightPanel.Visible = false
            PagesContainer.Size = UDim2.new(0, 320, 1, -55)
        end
    end)
end

-- ============================================================
-- HELPERS DE UI
-- ============================================================
local function createModuleCard(name, height, targetPage)
    local card = Instance.new("Frame", targetPage)
    card.Size = UDim2.new(1, -8, 0, height)
    card.BackgroundColor3 = COLORS.PanelBG
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local title = Instance.new("TextLabel", card)
    title.Text = "  " .. name
    title.Font = Enum.Font.GothamBold
    title.TextSize = 9.5
    title.TextColor3 = COLORS.TextWhite
    title.Size = UDim2.new(1, 0, 0, 22)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    return card
end

local function addToggleElement(parent, labelText, defaultState, yPos, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -12, 0, 20)
    frame.Position = UDim2.new(0, 6, 0, yPos)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", frame)
    label.Text = labelText
    label.Font = Enum.Font.Gotham
    label.TextSize = 8.5
    label.TextColor3 = COLORS.TextWhite
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left

    local clickBtn = Instance.new("TextButton", frame)
    clickBtn.Size = UDim2.new(0, 30, 0, 13)
    clickBtn.Position = UDim2.new(1, -30, 0.5, -6)
    clickBtn.BackgroundColor3 = defaultState and currentThemeColor or COLORS.ToggleOff
    clickBtn.Text = defaultState and "ON" or "OFF"
    clickBtn.Font = Enum.Font.GothamBold
    clickBtn.TextSize = 7
    clickBtn.TextColor3 = COLORS.TextWhite
    Instance.new("UICorner", clickBtn).CornerRadius = UDim.new(0, 4)
    if defaultState then table.insert(themeFrames, clickBtn) end

    local state = defaultState
    local function refresh()
        if state then
            clickBtn.BackgroundColor3 = currentThemeColor
            clickBtn.Text = "ON"
            if not table.find(themeFrames, clickBtn) then table.insert(themeFrames, clickBtn) end
        else
            clickBtn.BackgroundColor3 = COLORS.ToggleOff
            clickBtn.Text = "OFF"
            local idx = table.find(themeFrames, clickBtn)
            if idx then table.remove(themeFrames, idx) end
        end
    end

    clickBtn.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        callback(state)
        updateWidgetsVisuals()
    end)
end

local function addStepper(parent, labelText, yPos, minVal, maxVal, step, getter, setter, suffix)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -12, 0, 28)
    frame.Position = UDim2.new(0, 6, 0, yPos)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", frame)
    label.Text = labelText
    label.Font = Enum.Font.Gotham
    label.TextSize = 8.5
    label.TextColor3 = COLORS.TextWhite
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left

    local minus = Instance.new("TextButton", frame)
    minus.Size = UDim2.new(0, 22, 0, 18)
    minus.Position = UDim2.new(1, -60, 0.5, -9)
    minus.Text = "-"
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 12
    minus.BackgroundColor3 = COLORS.ToggleOff
    minus.TextColor3 = COLORS.TextWhite
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 4)

    local valueLabel = Instance.new("TextLabel", frame)
    valueLabel.Size = UDim2.new(0, 40, 0, 18)
    valueLabel.Position = UDim2.new(1, -36, 0.5, -9)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(getter()) .. suffix
    valueLabel.TextColor3 = currentThemeColor
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 9
    table.insert(themeTexts, valueLabel)

    local plus = Instance.new("TextButton", frame)
    plus.Size = UDim2.new(0, 22, 0, 18)
    plus.Position = UDim2.new(1, -12, 0.5, -9)
    plus.Text = "+"
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 12
    plus.BackgroundColor3 = COLORS.ToggleOff
    plus.TextColor3 = COLORS.TextWhite
    Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 4)

    minus.MouseButton1Click:Connect(function()
        local v = math.max(getter() - step, minVal); setter(v)
        valueLabel.Text = tostring(v) .. suffix
    end)
    plus.MouseButton1Click:Connect(function()
        local v = math.min(getter() + step, maxVal); setter(v)
        valueLabel.Text = tostring(v) .. suffix
    end)
end

-- ============================================================
-- POBLAR PESTAÑAS
-- ============================================================

-- Combat
local c1 = createModuleCard("Silent Aim", 75, CombatPage)
addToggleElement(c1, "Silent Players", false, 24, function(v) SilentAimPlayersEnabled = v end)
addToggleElement(c1, "Silent NPCs", false, 48, function(v) SilentAimNPCsEnabled = v end)

local c2 = createModuleCard("Fast Attack", 90, CombatPage)
addToggleElement(c2, "Fast Attack", false, 24, function(v) FastAttackEnabled = v; if v then StartFastAttack() end end)
addStepper(c2, "Range:", 52, 100, 5000, 100, function() return FastAttackRange end, function(v) FastAttackRange = v end, "")

local c3 = createModuleCard("Movement", 240, CombatPage) -- Anti-Stun eliminado
addToggleElement(c3, "Walk Speed", false, 24, function(v) WalkSpeedEnabled = v end)
addStepper(c3, "Speed:", 52, 16, 500, 5, function() return WalkSpeedValue end, function(v) WalkSpeedValue = v end, "")
addToggleElement(c3, "Dash Distance", false, 88, function(v) DashEnabled = v; if v then startDashLoop() else stopDashLoop() end end)
addStepper(c3, "Distance:", 116, 1, 300, 10, function() return DashLengthDist end, function(v) DashLengthDist = v end, "")
addToggleElement(c3, "Noclip", false, 152, function(v) SetNoclip(v) end)
addToggleElement(c3, "Infinite Jump", false, 176, function(v) InfiniteJumpEnabled = v end)
addToggleElement(c3, "Walk on Water", false, 200, function(v) WalkOnWaterEnabled = v end)

local c4 = createModuleCard("Auto V4", 50, CombatPage)
addToggleElement(c4, "Smart Auto V4", false, 24, function(v) SmartAutoV4Enabled = v end)

-- Glitches (AHK sin assets)
local glitchCard = createModuleCard("FPS Drop Lag", 50, GlitchesPage)
local lagGui = nil
local lagCleanup = nil

local function destroyLagGui()
    if lagGui then lagGui:Destroy(); lagGui = nil end
end

local function createLagGui()
    destroyLagGui()
    local gui = Instance.new("ScreenGui", playerGui)
    gui.Name = "SacredUI_Lag"
    gui.ResetOnSpawn = false
    lagGui = gui

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 90, 0, 42)
    frame.Position = UDim2.new(0.37, 0, 0.26, 0)
    frame.BackgroundColor3 = Color3.fromRGB(75, 30, 135)
    frame.Active = true
    frame.Draggable = true
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local zBtn = Instance.new("TextButton", frame)
    zBtn.Size = UDim2.new(0, 40, 0, 30)
    zBtn.Position = UDim2.new(0, 12, 0, 6)
    zBtn.BackgroundColor3 = Color3.fromRGB(210, 140, 255)
    zBtn.Text = "Z"  -- Se mantiene "Z" (no se cambia)
    zBtn.TextSize = 18
    zBtn.TextColor3 = Color3.new(1, 1, 1)
    zBtn.Font = Enum.Font.GothamBold
    zBtn.BorderSizePixel = 0
    Instance.new("UICorner", zBtn).CornerRadius = UDim.new(0, 8)

    local close = Instance.new("TextButton", frame)
    close.Size = UDim2.new(0, 18, 0, 18)
    close.Position = UDim2.new(1, -22, 0, 3)
    close.BackgroundColor3 = Color3.fromRGB(255, 90, 120)
    close.Text = "X"
    close.TextSize = 13
    close.Font = Enum.Font.GothamBold
    close.TextColor3 = Color3.new(1, 1, 1)
    close.BorderSizePixel = 0
    Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)

    local DROP_TO_FPS = 20
    local LAG_DURATION = 0.43
    local lagBusy = false

    local function dropFPS()
        if lagBusy then return end
        lagBusy = true
        local stop = tick() + LAG_DURATION
        local interval = 1 / DROP_TO_FPS
        local con
        con = RunService.RenderStepped:Connect(function()
            if tick() > stop then con:Disconnect(); return end
            local now = tick()
            while tick() - now < interval do end
        end)
        wait(LAG_DURATION + 0.03)
        lagBusy = false
    end

    zBtn.MouseButton1Click:Connect(dropFPS)
    close.MouseButton1Click:Connect(function() gui.Enabled = false end)
end

-- Cambio de etiqueta de "AHK" a "Sanguine Z"
addToggleElement(glitchCard, "Sanguine Z", false, 24, function(v)
    if v then
        createLagGui()
        lagCleanup = destroyLagGui
    else
        destroyLagGui()
        if lagCleanup then lagCleanup(); lagCleanup = nil end
    end
end)

-- Anti Lava
local antiLavaCard = createModuleCard("Anti Lava", 50, GlitchesPage)
local antiLavaActive = false
local antiLavaConnection = nil

local function startAntiLava()
    if antiLavaConnection then antiLavaConnection:Disconnect() end
    antiLavaConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if not (char and antiLavaActive) then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "Torso" and part.Name ~= "UpperTorso" and part.Name ~= "LowerTorso" and part.Name ~= "Head" then
                part.CanTouch = false
            end
        end
    end)
end

local function stopAntiLava()
    if antiLavaConnection then antiLavaConnection:Disconnect(); antiLavaConnection = nil end
end

addToggleElement(antiLavaCard, "Anti Lava", false, 24, function(v)
    antiLavaActive = v
    if v then startAntiLava() else stopAntiLava() end
end)

-- Delete Ghost Ship
local deleteShipCard = createModuleCard("Delete Ghost Ship (Sea 2)", 50, GlitchesPage)
local deleteShipActive = false
local deleteShipRunning = false

local function deleteShipStructure()
    if not deleteShipActive then return end
    spawn(function()
        local shipNames = {"CursedShip","Cursed Ship","Ship"}
        local exteriorNames = {"Wall","Floor","Ceiling","Base","Hull","Window","DoorFrame"}
        for _, obj in pairs(workspace:GetDescendants()) do
            for _, sName in pairs(shipNames) do
                if obj.Name:find(sName) and (obj:IsA("Model") or obj:IsA("Folder")) then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") and not child.Parent:FindFirstChild("Humanoid") then
                            local isExterior = false
                            for _, ext in pairs(exteriorNames) do
                                if child.Name:find(ext) then isExterior = true; break end
                            end
                            if not isExterior then child:Destroy() end
                        end
                    end
                end
            end
        end
    end)
end

local function startDeleteShipLoop()
    if deleteShipRunning then return end
    deleteShipRunning = true
    spawn(function()
        while deleteShipActive do
            deleteShipStructure()
            wait(3)
        end
        deleteShipRunning = false
    end)
end

addToggleElement(deleteShipCard, "Delete Ghost Ship", false, 24, function(v)
    deleteShipActive = v
    if v then startDeleteShipLoop() end
end)

-- Cam Lock
local aimlockCard = createModuleCard("Camera Aimlock", 75, CamLockPage)
addToggleElement(aimlockCard, "Lock Players", false, 24, function(v)
    PlayerWidgetActive = v
    if not v then AimlockPlayerEnabled = false end
end)
addToggleElement(aimlockCard, "Lock NPCs", false, 48, function(v)
    NpcWidgetActive = v
    if not v then AimlockNpcEnabled = false end
end)

local espCard = createModuleCard("ESP", 50, CamLockPage)
addToggleElement(espCard, "ESP Names", false, 24, function(v)
    ESPEnabled = v
    if v then UpdateESP() else ClearESP() end
end)

-- Target ESP
local targetEspCard = createModuleCard("Target ESP", 50, CamLockPage)
local targetEspEnabled = false
local targetEspFrame, targetEspName, targetEspDist, targetEspHealth

local function createTargetEspFrame()
    if targetEspFrame then targetEspFrame:Destroy() end
    targetEspFrame = Instance.new("Frame", screenGui)
    targetEspFrame.Size = UDim2.new(0, 220, 0, 80)
    targetEspFrame.Position = UDim2.new(1, -230, 0, 10)
    targetEspFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    targetEspFrame.BackgroundTransparency = 0.4
    targetEspFrame.BorderSizePixel = 0
    targetEspFrame.Visible = false
    Instance.new("UICorner", targetEspFrame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", targetEspFrame).Color = currentThemeColor

    local function mkLabel(text, yPos, size)
        local l = Instance.new("TextLabel", targetEspFrame)
        l.Size = UDim2.new(1, -10, 0, size or 22)
        l.Position = UDim2.new(0, 5, 0, yPos)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.new(1, 1, 1)
        l.Font = Enum.Font.GothamBold
        l.TextSize = size == 22 and 12 or 10
        l.TextXAlignment = Enum.TextXAlignment.Left
        return l
    end
    targetEspName = mkLabel("🎯 Target: None", 5, 22)
    targetEspDist = mkLabel("📏 Distance: --", 30, 18)
    targetEspHealth = mkLabel("❤️ Health: --", 52, 18)
    targetEspDist.TextColor3 = Color3.fromRGB(200, 200, 200)
    targetEspHealth.TextColor3 = Color3.fromRGB(200, 200, 200)
end

local function updateTargetEsp()
    if not targetEspEnabled then
        if targetEspFrame then targetEspFrame.Visible = false end
        return
    end
    if not targetEspFrame then createTargetEspFrame() end
    targetEspFrame.Visible = true
    local targetChar = nil
    if (PlayerWidgetActive and AimlockPlayerEnabled) or SilentAimPlayersEnabled then
        targetChar = getClosestPlayer()
    elseif SoruAimbotEnabled then
        if SelectedSoruTarget == "Nearest" then
            targetChar = getClosestPlayer()
        else
            local tp = Players:FindFirstChild(SelectedSoruTarget)
            if tp then targetChar = tp.Character end
        end
    end
    local targetPlayer = targetChar and Players:GetPlayerFromCharacter(targetChar)
    if targetPlayer and targetChar then
        local hum = targetChar:FindFirstChildOfClass("Humanoid")
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local dist = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0
            targetEspName.Text = "🎯 " .. targetPlayer.Name
            targetEspDist.Text = string.format("📏 Distance: %.1f", dist)
            targetEspHealth.Text = string.format("❤️ Health: %.0f / %.0f", hum.Health, hum.MaxHealth)
            targetEspHealth.TextColor3 = (hum.Health / hum.MaxHealth < 0.3) and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 255, 80)
            return
        end
    end
    targetEspName.Text = "🎯 Target: None"
    targetEspDist.Text = "📏 Distance: --"
    targetEspHealth.Text = "❤️ Health: --"
end

spawn(function()
    while true do wait(0.3); if targetEspEnabled then updateTargetEsp() end end
end)

addToggleElement(targetEspCard, "Show Target", false, 24, function(v)
    targetEspEnabled = v
    if v then
        if not targetEspFrame then createTargetEspFrame() end
        targetEspFrame.Visible = true; updateTargetEsp()
    else
        if targetEspFrame then targetEspFrame.Visible = false end
    end
end)

-- Soru Engine
local soruCard = createModuleCard("Soru & Bypass", 100, SoruPage)
addToggleElement(soruCard, "Infinite Soru", false, 24, function(v)
    SoruInfinitoEnabled = v
    if player.Character then enforceSoru(player.Character) end
end)
addToggleElement(soruCard, "Soru Aimbot (TP)", false, 48, function(v) SoruAimbotEnabled = v end)
-- No cooldown eliminado

-- Lista de jugadores (selector de objetivo Soru)
local function refreshPlayerListUI()
    for _, item in ipairs(ListScroll:GetChildren()) do
        if item:IsA("TextButton") and item.Name ~= "DropLabel" and item.Name ~= "RefreshBtn" then
            item:Destroy()
        end
    end

    local nearestBtn = Instance.new("TextButton", ListScroll)
    nearestBtn.Name = "NearestBtn"
    nearestBtn.Size = UDim2.new(1, 0, 0, 22)
    nearestBtn.BackgroundColor3 = (SelectedSoruTarget == "Nearest") and currentThemeColor or COLORS.Background
    nearestBtn.Text = "   🎯 Nearest (auto)"
    nearestBtn.Font = Enum.Font.GothamSemibold
    nearestBtn.TextSize = 8.5
    nearestBtn.TextColor3 = (SelectedSoruTarget == "Nearest") and COLORS.TextWhite or COLORS.TextGray
    Instance.new("UICorner", nearestBtn).CornerRadius = UDim.new(0, 4)
    if SelectedSoruTarget == "Nearest" then table.insert(themeFrames, nearestBtn) end
    nearestBtn.MouseButton1Click:Connect(function()
        SelectedSoruTarget = "Nearest"
        DropLabel.Text = "🎯 Selector: Nearest"
        refreshPlayerListUI()
    end)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local isSelected = (SelectedSoruTarget == p.Name)
            local pBtn = Instance.new("TextButton", ListScroll)
            pBtn.Name = "PlayerBtn"
            pBtn.Size = UDim2.new(1, 0, 0, 22)
            pBtn.BackgroundColor3 = isSelected and currentThemeColor or COLORS.Background
            pBtn.Text = "   " .. p.Name
            pBtn.Font = Enum.Font.GothamSemibold
            pBtn.TextSize = 8.5
            pBtn.TextColor3 = isSelected and COLORS.TextWhite or COLORS.TextGray
            Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
            if isSelected then table.insert(themeFrames, pBtn) end
            pBtn.MouseButton1Click:Connect(function()
                SelectedSoruTarget = p.Name
                DropLabel.Text = "🎯 Selector: " .. p.Name
                refreshPlayerListUI()
            end)
        end
    end

    if not ListScroll:FindFirstChild("RefreshBtn") then
        local refreshBtn = Instance.new("TextButton", ListScroll)
        refreshBtn.Name = "RefreshBtn"
        refreshBtn.Size = UDim2.new(1, 0, 0, 24)
        refreshBtn.BackgroundColor3 = COLORS.PanelBG
        refreshBtn.Text = "⟳ Refresh Players"
        refreshBtn.Font = Enum.Font.GothamBold
        refreshBtn.TextSize = 8.5
        refreshBtn.TextColor3 = currentThemeColor
        Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)
        refreshBtn.MouseButton1Click:Connect(refreshPlayerListUI)
    end
end

Players.PlayerAdded:Connect(refreshPlayerListUI)
Players.PlayerRemoving:Connect(refreshPlayerListUI)
DropLabel.MouseButton1Click:Connect(function()
    SelectedSoruTarget = "Nearest"
    DropLabel.Text = "🎯 Selector: Nearest"
    refreshPlayerListUI()
end)
refreshPlayerListUI()

-- ============================================================
-- SELECTOR DE TEMA
-- ============================================================
local themeSelector = Instance.new("TextButton", mainFrame)
themeSelector.Text = "Neon Purple  ▼"
themeSelector.Font = Enum.Font.GothamBold
themeSelector.TextSize = 8.5
themeSelector.TextColor3 = currentThemeColor
themeSelector.Size = UDim2.new(0, 110, 0, 20)
themeSelector.Position = UDim2.new(1, -175, 0, 12)
themeSelector.BackgroundColor3 = COLORS.PanelBG
Instance.new("UICorner", themeSelector).CornerRadius = UDim.new(0, 5)
table.insert(themeTexts, themeSelector)

local themeDropdown = Instance.new("Frame", themeSelector)
themeDropdown.Size = UDim2.new(1, 0, 0, 92)
themeDropdown.Position = UDim2.new(0, 0, 1, 4)
themeDropdown.BackgroundColor3 = COLORS.PanelBG
themeDropdown.Visible = false
Instance.new("UICorner", themeDropdown).CornerRadius = UDim.new(0, 5)
Instance.new("UIListLayout", themeDropdown).Padding = UDim.new(0, 1)

local function applyNewTheme(themeName)
    currentThemeColor = THEMES[themeName]
    themeSelector.Text = themeName .. "  ▼"
    for _, s in ipairs(themeStrokes) do if s and s.Parent then s.Color = currentThemeColor end end
    for _, t in ipairs(themeTexts) do if t and t.Parent then t.TextColor3 = currentThemeColor end end
    for _, f in ipairs(themeFrames) do if f and f.Parent then f.BackgroundColor3 = currentThemeColor end end
    for _, drop in ipairs(rainContainer:GetChildren()) do
        if drop.Name == "RainDrop" then drop.BackgroundColor3 = currentThemeColor end
    end
    for _, child in ipairs(themeDropdown:GetChildren()) do
        if child:IsA("TextButton") and THEMES[child.Text] then
            child.TextColor3 = THEMES[child.Text]
        end
    end
    themeDropdown.Visible = false
    updateWidgetsVisuals()
end

for name, color in pairs(THEMES) do
    local opt = Instance.new("TextButton", themeDropdown)
    opt.Size = UDim2.new(1, 0, 0, 22)
    opt.BackgroundTransparency = 1
    opt.Text = name
    opt.Font = Enum.Font.GothamSemibold
    opt.TextSize = 8.5
    opt.TextColor3 = color
    opt.MouseButton1Click:Connect(function() applyNewTheme(name) end)
end

themeSelector.MouseButton1Click:Connect(function()
    themeDropdown.Visible = not themeDropdown.Visible
end)

-- F4 toggle
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F4 then
        if mainFrame.Visible then
            mainFrame.Visible = false
            openButton.Visible = true
        else
            openButton.Visible = false
            centerAndMaximizeUI()
        end
    end
end)

updateWidgetsVisuals()
print("✅ SACRED AHK loaded (stable version)")  -- Mensaje actualizado
