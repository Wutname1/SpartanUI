---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/PlayedTime.lua
LibsDataBar PlayedTime Plugin
Displays character played time and session information
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Plugin Definition
---@class PlayedTimePlugin : Plugin
local PlayedTimePlugin = {
	-- Required metadata
	id = 'LibsDataBar_PlayedTime',
	name = 'Played Time',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Character',
	description = 'Displays character played time and session information',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_totalTimePlayed = 0,
	_timePlayedThisLevel = 0,
	_sessionStartTime = 0,
	_sessionTime = 0,
	_lastPlayedRequest = 0,
	_playedDataReceived = false,
}

-- Plugin Configuration Defaults
local playedTimeDefaults = {
	displayFormat = 'total', -- 'total', 'session', 'level', 'combined'
	timeFormat = 'smart', -- 'smart', 'full', 'compact', 'hours'
	showSessionInfo = true,
	autoRequestPlayed = false, -- Auto-request /played data periodically
	requestInterval = 300, -- Seconds between auto-requests (5 minutes)
	trackSessionTime = true,
	colorByAge = false,
}

---Required: Get the display text for this plugin
---@return string text Display text
function PlayedTimePlugin:GetText()
	local displayFormat = self:GetConfig('displayFormat')
	local timeFormat = self:GetConfig('timeFormat')
	local colorByAge = self:GetConfig('colorByAge')
	
	self:UpdateSessionTime()
	
	local text = ''
	local timeToDisplay = 0
	local prefix = ''
	
	if displayFormat == 'total' then
		timeToDisplay = self._totalTimePlayed
		prefix = 'Total: '
	elseif displayFormat == 'session' then
		timeToDisplay = self._sessionTime
		prefix = 'Session: '
	elseif displayFormat == 'level' then
		timeToDisplay = self._timePlayedThisLevel
		prefix = 'Level: '
	elseif displayFormat == 'combined' then
		-- Show both total and session
		local totalText = self:FormatTime(self._totalTimePlayed, timeFormat)
		local sessionText = self:FormatTime(self._sessionTime, timeFormat)
		text = string.format('T:%s | S:%s', totalText, sessionText)
		
		-- Apply coloring if enabled
		if colorByAge then
			text = self:ApplyAgeColor(text, self._totalTimePlayed)
		end
		
		return text
	else
		-- Default to total
		timeToDisplay = self._totalTimePlayed
		prefix = 'Played: '
	end
	
	text = prefix .. self:FormatTime(timeToDisplay, timeFormat)
	
	-- Apply color coding based on total played time
	if colorByAge then
		text = self:ApplyAgeColor(text, self._totalTimePlayed)
	end
	
	return text
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function PlayedTimePlugin:GetIcon()
	local totalHours = self._totalTimePlayed / 3600
	
	if totalHours < 24 then
		return 'Interface\\Icons\\INV_Misc_PocketWatch_01' -- New character
	elseif totalHours < 240 then -- Less than 10 days
		return 'Interface\\Icons\\INV_Misc_PocketWatch_02' -- Moderate playtime
	elseif totalHours < 720 then -- Less than 30 days
		return 'Interface\\Icons\\Spell_Holy_BorrowedTime' -- Experienced
	else
		return 'Interface\\Icons\\Spell_Nature_TimeStop' -- Veteran player
	end
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function PlayedTimePlugin:GetTooltip()
	self:UpdateSessionTime()
	
	local tooltip = 'Character Play Time:\\n\\n'
	
	-- Total played time
	tooltip = tooltip .. string.format('Total Played: %s\\n', self:FormatTime(self._totalTimePlayed, 'full'))
	
	-- Time played this level
	if self._timePlayedThisLevel > 0 then
		tooltip = tooltip .. string.format('This Level: %s\\n', self:FormatTime(self._timePlayedThisLevel, 'full'))
	end
	
	-- Session information
	if self:GetConfig('showSessionInfo') then
		tooltip = tooltip .. '\\nSession Statistics:\\n'
		tooltip = tooltip .. string.format('Session Time: %s\\n', self:FormatTime(self._sessionTime, 'full'))
		
		local sessionStart = self._sessionStartTime
		if sessionStart > 0 then
			tooltip = tooltip .. string.format('Session Started: %s\\n', date('%H:%M:%S', sessionStart))
		end
		
		-- Calculate session statistics
		local sessionHours = self._sessionTime / 3600
		if sessionHours >= 1 then
			local sessionsPerDay = 24 / sessionHours
			tooltip = tooltip .. string.format('Avg Sessions/Day: %.1f\\n', sessionsPerDay)
		end
	end
	
	-- Playtime analysis
	tooltip = tooltip .. '\\nPlaytime Analysis:\\n'
	local totalDays = self._totalTimePlayed / 86400
	local avgHoursPerDay = self._totalTimePlayed / 3600 / math.max(1, totalDays)
	
	tooltip = tooltip .. string.format('Total Days: %.1f\\n', totalDays)
	if totalDays > 1 then
		tooltip = tooltip .. string.format('Avg Hours/Day: %.1f\\n', avgHoursPerDay)
	end
	
	-- Playtime milestones
	local milestones = self:GetPlaytimeMilestones()
	if #milestones > 0 then
		tooltip = tooltip .. '\\nMilestones:\\n'
		for _, milestone in ipairs(milestones) do
			tooltip = tooltip .. '• ' .. milestone .. '\\n'
		end
	end
	
	-- Data freshness warning
	if not self._playedDataReceived or (GetTime() - self._lastPlayedRequest) > 1800 then
		tooltip = tooltip .. '\\n|cFFFFFF00Note: /played data may be outdated|r\\n'
		tooltip = tooltip .. '|cFFFFFF00Click to refresh played time data|r\\n'
	end
	
	tooltip = tooltip .. '\\nControls:\\n'
	tooltip = tooltip .. 'Left-click: Request /played update\\n'
	tooltip = tooltip .. 'Right-click: Change display format\\n'
	tooltip = tooltip .. 'Middle-click: Reset session timer'
	
	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function PlayedTimePlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Cycle display formats (session, level, character, account)
		self:CycleDisplayFormat()
	elseif button == 'RightButton' then
		-- Request fresh /played data
		self:RequestPlayedTime()
	elseif button == 'MiddleButton' then
		-- Reset session timer
		self:ResetSessionTimer()
		LibsDataBar:DebugLog('info', 'PlayedTime session timer reset')
	end
