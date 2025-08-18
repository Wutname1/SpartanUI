---@diagnostic disable: duplicate-set-field
--[[
-- **************************************************************************
-- * TitanStarter.lua
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************
--]]
-- ******************************** Constants *******************************
local add_on = ...
local _G = _G --getfenv(0);
local artwork_path = "Interface\\AddOns\\TitanPlugin\\Artwork\\"
-- NOTE: The plugin id needs be unique across Titan plugins
-- It does not need to match the addon id.
local TITAN_PLUGIN = "Starter"
-- NOTE: The convention is TitanPanel<id>Button
local TITAN_BUTTON = "TitanPanel" .. TITAN_PLUGIN .. "Button"
local VERSION = C_AddOns.GetAddOnMetadata(add_on, "Version")

local TITAN_BAG_THRESHOLD_TABLE = {
	Values = { 0.5, 0.75, 0.9 },
	Colors = { HIGHLIGHT_FONT_COLOR, NORMAL_FONT_COLOR, ORANGE_FONT_COLOR, RED_FONT_COLOR },
}

-- ******************************** Variables *******************************
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)

local bag_info = {                   -- itemType : warcraft.wiki.gg/wiki/itemType
	[1] =                            -- Soul bag
	{ color = { r = 0.96, g = 0.55, b = 0.73 } }, -- PINK
	[2] =                            -- HERBALISM =
	{ color = { r = 0, g = 1, b = 0 } }, -- GREEN
	[3] =                            -- ENCHANTING =
	{ color = { r = 0, g = 0, b = 1 } }, -- BLUE
	[4] =                            -- ENGINEERING =
	{ color = { r = 1, g = 0.49, b = 0.04 } }, -- ORANGE
	[5] =                            -- JEWELCRAFTING =
	{ color = { r = 1, g = 0, b = 0 } }, -- RED
	[6] =                            -- MINING =
	{ color = { r = 1, g = 1, b = 1 } }, -- WHITE
	[7] =                            -- LEATHERWORKING =
	{ color = { r = 0.78, g = 0.61, b = 0.43 } }, -- TAN
	[8] =                            -- INSCRIPTION =
	{ color = { r = 0.58, g = 0.51, b = 0.79 } }, -- PURPLE
	[9] =                            -- FISHING =
	{ color = { r = 0.41, g = 0.8, b = 0.94 } }, -- LIGHT_BLUE
	[10] =                           -- COOKING =
	{ color = { r = 0.96, g = 0.55, b = 0.73 } }, -- PINK
	-- These are Classic arrow or bullet bags
	[22] =                           -- Classic arrow
	{ color = { r = 1, g = .4, b = 0 } }, -- copper
	[23] =                           -- Classic bullet
	{ color = { r = 0.8, g = 0.8, b = 0.8 } }, -- silver
}

local trace = false -- true / false    Make true when debug output is needed.

local MIN_BAGS = 0
local MAX_BAGS = Constants.InventoryConstants.NumBagSlots
local bag_data = {} -- to hold the user bag data

-- ******************************** Functions *******************************
---@diagnostic disable-next-line: deprecated
local GetInstant = C_Item.GetItemInfoInstant or GetItemInfoInstant

local function IsProfessionBagID(slot)
	-- The info needed is available using GetItemInfoInstant; only the bag / item id is required
	-- itemType : warcraft.wiki.gg/wiki/itemType
	local res = false
	local style = 0
	local info, itemId, itemType, itemSubType, itemEquipLoc, itemTexture, classID, subclassID
	local inv_id = C_Container.ContainerIDToInventoryID(slot)

	if inv_id == nil then
		-- Only works on bag and bank bags NOT backpack!
	else
		info = GetInventoryItemLink("player", inv_id)
		itemId, itemType, itemSubType, itemEquipLoc, itemTexture, classID, subclassID = GetInstant(info)
		style = subclassID

		if classID == 1 then -- is a container / bag
			if subclassID >= 1 then
				-- profession bag of some type [2 - 10] Jan 2024 (DragonFlight / Wrath / Classic Era)
				-- OR soul bag [1]
				res = true
			else
				-- is a arrow or bullet; only two options
			end
		elseif classID == 6 then -- is a 'projectile' holder
			res = true
			-- is a ammo bag or quiver; only two options
		elseif classID == 11 then -- is a 'quiver'; Wrath and CE
			res = true
			-- is a ammo pouch or quiver; only two options
			style = subclassID + 20 -- change to get local color for name
		else
			-- not a bag
		end
	end

	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "T isP:"
			.. " " .. tostring(res) .. ""
			.. " " .. tostring(style) .. ""
			.. " " .. tostring(itemId) .. ""
			.. " " .. tostring(classID) .. ""
			.. " " .. tostring(subclassID) .. ""
			.. " " .. tostring(inv_id) .. ""
		)
	end

	return res, style
