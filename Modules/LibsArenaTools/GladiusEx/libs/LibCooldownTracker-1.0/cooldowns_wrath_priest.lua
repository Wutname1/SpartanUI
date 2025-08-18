-- ================ PRIEST ================

local SPEC_PRIEST_DISC = 256
local SPEC_PRIEST_HOLY = 257
local SPEC_PRIEST_SHADOW = 258

-- Power Word: Shield
LCT_SpellData[17] = {
  class = "PRIEST",
  cooldown = 4,
}
LCT_SpellData[592] = 17
LCT_SpellData[600] = 17
LCT_SpellData[25217] = 17
LCT_SpellData[25218] = 17
LCT_SpellData[10898] = 17
LCT_SpellData[10899] = 17
LCT_SpellData[10900] = 17
LCT_SpellData[10901] = 17
LCT_SpellData[3747] = 17
LCT_SpellData[6065] = 17
LCT_SpellData[6066] = 17
LCT_SpellData[10898] = 17
LCT_SpellData[10899] = 17
LCT_SpellData[10900] = 17
LCT_SpellData[10901] = 17
LCT_SpellData[25217] = 17
LCT_SpellData[25218] = 17
LCT_SpellData[48065] = 17
LCT_SpellData[48066] = 17

-- Divine Hymn
LCT_SpellData[64843] = {
  class = "PRIEST",
  cooldown = 480,
  defensive = true,
}

-- Hymn of Hope
LCT_SpellData[64901] = {
  class = "PRIEST",
  cooldown = 360,
  defensive = true,
}

-- Fade
LCT_SpellData[586] = {
  class = "PRIEST",
  cooldown = 30,
  opt_lower_cooldown = 24,
}

-- Power Infusion
LCT_SpellData[10060] = {
  class = "PRIEST",
  cooldown = 120,
  talent = true,
  specID = { SPEC_PRIEST_DISC },
}

-- Desperate Prayer
LCT_SpellData[48173] = {
  class = "PRIEST",
  cooldown = 120,
}
LCT_SpellData[19236] = 48173
LCT_SpellData[19238] = 48173
LCT_SpellData[19240] = 48173
LCT_SpellData[19241] = 48173
LCT_SpellData[19242] = 48173
LCT_SpellData[19243] = 48173
LCT_SpellData[25437] = 48173
LCT_SpellData[48172] = 48173

-- Shadow Word: Death
LCT_SpellData[32379] = {
  class = "PRIEST",
  cooldown = 12,
}
LCT_SpellData[32996] = 32379
LCT_SpellData[48157] = 32379
LCT_SpellData[48158] = 32379

-- Silence
LCT_SpellData[15487] = {
  class = "PRIEST",
  cooldown = 45,
  talent = true,
  specID = { SPEC_PRIEST_SHADOW },
}

-- Shadowfiend
LCT_SpellData[34433] = {
  class = "PRIEST",
  cooldown = 300,
}

-- Psychic Scream
LCT_SpellData[8122] = {
  class = "PRIEST",
  cooldown = 30,
  opt_lower_cooldown = 26,
}
LCT_SpellData[8124] = 8122
LCT_SpellData[10888] = 8122
LCT_SpellData[10890] = 8122

-- Mind Blast
LCT_SpellData[8092] = {
  class = "PRIEST",
  cooldown = 8,
  opt_lower_cooldown = 5.5,
}
LCT_SpellData[8102] = 8092
LCT_SpellData[8103] = 8092
LCT_SpellData[8104] = 8092
LCT_SpellData[8105] = 8092
LCT_SpellData[8106] = 8092
LCT_SpellData[10945] = 8092
LCT_SpellData[10946] = 8092
LCT_SpellData[10947] = 8092
LCT_SpellData[25372] = 8092
LCT_SpellData[25375] = 8092
LCT_SpellData[48126] = 8092
LCT_SpellData[48127] = 8092

-- Prayer of Mending
LCT_SpellData[33076] = {
  class = "PRIEST",
  cooldown = 10,
}
LCT_SpellData[48112] = 33076
LCT_SpellData[48113] = 33076

-- Inner Focus
LCT_SpellData[14751] = {
  class = "PRIEST",
  cooldown = 180,
  talent = true,
  specID = { SPEC_PRIEST_DISC },
}

-- Pain Suppression
LCT_SpellData[33206] = {
  class = "PRIEST",
  cooldown = 180,
  talent = true,
  specID = { SPEC_PRIEST_DISC },
}

-- Fear Ward
LCT_SpellData[6346] = {
  class = "PRIEST",
  cooldown = 180,
}

-- Lightwell
LCT_SpellData[724] = {
  class = "PRIEST",
  cooldown = 180,
  talent = true,
  specID = { SPEC_PRIEST_HOLY },
}
LCT_SpellData[27870] = 724
LCT_SpellData[27871] = 724
LCT_SpellData[28275] = 724
LCT_SpellData[48086] = 724
LCT_SpellData[48087] = 724

-- Penance
LCT_SpellData[47540] = {
  class = "PRIEST",
  cooldown = 12,
  talent = true,
  specID = { SPEC_PRIEST_DISC },
}
LCT_SpellData[53005] = 47540
LCT_SpellData[53006] = 47540
LCT_SpellData[53007] = 47540

-- Dispersion
LCT_SpellData[47585] = {
  class = "PRIEST",
  cooldown = 120,
  talent = true,
  specID = { SPEC_PRIEST_SHADOW },
}

-- Guardian Spirit
LCT_SpellData[47788] = {
  class = "PRIEST",
  cooldown = 180,
  talent = true,
  specID = { SPEC_PRIEST_HOLY },
}