end

---Update session time tracking
function PlayedTimePlugin:UpdateSessionTime()
	if not self:GetConfig('trackSessionTime') then return end
	
	local currentTime = GetTime()
	
	-- Initialize session start time if needed
	if self._sessionStartTime == 0 then
		self._sessionStartTime = currentTime
	end
	
	-- Calculate current session time
	self._sessionTime = currentTime - self._sessionStartTime
end

---Request played time data from server
function PlayedTimePlugin:RequestPlayedTime()
	local currentTime = GetTime()
	
	-- Throttle requests to avoid spam
	if (currentTime - self._lastPlayedRequest) < 5 then
		LibsDataBar:DebugLog('info', 'PlayedTime request throttled (too frequent)')
		return
	end
	
	self._lastPlayedRequest = currentTime
	RequestTimePlayed()
	LibsDataBar:DebugLog('info', 'PlayedTime data requested')
end

---Format time duration for display
---@param seconds number Time in seconds
---@param format string Format type ('smart', 'full', 'compact', 'hours')
---@return string formatted Formatted time string
function PlayedTimePlugin:FormatTime(seconds, format)
	if seconds <= 0 then return '0s' end
	
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	
	if format == 'hours' then
		local totalHours = seconds / 3600
		return string.format('%.1fh', totalHours)
	elseif format == 'compact' then
		if days > 0 then
			return string.format('%dd %dh', days, hours)
		elseif hours > 0 then
			return string.format('%dh %dm', hours, minutes)
		else
			return string.format('%dm', minutes)
		end
	elseif format == 'full' then
		local parts = {}
		if days > 0 then table.insert(parts, days .. ' day' .. (days == 1 and '' or 's')) end
		if hours > 0 then table.insert(parts, hours .. ' hour' .. (hours == 1 and '' or 's')) end
		if minutes > 0 then table.insert(parts, minutes .. ' minute' .. (minutes == 1 and '' or 's')) end
		if #parts == 0 and secs > 0 then table.insert(parts, secs .. ' second' .. (secs == 1 and '' or 's')) end
		
		return table.concat(parts, ', ')
	else -- 'smart' format
		if days > 7 then
			local weeks = math.floor(days / 7)
			local remainingDays = days % 7
			return string.format('%dw %dd', weeks, remainingDays)
		elseif days > 0 then
			return string.format('%dd %dh', days, hours)
		elseif hours > 0 then
			return string.format('%dh %dm', hours, minutes)
		elseif minutes > 0 then
			return string.format('%dm %ds', minutes, secs)
		else
			return string.format('%ds', secs)
		end
	end
