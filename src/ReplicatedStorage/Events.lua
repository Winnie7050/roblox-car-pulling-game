--[[
    Events.lua
    
    Central event system for client-server communication.
    This module creates and manages all RemoteEvents used in the game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = {}
local remoteEvents = {}

-- Create Events folder if it doesn't exist
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "Events"
    eventsFolder.Parent = ReplicatedStorage
end

-- Event definitions
local eventDefinitions = {
    -- Game state events
    "GameStarted",
    "GameEnded",
    "PlayerReset",
    
    -- Car and rope events
    "SpawnCar",
    "AttachRope",
    "DetachRope",
    "CarPositionUpdate", -- Optimized, throttled updates
    
    -- Player events
    "StaminaUpdate",
    "StrengthUpdate",
    "DistanceUpdate",
    
    -- UI events
    "UpdateDistanceUI",
    "UpdateStaminaUI",
    "ShowResetPrompt",
}

-- Create remote events
for _, eventName in ipairs(eventDefinitions) do
    local event = eventsFolder:FindFirstChild(eventName)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = eventName
        event.Parent = eventsFolder
    end
    remoteEvents[eventName] = event
end

-- Functions to fire events
function Events:FireClient(eventName, player, ...)
    local event = remoteEvents[eventName]
    if event then
        event:FireClient(player, ...)
    else
        warn("Attempted to fire nonexistent event: " .. eventName)
    end
end

function Events:FireAllClients(eventName, ...)
    local event = remoteEvents[eventName]
    if event then
        event:FireAllClients(...)
    else
        warn("Attempted to fire nonexistent event: " .. eventName)
    end
end

function Events:FireServer(eventName, ...)
    local event = remoteEvents[eventName]
    if event then
        event:FireServer(...)
    else
        warn("Attempted to fire nonexistent event: " .. eventName)
    end
end

-- Connect to events
function Events:ConnectClient(eventName, callback)
    local event = remoteEvents[eventName]
    if event then
        return event.OnClientEvent:Connect(callback)
    else
        warn("Attempted to connect to nonexistent event: " .. eventName)
        return nil
    end
end

function Events:ConnectServer(eventName, callback)
    local event = remoteEvents[eventName]
    if event then
        return event.OnServerEvent:Connect(callback)
    else
        warn("Attempted to connect to nonexistent event: " .. eventName)
        return nil
    end
end

-- Get the raw RemoteEvent instance
function Events:GetEvent(eventName)
    return remoteEvents[eventName]
end

return Events
