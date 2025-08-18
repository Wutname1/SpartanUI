-- ================ PRIEST ================

local SPEC_PRIEST_DISC = 256
local SPEC_PRIEST_HOLY = 257
local SPEC_PRIEST_SHADOW = 258

-- Smite
LCT_SpellData[585] = {
	class = "PRIEST",
	reduce = { spellid = 88625, duration = 4 }, -- Chastise
	hidden = true
}

-- Priest/baseline
-- Shadow Word: Death
LCT_SpellData[32379] = {
	class = "PRIEST",
	talent = true,
	cooldown = 10,
}
-- Power Infusion
LCT_SpellData[10060] = {
	class = "PRIEST",
	talent = true,
	offensive = true,
	duration = 20,
	cooldown = 120,
}
-- Fade
LCT_SpellData[586] = {
	class = "PRIEST",
	defensive = true,
	duration = 1,
	cooldown = 20
}
-- Leap of Faith
LCT_SpellData[73325] = {
	class = "PRIEST",
	talent = true,
	defensive = true,
	cooldown = 90,
}
-- Desperate Prayer
LCT_SpellData[19236] = {
	class = "PRIEST",
	defensive = true,
	duration = 10,
	cooldown = 90
}
-- Mass Dispel
LCT_SpellData[32375] = {
	class = "PRIEST",
	talent = true,
	mass_dispel = true,
	cooldown = 45
}
-- Psychic Scream
LCT_SpellData[8122] = {
	class = "PRIEST",
	cc = true,
	cooldown = 30, -- Technically 45, but no one plays without the talent
}
-- Priest/talents
-- Thoughtsteal
LCT_SpellData[316262] = {
	class = "PRIEST",
	talent = true,
	duration = 20,
	cooldown = 90
}
-- Priest/mixed
-- Purify
LCT_SpellData[527] = {
	class = "PRIEST",
	dispel = true,
	cooldown_starts_on_dispel = true,
	cooldown = 8,
	opt_charges = 2 -- With PVP talent, disc only
}
-- Shadowfiend
LCT_SpellData[34433] = {
	class = "PRIEST",
	talent = true,
	offensive = true,
	duration = 12,
	cooldown = 180,
}
-- Priest/mixed/talents
-- Divine Star
LCT_SpellData[110744] = {
	class = "PRIEST",
	talent = true,
	heal = true,
	cooldown = 15
}
-- Angelic Feather
LCT_SpellData[121536] = {
	class = "PRIEST",
	talent = true,
	charges = 3,
	cooldown = 20
}
-- Halo
LCT_SpellData[120517] = {
	class = "PRIEST",
	talent = true,
	heal = true,
	cooldown = 60
}

-- Priest/Discipline
-- Dark Archangel
LCT_SpellData[197871] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	talent = true,
	offensive = true,
	duration = 8,
	cooldown = 60
}
-- Ultimate Penitence
LCT_SpellData[421453] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	talent = true,
	defensive = true,
	duration = 6,
	cooldown = 240
}
-- Archangel
LCT_SpellData[197862] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	talent = true,
	offensive = true,
	duration = 15,
	cooldown = 60
}
-- Penance
LCT_SpellData[47540] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	heal = true,
	duration = 2,
	cooldown = 9,
}
-- Pain Suppression
LCT_SpellData[33206] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	defensive = true,
	duration = 8,
	cooldown = 180,
	opt_charges = 2
}
-- Power Word: Radiance
LCT_SpellData[194509] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	defensive = true,
	cooldown = 20,
	charges = 2,
}
-- Power Word: Barrier
LCT_SpellData[62618] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	defensive = true,
	duration = 10,
	cooldown = 180,
	opt_lower_cooldown = 90, -- with Dome of Light
}
-- Rapture
LCT_SpellData[47536] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	defensive = true,
	duration = 8,
	cooldown = 90,
}

-- Priest/Discipline/talents
-- Schism
LCT_SpellData[214621] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	talent = true,
	offensive = true,
	cooldown = 24,
}
-- Evangelism
--LCT_SpellData[246287] = {
--	class = "PRIEST",
--	specID = { SPEC_PRIEST_DISC },
--	talent = true,
--	duration = 6,
--	cooldown = 90,
--}
-- Mindbender (Disc)
LCT_SpellData[123040] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	talent = true,
	offensive = true,
	duration = 12,
	cooldown = 60,
	replaces = 34433, -- Shadowfiend
}

