# oUF Element Specifications for LibArenaTools

## Overview

This document provides detailed specifications for all oUF elements that will be created for LibArenaTools. Each element follows the standard oUF pattern while providing arena-specific functionality that enhances competitive PvP gameplay.

**Design Principles:**
- **Performance First**: Optimized for arena environments where every millisecond counts
- **Modularity**: Each element can be independently enabled/disabled
- **Configurability**: Extensive customization options for different playstyles
- **Integration**: Seamless integration with SpartanUI systems

---

## 1. Core Arena Elements

### 1.1 ArenaCooldowns Element

**Purpose**: Track and display important cooldowns for arena opponents with intelligent prioritization.

**File**: `Elements/ArenaCooldowns.lua`

#### Specification

```lua
---@class oUF.ArenaCooldowns : oUF.Element
local ArenaCooldowns = {}

-- Element configuration
ArenaCooldowns.elementName = 'ArenaCooldowns'
ArenaCooldowns.priority = 10
ArenaCooldowns.events = {
    'SPELL_UPDATE_COOLDOWN',
    'COMBAT_LOG_EVENT_UNFILTERED',
    'ARENA_OPPONENT_UPDATE',
    'ARENA_PREP_OPPONENT_SPECIALIZATIONS'
}

-- Default configuration
ArenaCooldowns.defaults = {
    enabled = true,
    maxCooldowns = 8,
    iconSize = 24,
    growthDirection = 'RIGHT', -- 'RIGHT', 'LEFT', 'UP', 'DOWN'
    spacing = 2,
    perRow = 4,
    
    -- Positioning
    anchor = 'TOPLEFT',
    relativePoint = 'BOTTOMLEFT',
    offsetX = 0,
    offsetY = -2,
    
    -- Visual settings
    showTooltips = true,
    showTimers = true,
    showStacks = true,
    cropIcons = true,
    desaturateUsed = true,
    
    -- Categories and priorities
    categories = {
        interrupt = {enabled = true, priority = 1, color = {r=1, g=0, b=0}},
        defensive = {enabled = true, priority = 2, color = {r=0, g=1, b=1}},
        offensive = {enabled = true, priority = 3, color = {r=1, g=0.5, b=0}},
        utility = {enabled = false, priority = 4, color = {r=0.8, g=0.8, b=0.8}},
        movement = {enabled = false, priority = 5, color = {r=0, g=1, b=0}},
        heal = {enabled = true, priority = 2, color = {r=0, g=1, b=0}}
    },
    
    -- Filtering options
    filters = {
        showOnlyImportant = false,
        hideUsedCooldowns = false,
        minCooldownTime = 10, -- Don't show cooldowns shorter than this
        maxCooldownTime = 600, -- Don't show cooldowns longer than this
        hideInactiveCooldowns = true
    },
    
    -- Alert settings
    alerts = {
        readyAlert = true,
        readySound = 'Interface\\AddOns\\LibArenaTools\\Media\\Sounds\\CooldownReady.ogg',
        usedAlert = false,
        usedSound = nil
    }
}
```

#### Core Methods

