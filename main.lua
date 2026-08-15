-- ========================================================
-- MM2 ULTIMATE HUB - С СУПЕР-МАГНИТОМ И АВТОСМЕРТЬЮ
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")

-- ========================================================
-- СИСТЕМА УВЕДОМЛЕНИЙ
-- ========================================================
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

-- ========================================================
-- НАСТРОЙКИ
-- ========================================================
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
_G.SmartMagnet = false
_G.MagnetRadius = 200
_G.MagnetStrength = 50
_G.RotationSpeed = 2
_G.AutoDeath = false  -- Автосмерть при переполнении
_G.MaxCoins = 40  -- Максимум монет

local MurdererColor = Color3.fromRGB(255, 0, 0)
local SheriffColor = Color3.fromRGB(0, 0, 255)
local lastMagnetCount = nil

-- ========================================================
-- ФУНКЦИЯ ОПРЕДЕЛЕНИЯ РОЛИ
-- ========================================================
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
-- ПОИСК МОНЕТ
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
-- СУПЕР-МАГНИТ МОНЕТ
-- ========================================================
local smartMagnetLoop = nil

local function findMapCenter()
    local coins = findAllCoins()
    if #coins == 0 then return Vector3.new(0, -10, 0) end
    
    local totalX = 0
    local totalZ = 0
    
    for _, coin in ipairs(coins) do
        totalX = totalX + coin.Position.X
        totalZ = totalZ + coin.Position.Z
    end
    
    local centerX = totalX / #coins
    local centerZ = totalZ / #coins
    
    return Vector3.new(centerX, -10, centerZ)
end

local function enableSmartMagnet()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not hum or hum.Health <= 0 then
        notify("❌ ОШИБКА", "Вы должны быть в игре и живы!", 3)
        _G.SmartMagnet = false
        return
    end
    
    local center = findMapCenter()
    
    notify("🧲 СУПЕР-МАГНИТ ВКЛЮЧЕН", "Телепортирую под карту и собираю монеты!", 5)
    
    hrp.CFrame = CFrame.new(center)
    
    -- Включаем NoClip
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    smartMagnetLoop = task.spawn(function()
        while _G.SmartMagnet and char and char.Parent do
            task.wait(0.05)
            
            local currentHrp = char:FindFirstChild("HumanoidRootPart")
            local currentHum = char:FindFirstChildOfClass("Humanoid")
            
            if not currentHrp or not currentHum or currentHum.Health <= 0 then
                break
            end
            
            -- Удерживаем позицию
            currentHrp.Velocity = Vector3.new(0, 0, 0)
            
            -- Вращаемся
            local rotationAngle = tick() * _G.RotationSpeed
            currentHrp.CFrame = CFrame.new(center) * CFrame.Angles(0, rotationAngle, 0)
            
            -- Притягиваем монеты
            local coins = findAllCoins()
            local collectedCount = 0
            
            for _, coin in ipairs(coins) do
                if coin and coin.Parent then
                    local distance = (currentHrp.Position - coin.Position).Magnitude
                    
                    if distance < _G.MagnetRadius then
                        collectedCount = collectedCount + 1
                        
                        pcall(function()
                            coin.Anchored = false
                            coin.CanCollide = false
                            
                            local direction = (currentHrp.Position - coin.Position).Unit
                            local strength = _G.MagnetStrength * (1 - distance / _G.MagnetRadius) * 2
                            
                            coin.Position = coin.Position + direction * strength
                            coin.Velocity = direction * strength * 10
                            
                            if distance < 5 then
                                coin.Position = currentHrp.Position + Vector3.new(0, 3, 0)
                                coin.Anchored = true
                            end
                        end)
                    end
                end
            end
            
            if collectedCount > 0 then
                if not lastMagnetCount or (tick() - lastMagnetCount) > 10 then
                    notify("🧲 СБОР МОНЕТ", "Притянуто монет: " .. collectedCount, 2)
                    lastMagnetCount = tick()
                end
            end
        end
    end)
end

local function disableSmartMagnet()
    _G.SmartMagnet = false
    
    if smartMagnetLoop then
        task.cancel(smartMagnetLoop)
        smartMagnetLoop = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum then
            hrp.CFrame = CFrame.new(hrp.Position.X, 10, hrp.Position.Z)
            
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
    
    notify("🧲 МАГНИТ ВЫКЛЮЧЕН", "Возвращаю на карту!", 3)
end

-- ========================================================
-- АВТОСМЕРТЬ ПРИ ПЕРЕПОЛНЕНИИ МОНЕТ
-- ========================================================
task.spawn(function()
    while true do
        task.wait(1)  -- Проверка каждую секунду
        if _G.AutoDeath then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                -- Проверяем количество монет
                local coinCount = #findAllCoins()
                
                -- Если монет мало (значит мы собрали много)
                if coinCount < 10 then
                    notify("💀 АВТОСМЕРТЬ", "Монеты собраны! Умираю и возвращаюсь в лобби...", 3)
                    
                    -- Убиваем себя
                    hum.Health = 0
                    
                    -- Отключаем фарм и магнит
                    _G.AutoFarm = false
                    _G.SmartMagnet = false
                    if smartMagnetLoop then
                        task.cancel(smartMagnetLoop)
                        smartMagnetLoop = nil
                    end
                    
                    -- Ждем возрождения
                    task.wait(2)
                    
                    notify("✅ В ЛОББИ", "Монеты сохранены! Следующий заход...", 3)
                end
            end
        end
    end
end)

