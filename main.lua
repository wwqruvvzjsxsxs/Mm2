-- ========================================================
-- MM2 ULTIMATE HUB (ANDROID DELTA VERSION) - FULL FIXED
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
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

-- Глобальные переменные настроек
_G.RolesESP = true
_G.InnocentColor = Color3.fromRGB(0, 255, 0)
_G.ESPTransparency = 0.4
_G.GunESP = true
_G.GunHitboxEnabled = false
_G.GunHitboxSize = 10
_G.AntiKnifeHitbox = false
_G.AntiBulletHitbox = false
_G.AimbotEnabled = false
_G.AimbotSmoothness = 0.3

-- Автофарм настройки
_G.CoinTeleportFarm = false
_G.FarmSpeed = 20

_G.Invisibility = false
_G.AutoRejoin = true
_G.AntiAFK = true
_G.HitboxEnabled = false
_G.HitboxSize = 10
_G.HitboxTransparency = 0.7
_G.FPSBoostEnabled = false
_G.FakeName = ""
_G.PosterURL = ""
_G.PosterWidth = 4
_G.PosterHeight = 4
_G.Posters = {}
_G.SilentAim = false
_G.HitSoundEnabled = true
_G.HitSoundVolume = 1
_G.FlyEnabled = false
_G.FlyNoClip = false
_G.CustomCoinImage = ""

local MurdererColor = Color3.fromRGB(255, 0, 0)
local SheriffColor = Color3.fromRGB(0, 0, 255)
local PinkColor = Color3.fromRGB(255, 105, 180)
local activeHighlights = {}
local activeGunHighlight = nil

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

-- Обновление подсветки игрока
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

-- Подсветка выпавшего пистолета
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

-- Увеличение зоны подбора пистолета
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

