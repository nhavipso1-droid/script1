-- ==========================================
-- SCRIPT: Double Rate 100% - MOBILE EDITION
-- TỐI ƯU: Cảm ứng, nút to, dễ bấm
-- GIAO DIỆN: Switch toggle + full touch
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- State
local IsEnabled = true
local OriginalMathRandom = math.random
local Connections = {}
local MoneyValue = nil
local LastMoney = 0
local MoneyRemote = nil
local DoubleCount = 0
local FailBlocked = 0

-- ==========================================
-- CORE: TÌM TIỀN
-- ==========================================
local function FindMoney()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then ls = LocalPlayer:WaitForChild("leaderstats", 10) end
    if not ls then return nil end
    for _, c in ipairs(ls:GetChildren()) do
        if c:IsA("IntValue") then
            local n = c.Name:lower()
            if n:find("coin") or n:find("cash") or n:find("money") or n:find("gem") then
                return c
            end
        end
    end
    for _, c in ipairs(ls:GetChildren()) do
        if c:IsA("IntValue") then return c end
    end
    return nil
end

-- ==========================================
-- CORE: TÌM MONEY REMOTE
-- ==========================================
local function FindMoneyRemote()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("addcoin") or n:find("addcash") or n:find("givemoney") or
               n:find("addmoney") or n:find("updatecoin") or n:find("rewardcoin") then
                return obj
            end
        end
    end
    return nil
end

-- ==========================================
-- CORE: GỬI TIỀN SERVER
-- ==========================================
local function SendMoney(amount)
    if not amount or amount <= 0 then return end
    if MoneyRemote then
        pcall(function()
            if MoneyRemote:IsA("RemoteEvent") then
                MoneyRemote:FireServer(amount)
            else
                MoneyRemote:InvokeServer(amount)
            end
        end)
    end
    if MoneyValue then
        pcall(function() MoneyValue.Value = MoneyValue.Value + amount end)
    end
end

-- ==========================================
-- CORE: HOOK REMOTE EVENT
-- ==========================================
local function HookAll()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            pcall(function()
                local conn = obj.OnClientEvent:Connect(function(...)
                    if not IsEnabled then return end
                    local args = {...}
                    local changed = false
                    local amount = nil
                    for i = 1, #args do
                        local arg = args[i]
                        if type(arg) == "string" then
                            local u = arg:upper()
                            if u == "NOTHING" or u == "LOSE" or u == "FAIL" then
                                args[i] = "DOUBLE"; changed = true
                            end
                        end
                        if type(arg) == "boolean" and arg == false then
                            args[i] = true; changed = true
                        end
                        if type(arg) == "number" and arg == 0 then
                            for j = 1, #args do
                                if j ~= i and type(args[j]) == "number" and args[j] > 0 then
                                    args[i] = args[j] * 2; amount = args[i]; changed = true; break
                                end
                            end
                        end
                        if type(arg) == "number" and arg > 0 then amount = arg end
                    end
                    if changed then
                        FailBlocked = FailBlocked + 1
                        DoubleCount = DoubleCount + 1
                        if amount then SendMoney(amount) end
                    end
                end)
                table.insert(Connections, conn)
            end)
        end
    end
end

-- ==========================================
-- CORE: MONITOR TIỀN
-- ==========================================
local function MonitorMoney()
    MoneyValue = FindMoney()
    if not MoneyValue then return end
    LastMoney = MoneyValue.Value
    MoneyValue.Changed:Connect(function(v)
        if not IsEnabled then LastMoney = v; return end
        local diff = v - LastMoney
        if diff < 0 then
            SendMoney(math.abs(diff) * 2)
            FailBlocked = FailBlocked + 1
            DoubleCount = DoubleCount + 1
        elseif diff > 0 then
            DoubleCount = DoubleCount + 1
        end
        LastMoney = v
    end)
end

-- ==========================================
-- CORE: MATH HOOK
-- ==========================================
local function MathOn()
    math.random = function(...)
        if not IsEnabled then return OriginalMathRandom(...) end
        local n = select("#", ...)
        if n == 0 then return OriginalMathRandom() * 0.39
        elseif n == 1 then return ...
        elseif n == 2 then return select(2, ...) end
        return OriginalMathRandom(...)
    end
end

local function MathOff()
    math.random = OriginalMathRandom
end

-- ==========================================
-- BẬT / TẮT
-- ==========================================
local function Enable()
    IsEnabled = true; MathOn()
end

local function Disable()
    IsEnabled = false; MathOff()
end

local function Toggle()
    if IsEnabled then Disable() else Enable() end
    return IsEnabled
end

-- ==========================================
-- GIAO DIỆN MOBILE (SWITCH TOGGLE)
-- ==========================================
local SG = Instance.new("ScreenGui")
SG.Name = "MobileDouble"
SG.Parent = LocalPlayer:WaitForChild("PlayerGui")
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true