-- ========================================================
-- ОТСЛЕЖИВАНИЕ СТАТУСА ИГРЫ
-- ========================================================
local lastRole = ""
local roundActive = false
local lastMurdererWarning = nil

task.spawn(function()
    while true do
        task.wait(1)
        
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if hum and hum.Health > 0 then
            local newRole = getMM2Role(LocalPlayer)
            
            if newRole ~= lastRole then
                lastRole = newRole
                
                if newRole == "Murderer" then
                    notify("🔪 ВЫ МАРДЕР!", "Быстрее убивайте всех! У вас есть нож!", 7)
                elseif newRole == "Sheriff" then
                    notify("🔫 ВЫ ШЕРИФ!", "Найдите и убейте Мардера! У вас есть пистолет!", 7)
                elseif newRole == "Innocent" then
                    notify("👤 ВЫ МИРНЫЙ", "Прячьтесь от Мардера и помогайте Шерифу!", 5)
                end
            end
            
            if not roundActive then
                roundActive = true
                notify("🎮 РАУНД НАЧАЛСЯ!", "Будьте аккуратнее! Осмотритесь вокруг!", 6)
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

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        if _G.SmartMagnet then
            disableSmartMagnet()
        end
        notify("💀 ВЫ ПОГИБЛИ", "Не расстраивайтесь! В следующем раунде повезет!", 5)
    end)
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
-- ПРОХОЖДЕНИЕ СКВОЗЬ СТЕНЫ
-- ========================================================
task.spawn(function()
    while true do
        task.wait(0.05)
        if _G.WallHack then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- ========================================================
-- АВТОФАРМ
-- ========================================================
task.spawn(function()
    while true do
        task.wait(_G.FarmTeleportDelay)
        if _G.AutoFarm and not _G.SmartMagnet then  -- Не конфликтует с магнитом
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
                    
                    root.CFrame = CFrame.new(coin.Position.X, coin.Position.Y + 3, coin.Position.Z)
                    root.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

-- ========================================================
-- СКОРОСТЬ ПЕРСОНАЖА
-- ========================================================
task.spawn(function()
    while true do
        task.wait(0.2)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if _G.AutoFarm and _G.FarmSpeed >= 16 then
                    hum.WalkSpeed = _G.FarmSpeed
                else
                    hum.WalkSpeed = 16
                end
            end
        end
    end
end)

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
-- ФЛАЙ
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
-- АВТО-УБИЙЦА МАРДЕРА
-- ========================================================
local function findMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local role = getMM2Role(player)
            if role == "Murderer" then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    return player, hrp
                end
            end
        end
    end
    return nil, nil
end

task.spawn(function()
    while true do
        task.wait(0.01)
        if _G.AutoKillMurderer and getMM2Role(LocalPlayer) == "Sheriff" then
            local myChar = LocalPlayer.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            
            if myHum and myHrp and myHum.Health > 0 then
                local murderer, murHrp = findMurderer()
                
                if murderer and murHrp then
                    local distance = (myHrp.Position - murHrp.Position).Magnitude
                    local direction = (murHrp.Position - Camera.CFrame.Position).Unit
                    local angle = math.acos(math.clamp(direction:Dot(Camera.CFrame.LookVector), -1, 1))
                    local angleDegrees = math.deg(angle)
                    
                    if distance < 200 and angleDegrees < 90 then
                        local lookAt = CFrame.lookAt(Camera.CFrame.Position, murHrp.Position)
                        Camera.CFrame = Camera.CFrame:Lerp(lookAt, 0.5)
                        
                        local gun = myChar:FindFirstChild("Gun") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Gun"))
                        if gun and gun:IsA("Tool") then
                            if gun.Parent ~= myChar then
                                myHum:EquipTool(gun)
                            end
                            gun:Activate()
                        else
                            notify("❌ НЕТ ПИСТОЛЕТА", "Вы не Шериф или у вас нет оружия!", 3)
                            _G.AutoKillMurderer = false
                        end
                    else
                        if distance >= 200 then
                            myHrp.CFrame = CFrame.new(murHrp.Position.X, murHrp.Position.Y + 5, murHrp.Position.Z - 20)
                            notify("🔍 ПОИСК МАРДЕРА", "Телепортируюсь к Мардеру...", 2)
                        end
                    end
                else
                    task.wait(1)
                end
            end
        else
            task.wait(0.5)
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
                
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        
        notify("👻 НЕВИДИМОСТЬ ВКЛЮЧЕНА", "Можно собирать монеты и убивать!", 5)
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
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                        obj.Enabled = false
                    end
                end
            end)
        end
    end
end)

-- ========================================================
-- ХИТБОКС МАРДЕРА
-- ========================================================
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
                            pcall(function()
                                hrp.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                                hrp.Transparency = _G.HitboxTransparency
                                hrp.Color = Color3.fromRGB(255, 0, 0)
                                hrp.Material = Enum.Material.ForceField
                                hrp.CanCollide = false
                                
                                for _, part in ipairs(char:GetChildren()) do
                                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                        part.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                                        part.Transparency = _G.HitboxTransparency
                                        part.CanCollide = false
                                    end
                                end
                            end)
                        end
                    end
                end
            end
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
    LoadingSubtitle = "Ultimate Version",
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
        notify("🎨 ЦВЕТ ОБНОВЛЕН", "Цвет мирных игроков изменен!", 3)
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
    Name = "Проходить сквозь стены",
    CurrentValue = _G.WallHack,
    Callback = function(Value)
        _G.WallHack = Value
        if Value then
            notify("🚪 WALLHACK ВКЛЮЧЕН", "Теперь вы проходите сквозь стены!", 3)
        end
    end,
})

