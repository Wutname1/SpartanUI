---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Friends.lua
LibsDataBar Friends Plugin
Displays online friends, guild members, and Battle.net friends
--]===]

-- Get the LibsDataBar addon
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- Plugin Definition
---@class FriendsPlugin : Plugin
local FriendsPlugin = {
	-- Required metadata
	id = 'LibsDataBar_Friends',
	name = 'Friends',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Social',
	description = 'Displays online friends, guild members, and Battle.net friends',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_playerRealm = nil,
	_lastUpdate = 0,
	_updateThrottle = 1.0, -- Throttle updates to once per second
}

-- Plugin Configuration Defaults
local friendsDefaults = {
	displayFormat = 'combined', -- 'combined', 'friends', 'guild', 'realid', 'detailed'
	showLabel = true,
	showMobileIndicators = true,
	showStatusIcons = true,
	showGroupMembers = true,
	showNotes = true,
	showBroadcasts = true,
	enableTooltip = true,
	clickAction = 'friends_frame', -- 'friends_frame', 'guild_frame', 'none'
	showIcon = true,
	colorByStatus = true,
	separateGuildLabel = false, -- Show guild name instead of "Friends:"
}

-- Status and mobile icons
local MOBILE_HERE_ICON = '|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat:0:0:0:0:16:16:0:16:0:16:73:177:73|t'
local MOBILE_BUSY_ICON = '|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-BusyMobile:0:0:0:0:16:16:0:16:0:16|t'
local MOBILE_AWAY_ICON = '|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-AwayMobile:0:0:0:0:16:16:0:16:0:16|t'
local CHECK_ICON = '|TInterface\\Buttons\\UI-CheckBox-Check:0:0|t'

-- Color constants
local COLORS = {
	realid = '00A2E8',
	friends = 'FFFFFF',
	guild = '00FF00',
	mobile = 'CCCCCC',
	separator = 'FFD200',
	offline = '808080',
	online = '40FF40',
}

-- Initialize plugin
function FriendsPlugin:OnInitialize()
	-- Cache player info for group member detection
	self._playerRealm = GetRealmName()

	-- Set default configuration
	self:SetDefaultConfig(friendsDefaults)

	-- Register for events
	self:RegisterForEvents()
end

-- Register events
function FriendsPlugin:RegisterForEvents()
	self:RegisterEvent('FRIENDLIST_UPDATE')
	self:RegisterEvent('BN_FRIEND_INFO_CHANGED')
	self:RegisterEvent('BN_FRIEND_ACCOUNT_ONLINE')
	self:RegisterEvent('BN_FRIEND_ACCOUNT_OFFLINE')
	self:RegisterEvent('GUILD_ROSTER_UPDATE')
	self:RegisterEvent('GROUP_ROSTER_UPDATE')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

-- Event handler
function FriendsPlugin:OnEvent(event, ...)
	-- Throttle updates to prevent spam
	local now = GetTime()
	if now - self._lastUpdate < self._updateThrottle then return end
	self._lastUpdate = now

	-- Update display
	self:Update()
end

-- Parse and return Battle.net friends information
---@return table friends, table bnetFriends
function FriendsPlugin:ParseRealID()
	local friends, bnets = {}, {}
	local _, numOnline = BNGetNumFriends()

	-- Handle case where numOnline might be nil (during loading or when Battle.net isn't ready)
	if not numOnline or numOnline == 0 then return friends, bnets end

	for i = 1, numOnline do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			local toons, focus, bnet = {}, nil, nil

			for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) do
				local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j)
				if gameAccountInfo then
					local toon = {
						name = gameAccountInfo.characterName,
						client = gameAccountInfo.clientProgram,
						realmName = gameAccountInfo.realmName,
						faction = gameAccountInfo.factionName,
						race = gameAccountInfo.raceName,
						class = gameAccountInfo.className,
						zone = gameAccountInfo.areaName,
						level = gameAccountInfo.characterLevel,
						location = gameAccountInfo.areaName or gameAccountInfo.richPresence,
					}

					if gameAccountInfo.clientProgram == BNET_CLIENT_APP or gameAccountInfo.clientProgram == 'BSAp' then
						if not bnet then bnet = toon end
					elseif gameAccountInfo.hasFocus then
						if focus then table.insert(toons, 1, focus) end
						focus = toon
					else
						table.insert(toons, toon)
					end
				end
			end

			-- Fallback if no focus character
			if not focus and #toons > 0 then
				focus = toons[1]
				table.remove(toons, 1)
			end

			if focus or bnet then
				local friend = {
					bnetAccountID = accountInfo.bnetAccountID,
					accountName = accountInfo.accountName,
					battleTag = accountInfo.isBattleTagFriend and accountInfo.battleTag or accountInfo.accountName,
					isAFK = accountInfo.gameAccountInfo.isAFK,
					isDND = accountInfo.gameAccountInfo.isDND,
					broadcastText = accountInfo.broadcastText,
					note = accountInfo.note,
					focus = focus,
					alts = toons,
					bnet = bnet,
				}

				if focus then table.insert(friends, friend) end
				if bnet then table.insert(bnets, friend) end
			end
		end
	end

	return friends, bnets
