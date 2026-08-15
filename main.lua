-- ========================================================
-- MM2 ULTIMATE HUB - ИСПРАВЛЕННАЯ ВЕРСИЯ ДЛЯ DELTA
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")

-- Уведомления для отладки
local function notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "MM2 Hub",
            Text = msg,
            Duration = 3
        })
    end)
end

-- ========================================================
-- НАСТРОЙКИ
-- ========================================================
_G.RolesESP = true
_G.InnocentColor = Color3.fromRGB(0, 255, 0)
_G.ESPTransparency = 0.4
_G.GunESP = true
_G.GunHitboxEnabled = false
_G.GunHitboxSize = 10
_G.AntiKnifeHitbox = false
_G.AntiBulletHitbox = false
_G.AimbotEnabled = false
_G.AimbotSmoothness = 0.3
_G.AutoFarm = false
_G.FarmSpeed = 20
_G.CoinHitboxSize = 5
_G.Invisibility = false
_G.AutoRejoin = true
_G.AntiAFK = true
_G.HitboxEnabled = false
_G.HitboxSize = 10
_G.HitboxTransparency = 0.7
_G.FPSBoostEnabled = false
_G.FakeName = ""
_G.SilentAim = false
_G.FlyEnabled = false
_G.FlyNoClip = false
_G.CustomCoinImage = ""
_G.HitSoundEnabled = true
_G.HitSoundVolume = 1

local MurdererColor = Color3.fromRGB(255, 0, 0)
local SheriffColor = Color3.fromRGB(0, 0, 255)

-- ========================================================
-- ФУНКЦИЯ ОПРЕДЕЛЕНИЯ РОЛИ
-- ========================================================
local function getMM2Role(player)
    local char = player.Character
    if not char then return "Innocent" end
    
    if char:FindFirstChild("Knife") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife")) then
        return "Murderer"
    elseif char:FindFirstChild("Gun") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    
    return "Innocent"
end

-- ========================================================
-- ESP ИГРОКОВ
-- ========================================================
local activeHighlights = {}

local function removeHighlight(player)
    if activeHighlights[player] then
        if activeHighlights[player].Parent then
            activeHighlights[player]:Destroy()
        end
        activeHighlights[player] = nil
    end
end

local function updatePlayerESP(player)
    if player == LocalPlayer then return end
    
    local char = player.Character
    if not char then
        removeHighlight(player)
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        removeHighlight(player)
        return
    end

    local role = getMM2Role(player)
    local targetColor = _G.InnocentColor

    if role == "Murderer" then
        targetColor = MurdererColor
    elseif role == "Sheriff" then
        targetColor = SheriffColor
    end

    local hl = activeHighlights[player]
    if not hl or hl.Parent ~= char then
        removeHighlight(player)
        hl = Instance.new("Highlight")
        hl.Name = "MM2_ESP_Highlight"
        hl.FillColor = targetColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = _G.ESPTransparency
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        activeHighlights[player] = hl
    else
        hl.FillColor = targetColor
        hl.FillTransparency = _G.ESPTransparency
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.RolesESP then
            for _, player in ipairs(Players:GetPlayers()) do
                updatePlayerESP(player)
            end
        else
            for player, _ in pairs(activeHighlights) do
                removeHighlight(player)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(removeHighlight)

-- ========================================================
-- ПОИСК МОНЕТ (УНИВЕРСАЛЬНЫЙ)
-- ========================================================
local function findAllCoins()
    local coins = {}
    
    -- Ищем в Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            if (name:find("coin") or name:find("монет")) and obj.Transparency < 0.9 then
                table.insert(coins, obj)
            end
        end
    end
    
    return coins
end

local function getNearestCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart

    local nearestCoin = nil
    local minDistance = 999999

    local coins = findAllCoins()
    for _, coin in ipairs(coins) do
        local dist = (root.Position - coin.Position).Magnitude
        if dist < minDistance then
            minDistance = dist
            nearestCoin = coin
        end
    end
    
    return nearestCoin
end

-- ========================================================
-- АВТОФАРМ МОНЕТ (ИСПРАВЛЕННЫЙ)
-- ========================================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoFarm then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                -- Включаем Noclip
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                
                local coin = getNearestCoin()
                if coin then
                    -- Увеличиваем хитбокс монеты
                    pcall(function()
                        coin.Size = Vector3.new(_G.CoinHitboxSize, _G.CoinHitboxSize, _G.CoinHitboxSize)
                        coin.CanCollide = false
                        coin.Transparency = 0.5
                    end)
                    
                    -- Телепорт на монету (над ней)
                    root.CFrame = CFrame.new(coin.Position.X, coin.Position.Y + 3, coin.Position.Z)
                    root.Velocity = Vector3.new(0, 0, 0)
                else
                    notify("Монеты не найдены! Ищем...")
                end
            end
        end
    end
end)

-- ========================================================
-- СКОРОСТЬ ПЕРСОНАЖА
-- ========================================================
task.spawn(function()
    while true do
        task.wait(0.2)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if _G.AutoFarm and _G.FarmSpeed >= 16 then
                    hum.WalkSpeed = _G.FarmSpeed
                else
                    hum.WalkSpeed = 16
                end
            end
        end
    end
end)

