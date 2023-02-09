local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local element = CreateFrame('Frame', '$parent_AuraWatch', frame)
	element.PostUpdateIcon = function(_, unit, button, index, position, duration, expiration, debuffType, isStealable)
		if not button.spellID then return end
		local settings = button.setting
		local SpellKnown = IsSpellKnown(button.spellID)
		if settings.onlyIfCastable and not SpellKnown then button:Hide() end
		if InCombatLockdown() and not settings.displayInCombat then button:Hide() end
	end
	frame.AuraWatch = element
end

---@param frame table
---@param data? table
local function Update(frame, data)
	local element = frame.AuraWatch
	local DB = data or element.DB
	element.size = DB.size or 20
	element.watched = DB.watched
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
---@param DB? table
local function Options(unitName, OptionSet, DB) end

---@class SUI.UF.Unit.Settings.AuraWatch.Watched
---@field anyUnit boolean
---@field onlyShowMissing boolean
---@field point string
---@field xOffset number
---@field yOffset number
local watched = {}

---@class SUI.UF.Unit.Settings.AuraWatch : SUI.UF.Unit.Settings
---@field watched table<integer, SUI.UF.Unit.Settings.AuraWatch.Watched>
local a = {}

---@class SUI.UF.Unit.Settings.AuraWatch
local Settings = {
	size = 20,
	watched = {
		['**'] = { onlyIfCastable = true, anyUnit = true, onlyShowMissing = true, point = 'BOTTOM', xOffset = 0, yOffset = 0, displayInCombat = false },
		[1126] = {}, -- Mark of the wild
		[1459] = {}, -- Arcane Intellect
		[21562] = {}, -- Power Word: Fortitude
	},
	config = {
		type = 'Auras',
	},
}

UF.Elements:Register('AuraWatch', Build, Update, Options, Settings)