-- Kích thước màn hình
local screenSize = workspace.CurrentCamera.ViewportSize
local screenWidth = screenSize.X
local screenHeight = screenSize.Y

-- Panel chính
local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Parent = SG
Panel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
Panel.BorderSizePixel = 0
Panel.Size = UDim2.new(0, math.min(320, screenWidth - 20), 0, 200)
Panel.Position = UDim2.new(0.5, -math.min(320, screenWidth - 20)/2, 0.06, 0)
Panel.Active = true
Panel.Draggable = true

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 20)
PanelCorner.Parent = Panel

-- Viền
local PanelStroke = Instance.new("UIStroke")
PanelStroke.Parent = Panel
PanelStroke.Thickness = 1.5
PanelStroke.Color = Color3.fromRGB(50, 55, 65)

-- Tiêu đề
local Title = Instance.new("TextLabel")
Title.Parent = Panel
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -40, 0, 36)
Title.Position = UDim2.new(0, 20, 0, 14)
Title.Font = Enum.Font.GothamBold
Title.Text = "🎰 DOUBLE RATE 100%"
Title.TextColor3 = Color3.fromRGB(255, 210, 50)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

-- ==========================================
-- THÔNG TIN TỈ LỆ
-- ==========================================
local RateFrame = Instance.new("Frame")
RateFrame.Parent = Panel
RateFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
RateFrame.BorderSizePixel = 0
RateFrame.Size = UDim2.new(1, -40, 0, 50)
RateFrame.Position = UDim2.new(0, 20, 0, 56)

local RateCorner = Instance.new("UICorner")
RateCorner.CornerRadius = UDim.new(0, 12)
RateCorner.Parent = RateFrame

local RateLeft = Instance.new("TextLabel")
RateLeft.Parent = RateFrame
RateLeft.BackgroundTransparency = 1
RateLeft.Size = UDim2.new(0.5, -5, 0, 22)
RateLeft.Position = UDim2.new(0, 10, 0, 4)
RateLeft.Font = Enum.Font.GothamBold
RateLeft.Text = "Gốc: 40%"
RateLeft.TextColor3 = Color3.fromRGB(255, 110, 110)
RateLeft.TextSize = 14
RateLeft.TextXAlignment = Enum.TextXAlignment.Left

local RateRight = Instance.new("TextLabel")
RateRight.Name = "RateRight"
RateRight.Parent = RateFrame
RateRight.BackgroundTransparency = 1
RateRight.Size = UDim2.new(0.5, -5, 0, 22)
RateRight.Position = UDim2.new(0.5, 5, 0, 4)
RateRight.Font = Enum.Font.GothamBold
RateRight.Text = "Hiện tại: 100%"
RateRight.TextColor3 = Color3.fromRGB(80, 255, 120)
RateRight.TextSize = 14
RateRight.TextXAlignment = Enum.TextXAlignment.Left

local CountLabel = Instance.new("TextLabel")
CountLabel.Name = "CountLabel"
CountLabel.Parent = RateFrame
CountLabel.BackgroundTransparency = 1
CountLabel.Size = UDim2.new(1, -20, 0, 20)
CountLabel.Position = UDim2.new(0, 10, 0, 27)
CountLabel.Font = Enum.Font.Gotham
CountLabel.Text = "✅ 0  |  ❌ 0"
CountLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
CountLabel.TextSize = 11
CountLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ==========================================
-- SWITCH TOGGLE (KIỂU iOS)
-- ==========================================
local SwitchFrame = Instance.new("Frame")
SwitchFrame.Parent = Panel
SwitchFrame.BackgroundTransparency = 1
SwitchFrame.Size = UDim2.new(0, 64, 0, 34)
SwitchFrame.Position = UDim2.new(1, -90, 0, 120)

-- Track
local Track = Instance.new("Frame")
Track.Name = "Track"
Track.Parent = SwitchFrame
Track.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
Track.BorderSizePixel = 0
Track.Size = UDim2.new(1, 0, 1, 0)

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(1, 0)
TrackCorner.Parent = Track

-- Thumb
local Thumb = Instance.new("Frame")
Thumb.Name = "Thumb"
Thumb.Parent = Track
Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Thumb.BorderSizePixel = 0
Thumb.Size = UDim2.new(0, 28, 0, 28)
Thumb.Position = UDim2.new(1, -31, 0.5, -14)

local ThumbCorner = Instance.new("UICorner")
ThumbCorner.CornerRadius = UDim.new(1, 0)
ThumbCorner.Parent = Thumb

