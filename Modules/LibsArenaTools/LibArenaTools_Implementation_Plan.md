# LibArenaTools Implementation Plan

## Executive Summary

This document provides detailed implementation steps for LibArenaTools, the next-generation arena frames addon for SpartanUI. The plan is organized into three phases with specific TODO items, file structures, and integration points.

**Development Timeline:** 6 months (3 phases × 2 months each)
**Target:** Replace SpartanUI arena frames and surpass GladiusEX functionality

---

## Phase 1: Foundation (Months 1-2)

### Month 1: Core Framework and oUF Integration

#### Week 1: Project Setup and Core Structure

**TODO: Set up basic module structure**
- [ ] Create main module file: `LibArenaTools.lua`
- [ ] Set up SpartanUI module registration pattern
- [ ] Create basic configuration defaults
- [ ] Implement module lifecycle methods (OnInitialize, OnEnable, OnDisable)
- [ ] Add module to SpartanUI LoadAll.xml

**TODO: Create Core directory and files**
- [ ] Create `Core/ArenaManager.lua` - Main arena state management
- [ ] Create `Core/ElementRegistry.lua` - oUF element registration system
- [ ] Create `Core/ConfigManager.lua` - Configuration handling
- [ ] Create `Core/EventHandler.lua` - Event management system
- [ ] Create `Core/Utils.lua` - Utility functions

**LibArenaTools.lua Implementation:**
```lua
---@class SUI.LibArenaTools : SUI.Module
local LibArenaTools = SUI:NewModule('LibArenaTools')
LibArenaTools.DisplayName = 'Arena Tools'
LibArenaTools.description = 'Advanced arena frames and tools'

LibArenaTools.Config = {
    IsGroup = false,
    Core = false,
    RequiredModules = {'UnitFrames'},
    OptionalModules = {'Artwork'}
}

function LibArenaTools:OnInitialize()
    -- Initialize core components
    self.ArenaManager = self:CreateArenaManager()
    self.ElementRegistry = self:CreateElementRegistry()
    self.ConfigManager = self:CreateConfigManager()
    
    -- Register with UnitFrames system
    SUI.UF:RegisterArenaProvider(self)
end
```

#### Week 2: Basic oUF Integration

**TODO: Create oUF arena unit system**
- [ ] Create `Units/arena.lua` - Arena enemy frames (arena1-5)
- [ ] Create `Units/arenapet.lua` - Arena pet frames (arenapet1-5)
- [ ] Implement basic oUF unit spawning
- [ ] Add arena unit positioning system
- [ ] Create arena unit builder functions

**TODO: Implement ArenaManager core**
- [ ] Arena state detection (in arena, prep phase, active match)
- [ ] Arena unit tracking and management
- [ ] Basic event handling (ARENA_PREP_OPPONENT_SPECIALIZATIONS, etc.)
- [ ] Arena match lifecycle management

**Core/ArenaManager.lua Implementation:**
```lua
---@class LibArenaTools.ArenaManager
local ArenaManager = {}

function ArenaManager:Initialize()
    self.arenaUnits = {}
    self.arenaState = 'none' -- 'none', 'prep', 'active'
    self.opponents = {}
    
    self:RegisterEvents()
end

function ArenaManager:RegisterEvents()
    self:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS', 'OnArenaPrep')
    self:RegisterEvent('ARENA_OPPONENT_UPDATE', 'OnOpponentUpdate')
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnEnteringWorld')
end

function ArenaManager:OnArenaPrep()
    self.arenaState = 'prep'
    self:UpdateArenaUnits()
    self:ShowArenaFrames()
end
```

#### Week 3: Basic Element Framework

**TODO: Create element registration system**
- [ ] Implement element registration interface
- [ ] Create element lifecycle management
- [ ] Add element configuration binding
- [ ] Create element update batching system

**TODO: Create first arena element (Health/Power)**
- [ ] Create `Elements/ArenaHealth.lua` - Basic health display
- [ ] Create `Elements/ArenaPower.lua` - Basic power display
- [ ] Create `Elements/ArenaName.lua` - Name and spec display
- [ ] Implement basic oUF element pattern
- [ ] Register elements with oUF system

**Core/ElementRegistry.lua Implementation:**
```lua
---@class LibArenaTools.ElementRegistry
local ElementRegistry = {
    registeredElements = {},
    enabledElements = {}
}

function ElementRegistry:RegisterElement(name, elementTable)
    self.registeredElements[name] = elementTable
    
    -- Register with oUF
    oUF:AddElement(name, elementTable.Update, elementTable.Enable, elementTable.Disable)
    
    -- Add to configuration
    LibArenaTools.ConfigManager:AddElementConfig(name, elementTable.defaults)
end

function ElementRegistry:EnableElement(frameName, elementName)
    local frame = LibArenaTools.ArenaManager:GetArenaUnit(frameName)
    if frame and frame[elementName] then
        frame:EnableElement(elementName)
    end
end
```

#### Week 4: Basic Configuration System

**TODO: Implement configuration management**
- [ ] Create configuration defaults structure
- [ ] Implement AceDB integration
- [ ] Create basic options interface
- [ ] Add profile management
- [ ] Implement configuration validation

**TODO: Create Options.lua**
- [ ] Basic enable/disable toggles
- [ ] Position configuration options
- [ ] Element enable/disable options
- [ ] Integration with SpartanUI options system

