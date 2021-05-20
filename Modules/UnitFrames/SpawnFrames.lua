local _G, SUI = _G, SUI
local module = SUI:GetModule('Component_UnitFrames')
local PartyFrames = {}
local PlayerFrames = {}
local RaidFrames = {}
----------------------------------------------------------------------------------------------------
local Smoothv2 = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'
local FramesList = {
	'pet',
	'target',
	'targettarget',
	'focus',
	'focustarget',
	'player'
}
local elementList = {
	'Portrait',
	'Health',
	'HealthPrediction',
	'Power',
	'Castbar',
	'Name',
	'LeaderIndicator',
	'DispelHighlight',
	'RestingIndicator',
	'GroupRoleIndicator',
	'CombatIndicator',
	'RaidTargetIndicator',
	'SUI_ClassIcon',
	'ReadyCheckIndicator',
	'PvPIndicator',
	'RareElite',
	'StatusText',
	'Runes',
	'Stagger',
	'Totems',
	'AssistantIndicator',
	'RaidRoleIndicator',
	'ResurrectIndicator',
	'SummonIndicator',
	'QuestMobIndicator',
	'Range',
	'PhaseIndicator',
	'ThreatIndicator',
	'SUI_RaidGroup'
}
local NoBulkUpdate = {
	'Range',
	'HealthPrediction',
	'Health',
	'Power',
	'Castbar'
}
local IndicatorList = {
	'LeaderIndicator',
	'RestingIndicator',
	'GroupRoleIndicator',
	'CombatIndicator',
	'RaidTargetIndicator',
	'SUI_ClassIcon',
	'ReadyCheckIndicator',
	'PvPIndicator',
	'AssistantIndicator',
	'RaidRoleIndicator',
	'ResurrectIndicator',
	'SummonIndicator',
	'QuestMobIndicator',
	'PhaseIndicator',
	'ThreatIndicator',
	'SUI_RaidGroup',
	'PetHappiness'
}
local GroupFrames = {'raid', 'party', 'boss', 'arena'}
if SUI.IsClassic or SUI.IsBCC then
	GroupFrames = {'raid', 'party'}
end

if SUI.IsClassic then
	FramesList = {
		[1] = 'pet',
		[2] = 'target',
		[3] = 'targettarget',
		[4] = 'player'
	}
end

local function InverseAnchor(anchor)
	if anchor == 'TOPLEFT' then
		return 'BOTTOMLEFT'
	elseif anchor == 'TOPRIGHT' then
		return 'BOTTOMRIGHT'
	elseif anchor == 'BOTTOMLEFT' then
		return 'TOPLEFT'
	elseif anchor == 'BOTTOMRIGHT' then
		return 'TOPRIGHT'
	elseif anchor == 'BOTTOM' then
		return 'TOP'
	elseif anchor == 'TOP' then
		return 'BOTTOM'
	elseif anchor == 'LEFT' then
		return 'RIGHT'
	elseif anchor == 'RIGHT' then
		return 'LEFT'
	end
end

local function customFilter(
	element,
	unit,
	button,
	name,
	texture,
	count,
	debuffType,
	duration,
	expiration,
	caster,
	isStealable,
	nameplateShowSelf,
	spellID,
	canApply,
	isBossDebuff,
	casterIsPlayer,
	nameplateShowAll,
	timeMod,
	effect1,
	effect2,
	effect3)
	-- check for onlyShowPlayer rules
	if (element.onlyShowPlayer and button.isPlayer) or (not element.onlyShowPlayer and name) then
		return true
	end
	-- Check boss rules
	if isBossDebuff and element.ShowBossDebuffs then
		return true
	end
	if isStealable and element.ShowStealable then
		return true
	end

	-- We did not find a display rule, so hide it
	return false
end

local function UpdateAura(self, elapsed)
	if (self.expiration) then
		self.expiration = math.max(self.expiration - elapsed, 0)

		if (self.expiration > 0 and self.expiration < 60) then
			self.Duration:SetFormattedText('%d', self.expiration)
		else
			self.Duration:SetText()
		end
	end
end

local function PostCreateAura(element, button)
	if button.SetBackdrop then
		button:SetBackdrop(nil)
		button:SetBackdropColor(0, 0, 0)
	end
	button.cd:SetReverse(true)
	button.cd:SetHideCountdownNumbers(true)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
	-- button:SetScript('OnEnter', OnAuraEnter)

	-- We create a parent for aura strings so that they appear over the cooldown widget
	local StringParent = CreateFrame('Frame', nil, button)
	StringParent:SetFrameLevel(20)

	button.count:SetParent(StringParent)
	button.count:ClearAllPoints()
	button.count:SetPoint('BOTTOMRIGHT', button, 2, 1)
	button.count:SetFont(SUI:GetFontFace('UnitFrames'), select(2, button.count:GetFont()) - 3)

	local Duration = StringParent:CreateFontString(nil, 'OVERLAY')
	Duration:SetFont(SUI:GetFontFace('UnitFrames'), 11)
	Duration:SetPoint('TOPLEFT', button, 0, -1)
	button.Duration = Duration

	button:HookScript('OnUpdate', UpdateAura)
end

local function PostUpdateAura(element, unit, button, index)
	local _, _, _, _, duration, expiration, owner, canStealOrPurge = UnitAura(unit, index, button.filter)
	if (duration and duration > 0) then
		button.expiration = expiration - GetTime()
	else
		button.expiration = math.huge
	end

	if button.SetBackdrop then
		if (unit == 'target' and canStealOrPurge) then
			button:SetBackdropColor(0, 1 / 2, 1 / 2)
		elseif (owner ~= 'player') then
			button:SetBackdropColor(0, 0, 0)
		end
	end
end

local function CalculateHeight(frameName)
	local elements = module.CurrentSettings[frameName].elements
	local FrameHeight = 0
	if elements.Castbar.enabled then
		FrameHeight = FrameHeight + elements.Castbar.height
	end
	if elements.Health.enabled then
		FrameHeight = FrameHeight + elements.Health.height
	end
	if elements.Power.enabled then
		FrameHeight = FrameHeight + elements.Power.height
	end
	return FrameHeight
end

local function GetBasicUnitName(unit)
	if string.match(unit, 'raid') then
		return 'raid'
	elseif string.match(unit, 'party') then
		return 'party'
	elseif string.match(unit, 'boss') then
		return 'boss'
	elseif string.match(unit, 'arena') then
		return 'arena'
	end
	return unit
end

