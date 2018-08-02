local SUI = SUI
----------------------------------------------------------------------------------------------------
--First Lets make the Module
SUI:NewModule('Style_Minimal')

--Now lets setup the initial Database settings
local Defaults = {
	Artwork = {},
	PlayerFrames = {},
	PartyFrames = {},
	RaidFrames = {},
	Movable = {
		Minimap = true,
		PlayerFrames = true,
		PartyFrames = true,
		RaidFrames = true
	},
	TooltipLoc = true,
	Minimap = {
		shape = 'square',
		size = {width = 140, height = 140}
	},
	BartenderProfile = 'SpartanUI - Minimal',
	BartenderSettings = {
		ActionBars = {
			actionbars = {
				{
					enabled = true,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {point = 'BOTTOM', x = -200, y = 102, scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 1
				{
					enabled = true,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {point = 'BOTTOM', x = -200, y = 70, scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 2
				{
					enabled = true,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {point = 'BOTTOM', x = -200, y = 35, scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 3
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 4
				{
					enabled = true,
					buttons = 12,
					rows = 3,
					padding = 3,
					skin = {Zoom = true},
					position = {point = 'BOTTOM', x = -317, y = 98, scale = 0.75, growHorizontal = 'RIGHT'}
				}, -- 5
				{
					enabled = true,
					buttons = 12,
					rows = 3,
					padding = 3,
					skin = {Zoom = true},
					position = {point = 'BOTTOM', x = 199, y = 98, scale = 0.75, growHorizontal = 'RIGHT'}
				}, -- 6
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 7
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 8
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 9
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {scale = 0.85, growHorizontal = 'RIGHT'}
				} -- 10
			}
		},
		BagBar = {
			version = 3,
			enabled = true,
			padding = 0,
			position = {point = 'TOP', x = 490, y = -1, scale = 0.70, growHorizontal = 'LEFT'},
			rows = 1,
			onebag = false,
			keyring = true
		},
		MicroMenu = {
			version = 3,
			enabled = true,
			padding = -3,
			position = {point = 'TOP', x = 160, y = -1, scale = 0.70, growHorizontal = 'RIGHT'}
		},
		PetBar = {
			version = 3,
			enabled = true,
			padding = 1,
			position = {point = 'TOP', x = -492, y = -1, scale = 0.70, growHorizontal = 'RIGHT'},
			rows = 1,
			skin = {Zoom = true}
		},
		StanceBar = {
			version = 3,
			enabled = true,
			padding = 1,
			position = {point = 'TOP', x = -163, y = -1, scale = 0.70, growHorizontal = 'LEFT'},
			rows = 1
		},
		MultiCast = {
			fadeoutalpha = .25,
			version = 3,
			fadeout = true,
			enabled = true,
			position = {point = 'TOPRIGHT', x = -777, y = -4, scale = 0.75}
		},
		Vehicle = {
			version = 3,
			enabled = false,
			padding = 3,
			position = {point = 'BOTTOM', x = -200, y = 155, scale = 0.85}
		},
		ExtraActionBar = {
			fadeoutalpha = .25,
			version = 3,
			fadeout = true,
			enabled = true,
			position = {point = 'BOTTOM', x = -32, y = 275}
		},
		ZoneAbilityBar = {
			fadeoutalpha = .6,
			version = 3,
			fadeout = true,
			enabled = true,
			position = {point = 'BOTTOM', x = -32, y = 275}
		},
		BlizzardArt = {enabled = false},
		XPBar = {enabled = false},
		RepBar = {enabled = false},
		APBar = {enabled = false},
		blizzardVehicle = true
	},
	Color = {
		0.6156862745098039,
		0.1215686274509804,
		0.1215686274509804,
		0.9
	},
	TalkingHeadUI = {
		point = 'BOTTOM',
		relPoint = 'TOP',
		x = 0,
		y = -30,
		scale = .8
	},
	PartyFramesSize = 'large',
	HideCenterGraphic = false
}
if not SUI.DB.Styles.Minimal.Artwork then
	SUI.DB.Styles.Minimal = SUI:MergeData(SUI.DB.Styles.Minimal, Defaults, true)
else
	SUI.DB.Styles.Minimal = SUI:MergeData(SUI.DB.Styles.Minimal, Defaults, false)
end
if not SUI.DBG.Bartender4[SUI.DB.Styles.Minimal.BartenderProfile] then
	SUI.DBG.Bartender4[SUI.DB.Styles.Minimal.BartenderProfile] = {Style = 'Minimal'}
end
