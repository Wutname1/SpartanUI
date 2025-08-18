local function sum(t)
    local sum = 0
    for k,v in pairs(t) do
        sum = sum + v
    end
    return sum
end

local TargetFrame = TargetFrame
local TargetFrameSpellBar = TargetFrameSpellBar
local FocusFrame = FocusFrame
local FocusFrameSpellBar = FocusFrameSpellBar

local BlizzardShouldShowDebuffs = TargetFrame.ShouldShowDebuffs

local playerBuffsHooked
local playerDebuffsHooked
local targetAurasHooked
local targetCastbarsHooked

local ipairs = ipairs
local math_ceil = math.ceil
local table_insert = table.insert
local table_sort = table.sort
local math_max = math.max
local print = print

local Masque
local MasquePlayerBuffs
local MasquePlayerDebuffs
local MasqueTargetBuffs
local MasqueTargetDebuffs
local MasqueFocusBuffs
local MasqueFocusDebuffs
local MasqueOn

-- Function to add buffs and debuffs to Masque group
local function addToMasque(frame, masqueGroup)
    if frame and not frame.bbfMsq then
        masqueGroup:AddButton(frame)
        frame.bbfMsq = true
        --print(frame:GetName())
    end
end

local function SetupAuraFilterClicks(auraFrame)
    if auraFrame.filterClick then return end
    auraFrame:HookScript("OnMouseDown", function(self, button)
        if IsShiftKeyDown() and IsAltKeyDown() then
            if button == "LeftButton" then
                BBF.auraWhitelist(auraFrame.spellId, "auraWhitelist", nil, true)
            elseif button == "RightButton" then
                BBF.auraBlacklist(auraFrame.spellId, "auraBlacklist", nil, true)
            end
        elseif IsControlKeyDown() and IsAltKeyDown() then
            if button == "RightButton" then
                BBF.auraBlacklist(auraFrame.spellId, "auraBlacklist", true, true)
            end
        end
    end)
    auraFrame.filterClick = true
end

local opBarriers = {
    [235313] = true, -- Blazing Barrier
    [11426] = true, -- Ice Barrier
    [235450] = true, -- Prismatic Barrier
}

local activeNonDurationAuras = {}
local updateInterval = 0.1
local timeSinceLastUpdate = {}
BBF.ActiveBuffCheck = CreateFrame("Frame")

local castToAuraMap = {
    [212182] = 212183, -- Smoke Bomb
    [359053] = 212183, -- Smoke Bomb
    [198838] = 201633, -- Earthen Wall Totem
    [62618]  = 81782,  -- Power Word: Barrier
    [204336] = 8178,   -- Grounding Totem
    [443028] = 456499, -- Celestial Conduit (Absolute Serenity)
    [289655] = 289655, -- Sanctified Ground
    --[34861] = 289655, -- Sanctified Ground
}

local trackedAuras = {
    [212183] = {duration = 5, helpful = false, texture = 458733},  -- Smoke Bomb
    [201633] = {duration = 18, helpful = true, texture = 136098},  -- Earthen Wall
    [81782]  = {duration = 10, helpful = true, texture = 253400},  -- Barrier
    [8178]   = {duration = 3,  helpful = true, texture = 136039},  -- Grounding
    [456499] = {duration = 4, helpful = true, texture = 988197}, -- Absolute Serenity
    [289655] = {duration = 5, helpful = true, texture = 237544}, -- Sanctified Ground
}

local function UpdateAuraDuration(self, elapsed)
    local auraID = self.trackedSpellId
    local spellData = trackedAuras[auraID]
    if not spellData then return end

    timeSinceLastUpdate[auraID] = (timeSinceLastUpdate[auraID] or 0) + elapsed
    self.Duration:Show()
    self.Duration:SetTextColor(1, 1, 1)

    if timeSinceLastUpdate[auraID] >= updateInterval then
        local remainingTime = (activeNonDurationAuras[auraID] or 0) + spellData.duration - GetTime()

        if remainingTime <= 0 then
            self.Duration:SetText("0 s")
            self:SetScript("OnUpdate", nil)
            activeNonDurationAuras[auraID] = nil
        else
            self.Duration:SetText(math.floor(remainingTime) .. " s")
        end
        timeSinceLastUpdate[auraID] = 0
    end
end

function BBF.CheckActiveAuras(auraID)
    local frameType = trackedAuras[auraID] and BuffFrame or DebuffFrame
    local activeAuras = {}

    for auraIndex, auraInfo in ipairs(frameType.auraInfo) do
        local auraFrame = frameType.auraFrames[auraIndex]
        if auraFrame and not auraFrame.isAuraAnchor and auraInfo.auraType ~= "TempEnchant" then
            local aura = C_UnitAuras.GetAuraDataByIndex("player", auraInfo.index, trackedAuras[auraID] and "HELPFUL" or "HARMFUL")
            if aura and aura.spellId == auraID then
                activeAuras[aura.spellId] = true

                if auraFrame.Cooldown then
                    local castTime = activeNonDurationAuras[auraID] or 0
                    local duration = trackedAuras[auraID].duration or 5
                    auraFrame.Cooldown:SetCooldown(castTime, duration)
                    C_Timer.After(0.1, function()
                        auraFrame.Cooldown:SetCooldown(castTime, duration)
                    end)
                end

                auraFrame.trackedSpellId = auraID
                auraFrame.ogSetScript = auraFrame:GetScript("OnUpdate")
                auraFrame:SetScript("OnUpdate", UpdateAuraDuration)
            else
                if auraFrame.ogSetScript then
                    auraFrame:SetScript("OnUpdate", auraFrame.ogSetScript)
                    auraFrame.ogSetScript = nil
                end
            end
        end
    end

    if next(activeAuras) then
        BBF.ActiveBuffCheck.isChecking = false
    else
        if not BBF.ActiveBuffCheck.isChecking then
            BBF.ActiveBuffCheck.isChecking = true
            C_Timer.After(2.5, function()
                BBF.CheckActiveAuras(auraID)
            end)
        else
            BBF.ActiveBuffCheck:UnregisterAllEvents()
            BBF.ActiveBuffCheck.isChecking = false
        end
    end
end

BBF.ActiveBuffCheck:SetScript("OnEvent", function(_, _, unit)
    if unit == "player" then
        for auraID, _ in pairs(activeNonDurationAuras) do
            BBF.CheckActiveAuras(auraID)
        end
    end
end)

local function BuffCastCheck()
    local _, subEvent, _, _, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if subEvent ~= "SPELL_CAST_SUCCESS" then return end
    if not castToAuraMap[spellID] then return end

    local auraID = castToAuraMap[spellID]

    local data = trackedAuras[auraID]
    local duration = data.duration

    activeNonDurationAuras[auraID] = GetTime()

    -- Register UNIT_AURA if not already done
    if not BBF.ActiveBuffCheck.isRegistered then
        BBF.ActiveBuffCheck:RegisterUnitEvent("UNIT_AURA", "player")
        BBF.ActiveBuffCheck.isRegistered = true
    end

    C_Timer.After(0.1, function()
        BBF.CheckActiveAuras(auraID)
    end)

    C_Timer.NewTimer(duration, function()
        activeNonDurationAuras[auraID] = nil
        timeSinceLastUpdate[auraID] = 0

        -- Check if all tracked buffs are gone
        local anyActive = false
        for _, activeTime in pairs(activeNonDurationAuras) do
            if activeTime then
                anyActive = true
                break
            end
        end

        if not anyActive and BBF.ActiveBuffCheck.isRegistered then
            BBF.ActiveBuffCheck:UnregisterAllEvents()
            BBF.ActiveBuffCheck.isRegistered = false
        end
    end)
end





local MountAuraTooltip = CreateFrame("GameTooltip", "MountAuraTooltip", nil, "GameTooltipTemplate")
MountAuraTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
local function isMountAura(spellId)
    MountAuraTooltip:ClearLines()
    MountAuraTooltip:SetHyperlink("spell:" .. spellId)
    local secondLineText = _G["MountAuraTooltipTextLeft2"]:GetText()
    if secondLineText and secondLineText:find("Warband Mount") then
        return true
    end
    return false
end

-- How did this spaghetti start?
-- For some reason accessing the global BetterBlizzFramesDB.variable inside of the target/focus aura function caused taint error.
-- and making it local like this fixed it. Idk why idk how and idk why im still doing it like this.

local printSpellId
local betterTargetPurgeGlow
local betterFocusPurgeGlow
local userEnlargedAuraSize = 1
local userCompactedAuraSize = 1
local auraSpacingX = 4
local auraSpacingY = 4
local aurasPerRow = 5
local targetAndFocusAuraOffsetY = 0
local baseOffsetX = 25
local baseOffsetY = 12.5
local auraScale = 1
local targetImportantAuraGlow
local targetdeBuffPandemicGlow
local targetEnlargeAura
local targetCompactAura
local focusImportantAuraGlow
local focusdeBuffPandemicGlow
local focusEnlargeAura
local focusCompactAura
local auraTypeGap = 1
local targetAndFocusSmallAuraScale = 1.4
local auraFilteringOn
local enlargedTextureAdjustment = 10
local compactedTextureAdjustment = 10
local displayDispelGlowAlways
local customLargeSmallAuraSorting
local shouldAdjustCastbar
local shouldAdjustCastbarFocus
local targetCastBarXPos = 0
local targetCastBarYPos = 0
local focusCastBarXPos = 0
local focusCastBarYPos = 0
local targetToTCastbarAdjustment
local targetAndFocusAuraScale = 1
local targetAndFocusVerticalGap = 4
local targetDetachCastbar
local focusToTCastbarAdjustment
local targetStaticCastbar
local showHiddenAurasIcon
local playerAuraSpacingX = 0
local playerAuraSpacingY = 0
local playerBuffFilterOn
local playerDebuffFilterOn
local printAuraSpellIds
local playerAuraImportantGlow
local focusStaticCastbar
local focusDetachCastbar
local purgeTextureColorRGB = {1, 1, 1, 1}
local changePurgeTextureColor
local targetToTAdjustmentOffsetY
local focusToTAdjustmentOffsetY
local buffsOnTopReverseCastbarMovement
local customImportantAuraSorting
local allowLargeAuraFirst
local onlyPandemicMine
local targetCastBarScale
local focusCastBarScale
local purgeableBuffSorting
local purgeableBuffSortingFirst
local targetEnlargeAuraEnemy
local targetEnlargeAuraFriendly
local focusEnlargeAuraEnemy
local focusEnlargeAuraFriendly
local increaseAuraStrata
local sameSizeAuras
local auraStackSize
local addCooldownFramePlayerDebuffs
local addCooldownFramePlayerBuffs
local hideDefaultPlayerAuraDuration
local hideDefaultPlayerAuraCdText
local clickthroughAuras
local importantDispel
local targetAuraGlows
local focusAuraGlows
local opBarriersOn
local db2

local function UpdateMore()
    onlyPandemicMine = BetterBlizzFramesDB.onlyPandemicAuraMine
    purgeableBuffSorting = BetterBlizzFramesDB.purgeableBuffSorting
    purgeableBuffSortingFirst = BetterBlizzFramesDB.purgeableBuffSortingFirst
    increaseAuraStrata = BetterBlizzFramesDB.increaseAuraStrata
    targetEnlargeAuraEnemy = BetterBlizzFramesDB.targetEnlargeAuraEnemy
    targetEnlargeAuraFriendly = BetterBlizzFramesDB.targetEnlargeAuraFriendly
    focusEnlargeAuraEnemy = BetterBlizzFramesDB.focusEnlargeAuraEnemy
    focusEnlargeAuraFriendly = BetterBlizzFramesDB.focusEnlargeAuraFriendly
    sameSizeAuras = BetterBlizzFramesDB.sameSizeAuras
    auraStackSize = BetterBlizzFramesDB.auraStackSize
    addCooldownFramePlayerBuffs = BetterBlizzFramesDB.addCooldownFramePlayerBuffs
    addCooldownFramePlayerDebuffs = BetterBlizzFramesDB.addCooldownFramePlayerDebuffs
    hideDefaultPlayerAuraDuration = BetterBlizzFramesDB.hideDefaultPlayerAuraDuration
    hideDefaultPlayerAuraCdText = BetterBlizzFramesDB.hideDefaultPlayerAuraCdText
    clickthroughAuras = BetterBlizzFramesDB.clickthroughAuras
    TargetFrame.staticCastbar = (BetterBlizzFramesDB.targetStaticCastbar or BetterBlizzFramesDB.targetDetachCastbar) and true or false
    FocusFrame.staticCastbar = (BetterBlizzFramesDB.focusStaticCastbar or BetterBlizzFramesDB.focusDetachCastbar) and true or false
    importantDispel = BetterBlizzFramesDB.auraImportantDispelIcon
    targetAuraGlows = BetterBlizzFramesDB.targetAuraGlows
    focusAuraGlows = BetterBlizzFramesDB.focusAuraGlows
    opBarriersOn = BetterBlizzFramesDB.opBarriersOn
    db2 = BetterBlizzFramesDB
end

