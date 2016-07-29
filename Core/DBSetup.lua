local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:NewModule("DBSetup");
---------------------------------------------------------------------------
local Bartender4Version, BartenderMin = "","4.6.10"
if select(4, GetAddOnInfo("Bartender4")) then Bartender4Version = GetAddOnMetadata("Bartender4", "Version") end
if (spartan.CurseVersion == nil) then spartan.CurseVersion = "" end

function module:OnInitialize()
	StaticPopupDialogs["BartenderVerWarning"] = {
		text = '|cff33ff99SpartanUI v'..spartan.SpartanVer..'|n|r|n|n'..L["Warning"]..': '..L["BartenderOldMSG"]..' '..Bartender4Version..'|n|nSpartanUI requires '..BartenderMin..' or higher.',
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.BartenderVerWarning = spartan.SpartanVer;
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["BartenderInstallWarning"] = {
		text = '|cff33ff99SpartanUI v'..spartan.SpartanVer..'|n|r|n|n'..L["Warning"]..': '..L["BartenderNotFoundMSG1"]..'|n'..L["BartenderNotFoundMSG2"],
		button1 = "Ok",
		OnAccept = function()
			DBGlobal.BartenderInstallWarning = spartan.SpartanVer
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
	spartan:DBUpdates()
end

function spartan:DBUpdates()
	if DBGlobal.Version then
		if (DB.Version < "4.0.0") then
			if DBMod.PlayerFrames.ClassBar.scale == nil then DBMod.PlayerFrames.ClassBar.scale = 1 end
			if DB.MiniMap.northTag == nil then DB.MiniMap.northTag = false end
			-- if DB.MiniMap.frames == nil then DB.MiniMap.frames = {} end
			-- if DB.MiniMap.IgnoredFrames == nil then DB.MiniMap.IgnoredFrames = {} end
			if DB.MiniMap.SUIMapChangesActive == nil then DB.MiniMap.SUIMapChangesActive = false end
			if DB.MiniMap.Moved == nil then
				DB.MiniMap.Shape = "square"
				DB.MiniMap.Moved = false
				DB.MiniMap.Position = nil
			end
			if DB.Styles.Classic.Artwork == true then
				DB.Styles.Classic.Artwork = {}
				DB.Styles.Classic.PlayerFrames = {}
				DB.Styles.Classic.PartyFrames = {}
				DB.Styles.Classic.RaidFrames = {}
			end
			if DB.Styles.Classic.Movable == nil then
				DB.Styles.Classic.Movable = {
					Minimap = false,
					PlayerFrames = true,
					PartyFrames = true,
					RaidFrames = true,
				}
			end
			if DB.Styles.Classic.Minimap == nil then
				Minimap = {
					shape = "circle",
					size = {width = 140, height = 140}
				}
			end
			if DB.MiniMap.MouseIsOver == nil then DB.MiniMap.MouseIsOver = false; end
			if DB.EnabledComponents == nil then DB.EnabledComponents = {} end
			if DBMod.PlayerFrames.Style == nil then DBMod.PlayerFrames.Style = DBMod.Artwork.Style; end
			if DBMod.PartyFrames.Style == nil then DBMod.PartyFrames.Style = DBMod.Artwork.Style; end
			if DBMod.RaidFrames.Style == nil then DBMod.RaidFrames.Style = DBMod.Artwork.Style; end
			if DBMod.PlayerFrames.PetPortrait == nil then DBMod.PlayerFrames.PetPortrait = true end
			if DBMod.PlayerFrames.ClassBar.scale == nil then DBMod.PlayerFrames.ClassBar.scale = 1 end
			if DBMod.PlayerFrames.Style == "theme" then DBMod.PlayerFrames.Style = DBMod.Artwork.Style end
			if DBMod.PlayerFrames.pet.moved == nil then
				DBMod.PlayerFrames.pet.moved=false
				DBMod.PlayerFrames.target.moved=false
				DBMod.PlayerFrames.targettarget.moved=false
				DBMod.PlayerFrames.focus.moved=false
				DBMod.PlayerFrames.focustarget.moved=false
				DBMod.PlayerFrames.player.moved=false
			end
			if DBMod.PlayerFrames.boss == nil then DBMod.PlayerFrames.boss.moved=false end
			if DBMod.RaidFrames.mode == "group" then DBMod.RaidFrames.mode = "GROUP" end
			if DB.MiniMap.OtherStyle == nil then DB.MiniMap.OtherStyle = "mouseover" end
			if DB.MiniMap.BlizzStyle == nil then DB.MiniMap.BlizzStyle = "mouseover" end
			if DBMod.RaidFrames.mode == "group" then DBMod.RaidFrames.mode = "GROUP" end
			if DBMod.RaidFrames.mode == "role" then DBMod.RaidFrames.mode = "ASSIGNEDROLE" end
			if DB.Styles.Classic.TooltipLoc == nil then DB.Styles.Classic.TooltipLoc = true end
		end
	end
end

function module:OnEnable()
	-- No Bartender/out of date Notification
	if (not select(4, GetAddOnInfo("Bartender4")) and (DBGlobal.BartenderInstallWarning ~= spartan.SpartanVer)) then
		if spartan.SpartanVer ~= DBGlobal.Version then StaticPopup_Show ("BartenderInstallWarning") end
	elseif Bartender4Version < BartenderMin then
			if spartan.SpartanVer ~= DBGlobal.Version then StaticPopup_Show ("BartenderVerWarning") end
	end
	-- MiniMap Modification
	if (((not DB.MiniMap.AutoDetectAllowUse) and (not DB.MiniMap.ManualAllowUse)) and DB.MiniMap.ManualAllowPrompt ~= DB.Version) then
		StaticPopup_Show("MiniMapNotice")
	end
	
	-- Update DB Version
	DB.Version = spartan.SpartanVer;
	DB.HVer = (string.gsub(string.gsub(spartan.CurseVersion, "%.", ""), "[0-9]", ""))
	DBGlobal.Version = spartan.SpartanVer;
end