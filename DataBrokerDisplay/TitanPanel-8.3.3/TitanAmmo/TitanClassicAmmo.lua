--[[
-- **************************************************************************
-- * TitanAmmo.lua
-- *
-- * By: Titan Panel Development Team
-- **************************************************************************
-- 2024 Jan - Combined Classic Era and Wrath into one version
-- 2019 Aug - reverted and updated for Classic
--
-- This will track the count of ammo (bows and guns) or thrown (knives) equipped. 
-- Ammo is placed in the 'ammo' slot where Blizzard counts ALL of that *type of ammo*
-- regardless of where it is in your bags.
-- Thrown is placed in the actual display.weapon slot where Blizzard counts ALL of that *type of thrown*.
-- This forces a different routine to be used so the ammo must always be checked for type and count.
--
-- Note: Thrown has no durability. Not sure when Blizz implemented this
--]]
-- ******************************** Constants *******************************
local _G = getfenv(0);
local TITAN_AMMO_ID = "Ammo";
local TITAN_BUTTON = "TitanPanel"..TITAN_AMMO_ID.."Button"

local SHOOT_STACK = 200
local ARROW_STACK = 200
local THROW_STACK = 200

local LIM_GOOD = 2
local LIM_OK   = 1.5
local LIM_BAD  = .5

local game_version = select(4, GetBuildInfo())

local TITAN_AMMO_THRESHOLD_TABLE = { -- Use ammo stack and threshold limits above to calc colored text
	["INVTYPE_RANGEDRIGHT"] = {
		 Values = { SHOOT_STACK*LIM_BAD, SHOOT_STACK*LIM_OK, SHOOT_STACK*LIM_GOOD }, -- 100,150,400
		 Colors = { RED_FONT_COLOR, ORANGE_FONT_COLOR, NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR },
	 },
	["INVTYPE_RANGED"] = {
		 Values = { ARROW_STACK*LIM_BAD, ARROW_STACK*LIM_OK, ARROW_STACK*LIM_GOOD }, -- 100,150,400
		 Colors = { RED_FONT_COLOR, ORANGE_FONT_COLOR, NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR },
	 },
	["INVTYPE_THROWN"] = {
		 Values = { THROW_STACK/10, THROW_STACK/4, THROW_STACK/2 }, -- 20, 50, 100
		 Colors = { RED_FONT_COLOR, ORANGE_FONT_COLOR, NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR },
	 },
};

-- ******************************** Variables *******************************
local ammoSlotID = GetInventorySlotInfo("AMMOSLOT")
local rangedSlotID = GetInventorySlotInfo("RANGEDSLOT")

-- Info to show on the plugin
local display = {
	ammo_count  = 0,
	ammo_type   = "",
	ammo_name   = "", -- L["TITAN_AMMO_BUTTON_NOAMMO"]
	weapon      = "",
	weapon_type = "",
	mismatch    = false,
	mismatch_text = "",
	}

local L = LibStub("AceLocale-3.0"):GetLocale("Titan", true)

local debug_flow = false

---@diagnostic disable-next-line: deprecated
local GetItem = C_Item.GetItemInfo or GetItemInfo -- For Classic versions

-- ******************************** Functions *******************************
--[[ local
-- **************************************************************************
-- NAME : debug_msg(Message)
-- DESC : Debug function to print message to chat frame
-- VARS : Message = message to print to chat frame
-- **************************************************************************
--]]
local function debug_msg(Message)
	local msg = ""
	local stamp = date("%H:%M:%S") -- date("%m/%d/%y %H:%M:%S")
	local milli = GetTime() -- seconds with millisecond precision (float)
	local milli_str = string.format("%0.2F", milli - math.modf(milli))
	msg = msg..TitanUtils_GetGoldText(stamp..milli_str.." "..TITAN_AMMO_ID..": ")
	msg = msg..TitanUtils_GetGreenText(Message)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
--		DEFAULT_CHAT_FRAME:AddMessage(TITAN_AMMO_ID..": " .. Message, 1.00, 0.49, 0.04)
end

