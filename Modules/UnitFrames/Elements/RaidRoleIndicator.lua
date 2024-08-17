local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidRoleIndicator = frame.raised:CreateTexture(nil, 'BORDER')
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 20,
	position = {
		anchor = 'TOP',
		x = 20,
		y = -10,
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Raid Role',
		Description = 'Raid assignment (main tank or main assist)',
	},
}

UF.Elements:Register('RaidRoleIndicator', Build, _, _, Settings)
