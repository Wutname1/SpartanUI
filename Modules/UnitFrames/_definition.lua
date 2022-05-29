---@class ElementSettings
---@field enabled boolean
---@field scale integer
---@field bgTexture string|boolean
---@field points boolean|table|string
---@field size integer|boolean
---@field FrameStrata FrameStrata
---@field FrameLevel integer
---@field position ElementPositioning
local ElementSettings = {
	enabled = false,
	bgTexture = false,
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
		color = false
	}
}

---@class ElementPositioning
---@field anchor AnchorPoint
---@field relativeTo UnitFrameElement
---@field relativePoint AnchorPoint
local position = {
	anchor = 'CENTER',
	relativeTo = 'Frame',
	relativePoint = nil,
	x = 0,
	y = 0
}

---@class ElementTextData
---@field SetJustifyH JustifyH
---@field SetJustifyV JustifyV
---@field position ElementPositioning
local text = {
	enabled = false,
	text = '',
	size = 10,
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE'
}

---@alias UnitFrameElement
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
---|"PVPIndicator"
---|"QuestMobIndicator"
---|"RaidTargetIndicator"
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

---@class UFrameSettings
---@field position ElementPositioning
---@field elements table<string, ElementSettings>
---@field visibility UFrameVisibility
local UFrameSettings = {
	enabled = true,
	width = 180,
	scale = 1,
	moved = false
}

---@class UFrameVisibility
local visibility = {
	alphaDelay = 1,
	hideDelay = 3,
	showAlways = false,
	showInCombat = true,
	showWithTarget = false,
	showInRaid = false,
	showInParty = false
}
