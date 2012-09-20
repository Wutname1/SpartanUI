local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------
function addon:UpdateAura()
	for i = 1,4 do
		local unit = _G["SUI_PartyFrameHeaderUnitButton"..i];
		if unit and unit.Auras then unit.Auras:PostUpdate(); end
	end
end
function addon:UpdateText()
	for i = 1,4 do
		local unit = _G["SUI_PartyFrameHeaderUnitButton"..i];
		if unit then unit:TextUpdate(); end
	end
end

function addon:OnInitialize()
	spartan.optionsPartyFrames.args["DisplayOpts"] = {name="Display Options",type="group",order=1,
		desc="Select when to show and when not to show your party",args = {
		
			bar1 = {name="When to show Party",type="header",order=0},
			toggleraid =  {name="Show party in raid",type="toggle",order=1,
				get = function(info) return DBMod.PartyFrames.showPartyInRaid; end,
				set = function(info,val) DBMod.PartyFrames.showPartyInRaid = val; addon:UpdateParty("FORCE_UPDATE") end
			},
			toggleparty = {name="Show while in party",type="toggle",order=2,
				get = function(info) return DBMod.PartyFrames.showParty; end,
				set = function(info,val) DBMod.PartyFrames.showParty = val; addon:UpdateParty("FORCE_UPDATE") end
			},
			toggleplayer = { name="Display self in Party",type="toggle",order=3,
				get = function(info) return DBMod.PartyFrames.showPlayer; end,
				set = function(info,val) DBMod.PartyFrames.showPlayer = val; addon:UpdateParty("FORCE_UPDATE"); end
			},
			togglesolo = {name="Show party while solo",type="toggle",order=4,
				get = function(info) return DBMod.PartyFrames.showSolo; end,
				set = function(info,val)
					DBMod.PartyFrames.showSolo = val;
					addon:UpdateParty("FORCE_UPDATE");
				end
			},
			
			bar2 = {name="Sub Frame Display",type="header",order=10},
			DisplayPet = {name="Display Pets",type="toggle",order=11,
				get = function(info) return DBMod.PartyFrames.display.pet; end,
				set = function(info,val) DBMod.PartyFrames.display.pet = val; end
			},
			DisplayTarget = {name="Display Target",type="toggle",order=12,
				get = function(info) return DBMod.PartyFrames.display.target; end,
				set = function(info,val) DBMod.PartyFrames.display.target = val; end
			},
		
			bar3 = {name="Text style",type="header",order=20},
			healthtextstyle = {name="Health Text style",type="select",order=21,
				desc = "Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed",
				values = {["long"]="Long",["longfor"]="Long Formatted",["dynamic"]="Dynamic",["disabled"]="Disabled"},
				get = function(info) return DBMod.PartyFrames.bars.health.textstyle; end,
				set = function(info,val) DBMod.PartyFrames.bars.health.textstyle = val; addon:UpdateText(); end
			},
			healthtextmode = {name="Health Text mode",type="select",order=22,
				values = {[1]="Avaliable / Total",[2]="(Missing) Avaliable / Total",[3]="(Missing) Avaliable"},
				get = function(info) return DBMod.PartyFrames.bars.health.textmode; end,
				set = function(info,val) DBMod.PartyFrames.bars.health.textmode = val; addon:UpdateText(); end
			},
			manatextstyle = {name="Mana Text style",type="select",order=23,
				desc = "Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed",
				values = {["long"]="Long",["longfor"]="Long Formatted",["dynamic"]="Dynamic"},
				get = function(info) return DBMod.PartyFrames.bars.mana.textstyle; end,
				set = function(info,val) DBMod.PartyFrames.bars.mana.textstyle = val; addon:UpdateText(); end
			},
			manatextmode = {name="Mana Text mode",type="select",order=24,
				values = {[1]="Avaliable / Total",[2]="(Missing) Avaliable / Total",[3]="(Missing) Avaliable"},
				get = function(info) return DBMod.PartyFrames.bars.mana.textmode; end,
				set = function(info,val) DBMod.PartyFrames.bars.mana.textmode = val; addon:UpdateText(); end
			}
		}
	}
	spartan.optionsPartyFrames.args["auras"] = {name="Buff & Debuffs",type="group",order=2,
		args = {
			display = {name="Display Buffs & Debuffs",type="toggle", order=1,
				get = function(info) return DBMod.PartyFrames.showAuras; end,
				set = function(info,val) DBMod.PartyFrames.showAuras = val; addon:UpdateAura(); end
			},
			showType = {name="Show the Type",type="toggle", order=2,
				get = function(info) return DBMod.PartyFrames.Auras.showType; end,
				set = function(info,val) DBMod.PartyFrames.Auras.showType = val; addon:UpdateAura(); end
			},
			numBufs = {name="Number of Buffs to show",type="range",width="full",order=11,
				min=0,max=50,step=1,
				get = function(info) return DBMod.PartyFrames.Auras.NumBuffs; end,
				set = function(info,val) DBMod.PartyFrames.Auras.NumBuffs = val; addon:UpdateAura(); end
			},
			numDebuffs = {name="Number of DeBuffs to show",type="range",width="full",order=12,
				min=0,max=50,step=1,
				get = function(info) return DBMod.PartyFrames.Auras.NumDebuffs; end,
				set = function(info,val) DBMod.PartyFrames.Auras.NumDebuffs = val; addon:UpdateAura(); end
			},
			size = {name="Size of Buffs/Debuffs",type="range",width="full",order=13,
				min=0,max=60,step=1,
				get = function(info) return DBMod.PartyFrames.Auras.size; end,
				set = function(info,val) DBMod.PartyFrames.Auras.size = val; addon:UpdateAura(); end
			},
			sizedesc={name="You will have control of Buff vs Debuff Size in a latter verison",type="description",order=13.5},
			spacing = {name="Spacing between Buffs/Debuffs",type="range",width="full",order=14,
				min=0,max=50,step=1,
				get = function(info) return DBMod.PartyFrames.Auras.spacing; end,
				set = function(info,val) DBMod.PartyFrames.Auras.spacing = val; addon:UpdateAura(); end
			},
			
		}
	};
	spartan.optionsPartyFrames.args["castbar"] = {name="Party Castbar",type="group",order=3,
		desc = "Party castbar settings", args = {
			castbar = {name="Fill Direction",type="select", style="radio",
				values = {[0]="Fill left to right",[1]="Deplete Right to Left"},
				get = function(info) return DBMod.PartyFrames.castbar; end,
				set = function(info,val) DBMod.PartyFrames.castbar = val; end
			},
			castbartext = {name="Text style",type="select", style="radio",
				values = {[0]="Count up",[1]="Count down"},
				get = function(info) return DBMod.PartyFrames.castbartext; end,
				set = function(info,val) DBMod.PartyFrames.castbartext = val; end
			}
		}
	};
	
	spartan.optionsPartyFrames.args["FrameStyle"] = {name="Frame Style",type="select",order=.2,
		values = {["large"]="Castbar & Health & Mana",["medium"]="Health & Mana",["small"]="Health",["xsmall"]="Health Narrow"},
		get = function(info) return DBMod.PartyFrames.FrameStyle; end,
		set = function(info,val)
			if (InCombatLockdown()) then return spartan:Print(ERR_NOT_IN_COMBAT);end DBMod.PartyFrames.FrameStyle = val;
		end
	};
	spartan.optionsPartyFrames.args["Portrait"] = {name="Display Portrait",type="toggle",order=.3,
		get = function(info) return DBMod.PartyFrames.Portrait; end,
		set = function(info,val)
			if (InCombatLockdown()) then return spartan:Print(ERR_NOT_IN_COMBAT);end DBMod.PartyFrames.Portrait = val;
		end
	};
	spartan.optionsPartyFrames.args["FramePreSets"] = {name="Frame Pre-Sets",type="select",order=.1,
		values = {["custom"]="Custom",["tank"]="Tank",["dps"]="DPS",["healer"]="Healer"},
		get = function(info) return DBMod.PartyFrames.Presets; end,
		set = function(info,val)
			if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.PartyFrames.Presets = val; end
		end
	};

	spartan.optionsPartyFrames.args["partyLockReset"] = {name="Reset Party poition",type="execute",order=12,
		func = function()
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				DBMod.PartyFrames.moved = false;
				addon:UpdatePartyPosition();
			end
		end
	};
	spartan.optionsPartyFrames.args["test"] = {name="test",type="execute",order=12,
		func = function()
			if (addon.party1:IsShown()) then
				addon.party1:hide()
			else
				addon.party1:show()
			end
		end
	};

end