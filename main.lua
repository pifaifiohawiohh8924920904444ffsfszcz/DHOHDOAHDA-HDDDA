-- Wait until the game is fully loaded
repeat task.wait() until game:IsLoaded()

-- Safely handle vape uninject
if shared.vape then
    shared.vape:Uninject()
end

-- Check if the executor is recognized
if identifyexecutor then
    local executor = identifyexecutor()
    if executor and table.find({'Argon', 'Wave'}, executor) then
        getgenv().setthreadidentity = nil
    end
end

-- Simplified and safe loadstring with error handling
local function safeLoadString(str)
    local res, err = loadstring(str)
    if err then
        warn("Error loading script:", err)
        return nil
    end
    return res
end

-- Simplified file check
local function isFile(path)
    local success, result = pcall(function()
        return readfile(path)
    end)
    return success and result ~= nil and result ~= ''
end

-- Download file function with safe handling
local function downloadFile(path, func)
    if not isFile(path) then
        local success, content = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/' .. readfile('newvape/profiles/commit.txt') .. '/' .. path:gsub('newvape/', ''), true)
        end)
        if not success or content == '404: Not Found' then
            return nil -- Handle missing file gracefully
        end
        writefile(path, content)
    end
    return (func or readfile)(path)
end

-- Initialize vape loading process
local function finishLoading()
    -- Ensure vape is loaded properly without overwhelming the system
    if vape then
        vape:Load()
        task.spawn(function()
            repeat
                vape:Save()
                task.wait(10)
            until not vape.Loaded
        end)
    end
end

-- Check if essential files exist and load them
if not isFile('newvape/profiles/gui.txt') then
    writefile('newvape/profiles/gui.txt', 'new')
end
local gui = readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/' .. gui) then
    makefolder('newvape/assets/' .. gui)
end

-- Simplified GUI loading
local vape = safeLoadString(downloadFile('newvape/guis/' .. gui .. '.lua'))()

-- Check and initialize necessary libraries
local XFunctions = safeLoadString(downloadFile('newvape/libraries/XFunctions.lua'))()
XFunctions:SetGlobalData('XFunctions', XFunctions)
XFunctions:SetGlobalData('vape', vape)

local PerformanceModule = safeLoadString(downloadFile('newvape/libraries/performance.lua'))()
XFunctions:SetGlobalData('Performance', PerformanceModule)

local utils_functions = safeLoadString(downloadFile('newvape/libraries/utils.lua'))()
for i, v in pairs(utils_functions) do
    getfenv()[i] = v
end

-- Function to create notifications (simplified)
getgenv().InfoNotification = function(title, msg, dur)
    warn('info', title, msg, dur)
end

-- Check for vape independent mode and load game scripts if necessary
if not shared.VapeIndependent then
    safeLoadString(downloadFile('newvape/games/universal.lua'))()
    safeLoadString(downloadFile('newvape/games/modules.lua'))()

    if isFile('newvape/games/' .. game.PlaceId .. '.lua') then
        safeLoadString(readfile('newvape/games/' .. game.PlaceId .. '.lua'))()
    end

    finishLoading()
else
    vape.Init = finishLoading
    return vape
end

-- Mark vape as fully loaded
shared.VapeFullyLoaded = true
