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
	spartan.options.args["auras"] = {
		name = "Unitframe Auras",
		desc = "unitframe aura settings",
		type = "group", args = {
			player = {name = "toggle player auras", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.player; end,
				set = function(info,val)
					if suiChar.PlayerFrames.player == 0 then
						suiChar.PlayerFrames.player = 1;
						spartan:Print("Player Auras Enabled. Default buffs are NOT disabled with this command. You will need a third-party addon such as HideBlizzard to hide them");
					else
						suiChar.PlayerFrames.player = 0;
						spartan:Print("Player Auras Disabled");
					end
					addon.player.Auras:PostUpdate("player");
				end
			},
			target = {name = "toggle target auras", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.target; end,
				set = function(info,val)
					if suiChar.PlayerFrames.target == 0 then
						suiChar.PlayerFrames.target = 1;
						spartan:Print("Target Auras Enabled");
					else
						suiChar.PlayerFrames.target = 0;
						spartan:Print("Target Auras Disabled");
					end
					addon.target.Auras:PostUpdate("target");
				end
			},
			targettarget = {name = "toggle target of target auras", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.targettarget; end,
				set = function(info,val)
					if suiChar.PlayerFrames.targettarget == 0 then
						suiChar.PlayerFrames.targettarget = 1;
						spartan:Print("Target of Target Auras Enabled");
					else
						suiChar.PlayerFrames.targettarget = 0;
						spartan:Print("Target of Target Auras Disabled");
					end
					addon.targettarget.Auras:PostUpdate("targettarget");
				end
			},
			pet = {name = "toggle pet auras", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.pet; end,
				set = function(info,val)
					if suiChar.PlayerFrames.pet == 0 then
						suiChar.PlayerFrames.pet = 1;
						spartan:Print("Pet Auras Enabled");
					else
						suiChar.PlayerFrames.pet = 0;
						spartan:Print("Pet Auras Disabled");
					end
					addon.pet.Auras:PostUpdate("pet");
				end
			},
			focus = {name = "toggle focus auras", type = "toggle",
				get = function(info) return suiChar.PlayerFrames.focus; end,
				set = function(info,val)
					if suiChar.PlayerFrames.focus == 0 then
						suiChar.PlayerFrames.focus = 1;
						spartan:Print("Focus Auras Enabled");
					else
						suiChar.PlayerFrames.focus = 0;
						spartan:Print("Focus Auras Disabled");
					end
					addon.focus.Auras:PostUpdate("focus");
				end
			}
		}
	};
	spartan.options.args["castbar"] = {
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
	spartan.options.args["resetfocus"] = {
		type = "execute", name = "Reset Focus Frame",
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