local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PartyFrames = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------

function PartyFrames:OnEnable()
	if (DBMod.PartyFrames.Style == "theme") and (DBMod.Artwork.Style ~= "Classic") then
		spartan.PFrame = spartan:GetModule("Style_" .. DBMod.Artwork.Style):PartyFrames();
	elseif (DBMod.PartyFrames.Style == "Classic") or (DBMod.Artwork.Style == "Classic") then
		spartan.PFrame = PartyFrames:Classic()
	elseif (DBMod.PartyFrames.Style == "plain") then
		spartan.PFrame = PartyFrames:Plain();
	else
		spartan.PFrame = spartan:GetModule("Style_" .. DBMod.PartyFrames.Style):PartyFrames();
	end
end