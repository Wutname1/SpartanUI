---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Currency.lua
LibsDataBar Currency Plugin
Tracks player gold and other currencies
--]===]

-- Get the LibsDataBar addon
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- Plugin Definition
---@class CurrencyPlugin : Plugin
local CurrencyPlugin = {
	-- Required metadata
	id = 'LibsDataBar_Currency',
	name = 'Currency',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Information',
	description = 'Displays player gold and other currencies',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_currentGold = 0,
	_showCopper = true,
	_showServerGold = false,

	-- Session and time tracking
	_sessionStartGold = 0,
	_sessionStartTime = 0,
	_goldHistory = {}, -- Stores daily gold snapshots
	_currencyHistory = {}, -- Stores currency changes over time
	_lastSaveTime = 0,
}

-- Plugin Configuration Defaults
local currencyDefaults = {
	showCopper = true,
	showSilver = true,
	showGold = true,
	showServerGold = false,
	shortFormat = false,
	colorText = true,
	displayFormat = 'current', -- 'current', 'session_gain', 'daily_gain', 'weekly_gain'
	trackSession = true,
	trackDaily = true,
	trackWeekly = true,
	showCurrencies = true,
	maxCurrenciesToShow = 5,
	autoSaveInterval = 300, -- Save tracking data every 5 minutes
}

---Required: Get the display text for this plugin
---@return string text Display text
function CurrencyPlugin:GetText()
	local displayFormat = self:GetConfig('displayFormat')
	local colorText = self:GetConfig('colorText')

	local money = GetMoney()
	self._currentGold = money
	self:UpdateTracking()

	if displayFormat == 'session_gain' then
		local sessionGain = money - self._sessionStartGold
		return self:FormatGainLoss('Session', sessionGain, colorText)
	elseif displayFormat == 'daily_gain' then
		local todayGain = self:GetTodayGain()
		return self:FormatGainLoss('Today', todayGain, colorText)
	elseif displayFormat == 'weekly_gain' then
		local weekGain = self:GetThisWeekGain()
		return self:FormatGainLoss('This Week', weekGain, colorText)
	else
		-- Default 'current' format
		return self:FormatCurrentMoney(money)
	end
end

---Add comma formatting to numbers
---@param num number Number to format
---@return string formatted Formatted number with commas
function CurrencyPlugin:FormatNumber(num)
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

---Format current money for display
---@param money number Total money in copper
---@return string formatted Formatted money string
function CurrencyPlugin:FormatCurrentMoney(money)
	if money == 0 then return '0g' end

	local goldText = ''
	local gold = floor(money / 10000)
	local silver = floor((money - (gold * 10000)) / 100)
	local copper = money - (gold * 10000) - (silver * 100)

	local colorText = self:GetConfig('colorText')
	local shortFormat = self:GetConfig('shortFormat')

	if gold > 0 and self:GetConfig('showGold') then
		local formattedGold = self:FormatNumber(gold)
		if colorText then
			goldText = goldText .. '|cFFFFD700' .. formattedGold .. 'g|r'
		else
			goldText = goldText .. formattedGold .. 'g'
		end
	end

	if silver > 0 and self:GetConfig('showSilver') then
		if goldText ~= '' then goldText = goldText .. ' ' end
		if colorText then
			goldText = goldText .. '|cFFC0C0C0' .. silver .. 's|r'
		else
			goldText = goldText .. silver .. 's'
		end
	end

	if copper > 0 and self:GetConfig('showCopper') and not shortFormat then
		if goldText ~= '' then goldText = goldText .. ' ' end
		if colorText then
			goldText = goldText .. '|cFFCD7F32' .. copper .. 'c|r'
		else
			goldText = goldText .. copper .. 'c'
		end
	end

	return goldText ~= '' and goldText or '0g'
end

