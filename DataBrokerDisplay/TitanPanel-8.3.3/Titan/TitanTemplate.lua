--[===[ File
Creates the following frames:
- TitanPanelBarButton : Main Titan frame handling events
- TitanPanelTooltip : Used? Inherits from GameTooltipTemplate

Contains the routines to control a Titan template frame.
These could be:
- A Titan bar (full or short)
- A Titan plugin (built-in, thrid party, or LDB)

The Titan templates are defined in .xml.
There appears to be no other way to make frame templates - virtual="true".
--]===]

--[===[ Var API TitanPanelTemplate overview
See TitanPanelButtonTemplate.xml also for more detail.

TitanTemplate (Lua and XML) contain the basics for Titan plugin frames.
Titan templates contain elements used by Titan.

A Titan plugin is a frame created using one of the button types in TitanPanelButtonTemplate.xml.
The available plugin types are:
- TitanPanelTextTemplate - * A frame that only displays text ("$parentText")
- TitanPanelIconTemplate - * A frame that only displays an icon ("$parentIcon")
- TitanPanelComboTemplate - * A frame that displays an icon then text ("$parentIcon"  "$parentText")
- TitanOptionsSliderTemplate - A frame that contains the basics for a vertical slider control. See TitanVolume for an example.

* Templates inherit TitanPanelButtonTemplate for common elements.

Most plugins use the combo template.

TitanPanelButtonTemplate contains:
- a frame to handle a menu invoked by a right mouse click ("$parentRightClickMenu")
- default event handlers for
			<OnLoad>
				TitanPanelButton_OnLoad(self);
			</OnLoad>
			<OnShow>
				TitanPanelButton_OnShow(self);
			</OnShow>
			<OnClick>
				TitanPanelButton_OnClick(self, button);
			</OnClick>
			<OnEnter>
				TitanPanelButton_OnEnter(self);
			</OnEnter>
			<OnLeave>
				TitanPanelButton_OnLeave(self);
			</OnLeave>
If these events are overridden then the default routine needs to be included!


NOTE: TitanPanelChildButtonTemplate - Removed 2024 Jun
--]===]

-- Globals

-- Constants
local TITAN_PANEL_LABEL_SEPARATOR = "  "
local TITAN_PANEL_BUTTON_WIDTH_CHANGE_TOLERANCE = 10;
local TITAN_PANEL_BUTTON_TYPE_TEXT = 1;
local TITAN_PANEL_BUTTON_TYPE_ICON = 2;
local TITAN_PANEL_BUTTON_TYPE_COMBO = 3;
local TITAN_PANEL_BUTTON_TYPE_CUSTOM = 4;
local pluginOnEnter = nil;
local TITAN_PANEL_MOVE_ADDON = "";
local TITAN_PANEL_DROPOFF_ADDON = "";

-- Library instances
local LibQTip = nil
local _G = getfenv(0);
local InCombatLockdown = _G.InCombatLockdown
local media = LibStub("LibSharedMedia-3.0")

--[[
print("B text"
.." "..tostring(id)..""
.." "..tostring(type(bFunction))..""
.." '"..tostring(bFunction).."'"
.." '"..tostring(buttonTextFunction).."'"
)
--]]
--==========================

--[[ local
NAME: TitanPanel_SetScale
DESC: Set the scale of each plugin and each Titan bar.
VAR:  None
OUT:  None
--]]
function TitanPanel_SetScale()
	local scale = TitanPanelGetVar("Scale");

	-- Set all the Titan bars
	for idx, v in pairs(TitanBarData) do
		_G[idx]:SetScale(scale)
	end
	-- Set all the registered plugins
	for index, value in pairs(TitanPlugins) do
		if index then
			TitanUtils_GetButton(index):SetScale(scale);
		end
	end
end

---local Helper to add a line of tooltip text to the tooltip.
---@param text string To add
---@param frame table Tooltip frame
--- Append a "\n" to the end if there is not one already there
local function TitanTooltip_AddTooltipText(text, frame)
	if (text) then
		-- Append a "\n" to the end
		if (string.sub(text, -1, -1) ~= "\n") then
			text = text .. "\n";
		end

		-- See if the string is intended for a double column
		for text1, text2 in string.gmatch(text, "([^\t\n]*)\t?([^\t\n]*)\n") do
			if (text2 ~= "") then
				-- Add as double wide
				frame:AddDoubleLine(text1, text2);
			elseif (text1 ~= "") then
				-- Add single column line
				frame:AddLine(text1);
			else
				-- Assume a blank line
				frame:AddLine("\n");
			end
		end
	else
		-- No text to display
	end
end

