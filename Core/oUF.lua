---@diagnostic disable: missing-parameter
local SUI = SUI
local unpack = unpack

--------------   oUF Functions   ------------------------------------
function SUI:HotsListing()
	local _, classFileName = UnitClass('player')
	local lifebloomInfo = C_Spell.GetSpellInfo('Lifebloom')
	local lifebloomSpellId = lifebloomInfo and lifebloomInfo.spellID
	if classFileName == 'DRUID' then
		return {
			774, -- Rejuvenation
			lifebloomSpellId, -- Lifebloom
			8936, -- Regrowth
			48438, -- Wild Growth
			155777, -- Germination
			102351, -- Cenarion Ward
			102342 -- Ironbark
		}
	elseif classFileName == 'PRIEST' then
		if SUI.IsClassic then
			return {
				139, -- Renew
				17 -- sheild
			}
		else
			return {
				139, -- Renew
				17, -- sheild
				33076 -- Prayer of Mending
			}
		end
	elseif classFileName == 'MONK' then
		return {
			119611, -- Renewing Mist
			227345 -- Enveloping Mist
		}
	end
	return {}
end

do -- TargetIndicator as an SUIUF module
	local Update = function(self, event, unit)
		if self.TargetIndicator.bg1:IsVisible() then
			self.TargetIndicator.bg1:Hide()
			self.TargetIndicator.bg2:Hide()
		end
		if UnitExists('target') and C_NamePlate.GetNamePlateForUnit('target') and SUI:GetModule('Nameplates').DB.ShowTarget then
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

--[[ WoW 12.0 UPDATED: Custom health/power tags rebuilt using secret-safe APIs

     OLD APPROACH (Broken in 12.0):
     - Performed arithmetic on UnitHealth/UnitPower secret values
     - Used division/multiplication for percentages and abbreviations

     NEW APPROACH (12.0 Compatible):
     - Uses AbbreviateNumbers() for K/M/B formatting (secret-safe)
     - Uses UnitHealthMissing() instead of subtraction (secret-safe)
     - Uses UnitHealthPercent() for percentage display (secret-safe)
     - Uses BreakUpLargeNumbers() for comma formatting (secret-safe)

     SUPPORTED OPTIONS:
     ✅ displayDead - Show "Dead" when unit is dead
     ✅ hideDead - Hide output when unit is dead
     ✅ hideZero - Hide when value is 0
     ✅ short/dynamic - K/M/B abbreviations (e.g., "1.2K", "45M")
     ✅ percentage - Show as percentage (e.g., "75")
     ✅ missing - Show missing health/power
     ✅ max - Show max health/power
     ✅ plain - No formatting, raw value
     ✅ comma/formatted - Comma-separated (e.g., "1,234,567") - DEFAULT if no format specified
     ❌ hideMax - REMOVED (requires comparing secrets - impossible in 12.0)

     See: https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes#Secret_values
--]]

---Formats health/power values using WoW 12.0 secret-safe APIs
---@param unit string Unit token
---@param _ any Unused realUnit parameter
---@param ... string Options: displayDead, hideDead, hideZero, short, dynamic, percentage, missing, max
---@return string|nil Formatted value or nil to hide
local function SUIHealth(unit, _, ...)
	local isDead = UnitIsDeadOrGhost(unit)

	-- Handle dead state first
	for i = 1, select('#', ...) do
		local var = tostring(select(i, ...))
		if var == 'hideDead' and isDead then
			return '' -- Hide when dead
		elseif var == 'displayDead' and isDead then
			return 'Dead' -- Show "Dead" text
		end
	end

	-- Check if percentage format requested
	local wantsPercentage = false
	for i = 1, select('#', ...) do
		if tostring(select(i, ...)) == 'percentage' then
			wantsPercentage = true
			break
		end
	end

	-- Handle percentage display (uses secret-safe UnitHealthPercent)
	if wantsPercentage then
		local percent = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
		-- Check hideZero
		for i = 1, select('#', ...) do
			if tostring(select(i, ...)) == 'hideZero' then
				local truncated = C_StringUtil.TruncateWhenZero(percent)
				if not truncated then return '' end
				break
			end
		end
		return string.format('%d', percent)
	end

	-- Determine which value to display (current, missing, or max)
	local value
	for i = 1, select('#', ...) do
		local var = tostring(select(i, ...))
		if var == 'missing' then
			value = UnitHealthMissing(unit) -- Secret-safe subtraction
		elseif var == 'max' then
			value = UnitHealthMax(unit)
		end
	end

	-- Default to current health if no specific value requested
	if not value then
		value = UnitHealth(unit)
	end

	-- Check hideZero option
	for i = 1, select('#', ...) do
		if tostring(select(i, ...)) == 'hideZero' then
			local truncated = C_StringUtil.TruncateWhenZero(value)
			if not truncated then return '' end
			break
		end
	end

	-- Format the value based on options
	for i = 1, select('#', ...) do
		local var = tostring(select(i, ...))
		if var == 'short' or var == 'dynamic' then
			return AbbreviateNumbers(value) -- Secret-safe abbreviation (1.2K, 45M, etc)
		elseif var == 'plain' then
			return tostring(value) -- Plain, unformatted value
		elseif var == 'comma' or var == 'formatted' then
			return BreakUpLargeNumbers(value) -- Comma-separated (1,234,567)
		end
	end

	-- Default: comma formatting
	return BreakUpLargeNumbers(value)
