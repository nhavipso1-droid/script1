-- Script: Auto Double Force
-- Can thiep manh vao game de luon chon Double

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Tao GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ForceDoubleGUI"
screenGui.Parent = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 120)
frame.Position = UDim2.new(0.5, -125, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Auto Double - FORCE MODE"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 200, 0, 40)
toggleBtn.Position = UDim2.new(0.5, -100, 0, 40)
toggleBtn.Text = "FORCE DOUBLE: ON"
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 18
toggleBtn.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0, 85)
statusLabel.Text = "Dang theo doi..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.Parent = frame

local forceActive = true
local clickCount = 0

-- Phuong phap 1: Click truc tiep
local function method1_click()
    local dGUI = gui:FindFirstChild("DoubleOrNothing")
    if not dGUI then return false end
    
    for _, v in ipairs(dGUI:GetDescendants()) do
        if v:IsA("TextButton") and v.Text == "Double" then
            v:Click()
            return true
        end
    end
    return false
end

-- Phuong phap 2: Fire ClickDetector
local function method2_fireDetector()
    local dGUI = gui:FindFirstChild("DoubleOrNothing")
    if not dGUI then return false end
    
    for _, v in ipairs(dGUI:GetDescendants()) do
        if v:IsA("TextButton") and v.Text == "Double" then
            local detector = v:FindFirstChildOfClass("ClickDetector")
            if detector then
                fireclickdetector(detector)
                return true
            end
        end
    end
    return false
end

-- Phuong phap 3: Mouse click
local function method3_mouseClick()
    local dGUI = gui:FindFirstChild("DoubleOrNothing")
    if not dGUI then return false end
    
    for _, v in ipairs(dGUI:GetDescendants()) do
        if v:IsA("TextButton") and v.Text == "Double" then
            local pos = v.AbsolutePosition
            local size = v.AbsoluteSize
            local center = pos + size/2
            
            -- Tao mouse event
            local inputObject = Instance.new("InputObject")
            inputObject.UserInputType = Enum.UserInputType.MouseButton1
            inputObject.Position = Vector2.new(center.X, center.Y)
            
            -- Gui su kien
            game:GetService("UserInputService"):SendInputEvent(inputObject)
            return true
        end
    end
    return false
end

-- Phuong phap 4: Remote event
local function method4_remote()
    -- Tim remote event trong game
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find("double") then
            v:FireServer()
            return true
        end
    end
    return false
end

-- Phuong phap 5: Find function
local function method5_function()
    -- Tim function trong script
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("LocalScript") or v:IsA("ModuleScript") then
            local success, result = pcall(function()
                return v:FindFirstChild("Double")
            end)
            if success and result then
                pcall(result)
                return true
            end
        end
    end
    return false
end

-- Vong lap chinh - thu tat ca phuong phap
spawn(function()
    while wait(0.1) do
        if forceActive then
            pcall(function()
                -- Kiem tra xem co cua so Double or Nothing khong
                local dGUI = gui:FindFirstChild("DoubleOrNothing")
                if dGUI and dGUI.Visible then
                    statusLabel.Text = "Da tim thay Double or Nothing!"
                    
                    -- Thu tung phuong phap
                    if method1_click() then
                        clickCount = clickCount + 1
                        statusLabel.Text = "Double clicked! (Phuong phap 1)"
                    elseif method2_fireDetector() then
                        clickCount = clickCount + 1
                        statusLabel.Text = "Double clicked! (Phuong phap 2)"
                    elseif method3_mouseClick() then
                        clickCount = clickCount + 1
                        statusLabel.Text = "Double clicked! (Phuong phap 3)"
                    elseif method4_remote() then
                        clickCount = clickCount + 1
                        statusLabel.Text = "Double clicked! (Phuong phap 4)"
                    elseif method5_function() then
                        clickCount = clickCount + 1
                        statusLabel.Text = "Double clicked! (Phuong phap 5)"
                    else
                        statusLabel.Text = "Khong tim thay nut Double!"
                    end
                else
                    statusLabel.Text = "Dang doi cua so Double or Nothing..."
                end
            })
        end
    end
end)

-- Xu ly nut toggle
toggleBtn.MouseButton1Click:Connect(function()
    forceActive = not forceActive
    toggleBtn.Text = forceActive and "FORCE DOUBLE: ON" or "FORCE DOUBLE: OFF"
    toggleBtn.BackgroundColor3 = forceActive and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    statusLabel.Text = forceActive and "Dang theo doi..." or "DA TAT"
end)

print("FORCE DOUBLE DA KICH HOAT!")
print("Dang su dung 5 phuong phap de click Double...")
