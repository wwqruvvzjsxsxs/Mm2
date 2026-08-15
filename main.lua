-- ========================================================
-- MM2 ULTIMATE HUB - С АВТО-УБИЙЦЕЙ ДЛЯ МАРДЕРА
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")

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
_G.RolesESP = true
_G.InnocentColor = Color3.fromRGB(0, 255, 0)
_G.ESPTransparency = 0.4
_G.GunESP = true
_G.AimbotEnabled = false
_G.AimbotSmoothness = 0.3
_G.AutoFarm = false
_G.FarmSpeed = 20
_G.CoinHitboxSize = 5
_G.FarmTeleportDelay = 0.5
_G.FarmMode = "OnMap"
_G.Invisibility = false
_G.AutoRejoin = true
_G.AntiAFK = true
_G.HitboxEnabled = false
_G.HitboxSize = 10
_G.HitboxTransparency = 0.7
_G.FPSBoostEnabled = false
_G.FakeName = ""
_G.FlyEnabled = false
_G.FlyNoClip = false
_G.FlySpeed = 50
_G.WallHack = false
_G.SelectedPlayer = nil
_G.AutoKillMurderer = false
_G.AutoDeathCycle = false
_G.MaxCoins = 40
_G.PhantomMode = false
_G.AutoMurderer = false  -- Новая функция: авто-убийца для Мардера
_G.MurdererKillDelay = 1.5  -- Задержка между убийствами

