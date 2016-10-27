local _, SUI
spartan = _G["SUI"]
local L = spartan.L;
local Artwork_Core = spartan:GetModule("Artwork_Core");

function Artwork_Core:SetupOptions()
	local Profiles = {}
	for name, module in spartan:IterateModules() do
		if (string.match(name, "Style_")) then
			Profiles[string.sub(name, 7)] = string.sub(name, 7)
		end
	end
	spartan.opt.args["Artwork"].args["Base"] = {name = "Base Options",type="group",order=0,
		args = {
			VehicleUI = {name = "Use Blizzard Vehicle UI", type = "toggle",order=0.9,
				get = function(info) return DBMod.Artwork.VehicleUI end,
				set = function(info,val) 
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); return; end
					DBMod.Artwork.VehicleUI = val
					--Make sure bartender knows to do it, or not...
					if Bartender4 then
						Bartender4.db.profile.blizzardVehicle = val
						Bartender4:UpdateBlizzardVehicle()
					end
					
					if DBMod.Artwork.VehicleUI then
						if spartan:GetModule("Style_" .. DBMod.Artwork.Style).SetupVehicleUI() ~= nil then
							spartan:GetModule("Style_" .. DBMod.Artwork.Style):SetupVehicleUI()
						end
					else
						if spartan:GetModule("Style_" .. DBMod.Artwork.Style).RemoveVehicleUI() ~= nil then
							spartan:GetModule("Style_" .. DBMod.Artwork.Style):RemoveVehicleUI()
						end
					end
				end,
			},
			-- MoveBars={name = "Move Bars", type = "toggle",order=0.91,
				-- get = function(info) if Bartender4 then return Bartender4.db.profile.buttonlock else spartan.opt.args["Artwork"].args["Base"].args["LockButtons"].disabled=true; return false; end end,
				-- set = function(info, value)
					-- Bartender4.db.profile.buttonlock = value
					-- Bartender4.Bar:ForAll("ForAll", "SetAttribute", "buttonlock", value)
				-- end,
			-- },
			LockButtons = {name = "Lock Buttons", type = "toggle",order=0.91,
				get = function(info) if Bartender4 then return Bartender4.db.profile.buttonlock else spartan.opt.args["Artwork"].args["Base"].args["LockButtons"].disabled=true; return false; end end,
				set = function(info, value)
					Bartender4.db.profile.buttonlock = value
					Bartender4.Bar:ForAll("ForAll", "SetAttribute", "buttonlock", value)
				end,
			},
			Viewport = {name = "Viewport",type = "group",inline=true,
			args = {
				Enabled = {name = "Enabled", type = "toggle",order=1,
					desc="Allow SpartanUI To manage the viewport",
					get = function(info) return DB.viewport end,
					set = function(info,val)
						if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); return; end
						if (not val) then
							--Since we are disabling reset the viewport
							WorldFrame:ClearAllPoints();
							WorldFrame:SetPoint("TOPLEFT", 0, 0);
							WorldFrame:SetPoint("BOTTOMRIGHT", 0, 0);
						end
						DB.viewport = val
						if (not DB.viewport) then
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetTop"].disabled = true;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetBottom"].disabled = true;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetLeft"].disabled = true;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetRight"].disabled = true;
						else
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetTop"].disabled = false;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetBottom"].disabled = false;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetLeft"].disabled = false;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetRight"].disabled = false;
						end
					end,
				},
				viewportoffsets = {name = "Offset",order=2,type = "description",fontSize = "large"},
				viewportoffsetTop = {name = "Top",type = "range",order=2.1,
					min=-100,max=100,step=.1,
					get = function(info) return DBMod.Artwork.Viewport.offset.top end,
					set = function(info,val) DBMod.Artwork.Viewport.offset.top = val; end,
				},
				viewportoffsetBottom = {name = "Bottom",type = "range",order=2.2,
					min=-100,max=100,step=.1,
					get = function(info) return DBMod.Artwork.Viewport.offset.bottom end,
					set = function(info,val) DBMod.Artwork.Viewport.offset.bottom = val; end,
				},
				viewportoffsetLeft = {name = "Left",type = "range",order=2.3,
					min=-100,max=100,step=.1,
					get = function(info) return DBMod.Artwork.Viewport.offset.left end,
					set = function(info,val) DBMod.Artwork.Viewport.offset.left = val; end,
				},
				viewportoffsetRight = {name = "Right",type = "range",order=2.4,
				min=-100,max=100,step=.1,
				get = function(info) return DBMod.Artwork.Viewport.offset.right end,
				set = function(info,val) DBMod.Artwork.Viewport.offset.right = val; end,
			},
			}
			}
		}
	}
	spartan.opt.args["Artwork"].args["scale"] = {name = L["ConfScale"],type = "range",order = 1,width = "double",
			desc = L["ConfScaleDesc"],min = 0,max = 1,
			set = function(info,val)
				if (InCombatLockdown()) then 
					spartan:Print(ERR_NOT_IN_COMBAT);
				else
					DB.scale = min(1,spartan:round(val));
				end
			end,
			get = function(info) return DB.scale; end
	};
	spartan.opt.args["Artwork"].args["DefaultScales"] = {name = L["DefScales"],type = "execute",order = 2,
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

	if (not DB.viewport) then
		spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetTop"].disabled = true;
		spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetBottom"].disabled = true;
		spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetLeft"].disabled = true;
		spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetRight"].disabled = true;
	end
end

function Artwork_Core:StatusBarOptions()
	local module = spartan:GetModule("Style_"..DBMod.Artwork.Style)
	local StatusBars = {["xp"] = L["Experiance"], ["rep"] = L["Reputation"], ["honor"] = L["Honor"], ["ap"] = L["Artifact Power"], ["disabled"] = L["Disabled"]}
	spartan.opt.args["Artwork"].args["StatusBars"] = {
		name = L["Status bars"],
		desc = L["BarXPDesc"],
		type = "group", args = {
			left = {name=L["Left status bar"],type="select",order=.1,
				values = StatusBars,
				get = function(info)
					return DB.StatusBars.left
				end,
				set = function(info,val)
					if DB.StatusBars.right == val then return end
					DB.StatusBars.left = val
					module:UpdateStatusBars()
				end
			},
			right = {name=L["Right status bar"],type="select",order=.2,
				values = StatusBars,
				get = function(info)
					return DB.StatusBars.right
				end,
				set = function(info,val)
					if DB.StatusBars.left == val then return end
					DB.StatusBars.right = val
					module:UpdateStatusBars()
				end
			},
			APBar = {name = L["Artifact Power"],type = "group",inline=true,
				args = {
					displaytext = {name=L["DisplayText"],type="toggle",order=.15,
						get = function(info) return DB.StatusBars.APBar.text; end,
						set = function(info,val)
							DB.StatusBars.APBar.text = val;
							module:UpdateAPBar()
						end
					}
				}
			},
			XPBar = {name = L["BarXP"],desc = L["BarXPDesc"],type = "group",inline=true,
				args = {
					display = {name=L["BarXPEnabled"],type="toggle",order=.1,
						get = function(info) return DB.StatusBars.XPBar.enabled; end,
						set = function(info,val) DB.StatusBars.XPBar.enabled = val; module:UpdateStatusBars(); end
					},
					displaytext = {name=L["DisplayText"],type="toggle",order=.15,
						get = function(info) return DB.StatusBars.XPBar.text; end,
						set = function(info,val) DB.StatusBars.XPBar.text = val; module:SetXPColors(); end
					},
					tooltip = {name=L["DisplayTooltip"],type="select",order=.2,
						values = {["hover"]="Mouse Over",["click"]="On Click",["off"]="Disabled"},
						get = function(info) return DB.StatusBars.XPBar.ToolTip; end,
						set = function(info,val) DB.StatusBars.XPBar.ToolTip = val; end
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
						get = function(info) return DB.StatusBars.XPBar.GainedColor; end,
						set = function(info,val) DB.StatusBars.XPBar.GainedColor = val; module:SetXPColors(); end
					},
					GainedRed = {name=L["Red"],type="range",order=2,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.XPBar.GainedRed*100); end,
						set = function(info,val)
							if (DB.StatusBars.XPBar.GainedColor ~= "Custom") then DB.StatusBars.XPBar.GainedColor = "Custom"; end DB.StatusBars.XPBar.GainedRed = (val/100); module:SetXPColors();
						end
					},
					GainedGreen = {name=L["Green"],type="range",order=3,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.XPBar.GainedGreen*100); end,
						set = function(info,val)
							if (DB.StatusBars.XPBar.GainedColor ~= "Custom") then DB.StatusBars.XPBar.GainedColor = "Custom"; end DB.StatusBars.XPBar.GainedGreen = (val/100);  module:SetXPColors();
						end
					},
					GainedBlue = {name=L["Blue"],type="range",order=4,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.XPBar.GainedBlue*100); end,
						set = function(info,val)
							if (DB.StatusBars.XPBar.GainedColor ~= "Custom") then DB.StatusBars.XPBar.GainedColor = "Custom"; end DB.StatusBars.XPBar.GainedBlue = (val/100); module:SetXPColors();
						end
					},
					GainedBrightness = {name=L["Brightness"],type="range",order=5,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.XPBar.GainedBrightness*100); end,
						set = function(info,val) if (DB.StatusBars.XPBar.GainedColor ~= "Custom") then DB.StatusBars.XPBar.GainedColor = "Custom"; end DB.StatusBars.XPBar.GainedBrightness = (val/100); module:SetXPColors(); end
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
						get = function(info) return DB.StatusBars.XPBar.RestedColor; end,
						set = function(info,val) DB.StatusBars.XPBar.RestedColor = val; module:SetXPColors(); end
					},
					RestedRed = {name=L["Red"],type="range",order=12,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.XPBar.RestedRed*100); end,
						set = function(info,val)
							if (DB.StatusBars.XPBar.RestedColor ~= "Custom") then DB.StatusBars.XPBar.RestedColor = "Custom"; end DB.StatusBars.XPBar.RestedRed = (val/100); module:SetXPColors();
						end
					},
					RestedGreen = {name=L["Green"],type="range",order=13,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.XPBar.RestedGreen*100); end,
						set = function(info,val)
							if (DB.StatusBars.XPBar.RestedColor ~= "Custom") then
								DB.StatusBars.XPBar.RestedColor = "Custom";
							end
							DB.StatusBars.XPBar.RestedGreen = (val/100);
							module:SetXPColors();
						end
					},
					RestedBlue = {name=L["Blue"],type="range",order=14,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.XPBar.RestedBlue*100); end,
						set = function(info,val)
							if (DB.StatusBars.XPBar.RestedColor ~= "Custom") then DB.StatusBars.XPBar.RestedColor = "Custom"; end DB.StatusBars.XPBar.RestedBlue = (val/100); module:SetXPColors();
						end
					},
					RestedBrightness = {name=L["Brightness"],type="range",order=15,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.XPBar.RestedBrightness*100); end,
						set = function(info,val) if (DB.StatusBars.XPBar.RestedColor ~= "Custom") then DB.StatusBars.XPBar.RestedColor = "Custom"; end DB.StatusBars.XPBar.RestedBrightness = (val/100); module:SetXPColors(); end
					},
					RestedMatchColor = {name=L["MatchRestedClr"],type="toggle",order=21,
						get = function(info) return DB.StatusBars.XPBar.RestedMatchColor; end,
						set = function(info,val) DB.StatusBars.XPBar.RestedMatchColor = val; module:SetXPColors(); end
					}
				}
			},
			RepBar = {name = L["Reputation"],type = "group",inline=true,
				args = {
					displaytext = {name=L["DisplayText"],type="toggle",order=.15,
						get = function(info) return DB.StatusBars.RepBar.text; end,
						set = function(info,val)
							DB.StatusBars.RepBar.text = val;
							module:SetRepColors();
						end
					},
					tooltip = {name=L["DisplayTooltip"],type="select",order=.95,
						values = {["hover"]="Mouse Over",["click"]="On Click",["off"]="Disabled"},
						get = function(info) return DB.StatusBars.RepBar.ToolTip; end,
						set = function(info,val) DB.StatusBars.RepBar.ToolTip = val; end
					},
					AutoDefined = {name=L["AutoRepClr"],type="toggle",order=1,desc=L["AutoRepClrDesc"],
					width="full",
						get = function(info) return DB.StatusBars.RepBar.AutoDefined; end,
						set = function(info,val) DB.StatusBars.RepBar.AutoDefined = val; module:SetRepColors(); end
					},
					RepColor = {name=L["Color"],type="select",style="dropdown",order=2,
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
						get = function(info) return DB.StatusBars.RepBar.GainedColor; end,
						set = function(info,val) DB.StatusBars.RepBar.GainedColor = val; if val == "AUTO" then DB.StatusBars.RepBar.AutoDefined = true end module:SetRepColors(); end
					},
					RepRed = {name=L["Red"],type="range",order=3,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.RepBar.GainedRed*100); end,
						set = function(info,val)
							if (DB.StatusBars.RepBar.AutoDefined) then return end if (DB.StatusBars.RepBar.GainedColor ~= "Custom") then DB.StatusBars.RepBar.GainedColor = "Custom"; end DB.StatusBars.RepBar.GainedRed = (val/100); module:SetRepColors();
						end
					},
					RepGreen = {name=L["Green"],type="range",order=4,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.RepBar.GainedGreen*100); end,
						set = function(info,val)
							if (DB.StatusBars.RepBar.AutoDefined) then return end if (DB.StatusBars.RepBar.GainedColor ~= "Custom") then DB.StatusBars.RepBar.GainedColor = "Custom"; end DB.StatusBars.RepBar.GainedGreen = (val/100);  module:SetRepColors();
						end
					},
					RepBlue = {name=L["Blue"],type="range",order=5,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.RepBar.GainedBlue*100); end,
						set = function(info,val)
							if (DB.StatusBars.RepBar.AutoDefined) then return end if (DB.StatusBars.RepBar.GainedColor ~= "Custom") then DB.StatusBars.RepBar.GainedColor = "Custom"; end DB.StatusBars.RepBar.GainedBlue = (val/100); module:SetRepColors();
						end
					},
					RepBrightness = {name=L["Brightness"],type="range",order=6,
						min=0,max=100,step=1,
						get = function(info) return (DB.StatusBars.RepBar.GainedBrightness*100); end,
						set = function(info,val) if (DB.StatusBars.RepBar.AutoDefined) then return end if (DB.StatusBars.RepBar.GainedColor ~= "Custom") then DB.StatusBars.RepBar.GainedColor = "Custom"; end DB.StatusBars.RepBar.GainedBrightness = (val/100); module:SetRepColors(); end
					}
				}
			}
		}
	}
end