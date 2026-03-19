-- =================================================================
-- SERVER HOP FIX (ROPROXY STATT ROBLOX API)
-- =================================================================

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
local SCRIPT_URL = "https://pastebin.com/raw/DEIN_PASTEBIN_LINK"

-- Hilfsfunktion für Benachrichtigungen
local function sendNotification(title, content)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = 5
    })
end

-- Korrigierte Server Hop Funktion (Nutzt Proxy)
local function hopToRandomServer()
    sendNotification("Server Hop", "Suche neuen Server...")
    
    -- Nutzt roproxy.com, da direktes HttpGet auf roblox.com blockiert wird
    local url = "https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
    
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success or not response then
        sendNotification("Fehler", "API-Anfrage fehlgeschlagen")
        return false
    end
    
    local data = HttpService:JSONDecode(response)
    local availableServers = {}
    
    if data and data.data then
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(availableServers, server.id)
            end
        end
    end
    
    if #availableServers == 0 then
        sendNotification("Fehler", "Keine freien Server gefunden")
        return false
    end
    
    local targetServerId = availableServers[math.random(1, #availableServers)]
    
    -- Script für Re-Execute nach Teleport vorbereiten
    local scriptToQueue = 'repeat task.wait() until game:IsLoaded(); loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()'
    local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    
    if queue then
        queue(scriptToQueue)
    end
    
    sendNotification("Server Hop", "Teleportiere...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServerId, player)
end

-- =================================================================
-- GAME LOGIC (BANK AUTOFARM)
-- =================================================================

-- Kamera Setup
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 120

local function lockCamera()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local cameraPosition = rootPart.Position - rootPart.CFrame.LookVector * 5 + Vector3.new(0, 4, 0)
        local lookAtPosition = rootPart.Position + rootPart.CFrame.LookVector * 10 + Vector3.new(0, 1.5, 0)
        camera.CFrame = CFrame.new(cameraPosition, lookAtPosition)
    end
end
RunService.RenderStepped:Connect(lockCamera)

-- Remote Events (Basierend auf deinem Code)
local RemoteEvents = {
    sell = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("eb233e6a-acb9-4169-acb9-129fe8cb06bb"),
    equip = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("b16cb2a5-7735-4e84-a72b-22718da109fc"),
    buy = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("29c2c390-e58d-4512-9180-2da58f0d98d8"),
    rob = ReplicatedStorage:WaitForChild("EJw"):WaitForChild("a3126821-130a-4135-80e1-1d28cece4007")
}

local Codes = { money = "yQL", items = "Vqe" }
local Config = { range = 200, proximityPromptTime = 2.5, vehicleSpeed = 200, playerSpeed = 28, policeCheckRange = 40, lowHealthThreshold = 35, checkInterval = 300 }
local State = { collected = {}, autofarmRunning = false }

local Locations = {
    start = CFrame.new(-1305.168, 51.356, 3391.559),
    bank = CFrame.new(-1271.356, 5.836, 3195.081),
    bankCollectPositions = {
        Vector3.new(-1251.52, 7.72, 3127.46),
        Vector3.new(-1247.19, 7.72, 3102.60),
        Vector3.new(-1231.88, 7.72, 3123.47),
        Vector3.new(-1236.92, 7.72, 3099.44)
    }
}

-- Helfer: Looten, Fahren, Checks
local function isPoliceNearby()
    local policeTeam = game:GetService("Teams"):FindFirstChild("Police")
    if not policeTeam then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Team == policeTeam and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if (plr.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude <= Config.policeCheckRange then
                return true
            end
        end
    end
    return false
end

local function ensurePlayerInVehicle()
    local vehicle = workspace.Vehicles:FindFirstChild(player.Name)
    if vehicle and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart ~= vehicle.DriveSeat then
            vehicle.DriveSeat:Sit(hum)
        end
    end
end

local function clickAtCoordinates(scaleX, scaleY)
    local screenWidth = camera.ViewportSize.X
    local screenHeight = camera.ViewportSize.Y
    VirtualInputManager:SendMouseButtonEvent(screenWidth * scaleX, screenHeight * scaleY, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(screenWidth * scaleX, screenHeight * scaleY, 0, false, game, 0)
end

local function tweenTo(targetCF)
    local v = workspace.Vehicles:FindFirstChild(player.Name)
    if not v or not v.PrimaryPart then return end
    ensurePlayerInVehicle()
    task.wait(0.5)
    v:SetPrimaryPartCFrame(targetCF) -- Vereinfachter Teleport für Stabilität
    task.wait(0.5)
end

-- Hauptlogik: Bank rauben
local function robBank()
    if player.Team and player.Team.Name == "Prisoner" then return end
    
    ensurePlayerInVehicle()
    clickAtCoordinates(0.5, 0.9)
    tweenTo(Locations.start)
    
    local bankOpen = false
    pcall(function()
        bankOpen = Workspace.Robberies.BankRobbery.LightGreen.Light.Enabled
    end)
    
    if bankOpen then
        sendNotification("Bank", "Raub startet...")
        tweenTo(Locations.bank)
        task.wait(1)
        
        -- Looting Logik (vereinfacht)
        for _, pos in ipairs(Locations.bankCollectPositions) do
            if isPoliceNearby() then break end
            player.Character:SetPrimaryPartCFrame(CFrame.new(pos))
            task.wait(2) -- Zeit zum Sammeln
        end
        
        -- Verkauf
        ensurePlayerInVehicle()
        tweenTo(Locations.start) -- Platzhalter für Dealer
        RemoteEvents.sell:FireServer("Gold", "Dealer")
    else
        sendNotification("Bank", "Geschlossen. Warte...")
    end
end

-- Autofarm Loop
local function startAutofarm()
    if State.autofarmRunning then return end
    State.autofarmRunning = true
    
    task.spawn(function()
        while State.autofarmRunning do
            robBank()
            task.wait(5)
            
            -- Server Hop nach Zeitintervall (5 Min)
            sendNotification("Autofarm", "Hop in 5 Minuten...")
            task.wait(Config.checkInterval)
            if State.autofarmRunning then
                hopToRandomServer()
                break
            end
        end
    end)
end

-- Start
task.wait(3)
startAutofarm()

-- Hotkey R zum Neustart
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        State.autofarmRunning = false
        task.wait(1)
        startAutofarm()
    end
end)
