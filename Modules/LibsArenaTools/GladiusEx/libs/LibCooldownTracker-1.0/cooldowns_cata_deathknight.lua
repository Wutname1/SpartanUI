-- ================ DK ================

local SPEC_DK_BLOOD  = 250
local SPEC_DK_FROST  = 251
local SPEC_DK_UNHOLY = 252

-- Death Knight/Blood
-- Blood Tap
LCT_SpellData[45529] = {
  class = "DEATHKNIGHT",
  cooldown = 60,
}
-- Death Pact
LCT_SpellData[48743] = {
  class = "DEATHKNIGHT",
  cooldown = 120,
}
-- Strangulate
LCT_SpellData[47476] = {
  class = "DEATHKNIGHT",
  cooldown = 120,
  opt_lower_cooldown = 60,
  cooldown_overload = { [SPEC_DK_BLOOD] = 60, },
}

-- Death Knight/Blood/talents
-- Bone Shield
LCT_SpellData[49222] = {
  class = "DEATHKNIGHT",
  cooldown = 60,
  talent = true,
  specID = { SPEC_DK_BLOOD },
}
-- Vampiric Blood
LCT_SpellData[55233] = {
  class = "DEATHKNIGHT",
  cooldown = 60,
  talent = true,
  specID = { SPEC_DK_BLOOD },
}
-- Rune Tap
LCT_SpellData[48982] = {
  class = "DEATHKNIGHT",
  cooldown = 30,
  talent = true,
  specID = { SPEC_DK_BLOOD },
}

-- Dancing Rune Weapon
LCT_SpellData[49028] = {
  class = "DEATHKNIGHT",
  cooldown = 90,
  talent = true,
  specID = { SPEC_DK_BLOOD },
}

-- Death Knight/Frost
-- Horn of Winter
LCT_SpellData[57330] = {
  class = "DEATHKNIGHT",
  cooldown = 20,
}
-- Icebound Fortitude
LCT_SpellData[48792] = {
  class = "DEATHKNIGHT",
  cooldown = 120,
  duration = 12,
}
-- Mind Freeze
LCT_SpellData[47528] = {
  class = "DEATHKNIGHT",
  cooldown = 10,
  interrupt = true,
}

-- Death Knight/Frost/talents
-- Lichborne
LCT_SpellData[49039] = {
  class = "DEATHKNIGHT",
  cooldown = 120,
  talent = true,
  specID = { SPEC_DK_UNHOLY },
  duration = 10,
}
-- Hungering Cold
LCT_SpellData[49203] = {
  class = "DEATHKNIGHT",
  cooldown = 60,
  talent = true,
  specID = { SPEC_DK_FROST },
}
-- Pillar of Frost
LCT_SpellData[51271] = {
  class = "DEATHKNIGHT",
  cooldown = 60,
  talent = true,
  specID = { SPEC_DK_FROST },
}

-- Death Knight/Unholy
-- Anti-Magic Shell
LCT_SpellData[48707] = {
  class = "DEATHKNIGHT",
  cooldown = 45,
  duration = 5,
}
-- Death Grip
LCT_SpellData[49576] = {
  class = "DEATHKNIGHT",
  cooldown = 35,
  opt_lower_cooldown = 25,
  cooldown_overload = { [SPEC_DK_UNHOLY] = 25, [SPEC_DK_FROST] = 25, },
}
-- Death and Decay
LCT_SpellData[43265] = {
  class = "DEATHKNIGHT",
  cooldown = 30,
}
-- Raise Dead
LCT_SpellData[46584] = {
  class = "DEATHKNIGHT",
  cooldown = 180,
  specID = { SPEC_DK_BLOOD, SPEC_DK_FROST, },
}
-- Death Knight/Unholy/talents
-- Anti-Magic Zone
LCT_SpellData[51052] = {
  class = "DEATHKNIGHT",
  cooldown = 120,
  talent = true,
  duration = 10,
  specID = { SPEC_DK_UNHOLY },
}
-- Summon Gargoyle
LCT_SpellData[49206] = {
  class = "DEATHKNIGHT",
  cooldown = 180,
  talent = true,
  duration = 30,
  specID = { SPEC_DK_UNHOLY },
}
-- Unholy Frenzy
LCT_SpellData[49016] = {
  class = "DEATHKNIGHT",
  cooldown = 180,
  talent = true,
  specID = { SPEC_DK_UNHOLY },
}