---local Helper to set both the parent and the position of GameTooltip for the plugin tooltip.
---@param parent table Reference to the frame to attach the tooltip to
---@param anchorPoint string Tooltip anchor location (side or corner) to use
---@param relativeToFrame string name name of the frame, usually the plugin), to attach the tooltip to
---@param relativePoint string Parent anchor location (side or corner) to use
---@param xOffset number X offset
---@param yOffset number Y offset
---@param frame table Tooltip frame
--- Set Titan_Global.debug.tool_tips to output debug
local function TitanTooltip_SetOwnerPosition(parent, anchorPoint, relativeToFrame, relativePoint, xOffset, yOffset, frame)
	-- Changes for 9.1.5 Removed the background template from the GameTooltip
	-- Making changes to it difficult and possibly changing the tooltip globally.

	frame:SetOwner(parent, "ANCHOR_NONE");
	frame:SetPoint(anchorPoint, relativeToFrame, relativePoint, xOffset, yOffset);

	-- set font size for the Game Tooltip
	if TitanPanelGetVar("DisableTooltipFont") then
		-- use UI scale
	else
		if TitanTooltipScaleSet < 1 then
			TitanTooltipOrigScale = frame:GetScale();
			TitanTooltipScaleSet = TitanTooltipScaleSet + 1;
		end
		frame:SetScale(TitanPanelGetVar("TooltipFont"));
	end

	if Titan_Global.debug.tool_tips then
		local dbg_msg = "_pos"
			.. " '" .. tostring(frame:GetName()) .. "'"
			.. " " .. tostring(frame:IsShown()) .. ""
			.. " @ '" .. tostring(relativeToFrame) .. "'"
			.. " " .. tostring(_G[relativeToFrame]:IsShown()) .. ""
		TitanDebug(dbg_msg, "normal")
		dbg_msg = ">>_pos"
			.. " " .. tostring(anchorPoint) .. ""
			.. " " .. tostring(relativePoint) .. ""
			.. " w" .. tostring(format("%0.1f", frame:GetWidth())) .. ""
			.. " h" .. tostring(format("%0.1f", frame:GetHeight())) .. ""
		TitanDebug(dbg_msg, "normal")
	end
end

---local Helper to set the screen position of the tooltip frame
---@param self table Tooltip frame
---@param id string Plugin id name
---@param frame table Tooltip frame - expected to be GameTooltip
local function TitanTooltip_SetPanelTooltip(self, id, frame)
	local button = TitanUtils_GetButton(id)

	if button then
		-- Adjust the Y offset as needed
		local rel_y = self:GetTop() - frame:GetHeight()
		local pt = ""
		local rel_pt = ""
		if rel_y > 0 then
			pt = "TOP";
			rel_pt = "BOTTOM";
		else
			-- too close to bottom of screen
			pt = "BOTTOM";
			rel_pt = "TOP";
		end
		local rel_x = self:GetLeft() + frame:GetHeight()
		if (rel_x < GetScreenWidth()) then
			-- menu will fit
			pt = pt .. "LEFT";
			rel_pt = rel_pt .. "LEFT";
		else
			pt = pt .. "RIGHT";
			rel_pt = rel_pt .. "RIGHT";
		end

		TitanTooltip_SetOwnerPosition(button, pt, button:GetName(), rel_pt, 0, 0, frame)
	end
end

