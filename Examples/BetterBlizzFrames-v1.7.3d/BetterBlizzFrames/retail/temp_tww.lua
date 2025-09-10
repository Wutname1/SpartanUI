function BBF.TWWUnitAura(unitToken, index, filter)
    local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
    if not auraData then
        return nil
    end

    return AuraUtil.UnpackAuraData(auraData)
end

function BBF.TWWUnitBuff(unitToken, index, filter)
    local auraData = C_UnitAuras.GetBuffDataByIndex(unitToken, index, filter)
    if not auraData then
        return nil
    end

    return AuraUtil.UnpackAuraData(auraData)
end

function BBF.TWWUnitDebuff(unitToken, index, filter)
    local auraData = C_UnitAuras.GetDebuffDataByIndex(unitToken, index, filter)
    if not auraData then
        return nil
    end

    return AuraUtil.UnpackAuraData(auraData)
end

function BBF.TWWGetSpellInfo(spellID)
    if not spellID then
        return nil
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
    end
end

function BBF.TWWGetSpellCooldown(spellID)
    local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
    if spellCooldownInfo then
        return spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled, spellCooldownInfo.modRate
    end
end