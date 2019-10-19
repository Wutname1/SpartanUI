local _G, SUI = _G, SUI
local module = SUI:GetModule('Component_UnitFrames')
local PartyFrames = {}
local PlayerFrames = {}
local RaidFrames = {}
----------------------------------------------------------------------------------------------------
local Smoothv2 = SUI.DB.BarTextures.smooth
local FramesList = {
	[1] = 'pet',
	[2] = 'target',
	[3] = 'targettarget',
	[4] = 'focus',
	[5] = 'focustarget',
	[6] = 'player'
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
	'QuestIndicator',
	'Range',
	'PhaseIndicator',
	'ThreatIndicator',
	'SUI_RaidGroup'
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
	'QuestIndicator',
	'PhaseIndicator',
	'ThreatIndicator',
	'SUI_RaidGroup',
	'PetHappiness'
}

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

local function BuffConstructor(self, unit)
	-- Build buffs
	if SUI.DB.Styles[CurStyle].Frames[unit] then
		local Buffsize = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.size
		local Debuffsize = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.size
		local BuffsMode = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.Mode
		local DebuffsMode = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.Mode

		--Determine how many we can fit for Hybrid Display
		local split = 4
		local Spacer = 3
		local BuffWidth = 0
		local BuffWidth2 = 0
		local DeBuffWidth = 0
		local DeBuffWidth2 = 0
		for index = 1, 10 do
			if
				((index * (Buffsize + SUI.DB.Styles[CurStyle].Frames[unit].Buffs.spacing)) <= (self.BuffAnchor:GetWidth() / split))
			 then
				BuffWidth = index
			end
			if ((index * (Buffsize + SUI.DB.Styles[CurStyle].Frames[unit].Buffs.spacing)) <= (self.BuffAnchor:GetWidth() / 2)) then
				BuffWidth2 = index
			end
		end
		for index = 1, 10 do
			if
				((index * (Debuffsize + SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.spacing)) <=
					(self.BuffAnchor:GetWidth() / split))
			 then
				DeBuffWidth = index
			end
			if
				((index * (Debuffsize + SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.spacing)) <= (self.BuffAnchor:GetWidth() / 2))
			 then
				DeBuffWidth2 = index
			end
		end
		local BuffWidthActual = (Buffsize + SUI.DB.Styles[CurStyle].Frames[unit].Buffs.spacing) * BuffWidth
		local DeBuffWidthActual = (Debuffsize + SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.spacing) * DeBuffWidth

		-- Position Bar
		local BarPosition = function(self, pos)
			-- Reminder on how position is defined
			-- * = Icons
			-- - = Bars
			--Pos1 -------**
			--Pos2 **-----**
			--Pos3 **-------
			if pos == 1 then
				self.AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
				self.AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', ((DeBuffWidthActual + Spacer) * -1), 0)
			elseif pos == 2 then
				self.AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', (BuffWidthActual + Spacer), 0)
				self.AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', ((DeBuffWidthActual + Spacer) * -1), 0)
			else --pos 3
				self.AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', (BuffWidthActual + Spacer), 0)
				self.AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			end
			return self
		end

		--Buff Icons
		local Buffs = CreateFrame('Frame', nil, self)
		--Debuff Icons
		local Debuffs = CreateFrame('Frame', nil, self)
		-- Setup icons if needed
		local iconFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
			if caster == 'player' and (duration == 0 or duration > 60) then --Do not show DOTS & HOTS
				return true
			elseif caster ~= 'player' then
				return true
			end
		end
		if BuffsMode ~= 'bars' and BuffsMode ~= 'disabled' then
			Buffs:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
			Buffs.size = Buffsize
			Buffs['growth-x'] = 'RIGHT'
			Buffs['growth-y'] = 'UP'
			Buffs.spacing = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.spacing
			Buffs.showType = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.showType
			Buffs.numBuffs = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.Number
			Buffs.onlyShowPlayer = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.onlyShowPlayer
			Buffs:SetSize(BuffWidthActual, (Buffsize * (Buffs.numBuffs / BuffWidth)))
			Buffs.PostUpdate = PostUpdateAura
			if BuffsMode ~= 'icons' then
				Buffs.CustomFilter = iconFilter
			end
			self.Buffs = Buffs
		end
		if DebuffsMode ~= 'bars' and DebuffsMode ~= 'disabled' then
			Debuffs:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			Debuffs.size = Debuffsize
			Debuffs.initialAnchor = 'BOTTOMRIGHT'
			Debuffs['growth-x'] = 'LEFT'
			Debuffs['growth-y'] = 'UP'
			Debuffs.spacing = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.spacing
			Debuffs.showType = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.showType
			Debuffs.numDebuffs = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.Number
			Debuffs.onlyShowPlayer = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.onlyShowPlayer
			Debuffs:SetSize(DeBuffWidthActual, (Debuffsize * (Debuffs.numDebuffs / DeBuffWidth)))
			Debuffs.PostUpdate = PostUpdateAura
			if DebuffsMode ~= 'icons' then
				Debuffs.CustomFilter = iconFilter
			end
			self.Debuffs = Debuffs
		end

		--Bars
		local AuraBars = CreateFrame('Frame', nil, self)
		AuraBars:SetHeight(1)
		AuraBars.auraBarTexture = Smoothv2
		AuraBars.PostUpdate = PostUpdateAura
		AuraBars.spellTimeFont = SUI:GetFontFace('Player')
		AuraBars.spellNameFont = SUI:GetFontFace('Player')

		--Hots and Dots Filter
		local Barfilter = function(name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, spellID)
			--Only Show things with a SHORT durration (HOTS and DOTS)
			if duration > 0 and duration < 60 then
				return true
			end
		end

		-- Determine Buff Bar locaion
		if BuffsMode == 'bars' and DebuffsMode == 'icons' then
			AuraBars.Buffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 1)
		elseif BuffsMode == 'bars' and DebuffsMode == 'both' then
			AuraBars.ShowAll = true
			self.AuraBars = AuraBars
			BarPosition(self, 1)
		elseif BuffsMode == 'bars' and (DebuffsMode == 'bars' or DebuffsMode == 'disabled') then
			if DebuffsMode == 'disabled' then
				AuraBars.Buffs = true
			else
				AuraBars.ShowAll = true
			end
			AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
			AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			self.AuraBars = AuraBars
		elseif BuffsMode == 'icons' and DebuffsMode == 'icons' then
			Buffs:SetSize(self.BuffAnchor:GetWidth() / 2, (Buffsize * (Buffs.numBuffs / BuffWidth2)))
			Debuffs:SetSize(self.BuffAnchor:GetWidth() / 2, (Debuffsize * (Debuffs.numDebuffs / DeBuffWidth2)))
		elseif BuffsMode == 'icons' and DebuffsMode == 'both' then
			AuraBars.Debuffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 2)
		elseif BuffsMode == 'icons' and DebuffsMode == 'bars' then
			AuraBars.Debuffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 3)
		elseif BuffsMode == 'icons' and DebuffsMode == 'disabled' then
			Buffs:SetSize(self.BuffAnchor:GetWidth(), (Buffsize * (Buffs.numBuffs / self.BuffAnchor:GetWidth())))
		elseif BuffsMode == 'both' and DebuffsMode == 'icons' then
			AuraBars.Buffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 2)
		elseif BuffsMode == 'both' and DebuffsMode == 'both' then
			AuraBars.ShowAll = true
			self.AuraBars = AuraBars
			BarPosition(self, 2)
		elseif BuffsMode == 'both' and DebuffsMode == 'bars' then
			AuraBars.ShowAll = true
			self.AuraBars = AuraBars
			BarPosition(self, 3)
		elseif BuffsMode == 'bars' and DebuffsMode == 'disabled' then
			AuraBars.Buffs = true
			AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
			AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			self.AuraBars = AuraBars
		elseif BuffsMode == 'disabled' and DebuffsMode == 'bars' then
			AuraBars.Debuffs = true
			AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
			AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			self.AuraBars = AuraBars
		elseif BuffsMode == 'disabled' and DebuffsMode == 'icons' then
			Debuffs:SetSize(self.BuffAnchor:GetWidth(), (Debuffsize * (Debuffs.numDebuffs / self.BuffAnchor:GetWidth())))
		elseif BuffsMode == 'disabled' and DebuffsMode == 'both' then
			AuraBars.Debuffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 1)
		end

		--Buff Filter for bars
		if self.AuraBars then
			AuraBars.filter = Barfilter
		end

		--Change options if needed
		if SUI.DB.Styles[CurStyle].Frames[unit].Buffs.Mode == 'bars' then
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Buffs'].args['Number'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Buffs'].args['size'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Buffs'].args['spacing'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Buffs'].args['showType'].disabled = true
		end
		if SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.Mode == 'bars' then
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Debuffs'].args['Number'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Debuffs'].args['size'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Debuffs'].args['spacing'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Debuffs'].args['showType'].disabled = true
		end

		SUI.opt.args['PlayerFrames'].args['auras'].args[unit].disabled = false
	end
	return self
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
	button:SetBackdrop(BACKDROP)
	button:SetBackdropColor(0, 0, 0)
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

	if (unit == 'target' and canStealOrPurge) then
		button:SetBackdropColor(0, 1 / 2, 1 / 2)
	elseif (owner ~= 'player') then
		button:SetBackdropColor(0, 0, 0)
	end
