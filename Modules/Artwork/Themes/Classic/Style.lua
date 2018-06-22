local _G, SUI = _G, SUI
local L = SUI.L;
local Artwork_Core = SUI:GetModule("Artwork_Core");
local module = SUI:GetModule("Style_Classic");
----------------------------------------------------------------------------------------------------
if DB.Styles.Classic.BuffLoc == nil then DB.Styles.Classic.BuffLoc = true end
local InitRan = false

function module:OnInitialize()
	if DB.Styles.Classic.TalkingHeadUI == nil then
		DB.Styles.Classic.TalkingHeadUI = {
			point = "BOTTOM",
			relPoint = "TOP",
			x = 0,
			y = -30,
			scale = .8
		}
	end
	if (SUI.DBMod.Artwork.Style == "Classic") then
		module:Init();
	else
		module:Disable();
	end
end

function module:Init()
	if (SUI.DBMod.Artwork.FirstLoad) then module:FirstLoad() end
	module:SetupMenus();
	module:InitFramework();
	module:InitActionBars();
	module:InitStatusBars();
	InitRan = true;
end

function module:FirstLoad()
	SUI.DBMod.Artwork.Viewport.offset.bottom = 2.8
end

function module:OnEnable()
	--If our profile exists activate it.
	if (Bartender4.db:GetCurrentProfile() ~= DB.Styles.Classic.BartenderProfile) and SUI.DBMod.Artwork.FirstLoad then
		Bartender4.db:SetProfile(DB.Styles.Classic.BartenderProfile);
	end
	if (SUI.DBMod.Artwork.Style == "Classic") then
		if (not InitRan) then module:Init(); end
		if (not Artwork_Core:BartenderProfileCheck(DB.Styles.Classic.BartenderProfile,true)) then module:CreateProfile(); end
		
		module:EnableFramework();
		module:EnableActionBars();
		module:EnableMinimap();
		module:EnableStatusBars();
		
		if (SUI.DBMod.Artwork.FirstLoad) then SUI.DBMod.Artwork.FirstLoad = false end -- We want to do this last
	end
end

