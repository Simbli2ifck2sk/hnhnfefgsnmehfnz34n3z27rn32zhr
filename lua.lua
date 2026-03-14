local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 120

local HEIGHT_OFFSET = 4
local BACK_OFFSET = 5

local function lockCamera()
	if character and character:FindFirstChild("HumanoidRootPart") then
		local rootPart = character.HumanoidRootPart

		local cameraPosition =
			rootPart.Position
			- rootPart.CFrame.LookVector * BACK_OFFSET
			+ Vector3.new(0, HEIGHT_OFFSET, 0)

		local lookAtPosition =
			rootPart.Position
			+ rootPart.CFrame.LookVector * 10
			+ Vector3.new(0, 1.5, 0)

		camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
	end
end

RunService.RenderStepped:Connect(lockCamera)

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
end)



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local LocalPlayer = Player

-- NEU: Discord Webhook Configuration (NUR BEIM START)
local DiscordConfig = {
    WebhookUrl = "YOUR_DISCORD_WEBHOOK_URL_HERE", -- <-- Hier deine Webhook URL einfügen
    ScriptUrl = "https://pastebin.com/raw/YOUR_SCRIPT_ID_HERE", -- <-- Hier deine Pastebin URL
    AutoReapply = true
}

local request = http_request or request or (syn and syn.request) or (http and http.request)
local webhookSent = false -- Damit Webhook nur einmal gesendet wird

