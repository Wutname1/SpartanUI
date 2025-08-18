---@diagnostic disable: duplicate-set-field
-- **************************************************************************
-- * TitanBag.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************

-- ******************************** Constants *******************************
local _G = getfenv(0);
local TITAN_BAG_ID = "Bag";
local TITAN_BUTTON = "TitanPanel" .. TITAN_BAG_ID .. "Button"

local TITAN_BAG_THRESHOLD_TABLE = {
	Values = { 0.5, 0.75, 0.9 },
	Colors = { HIGHLIGHT_FONT_COLOR, NORMAL_FONT_COLOR, ORANGE_FONT_COLOR, RED_FONT_COLOR },
}
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
--local updateTable = {TITAN_BAG_ID, TITAN_PANEL_UPDATE_BUTTON};

-- ******************************** Variables *******************************
--local AceTimer = LibStub("AceTimer-3.0")

local trace = false

local MIN_BAGS = 0
local MAX_BAGS = 0
local bag_data = {} -- to hold the user bag data

-- ******************************** Functions *******************************

-- Set so Retail and Classic can run
---@diagnostic disable-next-line: deprecated
local GetItemNow = C_Item.GetItemInfoInstant or GetItemInfoInstant

---Determine if this is a profession bag using only instant data rather than calling server
---@param slot number
---@return boolean
local function IsProfessionBagID(slot)
	-- The info needed is available using GetItemInfoInstant; only the bag slot or item id is required.
	-- A LOT of info is available but we only need class and subclass here.
	-- itemType : warcraft.wiki.gg/wiki/itemType
	local res = false
	local info, itemId, itemType, itemSubType, itemEquipLoc, itemTexture, classID, subclassID
	local inv_id = C_Container.ContainerIDToInventoryID(slot)

	if inv_id == nil then
		-- Only works on bag and bank bags NOT backpack!
		-- However the backpack is never a profession bag.
	else
		info = GetInventoryItemLink("player", inv_id)
		if info == nil then
			-- Slot likely empty, no need to process.
		else
			itemId, itemType, itemSubType, itemEquipLoc, itemTexture, classID, subclassID = GetItemNow(info)
			if classID == 1 then -- is a container / bag
				if subclassID >= 1 then
					-- profession bag of some type [2 - 10] Jan 2024 (DragonFlight / Wrath / Classic Era)
					-- OR soul bag [1]
					res = true
				else
					-- is a arrow or bullet bag; only two options
				end
			elseif classID == 6 then -- is a 'projectile' holder
				res = true
				-- is a ammo bag or quiver; only two options
			elseif classID == 11 then -- is a 'quiver'; Wrath and CE
				res = true
				-- is a ammo pouch or quiver; only two options
				-- style = subclassID + 20 -- change to get local color for name
			else
				-- not a profession bag
			end
		end
	end

	return res
end

---Tell the UI to open / close the bags
local function ToggleBags()
	if TitanGetVar(TITAN_BAG_ID, "OpenBags") then
		ToggleAllBags()
	else
		-- User has not enabled open on click
	end
end

