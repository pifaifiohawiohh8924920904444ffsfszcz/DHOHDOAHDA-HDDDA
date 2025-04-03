--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║                      CRASH PREVENTION SCRIPT                              ║
    ║                                                                           ║
    ║  Version: 2.1.0                                                           ║
    ║  Last Updated: 2024-04-03                                                 ║
    ║  GitHub: https://github.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/blob/main/CrashPrevention.lua                ║
    ║                                                                           ║
    ║  CHANGELOG:                                                               ║
    ║  • Added version tracking and update display                              ║
    ║  • Optimized monitoring to reduce game lag                                ║
    ║  • Improved memory management                                             ║
    ║  • Improved logging system                                                ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- Script Configuration
local CONFIG = {
    VERSION = "2.1.0",
    UPDATE_DATE = "2024-04-03",
    LOG_FILE = "CrashLog.json",
    VERSION_FILE = "CrashPrevVersion.txt",
    GITHUB_URL = "https://github.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/blob/main/CrashPrevention.lua",
    
    -- Performance thresholds
    CRITICAL_MEMORY_MB = 500,
    FREEZE_THRESHOLD_SEC = 5,
    FPS_THRESHOLD = 20,
    NETWORK_LAG_THRESHOLD_MS = 300,
    
    -- Features
    AUTO_GRAPHICS = true,
    SHOW_NOTIFICATIONS = true,
    LOG_TO_FILE = true,
    
    -- Performance settings
    MEMORY_CHECK_INTERVAL = 15,    -- seconds
    FREEZE_CHECK_INTERVAL = 5,     -- seconds
    NETWORK_CHECK_INTERVAL = 10,   -- seconds
    PLAYER_CHECK_INTERVAL = 15,    -- seconds
    MAX_LOG_ENTRIES = 100
}

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")

-- Variables
local LocalPlayer = Players.LocalPlayer
local LastHeartbeat = tick()
local CrashLog = {}
local FpsDropTime = 0
local FreezeCount = 0
local IsInitialized = false
local StartTime = os.time()
local LastVersionSeen = ""
local MonitoringTasks = {}

-- Utility Functions
local function CheckForUpdate()
    pcall(function()
        if isfile(CONFIG.VERSION_FILE) then
            LastVersionSeen = readfile(CONFIG.VERSION_FILE)
        end
        
        -- Save current version
        writefile(CONFIG.VERSION_FILE, CONFIG.VERSION)
        
        -- Check if this is a new version
        return LastVersionSeen ~= CONFIG.VERSION
    end)
    
    return false
end

local function DisplayUpdateMessage(isNewUpdate)
    local header = [[
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                      CRASH PREVENTION SCRIPT                              ║
║                                                                           ║]]
    
    local version = string.format("║  Version: %-63s ║", CONFIG.VERSION)
    local updated = string.format("║  Last Updated: %-57s ║", CONFIG.UPDATE_DATE)
    local github = string.format("║  GitHub: %-64s ║", CONFIG.GITHUB_URL)
    
    local footer = [[
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝]]

    local updateInfo = ""
    if isNewUpdate then
        updateInfo = [[
║                                                                           ║
║  ✨ NEW UPDATE INSTALLED! ✨                                              ║
║  • Added version tracking and update display                              ║
║  • Optimized monitoring to reduce game lag                                ║
║  • Improved memory management                                             ║
║  • Enhanced logging system                                                ║]]
    end
    
    local message = header .. "\n" .. version .. "\n" .. updated .. "\n" .. github .. "\n" .. updateInfo .. "\n" .. footer
    
    print(message)
    
    if isNewUpdate and CONFIG.SHOW_NOTIFICATIONS then
        StarterGui:SetCore("SendNotification", {
            Title = "Crash Prevention Updated!",
            Text = "Version " .. CONFIG.VERSION .. " installed",
            Duration = 10
        })
    end
end

local function FormatTime(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

local function FormatMemory(memoryMB)
    return string.format("%.2f MB", memoryMB)
end

local function LoadPreviousLogs()
    pcall(function()
        if CONFIG.LOG_TO_FILE and isfile(CONFIG.LOG_FILE) then
            local content = readfile(CONFIG.LOG_FILE)
            if content and #content > 0 then
                local success, result = pcall(function()
                    return HttpService:JSONDecode(content)
                end)
                if success and type(result) == "table" then
                    CrashLog = result
                    
                    -- Trim log if it's too large
                    if #CrashLog > CONFIG.MAX_LOG_ENTRIES then
                        local newLog = {}
                        for i = #CrashLog - CONFIG.MAX_LOG_ENTRIES + 1, #CrashLog do
                            table.insert(newLog, CrashLog[i])
                        end
                        CrashLog = newLog
                    end
                end
            end
        end
    end)
end

local function SaveLogs()
    if not CONFIG.LOG_TO_FILE then return end
    
    pcall(function()
        writefile(CONFIG.LOG_FILE, HttpService:JSONEncode(CrashLog))
    end)
end

local function NotifyUser(message, duration)
    if not CONFIG.SHOW_NOTIFICATIONS then return end
    
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Crash Prevention",
            Text = message,
            Duration = duration or 5
        })
    end)
