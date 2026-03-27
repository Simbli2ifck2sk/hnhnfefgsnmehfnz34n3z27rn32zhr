--[[
    Verbesserter Bank-Autofarm + Server-Hop
    - Keine 5-Minuten-Warte
    - Automatischer Serverwechsel nach jedem Raub (Bank offen oder geschlossen)
    - Robuste Fehlerbehandlung
    - Dynamisches Laden der Remote-Events
    - Optimierte Bewegungen und Interaktionen
    - Fahrzeug-Lock & automatisches Einsteigen
    - Polizei-Check & Gesundheits-Check
    - R-Taste zum Neustart
]]

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

-- ==============================
-- KONFIGURATION (anpassbar)
-- ==============================
local Config = {
    -- Skript-URL für Auto-Reapply (leer lassen, wenn nicht benötigt)
    SCRIPT_URL = "https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/ROB.lua",  -- z.B. "https://pastebin.com/raw/abc123"
    -- Job-IDs URL
    JOB_IDS_URL = "https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/100",
    -- Kamera-Einstellungen
    CAMERA_HEIGHT_OFFSET = 4,
    CAMERA_BACK_OFFSET = 5,
    -- Bewegungs- und Interaktions-Einstellungen
    PLAYER_SPEED = 28,
    VEHICLE_SPEED = 100,
    RANGE = 200,
    PROXIMITY_PROMPT_TIME = 2.5,
    POLICE_CHECK_RANGE = 40,
    LOW_HEALTH_THRESHOLD = 35,
    -- Wartezeiten
    START_DELAY = 5,           -- Warten nach Skriptstart
    HOP_DELAY = 2,             -- Warten vor Server-Hop
    COLLECT_DURATION = 4.5,    -- Sammelzeit pro Position
    -- Optionen
    FAST_PLAYER_TELEPORT = true,   -- Teleport statt Tween für Spieler
    LOCK_VEHICLE = true,            -- Fahrzeug automatisch abschließen
}

-- ==============================
-- GLOBALE VARIABLEN
-- ==============================
local RemoteEvents = {}      -- wird später dynamisch geladen
local Codes = {
    money = "yQL",
    items = "Vqe"
}
local State = {
    autorobToggle = true,
    autoSellToggle = true,
    collected = {},
    autofarmRunning = false,
    characterLoaded = false,
}

local Character = nil
local HumanoidRootPart = nil
local camera = workspace.CurrentCamera

-- ==============================
-- HILFSFUNKTIONEN
-- ==============================
local function sendNotification(title, content, duration)
    duration = duration or 5
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = content,
            Duration = duration
        })
    end)
end

-- Dynamisches Laden der RemoteEvents (robust)
local function loadRemoteEvents()
    local ejw = ReplicatedStorage:FindFirstChild("EJw")
    if not ejw then
        sendNotification("Fehler", "Remote-Ordner 'EJw' nicht gefunden!", 10)
        return false
    end
    local events = {
        sell = "eb233e6a-acb9-4169-acb9-129fe8cb06bb",
        equip = "b16cb2a5-7735-4e84-a72b-22718da109fc",
        buy = "29c2c390-e58d-4512-9180-2da58f0d98d8",
        rob = "a3126821-130a-4135-80e1-1d28cece4007"
    }
    for name, id in pairs(events) do
        local event = ejw:FindFirstChild(id)
        if not event then
            sendNotification("Fehler", "Remote-Event '" .. name .. "' nicht gefunden!", 10)
            return false
        end
        RemoteEvents[name] = event
    end
    return true
end

-- Auto-Reapply (nur wenn SCRIPT_URL gesetzt)
local function setupAutoReapply()
    if Config.SCRIPT_URL == "" then return end
    local function queueScript()
        local scriptToQueue = 'loadstring(game:HttpGet("' .. Config.SCRIPT_URL .. '"))()'
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport(scriptToQueue)
        elseif queue_on_teleport then
            queue_on_teleport(scriptToQueue)
        elseif queueonteleport then
            queueonteleport(scriptToQueue)
        end
    end
    Players.PlayerRemoving:Connect(function(plr)
        if plr == player then queueScript() end
    end)
    game:GetService("CoreGui").DescendantAdded:Connect(function(descendant)
        if descendant.Name == "ErrorPrompt" or descendant.Name == "ErrorTitle" then
            task.wait(0.5)
            queueScript()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
end

-- Kamera-Steuerung
local function lockCamera()
    if not Character or not HumanoidRootPart then return end
    local rootPart = HumanoidRootPart
    local cameraPosition = rootPart.Position - rootPart.CFrame.LookVector * Config.CAMERA_BACK_OFFSET + Vector3.new(0, Config.CAMERA_HEIGHT_OFFSET, 0)
    local lookAtPosition = rootPart.Position + rootPart.CFrame.LookVector * 10 + Vector3.new(0, 1.5, 0)
    camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
end

-- Spieler-Teleport (oder Tween)
local function teleportPlayer(position)
    if not Character or not Character.PrimaryPart then return end
    if Config.FAST_PLAYER_TELEPORT then
        Character:SetPrimaryPartCFrame(CFrame.new(position))
        task.wait(0.2)
    else
        -- einfacher Tween (optional)
        local distance = (Character.PrimaryPart.Position - position).Magnitude
        local duration = distance / Config.PLAYER_SPEED
        local tween = TweenService:Create(Character.PrimaryPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(position)})
        tween:Play()
        tween.Completed:Wait()
    end