end

local function CreateUnitFrame(self, unit)
	if (unit ~= 'raid') then
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
					if module.CurrentSettings[unit].elements[element].bg then
						self[element].bg:Show()
					else
						self[element].bg:Hide()
					end
				end
				-- SUI Update (size, position, etc)
				if SUI:isInTable(IndicatorList, element) then
					self:ElementUpdate(element)
				end
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
			if not SUI.IsClassic then
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

		-- Setup the Alpha scape and position
		print(elementName)
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
		if elementName == 'PvPIndicator' and data.Badge and self.PvPIndicator.Badge == nil then
			self.PvPIndicator.Badge = self.PvPIndicator.BadgeBackup
			self.PvPIndicator:ForceUpdate('OnUpdate')
		end

		--Portrait
		if elementName == 'Portrait' then
			self.Portrait3D:Hide()
			self.Portrait2D:Hide()
			if data.type == '3D' then
				self.Portrait = self.Portrait3D
				self.Portrait3D:Show()
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

		-- General
		if not InCombatLockdown() then
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

	local function UpdateAuras()
		local db = module.CurrentSettings[unit].auras

		local Buffs = self.Buffs
		Buffs.size = db.Buffs.size
		Buffs.initialAnchor = db.Buffs.initialAnchor
		Buffs['growth-x'] = db.Buffs.growthx
		Buffs['growth-y'] = db.Buffs.growthy
		Buffs.spacing = db.Buffs.spacing
		Buffs.showType = db.Buffs.showType
		Buffs.numBuffs = db.Buffs.number
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
		Buffs:SetSize(
			(db.Buffs.size + db.Buffs.spacing) * (db.Buffs.number / db.Buffs.rows),
			(db.Buffs.spacing + db.Buffs.size) * db.Buffs.rows
		)

		--Debuff Icons
		local Debuffs = self.Debuffs
		Debuffs.size = db.Debuffs.size
		Debuffs.initialAnchor = db.Debuffs.initialAnchor
		Debuffs['growth-x'] = db.Debuffs.growthx
		Debuffs['growth-y'] = db.Debuffs.growthy
		Debuffs.spacing = db.Debuffs.spacing
		Debuffs.showType = db.Debuffs.showType
		Debuffs.numDebuffs = db.Debuffs.number
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
		Debuffs:SetSize(
			(db.Debuffs.size + db.Debuffs.spacing) * (db.Buffs.number / db.Buffs.rows),
			(db.Debuffs.spacing + db.Debuffs.size) * db.Debuffs.rows
		)

		-- self.Buffs:PostUpdate(unit, 'Buffs')
		-- self.Debuffs:PostUpdate(unit, 'Buffs')
	end

	self.UpdateAll = UpdateAll
	self.UpdateSize = UpdateSize
	self.ElementUpdate = ElementUpdate
	self.UpdateAuras = UpdateAuras

	self.UpdateSize()

	local artwork = module.CurrentSettings[unit].artwork
	local elements = module.CurrentSettings[unit].elements

	do -- General setup
		self.artwork = CreateFrame('Frame', nil, self)
		self.artwork:SetFrameStrata('BACKGROUND')
		self.artwork:SetFrameLevel(2)
		self.artwork:SetAllPoints()

		-- self.artwork.top = self.artwork:CreateTexture(nil, 'BORDER')
		-- self.artwork.top:SetAllPoints(self)
		-- self.artwork.top:SetTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')
		-- self.artwork.top:SetTexCoord(unpack(Images.Horde.bg.Coords))
		-- self.artwork.top:SetVertexColor(0, 0, 0, .6)

		-- self.artwork.bottom = self.artwork:CreateTexture(nil, 'BORDER')
		-- self.artwork.bottom:SetAllPoints(self)
		-- self.artwork.bottom:SetTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')
		-- self.artwork.bottom:SetTexCoord(unpack(Images.Horde.bg.Coords))
		-- self.artwork.bottom:SetVertexColor(0, 0, 0, .6)

		-- 3D Portrait
		local Portrait3D = CreateFrame('PlayerModel', nil, self)
		Portrait3D:SetSize(self:GetHeight(), self:GetHeight())
		Portrait3D:SetScale(elements.Portrait.Scale)
		Portrait3D:SetFrameStrata('LOW')
		Portrait3D:SetFrameLevel(2)
		Portrait3D.PostUpdate = function(unit, event, shouldUpdate)
			self:SetAlpha(elements.Portrait.alpha)

			if (shouldUpdate) then
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
		local Buffs = CreateFrame('Frame', nil, self)
		-- Buffs.PostUpdate = PostUpdateAura
		-- Buffs.CustomFilter = customFilter
		self.Buffs = Buffs

		--Debuff Icons
		local Debuffs = CreateFrame('Frame', nil, self)
		-- Debuffs.PostUpdate = PostUpdateAura
		-- Debuffs.CustomFilter = customFilter
		self.Debuffs = Debuffs
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
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
				if key.enabled then
					local NewString = health:CreateFontString(nil, 'OVERLAY')
					SUI:FormatFont(NewString, key.size, 'UnitFrames')
					NewString:SetJustifyH(key.SetJustifyH)
					NewString:SetJustifyV(key.SetJustifyV)
					NewString:SetPoint(key.position.anchor, health, key.position.anchor, key.position.x, key.position.y)
					self:Tag(NewString, key.text)

					health.TextElements[i] = NewString
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
			power:SetHeight(elements.Power.height)

			power.bg = power:CreateTexture(nil, 'BACKGROUND')
			power.bg:SetAllPoints(power)
			power.bg:SetTexture(Smoothv2)
			power.bg:SetVertexColor(1, 1, 1, .2)

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
				if key.enabled then
					local NewString = power:CreateFontString(nil, 'OVERLAY')
					SUI:FormatFont(NewString, key.size, 'UnitFrames')
					NewString:SetJustifyH(key.SetJustifyH)
					NewString:SetJustifyV(key.SetJustifyV)
					NewString:SetPoint(key.position.anchor, power, key.position.anchor, key.position.x, key.position.y)
					self:Tag(NewString, key.text)

					power.TextElements[i] = NewString
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

			AdditionalPower.bg = AdditionalPower:CreateTexture(nil, 'BACKGROUND')
			AdditionalPower.bg:SetAllPoints(AdditionalPower)
			AdditionalPower.bg:SetTexture(1, 1, 1, .2)

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
	do -- setup indicators
		self.Name = self:CreateFontString()
		SUI:FormatFont(self.Name, elements.Name.size, 'UnitFrames')
		self.Name:SetSize(self:GetWidth(), 12)
		self.Name:SetJustifyH(elements.Name.SetJustifyH)
		self.Name:SetJustifyV(elements.Name.SetJustifyV)
		ElementUpdate(self, 'Name')
		self:Tag(self.Name, elements.Name.text)

		if SUI.IsClassic then
			-- Register it with oUF
			local HappinessIndicator = CreateFrame('Frame', nil, self)
			HappinessIndicator.Sizeable = true
			local function HIOnEnter()
				local element = self.PetHappiness
				if (element.tooltip) then
					GameTooltip:SetOwner(element, 'ANCHOR_RIGHT')
					GameTooltip:SetText(element.tooltip)
					if (element.tooltipDamage) then
						GameTooltip:AddLine(element.tooltipDamage, '', 1, 1, 1)
					end
					if (element.tooltipLoyalty) then
						GameTooltip:AddLine(element.tooltipLoyalty, '', 1, 1, 1)
					end
					GameTooltip:Show()
				end
			end
			local function HIOnLeave()
				GameTooltip:Hide()
			end
			HappinessIndicator:SetScript('OnEnter', HIOnEnter)
			HappinessIndicator:SetScript('OnLeave', HIOnLeave)
			self.HappinessIndicator = HappinessIndicator
			ElementUpdate(self, 'HappinessIndicator')
		end

		self.RareElite = self.artwork:CreateTexture(nil, 'BACKGROUND', nil, -8)
		self.RareElite:SetTexture('Interface\\Addons\\SpartanUI\\images\\blank')
		ElementUpdate(self, 'RareElite')

		self.LeaderIndicator = self:CreateTexture(nil, 'BORDER')
		self.LeaderIndicator.Sizeable = true
		ElementUpdate(self, 'LeaderIndicator')
		self.AssistantIndicator = self:CreateTexture(nil, 'BORDER')
		self.AssistantIndicator.Sizeable = true
		ElementUpdate(self, 'AssistantIndicator')

		-- 	self.SUI_RaidGroup = self:CreateTexture(nil, 'BORDER')
		-- 	self.SUI_RaidGroup:SetSize(elements.SUI_RaidGroup.size, elements.SUI_RaidGroup.size)
		-- 	self.SUI_RaidGroup:SetTexture(square)
		-- 	self.SUI_RaidGroup:SetVertexColor(0, .8, .9, .9)

		-- 	self.SUI_RaidGroup.Text = self:CreateFontString(nil, 'BORDER')
		--  SUI:FormatFont(self.SUI_RaidGroup.Text, elements.SUI_RaidGroup.size, 'UnitFrames')
		-- 	self.SUI_RaidGroup.Text:SetJustifyH(elements.SUI_RaidGroup.SetJustifyH)
		-- 	self.SUI_RaidGroup.Text:SetJustifyV(elements.SUI_RaidGroup.SetJustifyV)
		-- 	self.SUI_RaidGroup.Text:SetPoint('CENTER', self.SUI_RaidGroup, 'CENTER', 0, 0)
		--  ElementUpdate(self, 'SUI_RaidGroup')
		-- 	self:Tag(self.SUI_RaidGroup.Text, '[group]')

		self.ReadyCheckIndicator = self:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheckIndicator.Sizeable = true
		ElementUpdate(self, 'ReadyCheckIndicator')

		-- Position and size
		self.PhaseIndicator = self:CreateTexture(nil, 'OVERLAY')
		self.PhaseIndicator.Sizeable = true
		ElementUpdate(self, 'PhaseIndicator')

		self.PvPIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.PvPIndicator:SetSize(elements.PvPIndicator.size, elements.PvPIndicator.size)

		local Badge = self:CreateTexture(nil, 'BACKGROUND')
		Badge:SetSize(elements.PvPIndicator.size + 12, elements.PvPIndicator.size + 12)
		Badge:SetPoint('CENTER', self.PvPIndicator, 'CENTER')

		self.PvPIndicator.BadgeBackup = Badge
		self.PvPIndicator.SizeChange = function()
			self.PvPIndicator:SetSize(elements.PvPIndicator.size, elements.PvPIndicator.size)
			self.PvPIndicator.BadgeBackup:SetSize(elements.PvPIndicator.size + 12, elements.PvPIndicator.size + 12)
			if self.PvPIndicator.Badge then
				self.PvPIndicator.Badge:SetSize(elements.PvPIndicator.size + 12, elements.PvPIndicator.size + 12)
			end
		end
		ElementUpdate(self, 'PvPIndicator')
		if elements.PvPIndicator.Override then
			self.PvPIndicator.Override = elements.PvPIndicator.Override
		end

		self.RestingIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.RestingIndicator.Sizeable = true
		ElementUpdate(self, 'RestingIndicator')
		self.RestingIndicator:SetTexCoord(0.15, 0.86, 0.15, 0.86)

		self.GroupRoleIndicator = self:CreateTexture(nil, 'BORDER')
		self.GroupRoleIndicator:SetTexture('Interface\\AddOns\\SpartanUI\\images\\icon_role.tga')
		self.GroupRoleIndicator.Sizeable = true
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

				self.CPAnchor = self:CreateFontString(nil, 'BORDER', 'SUI_FontOutline13')
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
				if not SUI.IsClassic then
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
	-- self.TextUpdate = PostUpdateText
	-- self.ColorUpdate = PostUpdateColor

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

