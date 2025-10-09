local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.SUI_RaidGroup = frame:CreateTexture(nil, 'BORDER')

	frame.SUI_RaidGroup.Text = frame:CreateFontString(nil, 'BORDER')
	frame.SUI_RaidGroup.Text:SetPoint('CENTER', frame.SUI_RaidGroup, 'CENTER', 0, 0)
	SUI.Font:Format(frame.SUI_RaidGroup.Text, DB.textSize, 'UnitFrames')
	frame:Tag(frame.SUI_RaidGroup.Text, DB.content)
end

---@param frame table
local function Update(frame)
	local DB = frame.SUI_RaidGroup.DB
	frame:Tag(frame.SUI_RaidGroup.Text, DB.content)
	frame.SUI_RaidGroup.Text:SetJustifyH(DB.SetJustifyH)
	frame.SUI_RaidGroup.Text:SetJustifyV(DB.SetJustifyV)
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.SUI_RaidGroup then
		previewFrame.SUI_RaidGroup = previewFrame:CreateTexture(nil, 'BORDER')
		previewFrame.SUI_RaidGroup.Text = previewFrame:CreateFontString(nil, 'BORDER')
		previewFrame.SUI_RaidGroup.Text:SetPoint('CENTER', previewFrame.SUI_RaidGroup, 'CENTER', 0, 0)
		SUI.Font:Format(previewFrame.SUI_RaidGroup.Text, DB.textSize, 'UnitFrames')
	end

	local element = previewFrame.SUI_RaidGroup
	element:SetSize(30, 20)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 0, DB.position.y or 10)

	-- Show sample group number
	element.Text:SetText('3')
	element.Text:SetJustifyH(DB.SetJustifyH)
	element.Text:SetJustifyV(DB.SetJustifyV)
	element.Text:Show()
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	textSize = 13,
	content = '[group]',
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE',
	position = {
		anchor = 'BOTTOMRIGHT',
		x = 0,
		y = 10
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Raid Group'
	},
	showInPreview = false
}

UF.Elements:Register('SUI_RaidGroup', Build, Update, nil, Settings, Preview)
