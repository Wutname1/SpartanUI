-- ================ SHAMAN ================

local SPEC_SHAMAN_ELEMENTAL   = 262
local SPEC_SHAMAN_ENHANCEMENT = 263
local SPEC_SHAMAN_RESTORATION = 264

-- Earth Elemental Totem
LCT_SpellData[2062] = {
  cooldown = 600,
  class = "SHAMAN",
}

-- Astral Recall
LCT_SpellData[556] = {
  cooldown = 900,
  class = "SHAMAN",
}

-- Nature's Swiftness
LCT_SpellData[16188] = {
  cooldown = 120,
  class = "SHAMAN",
  talent = true,
	cooldown_starts_on_dispel = true,
}

-- Mana Tide Totem
LCT_SpellData[16190] = {
  cooldown = 300,
  class = "SHAMAN",
  talent = true,
}

-- Fire Elemental Totem
LCT_SpellData[2894] = {
  cooldown = 600,
  class = "SHAMAN",
  specID = { SPEC_SHAMAN_ELEMENTAL },
}

-- Grounding Totem
LCT_SpellData[8177] = {
  class = "SHAMAN",
  cooldown = 15,
  opt_lower_cooldown = 13,
}

-- Shamanistic Rage
LCT_SpellData[30823] = {
  class = "SHAMAN",
  cooldown = 60,
  talent = true,
  specID = { SPEC_SHAMAN_ENHANCEMENT },
}

-- Earth Shock
LCT_SpellData[8042] = {
  cooldown = 6,
  class = "SHAMAN",
}
LCT_SpellData[8044] = 8042
LCT_SpellData[8045] = 8042
LCT_SpellData[8046] = 8042
LCT_SpellData[10412] = 8042
LCT_SpellData[10413] = 8042
LCT_SpellData[10414] = 8042
LCT_SpellData[25454] = 8042
LCT_SpellData[49230] = 8042
LCT_SpellData[49231] = 8042
-- Frost Shock
LCT_SpellData[8056] = 8042
LCT_SpellData[8058] = 8042
LCT_SpellData[10472] = 8042
LCT_SpellData[10473] = 8042
LCT_SpellData[25464] = 8042
LCT_SpellData[49235] = 8042
LCT_SpellData[49236] = 8042
-- Flame Shock
LCT_SpellData[8050] = 8042
LCT_SpellData[8052] = 8042
LCT_SpellData[8053] = 8042
LCT_SpellData[10447] = 8042
LCT_SpellData[10448] = 8042
LCT_SpellData[29228] = 8042
LCT_SpellData[25457] = 8042
LCT_SpellData[49232] = 8042
LCT_SpellData[49233] = 8042

-- Elemental Mastery
LCT_SpellData[16166] = {
  cooldown = 180,
  class = "SHAMAN",
  talent = true,
  specID = { SPEC_SHAMAN_ELEMENTAL },
}

-- Heroism
LCT_SpellData[32182] = {
  cooldown = 300,
  class = "SHAMAN",
}
-- Bloodlust
LCT_SpellData[2825] = {
  cooldown = 600,
  class = "SHAMAN",
}

-- Reincarnation
LCT_SpellData[20608] = {
  class = "SHAMAN",
  cooldown = 1800,
}

-- Stormstrike
LCT_SpellData[17364] = {
  class = "SHAMAN",
  cooldown = 8,
  talent = true,
  specID = { SPEC_SHAMAN_ENHANCEMENT },
}

-- Chain Lightning
LCT_SpellData[421] = {
  cooldown = 6,
  class = "SHAMAN",
  specID = { SPEC_SHAMAN_ELEMENTAL },
}
LCT_SpellData[930] = 421
LCT_SpellData[2860] = 421
LCT_SpellData[10605] = 421
LCT_SpellData[25439] = 421
LCT_SpellData[25442] = 421
LCT_SpellData[49270] = 421
LCT_SpellData[49271] = 421

-- Earthbind Totem
LCT_SpellData[2484] = {
  cooldown = 15,
  class = "SHAMAN",
}

-- Stoneclaw Totem
LCT_SpellData[5730] = {
  cooldown = 30,
  class = "SHAMAN",
}
LCT_SpellData[6390] = 5730
LCT_SpellData[6391] = 5730
LCT_SpellData[6392] = 5730
LCT_SpellData[10427] = 5730
LCT_SpellData[10428] = 5730
LCT_SpellData[25525] = 5730
LCT_SpellData[58580] = 5730
LCT_SpellData[58581] = 5730
LCT_SpellData[58582] = 5730

-- Fire Nova Totem
LCT_SpellData[1535] = {
  class = "SHAMAN",
  cooldown = 10,
}
LCT_SpellData[8498] = 1535
LCT_SpellData[8499] = 1535
LCT_SpellData[11314] = 1535
LCT_SpellData[11315] = 1535
LCT_SpellData[25546] = 1535
LCT_SpellData[25547] = 1535
LCT_SpellData[61650] = 1535
LCT_SpellData[61657] = 1535

-- Riptide
LCT_SpellData[61295] = {
  class = "SHAMAN",
  cooldown = 6,
  talent = true,
  specID = { SPEC_SHAMAN_RESTORATION },
}
LCT_SpellData[61299] = 61295
LCT_SpellData[61300] = 61295
LCT_SpellData[61301] = 61295

-- Thunderstorm
LCT_SpellData[51490] = {
  class = "SHAMAN",
  cooldown = 45,
  talent = true,
  specID = { SPEC_SHAMAN_ELEMENTAL },
}

-- Hex
LCT_SpellData[51514] = {
  class = "SHAMAN",
  cooldown = 45,
  cc = true,
}

-- Wind Shear
LCT_SpellData[57994] = {
  class = "SHAMAN",
  cooldown = 6,
}

-- Feral Spirit
LCT_SpellData[51533] = {
  class = "SHAMAN",
  cooldown = 180,
  talent = true,
  specID = { SPEC_SHAMAN_ENHANCEMENT },
}

-- TODO Nature's Guardian (is there an event?)
