-- ========================================================
-- MM2 ULTIMATE HUB - ИСПРАВЛЕННАЯ ВЕРСИЯ (WITHOUT CRASH)
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
_G.GunESP = true
_G.GunColor = Color3.fromRGB(0, 0, 0)
_G.FlyEnabled = false
_G.FlySpeed = 50
_G.PhantomMode = false
_G.PhantomColor = Color3.fromRGB(255, 105, 180)
_G.AutoFarm = false
_G.FarmMode = "OnMap"
_G.FarmDelay = 0.5
_G.FarmHeight = -3
_G.HardAimEnabled = true
_G.AimTargetPart = "HumanoidRootPart"

-- Определение роли
local function getMM2Role(player)
    if not player then return "Innocent" end
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
        if obj:IsA("Tool") and isGunObject(obj) then
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
        task.wait(0.3)
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
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").PlatformStand = false
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
    flyBodyVelocity.Velocity = Vector3.zero
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
    
    if not flyBodyVelocity or not flyBodyGyro then startFly() end
    
    if flyBodyVelocity and flyBodyGyro then
        local camera = Workspace.CurrentCamera
        if not camera then return end
        
        local cameraForward = camera.CFrame.LookVector
        local cameraRight = camera.CFrame.RightVector
        local joyDirection = hum.MoveDirection
        local moveDirection = Vector3.zero
        
        if joyDirection.Z < 0 then moveDirection += cameraForward
        elseif joyDirection.Z > 0 then moveDirection -= cameraForward end
        
        if joyDirection.X > 0 then moveDirection += cameraRight
        elseif joyDirection.X < 0 then moveDirection -= cameraRight end
        
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
        if player ~= LocalPlayer and player.Character then
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
    
    if not teleportToSheriffOrMurderer() then
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
                    if selfHighlight then selfHighlight:Destroy() end
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
                end
            end
        end
    end)
end

local function deactivatePhantomMode()
    if phantomLoop then task.cancel(phantomLoop) phantomLoop = nil end
    if selfHighlight then selfHighlight:Destroy() selfHighlight = nil end
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth = 100 hum.Health = 100 end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.CanTouch = true
                part.CanQuery = true
            end
        end
    end
    notify("👁️ ФАНТОМ ВЫКЛЮЧЕН", "Вы снова обычный игрок!", 3)
end

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
    if farmBodyVelocity then farmBodyVelocity:Destroy() farmBodyVelocity = nil end
    if farmTween then farmTween:Cancel() farmTween = nil end
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
                notify("❌ ОШИБКА", "Вы не в игре!", 3)
                _G.AutoFarm = false
                disableFarmPhysics()
                continue
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
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                        enableUnderMapPhysics()
                        local targetPos = getUnderMapPosition(coin.Position)
                        local distance = (root.Position - targetPos).Magnitude
                        local tweenTime = math.clamp(distance / 40, 0.05, _G.FarmDelay)
                        
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
                        root.CFrame = CFrame.new(coin.Position.X, coin.Position.Y + _G.FarmHeight, coin.Position.Z)
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
-- УБИЙСТВО ВСЕХ
-- ========================================================
local function killAll()
    if getMM2Role(LocalPlayer) ~= "Murderer" then
        notify("❌ ОШИБКА", "Вы не Мардер!", 3)
        return
    end
    if not isInGame() then return end
    
    notify("💀 УБИЙСТВО ВСЕХ", "Убиваю всех игрока...", 3)
    task.wait(1.5)
    
    local killedCount = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local myChar = LocalPlayer.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
                if myHrp and targetHrp then
                    myHrp.CFrame = CFrame.new(targetHrp.Position + Vector3.new(0, 2, 0))
                end
                hum.Health = 0
                killedCount = killedCount + 1
                task.wait(0.1)
            end
        end
    end
    notify("✅ ПОБЕДА!", "Убито игроков: " .. killedCount, 5)
end

-- ========================================================
-- ОПТИМИЗИРОВАННЫЙ АИМБОТ НА МАРДЕРА (БЕЗ КРАШЕЙ)
-- ========================================================

-- Фоновое кеширование Мардера (раз в 0.5с)
local cachedMurderer = nil
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.HardAimEnabled then
            local found = nil
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and getMM2Role(player) == "Murderer" then
                        found = player
                        break
                    end
                end
            end
            cachedMurderer = found
        else
            cachedMurderer = nil
        end
    end
end)

local function snapAndShoot()
    if not _G.HardAimEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Pistol")
    if not gun then return end

    if cachedMurderer and cachedMurderer.Character then
        local targetPart = cachedMurderer.Character:FindFirstChild(_G.AimTargetPart) or cachedMurderer.Character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    end
end

UserInputService.TouchTapInWorld:Connect(function()
    snapAndShoot()
end)

