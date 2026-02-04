--[[
# Element: Health Prediction Bars

Handles the visibility and updating of incoming heals and heal/damage absorbs.

This is the oUF_Classic compatibility layer that accepts Retail 12.0+ API property names
and translates them to work with Classic WoW APIs internally.

## Widget

HealthPrediction - A `table` containing references to sub-widgets and options.

## Sub-Widgets (Retail 12.0+ API - preferred)

healingAll                - A `StatusBar` used to represent incoming heals from all sources.
damageAbsorb              - A `StatusBar` used to represent damage absorbs.
healAbsorb                - A `StatusBar` used to represent heal absorbs.
overDamageAbsorbIndicator - A `Texture` used to signify that the amount of damage absorb is greater than the unit's missing health.
overHealAbsorbIndicator   - A `Texture` used to signify that the amount of heal absorb is greater than the unit's current health.

## Notes

A default texture will be applied to the StatusBar widgets if they don't have a texture set.
A default texture will be applied to the Texture widgets if they don't have a texture or a color set.

This element accepts Retail-style property names and handles Classic API translation internally.
Write your UnitFrame code to Retail oUF specs - this compatibility layer handles the rest.

## Options

.incomingHealOverflow - The maximum amount of overflow past the end of the health bar. Set this to 1 to disable the overflow.
                        Defaults to 1.05 (number)

## Examples

    -- Position and size
    local healingAll = CreateFrame('StatusBar', nil, self.Health)
    healingAll:SetPoint('TOP')
    healingAll:SetPoint('BOTTOM')
    healingAll:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
    healingAll:SetWidth(200)

    local damageAbsorb = CreateFrame('StatusBar', nil, self.Health)
    damageAbsorb:SetPoint('TOP')
    damageAbsorb:SetPoint('BOTTOM')
    damageAbsorb:SetPoint('LEFT', healingAll:GetStatusBarTexture(), 'RIGHT')
    damageAbsorb:SetWidth(200)

    local healAbsorb = CreateFrame('StatusBar', nil, self.Health)
    healAbsorb:SetPoint('TOP')
    healAbsorb:SetPoint('BOTTOM')
    healAbsorb:SetPoint('RIGHT', self.Health:GetStatusBarTexture())
    healAbsorb:SetWidth(200)
    healAbsorb:SetReverseFill(true)

    local overDamageAbsorbIndicator = self.Health:CreateTexture(nil, "OVERLAY")
    overDamageAbsorbIndicator:SetPoint('TOP')
    overDamageAbsorbIndicator:SetPoint('BOTTOM')
    overDamageAbsorbIndicator:SetPoint('LEFT', self.Health, 'RIGHT')
    overDamageAbsorbIndicator:SetWidth(10)

    local overHealAbsorbIndicator = self.Health:CreateTexture(nil, "OVERLAY")
    overHealAbsorbIndicator:SetPoint('TOP')
    overHealAbsorbIndicator:SetPoint('BOTTOM')
    overHealAbsorbIndicator:SetPoint('RIGHT', self.Health, 'LEFT')
    overHealAbsorbIndicator:SetWidth(10)

    -- Register with oUF (Retail 12.0+ style)
    self.HealthPrediction = {
        healingAll = healingAll,
        damageAbsorb = damageAbsorb,
        healAbsorb = healAbsorb,
        overDamageAbsorbIndicator = overDamageAbsorbIndicator,
        overHealAbsorbIndicator = overHealAbsorbIndicator,
        incomingHealOverflow = 1.05,
    }
--]]

local _, ns = ...
local oUF = ns.oUF

local HealComm = LibStub('LibHealComm-4.0', true)

-- Helper to get widget using Retail name with fallback to legacy name
local function GetWidget(element, retailName, legacyName)
	return element[retailName] or element[legacyName]
end

-- Helper to get overflow setting using Retail name with fallback to legacy name
local function GetOverflow(element)
	return element.incomingHealOverflow or element.maxOverflow or 1.05
end

