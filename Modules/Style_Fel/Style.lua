local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Fel");
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	--Enable the in the Core options screen
	spartan.opt.args["General"].args["style"].args["OverallStyle"].args["Fel"].disabled = false
	spartan.opt.args["General"].args["style"].args["Artwork"].args["Fel"].disabled = false
	spartan.opt.args["General"].args["style"].args["PlayerFrames"].args["Fel"].disabled = false
	spartan.opt.args["General"].args["style"].args["PartyFrames"].args["Fel"].disabled = false
	spartan.opt.args["General"].args["style"].args["RaidFrames"].args["Fel"].disabled = false
	--Init if needed
	if (DBMod.Artwork.Style == "Fel") then module:Init() end
end

function module:Init()
	if (DBMod.Artwork.FirstLoad) then module:FirstLoad() end
	module:SetupMenus();
	Artwork_Core:StatusBarOptions()
	module:InitArtwork();
	InitRan = true;
end

function module:FirstLoad()
	--If our profile exists activate it.
	if ((Bartender4.db:GetCurrentProfile() ~= DB.Styles.Fel.BartenderProfile) and Artwork_Core:BartenderProfileCheck(DB.Styles.Fel.BartenderProfile,true)) then Bartender4.db:SetProfile(DB.Styles.Fel.BartenderProfile); end
end

function module:OnEnable()
	if (DBMod.Artwork.Style ~= "Fel") then
		module:Disable(); 
	else
		if (Bartender4.db:GetCurrentProfile() ~= DB.Styles.Fel.BartenderProfile) and DBMod.Artwork.FirstLoad then
			Bartender4.db:SetProfile(DB.Styles.Fel.BartenderProfile);
		end
		if (not InitRan) then module:Init(); end
		if (not Artwork_Core:BartenderProfileCheck(DB.Styles.Fel.BartenderProfile,true)) then module:CreateProfile(); end
		module:EnableArtwork();
		
		if (DBMod.Artwork.FirstLoad) then DBMod.Artwork.FirstLoad = false end -- We want to do this last
	end
end

function module:OnDisable()
	Fel_SpartanUI:Hide();
end

