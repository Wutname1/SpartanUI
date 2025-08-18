-- ================ MAGE ================

local SPEC_MAGE_ARCANE = 62
local SPEC_MAGE_FIRE = 63
local SPEC_MAGE_FROST = 64

local DRAGON_BREATH = 31661
local COMBUSTION = 190319
local db_reduce = {
	spellid = DRAGON_BREATH,
	duration = 2
}
-- Fingers of Frost
LCT_SpellData[112965] = {
	class = "MAGE",
	reduce = db_reduce,
	hidden = true,
	cooldown_starts_on_aura_fade = true,
}
-- Clearcasting
LCT_SpellData[263725] = {
	class = "MAGE",
	reduce = db_reduce,
	hidden = true,
	cooldown_starts_on_aura_fade = true,
}


local combust_reduce = {
	spellid = COMBUSTION,
	buff = COMBUSTION,
	duration = 1,
}
-- Pyroblast
LCT_SpellData[11366] = {
	class = "MAGE",
	reduce = combust_reduce,
	hidden = true,
	cooldown_starts_on_aura_fade = true,
}
-- Scorch
LCT_SpellData[2948] = {
	class = "MAGE",
	reduce = combust_reduce,
	hidden = true,
	cooldown_starts_on_aura_fade = true,
}
-- Fireball
LCT_SpellData[133] = {
	class = "MAGE",
	reduce = combust_reduce,
	hidden = true,
	cooldown_starts_on_aura_fade = true,
}


-- Mage/baseline
-- Blink
LCT_SpellData[1953] = {
	class = "MAGE",
	defensive = true,
	cooldown = 15
}
-- Shimmer
LCT_SpellData[212653] = {
	class = "MAGE",
	defensive = true,
	talent = true,
	charges = 2,
	cooldown = 20,
	replaces = 1953
}
-- Counterspell
LCT_SpellData[2139] = {
	class = "MAGE",
	interrupt = true,
	cooldown = 24,
}
-- Frost Nova
LCT_SpellData[122] = {
	class = "MAGE",
	cc = true,
	cooldown = 30,
	opt_charges = 2,
}
-- Ice Block
LCT_SpellData[45438] = {
	class = "MAGE",
	defensive = true,
	immune = true,
	duration = 10,
	cooldown = 240
}
-- Ice Cold
LCT_SpellData[414659] = {
	class = "MAGE",
  talent = true,
	defensive = true,
	duration = 6,
	cooldown = 240,
	replaces = 45438
}
-- Mirror Image
LCT_SpellData[55342] = {
	class = "MAGE",
	offensive = true,
	cooldown = 120
}
-- Time Warp
LCT_SpellData[80353] = {
	class = "MAGE",
	offensive = true,
	duration = 40,
	cooldown = 300
}

-- Mage/mixed
-- Alter Time
LCT_SpellData[342245] = {
	class = "MAGE",
	defensive = true,
	duration = 10,
	cooldown = 50,
	-- opt_lower_cooldown = 50, -- with 342249 Master of Time
}

-- Mage/talents
-- Temporal Shield
LCT_SpellData[198111] = {
	class = "MAGE",
	defensive = true,
	talent = true,
	duration = 4,
	cooldown = 45
}
-- Kleptomania
LCT_SpellData[198100] = {
	class = "MAGE",
	defensive = true,
	talent = true,
	cooldown = 20
}
-- Ring of Frost
LCT_SpellData[113724] = {
	class = "MAGE",
	talent = true,
	cc = true,
	duration = 10,
	cooldown = 45
}
-- Dragon's Breath
LCT_SpellData[DRAGON_BREATH] = {
	class = "MAGE",
	talent = true,
	cc = true,
	cooldown = 45
}
-- Rune of Power
LCT_SpellData[116011] = {
	class = "MAGE",
	talent = true,
	cooldown = 45,
	opt_charges = 2,
}
-- Invisibility
LCT_SpellData[66] = {
	class = "MAGE",
	defensive = true,
	duration = 20,
	cooldown = 300
}
-- Mass Invisibility
LCT_SpellData[414664] = {
	class = "MAGE",
	talent = true,
	duration = 12,
	cooldown = 300
}
-- Mass barrier
LCT_SpellData[414660] = {
	class = "MAGE",
	talent = true,
	cooldown = 180
}

