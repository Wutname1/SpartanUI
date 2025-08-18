--[===[ File
A "bridge" module to ensure proper registration and communication of LDB plugins with Titan Panel

By Titan Dev team
Originally by Tristanian aka "TristTitan" as a Titan member
Created and initially commited on : July 29th, 2008
--]===]

--[===[ Var Titan LDB overview
The spec: https://github.com/tekkub/libdatabroker-1-1
LDB (libdatabroker) is a small library that enables an addon to hook into a 'display' addon such as Titan.

--- Creation
The addon dev creates an LDB object which the lib places in storage accessible by lib:DataObjectIterator().
It also fires a "LibDataBroker_DataObjectCreated" callback.

LDB objects work by callbacks. 
When an LDB addon changes one of its values, the lib fires a callback for the display addon.

The LDB addon may declare scripts (tooltip, mouse clicks, etc.) per the spec for the display addon to use.

--- Starting from Titan view
On PLAYER_ENTERING_WORLD, Titan will use the iterator to wrap each LDB type addon into a Titan plugin.
Once done processing the known LDB objects, 
Titan registers for the callback to handle LDB objects created later or on demand.

Titan registers for callbacks on text and icon updates - depending on the LDB type.

--- Running from Titan view
The LDB addon is responsible for setting and changing its text and icon.
Titan is responsible for updating the Titan plugin in response.

The Titan plugin will use the LDB addon scripts IF declared, again depending on the LDB type.


--- Supported
Only LDB types listed in the LDB 1.1 spec are supported by Titan.

- "launcher" become "icon" plugins - TitanPanelIconTemplate
	icon* - always shown
	OnClick* -
	label^ -
	right side^ - default
	tooltip
- "data source" become "combo" plugins - TitanPanelComboTemplate
	icon^ -
	OnClick -
	text*^ - or value & suffix
	label^ -
	OnEnter -
	OnLeave -
	tooltip
	OnTooltipShow -

* required by LDB spec
^ Titan user controlled show / hide

--]===]

local xcategories = {
	-- Titan categories mapping to match addon metadata information
	["Combat"] = "Combat",
	["General"] = "General",
	["Information"] = "Information",
	["Interface"] = "Interface",
	["Profession"] = "Profession",
	-- Ace2 table mapping to Titan categories in order to match
	-- addon metadata information
	["Action Bars"] = "Interface",
	["Auction"] = "Information",
	["Audio"] = "Interface",
	["Battlegrounds/PvP"] = "Information",
	["Buffs"] = "Information",
	["Chat/Communication"] = "Interface",
	["Druid"] = "Information",
	["Hunter"] = "Information",
	["Mage"] = "Information",
	["Paladin"] = "Information",
	["Priest"] = "Information",
	["Rogue"] = "Information",
	["Shaman"] = "Information",
	["Warlock"] = "Information",
	["Warrior"] = "Information",
	["Healer"] = "Information",
	["Tank"] = "Information",
	["Caster"] = "Information",
	--	["Combat"] = "Combat",
	["Compilations"] = "General",
	["Data Export"] = "General",
	["Development Tools "] = "General",
	["Guild"] = "Information",
	["Frame Modification"] = "Interface",
	["Interface Enhancements"] = "Interface",
	["Inventory"] = "Information",
	["Library"] = "General",
	["Map"] = "Interface",
	["Mail"] = "Information",
	["Miscellaneous"] = "General",
	["Misc"] = "General",
	["Quest"] = "Information",
	["Raid"] = "Information",
	["Tradeskill"] = "Profession",
	["UnitFrame"] = "Interface",
}
local LAUNCHER = "launcher"
local DATA_SOURCE = "data source"
local SupportedDOTypes = { DATA_SOURCE, LAUNCHER } -- in the 1.1 spec
-- "macro" : this was attempted but Blizzard locked most macro to 'user click only'.
-- By adding a Titan template to any secure button, WoW thinks it could be a bot and errors.

-- constants & variables
local CALLBACK_PREFIX = "LibDataBroker_AttributeChanged_"
local _G = getfenv(0);
local InCombatLockdown = _G.InCombatLockdown;
-- Create control frame so we can get events
local LDBToTitan = CreateFrame("Frame", "LDBTitan")
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local Tablet, LibQTip = nil, nil
local media = LibStub("LibSharedMedia-3.0")
-- generic icon in case the DO does not provide one
local iconTitanDefault = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon";

