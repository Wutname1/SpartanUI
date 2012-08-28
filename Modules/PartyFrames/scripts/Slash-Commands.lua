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
	if not spartan.options.args.auras then
		spartan.options.args["auras"] = {
			name = "Unitframe Auras",
			desc = "unitframe aura settings",
			type = "group", args = {}
		};
	end
	if not spartan.options.args.castbar then
		spartan.options.args["castbar"] = {
			name = "Unitframe Castbar",
			desc = "unitframe castbar settings",
			type = "group", args = {}
		};
	end
	if not spartan.options.args.castbar.args.text then
		spartan.options.args["castbar"] = {
			name = "Unitframe Castbar Text",
			desc = "unitframe castbar text settings",
			type = "group", args = {}
		};
	end
	spartan.options.args.auras.args.party = {
		name = "toggle party auras", type = "toggle", 
		get = function(info) return suiChar.PartyFrames.showAuras; end,
		set = function(info,val)
			if suiChar.PartyFrames.showAuras == 0 then
				suiChar.PartyFrames.showAuras = 1;
				spartan:Print("Party Auras Enabled");
			else
				suiChar.PartyFrames.showAuras = 0;
				spartan:Print("Party Auras Disabled");
			end
			addon:UpdateAuraVisibility();
		end
	};
	spartan.options.args.castbar.args.party = {
		name = "toggle party castbar style", type = "toggle", 
		get = function(info) return suiChar.PartyFrames.castbar; end,
		set = function(info,val)
			if suiChar.PartyFrames.castbar == 0 then
				suiChar.PartyFrames.castbar = 1;
				spartan:Print("Party Castbar SpartanUI style");
			else
				suiChar.PartyFrames.castbar = 0;
				spartan:Print("Party Castbar oUF style");
			end
		end
	};
	spartan.options.args.castbar.args.party = {
		name = "toggle party castbar text style", type = "toggle", 
		get = function(info) return suiChar.PartyFrames.castbartext; end,
		set = function(info,val)
			if suiChar.PartyFrames.castbartext == 0 then
				suiChar.PartyFrames.castbartext = 1;
				spartan:Print("Party Castbar Text SpartanUI style");
			else
				suiChar.PartyFrames.castbartext = 0;
				spartan:Print("Party Castbar Text oUF style");
			end
		end
	};
	spartan.options.args["party"] = {
		type = "input",
		name = "lock, unlock or reset party frame positioning",
		set = function(info,val)
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				if (val == "" and addon.locked == 1) or (val == "unlock") then
					addon.locked = 0;
					SUI_PartyFrameHeader.mover:Show();
					spartan:Print("Party Position Unlocked");
				elseif (val == "" and addon.locked == 0) or (val == "lock") then
					addon.locked = 1;
					SUI_PartyFrameHeader.mover:Hide();
					spartan:Print("Party Position Locked");
				elseif val == "reset" then
					suiChar.PartyFrames.partyMoved = false;
					addon.locked = 1;
					SUI_PartyFrameHeader.mover:Hide();
					SUI_PartyFrameHeader:SetMovable(true);
					SUI_PartyFrameHeader:SetUserPlaced(false)
					addon:UpdatePartyPosition();
					spartan:Print("Party Position Reset");
				end
			end
		end,
		get = function(info) return suiChar and suiChar.PartyFrames and suiChar.PartyFrames.partyLock; end
	};
	spartan.options.args["toggleraid"] = {
		name = "toggle showing party unitframe while in raid",
		type = "toggle", 
		get = function(info) return suiChar.PartyFrames.HidePartyInRaid; end,
		set = function(info,val)
			if suiChar.PartyFrames.HidePartyInRaid == 0 then
				suiChar.PartyFrames.HidePartyInRaid = 1;
				spartan:Print("Party UnitFrame will now hide while in a raid");
				SUI_PartyFrameHeader:SetAttribute("showRaid",false)
			else
				suiChar.PartyFrames.HidePartyInRaid = 0;
				spartan:Print("Party UnitFrame will now show while in a raid");
				SUI_PartyFrameHeader:SetAttribute("showRaid",true)
			end
			addon:UpdateParty("FORCE_UPDATE")
		end
	};
	spartan.options.args["toggleparty"] = {
		name = "toggle party showing party unitframe",
		type = "toggle", 
		get = function(info) return suiChar.PartyFrames.HideParty; end,
		set = function(info,val)
			if suiChar.PartyFrames.HideParty == 0 then
				suiChar.PartyFrames.HideParty = 1;
				spartan:Print("Party UnitFrame Hidden");
				SUI_PartyFrameHeader:SetAttribute("showParty",false)
			else
				suiChar.PartyFrames.HideParty = 0;
				spartan:Print("Party UnitFrame Shown");
				SUI_PartyFrameHeader:SetAttribute("showParty",true)
			end
			addon:UpdateParty("FORCE_UPDATE")
		end
	};
	spartan.options.args["toggleplayer"] = {
		name = "toggle player showing party unitframe",
		type = "toggle", 
		get = function(info) return suiChar.PartyFrames.HidePlayer; end,
		set = function(info,val)
			if suiChar.PartyFrames.HidePlayer == 0 then
				suiChar.PartyFrames.HidePlayer = 1;
				spartan:Print("Player disabled in Party UnitFrame");
				SUI_PartyFrameHeader:SetAttribute("showPlayer",false)
			else
				suiChar.PartyFrames.HidePlayer = 0;
				spartan:Print("Player enabled in Party UnitFrame");
				SUI_PartyFrameHeader:SetAttribute("showPlayer",true)
			end
			addon:UpdateParty("FORCE_UPDATE")
		end
	};
	spartan.options.args["togglesolo"] = {
		name = "toggle showing party unitframe while solo",
		type = "toggle", 
		get = function(info) return suiChar.PartyFrames.HideSolo; end,
		set = function(info,val)
			if suiChar.PartyFrames.HideSolo == 0 then
				suiChar.PartyFrames.HideSolo = 1;
				spartan:Print("Disabled showing Party UnitFrame while solo");
				SUI_PartyFrameHeader:SetAttribute("showSolo",false)
			else
				suiChar.PartyFrames.HideSolo = 0;
				spartan:Print("Enabled showing Party UnitFrame while solo");
				SUI_PartyFrameHeader:SetAttribute("showSolo",true)
			end
			addon:UpdateParty("FORCE_UPDATE")
		end
	};
end