---@diagnostic disable: missing-parameter
local _, ns = ...
local oUF = ns.oUF or oUF

-- Rare / Elite dragon graphic as an oUF element
-- Displays elite/rare indicator - supports two modes:
-- Mode 'background': Colored background overlay (default)
-- Mode 'texture': Dragon texture wrapped around portrait (Classic style)
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
		local mode = element.mode or 'background'

		-- Determine colors based on classification
		local isEliteOrBoss = c == 'worldboss' or c == 'elite'
		local isRare = c == 'rare' or c == 'rareelite'

		if not isEliteOrBoss and not isRare then
			element:Hide()
			return
		end

		if mode == 'texture' then
			-- Dragon texture mode (Classic style)
			-- Always set the elite_rare texture for texture mode
			if element:IsObjectType('Texture') then
				element:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\elite_rare')
				-- Only set default texcoord if not already customized (e.g., by theme callback)
				if not element.texCoordSet then
					element:SetTexCoord(0, 1, 0, 1)
				end
			end

			if isEliteOrBoss then
				element:SetVertexColor(1, 0.9, 0) -- Gold for elite/boss
			elseif isRare then
				element:SetVertexColor(1, 1, 1) -- Silver/white for rare
			end

			-- Apply texture coord modifiers if set (overrides theme settings)
			if element.short == true then
				element:SetTexCoord(0, 1, 0, 0.7)
			elseif element.small == true then
				element:SetTexCoord(0, 1, 0, 0.4)
			end

			element:SetAlpha(element.alpha or 0.75)
		else
			-- Background overlay mode (default)
			if element:IsObjectType('Texture') then
				element:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\elite_rare')
				element:SetTexCoord(0, 1, 0, 1)
				element:SetAlpha(element.alpha or 0.75)
				if element.short == true then
					element:SetTexCoord(0, 1, 0, 0.7)
				end
				if element.small == true then
					element:SetTexCoord(0, 1, 0, 0.4)
				end
			end

			if isEliteOrBoss then
				element:SetVertexColor(1, 0.9, 0) -- Gold for elite/boss
			elseif isRare then
				element:SetVertexColor(1, 1, 1) -- Silver/white for rare
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