---local Set the tooltip (GameTooltip) of the given Titan plugin.
---@param self table Plugin frame
--- Set Titan_Global.debug.tool_tips to output debug of this routine
local function TitanPanelButton_SetTooltip(self)
	local dbg_msg = "TT:"
	local ok = false
	local frame = GameTooltip
	local id = self.registry.id

	-- ensure that the 'self' passed is a valid frame reference
	if self:GetName() then
		dbg_msg = dbg_msg .. "'" .. self:GetName() .. "'"
		-- sanity checks
		if (TitanPanelGetVar("HideTipsInCombat") and InCombatLockdown()) then
			dbg_msg = dbg_msg .. " HideTipsInCombat"
		else
			if TitanPanelGetVar("ToolTipsShown") then
				ok = true
			else
				dbg_msg = dbg_msg .. " ToolTipsShown false"
			end
		end
	else
		dbg_msg = dbg_msg .. " No frame"
		-- Cannot even start
	end

	if ok then
		local call_success = nil
		local tmp_txt = ""
		local use_mod = TitanAllGetVar("UseTooltipModifer")
		local use_alt = TitanAllGetVar("TooltipModiferAlt")
		local use_ctrl = TitanAllGetVar("TooltipModiferCtrl")
		local use_shift = TitanAllGetVar("TooltipModiferShift")

		if use_mod then
			if (use_alt and IsAltKeyDown())
				or (use_ctrl and IsControlKeyDown())
				or (use_shift and IsShiftKeyDown())
			then
				ok = true
			end
		else
			ok = true
		end

		self.tooltipCustomFunction = nil;
		self.titan_tt_func = ""
		self.titan_tt_err = ""

		if ok and (id and TitanUtils_IsPluginRegistered(id)) then
			local plugin = TitanUtils_GetPlugin(id)
			-- 2024 Jun Add id and frame name to 'pass' to tooltip routine.
			-- A compromise given that this mechanism is used by nearly all plugins.
			-- Used by Titan auto hide to better determine which bar the 'pin' / icon is on.
			self.plugin_id = id
			self.plugin_frame = TitanUtils_ButtonName(id)
			if (plugin and plugin.tooltipCustomFunction) then
                -- Hide the GameTooltip while being updated, to avoid race conditions.
                frame:Hide()
				-- Prep the tooltip frame
				TitanTooltip_SetPanelTooltip(self, id, frame);

				-- Fill the tooltip
				self.tooltipCustomFunction = plugin.tooltipCustomFunction;
				dbg_msg = dbg_msg .. " | custom"
				call_success, -- for pcall
				tmp_txt = pcall(self.tooltipCustomFunction, self)
				if call_success then
					-- all is good
					dbg_msg = dbg_msg .. " | ok"
				else
					dbg_msg = dbg_msg .. " | Err: " .. tmp_txt
				end

				frame:Show(); -- now show it
			elseif (plugin and plugin.tooltipTitle) then
				local tooltipTextFunc = {} ---@type function
				local tt_func = plugin.tooltipTextFunction

				if type(tt_func) == 'string' then
					-- Function MUST be in global namespace
					tooltipTextFunc = _G[tt_func]
					dbg_msg = dbg_msg .. " | string"
				elseif type(tt_func) == 'function' then
					-- Can be global or local to the plugin
					tooltipTextFunc = tt_func
					dbg_msg = dbg_msg .. " | function"
				else
					-- silently leave...
					dbg_msg = dbg_msg .. " | none found"
				end

				if (tooltipTextFunc) then
                    -- Hide the GameTooltip while being updated, to avoid race conditions.
                    frame:Hide()
					-- Prep the tooltip frame
					TitanTooltip_SetPanelTooltip(self, id, frame);
					self.tooltipTitle = plugin.tooltipTitle;
					call_success, -- for pcall
					tmp_txt = pcall(tooltipTextFunc, self)

					-- Fill the tooltip
					self.tooltipText = tmp_txt
					frame:SetText(self.tooltipTitle,
						HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
					if (self.tooltipText) then
						TitanTooltip_AddTooltipText(self.tooltipText, frame)
						dbg_msg = dbg_msg .. " | ok"
					else
						dbg_msg = dbg_msg .. " | No text"
					end

					frame:Show() -- now show it
				end
			else
				-- no recognized method to create tooltip
				dbg_msg = "No recognized tooltip method [.tooltipCustomFunction then .tooltipTitle /.tooltipText]"
			end
		end
	else
		-- no need to waste cycles
	end

	if Titan_Global.debug.tool_tips then
		TitanDebug(dbg_msg, "normal")
	end
end

---local Is the given Titan plugin template type text?
---@param id string Plugin id name
---@return boolean IsText
local function TitanPanelButton_IsText(id)
	if (TitanPanelButton_GetType(id) == TITAN_PANEL_BUTTON_TYPE_TEXT) then
		return true
	else
		return false
	end
end

---local Is the given Titan plugin of type combo?
---@param id string Plugin id name
---@return boolean IsCombo
local function TitanPanelButton_IsCombo(id)
	if (TitanPanelButton_GetType(id) == TITAN_PANEL_BUTTON_TYPE_COMBO) then
		return true
	else
		return false
	end
end

---Titan Is the given Titan plugin of type icon?
---@param id string Plugin id name
---@return boolean is_icon
function TitanPanelButton_IsIcon(id)
	local res = false
	if (TitanPanelButton_GetType(id) == TITAN_PANEL_BUTTON_TYPE_ICON) then
		res = true
	else
		res = false
	end

	return res
end

---local Handle the OnDragStart event of the given Titan plugin.
---@param self table Plugin frame
--- Do nothing if the user has locked plugins or if in combat.
--- Set the .isMoving of the plugin (frame) so other routine can check it.
--- Set TITAN_PANEL_MOVING so any Titan routine will know a 'drag & drop' is in progress.
--- Set TITAN_PANEL_MOVE_ADDON so sanity checks can be done on the 'drop'.
local function TitanPanelButton_OnDragStart(self)
	if TitanPanelGetVar("LockButtons") or InCombatLockdown() then return end

	local frname = self;

	-- Clear button positions or we'll grab the button and all buttons 'after'
	for i, j in pairs(TitanPanelSettings.Buttons) do
		local pluginid = _G[TitanUtils_ButtonName(TitanPanelSettings.Buttons[i])];
		if pluginid then
			pluginid:ClearAllPoints()
		end
	end

	-- Start the drag; close any tooltips and open control frames
	frname:StartMoving();
	frname.isMoving = true;
	TitanUtils_CloseAllControlFrames();
	TitanPanelRightClickMenu_Close();
	if AceLibrary then
		if AceLibrary:HasInstance("Dewdrop-2.0") then
			AceLibrary("Dewdrop-2.0"):Close()
		end
		if AceLibrary:HasInstance("Tablet-2.0") then
			AceLibrary("Tablet-2.0"):Close()
		end
	end
	GameTooltip:Hide();
	-- LibQTip-1.0 support code
	LibQTip = LibStub("LibQTip-1.0", true)
	if LibQTip then
		local key, tip
		for key, tip in LibQTip:IterateTooltips() do
			if tip then
				local _, relativeTo = tip:GetPoint()
				if relativeTo and relativeTo:GetName() == self:GetName() then
					tip:Hide()
					break
				end
			end
		end
	end
	-- /LibQTip-1.0 support code

	-- Hold the plugin id so we can do checks on the drop
	TITAN_PANEL_MOVE_ADDON = TitanUtils_GetButtonID(self:GetName());

	-- Tell Titan that a drag & drop is in process
	TITAN_PANEL_MOVING = 1;
	-- Store the OnEnter handler so the tooltip does not show - or other oddities
	pluginOnEnter = self:GetScript("OnEnter")
	self:SetScript("OnEnter", nil)
end

---local Handle the OnDragStop event of the given Titan plugin.
---@param self table Plugin frame
--- Clear the .isMoving of the plugin (frame).
--- Clear TITAN_PANEL_MOVING.
--- Clear TITAN_PANEL_MOVE_ADDON.
local function TitanPanelButton_OnDragStop(self)
	if TitanPanelGetVar("LockButtons") then
		return
	end
	local ok_to_move = true
	local nonmovableFrom = false;
	local nonmovableTo = false;
	local frname = self;

	if TITAN_PANEL_MOVING == 1 then
		frname:StopMovingOrSizing();
		frname.isMoving = false;
		TITAN_PANEL_MOVING = 0;

		-- See if the plugin is supposed to stay on the bar it is on
		if TitanGetVar(TITAN_PANEL_MOVE_ADDON, "ForceBar") then
			ok_to_move = false
		end

		-- eventually there could be several reasons to not allow
		-- the plugin to move
		if ok_to_move then
			local i, j;
			for i, j in pairs(TitanPanelSettings.Buttons) do
				local pluginid =
					_G[TitanUtils_ButtonName(TitanPanelSettings.Buttons[i])];
				--					_G["TitanPanel"..TitanPanelSettings.Buttons[i].."Button"];
				if (pluginid and MouseIsOver(pluginid)) and frname ~= pluginid then
					TITAN_PANEL_DROPOFF_ADDON = TitanPanelSettings.Buttons[i];
				end
			end

			-- switching sides is not allowed
			nonmovableFrom = TitanUtils_ToRight(TITAN_PANEL_MOVE_ADDON)
			nonmovableTo = TitanUtils_ToRight(TITAN_PANEL_DROPOFF_ADDON)
			if nonmovableTo ~= nonmovableFrom then
				TITAN_PANEL_DROPOFF_ADDON = "";
			end

			if TITAN_PANEL_DROPOFF_ADDON == "" then
				-- See if the plugin was dropped on a bar rather than
				-- another plugin.
				local bar
				local tbar = nil
				-- Find which bar it was dropped on
				for idx, v in pairs(TitanBarData) do
					bar = idx
					if (bar and MouseIsOver(_G[bar])) then
						tbar = bar
					end
				end

				if tbar then
					TitanPanel_RemoveButton(TITAN_PANEL_MOVE_ADDON)
					TitanUtils_AddButtonOnBar(TitanBarData[tbar].name, TITAN_PANEL_MOVE_ADDON)
				else
					-- not sure what the user did...
				end
			else
				-- plugin was dropped on another plugin - swap (for now)
				local dropoff = TitanUtils_GetCurrentIndex(TitanPanelSettings.Buttons
				, TITAN_PANEL_DROPOFF_ADDON);
				local pickup = TitanUtils_GetCurrentIndex(TitanPanelSettings.Buttons
				, TITAN_PANEL_MOVE_ADDON);
				local dropoffbar = TitanUtils_GetWhichBar(TITAN_PANEL_DROPOFF_ADDON);
				local pickupbar = TitanUtils_GetWhichBar(TITAN_PANEL_MOVE_ADDON);

				if dropoff ~= nil and dropoff ~= "" then
					-- TODO: Change to 'insert' rather than swap
					TitanPanelSettings.Buttons[dropoff] = TITAN_PANEL_MOVE_ADDON;
					TitanPanelSettings.Location[dropoff] = dropoffbar;
					TitanPanelSettings.Buttons[pickup] = TITAN_PANEL_DROPOFF_ADDON;
					TitanPanelSettings.Location[pickup] = pickupbar;
				end
			end
		end

		-- This is important! The start drag cleared the button positions so
		-- the buttons need to be put back properly.
		TitanPanel_InitPanelButtons();
		TITAN_PANEL_MOVE_ADDON = "";
		TITAN_PANEL_DROPOFF_ADDON = "";
		-- Restore the OnEnter script handler
		if pluginOnEnter then self:SetScript("OnEnter", pluginOnEnter) end
		pluginOnEnter = nil;
	end
end

---API Set the color of the tooltip text to normal (white) with the value in green.
---@param text string Label to show
---@param value any Value to show; something tostring() can handle
---@return string str Formatted text and value
--- self.tooltipText = TitanOptionSlider_TooltipText("Addons", TitanGetVar(TITAN_PERFORMANCE_ID, "NumOfAddons"));
function TitanOptionSlider_TooltipText(text, value)
	return tostring(text) .. " " .. GREEN_FONT_COLOR_CODE .. tostring(value) .. FONT_COLOR_CODE_CLOSE;
end

---API Handle the OnLoad event of the requested Titan plugin. Ensure the plugin is set to be registered.
---@param self table Plugin frame
--- This is called from the Titan plugin frame in the OnLoad event - usually as the frame is created in the Titan template.
function TitanPanelButton_OnLoad(self)
	-- Used by plugins
	--[[
--- This is called from the Titan plugin frame in the OnLoad event - usually as the frame is created in the Titan template.
--- This starts the plugin registration process. See TitanUtils for more details on plugin registration.
--- The plugin registration is a two step process because not all addons create Titan plugins in the frame create.
--- The Titan feature of converting LDB addons to Titan plugins is an example.
--- If the plugin needs an OnLoad process it should call this routine after its own. I.E.
--- TitanPanelLootTypeButton_OnLoad(self)
--- TitanPanelButton_OnLoad(self)
--]]
	TitanUtils_PluginToRegister(self)
end

---API Handle the OnShow event of the requested Titan plugin.
---@param self table Plugin frame
function TitanPanelButton_OnShow(self)
	local id = nil;
	-- ensure that the 'self' passed is a valid frame reference
	if self and self:GetName() then
		id = TitanUtils_GetButtonID(self:GetName());
	end
	-- ensure that id is a valid Titan plugin
	if (id) then
		TitanPanelButton_UpdateButton(id, 1);
	end
end

---API Handle the OnClick mouse event of the requested Titan plugin.
---@param self table Plugin frame
---@param button string Mouse button clicked
--- Only the left and right mouse buttons are handled by Titan.
--- Called from Titan templates unless overriden by plugin. If overridden the plugin should call this routine.
function TitanPanelButton_OnClick(self, button)
	local id
	-- ensure that the 'self' passed is a valid frame reference
	if self and self:GetName() then
		id = TitanUtils_GetButtonID(self:GetName())
	end

	if id then
		local controlFrame = TitanUtils_GetControlFrame(id);

		if controlFrame and (button == "LeftButton") then
			local isControlFrameShown;
			if (not controlFrame) then
				isControlFrameShown = false;
			elseif (controlFrame:IsVisible()) then
				isControlFrameShown = false;
			else
				isControlFrameShown = true;
			end

			TitanUtils_CloseAllControlFrames();
			TitanPanelRightClickMenu_Close();

			--			local position = TitanUtils_GetWhichBar(id)
			if (isControlFrameShown) then
				-- Note: This uses anchor points to place the control frame relative to the plugin on the screen.
				local parent = self:GetName() -- plugin with the control frame
				local point = ""  -- point of the control frame
				local rel_point = "" -- The middle - top or bottom edge - of the plugin to anchor to
				--[[ Mar 2023 : removed reference to Titan bar reference
					Instead use the relative position on the screen to show the control (plugin) frame properly.
					NOTE: If Titan bars need a left click to show a control frame the offset
					will need to be changed to use the cursor position like right click menu!!
				--]]
				if (self:GetTop() - controlFrame:GetHeight()) > 0 then
					point = "TOP"
					rel_point = "BOTTOM"
				else -- below screen
					point = "BOTTOM"
					rel_point = "TOP"
				end

				local x = 0
				local y = 0

				controlFrame:ClearAllPoints();
				controlFrame:SetPoint(point .. "LEFT", parent, rel_point, 0, 0) -- default left of plugin

				-- Adjust control frame position if it's off the screen
				local offscreenX, offscreenY = TitanUtils_GetOffscreen(controlFrame);
				if (offscreenX == -1) then
					-- Off to left of screen which should not happen...
				elseif (offscreenX == 1) then
					-- off to right of screen, flip to right of plugin
					controlFrame:ClearAllPoints();
					controlFrame:SetPoint(point .. "RIGHT", parent, rel_point, 0, 0)
				end

				controlFrame:Show();
			end
		elseif (button == "RightButton") then
			TitanUtils_CloseAllControlFrames();
			-- Show RightClickMenu anyway
			TitanPanelRightClickMenu_Close();
			TitanPanelRightClickMenu_Toggle(self);
		end

		GameTooltip:Hide();
	end
end

---API Handle the OnEnter event of the requested Titan plugin.
---@param self table Plugin frame
--- 1. The cursor has moved over the plugin so show the plugin tooltip.
--- 2. Return if plugin "is moving" or if tooltip is already shown.
function TitanPanelButton_OnEnter(self)
	local id = nil;
	-- ensure that the 'self' passed is a valid frame reference
	if self and self:GetName() then
		id = TitanUtils_GetButtonID(self:GetName())
	end

	if (id) then
		local controlFrame = TitanUtils_GetControlFrame(id);
		if (controlFrame and controlFrame:IsVisible()) then
			return;
		elseif (TitanPanelRightClickMenu_IsVisible()) then
			return;
		else
			if TITAN_PANEL_MOVING == 0 then
				TitanPanelButton_SetTooltip(self);
			end
			if self.isMoving then
				GameTooltip:Hide();
			end
		end
	end
end

---API Handle the OnLeave event of the requested Titan plugin.
---@param self table Plugin frame
--- 1. The cursor has moved over the plugin so hide the plugin tooltip.
function TitanPanelButton_OnLeave(self)
	local id = nil;
	-- ensure that the 'self' passed is a valid frame reference
	if self and self:GetName() then
		id = TitanUtils_GetButtonID(self:GetName())
	end

	if (id) then
		GameTooltip:Hide();
	end

	if TitanPanelGetVar("DisableTooltipFont") then
		-- use game font & scale
	else
		-- use Titan font & scale
		GameTooltip:SetScale(TitanTooltipOrigScale);
		TitanTooltipScaleSet = 0;
	end
end

-- local routines for Update Button


local format_with_label = { [0] = "" } -- Set format string once
for idx = 1, 4 do
	format_with_label[idx] = "%s%s" .. (TITAN_PANEL_LABEL_SEPARATOR .. "%s%s"):rep(idx - 1)
end
---local Set the width of the given icon Titan plugin - icon only.
---@param id string Plugin id
--- The plugin is expected to tell Titan what routine is to be called in <self>.registry.buttonTextFunction.
--- Note: Titan handles up to 4 label-value pairs. User may customize (override) the plugin labels.
--- The text routine is called in protected mode (pcall) to ensure the Titan main routines still run.
local function TitanPanelButton_SetButtonText(id)
	--- There are several places that return in this routine. Not best practice but more readable.
	local dbg_msg = "ptxt : '" .. tostring(id) .. "'"
	local ok = false

	if (id and TitanUtils_IsPluginRegistered(id)) then
		-- seems valid, registered plugin
		ok = true
	else
		-- return silently; The plugin is not registered!
		-- output here could be a lot and really annoy the user...
		dbg_msg = dbg_msg .. " | unregistered plugin"
	end

	local pdata = TitanUtils_GetPlugin(id) -- get plugin data
	local buttonTextFunction = {} ---@type function

	if pdata then
		local bFunction = pdata.buttonTextFunction
		if type(bFunction) == 'string' then
			-- Function MUST be in global namespace
			buttonTextFunction = _G[bFunction]
			ok = true
		elseif type(bFunction) == 'function' then
			-- Can be global or local to the plugin
			buttonTextFunction = bFunction
			ok = true
		else
			dbg_msg = dbg_msg .. " | invalid function type"
			-- silently leave...
		end
	else
		-- silently leave...
		dbg_msg = dbg_msg .. " | invalid plugin data"
	end

	if ok and buttonTextFunction then
		local label1, value1, label2, value2, label3, value3, label4, value4
		local call_success = false
		local button = TitanUtils_GetButton(id) -- get plugin frame
		local buttonText = {}

		local text = false
		if button then
			buttonText = _G[button:GetName() .. TITAN_PANEL_TEXT];

			local newfont = media:Fetch("font", TitanPanelGetVar("FontName"))
			if newfont then
				buttonText:SetFont(newfont, TitanPanelGetVar("FontSize"))
			end

			-- We'll be paranoid here and call the button text in protected mode.
			-- In case the button text fails it will not take Titan with it...
			call_success, -- for pcall
			label1, value1, label2, value2, label3, value3, label4, value4 =
				pcall(buttonTextFunction, id)

			if call_success then
				-- All is good
				text = true
			else
				buttonText:SetText("<?>")
				dbg_msg = dbg_msg .. " | Err '" .. tostring(label1) .. "'"
			end
		else
			dbg_msg = dbg_msg .. " | invalid plugin id"
		end

		--=====================================
		-- Determine the label value pairs : 1 - 4
		-- Each could be custom per user
		--
		-- NumLabelsSeen - used for the config to avoid confusing user
		-- Plugin MUST have been shown at least once.

		-- In the case of first label only (no value), set the button and return.
		if text and
			label1 and
			not (label2 or label3 or label4
				or value1 or value2 or value3 or value4) then
			buttonText:SetText(label1)

			TitanSetVar(id, "NumLabelsSeen", 1)

			dbg_msg = dbg_msg .. " | single label; no value | "
		else
			local show_label = TitanGetVar(id, "ShowLabelText")
			local values = 0
			if label1 or value1 then
				values = 1
				if show_label then
					if TitanGetVar(id, "CustomLabelTextShow") then
						-- override the label per the user
						label1 = TitanGetVar(id, "CustomLabelText")
					else
					end
				else
					label1 = ""
				end
				if label2 or value2 then
					values = 2
					if show_label then
						if TitanGetVar(id, "CustomLabel2TextShow") then
							-- override the label per the user
							label2 = TitanGetVar(id, "CustomLabel2Text")
						else
						end
					else
						label2 = ""
					end
					if label3 or value3 then
						if show_label then
							if TitanGetVar(id, "CustomLabel3TextShow") then
								-- override the label per the user
								label3 = TitanGetVar(id, "CustomLabel3Text")
							else
							end
						else
							label3 = ""
						end
						values = 3
						if label4 or value4 then
							values = 4
							if show_label then
								if TitanGetVar(id, "CustomLabel43TextShow") then
									-- override the label per the user
									label4 = TitanGetVar(id, "CustomLabel4Text")
								else
								end
							else
								label4 = ""
							end
						end
					end
				end
				dbg_msg = dbg_msg .. " | ok | " .. tostring(values)
			else
				-- no label or value
				-- Do nothing, it could be the right action for the plugin
				dbg_msg = dbg_msg .. " | no label or value : " .. tostring(values)
			end

			TitanSetVar(id, "NumLabelsSeen", values)

			-- values tells which format to use from the array
			buttonText:SetFormattedText(format_with_label[values],
				label1 or "", value1 or "",
				label2 or "", value2 or "",
				label3 or "", value3 or "",
				label4 or "", value4 or ""
			)
		end
	else
		-- no valid routine to update the plugin text
		dbg_msg = dbg_msg .. " | no valid routine found"
	end
	if Titan_Global.debug.plugin_text then
		TitanDebug(dbg_msg, "normal")
	end
end

---local Set the width of the given Titan plugin - text only.
---@param id string Plugin id
---@param setButtonWidth? integer Width in pixels
--- Titan uses a tolerance setting to prevent endless updating of the text width.
local function TitanPanelButton_SetTextButtonWidth(id, setButtonWidth)
	if (id) then
		local button = TitanUtils_GetButton(id)
		if button then
			local text = _G[button:GetName() .. TITAN_PANEL_TEXT];
			if (setButtonWidth
					or button:GetWidth() == 0
					or button:GetWidth() - text:GetWidth() > TITAN_PANEL_BUTTON_WIDTH_CHANGE_TOLERANCE
					or button:GetWidth() - text:GetWidth() < -TITAN_PANEL_BUTTON_WIDTH_CHANGE_TOLERANCE) then
				button:SetWidth(text:GetWidth());
				TitanPanelButton_Justify();
			end
		else
			-- no plugin registered, be silent
		end
	else
		-- no plugin received, be silent
	end
end

---local Set the width of the given Titan plugin - icon only.
---@param id string Plugin id
--- Wrap up by (re)drawing the plugins on the Bar.
--- Titan uses a tolerance setting to prevent endless updating of the text width.
local function TitanPanelButton_SetIconButtonWidth(id)
	if (id) then
		local button = TitanUtils_GetButton(id)
		if button and (TitanUtils_GetPlugin(id).iconButtonWidth) then
			button:SetWidth(TitanUtils_GetPlugin(id).iconButtonWidth);
		else
			-- no plugin registered, be silent
		end
	else
		-- no plugin received, be silent
	end
end

---local Set the width of the given Titan plugin - combo icon & text.
---@param id string Plugin id
---@param setButtonWidth? integer Width in pixels; default to .registry.iconWidth
--- Wrap up by (re)drawing the plugins on the Bar.
--- Titan uses a tolerance setting to prevent endless updating of the text width.
local function TitanPanelButton_SetComboButtonWidth(id, setButtonWidth)
	-- TODO - ensure this routine is proper - need this param?
	-- icon width default to .registry.iconWidth before getting the actual width
	if (id) then
		local button = TitanUtils_GetButton(id)
		if not button then return end -- sanity check

		local text = _G[button:GetName() .. TITAN_PANEL_TEXT];
		local icon = _G[button:GetName() .. "Icon"];
		local iconWidth, iconButtonWidth, newButtonWidth;

		-- Get icon button width
		iconButtonWidth = 0;
		if (TitanUtils_GetPlugin(id).iconButtonWidth) then
			iconButtonWidth = TitanUtils_GetPlugin(id).iconButtonWidth;
		elseif (icon:GetWidth()) then
			iconButtonWidth = icon:GetWidth();
		end

		if (TitanGetVar(id, "ShowIcon") and (iconButtonWidth ~= 0)) then
			icon:Show();
			text:ClearAllPoints();
			text:SetPoint("LEFT", icon:GetName(), "RIGHT", 2, 1);

			newButtonWidth = text:GetWidth() + iconButtonWidth;
		else
			icon:Hide();
			text:ClearAllPoints();
			text:SetPoint("LEFT", button:GetName(), "LEFT", 0, 1);

			newButtonWidth = text:GetWidth();
		end

		if (setButtonWidth
				or button:GetWidth() == 0
				or button:GetWidth() - newButtonWidth > TITAN_PANEL_BUTTON_WIDTH_CHANGE_TOLERANCE
				or button:GetWidth() - newButtonWidth < -TITAN_PANEL_BUTTON_WIDTH_CHANGE_TOLERANCE)
		then
			button:SetWidth(newButtonWidth);
			TitanPanelButton_Justify();
		end
	end
end

---API Update the display of the given Titan plugin.
---@param id string Plugin id
---@param setButtonWidth? integer Width in pixels
--- Use after any change to icon, label, or text (depending on Titan template used)
--- TitanPanelButton_UpdateButton(TITAN_CLOCK_ID)
function TitanPanelButton_UpdateButton(id, setButtonWidth)
	--	Used by plugins
	local plugin = TitanUtils_GetPlugin(id)
	-- safeguard to avoid errors
	if plugin and TitanUtils_IsPluginRegistered(id) then
		if (TitanPanelButton_IsText(id)) then
			-- Update textButton
			TitanPanelButton_SetButtonText(id);
			TitanPanelButton_SetTextButtonWidth(id, setButtonWidth);
		elseif (TitanPanelButton_IsIcon(id)) then
			-- Update iconButton
			TitanPanelButton_SetButtonIcon(id, (plugin.iconCoords or nil),
				(plugin.iconR or nil), (plugin.iconG or nil), (plugin.iconB or nil)
			);
			TitanPanelButton_SetIconButtonWidth(id);
		elseif (TitanPanelButton_IsCombo(id)) then
			-- Update comboButton
			TitanPanelButton_SetButtonText(id);
			TitanPanelButton_SetButtonIcon(id, (plugin.iconCoords or nil),
				(plugin.iconR or nil), (plugin.iconG or nil), (plugin.iconB or nil)
			);
			TitanPanelButton_SetComboButtonWidth(id, setButtonWidth);
		end
	else
		return
	end
end

---API Update the tooltip of the given Titan plugin.
---@param self table Plugin frame
function TitanPanelButton_UpdateTooltip(self)
	if not self then return end
	if (GameTooltip:IsOwned(self)) then
		local id = TitanUtils_GetButtonID(self:GetName());

		TitanPanelButton_SetTooltip(self);
	end
end

---API Refresh the display of the passed in Titan plugin.
---@param table table | string Either {plugin id, action} OR plugin id
---@param oldarg string? action OR nil
--- This is used by some plugins. It is not used within Titan.
--- Action :
--- 1 = refresh button
--- 2 = refresh tooltip
--- 3 = refresh button and tooltip
function TitanPanelPluginHandle_OnUpdate(table, oldarg)
	--- This is used by some plugins.
	local id, updateType = nil, nil
	-- set the id and updateType
	-- old method
	if table and type(table) == "string" and oldarg then
		id = table
		updateType = oldarg
	end
	-- new method
	if table and type(table) == "table" then
		if table[1] then id = table[1] end
		if table[2] then updateType = table[2] end
	end

	-- id is required
	if id then
		if updateType == TITAN_PANEL_UPDATE_BUTTON
			or updateType == TITAN_PANEL_UPDATE_ALL then
			TitanPanelButton_UpdateButton(id)
		end

		if (updateType == TITAN_PANEL_UPDATE_TOOLTIP
				or updateType == TITAN_PANEL_UPDATE_ALL)
			and MouseIsOver(_G[TitanUtils_ButtonName(id)]) then
			if TitanPanelRightClickMenu_IsVisible() or TITAN_PANEL_MOVING == 1 then
				return
			end

			TitanPanelButton_SetTooltip(_G[TitanUtils_ButtonName(id)])
		end
	end
end

---Titan Poorly named routine that sets the OnDragStart & OnDragStop scripts of a Titan plugin.
---@param id string Plugin id
function TitanPanelDetectPluginMethod(id)
	-- Ensure the id is not nil
	if not id then return end
	local TitanPluginframe = _G[TitanUtils_ButtonName(id)];
	-- Ensure the frame is valid
	if not TitanPluginframe and TitanPluginframe:GetName() then return end -- sanity check...

	-- Set the OnDragStart script
	TitanPluginframe:SetScript("OnDragStart", function(self)
		if not IsShiftKeyDown()
			and not IsControlKeyDown()
			and not IsAltKeyDown() then
			TitanPanelButton_OnDragStart(self);
		end
	end)

	-- Set the OnDragStop script
	TitanPluginframe:SetScript("OnDragStop", function(self)
		TitanPanelButton_OnDragStop(self);
	end)
end

---API Set the icon of the given Titan plugin.
---@param id string Plugin id
---@param iconCoords table? As {left, right, top, bottom}
---@param iconR number? Red (.0. - 1.0)
---@param iconG number? Green (.0. - 1.0)
---@param iconB number? Blue (.0. - 1.0)
--- Using TitanPanelButton_UpdateButton is preferred unless coords are needed
function TitanPanelButton_SetButtonIcon(id, iconCoords, iconR, iconG, iconB)
	if (id and TitanUtils_IsPluginRegistered(id)) then
		local button = TitanUtils_GetButton(id)
		if button then
			local icon = _G[button:GetName() .. "Icon"];
			local iconTexture = TitanUtils_GetPlugin(id).icon;
			local iconWidth = TitanUtils_GetPlugin(id).iconWidth;

			if (iconTexture) and icon then
				icon:SetTexture(iconTexture);
			end
			if (iconWidth) and icon then
				icon:SetWidth(iconWidth);
			end

			-- support for iconCoords, iconR, iconG, iconB attributes
			if iconCoords and icon then
				icon:SetTexCoord(unpack(iconCoords))
			end
			if iconR and iconG and iconB and icon then
				icon:SetVertexColor(iconR, iconG, iconB)
			end
		else
			-- plugin not registered
		end
	end
end

---Titan Get the type of the given Titan plugin.
--- This assumes that the developer is playing nice and is using the Titan templates as is...
---@param id string Plugin id name
---@return integer type (text-1, icon-2, combo-3 (default))
function TitanPanelButton_GetType(id)
	-- This assumes that the developer is playing nice and is using the Titan templates as is...
	-- id is required
	local type = 0 -- unknown
	if id then
		local button = TitanUtils_GetButton(id);
		if button then
			local text = _G[button:GetName() .. TITAN_PANEL_TEXT];
			local icon = _G[button:GetName() .. "Icon"];

			if (text and icon) then
				type = TITAN_PANEL_BUTTON_TYPE_COMBO;
			elseif (text and not icon) then
				type = TITAN_PANEL_BUTTON_TYPE_TEXT;
			elseif (not text and icon) then
				type = TITAN_PANEL_BUTTON_TYPE_ICON;
			elseif (not text and not icon) then
				type = TITAN_PANEL_BUTTON_TYPE_CUSTOM;
			end
		else
			type = TITAN_PANEL_BUTTON_TYPE_COMBO;
		end
	else
		-- no id...
	end

	return type
end

---Titan Apply saved Bar position to the Bar frame.
--- Bit of a sledge hammer; used when loading a profile over the current so the Bars are properly placed.
---@param frame_str string Bar frame name
function TitanPanelButton_ApplyBarPos(frame_str)
	--
	local frame = _G[frame_str]
	local bdata = TitanBarData[frame_str]
	if frame then
		frame:ClearAllPoints();
		if bdata.user_move then
			local x, y, w = TitanVariables_GetBarPos(frame_str)
			frame:SetPoint(bdata.show.pt, bdata.show.rel_fr, bdata.show.rel_pt, x, y)
		else
			-- full bar, ignore
		end
	end
end

---Titan Loads the Backdrop for TitanOptionsSliderTemplate with new 9.0 API
---@param self table Control frame
function TitanOptionsSliderTemplate_OnLoad(self)
	self:SetBackdrop({
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true,
		insets = {
			left = 6,
			right = 6,
			top = 3,
			bottom = 3,
		},
		tileSize = 8,
		edgeSize = 8,
	})
end
