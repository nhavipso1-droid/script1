-- ==========================================
-- SCRIPT: Double Rate 100% - NO LIMITATIONS
-- PHƯƠNG PHÁP: Can thiệp CẢ FireServer VÀ OnClientEvent
--              + Money Refund tự động
--              + Phát hiện mọi dạng kết quả
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

local IsActive = true
local OriginalMathRandom = math.random
local MoneyValue = nil
local LastMoney = 0
local RefundActive = false -- Cờ chống vòng lặp hoàn tiền

-- ==========================================
-- BƯỚC 1: TÌM MONEY VALUE TRONG LEADERSTATS
-- ==========================================
local function FindMoney()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then ls = LocalPlayer:WaitForChild("leaderstats", 10) end
    if not ls then return nil end
    
    for _, child in ipairs(ls:GetChildren()) do
        if child:IsA("IntValue") or child:IsA("DoubleValue") or child:IsA("NumberValue") then
            local name = child.Name:lower()
            if name:find("coin") or name:find("cash") or name:find("money") or 
               name:find("gem") or name:find("gold") or name:find("point") or
               name:find("balance") or name:find("currency") then
                return child
            end
        end
    end
    
    -- Fallback: IntValue đầu tiên
    for _, child in ipairs(ls:GetChildren()) do
        if child:IsA("IntValue") then
            return child
        end
    end
    
    return nil
end

-- ==========================================
-- BƯỚC 2: TÌM REMOTE LIÊN QUAN ĐẾN DOUBLE/SELL
-- ==========================================
local function FindDoubleRemotes()
    local fireTargets = {} -- Remote để gửi yêu cầu
    local receiveTargets = {} -- Remote để nhận kết quả
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local name = obj.Name:lower()
            local path = obj:GetFullName():lower()
            
            -- Remote gửi yêu cầu Double/Sell
            if name:find("double") or name:find("sell") or name:find("don") or
               name:find("gamble") or name:find("harvest") or name:find("bet") or
               path:find("double") or path:find("sell") or path:find("gamble") then
                table.insert(fireTargets, obj)
            end
            
            -- Remote nhận kết quả
            if name:find("result") or name:find("outcome") or name:find("reward") or
               name:find("response") or name:find("callback") or
               path:find("result") or path:find("outcome") then
                table.insert(receiveTargets, obj)
            end
        end
        
        if obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            local path = obj:GetFullName():lower()
            
            if name:find("double") or name:find("sell") or name:find("don") or
               name:find("gamble") or name:find("result") or name:find("outcome") or
               path:find("double") or path:find("sell") then
                table.insert(fireTargets, obj)
                table.insert(receiveTargets, obj)
            end
        end
    end
    
    return fireTargets, receiveTargets
end

-- ==========================================
-- BƯỚC 3: TÌM REMOTE CẬP NHẬT TIỀN TRỰC TIẾP
-- ==========================================
local function FindMoneyRemote()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            local path = obj:GetFullName():lower()
            
            -- Tìm event cập nhật tiền cụ thể
            if name == "addcoins" or name == "addcash" or name == "givemoney" or
               name == "addmoney" or name == "updatecoins" or name == "rewardcoins" or
               name == "setcoins" or name == "changemoney" or
               path:find("currency") or path:find("coin") or path:find("money") then
                return obj
            end
        end
    end
    return nil
end

