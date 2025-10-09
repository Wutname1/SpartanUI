local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RestingIndicator = frame:CreateTexture(nil, 'ARTWORK')
end

---@param previewFrame frame The preview frame to render into
---@param DB table Element settings
---@param frameName UnitFrameName The frame name being previewed
local function Preview(previewFrame, DB, frameName)
	local indicator = previewFrame.RestingIndicator or previewFrame:CreateTexture(nil, 'ARTWORK')
	indicator:SetSize(DB.size, DB.size)

	-- Show the actual resting icon
	indicator:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
	indicator:SetTexCoord(0, 0.5, 0, 0.421875) -- Resting icon coordinates

	-- Position in top right corner by default
	indicator:ClearAllPoints()
	indicator:SetPoint('TOPRIGHT', previewFrame, 'TOPRIGHT', -2, -2)
	indicator:Show()

	previewFrame.RestingIndicator = indicator

	return 0 -- Indicators don't contribute to height
end

---@type SUI.UF.Elements.Settings
local Settings = {
	size = 20,
	showInPreview = false, -- Conditional element, off by default
	config = {
		DisplayName = 'Resting',
		type = 'Indicator'
	}
}

UF.Elements:Register('RestingIndicator', Build, nil, nil, Settings, Preview)
