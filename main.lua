-- ========================================================
-- ПУНКТ 1: ПОДСВЕТКА ИГРОКОВ (ESP)
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

_G.Language = "RU"

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

_G.RolesESP = true
_G.InnocentColor = Color3.fromRGB(0, 255, 0)
_G.ESPTransparency = 0.4

local MurdererColor = Color3.fromRGB(255, 0, 0)
local SheriffColor = Color3.fromRGB(0, 0, 255)

local activeHighlights = {}

-- Очистка подсветки игрока
local function removeHighlight(player)
    if activeHighlights[player] then
        if activeHighlights[player].Parent then
            activeHighlights[player]:Destroy()
        end
        activeHighlights[player] = nil
    end
end

-- Функция определения роли
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

-- Обновление конкретного игрока
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

    -- Создаем или обновляем Highlight
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

-- Основной цикл обновления подсветки
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
-- ПУНКТ 2: ПОДСВЕТКА ОРУЖИЯ (ESP WEAPON) И УПРАВЛЕНИЕ ХИТБОКСАМИ
-- ========================================================

Translations.RU.GunESPButton = "подсветка оружия"
Translations.EN.GunESPButton = "ESP WEAPON"

_G.GunESP = true
_G.GunHitboxEnabled = false
_G.GunHitboxSize = 10

_G.AntiKnifeHitbox = false  -- Уменьшение хитбокса ножа Мардера
_G.AntiBulletHitbox = false -- Уменьшение хитбокса пуль/оружия Шерифа

local activeGunHighlight = nil

local function clearGunESP()
    if activeGunHighlight then
        activeGunHighlight:Destroy()
        activeGunHighlight = nil
    end
end

-- Обновление подсветки выпавшего пистолета
local function updateGunESP()
    if not _G.GunESP then
        clearGunESP()
        return
    end

    -- В MM2 выпавший пистолет называется GunDrop
    local gunDrop = Workspace:FindFirstChild("GunDrop")

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
end

task.spawn(function()
    while true do
        task.wait(0.3)
        updateGunESP()
    end
end)

-- 1. Увеличение зоны подбора упавшего пистолета (GunDrop)
task.spawn(function()
    while true do
        task.wait(0.4)
        local gunDrop = Workspace:FindFirstChild("GunDrop")
        if gunDrop then
            local mainPart = gunDrop:IsA("BasePart") and gunDrop or gunDrop:FindFirstChildOfClass("BasePart")
            if mainPart then
                if _G.GunHitboxEnabled then
                    mainPart.Size = Vector3.new(_G.GunHitboxSize, _G.GunHitboxSize, _G.GunHitboxSize)
                    mainPart.CanCollide = false
                    mainPart.Transparency = 0.6
                else
                    mainPart.Size = Vector3.new(2, 2, 2)
                    mainPart.Transparency = 0
                end
            end
        end
    end
end)

-- 2. Уменьшение хитбоксов Ножа (Мардера) и Оружия/Пули (Шерифа)
task.spawn(function()
    while true do
        task.wait(0.3)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local role = getMM2Role(player)
                
                -- Если включено уменьшение хитбокса ножа у Мардера
                if _G.AntiKnifeHitbox and role == "Murderer" then
                    local knife = char:FindFirstChild("Knife") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife"))
                    if knife and knife:FindFirstChild("Handle") then
                        knife.Handle.Size = Vector3.new(0.01, 0.01, 0.01)
                    end
                end

                -- Если включено уменьшение хитбокса выстрела у Шерифа
                if _G.AntiBulletHitbox and role == "Sheriff" then
                    local gun = char:FindFirstChild("Gun") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun"))
                    if gun and gun:FindFirstChild("Handle") then
                        gun.Handle.Size = Vector3.new(0.01, 0.01, 0.01)
                    end
                end
            end
        end
    end
end)
-- ========================================================
-- ПУНКТ 3: АВТО НАВОДКА И ВЫСТРЕЛ (AUTO-GUIDANCE & SHOOT)
-- ========================================================

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Translations.RU.AutoGuidanceButton = "авто наводка"
Translations.EN.AutoGuidanceButton = "auto-guidance"

