---@diagnostic disable: missing-parameter
local _, ns = ...
local oUF = ns.oUF or oUF

-- SUI_RaidGroup as an oUF element
-- Displays raid group number
do
	local Update = function(self, event, unit)
		if IsInRaid() then
			self.SUI_RaidGroup:Show()
			self.SUI_RaidGroup.Text:Show()
		else
			self.SUI_RaidGroup:Hide()
			self.SUI_RaidGroup.Text:Hide()
		end
	end

	local Enable = function(self)
		if self.SUI_RaidGroup then
			self:RegisterEvent('GROUP_ROSTER_UPDATE', Update, true)
			return true
		end
	end

	local Disable = function(self)
		if self.SUI_RaidGroup then
			self:UnregisterEvent('GROUP_ROSTER_UPDATE', Update)
			self.SUI_RaidGroup:Hide()
			self.SUI_RaidGroup.Text:Hide()
		end
	end

	oUF:AddElement('SUI_RaidGroup', Update, Enable, Disable)
end
