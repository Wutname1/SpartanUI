local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
----------------------------------------------------------------------------------------------------
--First Lets make the Module
local module = spartan:NewModule("Style_Fel");

--Now lets setup the initial Database settings
local Defaults = {
	Artwork = {
		Allenable = true,
		Allalpha = 100,
		bar1 = {enable=true, alpha=100},
		bar2 = {enable=true, alpha=100},
		bar3 = {enable=true, alpha=100},
		bar4 = {enable=true, alpha=100},
		Stance = {enable=true, alpha=100},
		MenuBar = {enable=true, alpha=100}
	},
	Frames = {
		player = {Buffs={Mode="both"},Debuffs={Mode="both"}},
		target = {Buffs={Mode="both",onlyShowPlayer=true},Debuffs={Mode="bars"}}
	},
	PlayerFrames = {},
	PartyFrames = {
		FrameStyle = "medium"
		},
	RaidFrames = {
		FrameStyle = "small"
		},
	Movable = {
		Minimap = true
	},
	Minimap = {
		Engulfed = true
	},
	TalkingHeadUI = {
		point = "TOP",
		relPoint = "TOP",
		x = 0,
		y = -30,
		scale = .8
	},
	BartenderProfile = "SpartanUI - Fel",
	BartenderSettings = {
		ActionBars = {
			actionbars = {
				{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=-510,	y=36,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 1
				{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=-510,	y=-8,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 2
				{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=108,	y=36,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 3
				{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=108,	y=-8,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 4
				{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=-645,	y=35,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 5
				{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "CENTER",	parent = "Fel_ActionBarPlate",	x=514,	y=35,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 6
				{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Fel_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 7
				{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Fel_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 8
				{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Fel_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 9
				{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Fel_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}} -- 10
			}
		},
		BagBar			= {	fadeoutalpha = .6,	version = 3,	fadeout = true,	enabled = true, padding = 0, 		position = {point = "TOP",		parent = "Fel_ActionBarPlate",	x=503,	y=2,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1, onebag = false, keyring = true},
		MicroMenu		= {	fadeoutalpha = .6,	version = 3,	fadeout = true,	enabled = true,	padding = -3,		position = {point = "TOP",		parent = "Fel_ActionBarPlate",	x=114,	y=4,	scale = 0.70,	growHorizontal="RIGHT"}},
		PetBar			= {	fadeoutalpha = .6,	version = 3,	fadeout = true,	enabled = true, padding = 1, 		position = {point = "TOP",		parent = "Fel_ActionBarPlate",	x=-497,	y=2,	scale = 0.70,	growHorizontal="RIGHT"},	rows = 1, skin = {Zoom = true}},
		StanceBar		= {	fadeoutalpha = .6,	version = 3,	fadeout = true,	enabled = true,	padding = 1, 		position = {point = "TOP",		parent = "Fel_ActionBarPlate",	x=-115,	y=2,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1},
		MultiCast		= {	fadeoutalpha = .6,	version = 3,	fadeout = true,	enabled = true,						position = {point = "TOPRIGHT",		parent = "Fel_ActionBarPlate",	x=-777,	y=-4,	scale = 0.75}},
		Vehicle			= {	fadeoutalpha = .6,	version = 3,	fadeout = true,	enabled = false,	padding = 3,	position = {point = "CENTER",		parent = "Fel_ActionBarPlate",	x=-15,	y=213,	scale = 0.85}},
		ExtraActionBar	= {	fadeoutalpha = .6,	version = 3,	fadeout = true,	enabled = true,						position = {point = "CENTER",		parent = "Fel_ActionBarPlate",	x=-32,	y=240}},
		BlizzardArt		= {	enabled = false,	},
		blizzardVehicle = DBMod.Artwork.VehicleUI
	},
	TooltipLoc = true,
	SubTheme = "Fel",
	StatusBars = {
		XP = true,
		REP = true,
		AP = true,
		HONOR = true
	},
	BuffLoc = true
}
if not DB.Styles.Fel.Artwork then
	DB.Styles.Fel = spartan:MergeData(DB.Styles.Fel, Defaults, true)
else
	DB.Styles.Fel = spartan:MergeData(DB.Styles.Fel, Defaults, false)
end
if not SUI.DBG.Bartender4[DB.Styles.Fel.BartenderProfile] then
	SUI.DBG.Bartender4[DB.Styles.Fel.BartenderProfile] = {Style = "Fel"}
end