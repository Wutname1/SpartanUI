local SUI = SUI
local module = SUI:GetModule('Style_Minimal')
local PlayerFrames, PartyFrames = nil
----------------------------------------------------------------------------------------------------

local FramesList = {
	[1] = 'pet',
	[2] = 'target',
	[3] = 'targettarget',
	[4] = 'focus',
	[5] = 'focustarget',
	[6] = 'player'
}
local Smoothv2 = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\Smoothv2.tga'

--Interface/WorldStateFrame/ICONS-CLASSES
local lfdrole = 'Interface\\AddOns\\SpartanUI\\media\\icon_role.tga'

local classFileName = select(2, UnitClass('player'))
local colors = setmetatable({}, {__index = SpartanoUF.colors})
for k, v in pairs(SpartanoUF.colors) do
	if not colors[k] then
		colors[k] = v
	end
end
do -- setup custom colors that we want to use
	colors.health = {0, 1, 50 / 255} -- the color of health bars
	colors.reaction[1] = {1, 50 / 255, 0} -- Hated
	colors.reaction[2] = colors.reaction[1] -- Hostile
	colors.reaction[3] = {1, 150 / 255, 0} -- Unfriendly
	colors.reaction[4] = {1, 220 / 255, 0} -- Neutral
	colors.reaction[5] = colors.health -- Friendly
	colors.reaction[6] = colors.health -- Honored
	colors.reaction[7] = colors.health -- Revered
	colors.reaction[8] = colors.health -- Exalted
end

local threat = function(self, event, unit)
	if (not self.Portrait) then -- no Portrait color artwork if possible
		-- if (not self.artwork.bg:IsObjectType("Texture")) then return; end
		-- unit = string.gsub(self.unit,"(.)",string.upper,1) or string.gsub(unit,"(.)",string.upper,1)
		-- local status
		-- if UnitExists(unit) then status = UnitThreatSituation(unit) else status = 0; end
		-- if (status and status > 0) then
		-- local r,g,b = GetThreatStatusColor(status);
		-- self.artwork.bg:SetVertexColor(r,g,b);
		-- else
		-- self.artwork.bg:SetVertexColor(1,1,1);
		-- end
		if (not self.artwork) then
			return
		end
	else -- Portrait exsits color picture for threat
		if (not self.Portrait:IsObjectType('Texture')) then
			return
		end
		unit = string.gsub(self.unit, '(.)', string.upper, 1) or string.gsub(unit, '(.)', string.upper, 1)
		local status
		if UnitExists(unit) then
			status = UnitThreatSituation(unit)
		else
			status = 0
		end
		if (status and status > 0) then
			local r, g, b = GetThreatStatusColor(status)
			self.Portrait:SetVertexColor(r, g, b)
		else
			self.Portrait:SetVertexColor(1, 1, 1)
		end
	end
end

local pvpIcon = function(self, event, unit)
	if (unit ~= self.unit) then
		return
	end

	local pvp = self.PvPIndicator
	if (pvp.PreUpdate) then
		pvp:PreUpdate()
	end

	if pvp.shadow == nil then
		pvp.shadow = self:CreateTexture(nil, 'BACKGROUND')
		pvp.shadow:SetSize(25, 25)
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
		pvp:Show()
		pvp.shadow:Show()
	else
		pvp:Hide()
		pvp.shadow:Hide()
	end

	if (pvp.PostUpdate) then
		return pvp:PostUpdate(status)
	end
end

function CreatePortrait(self)
	if SUI.DBMod.PlayerFrames.Portrait3D then
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript(
			'OnShow',
			function(self)
				self:SetCamera(0)
			end
		)
		Portrait.type = '3D'
		return Portrait
	else
		local tmp = self:CreateTexture(nil, 'BORDER')
		tmp:SetTexCoord(0.15, 0.86, 0.15, 0.86)
		return tmp
	end
end

--	Updating functions
local PostUpdateText = function(self, unit)
	self:Untag(self.Health.value)
	if self.Power then
		self:Untag(self.Power.value)
	end
	self:Tag(self.Health.value, PlayerFrames:TextFormat('health'))
	if self.Power then
		self:Tag(self.Power.value, PlayerFrames:TextFormat('mana'))
	end
end

