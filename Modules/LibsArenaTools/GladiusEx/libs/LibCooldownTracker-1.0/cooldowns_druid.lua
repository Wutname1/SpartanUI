-- ================ DRUID ================

-- Specs
local SPEC_DRUID_BALANCE  = 102
local SPEC_DRUID_FERAL    = 103
local SPEC_DRUID_GUARDIAN = 104
local SPEC_DRUID_RESTO    = 105

-- Druid/baseline
LCT_SpellData[16979] = 102401 -- Bear
LCT_SpellData[49376] = 102401 -- Cat
LCT_SpellData[102416] = 102401 -- Aquatic
LCT_SpellData[102417] = 102401 -- Travel
LCT_SpellData[102383] = 102401 -- Moonkin
-- Dash
LCT_SpellData[1850] = {
	class = "DRUID",
	duration = 10,
	cooldown = 120
}
-- Growl
LCT_SpellData[6795] = {
	class = "DRUID",
	cooldown = 8
}
-- Barkskin
LCT_SpellData[22812] = {
	class = "DRUID",
	defensive = true,
	duration = 8,
	cooldown = 60
}
LCT_SpellData[77764] = 77761
LCT_SpellData[106898] = 77761
-- Druid/mixed
-- Innervate
LCT_SpellData[29166] = {
	class = "DRUID",
	talent = true,
	cooldown = 180,
}
-- Remove Corruption
LCT_SpellData[2782] = {
	class = "DRUID",
	specID = { SPEC_DRUID_BALANCE, SPEC_DRUID_FERAL, SPEC_DRUID_GUARDIAN },
	dispel = true,
	cooldown_starts_on_dispel = true,
	cooldown = 8
}
-- Druid/talents
-- Tiger Dash
LCT_SpellData[252216] = {
	class = "DRUID",
	talent = true,
	duration = 5,
	cooldown = 45,
	replaces = 1850
}
-- Wild Charge
LCT_SpellData[102401] = {
	class = "DRUID",
	talent = true,
	cooldown = 15
}
-- Mass Entanglement
LCT_SpellData[102359] = {
	class = "DRUID",
	talent = true,
	cc = true,
	cooldown = 30
}
-- Mighty Bash
LCT_SpellData[5211] = {
	class = "DRUID",
	_talent = true,
	stun = true,
	cooldown = 60
}
-- Typhoon
LCT_SpellData[132469] = {
	class = "DRUID",
	talent = true,
	knockback = true,
	cooldown = 30
}
-- Survival instincts
LCT_SpellData[61336] = {
	class = "DRUID",
	specID = { SPEC_DRUID_FERAL, SPEC_DRUID_GUARDIAN },
	defensive = true,
	cooldown = 180,
	duration = 6,
	opt_charges = 2,
}
-- Druid/talents/mixed
-- Thorns
LCT_SpellData[305497] = {
	class = "DRUID",
	specID = { SPEC_DRUID_BALANCE, SPEC_DRUID_FERAL, SPEC_DRUID_RESTO },
	talent = true,
	cooldown = 45
}
-- Renewal
LCT_SpellData[108238] = {
	class = "DRUID",
	specID = { SPEC_DRUID_BALANCE, SPEC_DRUID_FERAL, SPEC_DRUID_RESTO },
	talent = true,
	heal = true,
	cooldown = 90
}