end

-- Fahrzeug-Tween (optimiert)
local function tweenVehicle(target)
    local v = workspace.Vehicles and workspace.Vehicles:FindFirstChild(player.Name)
    if not v or not v.PrimaryPart then return end

    local targetCF = (typeof(target) == "CFrame") and target or CFrame.new(target)
    local startPos = v.PrimaryPart.Position
    local targetPos = targetCF.Position
    local distance = (targetPos - startPos).Magnitude

    if distance < 50 then
        -- kurze Distanz: sofort setzen
        v:SetPrimaryPartCFrame(targetCF)
        return
    end

    -- Einsteigen, falls nicht im Fahrzeug
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    local driveSeat = v:FindFirstChild("DriveSeat")
    if humanoid and driveSeat and humanoid.SeatPart ~= driveSeat then
        driveSeat:Sit(humanoid)
        task.wait(0.3)
    end

    -- Hoch, dann horizontal, dann runter
    local height = -50
    local upCF = CFrame.new(startPos.X, startPos.Y + height, startPos.Z) * (targetCF - targetCF.Position)
    local horCF = CFrame.new(targetPos.X, startPos.Y + height, targetPos.Z) * (targetCF - targetCF.Position)
    local totalDur = distance / Config.VEHICLE_SPEED

    local function moveModel(model, cf, dur)
        if not model.PrimaryPart then return end
        local cv = Instance.new("CFrameValue")
        cv.Value = model:GetPrimaryPartCFrame()
        cv:GetPropertyChangedSignal("Value"):Connect(function()
            if model and model.PrimaryPart then model:SetPrimaryPartCFrame(cv.Value) end
        end)
        local tw = TweenService:Create(cv, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Value = cf})
        tw:Play()
        tw.Completed:Wait()
        cv:Destroy()
    end

    moveModel(v, upCF, (height / distance) * totalDur)
    moveModel(v, horCF, (math.abs(targetPos.X - startPos.X) / distance) * totalDur)
    moveModel(v, targetCF, (height / distance) * totalDur)
end

-- Fahrzeug abschließen
local function lockVehicle()
    if not Config.LOCK_VEHICLE then return end
    local vehicle = workspace.Vehicles and workspace.Vehicles:FindFirstChild(player.Name)
    if vehicle then
        vehicle:SetAttribute("Locked", true)
    end
end

