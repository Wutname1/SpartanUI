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

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	height = 5,
	width = false,
	position = {
		anchor = 'TOP',
		relativeTo = 'Power',
		relativePoint = 'BOTTOM',
		y = -1,
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Additional power',
	},
}

UF.Elements:Register('AdditionalPower', Build, nil, nil, Settings)
