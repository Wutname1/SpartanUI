local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local SummonIndicator = frame.raised:CreateTexture(nil, 'OVERLAY')
	frame.SummonIndicator = SummonIndicator
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.SummonIndicator then
		previewFrame.SummonIndicator = previewFrame:CreateTexture(nil, 'OVERLAY')
	end

	local element = previewFrame.SummonIndicator
	element:SetSize(32, 32)
	element:SetPoint('CENTER', previewFrame, 'CENTER', 0, 0)

	-- Show summon pending icon
	element:SetTexture([[Interface\RaidFrame\Raid-Icon-SummonPending]])
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	config = {
		type = 'Indicator',
		DisplayName = 'Summon',
		NoBulkUpdate = false
	},
	showInPreview = false
}

UF.Elements:Register('SummonIndicator', Build, nil, nil, Settings, Preview)
