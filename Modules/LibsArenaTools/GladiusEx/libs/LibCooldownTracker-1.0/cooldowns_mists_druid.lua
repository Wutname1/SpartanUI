-- ================ DRUID ================
-- Druid/baseline
-- Dash
LCT_SpellData[1850] = {
	class = "DRUID",
	duration = 15,
	cooldown = 180
}
-- Stampeding Roar
LCT_SpellData[77761] = {
	class = "DRUID",
	duration = 8,
	cooldown = 120
}
LCT_SpellData[77764] = 77761
LCT_SpellData[106898] = 77761

-- Druid/talents
-- Cenarion Ward
LCT_SpellData[102351] = {
	class = "DRUID",
	talent = true,
	heal = true,
	duration = 30,
	cooldown = 30
}
-- incapacitating Roar
LCT_SpellData[99] = {
	class = "DRUID",
	talent = true,
	cc = true,
	cooldown = 30
}
-- Displacer Beast
LCT_SpellData[102280] = {
	class = "DRUID",
	talent = true,
	cooldown = 30
}
-- Wild Charge
LCT_SpellData[102401] = {
	class = "DRUID",
	talent = true,
	cooldown = 15
}
LCT_SpellData[16979] = 102401 -- Bear
LCT_SpellData[49376] = 102401 -- Cat
LCT_SpellData[102416] = 102401 -- Aquatic
LCT_SpellData[102417] = 102401 -- Travel
LCT_SpellData[102383] = 102401 -- Moonkin
-- Incarnation : Guardion
LCT_SpellData[102558] = {
	class = "DRUID",
	talent = true,
	specID = { 104 },
	defensive = true,
	duration = 30,
	cooldown = 180
}
-- Incarnation : Feral
LCT_SpellData[102543] = {
	class = "DRUID",
	talent = true,
	specID = { 103 },
	offensive = true,
	duration = 30,
	cooldown = 180
}
-- Incarnation : Restoration
LCT_SpellData[33891] = {
	class = "DRUID",
	talent = true,
	specID = { 105 },
	defensive = true,
	duration = 30,
	cooldown = 180
}
LCT_SpellData[102560] = {
	class = "DRUID",
	talent = true,
	specID = { 102 },
	defensive = true,
	duration = 30,
	cooldown = 180
}

-- Heart of the Wild
LCT_SpellData[108291] = { -- Balance
	class = "DRUID",
	talent = true,
	offensive = true,
	defensive = true,
	duration = 45,
	cooldown = 360
}
LCT_SpellData[108292] = 108288 -- Feral
LCT_SpellData[108293] = 108288 -- Guardian
LCT_SpellData[108294] = 108288 -- Resto
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
	talent = true,
	stun = true,
	cooldown = 50
}
-- Nature's Vigil
LCT_SpellData[124974] = {
	class = "DRUID",
	talent = true,
	defensive = true,
	duration = 30,
	cooldown = 90
}
-- Renewal
LCT_SpellData[108238] = {
	class = "DRUID",
	talent = true,
	heal = true,
	cooldown = 120
}
-- Typhoon
LCT_SpellData[132469] = {
	class = "DRUID",
	talent = true,
	knockback = true,
	cooldown = 30
}
-- Ursol's Vortex
LCT_SpellData[102793] = {
	class = "DRUID",
	talent = true,
	cc = true,
	cooldown = 60
}

-- Druid/Balance
-- Barkskin
LCT_SpellData[22812] = {
	class = "DRUID",
	specID = { 102, 104, 105 },
	defensive = true,
	duration = 12,
	cooldown = 60
}
-- Celestial Alignment
LCT_SpellData[112071] = {
	class = "DRUID",
	specID = { 102 },
	offensive = true,
	duration = 15,
	cooldown = 180
}
-- Remove Corruption
LCT_SpellData[2782] = {
	class = "DRUID",
	specID = { 102, 103, 104 },
	dispel = true,
	cooldown_starts_on_dispel = true,
	cooldown = 8
}
-- Solar Beam
LCT_SpellData[78675] = {
	class = "DRUID",
	specID = { 102 },
	interrupt = true,
	silence = true,
	duration = 10,
	cooldown = 60
}
-- Starfall
LCT_SpellData[48505] = {
	class = "DRUID",
	specID = { 102 },
	offensive = true,
	duration = 10,
	charges = 3,
	cooldown = 30
}
-- Starsurge
LCT_SpellData[78674] = {
	class = "DRUID",
	specID = { 102 },
	offensive = true,
	charges = 3,
	cooldown = 30
}

-- Druid/Feral
-- Berserk (Cat Form)
LCT_SpellData[106951] = {
	class = "DRUID",
	specID = { 103, 104 },
	offensive = true,
	sets_cooldown = { spellid = 50334, cooldown = 180 },
	duration = 15,
	cooldown = 180
}
-- Berserk (Bear Form)
LCT_SpellData[50334] = {
	class = "DRUID",
	specID = { 103, 104 },
	offensive = true,
	sets_cooldown = { spellid = 106951, cooldown = 180 },
	duration = 10,
	cooldown = 180
}
-- Skull Bash
LCT_SpellData[106839] = {
	class = "DRUID",
	specID = { 103, 104 },
	interrupt = true,
	cooldown = 15
}
-- Tiger's Fury
LCT_SpellData[5217] = {
	class = "DRUID",
	specID = { 103 },
	offensive = true,
	duration = 6,
	cooldown = 30
}

-- Druid/Guardian
-- Savage Defense
LCT_SpellData[62606] = {
	class = "DRUID",
	specID = { 104 },
	charges = 2,
	defensive = true,
	duration = 6,
	cooldown = 12
}
-- Survival Instincts
LCT_SpellData[61336] = {
	class = "DRUID",
	specID = { 103, 104 },
	defensive = true,
	duration = 12,
	cooldown = 180
}

-- Druid/Restoration
-- Nature's Swiftness
LCT_SpellData[132158] = {
	class = "DRUID",
	specID = { 105 },
	heal = true,
	cooldown_starts_on_aura_fade = true,
	cooldown = 60
}
-- Tranquility
LCT_SpellData[740] = {
	class = "DRUID",
	specID = { 105 },
	heal = true,
	duration = 8,
	cooldown = 480
}
-- Ironbark
LCT_SpellData[102342] = {
	class = "DRUID",
	specID = { 105 },
	defensive = true,
	duration = 12,
	cooldown = 60
}
-- Nature's Cure
LCT_SpellData[88423] = {
	class = "DRUID",
	specID = { 105 },
	dispel = true,
	cooldown_starts_on_dispel = true,
	cooldown = 8
}
-- Swiftmend
LCT_SpellData[18562] = {
	class = "DRUID",
	specID = { 105 },
	heal = true,
	cooldown = 15
}
-- Wild Growth
LCT_SpellData[48438] = {
	class = "DRUID",
	specID = { 105 },
	heal = true,
	cooldown = 8
}
