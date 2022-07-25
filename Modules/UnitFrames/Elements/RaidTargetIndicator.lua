local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidTargetIndicator = frame:CreateTexture(nil, 'ARTWORK')
end

---@type ElementSettings
local Settings = {
	enabled = true,
	size = 20,
	position = {
		anchor = 'BOTTOMRIGHT',
		x = 5,
		y = -10
	}
}

UF.Elements:Register('RaidTargetIndicator', Build, nil, nil, Settings)
