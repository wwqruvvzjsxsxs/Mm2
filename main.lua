-- ========================================================
-- MM2 ULTIMATE HUB - NOCLIP + ПЛАТФОРМА + СКОРОСТЬ
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

-- Noclip (Сквозь стены)
RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Утилиты
local function getMM2Role(player)
    local char = player.Character
    if not char then return "Innocent" end
    if char:FindFirstChild("Knife") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife")) then return "Murderer" end
    if char:FindFirstChild("Gun") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun")) then return "Sheriff" end
    return "Innocent"
end

local function isInGame()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0
end

local function getCoinCount()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui and playerGui:FindFirstChild("MainGUI") then
            local text = playerGui.MainGUI.Game.CashBag.Container.CoinContainer.CoinTotal.Text
            return tonumber(text:match("%d+")) or 0
        end
    end)
    return 0
end

local function killSelf()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = CFrame.new(0, -9999, 0) end
end

local function createUnderMapPlatform(position)
    if _G.Platform then _G.Platform:Destroy() end
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(10, 1, 10)
    platform.Position = position
    platform.Anchored = true
    platform.Transparency = 0.5 -- Сделал полупрозрачной, чтобы ты видел, на чем стоишь
    platform.CanCollide = true
    platform.Parent = Workspace
    _G.Platform = platform
end

-- ESP Система
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.ESPEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hl = p.Character:FindFirstChild("MM2_ESP") or Instance.new("Highlight", p.Character)
                    hl.Name = "MM2_ESP"
                    local role = getMM2Role(p)
                    hl.FillColor = (role == "Murderer" and Color3.new(1,0,0)) or (role == "Sheriff" and Color3.new(0,0,1)) or Color3.new(0,1,0)
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("MM2_ESP") then p.Character.MM2_ESP:Destroy() end end
        end
    end
end)

-- Главный цикл фарма
task.spawn(function()
    while true do
        task.wait(_G.FarmDelay) -- Вот здесь используется твоя настройка скорости!
        if _G.AutoFarm and isInGame() then
            local coins = {}
            for _, obj in pairs(Workspace:GetDescendants()) do
                if (obj.Name == "Coin" or obj.Name == "GoldCoin") and obj:IsA("BasePart") then table.insert(coins, obj) end
            end
            
            local coin = coins[1]
            if coin then
                local root = LocalPlayer.Character.HumanoidRootPart
                local targetPos = Vector3.new(coin.Position.X, coin.Position.Y + _G.FarmHeight, coin.Position.Z)
                
                if _G.FarmMode == "UnderMap" then
                    createUnderMapPlatform(targetPos + Vector3.new(0, -2, 0))
                    root.CFrame = CFrame.new(targetPos)
                else
                    root.CFrame = CFrame.new(targetPos)
                end
                
                -- Микро-движения для подбора монетки
                root.CFrame = root.CFrame + Vector3.new(math.random(-1,1), 0, math.random(-1,1))
                
                if _G.AutoKillEnabled and getCoinCount() >= _G.AutoKillCoins then
                    killSelf()
                end
            end
        else
            if _G.Platform then _G.Platform:Destroy() _G.Platform = nil end
        end
    end
end)

-- ========================================================
-- UI (ИНТЕРФЕЙС)
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "MM2 Ultimate Hub", LoadingTitle = "Загрузка...", KeySystem = false})

local Tab1 = Window:CreateTab("Фарм и Чит", 4483362458)
Tab1:CreateToggle({Name = "Авто Фарм", Callback = function(v) _G.AutoFarm = v end})

Tab1:CreateDropdown({Name = "Режим", Options = {"На карте", "Под картой"}, CurrentOption = {"На карте"}, Callback = function(o) 
    _G.FarmMode = (o[1] == "На карте" and "OnMap" or "UnderMap") 
end})

Tab1:CreateToggle({Name = "Noclip (Сквозь стены)", Callback = function(v) _G.Noclip = v end})

-- ВЕРНУЛ ПОЛЗУНОК СКОРОСТИ
Tab1:CreateSlider({
    Name = "Задержка сбора (Скорость)",
    Range = {0.1, 2.0},
    Increment = 0.1,
    Suffix = "сек",
    CurrentValue = 0.5,
    Callback = function(Value)
        _G.FarmDelay = Value
    end,
})

Tab1:CreateSlider({
    Name = "Высота под картой",
    Range = {-10, 0},
    Increment = 0.5,
    Suffix = "блоков",
    CurrentValue = -2.5,
    Callback = function(Value)
        _G.FarmHeight = Value
    end,
})

local Tab2 = Window:CreateTab("Авто-килл", 4483362458)
Tab2:CreateToggle({Name = "Авто-смерть при лимите", Callback = function(v) _G.AutoKillEnabled = v end})
Tab2:CreateSlider({Name = "Лимит монет", Range = {10, 50}, Increment = 1, CurrentValue = 40, Callback = function(v) _G.AutoKillCoins = v end})

local Tab3 = Window:CreateTab("Визуал", 4483362458)
Tab3:CreateToggle({Name = "ESP (Подсветка)", CurrentValue = true, Callback = function(v) _G.ESPEnabled = v end})
