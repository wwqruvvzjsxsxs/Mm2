-- ========================================================
-- MM2 ULTIMATE HUB - ИСПРАВЛЕННАЯ ВЕРСИЯ
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Уведомления
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Icon = "rbxassetid://4483362458"
        })
    end)
end

-- Настройки
_G.ESPEnabled = true
_G.InnocentColor = Color3.fromRGB(0, 255, 0)
_G.MurdererColor = Color3.fromRGB(255, 0, 0)
_G.SheriffColor = Color3.fromRGB(0, 0, 255)
_G.AutoFarm = false
_G.FarmMode = "OnMap"
_G.FarmDelay = 0.5
_G.FarmHeight = -2.5
_G.SizeEnabled = false
_G.SizeScale = 0.5
_G.AutoKillEnabled = false
_G.AutoKillCoins = 40

local originalGravity = Workspace.Gravity

-- Определение роли
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

-- Проверка: в игре ли мы
local function isInGame()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- Получение количества монет
local function getCoinCount()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("coins") or leaderstats:FindFirstChild("Монеты")
        if coins and coins:IsA("IntValue") then
            return coins.Value
        end
    end
    
    return 0
end

-- Убить себя
local function killSelf()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    hum.Health = 0
    return true
end

-- Поиск монет
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

local function getNearestCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart

    local nearestCoin = nil
    local minDistance = 999999

    for _, coin in ipairs(findAllCoins()) do
        local dist = (root.Position - coin.Position).Magnitude
        if dist < minDistance then
            minDistance = dist
            nearestCoin = coin
        end
    end
    
    return nearestCoin
end

-- ========================================================
-- СИСТЕМА ИЗМЕНЕНИЯ РАЗМЕРА
-- ========================================================
local originalSizes = {}

local function saveOriginalSizes(char)
    originalSizes = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            originalSizes[part] = {
                Size = part.Size
            }
        end
    end
end

local function applySizeScale(char, scale)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    humanoid.HipHeight = 2 * scale
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= rootPart then
            if not originalSizes[part] then
                originalSizes[part] = { Size = part.Size }
            end
            local originalSize = originalSizes[part].Size
            part.Size = Vector3.new(
                originalSize.X * scale,
                originalSize.Y * scale,
                originalSize.Z * scale
            )
        elseif part:IsA("MeshPart") then
            if not originalSizes[part] then
                originalSizes[part] = { Size = part.Size }
            end
            local originalSize = originalSizes[part].Size
            part.Size = Vector3.new(
                originalSize.X * scale,
                originalSize.Y * scale,
                originalSize.Z * scale
            )
        end
    end
    
    if not originalSizes[rootPart] then
        originalSizes[rootPart] = { Size = rootPart.Size }
    end
    local rootOriginalSize = originalSizes[rootPart].Size
    rootPart.Size = Vector3.new(
        rootOriginalSize.X * scale,
        rootOriginalSize.Y * scale,
        rootOriginalSize.Z * scale
    )
end

local function restoreOriginalSize(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HipHeight = 2
    end
    
    for part, data in pairs(originalSizes) do
        if part and part.Parent then
            part.Size = data.Size
        end
    end
    
    originalSizes = {}
end

-- Мониторинг размера
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.SizeEnabled then
            local char = LocalPlayer.Character
            if char then
                applySizeScale(char, _G.SizeScale)
            end
        end
    end
end)

-- Применяем размер при возрождении
LocalPlayer.CharacterAdded:Connect(function(char)
    if _G.SizeEnabled then
        task.wait(1)
        saveOriginalSizes(char)
        applySizeScale(char, _G.SizeScale)
    end
end)

-- ========================================================
-- ESP СИСТЕМА (ИГРОКИ)
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
        targetColor = _G.MurdererColor
    elseif role == "Sheriff" then
        targetColor = _G.SheriffColor
    end

    local hl = activeHighlights[player]
    if not hl or hl.Parent ~= char then
        removeHighlight(player)
        hl = Instance.new("Highlight")
        hl.Name = "MM2_ESP_Highlight"
        hl.FillColor = targetColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.3
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        activeHighlights[player] = hl
    else
        hl.FillColor = targetColor
        hl.FillTransparency = 0.3
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.ESPEnabled then
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
-- СИСТЕМА АВТО ФАРМА
-- ========================================================
local farmTween = nil
local farmBodyVelocity = nil