```lua
function ArenaCooldowns:Update(event, ...)
    if event == 'SPELL_UPDATE_COOLDOWN' then
        self:UpdateAllCooldowns()
    elseif event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        self:ProcessCombatEvent(...)
    elseif event == 'ARENA_OPPONENT_UPDATE' then
        self:RefreshOpponentCooldowns()
    end
end

function ArenaCooldowns:UpdateAllCooldowns()
    local unit = self.__owner.unit
    if not unit or not UnitExists(unit) then return end
    
    -- Get cached cooldowns
    local cooldowns = self:GetCachedCooldowns(unit)
    
    -- Apply filters
    local filtered = self:ApplyFilters(cooldowns)
    
    -- Sort by priority and importance
    local sorted = self:SortCooldowns(filtered)
    
    -- Update display
    self:UpdateDisplay(sorted)
end

function ArenaCooldowns:GetCachedCooldowns(unit)
    -- Check cache first
    local cached = LibArenaTools.Cache:Get('cooldowns', unit, 0.1)
    if cached then return cached end
    
    -- Get fresh data from LibCooldownTracker
    local cooldowns = LibCooldownTracker:GetUnitCooldowns(unit)
    
    -- Enhance with our priority data
    local enhanced = {}
    for spellId, cooldownData in pairs(cooldowns) do
        enhanced[spellId] = self:EnhanceCooldownData(spellId, cooldownData)
    end
    
    -- Cache the result
    LibArenaTools.Cache:Set('cooldowns', unit, enhanced)
    
    return enhanced
end

function ArenaCooldowns:EnhanceCooldownData(spellId, cooldownData)
    local enhanced = CopyTable(cooldownData)
    
    -- Add category information
    enhanced.category = self:GetSpellCategory(spellId)
    enhanced.priority = self:GetSpellPriority(spellId)
    enhanced.importance = self:CalculateImportance(spellId, cooldownData)
    
    return enhanced
end

function ArenaCooldowns:GetSpellCategory(spellId)
    -- Check against spell database
    local spellData = LibArenaTools.Data:GetSpellData(spellId)
    if spellData then
        return spellData.category
    end
    
    -- Fallback to LibCooldownTracker categories
    return LibCooldownTracker:GetSpellCategory(spellId) or 'utility'
end

function ArenaCooldowns:CalculateImportance(spellId, cooldownData)
    local importance = 0
    
    -- Base importance from spell priority
    importance = importance + (self:GetSpellPriority(spellId) * 10)
    
    -- Boost importance for shorter cooldowns (more frequently available)
    local cooldownTime = cooldownData.duration or 0
    if cooldownTime > 0 then
        importance = importance + (300 / cooldownTime) -- 5 minute baseline
    end
    
    -- Boost importance for spells that are almost ready
    local remaining = cooldownData.remaining or 0
    if remaining < 30 then
        importance = importance + (30 - remaining)
    end
    
    return importance
end

function ArenaCooldowns:UpdateDisplay(sortedCooldowns)
    local maxCooldowns = self.db.maxCooldowns
    local displayed = 0
    
    -- Hide all icons first
    for i = 1, maxCooldowns do
        if self.icons[i] then
            self.icons[i]:Hide()
        end
    end
    
    -- Show sorted cooldowns up to max
    for i, cooldownData in ipairs(sortedCooldowns) do
        if displayed >= maxCooldowns then break end
        
        displayed = displayed + 1
        self:UpdateCooldownIcon(displayed, cooldownData)
    end
end

function ArenaCooldowns:UpdateCooldownIcon(index, cooldownData)
    local icon = self.icons[index]
    if not icon then
        icon = self:CreateCooldownIcon(index)
        self.icons[index] = icon
    end
    
    -- Update icon texture
    local spellTexture = GetSpellTexture(cooldownData.spellId)
    icon.texture:SetTexture(spellTexture)
    
    -- Update cooldown sweep
    if cooldownData.remaining and cooldownData.remaining > 0 then
        icon.cooldown:SetCooldown(
            GetTime() - (cooldownData.duration - cooldownData.remaining),
            cooldownData.duration
        )
        
        if self.db.desaturateUsed then
            icon.texture:SetDesaturated(true)
        end
    else
        icon.cooldown:Clear()
        icon.texture:SetDesaturated(false)
        
        -- Fire ready alert if enabled
        if self.db.alerts.readyAlert then
            self:PlayReadyAlert(cooldownData.spellId)
        end
    end
    
    -- Update border color based on category
    local category = cooldownData.category
    local categoryData = self.db.categories[category]
    if categoryData and categoryData.color then
        icon.border:SetVertexColor(
            categoryData.color.r,
            categoryData.color.g,
            categoryData.color.b,
            1
        )
    end
    
    -- Show/update stacks
    if cooldownData.stacks and cooldownData.stacks > 1 and self.db.showStacks then
        icon.stacks:SetText(cooldownData.stacks)
        icon.stacks:Show()
    else
        icon.stacks:Hide()
    end
    
    icon:Show()
end
```

#### Integration Points

