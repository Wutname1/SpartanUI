---@class SUI
local SUI = SUI
local L = SUI.L
local StdUi = SUI.StdUi
---@class SUI.Module.Chatbox : SUI.Module, AceHook-3.0
local module = SUI:NewModule('Chatbox', 'AceHook-3.0')
module.description = 'Lightweight quality of life chat improvements'
----------------------------------------------------------------------------------------------------
local popup = CreateFrame('Frame', nil, UIParent)
local linkTypes = {
	item = true,
	enchant = true,
	spell = true,
	achievement = true,
	talent = true,
	glyph = true,
	currency = true,
	unit = true,
	quest = true,
}
local ChatLevelLog, nameColor = {}, {}

local LeaveCount = 0
local battleOver = false

local function StripTextures(object)
	for i = 1, object:GetNumRegions() do
		local region = select(i, object:GetRegions())
		if region and region:GetObjectType() == 'Texture' then region:SetTexture(nil) end
	end
end

function module:SetPopupText(text)
	popup.editBox:SetText(text)
	popup:Show()
end

function module:GetColor(className, isLocal)
	-- For modules that need to class color things
	if isLocal then
		local found
		for k, v in next, LOCALIZED_CLASS_NAMES_FEMALE do
			if v == className then
				className = k
				found = true
				break
			end
		end
		if not found then
			for k, v in next, LOCALIZED_CLASS_NAMES_MALE do
				if v == className then
					className = k
					break
				end
			end
		end
	end
	local tbl = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[className] or RAID_CLASS_COLORS[className]
	if not tbl then
		-- Seems to be a bug since 5.3 where the friends list is randomly empty and fires friendlist updates with an "Unknown" class.
		return ('%02x%02x%02x'):format(GRAY_FONT_COLOR.r * 255, GRAY_FONT_COLOR.g * 255, GRAY_FONT_COLOR.b * 255)
	end
	local color = ('%02x%02x%02x'):format(tbl.r * 255, tbl.g * 255, tbl.b * 255)
	return color
end

local function get_color(c)
	if type(c.r) == 'number' and type(c.g) == 'number' and type(c.b) == 'number' and type(c.a) == 'number' then return c.r, c.g, c.b, c.a end
	if type(c.r) == 'number' and type(c.g) == 'number' and type(c.b) == 'number' then return c.r, c.g, c.b, 0.8 end
	return 1.0, 1.0, 1.0, 0.8
end

local function get_var_color(a1, a2, a3, a4)
	local r, g, b, a

	if type(a1) == 'table' then
		r, g, b, a = get_color(a1)
	elseif type(a1) == 'number' and type(a2) == 'number' and type(a3) == 'number' and type(a4) == 'number' then
		r, g, b, a = a1, a2, a3, a4
	elseif type(a1) == 'number' and type(a2) == 'number' and type(a3) == 'number' and type(a4) == 'nil' then
		r, g, b, a = a1, a2, a3, 0.8
	else
		r, g, b, a = 1.0, 1.0, 1.0, 0.8
	end

	return r, g, b, a
end

local function to225(r, g, b, a)
	return r * 255, g * 255, b * 255, a
end

local function GetHexColor(a1, a2, a3, a4)
	return string.format('%02x%02x%02x', to225(get_var_color(a1, a2, a3, a4)))
end

local changeName = function(fullName, misc, nameToChange, colon)
	local name = Ambiguate(fullName, 'none')
	--Do this here instead of listening to the guild event, as the event is slower than a player login
	--leading to player logins lacking color/level, unless we held a database of the entire guild.
	--Since the event usually fires when a player logs in, doing it this way should be virtually the same.
	local hasColor = nameToChange:find('|c', nil, true)
	if (nameColor and not hasColor and not nameColor[name]) or (ChatLevelLog and not ChatLevelLog[name]) then
		for i = 1, GetNumGuildMembers() do
			local n, _, _, l, _, _, _, _, _, _, c = GetGuildRosterInfo(i)
			if n then
				n = Ambiguate(n, 'none')
				if n == name then
					if ChatLevelLog and l and l > 0 then ChatLevelLog[n] = tostring(l) end
					if nameColor and c and not hasColor then nameColor[n] = module:GetColor(c) end
					break
				end
			end
		end
	end
	if nameColor and not hasColor then
		--If the displayed name was an in-chat who result, take the data and color it.
		if not nameColor[name] then
			local num = C_FriendList.GetNumWhoResults()
			for i = 1, num do
				local tbl = C_FriendList.GetWhoInfo(i)
				local n, l, c = tbl.fullName, tbl.level, tbl.filename
				if n == name and l and l > 0 then
					if ChatLevelLog then ChatLevelLog[n] = tostring(l) end
					if nameColor and c then nameColor[n] = module:GetColor(c) end
					break
				end
			end
		end
		if nameColor[name] then
			nameToChange = '|cFF' .. nameColor[name] .. nameToChange .. '|r' -- All this code just to color player log in events, worth it?
		end
	end
	if ChatLevelLog and ChatLevelLog[name] and module.DB.playerlevel then
		local color = GetHexColor(GetQuestDifficultyColor(ChatLevelLog[name]))

		nameToChange = '|cff' .. color .. ChatLevelLog[name] .. '|r:' .. nameToChange
	end
	return '|Hplayer:' .. fullName .. misc .. '[' .. nameToChange .. ']' .. (colon == ':' and ' ' or colon) .. '|h'