-- Events we want for LDBToTitan
LDBToTitan:RegisterEvent("PLAYER_LOGIN")
--LDBToTitan:RegisterEvent("PLAYER_ENTERING_WORLD")

---local OK to show tooltip?
---@return boolean
local function If_Show_Tooltip()
	local use_mod = TitanAllGetVar("UseTooltipModifer")
	local use_alt = TitanAllGetVar("TooltipModiferAlt")
	local use_ctrl = TitanAllGetVar("TooltipModiferCtrl")
	local use_shift = TitanAllGetVar("TooltipModiferShift")
	local ok = false
	local tmp_txt = ""
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
	return ok
end

---Titan Properly anchor tooltips of the Titan (LDB) plugin
---@param parent table Parent frame
---@param anchorPoint string
---@param relativeToFrame table|string
---@param relativePoint string
---@param xOffset number
---@param yOffset number
---@param frame table|string Tooltip frame
--- relativeToFrame and frame are really ScriptRegion|string for GameTooltip
function LDBToTitan:TitanLDBSetOwnerPosition(parent, anchorPoint, relativeToFrame, relativePoint, xOffset, yOffset, frame)
	if frame:GetName() == "GameTooltip" then
		-- Changes for 9.1.5 Removed the background template from the GameTooltip
		-- Making changes to it difficult and possibly changing the tooltip globally.

		frame:SetOwner(parent, "ANCHOR_NONE");

		-- set font size for the Game Tooltip
		if not TitanPanelGetVar("DisableTooltipFont") then
			if TitanTooltipScaleSet < 1 then
				TitanTooltipOrigScale = GameTooltip:GetScale();
				TitanTooltipScaleSet = TitanTooltipScaleSet + 1;
			end
			frame:SetScale(TitanPanelGetVar("TooltipFont"));
		end
	end
	frame:ClearAllPoints();
	frame:SetPoint(anchorPoint, relativeToFrame, relativePoint, xOffset, yOffset);
end

---Titan Fill in the tooltip for the Titan (LDB) plugin
---@param name string Plugin id name for LDB
---@param frame table Tooltip frame
---@param tt_func function? Tooltip function to be run
function LDBToTitan:TitanLDBSetTooltip(name, frame, tt_func)
	-- Check to see if we allow tooltips to be shown
	if not TitanPanelGetVar("ToolTipsShown")
		or (TitanPanelGetVar("HideTipsInCombat") and InCombatLockdown()) then
		return
	end

	local button = TitanUtils_GetButton(name);
	local scale = TitanPanelGetVar("Scale");
	local offscreenX, offscreenY;
	local i = TitanPanel_GetButtonNumber(name);
	local bar = TITAN_PANEL_DISPLAY_PREFIX .. TitanUtils_GetWhichBar(name)
	local vert = TitanBarData[bar].vert
	-- Get TOP or BOTTOM for the anchor and relative anchor
	local rel_pt, pt
	if vert == TITAN_TOP then
		pt = "TOP"
		rel_pt = "BOTTOM"
	else
		pt = "BOTTOM"
		rel_pt = "TOP"
	end

	if _G[bar] and button then
		self:TitanLDBSetOwnerPosition(button, pt .. "LEFT", button:GetName(),
			rel_pt .. "LEFT", -10, 0, frame); -- y 4 * scale
		-- Adjust frame position if it's off the screen
		offscreenX, offscreenY = TitanUtils_GetOffscreen(frame);
		if (offscreenX == -1) then
			self:TitanLDBSetOwnerPosition(button, pt .. "LEFT", bar,
				rel_pt .. "LEFT", 0, 0, frame);
		elseif (offscreenX == 1) then
			self:TitanLDBSetOwnerPosition(button, pt .. "RIGHT", bar,
				rel_pt .. "RIGHT", 0, 0, frame);
		end
	else
	end

	if tt_func and If_Show_Tooltip() then tt_func(frame) end; -- TODO: use pcall??
	frame:Show();
end

