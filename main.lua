-- ==========================================
-- SCRIPT: Double 100% - GUI HIỂN THỊ CHẮC CHẮN
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
-- CORE: CHẶN TABLE {Success, Multiplier, Reward}
-- ==========================================
local function HookAllForTable()
    local hooked = 0
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            pcall(function()
                local conn = obj.OnClientEvent:Connect(function(...)
                    if not IsEnabled then return end
                    local args = {...}
                    for i = 1, #args do
                        local arg = args[i]
                        if type(arg) == "table" and arg.Success ~= nil then
                            if arg.Success == false then
                                arg.Success = true
                                arg.Multiplier = 2
                                local base = arg.Reward or arg.BaseReward or arg.Value or 100
                                arg.Reward = (base > 0 and base * 2) or 200
                                FailBlocked = FailBlocked + 1
                                DoubleCount = DoubleCount + 1
                            elseif arg.Success == true then
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
        elseif obj:IsA("RemoteFunction") then
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
            local add = math.abs(diff) * 2
            MoneyValue.Value = MoneyValue.Value + add
            FailBlocked = FailBlocked + 1
            DoubleCount = DoubleCount + 1
        elseif diff > 0 then
            DoubleCount = DoubleCount + 1
        end
        LastMoney = MoneyValue.Value
    end)
end

-- ==========================================
-- MATH HOOK
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
-- BẬT/TẮT
-- ==========================================
local function Toggle()
    IsEnabled = not IsEnabled
    return IsEnabled
end

-- ==========================================
-- GIAO DIỆN (CHẮC CHẮN HIỂN THỊ)
-- ==========================================
local function CreateGUI()
    local SG = Instance.new("ScreenGui")
    SG.Name = "DoubleGUI_Main"
    SG.Parent = LocalPlayer:WaitForChild("PlayerGui")
    SG.ResetOnSpawn = false
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SG.IgnoreGuiInset = true

    -- Panel chính - đặt giữa màn hình, kích thước vừa phải
    local Panel = Instance.new("Frame")
    Panel.Name = "MainPanel"
    Panel.Parent = SG
    Panel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    Panel.BorderSizePixel = 0
    Panel.Size = UDim2.new(0, 280, 0, 160)
    Panel.AnchorPoint = Vector2.new(0.5, 0.5)
    Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    Panel.Active = true
    Panel.Draggable = true
    Panel.Visible = true

    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 16)
    local stroke = Instance.new("UIStroke", Panel)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(100, 200, 100)

    -- Tiêu đề
    local Title = Instance.new("TextLabel")
    Title.Parent = Panel
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, -20, 0, 28)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "🎰 DOUBLE 100%"
    Title.TextColor3 = Color3.fromRGB(255, 215, 0)
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Nút bật/tắt (to, rõ)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Parent = Panel
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Size = UDim2.new(1, -40, 0, 50)
    ToggleBtn.Position = UDim2.new(0, 20, 0, 45)
    ToggleBtn.Font = Enum.Font.GothamBlack
    ToggleBtn.Text = "ĐANG BẬT"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 20
    ToggleBtn.AutoButtonColor = false
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)
    local btnStroke = Instance.new("UIStroke", ToggleBtn)
    btnStroke.Thickness = 2
    btnStroke.Color = Color3.fromRGB(80, 255, 130)

    -- Nhãn thống kê
    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Name = "StatsLabel"
    StatsLabel.Parent = Panel
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Size = UDim2.new(1, -40, 0, 20)
    StatsLabel.Position = UDim2.new(0, 20, 0, 105)
    StatsLabel.Font = Enum.Font.Gotham
    StatsLabel.Text = "✅ 0  |  ❌ 0"
    StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatsLabel.TextSize = 13

    -- Dòng trạng thái
    local StatusLine = Instance.new("TextLabel")
    StatusLine.Name = "StatusLine"
    StatusLine.Parent = Panel
    StatusLine.BackgroundTransparency = 1
    StatusLine.Size = UDim2.new(1, -40, 0, 20)
    StatusLine.Position = UDim2.new(0, 20, 0, 128)
    StatusLine.Font = Enum.Font.Gotham
    StatusLine.Text = "Sẵn sàng"
    StatusLine.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLine.TextSize = 11

    -- Cập nhật giao diện
    local function UpdateUI()
        if IsEnabled then
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            ToggleBtn.Text = "ĐANG BẬT"
            btnStroke.Color = Color3.fromRGB(80, 255, 130)
            stroke.Color = Color3.fromRGB(100, 200, 100)
        else
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            ToggleBtn.Text = "ĐÃ TẮT"
            btnStroke.Color = Color3.fromRGB(255, 80, 80)
            stroke.Color = Color3.fromRGB(200, 100, 100)
        end
        StatsLabel.Text = string.format("✅ %d  |  ❌ %d", DoubleCount, FailBlocked)
        if MoneyValue then
            StatusLine.Text = string.format("💰 %s: %d", MoneyValue.Name, MoneyValue.Value)
        else
            StatusLine.Text = "Đang tìm tiền..."
        end
    end

    -- Sự kiện nút
    ToggleBtn.MouseButton1Click:Connect(function()
        Toggle()
        UpdateUI()
    end)
    ToggleBtn.TouchTap:Connect(function()
        Toggle()
        UpdateUI()
    end)

    -- Cập nhật định kỳ
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(UpdateUI)
        end
    end)

    -- Trả về hàm UpdateUI để gọi từ ngoài
    return UpdateUI
end

-- ==========================================
-- KHỞI ĐỘNG
-- ==========================================
local UpdateUI = CreateGUI()
MoneyValue = FindMoney()
local hookedCount = HookAllForTable()
MonitorMoney()

-- Thông báo
if UpdateUI then UpdateUI() end

print([[
============================================
  DOUBLE 100% - GUI ĐÃ HIỂN THỊ
============================================
]])

-- Chống AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
