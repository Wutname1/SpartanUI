--[===[ File
This file contains routines used by Titan to show and process the Titan options.
Titan uses Ace libraries to place the Titan options within the Blizzard option screens.

Most routines in this file are local because they create the Titan options.
These routines are called first when Titan processes the 'player entering world' event.
If an options list (skins, extra, etc) is changed by the user then the Ace table needs to be updated and WoW server informed to 'redraw'.
--]===]

local L = LibStub("AceLocale-3.0"):GetLocale(TITAN_ID, true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfig = LibStub("AceConfig-3.0")

local TitanSkinToRemove = "None";
local TitanSkinName, TitanSkinPath = "", "";
local TitanGlobalProfile = ""

TITAN_PANEL_CONFIG = {
	topic = {
		About          = L["TITAN_PANEL"],
		top            = L["TITAN_PANEL_MENU_OPTIONS_BARS"],
		globals        = L["TITAN_PANEL_MENU_OPTIONS_BARS_ALL"],
		bottom         = L["TITAN_PANEL_MENU_BOTTOM_BARS"],
		plugins        = L["TITAN_PANEL_MENU_PLUGINS"],
		profiles       = L["TITAN_PANEL_MENU_PROFILES"],
		tooltips       = L["TITAN_PANEL_MENU_OPTIONS_SHORT"],
		scale          = L["TITAN_PANEL_UISCALE_MENU_TEXT_SHORT"],
		trans          = L["TITAN_PANEL_TRANS_MENU_TEXT_SHORT"],
		skins          = L["TITAN_PANEL_MENU_TEXTURE_SETTINGS"],
		skinscust      = L["TITAN_PANEL_SKINS_OPTIONS_CUSTOM"],
		extras         = L["TITAN_PANEL_EXTRAS_SHORT"],
		attempts       = L["TITAN_PANEL_ATTEMPTS_SHORT"],
		advanced       = L["TITAN_PANEL_MENU_ADV"],
		changes        = L["TITAN_PANEL_MENU_CHANGE_HISTORY"],
		slash          = L["TITAN_PANEL_MENU_SLASH_COMMAND"],
		help           = L["TITAN_PANEL_MENU_HELP"],
		adjust         = "Frame Adjustment",
		adjust_classic = "Frame Adjustment - Classic",
	}
}

-- Titan local helper funcs
local function TitanPanel_GetTitle()
	return TitanUtils_GetAddOnMetadata(TITAN_ID, "Title") or L["TITAN_PANEL_NA"];
end

local function TitanPanel_GetAuthor()
	return TitanUtils_GetAddOnMetadata(TITAN_ID, "Author") or L["TITAN_PANEL_NA"];
end

local function TitanPanel_GetCredits()
	return TitanUtils_GetAddOnMetadata(TITAN_ID, "X-Credits") or L["TITAN_PANEL_NA"];
end

local function TitanPanel_GetCategory()
	return TitanUtils_GetAddOnMetadata(TITAN_ID, "X-Category") or L["TITAN_PANEL_NA"];
end

local function TitanPanel_GetEmail()
	return TitanUtils_GetAddOnMetadata(TITAN_ID, "X-Email") or L["TITAN_PANEL_NA"];
end

--[[ not used
local function TitanPanel_GetWebsite()
	return TitanUtils_GetAddOnMetadata(TITAN_ID, "X-Website") or L["TITAN_PANEL_NA"];
end
--]]

local function TitanPanel_GetLicense()
	return TitanUtils_GetAddOnMetadata(TITAN_ID, "X-License") or L["TITAN_PANEL_NA"];
end

-- helper functions

--[[ local
NAME: TitanAdjustPanelScale
DESC: Set the Tian bars and plugins to the selected scale then adjust other frames as needed.
VAR: scale - the scale the user has selected for Titan
OUT: None
--]]
	local function TitanAdjustPanelScale(scale)
		Titan_AdjustScale()

		-- Adjust frame positions
		TitanPanel_AdjustFrames(true, "TitanAdjustPanelScale")
	end

	-- helper functions
	--[[ local
NAME: TitanPanel_TicketReload
DESC: When the user changes the option to adjust for the Blizz ticket frame the UI must be reloaded. Ask the user if they want to do it now.
VAR:  None
OUT:  None
--]]
	local function TitanPanel_TicketReload()
		StaticPopupDialogs["TITAN_RELOAD"] = {
			text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"]) .. "\n\n"
				.. L["TITAN_PANEL_RELOAD"],
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function(self)
				TitanPanelBarButton_ToggleScreenAdjust()
				ReloadUI();
			end,
			showAlert = 1,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1
		};
		StaticPopup_Show("TITAN_RELOAD");
	end

	local function TitanPanel_ScreenAdjustReload()
		if TitanPanelGetVar("ScreenAdjust") then
			-- if set then clear it - the screen will adjust
			TitanPanelBarButton_ToggleScreenAdjust()
		else
			-- if NOT set then need a reload - the screen will NOT adjust
			StaticPopupDialogs["TITAN_RELOAD"] = {
				text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"]) .. "\n\n"
					.. L["TITAN_PANEL_RELOAD"],
				button1 = ACCEPT,
				button2 = CANCEL,
				OnAccept = function(self)
					TitanPanelToggleVar("ScreenAdjust");
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
	local function TitanPanel_AuxScreenAdjustReload()
		if TitanPanelGetVar("AuxScreenAdjust") then
			-- if set then clear it - the screen will adjust
			TitanPanelBarButton_ToggleAuxScreenAdjust()
		else
			-- if NOT set then need a reload - the screen will NOT adjust
			StaticPopupDialogs["TITAN_RELOAD"] = {
				text = TitanUtils_GetNormalText(L["TITAN_PANEL_MENU_TITLE"]) .. "\n\n"
					.. L["TITAN_PANEL_RELOAD"],
				button1 = ACCEPT,
				button2 = CANCEL,
				OnAccept = function(self)
					TitanPanelToggleVar("AuxScreenAdjust");
					ReloadUI();
					--				TitanPanelBarButton_ToggleAuxScreenAdjust();
				end,
				showAlert = 1,
				timeout = 0,
				whileDead = 1,
				hideOnEscape = 1
			};
			StaticPopup_Show("TITAN_RELOAD");
		end
	end

--============= Titan Panel entry
--
--[[ local
NAME: titan_entry
DESC: Local table to hold the 'about' Titan info in the options.
--]]
local titan_entry = {
	name = TITAN_PANEL_CONFIG.topic.About,
	desc = L["TITAN_PANEL"],
	type = "group",
	args = {
		confgendesc = {
			name = "Description",
			order = 1,
			type = "group",
			inline = true,
			args = {
				confdesc = {
					order = 1,
					type = "description",
					name = ""
						..
						"Titan Panel is an Interface Enhancement addon which allows you to add short display bars to the UI as well as bars to the top and bottom of your game screen."
						.. "\n\n"
						..
						"This addon does not interfere with, enhance, or replace any of your actual gameplay within the game. Titan Panel is meant to give you a quick visual point or click-on access to see the data related to your character without having to open other dialog boxes in the game or, in some cases, other addons."
						.. "\n\n"
						.. "Our main program allows you to add bars to the UI as well as the top and bottom of your game screen."
						.. "\n\n"
						..
						"Over the years, we have been able to add some other features, but only if they do not interfere with your actual game experience.",
					cmdHidden = true
				},
			}
		},
		confnotes = {
			name = "Notes",
			order = 3,
			type = "group",
			inline = true,
			args = {
				confversiondesc = {
					order = 1,
					type = "description",
					name = "" .. Titan_Global.config_notes,
					cmdHidden = true
				},
			}
		},
		confthanks = {
			name = "Thank You",
			order = 5,
			type = "group",
			inline = true,
			args = {
				confversiondesc = {
					order = 1,
					type = "description",
					name = ""
						.. "We would like to thank all of the users of TitanPanel."
						.. "\n"
						.. "We understand you have many choices on which addons to enhance your World of Warcraft experience."
						..
						" Our Mission has always been to provide you with a tool to help add and improve your experience without impeding your enjoyment of the game. ",
					cmdHidden = true
				},
			}
		},
		confinfodesc = {
			name = L["TITAN_PANEL_ABOUT"],
			order = 7,
			type = "group",
			inline = true,
			args = {
				confversiondesc = {
					order = 1,
					type = "description",
					name = TitanUtils_GetGoldText(L["TITAN_PANEL_ABOUT_VERSION"] .. ": ")
						.. TitanUtils_GetGreenText(TitanPanel_GetVersion()),
					cmdHidden = true
				},
				confauthordesc = {
					order = 2,
					type = "description",
					name = TitanUtils_GetGoldText(L["TITAN_PANEL_ABOUT_AUTHOR"] .. ": ")
						.. TitanUtils_GetGreenText(TitanPanel_GetAuthor()),
					cmdHidden = true
				},
				confcreditsdesc = {
					order = 3,
					type = "description",
					name = TitanUtils_GetGoldText(L["TITAN_PANEL_ABOUT_CREDITS"] .. ": ")
						.. TitanUtils_GetGreenText(TitanPanel_GetCredits()),
					cmdHidden = true
				},
				confcatdesc = {
					order = 4,
					type = "description",
					name = TitanUtils_GetGoldText(L["TITAN_PANEL_ABOUT_CATEGORY"] .. ": ")
						.. TitanUtils_GetGreenText(TitanPanel_GetCategory()),
					cmdHidden = true
				},
				confemaildesc = {
					order = 5,
					type = "description",
					name = TitanUtils_GetGoldText(L["TITAN_PANEL_ABOUT_EMAIL"] .. ": ")
						.. TitanUtils_GetGreenText(TitanPanel_GetEmail()),
					cmdHidden = true
				},
				--[[ has not been updated in quite a while...
				confwebsitedesc = {
					order = 6,
					type = "description",
					name = TitanUtils_GetGoldText(L["TITAN_PANEL_ABOUT_WEB"]..": ")
						..TitanUtils_GetGreenText(TitanPanel_GetWebsite()),
					cmdHidden = true
				},
--]]
				conflicensedesc = {
					order = 7,
					type = "description",
					name = TitanUtils_GetGoldText(L["TITAN_PANEL_ABOUT_LICENSE"] .. ": ")
						.. TitanUtils_GetGreenText(TitanPanel_GetLicense()),
					cmdHidden = true
				},
			}
		},
	}
}
-------------

--============= Frame Adjust
--
--[[ local
NAME: optionsAdjust
DESC: Bar control for the main (top) bars:
Each bar:
- Show
- Auto hide
- Center text (plugins)
Main (top) controls:
- Disable screen adjust - allows character frame and minimap to be 'over' the Titan bars
- Disable minimap adjust - allows the minimap to be 'over' the Titan bars
- Ticket frame adjust - adjusts the Blizz open ticket frame to be under the Titan bar(s)
:DESC
--]]
local optionsAdjust = {
	name = TITAN_PANEL_CONFIG.topic.adjust,
	type = "group",
	args = {
	}
}

local function ColorAdjShown(frame_str)
	local res = ""
	if TitanAdjustSettings[frame_str].adjust then
		res = frame_str -- leave as is
	else
		res = TitanUtils_GetGrayText(frame_str)
	end

	return res
end

--[[ local
NAME: TitanUpdateAdj
DESC: Allow the user to control each Titan bar.
:DESC
VAR:  None
OUT:  None
--]]
local function TitanUpdateAdj(t, pos)
	local args = t
	local position = pos

	-- sort the bar data by their intended order
	local bar_list = {}
	local i = 0
	for idx, v in pairs(Titan_Global.AdjList) do
		i = i + 1
		bar_list[i] = v
	end
	table.sort(bar_list, function(a, b)
		return a.frame_name < b.frame_name
	end)

	wipe(args)

	for idx = 1, #bar_list do
		-- ======
		-- Build the frame adjust list in order (left side)
		-- NOTE: v.name is the 'group' name which is the table passed to callbacks : info[1]
		local f_name = bar_list[idx].frame_name
		local v = TitanAdjustSettings[f_name] -- process this frame
		position = position + 1
		args[f_name] = {
			type = "group",
			name = ColorAdjShown(f_name),
			order = position,
		}
		-- ======
		-- adjust options (right side)
		args[f_name].args = {} -- .args caused the nesting / right side
		position = position + 1 -- Title divider
		args[f_name].args.title = {
			type = "header",
			name = bar_list[idx].purpose,
			order = position,
			width = "full",
		}
		position = position + 1 -- Show toggle
		args[f_name].args.show = {
			type = "toggle",
			width = .75, --"fill",
			name = USE or "Use", --L["TITAN_PANEL_MENU_DISPLAY_BAR"],
			order = position,
			get = function(info)
				local frame_str = info[1]
				return TitanAdjustSettings[frame_str].adjust
			end,
			set = function(info, val)
				local frame_str                       = info[1]
				TitanAdjustSettings[frame_str].adjust = not TitanAdjustSettings[frame_str].adjust
				TitanPanel_AdjustFrame(frame_str,
					"Adjust show changed : " .. tostring(TitanAdjustSettings[frame_str].adjust))
				TitanUpdateAdj(optionsAdjust.args, 1000)
			end,
		}
		-- ======
		position = position + 1 -- offset
		args[f_name].args.offset = {
			type = "range",
			width = "full",
			name = "Vertical Adjustment", --L["TITAN_PANEL_TRANS_MENU_TEXT_SHORT"],
			order = position,
			min = -200,
			max = 600,
			step = 1,
			get = function(info)
				local frame_str = info[1]
				return TitanAdjustSettings[frame_str].offset
			end,
			set = function(info, a)
				local frame_str                       = info[1]
				TitanAdjustSettings[frame_str].offset = a
				--[[
print("Cfg Adj"
.." '"..tostring(frame_str).."'"
.." "..tostring(a)..""
)
--]]
				TitanPanel_AdjustFrame(frame_str, "Adjust offset changed : " .. tostring(a))
			end,
		}
		position = position + 1 -- spacer
		args[f_name].args.colorspacer = {
			order = position,
			type = "description",
			width = "full",
			name = " ",
		}
	end

	-- Config Tables changed!
	AceConfigRegistry:NotifyChange("Titan Panel Bars")
	--[===[
print("Color new:"
.." "..tostring(format("%0.1f", r))..""
.." "..tostring(format("%0.1f", g))..""
.." "..tostring(format("%0.1f", b))..""
.." "..tostring(format("%0.1f", a))..""
)
--]===]
end

local function BuildAdj()
	TitanUpdateAdj(optionsAdjust.args, 1000)
	AceConfigRegistry:NotifyChange("Titan Panel Adjust")
end
-------------

--============= Bars
--
--[[ local
NAME: optionsBars
DESC: Bar control for the main (top) bars:
Each bar:
- Show
- Auto hide
- Center text (plugins)
Main (top) controls:
- Disable screen adjust - allows character frame and minimap to be 'over' the Titan bars
- Disable minimap adjust - allows the minimap to be 'over' the Titan bars
- Ticket frame adjust - adjusts the Blizz open ticket frame to be under the Titan bar(s)
:DESC
--]]
local optionsBars = {
	name = TITAN_PANEL_CONFIG.topic.top,
	type = "group",
	args = {
	}
}

local function ColorShown(bar)
	local res = bar.locale_name
	local frame_str = bar.frame_name
	if TitanBarDataVars[frame_str].show then
		-- leave as is
	else
		res = TitanUtils_GetGrayText(res)
	end

	return res
end

---X or Y into a string (<num>.yy)
---@param coord number
---@return string
local function Format_coord(coord)
	return (tostring(format("%0.2f", coord)))
end

--[[ local
NAME: TitanUpdateConfigBars
DESC: Allow the user to control each Titan bar.
:DESC
VAR:  None
OUT:  None
--]]
local function TitanUpdateConfigBars(t, pos)
	local args = t
	local position = pos

	-- sort the bar data by their intended order
	local bar_list = {}
	for _, v in pairs(TitanBarData) do
		bar_list[v.order] = v
	end
	table.sort(bar_list, function(a, b)
		return a.order < b.order
	end)

	local label = "Bar"

	wipe(args)

	for idx = 1, #bar_list do
		-- ======
		-- Build the bar list in order (left side)
		-- NOTE: v.name is the 'group' name which is the table passed to callbacks : info[1]
		local v = bar_list[idx] -- process this bar
		position = position + 1
		args[v.name] = {
			type = "group",
			name = ColorShown(v),
			order = position,
		}
		-- ======
		-- Build bar options (right side)
		args[v.name].args = {} -- ,args caused the nesting / right side
		position = position + 1 -- Title divider
		args[v.name].args.title = {
			type = "header",
			name = v.locale_name,
			order = position,
			width = "full",
		}
		position = position + 1 -- Show toggle
		args[v.name].args.show = {
			type = "toggle",
			width = .75, --"fill",
			name = L["TITAN_PANEL_MENU_DISPLAY_BAR"],
			order = position,
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return TitanBarDataVars[frame_str].show
			end,
			set = function(info, val)
				local frame_str                  = TitanVariables_GetFrameName(info[1])
				TitanBarDataVars[frame_str].show = not TitanBarDataVars[frame_str].show
				TitanPanelBarButton_DisplayBarsWanted(info[1] .. "Show " .. tostring(val))
				TitanUpdateConfigBars(optionsBars.args, 1000)
			end,
		}
		position = position + 1 -- Auto hide toggle
		args[v.name].args.autohide = {
			type = "toggle",
			width = .75, --"fill",
			name = L["TITAN_PANEL_MENU_AUTOHIDE"],
			order = position,
			disabled = (v.hider == nil),
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return TitanBarDataVars[frame_str].auto_hide
			end,
			set = function(info, val)
				Titan_AutoHide_ToggleAutoHide(info[1]) -- short bar name
			end,
		}
		position = position + 1 -- Center toggle
		args[v.name].args.center = {
			type = "toggle",
			width = .75, --"fill",
			name = L["TITAN_PANEL_MENU_CENTER_TEXT"],
			order = position,
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return (TitanBarDataVars[frame_str].align == TITAN_PANEL_BUTTONS_ALIGN_CENTER)
			end,
			set = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				if (TitanBarDataVars[frame_str].align == TITAN_PANEL_BUTTONS_ALIGN_CENTER) then
					TitanBarDataVars[frame_str].align = TITAN_PANEL_BUTTONS_ALIGN_LEFT
				else
					TitanBarDataVars[frame_str].align = TITAN_PANEL_BUTTONS_ALIGN_CENTER
				end

				-- Justify button position
				TitanPanelButton_Justify();
			end,
		}
		position = position + 1 -- Combat hide toggle
		args[v.name].args.hideincombat = {
			type = "toggle",
			width = .75, --"fill",
			name = L["TITAN_PANEL_MENU_HIDE_IN_COMBAT"],
			order = position,
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return TitanBarDataVars[frame_str].hide_in_combat
			end,
			set = function(info)
				local frame_str                            = TitanVariables_GetFrameName(info[1])
				TitanBarDataVars[frame_str].hide_in_combat =
					not TitanBarDataVars[frame_str].hide_in_combat
			end,
		}
		position = position + 1 -- spacer
		args[v.name].args.transpacer1 = {
			order = position,
			type = "description",
			width = "full",
			name = " ",
		}
		position = position + 1 -- spacer
		args[v.name].args.resetposspacer = {
			order = position,
			type = "description",
			width = "full",
			name = " ",
		}
		position = position + 1 -- reset pos
		args[v.name].args.resetbar = {
			type = "execute",
			width = "Full",
			name = L["TITAN_PANEL_MENU_RESET_POSITION"],
			order = position,
			disabled = (v.vert == TITAN_TOP or v.vert == TITAN_BOTTOM),
			func = function(info, arg1)
				local frame_str = TitanVariables_GetFrameName(info[1])
				TitanVariables_SetBarPos(_G[frame_str], true)
				TitanPanelBarButton_DisplayBarsWanted("Bar reset to default position - " .. tostring(info[1]))
			end,
		}
--[[
		position = position + 1 -- spacer
		args[v.name].args.position_spacer = {
			order = position,
			type = "description",
			width = "full",
			name = " ",
		}
		position = position + 1 -- reset pos
		args[v.name].args.offset_x_num = {
			order = position,
			name = " X ",
			desc = "",
			disabled = (v.vert == TITAN_TOP or v.vert == TITAN_BOTTOM),
			type = "input",
			width = ".2",
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				local res = TitanBarDataVars[frame_str].off_x
print("Config X get"
.." ".. tostring(info[1])..""
.." ".. tostring(frame_str)..""
.." ".. tostring(res)..""
)
				return Format_coord(res)
			end,
			set = function(info, val)
				local frame_str = TitanVariables_GetFrameName(info[1])
print("Config X set"
.." ".. tostring(frame_str)..""
.." ".. tostring(val)..""
)
				local num = tonumber(val)
				if num == nil then
					-- invalid num yell at user :)
					TitanPrint("error", "X not a number")
				else
					TitanBarDataVars[frame_str].off_x = val
				end
			end,
		}
		position = position + 1 -- reset pos
		args[v.name].args.offset_y_num = {
			order = position,
			name = " Y ",
			desc = "",
			disabled = (v.vert == TITAN_TOP or v.vert == TITAN_BOTTOM),
			type = "input",
			width = ".2",
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				local res = TitanBarDataVars[frame_str].off_y
print("Config Y get"
.." ".. tostring(frame_str)..""
.." ".. tostring(res)..""
)
				return Format_coord(res)
			end,
			set = function(info, val)
				local frame_str = TitanVariables_GetFrameName(info[1])
print("Config Y set"
.." ".. tostring(frame_str)..""
.." ".. tostring(val)..""
)
				local num = tonumber(val)
				if num == nil then
					-- invalid num yell at user :)
					TitanPrint("error", "Y not a number")
				else
					TitanBarDataVars[frame_str].off_y = val
				end
			end,
		}
--]]
-- ======
		-- Background group
		position = position + 1 -- background
		args[v.name].args.back = {
			type = "header",
			name = "=== " .. BACKGROUND .. " ===",
			order = position,
		}
		position = position + 1 -- select background
		args[v.name].args.settextousebar = {
			name = "",    --L["TITAN_PANEL_MENU_GLOBAL_SKIN"],
			desc = "",    --L["TITAN_PANEL_MENU_GLOBAL_SKIN_TIP"],
			order = position,
			type = "select",
			width = "full",
			style = "radio",
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return TitanBarDataVars[frame_str].texure
			end,
			set = function(info, val)
				local frame_str                    = TitanVariables_GetFrameName(info[1])
				TitanBarDataVars[frame_str].texure = val
				TitanPanel_SetBarTexture(frame_str)
			end,
			values = {
				[Titan_Global.SKIN] = L["TITAN_PANEL_SKINS_TITLE"],
				[Titan_Global.COLOR] = COLOR,
			},
		}
		position = position + 1 -- Title divider
		args[v.name].args.skintitle = {
			type = "header",
			name = L["TITAN_PANEL_SKINS_TITLE"],
			order = position,
			width = "full",
		}
		position = position + 1 -- Skin select
		args[v.name].args.skinselect = {
			type = "select",
			width = "normal",
			name = "", --v.locale_name,
			order = position,
			disabled = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return (TitanBarDataVars[frame_str].texure == Titan_Global.COLOR)
			end,
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return TitanBarDataVars[frame_str].skin.path
			end,
			set = function(info, val)
				local frame_str                       = TitanVariables_GetFrameName(info[1])
				TitanBarDataVars[frame_str].skin.path = val
				TitanPanel_SetBarTexture(frame_str)
				if TitanSkinToRemove == TitanPanelGetVar("Texture" .. info[1]) then
					TitanSkinToRemove = "None"
				end
			end,
			values = function(info)
				local Skinlist  = {}
				local frame_str = TitanVariables_GetFrameName(info[1])
				for _, val in pairs(TitanSkins) do
					if val.path ~= TitanBarDataVars[frame_str].skin.path then
						--						if val.path ~= TitanPanelGetVar("Texture"..v.name) then
						Skinlist[val.path] = TitanUtils_GetHexText(val.name, Titan_Global.colors.green)
					else
						Skinlist[val.path] = TitanUtils_GetHexText(val.name, Titan_Global.colors.yellow)
					end
				end
				table.sort(Skinlist, function(a, b)
					return string.lower(TitanSkins[a].name)
						< string.lower(TitanSkins[b].name)
				end)
				return Skinlist
			end,
		}
		position = position + 1 -- spacer
		args[v.name].args.skinspacer = {
			order = position,
			type = "description",
			width = "5",
			name = " ",
		}
		position = position + 1 -- selected skin
		args[v.name].args.skinselected = {
			name = "",
			image = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				local vert      = TitanBarData[frame_str].vert
				if vert == TITAN_SHORT then
					vert = TITAN_TOP
				else
					-- Use it as is
				end
				return TitanBarDataVars[frame_str].skin.path .. "TitanPanelBackground" .. vert .. "0"
			end,
			imageWidth = 256,
			order = position,
			type = "description",
			width = .5,   --"60",
		}
		position = position + 1 -- transparency
		args[v.name].args.trans = {
			type = "range",
			width = "full",
			name = L["TITAN_PANEL_TRANS_MENU_TEXT_SHORT"],
			order = position,
			min = 0,
			max = 1,
			step = 0.01,
			disabled = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return (TitanBarDataVars[frame_str].texure == Titan_Global.COLOR)
			end,
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return TitanBarDataVars[frame_str].skin.alpha
			end,
			set = function(info, a)
				local frame_str = TitanVariables_GetFrameName(info[1])
				_G[frame_str]:SetAlpha(a)
				TitanBarDataVars[frame_str].skin.alpha = a
			end,
		}
		position = position + 1 -- Title divider
		args[v.name].args.colortitle = {
			type = "header",
			name = COLOR,
			order = position,
			width = "full",
		}
		position = position + 1 -- spacer
		args[v.name].args.colorspacer = {
			order = position,
			type = "description",
			width = "full",
			name = " ",
		}
		position = position + 1 -- reset pos
		args[v.name].args.colorselect = {
			type = "color",
			width = "Full",
			name = "Select Bar Color", -- L["TITAN_PANEL_MENU_RESET_POSITION"],
			order = position,
			--				disabled = (v.vert == TITAN_TOP or v.vert == TITAN_BOTTOM),
			hasAlpha = true,
			disabled = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				return (TitanBarDataVars[frame_str].texure == Titan_Global.SKIN)
			end,
			get = function(info)
				local frame_str = TitanVariables_GetFrameName(info[1])
				local color     = TitanBarDataVars[frame_str].color
				return color.r,
					color.g,
					color.b,
					color.alpha
			end,
			set = function(info, r, g, b, a)
				local frame_str                         = TitanVariables_GetFrameName(info[1])

				TitanBarDataVars[frame_str].color.r     = r
				TitanBarDataVars[frame_str].color.g     = g
				TitanBarDataVars[frame_str].color.b     = b
				TitanBarDataVars[frame_str].color.alpha = a
				TitanPanel_SetBarTexture(frame_str)
			end,
		}
	end

	-- Config Tables changed!
	AceConfigRegistry:NotifyChange("Titan Panel Bars")
	--[===[
print("Color new:"
.." "..tostring(format("%0.1f", r))..""
.." "..tostring(format("%0.1f", g))..""
.." "..tostring(format("%0.1f", b))..""
.." "..tostring(format("%0.1f", a))..""
)
--]===]
end

