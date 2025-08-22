---@diagnostic disable: duplicate-set-field
--[===[ File: LibsDataBar.lua
LibsDataBar - Next-generation data broker display addon
Core library implementation based on the architecture design document

Combines TitanPanel's ecosystem depth with modern architectural patterns
and performance optimizations for World of Warcraft addons.
--]===]

-- Library Dependencies
assert(LibStub, 'LibsDataBar-1.0 requires LibStub')
assert(LibStub:GetLibrary('CallbackHandler-1.0', true), 'LibsDataBar-1.0 requires CallbackHandler-1.0')

-- Library Registration with LibStub
local lib, oldminor = LibStub:NewLibrary('LibsDataBar-1.0', 1)
if not lib then return end
oldminor = oldminor or 0

-- Local References for Performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, next = type, next
local tinsert, tremove = tinsert, tremove
local CreateFrame = CreateFrame
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown

-- Library Constants
local LIBSDATABAR_VERSION = '1.0.0'
local LIBSDATABAR_DEBUG = false -- Phase 1 debugging complete

-- Architecture Notes:
-- Pure LibDataBroker implementation following KISS principle
-- All plugins register as LDB objects using LDB:NewDataObject()
-- LDBAdapter provides clean interface bridge between LDB and display system
-- Single plugin interface for maximum maintainability

---@class LibsDataBar
---@field version string Library version
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

lib.events = lib.events or setmetatable({
	eventRegistry = {},
	batchQueue = {},
	updateTimer = nil,
	throttleRates = {},
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
	-- Initialize AceDB when available
	if LibStub:GetLibrary('AceDB-3.0', true) then
		local AceDB = LibStub('AceDB-3.0')
		self.db = AceDB:New('LibsDataBarDB', configDefaults, true)
	else
		-- Fallback to simple table
		self.db = { profile = configDefaults.profile }
	end
end

---Get configuration value by path
---@param path string Dot-separated configuration path
---@return any value Configuration value
function ConfigManager:GetConfig(path)
	if self.cache[path] then return self.cache[path] end

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

---Initialize the LibsDataBar library
function lib:Initialize()
	lib.events:Initialize()
	lib.config:Initialize()

	-- Fire library initialization event
	lib.callbacks:Fire('LibsDataBar_Initialized', self)

	if LIBSDATABAR_DEBUG then self:DebugLog('info', 'LibsDataBar-1.0 initialized successfully') end
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

-- Initialize library on load
lib:Initialize()

-- Setup startup event handling
local startupFrame = CreateFrame('Frame')
startupFrame:RegisterEvent('ADDON_LOADED')
startupFrame:RegisterEvent('PLAYER_LOGIN')

startupFrame:SetScript('OnEvent', function(self, event, ...)
	if event == 'ADDON_LOADED' then
		local addonName = ...
		-- Wait for all addons to load, then setup on player login
		return
	elseif event == 'PLAYER_LOGIN' then
		-- Small delay to ensure everything is ready
		C_Timer.After(0.5, function()
			lib:SetupDefaults()
		end)
		self:UnregisterAllEvents()
	end
end)

-- Export library
return lib