end

local function ToggleBags()
	if TitanGetVar(TITAN_PLUGIN, "OpenBags") then
		ToggleAllBags()
	else
	end
end

--[[
Where the magic happens!
It is good practice - and good memory - to document the 'why' the code does what it does.
And give details that are not obvious to the reader who did not write the code.
--]]
local function GetBagData(id)
	--[[
	The bag name is not always available when player entering world
	Grabbing the total slots is available though to determine if a bag exists.
	The user may see bag name as UNKNOWN until an event triggers a bag check AND the name is available.
	--]]

	local total_slots = 0
	local total_free = 0
	local total_used = 0

	local count_prof = TitanGetVar(TITAN_PLUGIN, "CountProfBagSlots")

	for bag_slot = MIN_BAGS, MAX_BAGS do -- assuming 0 (Backpack) will not be a profession bag
		local slots = C_Container.GetContainerNumSlots(bag_slot)

		-- Ensure a blank structure exists
		bag_data[bag_slot] = {
			has_bag = false,
			name = "",
			maxi_slots = 0,
			free_slots = 0,
			used_slots = 0,
			style = "",
			color = "",
		}

		if slots > 0 then
			bag_data[bag_slot].has_bag = true

			local bag_name = (C_Container.GetBagName(bag_slot) or UNKNOWN)
			bag_data[bag_slot].name = bag_name
			bag_data[bag_slot].maxi_slots = slots

			local free = C_Container.GetContainerNumFreeSlots(bag_slot)
			local used = slots - free
			bag_data[bag_slot].free_slots = free
			bag_data[bag_slot].used_slots = used

			-- some info is not known until the name is available...
			-- The API requires name to get the bag ID.
			local bag_type = "none"
			local color = { r = 0, g = 0, b = 0 } -- black (should never be used...)

			-- Jan 2024 : Moved away from named based to an id based. Allows name to come later from server
			local is_prof_bag, style = IsProfessionBagID(bag_slot)

			if is_prof_bag then
				color = bag_info[style].color
				bag_type = "profession"
			else
				bag_type = "normal"
			end
			bag_data[bag_slot].style = bag_type
			bag_data[bag_slot].color = color

			-- add to total
			if bag_data[bag_slot].style == "profession" then
				if count_prof then
					total_slots = total_slots + slots
					total_free = total_free + free
					total_used = total_used + used
				else
					-- ignore in totals
				end
			else
				total_slots = total_slots + slots
				total_free = total_free + free
				total_used = total_used + used
			end
		else
			bag_data[bag_slot].has_bag = false
		end

		if trace then
			TitanPluginDebug(TITAN_PLUGIN, "T info"
				.. " " .. tostring(bag_slot) .. ""
				.. " ?:" .. tostring(bag_data[bag_slot].has_bag) .. ""
				.. " max: " .. tostring(bag_data[bag_slot].maxi_slots) .. ""
				.. " used: " .. tostring(bag_data[bag_slot].used_slots) .. ""
				.. " free: " .. tostring(bag_data[bag_slot].free_slots) .. ""
				.. " type: " .. tostring(bag_data[bag_slot].style) .. ""
				.. " count: " .. tostring(count_prof) .. ""
				.. " '" .. tostring(bag_data[bag_slot].name) .. "'"
			)
		end
	end

	bag_data.total_slots = total_slots
	bag_data.total_free = total_free
	bag_data.total_used = total_used

	local bagText = ""
	if (TitanGetVar(TITAN_PLUGIN, "ShowUsedSlots")) then
		bagText = format(L["TITAN_BAG_FORMAT"], total_used, total_slots);
	else
		bagText = format(L["TITAN_BAG_FORMAT"], total_free, total_slots);
	end

	local bagRichText = ""
	if (TitanGetVar(TITAN_PLUGIN, "ShowColoredText")) then
		local color = ""
		color = TitanUtils_GetThresholdColor(TITAN_BAG_THRESHOLD_TABLE, total_used / total_slots);
		bagRichText = TitanUtils_GetColoredText(bagText, color);
	else
		bagRichText = TitanUtils_GetHighlightText(bagText);
	end

	bagRichText =
	bagRichText            --..bagRichTextProf[1]..bagRichTextProf[2]..bagRichTextProf[3]..bagRichTextProf[4]..bagRichTextProf[5];

	return L["TITAN_BAG_BUTTON_LABEL"], bagRichText
