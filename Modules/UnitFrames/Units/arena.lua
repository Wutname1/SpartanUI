if SUI.IsClassic then
	return
end

local UF = SUI.UF

local function GroupBuilder()
end

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
	maxColumns = 1,
	unitsPerColumn = 5,
	columnSpacing = 1,
	yOffset = -25,
	elements = {
		Name = {text = '[SUI_ColorClass][name] [arenaspec]'},
		Power = {
			height = 5
		},
		Castbar = {
			enabled = true,
			height = 15
		},
		Health = {
			position = {
				anchor = 'TOP',
				relativeTo = 'Castbar',
				relativePoint = 'BOTTOM'
			}
		},
		ThreatIndicator = {
			enabled = true,
			points = 'Name'
		},
		ClassIcon = {
			enabled = true
		}
	},
	config = {
		IsGroup = true
	}
}

UF.Unit.Add('arena', Builder, Settings, Options, GroupBuilder)
