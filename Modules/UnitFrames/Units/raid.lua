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
	'SUI_RaidGroup',
}

local function groupingOrder()
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'

	if UF.CurrentSettings.raid.mode == 'GROUP' then groupingOrder = '1,2,3,4,5,6,7,8' end
	return groupingOrder
end

local function GroupBuilder(holder)
	holder.header = SUIUF:SpawnHeader(
		'SUI_UF_raid_Header',
		nil,
		'raid',
		'showRaid',
		true,
		'showParty',
		false,
		'showPlayer',
		UF.CurrentSettings.raid.showSelf,
		'showSolo',
		true,
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

	holder.header:SetAttribute('startingIndex', -10)
	holder.header:Show()
	holder.header.initialized = true
	holder.header:SetAttribute('startingIndex', nil)
end

local function Builder(frame)
	local elementDB = frame.elementDB

	for _, elementName in pairs(elementList) do
		UF.Elements:Build(frame, elementName, elementDB[elementName])
	end
end

local function Options(OptionSet)
	UF.Options:AddGroupDisplay('raid', OptionSet)
	UF.Options:AddGroupDisplay('raid', OptionSet)
	UF.Options:AddGroupLayout('raid', OptionSet)

	OptionSet.args.General.args.Layout.args.bar2 = { name = 'Offsets', type = 'header', order = 20 }
	OptionSet.args.General.args.Layout.args.mode = {
		name = SUI.L['Sort order'],
		type = 'select',
		order = 11,
		values = { ['GROUP'] = 'Groups', ['NAME'] = 'Name', ['ASSIGNEDROLE'] = 'Roles' },
		set = function(info, val)
			--Update memory
			UF.CurrentSettings.raid.mode = val
			--Update the DB
			UF.DB.UserSettings[UF.DB.Style].raid.mode = val
			--Update the screen
			local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'
			if val == 'GROUP' then groupingOrder = '1,2,3,4,5,6,7,8' end

			UF.Unit:Get('raid').header:SetAttribute('groupingOrder', groupingOrder)
		end,
	}
end

---@type SUI.UF.Unit.Settings
local Settings = {
	width = 95,
	showParty = false,
	showPlayer = true,
	showRaid = true,
	showSolo = false,
	mode = 'ASSIGNEDROLE',
	xOffset = 2,
	yOffset = -3,
	maxColumns = 4,
	unitsPerColumn = 10,
	columnSpacing = 2,
	visibility = {
		showAlways = false,
		showInRaid = true,
		showInParty = false,
	},
	elements = {
		Buffs = {
			enabled = true,
			onlyShowPlayer = true,
			rows = 1,
			size = 10,
			growthx = 'LEFT',
			growthy = 'UP',
			position = {
				relativePoint = 'BOTTOMRIGHT',
				anchor = 'BOTTOMRIGHT',
			},
		},
		Debuffs = {
			enabled = true,
			rows = 1,
			number = 5,
			size = 10,
			growthy = 'DOWN',
			growthx = 'RIGHT',
			position = {
				relativePoint = 'TOPLEFT',
				anchor = 'TOPLEFT',
			},
		},
		Health = {
			height = 30,
			text = {
				['1'] = {
					text = '[health:missing-formatted] [perhp:conditional]',
				},
			},
		},
		Power = {
			height = 2,
			position = {
				y = 0,
			},
			text = {
				['1'] = {
					enabled = false,
				},
			},
		},
		ResurrectIndicator = {
			enabled = true,
		},
		SummonIndicator = {
			enabled = true,
		},
		RaidTargetIndicator = {
			size = 10,
		},
		RaidRoleIndicator = {
			enabled = true,
			size = 10,
			alpha = 0.7,
			position = {
				anchor = 'BOTTOMLEFT',
				x = 0,
				y = 0,
			},
		},
		ReadyCheckIndicator = {
			size = 15,
			position = {
				anchor = 'RIGHT',
				x = -5,
			},
		},
		ThreatIndicator = {
			enabled = true,
			points = 'Name',
		},
		Name = {
			enabled = true,
			height = 10,
			textSize = 10,
			text = '[SUI_ColorClass][name]',
			position = {
				y = 0,
			},
		},
		SUI_RaidGroup = {
			textSize = 9,
			text = '[group]',
			SetJustifyH = 'CENTER',
			SetJustifyV = 'MIDDLE',
			position = {
				anchor = 'BOTTOMRIGHT',
				x = 0,
				y = 5,
			},
		},
		GroupRoleIndicator = {
			enabled = true,
			size = 15,
			alpha = 0.75,
			ShowDPS = false,
			position = {
				anchor = 'TOPRIGHT',
				x = -1,
				y = 1,
			},
		},
	},
	config = {
		IsGroup = true,
		isFriendly = true,
	},
}

UF.Unit:Add('raid', Builder, Settings, Options, GroupBuilder)
