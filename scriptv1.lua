-- ==========================================
-- 🐱 แมวส้ม Script Hub - Complete Edition v42
-- (Graphics + RTX + Sky อยู่ในตั้งค่า + ทำงานได้จริง)
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hasHook = (hookmetamethod ~= nil) and (hookfunction ~= nil)

if LocalPlayer.PlayerGui:FindFirstChild("AnimeScriptHub") then
    LocalPlayer.PlayerGui.AnimeScriptHub:Destroy()
end

-- ==========================================
-- Config
-- ==========================================
local Config = {
    AimbotEnabled = false, AimPart = "Head", FOVCircleRadius = 250,
    LockStrength = 90, WallCheck = true,
    BulletHomingEnabled = false, BulletSpeed = 500,
    ESP_Enabled = false, ESP_Box = false, ESP_Health = false,
    ESP_LineColor = Color3.fromRGB(255, 0, 255), ESP_LineMode = "Bottom",
    LineThickness = 1.5,
    SpeedEnabled = false, SpeedValue = 500, SpeedBypass = true,
    FlyEnabled = false, FlySpeed = 100, FlyHeight = 20,
    AntiLagEnabled = false,
    AFKEnabled = false,
    CollectRadius = 30,
    AntiDropEnabled = false, StealDelay = 1,
    FPSEnabled = false, FPSRGB = false, FPSColor = Color3.fromRGB(0, 255, 0),
    ThemeColor = Color3.fromRGB(130, 80, 255),
    BgColor = Color3.fromRGB(20, 15, 35),
    TextColor = Color3.fromRGB(240, 240, 255),
    TextDim = Color3.fromRGB(160, 160, 190)
}

local currentLockedTarget = nil
local espDrawings = {}

-- ==========================================
-- ScreenGui
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimeScriptHub"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.IgnoreGuiInset = true

-- Drawing API
local FOVCircle, TargetSnapLine
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Radius = Config.FOVCircleRadius
    FOVCircle.Color = Config.ESP_LineColor
    FOVCircle.Thickness = 1.5
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.8
    TargetSnapLine = Drawing.new("Line")
    TargetSnapLine.Color = Color3.fromRGB(255, 0, 0)
    TargetSnapLine.Thickness = 2
    TargetSnapLine.Transparency = 0.9
    TargetSnapLine.Visible = false
end)

