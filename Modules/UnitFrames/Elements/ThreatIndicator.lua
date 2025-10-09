local UF = SUI.UF
local elementList = {
	---Basic
	'Name',
	'Health',
	'Castbar',
	'Power',
	'Portrait',
	'SpartanArt',
	'Buffs',
	'Debuffs',
	'RaidTargetIndicator',
	'Range',
	'ThreatIndicator',
	'RaidRoleIndicator'
}

---@param frame table
---@param DB table
local function Build(frame, DB)
	local ThreatIndicator = frame:CreateTexture(nil, 'BACKGROUND')
	ThreatIndicator:SetTexture('Interface\\AddOns\\SpartanUI\\images\\HighlightBar')
	ThreatIndicator.feedbackUnit = 'PLAYER'
	ThreatIndicator:Hide()

	-- Set default position
	ThreatIndicator:SetPoint('TOPLEFT', frame, 'TOPLEFT', -3, 3)
	ThreatIndicator:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 3, -3)

	frame.ThreatIndicator = ThreatIndicator
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.ThreatIndicator then
		previewFrame.ThreatIndicator = previewFrame:CreateTexture(nil, 'BACKGROUND')
		previewFrame.ThreatIndicator:SetTexture('Interface\\AddOns\\SpartanUI\\images\\HighlightBar')
		previewFrame.ThreatIndicator:SetPoint('TOPLEFT', previewFrame, 'TOPLEFT', -3, 3)
		previewFrame.ThreatIndicator:SetPoint('BOTTOMRIGHT', previewFrame, 'BOTTOMRIGHT', 3, -3)
	end

	local element = previewFrame.ThreatIndicator
	-- Show with high threat color (red)
	element:SetVertexColor(1, 0, 0, 0.7)
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	config = {
		type = 'Indicator',
		DisplayName = 'Threat'
	},
	showInPreview = false
}

UF.Elements:Register('ThreatIndicator', Build, nil, nil, Settings, Preview)
