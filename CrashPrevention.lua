local runService = game:GetService("RunService")
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")

local lastHeartbeat = tick()
local crashLog = {}
local fpsDropTime = 0
local memOverloadTime = 0

local function log(txt)
    table.insert(crashLog, txt)
    print("[Crash Helper] " .. txt)
    pcall(function()
        writefile("CrashLog.txt", httpService:JSONEncode(crashLog))
    end)
end

local function memCheck()
    while task.wait(2) do
        local mem = collectgarbage("count") / 1024
        if mem > 500 then
            memOverloadTime = memOverloadTime + 1
            log("Memory too high: " .. math.floor(mem) .. "MB")
            collectgarbage()
            log("Memory cleaned")
            if memOverloadTime >= 3 then
                log("Memory keeps overloading, possible memory leak")
                memOverloadTime = 0
            end
        else
            memOverloadTime = 0
        end
    end
end

local function freezeCheck()
    while task.wait(1) do
        if tick() - lastHeartbeat > 4 then
            log("Game freeze or lag spike detected")
        end
    end
end

local function fpsCheck()
    while task.wait(1) do
        local fps = math.floor(1 / runService.RenderStepped:Wait())
        if fps < 20 then
            fpsDropTime = fpsDropTime + 1
            if fpsDropTime >= 3 then
                log("FPS low for too long: " .. fps)
                fpsDropTime = 0
            end
        else
            fpsDropTime = 0
        end
    end
end

local function playerCheck()
    while task.wait(3) do
        if not players.LocalPlayer then
            log("Player missing, Roblox may crash soon")
        end
    end
end

runService.Heartbeat:Connect(function()
    lastHeartbeat = tick()
end)

task.spawn(memCheck)
task.spawn(freezeCheck)
task.spawn(fpsCheck)
task.spawn(playerCheck)

log("Crash Helper ready")
