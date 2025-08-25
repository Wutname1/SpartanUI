# LibsDataBar Architecture Design Document

## Executive Summary

LibsDataBar will be the next-generation data broker display addon, combining TitanPanel's ecosystem depth with modern architectural patterns and performance optimizations. Designed as both a standalone addon and integrated SpartanUI component, it targets the market gap for a technically excellent, developer-friendly data broker display that can challenge TitanPanel's dominance.

**Target Goals:**

- **Performance**: Match Bazooka's efficiency (minimal resource usage)
- **Ecosystem**: Exceed TitanPanel's plugin compatibility and developer experience
- **User Experience**: Surpass ChocolateBar's modern interface and customization
- **Innovation**: Advanced performance monitoring, intelligent caching, and superior developer tools

---

## 1. Overall Architecture Philosophy

### 1.1 Design Principles

**1. Hybrid Modularity**

- Core framework with pluggable components
- Clean separation between library, display, and plugin systems
- Minimal dependencies for core functionality
- Rich extensions for advanced features

**2. Performance First**

- Zero-cost abstractions where possible
- Lazy loading of non-essential components
- Efficient event batching and update mechanisms
- Built-in performance monitoring and optimization

**3. Developer Experience**

- Modern development tools and practices
- Comprehensive documentation with interactive examples
- Rich debugging and profiling capabilities
- Automated testing and validation frameworks

**4. Ecosystem Compatibility**

- Full TitanPanel plugin compatibility layer
- Complete LibDataBroker 1.1 implementation
- Migration tools for all major data broker displays
- Future-proof API design with versioning

### 1.2 Architecture Overview

```
LibsDataBar Ecosystem
├── Core Library (LibsDataBar-1.0)
│   ├── Plugin System (Native + LDB)
│   ├── Event Management
│   ├── Configuration System
│   └── Performance Framework
├── Display Engine
│   ├── Bar Management
│   ├── Rendering System
│   ├── Theme Engine
│   └── Animation Framework
├── Developer Tools
│   ├── Plugin Templates
│   ├── Debugging Framework
│   ├── Validation Suite
│   └── Documentation System
└── SpartanUI Integration
    ├── Theme Synchronization
    ├── Layout Coordination
    ├── Event Integration
    └── Unified Configuration
```

---

## 2. Core Library Architecture (LibsDataBar-1.0)

### 2.1 Library Interface Design

```lua
---@class LibsDataBar : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0, AceBucket-3.0, AceConsole-3.0, AceComm-3.0
---@field version string Library version
---@field bars table<string, DataBar> Active bars registry
---@field plugins table<string, Plugin> Plugin registry
---@field db table AceDB-3.0 database instance
---@field callbacks table CallbackHandler-1.0 instance for events
---@field performance PerformanceMonitor Performance tracking
local LibsDataBar = LibStub:NewLibrary("LibsDataBar-1.0", 1)

---Core API Surface
---@class LibsDataBarAPI
local API = {
    -- Bar Management
    CreateBar = function(config) end,
    DestroyBar = function(barId) end,
    GetBar = function(barId) end,
    GetBars = function() end,

    -- Plugin Management
    RegisterPlugin = function(plugin) end,
    UnregisterPlugin = function(pluginId) end,
    GetPlugin = function(pluginId) end,
    GetPlugins = function(category) end,

    -- Configuration
    GetConfig = function(path) end,
    SetConfig = function(path, value) end,
    ResetConfig = function(path) end,
    ImportConfig = function(source, data) end,

    -- Events
    RegisterEvent = function(event, callback) end,
    UnregisterEvent = function(event, callback) end,
    FireEvent = function(event, ...) end,

    -- Performance
    StartProfiler = function(category) end,
    StopProfiler = function(category) end,
    GetPerformanceReport = function() end,

    -- Developer Tools
    ValidatePlugin = function(plugin) end,
    DebugLog = function(level, message, category) end,
    GetAPIDocumentation = function() end
}
```

### 2.2 Plugin System Architecture

**Dual Plugin Support Strategy:**

```lua
---@class PluginRegistration
---@field type "native"|"ldb" Plugin type
---@field id string Unique plugin identifier
---@field name string Display name
---@field version string Plugin version
---@field author string Plugin author
---@field category string Plugin category
---@field dependencies table<string, string> Required dependencies
---@field api table Plugin API interface

-- Native Plugin Registration
local nativePlugin = {
    type = "native",
    id = "LibsDataBar_Clock",
    name = "Clock",
    version = "1.0.0",
    author = "LibsDataBar Team",
    category = "Information",

    -- Native API
    GetText = function() return date("%H:%M") end,
    GetTooltip = function() return "Current server time" end,
    GetIcon = function() return "Interface\\Icons\\INV_Misc_PocketWatch_01" end,
    OnClick = function(button) end,
    OnUpdate = function(elapsed) end,

    -- Configuration
    GetConfigOptions = function() return clockConfigTable end,
    GetDefaultConfig = function() return clockDefaults end,

    -- Lifecycle
    OnInitialize = function() end,
    OnEnable = function() end,
    OnDisable = function() end
}

-- LDB Plugin Adapter
local ldbAdapter = {
    type = "ldb",
    dataObject = LDB:GetDataObjectByName("Broker_Clock"),

    -- Adapter interface
    GetText = function() return self.dataObject.text end,
    GetTooltip = function() return self.dataObject.tooltip end,
    GetIcon = function() return self.dataObject.icon end,
    OnClick = function(button)
        if self.dataObject.OnClick then
            self.dataObject.OnClick(nil, button)
        end
    end
}
```

### 2.3 Event Management System

**Ace3-Based Event Framework:**

LibsDataBar uses the industry-standard Ace3 library system for robust event management:

- **AceEvent-3.0**: WoW event registration and handling
- **CallbackHandler-1.0**: Internal addon messaging system
- **AceTimer-3.0**: Efficient timer system for periodic updates
- **AceBucket-3.0**: Event batching for performance optimization

```lua
-- Event handling using AceEvent-3.0
function LibsDataBar:OnEnable()
    -- Register WoW events
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    
    -- Setup internal messaging
    self.callbacks = self.callbacks or LibStub("CallbackHandler-1.0"):New(self)
end

-- Internal messaging for plugins and systems
function LibsDataBar:TriggerInternalEvent(event, ...)
    if self.callbacks then
        self.callbacks:Fire(event, ...)
    end
    -- Also use AceEvent messaging
    self:SendMessage(event, ...)
            self.frame:RegisterEvent(event)
        end
    end

    -- Add callback with options
    self.eventRegistry[event][callback] = {
        enabled = true,
        throttle = options.throttle,
        batch = options.batch,
        priority = options.priority or 0
    }
end

function EventManager:FireEvent(event, ...)
    local callbacks = self.eventRegistry[event]
    if not callbacks then return end

    local args = {...}

    -- Sort by priority
    local sortedCallbacks = {}
    for callback, config in pairs(callbacks) do
        if config.enabled then
            table.insert(sortedCallbacks, {callback, config})
        end
    end
    table.sort(sortedCallbacks, function(a, b)
        return a[2].priority > b[2].priority
    end)

    -- Execute callbacks
    for _, callbackData in ipairs(sortedCallbacks) do
        local callback, config = callbackData[1], callbackData[2]

        if config.batch then
            self:AddToBatch(event, callback, args)
        elseif config.throttle then
            self:ThrottleCallback(event, callback, args, config.throttle)
        else
            self:SafeCall(callback, event, unpack(args))
        end
    end
end

function EventManager:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        LibsDataBar.Debug:LogError("Event callback failed", result)
    end
    return success, result
end
```

### 2.4 Configuration Management

**AceDB-3.0 Based Configuration System:**

LibsDataBar uses AceDB-3.0 for robust configuration management with profiles, persistence, and automatic UI generation through AceConfig-3.0.

```lua
-- Configuration system using AceDB-3.0
function LibsDataBar:InitializeDatabase()
    local AceDB = LibStub('AceDB-3.0')
    self.db = AceDB:New('LibsDataBarDB', databaseDefaults, true)
    
    -- Add profile support with AceDBOptions-3.0
    local AceDBOptions = LibStub('AceDBOptions-3.0')
    local profileOptions = AceDBOptions:GetOptionsTable(self.db)
end

-- Direct configuration access methods
function LibsDataBar:GetConfig(path)
    -- Navigate dot-separated path: "plugins.clock.enabled"
    local config = self.db.profile
    for key in string.gmatch(path, "[^%.]+") do
        if type(config) == "table" and config[key] ~= nil then
            config = config[key]
        else
            return nil
        end
    end
    return config
end

function LibsDataBar:SetConfig(path, value)
    local config = self.db.profile
    local keys = {string.match(path, "([^%.]+)")}
    
    -- Navigate to parent object
    for i = 1, #keys - 1 do
        if type(config[keys[i]]) ~= "table" then 
            config[keys[i]] = {} 
        end
        config = config[keys[i]]
    end
    
    config[keys[#keys]] = value
    self.callbacks:Fire('ConfigChanged', path, value)
end

-- Configuration Schema
local configSchema = {
    profile = {
        version = 1,

        -- Global settings
        global = {
            theme = "modern",
            performance = {
                enableProfiler = false,
                updateThrottle = 0.1,
                memoryOptimization = true
            },
            developer = {
                debugMode = false,
                showPerformanceStats = false,
                enableHotReload = false
            }
        },

        -- Bar configurations
        bars = {
            ["*"] = {
                id = "",
                enabled = true,
                position = "bottom", -- top, bottom, left, right, custom
                anchor = {
                    point = "BOTTOM",
                    relativeTo = "UIParent",
                    relativePoint = "BOTTOM",
                    x = 0,
                    y = 0
                },
                size = {
                    width = 0, -- 0 = auto (full screen)
                    height = 24,
                    scale = 1.0
                },
                appearance = {
                    background = {
                        texture = "Interface\\Tooltips\\UI-Tooltip-Background",
                        color = {r=0, g=0, b=0, a=0.8},
                        gradient = nil
                    },
                    border = {
                        texture = "Interface\\Tooltips\\UI-Tooltip-Border",
                        color = {r=1, g=1, b=1, a=1},
                        size = 1
                    },
                    font = {
                        family = "Fonts\\FRIZQT__.TTF",
                        size = 12,
                        flags = "",
                        color = {r=1, g=1, b=1, a=1}
                    }
                },
                behavior = {
                    autoHide = false,
                    autoHideDelay = 2.0,
                    combatHide = false,
                    mouseoverShow = true,
                    strata = "MEDIUM",
                    level = 1
                },
                layout = {
                    orientation = "horizontal", -- horizontal, vertical
                    alignment = "left", -- left, center, right
                    spacing = 4,
                    padding = {left=8, right=8, top=2, bottom=2},
                    grouping = false
                }
            }
        },

        -- Plugin configurations
        plugins = {
            ["*"] = {
                enabled = true,
                bar = "main",
                position = 100, -- Sort order

                display = {
                    showIcon = true,
                    showText = true,
                    showLabel = false,
                    width = 0, -- 0 = auto
                    iconSize = 16,
                    textFormat = "default"
                },

                behavior = {
                    clickThrough = false,
                    tooltip = true,
                    tooltipAnchor = "ANCHOR_CURSOR"
                },

                appearance = {
                    iconTexture = nil, -- Override default
                    fontOverride = nil,
                    colorOverride = nil,
                    opacity = 1.0
                },

                -- Plugin-specific settings
                pluginSettings = {}
            }
        },

        -- Theme configurations
        themes = {
            ["*"] = {
                name = "",
                author = "",
                version = "1.0.0",
                presets = {},
                customizations = {}
            }
        }
    }
}
```