-- Mage/Arcane
-- Greater Invisibility (arcane)
LCT_SpellData[110959] = {
	class = "MAGE",
	talent = true,
	defensive = true,
	duration = 20,
	cooldown = 120
}
-- Arcane Surge
LCT_SpellData[365350] = {
	class = "MAGE",
	specID = { SPEC_MAGE_ARCANE },
	offensive = true,
	duration = 15,
	cooldown = 90
}
-- Evocation
LCT_SpellData[12051] = {
	class = "MAGE",
	specID = { SPEC_MAGE_ARCANE },
	defensive = true,
	duration = 6,
	cooldown = 90
}
-- Presence of Mind
LCT_SpellData[205025] = {
	class = "MAGE",
	specID = { SPEC_MAGE_ARCANE },
	offensive = true,
	cooldown = 45
}
-- Prismatic Barrier
LCT_SpellData[235450] = {
	class = "MAGE",
	specID = { SPEC_MAGE_ARCANE },
	defensive = true,
	cooldown = 25
}
-- Displacement when Blink (Arcane)
LCT_SpellData[195676] = {
	class = "MAGE",
	specID = { SPEC_MAGE_ARCANE },
	defensive = true,
	cooldown = 30,
	resets = { 1953 }
}
-- Mage/Arcane/talents
-- Arcane Orb
LCT_SpellData[153626] = {
	class = "MAGE",
	specID = { SPEC_MAGE_ARCANE },
	talent = true,
	cooldown = 20
}
-- Supernova
LCT_SpellData[157980] = {
	class = "MAGE",
	specID = { SPEC_MAGE_ARCANE },
	talent = true,
	cooldown = 25
}
-- Arcanosphere
LCT_SpellData[353128] = {
	class = "MAGE",
	specID = { SPEC_MAGE_ARCANE },
	talent = true,
	cooldown = 45
}

-- Mage/Fire
-- Combustion
LCT_SpellData[COMBUSTION] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	offensive = true,
	duration = 10,
	cooldown = 120
}
-- Blazing Barrier
LCT_SpellData[235313] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	offensive = true,
	cooldown = 25
}
-- Fire Blast
LCT_SpellData[108853] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	offensive = true,
	cooldown = 12,
	reduces = {
		combust_reduce,
		{ -- like db_reduce, but only for fire
			spellid = DRAGON_BREATH,
			specId = SPEC_MAGE_FIRE,
			duration = 2
		}
	}
}
-- Cauterize
LCT_SpellData[86949] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	defensive = true,
	duration = 6,
	cooldown = 300
}
-- Mage/Fire/talents
-- Blast Wave
LCT_SpellData[157981] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	talent = true,
	offensive = true,
	cooldown = 30
}
-- Living Bomb
LCT_SpellData[44457] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	talent = true,
	cooldown = 30
}
-- Meteor
LCT_SpellData[153561] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	talent = true,
	cooldown = 45
}
-- Phoenix Flames
LCT_SpellData[257541] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	talent = true,
	cooldown = 25,
	charges = 3,
	reduce = combust_reduce
}
-- Ring of Fire
LCT_SpellData[353082] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FIRE },
	talent = true,
	cooldown = 30,
}

-- Mage/Frost
-- Ice Barrier
LCT_SpellData[11426] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	defensive = true,
	cooldown = 25
}
-- Frozen Orb
LCT_SpellData[84714] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	offensive = true,
	duration = 10,
	cooldown = 60
}
-- Icy Veins
LCT_SpellData[12472] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	offensive = true,
	duration = 20,
	cooldown = 120,
}
-- Cold Snap
LCT_SpellData[235219] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	resets = { 11426, 45438, 122, 120, 414659 }, -- ice barrier, ice block, frost nova, cone of cold, ice cold
	cooldown = 300,
}
-- Cone of Cold
LCT_SpellData[120] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	offensive = true,
	cooldown = 12,
}
-- Summon Water Elemental
LCT_SpellData[31687] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	cooldown = 30
}
-- Mage/Frost/talents
-- Comet Storm
LCT_SpellData[153595] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	talent = true,
	cooldown = 30
}
-- Ice Form
LCT_SpellData[198144] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	talent = true,
	duration = 12,
	cooldown = 60,
	replaces = 12472 -- Icy Veins
}
-- Ice Nova
LCT_SpellData[157997] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	talent = true,
	cooldown = 25
}
-- Ray of Frost
LCT_SpellData[205021] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	talent = true,
	offensive = true,
	cooldown = 60,
}
-- Ice Floes
LCT_SpellData[108839] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	talent = true,
	cooldown = 20,
	charges = 3
}
-- Ebonbolt
LCT_SpellData[257537] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	talent = true,
	offensive = true,
	cooldown = 30,
}
-- Ice Wall
LCT_SpellData[352278] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	talent = true,
	cooldown = 90,
}

-- Mage/Pet
-- Freeze
LCT_SpellData[33395] = {
	class = "MAGE",
	specID = { SPEC_MAGE_FROST },
	pet = true,
	cooldown = 25
}
-- Shifting Power
LCT_SpellData[382440] = {
	class = "MAGE",
	offensive = true,
	duration = 4,
	cooldown = 60,
	reduce = { all = true, duration = 10 }
}
