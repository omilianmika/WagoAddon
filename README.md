# WagoAddon - PvP Next-Move WeakAura Helper

A World of Warcraft addon that helps you make optimal decisions in PvP combat by suggesting your next move based on your class and your opponent's class.

## Features

- Real-time next-move suggestions based on PvP strategies
- Visual icon showing the recommended spell to cast
- Automatic switching between offensive and defensive strategies
- Draggable interface with position saving
- Cooldown tracking overlay
- Spell tooltips on hover
- Range indicator
- Keybind display
- Saved variables for persistence
- Slash commands for easy control
- Support for all class matchups
- Advanced combat state tracking
- Conditional spell suggestions based on:
  - Target's health percentage
  - Player's health percentage
  - Target's casting state
  - Target's buffs and debuffs
  - Combat state
  - Range to target
  - Available spells and cooldowns

## Installation

1. Download the addon files
2. Place them in your World of Warcraft `_retail_\Interface\AddOns\WagoAddon` folder
3. Restart World of Warcraft or type `/reload` in-game

## Usage

The addon will automatically show a draggable icon when you target an enemy player. The icon will display the recommended spell to cast based on the current situation.

### Slash Commands

- `/wago` or `/wagoaddon` - Show available commands
- `/wago toggle` - Toggle the addon on/off
- `/wago reset` - Reset the position of the icon to center screen
- `/wago scale <number>` - Set the scale of the icon (0.5-2.0)
- `/wago alpha <number>` - Set the transparency of the icon (0.0-1.0)
- `/wago cooldown` - Toggle cooldown display
- `/wago range` - Toggle range indicator
- `/wago keybind` - Toggle keybind display

### Features

- The icon is draggable to any position on your screen and remembers its position
- Automatically switches between offensive and defensive strategies based on combat events
- Shows only spells that are available and not on cooldown
- Displays cooldown overlay on the icon
- Shows spell tooltips when hovering over the icon
- Range indicator shows when target is out of range
- Displays your keybind for the suggested spell
- Saves your preferences between sessions
- Advanced combat state tracking including:
  - Health percentages
  - Casting states
  - Buff and debuff tracking
  - Combat state
  - Range information

## Supported Classes

The addon supports strategies for all classes:
- Warrior
- Rogue
- Hunter
- Priest
- Mage
- Warlock
- Paladin
- Druid
- Shaman

Each class matchup includes both offensive and defensive strategies with sophisticated conditional logic for optimal spell suggestions based on:
- Target's current health
- Player's current health
- Target's casting state
- Target's buffs and debuffs
- Combat state
- Range to target
- Available spells and cooldowns

## Contributing

Feel free to submit issues and enhancement requests! 