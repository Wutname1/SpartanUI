local _G, SUI = _G, SUI
local module = SUI:GetModule('Module_UnitFrames')
local PartyFrames = {}
local PlayerFrames = {}
local RaidFrames = {}
----------------------------------------------------------------------------------------------------
local Smoothv2 = SUI.BarTextures.smooth
local FramesList = {
	[1] = 'pet',
	[2] = 'target',
	[3] = 'targettarget',
	[4] = 'focus',
	[5] = 'focustarget',
	[6] = 'player'
}

local function CreateUnitFrame(self, unit)
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		self:SetParent(UIParent)
	else
		self:SetParent(SUI_FramesAnchor)
	end

	-- Build a function that updates the size of the frame and sizes of elements
	local function UpdateSize()
		-- Find the Height of the frame
		local FrameHeight = 0
		if module.CurrentSettings[unit].elements.Castbar.enabled then
			FrameHeight = FrameHeight + module.CurrentSettings[unit].elements.Castbar.height
		end
		if module.CurrentSettings[unit].elements.Health.enabled then
			FrameHeight = FrameHeight + module.CurrentSettings[unit].elements.Health.height
		end
		if module.CurrentSettings[unit].elements.Power.enabled then
			FrameHeight = FrameHeight + module.CurrentSettings[unit].elements.Power.height
		end
		self:SetSize(module.CurrentSettings[unit].width, FrameHeight)

		-- Adjust the elements that could be effected
		if self.Portrait3D then
			self.Portrait3D:SetSize(FrameHeight, FrameHeight)
		end

		if self.Portrait2D then
			self.Portrait2D:SetSize(FrameHeight, FrameHeight)
		end

		if self.Castbar then
			self.Castbar:SetSize(self:GetWidth(), module.CurrentSettings[unit].elements.Castbar.height)
		end

		if self.Health then
			if module.CurrentSettings[unit].elements.Castbar.enabled then
				self.Health:SetPoint('TOP', self, 'TOP', 0, ((module.CurrentSettings[unit].elements.Castbar.height + 2) * -1))
			else
				self.Health:SetPoint('TOP', self, 'TOP', 0, 0)
			end

			self.Health:SetSize(self:GetWidth(), module.CurrentSettings[unit].elements.Health.height)
		end

		if self.Power then
			local PositionData = 0
			if module.CurrentSettings[unit].elements.Castbar.enabled then
				PositionData = module.CurrentSettings[unit].elements.Castbar.height
			end

			PositionData = PositionData + module.CurrentSettings[unit].elements.Health.height

			self.Power:SetPoint('TOP', self, 'TOP', 0, ((PositionData + 2) * -1))

			self.Power:SetSize(self:GetWidth(), module.CurrentSettings[unit].elements.Power.height)
		end
	end
	self.UpdateSize = UpdateSize

	self.UpdateSize()

	do -- General setup
		-- 	self.artwork = CreateFrame('Frame', nil, self)
		-- 	self.artwork:SetFrameStrata('BACKGROUND')
		-- 	self.artwork:SetFrameLevel(2)
		-- 	self.artwork:SetAllPoints()

		-- 	self.artwork.bgNeutral = self.artwork:CreateTexture(nil, 'BORDER')
		-- 	self.artwork.bgNeutral:SetAllPoints(self)
		-- 	self.artwork.bgNeutral:SetTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')
		-- 	self.artwork.bgNeutral:SetVertexColor(0, 0, 0, .6)

		-- 	self.artwork.bgAlliance = self.artwork:CreateTexture(nil, 'BACKGROUND')
		-- 	self.artwork.bgAlliance:SetPoint('CENTER', self)
		-- 	self.artwork.bgAlliance:SetTexture(Images.Alliance.bg.Texture)
		-- 	self.artwork.bgAlliance:SetTexCoord(unpack(Images.Alliance.bg.Coords))
		-- 	self.artwork.bgAlliance:SetSize(self:GetSize())

		-- 	self.artwork.bgHorde = self.artwork:CreateTexture(nil, 'BACKGROUND')
		-- 	self.artwork.bgHorde:SetPoint('CENTER', self)
		-- 	self.artwork.bgHorde:SetTexture(Images.Horde.bg.Texture)
		-- 	self.artwork.bgHorde:SetTexCoord(unpack(Images.Horde.bg.Coords))
		-- 	self.artwork.bgHorde:SetSize(self:GetSize())

		-- 	self.artwork.flairAlliance = self.artwork:CreateTexture(nil, 'BORDER')
		-- 	self.artwork.flairAlliance:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, -7)
		-- 	self.artwork.flairAlliance:SetTexture(Images.Alliance.flair.Texture)
		-- 	self.artwork.flairAlliance:SetTexCoord(unpack(Images.Alliance.flair.Coords))
		-- 	self.artwork.flairAlliance:SetSize(self:GetWidth(), self:GetHeight() + 37)

		-- 	self.artwork.flairHorde = self.artwork:CreateTexture(nil, 'BORDER')
		-- 	self.artwork.flairHorde:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, -7)
		-- 	self.artwork.flairHorde:SetTexture(Images.Horde.flair.Texture)
		-- 	self.artwork.flairHorde:SetTexCoord(unpack(Images.Horde.flair.Coords))
		-- 	self.artwork.flairHorde:SetSize(self:GetWidth(), self:GetHeight() + 37)

		-- 3D Portrait
		local Portrait3D = CreateFrame('PlayerModel', nil, self)
		Portrait3D:SetSize(self:GetHeight(), self:GetHeight())
		Portrait3D:SetScale(module.CurrentSettings[unit].elements.Portrait.Scale)
		self.Portrait3D = Portrait3D

		-- 2D Portrait
		local Portrait2D = self:CreateTexture(nil, 'OVERLAY')
		Portrait2D:SetSize(self:GetHeight(), self:GetHeight())
		Portrait2D:SetScale(module.CurrentSettings[unit].elements.Portrait.Scale)
		self.Portrait2D = Portrait2D

		if module.CurrentSettings[unit].elements.Portrait.position == 'left' then
			Portrait3D:SetPoint('RIGHT', self, 'LEFT')
			Portrait2D:SetPoint('RIGHT', self, 'LEFT')
		else
			Portrait3D:SetPoint('LEFT', self, 'RIGHT')
			Portrait2D:SetPoint('LEFT', self, 'RIGHT')
		end
		if module.CurrentSettings[unit].elements.Portrait.type == '3D' then
			self.Portrait = self.Portrait3D
		else
			self.Portrait = self.Portrait2D
		end

		-- 	local Threat = self:CreateTexture(nil, 'OVERLAY')
		-- 	Threat:SetSize(25, 25)
		-- 	Threat:SetPoint('CENTER', self, 'RIGHT')
		-- 	self.ThreatIndicator = Threat
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(2)
			cast:SetStatusBarTexture(Smoothv2)
			cast:SetSize(self:GetWidth(), module.CurrentSettings[unit].elements.Castbar.height)
			cast:SetPoint('TOP', self, 'TOP', 0, 0)

			local Text = cast:CreateFontString()
			SUI:FormatFont(Text, 10, 'Player')
			Text:SetJustifyH('CENTER')
			Text:SetJustifyV('MIDDLE')
			Text:SetAllPoints(cast)

			-- Add Shield
			local Shield = cast:CreateTexture(nil, 'OVERLAY')
			Shield:SetSize(20, 20)
			Shield:SetPoint('CENTER', cast, 'RIGHT')
			-- Shield:SetTexture([[Interface\CastingBar\UI-CastingBar-Small-Shield]])
			local function PostCastNotInterruptible(unit)
				if not module.CurrentSettings[unit].elements.Castbar.interruptable then
					self.Castbar.Shield:Hide()
				end
			end
			cast.PostCastNotInterruptible = PostCastNotInterruptible

			-- Add safezone
			local SafeZone = cast:CreateTexture(nil, 'OVERLAY')

			self.Castbar = cast
			self.Castbar.Text = Text
			self.Castbar.SafeZone = SafeZone
			self.Castbar.Shield = Shield

			-- self.Castbar.OnUpdate = OnCastbarUpdate
			-- self.Castbar.PostCastStart = PostCastStart
			-- self.Castbar.PostChannelStart = PostChannelStart
			-- self.Castbar.PostCastStop = PostCastStop
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(2)
			health:SetStatusBarTexture(Smoothv2)
			health:SetSize(self:GetWidth(), module.CurrentSettings[unit].elements.Health.height)
			if module.CurrentSettings[unit].elements.Castbar.enabled then
				health:SetPoint('TOP', self, 'TOP', 0, ((module.CurrentSettings[unit].elements.Castbar.height + 2) * -1))
			else
				health:SetPoint('TOP', self, 'TOP', 0, 0)
			end

			health.TextData = module.CurrentSettings[unit].elements.Health.text
			health.TextElements = {}
			for i, key in pairs(module.CurrentSettings[unit].elements.Health.text) do
				if key.enabled then
					local NewString = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					NewString:SetJustifyH(key.SetJustifyH)
					NewString:SetJustifyV(key.SetJustifyV)
					NewString:SetPoint(key.position.anchor, health, key.position.anchor, key.position.x, key.position.y)
					self:Tag(NewString, key.text)

					health.TextElements[i] = NewString
				end
			end

			self.Health = health

			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			self.Health.colorDisconnected = module.CurrentSettings[unit].elements.Health.colorDisconnected
			self.Health.colorTapping = module.CurrentSettings[unit].elements.Health.colorTapping
			self.Health.colorReaction = module.CurrentSettings[unit].elements.Health.colorReaction
			self.Health.colorSmooth = module.CurrentSettings[unit].elements.Health.colorSmooth
			self.Health.colorClass = module.CurrentSettings[unit].elements.Health.colorClass

			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			self.Health.DataTable = module.CurrentSettings[unit].elements.Health.text

			if not SUI.IsClassic then
				-- Position and size
				local myBar = CreateFrame('StatusBar', nil, self.Health)
				myBar:SetPoint('TOP')
				myBar:SetPoint('BOTTOM')
				myBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
				myBar:SetStatusBarTexture(Smoothv2)
				myBar:SetStatusBarColor(0, 1, 0.5, 0.45)
				myBar:SetSize(150, 16)

				local otherBar = CreateFrame('StatusBar', nil, myBar)
				otherBar:SetPoint('TOP')
				otherBar:SetPoint('BOTTOM')
				otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
				otherBar:SetStatusBarTexture(Smoothv2)
				otherBar:SetStatusBarColor(0, 0.5, 1, 0.35)
				otherBar:SetSize(150, 16)

				local absorbBar = CreateFrame('StatusBar', nil, self.Health)
				absorbBar:SetPoint('TOP')
				absorbBar:SetPoint('BOTTOM')
				absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
				absorbBar:SetStatusBarTexture(Smoothv2)
				absorbBar:SetWidth(10)

				local healAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
				healAbsorbBar:SetPoint('TOP')
				healAbsorbBar:SetPoint('BOTTOM')
				healAbsorbBar:SetPoint('RIGHT', self.Health:GetStatusBarTexture())
				healAbsorbBar:SetStatusBarTexture(Smoothv2)
				healAbsorbBar:SetReverseFill(true)
				healAbsorbBar:SetWidth(10)

				local overAbsorb = self.Health:CreateTexture(nil, 'OVERLAY')
				overAbsorb:SetPoint('TOP')
				overAbsorb:SetPoint('BOTTOM')
				overAbsorb:SetPoint('LEFT', self.Health, 'RIGHT')
				overAbsorb:SetWidth(10)

				local overHealAbsorb = self.Health:CreateTexture(nil, 'OVERLAY')
				overHealAbsorb:SetPoint('TOP')
				overHealAbsorb:SetPoint('BOTTOM')
				overHealAbsorb:SetPoint('RIGHT', self.Health, 'LEFT')
				overHealAbsorb:SetWidth(10)

				self.HealthPrediction = {
					myBar = myBar,
					otherBar = otherBar,
					absorbBar = absorbBar,
					healAbsorbBar = healAbsorbBar,
					overAbsorb = overAbsorb,
					overHealAbsorb = overHealAbsorb,
					maxOverflow = 2
				}
			end
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(2)
			power:SetStatusBarTexture(Smoothv2)
			power:SetSize(self:GetWidth(), module.CurrentSettings[unit].elements.Power.height)
			local PositionData = 0
			if module.CurrentSettings[unit].elements.Castbar.enabled then
				PositionData = module.CurrentSettings[unit].elements.Castbar.height
			end
			PositionData = PositionData + module.CurrentSettings[unit].elements.Health.height
			power:SetPoint('TOP', self, 'TOP', 0, ((PositionData + 2) * -1))

			power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline8')
			power.ratio:SetJustifyH('CENTER')
			power.ratio:SetJustifyV('MIDDLE')
			power.ratio:SetAllPoints(power)
			self:Tag(power.ratio, '[perpp]%')

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true

			if unit == 'player' then
				-- Position and size
				local AdditionalPower = CreateFrame('StatusBar', nil, self)
				AdditionalPower:SetFrameStrata('BACKGROUND')
				AdditionalPower:SetFrameLevel(2)
				AdditionalPower:SetStatusBarTexture(Smoothv2)
				AdditionalPower:SetSize(self:GetWidth(), module.CurrentSettings[unit].elements.Power.height)
				if module.CurrentSettings[unit].elements.Power.enabled then
					PositionData = PositionData + module.CurrentSettings[unit].elements.Power.height
				end
				AdditionalPower:SetPoint('TOP', self, 'TOP', 0, ((PositionData + 2) * -1))

				-- local Background = AdditionalPower:CreateTexture(nil, 'BACKGROUND')
				-- Background:SetAllPoints(AdditionalPower)
				-- Background:SetTexture(1, 1, 1, .5)

				-- AdditionalPower.bg = Background
				AdditionalPower.colorPower = true
				self.AdditionalPower = AdditionalPower

				-- Position and size
				local mainBar = CreateFrame('StatusBar', nil, self.Power)
				mainBar:SetReverseFill(true)
				mainBar:SetStatusBarTexture(Smoothv2)
				mainBar:SetPoint('RIGHT', self.Power:GetStatusBarTexture(), 'RIGHT')
				mainBar:SetPoint('TOP')
				mainBar:SetPoint('BOTTOM')
				mainBar:SetWidth(200)

				local altBar = CreateFrame('StatusBar', nil, self.AdditionalPower)
				altBar:SetReverseFill(true)
				altBar:SetStatusBarTexture(Smoothv2)
				altBar:SetPoint('RIGHT', self.AdditionalPower:GetStatusBarTexture(), 'RIGHT')
				altBar:SetPoint('TOP')
				altBar:SetPoint('BOTTOM')
				altBar:SetWidth(200)

				self.PowerPrediction = {
					mainBar = mainBar,
					altBar = altBar
				}
			end
		end
	end
	-- do -- setup icons, and text
	-- 	local ring = CreateFrame('Frame', nil, self)
	-- 	ring:SetFrameStrata('MEDIUM')
	-- 	ring:SetAllPoints(self.Portrait)
	-- 	ring:SetFrameLevel(3)

	-- 	self.Name = self:CreateFontString()
	-- 	SUI:FormatFont(self.Name, 12, 'Player')
	-- 	self.Name:SetSize(self:GetWidth(), 12)
	-- 	self.Name:SetJustifyH('LEFT')
	-- 	self.Name:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -2)
	-- 	self:Tag(self.Name, '[difficulty][smartlevel] [SUI_ColorClass][name]')

	-- 	self.RareElite = self.artwork:CreateTexture(nil, 'BACKGROUND', nil, -2)
	-- 	self.RareElite:SetTexture('Interface\\Addons\\SpartanUI_Artwork\\Images\\status-glow')
	-- 	self.RareElite:SetAlpha(.6)
	-- 	self.RareElite:SetPoint('BOTTOMRIGHT', self.Name, 'BOTTOMRIGHT', 0, 0)
	-- 	self.RareElite:SetPoint('TOPLEFT', self.Portrait, 'TOPLEFT', 0, 0)

	-- 	self.LeaderIndicator = self:CreateTexture(nil, 'BORDER')
	-- 	self.LeaderIndicator:SetSize(12, 12)
	-- 	self.LeaderIndicator:SetPoint('RIGHT', self.Name, 'LEFT')

	-- 	self.SUI_RaidGroup = self:CreateTexture(nil, 'BORDER')
	-- 	self.SUI_RaidGroup:SetSize(12, 12)
	-- 	self.SUI_RaidGroup:SetPoint('TOPLEFT', self, 'TOPLEFT')
	-- 	self.SUI_RaidGroup:SetTexture(square)
	-- 	self.SUI_RaidGroup:SetVertexColor(0, .8, .9, .9)

	-- 	self.SUI_RaidGroup.Text = self:CreateFontString(nil, 'BORDER', 'SUI_Font10')
	-- 	self.SUI_RaidGroup.Text:SetSize(12, 12)
	-- 	self.SUI_RaidGroup.Text:SetJustifyH('CENTER')
	-- 	self.SUI_RaidGroup.Text:SetJustifyV('MIDDLE')
	-- 	self.SUI_RaidGroup.Text:SetPoint('CENTER', self.SUI_RaidGroup, 'CENTER', 0, 1)
	-- 	self:Tag(self.SUI_RaidGroup.Text, '[group]')

	-- 	self.ReadyCheckIndicator = self:CreateTexture(nil, 'OVERLAY')
	-- 	self.ReadyCheckIndicator:SetSize(30, 30)
	-- 	self.ReadyCheckIndicator:SetPoint('LEFT', self, 'LEFT', 0, 0)

	-- 	self.PvPIndicator = self:CreateTexture(nil, 'BORDER')
	-- 	self.PvPIndicator:SetSize(25, 25)
	-- 	self.PvPIndicator:SetPoint('CENTER', self, 'BOTTOMRIGHT', 0, -3)
	-- 	self.PvPIndicator.Override = pvpIconWar

	-- 	self.RestingIndicator = self:CreateTexture(nil, 'ARTWORK')
	-- 	self.RestingIndicator:SetSize(20, 20)
	-- 	self.RestingIndicator:SetPoint('CENTER', self, 'TOPLEFT')
	-- 	self.RestingIndicator:SetTexCoord(0.15, 0.86, 0.15, 0.86)

	-- 	self.GroupRoleIndicator = self:CreateTexture(nil, 'BORDER')
	-- 	self.GroupRoleIndicator:SetSize(18, 18)
	-- 	self.GroupRoleIndicator:SetPoint('CENTER', self, 'LEFT', 0, 0)
	-- 	self.GroupRoleIndicator:SetTexture(lfdrole)
	-- 	self.GroupRoleIndicator:SetAlpha(.75)

	-- 	self.CombatIndicator = self:CreateTexture(nil, 'ARTWORK')
	-- 	self.CombatIndicator:SetSize(20, 20)
	-- 	self.CombatIndicator:SetPoint('CENTER', self.RestingIndicator, 'CENTER')

	-- 	if unit ~= 'player' then
	-- 		self.SUI_ClassIcon = ring:CreateTexture(nil, 'BORDER')
	-- 		self.SUI_ClassIcon:SetSize(20, 20)
	-- 		self.SUI_ClassIcon:SetPoint('CENTER', self.RestingIndicator, 'CENTER', 0, 0)

	-- 		self.RaidTargetIndicator = ring:CreateTexture(nil, 'ARTWORK')
	-- 		self.RaidTargetIndicator:SetSize(20, 20)
	-- 		self.RaidTargetIndicator:SetPoint('CENTER', self, 'BOTTOMLEFT', -27, 0)
	-- 	end

	-- 	self.StatusText = self:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline22')
	-- 	-- self.StatusText:SetPoint("CENTER",self,"CENTER");
	-- 	self.StatusText:SetAllPoints(self.Portrait)
	-- 	self.StatusText:SetJustifyH('CENTER')
	-- 	self:Tag(self.StatusText, '[afkdnd]')
	-- end
	-- do -- Special Icons/Bars
	-- 	if unit == 'player' then
	-- 		local playerClass = select(2, UnitClass('player'))
	-- 		--Runes
	-- 		if playerClass == 'DEATHKNIGHT' then
	-- 			self.Runes = CreateFrame('Frame', nil, self)
	-- 			self.Runes.colorSpec = true

	-- 			for i = 1, 6 do
	-- 				self.Runes[i] = CreateFrame('StatusBar', self:GetName() .. '_Runes' .. i, self)
	-- 				self.Runes[i]:SetHeight(6)
	-- 				self.Runes[i]:SetWidth((self.Health:GetWidth() - 10) / 6)
	-- 				if (i == 1) then
	-- 					self.Runes[i]:SetPoint('TOPLEFT', self.Name, 'BOTTOMLEFT', 0, -3)
	-- 				else
	-- 					self.Runes[i]:SetPoint('TOPLEFT', self.Runes[i - 1], 'TOPRIGHT', 2, 0)
	-- 				end
	-- 				self.Runes[i]:SetStatusBarTexture(Smoothv2)
	-- 				self.Runes[i]:SetStatusBarColor(0, .39, .63, 1)

	-- 				self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, 'BORDER')
	-- 				self.Runes[i].bg:SetPoint('TOPLEFT', self.Runes[i], 'TOPLEFT', -0, 0)
	-- 				self.Runes[i].bg:SetPoint('BOTTOMRIGHT', self.Runes[i], 'BOTTOMRIGHT', 0, -0)
	-- 				self.Runes[i].bg:SetTexture(Smoothv2)
	-- 				self.Runes[i].bg:SetVertexColor(0, 0, 0, 1)
	-- 				self.Runes[i].bg.multiplier = 0.64
	-- 				self.Runes[i]:Hide()
	-- 			end
	-- 		end

	-- 		self.ComboPoints = self:CreateFontString(nil, 'BORDER', 'SUI_FontOutline13')
	-- 		self.ComboPoints:SetPoint('TOPLEFT', self.Name, 'BOTTOMLEFT', 40, -5)
	-- 		local ClassPower = {}
	-- 		for index = 1, 10 do
	-- 			local Bar = CreateFrame('StatusBar', nil, self)
	-- 			Bar:SetStatusBarTexture(Smoothv2)

	-- 			-- Position and size.
	-- 			Bar:SetSize(16, 5)
	-- 			if (index == 1) then
	-- 				Bar:SetPoint('LEFT', self.ComboPoints, 'RIGHT', (index - 1) * Bar:GetWidth(), -1)
	-- 			else
	-- 				Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 3, 0)
	-- 			end
	-- 			ClassPower[index] = Bar
	-- 		end

	-- 		-- Register with SUF
	-- 		self.ClassPower = ClassPower

	-- 		-- Druid Mana
	-- 		local DruidMana = CreateFrame('StatusBar', nil, self)
	-- 		DruidMana:SetSize(self.Power:GetWidth(), 4)
	-- 		DruidMana:SetPoint('TOP', self.Power, 'BOTTOM', 0, 0)
	-- 		DruidMana.colorPower = true
	-- 		DruidMana:SetStatusBarTexture(Smoothv2)
	-- 		local Background = DruidMana:CreateTexture(nil, 'BACKGROUND')
	-- 		Background:SetAllPoints(DruidMana)
	-- 		Background:SetTexture(1, 1, 1, .2)
	-- 		self.AdditionalPower = DruidMana
	-- 		self.AdditionalPower.bg = Background

	-- 		--Totem Bar
	-- 		for index = 1, 4 do
	-- 			_G['TotemFrameTotem' .. index]:SetFrameStrata('MEDIUM')
	-- 			_G['TotemFrameTotem' .. index]:SetFrameLevel(4)
	-- 			_G['TotemFrameTotem' .. index]:SetScale(.8)
	-- 		end
	-- 		hooksecurefunc(
	-- 			'TotemFrame_Update',
	-- 			function()
	-- 				TotemFrameTotem1:ClearAllPoints()
	-- 				TotemFrameTotem1:SetParent(self)
	-- 				TotemFrameTotem1:SetPoint('TOPLEFT', self.Name, 'BOTTOMLEFT', 20, 0)
	-- 			end
	-- 		)
	-- 	end
	-- end
	-- do -- setup buffs and debuffs
	-- 	self.DispelHighlight = self.Health:CreateTexture(nil, 'OVERLAY')
	-- 	self.DispelHighlight:SetAllPoints(self.Health:GetStatusBarTexture())
	-- 	self.DispelHighlight:SetTexture(Smoothv2)
	-- 	self.DispelHighlight:Hide()

	-- 	if unit == 'player' or unit == 'target' then
	-- 		self.BuffAnchor = CreateFrame('Frame', nil, self)
	-- 		self.BuffAnchor:SetSize(self:GetWidth() + 60, 1)
	-- 		self.BuffAnchor:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', -60, 5)
	-- 		self.BuffAnchor:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 5)

	-- 		self = PlayerFrames:Buffs(self, unit)
	-- 	end
	-- end

	self.Range = {insideAlpha = 1, outsideAlpha = .3}
	-- self.TextUpdate = PostUpdateText
	-- self.ColorUpdate = PostUpdateColor

	-- if self.Buffs and self.Buffs.PostUpdate then
	-- 	self.Buffs:PostUpdate(unit, 'Buffs')
	-- end
	-- if self.Debuffs and self.Debuffs.PostUpdate then
	-- 	self.Debuffs:PostUpdate(unit, 'Debuffs')
	-- end

	-- self = PlayerFrames:MakeMovable(self, unit)

	-- Setup the frame's Right click menu.
	self:RegisterForClicks('AnyDown')
	self:EnableMouse(enable)
	self:SetClampedToScreen(true)
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	return self
end