**Core/ConfigManager.lua Implementation:**
```lua
---@class LibArenaTools.ConfigManager
local ConfigManager = {}

local defaults = {
    profile = {
        enabled = true,
        elements = {
            ArenaHealth = {enabled = true},
            ArenaPower = {enabled = true},
            ArenaName = {enabled = true}
        },
        positioning = {
            anchor = 'RIGHT',
            anchorFrame = 'UIParent',
            offsetX = -50,
            offsetY = 0
        }
    }
}

function ConfigManager:Initialize()
    self.db = LibStub('AceDB-3.0'):New('LibArenaToolsDB', defaults, true)
end
```

### Month 2: Essential Arena Elements

#### Week 5: Core Display Elements

**TODO: Enhanced arena unit frames**
- [ ] Improve arena unit positioning and scaling
- [ ] Add class coloring for health bars
- [ ] Implement specialization icon display
- [ ] Add basic range checking
- [ ] Create arena preparation display

**TODO: Create ArenaSpecIcon element**
- [ ] Create `Elements/ArenaSpecIcon.lua`
- [ ] Implement spec detection from arena opponent data
- [ ] Add spec icon display with tooltips
- [ ] Include role detection (DPS/Healer/Tank)
- [ ] Add threat level assessment based on spec

**Elements/ArenaSpecIcon.lua Implementation:**
```lua
---@class oUF.ArenaSpecIcon : oUF.Element
local ArenaSpecIcon = {}

ArenaSpecIcon.elementName = 'ArenaSpecIcon'
ArenaSpecIcon.events = {'ARENA_PREP_OPPONENT_SPECIALIZATIONS', 'ARENA_OPPONENT_UPDATE'}

function ArenaSpecIcon:Update(event, ...)
    local specID = GetArenaOpponentSpec(self.__owner.id or 1)
    if specID and specID > 0 then
        local _, name, _, icon, role, class = GetSpecializationInfoByID(specID)
        
        self.icon:SetTexture(icon)
        self.name = name
        self.role = role
        self.class = class
        
        self:UpdateThreatLevel(specID)
        self:Show()
    else
        self:Hide()
    end
end
```

#### Week 6: Cooldown Tracking Foundation

**TODO: Create ArenaCooldowns element**
- [ ] Create `Elements/ArenaCooldowns.lua`
- [ ] Integrate with LibCooldownTracker-1.0
- [ ] Implement cooldown icon display system
- [ ] Add cooldown categorization (interrupt, defensive, offensive)
- [ ] Create cooldown priority system
- [ ] Add basic cooldown filtering

**TODO: Cooldown data integration**
- [ ] Create `Data/CooldownData.lua` - Arena-specific cooldown priorities
- [ ] Import LibCooldownTracker spell data
- [ ] Add arena-specific spell priorities
- [ ] Implement spell categorization system

**Elements/ArenaCooldowns.lua Implementation:**
```lua
---@class oUF.ArenaCooldowns : oUF.Element
local ArenaCooldowns = {}

ArenaCooldowns.elementName = 'ArenaCooldowns'
ArenaCooldowns.events = {'SPELL_UPDATE_COOLDOWN', 'COMBAT_LOG_EVENT_UNFILTERED'}

function ArenaCooldowns:Update(event, ...)
    if event == 'SPELL_UPDATE_COOLDOWN' then
        self:UpdateAllCooldowns()
    elseif event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        self:ProcessCombatEvent(...)
    end
end

function ArenaCooldowns:UpdateAllCooldowns()
    local unit = self.__owner.unit
    if not unit or not UnitExists(unit) then return end
    
    local cooldowns = LibCooldownTracker:GetUnitCooldowns(unit)
    local filtered = self:FilterImportantCooldowns(cooldowns)
    
    self:UpdateCooldownDisplay(filtered)
end
```

#### Week 7: Diminishing Returns Tracking

**TODO: Create ArenaDRTracker element**
- [ ] Create `Elements/ArenaDRTracker.lua`
- [ ] Integrate with DRList-1.0
- [ ] Implement DR calculation and tracking
- [ ] Add DR bar/icon display
- [ ] Create DR immunity warnings
- [ ] Add DR reset timers

**TODO: DR data management**
- [ ] Create DR tracking for all arena opponents
- [ ] Implement DR timeline visualization
- [ ] Add predictive DR warnings
- [ ] Create audio alerts for DR immunity

**Elements/ArenaDRTracker.lua Implementation:**
```lua
---@class oUF.ArenaDRTracker : oUF.Element
local ArenaDRTracker = {}

ArenaDRTracker.elementName = 'ArenaDRTracker'
ArenaDRTracker.events = {'COMBAT_LOG_EVENT_UNFILTERED'}

local DRList = LibStub('DRList-1.0')

function ArenaDRTracker:Update(event, timestamp, subevent, ...)
    if subevent == 'SPELL_AURA_APPLIED' or subevent == 'SPELL_AURA_REFRESH' then
        local sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
              destGUID, destName, destFlags, destRaidFlags, 
              spellId, spellName, spellSchool, auraType = ...
              
        if self:IsArenaUnit(destName) then
            self:ProcessDRApplication(destName, spellId, auraType)
        end
    end
end

function ArenaDRTracker:ProcessDRApplication(unit, spellId, auraType)
    local drCategory = DRList:GetCategoryBySpellID(spellId)
    if drCategory then
        self:UpdateDRData(unit, drCategory)
        self:UpdateDRDisplay(unit, drCategory)
    end
end
```

#### Week 8: Basic Target Calling

**TODO: Create ArenaTargetCalling element**
- [ ] Create `Elements/ArenaTargetCalling.lua`
- [ ] Implement target highlight system
- [ ] Add focus target highlighting
- [ ] Create target priority system
- [ ] Add basic target coordination features

**TODO: Target coordination system**
- [ ] Track team member targets
- [ ] Implement target swap detection
- [ ] Add target priority indicators
- [ ] Create basic target calling macros

