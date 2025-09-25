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
	'AuraWatch'
}

local function GroupBuilder(holder)
	holder.header =
		SUIUF:SpawnHeader(
		'SUI_UF_party_Header',
		nil,
		'party',
		'showRaid',
		UF.CurrentSettings.party.showRaid,
		'showParty',
		true,
		'showPlayer',
		UF.CurrentSettings.party.showPlayer,
		'showSolo',
		true,
		'xoffset',
		UF.CurrentSettings.party.xOffset,
		'yOffset',
		UF.CurrentSettings.party.yOffset,
		'maxColumns',
		UF.CurrentSettings.party.maxColumns,
		'unitsPerColumn',
		UF.CurrentSettings.party.unitsPerColumn,
		'columnSpacing',
		UF.CurrentSettings.party.columnSpacing,
		'columnAnchorPoint',
		'TOPLEFT',
		'initial-anchor',
		'TOPLEFT',
		'oUF-initialConfigFunction',
		('self:SetWidth(%d) self:SetHeight(%d)'):format(UF.CurrentSettings.party.width, UF:CalculateHeight('party')),
		'template',
		'SUI_UNITPET, SUI_UNITTARGET'
	)
	holder.header:Show()
	holder.header:SetPoint('TOPLEFT', holder, 'TOPLEFT')

	holder.header:SetAttribute('startingIndex', -4)
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

local function Update(frame)
	-- Force header to update its configuration when settings change
	if frame and frame.header then
		-- Update the initialConfigFunction with new dimensions
		local configFunc = ('self:SetWidth(%d) self:SetHeight(%d)'):format(UF.CurrentSettings.party.width, UF:CalculateHeight('party'))
		frame.header:SetAttribute('initialConfigFunction', configFunc)

		-- Update header attributes that affect layout and size
		frame.header:SetAttribute('xoffset', UF.CurrentSettings.party.xOffset)
		frame.header:SetAttribute('yOffset', UF.CurrentSettings.party.yOffset)
		frame.header:SetAttribute('maxColumns', UF.CurrentSettings.party.maxColumns)
		frame.header:SetAttribute('unitsPerColumn', UF.CurrentSettings.party.unitsPerColumn)
		frame.header:SetAttribute('columnSpacing', UF.CurrentSettings.party.columnSpacing)
		frame.header:SetAttribute('showPlayer', UF.CurrentSettings.party.showSelf)
	end
end

local function Options(OptionSet)
	UF.Options:AddGroupDisplay('party', OptionSet)
	UF.Options:AddGroupLayout('party', OptionSet)
end

---@type SUI.UF.Unit.Settings
local Settings = {
	width = 120,
	showParty = true,
	showPlayer = true,
	showRaid = false,
	showSolo = false,
	xOffset = 0,
	yOffset = -20,
	maxColumns = 1,
	unitsPerColumn = 5,
	columnSpacing = 2,
	frameBackground = {
		enabled = false,
		displayLevel = -5,
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
		AuraWatch = {
			enabled = true
		},
		Buffs = {
			enabled = true,
			onlyShowPlayer = true,
			size = 15,
			position = {
				relativePoint = 'BOTTOMRIGHT',
				anchor = 'BOTTOMLEFT',
				x = -2
			}
		},
		Debuffs = {
			enabled = true,
			size = 15,
			growthx = 'RIGHT',
			position = {
				relativePoint = 'BOTTOMLEFT',
				anchor = 'BOTTOMRIGHT',
				x = 15,
				y = 47
			}
		},
		Castbar = {
			enabled = true
		},
		ThreatIndicator = {
			enabled = true,
			points = 'Name'
		},
		Health = {
			text = {
				['1'] = {
					text = '[SUIHealth(displayDead)] [($>SUIHealth<$)(percentage,hideDead,hideMax)]'
				}
			},
			position = {
				anchor = 'TOP',
				relativeTo = 'Castbar',
				relativePoint = 'BOTTOM'
			}
		},
		ResurrectIndicator = {
			enabled = true
		},
		SummonIndicator = {
			enabled = true
		},
		GroupRoleIndicator = {
			enabled = true,
			position = {
				anchor = 'TOPRIGHT',
				x = 0,
				y = 0
			}
		},
		AssistantIndicator = {
			enabled = true
		},
		RaidTargetIndicator = {
			enabled = true,
			size = 15,
			position = {
				anchor = 'RIGHT',
				x = 5,
				y = 0
			}
		},
		ClassIcon = {
			enabled = false,
			size = 15,
			position = {
				anchor = 'TOPLEFT',
				x = 0,
				y = 0
			}
		},
		name = {
			position = {
				y = 12
			}
		},
		Power = {
			height = 5
		}
	},
	config = {
		IsGroup = true
	}
}

UF.Unit:Add('party', Builder, Settings, Options, GroupBuilder, Update)