function BBF.UpdateUserAuraSettings()
    printSpellId = BetterBlizzFramesDB.printAuraSpellIds
    betterTargetPurgeGlow = BetterBlizzFramesDB.targetBuffPurgeGlow
    betterFocusPurgeGlow = BetterBlizzFramesDB.focusBuffPurgeGlow
    userEnlargedAuraSize = BetterBlizzFramesDB.enlargedAuraSize
    userCompactedAuraSize = BetterBlizzFramesDB.compactedAuraSize
    auraSpacingX = BetterBlizzFramesDB.targetAndFocusHorizontalGap
    auraSpacingY = BetterBlizzFramesDB.targetAndFocusVerticalGap
    aurasPerRow = BetterBlizzFramesDB.targetAndFocusAurasPerRow
    targetAndFocusAuraOffsetY = BetterBlizzFramesDB.targetAndFocusAuraOffsetY
    baseOffsetX = 25 + BetterBlizzFramesDB.targetAndFocusAuraOffsetX + (BetterBlizzFramesDB.classicFrames and 1.5 or 0)
    baseOffsetY = 12.5 + BetterBlizzFramesDB.targetAndFocusAuraOffsetY + (BetterBlizzFramesDB.classicFrames and -0.5 or 0)
    auraScale = BetterBlizzFramesDB.targetAndFocusAuraScale
    targetImportantAuraGlow = BetterBlizzFramesDB.targetImportantAuraGlow
    targetdeBuffPandemicGlow = BetterBlizzFramesDB.targetdeBuffPandemicGlow
    targetEnlargeAura = BetterBlizzFramesDB.targetEnlargeAura
    targetCompactAura = BetterBlizzFramesDB.targetCompactAura
    focusImportantAuraGlow = BetterBlizzFramesDB.focusImportantAuraGlow
    focusdeBuffPandemicGlow = BetterBlizzFramesDB.focusdeBuffPandemicGlow
    focusEnlargeAura = BetterBlizzFramesDB.focusEnlargeAura
    focusCompactAura = BetterBlizzFramesDB.focusCompactAura
    auraTypeGap = BetterBlizzFramesDB.auraTypeGap
    targetAndFocusSmallAuraScale = BetterBlizzFramesDB.targetAndFocusSmallAuraScale
    auraFilteringOn = BetterBlizzFramesDB.playerAuraFiltering
    enlargedTextureAdjustment = 10 * userEnlargedAuraSize
    compactedTextureAdjustment = 10 * userCompactedAuraSize
    displayDispelGlowAlways = BetterBlizzFramesDB.displayDispelGlowAlways
    customLargeSmallAuraSorting = BetterBlizzFramesDB.customLargeSmallAuraSorting
    focusStaticCastbar = BetterBlizzFramesDB.focusStaticCastbar
    focusDetachCastbar = BetterBlizzFramesDB.focusDetachCastbar
    targetStaticCastbar = BetterBlizzFramesDB.targetStaticCastbar
    targetDetachCastbar = BetterBlizzFramesDB.targetDetachCastbar
    shouldAdjustCastbar = targetStaticCastbar or targetDetachCastbar or BetterBlizzFramesDB.playerAuraFiltering
    shouldAdjustCastbarFocus = focusStaticCastbar or focusDetachCastbar or BetterBlizzFramesDB.playerAuraFiltering
    targetCastBarXPos = BetterBlizzFramesDB.targetCastBarXPos
    targetCastBarYPos = BetterBlizzFramesDB.targetCastBarYPos
    focusCastBarXPos = BetterBlizzFramesDB.focusCastBarXPos
    focusCastBarYPos = BetterBlizzFramesDB.focusCastBarYPos
    targetToTAdjustmentOffsetY = BetterBlizzFramesDB.targetToTAdjustmentOffsetY
    focusToTAdjustmentOffsetY = BetterBlizzFramesDB.focusToTAdjustmentOffsetY
    targetToTCastbarAdjustment = BetterBlizzFramesDB.targetToTCastbarAdjustment
    targetAndFocusAuraScale = BetterBlizzFramesDB.targetAndFocusAuraScale
    targetAndFocusVerticalGap = BetterBlizzFramesDB.targetAndFocusVerticalGap
    focusToTCastbarAdjustment = BetterBlizzFramesDB.focusToTCastbarAdjustment
    showHiddenAurasIcon = BetterBlizzFramesDB.showHiddenAurasIcon
    playerAuraSpacingX = BetterBlizzFramesDB.playerAuraSpacingX
    playerAuraSpacingY = BetterBlizzFramesDB.playerAuraSpacingY
    playerBuffFilterOn = BetterBlizzFramesDB.playerAuraFiltering and BetterBlizzFramesDB.enablePlayerBuffFiltering
    playerDebuffFilterOn = BetterBlizzFramesDB.playerAuraFiltering and BetterBlizzFramesDB.enablePlayerDebuffFiltering
    printAuraSpellIds = BetterBlizzFramesDB.printAuraSpellIds
    playerAuraImportantGlow = BetterBlizzFramesDB.playerAuraImportantGlow
    targetCastBarScale = BetterBlizzFramesDB.targetCastBarScale
    focusCastBarScale = BetterBlizzFramesDB.focusCastBarScale
    allowLargeAuraFirst = BetterBlizzFramesDB.allowLargeAuraFirst
    customImportantAuraSorting = BetterBlizzFramesDB.customImportantAuraSorting
    purgeTextureColorRGB = BetterBlizzFramesDB.purgeTextureColorRGB
    changePurgeTextureColor = BetterBlizzFramesDB.changePurgeTextureColor
    buffsOnTopReverseCastbarMovement = BetterBlizzFramesDB.buffsOnTopReverseCastbarMovement
    UpdateMore()
end

local function isInBlacklist(spellName, spellId)
    local db = BetterBlizzFramesDB
    local entry = db["auraBlacklist"][spellId] or (spellName and db["auraBlacklist"][string.lower(spellName)])
    if entry then
        local showMine = entry.showMine
        return true, showMine
    end
end

local function GetAuraDetails(spellName, spellId)
    local db = BetterBlizzFramesDB
    local entry = db["auraWhitelist"][spellId] or (spellName and db["auraWhitelist"][string.lower(spellName)])

    if entry then
        local isImportant = entry.important
        local isPandemic = entry.pandemic
        local isEnlarged = entry.enlarged
        local isCompacted = entry.compacted
        local auraColor = entry.color
        local onlyMine = entry.onlyMine
        return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor, onlyMine
    end
end

local function ShouldShowBuff(unit, auraData, frameType)
    local spellName = auraData.name
    local spellId = auraData.spellId
    local duration = auraData.duration
    local expirationTime = auraData.expirationTime
    local caster = auraData.sourceUnit
    local isPurgeable = auraData.isStealable or auraData.dispelName == "Magic"
    local castByPlayer = (caster == "player" or caster == "pet")
    local db = BetterBlizzFramesDB
    local filterOverride = BBF.filterOverride

    -- TargetFrame
    if frameType == "target" then
        -- Buffs
        if db["targetBuffEnable"] and auraData.isHelpful then
            local isTargetFriendly = UnitIsFriend("target", "player")
            local isInWhitelist, isImportant, isPandemic, isEnlarged, isCompacted, auraColor, onlyMine = GetAuraDetails(spellName, spellId)
            local shouldBlacklist = db["targetBuffFilterBlacklist"]
            local filterMount = db["targetBuffFilterMount"]
            local filterWatchlist = db["targetBuffFilterWatchList"] and isInWhitelist
            local filterLessMinite = db["targetBuffFilterLessMinite"] and (duration < 61 and duration ~= 0 and expirationTime ~= 0)
            local filterPurgeable = db["targetBuffFilterPurgeable"] and isPurgeable
            local filterOnlyMe = db["targetBuffFilterOnlyMe"] and isTargetFriendly and castByPlayer
            if filterOverride then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if shouldBlacklist then
                local isInBlacklist, allowMine = isInBlacklist(spellName, spellId)
                -- if isInBlacklist and (auraData.isStealable or auraData.dispelName == "Magic") then
                --     -- Initialize the blacklist table if it doesn't exist
                --     if not BetterBlizzFramesDB.auraBlacklistFaulty then
                --         BetterBlizzFramesDB.auraBlacklistFaulty = {}
                --     end

                --     -- Check if the spell name already exists in the blacklist
                --     if BetterBlizzFramesDB.auraBlacklistFaulty[spellName] then
                --         -- If the spell ID is not already in the list, add it
                --         local alreadyExists = false
                --         for _, id in ipairs(BetterBlizzFramesDB.auraBlacklistFaulty[spellName]) do
                --             if id == spellId then
                --                 alreadyExists = true
                --                 break
                --             end
                --         end
                --         if not alreadyExists then
                --             table.insert(BetterBlizzFramesDB.auraBlacklistFaulty[spellName], spellId)
                --             print("Oopsie in BL: ", spellName, spellId)
                --         end
                --     else
                --         -- If the spell name is not in the blacklist, add it with the spell ID
                --         BetterBlizzFramesDB.auraBlacklistFaulty[spellName] = { spellId }
                --         print("Oopsie in BL: ", spellName, spellId)
                --     end

                --     if db["auraBlacklist"][spellId] then
                --         db["auraBlacklist"][spellId] = nil
                --     end
                --     if db["auraBlacklist"][string.lower(spellName)] then
                --         db["auraBlacklist"][string.lower(spellName)] = nil
                --     end
                -- end
                if isInBlacklist and not (allowMine and castByPlayer) then return end
            end
            if filterMount then
                if isMountAura(spellId) then return true end
            end
            if not castByPlayer and onlyMine then return end
            if filterWatchlist or filterLessMinite or filterPurgeable or ((filterOnlyMe and filterLessMinite) or (filterOnlyMe and not db["targetBuffFilterLessMinite"])) or isImportant or isPandemic or isEnlarged or isCompacted then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if not db["targetBuffFilterLessMinite"] and not db["targetBuffFilterWatchList"] and not db["targetBuffFilterPurgeable"] and not (db["targetBuffFilterOnlyMe"] and isTargetFriendly) then
                return true
            end
        end
        -- Debuffs
        if db["targetdeBuffEnable"] and auraData.isHarmful then
            local isInWhitelist, isImportant, isPandemic, isEnlarged, isCompacted, auraColor, onlyMine = GetAuraDetails(spellName, spellId)
            local shouldBlacklist = db["targetdeBuffFilterBlacklist"]
            local filterWatchlist = db["targetdeBuffFilterWatchList"] and isInWhitelist
            local filterLessMinite = db["targetdeBuffFilterLessMinite"] and (duration < 61 and duration ~= 0 and expirationTime ~= 0)
            local filterBlizzard = db["targetdeBuffFilterBlizzard"] and BlizzardShouldShowDebuffs
            local filterOnlyMe = db["targetdeBuffFilterOnlyMe"] and castByPlayer
            if filterOverride then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if shouldBlacklist then
                local isInBlacklist, allowMine = isInBlacklist(spellName, spellId)
                if isInBlacklist and not (allowMine and castByPlayer) then return end
            end
            if not castByPlayer and onlyMine then return end
            if filterWatchlist or filterLessMinite or filterBlizzard or filterOnlyMe or isImportant or isPandemic or isEnlarged or isCompacted then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if not db["targetdeBuffFilterLessMinite"] and not db["targetdeBuffFilterWatchList"] and not db["targetdeBuffFilterBlizzard"] and not db["targetdeBuffFilterOnlyMe"] then
                return true
            end
        end
    -- FocusFrame
    elseif frameType == "focus" then
        -- Buffs
        if db["focusBuffEnable"] and auraData.isHelpful then
            local isInWhitelist, isImportant, isPandemic, isEnlarged, isCompacted, auraColor, onlyMine = GetAuraDetails(spellName, spellId)
            local shouldBlacklist = db["focusBuffFilterBlacklist"]
            local isTargetFriendly = UnitIsFriend("focus", "player")
            local filterMount = db["focusBuffFilterMount"]
            local filterWatchlist = db["focusBuffFilterWatchList"] and isInWhitelist
            local filterLessMinite = db["focusBuffFilterLessMinite"] and (duration < 61 and duration ~= 0 and expirationTime ~= 0)
            local filterPurgeable = db["focusBuffFilterPurgeable"] and isPurgeable
            local filterOnlyMe = db["focusBuffFilterOnlyMe"] and isTargetFriendly and castByPlayer
            if filterOverride then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if shouldBlacklist then
                local isInBlacklist, allowMine = isInBlacklist(spellName, spellId)
                -- if isInBlacklist and (auraData.isStealable or auraData.dispelName == "Magic") then
                --     -- Initialize the blacklist table if it doesn't exist
                --     if not BetterBlizzFramesDB.auraBlacklistFaulty then
                --         BetterBlizzFramesDB.auraBlacklistFaulty = {}
                --     end

                --     -- Check if the spell name already exists in the blacklist
                --     if BetterBlizzFramesDB.auraBlacklistFaulty[spellName] then
                --         -- If the spell ID is not already in the list, add it
                --         local alreadyExists = false
                --         for _, id in ipairs(BetterBlizzFramesDB.auraBlacklistFaulty[spellName]) do
                --             if id == spellId then
                --                 alreadyExists = true
                --                 break
                --             end
                --         end
                --         if not alreadyExists then
                --             table.insert(BetterBlizzFramesDB.auraBlacklistFaulty[spellName], spellId)
                --             print("Oopsie in BL: ", spellName, spellId)
                --         end
                --     else
                --         -- If the spell name is not in the blacklist, add it with the spell ID
                --         BetterBlizzFramesDB.auraBlacklistFaulty[spellName] = { spellId }
                --         print("Oopsie in BL: ", spellName, spellId)
                --     end

                --     if db["auraBlacklist"][spellId] then
                --         db["auraBlacklist"][spellId] = nil
                --     end
                --     if db["auraBlacklist"][string.lower(spellName)] then
                --         db["auraBlacklist"][string.lower(spellName)] = nil
                --     end
                -- end
                if isInBlacklist and not (allowMine and castByPlayer) then return end
            end
            if filterMount then
                if isMountAura(spellId) then return true end
            end
            if not castByPlayer and onlyMine then return end
            if filterWatchlist or filterLessMinite or filterPurgeable or ((filterOnlyMe and filterLessMinite) or (filterOnlyMe and not db["focusBuffFilterLessMinite"])) or isImportant or isPandemic or isEnlarged or isCompacted then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if not db["focusBuffFilterLessMinite"] and not db["focusBuffFilterWatchList"] and not db["focusBuffFilterPurgeable"] and not db["focusBuffFilterOnlyMe"] then
                return true
            end
        end
        -- Debuffs
        if db["focusdeBuffEnable"] and auraData.isHarmful then
            local isInWhitelist, isImportant, isPandemic, isEnlarged, isCompacted, auraColor, onlyMine = GetAuraDetails(spellName, spellId)
            local filterWatchlist = db["focusdeBuffFilterWatchList"] and isInWhitelist
            local shouldBlacklist = db["focusdeBuffFilterBlacklist"]
            local filterLessMinite = db["focusdeBuffFilterLessMinite"] and (duration < 61 and duration ~= 0 and expirationTime ~= 0)
            local filterBlizzard = db["focusdeBuffFilterBlizzard"] and BlizzardShouldShowDebuffs
            local filterOnlyMe = db["focusdeBuffFilterOnlyMe"] and castByPlayer
            if filterOverride then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if shouldBlacklist then
                local isInBlacklist, allowMine = isInBlacklist(spellName, spellId)
                if isInBlacklist and not (allowMine and castByPlayer) then return end
            end
            if not castByPlayer and onlyMine then return end
            if filterWatchlist or filterLessMinite or filterBlizzard or filterOnlyMe or isImportant or isPandemic or isEnlarged or isCompacted then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if not db["focusdeBuffFilterLessMinite"] and not db["focusdeBuffFilterWatchList"] and not db["focusdeBuffFilterBlizzard"] and not db["focusdeBuffFilterOnlyMe"] then
                return true
            end
        end
    -- Player Buffs and Debuffs
    else
        if frameType == "playerBuffFrame" then
            -- Buffs
            if db["PlayerAuraFrameBuffEnable"] and (auraData.auraType == "Buff" or auraData.auraType == "TempEnchant") then
                local isInWhitelist, isImportant, isPandemic, isEnlarged, isCompacted, auraColor, onlyMine = GetAuraDetails(spellName, spellId)
                local shouldBlacklist = db["playerBuffFilterBlacklist"]
                local filterMount = db["playerBuffFilterMount"]
                local filterWatchlist = db["PlayerAuraFrameBuffFilterWatchList"] and isInWhitelist
                local filterLessMinite = db["PlayerAuraFrameBuffFilterLessMinite"] and (duration < 61 and duration ~= 0 and expirationTime ~= 0)
                if filterOverride then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
                if shouldBlacklist then
                    local isInBlacklist, allowMine = isInBlacklist(spellName, spellId)
                    -- if isInBlacklist and (auraData.isStealable or auraData.dispelName == "Magic") then
                    --     -- Initialize the blacklist table if it doesn't exist
                    --     if not BetterBlizzFramesDB.auraBlacklistFaulty then
                    --         BetterBlizzFramesDB.auraBlacklistFaulty = {}
                    --     end

                    --     -- Check if the spell name already exists in the blacklist
                    --     if BetterBlizzFramesDB.auraBlacklistFaulty[spellName] then
                    --         -- If the spell ID is not already in the list, add it
                    --         local alreadyExists = false
                    --         for _, id in ipairs(BetterBlizzFramesDB.auraBlacklistFaulty[spellName]) do
                    --             if id == spellId then
                    --                 alreadyExists = true
                    --                 break
                    --             end
                    --         end
                    --         if not alreadyExists then
                    --             table.insert(BetterBlizzFramesDB.auraBlacklistFaulty[spellName], spellId)
                    --             print("Oopsie in BL: ", spellName, spellId)
                    --         end
                    --     else
                    --         -- If the spell name is not in the blacklist, add it with the spell ID
                    --         BetterBlizzFramesDB.auraBlacklistFaulty[spellName] = { spellId }
                    --         print("Oopsie in BL: ", spellName, spellId)
                    --     end

                    --     if db["auraBlacklist"][spellId] then
                    --         db["auraBlacklist"][spellId] = nil
                    --     end
                    --     if db["auraBlacklist"][string.lower(spellName)] then
                    --         db["auraBlacklist"][string.lower(spellName)] = nil
                    --     end
                    -- end
                    if isInBlacklist and not (allowMine and castByPlayer) then return end
                end
                if filterMount then
                    if isMountAura(spellId) then return true end
                end
                if filterWatchlist or filterLessMinite or isImportant then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
                if not db["PlayerAuraFrameBuffFilterLessMinite"] and not db["PlayerAuraFrameBuffFilterWatchList"] then
                    return true
                end
            end
        else
            -- Debuffs
            if db["PlayerAuraFramedeBuffEnable"] and auraData.auraType == "Debuff" then
                local isInWhitelist, isImportant, isPandemic, isEnlarged, isCompacted, auraColor, onlyMine = GetAuraDetails(spellName, spellId)
                local shouldBlacklist = db["playerdeBuffFilterBlacklist"]
                local filterWatchlist = db["PlayerAuraFramedeBuffFilterWatchList"] and isInWhitelist
                local filterLessMinite = db["PlayerAuraFramedeBuffFilterLessMinite"] and (duration < 61 and duration ~= 0 and expirationTime ~= 0)
                if filterOverride then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
                if shouldBlacklist then
                    local isInBlacklist, allowMine = isInBlacklist(spellName, spellId)
                    if isInBlacklist and not (allowMine and castByPlayer) then return end
                end
                if filterWatchlist or filterLessMinite or isImportant then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
                if not db["PlayerAuraFramedeBuffFilterLessMinite"] and not db["PlayerAuraFramedeBuffFilterWatchList"] then
                    return true
                end
            end
        end
    end
