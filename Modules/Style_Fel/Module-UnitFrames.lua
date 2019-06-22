local _G, SUI = _G, _G['SUI']
local L = SUI.L
local module = SUI:GetModule('Style_Fel')
local PlayerFrames, PartyFrames = nil
----------------------------------------------------------------------------------------------------
local Smoothv2 = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\Smoothv2.tga'
local square = 'Interface\\AddOns\\SpartanUI_Style_Transparent\\Images\\square.tga'
local lfdrole = 'Interface\\AddOns\\SpartanUI\\media\\icon_role.tga'
local Images

function module:ImageSetup()
	if SUI.DB.Styles.Fel.SubTheme == 'Digital' then
		Images = {
			bg = {
				Texture = 'Interface\\addons\\SpartanUI_Style_Fel\\Digital\\Fel-Box',
				Coords = {0.0234375, 0.9765625, 0.265625, 0.7734375} --left, right, top, bottom
			},
			smallbg = {
				Texture = 'Interface\\Scenarios\\LegionInvasion',
				Coords = {0.017578125, 0.3203125, 0.4609375, 0.564453125} --left, right, top, bottom
			},
			flair = {
				Texture = 'Interface\\addons\\SpartanUI_Style_Fel\\Digital\\Fel-Box',
				Coords = {0, 0.1, 0, 0.2}
			},
			flair2 = {
				Texture = 'Interface\\addons\\SpartanUI_Style_Fel\\Digital\\Fel-Box',
				Coords = {0, 0.1, 0, 0.2}
			}
		}
	else
		Images = {
			bg = {
				Texture = 'Interface\\Scenarios\\LegionInvasion',
				Coords = {.02, .385, .45, .575} --left, right, top, bottom
			},
			smallbg = {
				Texture = 'Interface\\Scenarios\\LegionInvasion',
				Coords = {0.017578125, 0.3203125, 0.4609375, 0.564453125} --left, right, top, bottom
			},
			flair = {
				Texture = 'Interface\\Scenarios\\LegionInvasion',
				Coords = {0.140625, 0.615234375, 0, 0.265625}
			},
			flair2 = {
				Texture = 'Interface\\Addons\\SpartanUI_Style_Fel\\Images\\Party-Frame',
				Coords = {0.1953125, 0.8046875, 0.1328125, 0.859375}
			}
		}
	end
end

local function UpdatePowerPrep(self, event, specID)
	local element = self.Power
	element:SetMinMaxValues(0, 1)
	element:SetValue(0)
	element:SetShown(select(6, GetSpecializationInfoByID(specID)) == 'HEALER')
end

local function UpdateHealthPrep(self)
	local element = self.Health
	element:SetMinMaxValues(0, 1)
	element:SetValue(0)
end

--	Formatting functions
local TextFormat = function(text)
	local textstyle = SUI.DBMod.PlayerFrames.bars[text].textstyle
	local textmode = SUI.DBMod.PlayerFrames.bars[text].textmode
	local a, m, t, z
	if text == 'mana' then
		z = 'pp'
	else
		z = 'hp'
	end

	-- textstyle
	-- "Long: 			 Displays all numbers."
	-- "Long Formatted: Displays all numbers with commas."
	-- "Dynamic: 		 Abbriviates and formats as needed"
	if textstyle == 'long' then
		a = '[cur' .. z .. ']'
		m = '[missing' .. z .. ']'
		t = '[max' .. z .. ']'
	elseif textstyle == 'longfor' then
		a = '[cur' .. z .. 'formatted]'
		m = '[missing' .. z .. 'formatted]'
		t = '[max' .. z .. 'formatted]'
	elseif textstyle == 'dynamic' then
		a = '[cur' .. z .. 'dynamic]'
		m = '[missing' .. z .. 'dynamic]'
		t = '[max' .. z .. 'dynamic]'
	end
	-- textmode
	-- [1]="Avaliable / Total",
	-- [2]="(Missing) Avaliable / Total",
	-- [3]="(Missing) Avaliable"

	if textmode == 1 then
		return a .. ' / ' .. t
	elseif textmode == 2 then
		return '(' .. m .. ') ' .. a .. ' / ' .. t
	elseif textmode == 3 then
		return '(' .. m .. ') ' .. a
	elseif textmode == 4 then
		return a .. ' / ' .. t .. ' ([perhp]%)'
	end
end

local threat = function(self, event, unit)
	local status
	unit = string.gsub(self.unit, '(.)', string.upper, 1) or string.gsub(unit, '(.)', string.upper, 1)
	if UnitExists(unit) then
		status = UnitThreatSituation(unit)
	else
		status = 0
	end

	if self.ThreatIndicatorOverlay then
		if (status and status > 0) then
			self.ThreatIndicatorOverlay:SetVertexColor(GetThreatStatusColor(status))
			self.ThreatIndicatorOverlay:Show()
		else
			self.ThreatIndicatorOverlay:Hide()
		end
		if self.artwork.flair then
			self.artwork.flair.bg:SetVertexColor(GetThreatStatusColor(status))
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

	local status
	local factionGroup = UnitFactionGroup(unit)
	if (UnitIsPVPFreeForAll(unit)) then
		-- XXX - WoW5: UnitFactionGroup() can return Neutral as well.
		pvp:SetTexture('Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon')
		status = 'ffa'
	elseif (factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(unit)) then
		pvp:SetTexture('Interface\\FriendsFrame\\PlusManz-' .. factionGroup)
		-- pvp.shadow:SetTexture("Interface\\FriendsFrame\\PlusManz-"..factionGroup)
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

