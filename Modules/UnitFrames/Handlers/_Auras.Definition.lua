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

---@class SUI.UF.Auras.Rules
---@field duration SUI.UF.Auras.Rules.Durations
---@field isPlayerAura boolean
---@field isBossAura boolean
---@field isHarmful boolean
---@field isHelpful boolean
---@field isMount boolean
---@field isRaid boolean
---@field isStealable boolean
---@field IsDispellableByMe boolean
---@field whitelist table<string, boolean>
---@field blacklist table<string, boolean>
---@field sourceUnit table<string, boolean>
local SUIUnitFrameAuraRules = {}

---@class SUI.UF.Auras.Rules.Durations
---@field enabled boolean
---@field maxTime number
---@field minTime number
local SUIUnitFrameAuraRulesDurations = {}
