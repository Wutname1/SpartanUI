# SpartanUI Integration Specifications for LibArenaTools

## Overview

This document provides detailed specifications for integrating LibArenaTools with the SpartanUI ecosystem. The integration ensures seamless operation with existing SpartanUI modules, theme synchronization, configuration inheritance, and position coordination.

**Integration Goals:**
- **Seamless Operation**: LibArenaTools feels like a native SpartanUI component
- **Theme Synchronization**: Perfect integration with all SpartanUI themes
- **Configuration Unity**: Unified configuration experience within SpartanUI options
- **Position Coordination**: Intelligent positioning that avoids conflicts with other modules
- **Event Harmony**: Coordinated event handling with existing SpartanUI systems

---

## 1. Core SpartanUI Integration

### 1.1 Module Registration and Lifecycle

**File**: `LibArenaTools.lua`

```lua
---@class SUI.LibArenaTools : SUI.Module
local LibArenaTools = SUI:NewModule('LibArenaTools')
LibArenaTools.DisplayName = 'Arena Tools'
LibArenaTools.description = 'Advanced arena frames and tools for competitive PvP'

-- Module configuration following SpartanUI patterns
LibArenaTools.Config = {
    IsGroup = false,                    -- Not a group layout module
    Core = false,                      -- Not a core SUI module
    RequiredModules = {'UnitFrames'},  -- Depends on UnitFrames
    OptionalModules = {'Artwork'},     -- Enhanced by Artwork
    Dependencies = {                   -- External dependencies
        'oUF',
        'LibCooldownTracker-1.0',
        'DRList-1.0'
    }
}

-- Integration with SpartanUI lifecycle
function LibArenaTools:OnInitialize()
    -- Initialize after required modules
    if not SUI:IsModuleEnabled('UnitFrames') then
        self:SetEnabledState(false)
        return
    end
    
    -- Create core components
    self:InitializeCore()
    
    -- Register with UnitFrames system
    SUI.UF:RegisterArenaProvider(self)
    
    -- Setup SpartanUI integration
    self:InitializeSpartanUIIntegration()
    
    -- Initialize database with SpartanUI patterns
    self:InitializeDatabase()
end

function LibArenaTools:OnEnable()
    -- Register SpartanUI events
    self:RegisterEvent('SUI_THEME_CHANGED', 'OnThemeChanged')
    self:RegisterEvent('SUI_PROFILE_CHANGED', 'OnProfileChanged')
    self:RegisterEvent('SUI_MODULE_ENABLED', 'OnModuleStateChanged')
    
    -- Enable arena elements
    self:EnableArenaElements()
    
    -- Apply current theme
    self:ApplyCurrentTheme()
    
    -- Setup positioning
    self:UpdatePositioning()
end

function LibArenaTools:OnDisable()
    -- Cleanup arena frames
    self:DisableArenaElements()
    
    -- Unregister events
    self:UnregisterAllEvents()
    
    -- Hide all frames
    self:HideAllFrames()
end

-- SpartanUI profile integration
function LibArenaTools:OnProfileChanged(event, newProfile)
    -- Reload configuration for new profile
    self:ReloadConfiguration()
    
    -- Reapply theme
    self:ApplyCurrentTheme()
    
    -- Update positioning
    self:UpdatePositioning()
end
```

### 1.2 Database Integration

**File**: `Core/ConfigManager.lua`

```lua
---@class LibArenaTools.ConfigManager
local ConfigManager = {}

-- SpartanUI database integration
function ConfigManager:InitializeDatabase()
    -- Use SUI.DB pattern for consistent profile handling
    local defaults = self:GetConfigDefaults()
    
    -- Register with SpartanUI database system
    self.DB = SUI.DB:RegisterModule('LibArenaTools', defaults)
    
    -- Create easy access reference
    LibArenaTools.db = self.DB.profile
    
    -- Setup profile callbacks
    self.DB.RegisterCallback(self, 'OnProfileChanged', 'ProfileChanged')
    self.DB.RegisterCallback(self, 'OnProfileCopied', 'ProfileChanged')
    self.DB.RegisterCallback(self, 'OnProfileReset', 'ProfileChanged')
end

-- Configuration defaults following SpartanUI patterns
function ConfigManager:GetConfigDefaults()
    return {
        profile = {
            -- General settings
            enabled = true,
            mode = 'enhanced', -- 'enhanced', 'basic', 'replace'
            
            -- Integration settings
            integration = {
                useSpartanUITheme = true,
                useArtworkPositions = true,
                coordinateWithModules = true,
                inheritProfileSettings = true
            },
            
            -- Position coordination
            positioning = {
                mode = 'auto', -- 'auto', 'manual', 'artwork'
                anchor = 'RIGHT',
                anchorFrame = 'UIParent',
                anchorPoint = 'RIGHT',
                offsetX = -50,
                offsetY = 0,
                
                -- Conflict resolution
                avoidConflicts = true,
                conflictOffset = 10,
                preferredSide = 'right' -- 'left', 'right', 'top', 'bottom'
            },
            
            -- Element configurations
            elements = {
                ArenaCooldowns = {
                    enabled = true,
                    -- Element-specific config
                },
                ArenaDRTracker = {
                    enabled = true,
                    -- Element-specific config
                },
                -- ... other elements
            },
            
            -- Theme integration
            theme = {
                mode = 'automatic', -- 'automatic', 'override', 'custom'
                customTheme = nil,
                overrides = {
                    -- Theme-specific overrides
                }
            }
        }
    }
end
```