**Elements/ArenaTargetCalling.lua Implementation:**
```lua
---@class oUF.ArenaTargetCalling : oUF.Element
local ArenaTargetCalling = {}

ArenaTargetCalling.elementName = 'ArenaTargetCalling'
ArenaTargetCalling.events = {'PLAYER_TARGET_CHANGED', 'PARTY_MEMBER_TARGET_CHANGED'}

function ArenaTargetCalling:Update(event, ...)
    self:UpdateTargetHighlights()
    self:UpdateFocusHighlights()
    self:UpdatePriorityDisplay()
end

function ArenaTargetCalling:UpdateTargetHighlights()
    for i = 1, 5 do
        local arenaFrame = LibArenaTools:GetArenaFrame(i)
        if arenaFrame then
            local isTargeted = UnitIsUnit('target', 'arena' .. i)
            self:SetTargetHighlight(arenaFrame, isTargeted)
        end
    end
end

function ArenaTargetCalling:SetTargetHighlight(frame, highlighted)
    if highlighted then
        frame.targetHighlight:Show()
        frame.targetHighlight:SetVertexColor(1, 0, 0, 0.8)
    else
        frame.targetHighlight:Hide()
    end
end
```

### Phase 1 Deliverables Checklist

**Core Framework:**
- [ ] ✅ LibArenaTools module integrated with SpartanUI
- [ ] ✅ Basic oUF arena unit spawning system
- [ ] ✅ Element registration and management system
- [ ] ✅ Configuration system with AceDB integration
- [ ] ✅ Basic options interface

**Essential Elements:**
- [ ] ✅ ArenaSpecIcon - Specialization detection and display
- [ ] ✅ ArenaCooldowns - Basic cooldown tracking
- [ ] ✅ ArenaDRTracker - Diminishing returns tracking
- [ ] ✅ ArenaTargetCalling - Target highlighting system

**Integration:**
- [ ] ✅ SpartanUI module registration
- [ ] ✅ Basic theme integration
- [ ] ✅ Options panel integration

---

## Phase 2: Advanced Features (Months 3-4)

### Month 3: Advanced Arena Elements

#### Week 9: Enhanced Cooldown System

**TODO: Advanced cooldown tracking**
- [ ] Implement intelligent cooldown prioritization
- [ ] Add cooldown category filtering
- [ ] Create cooldown usage prediction
- [ ] Add visual cooldown effects (LibCustomGlow)
- [ ] Implement cooldown sound alerts

**TODO: Cooldown optimization**
- [ ] Add cooldown caching system
- [ ] Implement update batching for performance
- [ ] Create cooldown importance scoring
- [ ] Add spec-specific cooldown priorities

**Enhanced ArenaCooldowns Implementation:**
```lua
function ArenaCooldowns:UpdateCooldownDisplay(cooldowns)
    -- Sort by priority and importance
    local prioritized = self:PrioritizeCooldowns(cooldowns)
    
    -- Limit to maximum displayed
    local maxCooldowns = self.db.maxCooldowns or 8
    local displayed = {}
    
    for i = 1, min(maxCooldowns, #prioritized) do
        displayed[i] = prioritized[i]
    end
    
    self:UpdateCooldownIcons(displayed)
    self:UpdateCooldownTimers(displayed)
end

function ArenaCooldowns:PrioritizeCooldowns(cooldowns)
    local prioritized = {}
    
    for spellId, cooldownData in pairs(cooldowns) do
        local priority = self:GetSpellPriority(spellId)
        local importance = self:CalculateImportance(spellId, cooldownData)
        
        table.insert(prioritized, {
            spellId = spellId,
            data = cooldownData,
            priority = priority,
            importance = importance
        })
    end
    
    table.sort(prioritized, function(a, b)
        if a.priority == b.priority then
            return a.importance > b.importance
        end
        return a.priority < b.priority
    end)
    
    return prioritized
end
```

#### Week 10: Interrupt Coordination System

**TODO: Create ArenaInterrupts element**
- [ ] Create `Elements/ArenaInterrupts.lua`
- [ ] Implement cast tracking for all arena units
- [ ] Add interrupt opportunity detection
- [ ] Create interrupt coordination system
- [ ] Add interrupt timing assistance

**TODO: Advanced interrupt features**
- [ ] Track team interrupt cooldowns
- [ ] Implement interrupt rotation suggestions
- [ ] Add cast priority assessment
- [ ] Create interrupt success/failure tracking

**Elements/ArenaInterrupts.lua Implementation:**
```lua
---@class oUF.ArenaInterrupts : oUF.Element
local ArenaInterrupts = {}

ArenaInterrupts.elementName = 'ArenaInterrupts'
ArenaInterrupts.events = {
    'UNIT_SPELLCAST_START',
    'UNIT_SPELLCAST_STOP', 
    'UNIT_SPELLCAST_INTERRUPTED',
    'SPELL_UPDATE_COOLDOWN'
}

function ArenaInterrupts:UNIT_SPELLCAST_START(event, unit)
    if not self:IsArenaUnit(unit) then return end
    
    local castInfo = self:GetCastInfo(unit)
    if castInfo and castInfo.canInterrupt then
        self:ShowInterruptOpportunity(unit, castInfo)
        self:CalculateInterruptPriority(unit, castInfo)
    end
end

function ArenaInterrupts:ShowInterruptOpportunity(unit, castInfo)
    local frame = LibArenaTools:GetArenaFrame(unit)
    if frame and frame.ArenaInterrupts then
        frame.ArenaInterrupts.opportunity:Show()
        frame.ArenaInterrupts.priority = castInfo.priority
        
        -- Add glow effect for high priority casts
        if castInfo.priority >= 3 then
            LibCustomGlow.PixelGlow_Start(frame)
        end
    end
end
```

