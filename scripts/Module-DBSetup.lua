local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:NewModule("DBSetup");
local Bartender4Version, BartenderMin = "","4.5.12"
if select(4, GetAddOnInfo("Bartender4")) then Bartender4Version = GetAddOnMetadata("Bartender4", "Version") end
local CurseVersion = GetAddOnMetadata("SpartanUI", "X-Curse-Packaged-Version")
if (CurseVersion == nil) then CurseVersion = "" end

function module:OnInitialize()
	StaticPopupDialogs["FirstLaunchNotice"] = {
		text = '|cff33ff99SpartanUI v'..SpartanVer..'|n|r|n|n'..L["WelcomeMSG"]..' /sui|n|n',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.Version = SpartanVer;
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["BartenderVerWarning"] = {
		text = '|cff33ff99SpartanUI v'..SpartanVer..'|n|r|n|n'..L["Warning"]..': '..L["BartenderOldMSG"]..' '..Bartender4Version..'|n|nSpartanUI requires '..BartenderMin..' or higher.',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.BartenderVerWarning = SpartanVer;
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["BartenderInstallWarning"] = {
		text = '|cff33ff99SpartanUI v'..SpartanVer..'|n|r|n|n'..L["Warning"]..': '..L["BartenderNotFoundMSG1"]..'|n'..L["BartenderNotFoundMSG2"],
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.BartenderInstallWarning = SpartanVer
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["AlphaWarning"] = {
		text = '|cff33ff99SpartanUI Alpha '..CurseVersion..'|n|r|n|n'..L["Warning"]..': '..L["AplhaDetectedMSG1"]..'|n|n'..L["AplhaDetectedMSG2"],
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.AlphaWarning = CurseVersion
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	
	StaticPopupDialogs["MiniMapNotice"] = {
		text = '|cff33ff99SpartanUI Notice|n|r|n Another addon has been found modifying the minimap. Do you give permisson for SpartanUI to move and possibly modify the minimap as your theme dictates? |n|n You can change this option in the settings should you change your mind.',
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			DB.MiniMap.ManualAllowPrompt = DB.Version
			DB.MiniMap.ManualAllowUse = true
			ReloadUI();
		end,
		OnCancel = function()
			DB.MiniMap.ManualAllowPrompt = DB.Version
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	-- DB Updates
	if DBGlobal.Version then
		if DB.Version == nil then -- DB Updates from 3.0.2 to 3.0.3 this variable was not set in 3.0.2
			spartan:Print(L["DBUpdate"].." 3.0.2 "..L["settings"])
			local unitlist = {player=0,target=0,targettarget=0,pet=0,focus=0,focustarget=0};
			for k,v in pairs(unitlist) do
				tmp = true;
				if DBMod.PlayerFrames[k] == 0 then tmp = false end;
				DBMod.PlayerFrames[k] = {AuraDisplay = tmp, display = true};
			end
			--Update XP Bar Colors
			if DB.XPBar.GainedColor == DB.XPBar.RestedColor then
				DB.XPBar.GainedColor = "Blue";
			end
			
			DB.XPBar.ToolTip = true;
			if UnitXP("player") == 0 then DB.XPBar.text = false; else DB.XPBar.text = true; end
			DB.RepBar.text = false;
			DB.RepBar.ToolTip = true;
			DB.Version = "3.0.3"
		end
		if (DB.Version < "3.0.4") then -- DB updates for 3.0.5
			spartan:Print(L["DBUpdate"].." 3.0.4 "..L["settings"])
			DB.offsetAuto = true
			if DB.offset then
				if DB.offset >= 2 then 
					DB.offsetAuto = false
				end
			else
				DB.offset = 0
			end
			fontdefault = {Size = 0, Face = "SpartanUI", Type = "outline"}
			DB.font.Primary = fontdefault
			DB.font.Core = fontdefault
			DB.font.Player = fontdefault
			DB.font.Party = fontdefault
			DB.font.Raid = fontdefault
			if DB.XPBar.ToolTip then DB.XPBar.ToolTip = "click" else DB.XPBar.ToolTip = "disabled" end
			if DB.RepBar.ToolTip then DB.RepBar.ToolTip = "click" else DB.RepBar.ToolTip = "disabled" end
			DBMod.PlayerFrames.target.Debuffs = "all"
			DB.Version = "3.0.4"
		end
		if (DB.Version < "3.1.0") then -- DB Updates for 3.1.0
			spartan:Print(L["DBUpdate"].." 3.1.0 "..L["settings"])
			DB.yoffsetAuto = DB.offsetAuto;
			if not DB.offset then DB.offset = 0 end
			if not DB.yoffset then DB.yoffset = DB.offset; end
			if not DB.xOffset then DB.xOffset = 0; end
			if not DBMod.PlayerFrames.targettarget.style then DBMod.PlayerFrames.targettarget.style = "large"; end
			if not DB.alpha then DB.alpha = 1; end
			if not DBMod.PlayerFrames.bars.player.color then 
				DBMod.PlayerFrames.bars = {
					health = {textstyle="dynamic", textmode=1},
					mana = {textstyle="longfor", textmode=1},
					player = {color="dynamic"},
					target = {color="reaction"},
					targettarget = {color="dynamic"},
					pet = {color="happiness"},
					focus = {color="dynamic"},
					focustarget = {color="dynamic"},
				}
			end
			if not DBMod.RaidFrames.bars then 
				DBMod.RaidFrames.bars = {
					health = {textstyle="dynamic", textmode=1},
					mana = {textstyle="dynamic", textmode=1}
				}
			end
			if not DBMod.PartyFrames.bars then 
				DBMod.PartyFrames.bars = {
					health = {textstyle="dynamic", textmode=1},
					mana = {textstyle="dynamic", textmode=1}
				}
			end
			if not DBMod.PartyFrames.display then
				DBMod.PartyFrames.display = {};
				DBMod.PartyFrames.display.pet = DBMod.PartyFrames.DisplayPets; spartan:Print("Pet Display DB converted");
				DBMod.PartyFrames.display.target = true; spartan:Print("Party Target Enabled.");
			end
			if DBMod.PlayerFrames.focus.moved == nil then DBMod.PlayerFrames.focus.moved = false; spartan:Print("Focus Frame position reset"); end
			if not spartan.db.char.Version then spartan:Print("Setup char DB"); spartan.db.char = DBdefault; spartan.db.char.Version = SpartanVer; end
			if not spartan.db.realm.Version then spartan:Print("Setup realm DB"); spartan.db.realm = DBdefault; spartan.db.realm.Version = SpartanVer; end
			if not spartan.db.class.Version then spartan:Print("Setup class DB"); spartan.db.class = DBdefault; spartan.db.class.Version = SpartanVer; end
			if not DBMod.PartyFrames.Auras then DBMod.PartyFrames.Auras = {} end
			if not DBMod.PartyFrames.Auras.NumBuffs then DBMod.PartyFrames.Auras.NumBuffs = 0 end
			if not DBMod.PartyFrames.Auras.NumDebuffs then DBMod.PartyFrames.Auras.NumDebuffs = 10 end
			if not DBMod.PartyFrames.Auras.size then DBMod.PartyFrames.Auras.size = 16 end
			if not DBMod.PartyFrames.Auras.spacing then DBMod.PartyFrames.Auras.spacing = 1 end
			if DBMod.PartyFrames.Auras.showType == nil then DBMod.PartyFrames.Auras.showType = true end
			if DBMod.PartyFrames.Portrait == nil then DBMod.PartyFrames.Portrait = true end
			if DBMod.RaidFrames.moved == nil then DBMod.RaidFrames.moved = false end
			DBMod.RaidFrames.mode = "group";
			if not DBMod.RaidFrames.scale or DBMod.RaidFrames.scale == 0 then DBMod.RaidFrames.scale = 1 end
			if not DBMod.PartyFrames.scale or DBMod.PartyFrames.scale == 0 then DBMod.PartyFrames.scale = 1 end
			if not DBMod.RaidFrames.preset then DBMod.RaidFrames.preset = "dps" end
			if DBMod.PlayerFrames.BossFrame then DBMod.PlayerFrames.BossFrame = {display=false,moved=false,scale=1} end
			if DBMod.PlayerFrames.ArenaFrame then DBMod.PlayerFrames.ArenaFrame = {display=false,moved=false,scale=1} end
			if not DBMod.RaidFrames.Auras then DBMod.RaidFrames.Auras={size=10,spacing=1,showType=true} end
			if not DBMod.RaidFrames.showRaid then DBMod.RaidFrames.showRaid = true; end
			if not DBMod.RaidFrames.maxColumns then DBMod.RaidFrames.maxColumns = 8; end
			if not DBMod.RaidFrames.unitsPerColumn then DBMod.RaidFrames.unitsPerColumn = 5; end
			if not DBMod.RaidFrames.columnSpacing then DBMod.RaidFrames.columnSpacing = 5; end
			
			local unitlist={player=0,target=0,targettarget=0,pet=0,focus=0,focustarget=0};
			local Auras={NumBuffs = 10,NumDebuffs = 10,size = 16,spacing = 1,showType = true,onlyShowPlayer=true}
			for k,v in pairs(unitlist) do
				tmp = true;
				if not DBMod.PlayerFrames[k].Auras then
					spartan:Print("Updates Auras for "..k);
					DBMod.PlayerFrames[k].Auras = Auras;
					if k == "focus" or k == "focustarget" then DBMod.PlayerFrames[k].Auras.NumBuffs = 0; end
				end;
			end
			if not DBMod.PlayerFrames.global then DBMod.PlayerFrames.global = {Auras = Auras}; end
			if not DB.BuffSettings.disableblizz then DB.BuffSettings.disableblizz = true; end
			if not DB.XPBar.enabled then DB.XPBar.enabled = true; end
			if not DB.RepBar.enabled then DB.RepBar.enabled = true; end
			if not DBMod.RaidFrames.threat then DBMod.RaidFrames.threat = true end
			if not DBMod.PartyFrames.threat then DBMod.PartyFrames.threat = true end
		end
		if (DB.Version < "3.1.3") then -- DB Updates for 3.1.3
			spartan:Print(L["DBUpdate"].." 3.1.3 "..L["settings"])
			if DBMod.RaidFrames.maxColumns == 8 then DBMod.RaidFrames.maxColumns = 4 end
			if DBMod.RaidFrames.unitsPerColumn == 5 then DBMod.RaidFrames.unitsPerColumn = 10 end
		end
		if (DB.Version < "3.2.1") then -- DB Updates for 3.1.3
			spartan:Print(L["DBUpdate"].." 3.2.1 "..L["settings"])
			if not DBMod.PlayerFrames.AltManaBar then
				DBMod.PlayerFrames.AltManaBar = {movement={moved=false;point = "",relativeTo = "",relativePoint = "",xOffset = 0,yOffset = 0}}
			end
			if not DBMod.PlayerFrames.ClassBar then
				DBMod.PlayerFrames.ClassBar = {movement={moved=false;point = "",relativeTo = "",relativePoint = "",xOffset = 0,yOffset = 0}}
			end
			if not DBMod.PlayerFrames.focus.movement then
				DBMod.PlayerFrames.focus = {movement={moved=DBMod.PlayerFrames.focus.moved;point = "",relativeTo = "",relativePoint = "",xOffset = 0,yOffset = 0}}
			end
			if not DBMod.PlayerFrames.BossFrame.movement then
				DBMod.PlayerFrames.BossFrame.movement = {moved=false,point = "",relativeTo = "",relativePoint = "",xOffset = 0,yOffset = 0}
				DBMod.PlayerFrames.BossFrame.display = true;
			end
			if not DBMod.PlayerFrames.ArenaFrame.movement then
				DBMod.PlayerFrames.ArenaFrame.movement = {moved=false,point = "",relativeTo = "",relativePoint = "",xOffset = 0,yOffset = 0}
			end
			if DBMod.PlayerFrames.showClass == nil then DBMod.PlayerFrames.showClass = true end
			if DBMod.RaidFrames.showClass == nil then DBMod.RaidFrames.showClass = true end
			if DBMod.PartyFrames.showClass == nil then DBMod.PartyFrames.showClass = true end
		end
		if (DB.Version < "3.3.0") then
			if not DBMod.PlayerFrames.Portrait3D then DBMod.PlayerFrames.Portrait3D = false end
			if not DBMod.PartyFrames.Portrait3D then DBMod.PartyFrames.Portrait3D = false end
			if not DBMod.PartyFrames.HideBlizzFrames then DBMod.PartyFrames.HideBlizzFrames = true end
			
			if not DB.MiniMap.ManualAllowUse then DB.MiniMap.ManualAllowUse = false end
			if not DB.MiniMap.ManualAllowPrompt then DB.MiniMap.ManualAllowUse = "" end
			if not DB.MiniMap.AutoDetectAllowUse then DB.MiniMap.AutoDetectAllowUse = true end
		end
	end
end

function module:OnEnable()
	-- First Launch Notication
	if (not DBGlobal.Version) then
		spartan.db:ResetProfile(false,true);
		StaticPopup_Show ("FirstLaunchNotice")
	end
	-- No Bartender/out of date Notification
	if (not select(4, GetAddOnInfo("Bartender4")) and (DBGlobal.BartenderInstallWarning ~= SpartanVer)) then
		if SpartanVer ~= DBGlobal.Version then StaticPopup_Show ("BartenderInstallWarning") end
	elseif Bartender4Version < BartenderMin then
			if SpartanVer ~= DBGlobal.Version then StaticPopup_Show ("BartenderVerWarning") end
	end
	-- MiniMap Modification
	if (((not DB.MiniMap.AutoDetectAllowUse) and (not DB.MiniMap.ManualAllowUse)) and DB.MiniMap.ManualAllowPrompt ~= DB.Version) then
		StaticPopup_Show("MiniMapNotice")
	end
	--Alpha Warning
	if (CurseVersion) then
		if (DBGlobal.AlphaWarning ~= CurseVersion) and (CurseVersion ~= SpartanVer) then
			spartan:Print("Curse Version: "..CurseVersion);
			spartan:Print("Spartan Version: "..SpartanVer);
			StaticPopup_Show ("AlphaWarning")
		end
	end
	
	-- Update DB Version
	DB.Version = SpartanVer;
	DBGlobal.Version = SpartanVer;
end