```lua
-- Integration with LibCooldownTracker
function ArenaCooldowns:IntegrateLibCooldownTracker()
    LibCooldownTracker.RegisterCallback(self, 'LCT_CooldownUsed', 'OnCooldownUsed')
    LibCooldownTracker.RegisterCallback(self, 'LCT_CooldownReady', 'OnCooldownReady')
end

-- Integration with SpartanUI themes
function ArenaCooldowns:ApplyTheme(themeData)
    if not self.icons then return end
    
    for _, icon in pairs(self.icons) do
        -- Update border texture
        if themeData.border and themeData.border.texture then
            icon.border:SetTexture(themeData.border.texture)
        end
        
        -- Update background
        if themeData.background then
            icon.background:SetColorTexture(
                themeData.background.color.r,
                themeData.background.color.g,
                themeData.background.color.b,
                themeData.background.color.a
            )
        end
    end
end
```

### 1.2 ArenaDRTracker Element

**Purpose**: Track and display diminishing returns for crowd control effects with predictive warnings.

**File**: `Elements/ArenaDRTracker.lua`

#### Specification

```lua
---@class oUF.ArenaDRTracker : oUF.Element
local ArenaDRTracker = {}

ArenaDRTracker.elementName = 'ArenaDRTracker'
ArenaDRTracker.priority = 9
ArenaDRTracker.events = {
    'COMBAT_LOG_EVENT_UNFILTERED',
    'ARENA_OPPONENT_UPDATE'
}

-- Default configuration
ArenaDRTracker.defaults = {
    enabled = true,
    displayMode = 'both', -- 'bars', 'icons', 'both'
    
    -- Bar settings
    barWidth = 100,
    barHeight = 4,
    barSpacing = 1,
    showBarText = true,
    
    -- Icon settings
    iconSize = 16,
    iconSpacing = 2,
    iconsPerRow = 4,
    
    -- Positioning
    anchor = 'TOPLEFT',
    relativePoint = 'BOTTOMLEFT',
    offsetX = 0,
    offsetY = -2,
    
    -- Categories to track
    categories = {
        stun = {enabled = true, color = {r=1, g=0, b=0}, icon = 'Interface\\Icons\\Spell_Holy_Silence'},
        incap = {enabled = true, color = {r=1, g=0.5, b=0}, icon = 'Interface\\Icons\\Spell_Sleep'},
        disorient = {enabled = true, color = {r=1, g=1, b=0}, icon = 'Interface\\Icons\\Spell_Shadow_Charm'},
        fear = {enabled = true, color = {r=0.5, g=0, b=1}, icon = 'Interface\\Icons\\Spell_Shadow_Fear'},
        charm = {enabled = false, color = {r=1, g=0, b=1}, icon = 'Interface\\Icons\\Spell_Shadow_Charm'},
        knockout = {enabled = true, color = {r=0.8, g=0.4, b=0}, icon = 'Interface\\Icons\\Spell_Shaman_Stormstrike'},
        freeze = {enabled = true, color = {r=0, g=1, b=1}, icon = 'Interface\\Icons\\Spell_Frost_FrostShock'},
        banish = {enabled = false, color = {r=0.6, g=0.6, b=0.6}, icon = 'Interface\\Icons\\Spell_Shadow_Cripple'},
        cyclone = {enabled = false, color = {r=0, g=1, b=0}, icon = 'Interface\\Icons\\Spell_Nature_Cyclone'}
    },
    
    -- Warning settings
    warnings = {
        immuneWarning = true,
        immuneColor = {r=1, g=0, b=0, a=0.8},
        halfDRWarning = true,
        halfDRColor = {r=1, g=1, b=0, a=0.6},
        audioAlerts = false,
        immuneSound = 'Interface\\AddOns\\LibArenaTools\\Media\\Sounds\\Immune.ogg'
    },
    
    -- Timeline settings
    showTimeline = true,
    timelineHeight = 3,
    timelineWidth = 100,
    showTimelineText = true
}

-- DR Categories from DRList
local DRList = LibStub('DRList-1.0')
```

#### Core Methods