-- Уменьшение хитбоксов ножа и пули
task.spawn(function()
    while true do
        task.wait(0.3)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local role = getMM2Role(player)
                
                if _G.AntiKnifeHitbox and role == "Murderer" then
                    local knife = char:FindFirstChild("Knife") or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife"))
                    if knife and knife:FindFirstChild("Handle") then
                        knife.Handle.Size = Vector3.new(0.01, 0.01, 0.01)
                    end
                end

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

-- Авто-наводка (Aimbot)
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

RunService.RenderStepped:Connect(function()
    if _G.AimbotEnabled and LocalPlayer.Character then
        local myChar = LocalPlayer.Character
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        local hrp = myChar:FindFirstChild("HumanoidRootPart")

        if hrp and hum and hum.Health > 0 then
            local target = getAimbotTarget()
            if target then
                local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.AimbotSmoothness)

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
-- МОДУЛЬ: ПРЯМОЙ АВТОФАРМ ПО МОНЕТАМ (Универсальный поиск)
-- ========================================================

RunService.Stepped:Connect(function()
    if _G.CoinTeleportFarm and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

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

task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.CoinTeleportFarm then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local foundCoin = nil
                
                -- Ищем любую монету напрямую по всему Workspace
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name == "Coin" then
                        local targetPart = nil
                        if obj:IsA("BasePart") then
                            targetPart = obj
                        elseif obj:IsA("Model") then
                            targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        end
                        
                        -- Проверяем, что монета видима и имеет валидную позицию
                        if targetPart and targetPart.Transparency < 1 and targetPart.Position.Y > -100 then
                            foundCoin = targetPart
                            break
                        end
                    end
                end

                if foundCoin then
                    -- Телепортируемся чуть выше монеты, чтобы не провалиться под карту
                    hrp.CFrame = foundCoin.CFrame + Vector3.new(0, 3, 0)
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    task.wait(0.25)
                else
                    task.wait(0.5)
                end
            end
        end
    end
end)

-- Anti-AFK & Server Invisibility
LocalPlayer.Idled:Connect(function()
    if _G.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

local function setInvisibility(state)
    _G.Invisibility = state
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local highlight = char:FindFirstChild("Self_Invis_Highlight")

    if state then
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

        for _, part in ipairs(char:GetDescendants()) do
            if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = 0.7
            end
        end

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

LocalPlayer.CharacterAdded:Connect(function()
    _G.Invisibility = false
end)

GuiService.ErrorMessageChanged:Connect(function()
    if _G.AutoRejoin then
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

-- Хитбокс Мардера
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

-- FPS Booster
local function applyFPSBoost()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("Atmosphere") then
            v.Enabled = false
        end
    end

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

task.spawn(function()
    while true do
        task.wait(1)
        if _G.FPSBoostEnabled then
            applyFPSBoost()
        end
    end
end)

-- Name Spooker
local function applyFakeName()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        if _G.FakeName ~= "" then
            char.Humanoid.DisplayName = _G.FakeName
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    applyFakeName()
end)

-- Custom Poster System
local function placePoster()
    local player = game.Players.LocalPlayer
    local rayOrigin = workspace.CurrentCamera.CFrame.Position
    local rayDirection = workspace.CurrentCamera.CFrame.LookVector * 50
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult and _G.PosterURL ~= "" then
        local posterPart = Instance.new("Part")
        posterPart.Size = Vector3.new(_G.PosterWidth, _G.PosterHeight, 0.1)
        posterPart.Anchored = true
        posterPart.CanCollide = false
        posterPart.Transparency = 1
        posterPart.CFrame = CFrame.new(raycastResult.Position + (raycastResult.Normal * 0.05), raycastResult.Position + raycastResult.Normal)
        posterPart.Parent = workspace
        
        local decal = Instance.new("Decal")
        decal.Texture = _G.PosterURL
        decal.Face = Enum.NormalId.Front
        decal.Parent = posterPart
        
        table.insert(_G.Posters, posterPart)
    end
end

-- Silent Aim
local function getMurderer()
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if p.Character:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife")) then
                return p.Character:FindFirstChild("HumanoidRootPart")
            end
        end
    end
    return nil
end

local mt = getrawmetatable(game)
local backup = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local name = getnamecallmethod()
    
    if _G.SilentAim and name == "FireServer" and args[1] == "Shoot" then
        local target = getMurderer()
        if target then
            args[2] = target.Position
            return backup(self, unpack(args))
        end
    end
    
    return backup(self, ...)
end)
setreadonly(mt, true)

-- Custom Hit Sounds
local function playCustomSound(soundId)
    if not _G.HitSoundEnabled then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = _G.HitSoundVolume
    sound.Parent = SoundService
    
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

workspace.ChildRemoved:Connect(function(child)
    if child.Name and child:FindFirstChild("Humanoid") then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character == child then
                if child.Humanoid.Health <= 0 then
                    playCustomSound("rbxassetid://6034953932")
                end
            end
        end
    end
end)

-- Fly + NoClip
task.spawn(function()
    local player = game.Players.LocalPlayer
    local runService = game:GetService("RunService")
    local bodyVel, bodyGyro
    local flyingSpeed = 50
    
    runService.RenderStepped:Connect(function()
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
            if bodyVel then bodyVel:Destroy() bodyVel = nil end
            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
            return
        end
        
        local hrp = character.HumanoidRootPart
        local humanoid = character.Humanoid
        
        if _G.FlyEnabled and _G.FlyNoClip then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        
        if _G.FlyEnabled then
            humanoid.PlatformStand = true
            
            if not bodyVel then
                bodyVel = Instance.new("BodyVelocity")
                bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVel.Parent = hrp
            end
            
            if not bodyGyro then
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bodyGyro.P = 10000
                bodyGyro.Parent = hrp
            end
            
            local camera = workspace.CurrentCamera
            local moveDir = humanoid.MoveDirection
            
            if moveDir.Magnitude > 0 then
                moveDir = camera.CFrame.LookVector * (humanoid.MoveDirection:Dot(camera.CFrame.LookVector) > 0 and 1 or -1) * math.abs(moveDir.Magnitude)
                
                if humanoid.MoveDirection.Z < 0 then
                    bodyVel.Velocity = camera.CFrame.LookVector * flyingSpeed
                else
                    bodyVel.Velocity = moveDir * flyingSpeed
                end
            else
                bodyVel.Velocity = Vector3.new(0, 0, 0)
            end
            
            bodyGyro.CFrame = camera.CFrame
        else
            humanoid.PlatformStand = false
            if bodyVel then bodyVel:Destroy() bodyVel = nil end
            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
        end
    end)
end)

-- Custom Coin PNG Textures
local function applyCoinTexture(coin)
    if _G.CustomCoinImage ~= "" then
        coin.Transparency = 1
        
        local bgui = coin:FindFirstChild("CustomCoinGui")
        if not bgui then
            bgui = Instance.new("BillboardGui")
            bgui.Name = "CustomCoinGui"
            bgui.Size = UDim2.new(2, 0, 2, 0)
            bgui.AlwaysOnTop = true
            
            local img = Instance.new("ImageLabel")
            img.Name = "CoinImage"
            img.Size = UDim2.new(1, 0, 1, 0)
            img.BackgroundTransparency = 1
            img.Image = _G.CustomCoinImage
            img.Parent = bgui
            
            bgui.Parent = coin
        else
            bgui.CoinImage.Image = _G.CustomCoinImage
        end
    else
        coin.Transparency = 0
        if coin:FindFirstChild("CustomCoinGui") then
            coin.CustomCoinGui:Destroy()
        end
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "Coin" and descendant:IsA("BasePart") then
        task.wait(0.1)
        if _G.CustomCoinImage ~= "" then
            applyCoinTexture(descendant)
        end
    end
end)

-- ========================================================
-- RAYFIELD UI INTERFACE
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
local PosterTab = Window:CreateTab("Граффити / Posters", 4483362458)
local MiscTab = Window:CreateTab("Разное / Misc", 4483362458)