---Format gain/loss for display
---@param period string Time period name
---@param amount number Amount gained/lost in copper
---@param useColor boolean Whether to use colors
---@return string formatted Formatted gain/loss string
function CurrencyPlugin:FormatGainLoss(period, amount, useColor)
	if amount == 0 then return period .. ': 0g' end

	local prefix = period .. ': '
	local sign = amount > 0 and '+' or ''
	local color = ''
	local colorEnd = ''

	if useColor then
		if amount > 0 then
			color = '|cFF00FF00' -- Green for gains
			colorEnd = '|r'
		elseif amount < 0 then
			color = '|cFFFF0000' -- Red for losses
			colorEnd = '|r'
		end
	end

	-- Format the absolute amount using the same logic as current money
	local absAmount = math.abs(amount)
	local formattedAmount = self:FormatCurrentMoney(absAmount)
	-- Remove existing color codes to apply our own
	formattedAmount = formattedAmount:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')

	return prefix .. color .. sign .. formattedAmount .. colorEnd
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function CurrencyPlugin:GetIcon()
	return 'Interface\\Icons\\INV_Misc_Coin_01'
end

---Update tracking data
function CurrencyPlugin:UpdateTracking()
	if not self:GetConfig('trackSession') and not self:GetConfig('trackDaily') and not self:GetConfig('trackWeekly') then return end

	local currentTime = GetTime()

	-- Initialize session tracking if needed
	if self._sessionStartTime == 0 then
		self._sessionStartTime = currentTime
		self._sessionStartGold = self._currentGold
	end

	-- Auto-save tracking data periodically
	if (currentTime - self._lastSaveTime) >= self:GetConfig('autoSaveInterval') then
		self:SaveTrackingData()
		self._lastSaveTime = currentTime
	end

	-- Update daily tracking
	self:UpdateDailyTracking()
end

---Update daily tracking data
function CurrencyPlugin:UpdateDailyTracking()
	if not self:GetConfig('trackDaily') and not self:GetConfig('trackWeekly') then return end

	local today = self:GetDateKey()
	local currentGold = self._currentGold

	-- Initialize today's data if needed
	if not self._goldHistory[today] then
		self._goldHistory[today] = {
			start = currentGold,
			current = currentGold,
			timestamp = GetTime(),
		}
	else
		-- Update current amount
		self._goldHistory[today].current = currentGold
	end

	-- Clean up old data (keep last 14 days)
	self:CleanupOldData()
end

---Get date key for today (YYYY-MM-DD format)
---@return string dateKey Today's date key
function CurrencyPlugin:GetDateKey()
	return date('%Y-%m-%d')
end

---Get yesterday's date key
---@return string dateKey Yesterday's date key
function CurrencyPlugin:GetYesterdayKey()
	local yesterday = time() - 86400 -- 24 hours ago
	return date('%Y-%m-%d', yesterday)
end

---Get gain for today
---@return number gain Today's gold gain
function CurrencyPlugin:GetTodayGain()
	local today = self:GetDateKey()
	local todayData = self._goldHistory[today]

	if not todayData then return 0 end

	return todayData.current - todayData.start
end

---Get gain for yesterday
---@return number gain Yesterday's gold gain
function CurrencyPlugin:GetYesterdayGain()
	local yesterday = self:GetYesterdayKey()
	local yesterdayData = self._goldHistory[yesterday]

	if not yesterdayData then return 0 end

	return yesterdayData.current - yesterdayData.start
end

---Get gain for this week
---@return number gain This week's gold gain
function CurrencyPlugin:GetThisWeekGain()
	local totalGain = 0
	local currentTime = time()
	local weekStart = currentTime - (86400 * 7) -- 7 days ago

	for dateKey, data in pairs(self._goldHistory) do
		local dayTime = self:ParseDateKey(dateKey)
		if dayTime and dayTime >= weekStart then totalGain = totalGain + (data.current - data.start) end
	end

	return totalGain
end