local MurdererColor = Color3.fromRGB(255, 0, 0)
local SheriffColor = Color3.fromRGB(0, 0, 255)

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
    
    local myRole = getMM2Role(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local role = getMM2Role(player)
            if role ~= "Innocent" then
                return true
            end
        end
    end
    
    return myRole ~= "Innocent"
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
-- АВТО-УБИЙЦА ДЛЯ МАРДЕРА
-- ========================================================
local function findNearestTarget()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position
    
    local nearestTarget = nil
    local minDistance = 999999
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                -- Не убиваем других Мардеров (если они есть)
                local targetRole = getMM2Role(player)
                if targetRole ~= "Murderer" then
                    local dist = (myPos - hrp.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        nearestTarget = player
                    end
                end
            end
        end
    end
    
    return nearestTarget
end

task.spawn(function()
    while true do
        task.wait(0.1)
        
        if _G.AutoMurderer and getMM2Role(LocalPlayer) == "Murderer" and isInGame() then
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            
            if myHrp and myHum and myHum.Health > 0 then
                local target = findNearestTarget()
                
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
                    local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
                    
                    if targetHum and targetHum.Health > 0 then
                        -- Телепортируемся к цели
                        myHrp.CFrame = CFrame.new(targetHrp.Position + Vector3.new(0, 2, 0))
                        
                        -- Берем нож
                        local knife = myChar:FindFirstChild("Knife") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Knife"))
                        if knife and knife:IsA("Tool") then
                            if knife.Parent ~= myChar then
                                myHum:EquipTool(knife)
                            end
                            
                            -- Активируем нож (удар)
                            knife:Activate()
                            
                            -- Дополнительный удар для надежности
                            task.wait(0.1)
                            knife:Activate()
                            
                            notify("🔪 УБИЙСТВО", "Убит: " .. target.Name, 2)
                        else
                            notify("❌ НЕТ НОЖА", "Вы не Мардер или нет ножа!", 3)
                            _G.AutoMurderer = false
                        end
                        
                        -- Задержка перед следующим убийством
                        task.wait(_G.MurdererKillDelay)
                    end
                else
                    -- Нет целей
                    task.wait(1)
                end
            end
        end
    end
end)

-- ========================================================
-- АВТО-ЦИКЛ (Исправленный)
-- ========================================================
local cycleWaitingForRound = false

task.spawn(function()
    while true do
        task.wait(1)
        
        if _G.AutoDeathCycle then
            if isInGame() and isRoundActive() then
                if cycleWaitingForRound then
                    cycleWaitingForRound = false
                    notify("🔄 НОВЫЙ РАУНД", "Продолжаю фарм!", 3)
                end
                
                if not _G.AutoFarm then
                    _G.AutoFarm = true
                    notify("🪙 ФАРМ ВКЛЮЧЕН", "Собираю монеты...", 3)
                end
                
                local coinsOnMap = #findAllCoins()
                local collectedCoins = _G.MaxCoins - coinsOnMap
                
                if collectedCoins < 0 then collectedCoins = 0 end
                
                if collectedCoins >= _G.MaxCoins then
                    notify("💀 СМЕРТЬ", "Собрано " .. _G.MaxCoins .. " монет! Умираю...", 3)
                    
                    _G.AutoFarm = false
                    
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.Health = 0
                        end
                    end
                    
                    cycleWaitingForRound = true
                    notify("⏳ ОЖИДАНИЕ", "Жду новый раунд...", 3)
                end
            elseif not isInGame() and not cycleWaitingForRound then
                notify("⏳ ОЖИДАНИЕ", "Вы в лобби. Жду начала раунда...", 3)
                cycleWaitingForRound = true
            end
        end
    end
end)

-- ========================================================
-- АВТОФАРМ (Исправленный)
-- ========================================================
task.spawn(function()
    while true do
        task.wait(_G.FarmTeleportDelay)
        if _G.AutoFarm then
            if not isInGame() then
                notify("❌ ОШИБКА", "Вы не в игре! Фарм отключен!", 3)
                _G.AutoFarm = false
                continue
            end
            
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                
                local coin = getNearestCoin()
                if coin then
                    pcall(function()
                        coin.Size = Vector3.new(_G.CoinHitboxSize, _G.CoinHitboxSize, _G.CoinHitboxSize)
                        coin.CanCollide = false
                    end)
                    
                    if _G.FarmMode == "UnderMap" then
                        root.CFrame = CFrame.new(coin.Position.X, coin.Position.Y - 3, coin.Position.Z)
                    else
                        root.CFrame = CFrame.new(coin.Position.X, coin.Position.Y + 3, coin.Position.Z)
                    end
                    
                    root.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

-- ========================================================
-- ФАНТОМ-ПРИЗРАК
-- ========================================================
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.PhantomMode then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.MaxHealth = 999999
                    hum.Health = 999999
                    
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            part.CanTouch = false
                            part.CanQuery = false
                        end
                    end
                    
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.LocalTransparencyModifier = 0.5
                        end
                    end
                    
                    if not char:FindFirstChild("Phantom_Highlight") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "Phantom_Highlight"
                        highlight.FillColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineColor = Color3.fromRGB(150, 150, 255)
                        highlight.FillTransparency = 0.8
                        highlight.OutlineTransparency = 0.3
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = char
                    end
                end
            end
        else
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.MaxHealth = 100
                    hum.Health = 100
                end
                
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 0
                        part.CanCollide = true
                        part.CanTouch = true
                        part.CanQuery = true
                    end
                end
                
                local phantomHighlight = char:FindFirstChild("Phantom_Highlight")
                if phantomHighlight then
                    phantomHighlight:Destroy()
                end
            end
        end
    end
end)

-- ========================================================
-- ФЛАЙ (Исправленный - летит куда смотрит камера)
-- ========================================================
local flyBodyVel = nil
local flyBodyGyro = nil

task.spawn(function()
    while true do
        task.wait(0.01)
        local char = LocalPlayer.Character
        if not char then 
            if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
            continue 
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not hum then continue end
        
        if _G.FlyEnabled then
            if _G.FlyNoClip or _G.WallHack then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
            
            hum.PlatformStand = true
            
            if not flyBodyVel or flyBodyVel.Parent ~= hrp then
                if flyBodyVel then flyBodyVel:Destroy() end
                flyBodyVel = Instance.new("BodyVelocity")
                flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                flyBodyVel.Velocity = Vector3.new(0, 0, 0)
                flyBodyVel.Parent = hrp
            end
            
            if not flyBodyGyro or flyBodyGyro.Parent ~= hrp then
                if flyBodyGyro then flyBodyGyro:Destroy() end
                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                flyBodyGyro.P = 10000
                flyBodyGyro.CFrame = Camera.CFrame
                flyBodyGyro.Parent = hrp
            end
            
            local moveDirection = Vector3.new(0, 0, 0)
            
            if hum.MoveDirection.Z < 0 then
                moveDirection = moveDirection + Camera.CFrame.LookVector
            elseif hum.MoveDirection.Z > 0 then
                moveDirection = moveDirection - Camera.CFrame.LookVector
            end
            
            if hum.MoveDirection.X > 0 then
                moveDirection = moveDirection + Camera.CFrame.RightVector
            elseif hum.MoveDirection.X < 0 then
                moveDirection = moveDirection - Camera.CFrame.RightVector
            end
            
            if hum.Jump then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            
            if moveDirection.Magnitude > 0 then
                flyBodyVel.Velocity = moveDirection.Unit * _G.FlySpeed
            else
                flyBodyVel.Velocity = Vector3.new(0, 0, 0)
            end
            
            flyBodyGyro.CFrame = Camera.CFrame
        else
            hum.PlatformStand = false
            if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        end
    end
end)

-- ========================================================
-- ОТСЛЕЖИВАНИЕ СТАТУСА ИГРЫ
-- ========================================================
local lastRole = ""
local roundActive = false

task.spawn(function()
    while true do
        task.wait(1)
        
        if isInGame() then
            local newRole = getMM2Role(LocalPlayer)
            
            if newRole ~= lastRole then
                lastRole = newRole
                
                if newRole == "Murderer" then
                    notify("🔪 ВЫ МАРДЕР!", "Быстрее убивайте всех!", 7)
                elseif newRole == "Sheriff" then
                    notify("🔫 ВЫ ШЕРИФ!", "Найдите и убейте Мардера!", 7)
                elseif newRole == "Innocent" then
                    notify("👤 ВЫ МИРНЫЙ", "Прячьтесь от Мардера!", 5)
                end
            end
            
            if not roundActive then
                roundActive = true
                notify("🎮 РАУНД НАЧАЛСЯ!", "Будьте аккуратнее!", 6)
            end
        else
            if roundActive then
                roundActive = false
                lastRole = ""
                notify("⏸️ РАУНД ОКОНЧЕН", "Ожидание следующего раунда...", 4)
            end
        end
    end
end)

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
-- ESP ОРУЖИЯ
-- ========================================================
local activeGunHighlight = nil

task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.GunESP then
            local gunDrop = Workspace:FindFirstChild("GunDrop") or Workspace:FindFirstChild("Gun")
            
            if gunDrop and (gunDrop:IsA("BasePart") or gunDrop:IsA("Model")) then
                if not activeGunHighlight or activeGunHighlight.Parent ~= gunDrop then
                    if activeGunHighlight then activeGunHighlight:Destroy() end
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
                if activeGunHighlight then activeGunHighlight:Destroy() activeGunHighlight = nil end
            end
        else
            if activeGunHighlight then activeGunHighlight:Destroy() activeGunHighlight = nil end
        end
    end
end)

-- ========================================================
-- НЕВИДИМОСТЬ
-- ========================================================
local invisLoop = nil

local function setInvisibility(state)
    _G.Invisibility = state
    local char = LocalPlayer.Character
    if not char then return end

    if state then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = 1
            end
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "Self_Invis_Highlight"
        highlight.FillColor = Color3.fromRGB(255, 105, 180)
        highlight.OutlineColor = Color3.fromRGB(255, 192, 203)
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char
        
        invisLoop = task.spawn(function()
            while _G.Invisibility and char and char.Parent do
                task.wait(0.1)
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.LocalTransparencyModifier = 1
                    end
                end
            end
        end)
        
        notify("👻 НЕВИДИМОСТЬ ВКЛЮЧЕНА", "Вас не видно!", 5)
    else
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
        
        local highlight = char:FindFirstChild("Self_Invis_Highlight")
        if highlight then
            highlight:Destroy()
        end
        
        if invisLoop then
            task.cancel(invisLoop)
            invisLoop = nil
        end
        
        notify("👁️ НЕВИДИМОСТЬ ВЫКЛЮЧЕНА", "Вас снова видно!", 3)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    _G.Invisibility = false
    if invisLoop then
        task.cancel(invisLoop)
        invisLoop = nil
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
        notify("⚠️ ВНИМАНИЕ!", "Произошла ошибка! Перезаходим...", 5)
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
            end)
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
-- ИНТЕРФЕЙС
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "MM2 Ultimate Hub",
    LoadingTitle = "MM2 Script",
    LoadingSubtitle = "Final Version",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab("Главная", 4483362458)