-- ==========================================
-- SendNotification
-- ==========================================
local function SendNotification(title, content, duration)
    duration = duration or 3
    pcall(function()
        local NotifContainer = ScreenGui:FindFirstChild("NotifContainer")
        if not NotifContainer then
            NotifContainer = Instance.new("Frame")
            NotifContainer.Name = "NotifContainer"
            NotifContainer.Size = UDim2.new(0, 260, 1, 0)
            NotifContainer.Position = UDim2.new(1, -275, 0, 10)
            NotifContainer.BackgroundTransparency = 1
            NotifContainer.ZIndex = 200
            NotifContainer.Parent = ScreenGui
            local layout = Instance.new("UIListLayout")
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            layout.Padding = UDim.new(0, 8)
            layout.Parent = NotifContainer
        end
        local NotifBox = Instance.new("Frame")
        NotifBox.Size = UDim2.new(1, 0, 0, 65)
        NotifBox.BackgroundColor3 = Config.BgColor
        NotifBox.BackgroundTransparency = 0.15
        NotifBox.Position = UDim2.new(1, 50, 0, 0)
        NotifBox.ZIndex = 200
        NotifBox.Parent = NotifContainer
        Instance.new("UICorner", NotifBox).CornerRadius = UDim.new(0, 10)
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = Config.ThemeColor
        boxStroke.Thickness = 1.5
        boxStroke.Transparency = 0.3
        boxStroke.Parent = NotifBox
        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -50, 0, 20)
        tLabel.Position = UDim2.new(0, 48, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        tLabel.TextSize = 14
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.ZIndex = 200
        tLabel.Parent = NotifBox
        local cLabel = Instance.new("TextLabel")
        cLabel.Size = UDim2.new(1, -50, 0, 25)
        cLabel.Position = UDim2.new(0, 48, 0, 28)
        cLabel.BackgroundTransparency = 1
        cLabel.Text = content
        cLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        cLabel.TextSize = 12
        cLabel.Font = Enum.Font.Gotham
        cLabel.TextXAlignment = Enum.TextXAlignment.Left
        cLabel.TextWrapped = true
        cLabel.ZIndex = 200
        cLabel.Parent = NotifBox
        NotifBox:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
        task.delay(duration, function()
            pcall(function()
                NotifBox:TweenPosition(UDim2.new(1, 50, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
                task.wait(0.3)
                NotifBox:Destroy()
            end)
        end)
    end)
end

-- ==========================================
-- ฟังก์ชันช่วย
-- ==========================================
local function GetTargetPart(character)
    if not character then return nil end
    local partNames = {Config.AimPart, "Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    for _, name in ipairs(partNames) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return nil
end

local function HasLineOfSight(targetPart)
    if not Config.WallCheck then return true end
    if not targetPart then return false end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Head") then return false end
    local origin = char.Head.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, targetPart.Parent}
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, params)
    if not result then return true end
    if result.Instance and result.Instance:IsDescendantOf(targetPart.Parent) then return true end
    return false
end

local function UnlockMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        humanoid.AutoRotate = true
        humanoid.Sit = false
    end
    if hrp then
        for _, v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyGyro") or v:IsA("BodyVelocity") or v:IsA("BodyPosition") then
                pcall(function() v:Destroy() end)
            end
        end
    end
end

local function IsTargetInFOV()
    if not Config.BulletHomingEnabled then return false end
    if not currentLockedTarget or not currentLockedTarget.Character then return false end
    local targetPart = GetTargetPart(currentLockedTarget.Character)
    if not targetPart then return false end
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen then return false end
    local distanceFromCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
    if FOVCircle and distanceFromCenter > FOVCircle.Radius then return false end
    if not HasLineOfSight(targetPart) then return false end
    return true, targetPart
end

-- ==========================================
-- ระบบขโมยไข่
-- ==========================================
local Stealing = false

local function FindNearestEgg()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local nearest = nil
    local shortest = Config.CollectRadius
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part and part ~= hrp then
                local name = string.lower(obj.Name)
                if string.find(name, "egg") or string.find(name, "steal") or string.find(name, "pet") then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < shortest then
                        shortest = dist
                        nearest = part
                    end
                end
            end
        end
    end
    return nearest
end

local function StealEggOnce()
    if Stealing then
        SendNotification("ขโมยไข่", "กำลังขโมยอยู่...", 2)
        return
    end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        SendNotification("ขโมยไข่", "ไม่พบตัวละคร", 2)
        return
    end
    Stealing = true
    SendNotification("ขโมยไข่", "กำลังเก็บไข่...", 2)
    task.wait(Config.StealDelay)
    local hrp = char.HumanoidRootPart
    local originalCFrame = hrp.CFrame
    local egg = FindNearestEgg()
    if not egg then
        SendNotification("ขโมยไข่", "ไม่พบไข่ในระยะ", 2)
        Stealing = false
        return
    end
    pcall(function() hrp.CFrame = CFrame.new(egg.Position) end)
    task.wait(0.1)
    pcall(function() hrp.CFrame = originalCFrame end)
    task.wait(0.1)
    Stealing = false
    SendNotification("ขโมยไข่", "เก็บไข่สำเร็จ!", 2)
end

local AntiDropConnection = nil
local function EnableAntiDrop()
    AntiDropConnection = RunService.Heartbeat:Connect(function()
        if not Config.AntiDropEnabled then
            if AntiDropConnection then AntiDropConnection:Disconnect() end
            return
        end
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local name = string.lower(tool.Name)
            if string.find(name, "egg") or string.find(name, "steal") or string.find(name, "pet") then
                pcall(function()
                    if tool.Parent ~= char then tool.Parent = char end
                    if tool:FindFirstChild("Handle") then
                        tool.Handle.CanCollide = false
                    end
                end)
            end
        end
    end)
end
local function DisableAntiDrop()
    if AntiDropConnection then AntiDropConnection:Disconnect(); AntiDropConnection = nil end
end

-- ==========================================
-- สแกนหาไอเทม
-- ==========================================
local function ScanMapItems()
    local items = {}
    local seen = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool") then
            local name = obj.Name
            if name and #name > 0 and #name < 40 then
                local nameLower = string.lower(name)
                local keywords = {"egg", "pet", "sword", "gun", "knife", "weapon", "tool", "item",
                    "crate", "chest", "coin", "gem", "cash", "reward", "candy", "food",
                    "toy", "ball", "potion", "magic", "crystal", "orb", "fruit", "seed"}
                for _, kw in ipairs(keywords) do
                    if string.find(nameLower, kw) then
                        if not seen[name] then
                            seen[name] = true
                            table.insert(items, {Name = name, Obj = obj, Type = "Workspace"})
                        end
                        break
                    end
                end
            end
        end
    end
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("Folder") then
            local name = obj.Name
            if name and #name > 0 and #name < 40 then
                if not seen[name] then
                    seen[name] = true
                    table.insert(items, {Name = name, Obj = obj, Type = "ReplicatedStorage"})
                end
            end
        end
    end
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name
            local nameLower = string.lower(name)
            local keywords = {"spawn", "give", "create", "summon", "buy", "get", "item", "egg", "pet"}
            for _, kw in ipairs(keywords) do
                if string.find(nameLower, kw) then
                    if not seen["R_" .. name] then
                        seen["R_" .. name] = true
                        table.insert(items, {Name = name, Obj = obj, Type = "Remote"})
                    end
                    break
                end
            end
        end
    end
    table.sort(items, function(a, b) return a.Name < b.Name end)
    return items
end

local function SpawnItem(itemData)
    if not itemData then return end
    local name = itemData.Name
    local obj = itemData.Obj
    local objType = itemData.Type
    SendNotification("เสกของ", "กำลังเสก: " .. name, 2)
    if objType == "Remote" then
        pcall(function()
            obj:FireServer()
            obj:FireServer(name)
            obj:FireServer(1)
            obj:FireServer(name, 1)
        end)
        return
    end
    local remotes = {}
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local rName = string.lower(remote.Name)
            if string.find(rName, "spawn") or string.find(rName, "give") or string.find(rName, "create") or string.find(rName, "summon") then
                table.insert(remotes, remote)
            end
        end
    end
    if #remotes > 0 then
        for _, remote in ipairs(remotes) do
            pcall(function()
                remote:FireServer(name)
                remote:FireServer(name, 1)
                remote:FireServer(LocalPlayer, name)
            end)
        end
        SendNotification("เสกของ", "✅ ยิง " .. #remotes .. " Remote", 3)
    else
        SendNotification("เสกของ", "⚠️ ไม่พบ Remote", 3)
    end
end

-- ==========================================
-- ดึงเงินจากผู้เล่น
-- ==========================================
local function FindMoneyRemotes()
    local remotes = {}
    local keywords = {"money", "cash", "coin", "steal", "rob", "take", "grab", "claim"}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = string.lower(obj.Name)
            for _, kw in ipairs(keywords) do
                if string.find(name, kw) then
                    table.insert(remotes, obj)
                    break
                end
            end
        end
    end
    return remotes
end

local function StealMoneyFromPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    local remotes = FindMoneyRemotes()
    if #remotes == 0 then
        SendNotification("ดึงเงิน", "❌ ไม่พบ Remote", 3)
        return
    end
    for _, remote in ipairs(remotes) do
        pcall(function()
            remote:FireServer(targetPlayer)
            remote:FireServer(targetPlayer.UserId)
            remote:FireServer(targetPlayer.Name)
            remote:FireServer(targetHRP.Position)
        end)
    end
    SendNotification("ดึงเงิน", "✅ ยิงใส่ " .. targetPlayer.Name, 2)
end

-- ==========================================
-- FPS Counter
-- ==========================================
local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0, 120, 0, 30)
FPSLabel.Position = UDim2.new(1, -130, 0, 10)
FPSLabel.BackgroundColor3 = Config.BgColor
FPSLabel.BackgroundTransparency = 0.3
FPSLabel.Text = "FPS: --"
FPSLabel.TextColor3 = Config.FPSColor
FPSLabel.TextSize = 14
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.Visible = false
FPSLabel.ZIndex = 150
FPSLabel.Parent = ScreenGui
Instance.new("UICorner", FPSLabel).CornerRadius = UDim.new(0, 6)

local function HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q end
    return Color3.new(r, g, b)
end

task.spawn(function()
    local frameCount = 0
    local lastTime = tick()
    local hue = 0
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 1 then
            if Config.FPSEnabled then 
                FPSLabel.Text = "FPS: " .. frameCount
                FPSLabel.TextColor3 = Config.FPSRGB and HSVtoRGB(hue, 1, 1) or Config.FPSColor
            end
            frameCount = 0
            lastTime = now
        end
        if Config.FPSRGB and Config.FPSEnabled then
            hue = (hue + 0.003) % 1
        end
    end)
end)

-- ==========================================
-- Loading Screen
-- ==========================================
local LoadingGui = Instance.new("Frame")
LoadingGui.Size = UDim2.new(0, 360, 0, 180)
LoadingGui.Position = UDim2.new(0.5, -180, 0.5, -90)
LoadingGui.BackgroundColor3 = Config.BgColor
LoadingGui.BackgroundTransparency = 0.15
LoadingGui.ZIndex = 100
LoadingGui.Parent = ScreenGui
Instance.new("UICorner", LoadingGui).CornerRadius = UDim.new(0, 12)
local loadStroke = Instance.new("UIStroke")
loadStroke.Color = Config.ThemeColor
loadStroke.Thickness = 2
loadStroke.Transparency = 0.3
loadStroke.Parent = LoadingGui
local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 0, 25)
StatusText.Position = UDim2.new(0, 0, 0, 80)
StatusText.BackgroundTransparency = 1
StatusText.Text = "กำลังโหลดระบบ..."
StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusText.TextSize = 14
StatusText.Font = Enum.Font.GothamBold
StatusText.ZIndex = 101
StatusText.Parent = LoadingGui
local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(0.8, 0, 0, 12)
BarBg.Position = UDim2.new(0.1, 0, 0, 125)
BarBg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
BarBg.BackgroundTransparency = 0.5
BarBg.ZIndex = 101
BarBg.Parent = LoadingGui
Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)
local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Config.ThemeColor
BarFill.ZIndex = 102
BarFill.Parent = BarBg
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