end

local function Log(category, message, level)
    level = level or "INFO"
    
    local logEntry = {
        Timestamp = os.time(),
        FormattedTime = FormatTime(os.time()),
        Category = category,
        Message = message,
        Level = level,
        SessionTime = string.format("%02d:%02d:%02d", 
            math.floor((os.time() - StartTime) / 3600),
            math.floor((os.time() - StartTime) % 3600 / 60),
            (os.time() - StartTime) % 60
        ),
        Version = CONFIG.VERSION
    }
    
    table.insert(CrashLog, logEntry)
    
    -- Format console output with category and level
    local prefix = "[Crash Helper]"
    local formattedMessage = string.format("%s [%s-%s] %s", 
        prefix,
        logEntry.Category, 
        logEntry.Level, 
        logEntry.Message
    )
    
    print(formattedMessage)
    
    -- Show notification for warnings and errors
    if level == "WARNING" or level == "ERROR" then
        NotifyUser(message, level == "ERROR" and 8 or 5)
    end
    
    -- Save logs periodically (not on every log to reduce file operations)
    if #CrashLog % 5 == 0 then
        SaveLogs()
    end
end

-- Core Functionality
local function SafeCollectGarbage()
    pcall(function()
        local mem = collectgarbage("count") / 1024
        if mem > CONFIG.CRITICAL_MEMORY_MB then
            Log("Memory", "High memory usage detected: " .. FormatMemory(mem), "WARNING")
            
            -- Delay collection slightly to not cause stutters
            task.delay(0.5, function()
                collectgarbage("collect")
                
                task.wait(1)
                local newMem = collectgarbage("count") / 1024
                Log("Memory", "Memory cleaned: " .. FormatMemory(newMem), "INFO")
            end)
        end
    end)
end

local function AdjustGraphics()
    if not CONFIG.AUTO_GRAPHICS then return end
    
    pcall(function()
        local currentQuality = settings().Rendering.QualityLevel
        local newQuality = math.max(1, math.floor(CONFIG.FPS_THRESHOLD / 5))
        
        if newQuality < currentQuality then
            settings().Rendering.QualityLevel = newQuality
            Log("Graphics", "Lowered graphics quality to level " .. newQuality, "WARNING")
        end
    end)
end

local function GetSystemInfo()
    local info = {}
    
    pcall(function()
        info.MemoryUsage = FormatMemory(collectgarbage("count") / 1024)
        info.FPS = math.floor(1 / RunService.RenderStepped:Wait())
        info.Ping = Stats.Network:FindFirstChild("Ping") and Stats.Network.Ping:GetValue() or "N/A"
        info.GraphicsQuality = settings().Rendering.QualityLevel
        info.PlaceId = game.PlaceId
        
        pcall(function()
            info.GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        end)
    end)
    
    return info
end

-- Optimized Monitoring Functions
local function CreateMonitorTask(name, interval, callback)
    local task = {
        Name = name,
        LastRun = 0,
        Interval = interval,
        Callback = callback,
        IsRunning = false
    }
    
    table.insert(MonitoringTasks, task)
    return task
end

local function RunMonitoringTasks()
    RunService.Heartbeat:Connect(function()
        if not IsInitialized then return end
        
        -- Update heartbeat timestamp (for freeze detection)
        LastHeartbeat = tick()
        
        -- Run tasks that are due
        local currentTime = tick()
        for _, task in ipairs(MonitoringTasks) do
            if currentTime - task.LastRun >= task.Interval and not task.IsRunning then
                task.IsRunning = true
                
                -- Run the task in a protected call
                task.LastRun = currentTime
                task.Callback(function()
                    task.IsRunning = false
                end)
            end
        end
    end)
end

-- Monitoring Functions
local function SetupMemoryMonitoring()
    CreateMonitorTask("MemoryMonitor", CONFIG.MEMORY_CHECK_INTERVAL, function(done)
        SafeCollectGarbage()
        done()
    end)
end

local function SetupFPSMonitoring()
    local lastTime = tick()
    local frameCount = 0
    
    RunService.RenderStepped:Connect(function()
        if not IsInitialized then return end
        
        frameCount = frameCount + 1
        local currentTime = tick()
        local elapsed = currentTime - lastTime
        
        if elapsed >= 3 then
            local fps = math.floor(frameCount / elapsed)
            frameCount = 0
            lastTime = currentTime
            
            if fps < CONFIG.FPS_THRESHOLD then
                FpsDropTime = FpsDropTime + 1
                if FpsDropTime >= 2 then
                    Log("Performance", "Low FPS detected: " .. fps .. " FPS", "WARNING")
                    AdjustGraphics()
                    FpsDropTime = 0
                end
            else
                FpsDropTime = 0
            end
        end
    end)
