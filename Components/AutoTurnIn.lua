local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_AutoTurnIn");
----------------------------------------------------------------------------------------------------


function module:OnEnable()
	module:BuildOptions()
	
	if not DB.EnabledComponents.AutoTurnIn then module:HideOptions() return end
	
end


function module:BuildOptions()
	spartan.opt.args["General"].args["ModSetting"].args["AutoTurnIn"] = {type="group",name="Auto TurnIn",
		args = {
			OverrideTheme = {name=L["OverrideTheme"],type="toggle",order=2,desc=L["TooltipOverrideDesc"],
					get = function(info) return DB.AutoTurnIn.Override[DBMod.Artwork.Style] end,
					set = function(info,val) DB.AutoTurnIn.Override[DBMod.Artwork.Style] = val end
			}
		}
	}

end
function module:HideOptions()
	spartan.opt.args["General"].args["ModSetting"].args["AutoTurnIn"].disabled = true
end