#### Week 11: PvP Trinket and Immunity Tracking

**TODO: Create ArenaPvPTrinket element**
- [ ] Create `Elements/ArenaPvPTrinket.lua`
- [ ] Track PvP trinket usage for all opponents
- [ ] Implement trinket cooldown display
- [ ] Add immunity duration tracking
- [ ] Create vulnerability window indicators

**TODO: Immunity system tracking**
- [ ] Track all immunity effects (Divine Shield, Ice Block, etc.)
- [ ] Implement immunity duration timers
- [ ] Add vulnerability predictions
- [ ] Create immunity coordination features

**Elements/ArenaPvPTrinket.lua Implementation:**
```lua
---@class oUF.ArenaPvPTrinket : oUF.Element
local ArenaPvPTrinket = {}

ArenaPvPTrinket.elementName = 'ArenaPvPTrinket'
ArenaPvPTrinket.events = {'COMBAT_LOG_EVENT_UNFILTERED'}

-- PvP trinket spell IDs
local PVP_TRINKET_SPELLS = {
    [336126] = 120, -- Gladiator's Medallion (Retail)
    [42292] = 120,  -- PvP Trinket (Classic)
}

function ArenaPvPTrinket:Update(event, timestamp, subevent, ...)
    if subevent == 'SPELL_CAST_SUCCESS' then
        local sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
              destGUID, destName, destFlags, destRaidFlags, 
              spellId = ...
              
        if PVP_TRINKET_SPELLS[spellId] and self:IsArenaOpponent(sourceName) then
            self:ProcessTrinketUse(sourceName, spellId, timestamp)
        end
    end
end

function ArenaPvPTrinket:ProcessTrinketUse(unit, spellId, timestamp)
    local cooldown = PVP_TRINKET_SPELLS[spellId]
    
    self.trinketData[unit] = {
        lastUsed = timestamp,
        cooldown = cooldown,
        readyTime = timestamp + cooldown
    }
    
    self:UpdateTrinketDisplay(unit)
    self:StartCooldownTimer(unit, cooldown)
end
```

#### Week 12: Arena Skill History

**TODO: Create ArenaSkillHistory element**
- [ ] Create `Elements/ArenaSkillHistory.lua`
- [ ] Track important ability usage
- [ ] Implement skill history timeline
- [ ] Add ability pattern recognition
- [ ] Create usage frequency analysis

**TODO: Skill analysis features**
- [ ] Track healing cooldown usage patterns
- [ ] Monitor offensive cooldown coordination
- [ ] Analyze defensive ability timing
- [ ] Create pattern-based predictions

**Elements/ArenaSkillHistory.lua Implementation:**
```lua
---@class oUF.ArenaSkillHistory : oUF.Element
local ArenaSkillHistory = {}

ArenaSkillHistory.elementName = 'ArenaSkillHistory'
ArenaSkillHistory.events = {'COMBAT_LOG_EVENT_UNFILTERED'}

function ArenaSkillHistory:Update(event, timestamp, subevent, ...)
    if subevent == 'SPELL_CAST_SUCCESS' then
        local sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
              destGUID, destName, destFlags, destRaidFlags, 
              spellId, spellName = ...
              
        if self:IsImportantSpell(spellId) and self:IsArenaOpponent(sourceName) then
            self:RecordSkillUsage(sourceName, spellId, timestamp)
        end
    end
end

function ArenaSkillHistory:RecordSkillUsage(unit, spellId, timestamp)
    if not self.skillHistory[unit] then
        self.skillHistory[unit] = {}
    end
    
    table.insert(self.skillHistory[unit], {
        spellId = spellId,
        timestamp = timestamp,
        matchTime = self:GetMatchTime()
    })
    
    -- Keep only last 20 abilities
    while #self.skillHistory[unit] > 20 do
        table.remove(self.skillHistory[unit], 1)
    end
    
    self:UpdateHistoryDisplay(unit)
end
```

### Month 4: Performance and Polish

#### Week 13: Performance Optimization

**TODO: Implement performance monitoring**
- [ ] Create `Core/PerformanceMonitor.lua`
- [ ] Add update time tracking for all elements
- [ ] Implement memory usage monitoring
- [ ] Create performance bottleneck detection
- [ ] Add performance reporting system

**TODO: Optimize update systems**
- [ ] Implement intelligent update batching
- [ ] Add smart event filtering
- [ ] Create update frequency throttling
- [ ] Optimize memory allocation patterns

**Core/PerformanceMonitor.lua Implementation:**
```lua
---@class LibArenaTools.PerformanceMonitor
local PerformanceMonitor = {
    updateTimes = {},
    memorySnapshots = {},
    eventCounts = {},
    enabled = false
}

function PerformanceMonitor:StartProfiling()
    self.enabled = true
    self.startTime = GetTime()
    self.startMemory = gcinfo()
    
    -- Hook all element update functions
    self:HookElementUpdates()
end

function PerformanceMonitor:RecordUpdateTime(elementName, startTime, endTime)
    if not self.enabled then return end
    
    local duration = endTime - startTime
    
    if not self.updateTimes[elementName] then
        self.updateTimes[elementName] = {}
    end
    
    table.insert(self.updateTimes[elementName], duration)
    
    -- Keep only last 100 measurements
    local times = self.updateTimes[elementName]
    if #times > 100 then
        table.remove(times, 1)
    end
end

function PerformanceMonitor:GetAverageUpdateTime(elementName)
    local times = self.updateTimes[elementName]
    if not times or #times == 0 then return 0 end
    
    local total = 0
    for _, time in ipairs(times) do
        total = total + time
    end
    
    return total / #times
end
```

