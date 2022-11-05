local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RestingIndicator = frame:CreateTexture(nil, 'ARTWORK')
end

---@type SUI.UnitFrame.Element.Settings
local Settings = {
	size = 20,
	config = {
		DisplayName = 'Resting',
		type = 'Indicator'
	}
}

UF.Elements:Register('RestingIndicator', Build, nil, nil, Settings)