local function ClrAmmoInfo()
	display.ammo_count = 0;
	display.ammo_type  = L["TITAN_AMMO_BUTTON_NOAMMO"]
	display.ammo_name  = "" 
	display.weapon = ""
	display.weapon_type = ""
	display.mismatch = false
	display.mismatch_text = ""
end

local function GetItemLink(rangedSlotID)
	return GetInventoryItemLink("player", rangedSlotID)
end

local function IsAmmoClass()
	local class = select(2, UnitClass("player"))
	local res = false
	if class == "ROGUE" 
	or class == "WARRIOR" 
	or class == "HUNTER" 
	then
		res = true
	else
		res = false
	end
	return res
end

local function GetAmmoCount()
	local ammo = ""
	local mis = false
	local mist = ""
	local ammo_name = ""
	local ammo_count = 0
	local label = ""
	local text = ""
	local tool_tip = ""
	
	ClrAmmoInfo()
	-- weapon info
	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
	itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent
	-- ammo info
	local ammoName, ammoLink, ammoQuality, ammoLevel, ammoMinLevel, ammoType, ammoSubType, ammoStackCount,
	ammoEquipLoc, ammoTexture, _, ammoID, subammoID

	local weap = GetInventoryItemID("player", rangedSlotID)
	if weap == nil then
		-- nothing in slot
		ammo = L["TITAN_AMMO_BUTTON_NOAMMO"]
	else
		-- get weapon info (thrown) or ammo info (guns & bows)
		itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
		itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent
		   = GetItem(weap)
		ammo = itemEquipLoc
		
		-- set ammo name and count
		if (subclassID == 16) -- Thrown
		then
			-- treat thrown as ther ammo with 0 count
			ammo_name = itemName or ""
			ammo_count = 0
			
			ammoID = classID
			subammoID = subclassID
			
			label = L["TITAN_AMMO_BUTTON_LABEL_THROWN"]
			
			ammo_name = select(1, GetItem(GetInventoryItemID("player", rangedSlotID))) or _G["UNKNOWN"]
			if ammo_name == _G["UNKNOWN"] then
				ammo_count = 0
			else
				if game_version < 30000 then
					-- CE thrown has count
					ammo_count = GetInventoryItemCount("player", rangedSlotID) or ammo_count
					text = format(L["TITAN_AMMO_FORMAT"], ammo_count);
				else
					-- Wrath thrown has no count or durability
					text = TitanUtils_GetGoldText("*")
				end
			end
			if TitanGetVar(TITAN_AMMO_ID, "ShowAmmoName") and ammo_name ~= "" then
				text = text.."|cffffff9a".." ("..ammo_name..")".."|r"
			end
			tool_tip = itemName
			-- no mismatch
		elseif (subclassID == 3)  -- Gun
			or (subclassID == 2)  -- Bow
			or (subclassID == 18) -- Crossbow
		then
			ammoName, ammoLink, ammoQuality, ammoLevel, ammoMinLevel, ammoType, ammoSubType, ammoStackCount,
			ammoEquipLoc, ammoTexture, _, ammoID, subammoID, _, _, _, _
			   = GetItem(GetInventoryItemID("player", ammoSlotID))