--	Updating functions
local PostUpdateText = function(self)
	self:Untag(self.Health.value)
	self:Tag(self.Health.value, TextFormat('health'))
	if self.Power then
		self:Untag(self.Power.value)
		self:Tag(self.Power.value, TextFormat('mana'))
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

local PostCastStart = function(self)
	self:SetStatusBarColor(1, 0.7, 0)
end

local PostChannelStart = function(self)
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
				PostCastStop(self)
			end
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

-- Create Frames
local CreateLargeFrame = function(self, unit)
	-- if self:GetWidth() ~= 180 then self:SetSize(180, 58); end
	self:SetSize(180, 58)
	do -- setup base artwork
		self.artwork = CreateFrame('Frame', nil, self)
		self.artwork:SetFrameStrata('BACKGROUND')
		self.artwork:SetFrameLevel(2)
		self.artwork:SetAllPoints(self)

		self.artwork.bg = self.artwork:CreateTexture(nil, 'BACKGROUND')
		self.artwork.bg:SetPoint('CENTER', self)
		self.artwork.bg:SetTexture(Images.bg.Texture)
		self.artwork.bg:SetTexCoord(unpack(Images.bg.Coords))
		self.artwork.bg:SetSize(self:GetSize())

		self.artwork.flair = self.artwork:CreateTexture(nil, 'BACKGROUND')
		self.artwork.flair:SetPoint('RIGHT', self, 'RIGHT', 0, 5)
		self.artwork.flair:SetTexture(Images.flair.Texture)
		self.artwork.flair:SetTexCoord(unpack(Images.flair.Coords))
		self.artwork.flair:SetSize(self:GetWidth() + 60, self:GetHeight() + 75)

		self.Portrait = PlayerFrames:CreatePortrait(self)
		if SUI.DBMod.PlayerFrames.Portrait3D then
			self.Portrait:SetFrameStrata('LOW')
			self.Portrait:SetFrameLevel(2)
		end
		self.Portrait:SetSize(58, 58)
		self.Portrait:SetPoint('RIGHT', self, 'LEFT', -1, 0)

		local Threat = self:CreateTexture(nil, 'OVERLAY')
		Threat:SetSize(25, 25)
		Threat:SetPoint('CENTER', self, 'RIGHT')
		self.ThreatIndicator = Threat
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(3)
			cast:SetSize(self:GetWidth(), 8)
			cast:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
			cast:SetStatusBarTexture(Smoothv2)

			cast.Text = cast:CreateFontString()
			SUI:FormatFont(cast.Text, 10, 'Player')
			cast.Text:SetJustifyH('CENTER')
			cast.Text:SetJustifyV('MIDDLE')
			cast.Text:SetAllPoints(cast)

			self.Castbar = cast
			self.Castbar.OnUpdate = OnCastbarUpdate
			self.Castbar.PostCastStart = PostCastStart
			self.Castbar.PostChannelStart = PostChannelStart
			self.Castbar.PostCastStop = PostCastStop
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(2)
			health:SetStatusBarTexture(Smoothv2)
			health:SetWidth(self:GetWidth())
			health:SetPoint('TOPLEFT', self.Castbar, 'BOTTOMLEFT', 0, -2)
			health:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, 13)

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetJustifyH('CENTER')
			health.value:SetJustifyV('MIDDLE')
			health.value:SetAllPoints(health)
			self:Tag(health.value, PlayerFrames:TextFormat('health'))

			self.Health = health

			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			if SUI.DBMod.PlayerFrames.bars[unit] and SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
				self.Health.colorReaction = true
			elseif SUI.DBMod.PlayerFrames.bars[unit] and SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
				self.Health.colorHappiness = true
			elseif SUI.DBMod.PlayerFrames.bars[unit] and SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
				self.Health.colorClass = true
			else
				self.Health.colorSmooth = true
			end
			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			SUI:SUF_HealPrediction(self)
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(2)
			power:SetSize(self:GetWidth(), 10)
			power:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 0, 2)
			power:SetStatusBarTexture(Smoothv2)

			power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline8')
			power.ratio:SetJustifyH('CENTER')
			power.ratio:SetJustifyV('MIDDLE')
			power.ratio:SetAllPoints(power)
			self:Tag(power.ratio, PlayerFrames:TextFormat('mana'))

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
	end
	do -- setup icons, and text
		local ring = CreateFrame('Frame', nil, self)
		ring:SetFrameStrata('MEDIUM')
		ring:SetAllPoints(self.Portrait)
		ring:SetFrameLevel(3)

		self.Name = self:CreateFontString()
		SUI:FormatFont(self.Name, 12, 'Player')
		self.Name:SetSize(self:GetWidth(), 12)
		self.Name:SetJustifyH('LEFT')
		self.Name:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -5)
		self:Tag(self.Name, '[difficulty][level] [SUI_ColorClass][name]')

		self.RareElite = self.artwork:CreateTexture(nil, 'BACKGROUND', nil, -5)
		self.RareElite:SetTexture('Interface\\Addons\\SpartanUI_Artwork\\Images\\status-glow')
		self.RareElite:SetAlpha(.6)
		self.RareElite:SetPoint('BOTTOMRIGHT', self.Name, 'BOTTOMRIGHT', 0, 0)
		self.RareElite:SetPoint('TOPLEFT', self.Portrait, 'TOPLEFT', 0, 0)

		self.LeaderIndicator = self:CreateTexture(nil, 'BORDER')
		self.LeaderIndicator:SetSize(12, 12)
		self.LeaderIndicator:SetPoint('RIGHT', self.Name, 'LEFT')

		self.SUI_RaidGroup = self:CreateTexture(nil, 'BORDER')
		self.SUI_RaidGroup:SetSize(12, 12)
		self.SUI_RaidGroup:SetPoint('TOPLEFT', self, 'TOPLEFT')
		self.SUI_RaidGroup:SetTexture(square)
		self.SUI_RaidGroup:SetVertexColor(0, .8, .9, .9)

		self.SUI_RaidGroup.Text = self:CreateFontString(nil, 'BORDER', 'SUI_Font10')
		self.SUI_RaidGroup.Text:SetSize(12, 12)
		self.SUI_RaidGroup.Text:SetJustifyH('CENTER')
		self.SUI_RaidGroup.Text:SetJustifyV('MIDDLE')
		self.SUI_RaidGroup.Text:SetPoint('CENTER', self.SUI_RaidGroup, 'CENTER', 0, 1)
		self:Tag(self.SUI_RaidGroup.Text, '[group]')

		self.PvPIndicator = self:CreateTexture(nil, 'BORDER')
		self.PvPIndicator:SetSize(25, 25)
		self.PvPIndicator:SetPoint('CENTER', self, 'BOTTOMRIGHT', 0, -3)
		self.PvPIndicator.Override = pvpIcon

		self.RestingIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.RestingIndicator:SetSize(20, 20)
		self.RestingIndicator:SetPoint('CENTER', self, 'TOPLEFT')
		self.RestingIndicator:SetTexCoord(0.15, 0.86, 0.15, 0.86)

		self.GroupRoleIndicator = self:CreateTexture(nil, 'BORDER')
		self.GroupRoleIndicator:SetSize(18, 18)
		self.GroupRoleIndicator:SetPoint('CENTER', self, 'LEFT', 0, 0)
		self.GroupRoleIndicator:SetTexture(lfdrole)
		self.GroupRoleIndicator:SetAlpha(.75)

		self.CombatIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.CombatIndicator:SetSize(20, 20)
		self.CombatIndicator:SetPoint('CENTER', self.RestingIndicator, 'CENTER')

		if unit ~= 'player' then
			self.SUI_ClassIcon = self:CreateTexture(nil, 'BORDER')
			self.SUI_ClassIcon:SetSize(20, 20)
			self.SUI_ClassIcon:SetPoint('CENTER', self.RestingIndicator, 'CENTER', 0, 0)

			self.RaidTargetIndicator = self:CreateTexture(nil, 'ARTWORK')
			self.RaidTargetIndicator:SetSize(20, 20)
			self.RaidTargetIndicator:SetPoint('CENTER', self, 'BOTTOMLEFT', -27, 0)
		end

		self.StatusText = self:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline22')
		-- self.StatusText:SetPoint("CENTER",self,"CENTER");
		self.StatusText:SetAllPoints(self.Portrait)
		self.StatusText:SetJustifyH('CENTER')
		self:Tag(self.StatusText, '[afkdnd]')
	end
	do -- Special Icons/Bars
		if unit == 'player' then
			--Runes
			local playerClass = select(2, UnitClass('player'))
			if unit == 'player' and playerClass == 'DEATHKNIGHT' then
				self.Runes = CreateFrame('Frame', nil, self)
				self.Runes.colorSpec = true

				for i = 1, 6 do
					self.Runes[i] = CreateFrame('StatusBar', self:GetName() .. '_Runes' .. i, self)
					self.Runes[i]:SetHeight(6)
					self.Runes[i]:SetWidth((self.Health:GetWidth() - 10) / 6)
					if (i == 1) then
						self.Runes[i]:SetPoint('TOPLEFT', self.Name, 'BOTTOMLEFT', 0, -3)
					else
						self.Runes[i]:SetPoint('TOPLEFT', self.Runes[i - 1], 'TOPRIGHT', 2, 0)
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

			self.ReadyCheckIndicator = self:CreateTexture(nil, 'OVERLAY')
			self.ReadyCheckIndicator:SetSize(30, 30)
			self.ReadyCheckIndicator:SetPoint('LEFT', self, 'LEFT', 0, 0)
			
			--Combo Points & Special unit power itemsitems = CreateFrame("Frame",nil,self);
			local items = CreateFrame('Frame', nil, self)
			items:SetFrameStrata('BACKGROUND')
			items:SetSize(1, 1)
			items:SetFrameLevel(4)
			items:SetPoint('TOPLEFT', self)

			self.ComboPoints = self:CreateFontString(nil, 'BORDER', 'SUI_FontOutline13')
			self.ComboPoints:SetPoint('TOPLEFT', self.Name, 'BOTTOMLEFT', 40, -5)
			if unit == 'player' then
				local ClassPower = {}
				for index = 1, 10 do
					local Bar = CreateFrame('StatusBar', nil, self)
					Bar:SetStatusBarTexture(Smoothv2)

					-- Position and size.
					Bar:SetSize(16, 5)
					if (index == 1) then
						Bar:SetPoint('LEFT', self.ComboPoints, 'RIGHT', (index - 1) * Bar:GetWidth(), -1)
					else
						Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 3, 0)
					end
					-- Bar:SetPoint('LEFT', self, 'RIGHT', , 0)

					ClassPower[index] = Bar
				end

				-- Register with SUF
				self.ClassPower = ClassPower
			end

			-- Druid Mana
			local DruidMana = CreateFrame('StatusBar', nil, self)
			DruidMana:SetSize(self.Power:GetWidth(), 4)
			DruidMana:SetPoint('TOP', self.Power, 'BOTTOM', 0, 0)
			DruidMana.colorPower = true
			DruidMana:SetStatusBarTexture(Smoothv2)
			local Background = DruidMana:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(DruidMana)
			Background:SetTexture(1, 1, 1, .2)
			self.AdditionalPower = DruidMana
			self.AdditionalPower.bg = Background
		end
	end
	do -- setup buffs and debuffs
		self.DispelHighlight = self.Health:CreateTexture(nil, 'OVERLAY')
		self.DispelHighlight:SetAllPoints(self.Health:GetStatusBarTexture())
		self.DispelHighlight:SetTexture(Smoothv2)
		self.DispelHighlight:Hide()

		if unit == 'player' or unit == 'target' then
			self.BuffAnchor = CreateFrame('Frame', nil, self)
			self.BuffAnchor:SetSize(self:GetWidth() + 60, 1)
			self.BuffAnchor:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', -60, 5)
			self.BuffAnchor:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 5)

			self = PlayerFrames:Buffs(self, unit)
		end
	end

	self.Range = {insideAlpha = 1, outsideAlpha = .3}
	self.TextUpdate = PostUpdateText
	self.ColorUpdate = PostUpdateColor
	return self
