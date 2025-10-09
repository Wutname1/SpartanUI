# ProfileManager - Addon Registration System

The LibAT ProfileManager provides a unified profile import/export system that any addon can integrate with. Addons register their AceDB databases and get automatic UI integration with namespace-aware navigation.

## Features

- ✅ **Unified UI**: All registered addons appear in a single, organized interface
- ✅ **Namespace Support**: Automatic handling of AceDB namespaces with granular import/export
- ✅ **Auto-Generated Navigation**: Each addon gets Import/Export categories with optional namespace subcategories
- ✅ **Programmatic Navigation**: Direct links to specific import/export operations
- ✅ **Safety Features**: Validation, error handling, and namespace blacklisting

## Quick Start

### Basic Registration

```lua
-- Register your addon with the ProfileManager
local myAddonId = LibAT.ProfileManager:RegisterAddon({
    name = "My Addon",
    db = MyAddonDB  -- Your AceDB database object
})
```

### Advanced Registration

```lua
-- Register with namespaces and custom ID
local spartanId = LibAT.ProfileManager:RegisterAddon({
    id = "spartanui",  -- Optional: custom ID (defaults to auto-generated)
    name = "SpartanUI",
    db = SpartanUIDB,
    namespaces = {"PlayerFrame", "TargetFrame", "PartyFrame"},  -- Optional
    icon = "Interface\\AddOns\\SpartanUI\\Images\\Logo"  -- Optional
})
```

## API Reference

### ProfileManager:RegisterAddon(config)

Register an addon to enable profile import/export functionality.

**Parameters:**

- `config` (table) - Configuration table with the following fields:
  - `name` (string, **required**) - Display name shown in the UI
  - `db` (table, **required**) - AceDB database object (must have `.sv` property)
  - `id` (string, optional) - Custom unique identifier (auto-generated if not provided)
  - `namespaces` (table, optional) - Array of namespace names to show as subcategories
  - `icon` (string, optional) - Icon path to display in the navigation tree
  - `metadata` (table, optional) - Additional addon metadata

**Returns:**

- `addonId` (string) - The unique ID assigned to this addon

**Example:**

```lua
local addonId = LibAT.ProfileManager:RegisterAddon({
    name = "MyAddon",
    db = MyAddonDB,
    namespaces = {"Module1", "Module2", "Settings"}
})
```

---

### ProfileManager:UnregisterAddon(addonId)

Remove an addon from the ProfileManager.

**Parameters:**

- `addonId` (string) - The unique ID of the addon to unregister

**Example:**

```lua
LibAT.ProfileManager:UnregisterAddon("myAddon")
```

---

### ProfileManager:ShowExport(addonId, namespace)

Navigate directly to the export view for a specific addon.

**Parameters:**

- `addonId` (string) - The unique ID of the addon
- `namespace` (string, optional) - Specific namespace to export (nil = all namespaces)

**Example:**

```lua
-- Export all data for SpartanUI
LibAT.ProfileManager:ShowExport("spartanui")

-- Export only PlayerFrame namespace
LibAT.ProfileManager:ShowExport("spartanui", "PlayerFrame")
```

---

### ProfileManager:ShowImport(addonId, namespace)

Navigate directly to the import view for a specific addon.

**Parameters:**

- `addonId` (string) - The unique ID of the addon
- `namespace` (string, optional) - Specific namespace to import (nil = all namespaces)

**Example:**

```lua
-- Import all data for MyAddon
LibAT.ProfileManager:ShowImport("myAddon")

-- Import only Settings namespace
LibAT.ProfileManager:ShowImport("myAddon", "Settings")
```

---

### ProfileManager:GetRegisteredAddons()

Get all currently registered addons.

**Returns:**

- `addons` (table) - Table of registered addons keyed by ID

**Example:**

```lua
local addons = LibAT.ProfileManager:GetRegisteredAddons()
for id, addon in pairs(addons) do
    print("Addon:", addon.displayName, "ID:", id)
end
```

## UI Behavior

### Without Namespaces

When an addon is registered without specifying namespaces:

```
MyAddon
├── Import
└── Export
```

Clicking Import/Export directly sets that mode for the entire addon's database.

### With Namespaces

When an addon specifies namespaces:

```
SpartanUI
├── Import
│   ├── All Namespaces
│   ├── PlayerFrame
│   ├── TargetFrame
│   └── PartyFrame
└── Export
    ├── All Namespaces
    ├── PlayerFrame
    ├── TargetFrame
    └── PartyFrame
```

Users can choose to import/export all namespaces at once or work with individual namespaces.

## Integration Examples

### Basic Integration