-- Priest/Holy
-- Symbol of hope
LCT_SpellData[64901] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	talent = true,
	defensive = true,
	duration = 4,
	cooldown = 180
}
-- Prayer of Mending
LCT_SpellData[33076] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	heal = true,
	cooldown = 12
}
-- Guardian Spirit
LCT_SpellData[47788] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	defensive = true,
	duration = 10,
	cooldown = 180,
	cooldown_on_full_aura_duration = 60,
}
-- Apotheosis
LCT_SpellData[200183] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	talent = true,
	defensive = true,
	duration = 20,
	cooldown = 120,
}
-- Divine Hymn
LCT_SpellData[64843] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	heal = true,
	duration = 8,
	cooldown = 180, -- Seraphic Crescendo
	opt_cooldown = 120,
}
-- Holy Word: Chastise
LCT_SpellData[88625] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	cc = true,
	cooldown = 60
}
-- Holy Word: Serenity
LCT_SpellData[2050] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	heal = true,
	cooldown = 60,
	opt_charges = 2
}
-- Circle of Healing
LCT_SpellData[204883] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	heal = true,
	cooldown = 15,
}
-- Priest/Holy/talents
-- Ray of Hope
LCT_SpellData[197268] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	talent = true,
	cooldown = 90,
	duration = 6,
}
-- Holy Word: Sanctify
LCT_SpellData[34861] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	heal = true,
	cooldown = 60,
	opt_charges = 2,
}
-- Holy Ward
LCT_SpellData[213610] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	talent = true,
	defensive = true,
	cooldown = 45
}
-- Holy Word: Salvation
LCT_SpellData[265202] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	talent = true,
	defensive = true,
	cooldown = 720 -- 12min
}
-- Divine Ascension
LCT_SpellData[328530] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	talent = true,
	cooldown = 60
}
-- Greater Heal
LCT_SpellData[289666] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	talent = true,
	heal = true,
	cooldown = 12
}
-- Spirit of the Redeemer
LCT_SpellData[215982] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_HOLY },
	talent = true,
	cooldown = 120,
	duration = 8,
	-- replaces = 20711 -- Spirit of Redemption
}

-- Priest/Shadow
-- Mind Blast
LCT_SpellData[8092] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_SHADOW },
	offensive = true,
	cooldown = 9,
}
-- Dispersion
LCT_SpellData[47585] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_SHADOW },
	defensive = true,
	duration = 6,
	cooldown = 120, -- ?
}
-- Vampiric Embrace
LCT_SpellData[15286] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_SHADOW },
	defensive = true,
	duration = 12,
	cooldown = 120
}
-- Silence
LCT_SpellData[15487] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_SHADOW },
	silence = true,
	cooldown = 45
}
-- Priest/Shadow/talents
-- Void torrent
LCT_SpellData[263165] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_SHADOW },
	talent = true,
	cooldown = 45
}
-- Void Eruption
LCT_SpellData[228260] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_SHADOW },
	talent = true,
	duration = 20,
	cooldown = 120
}
-- Mindbender (Shadow)
LCT_SpellData[200174] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_DISC },
	talent = true,
	offensive = true,
	duration = 15,
	cooldown = 60,
	replaces = 34433, -- Shadowfiend
}
-- Psychic Horror
LCT_SpellData[64044] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_SHADOW },
	talent = true,
	cc = true,
	cooldown = 45
}
-- Void Shift
LCT_SpellData[108968] = {
	class = "PRIEST",
	_talent = true,
	cooldown = 300
}
-- Psyfiend
LCT_SpellData[211522] = {
	class = "PRIEST",
	specID = { SPEC_PRIEST_SHADOW },
	talent = true,
	cooldown = 45,
	duration = 12,
}
-- Mindgames
LCT_SpellData[375901] = {
	class = "PRIEST",
	offensive = true,
	duration = 5,
	cooldown = 45,
}