SUIUF:RegisterStyle('SpartanUI_UnitFrames', CreateUnitFrame)

function module:SpawnFrames()
	SUIUF:SetActiveStyle('SpartanUI_UnitFrames')
	--

	for _, b in pairs(FramesList) do
		module.frames[b] = SUIUF:Spawn(b, 'SUI_' .. b .. 'Frame')

		-- Disable objects based on settings
		if not module.CurrentSettings[b].elements.Portrait.enabled then
			module.frames[b]:DisableElement('Portrait')
		end
		if not module.CurrentSettings[b].elements.Castbar.enabled then
			module.frames[b]:DisableElement('Castbar')
		end
		if not module.CurrentSettings[b].elements.Health.enabled then
			module.frames[b]:DisableElement('Health')
		end
		if not module.CurrentSettings[b].elements.Power.enabled then
			module.frames[b]:DisableElement('Power')
		end
		if not module.CurrentSettings[b].elements.Range.enabled then
			module.frames[b]:DisableElement('Range')
		end

		-- if b == 'player' and not SUI.IsClassic then
		-- 	PlayerFrames:SetupExtras()
		-- end
	end

	-- local party =
	-- 	SUIUF:SpawnHeader(
	-- 	'SUI_PartyFrameHeader',
	-- 	nil,
	-- 	nil,
	-- 	'showRaid',
	-- 	SUI.DBMod.PartyFrames.showRaid,
	-- 	'showParty',
	-- 	SUI.DBMod.PartyFrames.showParty,
	-- 	'showPlayer',
	-- 	SUI.DBMod.PartyFrames.showPlayer,
	-- 	'showSolo',
	-- 	SUI.DBMod.PartyFrames.showSolo,
	-- 	'yOffset',
	-- 	-16,
	-- 	'xOffset',
	-- 	0,
	-- 	'columnAnchorPoint',
	-- 	'TOPLEFT',
	-- 	'initial-anchor',
	-- 	'TOPLEFT',
	-- 	'SUF-initialConfigFunction',
	-- 	module:FrameSize(SUI.DB.Styles.War.PartyFrames.FrameStyle)
	-- )

	-- local raid =
	-- 	SUIUF:SpawnHeader(
	-- 	'SUI_RaidFrameHeader',
	-- 	nil,
	-- 	'raid',
	-- 	'showRaid',
	-- 	SUI.DBMod.RaidFrames.showRaid,
	-- 	'showParty',
	-- 	SUI.DBMod.RaidFrames.showParty,
	-- 	'showPlayer',
	-- 	true,
	-- 	'showSolo',
	-- 	SUI.DBMod.RaidFrames.showSolo,
	-- 	'xoffset',
	-- 	xoffset,
	-- 	'yOffset',
	-- 	yOffset,
	-- 	'point',
	-- 	point,
	-- 	'groupBy',
	-- 	SUI.DBMod.RaidFrames.mode,
	-- 	'groupingOrder',
	-- 	groupingOrder,
	-- 	'sortMethod',
	-- 	'index',
	-- 	'maxColumns',
	-- 	SUI.DBMod.RaidFrames.maxColumns,
	-- 	'unitsPerColumn',
	-- 	SUI.DBMod.RaidFrames.unitsPerColumn,
	-- 	'columnSpacing',
	-- 	SUI.DBMod.RaidFrames.columnSpacing,
	-- 	'columnAnchorPoint',
	-- 	columnAnchorPoint,
	-- 	'SUF-initialConfigFunction',
	-- 	module:FrameSize(SUI.DB.Styles.War.RaidFrames.FrameStyle)
	-- )
