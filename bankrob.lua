local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local LocalPlayer = Player

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
    collected = {},
    teleportActive = false,
    fastPlayerTeleport = true
}

-- Warte auf Character
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Locations
local Locations = {
    start = CFrame.new(-1305.168, 51.356, 3391.559),
    bank = CFrame.new(-1271.356, 5.836, 3195.081),
    bankCollectPositions = {
        Vector3.new(-1251.5240478515625, 7.723498821258545, 3127.464111328125),
        Vector3.new(-1247.194091796875, 7.723498821258545, 3102.603271484375),
        Vector3.new(-1231.880859375, 7.723498821258545, 3123.473876953125),
        Vector3.new(-1236.9227294921875, 7.723498821258545, 3099.447509765625)
    },
    bankBombPos = Vector3.new(-1242.367919921875, 7.749999046325684, 3144.705322265625),
    bankWaitPos = Vector3.new(-1246.291015625, 7.749999046325684, 3120.8505859375)
}

-- HIER KANNST DU DEN SAVE PLACE ÄNDERN:
local SavePlace = CFrame.new(152.25, 5.20, 2224.75) -- Aktuell Startposition

-- Hilfsfunktionen
local function sendNotification(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

local function isPoliceNearby()
    local policeTeam = game:GetService("Teams"):FindFirstChild("Police")
    if not policeTeam then return false end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Team == policeTeam and plr.Character then
            local policeHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if policeHRP and HumanoidRootPart and (policeHRP.Position - HumanoidRootPart.Position).Magnitude <= Config.policeCheckRange then
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
    if isPoliceNearby() or isPlayerHurt() then return end
    
    for _, meshPart in ipairs(folder:GetDescendants()) do
        if meshPart:IsA("MeshPart") and meshPart.Transparency == 0 and not State.collected[meshPart] then
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

local function ensurePlayerInVehicle()
    local vehicle = workspace.Vehicles and workspace.Vehicles:FindFirstChild(Player.Name)
    local character = Player.Character
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
    local character = Player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.SeatPart then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
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
    return checkContainer(Player.Backpack) or checkContainer(Player.Character)
end

local function MoveToDealer()
    local dealers = workspace:FindFirstChild("Dealers")
    if not dealers then return end

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

    if closest then
        tweenTo(closest.Position + Vector3.new(0, 5, 0))
    end
end

local function plrTween(destination)
    local char = Player.Character
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

    local v = workspace.Vehicles:FindFirstChild(Player.Name)
    if not v or not v.PrimaryPart then 
        -- Wenn kein Fahrzeug, versuche zu Fuß zu gehen
        plrTween(targetCF.Position)
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
    
    tweenModel(v, targetCF, totalDur)
end

-- GEFIXTE Haupt-Funktion: Einmal rauben und zum Save Place
local function robOnceAndGoToSave()
    sendNotification("Starte Raubzug", "Einmal rauben und dann zum Save Place")
    
    -- Prüfe ob verhaftet
    local team = Player.Team
    if team and team.Name == "Prisoner" then
        sendNotification("Verhaftet", "Warte auf Freilassung...")
        repeat
            task.wait(5)
            team = Player.Team
        until team and team.Name ~= "Prisoner"
    end
    
    -- Stelle sicher, dass wir ein Fahrzeug haben
    ensurePlayerInVehicle()
    task.wait(1)
    
    -- Klicke auf den Bildschirm (für UI)
    clickAtCoordinates(0.5, 0.9)
    task.wait(1)
    
    -- Prüfe Bank-Status
    local success, bankLight = pcall(function()
        return Workspace.Robberies.BankRobbery.LightGreen.Light
    end)
    
    local success2, bankLight2 = pcall(function()
        return Workspace.Robberies.BankRobbery.LightRed.Light
    end)
    
    if success and success2 and bankLight2 and bankLight and bankLight2.Enabled == false and bankLight.Enabled == true then
        clickAtCoordinates(0.5, 0.9)
        sendNotification("Bank offen", "Starte Überfall")
        
        -- Granaten besorgen falls nötig
        ensurePlayerInVehicle()
        if not hasGrenade() then
            sendNotification("Kaufe Granate", "Gehe zum Dealer")
            MoveToDealer()
            task.wait(1)
            local args = {"Grenade", "Dealer"}
            RemoteEvents.buy:FireServer(unpack(args))
            task.wait(1)
        end
        
        -- Zur Bank
        sendNotification("Fahre zur Bank", "")
        tweenTo(Locations.bank)
        task.wait(1)
        
        -- Aussteigen
        JumpOut()
        task.wait(1.5)
        
        -- Zur Bomben-Position
        plrTween(Locations.bankBombPos)
        task.wait(0.5)
        
        -- Granate ausrüsten
        RemoteEvents.equip:FireServer({"Grenade"})
        task.wait(0.5)
        
        -- Granate werfen
        if Player.Character and Player.Character:FindFirstChild("Grenade") then
            sendNotification("Werfe Granate", "")
            SpawnGrenade()
        end
        
        -- Zur Warte-Position
        plrTween(Locations.bankWaitPos)
        task.wait(3) -- Warte bis Granate explodiert
        
        -- Beute einsammeln
        sendNotification("Sammle Beute", "")
        local bankRobberyFolder = Workspace.Robberies.BankRobbery
        
        for i, position in ipairs(Locations.bankCollectPositions) do
            if isPoliceNearby() then 
                sendNotification("Polizei in der Nähe", "Breche ab")
                ensurePlayerInVehicle()
                break 
            end
            
            -- Zur Sammelposition
            if Character and Character.PrimaryPart then
                Character:SetPrimaryPartCFrame(CFrame.new(position))
                task.wait(0.5)
            end
            
            -- Sammle für 4.5 Sekunden
            local startTime = tick()
            while tick() - startTime < 4.5 do
                if isPoliceNearby() then 
                    ensurePlayerInVehicle()
                    break 
                end
                lootVisibleMeshParts(bankRobberyFolder)
                task.wait(0.3)
            end
        end
        
        -- Zurück ins Fahrzeug
        ensurePlayerInVehicle()
        task.wait(1)
        
        -- Verkaufen
        sendNotification("Verkaufe Beute", "")
        MoveToDealer()
        task.wait(1)
        
        -- Mehrmals verkaufen
        local args = {"Gold", "Dealer"}
        RemoteEvents.sell:FireServer(unpack(args))
        task.wait(0.3)
        RemoteEvents.sell:FireServer(unpack(args))
        task.wait(0.3)
        RemoteEvents.sell:FireServer(unpack(args))
        task.wait(0.5)
        
        -- **ZUM SAVE PLACE GEHEN**
        sendNotification("Raub fertig", "Gehe zum Save Place")
        ensurePlayerInVehicle()
        tweenTo(SavePlace)
        sendNotification("Angekommen", "Am Save Place")
        
    else
        sendNotification("Bank geschlossen", "Kein Raub möglich")
        -- Trotzdem zum Save Place gehen
        ensurePlayerInVehicle()
        tweenTo(SavePlace)
        sendNotification("Angekommen", "Am Save Place (Bank war zu)")
    end
end

-- Auto Lock Vehicle
task.spawn(function()
    task.wait(2)
    local function lockVehicle()
        local vehicle = workspace:FindFirstChild("Vehicles") and workspace.Vehicles:FindFirstChild(Player.Name)
        if vehicle then
            vehicle:SetAttribute("Locked", true)
        end
    end
    lockVehicle()
    while task.wait(10) do
        lockVehicle()
    end
end)

-- Kamera-Sperre (wie im Original)
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 120

local HEIGHT_OFFSET = 4
local BACK_OFFSET = 5

local function lockCamera()
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = Character.HumanoidRootPart
        local cameraPosition = rootPart.Position - rootPart.CFrame.LookVector * BACK_OFFSET + Vector3.new(0, HEIGHT_OFFSET, 0)
        local lookAtPosition = rootPart.Position + rootPart.CFrame.LookVector * 10 + Vector3.new(0, 1.5, 0)
        camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
    end
end

RunService.RenderStepped:Connect(lockCamera)

Player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- **HIER STARTET DER RAUB SOFORT (NUR EINMAL)**
task.wait(3) -- Längere Wartezeit für Stabilität
spawn(function()
    robOnceAndGoToSave()
end)

-- Optional: Nochmal rauben mit "R" Taste
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        spawn(function()
            robOnceAndGoToSave()
        end)
    end
end)

-- Zusätzliche Info im Chat
print("Script geladen! Drücke R für einen weiteren Raubzug.")
print("Save Place kann in der Datei geändert werden (Zeile ~36)")