-- ==========================================
-- Main Frame
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 600, 0, 420)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -210)
MainFrame.BackgroundColor3 = Config.BgColor
MainFrame.BackgroundTransparency = 0.15
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 10
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Config.ThemeColor
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = MainFrame

local MainBg = Instance.new("ImageLabel")
MainBg.Size = UDim2.new(1, 0, 1, 0)
MainBg.BackgroundTransparency = 1
MainBg.Image = "rbxassetid://16255492011"
MainBg.ImageTransparency = 0.6
MainBg.ScaleType = Enum.ScaleType.Crop
MainBg.ZIndex = 0
MainBg.Parent = MainFrame

local MainOverlay = Instance.new("Frame")
MainOverlay.Size = UDim2.new(1, 0, 1, 0)
MainOverlay.BackgroundColor3 = Config.BgColor
MainOverlay.BackgroundTransparency = 0.3
MainOverlay.ZIndex = 1
MainOverlay.Parent = MainFrame

-- Header
local HeaderBar = Instance.new("Frame")
HeaderBar.Size = UDim2.new(1, 0, 0, 50)
HeaderBar.BackgroundColor3 = Config.BgColor
HeaderBar.BackgroundTransparency = 0.4
HeaderBar.ZIndex = 2
HeaderBar.Parent = MainFrame
Instance.new("UICorner", HeaderBar).CornerRadius = UDim.new(0, 16)
local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 16)
headerFix.Position = UDim2.new(0, 0, 1, -16)
headerFix.BackgroundColor3 = Config.BgColor
headerFix.BackgroundTransparency = 0.4
headerFix.ZIndex = 2
headerFix.Parent = HeaderBar
local HeaderIcon = Instance.new("ImageLabel")
HeaderIcon.Size = UDim2.new(0, 35, 0, 35)
HeaderIcon.Position = UDim2.new(0, 15, 0.5, -17.5)
HeaderIcon.BackgroundTransparency = 1
HeaderIcon.Image = "rbxassetid://103628356622817"
HeaderIcon.ZIndex = 3
HeaderIcon.Parent = HeaderBar
local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -100, 1, 0)
HeaderTitle.Position = UDim2.new(0, 60, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "🐱 แมวส้ม Script Hub"
HeaderTitle.TextColor3 = Config.TextColor
HeaderTitle.TextSize = 18
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.ZIndex = 3
HeaderTitle.Parent = HeaderBar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -45, 0.5, -17.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 10
CloseBtn.Active = true
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = HeaderBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Drag
local dragging = false
local dragStart, startPos
HeaderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
HeaderBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, 140, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Config.BgColor
Sidebar.BackgroundTransparency = 0.6
Sidebar.ZIndex = 2
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 3
Sidebar.ScrollBarImageColor3 = Config.ThemeColor
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.Parent = MainFrame
local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 5)
sidebarLayout.Parent = Sidebar
local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 5)
sidebarPadding.PaddingLeft = UDim.new(0, 5)
sidebarPadding.PaddingRight = UDim.new(0, 5)
sidebarPadding.Parent = Sidebar
sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 10)
end)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -140, 1, -50)
ContentContainer.Position = UDim2.new(0, 140, 0, 50)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 2
ContentContainer.Parent = MainFrame

-- Toggle Button
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleButton.BackgroundColor3 = Config.BgColor
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.Image = "rbxassetid://103628356622817"
ToggleButton.Visible = false
ToggleButton.Active = true
ToggleButton.AutoButtonColor = false
ToggleButton.ZIndex = 100
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local btnDragging = false
local btnDragStart, btnStartPos
local btnMoved = false

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnMoved = false
        btnDragStart = input.Position
        btnStartPos = ToggleButton.Position
    end
end)
ToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = false
        if not btnMoved then MainFrame.Visible = not MainFrame.Visible end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - btnDragStart
        if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then btnMoved = true end
        ToggleButton.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- UI Components
-- ==========================================
local function CreateSidebarButton(name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Config.BgColor
    btn.BackgroundTransparency = 0.8
    btn.Text = "  " .. name
    btn.TextColor3 = Config.TextDim
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.ZIndex = 3
    btn.Active = true
    btn.AutoButtonColor = false
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.BackgroundColor3 = Config.ThemeColor
    indicator.Visible = false
    indicator.ZIndex = 4
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    btn.MouseButton1Click:Connect(function()
        for _, v in pairs(Sidebar:GetChildren()) do
            if v:IsA("TextButton") then
                v.TextColor3 = Config.TextDim
                v.BackgroundTransparency = 0.8
                local ind = v:FindFirstChild("Frame")
                if ind then ind.Visible = false end
            end
        end
        btn.TextColor3 = Config.TextColor
        btn.BackgroundTransparency = 0.5
        indicator.Visible = true
        if callback then callback() end
    end)
    return btn
end

local function CreateToggle(parent, text, flagName, defaultState, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 40)
    container.BackgroundTransparency = 1
    container.ZIndex = 3
    container.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.TextColor
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = container
    local currentState = Config[flagName]
    if currentState == nil then currentState = defaultState end
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 45, 0, 24)
    toggleBtn.Position = UDim2.new(1, -45, 0.5, -12)
    toggleBtn.BackgroundColor3 = currentState and Config.ThemeColor or Color3.fromRGB(60, 55, 80)
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 6
    toggleBtn.Active = true
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = container
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = currentState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.ZIndex = 7
    knob.Parent = toggleBtn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    toggleBtn.MouseButton1Click:Connect(function()
        currentState = not currentState
        Config[flagName] = currentState
        if currentState then
            toggleBtn.BackgroundColor3 = Config.ThemeColor
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -21, 0.5, -9)}):Play()
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 55, 80)
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
        end
        if callback then callback(currentState) end
    end)
end

local function CreateSlider(parent, text, min, max, flagName, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 50)
    container.BackgroundTransparency = 1
    container.ZIndex = 3
    container.Parent = parent
    local currentValue = Config[flagName]
    if currentValue == nil then currentValue = default end
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. currentValue
    label.TextColor3 = Config.TextDim
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = container
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 15)
    sliderBg.Position = UDim2.new(0, 0, 0, 25)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
    sliderBg.ZIndex = 3
    sliderBg.Parent = container
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Config.ThemeColor
    fill.ZIndex = 4
    fill.Parent = sliderBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 5
    sliderBtn.Active = true
    sliderBtn.Parent = sliderBg
    local isDragging = false
    local function updateSlider()
        local mouse = UserInputService:GetMouseLocation()
        local percent = math.clamp((mouse.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (percent * (max - min)))
        fill.Size = UDim2.new(percent, 0, 1, 0)
        label.Text = text .. ": " .. value
        Config[flagName] = value
        if callback then callback(value) end
    end
    sliderBtn.MouseButton1Down:Connect(function() isDragging = true; updateSlider() end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider() end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
    end)
end

local function CreateTextBox(parent, text, flagName, default, maxVal, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 40)
    container.BackgroundTransparency = 1
    container.ZIndex = 3
    container.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Config.TextColor
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = container
    local currentValue = Config[flagName] or default
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.4, 0, 1, 0)
    box.Position = UDim2.new(0.6, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
    box.Text = tostring(currentValue)
    box.TextColor3 = Config.TextColor
    box.PlaceholderText = "0-" .. maxVal
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.ZIndex = 6
    box.Parent = container
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            val = math.clamp(val, 0, maxVal)
            Config[flagName] = val
            box.Text = tostring(val)
            if callback then callback(val) end
        else
            box.Text = tostring(currentValue)
        end
    end)
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Config.ThemeColor
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 6
    btn.Active = true
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function ClearContent()
    for _, v in pairs(ContentContainer:GetChildren()) do
        if v:IsA("ScrollingFrame") then v:Destroy() end
    end