local FarmTab = Window:CreateTab("Фарм", 4483362458)
local TeleportTab = Window:CreateTab("Телепорт", 4483362458)
local MiscTab = Window:CreateTab("Разное", 4483362458)

-- Главная вкладка
MainTab:CreateToggle({
    Name = "ESP / Подсветка игроков",
    CurrentValue = _G.RolesESP,
    Callback = function(Value)
        _G.RolesESP = Value
    end,
})

MainTab:CreateColorPicker({
    Name = "Цвет мирных игроков",
    Color = _G.InnocentColor,
    Callback = function(Value)
        _G.InnocentColor = Value
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
    Name = "🔪 АВТО-УБИЙЦА (Для Мардера)",
    CurrentValue = _G.AutoMurderer,
    Callback = function(Value)
        _G.AutoMurderer = Value
        if Value then
            if getMM2Role(LocalPlayer) == "Murderer" then
                notify("🔪 АВТО-УБИЙЦА ВКЛЮЧЕН", "Телепортируюсь и убиваю всех!", 5)
            else
                notify("⚠️ ВНИМАНИЕ", "Вы не Мардер! Функция работает только для Мардера!", 5)
                _G.AutoMurderer = false
            end
        else
            notify("🛑 АВТО-УБИЙЦА ВЫКЛЮЧЕН", "Функция отключена", 3)
        end
    end,
})

