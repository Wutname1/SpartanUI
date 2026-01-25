---@diagnostic disable: missing-parameter
local _, ns = ...
local oUF = ns.oUF or oUF

-- LevelSkull as an oUF element
-- Displays skull icon for skull-level units
do
	local Update = function(self, event, unit)
		if self.unit ~= unit then
			return
		end
		if not self.LevelSkull then
			return
		end
		local level = UnitLevel(unit)
		self.LevelSkull:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame-Skull')
		if level < 0 then
			self.LevelSkull:SetTexCoord(0, 1, 0, 1)
			if self.Level then
				self.Level:SetText('')
			end
		else
			self.LevelSkull:SetTexCoord(0, 0.01, 0, 0.01)
		end
	end

	local function ForceUpdate(element)
		return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
	end

	local Enable = function(self)
		if self.LevelSkull then
			self.LevelSkull.__owner = self
			self.LevelSkull.ForceUpdate = ForceUpdate
			return true
		end
	end

	local Disable = function(self)
		if self.LevelSkull then
			self.LevelSkull:Hide()
		end
	end

	oUF:AddElement('LevelSkull', Update, Enable, Disable)
end
