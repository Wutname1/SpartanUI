---@diagnostic disable: duplicate-set-field
--[===[ File
Contains the basic routines of Titan.
All the event handler routines, initialization routines, Titan menu routines, and select plugin handler routines.
--]===]

-- Locals
local TPC = TITAN_PANEL_CONSTANTS -- shortcut
local TITAN_PANEL_BUTTONS_INIT_FLAG = nil;

local _G = _G --getfenv(0);
local InCombatLockdown = _G.InCombatLockdown;
local IsTitanPanelReset = nil;

-- Library references
local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local AceTimer = LibStub("AceTimer-3.0")
local media = LibStub("LibSharedMedia-3.0")

--	TitanDebug (cmd.." : "..p1.." "..p2.." "..p3.." "..#cmd_list)

--------------------------------------------------------------
--

---Titan Give the user an are you sure popup whether to reload the UI or not.
function TitanPanel_OkToReload()
	StaticPopupDialogs["TITAN_RESET_RELOAD"] = {
		text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"])
			.. "\n\n" .. L["TITAN_PANEL_RESET_WARNING"],
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			ReloadUI()
		end,
		showAlert = 1,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	};
	StaticPopup_Show("TITAN_RESET_RELOAD");
end

---Titan Give the user a 'are you sure' popup whether to reset current toon back to default Titan settings.
function TitanPanel_ResetToDefault()
	StaticPopupDialogs["TITAN_RESET_BAR"] = {
		text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"])
			.. "\n\n" .. L["TITAN_PANEL_RESET_WARNING"],
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			TitanVariables_UseSettings(TitanSettings.Player, TITAN_PROFILE_RESET);
			IsTitanPanelReset = true;
			ReloadUI()
		end,
		showAlert = 1,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1
	};
	StaticPopup_Show("TITAN_RESET_BAR");
end

---Titan The user wants to save a custom Titan profile. Show the user the dialog boxes to make it happen.
--- The profile is written to the Titan saved variables. A reload of the UI is needed to ensure the profile is written to disk for the user to load later.
function TitanPanel_SaveCustomProfile()
	-- Create the dialog box code we'll need...

	---helper to get the edit box depending on expansion API
	---@param self table
	---@return table
	local function GetBox(self)
		if self.editBox then
			-- Older version of API
			return self.editBox
		else
			return self:GetEditBox()
		end
	end

	-- helper to actually write the profile to the Titan saved vars
	local function Write_profile(name)
		local currentprofilevalue, _, _ = TitanUtils_GetPlayer()
		local profileName = TitanUtils_CreateName(name, TITAN_CUSTOM_PROFILE_POSTFIX)
		TitanSettings.Players[profileName] =
			TitanSettings.Players[currentprofilevalue]
		TitanPrint(L["TITAN_PANEL_MENU_PROFILE_SAVE_PENDING"]
			.. "'" .. name .. "'"
			, "info")
	end
	-- helper to ask the user to overwrite a profile
	local function Overwrite_profile(name)
		local dialogFrame =
			StaticPopup_Show("TITAN_OVERWRITE_CUSTOM_PROFILE", name);
		if dialogFrame then
			dialogFrame.data = name;
		end
	end
	-- helper to handle getting the profile name from the user
	local function Get_profile_name(self)
		local rawprofileName = GetBox(self):GetText();
		-- remove any spaces the user may have typed in the name
		local conc2profileName = string.gsub(rawprofileName, " ", "");
		if conc2profileName == "" then return; end
		-- no '@' is allowed or it will mess with the Titan profile naming convention
		local concprofileName = string.gsub(conc2profileName, TITAN_AT, "-");
		local profileName = TitanUtils_CreateName(concprofileName, TITAN_CUSTOM_PROFILE_POSTFIX)
		if TitanSettings.Players[profileName] then
			-- Warn the user of an existing profile
			Overwrite_profile(rawprofileName)
			self:Hide();
			return;
		else
			-- Save the requested profile
			Write_profile(rawprofileName)
			self:Hide();
			StaticPopup_Show("TITAN_RELOADUI");
		end
	end
	-- Dialog box to warn the user that the UI will be reloaded
	-- This ensures the profile is written to disk
	StaticPopupDialogs["TITAN_RELOADUI"] = {
		text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"]) .. "\n\n"
			.. L["TITAN_PANEL_MENU_PROFILE_RELOADUI"],
		button1 = "OKAY",
		OnAccept = function(self)
			ReloadUI(); -- ensure profile is written to disk
		end,
		showAlert = 1,
		whileDead = 1,
		timeout = 0,
	};

	-- Dialog box to warn the user that an existing profile will be overwritten.
	StaticPopupDialogs["TITAN_OVERWRITE_CUSTOM_PROFILE"] = {
		text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"]) .. "\n\n"
			.. L["TITAN_PANEL_MENU_PROFILE_ALREADY_EXISTS"],
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self, data)
			Write_profile(data)
			self:Hide();
			StaticPopup_Show("TITAN_RELOADUI");
		end,
		showAlert = 1,
		whileDead = 1,
		timeout = 0,
		hideOnEscape = 1
	};

	-- Dialog box to save the profile.
	StaticPopupDialogs["TITAN_SAVE_CUSTOM_PROFILE"] = {
		text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"]) .. "\n\n"
			.. L["TITAN_PANEL_MENU_PROFILE_SAVE_CUSTOM_TITLE"],
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 20,
		OnAccept = function(self)
			-- self refers to this frame with the Accept button
			Get_profile_name(self)
		end,
		OnShow = function(self)
			GetBox(self):SetFocus();
		end,
		OnHide = function(self)
			GetBox(self):SetText("");
		end,
		EditBoxOnEnterPressed = function(self)
			-- We need to get the parent because self refers to the edit box.
			Get_profile_name(self:GetParent())
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide();
		end,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
		hideOnEscape = 1
	};

	StaticPopup_Show("TITAN_SAVE_CUSTOM_PROFILE");

	-- Can NOT cleanup. Execution does not stop when a dialog box is invoked!
	--	StaticPopupDialogs["TITAN_RELOADUI"] = {}
	--	StaticPopupDialogs["TITAN_OVERWRITE_CUSTOM_PROFILE"] = {}
	--	StaticPopupDialogs["TITAN_SAVE_CUSTOM_PROFILE"] = {}
end

---Titan Set or change the font and font size of text on the Titan bar. This affects ALL plugins.
--- Each registered plugin will have its font updated. Then all plugins will be refreshed to show the new font.
---@param fontname string path to font file
---@param fontsize number in points
function TitanSetPanelFont(fontname, fontsize)
	-- a couple of arg checks to avoid unpleasant things...
	if not fontname then fontname = TPC.FONT_NAME end
	if not fontsize then fontsize = TPC.FONT_SIZE end
	local newfont = media:Fetch("font", fontname)
	for index, id in pairs(TitanPluginsIndex) do
		local button = TitanUtils_GetButton(id)
		if button then
			local buttonText = _G[button:GetName() .. TITAN_PANEL_TEXT];
			if buttonText then
				buttonText:SetFont(newfont, fontsize);
			end
		end
	end
	TitanPanel_RefreshPanelButtons();
end

local function RegisterForEvents()
	-- Need to be careful of regeristering for events that initiate
	-- show / hide of Bars before the Bars can be initialized...
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("CVAR_UPDATE");
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("PLAYER_LOGOUT");

	-- For the pet battle - for now we'll hide the Titan bars...
	-- Cannot seem to move the 'top' part of the pet battle frame.
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("PET_BATTLE_OPENING_START");
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("PET_BATTLE_CLOSE");

	-- Hide Titan bars in combat (global or per bar); may be useful when using Short bars
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("PLAYER_REGEN_ENABLED");
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("PLAYER_REGEN_DISABLED");

	-- User request to hide Top bar(s) in BG or arena; more areas later?
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("ZONE_CHANGED");
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("ZONE_CHANGED_INDOORS");
	_G[TITAN_PANEL_CONTROL]:RegisterEvent("ZONE_CHANGED_NEW_AREA");
end

--------------------------------------------------------------
_G[TITAN_PANEL_CONTROL]:RegisterEvent("ADDON_LOADED");
--
-- Event routine : redirects to TitanPanelBarButton:<registered event> routines below.
_G[TITAN_PANEL_CONTROL]:SetScript("OnEvent", function(_, event, ...)
	_G[TITAN_PANEL_CONTROL][event](_G[TITAN_PANEL_CONTROL], ...)
end)

local function RegisterAddonCompartment()
	if AddonCompartmentFrame then
		AddonCompartmentFrame:RegisterAddon(
			{
			text = TITAN_ID,
			icon = "Interface\\Icons\\Achievement_Dungeon_UlduarRaid_Titan_01",
			notCheckable = true,
			func = function(button, menuInputData, menu)
				TitanUpdateConfig("init")
				Settings.OpenToCategory(TITAN_PANEL_CONFIG.topic.About)
				end,
			funcOnEnter = function(button)
				MenuUtil.ShowTooltip(button, function(tooltip)
					local msg = ""
						..L["TITAN_PANEL"]
						.." "..L["TITAN_PANEL_MENU_CONFIGURATION"]
					tooltip:SetText(msg)
				end)
			end,
			funcOnLeave = function(button)
				MenuUtil.HideTooltip(button)
			end,
			}
		)
	else
	end
end