-- Легковесный безопасный хук __namecall
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    -- Быстрая фильтрация метода до любых вычислений
    if _G.HardAimEnabled and not checkcaller() then
        if method == "Raycast" or method == "FindPartOnWithIgnoreList" or method == "findPartOnWithIgnoreList" then
            local char = LocalPlayer.Character
            if char and (char:FindFirstChild("Gun") or char:FindFirstChild("Pistol")) then
                if cachedMurderer and cachedMurderer.Character then
                    local targetPart = cachedMurderer.Character:FindFirstChild(_G.AimTargetPart) or cachedMurderer.Character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        local args = {...}
                        if method == "Raycast" and #args >= 2 then
                            args[2] = (targetPart.Position - args[1]).Unit * 1000
                            return oldNamecall(self, unpack(args))
                        elseif (method == "FindPartOnWithIgnoreList" or method == "findPartOnWithIgnoreList") and typeof(args[1]) == "Ray" then
                            args[1] = Ray.new(args[1].Origin, (targetPart.Position - args[1].Origin).Unit * 1000)
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end
            end
        end
    end

    return oldNamecall(self, ...)
end))

-- ========================================================
-- ИНТЕРФЕЙС
-- ========================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "MM2 Ultimate Hub",
    LoadingTitle = "MM2 Script",
    LoadingSubtitle = "Fixed Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local CombatTab = Window:CreateTab("⚔️ Сражение", 4483362458)
local VisualTab = Window:CreateTab("👁️ Визуализация", 4483362458)
local FarmTab = Window:CreateTab("🪙 Фарм", 4483362458)
local MiscTab = Window:CreateTab("🔧 Прочее", 4483362458)

CombatTab:CreateSection("Боевые функции")
CombatTab:CreateButton({
    Name = "💀 Убить всех",
    Callback = function() killAll() end,
})
CombatTab:CreateLabel("Убивает всех игроков на карте (только за Мардера)")

CombatTab:CreateSection("Аимбот")
CombatTab:CreateToggle({
    Name = "🎯 Жесткий аимбот на Мардера",
    CurrentValue = _G.HardAimEnabled,
    Callback = function(Value)
        _G.HardAimEnabled = Value
    end,
})

CombatTab:CreateDropdown({
    Name = "Часть тела для аимбота",
    Options = {"HumanoidRootPart", "Head"},
    CurrentOption = {"HumanoidRootPart"},
    MultipleOptions = false,
    Callback = function(Option)
        _G.AimTargetPart = Option[1]
    end,
})

VisualTab:CreateSection("ESP Настройки")
VisualTab:CreateToggle({
    Name = "👁️ ESP / Подсветка игроков",
    CurrentValue = _G.ESPEnabled,
    Callback = function(Value) _G.ESPEnabled = Value end,
})
VisualTab:CreateColorPicker({
    Name = "🎨 Цвет невинных игроков",
    Color = _G.InnocentColor,
    Callback = function(Value) _G.InnocentColor = Value end,
})

VisualTab:CreateSection("Оружие")
VisualTab:CreateToggle({
    Name = "🔫 Подсветка оружия",
    CurrentValue = _G.GunESP,
    Callback = function(Value) _G.GunESP = Value end,
})
VisualTab:CreateColorPicker({
    Name = "🎨 Цвет оружия",
    Color = _G.GunColor,
    Callback = function(Value) _G.GunColor = Value end,
})

VisualTab:CreateSection("Фантомный режим")
VisualTab:CreateToggle({
    Name = "👻 Фантомный призрак",
    CurrentValue = _G.PhantomMode,
    Callback = function(Value)
        _G.PhantomMode = Value
        if Value then
            if not isRoundActive() or not isInGame() then
                notify("❌ ОШИБКА", "Нельзя включить сейчас!", 3)
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
        if _G.PhantomMode and selfHighlight then selfHighlight.FillColor = Value end
    end,
})

FarmTab:CreateSection("Авто фарм")
FarmTab:CreateToggle({
    Name = "🪙 Авто фарм монет",
    CurrentValue = _G.AutoFarm,
    Callback = function(Value)
        _G.AutoFarm = Value
        if not Value then disableFarmPhysics() end
    end,
})
FarmTab:CreateDropdown({
    Name = "Режим фарма",
    Options = {"На карте", "Под картой"},
    CurrentOption = {"На карте"},
    MultipleOptions = false,
    Callback = function(Option)
        _G.FarmMode = (Option[1] == "На карте") and "OnMap" or "UnderMap"
        if _G.FarmMode == "OnMap" then disableFarmPhysics() end
    end,
})
FarmTab:CreateSlider({
    Name = "Скорость сборки монет",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "сек",
    CurrentValue = _G.FarmDelay,
    Callback = function(Value) _G.FarmDelay = Value end,
})
FarmTab:CreateSlider({
    Name = "Высота сбора монет",
    Range = {-10, 10},
    Increment = 0.5,
    Suffix = " блоков",
    CurrentValue = -3,
    Callback = function(Value) _G.FarmHeight = Value end,
})

MiscTab:CreateSection("Флай")
MiscTab:CreateToggle({
    Name = "✈️ Флай",
    CurrentValue = _G.FlyEnabled,
    Callback = function(Value)
        _G.FlyEnabled = Value
        if Value then startFly() else stopFly() end
    end,
})
MiscTab:CreateSlider({
    Name = "Скорость полета",
    Range = {20, 200},
    Increment = 10,
    CurrentValue = _G.FlySpeed,
    Callback = function(Value) _G.FlySpeed = Value end,
})

notify("✅ ИСПРАВЛЕННЫЙ СКРИПТ", "Аимбот оптимизирован!", 5)