---Titan Script Handler for the Titan (LDB) plugin
--- This implementation will work fine for a static tooltip but may have implications for dynamic ones so for now, 
--- we'll only set it once (no callback) and see what happens
---@param event string Event name
---@param name string Plugin id name for LDB
---@param _ any not used
---@param func function LDB data object
---@param obj table LDB data object
function LDBToTitan:TitanLDBHandleScripts(event, name, _, func, obj)
	local TitanPluginframe = _G["TitanPanel" .. name .. "Button"];

	-- tooltip
	if event:find("tooltip") and not event:find("OnTooltipShow") then
		local pluginframe = _G[obj.tooltip] or obj.tooltip
		if pluginframe then
			TitanPluginframe:SetScript("OnEnter", function(self)
				TitanPanelButton_OnEnter(self);
				LDBToTitan:TitanLDBSetTooltip(name, pluginframe, nil)
			end
			)

			TitanPluginframe:SetScript("OnMouseDown", function(self)
				pluginframe:Hide();
			end
			)

			if pluginframe:GetScript("OnLeave") then
				-- do nothing
			else
				TitanPluginframe:SetScript("OnLeave", function(self)
					if obj.OnLeave then
						obj.OnLeave(self)
					end
					pluginframe:Hide();
					TitanPanelButton_OnLeave(self);
				end
				)
			end

			if pluginframe:GetName() ~= "GameTooltip" then
				if pluginframe:GetScript("OnShow") then
					-- do nothing
				else
					pluginframe:SetScript("OnShow", function(self)
						LDBToTitan:TitanLDBSetTooltip(name, pluginframe, nil)
					end
					)
				end
			end
		end

		-- OnTooltipShow
	elseif event:find("OnTooltipShow") then
		TitanPluginframe:SetScript("OnEnter", function(self)
			if TITAN_PANEL_MOVING == 0 and func then
				LDBToTitan:TitanLDBSetTooltip(name, GameTooltip, func);
			end
			TitanPanelButton_OnEnter(self);
		end
		)
		TitanPluginframe:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
			TitanPanelButton_OnLeave(self);
		end
		)

		-- OnDoubleClick
	elseif event:find("OnDoubleClick") and not event:find("OnClick") then
		TitanPluginframe:SetScript("OnDoubleClick", function(self, button)
			if TITAN_PANEL_MOVING == 0 then
				func(self, button)
			end
		end
		)

		-- OnClick
	elseif event:find("OnClick") then
		TitanPluginframe:SetScript("OnClick", function(self, button)
			if TITAN_PANEL_MOVING == 0 then
				func(self, button)
			end
			-- implement a safeguard, since the DO may actually use
			-- Blizzy dropdowns !
			if not TitanPanelRightClickMenu_IsVisible() then
				TitanPanelButton_OnClick(self, button);
			else
				TitanUtils_CloseAllControlFrames();
			end
		end
		)
		-- OnEnter
	else
		TitanPluginframe:SetScript("OnEnter", function(self)
			-- Check for tooltip libs without embedding them
			if AceLibrary and AceLibrary:HasInstance("Tablet-2.0") then
				Tablet = AceLibrary("Tablet-2.0")
			end
			LibQTip = LibStub("LibQTip-1.0", true)
			-- Check to see if we allow tooltips to be shown
			if not TitanPanelGetVar("ToolTipsShown")
				or (TitanPanelGetVar("HideTipsInCombat") and InCombatLockdown()) then
				-- if a plugin is using tablet, then detach and close the tooltip
				if Tablet and Tablet:IsRegistered(TitanPluginframe)
					and Tablet:IsAttached(TitanPluginframe) then
					Tablet:Detach(TitanPluginframe);
					Tablet:Close(TitanPluginframe);
				end
				return;
			else
				-- if a plugin is using tablet, then re-attach the tooltip
				-- (it will auto-open on mouseover)
				if Tablet and Tablet:IsRegistered(TitanPluginframe)
					and not Tablet:IsAttached(TitanPluginframe) then
					Tablet:Attach(TitanPluginframe);
				end
			end
			-- if a plugin is using tablet then set its transparency
			-- and font size accordingly
			if Tablet and Tablet:IsRegistered(TitanPluginframe) then
				Tablet:SetTransparency(TitanPluginframe, TitanPanelGetVar("TooltipTrans"))
				if not TitanPanelGetVar("DisableTooltipFont") then
					Tablet:SetFontSizePercent(TitanPluginframe, TitanPanelGetVar("TooltipFont"))
				elseif TitanPanelGetVar("DisableTooltipFont")
					and Tablet:GetFontSizePercent(TitanPluginframe) ~= 1 then
					Tablet:SetFontSizePercent(TitanPluginframe, 1)
				end
			end
			-- set original tooltip scale for GameTooltip
			if not TitanPanelGetVar("DisableTooltipFont") then
				TitanTooltipOrigScale = GameTooltip:GetScale();
			end
			-- call OnEnter on LDB Object
			if TITAN_PANEL_MOVING == 0 and func and If_Show_Tooltip() then
				func(self)
			end

			TitanPanelButton_OnEnter(self);
			-- LibQTip-1.0 support code
			if LibQTip then
				local tt = nil
				local key, tip
				for key, tip in LibQTip:IterateTooltips() do
					if tip then
						local _, relativeTo = tip:GetPoint()
						if relativeTo
							and relativeTo:GetName() == TitanPluginframe:GetName() then
							tt = tip
							break
						end
					end
				end
				if tt then
					-- set transparency
					local red, green, blue, _ = tt:GetBackdropColor()
					local red2, green2, blue2, _ = tt:GetBackdropBorderColor()
					tt:SetBackdropColor(red, green, blue,
						TitanPanelGetVar("TooltipTrans"))
					tt:SetBackdropBorderColor(red2, green2, blue2,
						TitanPanelGetVar("TooltipTrans"))
				end
			end
			-- /LibQTip-1.0 support code
		end
		)

		-- OnLeave
		TitanPluginframe:SetScript("OnLeave", function(self)
			if obj.OnLeave then
				obj.OnLeave(self)
			end
			TitanPanelButton_OnLeave(self);
		end
		)
	end