---

## 3. Display Engine Architecture

### 3.1 Revolutionary Flexible Display System

**🚀 COMPETITIVE ADVANTAGE: LibsDataBar introduces a dual-mode display system that no other data broker addon offers:**

1. **Traditional Bars**: Full-width bars like TitanPanel/ChocolateBar for familiar usage
2. **Smart Containers**: Flexible, moveable rectangles that can be positioned anywhere on screen

**This flexible positioning system allows users to create highly customized layouts that are impossible with competing addons:**

- **3-item horizontal container** above chat box
- **Vertical sidebar container** with 5 plugins on screen edge
- **Corner mini-containers** for critical info near action bars
- **Floating containers** that follow screen real estate usage
- **Mixed layouts** with both bars and containers simultaneously

### 3.1.1 Container Architecture

**Smart Container System:**

```lua
---@class Container : DataBar
---@field containerType "floating"|"docked"|"anchored"
---@field dimensions table Container size and constraints
---@field dragHandle Frame Drag handle for movement
---@field resizeHandle Frame Resize handle for sizing
---@field snapZones table Available snap positions
local Container = setmetatable({}, {__index = DataBar})

function Container:Create(config)
    local container = DataBar:Create(config)
    setmetatable(container, {__index = Container})

    -- Container-specific properties
    container.containerType = config.containerType or "floating"
    container.dimensions = {
        minWidth = config.minWidth or 100,
        maxWidth = config.maxWidth or 800,
        minHeight = config.minHeight or 24,
        maxHeight = config.maxHeight or 200,
        aspectRatio = config.aspectRatio or nil
    }

    -- Create container-specific UI elements
    container:CreateDragHandle()
    container:CreateResizeHandle()
    container:SetupSnapping()

    return container
end

function Container:CreateDragHandle()
    self.dragHandle = CreateFrame("Frame", nil, self.frame)
    self.dragHandle:SetAllPoints(self.frame)
    self.dragHandle:EnableMouse(true)
    self.dragHandle:RegisterForDrag("LeftButton")

    self.dragHandle:SetScript("OnDragStart", function()
        if not self.config.behavior.locked then
            self:StartDrag()
        end
    end)

    self.dragHandle:SetScript("OnDragStop", function()
        self:StopDrag()
    end)
end

function Container:CreateResizeHandle()
    if not self.config.behavior.resizable then return end

    self.resizeHandle = CreateFrame("Frame", nil, self.frame)
    self.resizeHandle:SetSize(16, 16)
    self.resizeHandle:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -2, 2)

    -- Visual resize indicator
    local texture = self.resizeHandle:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    self.resizeHandle:EnableMouse(true)
    self.resizeHandle:RegisterForDrag("LeftButton")

    self.resizeHandle:SetScript("OnDragStart", function()
        self:StartResize()
    end)

    self.resizeHandle:SetScript("OnDragStop", function()
        self:StopResize()
    end)
end

function Container:SetupSnapping()
    self.snapZones = {
        -- Screen edges
        {type = "screen", edge = "top", threshold = 50},
        {type = "screen", edge = "bottom", threshold = 50},
        {type = "screen", edge = "left", threshold = 50},
        {type = "screen", edge = "right", threshold = 50},

        -- Other containers
        {type = "container", mode = "adjacent", threshold = 20},

        -- Custom anchor points (chat frame, minimap, etc.)
        {type = "anchor", frame = "ChatFrame1", threshold = 30},
        {type = "anchor", frame = "Minimap", threshold = 30},
    }
end
```

### 3.1.2 Advanced Bar Framework

```lua
---@class DataBar
---@field id string Unique bar identifier
---@field frame Frame WoW UI frame
---@field plugins table<string, PluginButton> Plugin buttons
---@field config table Bar configuration
---@field layoutManager LayoutManager Layout calculation engine
---@field animationController AnimationController Animation system
---@field theme Theme Current theme
local DataBar = {}

function DataBar:Create(config)
    local bar = setmetatable({}, {__index = DataBar})

    bar.id = config.id
    bar.config = config
    bar.plugins = {}

    -- Create main frame
    bar.frame = CreateFrame("Frame", "LibsDataBar_" .. config.id, UIParent)
    bar.frame:SetFrameStrata(config.behavior.strata)
    bar.frame:SetFrameLevel(config.behavior.level)

    -- Initialize systems
    bar.layoutManager = LayoutManager:New(bar)
    bar.animationController = AnimationController:New(bar)
    bar.theme = ThemeManager:GetTheme(config.appearance.theme)

    -- Setup events
    bar:RegisterEvents()
    bar:UpdateAppearance()
    bar:UpdatePosition()

    return bar
end

function DataBar:AddPlugin(plugin)
    local button = PluginButton:Create(plugin, self)
    self.plugins[plugin.id] = button

    -- Update layout
    self.layoutManager:CalculateLayout()
    self:UpdatePluginPositions()

    -- Fire event
    LibsDataBar.events:FireEvent("PLUGIN_ADDED", self.id, plugin.id)
end

function DataBar:UpdateLayout()
    if InCombatLockdown() then
        -- Queue for after combat
        self.layoutManager:QueueUpdate()
        return
    end

    local startTime = GetTime()

    -- Calculate new layout
    local layout = self.layoutManager:CalculateLayout()

    -- Update plugin positions with animation
    for pluginId, button in pairs(self.plugins) do
        local newPos = layout.positions[pluginId]
        if newPos then
            self.animationController:AnimateToPosition(button, newPos)
        end
    end

    -- Performance tracking
    local elapsed = GetTime() - startTime
    LibsDataBar.performance:RecordMetric("bar_layout_time", elapsed)
end
```

