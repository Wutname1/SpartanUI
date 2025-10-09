local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.LeaderIndicator = frame:CreateTexture(nil, 'BORDER')
	frame.LeaderIndicator:Hide()
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.LeaderIndicator then
		previewFrame.LeaderIndicator = previewFrame:CreateTexture(nil, 'BORDER')
	end

	local element = previewFrame.LeaderIndicator
	element:SetSize(DB.size, DB.size)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 0, DB.position.y or 6)

	-- Show leader icon
	element:SetTexture([[Interface\GroupFrame\UI-Group-LeaderIcon]])
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 12,
	position = {
		anchor = 'TOP',
		x = 0,
		y = 6
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Leader'
	},
	showInPreview = false
}

UF.Elements:Register('LeaderIndicator', Build, nil, nil, Settings, Preview)