```lua
function ArenaDRTracker:Update(event, ...)
    if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        self:ProcessCombatEvent(...)
    elseif event == 'ARENA_OPPONENT_UPDATE' then
        self:RefreshAllDRData()
    end
end

function ArenaDRTracker:ProcessCombatEvent(timestamp, subevent, ...)
    if subevent == 'SPELL_AURA_APPLIED' or subevent == 'SPELL_AURA_REFRESH' then
        local sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
              destGUID, destName, destFlags, destRaidFlags,
              spellId, spellName, spellSchool, auraType = ...
              
        if self:IsArenaUnit(destName) then
            self:ProcessDRApplication(destName, spellId, auraType, timestamp)
        end
    elseif subevent == 'SPELL_AURA_REMOVED' then
        local sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
              destGUID, destName, destFlags, destRaidFlags,
              spellId, spellName, spellSchool, auraType = ...
              
        if self:IsArenaUnit(destName) then
            self:ProcessDRRemoval(destName, spellId, auraType, timestamp)
        end
    end
end

function ArenaDRTracker:ProcessDRApplication(unit, spellId, auraType, timestamp)
    local drCategory = DRList:GetCategoryBySpellID(spellId)
    if not drCategory then return end
    
    -- Update DR data
    local drData = self:GetDRData(unit, drCategory)
    drData.applications = drData.applications + 1
    drData.lastApplication = timestamp
    drData.reduction = self:CalculateDRReduction(drData.applications)
    drData.nextReduction = self:CalculateDRReduction(drData.applications + 1)
    drData.isImmune = drData.reduction >= 1.0
    
    -- Set reset timer (18 seconds)
    drData.resetTime = timestamp + 18
    
    -- Update display
    self:UpdateDRDisplay(unit, drCategory, drData)
    
    -- Handle warnings
    if drData.isImmune and self.db.warnings.immuneWarning then
        self:ShowImmuneWarning(unit, drCategory)
    elseif drData.reduction >= 0.5 and self.db.warnings.halfDRWarning then
        self:ShowHalfDRWarning(unit, drCategory)
    end
    
    -- Schedule reset
    self:ScheduleDRReset(unit, drCategory, drData.resetTime)
end

function ArenaDRTracker:CalculateDRReduction(applications)
    if applications <= 1 then
        return 0 -- No reduction on first application
    elseif applications == 2 then
        return 0.5 -- 50% reduction on second
    elseif applications == 3 then
        return 0.75 -- 75% reduction on third
    else
        return 1.0 -- Immune on fourth and beyond
    end
end

function ArenaDRTracker:UpdateDRDisplay(unit, category, drData)
    local frame = self.__owner
    if not frame or not frame.ArenaDRTracker then return end
    
    local drElement = frame.ArenaDRTracker
    
    if self.db.displayMode == 'bars' or self.db.displayMode == 'both' then
        self:UpdateDRBar(drElement, category, drData)
    end
    
    if self.db.displayMode == 'icons' or self.db.displayMode == 'both' then
        self:UpdateDRIcon(drElement, category, drData)
    end
    
    if self.db.showTimeline then
        self:UpdateDRTimeline(drElement, category, drData)
    end
end

function ArenaDRTracker:UpdateDRBar(drElement, category, drData)
    local bar = drElement.bars[category]
    if not bar then
        bar = self:CreateDRBar(drElement, category)
        drElement.bars[category] = bar
    end
    
    -- Update bar fill based on DR level
    local fillPercent = 1.0 - drData.reduction
    bar.fill:SetWidth(self.db.barWidth * fillPercent)
    
    -- Update color based on DR level
    local categoryConfig = self.db.categories[category]
    if drData.isImmune then
        bar.fill:SetColorTexture(1, 0, 0, 0.8) -- Red for immune
    elseif drData.reduction >= 0.5 then
        bar.fill:SetColorTexture(1, 1, 0, 0.8) -- Yellow for half DR
    else
        bar.fill:SetColorTexture(
            categoryConfig.color.r,
            categoryConfig.color.g,
            categoryConfig.color.b,
            0.8
        )
    end
    
    -- Update text
    if self.db.showBarText then
        local reductionText = string.format("%.0f%%", drData.reduction * 100)
        if drData.isImmune then
            reductionText = "IMMUNE"
        end
        bar.text:SetText(reductionText)
    end
    
    -- Show reset timer
    if drData.resetTime > GetTime() then
        local remaining = drData.resetTime - GetTime()
        bar.timer:SetText(string.format("%.1f", remaining))
        bar.timer:Show()
        
        -- Start reset timer
        self:StartResetTimer(bar, drData.resetTime)
    else
        bar.timer:Hide()
    end
    
    bar:Show()
end

function ArenaDRTracker:ShowImmuneWarning(unit, category)
    local frame = self.__owner
    if not frame then return end
    
    -- Flash the frame
    UIFrameFlash(frame, 0.5, 0.5, 1, false, 0, 0)
    
    -- Show immune indicator
    if frame.ArenaDRTracker.immuneIndicator then
        frame.ArenaDRTracker.immuneIndicator:Show()
        frame.ArenaDRTracker.immuneIndicator.fadeOut:Play()
    end
    
    -- Play sound if enabled
    if self.db.warnings.audioAlerts and self.db.warnings.immuneSound then
        PlaySoundFile(self.db.warnings.immuneSound)
    end
end
```