end

----------------------------------------------------------------------------------------------------

function PlayerFrames:SUI_PlayerFrames_Classic()
	SUIUF:SetActiveStyle('SUI_PlayerFrames_Classic')

	for _, b in pairs(FramesList) do
		PlayerFrames[b] = SUIUF:Spawn(b, 'SUI_' .. b .. 'Frame')
		if b == 'player' then
			PlayerFrames:SetupExtras()
		end
	end

	PlayerFrames:PositionFrame_Classic()

	if SUI.DBMod.PlayerFrames.BossFrame.display == true then
		for i = 1, MAX_BOSS_FRAMES do
			PlayerFrames.boss[i] = SUIUF:Spawn('boss' .. i, 'SUI_Boss' .. i)
			if i == 1 then
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			else
				PlayerFrames.boss[i]:SetPoint('TOP', PlayerFrames.boss[i - 1], 'BOTTOM', 0, -10)
			end
		end
	end
	if SUI.DBMod.PlayerFrames.ArenaFrame.display == true then
		for i = 1, 3 do
			PlayerFrames.arena[i] = SUIUF:Spawn('arena' .. i, 'SUI_Arena' .. i)
			if i == 1 then
				PlayerFrames.arena[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				PlayerFrames.arena[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			else
				PlayerFrames.arena[i]:SetPoint('TOP', PlayerFrames.arena[i - 1], 'BOTTOM', 0, -10)
			end
		end
	end

	if SpartanUI then
		local unattached = false
		SpartanUI:HookScript(
			'OnHide',
			function(this, event)
				if UnitUsingVehicle('player') then
					SUI_FramesAnchor:SetParent(UIParent)
					unattached = true
				end
			end
		)

		SpartanUI:HookScript(
			'OnShow',
			function(this, event)
				if unattached then
					SUI_FramesAnchor:SetParent(SpartanUI)
					PlayerFrames:PositionFrame_Classic()
				end
			end
		)
	end
end

function PlayerFrames:PositionFrame_Classic(b)
	PlayerFrames.pet:SetParent(PlayerFrames.player)
	PlayerFrames.targettarget:SetParent(PlayerFrames.target)

	if (SUI_FramesAnchor:GetParent() == UIParent) then
		if b == 'player' or b == nil then
			PlayerFrames.player:SetPoint('BOTTOM', UIParent, 'BOTTOM', -220, 150)
		end
		if b == 'pet' or b == nil then
			PlayerFrames.pet:SetPoint('BOTTOMRIGHT', PlayerFrames.player, 'BOTTOMLEFT', -18, 12)
		end
		if b == 'target' or b == nil then
			PlayerFrames.target:SetPoint('LEFT', PlayerFrames.player, 'RIGHT', 100, 0)
		end

		if SUI.DBMod.PlayerFrames.targettarget.style == 'small' then
			if b == 'targettarget' or b == nil then
				PlayerFrames.targettarget:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'BOTTOMRIGHT', 8, -11)
			end
		else
			if b == 'targettarget' or b == nil then
				PlayerFrames.targettarget:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'BOTTOMRIGHT', 19, 15)
			end
		end

		for _, c in pairs(FramesList) do
			PlayerFrames[c]:SetScale(SUI.DB.scale)
		end
	else
		if b == 'player' or b == nil then
			PlayerFrames.player:SetPoint('BOTTOMRIGHT', SUI_FramesAnchor, 'TOP', -72, -3)
		end
		if b == 'pet' or b == nil then
			PlayerFrames.pet:SetPoint('BOTTOMRIGHT', PlayerFrames.player, 'BOTTOMLEFT', -18, 12)
		end
		if b == 'target' or b == nil then
			PlayerFrames.target:SetPoint('BOTTOMLEFT', SUI_FramesAnchor, 'TOP', 54, -3)
		end

		if SUI.DBMod.PlayerFrames.targettarget.style == 'small' then
			if b == 'targettarget' or b == nil then
				PlayerFrames.targettarget:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'BOTTOMRIGHT', -5, -15)
			end
		else
			if b == 'targettarget' or b == nil then
				PlayerFrames.targettarget:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'BOTTOMRIGHT', 7, 12)
			end
		end
	end

	if b == 'focus' or b == nil then
		PlayerFrames.focus:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'TOP', 0, 30)
	end
	if b == 'focustarget' or b == nil then
		PlayerFrames.focustarget:SetPoint('BOTTOMLEFT', PlayerFrames.focus, 'BOTTOMRIGHT', -35, 0)
	end
