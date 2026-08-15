-- ========================================================
-- MM2 ULTIMATE HUB - ИСПРАВЛЕННЫЙ АВТОФАРМ ПОД КАРТОЙ
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
            Duration = duration or 5,
            Icon = "rbxassetid://4483362458"
        })
    end)
end

-- Настройки
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
_G.FarmDelay = 0.2
_G.FarmHeight = -5.5          -- Рекомендую от -5.0 до -7.0

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

local function isInGame()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isRoundActive()
    if not isInGame() then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local role = getMM2Role(player)
            if role \~= "Innocent" then
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
    if not hl or hl.Parent \~= char then
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

local function isGunObject(obj)
    local name = obj.Name:lower()
    
    if name == "gun" or name == "pistol" or name == "пистолет" then
        return true
    end
    
    if obj:IsA("Tool") and (name:find("gun") or name:find("pistol") or name:find("пистолет")) then
        return true
    end
    
    return false
end

local function findGuns()
    local guns = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            if isGunObject(obj) then
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
    
    if #guns == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                local name = obj.Name:lower()
                if name == "gun" or name == "pistol" or name == "пистолет" or 
                   name == "gunhandle" or name == "gunbarrel" or name == "gunbody" then
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
    for gun, highlight in pairs(activeGunHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    activeGunHighlights = {}
    
    if not _G.GunESP then return end
    
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
-- СИСТЕМА ФЛАЯ
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
        
        local cameraForward = camera.CFrame.LookVector
        local cameraRight = camera.CFrame.RightVector
        
        local joyDirection = hum.MoveDirection
        local moveDirection = Vector3.zero
        
        if joyDirection.Z < 0 then
            moveDirection += cameraForward
        elseif joyDirection.Z > 0 then
            moveDirection -= cameraForward
        end
        
        if joyDirection.X > 0 then
            moveDirection += cameraRight
        elseif joyDirection.X < 0 then
            moveDirection -= cameraRight
        end
        
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            flyBodyVelocity.Velocity = moveDirection * _G.FlySpeed
        else
            flyBodyVelocity.Velocity = Vector3.zero
        end
        
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
-- СИСТЕМА ФАНТОМНОГО ПРИЗРАКА
-- ========================================================
local phantomLoop = nil
local selfHighlight = nil

local function findSheriffOrMurderer()
    local targets = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player \~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local role = getMM2Role(player)
            
            if hum and hum.Health > 0 and (role == "Sheriff" or role == "Murderer") then
                table.insert(targets, player)
            end
        end
    end
    
    if #targets == 0 then return nil end
    return targets[math.random(1, #targets)]
end

local function teleportToSheriffOrMurderer()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local targetPlayer = findSheriffOrMurderer()
    if not targetPlayer or not targetPlayer.Character then return false end
    
    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return false end
    
    local offset = Vector3.new(math.random(-3, 3), 2, math.random(-3, 3))
    char.HumanoidRootPart.CFrame = CFrame.new(targetHrp.Position + offset)
    
    return true
end

local function activatePhantomMode()
    local char = LocalPlayer.Character
    if not char then return end
    
    local teleported = teleportToSheriffOrMurderer()
    if not teleported then
        notify("❌ ОШИБКА", "Не удалось найти шерифа или мардера!", 3)
        _G.PhantomMode = false
        return
    end
    
    notify("👻 ФАНТОМНЫЙ РЕЖИМ", "Вы телепортированы!", 5)
    
    phantomLoop = task.spawn(function()
        while _G.PhantomMode and char and char.Parent do
            task.wait(0.1)
            
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
    
    if selfHighlight then
        selfHighlight:Destroy()
        selfHighlight = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
        end
        
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
-- СИСТЕМА АВТО ФАРМА (ИСПРАВЛЕННАЯ)
-- ========================================================
local farmVelocity = nil
local farmConnection = nil

local function enableStaticPhysics()
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    Workspace.Gravity = 0
    if hum then
        hum.PlatformStand = true
        hum.AutoRotate = false
    end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    if root and not farmVelocity then
        farmVelocity = Instance.new("BodyVelocity")
        farmVelocity.Name = "StaticFarmVelocity"
        farmVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        farmVelocity.Velocity = Vector3.zero
        farmVelocity.Parent = root
    end
end

local function disableFarmPhysics()
    Workspace.Gravity = originalGravity
    
    if farmVelocity then
        farmVelocity:Destroy()
        farmVelocity = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
        end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.CanTouch = true
                part.CanQuery = true
            end
        end
    end
end

local function forceCollect(coin)
    local char = LocalPlayer.Character
    if not char or not coin then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    
    pcall(function()
        if firetouchinterest then
            for i = 1, 18 do
                if root then
                    firetouchinterest(root, coin, 0)
                    firetouchinterest(root, coin, 1)
                end
                if head then
                    firetouchinterest(head, coin, 0)
                    firetouchinterest(head, coin, 1)
                end
                if torso then
                    firetouchinterest(torso, coin, 0)
                    firetouchinterest(torso, coin, 1)
                end
                task.wait()
            end
        end
    end)
end

-- Основной цикл фарма
task.spawn(function()
    while true do
        task.wait(_G.FarmDelay)
        
        if not _G.AutoFarm then
            disableFarmPhysics()
            continue
        end
        
        if not isInGame() then
            _G.AutoFarm = false
            disableFarmPhysics()
            continue
        end
        
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if not root or not hum or hum.Health <= 0 then
            continue
        end
        
        enableStaticPhysics()
        
        local coin = getNearestCoin()
        if not coin then continue end
        
        if _G.FarmMode == "UnderMap" then
            -- Под картой
            local depth = _G.FarmHeight
            if depth > -4 then
                depth = -5.5
            end
            
            local targetPos = coin.Position + Vector3.new(0, depth, 0)
            
            -- Ложимся + телепорт
            root.CFrame = CFrame.new(targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            
            forceCollect(coin)
            
        else
            -- На карте
            local targetPos = coin.Position + Vector3.new(0, 1.6, 0)
            root.CFrame = CFrame.new(targetPos)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            
            forceCollect(coin)
        end
    end
end)

-- ========================================================
-- СИСТЕМА УБИЙСТВА ВСЕХ
-- ========================================================
local function isPlayerInLobby(player)
    local char = player.Character
    if not char then return true end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return true end

    local lobby = Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("LobbySpawn")
    if lobby then
        local lobbyPos = lobby:IsA("BasePart") and lobby.Position or (lobby:FindFirstChildWhichIsA("BasePart") and lobby:FindFirstChildWhichIsA("BasePart").Position)
        if lobbyPos and (hrp.Position - lobbyPos).Magnitude < 120 then
            return true
        end
    end

    local coin = getNearestCoin()
    if coin and (hrp.Position - coin.Position).Magnitude > 300 then
        return true
    end

    return false
end

local function killAll()
    if getMM2Role(LocalPlayer) \~= "Murderer" then
        notify("❌ ОШИБКА", "Вы не Мардер!", 3)
        return
    end
    
    local myChar = LocalPlayer.Character
    if not myChar or not isInGame() then
        notify("❌ ОШИБКА", "Вы не в игре!", 3)
        return
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local knife = myChar:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))

    if not knife then
        notify("❌ ОШИБКА", "Нож не найден!", 3)
        return
    end

    if knife.Parent == backpack then
        knife.Parent = myChar
    end

    local knifeHandle = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
    if not knifeHandle then
        notify("❌ ОШИБКА", "Не найден Handle ножа!", 3)
        return
    end

    notify("💀 УБИЙСТВО ВСЕХ", "Начинаю ликвидацию игроков на карте...", 3)

    local killedCount = 0
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player \~= LocalPlayer and player.Character then
            local targetChar = player.Character
            local hum = targetChar:FindFirstChildOfClass("Humanoid")
            local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")

            if hum and hum.Health > 0 and targetHrp and not isPlayerInLobby(player) then
                myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1)
                task.wait(0.05)

                pcall(function()
                    if firetouchinterest then
                        firetouchinterest(knifeHandle, targetHrp, 0)
                        firetouchinterest(knifeHandle, targetHrp, 1)
                        
                        local head = targetChar:FindFirstChild("Head")
                        if head then
                            firetouchinterest(knifeHandle, head, 0)
                            firetouchinterest(knifeHandle, head, 1)
                        end
                    end
                    
                    knife:Activate()
                end)

                killedCount = killedCount + 1
                task.wait(0.12)
            end
        end
    end

    notify("✅ ГОТОВО!", "Ликвидировано игроков: " .. killedCount, 5)
end

-- ========================================================
-- ИНТЕРФЕЙС RAYFIELD
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "MM2 Ultimate Hub",
    LoadingTitle = "MM2 Script",
    LoadingSubtitle = "Loaded via Delta",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local CombatTab = Window:CreateTab("⚔️ Сражение", 4483362458)
local VisualTab = Window:CreateTab("👁️ Визуализация", 4483362458)
local FarmTab = Window:CreateTab("🪙 Фарм", 4483362458)
local MiscTab = Window:CreateTab("🔧 Прочее", 4483362458)

-- СРАЖЕНИЕ
CombatTab:CreateSection("Боевые функции")

CombatTab:CreateButton({
    Name = "💀 Убить всех",
    Callback = function()
        killAll()
    end,
})

CombatTab:CreateLabel("Убивает игроков только на карте (Мирных и Шерифа)")
CombatTab:CreateLabel("Работает только если вы Мардер")

-- ВИЗУАЛИЗАЦИЯ
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
            if not isRoundActive() then
                notify("❌ ОШИБКА", "Раунд еще не начался!", 3)
                _G.PhantomMode = false
                return
            end
            
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

-- ФАРМ
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
            notify("🪙 ФАРМ ВКЛЮЧЕН", "Режим: " .. (_G.FarmMode == "UnderMap" and "Под картой" or "На карте"), 3)
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
        local choice = type(Option) == "table" and Option[1] or Option
        if choice == "На карте" then
            _G.FarmMode = "OnMap"
        else
            _G.FarmMode = "UnderMap"
        end
        notify("🔄 РЕЖИМ ФАРМА", "Выбран: " .. choice, 3)
    end,
})

FarmTab:CreateSlider({
    Name = "Скорость сборки монет",
    Range = {0.08, 1.5},
    Increment = 0.05,
    Suffix = "сек",
    CurrentValue = _G.FarmDelay,
    Callback = function(Value)
        _G.FarmDelay = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Высота сбора (Под картой)",
    Range = {-9, -3},
    Increment = 0.2,
    Suffix = " блоков",
    CurrentValue = _G.FarmHeight,
    Callback = function(Value)
        _G.FarmHeight = Value
        notify("📏 ВЫСОТА", "Глубина: " .. Value, 2)
    end,
})

-- ПРОЧЕЕ
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

notify("✅ СКРИПТ ЗАГРУЖЕН", "Автофарм под картой исправлен", 5)