---

## 2. Theme Synchronization System

### 2.1 Theme Integration Architecture

**File**: `Integration/ThemeSync.lua`

```lua
---@class LibArenaTools.ThemeSync
local ThemeSync = {
    currentTheme = nil,
    themeMappings = {},
    themeOverrides = {},
    lastThemeUpdate = 0
}

function ThemeSync:Initialize()
    -- Build theme mappings for all SpartanUI themes
    self:BuildThemeMappings()
    
    -- Register for theme change events
    self:RegisterThemeEvents()
    
    -- Apply current theme
    local currentTheme = SUI.DB.Artwork.Style or 'Classic'
    self:ApplyTheme(currentTheme)
end

function ThemeSync:BuildThemeMappings()
    -- Map each SpartanUI theme to arena-specific styling
    self.themeMappings = {
        ['Classic'] = {
            healthBar = {
                texture = 'Interface\\TargetingFrame\\UI-StatusBar',
                colorMode = 'class', -- 'class', 'reaction', 'custom'
                customColor = {r=0, g=1, b=0, a=1}
            },
            powerBar = {
                texture = 'Interface\\TargetingFrame\\UI-StatusBar',
                colorMode = 'power',
                height = 5
            },
            background = {
                texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
                color = {r=0, g=0, b=0, a=0.8},
                borderTexture = 'Interface\\Tooltips\\UI-Tooltip-Border',
                borderColor = {r=1, g=1, b=1, a=1},
                borderSize = 1
            },
            font = {
                family = 'Fonts\\FRIZQT__.TTF',
                size = 12,
                flags = 'OUTLINE',
                color = {r=1, g=1, b=1, a=1}
            },
            spacing = {
                frameSpacing = 10,
                elementSpacing = 2,
                padding = {left=4, right=4, top=2, bottom=2}
            }
        },
        
        ['War'] = {
            healthBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2',
                colorMode = 'class',
                gradient = {
                    enabled = true,
                    orientation = 'HORIZONTAL'
                }
            },
            powerBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2',
                colorMode = 'power',
                height = 4
            },
            background = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\backgrounds\\WarBackground',
                color = {r=0.1, g=0, b=0, a=0.9},
                borderTexture = 'Interface\\AddOns\\SpartanUI\\images\\borders\\WarBorder',
                borderColor = {r=0.8, g=0, b=0, a=1},
                borderSize = 2
            },
            font = {
                family = 'Interface\\AddOns\\SpartanUI\\fonts\\Continuum.ttf',
                size = 12,
                flags = 'OUTLINE',
                color = {r=1, g=0.8, b=0.8, a=1}
            },
            spacing = {
                frameSpacing = 8,
                elementSpacing = 1,
                padding = {left=6, right=6, top=3, bottom=3}
            }
        },
        
        ['Fel'] = {
            healthBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Fel',
                colorMode = 'custom',
                customColor = {r=0.5, g=1, b=0.5, a=1},
                glow = {
                    enabled = true,
                    color = {r=0, g=1, b=0, a=0.8}
                }
            },
            powerBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Fel',
                colorMode = 'power',
                height = 4
            },
            background = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\backgrounds\\FelBackground',
                color = {r=0, g=0.2, b=0, a=0.9},
                borderTexture = 'Interface\\AddOns\\SpartanUI\\images\\borders\\FelBorder',
                borderColor = {r=0, g=1, b=0, a=1},
                borderSize = 1
            },
            font = {
                family = 'Interface\\AddOns\\SpartanUI\\fonts\\Fel.ttf',
                size = 11,
                flags = 'OUTLINE',
                color = {r=0.8, g=1, b=0.8, a=1}
            },
            effects = {
                enableGlow = true,
                enablePulse = true,
                glowColor = {r=0, g=1, b=0, a=0.6}
            }
        },
        
        ['Digital'] = {
            healthBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Digital',
                colorMode = 'class',
                scanlines = true
            },
            powerBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Digital',
                colorMode = 'power',
                height = 3,
                scanlines = true
            },
            background = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\backgrounds\\DigitalBackground',
                color = {r=0, g=0.1, b=0.2, a=0.9},
                borderTexture = 'Interface\\AddOns\\SpartanUI\\images\\borders\\DigitalBorder',
                borderColor = {r=0, g=0.8, b=1, a=1},
                borderSize = 1
            },
            font = {
                family = 'Interface\\AddOns\\SpartanUI\\fonts\\Digital.ttf',
                size = 10,
                flags = 'MONOCHROME',
                color = {r=0.8, g=0.9, b=1, a=1}
            },
            effects = {
                enableScanlines = true,
                digitalFlicker = true
            }
        },
        
        ['Minimal'] = {
            healthBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Minimal',
                colorMode = 'class',
                alpha = 0.9
            },
            powerBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Minimal',
                colorMode = 'power',
                height = 3,
                alpha = 0.8
            },
            background = {
                texture = nil, -- No background for minimal
                color = {r=0, g=0, b=0, a=0},
                borderTexture = nil,
                borderSize = 0
            },
            font = {
                family = 'Fonts\\ARIALN.TTF',
                size = 11,
                flags = '',
                color = {r=1, g=1, b=1, a=1}
            },
            spacing = {
                frameSpacing = 5,
                elementSpacing = 1,
                padding = {left=0, right=0, top=0, bottom=0}
            }
        },
        
        ['Tribal'] = {
            healthBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Tribal',
                colorMode = 'class',
                runic = true
            },
            powerBar = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Tribal',
                colorMode = 'power',
                height = 6,
                runic = true
            },
            background = {
                texture = 'Interface\\AddOns\\SpartanUI\\images\\backgrounds\\TribalBackground',
                color = {r=0.2, g=0.1, b=0, a=0.9},
                borderTexture = 'Interface\\AddOns\\SpartanUI\\images\\borders\\TribalBorder',
                borderColor = {r=0.8, g=0.6, b=0.4, a=1},
                borderSize = 3
            },
            font = {
                family = 'Interface\\AddOns\\SpartanUI\\fonts\\Tribal.ttf',
                size = 12,
                flags = 'OUTLINE',
                color = {r=1, g=0.9, b=0.7, a=1}
            },
            effects = {
                enableRunicEffects = true,
                tribalGlow = true
            }
        }
    }
end

function ThemeSync:ApplyTheme(themeName)
    if self.currentTheme == themeName and 
       (GetTime() - self.lastThemeUpdate) < 1 then
        return -- Avoid rapid theme changes
    end
    
    local themeData = self.themeMappings[themeName]
    if not themeData then
        LibArenaTools:Debug('Unknown theme: ' .. tostring(themeName))
        return
    end
    
    self.currentTheme = themeName
    self.lastThemeUpdate = GetTime()
    
    -- Apply to all arena frames
    self:ApplyThemeToFrames(themeData)
    
    -- Apply to all elements
    self:ApplyThemeToElements(themeData)
    
    -- Update configuration
    LibArenaTools.db.theme.currentTheme = themeName
    
    -- Fire theme change event
    LibArenaTools:FireEvent('ARENA_THEME_APPLIED', themeName, themeData)
end

function ThemeSync:ApplyThemeToFrames(themeData)
    for i = 1, 5 do
        local frame = LibArenaTools:GetArenaFrame(i)
        if frame then
            self:StyleFrame(frame, themeData)
        end
    end
end

function ThemeSync:StyleFrame(frame, themeData)
    -- Apply health bar styling
    if frame.Health and themeData.healthBar then
        local healthConfig = themeData.healthBar
        
        frame.Health:SetStatusBarTexture(healthConfig.texture)
        
        if healthConfig.colorMode == 'class' then
            frame.Health.colorClass = true
        elseif healthConfig.colorMode == 'custom' then
            frame.Health:SetStatusBarColor(
                healthConfig.customColor.r,
                healthConfig.customColor.g,
                healthConfig.customColor.b,
                healthConfig.customColor.a
            )
        end
        
        -- Apply gradient if enabled
        if healthConfig.gradient and healthConfig.gradient.enabled then
            frame.Health.colorSmooth = true
        end
        
        -- Apply alpha
        if healthConfig.alpha then
            frame.Health:SetAlpha(healthConfig.alpha)
        end
    end
    
    -- Apply power bar styling
    if frame.Power and themeData.powerBar then
        local powerConfig = themeData.powerBar
        
        frame.Power:SetStatusBarTexture(powerConfig.texture)
        frame.Power:SetHeight(powerConfig.height)
        
        if powerConfig.colorMode == 'power' then
            frame.Power.colorPower = true
        end
        
        if powerConfig.alpha then
            frame.Power:SetAlpha(powerConfig.alpha)
        end
    end
    
    -- Apply background and borders
    if themeData.background then
        local bgConfig = themeData.background
        
        if bgConfig.texture then
            frame:SetBackdrop({
                bgFile = bgConfig.texture,
                edgeFile = bgConfig.borderTexture,
                tile = false,
                tileSize = 0,
                edgeSize = bgConfig.borderSize or 0,
                insets = {left=0, right=0, top=0, bottom=0}
            })
            
            frame:SetBackdropColor(
                bgConfig.color.r,
                bgConfig.color.g,
                bgConfig.color.b,
                bgConfig.color.a
            )
            
            if bgConfig.borderTexture then
                frame:SetBackdropBorderColor(
                    bgConfig.borderColor.r,
                    bgConfig.borderColor.g,
                    bgConfig.borderColor.b,
                    bgConfig.borderColor.a
                )
            end
        end
    end
    
    -- Apply font styling
    if frame.Name and themeData.font then
        local fontConfig = themeData.font
        
        frame.Name:SetFont(
            fontConfig.family,
            fontConfig.size,
            fontConfig.flags
        )
        
        frame.Name:SetTextColor(
            fontConfig.color.r,
            fontConfig.color.g,
            fontConfig.color.b,
            fontConfig.color.a
        )
    end
    
    -- Apply special effects
    if themeData.effects then
        self:ApplySpecialEffects(frame, themeData.effects)
    end
end

function ThemeSync:ApplySpecialEffects(frame, effects)
    -- Glow effects
    if effects.enableGlow and LibCustomGlow then
        LibCustomGlow.PixelGlow_Start(frame, {
            effects.glowColor.r,
            effects.glowColor.g,
            effects.glowColor.b,
            effects.glowColor.a
        })
    end
    
    -- Scanline effects for Digital theme
    if effects.enableScanlines then
        self:ApplyScanlineEffect(frame)
    end
    
    -- Runic effects for Tribal theme
    if effects.enableRunicEffects then
        self:ApplyRunicEffect(frame)
    end
end

-- Theme change event handler
function ThemeSync:OnThemeChanged(event, newTheme)
    self:ApplyTheme(newTheme)
end
```

