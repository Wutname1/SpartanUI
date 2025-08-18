-- ================ SHAMAN ================

-- TODO how to model bloodlust

local SPEC_SHAMAN_ELEMENTAL   = 262
local SPEC_SHAMAN_ENHANCEMENT = 263
local SPEC_SHAMAN_RESTORATION = 264

-- Shaman/baseline
-- Cleanse Spirit
LCT_SpellData[51886] = {
	class = "SHAMAN",
	dispel = true,
	cooldown_starts_on_dispel = true,
	cooldown = 8
}
-- Tremor Totem
LCT_SpellData[8143] = {
	class = "SHAMAN",
	talent = true,
	cooldown = 60,
}
-- Earthbind Totem
LCT_SpellData[2484] = {
	class = "SHAMAN",
	cc = true,
	duration = 20,
	cooldown = 30
}
-- Hex
LCT_SpellData[51514] = {
	class = "SHAMAN",
	cc = true,
	cooldown = 30,
	opt_lower_cooldown = 15,
}
-- Wind Shear
LCT_SpellData[57994] = {
	class = "SHAMAN",
	interrupt = true,
	cooldown = 12,
}
-- Capacitator Totem
LCT_SpellData[192058] = {
	class = "SHAMAN",
	cc = true,
	cooldown = 60,
}
-- Earth Elemental
LCT_SpellData[198103] = {
	class = "SHAMAN",
	defensive = true,
	cooldown = 300
}
-- Shaman/talents
-- Grounding Totem
LCT_SpellData[204336] = {
	class = "SHAMAN",
	_talent = true,
	duration = 3,
	cooldown = 30,
}
-- Astral Shift
LCT_SpellData[108271] = {
	class = "SHAMAN",
	defensive = true,
	duration = 8,
	cooldown = 90, -- 120s, reduced by 381647 Planes Traveler
}
-- Skyfury Totem
LCT_SpellData[204330] = {
	class = "SHAMAN",
	talent = true,
	cooldown = 40,
	duration = 15,
}
-- Counterstrike Totem
LCT_SpellData[204331] = {
	class = "SHAMAN",
	talent = true,
	cooldown = 45,
	duration = 15
}
-- Wind Rush Totem
LCT_SpellData[192077] = {
	class = "SHAMAN",
	talent = true,
	cooldown = 120
}

-- Shaman/Elemental
-- Fire Elemental
LCT_SpellData[198067] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	cooldown = 150,
}
-- Lava Burst
LCT_SpellData[51505] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	offensive = true,
	cooldown = 8,
	opt_charges = 2,
}
-- Thunderstorm
LCT_SpellData[51490] = {
	class = "SHAMAN",
	knockback = true,
	cc = true,
	cooldown = 45
}
-- Earth Elemental
LCT_SpellData[198103] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	defensive = true,
	cooldown = 300
}
-- Shaman/Elemental/talents
-- Echoing Shock
LCT_SpellData[320125] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	talent = true,
	duration = 3, -- Most likely used right before a damage spell, put 3s duration for highlight
	cooldown = 30,
}
-- Stormkeeper
LCT_SpellData[191634] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	talent = true,
	cooldown = 60,
	duration = 15
}
-- Ancestral Guidance
LCT_SpellData[108281] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	talent = true,
	heal = true,
	duration = 10,
	cooldown = 120
}
-- Elemental Blast
LCT_SpellData[117014] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	talent = true,
	offensive = true,
	cooldown = 12,
	opt_charges = 2,
}
-- Ascendance (elemental)
LCT_SpellData[114050] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	talent = true,
	duration = 18,
	cooldown = 180,
}
-- Liquid magma totem
LCT_SpellData[192222] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	talent = true,
	duration = 15,
	cooldown = 60,
}
-- Storm Elemental
LCT_SpellData[192249] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	talent = true,
	duration = 30,
	cooldown = 150,
}
-- Icefury
LCT_SpellData[210714] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ELEMENTAL },
	talent = true,
	cooldown = 30,
}
-- Lightining Lasso
LCT_SpellData[305483] = {
	class = "SHAMAN",
	talent = true,
	duration = 6,
	cooldown = 45,
}
-- Shaman/Enhancement
-- Feral Spirit
LCT_SpellData[51533] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ENHANCEMENT },
	offensive = true,
	duration = 15,
	cooldown = 90
}
-- Spirit Walk
LCT_SpellData[58875] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ENHANCEMENT },
	defensive = true,
	duration = 8,
	cooldown = 60
}
-- Stormstrike
LCT_SpellData[17364] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ENHANCEMENT },
	offensive = true,
	cooldown = 7.5
}
-- Shaman/Enhancement/talents
-- Ascendance (enhancement)
LCT_SpellData[114051] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ENHANCEMENT },
	talent = true,
	offensive = true,
	duration = 15,
	cooldown = 180
}
-- Feral Lunge
LCT_SpellData[196884] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ENHANCEMENT },
	talent = true,
	cooldown = 30,
}
-- Sundering
LCT_SpellData[197214] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_ENHANCEMENT },
	talent = true,
	cooldown = 40,
}
-- Burrow
LCT_SpellData[409293] = {
	class = "SHAMAN",
	talent = true,
	cooldown = 120,
	duration = 5,
}

-- Shaman/Restoration
-- Healing Stream Totem
LCT_SpellData[392916] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	heal = true,
	duration = 15,
	cooldown = 30
}
LCT_SpellData[392915] = 392916
-- Healing Rain
LCT_SpellData[73920] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	heal = true,
	cooldown = 10
}
-- Purify Spirit
LCT_SpellData[77130] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	dispel = true,
	replaces = 51886,
	cooldown_starts_on_dispel = true,
	cooldown = 8
}
-- Riptide
LCT_SpellData[61295] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	heal = true,
	cooldown = 6,
	opt_charges = 2,
}
-- Spirit Link Totem
LCT_SpellData[98008] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	defensive = true,
	cooldown = 180,
	opt_charges = 2,
}
-- Earthen Wall Totem
LCT_SpellData[198838] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	talent = true,
	defensive = true,
	cooldown = 60
}
-- Spiritwalker's Grace
LCT_SpellData[79206] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	duration = 15,
	cooldown = 120,
	opt_lower_cooldown = 60
}
-- Healing Tide Totem
LCT_SpellData[108280] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	heal = true,
	cooldown = 180
}
-- Downpour
LCT_SpellData[207778] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	heal = true,
	talent = true,
	cooldown = 5 -- this is impossible to calculate
}
-- Shaman/Restoration/talents
-- Unleash Life
LCT_SpellData[73685] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	talent = true,
	heal = true,
	cooldown = 15,
	opt_charges = 2,
}
-- Earthgrab Totem
LCT_SpellData[51485] = {
	class = "SHAMAN",
	talent = true,
	replaces = 2484,
	cooldown = 30
}
-- Ascendance (Restoration)
LCT_SpellData[114052] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	talent = true,
	heal = true,
	duration = 15,
	cooldown = 180
}
-- Ancestral Protection Totem
LCT_SpellData[207399] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	defensive = true,
	talent = true,
	duration = 30,
	cooldown = 300
}
-- Cloudburst Totem
LCT_SpellData[157153] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	heal = true,
	talent = true,
	cooldown = 45,
	replaces = 5394 -- Healing Stream Totem
}
-- Wellspring
LCT_SpellData[197995] = {
	class = "SHAMAN",
	specID = { SPEC_SHAMAN_RESTORATION },
	heal = true,
	talent = true,
	cooldown = 20
}