end

local CreateMediumFrame = function(self, unit)
	if self:GetWidth() ~= 120 then
		self:SetSize(120, 45)
	end
	do -- setup base artwork
		self.artwork = CreateFrame('Frame', nil, self)
		self.artwork:SetFrameStrata('BACKGROUND')
		self.artwork:SetFrameLevel(1)
		self.artwork:SetAllPoints(self)

		self.artwork.bg = self.artwork:CreateTexture(nil, 'BACKGROUND')
		self.artwork.bg:SetPoint('CENTER', self)
		self.artwork.bg:SetTexture(Images.smallbg.Texture)
		self.artwork.bg:SetTexCoord(unpack(Images.smallbg.Coords))
		self.artwork.bg:SetSize(self:GetSize())

		self.artwork.flair = CreateFrame('Frame', nil, self)
		self.artwork.flair:SetFrameStrata('BACKGROUND')
		self.artwork.flair:SetFrameLevel(2)
		self.artwork.flair:SetAllPoints(self)

		self.artwork.flair.bg = self.artwork.flair:CreateTexture(nil, 'BACKGROUND')
		-- self.artwork.flair:SetBlendMode("ADD");
		-- self.artwork.flair:SetParent(self.artwork.bg)
		self.artwork.flair.bg:SetPoint('RIGHT', self, 'RIGHT', 0, 0)
		self.artwork.flair.bg:SetTexture(Images.flair2.Texture)
		self.artwork.flair.bg:SetTexCoord(unpack(Images.flair2.Coords))
		self.artwork.flair.bg:SetSize(self:GetWidth(), self:GetHeight() + 20)

		self.ThreatIndicator = self.artwork:CreateTexture(nil, 'BACKGROUND', nil, -5)
		self.ThreatIndicator:SetTexture('Interface\\Scenarios\\Objective-Lineglow')
		self.ThreatIndicator:SetAlpha(.6)
		self.ThreatIndicator:SetTexCoord(0, 1, 1, 0)
		self.ThreatIndicator:SetVertexColor(1, 0, 0)
		self.ThreatIndicator:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 3, -15)
		self.ThreatIndicator:SetSize(self:GetWidth() + 6, self:GetHeight() + 15)
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(3)
			cast:SetSize(self:GetWidth(), 8)
			cast:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, -2)
			cast:SetStatusBarTexture(Smoothv2)

			cast.Text = cast:CreateFontString()
			SUI:FormatFont(cast.Text, 8, 'Player')
			cast.Text:SetAllPoints(cast)
			cast.Text:SetJustifyH('CENTER')
			cast.Text:SetJustifyV('MIDDLE')

			cast.Time = cast:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline8')
			cast.Time:SetAllPoints(cast)
			cast.Time:SetJustifyH('LEFT')
			cast.Time:SetJustifyV('MIDDLE')

			self.Castbar = cast
			self.Castbar.OnUpdate = OnCastbarUpdate
			self.Castbar.PostCastStart = PostCastStart
			self.Castbar.PostChannelStart = PostChannelStart
			self.Castbar.PostCastStop = PostCastStop
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(2)
			health:SetStatusBarTexture(Smoothv2)
			health:SetSize(self.Castbar:GetWidth(), 24)
			health:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, -12)
			health:SetAlpha(.8)

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetSize(self:GetWidth(), 11)
			health.value:SetJustifyH('CENTER')
			health.value:SetJustifyV('MIDDLE')
			health.value:SetAllPoints(health)
			self:Tag(health.value, PlayerFrames:TextFormat('health'))
			self.Health = health

			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			-- self.Health.colorClass = true;
			self.Health.colorSmooth = true
			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			SUI:SUF_HealPrediction(self)
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(2)
			power:SetSize(self.Castbar:GetWidth(), 8)
			power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -1)
			power:SetStatusBarTexture(Smoothv2)
			power:SetAlpha(.7)

			power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline8')
			power.ratio:SetJustifyH('CENTER')
			power.ratio:SetJustifyV('MIDDLE')
			power.ratio:SetAllPoints(power)
			self:Tag(power.ratio, '[perpp]%')

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
	end
	do -- setup ring, icons, and text
		self.Name = self:CreateFontString()
		SUI:FormatFont(self.Name, 8, 'Player')
		self.Name:SetSize(self:GetWidth(), 10)
		self.Name:SetJustifyH('LEFT')
		self.Name:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -2)
		self:Tag(self.Name, '[level] [SUI_ColorClass][name]')

		self.LeaderIndicator = self:CreateTexture(nil, 'BORDER')
		self.LeaderIndicator:SetSize(12, 12)
		self.LeaderIndicator:SetPoint('RIGHT', self.Name, 'LEFT')

		self.SUI_RaidGroup = self:CreateTexture(nil, 'BORDER')
		self.SUI_RaidGroup:SetSize(12, 12)
		self.SUI_RaidGroup:SetPoint('TOPLEFT', self, 'TOPLEFT')
		self.SUI_RaidGroup:SetTexture(square)
		self.SUI_RaidGroup:SetVertexColor(0, .8, .9, .9)

		self.SUI_RaidGroup.Text = self:CreateFontString(nil, 'BORDER', 'SUI_Font10')
		self.SUI_RaidGroup.Text:SetSize(12, 12)
		self.SUI_RaidGroup.Text:SetJustifyH('CENTER')
		self.SUI_RaidGroup.Text:SetJustifyV('MIDDLE')
		self.SUI_RaidGroup.Text:SetPoint('CENTER', self.SUI_RaidGroup, 'CENTER', 0, 1)
		self:Tag(self.SUI_RaidGroup.Text, '[group]')

		self.PvPIndicator = self:CreateTexture(nil, 'BORDER')
		self.PvPIndicator:SetSize(25, 25)
		self.PvPIndicator:SetPoint('CENTER', self, 'BOTTOMRIGHT', 0, -3)
		self.PvPIndicator.Override = pvpIcon

		self.GroupRoleIndicator = self:CreateTexture(nil, 'BORDER')
		self.GroupRoleIndicator:SetSize(18, 18)
		self.GroupRoleIndicator:SetPoint('CENTER', self, 'LEFT', 0, 0)
		self.GroupRoleIndicator:SetTexture(lfdrole)
		self.GroupRoleIndicator:SetAlpha(.75)

		self.ReadyCheckIndicator = self:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheckIndicator:SetSize(30, 30)
		self.ReadyCheckIndicator:SetPoint('LEFT', self, 'LEFT', 0, 0)
		
		self.CombatIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.CombatIndicator:SetSize(20, 20)
		self.CombatIndicator:SetPoint('CENTER', self.RestingIndicator, 'CENTER')

		self.StatusText = self:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline22')
		self.StatusText:SetPoint('CENTER', self, 'CENTER')
		self.StatusText:SetJustifyH('CENTER')
		self:Tag(self.StatusText, '[afkdnd]')
	end
	do -- setup buffs and debuffs
		self.AuraWatch = SUI:SUF_Buffs(self, 'TOPRIGHT', 'TOPRIGHT', 0)

		self.DispelHighlight = self.Health:CreateTexture(nil, 'OVERLAY')
		self.DispelHighlight:SetAllPoints(self.Health:GetStatusBarTexture())
		self.DispelHighlight:SetTexture(Smoothv2)
		self.DispelHighlight:Hide()
	end

	self.Range = {insideAlpha = 1, outsideAlpha = .3}
	if unit == 'party' then
		self.TextUpdate = PartyFrames.PostUpdateText
	else
		self.TextUpdate = PostUpdateText
	end
	self.ColorUpdate = PostUpdateColor
	return self
