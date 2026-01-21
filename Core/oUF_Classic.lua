---@diagnostic disable: missing-parameter
local SUI = SUI
local unpack = unpack

--------------   oUF Functions   ------------------------------------
local function getCurrentUnitHP(unitid)
	local aCurrentHP = 0
	local aMaxHP = 0
	if RealMobHealth and RealMobHealth.UnitHasHealthData(unitid) and RealMobHealth.GetUnitHealth then
		aCurrentHP, aMaxHP = RealMobHealth.GetUnitHealth(unitid)
	else
		aCurrentHP = UnitHealth(unitid) or 0
	end
	return aCurrentHP
end

local function getMaxUnitHP(unitid)
	local aCurrentHP = 0
	local aMaxHP = 0
	if RealMobHealth and RealMobHealth.UnitHasHealthData(unitid) and RealMobHealth.GetUnitHealth then
		aCurrentHP, aMaxHP = RealMobHealth.GetUnitHealth(unitid)
	else
		aMaxHP = UnitHealthMax(unitid) or 1
	end
	return aMaxHP
end

do -- TargetIndicator as an SUIUF module
	local Update = function(self, event, unit)
		if self.TargetIndicator.bg1:IsVisible() then
			self.TargetIndicator.bg1:Hide()
			self.TargetIndicator.bg2:Hide()
		end
		if UnitExists('target') and C_NamePlate.GetNamePlateForUnit('target') and SUI:GetModule('Module_Nameplates').DB.ShowTarget then
			if self:GetName() == 'oUF_Spartan_NamePlates' .. C_NamePlate.GetNamePlateForUnit('target'):GetName() then
				self.TargetIndicator.bg1:Show()
				self.TargetIndicator.bg2:Show()
			end
		end
	end
	local function ForceUpdate(element)
		return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
	end
	local Enable = function(self)
		local icon = self.TargetIndicator
		if icon then
			icon.__owner = self
			icon.ForceUpdate = ForceUpdate
			self:RegisterEvent('PLAYER_TARGET_CHANGED', Update, true)
		end
	end
	local Disable = function(self)
		local icon = self.TargetIndicator
		if icon then
			self:UnregisterEvent('PLAYER_TARGET_CHANGED', Update)
			icon:Hide()
		end
	end
	SUIUF:AddElement('TargetIndicator', Update, Enable, Disable)
end

do -- Level Skull as an SUIUF module
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
	SUIUF:AddElement('LevelSkull', Update, Enable, Disable)
end

do -- Rare / Elite dragon graphic as an SUIUF module
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
	SUIUF:AddElement('RareElite', Update, Enable, Disable)
end

do -- SUI_RaidGroup as an SUIUF module
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
	SUIUF:AddElement('SUI_RaidGroup', Update, Enable, Disable)
end

-- AFK / DND status text, as an SUIUF module
SUIUF.Tags.Events['afkdnd'] = 'PLAYER_FLAGS_CHANGED PLAYER_TARGET_CHANGED UNIT_TARGET'
SUIUF.Tags.Methods['afkdnd'] = function(unit)
	if unit then
		return UnitIsAFK(unit) and 'AFK' or UnitIsDND(unit) and 'DND' or ''
	end
end

if SUI.IsRetail then
	SUIUF.Tags.Events['title'] = 'UNIT_NAME_UPDATE INSTANCE_ENCOUNTER_ENGAGE_UNIT'
	SUIUF.Tags.Methods['title'] = function(unit)
		if UnitIsPlayer(unit) then
			return GetTitleName(GetCurrentTitle())
		end
	end
	SUIUF.Tags.Events['specialization'] = 'PLAYER_TALENT_UPDATE'
	SUIUF.Tags.Methods['specialization'] = function(unit)
		if UnitIsPlayer(unit) then
			local currentSpec = GetSpecialization()
			if currentSpec then
				local _, currentSpecName = GetSpecializationInfo(currentSpec)
				if currentSpecName then
					return currentSpecName
				end
			end
		end
	end
end

local function dynamicCalc(num)
	if num >= 1000000000 then
		return SUI:round(num / 1000000000, 1) .. 'B'
	elseif num >= 1000000 then
		return SUI:round(num / 1000000, 1) .. 'M'
	else
		return SUI.Font:comma_value(num)
	end
end

local function shortCalc(num)
	if num >= 1000000 then
		return SUI:round(num / 1000000, 0) .. 'M'
	elseif num >= 1000 then
		return SUI:round(num / 1000, 0) .. 'K'
	else
		return SUI.Font:comma_value(num)
	end
