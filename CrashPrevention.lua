local runService = game:GetService("RunService")
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local lighting = game:GetService("Lighting")
local stats = game:GetService("Stats")

local localPlayer = players.LocalPlayer
local lastHeartbeat = tick()
local crashLog = {}
local fpsDropTime = 0
local memOverloadTime = 0
local freezeCount = 0
local criticalMemoryThreshold = 500
local freezeThreshold = 5
local fpsThreshold = 20
local networkLagThreshold = 300
local autoGraphics = true 

local function log(txt)
    local logMsg = os.date("[%X] ") .. txt
    table.insert(crashLog, logMsg)
    print("[Crash Helper] " .. txt)
    pcall(function()
        writefile("CrashLog.txt", httpService:JSONEncode(crashLog))
    end)
end

local function safeCollectGarbage()
    local mem = collectgarbage("count") / 1024
    if mem > criticalMemoryThreshold then
        log("Your memory mad high " .. math.floor(mem) .. "MB. Cleaning up ur shit now..")
        task.wait(0.5)
        collectgarbage()
        task.wait(1)
        log("Cleaning your shitty memory, its now at " .. math.floor(collectgarbage("count") / 1024) .. "MB")
    end
end

local function monitorMemory()
    while task.wait(10) do 
        safeCollectGarbage()
    end
end

local function adjustGraphics()
    if autoGraphics then
        local quality = math.max(1, math.floor(fpsThreshold / 5))
        settings().Rendering.QualityLevel = quality
        log("Lowering your graphics now as i speak: " .. quality)
    end
end

local function monitorFPS()
    while task.wait(3) do 
        local fps = math.floor(1 / runService.RenderStepped:Wait())
        if fps < fpsThreshold then
            fpsDropTime = fpsDropTime + 1
            if fpsDropTime >= 2 then
                log("Very low of the fps detected: " .. fps .. " FPS. Trying to fix it now")
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
                log("Why ur game freezing so much are u in a freezer(ha u get it cause cold freeze yeah imma shutup")
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
            log("God damn high ass ping: " .. math.floor(ping) .. "ms. Fix ur connection nn")
        end
    end
end

local function monitorPlayer()
    while task.wait(10) do 
        if not players.LocalPlayer then
            log("Local player missing, might crash.")
            task.wait(2)
            if not players.LocalPlayer then
                log("Your game prob crashed, reset roblox now bot")
            end
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

log("Crash Prevention System v1.5 Loaded. So now if u crash ur just ass lmao")