end

local function CalculateAuraRowsYOffset(frame, rowHeights, castBarScale)
    local totalHeight = 0
    for _, height in ipairs(rowHeights) do
        totalHeight = totalHeight + (height * targetAndFocusAuraScale) / castBarScale  -- Scaling each row height
    end
    return totalHeight + #rowHeights * targetAndFocusVerticalGap
end

local function adjustCastbar(self, frame)
    local meta = getmetatable(self).__index
    local parent = meta.GetParent(self)
    local rowHeights = parent.rowHeights or {}

    meta.ClearAllPoints(self)
    if frame == TargetFrameSpellBar then
        local buffsOnTop = parent.buffsOnTop
        local yOffset = 14
        if targetStaticCastbar then
            --meta.SetPoint(self, "TOPLEFT", meta.GetParent(self), "BOTTOMLEFT", 43, 110);
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", 43 + targetCastBarXPos, -14 + targetCastBarYPos);
        elseif targetDetachCastbar then
            meta.SetPoint(self, "CENTER", UIParent, "CENTER", targetCastBarXPos, targetCastBarYPos);
        elseif buffsOnTopReverseCastbarMovement and buffsOnTop then
            yOffset = yOffset + CalculateAuraRowsYOffset(parent, rowHeights, targetCastBarScale) + 100/targetCastBarScale
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", 43 + targetCastBarXPos, yOffset + targetCastBarYPos);
        else
            if not buffsOnTop then
                yOffset = yOffset - CalculateAuraRowsYOffset(parent, rowHeights, targetCastBarScale)
            end
            -- Check if totAdjustment is true and the ToT frame is shown
            if targetToTCastbarAdjustment and parent.haveToT then
                local minOffset = -40
                -- Choose the more negative value
                yOffset = min(minOffset, yOffset)
                yOffset = yOffset + targetToTAdjustmentOffsetY
            end

            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", 43 + targetCastBarXPos, yOffset + targetCastBarYPos);
        end
    elseif frame == FocusFrameSpellBar then
        local buffsOnTop = parent.buffsOnTop
        local yOffset = 14
        if focusStaticCastbar then
            --meta.SetPoint(self, "TOPLEFT", meta.GetParent(self), "BOTTOMLEFT", 43, 110);
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", 43 + focusCastBarXPos, -14 + focusCastBarYPos);
        elseif focusDetachCastbar then
            meta.SetPoint(self, "CENTER", UIParent, "CENTER", focusCastBarXPos, focusCastBarYPos);
        elseif buffsOnTopReverseCastbarMovement and buffsOnTop then
            yOffset = yOffset + CalculateAuraRowsYOffset(parent, rowHeights, focusCastBarScale) + 100/focusCastBarScale
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", 43 + focusCastBarXPos, yOffset + focusCastBarYPos);
        else
            if not buffsOnTop then
                yOffset = yOffset - CalculateAuraRowsYOffset(parent, rowHeights, focusCastBarScale)
            end
            -- Check if totAdjustment is true and the ToT frame is shown
            if focusToTCastbarAdjustment and parent.haveToT then
                local minOffset = -40
                -- Choose the more negative value
                yOffset = min(minOffset, yOffset)
                yOffset = yOffset + focusToTAdjustmentOffsetY
            end

            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", 43 + focusCastBarXPos, yOffset + focusCastBarYPos);
        end
    end
end

local function DefaultCastbarAdjustment(self, frame)
    local meta = getmetatable(self).__index
    local parentFrame = meta.GetParent(self)

    -- Determine whether to use the adjusted logic based on BetterBlizzFramesDB setting
    local useSpellbarAnchor = buffsOnTopReverseCastbarMovement and
                              ((parentFrame.haveToT and parentFrame.auraRows > 2) or (not parentFrame.haveToT and parentFrame.auraRows > 0)) or
                              (not buffsOnTopReverseCastbarMovement and not parentFrame.buffsOnTop and 
                               ((parentFrame.haveToT and parentFrame.auraRows > 2) or (not parentFrame.haveToT and parentFrame.auraRows > 0)))

    local relativeKey = useSpellbarAnchor and parentFrame.spellbarAnchor or parentFrame
    local pointX = useSpellbarAnchor and 18 or (parentFrame.smallSize and 38 or 43)
    local pointY = useSpellbarAnchor and -10 or (parentFrame.smallSize and 3 or 5)

    -- Adjustments for ToT and specific frame adjustments
    if (not useSpellbarAnchor) and parentFrame.haveToT then
        local totAdjustment = ((frame == TargetFrameSpellBar and targetToTCastbarAdjustment) or (frame == FocusFrameSpellBar and focusToTCastbarAdjustment))
        if totAdjustment then
            pointY = parentFrame.smallSize and -48 or -46
            if frame == TargetFrameSpellBar then
                pointY = pointY + targetToTAdjustmentOffsetY
            elseif frame == FocusFrameSpellBar then
                pointY = pointY + focusToTAdjustmentOffsetY
            end
        end
    end

    if frame == TargetFrameSpellBar then
        pointX = pointX + targetCastBarXPos
        pointY = pointY + targetCastBarYPos
    elseif frame == FocusFrameSpellBar then
        pointX = pointX + focusCastBarXPos
        pointY = pointY + focusCastBarYPos
    end

    -- Apply setting-specific adjustment
    if buffsOnTopReverseCastbarMovement then
        meta.SetPoint(self, "TOPLEFT", relativeKey, "BOTTOMLEFT", pointX, -pointY + 50)
    else
        meta.SetPoint(self, "TOPLEFT", relativeKey, "BOTTOMLEFT", pointX, pointY)
    end
end

function BBF.CastbarAdjustCaller()
    BBF.UpdateUserAuraSettings()
    if shouldAdjustCastbar or shouldAdjustCastbarFocus then
        if shouldAdjustCastbar then
            adjustCastbar(TargetFrame.spellbar, TargetFrameSpellBar)
        end
        if shouldAdjustCastbarFocus then
            adjustCastbar(FocusFrame.spellbar, FocusFrameSpellBar)
        end
    else
        DefaultCastbarAdjustment(TargetFrame.spellbar, TargetFrameSpellBar)
        DefaultCastbarAdjustment(FocusFrame.spellbar, FocusFrameSpellBar)
    end
end

local trackedBuffs = {};
local checkBuffsTimer = nil;

local function StopCheckBuffsTimer()
    if checkBuffsTimer then
        checkBuffsTimer:Cancel();
        checkBuffsTimer = nil;
    end
end

local pandemicSpells = {
    -- Death Knight
        -- Blood
        [55078] = 24,  -- Blood Plague
        -- Frost
        [55095] = 24,  -- Frost Fever
        -- Unholy
        [191587] = 21, -- Virulent Plague

    -- Demon Hunter
        -- Havoc
        [390181] = 6,  -- Soulscar

    -- Druid
        -- Feral
        [1079] = 8,   -- Rip
        [155722] = 15, -- Rake
        [106830] = 15, -- Thrash
        [155625] = 14, -- Moonfire
        -- Balance
        [164815] = 12, -- Sunfire
        [202347] = 24, -- Stellar Flare
        -- Resto
        [774] = 12,    -- Rejuvenation
        [33763] = 15,  -- Lifebloom
        [8936] = 6,    -- Regrowth

    -- Evoker
        -- Preservation
        [355941] = 8, -- Dream Breath
        -- Augmentation
        [395152] = 10, -- Ebon Might

    -- Hunter
        -- Survival
        [259491] = 12, -- Serpent Sting
        -- Marksman
        [271788] = 18, -- Serpent Sting (Aimed Shot)

    -- Monk
        -- Brewmaster
        [116847] = 6,  -- Rushing Jade Wind
        -- Mistweaver
        [119611] = 20, -- Renewing Mist
        [124682] = 6,  -- Enveloping Mist

    -- Priest
        [139] = 15,    -- Renew
        [589] = 16,    -- Shadow Word: Pain
        -- Discipline
        [204213] = 20, -- Purge the Wicked
        -- Shadow
        [34914] = 21,  -- Vampiric Touch
        [335467] = 6,  -- Devouring Plague

    -- Rogue
        [1943] = 8,   -- Rupture
        [315496] = 12, -- Slice and Dice
        -- Assassination
        [703] = 18,    -- Garrote
        [121411] = 6, -- Crimson Tempest

    -- Shaman
        [188389] = 18, -- Flame Shock
        -- Restoration
        [382024] = 12, -- Earthliving Weapon
        [61295] = 18,  -- Riptide

    -- Warlock
        [445474] = 16, -- Wither
        -- Destruction
        [157736] = 18, -- Immolate
        -- Demonology
        [460553] = 20, -- Doom
        -- Affliction
        [146739] = 14, -- Corruption
        [980] = 18,    -- Agony
        [316099] = 21, -- Unstable Affliction

    -- Warrior
        [388539] = 15, -- Rend
        -- Arms
        [262115] = 12, -- Deep Wounds
}


local nonPandemic = 5
local defaultPandemic = 0.3
local uaPandemic = 8
local agonyPandemic = 10

local function GetPandemicThresholds(buff)
    local minBaseDuration = pandemicSpells[buff.spellID] or buff.duration
    local baseDuration = math.max(buff.duration, minBaseDuration)  -- Ensure the duration doesn't go below the min base duration

    -- Specific pandemic logic for Agony with talent
    if buff.spellID == 980 and IsPlayerSpell(453034) then
        -- For Agony with talent, return special threshold
        return agonyPandemic, baseDuration * defaultPandemic
    elseif buff.spellID == 316099 and IsPlayerSpell(459376) then
        -- Unstable Affliction with talent
        return uaPandemic, baseDuration * defaultPandemic
    elseif pandemicSpells[buff.spellID] then
        -- Use 30% of the greater value (dynamic or minimum) for Pandemic spells
        return nil, baseDuration * defaultPandemic
    else
        -- Default non-pandemic (5 seconds)
        return nil, nonPandemic
    end
end

