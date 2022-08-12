local UF = SUI.UF
local elementList = {
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
	'SUI_RaidGroup'
}

local function groupingOrder()
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'

	if UF.CurrentSettings.raid.mode == 'GROUP' then
		groupingOrder = '1,2,3,4,5,6,7,8'
	end
	return groupingOrder
end

local function GroupBuilder(holder)
	holder.header =
		SUIUF:SpawnHeader(
		'SUI_UF_raid_Header',
		nil,
		'raid',
		'showRaid',
		UF.CurrentSettings.raid.showRaid,
		'showParty',
		UF.CurrentSettings.raid.showParty,
		'showPlayer',
		UF.CurrentSettings.raid.showSelf,
		'showSolo',
		UF.CurrentSettings.raid.showSolo,
		'xoffset',
		UF.CurrentSettings.raid.xOffset,
		'yOffset',
		UF.CurrentSettings.raid.yOffset,
		'point',
		'TOP',
		'groupBy',
		UF.CurrentSettings.raid.mode,
		'groupingOrder',
		groupingOrder(),
		'sortMethod',
		'index',
		'maxColumns',
		UF.CurrentSettings.raid.maxColumns,
		'unitsPerColumn',
		UF.CurrentSettings.raid.unitsPerColumn,
		'columnSpacing',
		UF.CurrentSettings.raid.columnSpacing,
		'columnAnchorPoint',
		'LEFT',
		'oUF-initialConfigFunction',
		('self:SetWidth(%d) self:SetHeight(%d)'):format(UF.CurrentSettings.raid.width, UF:CalculateHeight('raid'))
	)
	holder.header:SetPoint('TOPLEFT', holder, 'TOPLEFT')
	holder.elementList = elementList
end

local function Builder(frame)
	local elementDB = frame.elementDB

	for _, elementName in pairs(elementList) do
		UF.Elements:Build(frame, elementName, elementDB[elementName])
	end
end

local function Options(OptionSet)
	UF.Options:AddGroupDisplay('raid', OptionSet)
	UF.Options:AddGroupLayout('raid', OptionSet)

	OptionSet.args.General.args.Layout.args.bar2 = {name = 'Offsets', type = 'header', order = 20}
	OptionSet.args.General.args.Layout.args.mode = {
		name = SUI.L['Sort order'],
		type = 'select',
		order = 11,
		values = {['GROUP'] = 'Groups', ['NAME'] = 'Name', ['ASSIGNEDROLE'] = 'Roles'},
		set = function(info, val)
			--Update memory
			UF.CurrentSettings.raid.mode = val
			--Update the DB
			UF.DB.UserSettings[UF.DB.Style].raid.mode = val
			--Update the screen
			local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'
			if val == 'GROUP' then
				groupingOrder = '1,2,3,4,5,6,7,8'
			end

			UF.Unit:Get('raid').header:SetAttribute('groupingOrder', groupingOrder)
		end
	}
end

---@type UFrameSettings
local Settings = {
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
	},
	config = {
		IsGroup = true
	}
}

UF.Unit:Add('raid', Builder, Settings, Options, GroupBuilder)