---Collect bag info - name, slots (total, used, free), name (if available).
--- The bag name is not always available when player entering world but the required info is.
---@param id string Plugin ID
local function GetBagData(id)
	--[[
	The bag name is not always available when player entering world.
	The user may see bag name as <unknown> until an event triggers a bag check AND the name is available.
	Grabbing the total slots is available on client to determine if a bag exists and get its free / used counts.
	--]]
	-- 2024 Jan : Moved away from named based to id based. Allows name to come later from server
	-- 2024 Aug : Removed coloring of bag name to focus on counts which is the real info.

	if trace then
		TitanPluginDebug(TITAN_BAG_ID, "T GetBagData"
			.. " '" .. tostring(id) .. "'"
		)
	end
	local total_slots = 0
	local total_free = 0
	local total_used = 0
	local is_prof_bag = false
	-- calculated but not used ATM
	local prof_slots = 0
	local prof_free = 0
	local prof_used = 0

	for bag_slot = MIN_BAGS, MAX_BAGS do -- assuming 0 (Backpack) will not be a profession bag
		-- Ensure a blank structure exists.
		-- Blanking data may seem overkill but it allows the plugin to react to events without
		-- caring when they occur and it will set the bag name when it arrives AND an event occurs.
		bag_data[bag_slot] = {
			has_bag = false,
			name = "",
			max_slots = 0,
			free_slots = 0,
			used_slots = 0,
			style = "",
			color = "",
		}

		local slots = C_Container.GetContainerNumSlots(bag_slot)

		-- Check type here to set slot style properly.
		-- Profession bags are NOT included in overall free / used counts
		local bag_type = "none"
		is_prof_bag = IsProfessionBagID(bag_slot)

		-- Blizz treats 'last' slot as a reagent only slot...
		-- For our purpose, treat it as a profession bag.
		if is_prof_bag or bag_slot == 5 then
			bag_type = "profession"
		else
			bag_type = "normal"
		end
		bag_data[bag_slot].style = bag_type

		if slots > 0 then
			bag_data[bag_slot].has_bag = true

			local bag_name = (C_Container.GetBagName(bag_slot) or UNKNOWN)
			bag_data[bag_slot].name = bag_name
			bag_data[bag_slot].max_slots = slots

			local free = C_Container.GetContainerNumFreeSlots(bag_slot)
			local used = slots - free
			bag_data[bag_slot].free_slots = free
			bag_data[bag_slot].used_slots = used


			-- add to total
			if bag_data[bag_slot].style == "profession" then
				prof_slots = prof_slots + slots
				prof_free = prof_free + free
				prof_used = prof_used + used
			else
				total_slots = total_slots + slots
				total_free = total_free + free
				total_used = total_used + used
			end
		else
			bag_data[bag_slot].has_bag = false
			bag_data[bag_slot].name = NONE
		end

		if trace then
			TitanPluginDebug(TITAN_BAG_ID, "...T GetBagData"
				.. " " .. tostring(bag_slot) .. ""
				.. " ?:" .. tostring(bag_data[bag_slot].has_bag) .. ""
				.. " max: " .. tostring(bag_data[bag_slot].max_slots) .. ""
				.. " used: " .. tostring(bag_data[bag_slot].used_slots) .. ""
				.. " free: " .. tostring(bag_data[bag_slot].free_slots) .. ""
				.. " type: " .. tostring(bag_data[bag_slot].style) .. ""
				.. " prof: " .. tostring(is_prof_bag) .. ""
				.. " '" .. tostring(bag_data[bag_slot].name) .. "'"
			)
		end
	end

	-- Normal bags
	bag_data.total_slots = total_slots
	bag_data.total_free = total_free
	bag_data.total_used = total_used

	-- Profession / reagent bags
	bag_data.prof_slots = prof_slots
	bag_data.prof_free = prof_free
	bag_data.prof_used = prof_used
end

---plugin Handle registered events
---@param self Button
---@param event string
---@param ... any
local function OnEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		-- Leave in case future code is needed...
	elseif event == "BAG_UPDATE" then
		-- update the plugin text
		TitanPanelButton_UpdateButton(TITAN_BAG_ID);
	elseif event == "BAG_CONTAINER_UPDATE" then
		-- 2024 Aug : Added as additional check if user swaps bags; may not be required
		-- update the plugin text
		TitanPanelButton_UpdateButton(TITAN_BAG_ID);
	end

	if trace then
		TitanPluginDebug(TITAN_BAG_ID, "_OnEvent"
			.. " " .. tostring(event) .. ""
		)
	end
end

---Opens all bags on a LeftClick
---@param self Button
---@param button string
local function OnClick(self, button)
	if (button == "LeftButton") then
		ToggleBags();
	end
end

---Generate the plugin button text
---@param id string
---@return string
---@return string
local function GetButtonText(id)
	GetBagData(id)

	local bagText = ""
	if TitanGetVar(TITAN_BAG_ID, "ShowUsedSlots") then
		bagText = format(L["TITAN_BAG_FORMAT"], bag_data.total_used, bag_data.total_slots);
	else
		bagText = format(L["TITAN_BAG_FORMAT"], bag_data.total_free, bag_data.total_slots);
	end

	local bagRichText = ""
	if (TitanGetVar(TITAN_BAG_ID, "ShowColoredText")) then
		local color = ""
		color = TitanUtils_GetThresholdColor(TITAN_BAG_THRESHOLD_TABLE, bag_data.total_used / bag_data.total_slots);
		bagRichText = TitanUtils_GetColoredText(bagText, color);
	else
		bagRichText = TitanUtils_GetHighlightText(bagText);
	end

	bagRichText = bagRichText
	--..bagRichTextProf[1]..bagRichTextProf[2]..bagRichTextProf[3]..bagRichTextProf[4]..bagRichTextProf[5];

	if trace then
		TitanPluginDebug(TITAN_BAG_ID, "T GetBagData"
			.. " '" .. tostring(bagRichText) .. "'"
		)
	end
	return L["TITAN_BAG_BUTTON_LABEL"], bagRichText