function module:SetupMenus()
	spartan.opt.args["Artwork"].args["Artwork"] = {name = "Fel Options",type="group",order=10,
		args = {
			MinimapEngulfed = {name=L["Douse the flames"],type="toggle",order=.1,desc=L["Is it getting hot in here?"],
				get = function(info) return (DB.Styles.Fel.Minimap.Engulfed ~= true or false); end,
				set = function(info,val) DB.Styles.Fel.Minimap.Engulfed = (val ~= true or false) Minimap.FelUpdate(Minimap) end
			},
			alpha = {name=L["Transparency"],type="range",order=1,width="full",
				min=0,max=100,step=1,desc=L["TransparencyDesc"],
				get = function(info) return (DB.alpha*100); end,
				set = function(info,val) DB.alpha = (val/100); module:updateAlpha() end
			},
			-- xOffset = {name = L["MoveSideways"],type = "range",width="full",order=2,
				-- desc = L["MoveSidewaysDesc"],
				-- min=-200,max=200,step=.1,
				-- get = function(info) return DB.xOffset/6.25 end,
				-- set = function(info,val) DB.xOffset = val*6.25; module:updateSpartanXOffset(); end,
			-- },
			offset = {name = L["ConfOffset"],type = "range",width="normal",order=3,
				desc = L["ConfOffsetDesc"],min=0,max=200,step=.1,
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
							module:updateOffset();
						end
					end
				end,
				get = function(info) return DB.yoffset; end
			},
			offsetauto = {name = L["AutoOffset"],type = "toggle",desc = L["AutoOffsetDesc"],order=3.1,
				get = function(info) return DB.yoffsetAuto end,
				set = function(info,val) DB.yoffsetAuto = val; module:updateOffset(); end,
			}
		}
	}
	
	spartan.opt.args["Artwork"].args["ActionBar"] = { name = "Bar backgrounds", type = "group",desc = L["ActionBarConfDesc"],
		args = {
			header1 = {name="",type="header",order=1.1},
			Allenable = {name = L["AllBarEnable"], type="toggle",order=1,
				get = function(info) return DB.Styles.Fel.Artwork.Allenable; end,
				set = function(info,val)
					for i = 1,4 do DB.Styles.Fel.Artwork["bar"..i].enable,DB.Styles.Fel.Artwork.Allenable = val,val; end
					DB.Styles.Fel.Artwork.Stance.enable = val;
					DB.Styles.Fel.Artwork.MenuBar.enable = val;
					module:updateAlpha()
				end
			},
			Allalpha = {name = L["AllBarAlpha"], type="range",order=2,width="double",
				min=0, max=100, step=1,
				get = function(info) return DB.Styles.Fel.Artwork.Allalpha; end,
				set = function(info,val)
					for i = 1,4 do DB.Styles.Fel.Artwork["bar"..i].alpha,DB.Styles.Fel.Artwork.Allalpha = val,val; end
					DB.Styles.Fel.Artwork.Stance.alpha = val;
					DB.Styles.Fel.Artwork.MenuBar.alpha = val;
					module:updateAlpha()
				end
			},
			
			Stance = { name = L["Stance and Pet bar"], type = "group", inline=true, order=10, args = {
				bar5alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.Styles.Fel.Artwork.Stance.alpha; end,
					set = function(info,val) if DB.Styles.Fel.Artwork.Stance.enable == true then DB.Styles.Fel.Artwork.Stance.alpha = val; module:updateAlpha(); end end
				},
				bar5enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.Styles.Fel.Artwork.Stance.enable; end,
					set = function(info,val) DB.Styles.Fel.Artwork.Stance.enable = val; module:updateAlpha(); end
				}
			}},
			MenuBar = { name = L["Bag and Menu bar"], type = "group", inline=true, order=20, args = {
				bar6alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.Styles.Fel.Artwork.MenuBar.alpha; end,
					set = function(info,val) if DB.Styles.Fel.Artwork.MenuBar.enable == true then DB.Styles.Fel.Artwork.MenuBar.alpha = val; module:updateAlpha(); end end
				},
				bar6enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.Styles.Fel.Artwork.MenuBar.enable; end,
					set = function(info,val) DB.Styles.Fel.Artwork.MenuBar.enable = val; module:updateAlpha(); end
				}
			}},
			Bar1 = { name = L["Bar 1"], type = "group", inline=true, order=30, args = {
				bar1alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.Styles.Fel.Artwork.bar1.alpha; end,
					set = function(info,val) if DB.Styles.Fel.Artwork.bar1.enable == true then DB.Styles.Fel.Artwork.bar1.alpha = val; module:updateAlpha(); end end
				},
				bar1enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.Styles.Fel.Artwork.bar1.enable; end,
					set = function(info,val) DB.Styles.Fel.Artwork.bar1.enable = val; module:updateAlpha(); end
				},
			}},
			Bar2 = { name = L["Bar 2"], type = "group", inline=true, order=40, args = {
				bar2alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.Styles.Fel.Artwork.bar2.alpha; end,
					set = function(info,val) if DB.Styles.Fel.Artwork.bar2.enable == true then DB.Styles.Fel.Artwork.bar2.alpha = val; module:updateAlpha(); end end
				},
				bar2enable = {name = L["Enabled"], type="toggle",
				get = function(info) return DB.Styles.Fel.Artwork.bar2.enable; end,
					set = function(info,val) DB.Styles.Fel.Artwork.bar2.enable = val; module:updateAlpha(); end
				}
			}},
			Bar3 = { name = L["Bar 3"], type = "group", inline=true, order=50, args = {
				bar3alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.Styles.Fel.Artwork.bar3.alpha; end,
					set = function(info,val) if DB.Styles.Fel.Artwork.bar3.enable == true then DB.Styles.Fel.Artwork.bar3.alpha = val; module:updateAlpha(); end end
				},
				bar3enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.Styles.Fel.Artwork.bar3.enable; end,
					set = function(info,val) DB.Styles.Fel.Artwork.bar3.enable = val; module:updateAlpha(); end
				}
			}},
			Bar4 = { name = L["Bar 4"], type = "group", inline=true, order=60, args = {
				bar4alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.Styles.Fel.Artwork.bar4.alpha; end,
					set = function(info,val) if DB.Styles.Fel.Artwork.bar4.enable == true then DB.Styles.Fel.Artwork.bar4.alpha = val; module:updateAlpha(); end end
				},
				bar4enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.Styles.Fel.Artwork.bar4.enable; end,
					set = function(info,val) DB.Styles.Fel.Artwork.bar4.enable = val; module:updateAlpha(); end
				}
			}},
		}
	};
end