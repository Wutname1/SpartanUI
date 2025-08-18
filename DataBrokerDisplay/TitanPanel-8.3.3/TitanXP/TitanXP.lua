---@diagnostic disable: duplicate-set-field
--[[
-- **************************************************************************
-- * TitanXP.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************
--]]

-- ******************************** Constants *******************************

local TITAN_XP_ID = "XP";
local TITAN_XP_BUTTON = "TitanPanel" .. TITAN_XP_ID .. "Button"
local _G = getfenv(0);
--local TITAN_XP_FREQUENCY = 1;
--local updateTable = { TITAN_XP_ID, TITAN_PANEL_UPDATE_ALL };

-- ******************************** Variables *******************************

local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)

local AceTimer = LibStub("AceTimer-3.0")
local XPTimer = {}
---@diagnostic disable-next-line: missing-fields
XPTimer.timer = nil -- set & cancelled as needed
XPTimer.delay = 10 -- seconds
XPTimer.running = false
XPTimer.last = 0

local trace = false
local trace_update = false

--****** overload the 'time played' text to Chat - if XP requested the API call
local requesting

-- collect the various XP variables in one place
local txp = {
	frame = {},
	lastMobXP = 0,
	XPGain = 0,
	initXP = 0,
	accumXP = 0,
	sessionXP = 0,
	startSessionTime = 0,
	totalTime = 0,
	levelTime = 0,
	sessionTime = 0,
}
-- Save orignal output to Chat
local orig_ChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed
-- Override the output to Chat
ChatFrame_DisplayTimePlayed = function(...)
	if requesting then
		-- XP requested time played, do not spam Chat
		requesting = false
	else
		-- XP did not request time played so output
		orig_ChatFrame_DisplayTimePlayed(...)
	end
end
--****** Override

-- ******************************** Functions *******************************

---local Set icon based on faction
local function SetIcon()
	local icon = TitanPanelXPButtonIcon;
	local factionGroup, factionName = UnitFactionGroup("player");

	if (factionGroup == "Alliance") then
		icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance");
		icon:SetTexCoord(0.046875, 0.609375, 0.03125, 0.59375);
	elseif (factionGroup == "Horde") then
		icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde");
		icon:SetTexCoord(0.046875, 0.609375, 0.015625, 0.578125);
	else
		icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		icon:SetTexCoord(0.046875, 0.609375, 0.03125, 0.59375);
	end
end

---local Add commas or period in the value given per user options
---@param amount number
---@return string
local function comma_value(amount)
	local sep = ""
	local dec = ""
	if (TitanGetVar(TITAN_XP_ID, "UseSeperatorComma")) then
		sep = ","
		dec = "."
	else
		sep = "."
		dec = ","
	end

	return TitanUtils_NumToString(amount, sep, dec)
end

---local Reset session and accumulated variables
---@param self Button
local function ResetSession(self)
	txp.accumXP = 0
	txp.sessionXP = 0
	txp.startSessionTime = time() -- clock time

	local xp = UnitXP("player")
	if xp == nil then
		txp.initXP = 0
	else
		txp.initXP = xp
	end
	txp.lastXP = txp.initXP
end

---local Wrapper for menu to use
local function ResetThisSession()
	ResetSession(_G[TITAN_XP_BUTTON])
end

--[[ 2024 Apr
Change to a repeating timer instead of OnUpdate to reduce cycles
The timer, started OnShow, will update session time here
The prior scheme used OnUpdate which is related to FPS. 
XP does not need that level of precision.
--]]
---local Reset session and accumulated variables; used by timer
local function XPTimeUpdate()
	local elapsed = GetTime() - XPTimer.last
	XPTimer.last = GetTime()
	txp.totalTime = txp.totalTime + elapsed
	txp.levelTime = txp.levelTime + elapsed

	TitanPanelButton_UpdateButton(TITAN_XP_ID)

	if trace then
		local txt = "XP Text"
			.. " " .. tostring(format("%0.2f", elapsed)) .. ""
			TitanPluginDebug(TITAN_XP_ID, txt)
	end
end


