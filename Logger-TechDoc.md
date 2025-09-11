# SpartanUI Logger - External Addon Integration Guide

## Overview

The SpartanUI Logger provides a comprehensive logging system for World of Warcraft addons. External addons can easily integrate with SpartanUI's logging system through a simple registration API that handles categorization, UI integration, and log management automatically.

## Core Features

- **5-Level Logging System**: Debug, Info, Warning, Error, Critical
- **Dynamic Categorization**: Automatic UI organization based on addon registration
- **Real-Time Filtering**: Dynamic log level changes without data loss
- **Professional UI**: AuctionHouse-styled interface with search and export capabilities
- **Performance Optimized**: Minimal runtime overhead with efficient filtering
- **Cross-Module Search**: Search across all registered addons simultaneously

## Type Definitions (Emmy Lua)

For optimal IntelliSense support, include these type definitions in your addon:

```lua
---@alias LogLevel
---| "debug"    # Detailed debugging information
---| "info"     # General informational messages  
---| "warning"  # Warning conditions
---| "error"    # Error conditions
---| "critical" # Critical system failures

---Logger function returned by RegisterAddon
---@alias SimpleLogger fun(message: string, level?: LogLevel): nil

---Logger table returned by RegisterAddonCategory  
---@alias ComplexLoggers table<string, SimpleLogger>

---@class SUI.Logger
---@field RegisterAddon fun(addonName: string): SimpleLogger
---@field RegisterAddonCategory fun(addonName: string, subcategories: string[]): ComplexLoggers
```

## Registration API

### Simple Addon Registration

For addons that need basic logging functionality, use the simple registration method:

#### `SUI.Logger.RegisterAddon(addonName)`

Registers your addon for logging under the "External Addons" category.

**Type Signature:**
```lua
---@param addonName string Name of your addon
---@return SimpleLogger logger Logger function that accepts (message, level?)
function SUI.Logger.RegisterAddon(addonName)
```

**Parameters:**
- `addonName` (string): Name of your addon

**Returns:**
- `SimpleLogger`: Logger function that accepts `(message: string, level?: LogLevel)`

**Example:**

```lua
-- Registration (do this once during addon initialization)
local logger = SUI.Logger:RegisterAddon("LibsTotemBar")

-- Usage throughout your addon
logger("Totem bar initialized")
logger("Totem spell detected", "info")
logger("Failed to create totem button", "error")
```

### Advanced Addon Registration

For complex addons that need multiple logging categories, use the advanced registration method:

#### `SUI.Logger.RegisterAddonCategory(addonName, subcategories)`

Creates a custom expandable category for your addon with subcategories.

**Type Signature:**
```lua
---@param addonName string Name of your addon (becomes the category name)
---@param subcategories string[] Array of subcategory names  
---@return ComplexLoggers loggers Table of logger functions keyed by subcategory name
function SUI.Logger.RegisterAddonCategory(addonName, subcategories)
```

**Parameters:**
- `addonName` (string): Name of your addon (becomes the category name)
- `subcategories` (string[]): Array of subcategory names

**Returns:**
- `ComplexLoggers`: Table of logger functions keyed by subcategory name

**Example:**

```lua
-- Registration (do this once during addon initialization)
local loggers = SUI.Logger:RegisterAddonCategory("LibsDataBar", {
    "core", "modules", "display", "plugins"
})

-- Usage throughout your addon
loggers.core("DataBar system initialized")
loggers.modules("Loading module: " .. moduleName)
loggers.display("Updating display layout")
loggers.plugins("Plugin registered: " .. pluginName, "debug")
```

## User Interface Access

### Chat Commands

- `/logs` - Opens/closes the Logger window
- `/debug` - Alternative command for the same action

### Options Integration

Access logger configuration through SpartanUI options panel at `/sui > Help > Logging` or click the "Logging" button in the SpartanUI options window.

## Log Levels

The Logger uses a 5-tier priority system with color coding:

| Level    | Priority | Color   | Description                    |
| -------- | -------- | ------- | ------------------------------ |
| debug    | 1        | Gray    | Detailed debugging information |
| info     | 2        | Green   | General informational messages |
| warning  | 3        | Yellow  | Warning conditions             |
| error    | 4        | Red     | Error conditions               |
| critical | 5        | Magenta | Critical system failures       |

## Addon Categories

Registered addons are organized in the Logger UI as follows:

- **External Addons**: Simple registered addons (using `RegisterAddon()`)
- **Custom Categories**: Complex registered addons (using `RegisterAddonCategory()`) appear as their own expandable categories
- **SpartanUI Internal**: Core SpartanUI modules and handlers

## Logger UI Components

### Main Window