local function enableUnderMapPhysics()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    if not farmBodyVelocity or farmBodyVelocity.Parent ~= hrp then
        if farmBodyVelocity then farmBodyVelocity:Destroy() end
        farmBodyVelocity = Instance.new("BodyVelocity")
        farmBodyVelocity.Name = "FarmAntiFall"
        farmBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        farmBodyVelocity.Velocity = Vector3.zero
        farmBodyVelocity.Parent = hrp
    end
end

local function disableFarmPhysics()
    if farmBodyVelocity then
        farmBodyVelocity:Destroy()
        farmBodyVelocity = nil
    end
    if farmTween then
        farmTween:Cancel()
        farmTween = nil
    end
end

local function getUnderMapPosition(coinPos)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local ignoreList = {}
    if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
    for _, coin in ipairs(findAllCoins()) do table.insert(ignoreList, coin) end
    raycastParams.FilterDescendantsInstances = ignoreList

    local rayResult = Workspace:Raycast(coinPos, Vector3.new(0, -30, 0), raycastParams)
    
    if rayResult then
        return Vector3.new(coinPos.X, rayResult.Position.Y + _G.FarmHeight, coinPos.Z)
    else
        return Vector3.new(coinPos.X, coinPos.Y + _G.FarmHeight - 2, coinPos.Z)
    end
end

