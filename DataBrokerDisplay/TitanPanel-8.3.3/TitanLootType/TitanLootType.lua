---@diagnostic disable: duplicate-set-field
--[[
-- **************************************************************************
-- * TitanLootType.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************
--]]

-- ******************************** Constants *******************************
local TITAN_LOOTTYPE_ID = "LootType";
local TITAN_BUTTON = "TitanPanel"..TITAN_LOOTTYPE_ID.."Button"

local _G = getfenv(0);
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local TitanLootMethod = {};
local updateTable = {TITAN_LOOTTYPE_ID, TITAN_PANEL_UPDATE_ALL};
TitanLootMethod["freeforall"] = {text = L["TITAN_LOOTTYPE_FREE_FOR_ALL"]};
TitanLootMethod["roundrobin"] = {text = L["TITAN_LOOTTYPE_ROUND_ROBIN"]};
TitanLootMethod["master"] = {text = L["TITAN_LOOTTYPE_MASTER_LOOTER"]};
TitanLootMethod["group"] = {text = L["TITAN_LOOTTYPE_GROUP_LOOT"]};
TitanLootMethod["needbeforegreed"] = {text = L["TITAN_LOOTTYPE_NEED_BEFORE_GREED"]};
TitanLootMethod["personalloot"] = {text = L["TITAN_LOOTTYPE_PERSONAL"]};

-- ******************************** Variables *******************************
local loot_spec_name = ""
local current_spec = ""

-- ******************************** Functions *******************************
local LootMethod = nil
if C_PartyInfo and C_PartyInfo.GetLootMethod then
	LootMethod = C_PartyInfo.GetLootMethod
else
	LootMethod = GetLootMethod
end

--[[
-- **************************************************************************
-- NAME : TitanPanelLootTypeButton_OnLoad()
-- DESC : Registers the plugin upon it loading
-- **************************************************************************
--]]
function TitanPanelLootTypeButton_OnLoad(self)
	local notes = ""
		.."Adds group loot information to Titan Panel.\n"
		.."- Option to add instance difficulty information.\n"
		.."- Option to add current spec and loot spec.\n"
	self.registry = {
		id = TITAN_LOOTTYPE_ID,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = L["TITAN_LOOTTYPE_MENU_TEXT"],
		buttonTextFunction = "TitanPanelLootTypeButton_GetButtonText",
		tooltipTitle = L["TITAN_LOOTTYPE_TOOLTIP"],
		tooltipTextFunction = "TitanPanelLootTypeButton_GetTooltipText",
		icon = "Interface\\AddOns\\TitanLootType\\TitanLootType",
		iconWidth = 16,
		notes = notes,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowColoredText = false,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			RandomRoll = 100,
			DisplayOnRightSide = false,
			ShowDungeonDiff = false,
			DungeonDiffType = "AUTO",
			ShowLootType = true,
			ShowLootSpec = true,
		}
	};

	self:RegisterEvent("GROUP_ROSTER_UPDATE");
	self:RegisterEvent("RAID_ROSTER_UPDATE");
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED");
	self:RegisterEvent("CHAT_MSG_SYSTEM");
	
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	self:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
end

function TitanPanelLootTypeButton_GetDungeonDifficultyIDText(isRaid, withpar)
	local par1, par2 = "", ""
	if withpar then par1, par2 = "(", ")" end
	local diffstr = "|cffffff9a"..par1.._G["UNKNOWN"]..par2.."|r"
	if isRaid then
		-- raids
		local diff = GetRaidDifficultyID()
		if not diff then return diffstr end
		local name, groupType, isHeroic, isChallengeMode, displayHeroic, displayMythic, toggleDifficultyID = GetDifficultyInfo(diff)
		-- remove () chars from difficulty
		local tmpstr = string.gsub(name, "%(", "")
		tmpstr = string.gsub(tmpstr, "%)", "")
		if diff == 14 then
			diffstr = _G["GREEN_FONT_COLOR_CODE"]..par1..tmpstr..par2.."|r"
		elseif diff == 15 then
			diffstr = _G["ORANGE_FONT_COLOR_CODE"]..par1..tmpstr..par2.."|r"
		else
			diffstr = _G["RED_FONT_COLOR_CODE"]..par1..tmpstr..par2.."|r"
		end
	else
		-- dungeons
		local diff = GetDungeonDifficultyID()
		if not diff then return diffstr end
		local name, groupType, isHeroic, isChallengeMode, displayHeroic, displayMythic, toggleDifficultyID = GetDifficultyInfo(diff)
		-- remove () chars from difficulty
		local tmpstr = string.gsub(name, "%(", "")
		tmpstr = string.gsub(tmpstr, "%)", "")
		if diff == 1 then
			diffstr = _G["GREEN_FONT_COLOR_CODE"]..par1..tmpstr..par2.."|r"
		elseif diff == 2 then
			diffstr = _G["ORANGE_FONT_COLOR_CODE"]..par1..tmpstr..par2.."|r"
		else
			diffstr = _G["RED_FONT_COLOR_CODE"]..par1..tmpstr..par2.."|r"
		end
	end
	return diffstr
