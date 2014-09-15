local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local addon = spartan:GetModule("RaidFrames");
----------------------------------------------------------------------------------------------------
function addon:UpdateAura()
	for i = 1,40 do
		local unit = _G["SUI_RaidFrameHeaderUnitButton"..i];
		if unit and unit.Auras then unit.Auras:PostUpdateDebuffs(); end
	end
end
function addon:UpdateText()
	for i = 1,40 do
		local unit = _G["SUI_RaidFrameHeaderUnitButton"..i];
		if unit then unit:TextUpdate(); end
	end
end

function addon:OnInitialize()
	spartan.opt.RaidFrames.args["DisplayOpts"] = {name = L["Frames/DisplayOpts"],type="group",order=1,
		args = {
			toggleraid =  {name = L["Frames/ShowRFrames"], type = "toggle", order=1,
				get = function(info) return DBMod.RaidFrames.showRaid; end,
				set = function(info,val) DBMod.RaidFrames.showRaid = val; addon:UpdateRaid("FORCE_UPDATE"); end
			},
			toggleclassname =  {name = L["Frames/ClrNameClass"], type = "toggle", order=1,
				get = function(info) return DBMod.RaidFrames.showClass; end,
				set = function(info,val) DBMod.RaidFrames.showClass = val; addon:UpdateRaid("FORCE_UPDATE"); end
			},
			scale = {name=L["Frames/ScaleSize"],type="range",order=5,width="full",
				step=.01,min = .01,max = 2,
				get = function(info) return DBMod.RaidFrames.scale; end,
				set = function(info,val) if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.scale = val; addon:UpdateRaid("FORCE_UPDATE"); end end
			},
			
			bar1 = {name=L["Frames/LayoutConf"],type="header",order=20},
			maxColumns = {name=L["Frames/MaxCols"],type="range",order=21,width="full",
				step=1,min = 1,max = 40,
				get = function(info) return DBMod.RaidFrames.maxColumns; end,
				set = function(info,val)
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.maxColumns = val; end
				end
			},
			unitsPerColumn = {name=L["Frames/UnitPerCol"],type="range",order=22,width="full",
				step=1,min = 1,max = 40,
				get = function(info) return DBMod.RaidFrames.unitsPerColumn; end,
				set = function(info,val)
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.unitsPerColumn = val; end
				end
			},
			columnSpacing = {name=L["Frames/ColSpacing"],type="range",order=23,width="full",
				step=1,min = 0,max = 200,
				get = function(info) return DBMod.RaidFrames.columnSpacing; end,
				set = function(info,val)
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.columnSpacing = val; end
				end
			},
			desc1={name=L["Frames/LayoutConfDesc"],type="description",order=29.9},
			
			bar3 = {name=L["Frames/TextStyle"],type="header",order=30},
			healthtextstyle = {name=L["Frames/HTextStyle"],type="select",order=31,
				desc = L["Frames/TextStyle1Desc"].."|n"..L["Frames/TextStyle2Desc"].."|n"..L["Frames/TextStyle3Desc"],
				values = {["long"]=L["Frames/TextStyle1"],["longfor"]=L["Frames/TextStyle2"],["dynamic"]=L["Frames/TextStyle3"],["disabled"]=L["Frames/Disabled"]},
				get = function(info) return DBMod.RaidFrames.bars.health.textstyle; end,
				set = function(info,val) DBMod.RaidFrames.bars.health.textstyle = val; addon:UpdateText(); end
			},
			healthtextmode = {name=L["Frames/HTextMode"],type="select",order=32,
				values = {[1]=L["Frames/HTextMode1"],[2]=L["Frames/HTextMode2"],[3]=L["Frames/HTextMode3"]},
				get = function(info) return DBMod.RaidFrames.bars.health.textmode; end,
				set = function(info,val) DBMod.RaidFrames.bars.health.textmode = val; addon:UpdateText(); end
			}
		}
	}
	spartan.opt.RaidFrames.args["debuffs"] = { name = L["Frames/Debuffs"], type = "group", order = 2,
		args = {
			party = {name = L["Frames/ShowAuras"], type = "toggle",order=1,
				get = function(info) return DBMod.RaidFrames.showAuras; end,
				set = function(info,val)
					DBMod.RaidFrames.showAuras = val
					addon:UpdateAura();
				end
			},
			size = {name = L["Frames/BuffSize"], type = "range",order=2,
				min=1,max=30,step=1,
				get = function(info) return DBMod.RaidFrames.Auras.size; end,
				set = function(info,val) DBMod.RaidFrames.Auras.size = val; addon:UpdateAura(); end
			}
		}
	};
	
	spartan.opt.RaidFrames.args["FramePreSets"] = {name = L["Frames/PreSets"], type = "select", order=1,disabled=true,
		values = {["custom"]=L["Frames/Custom"],["tank"]=L["Frames/Tank"],["dps"]=L["Frames/DPS"],["healer"]=L["Frames/Healer"]},
		desc=L["Frames/SetTankDesc"].."|n|n"..L["Frames/SetDPSDesc"].."|n|n"..L["Frames/SetHealDesc"],
		get = function(info) return DBMod.RaidFrames.preset; end,
		set = function(info,val)
			if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.preset = val; end
		end
	};
	spartan.opt.RaidFrames.args["FrameStyle"] = {name = L["Frames/FrameStyle"], type = "select", order=2,
		values = {["large"]=L["Frames/Large"],["medium"]=L["Frames/Medium"],["small"]=L["Frames/Small"]},
		get = function(info) return DBMod.RaidFrames.FrameStyle; end,
		set = function(info,val)
			if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.FrameStyle = val; end
		end
	};
	spartan.opt.RaidFrames.args["mode"] = {name = L["Frames/LayMode"], type = "select", order=3,disabled=true,
		values = {["name"]=L["Frames/LayName"],["group"]=L["Frames/LayGrp"],["role"]=L["Frames/LayRole"]},
		get = function(info) return DBMod.RaidFrames.mode; end,
		set = function(info,val) DBMod.RaidFrames.mode = val; addon:UpdateRaid("FORCE_UPDATE"); end
	};
	spartan.opt.RaidFrames.args["threat"] = {name=L["Frames/DispThreat"],type="toggle",order=4,
		get = function(info) return DBMod.RaidFrames.threat; end,
		set = function(info,val) DBMod.RaidFrames.threat = val; DBMod.RaidFrames.preset = "custom"; end
	};
	spartan.opt.RaidFrames.args["raidLockReset"] = {name = L["Frames/ResetRaidPos"], type = "execute", order=11,
		func = function()
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				DBMod.RaidFrames.moved = false;
				addon:UpdateRaidPosition();
			end
		end
	};
	spartan.opt.RaidFrames.args["HideBlizz"] = {name=L["Frames/HideBlizzFrames"],type="toggle",order=4,
		get = function(info) return DBMod.RaidFrames.HideBlizzFrames; end,
		set = function(info,val) DBMod.RaidFrames.HideBlizzFrames = val; end
	};
end