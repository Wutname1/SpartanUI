local _G, SUI = _G, SUI
local UF = SUI.UF ---@class SUI_UnitFrames
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
	'ClassIcon',
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
	'SUI_RaidGroup',
	'HappinessIndicator'
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
	'ClassIcon',
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
local MigratedElements = {'PvPIndicator', 'ClassIcon', 'Portrait', 'GroupRoleIndicator', 'Range'}
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
	local elements = UF.CurrentSettings[frameName].elements
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
		local auras = UF.CurrentSettings[unit].auras
		local elements = UF.CurrentSettings[unit].elements
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
		local data = UF.CurrentSettings[unit].elements[elementName]
		local element = self[elementName]
		element.DB = data

		if elementName == 'SpartanArt' then
			self.SpartanArt:ForceUpdate('OnUpdate')
			return
		end

		-- Call the elements update function
		UF.Elements:Update(self, elementName)

		if SUI:IsInTable(NoBulkUpdate, elementName) then
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

		-- Call the elements update function
		if self[elementName] and self[elementName].ForceUpdate then
			self[elementName].ForceUpdate(element)
		end
	end

	-- Build a function that updates the size of the frame and sizes of elements
	local function UpdateSize()
		local elements = UF.CurrentSettings[unit].elements
		-- Find the Height of the frame
		local FrameHeight = CalculateHeight(unit)
		self.FrameHeight = FrameHeight

		-- General
		if not InCombatLockdown() then
			if self.scale then
				self:scale(UF.CurrentSettings[unit].scale, true)
			else
				self:SetScale(UF.CurrentSettings[unit].scale)
			end
			self:SetSize(UF.CurrentSettings[unit].width, FrameHeight)
		end

		for _, elementName in ipairs(MigratedElements) do
			UF.Elements:UpdateSize(self, elementName)
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
		local db = UF.CurrentSettings[unit].auras

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

	local elementsDB = UF.CurrentSettings[unit].elements

	do -- General setup
		UF.Elements:Build(self, 'SpartanArt')

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
		UF.Elements:Build(self, 'Castbar', elementsDB.Castbar)
		UF.Elements:Build(self, 'Health', elementsDB.Health)
		UF.Elements:Build(self, 'Power', elementsDB.Power)
		do -- power bar
			-- Additional Mana
			local AdditionalPower = CreateFrame('StatusBar', nil, self)
			AdditionalPower:SetHeight(elementsDB.AdditionalPower.height)
			AdditionalPower:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', 0, (elementsDB.AdditionalPower.offset * -1))
			AdditionalPower:SetPoint('TOPRIGHT', self.Power, 'BOTTOMRIGHT', 0, (elementsDB.AdditionalPower.offset * -1))
			AdditionalPower.colorPower = true
			AdditionalPower:SetStatusBarTexture(Smoothv2)
			AdditionalPower:Hide()

			AdditionalPower.bg = AdditionalPower:CreateTexture(nil, 'BACKGROUND')
			AdditionalPower.bg:SetAllPoints(AdditionalPower)
			AdditionalPower.bg:SetColorTexture(1, 1, 1, .2)

			self.AdditionalPower = AdditionalPower

			-- if unit == 'player' then
			-- 	-- Position and size
			-- 	local mainBar = CreateFrame('StatusBar', nil, self.Power)
			-- 	mainBar:SetReverseFill(true)
			-- 	mainBar:SetStatusBarTexture(Smoothv2)
			-- 	mainBar:SetPoint('RIGHT', self.Power:GetStatusBarTexture(), 'RIGHT')
			-- 	mainBar:SetPoint('TOP')
			-- 	mainBar:SetPoint('BOTTOM')
			-- 	mainBar:SetWidth(200)
			-- 	mainBar:Hide()

			-- 	local altBar = CreateFrame('StatusBar', nil, self.AdditionalPower)
			-- 	altBar:SetReverseFill(true)
			-- 	altBar:SetStatusBarTexture(Smoothv2)
			-- 	altBar:SetPoint('RIGHT', self.AdditionalPower:GetStatusBarTexture(), 'RIGHT')
			-- 	altBar:SetPoint('TOP')
			-- 	altBar:SetPoint('BOTTOM')
			-- 	altBar:SetWidth(200)
			-- 	altBar:Hide()

			-- 	self.PowerPrediction = {
			-- 		mainBar = mainBar,
			-- 		altBar = altBar
			-- 	}
			-- end
		end
	end
	do -- setup indicators
		self.Name = self:CreateFontString()
		SUI:FormatFont(self.Name, elementsDB.Name.size, 'UnitFrames')
		self.Name:SetSize(self:GetWidth(), 12)
		self.Name:SetJustifyH(elementsDB.Name.SetJustifyH)
		self.Name:SetJustifyV(elementsDB.Name.SetJustifyV)
		ElementUpdate(self, 'Name')
		self:Tag(self.Name, elementsDB.Name.text)

		if (_G['GetPetHappiness']) and 'HUNTER' == select(2, UnitClass('player')) and unit == 'pet' then
			UF.Elements:Build(self, 'HappinessIndicator')
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
		self.SUI_RaidGroup:SetSize(elementsDB.SUI_RaidGroup.size, elementsDB.SUI_RaidGroup.size)

		self.SUI_RaidGroup.Text = self:CreateFontString(nil, 'BORDER')
		SUI:FormatFont(self.SUI_RaidGroup.Text, elementsDB.SUI_RaidGroup.size, 'UnitFrames')
		self.SUI_RaidGroup.Text:SetJustifyH(elementsDB.SUI_RaidGroup.SetJustifyH)
		self.SUI_RaidGroup.Text:SetJustifyV(elementsDB.SUI_RaidGroup.SetJustifyV)
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

		self.RestingIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.RestingIndicator.Sizeable = true
		ElementUpdate(self, 'RestingIndicator')
		self.RestingIndicator:SetTexCoord(0.15, 0.86, 0.15, 0.86)

		self.CombatIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.CombatIndicator.Sizeable = true
		function self.CombatIndicator:PostUpdate(inCombat)
			if self.DB and self.DB.enabled and inCombat then
				self:Show()
			else
				self:Hide()
			end
		end
		ElementUpdate(self, 'CombatIndicator')

		self.RaidTargetIndicator = self:CreateTexture(nil, 'ARTWORK')
		self.RaidTargetIndicator.Sizeable = true
		ElementUpdate(self, 'RaidTargetIndicator')

		self.StatusText = self:CreateFontString(nil, 'OVERLAY')
		SUI:FormatFont(self.StatusText, elementsDB.StatusText.size, 'UnitFrames')
		ElementUpdate(self, 'StatusText')
		self:Tag(self.StatusText, '[afkdnd]')
		-- end
		do -- Special Icons/Bars
			if unit == 'player' then
				--Runes
				UF.Elements:Build(self, 'Runes')

				-- Combo points
				UF.Elements:Build(self, 'ClassPower')

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

	for _, element in ipairs(MigratedElements) do
		UF.Elements:Build(self, element, elementsDB[element])
		ElementUpdate(self, element)
	end

	-- do -- setup buffs and debuffs
	self.DispelHighlight = self.Health:CreateTexture(nil, 'OVERLAY')
	self.DispelHighlight:SetAllPoints(self.Health:GetStatusBarTexture())
	self.DispelHighlight:SetTexture(Smoothv2)
	self.DispelHighlight:Hide()
	ElementUpdate(self, 'DispelHighlight')

	-- Setup the frame's Right click menu.
	self:RegisterForClicks('AnyDown')
	if not InCombatLockdown() then
		self:EnableMouse(true)
	end
	self:SetClampedToScreen(true)
	--Setup unitframes tooltip hook
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	return self
end

