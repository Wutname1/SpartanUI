local addon = LibStub("AceAddon-3.0"):NewAddon("SpartanUI","AceConsole-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true)
addon.SpartanVer = GetAddOnMetadata("SpartanUI", "Version")
addon.CurseVersion = GetAddOnMetadata("SpartanUI", "X-Curse-Packaged-Version")
----------------------------------------------------------------------------------------------------
addon.opt = {
	-- name = "SpartanUI "..L["Version"]..": "..spartan.SpartanVer, type = "group", childGroups = "tab", args = {
	name = "SpartanUI 4.0 Alpha", type = "group", childGroups = "tab", args = {
		General = {name = "General", type = "group",order = 0, args = {}};
		Artwork = {name = "Artwork", type = "group", args = {}};
		PlayerFrames = {name = "Player Frames", type = "group", args = {}};
		PartyFrames = {name = "Party Frames", type = "group", args = {}};
		RaidFrames = {name = "Raid Frames", type = "group", args = {}};
		SpinCam = {name = "Spin Cam", type = "group",order = 900, args = {}};
		FilmEffects = {name = "Film Effects", type = "group", order = 950, args = {}};
	}
}

local FontItems = {Primary={},Core={},Party={},Player={},Raid={}}
local FontItemsSize = {Primary={},Core={},Party={},Player={},Raid={}}
local fontdefault = {Size = 0, Face = "SpartanUI", Type = "outline"}
local MovedDefault = {moved=false;point = "",relativeTo = nil,relativePoint = "",xOffset = 0,yOffset = 0}
local frameDefault1 = {movement=MovedDefault;AuraDisplay=true,display=true,Debuffs="all",buffs="all",style="large",Auras={NumBuffs=5,NumDebuffs = 10,size = 20,spacing = 1,showType=true,onlyShowPlayer=false}}
local frameDefault2 = {movement=MovedDefault;AuraDisplay=true,display=true,Debuffs="all",buffs="all",style="medium",Auras={NumBuffs=0,NumDebuffs = 10,size = 15,spacing = 1,showType=true,onlyShowPlayer=false}}

DBdefault = {
	SUIProper = {
		Version = addon.SpartanVer,
		HVer = "",
		yoffset = 0,
		xOffset = 0,
		yoffsetAuto = true,
		scale = .92,
		alpha = 1,
		viewport = true,
		Styles = {
			Classic = {
				Artwork = true,
				PlayerFrames = true,
				PartyFrames = true,
				RaidFrames = true,
				BartenderProfile = "SpartanUI - Classic",
				Movable = {
					Minimap = false,
					PlayerFrames = true,
					PartyFrames = true,
					RaidFrames = true,
				},
				Minimap = {
					shape = "circle",
					size = {width = 140, height = 140}
				},
			}
		},
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
			MapZoomButtons = true,
			Shape = "square",
			Moved = false,
			Position = nil,
			frames = {},
			IgnoredFrames = {},
			SUIMapChangesActive = false
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
			Path = "",
			Primary = fontdefault,
			Core = fontdefault,
			Player = fontdefault,
			Party = fontdefault,
			Raid = fontdefault,
		}
	},
	Modules = {
		Artwork = {
			Style = "Classic",
			FirstLoad = true,
			VehicleUI = true,
			Viewport = 
			{
				enabled = true,
				offset = 
				{
					top = 0,bottom = 2.3,left = 0,right = 0
				}
			}
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
DBGlobals = {Version = addon.SpartanVer}

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
	addon.opt.args["Profiles"] = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db);
	-- Add dual-spec support
	local LibDualSpec = LibStub('LibDualSpec-1.0')
	LibDualSpec:EnhanceDatabase(self.db, "SpartanUI")
	LibDualSpec:EnhanceOptions(addon.opt.args["Profiles"], self.db)
	addon.opt.args["Profiles"].order=999
	-- Spec Setup
	addon.db.RegisterCallback(self, "OnNewProfile", "InitializeProfile")
	addon.db.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	addon.db.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	addon.db.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")
	
	addon:FontSetup()
end

function addon:InitializeProfile()
	self.db:RegisterDefaults(DBdefaults)
end

function addon:UpdateModuleConfigs()
	self.db:RegisterDefaults(DBdefaults)
end

function addon:reloadui()
	DB.OpenOptions = true;
	ReloadUI();
end

function addon:OnEnable()
    AceConfig:RegisterOptionsTable("SpartanUIBliz", { name = "SpartanUI", type = "group",args={
		n1={type="description", fontSize="medium", order=1, width="full", name="Options have moved into their own window as this menu was getting a bit crowded."},
		n3={type="description", fontSize="medium", order=3, width="full", name="Options can be accessed by the button below or by typing /sui or /spartanui"},
		Close={name = "Launch Options",width="full",type = "execute",order = 50,
			func = function()
				InterfaceOptionsFrame:Hide();
				AceConfigDialog:SetDefaultSize("SpartanUI", 850, 600);
				AceConfigDialog:Open("SpartanUI");
			end	}
		}
	})
	AceConfigDialog:AddToBlizOptions("SpartanUIBliz", "SpartanUI")
	
    AceConfig:RegisterOptionsTable("SpartanUI", addon.opt)
	if not addon:GetModule("Artwork_Core", true) then addon.opt.args["Artwork"].disabled = true end
	if not addon:GetModule("FilmEffect", true) then addon.opt.args["FilmEffects"].disabled = true end
    if not addon:GetModule("PartyFrames", true) then  addon.opt.args["PartyFrames"].disabled = true end
    if not addon:GetModule("PlayerFrames", true) then addon.opt.args["PlayerFrames"].disabled = true end
    if not addon:GetModule("RaidFrames", true) then addon.opt.args["RaidFrames"].disabled = true end
    if not addon:GetModule("SpinCam", true) then addon.opt.args["SpinCam"].disabled = true end
    
    self:RegisterChatCommand("sui", "ChatCommand")
    self:RegisterChatCommand("spartanui", "ChatCommand")
	
	local LaunchOpt = CreateFrame("Frame");
	LaunchOpt:SetScript("OnEvent",function(self,...)
		if DB.OpenOptions then
			addon:ChatCommand()
			DB.OpenOptions = false;
		end
	end);
	LaunchOpt:RegisterEvent("PLAYER_ENTERING_WORLD");
end

function addon:ChatCommand(input)
	if input == "version" then
		addon:Print("SpartanUI "..L["Version"].." "..GetAddOnMetadata("SpartanUI", "Version"))
		addon:Print("SpartanUI Curse "..L["Version"].." "..GetAddOnMetadata("SpartanUI", "X-Curse-Packaged-Version"))
	elseif input == "b" then
		InterfaceOptionsFrame_OpenToCategory("SpartanUI")
		InterfaceOptionsFrame_OpenToCategory("SpartanUI")
	elseif input == "map" then
		Minimap.mover:Show();
	else
		AceConfigDialog:SetDefaultSize("SpartanUI", 850, 600)
		AceConfigDialog:Open("SpartanUI")
    end
end

---------------		Math and Comparison FUNCTIONS		-------------------------------

function addon:isPartialMatch(frameName, tab)
	local result = false

	for k,v in ipairs(tab) do
		startpos, endpos = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true;
		end
	end

	return result;
end

function addon:isInTable(tab, frameName)
	for k,v in ipairs(tab) do
		if v ~= nil and frameName ~= nil then
			if (strlower(v) == strlower(frameName)) then
				return true;
			end
		end
	end
	return false;
end

function addon:round(num) -- rounds a number to 2 decimal places
	if num then return floor( (num*10^2)+0.5) / (10^2); end
end;

function addon:comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1' .. _G.LARGE_NUMBER_SEPERATOR):reverse())..right
end

---------------		FONT FUNCTIONS		---------------------------------------------

function addon:FontSetup()
	local OutlineSizes = {22, 18, 13, 12,11,10,9,8}
	local Sizes = {10}
	for i,v in ipairs(OutlineSizes) do
		local filename, fontHeight, flags = _G["SUI_FontOutline" .. v]:GetFont()
		if filename ~= addon:GetFontFace("Primary") then
			_G["SUI_FontOutline" .. v] = _G["SUI_FontOutline" .. v]:SetFont(addon:GetFontFace("Primary"), v)
		end
	end	
	
	for i,v in ipairs(Sizes) do
		local filename, fontHeight, flags = _G["SUI_Font" .. v]:GetFont()
		if filename ~= addon:GetFontFace("Primary") then
			_G["SUI_Font" .. v] = _G["SUI_Font" .. v]:SetFont(addon:GetFontFace("Primary"), v)
		end
	end
end

function addon:GetFontFace(Module)
	if Module then
		if DB.font[Module].Face == "SpartanUI" then
			return "Interface\\AddOns\\SpartanUI\\media\\font-cognosis.ttf"
		elseif DB.font[Module].Face == "SUI4" then
			return "Interface\\AddOns\\SpartanUI\\media\\NotoSans-Bold.ttf"
		elseif DB.font[Module].Face == "FrizQuadrata" then
			return "Fonts\\FRIZQT__.TTF"
		elseif DB.font[Module].Face == "ArialNarrow" then
			return "Fonts\\ARIALN.TTF"
		elseif DB.font[Module].Face == "Skurri" then
			return "Fonts\\skurri.TTF"
		elseif DB.font[Module].Face == "Morpheus" then
			return "Fonts\\MORPHEUS.TTF"
		elseif DB.font[Module].Face == "Custom" and DB.font.Path ~= "" then
			return DB.font.Path
		end
	end
	
	return "Interface\\AddOns\\SpartanUI\\media\\NotoSans-Bold.ttf"
end

function addon:FormatFont(element, size, Module)
	--Adaptive Modules
	if DB.font[Module] == nil then
		DB.font[Module] = spartan.fontdefault;
	end
	--Set Font Outline
	local flags, sizeFinal
	if DB.font[Module].Type == "monochrome" then flags = flags.."monochrome " end
	
	-- Outline was deemed to thick, it is not a slight drop shadow done below
	--if DB.font[Module].Type == "outline" then flags = flags.."outline " end
	
	if DB.font[Module].Type == "thickoutline" then flags = flags.."thickoutline " end
	--Set Size
	sizeFinal = size + DB.font[Module].Size;
	--Create Font
	element:SetFont(addon:GetFontFace(Module), sizeFinal, flags)
	
	if DB.font[Module].Type == "outline" then
		element:SetShadowColor(0,0,0,.9)
		element:SetShadowOffset(1,-1)
	end
	--Add Item to the Array
	local count = 0
	for _ in pairs(FontItems[Module]) do count = count + 1 end
	FontItems[Module][count+1]=element
	FontItemsSize[Module][count+1]=size
end

function addon:FontRefresh(Module)
	for a,b in pairs(FontItems[Module]) do
		--Set Font Outline
		local flags, size
		if DB.font[Module].Type == "monochrome" then flags = flags.."monochrome " end
		if DB.font[Module].Type == "outline" then flags = flags.."outline " end
		if DB.font[Module].Type == "thickoutline" then flags = flags.."thickoutline " end
		--Set Size
		size = FontItemsSize[Module][a] + DB.font[Module].Size;
		--Update Font
		b:SetFont(addon:GetFontFace(Module), size, flags)
	end
end

--------------   oUF Functions   ------------------------------------

do -- ClassIcon as an SpartanoUF module
	local ClassIconCoord = {
		WARRIOR = {			0.00, 0.25, 0.00, 0.25 },
		MAGE = {			0.25, 0.50, 0.00, 0.25 },
		ROGUE = {			0.50, 0.75, 0.00, 0.25 },
		DRUID = {			0.75, 1.00, 0.00, 0.25 },
		HUNTER = {			0.00, 0.25, 0.25, 0.50 },
		SHAMAN = {			0.25, 0.50, 0.25, 0.50 },
		PRIEST = {			0.50, 0.75, 0.25, 0.50 },
		WARLOCK = {			0.75, 1.00, 0.25, 0.50 },
		PALADIN = {			0.00, 0.25, 0.50, 0.75 },
		DEATHKNIGHT = {		0.25, 0.50, 0.50, 0.75 },
		MONK = {			0.50, 0.75, 0.50, 0.75 },
		DEFAULT = {			0.75, 1.00, 0.75, 1.00 },
	};
	local Update = function(self,event,unit)
		local icon = self.SUI_ClassIcon;
		if (icon) then
			local _,class = UnitClass(self.unit);
			local coords = ClassIconCoord[class or "DEFAULT"];
			icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
			icon:Show();
		end
	end
	local Enable = function(self)
		local icon = self.SUI_ClassIcon;
		if (icon) then
			self:RegisterEvent("PARTY_MEMBERS_CHANGED", Update);
			self:RegisterEvent("PLAYER_TARGET_CHANGED", Update);
			self:RegisterEvent("UNIT_PET", Update);
			icon:SetTexture[[Interface\AddOns\SpartanUI\media\icon_class]]
			return true;
		end
	end
	local Disable = function(self)
		local icon = self.SUI_ClassIcon;
		if (icon) then
			self:UnregisterEvent("PARTY_MEMBERS_CHANGED", Update);
			self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update);
			self:UnregisterEvent("UNIT_PET", Update);
		end
	end
	SpartanoUF:AddElement('SUI_ClassIcon',Update,Enable,Disable);
end

do -- SUI_RaidGroup as an SpartanoUF module
	local Update = function(self,event,unit)
		if IsInRaid() then
			self.SUI_RaidGroup:Show();
			self.SUI_RaidGroup.Text:Show();
		else
			self.SUI_RaidGroup:Hide();
			self.SUI_RaidGroup.Text:Hide();
		end
	end
	local Enable = function(self)
		if (self.SUI_RaidGroup) then
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Update);
			return true;
		end
	end
	local Disable = function(self)
		if (self.SUI_RaidGroup) then
			self:UnregisterEvent("GROUP_ROSTER_UPDATE", Update);
		end
	end
	SpartanoUF:AddElement('SUI_RaidGroup',Update,Enable,Disable);
end

do -- AFK / DND status text, as an SpartanoUF module
	SpartanoUF.Tags.Events['afkdnd'] = "PLAYER_FLAGS_CHANGED PLAYER_TARGET_CHANGED UNIT_TARGET";
	SpartanoUF.Tags.Methods['afkdnd'] = function (unit)
		if unit then
			return UnitIsAFK(unit) and "AFK" or UnitIsDND(unit) and "DND" or "";
		end
	end
end

do --Health Formatting Tags
-- Current Health Short, as an SpartanoUF module
	SpartanoUF.Tags.Events['curhpshort'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['curhpshort'] = function (unit)
		local tmp = UnitHealth(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 0).."M"; end
		if tmp >= 1000 then return addon:round(tmp/1000, 0).."K"; end
		return addon:comma_value(tmp);
	end
-- Current Health Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['curhpdynamic'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['curhpdynamic'] = function (unit)
		local tmp = UnitHealth(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Total Health Short, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxhpshort'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['maxhpshort'] = function (unit)
		local tmp = UnitHealthMax(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 0).."M"; end
		if tmp >= 1000 then return addon:round(tmp/1000, 0).."K"; end
		return addon:comma_value(tmp);
	end
-- Total Health Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxhpdynamic'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['maxhpdynamic'] = function (unit)
		local tmp = UnitHealthMax(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Missing Health Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['missinghpdynamic'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['missinghpdynamic'] = function (unit)
		local tmp = UnitHealthMax(unit) - UnitHealth(unit)
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Current Health formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['curhpformatted'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['curhpformatted'] = function (unit) return addon:comma_value(UnitHealth(unit)); end
-- Total Health formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxhpformatted'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['maxhpformatted'] = function (unit) return addon:comma_value(UnitHealthMax(unit)); end
-- Missing Health formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['missinghpformatted'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['missinghpformatted'] = function (unit) return addon:comma_value(UnitHealthMax(unit) - UnitHealth(unit)); end
end

do -- Mana Formatting Tags
-- Current Mana Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['curppdynamic'] = "UNIT_MAXPOWER UNIT_POWER";
	SpartanoUF.Tags.Methods['curppdynamic'] = function (unit)
		local tmp = UnitPower(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Total Mana Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxppdynamic'] = "UNIT_MAXPOWER UNIT_POWER";
	SpartanoUF.Tags.Methods['maxppdynamic'] = function (unit)
		local tmp = UnitPowerMax(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Missing Mana Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['missingppdynamic'] = "UNIT_HEALTH";
	SpartanoUF.Tags.Methods['missingppdynamic'] = function (unit)
		local tmp = UnitPowerMax(unit) - UnitPower(unit)
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Current Mana formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['curppformatted'] = "UNIT_MAXPOWER UNIT_POWER";
	SpartanoUF.Tags.Methods['curppformatted'] = function (unit) return addon:comma_value(UnitPower(unit)); end
-- Total Mana formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxppformatted'] = "UNIT_MAXPOWER UNIT_POWER";
	SpartanoUF.Tags.Methods['maxppformatted'] = function (unit) return addon:comma_value(UnitPowerMax(unit)); end
-- Total Mana formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['missingppformatted'] = "UNIT_MAXPOWER UNIT_POWER";
	SpartanoUF.Tags.Methods['missingppformatted'] = function (unit) return addon:comma_value(UnitPowerMax(unit) - UnitPower(unit)); end
end

do --Color name by Class
	local function hex(r, g, b)
		if r then
			if (type(r) == "table") then
				if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
			end
			return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
		end
	end
	
	SpartanoUF.Tags.Events["SUI_ColorClass"] = 'UNIT_REACTION UNIT_HEALTH UNIT_HAPPINESS'
	SpartanoUF.Tags.Methods["SUI_ColorClass"] = function(u)
		local _, class = UnitClass(u)
		local reaction = UnitReaction(u, "player")
		
		if (u == "pet") then
			return hex(SpartanoUF.colors.class[class])
		elseif (UnitIsPlayer(u)) then
			return hex(SpartanoUF.colors.class[class])
		else
			return hex(1, 1, 1)
		end
	end
end

do -- Level Skull as an SpartanoUF module
	local Update = function(self,event,unit)
		if (self.unit ~= unit) then return; end
		if (not self.LevelSkull) then return; end
		local level = UnitLevel(unit);
		self.LevelSkull:SetTexture[[Interface\TargetingFrame\UI-TargetingFrame-Skull]]
		if level < 0 then
			self.LevelSkull:SetTexCoord(0,1,0,1);
			if self.Level then self.Level:SetText"" end
		else
			self.LevelSkull:SetTexCoord(0,0.01,0,0.01);
		end
	end
	local Enable = function(self)
		if (self.LevelSkull) then return true; end
	end
	local Disable = function(self) return; end
	SpartanoUF:AddElement('LevelSkull', Update,Enable,Disable);
end

do -- Rare / Elite dragon graphic as an SpartanoUF module
	local Update = function(self,event,unit)
		if (self.unit ~= unit) then return; end
		if (not self.RareElite) then return; end
		local c = UnitClassification(unit);
		self.RareElite:SetTexture[[Interface\AddOns\SpartanUI_PlayerFrames\media\elite_rare]];
		self.RareElite:SetTexCoord(0,1,0,1);
		self.RareElite:SetAlpha(.75);
		if self.RareElite.short == true then
			self.RareElite:SetTexCoord(0,1,0,.7);
		end
		
		if c == "worldboss" or c == "elite" or c == "rareelite" then
			self.RareElite:SetVertexColor(1,0.9,0,1);
		elseif c == "rare" then
			self.RareElite:SetVertexColor(1,1,1,1);
		else
			self.RareElite:SetAlpha(0);
		end
	end
	local Enable = function(self)
		if (self.RareElite) then return true; end
	end
	local Disable = function(self) return; end
	SpartanoUF:AddElement('RareElite', Update,Enable,Disable);
end
