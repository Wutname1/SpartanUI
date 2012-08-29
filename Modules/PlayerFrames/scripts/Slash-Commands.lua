local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
suiChar.PlayerFrames = suiChar.PlayerFrames or {};
local default = {player = 0,target = 1,targettarget = 0,pet = 1,focus = 1};
for k,v in pairs(default) do if not suiChar.PlayerFrames[k] then suiChar.PlayerFrames[k] = v end end
setmetatable(suiChar.PlayerFrames,{__index = default});

suiChar.PlayerFrames.Castbar = suiChar.PlayerFrames.Castbar or {};
local castbardefault = { player = 1,target = 1,targettarget = 1,pet = 1,focus = 1, text = { player = 1,target = 1,targettarget = 1,pet = 1,focus = 1 } };
for k,v in pairs(castbardefault) do if not suiChar.PlayerFrames.Castbar[k] then suiChar.PlayerFrames.Castbar[k] = v end end
setmetatable(suiChar.PlayerFrames.Castbar,{__index = castbardefault});
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
					if suiChar.PlayerFrames.player == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						suiChar.PlayerFrames.player = 0;
					elseif (val == true) or (val == nil) then
						suiChar.PlayerFrames.player = 1;
					end
					addon.player.Auras:PostUpdate("player");
				end
			},
			target = {
				name = "Display target buffs",
				type = "toggle",
				get = function(info)
					if suiChar.PlayerFrames.target == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						suiChar.PlayerFrames.target = 0;
					else
						suiChar.PlayerFrames.target = 1;
					end
					addon.target.Auras:PostUpdate("target");
				end
			},
			targettarget = {
				name = "Display target of target buffs",
				type = "toggle",
				get = function(info)
					if suiChar.PlayerFrames.targettarget == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						suiChar.PlayerFrames.targettarget = 0;
					else
						suiChar.PlayerFrames.targettarget = 1;
					end
					addon.targettarget.Auras:PostUpdate("targettarget");
				end
			},
			pet = {
				name = "Display pet buffs",
				type = "toggle",
				get = function(info)
					if suiChar.PlayerFrames.pet == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						suiChar.PlayerFrames.pet = 0;
					else
						suiChar.PlayerFrames.pet = 1;
					end
					addon.pet.Auras:PostUpdate("pet");
				end
			},
			focus = {
				name = "Display focus buffs",
				type = "toggle",
				get = function(info)
					if suiChar.PlayerFrames.focus == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						suiChar.PlayerFrames.focus = 0;
					else
						suiChar.PlayerFrames.focus = 1;
					end
					addon.focus.Auras:PostUpdate("focus");
				end
			},
			focustarget = {
				name = "Display focus target buffs",
				type = "toggle",
				get = function(info)
					if suiChar.PlayerFrames.focustarget == 0 then return false else return true end
				end,
				set = function(info,val)
					if val == false then
						suiChar.PlayerFrames.focustarget = 0;
					else
						suiChar.PlayerFrames.focustarget = 1;
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
			player = {name = "toggle player castbar style", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.Castbar.player; end,
				set = function(info,val)
					if suiChar.PlayerFrames.Castbar.player == 0 then
						suiChar.PlayerFrames.Castbar.player = 1;
						spartan:Print("Player Castbar SpartanUI style");
					else
						suiChar.PlayerFrames.Castbar.player = 0;
						spartan:Print("Player Castbar oUF style");
					end
				end
			},
			target = {name = "toggle target castbar style", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.Castbar.target; end,
				set = function(info,val)
					if suiChar.PlayerFrames.Castbar.target == 0 then
						suiChar.PlayerFrames.Castbar.target = 1;
						spartan:Print("Target Castbar SpartanUI style");
					else
						suiChar.PlayerFrames.Castbar.target = 0;
						spartan:Print("Target Castbar oUF style");
					end
				end
			},
			targettarget = {name = "toggle targetargett castbar style", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.Castbar.targettarget; end,
				set = function(info,val)
					if suiChar.PlayerFrames.Castbar.targettarget == 0 then
						suiChar.PlayerFrames.Castbar.targettarget = 1;
						spartan:Print("Targettarget Castbar SpartanUI style");
					else
						suiChar.PlayerFrames.Castbar.targettarget = 0;
						spartan:Print("Targettarget Castbar oUF style");
					end
				end
			},
			pet = {name = "toggle pet castbar style", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.Castbar.pet; end,
				set = function(info,val)
					if suiChar.PlayerFrames.Castbar.pet == 0 then
						suiChar.PlayerFrames.Castbar.pet = 1;
						spartan:Print("Pet Castbar SpartanUI style");
					else
						suiChar.PlayerFrames.Castbar.pet = 0;
						spartan:Print("Pet Castbar oUF style");
					end
				end
			},
			focus = {name = "toggle focus castbar style", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.Castbar.focus; end,
				set = function(info,val)
					if suiChar.PlayerFrames.Castbar.focus == 0 then
						suiChar.PlayerFrames.Castbar.focus = 1;
						spartan:Print("Focus Castbar SpartanUI style");
					else
						suiChar.PlayerFrames.Castbar.focus = 0;
						spartan:Print("Focus Castbar oUF style");
					end
				end
			},
			text = {
				name = "Unitframe Castbar Text",
				desc = "unitframe castbar text settings",
				type = "group", args = {
					player = {name = "toggle player castbar text style", type = "toggle",
						get = function(info) return suiChar.PlayerFrames.Castbar.text.player; end,
						set = function(info,val)
							if suiChar.PlayerFrames.Castbar.text.player == 0 then
								suiChar.PlayerFrames.Castbar.text.player = 1;
								spartan:Print("Player Castbar Text SpartanUI style");
							else
								suiChar.PlayerFrames.Castbar.text.player = 0;
								spartan:Print("Player Castbar Text oUF style");
							end
						end
					},
					target = {name = "toggle target castbar text style", type = "toggle",
						get = function(info) return suiChar.PlayerFrames.Castbar.text.target; end,
						set = function(info,val)
							if suiChar.PlayerFrames.Castbar.text.target == 0 then
								suiChar.PlayerFrames.Castbar.text.target = 1;
								spartan:Print("Target Castbar Text SpartanUI style");
							else
								suiChar.PlayerFrames.Castbar.text.target = 0;
								spartan:Print("Target Castbar Text oUF style");
							end
						end
					},
					targettarget = {name = "toggle targetargett castbar text style", type = "toggle",
						get = function(info) return suiChar.PlayerFrames.Castbar.text.targettarget; end,
						set = function(info,val)
							if suiChar.PlayerFrames.Castbar.text.targettarget == 0 then
								suiChar.PlayerFrames.Castbar.text.targettarget = 1;
								spartan:Print("Targettarget Castbar Text SpartanUI style");
							else
								suiChar.PlayerFrames.Castbar.text.targettarget = 0;
								spartan:Print("Targettarget Castbar Text oUF style");
							end
						end
					},
					pet = {name = "toggle pet castbar text style", type = "toggle",
						get = function(info) return suiChar.PlayerFrames.text.Castbar.pet; end,
						set = function(info,val)
							if suiChar.PlayerFrames.Castbar.text.pet == 0 then
								suiChar.PlayerFrames.Castbar.text.pet = 1;
								spartan:Print("Pet Castbar Text SpartanUI style");
							else
								suiChar.PlayerFrames.Castbar.text.pet = 0;
								spartan:Print("Pet Castbar Text oUF style");
							end
						end
					},
					focus = {name = "toggle focus castbar text style", type = "toggle",
						get = function(info) return suiChar.PlayerFrames.Castbar.text.focus; end,
						set = function(info,val)
							if suiChar.PlayerFrames.Castbar.text.focus == 0 then
								suiChar.PlayerFrames.Castbar.text.focus = 1;
								spartan:Print("Focus Castbar Text SpartanUI style");
							else
								suiChar.PlayerFrames.Castbar.text.focus = 0;
								spartan:Print("Focus Castbar Text oUF style");
							end
						end
					},
				},
			},
		}
	};
	spartan.optionsPlayerFrames.args["resetfocus"] = {
		type = "execute", name = "Reset Focus location",
		desc = "resets the potion to default",
		func = function()
			suiChar.PlayerFrames.focusMoved = false;
			addon:UpdateFocusPosition();
		end
	};
end

function addon:OnEnable()
	for k,v in pairs(default) do addon[k].Auras:PostUpdate(k); end
end