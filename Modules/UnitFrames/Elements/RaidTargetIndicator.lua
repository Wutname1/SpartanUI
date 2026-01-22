local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidTargetIndicator = frame.raised:CreateTexture(nil, 'BORDER')
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 20,
	position = {
		anchor = 'LEFT',
		relativePoint = 'LEFT',
		x = 0,
		y = 0,
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Raid Target Icon',
	},
}

UF.Elements:Register('RaidTargetIndicator', Build, nil, nil, Settings)
