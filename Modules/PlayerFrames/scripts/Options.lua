local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
local Units = {[1]="player",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="pet"}
function addon:UpdateAura()
	for k,v in pairs(Units) do
		if addon[v].Auras then addon[v].Auras:PostUpdate(v); end
		if addon[v].Debuffs then addon[v].Debuffs:PostUpdate(v); end
	end
end

function addon:OnInitialize()
	spartan.opt.PlayerFrames.args["FrameStyle"] = {name=L["Frames/FrameStyle"],type="group",order=1,
		desc=L["Frames/BarOptDesc"],
		args = {
			toggle3DPortrait =  {name = L["Frames/Portrait3D"], type = "toggle", order=1,
				get = function(info) return DBMod.PlayerFrames.Portrait3D; end,
				set = function(info,val) DBMod.PlayerFrames.Portrait3D = val; end
			},
			toggleclassname =  {name = L["Frames/ClrNameClass"], type = "toggle", order=2,
				get = function(info) return DBMod.PlayerFrames.showClass; end,
				set = function(info,val) DBMod.PlayerFrames.showClass = val; end
			},
			targettargetStyle = {name=L["Frames/ToTFrameStyle"],type="select",order=3,
				values = {["large"]=L["Frames/LargeFrame"],["medium"]=L["Frames/HidePicture"],["small"]=L["Frames/NameHealthOnly"]},
				get = function(info) return DBMod.PlayerFrames.targettarget.style; end,
				set = function(info,val) DBMod.PlayerFrames.targettarget.style = val; end
			},
			targettargetinfo = {name=L["Frames/ReloadRequired"],type="description",order=4},

			bars = {name=L["Frames/BarOpt"],type="group",order=1,desc=L["Frames/BarOptDesc"],
				args = {
					bar1 = {name=L["Frames/HBarClr"],type="header",order=10},
					healthPlayerColor = {name=L["Frames/PlayerHClr"],type="select",order=11,
						values = {["reaction"]=L["Frames/Green"],["dynamic"]=L["Frames/TextStyle3"]},
						get = function(info) return DBMod.PlayerFrames.bars.player.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.player.color = val; addon.player:ColorUpdate("player") end
					},
					healthTargetColor = {name="Target Health Color",type="select",order=12,
						values = {["class"]=L["Frames/ClrByClass"],["dynamic"]=L["Frames/TextStyle3"],["reaction"]=L["Frames/ClrByReac"]},
						get = function(info) return DBMod.PlayerFrames.bars.target.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.target.color = val; addon.player:ColorUpdate("target") end
					},
					healthToTColor = {name="Target of Target Health Color",type="select",order=13,
						values = {["class"]=L["Frames/ClrByClass"],["dynamic"]=L["Frames/TextStyle3"],["reaction"]=L["Frames/ClrByReac"]},
						get = function(info) return DBMod.PlayerFrames.bars.targettarget.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.targettarget.color = val; addon.player:ColorUpdate("targettarget") end
					},
					healthPetColor = {name="Pet Health Color",type="select",order=14,
						values = {["class"]=L["Frames/ClrByClass"],["dynamic"]=L["Frames/TextStyle3"],["happiness"]="Happiness"},
						get = function(info) return DBMod.PlayerFrames.bars.pet.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.pet.color = val; addon.player:ColorUpdate("pet") end
					},
					healthFocusColor = {name="Focus Health Color",type="select",order=15,
						values = {["class"]=L["Frames/ClrByClass"],["dynamic"]=L["Frames/TextStyle3"],["reaction"]=L["Frames/ClrByReac"]},
						get = function(info) return DBMod.PlayerFrames.bars.focus.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.focus.color = val; addon.player:ColorUpdate("focus") end
					},
					healthFocusTargetColor = {name="Focus Target Health Color",type="select",order=16,
						values = {["class"]=L["Frames/ClrByClass"],["dynamic"]=L["Frames/TextStyle3"],["reaction"]=L["Frames/ClrByReac"]},
						get = function(info) return DBMod.PlayerFrames.bars.focustarget.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.focustarget.color = val; addon.player:ColorUpdate("focustarget") end
					},
					
					bar2 = {name=L["Frames/TextStyle"],type="header",order=20},
					healthtextstyle = {name=L["Frames/HTextStyle"],type="select",order=21,
						desc = "Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed",
						values = {["long"]=L["Frames/TextStyle1"],["longfor"]=L["Frames/TextStyle2"],["dynamic"]=L["Frames/TextStyle3"]},
						get = function(info) return DBMod.PlayerFrames.bars.health.textstyle; end,
						set = function(info,val) DBMod.PlayerFrames.bars.health.textstyle = val; for a,b in pairs(Units) do addon[b]:TextUpdate(b); end	end
					},
					healthtextmode = {name=L["Frames/HTextMode"],type="select",order=22,
						values = {[1]=L["Frames/HTextMode1"],[2]=L["Frames/HTextMode2"],[3]=L["Frames/HTextMode3"]},
						get = function(info) return DBMod.PlayerFrames.bars.health.textmode; end,
						set = function(info,val) DBMod.PlayerFrames.bars.health.textmode = val; for a,b in pairs(Units) do addon[b]:TextUpdate(b); end	end
					},
					manatextstyle = {name=L["Frames/MTextStyle"],type="select",order=23,
						desc = "Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed",
						values = {["long"]=L["Frames/TextStyle1"],["longfor"]=L["Frames/TextStyle2"],["dynamic"]=L["Frames/TextStyle3"]},
						get = function(info) return DBMod.PlayerFrames.bars.mana.textstyle; end,
						set = function(info,val) DBMod.PlayerFrames.bars.mana.textstyle = val; for a,b in pairs(Units) do addon[b]:TextUpdate(b); end	end
					},
					manatextmode = {name=L["Frames/MTextMode"],type="select",order=24,
						values = {[1]=L["Frames/HTextMode1"],[2]=L["Frames/HTextMode2"],[3]=L["Frames/HTextMode3"]},
						get = function(info) return DBMod.PlayerFrames.bars.mana.textmode; end,
						set = function(info,val) DBMod.PlayerFrames.bars.mana.textmode = val; for a,b in pairs(Units) do addon[b]:TextUpdate(b); end	end
					}
				}
			}
		}
	}
	spartan.opt.PlayerFrames.args["frameDisplay"] = {name = "Disable Frames",type = "group",order=2,desc="Enable and Disable Specific frames",
		args = {
			player = {name = L["Frames/DispPlayer"],type = "toggle",order=1,
				get = function(info) return DBMod.PlayerFrames.player.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.player.display = val;
					if DBMod.PlayerFrames.player.display then addon.player:Enable(); else addon.player:Disable(); end
				end
			},
			pet = {name = L["Frames/DispPet"],type = "toggle",order=2,
				get = function(info) return DBMod.PlayerFrames.pet.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.pet.display = val;
					if DBMod.PlayerFrames.pet.display then addon.pet:Enable(); else addon.pet:Disable(); end
				end
			},
			target = {name = L["Frames/DispTarget"],type = "toggle",order=3,
				get = function(info) return DBMod.PlayerFrames.target.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.target.display = val;
					if DBMod.PlayerFrames.target.display then addon.target:Enable(); else addon.target:Disable(); end
				end
			},
			targettarget = {name = L["Frames/DispToT"],type = "toggle",order=4,
				get = function(info) return DBMod.PlayerFrames.targettarget.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.targettarget.display = val;
					if DBMod.PlayerFrames.targettarget.display then addon.targettarget:Enable(); else addon.targettarget:Disable(); end
				end
			},
			focustarget = {name = L["Frames/DispFocusTar"],type = "toggle",order=5,
				get = function(info) return DBMod.PlayerFrames.focustarget.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.focustarget.display = val;
					if DBMod.PlayerFrames.focustarget.display then addon.focustarget:Enable(); else addon.focustarget:Disable(); end
				end
			}
		}
	}
	spartan.opt.PlayerFrames.args["auras"] = {name = "Buffs & Debuffs",type = "group",order=3,
		desc = "Buff & Debuff display settings",
		args = {
			header0 = {name="Buffs & DeBuffs to Display",type="header",order=0},
			dplayer = {name = L["Frames/Player"],type = "toggle",order=1,
				get = function(info) return DBMod.PlayerFrames.player.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.player.AuraDisplay = val; addon.player.Auras:PostUpdate("player"); end
			},
			dtarget = {name = L["Frames/Target"],type = "toggle",order=2,
				get = function(info) return DBMod.PlayerFrames.target.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.target.AuraDisplay = val; addon.target.Auras:PostUpdate("target"); end
			},
			dtargettarget = {name = L["Frames/TargetTarget"],type = "toggle",order=3,
				get = function(info) return DBMod.PlayerFrames.targettarget.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.targettarget.AuraDisplay = val; addon.targettarget.Auras:PostUpdate("targettarget"); end
			},
			dpet = {name = L["Frames/Pet"],type = "toggle",order=4,
				get = function(info) return DBMod.PlayerFrames.pet.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.pet.AuraDisplay = val; addon.pet.Auras:PostUpdate("pet"); end
			},
			dfocus = {name = L["Frames/Focus"],type = "toggle",order=5,
				get = function(info) return DBMod.PlayerFrames.focus.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.focus.AuraDisplay = val; addon.focus.Auras:PostUpdate("focus"); end
			},
			dfocustarget = {name = L["Frames/FocusTarget"],type = "toggle",order=6,
				get = function(info) return DBMod.PlayerFrames.focustarget.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.focustarget.AuraDisplay = val; addon.focustarget.Auras:PostUpdate("focustarget"); end
			},
			
			header2 = {name="Buff & Debuff Display Settings",type="header",order=20},
			TargetAuras = {name="Target display style",type="select",order=22,
				values = {["all"]="Display All",["self"]="Applied by you"},
				get = function(info) return DBMod.PlayerFrames.target.Debuffs end,
				set = function(info,val) DBMod.PlayerFrames.target.Debuffs = val; if DBMod.PlayerFrames.target.Debuffs then addon.target.Auras.onlyShowPlayer = true; else DBMod.PlayerFrames.target.Debuffs = false; end end
			},

			global = {name=L["Frames/Global"],type="group",order=1,
				args = {
					showType = {name=L["Frames/ShowType"],type="toggle", order=2,
						get = function(info) return DBMod.PlayerFrames.global.Auras.showType; end,
						set = function(info,val) DBMod.PlayerFrames.global.Auras.showType = val; addon:UpdateAura(); end
					},
					onlyShowPlayer = {name=L["Frames/OnlyYourBuffDebuff"],type="toggle", order=3,
						get = function(info) return DBMod.PlayerFrames.global.Auras.onlyShowPlayer; end,
						set = function(info,val) DBMod.PlayerFrames.global.Auras.onlyShowPlayer = val; addon:UpdateAura(); end
					},
					numBufs = {name=L["Frames/NumBuffs"],type="range",width="full",order=11,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.global.Auras.NumBuffs; end,
						set = function(info,val) DBMod.PlayerFrames.global.Auras.NumBuffs = val; addon:UpdateAura(); end
					},
					numDebuffs = {name=L["Frames/NumDebuff"],type="range",width="full",order=12,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.global.Auras.NumDebuffs; end,
						set = function(info,val) DBMod.PlayerFrames.global.Auras.NumDebuffs = val; addon:UpdateAura(); end
					},
					size = {name=L["Frames/SizeBuff"],type="range",width="full",order=13,
						min=0,max=60,step=1,
						get = function(info) return DBMod.PlayerFrames.global.Auras.size; end,
						set = function(info,val) DBMod.PlayerFrames.global.Auras.size = val; addon:UpdateAura(); end
					},
					sizedesc={name=L["Frames/sizedesc"],type="description",order=13.5},
					spacing = {name=L["Frames/SpacingBuffDebuffs"],type="range",width="full",order=14,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.global.Auras.spacing; end,
						set = function(info,val) DBMod.PlayerFrames.global.Auras.spacing = val; addon:UpdateAura(); end
					},

					line1 = {name="",type="header",order=20},
					ApplyToPlayer = {name = L["Frames/ApplyPlayer"], type="execute", order = 21,
						func = function() DBMod.PlayerFrames.player.Auras = DBMod.PlayerFrames.global.Auras; addon:UpdateAura(); end
					},
					ApplyTotarget = {name = L["Frames/ApplyTarget"], type="execute", order = 22,
						func = function() DBMod.PlayerFrames.target.Auras = DBMod.PlayerFrames.global.Auras; addon:UpdateAura(); end
					},
					ApplyTotargettarget = {name = L["Frames/ApplyToT"], type="execute", order = 23,
						func = function() DBMod.PlayerFrames.targettarget.Auras = DBMod.PlayerFrames.global.Auras; addon:UpdateAura(); end
					},
					ApplyTopet = {name = L["Frames/ApplyPet"], type="execute", order = 24,
						func = function() DBMod.PlayerFrames.pet.Auras = DBMod.PlayerFrames.global.Auras; addon:UpdateAura(); end
					},
					ApplyTofocus = {name = L["Frames/ApplyFocus"], type="execute", order = 25,
						func = function() DBMod.PlayerFrames.focus.Auras = DBMod.PlayerFrames.global.Auras; addon:UpdateAura(); end
					},
					ApplyTofocustarget = {name = L["Frames/ApplyFocusTar"], type="execute", order = 26,
						func = function() DBMod.PlayerFrames.focustarget.Auras = DBMod.PlayerFrames.global.Auras; addon:UpdateAura(); end
					},
					ApplyToAll = {name = L["Frames/ApplyGlobAll"], type="execute", order = 28,width="double",
						func = function()
							for k,v in pairs(Units) do DBMod.PlayerFrames[v].Auras = DBMod.PlayerFrames.global.Auras; end
							addon:UpdateAura();
						end
					},
				}
			},
			player = {name=L["Frames/Player"],type="group",order=1,
				args = {
					showType = {name=L["Frames/ShowType"],type="toggle", order=2,
						get = function(info) return DBMod.PlayerFrames.player.Auras.showType; end,
						set = function(info,val) DBMod.PlayerFrames.player.Auras.showType = val; addon:UpdateAura(); end
					},
					numDebuffs = {name=L["Frames/NumDebuff"],type="range",width="full",order=12,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.player.Auras.NumDebuffs; end,
						set = function(info,val) DBMod.PlayerFrames.player.Auras.NumDebuffs = val; addon:UpdateAura(); end
					},
					size = {name=L["Frames/SizeBuff"],type="range",width="full",order=13,
						min=0,max=60,step=1,
						get = function(info) return DBMod.PlayerFrames.player.Auras.size; end,
						set = function(info,val) DBMod.PlayerFrames.player.Auras.size = val; addon:UpdateAura(); end
					},
					spacing = {name=L["Frames/SpacingBuffDebuffs"],type="range",width="full",order=14,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.player.Auras.spacing; end,
						set = function(info,val) DBMod.PlayerFrames.player.Auras.spacing = val; addon:UpdateAura(); end
					},
				}
			},
			target = {name=L["Frames/Target"],type="group",order=2,
				args = {
					showType = {name=L["Frames/ShowType"],type="toggle", order=2,
						get = function(info) return DBMod.PlayerFrames.target.Auras.showType; end,
						set = function(info,val) DBMod.PlayerFrames.target.Auras.showType = val; addon:UpdateAura(); end
					},
					onlyShowPlayer = {name=L["Frames/OnlyYourBuffDebuff"],type="toggle", order=3,
						get = function(info) return DBMod.PlayerFrames.target.Auras.onlyShowPlayer; end,
						set = function(info,val) DBMod.PlayerFrames.target.Auras.onlyShowPlayer = val; addon:UpdateAura(); end
					},
					numBufs = {name=L["Frames/NumBuffs"],type="range",width="full",order=11,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.target.Auras.NumBuffs; end,
						set = function(info,val) DBMod.PlayerFrames.target.Auras.NumBuffs = val; addon:UpdateAura(); end
					},
					numDebuffs = {name=L["Frames/NumDebuff"],type="range",width="full",order=12,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.target.Auras.NumDebuffs; end,
						set = function(info,val) DBMod.PlayerFrames.target.Auras.NumDebuffs = val; addon:UpdateAura(); end
					},
					size = {name=L["Frames/SizeBuff"],type="range",width="full",order=13,
						min=0,max=60,step=1,
						get = function(info) return DBMod.PlayerFrames.target.Auras.size; end,
						set = function(info,val) DBMod.PlayerFrames.target.Auras.size = val; addon:UpdateAura(); end
					},
					spacing = {name=L["Frames/SpacingBuffDebuffs"],type="range",width="full",order=14,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.target.Auras.spacing; end,
						set = function(info,val) DBMod.PlayerFrames.target.Auras.spacing = val; addon:UpdateAura(); end
					},
				}
			},
			targettarget = {name=L["Frames/TargetTarget"],type="group",order=3,
				args = {
					showType = {name=L["Frames/ShowType"],type="toggle", order=2,
						get = function(info) return DBMod.PlayerFrames.targettarget.Auras.showType; end,
						set = function(info,val) DBMod.PlayerFrames.targettarget.Auras.showType = val; addon:UpdateAura(); end
					},
					onlyShowPlayer = {name=L["Frames/OnlyYourBuffDebuff"],type="toggle", order=3,
						get = function(info) return DBMod.PlayerFrames.targettarget.Auras.onlyShowPlayer; end,
						set = function(info,val) DBMod.PlayerFrames.targettarget.Auras.onlyShowPlayer = val; addon:UpdateAura(); end
					},
					numBufs = {name=L["Frames/NumBuffs"],type="range",width="full",order=11,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.targettarget.Auras.NumBuffs; end,
						set = function(info,val) DBMod.PlayerFrames.targettarget.Auras.NumBuffs = val; addon:UpdateAura(); end
					},
					numDebuffs = {name=L["Frames/NumDebuff"],type="range",width="full",order=12,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.targettarget.Auras.NumDebuffs; end,
						set = function(info,val) DBMod.PlayerFrames.targettarget.Auras.NumDebuffs = val; addon:UpdateAura(); end
					},
					size = {name=L["Frames/SizeBuff"],type="range",width="full",order=13,
						min=0,max=60,step=1,
						get = function(info) return DBMod.PlayerFrames.targettarget.Auras.size; end,
						set = function(info,val) DBMod.PlayerFrames.targettarget.Auras.size = val; addon:UpdateAura(); end
					},
					spacing = {name=L["Frames/SpacingBuffDebuffs"],type="range",width="full",order=14,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.targettarget.Auras.spacing; end,
						set = function(info,val) DBMod.PlayerFrames.targettarget.Auras.spacing = val; addon:UpdateAura(); end
					},
				}
			},
			pet = {name=L["Frames/Pet"],type="group",order=4,
				args = {
					showType = {name=L["Frames/ShowType"],type="toggle", order=2,
						get = function(info) return DBMod.PlayerFrames.pet.Auras.showType; end,
						set = function(info,val) DBMod.PlayerFrames.pet.Auras.showType = val; addon:UpdateAura(); end
					},
					onlyShowPlayer = {name=L["Frames/OnlyYourBuffDebuff"],type="toggle", order=3,
						get = function(info) return DBMod.PlayerFrames.pet.Auras.onlyShowPlayer; end,
						set = function(info,val) DBMod.PlayerFrames.pet.Auras.onlyShowPlayer = val; addon:UpdateAura(); end
					},
					numBufs = {name=L["Frames/NumBuffs"],type="range",width="full",order=11,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.pet.Auras.NumBuffs; end,
						set = function(info,val) DBMod.PlayerFrames.pet.Auras.NumBuffs = val; addon:UpdateAura(); end
					},
					numDebuffs = {name=L["Frames/NumDebuff"],type="range",width="full",order=12,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.pet.Auras.NumDebuffs; end,
						set = function(info,val) DBMod.PlayerFrames.pet.Auras.NumDebuffs = val; addon:UpdateAura(); end
					},
					size = {name=L["Frames/SizeBuff"],type="range",width="full",order=13,
						min=0,max=60,step=1,
						get = function(info) return DBMod.PlayerFrames.pet.Auras.size; end,
						set = function(info,val) DBMod.PlayerFrames.pet.Auras.size = val; addon:UpdateAura(); end
					},
					spacing = {name=L["Frames/SpacingBuffDebuffs"],type="range",width="full",order=14,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.pet.Auras.spacing; end,
						set = function(info,val) DBMod.PlayerFrames.pet.Auras.spacing = val; addon:UpdateAura(); end
					},
				}
			},
			focus = {name=L["Frames/Focus"],type="group",order=5,
				args = {
					showType = {name=L["Frames/ShowType"],type="toggle", order=2,
						get = function(info) return DBMod.PlayerFrames.focus.Auras.showType; end,
						set = function(info,val) DBMod.PlayerFrames.focus.Auras.showType = val; addon:UpdateAura(); end
					},
					numBufs = {name=L["Frames/NumBuffs"],type="range",width="full",order=11,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.focus.Auras.NumBuffs; end,
						set = function(info,val) DBMod.PlayerFrames.focus.Auras.NumBuffs = val; addon:UpdateAura(); end
					},
					numDebuffs = {name=L["Frames/NumDebuff"],type="range",width="full",order=12,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.focus.Auras.NumDebuffs; end,
						set = function(info,val) DBMod.PlayerFrames.focus.Auras.NumDebuffs = val; addon:UpdateAura(); end
					},
					size = {name=L["Frames/SizeBuff"],type="range",width="full",order=13,
						min=0,max=60,step=1,
						get = function(info) return DBMod.PlayerFrames.focus.Auras.size; end,
						set = function(info,val) DBMod.PlayerFrames.focus.Auras.size = val; addon:UpdateAura(); end
					},
					spacing = {name=L["Frames/SpacingBuffDebuffs"],type="range",width="full",order=14,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.focus.Auras.spacing; end,
						set = function(info,val) DBMod.PlayerFrames.focus.Auras.spacing = val; addon:UpdateAura(); end
					},
					onlyShowPlayer = {name=L["Frames/OnlyYourBuffDebuff"],type="toggle", order=3,
						get = function(info) return DBMod.PlayerFrames.focus.Auras.onlyShowPlayer; end,
						set = function(info,val) DBMod.PlayerFrames.focus.Auras.onlyShowPlayer = val; addon:UpdateAura(); end
					},
				}
			},
			focustarget = {name=L["Frames/FocusTarget"],type="group",order=6,
				args = {
					showType = {name=L["Frames/ShowType"],type="toggle", order=2,
						get = function(info) return DBMod.PlayerFrames.focustarget.Auras.showType; end,
						set = function(info,val) DBMod.PlayerFrames.focustarget.Auras.showType = val; addon:UpdateAura(); end
					},
					numBufs = {name=L["Frames/NumBuffs"],type="range",width="full",order=11,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.focustarget.Auras.NumBuffs; end,
						set = function(info,val) DBMod.PlayerFrames.focustarget.Auras.NumBuffs = val; addon:UpdateAura(); end
					},
					numDebuffs = {name=L["Frames/NumDebuff"],type="range",width="full",order=12,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.focustarget.Auras.NumDebuffs; end,
						set = function(info,val) DBMod.PlayerFrames.focustarget.Auras.NumDebuffs = val; addon:UpdateAura(); end
					},
					size = {name=L["Frames/SizeBuff"],type="range",width="full",order=13,
						min=0,max=60,step=1,
						get = function(info) return DBMod.PlayerFrames.focustarget.Auras.size; end,
						set = function(info,val) DBMod.PlayerFrames.focustarget.Auras.size = val; addon:UpdateAura(); end
					},
					spacing = {name=L["Frames/SpacingBuffDebuffs"],type="range",width="full",order=14,
						min=0,max=50,step=1,
						get = function(info) return DBMod.PlayerFrames.focustarget.Auras.spacing; end,
						set = function(info,val) DBMod.PlayerFrames.focustarget.Auras.spacing = val; addon:UpdateAura(); end
					},
					onlyShowPlayer = {name=L["Frames/OnlyYourBuffDebuff"],type="toggle", order=3,
						get = function(info) return DBMod.PlayerFrames.focustarget.Auras.onlyShowPlayer; end,
						set = function(info,val) DBMod.PlayerFrames.focustarget.Auras.onlyShowPlayer = val; addon:UpdateAura(); end
					},
				}
			},
		}
	};
	spartan.opt.PlayerFrames.args["castbar"] = {name = L["Frames/castbar"],type = "group",order=4,
		desc = L["Frames/UnitCastSet"],
		args = {
			player = { name = L["Frames/PlayerStyle"], type = "select", style="radio",
				values = {[0]=L["Frames/FillLR"],[1]=L["Frames/DepRL"]},
				get = function(info) return DBMod.PlayerFrames.Castbar.player; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.player = val; end
			},
			target = { name = L["Frames/TargetStyle"], type = "select", style="radio",
				values = {[0]=L["Frames/FillLR"],[1]=L["Frames/DepRL"]},
				get = function(info) return DBMod.PlayerFrames.Castbar.target; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.target = val; end
			},
			targettarget = { name = L["Frames/ToTStyle"], type = "select", style="radio",
				values = {[0]=L["Frames/FillLR"],[1]=L["Frames/DepRL"]},
				get = function(info) return DBMod.PlayerFrames.Castbar.targettarget; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.targettarget = val; end
			},
			pet = { name = L["Frames/PetStyle"], type = "select", style="radio",
				values = {[0]=L["Frames/FillLR"],[1]=L["Frames/DepRL"]},
				get = function(info) return DBMod.PlayerFrames.Castbar.pet; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.pet = val; end
			},
			focus = { name = L["Frames/FocusStyle"], type = "select", style="radio",
				values = {[0]=L["Frames/FillLR"],[1]=L["Frames/DepRL"]},
				get = function(info) return DBMod.PlayerFrames.Castbar.focus; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.focus = val; end
			},
			text = {
				name = L["Frames/CastText"],
				desc = L["Frames/CastTextDesc"],
				type = "group", args = {
					player = {
						name = L["Frames/TextStyle"], type = "select", style="radio",
						values = {[0]=L["Frames/CountUp"],[1]=L["Frames/CountDown"]},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.player; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.player = val; end
					},
					target = {
						name = L["Frames/TextStyle"], type = "select", style="radio",
						values = {[0]=L["Frames/CountUp"],[1]=L["Frames/CountDown"]},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.target; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.target = val; end
					},
					targettarget = {
						name = L["Frames/TextStyle"], type = "select", style="radio",
						values = {[0]=L["Frames/CountUp"],[1]=L["Frames/CountDown"]},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.targettarget; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.targettarget = val; end
					},
					pet = {
						name = L["Frames/TextStyle"], type = "select", style="radio",
						values = {[0]=L["Frames/CountUp"],[1]=L["Frames/CountDown"]},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.pet; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.pet = val; end
					},
					focus = {
						name = L["Frames/TextStyle"], type = "select", style="radio",
						values = {[0]=L["Frames/CountUp"],[1]=L["Frames/CountDown"]},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.focus; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.focus = val; end
					}
				},
			},
		}
	};
	spartan.opt.PlayerFrames.args["bossarena"] = {name = L["Frames/BossArenaFrames"],type = "group",order=5,
		args = {
			bar0 = {name=L["Frames/BossFrames"],type="header",order=0},
			boss = { name = L["Frames/ShowFrames"], type = "toggle",order=1,--disabled=true,
				get = function(info) return DBMod.PlayerFrames.BossFrame.display; end,
				set = function(info,val) DBMod.PlayerFrames.BossFrame.display = val; end
			},
			bossreset = {name = L["Frames/ResetLoc"],type = "execute",order=2,--disabled=true,
				desc = L["Frames/ResetLocDesc"],
				func = function() DBMod.PlayerFrames.BossFrame.movement.moved = false; addon:UpdateBossFramePosition(); end
			},
			bossscale = { name = L["Frames/ScaleFrames"], type = "range",order=3,width="full",--disabled=true,
				min=.01,max=2,step=.01,
				get = function(info) return DBMod.PlayerFrames.BossFrame.scale; end,
				set = function(info,val) DBMod.PlayerFrames.BossFrame.scale = val; end
			},
			
			bar2 = {name=L["Frames/ArenaFrames"],type="header",order=20},
			arena = { name = L["Frames/ShowFrames"], type = "toggle",order=21,disabled=true,
				get = function(info) return DBMod.PlayerFrames.ArenaFrame.display; end,
				set = function(info,val) DBMod.PlayerFrames.ArenaFrame.display = val; end
			},
			arenareset = {name = L["Frames/ResetLoc"],type = "execute",order=22,disabled=true,
				desc = L["Frames/ResetLocDesc"],
				func = function() DBMod.PlayerFrames.ArenaFrame.moved = false; addon:UpdateArenaFramePosition(); end
			},
			arenascale = { name = L["Frames/ScaleFrames"], type = "range",order=23,width="full",disabled=true,
				min=.01,max=2,step=.01,
				get = function(info) return DBMod.PlayerFrames.ArenaFrame.scale; end,
				set = function(info,val) DBMod.PlayerFrames.ArenaFrame.scale = val; end
			},
		}
	};
	
	spartan.opt.PlayerFrames.args["UnitFrameMode"] = {name = "Unit Frame Mode",type="select",order=1,
		values = {["theme"]="Theme Frames",["classic"]="Classic Style",["plain"]="Minimal Frames"},
		get = function(info) return DBMod.PlayerFrames.style; end,
		set = function(info,val) DBMod.PlayerFrames.style = val; end
	};
	spartan.opt.PlayerFrames.args["resetfocus"] = {name = L["Frames/resetfocus"],type = "execute",order=2,
		desc = L["Frames/resetfocusDesc"],
		func = function() DBMod.PlayerFrames.focus.movement.moved = false; addon:UpdateFocusPosition(); end
	};
	spartan.opt.PlayerFrames.args["resetSpecialBar"] = {name = L["Frames/resetSpecialBar"],type = "execute",order=3,
		desc = L["Frames/resetSpecialBarDesc"],
		func = function() addon:ResetAltBarPositions(); end
	};
end

function addon:OnEnable()
	-- for k,v in pairs(Units) do if DBMod.PlayerFrames[v].AuraDisplay then
		-- if addon[v].Auras then addon[v].Auras:PostUpdate(v); end
		-- if addon[v].Debuffs then addon[v].Debuffs:PostUpdate(v); end
	-- end end
	-- for k,v in pairs(Units) do if DBMod.PlayerFrames[v].display then addon[v]:Enable(); else addon[v]:Disable(); end end
end