end

---Titan Text callback for the Titan (LDB) plugin when the LDB addon changes display text of the LDB object
---@param _ any not used
---@param name string Plugin id name for LDB
---@param attr string "value" or  "suffix" or "text" or "label"
---@param value any Should be string
---@param dataobj table LDB data object
function LDBToTitan:TitanLDBTextUpdate(_, name, attr, value, dataobj)
	-- just in case the LDB is active before Titan can register it...
	if not Titan__InitializedPEW then
		-- plugins have not been registered yet.
		return
	end
	-- This check is overkill but just in case...
	local plugin = TitanUtils_GetPlugin(name)
	local ldb = plugin and plugin.LDBVariables
	if not ldb then
		-- This plugin has not been registered
		return
	end

	-- Accept the various display elements and update the Titan plugin
	if attr == "value" then ldb.value = value end
	if attr == "suffix" then ldb.suffix = value end
	if attr == "text" then ldb.text = value end
	if attr == "label" then ldb.label = value end

	-- Now update the button with the change
	TitanPanelButton_UpdateButton(name)
end

---Titan Text callback when the LDB addon changes display text
---@param name string Plugin id name for LDB
---@return string label
---@return string value
function TitanLDBShowText(name)
	-- Set 'label1' and 'value1' for the Titan button display
	local nametrim = string.gsub(name, "LDBT_", "");
	local fontstring = _G[TitanUtils_ButtonName(nametrim) .. TITAN_PANEL_TEXT];
	local separator = ": "
	local lab1, val1 = "", ""
	local plugin = TitanUtils_GetPlugin(name)
	local ldb = plugin and plugin.LDBVariables

	if ldb then -- sanity check
		-- Check for display label
		if TitanGetVar(name, "ShowLabelText") then
			lab1 = (ldb.label or "")
		else
			lab1 = ""
		end

		if lab1 == "" then
			-- leave alone
		else
			lab1 = lab1 .. separator
		end

		-- Check for display text
		-- Check for display text
		-- .text is required to show
		-- .value is the text of the value - 100.0 in 100.0 FPS
		-- .suffix is the text after the value - FPS in 100.0 FPS
		if TitanGetVar(name, "ShowRegularText") then
			val1 = (ldb.text or "")
		else
			val1 = ""
		end
	else
		-- return values will be empty strings
	end

	if lab1 == "" then
		-- just empty
	else
		lab1 = TitanUtils_GetNormalText(lab1)
	end
	if val1 == "" then
		-- just empty
	else
		val1 = TitanGetVar(name, "ShowColoredText")
			and TitanUtils_GetGreenText(val1) or TitanUtils_GetHighlightText(val1)
	end
	return lab1, val1
