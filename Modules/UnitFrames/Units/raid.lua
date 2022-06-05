local UF = SUI.UF

local function builder(frame)
	local elementDB = frame.elementDB
	UF.Elements:Build(frame, 'Name', elementDB.Name)
	UF.Elements:Build(frame, 'Castbar', elementDB.Castbar)
	UF.Elements:Build(frame, 'Health', elementDB.Health)
	UF.Elements:Build(frame, 'Power', elementDB.Power)
	UF.Elements:Build(frame, 'SpartanArt', elementDB.SpartanArt)
	UF.Elements:Build(frame, 'RaidTargetIndicator', elementDB.RaidTargetIndicator)
	UF.Elements:Build(frame, 'Range', elementDB.Range)
	UF.Elements:Build(frame, 'ThreatIndicator', elementDB.ThreatIndicator)
	UF.Elements:Build(frame, 'Buffs', elementDB.Buffs)
	UF.Elements:Build(frame, 'Debuffs', elementDB.Debuffs)
	UF.Elements:Build(frame, 'DispelHighlight', elementDB.DispelHighlight)
	UF.Elements:Build(frame, 'LeaderIndicator', elementDB.LeaderIndicator)
	UF.Elements:Build(frame, 'GroupRoleIndicator', elementDB.GroupRoleIndicator)
	UF.Elements:Build(frame, 'ResurrectIndicator', elementDB.ResurrectIndicator)
end

---@type UFrameSettings
local config = {
	enabled = true,
	width = 95,
	showParty = false,
	showPlayer = true,
	showRaid = true,
	showSolo = false,
	mode = 'NAME',
	xOffset = 2,
	yOffset = 0,
	maxColumns = 4,
	unitsPerColumn = 10,
	columnSpacing = 2,
	visibility = {
		showAlways = false,
		showInRaid = true,
		showInParty = false
	},
	elements = {
		Buffs = {
			enabled = true,
			onlyShowPlayer = true,
			size = 10
		},
		Debuffs = {
			enabled = true,
			rows = 1,
			size = 10
		},
		Health = {
			height = 30
		},
		Power = {
			height = 3,
			text = {
				['1'] = {
					enabled = false
				}
			}
		},
		ResurrectIndicator = {
			enabled = true
		},
		SummonIndicator = {
			enabled = true
		},
		RaidRoleIndicator = {
			enabled = true,
			size = 10,
			alpha = .75,
			position = {
				anchor = 'BOTTOMLEFT',
				x = 0,
				y = 0
			}
		},
		ThreatIndicator = {
			enabled = true,
			points = 'Name'
		},
		Name = {
			enabled = true,
			height = 10,
			textSize = 10,
			text = '[SUI_ColorClass][name]',
			position = {
				y = 0
			}
		},
		SUI_RaidGroup = {
			textSize = 9,
			text = '[group]',
			SetJustifyH = 'CENTER',
			SetJustifyV = 'MIDDLE',
			position = {
				anchor = 'BOTTOMRIGHT',
				x = 0,
				y = 5
			}
		},
		GroupRoleIndicator = {
			enabled = true,
			size = 15,
			alpha = .75,
			position = {
				anchor = 'TOPRIGHT',
				x = -1,
				y = 1
			}
		}
	}
}

UF.Frames.Add('raid', builder, config)
