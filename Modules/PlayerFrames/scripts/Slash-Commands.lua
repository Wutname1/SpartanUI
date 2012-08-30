local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
local default = {player = 0,target = 1,targettarget = 0,pet = 1,focus = 1};
for k,v in pairs(default) do if not DBMod.PlayerFrames[k] then DBMod.PlayerFrames[k] = v end end
setmetatable(DBMod.PlayerFrames,{__index = default});

DBMod.PlayerFrames.Castbar = DBMod.PlayerFrames.Castbar or {};
local castbardefault = { player = 1,target = 1,targettarget = 1,pet = 1,focus = 1, text = { player = 1,target = 1,targettarget = 1,pet = 1,focus = 1 } };
for k,v in pairs(castbardefault) do if not DBMod.PlayerFrames.Castbar[k] then DBMod.PlayerFrames.Castbar[k] = v end end
setmetatable(DBMod.PlayerFrames.Castbar,{__index = castbardefault});
-- /spartanui castbar player

function addon:OnInitialize()
	spartan.optionsPlayerFrames.args["auras"] = {
		name = "Unitframe Buffs & Debuffs",
		desc = "Buff & Debuff display settings",
		type = "group", args = {
			player = {
				name = "Display player buffs",
				type = "toggle",
				get = function(info)
					if DBMod.PlayerFrames.player == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						DBMod.PlayerFrames.player = 0;
					elseif (val == true) or (val == nil) then
						DBMod.PlayerFrames.player = 1;
					end
					addon.player.Auras:PostUpdate("player");
				end
			},
			target = {
				name = "Display target buffs",
				type = "toggle",
				get = function(info)
					if DBMod.PlayerFrames.target == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						DBMod.PlayerFrames.target = 0;
					else
						DBMod.PlayerFrames.target = 1;
					end
					addon.target.Auras:PostUpdate("target");
				end
			},
			targettarget = {
				name = "Display target of target buffs",
				type = "toggle",
				get = function(info)
					if DBMod.PlayerFrames.targettarget == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						DBMod.PlayerFrames.targettarget = 0;
					else
						DBMod.PlayerFrames.targettarget = 1;
					end
					addon.targettarget.Auras:PostUpdate("targettarget");
				end
			},
			pet = {
				name = "Display pet buffs",
				type = "toggle",
				get = function(info)
					if DBMod.PlayerFrames.pet == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						DBMod.PlayerFrames.pet = 0;
					else
						DBMod.PlayerFrames.pet = 1;
					end
					addon.pet.Auras:PostUpdate("pet");
				end
			},
			focus = {
				name = "Display focus buffs",
				type = "toggle",
				get = function(info)
					if DBMod.PlayerFrames.focus == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						DBMod.PlayerFrames.focus = 0;
					else
						DBMod.PlayerFrames.focus = 1;
					end
					addon.focus.Auras:PostUpdate("focus");
				end
			},
			focustarget = {
				name = "Display focus target buffs",
				type = "toggle",
				get = function(info)
					if DBMod.PlayerFrames.focustarget == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						DBMod.PlayerFrames.focustarget = 0;
					else
						DBMod.PlayerFrames.focustarget = 1;
					end
					addon.focustarget.Auras:PostUpdate("focustarget");
				end
			}
		}
	};
	spartan.optionsPlayerFrames.args["castbar"] = {
		name = "Unitframe Castbar",
		desc = "unitframe castbar settings",
		type = "group", args = {
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
	spartan.optionsPlayerFrames.args["resetfocus"] = {
		type = "execute", name = "Reset Focus location",
		desc = "resets the potion to default",
		func = function()
			DBMod.PlayerFrames.focusMoved = false;
			addon:UpdateFocusPosition();
		end
	};
end

function addon:OnEnable()
	for k,v in pairs(default) do addon[k].Auras:PostUpdate(k); end
end