end

--[[
-- **************************************************************************
-- NAME : TitanPanelLootTypeButton_OnEvent()
-- DESC : Parse events registered to plugin and act on them
-- **************************************************************************
--]]
function TitanPanelLootTypeButton_OnEvent(self, event, ...)
	local arg1 = ...;
	if event == "CHAT_MSG_SYSTEM" then
		-- Match difficulty system message to alert addon for possible update
		-- dungeons
		local strm1 = format( _G["ERR_DUNGEON_DIFFICULTY_CHANGED_S"], _G["PLAYER_DIFFICULTY1"]) -- "Normal" (difficultyID=1)
		local strm2 = format( _G["ERR_DUNGEON_DIFFICULTY_CHANGED_S"], _G["PLAYER_DIFFICULTY2"]) -- "Heroic" (difficultyID=2)
		local strm3 = format( _G["ERR_DUNGEON_DIFFICULTY_CHANGED_S"], _G["PLAYER_DIFFICULTY6"]) -- "Mythic" (difficultyID=23)
		local strm4 = format( _G["ERR_DUNGEON_DIFFICULTY_CHANGED_S"], _G["PLAYER_DIFFICULTY5"]) -- "Challenge Mode" (difficultyID=8)

		-- raids
		local strm5 = format( _G["ERR_RAID_DIFFICULTY_CHANGED_S"], _G["PLAYER_DIFFICULTY1"]) -- "Normal" (difficultyID=14)
		local strm6 = format( _G["ERR_RAID_DIFFICULTY_CHANGED_S"], _G["PLAYER_DIFFICULTY2"]) -- "Heroic" (difficultyID=15)
		local strm7 = format( _G["ERR_RAID_DIFFICULTY_CHANGED_S"], _G["PLAYER_DIFFICULTY6"]) -- "Mythic" (difficultyID=16)

--			PLAYER_DIFFICULTY1="Normal"
--			PLAYER_DIFFICULTY2="Heroic"
--			PLAYER_DIFFICULTY3="Raid Finder"
--			PLAYER_DIFFICULTY4="Flexible"
--			PLAYER_DIFFICULTY5="Challenge"
--			PLAYER_DIFFICULTY6="Mythic"
--			PLAYER_DIFFICULTY_TIMEWALKER="Timewalking"

		-- legacy raid
--		local strm8 = format( _G["ERR_RAID_DIFFICULTY_CHANGED_S"], _G["LEGACY_RAID_DIFFICULTY1"]) -- "10 Player" (difficultyID=3)
--		local strm9 = format( _G["ERR_RAID_DIFFICULTY_CHANGED_S"], _G["LEGACY_RAID_DIFFICULTY2"]) -- "25 Player" (difficultyID=4)
--		local strm8 = format( _G["ERR_RAID_DIFFICULTY_CHANGED_S"], _G["LEGACY_RAID_DIFFICULTY3"]) -- "10 Player" (difficultyID=5)
--		local strm9 = format( _G["ERR_RAID_DIFFICULTY_CHANGED_S"], _G["LEGACY_RAID_DIFFICULTY4"]) -- "25 Player" (difficultyID=6)

		if (arg1 == strm1 or arg1 == strm2 or arg1 == strm3 or arg1 == strm4 or arg1 == strm5 or arg1 == strm6 or arg1 == strm7) and TitanGetVar(TITAN_LOOTTYPE_ID, "ShowDungeonDiff") then
			TitanPanelPluginHandle_OnUpdate(updateTable)
		end
		return;
	end
	TitanPanelPluginHandle_OnUpdate(updateTable)
end

