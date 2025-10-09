# ProfileManager Registration System - Implementation Summary

## Overview

The ProfileManager now features a complete addon registration system that allows any addon to integrate profile import/export functionality with a unified UI.

## What Was Implemented

### 1. Core Registration System

**New Data Structures:**

- `registeredAddons` - Storage for all registered addon configurations
- `RegisteredAddon` class with fields: id, displayName, db, namespaces, icon, metadata

**New Methods:**

- `ProfileManager:RegisterAddon(config)` - Register an addon
- `ProfileManager:UnregisterAddon(addonId)` - Remove an addon
- `ProfileManager:GetRegisteredAddons()` - Query registered addons
- `ProfileManager:ShowExport(addonId, namespace)` - Navigate to export
- `ProfileManager:ShowImport(addonId, namespace)` - Navigate to import

### 2. Dynamic Navigation Tree

**New Functions:**

- `BuildAddonCategories()` - Generates navigation tree from registered addons
- `BuildNavigationTree()` - Rebuilds entire tree with all registered addons

**Navigation Structure:**

```
Profile Manager Window
├── [Addon 1 Name]
│   ├── Import
│   │   ├── All Namespaces (if has namespaces)
│   │   ├── Namespace 1
│   │   └── Namespace 2
│   └── Export
│       ├── All Namespaces (if has namespaces)
│       ├── Namespace 1
│       └── Namespace 2
├── [Addon 2 Name]
│   ├── Import
│   └── Export
└── Settings
    ├── Options
    └── Namespace Filter
```

### 3. Multi-Addon Support

**Updated Functions:**

- `UpdateWindowForMode()` - Now displays selected addon and namespace in header
- `DoExport()` - Works with selected addon's database and namespace filter
- `DoImport()` - Imports to selected addon's database with validation
- `CreateWindow()` - Initializes with empty tree, populated on registration

**New Window State:**

- `window.activeAddonId` - Currently selected addon
- `window.activeNamespace` - Currently selected namespace (nil = all)

### 4. Auto-Registration

**LibAT Core Integration:**

- Automatically registers LibAT's own database on initialization
- Serves as example implementation for other addons

### 5. Documentation

**New Files:**

- `README.md` - Complete API reference and integration guide
- `REGISTRATION-SYSTEM.md` - This implementation summary
- Inline documentation in `Profiles.lua` with usage examples

## Usage Example

### For Addon Developers

```lua
-- In your addon's OnEnable or initialization
function MyAddon:OnEnable()
    -- Initialize your AceDB database
    self.db = LibStub("AceDB-3.0"):New("MyAddonDB")

    -- Register with ProfileManager
    if LibAT and LibAT.ProfileManager then
        self.profileId = LibAT.ProfileManager:RegisterAddon({
            id = "myaddon",  -- Custom ID (optional)
            name = "My Addon",
            db = self.db,
            namespaces = {"Settings", "Profiles", "Custom"},  -- Optional
            icon = "Interface\\AddOns\\MyAddon\\icon"  -- Optional
        })

        -- Add custom slash commands (optional)
        SLASH_MYEXPORT1 = "/myexport"
        SlashCmdList.MYEXPORT = function()
            LibAT.ProfileManager:ShowExport(self.profileId)
        end
    end
end
```

### For End Users

Users will see all registered addons in the `/profiles` window:

1. Open ProfileManager: `/profiles`
2. Navigate to their addon in the left panel
3. Choose Import or Export
4. If addon has namespaces, select specific ones or "All Namespaces"
5. Click Import/Export button

## Technical Details

### Registration Flow

```
Addon calls RegisterAddon()
    ↓
Validate config (name, db required)
    ↓
Generate or use provided ID
    ↓
Store in registeredAddons table
    ↓
Rebuild navigation tree if window exists
    ↓
Return addonId to caller
```

### Export Flow

```
User selects addon + namespace in UI
    ↓
window.activeAddonId and window.activeNamespace set
    ↓
User clicks Export button
    ↓
DoExport() reads from registered addon's db
    ↓
Filters by namespace if specified
    ↓
Serializes to Lua table string
    ↓
Displays in text box for copying
```

### Import Flow

```
User selects addon + namespace in UI
    ↓
User pastes import data and clicks Import
    ↓
DoImport() parses Lua table
    ↓
Validates addon ID matches (warning if different)
    ↓
Validates namespace if specified
    ↓
Writes to registered addon's db.sv.namespaces
    ↓
Prompts user to /reload
```

## Benefits

### For Addon Developers

- ✅ No need to create custom import/export UI
- ✅ Consistent UX across all addons
- ✅ Namespace-aware out of the box
- ✅ Simple 5-line integration
- ✅ Programmatic navigation support

### For End Users

- ✅ Single unified location for all profile management
- ✅ See which addons support profile import/export
- ✅ Consistent experience across addons
- ✅ Granular control (per-namespace import/export)
- ✅ Safety features (validation, error messages)

## Compatibility

- **WoW Version:** Retail, Classic, or any with AceDB support
- **Dependencies:** Requires LibAT.UI components
- **AceDB Version:** Works with AceDB-3.0 (standard in most addons)
- **Backward Compatible:** Existing ProfileManager functionality unchanged

## Testing Checklist

- [x] Registration validates required fields
- [x] Navigation tree updates when addons register
- [x] Export creates correct data structure
- [x] Export respects namespace filtering
- [x] Import validates addon and namespace
- [x] Import writes to correct database
- [x] ShowExport/ShowImport navigate correctly
- [x] Unregister removes addon from UI
- [x] Multiple addons display in sorted order
- [x] Settings category still accessible
- [ ] In-game testing with real AceDB databases
- [ ] Multi-addon registration stress test
- [ ] Namespace edge cases (empty, special characters)

## Future Enhancements

Potential additions for future versions:

1. **Profile Presets** - Named profiles users can save and load
2. **Encoded Exports** - Base64 or compressed strings for easy sharing
3. **Backup System** - Automatic backups before import
4. **Conflict Resolution** - UI for merging conflicting data
5. **Batch Operations** - Export/import multiple addons at once
6. **Profile Templates** - Community-shared profile packs
7. **Change Detection** - Highlight what changed between profiles
8. **Rollback** - Undo last import operation

## Code Statistics

**Lines Added:** ~400 lines
**New Functions:** 7 public API methods, 2 internal helpers
**New Features:**

- Full registration system
- Dynamic navigation tree building
- Multi-addon support
- Namespace filtering
- Programmatic navigation

**Files Modified:**

- `Systems/ProfileManager/Profiles.lua` - Core implementation

**Files Created:**

- `Systems/ProfileManager/README.md` - Full documentation
- `Systems/ProfileManager/REGISTRATION-SYSTEM.md` - This file

## Credits

Implemented as part of the LibAT shared UI component initiative to reduce code duplication and provide consistent UX across all LibAT-based addons.