end

-- Create the right click menu for this plugin
local function CreateMenu()
	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "TS event"
			.. " " .. tostring(TitanPanelRightClickMenu_GetDropdownLevel()) .. ""
			.. " '" .. tostring(TitanPanelRightClickMenu_GetDropdMenuValue()) .. "'"
		)
	end
	local info = {}
	-- level 2
	if TitanPanelRightClickMenu_GetDropdownLevel() == 2 then
		if TitanPanelRightClickMenu_GetDropdMenuValue() == "Options" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_OPTIONS"], TitanPanelRightClickMenu_GetDropdownLevel())
			info = {};
			info.text = L["TITAN_BAG_MENU_SHOW_USED_SLOTS"];
			info.func = function()
				TitanSetVar(TITAN_PLUGIN, "ShowUsedSlots", 1);
				TitanPanelButton_UpdateButton(TITAN_PLUGIN);
			end
			info.checked = TitanGetVar(TITAN_PLUGIN, "ShowUsedSlots");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_BAG_MENU_SHOW_AVAILABLE_SLOTS"];
			info.func = function()
				TitanSetVar(TITAN_PLUGIN, "ShowUsedSlots", nil);
				TitanPanelButton_UpdateButton(TITAN_PLUGIN);
			end
			info.checked = TitanUtils_Toggle(TitanGetVar(TITAN_PLUGIN, "ShowUsedSlots"));
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_BAG_MENU_SHOW_DETAILED"];
			info.func = function()
				TitanToggleVar(TITAN_PLUGIN, "ShowDetailedInfo");
			end
			info.checked = TitanGetVar(TITAN_PLUGIN, "ShowDetailedInfo");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_BAG_MENU_OPEN_BAGS"]
			info.func = function()
				TitanToggleVar(TITAN_PLUGIN, "OpenBags")
			end
			info.checked = TitanGetVar(TITAN_PLUGIN, "OpenBags");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end
		return
	end

	-- level 1
	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_PLUGIN].menuText);

	info = {};
	info.notCheckable = true
	info.text = L["TITAN_PANEL_OPTIONS"];
	info.value = "Options"
	info.hasArrow = 1;
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSpacer();
	info = {};
	info.text = L["TITAN_BAG_MENU_IGNORE_PROF_BAGS_SLOTS"];
	info.func = function()
		TitanToggleVar(TITAN_PLUGIN, "CountProfBagSlots");
		TitanPanelButton_UpdateButton(TITAN_PLUGIN);
	end
	info.checked = not TitanGetVar(TITAN_PLUGIN, "CountProfBagSlots")
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddControlVars(TITAN_PLUGIN)
end

-- Grab the button text to display
local function GetButtonText(id)
	local strA, strB = GetBagData(id)
	return strA, strB
end

