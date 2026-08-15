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
-- ESP СИСТЕМА (ОРУЖИЕ)
-- ========================================================
local activeGunHighlights = {}

local function findGuns()
    local guns = {}
    
    -- Ищем оружие в Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or obj:IsA("Model") then
            local name = obj.Name:lower()
            -- Ищем пистолеты и ножи
            if name:find("gun") or name:find("pistol") or name:find("пистолет") or 
               name:find("knife") or name:find("нож") then
                -- Проверяем, что оружие не у игрока в руках
                local parent = obj.Parent
                local isInCharacter = false
                
                -- Проверяем, не находится ли оружие у кого-то в инвентаре или руках
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
        elseif obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            if name:find("gun") or name:find("pistol") or name:find("пистолет") or 
               name:find("knife") or name:find("нож") then
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
        
        -- Обновляем подсветку оружия
        updateGunESP()
    end
end)

Players.PlayerRemoving:Connect(removeHighlight)

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

VisualTab:CreateSection("Информация о ролях")
VisualTab:CreateLabel("🔴 Красный - Мардер")
VisualTab:CreateLabel("🔵 Синий - Шериф")
VisualTab:CreateLabel("🟢 Зеленый - Невинный (настраиваемый)")
VisualTab:CreateLabel("⚫ Черный - Оружие (настраиваемый)")

-- Заглушки для других вкладок
CombatTab:CreateSection("Боевые функции")
CombatTab:CreateLabel("Здесь будут боевые функции")

FarmTab:CreateSection("Фарм функции")
FarmTab:CreateLabel("Здесь будут функции фарма")

MiscTab:CreateSection("Прочие функции")
MiscTab:CreateLabel("Здесь будут прочие функции")

notify("✅ СКРИПТ ЗАГРУЖЕН!", "Базовая версия активирована!", 5)
