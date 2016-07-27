local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
----------------------------------------------------------------------------------------------------

--First Lets make the Module
local module = spartan:NewModule("Style_Fel");

--Now lets setup the initial Database settings
if DB.Styles.Fel.BartenderProfile == nil then
	DB.Styles.Fel = {
		Artwork = {},
		PlayerFrames = {},
		PartyFrames = {},
		RaidFrames = {},
		Movable = {
			Minimap = false,
			PlayerFrames = true,
			PartyFrames = true,
			RaidFrames = true,
		},
		Minimap = {
			shape = "square",
			size = {width = 140, height = 140}
		},
		TalkingHeadUI = {
			point = "BOTTOM",
			relPoint = "TOP",
			x = 0,
			y = -30,
			scale = .8
		},
		BartenderProfile = "SpartanUI - Fel",
		TooltipLoc = true,
		BuffLoc = true
	}
end