### 1.3 ArenaTargetCalling Element

**Purpose**: Advanced target calling and coordination system with priority management.

**File**: `Elements/ArenaTargetCalling.lua`

#### Specification

```lua
---@class oUF.ArenaTargetCalling : oUF.Element
local ArenaTargetCalling = {}

ArenaTargetCalling.elementName = 'ArenaTargetCalling'
ArenaTargetCalling.priority = 8
ArenaTargetCalling.events = {
    'PLAYER_TARGET_CHANGED',
    'PLAYER_FOCUS_CHANGED',
    'PARTY_MEMBER_TARGET_CHANGED',
    'ARENA_OPPONENT_UPDATE'
}

-- Default configuration
ArenaTargetCalling.defaults = {
    enabled = true,
    
    -- Highlight settings
    targetHighlight = {
        enabled = true,
        color = {r=1, g=0, b=0, a=0.8},
        size = 2,
        style = 'border' -- 'border', 'glow', 'overlay'
    },
    
    focusHighlight = {
        enabled = true,
        color = {r=1, g=1, b=0, a=0.8},
        size = 2,
        style = 'border'
    },
    
    -- Priority system
    prioritySystem = {
        enabled = true,
        showPriorityNumbers = true,
        enableKeybinds = true,
        keybinds = {
            setPriorityKill = 'CTRL-1',
            setPriorityCC = 'CTRL-2',
            setPriorityMonitor = 'CTRL-3',
            clearPriority = 'CTRL-0'
        },
        colors = {
            kill = {r=1, g=0, b=0, a=0.9},      -- Red
            cc = {r=1, g=1, b=0, a=0.9},        -- Yellow  
            monitor = {r=0, g=1, b=0, a=0.9},   -- Green
            none = {r=0.5, g=0.5, b=0.5, a=0.5} -- Gray
        },
        icons = {
            kill = 'Interface\\Icons\\Ability_Dualwield',
            cc = 'Interface\\Icons\\Spell_Frost_ChainsOfIce',
            monitor = 'Interface\\Icons\\Spell_Shadow_MindSteal'
        }
    },
    
    -- Team coordination
    coordination = {
        announceTargets = false,
        announceSwaps = true,
        announcePriorities = true,
        channel = 'PARTY', -- 'PARTY', 'RAID', 'SAY'
        throttle = 2 -- Minimum seconds between announcements
    },
    
    -- Visual indicators
    indicators = {
        showTeamTargets = true,
        showTeamFocus = true,
        teamTargetColor = {r=0.8, g=0.4, b=0.4, a=0.7},
        teamFocusColor = {r=0.8, g=0.8, b=0.4, a=0.7}
    }
}
```

#### Core Methods

