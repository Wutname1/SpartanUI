# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpartanUI is a comprehensive World of Warcraft addon that provides a complete user interface overhaul. It moves interface elements to the bottom of the screen to free up screen real estate and includes modular components for various gameplay features.

## Core Architecture

### Main Framework

- **Core/Framework.lua**: Main addon initialization, library management, and core SUI object setup
- **SpartanUI.toc**: Addon manifest defining load order and dependencies
- **Framework.Definition.lua**: Type definitions and framework structure

### Module System

The addon uses a modular architecture where each feature is a separate module:

- **Modules/**: Contains all feature modules (Minimap, UnitFrames, Artwork, etc.)
- **Core/Handlers/**: Core functionality handlers (Events, Options, Profiles, etc.)
- Each module typically has its own Options.lua file for configuration

### Theme System

- **Themes/**: Multiple visual themes (Classic, War, Fel, Digital, etc.)
- **\_Theme.Definition.lua**: Base theme structure
- Each theme has Style.lua and Style.xml files plus image assets

### Libraries

- **libs/**: Third-party libraries including Ace3, oUF (unit frames), LibSharedMedia
- Uses LibStub for library management
- Extensive use of Ace3 framework for addon structure
- **LibAT.UI**: UI widget system provided by Libs-AddonTools for creating windows, buttons, checkboxes, etc.

## Key Commands

### Chat Commands

- `/sui` - Opens main options window
- `/sui > ModuleName` - Navigate directly to specific module options (e.g. `/sui > Artwork`)
- `/rl` - Reload UI (custom slash command)

### Development

This is a WoW addon project with no traditional build system. Development workflow:

1. Edit Lua/XML files directly
2. Use `/rl` in-game to reload changes
3. Test changes in World of Warcraft client

## File Structure Patterns

### Module Structure

```
Modules/ModuleName/
├── ModuleName.lua          # Main module logic
├── Options.lua             # Configuration options
└── Load.xml               # XML loader (if needed)
```

### Unit Frames

```
Modules/UnitFrames/
├── Framework.lua           # Main UF framework
├── Options.lua            # UF options
├── Elements/              # Individual UF elements (Health, Power, etc.)
├── Units/                 # Unit-specific configurations
└── Handlers/              # UF handlers (Style, Auras, etc.)
```

## Development Notes

### Lua Environment

- Uses World of Warcraft Lua API
- Extensive type annotations with @class and @field
- Global SUI object provides addon framework access

### Code Annotations

Use LuaLS annotations for proper documentation of function parameters and return values:

```lua
---@param paramName type Description of parameter
---@param optionalParam? type Optional parameter (note the ?)
---@return type Description of return value
---@return type|nil secondReturn Optional second return value
function MyFunction(paramName, optionalParam)
    -- function body
end
```

**Key annotation patterns:**

- `---@param name type` - Required parameter
- `---@param name? type` - Optional parameter
- `---@return type` - Return value
- `---@return type|nil` - Optional/nullable return
- `---@class ClassName` - Class definition
- `---@class ClassName : ParentClass` - Class inheritance
- `---@field fieldName type` - Class field
- `---@type type` - Variable type annotation
- `---@overload fun(params): returns` - Function overloads

**Class Extension:**
Classes can be extended by redefining them in different files. This allows adding fields and methods incrementally:

```lua
-- File 1: Initial class definition
---@class MyClass
---@field initialField string

-- File 2: Extend the same class
---@class MyClass
---@field newField number
---@field anotherMethod fun(): boolean
```

Always document function inputs and outputs to improve code maintainability and IDE support.

### Logging and Debugging

- **Use Logger System**: Always use `LibAT.Logger` for debugging and logging instead of `print()` statements
- **Logger Usage**: The logger system provides better control, filtering, and categorization of debug output
- **Avoid Print Statements**: Direct `print()` calls should be avoided in favor of the structured logging system

### Configuration System

- Uses AceConfig for options UI
- Profiles managed through AceDB
- Options structured as nested tables with specific AceConfig format

### Event Handling

- Uses AceEvent for event registration
- Module-based event handling
- Core event handlers in Core/Handlers/Events.lua

### Dependencies

- **Required**: Bartender4 (action bar addon), Libs-AddonTools (UI system and utilities)
- **Optional**: Various other addons for enhanced functionality

### WoW API Documentation Resources

When working with WoW addon development, use these authoritative resources:

- **TOC Format Variables**: https://warcraft.wiki.gg/wiki/TOC_format
  - Reference when modifying .toc files for available variables
- **Latest Interface Versions**: https://warcraft.wiki.gg/wiki/Template:API_LatestInterface
  - Quick lookup for current patch interface version numbers
- **WoW UI Source Code Export**: `C:\Users\jerem\Syncthing\WOWUICode\wow-ui-source`
  - Local copy of raw Blizzard UI source code (current live version)
- **Midnight Alpha/Beta**: `C:\Users\jerem\Syncthing\WOWUICode\wow-ui-source-Beta`
  - Next expansion UI source code
- **API Reference**: https://warcraft.wiki.gg
  - Most up-to-date resource for all WoW API lookups
  - Prefer this over the local code export for API documentation

Always use warcraft.wiki.gg as the primary reference for API lookups and documentation.

### Testing

No automated test framework. Testing done manually in World of Warcraft client using `/rl` to reload changes.

**Important Notes:**

- `luac` command does not work in this environment for syntax checking
- Use VS Code IDE integration for error detection via the Problems tab
- Only focus on actual errors, not formatting issues (formatting is auto-handled on save)
- Lua syntax errors and WoW API issues will be flagged by the language server

## Important Locations

- **Core/Framework.lua:1-100** - Main addon initialization and library setup
- **Core/Handlers/ChatCommands.lua:8-32** - Chat command handling logic
- **Modules/LoadAll.xml** - Module loading order
- **SpartanUI.toc** - Addon metadata and file loading order
