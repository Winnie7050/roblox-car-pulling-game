--[[
    Utils.lua
    
    Utility functions that can be used by both client and server.
]]

local Utils = {}

-- Calculate distance between two Vector3 positions
function Utils.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Get vector direction from pos1 to pos2, with optional normalization
function Utils.getDirection(pos1, pos2, normalize)
    local direction = pos2 - pos1
    if normalize then
        return direction.Unit
    end
    return direction
end

-- Clamp a value between min and max
function Utils.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

-- Linear interpolation between two values
function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Format a number as a string with thousands separator and decimal places
function Utils.formatNumber(number, decimals)
    decimals = decimals or 0
    
    local formatted = string.format("%." .. decimals .. "f", number)
    local left, right = string.match(formatted, "^([^%.]+)%.?(.*)$")
    
    left = string.gsub(left, "(%d)(%d%d%d)$", "%1,%2")
    left = string.gsub(left, "(%d)(%d%d%d),", "%1,%2,")
    
    if right == "" then
        return left
    else
        return left .. "." .. right
    end
end

-- Calculate a percentage and format it
function Utils.formatPercentage(current, total, decimals)
    decimals = decimals or 0
    local percentage = (current / total) * 100
    return string.format("%." .. decimals .. "f%%", percentage)
end

-- Create a throttled function that only executes at most once per specified interval
function Utils.throttle(callback, interval)
    interval = interval or 0.1
    local lastExecutionTime = 0
    
    return function(...)
        local args = {...}
        local currentTime = time()
        
        if currentTime - lastExecutionTime >= interval then
            lastExecutionTime = currentTime
            return callback(unpack(args))
        end
    end
end

-- Get the CFrame for attaching a rope to a character (at the torso/HumanoidRootPart)
function Utils.getCharacterAttachmentPoint(character)
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        -- Position slightly behind the character to make the rope visually connect better
        local offset = CFrame.new(0, 0, 0.5)
        return humanoidRootPart.CFrame * offset
    end
    
    return nil
end

-- Get the CFrame for attaching a rope to a car
function Utils.getCarAttachmentPoint(car)
    if not car then return nil end
    
    local primaryPart = car:FindFirstChild("PRIMARY")
    if primaryPart then
        -- Position at the front center of the car
        local offset = CFrame.new(0, 0, -primaryPart.Size.Z/2)
        return primaryPart.CFrame * offset
    end
    
    return nil
end

return Utils