function module:SetupMenus()
	SUI.opt.args["Artwork"].args["ActionBar"] = { name = "ActionBar Settings", type = "group",desc = L["ActionBarConfDesc"],
		args = {
			reset = {name = "Reset ActionBars", type = "execute", width= "double",order=1,
				func = function()
					if (InCombatLockdown()) then 
						SUI:Print(ERR_NOT_IN_COMBAT);
					else
						module:CreateProfile();
						ReloadUI();
					end
				end
			},
			header1 = {name="",type="header",order=1.1},
			Allenable = {name = L["AllBarEnable"], type="toggle",order=2,
				get = function(info) return DB.ActionBars.Allenable; end,
				set = function(info,val) for i = 1,6 do DB.ActionBars["bar"..i].enable,DB.ActionBars.Allenable = val,val; end end
			},
			Allalpha = {name = L["AllBarAlpha"], type="range",order=2.1,width="double",
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.Allalpha; end,
				set = function(info,val) for i = 1,6 do DB.ActionBars["bar"..i].alpha,DB.ActionBars.Allalpha = val,val; end end
			},
			Bar1 = { name = "Bar 1", type = "group", inline=true, args = {
				bar1alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.ActionBars.bar1.alpha; end,
					set = function(info,val) if DB.ActionBars.bar1.enable == true then DB.ActionBars.bar1.alpha = val end end
				},
				bar1enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.ActionBars.bar1.enable; end,
					set = function(info,val) DB.ActionBars.bar1.enable = val end
				},
			}},
			Bar2 = { name = "Bar 2", type = "group", inline=true, args = {
				bar2alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.ActionBars.bar2.alpha; end,
					set = function(info,val) if DB.ActionBars.bar2.enable == true then DB.ActionBars.bar2.alpha = val end end
				},
				bar2enable = {name = L["Enabled"], type="toggle",
				get = function(info) return DB.ActionBars.bar2.enable; end,
					set = function(info,val) DB.ActionBars.bar2.enable = val end
				}
			}},
			Bar3 = { name = "Bar 3", type = "group", inline=true, args = {
				bar3alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.ActionBars.bar3.alpha; end,
					set = function(info,val) if DB.ActionBars.bar3.enable == true then DB.ActionBars.bar3.alpha = val end end
				},
				bar3enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.ActionBars.bar3.enable; end,
					set = function(info,val) DB.ActionBars.bar3.enable = val end
				}
			}},
			Bar4 = { name = "Bar 4", type = "group", inline=true, args = {
				bar4alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.ActionBars.bar4.alpha; end,
					set = function(info,val) if DB.ActionBars.bar4.enable == true then DB.ActionBars.bar4.alpha = val end end
				},
				bar4enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.ActionBars.bar4.enable; end,
					set = function(info,val) DB.ActionBars.bar4.enable = val end
				}
			}},
			Bar5 = { name = "Bar 5", type = "group", inline=true, args = {
				bar5alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.ActionBars.bar5.alpha; end,
					set = function(info,val) if DB.ActionBars.bar5.enable == true then DB.ActionBars.bar5.alpha = val end end
				},
				bar5enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.ActionBars.bar5.enable; end,
					set = function(info,val) DB.ActionBars.bar5.enable = val end
				}
			}},
			Bar6 = { name = "Bar 6", type = "group", inline=true, args = {
				bar6alpha = {name = L["Alpha"], type="range",min=0, max=100, step=1, width="double",
					get = function(info) return DB.ActionBars.bar6.alpha; end,
					set = function(info,val) if DB.ActionBars.bar6.enable == true then DB.ActionBars.bar6.alpha = val end end
				},
				bar6enable = {name = L["Enabled"], type="toggle",
					get = function(info) return DB.ActionBars.bar6.enable; end,
					set = function(info,val) DB.ActionBars.bar6.enable = val end
				}
			}},
		}
	};
	SUI.opt.args["Artwork"].args["popup"] = { name = L["PopupAnimConf"], type = "group",
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
	SUI.opt.args["Artwork"].args["Artwork"] = {name = L["ArtworkOpt"],type="group",order=10,
		args = {
			Color = {name=L["ArtColor"],type="color",hasAlpha=true,order=.5,
				get = function(info) if not DB.Styles.Classic.Color.Art then return {1,1,1,1} end return unpack(DB.Styles.Classic.Color.Art) end,
				set = function(info,r,b,g,a) DB.Styles.Classic.Color.Art = {r,b,g,a}; module:SetColor(); end
			},
			ColorEnabled = {name="Color enabled",type="toggle",order=.6,
				get = function(info)
					if DB.Styles.Classic.Color.Art then
						return true
					else
						return false
					end
				end,
				set = function(info,val)
					if val then 
						DB.Styles.Classic.Color.Art = {1,1,1,1}
						module:SetColor()
					else
						DB.Styles.Classic.Color.Art = false
						module:SetColor()
					end
				end
			},
			alpha = {name=L["Transparency"],type="range",order=1,width="full",
				min=0,max=100,step=1,desc=L["TransparencyDesc"],
				get = function(info) return (DB.alpha*100); end,
				set = function(info,val) DB.alpha = (val/100); module:updateSpartanAlpha(); module:AddNotice(); end
			},
			TransparencyNotice = {
				name = L["TransparencyNotice"],order=1.1,type = "description", fontSize = "small",hidden=true
			},
			xOffset = {name = L["MoveSideways"],type = "range",width="full",order=2,
				desc = L["MoveSidewaysDesc"],
				min=-200,max=200,step=.1,
				get = function(info) return DB.xOffset/6.25 end,
				set = function(info,val) DB.xOffset = val*6.25; module:updateSpartanXOffset(); end,
			},
			offset = {name = L["ConfOffset"],type = "range",width="normal",order=3,
				desc = L["ConfOffsetDesc"],min=0,max=200,step=.1,
				get = function(info) return DB.yoffset end,
				set = function(info,val)
					if (InCombatLockdown()) then 
						SUI:Print(ERR_NOT_IN_COMBAT);
					else
						if DB.yoffsetAuto then
							SUI:Print(L["confOffsetAuto"]);
						else
							val = tonumber(val);
							DB.yoffset = val;
						end
					end
				end,
				get = function(info) return DB.yoffset; end
			},
			offsetauto = {name = L["AutoOffset"],type = "toggle",desc = L["AutoOffsetDesc"],order=3.1,
				get = function(info) return DB.yoffsetAuto end,
				set = function(info,val) DB.yoffsetAuto = val end,
			}
		},
	}
	
	Artwork_Core:StatusBarOptions()
	
	if (DB.alpha ~= 1) then
		module:AddNotice();
	end
end

function module:AddNotice()
	if (DB.alpha == 1) then
		SUI.opt.args["Artwork"].args["Artwork"].args["TransparencyNotice"].hidden = true;
	else
		SUI.opt.args["Artwork"].args["Artwork"].args["TransparencyNotice"].hidden = false;
	end
end

function module:OnDisable()
	SpartanUI:Hide();
end

do -- Style Setup
	if DB.Styles.Classic.Color == nil then
		DB.Styles.Classic.Color = {
			Art = false,
			PlayerFrames = false,
			PartyFrames = false,
			RaidFrames = false
		}
	end
	if not SUI.DBG.Bartender4[DB.Styles.Classic.BartenderProfile] then
		SUI.DBG.Bartender4[DB.Styles.Classic.BartenderProfile] = {Style = "Classic"}
	end
end
