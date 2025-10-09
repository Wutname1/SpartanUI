local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.CombatIndicator = frame:CreateTexture(nil, 'ARTWORK')
	frame.CombatIndicator.Sizeable = true
	function frame.CombatIndicator:PostUpdate(inCombat)
		if DB and self.DB.enabled and inCombat then
			self:Show()
		else
			self:Hide()
		end
	end
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.CombatIndicator then
		previewFrame.CombatIndicator = previewFrame:CreateTexture(nil, 'ARTWORK')
		previewFrame.CombatIndicator.Sizeable = true
	end

	local element = previewFrame.CombatIndicator
	element:SetSize(DB.size or 16, DB.size or 16)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 0, DB.position.y or 0)
	element:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
	element:SetTexCoord(0.5, 1, 0, 0.49)
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	config = {
		type = 'Indicator',
		DisplayName = 'Combat'
	},
	showInPreview = false
}

UF.Elements:Register('CombatIndicator', Build, nil, nil, Settings, Preview)
