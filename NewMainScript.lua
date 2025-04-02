-- Initialize error handling
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[Error] " .. tostring(result))
        return nil
    end
    return result
end

-- Load whitelist manager
local WhitelistManager = safeCall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/wrealaero/whitelistcheck/main/whitelist_manager.lua"))()
end) or {}

-- File system utilities with safety checks
local FileSystem = {
    isfile = isfile or function(file)
        return safeCall(function() return readfile(file) ~= nil end) or false
    end,
    
    readfile = readfile or function(file)
        return safeCall(function() return readfile(file) end) or ""
    end,
    
    writefile = writefile or function(file, content)
        return safeCall(function() writefile(file, content) end)
    end,
    
    delfile = delfile or function(file)
        return safeCall(function() delfile(file) end)
    end,
    
    isfolder = isfolder or function(folder)
        return safeCall(function() return isfolder(folder) end) or false
    end,
    
    makefolder = makefolder or function(folder)
        return safeCall(function() makefolder(folder) end)
    end,
    
    listfiles = listfiles or function(folder)
        return safeCall(function() return listfiles(folder) end) or {}
    end
}

-- Main execution with rate limiting and chunking to prevent crashes
local function main()
    local player = game.Players.LocalPlayer
    local userId = tostring(player.UserId)
    
    -- Check whitelist with improved system
    local isWhitelisted, userTier = WhitelistManager:isWhitelisted(userId)
    
    if not isWhitelisted then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Access Denied",
            Text = type(userTier) == "string" and userTier or "You are not whitelisted",
            Duration = 5
        })
        return
    end
    
    -- Create necessary folders with delay between operations
    local folders = {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'}
    
    for i, folder in ipairs(folders) do
        if not FileSystem.isfolder(folder) then
            FileSystem.makefolder(folder)
        end
        
        -- Small delay between folder operations to prevent resource spikes
        if i < #folders then
            task.wait(0.05)
        end
    end
    
    -- Check for updates with rate limiting
    if not shared.VapeDeveloper then
        local commitCheck = safeCall(function()
            local response = game:HttpGet('https://github.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA')
            local commit = response:match('currentOid":"([%w]+)"')
            return commit and #commit == 40 and commit or 'main'
        end)
        
        local currentCommit = FileSystem.isfile('newvape/profiles/commit.txt') and 
                             FileSystem.readfile('newvape/profiles/commit.txt') or ''
        
        -- Only wipe folders if commit has changed
        if commitCheck and (commitCheck == 'main' or currentCommit ~= commitCheck) then
            -- Function to safely wipe folder with rate limiting
            local function wipeFolder(path)
                if not FileSystem.isfolder(path) then return end
                
                local files = FileSystem.listfiles(path)
                for i, file in ipairs(files) do
                    if not file:find('loader') then
                        local content = FileSystem.readfile(file)
                        if content:find('--This watermark is used to delete the file if its cached') == 1 then
                            FileSystem.delfile(file)
                        end
                    end
                    
                    -- Add delay every few files to prevent resource spikes
                    if i % 5 == 0 then
                        task.wait(0.1)
                    end
                end
            end
            
            -- Wipe folders with delays between them
            local foldersToWipe = {'newvape', 'newvape/games', 'newvape/guis', 'newvape/libraries'}
            for i, folder in ipairs(foldersToWipe) do
                wipeFolder(folder)
                task.wait(0.2) -- Larger delay between folder wipes
            end
            
            -- Update commit file
            FileSystem.writefile('newvape/profiles/commit.txt', commitCheck)
        end
    end
    
    -- Download and load main script with chunking
    local function downloadFile(path)
        if not FileSystem.isfile(path) then
            local commit = FileSystem.readfile('newvape/profiles/commit.txt')
            local relativePath = path:gsub('newvape/', '')
            
            local content = safeCall(function()
                return game:HttpGet('https://raw.githubusercontent.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/' .. commit .. '/' .. relativePath, true)
            end)
            
            if not content or content == '404: Not Found' then
                warn("Failed to download file: " .. path)
                return nil
            end
            
            if path:find('.lua') then
                content = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. content
            end
            
            FileSystem.writefile(path, content)
            task.wait(0.1) -- Small delay after file download
        end
        
        return FileSystem.readfile(path)
    end
    
    -- Load main script with proper error handling
    local mainScript = downloadFile('newvape/main.lua')
    if mainScript then
        -- Use loadstring in a protected call with a custom environment to prevent global leaks
        local env = setmetatable({}, {__index = getfenv()})
        local func, err = loadstring(mainScript, 'main')
        
        if func then
            setfenv(func, env)
            safeCall(func)
        else
            warn("Failed to compile script: " .. tostring(err))
        end
    else
        warn("Failed to load main script")
    end
end

-- Execute main function with error handling
safeCall(main)
