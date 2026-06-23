-- ==========================================
-- SCRIPT: Double 100% - Table Intercept + GUI
-- ĐỊNH DẠNG: {Success, Multiplier, Reward}
-- GIAO DIỆN: Công tắc ON/OFF, thống kê
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- State
local IsEnabled = true
local OriginalMathRandom = math.random
local Connections = {}
local MoneyValue = nil
local LastMoney = 0
local DoubleCount = 0
local FailBlocked = 0

-- ==========================================
-- CORE 1: TÌM TIỀN
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
-- CORE 2: CHẶN TABLE KẾT QUẢ
-- ==========================================
local function HookAllForTable()
    local hooked = 0
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        -- RemoteEvent: OnClientEvent
        if obj:IsA("RemoteEvent") then
            pcall(function()
                local conn = obj.OnClientEvent:Connect(function(...)
                    if not IsEnabled then return end
                    local args = {...}
                    for i = 1, #args do
                        local arg = args[i]
                        if type(arg) == "table" then
                            local successField = arg.Success
                            if successField == false then
                                arg.Success = true
                                arg.Multiplier = 2
                                local baseReward = arg.Reward or arg.BaseReward or arg.Value or 100
                                arg.Reward = (baseReward > 0 and baseReward * 2) or 200
                                FailBlocked = FailBlocked + 1
                                DoubleCount = DoubleCount + 1
                                print(string.format("[FIX] false->true | Reward: %d", arg.Reward))
                            elseif successField == true then
                                -- Đã thành công, vẫn nhân đôi reward nếu có thể
                                if arg.Reward and arg.Reward > 0 then
                                    arg.Reward = arg.Reward * 2
                                    arg.Multiplier = 2
                                end
                                DoubleCount = DoubleCount + 1
                            end
                        end
                    end
                end)
                table.insert(Connections, conn)
                hooked = hooked + 1
            end)
        end
        
        -- RemoteFunction: OnClientInvoke
        if obj:IsA("RemoteFunction") then
            pcall(function()
                local conn = obj.OnClientInvoke:Connect(function(...)
                    if not IsEnabled then return nil end
                    local args = {...}
                    for i = 1, #args do
                        local arg = args[i]
                        if type(arg) == "table" and arg.Success ~= nil then
                            if arg.Success == false then
                                arg.Success = true
                                arg.Multiplier = 2
                                local base = arg.Reward or arg.BaseReward or 100
                                arg.Reward = (base > 0 and base * 2) or 200
                                FailBlocked = FailBlocked + 1
                                DoubleCount = DoubleCount + 1
                                print(string.format("[FUNC FIX] false->true | Reward: %d", arg.Reward))
                                return arg
                            elseif arg.Success == true then
                                if arg.Reward and arg.Reward > 0 then
                                    arg.Reward = arg.Reward * 2
                                end
                                DoubleCount = DoubleCount + 1
                                return arg
                            end
                        end
                    end
                    return nil
                end)
                table.insert(Connections, conn)
                hooked = hooked + 1
            end)
        end
    end
    return hooked
end

-- ==========================================
-- CORE 3: MONITOR TIỀN (DỰ PHÒNG)
-- ==========================================
local function MonitorMoney()
    MoneyValue = FindMoney()
    if not MoneyValue then return end
    LastMoney = MoneyValue.Value
    MoneyValue.Changed:Connect(function(v)
        if not IsEnabled then LastMoney = v; return end
        local diff = v - LastMoney
        if diff < 0 then
            local add = math.abs(diff) * 2
            MoneyValue.Value = MoneyValue.Value + add
            FailBlocked = FailBlocked + 1
            DoubleCount = DoubleCount + 1
            print(string.format("[MONEY] Lost %d -> Refund %d", math.abs(diff), add))
        elseif diff > 0 then
            DoubleCount = DoubleCount + 1
        end
        LastMoney = MoneyValue.Value
    end)
end

-- ==========================================
-- MATH HOOK (DỰ PHÒNG)
-- ==========================================
math.random = function(...)
    if not IsEnabled then return OriginalMathRandom(...) end
    local n = select("#", ...)
    if n == 0 then return OriginalMathRandom() * 0.39
    elseif n == 1 then return ...
    elseif n == 2 then return select(2, ...) end
    return OriginalMathRandom(...)
