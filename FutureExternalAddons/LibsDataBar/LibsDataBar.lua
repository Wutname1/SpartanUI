---@diagnostic disable: duplicate-set-field
--[===[ File: LibsDataBar.lua
LibsDataBar - Next-generation data broker display addon
Core addon implementation using AceAddon-3.0 framework

Combines TitanPanel's ecosystem depth with modern architectural patterns
and performance optimizations for World of Warcraft addons.
--]===]

-- Addon Dependencies
assert(LibStub, 'LibsDataBar requires LibStub')
assert(LibStub:GetLibrary('AceAddon-3.0', true), 'LibsDataBar requires AceAddon-3.0')
assert(LibStub:GetLibrary('AceEvent-3.0', true), 'LibsDataBar requires AceEvent-3.0')
assert(LibStub:GetLibrary('AceTimer-3.0', true), 'LibsDataBar requires AceTimer-3.0')
assert(LibStub:GetLibrary('CallbackHandler-1.0', true), 'LibsDataBar requires CallbackHandler-1.0')

-- Phase 3: LibQTip-1.0 for enhanced tooltips (optional)
local LibQTip = LibStub:GetLibrary('LibQTip-1.0', true)

-- Phase 4: LibSharedMedia-3.0 for theme system (optional)
local LibSharedMedia = LibStub:GetLibrary('LibSharedMedia-3.0', true)

-- Phase 4: Communication libraries for configuration sharing (optional)
local AceComm = LibStub:GetLibrary('AceComm-3.0', true)
local AceSerializer = LibStub:GetLibrary('AceSerializer-3.0', true)

-- Addon Registration with AceAddon-3.0
local LibsDataBar = LibStub('AceAddon-3.0'):NewAddon('LibsDataBar', 'AceEvent-3.0', 'AceTimer-3.0', 'AceBucket-3.0', 'AceConsole-3.0', 'AceComm-3.0')
if not LibsDataBar then return end

-- For backward compatibility, expose as library for existing code
local lib = LibsDataBar

-- Local References for Performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, next = type, next
local tinsert, tremove = tinsert, tremove
local CreateFrame = CreateFrame
local GetTime = GetTime

-- Library Constants
local LIBSDATABAR_VERSION = '1.0.0'
local LIBSDATABAR_DEBUG = false -- Phase 1 debugging complete

-- Architecture Notes:
-- Pure LibDataBroker implementation following KISS principle
-- All plugins register as LDB objects using LDB:NewDataObject()
-- LDBAdapter provides clean interface bridge between LDB and display system
-- Single plugin interface for maximum maintainability

---@class LibsDataBar : AceAddon
---@field version string Addon version
---@field bars table<string, DataBar> Active bars registry
---@field events EventManager Event management system
---@field config ConfigManager Configuration system
---@field performance PerformanceMonitor Performance tracking
---@field themes ThemeManager Theme management
---@field callbacks table CallbackHandler for event system
lib.version = LIBSDATABAR_VERSION
lib.bars = lib.bars or {}

-- Initialize CallbackHandler for event system
lib.callbacks = lib.callbacks or LibStub:GetLibrary('CallbackHandler-1.0'):New(lib)

----------------------------------------------------------------------------------------------------
-- Event Management System
----------------------------------------------------------------------------------------------------

---@class EventManager
---@field eventRegistry table<string, table<function, table>> Event callback registry
---@field batchQueue table<string, table> Batched event queue
---@field updateTimer number Timer for batched updates
---@field throttleRates table<string, number> Event throttling configuration
---@field frame Frame Hidden frame for WoW events
local EventManager = {}
EventManager.__index = EventManager

lib.events = lib.events
	or setmetatable({
		eventRegistry = {},
		batchQueue = {},
		updateTimer = nil,
		throttleRates = {},
		lastThrottleCall = {}, -- Phase 1B: Track last throttle calls
		frame = nil,
	}, EventManager)

function EventManager:Initialize()
	if not self.frame then
		self.frame = CreateFrame('Frame', 'LibsDataBar_EventFrame')
		self.frame:SetScript('OnEvent', function(frame, event, ...)
			self:FireEvent(event, ...)
		end)
	end
end

---Register an event callback with optional configuration
---@param event string Event name
---@param callback function Callback function
---@param options? table Optional configuration (throttle, batch, priority)
function EventManager:RegisterEvent(event, callback, options)
	options = options or {}

	-- Initialize event registry if needed
	if not self.eventRegistry[event] then
		self.eventRegistry[event] = {}
		-- Register with WoW event system for game events
		local gameEvents = {
			'ADDON_LOADED',
			'PLAYER_LOGIN',
			'PLAYER_ENTERING_WORLD',
			'PLAYER_LEAVING_WORLD',
			'ZONE_CHANGED',
			'ZONE_CHANGED_NEW_AREA',
			'PLAYER_MONEY',
			'BAG_UPDATE',
			'UPDATE_BONUS_ACTIONBAR',
		}
		for _, gameEvent in ipairs(gameEvents) do
			if event == gameEvent then
				self.frame:RegisterEvent(event)
				break
			end
		end

		-- Phase 1B: Set up default throttling for high-frequency events
		if event == 'BAG_UPDATE' or event == 'BAG_UPDATE_DELAYED' then
			self.throttleRates[event] = 0.5 -- Bag updates every 0.5s max
		elseif event == 'PLAYER_MONEY' then
			self.throttleRates[event] = 0.2 -- Money updates every 0.2s max
		elseif event == 'UPDATE_EXHAUSTION' or event == 'PLAYER_XP_UPDATE' then
			self.throttleRates[event] = 1.0 -- XP updates every 1s max
		end
	end

	-- Add callback with configuration
	self.eventRegistry[event][callback] = {
		enabled = true,
		throttle = options.throttle,
		batch = options.batch,
		priority = options.priority or 0,
		owner = options.owner,
	}
end

---Unregister an event callback
---@param event string Event name
---@param callback function Callback function
function EventManager:UnregisterEvent(event, callback)
	if self.eventRegistry[event] then
		self.eventRegistry[event][callback] = nil
		-- If no more callbacks, unregister from WoW
		if not next(self.eventRegistry[event]) then
			self.frame:UnregisterEvent(event)
			self.eventRegistry[event] = nil
		end
	end
end

---Fire an event to all registered callbacks
---@param event string Event name
---@param ... any Event arguments
function EventManager:FireEvent(event, ...)
	local callbacks = self.eventRegistry[event]
	if not callbacks then return end

	local args = { ... }

	-- Sort callbacks by priority
	local sortedCallbacks = {}
	for callback, config in pairs(callbacks) do
		if config.enabled then tinsert(sortedCallbacks, { callback, config }) end
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

---Safely call a function with error handling
---@param func function Function to call
---@param ... any Function arguments
---@return boolean success
---@return any result
function EventManager:SafeCall(func, ...)
	local success, result = pcall(func, ...)
	if not success then lib:DebugLog('error', 'Event callback failed: ' .. tostring(result)) end
	return success, result
end

---Add callback to batch queue for later execution
---@param event string Event name
---@param callback function Callback function
---@param args table Event arguments
function EventManager:AddToBatch(event, callback, args)
	local batchKey = event .. '_' .. tostring(callback)
	if not self.batchQueue[batchKey] then
		self.batchQueue[batchKey] = {
			event = event,
			callback = callback,
			args = args,
			count = 1,
		}
	else
		self.batchQueue[batchKey].count = self.batchQueue[batchKey].count + 1
		self.batchQueue[batchKey].args = args -- Use latest args
	end

	-- Schedule batch processing
	if not self.updateTimer then self.updateTimer = C_Timer.NewTimer(0.1, function()
		self:ProcessBatchQueue()
	end) end
end

---Process the batch queue
function EventManager:ProcessBatchQueue()
	for batchKey, batchData in pairs(self.batchQueue) do
		self:SafeCall(batchData.callback, batchData.event, unpack(batchData.args))
	end
	self.batchQueue = {}
	self.updateTimer = nil
end

---Phase 1B: Throttle callback execution to prevent spam
---@param event string Event name
---@param callback function Callback function
---@param args table Event arguments
---@param throttleRate number Throttle rate in seconds
function EventManager:ThrottleCallback(event, callback, args, throttleRate)
	local throttleKey = event .. '_' .. tostring(callback)
	local lastCall = self.lastThrottleCall and self.lastThrottleCall[throttleKey] or 0
	local now = GetTime()

	if now - lastCall >= throttleRate then
		self:SafeCall(callback, event, unpack(args))
		self.lastThrottleCall = self.lastThrottleCall or {}
		self.lastThrottleCall[throttleKey] = now
	end
end

----------------------------------------------------------------------------------------------------
-- Configuration Management
----------------------------------------------------------------------------------------------------

---@class ConfigManager
---@field db table AceDB database
---@field cache table<string, any> Cached configuration values
---@field validators table<string, function> Configuration validators
local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- Configuration Defaults
local configDefaults = {
	profile = {
		version = 1,
		global = {
			theme = 'modern',
			performance = {
				enableProfiler = false,
				updateThrottle = 0.1,
				memoryOptimization = true,
			},
			developer = {
				debugMode = false,
				showPerformanceStats = false,
				enableHotReload = false,
			},
		},
		bars = {
			['*'] = {
				id = '',
				enabled = true,
				position = 'bottom',
				anchor = {
					point = 'BOTTOM',
					relativeTo = 'UIParent',
					relativePoint = 'BOTTOM',
					x = 0,
					y = 0,
				},
				size = {
					width = 0, -- 0 = auto (full screen)
					height = 24,
					scale = 1.0,
				},
				appearance = {
					background = {
						texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
						color = { r = 0, g = 0, b = 0, a = 0.8 },
					},
					border = {
						texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
						color = { r = 1, g = 1, b = 1, a = 1 },
						size = 1,
					},
					font = {
						family = 'Fonts\\FRIZQT__.TTF',
						size = 12,
						flags = '',
						color = { r = 1, g = 1, b = 1, a = 1 },
					},
				},
				behavior = {
					autoHide = false,
					autoHideDelay = 2.0,
					combatHide = false,
					mouseoverShow = true,
					strata = 'MEDIUM',
					level = 1,
				},
				layout = {
					orientation = 'horizontal',
					alignment = 'left',
					spacing = 4,
					padding = { left = 8, right = 8, top = 2, bottom = 2 },
				},
			},
		},
		plugins = {
			['*'] = {
				enabled = true,
				bar = 'main',
				position = 100,
				display = {
					showIcon = true,
					showText = true,
					showLabel = false,
					width = 0,
					iconSize = 16,
					textFormat = 'default',
				},
				behavior = {
					clickThrough = false,
					tooltip = true,
					tooltipAnchor = 'ANCHOR_CURSOR',
				},
				appearance = {
					iconTexture = nil,
					fontOverride = nil,
					colorOverride = nil,
					opacity = 1.0,
				},
				pluginSettings = {},
			},
		},
	},
}

lib.config = lib.config or setmetatable({
	db = nil,
	cache = {},
	validators = {},
}, ConfigManager)

function ConfigManager:Initialize()
	-- Link to the main addon's database instead of creating our own
	self.db = LibsDataBar.db
	if not self.db then
		LibsDataBar:DebugLog('error', 'ConfigManager Initialize called before LibsDataBar database initialization')
		return
	end
	LibsDataBar:DebugLog('info', 'ConfigManager linked to main addon database')
end

---Get configuration value by path
---@param path string Dot-separated configuration path
---@return any value Configuration value
function ConfigManager:GetConfig(path)
	if self.cache[path] then return self.cache[path] end

	if not self.db or not self.db.profile then
		LibsDataBar:DebugLog('warning', 'ConfigManager GetConfig called before database initialization: ' .. tostring(path))
		return nil
	end

	local keys = { strsplit('.', path) }
	local value = self.db.profile

	for _, key in ipairs(keys) do
		if type(value) == 'table' and value[key] ~= nil then
			value = value[key]
		else
			return nil
		end
	end

	self.cache[path] = value
	return value
end

