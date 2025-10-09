# Libs-AddonTools Logger - External Addon Integration Guide

## Overview

The Libs-AddonTools Logger provides a comprehensive logging system for World of Warcraft addons. External addons can easily integrate with Libs-AddonTools's logging system through a simple registration API that handles categorization, UI integration, and log management automatically.

## Core Features

- **5-Level Logging System**: Debug, Info, Warning, Error, Critical
- **Three-Level Hierarchy**: Category → SubCategory → SubSubCategory organization
- **Dynamic Categorization**: Automatic UI organization based on addon registration
- **Real-Time Filtering**: Dynamic log level changes without data loss
- **Professional UI**: AuctionHouse-styled interface with authentic Blizzard styling
- **Performance Optimized**: Minimal runtime overhead with efficient filtering
- **Cross-Source Search**: Search across all registered addons simultaneously
- **Hierarchical Organization**: Support for granular log source organization

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

---@class LibAT.Logger
---@field RegisterAddon fun(addonName: string): SimpleLogger
---@field RegisterAddonCategory fun(addonName: string, subcategories: string[]): ComplexLoggers
```

## Registration API

### Simple Addon Registration

For addons that need basic logging functionality, use the simple registration method:

#### `LibAT.Logger.RegisterAddon(addonName)`

Registers your addon for logging under the "External Addons" category.

**Type Signature:**

```lua
---@param addonName string Name of your addon
---@return SimpleLogger logger Logger function that accepts (message, level?)
function LibAT.Logger.RegisterAddon(addonName)
```

**Parameters:**

- `addonName` (string): Name of your addon

**Returns:**

- `SimpleLogger`: Logger function that accepts `(message: string, level?: LogLevel)`

**Example:**

```lua
-- Registration (do this once during addon initialization)
local logger = LibAT.Logger:RegisterAddon("LibsTotemBar")

-- Usage throughout your addon
logger("Totem bar initialized")
logger("Totem spell detected", "info")
logger("Failed to create totem button", "error")
```

### Advanced Addon Registration

For complex addons that need multiple logging categories, use the advanced registration method:

#### `LibAT.Logger.RegisterAddonCategory(addonName, subcategories)`

Creates a custom expandable category for your addon with subcategories.

**Type Signature:**

```lua
---@param addonName string Name of your addon (becomes the category name)
---@param subcategories string[] Array of subcategory names
---@return ComplexLoggers loggers Table of logger functions keyed by subcategory name
function LibAT.Logger.RegisterAddonCategory(addonName, subcategories)
```

**Parameters:**

- `addonName` (string): Name of your addon (becomes the category name)
- `subcategories` (string[]): Array of subcategory names

**Returns:**

- `ComplexLoggers`: Table of logger functions keyed by subcategory name

**Example:**

```lua
-- Registration (do this once during addon initialization)
local loggers = LibAT.Logger.RegisterAddonCategory("LibsDataBar", {
    "core", "modules", "display", "plugins"
})

-- Usage throughout your addon
loggers.core("DataBar system initialized")
loggers.modules("Loading module: " .. moduleName)
loggers.display("Updating display layout")
loggers.plugins("Plugin registered: " .. pluginName, "debug")
```

## Hierarchical Logging Patterns

### Automatic SubSubCategory Detection

The Logger automatically detects and creates hierarchical structures based on your log source naming:

```lua
-- Two-level pattern: "AddonName.SubCategory"
LibAT.Log("Combat module loaded", "MyAddon.Combat")
-- → Category: "MyAddon", SubCategory: "Combat" (selectable)

-- Three-level pattern: "AddonName.SubCategory.SubSubCategory"
LibAT.Log("Spell rotation started", "MyAddon.Combat.Rotation")
LibAT.Log("Cooldown tracked", "MyAddon.Combat.Cooldowns")
-- → Category: "MyAddon", SubCategory: "Combat" (expandable)
--   ├─ SubSubCategory: "Rotation" (selectable)
--   └─ SubSubCategory: "Cooldowns" (selectable)
```

### Advanced Hierarchical Usage

For complex addons, you can combine registration with hierarchical source names:

```lua
-- Register your main category
local loggers = LibAT.Logger.RegisterAddonCategory("MyRaidAddon", {
    "core", "ui", "data"
})

-- Use basic subcategories
loggers.core("Addon initialized")
loggers.ui("Interface loaded")

-- Use hierarchical patterns for granular logging
LibAT.Log("Player data updated", "MyRaidAddon.data.player")
LibAT.Log("Guild data synced", "MyRaidAddon.data.guild")
LibAT.Log("Raid roster changed", "MyRaidAddon.data.roster")
-- Creates: "MyRaidAddon" → "data" → "player/guild/roster"

-- Mix registration and direct logging
LibAT.Log("Button created", "MyRaidAddon.ui.buttons")
LibAT.Log("Panel updated", "MyRaidAddon.ui.panels")
-- Creates: "MyRaidAddon" → "ui" → "buttons/panels"
```

### Best Practices for Hierarchy

- **Use consistent naming**: Stick to a pattern like "AddonName.System.Component"
- **Group related functionality**: Put similar features under the same SubCategory
- **Avoid deep nesting**: Three levels provide excellent organization without complexity
- **Be descriptive**: Use clear names that indicate the log source purpose

### Automatic Hierarchy Creation

The internal API automatically creates proper categorization:

```lua
-- With DisplayName = "Auto turn in"
self.logger("Quest completed")
-- → Category: "UI Components", SubCategory: "Auto turn in"

