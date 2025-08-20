# CLAUDE.md - LibsArenaTools

This file provides guidance to Claude Code (claude.ai/code) when working with LibsArenaTools code in this repository.

## Project Overview

LibsArenaTools is a next-generation arena frames addon designed as both a standalone solution and a SpartanUI integrated module. It provides comprehensive arena functionality including cooldown tracking, diminishing returns, target calling, interrupt coordination, and advanced PvP features that surpass existing solutions like Gladius/GladiusEX.

**Core Objectives:**
- Replace basic arena frames with advanced functionality
- Provide superior performance and features compared to Gladius/GladiusEX
- Seamless SpartanUI integration with theme synchronization
- Standalone mode for non-SpartanUI users

## Architecture Overview

### Dual-Mode Design
LibsArenaTools operates in two distinct modes:

1. **SpartanUI Mode**: Full integration with SpartanUI's oUF system, theme engine, and configuration
2. **Standalone Mode**: Independent operation with minimal oUF environment and self-contained configuration

### Core Components

```
LibsArenaTools Architecture
├── Core Framework
│   ├── ArenaManager.lua - Arena state and unit management
│   ├── ElementRegistry.lua - oUF element registration system
│   ├── ConfigManager.lua - Configuration and database handling
│   ├── EventHandler.lua - Event coordination and management
│   └── PerformanceMonitor.lua - Performance tracking and optimization
├── oUF Arena Elements
│   ├── ArenaCooldowns.lua - Cooldown tracking with LibCooldownTracker
│   ├── ArenaDRTracker.lua - Diminishing returns with DRList integration
│   ├── ArenaSpecIcon.lua - Enhanced specialization detection
│   ├── ArenaTargetCalling.lua - Advanced target coordination
│   ├── ArenaInterrupts.lua - Intelligent interrupt tracking
│   ├── ArenaPvPTrinket.lua - PvP trinket and immunity tracking
│   ├── ArenaSkillHistory.lua - Ability usage pattern analysis
│   └── ArenaPreparation.lua - Enhanced arena prep functionality
├── SpartanUI Integration
│   ├── ThemeSync.lua - Theme synchronization across all SUI themes
│   ├── PositionManager.lua - Intelligent positioning with conflict resolution
│   ├── ConfigBridge.lua - Unified configuration in SUI options
│   └── EventRelay.lua - Cross-module event coordination
└── Standalone Mode
    ├── StandaloneCore.lua - Minimal oUF environment setup
    ├── StandaloneConfig.lua - Independent configuration system
    └── StandaloneThemes.lua - Basic theme system for non-SUI users
```

## Key Features

### Advanced Arena Elements
- **Cooldown Tracking**: Intelligent prioritization, categorization, and caching with LibCooldownTracker-1.0
- **Diminishing Returns**: Predictive DR calculation with DRList-1.0, immunity warnings, visual timeline
- **Target Calling**: Priority system, team coordination, highlight management
- **Interrupt Coordination**: Cast tracking, opportunity detection, team rotation suggestions
- **Spec Detection**: Enhanced opponent analysis with threat assessment
- **PvP Trinket Tracking**: Usage monitoring, vulnerability window prediction
- **Skill History**: Pattern recognition, usage frequency analysis

### SpartanUI Integration
- **Theme Synchronization**: Complete integration with all SpartanUI themes (Classic, War, Fel, Digital, Minimal, Tribal)
- **Position Coordination**: Automatic conflict resolution with other modules
- **Configuration Unity**: Seamless integration into SpartanUI options panel
- **Event Harmony**: Coordinated event handling with SpartanUI systems

### Performance Optimization
- **Intelligent Caching**: 100ms cache system for expensive operations
- **Update Batching**: 50ms batching for improved performance
- **Memory Management**: Object pooling and leak prevention
- **Event Filtering**: Smart event registration and throttling

## Development Patterns

### oUF Element Structure
All arena elements follow standardized oUF patterns:

```lua
---@class oUF.ArenaElement : oUF.Element
local ArenaElement = {}

ArenaElement.elementName = 'ElementName'
ArenaElement.events = {'EVENT_LIST'}
ArenaElement.defaults = {/* configuration defaults */}

function ArenaElement:Update(event, unit, ...)
    -- Core update logic with performance monitoring
end

function ArenaElement:Enable(frame)
    -- Element initialization and event registration
end

function ArenaElement:Disable(frame) 
    -- Cleanup and event unregistration
end

-- Register with oUF
oUF:AddElement('ElementName', Update, Enable, Disable)
```

### Configuration System
Uses hierarchical configuration with AceDB integration:

```lua
local defaults = {
    profile = {
        enabled = true,
        mode = 'enhanced', -- 'enhanced', 'basic', 'replace'
        elements = {
            ElementName = {
                enabled = true,
                -- Element-specific config
            }
        },
        positioning = {
            mode = 'auto', -- 'auto', 'manual', 'artwork'
            anchor = 'RIGHT',
            -- Position settings
        },
        theme = {
            mode = 'automatic', -- 'automatic', 'override', 'custom'
            useSpartanUITheme = true
        }
    }
}
```

