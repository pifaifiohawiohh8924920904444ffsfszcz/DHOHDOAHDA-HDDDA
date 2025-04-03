-- Crash Prevention Script v2.0
-- Last updated: 4/10/2024
-- still in beta btw
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
local lastLogTime = 0
local logCooldown = 60
local lastLogMessages = {}
local scriptStartTime = os.time()

local SETTINGS = {
    LOG_TO_CONSOLE = false,
    LOG_TO_FILE = true,
    LOG_FILE_PATH = "VapeCrashLogs.txt",
    MAX_LOG_ENTRIES = 100
}

local FUNNY_MESSAGES = {
    memory = {
        "Yo memory's chonkier than my cat after Thanksgiving dinner! Cleaning up...",
        "Your RAM's having a buffet and forgot to pay the bill! Kicking it out...",
        "Memory leak bigger than the hole in my sneakers! Patching it up...",
        "Your PC's memory is hoarding data like I hoard snacks! Time for cleanup...",
        "RAM's more stuffed than my locker at the end of the school year! Emptying it..."
    },
    fps = {
        "FPS so low even a turtle would say 'bruh, speed up'! Fixing it...",
        "Your frames are lagging harder than my brain during math tests! Boosting...",
        "Game's running like me trying to finish the mile run with untied shoes! Helping out...",
        "Frames dropping faster than my phone when my crush texts me! Saving you...",
        "Your FPS is more dead than my TikTok career! Reviving it..."
    },
    freeze = {
        "Game just froze colder than that time I got locked out during winter! Thawing...",
        "Roblox pulled a 'my dad when I ask for Robux' and disappeared! Bringing it back...",
        "Your game's stiffer than my hair with too much gel! Loosening things up...",
        "Game froze like my brain during a pop quiz! Unfreezing...",
        "Roblox just went AFK without telling anyone! Dragging it back..."
    },
    network = {
        "Your WiFi's weaker than my excuses for not doing the dishes! Good luck...",
        "Ping higher than my mom's voice when I forget to take out the trash!",
        "Your internet's more unstable than a Jenga tower in an earthquake!",
        "Connection's laggier than school Chromebooks running Roblox! Yikes...",
        "Your ping's higher than the school's basketball hoop! Not looking good..."
    }
}