```lua
function ArenaTargetCalling:Update(event, ...)
    if event == 'PLAYER_TARGET_CHANGED' then
        self:UpdatePlayerTarget()
    elseif event == 'PLAYER_FOCUS_CHANGED' then
        self:UpdatePlayerFocus()
    elseif event == 'PARTY_MEMBER_TARGET_CHANGED' then
        self:UpdatePartyTargets()
    elseif event == 'ARENA_OPPONENT_UPDATE' then
        self:RefreshAllTargets()
    end
end

function ArenaTargetCalling:UpdatePlayerTarget()
    local targetUnit = UnitExists('target') and UnitGUID('target')
    local previousTarget = self.playerTarget
    
    self.playerTarget = targetUnit
    
    -- Update target highlights
    self:UpdateTargetHighlights()
    
    -- Announce target swap if enabled
    if targetUnit and targetUnit ~= previousTarget then
        if self.db.coordination.announceSwaps then
            self:AnnounceTargetSwap(targetUnit)
        end
    end
end

function ArenaTargetCalling:UpdateTargetHighlights()
    for i = 1, 5 do
        local frame = LibArenaTools:GetArenaFrame(i)
        if frame then
            local unitGUID = UnitGUID('arena' .. i)
            
            -- Player target highlight
            local isPlayerTarget = (unitGUID == self.playerTarget)
            self:SetTargetHighlight(frame, isPlayerTarget)
            
            -- Player focus highlight  
            local isPlayerFocus = (unitGUID == self.playerFocus)
            self:SetFocusHighlight(frame, isPlayerFocus)
            
            -- Team target indicators
            if self.db.indicators.showTeamTargets then
                local teamTargetCount = self:GetTeamTargetCount(unitGUID)
                self:SetTeamTargetIndicator(frame, teamTargetCount)
            end
        end
    end
end

function ArenaTargetCalling:SetTargetHighlight(frame, highlighted)
    if not frame.ArenaTargetCalling then return end
    
    local highlight = frame.ArenaTargetCalling.targetHighlight
    
    if highlighted and self.db.targetHighlight.enabled then
        local config = self.db.targetHighlight
        
        if config.style == 'border' then
            highlight.border:Show()
            highlight.border:SetBackdropBorderColor(
                config.color.r,
                config.color.g,
                config.color.b,
                config.color.a
            )
        elseif config.style == 'glow' then
            LibCustomGlow.PixelGlow_Start(frame, {
                config.color.r,
                config.color.g,
                config.color.b,
                config.color.a
            })
        elseif config.style == 'overlay' then
            highlight.overlay:Show()
            highlight.overlay:SetColorTexture(
                config.color.r,
                config.color.g,
                config.color.b,
                config.color.a
            )
        end
    else
        highlight.border:Hide()
        highlight.overlay:Hide()
        LibCustomGlow.PixelGlow_Stop(frame)
    end
end

function ArenaTargetCalling:SetPriority(unit, priority)
    if not self.db.prioritySystem.enabled then return end
    
    -- Update priority data
    self.priorities[unit] = priority
    
    -- Update visual priority indicator
    local frame = LibArenaTools:GetArenaFrameByUnit(unit)
    if frame then
        self:UpdatePriorityDisplay(frame, priority)
    end
    
    -- Announce priority change
    if self.db.coordination.announcePriorities then
        self:AnnouncePriority(unit, priority)
    end
    
    -- Fire event for other systems
    LibArenaTools:FireEvent('ARENA_PRIORITY_CHANGED', unit, priority)
end

function ArenaTargetCalling:UpdatePriorityDisplay(frame, priority)
    if not frame.ArenaTargetCalling then return end
    
    local priorityElement = frame.ArenaTargetCalling.priority
    local config = self.db.prioritySystem
    
    if priority and priority ~= 'none' then
        -- Show priority indicator
        priorityElement.icon:SetTexture(config.icons[priority])
        priorityElement.background:SetColorTexture(
            config.colors[priority].r,
            config.colors[priority].g,
            config.colors[priority].b,
            config.colors[priority].a
        )
        
        -- Show priority number
        if config.showPriorityNumbers then
            local priorityNumber = priority == 'kill' and '1' or 
                                 priority == 'cc' and '2' or
                                 priority == 'monitor' and '3' or ''
            priorityElement.text:SetText(priorityNumber)
            priorityElement.text:Show()
        else
            priorityElement.text:Hide()
        end
        
        priorityElement:Show()
    else
        priorityElement:Hide()
    end
end

function ArenaTargetCalling:AnnounceTargetSwap(targetGUID)
    if not self.db.coordination.announceSwaps then return end
    
    -- Throttle announcements
    local now = GetTime()
    if (now - (self.lastAnnouncement or 0)) < self.db.coordination.throttle then
        return
    end
    
    local targetName = self:GetUnitNameByGUID(targetGUID)
    if targetName then
        local message = string.format("Targeting: %s", targetName)
        self:SendMessage(message)
        self.lastAnnouncement = now
    end
end

function ArenaTargetCalling:AnnouncePriority(unit, priority)
    if not self.db.coordination.announcePriorities then return end
    
    local unitName = UnitName(unit) or unit
    local priorityText = priority == 'kill' and 'KILL TARGET' or
                        priority == 'cc' and 'CC TARGET' or  
                        priority == 'monitor' and 'MONITOR' or
                        'NO PRIORITY'
                        
    local message = string.format("%s: %s", unitName, priorityText)
    self:SendMessage(message)
end

function ArenaTargetCalling:SetupKeybinds()
    if not self.db.prioritySystem.enableKeybinds then return end
    
    local keybinds = self.db.prioritySystem.keybinds
    
    -- Register keybinds for priority setting
    for priority, keybind in pairs(keybinds) do
        if priority ~= 'clearPriority' then
            self:RegisterKeybind(keybind, function()
                local targetUnit = UnitExists('target') and 'target'
                if targetUnit and self:IsArenaUnit(targetUnit) then
                    self:SetPriority(targetUnit, priority)
                end
            end)
        end
    end
    
    -- Clear priority keybind
    if keybinds.clearPriority then
        self:RegisterKeybind(keybinds.clearPriority, function()
            local targetUnit = UnitExists('target') and 'target'
            if targetUnit and self:IsArenaUnit(targetUnit) then
                self:SetPriority(targetUnit, 'none')
            end
        end)
    end
end
```