end

---Apply color coding based on total playtime
---@param text string Text to color
---@param totalTime number Total played time in seconds
---@return string coloredText Colored text
function PlayedTimePlugin:ApplyAgeColor(text, totalTime)
	local totalDays = totalTime / 86400
	
	if totalDays < 1 then
		return '|cFF00FF00' .. text .. '|r' -- Green for new characters
	elseif totalDays < 7 then
		return '|cFF40FF40' .. text .. '|r' -- Light green for week-old
	elseif totalDays < 30 then
		return '|cFFFFFF00' .. text .. '|r' -- Yellow for month-old
	elseif totalDays < 90 then
		return '|cFFFF8000' .. text .. '|r' -- Orange for seasoned
	else
		return '|cFFFF4040' .. text .. '|r' -- Light red for veterans
	end
end

---Get playtime milestones achieved
---@return table milestones List of milestone descriptions
function PlayedTimePlugin:GetPlaytimeMilestones()
	local milestones = {}
	local totalHours = self._totalTimePlayed / 3600
	local totalDays = self._totalTimePlayed / 86400
	
	-- Hour milestones
	local hourMilestones = {10, 24, 48, 100, 200, 500, 1000, 2000, 5000}
	for _, milestone in ipairs(hourMilestones) do
		if totalHours >= milestone then
			if milestone == 24 then
				table.insert(milestones, 'First Full Day')
			elseif milestone == 48 then
				table.insert(milestones, 'Two Days Played')
			elseif milestone >= 1000 then
				table.insert(milestones, string.format('%d+ Hours Veteran', milestone))
			else
				table.insert(milestones, string.format('%d+ Hours', milestone))
			end
		end
	end
	
	-- Day milestones
	local dayMilestones = {7, 30, 90, 180, 365}
	for _, milestone in ipairs(dayMilestones) do
		if totalDays >= milestone then
			if milestone == 7 then
				table.insert(milestones, 'One Week Played')
			elseif milestone == 30 then
				table.insert(milestones, 'One Month Played')
			elseif milestone == 365 then
				table.insert(milestones, 'One Year Played!')
			else
				table.insert(milestones, string.format('%d+ Days', milestone))
			end
		end
	end
	
	-- Keep only the most recent few milestones
	if #milestones > 3 then
		local recentMilestones = {}
		for i = math.max(1, #milestones - 2), #milestones do
			table.insert(recentMilestones, milestones[i])
		end
		return recentMilestones
	end
	
	return milestones
end

---Reset session timer
function PlayedTimePlugin:ResetSessionTimer()
	self._sessionStartTime = GetTime()
	self._sessionTime = 0
end

---Cycle through different display formats
function PlayedTimePlugin:CycleDisplayFormat()
	local formats = {'total', 'session', 'level', 'combined'}
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
	LibsDataBar:DebugLog('info', 'PlayedTime display format changed to: ' .. nextFormat)
end

---Get configuration options
---@return table options AceConfig options table
function PlayedTimePlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			displayFormat = {
				type = 'select',
				name = 'Display Format',
				desc = 'Choose what time information to display',
				order = 10,
				values = {
					total = 'Total Played Time',
					session = 'Session Time',
					level = 'Time This Level',
					combined = 'Total + Session',
				},
				get = function()
					return self:GetConfig('displayFormat')
				end,
				set = function(_, value)
					self:SetConfig('displayFormat', value)
				end,
			},
			timeFormat = {
				type = 'select',
				name = 'Time Format',
				desc = 'Choose how to format time displays',
				order = 20,
				values = {
					smart = 'Smart (adaptive)',
					full = 'Full (verbose)',
					compact = 'Compact',
					hours = 'Hours Only',
				},
				get = function()
					return self:GetConfig('timeFormat')
				end,
				set = function(_, value)
					self:SetConfig('timeFormat', value)
				end,
			},
			colorByAge = {
				type = 'toggle',
				name = 'Color by Character Age',
				desc = 'Use colors to indicate how long the character has been played',
				order = 30,
				get = function()
					return self:GetConfig('colorByAge')
				end,
				set = function(_, value)
					self:SetConfig('colorByAge', value)
				end,
			},
			showSessionInfo = {
				type = 'toggle',
				name = 'Show Session Info',
				desc = 'Include session statistics in tooltip',
				order = 40,
				get = function()
					return self:GetConfig('showSessionInfo')
				end,
				set = function(_, value)
					self:SetConfig('showSessionInfo', value)
				end,
			},
			autoRequestPlayed = {
				type = 'toggle',
				name = 'Auto-Update Played Time',
				desc = 'Automatically request updated played time data',
				order = 50,
				get = function()
					return self:GetConfig('autoRequestPlayed')
				end,
				set = function(_, value)
					self:SetConfig('autoRequestPlayed', value)
				end,
			},
			requestInterval = {
				type = 'range',
				name = 'Update Interval',
				desc = 'Minutes between automatic played time updates',
				order = 60,
				min = 5,
				max = 60,
				step = 5,
				get = function()
					return self:GetConfig('requestInterval') / 60
				end,
				set = function(_, value)
					self:SetConfig('requestInterval', value * 60)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function PlayedTimePlugin:GetDefaultConfig()
	return playedTimeDefaults
end

---Lifecycle: Plugin initialization
function PlayedTimePlugin:OnInitialize()
	self._sessionStartTime = GetTime()
	
	-- Request initial played time data
	self:RequestPlayedTime()
	
	LibsDataBar:DebugLog('info', 'PlayedTime plugin initialized')
end

---Lifecycle: Plugin enabled
function PlayedTimePlugin:OnEnable()
	-- Register for played time events
	self:RegisterEvent('TIME_PLAYED_MSG', 'OnTimePlayedReceived')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnPlayerEnteringWorld')
	
	-- Setup auto-update timer if enabled
	if self:GetConfig('autoRequestPlayed') then
		local interval = self:GetConfig('requestInterval')
		self.autoUpdateTimer = C_Timer.NewTicker(interval, function()
			self:RequestPlayedTime()
		end)
	end
	
	LibsDataBar:DebugLog('info', 'PlayedTime plugin enabled')
end

---Lifecycle: Plugin disabled
function PlayedTimePlugin:OnDisable()
	self:UnregisterAllEvents()
	
	-- Cancel auto-update timer
	if self.autoUpdateTimer then
		self.autoUpdateTimer:Cancel()
		self.autoUpdateTimer = nil
	end
	
	LibsDataBar:DebugLog('info', 'PlayedTime plugin disabled')
end

---Event handler for played time data received
---@param totalTime number Total time played in seconds
---@param levelTime number Time played at current level in seconds
function PlayedTimePlugin:OnTimePlayedReceived(totalTime, levelTime)
	self._totalTimePlayed = totalTime or 0
	self._timePlayedThisLevel = levelTime or 0
	self._playedDataReceived = true
	
	LibsDataBar:DebugLog('info', string.format('PlayedTime data updated: %s total, %s this level',
		self:FormatTime(self._totalTimePlayed, 'compact'),
		self:FormatTime(self._timePlayedThisLevel, 'compact')))
	
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Event handler for entering world
function PlayedTimePlugin:OnPlayerEnteringWorld()
	-- Reset session timer when entering world (login/reload)
	self:ResetSessionTimer()
	
	-- Request fresh played time data
	C_Timer.NewTimer(2, function()
		self:RequestPlayedTime()
	end)
end

---Helper: Register for an event
---@param event string Event name
---@param method string Method name to call
function PlayedTimePlugin:RegisterEvent(event, method)
	LibsDataBar.events:RegisterEvent(event, function(...)
		if self[method] then self[method](self, ...) end
	end, { owner = self.id })
end

---Helper: Unregister all events
function PlayedTimePlugin:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'PlayedTime plugin events unregistered')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function PlayedTimePlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or playedTimeDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function PlayedTimePlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize and register the plugin
PlayedTimePlugin:OnInitialize()

-- Register with LibsDataBar
if LibsDataBar:RegisterPlugin(PlayedTimePlugin) then
	LibsDataBar:DebugLog('info', 'PlayedTime plugin registered successfully')
else
	LibsDataBar:DebugLog('error', 'Failed to register PlayedTime plugin')
end

-- Return plugin for external access
return PlayedTimePlugin