# Roblox Car Pulling Game

A physics-based Roblox game where players pull cars using rope physics. Players increase their pulling strength through training, allowing them to pull cars further and reach new levels.

## Project Structure

This repository is organized to mirror the Roblox service hierarchy:

```
/src
  /ServerScriptService   - Server-side scripts
  /ReplicatedStorage     - Shared modules and assets
  /StarterPlayerScripts  - Client-side scripts
  /StarterGui            - UI elements
```

## Core Features

- Physics-based rope pulling system
- Strength progression system
- Stamina management
- Distance tracking

## Development Notes

- Target platforms: Mobile (primary), Tablet, PC
- Performance optimized for older Android devices
- Using built-in RopeConstraint for better performance

## Technical Implementation

The game uses Roblox's physics system with a focus on:
- RopeConstraint with Winch functionality for pulling mechanics
- PhysicsService for collision management
- Network ownership optimization for seamless multiplayer

## Getting Started

1. Clone this repository
2. Open the `CarPullingGame.rbxl` file in Roblox Studio
3. Test the game in Play mode

## License

All rights reserved.