end

---Determine the color based on percentage
---@param text string
---@param show_color boolean
---@param numerator number
---@param denom number
---@return string
local function ThresholdColor(text, show_color, numerator, denom)
	local res = ""
	local color = ""
	if show_color then
		if denom == 0 then
			color = TitanUtils_GetThresholdColor(TITAN_BAG_THRESHOLD_TABLE, 1);
		else
			color = TitanUtils_GetThresholdColor(TITAN_BAG_THRESHOLD_TABLE, numerator / denom);
		end
		res = TitanUtils_GetColoredText(text, color);
	else
		-- use without color
		res = TitanUtils_GetHighlightText(text);
	end

	return res
end

---Generate tooltip text
---@return string
local function GetTooltipText()
	-- Normal shows free / used of total per user options.
	-- Detailed shows list bags with profession bag counts in gray - not counted.
	-- Hint shows if user selects open bags on left click.
	--#region-- 2024 Aug (8.1.0) : With the addition of new 'reagent' slot, we dropped coloring & counting profession bags.
	local returnstring = "";
	local show_color = TitanGetVar(TITAN_BAG_ID, "ShowColoredText")

	-- Collect names and x / y numbers, color numbers if user requested
	if TitanGetVar(TITAN_BAG_ID, "ShowDetailedInfo") then
		returnstring = "\n";
		if TitanGetVar(TITAN_BAG_ID, "ShowUsedSlots") then
			returnstring = returnstring .. TitanUtils_GetNormalText(L["TITAN_BAG_MENU_TEXT"])
				.. ":\t" .. TitanUtils_GetNormalText(L["TITAN_BAG_USED_SLOTS"]) .. ":\n";
		else
			returnstring = returnstring .. TitanUtils_GetNormalText(L["TITAN_BAG_MENU_TEXT"])
				.. ":\t" .. TitanUtils_GetNormalText(L["TITAN_BAG_FREE_SLOTS"]) .. ":\n";
		end

		for bag = MIN_BAGS, MAX_BAGS do
			local bagText = ""
			local bagRichText

			if bag_data[bag] then
				if bag_data[bag].has_bag then
					-- Format the x / y slots per user options
					if (TitanGetVar(TITAN_BAG_ID, "ShowUsedSlots")) then
						bagText = format(L["TITAN_BAG_FORMAT"], bag_data[bag].used_slots, bag_data[bag].max_slots);
					else
						bagText = format(L["TITAN_BAG_FORMAT"], bag_data[bag].free_slots, bag_data[bag].max_slots);
					end
					-- Format x / y per user options
					if bag_data[bag].style == "profession" then
						bagRichText = TitanUtils_GetGrayText(bagText)
					else
						bagRichText = ThresholdColor(bagText, show_color, bag_data[bag].used_slots, bag_data[bag].max_slots)
					end
				else
					bagRichText = ""
				end
				-- Format bag name as 'normal' 2024 Aug 
				local name_text = TitanUtils_GetNormalText(bag_data[bag].name)
				returnstring = returnstring .. name_text .. "\t" .. bagRichText .. "\n";
			else
				--Silent error - should never get here...
			end
		end
		returnstring = returnstring .. "------\t" .. "---\n";
	end

	-- Always show free / used of max slots to user
	local xofy = ""
	local slots = ""
	if TitanGetVar(TITAN_BAG_ID, "ShowUsedSlots") then
		xofy = "" .. tostring(bag_data.total_used) .. "/" .. tostring(bag_data.total_slots)
		xofy = ThresholdColor(xofy, show_color, bag_data.total_used, bag_data.total_slots)
		slots = L["TITAN_BAG_USED_SLOTS"]
	else
		xofy = "" .. tostring(bag_data.total_free) .. "/" .. tostring(bag_data.total_slots)
		xofy = ThresholdColor(xofy, show_color, bag_data.total_free, bag_data.total_slots)
		slots = L["TITAN_BAG_FREE_SLOTS"]
	end
	returnstring = returnstring .. TitanUtils_GetNormalText(slots) .. ":\t" .. xofy .. "\n"

	-- Add Hint if user wants to open bags on left click.
	if TitanGetVar(TITAN_BAG_ID, "OpenBags") then
		returnstring = returnstring .. "\n" .. TitanUtils_GetGreenText(L["TITAN_BAG_TOOLTIP_HINTS"])
	else
		-- nop
	end
	return returnstring
