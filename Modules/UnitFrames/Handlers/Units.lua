---@class SUI_UnitFrames : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0
local UF = SUI:GetModule('Component_UnitFrames')

local BuiltFrames = {} ---@type table<UnitFrameName, table>
local FrameData = {} ---@type table<UnitFrameName, table>

local Unit = {
	UnitsLoaded = {},
	arena = {},
	boss = {},
	party = {},
	raid = {},
	GroupContainer = {},
	defaultConfigs = {} ---@type table<string, UFrameSettings>
}

---@param frameName string
---@param builder function
---@param settings? UFrameSettings
---@param options? function
---@param groupbuilder? function
function Unit.Add(frameName, builder, settings, options, groupbuilder)
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
end

---@param frameName UnitFrameName
---@return table
function Unit.Get(frameName)
	return BuiltFrames[frameName]
end

---@param frameName UnitFrameName
---@return UFrameSettings
function Unit.GetConfig(frameName)
	return UF.CurrentSettings[frameName] ---@type UFrameSettings
end

---@param frameName UnitFrameName
---@param frame table
function Unit.BuildFrame(frameName, frame)
	if not FrameData[frameName] then
		return
	end

	FrameData[frameName].builder(frame)

	if Unit.GetConfig(frameName).config.IsGroup then
		if not BuiltFrames[frameName] then
			BuiltFrames[frameName] = {}
		end
		BuiltFrames[frameName][#BuiltFrames[frameName] + 1] = frame
	else
		BuiltFrames[frameName] = frame
	end
end

function Unit.BuildOptions(frameName)
end

UF.Unit = Unit