---local Get total time played
-- Do not send RequestTimePlayed output to Chat if XP requested the info.
-- Override ChatFrame_DisplayTimePlayed used by RequestTimePlayed().
-- TIME_PLAYED_MSG used to send response.
local function RefreshPlayed()
	txp.frame:RequestTimePlayed()
end

---local Display the plugin on selected Titan bar; register events; start timer; and init vars
---@param self Button
local function OnShow(self)
	local txt = ""

	self:RegisterEvent("TIME_PLAYED_MSG");
	self:RegisterEvent("PLAYER_XP_UPDATE");
	self:RegisterEvent("PLAYER_LEVEL_UP");
	self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");

	RefreshPlayed() -- TIME_PLAYED_MSG

	SetIcon();
	txt = txt .. " | Events"

	if XPTimer.running then
		-- Do not create a new one
	else
		XPTimer.timer = AceTimer:ScheduleRepeatingTimer(XPTimeUpdate, XPTimer.delay)
		XPTimer.running = true
		XPTimer.last = GetTime() -- No need for millisecond precision
	end

	if trace then
		local dbg = "XP _OnShow"
			.. " " .. tostring(txt) .. ""
		TitanPluginDebug(TITAN_XP_ID, dbg)
	end
end

---local Hide the plugin; unregister events; stop timer; and init vars
---@param self Button
local function OnHide(self)
	self:UnregisterEvent("TIME_PLAYED_MSG");
	self:UnregisterEvent("PLAYER_XP_UPDATE");
	self:UnregisterEvent("PLAYER_LEVEL_UP");
	self:UnregisterEvent("CHAT_MSG_COMBAT_XP_GAIN");

	AceTimer:CancelTimer(XPTimer.timer)
	XPTimer.running = false
	XPTimer.timer = nil
end

---local Handle events registered to plugin
---@param self Button
---@param event string
---@param ... any
local function OnEvent(self, event, a1, a2, ...)
	local txt = ""
	if trace then
		txt = "_OnEvent"
			.. " " .. tostring(event) .. ""
		--		.." "..tostring(a1)..""
		--		.." "..tostring(a2)..""
		TitanPluginDebug(TITAN_XP_ID, txt)
	end

	if (event == "PLAYER_ENTERING_WORLD") then
		if a1 == true then
			-- Initial login so start session
			ResetSession(self)
		end
	elseif (event == "TIME_PLAYED_MSG") then
		-- Remember play time
		txp.totalTime = a1;
		txp.levelTime = a2;

		TitanPanelButton_UpdateButton(TITAN_XP_ID)
	elseif (event == "PLAYER_XP_UPDATE") then
		-- XP data init on plugin load and PEW (first time)
		txp.XPGain = UnitXP("player") - txp.lastXP;
		txp.lastXP = UnitXP("player");
		if txp.XPGain < 0 then
			txp.XPGain = 0
		else
			-- Assume it is valid
		end
		txp.sessionXP = UnitXP("player") - txp.initXP + txp.accumXP;
		TitanPanelButton_UpdateButton(TITAN_XP_ID)
		if trace then
			txt = "XP Ev "
				.. " unit " .. tostring(format("%0.1f", UnitXP("player"))) .. ""
				.. " init " .. tostring(format("%0.1f", txp.initXP)) .. ""
				.. " acc " .. tostring(format("%0.1f", txp.accumXP)) .. ""
			TitanPluginDebug(TITAN_XP_ID, txt)
		end
	elseif (event == "PLAYER_LEVEL_UP") then
		txp.levelTime = 0;
		txp.accumXP = txp.accumXP + UnitXPMax("player") - txp.initXP;
		txp.initXP = 0;
		TitanPanelButton_UpdateButton(TITAN_XP_ID)
	elseif (event == "CHAT_MSG_COMBAT_XP_GAIN") then
		local _, _, _, killXP = string.find(a1, "^" .. L["TITAN_XP_GAIN_PATTERN"])
		if killXP then
			txp.lastMobXP = tonumber(killXP)
			if txp.lastMobXP < 0 then -- sanity check
				txp.lastMobXP = 0
			else
				-- Assume valid
			end
			TitanPanelButton_UpdateButton(TITAN_XP_ID)
		end
	end
