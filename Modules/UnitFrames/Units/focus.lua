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
		Debuffs = {
			enabled = true,
			onlyShowPlayer = true
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
		}
	}
}

UF.Unit:Add('focus', Builder, Settings)