local function expandCoinHitbox(coin)
    pcall(function()
        if coin:IsA("BasePart") then
            if not coin:GetAttribute("OriginalSize") then
                coin:SetAttribute("OriginalSize", coin.Size)
            end
            local originalSize = coin:GetAttribute("OriginalSize")
            coin.Size = Vector3.new(originalSize.X * 3, originalSize.Y * 3, originalSize.Z * 3)
            coin.CanCollide = false
            coin.Transparency = 0.3
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(_G.FarmDelay)
        
        if _G.AutoFarm then
            if not isInGame() then
                notify("❌ ОШИБКА", "Вы не в игре! Фарм отключен!", 3)
                _G.AutoFarm = false
                disableFarmPhysics()
                continue
            end
            
            -- Проверяем автокилл
            if _G.AutoKillEnabled then
                local coinCount = getCoinCount()
                if coinCount >= _G.AutoKillCoins then
                    notify("💀 АВТОКИЛЛ", "Собрано " .. coinCount .. " монет! Умираю...", 3)
                    killSelf()
                    task.wait(2)
                end
            end
            
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local coin = getNearestCoin()
                if coin then
                    expandCoinHitbox(coin)
                    
                    if _G.FarmMode == "UnderMap" then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                        
                        enableUnderMapPhysics()
                        
                        local targetPos = getUnderMapPosition(coin.Position)
                        local distance = (root.Position - targetPos).Magnitude
                        local speed = 40 
                        local tweenTime = math.clamp(distance / speed, 0.05, _G.FarmDelay)
                        
                        farmTween = TweenService:Create(root, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
                        farmTween:Play()
                        farmTween.Completed:Wait()
                        
                        pcall(function()
                            if firetouchinterest then
                                firetouchinterest(root, coin, 0)
                                firetouchinterest(root, coin, 1)
                            end
                        end)
                    else
                        disableFarmPhysics()
                        
                        local targetY = coin.Position.Y + _G.FarmHeight
                        root.CFrame = CFrame.new(coin.Position.X, targetY, coin.Position.Z)
                        root.Velocity = Vector3.zero
                    end
                end
            end
        else
            disableFarmPhysics()
        end
    end
end)

-- ========================================================
-- ИНТЕРФЕЙС
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "MM2 Ultimate Hub",
    LoadingTitle = "MM2 Script",
    LoadingSubtitle = "ESP + Farm + Size + AutoKill",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local VisualTab = Window:CreateTab("👁️ Визуализация", 4483362458)
local FarmTab = Window:CreateTab("🪙 Фарм", 4483362458)
local MiscTab = Window:CreateTab("🔧 Прочее", 4483362458)

-- ВКЛАДКА: ВИЗУАЛИЗАЦИЯ
VisualTab:CreateSection("ESP Настройки")

VisualTab:CreateToggle({
    Name = "👁️ ESP / Подсветка игроков",
    CurrentValue = _G.ESPEnabled,
    Callback = function(Value)
        _G.ESPEnabled = Value
        if Value then
            notify("👁️ ESP ВКЛЮЧЕН", "Игроки подсвечиваются сквозь стены", 3)
        else
            notify("🚫 ESP ВЫКЛЮЧЕН", "Подсветка отключена", 3)
        end
    end,
})

VisualTab:CreateSection("Цвета ролей")

VisualTab:CreateColorPicker({
    Name = "🟢 Цвет невинных",
    Color = _G.InnocentColor,
    Callback = function(Value)
        _G.InnocentColor = Value
    end,
})

VisualTab:CreateColorPicker({
    Name = "🔴 Цвет мардера",
    Color = _G.MurdererColor,
    Callback = function(Value)
        _G.MurdererColor = Value
    end,
})

VisualTab:CreateColorPicker({
    Name = "🔵 Цвет шерифа",
    Color = _G.SheriffColor,
    Callback = function(Value)
        _G.SheriffColor = Value
    end,
})

-- ВКЛАДКА: ФАРМ
FarmTab:CreateSection("Авто фарм")

FarmTab:CreateToggle({
    Name = "🪙 Авто фарм монет",
    CurrentValue = _G.AutoFarm,
    Callback = function(Value)
        _G.AutoFarm = Value
        if Value then
            if not isInGame() then
                notify("❌ ОШИБКА", "Вы не в игре!", 3)
                _G.AutoFarm = false
                return
            end
            notify("🪙 ФАРМ ВКЛЮЧЕН", "Собираю монеты...", 3)
        else
            notify("🚫 ФАРМ ВЫКЛЮЧЕН", "Остановлен", 3)
            disableFarmPhysics()
        end
    end,
})

FarmTab:CreateDropdown({
    Name = "Режим фарма",
    Options = {"На карте", "Под картой"},
    CurrentOption = {"На карте"},
    MultipleOptions = false,
    Callback = function(Option)
        if Option[1] == "На карте" then
            _G.FarmMode = "OnMap"
            disableFarmPhysics()
        else
            _G.FarmMode = "UnderMap"
        end
        notify("🔄 РЕЖИМ ФАРМА", "Выбран: " .. Option[1], 3)
    end,
})

FarmTab:CreateSlider({
    Name = "Скорость сборки монет",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "сек",
    CurrentValue = _G.FarmDelay,
    Callback = function(Value)
        _G.FarmDelay = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Высота сбора монет",
    Range = {-10, 10},
    Increment = 0.5,
    Suffix = " блоков",
    CurrentValue = -2.5,
    Callback = function(Value)
        _G.FarmHeight = Value
        notify("📏 ВЫСОТА", "Высота: " .. Value .. " от монеты", 2)
    end,
})

FarmTab:CreateSection("Автокилл")

FarmTab:CreateToggle({
    Name = "💀 Убить при заполнении рюкзака",
    CurrentValue = _G.AutoKillEnabled,
    Callback = function(Value)
        _G.AutoKillEnabled = Value
        if Value then
            notify("💀 АВТОКИЛЛ ВКЛЮЧЕН", "Вы умрете при " .. _G.AutoKillCoins .. " монетах", 3)
        else
            notify("🚫 АВТОКИЛЛ ВЫКЛЮЧЕН", "Функция отключена", 3)
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Монет для смерти",
    Range = {10, 100},
    Increment = 5,
    Suffix = " монет",
    CurrentValue = _G.AutoKillCoins,
    Callback = function(Value)
        _G.AutoKillCoins = Value
        notify("💀 НАСТРОЙКА", "Смерть при " .. Value .. " монетах", 2)
    end,
})

-- ВКЛАДКА: ПРОЧЕЕ
MiscTab:CreateSection("Изменение размера")

MiscTab:CreateToggle({
    Name = "📏 Уменьшить персонажа",
    CurrentValue = _G.SizeEnabled,
    Callback = function(Value)
        _G.SizeEnabled = Value
        local char = LocalPlayer.Character
        
        if Value then
            if char then
                saveOriginalSizes(char)
                applySizeScale(char, _G.SizeScale)
                notify("📏 РАЗМЕР ИЗМЕНЕН", "Вы уменьшены до " .. (_G.SizeScale * 100) .. "%", 3)
            end
        else
            if char then
                restoreOriginalSize(char)
                notify("📏 РАЗМЕР ВОССТАНОВЛЕН", "Вы снова нормального размера", 3)
            end
        end
    end,
})

MiscTab:CreateSlider({
    Name = "Размер персонажа",
    Range = {20, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 50,
    Callback = function(Value)
        _G.SizeScale = Value / 100
        if _G.SizeEnabled then
            local char = LocalPlayer.Character
            if char then
                saveOriginalSizes(char)
                applySizeScale(char, _G.SizeScale)
            end
        end
    end,
})

notify("✅ СКРИПТ ЗАГРУЖЕН!", "Все функции активированы!", 5)