### 3.2 Plugin Button System

**Modern Plugin Button Framework:**

```lua
---@class PluginButton
---@field plugin Plugin Associated plugin
---@field bar DataBar Parent bar
---@field frame Button UI button frame
---@field icon Texture Icon texture
---@field text FontString Text display
---@field config table Button configuration
local PluginButton = {}

function PluginButton:Create(plugin, bar)
    local button = setmetatable({}, {__index = PluginButton})

    button.plugin = plugin
    button.bar = bar
    button.config = LibsDataBar.config:GetPluginConfig(plugin.id)

    -- Create button frame
    button.frame = CreateFrame("Button",
        "LibsDataBar_" .. bar.id .. "_" .. plugin.id,
        bar.frame,
        "LibsDataBarButtonTemplate")

    -- Create icon
    if button.config.display.showIcon then
        button.icon = button.frame:CreateTexture(nil, "ARTWORK")
        button.icon:SetTexture(plugin:GetIcon())
        button.icon:SetSize(button.config.display.iconSize, button.config.display.iconSize)
    end

    -- Create text
    if button.config.display.showText then
        button.text = button.frame:CreateFontString(nil, "OVERLAY")
        button.text:SetFont(bar.config.appearance.font.family,
                           bar.config.appearance.font.size,
                           bar.config.appearance.font.flags)
        button.text:SetText(plugin:GetText())
    end

    -- Setup interactions
    button:SetupEventHandlers()
    button:UpdateSize()

    return button
end

function PluginButton:SetupEventHandlers()
    -- Click handling
    self.frame:SetScript("OnClick", function(frame, mouseButton, down)
        self:OnClick(mouseButton, down)
    end)

    -- Tooltip handling
    self.frame:SetScript("OnEnter", function(frame)
        self:ShowTooltip()
    end)

    self.frame:SetScript("OnLeave", function(frame)
        self:HideTooltip()
    end)

    -- Drag and drop
    if LibsDataBar.config:GetGlobal("ui.enableDragDrop") then
        self.frame:RegisterForDrag("LeftButton")
        self.frame:SetScript("OnDragStart", function(frame)
            self:StartDrag()
        end)
        self.frame:SetScript("OnDragStop", function(frame)
            self:StopDrag()
        end)
    end
end

function PluginButton:Update()
    local startTime = GetTime()

    -- Update text
    if self.text then
        local newText = self.plugin:GetText()
        if self.text:GetText() ~= newText then
            self.text:SetText(newText)
            self:UpdateSize()
        end
    end

    -- Update icon
    if self.icon then
        local newIcon = self.plugin:GetIcon()
        if self.icon:GetTexture() ~= newIcon then
            self.icon:SetTexture(newIcon)
        end
    end

    -- Performance tracking
    local elapsed = GetTime() - startTime
    LibsDataBar.performance:RecordMetric("plugin_update_time", elapsed)
end
```

### 3.3 Theme Engine

**Advanced Theme System:**

```lua
---@class ThemeManager
---@field themes table<string, Theme> Loaded themes
---@field currentTheme Theme Active theme
---@field customizations table User customizations
local ThemeManager = {}

---@class Theme
---@field id string Theme identifier
---@field name string Display name
---@field author string Theme author
---@field version string Theme version
---@field presets table<string, table> Theme presets
---@field textures table<string, string> Theme textures
---@field colors table<string, table> Color definitions
---@field animations table<string, table> Animation definitions
local Theme = {}

-- Built-in Modern Theme
local modernTheme = {
    id = "modern",
    name = "Modern",
    author = "LibsDataBar Team",
    version = "1.0.0",

    presets = {
        dark = {
            background = {
                texture = "Interface\\AddOns\\LibsDataBar\\Textures\\ModernBackground",
                color = {r=0.1, g=0.1, b=0.1, a=0.9},
                gradient = {
                    orientation = "HORIZONTAL",
                    startColor = {r=0.1, g=0.1, b=0.1, a=0.9},
                    endColor = {r=0.2, g=0.2, b=0.2, a=0.9}
                }
            },
            border = {
                texture = "Interface\\AddOns\\LibsDataBar\\Textures\\ModernBorder",
                color = {r=0.3, g=0.3, b=0.3, a=1.0},
                size = 1
            },
            font = {
                family = "Interface\\AddOns\\LibsDataBar\\Fonts\\Modern.ttf",
                size = 12,
                flags = "",
                color = {r=0.9, g=0.9, b=0.9, a=1.0}
            }
        },

        light = {
            background = {
                texture = "Interface\\AddOns\\LibsDataBar\\Textures\\ModernBackground",
                color = {r=0.95, g=0.95, b=0.95, a=0.9},
                gradient = {
                    orientation = "HORIZONTAL",
                    startColor = {r=0.95, g=0.95, b=0.95, a=0.9},
                    endColor = {r=0.85, g=0.85, b=0.85, a=0.9}
                }
            },
            border = {
                texture = "Interface\\AddOns\\LibsDataBar\\Textures\\ModernBorder",
                color = {r=0.7, g=0.7, b=0.7, a=1.0},
                size = 1
            },
            font = {
                family = "Interface\\AddOns\\LibsDataBar\\Fonts\\Modern.ttf",
                size = 12,
                flags = "",
                color = {r=0.1, g=0.1, b=0.1, a=1.0}
            }
        }
    },

    animations = {
        fadeIn = {
            type = "alpha",
            duration = 0.3,
            startValue = 0,
            endValue = 1,
            easing = "ease-out"
        },

        slideUp = {
            type = "position",
            duration = 0.2,
            startOffset = {x=0, y=-10},
            endOffset = {x=0, y=0},
            easing = "ease-out"
        },

        highlight = {
            type = "color",
            duration = 0.1,
            property = "background",
            startColor = "normal",
            endColor = "highlight",
            easing = "linear"
        }
    }
}

function ThemeManager:ApplyTheme(bar, themeId, presetId)
    local theme = self.themes[themeId]
    if not theme then return false end

    local preset = theme.presets[presetId or "dark"]
    if not preset then return false end

    -- Apply background
    if preset.background then
        bar.frame:SetBackdrop({
            bgFile = preset.background.texture,
            edgeFile = preset.border and preset.border.texture,
            tile = false,
            tileSize = 0,
            edgeSize = preset.border and preset.border.size or 0,
            insets = {left=0, right=0, top=0, bottom=0}
        })

        if preset.background.gradient then
            self:ApplyGradient(bar.frame, preset.background.gradient)
        else
            bar.frame:SetBackdropColor(
                preset.background.color.r,
                preset.background.color.g,
                preset.background.color.b,
                preset.background.color.a
            )
        end

        if preset.border then
            bar.frame:SetBackdropBorderColor(
                preset.border.color.r,
                preset.border.color.g,
                preset.border.color.b,
                preset.border.color.a
            )
        end
    end

    -- Apply fonts to all plugins
    for _, plugin in pairs(bar.plugins) do
        if plugin.text and preset.font then
            plugin.text:SetFont(
                preset.font.family,
                preset.font.size,
                preset.font.flags
            )
            plugin.text:SetTextColor(
                preset.font.color.r,
                preset.font.color.g,
                preset.font.color.b,
                preset.font.color.a
            )
        end
    end

    return true
end
```

