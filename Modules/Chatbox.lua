local SUI = SUI
local StdUi = LibStub('StdUi'):NewInstance()
local module = SUI:NewModule('Component_Chatbox', 'AceEvent-3.0', 'AceHook-3.0')
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
local ChatLevelLog

local function StripTextures(object)
	for i = 1, object:GetNumRegions() do
		local region = select(i, object:GetRegions())
		if region and region:GetObjectType() == 'Texture' then
			if region:GetTexture() == 'Interface\\DialogFrame\\UI-DialogBox-Header' then
				-- region:SetTexture(nil)
				region:SetScale(.2)
			end
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
	if ChatLevelLog and ChatLevelLog[name] then
		nameToChange = (ChatLevelLog[name]) .. ':' .. nameToChange
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
	SELECTED_FORMAT = '[' .. SUI.DBMod.Chatbox.TimeStamp.format .. ']'
	text = date(SELECTED_FORMAT) .. text
	return text
end

local ModifyMessage = function(self)
	if not SUI.DB.EnabledComponents.Chatbox then
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
	if not SUI.DB.EnabledComponents.Chatbox then
		return
	end
	local ChatAddons = {'Chatter', 'BasicChatMods', 'Prat-3.0'}
	for _, addonName in pairs(ChatAddons) do
		local enabled = select(4, GetAddOnInfo(addonName))
		if enabled then
			SUI.DB.EnabledComponents.Chatbox = false
			SUI:Print('Chat module disabled ' .. addonName .. ' Detected')
			return
		end
	end

	ChatLevelLog = SUI.DBG.ChatLevelLog
	-- Create popup
	popup = StdUi:Window(nil, 480, 200)
	popup:SetPoint('CENTER', 0, 0)
	popup:SetFrameStrata('DIALOG')

	popup.Title = StdUi:Texture(popup, 156, 45, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	popup.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	popup.Title:SetPoint('TOP')
	popup.Title:SetAlpha(.8)

	-- Create Popup Items
	popup.editBox = StdUi:MultiLineBox(popup, 450, 120, '')
	popup.btnClose = StdUi:Button(popup, 150, 20, 'CLOSE')

	-- Position
	StdUi:GlueTop(popup.editBox.panel, popup, 0, -50)
	popup.btnClose:SetPoint('BOTTOM', popup, 'BOTTOM', 0, 4)

	-- Actions
	popup.btnClose:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Next action
			popup:Hide()
		end
	)
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
	-- module.popup = popup
end

function module:OnEnable()
	if not SUI.DB.EnabledComponents.Chatbox then
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