#### Week 14: Advanced Configuration System

**TODO: Enhanced configuration options**
- [ ] Create advanced element configuration interfaces
- [ ] Add configuration presets for different playstyles
- [ ] Implement configuration import/export
- [ ] Create configuration validation system
- [ ] Add real-time configuration preview

**TODO: Profile management**
- [ ] Add character-specific profiles
- [ ] Create spec-based profile switching
- [ ] Implement configuration backup system
- [ ] Add profile sharing functionality

**Enhanced ConfigManager Implementation:**
```lua
function ConfigManager:CreateConfigurationPresets()
    return {
        ['Healer'] = {
            elements = {
                ArenaCooldowns = {
                    categories = {
                        interrupt = true,
                        defensive = true,
                        offensive = false,
                        utility = false
                    }
                },
                ArenaDRTracker = {
                    categories = {'stun', 'fear', 'incap'}
                }
            }
        },
        ['DPS'] = {
            elements = {
                ArenaCooldowns = {
                    categories = {
                        interrupt = true,
                        defensive = true,
                        offensive = true,
                        utility = false
                    }
                }
            }
        },
        ['Competitive'] = {
            elements = {
                -- All features enabled with maximum information
            }
        }
    }
end

function ConfigManager:ApplyPreset(presetName)
    local preset = self:GetPreset(presetName)
    if preset then
        self:MergeConfiguration(preset)
        LibArenaTools:RefreshAllElements()
    end
end
```

#### Week 15: GladiusEX Migration Tools

**TODO: Create Migration.lua**
- [ ] Implement GladiusEX configuration detection
- [ ] Create configuration conversion system
- [ ] Add migration validation and testing
- [ ] Implement migration rollback functionality
- [ ] Create migration success reporting

**TODO: Migration interface**
- [ ] Add migration wizard to options panel
- [ ] Create step-by-step migration process
- [ ] Add migration preview functionality
- [ ] Implement selective migration options

**Migration.lua Implementation:**
```lua
---@class LibArenaTools.Migration
local Migration = {}

function Migration:DetectGladiusEX()
    return _G.GladiusExDB ~= nil
end

function Migration:AnalyzeGladiusEXConfig()
    local gladiusDB = _G.GladiusExDB
    if not gladiusDB then return nil end
    
    local analysis = {
        hasProfiles = gladiusDB.profiles ~= nil,
        profileCount = 0,
        elements = {},
        positioning = {},
        customizations = {}
    }
    
    if gladiusDB.profiles then
        for profileName, profile in pairs(gladiusDB.profiles) do
            analysis.profileCount = analysis.profileCount + 1
            
            if profile.arena then
                analysis.elements[profileName] = self:AnalyzeElements(profile.arena)
                analysis.positioning[profileName] = self:AnalyzePositioning(profile.arena)
            end
        end
    end
    
    return analysis
end

function Migration:ExecuteMigration(options)
    local gladiusDB = _G.GladiusExDB
    if not gladiusDB then
        return false, "GladiusEX configuration not found"
    end
    
    local migrationResults = {
        success = true,
        profilesMigrated = 0,
        elementsMigrated = 0,
        errors = {}
    }
    
    -- Backup current configuration
    self:BackupCurrentConfig()
    
    -- Migrate profiles
    if gladiusDB.profiles then
        for profileName, profile in pairs(gladiusDB.profiles) do
            if options.profiles[profileName] then
                local success, error = self:MigrateProfile(profileName, profile)
                if success then
                    migrationResults.profilesMigrated = migrationResults.profilesMigrated + 1
                else
                    table.insert(migrationResults.errors, error)
                end
            end
        end
    end
    
    return migrationResults.success, migrationResults
end
```

#### Week 16: Testing and Quality Assurance

**TODO: Create comprehensive testing system**
- [ ] Create `Tests/UnitTests.lua` - Automated unit tests
- [ ] Create `Tests/IntegrationTests.lua` - Integration testing
- [ ] Create `Tests/PerformanceTests.lua` - Performance benchmarks
- [ ] Implement automated test running
- [ ] Add test result reporting

**TODO: Quality assurance processes**
- [ ] Create manual testing checklists
- [ ] Implement arena environment testing
- [ ] Add memory leak detection
- [ ] Create performance regression testing
- [ ] Implement configuration validation testing

**Tests/UnitTests.lua Implementation:**
```lua
---@class LibArenaTools.UnitTests
local UnitTests = {
    results = {passed = 0, failed = 0, errors = {}}
}

function UnitTests:RunAllTests()
    self:ResetResults()
    
    -- Core functionality tests
    self:TestArenaManager()
    self:TestElementRegistry()
    self:TestConfigManager()
    
    -- Element tests
    self:TestArenaCooldowns()
    self:TestArenaDRTracker()
    self:TestArenaTargetCalling()
    
    return self.results
end

function UnitTests:TestArenaCooldowns()
    local testName = "ArenaCooldowns Element"
    
    local success, error = pcall(function()
        -- Test cooldown detection
        local mockUnit = "arena1"
        local mockSpell = 47528 -- Mind Freeze
        
        -- Simulate spell usage
        LibArenaTools.Elements.ArenaCooldowns:SimulateSpellUse(mockUnit, mockSpell)
        
        -- Verify tracking
        local cooldowns = LibArenaTools.Elements.ArenaCooldowns:GetUnitCooldowns(mockUnit)
        assert(cooldowns[mockSpell], "Cooldown not tracked")
        assert(cooldowns[mockSpell].remaining > 0, "Invalid cooldown time")
    end)
    
    self:RecordTestResult(testName, success, error)
end
```