-- Create the tooltip string
local function GetTooltipText()
	local returnstring = "";

	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "TS tool tip"
			.. " detail " .. tostring(TitanGetVar(TITAN_PLUGIN, "ShowDetailedInfo")) .. ""
			.. " used " .. tostring(TitanGetVar(TITAN_PLUGIN, "ShowUsedSlots")) .. ""
			.. " prof " .. tostring(TitanGetVar(TITAN_PLUGIN, "CountProfBagSlots")) .. ""
			.. " color " .. tostring(TitanGetVar(TITAN_PLUGIN, "ShowColoredText")) .. ""
			.. " open " .. tostring(TitanGetVar(TITAN_PLUGIN, "OpenBags")) .. ""
		)
	end

	if TitanGetVar(TITAN_PLUGIN, "ShowDetailedInfo") then
		returnstring = "\n";
		if TitanGetVar(TITAN_PLUGIN, "ShowUsedSlots") then
			returnstring = returnstring .. TitanUtils_GetNormalText(L["TITAN_BAG_MENU_TEXT"])
				.. ":\t" .. TitanUtils_GetNormalText(L["TITAN_BAG_USED_SLOTS"]) .. ":\n";
		else
			returnstring = returnstring .. TitanUtils_GetNormalText(L["TITAN_BAG_MENU_TEXT"])
				.. ":\t" .. TitanUtils_GetNormalText(L["TITAN_BAG_FREE_SLOTS"]) .. ":\n";
		end

		for bag = MIN_BAGS, MAX_BAGS do
			local bagText, bagRichText, color;

			if bag_data[bag] and bag_data[bag].has_bag then
				if (TitanGetVar(TITAN_PLUGIN, "ShowUsedSlots")) then
					bagText = format(L["TITAN_BAG_FORMAT"], bag_data[bag].used_slots, bag_data[bag].maxi_slots);
				else
					bagText = format(L["TITAN_BAG_FORMAT"], bag_data[bag].free_slots, bag_data[bag].maxi_slots);
				end

				if bag_data[bag].style == "profession"
					and not TitanGetVar(TITAN_PLUGIN, "CountProfBagSlots")
				then
					bagRichText = "|cffa0a0a0" .. bagText .. "|r" -- show as gray
				elseif (TitanGetVar(TITAN_PLUGIN, "ShowColoredText")) then
					if bag_data[bag].maxi_slots == 0 then
						color = TitanUtils_GetThresholdColor(TITAN_BAG_THRESHOLD_TABLE, 1);
					else
						color = TitanUtils_GetThresholdColor(TITAN_BAG_THRESHOLD_TABLE,
							bag_data[bag].used_slots / bag_data[bag].maxi_slots);
					end
					bagRichText = TitanUtils_GetColoredText(bagText, color);
				else
					-- use without color
					bagRichText = TitanUtils_GetHighlightText(bagText);
				end

				local name_text = bag_data[bag].name
				if bag_data[bag].style == "profession"
				then
					name_text = TitanUtils_GetColoredText(name_text, bag_data[bag].color)
				else
					-- use without color
				end
				returnstring = returnstring .. name_text .. "\t" .. bagRichText .. "\n";
			else
				returnstring = returnstring .. NONE .. "\n";
			end
		end
		returnstring = returnstring .. "\n";
	end

	if TitanGetVar(TITAN_PLUGIN, "ShowUsedSlots") then
		local xofy = "" .. tostring(bag_data.total_used)
			.. "/" .. tostring(bag_data.total_slots) .. "\n"
		returnstring = returnstring .. TitanUtils_GetNormalText(L["TITAN_BAG_USED_SLOTS"])
			.. ":\t" .. xofy
	else
		local xofy = "" .. tostring(bag_data.total_free)
			.. "/" .. tostring(bag_data.total_slots) .. "\n"
		returnstring = returnstring .. TitanUtils_GetNormalText(L["TITAN_BAG_USED_SLOTS"])
			.. ":\t" .. xofy
	end

	-- Add Hint
	if TitanGetVar(TITAN_PLUGIN, "OpenBags") then
		returnstring = returnstring .. TitanUtils_GetGreenText(L["TITAN_BAG_TOOLTIP_HINTS"])
	else
		-- nop
	end
	return returnstring
end