---Get gain for last week
---@return number gain Last week's gold gain
function CurrencyPlugin:GetLastWeekGain()
	local totalGain = 0
	local currentTime = time()
	local lastWeekStart = currentTime - (86400 * 14) -- 14 days ago
	local lastWeekEnd = currentTime - (86400 * 7) -- 7 days ago

	for dateKey, data in pairs(self._goldHistory) do
		local dayTime = self:ParseDateKey(dateKey)
		if dayTime and dayTime >= lastWeekStart and dayTime < lastWeekEnd then totalGain = totalGain + (data.current - data.start) end
	end

	return totalGain
end

---Parse date key to timestamp
---@param dateKey string Date key in YYYY-MM-DD format
---@return number? timestamp Timestamp or nil if invalid
function CurrencyPlugin:ParseDateKey(dateKey)
	local year, month, day = dateKey:match('(%d+)-(%d+)-(%d+)')
	if year and month and day then return time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) }) end
	return nil
end

---Clean up old tracking data
function CurrencyPlugin:CleanupOldData()
	local cutoffTime = time() - (86400 * 14) -- Keep 14 days

	for dateKey, data in pairs(self._goldHistory) do
		local dayTime = self:ParseDateKey(dateKey)
		if dayTime and dayTime < cutoffTime then self._goldHistory[dateKey] = nil end
	end
end

---Save tracking data to character settings
function CurrencyPlugin:SaveTrackingData()
	-- Save to LibsDataBar config system
	local characterKey = UnitName('player') .. '-' .. GetRealmName()

	LibsDataBar:SetConfig('plugins.' .. self.id .. '.trackingData.' .. characterKey .. '.goldHistory', self._goldHistory)
	LibsDataBar:SetConfig('plugins.' .. self.id .. '.trackingData.' .. characterKey .. '.sessionStart', {
		gold = self._sessionStartGold,
		time = self._sessionStartTime,
	})
end

---Load tracking data from character settings
function CurrencyPlugin:LoadTrackingData()
	local characterKey = UnitName('player') .. '-' .. GetRealmName()

	-- Load gold history
	local savedHistory = LibsDataBar:GetConfig('plugins.' .. self.id .. '.trackingData.' .. characterKey .. '.goldHistory')
	if savedHistory then self._goldHistory = savedHistory end

	-- Load session data (only if from today)
	local savedSession = LibsDataBar:GetConfig('plugins.' .. self.id .. '.trackingData.' .. characterKey .. '.sessionStart')
	if savedSession then
		local sessionDate = date('%Y-%m-%d', savedSession.time)
		local today = self:GetDateKey()

		if sessionDate == today then
			-- Continue existing session
			self._sessionStartGold = savedSession.gold
			self._sessionStartTime = savedSession.time
		else
			-- Start new session
			self._sessionStartGold = self._currentGold
			self._sessionStartTime = GetTime()
		end
	else
		-- Initialize new session
		self._sessionStartGold = self._currentGold
		self._sessionStartTime = GetTime()
	end
end

