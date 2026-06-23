-- ==========================================
-- SCRIPT: Double Rate 100% - TABLE INTERCEPT
-- GAME: Grow a Garden 2
-- DATA FORMAT: {Success, Multiplier, Reward}
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
-- TÌM TIỀN
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
-- BƯỚC QUAN TRỌNG: CHẶN TABLE KẾT QUẢ
-- ==========================================
local function HookAllRemotesForTable()
    local hooked = 0
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        
        -- === CHẶN RemoteEvent (OnClientEvent) ===
        if obj:IsA("RemoteEvent") then
            pcall(function()
                local conn = obj.OnClientEvent:Connect(function(...)
                    if not IsEnabled then return end
                    local args = {...}
                    
                    for i = 1, #args do
                        local arg = args[i]
                        
                        -- Phát hiện table {Success, Multiplier, Reward}
                        if type(arg) == "table" and arg.Success ~= nil then
                            local originalSuccess = arg.Success
                            local originalReward = arg.Reward or 0
                            
                            if originalSuccess == false then
                                -- SỬA: Success = true, Multiplier = 2, Reward = Reward gốc × 2
                                arg.Success = true
                                arg.Multiplier = 2
                                
                                -- Tìm Reward gốc (nếu có)
                                if arg.Reward and arg.Reward <= 0 then
                                    -- Thử tìm trong các trường khác
                                    local baseReward = arg.BaseReward or arg.OriginalReward or arg.Value or 100
                                    arg.Reward = baseReward * 2
                                elseif arg.Reward and arg.Reward > 0 then
                                    -- Đã có Reward > 0, nhân đôi
                                    arg.Reward = arg.Reward * 2
                                else
                                    arg.Reward = 1000 -- Fallback
                                end
                                
                                FailBlocked = FailBlocked + 1
                                DoubleCount = DoubleCount + 1
                                
                                print(string.format("[TABLE FIX] Success: false -> true | Reward: %d -> %d | Remote: %s", 
                                    originalReward, arg.Reward, obj.Name))
                            elseif originalSuccess == true then
                                -- Đã thành công, vẫn đảm bảo Reward ×2
                                if arg.Reward and arg.Reward > 0 then
                                    arg.Reward = arg.Reward * 2
                                    arg.Multiplier = 2
                                end
                                DoubleCount = DoubleCount + 1
                                print(string.format("[TABLE BOOST] Reward ×2: %d -> %d | Remote: %s", 
                                    originalReward, arg.Reward, obj.Name))
                            end
                        end
                        
                        -- Phát hiện table dạng {Success = false}
                        if type(arg) == "table" and rawget(arg, "Success") == false then
                            rawset(arg, "Success", true)
                            if rawget(arg, "Multiplier") then rawset(arg, "Multiplier", 2) end
                            if rawget(arg, "Reward") then
                                local r = rawget(arg, "Reward")
                                rawset(arg, "Reward", r > 0 and r * 2 or 1000)
                            end
                            FailBlocked = FailBlocked + 1
                            DoubleCount = DoubleCount + 1
                            print(string.format("[RAW TABLE] Fixed in: %s", obj.Name))
                        end
                    end
                end)
                table.insert(Connections, conn)
                hooked = hooked + 1
            end)
        end
        
        -- === CHẶN RemoteFunction (OnClientInvoke) ===
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
                                arg.Reward = (arg.Reward and arg.Reward > 0 and arg.Reward * 2) or (arg.BaseReward or 100) * 2
                                FailBlocked = FailBlocked + 1
                                DoubleCount = DoubleCount + 1
                                print(string.format("[FUNC TABLE] Fixed in: %s", obj.Name))
                                return arg -- Trả về table đã sửa
                            elseif arg.Success == true then
                                arg.Reward = (arg.Reward or 100) * 2
                                arg.Multiplier = 2
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
-- THEO DÕI TIỀN (DỰ PHÒNG)
-- ==========================================
local function MonitorMoney()
    MoneyValue = FindMoney()
    if not MoneyValue then return end
    LastMoney = MoneyValue.Value
    
    MoneyValue.Changed:Connect(function(v)
        if not IsEnabled then LastMoney = v; return end
        local diff = v - LastMoney
        if diff < 0 then
            -- Tiền giảm = Double thất bại (dự phòng)
            MoneyValue.Value = MoneyValue.Value + math.abs(diff) * 2
            FailBlocked = FailBlocked + 1
            DoubleCount = DoubleCount + 1
            print(string.format("[MONEY FIX] Mất %d -> Hoàn %d", math.abs(diff), math.abs(diff) * 2))
        elseif diff > 0 then
            DoubleCount = DoubleCount + 1
        end
        LastMoney = MoneyValue.Value
    end)
end

-- ==========================================
-- GHI ĐÈ MATH.RANDOM (DỰ PHÒNG)
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
-- GIAO DIỆN MOBILE
-- ==========================================
local SG = Instance.new("ScreenGui")
SG.Name = "TableDoubleGUI"
SG.Parent = LocalPlayer:WaitForChild("PlayerGui")
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true