end

local CreateSmallFrame = function(self, unit)
	if self:GetWidth() ~= 95 then
		self:SetSize(95, 30)
	end
	do -- setup base artwork
		self.artwork = CreateFrame('Frame', nil, self)
		self.artwork:SetFrameStrata('BACKGROUND')
		self.artwork:SetFrameLevel(2)
		self.artwork:SetAllPoints(self)
		self.artwork.bg = self.artwork:CreateTexture(nil, 'BACKGROUND')
		self.artwork.bg:SetPoint('CENTER', self)
		self.artwork.bg:SetTexture(Images.smallbg.Texture)
		self.artwork.bg:SetTexCoord(unpack(Images.smallbg.Coords))
		self.artwork.bg:SetSize(self:GetSize())

		self.ThreatIndicator = CreateFrame('Frame', nil, self)
		local overlay = self:CreateTexture(nil, 'OVERLAY')
		overlay:SetTexture('Interface\\RaidFrame\\Raid-FrameHighlights')
		overlay:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750)
		overlay:SetAllPoints(self)
		overlay:SetVertexColor(1, 0, 0)
		overlay:Hide()
		self.ThreatIndicatorOverlay = overlay
		self.ThreatIndicator.Override = threat
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(2)
			health:SetStatusBarTexture(Smoothv2)
			health:SetSize(self:GetWidth(), 25)
			health:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 0)
			health:SetAlpha(.7)

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetSize(self:GetWidth(), 11)
			health.value:SetJustifyH('CENTER')
			health.value:SetJustifyV('MIDDLE')
			health.value:SetPoint('BOTTOMLEFT', health, 'BOTTOMLEFT')
			if unit == 'raid' then
				health.value:SetPoint('TOPRIGHT', health, 'TOPRIGHT', 0, -8)
			else
				health.value:SetPoint('TOPRIGHT', health, 'TOPRIGHT', 0, 0)
			end
			self:Tag(health.value, '[perhp]%')
			self.Health = health

			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			self.Health.colorClass = true
			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			SUI:SUF_HealPrediction(self)
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(2)
			power:SetSize(self:GetWidth(), 5)
			power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, 0)
			power:SetStatusBarTexture(Smoothv2)
			power:SetAlpha(.7)

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
		for i = 1, 3 do
			if unit == 'arena' .. i then
				self.Power.OverrideArenaPreparation = UpdatePowerPrep
				self.Health.OverrideArenaPreparation = UpdateHealthPrep
			end
		end
	end
	do -- setup ring, icons, and text
		self.Name = self:CreateFontString()
		SUI:FormatFont(self.Name, 10, 'Player')
		self.Name:SetSize(self:GetWidth(), 10)
		self.Name:SetJustifyV('TOP')
		self.Name:SetJustifyH('CENTER')
		if unit == 'raid' then
			self.Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 0)
		else
			self.Name:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, 0)
		end
		self:Tag(self.Name, '[SUI_ColorClass][name]')

		self.RaidTargetIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.RaidTargetIndicator:SetSize(20, 20)
		self.RaidTargetIndicator:SetPoint('BOTTOMLEFT', self)

		self.ReadyCheckIndicator = self:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheckIndicator:SetSize(30, 30)
		self.ReadyCheckIndicator:SetPoint('LEFT', self, 'LEFT', 0, 0)

		self.StatusText = self:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline22')
		self.StatusText:SetPoint('CENTER', self, 'CENTER')
		self.StatusText:SetJustifyH('CENTER')
		self:Tag(self.StatusText, '[afkdnd]')
	end
	do -- setup buffs and debuffs
		self.AuraWatch = SUI:SUF_Buffs(self, 'TOPRIGHT', 'TOPRIGHT', -5)

		self.DispelHighlight = self.Health:CreateTexture(nil, 'OVERLAY')
		self.DispelHighlight:SetAllPoints(self.Health:GetStatusBarTexture())
		self.DispelHighlight:SetTexture(Smoothv2)
		self.DispelHighlight:Hide()
	end

	self.Range = {insideAlpha = 1, outsideAlpha = .3}
	self.TextUpdate = PostUpdateText
	self.ColorUpdate = PostUpdateColor
	return self
