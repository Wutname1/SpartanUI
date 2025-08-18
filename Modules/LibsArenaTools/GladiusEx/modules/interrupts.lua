local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local fn = LibStub("LibFunctional-1.0")
local timer

-- V: heavily inspired by Jaxington's Gladius-With-Interrupts
-- K: Improved

local defaults = {
	interruptPrio = 3.0,
}

local Interrupt = GladiusEx:NewGladiusExModule("Interrupts", defaults, defaults)

local INTERRUPTS = GladiusEx.Data.Interrupts()

local CLASS_INTERRUPT_MODIFIERS = GladiusEx.Data.InterruptModifiers()

function Interrupt:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	if not self.frame then
		self.frame = {}
	end
	self.interrupts = {}
end

function Interrupt:OnDisable()
	self:UnregisterAllEvents()
	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
	end
end

function Interrupt:COMBAT_LOG_EVENT_UNFILTERED(event)
	Interrupt:CombatLogEvent(event, CombatLogGetCurrentEventInfo())
end

function Interrupt:CombatLogEvent(_, ...)
	local subEvent = select(2, ...)
	local destGUID = select(8, ...)
	local spellID = select(12, ...)

	local unit = GladiusEx:GetUnitIdByGUID(destGUID)
	if not unit then return end

	if subEvent ~= "SPELL_CAST_SUCCESS" and subEvent ~= "SPELL_INTERRUPT" then
		return
	end
	-- it is necessary to check ~= false, as if the unit isn't casting a channeled spell, it will be nil
	if subEvent == "SPELL_CAST_SUCCESS" and select(8, UnitChannelInfo(unit)) ~= false then
		-- not interruptible
		return
	end
	if INTERRUPTS[spellID] == nil then return end
	local duration = INTERRUPTS[spellID].duration
	if not duration then return end
	local button = GladiusEx.buttons[unit]
	if not button then return end

	local _, _, class = UnitClass(unit)
	if class == 7 then -- Shaman
		for buff, mult in ipairs(CLASS_INTERRUPT_MODIFIERS) do
			if AuraUtil.FindAuraByName(buff, unit, "HELPFUL") then
				duration = duration * mult
			end
		end
	end
	self:UpdateInterrupt(unit, spellID, duration)

end

function Interrupt:UpdateInterrupt(unit, spellid, duration, oldTime)
	local t = GetTime()
	if spellid and duration then
		self.interrupts[unit] = {spellid, t, duration}
	elseif oldTime then
		if t == oldTime then -- this ensures we don't overwrite a new interrupt with an old c_timer
			self.interrupts[unit] = nil
		end
	end

	self:SendMessage("GLADIUSEX_INTERRUPT", unit)

	if oldTime or duration == nil then return end -- avoid triggering the c_timer again

	-- K: Clears the interrupt after end of duration (in case no new UNIT_AURA ticks clears it)
	C_Timer.After(
		duration + 0.1,
		function()
			self:UpdateInterrupt(unit, spellid, nil, t+duration+0.1)
		end
	)
end

function Interrupt:GetInterruptFor(unit)
	local int = self.interrupts and self.interrupts[unit]
	if not int then return end

	local spellid, startedAt, duration = unpack(int)
	local endsAt = startedAt + duration
	if GetTime() > endsAt then
		self.interrupts[unit] = nil
	else

	local name, icon = nil

	if C_Spell and C_Spell.GetSpellTexture then
		name = C_Spell.GetSpellName(spellid)
		icon = C_Spell.GetSpellTexture(spellid)
	else
		name, _, icon = GetSpellInfo(spellid)
	end
		return name, icon, duration, endsAt, self.db[unit].interruptPrio
	end
end

function Interrupt:GetOptions(unit)
	-- TODO: enable/disable INTERRUPT_SPEC_MODIFIER, since they are talents, we're just guessing
	return {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				sep2 = {
					type = "description",
					name = "This module shows interrupt durations over the Arena Enemy Class Icons when they are interrupted.",
					width = "full",
					order = 17,
				},
				interruptPrio = {
					type = "range",
					name = "InterruptPrio",
					desc = "Sets the priority of interrupts (as compared to regular Class Icon auras)",
					disabled = function() return not self:IsUnitEnabled(unit) end,
					softMin = 0.0, softMax = 10, step = 0.1,
					order = 19,
				},
			},
		},
	}
end
