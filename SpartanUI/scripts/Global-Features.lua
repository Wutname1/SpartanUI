local addon = LibStub("AceAddon-3.0"):NewAddon("SpartanUI","AceConsole-3.0");
----------------------------------------------------------------------------------------------------
suiChar = suiChar or {};
addon.options = {name = "SpartanUI", type = "group", args = {}};

function addon:OnInitialize()
	local lang = GetLocale();
	if (lang == "ruRU" or lang == "zhCN" or lang == "zhTW") then
		local font = [[Interface\AddOns\SpartanUI\media\font-myriad.ttf]];
		SUI_FontOutline22:SetFont(font,22,"OUTLINE");
		SUI_FontOutline18:SetFont(font,18,"OUTLINE");
		SUI_FontOutline13:SetFont(font,13,"OUTLINE");
		SUI_FontOutline12:SetFont(font,12,"OUTLINE");
		SUI_FontOutline11:SetFont(font,11,"OUTLINE");
		SUI_FontOutline10:SetFont(font,10,"OUTLINE");
		SUI_FontOutline9:SetFont(font,9,"OUTLINE");
		SUI_FontOutline8:SetFont(font,8,"OUTLINE");
	end
	addon.options.args["reset"] = {
		type = "execute",
		name = "Reset Options",
		desc = "resets all options to default",
		func = function()
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
--				suiChar = nil;
				suiChar ={};
				suiChar.AlphaNotise = true
				ReloadUI();
			end
		end
	};
	addon.options.args["version"] = {
		type = "execute",
		name = "Show SpartanUI version",
		desc = "Show SpartanUI version",
		func = function()
			addon:Print("SpartanUI "..GetAddOnMetadata("SpartanUI", "Version"));
		end
	};
end

function addon:OnEnable()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("SpartanUI", addon.options, {"sui", "spartanui"});
end