local PostUpdateColor = function(self, unit)
	self.Health.frequentUpdates = true
	self.Health.colorDisconnected = true
	if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
		self.Health.colorReaction = true
		self.Health.colorClass = false
	elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
		self.Health.colorHappiness = true
		self.Health.colorReaction = false
		self.Health.colorClass = false
	elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
		self.Health.colorClass = true
		self.Health.colorReaction = false
	else
		self.Health.colorClass = false
		self.Health.colorReaction = false
		self.Health.colorSmooth = true
	end
	self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
	self.Health.colorHealth = true
end

local PostCastStop = function(self)
	if self.Time then
		self.Time:SetTextColor(1, 1, 1)
	end
end

local PostCastStart = function(self, unit, name, rank, text, castid)
	self:SetStatusBarColor(1, 0.7, 0)
end

local PostChannelStart = function(self, unit, name, rank, text, castid)
	self:SetStatusBarColor(1, 0.2, 0.7)
end

local OnCastbarUpdate = function(self, elapsed)
	if self.casting then
		self.duration = self.duration + elapsed
		if (self.duration >= self.max) then
			self.casting = nil
			self:Hide()
			if PostCastStop then
				PostCastStop(self:GetParent())
			end
			if PostCastStop then
				PostCastStop(self)
			end
			return
		end
		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetTextColor(1, 0, 0)
			else
				self.Time:SetTextColor(1, 1, 1)
			end
			if SUI.DBMod.PlayerFrames.Castbar.text[self:GetParent().unit] == 1 then
				self.Time:SetFormattedText('%.1f', self.max - self.duration)
			else
				self.Time:SetFormattedText('%.1f', self.duration)
			end
		end
		if SUI.DBMod.PlayerFrames.Castbar[self:GetParent().unit] == 1 then
			self:SetValue(self.max - self.duration)
		else
			self:SetValue(self.duration)
		end
	elseif self.channeling then
		self.duration = self.duration - elapsed
		if (self.duration <= 0) then
			self.channeling = nil
			self:Hide()
			if PostChannelStop then
				PostChannelStop(self:GetParent())
			end
			return
		end
		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetTextColor(1, 0, 0)
			else
				self.Time:SetTextColor(1, 1, 1)
			end
			self.Time:SetFormattedText('%.1f', self.max - self.duration)
		end
		if SUI.DBMod.PlayerFrames.Castbar[self:GetParent().unit] == 1 then
			self:SetValue(self.duration)
		else
			self:SetValue(self.max - self.duration)
		end
	else
		self.unitName = nil
		self.channeling = nil
		self:SetValue(1)
		self:Hide()
	end
end

