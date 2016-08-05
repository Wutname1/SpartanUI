local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Fel");
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	--Enable the in the Core options screen
	spartan.opt.args["General"].args["style"].args["OverallStyle"].args["Fel"].disabled = false
	spartan.opt.args["General"].args["style"].args["Artwork"].args["Fel"].disabled = false
	spartan.opt.args["General"].args["style"].args["PlayerFrames"].args["Fel"].disabled = false
	spartan.opt.args["General"].args["style"].args["PartyFrames"].args["Fel"].disabled = false
	spartan.opt.args["General"].args["style"].args["RaidFrames"].args["Fel"].disabled = false
	--Init if needed
	if (DBMod.Artwork.Style == "Fel") then module:Init() end
end

function module:Init()
	if (DBMod.Artwork.FirstLoad) then module:FirstLoad() end
	module:SetupMenus();
	module:InitArtwork();
	InitRan = true;
end

function module:FirstLoad()
	--If our profile exists activate it.
	if ((Bartender4.db:GetCurrentProfile() ~= DB.Styles.Fel.BartenderProfile) and Artwork_Core:BartenderProfileCheck(DB.Styles.Fel.BartenderProfile,true)) then Bartender4.db:SetProfile(DB.Styles.Fel.BartenderProfile); end
end

function module:OnEnable()
	if (DBMod.Artwork.Style ~= "Fel") then
		module:Disable(); 
	else
		if (not InitRan) then module:Init(); end
		if (not Artwork_Core:BartenderProfileCheck(DB.Styles.Fel.BartenderProfile,true)) then module:CreateProfile(); end
		module:EnableArtwork();
		
		if (DBMod.Artwork.FirstLoad) then DBMod.Artwork.FirstLoad = false end -- We want to do this last
	end
end

function module:OnDisable()
	Fel_SpartanUI:Hide();
end

function module:SetupMenus()


end