---

## 4. Performance Framework

### 4.1 Performance Monitoring System

**Comprehensive Performance Analytics:**

```lua
---@class PerformanceMonitor
---@field enabled boolean Performance tracking enabled
---@field metrics table<string, MetricCollector> Metric collectors
---@field profilers table<string, Profiler> Active profilers
---@field reports table<string, PerformanceReport> Generated reports
local PerformanceMonitor = {}

---@class MetricCollector
---@field samples table<number> Sample values
---@field maxSamples number Maximum samples to keep
---@field totalSamples number Total samples collected
---@field lastValue number Last recorded value
---@field average number Running average
---@field min number Minimum value
---@field max number Maximum value
local MetricCollector = {}

function PerformanceMonitor:RecordMetric(metricName, value)
    if not self.enabled then return end

    local collector = self.metrics[metricName]
    if not collector then
        collector = MetricCollector:New(metricName)
        self.metrics[metricName] = collector
    end

    collector:AddSample(value)
end

function PerformanceMonitor:StartProfiler(category)
    if not self.enabled then return nil end

    local profiler = {
        category = category,
        startTime = debugprofilestop(),
        memoryStart = gcinfo() * 1024, -- Convert to bytes
        startFrame = GetFramerate()
    }

    self.profilers[category] = profiler
    return profiler
end

function PerformanceMonitor:StopProfiler(category)
    local profiler = self.profilers[category]
    if not profiler then return nil end

    local endTime = debugprofilestop()
    local memoryEnd = gcinfo() * 1024
    local endFrame = GetFramerate()

    local result = {
        category = category,
        executionTime = endTime - profiler.startTime,
        memoryDelta = memoryEnd - profiler.memoryStart,
        framerateDelta = endFrame - profiler.startFrame,
        timestamp = GetTime()
    }

    -- Record metrics
    self:RecordMetric(category .. "_execution_time", result.executionTime)
    self:RecordMetric(category .. "_memory_delta", result.memoryDelta)
    self:RecordMetric("global_framerate", endFrame)

    self.profilers[category] = nil
    return result
end

function PerformanceMonitor:GenerateReport()
    local report = {
        timestamp = GetTime(),
        addon = {
            memoryUsage = GetAddOnMemoryUsage("LibsDataBar"),
            cpuUsage = GetAddOnCPUUsage("LibsDataBar"),
        },
        system = {
            framerate = GetFramerate(),
            latency = select(3, GetNetStats()),
            bandwidth = select(1, GetNetStats()),
        },
        metrics = {},
        recommendations = {}
    }

    -- Process metrics
    for metricName, collector in pairs(self.metrics) do
        report.metrics[metricName] = {
            average = collector.average,
            min = collector.min,
            max = collector.max,
            samples = collector.totalSamples,
            recent = collector:GetRecentSamples(10)
        }
    end

    -- Generate recommendations
    report.recommendations = self:GenerateRecommendations(report)

    return report
end

function PerformanceMonitor:GenerateRecommendations(report)
    local recommendations = {}

    -- Memory usage recommendations
    if report.addon.memoryUsage > 50 * 1024 then -- 50MB
        table.insert(recommendations, {
            type = "memory",
            severity = "warning",
            message = "High memory usage detected. Consider disabling unused plugins.",
            action = "review_plugins"
        })
    end

    -- Frame rate recommendations
    if report.system.framerate < 30 then
        table.insert(recommendations, {
            type = "performance",
            severity = "error",
            message = "Low framerate detected. Reduce animation frequency or disable visual effects.",
            action = "reduce_animations"
        })
    end

    -- Update frequency recommendations
    local updateTime = report.metrics.plugin_update_time
    if updateTime and updateTime.average > 5 then -- 5ms
        table.insert(recommendations, {
            type = "performance",
            severity = "warning",
            message = "Plugin updates taking too long. Consider throttling update frequency.",
            action = "throttle_updates"
        })
    end

    return recommendations
end
```

### 4.2 Memory Management

**Advanced Memory Optimization:**

