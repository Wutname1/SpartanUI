---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Reputation.lua
LibsDataBar Reputation Plugin
Displays faction reputation progress and standing
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Plugin Definition
---@class ReputationPlugin : Plugin
local ReputationPlugin = {
	-- Required metadata
	id = 'LibsDataBar_Reputation',
	name = 'Reputation',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Character',
	description = 'Displays faction reputation progress and standings',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_watchedFaction = nil,
	_sessionGains = {},
	_sessionStartTime = 0,
}

-- Plugin Configuration Defaults
local reputationDefaults = {
	displayFormat = 'progress', -- 'progress', 'standing', 'values', 'percent', 'paragon_rewards'
	autoTrackHighest = false, -- Auto-track faction with highest recent gains
	showSessionGains = true,
	colorByStanding = true,
	abbreviateValues = true,
	trackParagon = true, -- Track paragon reputation for max level factions
	showMultipleFactions = false,
	maxFactionsShown = 3,
	showParagonRewards = true, -- Show available paragon rewards
	paragonRewardPriority = true, -- Prioritize factions with available rewards
}

-- Reputation standing colors and names
local STANDING_INFO = {
	[1] = { name = 'Hated', color = '|cFFCC2222', short = 'Hated' },
	[2] = { name = 'Hostile', color = '|cFFFF0000', short = 'Hostile' },
	[3] = { name = 'Unfriendly', color = '|cFFEE6622', short = 'Unfriendly' },
	[4] = { name = 'Neutral', color = '|cFFFFFF00', short = 'Neutral' },
	[5] = { name = 'Friendly', color = '|cFF00FF00', short = 'Friendly' },
	[6] = { name = 'Honored', color = '|cFF00FF88', short = 'Honored' },
	[7] = { name = 'Revered', color = '|cFF0080FF', short = 'Revered' },
	[8] = { name = 'Exalted', color = '|cFF9900FF', short = 'Exalted' },
}

