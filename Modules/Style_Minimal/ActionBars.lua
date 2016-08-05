local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = addon:GetModule("Artwork_Core");
local module = addon:GetModule("Style_Minimal");
----------------------------------------------------------------------------------------------------
local ProfileName = DB.Styles.Minimal.BartenderProfile;

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
	Artwork_Core:SetupProfile()
end;

function module:CreateProfile()
	Artwork_Core:CreateProfile()
end

function module:InitActionBars()
	do -- create Top bar anchor
		plate = CreateFrame("Frame","Minimal_TopBarPlate",Minimal_AnchorFrame,"Minimal_ActionBarsTemplate");
		plate:SetFrameStrata("BACKGROUND");
		plate:SetFrameLevel(1);
		plate:SetPoint("TOP", Minimal_AnchorFrame, "TOP");
	end
end

function module:EnableActionBars()

end