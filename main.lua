-- ========================================================
-- MM2 ULTIMATE HUB - НОВАЯ ВЕРСИЯ
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

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
_G.InnocentColor = Color3.fromRGB(0, 255, 0) -- Зеленый по умолчанию
_G.MurdererColor = Color3.fromRGB(255, 0, 0) -- Красный (строго)
_G.SheriffColor = Color3.fromRGB(0, 0, 255) -- Синий (строго)
_G.GunESP = true -- Подсветка оружия
_G.GunColor = Color3.fromRGB(0, 0, 0) -- Черный цвет для оружия
_G.FlyEnabled = false
_G.FlySpeed = 50
_G.PhantomMode = false -- Фантомный призрак
_G.PhantomColor = Color3.fromRGB(255, 105, 180) -- Розовый цвет для себя
_G.AutoFarm = false -- Авто фарм
_G.FarmMode = "OnMap" -- Режим фарма: "OnMap" или "UnderMap"
_G.FarmDelay = 0.5 -- Задержка между телепортациями
_G.FarmHeight = -3 -- По умолчанию под картой

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

-- Проверка: начался ли раунд
local function isRoundActive()
    if not isInGame() then return false end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local role = getMM2Role(player)
            if role ~= "Innocent" then
                return true
            end
        end
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

-- ========================================================
-- ESP СИСТЕМА (ОРУЖИЕ) - ИСПРАВЛЕННАЯ
-- ========================================================
local activeGunHighlights = {}

local function isGunObject(obj)
    local name = obj.Name:lower()
    
    -- Более точные проверки для оружия
    if name == "gun" or name == "pistol" or name == "пистолет" then
        return true
    end
    
    -- Проверяем, является ли объект Tool с оружейным именем
    if obj:IsA("Tool") and (name:find("gun") or name:find("pistol") or name:find("пистолет")) then
        return true
    end
    
    return false
end

local function findGuns()
    local guns = {}
    
    -- Ищем только настоящие пистолеты (Tools)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            if isGunObject(obj) then
                -- Проверяем, что оружие не у игрока в руках
                local parent = obj.Parent
                local isInCharacter = false
                
                while parent do
                    if parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
                        isInCharacter = true
                        break
                    end
                    parent = parent.Parent
                end
                
                if not isInCharacter then
                    table.insert(guns, obj)
                end
            end
        end
    end
    
    -- Если не нашли Tools, ищем части с именем пистолета
    if #guns == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                local name = obj.Name:lower()
                -- Ищем только конкретные части пистолета, не карту
                if name == "gun" or name == "pistol" or name == "пистолет" or 
                   name == "gunhandle" or name == "gunbarrel" or name == "gunbody" then
                    -- Проверяем, что это не часть персонажа
                    local parent = obj.Parent
                    local isInCharacter = false
                    
                    while parent do
                        if parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
                            isInCharacter = true
                            break
                        end
                        parent = parent.Parent
                    end
                    
                    if not isInCharacter then
                        table.insert(guns, obj)
                    end
                end
            end
        end
    end
    
    return guns
end

local function updateGunESP()
    -- Удаляем старые подсветки
    for gun, highlight in pairs(activeGunHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    activeGunHighlights = {}
    
    if not _G.GunESP then return end
    
    -- Находим и подсвечиваем оружие
    local guns = findGuns()
    for _, gun in ipairs(guns) do
        local highlight = Instance.new("Highlight")
        highlight.Name = "MM2_GunESP"
        highlight.FillColor = _G.GunColor
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.2
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        if gun:IsA("Model") then
            highlight.Parent = gun
        else
            highlight.Parent = gun.Parent
        end
        
        activeGunHighlights[gun] = highlight
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
        
        updateGunESP()
    end
end)

Players.PlayerRemoving:Connect(removeHighlight)

-- ========================================================
-- СИСТЕМА ФЛАЯ (МОБИЛЬНАЯ ВЕРСИЯ - НАПРАВЛЕНИЕ ОТ КАМЕРЫ)
-- ========================================================
local flyBodyVelocity = nil
local flyBodyGyro = nil

