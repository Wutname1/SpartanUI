local UF = SUI.UF

local function builder(frame)
	local elementDB = frame.elementDB
	for elementName, _ in pairs(UF.Elements.List) do
		if not elementDB[elementName] then
			SUI:Error('MISSING: ' .. elementName .. ' Type:' .. type(elementName))
		else
			UF.Elements:Build(frame, elementName, elementDB[elementName])
		end
	end
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

UF.Frames.Add('player', builder, Settings)
