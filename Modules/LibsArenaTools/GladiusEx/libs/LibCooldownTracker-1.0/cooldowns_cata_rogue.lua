-- ================ ROGUE ================

local SPEC_ROGUE_ASSA = 259
local SPEC_ROGUE_COMBAT = 260
local SPEC_ROGUE_SUB = 261

-- Blind
LCT_SpellData[2094] = {
  class = "ROGUE",
  opt_lower_cooldown = 120,
  cooldown_overload = { [SPEC_ROGUE_SUB] = 120, },
  cooldown = 180,
}

-- Blade Flurry
LCT_SpellData[13877] = {
  cooldown = 120,
  class = "ROGUE",
  talent = true,
  specID = { SPEC_ROGUE_COMBAT },
}

-- Cold Blood
LCT_SpellData[14177] = {
  cooldown = 180,
  class = "ROGUE",
  cooldown_starts_on_aura_fade = true,
  talent = true,
  specID = { SPEC_ROGUE_ASSA },
}

-- Shadowstep
LCT_SpellData[36554] = {
  cooldown = 30,
  class = "ROGUE",
  specID = { SPEC_ROGUE_SUB },
}

-- Kick
LCT_SpellData[1766] = {
  cooldown = 10,
  class = "ROGUE",
  interrupt = true,
}

-- Distract
LCT_SpellData[1725] = {
  cooldown = 30,
  class = "ROGUE",
}

-- Evasion
LCT_SpellData[5277] = {
  class = "ROGUE",
  cooldown = 180,
}
LCT_SpellData[26669] = 5277

-- Sprint
LCT_SpellData[2983] = {
  class = "ROGUE",
  cooldown = 60,
}
LCT_SpellData[8696] = 2983
LCT_SpellData[11305] = 2983

-- Vanish
LCT_SpellData[1856] = {
  class = "ROGUE",
  cooldown = 180,
  opt_lower_cooldown = 120,
  cooldown_overload = { [SPEC_ROGUE_SUB] = 120, },
}
LCT_SpellData[1857] = 1856
LCT_SpellData[26889] = 1856

-- Riposte
LCT_SpellData[14251] = {
  cooldown = 6,
  class = "ROGUE",
  talent = true,
  specID = { SPEC_ROGUE_COMBAT },
}

-- Feint
LCT_SpellData[1966] = {
  cooldown = 10,
  class = "ROGUE",
}
LCT_SpellData[6768] = 1966
LCT_SpellData[8637] = 1966
LCT_SpellData[11303] = 1966
LCT_SpellData[25302] = 1966
LCT_SpellData[27448] = 1966
LCT_SpellData[48658] = 1966
LCT_SpellData[48659] = 1966

-- Stealth
LCT_SpellData[1784] = {
  class = "ROGUE",
  opt_lower_cooldown = 2, -- Nightstalker talent
  cooldown_starts_on_aura_fade = true,
  cooldown = 6,
}

-- Adrenaline Rush
LCT_SpellData[13750] = {
  cooldown = 180,
  class = "ROGUE",
  talent = true,
  specID = { SPEC_ROGUE_COMBAT },
}

-- Premeditation
-- Cannot track this as it's primarily in Stealth...
--LCT_SpellData[14183] = {
--  cooldown = 120,
--  class = "ROGUE",
--  talent = true,
--}

-- Preparation
LCT_SpellData[14185] = {
  cooldown = 600,
  class = "ROGUE",
  specID = { SPEC_ROGUE_SUB },
  talent = true,
  resets = {
    -- Always reset
    5277, 2983, 1856, 14177, 36554,
    -- Only reset with the glyph, but we consider everyone uses said glyph
    1766, 51722, 76577
  },
}

-- Kidney Shot
LCT_SpellData[408] = {
  cooldown = 20,
  class = "ROGUE",
}
LCT_SpellData[8643] = 408

-- Gouge
LCT_SpellData[1776] = {
  class = "ROGUE",
  cooldown = 10,
}

-- Cloak of Shadows
LCT_SpellData[31224] = {
  cooldown = 120,
  class = "ROGUE",
  opt_lower_cooldown = 90,
  cooldown_overload = { [SPEC_ROGUE_SUB] = 90, },
  sets_cooldown = { spellid = 74001, cooldown = 90 }, -- Combat Readiness
}

-- Combat Readiness
LCT_SpellData[74001] = {
  cooldown = 120,
  opt_lower_cooldown = 90,
  class = "ROGUE",
  cooldown_overload = { [SPEC_ROGUE_SUB] = 90, },
  sets_cooldown = { spellid = 31224, cooldown = 90 }, -- Cloak of Shadows
}

-- Shadow Dance
LCT_SpellData[51713] = {
  class = "ROGUE",
  cooldown = 60,
  talent = true,
  specID = { SPEC_ROGUE_SUB },
}

-- Dismantle
LCT_SpellData[51722] = {
  class = "ROGUE",
  cooldown = 60,
}

-- Killing Spree
LCT_SpellData[51690] = {
  class = "ROGUE",
  cooldown = 120,
  talent = true,
  specID = { SPEC_ROGUE_COMBAT },
}
