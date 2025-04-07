--[[
    RopeVisualController.lua
    
    Client-side module that handles rope visualizations.
    Creates and manages visual effects for the rope pulling.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Events = require(ReplicatedStorage:WaitForChild("Events"))
local Utils = require(ReplicatedStorage:WaitForChild("Utils"))

local RopeVisualController = {}
RopeVisualController.activeRopes = {}

-- Initialize rope visuals
function RopeVisualController:Initialize()
    -- Connect to rope events
    self:ConnectEvents()
    
    print("RopeVisualController initialized")
}

-- Connect to game events
function RopeVisualController:ConnectEvents()
    -- Rope attached event
    Events:ConnectClient("AttachRope", function(player, car)
        self:CreateRopeVisual(player, car)
    end)
    
    -- Rope detached event
    Events:ConnectClient("DetachRope", function(player)
        self:RemoveRopeVisual(player)
    end)
}

-- Create a rope visual between a player and a car
function RopeVisualController:CreateRopeVisual(player, car)
    -- If we already have an active rope for this player, remove it first
    self:RemoveRopeVisual(player)
    
    -- Create a new visual effects container for this rope
    local ropeEffects = {
        player = player,
        car = car,
        connections = {}
    }
    
    -- Add effects based on player's strength (example: particles, beam, etc.)
    self:AddPullingEffects(ropeEffects)
    
    -- Add update connection
    local updateConnection = RunService.RenderStepped:Connect(function(deltaTime)
        self:UpdateRopeVisuals(ropeEffects, deltaTime)
    end)
    
    table.insert(ropeEffects.connections, updateConnection)
    
    -- Store the rope visual data
    self.activeRopes[player.UserId] = ropeEffects
}

-- Add visual effects to the rope
function RopeVisualController:AddPullingEffects(ropeEffects)
    local player = ropeEffects.player
    local car = ropeEffects.car
    
    -- We don't need to manually create the rope visual since the server
    -- has already created a visible RopeConstraint
    
    -- Add optional particle effects when pulling
    -- These would show effort/strain when the player is actively pulling
    
    -- Example: Create a particle emitter on the character
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create a strain/effort particle effect
    local strainParticles = Instance.new("ParticleEmitter")
    strainParticles.Name = "PullingEffect"
    strainParticles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    strainParticles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 0.75),
        NumberSequenceKeypoint.new(1, 1)
    })
    strainParticles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0)
    })
    strainParticles.Rate = 0 -- Start with 0, will adjust based on pulling
    strainParticles.Lifetime = NumberRange.new(0.5, 1)
    strainParticles.Speed = NumberRange.new(2, 4)
    strainParticles.SpreadAngle = Vector2.new(30, 30)
    strainParticles.EmissionDirection = Enum.NormalId.Back
    strainParticles.Parent = humanoidRootPart
    
    ropeEffects.strainParticles = strainParticles
}

-- Update rope visual effects
function RopeVisualController:UpdateRopeVisuals(ropeEffects, deltaTime)
    local player = ropeEffects.player
    if not player or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Check if player is moving
    local isMoving = humanoid.MoveDirection.Magnitude > 0
    
    -- Update strain particles based on player movement
    if ropeEffects.strainParticles then
        if isMoving then
            -- Calculate strain level based on character speed and direction
            local strain = humanoid.MoveDirection.Magnitude
            
            -- Adjust particle emission rate
            ropeEffects.strainParticles.Rate = 20 * strain
        else
            -- No movement, no strain
            ropeEffects.strainParticles.Rate = 0
        end
    end
}

-- Remove a rope visual for a specific player
function RopeVisualController:RemoveRopeVisual(player)
    if not player then return end
    
    local ropeEffects = self.activeRopes[player.UserId]
    if not ropeEffects then return end
    
    -- Disconnect all connections
    for _, connection in pairs(ropeEffects.connections) do
        connection:Disconnect()
    end
    
    -- Remove any created effects
    if ropeEffects.strainParticles and ropeEffects.strainParticles.Parent then
        ropeEffects.strainParticles:Destroy()
    end
    
    -- Remove from active ropes
    self.activeRopes[player.UserId] = nil
}

return RopeVisualController