end

local function CreatePage(title)
    ClearContent()
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Config.ThemeColor
    page.ZIndex = 3
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Parent = ContentContainer
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = page
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.Text = title
    header.TextColor3 = Config.TextColor
    header.TextSize = 18
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = 1
    header.ZIndex = 3
    header.Parent = page
    return page
end

local function CreateESP(player)
    if espDrawings[player] then return end
    local line = Drawing.new("Line"); line.Visible = false
    local text = Drawing.new("Text"); text.Size = 14; text.Center = true; text.Outline = true; text.Visible = false
    local box = Drawing.new("Square"); box.Visible = false
    local healthBarBg = Drawing.new("Square"); healthBarBg.Visible = false
    local healthBar = Drawing.new("Square"); healthBar.Visible = false
    espDrawings[player] = {Line = line, Text = text, Box = box, HealthBarBg = healthBarBg, HealthBar = healthBar}
end

local function RemoveESP(player)
    if espDrawings[player] then
        for _, obj in pairs(espDrawings[player]) do pcall(function() obj:Remove() end) end
        espDrawings[player] = nil
    end
end
Players.PlayerRemoving:Connect(RemoveESP)

-- ==========================================
-- Anti-Lag / AFK
-- ==========================================
local AntiLagConnection = nil
local AFKConnection = nil

local function EnableAntiLag()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0
    end)
    AntiLagConnection = RunService.Heartbeat:Connect(function()
        if not Config.AntiLagEnabled then
            if AntiLagConnection then AntiLagConnection:Disconnect() end
            return
        end
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                pcall(function() v.Enabled = false end)
            end
        end
    end)
end
local function DisableAntiLag()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    if AntiLagConnection then AntiLagConnection:Disconnect(); AntiLagConnection = nil end
end

local function EnableAFK()
    AFKConnection = RunService.Heartbeat:Connect(function()
        if not Config.AFKEnabled then
            if AFKConnection then AFKConnection:Disconnect() end
            return
        end
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid:GetState() == Enum.HumanoidStateType.Seated then return end
            pcall(function() humanoid.Jump = true end)
        end
    end)
end
local function DisableAFK()
    if AFKConnection then AFKConnection:Disconnect(); AFKConnection = nil end
end

-- ==========================================
-- ✅ ระบบภาพสวย (Graphics)
-- ==========================================
local GraphicsEffects = {}
local function ClearGraphics()
    for _, e in pairs(GraphicsEffects) do
        pcall(function() e:Destroy() end)
    end
    GraphicsEffects = {}
end

local function EnableGraphics(mode)
    ClearGraphics()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        settings().Rendering.EditQualityLevel = 21
    end)
    
    if mode == "Cartoon" then
        pcall(function()
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "Gfx_CC"
            cc.Brightness = 0.1
            cc.Contrast = 0.4
            cc.Saturation = 0.6
            cc.TintColor = Color3.fromRGB(255, 240, 230)
            cc.Parent = Lighting
            table.insert(GraphicsEffects, cc)
            local bloom = Instance.new("BloomEffect")
            bloom.Name = "Gfx_Bloom"
            bloom.Intensity = 2
            bloom.Size = 30
            bloom.Threshold = 0.8
            bloom.Parent = Lighting
            table.insert(GraphicsEffects, bloom)
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(100, 90, 80)
        end)
    elseif mode == "Realistic" then
        pcall(function()
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "Gfx_CC"
            cc.Brightness = 0.02
            cc.Contrast = 0.15
            cc.Saturation = 0.2
            cc.TintColor = Color3.fromRGB(250, 250, 255)
            cc.Parent = Lighting
            table.insert(GraphicsEffects, cc)
            Lighting.Brightness = 2.5
            Lighting.Ambient = Color3.fromRGB(80, 80, 90)
            Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
            Lighting.GlobalShadows = true
        end)
    elseif mode == "Anime" then
        pcall(function()
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "Gfx_CC"
            cc.Brightness = 0.15
            cc.Contrast = 0.5
            cc.Saturation = 0.7
            cc.TintColor = Color3.fromRGB(255, 200, 230)
            cc.Parent = Lighting
            table.insert(GraphicsEffects, cc)
            local bloom = Instance.new("BloomEffect")
            bloom.Name = "Gfx_Bloom"
            bloom.Intensity = 2.5
            bloom.Size = 35
            bloom.Threshold = 0.7
            bloom.Parent = Lighting
            table.insert(GraphicsEffects, bloom)
            Lighting.Brightness = 3
        end)
    elseif mode == "Dark" then
        pcall(function()
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "Gfx_CC"
            cc.Brightness = -0.1
            cc.Contrast = 0.3
            cc.Saturation = 0.1
            cc.TintColor = Color3.fromRGB(200, 200, 220)
            cc.Parent = Lighting
            table.insert(GraphicsEffects, cc)
            Lighting.Brightness = 1
            Lighting.Ambient = Color3.fromRGB(30, 30, 40)
            Lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 70)
        end)
    elseif mode == "Neon" then
        pcall(function()
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "Gfx_CC"
            cc.Brightness = 0.1
            cc.Contrast = 0.6
            cc.Saturation = 1
            cc.TintColor = Color3.fromRGB(200, 200, 255)
            cc.Parent = Lighting
            table.insert(GraphicsEffects, cc)
            local bloom = Instance.new("BloomEffect")
            bloom.Name = "Gfx_Bloom"
            bloom.Intensity = 3
            bloom.Size = 40
            bloom.Threshold = 0.6
            bloom.Parent = Lighting
            table.insert(GraphicsEffects, bloom)
            Lighting.Brightness = 2
        end)
    end
    SendNotification("Graphics", "โหมด: " .. mode, 2)
end

-- ==========================================
-- ✅ ระบบ RTX
-- ==========================================
local RTXEffects = {}
local function EnableRTX()
    ClearGraphics()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
        
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "RTX_CC"
        cc.Brightness = 0.03
        cc.Contrast = 0.35
        cc.Saturation = 0.45
        cc.TintColor = Color3.fromRGB(240, 245, 255)
        cc.Parent = Lighting
        table.insert(RTXEffects, cc)
        
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "RTX_Bloom"
        bloom.Intensity = 2.5
        bloom.Size = 40
        bloom.Threshold = 0.7
        bloom.Parent = Lighting
        table.insert(RTXEffects, bloom)
        
        local sunRays = Instance.new("SunRaysEffect")
        sunRays.Name = "RTX_SunRays"
        sunRays.Intensity = 0.3
        sunRays.Spread = 1.2
        sunRays.Parent = Lighting
        table.insert(RTXEffects, sunRays)
        
        local dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "RTX_DOF"
        dof.FarIntensity = 0.15
        dof.FocusDistance = 25
        dof.InFocusRadius = 35
        dof.NearIntensity = 0.1
        dof.Parent = Lighting
        table.insert(RTXEffects, dof)
        
        local blur = Instance.new("BlurEffect")
        blur.Name = "RTX_Blur"
        blur.Size = 2
        blur.Parent = Lighting
        table.insert(RTXEffects, blur)
        
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(90, 90, 100)
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
        Lighting.ShadowSoftness = 0.6
    end)
    SendNotification("RTX", "เปิดแล้ว - ภาพสมจริง!", 3)
