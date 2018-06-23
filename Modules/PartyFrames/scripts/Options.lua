local _G, SUI = _G, SUI
local L = SUI.L;
local PartyFrames = SUI.PartyFrames
----------------------------------------------------------------------------------------------------
function PartyFrames:UpdateAura()
	for i = 1,4 do
		if _G["SUI_PartyFrameHeaderUnitButton"..i] then
			local unit = _G["SUI_PartyFrameHeaderUnitButton"..i];
			if unit and unit.Auras then unit.Auras:PostUpdate(); end
		end
	end
end
function PartyFrames:UpdateText()
	for i = 1,5 do
		if _G["SUI_PartyFrameHeaderUnitButton"..i] then
			local unit = _G["SUI_PartyFrameHeaderUnitButton"..i];
			if unit then unit:TextUpdate(); end
		end
	end
end

function PartyFrames:OnInitialize()
	SUI.opt.args["PartyFrames"].args["DisplayOpts"] = {name=L["Frames/DisplayOpts"],type="group",order=1,
		desc=L["Frames/DisplayOptsPartyDesc"],args = {
			bar1 = {name=L["Frames/WhenDisplayParty"],type="header",order=0},
			toggleraid =  {name=L["Frames/PartyDispRaid"],type="toggle",order=1,
				get = function(info) return SUI.DBMod.PartyFrames.showPartyInRaid; end,
				set = function(info,val) SUI.DBMod.PartyFrames.showPartyInRaid = val; PartyFrames:UpdateParty("FORCE_UPDATE") end
			},
			toggleparty = {name=L["Frames/PartyDispParty"],type="toggle",order=2,
				get = function(info) return SUI.DBMod.PartyFrames.showParty; end,
				set = function(info,val) SUI.DBMod.PartyFrames.showParty = val; PartyFrames:UpdateParty("FORCE_UPDATE") end
			},
			toggleplayer = { name=L["Frames/PartyDispSelf"],type="toggle",order=3,
				get = function(info) return SUI.DBMod.PartyFrames.showPlayer; end,
				set = function(info,val) SUI.DBMod.PartyFrames.showPlayer = val; PartyFrames:UpdateParty("FORCE_UPDATE"); end
			},
			togglesolo = {name=L["Frames/PartyDispSolo"],type="toggle",order=4,
				get = function(info) return SUI.DBMod.PartyFrames.showSolo; end,
				set = function(info,val)
					SUI.DBMod.PartyFrames.showSolo = val;
					PartyFrames:UpdateParty("FORCE_UPDATE");
				end
			},
			
			bar2 = {name=L["Frames/SubFrameDisp"],type="header",order=10},
			DisplayPet = {name=L["Frames/DispPet"],type="toggle",order=11,
				get = function(info) return SUI.DBMod.PartyFrames.display.pet; end,
				set = function(info,val) SUI.DBMod.PartyFrames.display.pet = val; end
			},
			DisplayTarget = {name=L["Frames/DispTarget"],type="toggle",order=12,
				get = function(info) return SUI.DBMod.PartyFrames.display.target; end,
				set = function(info,val) SUI.DBMod.PartyFrames.display.target = val; end
			},
		
			bar3 = {name=L["Frames/TextStyle"],type="header",order=20},
			healthtextstyle = {name=L["Frames/HTextStyle"],type="select",order=21,
				desc = L["Frames/TextStyle1Desc"].."|n"..L["Frames/TextStyle2Desc"].."|n"..L["Frames/TextStyle3Desc"],
				values = {["Long"]=L["Frames/TextStyle1"],["longfor"]=L["Frames/TextStyle2"],["dynamic"]=L["Frames/TextStyle3"],["disabled"]=L["Frames/Disabled"]},
				get = function(info) return SUI.DBMod.PartyFrames.bars.health.textstyle; end,
				set = function(info,val) SUI.DBMod.PartyFrames.bars.health.textstyle = val; PartyFrames:UpdateText(); end
			},
			healthtextmode = {name=L["Frames/HTextMode"],type="select",order=22,
				values = {[1]=L["Frames/HTextMode1"],[2]=L["Frames/HTextMode2"],[3]=L["Frames/HTextMode3"]},
				get = function(info) return SUI.DBMod.PartyFrames.bars.health.textmode; end,
				set = function(info,val) SUI.DBMod.PartyFrames.bars.health.textmode = val; PartyFrames:UpdateText(); end
			},
			manatextstyle = {name=L["Frames/MTextStyle"],type="select",order=23,
				desc = L["Frames/TextStyle1Desc"].."|n"..L["Frames/TextStyle2Desc"].."|n"..L["Frames/TextStyle3Desc"],
				values = {["Long"]=L["Frames/TextStyle1"],["longfor"]=L["Frames/TextStyle2"],["dynamic"]=L["Frames/TextStyle3"],["disabled"]=L["Frames/Disabled"]},
				get = function(info) return SUI.DBMod.PartyFrames.bars.mana.textstyle; end,
				set = function(info,val) SUI.DBMod.PartyFrames.bars.mana.textstyle = val; PartyFrames:UpdateText(); end
			},
			manatextmode = {name=L["Frames/MTextMode"],type="select",order=24,
				values = {[1]=L["Frames/HTextMode1"],[2]=L["Frames/HTextMode2"],[3]=L["Frames/HTextMode3"]},
				get = function(info) return SUI.DBMod.PartyFrames.bars.mana.textmode; end,
				set = function(info,val) SUI.DBMod.PartyFrames.bars.mana.textmode = val; PartyFrames:UpdateText(); end
			},
			toggleclasscolorname =  {name = L["Frames/ClrNameClass"], type = "toggle", order=25,
				get = function(info) return SUI.DBMod.PartyFrames.showClass; end,
				set = function(info,val) SUI.DBMod.PartyFrames.showClass = val; PartyFrames:UpdateParty("FORCE_UPDATE"); end
			}
		}
	}
	SUI.opt.args["PartyFrames"].args["partyReset"] = {name=L["Frames/ResetPartyPos"],type="execute",order=5,
		func = function()
			-- if (InCombatLockdown()) then 
				-- SUI:Print(ERR_NOT_IN_COMBAT);
			-- else
				SUI.DBMod.PartyFrames.moved = false;
				PartyFrames:UpdatePartyPosition();
			-- end
		end
	};
	SUI.opt.args["PartyFrames"].args["scale"] = {name = L["Frames/ScaleSize"], type = "range", order=11,width="full",
		step=.01,min = .01,max = 2,
		get = function(info) return SUI.DBMod.PartyFrames.scale; end,
		set = function(info,val)
			if (InCombatLockdown()) then SUI:Print(ERR_NOT_IN_COMBAT); else SUI.DBMod.PartyFrames.scale = val; PartyFrames:UpdateParty("FORCE_UPDATE"); end
		end
	};
end
