-- ================ ROGUE ================

-- Classification structure:
--	Rogue/baseline
--	Rogue/talents
--	Rogue/Assassination
--	Rogue/Assassination/talents
--	Rogue/Outlaw
--	Rogue/Outlaw/talents
--	Rogue/Subtlety
--	Rogue/Subtetly/talents
--	Rogue/Multispec/talents


local SPEC_ROGUE_ASSA = 259
local SPEC_ROGUE_OUTLAW = 260
local SPEC_ROGUE_SUB = 261

-- Rogue/baseline
-- Kick
LCT_SpellData[1766] = {
	class = "ROGUE",
	interrupt = true,
	cooldown = 15
}
-- Crimson Vial
LCT_SpellData[185311] = {
	class = "ROGUE",
	heal = true,
	duration = 6,
	cooldown = 30
}
-- Kidney Shot
LCT_SpellData[408] = {
	class = "ROGUE",
	stun = true,
	cooldown = 20
}
-- Sprint
LCT_SpellData[2983] = {
	class = "ROGUE",
	duration = 8,
	cooldown = 60,
	opt_lower_cooldown = 30, -- 197000 Maneuverability
}
-- Vanish
LCT_SpellData[1856] = {
	class = "ROGUE",
	defensive = true,
	duration = 3,
	cooldown = 120,
	opt_charges = 2,
	reduce = {
		specID = SPEC_ROGUE_SUB,
		all = true,
		duration = 30, -- 382523 Invigorating Shadowdust
	}
}
-- Rogue/talents
-- Blind
LCT_SpellData[2094] = {
	class = "ROGUE",
	_talent = true,
	cc = true,
	cooldown = 120,
}
-- Cloak of Shadows
LCT_SpellData[31224] = {
	class = "ROGUE",
	_talent = true,
	defensive = true,
	duration = 5,
	cooldown = 120
}
-- Evasion
LCT_SpellData[5277] = {
	class = "ROGUE",
	_talent = true,
	defensive = true,
	duration = 10,
	cooldown = 120
}
-- Feint
LCT_SpellData[1966] = {
	class = "ROGUE",
	talent = true,
	defensive = true,
	duration = 6,
	cooldown = 15
}
-- Shadowstep
LCT_SpellData[36554] = {
	class = "ROGUE",
	talent = true,
	cooldown = 24,
	charges = 2, -- note: subs always have 2 charges of this; but code doesn't handle such cases
}
-- Shiv
LCT_SpellData[5938] = {
	class = "ROGUE",
	talent = true,
	cooldown = 25,
	opt_charges = 2, -- 394983 Lightweight Shiv
}
-- Gouge
LCT_SpellData[1776] = {
	class = "ROGUE",
	talent = true,
	cc = true,
	cooldown = 20,
}
-- Tricks of the Trade
LCT_SpellData[57934] = {
	class = "ROGUE",
	talent = true,
	cooldown = 30,
}
-- Cold Blood
LCT_SpellData[382245] = {
	class = "ROGUE",
	talent = true,
	cooldown_starts_on_aura_fade = true,
	cooldown = 45,
}
-- Marked for death
LCT_SpellData[137619] = {
	class = "ROGUE",
	talent = true,
	cooldown = 60
}
-- Echoing Reprimand
LCT_SpellData[385616] = {
	class = "ROGUE",
	talent = true,
	offensive = true,
	cooldown = 45
}
-- Thistle Tea
LCT_SpellData[381623] = {
	class = "ROGUE",
	talent = true,
	offensive = true,
	cooldown = 60,
	charges = 3,
}
-- Shadow Dance
-- Rogue committee needs to be summoned for this one
LCT_SpellData[185313] = {
	class = "ROGUE",
	talent = true,
	offensive = true,
	duration = 6,
	cooldown = 60,
	opt_charges = 2,
}
-- Dismantle
LCT_SpellData[207777] = {
	class = "ROGUE",
	talent = true,
	cc = true,
	cooldown = 45,
}
-- Smoke Bomb
LCT_SpellData[212182] = {
	class = "ROGUE",
	talent = true,
	duration = 5,
	cooldown = 180
}
-- Death from Above
LCT_SpellData[269513] = {
	class = "ROGUE",
	talent = true,
	offensive = true,
	cooldown = 30
}
-- Rogue/Assassination
-- Garrote
LCT_SpellData[703] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_ASSA },
	silence = true,
	cooldown = 6
}
-- Rogue/Assassination/talents
-- Deathmark
LCT_SpellData[360194] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_ASSA },
	offensive = true,
	cooldown = 120,
}
-- Serrated Bone Spike
LCT_SpellData[385424] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_ASSA },
	charges = 3,
	cooldown = 30,
}
-- Exsanguinate
LCT_SpellData[200806] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_ASSA },
	offensive = true,
	cooldown = 180,
}
-- Kingsbane
LCT_SpellData[385627] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_ASSA },
	offensive = true,
	cooldown = 60,
}
-- Indiscriminate Carnage
LCT_SpellData[381802] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_ASSA },
	offensive = true,
	cooldown = 45,
}
-- Rogue/Outlaw - most CDs are rough estimates with cd reduction
-- Between the Eyes
LCT_SpellData[315341] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_OUTLAW },
	cc = true,
	cooldown = 30, -- 45s
}
-- Rogue/Outlaw/talents
-- Blade Flurry
LCT_SpellData[13877] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_OUTLAW },
	cooldown = 20, -- 30s
	duration = 10,
}
-- Blade Rush
LCT_SpellData[271877] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_OUTLAW },
	talent = true,
	cooldown = 30, -- 45s
}
-- Adrenaline Rush
LCT_SpellData[13750] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_OUTLAW },
	offensive = true,
	duration = 20,
	cooldown = 180
}
-- Grappling Hook
LCT_SpellData[195457] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_OUTLAW },
	cooldown = 30, -- 45s
	opt_lower_cooldown = 15, -- talent 'Retractable Hook'
}
-- Killing Spree
LCT_SpellData[51690] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_OUTLAW },
	talent = true,
	offensive = true,
	cooldown = 80, -- 120s
}
-- Roll the bones
LCT_SpellData[315508] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_OUTLAW },
	cooldown = 30, -- 45s

}
-- Ghostly Strike
LCT_SpellData[196937] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_OUTLAW },
	talent = true,
	cooldown = 25, -- 35s
}
-- Dreadblades
LCT_SpellData[343142] = {
	class = "ROGUE",
	talent = true,
	offensive = true,
	specID = { SPEC_ROGUE_OUTLAW },
	cooldown = 90, -- 120s
}
-- Keep it rolling
LCT_SpellData[381989] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_OUTLAW },
	cooldown = 300, -- 420s
}
-- Rogue/Subtlety
-- Symbols of Death
LCT_SpellData[212283] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_SUB },
	offensive = true,
	duration = 10,
	cooldown = 30,
}
-- Rogue/Subtlety/talents
-- Shadow Blades
LCT_SpellData[121471] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_SUB },
	offensive = true,
	duration = 20,
	cooldown = 120, --  will be less in practice, reduced by "Stiletto Staccato" talent
	opt_lower_cooldown = 80, -- Thief's Bargain
}
-- Secret Technique
LCT_SpellData[280719] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_SUB },
	offensive = true,
	talent = true,
	cooldown = 45, -- 60s, minus 1s by combo points spent, should never be used without echoing reprimand therefore setting cd at 45
}
-- Shuriken Tornado
LCT_SpellData[277925] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_SUB },
	talent = true,
	cooldown = 60,
	offensive = true,
}
-- Flagellation
LCT_SpellData[384631] = {
	class = "ROGUE",
	talent = true,
	specID = { SPEC_ROGUE_SUB },
	offensive = true,
	duration = 12,
	cooldown = 90,
}
-- Shadowy Duel
LCT_SpellData[207736] = {
	class = "ROGUE",
	specID = { SPEC_ROGUE_SUB },
	talent = true,
	duration = 5,
	cooldown = 120
}
-- Rogue/Multispec/talents
-- Sepsis
LCT_SpellData[385408] = {
	class = "ROGUE",
	talent = true,
	offensive = true,
	cooldown = 90
}

