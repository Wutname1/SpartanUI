local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	-- Additional Mana
	local AdditionalPower = CreateFrame('StatusBar', nil, frame)
	AdditionalPower:SetHeight(DB.height)
	AdditionalPower.colorPower = true
	AdditionalPower:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	AdditionalPower:Hide()

	AdditionalPower.bg = AdditionalPower:CreateTexture(nil, 'BACKGROUND')
	AdditionalPower.bg:SetAllPoints(AdditionalPower)
	AdditionalPower.bg:SetColorTexture(1, 1, 1, 0.2)

	frame.AdditionalPower = AdditionalPower
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.AdditionalPower then
		local AdditionalPower = CreateFrame('StatusBar', nil, previewFrame)
		AdditionalPower:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		AdditionalPower.bg = AdditionalPower:CreateTexture(nil, 'BACKGROUND')
		AdditionalPower.bg:SetAllPoints(AdditionalPower)
		AdditionalPower.bg:SetColorTexture(1, 1, 1, 0.2)
		previewFrame.AdditionalPower = AdditionalPower
	end

	local element = previewFrame.AdditionalPower
	element:SetHeight(DB.height)
	element:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))

	-- Show preview with mana color (blue)
	element:SetStatusBarColor(0, 0.5, 1)
	element:SetMinMaxValues(0, 100)
	element:SetValue(75)
	element:Show()

	return DB.height
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	height = 5,
	width = false,
	position = {
		anchor = 'TOP',
		relativeTo = 'Power',
		relativePoint = 'BOTTOM',
		y = -1
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Additional power'
	},
	showInPreview = false
}

UF.Elements:Register('AdditionalPower', Build, nil, nil, Settings, Preview)
