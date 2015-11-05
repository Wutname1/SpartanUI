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
		BartenderProfile = "SpartanUI - Transparent",
		TooltipLoc = true
	}
end

--Update from old versions
if DB.Styles.Transparent.TooltipLoc == nil then DB.Styles.Transparent.TooltipLoc = true end