end

-- ==========================================
-- BẬT / TẮT
-- ==========================================
local function Enable()
    IsEnabled = true
end

local function Disable()
    IsEnabled = false
end

local function Toggle()
    if IsEnabled then Disable() else Enable() end
    return IsEnabled
end

-- ==========================================
-- GIAO DIỆN (MOBILE FRIENDLY)
-- ==========================================
local SG = Instance.new("ScreenGui")
SG.Name = "DoubleGUI"
SG.Parent = LocalPlayer:WaitForChild("PlayerGui")
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true

-- Panel chính
local Panel = Instance.new("Frame")
Panel.Parent = SG
Panel.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
Panel.BorderSizePixel = 0
Panel.Size = UDim2.new(0, 300, 0, 190)
Panel.Position = UDim2.new(0.5, -150, 0.08, 0)
Panel.Active = true
Panel.Draggable = true

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 18)
Corner.Parent = Panel

Instance.new("UIStroke", Panel).Thickness = 1
Panel.UIStroke.Color = Color3.fromRGB(45, 50, 58)

-- Tiêu đề
local Title = Instance.new("TextLabel")
Title.Parent = Panel
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -30, 0, 32)
Title.Position = UDim2.new(0, 15, 0, 10)
Title.Font = Enum.Font.GothamBold
Title.Text = "🎰 DOUBLE RATE 100%"
Title.TextColor3 = Color3.fromRGB(255, 210, 50)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Khung thông tin
local InfoFrame = Instance.new("Frame")
InfoFrame.Parent = Panel
InfoFrame.BackgroundColor3 = Color3.fromRGB(25, 28, 33)
InfoFrame.BorderSizePixel = 0
InfoFrame.Size = UDim2.new(1, -30, 0, 48)
InfoFrame.Position = UDim2.new(0, 15, 0, 48)

Instance.new("UICorner", InfoFrame).CornerRadius = UDim.new(0, 10)

local RateOrigLabel = Instance.new("TextLabel")
RateOrigLabel.Parent = InfoFrame
RateOrigLabel.BackgroundTransparency = 1
RateOrigLabel.Size = UDim2.new(0.5, -5, 0, 20)
RateOrigLabel.Position = UDim2.new(0, 8, 0, 4)
RateOrigLabel.Font = Enum.Font.GothamBold
RateOrigLabel.Text = "Gốc: 40%"
RateOrigLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
RateOrigLabel.TextSize = 13
RateOrigLabel.TextXAlignment = Enum.TextXAlignment.Left

local RateNowLabel = Instance.new("TextLabel")
RateNowLabel.Name = "RateNowLabel"
RateNowLabel.Parent = InfoFrame
RateNowLabel.BackgroundTransparency = 1
RateNowLabel.Size = UDim2.new(0.5, -5, 0, 20)
RateNowLabel.Position = UDim2.new(0.5, 5, 0, 4)
RateNowLabel.Font = Enum.Font.GothamBold
RateNowLabel.Text = "Hiện tại: 100%"
RateNowLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
RateNowLabel.TextSize = 13
RateNowLabel.TextXAlignment = Enum.TextXAlignment.Left

local CountLabel = Instance.new("TextLabel")
CountLabel.Name = "CountLabel"
CountLabel.Parent = InfoFrame
CountLabel.BackgroundTransparency = 1
CountLabel.Size = UDim2.new(1, -16, 0, 18)
CountLabel.Position = UDim2.new(0, 8, 0, 26)
CountLabel.Font = Enum.Font.Gotham
CountLabel.Text = "✅ 0  |  ❌ 0"
CountLabel.TextColor3 = Color3.fromRGB(170, 170, 175)
CountLabel.TextSize = 11
CountLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Công tắc
local SwitchFrame = Instance.new("Frame")
SwitchFrame.Parent = Panel
SwitchFrame.BackgroundTransparency = 1
SwitchFrame.Size = UDim2.new(0, 60, 0, 32)
SwitchFrame.Position = UDim2.new(1, -85, 0, 110)

local Track = Instance.new("Frame")
Track.Parent = SwitchFrame
Track.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
Track.BorderSizePixel = 0
Track.Size = UDim2.new(1, 0, 1, 0)
Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