local MakeSmallFrame = function(self, unit)
	self:SetSize(100, 40)
	do --setup base artwork
		self.artwork = CreateFrame('Frame', nil, self)
		self.artwork:SetFrameStrata('BACKGROUND')
		self.artwork:SetFrameLevel(2)
		self.artwork:SetAllPoints(self)

		-- if SUI.DBMod.PartyFrames.Portrait then
		-- self.Portrait = CreatePortrait(self);
		-- self.Portrait:SetSize(60, 60);
		-- self.Portrait:SetPoint("TOPLEFT",self,"TOPLEFT",35,-15);
		-- end

		self.ThreatIndicator = CreateFrame('Frame', nil, self)
		self.ThreatIndicator.Override = threat
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(3)
			health:SetSize(self:GetWidth(), 30)
			health:SetPoint('TOP', self, 'TOP', 0, 0)
			health:SetStatusBarTexture(Smoothv2)

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			-- health.value:SetAllPoints(health);
			health.value:SetPoint('TOPLEFT', health, 'TOPLEFT', 0, -5)
			health.value:SetPoint('TOPRIGHT', health, 'TOPRIGHT', 0, -5)
			health.value:SetPoint('BOTTOMLEFT', health, 'BOTTOMLEFT', 0, 0)
			health.value:SetPoint('BOTTOMRIGHT', health, 'BOTTOMRIGHT', 0, 0)

			health.value:SetJustifyH('CENTER')
			health.value:SetJustifyV('MIDDLE')
			self:Tag(health.value, PlayerFrames:TextFormat('health'))

			-- self:Tag(health.value, RaidFrames:TextFormat("health"))
			-- self:Tag(health.value, "[perhp]% ([missinghpdynamic])")

			local Background = health:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(health)
			Background:SetTexture(Smoothv2)
			Background:SetVertexColor(1, 1, 1, .2)

			self.Health = health
			self.Health.bg = Background
			self.Health.colorTapping = true
			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			if SUI.DBMod.PlayerFrames.bars[unit] then
				if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
					self.Health.colorReaction = true
				elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
					self.Health.colorHappiness = true
				elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
					self.Health.colorClass = true
				end
			else
				self.Health.colorSmooth = true
			end

			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(200, 16)
			otherBars:SetSize(150, 16)

			self.HealthPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4
			}
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(3)
			power:SetSize(self:GetWidth(), 4)
			power:SetPoint('TOP', self.Health, 'BOTTOM', 0, 0)
			power:SetStatusBarTexture(Smoothv2)

			local Background = power:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(power)
			Background:SetTexture(Smoothv2)
			Background:SetVertexColor(0, 0, 0, .2)

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
	end
	do -- setup items, icons, and text
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1 / 2
		}

		local items = CreateFrame('Frame', nil, self)
		items:SetFrameStrata('BACKGROUND')
		items:SetAllPoints(self)
		items:SetFrameLevel(4)
		items.low = CreateFrame('Frame', nil, self)
		items.low:SetFrameStrata('BACKGROUND')
		items.low:SetAllPoints(self)
		items.low:SetFrameLevel(1)

		self.Name = items:CreateFontString()
		SUI:FormatFont(self.Name, 10, 'Player')
		self.Name:SetHeight(10)
		self.Name:SetJustifyH('CENTER')
		self.Name:SetJustifyV('BOTTOM')
		self.Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 0)
		self.Name:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
		self:Tag(self.Name, '[SUI_ColorClass][name]')

		self.GroupRoleIndicator = items:CreateTexture(nil, 'BORDER')
		self.GroupRoleIndicator:SetSize(15, 15)
		self.GroupRoleIndicator:SetPoint('CENTER', items, 'TOPLEFT', 0, 0)
		self.GroupRoleIndicator:SetTexture(lfdrole)
		self.GroupRoleIndicator:SetAlpha(.75)

		self.PvPIndicator = items:CreateTexture(nil, 'BORDER')
		self.PvPIndicator:SetSize(25, 25)
		self.PvPIndicator:SetPoint('CENTER', self.Portrait, 'BOTTOMLEFT', 0, 0)
		self.PvPIndicator.Override = pvpIcon

		self.LevelSkull = items:CreateTexture(nil, 'ARTWORK')
		self.LevelSkull:SetSize(16, 16)
		self.LevelSkull:SetPoint('LEFT', self.Name, 'LEFT')

		self.RaidTargetIndicator = items:CreateTexture(nil, 'ARTWORK')
		self.RaidTargetIndicator:SetSize(20, 20)
		self.RaidTargetIndicator:SetPoint('CENTER', self, 'RIGHT', 2, -2)

		self.ResurrectIndicator = items:CreateTexture(nil, 'OVERLAY')
		self.ResurrectIndicator:SetSize(30, 30)
		self.ResurrectIndicator:SetPoint('CENTER', self, 'CENTER', 0, 0)

		self.ReadyCheckIndicator = items:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheckIndicator:SetSize(30, 30)
		self.ReadyCheckIndicator:SetPoint('CENTER', self, 'CENTER', 0, 0)

		self.StatusText = items:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline12')
		self.StatusText:SetPoint('TOP', self.Name, 'BOTTOM')
		self.StatusText:SetJustifyH('CENTER')
		self:Tag(self.StatusText, '[afkdnd]')
	end
	-- self.AuraWatch = SUI:oUF_Buffs(self)

	if unit == 'party' then
		self.TextUpdate = PartyFrames.PostUpdateText
	else
		self.TextUpdate = PostUpdateText
	end
	self.ColorUpdate = PostUpdateColor
	return self
end

