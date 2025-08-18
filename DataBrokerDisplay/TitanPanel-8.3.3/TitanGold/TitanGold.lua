---@diagnostic disable: duplicate-set-field
--[[
-- **************************************************************************
-- * TitanGold.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************
--]]

-- WoW method to get addon name
local addonName = ...

-- ******************************** Constants *******************************
local TITAN_GOLD_ID = "Gold";
local TITAN_BUTTON = "TitanPanel" .. TITAN_GOLD_ID .. "Button"
local TITAN_GOLD_VERSION = TITAN_VERSION;
local TITAN_GOLD_SPACERBAR = "-----------------------";
local updateTable = { TITAN_GOLD_ID, TITAN_PANEL_UPDATE_TOOLTIP };

-- ******************************** Variables *******************************
GoldSave = {} -- saved vars in TOC
local GOLD_INITIALIZED = false;
local GOLD_INDEX = "";
local GOLD_STARTINGGOLD;
local GOLD_SESSIONSTART;
local AceTimer = LibStub("AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local GoldTimer = {};
local GoldTimerRunning = false
local _G = getfenv(0);
local realmName = ""     -- fill on PEW
local realmNames = {}    -- fill on PEW
local merged_realms = {} -- fill on PEW

-- English faction for indexing and sorting and coloring
local TITAN_ALLIANCE = "Alliance"
local TITAN_HORDE = "Horde"

local player_faction, player_faction_locale = UnitFactionGroup("Player")
local player_name = GetUnitName("Player")

--[[  debug
local FACTION_ALLIANCE = "Alliance_debug"
local FACTION_HORDE = "Horde_debug"
--]]

-- Topic debug tool / scheme
local dbg = Titan_Debug:New(TITAN_GOLD_ID)
dbg:EnableDebug(false)
dbg:EnableTopic("Events", false)
dbg:EnableTopic("Flow", false)

-- ******************************** Functions *******************************

---local Take the total cash and make it into a nice, colorful string of g s c (gold silver copper)
---@param value number
---@param show_zero boolean
---@param show_neg boolean
---@return string outstr Formatted cash for output
---@return integer gold part of value
---@return integer silver part of value
---@return integer copper part of value
local function NiceCash(value, show_zero, show_neg)
	local sep = ""
	local dec = ""
	if (TitanGetVar(TITAN_GOLD_ID, "UseSeperatorComma")) then
		sep = ","
		dec = "."
	elseif (TitanGetVar(TITAN_GOLD_ID, "UseSeperatorPeriod")) then
		sep = "."
		dec = ","
	elseif (TitanGetVar(TITAN_GOLD_ID, "UseSeperatorSpace")) then
		sep = " "
		dec = "."
	end

	local outstr, gold, silver, copper =
		TitanUtils_CashToString(value, sep, dec,
			TitanGetVar(TITAN_GOLD_ID, "ShowGoldOnly"),
			TitanGetVar(TITAN_GOLD_ID, "ShowCoinLabels"),
			TitanGetVar(TITAN_GOLD_ID, "ShowCoinIcons"),
			TitanGetVar(TITAN_GOLD_ID, "ShowColoredText"))
	return outstr, gold, silver, copper
end

-- A bit overkill but make a class for the Warbank bank functions

local Warband = {
	bank_sum = 0,
	active = false,
	label = "",
}
---local Warband Bank debug
function Gold_debug(reason)
	local str = ""
		.. "$" .. tostring(NiceCash(GetMoney(), false, false))
		.. " WB " .. reason
		.. " " .. tostring(Warband.active)
		.. " " .. tostring(Warband.label)
		.. " " .. tostring(NiceCash(Warband.bank_sum, false, false))
	return str
end

---local Check if Warband Bank is in this version and user requested
---@return boolean
function Warband.Use()
	local res = false
	if Warband.active then
		if TitanGetVar(TITAN_GOLD_ID, "ShowWarband") then
			res = true
		else
			-- Not requested by user
		end
	else
		-- Likely Classic version
	end
	return res
end

---local Update Warband Bank info - sum
function Warband.SetSum()
	if Warband.Use() then
		-- Really just prevents errors if not implemented in the WoW version

		-- There *may* have been instances of failure reported as Titan errors
		-- Wrap in pcall for safety
		--Warband.bank_sum = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
		local sum = 0
		local call_success = false
		local ret_val = nil

		call_success, -- needed for pcall
		ret_val =  -- actual return values
			pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)

		if call_success then
			-- Assume a valid Warband cash amount (WOWMONEY)
			sum = ret_val
		else
			-- Set to zero as a default and not an error.
			sum = 0
		end
		Warband.bank_sum = sum

	else
		-- Likely Classic version
	end
end

---local Set Warband Bank info
function Warband.Init()
	-- check for func in case either Classic implements  (Added 11.0.0)
	Warband.active = (C_Bank and C_Bank.CanUseBank) and true or false
	if Warband.active then
		Warband.label = L["TITAN_WARBAND_BANK"]
	else
		-- Likely Classic version
	end
end

---local Return Warband Bank info
---@return number
function Warband.GetSum()
	return Warband.bank_sum
end

---local Return Warband Bank info
---@return string
function Warband.GetName()
	return Warband.label
end

--===

---Helper to safely encapsulate WoW API (returns number in form ggsscc)
---@return number
local function Get_Money()
	local money = GetMoney()
	-- Do safety check to prevent errors
	if type(money) == "number" then
		-- assume it is good
	else
		-- Not accurate but safe
		money = 0
	end
	Warband.SetSum() -- update warbank as well
	return money
