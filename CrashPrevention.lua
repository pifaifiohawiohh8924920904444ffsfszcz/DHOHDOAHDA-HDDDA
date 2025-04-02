local runService = game:GetService("RunService")
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local stats = game:GetService("Stats")
local lighting = game:GetService("Lighting")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local networkClient = game:GetService("NetworkClient")

local localPlayer = players.LocalPlayer
local lastHeartbeat = tick()
local crashLog = {}
local fpsDropTime = 0
local freezeCount = 0
local criticalMemoryThreshold = 400
local freezeThreshold = 5
local fpsThreshold = 30
local pingThreshold = 200
local autoGraphics = true

local function log(txt)
    local logMsg = os.date("[%X] ") .. txt
    table.insert(crashLog, logMsg)
    print("[Crash Prevention] " .. txt)
    pcall(function()
        writefile("CrashLog.txt", httpService:JSONEncode(crashLog))
    end)
end

local function cleanMemory()
    local mem = collectgarbage("count") / 1024
    if mem > criticalMemoryThreshold then
        log("Memory high at " .. math.floor(mem) .. "MB. Running deep clean...")
        task.wait(0.2)
        collectgarbage()
        task.wait(0.3)
        log("Memory cleaned: Now at " .. math.floor(collectgarbage("count") / 1024) .. "MB")
    end
end

local function monitorMemory()
    while task.wait(5) do 
        cleanMemory()
    end
end

local function boostFPS()
    log("Activating FPS Boost...")

    setfpscap(75)
    settings().Rendering.QualityLevel = 1

    pcall(function()
        lighting.GlobalShadows = false
        lighting.FogEnd = 99999
        lighting.Brightness = 1
        settings().Rendering.EagerBulkExecution = true
        settings().Rendering.FrameSkip = true
    end)

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Beam") then
            v.Enabled = false
        elseif v:IsA("Texture") or v:IsA("Decal") then
            v.Transparency = 1
        end
    end

    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
    settings().Physics.AllowSleep = true

    log("FPS Boost Activated!")
end

local function monitorFPS()
    while task.wait(3) do 
        local fps = math.floor(1 / runService.RenderStepped:Wait())
        if fps < fpsThreshold then
            fpsDropTime = fpsDropTime + 1
            if fpsDropTime >= 2 then
                log("Low FPS detected: " .. fps .. " FPS. Optimizing performance...")
                boostFPS()
                fpsDropTime = 0
            end
        else
            fpsDropTime = 0
        end
    end
end

local function reducePing()
    log("Applying Ping Stabilization...")

    settings().Network.IncomingReplicationLag = 0
    settings().Network.UsePhysicsBasedPrediction = false

    pcall(function()
        networkClient:SetOutgoingKBPSLimit(4000)
    end)

    log("Ping Optimization Applied!")
end

local function monitorNetwork()
    while task.wait(5) do
        local ping = stats.Network:FindFirstChild("Ping") and stats.Network.Ping:GetValue()
        if ping and ping > pingThreshold then
            log("High ping detected: " .. math.floor(ping) .. "ms. Optimizing connection...")
            reducePing()
        end
    end
end

local function monitorFreeze()
    while task.wait(3) do 
        if tick() - lastHeartbeat > freezeThreshold then
            freezeCount = freezeCount + 1
            log("Freeze detected! Count: " .. freezeCount)
            if freezeCount >= 2 then
                log("Game freezing frequently. Applying stability fixes...")
                boostFPS()
                reducePing()
                freezeCount = 0
            end
        else
            freezeCount = 0
        end
    end
end

local function preventScriptLag()
    log("Applying Script Performance Optimization...")

    local function secureRemote(remote)
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function() return end
            remote.OnClientEvent:Connect(function() end)
        end
    end

    for _, v in pairs(replicatedStorage:GetDescendants()) do
        secureRemote(v)
    end

    replicatedStorage.DescendantAdded:Connect(secureRemote)

    log("Script Optimization Applied!")
end

local function disableHeavyParts()
    log("Removing excessive game objects...")
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Size.Magnitude > 100 then
            obj.CanCollide = false
            obj.Transparency = 1
        elseif obj:IsA("MeshPart") then
            obj.RenderFidelity = Enum.RenderFidelity.Automatic
        end
    end
    
    log("Heavy object optimization complete!")
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

runService.Heartbeat:Connect(function()
    lastHeartbeat = tick()
end)

task.spawn(monitorMemory)
task.spawn(monitorFPS)
task.spawn(monitorFreeze)
task.spawn(monitorNetwork)
task.spawn(monitorPlayer)
task.spawn(preventScriptLag)
task.spawn(disableHeavyParts)

log("Crash Prevention v3.0 Loaded - The Ultimate Performance & Stability Booster!")
