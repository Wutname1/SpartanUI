-- ================ MAGE ================

local SPEC_MAGE_ARCANE = 62
local SPEC_MAGE_FIRE = 63
local SPEC_MAGE_FROST = 64

-- Arcane Power
LCT_SpellData[12042] = {
  class = "MAGE",
  cooldown = 120,
  talent = true,
  specID = { SPEC_MAGE_ARCANE },
}

-- Presence of Mind
LCT_SpellData[12043] = {
  class = "MAGE",
  cooldown = 120,
  talent = true,
  specID = { SPEC_MAGE_ARCANE },
}

-- Evocation
LCT_SpellData[12051] = {
  cooldown = 240,
  class = "MAGE",
}

-- Mage Ward
LCT_SpellData[543] = {
  cooldown = 30,
  class = "MAGE",
}
LCT_SpellData[8457] = 543
LCT_SpellData[8458] = 543
LCT_SpellData[10225] = 543
LCT_SpellData[10223] = 543
LCT_SpellData[27128] = 543
LCT_SpellData[43010] = 543

-- Invisibility
LCT_SpellData[66] = {
  cooldown = 180,
  class = "MAGE",
}

-- Fire Blast
LCT_SpellData[2136] = {
  cooldown = 8,
  class = "MAGE",
}
LCT_SpellData[2137] = 2136
LCT_SpellData[2138] = 2136
LCT_SpellData[8412] = 2136
LCT_SpellData[8413] = 2136
LCT_SpellData[10197] = 2136
LCT_SpellData[10199] = 2136
LCT_SpellData[27078] = 2136
LCT_SpellData[27079] = 2136
LCT_SpellData[42872] = 2136
LCT_SpellData[42873] = 2136

-- Freeze
LCT_SpellData[33395] = {
  cooldown = 25,
  class = "MAGE",
  specID = { SPEC_MAGE_FROST },
  pet = true,
}

-- Cone of Cold
LCT_SpellData[120] = {
  cooldown = 10,
  opt_lower_cooldown = 8,
  cooldown_overload = { [SPEC_MAGE_FROST] = 8, },
  class = "MAGE",
}
LCT_SpellData[8492] = 120
LCT_SpellData[27087] = 120
LCT_SpellData[10161] = 120
LCT_SpellData[10159] = 120
LCT_SpellData[10160] = 120
LCT_SpellData[42930] = 120
LCT_SpellData[42931] = 120

-- Frost Nova
LCT_SpellData[122] = {
  cooldown = 25,
  opt_lower_cooldown = 20,
  cooldown_overload = { [SPEC_MAGE_FROST] = 20, },
  class = "MAGE",
}
LCT_SpellData[865] = 122
LCT_SpellData[6131] = 122
LCT_SpellData[10230] = 122
LCT_SpellData[27088] = 122
LCT_SpellData[42917] = 122

-- Ritual of Refreshment
LCT_SpellData[43987] = {
  cooldown = 300,
  class = "MAGE",
}
LCT_SpellData[58659] = 43987

-- Cold Snap
LCT_SpellData[11958] = {
  cooldown = 480,
  opt_lower_cooldown = 384,
  cooldown_overload = { [SPEC_MAGE_FROST] = 384, },
  class = "MAGE",
  specID = { SPEC_MAGE_FROST },
  talent = true,
  resets = { 122, 120, 12472, 11426, 31687, 45438, 44572 },
}

-- Dragon's Breath
LCT_SpellData[31661] = {
  cooldown = 20,
  opt_lower_cooldown = 17, -- Glyph of Dragon's Breath
  cooldown_overload = { [SPEC_MAGE_FIRE] = 17, }, -- assume everyone runs the glyph
  class = "MAGE",
  talent = true,
  specID = { SPEC_MAGE_FIRE },
}
LCT_SpellData[33041] = 31661
LCT_SpellData[33042] = 31661
LCT_SpellData[33043] = 31661
LCT_SpellData[42949] = 31661
LCT_SpellData[42950] = 31661

-- Blink
LCT_SpellData[1953] = {
  cooldown = 15,
  opt_lower_cooldown = 13,
  class = "MAGE",
}

-- Combustion
LCT_SpellData[11129] = {
  cooldown = 120,
  class = "MAGE",
  talent = true,
  specID = { SPEC_MAGE_FIRE },
}

-- Icy Veins
LCT_SpellData[12472] = {
  cooldown = 180,
  opt_lower_cooldown = 144,
  cooldown_overload = { [SPEC_MAGE_FROST] = 144, },
  class = "MAGE",
  talent = true,
  specID = { SPEC_MAGE_FROST },
}

-- Counterspell
LCT_SpellData[2139] = {
  class = "MAGE",
  cooldown = 24,
  interrupt = true,
}

-- Blast Wave
LCT_SpellData[11113] = {
  cooldown = 15,
  class = "MAGE",
  talent = true,
  specID = { SPEC_MAGE_FIRE },
}
LCT_SpellData[13018] = 11113
LCT_SpellData[13019] = 11113
LCT_SpellData[13020] = 11113
LCT_SpellData[13021] = 11113
LCT_SpellData[27133] = 11113
LCT_SpellData[33933] = 11113
LCT_SpellData[42944] = 11113
LCT_SpellData[42945] = 11113

-- Ice Barrier
LCT_SpellData[11426] = {
  cooldown = 30,
  opt_lower_cooldown = 24,
  cooldown_overload = { [SPEC_MAGE_FROST] = 24, },
  class = "MAGE",
  talent = true,
  specID = { SPEC_MAGE_FROST },
  detects = { 11958 }
}
LCT_SpellData[13031] = 11426
LCT_SpellData[13032] = 11426
LCT_SpellData[13033] = 11426
LCT_SpellData[27134] = 11426
LCT_SpellData[33405] = 11426
LCT_SpellData[43038] = 11426
LCT_SpellData[43039] = 11426

-- Summon Water Elemental
LCT_SpellData[31687] = {
  cooldown = 180,
  class = "MAGE",
  talent = true,
  specID = { SPEC_MAGE_FROST },
}

-- Ice Block
LCT_SpellData[45438] = {
  cooldown = 300,
  opt_lower_cooldown = 240,
  cooldown_overload = { [SPEC_MAGE_FROST] = 240, },
  class = "MAGE",
}

-- Mana Sapphire
LCT_SpellData[27103] = {
  class = "MAGE",
	item = true,
	opt_charges = 3,
	cooldown = 120
}

-- Mirror Image
LCT_SpellData[55342] = {
  class = "MAGE",
  cooldown = 180
}

-- Deep Freeze
LCT_SpellData[44572] = {
  class = "MAGE",
  cooldown = 30,
  talent = true,
  specID = { SPEC_MAGE_FROST },
}
