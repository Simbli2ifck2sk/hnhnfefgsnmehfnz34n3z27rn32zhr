local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local LocalPlayer = player

-- HIER DEINEN PASTEBIN LINK EINFÜGEN!
local SCRIPT_URL = "https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/ROB.lua"

-- Kamera Setup
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 120   -- wieder auf Standard gesetzt, weniger Render-Last

local HEIGHT_OFFSET = 4
local BACK_OFFSET = 5

-- Kamera Lock (kann bei Bedarf auskommentiert werden)
local function lockCamera()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local cameraPosition = rootPart.Position - rootPart.CFrame.LookVector * BACK_OFFSET + Vector3.new(0, HEIGHT_OFFSET, 0)
        local lookAtPosition = rootPart.Position + rootPart.CFrame.LookVector * 10 + Vector3.new(0, 1.5, 0)
        camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
    end
end

RunService.RenderStepped:Connect(lockCamera)

-- Remote Events
local RemoteEvents = {
    sell = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("eb233e6a-acb9-4169-acb9-129fe8cb06bb"),
    equip = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("b16cb2a5-7735-4e84-a72b-22718da109fc"),
    buy = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("29c2c390-e58d-4512-9180-2da58f0d98d8"),
    rob = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("a3126821-130a-4135-80e1-1d28cece4007")
}

local Codes = {
    money = "yQL",
    items = "Vqe"
}

local Config = {
    range = 200,
    proximityPromptTime = 2.5,
    vehicleSpeed = 200,
    playerSpeed = 28,
    policeCheckRange = 40,
    lowHealthThreshold = 35
}

local State = {
    autorobToggle = true,
    autoSellToggle = true,
    collected = {},
    teleportActive = false,
    fastPlayerTeleport = true,
    autofarmRunning = false
}

-- Character Setup
local Character = player.Character or player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Locations (NUR BANK)
local Locations = {
    start = CFrame.new(-1305.168, 51.356, 3391.559),
    bank = CFrame.new(-1271.356, 5.836, 3195.081),
    bankCollectPositions = {
        Vector3.new(-1251.5240478515625, 7.723498821258545, 3127.464111328125),
        Vector3.new(-1247.194091796875, 7.723498821258545, 3102.603271484375),
        Vector3.new(-1231.880859375, 7.723498821258545, 3123.473876953125),
        Vector3.new(-1236.9227294921875, 7.723498821258545, 3099.447509765625)
    }
}

-- Auto Re-apply Setup
local function setupAutoReapply()
    local function queueScript()
        local scriptToQueue = 'loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()'
        
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
    
    Players.PlayerRemoving:Connect(function(plr)
        if plr == player then
            queueScript()
        end
    end)
    
    game:GetService("CoreGui").DescendantAdded:Connect(function(descendant)
        if descendant.Name == "ErrorPrompt" or descendant.Name == "ErrorTitle" then
            task.wait(0.5)
            queueScript()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end

setupAutoReapply()

-- Hilfsfunktionen
local function sendNotification(title, content)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = 5
    })
end

