---@class SUI_UnitFrames : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0
local UF = SUI:GetModule('Component_UnitFrames')
local Elements = {
	Types = {}
}

local DefaultSettings = {
	enabled = false,
	points = false,
	alpha = 1,
	width = 20,
	height = 20,
	size = false,
	scale = 1,
	FrameStrata = nil,
	FrameLevel = nil,
	texture = nil,
	bg = {
		enabled = false,
		color = {0, 0, 0, .2}
	},
	text = {
		['**'] = {
			enabled = false,
			text = '',
			size = 10,
			SetJustifyH = 'CENTER',
			SetJustifyV = 'MIDDLE',
			position = {
				anchor = 'CENTER',
				x = 0,
				y = 0
			}
		},
		['1'] = {
			position = {}
		},
		['2'] = {
			position = {}
		}
	},
	position = {
		anchor = 'CENTER',
		relativeTo = 'Frame',
		relativePoint = nil,
		x = 0,
		y = 0
	},
	config = {
		NoBulkUpdate = false,
		type = 'General'
	}
} ---@type ElementSettings

Elements.Types.General = {}
Elements.Types.StatusBar = {}
Elements.Types.Indicator = {}
Elements.Types.Text = {}
Elements.Types.Auras = {}

---@class SUIUFElement
---@field Build function
---@field Update? function
---@field OptionsTable? function
---@field ElementSettings? ElementSettings

---@class SUIUFElementList
---@field T table<string, SUIUFElement>
Elements.List = {}

---@class SUIUFFrameSettingList
---@field T table<string, UnitFrameElement>
Elements.FrameSettings = {}

---@class ElementConfig
---@field NoBulkUpdate boolean

---@param ElementName string
---@param Build function
---@param Update? function
---@param OptionsTable? function
---@param ElementSettings? ElementSettings
function Elements:Register(ElementName, Build, Update, OptionsTable, ElementSettings)
	SUI:CopyData(ElementSettings, DefaultSettings) ---@type ElementSettings

	UF.Elements.List[ElementName] = {
		Build = Build,
		Update = Update,
		OptionsTable = OptionsTable,
		ElementSettings = ElementSettings
	}

	Elements.Types[ElementSettings.config.type or 'Other'][ElementName] = ElementName
end

---@param frame table
---@param ElementName UnitFrameElement
---@param DB? ElementSettings
function Elements:Build(frame, ElementName, DB)
	if UF.Elements.List[ElementName] then
		if not frame.elementList then
			frame.elementList = {}
		end

		table.insert(frame.elementList, ElementName)
		UF.Elements.List[ElementName].Build(frame, DB or UF.CurrentSettings[frame.unitOnCreate].elements[ElementName] or {})
	end
end

---@param frame table
---@param ElementName string
---@param DB? table
---@return boolean --False if the element did not provide an updater
function Elements:Update(frame, ElementName, DB)
	if UF.Elements.List[ElementName] and UF.Elements.List[ElementName].Update then
		UF.Elements.List[ElementName].Update(frame, DB or UF.CurrentSettings[frame.unitOnCreate].elements[ElementName] or {})
		return true
	else
		return false
	end
end

---@param ElementName string
---@return ElementSettings --False if the element did not provide a Size updater
function Elements:GetConfig(ElementName, frame)
	if frame then
		local unit = frame.unitOnCreate
	end

	if UF.Elements.List[ElementName] and UF.Elements.List[ElementName].ElementSettings then
		return UF.Elements.List[ElementName].ElementSettings
	else
		return DefaultSettings
	end
end

---@param unitName string
---@param ElementName string
---@param OptionSet AceConfigOptionsTable
---@param DB? table
---@return boolean --False if the element did not provide options customizer
function Elements:Options(unitName, ElementName, OptionSet, DB)
	if UF.Elements.List[ElementName] and UF.Elements.List[ElementName].OptionsTable then
		UF.Elements.List[ElementName].OptionsTable(
			unitName,
			OptionSet or {},
			DB or UF.CurrentSettings[unitName].elements[ElementName] or {}
		)
		return true
	else
		return false
	end
end

UF.Elements = Elements
