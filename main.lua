-- ========================================================
-- MM2 ULTIMATE HUB - MOBILE FIXED EDITION
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Уведомления
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 4,
            Icon = "rbxassetid://4483362458"
        })
    end)
end

-- ВСЕ НАСТРОЙКИ ВЫКЛЮЧЕНЫ ПО УМОЛЧАНИЮ
_G.ESPEnabled = false
_G.InnocentColor = Color3.fromRGB(0, 255, 0)
_G.MurdererColor = Color3.fromRGB(255, 0, 0)
_G.SheriffColor = Color3.fromRGB(0, 0, 255)

_G.GunESP = false
_G.GunColor = Color3.fromRGB(0, 0, 0)

_G.FlyEnabled = false
_G.FlySpeed = 50

_G.PhantomMode = false
_G.PhantomColor = Color3.fromRGB(255, 105, 180)

_G.AutoFarm = false
_G.FarmMode = "OnMap"
_G.FarmDelay = 0.5
_G.FarmHeight = -3

_G.HardAimEnabled = false
_G.AutoShoot = false
_G.AimTargetPart = "HumanoidRootPart"

-- Определение роли
local function getMM2Role(player)
    if not player then return "Innocent" end
    local char = player.Character
    if not char then return "Innocent" end
    
    if char:FindFirstChild("Knife") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife")) then
        return "Murderer"
    elseif char:FindFirstChild("Gun") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    
    return "Innocent"
end

local function isInGame()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isRoundActive()
    if not isInGame() then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and getMM2Role(player) ~= "Innocent" then
            return true
        end
    end
    return false
end

-- ========================================================
-- ПОИСК И КЕШИРОВАНИЕ МАРДЕРА
-- ========================================================
local cachedMurderer = nil

task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.HardAimEnabled then
            local found = nil
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and getMM2Role(player) == "Murderer" then
                        found = player
                        break
                    end
                end
            end
            cachedMurderer = found
        else
            cachedMurderer = nil
        end
    end
end)

-- АВТО-СТРЕЛЬБА ДЛЯ МОБИЛЬНЫХ
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.HardAimEnabled and _G.AutoShoot and cachedMurderer and cachedMurderer.Character then
            local char = LocalPlayer.Character
            if char then
                local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Pistol")
                if gun and gun:IsA("Tool") then
                    pcall(function()
                        gun:Activate() -- Имитирует тап выстрела на телефоне
                    end)
                end
            end
        end
    end
end)

-- SILENT AIM (ПЕРЕХВАТ ПУЛИ БЕЗ ЗАВИСАНИЯ КАМЕРЫ)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if _G.HardAimEnabled and not checkcaller() then
        if method == "Raycast" or method == "FindPartOnWithIgnoreList" or method == "findPartOnWithIgnoreList" then
            local char = LocalPlayer.Character
            if char and (char:FindFirstChild("Gun") or char:FindFirstChild("Pistol")) then
                if cachedMurderer and cachedMurderer.Character then
                    local targetPart = cachedMurderer.Character:FindFirstChild(_G.AimTargetPart) or cachedMurderer.Character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local args = {...}
                        if method == "Raycast" and #args >= 2 then
                            args[2] = (targetPart.Position - args[1]).Unit * 1000
                            return oldNamecall(self, unpack(args))
                        elseif (method == "FindPartOnWithIgnoreList" or method == "findPartOnWithIgnoreList") and typeof(args[1]) == "Ray" then
                            args[1] = Ray.new(args[1].Origin, (targetPart.Position - args[1].Origin).Unit * 1000)
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end
            end
        end
    end

    return oldNamecall(self, ...)
end))

-- ========================================================
-- ESP И ПОДСВЕТКА
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
    if not char then removeHighlight(player) return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then removeHighlight(player) return end

    local role = getMM2Role(player)
    local targetColor = _G.InnocentColor
    if role == "Murderer" then targetColor = _G.MurdererColor
    elseif role == "Sheriff" then targetColor = _G.SheriffColor end

    local hl = activeHighlights[player]
    if not hl or hl.Parent ~= char then
        removeHighlight(player)
        hl = Instance.new("Highlight")
        hl.Name = "MM2_ESP_Highlight"
        hl.FillColor = targetColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.3
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        activeHighlights[player] = hl
    else
        hl.FillColor = targetColor
    end
end

local activeGunHighlights = {}

local function updateGunESP()
    for gun, highlight in pairs(activeGunHighlights) do
        if highlight and highlight.Parent then highlight:Destroy() end
    end
    activeGunHighlights = {}
    
    if not _G.GunESP then return end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("pistol")) then
            if not obj:FindFirstAncestorOfClass("Model") or not obj:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid") then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = _G.GunColor
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = obj
                activeGunHighlights[obj] = highlight
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.4)
        if _G.ESPEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                updatePlayerESP(player)
            end
        else
            for player, _ in pairs(activeHighlights) do removeHighlight(player) end
        end
        updateGunESP()
    end
end)

Players.PlayerRemoving:Connect(removeHighlight)

-- ========================================================
-- МОБИЛЬНЫЙ ФЛАЙ
-- ========================================================
local flyBodyVelocity = nil
local flyBodyGyro = nil