local function CreateUnitFrame(self, unit)
	if (unit ~= 'raid' and unit ~= 'party') then
		if (SUI_FramesAnchor:GetParent() == UIParent) then
			self:SetParent(UIParent)
		else
			self:SetParent(SUI_FramesAnchor)
		end
	end
	if string.match(unit, 'boss') then
		unit = 'boss'
	elseif string.match(unit, 'arena') then
		unit = 'arena'
	end
	self.unitOnCreate = unit

	local function UpdateAll()
		local auras = module.CurrentSettings[unit].auras
		local elements = module.CurrentSettings[unit].elements
		-- Check that its a frame
		-- Loop all elements and update their status
		for _, element in ipairs(elementList) do
			if self[element] and element ~= nil then
				-- oUF Update (event/updater state)
				if elements[element].enabled then
					self:EnableElement(element)
				else
					self:DisableElement(element)
				end
				--Background
				if self[element].bg then
					if elements[element].bg.enabled then
						self[element].bg:Show()
						if elements[element].bg.color then
							self[element].bg:SetVertexColor(unpack(elements[element].bg.color))
						end
					else
						self[element].bg:Hide()
					end
				end
				-- SUI Update (size, position, etc)
				self:ElementUpdate(element)
			end
		end

		--Update the screen
		if elements.Power.PowerPrediction then
			self:EnableElement('PowerPrediction')
		else
			self:DisableElement('PowerPrediction')
		end

		--Update Health items
		self.Health.colorDisconnected = elements.Health.colorDisconnected
		self.Health.colorTapping = elements.Health.colorTapping
		self.Health.colorReaction = elements.Health.colorReaction
		self.Health.colorSmooth = elements.Health.colorSmooth
		self.Health.colorClass = elements.Health.colorClass

		do -- Castbar updates
			if SUI.IsRetail then
				-- latency
				if elements.Castbar.latency then
					self.Castbar.Shield:Show()
				else
					self.Castbar.Shield:Hide()
				end

				-- spell name
				if elements.Castbar.text['1'].enabled then
					self.Castbar.Text:Show()
				else
					self.Castbar.Text:Hide()
				end
				-- spell timer
				if elements.Castbar.text['2'].enabled then
					self.Castbar.Time:Show()
				else
					self.Castbar.Time:Hide()
				end
			end

			-- Spell icon
			if elements.Castbar.Icon.enabled then
				self.Castbar.Icon:Show()
			else
				self.Castbar.Icon:Hide()
			end
			self.Castbar.Icon:ClearAllPoints()
			self.Castbar.Icon:SetPoint(
				elements.Castbar.Icon.position.anchor,
				self.Castbar,
				elements.Castbar.Icon.position.anchor,
				elements.Castbar.Icon.position.x,
				elements.Castbar.Icon.position.y
			)
		end

		-- Update Buffs
		if (auras.Buffs.enabled) then
			self.Buffs:Show()
		else
			self.Buffs:Hide()
		end
		if (auras.Debuffs.enabled) then
			self.Debuffs:Show()
		else
			self.Debuffs:Hide()
		end

		-- Tell everything to update to get current data
		self:UpdateSize()
		self:UpdateAuras()
		self:UpdateAllElements('OnUpdate')
		self:UpdateTags()
	end

	local function ElementUpdate(self, elementName)
		if not self[elementName] then
			return
		end
		local data = module.CurrentSettings[unit].elements[elementName]
		local element = self[elementName]

		if elementName == 'SpartanArt' then
			self.SpartanArt:ForceUpdate('OnUpdate')
			return
		end

		if SUI:isInTable(NoBulkUpdate, elementName) then
			return
		end

		if not data then
			SUI:Error('NO SETTINGS FOR "' .. unit .. '" element: ' .. elementName)
			return
		end

		-- Setup the Alpha scape and position
		element:SetAlpha(data.alpha)
		element:SetScale(data.scale)

		-- Positioning
		element:ClearAllPoints()
		if data.points ~= false and data.points == true then
			element:SetAllPoints(self)
		elseif data.points ~= false and data.points ~= true then
			for _, key in pairs(data.points) do
				element:SetPoint(key.anchor, self, key.anchor, key.x, key.y)
			end
		elseif data.position.anchor then
			element:SetPoint(data.position.anchor, self, data.position.anchor, data.position.x, data.position.y)
		end

		--Size it if we have a size change function for the element
		if element.SizeChange then
			element:SizeChange()
		elseif element.Sizeable then
			element:SetSize(data.size, data.size)
		end

		--PVPIndicator
		if elementName == 'PvPIndicator' then
			for k, v in pairs({['Badge'] = 'BadgeBackup', ['Shadow'] = 'ShadowBackup'}) do
				-- If badge is true but does not exsist create from backup
				if data[k] and self.PvPIndicator[k] == nil then
					self.PvPIndicator[k] = self.PvPIndicator[v]
				elseif not data[k] and self.PvPIndicator[k] then
					-- If badge is false but exsists remove it
					self.PvPIndicator[k]:Hide()
					self.PvPIndicator[k] = nil
				end
			end
		end

		--Portrait
		if elementName == 'Portrait' then
			self.Portrait3D:Hide()
			self.Portrait2D:Hide()
			if data.type == '3D' then
				self.Portrait = self.Portrait3D
				self.Portrait3D:Show()
				if (self.Portrait:IsObjectType('PlayerModel')) then
					self.Portrait:SetAlpha(data.alpha)

					local rotation = data.rotation

					if self.Portrait:GetFacing() ~= (rotation / 57.29573671972358) then
						self.Portrait:SetFacing(rotation / 57.29573671972358) -- because 1 degree is equal 0,0174533 radian. Credit: Hndrxuprt
					end

					self.Portrait:SetCamDistanceScale(data.camDistanceScale)
					self.Portrait:SetPosition(data.xOffset, data.xOffset, data.yOffset)

					--Refresh model to fix incorrect display issues
					self.Portrait:ClearModel()
					self.Portrait:SetUnit(unit)
				end
			else
				self.Portrait = self.Portrait2D
				self.Portrait2D:Show()
			end
			if data.position == 'left' then
				self.Portrait3D:SetPoint('RIGHT', self, 'LEFT')
				self.Portrait2D:SetPoint('RIGHT', self, 'LEFT')
			else
				self.Portrait3D:SetPoint('LEFT', self, 'RIGHT')
				self.Portrait2D:SetPoint('LEFT', self, 'RIGHT')
			end
			self:UpdateAllElements('OnUpdate')
		end

		--Range
		if elementName == 'Range' then
			self.Range = {
				insideAlpha = elements.Range.insideAlpha,
				outsideAlpha = elements.Range.outsideAlpha
			}
		end
	end

	-- Build a function that updates the size of the frame and sizes of elements
	local function UpdateSize()
		local elements = module.CurrentSettings[unit].elements
		-- Find the Height of the frame
		local FrameHeight = CalculateHeight(unit)

		-- General
		if not InCombatLockdown() then
			if self.scale then
				self:scale(module.CurrentSettings[unit].scale, true)
			else
				self:SetScale(module.CurrentSettings[unit].scale)
			end
			self:SetSize(module.CurrentSettings[unit].width, FrameHeight)
		end

		if self.Portrait3D then
			self.Portrait3D:SetSize(FrameHeight, FrameHeight)
		end

		if self.Portrait2D then
			self.Portrait2D:SetSize(FrameHeight, FrameHeight)
		end

		-- Status bars
		if self.Castbar then
			self.Castbar:SetHeight(elements.Castbar.height)
			self.Castbar.Icon:SetSize(elements.Castbar.Icon.size, elements.Castbar.Icon.size)
		end

		if self.Health then
			local healthOffset = elements.Health.offset
			if elements.Castbar.enabled then
				healthOffset = (elements.Castbar.height * -1)
			end

			self.Health:ClearAllPoints()
			self.Health:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, healthOffset)
			self.Health:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, healthOffset)
			self.Health:SetHeight(elements.Health.height)
		end

		if self.Power then
			local powerOffset = elements.Power.offset
			if elements.Castbar.enabled then
				powerOffset = powerOffset + elements.Castbar.height
			end
			if elements.Health.enabled then
				powerOffset = powerOffset + elements.Health.height
			end
			if elements.Castbar.enabled or elements.Health.enabled then
				powerOffset = powerOffset * -1
			end

			self.Power:ClearAllPoints()
			self.Power:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, powerOffset)
			self.Power:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, powerOffset)
			self.Power:SetHeight(elements.Power.height)
		end

		if self.AdditionalPower then
			self.AdditionalPower:SetHeight(elements.AdditionalPower.height)
		end

		-- Inidcators
		if self.Name then
			self.Name:SetSize(self:GetWidth(), 12)
		end

		for _, key in ipairs(IndicatorList) do
			if self[key] then
				self[key]:SetSize(elements[key].size, elements[key].size)
			end
		end
	end

	local function UpdateAuras(self)
		local db = module.CurrentSettings[unit].auras

		local Buffs = self.Buffs
		Buffs.size = db.Buffs.size
		Buffs.initialAnchor = db.Buffs.initialAnchor
		Buffs['growth-x'] = db.Buffs.growthx
		Buffs['growth-y'] = db.Buffs.growthy
		Buffs.spacing = db.Buffs.spacing
		Buffs.showType = db.Buffs.showType
		Buffs.num = db.Buffs.number
		Buffs.onlyShowPlayer = db.Buffs.onlyShowPlayer
		Buffs.PostCreateIcon = PostCreateAura
		Buffs.PostUpdateIcon = PostUpdateAura
		Buffs:SetPoint(
			InverseAnchor(db.Buffs.position.anchor),
			self,
			db.Buffs.position.anchor,
			db.Buffs.position.x,
			db.Buffs.position.y
		)
		local w = (db.Buffs.number / db.Buffs.rows)
		if w < 1.5 then
			w = 1.5
		end
		Buffs:SetSize((db.Buffs.size + db.Buffs.spacing) * w, (db.Buffs.spacing + db.Buffs.size) * db.Buffs.rows)

		--Debuff Icons
		local Debuffs = self.Debuffs
		Debuffs.size = db.Debuffs.size
		Debuffs.initialAnchor = db.Debuffs.initialAnchor
		Debuffs['growth-x'] = db.Debuffs.growthx
		Debuffs['growth-y'] = db.Debuffs.growthy
		Debuffs.spacing = db.Debuffs.spacing
		Debuffs.showType = db.Debuffs.showType
		Debuffs.num = db.Debuffs.number
		Debuffs.onlyShowPlayer = db.Debuffs.onlyShowPlayer
		Debuffs.PostCreateIcon = PostCreateAura
		Debuffs.PostUpdateIcon = PostUpdateAura
		Debuffs:SetPoint(
			InverseAnchor(db.Debuffs.position.anchor),
			self,
			db.Debuffs.position.anchor,
			db.Debuffs.position.x,
			db.Debuffs.position.y
		)
		w = (db.Debuffs.number / db.Debuffs.rows)
		if w < 1.5 then
			w = 1.5
		end
		Debuffs:SetSize((db.Debuffs.size + db.Debuffs.spacing) * w, (db.Debuffs.spacing + db.Debuffs.size) * db.Debuffs.rows)
		self:UpdateAllElements('ForceUpdate')
		-- self.Buffs:PostUpdate(unit, 'Buffs')
		-- self.Debuffs:PostUpdate(unit, 'Buffs')
	end

	self.UpdateAll = UpdateAll
	self.UpdateSize = UpdateSize
	self.ElementUpdate = ElementUpdate
	self.UpdateAuras = UpdateAuras

	self.UpdateSize()

	local elements = module.CurrentSettings[unit].elements

	do -- General setup
		local ArtPositions = {'top', 'bg', 'bottom', 'full'}
		local unitName = GetBasicUnitName(unit)

		local SpartanArt = CreateFrame('Frame', nil, self)
		SpartanArt:SetFrameStrata('BACKGROUND')
		SpartanArt:SetFrameLevel(2)
		SpartanArt:SetAllPoints()
		SpartanArt.PostUpdate = function(self, unit)
			for _, pos in ipairs(ArtPositions) do
				local ArtSettings = module.CurrentSettings[unitName].artwork[pos]
				if
					ArtSettings and ArtSettings.enabled and ArtSettings.graphic ~= '' and
						module.Artwork[ArtSettings.graphic][pos].UnitFrameCallback
				 then
					module.Artwork[ArtSettings.graphic][pos].UnitFrameCallback(self:GetParent(), unit)
				end
			end
		end
		SpartanArt.PreUpdate = function(self, unit)
			if not unit or unit == 'vehicle' then
				return
			end
			-- Party frame shows 'player' instead of party 1-5
			if not module.CurrentSettings[unitName] then
				SUI:Error(unitName .. ' - NO SETTINGS FOUND')
				return
			end

			self.ArtSettings = module.CurrentSettings[unitName].artwork
			for _, pos in ipairs(ArtPositions) do
				local ArtSettings = self.ArtSettings[pos]
				if ArtSettings and ArtSettings.enabled and ArtSettings.graphic ~= '' and module.Artwork[ArtSettings.graphic] then
					self[pos].ArtData = module.Artwork[ArtSettings.graphic][pos]
					--Grab the settings for the frame specifically if defined (classic skin)
					if self[pos].ArtData.perUnit and self[pos].ArtData[unitName] then
						self[pos].ArtData = self[pos].ArtData[unitName]
					end
				end
			end
		end
		SpartanArt.top = SpartanArt:CreateTexture(nil, 'BORDER')
		SpartanArt.bg = SpartanArt:CreateTexture(nil, 'BACKGROUND')
		SpartanArt.bottom = SpartanArt:CreateTexture(nil, 'BORDER')
		SpartanArt.full = SpartanArt:CreateTexture(nil, 'BACKGROUND')

		self.SpartanArt = SpartanArt

		-- 3D Portrait
		local Portrait3D = CreateFrame('PlayerModel', nil, self)
		Portrait3D:SetSize(self:GetHeight(), self:GetHeight())
		Portrait3D:SetScale(elements.Portrait.Scale)
		Portrait3D:SetFrameStrata('BACKGROUND')
		Portrait3D:SetFrameLevel(2)
		Portrait3D.PostUpdate = function(unit, event, shouldUpdate)
			if (self:IsObjectType('PlayerModel')) then
				self:SetAlpha(elements.Portrait.alpha)

				local rotation = elements.Portrait.rotation

				if self:GetFacing() ~= (rotation / 57.29573671972358) then
					self:SetFacing(rotation / 57.29573671972358) -- because 1 degree is equal 0,0174533 radian. Credit: Hndrxuprt
				end

				self:SetCamDistanceScale(elements.Portrait.camDistanceScale)
				self:SetPosition(elements.Portrait.xOffset, elements.Portrait.xOffset, elements.Portrait.yOffset)

				--Refresh model to fix incorrect display issues
				self:ClearModel()
				self:SetUnit(unit)
			end
		end
		self.Portrait3D = Portrait3D

		-- 2D Portrait
		local Portrait2D = self:CreateTexture(nil, 'OVERLAY')
		Portrait2D:SetSize(self:GetHeight(), self:GetHeight())
		Portrait2D:SetScale(elements.Portrait.Scale)
		self.Portrait2D = Portrait2D

		self.Portrait = Portrait3D
		ElementUpdate(self, 'Portrait')

		-- 	local Threat = self:CreateTexture(nil, 'OVERLAY')
		-- 	Threat:SetSize(25, 25)
		-- 	Threat:SetPoint('CENTER', self, 'RIGHT')
		-- 	self.ThreatIndicator = Threat
	end
	do -- setup auras
		-- Setup icons if needed
		local iconFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
			if caster == 'player' and (duration == 0 or duration > 60) then --Do not show DOTS & HOTS
				return true
			elseif caster ~= 'player' then
				return true
			end
		end

		--Buff Icons
		local Buffs = CreateFrame('Frame', unit .. 'Buffs', self)
		-- Buffs.PostUpdate = PostUpdateAura
		-- Buffs.CustomFilter = customFilter
		self.Buffs = Buffs

		--Debuff Icons
		local Debuffs = CreateFrame('Frame', unit .. 'Debuffs', self)
		-- Debuffs.PostUpdate = PostUpdateAura
		-- Debuffs.CustomFilter = customFilter
		self.Debuffs = Debuffs
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:Hide()
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(2)
			cast:SetStatusBarTexture(Smoothv2)
			cast:SetHeight(elements.Castbar.height)

			local castOffset = (elements.Castbar.offset * -1)
			cast:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, castOffset)
			cast:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, castOffset)

			local Background = cast:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(cast)
			Background:SetTexture(Smoothv2)
			Background:SetVertexColor(1, 1, 1, .2)
			cast.bg = Background

			-- Add spell text
			local Text = cast:CreateFontString()
			SUI:FormatFont(Text, elements.Castbar.text['1'].size, 'UnitFrames')
			Text:SetPoint(
				elements.Castbar.text['1'].position.anchor,
				cast,
				elements.Castbar.text['1'].position.anchor,
				elements.Castbar.text['1'].position.x,
				elements.Castbar.text['1'].position.y
			)

			-- Add Shield
			local Shield = cast:CreateTexture(nil, 'OVERLAY')
			Shield:SetSize(20, 20)
			Shield:SetPoint('CENTER', cast, 'RIGHT')
			Shield:SetTexture([[Interface\CastingBar\UI-CastingBar-Small-Shield]])
			Shield:Hide()
			local function PostCastNotInterruptible(unit)
				if not elements.Castbar.interruptable then
					self.Castbar.Shield:Hide()
				end
			end
			cast.PostCastNotInterruptible = PostCastNotInterruptible

			-- Add a timer
			local Time = cast:CreateFontString(nil, 'OVERLAY')
			SUI:FormatFont(Time, elements.Castbar.text['2'].size, 'UnitFrames')
			Time:SetPoint(
				elements.Castbar.text['2'].position.anchor,
				cast,
				elements.Castbar.text['2'].position.anchor,
				elements.Castbar.text['2'].position.x,
				elements.Castbar.text['2'].position.y
			)

			-- Add spell icon
			local Icon = cast:CreateTexture(nil, 'OVERLAY')
			Icon:SetSize(elements.Castbar.Icon.size, elements.Castbar.Icon.size)
			Icon:SetPoint(
				elements.Castbar.Icon.position.anchor,
				cast,
				elements.Castbar.Icon.position.anchor,
				elements.Castbar.Icon.position.x,
				elements.Castbar.Icon.position.y
			)

			-- Add safezone
			local SafeZone = cast:CreateTexture(nil, 'OVERLAY')

			-- --Interupt Flash
			-- cast.PostCastStart = PostCastStart
			-- cast.PostCastInterruptible = PostCastStart
			-- cast.PostCastStop = PostCastStop
			-- cast.PostCastInterrupted = PostCastStop
			-- cast.PostCastNotInterruptible = PostCastStop

			self.Castbar = cast
			self.Castbar.Text = Text
			self.Castbar.Time = Time
			self.Castbar.TextElements = {
				['1'] = self.Castbar.Text,
				['2'] = self.Castbar.Time
			}
			self.Castbar.Icon = Icon
			self.Castbar.SafeZone = SafeZone
			self.Castbar.Shield = Shield
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(2)
			health:SetStatusBarTexture(Smoothv2)
			health:SetSize(self:GetWidth(), elements.Health.height)

			local Background = health:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(health)
			Background:SetTexture(Smoothv2)
			Background:SetVertexColor(1, 1, 1, .2)
			health.bg = Background

			local healthOffset = elements.Health.offset
			if elements.Castbar.enabled then
				healthOffset = (elements.Castbar.height * -1)
			end
			health:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, healthOffset)
			health:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, healthOffset)

			health.TextElements = {}
			for i, key in pairs(elements.Health.text) do
				local NewString = health:CreateFontString(nil, 'OVERLAY')
				SUI:FormatFont(NewString, key.size, 'UnitFrames')
				NewString:SetJustifyH(key.SetJustifyH)
				NewString:SetJustifyV(key.SetJustifyV)
				NewString:SetPoint(key.position.anchor, health, key.position.anchor, key.position.x, key.position.y)
				self:Tag(NewString, key.text)

				health.TextElements[i] = NewString
				if not key.enabled then
					health.TextElements[i]:Hide()
				end
			end

			self.Health = health

			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = elements.Health.colorDisconnected
			self.Health.colorTapping = elements.Health.colorTapping
			self.Health.colorReaction = elements.Health.colorReaction
			self.Health.colorSmooth = elements.Health.colorSmooth
			self.Health.colorClass = elements.Health.colorClass

			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			self.Health.DataTable = elements.Health.text

			if SUI.IsRetail then
				-- Position and size
				local myBar = CreateFrame('StatusBar', nil, self.Health)
				myBar:SetPoint('TOP')
				myBar:SetPoint('BOTTOM')
				myBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
				myBar:SetStatusBarTexture(Smoothv2)
				myBar:SetStatusBarColor(0, 1, 0.5, 0.45)
				myBar:SetSize(150, 16)
				myBar:Hide()

				local otherBar = CreateFrame('StatusBar', nil, myBar)
				otherBar:SetPoint('TOP')
				otherBar:SetPoint('BOTTOM')
				otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
				otherBar:SetStatusBarTexture(Smoothv2)
				otherBar:SetStatusBarColor(0, 0.5, 1, 0.35)
				otherBar:SetSize(150, 16)
				otherBar:Hide()

				local absorbBar = CreateFrame('StatusBar', nil, self.Health)
				absorbBar:SetPoint('TOP')
				absorbBar:SetPoint('BOTTOM')
				absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
				absorbBar:SetStatusBarTexture(Smoothv2)
				absorbBar:SetWidth(10)
				absorbBar:Hide()

				local healAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
				healAbsorbBar:SetPoint('TOP')
				healAbsorbBar:SetPoint('BOTTOM')
				healAbsorbBar:SetPoint('RIGHT', self.Health:GetStatusBarTexture())
				healAbsorbBar:SetStatusBarTexture(Smoothv2)
				healAbsorbBar:SetReverseFill(true)
				healAbsorbBar:SetWidth(10)
				healAbsorbBar:Hide()

				local overAbsorb = self.Health:CreateTexture(nil, 'OVERLAY')
				overAbsorb:SetPoint('TOP')
				overAbsorb:SetPoint('BOTTOM')
				overAbsorb:SetPoint('LEFT', self.Health, 'RIGHT')
				overAbsorb:SetWidth(10)
				overAbsorb:Hide()

				local overHealAbsorb = self.Health:CreateTexture(nil, 'OVERLAY')
				overHealAbsorb:SetPoint('TOP')
				overHealAbsorb:SetPoint('BOTTOM')
				overHealAbsorb:SetPoint('RIGHT', self.Health, 'LEFT')
				overHealAbsorb:SetWidth(10)
				overHealAbsorb:Hide()

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
			power:SetHeight(elements.Power.height)

			local Background = power:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(power)
			Background:SetTexture(Smoothv2)
			Background:SetVertexColor(1, 1, 1, .2)
			power.bg = Background

			local powerOffset = elements.Power.offset
			if elements.Castbar.enabled then
				powerOffset = powerOffset + elements.Castbar.height
			end
			if elements.Health.enabled then
				powerOffset = powerOffset + elements.Health.height
			end
			if elements.Castbar.enabled or elements.Health.enabled then
				powerOffset = powerOffset * -1
			end

			power:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, powerOffset)
			power:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, powerOffset)

			local PositionData = 0

			if elements.Castbar.enabled then
				PositionData = elements.Castbar.height
			end
			PositionData = PositionData + elements.Health.height
			power:SetPoint('TOP', self, 'TOP', 0, ((PositionData + 2) * -1))

			power.TextElements = {}
			for i, key in pairs(elements.Power.text) do
				local NewString = power:CreateFontString(nil, 'OVERLAY')
				SUI:FormatFont(NewString, key.size, 'UnitFrames')
				NewString:SetJustifyH(key.SetJustifyH)
				NewString:SetJustifyV(key.SetJustifyV)
				NewString:SetPoint(key.position.anchor, power, key.position.anchor, key.position.x, key.position.y)
				self:Tag(NewString, key.text)

				power.TextElements[i] = NewString
				if not key.enabled then
					power.TextElements[i]:Hide()
				end
			end

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true

			-- Additional Mana
			local AdditionalPower = CreateFrame('StatusBar', nil, self)
			AdditionalPower:SetHeight(elements.AdditionalPower.height)
			AdditionalPower:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', 0, (elements.AdditionalPower.offset * -1))
			AdditionalPower:SetPoint('TOPRIGHT', self.Power, 'BOTTOMRIGHT', 0, (elements.AdditionalPower.offset * -1))
			AdditionalPower.colorPower = true
			AdditionalPower:SetStatusBarTexture(Smoothv2)
			AdditionalPower:Hide()

			AdditionalPower.bg = AdditionalPower:CreateTexture(nil, 'BACKGROUND')
			AdditionalPower.bg:SetAllPoints(AdditionalPower)
			AdditionalPower.bg:SetColorTexture(1, 1, 1, .2)

			self.AdditionalPower = AdditionalPower

			if unit == 'player' then
				-- Position and size
				local mainBar = CreateFrame('StatusBar', nil, self.Power)
				mainBar:SetReverseFill(true)
				mainBar:SetStatusBarTexture(Smoothv2)
				mainBar:SetPoint('RIGHT', self.Power:GetStatusBarTexture(), 'RIGHT')
				mainBar:SetPoint('TOP')
				mainBar:SetPoint('BOTTOM')
				mainBar:SetWidth(200)
				mainBar:Hide()

				local altBar = CreateFrame('StatusBar', nil, self.AdditionalPower)
				altBar:SetReverseFill(true)
				altBar:SetStatusBarTexture(Smoothv2)
				altBar:SetPoint('RIGHT', self.AdditionalPower:GetStatusBarTexture(), 'RIGHT')
				altBar:SetPoint('TOP')
				altBar:SetPoint('BOTTOM')
				altBar:SetWidth(200)
				altBar:Hide()

				self.PowerPrediction = {
					mainBar = mainBar,
					altBar = altBar
				}
			end
		end
	end
	do -- setup indicators
		self.Name = self:CreateFontString()
		SUI:FormatFont(self.Name, elements.Name.size, 'UnitFrames')
		self.Name:SetSize(self:GetWidth(), 12)
		self.Name:SetJustifyH(elements.Name.SetJustifyH)
		self.Name:SetJustifyV(elements.Name.SetJustifyV)
		ElementUpdate(self, 'Name')
		self:Tag(self.Name, elements.Name.text)

		if (SUI.IsClassic or SUI.IsBCC) and 'HUNTER' == select(2, UnitClass('player')) and unit == 'pet' then
			-- Register it with oUF
			local HappinessIndicator = self:CreateTexture(nil, 'OVERLAY')
			HappinessIndicator.btn = CreateFrame('Frame', nil, self)
			HappinessIndicator.Sizeable = true
			local function HIOnEnter(self)
				local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
				if not happiness then
					return
				end

				GameTooltip:SetOwner(HappinessIndicator.btn, 'ANCHOR_RIGHT')
				GameTooltip:SetText(_G['PET_HAPPINESS' .. happiness])
				GameTooltip:AddLine(format(PET_DAMAGE_PERCENTAGE, damagePercentage), '', 1, 1, 1)
				local tooltipLoyalty = nil
				if (loyaltyRate < 0) then
					tooltipLoyalty = _G['LOSING_LOYALTY']
				elseif (loyaltyRate > 0) then
					tooltipLoyalty = _G['GAINING_LOYALTY']
				end
				if (tooltipLoyalty) then
					GameTooltip:AddLine(tooltipLoyalty, '', 1, 1, 1)
				end
				GameTooltip:Show()
			end
			local function HIOnLeave()
				GameTooltip:Hide()
			end
			HappinessIndicator.btn:SetAllPoints(HappinessIndicator)
			HappinessIndicator.btn:SetScript('OnEnter', HIOnEnter)
			HappinessIndicator.btn:SetScript('OnLeave', HIOnLeave)
			HappinessIndicator:Hide()
			self.HappinessIndicator = HappinessIndicator
			ElementUpdate(self, 'HappinessIndicator')
		end

		self.RareElite = self.SpartanArt:CreateTexture(nil, 'BORDER')
		self.RareElite:SetTexture('Interface\\Addons\\SpartanUI\\images\\blank')
		ElementUpdate(self, 'RareElite')

		self.LeaderIndicator = self:CreateTexture(nil, 'BORDER')
		self.LeaderIndicator.Sizeable = true
		self.LeaderIndicator:Hide()
		ElementUpdate(self, 'LeaderIndicator')
		self.AssistantIndicator = self:CreateTexture(nil, 'BORDER')
		self.AssistantIndicator.Sizeable = true
		ElementUpdate(self, 'AssistantIndicator')

		self.SUI_RaidGroup = self:CreateTexture(nil, 'BORDER')
		self.SUI_RaidGroup:SetSize(elements.SUI_RaidGroup.size, elements.SUI_RaidGroup.size)

		self.SUI_RaidGroup.Text = self:CreateFontString(nil, 'BORDER')
		SUI:FormatFont(self.SUI_RaidGroup.Text, elements.SUI_RaidGroup.size, 'UnitFrames')
		self.SUI_RaidGroup.Text:SetJustifyH(elements.SUI_RaidGroup.SetJustifyH)
		self.SUI_RaidGroup.Text:SetJustifyV(elements.SUI_RaidGroup.SetJustifyV)
		self.SUI_RaidGroup.Text:SetPoint('CENTER', self.SUI_RaidGroup, 'CENTER', 0, 0)
		ElementUpdate(self, 'SUI_RaidGroup')
		self:Tag(self.SUI_RaidGroup.Text, '[group]')

		self.ReadyCheckIndicator = self:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheckIndicator.Sizeable = true
		ElementUpdate(self, 'ReadyCheckIndicator')

		self.QuestMobIndicator = self:CreateTexture(nil, 'OVERLAY')
		ElementUpdate(self, 'QuestMobIndicator')

		-- Position and size
		self.PhaseIndicator = self:CreateTexture(nil, 'OVERLAY')
		self.PhaseIndicator.Sizeable = true
		self.PhaseIndicator:Hide()
		ElementUpdate(self, 'PhaseIndicator')

		-- PVP Indicator
		local SUIpvpIndicator = function(self, event, unit)
			if (unit ~= self.unit) then
				return
			end

			local pvp = self.PvPIndicator
			if (pvp.PreUpdate) then
				pvp:PreUpdate()
			end

			local status
			local factionGroup = UnitFactionGroup(unit) or 'Neutral'
			local honorRewardInfo = false
			if SUI.IsRetail then
				honorRewardInfo = C_PvP.GetHonorRewardInfo(UnitHonorLevel(unit))
			end

			if (UnitIsPVPFreeForAll(unit)) then
				pvp:SetTexture('Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon')
				status = 'FFA'
			elseif (factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(unit)) then
				status = factionGroup
			end

			if (status) then
				pvp:Show()

				if (pvp.Badge and honorRewardInfo) then
					pvp:SetTexture(honorRewardInfo.badgeFileDataID)
					pvp:SetTexCoord(0, 1, 0, 1)

					if (pvp.shadow) then
						pvp.shadow:Hide()
					end
				else
					if (pvp.shadow) then
						pvp.shadow:Show()
					end
					if (status == 'FFA') then
						pvp:SetTexture('Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon')
					else
						pvp:SetTexture('Interface\\FriendsFrame\\PlusManz-' .. factionGroup)
						if (pvp.shadow) then
							pvp.shadow:SetTexture('Interface\\FriendsFrame\\PlusManz-' .. factionGroup)
						end
					end

					if (pvp.Badge) then
						pvp.Badge:Hide()
					end
				end
			else
				pvp:Hide()
				if (pvp.shadow) then
					pvp.shadow:Hide()
				end
			end

			if (pvp.PostUpdate) then
				return pvp:PostUpdate(status)
			end
		end
		self.PvPIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.PvPIndicator:SetSize(elements.PvPIndicator.size, elements.PvPIndicator.size)
		self.PvPIndicator.ShadowBackup = self:CreateTexture(nil, 'ARTWORK')
		self.PvPIndicator.ShadowBackup:SetSize(elements.PvPIndicator.size, elements.PvPIndicator.size)

		local Badge = self:CreateTexture(nil, 'BACKGROUND')
		Badge:SetSize(elements.PvPIndicator.size + 12, elements.PvPIndicator.size + 12)
		Badge:SetPoint('CENTER', self.PvPIndicator, 'CENTER')

		self.PvPIndicator.BadgeBackup = Badge
		self.PvPIndicator.Badge = Badge
		self.PvPIndicator.SizeChange = function()
			self.PvPIndicator:SetSize(elements.PvPIndicator.size, elements.PvPIndicator.size)
			self.PvPIndicator.BadgeBackup:SetSize(elements.PvPIndicator.size + 12, elements.PvPIndicator.size + 12)
			if self.PvPIndicator.Badge then
				self.PvPIndicator.Badge:SetSize(elements.PvPIndicator.size + 12, elements.PvPIndicator.size + 12)
			end
			self.PvPIndicator.ShadowBackup:SetSize(elements.PvPIndicator.size + 12, elements.PvPIndicator.size + 12)
			if self.PvPIndicator.Shadow then
				self.PvPIndicator.Shadow:SetSize(elements.PvPIndicator.size + 12, elements.PvPIndicator.size + 12)
			end
		end
		self.PvPIndicator.Override = SUIpvpIndicator
		ElementUpdate(self, 'PvPIndicator')

		self.RestingIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.RestingIndicator.Sizeable = true
		ElementUpdate(self, 'RestingIndicator')
		self.RestingIndicator:SetTexCoord(0.15, 0.86, 0.15, 0.86)

		self.GroupRoleIndicator = self:CreateTexture(nil, 'BORDER')
		self.GroupRoleIndicator:SetTexture('Interface\\AddOns\\SpartanUI\\images\\icon_role.tga')
		self.GroupRoleIndicator.Sizeable = true
		self.GroupRoleIndicator:Hide()
		ElementUpdate(self, 'GroupRoleIndicator')

		self.CombatIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.CombatIndicator.Sizeable = true
		ElementUpdate(self, 'CombatIndicator')

		self.RaidTargetIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.RaidTargetIndicator.Sizeable = true
		ElementUpdate(self, 'RaidTargetIndicator')

		self.SUI_ClassIcon = self:CreateTexture(nil, 'BORDER')
		self.SUI_ClassIcon.Sizeable = true
		ElementUpdate(self, 'SUI_ClassIcon')

		self.StatusText = self:CreateFontString(nil, 'OVERLAY')
		SUI:FormatFont(self.StatusText, elements.StatusText.size, 'UnitFrames')
		ElementUpdate(self, 'StatusText')
		self:Tag(self.StatusText, '[afkdnd]')
		-- end
		do -- Special Icons/Bars
			if unit == 'player' then
				local playerClass = select(2, UnitClass('player'))
				--Runes
				if playerClass == 'DEATHKNIGHT' then
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

				self.CPAnchor = self:CreateFontString(nil, 'BORDER')
				self.CPAnchor:SetPoint('TOPLEFT', self.Name, 'BOTTOMLEFT', 40, -5)
				local ClassPower = {}
				for index = 1, 10 do
					local Bar = CreateFrame('StatusBar', nil, self)
					Bar:SetStatusBarTexture(Smoothv2)

					-- Position and size.
					Bar:SetSize(16, 5)
					if (index == 1) then
						Bar:SetPoint('LEFT', self.CPAnchor, 'RIGHT', (index - 1) * Bar:GetWidth(), -1)
					else
						Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 3, 0)
					end
					ClassPower[index] = Bar
				end

				-- Register with oUF
				self.ClassPower = ClassPower

				--Totem Bar
				if SUI.IsRetail then
					for index = 1, 4 do
						_G['TotemFrameTotem' .. index]:SetFrameStrata('MEDIUM')
						_G['TotemFrameTotem' .. index]:SetFrameLevel(4)
						_G['TotemFrameTotem' .. index]:SetScale(.8)
					end
					hooksecurefunc(
						'TotemFrame_Update',
						function()
							TotemFrameTotem1:ClearAllPoints()
							TotemFrameTotem1:SetParent(self)
							TotemFrameTotem1:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 20, 0)
						end
					)
				end
			end
		end
	end
	-- do -- setup buffs and debuffs
	self.DispelHighlight = self.Health:CreateTexture(nil, 'OVERLAY')
	self.DispelHighlight:SetAllPoints(self.Health:GetStatusBarTexture())
	self.DispelHighlight:SetTexture(Smoothv2)
	self.DispelHighlight:Hide()
	ElementUpdate(self, 'DispelHighlight')

	self.Range = {
		insideAlpha = elements.Range.insideAlpha,
		outsideAlpha = elements.Range.outsideAlpha
	}

	-- Setup the frame's Right click menu.
	self:RegisterForClicks('AnyDown')
	if not InCombatLockdown() then
		self:EnableMouse(enable)
	end
	self:SetClampedToScreen(true)
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	return self
end

