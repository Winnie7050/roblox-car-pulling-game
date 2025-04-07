--[[
    GameManager.lua
    
    Main server-side manager that initializes and coordinates all game systems.
    Acts as the central control point for the car pulling game.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Events = require(ReplicatedStorage:WaitForChild("Events"))

-- Import all manager modules
local CollisionManager = require(script.Parent:WaitForChild("CollisionManager"))
local PlayerManager = require(script.Parent:WaitForChild("PlayerManager"))
local CarManager = require(script.Parent:WaitForChild("CarManager"))
local RopeManager = require(script.Parent:WaitForChild("RopeManager"))

local GameManager = {}

-- Process when a player crosses the starting line
function GameManager:OnPlayerStartGame(player)
    if not player or not player.Character then return end
    
    -- Spawn a car for the player
    local carData = CarManager:SpawnCar(player)
    if not carData then
        warn("Failed to spawn car for player: " .. player.Name)
        return
    end
    
    -- Create a rope between player and car
    local ropeData = RopeManager:CreateRope(player, carData.car)
    if not ropeData then
        warn("Failed to create rope for player: " .. player.Name)
        return
    end
    
    -- Set player to pulling state
    PlayerManager:SetPullingState(player, true)
    
    -- Notify client
    Events:FireClient("GameStarted", player)
    
    print("Player started game: " .. player.Name)
end

-- Process when a player requests to reset/return
function GameManager:OnPlayerReset(player)
    if not player then return end
    
    -- Remove rope
    RopeManager:RemoveRope(player)
    
    -- Remove car
    CarManager:RemoveCar(player)
    
    -- Reset player state
    PlayerManager:ResetPlayer(player)
    
    -- Teleport player back to spawn
    local spawnLocation = workspace:FindFirstChild("SpawnLocation")
    if spawnLocation and player.Character then
        local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CFrame = spawnLocation.CFrame * CFrame.new(0, 3, 0) -- Offset to avoid clipping
        end
    end
    
    print("Player reset: " .. player.Name)
end

-- Set up event handlers
function GameManager:SetupEvents()
    -- Handle trigger for starting the game (crossing start line)
    Events:ConnectServer("GameStarted", function(player)
        self:OnPlayerStartGame(player)
    end)
    
    -- Handle player reset request
    Events:ConnectServer("PlayerReset", function(player)
        self:OnPlayerReset(player)
    end)
    
    print("Game events initialized")
end

-- Initialize the GameManager and all subsystems
function GameManager:Initialize()
    -- Initialize subsystems in the correct order
    CollisionManager:Initialize()
    PlayerManager:Initialize()
    CarManager:Initialize()
    RopeManager:Initialize()
    
    -- Setup event handlers
    self:SetupEvents()
    
    -- Set up any additional systems or triggers
    self:SetupStartTrigger()
    
    print("GameManager initialized")
end

-- Create a trigger at the start line
function GameManager:SetupStartTrigger()
    -- Check if trigger already exists
    local startTrigger = workspace:FindFirstChild("StartTrigger")
    if not startTrigger then
        -- Create a trigger part
        startTrigger = Instance.new("Part")
        startTrigger.Name = "StartTrigger"
        startTrigger.Size = Vector3.new(30, 10, 1) -- Wide but thin trigger zone
        startTrigger.Anchored = true
        startTrigger.CanCollide = false
        startTrigger.Transparency = 0.8
        startTrigger.Position = Vector3.new(0, 5, 10) -- Position at the start line
        startTrigger.Parent = workspace
        
        -- Create start line visual
        local startLine = Instance.new("Part")
        startLine.Name = "StartLine"
        startLine.Size = Vector3.new(30, 0.1, 1)
        startLine.Anchored = true
        startLine.CanCollide = false
        startLine.Position = Vector3.new(0, 0.05, 10)
        startLine.Color = Color3.fromRGB(255, 255, 255)
        startLine.Material = Enum.Material.Neon
        startLine.Parent = workspace
    end
    
    -- Connect to Touched event
    startTrigger.Touched:Connect(function(hit)
        local character = hit.Parent
        if not character:IsA("Model") then return end
        
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end
        
        -- Check if player is already pulling
        local playerData = PlayerManager.playerData[player.UserId]
        if playerData and playerData.isPullingCar then return end
        
        -- Start the game for this player
        self:OnPlayerStartGame(player)
    end)
    
    print("Start trigger set up")
end

return GameManager