end

function module:PlayerName(text)
	text = text:gsub('|Hplayer:([^:|]+)([^%[]+)%[([^%]]+)%]|h(:?)', changeName)
	return text
end

function module:TimeStamp(text)
	if module.DB.timestampFormat == '' then return text end
	text = date('|cff7d7d7d[' .. module.DB.timestampFormat .. ']|r ') .. text
	return text
end

local function shortenChannel(text)
	if not module.DB.shortenChannelNames then return text end

	local rplc = {
		'[I]', --Instance
		'[IL]', --Instance Leader
		'[G]', --Guild
		'[P]', --Party
		'[PL]', --Party Leader
		'[PL]', --Party Leader (Guide)
		'[O]', --Officer
		'[R]', --Raid
		'[RL]', --Raid Leader
		'[RW]', --Raid Warning
		'[%1]', --Custom Channels
	}
	local gsub = gsub
	local chn = {
		gsub(CHAT_INSTANCE_CHAT_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_INSTANCE_CHAT_LEADER_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_GUILD_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_PARTY_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_PARTY_LEADER_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_PARTY_GUIDE_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_OFFICER_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_RAID_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_RAID_LEADER_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		gsub(CHAT_RAID_WARNING_GET, '.*%[(.*)%].*', '%%[%1%%]'),
		'%[(%d%d?)%. ([^%]]+)%]', --Custom Channels
	}

	local num = #chn
	for i = 1, num do
		text = gsub(text, chn[i], rplc[i])
	end
	return text
end

local ModifyMessage = function(self)
	if SUI:IsModuleDisabled('Chatbox') then return end
	local num = self.headIndex
	if num == 0 then num = self.maxElements end
	local tbl = self.elements[num]
	local text = tbl and tbl.message

	if text then
		--Check if the message is from someone leaving the battle
		if text:find('has left the battle') and not battleOver then LeaveCount = LeaveCount + 1 end
		-- See if the alliance or horde has won the battle
		if text:find('The Alliance Wins!') or text:find('The Horde Wins!') then
			--Print the number of leavers
			SUI:Print('Leavers: ' .. LeaveCount)
			--Output to Instance chat if over 15 leavers
			if LeaveCount > 15 and module.DB.autoLeaverOutput then SendChatMessage('SpartanUI: BG Leavers counter: ' .. LeaveCount, 'INSTANCE_CHAT') end
			battleOver = true
		end

		text = tostring(text)
		text = shortenChannel(text)
		text = module:TimeStamp(text)
		text = module:PlayerName(text)

		self.elements[num].message = text
	end
end

-- Tooltip mouseover
local showingTooltip = false
function module:OnHyperlinkEnter(f, link)
	local t = strmatch(link, '^(.-):')
	if linkTypes[t] then
		showingTooltip = true
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, 'ANCHOR_CURSOR')
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end
end

function module:OnHyperlinkLeave(f, link)
	if showingTooltip then
		showingTooltip = false
		HideUIPanel(GameTooltip)
	end
end