end

---Formats power values using WoW 12.0 secret-safe APIs
---@param unit string Unit token
---@param _ any Unused realUnit parameter
---@param ... string Options: displayDead, hideDead, hideZero, short, dynamic, percentage, missing, max
---@return string|nil Formatted value or nil to hide
local function SUIPower(unit, _, ...)
	-- Return empty if no options provided
	if not ... then
		return ''
	end

	local isDead = UnitIsDeadOrGhost(unit)

	-- Handle dead state first
	for i = 1, select('#', ...) do
		local var = tostring(select(i, ...))
		if var == 'hideDead' and isDead then
			return '' -- Hide when dead
		elseif var == 'displayDead' and isDead then
			return 'Dead' -- Show "Dead" text
		end
	end

	-- Check if percentage format requested
	local wantsPercentage = false
	for i = 1, select('#', ...) do
		if tostring(select(i, ...)) == 'percentage' then
			wantsPercentage = true
			break
		end
	end

	-- Handle percentage display (uses secret-safe UnitPowerPercent)
	if wantsPercentage then
		local percent = UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100)
		-- Check hideZero
		for i = 1, select('#', ...) do
			if tostring(select(i, ...)) == 'hideZero' then
				local truncated = C_StringUtil.TruncateWhenZero(percent)
				if not truncated then return '' end
				break
			end
		end
		return string.format('%d', percent)
	end

	-- Determine which value to display (current, missing, or max)
	local value
	for i = 1, select('#', ...) do
		local var = tostring(select(i, ...))
		if var == 'missing' then
			value = UnitPowerMissing(unit) -- Secret-safe subtraction
		elseif var == 'max' then
			value = UnitPowerMax(unit)
		end
	end

	-- Default to current power if no specific value requested
	if not value then
		value = UnitPower(unit)
	end

	-- Check hideZero option
	for i = 1, select('#', ...) do
		if tostring(select(i, ...)) == 'hideZero' then
			local truncated = C_StringUtil.TruncateWhenZero(value)
			if not truncated then return '' end
			break
		end
	end

	-- Format the value based on options
	for i = 1, select('#', ...) do
		local var = tostring(select(i, ...))
		if var == 'short' or var == 'dynamic' then
			return AbbreviateNumbers(value) -- Secret-safe abbreviation (1.2K, 45M, etc)
		elseif var == 'plain' then
			return tostring(value) -- Plain, unformatted value
		elseif var == 'comma' or var == 'formatted' then
			return BreakUpLargeNumbers(value) -- Comma-separated (1,234,567)
		end
	end

	-- Default: comma formatting
	return BreakUpLargeNumbers(value)
end

-- Register the custom tags with oUF
SUIUF.Tags.Events['SUIHealth'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
SUIUF.Tags.Methods['SUIHealth'] = SUIHealth

SUIUF.Tags.Events['SUIPower'] = 'UNIT_MAXPOWER UNIT_POWER_UPDATE'
SUIUF.Tags.Methods['SUIPower'] = SUIPower

do --LEGACY Health Formatting Tags (for backwards compatibility)
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

do -- LEGACY Power Formatting Tags (for backwards compatibility)
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