-- ========================================================
-- ESP ОРУЖИЯ
-- ========================================================
local activeGunHighlight = nil

local function clearGunESP()
    if activeGunHighlight then
        activeGunHighlight:Destroy()
        activeGunHighlight = nil
    end
end

task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.GunESP then
            local gunDrop = Workspace:FindFirstChild("GunDrop") or Workspace:FindFirstChild("Gun")
            
            if gunDrop and (gunDrop:IsA("BasePart") or gunDrop:IsA("Model")) then
                if not activeGunHighlight or activeGunHighlight.Parent ~= gunDrop then
                    clearGunESP()
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "Gun_ESP_Highlight"
                    highlight.FillColor = SheriffColor
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.1
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = gunDrop
                    activeGunHighlight = highlight
                end
            else
                clearGunESP()
            end
        else
            clearGunESP()
        end
    end
end)

-- ========================================================
-- ANTI-AFK
-- ========================================================
LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
    end
end)

-- ========================================================
-- АВТО-ПЕРЕЗАХОД
-- ========================================================
GuiService.ErrorMessageChanged:Connect(function()
    if _G.AutoRejoin then
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- ========================================================
-- FPS BOOST
-- ========================================================
local Lighting = game:GetService("Lighting")

task.spawn(function()
    while true do
        task.wait(1)
        if _G.FPSBoostEnabled then
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                
                for _, v in ipairs(Lighting:GetChildren()) do
                    if v:IsA("PostEffect") or v:IsA("Atmosphere") then
                        v.Enabled = false
                    end
                end
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                        obj.Enabled = false
                    end
                end
            end)
        end
    end
end)

-- ========================================================
-- ХИТБОКС МАРДЕРА
-- ========================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.HitboxEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and getMM2Role(player) == "Murderer" then
                    local char = player.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            pcall(function()
                                hrp.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                                hrp.Transparency = _G.HitboxTransparency
                                hrp.Color = Color3.fromRGB(255, 0, 0)
                                hrp.Material = Enum.Material.ForceField
                                hrp.CanCollide = false
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ========================================================
-- ФЕЙКОВЫЙ НИК
-- ========================================================
local function applyFakeName()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and _G.FakeName ~= "" then
        char.Humanoid.DisplayName = _G.FakeName
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    applyFakeName()
end)

-- ========================================================
-- СБОРКА ИНТЕРФЕЙСА
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "MM2 Ultimate Hub",
    LoadingTitle = "MM2 Script",
    LoadingSubtitle = "Fixed for Delta",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab("Главная", 4483362458)
local MiscTab = Window:CreateTab("Разное", 4483362458)

-- Главная вкладка
MainTab:CreateToggle({
    Name = "ESP / Подсветка игроков",
    CurrentValue = _G.RolesESP,
    Callback = function(Value)
        _G.RolesESP = Value
    end,
})

MainTab:CreateToggle({
    Name = "Auto-farm / Авто-фарм монет",
    CurrentValue = _G.AutoFarm,
    Callback = function(Value)
        _G.AutoFarm = Value
        if Value then
            notify("Авто-фарм включен! Ищу монеты...")
        else
            notify("Авто-фарм выключен")
        end
    end,
})

MainTab:CreateSlider({
    Name = "Скорость персонажа",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = _G.FarmSpeed,
    Callback = function(Value)
        _G.FarmSpeed = Value
    end,
})

MainTab:CreateSlider({
    Name = "Размер хитбокса монет",
    Range = {3, 20},
    Increment = 1,
    CurrentValue = _G.CoinHitboxSize,
    Callback = function(Value)
        _G.CoinHitboxSize = Value
    end,
})

MainTab:CreateToggle({
    Name = "ESP Оружия",
    CurrentValue = _G.GunESP,
    Callback = function(Value)
        _G.GunESP = Value
    end,
})

MainTab:CreateToggle({
    Name = "Увеличить хитбокс Мардера",
    CurrentValue = _G.HitboxEnabled,
    Callback = function(Value)
        _G.HitboxEnabled = Value
    end,
})

MainTab:CreateSlider({
    Name = "Размер хитбокса Мардера",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = _G.HitboxSize,
    Callback = function(Value)
        _G.HitboxSize = Value
    end,
})

-- Разное
MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = _G.AntiAFK,
    Callback = function(Value)
        _G.AntiAFK = Value
    end,
})

MiscTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = _G.FPSBoostEnabled,
    Callback = function(Value)
        _G.FPSBoostEnabled = Value
    end,
})

MiscTab:CreateInput({
    Name = "Фейковый ник",
    PlaceholderText = "Введите имя...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        _G.FakeName = Text
        applyFakeName()
    end,
})

MiscTab:CreateButton({
    Name = "Телепорт к ближайшей монете",
    Callback = function()
        local coin = getNearestCoin()
        local char = LocalPlayer.Character
        if coin and char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(coin.Position + Vector3.new(0, 3, 0))
            notify("Телепортирован к монете!")
        else
            notify("Монеты не найдены!")
        end
    end,
})

MiscTab:CreateButton({
    Name = "Показать количество монет",
    Callback = function()
        local coins = findAllCoins()
        notify("Найдено монет: " .. #coins)
    end,
})

Rayfield:LoadConfiguration()
notify("Скрипт загружен успешно!")