local function CheckBuffs()
    local currentGameTime = GetTime()

    for auraInstanceID, aura in pairs(trackedBuffs) do
        if aura.isPandemic and aura.expirationTime then
            local remainingDuration = aura.expirationTime - currentGameTime
            local specialPandemicThreshold, defaultPandemicThreshold = GetPandemicThresholds(aura)

            if remainingDuration <= 0 then
                aura.isPandemic = false
                trackedBuffs[auraInstanceID] = nil
                if aura.PandemicGlow then
                    aura.PandemicGlow:Hide()
                end
                aura.isPandemicActive = false
            else
                if not aura.PandemicGlow then
                    aura.PandemicGlow = aura:CreateTexture(nil, "OVERLAY")
                    aura.PandemicGlow:SetAtlas("newplayertutorial-drag-slotgreen")
                    aura.PandemicGlow:SetDesaturated(true)
                end

                if remainingDuration <= defaultPandemicThreshold then
                    -- Set the glow to red
                    aura.PandemicGlow:SetVertexColor(1, 0, 0) -- Red color
                    aura.PandemicGlow:Show()
                    if aura.isEnlarged then
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -enlargedTextureAdjustment, enlargedTextureAdjustment)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", enlargedTextureAdjustment, -enlargedTextureAdjustment)
                    elseif aura.isCompacted then
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -compactedTextureAdjustment, compactedTextureAdjustment)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", compactedTextureAdjustment, -compactedTextureAdjustment)
                    else
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -10, 10)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 10, -10)
                    end
                    aura.isPandemicActive = true
                elseif specialPandemicThreshold and remainingDuration <= specialPandemicThreshold and remainingDuration > defaultPandemicThreshold then
                    -- Set the glow to reddish-orange
                    aura.PandemicGlow:SetVertexColor(1, 0.25, 0) -- Reddish-orange color
                    aura.PandemicGlow:Show()
                    if aura.isEnlarged then
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -enlargedTextureAdjustment, enlargedTextureAdjustment)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", enlargedTextureAdjustment, -enlargedTextureAdjustment)
                    elseif aura.isCompacted then
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -compactedTextureAdjustment, compactedTextureAdjustment)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", compactedTextureAdjustment, -compactedTextureAdjustment)
                    else
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -10, 10)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 10, -10)
                    end
                    aura.isPandemicActive = true
                else
                    -- Outside the pandemic window, hide the glow
                    if aura.PandemicGlow then
                        aura.PandemicGlow:Hide()
                    end
                    aura.isPandemicActive = false
                end

                -- Handle borders
                if aura.isPandemicActive then
                    if aura.border then
                        aura.border:SetAlpha(0)
                    end
                    if aura.Border then
                        aura.Border:SetAlpha(0)
                    end
                else
                    if aura.Border and not aura.isImportant and not aura.isPurgeGlow then
                        aura.Border:SetAlpha(1)
                    end
                    if aura.border and not aura.isImportant and not aura.isPurgeGlow then
                        aura.border:SetAlpha(1)
                    end
                end
            end
        else
            aura.isPandemicActive = false

            if aura.Border and not aura.isImportant and not aura.isPurgeGlow then
                aura.Border:SetAlpha(1)
            end
            if aura.border then
                aura.border:SetAlpha(1)
            end

            trackedBuffs[auraInstanceID] = nil
        end
    end

    if next(trackedBuffs) == nil then
        StopCheckBuffsTimer()
    end
end


local function StartCheckBuffsTimer()
    if not checkBuffsTimer then
        CheckBuffs()
        checkBuffsTimer = C_Timer.NewTicker(0.1, CheckBuffs);
    end
end

local function addMasque(frameType)
    if MasqueOn then
        if frameType == "target" then
            MasqueTargetBuffs:ReSkin(true)
            MasqueTargetDebuffs:ReSkin(true)
        else
            MasqueFocusBuffs:ReSkin(true)
            MasqueFocusDebuffs:ReSkin(true)
        end
    end
end

local function defaultComparator(a, b)
    -- Default sorting logic
    if a.isLarge and not b.isLarge then
        return true
    elseif not a.isLarge and b.isLarge then
        return false
    elseif a.canApply ~= b.canApply then
        return a.canApply
    else
        return a.auraInstanceID < b.auraInstanceID
    end
end

local function importantAuraComparator(a, b)
    if a.isImportant ~= b.isImportant then
        return a.isImportant
    end
    return defaultComparator(a, b)
end

local function importantAllowEnlargedAuraComparator(a, b)
    if a.isEnlarged ~= b.isEnlarged then
        return a.isEnlarged
    end
    if a.isImportant ~= b.isImportant then
        return a.isImportant
    end
    return defaultComparator(a, b)
end

local function largeSmallAuraComparator(a, b)
    if a.isEnlarged or b.isEnlarged then
        if a.isEnlarged and not b.isEnlarged then
            return true
        elseif not a.isEnlarged and b.isEnlarged then
            return false
        else
            return defaultComparator(a, b)
        end
    end

    if a.isCompacted or b.isCompacted then
        if a.isCompacted and not b.isCompacted then
            return false
        elseif not a.isCompacted and b.isCompacted then
            return true
        else
            return defaultComparator(a, b)
        end
    end

    -- For auras that are neither enlarged nor compacted, use default sorting
    if not a.isEnlarged and not a.isCompacted and not b.isEnlarged and not b.isCompacted then
        if a.isLarge and not b.isLarge then
            return true
        elseif not a.isLarge and b.isLarge then
            return false
        elseif a.canApply ~= b.canApply then
            return a.canApply
        else
            return defaultComparator(a, b)
        end
    end
    return defaultComparator(a, b)
end

local function largeSmallAndImportantAuraComparator(a, b)
    if a.isImportant ~= b.isImportant then
        return a.isImportant
    end

    if a.isEnlarged or b.isEnlarged then
        if a.isEnlarged and not b.isEnlarged then
            return true
        elseif not a.isEnlarged and b.isEnlarged then
            return false
        else
            -- Both are enlarged, sort by auraInstanceID
            return defaultComparator(a, b)
        end
    end

    -- Compacted auras come last, sorted by auraInstanceID
    if a.isCompacted or b.isCompacted then
        if a.isCompacted and not b.isCompacted then
            return false
        elseif not a.isCompacted and b.isCompacted then
            return true
        else
            -- Both are compacted, sort by auraInstanceID
            return defaultComparator(a, b)
        end
    end

    -- For auras that are neither enlarged nor compacted, use default sorting
    if not a.isEnlarged and not a.isCompacted and not b.isEnlarged and not b.isCompacted then
        if a.isLarge and not b.isLarge then
            return true
        elseif not a.isLarge and b.isLarge then
            return false
        elseif a.canApply ~= b.canApply then
            return a.canApply
        else
            return defaultComparator(a, b)
        end
    end
    return defaultComparator(a, b)
end

local function largeSmallAndImportantAndEnlargedFirstAuraComparator(a, b)
    if a.isEnlarged or b.isEnlarged then
        if a.isEnlarged and not b.isEnlarged then
            return true
        elseif not a.isEnlarged and b.isEnlarged then
            return false
        else
            -- Both are enlarged, sort by auraInstanceID
            return defaultComparator(a, b)
        end
    end

    -- Compacted auras come last, sorted by auraInstanceID
    if a.isCompacted or b.isCompacted then
        if a.isCompacted and not b.isCompacted then
            return false
        elseif not a.isCompacted and b.isCompacted then
            return true
        else
            -- Both are compacted, sort by auraInstanceID
            return defaultComparator(a, b)
        end
    end

    if a.isImportant ~= b.isImportant then
        return a.isImportant
    end

    -- For auras that are neither enlarged nor compacted, use default sorting
    if not a.isEnlarged and not a.isCompacted and not b.isEnlarged and not b.isCompacted then
        if a.isLarge and not b.isLarge then
            return true
        elseif not a.isLarge and b.isLarge then
            return false
        elseif a.canApply ~= b.canApply then
            return a.canApply
        else
            return defaultComparator(a, b)
        end
    end
    return defaultComparator(a, b)
end

local function allowLargeAuraFirstComparator(a, b)
    if a.isEnlarged ~= b.isEnlarged then
        return a.isEnlarged
    end
    -- Proceed with other sorting criteria without giving special treatment to isImportant
    if a.isLarge and not b.isLarge then
        return true
    elseif not a.isLarge and b.isLarge then
        return false
    elseif a.canApply ~= b.canApply then
        return a.canApply
    else
        return defaultComparator(a, b)
    end
end

local function getCustomAuraComparatorWithoutPurgeable()
    if customImportantAuraSorting and customLargeSmallAuraSorting and allowLargeAuraFirst then
        return largeSmallAndImportantAndEnlargedFirstAuraComparator
    elseif customImportantAuraSorting and customLargeSmallAuraSorting then
        return largeSmallAndImportantAuraComparator
    elseif customImportantAuraSorting and allowLargeAuraFirst then
        return importantAllowEnlargedAuraComparator
    elseif customImportantAuraSorting then
        return importantAuraComparator
    elseif customLargeSmallAuraSorting then
        return largeSmallAuraComparator
    elseif allowLargeAuraFirst then
        return allowLargeAuraFirstComparator
    else
        return defaultComparator
    end
end

local function purgeableFirstComparator(a, b)
    if a.isPurgeable ~= b.isPurgeable then
        return a.isPurgeable
    end
    return getCustomAuraComparatorWithoutPurgeable()(a, b)
end

local function purgeableAfterImportantAndEnlargedComparator(a, b)
    if a.isImportant ~= b.isImportant then
        return a.isImportant
    end

    if a.isEnlarged ~= b.isEnlarged then
        return a.isEnlarged
    end

    if a.isPurgeable ~= b.isPurgeable then
        return a.isPurgeable
    end

    return getCustomAuraComparatorWithoutPurgeable()(a, b)
end

local function purgeableAfterEnlargedAndImportantComparator(a, b)
    if a.isEnlarged ~= b.isEnlarged then
        return a.isEnlarged
    end

    if a.isImportant ~= b.isImportant then
        return a.isImportant
    end

    if a.isPurgeable ~= b.isPurgeable then
        return a.isPurgeable
    end

    return getCustomAuraComparatorWithoutPurgeable()(a, b)
end

local function getCustomAuraComparator()
    if purgeableBuffSorting then
        if purgeableBuffSortingFirst then
            return purgeableFirstComparator
        else
            if allowLargeAuraFirst then
                return purgeableAfterEnlargedAndImportantComparator
            else
                return purgeableAfterImportantAndEnlargedComparator
            end
        end
    end
    return getCustomAuraComparatorWithoutPurgeable()
end