--[[
-- **************************************************************************
-- NAME : TitanPanelLootTypeButton_GetButtonText(id)
-- DESC : Calculate loottype and then display data on button
-- VARS : id = button ID
-- **************************************************************************
--]]
function TitanPanelLootTypeButton_GetButtonText(id)
	local lootTypeText, lootThreshold, color, dungeondiff;
	dungeondiff = "";

	if (GetNumSubgroupMembers() > 0) or (GetNumGroupMembers() > 0) then
		lootTypeText = TitanLootMethod[LootMethod()].text;
		lootThreshold = GetLootThreshold();
		color = _G["ITEM_QUALITY_COLORS"][lootThreshold];
	else
		lootTypeText = _G["SOLO"];
		color = _G["GRAY_FONT_COLOR"];
	end
	if TitanGetVar(TITAN_LOOTTYPE_ID, "ShowDungeonDiff") then
		if TitanGetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType") == "DUNGEON" then
			-- Dungeon
			dungeondiff = dungeondiff.." "..TitanPanelLootTypeButton_GetDungeonDifficultyIDText(false, true)
		elseif TitanGetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType") == "RAID" then
			-- Raid
			dungeondiff = dungeondiff.." "..TitanPanelLootTypeButton_GetDungeonDifficultyIDText(true, true)
		elseif TitanGetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType") == "AUTO" then
			-- Auto
			if UnitExists("party1") and (GetNumGroupMembers() == 0 or GetNumGroupMembers() < 0) then dungeondiff = dungeondiff.." "..TitanPanelLootTypeButton_GetDungeonDifficultyIDText(false, true) end
			if GetNumGroupMembers() > 0 then dungeondiff = dungeondiff.." "..TitanPanelLootTypeButton_GetDungeonDifficultyIDText(true, true) end
		end
	end
	
	-- Determine current spec
	local spec = 0
	local id, name, descr, icon, role, is_rec, is_allowed 
	spec = GetSpecialization() -- 1-4 ; nil or 5 (Initial) assume none
	if spec == nil or spec == 5 then 
		name = (NONE or "None...")
	else 
		id, name, descr, icon, role, is_rec, is_allowed = GetSpecializationInfo(spec)
	end
	current_spec = name -- for tool tip

	-- Determine loot spec
	local loot_label = ((LOOT.." "..SPECIALIZATION) or "Loot Spec")..": "
	local loot_spec = GetLootSpecialization()
	if loot_spec == 0 then -- 0 means current spec
	else -- Id means user has set
		id, name, descr, icon, role, is_rec, is_allowed = GetSpecializationInfoByID(loot_spec)
	end
	
	loot_spec_name = name -- for tool tip
--[[
print("T Loot"
.." "..tostring(spec).." "
.." "..tostring(loot_spec).." "
--.." "..tostring(GetSpecializationInfo(spec)).." "
.." "..tostring(name).." "
)
--]]
	local show_loot_type = TitanGetVar(TITAN_LOOTTYPE_ID, "ShowLootType")
	local show_loot_spec = TitanGetVar(TITAN_LOOTTYPE_ID, "ShowLootSpec")
	local ltl, ltd, csl, csd, lsl, lsd
	
	if show_loot_type then
		ltl = L["TITAN_LOOTTYPE_BUTTON_LABEL"]
		ltd = TitanUtils_GetColoredText(lootTypeText, color)..dungeondiff
	else
		ltl = ""
		ltd = ""
	end
	
	if show_loot_spec then
		csl = (SPECIALIZATION or "Spec")..": "
		csd = current_spec
	else
		csl = ""
		csd = ""
	end

	if show_loot_spec then
		lsl = loot_label
		lsd = loot_spec_name
	else
		lsl = ""
		lsd = ""
	end
	
	return ltl, ltd, csl, TitanUtils_GetHighlightText(csd), lsl, TitanUtils_GetHighlightText(lsd)
	
end