---

## 3. Position Coordination System

### 3.1 Position Management Architecture

**File**: `Integration/PositionManager.lua`

```lua
---@class LibArenaTools.PositionManager
local PositionManager = {
    basePositions = {},
    adjustedPositions = {},
    conflictResolution = true,
    moduleConflicts = {},
    lastPositionUpdate = 0
}

function PositionManager:Initialize()
    -- Load base positions from SpartanUI
    self:LoadSpartanUIPositions()
    
    -- Register for position events
    self:RegisterPositionEvents()
    
    -- Setup initial positioning
    self:CalculateOptimalPositions()
end

function PositionManager:LoadSpartanUIPositions()
    -- Get positions from current artwork style
    local artworkStyle = SUI.DB.Artwork.Style
    local styleData = SUI.UF.Style:Get(artworkStyle)
    
    if styleData and styleData.positions then
        -- Use artwork-defined positions if available
        if styleData.positions.arena then
            self.basePositions.arena = styleData.positions.arena
        end
        
        -- Store other frame positions for conflict detection
        self.basePositions.party = styleData.positions.party
        self.basePositions.target = styleData.positions.target
        self.basePositions.focus = styleData.positions.focus
        self.basePositions.boss = styleData.positions.boss
    else
        -- Use default positions
        self:LoadDefaultPositions()
    end
end

function PositionManager:LoadDefaultPositions()
    self.basePositions = {
        arena = 'RIGHT,UIParent,RIGHT,-50,0',
        party = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
        target = 'LEFT,SUI_UF_player,RIGHT,150,0',
        focus = 'BOTTOMLEFT,SUI_UF_target,TOP,0,30',
        boss = 'RIGHT,UIParent,RIGHT,-9,162'
    }
end

function PositionManager:CalculateOptimalPositions()
    if (GetTime() - self.lastPositionUpdate) < 1 then
        return -- Throttle position updates
    end
    
    local finalPositions = CopyTable(self.basePositions)
    
    if LibArenaTools.db.positioning.avoidConflicts then
        finalPositions = self:ResolvePositionConflicts(finalPositions)
    end
    
    self.adjustedPositions = finalPositions
    self:ApplyPositions()
    
    self.lastPositionUpdate = GetTime()
end

function PositionManager:ResolvePositionConflicts(positions)
    local conflicts = self:DetectConflicts(positions)
    local resolvedPositions = CopyTable(positions)
    
    for conflictType, conflictData in pairs(conflicts) do
        resolvedPositions = self:ResolveConflict(resolvedPositions, conflictType, conflictData)
    end
    
    return resolvedPositions
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
                frame = partyFrame,
                bounds = partyBounds,
                suggestedOffset = self:CalculateAvoidanceOffset(partyBounds, arenaBounds)
            }
        end
    end
    
    -- Check target frame conflicts
    local targetFrame = SUI.UF.Unit:Get('target')
    if targetFrame and targetFrame:IsShown() then
        local targetBounds = self:GetFrameBounds(targetFrame)
        local arenaBounds = self:GetPredictedBounds(positions.arena)
        
        if self:BoundsOverlap(targetBounds, arenaBounds) then
            conflicts.target = {
                severity = 'medium',
                frame = targetFrame,
                bounds = targetBounds,
                suggestedOffset = self:CalculateAvoidanceOffset(targetBounds, arenaBounds)
            }
        end
    end
    
    -- Check boss frame conflicts
    local bossFrame = SUI.UF.Unit:Get('boss')
    if bossFrame and bossFrame:IsShown() then
        local bossBounds = self:GetFrameBounds(bossFrame)
        local arenaBounds = self:GetPredictedBounds(positions.arena)
        
        if self:BoundsOverlap(bossBounds, arenaBounds) then
            conflicts.boss = {
                severity = 'high',
                frame = bossFrame,
                bounds = bossBounds,
                suggestedOffset = self:CalculateAvoidanceOffset(bossBounds, arenaBounds)
            }
        end
    end
    
    return conflicts
end

function PositionManager:ResolveConflict(positions, conflictType, conflictData)
    local resolvedPositions = CopyTable(positions)
    local currentArenaPos = positions.arena
    
    -- Parse current arena position
    local anchor, anchorFrame, anchorPoint, x, y = strsplit(',', currentArenaPos)
    x, y = tonumber(x) or 0, tonumber(y) or 0
    
    -- Apply suggested offset
    local offset = conflictData.suggestedOffset
    local newX = x + offset.x
    local newY = y + offset.y
    
    -- Construct new position string
    resolvedPositions.arena = string.format('%s,%s,%s,%d,%d', 
        anchor, anchorFrame, anchorPoint, newX, newY)
    
    LibArenaTools:Debug('Resolved conflict with ' .. conflictType .. 
                       ': offset (' .. offset.x .. ', ' .. offset.y .. ')')
    
    return resolvedPositions
end

function PositionManager:CalculateAvoidanceOffset(conflictBounds, arenaBounds)
    local preferredSide = LibArenaTools.db.positioning.preferredSide
    local offsetDistance = LibArenaTools.db.positioning.conflictOffset
    
    local offset = {x = 0, y = 0}
    
    if preferredSide == 'right' then
        offset.x = conflictBounds.right - arenaBounds.left + offsetDistance
    elseif preferredSide == 'left' then
        offset.x = conflictBounds.left - arenaBounds.right - offsetDistance
    elseif preferredSide == 'top' then
        offset.y = conflictBounds.top - arenaBounds.bottom + offsetDistance
    elseif preferredSide == 'bottom' then
        offset.y = conflictBounds.bottom - arenaBounds.top - offsetDistance
    else
        -- Auto-detect best side
        local rightSpace = UIParent:GetWidth() - conflictBounds.right
        local leftSpace = conflictBounds.left
        local topSpace = conflictBounds.top
        local bottomSpace = UIParent:GetHeight() - conflictBounds.bottom
        
        local maxSpace = math.max(rightSpace, leftSpace, topSpace, bottomSpace)
        
        if maxSpace == rightSpace then
            offset.x = conflictBounds.right - arenaBounds.left + offsetDistance
        elseif maxSpace == leftSpace then
            offset.x = conflictBounds.left - arenaBounds.right - offsetDistance
        elseif maxSpace == topSpace then
            offset.y = conflictBounds.top - arenaBounds.bottom + offsetDistance
        else
            offset.y = conflictBounds.bottom - arenaBounds.top - offsetDistance
        end
    end
    
    return offset
end

function PositionManager:ApplyPositions()
    local arenaPosition = self.adjustedPositions.arena
    if not arenaPosition then return end
    
    local anchor, anchorFrame, anchorPoint, x, y = strsplit(',', arenaPosition)
    x, y = tonumber(x) or 0, tonumber(y) or 0
    
    -- Apply to arena frames
    for i = 1, 5 do
        local frame = LibArenaTools:GetArenaFrame(i)
        if frame then
            if i == 1 then
                -- First frame uses base position
                frame:ClearAllPoints()
                frame:SetPoint(anchor, anchorFrame, anchorPoint, x, y)
            else
                -- Subsequent frames stack vertically
                frame:ClearAllPoints()
                frame:SetPoint('TOP', LibArenaTools:GetArenaFrame(i-1), 'BOTTOM', 0, -10)
            end
        end
    end
end

-- Event handlers
function PositionManager:OnModuleEnabled(event, moduleName)
    if moduleName == 'Artwork' then
        -- Reload positions when Artwork is enabled
        self:LoadSpartanUIPositions()
        self:CalculateOptimalPositions()
    elseif moduleName == 'UnitFrames' then
        -- Recheck conflicts when UnitFrames changes
        self:CalculateOptimalPositions()
    end
end

function PositionManager:OnArtworkStyleChanged(event, newStyle)
    -- Reload positions for new artwork style
    self:LoadSpartanUIPositions()
    self:CalculateOptimalPositions()
end
```

