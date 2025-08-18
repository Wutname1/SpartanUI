-- Racials
-- Gift of the Naaru (Draenei)
LCT_SpellData[28880] = {
	race = "Draenei",
	heal = true,
	duration = 5,
	cooldown = 180,
}

-- Will of the Forsaken (Undead)
LCT_SpellData[7744] = {
	race = "Scourge",
	cooldown = 120,
    sets_cooldowns = {
        -- PvP Trinket
        { spellid = 42292, cooldown = 45 },
        -- Will to Survive 
        { spellid = 59752, cooldown = 45 },
    },
}
-- Will to Survive / EMFH (Human)
LCT_SpellData[59752] = {
    race = "Human",
    cooldown = 120,
    sets_cooldowns = {
        -- WOTF
        { spellid = 7744, cooldown = 45 },
        -- PvP Trinket
        { spellid = 42292, cooldown = 120 },
    }
}
-- Arcane Torrent (Blood Elf)
LCT_SpellData[28730] = {
	race = "BloodElf",
	cooldown = 120,
  silence = true,
}
LCT_SpellData[25046] = 28730
-- Blood Fury (Orc)
LCT_SpellData[20572] = {
	race = "Orc",
	offensive = true,
	duration = 15,
	cooldown = 120,
}
LCT_SpellData[33697] = 20572
LCT_SpellData[33702] = 20572
-- Cannibalize (Undead)
LCT_SpellData[20577] = {
	race = "Scourge",
	heal = true,
	duration = 10,
	cooldown = 120,
}
-- Escape Artist (Gnome)
LCT_SpellData[20589] = {
	race = "Gnome",
	defensive = true,
	cooldown = 105,
}
-- Shadowmeld (Night Elf)
LCT_SpellData[58984] = {
	race = "NightElf",
	defensive = true,
	cooldown = 120,
}
-- Stoneform (Dwarf)
LCT_SpellData[20594] = {
	race = "Dwarf",
	defensive = true,
	duration = 8,
	cooldown = 120,
}
-- War Stomp (Tauren)
LCT_SpellData[20549] = {
	race = "Tauren",
	stun = true,
	duration = 2,
	cooldown = 120,
}
-- Berserking (Troll)
LCT_SpellData[26297] = {
	race = "Troll",
	offensive = true,
	duration = 10,
	cooldown = 180
}