---Titan Do all the setup needed when a user logs in / reload UI / enter or leave an instance.
--- This is called after the 'player entering world' event is fired by Blizz.
--- This is also called when a LDB plugin is created after Titan runs the 'player entering world' code.
--- The common code section will setup this toon's info
--- 1) Register any plugins
--- 2) Load the plugin vars (UseSettings)
--- 3) Update the Titan config
--- 4) Set the Titan vars
--- 5) Load / register any LDB plugins into Titan
---@param reload boolean true if reload; false if character 'first' enter
function TitanPanel_PlayerEnteringWorld(reload)
	if Titan__InitializedPEW then
		-- Currently no additional steps needed
	else
		Titan_Global.dbg:Out("Tooltip", "PEW: Init settings")

		-- Get Profile and Saved Vars
		TitanVariables_InitTitanSettings();
		if TitanAllGetVar("Silenced") then
			-- No header output
		else
			TitanPrint("", "header")
		end

		if not ServerTimeOffsets then
			ServerTimeOffsets = {};
		end
		if not ServerHourFormat then
			ServerHourFormat = {};
		end

		-- Set the two anchors in their default positions
		-- until the Titan bars are drawn
		Titan_Global.dbg:Out("Tooltip", "PEW: Create anchors for other addons")
		TitanPanelTopAnchor:ClearAllPoints();
		TitanPanelTopAnchor:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 0, 0);
		TitanPanelBottomAnchor:ClearAllPoints();
		TitanPanelBottomAnchor:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 0, 0);

		-- Ensure the bars are created before the plugins are registered.
		Titan_Global.dbg:Out("Tooltip", "PEW: Create frames for Titan bars")
		for idx, v in pairs(TitanBarData) do
			Titan_Global.dbg:Out("Tooltip", "... ".. tostring(v.name))

			TitanPanelButton_CreateBar(idx)
		end
		--		Titan_AutoHide_Create_Frames()

		-- Add to Addon Compartment, if feature is present
		RegisterAddonCompartment()

		-- Set clock vars based on user setting
		if TitanPlugins["Clock"] then
			local realmName = GetRealmName()
			if ServerTimeOffsets[realmName] then
				TitanSetVar("Clock", "OffsetHour", ServerTimeOffsets[realmName])
			elseif TitanGetVar("Clock", "OffsetHour") then
				ServerTimeOffsets[realmName] = TitanGetVar("Clock", "OffsetHour")
			end

			if ServerHourFormat[realmName] then
				TitanSetVar("Clock", "Format", ServerHourFormat[realmName])
			elseif TitanGetVar("Clock", "Format") then
				ServerHourFormat[realmName] = TitanGetVar("Clock", "Format")
			end
		end

		-- Should be safe to register for events that could show / hide Bars
		Titan_Global.dbg:Out("Tooltip", "PEW: Register for events Titan needs")
		RegisterForEvents()
	end

	--====== Common code login versus reload / portal / ...

	local _ = nil
	TitanSettings.Player, _, _ = TitanUtils_GetPlayer()

	-- Some addons wait to create their LDB component or a Titan addon could
	-- create additional buttons as needed.
	Titan_Global.dbg:Out("Tooltip", "PEW: Register any plugins found")
	TitanUtils_RegisterPluginList()
	Titan_Global.dbg:Out("Tooltip", "> PEW: Register any plugins done")

	-- Now sync saved variables to the profile chosen by the user.
	-- This will set the bar(s) and enabled plugins (via OnShow).
	Titan_Global.dbg:Out("Tooltip", "PEW: Synch plugin saved vars")
	TitanVariables_UseSettings(nil, TITAN_PROFILE_INIT)

	Titan_Global.dbg:Out("Tooltip", "PEW: Init config data (right click menu)")
	-- all addons are loaded so update the config (options)
	-- some could have registered late...
	TitanUpdateConfig("init")

	-- Init panel font
	local isfontvalid = media:IsValid("font", TitanPanelGetVar("FontName"))
	if isfontvalid then
		TitanSetPanelFont(TitanPanelGetVar("FontName"), TitanPanelGetVar("FontSize"))
	else
		-- if the selected font is not valid, revert to default (Friz Quadrata TT)
		TitanPanelSetVar("FontName", TPC.FONT_NAME);
		TitanSetPanelFont(TPC.FONT_NAME, TitanPanelGetVar("FontSize"))
	end

	-- Init panel frame strata
	TitanVariables_SetPanelStrata(TitanPanelGetVar("FrameStrata"))

	-- Titan Panel has initialized its variables and registered plugins.
	-- Allow Titan - and others - to adjust the bars
	Titan__InitializedPEW = true

	-- Move frames
	if Titan_Global.switch.can_edit_ui then
		-- No need
	else
		TitanMovable_SecureFrames()
		TitanPanel_AdjustFrames(true, "_PlayerEnteringWorld")
	end

	-- Loop through the LDB objects to sync with their created Titan plugin
	Titan_Global.dbg:Out("Tooltip", "PEW: Register any LDB (Titan) plugins")
	TitanLDBRefreshButton()
	Titan_Global.dbg:Out("Tooltip", "> PEW: Register any LDB (Titan) plugins done")

	Titan_Global.dbg:Out("Tooltip", "PEW: Titan processing done")
end

--------------------------------------------------------------
--
-- Event handlers
--
--[===[
		local WoWClassicEra, WoWClassicTBC, WoWWOTLKC, WoWRetail
		if wowversion < 20000 then
			WoWClassicEra = true
		elseif wowversion < 30000 then
			WoWClassicTBC = true
		elseif wowversion < 40000 then
			WoWWOTLKC = true
		elseif wowversion > 90000 then
			WoWRetail = true
		else
			-- n/a
		end
--]===]


---Titan Handle ADDON_LOADED Minimal setup in prep for player login.
function TitanPanelBarButton:ADDON_LOADED(addon)
	if addon == TITAN_ID then
		_G[TITAN_PANEL_CONTROL]:RegisterEvent("PLAYER_ENTERING_WORLD")

		Titan_Global.dbg:Out("Tooltip", "ADDON_LOADED")

		-- Unregister event - saves a few event calls.
		self:UnregisterEvent("ADDON_LOADED");
		self.ADDON_LOADED = nil
	end
end

---Titan Handle PLAYER_ENTERING_WORLD Initialize Titan, set and display Titan bars and plugins.
function TitanPanelBarButton:PLAYER_ENTERING_WORLD(arg1, arg2)
	local call_success = nil
	local ret_val = nil

	Titan_Global.dbg:Out("Tooltip", "Titan PLAYER_ENTERING_WORLD pcall setup routine")

	call_success, -- needed for pcall
	ret_val =  -- actual return values
		pcall(TitanPanel_PlayerEnteringWorld, arg2)
	-- pcall does not allow errors to propagate out. Any error
	-- is returned as text with the success / fail.
	-- Think of it as a try - catch block
	--[[
print("_PlayerEnteringWorld"
.." "..tostring(call_success)..""
)
--]]
	if call_success then
		-- Titan initialized properly
	else
		-- something really bad occured...
		TitanPrint("Titan could not initialize!!!!  Cleaning up...", "error")
		TitanPrint("--" .. ret_val, "error")
		-- Clean up best we can and tell the user to submit a ticket.
		-- This could be the 1st log in or a reload (reload, instance, boat, ...)

		-- Hide the bars. At times they are there but at 0% transparency.
		-- They can be over the Blizz action bars creating havoc.
		TitanPrint("-- Hiding Titan bars...", "warning")
		TitanPanelBarButton_HideAllBars()

		-- Remove the options pages
		TitanUpdateConfig("nuke")
		-- What else to clean up???

		-- raise the error to WoW for display, if display errors is set.
		-- This *must be* the last statement of the routine!
		error(ret_val, 1)
	end
end

---Titan Handle CVAR_UPDATE React to user changed WoW options.
function TitanPanelBarButton:CVAR_UPDATE(cvarname, cvarvalue)
	if cvarname == "USE_UISCALE"
		or cvarname == "WINDOWED_MODE"
		or cvarname == "uiScale" then
		if TitanPlayerSettings and TitanPanelGetVar("Scale") then
			TitanPanel_InitPanelBarButton("CVAR_ " .. tostring(cvarname))
			if Titan_Global.switch.can_edit_ui then
				-- No need
			else
				-- Adjust frame positions
				TitanPanel_AdjustFrames(true, "CVAR_UPDATE Scale")
			end
		end
	end
end

---Titan Handle PLAYER_LOGOUT On logout, set some debug data in saved variables.
function TitanPanelBarButton:PLAYER_LOGOUT()
	if not IsTitanPanelReset then
		-- for debug
		if TitanPanelRegister then
			TitanPanelRegister.ToBe = TitanPluginToBeRegistered
			TitanPanelRegister.ToBeNum = TitanPluginToBeRegisteredNum
			TitanPanelRegister.TitanPlugins = TitanPlugins
		end
	end
	Titan__InitializedPEW = false
end

---Titan Handle ZONE_CHANGED_INDOORS Hide Titan top bars if user requested to hide Top bar(s) in BG or arena
function TitanPanelBarButton:ZONE_CHANGED()
	TitanPanelBarButton_DisplayBarsWanted("ZONE_CHANGED")
end

---Titan Handle ZONE_CHANGED_INDOORS Hide Titan top bars if user requested to hide Top bar(s) in BG or arena
function TitanPanelBarButton:ZONE_CHANGED_INDOORS()
	TitanPanelBarButton_DisplayBarsWanted("ZONE_CHANGED_INDOORS")
end

---Titan Handle ZONE_CHANGED_INDOORS Hide Titan top bars if user requested to hide Top bar(s) in BG or arena
function TitanPanelBarButton:ZONE_CHANGED_NEW_AREA()
	TitanPanelBarButton_DisplayBarsWanted("ZONE_CHANGED_NEW_AREA")
end

---Titan Handle PET_BATTLE_CLOSE Hide Titan bars during pet battle.
function TitanPanelBarButton:PET_BATTLE_OPENING_START()
	TitanPanelBarButton_DisplayBarsWanted("PET_BATTLE_OPENING_START")
end

---Titan Handle PET_BATTLE_CLOSE Show Titan bars hidden bars during pet battle.
function TitanPanelBarButton:PET_BATTLE_CLOSE()
	TitanPanelBarButton_DisplayBarsWanted("PET_BATTLE_CLOSE")
end

local in_combat = false -- seems InCombatLockdown may not be set fast enough to reliably hide bars...

---Titan Handle PLAYER_REGEN_ENABLED Titan bars may be hidden during combat.
--- Use local in_combat - seems InCombatLockdown() may not be set fast enough to reliably hide bars...
function TitanPanelBarButton:PLAYER_REGEN_ENABLED()
	in_combat = false
	TitanPanelBarButton_DisplayBarsWanted("PLAYER_REGEN_ENABLED")

	if Titan_Global.switch.can_edit_ui then
		-- No need
	else
		-- Adjust frame positions
		TitanPanel_AdjustFrames(false, "PLAYER_REGEN_ENABLED")
	end
end

---Titan Handle PLAYER_REGEN_DISABLED Titan bars may have been hidden during combat.
--- Use local in_combat - seems InCombatLockdown() may not be set fast enough to reliably hide bars...
function TitanPanelBarButton:PLAYER_REGEN_DISABLED()
	in_combat = true
	TitanPanelBarButton_DisplayBarsWanted("PLAYER_REGEN_DISABLED")
end

if Titan_Global.switch.can_edit_ui then
	-- Do not need to adjust frames
else
	function TitanPanelBarButton:ACTIVE_TALENT_GROUP_CHANGED()
		-- Is this needed??
		--	TitanMovable_AdjustTimer("DualSpec")
	end

	function TitanPanelBarButton:UNIT_ENTERED_VEHICLE(self, ...)
		TitanUtils_CloseAllControlFrames();
		TitanUtils_CloseRightClickMenu();

		-- Needed because 8.0 made changes to the menu bar processing (see TitanMovable)
		TitanMovable_MenuBar_Disable()
	end

	function TitanPanelBarButton:UNIT_EXITED_VEHICLE(self, ...)
		-- A combat check will be done inside the adjust
		TitanPanel_AdjustFrames(true, "UNIT_ENTERED_VEHICLE")
	end

	--]]
	--
end

---Titan Handle the button clicks on any Titan bar.
--- This only reacts to the right or left mouse click without modifiers.
--- Used in the set script for the Titan display and hider frames
---@param self table Titan bar frame
---@param button string Button clicked
function TitanPanelBarButton_OnClick(self, button)
	-- ensure that the right-click menu will not appear on "hidden" bottom bar(s)
	if (button == "LeftButton") then
		TitanUtils_CloseAllControlFrames();
		TitanUtils_CloseRightClickMenu();
	elseif (button == "RightButton") then
		TitanUtils_CloseAllControlFrames();
		TitanPanelRightClickMenu_Close();
		-- Show RightClickMenu anyway
		TitanPanelRightClickMenu_Toggle(self)
	end
end

--
-- Slash command handler
--