end

---local Display XP / hour to level data.
local function ShowXPPerHourLevel()
	TitanSetVar(TITAN_XP_ID, "DisplayType", "ShowXPPerHourLevel");
	TitanPanelButton_UpdateButton(TITAN_XP_ID);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleRested", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleToLevel", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfKills", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfGains", false);
end

---local Determine the plugin button text based on user preferences.
---@param id string
---@return string text_label
---@return string text
---@return string | nil labelrested
---@return string | nil rest
---@return string | nil labeltolevel
---@return string | nil toLevelXPText
---@return string | nil labelnumofgains
---@return string | nil numofgains
local function GetButtonText(id)
	local txt = ""
	local button, id = TitanUtils_GetButton(id) -- sanity check, also get plugin frame
	if button and (txp.startSessionTime == nil) then
		if trace then
			txt = "XP "
				.. " " .. tostring("start not set - too early") .. ""
			TitanPluginDebug(TITAN_XP_ID, txt)
		end
		return "XP", ""
	elseif button then
		local totalXP = UnitXPMax("player");
		local currentXP = UnitXP("player");
		local toLevelXP = totalXP - currentXP;
		local sessionXP = button and txp.sessionXP;
		local xpPerHour, xpPerHourText, timeToLevel, timeToLevelText;
		local sessionTime = time() - txp.startSessionTime;
		local levelTime = txp.levelTime;
		local numofkills, numofgains;
		if txp.lastMobXP ~= 0 then
			numofkills = math.ceil(toLevelXP / txp.lastMobXP)
		else
			numofkills = 0 --_G["UNKNOWN"]
		end
		if txp.XPGain ~= 0 then
			numofgains = math.ceil(toLevelXP / txp.XPGain)
		else
			numofgains = 0 --_G["UNKNOWN"]
		end
		if trace_update then
			txt = "XP / Hr"
				.. " sxp" .. tostring(format("%0.1f", sessionXP)) .. ""
				.. " st" .. tostring(format("%0.1f", txp.startSessionTime)) .. ""
			TitanPluginDebug(TITAN_XP_ID, txt)
		end

		if (levelTime) then
			if (TitanGetVar(TITAN_XP_ID, "DisplayType") == "ShowXPPerHourSession") then
				if sessionXP <= 0 then
					xpPerHour = 0
				else
					xpPerHour = sessionXP / sessionTime * 3600
				end
				--			timeToLevel = TitanUtils_Ternary((sessionXP == 0), -1, toLevelXP / sessionXP * sessionTime);
				timeToLevel = (sessionXP == 0) and -1 or toLevelXP / sessionXP * sessionTime;

				xpPerHourText = comma_value(math.floor(xpPerHour + 0.5));
				timeToLevelText = TitanUtils_GetEstTimeText(timeToLevel);

				if trace_update then
					txt = "XP / Hr"
						.. " hr: " .. tostring(format("%0.1f", xpPerHour)) .. ""
						.. " '" .. tostring(xpPerHourText) .. "'"
						.. " lvl: " .. tostring(format("%0.1f", timeToLevel)) .. ""
						.. " '" .. tostring(timeToLevelText) .. "'"
					TitanPluginDebug(TITAN_XP_ID, txt)
				end
				return L["TITAN_XP_BUTTON_LABEL_XPHR_SESSION"], TitanUtils_GetHighlightText(xpPerHourText),
					L["TITAN_XP_BUTTON_LABEL_TOLEVEL_TIME_LEVEL"], TitanUtils_GetHighlightText(timeToLevelText);
			elseif (TitanGetVar(TITAN_XP_ID, "DisplayType") == "ShowXPPerHourLevel") then
				xpPerHour = currentXP / levelTime * 3600;
				timeToLevel = (currentXP == 0) and -1 or toLevelXP / currentXP * levelTime;

				xpPerHourText = comma_value(math.floor(xpPerHour + 0.5));
				timeToLevelText = TitanUtils_GetEstTimeText(timeToLevel);

				return L["TITAN_XP_BUTTON_LABEL_XPHR_LEVEL"], TitanUtils_GetHighlightText(xpPerHourText),
					L["TITAN_XP_BUTTON_LABEL_TOLEVEL_TIME_LEVEL"], TitanUtils_GetHighlightText(timeToLevelText);
			elseif (TitanGetVar(TITAN_XP_ID, "DisplayType") == "ShowSessionTime") then
				return L["TITAN_XP_BUTTON_LABEL_SESSION_TIME"],
					TitanUtils_GetHighlightText(TitanUtils_GetAbbrTimeText(sessionTime));
			elseif (TitanGetVar(TITAN_XP_ID, "DisplayType") == "ShowXPSimple") then
				local toLevelXPText = "";
				local rest = "";
				local labelrested = "";
				local labeltolevel = "";
				local labelnumofkills = "";
				local labelnumofgains = "";
				local percent = floor(10000 * (currentXP / totalXP) + 0.5) / 100;
				if TitanGetVar(TITAN_XP_ID, "ShowSimpleToLevel") then
					toLevelXPText = TitanUtils_GetColoredText(
						format(L["TITAN_XP_FORMAT"], comma_value(math.floor(toLevelXP + 0.5))), _G["GREEN_FONT_COLOR"]);
					labeltolevel = L["TITAN_XP_XPTOLEVELUP"];
				end
				if TitanGetVar(TITAN_XP_ID, "ShowSimpleRested") then
					rest = TitanUtils_GetColoredText(comma_value(GetXPExhaustion() == nil and "0" or GetXPExhaustion()),
						{ r = 0.44, g = 0.69, b = 0.94 });
					labelrested = L["TITAN_XP_TOTAL_RESTED"];
				end
				if TitanGetVar(TITAN_XP_ID, "ShowSimpleNumOfKills") then
					numofkills = TitanUtils_GetColoredText(comma_value(numofkills), { r = 0.24, g = 0.7, b = 0.44 })
					labelnumofkills = L["TITAN_XP_KILLS_LABEL_SHORT"];
				else
					numofkills = ""
				end
				if TitanGetVar(TITAN_XP_ID, "ShowSimpleNumOfGains") then
					numofgains = TitanUtils_GetColoredText(comma_value(numofgains), { r = 1, g = 0.49, b = 0.04 })
					labelnumofgains = L["TITAN_XP_XPGAINS_LABEL_SHORT"];
				else
					numofgains = ""
				end

				if TitanGetVar(TITAN_XP_ID, "ShowSimpleNumOfGains") then
					return L["TITAN_XP_LEVEL_COMPLETE"], TitanUtils_GetHighlightText(percent .. "%"),
						labelrested, rest,
						labeltolevel, toLevelXPText,
						labelnumofgains, numofgains
				else
					return L["TITAN_XP_LEVEL_COMPLETE"], TitanUtils_GetHighlightText(percent .. "%"),
						labelrested, rest,
						labeltolevel, toLevelXPText,
						labelnumofkills, numofkills
				end
			end
		else
			if trace_update then
				TitanPluginDebug(TITAN_XP_ID, "pending")
			end
			return "", "(" .. L["TITAN_XP_UPDATE_PENDING"] .. ")"
		end
	else
		-- Invalid button - frame not created?
	end
	return "", ""