end

local CreateUnitFrame = function(self, unit)
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		self:SetParent(UIParent)
	else
		self:SetParent(SUI_FramesAnchor)
	end

	self =
		((unit == 'target' and CreateLargeFrame(self, unit)) or (unit == 'player' and CreateLargeFrame(self, unit)) or
		(unit == 'targettarget' and CreateSmallFrame(self, unit)) or
		(unit == 'focus' and CreateMediumFrame(self, unit)) or
		(unit == 'focustarget' and CreateSmallFrame(self, unit)) or
		(unit == 'pet' and CreateSmallFrame(self, unit)) or
		(unit == 'arena' and CreateMediumFrame(self, unit)) or
		CreateSmallFrame(self, unit))

	if self.Buffs and self.Buffs.PostUpdate then
		self.Buffs:PostUpdate(unit, 'Buffs')
	end
	if self.Debuffs and self.Debuffs.PostUpdate then
		self.Debuffs:PostUpdate(unit, 'Debuffs')
	end

	self = PlayerFrames:MakeMovable(self, unit)

	return self
end

local CreateUnitFrameParty = function(self, unit)
	if SUI.DB.Styles.Fel.PartyFrames.FrameStyle == 'small' then
		self = CreateSmallFrame(self, unit)
	elseif SUI.DB.Styles.Fel.PartyFrames.FrameStyle == 'medium' then
		self = CreateMediumFrame(self, unit)
	elseif SUI.DB.Styles.Fel.PartyFrames.FrameStyle == 'large' then
		self = CreateLargeFrame(self, unit)
	end
	self = PartyFrames:MakeMovable(self)
	return self
