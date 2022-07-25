local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.AssistantIndicator = frame:CreateTexture(nil, 'BORDER')
end

---@type ElementSettings
local Settings = {
	enabled = true,
	size = 12,
	position = {
		anchor = 'TOP',
		x = 0,
		y = 6
	},
	config = {
		type = 'Indicator'
	}
}

UF.Elements:Register('AssistantIndicator', Build, nil, nil, Settings)
