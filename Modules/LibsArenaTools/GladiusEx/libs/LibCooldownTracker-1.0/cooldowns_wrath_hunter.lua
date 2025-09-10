-- ================ HUNTER ================

local SPEC_HUNTER_BM   = 253
local SPEC_HUNTER_MM   = 254
local SPEC_HUNTER_SURV = 255

-- Distracting Shot
LCT_SpellData[20736] = {
  class = "HUNTER",
  cooldown = 8,
}

-- Flare
LCT_SpellData[1543] = {
  class = "HUNTER",
  cooldown = 20,
}

-- Feign Death
LCT_SpellData[5384] = {
  class = "HUNTER",
  cooldown = 30,
}

-- Disengage
LCT_SpellData[781] = {
  class = "HUNTER",
  cooldown = 25,
}

-- Scatter Shot
LCT_SpellData[19503] = {
  class = "HUNTER",
  cooldown = 30,
  talent = true,
  specID = { SPEC_HUNTER_MM },
}

-- Dash
LCT_SpellData[61684] = {
  class = "HUNTER",
  pet = true,
  cooldown = 32,
}

-- Deterrence
LCT_SpellData[19263] = {
  class = "HUNTER",
  cooldown = 90,
}

-- Scorpid Poison
LCT_SpellData[24640] = {
  class = "HUNTER",
  cooldown = 10,
}
LCT_SpellData[24583] = 24640
LCT_SpellData[24586] = 24640
LCT_SpellData[27060] = 24640
LCT_SpellData[24587] = 24640
LCT_SpellData[55728] = 24640

-- Tranquilizing Shot
LCT_SpellData[19801] = {
  class = "HUNTER",
  cooldown = 8,
}

-- Bite
LCT_SpellData[17253] = {
  class = "HUNTER",
  cooldown = 10,
}
LCT_SpellData[27050] = 17253
LCT_SpellData[17258] = 17253
LCT_SpellData[17259] = 17253
LCT_SpellData[17261] = 17253
LCT_SpellData[17260] = 17253
LCT_SpellData[17257] = 17253
LCT_SpellData[17256] = 17253
LCT_SpellData[17255] = 17253

-- Aimed Shot
LCT_SpellData[19434] = {
  class = "HUNTER",
  cooldown = 10,
}
LCT_SpellData[20900] = 19434
LCT_SpellData[20902] = 19434
LCT_SpellData[20903] = 19434
LCT_SpellData[20904] = 19434
LCT_SpellData[27065] = 19434
LCT_SpellData[20901] = 19434
LCT_SpellData[49049] = 19434
LCT_SpellData[49050] = 19434

-- Dive
LCT_SpellData[23145] = {
  class = "HUNTER",
  cooldown = 32,
}

-- Poison Spit
LCT_SpellData[35387] = {
  class = "HUNTER",
  cooldown = 10,
}
LCT_SpellData[35389] = 35387
LCT_SpellData[35392] = 35387
LCT_SpellData[55555] = 35387
LCT_SpellData[55556] = 35387
LCT_SpellData[55557] = 35387

-- Arcane Shot
LCT_SpellData[3044] = {
  class = "HUNTER",
  cooldown = 6,
  opt_lower_cooldown = 5,
}
LCT_SpellData[27019] = 3044
LCT_SpellData[14285] = 3044
LCT_SpellData[14283] = 3044
LCT_SpellData[14282] = 3044
LCT_SpellData[14281] = 3044
LCT_SpellData[14284] = 3044
LCT_SpellData[14286] = 3044
LCT_SpellData[14287] = 3044
LCT_SpellData[49044] = 3044
LCT_SpellData[49045] = 3044

-- Bestial Wrath
LCT_SpellData[19574] = {
  class = "HUNTER",
  cooldown = 120,
  talent = true,
  specID = { SPEC_HUNTER_BM },
}

-- Intimidation
LCT_SpellData[19577] = {
  class = "HUNTER",
  cooldown = 60,
  talent = true,
  specID = { SPEC_HUNTER_BM },
}