### 1.4 ArenaInterrupts Element

**Purpose**: Intelligent interrupt coordination and cast tracking system.

**File**: `Elements/ArenaInterrupts.lua`

#### Specification

```lua
---@class oUF.ArenaInterrupts : oUF.Element
local ArenaInterrupts = {}

ArenaInterrupts.elementName = 'ArenaInterrupts'
ArenaInterrupts.priority = 7
ArenaInterrupts.events = {
    'UNIT_SPELLCAST_START',
    'UNIT_SPELLCAST_STOP',
    'UNIT_SPELLCAST_SUCCEEDED',
    'UNIT_SPELLCAST_INTERRUPTED',
    'UNIT_SPELLCAST_FAILED',
    'SPELL_UPDATE_COOLDOWN'
}

-- Default configuration
ArenaInterrupts.defaults = {
    enabled = true,
    
    -- Cast tracking
    trackAllCasts = true,
    highlightInterruptible = true,
    showCastPriority = true,
    
    -- Interrupt coordination
    coordination = {
        enabled = true,
        announceInterrupts = true,
        announceOpportunities = false,
        suggestRotation = true,
        channel = 'PARTY'
    },
    
    -- Visual settings
    castBar = {
        enabled = true,
        height = 4,
        width = 100,
        color = {r=1, g=1, b=0, a=0.8},
        interruptibleColor = {r=1, g=0, b=0, a=0.8},
        nonInterruptibleColor = {r=0.5, g=0.5, b=0.5, a=0.8}
    },
    
    -- Priority system
    spellPriorities = {
        heal = 5,           -- Healing spells (highest priority)
        resurrect = 5,      -- Resurrection spells
        cc = 4,             -- Crowd control
        damage = 3,         -- Damage spells
        buff = 2,           -- Buffs/utility
        channel = 3,        -- Channeled abilities
        default = 1         -- Unknown spells
    },
    
    -- Opportunity detection
    opportunities = {
        showWindow = true,
        windowColor = {r=0, g=1, b=0, a=0.8},
        playSound = false,
        soundFile = 'Interface\\AddOns\\LibArenaTools\\Media\\Sounds\\InterruptWindow.ogg'
    },
    
    -- Team interrupt tracking
    teamTracking = {
        enabled = true,
        trackCooldowns = true,
        suggestOptimal = true,
        showAvailable = true
    }
}
```

### 1.5 Additional Elements (Summary)

**ArenaSpecIcon Element**: Enhanced specialization detection with threat assessment and role identification.

**ArenaPvPTrinket Element**: PvP trinket tracking with immunity duration and vulnerability windows.

**ArenaSkillHistory Element**: Ability usage tracking with pattern recognition and strategic analysis.

**ArenaAuraWatch Element**: Important aura tracking with customizable watch lists and alert systems.

