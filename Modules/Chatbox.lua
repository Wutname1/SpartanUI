local SUI, L, print = SUI, SUI.L, SUI.print
local StdUi = SUI.StdUi
local module = SUI:NewModule('Component_Chatbox', 'AceEvent-3.0', 'AceHook-3.0')
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
	quest = true
}
local ChatLevelLog = {}

local function StripTextures(object)
	for i = 1, object:GetNumRegions() do
		local region = select(i, object:GetRegions())
		if region and region:GetObjectType() == 'Texture' then
			region:SetTexture(nil)
		end
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
	if type(c.r) == 'number' and type(c.g) == 'number' and type(c.b) == 'number' and type(c.a) == 'number' then
		return c.r, c.g, c.b, c.a
	end
	if type(c.r) == 'number' and type(c.g) == 'number' and type(c.b) == 'number' then
		return c.r, c.g, c.b, .8
	end
	return 1.0, 1.0, 1.0, .8
end

local function get_var_color(a1, a2, a3, a4)
	local r, g, b, a

	if type(a1) == 'table' then
		r, g, b, a = get_color(a1)
	elseif type(a1) == 'number' and type(a2) == 'number' and type(a3) == 'number' and type(a4) == 'number' then
		r, g, b, a = a1, a2, a3, a4
	elseif type(a1) == 'number' and type(a2) == 'number' and type(a3) == 'number' and type(a4) == 'nil' then
		r, g, b, a = a1, a2, a3, .8
	else
		r, g, b, a = 1.0, 1.0, 1.0, .8
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
	if ((nameColor and not hasColor and not nameColor[name]) or (ChatLevelLog and not ChatLevelLog[name])) then
		for i = 1, GetNumGuildMembers() do
			local n, _, _, l, _, _, _, _, _, _, c = GetGuildRosterInfo(i)
			if n then
				n = Ambiguate(n, 'none')
				if n == name then
					if ChatLevelLog and l and l > 0 then
						ChatLevelLog[n] = tostring(l)
					end
					if nameColor and c and not hasColor then
						nameColor[n] = module:GetColor(c)
					end
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
					if ChatLevelLog then
						ChatLevelLog[n] = tostring(l)
					end
					if nameColor and c then
						nameColor[n] = module:GetColor(c)
					end
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

		nameToChange = '|cff' .. color .. (ChatLevelLog[name]) .. '|r:' .. nameToChange
	end
	if nameGroup and nameGroup[name] and IsInRaid() then
		nameToChange = nameToChange .. ':' .. nameGroup[name]
	end
	return '|Hplayer:' .. fullName .. misc .. '[' .. nameToChange .. ']' .. (colon == ':' and ' ' or colon) .. '|h'
end

function module:PlayerName(text)
	text = text:gsub('|Hplayer:([^:|]+)([^%[]+)%[([^%]]+)%]|h(:?)', changeName)
	return text
end

function module:TimeStamp(text)
	if module.DB.timestampFormat == '' then
		return text
	end
	text = date('|cff7d7d7d[' .. module.DB.timestampFormat .. ']|r ') .. text
	return text
end

local function shortenChannel(text)
	if not module.DB.shortenChannelNames then
		return text
	end

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
		'[%1]' --Custom Channels
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
		'%[(%d%d?)%. ([^%]]+)%]' --Custom Channels
	}

	local num = #chn
	for i = 1, num do
		text = gsub(text, chn[i], rplc[i])
	end
	return text
end