local function AdjustAuras(self, frameType)
    local adjustedSize = sameSizeAuras and 21 or 17 * targetAndFocusSmallAuraScale
    --local buffsOnTop = self.buffsOnTop
    self.previousAuraRows = self.previousAuraRows or 0

    local initialOffsetX = (baseOffsetX / auraScale)
    local initialOffsetY = (baseOffsetY / auraScale)

    local function adjustAuraPosition(auras, yOffset, buffsOnTop)
        local adjustmentForBuffsOnTop = -80
        local currentYOffset = yOffset + (buffsOnTop and -(initialOffsetY + adjustmentForBuffsOnTop) or initialOffsetY)
        local rowWidths, rowHeights = {}, {}
        --local previousAuraWasImportant = false

        for i, aura in ipairs(auras) do
            aura:SetScale(auraScale)
            --aura:SetMouseClickEnabled(false)
            local auraSize = aura:GetHeight()
            if not aura.isLarge then
                -- Apply the adjusted size to smaller auras
                aura:SetSize(adjustedSize, adjustedSize)
                if not MasqueOn then
                    if aura.PurgeGlow then
                        aura.PurgeGlow:SetScale(targetAndFocusSmallAuraScale)
                    end
                    if aura.ImportantGlow then
                        aura.ImportantGlow:SetScale(targetAndFocusSmallAuraScale)
                    end
                    if aura.PandemicGlow then
                        aura.PandemicGlow:SetScale(targetAndFocusSmallAuraScale)
                    end
                    if aura.Stealable then
                        aura.Stealable:SetScale(targetAndFocusSmallAuraScale)
                    end
                    if aura.Border then
                        aura.Border:SetScale(targetAndFocusSmallAuraScale)
                    end
                end
                auraSize = adjustedSize
            end

            if aura.Count then
                aura.Count:SetScale(auraStackSize)
            end

            if aura.isEnlarged or aura.isCompacted then
                local sizeMultiplier = aura.isEnlarged and userEnlargedAuraSize or userCompactedAuraSize
                local defaultLargeAuraSize = aura.isLarge and 21 or 17
                local importantSize = defaultLargeAuraSize * sizeMultiplier
                aura:SetSize(importantSize, importantSize)
                if aura.Stealable then
                    aura.Stealable:SetScale(sizeMultiplier)
                end
                aura.wasEnlarged = true
                auraSize = importantSize
            -- elseif aura.wasEnlarged then
            --     if aura.Stealable then
            --         aura.Stealable:SetScale(1)
            --         aura.wasEnlarged = nil
            --     end
            end

            local columnIndex, rowIndex
            columnIndex = (i - 1) % aurasPerRow
            rowIndex = math_ceil(i / aurasPerRow)

            rowWidths[rowIndex] = rowWidths[rowIndex] or initialOffsetX

            if columnIndex == 0 and i ~= 1 then
                if buffsOnTop then
                    -- Adjust the Y-offset for stacking upwards when buffs are on top
                    currentYOffset = currentYOffset + (rowHeights[rowIndex - 1] or 0) + auraSpacingY
                else
                    -- Existing logic for stacking downwards
                    currentYOffset = currentYOffset - (rowHeights[rowIndex - 1] or 0) - auraSpacingY
                end
            elseif columnIndex ~= 0 then
                rowWidths[rowIndex] = rowWidths[rowIndex] + auraSpacingX
            end


            local offsetX = rowWidths[rowIndex]
            rowHeights[rowIndex] = math_max(auraSize, (rowHeights[rowIndex] or 0))
            rowWidths[rowIndex] = offsetX + auraSize

            aura:ClearAllPoints()
            if buffsOnTop then
                aura:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", offsetX, currentYOffset + initialOffsetY)
            else
                aura:SetPoint("TOPLEFT", self, "BOTTOMLEFT", offsetX, currentYOffset + initialOffsetY)
            end
        end

        return rowHeights
    end

    local unit = self.unit
    local isFriend = unit and not UnitCanAttack("player", unit)

    local buffs, debuffs = {}, {}
    local customAuraComparator = getCustomAuraComparator()

    local auraGlowsEnabled = (frameType == "target" and targetAuraGlows) or (frameType == "focus" and focusAuraGlows)


    for aura in self.auraPools:EnumerateActive() do
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, aura.auraInstanceID)
        if auraData then
            local isLarge = auraData.sourceUnit == "player" or auraData.sourceUnit == "pet"
            local canApply = auraData.canApplyAura or false

            -- Store the properties with the aura for later sorting
            aura.isLarge = isLarge
            aura.canApply = canApply
            local shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor

            if frameType == "target" then
                shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor = ShouldShowBuff(unit, auraData, "target")
                if auraGlowsEnabled then
                    isImportant = isImportant and targetImportantAuraGlow
                    isPandemic = isPandemic and targetdeBuffPandemicGlow
                    isEnlarged = isEnlarged and targetEnlargeAura
                    isCompacted = isCompacted and targetCompactAura
                else
                    isImportant = nil
                    isPandemic = nil
                    isEnlarged = nil
                    isCompacted = nil
                end
            elseif frameType == "focus" then
                shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor = ShouldShowBuff(unit, auraData, "focus")
                if auraGlowsEnabled then
                    isImportant = isImportant and focusImportantAuraGlow
                    isPandemic = isPandemic and focusdeBuffPandemicGlow
                    isEnlarged = isEnlarged and focusEnlargeAura
                    isCompacted = isCompacted and focusCompactAura
                else
                    isImportant = nil
                    isPandemic = nil
                    isEnlarged = nil
                    isCompacted = nil
                end
            end

            if opBarriersOn and opBarriers[auraData.spellId] and auraData.duration ~= 5 then
                isImportant = nil
                isEnlarged = nil
            end

            if onlyPandemicMine and not isLarge then
                isPandemic = false
            end

            if isEnlarged then
                if frameType == "target" then
                    if not targetEnlargeAuraFriendly and isFriend then
                        isEnlarged = false
                    end
                    if not targetEnlargeAuraEnemy and not isFriend then
                        isEnlarged = false
                    end
                elseif frameType == "focus" then
                    if not focusEnlargeAuraFriendly and isFriend then
                        isEnlarged = false
                    end
                    if not focusEnlargeAuraEnemy and not isFriend then
                        isEnlarged = false
                    end
                end
            end

            if shouldShowAura then
                if db2.increaseAuraStrata then
                    aura:SetFrameStrata("FULLSCREEN")
                end
                aura:Show()

                aura.spellId = auraData.spellId
                aura.duration = auraData.duration

                if trackedAuras[auraData.spellId] then
                    aura.Cooldown:SetCooldown(activeNonDurationAuras[auraData.spellId] or 0, trackedAuras[auraData.spellId].duration or 0)
                    C_Timer.After(0.1, function()
                        aura.Cooldown:SetCooldown(activeNonDurationAuras[auraData.spellId] or 0, trackedAuras[auraData.spellId].duration or 0)
                    end)
                end

                if (auraData.isStealable or (auraData.dispelName == "Magic" and ((not isFriend and auraData.isHelpful) or (isFriend and auraData.isHarmful)))) then
                    aura.isPurgeable = true
                else
                    aura.isPurgeable = false
                end

                if db2.clickthroughAuras then
                    aura:SetMouseClickEnabled(false)
                else
                    SetupAuraFilterClicks(aura)
                end

                -- Print Logic
                if db2.printAuraSpellIds and not aura.bbfHookAdded then
                    aura:HookScript("OnEnter", function()
                        local currentAuraID = aura.auraInstanceID
                        if not aura.bbfPrinted or aura.bbfLastPrintedAuraID ~= currentAuraID then
                            local thisAuraData = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, currentAuraID)
                            if thisAuraData then
                                local iconTexture = thisAuraData.icon and "|T" .. thisAuraData.icon .. ":16:16|t" or ""
                                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconTexture .. " " .. (thisAuraData.name or "Unknown") .. "  |A:worldquest-icon-engineering:14:14|a ID: " .. (thisAuraData.spellId or "Unknown"))
                                aura.bbfPrinted = true
                                aura.bbfLastPrintedAuraID = currentAuraID

                                -- Cancel existing timer if any
                                if aura.bbfTimer then
                                    aura.bbfTimer:Cancel()
                                end

                                -- Schedule the reset of bbfPrinted flag
                                aura.bbfTimer = C_Timer.NewTimer(6, function()
                                    aura.bbfPrinted = false
                                end)
                            end
                        end
                    end)
                    aura.bbfHookAdded = true
                end

                -- Enlarged logic
                if isEnlarged then
                    aura.isEnlarged = true
                else
                    aura.isEnlarged = false
                end

                -- Smaller logic
                if isCompacted then
                    aura.isCompacted = true
                else
                    aura.isCompacted = false
                end

                -- Important logic
                if isImportant then
                    aura.isImportant = true
                    if not aura.ImportantGlow then
                        aura.ImportantGlow = aura:CreateTexture(nil, "OVERLAY")
                        aura.ImportantGlow:SetAtlas("newplayertutorial-drag-slotgreen")
                        aura.ImportantGlow:SetDesaturated(true)
                    end
                    if aura.isEnlarged then
                        aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -enlargedTextureAdjustment, enlargedTextureAdjustment)
                        aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", enlargedTextureAdjustment, -enlargedTextureAdjustment)
                    elseif aura.isCompacted then
                        aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -compactedTextureAdjustment, compactedTextureAdjustment)
                        aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", compactedTextureAdjustment, -compactedTextureAdjustment)
                    else
                        aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -10, 10)
                        aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 10, -10)
                    end
                    if auraColor then
                        aura.ImportantGlow:SetVertexColor(auraColor[1], auraColor[2], auraColor[3], auraColor[4])
                    else
                        aura.ImportantGlow:SetVertexColor(0, 1, 0)
                    end
                    aura.ImportantGlow:Show()
                    if importantDispel and aura.isPurgeable then
                        if not aura.ImportantDispell then
                            aura.ImportantDispell = aura:CreateTexture(nil, "OVERLAY")
                            aura.ImportantDispell:SetAtlas("AdventureMapIcon-DailyQuest")
                            aura.ImportantDispell:SetDrawLayer("OVERLAY", 7)
                            aura.ImportantDispell:SetSize(11,13)
                            aura.ImportantDispell:SetPoint("BOTTOMLEFT", aura, "BOTTOMLEFT", -2.5, -2)
                        else
                            aura.ImportantDispell:Show()
                        end
                    elseif aura.ImportantDispell then
                        aura.ImportantDispell:Hide()
                    end
                else--if aura.isImportant then
                    aura.isImportant = false
                    if aura.ImportantGlow then
                        aura.ImportantGlow:Hide()
                    end
                    if aura.Stealable and auraData.isStealable then
                        aura.Stealable:SetAlpha(1)
                    end
                    if aura.ImportantDispell then
                        aura.ImportantDispell:Hide()
                    end
                end

                -- Better Purge Glow
                if ((frameType == "target" and (auraData.isStealable or (displayDispelGlowAlways and aura.isPurgeable)) and betterTargetPurgeGlow) or
                (frameType == "focus" and (auraData.isStealable or (displayDispelGlowAlways and aura.isPurgeable)) and betterFocusPurgeGlow)) then
                    if not aura.isImportant then
                        if not aura.PurgeGlow then
                            aura.PurgeGlow = aura:CreateTexture(nil, "OVERLAY")
                            aura.PurgeGlow:SetAtlas("newplayertutorial-drag-slotblue")
                        end
                        if aura.isEnlarged then
                            aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -enlargedTextureAdjustment, enlargedTextureAdjustment)
                            aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", enlargedTextureAdjustment, -enlargedTextureAdjustment)
                        elseif aura.isCompacted then
                            aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -compactedTextureAdjustment, compactedTextureAdjustment)
                            aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", compactedTextureAdjustment, -compactedTextureAdjustment)
                        else
                            aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -10, 10)
                            aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 10, -10)
                        end
                        aura.isPurgeGlow = true
                        if changePurgeTextureColor then
                            aura.PurgeGlow:SetDesaturated(true)
                            aura.PurgeGlow:SetVertexColor(unpack(purgeTextureColorRGB))
                        end
                        aura.PurgeGlow:Show()
                    end
                else
                    if aura.PurgeGlow then
                        if aura.Stealable and auraData.isStealable then
                            aura.Stealable:SetAlpha(1)
                        end
                        aura.PurgeGlow:Hide()
                    end
                    aura.isPurgeGlow = false
                    if displayDispelGlowAlways then
                        if auraData.dispelName == "Magic" and ((not isFriend and auraData.isHelpful) or (isFriend and auraData.isHarmful)) then
                            if aura.Stealable then
                                aura.Stealable:Show()
                                if changePurgeTextureColor then
                                    aura.Stealable:SetVertexColor(unpack(purgeTextureColorRGB))
                                end
                            end
                        else
                            if aura.Stealable then
                                aura.Stealable:Hide()
                            end
                        end
                    end
                end

                -- Pandemic Logic
                if isPandemic then
                    aura.expirationTime = auraData.expirationTime
                    aura.isPandemic = true
                    trackedBuffs[aura.auraInstanceID] = aura
                    StartCheckBuffsTimer()
                else--if aura.isPandemic then
                    aura.isPandemic = false
                    if aura.PandemicGlow then
                        aura.PandemicGlow:Hide()
                    end
                end

                if aura.isImportant or aura.isPurgeGlow or (aura.isPandemicActive and isPandemic) then
                    if aura.border then
                        aura.border:SetAlpha(0)
                    end
                    if aura.Border then
                        aura.Border:SetAlpha(0)
                    end
                    if aura.Stealable then
                        aura.Stealable:SetAlpha(0)
                    end
                else
                    if aura.border then
                        if not aura.Border then
                            aura.border:SetAlpha(1)
                        end
                    end
                    if aura.Border then
                        aura.Border:SetAlpha(1)
                    end
                    if aura.Stealable then
                        aura.Stealable:SetAlpha(1)
                    end
                end

                --print(aura.Stealable, aura.Stealable:IsShown())

                -- if aura.Stealable and aura.Stealable:IsShown() then
                --     if aura.border then
                --         aura.border:Hide()
                --         aura.Icon:SetTexCoord(0, 1, 0, 1)
                --     end
                -- else
                --     if aura.border then
                --         aura.border:Show()
                --         aura.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                --     end
                -- end

                -- if BBF.purge then
                --     if auraData.dispelName == "Magic" and auraData.isHelpful then
                --         if aura.Stealable then
                --             aura.Stealable:Show()
                --         end
                --     else
                --         if aura.Stealable then
                --             aura.Stealable:Hide()
                --         end
                --     end
                -- end

                if aura.Border ~= nil then
                    debuffs[#debuffs + 1] = aura
                else
                    buffs[#buffs + 1] = aura
                end
            else
                aura:Hide()
                if aura.PandemicGlow then
                    aura.PandemicGlow:Hide()
                end
            end
        end
    end

    table.sort(buffs, customAuraComparator)
    table.sort(debuffs, customAuraComparator)

    if not isFriend then
        if self.buffsOnTop then
            self.rowHeights = adjustAuraPosition(debuffs, targetAndFocusAuraOffsetY, self.buffsOnTop)
            local totalDebuffHeight = sum(self.rowHeights)

            local yOffsetForBuffs = totalDebuffHeight + (auraSpacingY * #self.rowHeights) + targetAndFocusAuraOffsetY
            if #debuffs > 0 then
                yOffsetForBuffs = yOffsetForBuffs + 5 + auraTypeGap
            end

            local buffRowHeights = adjustAuraPosition(buffs, yOffsetForBuffs, self.buffsOnTop)
            if #buffs > 0 and #debuffs > 0 then
                self.rowHeights[#self.rowHeights] = self.rowHeights[#self.rowHeights] + auraTypeGap
            end
            for _, height in ipairs(buffRowHeights) do
                table_insert(self.rowHeights, height)
            end
        else
            self.rowHeights = adjustAuraPosition(debuffs, 0)
            local totalDebuffHeight = sum(self.rowHeights)
            local buffRowHeights
            if #debuffs == 0 then
                buffRowHeights = adjustAuraPosition(buffs, -totalDebuffHeight - (auraSpacingY * #self.rowHeights))
            else
                buffRowHeights = adjustAuraPosition(buffs, -totalDebuffHeight - (auraSpacingY * #self.rowHeights) - auraTypeGap)
            end
            if #buffs > 0 and #debuffs > 0 then
                self.rowHeights[#self.rowHeights] = self.rowHeights[#self.rowHeights] + auraTypeGap
            end
            for _, height in ipairs(buffRowHeights) do
                table_insert(self.rowHeights, height)
            end
        end
    else
        if self.buffsOnTop then
            self.rowHeights = adjustAuraPosition(buffs, targetAndFocusAuraOffsetY, self.buffsOnTop)
            local totalBuffHeight = sum(self.rowHeights)

            local yOffsetForDebuffs = totalBuffHeight + (auraSpacingY * #self.rowHeights) + targetAndFocusAuraOffsetY
            if #buffs > 0 then
                yOffsetForDebuffs = yOffsetForDebuffs + 5 + auraTypeGap
            end

            local debuffRowHeights = adjustAuraPosition(debuffs, yOffsetForDebuffs, self.buffsOnTop)
            if #buffs > 0 and #debuffs > 0 then
                self.rowHeights[#self.rowHeights] = self.rowHeights[#self.rowHeights] + auraTypeGap
            end
            for _, height in ipairs(debuffRowHeights) do
                table_insert(self.rowHeights, height)
            end
        else
            self.rowHeights = adjustAuraPosition(buffs, 0)
            local totalBuffHeight = sum(self.rowHeights)
            local debuffRowHeights
            if #buffs == 0 then
                debuffRowHeights = adjustAuraPosition(debuffs, -totalBuffHeight - (auraSpacingY * #self.rowHeights))
            else
                debuffRowHeights = adjustAuraPosition(debuffs, -totalBuffHeight - (auraSpacingY * #self.rowHeights) - auraTypeGap)
            end
            if #buffs > 0 and #debuffs > 0 then
                self.rowHeights[#self.rowHeights] = self.rowHeights[#self.rowHeights] + auraTypeGap
            end
            for _, height in ipairs(debuffRowHeights) do
                table_insert(self.rowHeights, height)
            end
        end
    end

    -- if not targetStaticCastbar or not targetDetachCastbar then
    --     if frameType == "target" then
    --         adjustCastbar(TargetFrame.spellbar, TargetFrameSpellBar)
    --     elseif frameType == "focus" then
    --         adjustCastbar(FocusFrame.spellbar, FocusFrameSpellBar)
    --     end
    -- end

    -- Check if the number of aura rows has changed
    if #self.rowHeights ~= self.previousAuraRows then
        -- The number of aura rows has changed, adjust the castbar
        if not self.staticCastbar and self.spellbar:IsShown() then
            if frameType == "target" then
                adjustCastbar(self.spellbar, TargetFrameSpellBar)
            elseif frameType == "focus" then
                adjustCastbar(self.spellbar, FocusFrameSpellBar)
            end
        end
    end

    -- Store the current number of rows for the next check
    self.previousAuraRows = #self.rowHeights

    addMasque(frameType)
end

-- Function to create the toggle icon
local toggleIconGlobal = nil
local shouldKeepAurasVisible = false
local hiddenAuras = 0
--local showHiddenAurasIcon = true

local function UpdateHiddenAurasCount()
    if not showHiddenAurasIcon then
        if toggleIconGlobal then
            toggleIconGlobal:Hide()
            return
        end
    else
        if toggleIconGlobal then
            toggleIconGlobal:Show()
        end
    end

    if toggleIconGlobal then
        toggleIconGlobal.hiddenAurasCount:SetText(hiddenAuras)
        if hiddenAuras == 1 then
            toggleIconGlobal.hiddenAurasCount:SetPoint("CENTER", ToggleHiddenAurasButton, "CENTER", -1.5, 0)
        elseif hiddenAuras == 0 then
            toggleIconGlobal:Hide()
        else
            toggleIconGlobal.hiddenAurasCount:SetPoint("CENTER", ToggleHiddenAurasButton, "CENTER", 0, 0)
        end
    end
end

local function ResetHiddenAurasCount()
    hiddenAuras = 0
    UpdateHiddenAurasCount()
end

-- Functions to show and hide the hidden auras
local function ShowHiddenAuras()
    if ToggleHiddenAurasButton.isDropdownExpanded then
        for _, auraFrame in ipairs(BuffFrame.auraFrames) do
            if auraFrame.isAuraHidden then
                auraFrame:Show()
            end
        end
    end
end

local function HideHiddenAuras()
    if not shouldKeepAurasVisible then
        for _, auraFrame in ipairs(BuffFrame.auraFrames) do
            if auraFrame.isAuraHidden then
                auraFrame:Hide()
            end
        end
    end
end

local function CreateToggleIcon()
    if not showHiddenAurasIcon then return end
    if toggleIconGlobal then return toggleIconGlobal end

    local toggleIcon = CreateFrame("Button", "ToggleHiddenAurasButton", BuffFrame)
    toggleIcon:SetSize(30, 30)
    local currentAuraSize = BuffFrame.AuraContainer.iconScale
    local addIconsToRight = BuffFrame.AuraContainer.addIconsToRight
    if currentAuraSize then
        toggleIcon:SetScale(currentAuraSize)
    end
    if BuffFrame.CollapseAndExpandButton then
        if addIconsToRight then
            toggleIcon:SetPoint("RIGHT", BuffFrame.CollapseAndExpandButton, "LEFT", 0, 0)
        else
            toggleIcon:SetPoint("LEFT", BuffFrame.CollapseAndExpandButton, "RIGHT", 0, 0)
        end
    else
        toggleIcon:SetPoint("TOPLEFT", BuffFrame, "TOPRIGHT", 0, -6)
    end

    local Icon = toggleIcon:CreateTexture(nil, "BACKGROUND")
    Icon:SetAllPoints()
    Icon:SetTexture(BetterBlizzFramesDB.auraToggleIconTexture)

    -------
    if C_AddOns.IsAddOnLoaded("SUI") then
        if SUIDB and SUIDB["profiles"] and SUIDB["profiles"]["Default"] and SUIDB["profiles"]["Default"]["general"] then
            -- Now check if the theme variable doesn't exist or is nil
            if SUIDB["profiles"]["Default"]["general"]["theme"] == "Dark" or SUIDB["profiles"]["Default"]["general"]["theme"] == "Custom" or SUIDB["profiles"]["Default"]["general"]["theme"] == "Class" then
                Icon:SetTexCoord(0.10000000149012, 0.89999997615814, 0.89999997615814, 0.10000000149012)
                -- Border creation
                local border = CreateFrame("Frame", nil, toggleIcon)
                border:SetSize(34, 34)
                border:SetPoint("CENTER", toggleIcon, "CENTER", 0, 0)

                border.texture = border:CreateTexture()
                border.texture:SetAllPoints()
                border.texture:SetTexture("Interface\\Addons\\SUI\\Media\\Textures\\Core\\gloss")
                border.texture:SetTexCoord(0, 1, 0, 1)
                border.texture:SetDrawLayer("BACKGROUND", -7)
                border.texture:SetVertexColor(0.4, 0.35, 0.35)

                -- Optional shadow effect
                local Backdrop = {
                    bgFile = nil,
                    edgeFile = "Interface\\Addons\\SUI\\Media\\Textures\\Core\\outer_shadow",
                    tile = false,
                    tileSize = 32,
                    edgeSize = 6,
                    insets = { left = 6, right = 6, top = 6, bottom = 6 },
                }

                border.shadow = CreateFrame("Frame", nil, border, "BackdropTemplate")
                border.shadow:SetPoint("TOPLEFT", border, "TOPLEFT", -4, 4)
                border.shadow:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 4, -4)
                border.shadow:SetBackdrop(Backdrop)
                border.shadow:SetBackdropBorderColor(unpack(SUI:Color(0.25, 0.9)))
            end
        end
    end
    -------
    if BetterBlizzFramesDB.enableMasque and C_AddOns.IsAddOnLoaded("Masque") then
        addToMasque(toggleIcon, MasquePlayerBuffs)
    end
    toggleIcon.icon = Icon
    toggleIcon.Icon = Icon

    -- Creating FontString to display the count of hidden auras
    toggleIcon.hiddenAurasCount = toggleIcon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toggleIcon.hiddenAurasCount:SetPoint("CENTER", toggleIcon, "CENTER", 0, 0)
    toggleIcon.hiddenAurasCount:SetTextColor(1, 1, 1)

    toggleIcon.isAurasShown = false

    -- Toggle hidden auras visibility on click or rotate direction with Alt + Left Click
    toggleIcon:SetScript("OnClick", function(self, button)
        if IsAltKeyDown() and button == "LeftButton" then
            -- Rotate the hiddenIconDirection
            if BetterBlizzFramesDB.hiddenIconDirection == "BOTTOM" then
                BetterBlizzFramesDB.hiddenIconDirection = "LEFT"
            elseif BetterBlizzFramesDB.hiddenIconDirection == "LEFT" then
                BetterBlizzFramesDB.hiddenIconDirection = "TOP"
            elseif BetterBlizzFramesDB.hiddenIconDirection == "TOP" then
                BetterBlizzFramesDB.hiddenIconDirection = "RIGHT"
            elseif BetterBlizzFramesDB.hiddenIconDirection == "RIGHT" then
                BetterBlizzFramesDB.hiddenIconDirection = "BOTTOM"
            end

            BBF.RefreshAllAuraFrames()

            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Hidden Icon Direction set to: " .. BetterBlizzFramesDB.hiddenIconDirection)

        elseif IsShiftKeyDown() then
            -- Reset position to default
            toggleIcon:ClearAllPoints()
            if BuffFrame.CollapseAndExpandButton then
                if BuffFrame.AuraContainer.addIconsToRight then
                    toggleIcon:SetPoint("RIGHT", BuffFrame.CollapseAndExpandButton, "LEFT", 0, 0)
                else
                    toggleIcon:SetPoint("LEFT", BuffFrame.CollapseAndExpandButton, "RIGHT", 0, 0)
                end
            else
                toggleIcon:SetPoint("TOPLEFT", BuffFrame, "TOPRIGHT", 0, -6)
            end
            BetterBlizzFramesDB.toggleIconPosition = nil
        else
            -- Toggle hidden auras visibility
            shouldKeepAurasVisible = not shouldKeepAurasVisible
            BuffFrame:UpdateAuraButtons()
            if shouldKeepAurasVisible then
                ShowHiddenAuras()
            else
                HideHiddenAuras()
            end
            UpdateHiddenAurasCount()
        end
    end)


    toggleIcon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -10)
        GameTooltip:AddLine("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames")
        GameTooltip:AddLine("Filtered buffs. Click to show/hide currently hidden buffs.\n\n|cff00ff00To Whitelist an Aura:|r\nShift+Alt + LeftClick\n\n|cffff0000To Blacklist an Aura:|r\nShift+Alt + RightClick |cffffff00OR|r\nCtrl+Alt RightClick with \"Show Mine\" tag\n\nCtrl+LeftClick to move.\nShift+LeftClick to reset position.\nAlt+LeftClick to change direction.\n\n(You can hide this icon in settings)", 1, 1, 1, true)
        GameTooltip:Show()
        if not self.isAurasShown then
            ShowHiddenAuras()
        end
    end)

    toggleIcon:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if not self.isAurasShown then
            HideHiddenAuras()
        end
    end)

    -- Enable dragging with Ctrl + Left Click
    toggleIcon:SetMovable(true)
    toggleIcon:EnableMouse(true)
    toggleIcon:RegisterForDrag("LeftButton")
    toggleIcon:SetScript("OnDragStart", function(self)
        if IsControlKeyDown() then
            self:StartMoving()
        end
    end)
    toggleIcon:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save the new position
        local point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint()
        BetterBlizzFramesDB.toggleIconPosition = {point, nil, relativePoint, xOffset, yOffset}
    end)

    -- Load saved position if available
    if BetterBlizzFramesDB.toggleIconPosition then
        local pos = BetterBlizzFramesDB.toggleIconPosition
        toggleIcon:ClearAllPoints()
        toggleIcon:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
    end

    toggleIconGlobal = toggleIcon
    return toggleIcon
end



local BuffFrame = BuffFrame
local printedMsg
local function PersonalBuffFrameFilterAndGrid(self)
    ResetHiddenAurasCount()
    local isExpanded = BuffFrame:IsExpanded();
    local currentAuraSize = BuffFrame.AuraContainer.iconScale
    local addIconsToRight = BuffFrame.AuraContainer.addIconsToRight
    local addIconsToTop = BuffFrame.AuraContainer.addIconsToTop
    if ToggleHiddenAurasButton then
        ToggleHiddenAurasButton:SetScale(currentAuraSize)
    end
    local db = BetterBlizzFramesDB

    -- Define the parameters for your grid system
    local maxAurasPerRow = BuffFrame.AuraContainer.iconStride
    local auraSpacingX = BuffFrame.AuraContainer.iconPadding - 7 + playerAuraSpacingX
    local auraSpacingY = BuffFrame.AuraContainer.iconPadding + 8 + playerAuraSpacingY
    local auraSize = 32;      -- Set the size of each aura frame
    --local auraScale = BuffFrame.AuraContainer.iconScale

    local currentRow = 1;
    local currentCol = 1;
    local xOffset = 0;
    local yOffset = 0;
    local hiddenYOffset = 0-- -auraSpacingY - auraSize + playerAuraSpacingY;
    local hiddenXOffset = 0
    local toggleIcon = showHiddenAurasIcon and CreateToggleIcon() or nil

    -- Initialize offsets based on the direction setting
    if db.hiddenIconDirection == "DOWN" then
        hiddenYOffset = -auraSpacingY - auraSize + playerAuraSpacingY
    elseif db.hiddenIconDirection == "UP" then
        hiddenYOffset = auraSpacingY + auraSize - playerAuraSpacingY
    elseif db.hiddenIconDirection == "LEFT" then
        hiddenXOffset = -auraSpacingX - auraSize
    elseif db.hiddenIconDirection == "RIGHT" then
        hiddenXOffset = auraSpacingX + auraSize
    end

    if isExpanded then
    for auraIndex, auraInfo in ipairs(BuffFrame.auraInfo or {}) do
        --if isExpanded or not auraInfo.hideUnlessExpanded then
            local auraFrame = BuffFrame.auraFrames[auraIndex]
            if auraFrame and not auraFrame.isAuraAnchor then

                local name, icon, count, dispelType, duration, expirationTime, source,
                    isStealable, nameplateShowPersonal, spellId, canApplyAura,
                    isBossDebuff, castByPlayer, nameplateShowAll, timeMod

                local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID

                if auraInfo.auraType == "TempEnchant" then
                    hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()
                    if mainHandEnchantID then
                        spellId = mainHandEnchantID
                        duration = 120
                        expirationTime = mainHandExpiration
                        name = "Temp Enchant"
                    elseif offHandEnchantID then
                        spellId = offHandEnchantID
                        duration = 120
                        expirationTime = offHandExpiration
                        name = "Temp Enchant"
                    end
                else
                    name, icon, count, dispelType, duration, expirationTime, source,
                    isStealable, nameplateShowPersonal, spellId, canApplyAura,
                    isBossDebuff, castByPlayer, nameplateShowAll, timeMod
                    = BBF.TWWUnitAura("player", auraInfo.index, 'HELPFUL');
                end

              local auraData = {
                  name = name,
                  icon = icon,
                  count = count,
                  dispelType = dispelType,
                  duration = duration,
                  expirationTime = expirationTime,
                  sourceUnit = source,
                  isStealable = isStealable,
                  nameplateShowPersonal = nameplateShowPersonal,
                  spellId = spellId,
                  auraType = "Buff",
              };
                --local unit = self.unit
                -- Print spell ID logic
                if printAuraSpellIds and not auraFrame.bbfHookAdded then
                    auraFrame.bbfHookAdded = true
                    auraFrame:HookScript("OnEnter", function()
                        local currentAuraIndex = auraInfo.index
                        local name, icon, count, dispelType, duration, expirationTime, source,
                            isStealable, nameplateShowPersonal, spellId, canApplyAura,
                            isBossDebuff, castByPlayer, nameplateShowAll, timeMod, hasMainHandEnchant,
                            mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID
                        if auraInfo.auraType == "TempEnchant" then
                            hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()
                            if mainHandEnchantID then
                                spellId = mainHandEnchantID
                                name = "Temp Enchant Mainhand"
                            elseif offHandEnchantID then
                                spellId = offHandEnchantID
                                name = "Temp Enchant Offhand"
                            end
                        else
                            name, icon, count, dispelType, duration, expirationTime, source,
                            isStealable, nameplateShowPersonal, spellId, canApplyAura,
                            isBossDebuff, castByPlayer, nameplateShowAll, timeMod
                            = BBF.TWWUnitAura("player", currentAuraIndex, 'HELPFUL');
                        end

                        local auraData = {
                            name = name,
                            icon = icon,
                            count = count,
                            dispelType = dispelType,
                            duration = duration,
                            expirationTime = expirationTime,
                            sourceUnit = source,
                            isStealable = isStealable,
                            nameplateShowPersonal = nameplateShowPersonal,
                            spellId = spellId,
                            auraType = auraInfo.auraType,
                        };

                        if auraData and (not auraFrame.bbfPrinted or auraFrame.bbfLastPrintedAuraIndex ~= currentAuraIndex) then
                            local iconTexture = auraData.icon and "|T" .. auraData.icon .. ":16:16|t" or ""
                            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconTexture .. " " .. (auraData.name or "Unknown") .. "  |A:worldquest-icon-engineering:14:14|a ID: " .. (auraData.spellId or "Unknown"))
                            auraFrame.bbfPrinted = true
                            auraFrame.bbfLastPrintedAuraIndex = currentAuraIndex  -- Store the index of the aura that was just printed
                            -- Cancel existing timer if any
                            if auraFrame.bbfTimer then
                                auraFrame.bbfTimer:Cancel()
                            end
                            -- Schedule the reset of bbfPrinted flag
                            auraFrame.bbfTimer = C_Timer.NewTimer(6, function()
                                auraFrame.bbfPrinted = false
                            end)
                        end
                    end)
                end

                local shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor
                shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor = ShouldShowBuff("player", auraData, "playerBuffFrame")
                isImportant = isImportant and playerAuraImportantGlow

                -- Nonprint logic
                if shouldShowAura then

                    local isPurgeable = dispelType == "Magic"

                    if opBarriersOn and opBarriers[auraData.spellId] and auraData.duration ~= 5 then
                        isImportant = nil
                    end

                    if not auraFrame.GlowFrame then
                        auraFrame.GlowFrame = CreateFrame("Frame", nil, auraFrame)
                        auraFrame.GlowFrame:SetAllPoints(auraFrame)
                        auraFrame.GlowFrame:SetFrameLevel(auraFrame:GetFrameLevel() + 1)
                        auraFrame.GlowFrame:SetFrameStrata("MEDIUM")
                    end

                    if addCooldownFramePlayerBuffs then
                        if not auraFrame.Cooldown then
                            local cooldownFrame = CreateFrame("Cooldown", nil, auraFrame, "CooldownFrameTemplate")
                            cooldownFrame:SetAllPoints(auraFrame.Icon)
                            cooldownFrame:SetDrawEdge(false)
                            cooldownFrame:SetDrawSwipe(true)
                            cooldownFrame:SetReverse(true)
                            auraFrame.Count:SetParent(auraFrame.GlowFrame)
                            if hideDefaultPlayerAuraCdText then
                                cooldownFrame:SetHideCountdownNumbers(true)
                            else
                                local cdText = cooldownFrame:GetRegions()
                                if cdText then
                                    cdText:SetScale(0.85)
                                end
                            end
                            auraFrame.Cooldown = cooldownFrame
                        end

                        if duration and duration > 0 and expirationTime then
                            local startTime = expirationTime - duration
                            auraFrame.Cooldown:SetCooldown(startTime, duration)
                        else
                            auraFrame.Cooldown:Hide()
                        end

                        if hideDefaultPlayerAuraDuration then
                            auraFrame.Duration:SetAlpha(0)
                        end
                    end

                    auraFrame:Show();
                    auraFrame:ClearAllPoints();
                    if addIconsToRight then
                        if addIconsToTop then
                            auraFrame:SetPoint("BOTTOMLEFT", BuffFrame, "BOTTOMLEFT", xOffset + 15, yOffset);
                        else
                            auraFrame:SetPoint("TOPLEFT", BuffFrame, "TOPLEFT", xOffset + 15, -yOffset);
                        end
                    else
                        if addIconsToTop then
                            auraFrame:SetPoint("BOTTOMRIGHT", BuffFrame, "BOTTOMRIGHT", -xOffset - 15, yOffset);
                        else
                            auraFrame:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", -xOffset - 15, -yOffset);
                        end
                    end

                    auraFrame.spellId = auraData.spellId

                    SetupAuraFilterClicks(auraFrame)

                    -- Update column and row counters
                    currentCol = currentCol + 1;
                    if currentCol > maxAurasPerRow then
                        currentRow = currentRow + 1;
                        currentCol = 1;
                    end
                    -- Calculate the new offsets
                    xOffset = (currentCol - 1) * (auraSize + auraSpacingX);
                    yOffset = (currentRow - 1) * (auraSize + auraSpacingY);
                    auraFrame.isAuraHidden = false

                    -- Important logic
                    if isImportant then
                        local borderFrame = BBF.auraBorders[auraFrame]
                        auraFrame.isImportant = true
                        if not auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow = auraFrame.GlowFrame:CreateTexture(nil, "OVERLAY", nil, 2)
                            if borderFrame then
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame.Icon, "TOPLEFT", -15, 17)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame.Icon, "BOTTOMRIGHT", 15, -16)
                            else
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame.Icon, "TOPLEFT", -15, 14.5)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame.Icon, "BOTTOMRIGHT", 15, -15)
                            end
                            auraFrame.ImportantGlow:SetDrawLayer("OVERLAY", 7)
                            auraFrame.ImportantGlow:SetAtlas("newplayertutorial-drag-slotgreen")
                            auraFrame.ImportantGlow:SetDesaturated(true)
                        end
                        if auraColor then
                            auraFrame.ImportantGlow:SetVertexColor(auraColor[1], auraColor[2], auraColor[3], auraColor[4])
                        else
                            auraFrame.ImportantGlow:SetVertexColor(0, 1, 0)
                        end
                        auraFrame.Duration:SetParent(auraFrame.GlowFrame)
                        auraFrame.ImportantGlow:Show()
                    else--if auraFrame.isImportant then
                        auraFrame.isImportant = false
                        if auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow:Hide()
                        end
                    end
                    if isPurgeable and db.showPurgeTextureOnSelf and not isImportant then
                        local borderFrame = BBF.auraBorders[auraFrame]
                        auraFrame.isPurgeGlow = true
                        if not auraFrame.PurgeGlow then
                            auraFrame.PurgeGlow = auraFrame.GlowFrame:CreateTexture(nil, "OVERLAY", nil, 1)
                            if (betterTargetPurgeGlow or betterFocusPurgeGlow) then
                                if borderFrame then
                                    auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame.Icon, "TOPLEFT", -15, 17)
                                    auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame.Icon, "BOTTOMRIGHT", 15, -16)
                                else
                                    auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame.Icon, "TOPLEFT", -15, 14.5)
                                    auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame.Icon, "BOTTOMRIGHT", 15, -15)
                                end
                                auraFrame.PurgeGlow:SetAtlas("newplayertutorial-drag-slotblue")
                            else
                                if borderFrame then
                                    auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame.Icon, "TOPLEFT", -5, 5.5)
                                    auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame.Icon, "BOTTOMRIGHT", 3, -3.5)
                                else
                                    auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame.Icon, "TOPLEFT", -5, 4.5)
                                    auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame.Icon, "BOTTOMRIGHT", 3, -2.5)
                                end
                                auraFrame.PurgeGlow:SetTexture(237671)
                                auraFrame.PurgeGlow:SetBlendMode("ADD")
                            end
                            auraFrame.PurgeGlow:SetDrawLayer("OVERLAY", 7)
                        end
                        if changePurgeTextureColor then
                            auraFrame.PurgeGlow:SetDesaturated(true)
                            auraFrame.PurgeGlow:SetVertexColor(unpack(purgeTextureColorRGB))
                        end
                        auraFrame.Duration:SetParent(auraFrame.GlowFrame)
                        auraFrame.PurgeGlow:Show()
                    else--if auraFrame.isPurgeGlow then
                        auraFrame.isPurgeGlow = false
                        if auraFrame.PurgeGlow then
                            auraFrame.PurgeGlow:Hide()
                        end
                    end
                    auraFrame.Duration:SetDrawLayer("OVERLAY")
                else
                    hiddenAuras = hiddenAuras + 1
                    if not shouldKeepAurasVisible then
                        auraFrame:Hide()
                        auraFrame.isAuraHidden = true
                    end
                    if auraFrame.isImportant then
                        auraFrame.ImportantGlow:Hide()
                        auraFrame.isImportant = false
                    end
                    if auraFrame.isPurgeGlow then
                        auraFrame.PurgeGlow:Hide()
                        auraFrame.isPurgeGlow = false
                    end
                    auraFrame:ClearAllPoints()
                    if toggleIcon then
                        local direction = BetterBlizzFramesDB.hiddenIconDirection
                        if direction == "BOTTOM" then
                            auraFrame:SetPoint("TOP", ToggleHiddenAurasButton, "TOP", 0, hiddenYOffset - 35 + (addIconsToTop and 10 or 0))
                            hiddenYOffset = hiddenYOffset - auraSize - auraSpacingY + 10
                        elseif direction == "TOP" then
                            auraFrame:SetPoint("BOTTOM", ToggleHiddenAurasButton, "BOTTOM", 0, hiddenYOffset + 25 + (addIconsToTop and 10 or 0))
                            hiddenYOffset = hiddenYOffset + auraSize + auraSpacingY - 10
                        elseif direction == "LEFT" then
                            auraFrame:SetPoint("RIGHT", ToggleHiddenAurasButton, "LEFT", hiddenXOffset + 30, addIconsToTop and 5 or -5)
                            hiddenXOffset = hiddenXOffset - auraSize - auraSpacingX
                        elseif direction == "RIGHT" then
                            auraFrame:SetPoint("LEFT", ToggleHiddenAurasButton, "RIGHT", hiddenXOffset - 30, addIconsToTop and 5 or -5)
                            hiddenXOffset = hiddenXOffset + auraSize + auraSpacingX
                        end
                    end
                end
            end
        end
    else
        if not printedMsg then
            printedMsg = true
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Buff Filtering with auras collapsed is currently not supported. Expand them (Pointy arrow next to Buffs) and reload or turn Player Buff filtering off. It is being worked on.")
            C_Timer.After(30, function()
                printedMsg = false
            end)
        end
    end
    UpdateHiddenAurasCount()
