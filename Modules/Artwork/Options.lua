local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");

function Artwork_Core:SetupOptions()
	local Profiles = {}
	for name, module in spartan:IterateModules() do
		if (string.match(name, "Style_")) then
			Profiles[string.sub(name, 7)] = string.sub(name, 7)
		end
	end
	spartan.opt.args["Artwork"].args["Profile"] = {name="Profile",type="select",order=0,style="dropdown",
		values=Profiles,
		get = function(info) return DBMod.Artwork.Style end,
		set = function(info,val) 
			DBMod.Artwork.FirstLoad = true
			DBMod.Artwork.Style = val;
			local newtheme = spartan:GetModule("Style_"..val)
			newtheme:SetupProfile();
			ReloadUI();
		end
	}
	spartan.opt.args["Artwork"].args["Base"] = {name = "Base Options",type="group",order=0,
		args = {
			VehicleUI = {name = "Use Blizzard Vehicle UI", type = "toggle",order=0.9,
				get = function(info) return DBMod.Artwork.VehicleUI end,
				set = function(info,val) 
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); return; end
					DBMod.Artwork.VehicleUI = val
					--Make sure bartender knows to do it, or not...
					if Bartender4 then
						Bartender4.db.profile.blizzardVehicle = val
						Bartender4:UpdateBlizzardVehicle()
					end
					
					if DBMod.Artwork.VehicleUI then
						if spartan:GetModule("Style_" .. DBMod.Artwork.Style).SetupVehicleUI() ~= nil then
							spartan:GetModule("Style_" .. DBMod.Artwork.Style):SetupVehicleUI()
						end
					else
						if spartan:GetModule("Style_" .. DBMod.Artwork.Style).RemoveVehicleUI() ~= nil then
							spartan:GetModule("Style_" .. DBMod.Artwork.Style):RemoveVehicleUI()
						end
					end
				end,
			},
			LockButtons = {name = "Lock Buttons", type = "toggle",order=0.91,
				get = function(info) if Bartender4 then return Bartender4.db.profile.buttonlock else spartan.opt.args["Artwork"].args["Global"].args["LockButtons"].disabled=true; return false; end end,
				set = function(info, value)
					Bartender4.db.profile.buttonlock = value
					Bartender4.Bar:ForAll("ForAll", "SetAttribute", "buttonlock", value)
				end,
			},
			Viewport = {name = "Viewport",type = "group",inline=true,
			args = {
				Enabled = {name = "Enabled", type = "toggle",order=1,
					desc="Allow SpartanUI To manage the viewport",
					get = function(info) return DB.viewport end,
					set = function(info,val)
						if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); return; end
						if (not val) then
							--Since we are disabling reset the viewport
							WorldFrame:ClearAllPoints();
							WorldFrame:SetPoint("TOPLEFT", 0, 0);
							WorldFrame:SetPoint("BOTTOMRIGHT", 0, 0);
						end
						DB.viewport = val
						if (not DB.viewport) then
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetTop"].disabled = true;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetBottom"].disabled = true;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetLeft"].disabled = true;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetRight"].disabled = true;
						else
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetTop"].disabled = false;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetBottom"].disabled = false;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetLeft"].disabled = false;
							spartan.opt.args["Artwork"].args["Base"].args["Viewport"].args["viewportoffsetRight"].disabled = false;
						end
					end,
				},
				viewportoffsets = {name = "Offset",order=2,type = "description",fontSize = "large"},
				viewportoffsetTop = {name = "Top",type = "range",order=2.1,
					min=-100,max=100,step=.1,
					get = function(info) return DBMod.Artwork.Viewport.offset.top end,
					set = function(info,val) DBMod.Artwork.Viewport.offset.top = val; end,
				},
				viewportoffsetBottom = {name = "Bottom",type = "range",order=2.2,
					min=-100,max=100,step=.1,
					get = function(info) return DBMod.Artwork.Viewport.offset.bottom end,
					set = function(info,val) DBMod.Artwork.Viewport.offset.bottom = val; end,
				},
				viewportoffsetLeft = {name = "Left",type = "range",order=2.3,
					min=-100,max=100,step=.1,
					get = function(info) return DBMod.Artwork.Viewport.offset.left end,
					set = function(info,val) DBMod.Artwork.Viewport.offset.left = val; end,
				},
				viewportoffsetRight = {name = "Right",type = "range",order=2.4,
				min=-100,max=100,step=.1,
				get = function(info) return DBMod.Artwork.Viewport.offset.right end,
				set = function(info,val) DBMod.Artwork.Viewport.offset.right = val; end,
			},
			}
			}
		}
	}
	spartan.opt.args["Artwork"].args["Minimap"] = {name = "Minimap Options",type="group",order=0,
		args = {
			NorthIndicator = {name = "Show North Indicator on Minimap", type = "toggle",order=0.9,
				get = function(info) return DB.MiniMap.northTag end,
				set = function(info,val) 
					if (InCombatLockdown()) then spartan:Print(ERR_NOT_IN_COMBAT); return; end
					DB.MiniMap.northTag = val;
					if DB.MiniMap.northTag then
						MinimapNorthTag:Show()
					else
						MinimapNorthTag:Hide()
					end
				end,
			}
		}
	}
	
	if (not DB.viewport) then
		spartan.opt.args["Artwork"].args["Global"].args["viewportoffsetTop"].disabled = true;
		spartan.opt.args["Artwork"].args["Global"].args["viewportoffsetBottom"].disabled = true;
		spartan.opt.args["Artwork"].args["Global"].args["viewportoffsetLeft"].disabled = true;
		spartan.opt.args["Artwork"].args["Global"].args["viewportoffsetRight"].disabled = true;
	end
end