end

local function GetConnectedRealms()
	local realms = GetAutoCompleteRealms()
	if #realms == 0 then
		realms[1] = GetRealmName()
	end
	return realms
end

---Take a table of indexes to sort GoldSave
---@param gold_table table
---@return table sorted May not be need but it is explicit
local function SortByIndex(gold_table)
	local by_realm = TitanGetVar(TITAN_GOLD_ID, "GroupByRealm")
	local by_name = TitanGetVar(TITAN_GOLD_ID, "SortByName")
	-- This section will sort the array based on user preference
	-- * by name or by gold amount descending
	-- * grouping by realm if selected
	if by_name then
		table.sort(gold_table, function(key1, key2)
			if by_realm then
				if GoldSave[key1].realm ~= GoldSave[key2].realm then
					return GoldSave[key1].realm < GoldSave[key2].realm
				end
			end

			return GoldSave[key1].name < GoldSave[key2].name
		end)
	else
		table.sort(gold_table, function(key1, key2)
			if by_realm then
				if GoldSave[key1].realm ~= GoldSave[key2].realm then
					return GoldSave[key1].realm < GoldSave[key2].realm
				end
			end

			return GoldSave[key1].gold > GoldSave[key2].gold
		end)
	end

	return gold_table
end

---local Create Gold index <character>_<server>::<faction>and see if the toon is in the table.
---@param character string
---@param charserver string
---@param char_faction string
local function CreateIndex(character, charserver, char_faction)
	local index = character .. "_" .. charserver .. "::" .. char_faction

	-- See if this is a new toon to Gold;
	-- There may be a timing issue on some systems where Gold is told to 'Show'
	-- by Titan before Gold processes PEW event.
	if (GoldSave[GOLD_INDEX] == nil) then
		GoldSave[GOLD_INDEX] = {}
		GoldSave[GOLD_INDEX] = { gold = 0, name = player_name }
	end

	return index
end

---local Break apart Gold index
---@param info string
---@return string
---@return string
---@return string
local function GetIndexInfo(info)
	local character, charserver, char_faction = string.match(info, '(.*)_(.*)::(.*)')
	return character, charserver, char_faction
end

---@class IndexInfo Index flags
---@field valid boolean Saved toon is valid
---@field char_name string Saved toon name
---@field server string Saved toon server
---@field faction string Saved toon faction
---@field same_faction boolean Saved toon faction is same as player
---@field ignore_faction boolean User selection to ignore faction or not
---@field same_realm boolean Saved realm is same as this server
---@field merge_realm boolean Saved realm is in mergerd server list (connected servers)
---@field show_toon boolean Show server - simple test

---local Take Gold index and return parts plus various flags
---@param index string
---@return IndexInfo
local function EvalIndexInfo(index)
	local res = { valid = false }
	local character, charserver, char_faction = GetIndexInfo(index)

	if character then
		res.valid = true

		res.char_name = character
		res.server = charserver
		res.faction = char_faction

		res.ignore_faction = TitanGetVar(TITAN_GOLD_ID, "IgnoreFaction")

		if (char_faction == player_faction) then
			res.same_faction = true
		else
			res.same_faction = false
		end

		if (charserver == realmName) then
			res.same_realm = true
		else
			res.same_realm = false
		end

		local saved_server = string.gsub(charserver, "%s", "") -- GetAutoCompleteRealms removes spaces, idk why...
		if merged_realms[saved_server] then
			res.merge_realm = true
		else
			res.merge_realm = false
		end

		if (res.ignore_faction or res.same_faction)
			and GoldSave[index].show then
			res.show_toon = true
		else
			res.show_toon = false
		end
	else
		-- do not fill in
	end

	return res
end

---local Take the total cash and make it into a nice, colorful string of g s c (gold silver copper)
---@param value number
---@return string outstr Formatted cash for output
---@return integer gold part of value
---@return integer silver part of value
---@return integer copper part of value
local function NiceTextCash(value)
	local sep = ""
	local dec = ""
	if (TitanGetVar(TITAN_GOLD_ID, "UseSeperatorComma")) then
		sep = ","
		dec = "."
	elseif (TitanGetVar(TITAN_GOLD_ID, "UseSeperatorPeriod")) then
		sep = "."
		dec = ","
	elseif (TitanGetVar(TITAN_GOLD_ID, "UseSeperatorSpace")) then
		sep = " "
		dec = "."
	end

	local outstr, gold, silver, copper =
		TitanUtils_CashToString(value, sep, dec,
			TitanGetVar(TITAN_GOLD_ID, "ShowGoldOnly"),
			true, --TitanGetVar(TITAN_GOLD_ID, "ShowCoinLabels"),
			false, --TitanGetVar(TITAN_GOLD_ID, "ShowCoinIcons"),
			TitanGetVar(TITAN_GOLD_ID, "ShowColoredText"))
	return outstr, gold, silver, copper
end

---local Create Show menu - list of characters in same faction
---@param faction string
---@param level number
local function ShowMenuButtons(faction, level)
	TitanPanelRightClickMenu_AddTitle(L["TITAN_GOLD_SHOW_PLAYER"], level)
	local info = {};
	-- Sort names for the menu list
	local GoldSorted = {};
	for index, money in pairs(GoldSave) do
		table.insert(GoldSorted, index)
	end
	GoldSorted = SortByIndex(GoldSorted)

	for i = 1, #GoldSorted do
		local index = GoldSorted[i]
		local character, charserver, char_faction = GetIndexInfo(index)
		if character and (char_faction == faction) then
			info.text = character .. " - " .. charserver.." "..NiceTextCash(GoldSave[index].gold).."";
			info.value = character;
			info.keepShownOnClick = true;
			info.checked = function()
				return GoldSave[index].show
			end
			info.func = function()
				GoldSave[index].show = not GoldSave[index].show;
				TitanPanelButton_UpdateButton(TITAN_GOLD_ID)
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end
	end
