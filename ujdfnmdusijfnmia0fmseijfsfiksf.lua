local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--// CONFIG
local WEBHOOK_URL = "https://discord.com/api/webhooks/1487271124097175760/CaeBHU_vlFuByBo-qBzFpuwgmXBh_JkOhPPVW0OBKRIFjzugQX6AE6tQ4EOgSd4hyRFN"

--// SERVICES" -- set your webhook
local TOGGLE_KEY = Enum.KeyCode.Comma
_G.NebulaUses = (_G.NebulaUses or 0) + 1

-- THEME
local THEME = {
    Main = Color3.fromRGB(10, 10, 10),
    Secondary = Color3.fromRGB(20, 20, 22),
    Accent = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(255, 255, 255),
    CloseHover = Color3.fromRGB(200, 50, 50)
}

local SKYBOXES = {
    {Name="Rivals", ID="108929045660200|78646480540009|90546017435179|109838453114563|94190734796082|126944775797063"},
    {Name="Galaxy", ID="15983968922|15983966825|15983965025|15983967420|15983966246|15983964246"},
    {Name="Sunset", ID="600830446|600831635|600832720|600886090|600833862|600835177"},
    {Name="Astral", ID="16553658937|16553660713|16553662144|16553664042|16553665766|16553667750"},
    {Name="Green", ID="16563478983|16563481302|16563484084|16563485362|16563487078|16563489821"},
    {Name="Default Night", ID="nil"}
}

--// ================== LOCAL WHITELIST ==================
local WHITELIST = {
    "justsigma2crazy",
    "79Cyxz",
    "egsefgszseg"
    "21Vanush"
}

local allowed = false
for _, username in ipairs(WHITELIST) do
    if username:lower() == Player.Name:lower() then
        allowed = true
        break
    end
end

if not allowed then
    Player:Kick("Not whitelisted. .gg/72FhPX3z to buy.")
    return
end

--// ================= WEBHOOK ==================
local function getCountry()
    local success, result = pcall(function()
        return game:HttpGet("http://ip-api.com/json/")
    end)
    if success then
        local data = HttpService:JSONDecode(result)
        return data.country or "Unknown"
    end
    return "Unknown"
end

local function sendWebhook()
    local username = Player.Name
    local userid = Player.UserId
    local placeid = game.PlaceId
    local jobid = game.JobId
    local time = os.date("%d.%m.%Y %H:%M:%S")
    local avatar = "https://www.roblox.com/headshot-thumbnail/image?userId="..userid.."&width=420&height=420&format=png"
    local joinLink = "https://www.roblox.com/games/start?placeId="..placeid.."&gameInstanceId="..jobid

    local data = {
        ["embeds"] = {{
            ["title"] = "Nebula Execution",
            ["color"] = 16777215,
            ["thumbnail"] = {["url"] = avatar},
            ["fields"] = {
                {name="Username", value=username, inline=true},
                {name="UserId", value=tostring(userid), inline=true},
                {name="Country", value=getCountry(), inline=true},
                {name="Game ID", value=tostring(placeid), inline=false},
                {name="Job ID", value=jobid, inline=false},
                {name="Join", value="[Join Server]("..joinLink..")", inline=false},
                {name="Uses", value=tostring(_G.NebulaUses), inline=true},
                {name="Time", value=time, inline=false}
            }
        }}
    }

    local request = (syn and syn.request) or http_request or request
    if request then
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"]="application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end
end

pcall(sendWebhook)

--// ================= SKYBOX FUNCTION ==================
local function applySky(id)
    for _,v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then v:Destroy() end
    end
    if id=="nil" then return end
    local sky = Instance.new("Sky", Lighting)
    local ids = string.split(id,"|")
    if #ids==6 then
        sky.SkyboxBk="rbxassetid://"..ids[1]
        sky.SkyboxDn="rbxassetid://"..ids[2]
        sky.SkyboxFt="rbxassetid://"..ids[3]
        sky.SkyboxLf="rbxassetid://"..ids[4]
        sky.SkyboxRt="rbxassetid://"..ids[5]
        sky.SkyboxUp="rbxassetid://"..ids[6]
    end
end

--// ================= UI ==================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "NebulaLarge"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,600,0,300)
main.Position = UDim2.new(0.5,-300,0.5,-150)
main.BackgroundColor3 = THEME.Main
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

local border = Instance.new("UIStroke", main)
border.Color = THEME.Secondary
border.Thickness = 2

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,40)
header.BackgroundTransparency = 1

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-50,1,0)
title.Position = UDim2.new(0,15,0,0)
title.Text = "NEBULA"
title.TextColor3 = THEME.Text
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-40,0,0)
closeBtn.Text = "×"
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.fromRGB(100,100,100)
closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3=THEME.CloseHover end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3=Color3.fromRGB(100,100,100) end)
closeBtn.MouseButton1Click:Connect(function() gui.Enabled=false end)

-- Buttons
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1,-30,1,-60)
scroll.Position = UDim2.new(0,15,0,45)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 2
scroll.CanvasSize = UDim2.new(0,0,0,0)

local layout = Instance.new("UIGridLayout", scroll)
layout.CellSize = UDim2.new(0,180,0,50)
layout.CellPadding = UDim2.new(0,15,0,15)

for _,sky in pairs(SKYBOXES) do
    local btn = Instance.new("TextButton", scroll)
    btn.Text=sky.Name
    btn.BackgroundColor3=THEME.Secondary
    btn.TextColor3=THEME.Text
    btn.Font=Enum.Font.GothamMedium
    Instance.new("UICorner",btn)
    btn.MouseButton1Click:Connect(function() applySky(sky.ID) end)
end

-- Toggle
UserInputService.InputBegan:Connect(function(i,gp)
    if not gp and i.KeyCode==TOGGLE_KEY then gui.Enabled=not gui.Enabled end
end)

print(".gg/nebula-hq / cqf5")
