local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Minimal");
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	spartan.opt.args["General"].args["style"].args["OverallStyle"].args["Minimal"].disabled = false
	spartan.opt.args["General"].args["style"].args["Artwork"].args["Minimal"].disabled = false
	spartan.opt.args["General"].args["style"].args["PlayerFrames"].args["Minimal"].disabled = false
	spartan.opt.args["General"].args["style"].args["PartyFrames"].args["Minimal"].disabled = false
	spartan.opt.args["General"].args["style"].args["RaidFrames"].args["Minimal"].disabled = false
	if (DBMod.Artwork.Style == "Minimal") then
		module:Init()
	end
end

function module:Init()
	if DB.Styles.Minimal == nil then DB.Styles.Minimal = {} end
	if DB.Styles.Minimal.Color == nil then
		DB.Styles.Minimal.Color = {
			0.6156862745098039,
			0.1215686274509804,
			0.1215686274509804,
			0.9
		}
	end
	
	if (DBMod.Artwork.FirstLoad) then module:FirstLoad() end
	module:SetupMenus();
	module:InitFramework();
	module:InitActionBars();
	InitRan = true;
end

function module:FirstLoad()
	--If our profile exists activate it.
	if ((Bartender4.db:GetCurrentProfile() ~= DB.Styles.Minimal.BartenderProfile) and module:BartenderProfileCheck(DB.Styles.Minimal.BartenderProfile,true)) then Bartender4.db:SetProfile(DB.Styles.Minimal.BartenderProfile); end
end

function module:OnEnable()
	if (DBMod.Artwork.Style ~= "Minimal") then module:Disable(); return end
	if (DBMod.Artwork.Style == "Minimal") then
		if (not InitRan) then module:Init(); end
		if (not module:BartenderProfileCheck(DB.Styles.Minimal.BartenderProfile,true)) then module:CreateProfile(); end
		module:EnableFramework();
		module:EnableActionBars();
		if (DBMod.Artwork.FirstLoad) then DBMod.Artwork.FirstLoad = false end -- We want to do this last
	end
end

function module:SetupMenus()
	if (DBMod.Artwork.Style == "Minimal") then
		spartan.opt.args["Artwork"].args["Art"] = {name = L["ArtworkOpt"],type="group",order=10,
			args = {
				alpha = {name=L["ArtColor"],type="color",hasAlpha=true,order=1,width="full",desc=L["TransparencyDesc"],
					get = function(info) return unpack(DB.Styles.Minimal.Color) end,
					set = function(info,r,b,g,a) DB.Styles.Minimal.Color = {r,b,g,a}; module:SetColor(); end
				}
			}
		}
	end
end

function module:OnDisable()
	Minimal_SpartanUI:Hide();
	Minimal_AnchorFrame:Hide();
end