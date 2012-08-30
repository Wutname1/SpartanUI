
StaticPopupDialogs["AlphaNotise"] = {
	text = '|cff33ff99SpartanUI|r|nv '..GetAddOnMetadata("SpartanUI", "Version")..'|n|r|n|nIt'.."'"..'s recomended to reset |cff33ff99SpartanUI|r.|n|nClick "|cff33ff99Yes|r" to Reset |cff33ff99SpartanUI|r & ReloadUI.|n|nAfter this you will need to setup |cff33ff99SpartanUI'.."'"..'s|r custom settings again.|n|nDo you want to reset & ReloadUI ?',
	button1 = "|cff33ff99Yes|r",
	button2 = "No",
	OnAccept = function()
		ReloadUI();
	end,
	OnCancel = function (_,reason)
		spartan:Print("Leaving old profile intact by user's choice, issues might occur due to this.")
	end,
	sound = "igPlayerInvite",
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
}

StaticPopupDialogs["Notise"] = {
	text = '|cff33ff99SpartanUI|r|nv '..GetAddOnMetadata("SpartanUI", "Version")..'|n|r|n|nUser attention required|n|nClick "Read" when ready',
	button1 = "Read",
	OnAccept = function()
		StaticPopup_Show ("AlphaNotise")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
}

if (event == 'PLAYER_ENTERING_WORLD') then if DB.Version ~= GetAddOnMetadata("SpartanUI", "Version"); then
	StaticPopup_Show ("Notise")
	DB.Version = GetAddOnMetadata("SpartanUI", "Version");
end