end

---Generate and display rightclick menu options for user.
local function PrepareBagMenu()
	local info
	-- level 1
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_BAG_ID].menuText);

	info = {};
	info.text = L["TITAN_BAG_MENU_SHOW_USED_SLOTS"];
	info.func = function()
		TitanSetVar(TITAN_BAG_ID, "ShowUsedSlots", 1);
		TitanPanelButton_UpdateButton(TITAN_BAG_ID);
		end
	info.checked = TitanGetVar(TITAN_BAG_ID, "ShowUsedSlots");
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_BAG_MENU_SHOW_AVAILABLE_SLOTS"];
	info.func = function()
		TitanSetVar(TITAN_BAG_ID, "ShowUsedSlots", nil);
		TitanPanelButton_UpdateButton(TITAN_BAG_ID);
		end
	info.checked = TitanUtils_Toggle(TitanGetVar(TITAN_BAG_ID, "ShowUsedSlots"));
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_BAG_MENU_SHOW_DETAILED"];
	info.func = function()
		TitanToggleVar(TITAN_BAG_ID, "ShowDetailedInfo");
	end
	info.checked = TitanGetVar(TITAN_BAG_ID, "ShowDetailedInfo");
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.text = L["TITAN_BAG_MENU_OPEN_BAGS"]
	info.func = function()
		TitanToggleVar(TITAN_BAG_ID, "OpenBags")
	end
	info.checked = TitanGetVar(TITAN_BAG_ID, "OpenBags");
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSpacer();

	TitanPanelRightClickMenu_AddControlVars(TITAN_BAG_ID)
end

---plugin Registers the plugin and simple init
---@param self Button
local function OnLoad(self)
	local notes = ""
		.. "Adds bag and free slot information to Titan Panel.\n"
		.. "- Open bags should work... Retail taint fixed Apr 2024 (10.2.7).\n"
		.. "- Professions counts moved to tooltip only : Aug 2024 (Titan 8.1.0).\n"
	self.registry = {
		id = TITAN_BAG_ID,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = L["TITAN_BAG_MENU_TEXT"],
		menuTextFunction = PrepareBagMenu,
		buttonTextFunction = GetButtonText,
		tooltipTitle = L["TITAN_BAG_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		icon = "Interface\\AddOns\\TitanBag\\TitanBag",
		iconWidth = 16,
		notes = notes,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowColoredText = true,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowUsedSlots = 1,
			ShowDetailedInfo = false,
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowColoredText = 1,
			DisplayOnRightSide = false,
			OpenBags = true,
		}
	};

	-- As of Apr 2024 (10.2.7) the taint on opening bags in Retail is fixed.

	-- Reagent bag slot added end of DragonFlight for War Within expansion.
	if NUM_TOTAL_EQUIPPED_BAG_SLOTS == nil then -- NOT Retail as of DragonFlight WHY BLIZZ!?
		MAX_BAGS = Constants.InventoryConstants.NumBagSlots
	else                                     -- Classic API
		MAX_BAGS = NUM_TOTAL_EQUIPPED_BAG_SLOTS
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD");
end

---Prep and update plugin button here to minimize resources.
---@param self Button
local function OnShow(self)
	-- Register for bag updates and update the plugin text
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_CONTAINER_UPDATE")
	TitanPanelButton_UpdateButton(TITAN_BAG_ID);
end

---Shutdown plugin button here to minimize resources.
---@param self Button
local function OnHide(self)
	self:UnregisterEvent("BAG_UPDATE")
	self:UnregisterEvent("BAG_CONTAINER_UPDATE")
end

---Create needed plugin frames
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
		OnHide(self)
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

--[[
TitanDebug("T isP 0:"
	.." "..tostring(slot)..""
	.." "..tostring(itemId)..""
	.." '"..tostring(itemType).."'"
	.." '"..tostring(itemSubType).."'"
	.." "..tostring(itemEquipLoc)..""
	.." '"..tostring(itemTexture).."'"
	.." "..tostring(classID)..""
	.." "..tostring(subclassID)..""
	)
--]]