---Set configuration value by path
---@param path string Dot-separated configuration path
---@param value any Value to set
function ConfigManager:SetConfig(path, value)
	if not self.db or not self.db.profile then
		LibsDataBar:DebugLog('warning', 'ConfigManager SetConfig called before database initialization: ' .. tostring(path))
		return
	end

	local keys = { strsplit('.', path) }
	local current = self.db.profile

	-- Navigate to parent table
	for i = 1, #keys - 1 do
		local key = keys[i]
		if type(current[key]) ~= 'table' then current[key] = {} end
		current = current[key]
	end

	-- Set the value
	local finalKey = keys[#keys]
	current[finalKey] = value

	-- Clear cache
	self.cache[path] = nil

	-- Fire configuration change event
	lib.callbacks:Fire('LibsDataBar_ConfigChanged', path, value)
end

----------------------------------------------------------------------------------------------------
-- Performance Monitoring
----------------------------------------------------------------------------------------------------

---@class PerformanceMonitor
---@field enabled boolean Performance tracking enabled
---@field metrics table<string, table> Collected metrics
---@field profilers table<string, table> Active profilers
local PerformanceMonitor = {}
PerformanceMonitor.__index = PerformanceMonitor

lib.performance = lib.performance or setmetatable({
	enabled = LIBSDATABAR_DEBUG,
	metrics = {},
	profilers = {},
}, PerformanceMonitor)

---Record a performance metric
---@param metricName string Metric name
---@param value number Metric value
function PerformanceMonitor:RecordMetric(metricName, value)
	if not self.enabled then return end

	if not self.metrics[metricName] then self.metrics[metricName] = {
		samples = {},
		count = 0,
		total = 0,
		min = value,
		max = value,
	} end

	local metric = self.metrics[metricName]
	metric.count = metric.count + 1
	metric.total = metric.total + value
	metric.min = math.min(metric.min, value)
	metric.max = math.max(metric.max, value)

	-- Keep only last 100 samples
	tinsert(metric.samples, value)
	if #metric.samples > 100 then tremove(metric.samples, 1) end
end

---Start a performance profiler
---@param category string Profiler category
---@return table profiler Profiler object
function PerformanceMonitor:StartProfiler(category)
	if not self.enabled then return {} end

	local profiler = {
		category = category,
		startTime = GetTime(),
		startMemory = gcinfo(),
	}

	self.profilers[category] = profiler
	return profiler
end

---Stop a performance profiler
---@param category string Profiler category
---@return table? result Profile results
function PerformanceMonitor:StopProfiler(category)
	local profiler = self.profilers[category]
	if not profiler then return nil end

	local endTime = GetTime()
	local endMemory = gcinfo()

	local result = {
		category = category,
		executionTime = (endTime - profiler.startTime) * 1000, -- Convert to milliseconds
		memoryDelta = endMemory - profiler.startMemory,
		timestamp = endTime,
	}

	-- Record metrics
	self:RecordMetric(category .. '_execution_time', result.executionTime)
	self:RecordMetric(category .. '_memory_delta', result.memoryDelta)

	self.profilers[category] = nil
	return result
end

----------------------------------------------------------------------------------------------------
-- Core Library API
----------------------------------------------------------------------------------------------------

---Initialize core systems (called from OnInitialize)
function lib:InitializeSystems()
	lib.events:Initialize()
	lib.config:Initialize()
end

-- Phase 4: Enhanced Theme System with LibSharedMedia-3.0 Support
---Initialize enhanced theme system with LibSharedMedia-3.0 integration
function LibsDataBar:InitializeThemeSystem()
	self:DebugLog('info', 'Initializing enhanced theme system...')
	
	-- Initialize theme manager
	self.themes = self.themes or {}
	
	-- Register default LibSharedMedia-3.0 fonts and textures if available
	if LibSharedMedia then
		self:RegisterSharedMediaDefaults()
		self:DebugLog('info', 'LibSharedMedia-3.0 integration enabled')
	end
	
	-- Initialize theme configuration
	self:InitializeThemeDefaults()
	
	-- Apply current theme
	local currentTheme = self.db.profile.appearance.theme or 'default'
	self:ApplyTheme(currentTheme)
end

---Register default fonts and textures with LibSharedMedia-3.0
function LibsDataBar:RegisterSharedMediaDefaults()
	if not LibSharedMedia then return end
	
	-- Register custom fonts for LibsDataBar
	LibSharedMedia:Register('font', 'LibsDataBar Default', [[Interface\AddOns\LibsDataBar\Media\Fonts\Default.ttf]])
	LibSharedMedia:Register('font', 'LibsDataBar Condensed', [[Interface\AddOns\LibsDataBar\Media\Fonts\Condensed.ttf]])
	
	-- Register custom textures for LibsDataBar
	LibSharedMedia:Register('statusbar', 'LibsDataBar Clean', [[Interface\AddOns\LibsDataBar\Media\Textures\Clean.tga]])
	LibSharedMedia:Register('statusbar', 'LibsDataBar Modern', [[Interface\AddOns\LibsDataBar\Media\Textures\Modern.tga]])
	LibSharedMedia:Register('background', 'LibsDataBar Panel', [[Interface\AddOns\LibsDataBar\Media\Textures\Panel.tga]])
end

---Initialize theme defaults and available themes
function LibsDataBar:InitializeThemeDefaults()
	self.themes.available = {
		default = {
			name = 'Default',
			description = 'Clean, minimalist theme',
			font = 'Fonts\\FRIZQT__.TTF',
			fontSize = 12,
			fontFlags = 'OUTLINE',
			texture = [[Interface\TargetingFrame\UI-StatusBar]],
			backgroundColor = {0, 0, 0, 0.8},
			borderColor = {0.5, 0.5, 0.5, 1},
		},
		modern = {
			name = 'Modern',
			description = 'Sleek modern appearance',
			font = 'Fonts\\ARIALN.TTF',
			fontSize = 11,
			fontFlags = 'OUTLINE',
			texture = [[Interface\RaidFrame\Raid-Bar-Hp-Fill]],
			backgroundColor = {0.1, 0.1, 0.1, 0.9},
			borderColor = {0.3, 0.6, 1, 1},
		},
		classic = {
			name = 'Classic',
			description = 'Traditional WoW styling',
			font = 'Fonts\\FRIZQT__.TTF',
			fontSize = 13,
			fontFlags = 'OUTLINE',
			texture = [[Interface\TargetingFrame\UI-StatusBar]],
			backgroundColor = {0.2, 0.1, 0, 0.8},
			borderColor = {0.8, 0.6, 0.2, 1},
		},
	}
	
	-- Add LibSharedMedia fonts and textures to theme options if available
	if LibSharedMedia then
		for themeName, theme in pairs(self.themes.available) do
			theme.sharedMediaFonts = LibSharedMedia:HashTable('font')
			theme.sharedMediaTextures = LibSharedMedia:HashTable('statusbar')
			theme.sharedMediaBackgrounds = LibSharedMedia:HashTable('background')
		end
	end
end

---Apply a theme to all bars and plugins
---@param themeName string Name of theme to apply
function LibsDataBar:ApplyTheme(themeName)
	local theme = self.themes.available[themeName]
	if not theme then
		self:DebugLog('error', 'Theme not found: ' .. tostring(themeName))
		return
	end
	
	self:DebugLog('info', 'Applying theme: ' .. themeName)
	
	-- Store current theme
	self.themes.current = theme
	self.db.profile.appearance.theme = themeName
	
	-- Apply theme to all existing bars
	for barName, bar in pairs(self.bars) do
		self:ApplyThemeToBar(bar, theme)
	end
	
	-- Fire theme changed callback
	self.callbacks:Fire('ThemeChanged', themeName, theme)
end

---Apply theme settings to a specific bar
---@param bar DataBar The bar to apply theme to
---@param theme table Theme configuration
function LibsDataBar:ApplyThemeToBar(bar, theme)
	if not bar or not theme then return end
	
	-- Apply font settings with LibSharedMedia override support
	local fontPath = theme.font
	-- Check for user custom font override first
	if LibSharedMedia and self.db.profile.appearance.customFont then
		fontPath = LibSharedMedia:Fetch('font', self.db.profile.appearance.customFont)
	-- Then check if theme specifies a LibSharedMedia font
	elseif LibSharedMedia and theme.sharedMediaFont then
		fontPath = LibSharedMedia:Fetch('font', theme.sharedMediaFont)
	end
	
	if bar.text then
		bar.text:SetFont(fontPath, theme.fontSize, theme.fontFlags)
	end
	
	-- Apply texture settings with LibSharedMedia override support
	local texturePath = theme.texture
	-- Check for user custom texture override first
	if LibSharedMedia and self.db.profile.appearance.customTexture then
		texturePath = LibSharedMedia:Fetch('statusbar', self.db.profile.appearance.customTexture)
	-- Then check if theme specifies a LibSharedMedia texture
	elseif LibSharedMedia and theme.sharedMediaTexture then
		texturePath = LibSharedMedia:Fetch('statusbar', theme.sharedMediaTexture)
	end
	
	if bar.texture then
		bar.texture:SetTexture(texturePath)
	end
	
	-- Apply colors
	if bar.background then
		local bg = theme.backgroundColor
		bar.background:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
	end
	
	if bar.border then
		local border = theme.borderColor
		bar.border:SetColorTexture(border[1], border[2], border[3], border[4])
	end
end

---Get available themes list
---@return table List of available theme names and descriptions
function LibsDataBar:GetAvailableThemes()
	local themes = {}
	for name, theme in pairs(self.themes.available) do
		themes[name] = {
			name = theme.name,
			description = theme.description
		}
	end
	return themes
end

---Get current theme name
---@return string Current theme name
function LibsDataBar:GetCurrentTheme()
	return self.db.profile.appearance.theme or 'default'
end

---Sync theme with SpartanUI if available
function LibsDataBar:SyncWithSpartanUITheme()
	-- Check if SpartanUI is available
	if not _G.SUI or not _G.SUI.DB or not _G.SUI.DB.profile then
		self:DebugLog('info', 'SpartanUI not found - cannot sync themes')
		return
	end
	
	local suiTheme = _G.SUI.DB.profile.theme
	if not suiTheme then
		self:DebugLog('info', 'SpartanUI theme not found in profile')
		return
	end
	
	-- Map SpartanUI themes to LibsDataBar themes
	local themeMapping = {
		['Classic'] = 'classic',
		['War'] = 'modern',
		['Fel'] = 'modern',
		['Digital'] = 'modern',
		['Default'] = 'default',
	}
	
	local mappedTheme = themeMapping[suiTheme] or 'default'
	
	self:DebugLog('info', 'Syncing with SpartanUI theme: ' .. suiTheme .. ' -> ' .. mappedTheme)
	
	if mappedTheme ~= self:GetCurrentTheme() then
		self:ApplyTheme(mappedTheme)
		self:Print('Theme synced with SpartanUI: ' .. suiTheme)
	end
end

-- Phase 4: Advanced Communication Features
---Initialize communication system for configuration sharing
function LibsDataBar:InitializeCommunication()
	if not AceComm or not AceSerializer then
		self:DebugLog('info', 'Communication libraries not available - configuration sharing disabled')
		return
	end
	
	-- Register communication channel (max 16 characters for AceComm)
	self:RegisterComm('LibsDataBar', 'OnCommReceived')
	self:DebugLog('info', 'Communication system initialized for configuration sharing')
end

---Export current configuration to shareable string
---@return string|nil Encoded configuration string or nil on error
function LibsDataBar:ExportConfiguration()
	if not AceSerializer then
		self:Print('AceSerializer-3.0 not available - cannot export configuration')
		return nil
	end
	
	-- Create export package with essential configuration
	local exportData = {
		version = LIBSDATABAR_VERSION,
		timestamp = time(),
		playerName = UnitName('player'),
		realmName = GetRealmName(),
		appearance = self.db.profile.appearance,
		plugins = {},
		bars = {},
	}
	
	-- Export plugin configurations (only enabled plugins)
	for pluginName, pluginConfig in pairs(self.db.profile.plugins) do
		if pluginConfig.enabled then
			exportData.plugins[pluginName] = {
				enabled = true,
				-- Copy safe configuration values (exclude sensitive data)
				bar = pluginConfig.bar,
				position = pluginConfig.position,
				display = pluginConfig.display,
				behavior = pluginConfig.behavior,
				appearance = pluginConfig.appearance,
			}
		end
	end
	
	-- Export bar configurations
	for barName, barConfig in pairs(self.db.profile.bars) do
		exportData.bars[barName] = {
			enabled = barConfig.enabled,
			anchor = barConfig.anchor,
			size = barConfig.size,
			appearance = barConfig.appearance,
			behavior = barConfig.behavior,
		}
	end
	
	-- Serialize and encode
	local serializedData = AceSerializer:Serialize(exportData)
	local encodedData = LibStub('AceComm-3.0'):Encode(serializedData)
	
	self:DebugLog('info', 'Configuration exported successfully')
	return encodedData
end

---Import configuration from encoded string
---@param encodedData string Encoded configuration string
---@param applyImmediately boolean Whether to apply changes immediately
---@return boolean Success status
function LibsDataBar:ImportConfiguration(encodedData, applyImmediately)
	if not AceSerializer or not encodedData then
		self:Print('Invalid data or AceSerializer-3.0 not available')
		return false
	end
	
	-- Decode and deserialize
	local success, serializedData = LibStub('AceComm-3.0'):Decode(encodedData)
	if not success then
		self:Print('Failed to decode configuration data')
		return false
	end
	
	success, importData = AceSerializer:Deserialize(serializedData)
	if not success or not importData then
		self:Print('Failed to deserialize configuration data')
		return false
	end
	
	-- Validate import data
	if not importData.version or not importData.appearance then
		self:Print('Invalid configuration format')
		return false
	end
	
	-- Show import preview to user
	self:ShowImportPreview(importData, applyImmediately)
	
	return true
end

---Show import preview dialog
---@param importData table Imported configuration data
---@param applyImmediately boolean Whether to apply immediately
function LibsDataBar:ShowImportPreview(importData, applyImmediately)
	local message = string.format(
		'Configuration Import Preview\n\n' ..
		'Source: %s (%s)\n' ..
		'Version: %s\n' ..
		'Theme: %s\n' ..
		'Plugins: %d enabled\n' ..
		'Bars: %d configured\n\n' ..
		'Apply this configuration?',
		importData.playerName or 'Unknown',
		importData.realmName or 'Unknown',
		importData.version or 'Unknown',
		importData.appearance.theme or 'default',
		self:CountTable(importData.plugins or {}),
		self:CountTable(importData.bars or {})
	)
	
	-- For now, just print the preview and apply if requested
	self:Print(message)
	
	if applyImmediately then
		self:ApplyImportedConfiguration(importData)
	else
		-- Store for manual application
		self.pendingImport = importData
		self:Print('Configuration stored. Use /libsdatabar import apply to apply changes.')
	end
end

---Apply imported configuration
---@param importData table Configuration data to apply
function LibsDataBar:ApplyImportedConfiguration(importData)
	if not importData then
		self:Print('No configuration data to apply')
		return
	end
	
	-- Apply appearance settings
	if importData.appearance then
		for key, value in pairs(importData.appearance) do
			self.db.profile.appearance[key] = value
		end
		self:ApplyTheme(self.db.profile.appearance.theme)
	end
	
	-- Apply plugin configurations
	if importData.plugins then
		for pluginName, pluginConfig in pairs(importData.plugins) do
			if not self.db.profile.plugins[pluginName] then
				self.db.profile.plugins[pluginName] = {}
			end
			for key, value in pairs(pluginConfig) do
				self.db.profile.plugins[pluginName][key] = value
			end
		end
	end
	
	-- Apply bar configurations  
	if importData.bars then
		for barName, barConfig in pairs(importData.bars) do
			if not self.db.profile.bars[barName] then
				self.db.profile.bars[barName] = {}
			end
			for key, value in pairs(barConfig) do
				self.db.profile.bars[barName][key] = value
			end
		end
	end
	
	-- Refresh all bars and plugins
	self:RefreshAllBarsAndPlugins()
	
	self:Print('Configuration imported and applied successfully')
	self.pendingImport = nil
end

---Share configuration with guild members
---@param target string|nil Target channel ('GUILD', 'WHISPER', etc.) or nil for guild
function LibsDataBar:ShareConfiguration(target)
	if not AceComm or not AceSerializer then
		self:Print('Communication libraries not available - cannot share configuration')
		return
	end
	
	local exportData = self:ExportConfiguration()
	if not exportData then
		self:Print('Failed to export configuration for sharing')
		return
	end
	
	-- Create sharing message
	local message = {
		action = 'SHARE_CONFIG',
		data = exportData,
		sender = UnitName('player'),
		timestamp = time(),
	}
	
	local serializedMessage = AceSerializer:Serialize(message)
	
	-- Default to guild channel
	target = target or 'GUILD'
	
	self:SendCommMessage('LibsDataBar', serializedMessage, target)
	self:Print('Configuration shared to ' .. target)
end

---Handle received communication messages
---@param prefix string Communication prefix
---@param message string Received message
---@param distribution string Distribution channel
---@param sender string Message sender
function LibsDataBar:OnCommReceived(prefix, message, distribution, sender)
	if prefix ~= 'LibsDataBar' or sender == UnitName('player') then
		return -- Ignore own messages
	end
	
	if not AceSerializer then
		return
	end
	
	-- Deserialize message
	local success, data = AceSerializer:Deserialize(message)
	if not success or not data then
		return
	end
	
	if data.action == 'SHARE_CONFIG' and data.data then
		-- Someone shared their configuration
		self:Print(string.format('%s shared their LibsDataBar configuration. Use /libsdatabar import <data> to import it.', sender))
		-- Could implement automatic import dialog here
	end
end

---Utility function to count table entries
---@param t table Table to count
---@return number Count of entries
function LibsDataBar:CountTable(t)
	local count = 0
	for _ in pairs(t or {}) do
		count = count + 1
	end
	return count
end

---Refresh all bars and plugins after configuration changes
function LibsDataBar:RefreshAllBarsAndPlugins()
	-- Refresh all existing bars
	for barName, bar in pairs(self.bars) do
		if self.db.profile.bars[barName] then
			-- Reapply bar configuration
			self:UpdateBar(barName)
		end
	end
	
	-- Refresh all plugins
	for pluginName, plugin in pairs(self.plugins) do
		if plugin.UpdateDisplay then
			plugin:UpdateDisplay()
		end
	end
	
	-- Apply current theme
	local currentTheme = self.db.profile.appearance.theme or 'default'
	self:ApplyTheme(currentTheme)
end

-- Phase 4: Enhanced Export/Import UI System (Native WoW UI Implementation)
---Create enhanced export/import window similar to SpartanUI
function LibsDataBar:CreateExportImportWindow()
	if self.exportImportFrame then
		self.exportImportFrame:Show()
		return
	end
	
	-- Main Window
	local frame = CreateFrame('Frame', 'LibsDataBarExportImportFrame', UIParent, 'BasicFrameTemplateWithInset')
	frame:SetSize(800, 600)
	frame:SetPoint('CENTER')
	frame:SetFrameStrata('DIALOG')
	frame:SetFrameLevel(100)
	frame.title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	frame.title:SetPoint('TOP', 0, -10)
	frame.title:SetText('LibsDataBar Configuration Manager')
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag('LeftButton')
	frame:SetScript('OnDragStart', frame.StartMoving)
	frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
	
	self.exportImportFrame = frame
	
	-- Mode switching tabs
	local exportTab = CreateFrame('Button', nil, frame, 'TabButtonTemplate')
	exportTab:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 5, 2)
	exportTab:SetText('Export Configuration')
	exportTab:SetWidth(160)
	frame.exportTab = exportTab
	
	local importTab = CreateFrame('Button', nil, frame, 'TabButtonTemplate')
	importTab:SetPoint('LEFT', exportTab, 'RIGHT', 0, 0)
	importTab:SetText('Import Configuration')  
	importTab:SetWidth(160)
	frame.importTab = importTab
	
	-- Content frames
	frame.exportFrame = self:CreateExportFrame(frame)
	frame.importFrame = self:CreateImportFrame(frame)
	
	-- Tab switching logic
	local function switchToExport()
		frame.exportFrame:Show()
		frame.importFrame:Hide()
		PanelTemplates_DeselectTab(importTab)
		PanelTemplates_SelectTab(exportTab)
		frame.mode = 'export'
	end
	
	local function switchToImport()
		frame.exportFrame:Hide()
		frame.importFrame:Show()
		PanelTemplates_DeselectTab(exportTab)
		PanelTemplates_SelectTab(importTab)
		frame.mode = 'import'
	end
	
	exportTab:SetScript('OnClick', switchToExport)
	importTab:SetScript('OnClick', switchToImport)
	
	-- Default to export mode
	switchToExport()
	
	return frame