---Get server-wide currency information
---@return table serverInfo Server currency totals
function CurrencyPlugin:GetServerInfo()
	-- This would track all characters on the server in a full implementation
	-- For now, return placeholder data
	return {
		totalCharacters = 1,
		totalGold = self._currentGold,
		averageGold = self._currentGold,
	}
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function CurrencyPlugin:GetTooltip()
	local money = GetMoney()
	local gold = floor(money / 10000)
	local silver = floor((money - (gold * 10000)) / 100)
	local copper = money - (gold * 10000) - (silver * 100)

	local tooltip = 'Currency Tracker\\n\\n'

	-- Current character money
	tooltip = tooltip .. 'Current Character:\\n'
	tooltip = tooltip .. string.format('|cFFFFD700%d|r gold |cFFC0C0C0%d|r silver |cFFCD7F32%d|r copper\\n', gold, silver, copper)
	tooltip = tooltip .. string.format('Total: %s\\n', self:FormatCurrentMoney(money))

	-- Session tracking
	if self:GetConfig('trackSession') then
		local sessionGain = money - self._sessionStartGold
		local sessionTime = GetTime() - self._sessionStartTime
		tooltip = tooltip .. '\\nSession Statistics:\\n'
		tooltip = tooltip .. self:FormatTooltipGainLoss('Session Gain', sessionGain)
		tooltip = tooltip .. string.format('Session Time: %s\\n', self:FormatDuration(sessionTime))

		if sessionTime > 0 and sessionGain ~= 0 then
			local goldPerHour = (sessionGain / sessionTime) * 3600
			tooltip = tooltip .. self:FormatTooltipGainLoss('Gold/Hour', goldPerHour)
		end
	end

	-- Daily/weekly tracking
	if self:GetConfig('trackDaily') or self:GetConfig('trackWeekly') then
		tooltip = tooltip .. '\\nTime Period Statistics:\\n'

		if self:GetConfig('trackDaily') then
			local todayGain = self:GetTodayGain()
			local yesterdayGain = self:GetYesterdayGain()
			tooltip = tooltip .. self:FormatTooltipGainLoss('Today', todayGain)
			if yesterdayGain ~= 0 then tooltip = tooltip .. self:FormatTooltipGainLoss('Yesterday', yesterdayGain) end
		end

		if self:GetConfig('trackWeekly') then
			local thisWeekGain = self:GetThisWeekGain()
			local lastWeekGain = self:GetLastWeekGain()
			tooltip = tooltip .. self:FormatTooltipGainLoss('This Week', thisWeekGain)
			if lastWeekGain ~= 0 then tooltip = tooltip .. self:FormatTooltipGainLoss('Last Week', lastWeekGain) end
		end
	end

	-- Currency information
	if self:GetConfig('showCurrencies') then
		local currencyInfo = self:GetCurrencyInfo()
		if currencyInfo and #currencyInfo > 0 then
			tooltip = tooltip .. '\\nCurrencies:\\n'
			local maxToShow = math.min(#currencyInfo, self:GetConfig('maxCurrenciesToShow'))
			for i = 1, maxToShow do
				local currency = currencyInfo[i]
				tooltip = tooltip .. string.format('%s: %d\\n', currency.name, currency.amount)
			end
		end
	end

	-- Server totals (if enabled)
	if self:GetConfig('showServerGold') then
		local serverInfo = self:GetServerInfo()
		tooltip = tooltip .. '\\nServer Totals:\\n'
		tooltip = tooltip .. string.format('Total Gold: %s\\n', self:FormatCurrentMoney(serverInfo.totalGold))
		tooltip = tooltip .. string.format('Characters: %d\\n', serverInfo.totalCharacters)
	end

	-- Controls
	tooltip = tooltip .. '\\nControls:\\n'
	tooltip = tooltip .. 'Left-click: Change display format\\n'
	tooltip = tooltip .. 'Right-click: Configuration options\\n'
	tooltip = tooltip .. 'Middle-click: Reset session tracking'

	return tooltip
end

---Format gain/loss for tooltip display
---@param label string Label for the gain/loss
---@param amount number Amount gained/lost
---@return string formatted Formatted tooltip line
function CurrencyPlugin:FormatTooltipGainLoss(label, amount)
	if amount == 0 then return string.format('%s: 0g\\n', label) end

	local sign = amount > 0 and '+' or ''
	local color = amount > 0 and '|cFF00FF00' or '|cFFFF0000'
	local absAmount = math.abs(amount)
	local formattedAmount = self:FormatCurrentMoney(absAmount)
	-- Remove existing colors
	formattedAmount = formattedAmount:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')

	return string.format('%s: %s%s%s|r\\n', label, color, sign, formattedAmount)
end

---Format duration in seconds to readable string
---@param seconds number Duration in seconds
---@return string formatted Formatted duration
function CurrencyPlugin:FormatDuration(seconds)
	if seconds < 60 then
		return string.format('%.0fs', seconds)
	elseif seconds < 3600 then
		local minutes = math.floor(seconds / 60)
		return string.format('%dm', minutes)
	else
		local hours = math.floor(seconds / 3600)
		local minutes = math.floor((seconds % 3600) / 60)
		return string.format('%dh %dm', hours, minutes)
	end
end

---Get important currency information
---@return table currencyList List of important currencies
function CurrencyPlugin:GetCurrencyInfo()
	local currencies = {}

	-- Important currency IDs (these may vary by expansion)
	local importantCurrencies = {
		{ id = 1813, name = 'Reservoir Anima' }, -- Shadowlands
		{ id = 1820, name = 'Infused Ruby' }, -- Shadowlands
		{ id = 1810, name = 'Bloody Tokens' }, -- Shadowlands
		{ id = 1767, name = 'Stygia' }, -- Shadowlands
		{ id = 1191, name = 'Valor Points' }, -- Generic
		{ id = 1602, name = 'Conquest' }, -- PvP
		{ id = 1533, name = 'Wakening Essence' }, -- Legion
		{ id = 1560, name = 'War Resources' }, -- BfA
	}

	for _, currencyData in ipairs(importantCurrencies) do
		local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyData.id)
		if currencyInfo and currencyInfo.quantity > 0 then
			table.insert(currencies, {
				id = currencyData.id,
				name = currencyInfo.name or currencyData.name,
				amount = currencyInfo.quantity,
				maxQuantity = currencyInfo.maxQuantity,
				icon = currencyInfo.iconFileID,
			})
		end
	end

	-- Sort by amount (highest first)
	table.sort(currencies, function(a, b)
		return a.amount > b.amount
	end)

	return currencies
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function CurrencyPlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Cycle through display formats
		self:CycleDisplayFormat()
	elseif button == 'RightButton' then
		-- Show configuration menu (placeholder)
		LibsDataBar:DebugLog('info', 'Currency configuration menu (coming in Phase 2)')
	elseif button == 'MiddleButton' then
		-- Reset session tracking
		self:ResetSessionTracking()
		LibsDataBar:DebugLog('info', 'Currency session tracking reset')
	end