local MakeLargeFrame = function(self, unit, width)
	if width then
		self:SetSize(width, 40)
	else
		self:SetSize(200, 40)
	end

	do --setup base artwork
		self.artwork = CreateFrame('Frame', nil, self)
		self.artwork:SetFrameStrata('BACKGROUND')
		self.artwork:SetFrameLevel(2)
		self.artwork:SetAllPoints(self)

		self.ThreatIndicator = CreateFrame('Frame', nil, self)
		self.ThreatIndicator.Override = threat
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(3)
			cast:SetSize(self:GetWidth(), 5)
			cast:SetPoint('TOP', self, 'TOP', 0, -1)
			cast:SetStatusBarTexture(Smoothv2)

			cast.Time = cast:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			cast.Time:SetSize(20, 8)
			cast.Time:SetJustifyH('LEFT')
			cast.Time:SetJustifyV('MIDDLE')
			cast.Time:SetPoint('LEFT', cast, 'RIGHT', 2, 0)

			local Background = cast:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(cast)
			Background:SetTexture(Smoothv2)
			Background:SetVertexColor(0, 0, 0, .2)

			self.Castbar = cast
			self.Castbar.OnUpdate = OnCastbarUpdate
			self.Castbar.PostCastStart = PostCastStart
			self.Castbar.PostChannelStart = PostChannelStart
			self.Castbar.PostCastStop = PostCastStop
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(3)
			health:SetSize(self:GetWidth(), 30)
			health:SetPoint('TOP', self.Castbar, 'BOTTOM', 0, 0)
			health:SetStatusBarTexture(Smoothv2)

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetAllPoints(health)
			health.value:SetJustifyH('CENTER')
			health.value:SetJustifyV('MIDDLE')
			self:Tag(health.value, PlayerFrames:TextFormat('health'))
			-- self:Tag(health.value, "[perhp]% ([missinghpdynamic])")

			local Background = health:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(health)
			Background:SetTexture(Smoothv2)
			Background:SetVertexColor(1, 1, 1, .2)

			self.Health = health
			self.Health.bg = Background
			self.Health.colorTapping = true
			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			if SUI.DBMod.PlayerFrames.bars[unit] then
				if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
					self.Health.colorReaction = true
				elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
					self.Health.colorHappiness = true
				elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
					self.Health.colorClass = true
				end
			else
				self.Health.colorSmooth = true
			end

			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(200, 16)
			otherBars:SetSize(150, 16)

			self.HealthPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4
			}
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(3)
			power:SetSize(self:GetWidth(), 8)
			power:SetPoint('TOP', self.Health, 'BOTTOM', 0, 0)
			power:SetStatusBarTexture(Smoothv2)

			power.value = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.value:SetAllPoints(power)
			power.value:SetJustifyH('CENTER')
			power.value:SetJustifyV('MIDDLE')
			self:Tag(power.value, '[perpp]%')

			local Background = power:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(power)
			Background:SetTexture(Smoothv2)
			Background:SetVertexColor(0, 0, 0, .2)

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
		do -- HoTs Display
			local spellIDs = {}
			if classFileName == 'DRUID' then
				spellIDs = {
					774, -- Rejuvenation
					33763, -- Lifebloom
					8936, -- Regrowth
					102351, -- Cenarion Ward
					48438, -- Wild Growth
					155777, -- Germination
					102342 -- Ironbark
				}
			elseif classFileName == 'PRIEST' then
				spellIDs = {
					139, -- Renew
					17, -- sheild
					33076 -- Prayer of Mending
				}
			end
			self.Buffs = CreateFrame('Frame', nil, self)
			self.Buffs:SetSize(self:GetWidth(), SUI.DBMod.PartyFrames.Auras.size + 2)
			if unit == 'player' or unit == 'target' then
				self.Buffs:SetPoint('BOTTOM', self, 'TOP', 0, 14)
			else
				self.Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 2, 0)
			end
			self.Buffs.onlyShowPlayer = true
			self.Buffs.filter = spellIDs
			self.Buffs.size = SUI.DBMod.PartyFrames.Auras.size
			self.Buffs.spacing = SUI.DBMod.PartyFrames.Auras.spacing
			self.Buffs.showType = SUI.DBMod.PartyFrames.Auras.showType
			self.Buffs.size = SUI.DBMod.PartyFrames.Auras.size
			local FilterType = function(
				icons,
				unit,
				icon,
				name,
				rank,
				texture,
				count,
				dtype,
				duration,
				timeLeft,
				caster,
				isStealable,
				shouldConsolidate,
				spellID,
				canApplyAura,
				isBossDebuff)
				for _, sid in pairs(spellIDs) do
					if sid == spellID then
						return true
					end
				end
				return false
			end
			self.Buffs.CustomFilter = FilterType
		end
		do -- setup buffs and debuffs
			if SUI.DB.Styles.Minimal.Frames[unit] and PlayerFrames then
				self.BuffAnchor = CreateFrame('Frame', nil, self)
				self.BuffAnchor:SetSize(self:GetWidth(), 1)
				self.BuffAnchor:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 12)
				self.BuffAnchor:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 12)

				self = PlayerFrames:Buffs(self, unit)
			end
		end
		do --Special Icons/Bars
			if unit == 'player' then
				local DruidMana = CreateFrame('StatusBar', nil, self)
				DruidMana:SetSize(self:GetWidth(), 4)
				DruidMana:SetPoint('TOP', self.Power, 'BOTTOM', 0, -1.2)
				DruidMana.colorPower = true
				DruidMana:SetStatusBarTexture(Smoothv2)

				-- Add a background
				local Background = DruidMana:CreateTexture(nil, 'BACKGROUND')
				Background:SetAllPoints(DruidMana)
				Background:SetTexture(Smoothv2)
				Background:SetVertexColor(1, 1, 1, .2)

				-- Register it with oUF
				self.AdditionalPower = DruidMana
				self.AdditionalPower.bg = Background

				self.Runes = CreateFrame('Frame', nil, self)
				self.Runes.colorSpec = true
				for i = 1, 6 do
					self.Runes[i] = CreateFrame('StatusBar', self:GetName() .. '_Runes' .. i, self)
					self.Runes[i]:SetHeight(6)
					self.Runes[i]:SetWidth((self:GetWidth() - 7) / 6)
					if (i == 1) then
						self.Runes[i]:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', 0, -1.5)
					else
						self.Runes[i]:SetPoint('TOPLEFT', self.Runes[i - 1], 'TOPRIGHT', 1.5, 0)
					end
					self.Runes[i]:SetStatusBarTexture(Smoothv2)
					self.Runes[i]:SetStatusBarColor(0, .39, .63, 1)

					self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, 'BORDER')
					self.Runes[i].bg:SetPoint('TOPLEFT', self.Runes[i], 'TOPLEFT', -0, 0)
					self.Runes[i].bg:SetPoint('BOTTOMRIGHT', self.Runes[i], 'BOTTOMRIGHT', 0, -0)
					self.Runes[i].bg:SetTexture(Smoothv2)
					self.Runes[i].bg:SetVertexColor(0, 0, 0, 1)
					self.Runes[i].bg.multiplier = 0.64
					self.Runes[i]:Hide()
				end
			end
		end
	end
	do -- setup items, icons, and text
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1 / 2
		}

		local items = CreateFrame('Frame', nil, self)
		items:SetFrameStrata('BACKGROUND')
		items:SetAllPoints(self)
		items:SetFrameLevel(4)
		items.low = CreateFrame('Frame', nil, self)
		items.low:SetFrameStrata('BACKGROUND')
		items.low:SetAllPoints(self.Portrait)
		items.low:SetFrameLevel(1)

		self.Name = items:CreateFontString()
		SUI:FormatFont(self.Name, 12, 'Player')
		self.Name:SetSize(self:GetWidth(), 12)
		self.Name:SetJustifyH('CENTER')
		self.Name:SetJustifyV('BOTTOM')
		self.Name:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 0)
		self.Name:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 0)
		self:Tag(self.Name, '[difficulty][level] [SUI_ColorClass][name]')

		self.RareElite = items.low:CreateTexture(nil, 'ARTWORK', nil, -5)
		self.RareElite:SetSize(150, 70)
		self.RareElite:SetPoint('BOTTOM', self.Health, 'TOP', 0, 0)
		self.RareElite.small = true

		self.GroupRoleIndicator = items:CreateTexture(nil, 'BORDER')
		self.GroupRoleIndicator:SetSize(18, 18)
		self.GroupRoleIndicator:SetPoint('CENTER', items, 'TOPLEFT', 0, 0)
		self.GroupRoleIndicator:SetTexture(lfdrole)
		self.GroupRoleIndicator:SetAlpha(.75)

		self.PvPIndicator = items:CreateTexture(nil, 'BORDER')
		self.PvPIndicator:SetSize(25, 25)
		self.PvPIndicator:SetPoint('CENTER', self.Portrait, 'BOTTOMLEFT', 0, 0)
		self.PvPIndicator.Override = pvpIcon

		self.LevelSkull = items:CreateTexture(nil, 'ARTWORK')
		self.LevelSkull:SetSize(16, 16)
		self.LevelSkull:SetPoint('LEFT', self.Name, 'LEFT')

		self.RaidTargetIndicator = items:CreateTexture(nil, 'ARTWORK')
		self.RaidTargetIndicator:SetSize(24, 24)
		self.RaidTargetIndicator:SetPoint('CENTER', items, 'RIGHT', 2, -4)

		self.StatusText = items:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline22')
		self.StatusText:SetPoint('CENTER', items, 'CENTER')
		self.StatusText:SetJustifyH('CENTER')
		self:Tag(self.StatusText, '[afkdnd]')

		if unit == 'player' then
			self.ComboPoints = items:CreateFontString(nil, 'BORDER', 'SUI_FontOutline13')
			self.ComboPoints:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', 50, -2)

			local ClassIcons = {}
			for i = 1, 6 do
				local Icon = self:CreateTexture(nil, 'OVERLAY')
				Icon:SetTexture('Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\icon_combo')

				if (i == 1) then
					Icon:SetPoint('LEFT', self.ComboPoints, 'RIGHT', 1, -1)
				else
					Icon:SetPoint('LEFT', ClassIcons[i - 1], 'RIGHT', -2, 0)
				end
				Icon:Hide()

				ClassIcons[i] = Icon
			end
			self.ClassIcons = ClassIcons

			local ClassPowerID = nil
			items:SetScript(
				'OnEvent',
				function(a, b)
					if b == 'PLAYER_SPECIALIZATION_CHANGED' then
						return
					end
					local cur
					cur = UnitPower('player', ClassPowerID)

					self.ComboPoints:SetText((cur > 0 and cur) or '')
				end
			)

			items:RegisterEvent(
				'PLAYER_SPECIALIZATION_CHANGED',
				function()
					ClassPowerID = nil
					if (classFileName == 'MONK') then
						ClassPowerID = SPELL_POWER_CHI
					elseif (classFileName == 'PALADIN') then
						ClassPowerID = SPELL_POWER_HOLY_POWER
					elseif (classFileName == 'WARLOCK') then
						ClassPowerID = SPELL_POWER_SOUL_SHARDS
					elseif (classFileName == 'ROGUE' or classFileName == 'DRUID') then
						ClassPowerID = SPELL_POWER_COMBO_POINTS
					elseif (classFileName == 'MAGE') then
						ClassPowerID = SPELL_POWER_ARCANE_CHARGES
					end
					if ClassPowerID ~= nil then
						items:RegisterEvent('UNIT_DISPLAYPOWER')
						items:RegisterEvent('PLAYER_ENTERING_WORLD')
						items:RegisterEvent('UNIT_POWER_FREQUENT')
						items:RegisterEvent('UNIT_MAXPOWER')
					end
				end
			)

			if (classFileName == 'MONK') then
				ClassPowerID = SPELL_POWER_CHI
			elseif (classFileName == 'PALADIN') then
				ClassPowerID = SPELL_POWER_HOLY_POWER
			elseif (classFileName == 'WARLOCK') then
				ClassPowerID = SPELL_POWER_SOUL_SHARDS
			elseif (classFileName == 'ROGUE' or classFileName == 'DRUID') then
				ClassPowerID = SPELL_POWER_COMBO_POINTS
			elseif (classFileName == 'MAGE') then
				ClassPowerID = SPELL_POWER_ARCANE_CHARGES
			end
			if ClassPowerID ~= nil then
				items:RegisterEvent('UNIT_DISPLAYPOWER')
				items:RegisterEvent('PLAYER_ENTERING_WORLD')
				items:RegisterEvent('UNIT_POWER_FREQUENT')
				items:RegisterEvent('UNIT_MAXPOWER')
			end
		end
	end

	if unit == 'party' then
		self.TextUpdate = PartyFrames.PostUpdateText
	else
		self.TextUpdate = PostUpdateText
	end
	self.ColorUpdate = PostUpdateColor
	return self