--[[
-- **************************************************************************
-- NAME : TitanPanelLootTypeButton_GetTooltipText()
-- DESC : Display tooltip text
-- **************************************************************************
--]]
function TitanPanelLootTypeButton_GetTooltipText()
	local party = ""
	if (GetNumSubgroupMembers() > 0) or (GetNumGroupMembers() > 0) then
		local lootTypeText = TitanLootMethod[LootMethod()].text;
		local lootThreshold = GetLootThreshold();
		local itemQualityDesc = _G["ITEM_QUALITY"..lootThreshold.."_DESC"];
		local color = _G["ITEM_QUALITY_COLORS"][lootThreshold];
		party = ""..
			_G["LOOT_METHOD"]..": \t"..TitanUtils_GetHighlightText(lootTypeText).."\n"..
			_G["LOOT_THRESHOLD"]..": \t"..TitanUtils_GetColoredText(itemQualityDesc, color).."\n"
	else
		party = TitanUtils_GetNormalText(_G["ERR_NOT_IN_GROUP"]).."\n"
	end
	local tt = ""..
			L["TITAN_LOOTTYPE_DUNGEONDIFF_LABEL"]..": \t"..TitanPanelLootTypeButton_GetDungeonDifficultyIDText().."\n"..
			L["TITAN_LOOTTYPE_DUNGEONDIFF_LABEL2"]..": \t"..TitanPanelLootTypeButton_GetDungeonDifficultyIDText(true).."\n"..
			(SPECIALIZATION or "Spec")..": \t"..current_spec.."\n"..
			(SELECT_LOOT_SPECIALIZATION or "Loot Spec")..": \t"..loot_spec_name.."\n"..
			party..
			"\n"..
			TitanUtils_GetGreenText(L["TITAN_LOOTTYPE_TOOLTIP_HINT1"]).."\n"..
			TitanUtils_GetGreenText(L["TITAN_LOOTTYPE_TOOLTIP_HINT2"])..
			""
	return tt
end

--[[
-- **************************************************************************
-- NAME : TitanPanelLootType_Random100()
-- DESC : Define random 100 loottype
-- **************************************************************************
--]]
function TitanPanelLootType_Random100()
	TitanSetVar(TITAN_LOOTTYPE_ID, "RandomRoll", 100);
end

--[[
-- **************************************************************************
-- NAME : TitanPanelLootType_Random1000()
-- DESC : Define random 1000 loottype
-- **************************************************************************
--]]
function TitanPanelLootType_Random1000()
	TitanSetVar(TITAN_LOOTTYPE_ID, "RandomRoll", 1000);
end

--[[
-- **************************************************************************
-- NAME : TitanPanelLootType_GetRoll(num)
-- DESC : Confirm loottype is random roll
-- **************************************************************************
--]]
function TitanPanelLootType_GetRoll(num)
	local temp = TitanGetVar(TITAN_LOOTTYPE_ID, "RandomRoll");
	if temp == num then
		return 1;
	end
	return nil;
end