end

---local Generate tooltip text
---@return string
local function GetTooltipText()
	local res = ""
	local button, id = TitanUtils_GetButton(TITAN_XP_ID) -- sanity check, also get plugin frame
	if button then
		local totalTime = txp.totalTime;
		local sessionTime = time() - txp.startSessionTime;
		local levelTime = txp.levelTime;
		-- failsafe to ensure that an error wont be returned
		if levelTime then
			local totalXP = UnitXPMax("player");
			local currentXP = UnitXP("player");
			local toLevelXP = totalXP - currentXP;
			local currentXPPercent = currentXP / totalXP * 100;
			local toLevelXPPercent = toLevelXP / totalXP * 100;
			local xpPerHourThisLevel = currentXP / levelTime * 3600;
			local xpPerHourThisSession = txp.sessionXP / sessionTime * 3600;
			local estTimeToLevelThisLevel = TitanUtils_Ternary((currentXP == 0), -1,
				toLevelXP / (max(currentXP, 1)) * levelTime);
			local estTimeToLevelThisSession = 0;

			if txp.sessionXP > 0 then
				estTimeToLevelThisSession = TitanUtils_Ternary((txp.sessionXP == 0), -1,
					toLevelXP / txp.sessionXP * sessionTime);
			end
			local numofkills, numofgains;
			if txp.lastMobXP ~= 0 then
				numofkills = math.ceil(toLevelXP / txp.lastMobXP)
			else
				numofkills = 0 --_G["UNKNOWN"]
			end
			if txp.XPGain ~= 0 then
				numofgains = math.ceil(toLevelXP / txp.XPGain)
			else
				numofgains = 0 --_G["UNKNOWN"]
			end

			res = "" ..
				L["TITAN_XP_TOOLTIP_TOTAL_TIME"] ..
				"\t" .. TitanUtils_GetHighlightText(TitanUtils_GetAbbrTimeText(totalTime)) .. "\n" ..
				L["TITAN_XP_TOOLTIP_LEVEL_TIME"] ..
				"\t" .. TitanUtils_GetHighlightText(TitanUtils_GetAbbrTimeText(levelTime)) .. "\n" ..
				L["TITAN_XP_TOOLTIP_SESSION_TIME"] ..
				"\t" .. TitanUtils_GetHighlightText(TitanUtils_GetAbbrTimeText(sessionTime)) .. "\n" ..
				"\n" ..
				L["TITAN_XP_TOOLTIP_TOTAL_XP"] .. "\t" .. TitanUtils_GetHighlightText(comma_value(totalXP)) .. "\n" ..
				L["TITAN_XP_TOTAL_RESTED"] ..
				"\t" ..
				TitanUtils_GetHighlightText(comma_value(GetXPExhaustion() == nil and "0" or GetXPExhaustion())) .. "\n" ..
				L["TITAN_XP_TOOLTIP_LEVEL_XP"] ..
				"\t" ..
				TitanUtils_GetHighlightText(comma_value(currentXP) .. " " ..
					format(L["TITAN_XP_PERCENT_FORMAT"], currentXPPercent)) .. "\n" ..
				L["TITAN_XP_TOOLTIP_TOLEVEL_XP"] ..
				"\t" ..
				TitanUtils_GetHighlightText(comma_value(toLevelXP) .. " " ..
					format(L["TITAN_XP_PERCENT_FORMAT"], toLevelXPPercent)) .. "\n" ..
				L["TITAN_XP_TOOLTIP_SESSION_XP"] ..
				"\t" .. TitanUtils_GetHighlightText(comma_value(txp.sessionXP)) .. "\n" ..
				format(L["TITAN_XP_KILLS_LABEL"], comma_value(txp.lastMobXP)) ..
				"\t" .. TitanUtils_GetHighlightText(comma_value(numofkills)) .. "\n" ..
				format(L["TITAN_XP_XPGAINS_LABEL"], comma_value(txp.XPGain)) ..
				"\t" .. TitanUtils_GetHighlightText(comma_value(numofgains)) .. "\n" ..
				"\n" ..
				L["TITAN_XP_TOOLTIP_XPHR_LEVEL"] ..
				"\t" ..
				TitanUtils_GetHighlightText(format(L["TITAN_XP_FORMAT"], comma_value(math.floor(xpPerHourThisLevel + 0.5)))) ..
				"\n" ..
				L["TITAN_XP_TOOLTIP_XPHR_SESSION"] ..
				"\t" ..
				TitanUtils_GetHighlightText(format(L["TITAN_XP_FORMAT"], comma_value(math.floor(xpPerHourThisSession + 0.5)))) ..
				"\n" ..
				L["TITAN_XP_TOOLTIP_TOLEVEL_LEVEL"] ..
				"\t" .. TitanUtils_GetHighlightText(TitanUtils_GetAbbrTimeText(estTimeToLevelThisLevel)) .. "\n" ..
				L["TITAN_XP_TOOLTIP_TOLEVEL_SESSION"] ..
				"\t" .. TitanUtils_GetHighlightText(TitanUtils_GetAbbrTimeText(estTimeToLevelThisSession));
		else
		end
	else
		-- No button - not created?
	end

	return res
