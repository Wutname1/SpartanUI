---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Clock.lua
LibsDataBar Clock Plugin
Basic time display plugin demonstrating the native plugin interface
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Plugin Definition
---@class ClockPlugin : Plugin
local ClockPlugin = {
	-- Required metadata
	id = 'LibsDataBar_Clock',
	name = 'Clock',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Information',
	description = 'Displays current server time',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_updateInterval = 1.0,
	_lastUpdate = 0,
	_format24Hour = true,
	_showSeconds = false,
	_showDate = false,
}

-- Plugin Configuration Defaults
local clockDefaults = {
	format24Hour = true,
	showSeconds = false,
	showDate = false,
	showRealm = false,
	timeZone = 'server', -- server, local
}

---Required: Get the display text for this plugin
---@return string text Display text
function ClockPlugin:GetText()
	local timeFormat
	if self._format24Hour then
		timeFormat = self._showSeconds and '%H:%M:%S' or '%H:%M'
	else
		timeFormat = self._showSeconds and '%I:%M:%S %p' or '%I:%M %p'
	end

	local timeString = date(timeFormat)

	if self._showDate then
		local dateString = date('%m/%d')
		timeString = dateString .. ' ' .. timeString
	end

	return timeString
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function ClockPlugin:GetIcon()
	return 'Interface\\Icons\\INV_Misc_PocketWatch_01'
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function ClockPlugin:GetTooltip()
	-- Get server time
	local serverTime = GetGameTime()
	local serverHour, serverMinute = floor(serverTime), floor((serverTime - floor(serverTime)) * 60)

	-- Format server time
	local serverTimeStr
	if self._format24Hour then
		serverTimeStr = string.format('%02d:%02d', serverHour, serverMinute)
	else
		local displayHour = serverHour == 0 and 12 or (serverHour > 12 and serverHour - 12 or serverHour)
		local ampm = serverHour < 12 and 'AM' or 'PM'
		serverTimeStr = string.format('%d:%02d %s', displayHour, serverMinute, ampm)
	end

	-- Get local time
	local localTimeFormat = self._format24Hour and '%H:%M' or '%I:%M %p'
	local localTimeStr = date(localTimeFormat)

	local tooltip = string.format('Realm Time: %s\nLocal Time: %s', serverTimeStr, localTimeStr)
	tooltip = tooltip .. '\n\nLeft-click: Toggle 12/24 hour format'
	tooltip = tooltip .. '\nRight-click: Configuration options'
	tooltip = tooltip .. '\nMiddle-click: Toggle seconds display'

	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button ("LeftButton", "RightButton", etc.)
function ClockPlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Toggle 12/24 hour format like a normal data broker plugin
		self._format24Hour = not self._format24Hour
		self:SetConfig('format24Hour', self._format24Hour)
		LibsDataBar:DebugLog('info', 'Clock format toggled to ' .. (self._format24Hour and '24-hour' or '12-hour'))
	elseif button == 'RightButton' then
		-- Show configuration menu (placeholder for Phase 2)
		LibsDataBar:DebugLog('info', 'Clock configuration menu (coming in Phase 2)')
	elseif button == 'MiddleButton' then
		-- Toggle seconds display
		self._showSeconds = not self._showSeconds
		self:SetConfig('showSeconds', self._showSeconds)
		LibsDataBar:DebugLog('info', 'Clock seconds display ' .. (self._showSeconds and 'enabled' or 'disabled'))
	end
end

---Optional: Update callback for time-sensitive plugins
---@param elapsed number Time elapsed since last update
function ClockPlugin:OnUpdate(elapsed)
	self._lastUpdate = self._lastUpdate + elapsed
	if self._lastUpdate >= self._updateInterval then
		self._lastUpdate = 0

		-- Update LDB object if available
		if self._ldbObject and self._ldbObject.UpdateLDB then self._ldbObject:UpdateLDB() end

		-- Fire update event if needed (for legacy compatibility)
		if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
	end
end

---Get configuration options for this plugin
---@return table options AceConfig options table
function ClockPlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			format24Hour = {
				type = 'toggle',
				name = '24-Hour Format',
				desc = 'Use 24-hour time format instead of 12-hour with AM/PM',
				order = 10,
				get = function()
					return self:GetConfig('format24Hour')
				end,
				set = function(_, value)
					self:SetConfig('format24Hour', value)
					self._format24Hour = value
				end,
			},
			showSeconds = {
				type = 'toggle',
				name = 'Show Seconds',
				desc = 'Display seconds in the time',
				order = 20,
				get = function()
					return self:GetConfig('showSeconds')
				end,
				set = function(_, value)
					self:SetConfig('showSeconds', value)
					self._showSeconds = value
				end,
			},
			showDate = {
				type = 'toggle',
				name = 'Show Date',
				desc = 'Display the date along with the time',
				order = 30,
				get = function()
					return self:GetConfig('showDate')
				end,
				set = function(_, value)
					self:SetConfig('showDate', value)
					self._showDate = value
				end,
			},
			timeZone = {
				type = 'select',
				name = 'Time Zone',
				desc = 'Choose which time to display',
				order = 40,
				values = {
					['server'] = 'Server Time',
					['local'] = 'Local Time',
				},
				get = function()
					return self:GetConfig('timeZone')
				end,
				set = function(_, value)
					self:SetConfig('timeZone', value)
					self._timeZone = value
				end,
			},
		},
	}
end

---Get default configuration for this plugin
---@return table defaults Default configuration table
function ClockPlugin:GetDefaultConfig()
	return clockDefaults
end

---Lifecycle: Plugin initialization
function ClockPlugin:OnInitialize()
	-- Load configuration
	self._format24Hour = self:GetConfig('format24Hour')
	self._showSeconds = self:GetConfig('showSeconds')
	self._showDate = self:GetConfig('showDate')
	self._timeZone = self:GetConfig('timeZone')

	LibsDataBar:DebugLog('info', 'Clock plugin initialized')
end

---Lifecycle: Plugin enabled
function ClockPlugin:OnEnable()
	-- Register for events if needed
	LibsDataBar:DebugLog('info', 'Clock plugin enabled')
end

---Lifecycle: Plugin disabled
function ClockPlugin:OnDisable()
	LibsDataBar:DebugLog('info', 'Clock plugin disabled')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function ClockPlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or clockDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function ClockPlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize the plugin
ClockPlugin:OnInitialize()

-- Register as LibDataBroker object for standardized plugin system
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
	local clockLDBObject = LDB:NewDataObject('LibsDataBar_Clock', {
		type = 'data source',
		text = ClockPlugin:GetText(),
		icon = ClockPlugin:GetIcon(),
		label = ClockPlugin.name,

		-- Forward methods to ClockPlugin with database access preserved
		OnClick = function(self, button)
			ClockPlugin:OnClick(button)
		end,

		OnTooltipShow = function(tooltip)
			tooltip:SetText(ClockPlugin:GetTooltip())
		end,

		-- Update method to refresh LDB object
		UpdateLDB = function(self)
			self.text = ClockPlugin:GetText()
			self.icon = ClockPlugin:GetIcon()
		end,
	})

	-- Store reference for updates
	ClockPlugin._ldbObject = clockLDBObject

	LibsDataBar:DebugLog('info', 'Clock plugin registered as LibDataBroker object')
else
	LibsDataBar:DebugLog('error', 'LibDataBroker not available for Clock plugin')
end

-- Return plugin for external access
return ClockPlugin