-- Главная вкладка
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

MainTab:CreateToggle({
   Name = "Auto-guidance / Авто-наводка",
   CurrentValue = _G.AimbotEnabled,
   Callback = function(Value)
       _G.AimbotEnabled = Value
   end,
})

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

MainTab:CreateToggle({
   Name = "Auto-farm / Авто-сбор монет",
   CurrentValue = _G.CoinTeleportFarm,
   Callback = function(Value)
       _G.CoinTeleportFarm = Value
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

MainTab:CreateToggle({
   Name = "Флай / Fly",
   CurrentValue = _G.FlyEnabled,
   Callback = function(Value)
       _G.FlyEnabled = Value
   end,
})

MainTab:CreateToggle({
   Name = "Проходить сквозь стены (при полете) / Fly No-Clip",
   CurrentValue = _G.FlyNoClip,
   Callback = function(Value)
       _G.FlyNoClip = Value
   end,
})

MainTab:CreateToggle({
   Name = "Silent Aim (Убийство мардера сквозь стены)",
   CurrentValue = _G.SilentAim,
   Callback = function(Value)
       _G.SilentAim = Value
   end,
})

-- Вкладка Граффити
PosterTab:CreateInput({
   Name = "Ссылка на картинку / Poster URL",
   PlaceholderText = "rbxassetid://... или ссылка...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       _G.PosterURL = Text
   end,
})

PosterTab:CreateSlider({
   Name = "Ширина плаката / Poster Width",
   Range = {1, 20},
   Increment = 0.5,
   Suffix = "studs",
   CurrentValue = _G.PosterWidth or 4,
   Callback = function(Value)
       _G.PosterWidth = Value
   end,
})

PosterTab:CreateSlider({
   Name = "Высота плаката / Poster Height",
   Range = {1, 20},
   Increment = 0.5,
   Suffix = "studs",
   CurrentValue = _G.PosterHeight or 4,
   Callback = function(Value)
       _G.PosterHeight = Value
   end,
})

PosterTab:CreateButton({
   Name = "Повесить плакат / Place Poster",
   Callback = function()
       if placePoster then
           placePoster()
       end
   end,
})

PosterTab:CreateButton({
   Name = "Удалить все плакаты / Clear All Posters",
   Callback = function()
       if _G.Posters then
           for _, poster in pairs(_G.Posters) do
               poster:Destroy()
           end
           _G.Posters = {}
       end
   end,
})

-- Вкладка Разное
MiscTab:CreateDropdown({
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

MiscTab:CreateInput({
   Name = "Custom Coin PNG / Текстура монет",
   PlaceholderText = "rbxassetid://... или ссылка...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       _G.CustomCoinImage = Text
       for _, coin in ipairs(workspace:GetDescendants()) do
           if coin.Name == "Coin" and coin:IsA("BasePart") then
               applyCoinTexture(coin)
           end
       end
   end,
})

MiscTab:CreateInput({
   Name = "Fake Name / Фейковый ник",
   PlaceholderText = "Введите имя...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       _G.FakeName = Text
       local LocalPlayer = game.Players.LocalPlayer
       if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
           LocalPlayer.Character.Humanoid.DisplayName = Text
       end
   end,
})

MiscTab:CreateToggle({
   Name = "Invisibility / Невидимость",
   CurrentValue = _G.Invisibility,
   Callback = function(Value)
       if setInvisibility then
           setInvisibility(Value)
       end
   end,
})

MiscTab:CreateToggle({
   Name = "Auto-Rejoin / Авто перезаход",
   CurrentValue = _G.AutoRejoin,
   Callback = function(Value)
       _G.AutoRejoin = Value
   end,
})

MiscTab:CreateToggle({
   Name = "FPS Boost / Оптимизация ФПС",
   CurrentValue = _G.FPSBoostEnabled,
   Callback = function(Value)
       _G.FPSBoostEnabled = Value
       if Value and applyFPSBoost then
           applyFPSBoost()
       end
   end,
})

MiscTab:CreateToggle({
   Name = "Anti-AFK / Защита от AFK",
   CurrentValue = _G.AntiAFK,
   Callback = function(Value)
       _G.AntiAFK = Value
   end,
})

MiscTab:CreateToggle({
   Name = "Звук попадания / Килла (Hit Sound)",
   CurrentValue = _G.HitSoundEnabled,
   Callback = function(Value)
       _G.HitSoundEnabled = Value
   end,
})

MiscTab:CreateSlider({
   Name = "Громкость звука / Sound Volume",
   Range = {0.1, 2},
   Increment = 0.1,
   Suffix = "x",
   CurrentValue = _G.HitSoundVolume,
   Callback = function(Value)
       _G.HitSoundVolume = Value
   end,
})

Rayfield:LoadConfiguration()