end

---local Place commas or periods in the number per user options.
---@param chosen string
local function Seperator(chosen)
	if chosen == "UseSeperatorComma" then
		TitanSetVar(TITAN_XP_ID, "UseSeperatorComma", true);
		TitanSetVar(TITAN_XP_ID, "UseSeperatorPeriod", false);
	end
	if chosen == "UseSeperatorPeriod" then
		TitanSetVar(TITAN_XP_ID, "UseSeperatorComma", false);
		TitanSetVar(TITAN_XP_ID, "UseSeperatorPeriod", true);
	end
	TitanPanelButton_UpdateButton(TITAN_XP_ID);
end

---local Display XP per hour this session.
local function ShowXPPerHourSession()
	TitanSetVar(TITAN_XP_ID, "DisplayType", "ShowXPPerHourSession");
	TitanPanelButton_UpdateButton(TITAN_XP_ID);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleRested", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleToLevel", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfKills", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfGains", false);
end

---local Display session time.
local function ShowSessionTime()
	TitanSetVar(TITAN_XP_ID, "DisplayType", "ShowSessionTime");
	TitanPanelButton_UpdateButton(TITAN_XP_ID);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleRested", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleToLevel", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfKills", false);
	TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfGains", false);
end

---local Display simple XP data (% level, rest, xp to level).
local function ShowXPSimple()
	TitanSetVar(TITAN_XP_ID, "DisplayType", "ShowXPSimple");
	TitanPanelButton_UpdateButton(TITAN_XP_ID);