-- With components
self.loggers.database("Player data saved")
-- → Category: "UI Components", SubCategory: "Auto turn in.database"

-- With sub-components
LibAT.ModuleLog(self, "Connection timeout", "database.connection", "warning")
-- → Category: "UI Components"
--   SubCategory: "Auto turn in.database" (expandable)
--   SubSubCategory: "connection" (selectable)
```

### Migration from Direct LibAT.Log Calls

**Old Pattern:**

```lua
LibAT.Log("Player health updated", "UnitFrames.Player.Health", "debug")
LibAT.Log("Action bar button created", "ActionBars", "info")
```

**New Recommended Pattern:**

```lua
-- In module initialization
self.loggers = LibAT.SetupModuleLogging(self, {"player", "target", "party"})

-- In usage
self.loggers.player("Health updated", "health", "debug")
-- Creates: "Unit Frames.player.health" hierarchy

self.loggers.general("Action bar button created", "info")
-- Creates: "Unit Frames" simple entry
```

## User Interface Access

### Chat Commands

- `/logs` - Opens/closes the Logger window

## Log Levels

The Logger uses a 5-tier priority system with color coding:

| Level    | Priority | Color   | Description                    |
| -------- | -------- | ------- | ------------------------------ |
| debug    | 1        | Gray    | Detailed debugging information |
| info     | 2        | Green   | General informational messages |
| warning  | 3        | Yellow  | Warning conditions             |
| error    | 4        | Red     | Error conditions               |
| critical | 5        | Magenta | Critical system failures       |

## Three-Level Hierarchy System

The Logger uses a sophisticated three-level hierarchy system that matches Blizzard's AuctionHouse organization:

### Level 1: Categories

Top-level organizational groups:

- **External Addons**: Simple registered addons (using `RegisterAddon()`)
- **Custom Categories**: Complex registered addons (using `RegisterAddonCategory()`)
- **Libs-AddonTools Internal**: Core, UI Components, Handlers, Development

### Level 2: SubCategories

Secondary organization within categories:

- **For External Addons**: Individual addon names (e.g., "MyAddon")
- **For Custom Categories**: User-defined subcategories (e.g., "Combat", "Interface")
- **For Libs-AddonTools Internal**: System components (e.g., "UnitFrames", "Database")

### Level 3: SubSubCategories

Granular log source organization:

- **Automatic Detection**: Sources like "MyAddon.Combat.Spells" automatically create hierarchy
- **Expandable Groups**: SubCategories with multiple SubSubCategories become expandable
- **Direct Logging**: Individual log sources are selectable for focused viewing

### Hierarchy Examples

```
📁 MyAddon (5)                    ← Category (your custom category)
├── 📂 Combat (3)                 ← SubCategory (expandable)
│   ├── 📄 Spells                 ← SubSubCategory (selectable log source)
│   ├── 📄 Rotation               ← SubSubCategory (selectable log source)
│   └── 📄 Cooldowns              ← SubSubCategory (selectable log source)
├── 📂 Interface                  ← SubCategory (selectable log source)
└── 📂 Database                   ← SubCategory (selectable log source)

📁 External Addons (8)            ← Category (simple registrations)
├── 📂 LibDataBroker              ← SubCategory (selectable log source)
├── 📂 WeakAuras                  ← SubCategory (selectable log source)
└── 📂 Details                    ← SubCategory (selectable log source)
```

## Logger UI Components

### Main Window

- **Size**: 800x538 pixels (matches AuctionHouse dimensions)
- **Layout**: Two-panel design with module tree (left) and log display (right)
- **Styling**: Uses AuctionHouse UI elements for consistent look

### Control Bar

- **Search All Sources**: Checkbox to enable cross-source searching
- **Search Box**: Real-time text filtering with highlighting
- **Log Level Dropdown**: Dynamic filtering by minimum log level
- **Settings Button**: Direct access to configuration options

### Hierarchy Tree (Left Panel)

- **Three-Level Organization**: Category → SubCategory → SubSubCategory
- **Expandable Structure**: Click to expand/collapse any level
- **Selection System**: Select individual log sources for focused viewing
- **Count Display**: Shows total items per category
- **Visual Indicators**: Expand/collapse icons match AuctionHouse style

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
local logger = LibAT.Logger.RegisterAddon(addonName) ---@type SimpleLogger

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
local loggers = LibAT.Logger.RegisterAddonCategory(addonName, {
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

Registered addons automatically appear in the Libs-AddonTools Logger configuration panel where users can:

- **Enable/Disable Logging**: Toggle logging for individual registered addons
- **Set Log Levels**: Control minimum log level per addon
- **Global Settings**: Configure overall logger behavior and history limits

All configuration is handled automatically through the Libs-AddonTools options system - no additional setup required from addon developers.

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

1. Check Libs-AddonTools documentation and options panel
2. Use `/logs` command to view your addon's logging output
3. Export logs when reporting issues to Libs-AddonTools developers

---

**Libs-AddonTools Logger External Addon Integration Guide**
_For addon developers integrating with Libs-AddonTools's logging system_