---

## 4. Configuration Integration System

### 4.1 Options Panel Integration

**File**: `Integration/ConfigBridge.lua`

```lua
---@class LibArenaTools.ConfigBridge
local ConfigBridge = {}

function ConfigBridge:Initialize()
    -- Add LibArenaTools options to SpartanUI config
    self:RegisterWithSpartanUIOptions()
    
    -- Setup configuration inheritance
    self:SetupConfigInheritance()
    
    -- Register for config events
    self:RegisterConfigEvents()
end

function ConfigBridge:RegisterWithSpartanUIOptions()
    local options = self:BuildSpartanUIOptions()
    
    -- Add to SpartanUI options system
    SUI.Options:AddModuleOptions('LibArenaTools', options)
end

function ConfigBridge:BuildSpartanUIOptions()
    return {
        type = 'group',
        name = 'Arena Tools',
        desc = 'Advanced arena frames and tools for competitive PvP',
        icon = 'Interface\\Icons\\Achievement_PVP_A_A',
        order = 70, -- Position after core modules
        args = {
            -- Header section
            header = {
                type = 'header',
                name = 'LibArenaTools - Advanced Arena Frames',
                order = 1
            },
            
            description = {
                type = 'description',
                name = 'LibArenaTools provides advanced arena frames with cooldown tracking, diminishing returns, target calling, and more. Designed to replace basic arena frames and provide superior functionality compared to GladiusEX.',
                order = 2
            },
            
            -- Main enable/disable
            enabled = {
                type = 'toggle',
                name = 'Enable Arena Tools',
                desc = 'Enable LibArenaTools enhanced arena frames',
                get = function() return LibArenaTools.db.enabled end,
                set = function(_, value)
                    LibArenaTools.db.enabled = value
                    LibArenaTools:SetEnabled(value)
                end,
                order = 3,
                width = 'full'
            },
            
            -- Mode selection
            mode = {
                type = 'select',
                name = 'Arena Tools Mode',
                desc = 'Select how LibArenaTools integrates with SpartanUI',
                values = {
                    enhanced = 'Enhanced - Full LibArenaTools features',
                    basic = 'Basic - Core features only',
                    replace = 'Replace - Replace default arena frames only'
                },
                get = function() return LibArenaTools.db.mode end,
                set = function(_, value)
                    LibArenaTools.db.mode = value
                    LibArenaTools:SetMode(value)
                end,
                order = 4,
                disabled = function() return not LibArenaTools.db.enabled end
            },
            
            -- Quick setup section
            quickSetup = {
                type = 'group',
                name = 'Quick Setup',
                desc = 'Quickly configure LibArenaTools for your playstyle',
                inline = true,
                order = 5,
                disabled = function() return not LibArenaTools.db.enabled end,
                args = {
                    healer = {
                        type = 'execute',
                        name = 'Healer Setup',
                        desc = 'Configure optimal settings for healer playstyle\n\n• Focus on interrupt and defensive cooldowns\n• Enhanced DR tracking for CC effects\n• Target calling optimized for healing',
                        func = function() self:ApplyHealerPreset() end,
                        order = 1
                    },
                    dps = {
                        type = 'execute',
                        name = 'DPS Setup', 
                        desc = 'Configure optimal settings for DPS playstyle\n\n• All cooldown categories enabled\n• Aggressive target calling features\n• Interrupt coordination for damage windows',
                        func = function() self:ApplyDPSPreset() end,
                        order = 2
                    },
                    competitive = {
                        type = 'execute',
                        name = 'Competitive Setup',
                        desc = 'Maximum information for competitive play\n\n• All features enabled\n• Enhanced analytics and tracking\n• Full team coordination features',
                        func = function() self:ApplyCompetitivePreset() end,
                        order = 3
                    }
                }
            },
            
            -- Integration settings
            integration = {
                type = 'group',
                name = 'SpartanUI Integration',
                desc = 'Control how LibArenaTools integrates with SpartanUI',
                order = 10,
                disabled = function() return not LibArenaTools.db.enabled end,
                args = {
                    themeSync = {
                        type = 'toggle',
                        name = 'Use SpartanUI Theme',
                        desc = 'Automatically apply SpartanUI theme to arena frames',
                        get = function() return LibArenaTools.db.integration.useSpartanUITheme end,
                        set = function(_, value)
                            LibArenaTools.db.integration.useSpartanUITheme = value
                            if value then
                                LibArenaTools.ThemeSync:ApplyCurrentTheme()
                            end
                        end,
                        order = 1
                    },
                    
                    artworkPositions = {
                        type = 'toggle',
                        name = 'Use Artwork Positions',
                        desc = 'Use positions defined by current artwork style',
                        get = function() return LibArenaTools.db.integration.useArtworkPositions end,
                        set = function(_, value)
                            LibArenaTools.db.integration.useArtworkPositions = value
                            LibArenaTools.PositionManager:UpdatePositioning()
                        end,
                        order = 2
                    },
                    
                    avoidConflicts = {
                        type = 'toggle',
                        name = 'Avoid Module Conflicts',
                        desc = 'Automatically adjust positions to avoid conflicts with other modules',
                        get = function() return LibArenaTools.db.positioning.avoidConflicts end,
                        set = function(_, value)
                            LibArenaTools.db.positioning.avoidConflicts = value
                            LibArenaTools.PositionManager:CalculateOptimalPositions()
                        end,
                        order = 3
                    }
                }
            },
            
            -- Element configuration
            elements = self:BuildElementOptions(),
            
            -- Positioning options
            positioning = self:BuildPositionOptions(),
            
            -- Migration tools
            migration = self:BuildMigrationOptions(),
            
            -- Advanced settings
            advanced = self:BuildAdvancedOptions()
        }
    }
end

function ConfigBridge:BuildElementOptions()
    local elementOptions = {
        type = 'group',
        name = 'Arena Elements',
        desc = 'Configure individual arena elements',
        order = 20,
        disabled = function() return not LibArenaTools.db.enabled end,
        args = {}
    }
    
    -- Add options for each registered element
    local elementRegistry = LibArenaTools.ElementRegistry
    for elementName, element in pairs(elementRegistry.registeredElements) do
        elementOptions.args[elementName] = {
            type = 'group',
            name = element.displayName or elementName,
            desc = element.description or ('Configure ' .. elementName),
            order = element.priority or 0,
            args = self:BuildElementSpecificOptions(elementName, element)
        }
    end
    
    return elementOptions
end

function ConfigBridge:BuildElementSpecificOptions(elementName, element)
    local options = {
        enabled = {
            type = 'toggle',
            name = 'Enable',
            desc = 'Enable/disable this element',
            get = function() return LibArenaTools.db.elements[elementName].enabled end,
            set = function(_, value)
                LibArenaTools.db.elements[elementName].enabled = value
                LibArenaTools:ToggleElement(elementName, value)
            end,
            order = 1,
            width = 'full'
        }
    }
    
    -- Add element-specific options if available
    if element.GetConfigOptions then
        local elementOptions = element:GetConfigOptions()
        for key, option in pairs(elementOptions) do
            option.order = (option.order or 0) + 10
            options[key] = option
        end
    end
    
    return options
end

function ConfigBridge:ApplyHealerPreset()
    LibArenaTools.db.elements.ArenaCooldowns.categories.interrupt.enabled = true
    LibArenaTools.db.elements.ArenaCooldowns.categories.defensive.enabled = true
    LibArenaTools.db.elements.ArenaCooldowns.categories.offensive.enabled = false
    LibArenaTools.db.elements.ArenaCooldowns.categories.heal.enabled = true
    
    LibArenaTools.db.elements.ArenaDRTracker.categories.stun.enabled = true
    LibArenaTools.db.elements.ArenaDRTracker.categories.fear.enabled = true
    LibArenaTools.db.elements.ArenaDRTracker.categories.incap.enabled = true
    
    LibArenaTools.db.elements.ArenaTargetCalling.prioritySystem.enabled = true
    LibArenaTools.db.elements.ArenaTargetCalling.coordination.announceTargets = false
    
    LibArenaTools:RefreshAllElements()
    SUI:Print('Applied healer preset configuration')
end

function ConfigBridge:ApplyDPSPreset()
    -- Enable all cooldown categories for DPS
    for category, _ in pairs(LibArenaTools.db.elements.ArenaCooldowns.categories) do
        LibArenaTools.db.elements.ArenaCooldowns.categories[category].enabled = true
    end
    
    -- Enable most DR categories
    for category, _ in pairs(LibArenaTools.db.elements.ArenaDRTracker.categories) do
        LibArenaTools.db.elements.ArenaDRTracker.categories[category].enabled = true
    end
    
    LibArenaTools.db.elements.ArenaTargetCalling.coordination.announceSwaps = true
    LibArenaTools.db.elements.ArenaInterrupts.coordination.enabled = true
    
    LibArenaTools:RefreshAllElements()
    SUI:Print('Applied DPS preset configuration')
end

function ConfigBridge:ApplyCompetitivePreset()
    -- Enable everything for competitive play
    for elementName, elementConfig in pairs(LibArenaTools.db.elements) do
        elementConfig.enabled = true
        
        -- Enable all sub-features
        if elementConfig.categories then
            for category, _ in pairs(elementConfig.categories) do
                elementConfig.categories[category].enabled = true
            end
        end
        
        if elementConfig.coordination then
            elementConfig.coordination.enabled = true
        end
        
        if elementConfig.warnings then
            for warning, _ in pairs(elementConfig.warnings) do
                elementConfig.warnings[warning] = true
            end
        end
    end
    
    LibArenaTools:RefreshAllElements()
    SUI:Print('Applied competitive preset configuration')
end
```

