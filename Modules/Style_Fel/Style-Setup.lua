local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
----------------------------------------------------------------------------------------------------
--First Lets make the Module
local module = spartan:NewModule("Style_Fel");

--Now lets setup the initial Database settings
-- if DB.Styles.Fel == nil then
	DB.Styles.Fel = {
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
		Minimap = {
			shape = "circle",
			size = {width = 140, height = 140},
			Engulfed = true
		},
		TalkingHeadUI = {
			point = "BOTTOM",
			relPoint = "TOP",
			x = 0,
			y = -30,
			scale = .8
		},
		BartenderProfile = "SpartanUI - Fel",
		BartenderSettings = {
			ActionBars = {
				actionbars = {
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=-501,	y=16,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 1
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=-501,	y=-29,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 2
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=98,	y=16,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 3
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=98,	y=-29,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 4
					{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=-635,	y=35,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 5
					{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=504,	y=35,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 6
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Fel_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 7
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Fel_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 8
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Fel_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 9
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Fel_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}} -- 10
				}
			},
			BagBar			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true, padding = 0, 		position = {point = "TOP",		parent = "Fel_ActionBarPlate",	x=494,	y=-15,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1, onebag = false, keyring = true},
			MicroMenu		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,	padding = -3,		position = {point = "TOP",		parent = "Fel_ActionBarPlate",	x=105,	y=-15,	scale = 0.70,	growHorizontal="RIGHT"}},
			PetBar			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true, padding = 1, 		position = {point = "TOP",		parent = "Fel_ActionBarPlate",	x=-493,	y=-15,	scale = 0.70,	growHorizontal="RIGHT"},	rows = 1, skin = {Zoom = true}},
			StanceBar		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,	padding = 1, 		position = {point = "TOP",		parent = "Fel_ActionBarPlate",	x=-105,	y=-15,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1},
			MultiCast		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,						position = {point = "TOPRIGHT",		parent = "Fel_ActionBarPlate",	x=-777,	y=-4,	scale = 0.75}},
			Vehicle			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = false,	padding = 3,	position = {point = "CENTER",		parent = "Fel_ActionBarPlate",	x=-15,	y=213,	scale = 0.85}},
			ExtraActionBar	= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,						position = {point = "CENTER",		parent = "Fel_ActionBarPlate",	x=-32,	y=240}},
			BlizzardArt		= {	enabled = false,	},
			blizzardVehicle = DBMod.Artwork.VehicleUI
		},
		TooltipLoc = true,
		BuffLoc = true
	}
-- end
