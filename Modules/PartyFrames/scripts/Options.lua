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
	SUI.opt.args["PartyFrames"].args["DisplayOpts"] = {name=L["DisplayOpts"],type="group",order=100,inline=true,
		desc=L["DisplayOptsPartyDesc"],args = {
			bar1 = {name=L["WhenDisplayParty"],type="header",order=0},
			toggleraid =  {name=L["PartyDispRaid"],type="toggle",order=1,
				get = function(info) return SUI.DBMod.PartyFrames.showPartyInRaid; end,
				set = function(info,val) SUI.DBMod.PartyFrames.showPartyInRaid = val; PartyFrames:UpdateParty("FORCE_UPDATE") end
			},
			toggleparty = {name=L["PartyDispParty"],type="toggle",order=2,
				get = function(info) return SUI.DBMod.PartyFrames.showParty; end,
				set = function(info,val) SUI.DBMod.PartyFrames.showParty = val; PartyFrames:UpdateParty("FORCE_UPDATE") end
			},
			toggleplayer = { name=L["PartyDispSelf"],type="toggle",order=3,
				get = function(info) return SUI.DBMod.PartyFrames.showPlayer; end,
				set = function(info,val) SUI.DBMod.PartyFrames.showPlayer = val; PartyFrames:UpdateParty("FORCE_UPDATE"); end
			},
			togglesolo = {name=L["PartyDispSolo"],type="toggle",order=4,
				get = function(info) return SUI.DBMod.PartyFrames.showSolo; end,
				set = function(info,val)
					SUI.DBMod.PartyFrames.showSolo = val;
					PartyFrames:UpdateParty("FORCE_UPDATE");
				end
			},
			
			bar2 = {name=L["SubFrameDisp"],type="header",order=10},
			DisplayPet = {name=L["DispPet"],type="toggle",order=11,
				get = function(info) return SUI.DBMod.PartyFrames.display.pet; end,
				set = function(info,val) SUI.DBMod.PartyFrames.display.pet = val; end
			},
			DisplayTarget = {name=L["DispTarget"],type="toggle",order=12,
				get = function(info) return SUI.DBMod.PartyFrames.display.target; end,
				set = function(info,val) SUI.DBMod.PartyFrames.display.target = val; end
			},
		
			bar3 = {name=L["TextStyle"],type="header",order=20},
			healthtextstyle = {name=L["HTextStyle"],type="select",order=21,
				desc = L["TextStyle1Desc"].."|n"..L["TextStyle2Desc"].."|n"..L["TextStyle3Desc"],
				values = {["Long"]=L["TextStyle1"],["longfor"]=L["TextStyle2"],["dynamic"]=L["TextStyle3"],["disabled"]=L["Disabled"]},
				get = function(info) return SUI.DBMod.PartyFrames.bars.health.textstyle; end,
				set = function(info,val) SUI.DBMod.PartyFrames.bars.health.textstyle = val; PartyFrames:UpdateText(); end
			},
			healthtextmode = {name=L["HTextMode"],type="select",order=22,
				values = {[1]=L["HTextMode1"],[2]=L["HTextMode2"],[3]=L["HTextMode3"]},
				get = function(info) return SUI.DBMod.PartyFrames.bars.health.textmode; end,
				set = function(info,val) SUI.DBMod.PartyFrames.bars.health.textmode = val; PartyFrames:UpdateText(); end
			},
			manatextstyle = {name=L["MTextStyle"],type="select",order=23,
				desc = L["TextStyle1Desc"].."|n"..L["TextStyle2Desc"].."|n"..L["TextStyle3Desc"],
				values = {["Long"]=L["TextStyle1"],["longfor"]=L["TextStyle2"],["dynamic"]=L["TextStyle3"],["disabled"]=L["Disabled"]},
				get = function(info) return SUI.DBMod.PartyFrames.bars.mana.textstyle; end,
				set = function(info,val) SUI.DBMod.PartyFrames.bars.mana.textstyle = val; PartyFrames:UpdateText(); end
			},
			manatextmode = {name=L["MTextMode"],type="select",order=24,
				values = {[1]=L["HTextMode1"],[2]=L["HTextMode2"],[3]=L["HTextMode3"]},
				get = function(info) return SUI.DBMod.PartyFrames.bars.mana.textmode; end,
				set = function(info,val) SUI.DBMod.PartyFrames.bars.mana.textmode = val; PartyFrames:UpdateText(); end
			},
			toggleclasscolorname =  {name = L["ClrNameClass"], type = "toggle", order=25,
				get = function(info) return SUI.DBMod.PartyFrames.showClass; end,
				set = function(info,val) SUI.DBMod.PartyFrames.showClass = val; PartyFrames:UpdateParty("FORCE_UPDATE"); end
			}
		}
	}
	SUI.opt.args["PartyFrames"].args["partyReset"] = {name=L["ResetPartyPos"],type="execute",order=5,
		func = function()
			-- if (InCombatLockdown()) then 
				-- SUI:Print(ERR_NOT_IN_COMBAT);
			-- else
				SUI.DBMod.PartyFrames.moved = false;
				PartyFrames:UpdatePartyPosition();
			-- end
		end
	};
	SUI.opt.args["PartyFrames"].args["scale"] = {name = L["ScaleSize"], type = "range", order=11,width="full",
		step=.01,min = .01,max = 2,
		get = function(info) return SUI.DBMod.PartyFrames.scale; end,
		set = function(info,val)
			if (InCombatLockdown()) then SUI:Print(ERR_NOT_IN_COMBAT); else SUI.DBMod.PartyFrames.scale = val; PartyFrames:UpdateParty("FORCE_UPDATE"); end
		end
	};
end
