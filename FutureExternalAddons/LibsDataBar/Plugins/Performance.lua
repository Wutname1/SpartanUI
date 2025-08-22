---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Performance.lua
LibsDataBar Performance Plugin
Displays FPS, latency, and memory usage information
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Plugin Definition
---@class PerformancePlugin : Plugin
local PerformancePlugin = {
	-- Required metadata
	id = 'LibsDataBar_Performance',
	name = 'Performance',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'System',
	description = 'Displays FPS, latency, and memory usage',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_updateInterval = 2.0,
	_lastUpdate = 0,
	_currentFPS = 0,
	_currentLatency = 0,
	_currentMemory = 0,
}

-- Plugin Configuration Defaults
local performanceDefaults = {
	showFPS = true,
	showLatency = true,
	showMemory = true,
	memoryUnits = 'MB', -- MB, KB
	shortFormat = true,
	colorByPerformance = true,
}

---Required: Get the display text for this plugin
---@return string text Display text
function PerformancePlugin:GetText()
	local parts = {}
	local colorByPerformance = self:GetConfig('colorByPerformance')
	local shortFormat = self:GetConfig('shortFormat')

	-- FPS Display
	if self:GetConfig('showFPS') then
		local fps = GetFramerate()
		local fpsText = string.format('%.0f', fps)

		if colorByPerformance then
			if fps >= 60 then
				fpsText = '|cFF00FF00' .. fpsText .. '|r' -- Green for good FPS
			elseif fps >= 30 then
				fpsText = '|cFFFFFF00' .. fpsText .. '|r' -- Yellow for moderate FPS
			else
				fpsText = '|cFFFF0000' .. fpsText .. '|r' -- Red for poor FPS
			end
		end

		tinsert(parts, fpsText .. (shortFormat and '' or ' fps'))
	end

	-- Latency Display
	if self:GetConfig('showLatency') then
		local _, _, latency = GetNetStats()
		local latencyText = string.format('%dms', latency or 0)

		if colorByPerformance then
			if latency <= 50 then
				latencyText = '|cFF00FF00' .. latencyText .. '|r' -- Green for low latency
			elseif latency <= 100 then
				latencyText = '|cFFFFFF00' .. latencyText .. '|r' -- Yellow for moderate latency
			else
				latencyText = '|cFFFF0000' .. latencyText .. '|r' -- Red for high latency
			end
		end

		tinsert(parts, latencyText)
	end

	-- Memory Display
	if self:GetConfig('showMemory') then
		local memory = gcinfo()
		local memoryText

		if self:GetConfig('memoryUnits') == 'MB' then
			memoryText = string.format('%.1fMB', memory / 1024)
		else
			memoryText = string.format('%.0fKB', memory)
		end

		if colorByPerformance then
			if memory < 50 * 1024 then -- Less than 50MB
				memoryText = '|cFF00FF00' .. memoryText .. '|r' -- Green
			elseif memory < 100 * 1024 then -- Less than 100MB
				memoryText = '|cFFFFFF00' .. memoryText .. '|r' -- Yellow
			else
				memoryText = '|cFFFF0000' .. memoryText .. '|r' -- Red
			end
		end

		tinsert(parts, memoryText)
	end

	return table.concat(parts, ' | ')
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function PerformancePlugin:GetIcon()
	return 'Interface\\Icons\\INV_Misc_EngGizmos_swissArmy'
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function PerformancePlugin:GetTooltip()
	local fps = GetFramerate()
	local _, _, latency = GetNetStats()
	local memory = gcinfo()

	local tooltip = 'Performance Information:\n\n'

	-- Detailed FPS info
	tooltip = tooltip .. string.format('Frame Rate: %.1f FPS\n', fps)
	if fps >= 60 then
		tooltip = tooltip .. '|cFF00FF00Excellent performance|r\n'
	elseif fps >= 30 then
		tooltip = tooltip .. '|cFFFFFF00Good performance|r\n'
	else
		tooltip = tooltip .. '|cFFFF0000Poor performance|r\n'
	end

	-- Detailed latency info
	tooltip = tooltip .. string.format('\nLatency: %d ms\n', latency or 0)
	if latency and latency <= 50 then
		tooltip = tooltip .. '|cFF00FF00Excellent connection|r\n'
	elseif latency and latency <= 100 then
		tooltip = tooltip .. '|cFFFFFF00Good connection|r\n'
	else
		tooltip = tooltip .. '|cFFFF0000Poor connection|r\n'
	end

	-- Detailed memory info
	tooltip = tooltip .. string.format('\nMemory Usage: %.2f MB (%.0f KB)\n', memory / 1024, memory)

	-- LibsDataBar specific memory
	local ldbMemory = GetAddOnMemoryUsage('LibsDataBar') or 0
	if ldbMemory > 0 then tooltip = tooltip .. string.format('LibsDataBar: %.2f KB\n', ldbMemory) end

	tooltip = tooltip .. '\nLeft-click: Toggle FPS display'
	tooltip = tooltip .. '\nRight-click: Configuration options'
	tooltip = tooltip .. '\nMiddle-click: Force garbage collection'

	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function PerformancePlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Toggle FPS display
		local showFPS = not self:GetConfig('showFPS')
		self:SetConfig('showFPS', showFPS)
		LibsDataBar:DebugLog('info', 'Performance FPS display ' .. (showFPS and 'enabled' or 'disabled'))
	elseif button == 'RightButton' then
		-- Show configuration menu (placeholder)
		LibsDataBar:DebugLog('info', 'Performance configuration menu (coming in Phase 2)')
	elseif button == 'MiddleButton' then
		-- Force garbage collection
		local beforeGC = gcinfo()
		collectgarbage('collect')
		local afterGC = gcinfo()
		local freed = beforeGC - afterGC
		LibsDataBar:DebugLog('info', string.format('Garbage collection freed %.2f KB', freed))
	end