end

function PlayerFrames:AddMover(frame, framename)
	if frame == nil then
		SUI:Err('PlayerFrames', SUI.DBMod.PlayerFrames.Style .. ' did not spawn ' .. framename)
	else
		frame.mover = CreateFrame('Frame')
		frame.mover:SetSize(20, 20)

		if framename == 'boss' then
			frame.mover:SetPoint('TOPLEFT', PlayerFrames.boss[1], 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', PlayerFrames.boss[MAX_BOSS_FRAMES], 'BOTTOMRIGHT')
		elseif framename == 'arena' then
			frame.mover:SetPoint('TOPLEFT', PlayerFrames.boss[1], 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', PlayerFrames.boss[MAX_BOSS_FRAMES], 'BOTTOMRIGHT')
		else
			frame.mover:SetPoint('TOPLEFT', frame, 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
		end

		frame.mover:EnableMouse(true)
		frame.mover:SetFrameStrata('LOW')

		frame:EnableMouse(enable)
		frame:SetScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' and IsAltKeyDown() then
					frame.mover:Show()
					SUI.DBMod.PlayerFrames[framename].moved = true
					frame:SetMovable(true)
					frame:StartMoving()
				end
			end
		)
		frame:SetScript(
			'OnMouseUp',
			function(self, button)
				frame.mover:Hide()
				frame:StopMovingOrSizing()
				local Anchors = {}
				Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = frame:GetPoint()
				Anchors.relativeTo = 'UIParent'
				for k, v in pairs(Anchors) do
					SUI.DBMod.PlayerFrames[framename].Anchors[k] = v
				end
			end
		)

		frame.mover.bg = frame.mover:CreateTexture(nil, 'BACKGROUND')
		frame.mover.bg:SetAllPoints(frame.mover)
		frame.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		frame.mover.bg:SetVertexColor(1, 1, 1, 0.5)

		frame.mover:SetScript(
			'OnEvent',
			function()
				PlayerFrames.locked = 1
				frame.mover:Hide()
			end
		)
		frame.mover:RegisterEvent('VARIABLES_LOADED')
		frame.mover:RegisterEvent('PLAYER_REGEN_DISABLED')
		frame.mover:Hide()

		--Set Position if moved
		if SUI.DBMod.PlayerFrames[framename].moved then
			frame:SetMovable(true)
			frame:SetUserPlaced(false)
			local Anchors = {}
			for k, v in pairs(SUI.DBMod.PlayerFrames[framename].Anchors) do
				Anchors[k] = v
			end
			frame:ClearAllPoints()
			frame:SetPoint(Anchors.point, UIParent, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		else
			frame:SetMovable(false)
		end
	end
end

function PlayerFrames:BossMoveScripts(frame)
	frame:EnableMouse(enable)
	frame:SetScript(
		'OnMouseDown',
		function(self, button)
			if button == 'LeftButton' and IsAltKeyDown() then
				PlayerFrames.boss[1].mover:Show()
				SUI.DBMod.PlayerFrames.boss.moved = true
				PlayerFrames.boss[1]:SetMovable(true)
				PlayerFrames.boss[1]:StartMoving()
			end
		end
	)
	frame:SetScript(
		'OnMouseUp',
		function(self, button)
			PlayerFrames.boss[1].mover:Hide()
			PlayerFrames.boss[1]:StopMovingOrSizing()
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs =
				PlayerFrames.boss[1]:GetPoint()
			for k, v in pairs(Anchors) do
				SUI.DBMod.PlayerFrames.boss.Anchors[k] = v
			end
		end
	)
end

function PlayerFrames:UpdateArenaFramePosition()
	if (InCombatLockdown()) then
		return
	end
	if SUI.DBMod.PlayerFrames.ArenaFrame.movement.moved then
		SUI_Arena1:SetPoint(
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.point,
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.relativeTo,
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.relativePoint,
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.xOffset,
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.yOffset
		)
	else
		SUI_Arena1:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', -50, -490)
	end
end

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

function PlayerFrames:ArenaMoveScripts(frame)
	frame:EnableMouse(enable)
	frame:SetScript(
		'OnMouseDown',
		function(self, button)
			if button == 'LeftButton' and IsAltKeyDown() then
				PlayerFrames.arena[1].mover:Show()
				DBMod.PlayerFrames.arena.moved = true
				PlayerFrames.arena[1]:SetMovable(true)
				PlayerFrames.arena[1]:StartMoving()
			end
		end
	)
	frame:SetScript(
		'OnMouseUp',
		function(self, button)
			PlayerFrames.arena[1].mover:Hide()
			PlayerFrames.arena[1]:StopMovingOrSizing()
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs =
				PlayerFrames.arena[1]:GetPoint()
			for k, v in pairs(Anchors) do
				DBMod.PlayerFrames.arena.Anchors[k] = v
			end
		end
	)
end

function PlayerFrames:OnEnable()
	PlayerFrames.boss = {}
	PlayerFrames.arena = {}
	if (SUI.DBMod.PlayerFrames.Style == 'Classic') then
		PlayerFrames:BuffOptions()
		PlayerFrames:SUI_PlayerFrames_Classic()
	else
		SUI:GetModule('Style_' .. SUI.DBMod.PlayerFrames.Style):PlayerFrames()
	end

	if SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Movable.PlayerFrames == true then
		for _, b in pairs(FramesList) do
			PlayerFrames:AddMover(PlayerFrames[b], b)
		end
		if SUI.DBMod.PlayerFrames.BossFrame.display then
			PlayerFrames:AddMover(PlayerFrames.boss[1], 'boss')
			for i = 2, MAX_BOSS_FRAMES do
				if PlayerFrames.boss[i] ~= nil then
					PlayerFrames:BossMoveScripts(PlayerFrames.boss[i])
				end
			end
		end
		-- if DBMod.PlayerFrames.ArenaFrame.display then
		PlayerFrames:AddMover(PlayerFrames.arena[1], 'arena')
		for i = 2, 6 do
			if PlayerFrames.arena[i] ~= nil then
				PlayerFrames:ArenaMoveScripts(PlayerFrames.arena[i])
			end
		end
	-- end
	end

	PlayerFrames:SetupStaticOptions()
	PlayerFrames:UpdatePosition()
end

function RaidFrames:OnEnable()
	if SUI.DBMod.RaidFrames.HideBlizzFrames and CompactRaidFrameContainer ~= nil then
		CompactRaidFrameContainer:UnregisterAllEvents()
		CompactRaidFrameContainer:Hide()

		local function hideRaid()
			CompactRaidFrameContainer:UnregisterAllEvents()
			if (InCombatLockdown()) then
				return
			end
			local shown = CompactRaidFrameManager_GetSetting('IsShown')
			if (shown and shown ~= '0') then
				CompactRaidFrameManager_SetSetting('IsShown', '0')
			end
		end

		hooksecurefunc(
			'CompactRaidFrameManager_UpdateShown',
			function()
				hideRaid()
			end
		)

		hideRaid()
		CompactRaidFrameContainer:HookScript('OnShow', hideRaid)
	end

	if (SUI.DBMod.RaidFrames.Style == 'theme') and (SUI.DBMod.Artwork.Style ~= 'Classic') then
		SUI.RaidFrames = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):RaidFrames()
	elseif (SUI.DBMod.RaidFrames.Style == 'Classic') or (SUI.DBMod.Artwork.Style == 'Classic') then
		SUI.RaidFrames = RaidFrames:Classic()
	elseif (SUI.DBMod.RaidFrames.Style == 'plain') then
		SUI.RaidFrames = RaidFrames:Plain()
	else
		SUI.RaidFrames = SUI:GetModule('Style_' .. SUI.DBMod.RaidFrames.Style):RaidFrames()
	end

	SUI.RaidFrames.mover = CreateFrame('Frame')
	SUI.RaidFrames.mover:SetSize(20, 20)
	SUI.RaidFrames.mover:SetPoint('TOPLEFT', SUI.RaidFrames, 'TOPLEFT')
	SUI.RaidFrames.mover:SetPoint('BOTTOMRIGHT', SUI.RaidFrames, 'BOTTOMRIGHT')
	SUI.RaidFrames.mover:EnableMouse(true)
	SUI.RaidFrames.mover:SetFrameStrata('LOW')

	SUI.RaidFrames:EnableMouse(enable)
	SUI.RaidFrames:SetScript(
		'OnMouseDown',
		function(self, button)
			if button == 'LeftButton' and IsAltKeyDown() then
				SUI.RaidFrames.mover:Show()
				SUI.DBMod.RaidFrames.moved = true
				SUI.RaidFrames:SetMovable(true)
				SUI.RaidFrames:StartMoving()
			end
		end
	)
	SUI.RaidFrames:SetScript(
		'OnMouseUp',
		function(self, button)
			SUI.RaidFrames.mover:Hide()
			SUI.RaidFrames:StopMovingOrSizing()
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = SUI.RaidFrames:GetPoint()
			for k, v in pairs(Anchors) do
				SUI.DBMod.RaidFrames.Anchors[k] = v
			end
		end
	)

	SUI.RaidFrames.mover.bg = SUI.RaidFrames.mover:CreateTexture(nil, 'BACKGROUND')
	SUI.RaidFrames.mover.bg:SetAllPoints(SUI.RaidFrames.mover)
	SUI.RaidFrames.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
	SUI.RaidFrames.mover.bg:SetVertexColor(1, 1, 1, 0.5)

	SUI.RaidFrames.mover:SetScript(
		'OnEvent',
		function()
			RaidFrames.locked = 1
			SUI.RaidFrames.mover:Hide()
		end
	)
	SUI.RaidFrames.mover:RegisterEvent('VARIABLES_LOADED')
	SUI.RaidFrames.mover:RegisterEvent('PLAYER_REGEN_DISABLED')
	SUI.RaidFrames.mover:Hide()

	local raidWatch = CreateFrame('Frame')
	raidWatch:RegisterEvent('GROUP_ROSTER_UPDATE')
	raidWatch:RegisterEvent('PLAYER_ENTERING_WORLD')

	raidWatch:SetScript(
		'OnEvent',
		function(self, event, ...)
			if (InCombatLockdown()) then
				self:RegisterEvent('PLAYER_REGEN_ENABLED')
			else
				self:UnregisterEvent('PLAYER_REGEN_ENABLED')
				RaidFrames:UpdateRaid(event)
			end
		end
	)
end

function PlayerFrames:BuffOptions()
	SUI.opt.args['PlayerFrames'].args['auras'] = {
		name = 'Buffs & Debuffs',
		type = 'group',
		order = 3,
		desc = 'Buff & Debuff display settings',
		args = {}
	}
	local Units = {[1] = 'player', [2] = 'pet', [3] = 'target', [4] = 'targettarget', [5] = 'focus', [6] = 'focustarget'}
	local values = {['bars'] = L['Bars'], ['icons'] = L['Icons'], ['both'] = L['Both'], ['disabled'] = L['Disabled']}

	for k, unit in pairs(Units) do
		SUI.opt.args['PlayerFrames'].args['auras'].args[unit] = {
			name = unit,
			type = 'group',
			order = k,
			disabled = true,
			args = {
				Notice = {type = 'description', order = .5, fontSize = 'medium', name = L['possiblereloadneeded']},
				Buffs = {
					name = 'Buffs',
					type = 'group',
					inline = true,
					order = 1,
					args = {
						Display = {
							name = L['Display mode'],
							type = 'select',
							order = 15,
							values = values,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Mode
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Mode = val
								SUI:reloadui()
							end
						},
						Number = {
							name = L['Number to show'],
							type = 'range',
							order = 20,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Number
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Number = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						},
						size = {
							name = L['Size'],
							type = 'range',
							order = 30,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.size
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.size = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						},
						spacing = {
							name = L['Spacing'],
							type = 'range',
							order = 40,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.spacing
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.spacing = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						},
						showType = {
							name = L['Show type'],
							type = 'toggle',
							order = 50,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.showType
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.showType = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						},
						onlyShowPlayer = {
							name = L['Only show players'],
							type = 'toggle',
							order = 60,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.onlyShowPlayer
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.onlyShowPlayer = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						}
					}
				},
				Debuffs = {
					name = 'Debuffs',
					type = 'group',
					inline = true,
					order = 2,
					args = {
						Display = {
							name = L['Display mode'],
							type = 'select',
							order = 15,
							values = values,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Mode
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Mode = val
								SUI:reloadui()
							end
						},
						Number = {
							name = L['Number to show'],
							type = 'range',
							order = 20,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Number
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Number = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						},
						size = {
							name = L['Size'],
							type = 'range',
							order = 30,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.size
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.size = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						},
						spacing = {
							name = L['Spacing'],
							type = 'range',
							order = 40,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.spacing
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.spacing = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						},
						showType = {
							name = L['Show type'],
							type = 'toggle',
							order = 50,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.showType
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.showType = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						},
						onlyShowPlayer = {
							name = L['Only show players'],
							type = 'toggle',
							order = 60,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.onlyShowPlayer
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.onlyShowPlayer = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						}
					}
				}
			}
		}
	end
end

function RaidFrames:UpdateRaidPosition()
	RaidFrames.offset = SUI.DB.yoffset
	if SUI.DBMod.RaidFrames.moved then
		SUI.RaidFrames:SetMovable(true)
		SUI.RaidFrames:SetUserPlaced(false)
	else
		SUI.RaidFrames:SetMovable(false)
	end
	if not SUI.DBMod.RaidFrames.moved then
		SUI.RaidFrames:ClearAllPoints()
		if SUI:GetModule('PartyFrames', true) then
			SUI.RaidFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -140 - (RaidFrames.offset))
		else
			SUI.RaidFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -20 - (RaidFrames.offset))
		end
	else
		local Anchors = {}
		for k, v in pairs(SUI.DBMod.RaidFrames.Anchors) do
			Anchors[k] = v
		end
		SUI.RaidFrames:ClearAllPoints()
		SUI.RaidFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