local function Update(self, event, unit)
	if self.unit ~= unit then
		return
	end

	local element = self.HealthPrediction

	--[[ Callback: HealthPrediction:PreUpdate(unit)
	Called before the element has been updated.

	* self - the HealthPrediction element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	-- Get widgets using Retail names with legacy fallbacks
	local healingAllBar = GetWidget(element, 'healingAll', 'myBar')
	local damageAbsorbBar = GetWidget(element, 'damageAbsorb', 'absorbBar')
	local healAbsorbBar = GetWidget(element, 'healAbsorb', 'healAbsorbBar')
	local overDamageIndicator = GetWidget(element, 'overDamageAbsorbIndicator', 'overAbsorb')
	local overHealIndicator = GetWidget(element, 'overHealAbsorbIndicator', 'overHealAbsorb')
	local maxOverflow = GetOverflow(element)

	local GUID = UnitGUID(unit)
	local myIncomingHeal = UnitGetIncomingHeals(unit, 'player') or 0
	local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
	local overTimeHeals = not oUF.isRetail and HealComm and ((HealComm:GetHealAmount(GUID, HealComm.OVERTIME_AND_BOMB_HEALS) or 0) * (HealComm:GetHealModifier(GUID) or 1)) or 0
	local absorb = oUF.isRetail and UnitGetTotalAbsorbs(unit) or 0
	local healAbsorb = oUF.isRetail and UnitGetTotalHealAbsorbs(unit) or 0
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
	local hasOverHealAbsorb = false

	-- Kludge to override value for heals not reported by WoW client (ref: https://github.com/Stanzilla/WoWUIBugs/issues/163)
	-- There may be other bugs that this workaround does not catch, but this does fix Priest PoH
	if HealComm and not oUF.isRetail then
		local healAmount = HealComm:GetHealAmount(GUID, HealComm.CASTED_HEALS) or 0
		if healAmount > 0 then
			if myIncomingHeal == 0 and unit == 'player' then
				myIncomingHeal = healAmount
			end

			if allIncomingHeal == 0 then
				allIncomingHeal = healAmount
			end
		end
	end

	-- Add overtime heals to total
	allIncomingHeal = allIncomingHeal + overTimeHeals

	if healAbsorb > allIncomingHeal then
		healAbsorb = healAbsorb - allIncomingHeal
		allIncomingHeal = 0

		if health < healAbsorb then
			hasOverHealAbsorb = true
		end
	else
		allIncomingHeal = allIncomingHeal - healAbsorb
		healAbsorb = 0

		if health + allIncomingHeal > maxHealth * maxOverflow then
			allIncomingHeal = maxHealth * maxOverflow - health
		end
	end

	local hasOverAbsorb = false
	if (health + allIncomingHeal + absorb >= maxHealth) and (absorb > 0) then
		hasOverAbsorb = true
	end

	-- Update healing bar (combined heals in Retail style)
	if healingAllBar then
		healingAllBar:SetMinMaxValues(0, maxHealth)
		healingAllBar:SetValue(allIncomingHeal)
		if allIncomingHeal > 0 then
			healingAllBar:Show()
		else
			healingAllBar:Hide()
		end
	end

	-- Update damage absorb bar
	if damageAbsorbBar then
		damageAbsorbBar:SetMinMaxValues(0, maxHealth)
		damageAbsorbBar:SetValue(absorb)
		if absorb > 0 then
			damageAbsorbBar:Show()
		else
			damageAbsorbBar:Hide()
		end
	end

	-- Update heal absorb bar
	if healAbsorbBar then
		healAbsorbBar:SetMinMaxValues(0, maxHealth)
		healAbsorbBar:SetValue(healAbsorb)
		if healAbsorb > 0 then
			healAbsorbBar:Show()
		else
			healAbsorbBar:Hide()
		end
	end

	-- Update overflow indicators
	if overDamageIndicator then
		if hasOverAbsorb then
			overDamageIndicator:Show()
		else
			overDamageIndicator:Hide()
		end
	end

	if overHealIndicator then
		if hasOverHealAbsorb then
			overHealIndicator:Show()
		else
			overHealIndicator:Hide()
		end
	end

	--[[ Callback: HealthPrediction:PostUpdate(unit)
	Called after the element has been updated.

	* self - the HealthPrediction element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if element.PostUpdate then
		return element:PostUpdate(unit)
	end
end

local function Path(self, ...)
	--[[ Override: HealthPrediction.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event
	--]]
	return (self.HealthPrediction.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function HealComm_Check(self, element, ...)
	if element and self:IsVisible() then
		for i = 1, select('#', ...) do
			if self.unit and UnitGUID(self.unit) == select(i, ...) then
				Path(self, nil, self.unit)
			end
		end
	end
end

local function HealComm_Create(self, element)
	local update = function(event, casterGUID, spellID, healType, _, ...)
		HealComm_Check(self, element, ...)
	end
	local modified = function(event, guid)
		HealComm_Check(self, element, guid)
	end
	return update, modified
end

local function SetUseHealComm(element, state)
	if not HealComm then
		return
	end

	if state then
		local frame = element.__owner
		if not frame.HealComm_Update then
			frame.HealComm_Update, frame.HealComm_Modified = HealComm_Create(frame, element)
		end

		HealComm.RegisterCallback(element, 'HealComm_HealStarted', frame.HealComm_Update)
		HealComm.RegisterCallback(element, 'HealComm_HealUpdated', frame.HealComm_Update)
		HealComm.RegisterCallback(element, 'HealComm_HealDelayed', frame.HealComm_Update)
		HealComm.RegisterCallback(element, 'HealComm_HealStopped', frame.HealComm_Update)
		HealComm.RegisterCallback(element, 'HealComm_ModifierChanged', frame.HealComm_Modified)
		HealComm.RegisterCallback(element, 'HealComm_GUIDDisappeared', frame.HealComm_Modified)
	else
		HealComm.UnregisterCallback(element, 'HealComm_HealStarted')
		HealComm.UnregisterCallback(element, 'HealComm_HealUpdated')
		HealComm.UnregisterCallback(element, 'HealComm_HealDelayed')
		HealComm.UnregisterCallback(element, 'HealComm_HealStopped')
		HealComm.UnregisterCallback(element, 'HealComm_ModifierChanged')
		HealComm.UnregisterCallback(element, 'HealComm_GUIDDisappeared')
	end
end

local function Enable(self)
	local element = self.HealthPrediction
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element.SetUseHealComm = SetUseHealComm

		oUF:RegisterEvent(self, 'UNIT_MAXHEALTH', Path)
		oUF:RegisterEvent(self, 'UNIT_HEAL_PREDICTION', Path)

		if oUF.isClassic then
			oUF:RegisterEvent(self, 'UNIT_HEALTH_FREQUENT', Path)
		else
			oUF:RegisterEvent(self, 'UNIT_HEALTH', Path)
		end

		if oUF.isRetail then
			oUF:RegisterEvent(self, 'UNIT_ABSORB_AMOUNT_CHANGED', Path)
			oUF:RegisterEvent(self, 'UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
		else
			element:SetUseHealComm(true)
		end

		-- Get widgets using Retail names with legacy fallbacks
		local healingAllBar = GetWidget(element, 'healingAll', 'myBar')
		local damageAbsorbBar = GetWidget(element, 'damageAbsorb', 'absorbBar')
		local healAbsorbBar = GetWidget(element, 'healAbsorb', 'healAbsorbBar')
		local overDamageIndicator = GetWidget(element, 'overDamageAbsorbIndicator', 'overAbsorb')
		local overHealIndicator = GetWidget(element, 'overHealAbsorbIndicator', 'overHealAbsorb')

		if healingAllBar then
			if healingAllBar:IsObjectType('StatusBar') and not healingAllBar:GetStatusBarTexture() then
				healingAllBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if damageAbsorbBar then
			if damageAbsorbBar:IsObjectType('StatusBar') and not damageAbsorbBar:GetStatusBarTexture() then
				damageAbsorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if healAbsorbBar then
			if healAbsorbBar:IsObjectType('StatusBar') and not healAbsorbBar:GetStatusBarTexture() then
				healAbsorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if overDamageIndicator then
			if overDamageIndicator:IsObjectType('Texture') and not overDamageIndicator:GetTexture() then
				overDamageIndicator:SetTexture([[Interface\RaidFrame\Shield-Overshield]])
				overDamageIndicator:SetBlendMode('ADD')
			end
		end

		if overHealIndicator then
			if overHealIndicator:IsObjectType('Texture') and not overHealIndicator:GetTexture() then
				overHealIndicator:SetTexture([[Interface\RaidFrame\Absorb-Overabsorb]])
				overHealIndicator:SetBlendMode('ADD')
			end
		end

		return true
	end
end

local function Disable(self)
	local element = self.HealthPrediction
	if element then
		-- Get widgets using Retail names with legacy fallbacks
		local healingAllBar = GetWidget(element, 'healingAll', 'myBar')
		local damageAbsorbBar = GetWidget(element, 'damageAbsorb', 'absorbBar')
		local healAbsorbBar = GetWidget(element, 'healAbsorb', 'healAbsorbBar')
		local overDamageIndicator = GetWidget(element, 'overDamageAbsorbIndicator', 'overAbsorb')
		local overHealIndicator = GetWidget(element, 'overHealAbsorbIndicator', 'overHealAbsorb')

		if healingAllBar then
			healingAllBar:Hide()
		end

		if damageAbsorbBar then
			damageAbsorbBar:Hide()
		end

		if healAbsorbBar then
			healAbsorbBar:Hide()
		end

		if overDamageIndicator then
			overDamageIndicator:Hide()
		end

		if overHealIndicator then
			overHealIndicator:Hide()
		end

		oUF:UnregisterEvent(self, 'UNIT_MAXHEALTH', Path)
		oUF:UnregisterEvent(self, 'UNIT_HEAL_PREDICTION', Path)

		if oUF.isClassic then
			oUF:UnregisterEvent(self, 'UNIT_HEALTH_FREQUENT', Path)
		else
			oUF:UnregisterEvent(self, 'UNIT_HEALTH', Path)
		end

		if oUF.isRetail then
			oUF:UnregisterEvent(self, 'UNIT_ABSORB_AMOUNT_CHANGED', Path)
			oUF:UnregisterEvent(self, 'UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
		else
			element:SetUseHealComm(false)
		end
	end
end

oUF:AddElement('HealthPrediction', Path, Enable, Disable)
