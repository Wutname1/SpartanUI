--[[
# Element: PVP Role Indicator

Handles the visibility and updating of an indicator based on the unit's raid assignment (main tank or main assist).

## Widget

PvPRoleIndicator - A `Texture` representing the unit's raid assignment.

## Notes

This element updates by changing the texture.

## Examples

    -- Position and size
    local PvPRoleIndicator = self:CreateTexture(nil, 'OVERLAY')
    PvPRoleIndicator:SetSize(16, 16)
    PvPRoleIndicator:SetPoint('TOPLEFT')

    -- Register it with oUF
    self.PvPRoleIndicator = PvPRoleIndicator
--]]

local _, ns = ...
local oUF = ns.oUF

local DEFAULT_TEXTURE = [[Interface\LFGFrame\UI-LFG-ICON-ROLES]]

local function Update(self, event)
	local element = self.PvPRoleIndicator

	--[[ Callback: PvPRoleIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the PvPRoleIndicator element
	--]]
	if element.PreUpdate then element:PreUpdate() end
	if element:IsObjectType('Texture') and not element:GetTexture() then
		element:SetTexture(DEFAULT_TEXTURE)
		element:SetTexCoord(GetTexCoordsForRole('HEALER'))
	end
	-- local RegItem = element.Registry[self.unitGUID]
	-- local role = UnitGroupRolesAssigned(self.unit)
	-- print(self.unitGUID)
	local info = C_PvP.GetScoreInfoByPlayerGuid(self.unitGUID)
	if info and info.roleAssigned == 2 and element.showTank then
		element:SetTexCoord(GetTexCoordsForRole('TANK'))
		element:Show()
	elseif info and info.roleAssigned == 4 then
		element:SetTexCoord(GetTexCoordsForRole('HEALER'))
		element:Show()
	else
		element:Hide()
	end
	-- element:Show()
	--[[ Callback: PvPRoleIndicator:PostUpdate(role)
	Called after the element has been updated.

	* self - the PvPRoleIndicator element
	* role - the unit's raid assignment (string?)['MAINTANK', 'MAINASSIST']
	--]]
	if element.PostUpdate then return element:PostUpdate() end
end

local function Path(self, ...)
	--[[ Override: PvPRoleIndicator.Override(self, event, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.PvPRoleIndicator.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.PvPRoleIndicator
	if element then
		--Check for HHTD
		local HHTD, _ = C_AddOns.IsAddOnLoaded('HHTD')
		if not HHTD then
			element.__owner = self
			element.ForceUpdate = ForceUpdate

			self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)
			self:RegisterEvent('UPDATE_BATTLEFIELD_SCORE', Path, true)

			return true
		end
	end
end

local function Disable(self)
	local element = self.PvPRoleIndicator
	if element then
		element:Hide()

		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
		self:UnregisterEvent('UPDATE_BATTLEFIELD_SCORE', Path)
	end
end

oUF:AddElement('PvPRoleIndicator', Path, Enable, Disable)