function module:SetupChatboxes()
	local filterFunc = function(_, _, msg, ...)
		if not SUI.DBMod.Chatbox.webLinks then
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
				if ChatFrameEdit:IsVisible() then
					ChatFrameEdit:Hide()
				end
			else
				ChatFrame:Show()
			end
		end
	end
	local TabHintEnter = function(frame)
		if not SUI.DBMod.Chatbox.ChatCopy.tip then
			return
		end

		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(frame, 'ANCHOR_TOP')
		GameTooltip:AddLine('Alt+Click to copy', .8, 0, 0)
		GameTooltip:AddLine('Shift+Click to toggle', 0, 0.1, 1)
		GameTooltip:Show()
	end
	local TabHintLeave = function(frame)
		if not SUI.DBMod.Chatbox.ChatCopy.tip then
			return
		end

		HideUIPanel(GameTooltip)
	end

	for i = 1, 10 do
		local ChatFrameName = ('%s%d'):format('ChatFrame', i)

		--Allow arrow keys editing in the edit box
		local ChatFrameEdit = _G[ChatFrameName .. 'EditBox']
		ChatFrameEdit:SetAltArrowKeyMode(false)

		if i ~= 2 then --skip combatlog
			local ChatFrame = _G[ChatFrameName]
			local ChatFrameTab = _G[ChatFrameName .. 'Tab']
			hooksecurefunc(ChatFrame.historyBuffer, 'PushFront', ModifyMessage)

			ChatFrameTab:HookScript('OnClick', TabClick)
			ChatFrameTab:HookScript('OnEnter', TabHintEnter)
			ChatFrameTab:HookScript('OnLeave', TabHintLeave)

			module:HookScript(ChatFrame, 'OnHyperlinkEnter', OnHyperlinkEnter)
			module:HookScript(ChatFrame, 'OnHyperlinkLeave', OnHyperlinkLeave)

			ChatFrame:SetClampRectInsets(0, 0, 0, 0)
			ChatFrame:SetClampedToScreen(false)
			StripTextures(ChatFrame)

			-- Setup Editbox BG
			local EBLeft = _G[ChatFrameName .. 'EditBoxLeft']
			local EBMid = _G[ChatFrameName .. 'EditBoxMid']
			local EBRight = _G[ChatFrameName .. 'EditBoxRight']

			-- ChatFrame:SetTexture('Interface\\AddOns\\SpartanUI\\images\\texture')
			EBLeft:SetTexture('Interface\\AddOns\\SpartanUI\\images\\texture')
			EBMid:SetTexture('Interface\\AddOns\\SpartanUI\\images\\texture')
			EBRight:SetTexture('Interface\\AddOns\\SpartanUI\\images\\texture')

			-- ChatFrame:SetVertexColor(0, 0, 0, .5)
			EBLeft:SetVertexColor(0, 0, 0, .5)
			EBMid:SetVertexColor(0, 0, 0, .5)
			EBRight:SetVertexColor(0, 0, 0, .5)

		-- local EBFocusLeft = _G[ChatFrameName .. 'EditBoxFocusLeft']
		-- local EBFocusMid = _G[ChatFrameName .. 'EditBoxFocusMid']
		-- local EBFocusRight = _G[ChatFrameName .. 'EditBoxFocusRight']

		-- local EditBoxFocusShow = function(frame)
		-- 	EBLeft:Show()
		-- 	EBMid:Show()
		-- 	EBRight:Show()
		-- end
		-- local EditBoxFocusHide = function(frame)
		-- 	EBLeft:Hide()
		-- 	EBMid:Hide()
		-- 	EBRight:Hide()
		-- end

		-- EBLeft:Hide()
		-- EBMid:Hide()
		-- EBRight:Hide()

		-- hooksecurefunc(EBFocusLeft, 'Show', EditBoxFocusShow)
		-- hooksecurefunc(EBFocusMid, 'Show', EditBoxFocusShow)
		-- hooksecurefunc(EBFocusRight, 'Show', EditBoxFocusShow)

		-- hooksecurefunc(EBFocusLeft, 'Hide', EditBoxFocusHide)
		-- hooksecurefunc(EBFocusMid, 'Hide', EditBoxFocusHide)
		-- hooksecurefunc(EBFocusRight, 'Hide', EditBoxFocusHide)

		-- hooksecurefunc(EBLeft, 'Hide', EditBoxShow)
		-- hooksecurefunc(EBMid, 'Hide', EditBoxShow)
		-- hooksecurefunc(EBRight, 'Hide', EditBoxShow)
		end
	end

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
		name = 'Chatbox',
		childGroups = 'tab',
		args = {
			enabled = {
				name = 'Enabled',
				type = 'toggle',
				width = 'full',
				order = 1,
				get = function(info)
					return SUI.DB.EnabledComponents.Chatbox
				end,
				set = function(info, val)
					SUI.DB.EnabledComponents.Chatbox = val
				end
			},
			timestamp = {
				name = 'Timestamp format',
				type = 'select',
				order = 2,
				values = {
					['%I:%M:%S %p'] = 'HH:MM:SS AM (12-hour)',
					['%I:%M:S'] = 'HH:MM (12-hour)',
					['%X'] = 'HH:MM:SS (24-hour)',
					['%I:%M'] = 'HH:MM (12-hour)',
					['%H:%M'] = 'HH:MM (24-hour)',
					['%M:%S'] = 'MM:SS'
				},
				get = function(info)
					return SUI.DBMod.Chatbox.TimeStamp.format
				end,
				set = function(info, val)
					SUI.DBMod.Chatbox.TimeStamp.format = val
				end
			},
			player = {
				name = 'Player name',
				type = 'group',
				inline = true,
				order = 100,
				width = 'full',
				args = {
					level = {
						name = 'Display level',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DBMod.Chatbox.player.level
						end,
						set = function(info, val)
							SUI.DBMod.Chatbox.player.level = val
						end
					},
					color = {
						name = 'Color by class',
						type = 'toggle',
						order = 2,
						get = function(info)
							return SUI.DBMod.Chatbox.player.color
						end,
						set = function(info, val)
							SUI.DBMod.Chatbox.player.color = val
						end
					}
				}
			},
			links = {
				name = 'Links',
				type = 'group',
				inline = true,
				order = 200,
				width = 'full',
				args = {
					links = {
						name = 'Clickable web link',
						type = 'toggle',
						order = 20,
						get = function(info)
							return SUI.DBMod.Chatbox.webLinks
						end,
						set = function(info, val)
							SUI.DBMod.Chatbox.webLinks = val
						end
					},
					gamelink = {
						name = 'Hoveable game links',
						type = 'toggle',
						order = 21,
						get = function(info)
							return SUI.DBMod.Chatbox.LinkHover
						end,
						set = function(info, val)
							SUI.DBMod.Chatbox.LinkHover = val
						end
					}
				}
			}
		}
	}
end

function module:HideOptions()
	SUI.opt.args['ModSetting'].args['Chatbox'].disabled = true
end
