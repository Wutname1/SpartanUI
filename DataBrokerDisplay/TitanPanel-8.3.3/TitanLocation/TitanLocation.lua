---@diagnostic disable: duplicate-set-field
--[[
-- **************************************************************************
-- * TitanLocation.lua
-- *
-- * 2023 Dec : Merged with Classic versions. Classic map does not include
-- * the quest log so the placement of coord on the map, if selected, is a
-- * bit more work.
-- *
-- * By: The Titan Panel Development Team
-- **************************************************************************
--]]
-- ******************************** Constants *******************************
local _G = getfenv(0);
local TITAN_LOCATION_ID = "Location";
local TITAN_BUTTON = "TitanPanel" .. TITAN_LOCATION_ID .. "Button"
local TITAN_MAP_FRAME = "TitanMapFrame"
local TITAN_LOCATION_VERSION = TITAN_VERSION;

local addon_conflict = false -- used for addon conflicts
local updateTable = { TITAN_LOCATION_ID, TITAN_PANEL_UPDATE_BUTTON };
-- ******************************** Variables *******************************
local AceTimer = LibStub("AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local LocationTimer = {};
local LocationTimerRunning = false

-- Topic debug tool / scheme
local dbg = Titan_Debug:New(TITAN_LOCATION_ID)
dbg:EnableDebug(false)
dbg:AddTopic("Map")
dbg:EnableTopic("Events", false) 
dbg:EnableTopic("Flow", false) 


local place = {
	zoneText = "",
	subZoneText = "",
	pvpType = "",
	factionName = "",
	px = 0,
	py = 0,
	realm = "",
	realm_connected = {},
	realm_connected_num = 0,
	realm_tooltip = "",
	-- to save a few cpu cycles when map is up
	show_on_map = false,
	coords_style = "",
	coords_label = "",
	player_format = "",
	cursor_format = "",
	}

---@diagnostic disable-next-line: deprecated
local GetZonePVP = C_PvP.GetZonePVPInfo or GetZonePVPInfo -- For Classic versions

-- ******************************** Functions *******************************

---local Register event if not already registered
---@param plugin Button
---@param event string
local function RegEvent(plugin, event)
	if plugin:IsEventRegistered(event) then
		-- already registered
	else
		plugin:RegisterEvent(event)
	end
end

---local Registers / unregisters (action) events the plugin needs
---@param action string
---@param reason string
local function Events(action, reason)
	local plugin = _G[TITAN_BUTTON]

	if action == "register" then
		RegEvent(plugin, "ZONE_CHANGED")
		RegEvent(plugin, "ZONE_CHANGED_INDOORS")
		RegEvent(plugin, "ZONE_CHANGED_NEW_AREA")
	elseif action == "unregister" then
		plugin:UnregisterEvent("ZONE_CHANGED")
		plugin:UnregisterEvent("ZONE_CHANGED_INDOORS")
		plugin:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	else
		-- action unknown ???
	end

	local msg = ""
		.. " " .. tostring(action) .. ""
		.. " " .. tostring(reason) .. ""
	dbg:Out("Events", msg)
end

---local Get the player coordinates on x,y axis of the map of the zone / area they are in.
---@return number | nil X
---@return number | nil Y
local function GetPlayerMapPosition()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID == nil then
		return nil, nil
	end

	local position = C_Map.GetPlayerMapPosition(mapID, "player")
	if position == nil then
		return nil, nil
	else
		return position:GetXY()
	end
end

---local Get the player realm and connected realms; set in place var for button text and tooltip.
local function RealmUpdate()
	local realmName = GetRealmName()
--	local normalized = GetNormalizedRealmName()
	local realm_names = GetAutoCompleteRealms() -- This returns normalized server names...

	place.realm = realmName
	place.realm_connected = realm_names

	local realm_text = ""
	if #realm_names == 0 then
		place.realm_connected_num = 0
		realm_text = " "..NONE.."\n"
	else
		place.realm_connected_num = #realm_names
		table.sort(realm_names, function(a, b)
			return a < b
		end)

		for i,v in pairs (realm_names) do
			realm_text = realm_text..string.format("%2d", i).." "..v.."\n"
		end
	end
	place.realm_tooltip = realm_text
end
---local Function to throttle down unnecessary updates
local function CheckForPositionUpdate()
	local tempx, tempy = GetPlayerMapPosition()

	-- If unknown then use 0,0
	if tempx == nil then
		place.px = 0
		tempx = 0
	end
	if tempy == nil then
		place.py = 0
		tempy = 0
	end

	-- If the same then do not update the text to save a few cycles.
	if tempx ~= place.px or tempy ~= place.py then
		place.px = tempx
		place.py = tempy
		TitanPanelPluginHandle_OnUpdate(updateTable);
	end
end

---local Update zone info of current toon
---@param self Button
local function ZoneUpdate(self)
	local _ = nil
	place.zoneText = GetZoneText();
	place.subZoneText = GetSubZoneText();
	place.pvpType, _, place.factionName = GetZonePVP();

	RealmUpdate()

	TitanPanelPluginHandle_OnUpdate(updateTable);
end

---local Set textg coord on map per user selection
---@param player string
---@param cursor string
local function SetCoordText(player, cursor)
	local player_frame = TitanMapPlayerLocation
	local cursor_frame = TitanMapCursorLocation
	local world_frame = WorldMapFrame

	player_frame:SetText(player or "");
	cursor_frame:SetText(cursor or "");
	player_frame:ClearAllPoints()
	cursor_frame:ClearAllPoints()

	local mloc = TitanGetVar(TITAN_LOCATION_ID, "CoordsLoc")

	if WorldMapFrame.MiniBorderFrame then -- older style world map
		-- Determine where to show the text
		if mloc == "Top" then
			if WorldMapFrame:IsMaximized() then
				player_frame:SetPoint("TOPLEFT", WorldMapFrame.BorderFrame, "TOPLEFT", 10, -5)
			else
				player_frame:SetPoint("TOPLEFT", WorldMapFrame.MiniBorderFrame, "TOPLEFT", 20, -5)
			end
			cursor_frame:SetPoint("RIGHT", WorldMapFrame.MaximizeMinimizeFrame, "LEFT", 0, 0)
		elseif mloc == "Bottom" then
			player_frame:SetPoint("BOTTOMRIGHT", world_frame, "BOTTOM", -10, 10)
			cursor_frame:SetPoint("BOTTOMLEFT", world_frame, "BOTTOM", 0, 10)
		else
			-- Correct to the default of bottom
			TitanSetVar(TITAN_LOCATION_ID, "CoordsLoc", "Bottom")
			player_frame:SetPoint("BOTTOMRIGHT", world_frame, "BOTTOM", -10, 10)
			cursor_frame:SetPoint("BOTTOMLEFT", world_frame, "BOTTOM", 0, 10)
		end
	else -- current retail
		-- Position the text
		if mloc == "Top" then
			if WorldMapFrame:IsMaximized() then
				player_frame:SetPoint("TOPLEFT", world_frame, "TOPLEFT", 20, -5)
			else
				player_frame:SetPoint("TOPLEFT", world_frame, "TOPLEFT", 100, -5)
			end
			cursor_frame:SetPoint("TOPLEFT", player_frame, "TOPRIGHT", 5, 0)
		elseif mloc == "Bottom" then
			player_frame:SetPoint("BOTTOMRIGHT", world_frame, "BOTTOM", -10, 10)
			cursor_frame:SetPoint("BOTTOMLEFT", world_frame, "BOTTOM", 0, 10)
		else
			-- Correct to the default of bottom
			TitanSetVar(TITAN_LOCATION_ID, "CoordsLoc", "Bottom")
			player_frame:SetPoint("BOTTOMRIGHT", world_frame, "BOTTOM", -10, 10)
			cursor_frame:SetPoint("BOTTOMLEFT", world_frame, "BOTTOM", 0, 10)
		end
	end
end

---local Update coordinates on map. This called every tick of timer while map is open.
---@param self Button
---@param elapsed number
local function TitanMapCoords_OnUpdate(self, elapsed)
	-- Determine the text to show for player coords
	-- This routine will do a LOT of checking for 'invalid' returns to prevent spraying errors at the user.

	local cursorLocationText = ""
	local playerLocationText = ""

	if place.show_on_map then
		place.px, place.py = GetPlayerMapPosition();
		if place.px == nil then -- invalid map / timing / ... ?
			-- Show something to user...
			playerLocationText = L["TITAN_LOCATION_NO_COORDS"]
		else
			-- format coords per the user requested format
			playerLocationText = format(place.coords_style, 100 * place.px, 100 * place.py);
		end
		-- Add label or not per user choice
		playerLocationText = (format(place.player_format, TitanUtils_GetHighlightText(playerLocationText)));

		-- Determine cursor coords REGARDLESS of map shown.
		-- The player may not be in that map / zone / area.
		local cx, cy = 0, 0
		local inside = false

		-- Use the global / screen cursor position to confirm the cursor is over the map, 
		-- then use a normalized cursor position if cursor is over map; accounts for map zooming
		cx, cy = GetCursorPosition()

		local left, bottom, width, height = WorldMapFrame.ScrollContainer:GetScaledRect();
		if left == nil then -- invalid map ?
			-- Show something to user...
			cursorLocationText = L["TITAN_LOCATION_NO_COORDS"]
		else
			if (cx > left and cy > bottom and cx < left + width and cy < bottom + height) then
				inside = true
				-- Get normalized cursor on map
				cx, cy = WorldMapFrame:GetNormalizedCursorPosition();
				cx, cy = cx or 0, cy or 0;
			else
				-- cursor outside map
				cx, cy = 0, 0
			end
			-- format coords per the user requested format
			cursorLocationText = format(place.coords_style, 100 * cx, 100 * cy)
--[[
local msg = ""
.. " " .. tostring(inside) .. ""
.. " [" .. (format("%.2f", left or 0)) .. ""
.. " " .. (format("%.2f", (bottom) or 0)) .. ""
.. " " .. (format("%.2f", (left + width) or 0)) .. ""
.. " " .. (format("%.2f", (bottom + height) or 0)) .. "]"
.. " " .. (format("%.2f", cx)) .. ""
.. " " .. (format("%.2f", cy)) .. ""
	dbg:Out("Map", msg)
--]]
		end

		-- Add label or not per user choice
		cursorLocationText = (format(place.cursor_format, TitanUtils_GetHighlightText(cursorLocationText)))
	else
		-- use defaults, saving a few cpu cycles
	end

	local msg = ""
		.. " " .. tostring(playerLocationText) .. ""
		.. " " .. tostring(cursorLocationText) .. ""
	dbg:Out("Map", msg)

	SetCoordText(playerLocationText, cursorLocationText)
end

---local Set the coordinates text for player and cursor if user requested. 
---'start' Sets the OnShow and OnHide for the coords frame. 
---'stop' Clears the OnShow and OnHide for the coords frame.
---OnShow and OnHide are triggered when world map is opened because it is the parent frame.
---@param action string start | stop
local function CoordFrames(action)
	if addon_conflict then
		-- Do not attempt coords
	else
		local frame = _G[TITAN_MAP_FRAME]
		place.show_on_map = (TitanGetVar(TITAN_LOCATION_ID, "ShowCoordsOnMap") and true or false)
		if place.show_on_map then
			if action == "start" then
				-- Save a few cycles on update by grabbing the Titan options here
				place.coords_style = TitanGetVar(TITAN_LOCATION_ID, "CoordsFormat")
				place.coords_label = TitanGetVar(TITAN_LOCATION_ID, "CoordsLabel")
				if place.coords_label then
					place.player_format = L["TITAN_LOCATION_MAP_PLAYER_COORDS_TEXT"]
					place.cursor_format = L["TITAN_LOCATION_MAP_CURSOR_COORDS_TEXT"]
				else
					place.player_format = "%s"
					place.cursor_format = "%s"
				end

				local function updateFunc()
					TitanMapCoords_OnUpdate(frame, 0.07); -- simulating an OnUpdate call
				end
				frame:SetScript("OnShow", function()
					frame.updateTicker = frame.updateTicker or C_Timer.NewTicker(0.07, updateFunc);
					if WorldMapFrame:IsMaximized() then
						WorldMapFrame.TitanSize = "large"
						WorldMapFrame.TitanSizePrev = "none"
					else
						WorldMapFrame.TitanSize = "small"
						WorldMapFrame.TitanSizePrev = "none"
					end
				end);
				frame:SetScript("OnHide", function()
					if (frame.updateTicker) then
						frame.updateTicker:Cancel();
						frame.updateTicker = nil;
					end
				end);
			elseif action == "stop" then
				-- stop timer, hooks are not needed
				frame:SetScript("OnShow", nil)
				frame:SetScript("OnHide", nil)
				SetCoordText("", "") -- cleanup
			else
				-- action unknown ???
			end
		else
			-- user did not request so save a few cycles
		end
	end

	local msg =
			"CoordFrames"
			.. " " .. tostring(action) .. ""
			.. " " .. tostring(place.show_on_map) .. ""
			.. " " .. tostring(addon_conflict) .. ""
	dbg:Out("Flow", msg)
end

---local Adds player and cursor coords to the WorldMapFrame, unless the player has CT_MapMod
local function CreateMapFrames()
	if _G[TITAN_MAP_FRAME] then
		return -- if already created
	end

	-- avoid an addon conflict
	if (_G["CT_MapMod"]) then
		addon_conflict = true
		return;
	end

	local msg =
		"CreateMapFrames"
	dbg:Out("Flow", msg)

	-- create the frame to hold the font strings, and simulate an "OnUpdate" script handler using C_Timer for efficiency
	local frame = CreateFrame("FRAME", TITAN_MAP_FRAME, WorldMapFrame)
	frame:SetFrameStrata("DIALOG") -- DF need to raise the strata to be seen

	-- create the font strings and update their position based in minimizing/maximizing the main map
	local playertext = frame:CreateFontString("TitanMapPlayerLocation", "ARTWORK", "GameFontNormal");
	local cursortext = frame:CreateFontString("TitanMapCursorLocation", "ARTWORK", "GameFontNormal");
	playertext:ClearAllPoints();
	cursortext:ClearAllPoints();
	playertext:SetPoint("TOPRIGHT", WorldMapFrameCloseButton, "BOTTOMRIGHT", 0, 0)
	cursortext:SetPoint("TOP", playertext, "BOTTOM", 0, 0)
end

---local Display button when plugin is visible
---@param self Button
local function OnShow(self)
	local msg =
		"_OnShow"
	dbg:Out("Flow", msg)

	if LocationTimerRunning then
		-- Do not schedule a new one
	else
		LocationTimer = AceTimer:ScheduleRepeatingTimer(CheckForPositionUpdate, 0.5)
	end

	CreateMapFrames() -- as needed
	CoordFrames("start") -- start coords on map, if requested

	Events("register", "_OnShow")

	-- Zone may not be available yet, PEW event should correct
	ZoneUpdate(self);

	TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
end

---local Destroy repeating timer when plugin is hidden
---@param self Button
local function OnHide(self)
	AceTimer:CancelTimer(LocationTimer)
	LocationTimerRunning = false

	Events("unregister", "_OnHide")
	CoordFrames("stop") -- stop coords on map, if requested
end

---local Calculate coordinates and then display data on button.
---@param id string
---@return string realm_label
---@return string realm_text
---@return string plugin_label
---@return string plugin_text
local function GetButtonText(id)
	-- Jul 2024 : Made display only; vars assigned per timer or events.
	local button = TitanUtils_GetButton(id);
	local locationRichText = ""

	local zone_text = ""
	local subzone_text = ""
	local xy_text = ""

	if button then -- sanity check
		-- Set in order of display on plugin...

		-- Zone text, if requested
		if TitanGetVar(TITAN_LOCATION_ID, "ShowZoneText") then
			zone_text = TitanUtils_ToString(place.zoneText)
				.." "..TitanUtils_ToString(place.subZoneText)
			-- overwrite with subZone text, if requested
			if TitanGetVar(TITAN_LOCATION_ID, "ShowSubZoneText") then
				if place.subZoneText == "" then
					-- Show the zone instead
				else
					zone_text = TitanUtils_ToString(place.subZoneText)
				end
			else
				-- leave alone
			end
		else
			zone_text = ""
		end

		-- Coordinates text, if requested
		if TitanGetVar(TITAN_LOCATION_ID, "ShowCoordsText") then
			if place.px == 0 and place.py == 0 then
				xy_text = ""
			elseif place.px == nil or place.py == nil then
				xy_text = ""
			else
				xy_text = format(TitanGetVar(TITAN_LOCATION_ID, "CoordsFormat"), 100 * place.px, 100 * place.py)
			end
		else
			xy_text = "";
		end

		-- seperator, if needed
		if ((zone_text:len() > 0) or (xy_text:len() > 0)) then
			zone_text = zone_text .. " "
		else
			-- no seperator needed
		end
	else
		locationRichText = "? id"
	end
	-- Color per type of zone (friendly, contested, hostile)
	locationRichText = zone_text..xy_text
	if (TitanGetVar(TITAN_LOCATION_ID, "ShowColoredText")) then
		if (place.isArena) then
			locationRichText = TitanUtils_GetRedText(locationRichText);
		elseif (place.pvpType == "friendly") then
			locationRichText = TitanUtils_GetGreenText(locationRichText);
		elseif (place.pvpType == "hostile") then
			locationRichText = TitanUtils_GetRedText(locationRichText);
		elseif (place.pvpType == "contested") then
			locationRichText = TitanUtils_GetNormalText(locationRichText);
		else
			locationRichText = TitanUtils_GetNormalText(locationRichText);
		end
	else
		locationRichText = TitanUtils_GetHighlightText(locationRichText);
	end

	local realm_label = ""
	local realm = ""
	if (TitanGetVar(TITAN_LOCATION_ID, "ShowRealmText")) then
		realm_label = L["TITAN_LOCATION_REALM"]
		realm = place.realm
	else
		realm_label = ""
		realm = ""
	end

	return realm_label, realm,
		L["TITAN_LOCATION_BUTTON_LABEL"], locationRichText
end

---local Get tooltip text
---@return string formatted_tooltip
local function GetTooltipText()
	local pvpInfoRichText;

	pvpInfoRichText = "";
	if (place.pvpType == "sanctuary") then
		pvpInfoRichText = TitanUtils_GetGreenText(SANCTUARY_TERRITORY);
	elseif (place.pvpType == "arena") then
		place.subZoneText = TitanUtils_GetRedText(place.subZoneText);
		pvpInfoRichText = TitanUtils_GetRedText(CONTESTED_TERRITORY);
	elseif (place.pvpType == "friendly") then
		pvpInfoRichText = TitanUtils_GetGreenText(format(FACTION_CONTROLLED_TERRITORY,
			place.factionName));
	elseif (place.pvpType == "hostile") then
		pvpInfoRichText = TitanUtils_GetRedText(format(FACTION_CONTROLLED_TERRITORY, place
		.factionName));
	elseif (place.pvpType == "contested") then
		pvpInfoRichText = TitanUtils_GetRedText(CONTESTED_TERRITORY);
	else
		pvpInfoRichText = ""
	end

	-- build the tool tip
	local zone = TitanUtils_GetHighlightText(place.zoneText) or ""
	local sub_zone = TitanUtils_Ternary(
		(place.subZoneText == ""),
		"",
		L["TITAN_LOCATION_TOOLTIP_SUBZONE"] ..
		"\t" .. TitanUtils_GetHighlightText(place.subZoneText) .. "\n"
	)
	local bind_loc = TitanUtils_GetHighlightText(GetBindLocation())

	local connected = "\n"
		..TitanUtils_GetHighlightText(L["TITAN_LOCATION_CONNECTED_REALMS"].." - "..place.realm_connected_num).."\n"
		..place.realm_tooltip.. "\n"

	return ""
		.."Realm:" .. "\t" .. TitanUtils_GetHighlightText(place.realm) .. "\n"
		..L["TITAN_LOCATION_TOOLTIP_ZONE"] .. "\t" .. zone .. "\n"
		.. sub_zone .. "\n"
		.. TitanUtils_GetHighlightText(L["TITAN_LOCATION_TOOLTIP_HOMELOCATION"]) .. "\n"
		.. L["TITAN_LOCATION_TOOLTIP_INN"] .. "\t" .. bind_loc .. "\n"
		.. pvpInfoRichText .. "\n"
		.. connected
		.. TitanUtils_GetGreenText(L["TITAN_LOCATION_TOOLTIP_HINTS_1"]) .. "\n"
		.. TitanUtils_GetGreenText(L["TITAN_LOCATION_TOOLTIP_HINTS_2"])
end

---local Handle events registered to plugin
---@param self Button
---@param event string
---@param ... any
local function OnEvent(self, event, ...)
	-- DF TODO See if we can turn off zone on minimap
	--[=[
--]=]
	local msg =
			"_OnEvent"
			.. " " .. tostring(event) .. ""
	dbg:Out("Events", msg)

	ZoneUpdate(self);
	--[[
--]]
end

---local Handle events registered to plugin. Copies coordinates to chat line for shift-LeftClick
---@param self Button
---@param button string
local function OnClick(self, button)
	if (button == "LeftButton") then
		if (IsShiftKeyDown()) then
			local activeWindow = ChatEdit_GetActiveWindow();
			if (activeWindow) then
				local message = TitanUtils_ToString(place.zoneText) .. " " ..
					format(TitanGetVar(TITAN_LOCATION_ID, "CoordsFormat"), 100 * place.px, 100 * place.py);
				activeWindow:Insert(message);
			end
		else
			ToggleFrame(WorldMapFrame);
		end
	end
end

---local Create right click menu
local function CreateMenu()
	local info

	-- level 1
	if TitanPanelRightClickMenu_GetDropdownLevel() == 1 then
		-- level 1
		TitanPanelRightClickMenu_AddTitle(TitanPlugins[TITAN_LOCATION_ID].menuText);

		info = {};
		info.notCheckable = true
		info.text = L["TITAN_PANEL_OPTIONS"];
		info.value = "Options"
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.notCheckable = true
		info.text = L["TITAN_LOCATION_FORMAT_COORD_LABEL"];
		info.value = "CoordFormat"
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		info = {};
		info.notCheckable = true
		info.text = "WorldMap"
		info.value = "WorldMap"
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

		TitanPanelRightClickMenu_AddControlVars(TITAN_LOCATION_ID)
		-- level 2
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 2 then
		if TitanPanelRightClickMenu_GetDropdMenuValue() == "Options" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_OPTIONS"], TitanPanelRightClickMenu_GetDropdownLevel());
			info = {};
			info.text = L["TITAN_LOCATION_MENU_SHOW_REALM_ON_PANEL_TEXT"];
			info.func = function()
				TitanToggleVar(TITAN_LOCATION_ID, "ShowRealmText");
				TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
			end
			info.checked = TitanGetVar(TITAN_LOCATION_ID, "ShowRealmText");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_LOCATION_MENU_SHOW_ZONE_ON_PANEL_TEXT"];
			info.func = function()
				TitanToggleVar(TITAN_LOCATION_ID, "ShowZoneText");
				TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
			end
			info.checked = TitanGetVar(TITAN_LOCATION_ID, "ShowZoneText");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

--			if TITAN_ID == "Titan" then
				info = {};
				info.text = L["TITAN_LOCATION_MENU_SHOW_SUBZONE_ON_PANEL_TEXT"];
				info.func = function()
					TitanToggleVar(TITAN_LOCATION_ID, "ShowSubZoneText");
					TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
				end
				info.checked = TitanGetVar(TITAN_LOCATION_ID, "ShowSubZoneText");
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
--			else
				-- no work needed
--			end

			info = {};
			info.text = L["TITAN_LOCATION_MENU_SHOW_COORDS_ON_PANEL_TEXT"];
			info.func = function()
				TitanToggleVar(TITAN_LOCATION_ID, "ShowCoordsText");
				TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
			end
			info.checked = TitanGetVar(TITAN_LOCATION_ID, "ShowCoordsText");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
--]]
		end

		if TitanPanelRightClickMenu_GetDropdMenuValue() == "CoordFormat" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_LOCATION_FORMAT_COORD_LABEL"],
				TitanPanelRightClickMenu_GetDropdownLevel());
			info = {};
			info.text = L["TITAN_LOCATION_FORMAT_LABEL"];
			info.func = function()
				TitanSetVar(TITAN_LOCATION_ID, "CoordsFormat", L["TITAN_LOCATION_FORMAT"]);
				TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
			end
			info.checked = (TitanGetVar(TITAN_LOCATION_ID, "CoordsFormat") == L["TITAN_LOCATION_FORMAT"])
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_LOCATION_FORMAT2_LABEL"];
			info.func = function()
				TitanSetVar(TITAN_LOCATION_ID, "CoordsFormat", L["TITAN_LOCATION_FORMAT2"]);
				TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
			end
			info.checked = (TitanGetVar(TITAN_LOCATION_ID, "CoordsFormat") == L["TITAN_LOCATION_FORMAT2"])
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_LOCATION_FORMAT3_LABEL"];
			info.func = function()
				TitanSetVar(TITAN_LOCATION_ID, "CoordsFormat", L["TITAN_LOCATION_FORMAT3"]);
				TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
			end
			info.checked = (TitanGetVar(TITAN_LOCATION_ID, "CoordsFormat") == L["TITAN_LOCATION_FORMAT3"])
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end

		if TitanPanelRightClickMenu_GetDropdMenuValue() == "WorldMap" then
			TitanPanelRightClickMenu_AddTitle(L["TITAN_LOCATION_MENU_TEXT"], TitanPanelRightClickMenu_GetDropdownLevel());
			info = {};
			info.text = L["TITAN_LOCATION_MENU_SHOW_COORDS_ON_MAP_TEXT"];
			info.func = function()
				TitanToggleVar(TITAN_LOCATION_ID, "ShowCoordsOnMap");
				if (TitanGetVar(TITAN_LOCATION_ID, "ShowCoordsOnMap")) then
					CoordFrames("start")
				else
					CoordFrames("stop")
				end
			end
			info.checked = TitanGetVar(TITAN_LOCATION_ID, "ShowCoordsOnMap");
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_LOCATION_MENU_UPDATE_WORLD_MAP"];
			info.func = function()
				TitanToggleVar(TITAN_LOCATION_ID, "UpdateWorldmap");
			end
			info.checked = TitanGetVar(TITAN_LOCATION_ID, "UpdateWorldmap");
			info.disabled = InCombatLockdown()
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			if TITAN_ID == "Titan" then
				info = {};
				info.notCheckable = true
				info.text = L["TITAN_LOCATION_MENU_TEXT"];
				info.value = "CoordsLoc"
				info.hasArrow = 1;
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			else
				-- no work needed
			end
		end

		-- level 3
	elseif TitanPanelRightClickMenu_GetDropdownLevel() == 3 then
		if TitanPanelRightClickMenu_GetDropdMenuValue() == "CoordsLoc" then
			info = {};
			info.text = L["TITAN_PANEL_MENU_BOTTOM"];
			info.func = function()
				TitanSetVar(TITAN_LOCATION_ID, "CoordsLoc", "Bottom");
				--				TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
			end
			info.checked = (TitanGetVar(TITAN_LOCATION_ID, "CoordsLoc") == "Bottom")
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.text = L["TITAN_PANEL_MENU_TOP"];
			info.func = function()
				TitanSetVar(TITAN_LOCATION_ID, "CoordsLoc", "Top");
				--				TitanPanelButton_UpdateButton(TITAN_LOCATION_ID);
			end
			info.checked = (TitanGetVar(TITAN_LOCATION_ID, "CoordsLoc") == "Top")
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end
	end