end

---local Generate right click menu.
local function CreateMenu()
	local info = {};
	if TitanPanelRightClickMenu_GetDropdownLevel() == 2 then
		TitanPanelRightClickMenu_AddTitle(L["TITAN_XP_MENU_SIMPLE_BUTTON_TITLE"], 2);

		info = {};
		info.text = L["TITAN_XP_MENU_SIMPLE_BUTTON_RESTED"];
		info.func = function() TitanPanelRightClickMenu_ToggleVar({ TITAN_XP_ID, "ShowSimpleRested" }) end
		info.checked = TitanUtils_Ternary(TitanGetVar(TITAN_XP_ID, "ShowSimpleRested"), 1, nil);
		info.keepShownOnClick = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = L["TITAN_XP_MENU_SIMPLE_BUTTON_TOLEVELUP"];
		info.func = function() TitanPanelRightClickMenu_ToggleVar({ TITAN_XP_ID, "ShowSimpleToLevel" }) end
		info.checked = TitanUtils_Ternary(TitanGetVar(TITAN_XP_ID, "ShowSimpleToLevel"), 1, nil);
		info.keepShownOnClick = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = L["TITAN_XP_MENU_SIMPLE_BUTTON_KILLS"];
		info.func = function()
			TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfKills", true)
			TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfGains", false)
		end
		info.checked = TitanUtils_Ternary(TitanGetVar(TITAN_XP_ID, "ShowSimpleNumOfKills"), 1, nil);
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = L["TITAN_XP_MENU_SIMPLE_BUTTON_XPGAIN"];
		info.func = function()
			TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfGains", true)
			TitanSetVar(TITAN_XP_ID, "ShowSimpleNumOfKills", false)
		end
		info.checked = TitanUtils_Ternary(TitanGetVar(TITAN_XP_ID, "ShowSimpleNumOfGains"), 1, nil);
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		return
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 1 then
		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_XP_ID].menuText);
		info = {};
		info.text = L["TITAN_XP_MENU_SHOW_XPHR_THIS_SESSION"];
		info.func = ShowXPPerHourSession;
		info.checked = TitanUtils_Ternary("ShowXPPerHourSession" == TitanGetVar(TITAN_XP_ID, "DisplayType"), 1, nil);
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = L["TITAN_XP_MENU_SHOW_XPHR_THIS_LEVEL"];
		info.func = ShowXPPerHourLevel;
		info.checked = TitanUtils_Ternary("ShowXPPerHourLevel" == TitanGetVar(TITAN_XP_ID, "DisplayType"), 1, nil);
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = L["TITAN_XP_MENU_SHOW_SESSION_TIME"];
		info.func = ShowSessionTime;
		info.checked = TitanUtils_Ternary("ShowSessionTime" == TitanGetVar(TITAN_XP_ID, "DisplayType"), 1, nil);
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = L["TITAN_XP_MENU_SHOW_RESTED_TOLEVELUP"];
		info.func = ShowXPSimple;
		info.hasArrow = 1;
		info.checked = TitanUtils_Ternary("ShowXPSimple" == TitanGetVar(TITAN_XP_ID, "DisplayType"), 1, nil);
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		TitanPanelRightClickMenu_AddSpacer();
		TitanPanelRightClickMenu_AddCommand(L["TITAN_XP_MENU_RESET_SESSION"], TITAN_XP_ID, ResetThisSession);
		TitanPanelRightClickMenu_AddCommand(L["TITAN_XP_MENU_REFRESH_PLAYED"], TITAN_XP_ID, RefreshPlayed);
	end

	TitanPanelRightClickMenu_AddSpacer();

	info = {};
	info.text = L["TITAN_PANEL_USE_COMMA"];
	info.checked = TitanGetVar(TITAN_XP_ID, "UseSeperatorComma");
	info.func = function()
		Seperator("UseSeperatorComma")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_PANEL_USE_PERIOD"];
	info.checked = TitanGetVar(TITAN_XP_ID, "UseSeperatorPeriod");
	info.func = function()
		Seperator("UseSeperatorPeriod")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddControlVars(TITAN_XP_ID)