---local Helper to parse the user commands from Chat.
---@param cmd any
---@return table cmds List of 'words' user typed
--- each 'word' is made lower case for comparison simplicity
local function TitanPanel_ParseSlashCmd(cmd)
	local words = {}
	for w in string.gmatch(cmd, "%w+") do
		words[#words + 1] = (w and string.lower(w) or "?")
	end
	--[[
	local tmp = ""
	for idx,v in pairs (words) do
		tmp = tmp.."'"..words[idx].."' "
	end

	TitanDebug (tmp.." : "..#words)
--]]
	return words
end

---local Helper to tell the user the relevant Titan help commands.
---@param cmd string? 'all' default | 'reset' | 'gui' | 'silent'
local function handle_slash_help(cmd)
	cmd = cmd or "all"

	--	Give the user the general help if we can not figure out what they want
	TitanPrint("", "header")
	-- Cannot count registered plugins after initial registration  TitanUtils_RegisterPluginList()

	if cmd == "reset" then
		TitanPrint(L["TITAN_PANEL_SLASH_RESET_0"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_RESET_1"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_RESET_2"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_RESET_3"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_RESET_4"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_RESET_5"], "plain")
	end
	if cmd == "gui" then
		TitanPrint(L["TITAN_PANEL_SLASH_GUI_0"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_GUI_1"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_GUI_2"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_GUI_3"], "plain")
	end
	if cmd == "profile" then
		TitanPrint(L["TITAN_PANEL_SLASH_PROFILE_0"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_PROFILE_1"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_PROFILE_2"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_PROFILE_3"], "plain")
	end
	if cmd == "silent" then
		TitanPrint(L["TITAN_PANEL_SLASH_SILENT_0"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_SILENT_1"], "plain")
	end
	if cmd == "orderhall" then
		TitanPrint(L["TITAN_PANEL_SLASH_ORDERHALL_0"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_ORDERHALL_1"], "plain")
	end
	if cmd == "help" then
		TitanPrint(L["TITAN_PANEL_SLASH_HELP_0"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_HELP_1"], "plain")
	end
	if cmd == "all" then
		TitanPrint(L["TITAN_PANEL_SLASH_ALL_0"], "plain")
		TitanPrint(L["TITAN_PANEL_SLASH_ALL_1"], "plain")
	end
end

---local Helper to handle 'reset' commands.
---@param cmd_list table  'tipfont' | 'panelscale' | "spacing" | none - Reset to Titan defaults
local function handle_reset_cmds(cmd_list)
	local cmd = cmd_list[1]
	local p1 = cmd_list[2] or nil
	-- sanity check
	if (not cmd == "reset") then
		return
	end

	if p1 == nil then
		TitanPanel_ResetToDefault();
	elseif p1 == "tipfont" then
		TitanPanelSetVar("TooltipFont", 1);
		GameTooltip:SetScale(TitanPanelGetVar("TooltipFont"));
		TitanPrint(L["TITAN_PANEL_SLASH_RESP1"], "info")
		--[[
	elseif p1 == "tipalpha" then
		TitanPanelSetVar("TooltipTrans", 1);
		local red, green, blue, _ = GameTooltip:GetBackdropColor();
		local red2, green2, blue2, _ = GameTooltip:GetBackdropBorderColor();
		GameTooltip:SetBackdropColor(red,green,blue,TitanPanelGetVar("TooltipTrans"));
		GameTooltip:SetBackdropBorderColor(red2,green2,blue2,TitanPanelGetVar("TooltipTrans"));
		TitanPrint(L["TITAN_PANEL_SLASH_RESP2"], "info")
--]]
	elseif p1 == "panelscale" then
		if not InCombatLockdown() then
			TitanPanelSetVar("Scale", 1);
			TitanPanel_InitPanelBarButton("/panelscale reset ")
			if Titan_Global.switch.can_edit_ui then
				-- No need
			else
				-- Adjust frame positions
				TitanPanel_AdjustFrames(true, "/panelscale reset ")
			end
			TitanPrint(L["TITAN_PANEL_SLASH_RESP3"], "info")
		else
			TitanPrint(L["TITAN_PANEL_MENU_IN_COMBAT_LOCKDOWN"], "warning")
		end
	elseif p1 == "spacing" then
		TitanPanelSetVar("ButtonSpacing", 20);
		TitanPanel_InitPanelButtons();
		TitanPrint(L["TITAN_PANEL_SLASH_RESP4"], "info")
	else
		handle_slash_help("reset")
	end
end

---local Helper to handle 'gui' commands - open Titan options.
---@param cmd_list table
local function handle_giu_cmds(cmd_list)
	local cmd = cmd_list[1]
	local p1 = cmd_list[2] or nil
	-- sanity check
	if (not cmd == "gui") then
		return
	end

	-- DF changed how options are called. The best I get is the Titan 'about', not deeper.
	Settings.OpenToCategory(TITAN_PANEL_CONFIG.topic.About, TITAN_PANEL_CONFIG.topic.scale)
	-- so the below does not work as expected...
end

---local Helper to handle 'profile' commands - Set to profile if not using global profile.
---@param cmd_list table
local function handle_profile_cmds(cmd_list)
	local cmd = cmd_list[1]
	local p1 = cmd_list[2] or nil
	local p2 = cmd_list[3] or nil
	local p3 = cmd_list[4] or nil
	-- sanity check
	if (not cmd == "profile") then
		return
	end

	if p1 == "use" and p2 and p3 then
		if TitanAllGetVar("GlobalProfileUse") then
			TitanPrint(L["TITAN_PANEL_GLOBAL_ERR_1"], "info")
		else
			TitanVariables_UseSettings(TitanUtils_CreateName(p2, p3), TITAN_PROFILE_USE)
		end
	else
		handle_slash_help("profile")
	end
end

---local Helper to handle 'silent' commands - Toggle "Silenced" setting.
---@param cmd_list table
local function handle_silent_cmds(cmd_list)
	local cmd = cmd_list[1]
	-- sanity check
	if (not cmd == "silent") then
		return
	end

	if TitanAllGetVar("Silenced") then
		TitanAllSetVar("Silenced", false);
		TitanPrint(L["TITAN_PANEL_MENU_SILENT_LOAD"] .. " " .. L["TITAN_PANEL_MENU_DISABLED"], "info")
	else
		TitanAllSetVar("Silenced", true);
		TitanPrint(L["TITAN_PANEL_MENU_SILENT_LOAD"] .. " " .. L["TITAN_PANEL_MENU_ENABLED"], "info")
	end
end

---local Helper to handle 'orderhall' commands - Toggle "OrderHall" setting.
---@param cmd_list table
local function handle_orderhall_cmds(cmd_list)
	local cmd = cmd_list[1]
	local p1 = cmd_list[2] or nil
	-- sanity check
	if (not cmd == "orderhall") then
		return
	end

	if TitanAllGetVar("OrderHall") then
		TitanAllSetVar("OrderHall", false);
		TitanPrint(L["TITAN_PANEL_MENU_HIDE_ORDERHALL"] .. " " .. L["TITAN_PANEL_MENU_ENABLED"], "info")
		StaticPopupDialogs["TITAN_RELOAD"] = {
			text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"]) .. "\n\n"
				.. L["TITAN_PANEL_RELOAD"],
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function(self)
				ReloadUI();
			end,
			showAlert = 1,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1
		};
		StaticPopup_Show("TITAN_RELOAD");
	else
		TitanAllSetVar("OrderHall", true);
		TitanPrint(L["TITAN_PANEL_MENU_HIDE_ORDERHALL"] .. " " .. L["TITAN_PANEL_MENU_DISABLED"], "info")
		StaticPopupDialogs["TITAN_RELOAD"] = {
			text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"]) .. "\n\n"
				.. L["TITAN_PANEL_RELOAD"],
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function(self)
				ReloadUI();
			end,
			showAlert = 1,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1
		};
		StaticPopup_Show("TITAN_RELOAD");
	end
end

--[=[ local
DESC: Helper to execute the help commands from the user.
VAR: cmd_list - A table containing the list of 'words' the user typed in
OUT: None
local function handle_help_cmds(cmd_list)
	local cmd = cmd_list[1]
	local p1 = cmd_list[2] or nil
	-- sanity check
	if (not cmd == "help") then
		return
	end

	handle_slash_help(p1 or "all")
end
--]=]

---local Helper to parse and execute all the Titan slash commands from the user.
---@param cmd_str string
local function TitanPanel_RegisterSlashCmd(cmd_str)
	local cmd_list = {}
	-- parse what the user typed
	cmd_list = TitanPanel_ParseSlashCmd(cmd_str)
	local cmd = cmd_list[1] or ""
	local p1 = cmd_list[2] or ""
	local p2 = cmd_list[3] or ""
	local p3 = cmd_list[4] or ""

	if (cmd == "reset") then
		handle_reset_cmds(cmd_list)
	elseif (cmd == "gui") then
		handle_giu_cmds(cmd_list)
	elseif (cmd == "profile") then
		handle_profile_cmds(cmd_list)
	elseif (cmd == "silent") then
		handle_silent_cmds(cmd_list)
	elseif (cmd == "orderhall") then
		handle_orderhall_cmds(cmd_list)
	elseif (cmd == "help") then
		handle_slash_help(p1)
	else
		handle_slash_help("all")
	end
end

--====== Register slash commands for Titan Panel
SlashCmdList["TitanPanel"] = TitanPanel_RegisterSlashCmd;
SLASH_TitanPanel1 = "/titanpanel";
SLASH_TitanPanel2 = "/titan";

--------------------------------------------------------------
--
-- Texture routines


---local Set the Titan bar color per user selection
---@param frame string Titan bar name
---@param tex table Texture frame to set
---@param color table Color - RBGA
local function Set_Color(frame, tex, color)
	--[[
print("_Set bar color"
.." "..tostring(TitanBarData[frame].tex_name)..""
--.." "..tostring(tex:GetName())..""
.." "..tostring(format("%0.1f", color.r))..""
.." "..tostring(format("%0.1f", color.g))..""
.." "..tostring(format("%0.1f", color.b))..""
.." "..tostring(format("%0.1f", color.alpha))..""
)
--]]
	_G[frame]:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		--		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
		--		edgeFile="Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
		edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
		tile = true,
		tileEdge = true,
		--		insets = { left = 1, right = 1, top = 1, bottom = 1 },
		tileSize = 8,
		edgeSize = 8,
	})

	_G[frame]:SetBackdropBorderColor(
		TOOLTIP_DEFAULT_COLOR.r,
		TOOLTIP_DEFAULT_COLOR.g,
		TOOLTIP_DEFAULT_COLOR.b,
		color.alpha); -- 2024 AUg : Border will use the color alpha
	_G[frame]:SetBackdropColor(
		color.r,
		color.g,
		color.b,
		color.alpha);
end

---local Set the Titan bar texture / skin per user selectable options
---@param frame string Titan bar name
---@param tex table Texture frame to set
---@param skin table Skin to use
local function Set_Skin(frame, tex, skin)
	-- skins are in two parts - top & bottom...
	-- TODO : have Short bars choose top or bottom skin??
	local edge = ""
	if TitanBarData[frame].vert == TITAN_BOTTOM
	then
		edge = TITAN_BOTTOM
	else
		edge = TITAN_TOP
	end

	-- Apply the texture to the bar, using the system repeat to fill it
	local texture_file = skin.path .. "TitanPanelBackground" .. edge .. "0"
	--[[
print("_Skin"
.." "..tostring(TitanBarData[frame].tex_name..""
--.." "..tostring(tex:GetName())..""
.." "..tostring(skin.path)..""
--.."\n "..tostring(edge)..""
--.." "..tostring(skin.alpha)..""
--.."\n "..tostring(tex:GetTexture())..""
)
--]]
	--[[ -- appears seeting image this way just smears image...
	_G[frame]:SetBackdrop({
		bgFile=texture_file,
--		edgeFile=nil,
		tile = true,
--		tileSize = 256,
--		tileEdge = true,
--		insets = { left = 1, right = 1, top = 1, bottom = 1 },
--		tileSize = 8,
--		edgeSize = 8,
	})
--]]
	tex:SetAllPoints()
	tex:SetHorizTile(true) -- ensures repeat; 'smears' if not sest to true
	tex:SetTexture(texture_file, "REPEAT")
	tex:SetVertTile(true) -- ensures image is 'full' height of frame
	--	tex:SetHeight(TITAN_PANEL_BAR_TEXTURE_HEIGHT) -- leaves a gap if used
	tex:SetAlpha(skin.alpha)
end

---Titan Set the texture / skin of the bar per the user selection.
---@param frame string Titan bar frame name
function TitanPanel_SetBarTexture(frame)
	if frame and TitanBarData[frame] then
		-- proceed
	else
		return
	end

	-- Create the path & file name to the texture
	local tex = TitanBarData[frame].tex_name
	local titanTexture = {}
	if _G[tex] then
		titanTexture = _G[tex]
	else
		titanTexture = _G[frame]:CreateTexture(tex, "BACKGROUND")
	end
	titanTexture:SetTexture()
	_G[frame]:SetBackdrop({
		bgFile = "",
	})

	--[[
print("_Tex"
.." "..tostring(TitanBarData[frame].name)..""
--.." "..tostring(tex)..""
.." "..tostring(titanTexture:GetName())..""
--.." "..tostring(skin.path)..""
--.."\n "..tostring(edge)..""
--.." "..tostring(skin.alpha)..""
--.."\n "..tostring(tex:GetTexture())..""
.." "..tostring(TitanBarDataVars["Global"].texure)..""
.." "..tostring(TitanBarDataVars[frame].texure)..""
)
--]]
	-- Use the texture / skin per user selectable options
	if TitanBarDataVars["Global"].texure == Titan_Global.SKIN then
		Set_Skin(frame, titanTexture, TitanBarDataVars["Global"].skin) -- tex_path = TitanPanelGetVar("TexturePath")
	elseif TitanBarDataVars["Global"].texure == Titan_Global.COLOR then
		Set_Color(frame, titanTexture, TitanBarDataVars["Global"].color)
	elseif TitanBarDataVars[frame].texure == Titan_Global.SKIN then
		Set_Skin(frame, titanTexture, TitanBarDataVars[frame].skin)
	elseif TitanBarDataVars[frame].texure == Titan_Global.COLOR then
		Set_Color(frame, titanTexture, TitanBarDataVars[frame].color)
	end
end

--------------------------------------------------------------
--
-- auto hide event handlers


---Titan On leaving the display check if we have to hide the Titan bar. A timer is used - when it expires the bar is hidden.
---@param self table Titan bar frame
function TitanPanelBarButton_OnLeave(self)
	local frame = (self and self:GetName() or nil)
	local bar = (TitanBarData[frame] and TitanBarData[frame].name or nil)

	-- if auto hide is active then let the timer hide the bar
	local hide = (bar and TitanBarDataVars[frame].auto_hide or nil)
	--	local hide = (bar and TitanPanelGetVar(bar.."_Hide") or nil)
	if hide then
		Titan_AutoHide_Timers(frame, "Leave")
	end
end

---Titan No code - this is a place holder for the XML template.
---@param self table Titan Hider bar frame
function TitanPanelBarButton_OnEnter(self)
	-- no work to do
end

---Titan No code - this is a place holder for the XML template.
---@param self table Titan Hider bar frame
function TitanPanelBarButtonHider_OnLeave(self)
	-- no work to do
end

---Titan On entering the hider, check if we need to show the display bar.
--- No action is taken if the user is on combat.
---@param self table Titan Hider bar frame
function TitanPanelBarButtonHider_OnEnter(self)
	-- make sure self is valid
	local index = self and self:GetName() or nil
	if not index then return end -- sanity check

	-- so the bar does not 'appear' when moused over in combat
	if TitanPanelGetVar("LockAutoHideInCombat") and InCombatLockdown() then return end

	-- find the relevant bar data
	local frame = nil
	for idx, v in pairs(TitanBarData) do
		if index == TitanBarData[idx].hider then
			frame = idx
		end
	end
	-- Now process that bar
	if frame then
		Titan_AutoHide_Timers(frame, "Enter")
		TitanPanelBarButton_Show(frame)
	end
end

--====== Titan Frames for CLASSIC versions

--
--==========================
-- Routines to handle adjusting some UI frames
--

--[[ Appears unsed...
---Titan Align the buttons per the user's new choice.
---@param align number left or center
function TitanPanelBarButton_ToggleAlign(align)
	-- toggle between left or center
	if (TitanPanelGetVar(align) == TITAN_PANEL_BUTTONS_ALIGN_CENTER) then
		TitanPanelSetVar(align, TITAN_PANEL_BUTTONS_ALIGN_LEFT);
	else
		TitanPanelSetVar(align, TITAN_PANEL_BUTTONS_ALIGN_CENTER);
	end

	-- Justify button position
	TitanPanelButton_Justify();
end
--]]

---Titan Toggle the auto hide of the given Titan bar per the user's new choice.
---@param frame string Frame mame of the Titan bar
function TitanPanelBarButton_ToggleAutoHide(frame)
	local frName = _G[frame]
	local plugin = (TitanBarData[frame] and TitanBarData[frame].auto_hide_plugin or nil)

	if frName then
		Titan_AutoHide_ToggleAutoHide(_G[plugin])
	end
end

---Titan Toggle whether Titan adjusts 'top' frames around Titan bars per the user's new choice.
--- Another addon can tell Titan to NOT adjust some or all frames.
function TitanPanelBarButton_ToggleScreenAdjust()
	-- Turn on / off adjusting of other frames around Titan
	TitanPanelToggleVar("ScreenAdjust");
	TitanPanel_AdjustFrames(true, "_ToggleScreenAdjust")
end

---Titan Toggle whether Titan adjusts 'bottom' frames around Titan bars per the user's new choice.
--- Another addon can tell Titan to NOT adjust some or all frames.
function TitanPanelBarButton_ToggleAuxScreenAdjust()
	-- turn on / off adjusting of frames at the bottom of the screen
	TitanPanelToggleVar("AuxScreenAdjust");
	TitanPanel_AdjustFrames(true, "_ToggleAuxScreenAdjust")
end

--====== Titan Bar
--
--==========================
-- Routines to handle moving and sizing of short bars
--

---local Check the change in width; snap to edge of any part goes off screen.
---@param self table Titan short bar frame
---@param width number New width
---@param reason string Note on why this was called
---@return table result .ok boolean; .err string
local function CheckBarBounds(self, width, reason)
	-- This is a touchy routine - change with care!! :)
	--
	-- Let WoW handle any change in game scale. 
	-- When Titan scaling changes, recalc the bar placement.
	-- Although the user may want to move bars in response to any scale change.
	local trace = false -- true false
	local result = {}
	result.ok = true
	result.err = ""
	local err = ""

	local f_name = self:GetName()
	local bar_name = TitanBarData[f_name].name
	local locale_name = TitanBarData[f_name].locale_name

	if TitanBarData[f_name].user_move
	and TitanBarDataVars[f_name].show
	then
---[[
		if trace then
			print("Bounds"
				.. " " .. tostring(bar_name) .. ""
				.. " " .. tostring(width) .. ""
				.. " " .. tostring(reason) .. ""
			)
		end
--]]

		local tscale = TitanPanelGetVar("Scale")
		local x, y, w, scale = TitanVariables_GetBarPos(f_name)
		local scale_change = false
		if tscale == scale then
			-- no need to use scaling to recalc position
		else
			scale_change = true
			-- The 'set' will update the sacaling for next time
		end
		local screen = TitanUtils_ScreenSize()
		local screen_right_scaled = screen.scaled_x
		local screen_top_scaled = screen.scaled_y
		local screen_right = screen.x
		local screen_top = screen.y
		local screen_right_t = screen.x * tscale
		local screen_top_t = screen.y * tscale

		local bar_left = math.floor(self:GetLeft())
		local bar_right = math.floor(self:GetRight())
		local bar_top = math.floor(self:GetTop())
		local bar_bottom = math.floor(self:GetBottom())

		local orig_w = self:GetWidth() -- * tscale --math.floor(self:GetWidth() * tscale)
		local l_off = bar_left
		local r_off = bar_right
		local t_off = bar_top
		local b_off = bar_bottom
		local hght = (t_off - b_off)

		if scale_change then
			-- Apply the Titan scaling to get 'real' position within WoW window;
			-- Use floor to trunc decimal places where the side could be right on the edge of the screen.
			l_off = math.floor(bar_left * tscale)
			r_off = math.floor(bar_right * tscale)
			t_off = math.floor(bar_top * tscale)
			b_off = math.floor(bar_bottom * tscale)
		else
			-- Just check the bar position
		end
---[[
		if trace then
			print(">Bounds"
				.. " " .. tostring(bar_name) .. ""
				.. "\n"
				.. " L " .. tostring(format("%0.1f", l_off)) .. ""
				.. " R " .. tostring(format("%0.1f", r_off)) .. ""
				.. " T " .. tostring(format("%0.1f", t_off)) .. ""
				.. " B " .. tostring(format("%0.1f", b_off)) .. ""
				.. " W " .. tostring(format("%0.1f", orig_w)) .. ""
				.. " H " .. tostring(format("%0.1f", hght)) .. ""
				.. "\n"
				.. " SR " .. tostring(format("%0.1f", screen_right)) .. ""
				.. " ST " .. tostring(format("%0.1f", screen_top)) .. ""
				.. " SR_t " .. tostring(format("%0.1f", screen_right_t)) .. ""
				.. " ST_t " .. tostring(format("%0.1f", screen_top_t)) .. ""
			)
		end
--]]
		local w = 0
		local x_off = 0
		local y_off = 0
		local w_off = 0

		-- Assume all ok :)
		x_off = l_off
		y_off = b_off

		if (width == 0) then -- drag & drop OR entry / reload
			-- Assumes BOTTOMLEFT of screen per Short bar defaults.
			-- if resolution is not 'pixel perfect' rounding could cause algorithm to think bar is off screen

			-- Keep the width
			w_off = orig_w

			if l_off < 0 then
				x_off = 0
				err = "Off left of screen, snap to edge"
			elseif (r_off) > screen_right then
				x_off = math.floor(screen_right - (r_off - l_off))
				err = "Off right side of screen, snap to edge"
			end
			if err ~= "" then
				result.ok = false
				result.err = err
				if trace then
					TitanPrint(locale_name .. " " .. err .. "!!!!"
					, "warning")
				end
			end
			err = ""
			if (t_off) > screen_top then
				y_off = math.floor(screen_top - (t_off - b_off))
				err = "Off top of screen, snap to edge"
			elseif b_off < 0 then
				y_off = 0
				err = "Off bottom of screen, snap to edge"
			end
			if err ~= "" then
				result.ok = false
				result.err = result.err .. "\n" .. err
				if trace then
					TitanPrint(locale_name .. " " .. err .. "!!!!"
						.. " [" .. tostring(format("%0.1f", x_off)) .. "]"
						.. " [" .. tostring(format("%0.1f", y_off)) .. "]"
						, "warning")
				end
			end
		else -- width change
			local min_w, min_h, max_w, max_h = self:GetResizeBounds()
			-- Keep the X and Y
			local w_new = orig_w + width
			if w_new < min_w then
				-- do nothing - too small
				w_off = min_w
				err = "Width too small. Set to min width."
			elseif w_new > max_w then
				w_off = max_w
				err = "Width too big. Set to max width." -- too wide
			elseif x_off + (w_new * tscale) > screen_right then
				w_off = orig_w
				err = "Off right of screen, snap to edge"
			else
				w_off = w_new
			end

			self:SetSize(w_off, TITAN_PANEL_BAR_HEIGHT)
			--			self:SetWidth(w_off)
		end

		if scale_change then
			-- Back out Titan scaling
			x_off = math.floor(x_off / tscale)
			y_off = math.floor(y_off / tscale)
		else
			-- Accept the results of the checks
		end
		w_off = w_off --/ tscale
		TitanVariables_SetBarPos(self, false, x_off, y_off, w_off)

		if trace then
			print(">>Bounds"
			.. " " .. tostring(bar_name) .. ""
			.. " " .. tostring(result.ok) .. ""
			.. " SC " .. tostring(scale_change) .. ""
			.." X "..tostring(format("%0.1f", x_off)).."("..tostring(bar_left)..")"
			.. " Y " .. tostring(format("%0.1f", y_off)).."("..tostring(bar_bottom)..")"
			.. " W " .. tostring(format("%0.1f", w_off)) .. ""
			)
			if err ~= "" then
				TitanPrint(locale_name .. " " .. err .. "!!!!"
					.. " [" .. tostring(format("%0.1f", x_off)) .. "]"
					.. " [" .. tostring(format("%0.1f", y_off)) .. "]"
					.. " [" .. tostring(format("%0.1f", w_off)) .. "]"
					, "warning")
			end
		end
	else
		-- Controlled with anchor points; cannot move so no check is needed
	end


	return result
end

---local Start the grap of a Short Titan bar if Shift and left mouse are held.
---@param self table
local function OnMoveStart(self)
	if IsShiftKeyDown() then
		if self:IsMovable() then
			self.isMoving = true
			self:StartMoving()
			_G.GameTooltip:Hide()
		end
	else
		-- Do not move
	end
end

---local When a Short Titan bar drag is stopped.
---@param self table
local function OnMovingStop(self)
	self:StopMovingOrSizing()
	self.isMoving = nil

	local res = CheckBarBounds(self, 0, "OnMovingStop")
	if res.ok then
		-- placement ok
	else
		-- Need to 'snap' it to an edge
		TitanPanel_InitPanelBarButton("OnMovingStop")
	end
	-- Seems overkill - this will recalc all bars...
end

---local Change the width of a Short Titan bar when mouse is over the bar and Shift is held when the mouse wheel is used.
---@param self table Frame mouse is over
---@param d integer Mouse wheel direction (1 larger; -1 smaller)
--- Assuming a 1 'click' is a pixel
local function OnMouseWheel(self, d)
	-- Can get noisy, "Initializes" all bars at each click to ensure the bar is drawn.
	if IsShiftKeyDown() then
		local msg = "OnMouseWheel"
		local delta = d
		if IsControlKeyDown() then
			delta = d * 10
			msg = msg.." +Alt"
		else
			-- use 1
		end
		local res = CheckBarBounds(self, delta, msg)
		if res.ok then
		end
		--[[
print("wheel"
.." "..tostring(self:GetName())..""
.." "..tostring(d)..""
.." old: "..tostring(format("%0.1f", old_w))..""
.." new: "..tostring(format("%0.1f", self:GetWidth()))..""
.." ok: "..tostring(res.ok)..""
)
--]]
		--		TitanPanel_InitPanelBarButton("OnMouseWheel")
	end
end

---Titan Force all plugins created from LDB addons, visible or not, to be on the right side of the Titan bar.
--- Any visible plugin will be forced to the right side on the same bar it is currently on.
function TitanPanelBarButton_ForceLDBLaunchersRight()
	local plugin = {}
	for index, id in pairs(TitanPluginsIndex) do
		plugin = TitanUtils_GetPlugin(id);
		if plugin and plugin.ldb == "launcher"
			and not TitanGetVar(id, "DisplayOnRightSide") then
			TitanToggleVar(id, "DisplayOnRightSide");
			local button = TitanUtils_GetButton(id)
			if button then
				local buttonText = _G[button:GetName() .. TITAN_PANEL_TEXT];
				if not TitanGetVar(id, "ShowIcon") then
					TitanToggleVar(id, "ShowIcon");
				end
				TitanPanelButton_UpdateButton(id);
				if buttonText then
					buttonText:SetText("")
					button:SetWidth(16);
					TitanPlugins[id].buttonTextFunction = nil;
					_G[TitanUtils_ButtonName(id) .. TITAN_PANEL_TEXT] = nil;
					if button:IsVisible() then
						local bar = TitanUtils_GetWhichBar(id)
						TitanPanel_RemoveButton(id);
						TitanUtils_AddButtonOnBar(bar, id)
					end
				end
			end
		end
	end
end

---local Helper to create the 'anchor' frames used by other addons that need to adjust so Titan can be visible.
---The anchor frames are adjusted depending on which Titan bars the user selects to show.
--- - TitanPanelTopAnchor - the frame at the bottom of the top bar(s) shown.
--- - TitanPanelBottomAnchor - the frame at the top of the bottom bar(s) shown.
local function TitanAnchors()
	local anchor_top = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_TOP)
	local anchor_bot = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM)
	anchor_top = anchor_top <= TITAN_WOW_SCREEN_TOP and anchor_top or TITAN_WOW_SCREEN_TOP
	anchor_bot = anchor_bot >= TITAN_WOW_SCREEN_BOT and anchor_bot or TITAN_WOW_SCREEN_BOT

	local top_point, top_rel_to, top_rel_point, top_x, top_y = TitanPanelTopAnchor:GetPoint(TitanPanelTopAnchor
		:GetNumPoints())
	local bot_point, bot_rel_to, bot_rel_point, bot_x, bot_y = TitanPanelBottomAnchor:GetPoint(TitanPanelBottomAnchor
		:GetNumPoints())
	top_y = floor(tonumber(top_y) + 0.5)
	bot_y = floor(tonumber(bot_y) + 0.5)
	--[[
TitanDebug("Anc top: "..top_y.." bot: "..bot_y
.." a_top: "..anchor_top.." a_bot: "..anchor_bot
)
--]]
	if top_y ~= anchor_top then
		TitanPanelTopAnchor:ClearAllPoints()
		TitanPanelTopAnchor:SetPoint(top_point, top_rel_to, top_rel_point, top_x, anchor_top);
	end
	if bot_y ~= anchor_bot then
		TitanPanelBottomAnchor:ClearAllPoints()
		TitanPanelBottomAnchor:SetPoint(bot_point, bot_rel_to, bot_rel_point, bot_x, anchor_bot)
	end
end

---Titan Show all the Titan bars the user has selected.
---@param reason string Debug note on where the call initiated
function TitanPanelBarButton_DisplayBarsWanted(reason)
	local trace = false
	if trace then
		print("_DisplayBarsWanted"
			.. " " .. tostring(reason) .. ""
		)
	end

	-- Check all bars to see if the user has requested they be shown
	for idx, v in pairs(TitanBarData) do
		-- Show / hide plus kick auto hide, if needed
		Titan_AutoHide_Init(idx)
	end

	-- Set anchors for other addons to use.
	TitanAnchors()

	if Titan_Global.switch.can_edit_ui then
		-- Not needed with UI movable widgets
	else
		-- Adjust other frames because the bars shown / hidden may have changed
		TitanPanel_AdjustFrames(true, "_DisplayBarsWanted")
	end
end

---Titan This routine will hide all the Titan bars (and hiders) regardless of what the user has selected.
--- For example when the pet battle is active. We cannot figure out how to move the pet battle frame so we are punting and hiding Titan...
--- We only need to hide the bars (and hiders) - not adjust frames
function TitanPanelBarButton_HideAllBars()
	for idx, v in pairs(TitanBarData) do
		TitanPanelBarButton_Hide(idx)
	end
end

---local Show the requested Titan bar.
---@param frame_str string Titan bar
---@return boolean CanShow False if there is a restricting condition
local function showBar(frame_str)
	local flag = true -- only set false for known conditions

	if frame_str == TitanVariables_GetFrameName("Bar")
		or frame_str == TitanVariables_GetFrameName("Bar2")
	then
		-- ===== Battleground or Arena : User selected
		if (TitanPanelGetVar("HideBarsInPVP"))
			and (C_PvP.IsBattleground()
				or C_PvP.IsArena()
			--			or GetZoneText() == "Stormwind City"
			--			or GetZoneText() == "Tempest Keep"
			)
		then
			flag = false
		end
	end

	-- ===== In Combat : User selected
	if TitanBarDataVars[frame_str].hide_in_combat
		or TitanPanelGetVar("HideBarsInCombat") then
		if in_combat then -- InCombatLockdown() too slow
			flag = false
		end
	end

	-- ===== In Pet Battle
	if C_PetBattles and C_PetBattles.IsInBattle() then
		if TitanBarData[frame_str].user_move then
			-- leave as is
		else
			flag = false
		end
	end
	--[[
print("showBar"
--.." "..tostring(C_PetBattles.IsInBattle())..""
.." > "..tostring(flag)..""
.." '"..tostring(frame_str).."'"
)
--]]
	return flag
end

---local Set the position of the requested Titan bar.
---@param frame string Titan bar
local function SetBar(frame)
	local trace = false
	local display = _G[frame];

	local x, y, w = TitanVariables_GetBarPos(frame)
	local tscale = TitanPanelGetVar("Scale")
	local show = TitanBarData[frame].show
	local bott = TitanBarData[frame].bott


	display:ClearAllPoints()
	if trace then
		--		local screen = TitanUtils_ScreenSize()
		--		local sx = screen.scaled_x
		--		local sy = screen.scaled_y
		print("SetBar"
			.. " " .. tostring(TitanBarData[frame].name) .. ""
			.. " x:" .. tostring(format("%0.1f", x)) .. ""
			.. " y:" .. tostring(format("%0.1f", y)) .. ""
			.. " w:" .. tostring(format("%0.1f", w)) .. ""
		)
	end

	if TitanBarData[frame].user_move then
		display:SetPoint(show.pt, show.rel_fr, show.rel_pt, x, y)
		display:SetSize(w, TITAN_PANEL_BAR_HEIGHT)
	else
		display:SetPoint(show.pt, show.rel_fr, show.rel_pt, x, y)
		local h = TITAN_PANEL_BAR_HEIGHT
		display:SetPoint(bott.pt, bott.rel_fr, bott.rel_pt, x, y - h)
	end
end

---Titan Toggle the given Titan bar based on the user selection.
---@param frame string Frame mame of the Titan bar
function TitanPanelBarButton_Show(frame)
	local display = _G[frame];

	if display and TitanBarData[frame].name
	then
		if TitanBarDataVars[frame].show -- User requested
			and showBar(frame)    -- No preventing condition
		then                      -- Place Bar
			SetBar(frame)
			---[[			
			-- The bar may need to be moved back onto the screen.
			local res = CheckBarBounds(display, 0, "_Show the bar")
			if res.ok then
				-- placement ok
			else
				-- Need to 'snap' it to an edge
				SetBar(frame)
			end
			--]]
			TitanPanel_SetBarTexture(frame)

			if TitanBarData[frame].hider then
				_G[TitanBarData[frame].hider]:Hide()
			else
				-- not allowed for this bar
			end
		else
			-- The user has not elected to show this bar
			TitanPanelBarButton_Hide(frame)
		end
	end
end

---Titan Hide the given Titan bar based on the user selection.
--- Hide moves rather than just 'not shown'. Otherwise the buttons will stay visible defeating the purpose of hide.
--- Also moves the hider bar if auto hide is not selected.
---@param frame string Frame mame of the Titan bar
function TitanPanelBarButton_Hide(frame)
	if TITAN_PANEL_MOVING == 1 then return end

	local display = _G[frame]
	local data = TitanBarData[frame]

	if display and data
	then
		local x, y, w = TitanVariables_GetBarPos(frame)
		-- This moves rather than hides. If we just hide then the plugins will still show.
		-- Hide by ensuriing the Y offset is off the screen.
		display:ClearAllPoints()
		local h = (math.abs(y) + TITAN_PANEL_BAR_HEIGHT * 2) * (-1 * y)
		local h = data.hide_y
		--[[
print("_Hide"
--.." "..tostring(frame)..""
.." "..tostring(data.name)..""
.." "..tostring(TitanBarDataVars[frame].show)..""
.." "..tostring(h)..""
)
--]]
		if TitanBarData[frame].user_move then
			display:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, x, h)
		else
			display:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, x, h)
			display:SetPoint(data.bott.pt, data.bott.rel_fr, data.bott.rel_pt, x, h - TITAN_PANEL_BAR_HEIGHT)
		end

		if TitanBarData[frame].hider then
			local hider = _G[data.hider]
			if TitanBarDataVars[frame].show
				and TitanBarDataVars[frame].auto_hide then
				--			if (TitanPanelGetVar(data.name.."_Show")) and (TitanPanelGetVar(data.name.."_Hide")) then
				-- Auto hide is requested so show the hider bar in the right place
				hider:ClearAllPoints();
				hider:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, x, y);
				hider:Show()
			else
				-- The bar was not requested
				hider:Hide()
			end
		else
			-- not allowed for this bar
		end
	end
end

---Titan Show all user selected plugins on the Titan bar(s) then justify per the user selection.
--- This is done an all bars whether shown or not.
function TitanPanel_InitPanelButtons()
	local button
	local r_prior = {}
	local l_prior = {}
	local scale = TitanPanelGetVar("Scale");
	local button_spacing = TitanPanelGetVar("ButtonSpacing") * scale
	local icon_spacing = TitanPanelGetVar("IconSpacing") * scale

	local prior = {}
	-- set prior to the starting offsets
	-- The right side plugins are set here.
	-- Justify adjusts the left side start according to the user setting
	-- The effect is left side plugins has spacing on the right side and
	-- right side plugins have spacing on the left.
	for idx, v in pairs(TitanBarData) do
		local bar = TitanBarData[idx].name
		local y_off = TitanBarData[idx].plugin_y_offset
		prior[bar] = {
			right = {
				button = TitanVariables_GetFrameName(bar),
				anchor = "RIGHT",
				x = 5, -- Offset of first plugin to right side of screen
				y = y_off,
			},
			left = {
				button = TitanVariables_GetFrameName(bar),
				anchor = "LEFT",
				x = 0, -- Justify adjusts - center or not
				y = y_off,
			},
		}
	end
	--
	TitanPanelBarButton_DisplayBarsWanted("TitanPanel_InitPanelButtons");

	-- Position all the buttons
	for idx = 1, table.maxn(TitanPanelSettings.Buttons) do
		local id = TitanPanelSettings.Buttons[idx];
		if (TitanUtils_IsPluginRegistered(id)) then
			local i = TitanPanel_GetButtonNumber(id);
			button = TitanUtils_GetButton(id);

			if button then
				-- If the plugin has asked to be on the right
				if TitanUtils_ToRight(id) then
					-- =========================
					-- position the plugin relative to the prior plugin
					-- or the bar if it is the 1st
					r_prior = prior[TitanPanelSettings.Location[i]].right
					-- =========================
					button:ClearAllPoints();
					button:SetPoint("RIGHT", _G[r_prior.button]:GetName(), r_prior.anchor, (-(r_prior.x) * scale),
						r_prior.y)

					-- =========================
					-- capture the button for the next plugin
					r_prior.button = TitanUtils_ButtonName(id)
					-- set prior[x] the anchor points and offsets for the next plugin
					r_prior.anchor = "LEFT"
					r_prior.x = icon_spacing
					r_prior.y = 0
					-- =========================
				else
					--  handle plugins on the left side of the bar
					--
					-- =========================
					-- position the plugin relative to the prior plugin
					-- or the bar if it is the 1st
					l_prior = prior[TitanPanelSettings.Location[i]].left
					--[===[
print("Bar plugins"
.." "..tostring(i)..""
.." "..tostring(TitanPanelSettings.Location[i])..""
.." "..tostring(id)..""
)
--]===]
					-- =========================
					--
					button:ClearAllPoints();
					button:SetPoint("LEFT", _G[l_prior.button]:GetName(), l_prior.anchor, l_prior.x * scale, l_prior.y);

					-- =========================
					-- capture the next plugin
					l_prior.button = TitanUtils_ButtonName(id)
					-- set prior[x] (anchor points and offsets) for the next plugin
					l_prior.anchor = "RIGHT"
					l_prior.x = (button_spacing)
					l_prior.y = 0
					-- =========================
				end
				button:Show()
			end
		end
	end
	-- Set panel button init flag
	TITAN_PANEL_BUTTONS_INIT_FLAG = 1;
	TitanPanelButton_Justify();
end

---Titan Reorder all the shown all user selected plugins on the Titan bar(s). Typically used after a button has been removed / hidden.
---@param index number of the plugin removed
function TitanPanel_ReOrder(index)
	for i = index, #TitanPanelSettings.Buttons do
--		for i = index, table.getn(TitanPanelSettings.Buttons) do
			TitanPanelSettings.Location[i] = TitanPanelSettings.Location[i + 1]
	end
end

---Titan Remove a plugin then show all the shown all user selected plugins on the Titan bar(s).
--- This cancels all timers of name "TitanPanel"..id as a safeguard to destroy any active plugin timers
--- based on a fixed naming convention : TitanPanel..id, eg. "TitanPanelClock" this prevents "rogue"
--- timers being left behind by lack of an OnHide check
---@param id string Unique ID of the plugin
function TitanPanel_RemoveButton(id)
	if (not TitanPanelSettings) then
		return;
	end

	local i = TitanPanel_GetButtonNumber(id)
	local currentButton = TitanUtils_GetButton(id);

	-- safeguard ...
---@diagnostic disable-next-line: missing-parameter
	if id then AceTimer.CancelAllTimers() end -- ??? seems confused 0 or 1 params  "TitanPanel" .. id

	TitanPanel_ReOrder(i);
	table.remove(TitanPanelSettings.Buttons, TitanUtils_GetCurrentIndex(TitanPanelSettings.Buttons, id));
	--TitanDebug("_Remove: "..(id or "?").." "..(i or "?"))
	if currentButton then
		currentButton:Hide();
	end
	-- Show the existing buttons
	TitanPanel_InitPanelButtons();
end

--- Titan Get the index of the given plugin from the Titan plugin displayed list.
--- The routine returns +1 if not found so it is 'safe' to add to the list
---@param id string Unique ID of the plugin
---@return number num position or num + 1 for end
function TitanPanel_GetButtonNumber(id)
	-- getn deprecated as of 5.2 - IDE now complaining 2024 Aug
	if (TitanPanelSettings) then
		for i = 1, #TitanPanelSettings.Buttons do
			if (TitanPanelSettings.Buttons[i] == id) then
				return i;
			end
		end
		return #TitanPanelSettings.Buttons + 1;
	else
		return 0;
	end
end

---Titan Update / refresh each plugin from the Titan plugin list. Used when a Titan option is changed that effects all plugins.
function TitanPanel_RefreshPanelButtons()
	if (TitanPanelSettings) then
		for i = 1, #TitanPanelSettings.Buttons do
			TitanPanelButton_UpdateButton(TitanPanelSettings.Buttons[i], 1);
		end
	end
end

---Titan Justify the plugins on each Titan bar.
--- Used when :
---- Init / show of a Titan bar
----the user changes the 'center' option on a Titan bar
function TitanPanelButton_Justify()
	-- Only the left side buttons are justified.
	if (not TITAN_PANEL_BUTTONS_INIT_FLAG or not TitanPanelSettings) then
		return;
	end
	if InCombatLockdown() then
		--TitanDebug("_Justify during combat!!!")
		return;
		-- Issue 856 where some taint is caused if the plugin size is updated during combat. Seems since Mists was released...
	end

	local bar
	local x_offset
	local y_offset
	local firstLeftButton
	local scale = TitanPanelGetVar("Scale");
	local button_spacing = TitanPanelGetVar("ButtonSpacing") * scale
	local icon_spacing = TitanPanelGetVar("IconSpacing") * scale
	local leftWidth = 0;
	local rightWidth = 0;
	local counter = 0;
	local align = 0;
	local center_offset = 0;

	-- Look at each bar for plugins.
	for idx, v in pairs(TitanBarData) do
		bar = TitanBarData[idx].name
		y_offset = TitanBarData[idx].plugin_y_offset
		x_offset = TitanBarData[idx].plugin_x_offset
		firstLeftButton = TitanUtils_GetButton(TitanPanelSettings.Buttons
			[TitanUtils_GetFirstButtonOnBar(bar, TITAN_LEFT)])
		align = TitanBarDataVars[idx].align --TitanPanelGetVar(bar.."_Align")
		leftWidth = 0;
		rightWidth = 0;
		counter = 0;
		-- If there is a plugin on this bar then justify the first button.
		-- The other buttons are relative to the first.
		if (firstLeftButton) then
			if (align == TITAN_PANEL_BUTTONS_ALIGN_LEFT) then
				-- Now offset the plugins
				firstLeftButton:ClearAllPoints();
				firstLeftButton:SetPoint("LEFT", idx, "LEFT", x_offset, y_offset);
			end
			-- Center if requested
			if (align == TITAN_PANEL_BUTTONS_ALIGN_CENTER) then
				leftWidth = 0;
				rightWidth = 0;
				counter = 0;
				-- Calc the total width of the icons so we know where to start
				for index, id in pairs(TitanPanelSettings.Buttons) do
					local button = TitanUtils_GetButton(id);
					if button and button:GetWidth() then
						if TitanUtils_GetWhichBar(id) == bar then
							if (TitanGetVar(id, "DisplayOnRightSide")) then
								rightWidth = rightWidth
									+ icon_spacing
									+ button:GetWidth();
							else
								counter = counter + 1;
								leftWidth = leftWidth
									+ button_spacing
									+ button:GetWidth()
							end
						end
					end
				end
				-- Now offset the plugins on the bar
				firstLeftButton:ClearAllPoints();
				-- remove the last spacing otherwise the buttons appear justified too far left
				center_offset = (0 - (leftWidth - button_spacing) / 2)
				firstLeftButton:SetPoint("LEFT", idx, "CENTER", center_offset, y_offset);
			end
		end
	end
end

--------------------------------------------------------------
--
-- Local routines for Titan menu creation
local R_ADDONS = "Addons_"
local R_PLUGIN = "Plugin_"
local R_SETTINGS = "Settings"
local R_PROFILE = "Profile_"

---local Show main Titan (right click) menu.
---@param frame string Frame to add to
local function BuildMainMenu(frame)
	local locale_bar = TitanBarData[frame].locale_name
	local info = {};
	-----------------
	-- Menu title
	TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_MENU_TITLE"] .. " - " .. locale_bar);
	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_MENU_PLUGINS"]);

	-----------------
	-- Plugin Categories
	-- Both arrays are in TitanGlobal
	---@diagnostic disable-next-line: param-type-mismatch
	for index, id in pairs(L["TITAN_PANEL_MENU_CATEGORIES"]) do
		info = {};
		info.notCheckable = true
		info.text = L["TITAN_PANEL_MENU_CATEGORIES"][index];
		info.value = R_ADDONS .. TITAN_PANEL_BUTTONS_PLUGIN_CATEGORY[index];
		info.hasArrow = 1;
		TitanPanelRightClickMenu_AddButton(info);
	end

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-----------------
	-- Options - just one button to open the first Titan option screen
	do
		info = {};
		info.notCheckable = true
		info.text = L["TITAN_PANEL_MENU_CONFIGURATION"];
		info.value = "Bars";
		info.func = function()
			TitanUpdateConfig("init")
			Settings.OpenToCategory(TITAN_PANEL_CONFIG.topic.About)
		end
		TitanPanelRightClickMenu_AddButton(info);
	end

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-----------------
	-- Profiles
	TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_MENU_PROFILES"]);

	-----------------
	-- Load/Delete
	info = {};
	info.notCheckable = true
	info.text = L["TITAN_PANEL_MENU_MANAGE_SETTINGS"];
	info.value = R_SETTINGS
	info.hasArrow = 1;
	-- lock this menu in combat
	if InCombatLockdown() then
		info.disabled = 1;
		info.hasArrow = nil;
		info.text = info.text .. " "
			.. _G["GREEN_FONT_COLOR_CODE"]
			.. L["TITAN_PANEL_MENU_IN_COMBAT_LOCKDOWN"];
	end
	TitanPanelRightClickMenu_AddButton(info);

	-----------------
	-- Save
	info = {};
	info.notCheckable = true
	info.text = L["TITAN_PANEL_MENU_SAVE_SETTINGS"];
	info.value = "SettingsCustom";
	info.func = TitanPanel_SaveCustomProfile;
	-- lock this menu in combat
	if InCombatLockdown() then
		info.disabled = 1;
		info.text = info.text .. " "
			.. _G["GREEN_FONT_COLOR_CODE"]
			.. L["TITAN_PANEL_MENU_IN_COMBAT_LOCKDOWN"];
	end
	TitanPanelRightClickMenu_AddButton(info);

	--	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());
	local glob, toon, player, server = TitanUtils_GetGlobalProfile()
	info = {};
	--  info.text = "Use Global Profile\n   "..toon
	info.text = L["TITAN_PANEL_GLOBAL_USE"] .. "\n   " .. toon;
	info.value = "Use Global Profile"
	info.func = function()
		TitanUtils_SetGlobalProfile(not glob, toon)
		TitanVariables_UseSettings(nil, TITAN_PROFILE_USE)
	end;
	info.checked = glob --TitanAllGetVar("GlobalProfileUse")
	info.keepShownOnClick = nil
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	-----------------
	-- Hide this bar
	info = {};
	info.text = (HIDE or "Hide")
	info.value = "HideMe"
	info.notCheckable = true
	info.disabled = (TitanUtils_NumActiveBars() == 1)
	info.arg1 = frame;
	info.func = function(self, frame_str)
		TitanBarDataVars[frame_str].show = not TitanBarDataVars[frame_str].show
		TitanPanelBarButton_DisplayBarsWanted(frame_str .. " user clicked Hide")
	end
	info.keepShownOnClick = nil
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
end

---local Show list of servers / custom submenu off Profiles/Manage from the Titan (right click) menu.
local function BuildServerProfilesMenu()
	local info = {};
	local servers = {};
	local player = nil;
	local server = nil;
	local s, e, ident;
	local setonce = 0;

	if (TitanPanelRightClickMenu_GetDropdMenuValue() == R_SETTINGS) then
		TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_MENU_PROFILE_SERVERS"],
			TitanPanelRightClickMenu_GetDropdownLevel());
		-- Normal profile per toon
		for index, id in pairs(TitanSettings.Players) do
			player, server = TitanUtils_ParseName(index)

			if TitanUtils_GetCurrentIndex(servers, server) == nil then
				if server ~= TITAN_CUSTOM_PROFILE_POSTFIX then
					table.insert(servers, server);
					info = {};
					info.notCheckable = true
					info.text = server;
					info.value = R_PROFILE .. server;
					info.hasArrow = 1;
					TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
				end
			end
		end
		-- Custom profiles
		for index, id in pairs(TitanSettings.Players) do
			player, server = TitanUtils_ParseName(index)

			if TitanUtils_GetCurrentIndex(servers, server) == nil then
				if server == TITAN_CUSTOM_PROFILE_POSTFIX then
					if setonce and setonce == 0 then
						TitanPanelRightClickMenu_AddTitle("", TitanPanelRightClickMenu_GetDropdownLevel());
						TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_MENU_PROFILE_CUSTOM"],
							TitanPanelRightClickMenu_GetDropdownLevel());
						setonce = 1;
					end
					info = {};
					info.notCheckable = true
					info.text = player;
					info.value = R_PROFILE .. player;
					info.hasArrow = 1;
					TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
				end
			end
		end
	end
end

---local Show list of plugin defined options from the Titan right click menu.
local function BuildPluginMenu()
	--
	local info = {};

	-- Handle the plugins

	for index, id in pairs(TitanPluginsIndex) do
		local plugin = TitanUtils_GetPlugin(id)
		local par_val = TitanPanelRightClickMenu_GetDropdMenuValue()
		local menu_plugin = string.gsub(par_val, R_PLUGIN, "")
		if plugin and plugin.id and plugin.id == menu_plugin then
			--title
			info = {};
			info.text = TitanPlugins[plugin.id].menuText;
			info.notCheckable = true
			info.notClickable = 1;
			info.isTitle = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			--ShowIcon
			if plugin.controlVariables.ShowIcon then
				info = {};
				info.text = L["TITAN_PANEL_MENU_SHOW_ICON"];
				info.value = plugin.id
				info.arg1 = plugin.id
				info.func = function(self, p_id) -- (self, info.arg1, info.arg2)
					TitanPanelRightClickMenu_ToggleVar({ p_id, "ShowIcon", nil })
				end
				info.keepShownOnClick = 1;
				info.checked = TitanGetVar(plugin.id, "ShowIcon");
				info.disabled = nil;
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			end

			--ShowLabel
			if plugin.controlVariables.ShowLabelText then
				info = {};
				info.text = L["TITAN_PANEL_MENU_SHOW_LABEL_TEXT"];
				info.value = plugin.id
				info.arg1 = plugin.id
				info.func = function(self, p_id) -- (self, info.arg1, info.arg2)
					TitanPanelRightClickMenu_ToggleVar({ p_id, "ShowLabelText", nil })
				end
				info.keepShownOnClick = 1;
				info.checked = TitanGetVar(plugin.id, "ShowLabelText");
				info.disabled = nil;
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			end

			--ShowRegularText (LDB data sources only atm)
			if plugin.controlVariables.ShowRegularText then
				info = {};
				info.text = L["TITAN_PANEL_MENU_SHOW_PLUGIN_TEXT"]
				info.value = plugin.id
				info.arg1 = plugin.id
				info.func = function(self, p_id) -- (self, info.arg1, info.arg2)
					TitanPanelRightClickMenu_ToggleVar({ p_id, "ShowRegularText", nil })
				end
				info.keepShownOnClick = 1;
				info.checked = TitanGetVar(plugin.id, "ShowRegularText");
				info.disabled = nil;
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			end

			--ShowColoredText
			if plugin.controlVariables.ShowColoredText then
				info = {};
				info.text = L["TITAN_PANEL_MENU_SHOW_COLORED_TEXT"];
				info.value = plugin.id
				info.arg1 = plugin.id
				info.func = function(self, p_id) -- (self, info.arg1, info.arg2)
					TitanPanelRightClickMenu_ToggleVar({ p_id, "ShowColoredText", nil })
				end
				info.keepShownOnClick = 1;
				info.checked = TitanGetVar(plugin.id, "ShowColoredText");
				info.disabled = nil;
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			end

			-- Right-side plugin
			if plugin.controlVariables.DisplayOnRightSide then
				info = {};
				info.text = L["TITAN_PANEL_MENU_LDB_SIDE"];
				info.value = plugin.id
				info.arg1 = plugin.id
				info.func = function(self, p_id) -- (self, info.arg1, info.arg2)
					TitanToggleVar(p_id, "DisplayOnRightSide")
					local bar = TitanUtils_GetWhichBar(p_id)
					TitanPanel_RemoveButton(p_id);
					TitanUtils_AddButtonOnBar(bar, p_id);
				end
				info.checked = TitanGetVar(plugin.id, "DisplayOnRightSide");
				info.disabled = nil;
				TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
			end
		end
	end
end

---local Show alphabetical list of toons submenu off Profiles/Manage/<server or custom> from the Titan right click menu.
local function BuildProfileMenu()
	--
	local info = {};
	local setonce = 0;

	--
	-- Handle the profiles
	--
	for idx = 1, #Titan_Global.players do
		local index = Titan_Global.players[idx]
		local player, server = TitanUtils_ParseName(index)
		local off = (index == TitanSettings.Player)
			or ((index == TitanAllGetVar("GlobalProfileUse")) and (TitanAllGetVar("GlobalProfileUse")))
		local par_val = TitanPanelRightClickMenu_GetDropdMenuValue()
		local menu_val = string.gsub(par_val, R_PROFILE, "")

		-- handle custom profiles here
		if server == TITAN_CUSTOM_PROFILE_POSTFIX
			and player == menu_val then
			info = {};
			info.notCheckable = true
			info.disabled = TitanAllGetVar("GlobalProfileUse")
			info.text = L["TITAN_PANEL_MENU_LOAD_SETTINGS"];
			info.value = index;
			info.func = function()
				TitanVariables_UseSettings(index, TITAN_PROFILE_USE)
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

			info = {};
			info.notCheckable = true
			info.disabled = off
			info.text = L["TITAN_PANEL_MENU_DELETE_SETTINGS"];
			info.value = index;
			info.arg1 = index;
			info.func = function(self, player) -- (self, info.arg1, info.arg2)
				if TitanSettings.Players[player] then
					TitanSettings.Players[player] = nil;
					local profname = TitanUtils_ParseName(index)
					TitanPrint(
						L["TITAN_PANEL_MENU_PROFILE"]
						.. " '" .. profname .. "' "
						.. L["TITAN_PANEL_MENU_PROFILE_DELETED"]
						, "info")
					table.remove(Titan_Global.players, idx)
					TitanPanelRightClickMenu_Close();
				end
			end
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end -- if server and player

		-- handle regular profiles here
		if server == menu_val then
			-- Set the label once
			if setonce and setonce == 0 then
				TitanPanelRightClickMenu_AddTitle(L["TITAN_PANEL_MENU_PROFILE_CHARS"],
					TitanPanelRightClickMenu_GetDropdownLevel());
				setonce = 1;
			end
			info = {};
			info.disabled = off
			info.notCheckable = true
			info.text = player;
			info.value = index;
			info.hasArrow = 1;
			TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
		end
	end -- for players
end

---local Show save / load submenu off Profiles/Manage/<server or custom>/<profile> from the Titan (right click) menu.
local function BuildAProfileMenu()
	local info = {};

	info = {};
	info.notCheckable = true
	info.disabled = TitanAllGetVar("GlobalProfileUse")
	info.text = L["TITAN_PANEL_MENU_LOAD_SETTINGS"];
	info.value = TitanPanelRightClickMenu_GetDropdMenuValue();
	info.func = function()
		TitanVariables_UseSettings(TitanPanelRightClickMenu_GetDropdMenuValue(), TITAN_PROFILE_USE)
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	TitanPanelRightClickMenu_AddSeparator(TitanPanelRightClickMenu_GetDropdownLevel());

	info = {};
	info.notCheckable = true
	info.disabled = (TitanPanelRightClickMenu_GetDropdMenuValue() == TitanSettings.Player)
		or ((TitanPanelRightClickMenu_GetDropdMenuValue() == TitanAllGetVar("GlobalProfileName"))
			and (TitanAllGetVar("GlobalProfileUse")))
	info.text = L["TITAN_PANEL_MENU_DELETE_SETTINGS"];
	info.value = TitanPanelRightClickMenu_GetDropdMenuValue();
	info.func = function()
		-- do not delete if current profile - .disabled
		if TitanSettings.Players[info.value] then
			TitanSettings.Players[info.value] = nil;
			TitanPrint(
				L["TITAN_PANEL_MENU_PROFILE"]
				.. " '" .. info.value .. "' "
				.. L["TITAN_PANEL_MENU_PROFILE_DELETED"]
				, "info")
			TitanPanelRightClickMenu_Close();
		end
	end
	TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
end

---local Build the list of plugins for the category the mouse is over - Titan (right click) menu.
---@param frame string Frame to add to
local function BuildPluginCategoryMenu(frame)
	local info = {};
	local plugin;

	for index, id in pairs(TitanPluginsIndex) do
		plugin = TitanUtils_GetPlugin(id)
		if plugin then -- add the plugin to the menu
			plugin.category = plugin and plugin.category or "General";
			if (TitanPanelRightClickMenu_GetDropdMenuValue() == R_ADDONS .. plugin.category) then
				if not TitanGetVar(id, "ForceBar")
					or (TitanGetVar(id, "ForceBar") == TitanBarData[frame].name) then
					info = {};
					local ver = plugin and plugin.version or ""
					if TitanPanelGetVar("VersionShown") then
						if ver == nil or ver == "" then
							ver = "" -- safety in case of nil
						else
							ver = TitanUtils_GetGreenText(" (" .. ver .. ")")
						end
					else
						ver = "" -- not requested
					end
					info.text = plugin and plugin.menuText .. ver or ""

					-- Add Bar
					local internal_bar, which_bar = TitanUtils_GetWhichBar(id)
					if which_bar == nil then
						-- Plugin not shown
					else
						--						if internal_bar == TitanBarData[frame].name then
						--							info.text = info.text .. TitanUtils_GetGreenText(" (" .. which_bar .. ")")
						--						else
						info.text = info.text .. TitanUtils_GetGoldText(" (" .. which_bar .. ")")
						--						end
					end

					if plugin.controlVariables then
						info.hasArrow = 1;
					end
					info.value = R_PLUGIN .. id; -- for next level dropdown
					info.arg1 = frame;
					info.arg2 = id;
					info.func = function(self, frame_str, plugin_id) -- (self, info.arg1, info.arg2)
						-- frame_str is the bar the user clicked to get the menu...
						local bar = TitanBarData[frame_str].name

						if TitanPanel_IsPluginShown(plugin_id) then
							TitanPanel_RemoveButton(plugin_id);
						else
							TitanUtils_AddButtonOnBar(bar, plugin_id)
						end
					end
					info.checked = TitanPanel_IsPluginShown(id) or nil
					info.keepShownOnClick = 1;
					TitanPanelRightClickMenu_AddButton(info, TitanPanelRightClickMenu_GetDropdownLevel());
				end
			end
		else
		end
	end
end

---Titan This is the controller for the Titan (right click) menu.
---@param self table Titan bar frame that was right clicked
--- Frame name used is <Titan bar name>RightClickMenu
function TitanPanelRightClickMenu_PrepareBarMenu(self)
	-- Determine which bar was clicked on
	--	local s, e, frame = string.find(self:GetName(), "(.*)RightClickMenu");
	local s, e, frame = string.find(self:GetName(), "(.*)" .. TITAN_PANEL_CLICK_MENU_SUFFIX);
	local lev = (TitanPanelRightClickMenu_GetDropdownLevel() or 1)
	--[[
print("_prep R click"
.." "..tostring(frame)..""
.." "..tostring(lev)..""
)
--]]

	-- Level 1
	--[===[
		Title - <Bar name>
		----
		Plugins
		<list of Categories>
		----
		Configuration => Opens Titan Options
		-----
		Profiles
		Manage > <Level 2>
		Save => Save current profile (used for Global)
		-----
		Use Global Profile
			<Profile name used or <>>
		----
		Hide => Hide this Bar
	--]===]
	if lev == 1 then
		BuildMainMenu(frame)
	end

	-- Level 2
	-- Plugin Categories => Plugins in that category
	-- OR
	-- Profiles => Server / Realm list
	if (lev == 2) then
		if string.find(TitanPanelRightClickMenu_GetDropdMenuValue(), R_ADDONS) then
			BuildPluginCategoryMenu(frame)
		end

		if (TitanPanelRightClickMenu_GetDropdMenuValue() == R_SETTINGS) then
			BuildServerProfilesMenu()
		end
		return;
	end

	-- Level 3
	-- Plugin Categories => Plugins in that category => Plugin defined options
	-- OR
	-- Profiles > Server / Realm list > Character on realm list
	if (lev == 3) then
		if string.find(TitanPanelRightClickMenu_GetDropdMenuValue(), R_PLUGIN) then
			BuildPluginMenu()
		end
		if string.find(TitanPanelRightClickMenu_GetDropdMenuValue(), R_PROFILE) then
			BuildProfileMenu()
		end
		return;
	end

	-- Level 4
	-- Profiles > Server / Realm list > Character on realm list > Load / Delete
	if (lev == 4) then
		BuildAProfileMenu()
		return;
	end
end

---Titan Determine if the given plugin is on any Titan bar.
---@param id string Unique ID of the plugin
---@return boolean shown True on a Titan bar even if hidden or on auto hide
function TitanPanel_IsPluginShown(id)
	if (id and TitanPanelSettings) then
		return TitanUtils_TableContainsValue(TitanPanelSettings.Buttons, id)
	else
		return false
	end
end

---Titan Determine if the given plugin is / would be on right or left of a Titan bar.
---@param id string Unique ID of the plugin
---@return string R_L  TITAN_RIGHT("Right") or TITAN_Left("Left")
function TitanPanel_GetPluginSide(id)
	if (TitanGetVar(id, "DisplayOnRightSide")) then
		return TITAN_RIGHT;
	else
		return TITAN_LEFT;
	end
end

---Titan Set the scale, texture (graphic), and transparancy of all the Titan bars based on the user selection.
---@param reason string Debug note on where the call initiated
function TitanPanel_InitPanelBarButton(reason)
	-- Set initial Panel Scale
	TitanPanel_SetScale();
	--[[
print("_InitPanelBarButton"
.." "..tostring(reason)..""
)
--]]

	TitanPanelBarButton_DisplayBarsWanted("InitPanelBarButton")
end

--
--==========================
-- Routines to handle creation of Titan bars
--

---Titan Create a Titan bar that can show plugins.
---@param frame_str string Unique ID of the plugin
function TitanPanelButton_CreateBar(frame_str)
	local this_bar = frame_str
	local a_bar = CreateFrame("Button", this_bar, UIParent, "Titan_Bar__Display_Template")

	local bar_data = TitanBarData[this_bar]

	-- ======
	-- Scripts
	a_bar:SetScript("OnEnter", function(self) TitanPanelBarButton_OnEnter(self) end)
	a_bar:SetScript("OnLeave", function(self) TitanPanelBarButton_OnLeave(self) end)
	a_bar:SetFrameStrata("DIALOG")

	if bar_data.user_move then
		a_bar:SetMovable(true)
		a_bar:SetResizable(true)
		a_bar:EnableMouse(true)
		a_bar:RegisterForDrag("LeftButton")
		a_bar:SetScript("OnDragStart", OnMoveStart)
		a_bar:SetScript("OnDragStop", OnMovingStop)
		a_bar:SetScript("OnMouseWheel", OnMouseWheel)
	else
		-- Static full width bar
	end

	-- ======
	-- Bounds only effective on Short bars for now
	-- Min : No smaller than the padding & one icon
	-- Max : No wider than the screen
	-- does not seem to work to restrict size automatically...
	local screen = TitanUtils_ScreenSize()
	a_bar:SetResizeBounds(TitanBarData[this_bar].plugin_x_offset + 16, TITAN_PANEL_BAR_HEIGHT, screen.x,
		TITAN_PANEL_BAR_HEIGHT)
	a_bar:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	a_bar:SetScript("OnClick", function(self, button) TitanPanelBarButton_OnClick(self, button) end)

	-- ======
	-- Frame for right clicks
	-- Use the plugin naming scheme for one frame to rule them all 
	-- 2024 Feb : Change to match plugin right click menu scheme so one routine can be used.
	local f = CreateFrame("Frame", this_bar .. TITAN_PANEL_CLICK_MENU_SUFFIX, UIParent, "UIDropDownMenuTemplate")

	-- ======
	-- Hider for auto hide feature
	local hide_bar_name = TITAN_PANEL_HIDE_PREFIX .. bar_data.name
	if bar_data.hider then
		local hide_bar = CreateFrame("Button", hide_bar_name, UIParent, "TitanPanelBarButtonHiderTemplate")
		hide_bar:SetFrameStrata("DIALOG")

		-- Set script handlers for display
		hide_bar:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		hide_bar:SetScript("OnEnter", function(self) TitanPanelBarButtonHider_OnEnter(self) end)
		hide_bar:SetScript("OnLeave", function(self) TitanPanelBarButtonHider_OnLeave(self) end)
		hide_bar:SetScript("OnClick", function(self, button) TitanPanelBarButton_OnClick(self, button) end)

		hide_bar:SetFrameStrata("BACKGROUND")
		hide_bar:SetSize(screen.x, TITAN_PANEL_BAR_HEIGHT)
	else
		-- Hider not allowed for this bar
	end
end

--====== deprecated / Unused
--[====[

--[[ local
NAME: TitanPanel_CreateABar
DESC: Helper to add scripts to the Titan bar passed in.
VAR: frame - The frame name (string) of the Titan bar to create
OUT: None
NOTE:
- This also creates the hider bar in case the user want to use auto hide.
:NOTE
--]]
local function TitanPanel_CreateABar(frame)
	if frame then
		local bar_name = TitanBarData[frame].name
		local bar_width = TitanBarData[frame].width

		if bar_name then
			-- Set script handlers for display
			_G[frame]:RegisterForClicks("LeftButtonUp", "RightButtonUp");
			_G[frame]:SetScript("OnEnter", function(self) TitanPanelBarButton_OnEnter(self) end)
			_G[frame]:SetScript("OnLeave", function(self) TitanPanelBarButton_OnLeave(self) end)
			_G[frame]:SetScript("OnClick", function(self, button) TitanPanelBarButton_OnClick(self, button) end)
			_G[frame]:SetWidth(bar_width)

			local hide_name = TitanBarData[frame].hider
			if hide_name then
				-- Set script handlers for display
				_G[hide_name]:RegisterForClicks("LeftButtonUp", "RightButtonUp");
				_G[hide_name]:SetScript("OnEnter", function(self) TitanPanelBarButtonHider_OnEnter(self) end)
				_G[hide_name]:SetScript("OnLeave", function(self) TitanPanelBarButtonHider_OnLeave(self) end)
				_G[hide_name]:SetScript("OnClick", function(self, button) TitanPanelBarButton_OnClick(self, button) end)

				_G[hide_name]:SetFrameStrata("BACKGROUND")
				_G[hide_name]:SetWidth(bar_width)
				_G[hide_name]:SetHeight(TITAN_PANEL_BAR_HEIGHT/2);
			end
			
			-- Set the display bar
			local container = _G[frame]
			container:SetHeight(TITAN_PANEL_BAR_HEIGHT);
			-- Set local identifier
			local container_text = _G[frame.."_Text"]
			if container_text then -- was used for debug/creating of the independent bars
				container_text:SetText(tostring(bar_name))
				-- for now show it
				container:Show()
			end
		end
	else
	end
end

--]====]
