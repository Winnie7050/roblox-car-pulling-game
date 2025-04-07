--[[
    RopeManager.lua
    
    Manages the creation, physics, and removal of ropes.
    Uses RopeConstraint for optimal performance and physics simulation.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Utils"))
local Events = require(ReplicatedStorage:WaitForChild("Events"))

local RopeManager = {}
RopeManager.activeRopes = {} -- Store references to active ropes by player userId

-- Create a rope between a player and a car
function RopeManager:CreateRope(player, car)
    if not player or not player.Character or not car then
        warn("Cannot create rope - missing player character or car")
        return nil
    end
    
    -- Remove any existing rope for this player
    self:RemoveRope(player)
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local carPrimaryPart = car:FindFirstChild("PRIMARY")
    
    if not humanoidRootPart or not carPrimaryPart then
        warn("Cannot create rope - missing required parts")
        return nil
    end
    
    -- Create attachment points
    local playerAttachment = Instance.new("Attachment")
    playerAttachment.Name = "RopeAttachment"
    playerAttachment.Position = Vector3.new(0, 0, 0.5) -- Slightly behind the character
    playerAttachment.Parent = humanoidRootPart
    
    local carAttachment = Instance.new("Attachment")
    carAttachment.Name = "RopeAttachment"
    carAttachment.Position = Vector3.new(0, 0, -carPrimaryPart.Size.Z/2) -- Front of the car
    carAttachment.Parent = carPrimaryPart
    
    -- Create rope constraint
    local ropeConstraint = Instance.new("RopeConstraint")
    ropeConstraint.Name = "PlayerRope_" .. player.UserId
    ropeConstraint.Visible = Config.Rope.Visible
    ropeConstraint.Thickness = Config.Rope.Thickness
    ropeConstraint.Length = Config.Rope.InitialLength
    ropeConstraint.Restitution = Config.Rope.Restitution
    ropeConstraint.Attachment0 = playerAttachment
    ropeConstraint.Attachment1 = carAttachment
    
    -- Tag the rope for easy access
    CollectionService:AddTag(ropeConstraint, "PlayerRope")
    
    -- Store connections and instances for cleanup
    local ropeData = {
        player = player,
        car = car,
        constraint = ropeConstraint,
        playerAttachment = playerAttachment,
        carAttachment = carAttachment,
        connections = {},
        winchEnabled = false
    }
    
    -- Create update connection to handle winch behavior based on player strength
    local updateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:UpdateRope(ropeData, deltaTime)
    end)
    
    table.insert(ropeData.connections, updateConnection)
    
    -- Store the rope data
    self.activeRopes[player.UserId] = ropeData
    
    -- Parent the constraint last to ensure everything is set up correctly
    ropeConstraint.Parent = workspace
    
    -- Notify clients
    Events:FireAllClients("AttachRope", player, car)
    
    return ropeData
end

-- Update a rope's physics behavior
function RopeManager:UpdateRope(ropeData, deltaTime)
    if not ropeData or not ropeData.constraint then return end
    
    local player = ropeData.player
    if not player or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Check if player is moving
    local isMoving = humanoid.MoveDirection.Magnitude > 0
    
    -- Enable winch if the player is moving forward relative to the rope
    local constraint = ropeData.constraint
    local playerAttachment = ropeData.playerAttachment
    local carAttachment = ropeData.carAttachment
    
    if isMoving then
        -- Only enable winch if player is moving in a direction that would pull the car
        local playerPosition = playerAttachment.WorldPosition
        local carPosition = carAttachment.WorldPosition
        
        local ropeDirection = (carPosition - playerPosition).Unit
        local moveDirection = humanoid.MoveDirection.Unit
        
        -- Dot product to determine if player is moving away from the car
        local pullFactor = -moveDirection:Dot(ropeDirection)
        
        if pullFactor > 0 then
            -- Player is pulling the car
            local strength = player:GetAttribute("Strength") or Config.Progression.BaseStrength
            
            -- Enable the winch to pull the car
            constraint.WinchEnabled = true
            constraint.WinchTarget = math.max(1, constraint.Length - 0.5) -- Gradually reduce length
            constraint.WinchSpeed = strength * 0.5 -- Speed based on strength
            constraint.WinchForce = strength * Config.Progression.StrengthPullForceMultiplier -- Force based on strength
            ropeData.winchEnabled = true
        else
            -- Player is moving toward the car, disable winch
            constraint.WinchEnabled = false
            ropeData.winchEnabled = false
        end
    else
        -- Player not moving, disable winch
        constraint.WinchEnabled = false
        ropeData.winchEnabled = false
    end
end

-- Remove a rope for a specific player
function RopeManager:RemoveRope(player)
    if not player then return end
    
    local ropeData = self.activeRopes[player.UserId]
    if not ropeData then return end
    
    -- Disconnect all connections
    for _, connection in pairs(ropeData.connections) do
        connection:Disconnect()
    end
    
    -- Destroy constraint and attachments
    if ropeData.constraint and ropeData.constraint.Parent then
        ropeData.constraint:Destroy()
    end
    
    if ropeData.playerAttachment and ropeData.playerAttachment.Parent then
        ropeData.playerAttachment:Destroy()
    end
    
    if ropeData.carAttachment and ropeData.carAttachment.Parent then
        ropeData.carAttachment:Destroy()
    end
    
    -- Remove from active ropes
    self.activeRopes[player.UserId] = nil
    
    -- Notify clients
    Events:FireAllClients("DetachRope", player)
end

-- Remove all ropes
function RopeManager:RemoveAllRopes()
    for userId, _ in pairs(self.activeRopes) do
        local player = game.Players:GetPlayerByUserId(userId)
        if player then
            self:RemoveRope(player)
        end
    end
end

-- Check if a player has an active rope
function RopeManager:HasRope(player)
    if not player then return false end
    return self.activeRopes[player.UserId] ~= nil
end

-- Get a player's active rope data
function RopeManager:GetRopeData(player)
    if not player then return nil end
    return self.activeRopes[player.UserId]
end

-- Initialize the RopeManager
function RopeManager:Initialize()
    -- Clean up when players leave
    game.Players.PlayerRemoving:Connect(function(player)
        self:RemoveRope(player)
    end)
    
    -- Clean up when the game shuts down
    game:BindToClose(function()
        self:RemoveAllRopes()
    end)
    
    print("RopeManager initialized")
end

return RopeManager
