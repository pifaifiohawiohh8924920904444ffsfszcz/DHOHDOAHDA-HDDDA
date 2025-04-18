-- still in beta btw 
-- updated on 4/6/25
-- changed name to anti-crash

local AntiCrash = {}
local OriginalFunctions = {}
local ProtectedInstances = {}
local ErrorCount = 0
local LastErrorTime = 0
local MaxErrorsPerMinute = 30
local IsEnabled = true
local MemoryThreshold = 1800000000
local LastMemoryCheck = 0
local MemoryCheckInterval = 5
local Executor = identifyexecutor and identifyexecutor() or "Unknown"

-- Debugging function to print AntiCrash and its methods
print("AntiCrash table initialized:", AntiCrash)
print("AntiCrash:Enable function exists:", AntiCrash.Enable)

local function SafePcall(fn, ...)
	local s, r = pcall(fn, ...)
	return s and r or nil
end

local function HookMethod(instance, methodName, customFunction)
    if not instance or typeof(instance) ~= "Instance" then return end
    if not OriginalFunctions[instance] then OriginalFunctions[instance] = {} end
    local originalFunction = instance[methodName]
    OriginalFunctions[instance][methodName] = originalFunction

    -- Use a named function for the callback
    instance[methodName] = function(...)
        local args = {...}  -- Capture all arguments
        local success, result = pcall(function() return customFunction(originalFunction, unpack(args)) end)
        if not success and IsEnabled then
            ErrorCount = ErrorCount + 1
            if tick() - LastErrorTime > 60 then
                ErrorCount = 1
                LastErrorTime = tick()
            elseif ErrorCount > MaxErrorsPerMinute then
                return nil
            end
        end
        return success and result or nil
    end
end

local function ProtectInstance(instance)
    if not instance or typeof(instance) ~= "Instance" or ProtectedInstances[instance] then return end
    ProtectedInstances[instance] = true
    HookMethod(instance, "Destroy", function(original, ...)
        if IsEnabled and (instance.ClassName == "Player" or instance.ClassName == "Workspace" or instance.ClassName == "CoreGui") then
            return nil
        end
        return original(...)
    end)
    HookMethod(instance, "Remove", function(original, ...)
        if IsEnabled and (instance.ClassName == "Player" or instance.ClassName == "Workspace" or instance.ClassName == "CoreGui") then
            return nil
        end
        return original(...)
    end)
    for _, child in pairs(instance:GetChildren()) do ProtectInstance(child) end
    instance.ChildAdded:Connect(function(child) ProtectInstance(child) end)
end

local function MonitorMemory()
    if tick() - LastMemoryCheck < MemoryCheckInterval then return end
    LastMemoryCheck = tick()
    local memoryUsage = gcinfo() * 1024
    if memoryUsage > MemoryThreshold then
        collectgarbage("collect")
    end
end

local function SafeConnect(signal, callback)
    local success, result = pcall(function()
        return signal:Connect(function(...) task.spawn(function() pcall(callback, ...) end) end)
    end)
    return success and result or nil
end

local function SelfHealHooks()
    for instance, methods in pairs(OriginalFunctions) do
        for methodName, original in pairs(methods) do
            if instance[methodName] ~= original then
                SafePcall(function()
                    instance[methodName] = original
                end)
            end
        end
    end
end

function AntiCrash:Enable()
    if not AntiCrash then
        print("Error: AntiCrash table is nil!")
        return
    end

    print("AntiCrash:Enable called!")

    IsEnabled = true
    local services = {
        game:GetService("Workspace"),
        game:GetService("Players"),
        game:GetService("CoreGui"),
        game:GetService("ReplicatedStorage"),
        game:GetService("RunService"),
        game:GetService("UserInputService"),
        game:GetService("GuiService"),
        game:GetService("Lighting")
    }
    for _, service in pairs(services) do ProtectInstance(service) end
    local mt = getrawmetatable(game:GetService("Players"))
    local oldIndex = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local callCount = self._antiCrashCallCount or 0
            local lastCallTime = self._antiCrashLastCall or 0
            if tick() - lastCallTime < 1 then
                callCount = callCount + 1
            else
                callCount = 1
            end
            self._antiCrashCallCount = callCount
            self._antiCrashLastCall = tick()
            if callCount > 60 then return nil end
        end
        return oldIndex(self, ...)
    end
    setreadonly(mt, true)
    local oldError = error
    error = function(...)
        if IsEnabled then
            ErrorCount = ErrorCount + 1
            if tick() - LastErrorTime > 60 then
                ErrorCount = 1
                LastErrorTime = tick()
            elseif ErrorCount > MaxErrorsPerMinute then
                return
            end
        end
        return oldError(...)
    end
    local oldAssert = assert
    assert = function(cond, ...)
        if not cond and IsEnabled then
            ErrorCount = ErrorCount + 1
            if tick() - LastErrorTime > 60 then
                ErrorCount = 1
                LastErrorTime = tick()
            elseif ErrorCount > MaxErrorsPerMinute then
                return true
            end
        end
        return oldAssert(cond, ...)
    end
    SafeConnect(game:GetService("RunService").Heartbeat, MonitorMemory)
    task.spawn(function()
        while IsEnabled do
            for _, conn in pairs(getconnections(game:GetService("RunService").Heartbeat)) do
                if conn.Function and not conn._antiCrashProtected then
                    local f = conn.Function
                    conn.Function = function(...)
                        local success, result = pcall(function() return f(...) end)
                        return success and result or nil
                    end
                    conn._antiCrashProtected = true
                end
            end
            SelfHealHooks()
            task.wait(5)
        end
    end)
    task.spawn(function()
        while IsEnabled do
            task.wait(1)
            for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
                for _, obj in pairs(plr:GetDescendants()) do
                    if (obj:IsA("Script") or obj:IsA("LocalScript")) and not obj._antiCrashProtected then
                        obj._antiCrashProtected = true
                        obj.Error:Connect(function()
                            if IsEnabled then
                                ErrorCount = ErrorCount + 1
                                if tick() - LastErrorTime > 60 then
                                    ErrorCount = 1
                                    LastErrorTime = tick()
                                elseif ErrorCount > MaxErrorsPerMinute then
                                    return
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
    if Executor == "Unknown" then
        warn("AntiCrash: Executor not detected. Behavior may vary.")
    end
    return true
end

function AntiCrash:Disable()
    IsEnabled = false
    for instance, methods in pairs(OriginalFunctions) do
        if typeof(instance) == "Instance" and instance:IsDescendantOf(game) then
            for methodName, original in pairs(methods) do
                pcall(function()
                    instance[methodName] = original
                end)
            end
        end
    end
    OriginalFunctions = {}
    ProtectedInstances = {}
    return true
end

-- Debugging print to confirm that AntiCrash:Enable is called
print("Calling AntiCrash:Enable()")
AntiCrash:Enable()

return AntiCrash