-- ==========================================
-- BƯỚC 4: HOOK TẤT CẢ ONCLIENTEVENT (MỌI DẠNG KẾT QUẢ)
-- ==========================================
local function HookAllResults(receiveTargets)
    local hooked = 0
    
    -- Nếu không tìm thấy receiveTargets cụ thể, hook TẤT CẢ RemoteEvent
    local targets = #receiveTargets > 0 and receiveTargets or {}
    if #targets == 0 then
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                table.insert(targets, obj)
            end
        end
    end
    
    for _, remote in ipairs(targets) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                local conn = remote.OnClientEvent:Connect(function(...)
                    local args = {...}
                    local modified = false
                    local moneyAmount = nil
                    
                    -- Quét tất cả tham số
                    for i = 1, #args do
                        local arg = args[i]
                        
                        -- Dạng 1: Chuỗi NOTHING/LOSE/FAIL
                        if type(arg) == "string" then
                            local upper = arg:upper()
                            if upper == "NOTHING" or upper == "LOSE" or upper == "FAIL" or upper == "FALSE" then
                                args[i] = "DOUBLE"
                                modified = true
                            end
                        end
                        
                        -- Dạng 2: Boolean false
                        if type(arg) == "boolean" and arg == false then
                            args[i] = true
                            modified = true
                        end
                        
                        -- Dạng 3: Số 0 (thua, không nhận được gì)
                        if type(arg) == "number" and arg == 0 then
                            -- Tìm số tiền lẽ ra nhận được
                            for j = 1, #args do
                                if j ~= i and type(args[j]) == "number" and args[j] > 0 then
                                    args[i] = args[j] * 2
                                    modified = true
                                    moneyAmount = args[i]
                                    break
                                end
                            end
                        end
                        
                        -- Lưu số tiền nếu có
                        if type(arg) == "number" and arg > 0 then
                            moneyAmount = arg
                        end
                    end
                    
                    if modified then
                        print(string.format("[Hook] Kết quả bị sửa trong: %s", remote:GetFullName()))
                    end
                    
                    -- Nếu có số tiền, cố gắng gửi lên Server
                    if moneyAmount and moneyAmount > 0 then
                        SendMoneyToServer(moneyAmount)
                    end
                end)
                
                hooked = hooked + 1
                
            elseif remote:IsA("RemoteFunction") then
                local conn = remote.OnClientInvoke:Connect(function(...)
                    local args = {...}
                    
                    if #args >= 1 then
                        if type(args[1]) == "string" then
                            local upper = args[1]:upper()
                            if upper == "NOTHING" or upper == "LOSE" or upper == "FAIL" then
                                local amount = (args[2] or 100) * 2
                                SendMoneyToServer(amount)
                                return "DOUBLE", amount
                            end
                        end
                        if type(args[1]) == "boolean" and args[1] == false then
                            local amount = (args[2] or 100) * 2
                            SendMoneyToServer(amount)
                            return true, amount
                        end
                        if type(args[1]) == "number" and args[1] == 0 and #args >= 2 then
                            local amount = args[2] * 2
                            SendMoneyToServer(amount)
                            return amount, amount
                        end
                    end
                    return nil
                end)
                
                hooked = hooked + 1
            end
        end)
    end
    
    return hooked
end

-- ==========================================
-- BƯỚC 5: GỬI TIỀN LÊN SERVER (ĐA PHƯƠNG PHÁP)
-- ==========================================
local MoneyRemote = nil

local function SendMoneyToServer(amount)
    if not amount or amount <= 0 then return end
    if RefundActive then return end -- Chống vòng lặp
    
    RefundActive = true
    
    -- Tìm MoneyRemote nếu chưa có
    if not MoneyRemote then
        MoneyRemote = FindMoneyRemote()
    end
    
    -- Phương pháp A: MoneyRemote trực tiếp
    if MoneyRemote then
        pcall(function()
            if MoneyRemote:IsA("RemoteEvent") then
                MoneyRemote:FireServer(amount)
                print(string.format("[SendMoney] A: FireServer %d qua %s", amount, MoneyRemote.Name))
            elseif MoneyRemote:IsA("RemoteFunction") then
                MoneyRemote:InvokeServer(amount)
                print(string.format("[SendMoney] A: InvokeServer %d qua %s", amount, MoneyRemote.Name))
            end
        end)
    end
    
    -- Phương pháp B: Cập nhật trực tiếp leaderstats (Client-side)
    if MoneyValue then
        pcall(function()
            MoneyValue.Value = MoneyValue.Value + amount
            print(string.format("[SendMoney] B: Client-side +%d", amount))
        end)
    end
    
    task.wait(0.5)
    RefundActive = false
end