end

--local tooltip = CreateFrame("GameTooltip", "AuraTooltip", nil, "GameTooltipTemplate")
--tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
local DebuffFrame = DebuffFrame
local function PersonalDebuffFrameFilterAndGrid(self)
    local maxAurasPerRow = DebuffFrame.AuraContainer.iconStride
    local auraSpacingX = DebuffFrame.AuraContainer.iconPadding - 7 + playerAuraSpacingX
    local auraSpacingY = DebuffFrame.AuraContainer.iconPadding + 8 + playerAuraSpacingY
    local auraSize = 32;      -- Set the size of each aura frame
    local addIconsToRight = DebuffFrame.AuraContainer.addIconsToRight
    local addIconsToTop = DebuffFrame.AuraContainer.addIconsToTop

    --local dotChecker = BetterBlizzFramesDB.debuffDotChecker
    local printAuraIds = printAuraSpellIds

    local currentRow = 1;
    local currentCol = 1;
    local xOffset = 0;
    local yOffset = 0;

    -- Create a texture next to the DebuffFrame
--[=[
    local warningTexture
    if dotChecker then
        if not DebuffFrame.warningTexture then
            warningTexture = DebuffFrame:CreateTexture(nil, "OVERLAY")
            warningTexture:SetPoint("TOPLEFT", DebuffFrame, "TOPRIGHT", 4, -2)
            warningTexture:SetSize(32, 32)
            warningTexture:SetAtlas("poisons")
            warningTexture:Hide()
            DebuffFrame.warningTexture = warningTexture
        else
            warningTexture = DebuffFrame.warningTexture
        end
        warningTexture:EnableMouse(true)
        warningTexture:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("BetterBlizzFrames\nDoT Detected", 1, 1, 1)
            GameTooltip:Show()
        end)

        warningTexture:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        warningTexture:SetMouseClickEnabled(false)
    end

    local keywordFound = false
    local keywords = {"over", "every",}

]=]


    for auraIndex, auraInfo in ipairs(DebuffFrame.auraInfo or {}) do
        --if isExpanded or not auraInfo.hideUnlessExpanded then
            local auraFrame = DebuffFrame.auraFrames[auraIndex]
            if auraFrame and not auraFrame.isAuraAnchor then
