local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_Nameplates");
----------------------------------------------------------------------------------------------------

function module:OnInitialize()
	if DBMod.Nameplates == nil then
		DBMod.Nameplates = {
			showThreat = true,
			healthMode = "detailed"
		}
	end
end

function module:OnEnable()

	module:BuildOptions()
	module:HideOptions()
end

function module:BuildOptions()
	spartan.opt.args["General"].args["ModSetting"].args["Nameplates"] = {type="group",name=L["Nameplates"],
		args = {}
	}
end

function module:HideOptions()
	spartan.opt.args["General"].args["ModSetting"].args["Nameplates"].disabled = true
end