- **Size**: 800x538 pixels (matches AuctionHouse dimensions)
- **Layout**: Two-panel design with module tree (left) and log display (right)
- **Styling**: Uses AuctionHouse UI elements for consistent look

### Control Bar

- **Search All Modules**: Checkbox to enable cross-module searching
- **Search Box**: Real-time text filtering with highlighting
- **Log Level Dropdown**: Dynamic filtering by minimum log level
- **Settings Button**: Direct access to configuration options

### Module Tree (Left Panel)

- **Expandable Categories**: Organized by module type
- **Selection System**: Single module selection for focused viewing
- **Count Display**: Shows number of modules per category

### Log Display (Right Panel)

- **Formatted Output**: Timestamp, level, and message display
- **Search Highlighting**: Magenta highlighting of search terms
- **Auto-scroll**: Optional automatic scrolling to new entries
- **Copy Support**: Full text selection for external copying

### Action Buttons

- **Clear**: Remove logs for current module or all modules
- **Export**: Generate copyable log export with metadata

## Integration Examples

### Simple Addon Integration (LibsTotemBar style)

```lua
-- In your addon's initialization code
local addonName = "LibsTotemBar"
local logger = SUI.Logger.RegisterAddon(addonName) ---@type SimpleLogger

-- Throughout your addon code
function TotemBar:Initialize()
    logger("Totem bar system starting up")
    
    local success = self:LoadConfiguration()
    if success then
        logger("Configuration loaded successfully", "info")
    else
        logger("Failed to load configuration", "error")
    end
end

function TotemBar:CreateTotemButton(spellID)
    logger("Creating totem button for spell: " .. spellID, "debug")
    
    local spellInfo = GetSpellInfo(spellID)
    if not spellInfo then
        logger("Spell data not available for ID: " .. spellID, "warning")
        return false
    end
    
    logger("Totem button created: " .. spellInfo.name, "info")
    return true
end
```

### Complex Addon Integration (LibsDataBar style)

```lua
-- In your addon's initialization code
local addonName = "LibsDataBar"
local loggers = SUI.Logger.RegisterAddonCategory(addonName, {
    "core", "modules", "display", "plugins"
}) ---@type ComplexLoggers

-- Core system logging
function DataBar:Initialize()
    loggers.core("DataBar system initializing")
    self:LoadModules()
    loggers.core("DataBar system ready")
end

-- Module management logging  
function DataBar:LoadModule(moduleName)
    loggers.modules("Loading module: " .. moduleName, "debug")
    
    local success, module = pcall(self.LoadModuleFile, moduleName)
    if success then
        loggers.modules("Module loaded: " .. moduleName, "info")
        return module
    else
        loggers.modules("Failed to load module: " .. moduleName .. " - " .. tostring(module), "error")
        return nil
    end
end

-- Display system logging
function DataBar:UpdateDisplay()
    loggers.display("Updating display layout", "debug")
    -- Display update logic
    loggers.display("Display update completed")
end

-- Plugin system logging
function DataBar:RegisterPlugin(plugin)
    loggers.plugins("Registering plugin: " .. plugin.name)
    -- Plugin registration logic
    loggers.plugins("Plugin registered successfully: " .. plugin.name, "info")
end
```

## Configuration

Registered addons automatically appear in the SpartanUI Logger configuration panel where users can:

- **Enable/Disable Logging**: Toggle logging for individual registered addons
- **Set Log Levels**: Control minimum log level per addon
- **Global Settings**: Configure overall logger behavior and history limits

All configuration is handled automatically through the SpartanUI options system - no additional setup required from addon developers.

## Performance Notes

The Logger system is designed for minimal performance impact:

- **Lightweight Logging**: Function calls have negligible runtime overhead
- **Efficient Storage**: Automatic cleanup and memory management
- **Smart UI Updates**: Display updates only when Logger window is visible

## Best Practices

### Registration Timing

- Register your addon during initialization, typically in `ADDON_LOADED` or equivalent event
- Store the returned logger function(s) for use throughout your addon's lifetime

### Message Guidelines

- **Use appropriate log levels**: Debug for development info, Info for user actions, Warning/Error/Critical for issues
- **Include context**: Add relevant identifiers, values, or state information
- **Be descriptive**: Write messages that will be helpful when debugging issues later

### Performance Considerations

- Logger functions are lightweight - don't worry about frequent calls during normal operation
- Avoid logging in extremely high-frequency loops (hundreds of calls per second)
- The Logger handles message formatting and storage efficiently

## Support

For Logger integration questions or issues:

1. Check SpartanUI documentation and options panel
2. Use `/logs` command to view your addon's logging output  
3. Export logs when reporting issues to SpartanUI developers

---

**SpartanUI Logger External Addon Integration Guide**  
*For addon developers integrating with SpartanUI's logging system*
