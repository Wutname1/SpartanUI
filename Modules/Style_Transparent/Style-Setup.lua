local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
----------------------------------------------------------------------------------------------------
--First Lets make the Module
local module = spartan:NewModule("Style_Transparent");
local BartenderSettings = {
	ActionBars = {
		actionbars = {
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
	blizzardVehicle = DBMod.Artwork.VehicleUI
}

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
		TalkingHeadUI = { point = "TOP", relPoint = "TOP", x = 0, y = -30, scale = .8 },
		BartenderProfile = "SpartanUI - Transparent",
		BartenderSettings = BartenderSettings,
		TooltipLoc = true,
		BuffLoc = true
	}
end
if DB.Styles.Transparent.Color == nil or DB.Styles.Transparent.Color.Art == nil then
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
if DB.Styles.Transparent.BartenderSettings == nil then
	DB.Styles.Transparent.BartenderSettings = BartenderSettings
end


--Update from old versions
if DB.Styles.Transparent.TooltipLoc == nil then DB.Styles.Transparent.TooltipLoc = true end
if DB.Styles.Transparent.BuffLoc == nil then DB.Styles.Transparent.BuffLoc = true end