### SpartanUI Module Integration
When running in SpartanUI mode:

```lua
---@class SUI.LibArenaTools : SUI.Module
local LibArenaTools = SUI:NewModule('LibArenaTools')

LibArenaTools.Config = {
    IsGroup = false,
    Core = false,
    RequiredModules = {'UnitFrames'},
    OptionalModules = {'Artwork'},
    Dependencies = {'oUF', 'LibCooldownTracker-1.0', 'DRList-1.0'}
}
```

## File Organization

### Core Structure
```
DataBrokerDisplay/LibsArenaTools/
├── LibArenaTools.lua                 # Main module file
├── Options.lua                       # Configuration interface
├── Migration.lua                     # GladiusEX migration tools
├── Core/
│   ├── ArenaManager.lua             # Arena state management
│   ├── ElementRegistry.lua          # Element registration system
│   ├── ConfigManager.lua            # Configuration handling
│   ├── EventHandler.lua             # Event management
│   └── PerformanceMonitor.lua       # Performance tracking
├── Elements/                        # oUF Arena Elements
│   ├── ArenaCooldowns.lua
│   ├── ArenaDRTracker.lua
│   ├── ArenaTargetCalling.lua
│   └── [other elements]
├── Integration/                     # SpartanUI Integration
│   ├── ThemeSync.lua
│   ├── PositionManager.lua
│   ├── ConfigBridge.lua
│   └── EventRelay.lua
├── Data/
│   ├── SpellData.lua               # Arena-specific spell information
│   ├── CooldownData.lua            # Enhanced cooldown priorities
│   └── SpecData.lua                # Specialization data
└── Standalone/
    ├── StandaloneCore.lua          # Standalone mode implementation
    ├── StandaloneConfig.lua        # Independent configuration
    └── StandaloneThemes.lua        # Basic theme system
```

## Dependencies

### Required Libraries
- **oUF**: Unit frame framework (core dependency)
- **LibCooldownTracker-1.0**: Cooldown tracking functionality
- **DRList-1.0**: Diminishing returns data and calculations

### Optional Libraries
- **LibCustomGlow**: Visual glow effects for highlights
- **LibSharedMedia-3.0**: Media resource management
- **LibRangeCheck-2.0**: Range checking capabilities

### SpartanUI Dependencies (when integrated)
- **SpartanUI Core**: Module system and base functionality
- **SpartanUI UnitFrames**: oUF integration and frame management
- **SpartanUI Artwork**: Theme and positioning systems

## Testing and Quality Assurance

### Performance Requirements
- Update times: <1ms average per element
- Memory usage: <10MB total footprint
- Event efficiency: Minimal registration, proper cleanup
- Cache utilization: 100ms intelligent caching

### Testing Framework
```lua
-- Automated testing structure
Tests/
├── UnitTests.lua              # Element functionality tests
├── IntegrationTests.lua       # SpartanUI integration tests
├── PerformanceTests.lua       # Performance benchmarks
└── CompatibilityTests.lua     # Addon compatibility tests
```

## Development Guidelines

### Code Standards
- Follow SpartanUI coding patterns when in integrated mode
- Use comprehensive LuaLS type annotations
- Implement proper error handling with pcall wrapping
- Include performance monitoring for all update functions
- Follow oUF element standards for consistency

### Configuration Guidelines
- Provide sensible defaults that work without configuration
- Use hierarchical structure for logical option grouping
- Include comprehensive validation and type checking
- Support both SpartanUI and standalone theme systems

### Integration Requirements
- Seamless SpartanUI module lifecycle integration
- Theme synchronization across all SpartanUI themes
- Intelligent position coordination with conflict resolution
- Unified configuration experience in SpartanUI options

## Migration and Compatibility

### Gladius/GladiusEX Migration
LibsArenaTools includes comprehensive migration tools for both Gladius and GladiusEX:
- Configuration analysis and conversion from existing setups
- Profile import with validation
- Feature mapping and adaptation
- Rollback functionality for safety

**Reference Implementation**: See `Examples\GladiusEx` for the codebase we're comparing against and improving upon.

### Backwards Compatibility
- Optional compatibility layer for addons expecting Gladius/GladiusEX APIs
- Event forwarding for integration points
- API mapping for common function calls

## Commands and Usage

### Chat Commands
- `/libarenatools` or `/lat` - Open configuration
- `/lat reload` - Reload configuration
- `/lat reset` - Reset to defaults
- `/lat migrate` - Run Gladius/GladiusEX migration wizard
- `/lat performance` - Show performance statistics

### Configuration Modes
- **Enhanced Mode**: All features enabled for maximum functionality
- **Basic Mode**: Core features only for performance
- **Replace Mode**: Simply replace default arena frames

This documentation provides the foundation for understanding and working with LibsArenaTools code, whether developing new features, debugging issues, or extending functionality for both standalone and SpartanUI integrated environments.