end

---local Create plugin .registry and and init some variables and register for first events
---@param self Button
local function OnLoad(self)
	local notes = ""
		.. "Adds information to Titan Panel about XP earned and time to level.\n"
		.."- Updates XP per hour statistics every "..XPTimer.delay.." sec.\n"
	self.registry = {
		id = TITAN_XP_ID,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = L["TITAN_XP_MENU_TEXT"],
		menuTextFunction = CreateMenu,
		buttonTextFunction = GetButtonText,
		tooltipTitle = L["TITAN_XP_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		iconWidth = 16,
		notes = notes,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowColoredText = false,
			DisplayOnRightSide = true
		},
		savedVariables = {
			DisplayType = "ShowXPPerHourSession",
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowSimpleRested = false,
			ShowSimpleToLevel = false,
			ShowSimpleNumOfKills = false,
			ShowSimpleNumOfGains = false,
			UseSeperatorComma = true,
			UseSeperatorPeriod = false,
			DisplayOnRightSide = false,
		}
	};
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	ResetSession(self)
end

---local Create needed frames
local function Create_Frames()
	if _G[TITAN_XP_BUTTON] then
		-- if already created
	else
		-- general container frame
		local f = CreateFrame("Frame", nil, UIParent)
		--	f:Hide()

		-- Titan plugin button
		local window = CreateFrame("Button", TITAN_XP_BUTTON, f, "TitanPanelComboTemplate")
		txp.frame = window
		window:SetFrameStrata("FULLSCREEN")
		-- Using SetScript("OnLoad",   does not work
		OnLoad(window);
		--	TitanPanelButton_OnLoad(window); -- Titan XML template calls this...

		window:SetScript("OnShow", function(self)
			OnShow(self)
			TitanPanelButton_OnShow(self)
		end)
		window:SetScript("OnHide", function(self)
			OnHide(self)
		end)
		window:SetScript("OnEvent", function(self, event, ...)
			OnEvent(self, event, ...)
		end)
		--		window:SetScript("OnUpdate", function(self, elapsed)
		--			OnUpdate(self, elapsed)
		--		end)

		-- Do not output Chat messages when using RequestTimePlayed
		function window:RequestTimePlayed()
			requesting = true
			RequestTimePlayed()
		end
	end
end


if TITAN_ID then -- it exists
	Create_Frames() -- do the work
end
