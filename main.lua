-- Script: Auto Double Only
-- Khi bam Double or Nothing -> luon la Double

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Tao GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoDoubleGUI"
screenGui.Parent = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Auto Double"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 160, 0, 40)
toggleBtn.Position = UDim2.new(0.5, -80, 0, 40)
toggleBtn.Text = "Auto Double: ON"
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSans
toggleBtn.TextSize = 16
toggleBtn.Parent = frame

local autoDouble = true

-- Ham click Double
local function clickDouble()
    local dGUI = gui:FindFirstChild("DoubleOrNothing")
    if not dGUI then return end
    
    for _, v in ipairs(dGUI:GetDescendants()) do
        if v:IsA("TextButton") and v.Text == "Double" then
            v:Click()
            return
        end
    end
end

-- Vong lap tu dong click Double
spawn(function()
    while wait(0.2) do
        if autoDouble then
            pcall(clickDouble)
        end
    end
end)

-- Xu ly nut toggle
toggleBtn.MouseButton1Click:Connect(function()
    autoDouble = not autoDouble
    toggleBtn.Text = autoDouble and "Auto Double: ON" or "Auto Double: OFF"
    toggleBtn.BackgroundColor3 = autoDouble and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(255, 50, 50)
end)

print("Auto Double da chay! Mac dinh: ON")
