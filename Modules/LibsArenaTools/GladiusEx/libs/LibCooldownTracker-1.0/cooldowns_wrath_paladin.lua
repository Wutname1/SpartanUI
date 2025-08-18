-- ================ PALADIN ================

local SPEC_PALADIN_HOLY        = 65
local SPEC_PALADIN_PROTECTION  = 66
local SPEC_PALADIN_RETRIBUTION = 70

-- Blessing of Freedom
LCT_SpellData[1044] = {
  class = "PALADIN",
  cooldown = 25,
}

-- Divine Intervention
LCT_SpellData[19752] = {
  class = "PALADIN",
  cooldown = 600,
}

-- Crusader Strike
LCT_SpellData[35395] = {
  class = "PALADIN",
  cooldown = 4,
}

-- Hand of Sacrifice
LCT_SpellData[6940] = {
  class = "PALADIN",
  cooldown = 120,
}

-- Lay on Hands
LCT_SpellData[633] = {
  opt_lower_cooldown = 2400,
  cooldown = 1200,
  class = "PALADIN",
}
LCT_SpellData[2800] = 633
LCT_SpellData[10310] = 633
LCT_SpellData[27154] = 633
LCT_SpellData[48788] = 633

-- Exorcism
LCT_SpellData[879] = {
  class = "PALADIN",
  cooldown = 15,
}
LCT_SpellData[5614] = 879
LCT_SpellData[5615] = 879
LCT_SpellData[10312] = 879
LCT_SpellData[10313] = 879
LCT_SpellData[10314] = 879
LCT_SpellData[27138] = 879
LCT_SpellData[48800] = 879
LCT_SpellData[48801] = 879

-- Avenging Wrath
LCT_SpellData[31884] = {
  class = "PALADIN",
  cooldown = 180,
}

-- Divine Illumination
LCT_SpellData[31842] = {
  class = "PALADIN",
  cooldown = 180,
  talent = true,
  specID = { SPEC_PALADIN_HOLY },
}

-- Hammer of Justice
LCT_SpellData[853] = {
  opt_lower_cooldown = 45,
  cooldown = 60,
  class = "PALADIN",
}
LCT_SpellData[5588] = 853
LCT_SpellData[5589] = 853
LCT_SpellData[10308] = 853

-- Divine Shield
LCT_SpellData[642] = {
  class = "PALADIN",
  cooldown = 300,
}

-- Holy Shield
LCT_SpellData[20925] = {
  class = "PALADIN",
  cooldown = 8,
  talent = true,
  specID = { SPEC_PALADIN_PROTECTION },
}
LCT_SpellData[20927] = 20925
LCT_SpellData[20928] = 20925
LCT_SpellData[27179] = 20925
LCT_SpellData[48951] = 20925
LCT_SpellData[48952] = 20925

-- Avenger's Shield
LCT_SpellData[31935] = {
  class = "PALADIN",
  cooldown = 30,
  talent = true,
  detects = { 20925 },
  specID = { SPEC_PALADIN_PROTECTION },
}
LCT_SpellData[32699] = 31935
LCT_SpellData[32700] = 31935
LCT_SpellData[48826] = 31935
LCT_SpellData[48827] = 31935

-- Judgement
LCT_SpellData[20271] = {
  opt_lower_cooldown = 8,
  cooldown = 10,
  class = "PALADIN",
}

-- Consecration
LCT_SpellData[26573] = {
  class = "PALADIN",
  cooldown = 8,
}
LCT_SpellData[20922] = 26573
LCT_SpellData[20923] = 26573
LCT_SpellData[20924] = 26573
LCT_SpellData[27173] = 26573
LCT_SpellData[20116] = 26573
LCT_SpellData[48818] = 26573
LCT_SpellData[48819] = 26573

-- Divine Favor
LCT_SpellData[20216] = {
  class = "PALADIN",
  cooldown = 120,
  talent = true,
  specID = { SPEC_PALADIN_HOLY },
}

-- Righteous Defense
LCT_SpellData[31789] = {
  class = "PALADIN",
  cooldown = 8,
}

-- Hammer of Wrath
LCT_SpellData[24275] = {
  class = "PALADIN",
  cooldown = 6,
}
LCT_SpellData[24239] = 24275
LCT_SpellData[24274] = 24275
LCT_SpellData[27180] = 24275
LCT_SpellData[48805] = 24275
LCT_SpellData[48806] = 24275

-- Repentance
LCT_SpellData[20066] = {
  class = "PALADIN",
  cooldown = 60,
  talent = true,
  specID = { SPEC_PALADIN_RETRIBUTION },
}

-- Divine Protection
LCT_SpellData[498] = {
  class = "PALADIN",
  cooldown = 180,
}

-- Holy Shock
LCT_SpellData[20473] = {
  class = "PALADIN",
  cooldown = 6,
  talent = true,
  detects = { 20216 },
  specID = { SPEC_PALADIN_HOLY },
}
LCT_SpellData[20929] = 20473
LCT_SpellData[20930] = 20473
LCT_SpellData[27174] = 20473
LCT_SpellData[33072] = 20473
LCT_SpellData[48824] = 20473
LCT_SpellData[48825] = 20473

-- Holy Wrath
LCT_SpellData[2812] = {
  class = "PALADIN",
  cooldown = 30,
}
LCT_SpellData[10318] = 2812
LCT_SpellData[27139] = 2812
LCT_SpellData[48816] = 2812
LCT_SpellData[48817] = 2812

-- Blessing of Protection
LCT_SpellData[1022] = {
  opt_lower_cooldown = 180,
  cooldown = 300,
  class = "PALADIN",
}
LCT_SpellData[5599] = 1022
LCT_SpellData[10278] = 1022

-- Divine Storm
LCT_SpellData[53385] = {
  class = "PALADIN",
  cooldown = 10,
  talent = true,
  specID = { SPEC_PALADIN_PROTECTION },
}

-- Hammer of the Righteous
LCT_SpellData[53595] = {
  class = "PALADIN",
  cooldown = 6,
  talent = true,
  specID = { SPEC_PALADIN_HOLY },
}

-- Divine Plea
LCT_SpellData[54428] = {
  class = "PALADIN",
  cooldown = 60,
  talent = true,
  specID = { SPEC_PALADIN_HOLY },
}

-- Shield of Righteousness
LCT_SpellData[53600] = {
  class = "PALADIN",
  cooldown = 6,
}
LCT_SpellData[61411] = 53600