local function stopFly()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
        end
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
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
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
    
    if not hrp or not hum or hum.Health <= 0 then
        stopFly()
        return
    end
    
    if not flyBodyVelocity or not flyBodyGyro then
        startFly()
    end
    
    if flyBodyVelocity and flyBodyGyro then
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        -- Получаем полное направление камеры (включая вертикаль)
        local cameraForward = camera.CFrame.LookVector
        local cameraRight = camera.CFrame.RightVector
        
        -- Получаем ввод с джойстика
        local joyDirection = hum.MoveDirection
        
        -- Вычисляем направление движения
        local moveDirection = Vector3.zero
        
        -- Вперед (джойстик вверх) - летим куда смотрит камера (включая вверх/вниз)
        if joyDirection.Z < 0 then
            moveDirection += cameraForward
        -- Назад (джойстик вниз) - летим назад от камеры
        elseif joyDirection.Z > 0 then
            moveDirection -= cameraForward
        end
        
        -- Вправо/влево (стрейф)
        if joyDirection.X > 0 then
            moveDirection += cameraRight
        elseif joyDirection.X < 0 then
            moveDirection -= cameraRight
        end
        
        -- Если есть движение - нормализуем
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            flyBodyVelocity.Velocity = moveDirection * _G.FlySpeed
        else
            -- Полная фиксация в воздухе
            flyBodyVelocity.Velocity = Vector3.zero
        end
        
        -- Персонаж смотрит туда же, куда и камера
        flyBodyGyro.CFrame = camera.CFrame
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if _G.FlyEnabled then
        task.wait(0.5)
        startFly()
    end
end)

-- ========================================================
-- СИСТЕМА ФАНТОМНОГО ПРИЗРАКА (ИСПРАВЛЕННАЯ)
-- ========================================================
local phantomLoop = nil
local selfHighlight = nil

local function findSheriffOrMurderer()
    local targets = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local role = getMM2Role(player)
            
            if hum and hum.Health > 0 and (role == "Sheriff" or role == "Murderer") then
                table.insert(targets, player)
            end
        end
    end
    
    if #targets == 0 then return nil end
    
    -- Выбираем случайного шерифа или мардера
    local randomIndex = math.random(1, #targets)
    return targets[randomIndex]
end

local function teleportToSheriffOrMurderer()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local targetPlayer = findSheriffOrMurderer()
    if not targetPlayer or not targetPlayer.Character then return false end
    
    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return false end
    
    -- Телепортируемся рядом с шерифом/мардером
    local offset = Vector3.new(math.random(-3, 3), 2, math.random(-3, 3))
    char.HumanoidRootPart.CFrame = CFrame.new(targetHrp.Position + offset)
    
    return true
end

local function activatePhantomMode()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Телепортируемся к шерифу или мардеру
    local teleported = teleportToSheriffOrMurderer()
    if not teleported then
        notify("❌ ОШИБКА", "Не удалось найти шерифа или мардера!", 3)
        _G.PhantomMode = false
        return
    end
    
    notify("👻 ФАНТОМНЫЙ РЕЖИМ", "Вы телепортированы! Вас видно, но убить нельзя!", 5)
    
    -- Запускаем цикл фантомного режима
    phantomLoop = task.spawn(function()
        while _G.PhantomMode and char and char.Parent do
            task.wait(0.1)
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                -- Делаем персонажа неуязвимым
                hum.MaxHealth = 999999
                hum.Health = 999999
                
                -- Отключаем коллизии (проходим сквозь стены)
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.CanTouch = false
                        part.CanQuery = false
                    end
                end
                
                -- Создаем розовую подсветку для себя
                if not selfHighlight or not selfHighlight.Parent then
                    if selfHighlight then
                        selfHighlight:Destroy()
                    end
                    
                    selfHighlight = Instance.new("Highlight")
                    selfHighlight.Name = "Phantom_Self_Highlight"
                    selfHighlight.FillColor = _G.PhantomColor
                    selfHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    selfHighlight.FillTransparency = 0.3
                    selfHighlight.OutlineTransparency = 0
                    selfHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    selfHighlight.Parent = char
                else
                    selfHighlight.FillColor = _G.PhantomColor
                    selfHighlight.FillTransparency = 0.3
                end
            end
        end
    end)
end

local function deactivatePhantomMode()
    if phantomLoop then
        task.cancel(phantomLoop)
        phantomLoop = nil
    end
    
    -- Убираем подсветку
    if selfHighlight then
        selfHighlight:Destroy()
        selfHighlight = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            -- Возвращаем обычное здоровье
            hum.MaxHealth = 100
            hum.Health = 100
        end
        
        -- Возвращаем коллизии
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.CanTouch = true
                part.CanQuery = true
            end
        end
    end
    
    notify("👁️ ФАНТОМНЫЙ РЕЖИМ ВЫКЛЮЧЕН", "Вы снова обычный игрок!", 3)
end

-- ========================================================
-- СИСТЕМА АВТО ФАРМА (ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ)
-- ========================================================
local antiFallVelocity = nil

local function createAntiFall()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    if antiFallVelocity then
        antiFallVelocity:Destroy()
    end
    
    antiFallVelocity = Instance.new("BodyVelocity")
    antiFallVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    antiFallVelocity.Velocity = Vector3.new(0, 0, 0)
    antiFallVelocity.Parent = hrp
end

local function removeAntiFall()
    if antiFallVelocity then
        antiFallVelocity:Destroy()
        antiFallVelocity = nil
    end
end

-- Функция для увеличения хитбокса монеты
local function expandCoinHitbox(coin)
    pcall(function()
        if coin:IsA("BasePart") then
            -- Сохраняем оригинальный размер
            if not coin:GetAttribute("OriginalSize") then
                coin:SetAttribute("OriginalSize", coin.Size)
            end
            
            -- Увеличиваем размер в 3 раза (не слишком много, чтобы не ломать игру)
            local originalSize = coin:GetAttribute("OriginalSize")
            local newSize = Vector3.new(
                originalSize.X * 3,
                originalSize.Y * 3,
                originalSize.Z * 3
            )
            coin.Size = newSize
            coin.CanCollide = false
            coin.Transparency = 0.3 -- Полупрозрачные
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
                removeAntiFall()
                continue
            end
            
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                -- Отключаем коллизии для прохождения сквозь стены
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                
                local coin = getNearestCoin()
                if coin then
                    -- Увеличиваем хитбокс монеты
                    expandCoinHitbox(coin)
                    
                    -- ВАЖНО: Телепортируемся НА ВЫСОТУ МОНЕТЫ + НАСТРОЙКА ВЫСОТЫ
                    local targetY = coin.Position.Y + _G.FarmHeight
                    
                    if _G.FarmMode == "UnderMap" then
                        -- Для режима под картой
                        -- Если FarmHeight положительный - летим над картой
                        -- Если отрицательный - под карту
                        targetY = coin.Position.Y + _G.FarmHeight
                        
                        -- Телепортируемся на нужную высоту
                        root.CFrame = CFrame.new(coin.Position.X, targetY, coin.Position.Z)
                        
                        -- Создаем анти-падение чтобы не упасть
                        createAntiFall()
                        
                        -- Дополнительно проверяем, не застряли ли мы
                        task.wait(0.1)
                        
                        -- Если персонаж не может двигаться, пробуем другую высоту
                        if root.Position.Y < -50 or root.Position.Y > 1000 then
                            -- Что-то пошло не так, пробуем стандартную высоту
                            root.CFrame = CFrame.new(coin.Position.X, coin.Position.Y - 3, coin.Position.Z)
                            createAntiFall()
                        end
                    else
                        -- Для режима "На карте"
                        removeAntiFall()
                        targetY = coin.Position.Y + _G.FarmHeight
                        root.CFrame = CFrame.new(coin.Position.X, targetY, coin.Position.Z)
                    end
                    
                    -- Обнуляем скорость
                    root.Velocity = Vector3.new(0, 0, 0)
                    
                    -- Принудительно пытаемся собрать монету
                    pcall(function()
                        -- Создаем невидимую часть для сбора
                        local collector = Instance.new("Part")
                        collector.Name = "CoinCollector"
                        collector.Size = Vector3.new(3, 3, 3)
                        collector.Transparency = 1
                        collector.CanCollide = false
                        collector.Anchored = true
                        collector.Position = coin.Position
                        collector.Parent = char
                        
                        -- Пытаемся телепортировать монету к нам
                        if coin:IsA("BasePart") then
                            coin.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0))
                        end
                        
                        task.wait(0.2)
                        collector:Destroy()
                    end)
                end
            end
        else
            if antiFallVelocity then
                removeAntiFall()
            end
        end
    end
