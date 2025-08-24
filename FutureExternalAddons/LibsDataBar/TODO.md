# LibsDataBar Ace3 Refactor Plan

This document outlines the phased refactor plan to convert LibsDataBar from a LibStub library pattern to a proper AceAddon-3.0 addon with full Ace3 integration.

## Current Issues Identified

1. **Text Display Bug**: DataBar text doesn't display - timing issue during initialization
2. **Library vs Addon Pattern**: Currently using `LibStub:NewLibrary()` instead of proper addon structure
3. **Manual Event Handling**: Using CreateFrame() instead of AceEvent-3.0
4. **Basic Configuration**: Missing AceDB profiles and AceConfig automation
5. **No Timer Management**: Lacking efficient update scheduling and throttling

## Phase 1A: Core Framework Conversion ⭐ **CRITICAL**

**Goal**: Convert from library to addon pattern with minimal functional changes

### Tasks:

- [x] **Convert LibsDataBar.lua from library to addon pattern**

  - Replace `LibStub:NewLibrary('LibsDataBar-1.0', 1)` with `LibStub("AceAddon-3.0"):NewAddon("LibsDataBar")`
  - Add AceEvent-3.0, AceTimer-3.0 embeds (minimal for now)
  - Implement OnInitialize(), OnEnable(), OnDisable() callbacks
  - Migrate existing initialization code to proper callbacks

- [ ] **Update plugin loading and initialization order**

  - Ensure plugins load after main addon initialization
  - Fix plugin registration timing to use OnEnable()
  - Preserve existing functionality during migration

- [ ] **Migrate basic event handling to AceEvent-3.0**
  - Replace manual CreateFrame() event registration
  - Use RegisterEvent() and event handler methods
  - Implement proper event cleanup on disable

### Testing Checkpoints:

- [ ] Addon loads without Lua errors
- [ ] All 11 built-in plugins register correctly
- [ ] Basic functionality preserved (even if text display still broken)
- [ ] No performance regressions

**Git Commit**: "Phase 1A: Convert LibsDataBar to AceAddon-3.0 pattern"

---

## Phase 1B: Display Refresh Fix ⭐ **CRITICAL**

**Goal**: Fix text display timing issues using AceTimer-3.0

### Tasks:

- [x] **Implement proper initialization timing with AceTimer-3.0**

  - Schedule initial bar updates after game data is fully loaded
  - Use `ScheduleTimer("UpdateAllBars", 1.0)` in OnEnable()
  - Add delayed initialization for data-dependent plugins

- [x] **Add periodic refresh system**

  - Replace immediate updates with timer-based updates
  - Add periodic refresh timers for all data bars
  - Implement configurable update intervals (default 5 seconds)

- [x] **Implement update throttling**

  - Prevent spam updates during rapid events
  - Add intelligent refresh triggers
  - Optimize update frequency per plugin type

- [x] **Test all plugin text display**
  - Verify each of the 11 plugins displays text correctly
  - Test edge cases (login, reload, zone changes)
  - Ensure data updates properly in real-time

### Testing Checkpoints:

- [x] **All DataBar text displays correctly on login**
- [x] **Plugins update properly with live data**
- [x] No timer conflicts or excessive updates
- [x] Performance impact is minimal (<1ms overhead)

**Git Commit**: "Phase 1B: Fix text display timing with AceTimer-3.0"

---

## Phase 2: Configuration System Enhancement

**Goal**: Implement robust configuration with profiles and automatic UI

### Tasks:

- [ ] **Integrate AceDB-3.0 for saved variables**

  - Replace manual SavedVariables with AceDB database
  - Implement profile system (per-character, realm, global)
  - Add automatic defaults merging
  - Setup database callbacks for live config updates

- [ ] **Enhance AceConfig-3.0 integration**

  - Convert manual option tables to proper AceConfig format
  - Add automatic Settings panel integration
  - Implement hierarchical plugin configuration
  - Add configuration validation and error handling

- [ ] **Add AceDBOptions-3.0 for profile management**
  - Automatic profile switching UI
  - Copy/delete/reset profile functionality
  - Integration with main configuration panels

### Testing Checkpoints:

- [ ] Configuration persists across sessions
- [ ] Profile switching works correctly
- [ ] Plugin settings are properly categorized
- [ ] Settings panel integration is seamless

**Git Commit**: "Phase 2: Implement AceDB profiles and enhanced configuration"