---

## 5. Event Coordination System

### 5.1 Event Integration Architecture

**File**: `Integration/EventRelay.lua`

```lua
---@class LibArenaTools.EventRelay
local EventRelay = {
    suiEventHandlers = {},
    arenaEventHandlers = {},
    eventFilters = {}
}

function EventRelay:Initialize()
    -- Register for SpartanUI core events
    self:RegisterSpartanUIEvents()
    
    -- Setup event filtering and coordination
    self:SetupEventFilters()
    
    -- Initialize event relay system
    self:InitializeEventRelay()
end

function EventRelay:RegisterSpartanUIEvents()
    -- Theme system events
    LibArenaTools:RegisterEvent('SUI_THEME_CHANGED', function(event, newTheme)
        self:OnThemeChanged(newTheme)
    end)
    
    -- Profile system events
    LibArenaTools:RegisterEvent('SUI_PROFILE_CHANGED', function(event, newProfile)
        self:OnProfileChanged(newProfile)
    end)
    
    -- Module state events
    LibArenaTools:RegisterEvent('SUI_MODULE_ENABLED', function(event, moduleName)
        self:OnModuleStateChanged(moduleName, true)
    end)
    
    LibArenaTools:RegisterEvent('SUI_MODULE_DISABLED', function(event, moduleName)
        self:OnModuleStateChanged(moduleName, false)
    end)
    
    -- Artwork events
    LibArenaTools:RegisterEvent('SUI_ARTWORK_STYLE_CHANGED', function(event, newStyle)
        self:OnArtworkStyleChanged(newStyle)
    end)
    
    -- UnitFrames events
    LibArenaTools:RegisterEvent('SUI_UNITFRAMES_UPDATED', function(event, frameType)
        self:OnUnitFramesUpdated(frameType)
    end)
end

function EventRelay:OnThemeChanged(newTheme)
    if LibArenaTools.db.integration.useSpartanUITheme then
        LibArenaTools.ThemeSync:ApplyTheme(newTheme)
    end
end

function EventRelay:OnProfileChanged(newProfile)
    -- Reload arena configuration
    LibArenaTools:ReloadConfiguration()
    
    -- Reapply current theme
    if LibArenaTools.db.integration.useSpartanUITheme then
        LibArenaTools.ThemeSync:ApplyCurrentTheme()
    end
    
    -- Update positioning
    LibArenaTools.PositionManager:CalculateOptimalPositions()
end

function EventRelay:OnModuleStateChanged(moduleName, enabled)
    if moduleName == 'Artwork' then
        if enabled and LibArenaTools.db.integration.useArtworkPositions then
            LibArenaTools.PositionManager:LoadSpartanUIPositions()
            LibArenaTools.PositionManager:CalculateOptimalPositions()
        end
    elseif moduleName == 'UnitFrames' then
        if not enabled then
            -- UnitFrames disabled, disable LibArenaTools too
            LibArenaTools:SetEnabledState(false)
        else
            -- UnitFrames re-enabled, check if we should re-enable
            if LibArenaTools.db.enabled then
                LibArenaTools:SetEnabledState(true)
            end
        end
    end
end

function EventRelay:OnArtworkStyleChanged(newStyle)
    if LibArenaTools.db.integration.useArtworkPositions then
        LibArenaTools.PositionManager:LoadSpartanUIPositions()
        LibArenaTools.PositionManager:CalculateOptimalPositions()
    end
    
    -- Apply new theme if theme sync is enabled
    if LibArenaTools.db.integration.useSpartanUITheme then
        LibArenaTools.ThemeSync:ApplyTheme(newStyle)
    end
end
```

