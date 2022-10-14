local _G, SUI = _G, SUI
local UF = SUI.UF ---@class SUI_UnitFrames
----------------------------------------------------------------------------------------------------
---comment
---@param frameName UnitFrameName
---@return integer width
---@return integer height
function UF:GroupSize(frameName)
	local CurFrameOpt = UF.CurrentSettings[frameName]
	local FrameHeight = UF:CalculateHeight(frameName)
	local height = (CurFrameOpt.unitsPerColumn or 10) * (FrameHeight + (CurFrameOpt.yOffset or 0))
	local width = (CurFrameOpt.maxColumns or 4) * (CurFrameOpt.width + (CurFrameOpt.columnSpacing or 1))
	return width, height
end

function UF:CalculateHeight(frameName)
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
	self.DB = UF.CurrentSettings[unit]
	if self.isChild then
		self.childType = 'pet'
		if self == _G[self:GetName() .. 'Target'] then
			self.childType = 'target'
		end
	end

	self.unitOnCreate = unit
	self.elementList = {}

	-- Build a function that updates the size of the frame and sizes of elements
	local function UpdateSize()
		if not InCombatLockdown() then
			if self.scale then
				self:scale(self.DB.scale, true)
			else
				self:SetScale(self.DB.scale)
			end
			self:SetSize(self.DB.width, UF:CalculateHeight(unit))
		end
	end

	local function UpdateAll()
		self.DB = UF.CurrentSettings[self.unitOnCreate]
		UpdateSize()

		UF.Unit:Update(self)
		local elementsDB = self.DB.elements
		-- Check that its a frame
		-- Loop all elements and update their status
		for elementName, _ in pairs(self.elementList) do
			if not elementsDB[elementName] then
				SUI:Error('MISSING: ' .. elementName .. ' Type:' .. type(elementName))
			else
				self:ElementUpdate(elementName)
			end
		end

		for element, _ in pairs(self.elementList) do
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
						if elementsDB[element].bg.color and type(elementsDB[element].bg.color) == 'table' then
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
		self:UpdateAllElements('OnUpdate')
		self:UpdateTags()
	end

	---@param frame table
	---@param elementName UnitFrameElement
	local function ElementUpdate(frame, elementName)
		if not frame[elementName] then
			return
		end
		local data = self.DB.elements[elementName]
		local element = frame[elementName]
		element.DB = data

		if data.enabled and frame.IsBuilt then
			frame:EnableElement(elementName)
		else
			frame:DisableElement(elementName)
		end

		-- Call the elements update function
		UF.Elements:Update(frame, elementName)

		if UF.Elements:GetConfig(elementName).config.NoBulkUpdate then
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
		if data.points then
			if type(data.points) == 'string' then
				element:SetAllPoints(frame[data.points])
			elseif data.points and type(data.points) == 'table' then
				for _, key in pairs(data.points) do
					if key.relativeTo == 'Frame' then
						element:SetPoint(key.anchor, frame, key.anchor, key.x, key.y)
					else
						element:SetPoint(key.anchor, frame[key.relativeTo], key.anchor, key.x, key.y)
					end
				end
			else
				element:SetAllPoints(frame)
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

	self.raised = CreateFrame('Frame', nil, self)
	local level = self:GetFrameLevel() + 100
	self.raised:SetFrameLevel(level)
	self.raised.__owner = self

	self.UpdateAll = UpdateAll
	self.ElementUpdate = ElementUpdate

	UpdateSize()

	local elementDB = self.DB.elements
	self.elementDB = elementDB

	UF.Unit:BuildFrame(unit, self)

	for elementName, _ in pairs(self.elementList) do
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
	self.IsBuilt = true

	return self
end

local function VisibilityCheck(group)
	if UF.CurrentSettings[group].showParty and (IsInGroup() and not IsInRaid()) then
		return true
	end
	if UF.CurrentSettings[group].showRaid and IsInRaid() then
		return true
	end
	if UF.CurrentSettings[group].showSolo and not (IsInGroup() or IsInRaid()) then
		return true
	end

	return false
end

function UF:SpawnFrames()
	SUIUF:RegisterStyle('SpartanUI_UnitFrames', CreateUnitFrame)
	SUIUF:SetActiveStyle('SpartanUI_UnitFrames')

	-- Spawn all main frames
	for frameName, config in pairs(UF.Unit:GetFrameList()) do
		if config.IsGroup then
			UF.Unit[frameName] = UF.Unit:BuildGroup(frameName)
		else
			UF.Unit[frameName] = SUIUF:Spawn(frameName, 'SUI_UF_' .. frameName)

			-- Disable objects based on settings
			UF.Unit[frameName]:UpdateAll()

			if not UF.CurrentSettings[frameName].enabled then
				UF.Unit[frameName]:Disable()
			end
		end
	end

	local function GroupEnableElement(groupFrame, elementName)
		for _, f in ipairs(groupFrame.frames) do
			if f.EnableElement then
				f:EnableElement(elementName)
			end
		end
	end
	local function GroupDisableElement(groupFrame, elementName)
		for _, f in ipairs(groupFrame.frames) do
			if f.DisableElement then
				f:DisableElement(elementName)
			end
		end
	end
	local function GroupFrameElementUpdate(groupFrame, elementName)
		for _, f in ipairs(groupFrame.frames) do
			if f.ElementUpdate then
				f:ElementUpdate(elementName)
			end
		end
	end
	local function GroupFrameEnable(groupFrame)
		groupFrame:UpdateAll()
		for _, f in ipairs(groupFrame.frames) do
			if f.Enable then
				f:Enable()
			end
		end
	end
	local function GroupFrameDisable(groupFrame)
		groupFrame:UpdateAll()
		for _, f in ipairs(groupFrame.frames) do
			if f.Disable then
				f:Disable()
			end
		end
	end

	for groupName, _ in pairs(UF.Unit:GetFrameList(true)) do
		local groupElement = UF.Unit:Get(groupName)
		if groupElement then
			local firstElement = groupElement.header or groupElement.frames[1]
			if firstElement then
				local function GroupFrameUpdateAll(groupFrame)
					if VisibilityCheck(groupName) and UF.CurrentSettings[groupName].enabled then
						if firstElement.visibility then
							RegisterStateDriver(firstElement, firstElement.visibility)
						end
						firstElement:Show()

						for i, f in pairs(groupFrame.frames) do
							if f.UpdateAll then
								f:UpdateAll()
							end
						end
					else
						UnregisterStateDriver(firstElement, 'visibility')
						firstElement:Hide()
					end
				end

				groupElement.UpdateAll = GroupFrameUpdateAll
				groupElement.ElementUpdate = GroupFrameElementUpdate
				groupElement.Enable = GroupFrameEnable
				groupElement.Disable = GroupFrameDisable
				groupElement.EnableElement = GroupEnableElement
				groupElement.DisableElement = GroupDisableElement
			end
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
	for frameName, config in pairs(UF.Unit:GetFrameList()) do
		local frame = UF.Unit:Get(frameName)
		if frame and frame.UpdateAll then
			frame:UpdateAll()
		elseif not config.isChild then
			SUI:Error('Unable to find updater for ' .. frameName, 'Unit Frames')
		end
	end

	UF:UpdateGroupFrames()
end

function UF:UpdateGroupFrames(event, ...)
	for frameName, _ in pairs(UF.Unit:GetFrameList(true)) do
		local frame = UF.Unit:Get(frameName)
		if frame then
			frame:UpdateAll()
		end
	end
end
