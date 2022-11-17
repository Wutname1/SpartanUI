---@class SUI.UF
local UF = SUI.UF

local BuiltFrames = {} ---@type table<UnitFrameName, table>
local FrameData = {} ---@type table<UnitFrameName, table>

local Unit = {
	UnitsLoaded = {}, ---@type table<UnitFrameName, SUI.UF.Unit.Config>
	GroupsLoaded = {}, ---@type table<UnitFrameName, SUI.UF.Unit.Config>
	defaultConfigs = {} ---@type table<string, SUI.UF.Unit.Settings>
}

---@param frameName string
---@param builder function
---@param settings? SUI.UF.Unit.Settings
---@param options? function
---@param groupbuilder? function
---@param updater? function
function Unit:Add(frameName, builder, settings, options, groupbuilder, updater)
	---@type SUI.UF.Unit.Settings
	local Defaults = {
		enabled = true,
		width = 180,
		scale = 1,
		moved = false,
		visibility = {
			alphaDelay = 1,
			hideDelay = 3,
			showAlways = false,
			showInCombat = true,
			showWithTarget = false,
			showInRaid = false,
			showInParty = false
		},
		position = {
			point = 'BOTTOM',
			relativeTo = 'Frame',
			relativePoint = 'BOTTOM',
			xOfs = 0,
			yOfs = 0
		},
		elements = {},
		config = {
			IsGroup = false
		}
	}
	local ElementList = UF.Elements.List

	FrameData[frameName] = {
		builder = builder,
		updater = updater,
		settings = settings,
		options = options,
		groupbuilder = groupbuilder
	}

	for elementName, elementData in pairs(ElementList) do
		Defaults.elements[elementName] = elementData.ElementSettings
	end

	Unit.defaultConfigs[frameName] = SUI:CopyData(settings, Defaults)

	Unit.UnitsLoaded[frameName] = Unit.defaultConfigs[frameName].config
	if Unit.defaultConfigs[frameName].config.IsGroup then
		Unit.GroupsLoaded[frameName] = Unit.defaultConfigs[frameName].config
	end
end

---@param frame table
function Unit:Update(frame)
	if not FrameData[frame.unitOnCreate].updater then
		return
	end
	FrameData[frame.unitOnCreate].updater(frame)
end

---Build a group holder
---@param groupName string
---@return SUI.UF.Unit.Frame?
function Unit:BuildGroup(groupName)
	if not Unit.defaultConfigs[groupName].config.IsGroup then
		return
	end

	local holder = CreateFrame('Frame', 'SUI_UF_' .. groupName .. '_Holder')
	holder:Hide()
	holder:SetSize(UF:GroupSize(groupName))

	holder.frames = {}
	holder.config = UF.Unit:GetConfig(groupName)

	BuiltFrames[groupName] = holder

	FrameData[groupName].groupbuilder(BuiltFrames[groupName])

	return BuiltFrames[groupName]
end

---Toggles the force display of a frame
---@param frame string|SUI.UF.Unit.Frame
function Unit:ToggleForceShow(frame)
	if type(frame) == 'string' then
		frame = Unit:Get(frame)
	end
	if frame.isForced then
		Unit:UnforceShow(frame)
	else
		Unit:ForceShow(frame)
	end
end

---Force a frame to show
---@param frame SUI.UF.Unit.Frame
function Unit:ForceShow(frame)
	if InCombatLockdown() then
		return
	end

	if type(frame) == 'string' then
		frame = Unit:Get(frame)
	end

	if frame.header and frame.frames then
		for i, childFrame in ipairs(frame.frames) do
			print(childFrame:GetName())
			childFrame:SetID(i)
			Unit:ForceShow(childFrame)
		end
		frame.header:Show()
		return
	end

	if not frame.isForced then
		frame.oldUnit = frame.unit
		frame.unit = 'player'
		frame.isForced = true
		frame.oldOnUpdate = frame:GetScript('OnUpdate')
	end

	frame:SetScript('OnUpdate', nil)
	frame.forceShowAuras = true
	UnregisterUnitWatch(frame)
	RegisterUnitWatch(frame, true)

	frame:EnableMouse(false)

	frame:Show()

	if frame.UpdateAll then
		frame:UpdateAll()
	end

	if _G[frame:GetName() .. 'Target'] then
		self:ForceShow(_G[frame:GetName() .. 'Target'])
	end

	if _G[frame:GetName() .. 'Pet'] then
		self:ForceShow(_G[frame:GetName() .. 'Pet'])
	end
