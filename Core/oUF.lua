local addon = LibStub('AceAddon-3.0'):GetAddon('SpartanUI')

--------------   oUF Functions   ------------------------------------
function addon:HotsListing()
	local _, classFileName = UnitClass('player')
	local LifebloomSpellId = select(7, GetSpellInfo('Lifebloom'))
	if classFileName == 'DRUID' then
		return {
			774, -- Rejuvenation
			LifebloomSpellId, -- Lifebloom
			8936, -- Regrowth
			48438, -- Wild Growth
			155777, -- Germination
			102351, -- Cenarion Ward
			102342 -- Ironbark
		}
	elseif classFileName == 'PRIEST' then
		return {
			139, -- Renew
			17, -- sheild
			33076 -- Prayer of Mending
		}
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
		local size = SUI.DBMod.PartyFrames.Auras.size + SizeModifier
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
	local factionGroup = UnitFactionGroup(unit)
	if (UnitIsPVPFreeForAll(unit)) then
		-- XXX - WoW5: UnitFactionGroup() can return Neutral as well.
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

--[[
	Creates all the Player Power Icons
	Converted to Lib item to provide a consistant experiance on SUI styles
]]
function addon:PlayerPowerIcons(frame, attachPoint)
	--Runes
	if select(2, UnitClass('player')) == 'DEATHKNIGHT' then
		frame.Runes = CreateFrame('Frame', nil, frame)
		frame.Runes.colorSpec = true

		for i = 1, 6 do
			frame.Runes[i] = CreateFrame('StatusBar', frame:GetName() .. '_Runes' .. i, frame)
			frame.Runes[i]:SetHeight(6)
			frame.Runes[i]:SetWidth((frame.Health:GetWidth() - 10) / 6)
			if (i == 1) then
				frame.Runes[i]:SetPoint('TOPLEFT', frame[attachPoint], 'BOTTOMLEFT', 0, -2)
			else
				frame.Runes[i]:SetPoint('TOPLEFT', frame.Runes[i - 1], 'TOPRIGHT', 2, 0)
			end
			frame.Runes[i]:SetStatusBarTexture(SUI.BarTextures.smooth)
			frame.Runes[i]:SetStatusBarColor(0, .39, .63, 1)

			frame.Runes[i].bg = frame.Runes[i]:CreateTexture(nil, 'BORDER')
			frame.Runes[i].bg:SetPoint('TOPLEFT', frame.Runes[i], 'TOPLEFT', -0, 0)
			frame.Runes[i].bg:SetPoint('BOTTOMRIGHT', frame.Runes[i], 'BOTTOMRIGHT', 0, -0)
			frame.Runes[i].bg:SetTexture(SUI.BarTextures.smooth)
			frame.Runes[i].bg:SetVertexColor(0, 0, 0, 1)
			frame.Runes[i].bg.multiplier = 0.64
			-- frame.Runes[i]:Hide()
		end
	else
		frame.ComboPoints = frame:CreateFontString(nil, 'BORDER', 'SUI_FontOutline13')
		frame.ComboPoints:SetPoint('TOPLEFT', frame[attachPoint], 'BOTTOMLEFT', 0, -2)
		local MaxPower, ClassPower = 5, {}

		if(select(2, UnitClass('player')) == 'MONK') then
			MaxPower = 6
		end

		for index = 1, MaxPower do
			local Bar = CreateFrame('StatusBar', nil, frame)
			Bar:SetStatusBarTexture(SUI.BarTextures.smooth)

			-- Position and size.
			Bar:SetSize(((frame.Health:GetWidth() - 10) / MaxPower), 6)
			if (index == 1) then
				Bar:SetPoint('TOPLEFT', frame.ComboPoints, 'TOPLEFT')
			else
				Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 2, 0)
			end
			Bar:Hide()
			
			ClassPower[index] = Bar
		end

		-- Register with oUF
		frame.ClassPower = ClassPower
	end
end
