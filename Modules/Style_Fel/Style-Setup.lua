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
		BartenderSettings = { -- actual settings being inserted into our custom profile
			ActionBars = {
				actionbars = { -- following settings are bare minimum, so that anything not defined is retained between resets
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	x=-501,	y=16,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 1
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	x=-501,	y=-29,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 2
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	x=98,	y=16,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 3
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	x=98,	y=-29,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 4
					{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "CENTER",	x=-635,	y=35,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 5
					{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "CENTER",	x=504,	y=35,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 6
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {									scale = 0.85,	growHorizontal="RIGHT"}}, -- 7
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {									scale = 0.85,	growHorizontal="RIGHT"}}, -- 8
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {									scale = 0.85,	growHorizontal="RIGHT"}}, -- 9
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {									scale = 0.85,	growHorizontal="RIGHT"}} -- 10
				}
			},
			BagBar			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true, padding = 0, 		position = {point = "TOP",		x=494,	y=-15,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1, onebag = false},
			MicroMenu		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,	padding = -3,		position = {point = "TOP",		x=105,	y=-15,	scale = 0.70,	growHorizontal="RIGHT"}},
			PetBar			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true, padding = 1, 		position = {point = "TOP",		x=-493,	y=-15,	scale = 0.70,	growHorizontal="RIGHT"},	rows = 1, skin = {Zoom = true}},
			StanceBar		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,	padding = 1, 		position = {point = "TOP",		x=-105,	y=-15,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1},
			MultiCast		= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,						position = {point = "TOPRIGHT",	x=-777,	y=-4,	scale = 0.75}},
			Vehicle			= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = false,padding = 3,		position = {point = "CENTER",	x=-15,	y=213,	scale = 0.85}},
			ExtraActionBar	= {	fadeoutalpha = .25,	version = 3,	fadeout = true,	enabled = true,						position = {point = "CENTER",	x=-32,	y=240}},
			BlizzardArt		= {	enabled = false,	},
			blizzardVehicle = DBMod.Artwork.VehicleUI
		},
		TooltipLoc = true,
		BuffLoc = true
	}
-- end
