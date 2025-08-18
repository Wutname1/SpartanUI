-- ================ PALADIN ================

local SPEC_PALADIN_HOLY        = 65
local SPEC_PALADIN_PROTECTION  = 66
local SPEC_PALADIN_RETRIBUTION = 70

-- Rebuke
LCT_SpellData[96231] = {
  cooldown = 10,
  class = "PALADIN",
  duration = 10,
}

-- Hand of Freedom
LCT_SpellData[1044] = {
  class = "PALADIN",
  cooldown = 25,
  opt_lower_cooldown = 20,
  cooldown_overload = { [SPEC_PALADIN_RETRIBUTION] = 20, },
}

-- Crusader Strike
LCT_SpellData[35395] = {
  class = "PALADIN",
  cooldown = 4.5,
}

-- Hand of Sacrifice
LCT_SpellData[6940] = {
  class = "PALADIN",
  cooldown = 120,
  opt_lower_cooldown = 96,
  cooldown_overload = { [SPEC_PALADIN_RETRIBUTION] = 96, [SPEC_PALADIN_HOLY] = 90, },
}

-- Word of Glory
LCT_SpellData[85673] = {
  class = "PALADIN",
  cooldown = 20,
}

-- Word of Glory
LCT_SpellData[85673] = {
  class = "PALADIN",
  cooldown = 120,
  specID = { SPEC_PALADIN_HOLY },
  talent = true,
}

-- Lay on Hands
LCT_SpellData[633] = {
  cooldown = 600,
  opt_lower_cooldown = 420, -- Glyph of Lay on Hands
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
  opt_lower_cooldown = 120,
  cooldown_overload = { [SPEC_PALADIN_HOLY] = 120, },
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
  cooldown = 60,
  opt_lower_cooldown = 40,
  cooldown_overload = { [SPEC_PALADIN_HOLY] = 40, [SPEC_PALADIN_PROTECTION] = 40, }, -- Note: Early Prot talent is picked by Prot and Holy
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

-- Guardian of Ancient Kings
LCT_SpellData[86150] = {
  class = "PALADIN",
  cooldown = 300,
  duration = 30,
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
  cooldown = 30,
  opt_lower_cooldown = 24, -- Glyph of Consecration
}
LCT_SpellData[20922] = 26573
LCT_SpellData[20923] = 26573
LCT_SpellData[20924] = 26573
LCT_SpellData[27173] = 26573
LCT_SpellData[20116] = 26573
LCT_SpellData[48818] = 26573
LCT_SpellData[48819] = 26573

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
  cooldown = 60,
  opt_lower_cooldown = 30,
  cooldown_overload = { [SPEC_PALADIN_HOLY] = 30, },
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
  cooldown = 15,
}
LCT_SpellData[10318] = 2812
LCT_SpellData[27139] = 2812
LCT_SpellData[48816] = 2812
LCT_SpellData[48817] = 2812

-- Hand of Protection
LCT_SpellData[1022] = {
  opt_lower_cooldown = 180,
  cooldown_overload = { [SPEC_PALADIN_RETRIBUTION] = 180 },
  cooldown = 300,
  class = "PALADIN",
}
LCT_SpellData[5599] = 1022
LCT_SpellData[10278] = 1022

-- Divine Storm
LCT_SpellData[53385] = {
  class = "PALADIN",
  cooldown = 4.5,
  talent = true,
  specID = { SPEC_PALADIN_RETRIBUTION },
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
