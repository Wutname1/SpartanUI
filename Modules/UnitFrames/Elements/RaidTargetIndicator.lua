local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidTargetIndicator = frame.raised:CreateTexture(nil, 'BORDER')
end

---@param previewFrame frame The preview frame to render into
---@param DB table Element settings
---@param frameName UnitFrameName The frame name being previewed
local function Preview(previewFrame, DB, frameName)
	local indicator = previewFrame.RaidTargetIndicator or previewFrame:CreateTexture(nil, 'BORDER')
	indicator:SetSize(DB.size, DB.size)

	-- Show actual raid target icon (star)
	indicator:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')
	SetRaidTargetIconTexture(indicator, 1) -- Star icon

	-- Position based on settings
	indicator:ClearAllPoints()
	if DB.position then
		indicator:SetPoint(DB.position.anchor, previewFrame, DB.position.relativePoint or DB.position.anchor, DB.position.x or 0, DB.position.y or 0)
	else
		indicator:SetPoint('LEFT', previewFrame, 'LEFT', 0, 0)
	end

	indicator:Show()
	previewFrame.RaidTargetIndicator = indicator

	return 0 -- Indicators don't contribute to height
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	showInPreview = false, -- Conditional element
	size = 20,
	position = {
		anchor = 'LEFT',
		relativePoint = 'LEFT',
		x = 0,
		y = 0
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Raid Target Icon'
	}
}

UF.Elements:Register('RaidTargetIndicator', Build, nil, nil, Settings, Preview)