end

function RaidFrames:UpdateRaid(event, ...)
	if SUI.RaidFrames == nil then
		return
	end

	if SUI.DBMod.RaidFrames.showRaid and IsInRaid() then
		SUI.RaidFrames:Show()
	elseif SUI.DBMod.RaidFrames.showParty and inParty then
		--Something keeps hiding it on us when solo so lets force it. Messy but oh well.
		SUI.RaidFrames.HideTmp = SUI.RaidFrames.Hide
		SUI.RaidFrames.Hide = SUI.RaidFrames.Show
		--Now Display
		SUI.RaidFrames:Show()
	elseif SUI.DBMod.RaidFrames.showSolo and not inParty and not IsInRaid() then
		--Something keeps hiding it on us when solo so lets force it. Messy but oh well.
		SUI.RaidFrames.HideTmp = SUI.RaidFrames.Hide
		SUI.RaidFrames.Hide = SUI.RaidFrames.Show
		--Now Display
		SUI.RaidFrames:Show()
	elseif SUI.RaidFrames:IsShown() then
		--Swap back hide function if needed
		if SUI.RaidFrames.HideTmp then
			SUI.RaidFrames.Hide = SUI.RaidFrames.HideTmp
		end

	-- SUI.RaidFrames:Hide()
	end

	RaidFrames:UpdateRaidPosition()

	SUI.RaidFrames:SetAttribute('showRaid', SUI.DBMod.RaidFrames.showRaid)
	SUI.RaidFrames:SetAttribute('showParty', SUI.DBMod.RaidFrames.showParty)
	SUI.RaidFrames:SetAttribute('showPlayer', SUI.DBMod.RaidFrames.showPlayer)
	SUI.RaidFrames:SetAttribute('showSolo', SUI.DBMod.RaidFrames.showSolo)

	SUI.RaidFrames:SetAttribute('groupBy', SUI.DBMod.RaidFrames.mode)
	SUI.RaidFrames:SetAttribute('maxColumns', SUI.DBMod.RaidFrames.maxColumns)
	SUI.RaidFrames:SetAttribute('unitsPerColumn', SUI.DBMod.RaidFrames.unitsPerColumn)
	SUI.RaidFrames:SetAttribute('columnSpacing', SUI.DBMod.RaidFrames.columnSpacing)

	SUI.RaidFrames:SetScale(SUI.DBMod.RaidFrames.scale)