--[[
                if auraInfo then
                    print("Aura Data:")
                    for k, v in pairs(auraInfo) do
                        print(k, v)
                    end
                else
                    print("No aura data available.")
                end
]]
                --local spellID = select(10, UnitAura("player", auraInfo.index));
                --if ShouldHideSpell(spellID) then
                    local name, icon, count, dispelType, duration, expirationTime, source, 
                    isStealable, nameplateShowPersonal, spellId, canApplyAura, 
                    isBossDebuff, castByPlayer, nameplateShowAll, timeMod 
                  = BBF.TWWUnitAura("player", auraInfo.index, 'HARMFUL');

              local auraData = {
                  name = name,
                  icon = icon,
                  count = count,
                  dispelType = dispelType,
                  duration = duration,
                  expirationTime = expirationTime,
                  sourceUnit = source,
                  isStealable = isStealable,
                  nameplateShowPersonal = nameplateShowPersonal,
                  spellId = spellId,
                  auraType = auraInfo.auraType,
              };
                --local unit = self.unit
                if printAuraIds and not auraFrame.bbfHookAdded then
                    auraFrame.bbfHookAdded = true
                    auraFrame:HookScript("OnEnter", function()
                        if printAuraIds then
                            local currentAuraIndex = auraInfo.index
                            local name, icon, count, dispelType, duration, expirationTime, source, 
                            isStealable, nameplateShowPersonal, spellId, canApplyAura, 
                            isBossDebuff, castByPlayer, nameplateShowAll, timeMod 
                            = BBF.TWWUnitAura("player", currentAuraIndex, 'HARMFUL');

                            local auraData = {
                                name = name,
                                icon = icon,
                                count = count,
                                dispelType = dispelType,
                                duration = duration,
                                expirationTime = expirationTime,
                                sourceUnit = source,
                                isStealable = isStealable,
                                nameplateShowPersonal = nameplateShowPersonal,
                                spellId = spellId,
                                auraType = auraInfo.auraType,
                            };

                            if auraData and (not auraFrame.bbfPrinted or auraFrame.bbfLastPrintedAuraIndex ~= currentAuraIndex) then
                                local iconTexture = auraData.icon and "|T" .. auraData.icon .. ":16:16|t" or ""
                                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconTexture .. " " .. (auraData.name or "Unknown") .. "  |A:worldquest-icon-engineering:14:14|a ID: " .. (auraData.spellId or "Unknown"))
                                auraFrame.bbfPrinted = true
                                auraFrame.bbfLastPrintedAuraIndex = currentAuraIndex
                                -- Cancel existing timer if any
                                if auraFrame.bbfTimer then
                                    auraFrame.bbfTimer:Cancel()
                                end
                                -- Schedule the reset of bbfPrinted flag
                                auraFrame.bbfTimer = C_Timer.NewTimer(6, function()
                                    auraFrame.bbfPrinted = false
                                end)
                            end
                        end
                    end)
                end
                local shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor = ShouldShowBuff("player", auraData, "playerDebuffFrame")
                if shouldShowAura then
                    -- Check the tooltip for specified keywords
