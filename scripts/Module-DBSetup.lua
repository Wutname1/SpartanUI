local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = spartan:NewModule("DBSetup");
local Bartender4Version, BartenderMin = "","4.5.1"
if select(4, GetAddOnInfo("Bartender4")) then Bartender4Version = GetAddOnMetadata("Bartender4", "Version") end

function module:OnInitialize()
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
	
	-- DB Updates for 3.0.2 to 3.0.3
	if DBGlobal.Version then
		if DB.Version == nil and DBGlobal.Version <= "3.0.4" then
			-- spartan:Print("Converting DB from 3.0.2 settings")
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
			
			DB.Version = SpartanVer;
		end
	end
end

function module:OnEnable()
	if (not DBGlobal.Version) then
		spartan.db:ResetProfile(false,true);
		StaticPopup_Show ("FirstLaunchNotice")
	end
	if (not select(4, GetAddOnInfo("Bartender4")) and (DBGlobal.BartenderInstallWarning ~= SpartanVer)) then
		if SpartanVer ~= DBGlobal.Version then StaticPopup_Show ("BartenderInstallWarning") end
	elseif Bartender4Version < BartenderMin then
			if SpartanVer ~= DBGlobal.Version then StaticPopup_Show ("BartenderVerWarning") end
	end
	DBGlobal.Version = SpartanVer;
end