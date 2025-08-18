-- ================ WARLOCK ================
-- Warlock/baseline
-- Soulstone
LCT_SpellData[20707] = {
	class = "WARLOCK",
	res = true,
	cooldown = 600
}
-- Unending Resolve
LCT_SpellData[104773] = {
	class = "WARLOCK",
	defensive = true,
	duration = 8,
	cooldown = 180
}
-- Demonic Circle: Teleport
LCT_SpellData[48020] = {
	class = "WARLOCK",
	defensive = true,
	cooldown = 30
}
-- Demonic gateway
LCT_SpellData[111771] = {
	class = "WARLOCK",
	defensive = true,
	cooldown = 10,
}

-- Warlock/talent
-- Dark Regeneration
LCT_SpellData[108359] = {
	class = "WARLOCK",
	talent = true,
	defensive = true,
	heal = true,
	duration = 12,
	cooldown = 120
}
-- Howl of Terror
LCT_SpellData[5484] = {
	class = "WARLOCK",
	talent = true,
	cc = true,
	cooldown = 40
}
-- Mortal Coil
LCT_SpellData[6789] = {
	class = "WARLOCK",
	talent = true,
	cc = true,
	heal = true,
	cooldown = 45
}
-- Shadowfury
LCT_SpellData[30283] = {
	class = "WARLOCK",
	talent = true,
	stun = true,
	cooldown = 30
}
-- Dark Bargain
LCT_SpellData[110913] = {
	class = "WARLOCK",
	talent = true,
	defensive = true,
	duration = 8,
	cooldown = 180
}
-- Sacrificial Pact
LCT_SpellData[108416] = {
	class = "WARLOCK",
	talent = true,
	defensive = true,
	duration = 20,
	cooldown = 60
}
-- Blood Horror
LCT_SpellData[111397] = {
	class = "WARLOCK",
	talent = true,
	cc = true,
	duration = 60,
	cooldown = 60
}
-- Unbound Will
LCT_SpellData[108482] = {
	class = "WARLOCK",
	talent = true,
	dispel = true,
	cooldown = 120
}
-- Grimoire of Service
LCT_SpellData[108501] = {
	class = "WARLOCK",
	talent = true,
	defensive = true,
	cooldown = 120
}
-- Kil'jaeden's Cunning
LCT_SpellData[108505] = {
	class = "WARLOCK",
	talent = true,
	offensive = true,
	duration = 8,
	cooldown = 60
}
-- Mannoroth's fury
LCT_SpellData[108508] = {
	class = "WARLOCK",
	talent = true,
	offensive = true,
	duration = 10,
	cooldown = 60
}
-- Warlock/265 - Affliction
-- Seed of Corruption
LCT_SpellData[87385] = {
	class = "WARLOCK",
	specID = { 265 },
	offensive = true,
	cooldown = 60
}
-- Dark Soul: Misery
LCT_SpellData[113860] = {
	class = "WARLOCK",
	specID = { 265 },
	offensive = true,
	duration = 20,
	cooldown = 120
}

-- Warlock/266 - Demonology
-- Demonic Leap
LCT_SpellData[109151] = {
	class = "WARLOCK",
	specID = { 266 },
	cooldown = 10
}
-- Dark Soul: Knowledge
LCT_SpellData[113861] = {
	class = "WARLOCK",
	specID = { 266 },
	offensive = true,
	duration = 20,
	cooldown = 120
}
-- Hand of Gul'dan
LCT_SpellData[105174] = {
	class = "WARLOCK",
	specID = { 266 },
	offensive = true,
	charges = 2,
	cooldown = 15
}

-- Warlock/267 - Destruction
-- Havoc
LCT_SpellData[80240] = {
	class = "WARLOCK",
	specID = { 267 },
	offensive = true,
	duration = 15,
	cooldown = 25 -- Will be 20 at lvl100
}
-- Flames of Xoroth
LCT_SpellData[120451] = {
	class = "WARLOCK",
	specID = { 267 },
	offensive = true,
	defensive = true,
	cooldown = 60
}
-- Dark Soul: Instability
LCT_SpellData[113858] = {
	class = "WARLOCK",
	specID = { 267 },
	offensive = true,
	duration = 20,
	cooldown = 120
}
-- Conflagrate
LCT_SpellData[17962] = {
	class = "WARLOCK",
	specID = { 267 },
	offensive = true,
	charges = 2,
	cooldown = 12
}

-- Warlock/Felguard
-- Axe Toss
LCT_SpellData[89766] = {
	class = "WARLOCK",
	pet = true,
	stun = true,
	cooldown = 30
}
-- Felstorm
LCT_SpellData[89751] = {
	class = "WARLOCK",
	pet = true,
	offensive = true,
	cooldown = 45
}
-- Pursuit
LCT_SpellData[30151] = {
	class = "WARLOCK",
	pet = true,
	offensive = true,
	cooldown = 15
}

-- Warlock/Felhunter
-- Devour Magic
LCT_SpellData[19505] = {
	class = "WARLOCK",
	pet = true,
	purge = true,
	cooldown = 15
}
-- Spell Lock
LCT_SpellData[19647] = {
	class = "WARLOCK",
	pet = true,
	interrupt = true,
	silence = true,
	cooldown = 24
}
LCT_SpellData[119910] = 19647
LCT_SpellData[132409] = 19647

-- Warlock/Observer
-- Clone Magic
LCT_SpellData[115284] = {
	class = "WARLOCK",
	pet = true,
	purge = true,
	cooldown = 15
}
-- Optical Blast
LCT_SpellData[115781] = {
	class = "WARLOCK",
	pet = true,
	interrupt = true,
	silence = true,
	cooldown = 24
}
LCT_SpellData[119911] = 115781


-- Warlock/Fel Imp
-- Sear Magic
LCT_SpellData[115276] = {
	class = "WARLOCK",
	pet = true,
	dispel = true,
	cooldown = 30
}

-- Warlock/Imp
-- Cauterize Master
LCT_SpellData[119899] = {
	class = "WARLOCK",
	pet = true,
	heal = true,
	duration = 12,
	cooldown = 30
}
-- Flee
LCT_SpellData[89792] = {
	class = "WARLOCK",
	pet = true,
	defensive = true,
	cooldown = 20
}
-- Single Magic
LCT_SpellData[89808] = {
	class = "WARLOCK",
	pet = true,
	dispel = true,
	cooldown = 10
}

-- Warlock/Shivarra
-- Fellash
LCT_SpellData[115770] = {
	class = "WARLOCK",
	pet = true,
	offensive = true,
	knockback = true,
	cooldown = 25
}

-- Warlock/Succubus
-- Whiplash
LCT_SpellData[6360] = {
	class = "WARLOCK",
	pet = true,
	offensive = true,
	knockback = true,
	cooldown = 25
}

-- Warlock/Voidlord

-- Warlock/Voidwalker
-- Shadow Bulwark
LCT_SpellData[17767] = {
	class = "WARLOCK",
	pet = true,
	defensive = true,
	duration = 20,
	cooldown = 120
}

-- Warlock/Wrathguard
-- Wrathstorm
LCT_SpellData[115831] = {
	class = "WARLOCK",
	pet = true,
	offensive = true,
	duration = 6,
	cooldown = 45
}
