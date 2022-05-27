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
	'DispelHighlight',
	'ReadyCheckIndicator',
	'RareElite',
	'Stagger',
	'Totems',
	'RaidRoleIndicator',
	'ResurrectIndicator',
	'SummonIndicator',
	'QuestMobIndicator',
	'PhaseIndicator'
}
local NoBulkUpdate = {
	'HealthPrediction'
}

local GroupFrames = {'raid', 'party', 'boss', 'arena'}
-- if SUI.IsClassic or SUI.IsBCC then
if SUI.IsClassic then
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

	-- Build a function that updates the size of the frame and sizes of elements
	local function UpdateSize()
		if not InCombatLockdown() then
			if self.scale then
				self:scale(UF.CurrentSettings[unit].scale, true)
			else
				self:SetScale(UF.CurrentSettings[unit].scale)
			end
			self:SetSize(UF.CurrentSettings[unit].width, CalculateHeight(unit))
		end
	end

	local function UpdateAll()
		local elementsDB = UF.CurrentSettings[unit].elements
		-- Check that its a frame
		-- Loop all elements and update their status
		for elementName, Functions in pairs(UF.Elements.List) do
			if not elementsDB[elementName] then
				SUI:Error('MISSING: ' .. elementName .. ' Type:' .. type(elementName))
			else
				self:ElementUpdate(elementName)
			end
		end

		for _, element in ipairs(elementList) do
			if self[element] and element ~= nil then
				-- oUF Update (event/updater state)
				if elementsDB[element].enabled then
					self:EnableElement(element)
				else
					self:DisableElement(element)
				end
				--Background
				if self[element].bg then
					if elementsDB[element].bg.enabled then
						self[element].bg:Show()
						if elementsDB[element].bg.color then
							self[element].bg:SetVertexColor(unpack(elementsDB[element].bg.color))
						end
					else
						self[element].bg:Hide()
					end
				end
				-- SUI Update (size, position, etc)
				self:ElementUpdate(element)
			end
		end

		-- Tell everything to update to get current data
		UpdateSize()
		self:UpdateAllElements('OnUpdate')
		self:UpdateTags()
	end

	local function ElementUpdate(frame, elementName)
		if not frame[elementName] then
			return
		end
		local data = UF.CurrentSettings[unit].elements[elementName]
		local element = frame[elementName]
		element.DB = data

		if data.enabled then
			frame:EnableElement(elementName)
		else
			frame:DisableElement(elementName)
		end

		-- Call the elements update function
		UF.Elements:Update(frame, elementName)

		if SUI:IsInTable(NoBulkUpdate, elementName) or UF.Elements:GetConfig(elementName).NoBulkUpdate then
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
		if data.points ~= false then
			if type(data.points) == 'string' then
				element:SetAllPoints(frame[data.points])
			else
				element:SetAllPoints(frame)
			end
		elseif data.points ~= false and data.points ~= true then
			for _, key in pairs(data.points) do
				if key.relativeTo == 'Frame' then
					element:SetPoint(key.anchor, frame, key.anchor, key.x, key.y)
				else
					element:SetPoint(key.anchor, frame[key.relativeTo], key.anchor, key.x, key.y)
				end
			end
		elseif data.position.anchor then
			if data.position.relativeTo == 'Frame' then
				element:SetPoint(
					data.position.anchor,
					frame,
					data.position.relativePoint or data.position.anchor,
					data.position.x,
					data.position.y
				)
			else
				element:SetPoint(
					data.position.anchor,
					frame[data.position.relativeTo],
					data.position.relativePoint or data.position.anchor,
					data.position.x,
					data.position.y
				)
			end
		end

		--Size it if we have a size change function for the element
		if element.SizeChange then
			element:SizeChange()
		elseif element.SingleSize then
			element:SetSize(data.size, data.size)
		else
			element:SetSize(data.width or frame:GetWidth(), data.height or frame:GetHeight())
		end

		-- Call the elements update function
		if frame[elementName] and data.enabled and frame[elementName].ForceUpdate then
			frame[elementName].ForceUpdate(element)
		end
	end

	self.UpdateAll = UpdateAll
	self.ElementUpdate = ElementUpdate

	UpdateSize()

	local elementsDB = UF.CurrentSettings[unit].elements
	self.elementDB = elementsDB
	for elementName, _ in pairs(UF.Elements.List) do
		if not elementsDB[elementName] then
			SUI:Error('MISSING: ' .. elementName .. ' Type:' .. type(elementName))
		else
			UF.Elements:Build(self, elementName, elementsDB[elementName])
		end
	end
	for elementName, _ in pairs(UF.Elements.List) do
		if elementsDB[elementName] then
			ElementUpdate(self, elementName)
		end
	end

	do -- setup indicators
		self.RareElite = self.SpartanArt:CreateTexture(nil, 'BORDER')
		self.RareElite:SetTexture('Interface\\Addons\\SpartanUI\\images\\blank')
		ElementUpdate(self, 'RareElite')

		self.ReadyCheckIndicator = self:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheckIndicator.SingleSize = true
		ElementUpdate(self, 'ReadyCheckIndicator')

		self.QuestMobIndicator = self:CreateTexture(nil, 'OVERLAY')
		ElementUpdate(self, 'QuestMobIndicator')

		-- Position and size
		self.PhaseIndicator = self:CreateTexture(nil, 'OVERLAY')
		self.PhaseIndicator.SingleSize = true
		self.PhaseIndicator:Hide()
		ElementUpdate(self, 'PhaseIndicator')

		do -- Special Icons/Bars
			if unit == 'player' then
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

	local function GroupEnableElement(groupFrame, elementName)
		for _, f in ipairs(groupFrame) do
			if f.EnableElement then
				f:EnableElement(elementName)
			end
		end
	end
	local function GroupDisableElement(groupFrame, elementName)
		for _, f in ipairs(groupFrame) do
			if f.DisableElement then
				f:DisableElement(elementName)
			end
		end
	end
	local function GroupFrameElementUpdate(groupFrame, elementName)
		for _, f in ipairs(groupFrame) do
			if f.ElementUpdate then
				f:ElementUpdate(elementName)
			end
		end
	end
	local function GroupFrameEnable(groupFrame)
		groupFrame:UpdateAll()
		for _, f in ipairs(groupFrame) do
			if f.Enable then
				f:Enable()
			end
		end
	end
	local function GroupFrameDisable(groupFrame)
		groupFrame:UpdateAll()
		for _, f in ipairs(groupFrame) do
			if f.Disable then
				f:Disable()
			end
		end
	end

	for _, group in ipairs(GroupFrames) do
		if UF.frames[group] then
			local function GroupFrameUpdateAll(groupFrame)
				if VisibilityCheck(group) and UF.CurrentSettings[group].enabled then
					if UF.frames[group].visibility then
						RegisterStateDriver(UF.frames[group], UF.frames[group].visibility)
					end
					UF.frames[group]:Show()

					for _, f in ipairs(groupFrame) do
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
			UF.frames[group].Enable = GroupFrameEnable
			UF.frames[group].Disable = GroupFrameDisable
			UF.frames[group].EnableElement = GroupEnableElement
			UF.frames[group].DisableElement = GroupDisableElement
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