end

local CreateUnitFrameRaid = function(self, unit)
	if SUI.DB.Styles.Fel.RaidFrames.FrameStyle == 'small' then
		self = CreateSmallFrame(self, unit)
	elseif SUI.DB.Styles.Fel.RaidFrames.FrameStyle == 'medium' then
		self = CreateMediumFrame(self, unit)
	elseif SUI.DB.Styles.Fel.RaidFrames.FrameStyle == 'large' then
		self = CreateLargeFrame(self, unit)
	end
	self = SUI:GetModule('RaidFrames'):MakeMovable(self)
	return self
end

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

SUIUF:RegisterStyle('Spartan_FelPlayerFrames', CreateUnitFrame)
SUIUF:RegisterStyle('Spartan_FelPartyFrames', CreateUnitFrameParty)
SUIUF:RegisterStyle('Spartan_FelRaidFrames', CreateUnitFrameRaid)

-- Module Calls
function module:FrameSize(size)
	--small
	local w = 95
	local h = 30
	if size == 'medium' then
		w = 120
		h = 45
	elseif size == 'large' then
		w = 180
		h = 58
	end

	local initialConfigFunction = [[
		self:SetWidth(%d)
		self:SetHeight(%d)
	]]
	return format(initialConfigFunction, w, h)
end

