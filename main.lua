-- ========================================================
-- MM2 ULTIMATE HUB - ВЕРСИЯ С THUNDER HUB ФАРМОМ
-- ========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
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
_G.FarmHeight = -5.5

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
            -- ИСПРАВЛЕНО: Убран слеш перед тильдой
            if role ~= "Innocent" then
                return true
            end
        end
    end
    return false
end

-- Старый поиск монет (оставлен для функции Kill All)
local function getNearestCoin()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart
    local nearestCoin = nil
    local minDistance = 999999

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            if (name:find("coin") or name:find("монет")) and obj.Transparency < 0.9 then
                local dist = (root.Position - obj.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    nearestCoin = obj
                end
            end
        end
    end
    return nearestCoin
end

-- ========================================================
-- ESP ИГРОКИ
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
    -- ИСПРАВЛЕНО: Убран слеш перед тильдой
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
-- ESP ОРУЖИЕ
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
        highlight.Parent = gun:IsA("Model") and gun or gun.Parent
        activeGunHighlights[gun] = highlight
    end
end

task.spawn(function()
    while true do
        task.wait(0.25)
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
-- ФЛАЙ
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
            moveDirection = moveDirection + cameraForward
        elseif joyDirection.Z > 0 then
            moveDirection = moveDirection - cameraForward
        end
        
        if joyDirection.X > 0 then
            moveDirection = moveDirection + cameraRight
        elseif joyDirection.X < 0 then
            moveDirection = moveDirection - cameraRight
        end
        
        if moveDirection.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveDirection.Unit * _G.FlySpeed
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
-- ФАНТОМ
-- ========================================================
local phantomLoop = nil
local selfHighlight = nil

local function findSheriffOrMurderer()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        -- ИСПРАВЛЕНО: Убран слеш перед тильдой
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
-- АВТОФАРМ (МЕТОД THUNDER HUB + ПОДДЕРЖКА ПОД КАРТОЙ)
-- ========================================================

local isFarming = false
local farmPlatform = nil
local moveSpeed = 25 -- скорость движения (рекомендую 22-28)

-- Точный поиск монет (как в Thunder Hub)
local function findClosestCoin()
	local closestDist = math.huge
	local closestCoin = nil
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("CoinContainer") then
			for _, coin in ipairs(model.CoinContainer:GetChildren()) do
				if coin:IsA("BasePart") 
					and coin:FindFirstChild("TouchInterest") 
					and coin.Name == "Coin_Server" 
					and coin.Transparency < 0.9 then

					local dist = (root.Position - coin.Position).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestCoin = coin
					end
				end
			end
		end
	end
	return closestCoin
end

local function createFarmPlatform(root)
	if farmPlatform then
		farmPlatform:Destroy()
	end
	farmPlatform = Instance.new("Part")
	farmPlatform.Size = Vector3.new(6, 1, 6)
	farmPlatform.Anchored = true
	farmPlatform.CanCollide = false
	farmPlatform.Transparency = 1
	farmPlatform.Position = root.Position + Vector3.new(0, -3, 0)
	farmPlatform.Parent = Workspace
end

local function destroyFarmPlatform()
	if farmPlatform then
		farmPlatform:Destroy()
		farmPlatform = nil
	end
end

local function enableFarmPhysics()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end

	Workspace.Gravity = 0
	hum.PlatformStand = true
	hum.AutoRotate = false

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end

	createFarmPlatform(root)
end

local function disableFarmPhysics()
	Workspace.Gravity = originalGravity
	destroyFarmPlatform()

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
			end
		end
	end
end

-- Плавное перемещение к монете
local function moveToCoin(coin)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not coin then return false end

	local depth = (_G.FarmMode == "UnderMap") and _G.FarmHeight or -1
	local targetPos = coin.Position + Vector3.new(0, depth, 0)

	local startPos = root.Position
	local distance = (targetPos - startPos).Magnitude
	local duration = distance / moveSpeed
	local startTime = tick()

	while tick() - startTime < duration do
		if not _G.AutoFarm or not coin or not coin.Parent then
			return false
		end

		local alpha = math.min((tick() - startTime) / duration, 1)
		root.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		task.wait()
	end

	-- Финальная позиция + лежание
	root.CFrame = CFrame.new(targetPos) * CFrame.Angles(math.rad(90), 0, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	task.wait(0.12)

	-- Собираем монету
	pcall(function()
		coin:Destroy()
	end)

	return true
end

-- Главный цикл фарма
task.spawn(function()
	while true do
		task.wait(0.1)

		if _G.AutoFarm and isInGame() then
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")

			if root and hum and hum.Health > 0 then
				if not isFarming then
					isFarming = true
					enableFarmPhysics()
				end

				local coin = findClosestCoin()
				if coin then
					moveToCoin(coin)
				else
					-- Если монет нет — просто ждём
					task.wait(0.5)
				end
			else
				isFarming = false
				disableFarmPhysics()
			end
		else
			if isFarming then
				isFarming = false
				disableFarmPhysics()
			end
		end
	end
end)

-- ========================================================
-- УБИТЬ ВСЕХ
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
    -- ИСПРАВЛЕНО: Убран слеш перед тильдой
    if getMM2Role(LocalPlayer) ~= "Murderer" then
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

    notify("💀 УБИЙСТВО ВСЕХ", "Начинаю ликвидацию...", 3)

    local killedCount = 0
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        -- ИСПРАВЛЕНО: Убран слеш перед тильдой
        if player ~= LocalPlayer and player.Character then
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

    notify("✅ ГОТОВО!", "Ликвидировано: " .. killedCount, 5)
end

-- ========================================================
-- ИНТЕРФЕЙС
-- ========================================================
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    notify("❌ ОШИБКА", "Не удалось загрузить Rayfield!", 8)
    return
end

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
CombatTab:CreateLabel("Работает только если вы Мардер")

-- ВИЗУАЛИЗАЦИЯ
VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({
    Name = "👁️ ESP игроков",
    CurrentValue = false,
    Callback = function(Value)
        _G.ESPEnabled = Value
        notify(Value and "👁️ ESP ВКЛЮЧЕН" or "🚫 ESP ВЫКЛЮЧЕН", "", 3)
    end,
})
VisualTab:CreateColorPicker({
    Name = "Цвет невинных",
    Color = _G.InnocentColor,
    Callback = function(Value)
        _G.InnocentColor = Value
    end,
})

VisualTab:CreateSection("Оружие")
VisualTab:CreateToggle({
    Name = "🔫 Подсветка оружия",
    CurrentValue = false,
    Callback = function(Value)
        _G.GunESP = Value
        notify(Value and "🔫 Оружие ВКЛ" or "🚫 Оружие ВЫКЛ", "", 3)
    end,
})
VisualTab:CreateColorPicker({
    Name = "Цвет оружия",
    Color = _G.GunColor,
    Callback = function(Value)
        _G.GunColor = Value
    end,
})

VisualTab:CreateSection("Фантом")
VisualTab:CreateToggle({
    Name = "👻 Фантомный призрак",
    CurrentValue = false,
    Callback = function(Value)
        _G.PhantomMode = Value
        if Value then
            if not isRoundActive() or not isInGame() then
                notify("❌ ОШИБКА", "Раунд не начался или вы мертвы!", 3)
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
    Name = "Цвет себя",
    Color = _G.PhantomColor,
    Callback = function(Value)
        _G.PhantomColor = Value
    end,
})

-- ФАРМ
FarmTab:CreateSection("Авто фарм")
FarmTab:CreateToggle({
    Name = "🪙 Авто фарм монет",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoFarm = Value
        if Value then
            if not isInGame() then
                notify("❌ ОШИБКА", "Вы не в игре!", 3)
                _G.AutoFarm = false
                return
            end
            notify("🪙 ФАРМ ВКЛЮЧЕН", _G.FarmMode == "UnderMap" and "Под картой" or "На карте", 3)
        else
            disableFarmPhysics()
            notify("🚫 ФАРМ ВЫКЛЮЧЕН", "", 3)
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
        _G.FarmMode = (choice == "Под картой") and "UnderMap" or "OnMap"
        notify("🔄 Режим", choice, 3)
    end,
})

FarmTab:CreateSlider({
    Name = "Скорость сборки",
    Range = {0.1, 1.2},
    Increment = 0.05,
    Suffix = "сек",
    CurrentValue = 0.2,
    Callback = function(Value)
        _G.FarmDelay = Value
    end,
})

FarmTab:CreateSlider({
    Name = "Глубина (Под картой)",
    Range = {-8, -3.5},
    Increment = 0.2,
    Suffix = "",
    CurrentValue = -5.5,
    Callback = function(Value)
        _G.FarmHeight = Value
    end,
})

-- ПРОЧЕЕ
MiscTab:CreateSection("Флай")
MiscTab:CreateToggle({
    Name = "✈️ Флай",
    CurrentValue = false,
    Callback = function(Value)
        _G.FlyEnabled = Value
        if Value then
            startFly()
            notify("✈️ ФЛАЙ ВКЛЮЧЕН", "", 3)
        else
            stopFly()
            notify("🚫 ФЛАЙ ВЫКЛЮЧЕН", "", 3)
        end
    end,
})
MiscTab:CreateSlider({
    Name = "Скорость полёта",
    Range = {20, 180},
    Increment = 10,
    CurrentValue = 50,
    Callback = function(Value)
        _G.FlySpeed = Value
    end,
})

notify("✅ СКРИПТ ЗАГРУЖЕН", "Меню должно появиться", 5)