---Required: Get the display text for this plugin
---@return string text Display text
function ReputationPlugin:GetText()
	local displayFormat = self:GetConfig('displayFormat')
	local colorByStanding = self:GetConfig('colorByStanding')
	local abbreviateValues = self:GetConfig('abbreviateValues')
	
	local watchedFactionData = self:GetWatchedFactionData()
	
	if not watchedFactionData then
		return 'No Watched Faction'
	end
	
	local name = watchedFactionData.name
	local standing = watchedFactionData.standingId
	local current = watchedFactionData.current
	local max = watchedFactionData.max
	local percent = max > 0 and (current / max * 100) or 0
	local standingInfo = STANDING_INFO[standing] or STANDING_INFO[4]
	
	local text = ''
	
	if displayFormat == 'standing' then
		text = string.format('%s: %s', name, standingInfo.short)
	elseif displayFormat == 'values' then
		local currentText = abbreviateValues and self:AbbreviateNumber(current) or tostring(current)
		local maxText = abbreviateValues and self:AbbreviateNumber(max) or tostring(max)
		text = string.format('%s: %s/%s', name, currentText, maxText)
	elseif displayFormat == 'percent' then
		text = string.format('%s: %.1f%%', name, percent)
	elseif displayFormat == 'paragon_rewards' then
		-- Show paragon reward status
		local paragonRewardData = self:GetParagonRewardStatus()
		if paragonRewardData and #paragonRewardData > 0 then
			local rewardCount = #paragonRewardData
			text = string.format('%d Paragon Reward%s Available', rewardCount, rewardCount == 1 and '' or 's')
			-- Use gold color to indicate rewards available
			colorByStanding = false -- Override color setting
			text = '|cFFFFD700' .. text .. '|r'
		else
			text = 'No Paragon Rewards'
		end
	else -- 'progress' default
		if standing == 8 and self:GetConfig('trackParagon') then
			-- Handle paragon reputation
			local paragonData = self:GetParagonData(watchedFactionData.factionId)
			if paragonData then
				if paragonData.hasReward then
					text = string.format('%s: %s Paragon |cFFFFD700(Reward!)|r', name, paragonData.level)
				else
					text = string.format('%s: %s Paragon', name, paragonData.level)
				end
			else
				text = string.format('%s: %s', name, standingInfo.short)
			end
		else
			text = string.format('%s: %.0f%% %s', name, percent, standingInfo.short)
		end
	end
	
	-- Apply standing color if enabled
	if colorByStanding then
		text = standingInfo.color .. text .. '|r'
	end
	
	return text
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function ReputationPlugin:GetIcon()
	local displayFormat = self:GetConfig('displayFormat')
	
	-- Check for paragon rewards first (highest priority)
	if displayFormat == 'paragon_rewards' or self:GetConfig('paragonRewardPriority') then
		local paragonRewards = self:GetParagonRewardStatus()
		if paragonRewards and #paragonRewards > 0 then
			return 'Interface\\Icons\\INV_Misc_Gift_02' -- Gift box for available rewards
		end
	end
	
	local watchedFactionData = self:GetWatchedFactionData()
	
	if not watchedFactionData then
		return 'Interface\\Icons\\Achievement_Reputation_01'
	end
	
	local standing = watchedFactionData.standingId
	
	-- Check if watched faction has paragon reward
	if standing == 8 and self:GetConfig('trackParagon') then
		local paragonData = self:GetParagonData(watchedFactionData.factionId)
		if paragonData and paragonData.hasReward then
			return 'Interface\\Icons\\INV_Misc_Gift_02' -- Gift box for paragon reward
		end
	end
	
	-- Return appropriate reputation icon based on standing
	if standing <= 2 then
		return 'Interface\\Icons\\Achievement_Reputation_08' -- Hated/Hostile
	elseif standing == 3 then
		return 'Interface\\Icons\\Achievement_Reputation_07' -- Unfriendly
	elseif standing == 4 then
		return 'Interface\\Icons\\Achievement_Reputation_06' -- Neutral
	elseif standing == 5 then
		return 'Interface\\Icons\\Achievement_Reputation_05' -- Friendly
	elseif standing == 6 then
		return 'Interface\\Icons\\Achievement_Reputation_04' -- Honored
	elseif standing == 7 then
		return 'Interface\\Icons\\Achievement_Reputation_03' -- Revered
	elseif standing == 8 then
		return 'Interface\\Icons\\Achievement_Reputation_01' -- Exalted
	else
		return 'Interface\\Icons\\Achievement_Reputation_06' -- Default
	end
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function ReputationPlugin:GetTooltip()
	local watchedFactionData = self:GetWatchedFactionData()
	
	if not watchedFactionData then
		local tooltip = 'Reputation Tracker:\\n\\n'
		tooltip = tooltip .. 'No faction is currently being watched.\\n'
		tooltip = tooltip .. 'Open your reputation panel and click the\\n'
		tooltip = tooltip .. 'checkbox next to a faction to track it.\\n\\n'
		tooltip = tooltip .. 'Left-click: Open Reputation panel\\n'
		tooltip = tooltip .. 'Right-click: Configuration options'
		return tooltip
	end
	
	local name = watchedFactionData.name
	local standing = watchedFactionData.standingId
	local current = watchedFactionData.current
	local max = watchedFactionData.max
	local percent = max > 0 and (current / max * 100) or 0
	local standingInfo = STANDING_INFO[standing] or STANDING_INFO[4]
	
	local tooltip = string.format('Reputation: %s\\n\\n', name)
	
	-- Current standing information
	tooltip = tooltip .. string.format('Standing: %s%s|r\\n', standingInfo.color, standingInfo.name)
	
	if standing < 8 then
		tooltip = tooltip .. string.format('Progress: %d / %d (%.1f%%)\\n', current, max, percent)
		tooltip = tooltip .. string.format('Remaining: %d points\\n', max - current)
		
		-- Estimate reputation needed for next standing
		local nextStandingPoints = self:GetPointsToNextStanding(standing)
		if nextStandingPoints > 0 then
			tooltip = tooltip .. string.format('To Next Standing: %d points\\n', nextStandingPoints - current)
		end
	else
		-- Exalted faction
		tooltip = tooltip .. string.format('Points: %d\\n', current)
		
		-- Paragon information
		if self:GetConfig('trackParagon') then
			local paragonData = self:GetParagonData(watchedFactionData.factionId)
			if paragonData then
				tooltip = tooltip .. string.format('Paragon Level: %d\\n', paragonData.level)
				tooltip = tooltip .. string.format('Paragon Progress: %d / %d\\n', paragonData.current, paragonData.max)
			end
		end
	end
	
	-- Session gains information
	if self:GetConfig('showSessionGains') then
		local sessionGain = self._sessionGains[watchedFactionData.factionId] or 0
		if sessionGain > 0 then
			tooltip = tooltip .. string.format('\\nSession Gain: +%d reputation\\n', sessionGain)
			
			local sessionTime = GetTime() - self._sessionStartTime
			if sessionTime > 0 then
				local repPerHour = (sessionGain / sessionTime) * 3600
				tooltip = tooltip .. string.format('Rep/Hour: %.0f\\n', repPerHour)
				
				if standing < 8 and max > current then
					local hoursToMax = (max - current) / repPerHour
					tooltip = tooltip .. string.format('Time to Next: %s\\n', self:FormatTime(hoursToMax * 3600))
				end
			end
		else
			tooltip = tooltip .. '\\nNo session gains yet\\n'
		end
	end
	
	-- Paragon reward information
	local paragonRewards = self:GetParagonRewardStatus()
	if paragonRewards and #paragonRewards > 0 then
		tooltip = tooltip .. string.format('\\n|cFFFFD700Available Paragon Rewards (%d):|r\\n', #paragonRewards)
		for _, reward in ipairs(paragonRewards) do
			tooltip = tooltip .. string.format('|cFFFFD700• %s (Paragon %d)|r\\n', reward.name, reward.paragonLevel)
		end
	end
	
	-- Multiple factions information
	if self:GetConfig('showMultipleFactions') then
		local topFactions = self:GetTopReputationChanges()
		if #topFactions > 1 then
			tooltip = tooltip .. '\\nOther Active Factions:\\n'
			for i = 2, math.min(#topFactions, self:GetConfig('maxFactionsShown')) do
				local faction = topFactions[i]
				local factionStanding = STANDING_INFO[faction.standing] or STANDING_INFO[4]
				tooltip = tooltip .. string.format('%s%s: +%d|r\\n', 
					factionStanding.color, faction.name, faction.sessionGain)
			end
		end
	end
	
	tooltip = tooltip .. '\\nControls:\\n'
	tooltip = tooltip .. 'Left-click: Open Reputation panel\\n'
	tooltip = tooltip .. 'Right-click: Change display format\\n'
	tooltip = tooltip .. 'Middle-click: Reset session gains'
	
	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function ReputationPlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Open reputation panel
		ToggleCharacter('ReputationFrame')
	elseif button == 'RightButton' then
		-- Cycle display formats
		self:CycleDisplayFormat()
	elseif button == 'MiddleButton' then
		-- Reset session gains
		self:ResetSessionGains()
		LibsDataBar:DebugLog('info', 'Reputation session gains reset')
	end
end

---Get data for the currently watched faction
---@return table? factionData Watched faction data or nil
function ReputationPlugin:GetWatchedFactionData()
	-- Use modern API if available, otherwise fall back to legacy method
	if C_Reputation and C_Reputation.GetWatchedFactionData then
		local factionData = C_Reputation.GetWatchedFactionData()
		if factionData then
			return {
				index = factionData.watchedFactionIndex,
				name = factionData.name,
				standingId = factionData.reaction,
				current = factionData.currentStanding - factionData.currentReactionThreshold,
				max = factionData.nextReactionThreshold - factionData.currentReactionThreshold,
				factionId = factionData.factionID,
				barMin = factionData.currentReactionThreshold,
				barMax = factionData.nextReactionThreshold,
				barValue = factionData.currentStanding,
			}
		end
	else
		-- Legacy API fallback
		local numFactions = GetNumFactions and GetNumFactions() or 0
		
		for i = 1, numFactions do
			local name, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, 
				isHeader, isCollapsed, hasRep, isWatched, isChild, factionId = GetFactionInfo(i)
				
			if isWatched and not isHeader then
				return {
					index = i,
					name = name,
					standingId = standingId,
					current = barValue - barMin,
					max = barMax - barMin,
					factionId = factionId,
					barMin = barMin,
					barMax = barMax,
					barValue = barValue,
				}
			end
		end
	end
	
	return nil
end

---Get paragon reputation data for a faction
---@param factionId number Faction ID
---@return table? paragonData Paragon data or nil
function ReputationPlugin:GetParagonData(factionId)
	if not C_Reputation.IsFactionParagon then return nil end
	
	local currentValue, threshold, rewardQuestId, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionId)
	
	if currentValue and threshold then
		local level = math.floor(currentValue / threshold)
		local current = currentValue % threshold
		
		return {
			level = level,
			current = current,
			max = threshold,
			hasReward = hasRewardPending,
			questId = rewardQuestId,
		}
	end
	
	return nil
end

---Get all factions with available paragon rewards
---@return table paragonRewards List of factions with available paragon rewards
function ReputationPlugin:GetParagonRewardStatus()
	if not self:GetConfig('showParagonRewards') then return {} end
	if not C_Reputation.IsFactionParagon then return {} end
	
	local paragonRewards = {}
	local numFactions = GetNumFactions()
	
	for i = 1, numFactions do
		local name, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, 
			isHeader, isCollapsed, hasRep, isWatched, isChild, factionId = GetFactionInfo(i)
			
		if not isHeader and factionId and standingId == 8 then -- Exalted factions only
			local paragonData = self:GetParagonData(factionId)
			if paragonData and paragonData.hasReward then
				table.insert(paragonRewards, {
					name = name,
					factionId = factionId,
					questId = paragonData.questId,
					paragonLevel = paragonData.level,
				})
			end
		end
	end
	
	return paragonRewards
end

---Get points required for next standing
---@param currentStanding number Current standing ID
---@return number points Points required for next standing
function ReputationPlugin:GetPointsToNextStanding(currentStanding)
	-- Reputation thresholds for each standing level
	local standingThresholds = {
		[1] = 36000, -- Hated to Hostile
		[2] = 3000,  -- Hostile to Unfriendly  
		[3] = 3000,  -- Unfriendly to Neutral
		[4] = 3000,  -- Neutral to Friendly
		[5] = 6000,  -- Friendly to Honored
		[6] = 12000, -- Honored to Revered
		[7] = 21000, -- Revered to Exalted
		[8] = 0,     -- Exalted (max)
	}
	
	return standingThresholds[currentStanding] or 0
end

---Get top reputation changes this session
---@return table factions Sorted list of factions by session gain
function ReputationPlugin:GetTopReputationChanges()
	local factions = {}
	
	for factionId, sessionGain in pairs(self._sessionGains) do
		if sessionGain > 0 then
			local factionData = self:GetFactionDataById(factionId)
			if factionData then
				table.insert(factions, {
					id = factionId,
					name = factionData.name,
					standing = factionData.standingId,
					sessionGain = sessionGain,
				})
			end
		end
	end
	
	-- Sort by session gains (highest first)
	table.sort(factions, function(a, b)
		return a.sessionGain > b.sessionGain
	end)
	
	return factions
end

---Get faction data by faction ID
---@param factionId number Faction ID to look up
---@return table? factionData Faction data or nil
function ReputationPlugin:GetFactionDataById(factionId)
	local numFactions = GetNumFactions()
	
	for i = 1, numFactions do
		local name, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, 
			isHeader, isCollapsed, hasRep, isWatched, isChild, id = GetFactionInfo(i)
			
		if id == factionId and not isHeader then
			return {
				index = i,
				name = name,
				standingId = standingId,
				factionId = id,
			}
		end
	end
	
	return nil
end

---Abbreviate large reputation values
---@param number number Number to abbreviate
---@return string abbreviated Abbreviated number string
function ReputationPlugin:AbbreviateNumber(number)
	if number >= 1000000 then
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
function ReputationPlugin:FormatTime(seconds)
	if seconds <= 0 then return '0s' end
	
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	
	if hours > 0 then
		return string.format('%dh %dm', hours, minutes)
	elseif minutes > 0 then
		return string.format('%dm', minutes)
	else
		return string.format('%.0fs', seconds)
	end
end

---Reset session reputation gains
function ReputationPlugin:ResetSessionGains()
	self._sessionGains = {}
	self._sessionStartTime = GetTime()
end

---Cycle through different display formats
function ReputationPlugin:CycleDisplayFormat()
	local formats = {'progress', 'standing', 'values', 'percent', 'paragon_rewards'}
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
	LibsDataBar:DebugLog('info', 'Reputation display format changed to: ' .. nextFormat)
end

---Get configuration options
---@return table options AceConfig options table
function ReputationPlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			displayFormat = {
				type = 'select',
				name = 'Display Format',
				desc = 'Choose how to display reputation information',
				order = 10,
				values = {
					progress = 'Progress Percentage',
					standing = 'Standing Name',
					values = 'Current/Max Values',
					percent = 'Percentage Only',
					paragon_rewards = 'Available Paragon Rewards',
				},
				get = function()
					return self:GetConfig('displayFormat')
				end,
				set = function(_, value)
					self:SetConfig('displayFormat', value)
				end,
			},
			colorByStanding = {
				type = 'toggle',
				name = 'Color by Standing',
				desc = 'Use faction standing colors',
				order = 20,
				get = function()
					return self:GetConfig('colorByStanding')
				end,
				set = function(_, value)
					self:SetConfig('colorByStanding', value)
				end,
			},
			abbreviateValues = {
				type = 'toggle',
				name = 'Abbreviate Values',
				desc = 'Use K/M suffixes for large reputation values',
				order = 30,
				get = function()
					return self:GetConfig('abbreviateValues')
				end,
				set = function(_, value)
					self:SetConfig('abbreviateValues', value)
				end,
			},
			showSessionGains = {
				type = 'toggle',
				name = 'Show Session Gains',
				desc = 'Track and display session reputation gains',
				order = 40,
				get = function()
					return self:GetConfig('showSessionGains')
				end,
				set = function(_, value)
					self:SetConfig('showSessionGains', value)
				end,
			},
			trackParagon = {
				type = 'toggle',
				name = 'Track Paragon Reputation',
				desc = 'Show paragon levels for exalted factions',
				order = 50,
				get = function()
					return self:GetConfig('trackParagon')
				end,
				set = function(_, value)
					self:SetConfig('trackParagon', value)
				end,
			},
			showMultipleFactions = {
				type = 'toggle',
				name = 'Show Multiple Factions',
				desc = 'Display other active factions in tooltip',
				order = 60,
				get = function()
					return self:GetConfig('showMultipleFactions')
				end,
				set = function(_, value)
					self:SetConfig('showMultipleFactions', value)
				end,
			},
			showParagonRewards = {
				type = 'toggle',
				name = 'Show Paragon Rewards',
				desc = 'Display available paragon rewards in tooltip and tracking',
				order = 70,
				get = function()
					return self:GetConfig('showParagonRewards')
				end,
				set = function(_, value)
					self:SetConfig('showParagonRewards', value)
				end,
			},
			paragonRewardPriority = {
				type = 'toggle',
				name = 'Prioritize Paragon Rewards',
				desc = 'Show reward icon when any faction has available paragon rewards',
				order = 80,
				get = function()
					return self:GetConfig('paragonRewardPriority')
				end,
				set = function(_, value)
					self:SetConfig('paragonRewardPriority', value)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function ReputationPlugin:GetDefaultConfig()
	return reputationDefaults
end

---Lifecycle: Plugin initialization
function ReputationPlugin:OnInitialize()
	self._sessionStartTime = GetTime()
	LibsDataBar:DebugLog('info', 'Reputation plugin initialized')
end

---Lifecycle: Plugin enabled
function ReputationPlugin:OnEnable()
	-- Register for reputation-related events
	self:RegisterEvent('UPDATE_FACTION', 'OnReputationUpdate')
	self:RegisterEvent('QUEST_TURNED_IN', 'OnQuestTurnIn')
	self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE', 'OnFactionChange')
	LibsDataBar:DebugLog('info', 'Reputation plugin enabled')
end

---Lifecycle: Plugin disabled
function ReputationPlugin:OnDisable()
	self:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Reputation plugin disabled')
end

---Event handler for reputation updates
function ReputationPlugin:OnReputationUpdate()
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Event handler for quest turn-ins (potential reputation gains)
function ReputationPlugin:OnQuestTurnIn()
	-- Small delay to allow reputation to update
	C_Timer.NewTimer(0.5, function()
		self:OnReputationUpdate()
	end)
end

---Event handler for faction change messages
---@param message string The faction change message
function ReputationPlugin:OnFactionChange(message)
	-- Parse reputation gain from combat message
	local factionName, amount = message:match('reputation with (.+) by (%d+)')
	
	if factionName and amount then
		amount = tonumber(amount)
		local factionId = self:GetFactionIdByName(factionName)
		
		if factionId then
			self._sessionGains[factionId] = (self._sessionGains[factionId] or 0) + amount
			LibsDataBar:DebugLog('info', string.format('Reputation gain: %s +%d', factionName, amount))
		end
	end
	
	self:OnReputationUpdate()
end

---Get faction ID by name (helper function)
---@param name string Faction name
---@return number? factionId Faction ID or nil
function ReputationPlugin:GetFactionIdByName(name)
	local numFactions = GetNumFactions()
	
	for i = 1, numFactions do
		local factionName, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionId = GetFactionInfo(i)
		
		if factionName == name and not isHeader then
			return factionId
		end
	end
	
	return nil
end

---Helper: Register for an event
---@param event string Event name
---@param method string Method name to call
function ReputationPlugin:RegisterEvent(event, method)
	LibsDataBar.events:RegisterEvent(event, function(...)
		if self[method] then self[method](self, ...) end
	end, { owner = self.id })
end

---Helper: Unregister all events
function ReputationPlugin:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Reputation plugin events unregistered')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function ReputationPlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or reputationDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function ReputationPlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize and register the plugin
ReputationPlugin:OnInitialize()

-- Register with LibsDataBar
if LibsDataBar:RegisterPlugin(ReputationPlugin) then
	LibsDataBar:DebugLog('info', 'Reputation plugin registered successfully')
else
	LibsDataBar:DebugLog('error', 'Failed to register Reputation plugin')
end

-- Return plugin for external access
return ReputationPlugin