local function BuildBars()
	TitanUpdateConfigBars(optionsBars.args, 1000)
	AceConfigRegistry:NotifyChange("Titan Panel Bars")
end
-------------

--============= Bars - All

local optionsGlobals = {
	name = TITAN_PANEL_CONFIG.topic.globals,
	type = "group",
	args = {
		confdesc = {
			order = 10,
			width = "full",
			type = "header",
			name = L["TITAN_PANEL_MENU_GLOBAL_SKIN_TITLE"],
		},
		setskinuseglobal = {
			name = "", --L["TITAN_PANEL_MENU_GLOBAL_SKIN"],
			desc = "", --L["TITAN_PANEL_MENU_GLOBAL_SKIN_TIP"],
			order = 15,
			type = "select",
			width = "full",
			style = "radio",
			get = function() return TitanBarDataVars["Global"].texure end,
			set = function(_, v)
				TitanBarDataVars["Global"].texure = v
				for idx, val in pairs(TitanBarData) do
					TitanPanel_SetBarTexture(idx)
				end
			end,
			values = {
				[Titan_Global.SKIN] = L["TITAN_PANEL_SKINS_TITLE"],
				[Titan_Global.COLOR] = COLOR,
				[Titan_Global.NONE] = NONE,
			},
		},
		confskindesc = {
			order = 20,
			width = "full",
			type = "description",
			name = L["TITAN_PANEL_SKINS_TITLE"],
		},
		setskinglobal = {
			order = 21,
			type = "select",
			width = "30",
			name = " ", --L["TITAN_PANEL_SKINS_LIST_TITLE"],
			desc = L["TITAN_PANEL_SKINS_SET_DESC"],
			get = function() return TitanBarDataVars["Global"].skin.path end,
			set = function(_, v)
				TitanBarDataVars["Global"].skin.path = v --TitanPanelSetVar("TexturePath", v);
				if TitanBarDataVars["Global"].texure == Titan_Global.SKIN then
					for idx, val in pairs(TitanBarData) do
						TitanPanel_SetBarTexture(idx)
					end
				end
			end,
			values = function()
				local Skinlist = {}
				local v;
				for _, v in pairs(TitanSkins) do
					if v.path ~= TitanBarDataVars["Global"].skin.path then --TitanPanelGetVar("TexturePath") then
						Skinlist[v.path] = TitanUtils_GetHexText(v.name, Titan_Global.colors.green)
					else
						Skinlist[v.path] = TitanUtils_GetHexText(v.name, Titan_Global.colors.yellow)
					end
				end
				table.sort(Skinlist, function(a, b)
					return string.lower(TitanSkins[a].name)
						< string.lower(TitanSkins[b].name)
				end)
				return Skinlist
			end,
		},
		show_skin_top_desc = {
			type = "description",
			name = "",
			order = 30,
			width = "10",
		},
		show_skin_global_top = {
			type = "description",
			name = "",
			image = function()
				return TitanBarDataVars["Global"].skin.path .. "TitanPanelBackgroundTop0"
				--				return TitanPanelGetVar("TexturePath").."TitanPanelBackgroundTop0"
			end,
			imageWidth = 256,
			order = 31,
			width = "60",
		},
		confcolorspacer = { -- spacer
			order = 50,
			type = "description",
			width = "full",
			name = " ",
		},
		confcolordesc = {
			order = 51,
			width = "full",
			type = "description",
			name = COLOR,
		},
		show_skin_color_picker = {
			type = "color",
			width = "Full",
			name = "Select Bar Color", -- L["TITAN_PANEL_MENU_RESET_POSITION"],
			order = 55,
			--				disabled = (v.vert == TITAN_TOP or v.vert == TITAN_BOTTOM),
			hasAlpha = true,
			get = function()
				local color = TitanBarDataVars["Global"].color
				return color.r,
					color.g,
					color.b,
					color.alpha
			end,
			set = function(info, r, g, b, a)
				--[===[
print("Color new:"
.." "..tostring(format("%0.1f", r))..""
.." "..tostring(format("%0.1f", g))..""
.." "..tostring(format("%0.1f", b))..""
.." "..tostring(format("%0.1f", a))..""
)
--]===]
				TitanBarDataVars["Global"].color.r = r
				TitanBarDataVars["Global"].color.g = g
				TitanBarDataVars["Global"].color.b = b
				TitanBarDataVars["Global"].color.alpha = a
				if TitanBarDataVars["Global"].texure == Titan_Global.COLOR then
					for idx, val in pairs(TitanBarData) do
						TitanPanel_SetBarTexture(idx)
					end
				end
			end,
		},
		hidecombatspacer = { -- spacer
			order = 100,
			type = "description",
			width = "full",
			name = " ",
		},
		confcombatdesc = {
			order = 101,
			width = "full",
			type = "header",
			name = L["TITAN_PANEL_MENU_COMMAND"],
		},
		setcombatuseglobal = {
			name = L["TITAN_PANEL_MENU_HIDE_IN_COMBAT"],
			desc = L["TITAN_PANEL_MENU_HIDE_IN_COMBAT_DESC"],
			order = 105,
			type = "toggle",
			width = "full",
			get = function() return TitanPanelGetVar("HideBarsInCombat") end,
			set = function() TitanPanelToggleVar("HideBarsInCombat"); end,
		},
		arenaspacer = { -- spacer
			order = 200,
			type = "description",
			width = "full",
			name = " ",
		},
		confarenadesc = {
			order = 201,
			width = "full",
			type = "header",
			name = BATTLEGROUND .. " / " .. ARENA,
		},
		setarenauseglobal = {
			name = HIDE .. " " .. L["TITAN_PANEL_MENU_TOP_BARS"]
				.. " - " .. BATTLEGROUND .. " / " .. ARENA,
			desc = "Hide"
				.. " " .. TitanBarData[TitanVariables_GetFrameName("Bar")].locale_name
				.. " and"
				.. " " .. TitanBarData[TitanVariables_GetFrameName("Bar2")].locale_name
				.. " in " .. BATTLEGROUND .. " / " .. ARENA,
			order = 205,
			type = "toggle",
			width = "full",
			--disabled = (TITAN_ID == "Titan~Classic"), --? Allow in all version ??
			get = function() return TitanPanelGetVar("HideBarsInPVP") end,
			set = function()
				TitanPanelToggleVar("HideBarsInPVP")
				TitanPanelBarButton_DisplayBarsWanted("HideBarsInPVP"
					.. " " .. tostring(TitanPanelGetVar("HideBarsInPVP")))
			end,
		},
		topbarspacer = { -- spacer
			order = 300,
			type = "description",
			width = "full",
			name = " ",
		},
		conftopbardesc = {
			order = 301,
			width = "full",
			type = "header",
			name = L["TITAN_PANEL_MENU_TOP_BARS"],
		},
		settopbar = {
			name = L["TITAN_PANEL_MENU_DISABLE_PUSH"],
			desc = L["TITAN_PANEL_MENU_DISABLE_PUSH"],
			order = 305,
			type = "toggle",
			width = "full",
			disabled = (Titan_Global.switch.can_edit_ui == true),
			get = function() return TitanPanelGetVar("ScreenAdjust") end,
			set = function() TitanPanel_ScreenAdjustReload() end,
		},
		bottombarspacer = { -- spacer
			order = 400,
			type = "description",
			width = "full",
			name = " ",
		},
		confbottombardesc = {
			order = 401,
			width = "full",
			type = "header",
			name = L["TITAN_PANEL_MENU_BOTTOM_BARS"],
		},
		setbottombar = {
			name = L["TITAN_PANEL_MENU_DISABLE_PUSH"],
			desc = L["TITAN_PANEL_MENU_DISABLE_PUSH"],
			order = 405,
			type = "toggle",
			width = "full",
			disabled = (Titan_Global.switch.can_edit_ui == true),
			get = function() return TitanPanelGetVar("AuxScreenAdjust") end,
			set = function() TitanPanel_AuxScreenAdjustReload() end,
		},
	}
}
-------------

