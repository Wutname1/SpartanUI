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

---@type ElementSettings
local Settings = {
	config = {
		type = 'Indicator'
	}
}

UF.Elements:Register('CombatIndicator', Build, nil, nil, Settings)
