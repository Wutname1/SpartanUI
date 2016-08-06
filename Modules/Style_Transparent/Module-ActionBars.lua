local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = addon:GetModule("Artwork_Core");
local module = addon:GetModule("Style_Transparent");
----------------------------------------------------------------------------------------------------
local ProfileName = DB.Styles.Transparent.BartenderProfile;
local BartenderSettings = DB.Styles.Transparent.BartenderSettings;

local default, plate = {
	popup1 = {alpha = 1, enable = 1},
	popup2 = {alpha = 1, enable = 1},
	bar1 = {alpha = 1, enable = 1},
	bar2 = {alpha = 1, enable = 1},
	bar3 = {alpha = 1, enable = 1},
	bar4 = {alpha = 1, enable = 1},
	bar5 = {alpha = 1, enable = 1},
	bar6 = {alpha = 1, enable = 1},
};

function module:SetupProfile()
	--If this is set then we have already setup the bars once, and the user changed them
	if DB.Styles.Transparent.BT4Profile and DB.Styles.Transparent.BT4Profile ~= ProfileName then return end
	
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo("Bartender4"))) then return; end
	
	-- Set/Create our Profile
	Bartender4.db:SetProfile(ProfileName);
	
	--Load the Profile Data
	for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = Artwork_Core:MergeData(v.db.profile,BartenderSettings[k])
		end
	end
end;

function module:CreateProfile()
	--If this is set then we have already setup the bars once, and the user changed them
	if DB.Styles.Transparent.BT4Profile and DB.Styles.Transparent.BT4Profile ~= ProfileName then return end
	
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo("Bartender4"))) then return; end
	
	-- Set/Create our Profile
	Bartender4.db:SetProfile(ProfileName);
	
	--Load the Profile Data
	for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = Artwork_Core:MergeData(v.db.profile,BartenderSettings[k])
		end
	end
	
	Bartender4:UpdateModuleConfigs();
end

function module:InitActionBars()
	--if (Bartender4.db:GetCurrentProfile() == DB.Styles.Transparent.BartenderProfile or not Artwork_Core:BartenderProfileCheck(DB.Styles.Transparent.BartenderProfile,true)) then
	Artwork_Core:ActionBarPlates("Transparent_ActionBarPlate");
	--end

	do -- create bar anchor
		plate = CreateFrame("Frame","Transparent_ActionBarPlate",Transparent_SpartanUI,"Transparent_ActionBarsTemplate");
		plate:SetFrameStrata("BACKGROUND");
		plate:SetFrameLevel(1);
		plate:SetPoint("BOTTOM");
	end
end

function module:EnableActionBars()
	do -- modify strata / levels of backdrops
		for i = 1,6 do
			_G["Transparent_Bar"..i]:SetFrameStrata("BACKGROUND");
			_G["Transparent_Bar"..i]:SetFrameLevel(3);
		end
		for i = 1,2 do
			_G["Transparent_Popup"..i]:SetFrameStrata("BACKGROUND");
			_G["Transparent_Popup"..i]:SetFrameLevel(3);
		end
	end
	
	-- Do what Bartender isn't - Make the Bag buttons the same size
	do -- modify CharacterBag(0-3) Scale
		for i = 1,4 do
			_G["CharacterBag"..(i-1).."Slot"]:SetScale(1.25);
		end
	end
end