local function VisibilityCheck(group)
	local retVal = false
	if module.CurrentSettings[group].showParty and (IsInGroup() and not IsInRaid()) then
		retVal = true
	end
	if module.CurrentSettings[group].showRaid and IsInRaid() then
		retVal = true
	end
	if module.CurrentSettings[group].showSolo and not (IsInGroup() or IsInRaid()) then
		retVal = true
	end

	return retVal
end

function module:SpawnFrames()
	SUIUF:RegisterStyle('SpartanUI_UnitFrames', CreateUnitFrame)
	SUIUF:SetActiveStyle('SpartanUI_UnitFrames')

	-- Spawn all main frames
	for _, b in pairs(FramesList) do
		module.frames[b] = SUIUF:Spawn(b, 'SUI_UF_' .. b)

		-- Disable objects based on settings
		module.frames[b]:UpdateAll()

		if not module.CurrentSettings[b].enabled then
			module.frames[b]:Disable()
		end
	end

	if SUI.IsRetail then
		for _, group in ipairs({'boss', 'arena'}) do
			local grpFrame = CreateFrame('Frame')
			for i = 1, (group == 'boss' and MAX_BOSS_FRAMES or 3) do
				grpFrame[i] = SUIUF:Spawn(group .. i, 'SUI_' .. group .. i)
				if i == 1 then
					grpFrame[i]:SetPoint('TOPLEFT', _G['SUI_UF_' .. group], 'TOPLEFT', 0, 0)
				else
					grpFrame[i]:SetPoint('TOP', grpFrame[i - 1], 'BOTTOM', 0, -10)
				end
			end
			module.frames[group] = grpFrame
		end
	end

	-- Party Frames
	local party =
		SUIUF:SpawnHeader(
		'SUI_partyFrameHeader',
		nil,
		'party',
		'showRaid',
		module.CurrentSettings.party.showRaid,
		'showParty',
		module.CurrentSettings.party.showParty,
		'showPlayer',
		module.CurrentSettings.party.showPlayer,
		'showSolo',
		module.CurrentSettings.party.showSolo,
		'xoffset',
		module.CurrentSettings.party.xOffset,
		'yOffset',
		module.CurrentSettings.party.yOffset,
		'maxColumns',
		module.CurrentSettings.party.maxColumns,
		'unitsPerColumn',
		module.CurrentSettings.party.unitsPerColumn,
		'columnSpacing',
		module.CurrentSettings.party.columnSpacing,
		'columnAnchorPoint',
		'TOPLEFT',
		'initial-anchor',
		'TOPLEFT',
		'oUF-initialConfigFunction',
		('self:SetWidth(%d) self:SetHeight(%d)'):format(module.CurrentSettings.party.width, CalculateHeight('party'))
	)
	party:SetPoint('TOPLEFT', SUI_UF_party, 'TOPLEFT')
	module.frames.party = party

	-- Raid Frames
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'

	if module.CurrentSettings.raid.mode == 'GROUP' then
		groupingOrder = '1,2,3,4,5,6,7,8'
	end

	local raid =
		SUIUF:SpawnHeader(
		'SUI_UF_raidFrameHeader',
		nil,
		'raid',
		'showRaid',
		module.CurrentSettings.raid.showRaid,
		'showParty',
		module.CurrentSettings.raid.showParty,
		'showPlayer',
		module.CurrentSettings.raid.showSelf,
		'showSolo',
		module.CurrentSettings.raid.showSolo,
		'xoffset',
		module.CurrentSettings.raid.xOffset,
		'yOffset',
		module.CurrentSettings.raid.yOffset,
		'point',
		'TOP',
		'groupBy',
		module.CurrentSettings.raid.mode,
		'groupingOrder',
		groupingOrder,
		'sortMethod',
		'index',
		'maxColumns',
		module.CurrentSettings.raid.maxColumns,
		'unitsPerColumn',
		module.CurrentSettings.raid.unitsPerColumn,
		'columnSpacing',
		module.CurrentSettings.raid.columnSpacing,
		'columnAnchorPoint',
		'LEFT',
		'oUF-initialConfigFunction',
		('self:SetWidth(%d) self:SetHeight(%d)'):format(module.CurrentSettings.raid.width, CalculateHeight('raid'))
	)
	raid:SetPoint('TOPLEFT', SUI_UF_raid, 'TOPLEFT')
	module.frames.raid = raid

	local function GroupFrameUpdateSize(self)
		for _, f in ipairs(self) do
			if f.UpdateSize then
				f:UpdateSize()
			end
		end
	end
	local function GroupFrameElementUpdate(self, elementName)
		for _, f in ipairs(self) do
			if f.ElementUpdate then
				f:ElementUpdate(elementName)
			end
		end
	end
	local function GroupFrameUpdateAuras(self)
		for _, f in ipairs(self) do
			if f.UpdateAuras then
				f:UpdateAuras()
			end
		end
	end
	local function GroupFrameEnable(self)
		self:UpdateAll()
		for _, f in ipairs(self) do
			if f.Enable then
				f:Enable()
			end
		end
	end
	local function GroupFrameDisable(self)
		self:UpdateAll()
		for _, f in ipairs(self) do
			if f.Disable then
				f:Disable()
			end
		end
	end

	for _, group in ipairs(GroupFrames) do
		if module.frames[group] then
			local function GroupFrameUpdateAll(self)
				if VisibilityCheck(group) and module.CurrentSettings[group].enabled then
					if module.frames[group].visibility then
						RegisterStateDriver(module.frames[group], module.frames[group].visibility)
					end
					module.frames[group]:Show()

					for _, f in ipairs(self) do
						if f.UpdateAll then
							f:UpdateAll()
						end
					end
				else
					UnregisterStateDriver(module.frames[group], 'visibility')
					module.frames[group]:Hide()
				end
			end

			module.frames[group].UpdateAll = GroupFrameUpdateAll
			module.frames[group].ElementUpdate = GroupFrameElementUpdate
			module.frames[group].UpdateSize = GroupFrameUpdateSize
			module.frames[group].UpdateAuras = GroupFrameUpdateAuras
			module.frames[group].Enable = GroupFrameEnable
			module.frames[group].Disable = GroupFrameDisable
		end
	end

	local function GroupWatcher(event)
		if not InCombatLockdown() then
			-- Update 1 second after login
			if event == 'PLAYER_ENTERING_WORLD' or event == 'GROUP_JOINED' then
				module:ScheduleTimer(GroupWatcher, 1)
				return
			end

			module:UpdateGroupFrames(event)
		end
	end
	module:RegisterEvent('GROUP_ROSTER_UPDATE', GroupWatcher)
	module:RegisterEvent('GROUP_JOINED', GroupWatcher)
	module:RegisterEvent('PLAYER_ENTERING_WORLD', GroupWatcher)
	module:RegisterEvent('ZONE_CHANGED', GroupWatcher)
	module:RegisterEvent('READY_CHECK', GroupWatcher)
	module:RegisterEvent('PARTY_MEMBER_ENABLE', GroupWatcher)
	module:RegisterEvent('PLAYER_LOGIN', GroupWatcher)
	module:RegisterEvent('RAID_ROSTER_UPDATE', GroupWatcher)
	module:RegisterEvent('PARTY_LEADER_CHANGED', GroupWatcher)
	module:RegisterEvent('PLAYER_REGEN_ENABLED', GroupWatcher)
	module:RegisterEvent('ZONE_CHANGED_NEW_AREA', GroupWatcher)
end

function module:UpdateAll(event, ...)
	for _, v in ipairs(FramesList) do
		if module.frames[v] and module.frames[v].UpdateAll then
			module.frames[v]:UpdateAll()
		else
			SUI:Error('Unable to find updater for ' .. v, 'Unit Frames')
		end
	end

	module:UpdateGroupFrames()
end

function module:UpdateGroupFrames(event, ...)
	for _, v in ipairs(GroupFrames) do
		if module.frames[v] then
			module.frames[v]:UpdateAll()
		end
	end
end