end

---Optional: Update callback
---@param elapsed number Time elapsed since last update
function PerformancePlugin:OnUpdate(elapsed)
	self._lastUpdate = self._lastUpdate + elapsed
	if self._lastUpdate >= self._updateInterval then
		-- Cache current values
		self._currentFPS = GetFramerate()
		local _, _, latency = GetNetStats()
		self._currentLatency = latency or 0
		self._currentMemory = gcinfo()

		self._lastUpdate = 0

		-- Fire update event
		if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
	end
end

---Get configuration options
---@return table options AceConfig options table
function PerformancePlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			showFPS = {
				type = 'toggle',
				name = 'Show FPS',
				desc = 'Display current frame rate',
				order = 10,
				get = function()
					return self:GetConfig('showFPS')
				end,
				set = function(_, value)
					self:SetConfig('showFPS', value)
				end,
			},
			showLatency = {
				type = 'toggle',
				name = 'Show Latency',
				desc = 'Display network latency',
				order = 20,
				get = function()
					return self:GetConfig('showLatency')
				end,
				set = function(_, value)
					self:SetConfig('showLatency', value)
				end,
			},
			showMemory = {
				type = 'toggle',
				name = 'Show Memory',
				desc = 'Display memory usage',
				order = 30,
				get = function()
					return self:GetConfig('showMemory')
				end,
				set = function(_, value)
					self:SetConfig('showMemory', value)
				end,
			},
			memoryUnits = {
				type = 'select',
				name = 'Memory Units',
				desc = 'Choose memory display units',
				order = 40,
				values = {
					KB = 'Kilobytes (KB)',
					MB = 'Megabytes (MB)',
				},
				get = function()
					return self:GetConfig('memoryUnits')
				end,
				set = function(_, value)
					self:SetConfig('memoryUnits', value)
				end,
			},
			colorByPerformance = {
				type = 'toggle',
				name = 'Color by Performance',
				desc = 'Use colors to indicate performance levels',
				order = 50,
				get = function()
					return self:GetConfig('colorByPerformance')
				end,
				set = function(_, value)
					self:SetConfig('colorByPerformance', value)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function PerformancePlugin:GetDefaultConfig()
	return performanceDefaults
end

---Lifecycle: Plugin initialization
function PerformancePlugin:OnInitialize()
	self._currentFPS = GetFramerate()
	local _, _, latency = GetNetStats()
	self._currentLatency = latency or 0
	self._currentMemory = gcinfo()

	LibsDataBar:DebugLog('info', 'Performance plugin initialized')
end

---Lifecycle: Plugin enabled
function PerformancePlugin:OnEnable()
	LibsDataBar:DebugLog('info', 'Performance plugin enabled')
end

---Lifecycle: Plugin disabled
function PerformancePlugin:OnDisable()
	LibsDataBar:DebugLog('info', 'Performance plugin disabled')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function PerformancePlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or performanceDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function PerformancePlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize and register the plugin
PerformancePlugin:OnInitialize()

-- Register with LibsDataBar
if LibsDataBar:RegisterPlugin(PerformancePlugin) then
	LibsDataBar:DebugLog('info', 'Performance plugin registered successfully')
else
	LibsDataBar:DebugLog('error', 'Failed to register Performance plugin')
end

-- Return plugin for external access
return PerformancePlugin
