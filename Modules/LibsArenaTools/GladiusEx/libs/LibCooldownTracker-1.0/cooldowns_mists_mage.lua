-- ================ MAGE ================
-- Mage/baseline
-- Blink
LCT_SpellData[1953] = {
	class = "MAGE",
	defensive = true,
	cooldown = 15
}
-- Cone of Cold
LCT_SpellData[120] = {
	class = "MAGE",
	offensive = true,
	cooldown = 12
}
-- Counterspell
LCT_SpellData[2139] = {
	class = "MAGE",
	interrupt = true,
	cooldown = 20,
}
-- Evocation
LCT_SpellData[12051] = {
	class = "MAGE",
	defensive = true,
	duration = 6,
	cooldown = 120
}
-- Fire Blast
LCT_SpellData[2136] = {
	class = "MAGE",
	offensive = true,
	cooldown = 8
}
-- Frost Nova
LCT_SpellData[122] = {
	class = "MAGE",
	cc = true,
	cooldown = 30
}
-- Ice Block
LCT_SpellData[45438] = {
	class = "MAGE",
	defensive = true,
	immune = true,
	duration = 10,
	cooldown = 300
}
-- Invisibility
LCT_SpellData[66] = {
	class = "MAGE",
	defensive = true,
	duration = 3,
	cooldown = 300
}
-- Remove Curse
LCT_SpellData[475] = {
	class = "MAGE",
	dispel = true,
	cooldown_starts_on_dispel = true,
	cooldown = 8
}

--[[
-- Time Warp
LCT_SpellData[80353] = {
	class = "MAGE",
	offensive = true,
	duration = 40,
	cooldown = 300
}
]]
-- Mage/talents
-- Alter Time
LCT_SpellData[108978] = {
	class = "MAGE",
	defensive = true,
	offensive = true,
	duration = 10,
	cooldown = 90
}
-- Mirror Image
LCT_SpellData[55342] = {
	class = "MAGE",
	offensive = true,
	talent = true,
	duration = 40,
	cooldown = 120
}
-- Blazing Speed
LCT_SpellData[108843] = {
	class = "MAGE",
	talent = true,
	defensive = true,
	duration = 1.5,
	cooldown = 25
}
-- Cauterize
LCT_SpellData[86949] = {
	class = "MAGE",
	talent = true,
	defensive = true,
	duration = 6,
	cooldown = 120
}
-- Cold Snap
LCT_SpellData[11958] = {
	class = "MAGE",
	talent = true,
	resets = { 45438, 157913, 31661, 122, 120, 157980 },
	cooldown = 180
}
-- Frostjaw
LCT_SpellData[102051] = {
	class = "MAGE",
	talent = true,
	silence = true,
	cc = true,
	cooldown = 20
}
-- Greater Invisibility
LCT_SpellData[110959] = {
	class = "MAGE",
	talent = true,
	defensive = true,
	replaces = 66,
	duration = 20,
	cooldown = 90
}
-- Ice Barrier
LCT_SpellData[11426] = {
	class = "MAGE",
	talent = true,
	defensive = true,
	duration = 60,
	cooldown = 25
}
-- Ice Floes
LCT_SpellData[108839] = {
	class = "MAGE",
	talent = true,
	offensive = true,
	duration = 15,
	cooldown = 20
}
-- Ice Ward
LCT_SpellData[111264] = {
	class = "MAGE",
	talent = true,
	cc = true,
	cooldown = 20
}
-- Incanter's Ward
LCT_SpellData[1463] = {
	class = "MAGE",
	talent = true,
	defensive = true,
	duration = 8,
	cooldown = 25
}
-- Ring of Frost
LCT_SpellData[113724] = {
	class = "MAGE",
	talent = true,
	cc = true,
	duration = 10,
	cooldown = 45
}
-- Temporal Shield
LCT_SpellData[115610] = {
	class = "MAGE",
	talent = true,
	defensive = true,
	duration = 4,
	cooldown = 25
}
-- Mage/Arcane
-- Presence of Mind
LCT_SpellData[12043] = {
	class = "MAGE",
	specID = { 62 },
	offensive = true,
	cooldown_starts_on_aura_fade = true,
	cooldown = 90
}
-- Arcane Power
LCT_SpellData[12042] = {
	class = "MAGE",
	specID = { 62 },
	offensive = true,
	duration = 15,
	cooldown = 90
}

-- Mage/Fire
-- Flamestrike
LCT_SpellData[2120] = {
	class = "MAGE",
	specID = { 63 },
	offensive = true,
	duration = 8,
	cooldown = 12
}
-- Combustion
LCT_SpellData[11129] = {
	class = "MAGE",
	specID = { 63 },
	stun = true,
	offensive = true,
	cooldown = 45
}
-- Dragon's Breath
LCT_SpellData[31661] = {
	class = "MAGE",
	specID = { 63 },
	cc = true,
	cooldown = 20
}

-- Mage/Frost
-- Deep Freeze
LCT_SpellData[44572] = {
	class = "MAGE",
	cc = true,
	specID = { 64 },
	cooldown = 30
}

-- Frozen Orb
LCT_SpellData[84714] = {
	class = "MAGE",
	specID = { 64 },
	offensive = true,
	duration = 10,
	cooldown = 60
}
-- Icy Veins
LCT_SpellData[12472] = {
	class = "MAGE",
	specID = { 64 },
	offensive = true,
	duration = 20,
	cooldown = 180
}
-- Summon Water Elemental
LCT_SpellData[31687] = {
	class = "MAGE",
	specID = { 64 },
	offensive = true,
	cooldown = 60
}
