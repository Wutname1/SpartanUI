---@class SUI.UF
local UF = SUI.UF

---@class SUI.UF.Elements
---@field Build function
---@field Update? function
---@field OptionsTable? function
---@field ElementSettings? SUI.UF.Elements.Settings
local Elements = {
	Types = {}
}

---@type SUI.UF.Elements.Settings
local DefaultSettings = {
	enabled = false,
	alpha = 1,
	width = 20,
	height = 20,
	size = false,
	scale = 1,
	FrameStrata = nil,
	FrameLevel = nil,
	texture = 'SpartanUI Default',
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
		x = 0,
		y = 0
	},
	rules = {
		duration = {
			mode = 'include'
		},
		whitelist = {},
		blacklist = {},
		sourceUnit = {},
		isPlayerAura = false,
		isBossAura = false,
		isHarmful = false,
		isHelpful = false,
		isRaid = false,
		isStealable = false,
		IsDispellableByMe = false
	},
	config = {
		NoBulkUpdate = false,
		type = 'General'
	}
}

Elements.Types.General = {}
Elements.Types.StatusBar = {}
Elements.Types.Indicator = {}
Elements.Types.Text = {}
Elements.Types.Auras = {}

---@class SUI.UF.Elements.Listing
---@field T table<string, SUI.UF.Elements>
Elements.List = {}

---@class SUIUFFrameSettingList
---@field T table<string, SUI.UF.Elements.list>
Elements.FrameSettings = {}

---@param ElementName string
---@param Build function
---@param Update? function
---@param OptionsTable? function
---@param ElementSettings? SUI.UF.Elements.Settings
function Elements:Register(ElementName, Build, Update, OptionsTable, ElementSettings)
	SUI:CopyData(ElementSettings, DefaultSettings) ---@type SUI.UF.Elements.Settings

	UF.Elements.List[ElementName] = {
		Build = Build,
		Update = Update,
		OptionsTable = OptionsTable,
		ElementSettings = ElementSettings
	}

	Elements.Types[ElementSettings.config.type or 'Other'][ElementName] = ElementName
end

---@param frame table
---@param ElementName SUI.UF.Elements.list
---@param DB? SUI.UF.Elements.Settings
function Elements:Build(frame, ElementName, DB)
	if UF.Elements.List[ElementName] then
		if not frame.elementList then
			frame.elementList = {}
		end

		frame.elementList[ElementName] = UF.Elements.List[ElementName].ElementSettings.config.DisplayName or ElementName
		if frame.unitOnCreate then
			if _G['SUI_UF_' .. frame.unitOnCreate .. '_Holder'] then
				_G['SUI_UF_' .. frame.unitOnCreate .. '_Holder'].elementList = frame.elementList
			end
		end

		UF.Elements.List[ElementName].Build(frame, DB or {})
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
---@return SUI.UF.Elements.Settings --False if the element did not provide a Size updater
function Elements:GetConfig(ElementName)
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
		UF.Elements.List[ElementName].OptionsTable(unitName, OptionSet, DB or (UF.CurrentSettings[unitName] and UF.CurrentSettings[unitName].elements[ElementName]) or {})
		return true
	else
		return false
	end
end

UF.Elements = Elements