--[[
-- **************************************************************************
-- NAME : TitanPanelRightClickMenu_PrepareLootTypeMenu()
-- DESC : Display rightclick menu options
-- **************************************************************************
--]]
function TitanPanelRightClickMenu_PrepareLootTypeMenu()
	local info = {};
	if TitanPanelRightClickMenu_GetDropdownLevel() == 2 and TitanPanelRightClickMenu_GetDropdMenuValue() == "RandomRoll" then
		info = {};
		info.text = "100";
		info.value = 100;
		info.func = TitanPanelLootType_Random100;
		info.checked = TitanPanelLootType_GetRoll(info.value);
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = "1000";
		info.value = 1000;
		info.func = TitanPanelLootType_Random1000;
		info.checked = TitanPanelLootType_GetRoll(info.value);
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 2 and TitanPanelRightClickMenu_GetDropdMenuValue() == "ShowDungeonDiffMenu" then
		info = {};
		info.text = _G["LFG_TYPE_DUNGEON"];
		info.func = function() TitanSetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType", "DUNGEON"); TitanPanelButton_UpdateButton(TITAN_LOOTTYPE_ID) end
		info.checked = function() if TitanGetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType") == "DUNGEON" then return true end return false end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = _G["LFG_TYPE_RAID"];
		info.func = function() TitanSetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType", "RAID"); TitanPanelButton_UpdateButton(TITAN_LOOTTYPE_ID) end
		info.checked = function() if TitanGetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType") == "RAID" then return true end return false end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = L["TITAN_LOOTTYPE_AUTODIFF_LABEL"];
		info.func = function() TitanSetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType", "AUTO"); TitanPanelButton_UpdateButton(TITAN_LOOTTYPE_ID) end
		info.checked = function() if TitanGetVar(TITAN_LOOTTYPE_ID, "DungeonDiffType") == "AUTO" then return true end return false end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 2 and TitanPanelRightClickMenu_GetDropdMenuValue() == "SetDungeonDiff" then
		info = {};
		info.text = _G["GREEN_FONT_COLOR_CODE"].._G["PLAYER_DIFFICULTY1"].."|r";
		info.func = function() SetDungeonDifficultyID(1) end
		info.checked = function() if GetDungeonDifficultyID() == 1 then return true end return false end
		local inParty = false;
		if (UnitExists("party1") or GetNumGroupMembers() > 0) then
			inParty = true;
		end
		local isLeader = false;
		if (UnitIsGroupLeader("player")) then
			isLeader = true;
		end
		local inInstance = IsInInstance()
		local playerlevel = UnitLevel("player")
		if inInstance or (inParty == 1 and isLeader == 0) or (playerlevel < 90 and GetDungeonDifficultyID() == 1) then
			info.disabled = true
		else
			info.disabled = false
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {}
		info.text = _G["ORANGE_FONT_COLOR_CODE"].._G["PLAYER_DIFFICULTY2"].."|r";
		info.func = function() SetDungeonDifficultyID(2) end
		info.checked = function() if GetDungeonDifficultyID() == 2 then return true end return false end
		local inParty = false;
		if (UnitExists("party1") or GetNumGroupMembers() > 0) then
			inParty = true;
		end
		local isLeader = false;
		if (UnitIsGroupLeader("player")) then
			isLeader = true;
		end
		local inInstance = IsInInstance()
		local playerlevel = UnitLevel("player")
		if inInstance or (inParty == 1 and isLeader == 0) or (playerlevel < 100 and GetDungeonDifficultyID() == 2) then
			info.disabled = true
		else
			info.disabled = false
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {}
		info.text = _G["RED_FONT_COLOR_CODE"].._G["PLAYER_DIFFICULTY6"].."|r";
		info.func = function() SetDungeonDifficultyID(23) end
		info.checked = function() if GetDungeonDifficultyID() == 23 then return true end return false end
		local inParty = false;
		if (UnitExists("party1") or GetNumGroupMembers() > 0) then
			inParty = true;
		end
		local isLeader = false;
		if (UnitIsGroupLeader("player")) then
			isLeader = true;
		end
		local inInstance = IsInInstance()
		local playerlevel = UnitLevel("player")
		if inInstance or (inParty == 1 and isLeader == 0) or (playerlevel < 100 and GetDungeonDifficultyID() == 23) then
			info.disabled = true
		else
			info.disabled = false
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {}
		info.text = _G["RED_FONT_COLOR_CODE"].._G["PLAYER_DIFFICULTY5"].."|r";
		info.func = function() SetDungeonDifficultyID(8) end
		info.checked = function() if GetDungeonDifficultyID() == 8 then return true end return false end
		local inParty = false;
		if (UnitExists("party1") or GetNumGroupMembers() > 0) then
			inParty = true;
		end
		local isLeader = false;
		if (UnitIsGroupLeader("player")) then
			isLeader = true;
		end
		local inInstance = IsInInstance()
		local playerlevel = UnitLevel("player")
		if inInstance or (inParty == 1 and isLeader == 0) or (playerlevel < 100 and GetDungeonDifficultyID() == 8) then
			info.disabled = true
		else
			info.disabled = false
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());


	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 2  and TitanPanelRightClickMenu_GetDropdMenuValue() == "SetRaidDiff" then
		info = {};
		info.text = _G["GREEN_FONT_COLOR_CODE"].._G["PLAYER_DIFFICULTY1"].."|r";
		info.func = function() SetRaidDifficultyID(1) end
		info.checked = function() if GetRaidDifficultyID() == 14 then return true end return false end
		local inParty = 0;
		if (UnitExists("party1") or GetNumGroupMembers() > 0) then
			inParty = 1;
		end
		local isLeader = 0;
		if (UnitIsGroupLeader("player")) then
			isLeader = 1;
		end
		local inInstance = IsInInstance()
		local playerlevel = UnitLevel("player")
		if inInstance or (inParty == 1 and isLeader == 0) or (playerlevel < 65 and GetRaidDifficultyID() == 14) then
			info.disabled = 1
		else
			info.disabled = false
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = _G["ORANGE_FONT_COLOR_CODE"].._G["PLAYER_DIFFICULTY2"].."|r";
		info.func = function() SetRaidDifficultyID(2) end
		info.checked = function() if GetRaidDifficultyID() == 15 then return true end return false end
		local inParty = 0;
		if (UnitExists("party1") or GetNumGroupMembers() > 0) then
			inParty = 1;
		end
		local isLeader = 0;
		if (UnitIsGroupLeader("player")) then
			isLeader = 1;
		end
		local inInstance = IsInInstance()
		local playerlevel = UnitLevel("player")
		if inInstance or (inParty == 1 and isLeader == 0) or (playerlevel < 65 and GetRaidDifficultyID() == 15) then
			info.disabled = 1
		else
			info.disabled = false
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = _G["RED_FONT_COLOR_CODE"].._G["PLAYER_DIFFICULTY6"].."|r";
		info.func = function() SetRaidDifficultyID(3) end
		info.checked = function() if GetRaidDifficultyID() == 16 then return true end return false end
		local inParty = 0;
		if (UnitExists("party1") or GetNumGroupMembers() > 0) then
			inParty = 1;
		end
		local isLeader = 0;
		if (UnitIsGroupLeader("player")) then
			isLeader = 1;
		end
		local inInstance = IsInInstance()
		local playerlevel = UnitLevel("player")
		if inInstance or (inParty == 1 and isLeader == 0) or (playerlevel < 65 and GetRaidDifficultyID() == 16) then
			info.disabled = 1
		else
			info.disabled = false
		end
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());


	else
		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_LOOTTYPE_ID].menuText);
		info = {};
		info.notCheckable = true
		info.text = L["TITAN_LOOTTYPE_SHOWDUNGEONDIFF_LABEL"]
		info.value = "ShowDungeonDiffMenu"
		info.func = function() TitanPanelRightClickMenu_ToggleVar({TITAN_LOOTTYPE_ID, "ShowDungeonDiff"}) end
		info.checked = TitanGetVar(TITAN_LOOTTYPE_ID, "ShowDungeonDiff");
		info.keepShownOnClick = 1;
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {}
		info.notCheckable = true
		info.text = L["TITAN_LOOTTYPE_SETDUNGEONDIFF_LABEL"];
		info.value = "SetDungeonDiff";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {}
		info.notCheckable = true
		info.text = L["TITAN_LOOTTYPE_SETRAIDDIFF_LABEL"];
		info.value = "SetRaidDiff";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		TitanPanelRightClickMenu_AddSpacer();
		info = {};
		info.text = SHOW.." "..(LOOT_METHOD or "Loot Type")
		info.func = function() TitanPanelRightClickMenu_ToggleVar({TITAN_LOOTTYPE_ID, "ShowLootType"}) end
		info.checked = TitanGetVar(TITAN_LOOTTYPE_ID, "ShowLootType")
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.text = SHOW.." "..(SPECIALIZATION or "Spec")
		info.func = function() TitanPanelRightClickMenu_ToggleVar({TITAN_LOOTTYPE_ID, "ShowLootSpec"}) end
		info.checked = TitanGetVar(TITAN_LOOTTYPE_ID, "ShowLootSpec")
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		TitanPanelRightClickMenu_AddSpacer();
		info = {};
		info.notCheckable = true
		info.text = L["TITAN_LOOTTYPE_RANDOM_ROLL_LABEL"];
		info.value = "RandomRoll";
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		
		TitanPanelRightClickMenu_AddControlVars(TITAN_LOOTTYPE_ID)
	end
end

--[[
-- **************************************************************************
-- NAME : TitanPanelBagButton_OnClick(button)
-- DESC : Generate random roll on leftclick of button
-- **************************************************************************
--]]
function TitanPanelLootTypeButton_OnClick(self, button)
	if button == "LeftButton" then
		RandomRoll(1, TitanGetVar(TITAN_LOOTTYPE_ID, "RandomRoll"));
	end
end


-- ====== Create needed frames
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
	TitanPanelLootTypeButton_OnLoad(window);
--	TitanPanelButton_OnLoad(window); -- Titan XML template calls this...
	
	window:SetScript("OnEvent", function(self, event, ...)
		TitanPanelLootTypeButton_OnEvent(self, event, ...) 
	end)
	window:SetScript("OnClick", function(self, button)
		TitanPanelLootTypeButton_OnClick(self, button);
		TitanPanelButton_OnClick(self, button);
	end)
end


Create_Frames() -- do the work