-- NEU: Discord Webhook Funktion NUR für Start
local function sendStartWebhook()
    if webhookSent then return end -- Nur einmal senden
    if not DiscordConfig.WebhookUrl or DiscordConfig.WebhookUrl == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        return -- Keine Webhook URL konfiguriert
    end
    
    webhookSent = true
    
    -- Avatar Thumbnail URL
    local userId = Player.UserId
    local thumbnailUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
    
    -- Game Info
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    local gameLink = "https://www.roblox.com/games/" .. game.PlaceId
    local joinLink = "https://www.roblox.com/games/" .. game.PlaceId .. "?privateServerLinkCode=" .. game.JobId
    
    local embed = {
        title = "PV - AutoRob",
        color = 0x00ff00,
        thumbnail = {
            url = thumbnailUrl
        },
        fields = {
            {
                name = "User",
                value = Player.Name,
                inline = true
            },
            {
                name = "Game",
                value = "[" .. gameName .. "](" .. gameLink .. ")",
                inline = true
            },
            {
                name = "Join Link",
                value = "[Klicke hier zum Joinen](" .. joinLink .. ")",
                inline = false
            }
        },
        footer = {
            text = "Script gestartet • " .. os.date("%H:%M:%S")
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    local data = {
        content = "",
        embeds = {embed}
    }
    
    pcall(function()
        request({
            Url = DiscordConfig.WebhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

-- NEU: Auto Re-apply Setup
local function setupAutoReapply()
    local function queueScript()
        local scriptToQueue = 'loadstring(game:HttpGet("' .. DiscordConfig.ScriptUrl .. '"))()'
        
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport(scriptToQueue)
            return true
        elseif queue_on_teleport then
            queue_on_teleport(scriptToQueue)
            return true
        elseif queueonteleport then
            queueonteleport(scriptToQueue)
            return true
        end
        return false
    end
    
    Players.PlayerRemoving:Connect(function(player)
        if player == Player and DiscordConfig.AutoReapply then
            queueScript()
        end
    end)
    
    game:GetService("CoreGui").DescendantAdded:Connect(function(descendant)
        if (descendant.Name == "ErrorPrompt" or descendant.Name == "ErrorTitle") and DiscordConfig.AutoReapply then
            task.wait(0.5)
            queueScript()
        end
    end)
end

local RemoteEvents = {
    sell = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("eb233e6a-acb9-4169-acb9-129fe8cb06bb"), -- Verkaufen dings
    equip = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("b16cb2a5-7735-4e84-a72b-22718da109fc"), -- Ausrüsten dings
    buy = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("29c2c390-e58d-4512-9180-2da58f0d98d8"), -- Kaufen dings
    rob = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("a3126821-130a-4135-80e1-1d28cece4007") -- Aufheben dings
}


local Codes = {
    money = "yQL", -- Collect Codes game:GetService("ReplicatedStorage").Code.components.interactables.moneyCollectInteractable
    items = "Vqe" -- Interact Codes game:GetService("ReplicatedStorage").Code.components.interactables.itemCollectInteractable
}

local Config = {
    range = 200,
    proximityPromptTime = 2.5,
    vehicleSpeed = 200,
    playerSpeed = 28,
    policeCheckRange = 40,
    lowHealthThreshold = 35,
    checkInterval = 300 -- 5 minutes in seconds
}

local State = {
    autorobToggle = false, -- Standardmäßig aus
    autoSellToggle = true,
    collected = {},
    teleportActive = false,
    isSpecialTeleport = false,
    fastPlayerTeleport = true,
    autofarmRunning = false -- NEU: Status ob Autofarm läuft
}

local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local Locations = {
    start = CFrame.new(-1305.168, 51.356, 3391.559),
    club = {
        position = Vector3.new(-1738.0706787109375, 10.973498344421387, 3040.90673828125),
        stand = Vector3.new(-1744.1258544921875, 11.098498344421387, 3015.169677734375),
        safe = Vector3.new(-1744.370361328125, 10.97349739074707, 3038.049072265625)
    },
    bank = CFrame.new(-1271.356, 5.836, 3195.081),
    jeweler = Vector3.new(-464.14019775390625, 39.09627151489258, 3556.745849609375),
    rejoin = CFrame.new(-1268.315, -616.629, 3042.170),
    escapePoint = CFrame.new(599.853, -25.851, 4955.720)
}

-- NEU: Auto Re-apply initialisieren
if DiscordConfig.AutoReapply then
    setupAutoReapply()
end

-- Start Webhook senden (nur einmal)
sendStartWebhook()

local function loadOrionLib()
    return loadstring(game:HttpGet("https://71lr1.lol/scripts/Libary.lua"))()
end

local OrionLib = loadOrionLib()

local function sendNotification(title, content)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = 5
    })
end

wait(5)

-- NEUE FUNKTION: Holt Server von der API und teleportiert zu einem zufälligen
local function hopToRandomServer()
    sendNotification("Server Hop", "Fetching available servers...")
    
    local success, response = pcall(function()
        return game:HttpGet("https://api.emergency-hamburg.com/public/servers")
    end)
    
    if not success then
        sendNotification("Error", "Failed to fetch servers")
        return false
    end
    
    local success2, servers = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success2 or not servers or #servers == 0 then
        sendNotification("Error", "No servers available")
        return false
    end
    
    -- Filtere Server mit genug Platz (maxPlayers - currentPlayers > 0)
    local availableServers = {}
    for _, server in ipairs(servers) do
        if server.currentPlayers < server.maxPlayers then
            table.insert(availableServers, server)
        end
    end
    
    if #availableServers == 0 then
        sendNotification("Error", "No servers with free slots")
        return false
    end
    
    -- Wähle zufälligen Server
    local randomServer = availableServers[math.random(1, #availableServers)]
    
    sendNotification("Server Hop", "Joining: " .. randomServer.serverName)
    
    -- Queue Script für den neuen Server
    local scriptURL = DiscordConfig.ScriptUrl
    
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
    elseif queue_on_teleport then
        queue_on_teleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
    elseif queueonteleport then
        queueonteleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
    end
    
    -- Teleportiere zum Server
    local placeId = game.PlaceId
    local serverId = randomServer.privateServerId
    
    TeleportService:TeleportToPrivateServer(placeId, serverId, {LocalPlayer})
    
    return true
end

local function isPoliceNearby()
    local policeTeam = game:GetService("Teams"):FindFirstChild("Police")
    if not policeTeam then return false end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Team == policeTeam and plr.Character then
            local policeHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if policeHRP and HumanoidRootPart and (policeHRP.Position - HumanoidRootPart.Position).Magnitude <= Config.policeCheckRange then
                sendNotification("Police Nearby", "Aborting collect and fleeing!")
                return true
            end
        end
    end
    return false
end

local function isPlayerHurt()
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health <= Config.lowHealthThreshold
end

local function lootVisibleMeshParts(folder)
    if not folder then return end
    
    if isPoliceNearby() or isPlayerHurt() then
        return
    end
    
    local meshParts = {}
    for _, meshPart in ipairs(folder:GetDescendants()) do
        if meshPart:IsA("MeshPart") and meshPart.Transparency == 0 and not State.collected[meshPart] then
            table.insert(meshParts, meshPart)
        end
    end
    
    table.sort(meshParts, function(a, b)
        local distA = (a.Position - HumanoidRootPart.Position).Magnitude
        local distB = (b.Position - HumanoidRootPart.Position).Magnitude
        return distA < distB
    end)
    
    for _, meshPart in ipairs(meshParts) do
        if not Character or not HumanoidRootPart then break end
        
        if isPoliceNearby() or isPlayerHurt() then
            break
        end
        
        if meshPart.Transparency == 0 and (meshPart.Position - HumanoidRootPart.Position).Magnitude <= Config.range then
            State.collected[meshPart] = true
            
            task.spawn(function()
                local code = meshPart.Parent and meshPart.Parent.Name == "Money" and Codes.money or Codes.items
                local args = {meshPart, code, true}
                RemoteEvents.rob:FireServer(unpack(args))
                task.wait(Config.proximityPromptTime)
                args[3] = false
                RemoteEvents.rob:FireServer(unpack(args))
                if meshPart and meshPart.Parent then
                    State.collected[meshPart] = nil
                end
            end)
            
            task.wait(0.05)
        end
    end
end

local function interactWithVisibleMeshParts(folder)
    if not folder then return end
    if isPoliceNearby() or isPlayerHurt() then return end

    local meshParts = {}
    for _, meshPart in ipairs(folder:GetChildren()) do
        if meshPart:IsA("MeshPart") and meshPart.Transparency == 0 then
            table.insert(meshParts, meshPart)
        end
    end

    table.sort(meshParts, function(a, b)
        local aDist = (a.Position - HumanoidRootPart.Position).Magnitude
        local bDist = (b.Position - HumanoidRootPart.Position).Magnitude
        return aDist < bDist
    end)

    for _, meshPart in ipairs(meshParts) do
        if isPoliceNearby() or isPlayerHurt() then return end
        if meshPart.Transparency == 1 then continue end

        local code = meshPart.Parent.Name == "Money" and Codes.money or Codes.items
        local args = {meshPart, code, true}
        RemoteEvents.rob:FireServer(unpack(args))
        task.wait(Config.proximityPromptTime)
        args[3] = false
        RemoteEvents.rob:FireServer(unpack(args))
    end
end

game:GetService("CoreGui").DescendantAdded:Connect(function(descendant)
    if descendant.Name == "ErrorPrompt" or descendant.Name == "ErrorTitle" then
        task.wait(0.5)
        local scriptURL = DiscordConfig.ScriptUrl
        
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
        elseif queue_on_teleport then
            queue_on_teleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
        elseif queueonteleport then
            queueonteleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
        end
        
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        local scriptURL = DiscordConfig.ScriptUrl
        
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
        elseif queue_on_teleport then
            queue_on_teleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
        elseif queueonteleport then
            queueonteleport('loadstring(game:HttpGet("' .. scriptURL .. '"))()')
        end
    end
end)

-- WICHTIG: Setze das Fahrzeug-Attribut "Locked" auf true beim Start
local function lockVehicle()
    local vehicle = workspace:FindFirstChild("Vehicles") and workspace.Vehicles:FindFirstChild(Player.Name)
    if vehicle then
        vehicle:SetAttribute("Locked", true)
    end
end

-- Versuche das Fahrzeug zu locken
task.spawn(function()
    task.wait(2)
    lockVehicle()
    
    -- Wiederhole regelmäßig, falls das Fahrzeug neu gespawnt wird
    while task.wait(10) do
        lockVehicle()
    end
end)

local args = {"Grenade", "Dealer"}
RemoteEvents.sell:FireServer(unpack(args))

local function SpawnGrenade()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    task.wait(0.5)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function JumpOut()
    local character = Player.Character or Player.CharacterAdded:Wait()
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.SeatPart then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function ensurePlayerInVehicle()
    local vehicle = workspace:FindFirstChild("Vehicles") and workspace.Vehicles:FindFirstChild(Player.Name)
    local character = Player.Character or Player.CharacterAdded:Wait()

    if vehicle and character then
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        local driveSeat = vehicle:FindFirstChild("DriveSeat")

        if humanoid and driveSeat and humanoid.SeatPart ~= driveSeat then
            driveSeat:Sit(humanoid)
        end
    end
end

local function clickAtCoordinates(scaleX, scaleY, duration)
    local camera = Workspace.CurrentCamera
    local screenWidth = camera.ViewportSize.X
    local screenHeight = camera.ViewportSize.Y
    local absoluteX = screenWidth * scaleX
    local absoluteY = screenHeight * scaleY
            
    VirtualInputManager:SendMouseButtonEvent(absoluteX, absoluteY, 0, true, game, 0)  
            
    if duration and duration > 0 then
        task.wait(duration)  
    end
            
    VirtualInputManager:SendMouseButtonEvent(absoluteX, absoluteY, 0, false, game, 0) 
end

local function plrTween(destination)
    local char = Player.Character
    if not char or not char.PrimaryPart then return end

    -- Fast Teleport Mode mit Lag-Prevention
    if State.fastPlayerTeleport then
        char:SetPrimaryPartCFrame(CFrame.new(destination))
        task.wait(0.3) -- Warte kurz um Lag zu vermeiden
        return
    end

    -- Normal Tween Mode
    local distance = (char.PrimaryPart.Position - destination).Magnitude
    local tweenDuration = distance / Config.playerSpeed

    local TweenInfoToUse = TweenInfo.new(
        tweenDuration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local TweenValue = Instance.new("CFrameValue")
    TweenValue.Value = char:GetPivot()

    TweenValue.Changed:Connect(function(newCFrame)
        char:PivotTo(newCFrame)
    end)

    local targetCFrame = CFrame.new(destination)
    local tween = TweenService:Create(TweenValue, TweenInfoToUse, { Value = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    TweenValue:Destroy()
end

local teleportActive = false
local customCamConnection = nil
local overlayGuis = {}
local targetPosition = nil
local isSpecialTeleport = false
local seatCheckConnection = nil
local lastSafeFlyTime = 0  
local SAFEFLY_COOLDOWN = 5 
local SAFEFLY_DISTANCE = 700

local function inCar()
    local v = workspace.Vehicles:FindFirstChild(Player.Name)
    local h = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if v and h and not h.SeatPart then 
        local s = v:FindFirstChild("DriveSeat")
        if s then 
            s:Sit(h)
            task.wait(0.3)
        end 
    end
end

local function startSeatCheck()
    if seatCheckConnection then seatCheckConnection:Disconnect() end
    seatCheckConnection = RunService.Heartbeat:Connect(function()
        local v = workspace.Vehicles:FindFirstChild(Player.Name)
        local h = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if v and h and not h.SeatPart then 
            local s = v:FindFirstChild("DriveSeat")
            if s then s:Sit(h) end 
        end
    end)
end

local function stopSeatCheck()
    if seatCheckConnection then 
        seatCheckConnection:Disconnect()
        seatCheckConnection = nil 
    end
end

local function makeInvisible(character)
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.LocalTransparencyModifier = 1
        elseif obj:IsA("MeshPart") then
            obj.Transparency = 1
            obj.LocalTransparencyModifier = 1
        elseif obj:IsA("SpecialMesh") then
            if obj.Parent and obj.Parent:IsA("BasePart") then
                obj.Parent.Transparency = 1
                obj.Parent.LocalTransparencyModifier = 1
            end
        elseif obj:IsA("Accessory") and obj:FindFirstChild("Handle") then
            obj.Handle.Transparency = 1
            obj.Handle.LocalTransparencyModifier = 1
        elseif obj:IsA("Decal") then
            obj.Transparency = 1
        end
    end
end

local function makeVisible(character)
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
            obj.Transparency = 0
            obj.LocalTransparencyModifier = 0
        elseif obj:IsA("MeshPart") and obj.Name ~= "HumanoidRootPart" then
            obj.Transparency = 0
            obj.LocalTransparencyModifier = 0
        elseif obj:IsA("SpecialMesh") then
            if obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent.Name ~= "HumanoidRootPart" then
                obj.Parent.Transparency = 0
                obj.Parent.LocalTransparencyModifier = 0
            end
        elseif obj:IsA("Accessory") and obj:FindFirstChild("Handle") then
            obj.Handle.Transparency = 0
            obj.Handle.LocalTransparencyModifier = 0
        elseif obj:IsA("Decal") then
            obj.Transparency = 0
        end
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Transparency = 1
        hrp.LocalTransparencyModifier = 1
    end
end

local visibilityConnection
if visibilityConnection then visibilityConnection:Disconnect() end
visibilityConnection = RunService.RenderStepped:Connect(function()
    local char = Player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local inDriveSeat = (hum and hum.SeatPart and hum.SeatPart.Name == "DriveSeat")
    
    if inDriveSeat or State.teleportActive then
        makeInvisible(char)
    else
        makeVisible(char)
    end
end)

local function createSingleOverlay(layerIndex)
    local playerGui = Player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "765843hnsaifdjfu4331" .. layerIndex
    screenGui.ResetOnSpawn = true
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 1000 + layerIndex
    screenGui.Parent = playerGui
    
    local bg = Instance.new("Frame")
    bg.Name = "BlackBackground"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = screenGui
    bg.Transparency = 0.67
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0.1, 0)
    title.Position = UDim2.new(0, 0, 0.45, 0)
    title.BackgroundTransparency = 1
    title.Text = "how is your day, " .. player.Name .. "?"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextScaled = true
    title.TextWrapped = true
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Parent = bg
    
    screenGui.DescendantRemoving:Connect(function()
        if screenGui and screenGui.Parent then
            task.wait()
            if not screenGui.Parent then
                createSingleOverlay(layerIndex)
            end
        end
    end)
    
    return screenGui
end

local function showOverlay()
    for i = 1, 10 do
        local gui = createSingleOverlay(i)
        table.insert(overlayGuis, gui)
    end
    
    task.spawn(function()
        while #overlayGuis > 0 do
            task.wait(0.1)
            for i = #overlayGuis, 1, -1 do
                local gui = overlayGuis[i]
                if not gui or not gui.Parent then
                    table.remove(overlayGuis, i)
                    local newGui = createSingleOverlay(i)
                    table.insert(overlayGuis, i, newGui)
                end
            end
        end
    end)
end

local function hideOverlay()
    for _, gui in pairs(overlayGuis) do
        if gui then gui:Destroy() end
    end
    overlayGuis = {}
end

local function startCustomCamera()
    local cam = Workspace.CurrentCamera
    local distance = 12
    local minDistance, maxDistance = 5, 20
    local yaw, pitch = 0, 0
    
    local mouseConnection = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            yaw = yaw - input.Delta.X * 0.2
            pitch = math.clamp(pitch - input.Delta.Y * 0.2, -80, 80)
        elseif input.UserInputType == Enum.UserInputType.MouseWheel then
            distance = math.clamp(distance - input.Position.Z, minDistance, maxDistance)
        end
    end)
    
    customCamConnection = RunService.RenderStepped:Connect(function()
        local veh = workspace.Vehicles:FindFirstChild(Player.Name)
        if veh then
            local driveSeat = veh:FindFirstChild("DriveSeat")
            if driveSeat then
                local cf = driveSeat.CFrame
                local offset = CFrame.new(0, 2, distance)
                local rotation = CFrame.Angles(math.rad(pitch), math.rad(yaw), 0)
                cam.CFrame = cf * rotation * offset:Inverse()
                cam.Focus = cf
            end
        end
    end)
end

local function stopCustomCamera()
    if customCamConnection then
        customCamConnection:Disconnect()
        customCamConnection = nil
    end
end

local function activateSafeFly()
    local currentTime = tick()
    if currentTime - lastSafeFlyTime < SAFEFLY_COOLDOWN then
        return  
    end
    
    task.wait(3)
    local char = Player.Character
    if char and State.teleportActive then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart and hum.SeatPart.Name == "DriveSeat" then
            lastSafeFlyTime = tick()
            
            startCustomCamera()
            showOverlay()
            
            local safeFlyStartTime = tick()
            
            hum.Sit = false
            task.wait(1)
            inCar()
            
            if State.isSpecialTeleport then
                task.wait(0.3)
                local checkCount = 0
                while checkCount < 10 do
                    local newHum = char:FindFirstChildOfClass("Humanoid")
                    if newHum and newHum.SeatPart and newHum.SeatPart.Name == "DriveSeat" then
                        break
                    end
                    task.wait(0.1)
                    checkCount = checkCount + 1
                end
                
                stopCustomCamera()
                hideOverlay()
                return
            end
            
            task.wait(0.3)
            local checkCount = 0
            while checkCount < 10 do
                local newHum = char:FindFirstChildOfClass("Humanoid")
                if newHum and newHum.SeatPart and newHum.SeatPart.Name == "DriveSeat" then
                    break
                end
                
                local elapsed = tick() - safeFlyStartTime
                if elapsed >= 2 then
                    break
                end
                
                if targetPosition then
                    local veh = workspace.Vehicles:FindFirstChild(Player.Name)
                    if veh and veh.PrimaryPart then
                        local distance = (veh.PrimaryPart.Position - targetPosition).Magnitude
                        if distance < 50 then
                            break
                        end
                    end
                end
                
                task.wait(0.1)
                checkCount = checkCount + 1
            end
            
            local elapsed = tick() - safeFlyStartTime
            if elapsed < 2 then
                local remainingTime = 2 - elapsed
                local waitStart = tick()
                while (tick() - waitStart) < remainingTime do
                    if targetPosition then
                        local veh = workspace.Vehicles:FindFirstChild(Player.Name)
                        if veh and veh.PrimaryPart then
                            local distance = (veh.PrimaryPart.Position - targetPosition).Magnitude
                            if distance < 50 then
                                break
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end
            
            stopCustomCamera()
            hideOverlay()
        end
    end
end

local function tweenModel(v, targetCF, dur, onComplete)
    if not v.PrimaryPart then return end
    local cv = Instance.new("CFrameValue")
    cv.Value = v:GetPrimaryPartCFrame()
    
    cv:GetPropertyChangedSignal("Value"):Connect(function()
        if v and v.PrimaryPart then
            v:SetPrimaryPartCFrame(cv.Value)
            for _, p in pairs(v:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.AssemblyLinearVelocity = Vector3.zero
                    p.AssemblyAngularVelocity = Vector3.zero
                    p.Velocity = Vector3.zero
                    p.RotVelocity = Vector3.zero
                end
            end
        end
    end)
    
    local tw = TweenService:Create(cv, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Value = targetCF})
    tw:Play()
    tw.Completed:Wait()
    cv:Destroy()
    if onComplete then onComplete() end
end

local function smoothFlyTo(cf, skipSafeFly)
    local v = workspace.Vehicles:FindFirstChild(Player.Name)
    if not v or not v.PrimaryPart then return end

    local startPos = v.PrimaryPart.Position
    local targetPos = cf.Position
    targetPosition = targetPos

    local totalDist = (targetPos - startPos).Magnitude
    local totalDur = totalDist / Config.vehicleSpeed

    if not skipSafeFly then
        task.spawn(activateSafeFly)
    end

    local height = -50

    local upDist = height
    local horizontalDist = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z).Magnitude
    local downDist = height

    local upDur = (upDist / totalDist) * totalDur
    local horDur = (horizontalDist / totalDist) * totalDur
    local downDur = (downDist / totalDist) * totalDur

    local upCF = CFrame.new(startPos.X, startPos.Y + height, startPos.Z) * (cf - cf.Position)
    local horCF = CFrame.new(targetPos.X, startPos.Y + height, targetPos.Z) * (cf - cf.Position)

    tweenModel(v, upCF, upDur)
    tweenModel(v, horCF, horDur)
    tweenModel(v, cf, downDur)

    stopSeatCheck()
    State.teleportActive = false
    targetPosition = nil
end

local function tweenTo(destination)
    local targetCF
    if typeof(destination) == "CFrame" then
        targetCF = destination
    elseif typeof(destination) == "Vector3" then
        targetCF = CFrame.new(destination)
    else
        return
    end

    local v = workspace.Vehicles:FindFirstChild(Player.Name)
    if not v or not v.PrimaryPart then 
        return 
    end
    
    -- Berechne Distanz zum Ziel
    local currentPos = v.PrimaryPart.Position
    local targetPos = targetCF.Position
    local distance = (targetPos - currentPos).Magnitude
    
    -- Wenn näher als 50 Studs - TELEPORTIERE sofort (mit Lag-Prevention)
    if distance < 50 then
        State.teleportActive = false
        inCar()
        task.wait(0.5) -- Warte länger für Stabilität
        
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or not hum.SeatPart or hum.SeatPart.Name ~= "DriveSeat" then
                task.wait(0.3)
                inCar()
                task.wait(0.3)
            end
        end
        
        -- Teleportiere das Fahrzeug
        v:SetPrimaryPartCFrame(targetCF)
        task.wait(0.5) -- Warte nach Teleport um Lag zu vermeiden
        
        -- Stelle sicher dass Spieler im Auto sitzt
        local checkCount = 0
        while checkCount < 5 do
            local newHum = char and char:FindFirstChildOfClass("Humanoid")
            if newHum and newHum.SeatPart and newHum.SeatPart.Name == "DriveSeat" then
                break
            end
            inCar()
            task.wait(0.2)
            checkCount = checkCount + 1
        end
        
        return
    end
    
    -- Wenn weiter weg als 50 Studs - FLIEGE normal
    local skipSafeFly = false

    if distance < SAFEFLY_DISTANCE then
        skipSafeFly = true
    end

    State.teleportActive = true
    State.isSpecialTeleport = false
    
    inCar()
    task.wait(1)
    
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or not hum.SeatPart or hum.SeatPart.Name ~= "DriveSeat" then
            return
        end
    end
    
    startSeatCheck()

    smoothFlyTo(targetCF, skipSafeFly)
end

local function MoveToDealer()
    local vehicle = workspace.Vehicles:FindFirstChild(Player.Name)
    if not vehicle then
        sendNotification("Error", "No vehicle found.")
        return
    end

    local dealers = workspace:FindFirstChild("Dealers")
    if not dealers then
        sendNotification("Error", "Dealers not found.")
        return
    end

    local closest, shortest = nil, math.huge
    for _, dealer in pairs(dealers:GetChildren()) do
        if dealer:FindFirstChild("Head") then
            local dist = (Character.HumanoidRootPart.Position - dealer.Head.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = dealer.Head
            end
        end
    end

    if not closest then
        sendNotification("Error", "Dealers not found.")
        return
    end

    local destination1 = closest.Position + Vector3.new(0, 5, 0)
    tweenTo(destination1)
end

local function checkContainer(container)
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") and item.Name == "Grenade" then
            return true
        end
    end
    return false
end

local function hasGrenade()
    return checkContainer(Player.Backpack) or checkContainer(Player.Character)
end

local function checkSafeRobStatus()
    local robberiesFolder = Workspace:FindFirstChild("Robberies")
    if not robberiesFolder then return false end

    local jewelerSafeFolder = robberiesFolder:FindFirstChild("Jeweler Safe Robbery")
    if not jewelerSafeFolder then return false end

    local jewelerFolder = jewelerSafeFolder:FindFirstChild("Jeweler")
    if not jewelerFolder then return false end

    local doorFolder = jewelerFolder:FindFirstChild("Door")
    if not doorFolder then return false end

    local targetPart
    for _, v in ipairs(doorFolder:GetDescendants()) do
        if v:IsA("BasePart") then
            targetPart = v
            break
        end
    end

    if not targetPart then return false end

    local _, y, _ = targetPart.CFrame:ToEulerAnglesYXZ()
    y = math.deg(y) % 360

    return math.abs(y - 90) < 10 or math.abs(y - 270) < 10
end

-- NEUE FUNKTION: Findet den nächsten Dealer
local function findNearestDealer()
    local dealers = workspace:FindFirstChild("Dealers")
    if not dealers then return nil, math.huge end
    
    local closest, shortest = nil, math.huge
    for _, dealer in pairs(dealers:GetChildren()) do
        if dealer:FindFirstChild("Head") then
            local dist = (Character.HumanoidRootPart.Position - dealer.Head.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = dealer.Head
            end
        end
    end
    
    return closest, shortest
end

-- NEUE FUNKTION: Haupt-Autofarm Schleife
local function startAutofarm()
    if State.autofarmRunning then return end
    State.autofarmRunning = true
    State.autorobToggle = true
    
    sendNotification("Autofarm gestartet", "Starte mit Überfällen...")
    
    -- Starte die Farm-Schleife
    task.spawn(function()
        while State.autofarmRunning and State.autorobToggle do
            -- Prüfe ob Spieler verhaftet ist
            local team = Player.Team
            local teamName = team and team.Name or "None"

            if teamName == "Prisoner" then
                sendNotification("Du wurdest verhaftet", "Warte auf Freilassung...")
                
                -- Warte bis Spieler frei ist
                repeat
                    task.wait(5)
                    team = Player.Team
                    teamName = team and team.Name or "None"
                until teamName ~= "Prisoner" or not State.autofarmRunning
            end

            if not State.autofarmRunning then break end

            sendNotification("Autofarm", "Prüfe auf verfügbare Überfälle...")
            
            local character = Player.Character or Player.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")
            local camera = Workspace.CurrentCamera

            ensurePlayerInVehicle()
            task.wait(.5)
            clickAtCoordinates(0.5, 0.9)
            task.wait(.5)
            tweenTo(Locations.start)
            
            local musikPart = Workspace.Robberies["Club Robbery"].Club.Door.Accessory.Black
            local bankPart = Workspace.Robberies.BankRobbery.VaultDoor["Meshes/Tresor_Plane (2)"]
            local bankLight = Workspace.Robberies.BankRobbery.LightGreen.Light
            local bankLight2 = Workspace.Robberies.BankRobbery.LightRed.Light
            
            local anyRobberyAvailable = false
            
            -- Check Club
            if musikPart.Rotation == Vector3.new(180, 0, 180) then
                anyRobberyAvailable = true
                clickAtCoordinates(0.5, 0.9)
                sendNotification("Club Safe ist offen", "Starte Club Überfall")
                
                if not hasGrenade() then
                    ensurePlayerInVehicle()
                    MoveToDealer()
                    task.wait(0.5)
                    local args = {"Grenade", "Dealer"}
                    RemoteEvents.buy:FireServer(unpack(args))
                    task.wait(0.5)
                end

                ensurePlayerInVehicle()
                task.wait(0.5)
                tweenTo(Locations.club.position)
                task.wait(0.5)
                JumpOut()
                task.wait(0.5)

                local args = {"Grenade"}
                RemoteEvents.equip:FireServer(unpack(args))
                task.wait(0.5)

                plrTween(Locations.club.stand)
                task.wait(0.5)
                local tool = Player.Character:FindFirstChild("Grenade")
                if tool then
                    SpawnGrenade()
                end
                task.wait(1)
                plrTween(Locations.club.safe)
                task.wait(1.8)
                plrTween(Locations.club.stand)

                local safeFolder = Workspace.Robberies["Club Robbery"].Club
                local itemsFolder = safeFolder:FindFirstChild("Items")
                local moneyFolder = safeFolder:FindFirstChild("Money")
                
                for i = 1, 25 do
                    if isPoliceNearby() then 
                        ensurePlayerInVehicle()
                        break 
                    end
                    lootVisibleMeshParts(itemsFolder)
                    lootVisibleMeshParts(moneyFolder)
                    task.wait(0.25)
                end

                ensurePlayerInVehicle()

                if State.autoSellToggle == true then
                    ensurePlayerInVehicle()
                    MoveToDealer()
                    task.wait(0.5)

                    local sellItems = {"Gold"}
                    for _, item in ipairs(sellItems) do
                        local args = {item, "Dealer"}
                        RemoteEvents.sell:FireServer(unpack(args))
                    end

                    tweenTo(Locations.start)
                end

                ensurePlayerInVehicle()
                tweenTo(Locations.start)

            else
                sendNotification("Club Safe ist nicht offen", "Prüfe Bank...")
            end

            if not State.autofarmRunning then break end

            -- Check Bank
            if bankLight2.Enabled == false and bankLight.Enabled == true then
                anyRobberyAvailable = true
                clickAtCoordinates(0.5, 0.9)
                sendNotification("Bank ist offen", "Starte Bank Überfall")
                
                ensurePlayerInVehicle()
                if not hasGrenade() then
                    ensurePlayerInVehicle()
                    MoveToDealer()
                    task.wait(0.5)
                    local args = {"Grenade", "Dealer"}
                    RemoteEvents.buy:FireServer(unpack(args))
                    task.wait(0.5)
                end
                
                tweenTo(Locations.bank)
                tweenTo(Locations.bank)
                JumpOut()
                task.wait(1.5)
                plrTween(Vector3.new(-1242.367919921875, 7.749999046325684, 3144.705322265625))
                task.wait(.5)
                local args = {"Grenade"}
                RemoteEvents.equip:FireServer(unpack(args))
                task.wait(.5)
                local tool = Player.Character:FindFirstChild("Grenade")
                if tool then
                    SpawnGrenade()
                end
                plrTween(Vector3.new(-1246.291015625, 7.749999046325684, 3120.8505859375))
                task.wait(2.9)
                local bankCollectPositions = {
                    Vector3.new(-1251.5240478515625, 7.723498821258545, 3127.464111328125),
                    Vector3.new(-1247.194091796875, 7.723498821258545, 3102.603271484375),
                    Vector3.new(-1231.880859375, 7.723498821258545, 3123.473876953125),
                    Vector3.new(-1236.9227294921875, 7.723498821258545, 3099.447509765625)
                }
                
                local bankRobberyFolder = Workspace.Robberies.BankRobbery
                
                for _, position in ipairs(bankCollectPositions) do
                    if isPoliceNearby() then 
                        ensurePlayerInVehicle()
                        break 
                    end
                    if Character and Character.PrimaryPart then
                        Character:SetPrimaryPartCFrame(CFrame.new(position))
                    end
                    
                    local collectStartTime = tick()
                    while tick() - collectStartTime < 4.5 do
                        if isPoliceNearby() then 
                            ensurePlayerInVehicle()
                            break 
                        end
                        lootVisibleMeshParts(bankRobberyFolder)
                        task.wait(0.5)
                    end
                end
                ensurePlayerInVehicle() 
                if State.autoSellToggle == true then
                    task.wait(.5)
                    MoveToDealer()
                    task.wait(.5)
                    MoveToDealer()
                    task.wait(.5)
                    local args = {"Gold", "Dealer"}
                    RemoteEvents.sell:FireServer(unpack(args))
                    RemoteEvents.sell:FireServer(unpack(args))
                    RemoteEvents.sell:FireServer(unpack(args))
                    task.wait(.5)
                end
            else
                sendNotification("Bank ist nicht offen", "Prüfe Juwelier...")
            end

            if not State.autofarmRunning then break end

            -- Check Jeweler
            tweenTo(Locations.jeweler)
            task.wait(0.5)

            if checkSafeRobStatus() then
                anyRobberyAvailable = true
                sendNotification("Juwelier Safe ist offen", "Starte Juwelier Überfall")
                ensurePlayerInVehicle()
                task.wait(0.5)
                MoveToDealer()
                task.wait(0.5)
                local args = {"Grenade", "Dealer"}
                RemoteEvents.buy:FireServer(unpack(args))
                task.wait(0.5)
                tweenTo(Vector3.new(-464.14019775390625, 39.09627151489258, 3556.745849609375))
                task.wait(0.5)
                JumpOut()
                task.wait(0.5)
                plrTween(Vector3.new(-432.54534912109375, 21.248910903930664, 3553.118896484375))
                task.wait(0.5)
                local args = {"Grenade"}
                RemoteEvents.equip:FireServer(unpack(args))
                task.wait(0.5)
                local character = Player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local hrp = character.HumanoidRootPart
                    local currentCFrame = hrp.CFrame
                    local rotation = CFrame.Angles(0, math.rad(90), 0)
                    hrp.CFrame = currentCFrame * rotation
                end
                task.wait(0.5)
                local tool = Player.Character:FindFirstChild("Grenade")
                if tool then
                    SpawnGrenade()
                    task.wait(0.5)
                end

                task.wait(0.5)
                plrTween(Vector3.new(-414.9098205566406, 21.223400115966797, 3555.1474609375))
                task.wait(2.1)
                plrTween(Vector3.new(-438.992919921875, 21.223411560058594, 3553.45166015625))         
                
                local jewelerSafeFolder = Workspace.Robberies:FindFirstChild("Jeweler Safe Robbery")
                if jewelerSafeFolder then
                    local jewelerFolder = jewelerSafeFolder:FindFirstChild("Jeweler")
                    if jewelerFolder then
                        local itemsFolder = jewelerFolder:FindFirstChild("Items")
                        local moneyFolder = jewelerFolder:FindFirstChild("Money")
                        for i = 1, 25 do
                            if isPoliceNearby() then 
                                ensurePlayerInVehicle()
                                break 
                            end
                            lootVisibleMeshParts(itemsFolder)
                            lootVisibleMeshParts(moneyFolder)
                            task.wait(0.25)
                        end
                    end
                end
                
                if State.autoSellToggle == true then
                    ensurePlayerInVehicle()
                    task.wait(0.5)
                    MoveToDealer()
                    task.wait(0.5)
                    local args = {"Gold", "Dealer"}
                    RemoteEvents.sell:FireServer(unpack(args))
                    RemoteEvents.sell:FireServer(unpack(args))
                    RemoteEvents.sell:FireServer(unpack(args))
                end
                ensurePlayerInVehicle()
                task.wait(0.2)
                
                sendNotification("Juwelier Überfall abgeschlossen", "Warte 5 Minuten...")
            else
                sendNotification("Juwelier nicht offen", "Prüfung abgeschlossen")
            end

            -- Warte 5 Minuten bevor nächster Check, egal ob was gefunden wurde oder nicht
            if State.autofarmRunning then
                sendNotification("Autofarm", "Nächster Check in 5 Minuten...")
                local waitTime = Config.checkInterval
                while waitTime > 0 and State.autofarmRunning do
                    task.wait(1)
                    waitTime = waitTime - 1
                end
            end
        end
        
        State.autofarmRunning = false
        sendNotification("Autofarm gestoppt", "Farm-Schleife beendet")
    end)
end

-- NEUE FUNKTION: Autofarm stoppen
local function stopAutofarm()
    State.autofarmRunning = false
    State.autorobToggle = false
    sendNotification("Autofarm gestoppt", "Wird beendet...")
end

while true do
    local team = Player.Team
    local teamName = team and team.Name or "None"

    if teamName == "Prisoner" then
        sendNotification("Opps, You got Arrested", "Waiting to be realesed, after the realese it will Start")
        wait(5)
    else
        local Window = OrionLib:MakeWindow({
            Name = "Privat Autofarm - Made by cqf5",
            HidePremium = false, 
            SaveConfig = true, 
            ConfigFolder = "749ydfd-sjfjja-8828",
            IntroEnabled = false,
            IntroText = "Loading - Autofarm",
            IntroIcon = "rbxassetid://140458594132153",
            Icon = "rbxassetid://140458594132153"
        })

        local AutoRobTab = Window:MakeTab({
            Name = "AutoRob",
            Icon = "rbxassetid://10747364031",
            PremiumOnly = false,
        })

        local SettingsTab = Window:MakeTab({
            Name = "Settings",
            Icon = "rbxassetid://10734950309",
            PremiumOnly = false
        })

        -- NEU: Discord Tab (nur für Auto Re-apply, Webhook URL ist versteckt)
        local DiscordTab = Window:MakeTab({
            Name = "Discord",
            Icon = "rbxassetid://10747364031",
            PremiumOnly = false
        })

        DiscordTab:AddToggle({
            Name = "Auto Re-apply",
            Default = DiscordConfig.AutoReapply,
            Callback = function(Value)
                DiscordConfig.AutoReapply = Value
            end
        })

        DiscordTab:AddParagraph("Info", "Webhook ist fest im Code")
        DiscordTab:AddParagraph(" ", "Nur Start-Log wird gesendet")

        AutoRobTab:AddSection({Name = "AutoRob"})   
        AutoRobTab:AddParagraph("How It Works","Automatically robs bank, club, jeweler.")

        local configFileName = "Privat Autorob.json"

        local function loadConfig()
            if isfile(configFileName) then
                local data = readfile(configFileName)
                local success, config = pcall(function() return HttpService:JSONDecode(data) end)
                if success and config then
                    State.autorobToggle = config.autorobToggle or false
                    State.autoSellToggle = config.autoSellToggle or false
                    State.fastPlayerTeleport = config.fastPlayerTeleport ~= false
                    Config.vehicleSpeed = config.vehicleSpeed or 200
                    Config.playerSpeed = config.playerSpeed or 28
                end
            end
end

        local function saveConfig()
            local config = {
                autorobToggle = State.autorobToggle,
                autoSellToggle = State.autoSellToggle,
                fastPlayerTeleport = State.fastPlayerTeleport,
                vehicleSpeed = Config.vehicleSpeed,
                playerSpeed = Config.playerSpeed
            }
            local json = HttpService:JSONEncode(config)
            writefile(configFileName, json)
        end

        loadConfig()

        SettingsTab:AddToggle({
            Name = "Fast Player Teleport",
            Default = State.fastPlayerTeleport,
            Callback = function(Value)
                State.fastPlayerTeleport = Value
                saveConfig()
            end    
        })

        SettingsTab:AddSlider({
            Name = "Vehicle Speed",
            Min = 100,
            Max = 300,
            Default = Config.vehicleSpeed,
            Color = Color3.fromRGB(85,170,255),
            Increment = 5,
            ValueName = "speed",
            Callback = function(Value)
                Config.vehicleSpeed = Value
                FARMspeed = Value
                saveConfig()
            end    
        })

        SettingsTab:AddSlider({
            Name = "Player Speed",
            Min = 20,
            Max = 50,
            Default = Config.playerSpeed,
            Color = Color3.fromRGB(85,170,255),
            Increment = 2,
            ValueName = "speed",
            Callback = function(Value)
                Config.playerSpeed = Value
                saveConfig()
            end    
        })

        SettingsTab:AddButton({
            Name = "Reset Config",
            Callback = function()
                if isfile(configFileName) then
                    delfile(configFileName)
                end
                State.autorobToggle = false
                State.autoSellToggle = false
                State.fastPlayerTeleport = true
                Config.vehicleSpeed = 200
                Config.playerSpeed = 28
                saveConfig()
                sendNotification("Settings Reset", "All settings reset to default")
            end
        })

        local autorobToggleUI = AutoRobTab:AddToggle({
            Name = "Autorob",
            Default = State.autorobToggle,
            Callback = function(Value)
                State.autorobToggle = Value
                if not Value then
                    stopAutofarm()
                end
                saveConfig()
            end    
        })

        local autoSellToggleUI = AutoRobTab:AddToggle({
            Name = "Auto-Sell",
            Default = State.autoSellToggle,
            Callback = function(Value)
                State.autoSellToggle = Value
                saveConfig()
            end    
        })

        -- NEU: Start Autofarm sofort Button
        AutoRobTab:AddButton({
            Name = "Start Autofarm sofort",
            Callback = function()
                if State.autofarmRunning then
                    sendNotification("Autofarm läuft bereits", "Stoppe zuerst das aktuelle Farming")
                else
                    startAutofarm()
                end
            end
        })

        -- NEU: Stop Autofarm Button
        AutoRobTab:AddButton({
            Name = "Stop Autofarm",
            Callback = function()
                stopAutofarm()
                autorobToggleUI:Set(false)
            end
        })

        autorobToggleUI:Set(State.autorobToggle)
        autoSellToggleUI:Set(State.autoSellToggle)

        OrionLib:Init()

        -- Warte in einer Schleife
        while true do
            task.wait(1)
        end
    end
    wait(1)
end