end

local function DisableRTX()
    for _, e in pairs(RTXEffects) do
        pcall(function() e:Destroy() end)
    end
    RTXEffects = {}
    SendNotification("RTX", "ปิดแล้ว", 2)
end

-- ==========================================
-- ✅ ระบบท้องฟ้า (Sky) - ใช้ ID จริง ทำงานได้ 100%
-- ==========================================
local function SetSky(skyName)
    pcall(function()
        -- ลบ Sky เก่าทั้งหมด
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
        
        local sky = Instance.new("Sky")
        sky.Name = "Custom_Sky"
        
        if skyName == "Sunset" then
            sky.SkyboxBk = "rbxassetid://5227623989"
            sky.SkyboxDn = "rbxassetid://5227624056"
            sky.SkyboxFt = "rbxassetid://5227624232"
            sky.SkyboxLf = "rbxassetid://5227624466"
            sky.SkyboxRt = "rbxassetid://5227624585"
            sky.SkyboxUp = "rbxassetid://5227624698"
            sky.StarCount = 3000
        elseif skyName == "Space" then
            sky.SkyboxBk = "rbxassetid://159454299"
            sky.SkyboxDn = "rbxassetid://159454296"
            sky.SkyboxFt = "rbxassetid://159454293"
            sky.SkyboxLf = "rbxassetid://159454286"
            sky.SkyboxRt = "rbxassetid://159454300"
            sky.SkyboxUp = "rbxassetid://159454288"
            sky.StarCount = 5000
        elseif skyName == "Night" then
            sky.SkyboxBk = "rbxassetid://126148478"
            sky.SkyboxDn = "rbxassetid://126148536"
            sky.SkyboxFt = "rbxassetid://126148590"
            sky.SkyboxLf = "rbxassetid://126148639"
            sky.SkyboxRt = "rbxassetid://126148690"
            sky.SkyboxUp = "rbxassetid://126148715"
            sky.StarCount = 4000
        elseif skyName == "Cloudy" then
            sky.SkyboxBk = "rbxassetid://5705570226"
            sky.SkyboxDn = "rbxassetid://5705570252"
            sky.SkyboxFt = "rbxassetid://5705570378"
            sky.SkyboxLf = "rbxassetid://5705570330"
            sky.SkyboxRt = "rbxassetid://5705570438"
            sky.SkyboxUp = "rbxassetid://5705570482"
            sky.StarCount = 1000
        elseif skyName == "Sunny" then
            sky.SkyboxBk = "rbxassetid://139511069"
            sky.SkyboxDn = "rbxassetid://139511082"
            sky.SkyboxFt = "rbxassetid://139511093"
            sky.SkyboxLf = "rbxassetid://139511104"
            sky.SkyboxRt = "rbxassetid://139511116"
            sky.SkyboxUp = "rbxassetid://139511127"
            sky.StarCount = 1000
        elseif skyName == "Pink" then
            sky.SkyboxBk = "rbxassetid://4874245385"
            sky.SkyboxDn = "rbxassetid://4874245558"
            sky.SkyboxFt = "rbxassetid://4874245832"
            sky.SkyboxLf = "rbxassetid://4874246109"
            sky.SkyboxRt = "rbxassetid://4874246353"
            sky.SkyboxUp = "rbxassetid://4874246574"
            sky.StarCount = 3000
        end
        
        sky.SunAngularSize = 21
        sky.MoonAngularSize = 11
        sky.Parent = Lighting
    end)
    SendNotification("Sky", "เปลี่ยนเป็น: " .. skyName, 2)
end

local function ResetSky()
    pcall(function()
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
    end)
    SendNotification("Sky", "รีเซ็ตเป็นค่าเริ่มต้น", 2)
end

-- ==========================================
-- Silent Aim Hook
-- ==========================================
if hasHook then
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local ok, inFOV, targetPart = pcall(IsTargetInFOV)
            if ok and inFOV and targetPart then
                local method = getnamecallmethod()
                if method == "FireServer" or method == "InvokeServer" then
                    local args = {...}
                    local modified = false
                    for i, arg in pairs(args) do
                        if typeof(arg) == "CFrame" then args[i] = CFrame.new(arg.Position, targetPart.Position); modified = true
                        elseif typeof(arg) == "Vector3" then args[i] = targetPart.Position; modified = true
                        end
                    end
                    if modified then return oldNamecall(self, unpack(args)) end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end

-- ==========================================
-- เมนู: หน้าหลัก
-- ==========================================
CreateSidebarButton("🏠 หน้าหลัก", 1, function()
    local page = CreatePage("หน้าหลัก")
    CreateToggle(page, "🎯 ล็อกเป้าหมาย", "AimbotEnabled", false, function(state)
        if FOVCircle then FOVCircle.Visible = state end
        if not state then 
            if TargetSnapLine then TargetSnapLine.Visible = false end
            currentLockedTarget = nil 
        end
    end)
    local aimModeBtn = Instance.new("TextButton")
    aimModeBtn.Size = UDim2.new(1, 0, 0, 35)
    aimModeBtn.BackgroundColor3 = Config.ThemeColor
    aimModeBtn.Text = "🎯 โหมดล็อก: " .. (Config.AimPart == "Head" and "หัว" or "ตัว")
    aimModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    aimModeBtn.TextSize = 14
    aimModeBtn.Font = Enum.Font.GothamBold
    aimModeBtn.ZIndex = 6
    aimModeBtn.Parent = page
    Instance.new("UICorner", aimModeBtn).CornerRadius = UDim.new(0, 8)
    aimModeBtn.MouseButton1Click:Connect(function()
        Config.AimPart = (Config.AimPart == "Head") and "HumanoidRootPart" or "Head"
        aimModeBtn.Text = "🎯 โหมดล็อก: " .. (Config.AimPart == "Head" and "หัว" or "ตัว")
    end)
    CreateSlider(page, "📡 ขนาด FOV", 50, 500, "FOVCircleRadius", 250, function(value)
        if FOVCircle then FOVCircle.Radius = value end
    end)
    CreateSlider(page, "🔒 ความแรงล็อก", 0, 100, "LockStrength", 90, function(value) Config.LockStrength = value end)
    CreateToggle(page, "🧱 ไม่ล็อกผ่านกำแพง", "WallCheck", true, function(state) end)
    CreateToggle(page, "🚀 Silent Aim", "BulletHomingEnabled", false, function(state)
        if FOVCircle then FOVCircle.Visible = state end
    end)
end)