end

---local Create Delete menu - list of characters in same faction
---@param faction string
---@param level number
local function DeleteMenuButtons(faction, level)
	TitanPanelRightClickMenu_AddTitle(L["TITAN_GOLD_DELETE_PLAYER"], level)

	local info = {};
	local name = player_name
	local server = realmName;

	-- Sort names for the menu list
	local GoldSorted = {};
	for index, money in pairs(GoldSave) do
		table.insert(GoldSorted, index)
	end
	GoldSorted = SortByIndex(GoldSorted)

	for i = 1, #GoldSorted do
		local index = GoldSorted[i]
		local character, charserver, char_faction = GetIndexInfo(index)
		info.notCheckable = true
		if character and (char_faction == faction) then
			info.text = character .. " - " .. charserver.." "..NiceTextCash(GoldSave[index].gold).."";
			info.value = character;
			info.func = function()
				GoldSave[index] = {}
				GoldSave[index] = nil
				TitanPanelButton_UpdateButton(TITAN_GOLD_ID)
			end
			-- cannot delete current character
			if name == character and server == charserver then
				info.disabled = 1;
			else
				info.disabled = nil;
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end
	end
end

---local Based on user Coin selection set None | Labels | Icons
---@param chosen string
local function ShowProperLabels(chosen)
	if chosen == "ShowCoinNone" then
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinNone", true);
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinLabels", false);
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinIcons", false);
	end
	if chosen == "ShowCoinLabels" then
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinNone", false);
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinLabels", true);
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinIcons", false);
	end
	if chosen == "ShowCoinIcons" then
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinNone", false);
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinLabels", false);
		TitanSetVar(TITAN_GOLD_ID, "ShowCoinIcons", true);
	end
	TitanPanelButton_UpdateButton(TITAN_GOLD_ID);
end

---local Based on user Seperator selection set Comma | Period | Space
---@param chosen string
local function Seperator(chosen)
	if chosen == "UseSeperatorComma" then
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorComma", true);
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorPeriod", false);
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorSpace", false);
	end
	if chosen == "UseSeperatorPeriod" then
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorComma", false);
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorPeriod", true);
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorSpace", false);
	end
	if chosen == "UseSeperatorSpace" then
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorComma", false);
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorPeriod", false);
		TitanSetVar(TITAN_GOLD_ID, "UseSeperatorSpace", true);
	end
	TitanPanelButton_UpdateButton(TITAN_GOLD_ID);
end

---local Based on user Server selection set Merge | Seperate | All
---@param chosen string
local function Merger(chosen)
	if chosen == "MergeServers" then
		TitanSetVar(TITAN_GOLD_ID, "MergeServers", true);
		TitanSetVar(TITAN_GOLD_ID, "SeparateServers", false);
		TitanSetVar(TITAN_GOLD_ID, "AllServers", false);
	end
	if chosen == "SeparateServers" then
		TitanSetVar(TITAN_GOLD_ID, "MergeServers", false);
		TitanSetVar(TITAN_GOLD_ID, "SeparateServers", true);
		TitanSetVar(TITAN_GOLD_ID, "AllServers", false);
	end
	if chosen == "AllServers" then
		TitanSetVar(TITAN_GOLD_ID, "MergeServers", false);
		TitanSetVar(TITAN_GOLD_ID, "SeparateServers", false);
		TitanSetVar(TITAN_GOLD_ID, "AllServers", true);
	end
	TitanPanelButton_UpdateButton(TITAN_GOLD_ID);
end

---local Toggles when the player selects the show gold/hour stats
local function GoldGPH_Toggle()
	TitanToggleVar(TITAN_GOLD_ID, "DisplayGoldPerHour")

	if TitanGetVar(TITAN_GOLD_ID, "DisplayGoldPerHour") then
		if GoldTimerRunning then
			-- Do not create a new one
		else
			GoldTimer = AceTimer:ScheduleRepeatingTimer(TitanPanelPluginHandle_OnUpdate, 1, updateTable)
			GoldTimerRunning = true
		end
	elseif GoldTimer and not TitanGetVar(TITAN_GOLD_ID, "DisplayGoldPerHour") then
		AceTimer:CancelTimer(GoldTimer)
		GoldTimerRunning = false
	end
end

---local Helper for TotalGold
--- If toon is to be shown add amount to total; otherwise pass back running total
local function ToonAdd(show, amount, total)
	local new_total = 0

	if show then
		new_total = total + amount
	else
		new_total = total
	end

	return new_total
end