end)

-- Убираем анти-падение при смерти
LocalPlayer.CharacterAdded:Connect(function()
    removeAntiFall()
end)

-- ========================================================
-- СИСТЕМА УБИЙСТВА ВСЕХ (ДЛЯ МАРДЕРА)
-- ========================================================
local function killAll()
    -- Проверяем, что мы мардер
    if getMM2Role(LocalPlayer) ~= "Murderer" then
        notify("❌ ОШИБКА", "Вы не Мардер!", 3)
        return
    end
    
    -- Проверяем, что мы в игре
    if not isInGame() then
        notify("❌ ОШИБКА", "Вы не в игре!", 3)
        return
    end
    
    notify("💀 УБИЙСТВО ВСЕХ", "Убиваю всех игроков через 2 секунды...", 3)
    
    -- Ждем 2 секунды
    task.wait(2)
    
    local killedCount = 0
    
    -- Убиваем всех игроков
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                -- Телепортируемся к игроку (для реалистичности)
                local myChar = LocalPlayer.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
                
                if myHrp and targetHrp then
                    myHrp.CFrame = CFrame.new(targetHrp.Position + Vector3.new(0, 2, 0))
                end
                
                -- Убиваем игрока
                hum.Health = 0
                killedCount = killedCount + 1
                
                -- Небольшая задержка между убийствами
                task.wait(0.1)
            end
        end
    end
    
    notify("✅ ПОБЕДА!", "Убито игроков: " .. killedCount, 5)
end

-- ========================================================
-- ИНТЕРФЕЙС
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "MM2 Ultimate Hub",
    LoadingTitle = "MM2 Script",
    LoadingSubtitle = "by YourName",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- Создаем вкладки
