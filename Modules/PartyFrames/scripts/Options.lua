local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local addon = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------
function addon:UpdateAura()
	for i = 1,4 do
		if _G["SUI_PartyFrameHeaderUnitButton"..i] then
			local unit = _G["SUI_PartyFrameHeaderUnitButton"..i];
			if unit and unit.Auras then unit.Auras:PostUpdate(); end
		end
	end
end
function addon:UpdateText()
	for i = 1,5 do
		if _G["SUI_PartyFrameHeaderUnitButton"..i] then
			local unit = _G["SUI_PartyFrameHeaderUnitButton"..i];
			if unit then unit:TextUpdate(); end
		end
	end
end

function addon:OnInitialize()
	spartan.opt.args["PartyFrames"].args["DisplayOpts"] = {name=L["Frames/DisplayOpts"],type="group",order=1,
		desc=L["Frames/DisplayOptsPartyDesc"],args = {
			bar1 = {name=L["Frames/WhenDisplayParty"],type="header",order=0},
			toggleraid =  {name=L["Frames/PartyDispRaid"],type="toggle",order=1,
				get = function(info) return DBMod.PartyFrames.showPartyInRaid; end,
				set = function(info,val) DBMod.PartyFrames.showPartyInRaid = val; addon:UpdateParty("FORCE_UPDATE") end
			},
			toggleparty = {name=L["Frames/PartyDispParty"],type="toggle",order=2,
				get = function(info) return DBMod.PartyFrames.showParty; end,
				set = function(info,val) DBMod.PartyFrames.showParty = val; addon:UpdateParty("FORCE_UPDATE") end
			},
			toggleplayer = { name=L["Frames/PartyDispSelf"],type="toggle",order=3,
				get = function(info) return DBMod.PartyFrames.showPlayer; end,
				set = function(info,val) DBMod.PartyFrames.showPlayer = val; addon:UpdateParty("FORCE_UPDATE"); end
			},
			togglesolo = {name=L["Frames/PartyDispSolo"],type="toggle",order=4,
				get = function(info) return DBMod.PartyFrames.showSolo; end,
				set = function(info,val)
					DBMod.PartyFrames.showSolo = val;
					addon:UpdateParty("FORCE_UPDATE");
				end
			},
			
			bar2 = {name=L["Frames/SubFrameDisp"],type="header",order=10},
			DisplayPet = {name=L["Frames/DispPet"],type="toggle",order=11,
				get = function(info) return DBMod.PartyFrames.display.pet; end,
				set = function(info,val) DBMod.PartyFrames.display.pet = val; end
			},
			DisplayTarget = {name=L["Frames/DispTarget"],type="toggle",order=12,
				get = function(info) return DBMod.PartyFrames.display.target; end,
				set = function(info,val) DBMod.PartyFrames.display.target = val; end
			},
		
			bar3 = {name=L["Frames/TextStyle"],type="header",order=20},
			healthtextstyle = {name=L["Frames/HTextStyle"],type="select",order=21,
				desc = L["Frames/TextStyle1Desc"].."|n"..L["Frames/TextStyle2Desc"].."|n"..L["Frames/TextStyle3Desc"],
				values = {["Long"]=L["Frames/TextStyle1"],["longfor"]=L["Frames/TextStyle2"],["dynamic"]=L["Frames/TextStyle3"],["disabled"]=L["Frames/Disabled"]},
				get = function(info) return DBMod.PartyFrames.bars.health.textstyle; end,
				set = function(info,val) DBMod.PartyFrames.bars.health.textstyle = val; addon:UpdateText(); end
			},
			healthtextmode = {name=L["Frames/HTextMode"],type="select",order=22,
				values = {[1]=L["Frames/HTextMode1"],[2]=L["Frames/HTextMode2"],[3]=L["Frames/HTextMode3"]},
				get = function(info) return DBMod.PartyFrames.bars.health.textmode; end,
				set = function(info,val) DBMod.PartyFrames.bars.health.textmode = val; addon:UpdateText(); end
			},
			manatextstyle = {name=L["Frames/MTextStyle"],type="select",order=23,
				desc = L["Frames/TextStyle1Desc"].."|n"..L["Frames/TextStyle2Desc"].."|n"..L["Frames/TextStyle3Desc"],
				values = {["Long"]=L["Frames/TextStyle1"],["longfor"]=L["Frames/TextStyle2"],["dynamic"]=L["Frames/TextStyle3"],["disabled"]=L["Frames/Disabled"]},
				get = function(info) return DBMod.PartyFrames.bars.mana.textstyle; end,
				set = function(info,val) DBMod.PartyFrames.bars.mana.textstyle = val; addon:UpdateText(); end
			},
			manatextmode = {name=L["Frames/MTextMode"],type="select",order=24,
				values = {[1]=L["Frames/HTextMode1"],[2]=L["Frames/HTextMode2"],[3]=L["Frames/HTextMode3"]},
				get = function(info) return DBMod.PartyFrames.bars.mana.textmode; end,
				set = function(info,val) DBMod.PartyFrames.bars.mana.textmode = val; addon:UpdateText(); end
			},
			toggleclasscolorname =  {name = L["Frames/ClrNameClass"], type = "toggle", order=25,
				get = function(info) return DBMod.PartyFrames.showClass; end,
				set = function(info,val) DBMod.PartyFrames.showClass = val; addon:UpdateParty("FORCE_UPDATE"); end
			}
		}
	}
	spartan.opt.args["PartyFrames"].args["partyReset"] = {name=L["Frames/ResetPartyPos"],type="execute",order=5,
		func = function()
			-- if (InCombatLockdown()) then 
				-- spartan:Print(ERR_NOT_IN_COMBAT);
			-- else
				DBMod.PartyFrames.moved = false;
				addon:UpdatePartyPosition();
			-- end
		end
	};
	spartan.opt.args["PartyFrames"].args["scale"] = {name = L["Frames/ScaleSize"], type = "range", order=11,width="full",
		step=.01,min = .01,max = 2,
		get = function(info) return DBMod.PartyFrames.scale; end,
		set = function(info,val)
			if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); else DBMod.PartyFrames.scale = val; addon:UpdateParty("FORCE_UPDATE"); end
		end
	};
end