```lua
-- In your addon's initialization code
local MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceConsole-3.0")
local MyAddonDB

function MyAddon:OnEnable()
    MyAddonDB = LibStub("AceDB-3.0"):New("MyAddonDB")

    -- Register with ProfileManager
    if LibAT and LibAT.ProfileManager then
        LibAT.ProfileManager:RegisterAddon({
            name = "My Addon",
            db = MyAddonDB
        })
    end
end
```

### Advanced Integration with Custom Commands

```lua
local SpartanUI = LibStub("AceAddon-3.0"):GetAddon("SpartanUI")
local spartanId

function SpartanUI:SetupProfileManager()
    if not LibAT or not LibAT.ProfileManager then
        return
    end

    -- Register with namespaces
    spartanId = LibAT.ProfileManager:RegisterAddon({
        id = "spartanui",
        name = "SpartanUI",
        db = SpartanUIDB,
        namespaces = {"PlayerFrame", "TargetFrame", "PartyFrame", "RaidFrames"},
        icon = "Interface\\AddOns\\SpartanUI\\Images\\Logo"
    })

    -- Add custom slash command for quick export
    SLASH_SUIEXPORT1 = "/suiexport"
    SlashCmdList.SUIEXPORT = function(msg)
        if msg == "" then
            LibAT.ProfileManager:ShowExport(spartanId)
        else
            LibAT.ProfileManager:ShowExport(spartanId, msg)
        end
    end

    -- Add custom slash command for quick import
    SLASH_SUIIMPORT1 = "/suiimport"
    SlashCmdList.SUIIMPORT = function(msg)
        if msg == "" then
            LibAT.ProfileManager:ShowImport(spartanId)
        else
            LibAT.ProfileManager:ShowImport(spartanId, msg)
        end
    end
end
```

## Data Format

Export data is serialized as Lua tables with metadata:

```lua
-- SpartanUI Profile Export
-- Generated: 2025-10-05 14:32:15
-- Version: 2.0.0
-- Namespace: PlayerFrame

return {
  ["version"] = "2.0.0",
  ["timestamp"] = "2025-10-05 14:32:15",
  ["addon"] = "SpartanUI",
  ["addonId"] = "spartanui",
  ["namespace"] = "PlayerFrame",
  ["data"] = {
    ["PlayerFrame"] = {
      -- Your namespace data here
    }
  }
}
```

## Best Practices

### 1. Register After Database Initialization

```lua
function MyAddon:OnEnable()
    -- Initialize DB first
    self.db = LibStub("AceDB-3.0"):New("MyAddonDB")

    -- Then register
    LibAT.ProfileManager:RegisterAddon({name = "MyAddon", db = self.db})
end
```

### 2. Use Custom IDs for Stability

```lua
-- Bad: Auto-generated ID might change
local id = LibAT.ProfileManager:RegisterAddon({name = "MyAddon", db = db})

-- Good: Custom ID stays consistent
local id = LibAT.ProfileManager:RegisterAddon({id = "myaddon", name = "MyAddon", db = db})
```

### 3. Check for LibAT Availability

```lua
if LibAT and LibAT.ProfileManager then
    -- Safe to use ProfileManager
else
    -- LibAT not available, skip integration
end
```

### 4. Provide Meaningful Namespace Names

```lua
-- Bad: Generic names
namespaces = {"ns1", "ns2", "data"}

-- Good: Descriptive names
namespaces = {"PlayerFrame", "UI Settings", "Saved Layouts"}
```

### 5. Add User Feedback

```lua
local id = LibAT.ProfileManager:RegisterAddon({name = "MyAddon", db = db})
MyAddon:Print("Profile import/export enabled! Use /profiles to access.")
```

## Troubleshooting

### Addon Not Appearing in UI

1. Verify registration succeeded:

```lua
local addons = LibAT.ProfileManager:GetRegisteredAddons()
if not addons["myaddon"] then
    print("Registration failed!")
end
```

2. Check that `db` is a valid AceDB object:

```lua
if not db or not db.sv then
    print("Invalid AceDB object!")
end
```

### Export/Import Not Working

1. Ensure you've selected an addon in the UI
2. Check for error messages in chat
3. Verify the AceDB structure is correct (has `.sv.namespaces` or `.sv.profiles`)

### Namespace Filtering Issues

1. Make sure namespace names match exactly (case-sensitive)
2. Check that namespaces exist in the database
3. Add to blacklist if needed:

```lua
-- In Profiles.lua
local namespaceblacklist = {'LibDualSpec-1.0', 'MyInternalNamespace'}
```

## Support

For issues or questions:

- Open an issue on GitHub
- Contact the LibAT development team
- Check the full LibAT documentation

## Future Enhancements

Planned features for future versions:

- Profile presets and templates
- Backup/restore functionality
- Profile sharing via encoded strings
- Conflict resolution UI
- Batch import/export operations