end

---Titan Icon callback for the Titan (LDB) plugin when the LDB addon changes the icon of the LDB object
---@param _ any not used
---@param name string Plugin id name for LDB
---@param attr string "icon" or  "iconCoords" or "iconR" "iconB" "iconR"
---@param value any icon : Path to icon file; iconCoords : coords
---@param dataobj table LDB data object
function LDBToTitan:TitanLDBIconUpdate(_, name, attr, value, dataobj)
	-- just in case the LDB is active before Titan can register it...
	if not Titan__InitializedPEW then
		-- no plugins are registered yet
		return
	end
	-- This check is overkill but just in case...
	local plugin = TitanUtils_GetPlugin(name)
	local ldb = plugin and plugin.LDBVariables
	if ldb then
		if attr == "icon" then
			TitanPlugins[name].icon = value;
			TitanPanelButton_SetButtonIcon(name);
		end
	
		-- support for iconCoords, iconR, iconG, iconB attributes
		if attr == "iconCoords" then
			TitanPanelButton_SetButtonIcon(name, value);
		end
	
		if attr == "iconR" or attr == "iconB" or attr == "iconG" then
			TitanPanelButton_SetButtonIcon(name, nil,
				dataobj.iconR, dataobj.iconG, dataobj.iconB);
		end
	else
		-- This plugin is not registered yet
		return
	end
end

---Titan Refresh all text & icon for LDB addons that were successfully registered
--- Ensure all the LDB buttons are updated.
--- This is called once x seconds after PEW. This helps close the gap where LDB addons set their text on their PEW event
function TitanLDBRefreshButton()
	--	TitanDebug("LDB: RefreshButton")
	for name, obj in ldb:DataObjectIterator() do
		if obj then
			local unused = nil
			LDBToTitan:TitanLDBTextUpdate(unused, name, "text", (obj.text or ""), obj)
			LDBToTitan:TitanLDBIconUpdate(unused, name, "icon", (obj.icon or iconTitanDefault), obj)
		else
			--	TitanDebug("LDB: '"..name.."' no refresh")
		end
	end
end