--============= Plugins

--[[ local
NAME: optionsAddons
DESC: This is the table shell. The plugin controls will be added by another routine.
--]]
local optionsAddons = {
	name = TITAN_PANEL_CONFIG.topic.plugins, --"Titan "..L["TITAN_PANEL_MENU_PLUGINS"],
	type = "group",
	args = {}
}

local function ColorVisible(id, name)
	local res = "?"
	if TitanPanel_IsPluginShown(id) then
		res = (name or "")
	else
		res = TitanUtils_GetGrayText(name)
	end

	return res
end

--[[ local
NAME: TitanUpdateConfigAddons
DESC: Allow the user to control each plugin registered to Titan.
Controls honored from the plugin .registry:
- Show
- Show label text
- Right side
- Show icon
- Show text
Position:
- Shift left one plugin position on the bar
- Shift right one plugin position on the bar
- The shift is on the same bar
- The shift will not move a plugin from one side to the other
Bar:
- Drop down so the user can pick the bar the plugin is to be shown on.
- The list contains only the bars the user has selected to be shown.
- The user can not move a plugin to a hidden bar to 'hide' it. The user should ensure "Show Plugin" is unchecked.
:DESC
VAR:  None
OUT:  None
--]]
local function TitanUpdateConfigAddons()
	local args = optionsAddons.args
	local plug_in = nil
	local plug_category = ""
	local plug_version = ""
	local plug_ldb = ""
	local plug_notes = ""

	wipe(args)

	for idx, value in pairs(TitanPluginsIndex) do
		plug_in = TitanUtils_GetPlugin(TitanPluginsIndex[idx])
		if plug_in then
			local header = (plug_in.menuText or "")
			args[plug_in.id] = {
				type = "group",
				name = ColorVisible(plug_in.id, plug_in.menuText or ""),
				order = idx,
				args = {
					name = {
						type = "header",
						name = header,
						order = 1,
					},
					show = {
						type = "toggle",
						name = L["TITAN_PANEL_MENU_SHOW"],
						order = 3,
						get = function(info) return (TitanPanel_IsPluginShown(info[1])) end,
						set = function(info, v)
							local name = info[1]
							if v then -- Show / add
								local bar = (TitanGetVar(name, "ForceBar") or TitanUtils_PickBar())
								TitanUtils_AddButtonOnBar(bar, name)
							else -- Hide / remove
								TitanPanel_RemoveButton(name)
							end
							TitanUpdateConfigAddons()
						end,
					},
				}
			}

			--ShowIcon
			if plug_in.controlVariables and plug_in.controlVariables.ShowIcon then
				args[plug_in.id].args.icon =
				{
					type = "toggle",
					name = L["TITAN_PANEL_MENU_SHOW_ICON"],
					order = 4,
					get = function(info) return (TitanGetVar(info[1], "ShowIcon")) end,
					set = function(info, v)
						TitanToggleVar(info[1], "ShowIcon");
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end

			--ShowLabel
			if plug_in.controlVariables and plug_in.controlVariables.ShowLabelText then
				args[plug_in.id].args.label = {
					type = "toggle",
					name = L["TITAN_PANEL_MENU_SHOW_LABEL_TEXT"],
					order = 5,
					get = function(info) return (TitanGetVar(info[1], "ShowLabelText")) end,
					set = function(info, v)
						TitanToggleVar(info[1], "ShowLabelText");
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end

			--ShowRegularText (LDB data sources only atm)
			if plug_in.controlVariables and plug_in.controlVariables.ShowRegularText then
				args[plug_in.id].args.regular_text =
				{
					type = "toggle",
					name = L["TITAN_PANEL_MENU_SHOW_PLUGIN_TEXT"],
					order = 6,
					get = function(info) return (TitanGetVar(info[1], "ShowRegularText")) end,
					set = function(info, v)
						TitanToggleVar(info[1], "ShowRegularText");
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end

			--ShowColoredText
			if plug_in.controlVariables and plug_in.controlVariables.ShowColoredText then
				args[plug_in.id].args.color_text = {
					type = "toggle",
					name = L["TITAN_PANEL_MENU_SHOW_COLORED_TEXT"],
					order = 7,
					get = function(info) return (TitanGetVar(info[1], "ShowColoredText")) end,
					set = function(info, v)
						TitanToggleVar(info[1], "ShowColoredText");
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end

			-- Right-side plugin
			if plug_in.controlVariables and plug_in.controlVariables.DisplayOnRightSide then
				args[plug_in.id].args.right_side = {
					type = "toggle",
					name = L["TITAN_PANEL_MENU_LDB_SIDE"],
					order = 8,
					get = function(info) return (TitanGetVar(info[1], "DisplayOnRightSide")) end,
					set = function(info, v)
						local bar = TitanUtils_GetWhichBar(info[1])
						TitanToggleVar(info[1], "DisplayOnRightSide");
						TitanPanel_RemoveButton(info[1]);
						TitanUtils_AddButtonOnBar(bar, info[1]);
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end
			-- Shift R / L
			args[plug_in.id].args.plugin_position = {
				order = 50,
				type = "header",
				name = L["TITAN_PANEL_MENU_POSITION"],
			}
			args[plug_in.id].args.shift_left = {
				type = "execute",
				name = "< " .. L["TITAN_PANEL_SHIFT_LEFT"] .. "  ",
				order = 51,
				func = function(info, arg1)
					local name = info[1]
					if TitanPanel_IsPluginShown(name) then
						TitanUtils_ShiftButtonOnBarLeft(name)
					end
				end,
			}
			args[plug_in.id].args.shift_right = {
				type = "execute",
				name = "> " .. L["TITAN_PANEL_SHIFT_RIGHT"],
				order = 52,
				func = function(info, arg1)
					local name = info[1]
					if TitanPanel_IsPluginShown(info[1]) then
						TitanUtils_ShiftButtonOnBarRight(name)
					end
				end,
			}
			args[plug_in.id].args.space_50_1 = {
				order = 53,
				type = "header",
				name = L["TITAN_PANEL_MENU_BAR"],
			}
			if not TitanVarExists(plug_in.id, "ForceBar") then
				args[plug_in.id].args.top_bottom = {
					order = 54,
					type = "select",
					name = L["TITAN_PANEL_MENU_BAR"],
					desc = L["TITAN_PANEL_MENU_DISPLAY_ON_BAR"],
					get = function(info)
						return TitanUtils_GetWhichBar(info[1])
					end,
					set = function(info, v)
						local name = info[1]
						if TitanPanel_IsPluginShown(name) then
							TitanUtils_AddButtonOnBar(v, name)
						end
					end,
					values = function()
						local Locationlist = {}
						local v
						for idx, v in pairs(TitanBarData) do
							if TitanBarDataVars[idx].show then
								--							if TitanPanelGetVar(TitanBarData[idx].name.."_Show") then
								Locationlist[TitanBarData[idx].name] = TitanBarData[idx].locale_name
							end
						end
						return Locationlist
					end,
				}
			else
				args[plug_in.id].args.top_bottom = {
					order = 54,
					type = "description",
					name = TitanUtils_GetGoldText(L["TITAN_PANEL_MENU_BAR_ALWAYS"] ..
						" " .. TitanGetVar(plug_in.id, "ForceBar")),
					cmdHidden = true,
				}
			end
			args[plug_in.id].args.space_50_2 = {
				order = 59,
				type = "description",
				name = "  ",
				cmdHidden = true,
			}
			-- Notes, if available
			args[plug_in.id].args.custom_notes = {
				order = 60,
				type = "header",
				name = L["TITAN_PANEL_MENU_ADV_NOTES_PLUGIN"],
			}
			if plug_in.version then
				plug_version = TitanUtils_GetGreenText(" (" .. plug_in.version .. ")")
			else
				plug_version = ""
			end
			if plug_in.category then
				plug_category = TitanUtils_GetGreenText(" " .. plug_in.category .. "")
			else
				plug_category = ""
			end
			if plug_in.notes then
				plug_notes = TitanUtils_GetGreenText("" .. plug_in.notes .. "")
			else
				plug_notes = ""
			end
			if plug_in.ldb then
				plug_ldb = TitanUtils_GetGreenText(" [LDB]")
			else
				plug_ldb = ""
			end
			local str = ""
				.. plug_version
				.. plug_category
				.. _G["GREEN_FONT_COLOR_CODE"] .. plug_ldb .. "|r"
				.. "\n"
				.. plug_notes
			if plug_in.notes then
				args[plug_in.id].args.notes = {
					type = "description",
					order = 61,
					name = str,
					cmdHidden = true,
				}
			else
				args[plug_in.id].args.notes = {
					type = "description",
					order = 61,
					name = str,
					cmdHidden = true,
				}
			end
			--
			-- Custom Labels 1 - 4
			local num_labels = tonumber(TitanGetVar(plug_in.id, "NumLabelsSeen") or 1)

			if num_labels >= 1 then
				args[plug_in.id].args.custom_labels = {
					order = 70,
					type = "header",
					name = L["TITAN_PANEL_MENU_ADV_LABEL"],
				}
				args[plug_in.id].args.custom_label_show = {
					type = "toggle",
					name = L["TITAN_PANEL_MENU_ADV_LABEL_SHOW"] .. " 1",
					order = 71,
					get = function(info) return (TitanGetVar(info[1], "CustomLabelTextShow") or false) end,
					set = function(info, v)
						TitanToggleVar(info[1], "CustomLabelTextShow");
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
				args[plug_in.id].args.custom_label_text = {
					order = 72,
					name = L["TITAN_PANEL_MENU_ADV_CUSTOM"],
					desc = L["TITAN_PANEL_MENU_ADV_CUSTOM_DESC"],
					type = "input",
					width = "full",
					get = function(info) return (TitanGetVar(info[1], "CustomLabelText") or "") end,
					set = function(info, v)
						TitanSetVar(info[1], "CustomLabelText", v);
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end
			if num_labels >= 2 then
				args[plug_in.id].args.custom_label2_show = {
					type = "toggle",
					name = L["TITAN_PANEL_MENU_ADV_LABEL_SHOW"] .. " 2",
					order = 73,
					get = function(info) return (TitanGetVar(info[1], "CustomLabel2TextShow") or false) end,
					set = function(info, v)
						TitanToggleVar(info[1], "CustomLabel2TextShow");
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
				args[plug_in.id].args.custom_label2_text = {
					order = 74,
					name = L["TITAN_PANEL_MENU_ADV_CUSTOM"],
					desc = L["TITAN_PANEL_MENU_ADV_CUSTOM_DESC"],
					type = "input",
					width = "full",
					get = function(info) return (TitanGetVar(info[1], "CustomLabel2Text") or "") end,
					set = function(info, v)
						TitanSetVar(info[1], "CustomLabel2Text", v);
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end
			if num_labels >= 3 then
				args[plug_in.id].args.custom_label3_show = {
					type = "toggle",
					name = L["TITAN_PANEL_MENU_ADV_LABEL_SHOW"] .. " 3",
					order = 75,
					get = function(info) return (TitanGetVar(info[1], "CustomLabel3TextShow") or false) end,
					set = function(info, v)
						TitanToggleVar(info[1], "CustomLabel3TextShow");
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
				args[plug_in.id].args.custom_label3_text = {
					order = 76,
					name = L["TITAN_PANEL_MENU_ADV_CUSTOM"],
					desc = L["TITAN_PANEL_MENU_ADV_CUSTOM_DESC"],
					type = "input",
					width = "full",
					get = function(info) return (TitanGetVar(info[1], "CustomLabel3Text") or "") end,
					set = function(info, v)
						TitanSetVar(info[1], "CustomLabel3Text", v);
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end
			if num_labels >= 4 then
				args[plug_in.id].args.custom_label4_show = {
					type = "toggle",
					name = L["TITAN_PANEL_MENU_ADV_LABEL_SHOW"] .. " 4",
					order = 77,
					get = function(info) return (TitanGetVar(info[1], "CustomLabel4TextShow") or false) end,
					set = function(info, v)
						TitanToggleVar(info[1], "CustomLabel4TextShow");
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
				args[plug_in.id].args.custom_label4_text = {
					order = 78,
					name = L["TITAN_PANEL_MENU_ADV_CUSTOM"],
					desc = L["TITAN_PANEL_MENU_ADV_CUSTOM_DESC"],
					type = "input",
					width = "full",
					get = function(info) return (TitanGetVar(info[1], "CustomLabel4Text") or "") end,
					set = function(info, v)
						TitanSetVar(info[1], "CustomLabel4Text", v);
						TitanPanelButton_UpdateButton(info[1])
					end,
				}
			end
		end
	end

	-- Config Tables changed!
	AceConfigRegistry:NotifyChange("Titan Panel Addon Control")
end
-------------

--============= Profiles

--[[ local
NAME: optionsChars
DESC: This is the table shell. The toon info will be added by another routine.
--]]
local optionsChars = {
	name = TITAN_PANEL_CONFIG.topic.profiles, --"Titan "..L["TITAN_PANEL_MENU_PROFILES"],
	type = "group",
	args = {}
}

--[[ local
NAME: TitanUpdateChars
DESC: Allow the user to delete toon data (just not the one they are logged into).
VAR:  None
OUT:  None
NOTE:
- Users can delete toons but the saved variable data is still stored by Titan.
- The old toon data can be removed by the user.
- This routine is called to 'redraw' the list as a user deletes toon data.
- A message is sent to chat that the plugin data has been deleted.
:NOTE
--]]
local function TitanUpdateChars()
	local players = {};
	-- Rip through the players (with server name) to sort them
	for index, id in pairs(TitanSettings.Players) do
		table.insert(players, index);
	end

	-- set up the options for the user
	local args = optionsChars.args
	local plug_in = nil

	wipe(args)

	args["desc"] = {
		order = 1,
		type = "description",
		name = L["TITAN_PANEL_CHARS_DESC"] .. "\n",
		cmdHidden = true,
	}
	args["custom_header"] = {
		order = 10,
		type = "header",
		name = L["TITAN_PANEL_MENU_PROFILE_CUSTOM"] .. "\n",
		cmdHidden = true,
	}
	args["custom_save"] = {
		order = 11,
		type = "execute",
		name = L["TITAN_PANEL_MENU_SAVE_SETTINGS"] .. "\n",
		func = function(info, v)
			TitanPanel_SaveCustomProfile()
			TitanUpdateChars() -- rebuild the toons
		end,
	}
	args["sp_1"] = {
		type = "description",
		name = "",
		cmdHidden = true,
		order = 12,
	}
	args["global_header"] = {
		order = 20,
		type = "header",
		name = L["TITAN_PANEL_GLOBAL"],
		cmdHidden = true,
	}
	args["global_use"] = {
		order = 21,
		type = "toggle",
		width = "full",
		name = L["TITAN_PANEL_GLOBAL_USE"],
		desc = L["TITAN_PANEL_GLOBAL_USE_DESC"],
		get = function() return TitanAllGetVar("GlobalProfileUse") end,
		set = function()
			TitanUtils_SetGlobalProfile(not TitanAllGetVar("GlobalProfileUse"), nil)
			TitanUpdateChars() -- rebuild the toons
			AceConfigRegistry:NotifyChange("Titan Panel Addon Chars")
		end,
	}
	args["global_name"] = {
		order = 22,
		type = "description",
		width = "full",
		name = L["TITAN_PANEL_GLOBAL_PROFILE"] ..
			": " .. TitanUtils_GetGoldText(TitanAllGetVar("GlobalProfileName") or "?"),
	}
	args["sp_20"] = {
		type = "description",
		name = "",
		cmdHidden = true,
		order = 23,
	}
	args["profile_header"] = {
		order = 30,
		type = "header",
		name = L["TITAN_PANEL_MENU_PROFILES"] .. "\n",
		cmdHidden = true
	}
	for idx, value in pairs(players) do
		local name = (players[idx] or "?")
		local s, e, ident, server, player
		local fancy_name = ""
		local disallow = false
		disallow = -- looks weird but we need to force a true or Ace complains
			((name == TitanSettings.Player)
				or ((name == TitanAllGetVar("GlobalProfileName"))
					and (TitanAllGetVar("GlobalProfileUse")))
			) and true or false

		if name then
			-- color code the name
			-- - gold for normal profiles
			-- - green for custom profiles
			player, server = TitanUtils_ParseName(name)
			-- handle custom profiles here
			if server == TITAN_CUSTOM_PROFILE_POSTFIX then
				fancy_name = TitanUtils_GetGreenText((name or "?"))
			else
				fancy_name = TitanUtils_GetGoldText((name or "?"))
			end
			-- end color code
			args[name] = {
				type = "group",
				name = fancy_name,
				desc = "",
				order = 40,
				args = {
					name = {
						type = "header",
						name = TitanUtils_GetGoldText(name or "?"),
						cmdHidden = true,
						order = 10,
					},
					sp_1 = {
						type = "description",
						name = "",
						cmdHidden = true,
						order = 11,
					},
					optionload = {
						name = L["TITAN_PANEL_MENU_LOAD_SETTINGS"],
						order = 20,
						type = "execute",
						width = "full",
						func = function(info, v)
							TitanVariables_UseSettings(info[1], TITAN_PROFILE_USE)
						end,
						-- does not make sense to load current character profile or global profile
						disabled = disallow,
					},
					sp_20 = {
						type = "description",
						name = "",
						cmdHidden = true,
						order = 21,
					},
					optionreset = {
						name = L["TITAN_PANEL_MENU_DELETE_SETTINGS"],
						order = 30,
						type = "execute",
						width = "full",
						func = function(info, v)
							TitanSettings.Players[info[1]] = nil -- delete the config entry
							TitanPrint(
								L["TITAN_PANEL_MENU_PROFILE"]
								.. info[1]
								.. L["TITAN_PANEL_MENU_PROFILE_DELETED"]
								, "info")
							if name == TitanAllGetVar("GlobalProfileName") then
								TitanAllSetVar("GlobalProfileName", TITAN_PROFILE_NONE)
							end
							TitanUpdateChars() -- rebuild the toons
							AceConfigRegistry:NotifyChange("Titan Panel Addon Chars")
						end,
						-- can not delete current character profile or global profile
						disabled = disallow,
					},
					sp_30 = {
						type = "description",
						name = "",
						cmdHidden = true,
						order = 31,
					},
					sp_31 = {
						type = "description",
						name = "",
						cmdHidden = true,
						order = 32,
					},
					global_header = {
						order = 40,
						type = "header",
						name = "Global", --L["TITAN_PANEL_MENU_VERSION_SHOWN"],
						cmdHidden = true,
					},
					use_as_global = {
						order = 41,
						type = "toggle",
						width = "full",
						name = L["TITAN_PANEL_GLOBAL_USE_AS"],
						get = function() return TitanPanelGetVar("GlobalProfileName") == name end,
						set = function()
							if TitanPanelGetVar("GlobalProfileName") == name then
								-- Was unchecked so clear the saved var
								TitanAllSetVar("GlobalProfileName", TITAN_PROFILE_NONE)
							else
								-- Was checked so set the saved var
								TitanAllSetVar("GlobalProfileName", name)
							end
							if TitanAllGetVar("GlobalProfileUse") then
								-- Use whatever toon the user picked, if not use current toon
								if TitanAllGetVar("GlobalProfileName") == TITAN_PROFILE_NONE then
									TitanAllSetVar("GlobalProfileName", TitanSettings.Player)
								end
								TitanVariables_UseSettings(TitanAllGetVar("GlobalProfileName"), TITAN_PROFILE_USE)
								TitanPrint(
									L["TITAN_PANEL_MENU_PROFILE"]
									.. ":" .. (TitanAllGetVar("GlobalProfileName") or "?")
									.. ": " .. L["TITAN_PANEL_GLOBAL_RESET_PART"] .. "..."
									, "info")
							else
								--
							end
							TitanUpdateChars()
							AceConfigRegistry:NotifyChange("Titan Panel Addon Chars")
						end,
						-- can not uncheck current global profile
						disabled = disallow,
					},
					sp_40 = {
						type = "description",
						name = "",
						cmdHidden = true,
						order = 42,
					},
				},
			}
		end
	end

	-- tell the options screen there is a new list
	AceConfigRegistry:NotifyChange("Titan Panel Addon Chars")
end
-------------

--============= Tooltips and Frames

--[[ local
NAME: optionsFrames
DESC: Show the general Tian options that hte user can change:
Tooltips:
- Hide in combat
- Show (or not)
Frames (bars):
- Lock buttons (plugins) - do not allow plugins to be moved via drag & drop. Shift left / right is still allowwed.
- Show plugin versions - show the version in the tooltips
Actions:
- Force LDB laucnhers to right side - This will move all converted LDB plugins of type launcher to the right side of the Titan bar.
- Refresh plugins - This can be used when a plugin has not updated its text. It may allow a plugin to show if it is not visible but the user has selected show.
- Reset Titan to default - used when the user wants to reset Titan options to a fresh install state. No plugins are removed by this.
:DESC
--]]
local optionsFrames = {
	name = TITAN_PANEL_CONFIG.topic.tooltips, --L["TITAN_PANEL_MENU_OPTIONS"],
	type = "group",
	args = {
		confdesc2 = {
			order = 200,
			type = "header",
			name = L["TITAN_PANEL_MENU_OPTIONS_TOOLTIPS"],
		},
		optiontooltip = {
			name = L["TITAN_PANEL_MENU_TOOLTIPS_SHOWN"],
			--			desc = L["TITAN_PANEL_MENU_TOOLTIPS_SHOWN"],
			order = 201,
			type = "toggle",
			width = "full",
			get = function() return TitanPanelGetVar("ToolTipsShown") end,
			set = function() TitanPanelToggleVar("ToolTipsShown"); end,
		},
		optiontooltipcombat = {
			name = L["TITAN_PANEL_MENU_TOOLTIPS_SHOWN_IN_COMBAT"],
			--			desc = L["TITAN_PANEL_MENU_TOOLTIPS_SHOWN_IN_COMBAT"],
			order = 210,
			type = "toggle",
			width = "full",
			get = function() return TitanPanelGetVar("HideTipsInCombat") end,
			set = function() TitanPanelToggleVar("HideTipsInCombat"); end,
		},
		conftooltipdesc = {
			name = "Tooltip Modifier",
			type = "group",
			inline = true,
			order = 220,
			args = {
				confdesc = {
					order = 110,
					type = "description",
					name = "",
					cmdHidden = true,
				},
				advname = {
					name = L["TITAN_PANEL_MENU_TOOLTIP_MOD"],
					desc = "", -- L[""],
					order = 120,
					type = "toggle",
					width = "full",
					get = function() return TitanAllGetVar("UseTooltipModifer") end,
					set = function(_, a)
						TitanAllSetVar("UseTooltipModifer", a);
					end,
				},
				tooltipmod = {
					name = "",
					type = "group",
					inline = true,
					order = 140,
					args = {
						alt_key = {
							name = _G["ALT_KEY_TEXT"],
							desc = _G["ALT_KEY"],
							order = 110,
							type = "toggle", --width = "full",
							get = function() return TitanAllGetVar("TooltipModiferAlt") end,
							set = function(_, a)
								TitanAllSetVar("TooltipModiferAlt", a);
							end,
						},
						ctrl_key = {
							name = _G["CTRL_KEY_TEXT"],
							desc = _G["CTRL_KEY"],
							order = 120,
							type = "toggle", --width = "full",
							get = function() return TitanAllGetVar("TooltipModiferCtrl") end,
							set = function(_, a)
								TitanAllSetVar("TooltipModiferCtrl", a);
							end,
						},
						shift_key = {
							name = _G["SHIFT_KEY_TEXT"],
							desc = _G["SHIFT_KEY"],
							order = 130,
							type = "toggle", --width = "full",
							get = function() return TitanAllGetVar("TooltipModiferShift") end,
							set = function(_, a)
								TitanAllSetVar("TooltipModiferShift", a);
							end,
						},
					},
				},
			},
		},
		confdesc = {
			order = 300,
			type = "header",
			name = L["TITAN_PANEL_MENU_OPTIONS_FRAMES"],
		},
		optionlock = {
			name = L["TITAN_PANEL_MENU_LOCK_BUTTONS"],
			order = 301,
			type = "toggle",
			width = "full",
			get = function() return TitanPanelGetVar("LockButtons") end,
			set = function() TitanPanelToggleVar("LockButtons") end,
		},
		optionversions = {
			name = L["TITAN_PANEL_MENU_VERSION_SHOWN"],
			order = 302,
			type = "toggle",
			width = "full",
			get = function() return TitanPanelGetVar("VersionShown") end,
			set = function() TitanPanelToggleVar("VersionShown") end,
		},
		autohidelock = {
			name = L["TITAN_PANEL_MENU_AUTOHIDE_IN_COMBAT"],
			order = 303,
			type = "toggle",
			width = "full",
			get = function() return TitanPanelGetVar("LockAutoHideInCombat") end,
			set = function() TitanPanelToggleVar("LockAutoHideInCombat") end,
		},
		space_400_1 = {
			order = 400,
			type = "description",
			name = "  ",
			cmdHidden = true,
		},
		optionlaunchers = {
			name = L["TITAN_PANEL_MENU_LDB_FORCE_LAUNCHER"],
			order = 401,
			type = "execute",
			width = "full",
			func = function() TitanPanelBarButton_ForceLDBLaunchersRight() end,
		},
		space_500_1 = {
			order = 500,
			type = "description",
			name = "  ",
			cmdHidden = true,
		},
		pluginreset = {
			name = L["TITAN_PANEL_MENU_PLUGIN_RESET"],
			desc = L["TITAN_PANEL_MENU_PLUGIN_RESET_DESC"],
			order = 501,
			type = "execute",
			width = "full",
			func = function() TitanPanel_InitPanelButtons() end,
		},
		space_600_1 = {
			order = 600,
			type = "description",
			name = "  ",
			cmdHidden = true,
		},
		optionreset = {
			name = L["TITAN_PANEL_MENU_RESET"] .. " "
				.. _G["GREEN_FONT_COLOR_CODE"]
				.. L["TITAN_PANEL_MENU_RELOADUI"],
			order = 601,
			type = "execute",
			width = "full",
			func = function() TitanPanel_ResetToDefault() end,
		}
	}
}
-------------

--============= Scale and Font

--[[ local
NAME: optionsUIScale
DESC: Local table to hold the Titan options that allow a user to adjust:
- UI scale
- Titan scale for bars
- Spacing between Titan plugins (right side)
- Spacing between Titan icons (left side)
- Titan tooltip font scale (bar and plugins)
- Toggle the tooltip font scale (allow Titan or Blizz to control)
- Set Titan font (bar and plugins)
- Set Titan font size
- Set Titan bar strata (tells Blizz which frames could go over Titan bar (and plugins)
:DESC
--]]
local optionsUIScale = {
	name = TITAN_PANEL_CONFIG.topic.scale, --L["TITAN_PANEL_UISCALE_MENU_TEXT"],
	type = "group",
	args = {
		confdesc = {
			order = 1,
			type = "description",
			name = L["TITAN_PANEL_UISCALE_MENU_DESC"] .. "\n",
			cmdHidden = true
		},
		uiscale = {
			name = L["TITAN_PANEL_UISCALE_CONTROL_TITLE_UI"],
			desc = L["TITAN_PANEL_UISCALE_SLIDER_DESC"],
			order = 2,
			type = "range",
			width = "full",
			min = 0.64,
			max = 1,
			step = 0.01,
			get = function() return UIParent:GetScale() end,
			set = function(_, a)
				SetCVar("useUiScale", 1);
				SetCVar("uiScale", a);
			end,
		},
		panelscale = {
			name = L["TITAN_PANEL_UISCALE_CONTROL_TITLE_PANEL"],
			desc = L["TITAN_PANEL_UISCALE_PANEL_SLIDER_DESC"],
			order = 3,
			type = "range",
			width = "full",
			min = 0.75,
			max = 1.25,
			step = 0.01,
			get = function() return TitanPanelGetVar("Scale") end,
			set = function(_, a)
				TitanPanelSetVar("Scale", a)
				TitanPanel_InitPanelBarButton("Config scale change " .. a)
			end,
			disabled = function()
				if InCombatLockdown() then
					return true
				else
					return false
				end
			end,
		},
		buttonspacing = {
			name = L["TITAN_PANEL_UISCALE_CONTROL_TITLE_BUTTON"],
			desc = L["TITAN_PANEL_UISCALE_BUTTON_SLIDER_DESC"],
			order = 4,
			type = "range",
			width = "full",
			min = 5,
			max = 80,
			step = 1,
			get = function() return TitanPanelGetVar("ButtonSpacing") end,
			set = function(_, a)
				TitanPanelSetVar("ButtonSpacing", a);
				TitanPanel_InitPanelButtons();
			end,
		},
		iconspacing = { -- right side plugins
			name = L["TITAN_PANEL_UISCALE_CONTROL_TITLE_ICON"],
			desc = L["TITAN_PANEL_UISCALE_ICON_SLIDER_DESC"],
			order = 5,
			type = "range",
			width = "full",
			min = 0,
			max = 20,
			step = 1,
			get = function() return TitanPanelGetVar("IconSpacing") end,
			set = function(_, a)
				TitanPanelSetVar("IconSpacing", a);
				TitanPanel_InitPanelButtons();
			end,
		},
		spacer01 = {
			type = "description",
			name = "\n\n",
			imageHeight = 0,
			order = 10,
			width = "full",
		},
		tooltipdesc = {
			order = 20,
			width = "full",
			type = "header",
			name = "Tooltip", --L["TITAN_PANEL_MENU_GLOBAL_SKIN_TITLE"],
		},
		tooltipfont = {
			name = L["TITAN_PANEL_UISCALE_CONTROL_TOOLTIP_TOOLTIPFONT"],
			desc = L["TITAN_PANEL_UISCALE_TOOLTIP_SLIDER_DESC"],
			order = 21,
			type = "range",
			width = "full",
			min = 0.5,
			max = 1.3,
			step = 0.01,
			get = function() return TitanPanelGetVar("TooltipFont") end,
			set = function(_, a)
				TitanPanelSetVar("TooltipFont", a);
			end,
		},
		tooltipfontdisable = {
			name = L["TITAN_PANEL_UISCALE_TOOLTIP_DISABLE_TEXT"],
			desc = L["TITAN_PANEL_UISCALE_DISABLE_TOOLTIP_DESC"],
			order = 22,
			type = "toggle",
			width = "full",
			get = function() return TitanPanelGetVar("DisableTooltipFont") end,
			set = function()
				TitanPanelToggleVar("DisableTooltipFont");
			end,
		},
		fontdesc = {
			order = 30,
			width = "full",
			type = "header",
			name = "Font", --L["TITAN_PANEL_MENU_GLOBAL_SKIN_TITLE"],
		},
		fontselection = {
			name = L["TITAN_PANEL_MENU_LSM_FONTS"],
			desc = L["TITAN_PANEL_MENU_LSM_FONTS_DESC"],
			order = 31,
			type = "select",
			width = "40",
			dialogControl = "LSM30_Font",
			get = function()
				return TitanPanelGetVar("FontName")
			end,
			set = function(_, v)
				TitanPanelSetVar("FontName", v)
				TitanSetPanelFont(v, TitanPanelGetVar("FontSize"))
			end,
			values = AceGUIWidgetLSMlists.font,
		},
		fontspacer = {
			order = 32,
			type = "description",
			width = "20",
			name = " ",
		},
		fontsize = {
			name = L["TITAN_PANEL_MENU_FONT_SIZE"],
			desc = L["TITAN_PANEL_MENU_FONT_SIZE_DESC"],
			order = 33,
			type = "range",
			width = "40",
			min = 7,
			max = 15,
			step = 1,
			get = function() return TitanPanelGetVar("FontSize") end,
			set = function(_, v)
				TitanPanelSetVar("FontSize", v);
				TitanSetPanelFont(TitanPanelGetVar("FontName"), v)
			end,
		},
		paneldesc = {
			order = 40,
			width = "full",
			type = "header",
			name = "Strata", --L["TITAN_PANEL_MENU_GLOBAL_SKIN_TITLE"],
		},
		panelstrata = {
			name = L["TITAN_PANEL_MENU_FRAME_STRATA"],
			desc = L["TITAN_PANEL_MENU_FRAME_STRATA_DESC"],
			order = 41,
			type = "select",
			get = function()
				return TitanPanelGetVar("FrameStrata")
			end,
			set = function(_, v)
				TitanPanelSetVar("FrameStrata", v)
				TitanVariables_SetPanelStrata(v)
			end,
			values = {
				["BACKGROUND"] = "BACKGROUND",
				["LOW"] = "LOW",
				["MEDIUM"] = "MEDIUM",
				["HIGH"] = "HIGH",
				["DIALOG"] = "DIALOG",
				["FULLSCREEN"] = "FULLSCREEN",
			},
		},
		panelstrataorder = {
			order = 42,
			type = "description",
			name = "Order of Strata\n"
				.. "- BACKGROUND\n"
				.. "- LOW - default\n"
				.. "- MEDIUM\n"
				.. "- HIGH\n"
				.. "- DIALOG\n"
				.. "- FULLSCREEN\n",
			cmdHidden = true
		},
	}
}
-------------

--============= Skins

--[[ local
NAME: optionsSkins
DESC: Local table to hold the Titan skins options. Shows default Titan and any custom skins the user has added.
--]]
local optionsSkins = {
	name = TITAN_PANEL_CONFIG.topic.skins,
	type = "group",
	args = {
	}
}

local function Show_Skins(t, position)
	--[[
	table.sort(TitanSkins, function(a, b)
		return string.lower(TitanSkins[a].name)
			< string.lower(TitanSkins[b].name)
		end)
--]]
	local skin = "Skin"
	t[skin .. position] = {
		type = "description",
		name = ""
			.. L["TITAN_PANEL_MENU_SKIN_CHANGE"] .. "\n"
			.. "- " .. L["TITAN_PANEL_MENU_OPTIONS_BARS"] .. "\n"
			.. "- " .. L["TITAN_PANEL_MENU_OPTIONS_BARS_ALL"] .. "\n"
			.. "",
		cmdHidden = true,
		order = position,
	}

	for idx, v in pairs(TitanSkins) do
		position = position + 1 -- spacer
		t[skin .. position] = {
			type = "header",
			name = "",
			order = position,
			width = "full",
		}

		position = position + 1 -- Name of skin (col 1)
		t[skin .. position] = {
			type = "description",
			name = TitanUtils_GetHexText(v.name, Titan_Global.colors.green),
			order = position,
			width = "30",
		}

		position = position + 1 -- Top image (col 2)
		t[skin .. position] = {
			type = "description",
			name = "",
			image = v.path .. "TitanPanelBackgroundTop0",
			imageWidth = 256,
			order = position,
			width = "50",
		}

		position = position + 1 -- spacer
		t[skin .. position] = {
			type = "description",
			name = "",
			imageHeight = 0,
			order = position,
			width = "full",
		}

		position = position + 1 -- Bottom (col 1)
		t[skin .. position] = {
			type = "description",
			name = "",
			order = position,
			width = "30",
		}
		position = position + 1 -- Bottom image (col 2)
		t[skin .. position] = {
			type = "description",
			name = "",
			image = v.path .. "TitanPanelBackgroundBottom0",
			imageWidth = 256,
			order = position,
			width = "50",
		}

		position = position + 1 -- final spacer - bottom of config
		t[skin .. position] = {
			type = "description",
			name = "",
			imageHeight = 0,
			order = position,
			width = "full",
		}
	end

	position = position + 1 -- final spacer - bottom of config
	t[skin .. position] = {
		type = "description",
		name = "",
		order = position,
		width = "full",
	}
end

local function BuildSkins()
	optionsSkins.args = {}

	Show_Skins(optionsSkins.args, 100) -- the current list of skins with images
	AceConfigRegistry:NotifyChange("Titan Panel Skin Control")
end

--============= Skins - Custom

--[[ local
NAME: TitanPanel_AddNewSkin
DESC: Add each skin to the options list. If the user had added custom skins these will be shown as well.
VAR: skinname - the file name to use
VAR: skinpath - the file path to use
OUT:  None
NOTE:
- Blizz *does not allow* LUA to access the user file system dynamically so the skins have to be input by hand. Titan can not search for available skins in the Artwork folder.
- On the flip side a user can add a custom skin to the Titan saved variables then later delete the skin from the file system. This will not cause an error when the user tries to use (show) that skin but Titan will show a 'blank' skin.
:NOTE
--]]
local function TitanPanel_AddNewSkin(skinname, skinpath)
	-- name and path must be provided
	if not skinname or not skinpath then return end

	-- name cannot be empty or "None", path cannot be empty
	if skinname == "" or skinname == L["TITAN_PANEL_NONE"] or skinpath == "" then
		return
	end

	-- Assume the skin is already in the Titan saved variables list
	local found
	for _, i in pairs(TitanSkins) do
		if i.name == skinname or i.path == skinpath then
			found = true
			break
		end
	end

	-- The skin is new so add it to the Titan saved variables list
	if not found then
		table.insert(TitanSkins, { name = skinname, path = skinpath })
	end

	BuildSkins()
end

--[[ local
NAME: optionsSkinsCustom
DESC: Local table to hold the Titan custom skins options that allow a user to add or delete skins.
- You may not remove the currently used skin
- or the default one
- or a Titan default skin (it would only come back...)
:DESC
--]]
local optionsSkinsCustom = {
	name = TITAN_PANEL_CONFIG.topic.skinscust, --L["TITAN_PANEL_SKINS_TITLE_CUSTOM"],
	type = "group",
	args = {
		confdesc = {
			order = 1,
			type = "description",
			name = L["TITAN_PANEL_SKINS_MAIN_DESC"] .. "\n",
			cmdHidden = true
		},
		nulloption1 = {
			order = 5,
			type = "description",
			name = "   ",
			cmdHidden = true
		},
		addskinheader = {
			order = 10,
			type = "header",
			name = L["TITAN_PANEL_SKINS_NEW_HEADER"],
		},
		newskinname = {
			order = 11,
			name = L["TITAN_PANEL_SKINS_NAME_TITLE"],
			desc = L["TITAN_PANEL_SKINS_NAME_DESC"],
			type = "input",
			width = "full",
			get = function() return TitanSkinName end,
			set = function(_, v) TitanSkinName = v end,
		},
		newskinpath = {
			order = 12,
			name = L["TITAN_PANEL_SKINS_PATH_TITLE"],
			desc = L["TITAN_PANEL_SKINS_PATH_DESC"],
			type = "input",
			width = "full",
			get = function() return TitanSkinPath end,
			set = function(_, v) TitanSkinPath = TitanSkinsCustomPath .. v .. TitanSkinsPathEnd end,

		},
		addnewskin = {
			order = 13,
			name = L["TITAN_PANEL_SKINS_ADD_HEADER"],
			type = "execute",
			desc = L["TITAN_PANEL_SKINS_ADD_DESC"],
			func = function()
				if TitanSkinName ~= "" and TitanSkinPath ~= "" then
					TitanPanel_AddNewSkin(TitanSkinName, TitanSkinPath)
					TitanSkinName = ""
					TitanSkinPath = ""
					-- Config Tables changed!
					AceConfigRegistry:NotifyChange("Titan Panel Skin Custom")
				end
			end,
		},
		nulloption2 = {
			order = 14,
			type = "description",
			name = "   ",
			cmdHidden = true
		},
		removeskinheader = {
			order = 20,
			type = "header",
			name = L["TITAN_PANEL_SKINS_REMOVE_HEADER"],
		},
		removeskinlist = {
			order = 21,
			type = "select",
			width = "full",
			name = L["TITAN_PANEL_SKINS_REMOVE_HEADER"],
			desc = L["TITAN_PANEL_SKINS_REMOVE_DESC"],
			get = function() return TitanSkinToRemove end,
			set = function(_, v)
				TitanSkinToRemove = v
			end,
			values = function()
				local Skinlist = {}
				local v;
				for _, v in pairs(TitanSkins) do
					if v.path ~= TitanPanelGetVar("TexturePath")
						and v.path ~= "Interface\\AddOns\\Titan\\Artwork\\"
						and v.titan ~= true
					then
						Skinlist[v.path] = TitanUtils_GetHexText(v.name, Titan_Global.colors.green)
					end
					if v.path == TitanSkinToRemove then
						Skinlist[v.path] = TitanUtils_GetHexText(v.name, Titan_Global.colors.yellow)
					end
				end
				if TitanSkinToRemove ~= "None" then
					Skinlist["None"] = TitanUtils_GetHexText(L["TITAN_PANEL_NONE"], Titan_Global.colors.green)
				else
					Skinlist["None"] = TitanUtils_GetHexText(L["TITAN_PANEL_NONE"], Titan_Global.colors.yellow)
				end
				table.sort(Skinlist, function(a, b)
					return string.lower(TitanSkins[a].name)
						< string.lower(TitanSkins[b].name)
				end)
				return Skinlist
			end,
		},
		removeskin = {
			order = 22,
			type = "execute",
			name = L["TITAN_PANEL_SKINS_REMOVE_BUTTON"],
			desc = L["TITAN_PANEL_SKINS_REMOVE_BUTTON_DESC"],
			func = function()
				if TitanSkinToRemove == "None" then return end
				local k, v;
				for k, v in pairs(TitanSkins) do
					if v.path == TitanSkinToRemove then
						table.remove(TitanSkins, k)
						TitanSkinToRemove = "None"
						-- Config Tables changed!
						AceConfigRegistry:NotifyChange("Titan Panel Skin Custom")
						break
					end
				end
			end,
		},
		nulloption4 = {
			order = 24,
			type = "description",
			name = "   ",
			cmdHidden = true
		},
		resetskinhdear = {
			order = 200,
			type = "header",
			name = L["TITAN_PANEL_SKINS_RESET_HEADER"],
		},
		defaultskins = {
			order = 201,
			name = L["TITAN_PANEL_SKINS_RESET_DEFAULTS_TITLE"],
			type = "execute",
			desc = L["TITAN_PANEL_SKINS_RESET_DEFAULTS_DESC"],
			func = function()
				TitanSkins = TitanSkinsDefault;
				BuildSkins()
			end,
		},
		notes_delete = {
			order = 999,
			type = "description",
			name = "\n\n" .. L["TITAN_PANEL_SKINS_REMOVE_NOTES"] .. "\n",
			cmdHidden = true
		},
	}
}
-------------

--============= Extras

--[[ local
NAME: optionsExtras
DESC: This is the table shell. The plugin info will be added by another routine.
--]]
local optionsExtras = {
	name = TITAN_PANEL_CONFIG.topic.extras, --L["TITAN_PANEL_EXTRAS"],
	type = "group",
	args = {}
}

--[[ local
NAME: TitanUpdateAddonAttempts
DESC: Show plugins that are not registered (loaded) but have config data. The data can be deleted by the user.
VAR:  None
OUT:  None
NOTE:
- As users change the plugins they use the old ones still have saved variable data stored by Titan.
- The old plugin data can be removed by the user when they will not longer use that plugin.
- This routine is called to 'redraw' the list as a user deletes data.
- A message is sent to chat that the plugin data has been deleted.
:NOTE
--]]
local function TitanUpdateExtras()
	local args = optionsExtras.args
	local plug_in = nil

	wipe(args)

	args["desc"] = {
		order = 1,
		type = "description",
		name = L["TITAN_PANEL_EXTRAS_DESC"] .. "\n",
		cmdHidden = true
	}
	for idx, value in pairs(TitanPluginExtras) do
		if TitanPluginExtras[idx] then
			local num = TitanPluginExtras[idx].num
			local name = TitanPluginExtras[idx].id
			args[name] = {
				type = "group",
				name = TitanUtils_GetGoldText(tostring(num) .. ": " .. (name or "?")),
				order = idx,
				args = {
					name = {
						type = "description",
						name = TitanUtils_GetGoldText(name or "?"),
						cmdHidden = true,
						order = 10,
					},
					optionreset = {
						name = L["TITAN_PANEL_EXTRAS_DELETE_BUTTON"],
						order = 15,
						type = "execute",
						width = "full",
						func = function(info, v)
							TitanPluginSettings[info[1]] = nil -- delete the config entry
							TitanPrint(
								" '" .. info[1] .. "' " .. L["TITAN_PANEL_EXTRAS_DELETE_MSG"]
								, "info")
							--							TitanVariables_ExtraPluginSettings() -- rebuild the list
							TitanUpdateExtras()                   -- rebuild the options config
							AceConfigRegistry:NotifyChange("Titan Panel Addon Extras") -- tell Ace to redraw
						end,
					},
				}
			}
		end
	end

	AceConfigRegistry:NotifyChange("Titan Panel Addon Extras")
end
-------------

--============= Attempts

--[[ local
NAME: optionsAddonAttempts
DESC: This is the table shell. The plugin info will be added by another routine.
--]]
local optionsAddonAttempts = {
	name = TITAN_PANEL_CONFIG.topic.attempts, --L["TITAN_PANEL_ATTEMPTS"],
	type = "group",
	args = {}
}

--[[ local
NAME: TitanUpdateAddonAttempts
DESC: Show the each plugin that attempted to register with Titan. This can be used by plugin developers as the create / update plugins (Titan or LDB). It can also be used by user to attempt to figure out why a plugin is not shown or to report an issue to Titan.
VAR:  None
OUT:  None
NOTE:
- This is called after the plugins are registered in the 'player entering world' event. It can be called again as plugins registered.
- Any plugins that attempted to register are shown. See the Titan Utils section for more details on plugin registration.
- This option page is for display only. The user can take not action.
:NOTE
--]]
local function TitanUpdateAddonAttempts()
	local args = optionsAddonAttempts.args
	local plug_in = nil

	wipe(args)

	args["desc"] = {
		order = 0,
		type = "description",
		name = L["TITAN_PANEL_ATTEMPTS_DESC"],
		cmdHidden = true
	}
	for idx, value in pairs(TitanPluginToBeRegistered) do
		if TitanPluginToBeRegistered[idx]
		then
			local num = tostring(idx)
			local button = TitanPluginToBeRegistered[idx].button
			local name = (TitanPluginToBeRegistered[idx].name or "?")
			local reason = TitanPluginToBeRegistered[idx].status
			local issue = TitanPluginToBeRegistered[idx].issue
			local notes = TitanPluginToBeRegistered[idx].notes or ""
			local category = TitanPluginToBeRegistered[idx].category
			local ptype = TitanPluginToBeRegistered[idx].plugin_type
			local btype = TitanPanelButton_GetType(idx)
			local title = TitanPluginToBeRegistered[idx].name
			if reason ~= TITAN_REGISTERED then
				title = TitanUtils_GetRedText(title)
				issue = TitanUtils_GetRedText(issue)
			end

			args[num] = {
				type = "group",
				name = title,
				order = idx,
				args = {
					name = {
						type = "description",
						name = TitanUtils_GetGoldText("") .. name,
						cmdHidden = true,
						order = 1,
					},
					reason = {
						type = "description",
						name = TitanUtils_GetGoldText(L["TITAN_PANEL_ATTEMPTS_STATUS"] .. ": ") .. reason,
						cmdHidden = true,
						order = 2,
					},
					issue = {
						type = "description",
						name = TitanUtils_GetGoldText(L["TITAN_PANEL_ATTEMPTS_ISSUE"] .. ": \n") .. issue,
						cmdHidden = true,
						order = 3,
					},
					notes = {
						type = "description",
						name = TitanUtils_GetGoldText(L["TITAN_PANEL_ATTEMPTS_NOTES"] .. ": \n") .. notes,
						cmdHidden = true,
						order = 4,
					},
					sp_1 = {
						type = "description",
						name = "",
						cmdHidden = true,
						order = 5,
					},
					category = {
						type = "description",
						name = TitanUtils_GetGoldText(L["TITAN_PANEL_ATTEMPTS_CATEGORY"] .. ": ") .. category,
						cmdHidden = true,
						order = 10,
					},
					ptype = {
						type = "description",
						name = TitanUtils_GetGoldText(L["TITAN_PANEL_ATTEMPTS_TYPE"] .. ": ") .. ptype, --.." "..btype,
						cmdHidden = true,
						order = 11,
					},
					button = {
						type = "description",
						name = TitanUtils_GetGoldText(L["TITAN_PANEL_ATTEMPTS_BUTTON"] .. ": ") .. button,
						cmdHidden = true,
						order = 12,
					},
					num_val = {
						type = "description",
						name = TitanUtils_GetGoldText(L["TITAN_PANEL_ATTEMPTS_TABLE"] .. ": ") .. num,
						cmdHidden = true,
						order = 13,
					},
				}
			}
		end
	end

	-- Config Tables changed!
	AceConfigRegistry:NotifyChange(L["TITAN_PANEL"])
end
-------------

--============= Advanced

local conftimerdesc = {
	name = L["TITAN_PANEL_MENU_ADV_TIMER"],
	type = "group",
	inline = true,
	order = 1,
	args = {
		confdesc = {
			order = 10,
			type = "description",
			name = L["TITAN_PANEL_MENU_ADV_TIMER_DESC"],
			cmdHidden = true
		},
		advtimerpew = {
			name = L["TITAN_PANEL_MENU_ADV_PEW"],
			desc = L["TITAN_PANEL_MENU_ADV_PEW_DESC"],
			order = 20,
			type = "range",
			width = "full",
			min = 1,
			max = 10,
			step = 0.5,
			get = function() return TitanAllGetVar("TimerPEW") end,
			set = function(_, a)
				TitanAllSetVar("TimerPEW", a);
				TitanTimers["EnterWorld"].delay = a
			end,
		},
		advtimervehicle = {
			name = L["TITAN_PANEL_MENU_ADV_VEHICLE"],
			desc = L["TITAN_PANEL_MENU_ADV_VEHICLE_DESC"],
			order = 50,
			type = "range",
			width = "full",
			min = 1,
			max = 10,
			step = 0.5,
			get = function() return TitanAllGetVar("TimerVehicle") end,
			set = function(_, a)
				TitanAllSetVar("TimerVehicle", a);
				TitanTimers["Vehicle"].delay = a
			end,
		},
	},
}
local confbuffdesc = {
	name = L["TITAN_PANEL_MENU_ADV_BUFF"],
	type = "group",
	inline = true,
	order = 2,
	args = {
		confbuffdesc = {
			order = 110,
			type = "description",
			name = L["TITAN_PANEL_MENU_ADV_BUFF_DESC"],
			cmdHidden = true
		},
		advbuffadj = {
			name = "Buff", --L["TITAN_PANEL_MENU_ADV_PEW"],
			desc = "", -- L["TITAN_PANEL_MENU_ADV_PEW_DESC"],
			order = 120,
			type = "range",
			width = "full",
			min = -100,
			max = 100,
			step = 1,
			get = function() return TitanPanelGetVar("BuffIconVerticalAdj") end,
			set = function(_, a)
				TitanPanelSetVar("BuffIconVerticalAdj", a);
				-- Adjust frame positions
				TitanPanel_AdjustFrames(true, "BuffIconVerticalAdj")
			end,
		},
	},
}

--[[ local
NAME: optionsAdvanced
DESC: Set the table to allow the user to control advanced features.
Controls:
- Entering world timer - some users need Titan to wait longer whenever the splash / loading screen is shown before adjusting frames and (re)setting data.
- Vehicle timer - some users need Titan to wait longer whenever entering or leaving a vehicle before adjusting frames.
:DESC
--]]
local optionsAdvanced = {
	name = TITAN_PANEL_CONFIG.topic.advanced, --L["TITAN_PANEL_MENU_ADV"],
	type = "group",
	args = {
		confoutputdesc = {
			name = L["TITAN_PANEL_MENU_ADV_OUTPUT"],
			type = "group",
			inline = true,
			order = 100,
			args = {
				confdesc = {
					order = 110,
					type = "description",
					name = L["TITAN_PANEL_MENU_ADV_OUTPUT_DESC"],
					cmdHidden = true
				},
				advname = {
					name = L["TITAN_PANEL_MENU_ADV_NAME"],
					desc = L["TITAN_PANEL_MENU_ADV_NAME_DESC"],
					order = 120,
					type = "toggle",
					width = "full",
					get = function() return not TitanAllGetVar("Silenced") end, -- yes, we did it to ourselves...
					set = function(_, a)
						TitanAllSetVar("Silenced", not a);
					end,
				},
				advplugins = {
					name = L["TITAN_PANEL_MENU_ADV_PLUGINS"],
					desc = L["TITAN_PANEL_MENU_ADV_PLUGINS_DESC"],
					order = 120,
					type = "toggle",
					width = "full",
					get = function() return TitanAllGetVar("Registered") end,
					set = function(_, a)
						TitanAllSetVar("Registered", a);
					end,
				},
			},
		},
		devoutputdesc = {
			name = "Developer Only",
			type = "group",
			inline = true,
			order = 200,
			args = {
				confdesc = {
					order = 110,
					type = "description",
					name = "Debug Output",
					cmdHidden = true
				},
				advname = {
					name = "Tooltip",
					desc = "Tooltip debug output to Chat",
					order = 120,
					type = "toggle",
					width = "full",
					get = function() return Titan_Global.debug.tool_tips end,
					set = function(_, a)
						Titan_Global.debug.tool_tips = not Titan_Global.debug.tool_tips
					end,
				},
				advplugins = {
					name = "Plugin",
					desc = "Plugin debug output to Chat",
					order = 130,
					type = "toggle",
					width = "full",
					get = function() return Titan_Global.debug.plugin_text end,
					set = function(_, a)
						Titan_Global.debug.plugin_text = not Titan_Global.debug.plugin_text
					end,
				},
			},
		},
	},
}

local function BuildAdv()
	if Titan_Global.switch.can_edit_ui then
	else
		optionsAdvanced.args.conftimerdesc = conftimerdesc
		optionsAdvanced.args.confbuffdesc = confbuffdesc
	end

	AceConfigRegistry:NotifyChange("Titan Panel Advanced")
end

-------------


--============= Change History

--[[ local
NAME: Recent change history
DESC: Show change history of releases
:DESC
--]]
local changeHistory = {
	name = TITAN_PANEL_CONFIG.topic.changes, --L["TITAN_PANEL_MENU_ADV"],
	type = "group",
	args = {
		confchanges = {
			order = 7,
			name = " ", --CHANGES_COLON,
			type = "group",
			inline = true,
			args = {
				confversiondesc = {
					order = 1,
					type = "description",
					name = "" .. Titan_Global.recent_changes,
					cmdHidden = true
				},
			}
		},
	},
}


--============= / Command

--[[ local
NAME: slash command help
DESC: Show detailed help for slash commands
:DESC
--]]
local slashHelp = {
	name = TITAN_PANEL_CONFIG.topic.slash,
	type = "group",
	args = {
		confslash = {
			name = L["TITAN_PANEL_MENU_HELP"],
			order = 3,
			type = "group",
			inline = true,
			args = {
				confversiondesc = {
					order = 1,
					type = "description",
					name = ""
						.. TitanUtils_GetGoldText("reset\n")
						.. L["TITAN_PANEL_SLASH_RESET_0"] .. "\n"
						.. L["TITAN_PANEL_SLASH_RESET_1"] .. "\n"
						.. L["TITAN_PANEL_SLASH_RESET_2"] .. "\n"
						.. L["TITAN_PANEL_SLASH_RESET_3"] .. "\n"
						.. L["TITAN_PANEL_SLASH_RESET_4"] .. "\n"
						.. L["TITAN_PANEL_SLASH_RESET_5"] .. "\n"
						.. "\n"
						.. TitanUtils_GetGoldText("gui\n")
						.. L["TITAN_PANEL_SLASH_GUI_0"] .. "\n"
						.. L["TITAN_PANEL_SLASH_GUI_1"] .. "\n"
						.. L["TITAN_PANEL_SLASH_GUI_2"] .. "\n"
						.. L["TITAN_PANEL_SLASH_GUI_3"] .. "\n"
						.. "\n"
						.. TitanUtils_GetGoldText("profile\n")
						.. L["TITAN_PANEL_SLASH_PROFILE_0"] .. "\n"
						.. L["TITAN_PANEL_SLASH_PROFILE_1"] .. "\n"
						.. L["TITAN_PANEL_SLASH_PROFILE_2"] .. "\n"
						.. L["TITAN_PANEL_SLASH_PROFILE_3"] .. "\n"
						.. "\n"
						.. TitanUtils_GetGoldText("silent\n")
						.. L["TITAN_PANEL_SLASH_SILENT_0"] .. "\n"
						.. L["TITAN_PANEL_SLASH_SILENT_1"] .. "\n"
						.. "\n"
						.. TitanUtils_GetGoldText("orderhall\n")
						.. L["TITAN_PANEL_SLASH_ORDERHALL_0"] .. "\n"
						.. L["TITAN_PANEL_SLASH_ORDERHALL_1"] .. "\n"
						.. "\n"
						.. TitanUtils_GetGoldText("help\n")
						.. L["TITAN_PANEL_SLASH_HELP_0"] .. "\n"
						.. L["TITAN_PANEL_SLASH_HELP_1"] .. "\n"
						.. "\n"
						.. TitanUtils_GetGoldText("all\n")
						.. L["TITAN_PANEL_SLASH_ALL_0"] .. "\n"
						.. L["TITAN_PANEL_SLASH_ALL_1"] .. "\n"
						.. "",
					cmdHidden = true
				},
			}
		},
	},
}
-------------

--============= / Help

local help_text = ""
do -- set help_text
	help_text = ""
		.. TitanUtils_GetGreenText("Plugins: \n")
		.. TitanUtils_GetGoldText("Show / Hide Plugins :")
		.. TitanUtils_GetHighlightText(""
			.. " Use one of the methods below:\n"
			.. "- Open the right-click Bar menu; find the plugin in a category then click to toggle Show on the plugin.\n"
			..
			"- Open Titan Configuration > Plugins then select the plugin by name then toggle Show. Uuse the Bar dropdown to select the Bar the plugin should be on.\n"
		)
		.. TitanUtils_GetGoldText("Moving Plugins :")
		.. TitanUtils_GetHighlightText(""
			.. " Use one of the methods below:\n"
			..
			"- Open the right-click Bar menu of the Bar you want the plugin on; find the plugin in a category then toggle Show. If plugin is already shown on another Bar then toggle again to have it appear in this Bar.\n"
			.. "- Drag and drop on another bar or on the same bar.\n"
			.. "- Drag and drop on another plugin to swap the plugins.\n"
			..
			"- Open Titan Configuration > Plugins then toggle Show. Use the Bar dropdown and Right / Left buttons to place the plugin as desired.\n"
		)
		.. "\n\n"
		.. TitanUtils_GetGreenText("Short Bars: \n")
		.. TitanUtils_GetHighlightText(""
			.. "Short bars are 10 shorter Titan bars that the user can place and change width.\n"
			.. "- Short bars are independent. They may be used with or without the full width Titan bars.\n"
			..
			"- Titan does not restrict plugins to fit within the visible width (background). Using Configuration, plugins can be assigned well beyond the visible side. This may be desirable for some users.\n"
			..
			"- Setting a plugin to right-side will use the visible right side (background); and may overlap with left or center aligned plugins.\n"
		)
		.. TitanUtils_GetGoldText("Enable :\n")
		.. TitanUtils_GetHighlightText(""
			.. "- Open Configuration > Bars to enable and change Bar options.\n"
			.. "- The default position is the top center under the full width bars. They will be stacked to not overlap.\n"
		)
		.. TitanUtils_GetGoldText("Change Size :\n")
		.. TitanUtils_GetHighlightText(""
			.. "- Change width by 1 : Use Shift + mouse wheel.\n"
			.. "- Change width by 10: Use Shift + Ctrl + mouse wheel.\n"
			.. "- WIll not go beyond right side of screen.\n"
		)
		.. TitanUtils_GetGoldText("Move :\n")
		.. TitanUtils_GetHighlightText(""
			.. "- Use Shift + left mouse on Bar, not plugins, and drag.\n"
			.. "- When dragging, best to place your mouse over the left side padding before moving or changing width.\n"
			.. "- When dragging stops, if the Short Bar is beyond the screen edge the Short Bar should 'snap' to the edge.\n"
		)
		.. TitanUtils_GetGoldText("Reset :\n")
		.. TitanUtils_GetHighlightText(""
			..
			" In case a Short bar gets messed up, use Config > Bar > <Pick the Bar> then click Reset Position to place it at original position and width.\n"
		)
		.. TitanUtils_GetGoldText("Skin :\n")
		.. TitanUtils_GetHighlightText(""
			.. "- Can select Skin per Short bar BUT only the 'top' skin is used; some skins have a different top & bottom.\n"
		)
		.. TitanUtils_GetGoldText("Limitations :\n")
		.. TitanUtils_GetHighlightText(""
			.. "- Min width : Left side padding plus one icon width.\n"
			.. "- Max width : Screen width.\n"
			.. "- There is no 'snap together' or grid for placing Short Bars.\n"
			.. "\n"
		)
		.. TitanUtils_GetGreenText("All Bars: \n")
		.. TitanUtils_GetHighlightText(""
			.. "- Bar Right click menu shows the name of the Bar in the menu title. Same name in configuration options.\n"
			.. "- Hide any Titan bar by using the Bar Right click menu then click Hide.\n"
		)
		.. TitanUtils_GetGoldText("Skins :\n")
		.. TitanUtils_GetHighlightText(""
			.. "- Select per Titan bar.\n"
			.. "- Select a skin for all Titan bars. This does NOT change the individual Titan bar skin settings.\n"
		)
		.. TitanUtils_GetGoldText("Hide in Combat :\n")
		.. TitanUtils_GetHighlightText(""
			.. "- Select per Titan bar.\n"
			.. "- Hide all Titan bars during combat. This does NOT change the individual Titan bar hide in combat settings.\n"
		)
		.. TitanUtils_GetGoldText("Bar Order (English) :")
		.. TitanUtils_GetHighlightText(""
			.. " Configuration > Bars shows localized Bar names.\n"
			.. "- Top   : Always top of screen\n"
			.. "- Top 2 : Always under Top Bar\n"
			.. "- Bottom 2 : Always above Bottom Bar\n"
			.. "- Bottom   : Always bottom of screen\n"
			.. "- Short 01 - 10 : User placed\n"
		)
		.. "\n\n"
end
--[[ local
NAME: helpBars
DESC: Help for the Titan Panel user
:DESC
--]]
local helpBars = {
	name = TITAN_PANEL_CONFIG.topic.help,
	type = "group",
	args = {
		confgendesc = {
			name = "Help",
			order = 1,
			type = "group",
			inline = true,
			args = {
				confdesc = {
					order = 1,
					type = "description",
					name = help_text,
					cmdHidden = true
				},
			}
		},
	}
}
-------------

-------------

---Titan This routine will handle the requests to update the various data items in Titan options screens.
--- This is called after the plugins are registered in the 'player entering world' event. It can be called again as more plugins are registered.
---@param action string "init" or "nuke"
function TitanUpdateConfig(action)
	if action == "init" then
		-- Update the tables for the latest lists
		TitanUpdateConfigAddons()
		TitanUpdateAddonAttempts()
		TitanUpdateExtras()
		TitanUpdateChars()
		BuildSkins()
		BuildBars()
		BuildAdj()
		BuildAdv()
	end
	if action == "nuke" then
		local nuked = {
			name = "Titan could not initialize properly.", --L["TITAN_PANEL_DEBUG"],
			type = "group",
			args = {}
		}

		TitanPrint("-- Clearing Titan options...", "warning")
		-- Use the same group as below!!
		--		AceConfig:RegisterOptionsTable("Titan Panel Main", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Bars", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Globals", nuked)
		--		AceConfig:RegisterOptionsTable("Titan Panel Aux Bars", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Frames", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Transparency Control", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Panel Control", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Skin Control", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Skin Custom", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Addon Control", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Addon Attempts", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Addon Extras", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Addon Chars", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Addon Advanced", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Addon Changes", nuked)
		AceConfig:RegisterOptionsTable("Titan Panel Addon Slash", nuked)
	end
end

--[[
Register the options tables with Ace then register the options with Blizz so the user can use them.
--]]
-- Add Blizzard Configuration Panels
--[[ The first param needs to used for the 'add to options'
The second param must be the table Ace will use to create the user options
--]]
AceConfig:RegisterOptionsTable("Titan Panel Main", titan_entry)
AceConfig:RegisterOptionsTable("Titan Panel Bars", optionsBars)
AceConfig:RegisterOptionsTable("Titan Panel Globals", optionsGlobals)
AceConfig:RegisterOptionsTable("Titan Panel Adjust", optionsAdjust)
AceConfig:RegisterOptionsTable("Titan Panel Frames", optionsFrames)
AceConfig:RegisterOptionsTable("Titan Panel Panel Control", optionsUIScale)
AceConfig:RegisterOptionsTable("Titan Panel Skin Control", optionsSkins)
AceConfig:RegisterOptionsTable("Titan Panel Skin Custom", optionsSkinsCustom)
AceConfig:RegisterOptionsTable("Titan Panel Addon Control", optionsAddons)
AceConfig:RegisterOptionsTable("Titan Panel Addon Attempts", optionsAddonAttempts)
AceConfig:RegisterOptionsTable("Titan Panel Addon Extras", optionsExtras)
AceConfig:RegisterOptionsTable("Titan Panel Addon Chars", optionsChars)
AceConfig:RegisterOptionsTable("Titan Panel Addon Advanced", optionsAdvanced)
AceConfig:RegisterOptionsTable("Titan Panel Addon Changes", changeHistory)
AceConfig:RegisterOptionsTable("Titan Panel Addon Slash", slashHelp)
AceConfig:RegisterOptionsTable("Titan Panel Help", helpBars)
--]]
-- Set the main options pages
--[[ The first param must be the same as the cooresponding 'Ace register'
The second param should be the same as the .name of the cooresponding table that was registered,
if not, any 'open' may fail.
--]]
--AceConfigDialog:AddToBlizOptions("Titan Panel Main", L["TITAN_PANEL"])
AceConfigDialog:AddToBlizOptions("Titan Panel Main", titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Bars", optionsBars.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Globals", optionsGlobals.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Adjust", optionsAdjust.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Addon Control", optionsAddons.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Addon Chars", optionsChars.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Frames", optionsFrames.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Panel Control", optionsUIScale.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Skin Control", optionsSkins.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Skin Custom", optionsSkinsCustom.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Addon Extras", optionsExtras.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Addon Attempts", optionsAddonAttempts.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Addon Advanced", optionsAdvanced.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Addon Changes", changeHistory.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Addon Slash", slashHelp.name, titan_entry.name)
AceConfigDialog:AddToBlizOptions("Titan Panel Help", helpBars.name, titan_entry.name)
