-- ========================================================
-- MM2 ULTIMATE HUB - ESP + АВТОФАРМ + АВТОСМЕРТЬ + НЕУЯЗВИМОСТЬ
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Уведомления
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Button1 = "OK",
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
_G.AutoKillEnabled = false
_G.AutoKillCoins = 40
_G.SafeDistance = 10
_G.GodMode = false

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

-- Получение позиции мардера
local function getMurdererPosition()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local role = getMM2Role(player)
            if role == "Murderer" then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    return hrp.Position, player
                end
            end
        end
    end
    return nil, nil
end

-- Проверка безопасности позиции
local function isSafePosition(pos)
    local murdererPos = getMurdererPosition()
    if murdererPos then
        local distance = (pos - murdererPos).Magnitude
        return distance >= _G.SafeDistance
    end
    return true
end

-- Получение количества монет (Улучшено для MM2)
local function getCoinCount()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui and playerGui:FindFirstChild("MainGUI") then
            -- Читаем напрямую из интерфейса MM2
            local coinText = playerGui.MainGUI.Game.CashBag.Container.CoinContainer.CoinTotal.Text
            local current = tonumber(coinText:match("%d+"))
            if current then return current end
        end
    end)
    return 0
end

-- Убить себя (Переделано: Падение в пустоту гарантирует смерть в MM2)
local function killSelf()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        -- Телепорт далеко вниз, игра убьет моментально
        hrp.CFrame = CFrame.new(0, -9999, 0)
        hrp.Velocity = Vector3.new(0, -500, 0)
        return true
    end
    return false
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

-- Поиск ближайшей безопасной монеты
local function getNearestSafeCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart

    local nearestCoin = nil
    local minDistance = 999999
    local murdererPos = getMurdererPosition()

    for _, coin in ipairs(findAllCoins()) do
        if murdererPos then
            local distanceToMurderer = (coin.Position - murdererPos).Magnitude
            if distanceToMurderer < _G.SafeDistance then
                continue
            end
        end
        
        local dist = (root.Position - coin.Position).Magnitude
        if dist < minDistance then
            minDistance = dist
            nearestCoin = coin
        end
    end
    
    return nearestCoin
end

-- ========================================================
-- СИСТЕМА НЕУЯЗВИМОСТИ (УЛУЧШЕНА)
-- ========================================================
local originalSizes = {}

local function enableGodMode()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Сжимаем хитбоксы, чтобы в нас было физически невозможно попасть
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not originalSizes[part] then
                originalSizes[part] = part.Size
            end
            part.Size = Vector3.new(0.05, 0.05, 0.05)
            part.CanCollide = false
        end
    end
end

local function disableGodMode()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Возвращаем нормальный размер
    for part, size in pairs(originalSizes) do
        if part and part.Parent then
            part.Size = size
            part.CanCollide = true
        end
    end
    originalSizes = {}
end

-- Мониторинг God Mode (Удаление ножей и авто-уклонение)
task.spawn(function()
    while true do
        task.wait(0.05) -- Быстрый цикл для уклонения
        if _G.GodMode and isInGame() then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- 1. Уничтожаем брошенные в нас ножи
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name == "Knife" or obj.Name == "ThrowingKnife") then
                        local dist = (hrp.Position - obj.Position).Magnitude
                        if dist < 12 then
                            obj:Destroy()
                        end
                    end
                end
                
                -- 2. Авто-додж (если мардер подошел вплотную)
                local murdererPos, murdererPlayer = getMurdererPosition()
                if murdererPos and murdererPlayer and murdererPlayer.Character then
                    local mHrp = murdererPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if mHrp then
                        local dist = (hrp.Position - mHrp.Position).Magnitude
                        if dist < 8 then
                            -- Телепорт ему за спину и немного вверх
                            hrp.CFrame = mHrp.CFrame * CFrame.new(0, 5, 5) 
                        end
                    end
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if _G.GodMode then
        enableGodMode()
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
-- СИСТЕМА АВТО ФАРМА И АВТОКИЛЛА
-- ========================================================
local farmTween = nil
local farmBodyVelocity = nil
local farmActive = false

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

-- Мониторинг Автокилла
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoKillEnabled and _G.AutoFarm and isInGame() then
            local coinCount = getCoinCount()
            if coinCount >= _G.AutoKillCoins and coinCount > 0 then
                notify("💀 АВТОКИЛЛ", "Собрано " .. coinCount .. " монет! Убиваю персонажа...", 5)
                killSelf()
                task.wait(5) -- Пауза на время возрождения
            end
        end
    end
end)

