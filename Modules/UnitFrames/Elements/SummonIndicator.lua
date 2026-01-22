local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local SummonIndicator = frame.raised:CreateTexture(nil, 'OVERLAY')
	frame.SummonIndicator = SummonIndicator
end

---@type SUI.UF.Elements.Settings
local Settings = {
	config = {
		type = 'Indicator',
		DisplayName = 'Summon',
		NoBulkUpdate = false,
	},
}

UF.Elements:Register('SummonIndicator', Build, nil, nil, Settings)
