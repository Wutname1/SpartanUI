local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
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
	spartan.optionsRaidFrames.args["DisplayOpts"] = {name = "Display Options",type="group",order=1,
		args = {
			toggleraid =  {name = "Show Raid Frames", type = "toggle", order=1,
				get = function(info) return DBMod.RaidFrames.showRaid; end,
				set = function(info,val) DBMod.RaidFrames.showRaid = val; addon:UpdateRaid("FORCE_UPDATE"); end
			},
			scale = {name="Scale Size",type="range",order=5,width="full",
				step=.01,min = .01,max = 2,
				get = function(info) return DBMod.RaidFrames.scale; end,
				set = function(info,val) if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.scale = val; addon:UpdateRaid("FORCE_UPDATE"); end end
			},
			bar1 = {name="Layout Configuration",type="header",order=20},
			maxColumns = {name="Max Columns",type="range",order=21,width="full",
				step=1,min = 1,max = 40,
				get = function(info) return DBMod.RaidFrames.maxColumns; end,
				set = function(info,val)
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.maxColumns = val; end
				end
			},
			unitsPerColumn = {name="Units Per Column",type="range",order=22,width="full",
				step=1,min = 1,max = 40,
				get = function(info) return DBMod.RaidFrames.unitsPerColumn; end,
				set = function(info,val)
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.unitsPerColumn = val; end
				end
			},
			columnSpacing = {name="Column Spacing",type="range",order=23,width="full",
				step=1,min = 0,max = 200,
				get = function(info) return DBMod.RaidFrames.columnSpacing; end,
				set = function(info,val)
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.columnSpacing = val; end
				end
			},
			desc1={name="All above options require a /reload",type="description",order=29.9},
			
			bar3 = {name="Text style",type="header",order=30},
			healthtextstyle = {name="Health Text style",type="select",order=31,
				desc = "Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed",
				values = {["long"]="Long",["longfor"]="Long Formatted",["dynamic"]="Dynamic",["disabled"]="Disabled"},
				get = function(info) return DBMod.RaidFrames.bars.health.textstyle; end,
				set = function(info,val) DBMod.RaidFrames.bars.health.textstyle = val; addon:UpdateText(); end
			},
			healthtextmode = {name="Health Text mode",type="select",order=32,
				values = {[1]="Avaliable / Total",[2]="(Missing) Avaliable / Total",[3]="(Missing) Avaliable"},
				get = function(info) return DBMod.RaidFrames.bars.health.textmode; end,
				set = function(info,val) DBMod.RaidFrames.bars.health.textmode = val; addon:UpdateText(); end
			}
		}
	}
	spartan.optionsRaidFrames.args["debuffs"] = { name = "Debuffs", type = "group", order = 2,
		args = {
			party = {name = "Show auras", type = "toggle",order=1,
				get = function(info) return DBMod.RaidFrames.showAuras; end,
				set = function(info,val)
					DBMod.RaidFrames.showAuras = val
					addon:UpdateAura();
				end
			},
			size = {name = "Buff size", type = "range",order=2,
				min=1,max=30,step=1,
				get = function(info) return DBMod.RaidFrames.Auras.size; end,
				set = function(info,val) DBMod.RaidFrames.Auras.size = val; addon:UpdateAura(); end
			}
		}
	};
	
	spartan.optionsRaidFrames.args["FramePreSets"] = {name = "Frame Pre-Sets", type = "select", order=1,disabled=true,
		values = {["custom"]="Custom",["tank"]="Tank",["dps"]="DPS",["healer"]="Healer"},
		desc="Tank: Smaller bars, aggro very noticible|n|nDPS:Smaller bars|n|nHealer: Large bars, draws attention to those with aggo.",
		get = function(info) return DBMod.RaidFrames.preset; end,
		set = function(info,val)
			if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.preset = val; end
		end
	};
	spartan.optionsRaidFrames.args["FrameStyle"] = {name = "Frame Style", type = "select", order=2,
		values = {["large"]="Large",["medium"]="Medium",["small"]="Small"},
		get = function(info) return DBMod.RaidFrames.FrameStyle; end,
		set = function(info,val)
			if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.RaidFrames.FrameStyle = val; end
		end
	};
	spartan.optionsRaidFrames.args["mode"] = {name = "Layout Mode", type = "select", order=3,disabled=true,
		values = {["name"]="Order by Name",["group"]="Groups",["role"]="Roles"},
		get = function(info) return DBMod.RaidFrames.mode; end,
		set = function(info,val) DBMod.RaidFrames.mode = val; addon:UpdateRaid("FORCE_UPDATE"); end
	};
	spartan.optionsRaidFrames.args["partyLockReset"] = {name = "Reset Raid poition", type = "execute", order=11,
		func = function()
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				DBMod.RaidFrames.moved = false;
				addon:UpdateRaidPosition();
			end
		end
	};
end