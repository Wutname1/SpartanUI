local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = spartan:NewModule("DBSetup");
local Bartender4Version, BartenderMin = "","4.5.1"
if select(4, GetAddOnInfo("Bartender4")) then Bartender4Version = GetAddOnMetadata("Bartender4", "Version") end

function module:OnInitialize()
	-- Below is not used keeping for refrence
	-- StaticPopupDialogs["AlphaNotice"] = {
		-- text = '|cff33ff99SpartanUI|r|nv '..GetAddOnMetadata("SpartanUI", "Version")..'|n|r|n|nIt'.."'"..'s recomended to reset |cff33ff99SpartanUI|r.|n|nClick "|cff33ff99Yes|r" to Reset |cff33ff99SpartanUI|r & ReloadUI.|n|nAfter this you will need to setup |cff33ff99SpartanUI'.."'"..'s|r custom settings again.|n|nDo you want to reset & ReloadUI ?',
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
	StaticPopupDialogs["DBNotice"] = {
		text = '|cff33ff99SpartanUI v'..GetAddOnMetadata("SpartanUI", "Version")..'|n|r|n|nSettings are no longer done with slash commands they are now accessed by typing /sui|n|n|nReturning users:|n|rAll settings have been reset|n(Sorry had to be done)',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.Version = GetAddOnMetadata("SpartanUI", "Version");
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["BartenderVerWarning"] = {
		text = '|cff33ff99SpartanUI v'..GetAddOnMetadata("SpartanUI", "Version")..'|n|r|n|nWarning: Your bartender version of '..Bartender4Version..' may be out of date.|n|nSpartanUI requires '..BartenderMin..' or higher.',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.Version = GetAddOnMetadata("SpartanUI", "Version");
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["BartenderInstallWarning"] = {
		text = '|cff33ff99SpartanUI v'..GetAddOnMetadata("SpartanUI", "Version")..'|n|r|n|nWarning: Bartender not detected|nUI Issues may be experienced.',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.BartenderInstallWarning = GetAddOnMetadata("SpartanUI", "Version")
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	
end

function module:OnEnable()
	if (not DBGlobal.Version) then
		spartan.db:ResetProfile(false,true);
		StaticPopup_Show ("DBNotice")
	end
	if (Bartender4Version ~= "") and (Bartender4Version ~= nil) then
		if Bartender4Version < BartenderMin then
			StaticPopup_Show ("BartenderVerWarning")
		end
	elseif (not select(4, GetAddOnInfo("Bartender4")) and (DBGlobal.BartenderInstallWarning ~= GetAddOnMetadata("SpartanUI", "Version"))) then
			StaticPopup_Show ("BartenderInstallWarning")
	end
end