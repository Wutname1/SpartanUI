local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("RaidFrames");
----------------------------------------------------------------------------------------------------
function addon:UpdateAuraVisibility()
	for i = 1,4 do
		local pet = _G["SUI_PartyFrameHeaderUnitButton"..i.."Pet"];
		local unit = _G["SUI_PartyFrameHeaderUnitButton"..i];
		if pet and pet.Auras then pet.Auras:PostUpdate(); end
		if unit and unit.Auras then unit.Auras:PostUpdate(); end
	end
end

function addon:OnInitialize()
	spartan.optionsRaidFrames.args["DisplayOpts"] = {name = "Display Options",type="group",order=1,
		args = {
			toggleraid =  {name = "Show party in raid", type = "toggle", order=1,
				get = function(info) return DBMod.PartyFrames.showPartyInRaid; end,
				set = function(info,val) DBMod.PartyFrames.showPartyInRaid = val; addon:UpdateParty("FORCE_UPDATE") end
			},
			toggleparty = {name = "Show while in party", type = "toggle", order = 2,
				get = function(info) return DBMod.PartyFrames.showParty; end,
				set = function(info,val) DBMod.PartyFrames.showParty = val; addon:UpdateParty("FORCE_UPDATE") end
			},
			toggleplayer = { name = "Display self in Party", type = "toggle", order=3,
				get = function(info) return DBMod.PartyFrames.showPlayer; end,
				set = function(info,val) DBMod.PartyFrames.showPlayer = val; addon:UpdateParty("FORCE_UPDATE"); end
			},
			togglesolo = {name = "Show party while solo", type = "toggle", order=4,
				get = function(info) return DBMod.PartyFrames.showSolo; end,
				set = function(info,val)
					DBMod.PartyFrames.showSolo = val;
					addon:UpdateParty("FORCE_UPDATE");
				end
			},
			DisplayPets = {name = "Display Pets", type = "toggle", order=21,disabled=true,
				get = function(info) return DBMod.PartyFrames.DisplayPets; end,
				set = function(info,val) DBMod.PartyFrames.DisplayPets = val; end
			}
		}
	}
	spartan.optionsRaidFrames.args["auras"] = { name = "Party Auras", type = "group", order = 2,
		desc = "Aura settings", args = {
			party = {name = "Display party auras", type = "toggle", 
				get = function(info) return DBMod.PartyFrames.showAuras; end,
				set = function(info,val)
					DBMod.PartyFrames.showAuras = val
					addon:UpdateAuraVisibility();
				end
			}
		}
	};
	spartan.optionsRaidFrames.args["castbar"] = { name = "Party Castbar", type = "group", order = 3,
		desc = "Party castbar settings", args = {
			castbar = { name = "Fill Direction", type = "select", style="radio",
				values = {[0]="Fill left to right",[1]="Deplete Right to Left"},
				get = function(info) return DBMod.PartyFrames.castbar; end,
				set = function(info,val) DBMod.PartyFrames.castbar = val; end
			},
			castbartext = {
				name = "Text style", type = "select", style="radio",
				values = {[0]="Count up",[1]="Count down"},
				get = function(info) return DBMod.PartyFrames.castbartext; end,
				set = function(info,val) DBMod.PartyFrames.castbartext = val; end
			}
		}
	};

	spartan.optionsRaidFrames.args["partyLock"] = {name = "Lock/Unlock Party frame position", type = "execute", width="double", order=11,
		func = function()
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				if DBMod.PartyFrames.partyLock then
					DBMod.PartyFrames.partyLock = false;
					SUI_PartyFrameHeader.mover:Show();
				else
					DBMod.PartyFrames.partyLock = true;
					SUI_PartyFrameHeader.mover:Hide();
				end
			end
		end
	};
	spartan.optionsRaidFrames.args["partyLockReset"] = {name = "Reset Party poition", type = "execute", order=12,
		func = function()
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				DBMod.PartyFrames.partyMoved = false;
				DBMod.PartyFrames.partyLock = true;
				SUI_PartyFrameHeader.mover:Hide();
				SUI_PartyFrameHeader:SetMovable(true);
				SUI_PartyFrameHeader:SetUserPlaced(false)
				addon:UpdatePartyPosition();
			end
		end
	};
	
	spartan.optionsRaidFrames.args["FrameStyle"] = {name = "Frame Style", type = "select", order=.2,disabled=true,
		values = {["large"]="Large",["medium"]="Medium",["small"]="Small"},
		get = function(info) return DBMod.PartyFrames.FrameStyle; end,
		set = function(info,val)
			if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.PartyFrames.FrameStyle = val; end
		end
	};
	spartan.optionsRaidFrames.args["FramePreSets"] = {name = "Frame Pre-Sets", type = "select", order=.1,disabled=true,
		values = {["custom"]="Custom",["dps"]="DPS",["healer"]="Healer"},
		get = function(info) return DBMod.PartyFrames.Presets; end,
		set = function(info,val)
			if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.PartyFrames.Presets = val; end
		end
	};

end