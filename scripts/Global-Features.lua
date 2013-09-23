local addon = LibStub("AceAddon-3.0"):NewAddon("SpartanUI","AceConsole-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true)
SpartanVer = GetAddOnMetadata("SpartanUI", "Version")
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
local MovedDefault = {moved=false;point = "",relativeTo = nil,relativePoint = "",xOffset = 0,yOffset = 0}
local frameDefault1 = {movement=MovedDefault;AuraDisplay=true,display=true,Debuffs="all",buffs="all",style="large",Auras={NumBuffs=5,NumDebuffs = 10,size = 20,spacing = 1,showType=true,onlyShowPlayer=false}}
local frameDefault2 = {movement=MovedDefault;AuraDisplay=true,display=true,Debuffs="all",buffs="all",style="medium",Auras={NumBuffs=0,NumDebuffs = 10,size = 15,spacing = 1,showType=true,onlyShowPlayer=false}}

DBdefault = {
	SUIProper = {
		Version = SpartanVer,
		yoffset = 0,
		xOffset = 0,
		yoffsetAuto = true,
		scale = .92,
		alpha = 1,
		ChatSettings = {
			enabled = true
		},
		BuffSettings = {
			disableblizz = true,
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
			enabled = true,
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
			enabled = true,
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
			threat = true,
			preset = "dps",
			FrameStyle = "large",
			showAuras = true,
			partyLock = true,
			showClass = true,
			partyMoved = false,
			castbar = true,
			castbartext = true,
			showPartyInRaid = false,
			showParty = true,
			showPlayer = true,
			showSolo = false,
			Portrait = true,
			scale=1,
			Auras = {
				NumBuffs = 0,
				NumDebuffs = 10,
				size = 16,
				spacing = 1,
				showType = true
			},
			Anchors = {
				point = "TOPLEFT",
				relativeTo = "UIParent",
				relativePoint = "TOPLEFT",
				xOfs = 10,
				yOfs = -20
			},
			bars = {health={textstyle="dynamic", textmode=1},mana={textstyle="dynamic", textmode=1}},
			display = {pet = true,target=true,mana=true},
		},
		PlayerFrames = {
			showClass = true,
			focusMoved = false,
			global = frameDefault1,
			player = frameDefault1,
			target = frameDefault1,
			targettarget = frameDefault2,
			pet = frameDefault2,
			focus = frameDefault2,
			focustarget = frameDefault2,
			bars = {
				health = {textstyle = "dynamic",textmode=1},
				mana = {textstyle = "longfor",textmode=1},
				player = {color="dynamic"},
				target = {color="reaction"},
				targettarget = {color="dynamic",style="large"},
				pet = {color="happiness"},
				focus = {color="dynamic"},
				focustarget = {color="dynamic"},
			},
			Castbar = {player=1,target=1,targettarget=1,pet=1,focus=1,text={player=1,target=1,targettarget=1,pet=1,focus=1}},
			BossFrame = {movement=MovedDefault,display=true,scale=1},
			ArenaFrame = {movement=MovedDefault,display=false,scale=1},
			ClassBar = {movement=MovedDefault},
			TotemFrame = {movement=MovedDefault},
			AltManaBar = {movement=MovedDefault},
		},
		RaidFrames  = {
			threat = true,
			mode = "group",
			preset = "dps",
			FrameStyle = "small",
			showAuras = true,
			showClass = true,
			moved = false,
			showRaid = true,
			maxColumns = 4,
			unitsPerColumn = 10,
			columnSpacing = 5,
			scale=1,
			Anchors = {
				point = "TOPLEFT",
				relativeTo = "UIParent",
				relativePoint = "TOPLEFT",
				xOfs = 10,
				yOfs = -20
			},
			bars = {
				health = {textstyle="dynamic", textmode=1},
				mana = {textstyle="dynamic", textmode=1}
			},
			debuffs = {display=true},
			Auras={size=10,spacing=1,showType=true}
		}
	}
}
DBdefaults = {char = DBdefault,realm = DBdefault,class = DBdefault,profile = DBdefault}
DBGlobals = {Version = SpartanVer}

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
	addon.Optionsprofile = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db);
	addon.optionsMain.args["version"] = {name = "SpartanUI "..L["Version"]..": "..GetAddOnMetadata("SpartanUI", "Version"),order=0,type = "header"};
	addon.optionsMain.args["reset"] = {name = L["ResetDatabase"],type = "execute",order=100,width="full",
		desc = L["ResetDatabaseDesc"],
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
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("SpartanUI General", L["General"], "SpartanUI")
    
	if addon:GetModule("FilmEffect", true) then	AceConfigDialog:AddToBlizOptions("SpartanUI Film Effects", L["Film Effects"], "SpartanUI") end
    if addon:GetModule("PartyFrames", true) then AceConfigDialog:AddToBlizOptions("SpartanUI Party Frames", L["Party Frames"], "SpartanUI") end
    if addon:GetModule("PlayerFrames", true) then AceConfigDialog:AddToBlizOptions("SpartanUI Player Frames", L["Player Frames"], "SpartanUI") end
    if addon:GetModule("RaidFrames", true) then AceConfigDialog:AddToBlizOptions("SpartanUI Raid Frames", L["Raid Frames"], "SpartanUI") end
    if addon:GetModule("SpinCam", true) then AceConfigDialog:AddToBlizOptions("SpartanUI Spin Cam", L["Spin Cam"], "SpartanUI") end
    --AceConfigDialog:AddToBlizOptions("SpartanUI Change Log", "Change Log", "SpartanUI")
	
	AceConfigDialog:AddToBlizOptions("Profiles", "Profiles", "SpartanUI");
	
	
    self:RegisterChatCommand("sui", "ChatCommand")
	
end

function addon:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    elseif input == "version" then
		addon:Print("SpartanUI "..L["Version"].." "..GetAddOnMetadata("SpartanUI", "Version"))
	else
        LibStub("AceConfigCmd-3.0").HandleCommand(addon, "sui", "spartanui", input)
    end
end