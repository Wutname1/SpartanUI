local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
local default = {player = 0,target = 1,targettarget = 0,pet = 1,focus = 0,focustarget=0};
setmetatable(DBMod.PlayerFrames,{__index = default});

DBMod.PlayerFrames.Castbar = DBMod.PlayerFrames.Castbar or {};
local castbardefault = { player = 1,target = 1,targettarget = 1,pet = 1,focus = 1, text = { player = 1,target = 1,targettarget = 1,pet = 1,focus = 1 } };
for k,v in pairs(castbardefault) do if not DBMod.PlayerFrames.Castbar[k] then DBMod.PlayerFrames.Castbar[k] = v end end
setmetatable(DBMod.PlayerFrames.Castbar,{__index = castbardefault});
-- /spartanui castbar player

function addon:OnInitialize()
	spartan.optionsPlayerFrames.args["frameDisplay"] = {name = "Unitframe Display",type = "group",order=1,
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
	spartan.optionsPlayerFrames.args["auras"] = {name = "Unitframe Buffs & Debuffs",type = "group",order=2,
		desc = "Buff & Debuff display settings",
		args = {
			player = {
				name = "Display player buffs",
				type = "toggle",
				get = function(info) return DBMod.PlayerFrames.player.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.player.AuraDisplay = val; addon.player.Auras:PostUpdate("player"); end
			},
			target = {
				name = "Display target buffs",
				type = "toggle",
				get = function(info) return DBMod.PlayerFrames.target.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.target.AuraDisplay = val; addon.target.Auras:PostUpdate("target"); end
			},
			targettarget = {
				name = "Display target of target buffs",
				type = "toggle",
				get = function(info) return DBMod.PlayerFrames.targettarget.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.targettarget.AuraDisplay = val; addon.targettarget.Auras:PostUpdate("targettarget"); end
			},
			pet = {
				name = "Display pet buffs",
				type = "toggle",
				get = function(info) return DBMod.PlayerFrames.pet.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.pet.AuraDisplay = val; addon.pet.Auras:PostUpdate("pet"); end
			},
			focus = {
				name = "Display focus buffs",
				type = "toggle",
				get = function(info) return DBMod.PlayerFrames.focus.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.focus.AuraDisplay = val; addon.focus.Auras:PostUpdate("focus"); end
			},
			focustarget = {
				name = "Display focus target buffs",
				type = "toggle",
				get = function(info) return DBMod.PlayerFrames.focustarget.AuraDisplay end,
				set = function(info,val) DBMod.PlayerFrames.focustarget.AuraDisplay = val; addon.focustarget.Auras:PostUpdate("focustarget"); end
			}
		}
	};
	spartan.optionsPlayerFrames.args["castbar"] = {name = "Unitframe Castbar",type = "group",order=3,
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
				name = "Unitframe Castbar Text",
				desc = "unitframe castbar text settings",
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
	
	spartan.optionsPlayerFrames.args["resetfocus"] = {name = "Reset Focus location",type = "execute",order=1,
		desc = "resets the potion to default",
		func = function()
			DBMod.PlayerFrames.focusMoved = false;
			addon:UpdateFocusPosition();
		end
	};
end

function addon:OnEnable()
	for k,v in pairs(default) do if DBMod.PlayerFrames[k].AuraDisplay then addon[k].Auras:PostUpdate(k); end end
	for k,v in pairs(default) do if DBMod.PlayerFrames[k].display then addon[k]:Enable(); else addon[k]:Disable(); end end
end