```lua
---@class MemoryManager
---@field pools table<string, ObjectPool> Object pools
---@field gcThreshold number Memory threshold for GC
---@field monitoring boolean Memory monitoring enabled
local MemoryManager = {}

---@class ObjectPool
---@field objects table Pool of reusable objects
---@field factory function Object creation function
---@field reset function Object reset function
---@field maxSize number Maximum pool size
local ObjectPool = {}

function MemoryManager:GetPooledFrame(frameType)
    local pool = self.pools[frameType]
    if not pool then
        pool = ObjectPool:New(frameType,
            function() return CreateFrame(frameType) end,
            function(frame) frame:Hide(); frame:ClearAllPoints() end
        )
        self.pools[frameType] = pool
    end

    return pool:Acquire()
end

function MemoryManager:ReturnPooledFrame(frame, frameType)
    local pool = self.pools[frameType]
    if pool then
        pool:Release(frame)
    end
end

function MemoryManager:OptimizeMemory()
    local currentMemory = gcinfo() * 1024

    if currentMemory > self.gcThreshold then
        -- Clean up pools
        for poolType, pool in pairs(self.pools) do
            pool:Cleanup()
        end

        -- Force garbage collection
        collectgarbage("collect")

        local newMemory = gcinfo() * 1024
        local freed = currentMemory - newMemory

        LibsDataBar.performance:RecordMetric("memory_freed", freed)
        LibsDataBar.Debug:Log("Memory optimization freed " ..
                              math.floor(freed / 1024) .. "KB", "performance")
    end
end
```

---

## 5. Developer Experience Framework

### 5.1 Plugin Development Tools

**Modern Development Environment:**

```lua
---@class DeveloperTools
---@field debugger Debugger Debug framework
---@field validator PluginValidator Plugin validation
---@field templates table<string, Template> Plugin templates
---@field hotReload HotReload Hot reload system
---@field documentation Documentation Interactive docs
local DeveloperTools = {}

---@class PluginValidator
---@field rules table<string, function> Validation rules
---@field severity table<string, string> Rule severity levels
local PluginValidator = {}

function PluginValidator:ValidatePlugin(plugin)
    local results = {
        valid = true,
        errors = {},
        warnings = {},
        suggestions = {}
    }

    -- Required field validation
    local requiredFields = {"id", "name", "version", "GetText"}
    for _, field in ipairs(requiredFields) do
        if not plugin[field] then
            table.insert(results.errors, "Missing required field: " .. field)
            results.valid = false
        end
    end

    -- Type validation
    if plugin.GetText and type(plugin.GetText) ~= "function" then
        table.insert(results.errors, "GetText must be a function")
        results.valid = false
    end

    -- Performance validation
    if plugin.OnUpdate then
        table.insert(results.warnings, "OnUpdate can impact performance. Consider using events instead.")
    end

    -- Best practice suggestions
    if not plugin.GetTooltip then
        table.insert(results.suggestions, "Consider adding GetTooltip for better user experience")
    end

    if not plugin.category then
        table.insert(results.suggestions, "Add category for better plugin organization")
    end

    return results
end

function PluginValidator:GetValidationReport(plugin)
    local validation = self:ValidatePlugin(plugin)

    local report = {
        pluginId = plugin.id or "unknown",
        timestamp = GetTime(),
        valid = validation.valid,
        score = self:CalculateQualityScore(validation),
        issues = {
            errors = validation.errors,
            warnings = validation.warnings,
            suggestions = validation.suggestions
        },
        recommendations = self:GenerateRecommendations(validation)
    }

    return report
end
```

### 5.2 Plugin Templates

**Modern Plugin Templates:**

```lua
-- Native Plugin Template
local NativePluginTemplate = {
    -- Required metadata
    id = "MyPlugin",
    name = "My Plugin",
    version = "1.0.0",
    author = "Plugin Author",
    category = "Information",
    description = "Plugin description",

    -- Dependencies
    dependencies = {
        ["LibsDataBar-1.0"] = "1.0.0"
    },

    -- Required methods
    GetText = function(self)
        return "Plugin Text"
    end,

    -- Optional methods
    GetIcon = function(self)
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end,

    GetTooltip = function(self)
        return "Plugin tooltip information"
    end,

    OnClick = function(self, button)
        if button == "LeftButton" then
            print("Left clicked!")
        elseif button == "RightButton" then
            self:ShowConfigMenu()
        end
    end,

    OnUpdate = function(self, elapsed)
        -- Use sparingly - consider events instead
    end,

    -- Configuration
    GetConfigOptions = function(self)
        return {
            type = "group",
            name = self.name,
            args = {
                enable = {
                    type = "toggle",
                    name = "Enable",
                    desc = "Enable/disable this plugin",
                    get = function() return self:GetConfig("enabled") end,
                    set = function(_, value) self:SetConfig("enabled", value) end
                },

                format = {
                    type = "select",
                    name = "Format",
                    desc = "Text display format",
                    values = {
                        short = "Short",
                        long = "Long",
                        custom = "Custom"
                    },
                    get = function() return self:GetConfig("format") end,
                    set = function(_, value) self:SetConfig("format", value) end
                }
            }
        }
    end,

    GetDefaultConfig = function(self)
        return {
            enabled = true,
            format = "short",
            updateInterval = 1.0
        }
    end,

    -- Lifecycle methods
    OnInitialize = function(self)
        LibsDataBar.Debug:Log("Initializing " .. self.name, "plugin")
    end,

    OnEnable = function(self)
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnterWorld")
        LibsDataBar.Debug:Log("Enabled " .. self.name, "plugin")
    end,

    OnDisable = function(self)
        self:UnregisterAllEvents()
        LibsDataBar.Debug:Log("Disabled " .. self.name, "plugin")
    end,

    -- Helper methods
    RegisterEvent = function(self, event, method)
        LibsDataBar.events:RegisterEvent(event, self[method] or method, {
            owner = self.id
        })
    end,

    UnregisterEvent = function(self, event)
        LibsDataBar.events:UnregisterEvent(event, self.id)
    end,

    UnregisterAllEvents = function(self)
        LibsDataBar.events:UnregisterAllEvents(self.id)
    end,

    GetConfig = function(self, key)
        return LibsDataBar.config:GetPluginConfig(self.id, key)
    end,

    SetConfig = function(self, key, value)
        return LibsDataBar.config:SetPluginConfig(self.id, key, value)
    end,

    ShowConfigMenu = function(self)
        LibsDataBar.config:ShowPluginConfig(self.id)
    end
}

-- LDB Plugin Template
local LDBPluginTemplate = {
    -- LDB object
    dataObject = {
        type = "data source",
        text = "Plugin Text",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",

        OnClick = function(clickedframe, button)
            if button == "LeftButton" then
                print("Left clicked!")
            end
        end,

        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Plugin Name")
            tooltip:AddLine("Plugin information", 1, 1, 1)
        end
    },

    -- Registration
    OnInitialize = function(self)
        LibStub("LibDataBroker-1.1"):NewDataObject(self.dataObject.name or "MyLDBPlugin", self.dataObject)
    end,

    -- Update methods
    UpdateText = function(self, newText)
        self.dataObject.text = newText
        LibStub("LibDataBroker-1.1"):AttributeChanged(self.dataObject.name, "text", newText)
    end,

    UpdateIcon = function(self, newIcon)
        self.dataObject.icon = newIcon
        LibStub("LibDataBroker-1.1"):AttributeChanged(self.dataObject.name, "icon", newIcon)
    end
}
```

