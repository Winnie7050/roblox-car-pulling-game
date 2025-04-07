--[[
    Server.server.lua
    
    Main server script that initializes the game.
    This is the entry point for the server-side code.
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Load the GameManager
local GameManager = require(ServerScriptService:WaitForChild("GameManager"))

-- Initialize all game systems
GameManager:Initialize()

print("Car Pulling Game initialized!")