end

local function calculateResult(currentVal, maxVal, isDead, ...)
	local returnVal = ''
	local num = currentVal

	for i = 1, select('#', ...) do
		local var = tostring(select(i, ...))
		if var == 'missing' then
			num = maxVal - currentVal
		elseif var == 'max' then
			num = maxVal
		end
	end

	for i = 1, select('#', ...) do
		local var = tostring(select(i, ...))

		if var == 'percentage' then
			returnVal = math.floor(currentVal / maxVal * 100 + 0.5) .. '%'
		elseif var == 'dynamic' then
			returnVal = dynamicCalc(num)
		elseif var == 'short' then
			returnVal = shortCalc(num)
		elseif var == 'hideDead' and isDead then
			return ''
		elseif var == 'displayDead' and isDead then
			return 'Dead'
		elseif var == 'hideZero' and (currentVal == 0 or num == 0) then
			return ''
		elseif var == 'hideMax' and currentVal == maxVal then
			return ''
		end
	end
	if returnVal == '' then
		returnVal = SUI.Font:comma_value(num)
	end

	return returnVal
end

local function SUIHealth(unit, _, ...)
	local currentVal = getCurrentUnitHP(unit) or 0
	local maxVal = getMaxUnitHP(unit) or currentVal
	local isDead = UnitIsDeadOrGhost(unit)

	return calculateResult(currentVal, maxVal, isDead, ...)
end

local function SUIPower(unit, _, ...)
	local returnVal = ''
	if not ... then
		return returnVal
	end

	local currentVal = UnitPower(unit) or 0
	local maxVal = UnitPowerMax(unit) or currentVal
	local isDead = UnitIsDeadOrGhost(unit)

	return calculateResult(currentVal, maxVal, isDead, ...)
end

SUIUF.Tags.Events['SUIHealth'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
SUIUF.Tags.Methods['SUIHealth'] = SUIHealth

SUIUF.Tags.Events['SUIPower'] = 'UNIT_MAXPOWER UNIT_POWER_UPDATE'
SUIUF.Tags.Methods['SUIPower'] = SUIPower

do --LEGACY Health Formatting Tags
	local listing = {
		['health:current-short'] = {'short'},
		['health:current-dynamic'] = {'dynamic'},
		['health:current-formatted'] = {},
		['health:max-short'] = {'max', 'short'},
		['health:max-dynamic'] = {'max', 'dynamic'},
		['health:max-formatted'] = {'max'},
		['health:missing-short'] = {'missing', 'short'},
		['health:missing-dynamic'] = {'missing', 'dynamic'},
		['health:missing-formatted'] = {'missing'}
	}
	for k, v in pairs(listing) do
		SUIUF.Tags.Events[k] = 'UNIT_HEALTH UNIT_MAXHEALTH'
		SUIUF.Tags.Methods[k] = function(unit)
			return SUIHealth(unit, nil, unpack(v or {}))
		end
	end
end

do -- LEGACY Mana Formatting Tags
	local listing = {
		['power:current-short'] = {'short'},
		['power:current-dynamic'] = {'dynamic'},
		['power:current-formatted'] = {},
		['power:max-short'] = {'max', 'short'},
		['power:max-dynamic'] = {'max', 'dynamic'},
		['power:max-formatted'] = {'max'},
		['power:missing-short'] = {'missing', 'short'},
		['power:missing-dynamic'] = {'missing', 'dynamic'},
		['power:missing-formatted'] = {'missing'}
	}
	for k, v in pairs(listing) do
		SUIUF.Tags.Events[k] = 'UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT'
		SUIUF.Tags.Methods[k] = function(unit)
			return SUIPower(unit, nil, unpack(v))
		end
	end
end

do --Color name by Class
	local function hex(r, g, b)
		if r then
			if type(r) == 'table' then
				if r.r then
					r, g, b = r.r, r.g, r.b
				else
					r, g, b = unpack(r)
				end
			end
			return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
		end
	end

	SUIUF.Tags.Events['SUI_ColorClass'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['SUI_ColorClass'] = function(u)
		local _, class = UnitClass(u)

		if u == 'pet' then
			return hex(SUIUF.colors.class[class])
		elseif UnitIsPlayer(u) then
			return hex(SUIUF.colors.class[class])
		else
			return hex(1, 1, 1)
		end
	end
end
