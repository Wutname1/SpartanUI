--[===[ File
Contains the routines of AutoHide Titan plugin to auto hide a Titan bar.

Auto hide uses a data driven approach. Rather than seperate routines for each bar, auto hide is implemented in a general manner. 
The table TitanBarData hold relevant data needed to control auto hide. 

If auto hide is turned on these routines will show / hide the proper bar (and plugins on the bar).
These routines control the 'push pin' on each bar, if shown.

The hider bar is a 1/2 height bar used to catch the mouse over to show the bar again.

For documentation, this is treated as a Titan plugin
--]===]
local AceTimer = LibStub("AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local Dewdrop = nil
if AceLibrary and AceLibrary:HasInstance("Dewdrop-2.0") then Dewdrop = AceLibrary("Dewdrop-2.0") end

-- local routines

---local Set the icon for the plugin.
---@param self table Titan bar frame
local function Titan_AutoHide_SetIcon(self)
	local frame_auto_hide = self:GetName()
	local icon = _G[frame_auto_hide.."Icon"]
	local short = self.registry.short_name
	local bar = TitanVariables_GetFrameName(short)

	-- Get the icon of the icon template
	if TitanBarDataVars[bar].auto_hide then
		icon:SetTexture("Interface\\AddOns\\Titan\\Artwork\\TitanPanelPushpinOut")
	else
		icon:SetTexture("Interface\\AddOns\\Titan\\Artwork\\TitanPanelPushpinIn")
	end	
end

---local Create tooltip text
---@param self table Titan bar frame
---@return string toolt_tip
local function GetTooltipText(self)
	local returnstring = ""
	if self.registry.titan_bar then
		if TitanBarDataVars[self.registry.titan_bar].auto_hide then
			returnstring = L["TITAN_PANEL_MENU_ENABLED"]
		else
			returnstring = L["TITAN_PANEL_MENU_DISABLED"]
		end
	else
		-- do nothing
	end

	return returnstring
end

---Titan Initialize the Titan full bar
---@param frame string Titan bar name
function Titan_AutoHide_Init(frame)
	if _G[frame] then -- sanity check
		local bar = TitanBarData[frame].name

		-- Make sure the bar should be processed
		if TitanBarDataVars[frame].show then
			-- Hide / show the bar 
			if TitanBarDataVars[frame].auto_hide then
				TitanPanelBarButton_Hide(frame);
			else
				TitanPanelBarButton_Show(frame);
			end
		else
			TitanPanelBarButton_Hide(frame);
		end
		if TitanBarData[frame].hider then
			Titan_AutoHide_SetIcon(_G[AUTOHIDE_PREFIX..bar..AUTOHIDE_SUFFIX])
		else
			-- No auto hide
		end
	else
		-- sanity check, do nothing
	end
end

---Titan Toggle the user requested show / hide setting then show / hide given bar
---@param bar string
function Titan_AutoHide_ToggleAutoHide(bar)
	local frame_str  = TitanVariables_GetFrameName(bar)

	-- toggle the correct auto hide variable
	TitanBarDataVars[frame_str].auto_hide = not TitanBarDataVars[frame_str].auto_hide
	-- Hide / show the requested Titan bar
	Titan_AutoHide_Init(frame_str)
end

-- Event handlers

---local Setup the plugin on the given bar.
---@param self table Titan bar frame
local function Titan_AutoHide_OnLoad(self)
	local frame = self:GetName()
	local bar = self.short_name

	self.registry = {
		id = "AutoHide_"..bar,
		category = "Built-ins",
		version = TITAN_VERSION,
		menuText = "AutoHide_"..bar,
		tooltipTitle = L["TITAN_PANEL_AUTOHIDE_TOOLTIP"],
		tooltipTextFunction = GetTooltipText,
		savedVariables = {
			DisplayOnRightSide = 1,
			ForceBar = bar,
		},
		-- Based on ForceBar, pass the Titan bar to the tooltip routine
		short_name = bar,
		titan_bar = TitanVariables_GetFrameName(bar)
	};
end

---local Show the plugin on the given bar.
---@param self table Titan bar frame
local function Titan_AutoHide_OnShow(self)
	Titan_AutoHide_SetIcon(self)	
end

---local Handle button clicks on the given bar.
---@param self table Titan bar frame
---@param button string mouse button name
local function Titan_AutoHide_OnClick(self, button)
	if (button == "LeftButton") then
		Titan_AutoHide_ToggleAutoHide(self.registry.short_name);
	end
end

---Titan Hide the bar if the user has auto hide after the cursor leaves the display bar.
---@param frame string Titan bar name
function Handle_OnUpdateAutoHide(frame)
	if TitanPanelRightClickMenu_IsVisible()
	or (Tablet20Frame and Tablet20Frame:IsVisible())
	or (Dewdrop and Dewdrop:IsOpen())then
		return
	end

	local data = TitanBarData[frame] or nil
	if not data then -- sanity check
		return
	end

	local hide = TitanBarDataVars[frame].auto_hide
	if hide then
---@diagnostic disable-next-line: param-type-mismatch
		AceTimer.CancelAllTimers(frame)
		TitanPanelBarButton_Hide(frame)
	end
end

-- Auto hide routines

---Titan This routine accepts the display bar frame and whether the cursor is entering or leaving. On enter kill the timers that are looking to hide the bar. On leave start the timer to hide the bar.
---@param frame? string Titan bar name
---@param action string "Enter" | "Leave"
function Titan_AutoHide_Timers(frame, action)
	if not frame or not action then
		return
	end
	local bar = TitanBarData[frame].name
	local hide = TitanBarDataVars[frame].auto_hide

	if bar and hide then
		if (action == "Enter") then
---@diagnostic disable-next-line: param-type-mismatch
				AceTimer.CancelAllTimers(frame)
		end
		if (action == "Leave") then
			-- pass the bar as an arg so we can get it back
---@diagnostic disable-next-line: param-type-mismatch
			AceTimer.ScheduleRepeatingTimer(frame, Handle_OnUpdateAutoHide, 0.5, frame)
		end
	end
end
---local Create the 'push pin' for the given full bar
---@param bar string Titan full bar short name
---@param f  table Titan bar frame
local function Create_Hide_Button(bar, f)
	local name = AUTOHIDE_PREFIX..bar..AUTOHIDE_SUFFIX
	local plugin = CreateFrame("Button", name, f, "TitanPanelIconTemplate")
	plugin:SetFrameStrata("FULLSCREEN")

	plugin.short_name = bar -- set the short bar name for the .registry

	-- Using SetScript("OnLoad",   does not work
	Titan_AutoHide_OnLoad(plugin);
--	TitanPanelButton_OnLoad(plugin); -- Titan XML template calls this...

plugin:SetScript("OnShow", function(self)
		Titan_AutoHide_OnShow(self)
	end)
	plugin:SetScript("OnClick", function(self, button)
		Titan_AutoHide_OnClick(self, button);
		TitanPanelButton_OnClick(self, button);
	end)
end

---local Create all the hide button / 'push pins' for user
local function Titan_AutoHide_Create_Frames()
	-- general container frame as a parent
	local f = CreateFrame("Frame", nil, UIParent)

	Create_Hide_Button("Bar", f)
	Create_Hide_Button("Bar2", f)
	Create_Hide_Button("AuxBar2", f)
	Create_Hide_Button("AuxBar", f)
end

Titan_AutoHide_Create_Frames() -- do the work
