local whitelist_url = "https://raw.githubusercontent.com/wrealaero/whitelistcheck/main/whitelist.json"
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local userId = tostring(localPlayer.UserId)

local whitelist_cache = nil
shared.Injected = true

local function getWhitelist()
    if whitelist_cache then return whitelist_cache end

    local success, response = pcall(function()
        return game:HttpGet(whitelist_url)
    end)

    if success and response and response ~= "404: Not Found" then
        local successDecode, whitelist = pcall(function()
            return httpService:JSONDecode(response)
        end)

        if successDecode and typeof(whitelist) == "table" then
            whitelist_cache = whitelist 
            return whitelist
        end
    end
    return nil
end

local whitelist = getWhitelist()
local userTag = whitelist and whitelist[userId] or nil

local function addChatTag()
    if not shared.Injected or not userTag then return end

    local chatEvents = game.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents and chatEvents.OnMessageDoneFiltering then
        chatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
            if tostring(players:GetUserIdFromNameAsync(messageData.FromSpeaker)) == userId then
                messageData.ExtraData = messageData.ExtraData or {}
                messageData.ExtraData.Tags = messageData.ExtraData.Tags or {}

                table.insert(messageData.ExtraData.Tags, {
                    TagText = "[" .. userTag .. "]",
                    TagColor = Color3.fromRGB(255, 50, 50)
                })
            end
        end)
    end
end

addChatTag()

local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local function createNotification(title, text)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Parent = screenGui
    frame.Size = UDim2.new(0, 400, 0, 150)
    frame.Position = UDim2.new(0.5, -200, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.85
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.ZIndex = 10
    frame.ClipsDescendants = true

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = frame
    titleLabel.Text = title
    titleLabel.Size = UDim2.new(1, 0, 0, 35)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 22
    titleLabel.TextStrokeTransparency = 0.6
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center

    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = frame
    textLabel.Text = text
    textLabel.Size = UDim2.new(1, 0, 0, 90)
    textLabel.Position = UDim2.new(0, 0, 0, 35)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.TextStrokeTransparency = 0.8
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center

    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -200, 0.5, -75)
    })

    local tweenOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -200, 1, 50)
    })

    tweenIn:Play()
    tweenIn.Completed:Connect(function()
        wait(3)
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)
end

if userTag then
    createNotification("Whitelisted", "You're good to go, bro!")
else
    createNotification("Denied", "You're not whitelisted, bro.")
end

if userTag then

    local isfile = isfile or function(file)
        local suc, res = pcall(function() return readfile(file) end)
        return suc and res ~= nil and res ~= ''
    end
    local delfile = delfile or function(file)
        writefile(file, '')
    end

    local function downloadFile(path, func)
        if not isfile(path) then
            local suc, res = pcall(function()
                return game:HttpGet('https://raw.githubusercontent.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA/' .. readfile('newvape/profiles/commit.txt') .. '/' .. select(1, path:gsub('newvape/', '')), true)
            end)
            if not suc or res == '404: Not Found' then
                error(res)
            end
            if path:find('.lua') then
                res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
            end
            writefile(path, res)
        end
        return (func or readfile)(path)
    end

    local function wipeFolder(path)
        if not isfolder(path) then return end
        for _, file in listfiles(path) do
            if file:find('loader') then continue end
            if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
                delfile(file)
            end
        end
    end

    for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
        if not isfolder(folder) then
            makefolder(folder)
        end
    end

    if not shared.VapeDeveloper then
        local _, subbed = pcall(function()
            return game:HttpGet('https://github.com/pifaifiohawiohh8924920904444ffsfszcz/DHOHDOAHDA-HDDDA')
        end)
        local commit = subbed:find('currentOid')
        commit = commit and subbed:sub(commit + 13, commit + 52) or nil
        commit = commit and #commit == 40 and commit or 'main'
        if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
            wipeFolder('newvape')
            wipeFolder('newvape/games')
            wipeFolder('newvape/guis')
            wipeFolder('newvape/libraries')
        end
        writefile('newvape/profiles/commit.txt', commit)
    end

    return loadstring(downloadFile('newvape/main.lua'), 'main')()
else
    createNotification("Denied", "You're not whitelisted, bro.")
end
