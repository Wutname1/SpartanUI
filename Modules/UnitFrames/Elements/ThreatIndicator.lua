local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	-- local ThreatIndicator = frame.ThreatIndicator
	-- if not ThreatIndicator then
	-- 	ThreatIndicator = frame:CreateTexture(nil, 'OVERLAY')
	-- 	frame.ThreatIndicator = ThreatIndicator
	-- end

	-- ThreatIndicator:SetTexture('Interface\\AddOns\\SpartanUI\\images\\HighlightBar')
	-- ThreatIndicator:SetSize(DB.width, DB.height)
	-- ThreatIndicator:SetPoint(DB.anchor, frame, DB.anchor, DB.x, DB.y)
	-- ThreatIndicator:SetTexture(DB.texture)
	-- ThreatIndicator:SetVertexColor(DB.color.r, DB.color.g, DB.color.b, DB.color.a)
	-- ThreatIndicator:SetBlendMode(DB.blendMode)
	-- ThreatIndicator:SetAlpha(DB.alpha)

	local ThreatIndicator = frame:CreateTexture(nil, 'BACKGROUND')
	ThreatIndicator:SetTexture('Interface\\AddOns\\SpartanUI\\images\\HighlightBar')
	ThreatIndicator:SetPoint('TOPLEFT', frame, 'TOPLEFT', -3, 3)
	ThreatIndicator:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 3, -3)
	ThreatIndicator.feedbackUnit = 'PLAYER'
	ThreatIndicator:Hide()
	frame.ThreatIndicator = ThreatIndicator
end

---@param frame table
local function Update(frame)
	local DB = frame.ThreatIndicator.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.ThreatIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.ThreatIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('ThreatIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.ThreatIndicator
end

UF.Elements:Register('ThreatIndicator', Build, Update, Options)