local ModifyMessage = function(self)
	if SUI.DB.DisabledComponents.Chatbox then
		return
	end
	local num = self.headIndex
	if num == 0 then
		num = self.maxElements
	end
	local tbl = self.elements[num]
	local text = tbl and tbl.message

	if text then
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
	local defaults = {
		profile = {
			LinkHover = true,
			shortenChannelNames = true,
			webLinks = true,
			EditBoxTop = false,
			timestampFormat = '%X',
			playerlevel,
			ChatCopyTip = true,
			fontSize = 12
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Chatbox', defaults)
	module.DB = module.Database.profile

	if SUI:IsModuleDisabled('Chatbox') then
		return
	end
	local ChatAddons = {'Chatter', 'BasicChatMods', 'Prat-3.0'}
	for _, addonName in pairs(ChatAddons) do
		local enabled = select(4, GetAddOnInfo(addonName))
		if enabled then
			SUI:Print('Chat module disabling ' .. addonName .. ' Detected')
			SUI:DisableModule('Chatbox')
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
	popup.Title:SetPoint('TOP')
	popup.Title:SetAlpha(.8)

	-- Create Popup Items
	popup.editBox = StdUi:MultiLineBox(popup, 580, 120, '')
	popup.editBox.editBox:SetFont(SUI:GetFontFace('chatbox'), 12)

	-- Position
	popup.editBox:SetPoint('TOPLEFT', popup, 'TOPLEFT', 10, -55)
	popup.editBox:SetPoint('BOTTOMRIGHT', popup, 'BOTTOMRIGHT', -10, 10)

	-- Actions
	popup:Hide()

	popup.font = popup:CreateFontString(nil, nil, 'GameFontNormal')
	popup.font:Hide()
	popup:HookScript(
		'OnShow',
		function()
			popup.editBox.scrollFrame:SetVerticalScroll((popup.editBox.scrollFrame:GetVerticalScrollRange()) or 0)
		end
	)

	-- Disable Blizz class color
	if GetCVar('chatClassColorOverride') ~= '0' then
		SetCVar('chatClassColorOverride', '0')
	end
	-- Disable Blizz time stamping
	if GetCVar('showTimestamps') ~= 'none' then
		SetCVar('showTimestamps', 'none')
		CHAT_TIMESTAMP_FORMAT = nil
	end
	ChatLevelLog = {}
	ChatLevelLog[(UnitName('player'))] = tostring((UnitLevel('player')))
end

function module:OnEnable()
	if SUI:IsModuleDisabled('Chatbox') then
		return
	end

	-- Setup Player level monitor
	module.PLAYER_TARGET_CHANGED = function()
		if UnitIsPlayer('target') and UnitIsFriend('player', 'target') then
			local n, s = UnitName('target')
			local l = UnitLevel('target')
			if n and l and l > 0 then
				if s and s ~= '' then
					n = n .. '-' .. s
				end
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
				if s and s ~= '' then
					n = n .. '-' .. s
				end
				ChatLevelLog[n] = tostring(l)
			end
		end
	end
	module:RegisterEvent('UPDATE_MOUSEOVER_UNIT')

	-- Setup everything
	module:SetupChatboxes()
	module:BuildOptions()
end

function module:EditBoxPosition()
	for i = 1, 10 do
		local ChatFrameName = ('%s%d'):format('ChatFrame', i)
		local ChatFrame = _G[ChatFrameName]
		local ChatFrameEdit = _G[ChatFrameName .. 'EditBox']

		ChatFrameEdit:ClearAllPoints()

		if module.DB.EditBoxTop then
			local GDM = _G.GeneralDockManager
			ChatFrameEdit:SetPoint('BOTTOMLEFT', GDM, 'TOPLEFT', 0, 1)
			ChatFrameEdit:SetPoint('BOTTOMRIGHT', GDM, 'TOPRIGHT', 0, 1)
		else
			ChatFrameEdit:SetPoint('TOPLEFT', ChatFrame.Background, 'BOTTOMLEFT', -1, -1)
			ChatFrameEdit:SetPoint('TOPRIGHT', ChatFrame.Background, 'BOTTOMRIGHT', 1, -1)
		end
	end
end

function module:SetupChatboxes()
	if SUI:IsModuleDisabled('Chatbox') then
		return
	end
	DEFAULT_CHATFRAME_ALPHA = 0.7
	DEFAULT_CHATFRAME_COLOR = {r = .05, g = .05, b = .05}
	DEFAULT_TAB_SELECTED_COLOR_TABLE = {r = .9, g = .9, b = .9}
	local icon = 'Interface\\Addons\\SpartanUI\\images\\chaticons'

	local chatBG = {
		bgFile = [[Interface\Buttons\WHITE8X8]],
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		tile = true,
		tileSize = 16,
		edgeSize = 2
	}

	local c = {r = .05, g = .05, b = .05, a = 0.7}
	local filterFunc = function(_, _, msg, ...)
		if not module.DB.webLinks then
			return
		end

		local newMsg, found =
			gsub(
			msg,
			"[^ \"£%^`¬{}%[%]\\|<>]*[^ '%-=%./,\"£%^`¬{}%[%]\\|<>%d][^ '%-=%./,\"£%^`¬{}%[%]\\|<>%d]%.[^ '%-=%./,\"£%^`¬{}%[%]\\|<>%d][^ '%-=%./,\"£%^`¬{}%[%]\\|<>%d][^ \"£%^`¬{}%[%]\\|<>]*",
			'|cffffffff|Hbcmurl~%1|h[%1]|h|r'
		)
		if found > 0 then
			return false, newMsg, ...
		end
		newMsg, found =
			gsub(
			msg,
			-- This is our IPv4/v6 pattern at the beggining of a sentence.
			'^%x+[%.:]%x+[%.:]%x+[%.:]%x+[^ "£%^`¬{}%[%]\\|<>]*',
			'|cffffffff|Hbcmurl~%1|h[%1]|h|r'
		)
		if found > 0 then
			return false, newMsg, ...
		end
		newMsg, found =
			gsub(
			msg,
			-- Mid-sentence IPv4/v6 pattern
			' %x+[%.:]%x+[%.:]%x+[%.:]%x+[^ "£%^`¬{}%[%]\\|<>]*',
			'|cffffffff|Hbcmurl~%1|h[%1]|h|r'
		)
		if found > 0 then
			return false, newMsg, ...
		end
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
				popup.font:SetFormattedText('%s\n', line)
				local cleanLine = popup.font:GetText() or ''
				text = text .. cleanLine
			end
			text =
				text:gsub(
				'|T[^\\]+\\[^\\]+\\[Uu][Ii]%-[Rr][Aa][Ii][Dd][Tt][Aa][Rr][Gg][Ee][Tt][Ii][Nn][Gg][Ii][Cc][Oo][Nn]_(%d)[^|]+|t',
				'{rt%1}'
			)

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

		if ChatFrameEdit:IsVisible() then
			ChatFrameEdit:Hide()
		end
	end
	local TabHintEnter = function(frame)
		if not module.DB.ChatCopyTip then
			return
		end

		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(frame, 'ANCHOR_TOP')
		GameTooltip:AddLine('Alt+Click to copy', .8, 0, 0)
		GameTooltip:AddLine('Shift+Click to toggle', 0, 0.1, 1)
		GameTooltip:Show()
	end
	local TabHintLeave = function(frame)
		if not module.DB.ChatCopyTip then
			return
		end

		HideUIPanel(GameTooltip)
	end

	local GDM = _G.GeneralDockManager
	if not GDM.SetBackdrop then
		Mixin(GDM, BackdropTemplateMixin)
	end

	if (GDM.SetBackdrop) then
		GDM:SetBackdrop(chatBG)
		GDM:SetBackdropColor(c.r, c.g, c.b, c.a)
		GDM:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
	end
	GDM:ClearAllPoints()
	GDM:SetPoint('BOTTOMLEFT', _G.ChatFrame1Background, 'TOPLEFT', -1, 1)
	GDM:SetPoint('BOTTOMRIGHT', _G.ChatFrame1Background, 'TOPRIGHT', 1, 1)

	ChatAlertFrame:ClearAllPoints()
	ChatAlertFrame:SetPoint('BOTTOMLEFT', GDM, 'TOPLEFT', 0, 2)

	local QJTB = _G.QuickJoinToastButton
	if QJTB then
		QJTB:ClearAllPoints()
		QJTB:SetSize(18, 18)
		StripTextures(QJTB)

		QJTB:ClearAllPoints()
		QJTB:SetPoint('TOPRIGHT', GDM, 'TOPRIGHT', -2, -3)
		QJTB.FriendCount:Hide()
		hooksecurefunc(
			QJTB,
			'UpdateQueueIcon',
			function(frame)
				if not frame.displayedToast then
					return
				end
				frame.FriendsButton:SetTexture(icon)
				frame.QueueButton:SetTexture(icon)
				frame.FlashingLayer:SetTexture(icon)
				frame.FriendsButton:SetShown(false)
				frame.FriendCount:SetShown(false)
			end
		)
		hooksecurefunc(
			QJTB,
			'SetPoint',
			function(frame, point, anchor)
				if anchor ~= GDM and point ~= 'TOPRIGHT' then
					frame:ClearAllPoints()
					frame:SetPoint('TOPRIGHT', GDM, 'TOPRIGHT', -2, -3)
				end
			end
		)

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

	local VoiceChannelButton = _G.ChatFrameChannelButton
	VoiceChannelButton:ClearAllPoints()
	if SUI.IsRetail then
		VoiceChannelButton:SetPoint('TOPRIGHT', QJTB, 'TOPLEFT', -1, 0)
	else
		VoiceChannelButton:SetPoint('TOPRIGHT', GDM, 'TOPRIGHT', -2, -3)
	end

	StripTextures(VoiceChannelButton)
	VoiceChannelButton:SetSize(18, 18)
	VoiceChannelButton.Icon:SetTexture(icon)
	VoiceChannelButton.Icon:SetTexCoord(0.1484375, 0.359375, 0.1484375, 0.359375)
	VoiceChannelButton.Icon:SetScale(.8)

	ChatFrameMenuButton:ClearAllPoints()
	ChatFrameMenuButton:SetPoint('TOPRIGHT', VoiceChannelButton, 'TOPLEFT', -1, 0)
	ChatFrameMenuButton:SetSize(18, 18)
	StripTextures(ChatFrameMenuButton)
	ChatFrameMenuButton.Icon = ChatFrameMenuButton:CreateTexture(nil, 'ARTWORK')
	ChatFrameMenuButton.Icon:SetAllPoints(ChatFrameMenuButton)
	ChatFrameMenuButton.Icon:SetTexture(icon)
	ChatFrameMenuButton.Icon:SetTexCoord(.6, .9, .6, .9)

	for i = 1, 10 do
		local ChatFrameName = ('%s%d'):format('ChatFrame', i)

		--Allow arrow keys editing in the edit box
		local ChatFrameEdit = _G[ChatFrameName .. 'EditBox']
		ChatFrameEdit:SetAltArrowKeyMode(false)

		-- Setup chat message modification
		local ChatFrame = _G[ChatFrameName]
		hooksecurefunc(ChatFrame.historyBuffer, 'PushFront', ModifyMessage)
		module:HookScript(ChatFrame, 'OnHyperlinkEnter', OnHyperlinkEnter)
		module:HookScript(ChatFrame, 'OnHyperlinkLeave', OnHyperlinkLeave)

		-- Now we can skin everything
		-- First lets setup some settings
		ChatFrame:SetClampRectInsets(0, 0, 0, 0)
		ChatFrame:SetClampedToScreen(false)

		-- Setup main BG
		local _, _, r, g, b, a = FCF_GetChatWindowInfo(i)
		if r == 0 and g == 0 and b == 0 and ((SUI.IsRetail and a < .16 and a > .15) or (SUI.IsClassic and a < .1)) then
			FCF_SetWindowColor(ChatFrame, DEFAULT_CHATFRAME_COLOR.r, DEFAULT_CHATFRAME_COLOR.g, DEFAULT_CHATFRAME_COLOR.b)
			FCF_SetWindowAlpha(ChatFrame, DEFAULT_CHATFRAME_ALPHA)
		end
		if (ChatFrame.SetBackdrop) then
			ChatFrame:SetBackdrop(nil)
		end

		--Setup Scrollbar
		if ChatFrame.ScrollBar then
			ChatFrame.ScrollBar.ThumbTexture:SetColorTexture(1, 1, 1, .4)
			ChatFrame.ScrollBar.ThumbTexture:SetWidth(10)

			StripTextures(ChatFrame.ScrollToBottomButton)
			local BG = ChatFrame.ScrollToBottomButton:CreateTexture()
			BG = ChatFrame.ScrollToBottomButton:CreateTexture(nil, 'ARTWORK')
			BG:SetAllPoints(ChatFrame.ScrollToBottomButton)
			BG:SetTexture('Interface\\Addons\\SpartanUI\\images\\ToBottomArrow')
			BG:SetAlpha(.4)
			ChatFrame.ScrollToBottomButton.BG = BG
			ChatFrame.ScrollToBottomButton:ClearAllPoints()
			ChatFrame.ScrollToBottomButton:SetSize(20, 20)
			ChatFrame.ScrollToBottomButton:SetPoint('BOTTOMRIGHT', ChatFrame.ResizeButton, 'TOPRIGHT', -4, 0)
		end

		if SUI.IsClassic then
			--Position the bottom button in classic to the same spot as retail
			local bottombutton = _G[ChatFrameName .. 'ButtonFrameButtomButton']
			if bottombutton then
				bottombutton:ClearAllPoints()
				bottombutton:SetParent(ChatFrame.Background)
				bottombutton:SetPoint('BOTTOMLEFT', ChatFrame.Background, 'BOTTOMLEFT', 0, 0)
				bottombutton:Show()
			end
		end

		--Skin the Tab
		local ChatFrameTab = _G[ChatFrameName .. 'Tab']
		ChatFrameTab:HookScript('OnClick', TabClick)
		ChatFrameTab:HookScript('OnEnter', TabHintEnter)
		ChatFrameTab:HookScript('OnLeave', TabHintLeave)
		ChatFrameTab.Text:ClearAllPoints()
		ChatFrameTab.Text:SetPoint('CENTER', ChatFrameTab)

		for _, v in ipairs({'left', 'middle', 'right'}) do
			ChatFrameTab[v .. 'HighlightTexture']:SetTexture(nil)
			ChatFrameTab[v .. 'SelectedTexture']:SetTexture(nil)
			ChatFrameTab[v .. 'Texture']:SetTexture(nil)
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
		SUI:FormatFont(header, s, 'Chatbox')
		SUI:FormatFont(ChatFrame, module.DB.fontSize, 'Chatbox')
		SUI:FormatFont(ChatFrameEdit, module.DB.fontSize, 'Chatbox')

		if (_G[ChatFrameName .. 'EditBoxFocusLeft'] ~= nil) then
			_G[ChatFrameName .. 'EditBoxFocusLeft']:SetTexture(nil)
		end
		if (_G[ChatFrameName .. 'EditBoxFocusRight'] ~= nil) then
			_G[ChatFrameName .. 'EditBoxFocusRight']:SetTexture(nil)
		end
		if (_G[ChatFrameName .. 'EditBoxFocusMid'] ~= nil) then
			_G[ChatFrameName .. 'EditBoxFocusMid']:SetTexture(nil)
		end

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

		if not ChatFrameEdit.SetBackdrop then
			Mixin(ChatFrameEdit, BackdropTemplateMixin)
		end
		if (ChatFrameEdit.SetBackdrop) then
			ChatFrameEdit:SetBackdrop(chatBG)
			local bg = {ChatFrame.Background:GetVertexColor()}
			ChatFrameEdit:SetBackdropColor(unpack(bg))
			ChatFrameEdit:SetBackdropBorderColor(unpack(bg))
		end

		local function BackdropColorUpdate(frame, r, g, b)
			local bg = {ChatFrame.Background:GetVertexColor()}
			if (ChatFrameEdit.SetBackdrop) then
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
	SUI.opt.args['ModSetting'].args['Chatbox'] = {
		type = 'group',
		name = L['Chatbox'],
		childGroups = 'tab',
		disabled = SUI:IsModuleDisabled('Chatbox'),
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
					['%M:%S'] = 'MM:SS'
				}
			},
			shortenChannelNames = {
				name = L['Shorten channel names'],
				type = 'toggle'
			},
			EditBoxTop = {
				name = L['Edit box on top'],
				type = 'toggle'
			},
			playerlevel = {
				name = L['Display level'],
				type = 'toggle',
				order = 1
			},
			webLinks = {
				name = L['Clickable web link'],
				type = 'toggle',
				order = 20
			},
			LinkHover = {
				name = L['Hoveable game links'],
				type = 'toggle',
				order = 21
			}
		}
	}
end
