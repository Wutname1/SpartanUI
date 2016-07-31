local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
----------------------------------------------------------------------------------------------------

--First Lets make the Module
local module = spartan:NewModule("Style_Transparent");

--Now lets setup the initial Database settings
if DB.Styles.Transparent.BartenderProfile == nil then
	DB.Styles.Transparent = {
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
		Color = {
		Art = {0,.8,.9,.7},
		PlayerFrames = {0,.8,.9,.7},
		PartyFrames = {0,.8,.9,.7},
		RaidFrames = {0,.8,.9,.7}
		},
		TalkingHeadUI = { point = "BOTTOM", relPoint = "TOP", x = 0, y = -30, scale = .8 },
		BartenderProfile = "SpartanUI - Transparent",
		TooltipLoc = true,
		BuffLoc = true
	}
end
if DB.Styles.Transparent.Color == nil then
	DB.Styles.Transparent.Color = {
		Art = {0,.8,.9,.7},
		PlayerFrames = {0,.8,.9,.7},
		PartyFrames = {0,.8,.9,.7},
		RaidFrames = {0,.8,.9,.7}
	}
end
if DB.Styles.Transparent.TalkingHeadUI == nil then
	DB.Styles.Transparent.TalkingHeadUI = {
		point = "BOTTOM",
		relPoint = "TOP",
		x = 0,
		y = -30,
		scale = .8
	}
end

--Update from old versions
if DB.Styles.Transparent.TooltipLoc == nil then DB.Styles.Transparent.TooltipLoc = true end
if DB.Styles.Transparent.BuffLoc == nil then DB.Styles.Transparent.BuffLoc = true end