end

local CreateUnitFrame = function(self, unit)
	self =
		((unit == 'player' and MakeLargeFrame(self, unit)) or (unit == 'target' and MakeLargeFrame(self, unit)) or
		MakeSmallFrame(self, unit))
	self = PlayerFrames:MakeMovable(self, unit)
	return self
end

local CreateUnitFrameParty = function(self, unit)
	if SUI.DB.Styles.Minimal.PartyFramesSize ~= nil and SUI.DB.Styles.Minimal.PartyFramesSize == 'small' then
		self = MakeSmallFrame(self, unit)
	else
		self = MakeLargeFrame(self, unit, 150)
	end
	self = PartyFrames:MakeMovable(self)
	return self
end

local CreateUnitFrameRaid = function(self, unit)
	self = MakeSmallFrame(self, unit)
	self = SUI:GetModule('RaidFrames'):MakeMovable(self)
	return self
end

SpartanoUF:RegisterStyle('Spartan_MinimalFrames', CreateUnitFrame)
SpartanoUF:RegisterStyle('Spartan_MinimalFrames_Party', CreateUnitFrameParty)
SpartanoUF:RegisterStyle('Spartan_MinimalFrames_Raid', CreateUnitFrameRaid)

function module:UpdateAltBarPositions()
	if RuneFrame then
		RuneFrame:Hide()
		RuneFrame.Rune1:Hide()
		RuneFrame.Rune2:Hide()
		RuneFrame.Rune3:Hide()
		RuneFrame.Rune4:Hide()
		RuneFrame.Rune5:Hide()
		RuneFrame.Rune6:Hide()
	end

	-- Hide the AlternatePowerBar
	if PlayerFrameAlternateManaBar then
		PlayerFrameAlternateManaBar:Hide()
		PlayerFrameAlternateManaBar.Show = PlayerFrameAlternateManaBar.Hide
	end