--			ammo_name = select(1, GetItemInfo(GetInventoryItemID("player", ammoSlotID))) or UNKNOWN
			ammo_name = ammoName or ""
			if ammoName == nil then
				ammo_count = 0
			else
				ammo_count = GetInventoryItemCount("player", ammoSlotID) or display.ammo_count
			end
			text = format(L["TITAN_AMMO_FORMAT"], ammo_count);
			if TitanGetVar(TITAN_AMMO_ID, "ShowAmmoName") and ammo_name ~= "" then
				text = text.."|cffffff9a".." ("..ammo_name..")".."|r"
			end
			label = L["TITAN_AMMO_BUTTON_LABEL_AMMO"]
			tool_tip = ""
				..tostring(itemName)
				.."\n"..tostring(ammo_name)..""

			
			-- check for mismatch
			if (subclassID == 3) -- Bullet
			and (subammoID == 2) -- Arrow
			then
				mis = true
				mist = ""
					..tostring(itemName)
					.." <> "
					..tostring(ammoName)
				mist = TitanUtils_GetRedText(mist)
			elseif ((subclassID == 2) -- Bow
			or (subclassID == 18)) -- Crossbow
			and (subammoID == 3) -- Bullets
			then
				mis = true
				mist = ""
					..tostring(itemName)
					.." <> "
					..tostring(ammoName)
				mist = TitanUtils_GetRedText(mist)
			else
			end
		else
			ammo_name = UNKNOWN
			ammo_count = 0
			
			-- no mismatch
		end
--[[
local msg = 
	"GII-ammo"
	.." ("..tostring(itemType)..""
	.." "..tostring(classID)..""
	.." "..tostring(subclassID) ..")"
	.." ? ("..tostring(ammoID)..""
	.." "..tostring(subammoID)..")"
	.." "..tostring(mis)..""
debug_msg(msg)
local msg = 
	"GII-ammo > "
	.." '"..tostring(label).."'"
	.." '"..tostring(text).."'"
debug_msg(msg)
--]]
	end

	-- Set variables
	display.label = label
	display.text = text
	display.tool_tip = tool_tip
	display.weapon = itemName
	display.weapon_type = itemSubType
	display.ammo_name = ammo_name
	display.ammo_count = ammo_count
	display.ammo_type = ammo
	display.ammo_type_id = subclassID
	display.mismatch = mis
	display.mismatch_text = mist

	if debug_flow then
		local msg = 
			"Count"
			.." '"..tostring(itemSubType).."'"
			.." '"..tostring(itemName).."'"
		debug_msg(msg)
	else
		-- not requested
	end
end

local function Events(action, reason)
--[[
- Thrown has no durability so do not register for that event
- Remove ACTIONBAR_HIDEGRID; this is triggered when dragging an item to actionbar
  Not sure why this was implemented - use of event changed?
--]]
	if action == "register" then
		TitanPanelAmmoButton:RegisterEvent("UNIT_INVENTORY_CHANGED")
		TitanPanelAmmoButton:RegisterEvent("MERCHANT_CLOSED")
	elseif action == "unregister" then
		TitanPanelAmmoButton:UnregisterEvent("UNIT_INVENTORY_CHANGED")
		TitanPanelAmmoButton:UnregisterEvent("MERCHANT_CLOSED")
	else
		-- action unknown ???
	end

	if debug_flow then
		local msg = 
			"Events"
			.." "..tostring(reason)..""
		debug_msg(msg)
	else
		-- not requested
	end
end

--[[
-- **************************************************************************
-- NAME : GetButtonText(id)
-- DESC : Calculate ammo/thrown logic then put on button
-- VARS : id = button ID
-- **************************************************************************
--]]
function GetButtonText(id)
     
	local labelText, ammoText, ammoRichText, color;

	labelText = display.label
	ammoText = display.text or "-"

	if display.mismatch then
		ammoRichText = tostring(display.mismatch_text)
	elseif (TitanGetVar(TITAN_AMMO_ID, "ShowColoredText")) then     
		color = TitanUtils_GetThresholdColor(TITAN_AMMO_THRESHOLD_TABLE[display.ammo_type], display.ammo_count);
		ammoRichText = TitanUtils_GetColoredText(ammoText, color);
	else
		ammoRichText = TitanUtils_GetHighlightText(ammoText);
	end

	if debug_flow then
		local msg = 
			"Btn_Text"
			.." '"..tostring(display.weapon_type).."'"
			.." '"..tostring(ammoRichText).."'"
		debug_msg(msg)
	else
		-- not requested
	end

	return labelText, ammoRichText;
end

