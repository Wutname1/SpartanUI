local SUI = SUI
----------------------------------------------------------------------------------------------------

do -- ClassIcon as an SpartanoUF module
	local Update = function(self, event, unit)
		local icon = self.SUI_ClassIcon
		if (icon) then
			local _, class = UnitClass(self.unit)
			if class then
				-- local coords = ClassIconCoord[class or "DEFAULT"];
				-- icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
				local path = 'Interface\\AddOns\\SpartanUI\\media\\flat_classicons\\wow_flat_' .. (string.lower(class))
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
	local Enable = function(self)
		local icon = self.SUI_ClassIcon
		if (icon) then
			--self:RegisterEvent("PARTY_MEMBERS_CHANGED", Update);
			self:RegisterEvent('PLAYER_TARGET_CHANGED', Update)
			self:RegisterEvent('UNIT_PET', Update)
			icon:SetTexture('Interface\\AddOns\\SpartanUI\\media\\icon_class')
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
			--self:UnregisterEvent("PARTY_MEMBERS_CHANGED", Update);
			self:UnregisterEvent('PLAYER_TARGET_CHANGED', Update)
			self:UnregisterEvent('UNIT_PET', Update)
		end
	end
	SpartanoUF:AddElement('SUI_ClassIcon', Update, Enable, Disable)
end

do -- TargetIndicator as an SpartanoUF module
	local Update = function(self, event, unit)
		if self.TargetIndicator.bg1:IsVisible() then
			self.TargetIndicator.bg1:Hide()
			self.TargetIndicator.bg2:Hide()
		end
		if UnitExists('target') and C_NamePlate.GetNamePlateForUnit('target') and SUI.DBMod.NamePlates.ShowTarget then
			if self:GetName() == 'oUF_Spartan_NamePlates' .. C_NamePlate.GetNamePlateForUnit('target'):GetName() then
				self.TargetIndicator.bg1:Show()
				self.TargetIndicator.bg2:Show()
			end
		end
	end
	local Enable = function(self)
		local icon = self.TargetIndicator
		if (icon) then
			self:RegisterEvent('PLAYER_TARGET_CHANGED', Update)
		end
	end
	local Disable = function(self)
		local icon = self.TargetIndicator
		if (icon) then
			self:UnregisterEvent('PLAYER_TARGET_CHANGED', Update)
		end
	end
	SpartanoUF:AddElement('TargetIndicator', Update, Enable, Disable)
end

do -- Boss graphic as an SpartanoUF module
	local Update = function(self, event, unit)
		if (self.unit ~= unit) then
			return
		end
		if (not self.BossGraphic) then
			return
		end
		self.BossGraphic:SetTexture('Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\elite_rare')
		self.BossGraphic:SetTexCoord(1, 0, 0, 1)
		self.BossGraphic:SetVertexColor(1, 0.9, 0, 1)
	end
	local Enable = function(self)
		if (self.BossGraphic) then
			return true
		end
	end
	local Disable = function(self)
		return
	end
	SpartanoUF:AddElement('BossGraphic', Update, Enable, Disable)
end

do -- SUI_RaidGroup as an SpartanoUF module
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
			self:RegisterEvent('GROUP_ROSTER_UPDATE', Update)
			return true
		end
	end
	local Disable = function(self)
		if (self.SUI_RaidGroup) then
			self:UnregisterEvent('GROUP_ROSTER_UPDATE', Update)
		end
	end
	SpartanoUF:AddElement('SUI_RaidGroup', Update, Enable, Disable)
end

do -- AFK / DND status text, as an SpartanoUF module
	SpartanoUF.Tags.Events['afkdnd'] = 'PLAYER_FLAGS_CHANGED PLAYER_TARGET_CHANGED UNIT_TARGET'
	SpartanoUF.Tags.Methods['afkdnd'] = function(unit)
		if unit then
			return UnitIsAFK(unit) and 'AFK' or UnitIsDND(unit) and 'DND' or ''
		end
	end
end

