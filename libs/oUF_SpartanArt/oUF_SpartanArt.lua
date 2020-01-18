--[[
# Element: Spartan Artwork handler

## Notes

This element updates by changing the texture.
The `Badge` sub-widget has to be on a lower sub-layer than the `PvP` texture.

--]]
local _, ns = ...
local oUF = ns.oUF

local ArtPositions = {'top', 'bg', 'bottom', 'full'}

local function Update(self, event, unit)
	if (unit and unit ~= self.unit) then
		return
	end

	local element = self.SpartanArt
	unit = unit or self.unit

	--[[ Callback: SpartanArt:PreUpdate(unit)
	Called before the element has been updated.

	* self - the SpartanArt element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end

	--[[ Update code
	--]]
	for _, pos in ipairs(ArtPositions) do
		local artObj = element[pos]
		local ArtSettings = element.ArtSettings[pos]
		if artObj and ArtSettings and ArtSettings.enabled and ArtSettings.graphic ~= '' then
			local ArtData = artObj.ArtData

			-- -- setup a bg height
			local height
			if pos == 'bg' then
				height = (self:GetHeight() + (ArtData.height or 0))
			end
			if ArtData.heightScale then
				height = self:GetWidth() * ArtData.heightScale
			end

			-- Setup the Artwork
			if type(ArtData.path) == 'function' then
				artObj:SetTexture(ArtData.path(self, pos))
			else
				artObj:SetTexture(ArtData.path)
			end

			if ArtData.TexCoord then
				if type(ArtData.TexCoord) == 'function' then
					local cords = ArtData.TexCoord(self, pos)
					if cords then
						artObj:SetTexCoord(unpack(cords))
					end
				else
					artObj:SetTexCoord(unpack(ArtData.TexCoord))
				end
			end
			if ArtData.Colorable then
				artObj:SetVertexColor(0, 0, 0, .6)
			end

			artObj:SetScale(ArtData.scale or 1)
			if ArtData.PVPAlpha and not ArtSettings.alpha then
				artObj:SetAlpha((UnitIsPVP(unit) and 1) or ArtData.PVPAlpha)
			else
				artObj:SetAlpha((ArtSettings.alpha or ArtData.alpha) or 1)
			end

			artObj:SetWidth(ArtData.width or self:GetWidth())
			artObj:SetHeight((height or ArtData.height) or 25)

			-- Position artwork
			local x = (ArtData.x or 0)
			local y = (ArtData.y or 0)
			if ArtData.xScale then
				x = self:GetWidth() * ArtData.xScale
			end
			if ArtData.yScale then
				y = self:GetWidth() * ArtData.yScale
			end
			local x = (ArtSettings.x + x)
			local y = (ArtSettings.y + y)
			artObj:ClearAllPoints()
			if ArtData.position then
				x = (x + (ArtData.position.x or 0))
				y = (y + (ArtData.position.y or 0))

				artObj:SetPoint(ArtData.position.anchor, self, ArtData.position.anchor, x, y)
			else
				if pos == 'top' then
					artObj:SetPoint('BOTTOM', self, 'TOP', x, y)
				elseif pos == 'bottom' then
					artObj:SetPoint('TOP', self, 'BOTTOM', x, y)
				elseif pos == 'bg' then
					artObj:SetPoint('CENTER', self, 'CENTER', x, y)
				end
			end

			artObj:Show()
		elseif artObj then
			artObj:Hide()
		end
	end

	--[[ Callback: SpartanArt:PostUpdate(unit, status)
	Called after the element has been updated.

	* self   - the SpartanArt element
	* unit   - the unit for which the update has been triggered (string)
	* status - the unit's current PvP status or faction accounting for mercenary mode (string)['FFA', 'Alliance',
	           'Horde']
	--]]
	if (element.PostUpdate) then
		return element:PostUpdate(unit, status)
	end
end

local function Path(self, ...)
	--[[Override: SpartanArt.Override(self, event, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.SpartanArt.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.SpartanArt
	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		element.top = element.top or element:CreateTexture(nil, 'BORDER')
		element.bg = element.bg or element:CreateTexture(nil, 'BACKGROUND')
		element.bottom = element.bottom or element:CreateTexture(nil, 'BORDER')
		element.full = element.full or element:CreateTexture(nil, 'BACKGROUND')

		self:RegisterEvent('UNIT_FACTION', Path)
		if not oUF.IsClassic then
			self:RegisterEvent('HONOR_LEVEL_UPDATE', Path, true)
		end

		return true
	end
end

local function Disable(self)
	local element = self.SpartanArt
	if (element) then
		element:Hide()

		if (element.Badge) then
			element.Badge:Hide()
		end

		self:UnregisterEvent('UNIT_FACTION', Path)
		self:UnregisterEvent('PLAYER_REGEN_DISABLED', Path)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', Path)
		if not oUF.IsClassic then
			self:UnregisterEvent('HONOR_LEVEL_UPDATE', Path)
		end
	end
end

oUF:AddElement('SpartanArt', Path, Enable, Disable)
