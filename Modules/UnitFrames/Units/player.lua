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

local function Options()
end

---@type UFrameSettings
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
	elements = {
		AuraBars = {
			enabled = true
		},
		Buffs = {
			enabled = true,
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
	}
}

UF.Unit:Add('player', Builder, Settings)
