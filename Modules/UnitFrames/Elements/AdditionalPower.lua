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
	AdditionalPower.bg:SetColorTexture(1, 1, 1, .2)

	frame.AdditionalPower = AdditionalPower
end

UF.Elements:Register('AdditionalPower', Build)