---

## 6. Integration Strategy

### 6.1 SpartanUI Integration

**Seamless SpartanUI Integration:**

```lua
-- SpartanUI Module Integration
SUI.Module:NewModule("DataBar", "AceEvent-3.0")

function SUI.Module.DataBar:OnInitialize()
    -- Initialize LibsDataBar as SpartanUI module
    self.DB = SUI.DB:RegisterModule("DataBar", LibsDataBar.ConfigDefaults)

    -- Create SpartanUI-specific bars
    self:CreateSpartanUIBars()

    -- Register SpartanUI events
    self:RegisterEvent("SUI_THEME_CHANGED", "OnThemeChanged")
    self:RegisterEvent("SUI_PROFILE_CHANGED", "OnProfileChanged")
end

function SUI.Module.DataBar:CreateSpartanUIBars()
    -- Main action bar integration
    local actionBarConfig = {
        id = "spartan_main",
        position = "bottom",
        anchor = {
            relativeTo = "SUI_ActionBar",
            point = "TOP",
            relativePoint = "BOTTOM",
            y = -2
        },
        appearance = {
            theme = SUI.DB.profile.theme or "spartan"
        }
    }

    LibsDataBar:CreateBar(actionBarConfig)

    -- Minimap integration
    local minimapConfig = {
        id = "spartan_minimap",
        position = "custom",
        anchor = {
            relativeTo = "SUI_Minimap",
            point = "BOTTOM",
            relativePoint = "TOP",
            y = 2
        },
        size = {
            width = 200,
            height = 20
        }
    }

    LibsDataBar:CreateBar(minimapConfig)
end

function SUI.Module.DataBar:OnThemeChanged(event, newTheme)
    -- Update all bars to match SpartanUI theme
    for barId, bar in pairs(LibsDataBar:GetBars()) do
        if barId:match("^spartan_") then
            LibsDataBar:ApplyTheme(barId, newTheme)
        end
    end
end
```

### 6.2 Migration and Compatibility

**Comprehensive Migration Framework:**

```lua
---@class MigrationManager
---@field migrators table<string, Migrator> Migration handlers
---@field validators table<string, function> Migration validators
local MigrationManager = {}

---@class TitanPanelMigrator
local TitanPanelMigrator = {}

function TitanPanelMigrator:DetectInstallation()
    return _G.TitanSettings ~= nil
end

function TitanPanelMigrator:MigrateSettings()
    local titanSettings = _G.TitanSettings
    if not titanSettings then return false end

    local migrationReport = {
        success = true,
        bars = 0,
        plugins = 0,
        settings = 0,
        errors = {}
    }

    -- Migrate bars
    if titanSettings.Players then
        for playerKey, playerData in pairs(titanSettings.Players) do
            if playerData.Panel then
                for barName, barData in pairs(playerData.Panel) do
                    local success = self:MigrateBar(barName, barData)
                    if success then
                        migrationReport.bars = migrationReport.bars + 1
                    else
                        table.insert(migrationReport.errors, "Failed to migrate bar: " .. barName)
                    end
                end
            end

            -- Migrate plugin settings
            if playerData.Plugins then
                for pluginId, pluginData in pairs(playerData.Plugins) do
                    local success = self:MigratePlugin(pluginId, pluginData)
                    if success then
                        migrationReport.plugins = migrationReport.plugins + 1
                    else
                        table.insert(migrationReport.errors, "Failed to migrate plugin: " .. pluginId)
                    end
                end
            end
        end
    end

    return migrationReport
end

function TitanPanelMigrator:MigrateBar(titanBarName, titanBarData)
    local barConfig = {
        id = "migrated_" .. titanBarName:lower(),
        enabled = titanBarData.Show or false,
        position = titanBarData.Position or "bottom",

        size = {
            width = 0, -- Full width
            height = titanBarData.Height or 24,
            scale = titanBarData.Scale or 1.0
        },

        appearance = {
            background = {
                texture = titanBarData.Texture or "Interface\\Tooltips\\UI-Tooltip-Background",
                color = {
                    r = (titanBarData.BgColor and titanBarData.BgColor.r) or 0,
                    g = (titanBarData.BgColor and titanBarData.BgColor.g) or 0,
                    b = (titanBarData.BgColor and titanBarData.BgColor.b) or 0,
                    a = (titanBarData.Alpha) or 0.8
                }
            },
            font = {
                family = titanBarData.FontName or "Fonts\\FRIZQT__.TTF",
                size = titanBarData.FontSize or 12
            }
        },

        behavior = {
            autoHide = titanBarData.AutoHide or false,
            combatHide = titanBarData.HideCombat or false,
            strata = titanBarData.Strata or "MEDIUM"
        }
    }

    return LibsDataBar:CreateBar(barConfig) ~= nil
end

function TitanPanelMigrator:MigratePlugin(titanPluginId, titanPluginData)
    -- Map TitanPanel plugin IDs to LibsDataBar equivalents
    local pluginMapping = {
        ["TitanClock"] = "LibsDataBar_Clock",
        ["TitanGold"] = "LibsDataBar_Currency",
        ["TitanPerformance"] = "LibsDataBar_Performance",
        ["TitanLocation"] = "LibsDataBar_Location",
        ["TitanBag"] = "LibsDataBar_Bags",
        ["TitanVolume"] = "LibsDataBar_Volume",
        ["TitanXP"] = "LibsDataBar_Experience"
    }

    local mappedId = pluginMapping[titanPluginId] or titanPluginId

    local pluginConfig = {
        enabled = not (titanPluginData.Disable or false),
        bar = "migrated_main", -- Default to main bar

        display = {
            showIcon = not (titanPluginData.HideIcon or false),
            showText = not (titanPluginData.HideText or false),
            showLabel = titanPluginData.ShowLabelText or false
        },

        behavior = {
            tooltip = not (titanPluginData.HideTooltip or false)
        },

        -- Migrate plugin-specific settings
        pluginSettings = titanPluginData.savedVariables or {}
    }

    return LibsDataBar.config:SetPluginConfig(mappedId, pluginConfig)
end
```

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Months 1-3)

