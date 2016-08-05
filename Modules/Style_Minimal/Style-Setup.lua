local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
----------------------------------------------------------------------------------------------------
--First Lets make the Module
local module = spartan:NewModule("Style_Minimal");

--Now lets setup the initial Database settings
local default = {
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
	TooltipLoc = true,
	Minimap = {
		shape = "square",
		size = {width = 140, height = 140}
	},
	BartenderProfile = "SpartanUI - Minimal",
	BartenderSettings = {
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
	},
	Color = {
		0.6156862745098039,
		0.1215686274509804,
		0.1215686274509804,
		0.9
	},
	TalkingHeadUI = {
		point = "BOTTOM",
		relPoint = "TOP",
		x = 0,
		y = -30,
		scale = .8
	},
	PartyFramesSize = "large"
}
if DB.Styles.Minimal == nil then DB.Styles.Minimal = default end

--Update from old versions
if DB.Styles.Transparent.TalkingHeadUI == nil then
	DB.Styles.Transparent.TalkingHeadUI = {
		point = "BOTTOM",
		relPoint = "TOP",
		x = 0,
		y = -30,
		scale = .8
	}
end
if DB.Styles.Minimal.Color == nil then
	DB.Styles.Minimal.Color = {0.6156862745098039,0.1215686274509804,0.1215686274509804,0.9}
	DB.Styles.Minimal.PartyFramesSize = "large"
end
if DB.Styles.Minimal.PartyFramesSize == nil then DB.Styles.Minimal.PartyFramesSize = "large" end
if DB.Styles.Minimal.TooltipLoc == nil then DB.Styles.Minimal.TooltipLoc = true end
if DB.Styles.Minimal.BartenderSettings == nil then DB.Styles.Minimal.BartenderSettings = default.BartenderSettings end