MainTab:CreateSlider({
    Name = "Задержка между убийствами",
    Range = {0.5, 5},
    Increment = 0.5,
    Suffix = "сек",
    CurrentValue = _G.MurdererKillDelay,
    Callback = function(Value)
        _G.MurdererKillDelay = Value
    end,
})

MainTab:CreateToggle({
    Name = "👻 ФАНТОМ-ПРИЗРАК",
    CurrentValue = _G.PhantomMode,
    Callback = function(Value)
        _G.PhantomMode = Value
        if Value then
            notify("👻 ФАНТОМ ВКЛЮЧЕН", "Вас видно, но убить нельзя!", 5)
        else
            notify("👁️ ФАНТОМ ВЫКЛЮЧЕН", "Вы снова обычный игрок!", 3)
        end
    end,
})

MainTab:CreateToggle({
    Name = "Проходить сквозь стены",
    CurrentValue = _G.WallHack,
    Callback = function(Value)
        _G.WallHack = Value
    end,
})

MainTab:CreateToggle({
    Name = "🔫 АВТО-УБИЙЦА МАРДЕРА (Для Шерифа)",
    CurrentValue = _G.AutoKillMurderer,
    Callback = function(Value)
        _G.AutoKillMurderer = Value
        if Value then
            notify("🎯 АВТО-УБИЙЦА ВКЛЮЧЕН", "Навожусь и стреляю в Мардера!", 5)
        end
    end,
})

-- Вкладка Фарм
FarmTab:CreateToggle({
    Name = "Авто-фарм монет",
    CurrentValue = _G.AutoFarm,
    Callback = function(Value)
        if Value and not isInGame() then
            notify("❌ ОШИБКА", "Вы не в игре! Нельзя включить фарм!", 3)
            _G.AutoFarm = false
            return
        end
        _G.AutoFarm = Value
        if Value then
            notify("🪙 ФАРМ ВКЛЮЧЕН", "Собираю монеты!", 3)
        end
    end,
})