MainTab:CreateToggle({
    Name = "🔫 АВТО-УБИЙЦА МАРДЕРА",
    CurrentValue = _G.AutoKillMurderer,
    Callback = function(Value)
        _G.AutoKillMurderer = Value
        if Value then
            if getMM2Role(LocalPlayer) == "Sheriff" then
                notify("🎯 АВТО-УБИЙЦА ВКЛЮЧЕН", "Автоматически навожусь и стреляю в Мардера!", 5)
            else
                notify("⚠️ ВНИМАНИЕ", "Вы не Шериф! Функция работает только для Шерифа!", 5)
                _G.AutoKillMurderer = false
            end
        else
            notify("🛑 АВТО-УБИЙЦА ВЫКЛЮЧЕН", "Функция отключена", 3)
        end
    end,
})

MainTab:CreateToggle({
    Name = "Увеличить хитбокс Мардера",
    CurrentValue = _G.HitboxEnabled,
    Callback = function(Value)
        _G.HitboxEnabled = Value
    end,
})

MainTab:CreateSlider({
    Name = "Размер хитбокса Мардера",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = _G.HitboxSize,
    Callback = function(Value)
        _G.HitboxSize = Value
    end,
})

-- Вкладка Фарм
FarmTab:CreateToggle({
    Name = "Авто-фарм монет",
    CurrentValue = _G.AutoFarm,
    Callback = function(Value)
        _G.AutoFarm = Value
        if Value then
            notify("🪙 АВТО-ФАРМ ВКЛЮЧЕН", "Начинаю собирать монеты!", 3)
        end
    end,
})

FarmTab:CreateToggle({
    Name = "🧲 Супер-магнит монет",
    CurrentValue = _G.SmartMagnet,
    Callback = function(Value)
        if Value then
            enableSmartMagnet()
        else
            disableSmartMagnet()
        end
    end,
})

FarmTab:CreateToggle({
    Name = "💀 Автосмерть при сборе",
    CurrentValue = _G.AutoDeath,
    Callback = function(Value)
        _G.AutoDeath = Value
        if Value then
            notify("💀 АВТОСМЕРТЬ ВКЛЮЧЕНА", "Умру автоматически после сбора монет!", 3)
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Радиус магнита",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = _G.MagnetRadius,
    Callback = function(Value)
        _G.MagnetRadius = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Сила притяжения",
    Range = {10, 100},
    Increment = 5,
    CurrentValue = _G.MagnetStrength,
    Callback = function(Value)
        _G.MagnetStrength = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Скорость вращения",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.RotationSpeed,
    Callback = function(Value)
        _G.RotationSpeed = Value
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
        if Value < 0.3 then
            notify("⚠️ ОСТОРОЖНО!", "Слишком быстро может кикнуть!", 3)
        end
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

FarmTab:CreateToggle({
    Name = "Флай",
    CurrentValue = _G.FlyEnabled,
    Callback = function(Value)
        _G.FlyEnabled = Value
        if Value then
            notify("✈️ ФЛАЙ ВКЛЮЧЕН", "Управление: Джойстик + Прыжок (вверх)", 3)
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
    Name = "Обновить список игроков",
    Callback = function()
        local players = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(players, player.Name)
            end
        end
        notify("🔄 ОБНОВЛЕНО", "Найдено игроков: " .. #players, 3)
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
                    notify("✅ ТЕЛЕПОРТАЦИЯ", "Телепортирован к игроку: " .. _G.SelectedPlayer, 3)
                end
            else
                notify("❌ ОШИБКА", "Игрок не найден или мертв!", 3)
            end
        else
            notify("❌ ОШИБКА", "Сначала выберите игрока!", 3)
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
notify("✅ СКРИПТ ЗАГРУЖЕН!", "Все функции активны! Удачной игры!", 5)