---

## 6. Performance Integration

### 6.1 SpartanUI Performance Coordination

```lua
---@class LibArenaTools.PerformanceIntegration
local PerformanceIntegration = {}

function PerformanceIntegration:Initialize()
    -- Integrate with SpartanUI performance monitoring
    self:IntegrateWithSUIPerformance()
    
    -- Setup arena-specific performance tracking
    self:SetupArenaPerformanceTracking()
    
    -- Register performance events
    self:RegisterPerformanceEvents()
end

function PerformanceIntegration:IntegrateWithSUIPerformance()
    -- Add LibArenaTools to SUI performance monitoring
    if SUI.Performance then
        SUI.Performance:RegisterModule('LibArenaTools', function()
            return LibArenaTools.PerformanceMonitor:GetCurrentMetrics()
        end)
    end
end

function PerformanceIntegration:OnCombatStart()
    -- Optimize for combat performance
    LibArenaTools.PerformanceMonitor:EnableCombatMode()
    
    -- Reduce update frequencies for non-critical elements
    LibArenaTools:SetUpdateMode('combat')
end

function PerformanceIntegration:OnCombatEnd()
    -- Restore normal performance settings
    LibArenaTools.PerformanceMonitor:DisableCombatMode()
    
    -- Resume normal update frequencies
    LibArenaTools:SetUpdateMode('normal')
end
```