end

-- Get character friends data
---@return table
function FriendsPlugin:GetFriendsData()
	local friends = {}
	local numOnline = C_FriendList.GetNumOnlineFriends()

	-- Handle case where numOnline might be nil (during loading or when friends list isn't ready)
	if not numOnline or numOnline == 0 then return friends end

	for i = 1, numOnline do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then table.insert(friends, info) end
	end

	return friends
end

-- Get guild members data
---@return table
function FriendsPlugin:GetGuildData()
	local members = {}

	if not IsInGuild() then return members end

	local numTotal, numOnline = GetNumGuildMembers()

	-- Handle case where numOnline might be nil (during loading or when guild roster isn't ready)
	if not numOnline or numOnline == 0 then return members end

	for i = 1, numOnline do
		local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i)

		if name and online then
			table.insert(members, {
				name = Ambiguate(name, 'guild'),
				fullName = name,
				rank = rank,
				rankIndex = rankIndex,
				level = level,
				class = class,
				classFileName = classFileName,
				zone = zone,
				note = note,
				officerNote = officerNote,
				status = status,
				isMobile = isMobile,
			})
		end
	end

	return members
end

-- Check if a character is in the player's group
---@param name string
---@param realmName? string
---@return boolean
function FriendsPlugin:IsInGroup(name, realmName)
	if not IsInGroup() then return false end

	local fullName = name
	if realmName and realmName ~= self._playerRealm then fullName = name .. '-' .. realmName end

	return UnitInParty(fullName) or UnitInRaid(fullName)
end

-- Get status icon for AFK/DND
---@param status string|number
---@return string
function FriendsPlugin:GetStatusIcon(status)
	if not self:GetConfig('showStatusIcons') then return '' end

	if status == CHAT_FLAG_AFK or status == 1 then
		return '|T' .. FRIENDS_TEXTURE_AFK .. ':0|t'
	elseif status == CHAT_FLAG_DND or status == 2 then
		return '|T' .. FRIENDS_TEXTURE_DND .. ':0|t'
	end

	return ''
end

-- Color text by class
---@param text string
---@param class string
---@return string
function FriendsPlugin:ColorTextByClass(text, class)
	if not class then return text end

	local color = RAID_CLASS_COLORS[class]
	if color then return string.format('|c%s%s|r', color.colorStr, text) end

	return text
end

-- Required: Get the display text for this plugin
---@return string text Display text
function FriendsPlugin:GetText()
	local displayFormat = self:GetConfig('displayFormat')
	local showLabel = self:GetConfig('showLabel')
	local separateGuildLabel = self:GetConfig('separateGuildLabel')

	-- Get all data
	local realidFriends, bnetFriends = self:ParseRealID()
	local characterFriends = self:GetFriendsData()
	local guildMembers = self:GetGuildData()

	-- Count totals
	local realidCount = #realidFriends
	local bnetCount = #bnetFriends
	local friendsCount = #characterFriends
	local guildCount = #guildMembers

	local text = ''
	local components = {}

	-- Add label if enabled
	if showLabel then
		if separateGuildLabel and IsInGuild() then
			local guildName = GetGuildInfo('player') or 'Guild'
			text = guildName .. ': '
		else
			text = 'Friends: '
		end
	end

	-- Build display based on format
	if displayFormat == 'combined' then
		if realidCount > 0 then table.insert(components, string.format('|cff%s%d|r', COLORS.realid, realidCount)) end
		if friendsCount > 0 then table.insert(components, string.format('|cff%s%d|r', COLORS.friends, friendsCount)) end
		if guildCount > 0 then table.insert(components, string.format('|cff%s%d|r', COLORS.guild, guildCount)) end
		if self:GetConfig('showMobileIndicators') and bnetCount > 0 then table.insert(components, string.format('|cff%s%d|r', COLORS.mobile, bnetCount)) end
	elseif displayFormat == 'friends' then
		table.insert(components, string.format('|cff%s%d|r', COLORS.friends, friendsCount))
	elseif displayFormat == 'guild' then
		table.insert(components, string.format('|cff%s%d|r', COLORS.guild, guildCount))
	elseif displayFormat == 'realid' then
		table.insert(components, string.format('|cff%s%d|r', COLORS.realid, realidCount))
	elseif displayFormat == 'detailed' then
		local total = realidCount + friendsCount + guildCount
		if self:GetConfig('showMobileIndicators') then total = total + bnetCount end
		table.insert(components, string.format('|cff%s%d|r', COLORS.online, total))
	end

	if #components == 0 then return text .. '|cff' .. COLORS.offline .. '0|r' end

	return text .. table.concat(components, string.format(' |cff%s/|r ', COLORS.separator))
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function FriendsPlugin:GetIcon()
	return 'Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon'
end

-- Required: Update tooltip content
---@param tooltip GameTooltip
function FriendsPlugin:UpdateTooltip(tooltip)
	if not self:GetConfig('enableTooltip') then return end

	-- Get all data
	local realidFriends, bnetFriends = self:ParseRealID()
	local characterFriends = self:GetFriendsData()
	local guildMembers = self:GetGuildData()

	tooltip:AddLine(self.name, nil, 1, 1, 1)
	tooltip:AddLine(' ')

	-- RealID Friends Section
	if #realidFriends > 0 then
		tooltip:AddLine(string.format('|cff%sRealID Friends (%d)|r', COLORS.realid, #realidFriends))

		for _, friend in ipairs(realidFriends) do
			local focus = friend.focus
			if focus then
				local line = ''

				-- Group indicator
				if self:GetConfig('showGroupMembers') and self:IsInGroup(focus.name, focus.realmName) then line = line .. CHECK_ICON .. ' ' end

				-- Status icon
				line = line .. self:GetStatusIcon(friend.isAFK and CHAT_FLAG_AFK or (friend.isDND and CHAT_FLAG_DND or ''))

				-- Character name and level
				if focus.client == BNET_CLIENT_WOW then
					line = line .. self:ColorTextByClass(focus.name, focus.class)
					if focus.level then line = line .. string.format(' (%d)', focus.level) end
				else
					line = line .. (focus.name or 'Unknown')
				end

				-- Battle tag
				line = line .. string.format(' [|cff%s%s|r]', COLORS.realid, friend.battleTag)

				-- Location
				local location = focus.location or ''
				if location ~= '' then location = ' - ' .. location end

				tooltip:AddDoubleLine(line, location)

				-- Note
				if self:GetConfig('showNotes') and friend.note and friend.note ~= '' then tooltip:AddLine('  Note: ' .. friend.note, 0.8, 0.8, 0.8) end

				-- Broadcast
				if self:GetConfig('showBroadcasts') and friend.broadcastText and friend.broadcastText ~= '' then tooltip:AddLine('  ' .. friend.broadcastText, 0, 0.7, 1) end
			end
		end
		tooltip:AddLine(' ')
	end

	-- Character Friends Section
	if #characterFriends > 0 then
		tooltip:AddLine(string.format('|cff%sFriends (%d)|r', COLORS.friends, #characterFriends))

		for _, friend in ipairs(characterFriends) do
			local line = ''

			-- Group indicator
			if self:GetConfig('showGroupMembers') and self:IsInGroup(friend.name) then line = line .. CHECK_ICON .. ' ' end

			-- Status icon
			local status = ''
			if friend.afk then
				status = CHAT_FLAG_AFK
			elseif friend.dnd then
				status = CHAT_FLAG_DND
			end
			line = line .. self:GetStatusIcon(status)

			-- Name and level
			line = line .. self:ColorTextByClass(friend.name, friend.className)
			if friend.level then line = line .. string.format(' (%d)', friend.level) end

			-- Location
			local location = friend.area or ''

			tooltip:AddDoubleLine(line, location)

			-- Note
			if self:GetConfig('showNotes') and friend.notes and friend.notes ~= '' then tooltip:AddLine('  Note: ' .. friend.notes, 0.8, 0.8, 0.8) end
		end
		tooltip:AddLine(' ')
	end

	-- Guild Members Section
	if #guildMembers > 0 then
		local guildName = GetGuildInfo('player') or 'Guild'
		tooltip:AddLine(string.format('|cff%s%s (%d)|r', COLORS.guild, guildName, #guildMembers))

		for _, member in ipairs(guildMembers) do
			local line = ''

			-- Group indicator
			if self:GetConfig('showGroupMembers') and self:IsInGroup(member.name) then line = line .. CHECK_ICON .. ' ' end

			-- Mobile/Status icon
			if member.isMobile then
				if member.status == 2 then
					line = line .. MOBILE_BUSY_ICON
				elseif member.status == 1 then
					line = line .. MOBILE_AWAY_ICON
				else
					line = line .. MOBILE_HERE_ICON
				end
			else
				line = line .. self:GetStatusIcon(member.status)
			end

			-- Name and level
			line = line .. self:ColorTextByClass(member.name, member.classFileName)
			if member.level then line = line .. string.format(' (%d)', member.level) end

			-- Rank
			line = line .. ' - ' .. (member.rank or '')

			-- Location
			local location = member.zone or ''

			tooltip:AddDoubleLine(line, location)

			-- Note
			if self:GetConfig('showNotes') and member.note and member.note ~= '' then tooltip:AddLine('  Note: ' .. member.note, 0.8, 0.8, 0.8) end

			-- Officer note (if visible)
			if C_GuildInfo.CanViewOfficerNote() and member.officerNote and member.officerNote ~= '' then tooltip:AddLine('  Officer Note: ' .. member.officerNote, 0.7, 1, 0.7) end
		end
		tooltip:AddLine(' ')
	end

	-- Mobile Battle.net Friends Section
	if self:GetConfig('showMobileIndicators') and #bnetFriends > 0 then
		tooltip:AddLine(string.format('|cff%sBattle.net App (%d)|r', COLORS.mobile, #bnetFriends))

		for _, friend in ipairs(bnetFriends) do
			local bnet = friend.bnet
			if bnet then
				local line = ''

				-- Status icon
				line = line .. self:GetStatusIcon(friend.isAFK and CHAT_FLAG_AFK or (friend.isDND and CHAT_FLAG_DND or ''))

				-- Battle tag
				line = line .. string.format('|cff%s%s|r', COLORS.realid, friend.battleTag)

				tooltip:AddLine(line)

				-- Note
				if self:GetConfig('showNotes') and friend.note and friend.note ~= '' then tooltip:AddLine('  Note: ' .. friend.note, 0.8, 0.8, 0.8) end
			end
		end
		tooltip:AddLine(' ')
	end

	-- Usage instructions
	tooltip:AddLine('|cffFFFFFFLeft-click:|r Open Friends Frame')
	tooltip:AddLine('|cffFFFFFFRight-click:|r Plugin Options')
end

-- Handle clicks
function FriendsPlugin:OnClick(button)
	local clickAction = self:GetConfig('clickAction')

	if button == 'LeftButton' then
		if clickAction == 'friends_frame' then
			ToggleFriendsFrame(1)
		elseif clickAction == 'guild_frame' then
			ToggleGuildFrame()
		end
	elseif button == 'RightButton' then
		self:OpenConfig()
	end
end

-- Configuration options
function FriendsPlugin:GetConfigOptions()
	return {
		displayFormat = {
			name = 'Display Format',
			type = 'select',
			values = {
				combined = 'Combined (RealID/Friends/Guild)',
				friends = 'Character Friends Only',
				guild = 'Guild Members Only',
				realid = 'RealID Friends Only',
				detailed = 'Total Count',
			},
			desc = 'Choose what information to display in the data text',
			order = 1,
		},
		showLabel = {
			name = 'Show Label',
			type = 'toggle',
			desc = 'Show "Friends:" or guild name label before the counts',
			order = 2,
		},
		separateGuildLabel = {
			name = 'Show Guild Name as Label',
			type = 'toggle',
			desc = 'Show guild name instead of "Friends:" when in a guild',
			order = 3,
		},
		showIcon = {
			name = 'Show Icon',
			type = 'toggle',
			desc = 'Show the friends icon in the data text',
			order = 4,
		},
		showMobileIndicators = {
			name = 'Show Mobile Friends',
			type = 'toggle',
			desc = 'Include Battle.net app friends in display and tooltip',
			order = 5,
		},
		showStatusIcons = {
			name = 'Show Status Icons',
			type = 'toggle',
			desc = 'Display AFK/DND status icons in tooltip',
			order = 6,
		},
		showGroupMembers = {
			name = 'Show Group Members',
			type = 'toggle',
			desc = 'Indicate friends who are in your party/raid with a checkmark',
			order = 7,
		},
		showNotes = {
			name = 'Show Notes',
			type = 'toggle',
			desc = 'Display friend and guild member notes in tooltip',
			order = 8,
		},
		showBroadcasts = {
			name = 'Show Broadcasts',
			type = 'toggle',
			desc = 'Display RealID broadcast messages in tooltip',
			order = 9,
		},
		enableTooltip = {
			name = 'Enable Tooltip',
			type = 'toggle',
			desc = 'Show detailed information when hovering over the data text',
			order = 10,
		},
		colorByStatus = {
			name = 'Color by Status',
			type = 'toggle',
			desc = 'Color the text based on online/offline status',
			order = 11,
		},
		clickAction = {
			name = 'Click Action',
			type = 'select',
			values = {
				friends_frame = 'Open Friends Frame',
				guild_frame = 'Open Guild Frame',
				none = 'No Action',
			},
			desc = 'Action to perform when left-clicking the data text',
			order = 12,
		},
	}
end

---Get default configuration for this plugin
---@return table defaults Default configuration table
function FriendsPlugin:GetDefaultConfig()
	return friendsDefaults
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function FriendsPlugin:GetConfig(key)
	return LibsDataBar:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or friendsDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function FriendsPlugin:SetConfig(key, value)
	return LibsDataBar:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

---Lifecycle: Plugin enabled
function FriendsPlugin:OnEnable()
	LibsDataBar:DebugLog('info', 'Friends plugin enabled')
end

---Lifecycle: Plugin disabled
function FriendsPlugin:OnDisable()
	LibsDataBar:DebugLog('info', 'Friends plugin disabled')
end

-- Register as LibDataBroker object for standardized plugin system
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
	local friendsLDBObject = LDB:NewDataObject('LibsDataBar_Friends', {
		type = 'data source',
		text = FriendsPlugin:GetText(),
		icon = FriendsPlugin:GetIcon(),
		label = FriendsPlugin.name,

		-- Forward methods to FriendsPlugin with database access preserved
		OnClick = function(self, button)
			FriendsPlugin:OnClick(button)
		end,

		OnTooltipShow = function(tooltip)
			FriendsPlugin:UpdateTooltip(tooltip)
		end,

		-- Update method to refresh LDB object
		UpdateLDB = function(self)
			self.text = FriendsPlugin:GetText()
			self.icon = FriendsPlugin:GetIcon()
		end,
	})

	-- Store reference for updates
	FriendsPlugin._ldbObject = friendsLDBObject

	LibsDataBar:DebugLog('info', 'Friends plugin registered as LibDataBroker object')
else
	LibsDataBar:DebugLog('error', 'LibDataBroker not available for Friends plugin')
end
