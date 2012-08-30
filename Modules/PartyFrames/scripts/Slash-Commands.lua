local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PartyFrames");
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
	spartan.optionsPartyFrames.args["auras"] = { name = "Party Auras", type = "group", order = 1,
		desc = "Aura settings", args = {}
	};

	spartan.optionsPartyFrames.args["toggleraid"] = {name = "Show party while in raid", type = "toggle", order=1,
		get = function(info) return DBMod.PartyFrames.showPartyInRaid; end,
		set = function(info,val) DBMod.PartyFrames.showPartyInRaid = val; addon:UpdateParty("FORCE_UPDATE") end
	};
	spartan.optionsPartyFrames.args["toggleparty"] = {name = "Show party frames when in party", type = "toggle", order = 2, width="double",
		get = function(info) return DBMod.PartyFrames.showParty; end,
		set = function(info,val) DBMod.PartyFrames.showParty = val; addon:UpdateParty("FORCE_UPDATE") end
	};
	spartan.optionsPartyFrames.args["toggleplayer"] = { name = "Display self in Party", type = "toggle", order=3,
		get = function(info) return DBMod.PartyFrames.showPlayer; end,
		set = function(info,val) DBMod.PartyFrames.showPlayer = val; addon:UpdateParty("FORCE_UPDATE"); end
	};
	spartan.optionsPartyFrames.args["togglesolo"] = {name = "Show party while solo", type = "toggle", order=4,
		get = function(info) return DBMod.PartyFrames.showSolo; end,
		set = function(info,val)
			DBMod.PartyFrames.showSolo = val;
			addon:UpdateParty("FORCE_UPDATE");
		end
	};

	spartan.optionsPartyFrames.args["partyLock"] = {name = "Lock/Unlock Party frame position", type = "execute", width="double", order=11,
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
	spartan.optionsPartyFrames.args["partyLockReset"] = {name = "Reset Party poition", type = "execute", order=12,
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
	
	spartan.optionsPartyFrames.args.auras.args.party = {name = "Display party auras", type = "toggle", 
		get = function(info) return DBMod.PartyFrames.showAuras; end,
		set = function(info,val)
			DBMod.PartyFrames.showAuras = val
			addon:UpdateAuraVisibility();
		end
	};

	spartan.optionsPartyFrames.args["castbar"] = { name = "Party Castbar", type = "group", order = 2,
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

	
end