---

## 7. Migration Integration

### 7.1 SpartanUI Arena Frame Replacement

```lua
---@class LibArenaTools.SUIIntegration
local SUIIntegration = {}

function SUIIntegration:ReplaceDefaultArenaFrames()
    -- Disable default SpartanUI arena frames
    if SUI.UF.Unit:Get('arena') then
        SUI.UF.Unit:Get('arena'):SetEnabled(false)
    end
    
    -- Register LibArenaTools as arena provider
    SUI.UF:RegisterArenaProvider(LibArenaTools)
    
    -- Update UnitFrames configuration
    SUI.UF.db.arena.provider = 'LibArenaTools'
end

function SUIIntegration:RestoreDefaultArenaFrames()
    -- Re-enable default SpartanUI arena frames
    if SUI.UF.Unit:Get('arena') then
        SUI.UF.Unit:Get('arena'):SetEnabled(true)
    end
    
    -- Unregister LibArenaTools as arena provider
    SUI.UF:UnregisterArenaProvider(LibArenaTools)
    
    -- Update UnitFrames configuration
    SUI.UF.db.arena.provider = 'default'
end
```

---

## 8. Integration Checklist

### 8.1 Pre-Integration Requirements

- [ ] ✅ SpartanUI UnitFrames module is enabled and functional
- [ ] ✅ oUF framework is available and working
- [ ] ✅ Required libraries (LibCooldownTracker, DRList) are loaded
- [ ] ✅ SpartanUI database system is operational
- [ ] ✅ SpartanUI options system is available

