---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Experience.lua
LibsDataBar Experience Plugin
Displays character experience, level progress, and XP information
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Plugin Definition
---@class ExperiencePlugin : Plugin
local ExperiencePlugin = {
	-- Required metadata
	id = 'LibsDataBar_Experience',
	name = 'Experience',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Character',
	description = 'Displays character experience and level progress',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_currentXP = 0,
	_maxXP = 0,
	_restXP = 0,
	_level = 1,
	_percentComplete = 0,
	_isMaxLevel = false,
	_xpPerHour = 0,
	_sessionXP = 0,
	_sessionStartTime = 0,
}

-- Plugin Configuration Defaults
local experienceDefaults = {
	displayFormat = 'percent', -- 'percent', 'current', 'remaining', 'time', 'custom'
	showRested = true,
	showLevel = true,
	showMaxLevel = true,
	colorByRested = true,
	showXPPerHour = false,
	showTimeToLevel = false,
	abbreviateNumbers = true,
	showSessionGains = true,
	trackPlaytime = true,
}

---Required: Get the display text for this plugin
---@return string text Display text
function ExperiencePlugin:GetText()
	local displayFormat = self:GetConfig('displayFormat')
	local showLevel = self:GetConfig('showLevel')
	local colorByRested = self:GetConfig('colorByRested')

	self:UpdateExperienceData()

	if self._isMaxLevel then
		if self:GetConfig('showMaxLevel') then
			local text = 'Max Level'
			if showLevel then text = string.format('Level %d (Max)', self._level) end
			return '|cFFFFD700' .. text .. '|r' -- Gold color for max level
		else
			return '' -- Hide at max level
		end
	end

	local text = ''
	local prefix = showLevel and ('L' .. self._level .. ': ') or ''

	if displayFormat == 'percent' then
		text = string.format('%s%.1f%%', prefix, self._percentComplete)
	elseif displayFormat == 'current' then
		local current = self:GetConfig('abbreviateNumbers') and self:AbbreviateNumber(self._currentXP) or tostring(self._currentXP)
		local max = self:GetConfig('abbreviateNumbers') and self:AbbreviateNumber(self._maxXP) or tostring(self._maxXP)
		text = string.format('%s%s/%s', prefix, current, max)
	elseif displayFormat == 'remaining' then
		local remaining = self._maxXP - self._currentXP
		local remainingText = self:GetConfig('abbreviateNumbers') and self:AbbreviateNumber(remaining) or tostring(remaining)
		text = string.format('%s%s to go', prefix, remainingText)
	elseif displayFormat == 'time' then
		if self._xpPerHour > 0 then
			local hoursToLevel = (self._maxXP - self._currentXP) / self._xpPerHour
			text = string.format('%s%s', prefix, self:FormatTime(hoursToLevel * 3600))
		else
			text = prefix .. 'Unknown'
		end
	else
		-- Default to percent
		text = string.format('%s%.1f%%', prefix, self._percentComplete)
	end

	-- Apply color coding based on rested XP
	if colorByRested and not self._isMaxLevel then
		if self._restXP > 0 then
			text = '|cFF00D4FF' .. text .. '|r' -- Light blue for rested
		else
			text = '|cFFFFFFFF' .. text .. '|r' -- White for normal
		end
	end

	return text
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function ExperiencePlugin:GetIcon()
	if self._isMaxLevel then
		return 'Interface\\Icons\\Achievement_Level_85' -- Max level achievement
	elseif self._restXP > 0 then
		return 'Interface\\Icons\\Spell_Nature_Regeneration' -- Rested XP
	else
		return 'Interface\\Icons\\INV_Misc_Book_11' -- Normal XP
	end
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function ExperiencePlugin:GetTooltip()
	self:UpdateExperienceData()

	local tooltip = string.format('Character Experience - Level %d\\n\\n', self._level)

	if self._isMaxLevel then
		tooltip = tooltip .. 'You have reached the maximum level!\\n'
		tooltip = tooltip .. string.format('Total Experience: %s\\n', self:AbbreviateNumber(self._currentXP))
	else
		tooltip = tooltip .. string.format('Current XP: %s\\n', self:AbbreviateNumber(self._currentXP))
		tooltip = tooltip .. string.format('Required XP: %s\\n', self:AbbreviateNumber(self._maxXP))
		tooltip = tooltip .. string.format('Remaining XP: %s\\n', self:AbbreviateNumber(self._maxXP - self._currentXP))
		tooltip = tooltip .. string.format('Progress: %.2f%%\\n', self._percentComplete)

		-- Rested XP information
		if self._restXP > 0 then
			local restedPercent = (self._restXP / self._maxXP) * 100
			tooltip = tooltip .. string.format('\\n|cFF00D4FFRested XP: %s (%.1f%%)|r\\n', self:AbbreviateNumber(self._restXP), restedPercent)
			local bubblesRested = math.floor(self._restXP / (self._maxXP * 0.05)) -- Each bubble is 5%
			tooltip = tooltip .. string.format('|cFF00D4FFRested Bubbles: %d|r\\n', bubblesRested)
		else
			tooltip = tooltip .. '\\nNo rested XP\\n'
		end

		-- Session information
		if self:GetConfig('showSessionGains') then
			tooltip = tooltip .. '\\nSession Statistics:\\n'
			tooltip = tooltip .. string.format('Session XP: %s\\n', self:AbbreviateNumber(self._sessionXP))
			if self._xpPerHour > 0 then
				tooltip = tooltip .. string.format('XP/Hour: %s\\n', self:AbbreviateNumber(self._xpPerHour))
				local hoursToLevel = (self._maxXP - self._currentXP) / self._xpPerHour
				tooltip = tooltip .. string.format('Time to Level: %s\\n', self:FormatTime(hoursToLevel * 3600))
			end
		end

		-- Kill information (if available)
		local xpPerKill = self:EstimateXPPerKill()
		if xpPerKill > 0 then
			local killsToLevel = math.ceil((self._maxXP - self._currentXP) / xpPerKill)
			tooltip = tooltip .. string.format('\\nEst. kills to level: %d (avg %s XP/kill)\\n', killsToLevel, self:AbbreviateNumber(xpPerKill))
		end
	end

	tooltip = tooltip .. '\\nLeft-click: Change display format\\n'
	tooltip = tooltip .. 'Right-click: Configuration options\\n'
	tooltip = tooltip .. 'Middle-click: Reset session statistics'

	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function ExperiencePlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Cycle display formats
		self:CycleDisplayFormat()
	elseif button == 'RightButton' then
		-- Show configuration menu (placeholder)
		LibsDataBar:DebugLog('info', 'Experience configuration menu (coming in Phase 2)')
	elseif button == 'MiddleButton' then
		-- Reset session statistics
		self:ResetSessionStats()
		LibsDataBar:DebugLog('info', 'Experience session statistics reset')
	end
