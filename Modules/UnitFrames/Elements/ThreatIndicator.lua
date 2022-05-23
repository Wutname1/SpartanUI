local UF = SUI.UF

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

UF.Elements:Register('ThreatIndicator', Build)
