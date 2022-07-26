---@class SUI_UnitFrames : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0
local UF = SUI:GetModule('Component_UnitFrames')

local BuiltFrames = {} ---@type table<UnitFrameName, table>
local FrameData = {} ---@type table<UnitFrameName, table>

local Unit = {
	UnitsLoaded = {}, ---@type table<UnitFrameName, UFrameConfig>
	GroupsLoaded = {}, ---@type table<UnitFrameName, UFrameConfig>
	defaultConfigs = {} ---@type table<string, UFrameSettings>
}

---@param frameName string
---@param builder function
---@param settings? UFrameSettings
---@param options? function
---@param groupbuilder? function
function Unit:Add(frameName, builder, settings, options, groupbuilder)
	---@class SUI_UF_Unit_DB
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

function Unit:BuildGroup(groupName)
	if not Unit.defaultConfigs[groupName].config.IsGroup then
		return
	end

	local holder = CreateFrame('Frame', 'SUI_UF_' .. groupName .. '_Holder')
	holder:Hide()
	holder:SetSize(UF:GroupSize(groupName))

	holder:EnableMouse(false)
	holder:SetMouseClickEnabled(false)

	holder.frames = {}

	BuiltFrames[groupName] = holder

	FrameData[groupName].groupbuilder(BuiltFrames[groupName])
end

---@param frameName UnitFrameName
---@return table
function Unit:Get(frameName)
	-- if Unit:GetConfig(frameName).config.IsGroup then
	-- 	return Unit.GroupContainer[frameName]
	-- else
	return BuiltFrames[frameName]
	-- end
end

---@param frameName UnitFrameName
---@return UFrameSettings
function Unit:GetConfig(frameName)
	return UF.CurrentSettings[frameName] ---@type UFrameSettings
end

---@param frameName UnitFrameName
---@param frame table
function Unit:BuildFrame(frameName, frame)
	if not FrameData[frameName] then
		return
	end

	FrameData[frameName].builder(frame)

	if Unit:GetConfig(frameName).config.IsGroup then
		if not BuiltFrames[frameName] then
			print('NO WHERE TO STORE FRAME FOR ' .. frameName)
			return
		end

		-- BuiltFrames[frameName].frames[#BuiltFrames[frameName].frames + 1] = frame
		table.insert(BuiltFrames[frameName].frames, frame)
	else
		BuiltFrames[frameName] = frame
	end
end

---comment
---@param onlyGroups any
---@return table
function Unit:GetFrameList(onlyGroups)
	if onlyGroups then
		return Unit.GroupsLoaded
	end

	return Unit.UnitsLoaded
end

function Unit:BuildOptions(frameName)
end

UF.Unit = Unit