end

local function SetupFreezeMonitoring()
    CreateMonitorTask("FreezeMonitor", CONFIG.FREEZE_CHECK_INTERVAL, function(done)
        if tick() - LastHeartbeat > CONFIG.FREEZE_THRESHOLD_SEC then
            FreezeCount = FreezeCount + 1
            Log("Stability", "Game freeze detected (" .. FreezeCount .. " occurrences)", "WARNING")
            
            if FreezeCount >= 3 then
                Log("Stability", "Multiple freezes detected, applying emergency fixes", "ERROR")
                
                task.spawn(function()
                    collectgarbage("collect")
                    AdjustGraphics()
                    FreezeCount = 0
                end)
            end
        else
            FreezeCount = math.max(0, FreezeCount - 0.5) -- Gradually reduce freeze count if stable
        end
        
        done()
    end)
end

local function SetupNetworkMonitoring()
    CreateMonitorTask("NetworkMonitor", CONFIG.NETWORK_CHECK_INTERVAL, function(done)
        pcall(function()
            local ping = Stats.Network:FindFirstChild("Ping") and Stats.Network.Ping:GetValue()
            if ping and ping > CONFIG.NETWORK_LAG_THRESHOLD_MS then
                Log("Network", "High network latency: " .. math.floor(ping) .. "ms", "WARNING")
            end
        end)
        
        done()
    end)
end

local function SetupPlayerMonitoring()
    CreateMonitorTask("PlayerMonitor", CONFIG.PLAYER_CHECK_INTERVAL, function(done)
        if not Players.LocalPlayer then
            Log("Player", "LocalPlayer reference lost", "WARNING")
            
            task.delay(2, function()
                if not Players.LocalPlayer then
                    Log("Player", "LocalPlayer still missing, game stability compromised", "ERROR")
                end
            end)
        end
        
        done()
    end)
end

-- Commands (for debugging and control)
local function RegisterCommands()
    local function ProcessCommand(cmd)
        local parts = {}
        for part in cmd:gmatch("%S+") do
            table.insert(parts, part:lower())
        end
        
        if parts[1] == "/crashhelp" then
            Log("Command", "Available commands: /crashstats, /crashclean, /crashlog, /crashversion", "INFO")
        elseif parts[1] == "/crashstats" then
            local info = GetSystemInfo()
            Log("Command", "Memory: " .. info.MemoryUsage .. ", FPS: " .. (info.FPS or "Unknown") .. ", Ping: " .. info.Ping, "INFO")
        elseif parts[1] == "/crashclean" then
            collectgarbage("collect")
            Log("Command", "Manual memory cleanup performed", "INFO")
        elseif parts[1] == "/crashlog" then
            Log("Command", "Saving crash log...", "INFO")
            SaveLogs()
        elseif parts[1] == "/crashversion" then
            DisplayUpdateMessage(false)
        end
    end
    
    pcall(function()
        if LocalPlayer then
            LocalPlayer.Chatted:Connect(function(msg)
                if msg:sub(1, 1) == "/" then
                    ProcessCommand(msg)
                end
            end)
        end
    end)
end

-- Initialization
local function InitCrashPrevention()
    pcall(function()
        -- Check for updates and display version info
        local isNewUpdate = CheckForUpdate()
        DisplayUpdateMessage(isNewUpdate)
        
        -- Load previous logs
        LoadPreviousLogs()
        
        -- Log session start with system info
        local sysInfo = GetSystemInfo()
        Log("System", "Session started in game: " .. (sysInfo.GameName or "Unknown"), "INFO")
        Log("System", "Memory: " .. sysInfo.MemoryUsage .. ", FPS: " .. (sysInfo.FPS or "Unknown"), "INFO")
        
        -- Set up monitoring systems
        SetupMemoryMonitoring()
        SetupFreezeMonitoring()
        SetupNetworkMonitoring()
        SetupPlayerMonitoring()
        SetupFPSMonitoring()
        
        -- Start the monitoring engine
        RunMonitoringTasks()
        
        -- Register chat commands
        RegisterCommands()
        
        IsInitialized = true
        Log("System", "Crash Prevention v" .. CONFIG.VERSION .. " initialized successfully", "INFO")
        
        if isNewUpdate then
            NotifyUser("Crash Prevention v" .. CONFIG.VERSION .. " activated!", 5)
        else
            NotifyUser("Crash Prevention active", 3)
        end
    end)
end

-- Performance optimization for script shutdown
local function CleanupOnShutdown()
    pcall(function()
        if IsInitialized then
            Log("System", "Session ending, final save", "INFO")
            SaveLogs()
            
            -- Clear monitoring tasks
            MonitoringTasks = {}
            
            -- Force garbage collection
            collectgarbage("collect")
        end
    end)
end

-- Run the script
InitCrashPrevention()

-- Save logs when script is unloaded
game:BindToClose(CleanupOnShutdown)