---local Calculates total gold for display per user selections
---@return integer
local function TotalGold()
	-- EvalIndexInfo checks the toon info against the user options
	-- then returns as a table of 'flags'.
	-- The if within each loop checks the appropriate flags per user server display option.

	local ttlgold = 0;

	if TitanGetVar(TITAN_GOLD_ID, "SeparateServers") then
		-- Parse the database and display all characters on this server
		for index, money in pairs(GoldSave) do
			local char = EvalIndexInfo(index)
			if char.valid and char.same_realm and char.show_toon then
				ttlgold = ToonAdd(GoldSave[index].show, GoldSave[index].gold, ttlgold)
			else
				-- Do not show per flags
			end
		end
	elseif TitanGetVar(TITAN_GOLD_ID, "MergeServers") then
		-- Parse the database and display characters on merged / connected servers
		for index, money in pairs(GoldSave) do
			local char = EvalIndexInfo(index)
			if char.valid and char.merge_realm and char.show_toon then
				ttlgold = ToonAdd(GoldSave[index].show, GoldSave[index].gold, ttlgold)
			else
				-- Do not show per flags
			end
		end
	elseif TitanGetVar(TITAN_GOLD_ID, "AllServers") then
		-- Parse the database and display characters on all servers
		for index, money in pairs(GoldSave) do
			local char = EvalIndexInfo(index)
			if char.valid and char.show_toon then
				ttlgold = ToonAdd(GoldSave[index].show, GoldSave[index].gold, ttlgold)
			else
				-- Do not show per flags
			end
		end
	end

	--
	-- === Add Warband Bank, if enabled and requested
	if Warband.Use() then
		ttlgold = ttlgold + Warband.GetSum()
	end

	return ttlgold;
end

-- ====== Tool tip routines

---local Generate formatted tooltip text
---@return string
local function GetTooltipText()
	local GoldSorted = {};
	local currentMoneyRichText = "";
	local countelements = 0;
	local faction = player_faction
	local ignore_faction = TitanGetVar(TITAN_GOLD_ID, "IgnoreFaction")

	for _ in pairs(realmNames) do
		countelements = countelements + 1
	end

	-- insert all keys from hash into the GoldSorted array

	if TitanGetVar(TITAN_GOLD_ID, "SeparateServers") then
		-- Parse the database and display characters from this server
		for index, money in pairs(GoldSave) do
			local char = EvalIndexInfo(index)
			if char.valid and char.same_realm and char.show_toon then
				table.insert(GoldSorted, index);
			end
		end
	elseif TitanGetVar(TITAN_GOLD_ID, "MergeServers") then
		-- Parse the database and display characters from merged / connected servers
		for index, money in pairs(GoldSave) do
			local char = EvalIndexInfo(index)

			if char.valid and char.merge_realm and char.show_toon then
				table.insert(GoldSorted, index);
			end
		end
	elseif TitanGetVar(TITAN_GOLD_ID, "AllServers") then
		-- Parse the database and display characters from all servers
		for index, money in pairs(GoldSave) do
			local char = EvalIndexInfo(index)
			if char.valid and char.show_toon then
				table.insert(GoldSorted, index);
			end
		end
	end

	local by_realm = TitanGetVar(TITAN_GOLD_ID, "GroupByRealm")
	GoldSorted = SortByIndex(GoldSorted)

	-- Array holds all characters to display, nicely sorted.
	currentMoneyRichText = ""
	local coin_str = ""
	local faction_text = ""
	local curr_realm = ""
	local show_dash = false
	local show_realm = true
	local character, charserver, char_faction
	for i = 1, #GoldSorted do
		character, charserver, char_faction = GetIndexInfo(GoldSorted[i])
		coin_str = NiceCash(GoldSave[GoldSorted[i]].gold, false, false)
		show_dash = false
		show_realm = true

		if (TitanGetVar(TITAN_GOLD_ID, "SeparateServers")) then
			show_realm = false
		elseif (TitanGetVar(TITAN_GOLD_ID, "MergeServers")) then
			show_dash = true
		elseif (TitanGetVar(TITAN_GOLD_ID, "AllServers")) then
			show_dash = true
		end

		if by_realm then
			-- Set a realm header
			if charserver ~= curr_realm then
				currentMoneyRichText = currentMoneyRichText .. "\n"
					.. "-- " .. charserver
				curr_realm = charserver
			end
			show_dash = false
			show_realm = false
		end

		if ignore_faction then
			local font_size = TitanPanelGetVar("FontSize")
			local icon_pre = "|TInterface/AddOns/TitanGold/Artwork/"
			local icon_post = ":" .. font_size .. ":" .. font_size .. ":2:0|t"
			local a_icon = icon_pre .. "UI_AllianceIcon-round" .. icon_post
			local h_icon = icon_pre .. "UI_HordeIcon-round" .. icon_post
			if char_faction == TITAN_ALLIANCE then
				faction_text = " " .. a_icon
			elseif char_faction == TITAN_HORDE then
				faction_text = " " .. h_icon
			end
		end

		currentMoneyRichText = currentMoneyRichText .. "\n"
			.. character
			.. (show_dash and "-" or "")
			.. (show_realm and charserver or "")
			.. faction_text
			.. "\t" .. coin_str
	end

	--
	-- === Add Warband Bank
	--
	if Warband.Use() then
		local cash = NiceCash(Warband.GetSum(), false, false)
		local war_name = ""..Warband.GetName() -- localized
		currentMoneyRichText = currentMoneyRichText .. "\n"
			.. "------ \t +" .. "\n"
			.. war_name
			.. "\t" .. cash
		local msg = "" .. war_name .. " ".. cash
		dbg:Out("Tooltip", msg)
	end


	--[[
print("TG"
.." "..tostring(counter)
.." "..tostring(x0)
.." "..tostring(x1)
.." "..tostring(getn(GoldSorted))
.." "..tostring(TitanGetVar(TITAN_GOLD_ID, "SeparateServers"))
.." "..tostring(TitanGetVar(TITAN_GOLD_ID, "MergeServers"))
.." "..tostring(TitanGetVar(TITAN_GOLD_ID, "AllServers"))
.." "..tostring(TITANPANEL_TOOLTIP)
--.." "..tostring(TITANPANEL_TOOLTIP_X)
)
--]]

	--
	-- === Add Total per user options
	--
	coin_str = ""
	-- Display total gold
	coin_str = NiceCash(TotalGold(), false, false)
	currentMoneyRichText = currentMoneyRichText .. "\n"
		.. TITAN_GOLD_SPACERBAR .. "\n"
		.. L["TITAN_GOLD_TTL_GOLD"] .. "\t" .. coin_str

	-- find session earnings and earning per hour
	local sesstotal = Get_Money() - GOLD_STARTINGGOLD;
	local negative = false;
	if (sesstotal < 0) then
		sesstotal = math.abs(sesstotal);
		negative = true;
	end

	local sesslength = GetTime() - GOLD_SESSIONSTART;
	local perhour = math.floor(sesstotal / sesslength * 3600);

	coin_str = NiceCash(GOLD_STARTINGGOLD, false, false)

	local session_status;
	local per_hour_status;
	local sessionMoneyRichText = ""
	if TitanGetVar(TITAN_GOLD_ID, "ShowSessionInfo") then
		sessionMoneyRichText = "\n\n" .. TitanUtils_GetHighlightText(L["TITAN_GOLD_STATS_TITLE"])
			.. "\n" .. L["TITAN_GOLD_START_GOLD"] .. "\t" .. coin_str .. "\n"

		if (negative) then
			session_status = TitanUtils_GetRedText(L["TITAN_GOLD_SESS_LOST"])
			per_hour_status = TitanUtils_GetRedText(L["TITAN_GOLD_PERHOUR_LOST"])
		else
			session_status = TitanUtils_GetGreenText(L["TITAN_GOLD_SESS_EARNED"])
			per_hour_status = TitanUtils_GetGreenText(L["TITAN_GOLD_PERHOUR_EARNED"])
		end

		coin_str = NiceCash(sesstotal, true, true)
		sessionMoneyRichText = sessionMoneyRichText
			.. session_status
			.. "\t" .. coin_str .. "\n";

		if TitanGetVar(TITAN_GOLD_ID, "DisplayGoldPerHour") then
			coin_str = NiceCash(perhour, true, true)
			sessionMoneyRichText = sessionMoneyRichText
				.. per_hour_status
				.. "\t" .. coin_str .. "\n";
		end
	else
		-- Do not display session info
	end

	--
	-- === Add Gold notes and info
	--
	local final_tooltip = TitanUtils_GetGoldText(L["TITAN_GOLD_TOOLTIPTEXT"] .. " : ")

	local final_server = ""
	if realmNames == nil or TitanGetVar(TITAN_GOLD_ID, "SeparateServers") then
		final_server = realmName
	elseif TitanGetVar(TITAN_GOLD_ID, "MergeServers") then
		final_server = L["TITAN_GOLD_MERGED"]
	elseif TitanGetVar(TITAN_GOLD_ID, "AllServers") then
		final_server = ALL
	end
	final_server = TitanUtils_GetGoldText(final_server .. " : ")

	local final_faction = ""
	if ignore_faction then
		final_faction = TitanUtils_GetGoldText(ALL)
	elseif faction == TITAN_ALLIANCE then
		final_faction = TitanUtils_GetHexText(FACTION_ALLIANCE, Titan_Global.colors.alliance)
	elseif faction == TITAN_HORDE then
		final_faction = TitanUtils_GetHexText(FACTION_HORDE, Titan_Global.colors.horde)
	end

	return ""
		.. currentMoneyRichText .. "\n"
		.. TITAN_GOLD_SPACERBAR .. "\n"
		.. final_tooltip .. final_server .. final_faction .. "\n"
		.. sessionMoneyRichText