_G.AimbotEnabled = false
_G.AimbotSmoothness = 0.3

-- Поиск цели в зависимости от вашей роли
local function getAimbotTarget()
    local myRole = getMM2Role(LocalPlayer)
    local bestTarget = nil
    local minDistance = math.huge

    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local targetRole = getMM2Role(player)
                local shouldTarget = false
                
                -- Шериф целится в Мардера, Мардер — во всех остальных
                if myRole == "Sheriff" and targetRole == "Murderer" then
                    shouldTarget = true
                elseif myRole == "Murderer" and targetRole ~= "Murderer" then
                    shouldTarget = true
                end

                if shouldTarget then
                    local dist = (myPos - hrp.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        bestTarget = hrp
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Плавный поворот камеры и автоматический выстрел
RunService.RenderStepped:Connect(function()
    if _G.AimbotEnabled and LocalPlayer.Character then
        local myChar = LocalPlayer.Character
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        local hrp = myChar:FindFirstChild("HumanoidRootPart")

        if hrp and hum and hum.Health > 0 then
            local target = getAimbotTarget()
            if target then
                -- Поворот камеры на цель
                local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.AimbotSmoothness)

                -- Автоматический выстрел для Шерифа
                if getMM2Role(LocalPlayer) == "Sheriff" then
                    local gun = myChar:FindFirstChild("Gun") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Gun"))
                    if gun then
                        if gun.Parent ~= myChar then
                            hum:EquipTool(gun)
                        end
                        gun:Activate()
                    end
                end
            end
        end
    end
end)
-- ========================================================
-- ПУНКТ 4: БЫСТРЫЙ ФАРМ ПОД КАРТОЙ С МАГНИТОМ МОНЕТ (UNDERGROUND COIN MAGNET)
-- ========================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

Translations.RU.AutoFarmButton = "авто-фарм"
Translations.EN.AutoFarmButton = "Avto-farm"
Translations.RU.SpeedLabel = "Скорость персонажа"
Translations.EN.SpeedLabel = "Player Speed"

_G.AutoFarm = false
_G.FarmSpeed = 20
_G.CoinHitboxSize = 5 -- Размер хитбокса монеты для моментального сбора

