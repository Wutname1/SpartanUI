local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.ReadyCheckIndicator = frame:CreateTexture(nil, 'OVERLAY')
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.ReadyCheckIndicator then
		previewFrame.ReadyCheckIndicator = previewFrame:CreateTexture(nil, 'OVERLAY')
	end

	local element = previewFrame.ReadyCheckIndicator
	element:SetSize(DB.size, DB.size)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 0, DB.position.y or 0)

	-- Show ready check ready texture
	element:SetTexture([[Interface\RaidFrame\ReadyCheck-Ready]])
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 35,
	position = {
		anchor = 'LEFT',
		x = 0,
		y = 0
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Ready Check'
	},
	showInPreview = false
}

UF.Elements:Register('ReadyCheckIndicator', Build, nil, nil, Settings, Preview)
