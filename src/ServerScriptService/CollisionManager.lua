--[[
    CollisionManager.lua
    
    Manages collision groups for the game to implement the required collision rules:
    - Players cannot collide with: other players, cars, or ropes
    - Cars cannot collide with: players or ropes
    - Ropes have no collision with any objects including the map
]]

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local CollisionManager = {}

-- Collision group names
local COLLISION_GROUPS = {
    PLAYERS = "Players",
    CARS = "Cars",
    ROPES = "Ropes",
    WORLD = "World",
    DEFAULT = "Default"
}

function CollisionManager:Initialize()
    -- Register collision groups
    for _, groupName in pairs(COLLISION_GROUPS) do
        if not PhysicsService:IsCollisionGroupRegistered(groupName) then
            PhysicsService:RegisterCollisionGroup(groupName)
        end
    end
    
    -- Set collision rules
    
    -- Players don't collide with other players
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUPS.PLAYERS, COLLISION_GROUPS.PLAYERS, false)
    
    -- Players don't collide with cars
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUPS.PLAYERS, COLLISION_GROUPS.CARS, false)
    
    -- Players don't collide with ropes
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUPS.PLAYERS, COLLISION_GROUPS.ROPES, false)
    
    -- Cars don't collide with ropes
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUPS.CARS, COLLISION_GROUPS.ROPES, false)
    
    -- Ropes don't collide with the world
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUPS.ROPES, COLLISION_GROUPS.WORLD, false)
    
    -- Ropes don't collide with the default group
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUPS.ROPES, COLLISION_GROUPS.DEFAULT, false)
    
    print("Collision groups initialized")
end

-- Set collision group for a character
function CollisionManager:SetupCharacterCollision(character)
    if not character then return end
    
    -- Apply collision group to all character parts
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = COLLISION_GROUPS.PLAYERS
        end
    end
    
    -- Handle when new parts are added to the character (like accessories)
    character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = COLLISION_GROUPS.PLAYERS
        end
    end)
end

-- Set collision group for a car
function CollisionManager:SetupCarCollision(car)
    if not car then return end
    
    -- Apply collision group to all car parts
    for _, part in pairs(car:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = COLLISION_GROUPS.CARS
        end
    end
end

-- Set collision group for a rope
function CollisionManager:SetupRopeCollision(rope)
    if not rope then return end
    
    -- Apply collision group to all rope parts
    if rope:IsA("RopeConstraint") then
        -- If it's a RopeConstraint, we don't need to do anything for collision
        -- since constraints don't have collision properties
        return
    end
    
    -- For custom rope implementation with parts
    for _, part in pairs(rope:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = COLLISION_GROUPS.ROPES
            part.CanCollide = false -- Additional safety to ensure no collisions
        end
    end
end

-- Set collision group for a world object
function CollisionManager:SetupWorldCollision(object)
    if not object then return end
    
    -- Apply world collision group
    for _, part in pairs(object:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = COLLISION_GROUPS.WORLD
        end
    end
end

-- Get the collision group name for an object type
function CollisionManager:GetCollisionGroup(objectType)
    return COLLISION_GROUPS[string.upper(objectType)] or COLLISION_GROUPS.DEFAULT
end

return CollisionManager