-- Server Hop via TeleportToPlaceInstance with job IDs from GitHub
local function hopToRandomServer()
    sendNotification("Server Hop", "Lade Job-IDs...")
    
    local jobIdsUrl = "https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/100"
    
    local success, response = pcall(function()
        return game:HttpGet(jobIdsUrl)
    end)
    
    if not success then
        sendNotification("Fehler", "Konnte Job-IDs nicht laden")
        return false
    end
    
    local jobIds = {}
    for line in response:gmatch("[^\r\n]+") do
        line = line:gsub("^%s*(.-)%s*$", "%1")
        if line ~= "" then
            table.insert(jobIds, line)
        end
    end
    
    if #jobIds == 0 then
        sendNotification("Fehler", "Keine gültigen Job-IDs gefunden")
        return false
    end
    
    local randomJobId = jobIds[math.random(1, #jobIds)]
    sendNotification("Server Hop", "Wechsle zu: " .. randomJobId)
    
    local scriptToQueue = 'loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()'
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(scriptToQueue)
    elseif queue_on_teleport then
        queue_on_teleport(scriptToQueue)
    elseif queueonteleport then
        queueonteleport(scriptToQueue)
    end
    
    TeleportService:TeleportToPlaceInstance(game.PlaceId, randomJobId, player)
    return true
end

-- Polizei-Check mit Cooldown (nur alle 2 Sekunden)
local lastPoliceCheck = 0
local policeNearby = false
local function updatePoliceNearby()
    if tick() - lastPoliceCheck < 2 then return policeNearby end
    lastPoliceCheck = tick()
    local policeTeam = game:GetService("Teams"):FindFirstChild("Police")
    if not policeTeam then
        policeNearby = false
        return false
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Team == policeTeam and plr.Character then
            local policeHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if policeHRP and HumanoidRootPart and (policeHRP.Position - HumanoidRootPart.Position).Magnitude <= Config.policeCheckRange then
                policeNearby = true
                return true
            end
        end
    end
    policeNearby = false
    return false
end

local function isPoliceNearby()
    return updatePoliceNearby()
end

local function isPlayerHurt()
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health <= Config.lowHealthThreshold
end

-- Cache für MeshParts im BankRobbery-Ordner
local cachedMeshParts = nil
local function getBankMeshParts(folder)
    if not folder then return {} end
    if cachedMeshParts then return cachedMeshParts end
    local parts = {}
    for _, meshPart in ipairs(folder:GetDescendants()) do
        if meshPart:IsA("MeshPart") and meshPart.Transparency == 0 then
            table.insert(parts, meshPart)
        end
    end
    cachedMeshParts = parts
    return parts
end

local function lootVisibleMeshParts(folder)
    if not folder then return end
    
    if isPoliceNearby() or isPlayerHurt() then
        return
    end
    
    local meshParts = getBankMeshParts(folder)
    for _, meshPart in ipairs(meshParts) do
        if not State.collected[meshPart] then
            if (meshPart.Position - HumanoidRootPart.Position).Magnitude <= Config.range then
                State.collected[meshPart] = true
                
                task.spawn(function()
                    local code = meshPart.Parent and meshPart.Parent.Name == "Money" and Codes.money or Codes.items
                    local args = {meshPart, code, true}
                    RemoteEvents.rob:FireServer(unpack(args))
                    task.wait(Config.proximityPromptTime)
                    args[3] = false
                    RemoteEvents.rob:FireServer(unpack(args))
                    State.collected[meshPart] = nil
                end)
                
                task.wait(0.05)
            end
        end
    end
end

local function inCar()
    local v = workspace.Vehicles:FindFirstChild(player.Name)
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if v and h and not h.SeatPart then 
        local s = v:FindFirstChild("DriveSeat")
        if s then 
            s:Sit(h)
            task.wait(0.3)
        end 
    end
end

local function ensurePlayerInVehicle()
    local vehicle = workspace.Vehicles and workspace.Vehicles:FindFirstChild(player.Name)
    local character = player.Character
    if vehicle and character then
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        local driveSeat = vehicle:FindFirstChild("DriveSeat")
        if humanoid and driveSeat and humanoid.SeatPart ~= driveSeat then
            driveSeat:Sit(humanoid)
        end
    end
end

local function clickAtCoordinates(scaleX, scaleY)
    local camera = Workspace.CurrentCamera
    local screenWidth = camera.ViewportSize.X
    local screenHeight = camera.ViewportSize.Y
    local absoluteX = screenWidth * scaleX
    local absoluteY = screenHeight * scaleY
            
    VirtualInputManager:SendMouseButtonEvent(absoluteX, absoluteY, 0, true, game, 0)  
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(absoluteX, absoluteY, 0, false, game, 0) 
end

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
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.SeatPart then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function plrTween(destination)
    local char = player.Character
    if not char or not char.PrimaryPart then return end

    if State.fastPlayerTeleport then
        char:SetPrimaryPartCFrame(CFrame.new(destination))
        task.wait(0.3)
        return
    end

    local distance = (char.PrimaryPart.Position - destination).Magnitude
    local tweenDuration = distance / Config.playerSpeed

    local TweenValue = Instance.new("CFrameValue")
    TweenValue.Value = char:GetPivot()

    TweenValue.Changed:Connect(function(newCFrame)
        char:PivotTo(newCFrame)
    end)

    local targetCFrame = CFrame.new(destination)
    local tween = TweenService:Create(TweenValue, TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear), { Value = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    TweenValue:Destroy()
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

    local v = workspace.Vehicles:FindFirstChild(player.Name)
    if not v or not v.PrimaryPart then 
        return 
    end
    
    local distance = (v.PrimaryPart.Position - targetCF.Position).Magnitude
    
    if distance < 50 then
        inCar()
        task.wait(0.5)
        v:SetPrimaryPartCFrame(targetCF)
        task.wait(0.5)
        return
    end
    
    inCar()
    task.wait(1)
    
    local startPos = v.PrimaryPart.Position
    local targetPos = targetCF.Position
    local totalDist = (targetPos - startPos).Magnitude
    local totalDur = totalDist / Config.vehicleSpeed
    
    local height = -50
    local upCF = CFrame.new(startPos.X, startPos.Y + height, startPos.Z) * (targetCF - targetCF.Position)
    local horCF = CFrame.new(targetPos.X, startPos.Y + height, targetPos.Z) * (targetCF - targetCF.Position)
    
    local function tweenModel(model, target, duration)
        if not model.PrimaryPart then return end
        local cv = Instance.new("CFrameValue")
        cv.Value = model:GetPrimaryPartCFrame()
        
        cv:GetPropertyChangedSignal("Value"):Connect(function()
            if model and model.PrimaryPart then
                model:SetPrimaryPartCFrame(cv.Value)
            end
        end)
        
        local tw = TweenService:Create(cv, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Value = target})
        tw:Play()
        tw.Completed:Wait()
        cv:Destroy()
    end
    
    tweenModel(v, upCF, (height / totalDist) * totalDur)
    tweenModel(v, horCF, (math.abs(targetPos.X - startPos.X) / totalDist) * totalDur)
    tweenModel(v, targetCF, (height / totalDist) * totalDur)
end

local function MoveToDealer()
    local vehicle = workspace.Vehicles:FindFirstChild(player.Name)
    if not vehicle then
        sendNotification("Fehler", "Kein Fahrzeug gefunden")
        return
    end

    local dealers = workspace:FindFirstChild("Dealers")
    if not dealers then
        sendNotification("Fehler", "Keine Dealer gefunden")
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
        sendNotification("Fehler", "Kein Dealer in Reichweite")
        return
    end

    local destination1 = closest.Position + Vector3.new(0, 5, 0)
    tweenTo(destination1)
end

local function hasGrenade()
    local function checkContainer(container)
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item.Name == "Grenade" then
                return true
            end
        end
        return false
    end
    return checkContainer(player.Backpack) or checkContainer(player.Character)
end

-- Fahrzeug automatisch abschließen
local function lockVehicle()
    local vehicle = workspace:FindFirstChild("Vehicles") and workspace.Vehicles:FindFirstChild(player.Name)
    if vehicle then
        vehicle:SetAttribute("Locked", true)
    end
end

task.spawn(function()
    task.wait(2)
    lockVehicle()
    while task.wait(10) do
        lockVehicle()
    end
end)

-- Hauptfunktion: NUR BANK RAUBEN
local function robBank()
    sendNotification("Bank Raub", "Starte Bank Überfall...")
    
    -- Prüfe ob verhaftet
    local team = player.Team
    local teamName = team and team.Name or "None"

    if teamName == "Prisoner" then
        sendNotification("Verhaftet", "Warte auf Freilassung...")
        repeat
            task.wait(5)
            team = player.Team
            teamName = team and team.Name or "None"
        until teamName ~= "Prisoner"
    end
    
    -- Zum Startpunkt
    ensurePlayerInVehicle()
    task.wait(.5)
    clickAtCoordinates(0.5, 0.9)
    task.wait(.5)
    tweenTo(Locations.start)
    
    -- Prüfe Bank-Status
    local bankLight = nil
    local bankLight2 = nil
    
    pcall(function()
        bankLight = Workspace.Robberies.BankRobbery.LightGreen.Light
        bankLight2 = Workspace.Robberies.BankRobbery.LightRed.Light
    end)
    
    -- Bank Überfall
    if bankLight2 and bankLight and bankLight2.Enabled == false and bankLight.Enabled == true then
        clickAtCoordinates(0.5, 0.9)
        sendNotification("Bank ist offen", "Starte Bank Überfall")
        
        -- Zur Bank
        tweenTo(Locations.bank)
        tweenTo(Locations.bank)
        JumpOut()
        task.wait(1.5)
        
        -- Granate werfen (nur wenn vorhanden)
        plrTween(Vector3.new(-1242.367919921875, 7.749999046325684, 3144.705322265625))
        task.wait(.5)
        local args = {"Grenade"}
        RemoteEvents.equip:FireServer(unpack(args))
        task.wait(.5)
        local tool = player.Character:FindFirstChild("Grenade")
        if tool then
            SpawnGrenade()
        end
        plrTween(Vector3.new(-1246.291015625, 7.749999046325684, 3120.8505859375))
        task.wait(2.9)
        
        -- Beute einsammeln
        local bankRobberyFolder = Workspace.Robberies.BankRobbery
        cachedMeshParts = nil -- Cache zurücksetzen, falls neue Teile erscheinen
        
        for _, position in ipairs(Locations.bankCollectPositions) do
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
                task.wait(0.3)   -- von 0.5 auf 0.3 reduziert, aber dennoch entlastend
            end
        end
        
        ensurePlayerInVehicle() 
        
        -- Verkaufen
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
        
        sendNotification("Bank Raub abgeschlossen", "Wechsle sofort den Server...")
        task.wait(2)
        hopToRandomServer()
        return true
        
    else
        sendNotification("Bank geschlossen", "Wechsle sofort zu einem neuen Server...")
        task.wait(2)
        hopToRandomServer()
        return true
    end
end

-- Haupt-Autofarm Funktion
local function startAutofarm()
    if State.autofarmRunning then return end
    State.autofarmRunning = true
    
    sendNotification("Bank Autofarm gestartet", "Starte mit Bank Überfällen...")
    
    task.spawn(function()
        while State.autofarmRunning do
            local hopped = robBank()
            if hopped then
                State.autofarmRunning = false
                return
            end
            task.wait(5)
        end
        
        State.autofarmRunning = false
        sendNotification("Bank Autofarm gestoppt", "Farm-Schleife beendet")
    end)
end

-- Character Added Event
player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- AUTO-START
task.wait(5)
startAutofarm()

-- Mit "R" Taste manuell neu starten
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        if State.autofarmRunning then
            State.autofarmRunning = false
            task.wait(1)
        end
        startAutofarm()
    end
end)
