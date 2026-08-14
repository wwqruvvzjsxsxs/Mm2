-- ========================================================
-- ПУНКТ 1: ПОДСВЕТКА ИГРОКОВ (ESP)
-- ========================================================

local Players = game:GetService("Players")
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
-- ПУНКТ 2: ПОДСВЕТКА ОРУЖИЯ (ESP WEAPON)
-- ========================================================

local Workspace = game:GetService("Workspace")

Translations.RU.GunESPButton = "подсветка оружия"
Translations.EN.GunESPButton = "ESP WEAPON"

_G.GunESP = true

local activeGunHighlight = nil

local function clearGunESP()
    if activeGunHighlight then
        activeGunHighlight:Destroy()
        activeGunHighlight = nil
    end
end

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

-- ========================================================
-- ПУНКТ 3: АВТО НАВОДКА И ВЫСТРЕЛ (AUTO-GUIDANCE & SHOOT)
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
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
-- ПУНКТ 4: АВТОФАРМ ПОД КАРТОЙ И СКОРОСТЬ (UNDERGROUND FARM & NOCLIP)
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

-- 1. Noclip (отключение столкновений с блоками при фарме под картой)
RunService.Stepped:Connect(function()
    if _G.AutoFarm and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 2. Принудительное назначение скорости бега
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

-- 3. Поиск ближайшей монеты на карте
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

-- 4. Телепортация под карту прямо под монеты
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.AutoFarm then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                local coin = getNearestCoin()
                if coin then
                    root.CFrame = coin.CFrame * CFrame.new(0, -2.5, 0)
                end
            end
        end
    end
end)
-- ========================================================
-- ПУНКТ 5: НЕВИДИМОСТЬ И АВТО-ПЕРЕЗАХОД (INVISIBILITY & AUTO-REJOIN)
-- ========================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

Translations.RU.InvisButton = "невидимость"
Translations.EN.InvisButton = "Invisibility"

_G.Invisibility = false
_G.AutoRejoin = true
local PinkColor = Color3.fromRGB(255, 105, 180)

-- Безопасная невидимость без багов модели
local function setInvisibility(state)
    _G.Invisibility = state
    local char = LocalPlayer.Character
    if not char then return end

    local highlight = char:FindFirstChild("Self_Invis_Highlight")

    if state then
        -- Розовый силуэт для удобства владельца
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

        -- Делаем части тела прозрачными
        for _, part in ipairs(char:GetDescendants()) do
            if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = 0.8
            end
        end
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

-- Авто-перезаход на сервер при кике или вылете
GuiService.ErrorMessageChanged:Connect(function()
    if _G.AutoRejoin then
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)
-- ========================================================
-- ПУНКТ 6: УВЕЛИЧЕНИЕ ХИТБОКСА МАРДЕРА (HITBOX EXPANDER)
-- ========================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
            -- Сброс размеров хитбокса
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
-- ПУНКТ 7: СБОРКА ИНТЕРФЕЙСА RAYFIELD
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
   Name = "ESP / подсветка",
   CurrentValue = _G.RolesESP,
   Callback = function(Value)
       _G.RolesESP = Value
   end,
})

MainTab:CreateColorPicker({
    Name = "Innocent ESP Color",
    Color = _G.InnocentColor,
    Callback = function(Value)
        _G.InnocentColor = Value
    end
})

-- [2] ESP Оружия
MainTab:CreateToggle({
   Name = "ESP WEAPON / подсветка оружия",
   CurrentValue = _G.GunESP,
   Callback = function(Value)
       _G.GunESP = Value
   end,
})

-- [3] Авто-наводка
MainTab:CreateToggle({
   Name = "auto-guidance / авто наводка",
   CurrentValue = _G.AimbotEnabled,
   Callback = function(Value)
       _G.AimbotEnabled = Value
   end,
})

-- [4] Хитбокс Мардера
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

-- [5] Автофарм и Скорость
MainTab:CreateToggle({
   Name = "Avto-farm / авто-фарм",
   CurrentValue = _G.AutoFarm,
   Callback = function(Value)
       _G.AutoFarm = Value
   end,
})

MainTab:CreateSlider({
   Name = "значение скорости персонажа / Player Speed",
   Range = {16, 60},
   Increment = 1,
   CurrentValue = _G.FarmSpeed,
   Callback = function(Value)
       _G.FarmSpeed = Value
   end,
})

-- [6] Невидимость и Авто-перезаход
MainTab:CreateToggle({
   Name = "Invisibility / невидимость",
   CurrentValue = _G.Invisibility,
   Callback = function(Value)
       setInvisibility(Value)
   end,
})

MainTab:CreateToggle({
   Name = "Auto-Rejoin / авто перезаход",
   CurrentValue = _G.AutoRejoin,
   Callback = function(Value)
       _G.AutoRejoin = Value
   end,
})



