--[[
    Config.lua
    
    Central configuration for the car pulling game.
    Contains tunable parameters for gameplay mechanics.
]]

local Config = {}

-- Rope System
Config.Rope = {
    InitialLength = 5, -- Initial rope length in studs
    Thickness = 0.15, -- Rope visual thickness
    Restitution = 0.3, -- Elasticity of the rope (0-1)
    Visible = true, -- Whether the rope is visible
}

-- Car System
Config.Car = {
    InitialDistance = 5, -- Distance behind player when spawned
    Mass = 1000, -- Mass of the car in kg
    Friction = 0.3, -- Ground friction coefficient
    CollisionGroup = "Cars", -- Collision group name
}

-- Player System
Config.Player = {
    BaseWalkSpeed = 16, -- Base walk speed
    BasePullSpeed = 8, -- Base speed while pulling
    StaminaMax = 100, -- Maximum stamina
    StaminaRegenRate = 5, -- Stamina regeneration per second
    StaminaDrainRate = 10, -- Stamina drain per second while pulling
    StaminaLowPenalty = 0.5, -- Multiplier for speed when stamina is low
    CollisionGroup = "Players", -- Collision group name
}

-- Progression System
Config.Progression = {
    BaseStrength = 1, -- Starting strength level
    StrengthGainPerMeter = 0.01, -- Strength gain per meter traveled
    StrengthPullForceMultiplier = 50, -- How much each strength level affects pull force
}

-- Game Settings
Config.Game = {
    DistanceTrackingInterval = 0.1, -- How often to update distance (seconds)
    FinishLineDistance = 100, -- Distance to the finish line in studs
    MobileOptimizationEnabled = true, -- Enable mobile-specific optimizations
}

return Config
