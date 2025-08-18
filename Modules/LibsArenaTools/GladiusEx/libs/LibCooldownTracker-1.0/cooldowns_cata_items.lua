-- PvP Trinket
LCT_SpellData[42292] = {
    item = true,
    pvp_trinket = true,
    cooldown = 120,
    icon_alliance = [[Interface\Icons\INV_Jewelry_TrinketPVP_01]],
    icon_horde = [[Interface\Icons\INV_Jewelry_TrinketPVP_02]],
    icon_horde_wotlk = [[Interface\Icons\inv_jewelry_necklace_38]],
    icon_alliance_wotlk = [[Interface\Icons\inv_jewelry_necklace_37]],
    sets_cooldowns = {
        -- WOTF
        { spellid = 7744, cooldown = 30 },
        -- Will to Survive (EMFH)
        { spellid = 59752, cooldown = 120 },
    }
}

-- Healthstone
LCT_SpellData[5512] = {
	item = true,
	heal = true,
	cooldown = 120
}
