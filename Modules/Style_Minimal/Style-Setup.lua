local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
----------------------------------------------------------------------------------------------------

--First Lets make the Module
local module = spartan:NewModule("Style_Minimal");

--Now lets setup the initial Database settings
if DB.Styles.Minimal == nil then
	DB.Styles.Minimal = {
		Artwork = {},
		PlayerFrames = {},
		PartyFrames = {},
		RaidFrames = {},
		Movable = {
			Minimap = true,
			PlayerFrames = true,
			PartyFrames = true,
			RaidFrames = true,
		},
		TooltipLoc = true,
		Minimap = {
			shape = "square",
			size = {width = 140, height = 140}
		},
		BartenderProfile = "SpartanUI - Minimal",
		Color = {
				0.6156862745098039,
				0.1215686274509804,
				0.1215686274509804,
				0.9
			},
		PartyFramesSize = "large"
	}
end

--Update from old versions
if DB.Styles.Minimal == true then
		DB.Styles.Minimal.Artwork = {}
		DB.Styles.Minimal.PlayerFrames = {}
		DB.Styles.Minimal.PartyFrames = {}
		DB.Styles.Minimal.RaidFrames = {}
end
if DB.Styles.Minimal.Movable == nil then
	DB.Styles.Minimal.Movable = {
		Minimap = true,
		PlayerFrames = true,
		PartyFrames = true,
		RaidFrames = true,
	}
end
if DB.Styles.Minimal.Minimap == nil then
	DB.Styles.Minimal.Minimap = {
		shape = "square",
		size = {width = 140, height = 140}
	}
end
if DB.Styles.Minimal.Color == nil then
	DB.Styles.Minimal.Color = {0.6156862745098039,0.1215686274509804,0.1215686274509804,0.9}
	DB.Styles.Minimal.PartyFramesSize = "large"
end
if DB.Styles.Minimal.PartyFramesSize == nil then DB.Styles.Minimal.PartyFramesSize = "large" end
if DB.Styles.Transparent.TooltipLoc == nil then DB.Styles.Classic.TooltipLoc = true end