local function getFunnyMessage(category)
    local messages = FUNNY_MESSAGES[category]
    if messages then
        return messages[math.random(1, #messages)]
    end
    return "Something weird happened. Fixing it..."
end

local function getFormattedDateTime()
    return os.date("%m/%d/%Y %H:%M:%S")
end

local function canLogMessage(message, category)
    local currentTime = os.time()
    
    if lastLogMessages[category] and currentTime - lastLogMessages[category].time < logCooldown then
        return false
    end
    
    lastLogMessages[category] = {
        message = message,
        time = currentTime
    }
    
    return true
end

local function loadPreviousLogs()
    pcall(function()
        if isfile(SETTINGS.LOG_FILE_PATH) then
            local content = readfile(SETTINGS.LOG_FILE_PATH)
            if content and #content > 0 then
                local success, result = pcall(function()
                    return httpService:JSONDecode(content)
                end)
                
                if success and type(result) == "table" then
                    if #result > SETTINGS.MAX_LOG_ENTRIES then
                        local trimmedLogs = {}
                        for i = #result - SETTINGS.MAX_LOG_ENTRIES + 1, #result do
                            table.insert(trimmedLogs, result[i])
                        end
                        crashLog = trimmedLogs
                    else
                        crashLog = result
                    end
                end
            end
        end
    end)
end

local function log(txt, category)
    if not canLogMessage(txt, category or "general") then
        return
    end
    
    local dateTime = getFormattedDateTime()
    local logMsg = "[" .. dateTime .. "] " .. txt
    
    table.insert(crashLog, logMsg)
    
    if SETTINGS.LOG_TO_CONSOLE then
        print("[Vape Crash Helper] " .. txt)
    end
    
    if SETTINGS.LOG_TO_FILE then
        pcall(function()
            if #crashLog > SETTINGS.MAX_LOG_ENTRIES then
                local trimmedLogs = {}
                for i = #crashLog - SETTINGS.MAX_LOG_ENTRIES + 1, #crashLog do
                    table.insert(trimmedLogs, crashLog[i])
                end
                crashLog = trimmedLogs
            end
            
            writefile(SETTINGS.LOG_FILE_PATH, httpService:JSONEncode(crashLog))
        end)
    end
end

local function safeCollectGarbage()
    pcall(function()
        local mem = collectgarbage("count") / 1024
        if mem > criticalMemoryThreshold then
            local funnyMsg = getFunnyMessage("memory")
            log(funnyMsg .. " (" .. math.floor(mem) .. "MB)", "memory")
            
            for i = 1, 5 do
                collectgarbage("step", 250)
                task.wait(0.1)
            end
            
            collectgarbage("collect")
            task.wait(0.5)
            
            local newMem = collectgarbage("count") / 1024
            log("Memory cleaned up: " .. math.floor(mem) .. "MB → " .. math.floor(newMem) .. "MB", "memory")
        end
    end)
end

local function adjustGraphics()
    if not autoGraphics then return end
    
    pcall(function()
        local currentQuality = settings().Rendering.QualityLevel
        local fps = stats:GetValue("fps") or 60
        
        local targetQuality = currentQuality
        if fps < fpsThreshold then
            if fps < fpsThreshold * 0.5 then
                targetQuality = math.max(1, currentQuality - 2)
            else
                targetQuality = math.max(1, currentQuality - 1)
            end
            
            if targetQuality < currentQuality then
                settings().Rendering.QualityLevel = targetQuality
                log("Graphics lowered to level " .. targetQuality .. " to help your FPS", "fps")
            end
        end
    end)
end

local function monitorFPS()
    local lastTime = tick()
    local frameCount = 0
    
    runService.RenderStepped:Connect(function()
        if not isInitialized then return end
        
        frameCount = frameCount + 1
        local currentTime = tick()
        local elapsed = currentTime - lastTime
        
        if elapsed >= 2 then
            local fps = math.floor(frameCount / elapsed)
            frameCount = 0
            lastTime = currentTime
            
            if fps < fpsThreshold then
                fpsDropTime = fpsDropTime + 1
                if fpsDropTime >= 2 then
                    local funnyMsg = getFunnyMessage("fps")
                    log(funnyMsg .. " (FPS: " .. fps .. ")", "fps")
                    adjustGraphics()
                    
                    pcall(function()
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("ParticleEmitter") then
                                v.Enabled = false
                            end
                        end
                        
                        lighting.GlobalShadows = false
                    end)
                    
                    fpsDropTime = 0
                end
            else
                fpsDropTime = 0
            end
        end
    end)
end

local function monitorFreeze()
    while task.wait(2) do
        if not isInitialized then return end
        
        if tick() - lastHeartbeat > freezeThreshold then
            freezeCount = freezeCount + 1
            local funnyMsg = getFunnyMessage("freeze")
            log(funnyMsg .. " (Freeze #" .. freezeCount .. ")", "freeze")
            
            if freezeCount >= 3 then
                log("Multiple freezes detected. Performing emergency cleanup...", "freeze")
                
                pcall(function()
                    collectgarbage("collect")
                    adjustGraphics()
                    
                    settings().Rendering.QualityLevel = 1
                    
                    pcall(function() 
                        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
                        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
                    end)
                end)
                
                freezeCount = 0
            end
        else
            if freezeCount > 0 and tick() % 30 < 1 then
                freezeCount = math.max(0, freezeCount - 1)
            end
        end
    end
end

local function monitorNetwork()
    local highPingCount = 0
    
    while task.wait(5) do
        if not isInitialized then return end
        
        pcall(function()
            local ping = stats.Network:FindFirstChild("Ping") and stats.Network.Ping:GetValue()
            if ping and ping > networkLagThreshold then
                highPingCount = highPingCount + 1
                
                if highPingCount >= 3 then
                    local funnyMsg = getFunnyMessage("network")
                    log(funnyMsg .. " (Ping: " .. math.floor(ping) .. "ms)", "network")
                    highPingCount = 0
                end
            else
                highPingCount = math.max(0, highPingCount - 1)
            end
        end)
    end
end

local function monitorPlayer()
    while task.wait(10) do
        if not isInitialized then return end
        
        if not players.LocalPlayer then
            log("LocalPlayer missing - this might cause issues with scripts", "player")
            task.wait(2)
            if not players.LocalPlayer then
                log("LocalPlayer still missing after waiting. Game functionality may be limited.", "player")
            end
        end
    end
end

local function initCrashPrevention()
    pcall(function()
        log("Vape Crash Prevention v2.0 loaded. Ready to keep things running smooth!", "init")
        
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
    end)
end

initCrashPrevention()

return {
    forceGarbageCollection = function()
        safeCollectGarbage()
    end,
    setAutoGraphics = function(enabled)
        autoGraphics = enabled
    end,
    getStatus = function()
        return {
            uptime = os.time() - scriptStartTime,
            freezeCount = freezeCount,
            isHealthy = (freezeCount < 2)
        }
    end
}