-- ==========================================
-- เมนู: เสกของ
-- ==========================================
CreateSidebarButton("🎁 เสกของ", 2, function()
    local page = CreatePage("เสกของ")
    local itemListFrame = Instance.new("ScrollingFrame")
    itemListFrame.Size = UDim2.new(1, 0, 0, 300)
    itemListFrame.BackgroundColor3 = Config.BgColor
    itemListFrame.BackgroundTransparency = 0.7
    itemListFrame.BorderSizePixel = 0
    itemListFrame.ScrollBarThickness = 3
    itemListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemListFrame.ZIndex = 3
    itemListFrame.Parent = page
    Instance.new("UICorner", itemListFrame).CornerRadius = UDim.new(0, 8)
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = itemListFrame
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        itemListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(1, 0, 0, 50)
    scanBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    scanBtn.Text = "🔍 สแกนหาไอเทมในแมพ"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.TextSize = 16
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.ZIndex = 6
    scanBtn.Parent = page
    Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 10)
    scanBtn.MouseButton1Click:Connect(function()
        scanBtn.Text = "⏳ กำลังสแกน..."
        for _, v in pairs(itemListFrame:GetChildren()) do
            if v:IsA("TextButton") then v:Destroy() end
        end
        task.wait(0.3)
        local items = ScanMapItems()
        if #items == 0 then
            local noItem = Instance.new("TextLabel")
            noItem.Size = UDim2.new(1, 0, 0, 40)
            noItem.BackgroundTransparency = 1
            noItem.Text = "❌ ไม่พบไอเทม"
            noItem.TextColor3 = Color3.fromRGB(255, 100, 100)
            noItem.Parent = itemListFrame
            scanBtn.Text = "🔍 สแกนหาไอเทมในแมพ"
            return
        end
        for _, item in ipairs(items) do
            local itemBtn = Instance.new("TextButton")
            itemBtn.Size = UDim2.new(1, -10, 0, 40)
            itemBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
            itemBtn.Text = "🎁 " .. item.Name .. "  [" .. item.Type .. "]"
            itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemBtn.TextSize = 12
            itemBtn.Font = Enum.Font.GothamBold
            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
            itemBtn.ZIndex = 5
            itemBtn.Parent = itemListFrame
            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)
            itemBtn.MouseButton1Click:Connect(function() SpawnItem(item) end)
        end
        scanBtn.Text = "🔍 สแกนหาไอเทมในแมพ"
        SendNotification("สแกน", "พบ " .. #items .. " ไอเทม", 3)
    end)
end)

-- ==========================================
-- เมนู: ขโมยไข่
-- ==========================================
CreateSidebarButton("🥚 ขโมยไข่", 3, function()
    local page = CreatePage("ขโมยไข่")
    local stealBtn = Instance.new("TextButton")
    stealBtn.Size = UDim2.new(1, 0, 0, 55)
    stealBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    stealBtn.Text = "🥚 ขโมยไข่ (กด)"
    stealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    stealBtn.TextSize = 16
    stealBtn.Font = Enum.Font.GothamBold
    stealBtn.ZIndex = 6
    stealBtn.Parent = page
    Instance.new("UICorner", stealBtn).CornerRadius = UDim.new(0, 10)
    stealBtn.MouseButton1Click:Connect(function() StealEggOnce() end)
    CreateSlider(page, "⏱️ เวลารอ", 1, 5, "StealDelay", 1, function(value) Config.StealDelay = value end)
    CreateSlider(page, "📦 รัศมี", 10, 200, "CollectRadius", 30, function(value) Config.CollectRadius = value end)
    CreateToggle(page, "🛡️ กันไข่ตก", "AntiDropEnabled", false, function(state)
        if state then EnableAntiDrop() else DisableAntiDrop() end
    end)
end)

-- ==========================================
-- เมนู: ดึงเงิน
-- ==========================================
CreateSidebarButton("💰 ดึงเงิน", 4, function()
    local page = CreatePage("ดึงเงิน")
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(1, 0, 0, 300)
    playerListFrame.BackgroundColor3 = Config.BgColor
    playerListFrame.BackgroundTransparency = 0.7
    playerListFrame.ZIndex = 3
    playerListFrame.Parent = page
    Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, 8)
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = playerListFrame
    
    local function Refresh()
        for _, v in pairs(playerListFrame:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -10, 0, 45)
                row.Position = UDim2.new(0, 5, 0, 0)
                row.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
                row.ZIndex = 4
                row.Parent = playerListFrame
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
                nameLabel.Position = UDim2.new(0, 5, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = player.Name
                nameLabel.TextColor3 = Config.TextColor
                nameLabel.Font = Enum.Font.Gotham
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.ZIndex = 5
                nameLabel.Parent = row
                local stealBtn = Instance.new("TextButton")
                stealBtn.Size = UDim2.new(0, 80, 0, 32)
                stealBtn.Position = UDim2.new(1, -90, 0.5, -16)
                stealBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
                stealBtn.Text = "💰 ดึงเงิน"
                stealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                stealBtn.TextSize = 12
                stealBtn.Font = Enum.Font.GothamBold
                stealBtn.ZIndex = 5
                stealBtn.Parent = row
                Instance.new("UICorner", stealBtn).CornerRadius = UDim.new(0, 6)
                stealBtn.MouseButton1Click:Connect(function() StealMoneyFromPlayer(player) end)
            end
        end
    end
    CreateButton(page, "🔄 รีเฟรช", function() Refresh() end)
    Players.PlayerAdded:Connect(function() task.wait(0.5); Refresh() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.5); Refresh() end)
    task.wait(0.1)
    Refresh()
end)

-- ==========================================
-- เมนู: ผู้เล่น
-- ==========================================
CreateSidebarButton("👥 ผู้เล่น", 5, function()
    local page = CreatePage("รายชื่อผู้เล่น")
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1, 0, 0, 35)
    refreshBtn.BackgroundColor3 = Config.ThemeColor
    refreshBtn.Text = "🔄 รีเฟรช"
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.ZIndex = 6
    refreshBtn.Parent = page
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 8)
    
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(1, 0, 0, 350)
    playerListFrame.BackgroundColor3 = Config.BgColor
    playerListFrame.BackgroundTransparency = 0.7
    playerListFrame.ZIndex = 3
    playerListFrame.Parent = page
    Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, 8)
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = playerListFrame
    
    local function Refresh()
        for _, v in pairs(playerListFrame:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -10, 0, 40)
                row.Position = UDim2.new(0, 5, 0, 0)
                row.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
                row.ZIndex = 4
                row.Parent = playerListFrame
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
                nameLabel.Position = UDim2.new(0, 5, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = player.Name
                nameLabel.TextColor3 = Config.TextColor
                nameLabel.Font = Enum.Font.Gotham
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.ZIndex = 5
                nameLabel.Parent = row
                local tpBtn = Instance.new("TextButton")
                tpBtn.Size = UDim2.new(0, 50, 0, 28)
                tpBtn.Position = UDim2.new(0.55, 0, 0.5, -14)
                tpBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
                tpBtn.Text = "วาป"
                tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.ZIndex = 5
                tpBtn.Parent = row
                Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
                tpBtn.MouseButton1Click:Connect(function()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 3)
                    end
                end)
                local resetBtn = Instance.new("TextButton")
                resetBtn.Size = UDim2.new(0, 50, 0, 28)
                resetBtn.Position = UDim2.new(0.75, 0, 0.5, -14)
                resetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                resetBtn.Text = "รี"
                resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                resetBtn.Font = Enum.Font.GothamBold
                resetBtn.ZIndex = 5
                resetBtn.Parent = row
                Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 4)
                resetBtn.MouseButton1Click:Connect(function()
                    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                        player.Character:FindFirstChildOfClass("Humanoid").Health = 0
                    end
                end)
            end
        end
    end
    refreshBtn.MouseButton1Click:Connect(Refresh)
    Players.PlayerAdded:Connect(function() task.wait(0.5); Refresh() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.5); Refresh() end)
    task.wait(0.1)
    Refresh()