**ArenaPreparation Element**: Arena preparation phase enhancements with team composition analysis.

---

## 2. Element Integration Framework

### 2.1 Element Registry System

```lua
---@class LibArenaTools.ElementRegistry
local ElementRegistry = {
    registeredElements = {},
    elementPriorities = {},
    enabledElements = {}
}

function ElementRegistry:RegisterElement(name, elementTable)
    -- Validate element structure
    self:ValidateElement(elementTable)
    
    -- Register with internal registry
    self.registeredElements[name] = elementTable
    self.elementPriorities[name] = elementTable.priority or 0
    
    -- Register with oUF
    oUF:AddElement(name, elementTable.Update, elementTable.Enable, elementTable.Disable)
    
    -- Add to configuration system
    LibArenaTools.ConfigManager:AddElementConfig(name, elementTable.defaults)
    
    -- Fire registration event
    LibArenaTools:FireEvent('ELEMENT_REGISTERED', name, elementTable)
end

function ElementRegistry:ValidateElement(elementTable)
    local required = {'elementName', 'Update', 'Enable', 'Disable', 'defaults'}
    
    for _, field in ipairs(required) do
        if not elementTable[field] then
            error(string.format("Element missing required field: %s", field))
        end
    end
end
```

### 2.2 Performance Integration

```lua
-- Performance monitoring for elements
local function CreatePerformanceWrapper(elementName, originalUpdate)
    return function(self, ...)
        local startTime = debugprofilestop()
        
        local success, result = pcall(originalUpdate, self, ...)
        
        local endTime = debugprofilestop()
        local duration = endTime - startTime
        
        LibArenaTools.PerformanceMonitor:RecordUpdateTime(elementName, duration)
        
        if not success then
            LibArenaTools:HandleElementError(elementName, result)
        end
        
        return result
    end
end
```

### 2.3 Configuration Integration

Each element automatically integrates with the configuration system:

```lua
-- Auto-generated configuration options
function ElementRegistry:BuildElementOptions(elementName)
    local element = self.registeredElements[elementName]
    if not element then return {} end
    
    local options = {
        type = 'group',
        name = element.displayName or elementName,
        desc = element.description or ('Configuration for ' .. elementName),
        args = {
            enabled = {
                type = 'toggle',
                name = 'Enable',
                desc = 'Enable/disable this element',
                get = function() return LibArenaTools.db.elements[elementName].enabled end,
                set = function(_, value)
                    LibArenaTools.db.elements[elementName].enabled = value
                    LibArenaTools:ToggleElement(elementName, value)
                end,
                order = 1
            }
        }
    }
    
    -- Add element-specific options
    if element.GetConfigOptions then
        local elementOptions = element:GetConfigOptions()
        for key, option in pairs(elementOptions) do
            options.args[key] = option
        end
    end
    
    return options
end
```

---

## 3. Implementation Guidelines

### 3.1 Element Development Checklist

When creating a new arena element:

- [ ] Follow oUF element pattern with Update, Enable, Disable functions
- [ ] Include comprehensive defaults configuration
- [ ] Implement performance monitoring hooks
- [ ] Add proper error handling with pcall wrapping
- [ ] Include theme integration support
- [ ] Add configuration options interface
- [ ] Implement proper event registration/cleanup
- [ ] Add unit tests for core functionality
- [ ] Include integration with LibArenaTools cache system
- [ ] Document all public methods and configuration options

### 3.2 Performance Requirements

All arena elements must meet these performance standards:

- **Update Time**: <1ms average update time per element
- **Memory Usage**: <1MB memory footprint per element
- **Event Efficiency**: Minimal event registration, proper cleanup
- **Cache Utilization**: Use LibArenaTools cache system for expensive operations
- **Error Handling**: Graceful failure without affecting other elements

### 3.3 Configuration Standards

Element configuration must follow these patterns:

- **Hierarchical Structure**: Use nested tables for logical grouping
- **Sensible Defaults**: Work well out-of-the-box without configuration
- **Validation**: Include type checking and range validation
- **Documentation**: Include descriptions for all options
- **Theme Integration**: Support SpartanUI theme system

This specification provides the foundation for implementing all arena elements with consistent interfaces, performance characteristics, and integration patterns.