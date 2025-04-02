-- crash prevention script(still in beta) updated 4/2/25 finished at 3:49

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
local isInitialized = false

local function loadPreviousLogs()
    pcall(function()
        if isfile("CrashLog.txt") then
            local content = readfile("CrashLog.txt")
            if content and #content > 0 then
                local success, result = pcall(function()
                    return httpService:JSONDecode(content)
                end)
                
                if success and type(result) == "table" then
                    crashLog = result
                    print("[Crash Helper] Loaded " .. #crashLog .. " previous log from before")
                end
            end
        end
    end)
end

local function log(txt)
    local logMsg = os.date("[%X] ") .. txt
    table.insert(crashLog, logMsg)
    print("[Crash Helper] " .. txt)

    pcall(function()
        writefile("CrashLog.txt", httpService:JSONEncode(crashLog))
    end)
end

local function safeCollectGarbage()
    pcall(function()
        local mem = collectgarbage("count") / 1024
        if mem > criticalMemoryThreshold then
            log("A lot of memory being used wyd? : " .. math.floor(mem) .. "MB. Cleaning it up now..")
            task.wait(0.5)
            collectgarbage("collect")
            task.wait(1)
            local newMem = collectgarbage("count") / 1024
            log("Just cleaned your shit memory, its now at" .. math.floor(newMem) .. "MB")
        end
    end)
end

local function monitorMemory()
    while task.wait(10) do
        if not isInitialized then return end
        safeCollectGarbage()
    end
end

local function adjustGraphics()
    if autoGraphics then
        pcall(function()
            local currentQuality = settings().Rendering.QualityLevel
            local newQuality = math.max(1, math.floor(fpsThreshold / 5))
            
            if newQuality < currentQuality then
                settings().Rendering.QualityLevel = newQuality
                log("Gonna lower your graphics too.. " .. newQuality)
            end
        end)
    end
end

local function monitorFPS()
    local lastTime = tick()
    local frameCount = 0
    
    runService.RenderStepped:Connect(function()
        if not isInitialized then return end
        
        frameCount = frameCount + 1
        local currentTime = tick()
        local elapsed = currentTime - lastTime
        
        if elapsed >= 3 then
            local fps = math.floor(frameCount / elapsed)
            frameCount = 0
            lastTime = currentTime
            
            if fps < fpsThreshold then
                fpsDropTime = fpsDropTime + 1
                if fpsDropTime >= 2 then
                    log("WHY IS UR FPSA T " .. fps .. " TRYING TO FIX IT NOW..")
                    adjustGraphics()
                    fpsDropTime = 0
                end
            else
                fpsDropTime = 0
            end
        end
    end)
end

local function monitorFreeze()
    while task.wait(3) do
        if not isInitialized then return end
        
        if tick() - lastHeartbeat > freezeThreshold then
            freezeCount = freezeCount + 1
            log("Oop your game froze " .. freezeCount .. "times")
            if freezeCount >= 3 then
                log("Idk why your game your game crashing so much, gonna be mad unstable now..")
                
                pcall(function()
                    collectgarbage("collect")
                    adjustGraphics()
                end)
                
                freezeCount = 0
            end
        else
            freezeCount = 0
        end
    end
end

local function monitorNetwork()
    while task.wait(5) do
        if not isInitialized then return end
        
        pcall(function()
            local ping = stats.Network:FindFirstChild("Ping") and stats.Network.Ping:GetValue()
            if ping and ping > networkLagThreshold then
                log("VERY BAD SEVER/PING Detected AT " .. math.floor(ping) .. "ms. Connecting may be a lil hard")
            end
        end)
    end
end

local function monitorPlayer()
    while task.wait(10) do
        if not isInitialized then return end
        
        if not players.LocalPlayer then
            log("Can now find LocalPlayer")
            task.wait(2)
            if not players.LocalPlayer then
                log("LocalPlayer still missing bot, game gonna be a little wonky")
            end
        end
    end
end

local function initCrashPrevention()
    pcall(function()
        loadPreviousLogs()

        runService.Heartbeat:Connect(function()
            lastHeartbeat = tick()
        end)
        
        task.spawn(monitorMemory)
        task.spawn(monitorFreeze)
        task.spawn(monitorNetwork)
        task.spawn(monitorPlayer)

        monitorFPS()
        
        isInitialized = true
        log("Crash Prevention Script Loaded.. If you crash your comp just ass icl")
    end)
end

initCrashPrevention()
