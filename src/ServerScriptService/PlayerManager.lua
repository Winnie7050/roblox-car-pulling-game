--[[
    PlayerManager.lua
    
    Manages player state, attributes, and progression.
    Handles player stamina, strength, and movement.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Utils"))
local Events = require(ReplicatedStorage:WaitForChild("Events"))

local CollisionManager = require(script.Parent:WaitForChild("CollisionManager"))

local PlayerManager = {}
PlayerManager.playerData = {} -- Store data by player UserId

-- Initialize a player when they join
function PlayerManager:InitializePlayer(player)
    -- Create data structure for player
    local playerData = {
        player = player,
        isPullingCar = false,
        startLinePosition = nil,
        distanceTraveled = 0,
        connections = {}
    }
    
    -- Set initial attributes that will replicate to client
    player:SetAttribute("Stamina", Config.Player.StaminaMax)
    player:SetAttribute("MaxStamina", Config.Player.StaminaMax)
    player:SetAttribute("Strength", Config.Progression.BaseStrength)
    player:SetAttribute("DistanceTraveled", 0)
    
    -- Save playerData
    self.playerData[player.UserId] = playerData
    
    -- Wait for character
    if player.Character then
        self:SetupCharacter(player, player.Character)
    end
    
    -- Connect to CharacterAdded for future respawns
    player.CharacterAdded:Connect(function(character)
        self:SetupCharacter(player, character)
    end)
    
    -- Setup background loop for this player
    local updateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:UpdatePlayer(player, deltaTime)
    end)
    
    table.insert(playerData.connections, updateConnection)
    
    print("Initialized player: " .. player.Name)
end

-- Set up character physics and events
function PlayerManager:SetupCharacter(player, character)
    local playerData = self.playerData[player.UserId]
    if not playerData then return end
    
    -- Setup collision group
    CollisionManager:SetupCharacterCollision(character)
    
    -- Get humanoid
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Set initial walk speed
    humanoid.WalkSpeed = Config.Player.BaseWalkSpeed
    
    -- Connect to humanoid state changes 
    local stateChangedConnection = humanoid.StateChanged:Connect(function(_, newState)
        self:OnHumanoidStateChanged(player, newState)
    end)
    
    table.insert(playerData.connections, stateChangedConnection)
    
    -- Reset pulling state when character is added
    playerData.isPullingCar = false
    
    print("Character setup for player: " .. player.Name)
end

-- Handle humanoid state changes
function PlayerManager:OnHumanoidStateChanged(player, newState)
    -- Handle specific states as needed (e.g., death, ragdoll, etc.)
    if newState == Enum.HumanoidStateType.Dead then
        -- Reset pulling state when character dies
        local playerData = self.playerData[player.UserId]
        if playerData then
            playerData.isPullingCar = false
        end
    end
end

-- Set player pulling state
function PlayerManager:SetPullingState(player, isPulling)
    local playerData = self.playerData[player.UserId]
    if not playerData then return end
    
    playerData.isPullingCar = isPulling
    
    -- Adjust walk speed based on pulling state
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if isPulling then
                humanoid.WalkSpeed = Config.Player.BasePullSpeed
            else
                humanoid.WalkSpeed = Config.Player.BaseWalkSpeed
            end
        end
    end
end

-- Update player state each frame
function PlayerManager:UpdatePlayer(player, deltaTime)
    local playerData = self.playerData[player.UserId]
    if not playerData or not player.Character then return end
    
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Update stamina
    self:UpdateStamina(player, humanoid, deltaTime)
    
    -- Update distance traveled
    self:UpdateDistance(player, character, deltaTime)
end

-- Update player stamina
function PlayerManager:UpdateStamina(player, humanoid, deltaTime)
    local currentStamina = player:GetAttribute("Stamina")
    if not currentStamina then return end
    
    local maxStamina = player:GetAttribute("MaxStamina") or Config.Player.StaminaMax
    local playerData = self.playerData[player.UserId]
    
    -- Check if player is moving
    local isMoving = humanoid.MoveDirection.Magnitude > 0
    
    -- Calculate stamina change
    local staminaChange = 0
    
    if isMoving and playerData.isPullingCar then
        -- Drain stamina when pulling and moving
        staminaChange = -Config.Player.StaminaDrainRate * deltaTime
    elseif not isMoving then
        -- Regenerate stamina when not moving
        staminaChange = Config.Player.StaminaRegenRate * deltaTime
    end
    
    -- Apply change
    local newStamina = Utils.clamp(currentStamina + staminaChange, 0, maxStamina)
    player:SetAttribute("Stamina", newStamina)
    
    -- Apply speed penalty if stamina is low
    if newStamina < maxStamina * 0.2 then
        humanoid.WalkSpeed = humanoid.WalkSpeed * Config.Player.StaminaLowPenalty
    end
    
    -- Notify clients of stamina update
    Events:FireClient("StaminaUpdate", player, newStamina, maxStamina)
end

-- Update player distance traveled
function PlayerManager:UpdateDistance(player, character, deltaTime)
    local playerData = self.playerData[player.UserId]
    if not playerData or not playerData.isPullingCar then return end
    
    -- Get character position
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- If start line position isn't set, use current position as reference
    if not playerData.startLinePosition then
        playerData.startLinePosition = humanoidRootPart.Position
        return
    end
    
    -- Calculate distance traveled along forward axis only (Z or X depending on your world)
    local currentPosition = humanoidRootPart.Position
    local startPosition = playerData.startLinePosition
    
    -- Get forward direction vector (assuming Z is forward)
    local forwardDirection = Vector3.new(0, 0, 1)
    
    -- Project the movement onto the forward axis only
    local movement = currentPosition - startPosition
    local distanceAlongAxis = math.abs(movement:Dot(forwardDirection))
    
    -- Update distance
    playerData.distanceTraveled = distanceAlongAxis
    player:SetAttribute("DistanceTraveled", math.floor(distanceAlongAxis))
    
    -- Notify clients of distance update
    local finishDistance = Config.Game.FinishLineDistance
    local percentage = math.min(100, (distanceAlongAxis / finishDistance) * 100)
    
    Events:FireClient("DistanceUpdate", player, 
        math.floor(distanceAlongAxis), 
        finishDistance, 
        percentage)
    
    -- Update strength based on distance
    self:UpdateStrength(player, distanceAlongAxis)
end

-- Update player strength based on distance traveled
function PlayerManager:UpdateStrength(player, distanceTraveled)
    -- Calculate strength based on distance traveled
    local baseStrength = Config.Progression.BaseStrength
    local strengthGain = distanceTraveled * Config.Progression.StrengthGainPerMeter
    
    local newStrength = baseStrength + strengthGain
    player:SetAttribute("Strength", newStrength)
    
    -- Notify clients of strength update
    Events:FireClient("StrengthUpdate", player, newStrength)
end

-- Reset player state (when they request to return to start)
function PlayerManager:ResetPlayer(player)
    local playerData = self.playerData[player.UserId]
    if not playerData then return end
    
    -- Reset pulling state
    playerData.isPullingCar = false
    
    -- Reset start line position
    playerData.startLinePosition = nil
    
    -- Reset distance traveled
    playerData.distanceTraveled = 0
    player:SetAttribute("DistanceTraveled", 0)
    
    -- Restore stamina
    player:SetAttribute("Stamina", player:GetAttribute("MaxStamina") or Config.Player.StaminaMax)
    
    -- Notify clients
    Events:FireClient("PlayerReset", player)
end

-- Clean up when player leaves
function PlayerManager:CleanupPlayer(player)
    local playerData = self.playerData[player.UserId]
    if not playerData then return end
    
    -- Disconnect all connections
    for _, connection in pairs(playerData.connections) do
        connection:Disconnect()
    end
    
    -- Remove player data
    self.playerData[player.UserId] = nil
    
    print("Cleaned up player: " .. player.Name)
end

-- Initialize the PlayerManager
function PlayerManager:Initialize()
    -- Set up existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayer(player)
    end
    
    -- Connect to PlayerAdded event
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayer(player)
    end)
    
    -- Connect to PlayerRemoving event
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayer(player)
    end)
    
    print("PlayerManager initialized")
end

return PlayerManager
