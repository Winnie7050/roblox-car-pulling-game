--[[
    Client.client.lua
    
    Main client script that initializes client-side controllers.
    This is the entry point for client-side code.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = require(script.Parent:WaitForChild("UIController"))
local RopeVisualController = require(script.Parent:WaitForChild("RopeVisualController"))

-- Wait for the client to be fully loaded
local player = Players.LocalPlayer
player.CharacterAdded:Wait()

-- Initialize client controllers
UIController:Initialize()
RopeVisualController:Initialize()

print("Car Pulling Game client initialized!")