-- Prowl
LCT_SpellData[24450] = {
  class = "HUNTER",
  cooldown = 10,
}
LCT_SpellData[24452] = 24450
LCT_SpellData[24453] = 24450

-- Raptor Strike
LCT_SpellData[2973] = {
  class = "HUNTER",
  cooldown = 6,
}
LCT_SpellData[27014] = 2973
LCT_SpellData[14266] = 2973
LCT_SpellData[14261] = 2973
LCT_SpellData[14262] = 2973
LCT_SpellData[14260] = 2973
LCT_SpellData[14263] = 2973
LCT_SpellData[14264] = 2973
LCT_SpellData[14265] = 2973
LCT_SpellData[48995] = 2973
LCT_SpellData[48996] = 2973

-- Concussive Shot
LCT_SpellData[5116] = {
  opt_lower_cooldown = 12,
  class = "HUNTER",
  cooldown = 12,
}

-- Counterattack
LCT_SpellData[19306] = {
  class = "HUNTER",
  cooldown = 5,
}
LCT_SpellData[20909] = 19306
LCT_SpellData[20910] = 19306
LCT_SpellData[27067] = 19306
LCT_SpellData[48998] = 19306
LCT_SpellData[48999] = 19306

-- Wyvern Sting
LCT_SpellData[19386] = {
  class = "HUNTER",
  cooldown = 60,
  talent = true,
  specID = { SPEC_HUNTER_SURV },
}
LCT_SpellData[24132] = 19386
LCT_SpellData[24133] = 19386
LCT_SpellData[27068] = 19386
LCT_SpellData[49011] = 19386
LCT_SpellData[49012] = 19386

-- Snake Trap
LCT_SpellData[34600] = {
  opt_lower_cooldown = 24,
  class = "HUNTER",
  cooldown = 30,
}

-- Growl
LCT_SpellData[2649] = {
  class = "HUNTER",
  cooldown = 5,
}
LCT_SpellData[14918] = 2649
LCT_SpellData[14919] = 2649
LCT_SpellData[14921] = 2649
LCT_SpellData[14916] = 2649
LCT_SpellData[14917] = 2649
LCT_SpellData[27047] = 2649
LCT_SpellData[14920] = 2649
LCT_SpellData[61676] = 2649

-- Misdirection
LCT_SpellData[34477] = {
  class = "HUNTER",
  cooldown = 30,
}

-- Fire Breath
LCT_SpellData[34889] = {
  class = "HUNTER",
  cooldown = 10,
}
LCT_SpellData[35323] = 34889
LCT_SpellData[55482] = 34889
LCT_SpellData[55483] = 34889
LCT_SpellData[55484] = 34889
LCT_SpellData[55485] = 34889

-- Warp
LCT_SpellData[35346] = {
  class = "HUNTER",
  cooldown = 15,
}

-- Readiness
LCT_SpellData[23989] = {
  class = "HUNTER",
  cooldown = 180,
  talent = true,
  resets = { 5116, 34026, 53271, 1513, 3044, 20736, 1543, 53351, 2643, 3045, 19801, 3034, 19263, 781, 13813, 5384, 60192, 1499, 13809, 13795, 34477, 1495, 2973, 34600, 19434, 53209, 34490, 19503 },
  specID = { SPEC_HUNTER_MM },
}

-- Silencing Shot
LCT_SpellData[34490] = {
  class = "HUNTER",
  cooldown = 20,
  talent = true,
  specID = { SPEC_HUNTER_MM },
}

-- Cower
LCT_SpellData[1742] = {
  class = "HUNTER",
  cooldown = 45,
}

-- Shell Shield
LCT_SpellData[26064] = {
  class = "HUNTER",
  cooldown = 180,
  pet = true,
}

-- Mongoose Bite
LCT_SpellData[1495] = {
  class = "HUNTER",
  cooldown = 5,
}
LCT_SpellData[14269] = 1495
LCT_SpellData[14270] = 1495
LCT_SpellData[14271] = 1495
LCT_SpellData[36916] = 1495
LCT_SpellData[53339] = 1495

