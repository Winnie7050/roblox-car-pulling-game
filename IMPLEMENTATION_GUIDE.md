# Car Pulling Game - Implementation Guide

This guide provides steps for implementing and testing the car pulling game using the provided codebase.

## Setup Instructions

1. Create a new Roblox experience in Studio
2. Import the script files to their respective locations:
   - `/src/ServerScriptService/*.lua` files go to `ServerScriptService`
   - `/src/ReplicatedStorage/*.lua` files go to `ReplicatedStorage`
   - `/src/StarterPlayerScripts/*.lua` files go to `StarterPlayer/StarterPlayerScripts`
   - Follow UI design guide in `/src/StarterGui/UI_DESIGN_GUIDE.md` to create UI

## Map Setup

1. Add a `SpawnLocation` in the workspace where players will start
2. The game automatically creates:
   - A start trigger part
   - A start line visual
   - Make sure there's a clear path from the spawn point to the start line and beyond

## Required Game Configurations

1. Make sure `CollisionGroups` are properly set up (the code handles this automatically)
2. Set appropriate `Workspace.Gravity` (default 196.2 should work fine)
3. Ensure `Filtering Enabled` is on (this is the default)

## Testing the Game

1. Run the game in Studio
2. Check console for initialization messages
3. Test the gameplay loop:
   - Walk to the start line
   - Car should spawn and attach with a rope
   - Pull the car while watching stamina bar
   - Walk as far as possible to increase strength
   - Test the reset functionality

## Customization Options

All game parameters can be adjusted in `ReplicatedStorage/Config.lua`:

- **Rope Physics**: Adjust rope length, thickness, elasticity
- **Car Properties**: Change mass, friction, spawn distance
- **Player Attributes**: Modify walk speed, stamina values, strength progression
- **Game Settings**: Alter distance tracking, finish line distance

## Code Architecture Overview

The game uses a modular architecture with a clear separation of concerns:

```
┌─────────────────┐     ┌─────────────────┐
│  GameManager    │────▶│  PlayerManager  │
└────────┬────────┘     └─────────────────┘
         │
         │              ┌─────────────────┐
         ├─────────────▶│   CarManager    │
         │              └─────────────────┘
         │
         │              ┌─────────────────┐
         ├─────────────▶│   RopeManager   │
         │              └─────────────────┘
         │
         │              ┌─────────────────┐
         └─────────────▶│CollisionManager │
                        └─────────────────┘
```

- **GameManager**: Central coordinator that initializes all systems
- **PlayerManager**: Handles player attributes, stamina, and progression
- **CarManager**: Manages car spawning, physics, and network ownership
- **RopeManager**: Creates and manages the rope physics via RopeConstraint
- **CollisionManager**: Sets up collision groups for proper physics interactions

## Client-Side Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Client Script  │────▶│  UIController   │
└────────┬────────┘     └─────────────────┘
         │
         │              ┌─────────────────┐
         └─────────────▶│RopeVisualControl│
                        └─────────────────┘
```

- **UIController**: Manages all UI elements and user input
- **RopeVisualController**: Adds visual effects to the rope pulling

## Event System

The game uses a centralized event system for client-server communication via `ReplicatedStorage/Events.lua`:

| Event | Direction | Purpose |
|-------|-----------|---------|
| GameStarted | Server → Client | Notify client that game has started |
| PlayerReset | Client → Server | Player requested to reset position |
| SpawnCar | Server → Client | Car has been spawned for a player |
| AttachRope | Server → Client | Rope has been attached |
| StaminaUpdate | Server → Client | Player's stamina has changed |
| DistanceUpdate | Server → Client | Player's distance has changed |

## Network Optimization

The game is optimized for mobile devices:

1. **Throttled Updates**: Car position updates are throttled to reduce network traffic
2. **Server Authority**: Cars and ropes are server-owned for physics stability
3. **Minimal Replication**: Only essential data is sent to clients

## Mobile Performance Considerations

1. **Simple Physics**: Using built-in RopeConstraint instead of custom implementation
2. **Efficient Network Usage**: Throttled updates and minimal replication
3. **Optimized UI**: Simple UI elements with minimal animations
4. **Collision Optimizations**: Proper collision groups to reduce physics calculations

## Debug Tools

For debugging:

1. Enable console output (`Ctrl+F9` in Studio)
2. Check initialization messages
3. Use PhysicsService visualization options (in Studio's View tab) to see:
   - Network Ownership
   - Collision Groups
   - Assemblies

## Common Issues

- **Car Spawning Issues**: Check that players can cross the start line trigger
- **Rope Physics Problems**: Ensure network ownership is properly set
- **UI Not Appearing**: Verify UI structure matches `UIController`'s expectations
- **Performance Issues**: Check for excessive physics calculations or network traffic

## Next Steps for Enhancement

- Add car model customization
- Implement persistent data saving
- Add more training activities
- Create a progression system with multiple levels
