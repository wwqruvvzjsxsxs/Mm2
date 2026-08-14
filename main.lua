-- ========================================================
-- СИСТЕМА ЛОКАЛИЗАЦИИ И ПУНКТ 1: ПОДСВЕТКА ИГРОКОВ (ESP)
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Настройки языка ("RU" или "EN", по умолчанию "RU")
_G.Language = "RU"

-- Словари перевода интерфейса
local Translations = {
    RU = {
        ESPButton = "Подсветка игроков",
        InnocentColorPicker = "Цвет мирных игроков",
        TabMain = "Главная"
    },
    EN = {
        ESPButton = "Player ESP",
        InnocentColorPicker = "Innocent ESP Color",
        TabMain = "Main"
    }
}

-- Вспомогательная функция получения текста на текущем языке
local function getText(key)
    return Translations[_G.Language] and Translations[_G.Language][key] or Translations["RU"][key]
end

-- Настройки функции ESP
_G.RolesESP = true
_G.InnocentColor = Color3.fromRGB(0, 255, 0) -- Зеленый по умолчанию для мирных
_G.ESPTransparency = 0.5

-- СТРОГИЕ фиксированные цвета
local MurdererColor = Color3.fromRGB(255, 0, 0) -- СТРОГО красный
local SheriffColor = Color3.fromRGB(0, 0, 255)  -- СТРОГО синий

local activeHighlights = {}

