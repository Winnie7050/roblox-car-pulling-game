--[[
    CarManager.lua
    
    Manages the spawning, physics, and removal of cars.
    Handles car physics properties and network ownership.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Utils"))
local Events = require(ReplicatedStorage:WaitForChild("Events"))

local CarManager = {}
CarManager.activeCars = {} -- Store references to active cars by player userId

-- Create a car for a player
function CarManager:SpawnCar(player, spawnPosition)
    if not player or not player.Character then
        warn("Cannot spawn car - player or character is missing")
        return nil
    end
    
    -- Remove any existing car for this player
    self:RemoveCar(player)
    
    -- Get character position if spawnPosition not provided
    if not spawnPosition then
        local character = player.Character
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoidRootPart then
            -- Position the car behind the player
            local characterCFrame = humanoidRootPart.CFrame
            spawnPosition = characterCFrame.Position - (characterCFrame.LookVector * Config.Car.InitialDistance)
            spawnPosition = Vector3.new(spawnPosition.X, humanoidRootPart.Position.Y, spawnPosition.Z)
        else
            warn("Cannot determine spawn position for car")
            return nil
        end
    end
    
    -- Create the car model
    local car = Instance.new("Model")
    car.Name = "Car_" .. player.UserId
    
    -- Create the car body (primary part)
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "PRIMARY"
    primaryPart.Size = Vector3.new(4, 1.5, 6) -- Size of the car body
    primaryPart.Position = spawnPosition
    primaryPart.Anchored = false
    primaryPart.CanCollide = true
    primaryPart.Material = Enum.Material.Metal
    primaryPart.Color = Color3.fromRGB(0, 100, 200) -- Blue color
    primaryPart.Parent = car
    
    -- Set custom physical properties
    local physicalProperties = PhysicalProperties.new(
        1, -- Density
        0.3, -- Friction
        0.2, -- Elasticity
        1, -- FrictionWeight
        1  -- ElasticityWeight
    )
    primaryPart.CustomPhysicalProperties = physicalProperties
    
    -- Create wheels
    local wheelPositions = {
        FL = Vector3.new(-1.8, -0.7, 2), -- Front Left
        FR = Vector3.new(1.8, -0.7, 2),  -- Front Right
        RL = Vector3.new(-1.8, -0.7, -2), -- Rear Left
        RR = Vector3.new(1.8, -0.7, -2)  -- Rear Right
    }
    
    local wheelSize = Vector3.new(0.8, 0.8, 0.8)
    
    for name, position in pairs(wheelPositions) do
        local wheel = Instance.new("Part")
        wheel.Name = name
        wheel.Size = wheelSize
        wheel.Shape = Enum.PartType.Cylinder
        wheel.Orientation = Vector3.new(0, 0, 90) -- Horizontal cylinder
        wheel.Position = spawnPosition + position
        wheel.Anchored = false
        wheel.CanCollide = true
        wheel.Material = Enum.Material.SmoothPlastic
        wheel.Color = Color3.fromRGB(20, 20, 20) -- Dark gray
        wheel.Parent = car
        
        -- Weld wheel to body
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = primaryPart
        weld.Part1 = wheel
        weld.Parent = wheel
    end
    
    -- Set primary part for the model
    car.PrimaryPart = primaryPart
    
    -- Tag the car for easy reference
    CollectionService:AddTag(car, "PlayerCar")
    
    -- Store car data
    local carData = {
        player = player,
        car = car,
        connections = {}
    }
    
    -- Setup network ownership - server will own the car for physics stability
    primaryPart:SetNetworkOwner(nil)
    
    -- Add update connection to handle potential network ownership changes
    local updateConnection = RunService.Heartbeat:Connect(function()
        self:UpdateCar(carData)
    end)
    
    table.insert(carData.connections, updateConnection)
    
    -- Store the car data
    self.activeCars[player.UserId] = carData
    
    -- Parent the car to workspace last to ensure everything is set up
    car.Parent = workspace
    
    -- Notify clients
    Events:FireAllClients("SpawnCar", player, car)
    
    return carData
end

-- Update a car's physics and network ownership
function CarManager:UpdateCar(carData)
    if not carData or not carData.car or not carData.car.Parent then return end
    
    local car = carData.car
    local primaryPart = car.PrimaryPart
    
    if not primaryPart then return end
    
    -- Ensure server maintains ownership for physics stability
    if primaryPart:GetNetworkOwner() ~= nil then
        primaryPart:SetNetworkOwner(nil)
    end
    
    -- Update position for clients at a throttled rate to reduce network traffic
    -- This is handled by a separate throttled update function
end

-- Throttled function to send car position updates to clients
-- This will run at a lower frequency than the physics update
local lastUpdateTime = {}
function CarManager:SendPositionUpdate(carData)
    if not carData or not carData.car or not carData.car.Parent then return end
    
    local player = carData.player
    local car = carData.car
    
    -- Throttle updates to reduce network traffic (10 updates per second max)
    local now = tick()
    if not lastUpdateTime[player.UserId] or now - lastUpdateTime[player.UserId] >= 0.1 then
        lastUpdateTime[player.UserId] = now
        
        -- Send position update to clients
        local position = car.PrimaryPart.Position
        local rotation = car.PrimaryPart.Orientation
        
        Events:FireAllClients("CarPositionUpdate", player, position, rotation)
    end
end

-- Remove a car for a specific player
function CarManager:RemoveCar(player)
    if not player then return end
    
    local carData = self.activeCars[player.UserId]
    if not carData then return end
    
    -- Disconnect all connections
    for _, connection in pairs(carData.connections) do
        connection:Disconnect()
    end
    
    -- Destroy the car
    if carData.car and carData.car.Parent then
        carData.car:Destroy()
    end
    
    -- Remove from active cars
    self.activeCars[player.UserId] = nil
    lastUpdateTime[player.UserId] = nil
    
    -- Notify clients
    Events:FireAllClients("CarRemoved", player)
end

-- Remove all cars
function CarManager:RemoveAllCars()
    for userId, _ in pairs(self.activeCars) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            self:RemoveCar(player)
        end
    end
end

-- Check if a player has an active car
function CarManager:HasCar(player)
    if not player then return false end
    return self.activeCars[player.UserId] ~= nil
end

-- Get a player's active car data
function CarManager:GetCarData(player)
    if not player then return nil end
    return self.activeCars[player.UserId]
end

-- Initialize the CarManager
function CarManager:Initialize()
    -- Set up global throttled update for all cars
    RunService.Heartbeat:Connect(function()
        for _, carData in pairs(self.activeCars) do
            self:SendPositionUpdate(carData)
        end
    end)
    
    -- Clean up when players leave
    Players.PlayerRemoving:Connect(function(player)
        self:RemoveCar(player)
    end)
    
    -- Clean up when the game shuts down
    game:BindToClose(function()
        self:RemoveAllCars()
    end)
    
    print("CarManager initialized")
end

return CarManager