local Thumb = Instance.new("Frame")
Thumb.Parent = Track
Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Thumb.BorderSizePixel = 0
Thumb.Size = UDim2.new(0, 26, 0, 26)
Thumb.Position = UDim2.new(1, -29, 0.5, -13)
Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

-- Bóng thumb
local Shadow = Instance.new("ImageLabel")
Shadow.Parent = Thumb
Shadow.BackgroundTransparency = 1
Shadow.Size = UDim2.new(1.3, 0, 1.3, 0)
Shadow.Position = UDim2.new(-0.15, 0, -0.15, 0)
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(8, 8, 8, 8)

local SwitchLabel = Instance.new("TextLabel")
SwitchLabel.Name = "SwitchLabel"
SwitchLabel.Parent = Panel
SwitchLabel.BackgroundTransparency = 1
SwitchLabel.Size = UDim2.new(0, 70, 0, 26)
SwitchLabel.Position = UDim2.new(0, 20, 0, 113)
SwitchLabel.Font = Enum.Font.GothamBlack
SwitchLabel.Text = "BẬT"
SwitchLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
SwitchLabel.TextSize = 19
SwitchLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Nút chạm
local TouchBtn = Instance.new("TextButton")
TouchBtn.Parent = SwitchFrame
TouchBtn.BackgroundTransparency = 1
TouchBtn.Size = UDim2.new(2.5, 0, 2.5, 0)
TouchBtn.Position = UDim2.new(-0.75, 0, -0.75, 0)
TouchBtn.Text = ""

-- Dòng trạng thái
local StatusLine = Instance.new("TextLabel")
StatusLine.Name = "StatusLine"
StatusLine.Parent = Panel
StatusLine.BackgroundTransparency = 1
StatusLine.Size = UDim2.new(1, -30, 0, 20)
StatusLine.Position = UDim2.new(0, 15, 0, 158)
StatusLine.Font = Enum.Font.Gotham
StatusLine.Text = "🎯 Đang chặn table {Success, Reward}"
StatusLine.TextColor3 = Color3.fromRGB(140, 140, 145)
StatusLine.TextSize = 10
StatusLine.TextXAlignment = Enum.TextXAlignment.Left

-- ==========================================
-- ANIMATION SWITCH
-- ==========================================
local function AnimateSwitch(on)
    local goal = on and UDim2.new(1, -29, 0.5, -13) or UDim2.new(0, 3, 0.5, -13)
    local trackCol = on and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(70, 70, 75)
    local text = on and "BẬT" or "TẮT"
    local textCol = on and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
    local rateText = on and "Hiện tại: 100%" or "Hiện tại: 40% (Gốc)"
    local rateCol = on and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 110, 110)
    
    TweenService:Create(Thumb, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Position = goal}):Play()
    TweenService:Create(Track, TweenInfo.new(0.25), {BackgroundColor3 = trackCol}):Play()
    SwitchLabel.Text = text
    SwitchLabel.TextColor3 = textCol
    RateNowLabel.Text = rateText
    RateNowLabel.TextColor3 = rateCol
end

-- Sự kiện
TouchBtn.MouseButton1Click:Connect(function()
    Toggle()
    AnimateSwitch(IsEnabled)
end)
TouchBtn.TouchTap:Connect(function()
    Toggle()
    AnimateSwitch(IsEnabled)
end)

-- Cập nhật số liệu
task.spawn(function()
    while true do
        task.wait(1)
        CountLabel.Text = string.format("✅ %d  |  ❌ %d", DoubleCount, FailBlocked)
    end
end)

-- ==========================================
-- KHỞI ĐỘNG
-- ==========================================
MoneyValue = FindMoney()
local hookedCount = HookAllForTable()
MonitorMoney()

print(string.format([[
============================================
  DOUBLE 100% - TABLE INTERCEPT
  Hooked: %d Remotes
  Money: %s
============================================
]], hookedCount, MoneyValue and (MoneyValue.Name .. " = " .. MoneyValue.Value) or "NOT FOUND"))

if MoneyValue then
    StatusLine.Text = string.format("💰 %s: %d  |  🎯 %d Remotes", MoneyValue.Name, MoneyValue.Value, hookedCount)
else
    StatusLine.Text = string.format("🎯 %d Remotes | ⏳ Đợi tiền...", hookedCount)
end

-- Chống AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
