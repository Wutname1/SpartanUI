local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = addon:GetModule("Artwork_Core");
local module = addon:GetModule("Style_Transparent");
----------------------------------------------------------------------------------------------------
local ProfileName = DB.Styles.Transparent.BartenderProfile;
local BartenderSettings = { -- actual settings being inserted into our custom profile
	ActionBars = {
		actionbars = { -- following settings are bare minimum, so that anything not defined is retained between resets
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Transparent_ActionBarPlate",	x=-501,	y=16,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 1
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Transparent_ActionBarPlate",	x=-501,	y=-29,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 2
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Transparent_ActionBarPlate",	x=98,	y=16,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 3
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Transparent_ActionBarPlate",	x=98,	y=-29,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 4
			{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Transparent_ActionBarPlate",	x=-635,	y=35,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 5
			{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Transparent_ActionBarPlate",	x=504,	y=35,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 6
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Transparent_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 7
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Transparent_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 8
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Transparent_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 9
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Transparent_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}} -- 10
		}
	},
	BagBar			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true, padding = 0, 		position = {point = "TOP",		parent = "Transparent_ActionBarPlate",	x=494,	y=-15,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1, onebag = false, keyring = true},
	MicroMenu		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,	padding = -3,		position = {point = "TOP",		parent = "Transparent_ActionBarPlate",	x=105,	y=-15,	scale = 0.70,	growHorizontal="RIGHT"}},
	PetBar			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true, padding = 1, 		position = {point = "TOP",		parent = "Transparent_ActionBarPlate",	x=-493,	y=-15,	scale = 0.70,	growHorizontal="RIGHT"},	rows = 1, skin = {Zoom = true}},
	StanceBar		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,	padding = 1, 		position = {point = "TOP",		parent = "Transparent_ActionBarPlate",	x=-105,	y=-15,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1},
	MultiCast		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,						position = {point = "TOPRIGHT",		parent = "Transparent_ActionBarPlate",	x=-777,	y=-4,	scale = 0.75}},
	Vehicle			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = false,	padding = 3,	position = {point = "CENTER",		parent = "Transparent_ActionBarPlate",	x=-15,	y=213,	scale = 0.85}},
	ExtraActionBar	= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,						position = {point = "CENTER",		parent = "Transparent_ActionBarPlate",	x=-32,	y=240}},
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
	--if (Bartender4.db:GetCurrentProfile() == DB.Styles.Transparent.BartenderProfile or not module:BartenderProfileCheck(DB.Styles.Transparent.BartenderProfile,true)) then
	Artwork_Core:ActionBarPlates("Transparent_ActionBarPlate");
	--end

	do -- create bar anchor
		plate = CreateFrame("Frame","Transparent_ActionBarPlate",Transparent_SpartanUI,"Transparent_ActionBarsTemplate");
		plate:SetFrameStrata("BACKGROUND");
		plate:SetFrameLevel(1);
		plate:SetPoint("BOTTOM");
	end
end

function module:EnableActionBars()
	do -- modify strata / levels of backdrops
		for i = 1,6 do
			_G["Transparent_Bar"..i]:SetFrameStrata("BACKGROUND");
			_G["Transparent_Bar"..i]:SetFrameLevel(3);
		end
		for i = 1,2 do
			_G["Transparent_Popup"..i]:SetFrameStrata("BACKGROUND");
			_G["Transparent_Popup"..i]:SetFrameLevel(3);
		end
	end
	
	-- Do what Bartender isn't - Make the Bag buttons the same size
	do -- modify CharacterBag(0-3) Scale
		for i = 1,4 do
			_G["CharacterBag"..(i-1).."Slot"]:SetScale(1.25);
		end
	end
end