do --Health Formatting Tags
	-- Current Health Short, as an SpartanoUF module
	SpartanoUF.Tags.Events['curhpshort'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['curhpshort'] = function(unit)
		local tmp = UnitHealth(unit)
		if tmp >= 1000000 then
			return SUI:round(tmp / 1000000, 0) .. 'M'
		end
		if tmp >= 1000 then
			return SUI:round(tmp / 1000, 0) .. 'K'
		end
		return SUI:comma_value(tmp)
	end
	-- Current Health Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['curhpdynamic'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['curhpdynamic'] = function(unit)
		local tmp = UnitHealth(unit)
		if tmp >= 1000000 then
			return SUI:round(tmp / 1000000, 1) .. 'M '
		else
			return SUI:comma_value(tmp)
		end
	end
	-- Total Health Short, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxhpshort'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['maxhpshort'] = function(unit)
		local tmp = UnitHealthMax(unit)
		if tmp >= 1000000 then
			return SUI:round(tmp / 1000000, 0) .. 'M'
		end
		if tmp >= 1000 then
			return SUI:round(tmp / 1000, 0) .. 'K'
		end
		return SUI:comma_value(tmp)
	end
	-- Total Health Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxhpdynamic'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['maxhpdynamic'] = function(unit)
		local tmp = UnitHealthMax(unit)
		if tmp >= 1000000 then
			return SUI:round(tmp / 1000000, 1) .. 'M '
		else
			return SUI:comma_value(tmp)
		end
	end
	-- Missing Health Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['missinghpdynamic'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['missinghpdynamic'] = function(unit)
		local tmp = UnitHealthMax(unit) - UnitHealth(unit)
		if tmp >= 1000000 then
			return SUI:round(tmp / 1000000, 1) .. 'M '
		else
			return SUI:comma_value(tmp)
		end
	end
	-- Current Health formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['curhpformatted'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['curhpformatted'] = function(unit)
		return SUI:comma_value(UnitHealth(unit))
	end
	-- Total Health formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxhpformatted'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['maxhpformatted'] = function(unit)
		return SUI:comma_value(UnitHealthMax(unit))
	end
	-- Missing Health formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['missinghpformatted'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['missinghpformatted'] = function(unit)
		return SUI:comma_value(UnitHealthMax(unit) - UnitHealth(unit))
	end
end

do -- Mana Formatting Tags
	-- Current Mana Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['curppdynamic'] = 'UNIT_MAXPOWER UNIT_POWER_FREQUENT'
	SpartanoUF.Tags.Methods['curppdynamic'] = function(unit)
		local tmp = UnitPower(unit)
		if tmp >= 1000000 then
			return SUI:round(tmp / 1000000, 1) .. 'M '
		else
			return SUI:comma_value(tmp)
		end
	end
	-- Total Mana Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxppdynamic'] = 'UNIT_MAXPOWER UNIT_POWER_FREQUENT'
	SpartanoUF.Tags.Methods['maxppdynamic'] = function(unit)
		local tmp = UnitPowerMax(unit)
		if tmp >= 1000000 then
			return SUI:round(tmp / 1000000, 1) .. 'M '
		else
			return SUI:comma_value(tmp)
		end
	end
	-- Missing Mana Dynamic, as an SpartanoUF module
	SpartanoUF.Tags.Events['missingppdynamic'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['missingppdynamic'] = function(unit)
		local tmp = UnitPowerMax(unit) - UnitPower(unit)
		if tmp >= 1000000 then
			return SUI:round(tmp / 1000000, 1) .. 'M '
		else
			return SUI:comma_value(tmp)
		end
	end
	-- Current Mana formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['curppformatted'] = 'UNIT_MAXPOWER UNIT_POWER_FREQUENT'
	SpartanoUF.Tags.Methods['curppformatted'] = function(unit)
		return SUI:comma_value(UnitPower(unit))
	end
	-- Total Mana formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['maxppformatted'] = 'UNIT_MAXPOWER UNIT_POWER_FREQUENT'
	SpartanoUF.Tags.Methods['maxppformatted'] = function(unit)
		return SUI:comma_value(UnitPowerMax(unit))
	end
	-- Total Mana formatted, as an SpartanoUF module
	SpartanoUF.Tags.Events['missingppformatted'] = 'UNIT_MAXPOWER UNIT_POWER_FREQUENT'
	SpartanoUF.Tags.Methods['missingppformatted'] = function(unit)
		return SUI:comma_value(UnitPowerMax(unit) - UnitPower(unit))
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

	SpartanoUF.Tags.Events['SUI_ColorClass'] = 'UNIT_HEALTH'
	SpartanoUF.Tags.Methods['SUI_ColorClass'] = function(u)
		local _, class = UnitClass(u)

		if (u == 'pet') then
			return hex(SpartanoUF.colors.class[class])
		elseif (UnitIsPlayer(u)) then
			return hex(SpartanoUF.colors.class[class])
		else
			return hex(1, 1, 1)
		end
	end
end

do -- Level Skull as an SpartanoUF module
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
	local Enable = function(self)
		if (self.LevelSkull) then
			return true
		end
	end
	local Disable = function(self)
		return
	end
	SpartanoUF:AddElement('LevelSkull', Update, Enable, Disable)
end

do -- Rare / Elite dragon graphic as an SpartanoUF module
	local Update = function(self, event, unit)
		if (self.unit ~= unit) then
			return
		end
		if (not self.RareElite) then
			return
		end
		local c = UnitClassification(unit)

		if (self.RareElite:IsObjectType 'Texture' and not self.RareElite:GetTexture()) then
			self.RareElite:SetTexture('Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\elite_rare')
			self.RareElite:SetTexCoord(0, 1, 0, 1)
			self.RareElite:SetAlpha(.75)
			if self.RareElite.short == true then
				self.RareElite:SetTexCoord(0, 1, 0, .7)
			end
			if self.RareElite.small == true then
				self.RareElite:SetTexCoord(0, 1, 0, .4)
			end
		end
		self.RareElite:Show()
		if c == 'worldboss' or c == 'elite' or c == 'rareelite' then
			self.RareElite:SetVertexColor(1, 0.9, 0)
		elseif c == 'rare' then
			self.RareElite:SetVertexColor(1, 1, 1)
		else
			self.RareElite:Hide()
		end
	end
	local Enable = function(self)
		if (self.RareElite) then
			return true
		end
	end
	local Disable = function(self)
		return
	end
	SpartanoUF:AddElement('RareElite', Update, Enable, Disable)
end
