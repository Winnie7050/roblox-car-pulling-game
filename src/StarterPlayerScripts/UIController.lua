--[[
    UIController.lua
    
    Client-side module that handles UI elements and interactions.
    Manages stamina bar, distance meter, and reset button.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Events = require(ReplicatedStorage:WaitForChild("Events"))
local Utils = require(ReplicatedStorage:WaitForChild("Utils"))

local UIController = {}
UIController.uiElements = {}

-- Initialize UI elements
function UIController:Initialize()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Wait for UI to be available (you will create these UI elements)
    local mainUI = playerGui:WaitForChild("MainUI")
    
    -- Store references to UI elements
    self.uiElements = {
        staminaBar = mainUI:WaitForChild("StaminaBar"),
        staminaFill = mainUI.StaminaBar:WaitForChild("Fill"),
        distanceMeter = mainUI:WaitForChild("DistanceMeter"),
        distanceText = mainUI.DistanceMeter:WaitForChild("Text"),
        resetButton = mainUI:WaitForChild("ResetButton"),
        resetPrompt = mainUI:WaitForChild("ResetPrompt"),
        promptYesButton = mainUI.ResetPrompt:WaitForChild("YesButton"),
        promptNoButton = mainUI.ResetPrompt:WaitForChild("NoButton"),
    }
    
    -- Hide elements initially
    self:SetElementsVisible(false)
    self.uiElements.resetPrompt.Visible = false
    
    -- Connect UI events
    self:ConnectUIEvents()
    
    -- Connect to game events
    self:ConnectGameEvents()
    
    print("UIController initialized")
end

-- Connect UI button events
function UIController:ConnectUIEvents()
    -- Reset button
    self.uiElements.resetButton.MouseButton1Click:Connect(function()
        self:ShowResetPrompt()
    end)
    
    -- Prompt Yes button
    self.uiElements.promptYesButton.MouseButton1Click:Connect(function()
        self:ResetPlayer()
    end)
    
    -- Prompt No button
    self.uiElements.promptNoButton.MouseButton1Click:Connect(function()
        self.uiElements.resetPrompt.Visible = false
    end)
end

-- Connect to game events
function UIController:ConnectGameEvents()
    -- Game started event
    Events:ConnectClient("GameStarted", function()
        self:SetElementsVisible(true)
    end)
    
    -- Stamina update event
    Events:ConnectClient("StaminaUpdate", function(currentStamina, maxStamina)
        self:UpdateStaminaBar(currentStamina, maxStamina)
    end)
    
    -- Distance update event
    Events:ConnectClient("DistanceUpdate", function(distance, maxDistance, percentage)
        self:UpdateDistanceMeter(distance, maxDistance, percentage)
    end)
    
    -- Player reset event
    Events:ConnectClient("PlayerReset", function()
        self:SetElementsVisible(false)
    end)
}

-- Update stamina bar
function UIController:UpdateStaminaBar(currentStamina, maxStamina)
    -- Calculate fill percentage
    local fillPercentage = currentStamina / maxStamina
    
    -- Update bar
    self.uiElements.staminaFill.Size = UDim2.new(fillPercentage, 0, 1, 0)
    
    -- Change color based on stamina level
    if fillPercentage < 0.2 then
        -- Low stamina - red
        self.uiElements.staminaFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    elseif fillPercentage < 0.5 then
        -- Medium stamina - yellow
        self.uiElements.staminaFill.BackgroundColor3 = Color3.fromRGB(255, 255, 50)
    else
        -- High stamina - green
        self.uiElements.staminaFill.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    end
end

-- Update distance meter
function UIController:UpdateDistanceMeter(distance, maxDistance, percentage)
    -- Format text
    local formattedText = string.format(
        "Travelled %d/%d (%d%%)", 
        distance, 
        maxDistance, 
        math.floor(percentage)
    )
    
    -- Update text
    self.uiElements.distanceText.Text = formattedText
}

-- Show reset confirmation prompt
function UIController:ShowResetPrompt()
    local player = Players.LocalPlayer
    local distance = player:GetAttribute("DistanceTraveled") or 0
    
    -- Update prompt text with distance information
    self.uiElements.resetPrompt.PromptText.Text = string.format(
        "Are you sure you want to reset?\nYou travelled %d studs.",
        distance
    )
    
    -- Show prompt
    self.uiElements.resetPrompt.Visible = true
}

-- Reset player (confirm reset)
function UIController:ResetPlayer()
    -- Hide prompt
    self.uiElements.resetPrompt.Visible = false
    
    -- Fire reset event to server
    Events:FireServer("PlayerReset")
}

-- Set UI elements visibility
function UIController:SetElementsVisible(visible)
    self.uiElements.staminaBar.Visible = visible
    self.uiElements.distanceMeter.Visible = visible
    self.uiElements.resetButton.Visible = visible
}

return UIController
