local stealthSpellIDs = {
    [1784] = true,    -- Stealth
    [115191] = true,  -- Stealth (With Subterfuge Talent)
    [11327] = true,   -- Vanish
    [5215] = true,    -- Prowl
    [58984] = true,   -- Shadowmeld
    [110960] = true,  -- Greater Invisibility
    [32612] = true,   -- Invisibility
    [199483] = true,  -- Camouflage
    [414664] = true,  -- Mass Invisibility
    [115834] = true,  -- Shroud of Concealment
    [114018] = true,  -- Shroud of Concealment
}

local PlayerAuras = {}
local stealthIndicator
local stealthEvent

local function createOrShowStealthIndicator()
    if not stealthIndicator then
        stealthIndicator = PlayerFrame:CreateTexture(nil, "OVERLAY")
        stealthIndicator:SetTexture(137016)
        --stealthIndicator:SetSize(201, 83.5)
        stealthIndicator:SetVertexColor(0.212, 0.486, 1)
        --stealthIndicator:SetPoint("CENTER", PlayerFrame, "CENTER", -4, 0)
        stealthIndicator:SetAllPoints(PlayerFrameFlash)
        stealthIndicator:SetTexCoord(PlayerFrameFlash:GetTexCoord())
    end
    stealthIndicator:Show()
end

local function hideStealthIndicator()
    if stealthIndicator then
        stealthIndicator:Hide()
    end
end

local function isStealthAuraActive()
    for _, aura in pairs(PlayerAuras) do
        if stealthSpellIDs[aura.spellId] then
            return true
        end
    end
    return false
end

local function updateStealthIndicator()
    if isStealthAuraActive() then
        createOrShowStealthIndicator()
    else
        hideStealthIndicator()
    end
end

local function UpdatePlayerAurasFull()
    PlayerAuras = {}

    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, auraInstanceID = UnitBuff("player", i)
        if not name then break end

        if stealthSpellIDs[spellId] then
            PlayerAuras[auraInstanceID or spellId] = {
                name = name,
                icon = icon,
                count = count,
                debuffType = debuffType,
                duration = duration,
                expirationTime = expirationTime,
                source = source,
                spellId = spellId,
                auraInstanceID = auraInstanceID or spellId,
            }
        end
    end

    updateStealthIndicator()
end


local function UpdatePlayerAurasIncremental(unitAuraUpdateInfo)
    if unitAuraUpdateInfo.addedAuras then
        for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
            if stealthSpellIDs[aura.spellId] then
                PlayerAuras[aura.auraInstanceID] = aura
            end
        end
    end

    if unitAuraUpdateInfo.removedAuraInstanceIDs then
        for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
            PlayerAuras[auraInstanceID] = nil
        end
    end

    updateStealthIndicator()
end

local function OnUnitAurasUpdated(self, event, unit, unitAuraUpdateInfo)
    if not unitAuraUpdateInfo or unitAuraUpdateInfo.isFullUpdate then
        UpdatePlayerAurasFull()
    else
        UpdatePlayerAurasIncremental(unitAuraUpdateInfo)
    end
end

function BBF.StealthIndicator()
    if BetterBlizzFramesDB.stealthIndicatorPlayer and not stealthEvent then
        stealthEvent = CreateFrame("Frame")
        stealthEvent:RegisterUnitEvent("UNIT_AURA", "player")
        stealthEvent:SetScript("OnEvent", OnUnitAurasUpdated)
        UpdatePlayerAurasFull()
    elseif not BetterBlizzFramesDB.stealthIndicatorPlayer and stealthEvent then
        stealthEvent:UnregisterEvent("UNIT_AURA")
        stealthEvent:SetScript("OnEvent", nil)
        stealthEvent = nil
        hideStealthIndicator()
    end
end