local screenWidth = workspace.CurrentCamera.ViewportSize.X
local panelWidth = math.min(320, screenWidth - 20)

local Panel = Instance.new("Frame")
Panel.Parent = SG
Panel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
Panel.BorderSizePixel = 0
Panel.Size = UDim2.new(0, panelWidth, 0, 210)
Panel.Position = UDim2.new(0.5, -panelWidth/2, 0.06, 0)
Panel.Active = true
Panel.Draggable = true

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 20)
local PS = Instance.new("UIStroke", Panel)
PS.Thickness = 1.5
PS.Color = Color3.fromRGB(50, 55, 65)

-- Tiêu đề
local Title = Instance.new("TextLabel")
Title.Parent = Panel
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Position = UDim2.new(0, 20, 0, 14)
Title.Font = Enum.Font.GothamBold
Title.Text = "🎰 DOUBLE 100%"
Title.TextColor3 = Color3.fromRGB(255, 210, 50)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Khung tỉ lệ
local RateFrame = Instance.new("Frame")
RateFrame.Parent = Panel
RateFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
RateFrame.BorderSizePixel = 0
RateFrame.Size = UDim2.new(1, -40, 0, 50)
RateFrame.Position = UDim2.new(0, 20, 0, 52)

Instance.new("UICorner", RateFrame).CornerRadius = UDim.new(0, 12)

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

-- Switch toggle
local SwitchFrame = Instance.new("Frame")
SwitchFrame.Parent = Panel
SwitchFrame.BackgroundTransparency = 1
SwitchFrame.Size = UDim2.new(0, 64, 0, 34)
SwitchFrame.Position = UDim2.new(1, -90, 0, 120)

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
Thumb.Size = UDim2.new(0, 28, 0, 28)
Thumb.Position = UDim2.new(1, -31, 0.5, -14)
Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

local Shadow = Instance.new("ImageLabel")
Shadow.Parent = Thumb
Shadow.BackgroundTransparency = 1
Shadow.Size = UDim2.new(1.3, 0, 1.3, 0)
Shadow.Position = UDim2.new(-0.15, 0, -0.15, 0)
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageTransparency = 0.55
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(8, 8, 8, 8)

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

local TouchBtn = Instance.new("TextButton")
TouchBtn.Parent = SwitchFrame
TouchBtn.BackgroundTransparency = 1
TouchBtn.Size = UDim2.new(2, 0, 2, 0)
TouchBtn.Position = UDim2.new(-0.5, 0, -0.5, 0)
TouchBtn.Text = ""

-- Trạng thái Remote
local RemoteInfo = Instance.new("TextLabel")
RemoteInfo.Parent = Panel
RemoteInfo.BackgroundTransparency = 1
RemoteInfo.Size = UDim2.new(1, -40, 0, 20)
RemoteInfo.Position = UDim2.new(0, 20, 0, 175)
RemoteInfo.Font = Enum.Font.Gotham
RemoteInfo.Text = "🎯 Chặn table {Success, Reward}"
RemoteInfo.TextColor3 = Color3.fromRGB(140, 140, 145)
RemoteInfo.TextSize = 10
RemoteInfo.TextXAlignment = Enum.TextXAlignment.Left

-- ==========================================
-- ANIMATION SWITCH
-- ==========================================
local function AnimateSwitch(on)
    local TweenService = game:GetService("TweenService")
    local thumbGoal = on and UDim2.new(1, -31, 0.5, -14) or UDim2.new(0, 3, 0.5, -14)
    local trackColor = on and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(70, 70, 75)
    local labelText = on and "BẬT" or "TẮT"
    local labelColor = on and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
    local rateText = on and "Hiện tại: 100%" or "Hiện tại: 40% (Gốc)"
    local rateColor = on and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 110, 110)
    
    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(Thumb, ti, {Position = thumbGoal}):Play()
    TweenService:Create(Track, TweenInfo.new(0.25), {BackgroundColor3 = trackColor}):Play()
    
    SwitchLabel.Text = labelText
    SwitchLabel.TextColor3 = labelColor
    RateRight.Text = rateText
    RateRight.TextColor3 = rateColor
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
-- KHỞI CHẠY
-- ==========================================
MoneyValue = FindMoney()
local hookedCount = HookAllRemotesForTable()
MonitorMoney()

print([[
============================================
  TABLE INTERCEPT - DOUBLE 100%
  Định dạng: {Success, Multiplier, Reward}
  Đã hook: ]] .. hookedCount .. [[ Remotes
============================================
]])

if MoneyValue then
    RemoteInfo.Text = string.format("💰 %s: %d  |  🎯 %d Remotes", MoneyValue.Name, MoneyValue.Value, hookedCount)
else
    RemoteInfo.Text = string.format("🎯 Đã quét %d Remotes | ⏳ Chờ tiền...", hookedCount)
end

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
