# Ace3 Libraries Documentation

This document provides a consolidated reference for the Ace3 libraries available in SpartanUI that are relevant for LibsDataBar development.

## Core Addon Framework

### AceAddon-3.0
**Purpose**: Primary addon framework providing structured initialization and lifecycle management.

**Key Features**:
- Structured addon creation with `LibStub("AceAddon-3.0"):NewAddon("AddonName")`
- Lifecycle callbacks: `OnInitialize()`, `OnEnable()`, `OnDisable()`
- Module system for organizing code into discrete components
- Automatic library embedding system

**Usage for LibsDataBar**:
- Replace LibStub library pattern with proper addon pattern
- Provides proper initialization order and event handling
- Essential for text display timing issues

**Example**:
```lua
local LibsDataBar = LibStub("AceAddon-3.0"):NewAddon("LibsDataBar", "AceEvent-3.0", "AceTimer-3.0")

function LibsDataBar:OnInitialize()
    -- Initialize configuration, plugins, etc.
end

function LibsDataBar:OnEnable()
    -- Start timers, register events, show displays
end
```

### AceEvent-3.0
**Purpose**: Event registration and handling system.

**Key Features**:
- Simplified event registration: `RegisterEvent("EVENT_NAME")`
- Automatic cleanup on disable
- Message passing system for inter-addon communication
- Bucket events for throttling high-frequency events

**Usage for LibsDataBar**:
- Replace manual event frame creation
- Handle plugin updates, configuration changes
- System events for bar updates

## Configuration and Data Management

### AceDB-3.0
**Purpose**: Saved variables management with profiles, defaults, and validation.

**Key Features**:
- Profile system (per-character, realm, global)
- Automatic defaults merging
- Database callbacks for configuration changes
- Built-in profile switching UI

**Usage for LibsDataBar**:
- Replace manual SavedVariables handling
- Provide robust configuration storage
- Enable profile system for different characters/specs

### AceConfig-3.0
**Purpose**: Configuration UI framework with automatic option panel generation.

**Key Features**:
- Declarative option tables
- Automatic Settings panel integration
- Type validation and callbacks
- Hierarchical configuration structure

**Usage for LibsDataBar**:
- Generate plugin configuration panels
- Replace manual option frame creation
- Provide consistent UI across all plugins

### AceDBOptions-3.0
**Purpose**: Automatic profile management options for AceDB databases.

**Key Features**:
- Pre-built profile switching interface
- Copy/delete/reset profile functionality
- Integrates seamlessly with AceConfig

## Timing and Performance

### AceTimer-3.0 ⭐ **CRITICAL FOR TEXT DISPLAY FIX**
**Purpose**: Efficient timer management system.

**Key Features**:
- High-precision timers with 0.01s resolution
- One-shot and repeating timers
- Automatic cleanup on addon disable
- Efficient data structures for timer management

**Usage for LibsDataBar**:
- **Fix text display issues by scheduling updates after game data is ready**
- Throttle plugin updates for performance
- Schedule periodic refreshes of data text
- Handle delayed initialization

**Example for fixing text display**:
```lua
function LibsDataBar:OnEnable()
    -- Schedule initial update after game data is fully loaded
    self:ScheduleTimer("UpdateAllBars", 1.0)
    
    -- Set up periodic updates
    self.updateTimer = self:ScheduleRepeatingTimer("UpdateAllBars", 5.0)
end
```

### AceBucket-3.0
**Purpose**: Event throttling and batching system.

**Key Features**:
- Combine multiple rapid events into single callbacks
- Configurable bucket intervals
- Automatic event filtering

**Usage for LibsDataBar**:
- Throttle rapid-fire events like bag updates, currency changes
- Improve performance by batching UI updates

## User Interface

### AceGUI-3.0
**Purpose**: Widget library for creating custom UI elements.

**Key Features**:
- Pre-built widgets (buttons, sliders, dropdowns, etc.)
- Layout containers and management
- Event handling and callbacks
- Styling and theming support

**Usage for LibsDataBar**:
- Create custom configuration panels
- Build plugin wizards and advanced UIs
- Enhance user experience beyond basic AceConfig options

### AceConsole-3.0
**Purpose**: Slash command and chat command processing.

**Key Features**:
- Automatic command parsing and validation
- Help text generation
- Command aliasing and shortcuts
- Integration with AceConfig for command-line options

**Usage for LibsDataBar**:
- Provide /libsdatabar commands for debugging
- Enable quick configuration changes via chat
- Developer tools and diagnostics

## Communication and Serialization

### AceComm-3.0
**Purpose**: Addon communication system for multi-user features.

**Key Features**:
- Cross-addon messaging
- Guild/party communication
- Automatic serialization/deserialization
- Throttling and priority management

**Usage for LibsDataBar**:
- Share configurations between guild members
- Synchronize themes across characters
- Future features like shared plugin settings

### AceSerializer-3.0
**Purpose**: Lua table serialization and compression.

**Key Features**:
- Convert tables to strings and back
- Data compression for storage/transmission
- Version-safe serialization

**Usage for LibsDataBar**:
- Export/import configuration profiles
- Store complex configuration data
- Network communication payload preparation

## Hook and Override System

### AceHook-3.0
**Purpose**: Safe function hooking without conflicts.

**Key Features**:
- Pre/post hooks with automatic restoration
- Secure hooking that prevents taint
- Conflict resolution between multiple addons
- Automatic cleanup on disable

**Usage for LibsDataBar**:
- Hook Blizzard UI elements for integration
- Modify existing addon behavior safely
- Create compatibility layers with other addons

## Localization

### AceLocale-3.0
**Purpose**: Multi-language support system.

**Key Features**:
- Dynamic locale switching
- Fallback language support
- Memory-efficient string storage
- Development aids for translation

**Usage for LibsDataBar**:
- Support multiple languages for international users
- Provide localized configuration options
- Enable community translations

## Summary of Critical Libraries for LibsDataBar Refactor

**Phase 1 - Core Framework** (Essential):
1. **AceAddon-3.0** - Convert from library to addon pattern
2. **AceTimer-3.0** - Fix text display timing issues
3. **AceEvent-3.0** - Replace manual event handling

**Phase 2 - Configuration** (High Priority):
4. **AceDB-3.0** - Robust saved variables management
5. **AceConfig-3.0** - Automated configuration UI

**Phase 3 - Polish** (Medium Priority):
6. **AceBucket-3.0** - Performance optimization
7. **AceConsole-3.0** - Developer and user commands
8. **AceDBOptions-3.0** - Profile management UI