### Phase 2 Deliverables Checklist

**Advanced Elements:**
- [ ] ✅ Enhanced ArenaCooldowns with prioritization and filtering
- [ ] ✅ ArenaInterrupts with coordination system
- [ ] ✅ ArenaPvPTrinket with immunity tracking
- [ ] ✅ ArenaSkillHistory with pattern recognition

**Performance Systems:**
- [ ] ✅ Performance monitoring and optimization
- [ ] ✅ Update batching and caching systems
- [ ] ✅ Memory management and leak prevention

**Configuration:**
- [ ] ✅ Advanced configuration options
- [ ] ✅ Configuration presets and profiles
- [ ] ✅ GladiusEX migration tools

**Quality Assurance:**
- [ ] ✅ Comprehensive testing framework
- [ ] ✅ Performance benchmarking
- [ ] ✅ Configuration validation

---

## Phase 3: Integration and Launch (Months 5-6)

### Month 5: Deep SpartanUI Integration

#### Week 17: Theme Synchronization

**TODO: Create Integration/ThemeSync.lua**
- [ ] Implement complete theme mapping system
- [ ] Add real-time theme change detection
- [ ] Create arena-specific theme adaptations
- [ ] Implement theme override capabilities
- [ ] Add custom theme support

**TODO: Theme integration for all SpartanUI themes**
- [ ] Classic theme integration
- [ ] War theme integration
- [ ] Fel theme integration
- [ ] Digital theme integration
- [ ] Minimal theme integration
- [ ] Tribal theme integration

**Integration/ThemeSync.lua Implementation:**
```lua
---@class LibArenaTools.ThemeSync
local ThemeSync = {
    themeMappings = {},
    currentTheme = nil
}

function ThemeSync:Initialize()
    self:BuildThemeMappings()
    self:RegisterThemeEvents()
    
    -- Apply current theme
    local currentTheme = SUI.DB.Artwork.Style
    self:ApplyTheme(currentTheme)
end

function ThemeSync:BuildThemeMappings()
    self.themeMappings = {
        ['Classic'] = {
            healthBar = {
                texture = 'Interface\\TargetingFrame\\UI-StatusBar',
                color = {r = 0, g = 1, b = 0, a = 1}
            },
            background = {
                texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
                color = {r = 0, g = 0, b = 0, a = 0.8}
            },
            border = {
                texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
                size = 1,
                color = {r = 1, g = 1, b = 1, a = 1}
            },
            font = {
                family = 'Fonts\\FRIZQT__.TTF',
                size = 12,
                flags = 'OUTLINE'
            }
        },
        
        ['War'] = {
            healthBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2',
                color = {r = 0.8, g = 0, b = 0, a = 1}
            },
            background = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\backgrounds\\WarBackground',
                color = {r = 0.1, g = 0, b = 0, a = 0.9}
            },
            font = {
                family = 'Interface\\AddOns\\SpartanUI\\fonts\\Continuum.ttf',
                size = 12,
                flags = 'OUTLINE'
            }
        }
        -- ... other themes
    }
end

function ThemeSync:ApplyTheme(themeName)
    local themeData = self.themeMappings[themeName]
    if not themeData then return end
    
    self.currentTheme = themeName
    
    -- Apply to all arena frames
    for i = 1, 5 do
        local frame = LibArenaTools:GetArenaFrame(i)
        if frame then
            self:ApplyThemeToFrame(frame, themeData)
        end
    end
    
    -- Update element themes
    LibArenaTools.ElementRegistry:UpdateAllElementThemes(themeData)
end
```

#### Week 18: Position Coordination

**TODO: Create Integration/PositionManager.lua**
- [ ] Implement dynamic position coordination
- [ ] Add collision detection with other modules
- [ ] Create automatic position adjustment
- [ ] Implement position saving per theme
- [ ] Add manual position override options

**TODO: Coordinate with SpartanUI modules**
- [ ] Coordinate with party frames positioning
- [ ] Avoid conflicts with target frames
- [ ] Coordinate with raid frames
- [ ] Handle Artwork module interactions
- [ ] Manage MoveIt integration

**Integration/PositionManager.lua Implementation:**
```lua
---@class LibArenaTools.PositionManager
local PositionManager = {
    basePositions = {},
    adjustedPositions = {},
    conflictResolution = true
}

function PositionManager:Initialize()
    self:LoadBasePositions()
    self:RegisterPositionEvents()
    self:CalculateOptimalPositions()
end

function PositionManager:LoadBasePositions()
    -- Get positions from current artwork style
    local artworkStyle = SUI.DB.Artwork.Style
    local styleData = SUI.UF.Style:Get(artworkStyle)
    
    if styleData and styleData.positions and styleData.positions.arena then
        self.basePositions.arena = styleData.positions.arena
    else
        -- Use default positions
        self.basePositions.arena = 'RIGHT,UIParent,RIGHT,-50,0'
    end
end

function PositionManager:CalculateOptimalPositions()
    local finalPositions = CopyTable(self.basePositions)
    
    if self.conflictResolution then
        finalPositions = self:ResolvePositionConflicts(finalPositions)
    end
    
    self.adjustedPositions = finalPositions
    self:ApplyPositions()
end

function PositionManager:ResolvePositionConflicts(positions)
    local conflicts = self:DetectConflicts(positions)
    
    for conflictType, conflictData in pairs(conflicts) do
        positions = self:ResolveConflict(positions, conflictType, conflictData)
    end
    
    return positions
end

function PositionManager:DetectConflicts(positions)
    local conflicts = {}
    
    -- Check party frame conflicts
    local partyFrame = SUI.UF.Unit:Get('party')
    if partyFrame and partyFrame:IsShown() then
        local partyBounds = self:GetFrameBounds(partyFrame)
        local arenaBounds = self:GetPredictedBounds(positions.arena)
        
        if self:BoundsOverlap(partyBounds, arenaBounds) then
            conflicts.party = {
                severity = 'high',
                bounds = partyBounds,
                suggestedOffset = self:CalculateAvoidanceOffset(partyBounds, arenaBounds)
            }
        end
    end
    
    return conflicts
end
```