-- Module Setup
function module:OnInitialize()
	---@class SUI.Chat.DB
	local defaults = {
		LinkHover = true,
		autoLeaverOutput = true,
		shortenChannelNames = true,
		webLinks = true,
		EditBoxTop = false,
		timestampFormat = '%X',
		playerlevel = nil,
		ChatCopyTip = true,
		fontSize = 12,
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Chatbox', { profile = defaults })
	module.DB = module.Database.profile ---@type SUI.Chat.DB

	if not SUI.CharDB.ChatHistory then SUI.CharDB.ChatHistory = {} end
	if not SUI.CharDB.ChatEditHistory then SUI.CharDB.ChatEditHistory = {} end

	if SUI:IsModuleDisabled(module) then return end
	local ChatAddons = { 'Chatter', 'BasicChatMods', 'Prat-3.0' }
	for _, addonName in pairs(ChatAddons) do
		if SUI:IsAddonEnabled(addonName) then
			SUI:Print('Chat module disabling ' .. addonName .. ' Detected')
			module.Override = true
			return
		end
	end

	ChatLevelLog = SUI.DBG.ChatLevelLog
	-- Create popup
	popup = StdUi:Window(nil, 600, 350)
	popup:MakeResizable('BOTTOMRIGHT')
	popup:SetPoint('CENTER', 0, 0)
	popup:SetFrameStrata('DIALOG')

	popup.Title = StdUi:Texture(popup, 156, 45, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	popup.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	StdUi:GlueTop(popup.Title, popup, 0, 0)
	popup.Title:SetAlpha(0.8)

	-- Create Popup Items
	popup.editBox = StdUi:MultiLineBox(popup, 580, 120, '')

	-- Position
	popup.editBox:SetPoint('TOPLEFT', popup, 'TOPLEFT', 10, -55)
	popup.editBox:SetPoint('BOTTOMRIGHT', popup, 'BOTTOMRIGHT', -10, 10)

	-- Actions
	popup:Hide()

	popup.font = popup:CreateFontString(nil, nil, 'GameFontNormal')
	popup.font:Hide()
	popup:HookScript('OnShow', function()
		popup.editBox.scrollFrame:SetVerticalScroll((popup.editBox.scrollFrame:GetVerticalScrollRange()) or 0)
	end)

	-- Disable Blizz class color
	if GetCVar('chatClassColorOverride') ~= '0' then SetCVar('chatClassColorOverride', '0') end
	-- Disable Blizz time stamping
	if GetCVar('showTimestamps') ~= 'none' then
		SetCVar('showTimestamps', 'none')
		CHAT_TIMESTAMP_FORMAT = nil
	end
	ChatLevelLog = {}
	ChatLevelLog[(UnitName('player'))] = tostring((UnitLevel('player')))
end

function module:OnEnable()
	module:BuildOptions()
	if SUI:IsModuleDisabled(module) then return end

	-- Setup Player level monitor
	module.PLAYER_TARGET_CHANGED = function()
		if UnitIsPlayer('target') and UnitIsFriend('player', 'target') then
			local n, s = UnitName('target')
			local l = UnitLevel('target')
			if n and l and l > 0 then
				if s and s ~= '' then n = n .. '-' .. s end
				ChatLevelLog[n] = tostring(l)
			end
		end
	end
	module:RegisterEvent('PLAYER_TARGET_CHANGED')

	module.UPDATE_MOUSEOVER_UNIT = function()
		if UnitIsPlayer('mouseover') and UnitIsFriend('player', 'mouseover') then
			local n, s = UnitName('mouseover')
			local l = UnitLevel('mouseover')
			if n and l and l > 0 then
				if s and s ~= '' then n = n .. '-' .. s end
				ChatLevelLog[n] = tostring(l)
			end
		end
	end
	module:RegisterEvent('UPDATE_MOUSEOVER_UNIT')

	-- Setup everything
	module:SetupChatboxes()

	--Add a chat command to print the number of leavers
	SUI:AddChatCommand('leavers', function(output)
		--If output is true then tell the instance chat
		if output then SendChatMessage('SpartanUI: BG Leavers counter: ' .. LeaveCount, 'INSTANCE_CHAT') end
		SUI:Print('Leavers: ' .. LeaveCount)
	end, 'Prints the number of leavers in the current battleground, addings anything after leavers will output to instance chat')
	--Detect when we leave the battleground and reset the counter
	module:SecureHook('LeaveBattlefield', function()
		LeaveCount = 0
		battleOver = false
	end)
end

function module:EditBoxPosition()
	for i = 1, 10 do
		local ChatFrameName = ('%s%d'):format('ChatFrame', i)
		local ChatFrame = _G[ChatFrameName]
		local ChatFrameEdit = _G[ChatFrameName .. 'EditBox']

		ChatFrameEdit:ClearAllPoints()

		if module.DB.EditBoxTop then
			local GDM = _G['GeneralDockManager']
			ChatFrameEdit:SetPoint('BOTTOMLEFT', GDM, 'TOPLEFT', 0, 1)
			ChatFrameEdit:SetPoint('BOTTOMRIGHT', GDM, 'TOPRIGHT', 0, 1)
		else
			ChatFrameEdit:SetPoint('TOPLEFT', ChatFrame.Background, 'BOTTOMLEFT', -1, -1)
			ChatFrameEdit:SetPoint('TOPRIGHT', ChatFrame.Background, 'BOTTOMRIGHT', 1, -1)
		end
	end
end

---@param key string
function module:ChatEdit_OnKeyDown(key)
	-- Make sure we are setup and valid
	local history = SUI.CharDB.ChatEditHistory
	if (not history) or #history == 0 then return end

	--Grab the next item in the history
	if key == 'DOWN' then
		self.historyIndex = self.historyIndex - 1

		if self.historyIndex < 1 then
			self.historyIndex = 0
			self:SetText('')
			return
		end
	elseif key == 'UP' then
		self.historyIndex = self.historyIndex + 1

		if self.historyIndex > #history then self.historyIndex = #history end
	else
		return
	end

	--Display the history item
	self:SetText(strtrim(history[#history - (self.historyIndex - 1)]))
end

---@param line string
function module:ChatEdit_AddHistory(_, line)
	line = line and strtrim(line)

	if line and strlen(line) > 0 then
		local cmd = strmatch(line, '^/%w+')
		-- block secure commands from history
		if cmd and IsSecureCmd(cmd) then return end

		for index, text in pairs(SUI.CharDB.ChatEditHistory) do
			if text == line then
				tremove(SUI.CharDB.ChatEditHistory, index)
				break
			end
		end

		tinsert(SUI.CharDB.ChatEditHistory, line)

		if #SUI.CharDB.ChatEditHistory > 50 then tremove(SUI.CharDB.ChatEditHistory, 1) end
	end
end

function module:SetupChatboxes()
	if SUI:IsModuleDisabled(module) then return end
	-- DEFAULT_CHATFRAME_ALPHA = 0.7
	-- DEFAULT_CHATFRAME_COLOR = {r = .05, g = .05, b = .05}
	-- DEFAULT_TAB_SELECTED_COLOR_TABLE = {r = .9, g = .9, b = .9}

	local icon = 'Interface\\Addons\\SpartanUI\\images\\chatbox\\chaticons'

	local chatBG = {
		bgFile = [[Interface\Buttons\WHITE8X8]],
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		tile = true,
		tileSize = 16,
		edgeSize = 2,
	}

	local c = { r = 0.05, g = 0.05, b = 0.05, a = 0.7 }
	local filterFunc = function(_, _, msg, ...)
		if not module.DB.webLinks then return end

		local newMsg, found = gsub(
			msg,
			'[^ "£%^`¬{}%[%]\\|<>]*[^ \'%-=%./,"£%^`¬{}%[%]\\|<>%d][^ \'%-=%./,"£%^`¬{}%[%]\\|<>%d]%.[^ \'%-=%./,"£%^`¬{}%[%]\\|<>%d][^ \'%-=%./,"£%^`¬{}%[%]\\|<>%d][^ "£%^`¬{}%[%]\\|<>]*',
			'|cffffffff|Hbcmurl~%1|h[%1]|h|r'
		)
		if found > 0 then return false, newMsg, ... end
		newMsg, found = gsub(
			msg,
			-- This is our IPv4/v6 pattern at the beggining of a sentence.
			'^%x+[%.:]%x+[%.:]%x+[%.:]%x+[^ "£%^`¬{}%[%]\\|<>]*',
			'|cffffffff|Hbcmurl~%1|h[%1]|h|r'
		)
		if found > 0 then return false, newMsg, ... end
		newMsg, found = gsub(
			msg,
			-- Mid-sentence IPv4/v6 pattern
			' %x+[%.:]%x+[%.:]%x+[%.:]%x+[^ "£%^`¬{}%[%]\\|<>]*',
			'|cffffffff|Hbcmurl~%1|h[%1]|h|r'
		)
		if found > 0 then return false, newMsg, ... end
	end

	--Copying Functions
	local TabClick = function(frame)
		local ChatFrameName = format('%s%d', 'ChatFrame', frame:GetID())
		local ChatFrame = _G[ChatFrameName]
		local ChatFrameEdit = _G[ChatFrameName .. 'EditBox']

		if IsAltKeyDown() then
			local text = ''
			-- Fix special pipe methods e.g. 5 |4hour:hours; Example: copying /played text
			for i = 1, ChatFrame:GetNumMessages() do
				local line = ChatFrame:GetMessageInfo(i)
				popup.font:SetFormattedText(string.format('%s\n', line))
				local cleanLine = popup.font:GetText() or ''
				text = text .. cleanLine
			end
			text = text:gsub('|T[^\\]+\\[^\\]+\\[Uu][Ii]%-[Rr][Aa][Ii][Dd][Tt][Aa][Rr][Gg][Ee][Tt][Ii][Nn][Gg][Ii][Cc][Oo][Nn]_(%d)[^|]+|t', '{rt%1}')

			text = text:gsub('|T13700([1-8])[^|]+|t', '{rt%1}') -- raid icons
			text = text:gsub('|T[^|]+|t', '') -- Remove icons to prevent copying issues
			text = text:gsub('|K[^|]+|k', '<Protected Text>') -- Remove protected text
			module:SetPopupText(text)
		elseif IsShiftKeyDown() then
			if ChatFrame:IsVisible() then
				ChatFrame:Hide()
			else
				ChatFrame:Show()
			end
		end

		if ChatFrameEdit:IsVisible() then ChatFrameEdit:Hide() end
	end
	local TabHintEnter = function(frame)
		if not module.DB.ChatCopyTip then return end

		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(frame, 'ANCHOR_TOP')
		GameTooltip:AddLine('Alt+Click to copy', 0.8, 0, 0)
		GameTooltip:AddLine('Shift+Click to toggle', 0, 0.1, 1)
		GameTooltip:Show()
	end
	local TabHintLeave = function(frame)
		if not module.DB.ChatCopyTip then return end

		HideUIPanel(GameTooltip)
	end

	local GDM = _G['GeneralDockManager']
	if not GDM.SetBackdrop then Mixin(GDM, BackdropTemplateMixin) end

	if GDM.SetBackdrop then
		GDM:SetBackdrop(chatBG)
		GDM:SetBackdropColor(c.r, c.g, c.b, c.a)
		GDM:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
	end
	GDM:ClearAllPoints()
	GDM:SetPoint('BOTTOMLEFT', _G['ChatFrame1Background'], 'TOPLEFT', -1, 1)
	GDM:SetPoint('BOTTOMRIGHT', _G['ChatFrame1Background'], 'TOPRIGHT', 1, 1)

	ChatAlertFrame:ClearAllPoints()
	ChatAlertFrame:SetPoint('BOTTOMLEFT', GDM, 'TOPLEFT', 0, 2)

	local QJTB = _G['QuickJoinToastButton']
	if QJTB then
		QJTB:ClearAllPoints()
		QJTB:SetSize(18, 18)
		StripTextures(QJTB)

		QJTB:ClearAllPoints()
		QJTB:SetPoint('TOPRIGHT', GDM, 'TOPRIGHT', -2, -3)
		QJTB.FriendCount:Hide()
		hooksecurefunc(QJTB, 'UpdateQueueIcon', function(frame)
			if not frame.displayedToast then return end
			frame.FriendsButton:SetTexture(icon)
			frame.QueueButton:SetTexture(icon)
			frame.FlashingLayer:SetTexture(icon)
			frame.FriendsButton:SetShown(false)
			frame.FriendCount:SetShown(false)
		end)
		hooksecurefunc(QJTB, 'SetPoint', function(frame, point, anchor)
			if anchor ~= GDM and point ~= 'TOPRIGHT' then
				frame:ClearAllPoints()
				frame:SetPoint('TOPRIGHT', GDM, 'TOPRIGHT', -2, -3)
			end
		end)

		local function updateTexture()
			QJTB.FriendsButton:SetTexture(icon)
			QJTB.QueueButton:SetTexture(icon)
		end
		QJTB:HookScript('OnMouseDown', updateTexture)
		QJTB:HookScript('OnMouseUp', updateTexture)
		updateTexture()

		QJTB.FriendsButton:SetTexture(icon)
		QJTB.FriendsButton:SetTexCoord(0.08, 0.4, 0.6, 0.9)
		QJTB.FriendsButton:ClearAllPoints()
		QJTB.FriendsButton:SetPoint('CENTER')
		QJTB.FriendsButton:SetSize(18, 18)

		QJTB.QueueButton:SetTexture(icon)
		QJTB.QueueButton:SetTexCoord(0.6, 0.9, 0.08, 0.4)
		QJTB.QueueButton:ClearAllPoints()
		QJTB.QueueButton:SetPoint('CENTER')
		QJTB.QueueButton:SetSize(18, 18)

		QJTB.FlashingLayer:SetTexture(icon)
		QJTB.FlashingLayer:SetTexCoord(0.6, 0.9, 0.08, 0.4)
		QJTB.FlashingLayer:ClearAllPoints()
		QJTB.FlashingLayer:SetPoint('CENTER')
		QJTB.FlashingLayer:SetSize(20, 20)

		QJTB.Toast:ClearAllPoints()
		QJTB.Toast:SetPoint('BOTTOMLEFT', QJTB, 'TOPLEFT')
		QJTB.Toast2:ClearAllPoints()
		QJTB.Toast2:SetPoint('BOTTOMLEFT', QJTB, 'TOPLEFT')
	end

	BNToastFrame:ClearAllPoints()
	BNToastFrame:SetPoint('BOTTOM', GDM, 'TOP')
	local function fixbnetpos(frame, _, anchor)
		if anchor ~= GDM then
			frame:ClearAllPoints()
			BNToastFrame:SetPoint('BOTTOM', GDM, 'TOP')
		end
	end
	hooksecurefunc(BNToastFrame, 'SetPoint', fixbnetpos)

	local VoiceChannelButton = _G['ChatFrameChannelButton']
	VoiceChannelButton:ClearAllPoints()
	VoiceChannelButton:SetParent(GDM)
	VoiceChannelButton:SetPoint('RIGHT', QJTB, 'LEFT', -1, 0)
	StripTextures(VoiceChannelButton)
	VoiceChannelButton:SetSize(18, 18)
	VoiceChannelButton.Icon:SetTexture(icon)
	VoiceChannelButton.Icon:SetTexCoord(0.1484375, 0.359375, 0.1484375, 0.359375)
	VoiceChannelButton.Icon:SetScale(0.8)

	ChatFrameMenuButton:ClearAllPoints()
	ChatFrameMenuButton:SetParent(GDM)
	ChatFrameMenuButton:SetPoint('RIGHT', VoiceChannelButton, 'LEFT', -1, -2)
	ChatFrameMenuButton:SetSize(18, 18)
	StripTextures(ChatFrameMenuButton)
	ChatFrameMenuButton.Icon = ChatFrameMenuButton:CreateTexture(nil, 'ARTWORK')
	ChatFrameMenuButton.Icon:SetAllPoints(ChatFrameMenuButton)
	ChatFrameMenuButton.Icon:SetTexture(icon)
	ChatFrameMenuButton.Icon:SetTexCoord(0.6, 0.9, 0.6, 0.9)

	for i = 1, 10 do
		local ChatFrameName = ('%s%d'):format('ChatFrame', i)

		--Allow arrow keys editing in the edit box
		local ChatFrameEdit = _G[ChatFrameName .. 'EditBox']

		--Setup Chatbox History
		ChatFrameEdit:SetAltArrowKeyMode(false)
		ChatFrameEdit.historyIndex = 0

		ChatFrameEdit:HookScript('OnKeyDown', module.ChatEdit_OnKeyDown)
		module:SecureHook(ChatFrameEdit, 'AddHistoryLine', 'ChatEdit_AddHistory')

		-- Setup chat message modification
		local ChatFrame = _G[ChatFrameName]
		hooksecurefunc(ChatFrame.historyBuffer, 'PushFront', ModifyMessage)
		module:HookScript(ChatFrame, 'OnHyperlinkEnter', OnHyperlinkEnter)
		module:HookScript(ChatFrame, 'OnHyperlinkLeave', OnHyperlinkLeave)

		if ChatFrame.Selection then
			ChatFrame.Selection:ClearAllPoints()
			ChatFrame.Selection:SetPoint('TOPLEFT', ChatFrame, 'TOPLEFT', 0, 30)
			ChatFrame.Selection:SetPoint('BOTTOMRIGHT', ChatFrame, 'BOTTOMRIGHT', 25, -32)
		end

		-- Now we can skin everything
		-- First lets setup some settings
		ChatFrame:SetClampRectInsets(0, 0, 0, 0)
		ChatFrame:SetClampedToScreen(false)

		-- Setup main BG
		local _, _, r, g, b, a = FCF_GetChatWindowInfo(i)
		if r == 0 and g == 0 and b == 0 and ((SUI.IsRetail and a < 0.16 and a > 0.15) or (SUI.IsClassic and a < 0.1)) then
			FCF_SetWindowColor(ChatFrame, DEFAULT_CHATFRAME_COLOR.r, DEFAULT_CHATFRAME_COLOR.g, DEFAULT_CHATFRAME_COLOR.b)
			FCF_SetWindowAlpha(ChatFrame, DEFAULT_CHATFRAME_ALPHA)
		end
		if ChatFrame.SetBackdrop then ChatFrame:SetBackdrop(nil) end

		--Setup Scrollbar
		if ChatFrame.ScrollBar and ChatFrame.ScrollBar.ThumbTexture then
			ChatFrame.ScrollBar.ThumbTexture:SetColorTexture(1, 1, 1, 0.4)
			ChatFrame.ScrollBar.ThumbTexture:SetWidth(10)

			StripTextures(ChatFrame.ScrollToBottomButton)
			local BG = ChatFrame.ScrollToBottomButton:CreateTexture()
			BG = ChatFrame.ScrollToBottomButton:CreateTexture(nil, 'ARTWORK')
			BG:SetAllPoints(ChatFrame.ScrollToBottomButton)
			BG:SetTexture('Interface\\Addons\\SpartanUI\\images\\chatbox\\bottomArrow')
			BG:SetAlpha(0.4)
			ChatFrame.ScrollToBottomButton.BG = BG
			ChatFrame.ScrollToBottomButton:ClearAllPoints()
			ChatFrame.ScrollToBottomButton:SetSize(20, 20)
			ChatFrame.ScrollToBottomButton:SetPoint('BOTTOMRIGHT', ChatFrame.ResizeButton, 'TOPRIGHT', -4, 0)
		end

		--Skin the Tab
		local ChatFrameTab = _G[ChatFrameName .. 'Tab']
		ChatFrameTab:HookScript('OnClick', TabClick)
		ChatFrameTab:HookScript('OnEnter', TabHintEnter)
		ChatFrameTab:HookScript('OnLeave', TabHintLeave)
		ChatFrameTab.Text:ClearAllPoints()
		ChatFrameTab.Text:SetPoint('CENTER', ChatFrameTab)

		if SUI.IsRetail then
			local sides = { 'Left', 'Middle', 'Right' }
			local modes = { 'Active', 'Highlight', '' }

			for _, mode in ipairs(modes) do
				for _, side in ipairs(sides) do
					ChatFrameTab[mode .. side]:SetTexture(nil)
				end
			end
		else
			for _, v in ipairs({ 'left', 'middle', 'right' }) do
				ChatFrameTab[v .. 'HighlightTexture']:SetTexture(nil)
				ChatFrameTab[v .. 'SelectedTexture']:SetTexture(nil)
				ChatFrameTab[v .. 'Texture']:SetTexture(nil)
			end
		end

		-- Setup Editbox
		local EBLeft = _G[ChatFrameName .. 'EditBoxLeft']
		local EBMid = _G[ChatFrameName .. 'EditBoxMid']
		local EBRight = _G[ChatFrameName .. 'EditBoxRight']
		EBLeft:Hide()
		EBRight:Hide()
		EBMid:Hide()

		local header = _G[ChatFrameName .. 'EditBoxHeader']
		local _, s, m = header:GetFont()
		SUI.Font:Format(header, s, 'Chatbox')
		SUI.Font:Format(ChatFrame, module.DB.fontSize, 'Chatbox')
		SUI.Font:Format(ChatFrameEdit, module.DB.fontSize, 'Chatbox')

		if _G[ChatFrameName .. 'EditBoxFocusLeft'] ~= nil then _G[ChatFrameName .. 'EditBoxFocusLeft']:SetTexture(nil) end
		if _G[ChatFrameName .. 'EditBoxFocusRight'] ~= nil then _G[ChatFrameName .. 'EditBoxFocusRight']:SetTexture(nil) end
		if _G[ChatFrameName .. 'EditBoxFocusMid'] ~= nil then _G[ChatFrameName .. 'EditBoxFocusMid']:SetTexture(nil) end

		ChatFrameEdit:Hide()
		ChatFrameEdit:SetHeight(22)

		local function disable(element)
			if element.UnregisterAllEvents then
				element:UnregisterAllEvents()
				element:SetParent(nil)
			end
			element.Show = element.Hide

			element:Hide()
		end

		if not ChatFrameEdit.SetBackdrop then Mixin(ChatFrameEdit, BackdropTemplateMixin) end
		if ChatFrameEdit.SetBackdrop then
			ChatFrameEdit:SetBackdrop(chatBG)
			local bg = { ChatFrame.Background:GetVertexColor() }
			ChatFrameEdit:SetBackdropColor(unpack(bg))
			ChatFrameEdit:SetBackdropBorderColor(unpack(bg))
		end

		local function BackdropColorUpdate(frame, r, g, b)
			local bg = { ChatFrame.Background:GetVertexColor() }
			if ChatFrameEdit.SetBackdrop then
				ChatFrameEdit:SetBackdropColor(unpack(bg))
				ChatFrameEdit:SetBackdropBorderColor(unpack(bg))
			end
		end
		hooksecurefunc(ChatFrame.Background, 'SetVertexColor', BackdropColorUpdate)

		if SUI.IsRetail then
			local EBFocusLeft = _G[ChatFrameName .. 'EditBoxFocusLeft']
			local EBFocusMid = _G[ChatFrameName .. 'EditBoxFocusMid']
			local EBFocusRight = _G[ChatFrameName .. 'EditBoxFocusRight']
			EBFocusLeft:SetVertexColor(c.r, c.g, c.b, c.a)
			EBFocusMid:SetVertexColor(c.r, c.g, c.b, c.a)
			EBFocusRight:SetVertexColor(c.r, c.g, c.b, c.a)

			-- Ensure the edit box hides all textures
			local EditBoxFocusHide = function(frame)
				ChatFrameEdit:Hide()
			end
			hooksecurefunc(EBFocusMid, 'Hide', EditBoxFocusHide)

			disable(_G[ChatFrameName .. 'ButtonFrame'])
		end
	end

	module:EditBoxPosition()

	ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_YELL', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_GUILD', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_OFFICER', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_PARTY', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_PARTY_LEADER', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_RAID', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_RAID_LEADER', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_INSTANCE_CHAT', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_INSTANCE_CHAT_LEADER', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_SAY', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_WHISPER', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_WHISPER_INFORM', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_BN_WHISPER', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_BN_WHISPER_INFORM', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_BN_CONVERSATION', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_BN_INLINE_TOAST_BROADCAST', filterFunc)
	ChatFrame_AddMessageEventFilter('CHAT_MSG_COMMUNITIES_CHANNEL', filterFunc)
end

local SetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(data, ...)
	local isURL, link = strsplit('~', data)
	if isURL and isURL == 'bcmurl' then
		module:SetPopupText(link)
	else
		SetHyperlink(self, data, ...)
	end
end

function module:BuildOptions()
	--@type AceConfig.OptionsTable
	local optTable = {
		type = 'group',
		name = L['Chatbox'],
		childGroups = 'tab',
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
			module:EditBoxPosition()
		end,
		args = {
			timestampFormat = {
				name = L['Timestamp format'],
				type = 'select',
				order = 2,
				values = {
					[''] = 'Disabled',
					['%I:%M:%S %p'] = 'HH:MM:SS AM (12-hour)',
					['%I:%M:S'] = 'HH:MM (12-hour)',
					['%X'] = 'HH:MM:SS (24-hour)',
					['%I:%M'] = 'HH:MM (12-hour)',
					['%H:%M'] = 'HH:MM (24-hour)',
					['%M:%S'] = 'MM:SS',
				},
			},
			autoLeaverOutput = {
				name = L['Automatically output number of BG leavers to instance chat if over 15'],
				type = 'toggle',
			},
			shortenChannelNames = {
				name = L['Shorten channel names'],
				type = 'toggle',
			},
			EditBoxTop = {
				name = L['Edit box on top'],
				type = 'toggle',
			},
			playerlevel = {
				name = L['Display level'],
				type = 'toggle',
				order = 1,
			},
			webLinks = {
				name = L['Clickable web link'],
				type = 'toggle',
				order = 20,
			},
			LinkHover = {
				name = L['Hoveable game links'],
				type = 'toggle',
				order = 21,
			},
		},
	}
	SUI.Options:AddOptions(optTable, 'Chatbox')
end

function module:SetEditBoxMessage(msg)
	if not ChatFrame1EditBox:IsShown() then ChatEdit_ActivateChat(ChatFrame1EditBox) end

	local editBoxText = ChatFrame1EditBox:GetText()
	if editBoxText and editBoxText ~= '' then ChatFrame1EditBox:SetText('') end
	ChatFrame1EditBox:Insert(msg)
	ChatFrame1EditBox:HighlightText()
end

SUI.Chat = module
