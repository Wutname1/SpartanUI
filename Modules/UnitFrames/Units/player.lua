local UF = SUI.UF

local function Builder(frame)
	local elementDB = frame.elementDB
	local ElementsToBuild = {
		---Basic
		'Name',
		'Health',
		'Castbar',
		'Power',
		'Portrait',
		'DispelHighlight',
		'SpartanArt',
		'Buffs',
		'Debuffs',
		'ClassIcon',
		'RaidTargetIndicator',
		'ThreatIndicator',
		'Range',
		--Friendly Only
		'AssistantIndicator',
		'GroupRoleIndicator',
		'LeaderIndicator',
		'PhaseIndicator',
		'PvPIndicator',
		'RaidRoleIndicator',
		'ReadyCheckIndicator',
		'ResurrectIndicator',
		'SummonIndicator',
		'StatusText',
		'SUI_RaidGroup',
		---Player Only
		'Totems',
		'CombatIndicator',
		'Runes',
		'RestingIndicator',
		'ClassPower',
		'AdditionalPower',
		'AuraBars'
	}

	for _, elementName in pairs(ElementsToBuild) do
		UF.Elements:Build(frame, elementName, elementDB[elementName])
	end
end

local function Update()
end

---@type SUI.UF.Unit.Settings
local Settings = {
	visibility = {
		showAlways = true
	},
	anchor = {
		point = 'BOTTOMRIGHT',
		relativePoint = 'BOTTOM',
		xOfs = -60,
		yOfs = 250
	},
	frameBackground = {
		enabled = false,
		displayLevel = -1,
		background = {
			enabled = false,
			type = 'color',
			color = {0.1, 0.1, 0.1, 0.8},
			alpha = 0.8,
			classColor = false
		},
		border = {
			enabled = false,
			sides = {top = true, bottom = true, left = true, right = true},
			size = 1,
			colors = {
				top = {1, 1, 1, 1},
				bottom = {1, 1, 1, 1},
				left = {1, 1, 1, 1},
				right = {1, 1, 1, 1}
			},
			classColors = {top = false, bottom = false, left = false, right = false}
		}
	},
	elements = {
		AuraBars = {
			enabled = true
		},
		Buffs = {
			enabled = false,
			rules = {
				duration = {
					enabled = true,
					mode = 'exclude'
				}
			},
			position = {
				anchor = 'TOPLEFT'
			}
		},
		Debuffs = {
			enabled = true,
			position = {
				anchor = 'TOPRIGHT'
			}
		},
		Portrait = {
			enabled = true
		},
		Castbar = {
			enabled = true
		},
		Health = {
			position = {
				anchor = 'TOP',
				relativeTo = 'Castbar',
				relativePoint = 'BOTTOM'
			}
		},
		CombatIndicator = {
			enabled = true,
			position = {
				anchor = 'TOPRIGHT',
				x = 10,
				y = 10
			}
		},
		ClassIcon = {
			enabled = true
		},
		RestingIndicator = {
			enabled = true,
			position = {
				anchor = 'TOPLEFT',
				x = 0,
				y = 0
			}
		},
		Power = {
			text = {
				['1'] = {
					enabled = true
				}
			}
		},
		PvPIndicator = {
			enabled = true
		},
		AdditionalPower = {
			enabled = true
		},
		SUI_RaidGroup = {enabled = true}
	},
	config = {
		isFriendly = true
	}
}

UF.Unit:Add('player', Builder, Settings, nil, nil, Update)