end

---If the frame is forced to show, unforce it
---@param frame any
function Unit:UnforceShow(frame)
	if InCombatLockdown() then
		return
	end

	if frame.header and frame.frames then
		for _, childFrame in ipairs(frame.frames) do
			Unit:UnforceShow(childFrame)
		end
		frame.header:Hide()
		return
	end

	if not frame.isForced then
		return
	end
	frame.forceShowAuras = nil
	frame.isForced = nil

	-- Ask the SecureStateDriver to show/hide the frame for us
	UnregisterUnitWatch(frame)
	RegisterUnitWatch(frame)

	frame:EnableMouse(true)

	if frame.oldOnUpdate then
		frame:SetScript('OnUpdate', frame.oldOnUpdate)
		frame.oldOnUpdate = nil
	end

	frame.unit = frame.oldUnit or frame.unit

	if _G[frame:GetName() .. 'Target'] then
		self:UnforceShow(_G[frame:GetName() .. 'Target'])
	end

	if _G[frame:GetName() .. 'Pet'] then
		self:UnforceShow(_G[frame:GetName() .. 'Pet'])
	end

	if frame.UpdateAll then
		frame:UpdateAll()
	end
end

---Returns the unitframe object
---@param frameName UnitFrameName
---@return SUI.UF.Unit.Frame
function Unit:Get(frameName)
	-- if Unit:GetConfig(frameName).config.IsGroup then
	-- 	return Unit.GroupContainer[frameName]
	-- else
	return BuiltFrames[frameName]
	-- end
end

---Gets the current active settings for a unit frame
---@param frameName UnitFrameName
---@return SUI.UF.Unit.Settings
function Unit:GetConfig(frameName)
	return UF.CurrentSettings[frameName] ---@type SUI.UF.Unit.Settings
end

---Adds the elements needed to the passed frame for the specified unit
---@param frameName UnitFrameName
---@param frame table
function Unit:BuildFrame(frameName, frame)
	if not FrameData[frameName] then
		return
	end

	FrameData[frameName].builder(frame)
	frame.config = UF.Unit:GetConfig(frameName)

	if Unit:GetConfig(frameName).config.IsGroup then
		if not BuiltFrames[frameName] then
			print('NO WHERE TO STORE FRAME FOR ' .. frameName)
			return
		end

		table.insert(BuiltFrames[frameName].frames, frame)
	else
		BuiltFrames[frameName] = frame
	end
end

---Gets a table of all the frames that are currently loaded and their default settings
---@param onlyGroups any
---@return table<UnitFrameName, SUI.UF.Unit.Config>
function Unit:GetFrameList(onlyGroups)
	if onlyGroups then
		return Unit.GroupsLoaded
	end

	return Unit.UnitsLoaded
end

---Used to add unit specific frame options to the passes OptionSet
---@param frameName UnitFrameName
---@param OptionsSet AceConfigOptionsTable
function Unit:BuildOptions(frameName, OptionsSet)
	if not FrameData[frameName] or not FrameData[frameName].options then
		return
	end

	FrameData[frameName].options(OptionsSet)
end

---Returns if the frame is used to display friendly units
---@param unit UnitFrameName
---@return boolean
function Unit:isFriendly(unit)
	local config = Unit:GetConfig(unit)

	if not unit then
		return false
	end

	return config.config.isFriendly
end

UF.Unit = Unit
