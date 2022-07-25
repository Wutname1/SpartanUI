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
	width = 100,
	elements = {
		auras = {
			Debuffs = {
				size = 10
			}
		},
		ThreatIndicator = {
			enabled = true,
			points = 'Name'
		},
		Health = {
			height = 30
		},
		Power = {
			height = 5
		}
	},
	config = {
		Requires = 'target'
	}
}

UF.Unit.Add('targettarget', Builder, Settings)
