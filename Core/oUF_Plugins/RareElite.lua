---@diagnostic disable: missing-parameter
local _, ns = ...
local oUF = ns.oUF or oUF

-- Rare / Elite dragon graphic as an oUF element
-- Displays elite/rare dragon border texture
do
	local Update = function(self, event, unit)
		if self.unit ~= unit then
			return
		end
		if not self.RareElite then
			return
		end
		local c = UnitClassification(unit)
		local element = self.RareElite

		if c == 'worldboss' or c == 'elite' or c == 'rareelite' then
			element:SetVertexColor(1, 0.9, 0)
		elseif c == 'rare' then
			element:SetVertexColor(1, 1, 1)
		else
			element:Hide()
			return
		end

		if element:IsObjectType('Texture') and not element:GetTexture() then
			element:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\elite_rare')
			element:SetTexCoord(0, 1, 0, 1)
			element:SetAlpha(0.75)
			if element.short == true then
				element:SetTexCoord(0, 1, 0, 0.7)
			end
			if element.small == true then
				element:SetTexCoord(0, 1, 0, 0.4)
			end
		end
		element:Show()
	end

	local function ForceUpdate(element)
		return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
	end

	local Enable = function(self)
		if self.RareElite then
			self.RareElite.__owner = self
			self.RareElite.ForceUpdate = ForceUpdate
			self.RareElite:Hide()
			return true
		end
	end

	local Disable = function(self)
		if self.RareElite then
			self.RareElite:Hide()
		end
	end

	oUF:AddElement('RareElite', Update, Enable, Disable)
end
