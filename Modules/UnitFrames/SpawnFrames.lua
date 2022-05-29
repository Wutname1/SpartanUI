local _G, SUI = _G, SUI
local UF = SUI.UF ---@class SUI_UnitFrames
----------------------------------------------------------------------------------------------------
local FramesList = {
	'pet',
	'target',
	'targettarget',
	'focus',
	'focustarget',
	'player'
}

local GroupFrames = {'raid', 'party'}
if SUI.IsRetail then
	table.insert(GroupFrames, 'boss')
end
if not SUI.IsClassic then
	table.insert(GroupFrames, 'arena')
end

if SUI.IsClassic then
	FramesList = {
		'pet',
		'target',
		'targettarget',
		'player'
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
	self.elementList = {}

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
		for _, elementName in pairs(self.elementList) do
			if not elementsDB[elementName] then
				SUI:Error('MISSING: ' .. elementName .. ' Type:' .. type(elementName))
			else
				self:ElementUpdate(elementName)
			end
		end

		for _, element in ipairs(self.elementList) do
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

		if UF.Elements:GetConfig(elementName).NoBulkUpdate then
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
		elseif data.size then
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

	local elementDB = UF.CurrentSettings[unit].elements
	self.elementDB = elementDB

	UF.Frames.Build(self)

	for _, elementName in pairs(self.elementList) do
		if elementDB[elementName] then
			ElementUpdate(self, elementName)
		end
	end

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
		UF.Frames[b] = SUIUF:Spawn(b, 'SUI_UF_' .. b)

		-- Disable objects based on settings
		UF.Frames[b]:UpdateAll()

		if not UF.CurrentSettings[b].enabled then
			UF.Frames[b]:Disable()
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
			UF.Frames[group] = grpFrame
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
	UF.Frames.party = party

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
	UF.Frames.raid = raid

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
		if UF.Frames[group] then
			local function GroupFrameUpdateAll(groupFrame)
				if VisibilityCheck(group) and UF.CurrentSettings[group].enabled then
					if UF.Frames[group].visibility then
						RegisterStateDriver(UF.Frames[group], UF.Frames[group].visibility)
					end
					UF.Frames[group]:Show()

					for _, f in ipairs(groupFrame) do
						if f.UpdateAll then
							f:UpdateAll()
						end
					end
				else
					UnregisterStateDriver(UF.Frames[group], 'visibility')
					UF.Frames[group]:Hide()
				end
			end

			UF.Frames[group].UpdateAll = GroupFrameUpdateAll
			UF.Frames[group].ElementUpdate = GroupFrameElementUpdate
			UF.Frames[group].Enable = GroupFrameEnable
			UF.Frames[group].Disable = GroupFrameDisable
			UF.Frames[group].EnableElement = GroupEnableElement
			UF.Frames[group].DisableElement = GroupDisableElement
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
		if UF.Frames[v] and UF.Frames[v].UpdateAll then
			UF.Frames[v]:UpdateAll()
		else
			SUI:Error('Unable to find updater for ' .. v, 'Unit Frames')
		end
	end

	UF:UpdateGroupFrames()
end

function UF:UpdateGroupFrames(event, ...)
	for _, v in ipairs(GroupFrames) do
		if UF.Frames[v] then
			UF.Frames[v]:UpdateAll()
		end
	end
end
