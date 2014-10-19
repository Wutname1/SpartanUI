local addon = LibStub("AceAddon-3.0"):NewAddon("SpartanUI","AceConsole-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true)
SpartanVer = GetAddOnMetadata("SpartanUI", "Version")
local CurseVersion = GetAddOnMetadata("SpartanUI", "X-Curse-Packaged-Version")
----------------------------------------------------------------------------------------------------
addon.opt = {
	Main = {name = "Main", type = "group", args = {}};
	General = {name = "General", type = "group", args = {}};
	Artwork = {name = "Artwork", type = "group", args = {}};
	PlayerFrames = {name = "Player Frames", type = "group", args = {}};
	PartyFrames = {name = "Party Frames", type = "group", args = {}};
	RaidFrames = {name = "Raid Frames", type = "group", args = {}};
	SpinCam = {name = "Spin Cam", type = "group", args = {}};
	FilmEffects = {name = "Film Effects", type = "group", args = {}};
}

local fontdefault = {Size = 0, Face = "SpartanUI", Type = "outline"}
local MovedDefault = {moved=false;point = "",relativeTo = nil,relativePoint = "",xOffset = 0,yOffset = 0}
local frameDefault1 = {movement=MovedDefault;AuraDisplay=true,display=true,Debuffs="all",buffs="all",style="large",Auras={NumBuffs=5,NumDebuffs = 10,size = 20,spacing = 1,showType=true,onlyShowPlayer=false}}
local frameDefault2 = {movement=MovedDefault;AuraDisplay=true,display=true,Debuffs="all",buffs="all",style="medium",Auras={NumBuffs=0,NumDebuffs = 10,size = 15,spacing = 1,showType=true,onlyShowPlayer=false}}

DBdefault = {
	SUIProper = {
		Version = SpartanVer,
		HVer = "",
		yoffset = 0,
		xOffset = 0,
		yoffsetAuto = true,
		scale = .92,
		alpha = 1,
		viewport = true,
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
			ManualAllowUse = false,
			ManualAllowPrompt = "",
			AutoDetectAllowUse = true,
			MapButtons = true,
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
		Artwork = {
			Viewport = 
			{
				enabled = true,
				offset = 
				{
					top = 0,bottom = 2.3,left = 0,right = 0
				}
			},
			FirstLoad = true,
			Theme = "Classic"
		},
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
			Portrait3D = true,
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
			style = "theme",
			Portrait3D = true,
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
			HideBlizzFrames = true,
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

function addon:comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1' .. _G.LARGE_NUMBER_SEPERATOR):reverse())..right
end

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
	addon.opt.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db);
	addon.opt.Main.args["SuiVersion"] = {name = "SpartanUI "..L["Version"]..": "..SpartanVer,order=1,type = "header"};
	if (SpartanVer ~= CurseVersion) then
		addon.opt.Main.args["CurseVersion"] = {name = "Build "..CurseVersion,order=1.1,type = "header"};
	end
	addon.opt.Main.args["reset"] = {name = L["ResetDatabase"],type = "execute",order=100,width="full",
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
	LibDualSpec:EnhanceOptions(addon.opt.profile, self.db)
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
    AceConfig:RegisterOptionsTable("SpartanUI", addon.opt.Main)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions("SpartanUI")
	addon:AddOption("General", addon.opt.General, L["General"])
	if addon:GetModule("Artwork_Core", true) then addon:AddOption("Artwork", addon.opt.Artwork, "Artwork") end
	if addon:GetModule("FilmEffect", true) then addon:AddOption("Film Effects", addon.opt.FilmEffects, L["FilmEffects"]) end
    if addon:GetModule("PartyFrames", true) then addon:AddOption("Party Frames", addon.opt.PartyFrames, L["PartyFrames"]) end
    if addon:GetModule("PlayerFrames", true) then addon:AddOption("Player Frames", addon.opt.PlayerFrames, L["PlayerFrames"]) end
    if addon:GetModule("RaidFrames", true) then addon:AddOption("Raid Frames", addon.opt.RaidFrames, L["RaidFrames"]) end
    if addon:GetModule("SpinCam", true) then addon:AddOption("Spin Cam", addon.opt.SpinCam, L["SpinCam"]) end
	addon:AddOption("Profiles", addon.opt.profile, "Profiles"); --Localization Needed
    
    self:RegisterChatCommand("sui", "ChatCommand")
    self:RegisterChatCommand("spartanui", "ChatCommand")
end

function addon:AddOption(name, Table, displayName)
	AceConfig:RegisterOptionsTable("SpartanUI"..name, Table)
	AceConfigDialog:AddToBlizOptions("SpartanUI"..name, displayName, "SpartanUI")
end

function addon:ChatCommand(input)
	if input == "version" then
		addon:Print("SpartanUI "..L["Version"].." "..GetAddOnMetadata("SpartanUI", "Version"))
	else
		InterfaceOptionsFrame_OpenToCategory("SpartanUI")
		InterfaceOptionsFrame_OpenToCategory("SpartanUI")
        --LibStub("AceConfigCmd-3.0").HandleCommand(addon, "sui", "spartanui", input)
    end
end