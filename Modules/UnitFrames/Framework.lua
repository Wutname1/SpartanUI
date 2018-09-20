local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Module_UnitFrames', 'AceTimer-3.0')
module.DisplayName = L['Unit frames']
local DB = SUI.DB.Unitframes
----------------------------------------------------------------------------------------------------
local FrameList = {
	'raid',
	'party',
	'player',
	'pet',
	'target',
	'targettarget',
	'focus',
	'focustarget',
	'arena',
	'boss'
}
local DefaultSettings = {
	FrameOptions = {
		['**'] = {
			width = 180,
			height = 60,
			elements = {
				['**'] = {
					enabled = false,
					Scale = 1,
					bgTexture = false,
					AllPoints = false,
					points = false,
					alpha = 1
				},
				Health = {
					enabled = true,
					width = 'full',
					height = 60,
					points = {
						{point = 'TOPRIGHT', relativePoint = 'frame'}
					},
					Text = {
						enabled = true,
						Size = 12,
						AllPoints = 'Health'
					}
				},
				Mana = {
					enabled = true,
					width = 'full',
					height = 15,
					points = {
						{point = 'TOPRIGHT', relativeTo = 'BOTTOMRIGHT', relativePoint = 'Health', x = 0, y = 0}
					},
					Text = {
						enabled = true,
						Size = 12,
						AllPoints = 'Mana'
					}
				},
				Castbar = {
					enabled = false,
					width = 'full',
					height = 15,
					points = {
						{point = 'BOTTOMRIGHT', relativePoint = 'Health', relativeTo = 'TOPRIGHT'}
					},
					Text = {
						enabled = true,
						AllPoints = 'Castbar'
					}
				},
				Name = {
					enabled = true,
					height = 12,
					size = 12,
					width = 'full',
					points = {
						{point = 'RIGHT', relativePoint = 'Name', relativeTo = 'LEFT'}
					}
				},
				LeaderIndicator = {
					enabled = true,
					height = 12,
					width = 12,
					points = {
						{point = 'RIGHT', relativePoint = 'Name', relativeTo = 'LEFT'}
					}
				},
				RestingIndicator = {
					enabled = true,
					height = 20,
					width = 20,
					points = {
						{point = 'CENTER', relativePoint = 'frame', relativeTo = 'LEFT'}
					}
				},
				GroupRoleIndicator = {
					enabled = true,
					height = 18,
					width = 18,
					alpha = .75,
					points = {
						{point = 'CENTER', relativePoint = 'frame', relativeTo = 'LEFT'}
					}
				},
				CombatIndicator = {
					enabled = true,
					height = 20,
					width = 20,
					points = {
						{point = 'CENTER', relativePoint = 'GroupRoleIndicator', relativeTo = 'CENTER'}
					}
				},
				RaidTargetIndicator = {
					enabled = true,
					height = 20,
					width = 20,
					points = {
						{point = 'LEFT', relativePoint = 'RestingIndicator', relativeTo = 'RIGHT'}
					}
				},
				SUI_ClassIcon = {
					enabled = true,
					height = 20,
					width = 20,
					points = {
						{point = 'CENTER', relativePoint = 'RestingIndicator', relativeTo = 'CENTER'}
					}
				},
				ReadyCheckIndicator = {
					enabled = true,
					width = 25,
					height = 25,
					points = {
						{point = 'LEFT', relativeTo = 'LEFT'}
					}
				},
				PvPIndicator = {
					width = 25,
					height = 25,
					points = {
						{point = 'CENTER', relativeTo = 'BOTTOMRIGHT'}
					}
				},
				StatusText = {
					size = 22,
					SetJustifyH = 'CENTER',
					SetJustifyV = 'MIDDLE',
					points = {
						{point = 'CENTER', relativeTo = 'CENTER'}
					}
				}
			}
		}
	},
	PlayerCustomizations = {
		['**'] = {
			['**'] = {
				elements = {
					['**'] = {}
				}
			}
		}
	}
}
local StyleSettings = {}

function module:AddStyleSettings(frame, settings)
	StyleSettings[frame] = SUI:MergeData(settings, DB.FrameOptions[frame], false)
end

function module:SpawnFrames()
end

function module:OnInitalize()
	DB = SUI:MergeData(DB, DefaultSettings, false)
end

function module:OnEnable()
end
