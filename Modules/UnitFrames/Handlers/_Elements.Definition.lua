---@class ElementProps
---@field DB SUI.UnitFrame.Element.Settings
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

---@class SUI.UnitFrame.Element.Settings
---@field enabled boolean
---@field scale integer
---@field points boolean|table|string
---@field size integer|boolean
---@field FrameStrata FrameStrata
---@field FrameLevel integer
---@field config? ElementConfig
---@field position SUI.UnitFrame.Element.Positioning
---@field rules SUI.UnitFrame.Aura.Rules
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

---@class SUI.UnitFrame.Element.Positioning
---@field anchor AnchorPoint
---@field relativeTo SUI.UnitFrame.Elements
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
---@field position SUI.UnitFrame.Element.Positioning
local ElementTextData = {
	enabled = false,
	text = '',
	size = 10,
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE'
}

---@alias SUI.UnitFrame.Elements
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

---@class SUI.UnitFrame.Element.Details
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

---@class UnitAuraInfo
---@field applications number
---@field auraInstanceID number
---@field canApplyAura boolean
---@field charges number
---@field dispelName string?
---@field duration number
---@field expirationTime number
---@field icon number
---@field isBossAura boolean
---@field isFromPlayerOrPlayerPet boolean
---@field isHarmful boolean
---@field isPlayerAura boolean
---@field isHelpful boolean
---@field isNameplateOnly boolean
---@field isRaid boolean
---@field isStealable boolean
---@field maxCharges number
---@field name string
---@field nameplateShowAll boolean
---@field nameplateShowPersonal boolean
---@field points table Variable returns - Some auras return additional values that typically correspond to something shown in the tooltip, such as the remaining strength of an absorption effect.
---@field sourceUnit string?
---@field spellId number
---@field timeMod number
local UnitAuraInfo = {}

---@class SUI.UnitFrame.Aura.Rules.Durations
---@field enabled boolean
---@field maxTime number
---@field minTime number
local SUIUnitFrameAuraRulesDurations = {}

---@class SUI.UnitFrame.Aura.Rules
---@field duration SUI.UnitFrame.Aura.Rules.Durations
---@field isPlayerAura boolean
---@field isBossAura boolean
---@field isHarmful boolean
---@field isHelpful boolean
---@field isRaid boolean
---@field isStealable boolean
---@field IsDispellableByMe boolean
---@field whitelist table<string, boolean>
---@field blacklist table<string, boolean>
---@field sourceUnit table<string, boolean>
local SUIUnitFrameAuraRules = {}
