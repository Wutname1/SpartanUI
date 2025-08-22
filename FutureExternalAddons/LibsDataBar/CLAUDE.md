# CLAUDE.md - LibsDataBar Project

This file provides guidance to Claude Code when working with the LibsDataBar addon development project.

## Project Overview

LibsDataBar is an ambitious next-generation data broker display addon for World of Warcraft, designed to challenge TitanPanel's market dominance (48.2M downloads) through superior architecture, modern features, and exceptional developer experience. The project aims to combine the best aspects of existing solutions while adding revolutionary positioning capabilities and modern development practices.

## Core Mission

**Target Goals:**

- **Performance**: Match Bazooka's efficiency (<2ms updates, <50MB memory)
- **Ecosystem**: Exceed TitanPanel's plugin compatibility and developer experience
- **User Experience**: Surpass ChocolateBar's modern interface and customization
- **Innovation**: Revolutionary flexible positioning system, performance analytics, and developer tools

## Competitive Analysis & Reference Materials

### Primary Comparison Addons (Located in `Examples/` folder)

We are comparing ourselves to and basing our architecture on these three major data broker display addons:

1. **TitanPanel** (`Examples/TitanPanel-8.3.3/`) - **Market Leader (48.2M downloads)**

   - Comprehensive plugin ecosystem with hundreds of options
   - Excellent developer documentation and tools
   - Professional quality with 15+ years of refinement
   - **We MUST achieve 100% TitanPanel plugin compatibility**

2. **ChocolateBar** (`Examples/ChocolateBar/`) - **Modern UX Leader (1.2M downloads)**

   - Superior modern UX with smooth drag-and-drop interface
   - Better code organization and maintainability
   - Flexible bar positioning and configuration
   - Advanced visual customization options

3. **Bazooka** (`Examples/Bazooka-v3.2.0/`) - **Performance Champion (962.7K downloads)**
   - Exceptional performance and minimal resource usage
   - Lightweight architecture with fewer dependencies
   - Simple, clean interface focused on core functionality

### ElvUI Plugin Analysis (Located in `Examples/ElvUI_DataModules/`)

ElvUI is the king of UI addons and far surpasses even TitanPanel in features. While we **DO NOT** want to copy ElvUI's approach (it does things its own way), we **DO** want to ensure we capture and include their comprehensive featureset, especially in the plugin area.

**Key ElvUI DataModules to implement:**

- Agility, Armor, AttackPower, Avoidance, Block, Crit, Defense, Dodge, Parry
- Battlegrounds, CombatIndicator, CombatTime, Difficulty
- Coordinates, Currencies, CustomCurrency, Date, Time
- DPS, HPS, Durability, Experience, Friends, Guild, Mail
- ItemLevel, Location, MovementSpeed, Quests, Reputation
- System performance metrics, Volume controls
- And many more comprehensive data display options

**Reference Policy**: We are 100% OK to copy code from the reference material in the `Examples/` folder. These are our benchmarks and learning resources.

## Revolutionary Positioning System ⭐

**Our Key Competitive Advantage**: LibsDataBar offers a dual-mode display system that no other data broker addon provides:

1. **Traditional Bars**: Full-width bars like TitanPanel/ChocolateBar for familiar usage
2. **Smart Containers**: Flexible, moveable rectangles that can be positioned anywhere on screen

This allows users to create highly customized layouts impossible with competing addons:

- 3-item horizontal container above chat box
- Vertical sidebar container with 5 plugins on screen edge
- Corner mini-containers for critical info near action bars
- Floating containers that follow screen real estate usage
- Mixed layouts with both bars and containers simultaneously

## Development Architecture

### Core Components

1. **LibsDataBar-1.0** - Core library with LibStub registration
2. **Display Engine** - DataBar and revolutionary Container classes
3. **Plugin System** - Native + LibDataBroker 1.1 compatibility
4. **Theme System** - Professional themes with real-time switching
5. **Configuration** - AceDB integration with hierarchical config
6. **Performance Framework** - Built-in profiling and optimization
7. **Developer Tools** - Plugin templates, validator, debugger, hot-reload

