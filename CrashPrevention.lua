local runService = game:GetService("RunService")
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local teleportService = game:GetService("TeleportService")
local lighting = game:GetService("Lighting")
local stats = game:GetService("Stats")

local localPlayer = players.LocalPlayer
local lastHeartbeat = tick()
local crashLog = {}
local fpsDropTime = 0
local memOverloadTime = 0
local freezeCount = 0
local criticalMemoryThreshold = 500 -- Clears memory if over 500MB
local freezeThreshold = 5 -- Detects freeze if no heartbeat for 5 secs
local fpsThreshold = 20 -- FPS alert threshold
local networkLagThreshold = 300 -- Ping threshold in ms
local autoGraphics = true -- Auto adjusts graphics if enabled

local function log(txt)
    local logMsg = os.date("[%X] ") .. txt
    table.insert(crashLog, logMsg)
    print("[Crash Helper] " .. txt)
    pcall(function()
        writefile("CrashLog.txt", httpService:JSONEncode(crashLog))
    end)
end

local function safeCollectGarbage()
    local mem = collectgarbage("count") / 1024 -- Convert to MB
    if mem > criticalMemoryThreshold then
        log("Memory high at " .. math.floor(mem) .. "MB. Cleaning up...")
        task.wait(0.5)
        collectgarbage()
        task.wait(1)
        log("Memory cleaned: Now at " .. math.floor(collectgarbage("count") / 1024) .. "MB")
    end
end

local function monitorMemory()
    while task.wait(10) do 
        safeCollectGarbage()
    end
end

local function adjustGraphics()
    if autoGraphics then
        local quality = math.max(1, math.floor(fpsThreshold / 5)) -- Adjust quality dynamically
        settings().Rendering.QualityLevel = quality
        log("Graphics lowered to: " .. quality)
    end
end

local function monitorFPS()
    while task.wait(3) do 
        local fps = math.floor(1 / runService.RenderStepped:Wait())
        if fps < fpsThreshold then
            fpsDropTime = fpsDropTime + 1
            if fpsDropTime >= 2 then
                log("Low FPS detected: " .. fps .. " FPS. Adjusting settings...")
                adjustGraphics()
                fpsDropTime = 0
            end
        else
            fpsDropTime = 0
        end
    end
end

local function monitorFreeze()
    while task.wait(3) do 
        if tick() - lastHeartbeat > freezeThreshold then
            freezeCount = freezeCount + 1
            log("Freeze detected! Count: " .. freezeCount)
            if freezeCount >= 3 then
                log("Game is freezing often! Try lowering graphics or restarting.")
                freezeCount = 0
            end
        else
            freezeCount = 0
        end
    end
end

local function monitorNetwork()
    while task.wait(5) do
        local ping = stats.Network:FindFirstChild("Ping") and stats.Network.Ping:GetValue()
        if ping and ping > networkLagThreshold then
            log("High ping detected: " .. math.floor(ping) .. "ms. Check your connection.")
        end
    end
end

local function monitorPlayer()
    while task.wait(10) do 
        if not players.LocalPlayer then
            log("Local player missing, might crash.")
            task.wait(2)
            if not players.LocalPlayer then
                log("Game might have crashed! Restart Roblox if necessary.")
            end
        end
    end
end

local function autoReconnect()
    while task.wait(15) do
        if not localPlayer or not localPlayer.Parent then
            log("Game crash detected. Reconnecting in 5 seconds...")
            task.wait(5)
            teleportService:Teleport(game.PlaceId)
        end
    end
end

runService.Heartbeat:Connect(function()
    lastHeartbeat = tick()
end)

task.spawn(monitorMemory)
task.spawn(monitorFPS)
task.spawn(monitorFreeze)
task.spawn(monitorNetwork)
task.spawn(monitorPlayer)
task.spawn(autoReconnect)

log("Crash Prevention System v1.5 Loaded. Now with smarter detection and self-healing!")
