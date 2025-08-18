-- Racials
-- Gift of the Naaru (Draenei)
LCT_SpellData[59544] = {
	race = "Draenei",
	heal = true,
	duration = 5,
	cooldown = 180,
}

set_trinkets_emfh = {
	-- Gladiator's Medallion
	{ spellid = 336126, cooldown = 90 },
	-- Adaptation
	{ spellid = 336135, cooldown = 30 },
}

set_trinkets_wotf = {
	-- Gladiator's Medallion
	{ spellid = 336126, cooldown = 30 },
	-- Adaptation
	{ spellid = 336135, cooldown = 30 },
}
-- Every Man For Himself
LCT_SpellData[59752] = {
	race = "Human",
	sets_cooldowns = set_trinkets_emfh,
	cooldown = 180
}
-- Will of the Forsaken (Undead)
LCT_SpellData[7744] = {
	race = "Scourge",
	sets_cooldowns = set_trinkets_wotf, -- PvP trinket
	cooldown = 120,
}

LCT_SpellData[28880] = 59544
LCT_SpellData[59542] = 59544
LCT_SpellData[59543] = 59544
LCT_SpellData[59545] = 59544
LCT_SpellData[59547] = 59544
LCT_SpellData[59548] = 59544
LCT_SpellData[121093] = 59544
-- Arcane Torrent (Blood Elf)
LCT_SpellData[28730] = {
	race = "BloodElf",
	cooldown = 120,
}
LCT_SpellData[50613] = 28730
LCT_SpellData[80483] = 28730
LCT_SpellData[129597] = 28730
LCT_SpellData[155145] = 28730
LCT_SpellData[25046] = 28730
LCT_SpellData[69179] = 28730
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
-- Darkflight (Worgen)
LCT_SpellData[68992] = {
	race = "Worgen",
	duration = 10,
	cooldown = 120,
}
-- Escape Artist (Gnome)
LCT_SpellData[20589] = {
	race = "Gnome",
	defensive = true,
	cooldown = 60,
}
-- Quaking Palm (Pandaren)
LCT_SpellData[107079] = {
	race = "Pandaren",
	cc = true,
	cooldown = 120,
}
-- Rocket Barrage (Goblin)
LCT_SpellData[69041] = {
	race = "Goblin",
	offensive = true,
	sets_cooldown = { spellid = 69070, cooldown = 120 }, -- Rocket jump
	cooldown = 120,
}
-- Rocket Jump (Goblin)
LCT_SpellData[69070] = {
	race = "Goblin",
	sets_cooldown = { spellid = 69041, cooldown = 120 }, -- Rocket Barrage
	cooldown = 120,
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
-- Arcane Pulse (Nightborne)
LCT_SpellData[260364] = {
	race = "Nightborne",
	offensive = true,
	duration = 12,
	cooldown = 180
}
-- Bull Rush (HighmountainTauren)
LCT_SpellData[255654] = {
	race = "HighmountainTauren",
	offensive = true,
	cooldown = 120
}
-- Forge of Light (LightforgedDraenei)
LCT_SpellData[255647] = {
	race = "LightforgedDraenei",
	offensive = true,
	duration = 3,
	cooldown = 150, -- 2.5min
}
-- Spatial Rift (VoidElf)
LCT_SpellData[256948] = {
	race = "VoidElf",
	cooldown = 180,
}
-- Fireblood (DarkIronDward)
LCT_SpellData[265221] = {
	race = "DarkIronDwarf",
	cooldown = 120,
}
-- Wing Buffet (Dracthyr)
LCT_SpellData[357214] = {
	race = "Dracthyr",
	cooldown = 72,
	opt_lower_cooldown = 27 -- Reduced by the 'Heavy Wingbeats' talent
}
-- Tail Swipe (Dracthyr)
LCT_SpellData[368970] = {
	race = "Dracthyr",
	cooldown = 72,
	opt_lower_cooldown = 27 -- Reduced by the 'Clobbering Sweep' talent
}
