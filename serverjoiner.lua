local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Die ID deines Spiels (PlaceId)
local placeId = game.PlaceId 

local function teleportToNewServer()
    print("Suche nach einem neuen Server...")
    
    -- Teleportiert den Spieler zu einem zufälligen öffentlichen Server desselben Spiels
    TeleportService:Teleport(placeId, player)
end

-- Sofortiges Ausführen beim Start des Scripts
teleportToNewServer()