--[=[
                    tooltip:ClearLines()
                    tooltip:SetHyperlink("spell:" .. auraData.spellId)

                    local tooltipText = ""
                    for i = 1, tooltip:NumLines() do
                        local line = _G["AuraTooltipTextLeft" .. i]
                        tooltipText = tooltipText .. line:GetText()
                    end

                    for _, keyword in ipairs(keywords) do
                        if string.find(tooltipText:lower(), keyword) then
                            keywordFound = true
                            break
                        end
                    end

]=]

                    if addCooldownFramePlayerDebuffs then
                        if not auraFrame.Cooldown then
                            local cooldownFrame = CreateFrame("Cooldown", nil, auraFrame, "CooldownFrameTemplate")
                            cooldownFrame:SetAllPoints(auraFrame.Icon)
                            cooldownFrame:SetDrawEdge(false)
                            cooldownFrame:SetDrawSwipe(true)
                            cooldownFrame:SetReverse(true)
                            if hideDefaultPlayerAuraCdText then
                                cooldownFrame:SetHideCountdownNumbers(true)
                            end
                            auraFrame.Cooldown = cooldownFrame
                        end

                        if duration and duration > 0 and expirationTime then
                            local startTime = expirationTime - duration
                            auraFrame.Cooldown:SetCooldown(startTime, duration)
                        else
                            auraFrame.Cooldown:Hide()
                        end

                        if hideDefaultPlayerAuraDuration then
                            auraFrame.Duration:SetAlpha(0)
                        end
                    end

                    auraFrame.spellId = auraData.spellId

                    -- if auraData.spellId == 212183 then
                    --     --moved
                    -- end

                    SetupAuraFilterClicks(auraFrame)

                    auraFrame:Show();
                    auraFrame:ClearAllPoints();
                    if addIconsToRight then
                        if addIconsToTop then
                            auraFrame:SetPoint("BOTTOMLEFT", DebuffFrame, "BOTTOMLEFT", xOffset, yOffset);
                        else
                            auraFrame:SetPoint("TOPLEFT", DebuffFrame, "TOPLEFT", xOffset, -yOffset);
                        end
                    else
                        if addIconsToTop then
                            auraFrame:SetPoint("BOTTOMRIGHT", DebuffFrame, "BOTTOMRIGHT", -xOffset, yOffset);
                        else
                            auraFrame:SetPoint("TOPRIGHT", DebuffFrame, "TOPRIGHT", -xOffset, -yOffset);
                        end
                    end

                    -- Update column and row counters
                    currentCol = currentCol + 1;
                    if currentCol > maxAurasPerRow then
                        currentRow = currentRow + 1;
                        currentCol = 1;
                    end

                    -- Calculate the new offsets
                    xOffset = (currentCol - 1) * (auraSize + auraSpacingX);
                    yOffset = (currentRow - 1) * (auraSize + auraSpacingY);


                    -- Important logic
                    if isImportant then
                        local borderFrame = BBF.auraBorders[auraFrame]
                        auraFrame.isImportant = true
                        if not auraFrame.ImportantGlow then
                            auraFrame.GlowFrame = CreateFrame("Frame", nil, auraFrame)
                            auraFrame.GlowFrame:SetAllPoints(auraFrame)
                            auraFrame.GlowFrame:SetFrameLevel(auraFrame:GetFrameLevel() + 1)
                            auraFrame.ImportantGlow = auraFrame.GlowFrame:CreateTexture(nil, "OVERLAY")
                            if borderFrame then
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame.Icon, "TOPLEFT", -15, 17)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame.Icon, "BOTTOMRIGHT", 15, -16)
                            else
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame.Icon, "TOPLEFT", -15, 14.5)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame.Icon, "BOTTOMRIGHT", 15, -15)
                            end
                            --auraFrame.ImportantGlow:SetDrawLayer("OVERLAY", 7)
                            auraFrame.ImportantGlow:SetAtlas("newplayertutorial-drag-slotgreen")
                            auraFrame.ImportantGlow:SetDesaturated(true)
                        end
                        if auraColor then
                            auraFrame.ImportantGlow:SetVertexColor(auraColor[1], auraColor[2], auraColor[3], auraColor[4])
                        else
                            auraFrame.ImportantGlow:SetVertexColor(0, 1, 0)
                        end
                        auraFrame.DebuffBorder:Hide()
                        auraFrame.Duration:SetParent(auraFrame.GlowFrame)
                        auraFrame.Duration:SetDrawLayer("OVERLAY")
                        auraFrame.ImportantGlow:Show()
                    else
                        auraFrame.isImportant = false
                        if auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow:Hide()
                        end
                        auraFrame.DebuffBorder:Show()
                        auraFrame.Duration:SetParent(auraFrame)
                    end
                    auraFrame:SetMouseClickEnabled(false)
                else
                    auraFrame:Hide();
                end
            end
        --end
    end
--[=[
    if dotChecker then
        if keywordFound then
            warningTexture:Show()
        else
            warningTexture:Hide()
        end
    end
]=]
end

local auraMsgSent = false
function BBF.RefreshAllAuraFrames()
    BBF.UpdateUserAuraSettings()
    if BetterBlizzFramesDB.playerAuraFiltering then
        if playerBuffFilterOn then
            PersonalBuffFrameFilterAndGrid(BuffFrame)
        end
        if playerDebuffFilterOn then
            PersonalDebuffFrameFilterAndGrid(DebuffFrame)
        end
        AdjustAuras(TargetFrame, "target")
        AdjustAuras(FocusFrame, "focus")
    else
        if not auraMsgSent then
            auraMsgSent = true
            DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: You need to enable aura settings for blacklist and whitelist etc to work.")
            C_Timer.After(9, function()
                auraMsgSent = false
            end)
        end
    end
end

BBF.filterOverride = false
function BBF.ToggleFilterOverride()
    BBF.filterOverride = not BBF.filterOverride
    BBF.RefreshAllAuraFrames()
end

function BBF.SetupMasqueSupport()
    Masque = LibStub("Masque", true)
    if Masque then
        MasqueOn = true
        MasquePlayerBuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Player Buffs")
        MasquePlayerDebuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Player Debuffs")
        MasqueTargetBuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Target Buffs")
        MasqueTargetDebuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Target Debuffs")
        MasqueFocusBuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Focus Buffs")
        MasqueFocusDebuffs = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Focus Debuffs")
        local MasqueCastbars = Masque:Group("Better|cff00c0ffBlizz|rFrames", "Castbars")

        local function MsqSkinIcon(frame, group)
            local skinWrapper = CreateFrame("Frame")
            skinWrapper:SetParent(frame)
            skinWrapper:SetSize(30, 30)
            skinWrapper:SetAllPoints(frame.Icon)
            frame.Icon:Hide()
            frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
            frame.SkinnedIcon:SetSize(30, 30)
            frame.SkinnedIcon:SetPoint("CENTER")
            frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())
            hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
                skinWrapper:SetScale(frame.Icon:GetScale())
                frame.Icon:SetAlpha(0)
                frame.SkinnedIcon:SetTexture(tex)
            end)
            group:AddButton(skinWrapper, {
                Icon = frame.SkinnedIcon,
            })
        end
        if BetterBlizzFramesDB.playerCastBarShowIcon then
            MsqSkinIcon(PlayerCastingBarFrame, MasqueCastbars)
        end
        MsqSkinIcon(TargetFrameSpellBar, MasqueCastbars)
        MsqSkinIcon(FocusFrameSpellBar, MasqueCastbars)
        if BetterBlizzFramesDB.showPartyCastbar and BetterBlizzFramesDB.showPartyCastBarIcon then
            C_Timer.After(3, function()
                for i = 1, 5 do
                    local castbar = _G["Party"..i.."SpellBar"]
                    if castbar then
                        MsqSkinIcon(castbar, MasqueCastbars)
                    end
                end
            end)
        end

        -- Props to Masque Skinner: Blizz Buffs by Cybeloras of Aerie Peak
        local skinned = {}
        local function makeHook(group, container)
            local function updateFrames(frames)
                for i = 1, #frames do
                    local frame = frames[i]
                    if not skinned[frame] and frame.Icon.GetTexture then
                        skinned[frame] = 1

                        -- We have to make a wrapper to hold the skinnable components of the Icon
                        -- because the aura frames are not square (and so if we skinned them directly
                        -- with Masque, they'd get all distorted and weird).
                        local skinWrapper = CreateFrame("Frame")
                        skinWrapper:SetParent(frame)
                        skinWrapper:SetSize(30, 30)
                        skinWrapper:SetPoint("TOP")

                        -- Blizzard's code constantly tries to reposition the icon,
                        -- so we have to make our own icon that it won't try to move.
                        frame.Icon:Hide()
                        frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
                        frame.SkinnedIcon:SetSize(30, 30)
                        frame.SkinnedIcon:SetPoint("CENTER")
                        frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())
                        hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
                            frame.SkinnedIcon:SetTexture(tex)
                        end)

                        if frame.Count then
                            -- edit mode versions don't have stack text
                            frame.Count:SetParent(skinWrapper);
                        end
                        if frame.DebuffBorder then
                            frame.DebuffBorder:SetParent(skinWrapper);
                        end
                        if frame.TempEnchantBorder then
                            frame.TempEnchantBorder:SetParent(skinWrapper);
                            frame.TempEnchantBorder:SetVertexColor(.75, 0, 1)
                        end
                        if frame.Symbol then
                            -- Shows debuff types as text in colorblind mode (except it currently doesnt work)
                            frame.Symbol:SetParent(skinWrapper);
                        end

                        if C_AddOns.IsAddOnLoaded("SUI") then
                            local skinWrapper2 = CreateFrame("Frame")
                            skinWrapper2:SetParent(skinWrapper)
                            skinWrapper2:SetSize(30, 40)
                            skinWrapper2:SetPoint("TOP")
                            frame.Duration:SetParent(skinWrapper2)
                        end

                        local bType = frame.auraType or "Aura"

                        if bType == "DeadlyDebuff" then
                            bType = "Debuff"
                        end

                        group:AddButton(skinWrapper, {
                            Icon = frame.SkinnedIcon,
                            DebuffBorder = frame.DebuffBorder,
                            EnchantBorder = frame.TempEnchantBorder,
                            Count = frame.Count,
                            HotKey = frame.Symbol
                        }, bType)
                    end
                end
            end

            return function(self)
                updateFrames(self.auraFrames, group)
                if self.exampleAuraFrames then
                    updateFrames(self.exampleAuraFrames, group)
                end
            end
        end

        hooksecurefunc(BuffFrame, "UpdateAuraButtons", makeHook(MasquePlayerBuffs, BuffFrame))
        hooksecurefunc(BuffFrame, "OnEditModeEnter", makeHook(MasquePlayerBuffs, BuffFrame))
        hooksecurefunc(DebuffFrame, "UpdateAuraButtons", makeHook(MasquePlayerDebuffs, DebuffFrame))
        hooksecurefunc(DebuffFrame, "OnEditModeEnter", makeHook(MasquePlayerDebuffs, DebuffFrame))

        C_Timer.After(1.5, function()
            if toggleIconGlobal then
                MasquePlayerBuffs:AddButton(toggleIconGlobal)
            end
        end)

        local function hookUnitFrameAuras(frame, buffGroup, debuffGroup)
            local function updateUnitFrameAuras()
                for aura in frame.auraPools:EnumerateActive() do
                    if not skinned[aura] then
                        skinned[aura] = true
                        -- Check if the aura is a debuff
                        if aura.Border then
                            debuffGroup:AddButton(aura, {
                                Icon = aura.Icon,
                                DebuffBorder = aura.Border,
                                Cooldown = aura.Cooldown,
                            })
                        else
                            buffGroup:AddButton(aura, {
                                Icon = aura.Icon,
                                Cooldown = aura.Cooldown,
                            })
                        end
                    end
                end
                if not auraFilteringOn then
                    buffGroup:ReSkin(true)
                    debuffGroup:ReSkin(true)
                end
            end

            updateUnitFrameAuras()

            hooksecurefunc(frame, "UpdateAuras", updateUnitFrameAuras)
        end

        hookUnitFrameAuras(TargetFrame, MasqueTargetBuffs, MasqueTargetDebuffs)
        hookUnitFrameAuras(FocusFrame, MasqueFocusBuffs, MasqueFocusDebuffs)
    end
end

function BBF.HookPlayerAndTargetAuras()
    --Hook Player BuffFrame
    if playerBuffFilterOn and not playerBuffsHooked then
        if BetterBlizzFramesDB.PlayerAuraFrameBuffEnable then
            hooksecurefunc(BuffFrame, "UpdateAuraButtons", PersonalBuffFrameFilterAndGrid)
            playerBuffsHooked = true
            if BBF.BuffFrameHidden then
                BuffFrame:Show()
                BBF.BuffFrameHidden = nil
            end
        else
            BuffFrame:Hide()
            BBF.BuffFrameHidden = true
        end
    end

    --Hook Player DebuffFrame
    if playerDebuffFilterOn and not playerDebuffsHooked then
        if BetterBlizzFramesDB.PlayerAuraFramedeBuffEnable then
            hooksecurefunc(DebuffFrame, "UpdateAuraButtons", PersonalDebuffFrameFilterAndGrid)
            playerDebuffsHooked = true
            if BBF.DebuffFrameHidden then
                DebuffFrame:Show()
                BBF.DebuffFrameHidden = nil
            end
        else
            DebuffFrame:Hide()
            BBF.DebuffFrameHidden = true
        end
    end

    --Hook Target & Focus Frame
    if auraFilteringOn and not targetAurasHooked then

        if not BetterBlizzFramesDB.targetBuffEnable and not BetterBlizzFramesDB.targetdeBuffEnable then
            hooksecurefunc(TargetFrame, "UpdateAuras", function(self)
                for aura in self.auraPools:EnumerateActive() do
                    aura:Hide()
                end
            end)
            BBF.HidingAllTargetAuras = true
        else
            hooksecurefunc(TargetFrame, "UpdateAuras", function(self) AdjustAuras(self, "target") end)
        end

        if not BetterBlizzFramesDB.focusBuffEnable and not BetterBlizzFramesDB.focusdeBuffEnable then
            hooksecurefunc(FocusFrame, "UpdateAuras", function(self)
                for aura in self.auraPools:EnumerateActive() do
                    aura:Hide()
                end
            end)
            BBF.HidingAllFocusAuras = true
        else
            hooksecurefunc(FocusFrame, "UpdateAuras", function(self) AdjustAuras(self, "focus") end)
        end

        targetAurasHooked = true
    end

    --Hook Target & Focus Castbars
    if not targetCastbarsHooked then
        hooksecurefunc(TargetFrame.spellbar, "SetPoint", function()
            if shouldAdjustCastbar then
                adjustCastbar(TargetFrame.spellbar, TargetFrameSpellBar)
            else
                DefaultCastbarAdjustment(TargetFrame.spellbar, TargetFrameSpellBar)
            end
        end);
        hooksecurefunc(FocusFrame.spellbar, "SetPoint", function()
            if shouldAdjustCastbarFocus then
                adjustCastbar(FocusFrame.spellbar, FocusFrameSpellBar)
            else
                DefaultCastbarAdjustment(FocusFrame.spellbar, FocusFrameSpellBar)
            end
        end);
    end

    -- --Hook Target & Focus Castbars
    -- if not targetCastbarsHooked then
    --     if not shouldAdjustCastbar then
    --         hooksecurefunc(TargetFrame.spellbar, "SetPoint", function()
    --             DefaultCastbarAdjustment(TargetFrame.spellbar, TargetFrameSpellBar)
    --         end);
    --         hooksecurefunc(FocusFrame.spellbar, "SetPoint", function()
    --             DefaultCastbarAdjustment(FocusFrame.spellbar, FocusFrameSpellBar)
    --         end);
    --     end
    -- end

    if not BBF.buffDetector then
        BBF.buffDetector = CreateFrame("Frame")
        BBF.buffDetector:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        BBF.buffDetector:SetScript("OnEvent", BuffCastCheck)
    end
end