--[[
-- **************************************************************************
-- NAME : CreateMenu()
-- DESC : Display rightclick menu options
-- **************************************************************************
--]]
function CreateMenu()
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_AMMO_ID].menuText);

	local info = {};
	info.text = L["TITAN_AMMO_BULLET_NAME"];
	info.func = function() TitanPanelRightClickMenu_ToggleVar({TITAN_AMMO_ID, "ShowAmmoName"})
		GetAmmoCount()
		TitanPanelButton_UpdateButton(TITAN_AMMO_ID);
	end
	info.checked = TitanUtils_Ternary(TitanGetVar(TITAN_AMMO_ID, "ShowAmmoName"), 1, nil);
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel())
	TitanPanelRightClickMenu_AddSpacer();

	info = {};
	TitanPanelRightClickMenu_AddToggleIcon(TITAN_AMMO_ID);
	TitanPanelRightClickMenu_AddToggleLabelText(TITAN_AMMO_ID);
	TitanPanelRightClickMenu_AddToggleColoredText(TITAN_AMMO_ID);

	TitanPanelRightClickMenu_AddToggleRightSide(TITAN_AMMO_ID);
	TitanPanelRightClickMenu_AddSpacer();
	TitanPanelRightClickMenu_AddCommand(L["TITAN_PANEL_MENU_HIDE"], TITAN_AMMO_ID, TITAN_PANEL_MENU_FUNC_HIDE);
end

function GetTooltipText()
	local txt = display.tool_tip
	if display.mismatch then
		txt = txt
			.."\n\n"
			..tostring(display.mismatch_text)..""
	else
		-- weapon and projectile match
	end
	return txt
end

--[[
-- **************************************************************************
-- NAME : TitanPanelAmmoButton_OnLoad()
-- DESC : Registers the plugin upon it loading
-- **************************************************************************
--]]
local function OnLoad(self)
	self.registry = {
		id = TITAN_AMMO_ID,
		--builtIn = 1,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = L["TITAN_AMMO_MENU_TEXT"],
		menuTextFunction = CreateMenu,
		buttonTextFunction = GetButtonText, 
		tooltipTitle = L["TITAN_AMMO_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		icon = "Interface\\AddOns\\TitanAmmo\\TitanClassicThrown",
		iconWidth = 16,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = true,
			DisplayOnRightSide = true
		},
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowColoredText = 1,
			ShowAmmoName = false,
			DisplayOnRightSide = false,
		}
	}
end

local function OnShow(self)
	ClrAmmoInfo()

	if IsAmmoClass() then
		-- No need to start events and consume cycles if no ammo
		GetAmmoCount()

		Events("register", "OnShow")
	else
		-- Just set the default text on button
		-- for a class w/o ammo
	end

	TitanPanelButton_UpdateButton(TITAN_AMMO_ID);
end

local function OnHide(self)
	ClrAmmoInfo()

	Events("unregister", "OnHide")
end

local function UpdateDisplay()
	GetAmmoCount()
	
	TitanPanelButton_UpdateButton(TITAN_AMMO_ID);
end

--[[
-- **************************************************************************
-- NAME : TitanPanelAmmoButton_OnEvent()
-- DESC : React to any registered Events
-- **************************************************************************
--]]
local function OnEvent(self, event, arg1, arg2, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if arg1 == true then -- login
			-- EnterWorld()
		end
		if arg2 == true then -- reload / zoning
			UpdateDisplay()
		end
	elseif event == "UNIT_INVENTORY_CHANGED" then
		if arg1 == "player" then
			UpdateDisplay()
		end
	elseif event == "MERCHANT_CLOSED" then
		UpdateDisplay()
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
	OnLoad(window);
--	TitanPanelButton_OnLoad(window); -- Titan XML template calls this...
	
	window:SetScript("OnEvent", function(self, event, ...)
		OnEvent(self, event, ...) 
	end)
	window:SetScript("OnShow", function(self, button)
		OnShow(self)
	end)
	window:SetScript("OnHide", function(self, button)
		OnHide(self)
	end)

end

Create_Frames() -- do the work