FarmTab:CreateDropdown({
    Name = "Режим фарма",
    Options = {"OnMap", "UnderMap"},
    CurrentOption = {"OnMap"},
    MultipleOptions = false,
    Callback = function(Option)
        _G.FarmMode = Option[1]
        notify("🔄 РЕЖИМ ФАРМА", "Выбран режим: " .. Option[1], 3)
    end,
})

FarmTab:CreateToggle({
    Name = "💀 АВТО-ЦИКЛ (Фарм+Смерть+Авто)",
    CurrentValue = _G.AutoDeathCycle,
    Callback = function(Value)
        _G.AutoDeathCycle = Value
        if Value then
            notify("💀 АВТО-ЦИКЛ ВКЛЮЧЕН", "Буду фармить и умирать автоматически!", 5)
        else
            notify("🛑 АВТО-ЦИКЛ ВЫКЛЮЧЕН", "Цикл остановлен", 3)
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Скорость подбора монет",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "сек",
    CurrentValue = _G.FarmTeleportDelay,
    Callback = function(Value)
        _G.FarmTeleportDelay = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Скорость персонажа",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = _G.FarmSpeed,
    Callback = function(Value)
        _G.FarmSpeed = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Размер хитбокса монет",
    Range = {3, 20},
    Increment = 1,
    CurrentValue = _G.CoinHitboxSize,
    Callback = function(Value)
        _G.CoinHitboxSize = Value
    end,
})

FarmTab:CreateToggle({
    Name = "Флай",
    CurrentValue = _G.FlyEnabled,
    Callback = function(Value)
        _G.FlyEnabled = Value
        if Value then
            notify("✈️ ФЛАЙ ВКЛЮЧЕН", "Летите куда смотрит камера!", 3)
        end
    end,
})

FarmTab:CreateToggle({
    Name = "Сквозь стены (при флае)",
    CurrentValue = _G.FlyNoClip,
    Callback = function(Value)
        _G.FlyNoClip = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Скорость полета",
    Range = {20, 200},
    Increment = 10,
    CurrentValue = _G.FlySpeed,
    Callback = function(Value)
        _G.FlySpeed = Value
    end,
})

-- Вкладка Телепорт
TeleportTab:CreateDropdown({
    Name = "Выберите игрока",
    Options = {},
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(Option)
        if Option and Option[1] then
            _G.SelectedPlayer = Option[1]
            notify("👤 ИГРОК ВЫБРАН", "Выбран: " .. Option[1], 3)
        end
    end,
})

TeleportTab:CreateButton({
    Name = "Телепортироваться к игроку",
    Callback = function()
        if _G.SelectedPlayer then
            local targetPlayer = Players:FindFirstChild(_G.SelectedPlayer)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local targetPos = targetPlayer.Character.HumanoidRootPart.Position
                    myChar.HumanoidRootPart.CFrame = CFrame.new(targetPos.X, targetPos.Y + 3, targetPos.Z)
                    notify("✅ ТЕЛЕПОРТАЦИЯ", "Телепортирован к: " .. _G.SelectedPlayer, 3)
                end
            else
                notify("❌ ОШИБКА", "Игрок не найден!", 3)
            end
        else
            notify("❌ ОШИБКА", "Выберите игрока!", 3)
        end
    end,
})

-- Разное
MiscTab:CreateToggle({
    Name = "Невидимость",
    CurrentValue = _G.Invisibility,
    Callback = function(Value)
        setInvisibility(Value)
    end,
})

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

MiscTab:CreateToggle({
    Name = "Авто-перезаход",
    CurrentValue = _G.AutoRejoin,
    Callback = function(Value)
        _G.AutoRejoin = Value
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

Rayfield:LoadConfiguration()
notify("✅ СКРИПТ ЗАГРУЖЕН!", "Все функции активны!", 5)