- **Core Library Architecture**

  - Basic LibsDataBar-1.0 library structure
  - Event management system
  - Configuration framework with AceDB
  - Performance monitoring foundation

- **Basic Display Engine**

  - Simple bar creation and management
  - Plugin button system
  - Basic TitanPanel compatibility layer
  - Simple theme support

- **Essential Plugins**
  - Clock, Gold/Currency, Performance, Location
  - Bags, Volume, Experience
  - Basic LibDataBroker adapter

### Phase 2: Advanced Features (Months 4-6)

- **Enhanced Display System**

  - Multiple bar support with flexible positioning
  - Advanced theme engine with custom skin support
  - Animation framework for smooth transitions
  - Drag-and-drop configuration interface

- **Developer Tools**

  - Plugin templates and examples
  - Debugging framework with categorized logging
  - Plugin validator with quality scoring
  - Basic documentation system

- **Migration Tools**
  - Complete TitanPanel settings migration
  - ChocolateBar and Bazooka import tools
  - Configuration backup and restore

### Phase 3: Modern Features (Months 7-9)

- **Performance Optimization**

  - Advanced memory management with object pooling
  - Efficient event batching and throttling
  - Hot-reload system for development
  - Comprehensive performance analytics

- **Advanced Configuration**

  - Profile sharing and import/export
  - Real-time preview of configuration changes
  - Context-sensitive configuration UI
  - Advanced plugin management

- **SpartanUI Integration**
  - Deep integration with SpartanUI themes
  - Automatic positioning relative to SpartanUI elements
  - Unified configuration experience

### Phase 4: Innovation (Months 10-12)

- **Cloud Features**

  - Profile synchronization across characters/realms
  - Community plugin marketplace
  - Plugin rating and review system
  - Automatic plugin updates

- **AI-Powered Features**

  - Smart plugin recommendations based on play style
  - Intelligent bar layout optimization
  - Performance optimization suggestions
  - Contextual plugin show/hide

- **Advanced Integration**
  - Deep integration with popular addons
  - Console and mobile WoW interface support
  - Accessibility features (screen reader, keyboard nav)
  - Advanced data visualization options

---

## 8. Success Metrics and KPIs

### 8.1 Technical Metrics

- **Performance**: <2ms average update time, <50MB memory usage
- **Compatibility**: 100% TitanPanel plugin compatibility
- **Reliability**: <0.1% error rate, 99.9% uptime
- **Code Quality**: 90%+ test coverage, A+ maintainability rating

### 8.2 User Adoption Metrics

- **Downloads**: Target 1M downloads in first year
- **Active Users**: 100K+ monthly active users
- **User Retention**: 80%+ weekly retention rate
- **User Satisfaction**: 4.5+ average rating

### 8.3 Developer Ecosystem Metrics

- **Plugin Development**: 50+ new plugins in first year
- **Developer Satisfaction**: 90%+ positive feedback
- **Documentation Usage**: 10K+ monthly doc page views
- **Community Engagement**: Active Discord with 1K+ members

### 8.4 Competition Metrics

- **Market Share**: 10% of data broker display market by year 2
- **Migration Rate**: 20% of TitanPanel users try LibsDataBar
- **Feature Parity**: Match or exceed all competitor features
- **Innovation Leadership**: First to market with cloud and AI features

---

## Conclusion

LibsDataBar represents an opportunity to modernize the data broker display addon category by combining the best aspects of existing solutions with contemporary development practices and innovative features. The architecture focuses on three core principles:

1. **Performance First** - Efficient, lightweight core with minimal resource usage
2. **Developer Experience** - Rich tools, comprehensive documentation, and modern development practices
3. **User Delight** - Polished interface, intelligent features, and seamless integration

By implementing this architecture, LibsDataBar can challenge TitanPanel's dominance while providing both SpartanUI users and the broader WoW community with a superior data broker display solution that evolves with the game and its players' needs.

The key to success will be executing the migration strategy effectively - making it trivial for existing TitanPanel users to switch while providing clear benefits that justify the change. With careful implementation of this architecture and consistent execution of the roadmap, LibsDataBar can become the new standard for data broker displays in World of Warcraft.
