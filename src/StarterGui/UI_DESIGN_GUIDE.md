# UI Design Guide for Car Pulling Game

This document outlines the required UI elements for the Car Pulling game, their structure, and how they should interact with the game systems.

## Required UI Elements

The game requires the following UI elements:

1. **Stamina Bar** - Right side of screen
2. **Distance Meter** - Top of screen
3. **Return Button** - Bottom of screen
4. **Reset Confirmation Dialog** - Center of screen (popup)

## UI Structure

Create a ScreenGui named `MainUI` with the following structure:

```
MainUI (ScreenGui)
├── StaminaBar (Frame)
│   └── Fill (Frame)
├── DistanceMeter (Frame)
│   └── Text (TextLabel)
├── ResetButton (TextButton)
└── ResetPrompt (Frame)
    ├── PromptText (TextLabel)
    ├── YesButton (TextButton)
    └── NoButton (TextButton)
```

## Element Specifications

### Stamina Bar

- **Position**: Right side of screen, vertical orientation
- **Size**: ~60-80% of screen height, fixed width (~30-40 pixels)
- **Behavior**: Fill level decreases as stamina is used, refills when resting
- **Color**: Green when full, yellow at medium levels, red when low

### Distance Meter

- **Position**: Top center of screen
- **Size**: ~50% of screen width, fixed height
- **Content**: Text displaying "Travelled X/X (X%)" in studs
- **Behavior**: Updates as player moves with car

### Reset Button

- **Position**: Bottom center of screen
- **Size**: ~120 x 40 pixels
- **Content**: "Return" text with contrasting colors
- **Behavior**: Shows reset confirmation dialog when clicked

### Reset Confirmation Dialog

- **Position**: Center of screen (modal popup)
- **Size**: ~300 x 200 pixels
- **Content**: 
  - "Are you sure you want to reset? You travelled X/X" text
  - "Yes" and "No" buttons
- **Behavior**: 
  - Initially hidden
  - Appears when Reset Button is clicked
  - "Yes" triggers reset and teleports player back to start
  - "No" dismisses the dialog

## Mobile Considerations

- All elements should be appropriately sized for touch input
- Buttons should be at least 44x44 pixels for touch targets
- Text should be large enough to read on small screens
- UI elements should work in both portrait and landscape orientations

## Implementation Notes

1. The code in `UIController.lua` expects these specific UI element names to find and control them
2. All primary UI elements should start hidden and only appear when the game starts
3. The Reset Confirmation dialog should always start hidden
4. Ensure the UI is anchored appropriately to work on different screen sizes
5. For optimal mobile performance, use minimal UI animations and effects

## Reference Example

A simple diagram showing the layout of UI elements:

```
+----------------------------------------------------------+
|                                                          |
|                   [Distance Meter]                       |
|                                                          |
|                                                          |
|                                                     [S]  |
|                                                     [T]  |
|                                                     [A]  |
|                                                     [M]  |
|                                                     [I]  |
|                                                     [N]  |
|                                                     [A]  |
|                                                          |
|                                                          |
|                      [Return]                            |
|                                                          |
+----------------------------------------------------------+

Reset Confirmation Dialog (Popup):
+----------------------------+
|                            |
| Are you sure you want to   |
| reset?                     |
|                            |
| You travelled 85/100       |
|                            |
|   [Yes]          [No]      |
|                            |
+----------------------------+
```

These UI elements should be created as children of the MainUI ScreenGui in StarterGui.
