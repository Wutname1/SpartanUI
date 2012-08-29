local addon = LibStub("AceAddon-3.0"):NewAddon("SpartanUI","AceConsole-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local AceConfig = LibStub("AceConfig-3.0");
----------------------------------------------------------------------------------------------------
suiChar = suiChar or {};
  
addon.optionsMain = {name = "SpartanUI Main", type = "group", args = {}};
addon.optionsGeneral = {name = "SpartanUI General", type = "group", args = {}};
addon.optionsPlayerFrames = {name = "SpartanUI Player Frames", type = "group", args = {}};
addon.optionsPartyFrames = {name = "SpartanUI Party Frames", type = "group", args = {}};
addon.optionsRaidFrames = {name = "SpartanUI Raid Frames", type = "group", args = {}};
addon.optionsFilmEffects = {name = "SpartanUI Film Effects", type = "group", args = {}};
addon.optionsSpinCam = {name = "SpartanUI Spin Cam", type = "group", args = {}};

addon.options = {name = "SpartanUI", type = "group", args = {}};

local DBdefaults = {
	profile = {
		playerName = UnitName("player"),
		ChatSettings = {
			enabled = true
		},
		BuffSettings = {
			enabled = true,
			Manualoffset = false,
			offset = 0
		},
		ActionBars = {
			Allenable = true,
			bar1enable = true,
			bar2enable = true,
			bar3enable = true,
			bar4enable = true,
			bar5enable = true,
			bar6enable = true,
			Allenable = 100,
			bar1alpha = 100,
			bar2alpha = 100,
			bar3alpha = 100,
			bar4alpha = 100,
			bar5alpha = 100,
			bar6alpha = 100
		},
		PopUP = {
			popup1enable = true,
			popup2enable = true,
			popup1alpha = 100,
			popup2alpha = 100,
			popup1anim = true,
			popup2anim = true
		},
		XPBar = {
			GainedColor	= "Light_Blue",
			GainedRed	= 0,
			GainedBlue	= 1,
			GainedGreen	= .5,
			GainedBrightness= .7,
			RestedColor	= "Light_Blue",
			RestedRed	= 0,
			RestedBlue	= 1,
			RestedGreen	= .5,
			RestedBrightness= .7,
			RestedMatchColor= false
		},
		RepBar = {
			GainedColor	= "AUTO",
			GainedRed	= 0,
			GainedBlue	= 0,
			GainedGreen	= 1,
			GainedBrightness= .6,
			AutoDefined	= true
		}
	}
}

function addon:RefreshConfig()
	addon:Print("Refresh called");
end
	
function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New("SpartanUIDB", DBdefaults);
	DB = addon.db.profile
	addon.Optionsprofile = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db);
	addon.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	addon.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	addon.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
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
	addon.optionsMain.args["reset"] = {
		type = "execute",
		name = "Reset Options",
		desc = "resets all options to default",
		func = function()
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				addon.db:ResetProfile();
				ReloadUI();
			end
		end
	};
	addon.optionsMain.args["version"] = {
		type = "execute",
		name = "Show SpartanUI version",
		desc = "Show SpartanUI version",
		func = function()
			addon:Print("SpartanUI "..GetAddOnMetadata("SpartanUI", "Version"));
		end
	};
end

function addon:OnEnable()

	--AceConfig:RegisterOptionsTable("SpartanUI", addon.options, {"sui", "spartanui"});
	
    AceConfig:RegisterOptionsTable("SpartanUI Main", addon.optionsMain)
    AceConfig:RegisterOptionsTable("SpartanUI General", addon.optionsGeneral)
    AceConfig:RegisterOptionsTable("SpartanUI Player Frames", addon.optionsPlayerFrames)
    AceConfig:RegisterOptionsTable("SpartanUI Party Frames", addon.optionsPartyFrames)
    AceConfig:RegisterOptionsTable("SpartanUI Raid Frames", addon.optionsRaidFrames)
    AceConfig:RegisterOptionsTable("SpartanUI Film Effects", addon.optionsFilmEffects)
    AceConfig:RegisterOptionsTable("SpartanUI Spin Cam", addon.optionsSpinCam)
    AceConfig:RegisterOptionsTable("SpartanUI Archive Options", addon.options)
	AceConfig:RegisterOptionsTable("Profiles", self.Optionsprofile);

    AceConfigDialog:AddToBlizOptions("SpartanUI Main", "SpartanUI", nil)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("SpartanUI General", "General", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Player Frames", "Player Frames", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Party Frames", "Party Frames", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Raid Frames", "Raid Frames", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Film Effects", "Film Effects", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Spin Cam", "Spin Cam", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Archive Options", "Archive Options", "SpartanUI")
	AceConfigDialog:AddToBlizOptions("Profiles", "Profiles", "SpartanUI");
	
    self:RegisterChatCommand("sui", "ChatCommand")
    self:RegisterChatCommand("spartanui", "ChatCommand")
end

function addon:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(addon, "sui", "spartanui", input)
    end
end