-- Create the .registry for Titan so it can register and place the plugin
local function OnLoad(self)
	local notes = ""
		.. "Adds bag and free slot information to Titan Panel.\n"
	--		.."- xxx.\n"
	self.registry = {
		id = TITAN_PLUGIN,
		category = "Information",
		version = VERSION,
		menuText = L["TITAN_BAG_MENU_TEXT"],
		menuTextFunction = CreateMenu,
		buttonTextFunction = GetButtonText,
		tooltipTitle = L["TITAN_BAG_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		icon = artwork_path .. "TitanStarter",
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
			CountProfBagSlots = false,
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowColoredText = 1,
			DisplayOnRightSide = false,
			OpenBags = false,
			OpenBagsClassic = "new_install",
		}
	};

	self:RegisterEvent("PLAYER_ENTERING_WORLD");

	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "TS OnLoad"
			.. " complete"
		)
	end
end

-- Parse and react to registered events
local function OnEvent(self, event, a1, a2, ...)
	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "TS event"
			.. " " .. tostring(event) .. ""
			.. " " .. tostring(a1) .. ""
		)
	end

	if event == "PLAYER_ENTERING_WORLD" then
	end

	if event == "BAG_UPDATE" then
		-- update the plugin text
		TitanPanelButton_UpdateButton(TITAN_PLUGIN);
	end
end

-- Handle mouse clicks; here L click opens all bags
local function OnClick(self, button)
	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "TS click"
			.. " " .. tostring(button) .. ""
		)
	end

	if (button == "LeftButton") then
		ToggleBags();
	end
end

local function OnShow(self)
	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "TS OnShow"
			.. " register"
		)
	end
	-- Register for bag updates and update the plugin text
	self:RegisterEvent("BAG_UPDATE")
	TitanPanelButton_UpdateButton(TITAN_PLUGIN);
end

local function OnHide(self)
	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "TS OnShow"
			.. " unregister"
		)
	end
	self:UnregisterEvent("BAG_UPDATE")
end

-- ====== Create needed frames
local function Create_Frames()
	if _G[TITAN_BUTTON] then
		return -- if already created
	end

	if trace then
		TitanPluginDebug(TITAN_PLUGIN, "TS frames"
			.. " '" .. tostring(TITAN_BUTTON) .. "'"
		)
	end

	-- general container frame
	local f = CreateFrame("Frame", nil, UIParent)
	--	f:Hide()

	-- Titan plugin button
	--[[
	The plugin frame is created here. The typical plugin is a 'combo' which includes
	- an icon (can be shown or hidden)
	- label - value pair where the label can be turned off
	There can be multiple label - value pairs; TitanPerformance uses this scheme.
	
	The frame is 'forever' as are most of WoW game frames.
	--]]
	local window = CreateFrame("Button", TITAN_BUTTON, f, "TitanPanelComboTemplate")
	window:SetFrameStrata("FULLSCREEN")
	-- Using SetScript to set "OnLoad" does not work
	--
	-- This routine sets the guts of the plugin - the .registry
	OnLoad(window);

	--[[
	Below are the frame 'events' that need to be processed.
	A couple have Titan routines that ensure the plugin is properly on / off a Titan bar.
	
	The combined Titan changed design to register for events when the user places the plugin
	on the bar (OnShow)	and unregister events when the user hids the plugin (OnHide).
	This reduces cycles the plugin uses when the user does not want the plugin.
	
	NOTE: If a Titan bar is hidden, the plugins on it will still run.
	NOTE: Titan plugins are NOT child frames!! Meaning plugins are not automatically hidden when the
	bar they are on is hidden!
	--]]
	window:SetScript("OnShow", function(self)
		OnShow(self)
		-- This routine ensures the plugin is put where the user requested it.
		-- Titan saves the bar the plugin was on. It does not save the relative order.
		TitanPanelButton_OnShow(self);
	end)
	window:SetScript("OnHide", function(self)
		OnHide(self)
		-- We use the Blizzard frame hide to visually remove the frame
	end)
	window:SetScript("OnEvent", function(self, event, ...)
		-- Handle any events the plugin is interested in
		OnEvent(self, event, ...)
	end)
	window:SetScript("OnClick", function(self, button)
		-- Typically this routine handles actions on left click
		OnClick(self, button);
		-- Typically this routine handles the menu creation on right click
		TitanPanelButton_OnClick(self, button);
	end)
end

Create_Frames() -- do the work