end

---local Create the plugin .registry and register startign events
---@param self Button
local function OnLoad(self)
	local notes = ""
	.. "Adds coordinates and location information to Titan Panel.\n"
	.. "Option Show Zone Text shows zone text - or not.\n"
	.. "- Show ONLY Subzone Text removes zone text from plugin.\n"
	--		.."- xxx.\n"
	self.registry = {
		id = TITAN_LOCATION_ID,
		category = "Built-ins",
		version = TITAN_LOCATION_VERSION,
		menuText = L["TITAN_LOCATION_MENU_TEXT"],
		menuTextFunction = CreateMenu,
		buttonTextFunction = GetButtonText,
		tooltipTitle = L["TITAN_LOCATION_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		icon = "Interface\\AddOns\\TitanLocation\\TitanLocation",
		iconWidth = 16,
		notes = notes,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = true,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowRealmText = false,
			ShowZoneText = 1,
			ShowSubZoneText = false,
			ShowCoordsText = true,
			ShowCoordsOnMap = true,
			ShowCursorOnMap = true,
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowColoredText = 1,
			CoordsFormat = L["TITAN_LOCATION_FORMAT"],
			CoordsLoc = "Bottom",
			CoordsLabel = true,
			UpdateWorldmap = false,
			DisplayOnRightSide = false,
		}
	};

	local msg =
		"_OnLoad"
	dbg:Out("Flow", msg)
end

---local Create needed frames
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


Create_Frames()
