local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Artwork_Classic");
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	if (DBMod.Artwork.Theme == "Classic") then
		Init();
	else
		module:Disable();
	end
end

function module:OnEnable()
	if (DBMod.Artwork.Theme == "Classic") then
		if (not InitRan) then Init(); end
		module:EnableFramework();
		module:EnableActionBars();
		module:EnableMinimap();
		module:EnableStatusBars();
	end
end

function Init()
	SetupMenus();
	module:InitFramework();
	module:InitActionBars();
	module:InitMinimap();
	module:InitStatusBars();
	InitRan = true;
end

function SetupMenus()
	spartan.opt.Artwork.args["backdrop"] = { name = "ActionBar Settings", type = "group",
		desc = L["ActionBarConfDesc"],
		args = {
			Allalpha = {name = L["AllBarAlpha"], type="range", order = 15,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.Allalpha; end,
				set = function(info,val) for i = 1,6 do DB.ActionBars["bar"..i].alpha,DB.ActionBars.Allalpha = val,val; end end
			},
			Allenable = {name = L["AllBarEnable"], type="toggle", order= 16,
				get = function(info) return DB.ActionBars.Allenable; end,
				set = function(info,val) for i = 1,6 do DB.ActionBars["bar"..i].enable,DB.ActionBars.Allenable = val,val; end end
			},
			bar1alpha = {name = L["BarAlpha"].." 1", type="range", order = 1,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar1.alpha; end,
				set = function(info,val) if DB.ActionBars.bar1.enable == true then DB.ActionBars.bar1.alpha = val end end
			},
			bar1enable = {name = L["BarEnable"].." 1", type="toggle", order= 2,
				get = function(info) return DB.ActionBars.bar1.enable; end,
				set = function(info,val) DB.ActionBars.bar1.enable = val end
			},
			bar2alpha = {name = L["BarAlpha"].." 2", type="range", order = 3,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar2.alpha; end,
				set = function(info,val) if DB.ActionBars.bar2.enable == true then DB.ActionBars.bar2.alpha = val end end
			},
			bar2enable = {name = L["BarEnable"].." 2", type="toggle", order= 4,
				get = function(info) return DB.ActionBars.bar2.enable; end,
				set = function(info,val) DB.ActionBars.bar2.enable = val end
			},
			bar3alpha = {name = L["BarAlpha"].." 3", type="range", order = 5,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar3.alpha; end,
				set = function(info,val) if DB.ActionBars.bar3.enable == true then DB.ActionBars.bar3.alpha = val end end
			},
			bar3enable = {name = L["BarEnable"].." 3", type="toggle", order= 6,
				get = function(info) return DB.ActionBars.bar3.enable; end,
				set = function(info,val) DB.ActionBars.bar3.enable = val end
			},
			bar4alpha = {name = L["BarAlpha"].." 4", type="range", order = 7,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar4.alpha; end,
				set = function(info,val) if DB.ActionBars.bar4.enable == true then DB.ActionBars.bar4.alpha = val end end
			},
			bar4enable = {name = L["BarEnable"].." 4", type="toggle", order= 8,
				get = function(info) return DB.ActionBars.bar4.enable; end,
				set = function(info,val) DB.ActionBars.bar4.enable = val end
			},
			bar5alpha = {name = L["BarAlpha"].." 5", type="range", order = 9,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar5.alpha; end,
				set = function(info,val) if DB.ActionBars.bar5.enable == true then DB.ActionBars.bar5.alpha = val end end
			},
			bar5enable = {name = L["BarEnable"].." 5", type="toggle", order= 10,
				get = function(info) return DB.ActionBars.bar5.enable; end,
				set = function(info,val) DB.ActionBars.bar5.enable = val end
			},
			bar6alpha = {name = L["BarAlpha"].." 6", type="range", order = 11,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar6.alpha; end,
				set = function(info,val) if DB.ActionBars.bar6.enable == true then DB.ActionBars.bar6.alpha = val end end
			},
			bar6enable = {name = L["BarEnable"].." 6", type="toggle", order= 12,
				get = function(info) return DB.ActionBars.bar6.enable; end,
				set = function(info,val) DB.ActionBars.bar6.enable = val end
			},
			reset = {
				type = "execute",
				name = "Reset ActionBars",
				desc = "resets all ActionBar options to default",
				order= 99,
				width= "full",
				func = function()
					if (InCombatLockdown()) then 
						spartan:Print(ERR_NOT_IN_COMBAT);
					else
						DB.ActionBars = {};
						SetupProfile();
					end
				end
			}
		}
	};
	spartan.opt.Artwork.args["popup"] = { name = L["PopupAnimConf"], type = "group",
		desc = L["PopupAnimConfDesc"],
		args = {
			popup1anim = {	name = L["LPopupAnimate"], type="toggle", order=1, width="full",
				get = function(info) return DB.ActionBars.popup1.anim; end,
				set = function(info,val) DB.ActionBars.popup1.anim = val; end
			},
			popup1alpha = {	name = L["LPopupAlpha"], type="range", order=2,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.popup1.alpha; end,
				set = function(info,val) if DB.ActionBars.popup1.enable == true then DB.ActionBars.popup1.alpha = val end end
			},
			popup1enable = {name = L["LPopupEnable"], type="toggle", order=3,
				get = function(info) return DB.ActionBars.popup1.enable; end,
				set = function(info,val) DB.ActionBars.popup1.enable = val end
			},
			popup2anim = {	name = L["RPopupAnimate"], type="toggle", order=4, width="full",
				get = function(info) return DB.ActionBars.popup2.anim; end,
				set = function(info,val) DB.ActionBars.popup2.anim = val; end
			},
			popup2alpha = {	name = L["RPopupAlpha"], type="range", order=5,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.popup2.alpha; end,
				set = function(info,val) if DB.ActionBars.popup2.enable == true then DB.ActionBars.popup2.alpha = val end end
			},
			popup2enable = {name = L["RPopupEnable"], type="toggle", order=6,
				get = function(info) return DB.ActionBars.popup2.enable; end,
				set = function(info,val) DB.ActionBars.popup2.enable = val end
			}
		}
	};
	spartan.opt.Artwork.args["minimap"] = {
		name = L["MinMapSet"],
		desc = L["MinMapSetConf"],
		type = "group", args = {
			minimapbuttons = {name = L["MinMapHidebtns"], type="toggle", width="full",
				get = function(info) return DB.MiniMap.MapButtons; end,
				set = function(info,val) DB.MiniMap.MapButtons = val; end
			},
			minimapzoom = {name = L["MinMapHideZoom"], type="toggle", width="full",
				get = function(info) return DB.MiniMap.MapZoomButtons; end,
				set = function(info,val) DB.MiniMap.MapZoomButtons = val; end
			}
		}
	}
	spartan.opt.Artwork.args["ChatSettings"] = {
		name = L["ChatSettings"],
		desc = L["ChatSettingsDesc"],
		type = "group", args = {
			enabled = {
				name = L["ChatSettingsEnabled"],
				desc = L["ChatSettingsEnabledDesc"],
				type="toggle",
				get = function(info) return DB.ChatSettings.enabled; end,
				set = function(info,val)
					if (val == true) then
					DB.ChatSettings.enabled = true;
						if (Prat or ChatMOD_Loaded or ChatSync or Chatter or PhanxChatDB) then
							-- Chat Mod Detected, disable and exit
							DB.ChatSettings.enabled = false
							return;
						end
					else
						DB.ChatSettings.enabled = false;
					end
				end
			}
		}
	}
	spartan.opt.Artwork.args["BuffSettings"] = {
		name = L["BuffOffsetSetting"],
		desc = L["BuffOffsetSettingDesc"],
		type = "group", args = {
			enabled = {name= L["BuffOffsetEnable"],type="toggle",width="full",order = 1,
				desc= L["BuffOffsetEnableDesc"],
				get = function(info) return DB.BuffSettings.enabled; end,
				set = function(info,val)
					DB.BuffSettings.enabled = val;
					if val == true then module:UpdateBuffPosition(); end
				end
			},
			offset = {name = L["BuffOffsetConf"], type = "range", order = 2,
				desc = L["BuffOffsetConfDesc"],
				width="double", min=0, max=200, step=.1,
				get = function(info) return DB.BuffSettings.offset; end,
				set = function(info,val)
					if DB.BuffSettings.Manualoffset == true then DB.BuffSettings.offset = val; end
				end
			},
			ManualOffset = {name=L["BuffOffsetManual"], type="toggle", order = 3,
				get	= function(info) return DB.BuffSettings.Manualoffset; end,
				set = function(info,val)
					DB.BuffSettings.Manualoffset = val;
					if val ~= true then
						DB.BuffSettings.offset = module:updateBuffOffset();
						module:UpdateBuffPosition();
					end
				end
			},
		}
	}
	spartan.opt.Artwork.args["XPBar"] = {
		name = L["BarXP"],
		desc = L["BarXPDesc"],
		type = "group", args = {
			display = {name=L["BarXPEnabled"],type="toggle",order=.1,
				get = function(info) return DB.XPBar.enabled; end,
				set = function(info,val) DB.XPBar.enabled = val; if DB.XPBar.enabled and not xpframe:IsVisible() then xpframe:Show(); elseif not DB.XPBar.enabled then xpframe:Hide(); end end
			},
			displaytext = {name=L["DisplayText"],type="toggle",order=.15,
				get = function(info) return DB.XPBar.text; end,
				set = function(info,val) DB.XPBar.text = val; module:SetXPColors(); end
			},
			tooltip = {name=L["DisplayTooltip"],type="select",order=.2,
				values = {["hover"]="Mouse Over",["click"]="On Click",["off"]="Disabled"},
				get = function(info) return DB.XPBar.ToolTip; end,
				set = function(info,val) DB.XPBar.ToolTip = val; end
			},
			header1 = {name=L["ClrGained"],type="header",order=.9},
			GainedColor = {name=L["GainedColor"],type="select",style="dropdown",order=1,width="full",
				values = {
					["Custom"]	= "Custom",
					["Orange"]	= "Orange",
					["Yellow"]	= "Yellow",
					["Green"]	= "Green",
					["Pink"]	= "Pink",
					["Purple"]	= "Purple",
					["Blue"]	= "Blue",
					["Red"]	= "Red",
					["Light_Blue"]	= "Light Blue",
				},
				get = function(info) return DB.XPBar.GainedColor; end,
				set = function(info,val) DB.XPBar.GainedColor = val; module:SetXPColors(); end
			},
			GainedRed = {name=L["Red"],type="range",order=2,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.GainedRed*100); end,
				set = function(info,val)
					if (DB.XPBar.GainedColor ~= "Custom") then DB.XPBar.GainedColor = "Custom"; end DB.XPBar.GainedRed = (val/100); module:SetXPColors();
				end
			},
			GainedGreen = {name=L["Green"],type="range",order=3,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.GainedGreen*100); end,
				set = function(info,val)
					if (DB.XPBar.GainedColor ~= "Custom") then DB.XPBar.GainedColor = "Custom"; end DB.XPBar.GainedGreen = (val/100);  module:SetXPColors();
				end
			},
			GainedBlue = {name=L["Blue"],type="range",order=4,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.GainedBlue*100); end,
				set = function(info,val)
					if (DB.XPBar.GainedColor ~= "Custom") then DB.XPBar.GainedColor = "Custom"; end DB.XPBar.GainedBlue = (val/100); module:SetXPColors();
				end
			},
			GainedBrightness = {name=L["Brightness"],type="range",order=5,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.GainedBrightness*100); end,
				set = function(info,val) if (DB.XPBar.GainedColor ~= "Custom") then DB.XPBar.GainedColor = "Custom"; end DB.XPBar.GainedBrightness = (val/100); module:SetXPColors(); end
			},
			header2 = {name=L["ClrRested"],type="header",order=10},
			RestedColor = {name=L["RestedColor"],type="select",style="dropdown",order=11,width="full",
				values = {
					["Custom"]	= "Custom",
					["Orange"]	= "Orange",
					["Yellow"]	= "Yellow",
					["Green"]	= "Green",
					["Pink"]	= "Pink",
					["Purple"]	= "Purple",
					["Blue"]	= "Blue",
					["Red"]	= "Red",
					["Light_Blue"]	= "Light Blue",
				},
				get = function(info) return DB.XPBar.RestedColor; end,
				set = function(info,val) DB.XPBar.RestedColor = val; module:SetXPColors(); end
			},
			RestedRed = {name=L["Red"],type="range",order=12,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.RestedRed*100); end,
				set = function(info,val)
					if (DB.XPBar.RestedColor ~= "Custom") then DB.XPBar.RestedColor = "Custom"; end DB.XPBar.RestedRed = (val/100); module:SetXPColors();
				end
			},
			RestedGreen = {name=L["Green"],type="range",order=13,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.RestedGreen*100); end,
				set = function(info,val)
					if (DB.XPBar.RestedColor ~= "Custom") then DB.XPBar.RestedColor = "Custom"; end DB.XPBar.RestedGreen = (val/100); module:SetXPColors();
				end
			},
			RestedBlue = {name=L["Blue"],type="range",order=14,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.RestedBlue*100); end,
				set = function(info,val)
					if (DB.XPBar.RestedColor ~= "Custom") then DB.XPBar.RestedColor = "Custom"; end DB.XPBar.RestedBlue = (val/100); module:SetXPColors();
				end
			},
			RestedBrightness = {name=L["Brightness"],type="range",order=15,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.RestedBrightness*100); end,
				set = function(info,val) if (DB.XPBar.RestedColor ~= "Custom") then DB.XPBar.RestedColor = "Custom"; end DB.XPBar.RestedBrightness = (val/100); module:SetXPColors(); end
			},
			RestedMatchColor = {name=L["MatchRestedClr"],type="toggle",order=21,
				get = function(info) return DB.XPBar.RestedMatchColor; end,
				set = function(info,val) DB.XPBar.RestedMatchColor = val; module:SetXPColors(); end
			}
		}
	}
	spartan.opt.Artwork.args["RepBar"] = {
		name = L["BarRep"],
		desc = L["BarRepDesc"],
		type = "group", args = {
			display = {name=L["BarRepEnabled"],type="toggle",order=.1,
				get = function(info) return DB.RepBar.enabled; end,
				set = function(info,val) DB.RepBar.enabled = val; if DB.RepBar.enabled and not repframe:IsVisible() then repframe:Show(); elseif not DB.RepBar.enabled then repframe:Hide(); end end
			},
			displaytext = {name=L["DisplayText"],type="toggle",order=.15,
				get = function(info) return DB.RepBar.text; end,
				set = function(info,val) DB.RepBar.text = val; module:SetRepColors(); end
			},
			tooltip = {name=L["DisplayTooltip"],type="select",order=.2,
				values = {["hover"]="Mouse Over",["click"]="On Click",["off"]="Disabled"},
				get = function(info) return DB.RepBar.ToolTip; end,
				set = function(info,val) DB.RepBar.ToolTip = val; end
			},
			header1 = {name=L["ClrRep"],type="header",order=.9},
			AutoDefined = {name=L["AutoRepClr"],type="toggle",order=1,desc=L["AutoRepClrDesc"],
			width="full",
				get = function(info) return DB.RepBar.AutoDefined; end,
				set = function(info,val) DB.RepBar.AutoDefined = val; module:SetRepColors(); end
			},
			RepColor = {name=L["Color"],type="select",style="dropdown",order=2,width="full",
				values = {
					["AUTO"]	= L["AUTO"],
					["Custom"]	= L["Custom"],
					["Orange"]	= L["Orange"],
					["Yellow"]	= L["Yellow"],
					["Green"]	= L["Green"],
					["Pink"]	= L["Pink"],
					["Purple"]	= L["Purple"],
					["Blue"]	= L["Blue"],
					["Red"]	= L["Red"],
					["Light_Blue"]	= L["LightBlue"],
				},
				get = function(info) return DB.RepBar.GainedColor; end,
				set = function(info,val) DB.RepBar.GainedColor = val; if val == "AUTO" then DB.RepBar.AutoDefined = true end module:SetRepColors(); end
			},
			RepRed = {name=L["Red"],type="range",order=3,
				min=0,max=100,step=1,
				get = function(info) return (DB.RepBar.GainedRed*100); end,
				set = function(info,val)
					if (DB.RepBar.AutoDefined) then return end if (DB.RepBar.GainedColor ~= "Custom") then DB.RepBar.GainedColor = "Custom"; end DB.RepBar.GainedRed = (val/100); module:SetRepColors();
				end
			},
			RepGreen = {name=L["Green"],type="range",order=4,
				min=0,max=100,step=1,
				get = function(info) return (DB.RepBar.GainedGreen*100); end,
				set = function(info,val)
					if (DB.RepBar.AutoDefined) then return end if (DB.RepBar.GainedColor ~= "Custom") then DB.RepBar.GainedColor = "Custom"; end DB.RepBar.GainedGreen = (val/100);  module:SetRepColors();
				end
			},
			RepBlue = {name=L["Blue"],type="range",order=5,
				min=0,max=100,step=1,
				get = function(info) return (DB.RepBar.GainedBlue*100); end,
				set = function(info,val)
					if (DB.RepBar.AutoDefined) then return end if (DB.RepBar.GainedColor ~= "Custom") then DB.RepBar.GainedColor = "Custom"; end DB.RepBar.GainedBlue = (val/100); module:SetRepColors();
				end
			},
			RepBrightness = {name=L["Brightness"],type="range",order=6,
				min=0,max=100,step=1,
				get = function(info) return (DB.RepBar.GainedBrightness*100); end,
				set = function(info,val) if (DB.RepBar.AutoDefined) then return end if (DB.RepBar.GainedColor ~= "Custom") then DB.RepBar.GainedColor = "Custom"; end DB.RepBar.GainedBrightness = (val/100); module:SetRepColors(); end
			}
		}
	}
	spartan.opt.Artwork.args["DefaultScales"] = {name = L["DefScales"],type = "execute",order = 2,
		desc = L["DefScalesDesc"],
		func = function()
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				if (DB.scale >= 0.92) or (DB.scale < 0.78) then
					DB.scale = 0.78;
				else
					DB.scale = 0.92;
				end
			end
		end
	};
	spartan.opt.Artwork.args["scale"] = {name = L["ConfScale"],type = "range",order = 1,width = "double",
		desc = L["ConfScaleDesc"],min = 0,max = 1,
		set = function(info,val)
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				DB.scale = min(1,Artwork_Core:round(val));
				module:updateSpartanScale();
				module:updateSpartanOffset();
				module:updateSpartanXOffset();
				module:updateSpartanViewport();
				module:updateSpartanAlpha();
			end
		end,
		get = function(info) return DB.scale; end
	};
	spartan.opt.Artwork.args["offset"] = {name = L["ConfOffset"],type = "range",order = 3,width="double",
		desc = L["ConfOffsetDesc"],
		min=0,max=200,step=.1,
		get = function(info) return DB.yoffset end,
		set = function(info,val)
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				if DB.yoffsetAuto then
					spartan:Print(L["confOffsetAuto"]);
				else
					val = tonumber(val);
					DB.yoffset = val;
				end
			end
		end,
		get = function(info) return DB.yoffset; end
	};
	spartan.opt.Artwork.args["offsetauto"] = {name = L["AutoOffset"],type = "toggle",order = 4,
		desc = L["AutoOffsetDesc"],
		get = function(info) return DB.yoffsetAuto end,
		set = function(info,val) DB.yoffsetAuto = val end,
	};
	spartan.opt.Artwork.args["Artwork"] = {name = "Artwork Options",type="group",order=10,
		args = {
			alpha = {name=L["Transparency"],type="range",order=1,width="full",
				min=0,max=100,step=1,desc=L["TransparencyDesc"],
				get = function(info) return (DB.alpha*100); end,
				set = function(info,val) DB.alpha = (val/100); updateSpartanAlpha(); end
			},
			xOffset = {name = L["MoveSideways"],type = "range",order = 3,width="full",
				desc = L["MoveSidewaysDesc"],
				min=-200,max=200,step=.1,
				get = function(info) return DB.xOffset/6.25 end,
				set = function(info,val) DB.xOffset = val*6.25; updateSpartanXOffset(); end,
			}
		}
	}
end

function module:OnDisable()
	SpartanUI:Hide();
end
