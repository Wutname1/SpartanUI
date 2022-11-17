---@class ElementProps
---@field DB SUI.UnitFrame.Elements.Settings
local ElementProps = {}

---@class ElementConfig
---@field NoBulkUpdate? boolean
---@field type? ElementType
---@field DisplayName? string
---@field Description? string
local ElementConfig = {}

---@alias ElementType
---|'Indicator'
---|'StatusBar'
---|'Text'
---|'Auras'
---|'General'

---@class SUI.UnitFrame.Elements.Settings
---@field enabled boolean
---@field scale integer
---@field points boolean|table|string
---@field size integer|boolean
---@field FrameStrata FrameStrata
---@field FrameLevel integer
---@field config? ElementConfig
---@field position SUI.UnitFrame.Elements.Positioning
---@field rules SUI.UnitFrame.Auras.Rules
local ElementSettings = {
	enabled = false,
	points = false,
	alpha = 1,
	width = 20,
	height = 20,
	size = false,
	scale = 1,
	FrameStrata = nil,
	FrameLevel = nil,
	bg = {
		enabled = false,
		texture = nil,
		color = false
	}
}

---@class SUI.UnitFrame.Elements.Positioning
---@field anchor AnchorPoint
---@field relativeTo SUI.UnitFrame.Elements.list
---@field relativePoint AnchorPoint
local ElementPositioning = {
	anchor = 'CENTER',
	relativeTo = 'Frame',
	relativePoint = nil,
	x = 0,
	y = 0
}

---@class FramePositioning
---@field point AnchorPoint
---@field relativePoint AnchorPoint
---@field xOfs integer
---@field yOfs integer
local FramePositioning = {}

---@class ElementTextData
---@field SetJustifyH JustifyH
---@field SetJustifyV JustifyV
---@field position SUI.UnitFrame.Elements.Positioning
local ElementTextData = {
	enabled = false,
	text = '',
	size = 10,
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE'
}

---@alias SUI.UnitFrame.Elements.list
---|"AdditionalPower"
---|"AssistantIndicator"
---|"AuraBars"
---|"Auras"
---|"Buffs"
---|"Castbar"
---|"ClassIcon"
---|"ClassPower"
---|"CombatIndicator"
---|"Debuffs"
---|"DispelHighlight"
---|"GroupRoleIndicator"
---|"HappinessIndicator"
---|"Health"
---|"LeaderIndicator"
---|"Name"
---|"PhaseIndicator"
---|"Portrait"
---|"Power"
---|"PvPIndicator"
---|"QuestMobIndicator"
---|"RaidTargetIndicator"
---|"RaidRoleIndicator"
---|"Range"
---|"RareElite"
---|"ReadyCheckIndicator"
---|"RestingIndicator"
---|"ResurrectIndicator"
---|"Runes"
---|"SpartanArt"
---|"StatusText"
---|"SUI_RaidGroup"
---|"ThreatIndicator"
---|"Totems"

---@class SUI.UnitFrame.Elements.Details
---@field AdditionalPower ElementProps
---@field AssistantIndicator ElementProps
---@field AuraBars ElementProps
---@field Auras ElementProps
---@field Buffs ElementProps
---@field Castbar ElementProps
---@field ClassIcon ElementProps
---@field ClassPower ElementProps
---@field CombatIndicator ElementProps
---@field Debuffs ElementProps
---@field DispelHighlight ElementProps
---@field GroupRoleIndicator ElementProps
---@field HappinessIndicator ElementProps
---@field Health ElementProps
---@field LeaderIndicator ElementProps
---@field Name ElementProps
---@field PhaseIndicator ElementProps
---@field Portrait ElementProps
---@field Power ElementProps
---@field PvPIndicator ElementProps
---@field QuestMobIndicator ElementProps
---@field RaidTargetIndicator ElementProps
---@field RaidRoleIndicator ElementProps
---@field Range ElementProps
---@field RareElite ElementProps
---@field ReadyCheckIndicator ElementProps
---@field RestingIndicator ElementProps
---@field ResurrectIndicator ElementProps
---@field Runes ElementProps
---@field SpartanArt ElementProps
---@field StatusText ElementProps
---@field SUI_RaidGroup ElementProps
---@field ThreatIndicator ElementProps
---@field Totems ElementProps
local SUIElements = {}
