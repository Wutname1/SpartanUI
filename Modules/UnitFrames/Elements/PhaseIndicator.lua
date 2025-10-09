local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.PhaseIndicator = frame:CreateTexture(nil, 'OVERLAY')
	frame.PhaseIndicator:Hide()
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.PhaseIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.PhaseIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('PhaseIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.PhaseIndicator
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.PhaseIndicator then
		previewFrame.PhaseIndicator = previewFrame:CreateTexture(nil, 'OVERLAY')
	end

	local element = previewFrame.PhaseIndicator
	element:SetSize(DB.size, DB.size)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 0, DB.position.y or 0)
	element:SetTexture([[Interface\TargetingFrame\UI-PhasingIcon]])
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 20,
	position = {
		anchor = 'TOP',
		x = 0,
		y = 0
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Phase'
	},
	showInPreview = false
}

UF.Elements:Register('PhaseIndicator', Build, nil, Options, Settings, Preview)