### Key Development Principles

- **Performance First**: Zero-cost abstractions, lazy loading, efficient event batching
- **Developer Experience**: Modern tools, comprehensive docs, rich debugging
- **Ecosystem Compatibility**: Full TitanPanel + LDB compatibility for easy migration
- **Code Quality**: Modern Lua with comprehensive type annotations

## Current Status: Phase 1 Complete ✅

**100% Complete Foundation:**

- ✅ Core LibsDataBar-1.0 library fully implemented
- ✅ Revolutionary positioning system (DataBar + Container classes)
- ✅ 10 comprehensive plugins fully functional
- ✅ Plugin system with lifecycle management
- ✅ LibDataBroker compatibility layer
- ✅ Configuration system with AceConfig integration
- ✅ Performance monitoring and profiling framework
- ✅ Advanced animation system with 7 presets
- ✅ Professional theme system with 6 themes
- ✅ Developer tools (templates, validator, debugger, hot-reload)

**Next Phase**: TitanPanel compatibility adapter and plugin marketplace

## Plugin Development

### Built-in Plugins (All Complete)

- Clock (time/date with timezone support)
- Currency/Gold (character totals with color coding)
- Performance (FPS, latency, memory with analysis)
- Location (coordinates, PvP status, resting state)
- Bags (space tracking with quality indicators)
- Volume (master/music/sound control)
- Experience (XP progress with rested tracking)
- Repair (durability monitoring with cost estimation)
- PlayedTime (character playtime with session info)
- Reputation (faction progress with paragon support)

### Plugin Template System

- Native LibsDataBar plugin template with full lifecycle
- LDB plugin template for compatibility
- Interactive plugin wizard for rapid development
- Validation system with quality scoring

## SpartanUI Integration

LibsDataBar integrates seamlessly with SpartanUI:

- Theme synchronization with SpartanUI themes
- Unified configuration experience

## Key Files & Structure

- **LibsDataBar.lua** - Main library entry point
- **Loader.xml** - Load order management
- **Display/** - DataBar, Container, PluginButton, ThemeManager, AnimationManager
- **Configuration/** - ConfigManager, PluginManager
- **Developer/** - Debugger, HotReload, PluginTemplates, PluginValidator, PluginWizard
- **Plugins/** - All built-in plugins and LDBAdapter
- **Integration/** - SpartanUI.lua for seamless integration
- **Options.lua** - AceConfig interface

## Available Libraries

**Core Framework** (see `Claude/libdocumentation/Ace3-Libraries.md`):
- **AceAddon-3.0** - Addon lifecycle and module management
- **AceTimer-3.0** - Efficient timer system (critical for text display fixes)
- **AceEvent-3.0** - Event registration and handling
- **AceDB-3.0** - Saved variables with profiles
- **AceConfig-3.0** - Automatic configuration UI generation

**UI Enhancement** (see `Claude/libdocumentation/Other-Libraries.md`):
- **LibQTip-1.0** - Advanced multi-column tooltips
- **LibSharedMedia-3.0** - Theme system media integration
- **LibEditMode** - Modern positioning with Edit Mode integration
- **LibDataBroker-1.1** - Plugin ecosystem compatibility

## Development Commands

- `/libsdatabar` or `/ldb` - Open main options window
- Hot-reload enabled for rapid development iteration
- Built-in performance profiling and debug logging
- Plugin validation with quality scoring

## Strategic Goals

1. **Migration Strategy**: Full TitanPanel compatibility to ease user transition
2. **Performance Leadership**: Outperform all competitors in speed and efficiency
3. **Developer Focus**: Best-in-class tools to attract plugin developers
4. **Innovation**: Modern features not available in existing solutions (cloud sync, AI recommendations, advanced analytics)

The project represents an opportunity to modernize the data broker display category by combining TitanPanel's ecosystem depth with ChocolateBar's UX excellence and Bazooka's performance efficiency, while adding revolutionary positioning capabilities that no competitor offers.
