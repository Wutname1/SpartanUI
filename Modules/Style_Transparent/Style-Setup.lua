local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
----------------------------------------------------------------------------------------------------

--First Lets make the Module
local module = spartan:NewModule("Style_Transparent");

--Now lets setup the initial Database settings
if DB.Styles.Transparent == nil then
	DB.Styles.Transparent = {
		Artwork = true,
		PlayerFrames = true,
		PartyFrames = true,
		RaidFrames = false,
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
		BartenderProfile = "SpartanUI - Transparent"
	}
end

--Update from old versions
if DB.Styles.Transparent.Movable == nil or DB.Styles.Transparent.Movable then
	DB.Styles.Transparent.Movable = {
		Minimap = Minimap,
		PlayerFrames = true,
		PartyFrames = true,
		RaidFrames = true,
	}
end
if DB.Styles.Transparent.Minimap == nil then
	DB.Styles.Transparent.Minimap = {
		shape = "square",
		size = {width = 140, height = 140}
	}
end