end

---Update experience data from game
function ExperiencePlugin:UpdateExperienceData()
	self._level = UnitLevel('player')
	self._isMaxLevel = UnitLevel('player') == GetMaxPlayerLevel()

	if not self._isMaxLevel then
		self._currentXP = UnitXP('player')
		self._maxXP = UnitXPMax('player')
		self._restXP = GetXPExhaustion() or 0
		self._percentComplete = (self._currentXP / self._maxXP) * 100

		-- Update session tracking
		self:UpdateSessionTracking()
	else
		-- For max level characters, show total XP
		self._currentXP = UnitXP('player')
		self._maxXP = 0
		self._restXP = 0
		self._percentComplete = 100
	end
end

---Update session tracking statistics
function ExperiencePlugin:UpdateSessionTracking()
	if not self:GetConfig('trackPlaytime') then return end

	local currentTime = GetTime()

	-- Initialize session start time if needed
	if self._sessionStartTime == 0 then
		self._sessionStartTime = currentTime
		self._sessionStartXP = self._currentXP
	end

	-- Calculate session XP and XP per hour
	local sessionDuration = currentTime - self._sessionStartTime
	self._sessionXP = self._currentXP - (self._sessionStartXP or self._currentXP)

	if sessionDuration > 0 then self._xpPerHour = (self._sessionXP / sessionDuration) * 3600 end