SUIUF:RegisterStyle('SpartanUI_UnitFrames', CreateUnitFrame)

function module:SpawnFrames()
	SUIUF:SetActiveStyle('SpartanUI_UnitFrames')

	-- Spawn all main frames
	for _, b in pairs(FramesList) do
		module.frames[b] = SUIUF:Spawn(b, 'SUI_UF_' .. b)

		-- Disable objects based on settings
		module.frames[b]:UpdateAll()
	end

	-- Area Frames
	if not SUI.IsClassic then
		local arena = {}
		for i = 1, 3 do
			arena[i] = SUIUF:Spawn('arena' .. i, 'SUI_Arena' .. i)

			if i == 1 then
				arena[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			else
				arena[i]:SetPoint('TOP', arena[i - 1], 'BOTTOM', 0, -10)
			end
		end
		module.frames.arena = arena
	end

	-- Boss Frames
	local boss = {}
	for i = 1, MAX_BOSS_FRAMES do
		boss[i] = SUIUF:Spawn('boss' .. i, 'SUI_Boss' .. i)

		if i == 1 then
			boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
		else
			boss[i]:SetPoint('TOP', boss[i - 1], 'BOTTOM', 0, -10)
		end
	end
	module.frames.boss = boss

	-- Party Frames
	local party =
		SUIUF:SpawnHeader(
		'SUI_PartyFrameHeader',
		nil,
		'party',
		'showRaid',
		true,
		'showParty',
		true,
		'showPlayer',
		module.CurrentSettings.party.showSelf,
		'showSolo',
		true,
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
		([[
			local elements = module.CurrentSettings.party.elements
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

			self:SetSize(module.CurrentSettings.party.width, FrameHeight)
			self:EnableMouse(enable)
			]])
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
		'SUI_UF_RaidFrameHeader',
		nil,
		'raid',
		'showRaid',
		true,
		'showParty',
		module.CurrentSettings.raid.showParty,
		'showPlayer',
		module.CurrentSettings.raid.showSelf,
		'showSolo',
		true,
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
		([[
			local elements = module.CurrentSettings.raid.elements
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

			self:SetSize(module.CurrentSettings.raid.width, FrameHeight)
			self:EnableMouse(enable)
			]])
	)
	raid:SetPoint('TOPLEFT', SUI_UF_raid, 'TOPLEFT')
	module.frames.raid = raid

	local function GroupFrameUpdateAll(self)
		for _, f in ipairs({self:GetChildren()}) do
			if f.UpdateAll then
				f:UpdateAll()
			end
		end
	end
	local function GroupFrameElementUpdate(self, elementName)
		for _, f in ipairs({self:GetChildren()}) do
			if f.ElementUpdate then
				f:ElementUpdate(elementName)
			end
		end
	end
	local function GroupFrameUpdateSize(self)
		for _, f in ipairs({self:GetChildren()}) do
			if f.UpdateSize then
				f:UpdateSize()
			end
		end
	end
	local function GroupFrameUpdateAuras(self)
		for _, f in ipairs({self:GetChildren()}) do
			if f.UpdateAuras then
				f:UpdateAuras()
			end
		end
	end

	for _, group in ipairs({'raid', 'party'}) do
		module.frames[group].UpdateAll = GroupFrameUpdateAll
		module.frames[group].ElementUpdate = GroupFrameElementUpdate
		module.frames[group].UpdateSize = GroupFrameUpdateSize
		module.frames[group].UpdateAuras = GroupFrameUpdateAuras
	end

	local function GroupWatcher(event)
		if (InCombatLockdown()) then
			module:RegisterEvent('PLAYER_REGEN_ENABLED', GroupWatcher)
		else
			-- Update 1 second after login
			if event == 'PLAYER_ENTERING_WORLD' or event == 'GROUP_JOINED' then
				module:ScheduleTimer(GroupWatcher, 1)
			end

			module:UnregisterEvent('PLAYER_REGEN_ENABLED', GroupWatcher)
			module:UpdateGroupFrames(event)
		end
	end
	module:RegisterEvent('GROUP_ROSTER_UPDATE', GroupWatcher)
	module:RegisterEvent('GROUP_JOINED', GroupWatcher)
	module:RegisterEvent('PLAYER_ENTERING_WORLD', GroupWatcher)
	module:RegisterEvent('ZONE_CHANGED', GroupWatcher)
	module:RegisterEvent('READY_CHECK', GroupWatcher)
	module:RegisterEvent('PARTY_MEMBER_ENABLE', GroupWatcher)
end

function module:UpdateGroupFrames(event, ...)
	local SUIPartyFrame = module.frames.party
	for _, PartyUnit in ipairs({SUIPartyFrame:GetChildren()}) do
		PartyUnit:UpdateAll()
	end

	local SUIRaidFrame = module.frames.raid
	for _, RaidUnit in ipairs({SUIRaidFrame:GetChildren()}) do
		RaidUnit:UpdateAll()
	end

	-- if module.CurrentSettings.raid.showRaid and IsInRaid() then
	-- 	SUIRaidFrame:Show()
	-- elseif module.CurrentSettings.raid.showParty and inParty then
	-- 	--Something keeps hiding it on us when solo so lets force it. Messy but oh well.
	-- 	SUIRaidFrame.HideTmp = SUIRaidFrame.Hide
	-- 	SUIRaidFrame.Hide = SUIRaidFrame.Show
	-- 	--Now Display
	-- 	SUIRaidFrame:Show()
	-- elseif module.CurrentSettings.raid.showSolo and not inParty and not IsInRaid() then
	-- 	--Something keeps hiding it on us when solo so lets force it. Messy but oh well.
	-- 	SUIRaidFrame.HideTmp = SUIRaidFrame.Hide
	-- 	SUIRaidFrame.Hide = SUIRaidFrame.Show
	-- 	--Now Display
	-- 	SUIRaidFrame:Show()
	-- elseif SUIRaidFrame:IsShown() then
	-- 	--Swap back hide function if needed
	-- 	if SUIRaidFrame.HideTmp then
	-- 		SUIRaidFrame.Hide = SUIRaidFrame.HideTmp
	-- 	end
	-- -- SUIRaidFrame:Hide()
	-- end
	-- RaidFrames:UpdateRaidPosition()

	-- SUIRaidFrame:SetAttribute('showRaid', module.CurrentSettings.raid.showRaid)
	-- SUIRaidFrame:SetAttribute('showParty', module.CurrentSettings.raid.showParty)
	-- SUIRaidFrame:SetAttribute('showPlayer', module.CurrentSettings.raid.showPlayer)
	-- SUIRaidFrame:SetAttribute('showSolo', module.CurrentSettings.raid.showSolo)

	-- SUIRaidFrame:SetAttribute('groupBy', module.CurrentSettings.raid.mode)
	-- SUIRaidFrame:SetAttribute('maxColumns', module.CurrentSettings.raid.maxColumns)
	-- SUIRaidFrame:SetAttribute('unitsPerColumn', module.CurrentSettings.raid.unitsPerColumn)
	-- SUIRaidFrame:SetAttribute('columnSpacing', module.CurrentSettings.raid.columnSpacing)

	-- SUIRaidFrame:SetScale(module.CurrentSettings.raid.scale)
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
	if module.CurrentSettings.raid.HideBlizzFrames and CompactRaidFrameContainer ~= nil then
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

	if (module.CurrentSettings.raid.Style == 'theme') and (SUI.DBMod.Artwork.Style ~= 'Classic') then
		SUI.RaidFrames = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):RaidFrames()
	elseif (module.CurrentSettings.raid.Style == 'Classic') or (SUI.DBMod.Artwork.Style == 'Classic') then
		SUI.RaidFrames = RaidFrames:Classic()
	elseif (module.CurrentSettings.raid.Style == 'plain') then
		SUI.RaidFrames = RaidFrames:Plain()
	else
		SUI.RaidFrames = SUI:GetModule('Style_' .. module.CurrentSettings.raid.Style):RaidFrames()
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
				module.CurrentSettings.raid.moved = true
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
				module.CurrentSettings.raid.Anchors[k] = v
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
	if module.CurrentSettings.raid.moved then
		SUI.RaidFrames:SetMovable(true)
		SUI.RaidFrames:SetUserPlaced(false)
	else
		SUI.RaidFrames:SetMovable(false)
	end
	if not module.CurrentSettings.raid.moved then
		SUI.RaidFrames:ClearAllPoints()
		if SUI:GetModule('PartyFrames', true) then
			SUI.RaidFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -140 - (RaidFrames.offset))
		else
			SUI.RaidFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -20 - (RaidFrames.offset))
		end
	else
		local Anchors = {}
		for k, v in pairs(module.CurrentSettings.raid.Anchors) do
			Anchors[k] = v
		end
		SUI.RaidFrames:ClearAllPoints()
		SUI.RaidFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
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