#### Week 19: Configuration Bridge

**TODO: Create Integration/ConfigBridge.lua**
- [ ] Integrate arena options into SpartanUI config panel
- [ ] Create unified configuration experience
- [ ] Add arena configuration to profiles
- [ ] Implement configuration inheritance
- [ ] Create configuration conflict resolution

**TODO: SpartanUI options integration**
- [ ] Add LibArenaTools section to main options
- [ ] Create per-theme configuration options
- [ ] Add quick setup wizards
- [ ] Implement configuration reset options
- [ ] Add import/export functionality

**Integration/ConfigBridge.lua Implementation:**
```lua
---@class LibArenaTools.ConfigBridge
local ConfigBridge = {}

function ConfigBridge:BuildSpartanUIOptions()
    return {
        type = 'group',
        name = 'Arena Tools',
        desc = 'Advanced arena frames and tools',
        icon = 'Interface\\Icons\\Achievement_PVP_A_A',
        order = 70,
        args = {
            header = {
                type = 'header',
                name = 'LibArenaTools - Advanced Arena Frames',
                order = 1
            },
            
            enabled = {
                type = 'toggle',
                name = 'Enable Arena Tools',
                desc = 'Enable LibArenaTools enhanced arena frames',
                get = function() return LibArenaTools.db.enabled end,
                set = function(_, value)
                    LibArenaTools.db.enabled = value
                    LibArenaTools:SetEnabled(value)
                end,
                order = 2
            },
            
            mode = {
                type = 'select',
                name = 'Arena Mode',
                desc = 'Select the arena tools mode',
                values = {
                    enhanced = 'Enhanced (Full Features)',
                    basic = 'Basic (Core Only)',
                    replace = 'Replace Default Only'
                },
                get = function() return LibArenaTools.db.mode end,
                set = function(_, value)
                    LibArenaTools.db.mode = value
                    LibArenaTools:SetMode(value)
                end,
                order = 3
            },
            
            quickSetup = {
                type = 'group',
                name = 'Quick Setup',
                inline = true,
                order = 4,
                args = {
                    healer = {
                        type = 'execute',
                        name = 'Healer Setup',
                        desc = 'Configure for healer playstyle',
                        func = function() self:ApplyHealerPreset() end
                    },
                    dps = {
                        type = 'execute', 
                        name = 'DPS Setup',
                        desc = 'Configure for DPS playstyle',
                        func = function() self:ApplyDPSPreset() end
                    },
                    competitive = {
                        type = 'execute',
                        name = 'Competitive Setup',
                        desc = 'Maximum information for competitive play',
                        func = function() self:ApplyCompetitivePreset() end
                    }
                }
            },
            
            elements = self:BuildElementOptions(),
            positioning = self:BuildPositionOptions(),
            migration = self:BuildMigrationOptions()
        }
    }
end
```

#### Week 20: Event Integration

**TODO: Create Integration/EventRelay.lua**
- [ ] Integrate with SpartanUI event system
- [ ] Create arena-specific event handling
- [ ] Add cross-module event communication
- [ ] Implement event priority management
- [ ] Create event debugging capabilities

**TODO: SpartanUI event coordination**
- [ ] Coordinate PLAYER_ENTERING_WORLD events
- [ ] Handle ADDON_LOADED coordination
- [ ] Manage COMBAT_LOG events efficiently
- [ ] Coordinate UI refresh events
- [ ] Handle profile change events

### Month 6: Standalone Mode and Launch

#### Week 21: Standalone Mode Development

**TODO: Create standalone functionality**
- [ ] Create minimal oUF environment for standalone
- [ ] Implement independent configuration system
- [ ] Add basic theme system for standalone
- [ ] Create standalone addon structure
- [ ] Implement feature parity checking

**TODO: Standalone mode testing**
- [ ] Test without SpartanUI dependencies
- [ ] Verify all features work independently
- [ ] Test configuration persistence
- [ ] Validate performance in standalone mode
- [ ] Test compatibility with other UI addons

**Standalone Implementation:**
```lua
-- Standalone mode detection and setup
if not SUI then
    -- Create minimal SUI environment for standalone mode
    LibArenaTools.StandaloneMode = true
    LibArenaTools:InitializeStandaloneEnvironment()
end

function LibArenaTools:InitializeStandaloneEnvironment()
    -- Create minimal oUF environment
    self:SetupStandaloneoUF()
    
    -- Create independent configuration
    self:InitializeStandaloneConfig()
    
    -- Setup basic theme system
    self:InitializeStandaloneThemes()
    
    -- Create options interface
    self:CreateStandaloneOptions()
end

function LibArenaTools:SetupStandaloneoUF()
    -- Verify oUF is available
    if not oUF then
        error("LibArenaTools: oUF is required for standalone mode")
    end
    
    -- Create our own oUF style
    oUF:RegisterStyle('LibArenaTools', function(frame, unit)
        self:StyleArenaFrame(frame, unit)
    end)
    
    oUF:SetActiveStyle('LibArenaTools')
end
```