end

---Cycle through display formats
function CurrencyPlugin:CycleDisplayFormat()
	local formats = { 'current', 'session_gain', 'daily_gain', 'weekly_gain' }
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
	LibsDataBar:DebugLog('info', 'Currency display format changed to: ' .. nextFormat)
end

---Reset session tracking
function CurrencyPlugin:ResetSessionTracking()
	self._sessionStartGold = self._currentGold
	self._sessionStartTime = GetTime()
	self:SaveTrackingData()
end

---Get configuration options for this plugin
---@return table options AceConfig options table
function CurrencyPlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			displayFormat = {
				type = 'select',
				name = 'Display Format',
				desc = 'Choose what currency information to display',
				order = 10,
				values = {
					current = 'Current Amount',
					session_gain = 'Session Gain/Loss',
					daily_gain = 'Daily Gain/Loss',
					weekly_gain = 'Weekly Gain/Loss',
				},
				get = function()
					return self:GetConfig('displayFormat')
				end,
				set = function(_, value)
					self:SetConfig('displayFormat', value)
				end,
			},
			trackingHeader = {
				type = 'header',
				name = 'Tracking Options',
				order = 15,
			},
			trackSession = {
				type = 'toggle',
				name = 'Track Session',
				desc = 'Track gold gains/losses during current play session',
				order = 20,
				get = function()
					return self:GetConfig('trackSession')
				end,
				set = function(_, value)
					self:SetConfig('trackSession', value)
				end,
			},
			trackDaily = {
				type = 'toggle',
				name = 'Track Daily',
				desc = 'Track daily gold gains/losses',
				order = 30,
				get = function()
					return self:GetConfig('trackDaily')
				end,
				set = function(_, value)
					self:SetConfig('trackDaily', value)
				end,
			},
			trackWeekly = {
				type = 'toggle',
				name = 'Track Weekly',
				desc = 'Track weekly gold gains/losses',
				order = 40,
				get = function()
					return self:GetConfig('trackWeekly')
				end,
				set = function(_, value)
					self:SetConfig('trackWeekly', value)
				end,
			},
			displayHeader = {
				type = 'header',
				name = 'Display Options',
				order = 45,
			},
			showGold = {
				type = 'toggle',
				name = 'Show Gold',
				desc = 'Display gold amount',
				order = 50,
				get = function()
					return self:GetConfig('showGold')
				end,
				set = function(_, value)
					self:SetConfig('showGold', value)
				end,
			},
			showSilver = {
				type = 'toggle',
				name = 'Show Silver',
				desc = 'Display silver amount',
				order = 60,
				get = function()
					return self:GetConfig('showSilver')
				end,
				set = function(_, value)
					self:SetConfig('showSilver', value)
				end,
			},
			showCopper = {
				type = 'toggle',
				name = 'Show Copper',
				desc = 'Display copper amount',
				order = 70,
				get = function()
					return self:GetConfig('showCopper')
				end,
				set = function(_, value)
					self:SetConfig('showCopper', value)
				end,
			},
			colorText = {
				type = 'toggle',
				name = 'Color Text',
				desc = 'Use colored text for different currency types',
				order = 80,
				get = function()
					return self:GetConfig('colorText')
				end,
				set = function(_, value)
					self:SetConfig('colorText', value)
				end,
			},
			shortFormat = {
				type = 'toggle',
				name = 'Short Format',
				desc = 'Use short format (1g 2s 3c)',
				order = 90,
				get = function()
					return self:GetConfig('shortFormat')
				end,
				set = function(_, value)
					self:SetConfig('shortFormat', value)
				end,
			},
			currencyHeader = {
				type = 'header',
				name = 'Currency Options',
				order = 95,
			},
			showCurrencies = {
				type = 'toggle',
				name = 'Show Other Currencies',
				desc = 'Display other important currencies in tooltip',
				order = 100,
				get = function()
					return self:GetConfig('showCurrencies')
				end,
				set = function(_, value)
					self:SetConfig('showCurrencies', value)
				end,
			},
			maxCurrenciesToShow = {
				type = 'range',
				name = 'Max Currencies to Show',
				desc = 'Maximum number of currencies to show in tooltip',
				order = 110,
				min = 1,
				max = 10,
				step = 1,
				get = function()
					return self:GetConfig('maxCurrenciesToShow')
				end,
				set = function(_, value)
					self:SetConfig('maxCurrenciesToShow', value)
				end,
			},
			serverHeader = {
				type = 'header',
				name = 'Server Options',
				order = 115,
			},
			showServerGold = {
				type = 'toggle',
				name = 'Show Server Gold',
				desc = 'Display server-wide gold totals (future feature)',
				order = 120,
				get = function()
					return self:GetConfig('showServerGold')
				end,
				set = function(_, value)
					self:SetConfig('showServerGold', value)
				end,
			},
			advancedHeader = {
				type = 'header',
				name = 'Advanced Options',
				order = 125,
			},
			autoSaveInterval = {
				type = 'range',
				name = 'Auto-Save Interval',
				desc = 'How often to save tracking data (seconds)',
				order = 130,
				min = 60,
				max = 600,
				step = 30,
				get = function()
					return self:GetConfig('autoSaveInterval')
				end,
				set = function(_, value)
					self:SetConfig('autoSaveInterval', value)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function CurrencyPlugin:GetDefaultConfig()
	return currencyDefaults
end

---Lifecycle: Plugin initialization
function CurrencyPlugin:OnInitialize()
	self._currentGold = GetMoney()
	self:LoadTrackingData()
	LibsDataBar:DebugLog('info', 'Currency plugin initialized')
end

---Lifecycle: Plugin enabled
function CurrencyPlugin:OnEnable()
	-- Register for money-related events
	self:RegisterEvent('PLAYER_MONEY', 'OnMoneyChanged')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnPlayerEnteringWorld')

	-- Setup auto-save timer
	if self:GetConfig('trackSession') or self:GetConfig('trackDaily') or self:GetConfig('trackWeekly') then
		local interval = self:GetConfig('autoSaveInterval')
		self.autoSaveTimer = C_Timer.NewTicker(interval, function()
			self:SaveTrackingData()
		end)
	end

	LibsDataBar:DebugLog('info', 'Currency plugin enabled')
end

---Lifecycle: Plugin disabled
function CurrencyPlugin:OnDisable()
	self:UnregisterAllEvents()

	-- Cancel auto-save timer
	if self.autoSaveTimer then
		self.autoSaveTimer:Cancel()
		self.autoSaveTimer = nil
	end

	-- Final save
	self:SaveTrackingData()

	LibsDataBar:DebugLog('info', 'Currency plugin disabled')
end

---Event handler for money changes
function CurrencyPlugin:OnMoneyChanged()
	local newMoney = GetMoney()
	if newMoney ~= self._currentGold then
		local oldMoney = self._currentGold
		self._currentGold = newMoney

		-- Update tracking
		self:UpdateTracking()

		-- Log significant changes
		local change = newMoney - oldMoney
		if math.abs(change) >= 10000 then -- Log changes >= 1 gold
			local changeText = change > 0 and ('+' .. self:FormatCurrentMoney(change)) or ('-' .. self:FormatCurrentMoney(math.abs(change)))
			LibsDataBar:DebugLog('info', 'Currency change: ' .. changeText)
		end

		-- Update LDB object if available
		if self._ldbObject and self._ldbObject.UpdateLDB then self._ldbObject:UpdateLDB() end

		-- Trigger plugin update (for legacy compatibility)
		if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
	end
end

---Event handler for entering world
function CurrencyPlugin:OnPlayerEnteringWorld()
	-- Load tracking data for this character
	self:LoadTrackingData()
	self._currentGold = GetMoney()
	self:UpdateTracking()

	-- Update LDB object if available
	if self._ldbObject and self._ldbObject.UpdateLDB then self._ldbObject:UpdateLDB() end
end

---Helper: Register for an event
---@param event string Event name
---@param method string Method name to call
function CurrencyPlugin:RegisterEvent(event, method)
	LibsDataBar.events:RegisterEvent(event, function(...)
		if self[method] then self[method](self, ...) end
	end, { owner = self.id })
end

---Helper: Unregister all events
function CurrencyPlugin:UnregisterAllEvents()
	-- This would need to be implemented in the event system
	LibsDataBar:DebugLog('info', 'Currency plugin events unregistered')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function CurrencyPlugin:GetConfig(key)
	return LibsDataBar:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or currencyDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function CurrencyPlugin:SetConfig(key, value)
	return LibsDataBar:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize the plugin
CurrencyPlugin:OnInitialize()

-- Register as LibDataBroker object for standardized plugin system
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
	local currencyLDBObject = LDB:NewDataObject('LibsDataBar_Currency', {
		type = 'data source',
		text = CurrencyPlugin:GetText(),
		icon = CurrencyPlugin:GetIcon(),
		label = CurrencyPlugin.name,

		-- Forward methods to CurrencyPlugin with database access preserved
		OnClick = function(self, button)
			CurrencyPlugin:OnClick(button)
		end,

		OnTooltipShow = function(tooltip)
			local tooltipText = CurrencyPlugin:GetTooltip()
			-- Handle both \n and \\n newline formats
			tooltipText = tooltipText:gsub('\\n', '\n')
			local lines = { strsplit('\n', tooltipText) }
			for i, line in ipairs(lines) do
				if i == 1 then
					tooltip:SetText(line)
				else
					tooltip:AddLine(line, 1, 1, 1, true)
				end
			end
		end,

		-- Update method to refresh LDB object
		UpdateLDB = function(self)
			self.text = CurrencyPlugin:GetText()
			self.icon = CurrencyPlugin:GetIcon()
		end,
	})

	-- Store reference for updates
	CurrencyPlugin._ldbObject = currencyLDBObject

	LibsDataBar:DebugLog('info', 'Currency plugin registered as LibDataBroker object')
else
	LibsDataBar:DebugLog('error', 'LibDataBroker not available for Currency plugin')
end

-- Return plugin for external access
return CurrencyPlugin
