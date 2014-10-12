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
	spartan.opt.Artwork.args["Global"] = {name = "Artwork Options",type="group",order=10,
		args = {
			alpha = {name=L["Transparency"],type="range",order=1,width="full",
				min=0,max=100,step=1,desc=L["TransparencyDesc"],
				get = function(info) return (DB.alpha*100); end,
				set = function(info,val) DB.alpha = (val/100); updateSpartanAlpha(); end
			},
			xOffset = {name = L["MoveSideways"],type = "range",order = 3,width="full",
				desc = L["MoveSidewaysDesc"],
				min=-200,max=200,step=.1,
				get = function(info) return DB.xOffset/6.25 end,
				set = function(info,val) DB.xOffset = val*6.25; updateSpartanXOffset(); end,
			}
		}
	}
end