end
-- ======

-- ====== Right click menu routines

---local Toggle whether button shows player or total gold (based on other user selections).
local function ViewAll_Toggle()
	TitanToggleVar(TITAN_GOLD_ID, "ViewAll")
	TitanPanelButton_UpdateButton(TITAN_GOLD_ID)
end

---local Toggle whether tooltip sorts by toon name or gold amount.
local function Sort_Toggle()
	TitanToggleVar(TITAN_GOLD_ID, "SortByName")
end

local function ResetSession()
	GOLD_STARTINGGOLD = Get_Money();
	GOLD_SESSIONSTART = GetTime();
	DEFAULT_CHAT_FRAME:AddMessage(TitanUtils_GetGreenText(L["TITAN_GOLD_SESSION_RESET"]));
end

---local See if this toon is in saved vars AFTER PEW event.
--- Get current total and session start time. Toon gold is available via API AFTER PEW event.
local function Initialize_Array()
	dbg:Out("Flow", "Init inititated")

	local info = ""
	if (GOLD_INITIALIZED) then
		-- already done
	else
		-- See if this is a new toon to Gold saved vars or reset
		-- Set gold to 0; it will be set properly later
		if (GoldSave[GOLD_INDEX] == nil) then
			GoldSave[GOLD_INDEX] = {}
			GoldSave[GOLD_INDEX] = { gold = 0, name = player_name }
		end

		Warband.Init()

		-- Ensure the saved vars are usable
		for index, money in pairs(GoldSave) do
			local character, charserver, char_faction = GetIndexInfo(index)

			-- Could be a new toon to Gold or an updated Gold
			local show_toon = GoldSave[index].show
			if show_toon == nil then
				show_toon = true
			end
			GoldSave[index].show = show_toon
			GoldSave[index].realm = charserver -- added July 2022

			-- added Aug 2022 for #1332.
			-- Faction in index was not set for display in tool tip.
			-- Created localized faction as a field; set every time in case user changes languages
			if char_faction == TITAN_ALLIANCE then
				GoldSave[index].faction = FACTION_ALLIANCE
			elseif char_faction == TITAN_HORDE then
				GoldSave[index].faction = FACTION_HORDE
			else
				GoldSave[index].faction = FACTION_OTHER
			end
		end
		GOLD_STARTINGGOLD = Get_Money();
		GOLD_SESSIONSTART = GetTime();
		GOLD_INITIALIZED = true;

		-- added Jan 2025 
		-- Also restore initial gold:
		-- new toon; Titan install / update / reload
		GoldSave[GOLD_INDEX].gold = Get_Money()

		info = ""
		.." "..tostring(GOLD_SESSIONSTART)..""
		.." "..tostring(GOLD_STARTINGGOLD)..""
		.." "..tostring(Warband.GetSum())..""
		end

	local msg = ""
	.." "..tostring(GOLD_INITIALIZED)..""
	.." "..info..""
	dbg:Out("Flow", ">Init done : "..msg)