end

---Abbreviate large numbers for display
---@param number number Number to abbreviate
---@return string abbreviated Abbreviated number string
function ExperiencePlugin:AbbreviateNumber(number)
	if number >= 1000000000 then
		return string.format('%.1fB', number / 1000000000)
	elseif number >= 1000000 then
		return string.format('%.1fM', number / 1000000)
	elseif number >= 1000 then
		return string.format('%.1fK', number / 1000)
	else
		return tostring(number)
	end
end

---Format time duration into readable string
---@param seconds number Time in seconds
---@return string formatted Formatted time string
function ExperiencePlugin:FormatTime(seconds)
	if seconds <= 0 then return '0s' end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if hours > 0 then
		return string.format('%dh %dm', hours, minutes)
	elseif minutes > 0 then
		return string.format('%dm %ds', minutes, secs)
	else
		return string.format('%ds', secs)
	end
end

---Estimate XP per kill based on level
---@return number xpPerKill Estimated XP per kill
function ExperiencePlugin:EstimateXPPerKill()
	-- This is a rough estimate based on mob levels relative to player level
	-- In a real implementation, you'd track actual kills and XP gains
	local level = self._level

	if level <= 10 then
		return math.floor(self._maxXP * 0.05) -- ~5% per kill at low levels
	elseif level <= 30 then
		return math.floor(self._maxXP * 0.03) -- ~3% per kill at mid levels
	elseif level <= 50 then
		return math.floor(self._maxXP * 0.02) -- ~2% per kill at higher levels
	else
		return math.floor(self._maxXP * 0.01) -- ~1% per kill at max levels
	end
end

---Cycle through different display formats
function ExperiencePlugin:CycleDisplayFormat()
	local formats = { 'percent', 'current', 'remaining', 'time' }
	local current = self:GetConfig('displayFormat')
	local currentIndex = 1

	-- Find current format index
	for i, format in ipairs(formats) do
		if format == current then
			currentIndex = i
			break
		end
	end

	-- Move to next format (wrap around)
	local nextIndex = currentIndex < #formats and currentIndex + 1 or 1
	local nextFormat = formats[nextIndex]

	self:SetConfig('displayFormat', nextFormat)
	LibsDataBar:DebugLog('info', 'Experience display format changed to: ' .. nextFormat)
end

---Reset session statistics
function ExperiencePlugin:ResetSessionStats()
	self._sessionStartTime = GetTime()
	self._sessionStartXP = self._currentXP
	self._sessionXP = 0
	self._xpPerHour = 0
end