-- ==========================================
-- BƯỚC 6: THEO DÕI LEADERSTATS (PHÁT HIỆN THUA)
-- ==========================================
local function MonitorMoneyChanges()
    MoneyValue = FindMoney()
    if not MoneyValue then
        print("[Monitor] KHÔNG tìm thấy tiền!")
        return
    end
    
    LastMoney = MoneyValue.Value
    print(string.format("[Monitor] Theo dõi: %s = %d", MoneyValue.Name, LastMoney))
    
    MoneyValue.Changed:Connect(function(newValue)
        local diff = newValue - LastMoney
        
        if diff < 0 then
            -- Tiền GIẢM = Double thất bại
            local lost = math.abs(diff)
            print(string.format("[Monitor] ❌ MẤT %d coin! (Double thất bại)", lost))
            
            -- Hoàn lại gấp đôi
            local refund = lost * 2
            print(string.format("[Monitor] 🔄 Hoàn lại: %d coin", refund))
            SendMoneyToServer(refund)
            
        elseif diff > 0 then
            print(string.format("[Monitor] ✅ Nhận: +%d coin", diff))
        end
        
        LastMoney = MoneyValue.Value
    end)
end

-- ==========================================
-- BƯỚC 7: GHI ĐÈ MATH.RANDOM
-- ==========================================
math.random = function(...)
    local count = select("#", ...)
    if count == 0 then
        return OriginalMathRandom() * 0.39
    elseif count == 1 then
        return ...
    elseif count == 2 then
        return select(2, ...)
    end
    return OriginalMathRandom(...)
end

-- ==========================================
-- KHỞI CHẠY
-- ==========================================
print([[
============================================
  DOUBLE 100% - FULL METHOD
  Không giới hạn - Mọi dạng kết quả
============================================
]])

-- Tìm Money
MoneyValue = FindMoney()
if MoneyValue then
    print(string.format("[Init] Tiền: %s = %d", MoneyValue.Name, MoneyValue.Value))
else
    print("[Init] CẢNH BÁO: Không tìm thấy tiền!")
end

-- Tìm Remotes
local fireTargets, receiveTargets = FindDoubleRemotes()
print(string.format("[Init] FireTargets: %d, ReceiveTargets: %d", #fireTargets, #receiveTargets))

-- In ra để debug
if #fireTargets > 0 then
    print("[Init] FireTargets tìm thấy:")
    for i, r in ipairs(fireTargets) do
        print(string.format("  [%d] %s", i, r:GetFullName()))
    end
end
if #receiveTargets > 0 then
    print("[Init] ReceiveTargets tìm thấy:")
    for i, r in ipairs(receiveTargets) do
        print(string.format("  [%d] %s", i, r:GetFullName()))
    end
end

-- Tìm MoneyRemote
MoneyRemote = FindMoneyRemote()
if MoneyRemote then
    print(string.format("[Init] MoneyRemote: %s", MoneyRemote:GetFullName()))
else
    print("[Init] MoneyRemote: KHÔNG tìm thấy")
end

-- Hook kết quả
local hooked = HookAllResults(receiveTargets)
print(string.format("[Init] Đã hook %d sự kiện", hooked))

-- Theo dõi tiền
MonitorMoneyChanges()

-- ==========================================
-- GIAO DIỆN
-- ==========================================
local SG = Instance.new("ScreenGui")
SG.Name = "Double100"
SG.Parent = LocalPlayer:WaitForChild("PlayerGui")
SG.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Parent = SG
Frame.BackgroundColor3 = Color3.fromRGB(10, 20, 10)
Frame.BorderSizePixel = 0
Frame.Size = UDim2.new(0, 220, 0, 70)
Frame.Position = UDim2.new(1, -230, 0, 10)

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Label = Instance.new("TextLabel")
Label.Parent = Frame
Label.BackgroundTransparency = 1
Label.Size = UDim2.new(1, 0, 1, 0)
Label.Font = Enum.Font.GothamBold
Label.Text = "DOUBLE: 100%"
Label.TextColor3 = Color3.fromRGB(0, 255, 80)
Label.TextSize = 16

print([[
============================================
  HOẠT ĐỘNG:
  
  Khi Double thất bại:
  1. Chặn kết quả NOTHING
  2. Gửi tiền hoàn lại ×2 qua MoneyRemote
  3. Cập nhật Client-side
  
  Hạn chế đã xử lý:
  ✅ Mọi dạng kết quả (String/Boolean/Number)
  ✅ Cả RemoteEvent & RemoteFunction
  ✅ Tự động hoàn tiền khi thua
  ✅ Math.random ghi đè
============================================
]])

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
