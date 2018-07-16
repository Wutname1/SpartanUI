local SUI = SUI
----------------------------------------------------------------------------------------------------
--First Lets make the Module
local module = SUI:NewModule('Style_War')

module.Settings = {}

--Now lets setup the initial Database settings
local Defaults = {
	Artwork = {
		Allenable = true,
		Allalpha = 100,
		bar1 = {enable = true, alpha = 100},
		bar2 = {enable = true, alpha = 100},
		bar3 = {enable = true, alpha = 100},
		bar4 = {enable = true, alpha = 100},
		Stance = {enable = true, alpha = 100},
		MenuBar = {enable = true, alpha = 100}
	},
	Frames = {
		player = {Buffs = {Mode = 'both'}, Debuffs = {Mode = 'both'}},
		target = {Buffs = {Mode = 'both', onlyShowPlayer = true}, Debuffs = {Mode = 'bars'}}
	},
	PlayerFrames = {},
	PartyFrames = {
		FrameStyle = 'medium'
	},
	RaidFrames = {
		FrameStyle = 'small'
	},
	Movable = {
		Minimap = true
	},
	Minimap = {
		Engulfed = true
	},
	SlidingTrays = {
		left = {
			enabled = true,
			collapsed = false
		},
		right = {
			enabled = true,
			collapsed = false
		}
	},
	TalkingHeadUI = {
		point = 'TOP',
		relPoint = 'TOP',
		x = 0,
		y = -30,
		scale = .8
	},
	BartenderProfile = 'SpartanUI - War',
	BartenderSettings = {
		ActionBars = {
			actionbars = {
				{
					enabled = true,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {
						point = 'CENTER',
						parent = 'War_ActionBarPlate',
						x = -510,
						y = 36,
						scale = 0.85,
						growHorizontal = 'RIGHT'
					},
					states = {
						stance = {
							DRUID = {
								prowl = 0,
								cat = 0,
							},
						},
					},
				}, -- 1
				{
					enabled = true,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {
						point = 'CENTER',
						parent = 'War_ActionBarPlate',
						x = -510,
						y = -8,
						scale = 0.85,
						growHorizontal = 'RIGHT'
					}
				}, -- 2
				{
					enabled = true,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {
						point = 'CENTER',
						parent = 'War_ActionBarPlate',
						x = 108,
						y = 36,
						scale = 0.85,
						growHorizontal = 'RIGHT'
					}
				}, -- 3
				{
					enabled = true,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {
						point = 'CENTER',
						parent = 'War_ActionBarPlate',
						x = 108,
						y = -8,
						scale = 0.85,
						growHorizontal = 'RIGHT'
					}
				}, -- 4
				{
					enabled = true,
					buttons = 12,
					rows = 3,
					padding = 4,
					skin = {Zoom = true},
					position = {
						point = 'CENTER',
						parent = 'War_ActionBarPlate',
						x = -645,
						y = 35,
						scale = 0.80,
						growHorizontal = 'RIGHT'
					}
				}, -- 5
				{
					enabled = true,
					buttons = 12,
					rows = 3,
					padding = 4,
					skin = {Zoom = true},
					position = {
						point = 'CENTER',
						parent = 'War_ActionBarPlate',
						x = 514,
						y = 35,
						scale = 0.80,
						growHorizontal = 'RIGHT'
					}
				}, -- 6
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {parent = 'War_ActionBarPlate', scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 7
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {parent = 'War_ActionBarPlate', scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 8
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {parent = 'War_ActionBarPlate', scale = 0.85, growHorizontal = 'RIGHT'}
				}, -- 9
				{
					enabled = false,
					buttons = 12,
					rows = 1,
					padding = 3,
					skin = {Zoom = true},
					position = {parent = 'War_ActionBarPlate', scale = 0.85, growHorizontal = 'RIGHT'}
				} -- 10
			}
		},
		BagBar = {
			version = 3,
			enabled = true,
			padding = 0,
			position = {point = 'TOP', x = 465, y = -1, scale = 0.6, growHorizontal = 'LEFT'},
			rows = 1,
			onebag = false,
			keyring = true
		},
		MicroMenu = {
			version = 3,
			enabled = true,
			padding = -3,
			position = {point = 'TOP', x = 138, y = -1, scale = 0.65, growHorizontal = 'RIGHT'}
		},
		PetBar = {
			version = 3,
			enabled = true,
			padding = 1,
			position = {point = 'TOP', x = -465, y = -1, scale = 0.65, growHorizontal = 'RIGHT'},
			rows = 1,
			skin = {Zoom = true}
		},
		StanceBar = {
			version = 3,
			enabled = true,
			padding = 1,
			position = {point = 'TOP', x = -129, y = -1, scale = 0.6, growHorizontal = 'LEFT'},
			rows = 1
		},
		MultiCast = {
			fadeoutalpha = .6,
			version = 3,
			fadeout = true,
			enabled = true,
			position = {point = 'TOPRIGHT', parent = 'War_ActionBarPlate', x = -777, y = -4, scale = 0.75}
		},
		Vehicle = {
			fadeoutalpha = .6,
			version = 3,
			fadeout = true,
			enabled = false,
			padding = 3,
			position = {point = 'CENTER', parent = 'War_ActionBarPlate', x = -15, y = 213, scale = 0.85}
		},
		ExtraActionBar = {
			fadeoutalpha = .6,
			version = 3,
			fadeout = true,
			enabled = true,
			position = {point = 'CENTER', parent = 'War_ActionBarPlate', x = -32, y = 240}
		},
		BlizzardArt = {enabled = false},
		XPBar = {enabled = false},
		RepBar = {enabled = false},
		APBar = {enabled = false},
		blizzardVehicle = SUI.DBMod.Artwork.VehicleUI
	},
	TooltipLoc = true,
	BuffLoc = true
}
if not SUI.DB.Styles.War.Artwork then
	SUI.DB.Styles.War = SUI:MergeData(SUI.DB.Styles.War, Defaults, true)
else
	SUI.DB.Styles.War = SUI:MergeData(SUI.DB.Styles.War, Defaults, false)
end
SUI.DB.Styles.War.BartenderSettings = Defaults.BartenderSettings
