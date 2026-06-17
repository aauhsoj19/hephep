local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlaceID = game.PlaceId

-- Persist settings
getgenv().AutoHopEnabled = getgenv().AutoHopEnabled ~= false
getgenv().HopDelay = getgenv().HopDelay or 30

local AutoHop = getgenv().AutoHopEnabled
local Delay = getgenv().HopDelay
local TimeLeft = Delay

-- Teleport Queue Support
local QueueOnTeleport =
    queue_on_teleport or
    queueonteleport or
    (syn and syn.queue_on_teleport)

local function QueueScript()
    if QueueOnTeleport then
        QueueOnTeleport([[
            loadstring(game:HttpGet("YOUR_SCRIPT_URL"))()
        ]])
    end
end

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerHopUI"
ScreenGui.ResetOnSpawn = false
pcall(function()
    ScreenGui.Parent = LocalPlayer.PlayerGui
end)

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 180)
Frame.Position = UDim2.new(0.5, -130, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundColor3 = Color3.fromRGB(20,20,20)
Title.TextColor3 = Color3.new(1,1,1)
Title.Text = "Auto Server Hopper"
Title.Parent = Frame

local Countdown = Instance.new("TextLabel")
Countdown.Size = UDim2.new(1,0,0,25)
Countdown.Position = UDim2.new(0,0,0,40)
Countdown.BackgroundTransparency = 1
Countdown.TextColor3 = Color3.new(1,1,1)
Countdown.Text = "Next Hop: "..TimeLeft.."s"
Countdown.Parent = Frame

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(0.8,0,0,30)
Toggle.Position = UDim2.new(0.1,0,0,75)
Toggle.Text =
    "Auto Hop: " ..
    (getgenv().AutoHopEnabled and "ON" or "OFF")
Toggle.Parent = Frame

local DelayBox = Instance.new("TextBox")
DelayBox.Size = UDim2.new(0.8,0,0,30)
DelayBox.Position = UDim2.new(0.1,0,0,115)
DelayBox.Text = tostring(Delay)
DelayBox.PlaceholderText = "Hop Delay (Seconds)"
DelayBox.Parent = Frame

local ServerLabel = Instance.new("TextLabel")
ServerLabel.Size = UDim2.new(1,0,0,20)
ServerLabel.Position = UDim2.new(0,0,0,150)
ServerLabel.BackgroundTransparency = 1
ServerLabel.TextColor3 = Color3.new(1,1,1)
ServerLabel.Text = "Server: "..string.sub(game.JobId,1,8)
ServerLabel.Parent = Frame

-- Dragging
local dragging = false
local dragInput
local dragStart
local startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart

        Frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Toggle
Toggle.MouseButton1Click:Connect(function()
    getgenv().AutoHopEnabled = not getgenv().AutoHopEnabled
    AutoHop = getgenv().AutoHopEnabled

    Toggle.Text =
        "Auto Hop: " ..
        (AutoHop and "ON" or "OFF")
end)

-- Delay Change
DelayBox.FocusLost:Connect(function()
    local num = tonumber(DelayBox.Text)

    if num and num > 0 then
        Delay = num
        TimeLeft = num

        getgenv().HopDelay = num
    else
        DelayBox.Text = tostring(Delay)
    end
end)

-- Server Hop Function
local function ServerHop()
    QueueScript()

    local url = string.format(
        "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
        PlaceID
    )

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("Failed to fetch servers")
        return
    end

    local data = HttpService:JSONDecode(response)

    for _, server in ipairs(data.data) do
        if server.id ~= game.JobId
        and server.playing < server.maxPlayers then

            TeleportService:TeleportToPlaceInstance(
                PlaceID,
                server.id,
                LocalPlayer
            )

            return
        end
    end
end

-- Countdown Loop
task.spawn(function()
    while true do
        task.wait(1)

        AutoHop = getgenv().AutoHopEnabled

        if AutoHop then
            TimeLeft -= 1

            Countdown.Text =
                "Next Hop: "..TimeLeft.."s"

            if TimeLeft <= 0 then
                pcall(ServerHop)
                TimeLeft = Delay
            end
        else
            Countdown.Text = "Auto Hop Disabled"
        end
    end
end)