-- Bóng Thumb
local Shadow = Instance.new("ImageLabel")
Shadow.Parent = Thumb
Shadow.BackgroundTransparency = 1
Shadow.Size = UDim2.new(1.3, 0, 1.3, 0)
Shadow.Position = UDim2.new(-0.15, 0, -0.15, 0)
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageTransparency = 0.55
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(8, 8, 8, 8)

-- Label ON/OFF
local SwitchLabel = Instance.new("TextLabel")
SwitchLabel.Name = "SwitchLabel"
SwitchLabel.Parent = Panel
SwitchLabel.BackgroundTransparency = 1
SwitchLabel.Size = UDim2.new(0, 80, 0, 28)
SwitchLabel.Position = UDim2.new(0, 24, 0, 123)
SwitchLabel.Font = Enum.Font.GothamBlack
SwitchLabel.Text = "BẬT"
SwitchLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
SwitchLabel.TextSize = 20
SwitchLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ==========================================
-- NÚT ẨN (TOUCH AREA)
-- ==========================================
local TouchBtn = Instance.new("TextButton")
TouchBtn.Parent = SwitchFrame
TouchBtn.BackgroundTransparency = 1
TouchBtn.Size = UDim2.new(2, 0, 2, 0)
TouchBtn.Position = UDim2.new(-0.5, 0, -0.5, 0)
TouchBtn.Text = ""

-- ==========================================
-- DÒNG TRẠNG THÁI REMOTE
-- ==========================================
local RemoteInfo = Instance.new("TextLabel")
RemoteInfo.Name = "RemoteInfo"
RemoteInfo.Parent = Panel
RemoteInfo.BackgroundTransparency = 1
RemoteInfo.Size = UDim2.new(1, -40, 0, 20)
RemoteInfo.Position = UDim2.new(0, 20, 0, 170)
RemoteInfo.Font = Enum.Font.Gotham
RemoteInfo.Text = ""
RemoteInfo.TextColor3 = Color3.fromRGB(140, 140, 145)
RemoteInfo.TextSize = 10
RemoteInfo.TextXAlignment = Enum.TextXAlignment.Left

-- ==========================================
-- ANIMATION SWITCH
-- ==========================================
local switchTween = nil

local function AnimateSwitch(on)
    local thumbGoal
    local trackColor
    local labelText
    local labelColor
    local rateText
    local rateColor
    
    if on then
        thumbGoal = UDim2.new(1, -31, 0.5, -14)
        trackColor = Color3.fromRGB(52, 199, 89)
        labelText = "BẬT"
        labelColor = Color3.fromRGB(80, 255, 120)
        rateText = "Hiện tại: 100%"
        rateColor = Color3.fromRGB(80, 255, 120)
    else
        thumbGoal = UDim2.new(0, 3, 0.5, -14)
        trackColor = Color3.fromRGB(70, 70, 75)
        labelText = "TẮT"
        labelColor = Color3.fromRGB(255, 100, 100)
        rateText = "Hiện tại: 40% (Gốc)"
        rateColor = Color3.fromRGB(255, 110, 110)
    end
    
    if switchTween then switchTween:Cancel() end
    
    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    switchTween = TweenService:Create(Thumb, ti, {Position = thumbGoal})
    switchTween:Play()
    
    TweenService:Create(Track, TweenInfo.new(0.25), {BackgroundColor3 = trackColor}):Play()
    
    SwitchLabel.Text = labelText
    SwitchLabel.TextColor3 = labelColor
    RateRight.Text = rateText
    RateRight.TextColor3 = rateColor
end

-- ==========================================
-- SỰ KIỆN
-- ==========================================
TouchBtn.MouseButton1Click:Connect(function()
    Toggle()
    AnimateSwitch(IsEnabled)
end)

TouchBtn.TouchTap:Connect(function()
    Toggle()
    AnimateSwitch(IsEnabled)
end)

-- ==========================================
-- CẬP NHẬT SỐ LIỆU
-- ==========================================
task.spawn(function()
    while true do
        task.wait(1.5)
        CountLabel.Text = string.format("✅ %d  |  ❌ %d", DoubleCount, FailBlocked)
    end
end)

-- ==========================================
-- KHỞI TẠO
-- ==========================================
MoneyValue = FindMoney()
MoneyRemote = FindMoneyRemote()
HookAll()
MonitorMoney()
MathOn()
AnimateSwitch(true)

if MoneyValue then
    RemoteInfo.Text = string.format("💰 %s: %d  |  📡 Server: %s", 
        MoneyValue.Name, MoneyValue.Value, MoneyRemote and "✅" or "⚠️")
else
    RemoteInfo.Text = "⏳ Đang chờ dữ liệu..."
end

print([[
============================================
  MOBILE DOUBLE 100% - READY
  Chạm công tắc để BẬT/TẮT
============================================
]])

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