-- Druid/Balance
-- Solar Beam
LCT_SpellData[78675] = {
	class = "DRUID",
	specID = { SPEC_DRUID_BALANCE },
	interrupt = true,
	silence = true,
	duration = 8,
	cooldown = 60
}
-- Druid/Balance/talents
-- Incarnation (balance)
LCT_SpellData[102560] = {
	class = "DRUID",
	specID = { SPEC_DRUID_BALANCE },
	talent = true,
	offensive = true,
	duration = 30,
	cooldown = 180,
}
-- Force of Nature
LCT_SpellData[205636] = {
	class = "DRUID",
	specID = { SPEC_DRUID_BALANCE },
	talent = true,
	duration = 10,
	cooldown = 60
}
-- Fury of Elune
LCT_SpellData[202770] = {
	class = "DRUID",
	specID = { SPEC_DRUID_BALANCE },
	talent = true,
	duration = 8,
	cooldown = 60
}
-- Faerie Swarm
LCT_SpellData[209749] = {
	class = "DRUID",
	specID = { SPEC_DRUID_BALANCE },
	talent = true,
	duration = 5,
	cooldown = 30
}
-- Druid/Feral
-- Tiger's Fury
LCT_SpellData[5217] = {
	class = "DRUID",
	specID = { SPEC_DRUID_FERAL },
	offensive = true,
	duration = 10,
	cooldown = 30
}
-- Maim
LCT_SpellData[22570] = {
	class = "DRUID",
	talent = true,
	stun = true,
	cooldown = 20,
}
-- Skull Bash
LCT_SpellData[106839] = {
	class = "DRUID",
	_talent = true,
	interrupt = true,
	cooldown = 15,
}
-- Berserk
LCT_SpellData[343223] = {
	class = "DRUID",
	specID = { SPEC_DRUID_FERAL },
	offensive = true,
	cooldown = 180,
	duration = 20
}
-- Druid/Feral/talents
-- Incarnation (feral)
LCT_SpellData[102543] = {
	class = "DRUID",
	specID = { SPEC_DRUID_FERAL },
	talent = true,
	offensive = true,
	cooldown = 180,
	duration = 30,
	replaces = 106951 -- Berserk
}
-- Feral Frenzy
LCT_SpellData[274837] = {
	class = "DRUID",
	specID = { SPEC_DRUID_FERAL },
	talent = true,
	cooldown = 45
}
-- Brutal Slash
LCT_SpellData[202028] = {
	class = "DRUID",
	specID = { SPEC_DRUID_FERAL },
	talent = true,
	cooldown = 8,
	charges = 3,
	-- replaces = 213764, -- replaces Swipe which has no cooldown
}

-- Druid/Guardian
-- Incapacitating Roar
LCT_SpellData[99] = {
	class = "DRUID",
	talent = true,
	cooldown = 30
}
-- Frenzied Regeneration
LCT_SpellData[22842] = {
	class = "DRUID",
	defensive = true,
	opt_charges = 2,
	cooldown = 36,
}
-- Druid/Guardian/talents
-- Incarnation (Guardian)
LCT_SpellData[102558] = {
	class = "DRUID",
	specID = { SPEC_DRUID_GUARDIAN },
	talent = true,
	offensive = true,
	duration = 30,
	cooldown = 180
}
-- Lunar Beam
LCT_SpellData[204066] = {
	class = "DRUID",
	specID = { SPEC_DRUID_GUARDIAN },
	talent = true,
	offensive = true,
	cooldown = 60
}
-- Alpha Challenge
LCT_SpellData[207017] = {
	class = "DRUID",
	specID = { SPEC_DRUID_GUARDIAN },
	talent = true,
	cooldown = 20,
	replaces = 6795
}
-- Bristling Fur
LCT_SpellData[155835] = {
	class = "DRUID",
	specID = { SPEC_DRUID_GUARDIAN },
	talent = true,
	duration = 8,
	cooldown = 40
}
-- Demoralizing Roar
LCT_SpellData[201664] = {
	class = "DRUID",
	specID = { SPEC_DRUID_GUARDIAN },
	talent = true,
	cooldown = 30
}
-- Emerald Slumber
LCT_SpellData[329042] = {
	class = "DRUID",
	specID = { SPEC_DRUID_GUARDIAN },
	talent = true,
	cooldown = 120,
	duration = 8
}

-- Druid/Restoration
-- Ursol's Vortex
LCT_SpellData[102793] = {
	class = "DRUID",
	cc = true,
	cooldown = 60
}
-- Ironbark
LCT_SpellData[102342] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	defensive = true,
	duration = 12,
	cooldown = 90,
}
-- Nature's Cure
LCT_SpellData[88423] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	dispel = true,
	cooldown_starts_on_dispel = true,
	cooldown = 8
}
-- Swiftmend
LCT_SpellData[18562] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	heal = true,
	cooldown = 15,
	opt_charges = 2,
}
-- Wild Growth
LCT_SpellData[48438] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	heal = true,
	cooldown = 10
}
-- Incarnation (resto)
LCT_SpellData[33891] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	talent = true,
	defensive = true,
	cooldown = 180,
}
-- Tranquility
LCT_SpellData[740] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	defensive = true,
	duration = 8,
	cooldown = 180,
}
-- Nature's Swiftness
LCT_SpellData[132158] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	cooldown = 60,
}
-- Druid/Restoration/talents
-- Cenarion Ward
LCT_SpellData[102351] = {
	class = "DRUID",
	talent = true,
	heal = true,
	duration = 8,
	cooldown = 30
}
-- Flourish
LCT_SpellData[197721] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	talent = true,
	heal = true,
	cooldown = 90
}
-- Overgrowth
LCT_SpellData[203651] = {
	class = "DRUID",
	specID = { SPEC_DRUID_RESTO },
	talent = true,
	heal = true,
	cooldown = 60
}
