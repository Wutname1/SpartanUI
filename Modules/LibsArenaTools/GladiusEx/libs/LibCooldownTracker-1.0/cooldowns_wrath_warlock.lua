-- ================ WARLOCK ================

local SPEC_WARLOCK_AFFLICTION  = 265
local SPEC_WARLOCK_DEMONOLOGY  = 266
local SPEC_WARLOCK_DESTRUCTION = 267

-- Conflagrate
LCT_SpellData[17962] = {
  cooldown = 10,
  class = "WARLOCK",
  specID = { SPEC_WARLOCK_DESTRUCTION },
}

-- Suffering
LCT_SpellData[17735] = {
  class = "WARLOCK",
  cooldown = 120,
  pet = true,
}
LCT_SpellData[17750] = 17735
LCT_SpellData[17751] = 17735
LCT_SpellData[17752] = 17735
LCT_SpellData[27271] = 17735
LCT_SpellData[33701] = 17735
LCT_SpellData[47989] = 17735
LCT_SpellData[47990] = 17735

-- Shadowfury
LCT_SpellData[30283] = {
  class = "WARLOCK",
  cooldown = 20,
  specID = { SPEC_WARLOCK_DESTRUCTION },
}
LCT_SpellData[30413] = 30283
LCT_SpellData[30414] = 30283
LCT_SpellData[47846] = 30283
LCT_SpellData[47847] = 30283

-- Shadow Ward
LCT_SpellData[6229] = {
  class = "WARLOCK",
  cooldown = 30,
}
LCT_SpellData[11739] = 6229
LCT_SpellData[11740] = 6229
LCT_SpellData[28610] = 6229
LCT_SpellData[47890] = 6229
LCT_SpellData[47891] = 6229

-- Phase Shift
LCT_SpellData[4511] = {
  class = "WARLOCK",
  cooldown = 10,
  pet = true,
}

-- Inferno
LCT_SpellData[1122] = {
  class = "WARLOCK",
  cooldown = 600,
}

-- Ritual of Doom
LCT_SpellData[18540] = {
  class = "WARLOCK",
  cooldown = 1800,
}

-- Howl of Terror
LCT_SpellData[5484] = {
  class = "WARLOCK",
  cooldown = 40,
}
LCT_SpellData[17928] = 5484

-- Torment
LCT_SpellData[3716] = {
  class = "WARLOCK",
  cooldown = 5,
  pet = true,
}
LCT_SpellData[7809] = 3716
LCT_SpellData[7810] = 3716
LCT_SpellData[7811] = 3716
LCT_SpellData[11774] = 3716
LCT_SpellData[11775] = 3716
LCT_SpellData[27270] = 3716
LCT_SpellData[47984] = 3716

-- Death Coil
LCT_SpellData[6789] = {
  cooldown = 120,
  class = "WARLOCK",
}
LCT_SpellData[17925] = 6789
LCT_SpellData[17926] = 6789
LCT_SpellData[27223] = 6789
LCT_SpellData[47859] = 6789
LCT_SpellData[47860] = 6789

-- Lash of Pain
LCT_SpellData[7814] = {
  class = "WARLOCK",
  cooldown = 12,
  opt_lower_cooldown = 6,
  pet = true,
}
LCT_SpellData[7815] = 7814
LCT_SpellData[7816] = 7814
LCT_SpellData[11778] = 7814
LCT_SpellData[11779] = 7814
LCT_SpellData[11780] = 7814
LCT_SpellData[27274] = 7814
LCT_SpellData[47991] = 7814
LCT_SpellData[47992] = 7814

-- Soulshatter
LCT_SpellData[29858] = {
  class = "WARLOCK",
  cooldown = 180,
  pet = true,
}

-- Amplify Curse
LCT_SpellData[18288] = {
  class = "WARLOCK",
  cooldown = 180,
  talent = true,
  specID = { SPEC_WARLOCK_AFFLICTION },
}

-- Curse of Doom
LCT_SpellData[603] = {
  class = "WARLOCK",
  cooldown = 60,
}
LCT_SpellData[30910] = 603
LCT_SpellData[47867] = 603

-- Spell Lock
LCT_SpellData[19244] = {
  class = "WARLOCK",
  cooldown = 24,
  pet = true,
}
LCT_SpellData[19647] = 19244

-- Ritual of Souls
LCT_SpellData[29893] = {
  class = "WARLOCK",
  cooldown = 300,
}
LCT_SpellData[58887] = 29893

-- Shadowburn
LCT_SpellData[17877] = {
  cooldown = 15,
  class = "WARLOCK",
  specID = { SPEC_WARLOCK_DESTRUCTION },

}
LCT_SpellData[18867] = 17877
LCT_SpellData[18868] = 17877
LCT_SpellData[18869] = 17877
LCT_SpellData[18871] = 17877
LCT_SpellData[27263] = 17877
LCT_SpellData[18870] = 17877
LCT_SpellData[30546] = 17877
LCT_SpellData[47826] = 17877
LCT_SpellData[47827] = 17877

-- Soothing Kiss
LCT_SpellData[6360] = {
  class = "WARLOCK",
  cooldown = 4,
  pet = true,
}
LCT_SpellData[7813] = 6360
LCT_SpellData[11784] = 6360
LCT_SpellData[11785] = 6360
LCT_SpellData[27275] = 6360

-- Fel Domination
LCT_SpellData[18708] = {
  class = "WARLOCK",
  cooldown = 180,
}

-- Devour Magic
LCT_SpellData[19505] = {
  class = "WARLOCK",
  cooldown = 8,
  pet = true,
}
LCT_SpellData[19731] = 19505
LCT_SpellData[19734] = 19505
LCT_SpellData[19736] = 19505
LCT_SpellData[27276] = 19505
LCT_SpellData[27277] = 19505
LCT_SpellData[48011] = 19505

-- Chaos Bolt
LCT_SpellData[50796] = {
  class = "WARLOCK",
  cooldown = 12,
  talent = true,
  specID = { SPEC_WARLOCK_DESTRUCTION },
}

-- Haunt
LCT_SpellData[48141] = {
  class = "WARLOCK",
  cooldown = 8,
  talent = true,
  specID = { SPEC_WARLOCK_AFFLICTION },
}

-- Metamorphosis
LCT_SpellData[59672] = {
  class = "WARLOCK",
  cooldown = 180,
  talent = true,
  specID = { SPEC_WARLOCK_DEMONOLOGY },
}

-- Shadowflame
LCT_SpellData[47897] = {
  class = "WARLOCK",
  cooldown = 15,
}
LCT_SpellData[61290] = 47897

-- Demonic Circle: Teleport
LCT_SpellData[48020] = {
  class = "WARLOCK",
  cooldown = 30,
}
LCT_SpellData[61290] = 47897