end

---Create export configuration frame
---@param parent Frame Parent frame
---@return Frame Export frame
function LibsDataBar:CreateExportFrame(parent)
	local frame = CreateFrame('Frame', nil, parent)
	frame:SetPoint('TOPLEFT', 10, -35)
	frame:SetPoint('BOTTOMRIGHT', -10, 10)
	
	-- Left side: Configuration options
	local optionFrame = CreateFrame('Frame', nil, frame, 'InsetFrameTemplate')
	optionFrame:SetPoint('TOPLEFT', 0, 0)
	optionFrame:SetPoint('BOTTOMLEFT', 0, 0)
	optionFrame:SetWidth(250)
	
	local optionTitle = optionFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	optionTitle:SetPoint('TOP', 0, -10)
	optionTitle:SetText('Export Options')
	
	-- Export scope checkboxes
	local yOffset = -40
	local checkboxes = {}
	
	local exportScopes = {
		{key = 'appearance', label = 'Theme & Appearance Settings', desc = 'Current theme, fonts, and visual customizations'},
		{key = 'bars', label = 'Data Bar Configurations', desc = 'Bar positioning, size, and display settings'},
		{key = 'plugins', label = 'Plugin Configurations', desc = 'All plugin settings and enabled states'},
		{key = 'performance', label = 'Performance Settings', desc = 'Update intervals and optimization settings'},
	}
	
	for i, scope in ipairs(exportScopes) do
		local checkbox = CreateFrame('CheckButton', nil, optionFrame, 'ChatConfigCheckButtonTemplate')
		checkbox:SetPoint('TOPLEFT', 15, yOffset)
		checkbox.Text:SetText(scope.label)
		checkbox.Text:SetFontObject('GameFontNormal')
		checkbox:SetChecked(true) -- Default to all selected
		checkbox.scope = scope.key
		checkboxes[scope.key] = checkbox
		
		-- Tooltip
		checkbox:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
			GameTooltip:SetText(scope.label, 1, 1, 1, 1, true)
			GameTooltip:AddLine(scope.desc, 1, 0.8, 0, true)
			GameTooltip:Show()
		end)
		checkbox:SetScript('OnLeave', GameTooltip_Hide)
		
		yOffset = yOffset - 30
	end
	
	frame.exportCheckboxes = checkboxes
	
	-- Select All / Deselect All buttons
	local selectAllBtn = CreateFrame('Button', nil, optionFrame, 'UIPanelButtonTemplate')
	selectAllBtn:SetPoint('TOPLEFT', 15, yOffset - 10)
	selectAllBtn:SetSize(100, 22)
	selectAllBtn:SetText('Select All')
	selectAllBtn:SetScript('OnClick', function()
		for _, cb in pairs(checkboxes) do
			cb:SetChecked(true)
		end
	end)
	
	local deselectAllBtn = CreateFrame('Button', nil, optionFrame, 'UIPanelButtonTemplate')
	deselectAllBtn:SetPoint('LEFT', selectAllBtn, 'RIGHT', 5, 0)
	deselectAllBtn:SetSize(100, 22)
	deselectAllBtn:SetText('Clear All')
	deselectAllBtn:SetScript('OnClick', function()
		for _, cb in pairs(checkboxes) do
			cb:SetChecked(false)
		end
	end)
	
	-- Export button
	local exportBtn = CreateFrame('Button', nil, optionFrame, 'UIPanelButtonTemplate')
	exportBtn:SetPoint('BOTTOM', 0, 15)
	exportBtn:SetSize(120, 25)
	exportBtn:SetText('Generate Export')
	exportBtn:SetScript('OnClick', function()
		self:GenerateConfigurationExport(frame)
	end)
	
	-- Right side: Export text display
	local textFrame = CreateFrame('Frame', nil, frame, 'InsetFrameTemplate')
	textFrame:SetPoint('TOPLEFT', optionFrame, 'TOPRIGHT', 5, 0)
	textFrame:SetPoint('BOTTOMRIGHT', 0, 0)
	
	local textTitle = textFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	textTitle:SetPoint('TOP', 0, -10)
	textTitle:SetText('Exported Configuration')
	
	-- Scrollable text area
	local scrollFrame = CreateFrame('ScrollFrame', nil, textFrame, 'UIPanelScrollFrameTemplate')
	scrollFrame:SetPoint('TOPLEFT', 10, -35)
	scrollFrame:SetPoint('BOTTOMRIGHT', -30, 40)
	
	local editBox = CreateFrame('EditBox', nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject('ChatFontNormal')
	editBox:SetWidth(scrollFrame:GetWidth())
	editBox:SetAutoFocus(false)
	editBox:SetScript('OnEscapePressed', function() editBox:ClearFocus() end)
	scrollFrame:SetScrollChild(editBox)
	
	frame.exportTextBox = editBox
	
	-- Copy button
	local copyBtn = CreateFrame('Button', nil, textFrame, 'UIPanelButtonTemplate')
	copyBtn:SetPoint('BOTTOM', 0, 15)
	copyBtn:SetSize(100, 22)
	copyBtn:SetText('Select All')
	copyBtn:SetScript('OnClick', function()
		editBox:SetFocus()
		editBox:HighlightText()
	end)
	
	return frame
end

---Create import configuration frame
---@param parent Frame Parent frame
---@return Frame Import frame
function LibsDataBar:CreateImportFrame(parent)
	local frame = CreateFrame('Frame', nil, parent)
	frame:SetPoint('TOPLEFT', 10, -35)
	frame:SetPoint('BOTTOMRIGHT', -10, 10)
	
	-- Instructions
	local instructionText = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	instructionText:SetPoint('TOP', 0, -10)
	instructionText:SetText('Paste exported configuration string below:')
	instructionText:SetJustifyH('CENTER')
	
	-- Import text area
	local scrollFrame = CreateFrame('ScrollFrame', nil, frame, 'UIPanelScrollFrameTemplate')
	scrollFrame:SetPoint('TOPLEFT', 10, -35)
	scrollFrame:SetPoint('BOTTOMRIGHT', -30, 120)
	
	local editBox = CreateFrame('EditBox', nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject('ChatFontNormal')
	editBox:SetWidth(scrollFrame:GetWidth())
	editBox:SetAutoFocus(false)
	editBox:SetScript('OnEscapePressed', function() editBox:ClearFocus() end)
	editBox:SetScript('OnTextChanged', function()
		-- Enable preview button when text is entered
		frame.previewBtn:SetEnabled(editBox:GetText():len() > 0)
		frame.importBtn:SetEnabled(false) -- Reset import button
	end)
	scrollFrame:SetScrollChild(editBox)
	
	frame.importTextBox = editBox
	
	-- Preview area
	local previewFrame = CreateFrame('Frame', nil, frame, 'InsetFrameTemplate')
	previewFrame:SetPoint('TOPLEFT', 10, -scrollFrame:GetHeight() - 45)
	previewFrame:SetPoint('BOTTOMRIGHT', -10, 80)
	
	local previewTitle = previewFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	previewTitle:SetPoint('TOP', 0, -10)
	previewTitle:SetText('Import Preview')
	
	local previewText = previewFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	previewText:SetPoint('TOPLEFT', 10, -35)
	previewText:SetPoint('BOTTOMRIGHT', -10, 10)
	previewText:SetJustifyH('LEFT')
	previewText:SetJustifyV('TOP')
	previewText:SetText('Preview will appear here after validation...')
	
	frame.previewText = previewText
	
	-- Buttons
	local previewBtn = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
	previewBtn:SetPoint('BOTTOMLEFT', 10, 15)
	previewBtn:SetSize(120, 25)
	previewBtn:SetText('Validate & Preview')
	previewBtn:SetEnabled(false)
	previewBtn:SetScript('OnClick', function()
		self:PreviewConfigurationImport(frame)
	end)
	frame.previewBtn = previewBtn
	
	local importBtn = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
	importBtn:SetPoint('LEFT', previewBtn, 'RIGHT', 10, 0)
	importBtn:SetSize(100, 25)
	importBtn:SetText('Import')
	importBtn:SetEnabled(false)
	importBtn:SetScript('OnClick', function()
		self:ExecuteConfigurationImport(frame)
	end)
	frame.importBtn = importBtn
	
	local clearBtn = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
	clearBtn:SetPoint('LEFT', importBtn, 'RIGHT', 10, 0)
	clearBtn:SetSize(80, 25)
	clearBtn:SetText('Clear')
	clearBtn:SetScript('OnClick', function()
		editBox:SetText('')
		previewText:SetText('Preview will appear here after validation...')
		previewBtn:SetEnabled(false)
		importBtn:SetEnabled(false)
		frame.validatedImport = nil
	end)
	
	return frame
end

---Generate configuration export based on selected options
---@param exportFrame Frame Export frame with checkboxes
function LibsDataBar:GenerateConfigurationExport(exportFrame)
	local selectedScopes = {}
	
	-- Check which scopes are selected
	for scope, checkbox in pairs(exportFrame.exportCheckboxes) do
		if checkbox:GetChecked() then
			selectedScopes[scope] = true
		end
	end
	
	-- Build export data
	local exportData = {
		version = LIBSDATABAR_VERSION,
		timestamp = time(),
		playerName = UnitName('player'),
		realmName = GetRealmName(),
		scopes = {},
	}
	
	-- Export selected scopes
	if selectedScopes.appearance then
		exportData.scopes.appearance = self.db.profile.appearance
	end
	
	if selectedScopes.bars then
		exportData.scopes.bars = self.db.profile.bars
	end
	
	if selectedScopes.plugins then
		-- Only export enabled plugins
		exportData.scopes.plugins = {}
		for pluginName, pluginConfig in pairs(self.db.profile.plugins) do
			if pluginConfig.enabled then
				exportData.scopes.plugins[pluginName] = {
					enabled = true,
					bar = pluginConfig.bar,
					position = pluginConfig.position,
					display = pluginConfig.display,
					behavior = pluginConfig.behavior,
					appearance = pluginConfig.appearance,
				}
			end
		end
	end
	
	if selectedScopes.performance then
		exportData.scopes.performance = self.db.profile.performance
	end
	
	-- Serialize and encode
	if AceSerializer then
		local serializedData = AceSerializer:Serialize(exportData)
		local encodedData = LibStub('AceComm-3.0'):Encode(serializedData)
		
		exportFrame.exportTextBox:SetText(encodedData)
		exportFrame.exportTextBox:SetFocus()
		exportFrame.exportTextBox:HighlightText()
		
		self:Print('Configuration exported successfully!')
	else
		self:Print('AceSerializer-3.0 not available - cannot export')
	end
end

---Preview configuration import with validation
---@param importFrame Frame Import frame
function LibsDataBar:PreviewConfigurationImport(importFrame)
	local importText = importFrame.importTextBox:GetText()
	
	if not importText or importText:len() == 0 then
		importFrame.previewText:SetText('|cffff0000Error: No import data provided|r')
		return
	end
	
	-- Validate and deserialize
	local success, importData = self:ValidateImportData(importText)
	
	if not success then
		importFrame.previewText:SetText('|cffff0000Error: Invalid import data\n' .. (importData or 'Unknown error') .. '|r')
		importFrame.importBtn:SetEnabled(false)
		return
	end
	
	-- Generate preview text
	local previewLines = {
		'|cff00ff00Import Validation Successful|r',
		'',
		'Source: ' .. (importData.playerName or 'Unknown') .. ' (' .. (importData.realmName or 'Unknown') .. ')',
		'Version: ' .. (importData.version or 'Unknown'),
		'Export Date: ' .. (importData.timestamp and date('%Y-%m-%d %H:%M:%S', importData.timestamp) or 'Unknown'),
		'',
		'Configuration Scopes:',
	}
	
	if importData.scopes then
		for scope, data in pairs(importData.scopes) do
			local count = 0
			if type(data) == 'table' then
				for _ in pairs(data) do count = count + 1 end
			end
			table.insert(previewLines, '  • ' .. scope:gsub('^%l', string.upper) .. ': ' .. count .. ' items')
		end
	end
	
	importFrame.previewText:SetText(table.concat(previewLines, '\n'))
	importFrame.validatedImport = importData
	importFrame.importBtn:SetEnabled(true)
end

---Execute configuration import
---@param importFrame Frame Import frame
function LibsDataBar:ExecuteConfigurationImport(importFrame)
	local importData = importFrame.validatedImport
	
	if not importData then
		self:Print('No validated import data available')
		return
	end
	
	-- Apply imported scopes
	if importData.scopes then
		if importData.scopes.appearance then
			for key, value in pairs(importData.scopes.appearance) do
				self.db.profile.appearance[key] = value
			end
		end
		
		if importData.scopes.bars then
			for barName, barConfig in pairs(importData.scopes.bars) do
				if not self.db.profile.bars[barName] then
					self.db.profile.bars[barName] = {}
				end
				for key, value in pairs(barConfig) do
					self.db.profile.bars[barName][key] = value
				end
			end
		end
		
		if importData.scopes.plugins then
			for pluginName, pluginConfig in pairs(importData.scopes.plugins) do
				if not self.db.profile.plugins[pluginName] then
					self.db.profile.plugins[pluginName] = {}
				end
				for key, value in pairs(pluginConfig) do
					self.db.profile.plugins[pluginName][key] = value
				end
			end
		end
		
		if importData.scopes.performance then
			for key, value in pairs(importData.scopes.performance) do
				self.db.profile.performance[key] = value
			end
		end
	end
	
	-- Refresh everything
	self:RefreshAllBarsAndPlugins()
	
	self:Print('Configuration imported successfully!')
	
	-- Close the window
	self.exportImportFrame:Hide()
end

---Validate import data
---@param importText string Encoded import string
---@return boolean success, table|string data_or_error
function LibsDataBar:ValidateImportData(importText)
	if not AceSerializer then
		return false, 'AceSerializer-3.0 not available'
	end
	
	-- Decode
	local success, serializedData = LibStub('AceComm-3.0'):Decode(importText)
	if not success then
		return false, 'Failed to decode import string'
	end
	
	-- Deserialize
	success, importData = AceSerializer:Deserialize(serializedData)
	if not success or not importData then
		return false, 'Failed to deserialize import data'
	end
	
	-- Validate structure
	if not importData.version then
		return false, 'Missing version information'
	end
	
	if not importData.scopes then
		return false, 'Missing configuration scopes'
	end
	
	return true, importData
end

---Setup default bars and plugins for first-time use
function lib:SetupDefaults()
	self:DebugLog('info', 'Setting up LibsDataBar defaults...')

	-- Create default main bar
	local defaultBarConfig = {
		id = 'main',
		position = 'bottom',
		enabled = true,

		size = {
			width = 0, -- Full width
			height = 24,
			scale = 1.0,
		},

		anchor = {
			x = 0,
			y = 0,
		},

		appearance = {
			background = {
				show = true,
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
				color = { r = 0, g = 0, b = 0, a = 0.8 },
			},
			border = {
				show = false,
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				color = { r = 1, g = 1, b = 1, a = 1 },
				size = 1,
			},
		},

		behavior = {
			autoHide = false,
			combatHide = false,
			strata = 'MEDIUM',
			level = 1,
		},

		layout = {
			orientation = 'horizontal',
			alignment = 'left',
			spacing = 4,
			padding = { left = 8, right = 8, top = 2, bottom = 2 },
		},
	}

	local mainBar = self:CreateBar(defaultBarConfig)
	if mainBar then
		self:DebugLog('info', 'Created default main bar')

		-- Auto-register essential built-in plugins
		self:RegisterBuiltinPlugins(mainBar)
	else
		self:DebugLog('error', 'Failed to create default main bar')
	end
end

---Register LDB plugins and add them to the specified bar
---@param bar DataBar Target bar for plugins
function lib:RegisterBuiltinPlugins(bar)
	-- Pure LDB implementation - direct object handling without adapter
	local registeredCount = 0

	-- Check for LibDataBroker
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if not LDB then
		self:DebugLog('warning', 'LibDataBroker-1.1 not found - no LDB plugins available')
		return
	end

	-- Register callback for new LDB objects
	LDB.RegisterCallback(self, 'LibDataBroker_DataObjectCreated', function(event, name, dataObject)
		self:DebugLog('info', 'New LDB object created: ' .. name)
		if self:IsValidLDBObject(dataObject) then
			-- Create direct LDB plugin object
			local plugin = {
				id = 'LDB_' .. name,
				name = dataObject.label or name,
				version = '1.0.0',
				author = 'LibDataBroker',
				category = 'LibDataBroker',
				description = 'LibDataBroker plugin: ' .. name,
				type = 'ldb', -- Mark as LDB plugin for PluginButton
				ldbObject = dataObject, -- Direct reference to LDB object
				ldbName = name,
			}

			-- Add to bar
			local button = bar:AddPlugin(plugin)
			if button then
				self:DebugLog('info', 'Auto-added new LDB plugin to main bar: ' .. name)
			else
				self:DebugLog('warning', 'Failed to auto-add new LDB plugin to main bar: ' .. name)
			end
		end
	end)

	-- Discover and register existing LDB objects directly
	self:DebugLog('info', 'Starting direct LDB plugin discovery for main bar')
	C_Timer.After(5, function()
		local available = 0

		-- Iterate through all LDB objects
		for name, dataObject in LDB:DataObjectIterator() do
			if self:IsValidLDBObject(dataObject) then
				available = available + 1

				-- Create direct LDB plugin object
				local plugin = {
					id = 'LDB_' .. name,
					name = dataObject.label or name,
					version = '1.0.0',
					author = 'LibDataBroker',
					category = 'LibDataBroker',
					description = 'LibDataBroker plugin: ' .. name,
					type = 'ldb', -- Mark as LDB plugin for PluginButton
					ldbObject = dataObject, -- Direct reference to LDB object
					ldbName = name,
				}

				-- Add to bar
				local button = bar:AddPlugin(plugin)
				if button then
					registeredCount = registeredCount + 1
					self:DebugLog('info', 'Added LDB plugin directly to main bar: ' .. name)
				else
					self:DebugLog('warning', 'Failed to add LDB plugin to main bar: ' .. name)
				end
			end
		end

		self:DebugLog('info', 'Direct LDB Discovery complete: ' .. available .. ' available, ' .. registeredCount .. ' added to main bar')
	end)
end

---Check if an LDB object is valid for registration
---@param dataObject table LDB data object
---@return boolean valid Whether the object is valid
function lib:IsValidLDBObject(dataObject)
	if not dataObject or type(dataObject) ~= 'table' then return false end

	-- Must have either text or label
	if not dataObject.text and not dataObject.label then return false end

	-- Must be a data source
	if dataObject.type ~= 'data source' then return false end

	return true
end

---Create a new data bar
---@param config table Bar configuration
---@return DataBar? bar Created bar or nil if failed
function lib:CreateBar(config)
	if not config or not config.id then
		self:DebugLog('error', 'CreateBar requires config with id')
		return nil
	end

	if self.bars[config.id] then
		self:DebugLog('warning', 'Bar ' .. config.id .. ' already exists')
		return self.bars[config.id]
	end

	-- Use DataBar class if available
	if self.DataBar then
		local bar = self.DataBar:Create(config)
		if bar then
			-- Register the bar in our multi-bar system
			self.bars[config.id] = bar

			-- Apply intelligent positioning if not explicitly set
			if not config.position then
				local position = self:GetOptimalBarPosition()
				local offset = self:CalculateBarOffset(position, config.size and config.size.height or 24)
				bar.config.position = position
				bar.config.anchor.x = offset.x
				bar.config.anchor.y = offset.y
				bar:UpdatePosition()
			end

			-- Fire bar created event
			if self.callbacks then self.callbacks:Fire('LibsDataBar_BarCreated', config.id, bar) end

			self:DebugLog('info', 'DataBar created: ' .. config.id)
			return bar
		end
	else
		self:DebugLog('warning', 'DataBar class not available - display system not loaded')
	end

	return nil
end

---Get optimal position for a new bar based on existing bars
---@return string position Optimal position (top, bottom, left, right)
function lib:GetOptimalBarPosition()
	local positions = {
		bottom = 0,
		top = 0,
		left = 0,
		right = 0,
	}

	-- Count bars at each position
	for _, bar in pairs(self.bars) do
		if bar.config.position and positions[bar.config.position] ~= nil then positions[bar.config.position] = positions[bar.config.position] + 1 end
	end

	-- Find position with least bars
	local minCount = math.huge
	local bestPosition = 'bottom'

	local preferredOrder = { 'bottom', 'top', 'left', 'right' }
	for _, pos in ipairs(preferredOrder) do
		if positions[pos] < minCount then
			minCount = positions[pos]
			bestPosition = pos
		end
	end

	return bestPosition
end

---Calculate intelligent offset for a new bar to avoid collisions
---@param position string Bar position (top, bottom, left, right)
---@param barHeight? number Height of the new bar (default: 24)
---@return table offset {x, y} offset values
function lib:CalculateBarOffset(position, barHeight)
	barHeight = barHeight or 24
	local baseOffset = { x = 0, y = 0 }
	local barSpacing = 4 -- Spacing between bars

	-- Count existing bars at this position
	local barsAtPosition = 0
	for _, bar in pairs(self.bars) do
		if bar.config.position == position then barsAtPosition = barsAtPosition + 1 end
	end

	-- Calculate offset based on position and existing bars
	if position == 'bottom' then
		baseOffset.y = 0 + (barsAtPosition * (barHeight + barSpacing))
	elseif position == 'top' then
		baseOffset.y = 0 - (barsAtPosition * (barHeight + barSpacing))
	elseif position == 'left' then
		baseOffset.x = 0 + (barsAtPosition * (barHeight + barSpacing))
	elseif position == 'right' then
		baseOffset.x = 0 - (barsAtPosition * (barHeight + barSpacing))
	end

	return baseOffset
end

---Update all bar positions to prevent overlaps
function lib:UpdateBarPositions()
	-- Group bars by position
	local barsByPosition = {
		bottom = {},
		top = {},
		left = {},
		right = {},
	}

	for barId, bar in pairs(self.bars) do
		local pos = bar.config.position or 'bottom'
		if barsByPosition[pos] then tinsert(barsByPosition[pos], { id = barId, bar = bar }) end
	end

	-- Update positions with proper spacing
	for position, bars in pairs(barsByPosition) do
		for i, barData in ipairs(bars) do
			local offset = self:CalculateBarOffset(position, barData.bar.config.size.height)
			barData.bar.config.anchor.x = offset.x
			barData.bar.config.anchor.y = offset.y
			barData.bar:UpdatePosition()
		end
	end
end

---Delete a data bar
---@param barId string Bar ID to delete
---@return boolean success Whether deletion was successful
function lib:DeleteBar(barId)
	local bar = self.bars[barId]
	if not bar then
		self:DebugLog('warning', 'Cannot delete bar - not found: ' .. tostring(barId))
		return false
	end

	-- Don't allow deletion of main bar
	if barId == 'main' then
		self:DebugLog('warning', 'Cannot delete main bar')
		return false
	end

	-- Hide and cleanup the bar
	if bar.frame then bar.frame:Hide() end

	-- Remove all plugins from the bar
	if bar.plugins then
		for pluginId, _ in pairs(bar.plugins) do
			bar:RemovePlugin(pluginId)
		end
	end

	-- Fire bar deleted event
	if self.callbacks then self.callbacks:Fire('LibsDataBar_BarDeleted', barId, bar) end

	-- Remove from registry
	self.bars[barId] = nil

	self:DebugLog('info', 'DataBar deleted: ' .. barId)
	return true
end

---Get list of all bar IDs
---@return table barIds Array of bar IDs
function lib:GetBarList()
	local barIds = {}
	for barId, _ in pairs(self.bars) do
		tinsert(barIds, barId)
	end
	return barIds
end

---Get bar by ID
---@param barId string Bar ID
---@return DataBar? bar Bar instance or nil
function lib:GetBar(barId)
	return self.bars[barId]
end

---Move plugin between bars
---@param pluginId string Plugin ID
---@param fromBarId string Source bar ID
---@param toBarId string Target bar ID
---@return boolean success Whether move was successful
function lib:MovePlugin(pluginId, fromBarId, toBarId)
	local fromBar = self.bars[fromBarId]
	local toBar = self.bars[toBarId]

	if not fromBar then
		self:DebugLog('error', 'Source bar not found: ' .. tostring(fromBarId))
		return false
	end

	if not toBar then
		self:DebugLog('error', 'Target bar not found: ' .. toString(toBarId))
		return false
	end

	-- Find plugin in source bar
	local pluginButton = fromBar.plugins[pluginId]
	if not pluginButton or not pluginButton.plugin then
		self:DebugLog('error', 'Plugin not found in source bar: ' .. tostring(pluginId))
		return false
	end

	local plugin = pluginButton.plugin

	-- Remove from source bar
	if not fromBar:RemovePlugin(pluginId) then
		self:DebugLog('error', 'Failed to remove plugin from source bar')
		return false
	end

	-- Add to target bar
	local button = toBar:AddPlugin(plugin)
	if not button then
		self:DebugLog('error', 'Failed to add plugin to target bar')
		-- Try to restore to source bar
		fromBar:AddPlugin(plugin)
		return false
	end

	-- Fire plugin moved event
	if self.callbacks then self.callbacks:Fire('LibsDataBar_PluginMoved', pluginId, fromBarId, toBarId) end

	self:DebugLog('info', 'Plugin moved: ' .. pluginId .. ' from ' .. fromBarId .. ' to ' .. toBarId)
	return true
end

---Create a quick secondary bar with intelligent positioning
---@param barId? string Optional bar ID (auto-generated if not provided)
---@param position? string Optional position override
---@return DataBar? bar Created bar or nil if failed
function lib:CreateQuickBar(barId, position)
	barId = barId or ('bar_' .. (#self:GetBarList() + 1))

	local quickBarConfig = {
		id = barId,
		position = position, -- Will auto-determine if nil
		enabled = true,

		size = {
			width = 0, -- Full width
			height = 20, -- Slightly smaller than main
			scale = 1.0,
		},

		appearance = {
			background = {
				show = false,
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
				color = { r = 0, g = 0, b = 0, a = 0.6 },
			},
			border = {
				show = false,
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				color = { r = 1, g = 1, b = 1, a = 1 },
				size = 1,
			},
		},

		behavior = {
			autoHide = false,
			combatHide = false,
			strata = 'MEDIUM',
			level = 1,
		},

		layout = {
			orientation = 'horizontal',
			alignment = 'center',
			spacing = 4,
			padding = { left = 8, right = 8, top = 2, bottom = 2 },
		},
	}

	local bar = self:CreateBar(quickBarConfig)
	if bar then
		self:DebugLog('info', 'Quick bar created: ' .. barId)

		-- Update all bar positions to prevent overlaps
		self:UpdateBarPositions()
	end

	return bar
end

---Create a new flexible container
---@param config table Container configuration
---@return Container? container Created container or nil if failed
function lib:CreateContainer(config)
	if not config or not config.id then
		self:DebugLog('error', 'CreateContainer requires config with id')
		return nil
	end

	if self.bars[config.id] then
		self:DebugLog('warning', 'Container ' .. config.id .. ' already exists')
		return self.bars[config.id]
	end

	-- Use Container class if available
	if self.Container then
		local container = self.Container:Create(config)
		if container then
			self:DebugLog('info', 'Container created: ' .. config.id .. ' (' .. (config.containerType or 'floating') .. ')')
			return container
		end
	else
		self:DebugLog('warning', 'Container class not available - display system not loaded')
	end

	return nil
end

---Get a data bar by ID
---@param barId string Bar identifier
---@return DataBar? bar Bar object or nil
function lib:GetBar(barId)
	return self.bars[barId]
end

---Get all data bars
---@return table<string, DataBar> bars All registered bars
function lib:GetBars()
	return self.bars
end

---Debug logging function
---@param level string Log level (info, warning, error)
---@param message string Log message
---@param category? string Optional category
function lib:DebugLog(level, message, category)
	if not LIBSDATABAR_DEBUG then return end

	local prefix = '|cFF00FF00LibsDataBar|r'
	local levelColor = level == 'error' and '|cFFFF0000' or level == 'warning' and '|cFFFFFF00' or '|cFFFFFFFF'
	local categoryText = category and ('[' .. category .. '] ') or ''

	print(prefix .. ' ' .. levelColor .. '[' .. level:upper() .. ']|r ' .. categoryText .. message)
end

----------------------------------------------------------------------------------------------------
-- Database Defaults
----------------------------------------------------------------------------------------------------

---Default database structure for AceDB-3.0
local databaseDefaults = {
	profile = {
		displays = {
			bars = {},
			containers = {},
		},
		bars = {
			main = {
				enabled = true,
				size = {
					height = 24,
				},
			},
		},
		plugins = {
			Clock = {
				enabled = true,
				format = 'short',
				showSeconds = false,
				showDate = true,
				use24Hour = false,
				timezone = 'local',
			},
			Currency = {
				enabled = true,
				showIcons = true,
				colorByQuality = true,
				trackAcrossCharacters = false,
			},
			Performance = {
				enabled = true,
				showFPS = true,
				showLatency = true,
				showMemory = true,
				updateInterval = 1.0,
			},
			Location = {
				enabled = true,
				showCoordinates = true,
				showPvPStatus = true,
				showRestingState = true,
			},
			Bags = {
				enabled = true,
				showFreeSlots = true,
				colorBySpace = true,
				includeReagentBag = true,
			},
			Volume = {
				enabled = true,
				showIcons = true,
				compactMode = false,
			},
			Experience = {
				enabled = true,
				showPercentage = true,
				showRested = true,
				autoHideAtMaxLevel = true,
			},
			Repair = {
				enabled = true,
				showPercentage = true,
				warnThreshold = 50,
				showRepairCost = true,
			},
			PlayedTime = {
				enabled = true,
				showTotal = true,
				showSession = true,
				format = 'short',
			},
			Reputation = {
				enabled = true,
				showPercentage = true,
				autoTrack = true,
				showParagon = true,
			},
		},
		appearance = {
			theme = 'default',
			animation = 'fade',
			updateInterval = 1.0,
			-- Phase 4: LibSharedMedia-3.0 integration defaults
			customFont = nil, -- User override for LibSharedMedia fonts
			customTexture = nil, -- User override for LibSharedMedia textures
			syncWithSpartanUI = false, -- Auto-sync with SpartanUI themes
		},
		performance = {
			enableProfiling = false,
			maxUpdateFrequency = 0.1,
			updateInterval = 5.0, -- Phase 1B: Default 5-second refresh interval
		},
	},
}

----------------------------------------------------------------------------------------------------
-- AceAddon-3.0 Lifecycle Callbacks
----------------------------------------------------------------------------------------------------

---Called when the addon is first loaded
function LibsDataBar:OnInitialize()
	self:DebugLog('info', 'LibsDataBar OnInitialize() called')

	-- Phase 2: Initialize AceDB-3.0 database
	local AceDB = LibStub('AceDB-3.0')
	self.db = AceDB:New('LibsDataBarDB', databaseDefaults, true)

	-- Add LibDualSpec-1.0 support for spec-specific configurations
	local LibDualSpec = LibStub('LibDualSpec-1.0', true)
	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.db, 'LibsDataBar')
		self:DebugLog('info', 'LibDualSpec-1.0 support enabled for LibsDataBar')
	end

	-- Create database change callbacks
	self.db.RegisterCallback(self, 'OnProfileChanged', 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileCopied', 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileReset', 'OnProfileChanged')

	-- Initialize core systems
	self:InitializeSystems()
	
	-- Phase 4: Initialize enhanced theme system with LibSharedMedia-3.0
	self:InitializeThemeSystem()
	
	-- Phase 4: Initialize communication system for configuration sharing
	self:InitializeCommunication()

	-- Phase 2: Setup AceConfig-3.0 options
	self:SetupConfigOptions()

	-- Fire library initialization event for backward compatibility
	self.callbacks:Fire('LibsDataBar_Initialized', self)

	if LIBSDATABAR_DEBUG then self:DebugLog('info', 'LibsDataBar-1.0 initialized with AceDB-3.0 and AceConfig-3.0') end
end

---Called when the addon is enabled (PLAYER_LOGIN equivalent)
function LibsDataBar:OnEnable()
	self:DebugLog('info', 'LibsDataBar OnEnable() called')

	-- Register events using AceEvent-3.0
	self:RegisterEvent('ADDON_LOADED')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')

	-- Phase 1B: Implement proper initialization timing with AceTimer-3.0
	-- Schedule initial setup after game data is fully loaded
	self.initTimer = self:ScheduleTimer('InitialSetup', 1.0)
end

---Called when the addon is disabled
function LibsDataBar:OnDisable()
	self:DebugLog('info', 'LibsDataBar OnDisable() called')

	-- Phase 1B: Clean up timers
	if self.initTimer then
		self:CancelTimer(self.initTimer)
		self.initTimer = nil
	end

	if self.refreshTimer then
		self:CancelTimer(self.refreshTimer)
		self.refreshTimer = nil
	end

	if self.pendingUpdateTimer then
		self:CancelTimer(self.pendingUpdateTimer)
		self.pendingUpdateTimer = nil
	end

	-- Phase 3: Clean up enhanced tooltips
	self:HideEnhancedTooltips()

	-- AceEvent-3.0 automatically unregisters events
	self:DebugLog('info', 'LibsDataBar disabled and timers cleaned up')
end

----------------------------------------------------------------------------------------------------
-- Event Handlers (AceEvent-3.0)
----------------------------------------------------------------------------------------------------

---Handle ADDON_LOADED event
function LibsDataBar:ADDON_LOADED(event, addonName)
	-- Currently unused, but ready for future addon-specific handling
	self:DebugLog('info', 'Addon loaded: ' .. tostring(addonName))
end

---Handle PLAYER_ENTERING_WORLD event
function LibsDataBar:PLAYER_ENTERING_WORLD(event)
	-- This can be used for world-specific initialization
	self:DebugLog('info', 'Player entering world')
end

----------------------------------------------------------------------------------------------------
-- Timer Callbacks (AceTimer-3.0)
----------------------------------------------------------------------------------------------------

---Initial setup callback - called once after game data is loaded
function LibsDataBar:InitialSetup()
	self:DebugLog('info', 'InitialSetup timer callback executed')

	-- Call the original setup defaults function
	self:SetupDefaults()

	-- Trigger an immediate update of all bars to display initial data
	self:UpdateAllBars()

	-- Phase 1B: Add periodic refresh system with configurable update intervals
	local updateInterval = self:GetConfig('performance.updateInterval') or 5.0
	self.refreshTimer = self:ScheduleRepeatingTimer('UpdateAllBars', updateInterval)

	-- Clear the init timer reference
	self.initTimer = nil

	-- Phase 1B: Schedule delayed initialization for data-dependent plugins
	self:ScheduleDelayedPluginInit()

	-- Phase 1B: Schedule plugin text display validation
	self:ScheduleTimer('ValidatePluginTextDisplay', 5.0)

	-- Phase 3: Setup AceBucket event throttling for performance
	self:SetupEventBuckets()

	-- Phase 3: Initialize enhanced tooltips system
	self:InitializeTooltipSystem()

	self:DebugLog('info', 'Initial setup completed with periodic refresh every ' .. updateInterval .. 's - bars should now display text')
end

---Phase 1B: Schedule delayed initialization for data-dependent plugins
---Some plugins need game data to be fully loaded before they can display correctly
function LibsDataBar:ScheduleDelayedPluginInit()
	-- Additional delay for plugins that need specific game data
	local dataDelays = {
		{
			delay = 2.0,
			reason = 'currency_data',
			callback = function()
				self:ScheduleUpdate(0.1, 'delayed_currency_init')
			end,
		},
		{
			delay = 3.0,
			reason = 'reputation_data',
			callback = function()
				self:ScheduleUpdate(0.1, 'delayed_reputation_init')
			end,
		},
		{
			delay = 1.5,
			reason = 'location_data',
			callback = function()
				self:ScheduleUpdate(0.1, 'delayed_location_init')
			end,
		},
		{
			delay = 2.5,
			reason = 'friends_data',
			callback = function()
				self:ScheduleUpdate(0.1, 'delayed_friends_init')
			end,
		},
	}

	for _, delayInfo in ipairs(dataDelays) do
		self:ScheduleTimer(function()
			delayInfo.callback()
			self:DebugLog('info', 'Delayed plugin refresh for: ' .. delayInfo.reason)
		end, delayInfo.delay)
	end
end

---Phase 1B: Validate that all plugins are displaying text correctly
---This function checks each plugin to ensure text display is working after initialization
function LibsDataBar:ValidatePluginTextDisplay()
	local validationResults = {
		total = 0,
		working = 0,
		failing = {},
		testTime = GetTime(),
	}

	self:DebugLog('info', 'Starting Phase 1B plugin text display validation...')

	-- Expected plugins that should display text
	local expectedPlugins = {
		'Clock',
		'Currency',
		'Performance',
		'Location',
		'Bags',
		'Volume',
		'Experience',
		'Repair',
		'PlayedTime',
		'Reputation',
		'Friends',
	}

	-- Check each bar for plugin text display
	for barId, bar in pairs(self.bars) do
		if bar and bar.plugins then
			for pluginId, pluginButton in pairs(bar.plugins) do
				validationResults.total = validationResults.total + 1

				-- Check if plugin has text being displayed
				local hasValidText = false
				if pluginButton and pluginButton.textFrame then
					local text = pluginButton.textFrame:GetText()
					if text and text:trim() ~= '' and text ~= 'N/A' and text ~= '???' then
						hasValidText = true
						validationResults.working = validationResults.working + 1
					end
				end

				if not hasValidText then table.insert(validationResults.failing, {
					barId = barId,
					pluginId = pluginId,
					reason = 'No valid text displayed',
				}) end
			end
		end
	end

	-- Report validation results
	local successRate = (validationResults.working / math.max(validationResults.total, 1)) * 100

	if successRate >= 90 then
		self:DebugLog(
			'info',
			'Phase 1B Validation PASSED: ' .. validationResults.working .. '/' .. validationResults.total .. ' plugins displaying text (' .. string.format('%.1f%%', successRate) .. ')'
		)
	else
		self:DebugLog(
			'warning',
			'Phase 1B Validation NEEDS ATTENTION: ' .. validationResults.working .. '/' .. validationResults.total .. ' plugins displaying text (' .. string.format('%.1f%%', successRate) .. ')'
		)

		-- Log specific failures
		for _, failure in ipairs(validationResults.failing) do
			self:DebugLog('warning', 'Plugin text display issue: ' .. failure.pluginId .. ' in bar ' .. failure.barId .. ' - ' .. failure.reason)
		end

		-- Schedule another validation attempt in 10 seconds
		self:ScheduleTimer('ValidatePluginTextDisplay', 10.0)
		self:DebugLog('info', 'Scheduling re-validation in 10 seconds...')
	end

	return validationResults
end

---Phase 3: Setup AceBucket-3.0 event throttling for high-frequency events
function LibsDataBar:SetupEventBuckets()
	-- Check if AceBucket-3.0 is available
	if not self.RegisterBucket then
		self:DebugLog('warning', 'AceBucket-3.0 not available - using fallback event throttling')
		-- Fallback to regular AceEvent with our existing throttling
		self:RegisterEvent('BAG_UPDATE', function() self:ScheduleUpdate(0.5, 'bag_fallback') end)
		self:RegisterEvent('BAG_UPDATE_DELAYED', function() self:ScheduleUpdate(0.5, 'bag_fallback') end)
		self:RegisterEvent('PLAYER_MONEY', function() self:ScheduleUpdate(0.3, 'money_fallback') end)
		self:RegisterEvent('PLAYER_XP_UPDATE', function() self:ScheduleUpdate(1.0, 'xp_fallback') end)
		self:RegisterEvent('UPDATE_EXHAUSTION', function() self:ScheduleUpdate(1.0, 'xp_fallback') end)
		self:RegisterEvent('UPDATE_FACTION', function() self:ScheduleUpdate(2.0, 'reputation_fallback') end)
		self:RegisterEvent('QUEST_TURNED_IN', function() self:ScheduleUpdate(2.0, 'reputation_fallback') end)
		return
	end
	
	-- Register buckets for high-frequency events to batch updates

	-- Bag update bucket - batch bag changes every 0.5 seconds
	self:RegisterBucket('BAG_UPDATE', 0.5, 'LibsDataBar_BagUpdates')
	self:RegisterBucket('BAG_UPDATE_DELAYED', 0.5, 'LibsDataBar_BagUpdates')

	-- Money update bucket - batch currency changes every 0.3 seconds
	self:RegisterBucket('PLAYER_MONEY', 0.3, 'LibsDataBar_MoneyUpdates')

	-- XP update bucket - batch XP changes every 1.0 seconds
	self:RegisterBucket('PLAYER_XP_UPDATE', 1.0, 'LibsDataBar_XPUpdates')
	self:RegisterBucket('UPDATE_EXHAUSTION', 1.0, 'LibsDataBar_XPUpdates')

	-- Reputation update bucket - batch reputation changes every 2.0 seconds
	self:RegisterBucket('UPDATE_FACTION', 2.0, 'LibsDataBar_ReputationUpdates')
	self:RegisterBucket('QUEST_TURNED_IN', 2.0, 'LibsDataBar_ReputationUpdates')

	self:DebugLog('info', 'Phase 3: AceBucket event throttling enabled for performance optimization')
end

---Phase 3: Handle bucketed bag updates
function LibsDataBar:LibsDataBar_BagUpdates()
	self:ScheduleUpdate(0.1, 'bag_bucket')
end

---Phase 3: Handle bucketed money updates
function LibsDataBar:LibsDataBar_MoneyUpdates()
	self:ScheduleUpdate(0.1, 'money_bucket')
end

---Phase 3: Handle bucketed XP updates
function LibsDataBar:LibsDataBar_XPUpdates()
	self:ScheduleUpdate(0.1, 'xp_bucket')
end

---Phase 3: Handle bucketed reputation updates
function LibsDataBar:LibsDataBar_ReputationUpdates()
	self:ScheduleUpdate(0.1, 'reputation_bucket')
end

---Periodic update callback - refreshes all data bar content
function LibsDataBar:UpdateAllBars()
	if not self.bars then
		self:DebugLog('warning', 'UpdateAllBars called but no bars registry found')
		return
	end

	local updateCount = 0
	for barId, bar in pairs(self.bars) do
		if bar and bar.Update then
			-- Safely call bar update with error handling
			local success, errorMsg = pcall(function()
				bar:Update()
			end)

			if success then
				updateCount = updateCount + 1
			else
				self:DebugLog('error', 'Failed to update bar ' .. tostring(barId) .. ': ' .. tostring(errorMsg))
			end
		end
	end

	if LIBSDATABAR_DEBUG then self:DebugLog('info', 'Updated ' .. updateCount .. ' data bars') end
end

---Phase 1B: Enhanced throttled update function for high-frequency events
---@param delay? number Optional delay before update (default based on maxUpdateFrequency)
---@param reason? string Reason for update (for debugging and intelligent throttling)
function LibsDataBar:ScheduleUpdate(delay, reason)
	-- Phase 1B: Intelligent delay based on update reason
	local maxFreq = self:GetConfig('performance.maxUpdateFrequency') or 0.1

	if not delay then
		-- Intelligent throttling based on update reason
		if reason == 'money' or reason == 'currency' then
			delay = 0.2 -- Money updates less frequent
		elseif reason == 'bag' or reason == 'inventory' then
			delay = 0.5 -- Bag updates can be slower
		elseif reason == 'zone' or reason == 'location' then
			delay = 0.1 -- Zone changes need quick response
		else
			delay = maxFreq -- Default throttling
		end
	end

	-- Cancel any pending update to prevent spam
	if self.pendingUpdateTimer then self:CancelTimer(self.pendingUpdateTimer) end

	-- Schedule new update
	self.pendingUpdateTimer = self:ScheduleTimer('UpdateAllBars', delay)

	if LIBSDATABAR_DEBUG and reason then self:DebugLog('info', 'Scheduled update in ' .. delay .. 's for reason: ' .. reason) end
end

----------------------------------------------------------------------------------------------------
-- Configuration System (AceDB-3.0 + AceConfig-3.0)
----------------------------------------------------------------------------------------------------

---Generate plugin configuration options dynamically based on available plugins
---@param pluginArgs table Plugin arguments table to populate
function LibsDataBar:GeneratePluginOptions(pluginArgs)
	-- Safety check for database availability
	if not self.db or not self.db.profile then self:DebugLog('warning', 'Database not ready during plugin options generation - using defaults') end
	-- Plugin configuration based on database defaults
	local pluginConfigs = {
		Clock = {
			name = 'Clock',
			desc = 'Configure clock display settings',
			args = {
				enabled = { type = 'toggle', name = 'Enabled', desc = 'Show/hide clock plugin', order = 1 },
				format = { type = 'select', name = 'Format', desc = 'Time display format', values = { short = 'Short', long = 'Long' }, order = 2 },
				showSeconds = { type = 'toggle', name = 'Show Seconds', desc = 'Display seconds in time', order = 3 },
				showDate = { type = 'toggle', name = 'Show Date', desc = 'Display current date', order = 4 },
				use24Hour = { type = 'toggle', name = '24-Hour Format', desc = 'Use 24-hour time format', order = 5 },
			},
		},
		Currency = {
			name = 'Currency',
			desc = 'Configure currency display settings',
			args = {
				enabled = { type = 'toggle', name = 'Enabled', desc = 'Show/hide currency plugin', order = 1 },
				showIcons = { type = 'toggle', name = 'Show Icons', desc = 'Display currency icons', order = 2 },
				colorByQuality = { type = 'toggle', name = 'Color by Quality', desc = 'Color currency by quality', order = 3 },
			},
		},
		Performance = {
			name = 'Performance',
			desc = 'Configure performance display settings',
			args = {
				enabled = { type = 'toggle', name = 'Enabled', desc = 'Show/hide performance plugin', order = 1 },
				showFPS = { type = 'toggle', name = 'Show FPS', desc = 'Display frames per second', order = 2 },
				showLatency = { type = 'toggle', name = 'Show Latency', desc = 'Display network latency', order = 3 },
				showMemory = { type = 'toggle', name = 'Show Memory', desc = 'Display memory usage', order = 4 },
			},
		},
		Location = {
			name = 'Location',
			desc = 'Configure location display settings',
			args = {
				enabled = { type = 'toggle', name = 'Enabled', desc = 'Show/hide location plugin', order = 1 },
				showCoordinates = { type = 'toggle', name = 'Show Coordinates', desc = 'Display player coordinates', order = 2 },
				showPvPStatus = { type = 'toggle', name = 'Show PvP Status', desc = 'Display PvP zone status', order = 3 },
			},
		},
		Bags = {
			name = 'Bags',
			desc = 'Configure bag space display settings',
			args = {
				enabled = { type = 'toggle', name = 'Enabled', desc = 'Show/hide bags plugin', order = 1 },
				showFreeSlots = { type = 'toggle', name = 'Show Free Slots', desc = 'Display free bag slots', order = 2 },
				colorBySpace = { type = 'toggle', name = 'Color by Space', desc = 'Color by available space', order = 3 },
			},
		},
	}

	-- Generate options for each plugin
	for pluginName, config in pairs(pluginConfigs) do
		pluginArgs[pluginName] = {
			type = 'group',
			name = config.name,
			desc = config.desc,
			order = self:GetPluginOrder(pluginName),
			args = {},
		}

		-- Add each plugin's configuration options
		for optionKey, optionConfig in pairs(config.args) do
			pluginArgs[pluginName].args[optionKey] = {
				type = optionConfig.type,
				name = optionConfig.name,
				desc = optionConfig.desc,
				order = optionConfig.order,
				values = optionConfig.values,
				get = function()
					if self.db and self.db.profile and self.db.profile.plugins and self.db.profile.plugins[pluginName] then return self.db.profile.plugins[pluginName][optionKey] end
					-- Return default from database defaults structure
					local defaults = databaseDefaults.profile.plugins[pluginName]
					return defaults and defaults[optionKey] or false
				end,
				set = function(_, value)
					if self.db and self.db.profile and self.db.profile.plugins then
						-- Ensure plugin section exists
						if not self.db.profile.plugins[pluginName] then self.db.profile.plugins[pluginName] = {} end
						self.db.profile.plugins[pluginName][optionKey] = value
						-- Trigger plugin update
						self:ScheduleUpdate(0.1, 'plugin_config_change')
					end
				end,
			}
		end
	end
end

---Generate dynamic bar configuration options for all existing bars
---@param barArgs table Bar arguments table to populate
function LibsDataBar:GenerateDynamicBarOptions(barArgs)
	-- Safety check for bars registry
	if not self.bars then
		self:DebugLog('warning', 'Bars registry not initialized during dynamic bar options generation')
		return
	end

	-- Get all existing bars and create options for each
	for barId, bar in pairs(self.bars) do
		if barId ~= 'main' then -- Main bar already configured statically
			barArgs[barId] = {
				type = 'group',
				name = 'Bar: ' .. barId,
				desc = 'Configure ' .. barId .. ' data bar',
				order = 10 + tonumber(barId:match('%d+') or 0),
				args = {
					enabled = {
						type = 'toggle',
						name = 'Enable Bar',
						desc = 'Show or hide this data bar',
						get = function()
							return bar and bar.config and bar.config.enabled
						end,
						set = function(_, value)
							if bar and bar.config then
								bar.config.enabled = value
								if value then
									bar:Show()
								else
									bar:Hide()
								end
							end
						end,
						order = 1,
					},
					delete = {
						type = 'execute',
						name = 'Delete Bar',
						desc = 'Remove this data bar',
						func = function()
							self:DeleteBar(barId)
							LibStub('AceConfigRegistry-3.0'):NotifyChange('LibsDataBar')
						end,
						order = 99,
						confirm = true,
						confirmText = 'Are you sure you want to delete this bar?',
					},
				},
			}
		end
	end
end

---Get plugin display order for options
---@param pluginName string Plugin name
---@return number order Display order
function LibsDataBar:GetPluginOrder(pluginName)
	local orderMap = {
		Clock = 1,
		Currency = 2,
		Performance = 3,
		Location = 4,
		Bags = 5,
		Volume = 6,
		Experience = 7,
		Repair = 8,
		PlayedTime = 9,
		Reputation = 10,
		Friends = 11,
	}
	return orderMap[pluginName] or 99
end

---Phase 3: Setup AceConsole-3.0 command system with help and debug commands
function LibsDataBar:SetupConsoleCommands()
	-- Register main command with AceConsole
	self:RegisterChatCommand('libsdatabar', 'HandleChatCommand')
	self:RegisterChatCommand('ldb', 'HandleChatCommand')

	self:DebugLog('info', 'Phase 3: AceConsole-3.0 command system registered')
end

---Phase 3: Handle chat commands with AceConsole-3.0
---@param input string Command input
function LibsDataBar:HandleChatCommand(input)
	local args = { self:GetArgs(input, 10) }
	local command = args[1] and string.lower(args[1]) or ''

	if command == 'config' or command == 'options' or command == '' then
		-- Open configuration panel
		LibStub('AceConfigDialog-3.0'):Open('LibsDataBar')
	elseif command == 'debug' then
		-- Toggle debug mode
		local newState = not LIBSDATABAR_DEBUG
		LIBSDATABAR_DEBUG = newState
		if self.db and self.db.profile then self.db.profile.debug = newState end
		self:Print('Debug mode ' .. (newState and 'enabled' or 'disabled'))
	elseif command == 'reload' or command == 'rl' then
		-- Reload LibsDataBar
		self:Disable()
		self:Enable()
		self:Print('LibsDataBar reloaded')
	elseif command == 'status' then
		-- Show status information
		local bars = self:GetBarList()
		self:Print('LibsDataBar Status:')
		self:Print('- Version: ' .. self.version)
		self:Print('- Active bars: ' .. #bars .. ' (' .. table.concat(bars, ', ') .. ')')
		self:Print('- Debug mode: ' .. (LIBSDATABAR_DEBUG and 'enabled' or 'disabled'))
	elseif command == 'validate' then
		-- Run plugin text display validation
		self:ValidatePluginTextDisplay()
		self:Print('Plugin validation completed - check debug log for results')
	elseif command == 'export' then
		-- Phase 4: Open enhanced export/import UI (Export tab)
		local window = self:CreateExportImportWindow()
		if window and window.exportTab then
			window.exportTab:Click() -- Ensure export tab is selected
		end
	elseif command == 'import' then
		-- Phase 4: Handle import command variants
		local subCommand = args[2] and string.lower(args[2]) or ''
		if subCommand == 'apply' then
			-- Apply pending import (legacy support)
			if self.pendingImport then
				self:ApplyImportedConfiguration(self.pendingImport)
			else
				self:Print('No pending import to apply')
			end
		else
			-- Open enhanced export/import UI (Import tab)
			local window = self:CreateExportImportWindow()
			if window and window.importTab then
				window.importTab:Click() -- Ensure import tab is selected
			end
			
			-- If user provided import data, populate the text field
			local importData = args[2]
			if importData and window and window.importFrame and window.importFrame.importTextBox then
				window.importFrame.importTextBox:SetText(importData)
				window.importFrame.importTextBox:SetFocus()
				-- Trigger validation automatically
				if window.importFrame.previewBtn then
					window.importFrame.previewBtn:SetEnabled(true)
				end
			end
		end
	elseif command == 'share' then
		-- Phase 4: Share configuration with guild
		local target = args[2] and string.upper(args[2]) or 'GUILD'
		self:ShareConfiguration(target)
	elseif command == 'manager' or command == 'configmgr' then
		-- Phase 4: Open enhanced export/import UI
		self:CreateExportImportWindow()
	elseif command == 'help' then
		-- Show command help
		self:Print('LibsDataBar Commands:')
		self:Print('/ldb config - Open configuration panel')
		self:Print('/ldb debug - Toggle debug mode')
		self:Print('/ldb reload - Reload the addon')
		self:Print('/ldb status - Show addon status')
		self:Print('/ldb validate - Run plugin validation')
		self:Print('/ldb export - Open configuration manager (Export tab)')
		self:Print('/ldb import [config] - Open configuration manager (Import tab)')
		self:Print('/ldb import apply - Apply pending import (legacy)')
		self:Print('/ldb share [channel] - Share config (default: GUILD)')
		self:Print('/ldb manager - Open configuration manager')
		self:Print('/ldb help - Show this help')
	else
		self:Print('Unknown command: ' .. command .. '. Type /ldb help for available commands.')
	end
end

---Phase 3: Initialize LibQTip-1.0 enhanced tooltip system
function LibsDataBar:InitializeTooltipSystem()
	if not LibQTip then
		self:DebugLog('warning', 'LibQTip-1.0 not available - using basic tooltips')
		return
	end

	-- Create tooltip registry for cleanup
	self.tooltips = self.tooltips or {}

	self:DebugLog('info', 'Phase 3: Enhanced LibQTip-1.0 tooltip system initialized')
end

---Phase 3: Create enhanced multi-column tooltip for plugins
---@param pluginName string Plugin name
---@param parent Frame Parent frame for tooltip anchor
---@return table|nil tooltip LibQTip tooltip or nil if unavailable
function LibsDataBar:CreateEnhancedTooltip(pluginName, parent)
	if not LibQTip then
		-- Fallback to basic GameTooltip
		return nil
	end

	local tooltipKey = 'LibsDataBar_' .. pluginName

	-- Release existing tooltip
	if self.tooltips[tooltipKey] then
		LibQTip:Release(self.tooltips[tooltipKey])
		self.tooltips[tooltipKey] = nil
	end

	-- Create new enhanced tooltip
	local tooltip = LibQTip:Acquire(tooltipKey, 3, 'LEFT', 'CENTER', 'RIGHT')
	if not tooltip then return nil end

	-- Configure tooltip appearance
	tooltip:SetFrameStrata('TOOLTIP')
	tooltip:SetBackdropBorderColor(1, 1, 1, 1)
	tooltip:SetBackdropColor(0, 0, 0, 0.8)

	-- Add header
	local headerLine = tooltip:AddHeader()
	tooltip:SetCell(headerLine, 1, pluginName .. ' Details', nil, 'CENTER', 3)
	tooltip:AddSeparator()

	-- Store tooltip reference
	self.tooltips[tooltipKey] = tooltip

	return tooltip
end

---Phase 3: Show enhanced tooltip with rich formatting
---@param pluginName string Plugin name
---@param data table Plugin data for display
---@param parent Frame Parent frame for anchoring
function LibsDataBar:ShowEnhancedTooltip(pluginName, data, parent)
	local tooltip = self:CreateEnhancedTooltip(pluginName, parent)
	if not tooltip then
		-- Fallback to basic tooltip
		GameTooltip:SetOwner(parent, 'ANCHOR_CURSOR')
		GameTooltip:SetText(pluginName)
		if data.text then GameTooltip:AddLine(data.text, 1, 1, 1) end
		GameTooltip:Show()
		return
	end

	-- Add plugin-specific rich data
	if pluginName == 'Performance' and data.fps and data.latency and data.memory then
		tooltip:AddLine('FPS:', data.fps, self:GetPerformanceColor(data.fps, 60))
		tooltip:AddLine('Latency:', data.latency .. 'ms', self:GetPerformanceColor(100 - data.latency, 50))
		tooltip:AddLine('Memory:', data.memory, self:GetMemoryColor(data.memory))
	elseif pluginName == 'Currency' and data.gold then
		tooltip:AddLine('Gold:', self:FormatGold(data.gold), '|cFFFFD700')
		if data.session then
			tooltip:AddSeparator()
			tooltip:AddLine('Session:', self:FormatGold(data.session), data.session >= 0 and '|cFF00FF00' or '|cFFFF0000')
		end
	elseif pluginName == 'Location' and data.zone and data.coords then
		tooltip:AddLine('Zone:', data.zone, '|cFF00FFFF')
		tooltip:AddLine('Coordinates:', data.coords, '|cFFFFFFFF')
		if data.pvpStatus then tooltip:AddLine('PvP Status:', data.pvpStatus, '|cFFFF0000') end
	else
		-- Generic data display
		if data.text then tooltip:AddLine('Value:', data.text, '|cFFFFFFFF') end
		if data.status then tooltip:AddLine('Status:', data.status, '|cFF00FF00') end
	end

	-- Add timestamp
	tooltip:AddSeparator()
	local timeText = date('%H:%M:%S')
	tooltip:AddLine('Updated:', timeText, '|cFF888888')

	-- Position and show tooltip
	tooltip:SetAutoHideDelay(0.25, parent)
	tooltip:SmartAnchorTo(parent)
	tooltip:Show()
end

---Phase 3: Get performance-based color coding
---@param value number Performance value
---@param threshold number Good performance threshold
---@return string colorCode Color code string
function LibsDataBar:GetPerformanceColor(value, threshold)
	if value >= threshold then
		return '|cFF00FF00' -- Green
	elseif value >= threshold * 0.7 then
		return '|cFFFFFF00' -- Yellow
	else
		return '|cFFFF0000'
	end -- Red
end

---Phase 3: Get memory usage color coding
---@param memoryString string Memory usage string
---@return string colorCode Color code string
function LibsDataBar:GetMemoryColor(memoryString)
	local memory = tonumber(memoryString:match('%d+')) or 0
	if memory < 50 then
		return '|cFF00FF00' -- Green < 50MB
	elseif memory < 100 then
		return '|cFFFFFF00' -- Yellow < 100MB
	else
		return '|cFFFF0000'
	end -- Red >= 100MB
end

---Phase 3: Format gold with proper separators
---@param copper number Copper amount
---@return string formatted Formatted gold string
function LibsDataBar:FormatGold(copper)
	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper % 10000) / 100)
	copper = copper % 100

	if gold > 0 then
		return string.format('%d|cFFFFD700g|r %02d|cFFC7C7C7s|r %02d|cFFB87333c|r', gold, silver, copper)
	elseif silver > 0 then
		return string.format('%d|cFFC7C7C7s|r %02d|cFFB87333c|r', silver, copper)
	else
		return string.format('%d|cFFB87333c|r', copper)
	end
end

---Phase 3: Hide all enhanced tooltips
function LibsDataBar:HideEnhancedTooltips()
	if not LibQTip then return end

	for key, tooltip in pairs(self.tooltips or {}) do
		LibQTip:Release(tooltip)
		self.tooltips[key] = nil
	end
end

---Setup AceConfig-3.0 options table and register with Settings panel
function LibsDataBar:SetupConfigOptions()
	local options = {
		name = 'LibsDataBar',
		handler = self,
		type = 'group',
		args = {
			general = {
				type = 'group',
				name = 'General',
				order = 1,
				args = {
					enabled = {
						type = 'toggle',
						name = 'Enable LibsDataBar',
						desc = 'Enable or disable the LibsDataBar addon',
						get = function()
							return self.db.profile.enabled
						end,
						set = function(_, value)
							self.db.profile.enabled = value
							if value then
								self:Enable()
							else
								self:Disable()
							end
						end,
						order = 1,
					},
					debug = {
						type = 'toggle',
						name = 'Debug Mode',
						desc = 'Enable debug logging for troubleshooting',
						get = function()
							return self.db.profile.debug
						end,
						set = function(_, value)
							self.db.profile.debug = value
						end,
						order = 2,
					},
					updateInterval = {
						type = 'range',
						name = 'Update Interval',
						desc = 'How often to refresh data bars (in seconds)',
						min = 1.0,
						max = 30.0,
						step = 0.5,
						get = function()
							return self.db.profile.performance.updateInterval
						end,
						set = function(_, value)
							self.db.profile.performance.updateInterval = value
							-- Restart the refresh timer with new interval
							if self.refreshTimer then
								self:CancelTimer(self.refreshTimer)
								self.refreshTimer = self:ScheduleRepeatingTimer('UpdateAllBars', value)
							end
						end,
						order = 3,
					},
				},
			},
			bars = {
				type = 'group',
				name = 'Data Bars',
				order = 2,
				args = {
					main = {
						type = 'group',
						name = 'Main Bar',
						order = 1,
						args = {
							enabled = {
								type = 'toggle',
								name = 'Enable Main Bar',
								desc = 'Show or hide the main data bar',
								get = function()
									return self.db and self.db.profile and self.db.profile.bars and self.db.profile.bars.main and self.db.profile.bars.main.enabled or true
								end,
								set = function(_, value)
									if self.db and self.db.profile and self.db.profile.bars and self.db.profile.bars.main then self.db.profile.bars.main.enabled = value end
								end,
								order = 1,
							},
							height = {
								type = 'range',
								name = 'Bar Height',
								desc = 'Height of the data bar in pixels',
								min = 16,
								max = 64,
								step = 1,
								get = function()
									return self.db
											and self.db.profile
											and self.db.profile.bars
											and self.db.profile.bars.main
											and self.db.profile.bars.main.size
											and self.db.profile.bars.main.size.height
										or 24
								end,
								set = function(_, value)
									if self.db and self.db.profile and self.db.profile.bars and self.db.profile.bars.main and self.db.profile.bars.main.size then
										self.db.profile.bars.main.size.height = value
									end
								end,
								order = 2,
							},
						},
					},
				},
			},
			barManagement = {
				type = 'group',
				name = 'Bar Management',
				order = 3,
				args = {
					createBar = {
						type = 'execute',
						name = 'Create New Bar',
						desc = 'Create a new data bar',
						func = function()
							local newBarId = 'bar_' .. (#self:GetBarList() + 1)
							local bar = self:CreateQuickBar(newBarId)
							if bar then
								self:DebugLog('info', 'Created new bar: ' .. newBarId)
								-- Refresh options to show the new bar
								LibStub('AceConfigRegistry-3.0'):NotifyChange('LibsDataBar')
							end
						end,
						order = 1,
					},
					listBars = {
						type = 'description',
						name = function()
							local bars = self:GetBarList()
							if #bars == 0 then return 'No bars created yet.' end
							return 'Active bars: ' .. table.concat(bars, ', ')
						end,
						order = 2,
					},
				},
			},
		},
		plugins = {
			type = 'group',
			name = 'Plugin Settings',
			order = 3,
			args = {},
		},
		appearance = {
			type = 'group',
			name = 'Appearance & Themes',
			order = 4,
			args = {
				theme = {
					type = 'select',
					name = 'Theme',
					desc = 'Choose the visual theme for all data bars',
					values = function()
						local themes = {}
						if self.themes and self.themes.available then
							for name, theme in pairs(self.themes.available) do
								themes[name] = theme.name .. ' - ' .. theme.description
							end
						end
						return themes
					end,
					get = function()
						return self.db.profile.appearance.theme or 'default'
					end,
					set = function(_, value)
						self.db.profile.appearance.theme = value
						self:ApplyTheme(value)
					end,
					order = 1,
				},
				themePreview = {
					type = 'description',
					name = function()
						local currentTheme = self.db.profile.appearance.theme or 'default'
						local theme = self.themes and self.themes.available and self.themes.available[currentTheme]
						if theme then
							return 'Current Theme: |cff00ff00' .. theme.name .. '|r\n' .. theme.description
						end
						return 'Theme information not available'
					end,
					order = 2,
				},
				separator1 = {
					type = 'description',
					name = '',
					order = 3,
				},
				sharedMediaSection = {
					type = 'header',
					name = LibSharedMedia and 'LibSharedMedia-3.0 Options' or 'LibSharedMedia-3.0 Not Available',
					order = 4,
				},
				customFont = {
					type = 'select',
					name = 'Custom Font',
					desc = 'Override the theme font with a LibSharedMedia font',
					values = function()
						if LibSharedMedia then
							return LibSharedMedia:HashTable('font')
						end
						return {}
					end,
					get = function()
						return self.db.profile.appearance.customFont or 'None'
					end,
					set = function(_, value)
						if value == 'None' then
							self.db.profile.appearance.customFont = nil
						else
							self.db.profile.appearance.customFont = value
						end
						-- Reapply current theme to update fonts
						local currentTheme = self.db.profile.appearance.theme or 'default'
						self:ApplyTheme(currentTheme)
					end,
					disabled = function() return not LibSharedMedia end,
					order = 5,
				},
				customTexture = {
					type = 'select',
					name = 'Custom Status Bar Texture',
					desc = 'Override the theme texture with a LibSharedMedia texture',
					values = function()
						if LibSharedMedia then
							return LibSharedMedia:HashTable('statusbar')
						end
						return {}
					end,
					get = function()
						return self.db.profile.appearance.customTexture or 'None'
					end,
					set = function(_, value)
						if value == 'None' then
							self.db.profile.appearance.customTexture = nil
						else
							self.db.profile.appearance.customTexture = value
						end
						-- Reapply current theme to update textures
						local currentTheme = self.db.profile.appearance.theme or 'default'
						self:ApplyTheme(currentTheme)
					end,
					disabled = function() return not LibSharedMedia end,
					order = 6,
				},
				spartanUIIntegration = {
					type = 'header',
					name = 'SpartanUI Integration',
					order = 7,
				},
				syncWithSpartanUI = {
					type = 'toggle',
					name = 'Sync with SpartanUI Themes',
					desc = 'Automatically match SpartanUI theme changes',
					get = function()
						return self.db.profile.appearance.syncWithSpartanUI or false
					end,
					set = function(_, value)
						self.db.profile.appearance.syncWithSpartanUI = value
						if value then
							-- Try to detect and sync with SpartanUI theme
							self:SyncWithSpartanUITheme()
						end
					end,
					order = 8,
				},
				separator2 = {
					type = 'description',
					name = '',
					order = 9,
				},
				configSharingSection = {
					type = 'header',
					name = 'Configuration Sharing',
					order = 10,
				},
				exportConfig = {
					type = 'execute',
					name = 'Open Configuration Manager',
					desc = 'Open enhanced export/import window with detailed options',
					func = function()
						self:CreateExportImportWindow()
					end,
					order = 11,
				},
				shareToGuild = {
					type = 'execute',
					name = 'Share to Guild',
					desc = 'Share your configuration with guild members',
					func = function()
						self:ShareConfiguration('GUILD')
					end,
					disabled = function() return not AceComm or not AceSerializer end,
					order = 12,
				},
			},
		},
	}

	-- Generate plugin configuration options dynamically (with safety checks)
	if options.args.plugins and options.args.plugins.args then
		self:DebugLog('info', 'Generating plugin options - plugins structure exists')
		self:GeneratePluginOptions(options.args.plugins.args)
		self:DebugLog('info', 'Plugin options generated')
		-- Check if the plugins structure is still intact
		self:DebugLog('info', 'After generation - options.args.plugins type: ' .. type(options.args.plugins))
		if type(options.args.plugins) == 'table' then
			self:DebugLog('info', 'plugins.order after generation: ' .. tostring(options.args.plugins.order))
			self:DebugLog('info', 'plugins.args type after generation: ' .. type(options.args.plugins.args))
		end
	else
		self:DebugLog('error', 'plugins options structure is nil - skipping plugin options generation')
		-- Debug what we have
		if options.args.plugins then
			self:DebugLog('error', 'plugins exists but args is: ' .. type(options.args.plugins.args))
		else
			self:DebugLog('error', 'plugins is: ' .. type(options.args.plugins))
		end
	end

	-- Generate dynamic bar options (with safety checks)
	if options.args.bars and options.args.bars.args then
		self:GenerateDynamicBarOptions(options.args.bars.args)
	else
		self:DebugLog('error', 'bars options structure is nil - skipping dynamic bar options generation')
	end

	-- Debug the options structure before registration
	self:DebugLog('info', 'Options structure before registration:')
	self:DebugLog('info', 'options.args type: ' .. type(options.args))
	self:DebugLog('info', 'options.args.plugins type: ' .. type(options.args.plugins))
	if type(options.args.plugins) == 'table' then
		self:DebugLog('info', 'plugins.args type: ' .. type(options.args.plugins.args))
		self:DebugLog('info', 'plugins.order: ' .. tostring(options.args.plugins.order))
	end

	-- Register the options table with AceConfig
	LibStub('AceConfig-3.0'):RegisterOptionsTable('LibsDataBar', options)

	-- Add to Settings panel
	self.optionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions('LibsDataBar', 'LibsDataBar')

	-- Add AceDBOptions for profile management
	local AceDBOptions = LibStub('AceDBOptions-3.0')
	local profileOptions = AceDBOptions:GetOptionsTable(self.db)

	-- Enhance with LibDualSpec-1.0 if available
	local LibDualSpec = LibStub('LibDualSpec-1.0', true)
	if LibDualSpec then
		LibDualSpec:EnhanceOptions(profileOptions, self.db)
		self:DebugLog('info', 'LibDualSpec-1.0 enhanced profile options')
	end

	LibStub('AceConfig-3.0'):RegisterOptionsTable('LibsDataBar_Profiles', profileOptions)
	LibStub('AceConfigDialog-3.0'):AddToBlizOptions('LibsDataBar_Profiles', 'Profiles', 'LibsDataBar')

	-- Phase 3: Setup AceConsole-3.0 command system
	self:SetupConsoleCommands()

	-- Legacy slash commands for compatibility
	SLASH_LIBSDATABAR1 = '/libsdatabar'
	SLASH_LIBSDATABAR2 = '/ldb'
	SlashCmdList['LIBSDATABAR'] = function(msg)
		LibStub('AceConfigDialog-3.0'):Open('LibsDataBar')
	end

	self:DebugLog('info', 'Configuration options and slash commands registered')
end

---Handle profile changes from AceDB
function LibsDataBar:OnProfileChanged()
	self:DebugLog('info', 'Profile changed - refreshing configuration')

	-- Update debug logging based on new profile
	LIBSDATABAR_DEBUG = self.db.profile.debug

	-- Refresh all bars with new settings
	self:ScheduleUpdate(0.1)
end

---Get configuration value from database
---@param path string Dot-separated path to config value
---@return any value The configuration value
function LibsDataBar:GetConfig(path)
	-- Handle case where database isn't initialized yet
	if not self.db or not self.db.profile then
		self:DebugLog('warning', 'GetConfig called before database initialization: ' .. tostring(path))
		return nil
	end

	local keys = { strsplit('.', path) }
	local value = self.db.profile

	for _, key in ipairs(keys) do
		if type(value) == 'table' and value[key] ~= nil then
			value = value[key]
		else
			return nil
		end
	end

	return value
end

---Set configuration value in database
---@param path string Dot-separated path to config value
---@param value any The value to set
function LibsDataBar:SetConfig(path, value)
	-- Handle case where database isn't initialized yet
	if not self.db or not self.db.profile then
		self:DebugLog('warning', 'SetConfig called before database initialization: ' .. tostring(path))
		return
	end

	local keys = { strsplit('.', path) }
	local config = self.db.profile

	-- Navigate to parent table
	for i = 1, #keys - 1 do
		local key = keys[i]
		if type(config[key]) ~= 'table' then config[key] = {} end
		config = config[key]
	end

	-- Set the value
	config[keys[#keys]] = value

	-- Fire change callback for real-time updates
	self.callbacks:Fire('ConfigChanged', path, value)
end

-- For backward compatibility, maintain library interface
-- This allows existing code to continue working while we migrate
_G.LibsDataBar = LibsDataBar
return LibsDataBar