end

---local Clear the gold array and rebuild
---@param self Button
local function ClearData(self)
	GOLD_INITIALIZED = false;

	GoldSave = {};
	Initialize_Array();

	TitanPanelButton_UpdateButton(TITAN_GOLD_ID)

	DEFAULT_CHAT_FRAME:AddMessage(TitanUtils_GetGreenText(L["TITAN_GOLD_DB_CLEARED"]));
end

---local Pops an 'are you sure' when user clicks to reset the gold array
local function TitanGold_ClearDB()
	StaticPopupDialogs["TITANGOLD_CLEAR_DATABASE"] = {
		text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"] .. " "
			.. L["TITAN_GOLD_MENU_TEXT"]) .. "\n\n" .. L["TITAN_GOLD_CLEAR_DATA_WARNING"],
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			local frame = _G["TitanPanelGoldButton"]
			ClearData(frame)
		end,
		showAlert = 1,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	};
	StaticPopup_Show("TITANGOLD_CLEAR_DATABASE");
end

---local Generate the tooltip display option menu
local function DisplayOptions()
	local info = {};
	info.notCheckable = true
	info.text = L["TITAN_GOLD_SORT_BY"];
	info.value = "Sorting";
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-- Which characters to show
	--  - Separate : this server
	--  - Merge : connected / merged servers
	--  - All : any server
	info = {};
	info.text = L["TITAN_GOLD_SEPARATE"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "SeparateServers");
	info.func = function()
		Merger("SeparateServers")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_GOLD_MERGE"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "MergeServers");
	info.func = function()
		Merger("MergeServers")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_GOLD_ALL"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "AllServers");
	info.func = function()
		Merger("AllServers")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-- Option to ignore faction - per 9.2.5 changes
	info = {};
	info.text = L["TITAN_GOLD_IGNORE_FACTION"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "IgnoreFaction");
	info.func = function()
		TitanToggleVar(TITAN_GOLD_ID, "IgnoreFaction");
		TitanPanelButton_UpdateButton(TITAN_GOLD_ID);
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-- What labels to show next to money : none / text / icon
	info = {};
	info.text = L["TITAN_GOLD_COIN_NONE"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "ShowCoinNone");
	info.func = function()
		ShowProperLabels("ShowCoinNone")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_GOLD_COIN_LABELS"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "ShowCoinLabels");
	info.func = function()
		ShowProperLabels("ShowCoinLabels")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_GOLD_COIN_ICONS"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "ShowCoinIcons");
	info.func = function()
		ShowProperLabels("ShowCoinIcons")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-- Show gold only option - no silver, no copper
	info = {};
	info.text = L["TITAN_GOLD_ONLY"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "ShowGoldOnly");
	info.func = function()
		TitanToggleVar(TITAN_GOLD_ID, "ShowGoldOnly");
		TitanPanelButton_UpdateButton(TITAN_GOLD_ID);
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-- Use thousands separater : , . ' '
	info = {};
	info.text = L["TITAN_PANEL_USE_COMMA"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "UseSeperatorComma");
	info.func = function()
		Seperator("UseSeperatorComma")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_PANEL_USE_PERIOD"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "UseSeperatorPeriod");
	info.func = function()
		Seperator("UseSeperatorPeriod")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TITAN_PANEL_USE_SPACE = "Use Space"
	info = {};
	info.text = TITAN_PANEL_USE_SPACE
	info.checked = TitanGetVar(TITAN_GOLD_ID, "UseSeperatorSpace");
	info.func = function()
		Seperator("UseSeperatorSpace")
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-- Show session info
	info = {};
	info.text = L["TITAN_GOLD_SHOW_STATS_TITLE"];
	info.checked = TitanGetVar(TITAN_GOLD_ID, "ShowSessionInfo");
	info.func = function()
		TitanToggleVar(TITAN_GOLD_ID, "ShowSessionInfo");
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-- Function to toggle gold per hour sort
	info = {};
	info.text = L["TITAN_GOLD_TOGGLE_GPH_SHOW"]
	info.checked = TitanGetVar(TITAN_GOLD_ID, "DisplayGoldPerHour");
	info.func = function()
		GoldGPH_Toggle()
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
end

