local UF = SUI.UF

local function Builder(frame)
	local elementDB = frame.elementDB
	for elementName, _ in pairs(UF.Elements.List) do
		if not elementDB[elementName] then
			SUI:Error('MISSING: ' .. elementName .. ' Type:' .. type(elementName))
		else
			UF.Elements:Build(frame, elementName, elementDB[elementName])
		end
	end
end

local function Options()
end

---@type UFrameSettings
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
	elements = {
		Buffs = {
			enabled = true,
			onlyShowPlayer = true,
			size = 15,
			initialAnchor = 'BOTTOMLEFT',
			growthx = 'LEFT',
			position = {
				anchor = 'BOTTOMLEFT',
				x = -15,
				y = 47
			}
		},
		Debuffs = {
			enabled = true,
			size = 15,
			initialAnchor = 'BOTTOMRIGHT',
			growthx = 'RIGHT',
			position = {
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

UF.Unit.Add('party', Builder, Settings)