end

function module:PlayerFrames()
	PlayerFrames = SUI:GetModule('PlayerFrames')
	SpartanoUF:SetActiveStyle('Spartan_MinimalFrames')
	PlayerFrames:BuffOptions()

	for _, b in pairs(FramesList) do
		PlayerFrames[b] = SpartanoUF:Spawn(b, 'SUI_' .. b .. 'Frame')
		if b == 'player' then
			PlayerFrames:SetupExtras()
		end
	end

	module:PositionFrame()

	module:UpdateAltBarPositions()

	if SUI.DBMod.PlayerFrames.BossFrame.display == true then
		for i = 1, MAX_BOSS_FRAMES do
			PlayerFrames.boss[i] = SpartanoUF:Spawn('boss' .. i, 'SUI_Boss' .. i)
			if i == 1 then
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			else
				PlayerFrames.boss[i]:SetPoint('TOP', PlayerFrames.boss[i - 1], 'BOTTOM', 0, -10)
			end
		end
	end

	local arena = {}
	for i = 1, 3 do
		arena[i] = SpartanoUF:Spawn('arena' .. i, 'SUI_Arena' .. i)
		if i == 1 then
			arena[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			arena[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
		else
			arena[i]:SetPoint('TOP', arena[i - 1], 'BOTTOM', 0, -10)
		end
	end
	arena.mover = CreateFrame('Frame')
	arena.mover:SetSize(5, 5)
	arena.mover:SetPoint('TOPLEFT', SUI_Arena1, 'TOPLEFT')
	arena.mover:SetPoint('TOPRIGHT', SUI_Arena1, 'TOPRIGHT')
	arena.mover:SetPoint('BOTTOMLEFT', 'SUI_Arena3', 'BOTTOMLEFT')
	arena.mover:SetPoint('BOTTOMRIGHT', 'SUI_Arena3', 'BOTTOMRIGHT')
	arena.mover:EnableMouse(true)

	arena.bg = arena.mover:CreateTexture(nil, 'BACKGROUND')
	arena.bg:SetAllPoints(arena.mover)
	arena.bg:SetTexture(1, 1, 1, 0.5)

	arena.mover:Hide()
	arena.mover:RegisterEvent('VARIABLES_LOADED')
	arena.mover:RegisterEvent('PLAYER_REGEN_DISABLED')

	function PlayerFrames:UpdatearenaFramePosition()
		if (InCombatLockdown()) then
			return
		end
		if DBMod.PlayerFrames.ArenaFrame.movement.moved then
			SUI_arena1:SetPoint(
				DBMod.PlayerFrames.ArenaFrame.movement.point,
				DBMod.PlayerFrames.ArenaFrame.movement.relativeTo,
				DBMod.PlayerFrames.ArenaFrame.movement.relativePoint,
				DBMod.PlayerFrames.ArenaFrame.movement.xOffset,
				DBMod.PlayerFrames.ArenaFrame.movement.yOffset
			)
		else
			SUI_arena1:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', -50, -490)
		end
	end

	PlayerFrames.arena = arena
end

function module:PositionFrame(b)
	if b == 'player' or b == nil then
		PlayerFrames.player:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOM', -60, 170)
	end
	if b == 'pet' or b == nil then
		PlayerFrames.pet:SetPoint('RIGHT', PlayerFrames.player, 'BOTTOMLEFT', -4, 0)
	end

	if b == 'target' or b == nil then
		PlayerFrames.target:SetPoint('LEFT', PlayerFrames.player, 'RIGHT', 120, 0)
	end
	if b == 'targettarget' or b == nil then
		PlayerFrames.targettarget:SetPoint('LEFT', PlayerFrames.target, 'BOTTOMRIGHT', 4, 0)
	end

	if b == 'focus' or b == nil then
		PlayerFrames.focus:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'TOP', 0, 30)
	end
	if b == 'focustarget' or b == nil then
		PlayerFrames.focustarget:SetPoint('BOTTOMLEFT', PlayerFrames.focus, 'BOTTOMRIGHT', 5, 0)
	end

	-- PlayerFrames.player:SetScale(SUI.DB.scale);
	for _, c in pairs(FramesList) do
		PlayerFrames[c]:SetScale(SUI.DB.scale)
		-- _G["SUI_"..c.."Frame"]:SetScale(SUI.DB.scale);
	end
end

function module:RaidFrames()
	SpartanoUF:SetActiveStyle('Spartan_MinimalFrames_Raid')

	local xoffset = 3
	local yOffset = -5
	local point = 'TOP'
	local columnAnchorPoint = 'LEFT'
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'

	if SUI.DBMod.RaidFrames.mode == 'GROUP' then
		groupingOrder = '1,2,3,4,5,6,7,8'
	end
	-- print(SUI.DBMod.RaidFrames.mode)
	-- print(groupingOrder)
	local raid =
		SpartanoUF:SpawnHeader(
		nil,
		nil,
		'raid',
		'showRaid',
		SUI.DBMod.RaidFrames.showRaid,
		'showParty',
		SUI.DBMod.RaidFrames.showParty,
		'showPlayer',
		SUI.DBMod.RaidFrames.showPlayer,
		'showSolo',
		SUI.DBMod.RaidFrames.showSolo,
		'xoffset',
		xoffset,
		'yOffset',
		yOffset,
		'point',
		point,
		'groupBy',
		SUI.DBMod.RaidFrames.mode,
		'groupingOrder',
		groupingOrder,
		'sortMethod',
		'index',
		'maxColumns',
		SUI.DBMod.RaidFrames.maxColumns,
		'unitsPerColumn',
		SUI.DBMod.RaidFrames.unitsPerColumn,
		'columnSpacing',
		SUI.DBMod.RaidFrames.columnSpacing,
		'columnAnchorPoint',
		columnAnchorPoint
	)

	return (raid)
end

function module:PartyFrames()
	PartyFrames = SUI:GetModule('PartyFrames')
	module:Options_PartyFrames()
	SpartanoUF:SetActiveStyle('Spartan_MinimalFrames_Party')
	local party =
		SpartanoUF:SpawnHeader(
		'SUI_PartyFrameHeader',
		nil,
		nil,
		'showRaid',
		SUI.DBMod.PartyFrames.showRaid,
		'showParty',
		SUI.DBMod.PartyFrames.showParty,
		'showPlayer',
		SUI.DBMod.PartyFrames.showPlayer,
		'showSolo',
		SUI.DBMod.PartyFrames.showSolo,
		'yOffset',
		-15,
		'xOffset',
		0,
		'columnAnchorPoint',
		'TOPLEFT',
		'initial-anchor',
		'TOPLEFT'
	)

	-- party:SetParent("SpartanUI");
	-- party:SetClampedToScreen(true);
	-- PartyMemberBackground.Show = function() return; end
	-- PartyMemberBackground:Hide();

	-- party:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -60)

	return (party)
end
