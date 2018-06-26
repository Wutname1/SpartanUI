local _G, SUI = _G, SUI
local L = SUI.L;
local RaidFrames = SUI.RaidFrames
----------------------------------------------------------------------------------------------------

function RaidFrames:OnInitialize()
	SUI.opt.args["RaidFrames"].args["DisplayOpts"] = {name = L["DisplayOpts"],type="group",order=100,inline=true,
		args = {
			toggleraid =  {name = L["ShowRFrames"], type = "toggle", order=1,
				get = function(info) return SUI.DBMod.RaidFrames.showRaid; end,
				set = function(info,val) SUI.DBMod.RaidFrames.showRaid = val; RaidFrames:UpdateRaid("FORCE_UPDATE"); end
			},
			toggleparty = {name=L["PartyDispParty"],type="toggle",order=2,
				get = function(info) return SUI.DBMod.RaidFrames.showParty; end,
				set = function(info,val) SUI.DBMod.RaidFrames.showParty = val; RaidFrames:UpdateRaid("FORCE_UPDATE") end
			},
			togglesolo = {name=L["PartyDispSolo"],type="toggle",order=4,
				get = function(info) return SUI.DBMod.RaidFrames.showSolo; end,
				set = function(info,val) SUI.DBMod.RaidFrames.showSolo = val; RaidFrames:UpdateRaid("FORCE_UPDATE"); end
			},
			
			toggleclassname =  {name = L["ClrNameClass"], type = "toggle", order=1,
				get = function(info) return SUI.DBMod.RaidFrames.showClass; end,
				set = function(info,val) SUI.DBMod.RaidFrames.showClass = val; RaidFrames:UpdateRaid("FORCE_UPDATE"); end
			},
			scale = {name=L["ScaleSize"],type="range",order=5,width="full",
				step=.01,min = .01,max = 2,
				get = function(info) return SUI.DBMod.RaidFrames.scale; end,
				set = function(info,val) if (InCombatLockdown()) then SUI:Print(ERR_NOT_IN_COMBAT); else SUI.DBMod.RaidFrames.scale = val; RaidFrames:UpdateRaid("FORCE_UPDATE"); end end
			},
			
			bar1 = {name=L["LayoutConf"],type="header",order=20},
			maxColumns = {name=L["MaxCols"],type="range",order=21,width="full",
				step=1,min = 1,max = 40,
				get = function(info) return SUI.DBMod.RaidFrames.maxColumns; end,
				set = function(info,val)
					if (InCombatLockdown()) then SUI:Print(ERR_NOT_IN_COMBAT); else SUI.DBMod.RaidFrames.maxColumns = val; RaidFrames:UpdateRaid("FORCE_UPDATE"); end
				end
			},
			unitsPerColumn = {name=L["UnitPerCol"],type="range",order=22,width="full",
				step=1,min = 1,max = 40,
				get = function(info) return SUI.DBMod.RaidFrames.unitsPerColumn; end,
				set = function(info,val)
					if (InCombatLockdown()) then SUI:Print(ERR_NOT_IN_COMBAT); else SUI.DBMod.RaidFrames.unitsPerColumn = val; RaidFrames:UpdateRaid("FORCE_UPDATE"); end
				end
			},
			columnSpacing = {name=L["ColSpacing"],type="range",order=23,width="full",
				step=1,min = 0,max = 200,
				get = function(info) return SUI.DBMod.RaidFrames.columnSpacing; end,
				set = function(info,val)
					if (InCombatLockdown()) then SUI:Print(ERR_NOT_IN_COMBAT); else SUI.DBMod.RaidFrames.columnSpacing = val; RaidFrames:UpdateRaid("FORCE_UPDATE"); end
				end
			},
			desc1={name=L["LayoutConfDesc"],type="description",order=29.9},
			
			bar3 = {name=L["TextStyle"],type="header",order=30},
			healthtextstyle = {name=L["HTextStyle"],type="select",order=31,
				desc = L["TextStyle1Desc"].."|n"..L["TextStyle2Desc"].."|n"..L["TextStyle3Desc"],
				values = {["long"]=L["TextStyle1"],["longfor"]=L["TextStyle2"],["dynamic"]=L["TextStyle3"],["disabled"]=L["Disabled"]},
				get = function(info) return SUI.DBMod.RaidFrames.bars.health.textstyle; end,
				set = function(info,val) SUI.DBMod.RaidFrames.bars.health.textstyle = val; RaidFrames:UpdateText(); end
			},
			healthtextmode = {name=L["HTextMode"],type="select",order=32,
				values = {[1]=L["HTextMode1"],[2]=L["HTextMode2"],[3]=L["HTextMode3"]},
				get = function(info) return SUI.DBMod.RaidFrames.bars.health.textmode; end,
				set = function(info,val) SUI.DBMod.RaidFrames.bars.health.textmode = val; RaidFrames:UpdateText(); end
			}
		}
	}
	
	SUI.opt.args["RaidFrames"].args["mode"] = {name = L["LayMode"], type = "select", order=3,
		values = {["NAME"]=L["LayName"],["GROUP"]=L["LayGrp"],["ASSIGNEDROLE"]=L["LayRole"]},
		get = function(info) return SUI.DBMod.RaidFrames.mode; end,
		set = function(info,val) SUI.DBMod.RaidFrames.mode = val; RaidFrames:UpdateRaid("FORCE_UPDATE"); end
	};
	SUI.opt.args["RaidFrames"].args["raidLockReset"] = {name = L["ResetRaidPos"], type = "execute", order=11,
		func = function()
			if (InCombatLockdown()) then 
				SUI:Print(ERR_NOT_IN_COMBAT);
			else
				SUI.DBMod.RaidFrames.moved = false;
				RaidFrames:UpdateRaidPosition();
			end
		end
	};
	SUI.opt.args["RaidFrames"].args["HideBlizz"] = {name=L["HideBlizzFrames"],type="toggle",order=4,
		get = function(info) return SUI.DBMod.RaidFrames.HideBlizzFrames; end,
		set = function(info,val) SUI.DBMod.RaidFrames.HideBlizzFrames = val; end
	};
end
