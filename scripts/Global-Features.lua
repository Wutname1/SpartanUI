local addon = LibStub("AceAddon-3.0"):NewAddon("SpartanUI","AceConsole-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
----------------------------------------------------------------------------------------------------
suiChar = suiChar or {};
  
addon.optionsMain = {name = "SpartanUI Main", type = "group", args = {}};
addon.optionsGeneral = {name = "SpartanUI General", type = "group", args = {}};
addon.optionsPlayerFrames = {name = "SpartanUI Player Frames", type = "group", args = {}};
addon.optionsPartyFrames = {name = "SpartanUI Party Frames", type = "group", args = {}};
addon.optionsRaidFrames = {name = "SpartanUI Raid Frames", type = "group", args = {comingsoon={name="Raid frames not implemented yet",type="header"}}};
addon.optionsSpinCam = {name = "SpartanUI Spin Cam", type = "group", args = {}};
addon.optionsFilmEffects = {name = "SpartanUI Film Effects", type = "group", args = {}};

addon.options = {name = "SpartanUI", type = "group", args = {}};

DBdefaults = {
	profile = {
		playerName = UnitName("player"),
		SUIProper = {
			ChatSettings = {
				enabled = true
			},
			BuffSettings = {
				enabled = true,
				Manualoffset = false,
				offset = 0
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
			},
			MiniMap = {
				MapButtons = false,
				MapZoomButtons = true
			},
			ActionBars = {
				Allalpha = 100,
				Allenable = true,
				popup1 = {anim = true, alpha = 100, enable = true},
				popup2 = {anim = true, alpha = 100, enable = true},
				bar1 = {alpha = 100, enable = true},
				bar2 = {alpha = 100, enable = true},
				bar3 = {alpha = 100, enable = true},
				bar4 = {alpha = 100, enable = true},
				bar5 = {alpha = 100, enable = true},
				bar6 = {alpha = 100, enable = true},
			}
		},
		Modules = {
			SpinCam = {
				enable = true,
				speed = 8
			},
			FilmEffects = {
				enable = false,
				animationInterval = 0,
				anim = "",
				vignette = nil
			},
			PartyFrames  = {
				showAuras = true,
				partyLock = true,
				partyMoved = false,
				castbar = true,
				castbartext = true,
				showPartyInRaid = false,
				showParty = true,
				showPlayer = true,
				showSolo = false,
				Anchors = {
					point = "TOPLEFT",
					relativeTo = "UIParent",
					relativePoint = "TOPLEFT",
					xOfs = 10,
					yOfs = -20
				},
			},
			PlayerFrames = {},
			RaidFrames = {}
		}
	}
}

function addon:ResetConfig()
	addon.db:ResetProfile(false,true);
	ReloadUI();
end

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New("SpartanUIDB", DBdefaults);
	DB = addon.db.profile.SUIProper
	DBMod = addon.db.profile.Modules
	addon.Optionsprofile = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db);
	addon.optionsMain.args["version"] = {name = "SpartanUI Version: "..GetAddOnMetadata("SpartanUI", "Version"),order=0,type = "header"};
	addon.optionsMain.args["reset"] = {
		type = "execute",
		name = "Reset Options",
		desc = "resets all options to default",
		func = function()
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				addon.db:ResetConfig();
				ReloadUI();
			end
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
    AceConfig:RegisterOptionsTable("SpartanUI Spin Cam", addon.optionsSpinCam)
    AceConfig:RegisterOptionsTable("SpartanUI Film Effects", addon.optionsFilmEffects)
	addon.options.args["warning1"] = {name="These Settings have yet to be tested and migrated to the new profile system.",type="header",order=0}
	addon.options.args["warning2"] = {name="They may or may not work.",type="header",order=1}
	addon.options.args["warning3"] = {name="",type="header",order=2}
    AceConfig:RegisterOptionsTable("SpartanUI Archive Options", addon.options)
	AceConfig:RegisterOptionsTable("Profiles", self.Optionsprofile);

    AceConfigDialog:AddToBlizOptions("SpartanUI Main", "SpartanUI", nil)
    AceConfigDialog:AddToBlizOptions("SpartanUI General", "General", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Player Frames", "Player Frames", "SpartanUI")
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("SpartanUI Party Frames", "Party Frames", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Raid Frames", "Raid Frames", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Spin Cam", "Spin Cam", "SpartanUI")
    AceConfigDialog:AddToBlizOptions("SpartanUI Film Effects", "Film Effects", "SpartanUI")
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