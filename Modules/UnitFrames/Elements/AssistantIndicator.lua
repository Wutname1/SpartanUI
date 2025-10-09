local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.AssistantIndicator = frame:CreateTexture(nil, 'BORDER')
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.AssistantIndicator then
		previewFrame.AssistantIndicator = previewFrame:CreateTexture(nil, 'BORDER')
	end

	local element = previewFrame.AssistantIndicator
	element:SetSize(DB.size, DB.size)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 0, DB.position.y or 6)

	-- Use the actual WoW raid assistant icon
	element:SetTexture([[Interface\GroupFrame\UI-Group-AssistantIcon]])
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
		DisplayName = 'Raid Assistant'
	},
	showInPreview = false
}

UF.Elements:Register('AssistantIndicator', Build, nil, nil, Settings, Preview)
