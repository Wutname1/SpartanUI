local addon = LibStub("AceAddon-3.0"):NewAddon("SpartanUI","AceConsole-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
----------------------------------------------------------------------------------------------------
addon.optionsMain = {name = "SpartanUI Main", type = "group", args = {}};
addon.optionsGeneral = {name = "SpartanUI General", type = "group", args = {}};
addon.optionsPlayerFrames = {name = "SpartanUI Player Frames", type = "group", args = {}};
addon.optionsPartyFrames = {name = "SpartanUI Party Frames", type = "group", args = {}};
addon.optionsRaidFrames = {name = "SpartanUI Raid Frames", type = "group", args = {}};
addon.optionsSpinCam = {name = "SpartanUI Spin Cam", type = "group", args = {}};
addon.optionsFilmEffects = {name = "SpartanUI Film Effects", type = "group", args = {}};
--addon.ChangeLog = {name = "SpartanUI Change Log", type = "group", args = {}};

local fontdefault = {Size = 0, Face = "SpartanUI", Type = "outline"}
local frameDefault = {moved=false;AuraDisplay=true,display=true,Debuffs="all",buffs="all",style="large"}

DBdefault = {
	SUIProper = {
		yoffset = 0,
		xOffset = 0,
		yoffsetAuto = true,
		scale = .92,
		alpha = 1,
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
			text = true,
			ToolTip = "click",
			GainedColor	= "Blue",
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
			text = false,
			ToolTip = "click",
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
		},
		font = {
			Primary = fontdefault,
			Core = fontdefault,
			Player = fontdefault,
			Party = fontdefault,
			Raid = fontdefault,
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
			DisplayPets = true,
			FrameStyle = "large",
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
		PlayerFrames = {
			focusMoved = false,
			player = frameDefault,
			target = frameDefault,
			targettarget = frameDefault,
			pet = frameDefault,
			focus = frameDefault,
			focustarget = frameDefault,
			bars = {
				health = {textstyle = "dynamic",textmode=1},
				mana = {textstyle = "longfor",textmode=1},
				player = {color="dynamic"},
				target = {color="reaction"},
				targettarget = {color="dynamic"},
				pet = {color="happiness"},
				focus = {color="dynamic"},
				focustarget = {color="dynamic"},
			}
		},
		RaidFrames  = {
			DisplayPets = true,
			FrameStyle = "large",
			showAuras = true,
			raidLock = true,
			raidMoved = false,
			castbar = true,
			castbartext = true,
			hideRaid = false,
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
		}
	}
}
DBdefaults = {char = DBdefault,realm = DBdefault,class = DBdefault,profile = DBdefault}
DBGlobals = { }

function addon:ResetConfig()
	addon.db:ResetProfile(false,true);
	ReloadUI();
end

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New("SpartanUIDB", DBdefaults);
	addon.db.profile.playerName = UnitName("player")
	DBGlobal = addon.db.global
	DB = addon.db.profile.SUIProper
	DBMod = addon.db.profile.Modules
	SpartanVer = GetAddOnMetadata("SpartanUI", "Version")
	addon.Optionsprofile = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db);
	addon.optionsMain.args["version"] = {name = "SpartanUI Version: "..GetAddOnMetadata("SpartanUI", "Version"),order=0,type = "header"};
	addon.optionsMain.args["reset"] = {name = "Reset Database",type = "execute",order=100,width="full",
		desc = "Will Reset the ENTIRE Database. This should fix 99% of Settings related issues.",
		func = function()
			if (InCombatLockdown()) then 
				addon:Print(ERR_NOT_IN_COMBAT);
			else
				addon.db:ResetDB();
				ReloadUI();
			end
		end
	};
	-- Add dual-spec support
	local LibDualSpec = LibStub('LibDualSpec-1.0')
	LibDualSpec:EnhanceDatabase(self.db, "SpartanUI")
	LibDualSpec:EnhanceOptions(addon.Optionsprofile, self.db)
	-- Spec Setup
	addon.db.RegisterCallback(self, "OnNewProfile", "InitializeProfile")
	addon.db.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	addon.db.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	addon.db.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")
end

function addon:InitializeProfile()
	self.db:RegisterDefaults(DBdefaults)
end

function addon:UpdateModuleConfigs()
	self.db:RegisterDefaults(DBdefaults)
end

function addon:OnEnable()
	
    AceConfig:RegisterOptionsTable("SpartanUI Main", addon.optionsMain)
    AceConfig:RegisterOptionsTable("SpartanUI General", addon.optionsGeneral)
    AceConfig:RegisterOptionsTable("SpartanUI Player Frames", addon.optionsPlayerFrames)
    AceConfig:RegisterOptionsTable("SpartanUI Party Frames", addon.optionsPartyFrames)
    AceConfig:RegisterOptionsTable("SpartanUI Raid Frames", addon.optionsRaidFrames)
    AceConfig:RegisterOptionsTable("SpartanUI Spin Cam", addon.optionsSpinCam)
    AceConfig:RegisterOptionsTable("SpartanUI Film Effects", addon.optionsFilmEffects)
    --AceConfig:RegisterOptionsTable("SpartanUI Change Log", addon.ChangeLog)
	AceConfig:RegisterOptionsTable("Profiles", self.Optionsprofile);

	AceConfigDialog:AddToBlizOptions("SpartanUI Main", "SpartanUI", nil)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("SpartanUI General", "General", "SpartanUI")
    
	if addon:GetModule("FilmEffect", true) then	AceConfigDialog:AddToBlizOptions("SpartanUI Film Effects", "Film Effects", "SpartanUI") end
    if addon:GetModule("PartyFrames", true) then AceConfigDialog:AddToBlizOptions("SpartanUI Party Frames", "Party Frames", "SpartanUI") end
    if addon:GetModule("PlayerFrames", true) then AceConfigDialog:AddToBlizOptions("SpartanUI Player Frames", "Player Frames", "SpartanUI") end
    if addon:GetModule("RaidFrames", true) then AceConfigDialog:AddToBlizOptions("SpartanUI Raid Frames", "Raid Frames", "SpartanUI") end
    if addon:GetModule("SpinCam", true) then AceConfigDialog:AddToBlizOptions("SpartanUI Spin Cam", "Spin Cam", "SpartanUI") end
    --AceConfigDialog:AddToBlizOptions("SpartanUI Change Log", "Change Log", "SpartanUI")
	
	AceConfigDialog:AddToBlizOptions("Profiles", "Profiles", "SpartanUI");
	
	
    self:RegisterChatCommand("sui", "ChatCommand")
	
end

function addon:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    elseif input == "version" then
		addon:Print("Version "..GetAddOnMetadata("SpartanUI", "Version"))
	else
        LibStub("AceConfigCmd-3.0").HandleCommand(addon, "sui", "spartanui", input)
    end
end