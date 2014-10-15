local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");

function Artwork_Core:SetupOptions()
	Profiles = {}
	for name, module in spartan:IterateModules() do
		if (string.match(name, "Artwork_") and name ~= "Artwork_Core") then
			Profiles[string.sub(name, 9)] = string.sub(name, 9)
		end
	end
	spartan.opt.Artwork.args["Profile"] = {name="Profile",type="select",order=0,style="dropdown",
		values=Profiles,
		get = function(info) return DBMod.Artwork.Theme end,
		set = function(info,val) 
			DBMod.Artwork.Theme = val;
			newtheme = spartan:GetModule("Artwork_"..val)
			newtheme:CreateProfile();
			ReloadUI();
		end
	}
	spartan.opt.Artwork.args["Reload"] = {name = "ReloadUI",type = "execute",order=2,
		desc = L["ResetDatabaseDesc"],
		func = function() ReloadUI(); end
	};
	spartan.opt.Artwork.args["Global"] = {name = "Base Options",type="group",order=0,
		args = {
			viewport = {name = "Viewport", type = "toggle",order=2,
				desc="Allow SpartanUI To manage the viewport",
				get = function(info) return DB.viewport end,
				set = function(info,val)
					if (not val) then
						--Since we are disabling reset the viewport
						WorldFrame:ClearAllPoints();
						WorldFrame:SetPoint("TOPLEFT", 0, 0);
						WorldFrame:SetPoint("BOTTOMRIGHT", 0, 0);
					end
					DB.viewport = val
				end,
			},
		}
	}
end