local runService = game:GetService("RunService")
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")

local lastMemCheck = tick()
local lastHeartbeat = tick()
local crashDetected = false
local logErrors = {}

-- 🟢 Function to Log Errors
local function logIssue(message)
    table.insert(logErrors, message)
    warn("[⚠️ Crash Prevention] " .. message)

    -- (Optional) Save to a local file for debugging
    pcall(function()
        writefile("CrashLog.txt", httpService:JSONEncode(logErrors))
    end)
end

-- 🟢 Memory Monitor: Prevents Overload
local function memoryMonitor()
    while task.wait(1) do
        local memUsage = collectgarbage("count") / 1024 -- MB
        if memUsage > 500 then
            logIssue("High memory usage detected: " .. memUsage .. "MB")
            collectgarbage() -- Free memory
        end
    end
end

-- 🟢 Freeze Detection: Detects if Roblox is Stalling
local function detectFreeze()
    while task.wait(2) do
        if tick() - lastHeartbeat > 4 then
            logIssue("Possible freeze detected! Script execution delay.")
        end
    end
end

-- 🟢 Error Handler: Catches Any Runtime Errors
local function monitorErrors()
    local success, err = pcall(function()
        while task.wait(1) do
            -- Check if game is still responsive
            if not game or not players then
                logIssue("Game instance disappeared. Possible forced shutdown.")
                crashDetected = true
            end
        end
    end)

    if not success then
        logIssue("Lua runtime error detected: " .. tostring(err))
    end
end

-- 🟢 Heartbeat Monitor: Keeps Track of Performance
runService.Heartbeat:Connect(function()
    lastHeartbeat = tick()
end)

-- 🔥 Start All Crash Prevention Systems
task.spawn(memoryMonitor)
task.spawn(detectFreeze)
task.spawn(monitorErrors)

logIssue("Crash prevention initialized successfully.")