#### Week 22: Documentation and Help System

**TODO: Create comprehensive documentation**
- [ ] Write user installation guide
- [ ] Create configuration documentation
- [ ] Add element feature documentation
- [ ] Create troubleshooting guide
- [ ] Write developer API documentation

**TODO: In-game help system**
- [ ] Create interactive help tooltips
- [ ] Add configuration wizard
- [ ] Implement feature showcase mode
- [ ] Create help command system
- [ ] Add context-sensitive help

#### Week 23: Beta Testing and Bug Fixes

**TODO: Beta testing program**
- [ ] Create beta test builds
- [ ] Recruit arena community testers
- [ ] Setup feedback collection system
- [ ] Implement rapid bug fix deployment
- [ ] Create performance monitoring

**TODO: Bug fix and optimization phase**
- [ ] Fix all critical and high priority bugs
- [ ] Optimize performance based on testing data
- [ ] Resolve configuration issues
- [ ] Fix compatibility problems
- [ ] Polish user interface elements

#### Week 24: Launch Preparation and Release

**TODO: Release preparation**
- [ ] Final code review and cleanup
- [ ] Complete documentation review
- [ ] Create release notes
- [ ] Prepare distribution packages
- [ ] Setup community channels

**TODO: Launch execution**
- [ ] Release to SpartanUI users first
- [ ] Announce to arena community
- [ ] Monitor initial feedback
- [ ] Provide rapid support responses
- [ ] Plan first update cycle

### Phase 3 Deliverables Checklist

**SpartanUI Integration:**
- [ ] ✅ Complete theme synchronization system
- [ ] ✅ Advanced position coordination
- [ ] ✅ Unified configuration experience
- [ ] ✅ Cross-module event integration

**Standalone Mode:**
- [ ] ✅ Fully functional standalone addon
- [ ] ✅ Independent configuration system
- [ ] ✅ Compatibility with other UI addons

**Launch Readiness:**
- [ ] ✅ Comprehensive documentation
- [ ] ✅ Beta testing completion
- [ ] ✅ All critical bugs resolved
- [ ] ✅ Performance optimized
- [ ] ✅ Community channels established

---

## Implementation Success Metrics

### Development Progress Tracking

**Phase 1 Success Criteria:**
- All core elements functional in arena environment
- Basic SpartanUI integration working
- Performance baseline established (sub-5ms updates)
- Configuration system operational

**Phase 2 Success Criteria:**
- All advanced elements implemented and tested
- Performance targets met (sub-2ms updates, <10MB memory)
- Migration tools validated with GladiusEX configurations
- Comprehensive testing suite operational

**Phase 3 Success Criteria:**
- Perfect SpartanUI theme integration across all themes
- Standalone mode fully functional
- Documentation complete and user-friendly
- Beta testing feedback incorporated
- Ready for public release

### Quality Gates

**Code Quality Requirements:**
- [ ] All code follows SpartanUI patterns and standards
- [ ] Comprehensive error handling implemented
- [ ] Performance monitoring integrated
- [ ] Memory leak testing passed
- [ ] Cross-addon compatibility verified

**Feature Completeness:**
- [ ] Feature parity with GladiusEX achieved
- [ ] SpartanUI-specific enhancements implemented
- [ ] Performance superiority demonstrated
- [ ] User experience improvements validated

**Integration Requirements:**
- [ ] Seamless SpartanUI integration across all modules
- [ ] Theme synchronization perfect across all themes
- [ ] Configuration inheritance working properly
- [ ] Event coordination functioning correctly

---

## Risk Mitigation Strategies

### Technical Risks

**Performance Risk:**
- **Mitigation**: Continuous performance monitoring and optimization
- **Fallback**: Performance degradation alerts and automatic feature scaling

**Compatibility Risk:**
- **Mitigation**: Extensive testing with multiple addon combinations
- **Fallback**: Compatibility mode with reduced features

**Integration Risk:**
- **Mitigation**: Close coordination with SpartanUI core development
- **Fallback**: Standalone mode with reduced integration features

### Development Risks

**Timeline Risk:**
- **Mitigation**: Modular development with independent deliverables
- **Fallback**: Feature reduction to meet critical launch dates

**Complexity Risk:**
- **Mitigation**: Regular code reviews and architecture validation
- **Fallback**: Simplified feature set with core functionality focus

**Resource Risk:**
- **Mitigation**: Cross-training and comprehensive documentation
- **Fallback**: Community development assistance programs

---

## Post-Launch Development Plan

### Immediate Post-Launch (Month 7)

**TODO: Launch support and stabilization**
- [ ] Monitor user feedback and bug reports
- [ ] Deploy rapid hotfixes for critical issues
- [ ] Optimize performance based on real-world usage
- [ ] Expand documentation based on user questions
- [ ] Begin community feature request collection

### First Major Update (Month 8-9)

**TODO: Community-driven improvements**
- [ ] Implement most requested features
- [ ] Add additional arena elements based on feedback
- [ ] Expand customization options
- [ ] Improve migration tools based on user experience
- [ ] Add advanced configuration presets

### Long-term Development (Month 10+)

**TODO: Advanced features and innovation**
- [ ] Machine learning integration for ability prediction
- [ ] Advanced team coordination features
- [ ] Tournament mode with enhanced features
- [ ] Community element marketplace
- [ ] Cross-server configuration synchronization

This implementation plan provides a comprehensive roadmap for developing LibArenaTools from initial concept through launch and beyond, with detailed TODO items and success criteria for each phase of development.