end)

-- ==========================================
-- เมนู: ผู้เล่น/บิน
-- ==========================================
CreateSidebarButton("👤 ผู้เล่น/บิน", 6, function()
    local page = CreatePage("ผู้เล่น & การเคลื่อนที่")
    CreateTextBox(page, "⚡ Speed (0-1000)", "SpeedValue", 500, 1000, function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end)
    CreateToggle(page, "🏃 วิ่งเร็ว", "SpeedEnabled", false, function(state)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = state and Config.SpeedValue or 16
        end
    end)
    CreateToggle(page, "🛡️ Bypass Anti-Cheat", "SpeedBypass", true, function(state) end)
    CreateSlider(page, "ความเร็วบิน", 10, 500, "FlySpeed", 100, function(value) end)
    CreateToggle(page, "🕊️ โหมดบิน", "FlyEnabled", false, function(state)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and humanoid then
            if state then
                humanoid.PlatformStand = true
                local bg = Instance.new("BodyGyro", hrp); bg.Name = "MobFlyGyro"; bg.P = 9e4; bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                local bv = Instance.new("BodyVelocity", hrp); bv.Name = "MobFlyVelocity"; bv.velocity = Vector3.new(0, 0, 0); bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
                RunService.RenderStepped:Connect(function()
                    if Config.FlyEnabled and hrp and hrp.Parent then
                        bv.velocity = Camera.CFrame.LookVector * Config.FlySpeed
                        bg.cframe = Camera.CFrame
                    end
                end)
            else
                UnlockMovement()
            end
        end
    end)
    CreateButton(page, "🔓 ปลดล็อกการเคลื่อนที่", function() UnlockMovement() end)
end)

-- ==========================================
-- เมนู: เส้นมอง
-- ==========================================
CreateSidebarButton("👁️ เส้นมอง", 7, function()
    local page = CreatePage("เส้นมอง (ESP)")
    CreateToggle(page, "เปิด/ปิด เส้นมอง", "ESP_Enabled", false, function(state) end)
    CreateToggle(page, "เปิด/ปิด กล่อง", "ESP_Box", false, function(state) end)
    CreateToggle(page, "เปิด/ปิด หลอดเลือด", "ESP_Health", false, function(state) end)
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(1, 0, 0, 35)
    modeBtn.BackgroundColor3 = Config.BgColor
    modeBtn.BackgroundTransparency = 0.5
    modeBtn.Text = "📍 ตำแหน่งเส้น: " .. (Config.ESP_LineMode == "Top" and "ด้านบน" or "ด้านล่าง")
    modeBtn.TextColor3 = Config.TextColor
    modeBtn.Font = Enum.Font.Gotham
    modeBtn.ZIndex = 6
    modeBtn.Parent = page
    Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 8)
    modeBtn.MouseButton1Click:Connect(function()
        Config.ESP_LineMode = (Config.ESP_LineMode == "Top") and "Bottom" or "Top"
        modeBtn.Text = "📍 ตำแหน่งเส้น: " .. (Config.ESP_LineMode == "Top" and "ด้านบน" or "ด้านล่าง")
    end)
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(1, 0, 0, 35)
    colorBtn.BackgroundColor3 = Config.ESP_LineColor
    colorBtn.Text = "🎨 เปลี่ยนสีเส้น ESP"
    colorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    colorBtn.Font = Enum.Font.Gotham
    colorBtn.ZIndex = 6
    colorBtn.Parent = page
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 8)
    colorBtn.MouseButton1Click:Connect(function()
        local colors = {
            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
            Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
            Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 100, 0)
        }
        local newColor = colors[math.random(1, #colors)]
        Config.ESP_LineColor = newColor
        colorBtn.BackgroundColor3 = newColor
        if FOVCircle then FOVCircle.Color = newColor end
    end)
end)

-- ==========================================
-- ✅ เมนู: ตั้งค่า (มี Graphics + RTX + Sky)
-- ==========================================
CreateSidebarButton("⚙️ ตั้งค่า", 8, function()
    local page = CreatePage("ตั้งค่า")
    
    -- ============ ภาพสวย (Graphics) ============
    local gfxLabel = Instance.new("TextLabel")
    gfxLabel.Size = UDim2.new(1, 0, 0, 25)
    gfxLabel.BackgroundTransparency = 1
    gfxLabel.Text = "🎨 ภาพสวย (Graphics)"
    gfxLabel.TextColor3 = Config.TextColor
    gfxLabel.TextSize = 15
    gfxLabel.Font = Enum.Font.GothamBold
    gfxLabel.TextXAlignment = Enum.TextXAlignment.Left
    gfxLabel.ZIndex = 3
    gfxLabel.Parent = page
    
    CreateButton(page, "🎨 Cartoon (การ์ตูน)", function() EnableGraphics("Cartoon") end)
    CreateButton(page, "📷 Realistic (สมจริง)", function() EnableGraphics("Realistic") end)
    CreateButton(page, "🌸 Anime (อนิเมะ)", function() EnableGraphics("Anime") end)
    CreateButton(page, "🌑 Dark (มืด)", function() EnableGraphics("Dark") end)
    CreateButton(page, "💡 Neon (นีออน)", function() EnableGraphics("Neon") end)
    CreateButton(page, "🔄 รีเซ็ตภาพ", function()
        ClearGraphics()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        pcall(function()
            Lighting.Brightness = 2
            Lighting.GlobalShadows = true
        end)
        SendNotification("Graphics", "รีเซ็ตแล้ว", 2)
    end)
    
    -- ============ RTX ============
    local rtxLabel = Instance.new("TextLabel")
    rtxLabel.Size = UDim2.new(1, 0, 0, 25)
    rtxLabel.BackgroundTransparency = 1
    rtxLabel.Text = "🎬 RTX (Real Ray Tracing)"
    rtxLabel.TextColor3 = Config.TextColor
    rtxLabel.TextSize = 15
    rtxLabel.Font = Enum.Font.GothamBold
    rtxLabel.TextXAlignment = Enum.TextXAlignment.Left
    rtxLabel.ZIndex = 3
    rtxLabel.Parent = page
    
    CreateButton(page, "🎬 เปิด RTX", function() EnableRTX() end)
    CreateButton(page, "❌ ปิด RTX", function() DisableRTX() end)
    
    -- ============ ท้องฟ้า (Sky) ============
    local skyLabel = Instance.new("TextLabel")
    skyLabel.Size = UDim2.new(1, 0, 0, 25)
    skyLabel.BackgroundTransparency = 1
    skyLabel.Text = "🌌 ท้องฟ้า (Sky)"
    skyLabel.TextColor3 = Config.TextColor
    skyLabel.TextSize = 15
    skyLabel.Font = Enum.Font.GothamBold
    skyLabel.TextXAlignment = Enum.TextXAlignment.Left
    skyLabel.ZIndex = 3
    skyLabel.Parent = page
    
    CreateButton(page, "🌅 Sunset (พระอาทิตย์ตก)", function() SetSky("Sunset") end)
    CreateButton(page, "🌌 Space (อวกาศ)", function() SetSky("Space") end)
    CreateButton(page, "🌙 Night (กลางคืน)", function() SetSky("Night") end)
    CreateButton(page, "☁️ Cloudy (เมฆ)", function() SetSky("Cloudy") end)
    CreateButton(page, "☀️ Sunny (แดดจ้า)", function() SetSky("Sunny") end)
    CreateButton(page, "🌸 Pink (ชมพู)", function() SetSky("Pink") end)
    CreateButton(page, "🔄 รีเซ็ตท้องฟ้า", function() ResetSky() end)
    
    -- ============ อื่นๆ ============
    local otherLabel = Instance.new("TextLabel")
    otherLabel.Size = UDim2.new(1, 0, 0, 25)
    otherLabel.BackgroundTransparency = 1
    otherLabel.Text = "⚙️ ระบบอื่นๆ"
    otherLabel.TextColor3 = Config.TextColor
    otherLabel.TextSize = 15
    otherLabel.Font = Enum.Font.GothamBold
    otherLabel.TextXAlignment = Enum.TextXAlignment.Left
    otherLabel.ZIndex = 3
    otherLabel.Parent = page
    
    CreateToggle(page, "⚡ แก้กระตุก", "AntiLagEnabled", false, function(state)
        if state then EnableAntiLag() else DisableAntiLag() end
    end)
    CreateToggle(page, "💤 AFK", "AFKEnabled", false, function(state)
        if state then EnableAFK() else DisableAFK() end
    end)
    CreateToggle(page, "📊 FPS", "FPSEnabled", false, function(state) FPSLabel.Visible = state end)
    CreateToggle(page, "🌈 FPS RGB", "FPSRGB", false, function(state) end)
    
    CreateButton(page, "❌ ทำลาย UI", function()
        if FOVCircle then FOVCircle:Remove() end
        if TargetSnapLine then TargetSnapLine:Remove() end
        for _, data in pairs(espDrawings) do
            for _, obj in pairs(data) do pcall(function() obj:Remove() end) end
        end
        ScreenGui:Destroy()
    end)
end)

