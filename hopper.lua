-- =================================================================
-- EINSTELLUNGEN
-- =================================================================
local SCRIPT_URL = "https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/WORKING.lua"

local WAIT_BEFORE_HOP = math.random(50, 60) -- leicht randomisiert
local RETRY_DELAY = 5
local AFTER_HOP_DELAY = 10

-- =================================================================
-- SERVICES
-- =================================================================
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local queue = queue_on_teleport
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)

-- =================================================================
-- FUNKTION: SCRIPT LADEN
-- =================================================================
local function runMainScript()
    local success, content = pcall(function()
        return game:HttpGet(SCRIPT_URL)
    end)

    if not success or not content then
        warn("❌ Script konnte nicht geladen werden!")
        return
    end

    local func, err = loadstring(content)
    if not func then
        warn("❌ Loadstring Error:", err)
        return
    end

    task.spawn(func)
    print("✅ Hauptscript gestartet.")
end

-- =================================================================
-- FUNKTION: SERVER HOP
-- =================================================================
local function hopToRandomServer()
    while true do
        print("🔍 Suche neuen Server...")

        local success, response = pcall(function()
            return game:HttpGet(
                "https://games.roblox.com/v1/games/"
                .. game.PlaceId ..
                "/servers/Public?sortOrder=Asc&limit=100"
            )
        end)

        if success and response then
            local data = HttpService:JSONDecode(response)

            if data and data.data then
                local servers = {}

                for _, s in ipairs(data.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        table.insert(servers, s.id)
                    end
                end

                if #servers > 0 then
                    -- random server (stealth)
                    local targetServerId = servers[math.random(1, #servers)]

                    -- queue für nächsten server
                    if queue then
                        queue([[
                            repeat task.wait() until game:IsLoaded()
                            task.wait(]] .. AFTER_HOP_DELAY .. [[)
                            loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()
                        ]])
                    end

                    print("🚀 Teleporting...")

                    local ok, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(
                            game.PlaceId,
                            targetServerId,
                            player
                        )
                    end)

                    if ok then
                        return -- WICHTIG: beendet loop
                    else
                        warn("❌ Teleport Fehler:", err)
                    end
                end
            end
        end

        print("🔁 Retry in " .. RETRY_DELAY .. "s...")
        task.wait(RETRY_DELAY + math.random()) -- mini random delay
    end
end

-- =================================================================
-- START
-- =================================================================
runMainScript()

print("⏳ Warte " .. WAIT_BEFORE_HOP .. " Sekunden...")
task.wait(WAIT_BEFORE_HOP)

hopToRandomServer()
