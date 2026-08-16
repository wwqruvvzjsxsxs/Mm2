-- ========================================================
-- MM2 ULTIMATE HUB - FIXED & FULL
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

_G.ESPEnabled = true
_G.AutoFarm = false
_G.FarmMode = "OnMap"
_G.FarmDelay = 0.5
_G.FarmHeight = -2.5
_G.AutoKillEnabled = false
_G.AutoKillCoins = 40
_G.Noclip = false
_G.Platform = nil

-- Функция Noclip (работает всегда при включении)
RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Функция создания платформы
local function createPlatform(pos)
    if _G.Platform then _G.Platform:Destroy() end
    local p = Instance.new("Part")
    p.Name = "FarmPlatform"
    p.Size = Vector3.new(10, 1, 10)
    p.Position = pos
    p.Anchored = true
    p.CanCollide = true
    p.Transparency = 0.8
    p.Parent = Workspace
    _G.Platform = p
end

-- Основной цикл Фарма
task.spawn(function()
    while true do
        task.wait(_G.FarmDelay)
        if _G.AutoFarm and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local targetCoin = nil
            
            -- Поиск всех монет
            for _, obj in pairs(Workspace:GetChildren()) do
                if (obj.Name == "Coin" or obj.Name == "GoldCoin") and obj:IsA("BasePart") then
                    targetCoin = obj
                    break
                end
            end
            
            if targetCoin then
                local targetPos = Vector3.new(targetCoin.Position.X, targetCoin.Position.Y + _G.FarmHeight, targetCoin.Position.Z)
                
                -- Режим "Под картой"
                if _G.FarmMode == "UnderMap" then
                    createPlatform(targetPos + Vector3.new(0, -1, 0))
                else
                    if _G.Platform then _G.Platform:Destroy(); _G.Platform = nil end
                end
                
                -- Телепорт
                hrp.CFrame = CFrame.new(targetPos)
                
                -- Микро-движения
                for i=1, 2 do
                    hrp.CFrame = hrp.CFrame + Vector3.new(math.random(-1,1), 0, math.random(-1,1))
                    task.wait(0.05)
                end
                
                -- Автокилл
                if _G.AutoKillEnabled then
                    local count = 0
                    pcall(function() count = tonumber(LocalPlayer.PlayerGui.MainGUI.Game.CashBag.Container.CoinContainer.CoinTotal.Text:match("%d+")) end)
                    if count and count >= _G.AutoKillCoins then
                        hrp.CFrame = CFrame.new(0, -9999, 0)
                    end
                end
            end
        else
            if _G.Platform then _G.Platform:Destroy(); _G.Platform = nil end
        end
    end
end)

-- Интерфейс (Rayfield)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "MM2 Ultimate Hub", LoadingTitle = "MM2", KeySystem = false})

local Tab1 = Window:CreateTab("Фарм", 4483362458)
Tab1:CreateToggle({Name = "Авто Фарм", Callback = function(v) _G.AutoFarm = v end})
Tab1:CreateDropdown({Name = "Режим", Options = {"На карте", "Под картой"}, Callback = function(o) _G.FarmMode = (o[1] == "На карте" and "OnMap" or "UnderMap") end})
Tab1:CreateToggle({Name = "Noclip (Сквозь стены)", Callback = function(v) _G.Noclip = v end})
Tab1:CreateSlider({Name = "Задержка (скорость)", Range = {0.1, 1}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) _G.FarmDelay = v end})
Tab1:CreateSlider({Name = "Высота", Range = {-10, 5}, Increment = 0.5, CurrentValue = -2.5, Callback = function(v) _G.FarmHeight = v end})

local Tab2 = Window:CreateTab("Визуал", 4483362458)
Tab2:CreateToggle({Name = "ESP Игроков", Callback = function(v) _G.ESPEnabled = v end})
-- ESP Цикл (полный)
RunService.RenderStepped:Connect(function()
    if not _G.ESPEnabled then 
        for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("Highlight") then p.Character.Highlight:Destroy() end end
        return 
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if not p.Character:FindFirstChild("Highlight") then
                local h = Instance.new("Highlight", p.Character)
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            end
        end
    end
end)