---

## Phase 3: Performance and User Experience

**Goal**: Optimize performance and enhance user experience

### Tasks:

- [ ] **Implement AceBucket-3.0 for event throttling**

  - Replace rapid-fire event handling with buckets
  - Throttle bag updates, currency changes, etc.
  - Batch UI updates for better performance
  - Add configurable update intervals

- [ ] **Add AceConsole-3.0 for command system**

  - Replace basic slash commands with AceConsole
  - Add help text generation
  - Implement command-line configuration options
  - Add developer debug commands

- [ ] **Integrate LibQTip-1.0 for enhanced tooltips**
  - Replace basic GameTooltip with multi-column tooltips
  - Add rich formatting for plugin data
  - Implement interactive tooltip elements
  - Add tabular data display for complex plugins

### Testing Checkpoints:

- [ ] Event throttling improves performance
- [ ] Commands work correctly with help text
- [ ] Tooltips display rich data properly
- [ ] Memory usage remains optimized

**Git Commit**: "Phase 3: Performance optimization and UX enhancements"

---

## Phase 4: Advanced Integration

**Goal**: Modern positioning and theme integration

### Tasks:

- [ ] **Integrate LibEditMode for modern positioning**

  - Register bars/containers in Edit Mode
  - Add snap-to-grid and alignment helpers
  - Implement intuitive drag-and-drop positioning
  - Ensure persistent position saving

- [ ] **Enhance LibSharedMedia-3.0 integration**

  - Expand theme system with shared media
  - Add user-configurable fonts and textures
  - Integrate with SpartanUI theme system
  - Support community texture packs

- [ ] **Add advanced communication features**
  - Implement AceComm-3.0 for guild configuration sharing
  - Add AceSerializer-3.0 for export/import
  - Create configuration sync features
  - Enable community preset sharing

### Testing Checkpoints:

- [ ] Edit Mode integration works seamlessly
- [ ] Shared media selection works correctly
- [ ] Configuration sharing functions properly
- [ ] Theme synchronization with SpartanUI

**Git Commit**: "Phase 4: Advanced positioning and theme integration"

---

## Phase 5: Developer Experience and Polish

**Goal**: Enhanced developer tools and final polish

### Tasks:

- [ ] **Enhance developer tools with Ace3**

  - Integrate AceGUI-3.0 for plugin wizard UI
  - Add advanced configuration panel creation
  - Implement live plugin validation with feedback
  - Create comprehensive developer documentation

- [ ] **Add optional advanced features**

  - Implement AceLocale-3.0 for internationalization
  - Add AceHook-3.0 for Blizzard UI integration
  - Consider LibDualSpec-1.0 for spec-specific configs
  - Add HereBeDragons-2.0 for advanced location features

- [ ] **Final optimization and cleanup**
  - Remove deprecated code patterns
  - Optimize memory usage and performance
  - Add comprehensive error handling
  - Complete testing across all features

### Testing Checkpoints:

- [ ] All developer tools function correctly
- [ ] No deprecated patterns remain
- [ ] Performance meets target goals
- [ ] Feature completeness verified

**Git Commit**: "Phase 5: Developer tools enhancement and final polish"

---

## Critical Path Dependencies

**Phase 1A MUST be completed first** - establishes the addon foundation safely.

**Phase 1B immediately follows 1A** - fixes the critical text display bug.

**Phase 1A + 1B together** establish the foundation for all other phases.

**Phase 2** can begin immediately after Phase 1 - configuration system is independent.

**Phases 3-5** can be done in parallel after Phase 2, depending on priority and available development time.

## Risk Mitigation

1. **Each phase includes testing checkpoints** to ensure stability
2. **Git commits at each phase** provide rollback points
3. **Preserve LibDataBroker compatibility** throughout refactor
4. **Maintain all existing plugin functionality** during migration
5. **Performance monitoring** to ensure no regressions

## Success Metrics

- **Text Display**: 100% reliable on all load conditions
- **Performance**: <2ms update cycles, <50MB memory usage
- **Compatibility**: All existing plugins continue to work
- **User Experience**: Seamless migration for existing users
- **Developer Experience**: Enhanced tools and documentation
- **Code Quality**: Modern patterns, comprehensive error handling

This phased approach ensures the critical text display bug is fixed immediately while providing a structured path to full Ace3 integration and enhanced functionality.