-- Viper Sting
LCT_SpellData[3034] = {
  class = "HUNTER",
  cooldown = 15,
}

-- Freezing Trap
LCT_SpellData[1499] = {
    opt_lower_cooldown = 24,
    class = "HUNTER",
    cooldown = 30,
    sets_cooldowns = {
        -- Freezing Arrow
        { spellid = 60192, cooldown = 30 },
    }
}
LCT_SpellData[14310] = 1499
LCT_SpellData[14311] = 1499

-- Pummel
LCT_SpellData[26090] = {
  class = "HUNTER",
  cooldown = 30,
}

-- Immolation Trap
LCT_SpellData[13795] = {
  opt_lower_cooldown = 24,
  class = "HUNTER",
  cooldown = 30,
}
LCT_SpellData[27023] = 13795
LCT_SpellData[14302] = 13795
LCT_SpellData[14303] = 13795
LCT_SpellData[14304] = 13795
LCT_SpellData[14305] = 13795
LCT_SpellData[49055] = 13795
LCT_SpellData[49056] = 13795

-- Rapid Fire
LCT_SpellData[3045] = {
  opt_lower_cooldown = 180,
  class = "HUNTER",
  cooldown = 300,
}
-- Volley
LCT_SpellData[1510] = {
  class = "HUNTER",
  cooldown = 60,
}
LCT_SpellData[27022] = 1510
LCT_SpellData[14294] = 1510
LCT_SpellData[14295] = 1510
LCT_SpellData[58431] = 1510
LCT_SpellData[58434] = 1510

-- Scare Beast
LCT_SpellData[1513] = {
  class = "HUNTER",
  cooldown = 30,
}
LCT_SpellData[14326] = 1513
LCT_SpellData[14327] = 1513

-- Kill Command
LCT_SpellData[34026] = {
  class = "HUNTER",
  cooldown = 60,
}

-- Furious Howl
LCT_SpellData[24604] = {
  class = "HUNTER",
  cooldown = 40,
}
LCT_SpellData[66491] = 24604
LCT_SpellData[66492] = 24604
LCT_SpellData[66493] = 24604
LCT_SpellData[66494] = 24604
LCT_SpellData[66495] = 24604

-- Frost Trap
LCT_SpellData[13809] = {
  opt_lower_cooldown = 24,
  class = "HUNTER",
  cooldown = 30,
}

-- Explosive Trap
LCT_SpellData[13813] = {
  opt_lower_cooldown = 24,
  class = "HUNTER",
  cooldown = 30,
}
LCT_SpellData[27025] = 13813
LCT_SpellData[14316] = 13813
LCT_SpellData[14317] = 13813
LCT_SpellData[49066] = 13813
LCT_SpellData[49067] = 13813

-- Multi-Shot
LCT_SpellData[2643] = {
  class = "HUNTER",
  cooldown = 10,
}
LCT_SpellData[27021] = 2643
LCT_SpellData[25294] = 2643
LCT_SpellData[14288] = 2643
LCT_SpellData[14289] = 2643
LCT_SpellData[14290] = 2643 
LCT_SpellData[49047] = 2643 
LCT_SpellData[49048] = 2643 

-- Chimera Shot
LCT_SpellData[53209] = {
  class = "HUNTER",
  cooldown = 10,
  talent = true,
  specID = { SPEC_HUNTER_MM },
}

-- Black Arrow
LCT_SpellData[3674] = {
  class = "HUNTER",
  cooldown = 30,
  talent = true,
  specID = { SPEC_HUNTER_SURV },
}

-- Explosive Shot
LCT_SpellData[53301] = {
  class = "HUNTER",
  cooldown = 6,
  talent = true,
  detects = { 3674 },
  specID = { SPEC_HUNTER_SURV },
}

-- Master's Call
LCT_SpellData[53271] = {
  class = "HUNTER",
  cooldown = 60,
}

-- Freezing Arrow
LCT_SpellData[60192] = {
  class = "HUNTER",
  cooldown = 30,
	sets_cooldowns = {
        -- Freezing Trap
        { spellid = 1499, cooldown = 30 },
	}
}