### 8.2 Integration Implementation Checklist

**Core Integration:**
- [ ] ✅ Module registration following SpartanUI patterns
- [ ] ✅ Database integration with SUI.DB system
- [ ] ✅ Event coordination with SpartanUI core events
- [ ] ✅ Options panel integration
- [ ] ✅ Performance monitoring integration

**Theme Integration:**
- [ ] ✅ Complete theme mapping for all SpartanUI themes
- [ ] ✅ Real-time theme change detection and application
- [ ] ✅ Theme override system for customizations
- [ ] ✅ Special effects integration (glows, scanlines, etc.)

**Position Integration:**
- [ ] ✅ Artwork position inheritance system
- [ ] ✅ Conflict detection with other SpartanUI modules
- [ ] ✅ Automatic position adjustment system
- [ ] ✅ Manual position override capabilities

**Configuration Integration:**
- [ ] ✅ Unified options in SpartanUI config panel
- [ ] ✅ Profile inheritance and management
- [ ] ✅ Configuration presets for different playstyles
- [ ] ✅ Migration tools from other arena addons

### 8.3 Testing and Validation

**Integration Testing:**
- [ ] ✅ All SpartanUI themes apply correctly to arena frames
- [ ] ✅ Position coordination works with all module combinations
- [ ] ✅ Configuration changes persist across sessions
- [ ] ✅ Profile switching works correctly
- [ ] ✅ Performance impact is minimal and acceptable

**Compatibility Testing:**
- [ ] ✅ Works with SpartanUI in all supported configurations
- [ ] ✅ No conflicts with other SpartanUI modules
- [ ] ✅ Graceful degradation when optional modules are disabled
- [ ] ✅ Proper cleanup when LibArenaTools is disabled

This integration specification ensures that LibArenaTools operates as a first-class citizen within the SpartanUI ecosystem, providing seamless operation, consistent theming, intelligent positioning, and unified configuration management.