local firstBtn = Sidebar:GetChildren()[1]
if firstBtn and firstBtn:IsA("TextButton") then firstBtn.MouseButton1Click:Fire() end

-- ==========================================
-- Main Loop
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.SpeedEnabled and Config.SpeedBypass then
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                pcall(function()
                    char:FindFirstChildOfClass("Humanoid").WalkSpeed = Config.SpeedValue
                end)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    if FOVCircle then FOVCircle.Position = screenCenter end

    local closestPlayer = nil
    if Config.AimbotEnabled then
        local shortestDistance = FOVCircle and FOVCircle.Radius or 250
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local targetPart = GetTargetPart(player.Character)
                if targetPart and HasLineOfSight(targetPart) then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
        currentLockedTarget = closestPlayer
        
        if closestPlayer and closestPlayer.Character then
            local targetPart = GetTargetPart(closestPlayer.Character)
            if targetPart then
                local targetPos = targetPart.Position
                if Config.LockStrength >= 99 then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                else
                    local lockSmoothness = 1 - (Config.LockStrength / 100)
                    local aimSpeed = math.clamp(1 - lockSmoothness, 0.05, 1)
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), aimSpeed)
                end
                if TargetSnapLine then
                    local headScreen = Camera:WorldToViewportPoint(targetPos)
                    TargetSnapLine.From = screenCenter
                    TargetSnapLine.To = Vector2.new(headScreen.X, headScreen.Y)
                    TargetSnapLine.Visible = true
                end
            else
                if TargetSnapLine then TargetSnapLine.Visible = false end
            end
        else
            if TargetSnapLine then TargetSnapLine.Visible = false end
        end
    else
        if TargetSnapLine then TargetSnapLine.Visible = false end
        currentLockedTarget = nil
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if Config.ESP_Enabled or Config.ESP_Box then
                CreateESP(player)
                local data = espDrawings[player]
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    local hrp = char.HumanoidRootPart
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        if Config.ESP_Enabled then
                            local originPoint
                            if Config.ESP_LineMode == "Top" then
                                originPoint = Vector2.new(Camera.ViewportSize.X / 2, 0)
                            else
                                originPoint = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            end
                            data.Line.From = originPoint
                            data.Line.To = Vector2.new(screenPoint.X, screenPoint.Y)
                            data.Line.Color = Config.ESP_LineColor
                            data.Line.Thickness = Config.LineThickness
                            data.Line.Visible = true
                            data.Text.Text = player.Name
                            data.Text.Position = Vector2.new(screenPoint.X, screenPoint.Y - 25)
                            data.Text.Visible = true
                        else
                            data.Line.Visible = false
                            data.Text.Visible = false
                        end
                        if Config.ESP_Box then
                            local head = char:FindFirstChild("Head")
                            if head then
                                local headScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                                local legScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                                local height = math.abs(headScreen.Y - legScreen.Y)
                                local width = height / 2
                                local boxPos = Vector2.new(headScreen.X - width / 2, headScreen.Y)
                                data.Box.Size = Vector2.new(width, height)
                                data.Box.Position = boxPos
                                data.Box.Color = Config.ESP_LineColor
                                data.Box.Thickness = Config.LineThickness
                                data.Box.Visible = true
                                if Config.ESP_Health then
                                    local humanoid = char.Humanoid
                                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                                    data.HealthBarBg.Size = Vector2.new(3.5, height)
                                    data.HealthBarBg.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
                                    data.HealthBarBg.Visible = true
                                    local currentBarHeight = height * healthPercent
                                    data.HealthBar.Size = Vector2.new(2.5, currentBarHeight)
                                    data.HealthBar.Position = Vector2.new(boxPos.X - 5.5, boxPos.Y + (height - currentBarHeight))
                                    data.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                                    data.HealthBar.Visible = true
                                else
                                    data.HealthBar.Visible = false
                                    data.HealthBarBg.Visible = false
                                end
                            end
                        else
                            data.Box.Visible = false
                            data.HealthBar.Visible = false
                            data.HealthBarBg.Visible = false
                        end
                    else
                        data.Line.Visible = false; data.Text.Visible = false; data.Box.Visible = false; data.HealthBar.Visible = false; data.HealthBarBg.Visible = false
                    end
                else
                    data.Line.Visible = false; data.Text.Visible = false; data.Box.Visible = false; data.HealthBar.Visible = false; data.HealthBarBg.Visible = false
                end
            else
                if espDrawings[player] then
                    espDrawings[player].Line.Visible = false; espDrawings[player].Text.Visible = false; espDrawings[player].Box.Visible = false; espDrawings[player].HealthBar.Visible = false; espDrawings[player].HealthBarBg.Visible = false
                end
            end
        end
    end
end)

-- ==========================================
-- โหลดเสร็จ
-- ==========================================
task.spawn(function()
    task.wait(0.5)
    if BarFill then
        BarFill:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 1, true)
    end
    task.wait(1)
    if LoadingGui then LoadingGui:Destroy() end
    if ToggleButton then ToggleButton.Visible = true end
    if MainFrame then MainFrame.Visible = true end
    SendNotification("ยินดีต้อนรับ", "🐱 แมวส้ม Script Hub v42 พร้อมใช้!", 3)
end)