---local Generate the options menu
local function CreateMenu()
	if TitanPanelRightClickMenu_GetDropdownLevel() == 1 then
		-- Menu title
		TitanPanelRightClickMenu_AddTitle(L["TITAN_GOLD_ITEMNAME"]);

		-- Function to toggle button gold view
		local info = {};
		info.text = L["TITAN_GOLD_TOGGLE_ALL_TEXT"]
		info.checked = TitanGetVar(TITAN_GOLD_ID, "ViewAll");
		info.func = function()
			ViewAll_Toggle()
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = L["TITAN_GOLD_TOGGLE_PLAYER_TEXT"]
		info.checked = not TitanGetVar(TITAN_GOLD_ID, "ViewAll");
		info.func = function()
			ViewAll_Toggle()
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		TitanPanelRightClickMenu_AddSeparator();

		-- Display options
		info = {};
		info.notCheckable = true
		info.text = L["TITAN_GOLD_TOOLTIP_DISPLAY_OPTIONS"];
		info.value = "Display_Options";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		TitanPanelRightClickMenu_AddSeparator();

		if Warband.active then
			-- Function to toggle show / hide of Warbank gold
			info = {};
			info.text = L["TITAN_GOLD_INCLUDE_WARBANK"]

			info.checked = TitanGetVar(TITAN_GOLD_ID, "ShowWarband");
			info.func = function()
				TitanToggleVar(TITAN_GOLD_ID, "ShowWarband")
				TitanPanelButton_UpdateButton(TITAN_GOLD_ID)
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel())
		else
			-- Warbank not in this expansion
		end

		-- Show / delete toons
		info = {};
		info.notCheckable = true
		info.text = L["TITAN_GOLD_SHOW_PLAYER"];
		info.value = "ToonShow";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.notCheckable = true
		info.text = L["TITAN_GOLD_DELETE_PLAYER"];
		info.value = "ToonDelete";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		TitanPanelRightClickMenu_AddSeparator();

		-- Option to clear the enter database
		info = {};
		info.notCheckable = true
		info.text = L["TITAN_GOLD_CLEAR_DATA_TEXT"];
		info.func = TitanGold_ClearDB;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		TitanPanelRightClickMenu_AddCommand(L["TITAN_GOLD_RESET_SESS_TEXT"], TITAN_GOLD_ID, ResetSession);

		TitanPanelRightClickMenu_AddControlVars(TITAN_GOLD_ID)
	end

	-- Second (2nd) level for show / delete | sort by
	if TitanPanelRightClickMenu_GetDropdownLevel() == 2
		and TitanPanelRightClickMenu_GetDropdMenuValue() == "ToonDelete" then
		local info = {};
		info.notCheckable = true
		info.text = L["TITAN_GOLD_FACTION_PLAYER_ALLY"];
		info.value = "DeleteAlliance";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info.text = L["TITAN_GOLD_FACTION_PLAYER_HORDE"];
		info.value = "DeleteHorde";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 2
		and TitanPanelRightClickMenu_GetDropdMenuValue() == "ToonShow" then
		local info = {};
		info.notCheckable = true
		info.text = L["TITAN_GOLD_FACTION_PLAYER_ALLY"];
		info.value = "ShowAlliance";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info.text = L["TITAN_GOLD_FACTION_PLAYER_HORDE"];
		info.value = "ShowHorde";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 3
		and TitanPanelRightClickMenu_GetDropdMenuValue() == "Sorting" then
		-- Show gold only option - no silver, no copper
		local info = {};
		info.text = L["TITAN_GOLD_TOGGLE_SORT_GOLD"]
		info.checked = not TitanGetVar(TITAN_GOLD_ID, "SortByName");
		info.func = function()
			Sort_Toggle()
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		local info = {};
		info.text = L["TITAN_GOLD_TOGGLE_SORT_NAME"]
		info.checked = TitanGetVar(TITAN_GOLD_ID, "SortByName");
		info.func = function()
			Sort_Toggle()
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

		local info = {};
		info.text = L["TITAN_GOLD_GROUP_BY_REALM"];
		info.checked = TitanGetVar(TITAN_GOLD_ID, "GroupByRealm")
		info.func = function()
			TitanToggleVar(TITAN_GOLD_ID, "GroupByRealm")
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 2
		and TitanPanelRightClickMenu_GetDropdMenuValue() == "Display_Options" then
		DisplayOptions()
	end

	-- Third (3rd) level for the list of characters / toons
	if TitanPanelRightClickMenu_GetDropdownLevel() == 3 and TitanPanelRightClickMenu_GetDropdMenuValue() == "DeleteAlliance" then
		DeleteMenuButtons(TITAN_ALLIANCE, 3)
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 3 and TitanPanelRightClickMenu_GetDropdMenuValue() == "DeleteHorde" then
		DeleteMenuButtons(TITAN_HORDE, 3)
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 3 and TitanPanelRightClickMenu_GetDropdMenuValue() == "ShowAlliance" then
		ShowMenuButtons(TITAN_ALLIANCE, 3)
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 3 and TitanPanelRightClickMenu_GetDropdMenuValue() == "ShowHorde" then
		ShowMenuButtons(TITAN_HORDE, 3)
	end
end

---local Get the gold total the user wants (server or player).
local function FindGold()
	if (not GOLD_INITIALIZED) then
		-- in case there is no db entry for this toon, return blank.
		-- When Gold is ready it will init
		return ""
	end

	local ret_str = ""
	local ttlgold = 0;

	if TitanGetVar(TITAN_GOLD_ID, "ViewAll") then
		ttlgold = TotalGold()
	else
		ttlgold = GoldSave[GOLD_INDEX].gold
	end

	ret_str = NiceCash(ttlgold, true, false)

	return L["TITAN_GOLD_MENU_TEXT"] .. ": " .. FONT_COLOR_CODE_CLOSE, ret_str
