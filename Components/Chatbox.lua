local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_Chatbox");
----------------------------------------------------------------------------------------------------
local popup = CreateFrame("Frame", nil, UIParent)

function module:SetPopupText(text)
	popup.editBox:SetText(text)
	popup.editBox:HighlightText(0)
	popup.editBox:GetParent():Show()
end

function module:OnInitialize()
	if DBMod.Chatbox == nil then
		DBMod.Chatbox = {
			showThreat = true,
			healthMode = "detailed"
		}
	end
end

function module:OnEnable()
	--module:SetupLinks()
	module:BuildOptions()
	module:HideOptions()
	
end

function module:SetupLinks()
	local filterFunc = function(_, _, msg, ...)
		local newMsg, found = gsub(msg,
			"[^ \"£%^`¬{}%[%]\\|<>]*[^ '%-=%./,\"£%^`¬{}%[%]\\|<>%d][^ '%-=%./,\"£%^`¬{}%[%]\\|<>%d]%.[^ '%-=%./,\"£%^`¬{}%[%]\\|<>%d][^ '%-=%./,\"£%^`¬{}%[%]\\|<>%d][^ \"£%^`¬{}%[%]\\|<>]*",
			"|cffffffff|Hbcmurl~%1|h[%1]|h|r"
		)
		if found > 0 then return false, newMsg, ... end
		newMsg, found = gsub(msg,
			-- This is our IPv4/v6 pattern at the beggining of a sentence.
			"^%x+[%.:]%x+[%.:]%x+[%.:]%x+[^ \"£%^`¬{}%[%]\\|<>]*",
			"|cffffffff|Hbcmurl~%1|h[%1]|h|r"
		)
		if found > 0 then return false, newMsg, ... end
		newMsg, found = gsub(msg,
			-- Mid-sentence IPv4/v6 pattern
			" %x+[%.:]%x+[%.:]%x+[%.:]%x+[^ \"£%^`¬{}%[%]\\|<>]*",
			"|cffffffff|Hbcmurl~%1|h[%1]|h|r"
		)
		if found > 0 then return false, newMsg, ... end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", filterFunc)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_BROADCAST", filterFunc)
	
	
	-- popup:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		-- edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		-- tile = true, tileSize = 16, edgeSize = 16,
		-- insets = {left = 1, right = 1, top = 1, bottom = 1}}
	-- )
	-- popup:SetSize(650, 40)
	-- popup:SetPoint("CENTER", UIParent, "CENTER")
	-- popup:SetFrameStrata("DIALOG")
	-- popup:Hide()

	-- popup.editBox = CreateFrame("EditBox", nil, frame)
	-- popup.editBox:SetFontObject(ChatFontNormal)
	-- popup.editBox:SetSize(610, 40)
	-- popup.editBox:SetPoint("LEFT", frame, "LEFT", 10, 0)
	-- local hide = function(f) f:GetParent():Hide() end
	-- popup.editBox:SetScript("OnEscapePressed", hide)

	-- popup.close = CreateFrame("Button", nil, frame)
	-- popup.close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	-- popup.close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	-- popup.close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
	-- popup.close:SetSize(32, 32)
	-- popup.close:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
	-- popup.close:SetScript("OnClick", hide)
end

-- local SetHyperlink = ItemRefTooltip.SetHyperlink
-- function ItemRefTooltip:SetHyperlink(data, ...)
	-- local isURL, link = strsplit("~", data)
	-- if isURL and isURL == "bcmurl" then
		-- module:SetPopupText(link)
	-- else
		-- SetHyperlink(self, data, ...)
	-- end
-- end

function module:BuildOptions()
	spartan.opt.args["ModSetting"].args["Chatbox"] = {type="group",name="Chatbox",
		args = {}
	}
end

function module:HideOptions()
	spartan.opt.args["ModSetting"].args["Chatbox"].disabled = true
end