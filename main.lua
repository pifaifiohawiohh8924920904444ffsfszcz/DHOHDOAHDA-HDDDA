repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/refs/heads/main/CrashPrevention.lua"))()
end)

if identifyexecutor then
    if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
        getgenv().setthreadidentity = nil
    end
end

local vape
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
    local suc, res = pcall(function() return readfile(file) end)
    return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj) return obj end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
    if not isfile(path) then
        local suc, res = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
        end)
        if not suc or res == '404: Not Found' then return nil end
        if path:find('.lua') then
            res = '-- Cache Control --\n'..res
        end
        writefile(path, res)
    end
    return (func or readfile)(path)
end

local function finishLoading()
    vape.Init = nil
    vape:Load()
    
    task.spawn(function()
        while vape.Loaded do
            vape:Save()
            task.wait(30)
        end
    end)

    local teleportedServers
    vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
        if (not teleportedServers) and (not shared.VapeIndependent) then
            teleportedServers = true
            local teleportScript = [[
                script_key = ']]..(getgenv().script_key or "")..[[';
                getgenv().script_key = script_key
                shared.vapereload = true
                loadstring(game:HttpGet('https://raw.githubusercontent.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/]]..readfile('newvape/profiles/commit.txt')..[[/loader.lua', true))()
            ]]
            if shared.VapeDeveloper then
                teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
            end
            if shared.VapeCustomProfile then
                teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
            end
            vape:Save()
            queue_on_teleport(teleportScript)
        end
    end))

    if not shared.vapereload then
        if vape.Categories and vape.Categories.Main.Options['GUI bind indicator'].Enabled then
            vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
        end
    end
end

if not isfile('newvape/profiles/gui.txt') then
    writefile('newvape/profiles/gui.txt', 'new')
end
local gui = readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/'..gui) then
    makefolder('newvape/assets/'..gui)
end

pcall(function() vape = loadstring(downloadFile('newvape/guis/'..gui..'.lua'))() end)

local XFunctions = pcall(function() return loadstring(downloadFile('newvape/libraries/XFunctions.lua'))() end)
if XFunctions then
    XFunctions:SetGlobalData('XFunctions', XFunctions)
    XFunctions:SetGlobalData('vape', vape)
end

local PerformanceModule = pcall(function() return loadstring(downloadFile('newvape/libraries/performance.lua'))() end)
if PerformanceModule then
    XFunctions:SetGlobalData('Performance', PerformanceModule)
end

local utils_functions = pcall(function() return loadstring(downloadFile('newvape/libraries/utils.lua'))() end)
if utils_functions then
    for i, v in pairs(utils_functions) do
        getfenv()[i] = v
    end
end

getgenv().InfoNotification = function(title, msg, dur)
    warn('INFO:', tostring(title), tostring(msg), tostring(dur))
    if vape then vape:CreateNotification(title, msg, dur) end
end
getgenv().warningNotification = function(title, msg, dur)
    warn('WARNING:', tostring(title), tostring(msg), tostring(dur))
    if vape then vape:CreateNotification(title, msg, dur, 'warning') end
end
getgenv().errorNotification = function(title, msg, dur)
    warn("ERROR:", tostring(title), tostring(msg), tostring(dur))
    if vape then vape:CreateNotification(title, msg, dur, 'alert') end
end

if not shared.VapeIndependent then
    pcall(function() loadstring(downloadFile('newvape/games/universal.lua'))() end)
    pcall(function() loadstring(downloadFile('newvape/games/modules.lua'))() end)
    
    local gameScript = 'newvape/games/'..game.PlaceId..'.lua'
    if isfile(gameScript) then
        pcall(function() loadstring(readfile(gameScript))() end)
    else
        if not shared.VapeDeveloper then
            local suc, res = pcall(function()
                return game:HttpGet('https://raw.githubusercontent.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/'..readfile('newvape/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
            end)
            if suc and res ~= '404: Not Found' then
                pcall(function() loadstring(downloadFile(gameScript))() end)
            end
        end
    end
    finishLoading()
else
    vape.Init = finishLoading
    return vape
end

shared.VapeFullyLoaded = true