-- 1. Noclip (Отключение столкновений)
RunService.Stepped:Connect(function()
    if _G.AutoFarm and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 2. Установка скорости
task.spawn(function()
    while true do
        task.wait(0.2)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and _G.FarmSpeed and _G.FarmSpeed >= 16 then
                hum.WalkSpeed = _G.FarmSpeed
            end
        end
    end
end)

-- 3. Поиск ближайшей монеты
local function getNearestCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart

    local nearestCoin = nil
    local minDistance = math.huge

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "CoinContainer" or obj:FindFirstChild("CoinContainer") then
            local container = obj.Name == "CoinContainer" and obj or obj:FindFirstChild("CoinContainer")
            for _, coin in ipairs(container:GetChildren()) do
                if coin:IsA("BasePart") and coin.Transparency < 1 then
                    local dist = (root.Position - coin.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        nearestCoin = coin
                    end
                end
            end
        end
    end
    return nearestCoin
end

-- 4. Телепорт под картой + Магнит хитбокса монет
task.spawn(function()
    while true do
        task.wait(0.01) -- Максимально быстрый цикл сбора
        if _G.AutoFarm then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                local coin = getNearestCoin()
                if coin then
                    -- Увеличиваем хитбокс монеты, чтобы зацепить её издалека
                    coin.Size = Vector3.new(_G.CoinHitboxSize, _G.CoinHitboxSize, _G.CoinHitboxSize)
                    coin.CanCollide = false

                    -- Мгновенно перемещаемся под монету (на 3 блока ниже пола)
                    root.CFrame = CFrame.new(coin.Position.X, coin.Position.Y - 3, coin.Position.Z)
                end
            end
        end
    end
end)
-- ========================================================
-- ПУНКТ 5: НАСТОЯЩАЯ НЕВИДИМОСТЬ И АВТО-ПЕРЕЗАХОД (SERVER INVISIBILITY & AUTO-REJOIN)
-- ========================================================

-- ========================================================
-- ПУНКТ 5: СЕРВЕРНАЯ НЕВИДИМОСТЬ, АВТО-ПЕРЕЗАХОД И ANTI-AFK
-- ========================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

Translations.RU.InvisButton = "невидимость"
Translations.EN.InvisButton = "Invisibility"
Translations.RU.AntiAfkButton = "Защита от AFK"
Translations.EN.AntiAfkButton = "Anti-AFK"

_G.Invisibility = false
_G.AutoRejoin = true
_G.AntiAFK = true

local PinkColor = Color3.fromRGB(255, 105, 180)

-- 1. Anti-AFK (Защита от вылета за бездействие через 20 минут)
LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

-- 2. Настоящая серверная невидимость (смещение визуальной модели под карту)
local function setInvisibility(state)
    _G.Invisibility = state
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local highlight = char:FindFirstChild("Self_Invis_Highlight")

    if state then
        -- Создаем розовый силуэт для собственного удобства
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "Self_Invis_Highlight"
            highlight.FillColor = PinkColor
            highlight.OutlineColor = Color3.fromRGB(255, 192, 203)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = char
        end

        -- Локальная прозрачность для себя
        for _, part in ipairs(char:GetDescendants()) do
            if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = 0.7
            end
        end

        -- Сдвигаем части тела под карту на 500 блоков для остальных
        task.spawn(function()
            while _G.Invisibility and char and char.Parent do
                task.wait()
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CFrame = hrp.CFrame * CFrame.new(0, -500, 0)
                    end
                end
            end
        end)
    else
        -- Сброс невидимости
        if highlight then
            highlight:Destroy()
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.LocalTransparencyModifier = 0
            end
        end
    end
end

-- Автоматический сброс невидимости при перерождении
LocalPlayer.CharacterAdded:Connect(function()
    _G.Invisibility = false
end)

-- 3. Авто-перезаход на сервер при кике или вылете
GuiService.ErrorMessageChanged:Connect(function()
    if _G.AutoRejoin then
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- ========================================================
-- ПУНКТ 6: УВЕЛИЧЕНИЕ ХИТБОКСА МАРДЕРА (HITBOX EXPANDER)
-- ========================================================

_G.HitboxEnabled = false
_G.HitboxSize = 10
_G.HitboxTransparency = 0.7

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
                            hrp.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                            hrp.Transparency = _G.HitboxTransparency
                            hrp.Color = Color3.fromRGB(255, 0, 0)
                            hrp.Material = Enum.Material.ForceField
                            hrp.CanCollide = false
                        end
                    end
                end
            end
        else
            -- Сброс размеров хитбокса до стандартных значений
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 1
                    end
                end
            end
        end
    end
end)
-- ========================================================
-- ПУНКТ 7: НОВЫЕ ФУНКЦИИ (ХИТБОКС ПИСТОЛЕТА И МИНИМИЗАЦИЯ УРОНА)
-- ========================================================

_G.GunHitboxEnabled = false
_G.GunHitboxSize = 10

_G.AntiKnifeHitbox = false  -- Уменьшение хитбокса ножа Мардера
_G.AntiBulletHitbox = false -- Уменьшение хитбокса пуль/оружия Шерифа

-- 1. Увеличение зоны подбора упавшего пистолета (GunDrop)
task.spawn(function()
    while true do
        task.wait(0.4)
        local gunDrop = Workspace:FindFirstChild("GunDrop")
        if gunDrop then
            local mainPart = gunDrop:IsA("BasePart") and gunDrop or gunDrop:FindFirstChildOfClass("BasePart")
            if mainPart then
                if _G.GunHitboxEnabled then
                    mainPart.Size = Vector3.new(_G.GunHitboxSize, _G.GunHitboxSize, _G.GunHitboxSize)
                    mainPart.CanCollide = false
                    mainPart.Transparency = 0.6
                else
                    mainPart.Size = Vector3.new(2, 2, 2)
                    mainPart.Transparency = 0
                end
            end
        end
    end
end)

-- 2. Уменьшение хитбоксов Ножа (Мардера) и Оружия/Пули (Шерифа)
task.spawn(function()
    while true do
        task.wait(0.3)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local role = getMM2Role(player)
                
                -- Уменьшение хитбокса ножа у Мардера
                if _G.AntiKnifeHitbox and role == "Murderer" then
                    local knife = char:FindFirstChild("Knife") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife"))
                    if knife and knife:FindFirstChild("Handle") then
                        knife.Handle.Size = Vector3.new(0.01, 0.01, 0.01)
                    end
                end

                -- Уменьшение хитбокса выстрела/оружия у Шерифа
                if _G.AntiBulletHitbox and role == "Sheriff" then
                    local gun = char:FindFirstChild("Gun") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun"))
                    if gun and gun:FindFirstChild("Handle") then
                        gun.Handle.Size = Vector3.new(0.01, 0.01, 0.01)
                    end
                end
            end
        end
    end
end)

-- ========================================================
-- ПУНКТ 8: ОПТИМИЗАЦИЯ ГРАФИКИ И УВЕЛИЧЕНИЕ FPS (FPS BOOSTER)
-- ========================================================

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

_G.FPSBoostEnabled = false

local function applyFPSBoost()
    -- 1. Отключение теней и тумана
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("Atmosphere") then
            v.Enabled = false
        end
    end

    -- 2. Очистка текстур и материалов объектов на карте
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if _G.FPSBoostEnabled then
            if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
                obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Texture = ""
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
    end
end

-- Отслеживание включения функции
task.spawn(function()
    while true do
        task.wait(1)
        if _G.FPSBoostEnabled then
            applyFPSBoost()
        end
    end
end)

-- ========================================================
-- МОДУЛЬ: NAME SPOOFER (ФЕЙКОВЫЙ НИК)
-- ========================================================

_G.FakeName = "" -- Переменная для хранения ника

local function applyFakeName()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        if _G.FakeName ~= "" then
            char.Humanoid.DisplayName = _G.FakeName
        end
    end
end

-- Авто-применение при каждом возрождении
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- Ждем загрузки персонажа
    applyFakeName()
end)

-- ========================================================
-- ПУНКТ 9: СБОРКА ИНТЕРФЕЙСА RAYFIELD
-- ========================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MM2 Ultimate Hub",
   LoadingTitle = "MM2 Script",
   LoadingSubtitle = "by Yuri",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("Главная / Main", 4483362458)

-- Выбор языка
MainTab:CreateDropdown({
   Name = "Language / Язык",
   Options = {"RU", "EN"},
   CurrentOption = {"RU"},
   MultipleOptions = false,
   Callback = function(Option)
       _G.Language = Option[1]
       
       Rayfield:Notify({
          Title = _G.Language == "RU" and "Язык изменен" or "Language Changed",
          Content = _G.Language == "RU" and "Текущий язык: Русский" or "Current language: English",
          Duration = 3,
          Image = 4483362458,
       })
   end,
})

-- [1] ESP Игроков
MainTab:CreateToggle({
   Name = "ESP / Подсветка игроков",
   CurrentValue = _G.RolesESP,
   Callback = function(Value)
       _G.RolesESP = Value
   end,
})

MainTab:CreateColorPicker({
    Name = "Цвет мирных / Innocent ESP Color",
    Color = _G.InnocentColor,
    Callback = function(Value)
        _G.InnocentColor = Value
    end
})

-- [2] ESP Оружия и Зона подбора
MainTab:CreateToggle({
   Name = "ESP WEAPON / Подсветка оружия",
   CurrentValue = _G.GunESP,
   Callback = function(Value)
       _G.GunESP = Value
   end,
})

MainTab:CreateToggle({
   Name = "Увеличить хитбокс пистолета / Gun Hitbox",
   CurrentValue = _G.GunHitboxEnabled,
   Callback = function(Value)
       _G.GunHitboxEnabled = Value
   end,
})

MainTab:CreateSlider({
   Name = "Дистанция подбора пистолета / Gun Hitbox Size",
   Range = {10, 30},
   Increment = 1,
   CurrentValue = _G.GunHitboxSize,
   Callback = function(Value)
       _G.GunHitboxSize = Value
   end,
})

-- [3] Защита (Уменьшение хитбоксов врагов)
MainTab:CreateToggle({
   Name = "Мини-хитбокс ножа Мардера / Anti-Knife Hitbox",
   CurrentValue = _G.AntiKnifeHitbox,
   Callback = function(Value)
       _G.AntiKnifeHitbox = Value
   end,
})

MainTab:CreateToggle({
   Name = "Мини-хитбокс пуль Шерифа / Anti-Bullet Hitbox",
   CurrentValue = _G.AntiBulletHitbox,
   Callback = function(Value)
       _G.AntiBulletHitbox = Value
   end,
})

-- [4] Авто-наводка
MainTab:CreateToggle({
   Name = "auto-guidance / Авто наводка",
   CurrentValue = _G.AimbotEnabled,
   Callback = function(Value)
       _G.AimbotEnabled = Value
   end,
})

-- [5] Хитбокс Мардера
MainTab:CreateToggle({
   Name = "Big Murderer Hitbox / Увеличить хитбокс Мардера",
   CurrentValue = _G.HitboxEnabled,
   Callback = function(Value)
       _G.HitboxEnabled = Value
   end,
})

MainTab:CreateSlider({
   Name = "Размер хитбокса / Hitbox Size",
   Range = {5, 30},
   Increment = 1,
   CurrentValue = _G.HitboxSize,
   Callback = function(Value)
       _G.HitboxSize = Value
   end,
})

-- [6] Автофарм и Скорость
MainTab:CreateToggle({
   Name = "Avto-farm / Авто-фарм",
   CurrentValue = _G.AutoFarm,
   Callback = function(Value)
       _G.AutoFarm = Value
   end,
})

MainTab:CreateSlider({
   Name = "Скорость персонажа / Player Speed",
   Range = {16, 60},
   Increment = 1,
   CurrentValue = _G.FarmSpeed,
   Callback = function(Value)
       _G.FarmSpeed = Value
   end,
})

-- [7] Невидимость и Авто-перезаход
MainTab:CreateToggle({
   Name = "Invisibility / Невидимость",
   CurrentValue = _G.Invisibility,
   Callback = function(Value)
       setInvisibility(Value)
   end,
})

MainTab:CreateToggle({
   Name = "Auto-Rejoin / Авто перезаход",
   CurrentValue = _G.AutoRejoin,
   Callback = function(Value)
       _G.AutoRejoin = Value
   end,
})

MainTab:CreateToggle({
   Name = "FPS Boost / Оптимизация ФПС",
   CurrentValue = _G.FPSBoostEnabled,
   Callback = function(Value)
       _G.FPSBoostEnabled = Value
       if Value then
           applyFPSBoost()
       end
   end,
})

-- Самый конец Блока 9 (в самом низу меню)
MainTab:CreateToggle({
   Name = "Anti-AFK / Защита от AFK",
   CurrentValue = _G.AntiAFK,
   Callback = function(Value)
       _G.AntiAFK = Value
   end,
})

-- Поле для ввода фейкового ника в 9 блоке
MainTab:CreateInput({
   Name = "Fake Name / Фейковый ник",
   PlaceholderText = "Введите имя...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       _G.FakeName = Text
       -- Сразу применяем к текущему персонажу
       if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
           LocalPlayer.Character.Humanoid.DisplayName = Text
       end
   end,
})

