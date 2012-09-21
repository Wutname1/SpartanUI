local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
local default = {player = 0,target = 1,targettarget = 0,pet = 1,focus = 0,focustarget=0};
setmetatable(DBMod.PlayerFrames,{__index = default});

DBMod.PlayerFrames.Castbar = DBMod.PlayerFrames.Castbar or {};
local Units = {[1]="player",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="pet"}
local castbardefault = { player = 1,target = 1,targettarget = 1,pet = 1,focus = 1, text = { player = 1,target = 1,targettarget = 1,pet = 1,focus = 1 } };
for k,v in pairs(castbardefault) do if not DBMod.PlayerFrames.Castbar[k] then DBMod.PlayerFrames.Castbar[k] = v end end
setmetatable(DBMod.PlayerFrames.Castbar,{__index = castbardefault});
-- /spartanui castbar player

function addon:OnInitialize()
	spartan.optionsPlayerFrames.args["FrameStyle"] = {name="Frame Style",type="group",order=1,
		desc="Customize health and mana bar display",
		args = {
			targettargetStyle = {name="Target of Target Frame Style",type="select",order=11,
				values = {["large"]="Large Frame",["medium"]="Hide Picture",["small"]="Name & Health Only"},
				get = function(info) return DBMod.PlayerFrames.targettarget.style; end,
				set = function(info,val) DBMod.PlayerFrames.targettarget.style = val; end
			},
			targettargetinfo = {name="Reload UI Required.",type="description",order=12},

			bars = {name="Bar Options",type="group",order=1,desc="Customize health and mana bar display",
				args = {
					bar1 = {name="Health bar color",type="header",order=10},
					healthPlayerColor = {name="Player Health Color",type="select",order=11,
						values = {["reaction"]="Green",["dynamic"]="Dynamic"},
						get = function(info) return DBMod.PlayerFrames.bars.player.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.player.color = val; addon.player:ColorUpdate("player") end
					},
					healthTargetColor = {name="Target Health Color",type="select",order=12,
						values = {["class"]="Class",["dynamic"]="Dynamic",["reaction"]="Reaction"},
						get = function(info) return DBMod.PlayerFrames.bars.target.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.target.color = val; addon.player:ColorUpdate("target") end
					},
					healthToTColor = {name="Target of Target Health Color",type="select",order=13,
						values = {["class"]="Class",["dynamic"]="Dynamic",["reaction"]="Reaction"},
						get = function(info) return DBMod.PlayerFrames.bars.targettarget.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.targettarget.color = val; addon.player:ColorUpdate("targettarget") end
					},
					healthPetColor = {name="Pet Health Color",type="select",order=14,
						values = {["class"]="class",["dynamic"]="Dynamic",["happiness"]="Happiness"},
						get = function(info) return DBMod.PlayerFrames.bars.pet.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.pet.color = val; addon.player:ColorUpdate("pet") end
					},
					healthFocusColor = {name="Focus Health Color",type="select",order=15,
						values = {["class"]="Class",["dynamic"]="Dynamic",["reaction"]="Reaction"},
						get = function(info) return DBMod.PlayerFrames.bars.focus.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.focus.color = val; addon.player:ColorUpdate("focus") end
					},
					healthFocusTargetColor = {name="Focus Target Health Color",type="select",order=16,
						values = {["class"]="Class",["dynamic"]="Dynamic",["reaction"]="Reaction"},
						get = function(info) return DBMod.PlayerFrames.bars.focustarget.color; end,
						set = function(info,val) DBMod.PlayerFrames.bars.focustarget.color = val; addon.player:ColorUpdate("focustarget") end
					},
					
					bar2 = {name="Text style",type="header",order=20},
					healthtextstyle = {name="Health Text style",type="select",order=21,
						desc = "Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed",
						values = {["long"]="Long",["longfor"]="Long Formatted",["dynamic"]="Dynamic"},
						get = function(info) return DBMod.PlayerFrames.bars.health.textstyle; end,
						set = function(info,val) DBMod.PlayerFrames.bars.health.textstyle = val; for a,b in pairs(Units) do addon[b]:TextUpdate(b); end	end
					},
					healthtextmode = {name="Health Text mode",type="select",order=22,
						values = {[1]="Avaliable / Total",[2]="(Missing) Avaliable / Total",[3]="(Missing) Avaliable"},
						get = function(info) return DBMod.PlayerFrames.bars.health.textmode; end,
						set = function(info,val) DBMod.PlayerFrames.bars.health.textmode = val; for a,b in pairs(Units) do addon[b]:TextUpdate(b); end	end
					},
					manatextstyle = {name="Mana Text style",type="select",order=23,
						desc = "Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed",
						values = {["long"]="Long",["longfor"]="Long Formatted",["dynamic"]="Dynamic"},
						get = function(info) return DBMod.PlayerFrames.bars.mana.textstyle; end,
						set = function(info,val) DBMod.PlayerFrames.bars.mana.textstyle = val; for a,b in pairs(Units) do addon[b]:TextUpdate(b); end	end
					},
					manatextmode = {name="Mana Text mode",type="select",order=24,
						values = {[1]="Avaliable / Total",[2]="(Missing) Avaliable / Total",[3]="(Missing) Avaliable"},
						get = function(info) return DBMod.PlayerFrames.bars.mana.textmode; end,
						set = function(info,val) DBMod.PlayerFrames.bars.mana.textmode = val; for a,b in pairs(Units) do addon[b]:TextUpdate(b); end	end
					}
				}
			}
		}
	}
	spartan.optionsPlayerFrames.args["frameDisplay"] = {name = "Disable Frames",type = "group",order=2,desc="Enable and Disable Specific frames",
		desc = "unitframe display settings",
		args = {
			player = {name = "Display player",type = "toggle",order=1,
				get = function(info) return DBMod.PlayerFrames.player.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.player.display = val;
					if DBMod.PlayerFrames.player.display then addon.player:Enable(); else addon.player:Disable(); end
				end
			},
			pet = {name = "Display pet",type = "toggle",order=2,
				get = function(info) return DBMod.PlayerFrames.pet.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.pet.display = val;
					if DBMod.PlayerFrames.pet.display then addon.pet:Enable(); else addon.pet:Disable(); end
				end
			},
			target = {name = "Display Target",type = "toggle",order=3,
				get = function(info) return DBMod.PlayerFrames.target.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.target.display = val;
					if DBMod.PlayerFrames.target.display then addon.target:Enable(); else addon.target:Disable(); end
				end
			},
			targettarget = {name = "Display Target of Target",type = "toggle",order=4,
				get = function(info) return DBMod.PlayerFrames.targettarget.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.targettarget.display = val;
					if DBMod.PlayerFrames.targettarget.display then addon.targettarget:Enable(); else addon.targettarget:Disable(); end
				end
			},
			focustarget = {name = "Display focus target",type = "toggle",order=5,
				get = function(info) return DBMod.PlayerFrames.focustarget.display; end,
				set = function(info,val)
					DBMod.PlayerFrames.focustarget.display = val;
					if DBMod.PlayerFrames.focustarget.display then addon.focustarget:Enable(); else addon.focustarget:Disable(); end
				end
			}
		}
	}
	spartan.optionsPlayerFrames.args["auras"] = {name = "Buffs & Debuffs",type = "group",order=3,
		desc = "Buff & Debuff display settings",
		args = {
			player = {name = "Display player buffs",type = "toggle",order=1,
				get = function(info) return DBMod.PlayerFrames.player.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.player.AuraDisplay = val; addon.player.Auras:PostUpdate("player"); end
			},
			target = {name = "Display target buffs",type = "toggle",order=2,
				get = function(info) return DBMod.PlayerFrames.target.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.target.AuraDisplay = val; addon.target.Auras:PostUpdate("target"); end
			},
			targettarget = {name = "Display target of target buffs",type = "toggle",order=3,
				get = function(info) return DBMod.PlayerFrames.targettarget.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.targettarget.AuraDisplay = val; addon.targettarget.Auras:PostUpdate("targettarget"); end
			},
			pet = {name = "Display pet buffs",type = "toggle",order=4,
				get = function(info) return DBMod.PlayerFrames.pet.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.pet.AuraDisplay = val; addon.pet.Auras:PostUpdate("pet"); end
			},
			focus = {name = "Display focus buffs",type = "toggle",order=5,
				get = function(info) return DBMod.PlayerFrames.focus.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.focus.AuraDisplay = val; addon.focus.Auras:PostUpdate("focus"); end
			},
			focustarget = {name = "Display focus target buffs",type = "toggle",order=6,
				get = function(info) return DBMod.PlayerFrames.focustarget.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.focustarget.AuraDisplay = val; addon.focustarget.Auras:PostUpdate("focustarget"); end
			},
			header2 = {name="Buff & Debuff Display Settings",type="header",order=20},
			header3 = {name="This will be expanded more in 3.1.0",type="header",order=20.1},
			TargetAuras = {name="Target display style",type="select",order=22,
				values = {["all"]="Display All",["self"]="Applied by you"},
				get = function(info) return DBMod.PlayerFrames.target.Debuffs end,
				set = function(info,val) DBMod.PlayerFrames.target.Debuffs = val; if DBMod.PlayerFrames.target.Debuffs then addon.target.Auras.onlyShowPlayer = true; else DBMod.PlayerFrames.target.Debuffs = false; end end
			}
		}
	};
	spartan.optionsPlayerFrames.args["castbar"] = {name = "Castbar",type = "group",order=4,
		desc = "unitframe castbar settings",
		args = {
			player = { name = "Player style", type = "select", style="radio",
				values = {[0]="Fill left to right",[1]="Deplete Right to Left"},
				get = function(info) return DBMod.PlayerFrames.Castbar.player; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.player = val; end
			},
			target = { name = "Target style", type = "select", style="radio",
				values = {[0]="Fill left to right",[1]="Deplete Right to Left"},
				get = function(info) return DBMod.PlayerFrames.Castbar.target; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.target = val; end
			},
			targettarget = { name = "Target of Target style", type = "select", style="radio",
				values = {[0]="Fill left to right",[1]="Deplete Right to Left"},
				get = function(info) return DBMod.PlayerFrames.Castbar.targettarget; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.targettarget = val; end
			},
			pet = { name = "Pet style", type = "select", style="radio",
				values = {[0]="Fill left to right",[1]="Deplete Right to Left"},
				get = function(info) return DBMod.PlayerFrames.Castbar.pet; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.pet = val; end
			},
			focus = { name = "Focus style", type = "select", style="radio",
				values = {[0]="Fill left to right",[1]="Deplete Right to Left"},
				get = function(info) return DBMod.PlayerFrames.Castbar.focus; end,
				set = function(info,val) DBMod.PlayerFrames.Castbar.focus = val; end
			},
			text = {
				name = "Castbar Text",
				desc = "Castbar text settings",
				type = "group", args = {
					player = {
						name = "Text style", type = "select", style="radio",
						values = {[0]="Count up",[1]="Count down"},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.player; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.player = val; end
					},
					target = {
						name = "Text style", type = "select", style="radio",
						values = {[0]="Count up",[1]="Count down"},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.target; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.target = val; end
					},
					targettarget = {
						name = "Text style", type = "select", style="radio",
						values = {[0]="Count up",[1]="Count down"},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.targettarget; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.targettarget = val; end
					},
					pet = {
						name = "Text style", type = "select", style="radio",
						values = {[0]="Count up",[1]="Count down"},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.pet; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.pet = val; end
					},
					focus = {
						name = "Text style", type = "select", style="radio",
						values = {[0]="Count up",[1]="Count down"},
						get = function(info) return DBMod.PlayerFrames.Castbar.text.focus; end,
						set = function(info,val) DBMod.PlayerFrames.Castbar.text.focus = val; end
					}
				},
			},
		}
	};
	spartan.optionsPlayerFrames.args["bossarena"] = {name = "Boss & Arena frames",type = "group",order=5,
		args = {
			boss = { name = "Show Boss Frames", type = "toggle",order=1,disabled=true,
				get = function(info) return DBMod.PlayerFrames.BossFrame.display; end,
				set = function(info,val) DBMod.PlayerFrames.BossFrame.display = val; end
			},
			arena = { name = "Show Arena Frames", type = "toggle",order=20,disabled=true,
				get = function(info) return DBMod.PlayerFrames.ArenaFrame.display; end,
				set = function(info,val) DBMod.PlayerFrames.ArenaFrame.display = val; end
			},
		}
	};
	
	spartan.optionsPlayerFrames.args["resetfocus"] = {name = "Reset Focus location",type = "execute",order=1,
		desc = "resets the potion to default",
		func = function()
			DBMod.PlayerFrames.focus.moved = false;
			addon:UpdateFocusPosition();
		end
	};
end

function addon:OnEnable()
	for k,v in pairs(default) do if DBMod.PlayerFrames[k].AuraDisplay then addon[k].Auras:PostUpdate(k); end end
	for k,v in pairs(default) do if DBMod.PlayerFrames[k].display then addon[k]:Enable(); else addon[k]:Disable(); end end
end