-- Server Hop mit Job-IDs
local function hopToRandomServer()
    sendNotification("Server Hop", "Lade Job-IDs...")
    local success, response = pcall(function()
        return game:HttpGet(Config.JOB_IDS_URL)
    end)
    if not success then
        sendNotification("Fehler", "Konnte Job-IDs nicht laden", 5)
        return false
    end
    local jobIds = {}
    for line in response:gmatch("[^\r\n]+") do
        line = line:gsub("^%s*(.-)%s*$", "%1")
        if line ~= "" then table.insert(jobIds, line) end
    end
    if #jobIds == 0 then
        sendNotification("Fehler", "Keine gültigen Job-IDs gefunden", 5)
        return false
    end
    local randomJobId = jobIds[math.random(1, #jobIds)]
    sendNotification("Server Hop", "Wechsle zu: " .. randomJobId, 5)

    -- Skript für neuen Server vorbereiten
    if Config.SCRIPT_URL ~= "" then
        local scriptToQueue = 'loadstring(game:HttpGet("' .. Config.SCRIPT_URL .. '"))()'
        if syn and syn.queue_on_teleport then syn.queue_on_teleport(scriptToQueue)
        elseif queue_on_teleport then queue_on_teleport(scriptToQueue)
        elseif queueonteleport then queueonteleport(scriptToQueue) end
    end

    TeleportService:TeleportToPlaceInstance(game.PlaceId, randomJobId, player)
    return true
end

-- Hilfsfunktionen: Granate werfen, aussteigen, klicken
local function clickAtCoordinates(scaleX, scaleY)
    local viewport = camera.ViewportSize
    local x, y = viewport.X * scaleX, viewport.Y * scaleY
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function spawnGrenade()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    task.wait(0.5)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function jumpOut()
    local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

-- Prüfungen: Polizei, Gesundheit, Granate
local function isPoliceNearby()
    local policeTeam = game:GetService("Teams"):FindFirstChild("Police")
    if not policeTeam then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Team == policeTeam and plr.Character then
            local policeHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if policeHRP and HumanoidRootPart and (policeHRP.Position - HumanoidRootPart.Position).Magnitude <= Config.POLICE_CHECK_RANGE then
                return true
            end
        end
    end
    return false
end

local function isPlayerHurt()
    local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health <= Config.LOW_HEALTH_THRESHOLD
end

local function hasGrenade()
    local function check(container)
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item.Name == "Grenade" then return true end
        end
        return false
    end
    return check(player.Backpack) or (Character and check(Character))
end

-- Beute einsammeln
local function lootMeshParts(folder)
    if not folder then return end
    for _, mesh in ipairs(folder:GetDescendants()) do
        if mesh:IsA("MeshPart") and mesh.Transparency == 0 and not State.collected[mesh] then
            if HumanoidRootPart and (mesh.Position - HumanoidRootPart.Position).Magnitude <= Config.RANGE then
                State.collected[mesh] = true
                task.spawn(function()
                    local code = (mesh.Parent and mesh.Parent.Name == "Money") and Codes.money or Codes.items
                    RemoteEvents.rob:FireServer(mesh, code, true)
                    task.wait(Config.PROXIMITY_PROMPT_TIME)
                    RemoteEvents.rob:FireServer(mesh, code, false)
                    State.collected[mesh] = nil
                end)
                task.wait(0.05)
            end
        end
    end
end

-- Händler ansteuern
local function moveToDealer()
    local vehicle = workspace.Vehicles and workspace.Vehicles:FindFirstChild(player.Name)
    if not vehicle then
        sendNotification("Fehler", "Kein Fahrzeug gefunden", 3)
        return false
    end
    local dealers = workspace:FindFirstChild("Dealers")
    if not dealers then
        sendNotification("Fehler", "Keine Dealer gefunden", 3)
        return false
    end
    local closest, shortest = nil, math.huge
    for _, dealer in pairs(dealers:GetChildren()) do
        local head = dealer:FindFirstChild("Head")
        if head and HumanoidRootPart then
            local dist = (HumanoidRootPart.Position - head.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = head
            end
        end
    end
    if not closest then
        sendNotification("Fehler", "Kein Dealer in Reichweite", 3)
        return false
    end
    tweenVehicle(closest.Position + Vector3.new(0, 5, 0))
    return true
end

-- ==============================
-- BANK-RAUB (Hauptlogik)
-- ==============================
local function robBank()
    sendNotification("Bank Raub", "Starte...")

    -- Warten, bis Charakter vollständig geladen
    repeat task.wait(0.5) until Character and Character.PrimaryPart and HumanoidRootPart

    -- Im Gefängnis? Warten
    local team = player.Team
    while team and team.Name == "Prisoner" do
        sendNotification("Im Gefängnis", "Warte auf Freilassung...", 3)
        repeat task.wait(5) until player.Team and player.Team.Name ~= "Prisoner"
        team = player.Team
    end

    -- Zum Startpunkt fahren
    local startCF = CFrame.new(-1305.168, 51.356, 3391.559)
    tweenVehicle(startCF)
    task.wait(0.5)
    clickAtCoordinates(0.5, 0.9)  -- optional: Türen schließen/öffnen
    task.wait(0.5)
    tweenVehicle(startCF) -- nochmal sicherstellen

    -- Bankstatus prüfen
    local bankFolder = Workspace:FindFirstChild("Robberies") and Workspace.Robberies:FindFirstChild("BankRobbery")
    if not bankFolder then
        sendNotification("Fehler", "BankRobbery nicht gefunden", 5)
        task.wait(2)
        hopToRandomServer()
        return true
    end
    local lightGreen = bankFolder:FindFirstChild("LightGreen") and bankFolder.LightGreen:FindFirstChild("Light")
    local lightRed   = bankFolder:FindFirstChild("LightRed")   and bankFolder.LightRed:FindFirstChild("Light")
    local bankOpen = lightGreen and lightRed and lightRed.Enabled == false and lightGreen.Enabled == true

    if bankOpen then
        sendNotification("Bank ist offen", "Starte Überfall", 3)

        -- Granate besorgen, falls nötig
        if not hasGrenade() then
            if moveToDealer() then
                task.wait(0.5)
                RemoteEvents.buy:FireServer("Grenade", "Dealer")
                task.wait(0.5)
            end
        end

        -- Zur Bank fahren
        local bankCF = CFrame.new(-1271.356, 5.836, 3195.081)
        tweenVehicle(bankCF)
        tweenVehicle(bankCF) -- doppelt, um sicher anzukommen
        jumpOut()
        task.wait(1)

        -- Granate werfen
        teleportPlayer(Vector3.new(-1242.367919921875, 7.749999046325684, 3144.705322265625))
        task.wait(0.5)
        RemoteEvents.equip:FireServer("Grenade")
        task.wait(0.5)
        local grenade = Character and Character:FindFirstChild("Grenade")
        if grenade then spawnGrenade() end
        teleportPlayer(Vector3.new(-1246.291015625, 7.749999046325684, 3120.8505859375))
        task.wait(2.9)

        -- Beute einsammeln
        local collectPositions = {
            Vector3.new(-1251.5240478515625, 7.723498821258545, 3127.464111328125),
            Vector3.new(-1247.194091796875, 7.723498821258545, 3102.603271484375),
            Vector3.new(-1231.880859375, 7.723498821258545, 3123.473876953125),
            Vector3.new(-1236.9227294921875, 7.723498821258545, 3099.447509765625)
        }
        for _, pos in ipairs(collectPositions) do
            if isPoliceNearby() then break end
            teleportPlayer(pos)
            local startTime = tick()
            while tick() - startTime < Config.COLLECT_DURATION do
                if isPoliceNearby() then break end
                lootMeshParts(bankFolder)
                task.wait(0.5)
            end
        end

        -- Verkaufen
        task.wait(0.5)
        moveToDealer()
        task.wait(0.5)
        moveToDealer()
        task.wait(0.5)
        RemoteEvents.sell:FireServer("Gold", "Dealer")
        RemoteEvents.sell:FireServer("Gold", "Dealer")
        RemoteEvents.sell:FireServer("Gold", "Dealer")
        task.wait(0.5)

        sendNotification("Bank Raub abgeschlossen", "Wechsle Server...", 3)
    else
        sendNotification("Bank geschlossen", "Wechsle Server...", 3)
    end

    task.wait(Config.HOP_DELAY)
    hopToRandomServer()
    return true
end

-- ==============================
-- AUTOFARM (Hauptschleife)
-- ==============================
local function startAutofarm()
    if State.autofarmRunning then return end
    State.autofarmRunning = true
    sendNotification("Bank Autofarm gestartet", "Raube unendlich Banken...", 5)

    task.spawn(function()
        while State.autofarmRunning do
            local success, err = pcall(robBank)
            if not success then
                sendNotification("Fehler", err, 10)
                task.wait(5)
            end
            -- robBank führt immer einen Server-Hop durch, daher endet die Schleife hier
            State.autofarmRunning = false
        end
        sendNotification("Bank Autofarm gestoppt", "Farm-Schleife beendet", 5)
    end)
end

-- ==============================
-- INITIALISIERUNG
-- ==============================
local function init()
    -- RemoteEvents laden
    if not loadRemoteEvents() then
        sendNotification("Fehler", "RemoteEvents konnten nicht geladen werden!", 10)
        return
    end

    -- Kamera einstellen
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 120
    RunService.RenderStepped:Connect(lockCamera)

    -- Charakter abwarten
    Character = player.Character or player.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    State.characterLoaded = true

    -- Fahrzeug-Lock (dauerhaft)
    if Config.LOCK_VEHICLE then
        task.spawn(function()
            while true do
                task.wait(10)
                lockVehicle()
            end
        end)
    end

    -- Auto-Reapply einrichten
    setupAutoReapply()

    -- Nach Startverzögerung Autofarm starten
    task.wait(Config.START_DELAY)
    startAutofarm()
end

-- Charakter-Neuladung abfangen
player.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    State.characterLoaded = true
end)

-- Mit R-Taste manuell neustarten
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        if State.autofarmRunning then
            State.autofarmRunning = false
            task.wait(1)
        end
        startAutofarm()
    end
end)

-- Skript starten
init()