end

---local Build the plugin .registry and init and register for events
---@param self Button
local function OnLoad(self)
	local notes = ""
		.. "Keeps track of all gold held by a player's toons.\n"
		.. "- Can show by server / merged servers / all servers.\n"
		.. "- Can show by faction.\n"
		.. "Shift + Left click will print list of connected servers to chat.\n"
	self.registry = {
		id = TITAN_GOLD_ID,
		category = "Built-ins",
		version = TITAN_GOLD_VERSION,
		menuText = L["TITAN_GOLD_MENU_TEXT"],
		menuTextFunction = CreateMenu,
		tooltipTitle = L["TITAN_GOLD_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		buttonTextFunction = FindGold,
		icon = "Interface\\AddOns\\TitanGold\\Artwork\\TitanGold",
		iconWidth = 16,
		notes = notes,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = false,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			Initialized = true,
			DisplayGoldPerHour = true,
			ShowCoinNone = false,
			ShowCoinLabels = true,
			ShowCoinIcons = false,
			ShowGoldOnly = false,
			SortByName = true,
			ViewAll = true,
			ShowIcon = true,
			ShowLabelText = false,
			ShowColoredText = true,
			DisplayOnRightSide = false,
			UseSeperatorComma = true,
			UseSeperatorPeriod = false,
			UseSeperatorSpace = false,
			MergeServers = false,
			SeparateServers = true,
			AllServers = false,
			IgnoreFaction = false,
			GroupByRealm = false,
			gold = { total = "112233", neg = false },
			ShowSessionInfo = true,
			ShowWarband = true,
		}
	};

	self:RegisterEvent("ADDON_LOADED");
--	self:RegisterEvent("PLAYER_ENTERING_WORLD");
end

---local When shown, register needed events and start timer for gold per hour
---@param self Button
local function OnShow(self)
	Initialize_Array()
	self:RegisterEvent("PLAYER_MONEY")

	if GoldSave and TitanGetVar(TITAN_GOLD_ID, "DisplayGoldPerHour") then
		if GoldTimerRunning then
			-- Do not start a new one
		else
			GoldTimer = AceTimer:ScheduleRepeatingTimer(TitanPanelPluginHandle_OnUpdate, 1, updateTable)
			GoldTimerRunning = true
		end
	else
		-- timer running or user does not want gold per hour
	end

	local msg = ""
		.." "..Gold_debug("OnShow")
	dbg:Out("Flow", msg)
	end

---local When shown, unregister needed events and stop timer for gold per hour
---@param self Button
local function OnHide(self)
	self:UnregisterEvent("PLAYER_MONEY");
	AceTimer:CancelTimer(GoldTimer)
	GoldTimerRunning = false
end

---local Handle registered events for this plugin
---@param self Button
---@param event string
---@param ... any
local function OnEvent(self, event, a1, ...)
	if (event == "PLAYER_MONEY") then
		if (GOLD_INITIALIZED) then
			GoldSave[GOLD_INDEX].gold = Get_Money()
			TitanPanelButton_UpdateButton(TITAN_GOLD_ID)
		end
	elseif (event == "ADDON_LOADED") then
		if a1 == addonName then
			realmName = GetRealmName() -- this realm
			realmNames = GetConnectedRealms()
			-- flip to make a simple lookup later rather than a loop
			for index, realm in pairs(realmNames) do
				merged_realms[realm] = true
			end

			-- Faction is English to use as index NOT display
			GOLD_INDEX = CreateIndex(player_name, realmName, player_faction)

			self:UnregisterEvent("ADDON_LOADED");
		else
			-- Not this addon
			return -- no debug, if enabled
		end
	end

	dbg:Out("Events", event)
end

---Button clicks - only shift-left for now
---@param self Button
---@param button string
local function OnClick(self, button)
	if button == "LeftButton" and IsShiftKeyDown() then
		local realms = GetConnectedRealms()
		local this_realm = " * "
		local mark = ""
		TitanPrint("Connected Realms:", "plain")
		for idx = 1, #realms do
			if realms[idx] == realmName then
				mark = this_realm
			else
				mark = ""
			end
			TitanPrint("- " .. tostring(realms[idx]) .. mark, "plain")
		end
	end
end

---local Create required Gold frames
local function Create_Frames()
	if _G[TITAN_BUTTON] then
		return -- if already created
	end

	-- general container frame
	local f = CreateFrame("Frame", nil, UIParent)
	--	f:Hide()

	-- Titan plugin button
	local window = CreateFrame("Button", TITAN_BUTTON, f, "TitanPanelComboTemplate")
	window:SetFrameStrata("FULLSCREEN")
	-- Using SetScript("OnLoad",   does not work
	OnLoad(window);
	--	TitanPanelButton_OnLoad(window); -- Titan XML template calls this...

	window:SetScript("OnShow", function(self)
		OnShow(self);
		TitanPanelButton_OnShow(self);
	end)
	window:SetScript("OnHide", function(self)
		OnHide(self);
	end)
	window:SetScript("OnEvent", function(self, event, ...)
		OnEvent(self, event, ...)
	end)
	window:SetScript("OnClick", function(self, button)
		OnClick(self, button);
		TitanPanelButton_OnClick(self, button);
	end)
end

Create_Frames() -- do the work