local function stopFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    hum.PlatformStand = true
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = hrp
    
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.P = 10000
    flyBodyGyro.D = 100
    flyBodyGyro.Parent = hrp
end

RunService.RenderStepped:Connect(function()
    if not _G.FlyEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum or hum.Health <= 0 then stopFly() return end
    if not flyBodyVelocity or not flyBodyGyro then startFly() end
    
    if flyBodyVelocity and flyBodyGyro then
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        local joyDirection = hum.MoveDirection
        local moveDirection = Vector3.zero
        
        if joyDirection.Z < 0 then moveDirection += camera.CFrame.LookVector
        elseif joyDirection.Z > 0 then moveDirection -= camera.CFrame.LookVector end
        
        if joyDirection.X > 0 then moveDirection += camera.CFrame.RightVector
        elseif joyDirection.X < 0 then moveDirection -= camera.CFrame.RightVector end
        
        if moveDirection.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveDirection.Unit * _G.FlySpeed
        else
            flyBodyVelocity.Velocity = Vector3.zero
        end
        flyBodyGyro.CFrame = camera.CFrame
    end
end)

-- ========================================================
-- АВТО ФАРМ МОНЕТ
-- ========================================================
local function findAllCoins()
    local coins = {}
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

task.spawn(function()
    while true do
        task.wait(_G.FarmDelay)
        if _G.AutoFarm and isInGame() then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local coins = findAllCoins()
                if #coins > 0 then
                    local coin = coins[1]
                    root.CFrame = CFrame.new(coin.Position.X, coin.Position.Y + _G.FarmHeight, coin.Position.Z)
                end
            end
        end
    end
end)

-- ========================================================
-- УБИЙСТВО ВСЕХ
-- ========================================================
local function killAll()
    if getMM2Role(LocalPlayer) ~= "Murderer" or not isInGame() then
        notify("❌ ОШИБКА", "Вы не Мардер или не в игре!", 3)
        return
    end
    
    notify("💀 УБИЙСТВО ВСЕХ", "Убиваю игроков...", 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and targetHrp and myHrp then
                myHrp.CFrame = CFrame.new(targetHrp.Position + Vector3.new(0, 2, 0))
                hum.Health = 0
                task.wait(0.1)
            end
        end
    end
end

-- ========================================================
-- ИНТЕРФЕЙС (RAYFIELD)
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "MM2 Hub (Mobile Fixed)",
    LoadingTitle = "MM2 Mobile",
    LoadingSubtitle = "All Disabled By Default",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local CombatTab = Window:CreateTab("⚔️ Сражение", 4483362458)
local VisualTab = Window:CreateTab("👁️ Визуализация", 4483362458)
local FarmTab = Window:CreateTab("🪙 Фарм", 4483362458)
local MiscTab = Window:CreateTab("🔧 Прочее", 4483362458)

-- Вкладка Сражение
CombatTab:CreateSection("Боевые функции")
CombatTab:CreateButton({
    Name = "💀 Убить всех (Мардер)",
    Callback = function() killAll() end,
})

CombatTab:CreateSection("Аимбот для мобильных")
CombatTab:CreateToggle({
    Name = "🎯 Аимбот на Мардера (Silent Aim)",
    CurrentValue = false,
    Callback = function(Value)
        _G.HardAimEnabled = Value
    end,
})

CombatTab:CreateToggle({
    Name = "🔥 Авто-выстрел (при доставшем песте)",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoShoot = Value
    end,
})

CombatTab:CreateDropdown({
    Name = "Часть тела цели",
    Options = {"HumanoidRootPart", "Head"},
    CurrentOption = {"HumanoidRootPart"},
    MultipleOptions = false,
    Callback = function(Option)
        _G.AimTargetPart = Option[1]
    end,
})

-- Вкладка Визуализация
VisualTab:CreateSection("ESP Игроков")
VisualTab:CreateToggle({
    Name = "👁️ ESP Подсветка",
    CurrentValue = false,
    Callback = function(Value) _G.ESPEnabled = Value end,
})

VisualTab:CreateSection("ESP Оружия")
VisualTab:CreateToggle({
    Name = "🔫 Подсветка выпавшего оружия",
    CurrentValue = false,
    Callback = function(Value) _G.GunESP = Value end,
})

-- Вкладка Фарм
FarmTab:CreateSection("Авто фарм")
FarmTab:CreateToggle({
    Name = "🪙 Фарм монет",
    CurrentValue = false,
    Callback = function(Value) _G.AutoFarm = Value end,
})

-- Вкладка Прочее
MiscTab:CreateSection("Флай")
MiscTab:CreateToggle({
    Name = "✈️ Флай (Движение по камере)",
    CurrentValue = false,
    Callback = function(Value)
        _G.FlyEnabled = Value
        if Value then startFly() else stopFly() end
    end,
})

MiscTab:CreateSlider({
    Name = "Скорость полета",
    Range = {20, 150},
    Increment = 10,
    CurrentValue = 50,
    Callback = function(Value) _G.FlySpeed = Value end,
})

notify("✅ СКРИПТ ГОТОВ", "Все функции отключены при старте!", 4)

