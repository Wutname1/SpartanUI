local addon = LibStub('AceAddon-3.0'):GetAddon('SpartanUI')

--------------   oUF Functions   ------------------------------------
function addon:HotsListing()
	local _, classFileName = UnitClass('player')
	local LifebloomSpellId = select(7, GetSpellInfo('Lifebloom'))
	if classFileName == 'DRUID' then
		return {
			774, -- Rejuvenation
			LifebloomSpellId, -- Lifebloom
			8936 -- Regrowth
			-- 48438, -- Wild Growth
			-- 155777, -- Germination
			-- 102351, -- Cenarion Ward
			-- 102342 -- Ironbark
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

function addon:oUF_Buffs(self, point, relativePoint, SizeModifier)
	if self == nil then
		return
	end
	if point == nil then
		point = 'TOPRIGHT'
	end
	if relativePoint == nil then
		relativePoint = 'TOPRIGHT'
	end
	if SizeModifier == nil then
		SizeModifier = 0
	end

	local auras = {}
	local spellIDs = addon:HotsListing()
	auras.presentAlpha = 1
	auras.onlyShowPresent = true
	-- auras.PostCreateIcon = myCustomIconSkinnerFunction

	-- Make icons table if needed
	if auras.icons == nil then
		auras.icons = {}
	end

	-- Set any other AuraWatch settings

	for i, sid in pairs(spellIDs) do
		local icon = CreateFrame('Frame', nil, self)
		icon.spellID = sid
		-- set the dimensions and positions
		local size = SUI.DB.PartyFrames.Auras.size + SizeModifier
		icon:SetSize(size, size)
		icon:SetPoint(point, self, relativePoint, (-icon:GetWidth() * (i - 1)) - 2, -2)

		local cd = CreateFrame('Cooldown', nil, icon)
		cd:SetAllPoints(icon)
		icon.cd = cd

		auras.icons[sid] = icon
		-- Set any other AuraWatch icon settings
	end
	return auras
end

function addon:pvpIcon(self, event, unit)
	if (unit ~= self.unit) then
		return
	end

	local pvp = self.PvP
	if (pvp.PreUpdate) then
		pvp:PreUpdate()
	end
	pvp:SetFrameStrata('LOW')

	if pvp.shadow == nil then
		pvp.shadow = self:CreateTexture(nil, 'BACKGROUND')
		pvp.shadow:SetSize(pvp:GetSize())
		pvp.shadow:SetParent(pvp)
		pvp.shadow:SetPoint('CENTER', pvp, 'CENTER', 2, -2)
		pvp.shadow:SetVertexColor(0, 0, 0, .9)
	end

	local status
	local factionGroup = UnitFactionGroup(unit) or 'Neutral'
	if (UnitIsPVPFreeForAll(unit)) then
		pvp:SetTexture('Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon')
		status = 'ffa'
	elseif (factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(unit)) then
		pvp:SetTexture('Interface\\FriendsFrame\\PlusManz-' .. factionGroup)
		pvp.shadow:SetTexture('Interface\\FriendsFrame\\PlusManz-' .. factionGroup)
		status = factionGroup
	end

	if (status) then
		-- pvp.shadow:Show()
		pvp:Show()
	else
		-- pvp.shadow:Hide()
		pvp:Hide()
	end

	if (pvp.PostUpdate) then
		return pvp:PostUpdate(status)
	end
end

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

do -- ClassIcon as an SUIUF module
	local ClassIconCoord = {
		WARRIOR = {0.00, 0.25, 0.00, 0.25},
		MAGE = {0.25, 0.50, 0.00, 0.25},
		ROGUE = {0.50, 0.75, 0.00, 0.25},
		DRUID = {0.75, 1.00, 0.00, 0.25},
		HUNTER = {0.00, 0.25, 0.25, 0.50},
		SHAMAN = {0.25, 0.50, 0.25, 0.50},
		PRIEST = {0.50, 0.75, 0.25, 0.50},
		WARLOCK = {0.75, 1.00, 0.25, 0.50},
		PALADIN = {0.00, 0.25, 0.50, 0.75},
		DEATHKNIGHT = {0.25, 0.50, 0.50, 0.75},
		MONK = {0.50, 0.75, 0.50, 0.75},
		DEMONHUNTER = {0.75, 1.00, 0.50, 0.75},
		DEFAULT = {0.75, 1.00, 0.75, 1.00}
	}
	local Update = function(self, event, unit)
		local icon = self.SUI_ClassIcon
		if (icon) then
			local _, class = UnitClass(self.unit)
			if not class then
				return
			end

			local path = 'Interface\\AddOns\\SpartanUI\\images\\flat_classicons\\' .. (string.lower(class))

			if class then
				-- local coords = ClassIconCoord[class or 'DEFAULT']
				-- icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
				icon:SetTexture(path)
				icon:Show()
				if icon.shadow then
					icon.shadow:SetTexture(path)
					icon.shadow:Show()
				end
			else
				icon:Hide()
				icon.shadow:Hide()
			end
		end
	end
	local function ForceUpdate(element)
		return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
	end
	local Enable = function(self)
		local icon = self.SUI_ClassIcon
		if (icon) then
			icon.__owner = self
			icon.ForceUpdate = ForceUpdate
			self:RegisterEvent('PLAYER_TARGET_CHANGED', Update, true)
			self:RegisterEvent('UNIT_PET', Update, true)
			if icon.shadow == nil then
				icon.shadow = self:CreateTexture(nil, 'BACKGROUND')
				icon.shadow:SetSize(icon:GetSize())
				icon.shadow:SetPoint('CENTER', icon, 'CENTER', 2, -2)
				icon.shadow:SetVertexColor(0, 0, 0, .9)
			end
			return true
		end
	end
	local Disable = function(self)
		local icon = self.SUI_ClassIcon
		if (icon) then
			self:UnregisterEvent('PLAYER_TARGET_CHANGED', Update)
			self:UnregisterEvent('UNIT_PET', Update)
			self.SUI_ClassIcon:Hide()
			self.SUI_ClassIcon.shadow:Hide()
		end
	end
	SUIUF:AddElement('SUI_ClassIcon', Update, Enable, Disable)
end

do -- TargetIndicator as an SUIUF module
	local Update = function(self, event, unit)
		if self.TargetIndicator.bg1:IsVisible() then
			self.TargetIndicator.bg1:Hide()
			self.TargetIndicator.bg2:Hide()
		end
		if
			UnitExists('target') and C_NamePlate.GetNamePlateForUnit('target') and
				SUI:GetModule('Component_Nameplates').DB.ShowTarget
		 then
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
		if (icon) then
			icon.__owner = self
			icon.ForceUpdate = ForceUpdate
			self:RegisterEvent('PLAYER_TARGET_CHANGED', Update, true)
		end
	end
	local Disable = function(self)
		local icon = self.TargetIndicator
		if (icon) then
			self:UnregisterEvent('PLAYER_TARGET_CHANGED', Update)
			icon:Hide()
		end
	end
	SUIUF:AddElement('TargetIndicator', Update, Enable, Disable)
end

do -- Level Skull as an SUIUF module
	local Update = function(self, event, unit)
		if (self.unit ~= unit) then
			return
		end
		if (not self.LevelSkull) then
			return
		end
		local level = UnitLevel(unit)
		self.LevelSkull:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame-Skull')
		if level < 0 then
			self.LevelSkull:SetTexCoord(0, 1, 0, 1)
			if self.Level then
				self.Level:SetText ''
			end
		else
			self.LevelSkull:SetTexCoord(0, 0.01, 0, 0.01)
		end
	end
	local function ForceUpdate(element)
		return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
	end
	local Enable = function(self)
		if (self.LevelSkull) then
			self.LevelSkull.__owner = self
			self.LevelSkull.ForceUpdate = ForceUpdate
			return true
		end
	end
	local Disable = function(self)
		if (self.LevelSkull) then
			self.LevelSkull:Hide()
		end
		return
	end
	SUIUF:AddElement('LevelSkull', Update, Enable, Disable)
end

do -- Rare / Elite dragon graphic as an SUIUF module
	local Update = function(self, event, unit)
		if (self.unit ~= unit) then
			return
		end
		if (not self.RareElite) then
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

		if (element:IsObjectType 'Texture' and not element:GetTexture()) then
			element:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\elite_rare')
			element:SetTexCoord(0, 1, 0, 1)
			element:SetAlpha(.75)
			if element.short == true then
				element:SetTexCoord(0, 1, 0, .7)
			end
			if element.small == true then
				element:SetTexCoord(0, 1, 0, .4)
			end
		end
		element:Show()
	end
	local function ForceUpdate(element)
		return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
	end
	local Enable = function(self)
		if (self.RareElite) then
			self.RareElite.__owner = self
			self.RareElite.ForceUpdate = ForceUpdate
			self.RareElite:Hide()
			return true
		end
	end

	local Disable = function(self)
		if (self.RareElite) then
			self.RareElite:Hide()
		end
		return
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
		if (self.SUI_RaidGroup) then
			self:RegisterEvent('GROUP_ROSTER_UPDATE', Update, true)
			return true
		end
	end
	local Disable = function(self)
		if (self.SUI_RaidGroup) then
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

do --Health Formatting Tags
	-- Current Health Short, as an SUIUF module
	SUIUF.Tags.Events['health:current-short'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['health:current-short'] = function(unit)
		local tmp = getCurrentUnitHP(unit)
		if tmp >= 1000000 then
			return addon:round(tmp / 1000000, 0) .. 'M'
		end
		if tmp >= 1000 then
			return addon:round(tmp / 1000, 0) .. 'K'
		end
		return addon:comma_value(tmp)
	end
	-- Current Health Dynamic, as an SUIUF module
	SUIUF.Tags.Events['health:current-dynamic'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['health:current-dynamic'] = function(unit)
		local tmp = getCurrentUnitHP(unit)
		if tmp >= 1000000 then
			return addon:round(tmp / 1000000, 1) .. 'M '
		else
			return addon:comma_value(tmp)
		end
	end
	-- Current Health formatted, as an SUIUF module
	SUIUF.Tags.Events['health:current-formatted'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['health:current-formatted'] = function(unit)
		return addon:comma_value(getCurrentUnitHP(unit))
	end

	-- Total Health Short, as an SUIUF module
	SUIUF.Tags.Events['health:max-short'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['health:max-short'] = function(unit)
		local tmp = getMaxUnitHP(unit)
		if tmp >= 1000000 then
			return addon:round(tmp / 1000000, 0) .. 'M'
		end
		if tmp >= 1000 then
			return addon:round(tmp / 1000, 0) .. 'K'
		end
		return addon:comma_value(tmp)
	end
	-- Total Health Dynamic, as an SUIUF module
	SUIUF.Tags.Events['health:max-dynamic'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['health:max-dynamic'] = function(unit)
		local tmp = getMaxUnitHP(unit)
		if tmp >= 1000000 then
			return addon:round(tmp / 1000000, 1) .. 'M '
		else
			return addon:comma_value(tmp)
		end
	end
	-- Total Health formatted, as an SUIUF module
	SUIUF.Tags.Events['health:max-formatted'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['health:max-formatted'] = function(unit)
		return addon:comma_value(getMaxUnitHP(unit))
	end

	-- Missing Health Dynamic, as an SUIUF module
	SUIUF.Tags.Events['health:missing-dynamic'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['health:missing-dynamic'] = function(unit)
		local tmp = getMaxUnitHP(unit) - getCurrentUnitHP(unit)
		if tmp >= 1000000 then
			return addon:round(tmp / 1000000, 1) .. 'M '
		else
			return addon:comma_value(tmp)
		end
	end
	-- Missing Health formatted, as an SUIUF module
	SUIUF.Tags.Events['health:missing-formatted'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['health:missing-formatted'] = function(unit)
		return addon:comma_value(getMaxUnitHP(unit) - getCurrentUnitHP(unit))
	end
end

do -- Mana Formatting Tags
	-- Current Mana Dynamic, as an SUIUF module
	SUIUF.Tags.Events['power:current-dynamic'] = 'UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT'
	SUIUF.Tags.Methods['power:current-dynamic'] = function(unit)
		local tmp = UnitPower(unit)
		if tmp >= 1000000 then
			return addon:round(tmp / 1000000, 1) .. 'M '
		else
			return addon:comma_value(tmp)
		end
	end
	-- Current Mana formatted, as an SUIUF module
	SUIUF.Tags.Events['power:current-formatted'] = 'UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT'
	SUIUF.Tags.Methods['power:current-formatted'] = function(unit)
		return addon:comma_value(UnitPower(unit))
	end

	-- Total Mana Dynamic, as an SUIUF module
	SUIUF.Tags.Events['power:max-dynamic'] = 'UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT'
	SUIUF.Tags.Methods['power:max-dynamic'] = function(unit)
		local tmp = UnitPowerMax(unit)
		if tmp >= 1000000 then
			return addon:round(tmp / 1000000, 1) .. 'M '
		else
			return addon:comma_value(tmp)
		end
	end
	-- Total Mana formatted, as an SUIUF module
	SUIUF.Tags.Events['power:max-formatted'] = 'UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT'
	SUIUF.Tags.Methods['power:max-formatted'] = function(unit)
		return addon:comma_value(UnitPowerMax(unit))
	end

	-- Missing Mana Dynamic, as an SUIUF module
	SUIUF.Tags.Events['power:missing-dynamic'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
	SUIUF.Tags.Methods['power:missing-dynamic'] = function(unit)
		local tmp = UnitPowerMax(unit) - UnitPower(unit)
		if tmp >= 1000000 then
			return addon:round(tmp / 1000000, 1) .. 'M '
		else
			return addon:comma_value(tmp)
		end
	end
	-- Missing Mana formatted, as an SUIUF module
	SUIUF.Tags.Events['power:missing-formatted'] = 'UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT'
	SUIUF.Tags.Methods['power:missing-formatted'] = function(unit)
		return addon:comma_value(UnitPowerMax(unit) - UnitPower(unit))
	end
end

do --Color name by Class
	local function hex(r, g, b)
		if r then
			if (type(r) == 'table') then
				if (r.r) then
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

		if (u == 'pet') then
			return hex(SUIUF.colors.class[class])
		elseif (UnitIsPlayer(u)) then
			return hex(SUIUF.colors.class[class])
		else
			return hex(1, 1, 1)
		end
	end
end