function module:PlayerFrames()
	module:ImageSetup()
	PlayerFrames = SUI:GetModule('PlayerFrames')
	SUIUF:SetActiveStyle('Spartan_FelPlayerFrames')
	PlayerFrames:BuffOptions()

	local FramesList = {
		[1] = 'pet',
		[2] = 'target',
		[3] = 'targettarget',
		[4] = 'focus',
		[5] = 'focustarget',
		[6] = 'player'
	}

	for _, b in pairs(FramesList) do
		PlayerFrames[b] = SUIUF:Spawn(b, 'SUI_' .. b .. 'Frame')
		if b == 'player' then
			PlayerFrames:SetupExtras()
		end
		-- PlayerFrames[b].artwork.bg:SetVertexColor(0,.8,.9,.9)
	end

	module:PositionFrame()
	module:UpdateAltBarPositions()

	if SUI.DBMod.PlayerFrames.BossFrame.display == true then
		if (InCombatLockdown()) then
			return
		end
		local arena = {}
		for i = 1, 3 do
			arena[i] = SUIUF:Spawn('arena' .. i, 'SUI_Arena' .. i)
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

		local boss = {}
		for i = 1, MAX_BOSS_FRAMES do
			boss[i] = SUIUF:Spawn('boss' .. i, 'SUI_Boss' .. i)
			-- boss[i].artwork.bg:SetVertexColor(0,.8,.9,.9)

			if i == 1 then
				boss[i]:SetMovable(true)
				if SUI.DBMod.PlayerFrames.BossFrame.movement.moved then
					boss[i]:SetPoint(
						SUI.DBMod.PlayerFrames.BossFrame.movement.point,
						SUI.DBMod.PlayerFrames.BossFrame.movement.relativeTo,
						SUI.DBMod.PlayerFrames.BossFrame.movement.relativePoint,
						SUI.DBMod.PlayerFrames.BossFrame.movement.xOffset,
						SUI.DBMod.PlayerFrames.BossFrame.movement.yOffset
					)
				else
					boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				end
			else
				boss[i]:SetPoint('TOP', boss[i - 1], 'BOTTOM', 0, -10)
			end
		end

		boss.mover = CreateFrame('Frame')
		boss.mover:SetSize(5, 5)
		boss.mover:SetPoint('TOPLEFT', SUI_Boss1, 'TOPLEFT')
		boss.mover:SetPoint('TOPRIGHT', SUI_Boss1, 'TOPRIGHT')
		boss.mover:SetPoint('BOTTOMLEFT', 'SUI_Boss' .. MAX_BOSS_FRAMES, 'BOTTOMLEFT')
		boss.mover:SetPoint('BOTTOMRIGHT', 'SUI_Boss' .. MAX_BOSS_FRAMES, 'BOTTOMRIGHT')
		boss.mover:EnableMouse(true)

		boss.bg = boss.mover:CreateTexture(nil, 'BACKGROUND')
		boss.bg:SetAllPoints(boss.mover)
		boss.bg:SetTexture(1, 1, 1, 0.5)

		boss.mover:Hide()
		boss.mover:RegisterEvent('VARIABLES_LOADED')
		boss.mover:RegisterEvent('PLAYER_REGEN_DISABLED')

		function PlayerFrames:UpdateBossFramePosition()
			if (InCombatLockdown()) then
				return
			end
			if SUI.DBMod.PlayerFrames.BossFrame.movement.moved then
				SUI_Boss1:SetPoint(
					SUI.DBMod.PlayerFrames.BossFrame.movement.point,
					SUI.DBMod.PlayerFrames.BossFrame.movement.relativeTo,
					SUI.DBMod.PlayerFrames.BossFrame.movement.relativePoint,
					SUI.DBMod.PlayerFrames.BossFrame.movement.xOffset,
					SUI.DBMod.PlayerFrames.BossFrame.movement.yOffset
				)
			else
				SUI_Boss1:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', -50, -490)
			end
		end

		PlayerFrames.boss = boss
	end
	SUI.PlayerFrames = PlayerFrames

	local unattached = false
	Fel_SpartanUI:HookScript(
		'OnHide',
		function(this, event)
			if UnitUsingVehicle('player') then
				SUI_FramesAnchor:SetParent(UIParent)
				unattached = true
			end
		end
	)

	Fel_SpartanUI:HookScript(
		'OnShow',
		function(this, event)
			if unattached then
				SUI_FramesAnchor:SetParent(Fel_SpartanUI)
				module:PositionFrame()
			end
		end
	)
