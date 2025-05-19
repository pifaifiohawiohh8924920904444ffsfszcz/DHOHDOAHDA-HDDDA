local function downloadFile(path, func)
    if not isfile(path) then
        local suc, res = pcall(function()
            local commit = readfile('newvape/profiles/commit.txt')
            local filePath = path:gsub('newvape/', '')
            return game:HttpGet('https://raw.githubusercontent.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/' .. commit .. '/' .. filePath, true)
        end)

        if not suc or res == '404: Not Found' then
            warn("Failed to download file: " .. tostring(res))
            return nil
        end

        if path:find('%.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
        end

        pcall(function() writefile(path, res) end)
    end

    return (func or readfile)(path)
end

local function wipeFolder(path)
    if not isfolder(path) then return end
    for _, file in ipairs(listfiles(path)) do
        if file:find('loader') then continue end
        if isfile(file) then
            local content = readfile(file)
            if content:find('^%-%-This watermark is used to delete the file if its cached') then
                delfile(file)
            end
        end
    end
end

for _, folder in ipairs({'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'}) do
    if not isfolder(folder) then
        pcall(function() makefolder(folder) end)
    end
end

if not shared.VapeDeveloper then
    local _, subbed = pcall(function()
        return game:HttpGet('https://github.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA')
    end)

    if subbed then
        local commit = subbed:match('currentOid%s*:%s*"([a-f0-9]+)"') or 'main'
        local current = isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or ''

        if commit == 'main' or current ~= commit then
            wipeFolder('newvape')
            wipeFolder('newvape/games')
            wipeFolder('newvape/guis')
            wipeFolder('newvape/libraries')
        end

        pcall(function() writefile('newvape/profiles/commit.txt', commit) end)
    end
end

local success, err = pcall(function()
    local mainCode = downloadFile('newvape/main.lua')
    if mainCode then
        loadstring(mainCode, 'main')()
    else
        error("Download returned nil")
    end
end)

if not success then
    warn("Failed to load script, check ur executer..: " .. tostring(err))
end