local function VisibilityCheck(group)
	local retVal = false
	if UF.CurrentSettings[group].showParty and (IsInGroup() and not IsInRaid()) then
		retVal = true
	end
	if UF.CurrentSettings[group].showRaid and IsInRaid() then
		retVal = true
	end
	if UF.CurrentSettings[group].showSolo and not (IsInGroup() or IsInRaid()) then
		retVal = true
	end

	return retVal
end

function UF:SpawnFrames()
	SUIUF:RegisterStyle('SpartanUI_UnitFrames', CreateUnitFrame)
	SUIUF:SetActiveStyle('SpartanUI_UnitFrames')

	-- Spawn all main frames
	for _, b in pairs(FramesList) do
		UF.frames[b] = SUIUF:Spawn(b, 'SUI_UF_' .. b)

		-- Disable objects based on settings
		UF.frames[b]:UpdateAll()

		if not UF.CurrentSettings[b].enabled then
			UF.frames[b]:Disable()
		end
	end

	if SUI.IsRetail then
		for _, group in ipairs({'boss', 'arena'}) do
			local grpFrame = CreateFrame('Frame')
			for i = 1, (group == 'boss' and MAX_BOSS_FRAMES or 5) do
				grpFrame[i] = SUIUF:Spawn(group .. i, 'SUI_' .. group .. i)
				if i == 1 then
					grpFrame[i]:SetPoint('TOPLEFT', _G['SUI_UF_' .. group], 'TOPLEFT', 0, 0)
				else
					grpFrame[i]:SetPoint('TOP', grpFrame[i - 1], 'BOTTOM', 0, -10)
				end
			end
			UF.frames[group] = grpFrame
		end
	end

	-- Party Frames
	local party =
		SUIUF:SpawnHeader(
		'SUI_partyFrameHeader',
		nil,
		'party',
		'showRaid',
		UF.CurrentSettings.party.showRaid,
		'showParty',
		UF.CurrentSettings.party.showParty,
		'showPlayer',
		UF.CurrentSettings.party.showPlayer,
		'showSolo',
		UF.CurrentSettings.party.showSolo,
		'xoffset',
		UF.CurrentSettings.party.xOffset,
		'yOffset',
		UF.CurrentSettings.party.yOffset,
		'maxColumns',
		UF.CurrentSettings.party.maxColumns,
		'unitsPerColumn',
		UF.CurrentSettings.party.unitsPerColumn,
		'columnSpacing',
		UF.CurrentSettings.party.columnSpacing,
		'columnAnchorPoint',
		'TOPLEFT',
		'initial-anchor',
		'TOPLEFT',
		'oUF-initialConfigFunction',
		('self:SetWidth(%d) self:SetHeight(%d)'):format(UF.CurrentSettings.party.width, CalculateHeight('party'))
	)
	party:SetPoint('TOPLEFT', SUI_UF_party, 'TOPLEFT')
	UF.frames.party = party

	-- Raid Frames
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'

	if UF.CurrentSettings.raid.mode == 'GROUP' then
		groupingOrder = '1,2,3,4,5,6,7,8'
	end

	local raid =
		SUIUF:SpawnHeader(
		'SUI_UF_raidFrameHeader',
		nil,
		'raid',
		'showRaid',
		UF.CurrentSettings.raid.showRaid,
		'showParty',
		UF.CurrentSettings.raid.showParty,
		'showPlayer',
		UF.CurrentSettings.raid.showSelf,
		'showSolo',
		UF.CurrentSettings.raid.showSolo,
		'xoffset',
		UF.CurrentSettings.raid.xOffset,
		'yOffset',
		UF.CurrentSettings.raid.yOffset,
		'point',
		'TOP',
		'groupBy',
		UF.CurrentSettings.raid.mode,
		'groupingOrder',
		groupingOrder,
		'sortMethod',
		'index',
		'maxColumns',
		UF.CurrentSettings.raid.maxColumns,
		'unitsPerColumn',
		UF.CurrentSettings.raid.unitsPerColumn,
		'columnSpacing',
		UF.CurrentSettings.raid.columnSpacing,
		'columnAnchorPoint',
		'LEFT',
		'oUF-initialConfigFunction',
		('self:SetWidth(%d) self:SetHeight(%d)'):format(UF.CurrentSettings.raid.width, CalculateHeight('raid'))
	)
	raid:SetPoint('TOPLEFT', SUI_UF_raid, 'TOPLEFT')
	UF.frames.raid = raid

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
		if UF.frames[group] then
			local function GroupFrameUpdateAll(self)
				if VisibilityCheck(group) and UF.CurrentSettings[group].enabled then
					if UF.frames[group].visibility then
						RegisterStateDriver(UF.frames[group], UF.frames[group].visibility)
					end
					UF.frames[group]:Show()

					for _, f in ipairs(self) do
						if f.UpdateAll then
							f:UpdateAll()
						end
					end
				else
					UnregisterStateDriver(UF.frames[group], 'visibility')
					UF.frames[group]:Hide()
				end
			end

			UF.frames[group].UpdateAll = GroupFrameUpdateAll
			UF.frames[group].ElementUpdate = GroupFrameElementUpdate
			UF.frames[group].UpdateSize = GroupFrameUpdateSize
			UF.frames[group].UpdateAuras = GroupFrameUpdateAuras
			UF.frames[group].Enable = GroupFrameEnable
			UF.frames[group].Disable = GroupFrameDisable
		end
	end

	local function GroupWatcher(event)
		if not InCombatLockdown() then
			-- Update 1 second after login
			if event == 'PLAYER_ENTERING_WORLD' or event == 'GROUP_JOINED' then
				UF:ScheduleTimer(GroupWatcher, 1)
				return
			end

			UF:UpdateGroupFrames(event)
		end
	end
	UF:RegisterEvent('GROUP_ROSTER_UPDATE', GroupWatcher)
	UF:RegisterEvent('GROUP_JOINED', GroupWatcher)
	UF:RegisterEvent('PLAYER_ENTERING_WORLD', GroupWatcher)
	UF:RegisterEvent('ZONE_CHANGED', GroupWatcher)
	UF:RegisterEvent('READY_CHECK', GroupWatcher)
	UF:RegisterEvent('PARTY_MEMBER_ENABLE', GroupWatcher)
	UF:RegisterEvent('PLAYER_LOGIN', GroupWatcher)
	UF:RegisterEvent('RAID_ROSTER_UPDATE', GroupWatcher)
	UF:RegisterEvent('PARTY_LEADER_CHANGED', GroupWatcher)
	UF:RegisterEvent('PLAYER_REGEN_ENABLED', GroupWatcher)
	UF:RegisterEvent('ZONE_CHANGED_NEW_AREA', GroupWatcher)
end

function UF:UpdateAll(event, ...)
	for _, v in ipairs(FramesList) do
		if UF.frames[v] and UF.frames[v].UpdateAll then
			UF.frames[v]:UpdateAll()
		else
			SUI:Error('Unable to find updater for ' .. v, 'Unit Frames')
		end
	end

	UF:UpdateGroupFrames()
end

function UF:UpdateGroupFrames(event, ...)
	for _, v in ipairs(GroupFrames) do
		if UF.frames[v] then
			UF.frames[v]:UpdateAll()
		end
	end
end