---Get configuration options
---@return table options AceConfig options table
function ExperiencePlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			displayFormat = {
				type = 'select',
				name = 'Display Format',
				desc = 'Choose how to display experience information',
				order = 10,
				values = {
					percent = 'Percentage Complete',
					current = 'Current/Max XP',
					remaining = 'XP Remaining',
					time = 'Time to Level',
				},
				get = function()
					return self:GetConfig('displayFormat')
				end,
				set = function(_, value)
					self:SetConfig('displayFormat', value)
				end,
			},
			showLevel = {
				type = 'toggle',
				name = 'Show Level',
				desc = 'Include character level in display',
				order = 20,
				get = function()
					return self:GetConfig('showLevel')
				end,
				set = function(_, value)
					self:SetConfig('showLevel', value)
				end,
			},
			showRested = {
				type = 'toggle',
				name = 'Show Rested XP',
				desc = 'Display rested experience information',
				order = 30,
				get = function()
					return self:GetConfig('showRested')
				end,
				set = function(_, value)
					self:SetConfig('showRested', value)
				end,
			},
			colorByRested = {
				type = 'toggle',
				name = 'Color by Rested Status',
				desc = 'Use blue color when rested XP is available',
				order = 40,
				get = function()
					return self:GetConfig('colorByRested')
				end,
				set = function(_, value)
					self:SetConfig('colorByRested', value)
				end,
			},
			abbreviateNumbers = {
				type = 'toggle',
				name = 'Abbreviate Numbers',
				desc = 'Use K/M/B suffixes for large numbers',
				order = 50,
				get = function()
					return self:GetConfig('abbreviateNumbers')
				end,
				set = function(_, value)
					self:SetConfig('abbreviateNumbers', value)
				end,
			},
			showSessionGains = {
				type = 'toggle',
				name = 'Show Session Statistics',
				desc = 'Track and display session XP gains',
				order = 60,
				get = function()
					return self:GetConfig('showSessionGains')
				end,
				set = function(_, value)
					self:SetConfig('showSessionGains', value)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function ExperiencePlugin:GetDefaultConfig()
	return experienceDefaults
end

---Lifecycle: Plugin initialization
function ExperiencePlugin:OnInitialize()
	self._sessionStartTime = GetTime()
	self:UpdateExperienceData()
	self._sessionStartXP = self._currentXP
	LibsDataBar:DebugLog('info', 'Experience plugin initialized')
end

---Lifecycle: Plugin enabled
function ExperiencePlugin:OnEnable()
	-- Register for XP-related events
	self:RegisterEvent('PLAYER_XP_UPDATE', 'OnXPUpdate')
	self:RegisterEvent('PLAYER_LEVEL_UP', 'OnLevelUp')
	self:RegisterEvent('UPDATE_EXHAUSTION', 'OnExhaustionUpdate')
	self:RegisterEvent('PLAYER_UPDATE_RESTING', 'OnRestingUpdate')
	LibsDataBar:DebugLog('info', 'Experience plugin enabled')
end

---Lifecycle: Plugin disabled
function ExperiencePlugin:OnDisable()
	self:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Experience plugin disabled')
end

---Event handler for XP updates
function ExperiencePlugin:OnXPUpdate()
	self:UpdateExperienceData()
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Event handler for level up
function ExperiencePlugin:OnLevelUp()
	-- Reset session stats on level up
	self:ResetSessionStats()
	self:UpdateExperienceData()
	LibsDataBar:DebugLog('info', 'Congratulations on reaching level ' .. self._level .. '!')
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Event handler for exhaustion (rested XP) updates
function ExperiencePlugin:OnExhaustionUpdate()
	self:UpdateExperienceData()
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Event handler for resting state updates
function ExperiencePlugin:OnRestingUpdate()
	self:UpdateExperienceData()
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Helper: Register for an event
---@param event string Event name
---@param method string Method name to call
function ExperiencePlugin:RegisterEvent(event, method)
	LibsDataBar.events:RegisterEvent(event, function(...)
		if self[method] then self[method](self, ...) end
	end, { owner = self.id })
end

---Helper: Unregister all events
function ExperiencePlugin:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Experience plugin events unregistered')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function ExperiencePlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or experienceDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function ExperiencePlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize the plugin
ExperiencePlugin:OnInitialize()

-- Register as LibDataBroker object for standardized plugin system
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
	local experienceLDBObject = LDB:NewDataObject('LibsDataBar_Experience', {
		type = 'data source',
		text = ExperiencePlugin:GetText(),
		icon = ExperiencePlugin:GetIcon(),
		label = ExperiencePlugin.name,

		-- Forward methods to ExperiencePlugin with database access preserved
		OnClick = function(self, button)
			ExperiencePlugin:OnClick(button)
		end,

		OnTooltipShow = function(tooltip)
			tooltip:SetText(ExperiencePlugin:GetTooltip())
		end,

		-- Update method to refresh LDB object
		UpdateLDB = function(self)
			self.text = ExperiencePlugin:GetText()
			self.icon = ExperiencePlugin:GetIcon()
		end,
	})

	-- Store reference for updates
	ExperiencePlugin._ldbObject = experienceLDBObject

	LibsDataBar:DebugLog('info', 'Experience plugin registered as LibDataBroker object')
else
	LibsDataBar:DebugLog('error', 'LibDataBroker not available for Experience plugin')
end

-- Return plugin for external access
return ExperiencePlugin