---Titan Create a Titan plugin from the DO (Data Object)
--- This is the heart of the LDB to Titan. It reads the LDB DO (Data Object) and creates a Titan plugin.
--- This takes a stricter interpretation of the LDB 1.1 spec rather than guessing what LDB addon developers intended.
---@param self table LDB frame
---@param name_str string LDB id name
---@param obj table LDB data object
function TitanLDBCreateObject(self, name_str, obj)
	local name = name_str
	if Titan_Global.debug.ldb_setup then
		TitanDebug(tostring(name) .. " : Attempting to register ");
	end

	-- couple sanity checks
	--	if not obj or not name then
	if name and type(name) == 'string' then
		-- The name should be reasonable
	else
		local issue = "LDB request name "
			.. " '" .. tostring(name) .. "'"
			.. " unrecognizable !!!!"
		if Titan_Global.debug.ldb_setup then
			TitanDebug(issue);
		end
		error(issue) -- get out
	end
	if obj and type(obj) == 'table' then
		-- The LDB obj should be reasonable
	else
		local object = ""
		if obj then
			object = "is not a table"
		else
			object = "does not exist"
		end
		local issue = "LDB request object for "
			.. " '" .. tostring(name) .. "'"
			.. " " .. tostring(object) .. ""
			.. "  !!!!"
		if Titan_Global.debug.ldb_setup then
			TitanDebug(issue);
		end
		error(issue) -- get out
	end

	-- anything to pass to the developer / user
	local notes = ""

	-- sanity check for supported types
	obj.type = obj.type or "Unknown"
	local supported = false -- assume failure
	for idx in ipairs(SupportedDOTypes) do
		if obj.type and obj.type == SupportedDOTypes[idx] then
			supported = true
		end
	end
	if supported then
		-- all is good - continue plugin creation
	else
		-- Create enough of a plugin to tell the user / developer
		-- that this plugin failed miserably
		local issue = "Unsupported LDB type '" .. tostring(obj.type) .. "'"
		if Titan_Global.debug.ldb_setup then
			TitanDebug(TITAN_REGISTER_FAILED .. " " .. issue);
		end
		error(issue)
		--		return TITAN_REGISTER_FAILED -- get out, there is nothing more that can be done
	end

	--
	-- Handle the display attributes of the DO and register the appropriate callbacks
	--
	-- Init the display elements of the plugin
	local ldb__label = obj.label or ""
	local ldb__suffix = obj.suffix or ""
	local ldb__value = obj.value or ""
	local ldb__text = obj.text or ""
	local ldb__icon = obj.icon or iconTitanDefault

	-- if .icon exists honor it and assume the addon may change it
	if obj.icon then
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_icon", "TitanLDBIconUpdate")
	end

	-- LAUNCHER text display elements
	if obj.type == LAUNCHER then
		if obj.label then
			ldb.RegisterCallback(self,
				CALLBACK_PREFIX .. name .. "_label", "TitanLDBTextUpdate")
		elseif obj.text then
			-- This is a 'be nice' check. It technically violates the 1.1 spec.
			-- Blank the .text so the rest of the routines work
			ldb__label = obj.text
			obj.text = ""
			ldb.RegisterCallback(self,
				CALLBACK_PREFIX .. name .. "_text", "TitanLDBTextUpdate")
			notes = notes .. "\n"
				.. "This is a LDB '" .. LAUNCHER
				.. "' without .label using .text instead!!!!"
		end
	end
	if Titan__InitializedPEW then
		notes = notes .. "\n"
			.. "Will be registered as single LDB plugin after the normal registration."
	end
	-- DATA_SOURCE text display elements
	if obj.type == DATA_SOURCE then
		-- .text so always allow it
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_text", "TitanLDBTextUpdate")
		if obj.label then
			ldb.RegisterCallback(self,
				CALLBACK_PREFIX .. name .. "_label", "TitanLDBTextUpdate")
		end
		if obj.suffix then
			ldb.RegisterCallback(self,
				CALLBACK_PREFIX .. name .. "_suffix", "TitanLDBTextUpdate")
		end
		if obj.value then
			ldb.RegisterCallback(self,
				CALLBACK_PREFIX .. name .. "_value", "TitanLDBTextUpdate")
		end
	end

	--
	-- These are icon extensions listed within the 1.1 spec
	--
	-- support for iconCoords, iconR, iconG, iconB attributes
	-- Due to the callbacks being fired these can easily affect
	-- performance, BEWARE when using them !
	--
	-- capture the icon coords & color for the Titan plugin
	if obj.iconCoords then
		self:TitanLDBIconUpdate(nil, name, "iconCoords", obj.iconCoords, obj)
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_iconCoords", "TitanLDBIconUpdate")
	end
	if obj.iconR and obj.iconG and obj.iconB then
		self:TitanLDBIconUpdate(nil, name, "iconR", obj.iconR, obj)
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_iconR", "TitanLDBIconUpdate")
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_iconG", "TitanLDBIconUpdate")
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_iconB", "TitanLDBIconUpdate")
	end

	--
	-- Setup the Titan plugin for this LDB addon
	--

	-- Create the appropriate Titan registry for the DO
	local registry = {
		id = name,
		ldb = tostring(obj.type),
		-- per 1.1 spec if .label exists use it else use data object's name
		menuText = obj.label or name,
		buttonTextFunction = "TitanLDBShowText",
		icon = ldb__icon,
		iconWidth = 16,
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = false,
			ShowColoredText = false,
			DisplayOnRightSide = true
		},
		savedVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowRegularText = true,
			ShowColoredText = false,
			DisplayOnRightSide = false
		},
		LDBVariables = {
			value = ldb__value,
			suffix = ldb__suffix,
			text = ldb__text,
			label = ldb__label,
			name = name,
			type = (obj.type or ""),
		},
		notes = notes,
		iconCoords = (obj.iconCoords or nil),
		iconR = (obj.iconR or nil),
		iconB = (obj.iconB or nil),
		iconG = (obj.iconG or nil),
	};

	if Titan_Global.debug.ldb_setup then
		TitanDebug(""
			.. " type: '" .. tostring(registry.ldb) .. "' "
		)
	end

	-- Set the plugin category, if it exists, else default to "General"
	-- Per the 1.1 LDB spec we check for a tocname attrib first,
	-- if found we use it, if not we assume that the DO "name"
	-- attribute is the same as the actual
	-- addon name, which might not always be the case.
	-- Titan defaults again to "General" if no categoy is found
	-- via a check in the menu implementation, later on.
	local addoncategory, addonversion;
	local tempname = obj.tocname or name;

	-- This was a sanity check but does not allow for multiple
	-- LDB to be within an addon yet act as their own addon.
	--	if IsAddOnLoaded(tempname) then
	addoncategory = TitanUtils_GetAddOnMetadata(tempname, "X-Category");
	registry.category = (addoncategory and xcategories[addoncategory])
		or (obj.category)
		or "General"
	addonversion = TitanUtils_GetAddOnMetadata(tempname, "Version")
		or (obj.version)
		or ""
	registry["version"] = addonversion;
	registry["notes"] = (TitanUtils_GetAddOnMetadata(tempname, "Notes") or "") .. "\n"
	--	end

	-- Depending on the LDB type set the control and saved Variables appropriately
	if obj.type == LAUNCHER then
		-- controls
		-- one interpretation of the LDB spec is launchers
		-- should always have an icon.
		registry["controlVariables"].ShowIcon = true;
		registry["controlVariables"].ShowRegularText = false; -- no text
		-- defaults
		registry["savedVariables"].ShowRegularText = false;
		registry["savedVariables"].DisplayOnRightSide = true; -- start on right side
	end

	if obj.type == DATA_SOURCE then
		-- controls
		registry["controlVariables"].ShowRegularText = true;
		-- defaults
		registry["savedVariables"].ShowRegularText = true;
	end

	--
	-- Create the Titan frame for this LDB addon
	-- Titan _OnLoad will be used to request the plugin be registered by Titan (Template)
	local newTitanFrame -- a frame
	--[===[
	if obj.type == "macro" then  -- custom
		newTitanFrame = CreateFrame("Button",
			TitanUtils_ButtonName(name),
			UIParent, "SecureActionButtonTemplate, TitanPanelComboTemplate")
--			UIParent, "TitanPanelComboTemplate")
		newTitanFrame:RegisterForClicks("AnyUp", "AnyDown")
		newTitanFrame:SetMouseClickEnabled(true)
		newTitanFrame:SetAttribute("type", "macro")
--		newTitanFrame:SetAttribute("macro", obj.commandtext)
		newTitanFrame:SetAttribute("macrotext", obj.commandtext)
		newTitanFrame:SetScript("OnClick", function(self, button, down)
						SecureUnitButton_OnClick(self, button, down)
						--TitanPanelBarButton_OnClick(self, button)
						end)
		if Titan_Global.debug.ldb_setup then
			TitanDebug(""
				.." macrotext cmd: '"..tostring(obj.commandtext).."' "
			)
		end
	else
		newTitanFrame = CreateFrame("Button",
			TitanUtils_ButtonName(name),
			UIParent, "TitanPanelComboTemplate")
	end
--]===]
	newTitanFrame = CreateFrame("Button",
		TitanUtils_ButtonName(name),
		UIParent, "TitanPanelComboTemplate")

	newTitanFrame.TitanCreatedBy = "LDB"
	--	newTitanFrame.TitanType = "macro"
	newTitanFrame.TitanName = (name or "?")
	newTitanFrame.TitanAction = (obj.commandtext or "None")

	newTitanFrame.registry = registry
	newTitanFrame:SetFrameStrata("FULLSCREEN");
	newTitanFrame:SetToplevel(true);
	newTitanFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp");

	-- Use the routines given by the DO in this precedence
	-- tooltip > OnEnter > OnTooltipShow >
	-- or register a callback in case it is created later. Per the 1.1 LDB spec
	if obj.tooltip then
		self:TitanLDBHandleScripts("tooltip", name, nil, obj.tooltip, obj)
	elseif obj.OnEnter then
		self:TitanLDBHandleScripts("OnEnter", name, nil, obj.OnEnter, obj)
	elseif obj.OnTooltipShow then
		self:TitanLDBHandleScripts("OnTooltipShow", name, nil, obj.OnTooltipShow, obj)
	else
		self:TitanLDBHandleScripts("OnEnter", name, nil, nil, obj)
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_OnEnter", "TitanLDBHandleScripts")
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_OnTooltipShow", "TitanLDBHandleScripts")
	end

	-- Use the OnClick given by the DO
	-- or register a callback in case it is created later.
	if obj.OnClick then
		self:TitanLDBHandleScripts("OnClick", name, nil, obj.OnClick)
	else
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_OnClick", "TitanLDBHandleScripts")
	end

	--
	-- OnDoubleClick is UNDOCUMENTED in the 1.1 spec
	-- but was implemented by the original developer
	--
	-- Use the OnDoubleClick given by the DO
	-- or register a callback in case it is created later.
	if obj.OnDoubleClick then
		self:TitanLDBHandleScripts("OnDoubleClick", name, nil, obj.OnDoubleClick)
	else
		ldb.RegisterCallback(self,
			CALLBACK_PREFIX .. name .. "_OnDoubleClick", "TitanLDBHandleScripts")
	end

	local pew = "event"
	if Titan__InitializedPEW then
		pew = "post event"
		-- Plugins have already been registered and loaded
		-- Get this one loaded
		-- This works because the .registry is now set
		TitanUtils_RegisterPluginList()
		TitanVariables_SyncSinglePluginSettings(registry.id)
		TitanPanel_InitPanelButtons() -- Show it...
	end
	if Titan_Global.debug.ldb_setup then
		TitanDebug("LDB create"
			.. " " .. tostring(pew) .. ""
			.. " '" .. tostring(registry.id) .. "'"
			.. " '" .. tostring(registry.ldb) .. "'"
			.. "\n...'" .. tostring(newTitanFrame:GetName()) .. "'"
		)
	end
	return "Success"