-- Функция определения роли игрока в MM2
local function getMM2Role(player)
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if (character and character:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife")) then
        return "Murderer"
    elseif (character and character:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

-- Обновление подсветки конкретного игрока
local function updatePlayerESP(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        if activeHighlights[player.Name] then
            activeHighlights[player.Name]:Destroy()
            activeHighlights[player.Name] = nil
        end
        return
    end

    local role = getMM2Role(player)
    local fillColor = _G.InnocentColor

    if role == "Murderer" then
        fillColor = MurdererColor
    elseif role == "Sheriff" then
        fillColor = SheriffColor
    end

    if not activeHighlights[player.Name] or activeHighlights[player.Name].Parent ~= character then
        if activeHighlights[player.Name] then 
            activeHighlights[player.Name]:Destroy() 
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_MM2_Player"
        highlight.FillColor = fillColor
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = _G.ESPTransparency
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
        
        activeHighlights[player.Name] = highlight
    else
        activeHighlights[player.Name].FillColor = fillColor
        activeHighlights[player.Name].FillTransparency = _G.ESPTransparency
    end
end

-- Постоянный цикл проверки ролей
RunService.RenderStepped:Connect(function()
    if _G.RolesESP then
        for _, player in ipairs(Players:GetPlayers()) do
            updatePlayerESP(player)
        end
    else
        for name, hl in pairs(activeHighlights) do
            hl:Destroy()
        end
        activeHighlights = {}
    end
end)

-- Очистка при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    if activeHighlights[player.Name] then
        activeHighlights[player.Name]:Destroy()
        activeHighlights[player.Name] = nil
    end
end)
-- ========================================================
-- ПУНКТ 2: ПОДСВЕТКА ОРУЖИЯ (ESP WEAPON / ПОДСВЕТКА ОРУЖИЯ)
-- ========================================================

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Расширение словаря переводов для второго пункта
Translations.RU.GunESPButton = "подсветка оружия"
Translations.EN.GunESPButton = "ESP WEAPON"

-- Настройки функции подсветки оружия
_G.GunESP = true

local SheriffColor = Color3.fromRGB(0, 0, 255) -- СТРОГО синий цвет
local activeGunHighlight = nil

-- Функция отслеживания и подсвечивания выпавшего или находящегося на карте пистолета
local function updateGunESP()
    if not _G.GunESP then
        if activeGunHighlight then
            activeGunHighlight:Destroy()
            activeGunHighlight = nil
        end
        return
    end

    -- Поиск объекта выпавшего пистолета в Workspace карты MM2
    local gunDrop = Workspace:FindFirstChild("GunDrop", true)

    if gunDrop and gunDrop:IsA("BasePart") then
        if not activeGunHighlight or activeGunHighlight.Parent ~= gunDrop then
            if activeGunHighlight then 
                activeGunHighlight:Destroy() 
            end

            local highlight = Instance.new("Highlight")
            highlight.Name = "Gun_ESP_Highlight"
            highlight.FillColor = SheriffColor
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0 -- Яркая видимость формы оружия
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = gunDrop

            activeGunHighlight = highlight
        end
    else
        -- Если пистолет кто-то поднял обратно в инвентарь или он отсутствует на карте
        if activeGunHighlight then
            activeGunHighlight:Destroy()
            activeGunHighlight = nil
        end
    end
end

-- Постоянное отслеживание статуса пистолета каждый кадр
RunService.RenderStepped:Connect(function()
    updateGunESP()
end)
-- ========================================================
-- ПУНКТ 3: АВТО НАВОДКА (AUTO-GUIDANCE / АВТО НАВОДКА)
-- ========================================================

-- Обновление словаря переводов
Translations.RU.AutoGuidanceButton = "авто наводка"
Translations.EN.AutoGuidanceButton = "auto-guidance"

-- Настройки функции авто-наводки
_G.AimbotEnabled = false
_G.AimbotSmoothness = 0.1 -- Плавность (чем меньше, тем быстрее)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Поиск цели в зависимости от роли
local function getTarget()
    local myRole = getMM2Role(LocalPlayer)
    local bestTarget = nil
    local minDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetRole = getMM2Role(player)
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local shouldTarget = false
                
                -- Логика: Шериф ищет Мардера, Мардер ищет ближайшую цель
                if myRole == "Sheriff" then
                    if targetRole == "Murderer" then shouldTarget = true end
                elseif myRole == "Murderer" then
                    shouldTarget = true
                end

                if shouldTarget then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        bestTarget = player.Character.HumanoidRootPart
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Основной цикл наводки
RunService.RenderStepped:Connect(function()
    if _G.AimbotEnabled then
        local target = getTarget()
        if target then
            -- Плавное наведение камеры на цель
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.AimbotSmoothness)
        end
    end
end)
-- ========================================================
-- ПУНКТ 4: АВТОФАРМ (AVTO-FARM / АВТО-ФАРМ)
-- ========================================================

-- Обновление словаря переводов
Translations.RU.AutoFarmButton = "авто-фарм"
Translations.EN.AutoFarmButton = "Avto-farm"
Translations.RU.SpeedLabel = "Скорость персонажа"
Translations.EN.SpeedLabel = "Player Speed"

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Настройки автофарма
_G.AutoFarm = false
_G.FarmSpeed = 20 -- Начальное значение скорости

-- Функция поиска ближайшей монетки
local function getNearestCoin()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local root = character.HumanoidRootPart
    
    local nearestCoin = nil
    local shortestDistance = math.huge

    -- Поиск монеток в стандартных контейнерах MM2
    for _, container in ipairs(Workspace:GetChildren()) do
        if container.Name == "CoinContainer" then
            for _, coin in ipairs(container:GetChildren()) do
                if coin:IsA("BasePart") then
                    local dist = (root.Position - coin.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        nearestCoin = coin
                    end
                end
            end
        end
    end
    return nearestCoin
end

-- Основной поток автофарма
task.spawn(function()
    while true do
        task.wait(0.1) -- Задержка цикла
        if _G.AutoFarm then
            local coin = getNearestCoin()
            if coin and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local distance = (root.Position - coin.Position).Magnitude
                
                -- Вычисление времени на основе настроенной скорости
                local moveTime = distance / math.max(_G.FarmSpeed, 1)
                
                -- Плавное перемещение (Tween) к позиции монетки
                local tweenInfo = TweenInfo.new(moveTime, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(root, tweenInfo, {CFrame = coin.CFrame})
                
                tween:Play()
                tween.Completed:Wait() -- Ожидание завершения движения
            end
        end
    end
end)
-- ========================================================
-- ПУНКТ 5: НЕВИДИМОСТЬ (INVISIBILITY / НЕВИДИМОСТЬ)
-- ========================================================

-- Обновление словаря переводов
Translations.RU.InvisButton = "невидимость"
Translations.EN.InvisButton = "Invisibility"

-- Настройки невидимости
_G.Invisibility = false

local PinkColor = Color3.fromRGB(255, 105, 180) -- Ярко-розовый цвет для локального тела

-- Функция включения/выключения локальной невидимости
local function setInvisibility(state)
    _G.Invisibility = state
    local character = LocalPlayer.Character
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")

    if state then
        -- 1. Подсветка ярко-розовым цветом для самого себя
        local highlight = character:FindFirstChild("Self_Invis_Highlight") or Instance.new("Highlight")
        highlight.Name = "Self_Invis_Highlight"
        highlight.FillColor = PinkColor
        highlight.OutlineColor = Color3.fromRGB(255, 192, 203)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character

        -- 2. Локальное скрытие деталей персонажа (подсветка остается видимой)
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                if part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = 0.7
                end
            end
        end

        -- 3. Отвязка RootPart (заморозка отображения хитбокса на сервере)
        if root then
            local clone = root:Clone()
            clone.Parent = character
            root.Transparency = 1
        end
    else
        -- Сброс невидимости и удаление розовoй подсветки
        local highlight = character:FindFirstChild("Self_Invis_Highlight")
        if highlight then
            highlight:Destroy()
        end

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = 0
            end
        end
    end
end

-- ========================================================
-- ПУНКТ 6: СБОРКА ИНТЕРФЕЙСА RAYFIELD С ПЕРЕКЛЮЧЕНИЕМ ЯЗЫКА
-- ========================================================

-- Подключение графической библиотеки Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Создание главного окна
local Window = Rayfield:CreateWindow({
   Name = "MM2 Ultimate Hub",
   LoadingTitle = "MM2 Script",
   LoadingSubtitle = "by Yuri",
   ConfigurationSaving = { Enabled = false }
})

-- Создание вкладок
local MainTab = Window:CreateTab("Главная / Main", 4483362458)

-- Переключатель языка (RU / EN)
MainTab:CreateDropdown({
   Name = "Language / Язык",
   Options = {"RU", "EN"},
   CurrentOption = {"RU"},
   MultipleOptions = false,
   Callback = function(Option)
       _G.Language = Option[1]
       
       -- Уведомление о смене языка
       Rayfield:Notify({
          Title = _G.Language == "RU" and "Язык изменен" or "Language Changed",
          Content = _G.Language == "RU" and "Текущий язык: Русский" or "Current language: English",
          Duration = 3,
          Image = 4483362458,
       })
   end,
})

-- [1] Переключатель Подсветки Игроков
MainTab:CreateToggle({
   Name = "ESP / подсветка",
   CurrentValue = true,
   Callback = function(Value)
       _G.RolesESP = Value
   end,
})

-- Выбор цвета для Мирных игроков
MainTab:CreateColorPicker({
    Name = "Innocent ESP Color",
    Color = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        _G.InnocentColor = Value
    end
})

-- [2] Переключатель Подсветки Оружия
MainTab:CreateToggle({
   Name = "ESP WEAPON / подсветка оружия",
   CurrentValue = true,
   Callback = function(Value)
       _G.GunESP = Value
   end,
})

-- [3] Переключатель Авто-наводки
MainTab:CreateToggle({
   Name = "auto-guidance / авто наводка",
   CurrentValue = false,
   Callback = function(Value)
       _G.AimbotEnabled = Value
   end,
})

-- [4] Переключатель и Слайдер Автофарма
MainTab:CreateToggle({
   Name = "Avto-farm / авто-фарм",
   CurrentValue = false,
   Callback = function(Value)
       _G.AutoFarm = Value
   end,
})

MainTab:CreateSlider({
   Name = "значение скорости персонажа / Player Speed",
   Range = {10, 50},
   Increment = 1,
   CurrentValue = 20,
   Callback = function(Value)
       _G.FarmSpeed = Value
   end,
})

-- [5] Переключатель Невидимости
MainTab:CreateToggle({
   Name = "Invisibility / невидимость",
   CurrentValue = false,
   Callback = function(Value)
       setInvisibility(Value)
   end,
})
