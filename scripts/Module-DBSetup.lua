local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = spartan:NewModule("DBSetup");
local Bartender4Version, BartenderMin = "","4.5.3"
if select(4, GetAddOnInfo("Bartender4")) then Bartender4Version = GetAddOnMetadata("Bartender4", "Version") end
local CurseVersion = GetAddOnMetadata("SpartanUI", "X-Curse-Packaged-Version")

function module:OnInitialize()
	--spartan.ChangeLog.args["autoOpen"]={name="Auto open on new version",type="description",fontSize="large",order=1}
	-- spartan.ChangeLog.args["301"]={name="v3.0.1",type="description",fontSize="large",order=500}
	-- spartan.ChangeLog.args["301d"]={name="Inital MOP Release updating TOC files and major functionality bug fixes",type="description",order=500.5}
	-- spartan.ChangeLog.args["302"]={name="v3.0.2",type="description",fontSize="large",order=499}
	-- spartan.ChangeLog.args["302d"]={name="New: Bartender install detection|nNew: Bartender out of date detection|nNew: Revamped Database storing system|nNew: custom Colors for XP and Rep|nNew: Manual Spin Cam Speed|nRemoved: All slash commands except /sui and /sui version|nImproved: Settings are now done via UI and not chat commands, you can access settings with /sui or in the WoW interface menu|nImproved: Party Pet Frame size reduced|nImproved: Backed Database is now account wide as opposed to per character|nNew/Improved: All SpartanUI Components now all use 1 database for settings",type="description",order=499.5}
	-- spartan.ChangeLog.args["303"]={name="v3.0.3",type="description",fontSize="large",order=498}
	-- spartan.ChangeLog.args["303d"]={name="New: SpartanUI will hide when in pet battles.|nNew: Tool tips for Rep and XP Bars|nNew: text displayed on top of the Rep and XP Bars|nNew: Disable or enable every unit frame|nNew: Dual Spec Support, setup different profiles based on spec.",type="description",order=498.5}
	-- spartan.ChangeLog.args["305a"]={name="v3.0.5a",type="description",fontSize="large",order=497}
	-- spartan.ChangeLog.args["305ad"]={name="New: Font Settings|n- Adjust font size|n- Change font type|n- Change font Style|nNew: Rep/XP Bar tooltip on Click|nNew: Chocolate Bar Detection|nNew/Improved: Health Bars colored by amount of health remaining|n- Not Available on All bars yet|nNew: Hide buffs and Debuffs not applied by you.|n- Only on Target frame. Other frames will be available in 3.1|nImproved: Short Health Display|nImproved: Health Display Update Method|nFixed: Offset for Cords|nFixed: Vehicle UI Hiding|nFixed: Titan Panel Detection|nFixed: Rep Bar Text Display",type="description",order=497.5}
	-- Below is not used keeping for refrence
	-- StaticPopupDialogs["AlphaNotice"] = {
		-- text = '|cff33ff99SpartanUI|r|nv '..SpartanVer..'|n|r|n|nIt'.."'"..'s recomended to reset |cff33ff99SpartanUI|r.|n|nClick "|cff33ff99Yes|r" to Reset |cff33ff99SpartanUI|r & ReloadUI.|n|nAfter this you will need to setup |cff33ff99SpartanUI'.."'"..'s|r custom settings again.|n|nDo you want to reset & ReloadUI ?',
		-- button1 = "|cff33ff99Yes|r",
		-- button2 = "No",
		-- OnAccept = function()
			-- ReloadUI();
		-- end,
		-- OnCancel = function (_,reason)
			-- spartan:Print("Leaving old profile intact by user's choice, issues might occur due to this.")
		-- end,
		-- sound = "igPlayerInvite",
		-- timeout = 0,
		-- whileDead = true,
		-- hideOnEscape = false,
	-- }
	StaticPopupDialogs["FirstLaunchNotice"] = {
		text = '|cff33ff99SpartanUI v'..SpartanVer..'|n|r|n|nSettings are no longer done with slash commands they are now accessed by typing /sui|n|n',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.Version = SpartanVer;
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["BartenderVerWarning"] = {
		text = '|cff33ff99SpartanUI v'..SpartanVer..'|n|r|n|nWarning: Your bartender version of '..Bartender4Version..' may be out of date.|n|nSpartanUI requires '..BartenderMin..' or higher.',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.BartenderVerWarning = SpartanVer;
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["BartenderInstallWarning"] = {
		text = '|cff33ff99SpartanUI v'..SpartanVer..'|n|r|n|nWarning: Bartender not detected|nUI Issues may be experienced.',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.BartenderInstallWarning = SpartanVer
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["AlphaWarning"] = {
		text = '|cff33ff99SpartanUI Alpha '..CurseVersion..'|n|r|n|nWarning: Alpha version detected|n|nThank you for your help in testing SpartanUI. Please report any issues experienced.|n|nThis is an Alpha Build for 3.1.0|n|n',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.AlphaWarning = SpartanVer
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	
	-- DB Updates
	if DBGlobal.Version then
		if DB.Version == nil then -- DB Updates from 3.0.2 to 3.0.3 this variable was not set in 3.0.2
			spartan:Print("DB updated from 3.0.2 settings")
			unitlist = {player=0,target=0,targettarget=0,pet=0,focus=0,focustarget=0};
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
			spartan:Print("DB updated from 3.0.3 settings")
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
			spartan:Print("DB updated from 3.0.5 settings")
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
			if not spartan.db.char.Version then spartan:Print("Setup char DB"); spartan.db.char = DBdefault; spartan.db.char.Version = SpartanVer; end
			if not spartan.db.realm.Version then spartan:Print("Setup realm DB"); spartan.db.realm = DBdefault; spartan.db.realm.Version = SpartanVer; end
			if not spartan.db.class.Version then spartan:Print("Setup class DB"); spartan.db.class = DBdefault; spartan.db.class.Version = SpartanVer; end
		end
	end
end

function module:OnEnable()
	DBGlobal.AlphaWarning = nil
	if (not DBGlobal.Version) then
		spartan:Print("Welcome to SpartanUI")
		spartan.db:ResetProfile(false,true);
		StaticPopup_Show ("FirstLaunchNotice")
	end
	if (not select(4, GetAddOnInfo("Bartender4")) and (DBGlobal.BartenderInstallWarning ~= SpartanVer)) then
		if SpartanVer ~= DBGlobal.Version then StaticPopup_Show ("BartenderInstallWarning") end
	elseif Bartender4Version < BartenderMin then
			if SpartanVer ~= DBGlobal.Version then StaticPopup_Show ("BartenderVerWarning") end
	end
	DB.Version = SpartanVer;
	DBGlobal.Version = SpartanVer;
	if (CurseVersion) then
		if (DBGlobal.AlphaWarning ~= CurseVersion) and (CurseVersion ~= SpartanVer) then
			StaticPopup_Show ("AlphaWarning")
		end
	end
end