end

function module:PositionFrame(b)
	--Clear Point
	if b ~= nil and PlayerFrames[b] then
		PlayerFrames[b]:ClearAllPoints()
	end
	--Set Position
	if Fel_SpartanUI.Left then
		if b == 'player' or b == nil then
			PlayerFrames.player:SetPoint('BOTTOMRIGHT', Fel_SpartanUI.Left, 'TOPLEFT', -60, 10)
		end
	else
		if b == 'player' or b == nil then
			PlayerFrames.player:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOM', -60, 250)
		end
	end

	if b == 'pet' or b == nil then
		PlayerFrames.pet:SetPoint('RIGHT', PlayerFrames.player, 'BOTTOMLEFT', -60, 0)
	end

	if b == 'target' or b == nil then
		PlayerFrames.target:SetPoint('LEFT', PlayerFrames.player, 'RIGHT', 150, 0)
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

	local FramesList = {
		[1] = 'pet',
		[2] = 'target',
		[3] = 'targettarget',
		[4] = 'focus',
		[5] = 'focustarget',
		[6] = 'player'
	}
	for _, c in pairs(FramesList) do
		PlayerFrames[c]:SetScale(SUI.DB.scale)
	end

	module:UpdateAltBarPositions()
end

function module:RaidFrames()
	module:ImageSetup()
	SUIUF:SetActiveStyle('Spartan_FelRaidFrames')
	module:RaidOptions()

	local xoffset = 1
	local yOffset = -1
	local point = 'TOP'
	local columnAnchorPoint = 'LEFT'
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'

	if SUI.DBMod.RaidFrames.mode == 'GROUP' then
		groupingOrder = '1,2,3,4,5,6,7,8'
	end
	if SUI.DB.Styles.Fel.RaidFrames.FrameStyle == 'medium' then
		xoffset = 10
	end

	if _G['SUI_RaidFrameHeader'] then
		_G['SUI_RaidFrameHeader'] = nil
	end

	local raid =
		SUIUF:SpawnHeader(
		'SUI_RaidFrameHeader',
		nil,
		'raid',
		'showRaid',
		SUI.DBMod.RaidFrames.showRaid,
		'showParty',
		SUI.DBMod.RaidFrames.showParty,
		'showPlayer',
		true,
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
		columnAnchorPoint,
		'SUF-initialConfigFunction',
		module:FrameSize(SUI.DB.Styles.Fel.RaidFrames.FrameStyle)
	)

	raid:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 20, -40)

	return (raid)
end

function module:PartyFrames()
	module:ImageSetup()
	PartyFrames = SUI:GetModule('PartyFrames')
	SUIUF:SetActiveStyle('Spartan_FelPartyFrames')
	module:PartyOptions()

	if _G['SUI_PartyFrameHeader'] then
		_G['SUI_PartyFrameHeader'] = nil
	end

	local party =
		SUIUF:SpawnHeader(
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
		-16,
		'xOffset',
		0,
		'columnAnchorPoint',
		'TOPLEFT',
		'initial-anchor',
		'TOPLEFT',
		'SUF-initialConfigFunction',
		module:FrameSize(SUI.DB.Styles.Fel.PartyFrames.FrameStyle)
	)

	return (party)
end

-- Options Builders

function module:RaidOptions()
	SUI.opt.args['RaidFrames'].args['FrameStyle'] = {
		name = L['FrameStyle'],
		type = 'select',
		order = 2,
		values = {['large'] = L['Large'], ['medium'] = L['Medium'], ['small'] = L['Small']},
		get = function(info)
			return SUI.DB.Styles.Fel.RaidFrames.FrameStyle
		end,
		set = function(info, val)
			SUI.DB.Styles.Fel.RaidFrames.FrameStyle = val
			SUI:reloadui()
		end
	}
end

function module:PartyOptions()
	SUI.opt.args['PartyFrames'].args['FrameStyle'] = {
		name = L['FrameStyle'],
		type = 'select',
		order = 2,
		values = {['large'] = L['Large'], ['medium'] = L['Medium'], ['small'] = L['Small']},
		get = function(info)
			return SUI.DB.Styles.Fel.PartyFrames.FrameStyle
		end,
		set = function(info, val)
			SUI.DB.Styles.Fel.PartyFrames.FrameStyle = val
			SUI:reloadui()
		end
	}
end
