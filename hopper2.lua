-- =================================================================
-- ANTI DOUBLE EXECUTE
-- =================================================================
if getgenv().HopperLoaded then return end
getgenv().HopperLoaded = true

-- =================================================================
-- EINSTELLUNGEN
-- =================================================================
local HOPPER_URL = "https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/hopper2.lua"
local MAIN_SCRIPT = "https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/WORKING2.lua"

local WAIT_BEFORE_HOP = 39 -- Changed to 0 for immediate hop (or keep math.random if you want delay)
local RETRY_DELAY = 5
local AFTER_HOP_DELAY = 10

-- =================================================================
-- SERVICES
-- =================================================================
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService") -- For console message detection

local player = Players.LocalPlayer

local queue = queue_on_teleport
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)

-- =================================================================
-- BANK CLOSED DETECTION
-- =================================================================
local bankClosedDetected = false

-- Function to check if bank is closed (by checking game objects)
local function isBankClosed()
    -- Try to find bank-related objects in the game
    local bankGui = player.PlayerGui:FindFirstChild("Bank") 
        or player.PlayerGui:FindFirstChild("BankUI")
        or player.PlayerGui:FindFirstChild("BankSystem")
    
    if bankGui then
        -- Check for closed indicators in UI
        local closedText = bankGui:FindFirstChild("ClosedLabel") 
            or bankGui:FindFirstChild("BankClosed")
            or bankGui:FindFirstChild("Status")
        
        if closedText and closedText.Visible then
            return true
        end
    end
    
    -- Check workspace for bank closed indicators
    local bankPart = workspace:FindFirstChild("Bank") 
        or workspace:FindFirstChild("BankArea")
        or workspace:FindFirstChild("BankSystem")
    
    if bankPart then
        local closedPart = bankPart:FindFirstChild("Closed")
            or bankPart:FindFirstChild("BankClosed")
        
        if closedPart and closedPart.Visible then
            return true
        end
    end
    
    return false
end

-- Monitor console for bank closed message
local function monitorConsole()
    local originalPrint = print
    local consoleMessages = {}
    
    -- Override print to capture messages
    print = function(...)
        local args = {...}
        local msg = table.concat(args, " ")
        table.insert(consoleMessages, msg)
        
        -- Check for bank closed message
        if string.find(msg, "BANK.*CLOSED") or string.find(msg, "CLOSED.*BANK") or string.find(msg, "bank.*closed") then
            bankClosedDetected = true
            print("🔴 Bank closed detected! Hopping immediately...")
        end
        
        -- Call original print
        originalPrint(...)
    end
    
    -- Also check LogService for console output (more reliable)
    if LogService and LogService.MessageOut then
        LogService.MessageOut:Connect(function(message, messageType)
            if string.find(message, "BANK.*CLOSED") or string.find(message, "CLOSED.*BANK") or string.find(message, "bank.*closed") then
                bankClosedDetected = true
                originalPrint("🔴 Bank closed detected via LogService! Hopping immediately...")
            end
        end)
    end
end

-- Start monitoring
monitorConsole()

-- =================================================================
-- MAIN SCRIPT LADEN
-- =================================================================
local function runMainScript()
    local success, content = pcall(function()
        return game:HttpGet(MAIN_SCRIPT)
    end)

    if not success or not content then
        warn("❌ Main Script konnte nicht geladen werden!")
        return
    end

    local func, err = loadstring(content)
    if not func then
        warn("❌ Loadstring Error:", err)
        return
    end

    task.spawn(func)
    print("✅ Main Script gestartet.")
end

-- =================================================================
-- SERVER HOP
-- =================================================================
local function hopToRandomServer()
    while true do
        -- Check if bank closed was detected before hopping
        if bankClosedDetected then
            print("🔍 Bank closed detected, searching for new server...")
        else
            print("🔍 Suche neuen Server...")
        end
        
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
                    local targetServerId = servers[math.random(1, #servers)]

                    -- Queue → startet Hopper wieder im nächsten Server
                    if queue then
                        queue([[
                            repeat task.wait() until game:IsLoaded()
                            task.wait(]] .. AFTER_HOP_DELAY .. [[)
                            loadstring(game:HttpGet("]] .. HOPPER_URL .. [["))()
                        ]])
                    end

                    print("🚀 Teleportiere...")

                    local ok, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(
                            game.PlaceId,
                            targetServerId,
                            player
                        )
                    end)

                    if ok then
                        return
                    else
                        warn("❌ Teleport Fehler:", err)
                    end
                else
                    print("⚠️ Keine Server mit freien Plätzen gefunden!")
                end
            end
        else
            warn("❌ Fehler beim Abrufen der Serverliste!")
        end

        print("🔁 Retry in " .. RETRY_DELAY .. "s...")
        task.wait(RETRY_DELAY + math.random())
    end
end

-- =================================================================
-- WAIT WITH BANK CLOSED DETECTION
-- =================================================================
local function waitWithBankDetection(waitTime)
    print("⏳ Warte " .. waitTime .. " Sekunden oder bis Bank Closed erkannt wird...")
    
    local startTime = tick()
    local waitEnd = startTime + waitTime
    
    while tick() < waitEnd do
        if bankClosedDetected then
            print("🔴 Bank Closed erkannt! Starte sofortigen Hop...")
            return true -- Signal to hop immediately
        end
        task.wait(1) -- Check every second
    end
    
    return false -- Normal wait completed
end

-- =================================================================
-- START
-- =================================================================
runMainScript()

-- Wait with bank detection
local shouldHopNow = waitWithBankDetection(WAIT_BEFORE_HOP)

-- If bank was detected during wait, hop immediately
if shouldHopNow then
    hopToRandomServer()
else
    -- Check one more time before hopping
    if isBankClosed() or bankClosedDetected then
        print("🔴 Bank ist geschlossen! Hopping...")
        hopToRandomServer()
    else
        print("✅ Bank scheint verfügbar zu sein. Starte Hop...")
        hopToRandomServer()
    end
end