end

function PartyFrames:UpdatePartyPosition()
	PartyFrames.offset = SUI.DB.yoffset
	if SUI.DBMod.PartyFrames.moved then
		SUI.PartyFrames:SetMovable(true)
		SUI.PartyFrames:SetUserPlaced(false)
	else
		SUI.PartyFrames:SetMovable(false)
	end
	-- User Moved the PartyFrame, so we shouldn't be moving it
	if not SUI.DBMod.PartyFrames.moved then
		SUI.PartyFrames:ClearAllPoints()
		-- SpartanUI_PlayerFrames are loaded
		if SUI:GetModule('PlayerFrames', true) then
			-- SpartanUI_PlayerFrames isn't loaded
			SUI.PartyFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -20 - (SUI.DB.BuffSettings.offset))
		else
			SUI.PartyFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -140 - (SUI.DB.BuffSettings.offset))
		end
	else
		local Anchors = {}
		for k, v in pairs(SUI.DBMod.PartyFrames.Anchors) do
			Anchors[k] = v
		end
		SUI.PartyFrames:ClearAllPoints()
		SUI.PartyFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
end

function PartyFrames:OnEnable()
	local pf
	if (SUI.DBMod.PartyFrames.Style == 'theme') and (SUI.DBMod.Artwork.Style ~= 'Classic') then
		pf = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):PartyFrames()
	elseif (SUI.DBMod.PartyFrames.Style == 'Classic') then
		pf = PartyFrames:Classic()
	elseif (SUI.DBMod.PartyFrames.Style == 'plain') then
		pf = PartyFrames:Plain()
	else
		pf = SUI:GetModule('Style_' .. SUI.DBMod.PartyFrames.Style):PartyFrames()
	end

	if SUI.DB.Styles[SUI.DBMod.PartyFrames.Style].Movable.PartyFrames then
		pf.mover = CreateFrame('Frame')
		pf.mover:SetPoint('TOPLEFT', pf, 'TOPLEFT')
		pf.mover:SetPoint('BOTTOMRIGHT', pf, 'BOTTOMRIGHT')
		pf.mover:EnableMouse(true)
		pf.mover:SetFrameStrata('LOW')

		pf.mover.bg = pf.mover:CreateTexture(nil, 'BACKGROUND')
		pf.mover.bg:SetAllPoints(pf.mover)
		pf.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		pf.mover.bg:SetVertexColor(1, 1, 1, 0.5)

		pf.mover:SetScript(
			'OnEvent',
			function(self, event, ...)
				PartyFrames.locked = 1
				self:Hide()
			end
		)
		pf.mover:RegisterEvent('VARIABLES_LOADED')
		pf.mover:RegisterEvent('PLAYER_REGEN_DISABLED')
		pf.mover:Hide()
	end

	if SpartanUI then
		pf:SetParent('SpartanUI')
	else
		pf:SetParent(UIParent)
	end

	PartyMemberBackground.Show = function()
		return
	end
	PartyMemberBackground:Hide()

	SUI.PartyFrames = pf

	function PartyFrames:UpdateParty(event, ...)
		if InCombatLockdown() then
			return
		end
		local inParty = IsInGroup() -- ( numGroupMembers () > 0 )

		SUI.PartyFrames:SetAttribute('showParty', SUI.DBMod.PartyFrames.showParty)
		SUI.PartyFrames:SetAttribute('showPlayer', SUI.DBMod.PartyFrames.showPlayer)
		SUI.PartyFrames:SetAttribute('showSolo', SUI.DBMod.PartyFrames.showSolo)

		if SUI.DBMod.PartyFrames.showParty or SUI.DBMod.PartyFrames.showSolo then
			if IsInRaid() then
				if SUI.DBMod.PartyFrames.showPartyInRaid then
					SUI.PartyFrames:Show()
				else
					SUI.PartyFrames:Hide()
				end
			elseif inParty then
				SUI.PartyFrames:Show()
			elseif SUI.DBMod.PartyFrames.showSolo then
				SUI.PartyFrames:Show()
			elseif SUI.PartyFrames:IsShown() then
				SUI.PartyFrames:Hide()
			end
		else
			SUI.PartyFrames:Hide()
		end

		PartyFrames:UpdatePartyPosition()
		SUI.PartyFrames:SetScale(SUI.DBMod.PartyFrames.scale)
	end

	local partyWatch = CreateFrame('Frame')
	partyWatch:RegisterEvent('PLAYER_LOGIN')
	partyWatch:RegisterEvent('PLAYER_ENTERING_WORLD')
	partyWatch:RegisterEvent('RAID_ROSTER_UPDATE')
	partyWatch:RegisterEvent('PARTY_LEADER_CHANGED')
	--partyWatch:RegisterEvent('PARTY_MEMBERS_CHANGED');
	--partyWatch:RegisterEvent('PARTY_CONVERTED_TO_RAID');
	partyWatch:RegisterEvent('CVAR_UPDATE')
	partyWatch:RegisterEvent('PLAYER_REGEN_ENABLED')
	partyWatch:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	--partyWatch:RegisterEvent('FORCE_UPDATE');

	partyWatch:SetScript(
		'OnEvent',
		function(self, event, ...)
			if InCombatLockdown() then
				return
			end
			PartyFrames:UpdateParty(event)
		end
	)
end