end

---Titan OnEvent handler for LDBToTitan
--- Read through all the LDB objects requesting creation so far. Try to create cooresponding Titan plugins.
---@param sender any !! Not Used !!
---@param name string LDB id name
---@param obj table LDB data object
function LDBToTitan:TitanLDBCreateObject(sender, name, obj)
	local call_success = true
	local ret_val = ""

	call_success, -- needed for pcall
	ret_val =  -- actual return values
		pcall(TitanLDBCreateObject, self, name, obj)

	if call_success then
		-- Registration request created
	else
		-- Create enough of a plugin to tell the user / developer
		-- that this plugin failed
		local plugin =
		{
			self = nil,
			button = nil,
			name = tostring(name),
			issue = ret_val,
			notes = "",
			status = TITAN_REGISTER_FAILED,
			category = "",
			plugin_type = tostring(obj.type or "LDB"),
		}
		TitanUtils_PluginFail(plugin)
	end

	if Titan_Global.debug.ldb_setup then
		TitanDebug("LDB Create:"
			--			.." "..tostring(sender)..""
			.. " " .. tostring(name) .. ""
			.. " " .. tostring(call_success) .. ""
			.. " " .. tostring(ret_val) .. ""
		)
	end
end

--- OnEvent - PLAYER_LOGIN - handler for LDBToTitan
---@param self table Plugin frame
---@param event string Event name
---@param ... any Event args
LDBToTitan:SetScript("OnEvent", function(self, event, ...)
	if (event == "PLAYER_LOGIN") then
		self:UnregisterEvent("PLAYER_LOGIN")
		-- Register the LDB plugins that have been created so far
		for name, obj in ldb:DataObjectIterator() do
			local call_success = true
			local ret_val = ""

			-- Just in case, catch any errors
			call_success, -- needed for pcall
			ret_val = -- actual return values
				pcall(TitanLDBCreateObject, self, name, obj)

			if call_success then
				-- Registration request created
			else
				-- Create enough of a plugin to tell the user / developer
				-- that this plugin failed
				local plugin =
				{
					self = nil,
					button = nil,
					name = tostring(name),
					issue = ret_val,
					notes = "",
					status = TITAN_REGISTER_FAILED,
					category = "",
					plugin_type = tostring(obj.type or "LDB"),
				}
				TitanUtils_PluginFail(plugin)
			end

			if Titan_Global.debug.ldb_setup then
				TitanDebug("LDB"
					.. " " .. tostring(name) .. ""
					.. " " .. tostring(call_success) .. ""
					.. " " .. tostring(ret_val) .. ""
				)
			end
		end

		-- In case a LDB plugin is created later...
		ldb.RegisterCallback(self,
			"LibDataBroker_DataObjectCreated", "TitanLDBCreateObject")
	end
end
)
