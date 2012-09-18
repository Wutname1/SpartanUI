local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------
function addon:UpdateAuraVisibility()
	for i = 1,4 do
		local unit = _G["SUI_PartyFrameHeaderUnitButton"..i];
		if unit and unit.Auras then unit.Auras:PostUpdate(); end
	end
end

function addon:OnInitialize()
	spartan.optionsPartyFrames.args["DisplayOpts"] = {name="Display Options",type="group",order=1,
		desc="Select when to show and when not to show your party",args = {
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
			DisplayPet = {name="Display Pets",type="toggle",order=21,
				get = function(info) return DBMod.PartyFrames.display.pet; end,
				set = function(info,val) DBMod.PartyFrames.display.pet = val; end
			},
			DisplayTarget = {name="Display Target",type="toggle",order=21,
				get = function(info) return DBMod.PartyFrames.display.target; end,
				set = function(info,val) DBMod.PartyFrames.display.target = val; end
			}
		}
	}
	spartan.optionsPartyFrames.args["auras"] = {name="Buff & Debuffs",type="group",order=2,
		args = {
			party = {name="Display Buffs & Debuffs",type="toggle", 
				get = function(info) return DBMod.PartyFrames.showAuras; end,
				set = function(info,val) DBMod.PartyFrames.showAuras = val; addon:UpdateAuraVisibility(); end
			}
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
		values = {["custom"]="Custom",["dps"]="DPS",["healer"]="Healer"},
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