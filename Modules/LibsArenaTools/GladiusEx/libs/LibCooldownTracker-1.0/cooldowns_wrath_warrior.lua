-- ================ WARRIOR ================

local SPEC_WARRIOR_ARMS = 71
local SPEC_WARRIOR_FURY = 72
local SPEC_WARRIOR_PROT = 73

-- Death Wish
LCT_SpellData[12292] = {
  class = "WARRIOR",
  cooldown = 180,
  talent = true,
  duration = 30,
  specID = { SPEC_WARRIOR_FURY },
}

-- Shield Block
LCT_SpellData[2565] = {
  class = "WARRIOR",
  cooldown = 60,
}

-- Mortal Strike
LCT_SpellData[12294] = {
  class = "WARRIOR",
  cooldown = 5,
  talent = true,
  specID = { SPEC_WARRIOR_ARMS },
}
LCT_SpellData[21551] = 12294
LCT_SpellData[21552] = 12294
LCT_SpellData[21553] = 12294
LCT_SpellData[25248] = 12294
LCT_SpellData[30330] = 12294
LCT_SpellData[47485] = 12294
LCT_SpellData[47486] = 12294

-- Bloodthirst
LCT_SpellData[23881] = {
  class = "WARRIOR",
  cooldown = 4,
  talent = true,
  detects = { 12292 },
  specID = { SPEC_WARRIOR_FURY },
}

-- Intervene
LCT_SpellData[3411] = {
  class = "WARRIOR",
  cooldown = 30,
}

-- Taunt
LCT_SpellData[355] = {
  class = "WARRIOR",
  cooldown = 8,
}

-- Charge
LCT_SpellData[100] = {
  class = "WARRIOR",
  cooldown = 15,
}
LCT_SpellData[6178] = 100
LCT_SpellData[11578] = 100

-- Spell Reflection
LCT_SpellData[23920] = {
  class = "WARRIOR",
  cooldown = 10,
}

-- Shield Slam
LCT_SpellData[23922] = {
  class = "WARRIOR",
  cooldown = 6,
}
LCT_SpellData[23923] = 23922
LCT_SpellData[23924] = 23922
LCT_SpellData[25258] = 23922
LCT_SpellData[23925] = 23922
LCT_SpellData[30356] = 23922
LCT_SpellData[47487] = 23922
LCT_SpellData[47488] = 23922

-- Intimidating Shout
LCT_SpellData[5246] = {
  class = "WARRIOR",
  cooldown = 120,
}

-- Challenging Shout
LCT_SpellData[1161] = {
  class = "WARRIOR",
  cooldown = 180,
}

-- Whirlwind
LCT_SpellData[1680] = {
  class = "WARRIOR",
  cooldown = 10,
}

-- Concussion Blow
LCT_SpellData[12809] = {
  class = "WARRIOR",
  cooldown = 30,
  talent = true,
  specID = { SPEC_WARRIOR_PROT },
}

-- Pummel
LCT_SpellData[6552] = {
  class = "WARRIOR",
  cooldown = 10,
  interrupt = true,
}
LCT_SpellData[72] = 6552
LCT_SpellData[1671] = 6552
LCT_SpellData[1672] = 6552
LCT_SpellData[6554] = 6552
LCT_SpellData[29704] = 6552

-- Berserker Rage
LCT_SpellData[18499] = {
  class = "WARRIOR",
  cooldown = 30,
}

-- Disarm
LCT_SpellData[676] = {
  class = "WARRIOR",
  cooldown = 60,
}

-- Revenge
LCT_SpellData[6572] = {
  class = "WARRIOR",
  cooldown = 5,
  specID = { SPEC_WARRIOR_PROT },
}
LCT_SpellData[6574] = 6572
LCT_SpellData[7379] = 6572
LCT_SpellData[11600] = 6572
LCT_SpellData[11601] = 6572
LCT_SpellData[25269] = 6572
LCT_SpellData[25288] = 6572
LCT_SpellData[30357] = 6572
LCT_SpellData[57823] = 6572

-- Last Stand
LCT_SpellData[12975] = {
  class = "WARRIOR",
  cooldown = 180,
  talent = true,
  duration = 20,
  specID = { SPEC_WARRIOR_PROT },
}

-- Recklessness
LCT_SpellData[1719] = {
  class = "WARRIOR",
  cooldown = 300,
}

-- Thunder Clap
LCT_SpellData[6343] = {
  class = "WARRIOR",
  cooldown = 6,
}
LCT_SpellData[8198] = 6343
LCT_SpellData[8205] = 6343
LCT_SpellData[8204] = 6343
LCT_SpellData[11580] = 6343
LCT_SpellData[11581] = 6343
LCT_SpellData[25264] = 6343
LCT_SpellData[47501] = 6343
LCT_SpellData[47502] = 6343

-- Retaliation
LCT_SpellData[20230] = {
  class = "WARRIOR",
  cooldown = 300,
  duration = 12,
}

-- Mocking Blow
LCT_SpellData[694] = {
  class = "WARRIOR",
  cooldown = 60,
}

-- Shield Wall
LCT_SpellData[871] = {
  class = "WARRIOR",
  cooldown = 300,
  duration = 12,
}

-- Bloodrage
LCT_SpellData[2687] = {
  class = "WARRIOR",
  cooldown = 60,
}

-- Sweeping Strikes
LCT_SpellData[12328] = {
  class = "WARRIOR",
  cooldown = 30,
}

-- Intercept
LCT_SpellData[20252] = {
  class = "WARRIOR",
  cooldown = 30,
}

-- Overpower
LCT_SpellData[7384] = {
  class = "WARRIOR",
  cooldown = 5,
}

-- Shockwave
LCT_SpellData[46968] = {
  class = "WARRIOR",
  cooldown = 20,
  talent = true,
  specID = { SPEC_WARRIOR_PROT },
}

-- Bladestorm
LCT_SpellData[46924] = {
  class = "WARRIOR",
  cooldown = 90,
  talent = true,
  specID = { SPEC_WARRIOR_ARMS },
}

-- Shattering Throw
LCT_SpellData[64382] = {
  class = "WARRIOR",
  cooldown = 300,
}

-- Heroic Throw
LCT_SpellData[57755] = {
  class = "WARRIOR",
  cooldown = 60,
}