-- Главный цикл фарма
task.spawn(function()
    while true do
        task.wait(0.1)
        
        if _G.AutoFarm then
            if isInGame() then
                farmActive = true
                
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                if root and hum and hum.Health > 0 then
                    local coin = getNearestSafeCoin()
                    
                    if coin and isSafePosition(coin.Position) then
                        expandCoinHitbox(coin)
                        
                        if _G.FarmMode == "UnderMap" then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                    part.CanCollide = false
                                end
                            end
                            
                            enableUnderMapPhysics()
                            
                            local targetPos = getUnderMapPosition(coin.Position)
                            local distance = (root.Position - targetPos).Magnitude
                            local speed = 30
                            local tweenTime = math.clamp(distance / speed, 0.1, _G.FarmDelay)
                            
                            farmTween = TweenService:Create(root, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
                            farmTween:Play()
                            farmTween.Completed:Wait()
                        else
                            disableFarmPhysics()
                            local targetY = coin.Position.Y + _G.FarmHeight
                            root.CFrame = CFrame.new(coin.Position.X, targetY, coin.Position.Z)
                            root.Velocity = Vector3.zero
                        end
                        
                        -- НОВОЕ: Микро-движения для точного подбора монеты
                        local wiggleOffsets = {
                            Vector3.new(1.5, 0, 0),
                            Vector3.new(-1.5, 0, 0),
                            Vector3.new(0, 0, 1.5),
                            Vector3.new(0, 0, -1.5)
                        }
                        for _, offset in ipairs(wiggleOffsets) do
                            root.CFrame = root.CFrame + offset
                            task.wait(0.05)
                        end
                        
                        pcall(function()
                            if firetouchinterest then
                                firetouchinterest(root, coin, 0)
                                firetouchinterest(root, coin, 1)
                            end
                        end)
                        
                        task.wait(_G.FarmDelay)
                    else
                        task.wait(0.5)
                    end
                end
            else
                if farmActive then
                    farmActive = false
                    disableFarmPhysics()
                end
                task.wait(1)
            end
        else
            if farmActive then
                farmActive = false
                disableFarmPhysics()
            end
            task.wait(0.5)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    
    if _G.GodMode then
        enableGodMode()
    end
    
    if _G.AutoFarm then
        farmActive = false
        notify("🪙 ФАРМ", "Продолжаю сбор монет...", 3)
    end
end)

-- ========================================================
-- ИНТЕРФЕЙС
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "MM2 Ultimate Hub",
    LoadingTitle = "MM2 Script",
    LoadingSubtitle = "ESP + Farm + GodMode + AutoKill",
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
        notify(Value and "👁️ ESP ВКЛЮЧЕН" or "🚫 ESP ВЫКЛЮЧЕН", "", 3)
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
                notify("⏳ ФАРМ ВКЛЮЧЕН", "Начнется когда вы зайдете в раунд", 3)
            else
                notify("🪙 ФАРМ ВКЛЮЧЕН", "Собираю монеты...", 3)
            end
        else
            farmActive = false
            disableFarmPhysics()
            notify("🚫 ФАРМ ВЫКЛЮЧЕН", "Остановлен", 3)
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
    Range = {0.5, 3},
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
    end,
})

FarmTab:CreateSlider({
    Name = "Безопасная дистанция от мардера",
    Range = {5, 30},
    Increment = 1,
    Suffix = " блоков",
    CurrentValue = 10,
    Callback = function(Value)
        _G.SafeDistance = Value
    end,
})

FarmTab:CreateSection("Автокилл")

FarmTab:CreateToggle({
    Name = "💀 Убить при заполнении рюкзака",
    CurrentValue = _G.AutoKillEnabled,
    Callback = function(Value)
        _G.AutoKillEnabled = Value
        if Value then
            notify("💀 АВТОКИЛЛ ВКЛЮЧЕН", "Смерть при " .. _G.AutoKillCoins .. " монетах", 3)
        else
            notify("🚫 АВТОКИЛЛ ВЫКЛЮЧЕН", "Функция отключена", 3)
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Монет для смерти",
    Range = {10, 50},
    Increment = 1,
    Suffix = " монет",
    CurrentValue = _G.AutoKillCoins,
    Callback = function(Value)
        _G.AutoKillCoins = Value
    end,
})

-- ВКЛАДКА: ПРОЧЕЕ
MiscTab:CreateSection("Неуязвимость")

MiscTab:CreateToggle({
    Name = "🛡️ Неуязвимость (God Mode / Auto Dodge)",
    CurrentValue = _G.GodMode,
    Callback = function(Value)
        _G.GodMode = Value
        if Value then
            enableGodMode()
            notify("🛡️ GOD MODE ВКЛЮЧЕН", "Хитбоксы сжаты, уклонение активировано!", 3)
        else
            disableGodMode()
            notify("🚫 GOD MODE ВЫКЛЮЧЕН", "Вы снова уязвимы", 3)
        end
    end,
})

notify("✅ СКРИПТ ОБНОВЛЕН!", "Новые функции активированы!", 5)

