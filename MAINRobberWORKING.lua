local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local SCRIPT_URL = "https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/bankrob.lua"
local WAIT_BEFORE_HOP = 60 

-- Funktion für den Server-Wechsel
local function teleportToRandomServer()
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        local servers = data.data
        local target = servers[math.random(1, #servers)]
        return target.id
    end)

    if success and result then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, result, player)
    else
        TeleportService:Teleport(game.PlaceId, player)
    end
end

-- UI ERSTELLUNG
local function createUI()
    -- Falls schon eine UI existiert, löschen
    local oldGui = player.PlayerGui:FindFirstChild("ServerHopGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ServerHopGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999 -- Immer ganz oben
    screenGui.Parent = player.PlayerGui

    local hopButton = Instance.new("TextButton")
    hopButton.Size = UDim2.new(0, 200, 0, 50)
    hopButton.Position = UDim2.new(0.5, -100, 0, 50) -- 50 Pixel vom oberen Rand
    hopButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    hopButton.BorderSizePixel = 2
    hopButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    hopButton.Text = "HOP SERVER NOW"
    hopButton.Font = Enum.Font.RobotoMono
    hopButton.TextSize = 20
    hopButton.Active = true
    hopButton.Draggable = true -- Du kannst den Button verschieben
    hopButton.Parent = screenGui

    hopButton.MouseButton1Click:Connect(function()
        hopButton.Text = "Teleporting..."
        teleportToRandomServer()
    end)
end

-- UI sofort erstellen
createUI()

-- Hauptscript starten
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet(SCRIPT_URL))()
    end)
end)

-- Automatischer Hop nach Zeit
task.delay(WAIT_BEFORE_HOP, function()
    teleportToRandomServer()
end)
