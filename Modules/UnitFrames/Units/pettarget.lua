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
		Health = {
			height = 30
		},
		Power = {
			height = 5,
			text = {
				['1'] = {
					enabled = false
				}
			}
		},
		Name = {
			enabled = true,
			height = 10,
			position = {
				y = 0
			}
		}
	},
	config = {
		Requires = 'pet'
	}
}

UF.Unit:Add('pettarget', Builder, Settings)
