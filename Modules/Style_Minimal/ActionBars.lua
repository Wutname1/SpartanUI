local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = addon:GetModule("Artwork_Core");
local module = addon:GetModule("Style_Minimal");
----------------------------------------------------------------------------------------------------
local ProfileName = DB.Styles.Minimal.BartenderProfile;
local BartenderSettings = { -- actual settings being inserted into our custom profile
	ActionBars = {
		actionbars = { -- following settings are bare minimum, so that anything not defined is retained between resets
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "BOTTOM",		x=-200,	y=102,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 1
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "BOTTOM",		x=-200,	y=70,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 2
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "BOTTOM",		x=-200,	y=35,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 3
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {										scale = 0.85,	growHorizontal="RIGHT"}}, -- 4
			{enabled = true,	buttons = 12,	rows = 3,	padding = 3,	skin = {Zoom = true},	position = {point = "BOTTOM",		x=-317,	y=98,	scale = 0.75,	growHorizontal="RIGHT"}}, -- 5
			{enabled = true,	buttons = 12,	rows = 3,	padding = 3,	skin = {Zoom = true},	position = {point = "BOTTOM",		x=199,	y=98,	scale = 0.75,	growHorizontal="RIGHT"}}, -- 6
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {										scale = 0.85,	growHorizontal="RIGHT"}}, -- 7
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {										scale = 0.85,	growHorizontal="RIGHT"}}, -- 8
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {										scale = 0.85,	growHorizontal="RIGHT"}}, -- 9
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {										scale = 0.85,	growHorizontal="RIGHT"}} -- 10
		}
	},
	BagBar			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true, padding = 0, 		position = {point = "TOP",			x=490,	y=-1,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1, onebag = false, keyring = true},
	MicroMenu		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,	padding = -3,		position = {point = "TOP",			x=160,	y=-1,	scale = 0.70,	growHorizontal="RIGHT"}},
	PetBar			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true, padding = 1, 		position = {point = "TOP",			x=-492,	y=-1,	scale = 0.70,	growHorizontal="RIGHT"},	rows = 1, skin = {Zoom = true}},
	StanceBar		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,	padding = 1, 		position = {point = "TOP",			x=-163,	y=-1,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1},
	MultiCast		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,						position = {point = "TOPRIGHT",			x=-777,	y=-4,	scale = 0.75}},
	Vehicle			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = false,	padding = 3,	position = {point = "BOTTOM",			x=-200,	y=155,	scale = 0.85}},
	ExtraActionBar	= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,						position = {point = "BOTTOM",			x=-32,	y=275}},
	BlizzardArt		= {	enabled = false,	},
	blizzardVehicle = true
};

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
	if DB.Styles.Transparent.BT4Profile then return end
	
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo("Bartender4"))) then return; end
	
	-- Set/Create our Profile
	Bartender4.db:SetProfile(ProfileName);
	
	--Load the Profile Data
	for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = module:MergeData(v.db.profile,BartenderSettings[k])
		end
	end
end;

function module:CreateProfile()
	--If this is set then we have already setup the bars once, and the user changed them
	if DB.Styles.Transparent.BT4Profile then return end
	
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo("Bartender4"))) then return; end
	
	-- Set/Create our Profile
	Bartender4.db:SetProfile(ProfileName);
	
	--Load the Profile Data
	for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = module:MergeData(v.db.profile,BartenderSettings[k])
		end
	end
	
	Bartender4:UpdateModuleConfigs();
end

function module:BartenderProfileCheck(Input,Report)
	local profiles, r = Bartender4.db:GetProfiles(), false
	for k,v in pairs(profiles) do
		if v == Input then r = true end
	end
	if (Report) and (r ~= true) then
		addon:Print(Input.." "..L["BartenderProfileCheckFail"])
	end
	return r
end

function module:MergeData(target,source)
	if type(target) ~= "table" then target = {} end
	for k,v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:MergeData(target[k], v);
		else
			target[k] = v;
		end
	end
	return target;
end

function module:InitActionBars()
	--if (Bartender4.db:GetCurrentProfile() == DB.Styles.Minimal.BartenderProfile or not module:BartenderProfileCheck(DB.Styles.Minimal.BartenderProfile,true)) then
	-- Artwork_Core:ActionBarPlates("Minimal_ActionBarPlate");
	--end

	do -- create Bottom bar anchor
		-- plate = CreateFrame("Frame","Minimal_ActionBarPlate",Minimal_SpartanUI,"Minimal_ActionBarsTemplate");
		-- plate:SetFrameStrata("BACKGROUND"); plate:SetFrameLevel(1);
		-- plate:SetPoint("BOTTOM", Minimal_AnchorFrame);
	end
	do -- create Top bar anchor
		plate = CreateFrame("Frame","Minimal_TopBarPlate",Minimal_AnchorFrame,"Minimal_ActionBarsTemplate");
		plate:SetFrameStrata("BACKGROUND");
		plate:SetFrameLevel(1);
		plate:SetPoint("TOP", Minimal_AnchorFrame, "TOP");
	end
end

function module:EnableActionBars()
	--module:SetupProfile();
end