local CombatTab = Window:CreateTab("⚔️ Сражение", 4483362458)
local VisualTab = Window:CreateTab("👁️ Визуализация", 4483362458)
local FarmTab = Window:CreateTab("🪙 Фарм", 4483362458)
local MiscTab = Window:CreateTab("🔧 Прочее", 4483362458)

-- ========================================================
-- ВКЛАДКА: СРАЖЕНИЕ
-- ========================================================

CombatTab:CreateSection("Боевые функции")

CombatTab:CreateButton({
    Name = "💀 Убить всех",
    Callback = function()
        killAll()
    end,
})

CombatTab:CreateLabel("Убивает всех игроков на карте")
CombatTab:CreateLabel("Работает только если вы Мардер")

-- ========================================================
-- ВКЛАДКА: ВИЗУАЛИЗАЦИЯ
-- ========================================================

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

VisualTab:CreateColorPicker({
    Name = "🎨 Цвет невинных игроков",
    Color = _G.InnocentColor,
    Callback = function(Value)
        _G.InnocentColor = Value
    end,
})

VisualTab:CreateSection("Оружие")

VisualTab:CreateToggle({
    Name = "🔫 Подсветка оружия",
    CurrentValue = _G.GunESP,
    Callback = function(Value)
        _G.GunESP = Value
        if Value then
            notify("🔫 ПОДСВЕТКА ОРУЖИЯ ВКЛЮЧЕНА", "Оружие подсвечивается сквозь стены", 3)
        else
            notify("🚫 ПОДСВЕТКА ОРУЖИЯ ВЫКЛЮЧЕНА", "Подсветка отключена", 3)
        end
    end,
})

VisualTab:CreateColorPicker({
    Name = "🎨 Цвет оружия",
    Color = _G.GunColor,
    Callback = function(Value)
        _G.GunColor = Value
    end,
})

VisualTab:CreateSection("Фантомный режим")

VisualTab:CreateToggle({
    Name = "👻 Фантомный призрак",
    CurrentValue = _G.PhantomMode,
    Callback = function(Value)
        _G.PhantomMode = Value
        if Value then
            -- Проверяем, идет ли раунд
            if not isRoundActive() then
                notify("❌ ОШИБКА", "Раунд еще не начался!", 3)
                _G.PhantomMode = false
                return
            end
            
            -- Проверяем, жив ли игрок
            if not isInGame() then
                notify("❌ ОШИБКА", "Вы мертвы или не в игре!", 3)
                _G.PhantomMode = false
                return
            end
            
            activatePhantomMode()
        else
            deactivatePhantomMode()
        end
    end,
})

VisualTab:CreateColorPicker({
    Name = "🎨 Цвет подсветки себя",
    Color = _G.PhantomColor,
    Callback = function(Value)
        _G.PhantomColor = Value
        if _G.PhantomMode and selfHighlight then
            selfHighlight.FillColor = Value
        end
    end,
})

VisualTab:CreateSection("Информация о ролях")
VisualTab:CreateLabel("🔴 Красный - Мардер")
VisualTab:CreateLabel("🔵 Синий - Шериф")
VisualTab:CreateLabel("🟢 Зеленый - Невинный (настраиваемый)")
VisualTab:CreateLabel("⚫ Черный - Оружие (настраиваемый)")
VisualTab:CreateLabel("🩷 Розовый - Вы (в фантомном режиме)")

-- ========================================================
-- ВКЛАДКА: ФАРМ
-- ========================================================

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
            removeAntiFall()
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
            removeAntiFall()
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
    CurrentValue = -3,
    Callback = function(Value)
        _G.FarmHeight = Value
        notify("📏 ВЫСОТА", "Высота: " .. Value .. " от монеты", 2)
    end,
})

-- ========================================================
-- ВКЛАДКА: ПРОЧЕЕ
-- ========================================================

MiscTab:CreateSection("Флай")

MiscTab:CreateToggle({
    Name = "✈️ Флай",
    CurrentValue = _G.FlyEnabled,
    Callback = function(Value)
        _G.FlyEnabled = Value
        if Value then
            startFly()
            notify("✈️ ФЛАЙ ВКЛЮЧЕН", "Летите куда смотрит камера!", 3)
        else
            stopFly()
            notify("🚫 ФЛАЙ ВЫКЛЮЧЕН", "Вы снова ходите!", 3)
        end
    end,
})

MiscTab:CreateSlider({
    Name = "Скорость полета",
    Range = {20, 200},
    Increment = 10,
    CurrentValue = _G.FlySpeed,
    Callback = function(Value)
        _G.FlySpeed = Value
    end,
})

notify("✅ СКРИПТ ЗАГРУЖЕН!", "Базовая версия активирована!", 5)
