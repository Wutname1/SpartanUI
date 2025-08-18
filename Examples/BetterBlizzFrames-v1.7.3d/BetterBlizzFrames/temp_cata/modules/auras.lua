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
local smokeBombDetector

--local ipairs = ipairs
local math_ceil = math.ceil
local table_insert = table.insert
local table_sort = table.sort
local math_max = math.max

local Masque
local MasquePlayerBuffs
local MasquePlayerDebuffs
local MasqueTargetBuffs
local MasqueTargetDebuffs
local MasqueFocusBuffs
local MasqueFocusDebuffs
local MasqueOn

-- Function to add buffs and debuffs to Masque group
local function addToMasque(frameName, masqueGroup)
    local frame = _G[frameName]
    if frame and not frame.bbfMsq then
        masqueGroup:AddButton(frame)
        frame.bbfMsq = true
        --print(frame:GetName())
    end
end

local smokeBombId = 76577
local smokeBombCast = 0
local smokeTracker
local updateInterval = 0.1
local remainingTime = 5

local function UpdateAuraDuration(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed

    -- Only update every second
    if self.timeSinceLastUpdate >= updateInterval then
        remainingTime = remainingTime - 0.1
        if remainingTime <= 0 then
            self.duration:SetText("0 s")
            self:SetScript("OnUpdate", nil)
        else
            local displayTime = math.floor(remainingTime-0.2)
            self.duration:SetText(displayTime .. " s")
        end
        self.timeSinceLastUpdate = 0
    end
end

local function SmokeBombCheck(self, event)
    local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID = CombatLogGetCurrentEventInfo()
    if subEvent == "SPELL_CAST_SUCCESS" and spellID == smokeBombId then
        if smokeTracker then
            smokeTracker:Cancel()
        end
        smokeBombCast = GetTime()
        smokeTracker = C_Timer.NewTimer(5, function()
            smokeBombCast = 0
        end)
    end
end

MountAuraTooltip = CreateFrame("GameTooltip", "MountAuraTooltip", nil, "GameTooltipTemplate")
MountAuraTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
local function isMountAura(spellId)
    MountAuraTooltip:ClearLines()
    MountAuraTooltip:SetHyperlink("spell:" .. spellId)
    local thirdLineText = _G["MountAuraTooltipTextLeft3"]:GetText()
    if thirdLineText and thirdLineText:find("Summons and dismisses a rideable") then
        return true
    end
    return false
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


local printSpellId
local betterTargetPurgeGlow
local betterFocusPurgeGlow
local userEnlargedAuraSize = 1
local userCompactedAuraSize = 1
local userPurgeableAuraSize = 1
local auraSpacingX = 4
local auraSpacingY = 4
local aurasPerRow = 5
local targetAndFocusAuraOffsetY = 0
local baseOffsetX = 5--25
local baseOffsetY = 16--12.5
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
local enlargedTextureAdjustment = 5
local compactedTextureAdjustment = 5
local purgeableTextureAdjustment = 5
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
local playerAuraBuffScale
local playerAuraXOffset
local playerAuraYOffset
local maxPlayerAurasPerRow
local customPurgeSize
local enlargedTextureAdjustmentSmall = 1
local compactedTextureAdjustmentSmall = 1
local purgeableTextureAdjustmentSmall = 1
local purgeableAuraSize = 1
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
local targetAuraGlows
local focusAuraGlows

local function UpdateMore()
    purgeableBuffSorting = BetterBlizzFramesDB.purgeableBuffSorting
    purgeableBuffSortingFirst = BetterBlizzFramesDB.purgeableBuffSortingFirst
    playerAuraBuffScale = BetterBlizzFramesDB.playerAuraBuffScale
    playerAuraXOffset = BetterBlizzFramesDB.playerAuraXOffset
    playerAuraYOffset = BetterBlizzFramesDB.playerAuraYOffset
    maxPlayerAurasPerRow = BetterBlizzFramesDB.maxPlayerAurasPerRow
    onlyPandemicMine = BetterBlizzFramesDB.onlyPandemicAuraMine
    buffsOnTopReverseCastbarMovement = BetterBlizzFramesDB.buffsOnTopReverseCastbarMovement
    customPurgeSize = BetterBlizzFramesDB.customPurgeSize
    enlargedTextureAdjustmentSmall = 20 * userEnlargedAuraSize
    compactedTextureAdjustmentSmall = 20 * userCompactedAuraSize
    purgeableAuraSize = BetterBlizzFramesDB.purgeableAuraSize
    purgeableTextureAdjustment = 20 * purgeableAuraSize
    purgeableTextureAdjustmentSmall = 20 * purgeableAuraSize
    targetEnlargeAuraEnemy = BetterBlizzFramesDB.targetEnlargeAuraEnemy
    targetEnlargeAuraFriendly = BetterBlizzFramesDB.targetEnlargeAuraFriendly
    focusEnlargeAuraEnemy = BetterBlizzFramesDB.focusEnlargeAuraEnemy
    focusEnlargeAuraFriendly = BetterBlizzFramesDB.focusEnlargeAuraFriendly
    increaseAuraStrata = BetterBlizzFramesDB.increaseAuraStrata
    sameSizeAuras = BetterBlizzFramesDB.sameSizeAuras
    auraStackSize = BetterBlizzFramesDB.auraStackSize
    addCooldownFramePlayerBuffs = BetterBlizzFramesDB.addCooldownFramePlayerBuffs
    addCooldownFramePlayerDebuffs = BetterBlizzFramesDB.addCooldownFramePlayerDebuffs
    hideDefaultPlayerAuraDuration = BetterBlizzFramesDB.hideDefaultPlayerAuraDuration
    hideDefaultPlayerAuraCdText = BetterBlizzFramesDB.hideDefaultPlayerAuraCdText
    targetAuraGlows = BetterBlizzFramesDB.targetAuraGlows
    focusAuraGlows = BetterBlizzFramesDB.focusAuraGlows
    clickthroughAuras = BetterBlizzFramesDB.clickthroughAuras

    if BetterBlizzFramesDB.targetdeBuffFilterBlizzard or BetterBlizzFramesDB.focusdeBuffFilterBlizzard then
        BetterBlizzFramesDB.targetdeBuffFilterBlizzard = false
        BetterBlizzFramesDB.focusdeBuffFilterBlizzard = false
    end
end

function BBF.UpdateUserAuraSettings()
    printSpellId = BetterBlizzFramesDB.printAuraSpellIds
    betterTargetPurgeGlow = BetterBlizzFramesDB.targetBuffPurgeGlow
    betterFocusPurgeGlow = BetterBlizzFramesDB.focusBuffPurgeGlow
    userEnlargedAuraSize = BetterBlizzFramesDB.enlargedAuraSize
    userCompactedAuraSize = BetterBlizzFramesDB.compactedAuraSize
    userPurgeableAuraSize = BetterBlizzFramesDB.purgeableAuraSize
    auraSpacingX = BetterBlizzFramesDB.targetAndFocusHorizontalGap
    auraSpacingY = BetterBlizzFramesDB.targetAndFocusVerticalGap
    aurasPerRow = BetterBlizzFramesDB.targetAndFocusAurasPerRow
    targetAndFocusAuraOffsetY = BetterBlizzFramesDB.targetAndFocusAuraOffsetY
    baseOffsetX = 5 + BetterBlizzFramesDB.targetAndFocusAuraOffsetX
    baseOffsetY = 16 + BetterBlizzFramesDB.targetAndFocusAuraOffsetY
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
    enlargedTextureAdjustment = 23 * userEnlargedAuraSize
    compactedTextureAdjustment = 23 * userCompactedAuraSize
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
    if not spellId then return false end
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
            local filterOnlyMe = db["targetBuffFilterOnlyMe"] and isTargetFriendly and (caster == "player" or (caster == "pet" and UnitIsUnit(caster, "pet")))
            if filterOverride then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if shouldBlacklist then
                local isInBlacklist, allowMine = isInBlacklist(spellName, spellId)
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
            local filterOnlyMe = db["targetdeBuffFilterOnlyMe"] and (caster == "player" or (caster == "pet" and UnitIsUnit(caster, "pet")))
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
            local filterOnlyMe = db["focusBuffFilterOnlyMe"] and isTargetFriendly and (caster == "player" or (caster == "pet" and UnitIsUnit(caster, "pet")))
            if filterOverride then return true, isImportant, isPandemic, isEnlarged, isCompacted, auraColor end
            if shouldBlacklist then
                local isInBlacklist, allowMine = isInBlacklist(spellName, spellId)
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
            local filterOnlyMe = db["focusdeBuffFilterOnlyMe"] and (caster == "player" or (caster == "pet" and UnitIsUnit(caster, "pet")))
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
    local noAuras = #rowHeights == 0

    meta.ClearAllPoints(self)
    if frame == TargetFrameSpellBar then
        local buffsOnTop = parent.buffsOnTop
        local yOffset = 23 / targetCastBarScale
        local xOffset = 24
        if targetStaticCastbar then
            --meta.SetPoint(self, "TOPLEFT", meta.GetParent(self), "BOTTOMLEFT", 43, 110);
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", xOffset + targetCastBarXPos, -14 + targetCastBarYPos);
        elseif targetDetachCastbar then
            meta.SetPoint(self, "CENTER", parent, "CENTER", targetCastBarXPos, targetCastBarYPos);
        elseif buffsOnTopReverseCastbarMovement and buffsOnTop then
            yOffset = yOffset + CalculateAuraRowsYOffset(parent, rowHeights, auraScale) + (80*auraScale)
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", xOffset + targetCastBarXPos, yOffset + targetCastBarYPos);
        else
            if not buffsOnTop then
                yOffset = yOffset - CalculateAuraRowsYOffset(parent, rowHeights, targetCastBarScale)
                if noAuras then
                    yOffset = yOffset - 13
                end
            else
                yOffset = yOffset - 10
            end
            -- Check if totAdjustment is true and the ToT frame is shown
            if targetToTCastbarAdjustment and parent.haveToT then
                local minOffset = -40
                -- Choose the more negative value
                yOffset = min(minOffset, yOffset)
                yOffset = yOffset + targetToTAdjustmentOffsetY
            end

            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", xOffset + targetCastBarXPos, yOffset + targetCastBarYPos);
        end
    elseif frame == FocusFrameSpellBar then
        local buffsOnTop = parent.buffsOnTop
        local yOffset = 23 / focusCastBarScale
        local xOffset = 24
        if focusStaticCastbar then
            --meta.SetPoint(self, "TOPLEFT", meta.GetParent(self), "BOTTOMLEFT", 43, 110);
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", xOffset + focusCastBarXPos, -14 + focusCastBarYPos);
        elseif focusDetachCastbar then
            meta.SetPoint(self, "CENTER", parent, "CENTER", focusCastBarXPos, focusCastBarYPos);
        elseif buffsOnTopReverseCastbarMovement and buffsOnTop then
            yOffset = yOffset + CalculateAuraRowsYOffset(parent, rowHeights, auraScale) + (80*auraScale)
            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", xOffset + focusCastBarXPos, yOffset + focusCastBarYPos);
        else
            if not buffsOnTop then
                yOffset = yOffset - CalculateAuraRowsYOffset(parent, rowHeights, focusCastBarScale)
                if noAuras then
                    yOffset = yOffset - 13
                end
            else
                yOffset = yOffset - 10
            end
            -- Check if totAdjustment is true and the ToT frame is shown
            if focusToTCastbarAdjustment and parent.haveToT then
                local minOffset = -40
                -- Choose the more negative value
                yOffset = min(minOffset, yOffset)
                yOffset = yOffset + focusToTAdjustmentOffsetY
            end

            meta.SetPoint(self, "TOPLEFT", parent, "BOTTOMLEFT", xOffset + focusCastBarXPos, yOffset + focusCastBarYPos);
        end
    end
end

local function DefaultCastbarAdjustment(self, frame)
    local meta = getmetatable(self).__index
    local parentFrame = meta.GetParent(self)

    -- Determine whether to use the adjusted logic based on BetterBlizzFramesDB setting
    local useSpellbarAnchor =   (buffsOnTopReverseCastbarMovement and parentFrame.buffsOnTop) and ((parentFrame.haveToT and parentFrame.auraRows > 0) or
                                (not parentFrame.haveToT and parentFrame.auraRows > 0)) or
                                (not parentFrame.buffsOnTop and ((parentFrame.haveToT and parentFrame.auraRows > 2) or
                                (not parentFrame.haveToT and parentFrame.auraRows > 0)))

    local relativeKey = useSpellbarAnchor and parentFrame.spellbarAnchor or parentFrame
    local pointX = 21--useSpellbarAnchor and 18 or (parentFrame.smallSize and 38 or 43)
    local pointY = useSpellbarAnchor and -10 or (parentFrame.smallSize and 3 or 5)

    -- Adjustments for ToT and specific frame adjustments
    if (not useSpellbarAnchor) and parentFrame.haveToT and not (buffsOnTopReverseCastbarMovement and parentFrame.buffsOnTop) then
        local totAdjustment = ((frame == TargetFrameSpellBar and targetToTCastbarAdjustment) or (frame == FocusFrameSpellBar and focusToTCastbarAdjustment))
        if totAdjustment then
            pointY = parentFrame.smallSize and -48 or -23
            if frame == TargetFrameSpellBar then
                pointY = pointY + targetToTAdjustmentOffsetY
            elseif frame == FocusFrameSpellBar then
                pointY = pointY + focusToTAdjustmentOffsetY
            end
        end
    end

    if not useSpellbarAnchor then
        pointX = pointX + 5
    end

    if frame == TargetFrameSpellBar then
        pointX = pointX + targetCastBarXPos
        pointY = pointY + targetCastBarYPos
    elseif frame == FocusFrameSpellBar then
        pointX = pointX + focusCastBarXPos
        pointY = pointY + focusCastBarYPos
    end

    -- Apply setting-specific adjustment
    if buffsOnTopReverseCastbarMovement and parentFrame.buffsOnTop then
        local extraOffset = parentFrame.auraRows == 0 and 120 or 30
        meta.SetPoint(self, "TOPLEFT", relativeKey, "BOTTOMLEFT", pointX, -pointY + extraOffset)
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

local function CheckBuffs()
    local currentGameTime = GetTime()
    for auraInstanceID, aura in pairs(trackedBuffs) do
        if aura.isPandemic and aura.expirationTime then
            local remainingDuration = aura.expirationTime - currentGameTime
            if remainingDuration <= 0 then
                aura.isPandemic = false
                trackedBuffs[auraInstanceID] = nil
                if aura.PandemicGlow then
                    aura.PandemicGlow:Hide()
                end
                if aura.ImportantGlow then
                    aura.ImportantGlow:SetAlpha(1)
                end
                aura.isPandemicActive = false
            elseif remainingDuration <= 5.1 then
                if not aura.PandemicGlow then
                    aura.PandemicGlow = aura.GlowFrame:CreateTexture(nil, "OVERLAY");
                    aura.PandemicGlow:SetTexture(BBF.squareGreenGlow);
                    aura.PandemicGlow:SetDesaturated(true)
                    aura.PandemicGlow:SetVertexColor(1, 0, 0)
                end
                local texAdjust = aura.isEnlarged and enlargedTextureAdjustment or compactedTextureAdjustment
                local texAdjustSmall = aura.isEnlarged and enlargedTextureAdjustmentSmall or compactedTextureAdjustmentSmall
                if aura.isEnlarged or aura.isCompacted then
                    if aura.isLarge then
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -texAdjust, texAdjust)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", texAdjust, -texAdjust)
                    else
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -texAdjustSmall, texAdjustSmall)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", texAdjustSmall, -texAdjustSmall)
                    end
                else
                    if aura.isLarge then
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -24, 25)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 24, -24)
                    else
                        aura.PandemicGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -18, 18)
                        aura.PandemicGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 18, -18)
                    end
                end

                aura.isPandemicActive = true
                aura.PandemicGlow:Show();
                if aura.ImportantGlow then
                    aura.ImportantGlow:SetAlpha(0)
                end
                if aura.Border then
                    aura.Border:SetAlpha(0)
                end
            else
                if aura.PandemicGlow then
                    aura.PandemicGlow:Hide();
                end
                if aura.ImportantGlow then
                    aura.ImportantGlow:SetAlpha(1)
                end
                aura.isPandemicActive = false
            end
        else
            aura.isPandemicActive = false
            if aura.Border and not aura.isImportant and not aura.isPurgeGlow then
                aura.Border:SetAlpha(1)
            end
            if aura.border and not aura.isImportant and not aura.isPurgeGlow then
                aura.border:SetAlpha(1)
            end
            if aura.ImportantGlow then
                aura.ImportantGlow:SetAlpha(1)
            end
            for auraInstanceID, _ in pairs(trackedBuffs) do
                trackedBuffs[auraInstanceID] = nil
            end
        end
    end
    if next(trackedBuffs) == nil then
        StopCheckBuffsTimer();
    end
end

local function StartCheckBuffsTimer()
    if not checkBuffsTimer then
        CheckBuffs()
        checkBuffsTimer = C_Timer.NewTicker(0.1, CheckBuffs);
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

local function getCustomAuraComparator()
    if purgeableBuffSorting then
        if purgeableBuffSortingFirst then
            return purgeableFirstComparator
        else
            return purgeableAfterImportantAndEnlargedComparator
        end
    end
    return getCustomAuraComparatorWithoutPurgeable()
end

local spammyAuras = {
    [51701] = "Honor Among Thieves",
    [51699] = "Honor Among Thieves",
    [51698] = "Honor Among Thieves",
    [51700] = "Honor Among Thieves",
    --

}

local function getSpammyGroup(spellId)
    return spammyAuras[spellId]
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

local function AdjustCastbarAfterAuras(unit)
    if unit == "target" then
        if (not targetStaticCastbar and not targetDetachCastbar) then
            adjustCastbar(TargetFrame.spellbar, TargetFrameSpellBar)
        end
    elseif unit == "focus" then
        if (not focusStaticCastbar and not focusDetachCastbar) then
            adjustCastbar(FocusFrame.spellbar, FocusFrameSpellBar)
        end
    end
end

local function AdjustAuras(self, frameType)
    local adjustedSize = sameSizeAuras and 21 or 17 * targetAndFocusSmallAuraScale
    local buffsOnTop = self.buffsOnTop

    local initialOffsetX = (baseOffsetX / auraScale)
    local initialOffsetY = (baseOffsetY / auraScale)

    local function adjustAuraPosition(auras, yOffset, buffsOnTop)
        local adjustmentForBuffsOnTop = -80
        local currentYOffset = yOffset + (buffsOnTop and -((initialOffsetY + adjustmentForBuffsOnTop)/auraScale) or initialOffsetY)
        local rowWidths, rowHeights = {}, {}

        for i, aura in ipairs(auras) do
            aura:SetScale(auraScale)
            local auraSize = aura:GetHeight()
            -- if not aura.isLarge then
            --     aura:SetSize(adjustedSize, adjustedSize)
            --     if aura.ImportantGlow then
            --         aura.ImportantGlow:SetScale(targetAndFocusSmallAuraScale)
            --     end
            --     if aura.PandemicGlow then
            --         aura.PandemicGlow:SetScale(targetAndFocusSmallAuraScale)
            --     end
            --     if not customPurgeSize then
            --         if aura.PurgeGlow then
            --             aura.PurgeGlow:SetScale(targetAndFocusSmallAuraScale)
            --         end
            --         if aura.Stealable then
            --             aura.Stealable:SetScale(targetAndFocusSmallAuraScale)
            --         end
            --     end
            --     if aura.Border then
            --         aura.Border:SetScale(targetAndFocusSmallAuraScale)
            --     end
            --     auraSize = adjustedSize
            -- end

            if aura.isEnlarged or aura.isCompacted then
                local sizeMultiplier = aura.isEnlarged and userEnlargedAuraSize or userCompactedAuraSize
                local texAdjust = aura.isEnlarged and enlargedTextureAdjustment or compactedTextureAdjustment
                local texAdjustSmall = aura.isEnlarged and enlargedTextureAdjustmentSmall or compactedTextureAdjustmentSmall
                local defaultLargeAuraSize = aura.isLarge and 21 or 17
                local importantSize = defaultLargeAuraSize * sizeMultiplier
                aura:SetSize(importantSize, importantSize)
                if aura.isImportant then
                    if aura.isLarge or sameSizeAuras then
                        aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -texAdjust, texAdjust)
                        aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", texAdjust, -texAdjust)
                    else
                        aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -texAdjustSmall, texAdjustSmall)
                        aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", texAdjustSmall, -texAdjustSmall)
                    end
                end
                if aura.isPurgeable then
                    local scale = aura.isEnlarged and userEnlargedAuraSize or userCompactedAuraSize
                    if aura.Stealable then
                        aura.Stealable:SetScale(scale)
                    end
                    if aura.PurgeGlow then
                        if aura.isLarge or sameSizeAuras then
                            aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -texAdjust, texAdjust)
                            aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", texAdjust, -texAdjust)
                        else
                            aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -texAdjustSmall, texAdjustSmall)
                            aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", texAdjustSmall, -texAdjustSmall)
                        end
                    end
                end
                auraSize = importantSize
            elseif aura.isPurgeable and customPurgeSize then
                local sizeMultiplier = userPurgeableAuraSize
                local defaultLargeAuraSize = aura.isLarge and 21 or 17
                local purgeableSize = defaultLargeAuraSize * sizeMultiplier
                aura:SetSize(purgeableSize, purgeableSize)
                if aura.isImportant then
                    if aura.isLarge or sameSizeAuras then
                        aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -purgeableTextureAdjustment, purgeableTextureAdjustment)
                        aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", purgeableTextureAdjustment, -purgeableTextureAdjustment)
                    else
                        aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -purgeableTextureAdjustmentSmall, purgeableTextureAdjustmentSmall)
                        aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", purgeableTextureAdjustmentSmall, -purgeableTextureAdjustmentSmall)
                    end
                end
                auraSize = purgeableSize
                if aura.PurgeGlow then
                    if aura.isLarge or sameSizeAuras then
                        aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -purgeableTextureAdjustment, purgeableTextureAdjustment)
                        aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", purgeableTextureAdjustment, -purgeableTextureAdjustment)
                    else
                        aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -purgeableTextureAdjustmentSmall, purgeableTextureAdjustmentSmall)
                        aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", purgeableTextureAdjustmentSmall, -purgeableTextureAdjustmentSmall)
                    end
                else
                    if aura.Stealable then
                        aura.Stealable:SetScale(purgeableAuraSize)
                    end
                end
            elseif not aura.isLarge then
                aura:SetSize(adjustedSize, adjustedSize)
                if aura.isPurgeable then
                    if aura.Stealable then
                        aura.Stealable:SetScale(targetAndFocusSmallAuraScale)
                    end
                end
                if sameSizeAuras then
                    if aura.isImportant then
                        aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -25.5, 25.5)
                        aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 25.5, -26)
                    end
                    if aura.PurgeGlow then
                        aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -24, 24)
                        aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 24, -24)
                    end
                else
                    if aura.isHarmful then
                        if aura.isImportant then
                            aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -22.5, 22)
                            aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 22.5, -22.5)
                        end
                        if aura.PurgeGlow then
                            aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -22.5, 22)
                            aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 22.5, -22.5)
                        end
                    else
                        if aura.isImportant then
                            aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -20, 20)
                            aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 20, -20)
                        end
                        if aura.PurgeGlow then
                            aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -20, 20)
                            aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 20, -20)
                        end
                    end
                end
                auraSize = adjustedSize
            else
                if aura.isImportant then
                    aura.ImportantGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -25.5, 25.5)
                    aura.ImportantGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 25.5, -26)
                end
                if aura.PurgeGlow then
                    aura.PurgeGlow:SetPoint("TOPLEFT", aura, "TOPLEFT", -24, 24)
                    aura.PurgeGlow:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 24, -24)
                end
            end

            if aura.Count then
                aura.Count:SetScale(auraStackSize)
            end

            local columnIndex, rowIndex
            columnIndex = (i - 1) % aurasPerRow
            rowIndex = math.ceil(i / aurasPerRow)

            rowWidths[rowIndex] = rowWidths[rowIndex] or initialOffsetX

            if columnIndex == 0 and i ~= 1 then
                if buffsOnTop then
                    currentYOffset = currentYOffset + (rowHeights[rowIndex - 1] or 0) + auraSpacingY
                else
                    currentYOffset = currentYOffset - (rowHeights[rowIndex - 1] or 0) - auraSpacingY
                end
            elseif columnIndex ~= 0 then
                rowWidths[rowIndex] = rowWidths[rowIndex] + auraSpacingX
            end

            local offsetX = rowWidths[rowIndex]
            rowHeights[rowIndex] = math.max(auraSize, (rowHeights[rowIndex] or 0))
            rowWidths[rowIndex] = offsetX + auraSize

            aura:ClearAllPoints()
            if buffsOnTop then
                aura:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", offsetX, (currentYOffset + initialOffsetY))
            else
                aura:SetPoint("TOPLEFT", self, "BOTTOMLEFT", offsetX, currentYOffset + initialOffsetY)
            end
        end

        return rowHeights
    end

    local unit = self.unit
    local isFriend = unit and not UnitCanAttack("player", unit)

    local buffs, debuffs = {}, {}
    local addedGroups = {}

    local auraGlowsEnabled = (frameType == "target" and targetAuraGlows) or (frameType == "focus" and focusAuraGlows)

    local function UpdateAuraFrames(self, unit, isBuff)
        local maxAuras = isBuff and MAX_TARGET_BUFFS or 60
        local auraType = isBuff and "Buff" or "Debuff"

        for i = 1, maxAuras do
            local auraName = self:GetName()..auraType..i
            local stealable = _G[auraName.."Stealable"]
            local cooldown = _G[auraName.."Cooldown"]
            local count = _G[auraName.."Count"]
            local icon = _G[auraName.."Icon"]

            local auraFrame = _G[auraName]
            if auraFrame and auraFrame:IsShown() then
                if increaseAuraStrata then
                    auraFrame:SetFrameStrata("HIGH")
                end

                -- if MasqueUnitFrameAuras and not auraFrame.added then
                --     MasqueUnitFrameAuras:AddButton(auraFrame)
                --     auraFrame.added = true
                -- end
                auraFrame.Icon = icon
                auraFrame.Stealable = stealable
                auraFrame.Cooldown = cooldown
                auraFrame.Count = count

                if auraFrame.Cooldown:IsShown() then
                    auraFrame.Count:SetParent(auraFrame.Cooldown)
                else
                    auraFrame.Count:SetParent(auraFrame)
                end

                local spellName, icon, count, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, canApplyAura
                if isBuff then
                    spellName, icon, count, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, canApplyAura = UnitBuff(unit, i)
                else
                    spellName, icon, count, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, canApplyAura = UnitDebuff(unit, i)
                end


                auraFrame.spellId = spellId
                auraFrame.auraInstanceID = i

                if spellId == 88611 then
                    auraFrame.Cooldown:SetCooldown(smokeBombCast, 5)
                end

                local auraData = {
                    sourceUnit = sourceUnit,
                    canApplyAura = canApplyAura,
                    isStealable = isStealable,
                    dispelName = dispelName,
                    isHelpful = isBuff,
                    isHarmful = not isBuff,
                    spellId = spellId,
                    expirationTime = expirationTime,
                    icon = icon,
                    name = spellName,
                    duration = duration,
                }

                local isLarge = auraData.sourceUnit == "player" or auraData.sourceUnit == "pet"
                local canApply = auraData.canApplyAura or false

                auraFrame.isLarge = isLarge
                auraFrame.canApply = canApply
                auraFrame.isHelpful = isBuff
                auraFrame.isHarmful = not isBuff
                --auraFrame.isStealable = stealable

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
                    auraFrame:Show()

                    if (auraData.isStealable or (auraData.dispelName == "Magic" and ((not isFriend and auraData.isHelpful) or (isFriend and auraData.isHarmful)))) then
                        auraFrame.isPurgeable = true
                        if BBF.hasExtraPurge then
                            auraData.isStealable = true
                        end
                    else
                        auraFrame.isPurgeable = false
                    end

                    -- auraFrame.isPurgeable = auraData.isStealable

                    if clickthroughAuras then
                        auraFrame:SetMouseClickEnabled(false)
                    else
                        SetupAuraFilterClicks(auraFrame)
                    end

                    if printSpellId and not auraFrame.bbfHookAdded then
                        auraFrame.bbfHookAdded = true
                        auraFrame:HookScript("OnEnter", function()
                            local currentAuraIndex = auraFrame.auraInstanceID
                            local name, icon, count, dispelType, duration, expirationTime, source,
                                isStealable, nameplateShowPersonal, spellId, canApplyAura,
                                isBossDebuff, castByPlayer, nameplateShowAll, timeMod
                                = UnitAura("player", currentAuraIndex, auraFrame.isHelpful and "HELPFUL" or "HARMFUL");

                            if name and (not auraFrame.bbfPrinted or auraFrame.bbfLastPrintedAuraIndex ~= currentAuraIndex) then
                                local iconTexture = icon and "|T" .. icon .. ":16:16|t" or ""
                                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconTexture .. " " .. (name or "Unknown") .. "  |A:worldquest-icon-engineering:14:14|a ID: " .. (spellId or "Unknown"))
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

                    if isEnlarged then
                        auraFrame.isEnlarged = true
                    else
                        auraFrame.isEnlarged = false
                    end
    
                    if isCompacted then
                        auraFrame.isCompacted = true
                    else
                        auraFrame.isCompacted = false
                    end
    
                    -- if auraFrame.Stealable and auraFrame.Stealable:IsShown() then
                    --     auraFrame.Stealable:SetScale(userPurgeableAuraSize)
                    --     print("setting size")
                    -- end
    
                    --stealableTexture:SetScale(3)
    
                    if not auraFrame.GlowFrame then
                        auraFrame.GlowFrame = CreateFrame("Frame", nil, auraFrame)
                        auraFrame.GlowFrame:SetAllPoints(auraFrame)
                        auraFrame.GlowFrame:SetFrameLevel(auraFrame:GetFrameLevel() + 1)  -- Ensure it's above the cooldown texture
                    end
    
                    if isImportant then
                        auraFrame.isImportant = true
                        if not auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow = auraFrame.GlowFrame:CreateTexture(nil, "OVERLAY")
                            auraFrame.ImportantGlow:SetTexture(BBF.squareGreenGlow)
                            auraFrame.ImportantGlow:SetDesaturated(true)
                        end
                        -- if auraFrame.isEnlarged then
                        --     auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -enlargedTextureAdjustment, enlargedTextureAdjustment)
                        --     auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", enlargedTextureAdjustment, -enlargedTextureAdjustment)
                        -- elseif auraFrame.isCompacted then
                        --     auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -compactedTextureAdjustment, compactedTextureAdjustment)
                        --     auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", compactedTextureAdjustment, -compactedTextureAdjustment)
                        -- else
                        --     auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -23, 23)
                        --     auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 23, -23)
                        -- end
                        if auraColor then
                            auraFrame.ImportantGlow:SetVertexColor(auraColor[1], auraColor[2], auraColor[3], auraColor[4])
                        else
                            auraFrame.ImportantGlow:SetVertexColor(0, 1, 0)
                        end
                        auraFrame.ImportantGlow:Show()
                    else
                        auraFrame.isImportant = false
                        if auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow:Hide()
                            if auraFrame.Stealable and auraData.isStealable then
                                auraFrame.Stealable:SetAlpha(1)
                            end
                        end
                    end
    
                    -- if auraFrame.Stealable and auraFrame.Stealable:IsShown() then
                    --     if auraFrame.isEnlarged then
                    --         auraFrame.Stealable:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -3, 4)
                    --         auraFrame.Stealable:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 3, -3)
                    --     elseif auraFrame.isCompacted then
                    --         auraFrame.Stealable:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -compactedTextureAdjustment, compactedTextureAdjustment)
                    --         auraFrame.Stealable:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", compactedTextureAdjustment, -compactedTextureAdjustment)
                    --     else
                    --         auraFrame.Stealable:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -2, 2)
                    --         auraFrame.Stealable:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 2, -2)
                    --     end
                    -- end
    
                    if (frameType == "target" and (auraData.isStealable or (displayDispelGlowAlways and auraFrame.isPurgeable)) and betterTargetPurgeGlow) or
                    (frameType == "focus" and (auraData.isStealable or (displayDispelGlowAlways and auraFrame.isPurgeable)) and betterFocusPurgeGlow) then
                        if not auraFrame.PurgeGlow then
                            auraFrame.PurgeGlow = auraFrame.GlowFrame:CreateTexture(nil, "OVERLAY")
                            auraFrame.PurgeGlow:SetTexture(BBF.squareBlueGlow)
                            auraFrame.PurgeGlow:SetDesaturated(true)
                            auraFrame.PurgeGlow:SetVertexColor(0.27, 0.858, 1)
                        end
                        -- if auraFrame.isEnlarged then
                        --     auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -enlargedTextureAdjustment, enlargedTextureAdjustment)
                        --     auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", enlargedTextureAdjustment, -enlargedTextureAdjustment)
                        --     -- auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -enlargedPurgeTextureAdjustment, enlargedPurgeTextureAdjustment)
                        --     -- auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", enlargedPurgeTextureAdjustment, -enlargedPurgeTextureAdjustment)
                        -- elseif auraFrame.isCompacted then
                        --     auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -compactedTextureAdjustment, compactedTextureAdjustment)
                        --     auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", compactedTextureAdjustment, -compactedTextureAdjustment)
                        -- else
                        --     if customPurgeSize then
                        --         auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -purgeableTextureAdjustment, purgeableTextureAdjustment)
                        --         auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", purgeableTextureAdjustment, -purgeableTextureAdjustment)
                        --     else
                        --         auraFrame.PurgeGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -22, 22)
                        --         auraFrame.PurgeGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 22, -22)
                        --     end
                        -- end
                        auraFrame.isPurgeGlow = true
                        if changePurgeTextureColor then
                            auraFrame.PurgeGlow:SetDesaturated(true)
                            auraFrame.PurgeGlow:SetVertexColor(unpack(purgeTextureColorRGB))
                        end
                        auraFrame.PurgeGlow:Show()
                    else
                        if auraFrame.PurgeGlow then
                            if auraFrame.Stealable and auraData.isStealable then
                                auraFrame.Stealable:SetAlpha(1)
                            end
                            auraFrame.PurgeGlow:Hide()
                        end
                        auraFrame.isPurgeGlow = false
                        if displayDispelGlowAlways then
                            if auraFrame.isPurgeable then
                                if auraFrame.Stealable then
                                    auraFrame.Stealable:Show()
                                    if changePurgeTextureColor then
                                        auraFrame.Stealable:SetVertexColor(unpack(purgeTextureColorRGB))
                                    end
                                end
                            else
                                if auraFrame.Stealable then
                                    auraFrame.Stealable:Hide()
                                end
                            end
                        else
                            if changePurgeTextureColor and auraFrame.Stealable then
                                auraFrame.Stealable:SetDesaturated(true)
                                auraFrame.Stealable:SetVertexColor(unpack(purgeTextureColorRGB))
                            end
                            if auraFrame.isPurgeable and BBF.hasExtraPurge then
                                auraFrame.Stealable:Show()
                            end
                        end
                    end

                    if isPandemic then
                        auraFrame.expirationTime = auraData.expirationTime
                        auraFrame.isPandemic = true
                        trackedBuffs[auraFrame.auraInstanceID] = auraFrame
                        StartCheckBuffsTimer()
                    else
                        auraFrame.isPandemic = false
                        if auraFrame.PandemicGlow then
                            auraFrame.PandemicGlow:Hide()
                        end
                    end
    
                    if auraFrame.isImportant or auraFrame.isPurgeGlow or (auraFrame.isPandemicActive and isPandemic) then
                        if auraFrame.border then
                            auraFrame.border:SetAlpha(0)
                        end
                        if auraFrame.Border then
                            auraFrame.Border:SetAlpha(0)
                        end
                        if auraFrame.Stealable then
                            auraFrame.Stealable:SetAlpha(0)
                        end
                    else
                        if auraFrame.border then
                            auraFrame.border:SetAlpha(1)
                        end
                        if auraFrame.Border then
                            auraFrame.Border:SetAlpha(1)
                        end
                        if auraFrame.Stealable then
                            auraFrame.Stealable:SetAlpha(1)
                        end
                    end
    
                    -- if auraFrame.Border ~= nil then
                    --     debuffs[#debuffs + 1] = auraFrame
                    -- else
                        if isBuff then
                            local groupName = getSpammyGroup(spellId)
                            if groupName then
                                if addedGroups[groupName] then
                                    auraFrame:Hide()
                                else
                                    addedGroups[groupName] = true
                                    buffs[#buffs + 1] = auraFrame
                                end
                            else
                                buffs[#buffs + 1] = auraFrame
                            end
                        else
                            debuffs[#debuffs + 1] = auraFrame
                        end

                    --end
                else
                    auraFrame:Hide()
                    if auraFrame.PandemicGlow then
                        auraFrame.PandemicGlow:Hide()
                    end
                end
            else
                break
            end
        end
    end

    UpdateAuraFrames(self, unit, true)
    UpdateAuraFrames(self, unit, false)


    local customAuraComparator = getCustomAuraComparator()
    table.sort(buffs, customAuraComparator)
    table.sort(debuffs, customAuraComparator)

    if not isFriend then
        if buffsOnTop then
            self.rowHeights = adjustAuraPosition(debuffs, targetAndFocusAuraOffsetY, buffsOnTop)
            local totalDebuffHeight = sum(self.rowHeights)

            local yOffsetForBuffs = totalDebuffHeight + (auraSpacingY * #self.rowHeights) + targetAndFocusAuraOffsetY
            if #debuffs > 0 then
                yOffsetForBuffs = yOffsetForBuffs + 5 + auraTypeGap
            end

            local buffRowHeights = adjustAuraPosition(buffs, yOffsetForBuffs, buffsOnTop)
            if #buffs > 0 and #debuffs > 0 then
                self.rowHeights[#self.rowHeights] = self.rowHeights[#self.rowHeights] + auraTypeGap
            end
            for _, height in ipairs(buffRowHeights) do
                table.insert(self.rowHeights, height)
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
                table.insert(self.rowHeights, height)
            end
        end
    else
        if buffsOnTop then
            self.rowHeights = adjustAuraPosition(buffs, targetAndFocusAuraOffsetY, buffsOnTop)
            local totalBuffHeight = sum(self.rowHeights)

            local yOffsetForDebuffs = totalBuffHeight + (auraSpacingY * #self.rowHeights) + targetAndFocusAuraOffsetY
            if #buffs > 0 then
                yOffsetForDebuffs = yOffsetForDebuffs + 5 + auraTypeGap
            end

            local debuffRowHeights = adjustAuraPosition(debuffs, yOffsetForDebuffs, buffsOnTop)
            if #buffs > 0 and #debuffs > 0 then
                self.rowHeights[#self.rowHeights] = self.rowHeights[#self.rowHeights] + auraTypeGap
            end
            for _, height in ipairs(debuffRowHeights) do
                table.insert(self.rowHeights, height)
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
                table.insert(self.rowHeights, height)
            end
        end
    end

    -- Adjust castbar position if needed
    AdjustCastbarAfterAuras(unit)
    addMasque(frameType)
end

-- Function to create the toggle icon
local toggleIconGlobal = nil
local shouldKeepAurasVisible = false
local hiddenAuras = 0
local keepIcon = false
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
        elseif hiddenAuras == 0 and not keepIcon then
            toggleIconGlobal:Hide()
        else
            toggleIconGlobal.hiddenAurasCount:SetPoint("CENTER", ToggleHiddenAurasButton, "CENTER", 0, 0)
        end
    end
end

local function ResetHiddenAurasCount(keepTrack)
    hiddenAuras = 0
    UpdateHiddenAurasCount()
end

-- Functions to show and hide the hidden auras
local function ShowHiddenAuras(bypass)
    if ToggleHiddenAurasButton.isDropdownExpanded or bypass then
        for i = 1, 40 do
            local buffName = "BuffButton"..i
            local auraFrame = _G[buffName]

        --for _, auraFrame in ipairs(BuffFrame.auraFrames) do
            if auraFrame and auraFrame.isAuraHidden then
                auraFrame:Show()
            end
        end
        for i = 1, BuffFrame.numEnchants do
            local buffName = "TempEnchant"..i
            local auraFrame = _G[buffName]

        --for _, auraFrame in ipairs(BuffFrame.auraFrames) do
            if auraFrame and auraFrame.isAuraHidden then
                auraFrame:Show()
            end
        end
    end
end

local function HideHiddenAuras()
    if not shouldKeepAurasVisible then
        for i = 1, MAX_TARGET_BUFFS do
            local buffName = "BuffButton"..i
            local auraFrame = _G[buffName]
        --for _, auraFrame in ipairs(BuffFrame.auraFrames) do
            if auraFrame and auraFrame.isAuraHidden then
                auraFrame:Hide()
            end
        end
        for i = 1, BuffFrame.numEnchants do
            local buffName = "TempEnchant"..i
            local auraFrame = _G[buffName]
            
        --for _, auraFrame in ipairs(BuffFrame.auraFrames) do
            if auraFrame and auraFrame.isAuraHidden then
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
    local currentAuraSize = 1--BuffFrame.AuraContainer.iconScale
    local addIconsToRight = false--BuffFrame.AuraContainer.addIconsToRight or false
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
        toggleIcon:SetPoint("TOPLEFT", BuffFrame, "TOPRIGHT", 2 + BetterBlizzFramesDB.playerAuraSpacingX, 0)
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
            --BuffFrame:UpdateAuraButtons()
            if shouldKeepAurasVisible then
                ShowHiddenAuras(true)
            else
                HideHiddenAuras()
            end
            UpdateHiddenAurasCount()
        end
    end)


    toggleIcon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 0, -10)
        GameTooltip:AddLine("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames")
        GameTooltip:AddLine("Filtered buffs. Click to show/hide.\nShift+Alt+RightClick to blacklist buffs.\n\nCtrl+LeftClick to move.\nShift+LeftClick to reset position.\nAlt+LeftClick to change direction.\n\n(You can hide this icon in settings)", 1, 1, 1, true)
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
local function PersonalBuffFrameFilterAndGrid(self)
    ResetHiddenAurasCount()
    local isExpanded = BuffFrame.numConsolidated == 0--BuffFrame:IsExpanded();
    local currentAuraSize = 1--playerAuraBuffScale--BuffFrame.AuraContainer.iconScale
    local addIconsToRight = false--BuffFrame.AuraContainer.addIconsToRight or false
    if ToggleHiddenAurasButton then
        ToggleHiddenAurasButton:SetScale(currentAuraSize)
    end

    local maxAurasPerRow = maxPlayerAurasPerRow
    local auraSpacingX = playerAuraSpacingX--BuffFrame.AuraContainer.iconPadding - 7 + playerAuraSpacingX
    local auraSpacingY = 13 + playerAuraSpacingY--BuffFrame.AuraContainer.iconPadding + 8 + playerAuraSpacingY
    local auraSize = 32;      -- Set the size of each aura frame
    --local auraScale = BuffFrame.AuraContainer.iconScale

    local currentRow = 1;
    local currentCol = 1;
    local xOffset = 0;
    local yOffset = 0;
    local hiddenYOffset = 0 -- -auraSpacingY - auraSize + playerAuraSpacingY;
    local hiddenXOffset = 0
    local toggleIcon = showHiddenAurasIcon and CreateToggleIcon() or nil

    local addedGroups = {}

    if isExpanded then
        for i = 1, BuffFrame.numEnchants do
            local tempEnchantName = "TempEnchant"..i
            local auraFrame = _G[tempEnchantName]
            local name = "TempEnchant"
            local spellId = "TempEnchantID"

            local auraData = {
                name = name,
                isHelpful = true,
                isHarmful = false,
                spellId = spellId,
                auraType = "Buff",
                duration = 0,
            }

            if auraFrame then
                auraFrame.isTempEnchant = true
                auraFrame.isNormalAura = false
                auraFrame.currentAuraIndex = i

                local shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor
                shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor = ShouldShowBuff("player", auraData, "playerBuffFrame")

                -- Nonprint logic
                if shouldShowAura then
                    auraFrame.duration:SetDrawLayer("OVERLAY", 7)
                    auraFrame:Show();
                    auraFrame:ClearAllPoints();
                    if addIconsToRight then
                        auraFrame:SetPoint("TOPLEFT", BuffFrame, "TOPLEFT", xOffset, -yOffset);
                    else
                        auraFrame:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", -xOffset, -yOffset);
                    end

                    auraFrame.spellId = "TempEnchant"
                    auraFrame.name = "TempEnchant"

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


                    if printAuraSpellIds and not auraFrame.bbfHookAdded then
                        auraFrame.bbfHookAdded = true
                        auraFrame:HookScript("OnEnter", function()
                            local currentAuraIndex = auraFrame.currentAuraIndex
                            local name, icon, count, dispelType, duration, expirationTime, source,
                                isStealable, nameplateShowPersonal, spellId, canApplyAura,
                                isBossDebuff, castByPlayer, nameplateShowAll, timeMod, hasMainHandEnchant,
                                mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID
                            if auraFrame.isTempEnchant then
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
                                = UnitAura("player", currentAuraIndex, 'HELPFUL');
                            end

                            if name and (not auraFrame.bbfPrinted or auraFrame.bbfLastPrintedAuraIndex ~= currentAuraIndex) then
                                local iconTexture = icon and "|T" .. icon .. ":16:16|t" or ""
                                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconTexture .. " " .. (name or "Unknown") .. "  |A:worldquest-icon-engineering:14:14|a ID: " .. (auraFrame.isTempEnchant and "No ID" or spellId or "Unknown"))
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

                    -- Important logic
                    if isImportant then
                        local borderFrame = BBF.auraBorders[auraFrame]
                        auraFrame.isImportant = true
                        if not auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow = auraFrame:CreateTexture(nil, "ARTWORK", nil, 1)
                            if borderFrame then
                                auraFrame.ImportantGlow:SetParent(borderFrame)
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -15, 16)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 15, -6)
                            else
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -34, 35)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 34, -36)
                            end
                            --auraFrame.ImportantGlow:SetDrawLayer("OVERLAY", 7)
                            auraFrame.ImportantGlow:SetTexture(BBF.squareGreenGlow)
                            auraFrame.ImportantGlow:SetDesaturated(true)
                        end
                        if borderFrame then
                            auraFrame.ImportantGlow:SetParent(borderFrame)
                        end
                        if auraColor then
                            auraFrame.ImportantGlow:SetVertexColor(auraColor[1], auraColor[2], auraColor[3], auraColor[4])
                        else
                            auraFrame.ImportantGlow:SetVertexColor(0, 1, 0)
                        end
                        auraFrame.ImportantGlow:Show()
                    else
                        auraFrame.isImportant = false
                        if auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow:Hide()
                        end
                    end
                else
                    if not auraFrame.isHooked then
                        auraFrame:HookScript("OnShow", function(self)
                            if self.isAuraHidden and not shouldKeepAurasVisible then
                                self:Hide()
                            end
                        end)
                        auraFrame.isHooked = true
                    end
                    hiddenAuras = hiddenAuras + 1
                    if not shouldKeepAurasVisible then
                        auraFrame:Hide()
                        auraFrame.isAuraHidden = true
                    end
                    auraFrame:ClearAllPoints()
                    if toggleIcon then
                        if BetterBlizzFramesDB.hiddenIconDirection == "BOTTOM" then
                            auraFrame:SetPoint("TOP", ToggleHiddenAurasButton, "TOP", 0, hiddenYOffset - 35)
                            hiddenYOffset = hiddenYOffset - auraSize - auraSpacingY + 10
                        elseif BetterBlizzFramesDB.hiddenIconDirection == "TOP" then
                            auraFrame:SetPoint("BOTTOM", ToggleHiddenAurasButton, "BOTTOM", 0, hiddenYOffset + 25)
                            hiddenYOffset = hiddenYOffset + auraSize + auraSpacingY - 10
                        elseif BetterBlizzFramesDB.hiddenIconDirection == "LEFT" then
                            auraFrame:SetPoint("RIGHT", ToggleHiddenAurasButton, "LEFT", hiddenXOffset + 30, -5)
                            hiddenXOffset = hiddenXOffset - auraSize - auraSpacingX
                        elseif BetterBlizzFramesDB.hiddenIconDirection == "RIGHT" then
                            auraFrame:SetPoint("LEFT", ToggleHiddenAurasButton, "RIGHT", hiddenXOffset - 30, -5)
                            hiddenXOffset = hiddenXOffset + auraSize + auraSpacingX
                        end
                    end
                end


            end

        end

        for i = 1, BUFF_ACTUAL_DISPLAY do
            local buffName = "BuffButton"..i
            local icon = buffName.."Icon"
            local auraFrame = _G[buffName]
            auraFrame.Icon = icon
            if auraFrame then
                auraFrame.isTempEnchant = false
                auraFrame.isNormalAura = true
                auraFrame.currentAuraIndex = i
                auraFrame.duration:SetDrawLayer("OVERLAY", 7)
                --buffFrame.Icon = _G[icon]

                local spellName, icon, count, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitBuff("player", i)
                auraFrame.spellId = spellId

                local auraData = { -- Manually create the aura data structure as needed
                    sourceUnit = sourceUnit,
                    canApplyAura = canApplyAura,
                    isStealable = isStealable,
                    dispelName = dispelName,
                    isHelpful = true,
                    isHarmful = false,
                    spellId = spellId,
                    expirationTime = expirationTime,
                    icon = icon,
                    name = spellName,
                    auraType = "Buff",
                    duration = duration,
                }


                local shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor
                shouldShowAura, isImportant, isPandemic, isEnlarged, isCompacted, auraColor = ShouldShowBuff("player", auraData, "playerBuffFrame")
                isImportant = isImportant and playerAuraImportantGlow

                local groupName = getSpammyGroup(spellId)
                local shouldBeAdded = true
                if groupName then
                    if addedGroups[groupName] then
                        shouldBeAdded = false
                    else
                        addedGroups[groupName] = true
                    end
                end

                -- Nonprint logic
                if shouldShowAura and shouldBeAdded then
                    if addCooldownFramePlayerBuffs then
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
                            auraFrame.duration:SetAlpha(0)
                        end
                    end

                    if printAuraSpellIds and not auraFrame.bbfHookAdded then
                        auraFrame.bbfHookAdded = true
                        auraFrame:HookScript("OnEnter", function()
                            local currentAuraIndex = auraFrame.currentAuraIndex
                            local name, icon, count, dispelType, duration, expirationTime, source,
                                isStealable, nameplateShowPersonal, spellId, canApplyAura,
                                isBossDebuff, castByPlayer, nameplateShowAll, timeMod, hasMainHandEnchant,
                                mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID
                            if auraFrame.isTempEnchant then
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
                                = UnitAura("player", currentAuraIndex, 'HELPFUL');
                            end

                            if name and (not auraFrame.bbfPrinted or auraFrame.bbfLastPrintedAuraIndex ~= currentAuraIndex) then
                                local iconTexture = icon and "|T" .. icon .. ":16:16|t" or ""
                                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconTexture .. " " .. (name or "Unknown") .. "  |A:worldquest-icon-engineering:14:14|a ID: " .. (auraFrame.isTempEnchant and "No ID" or spellId or "Unknown"))
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


                    auraFrame.duration:SetDrawLayer("OVERLAY", 7)
                    auraFrame:Show();
                    auraFrame:ClearAllPoints();
                    if addIconsToRight then
                        auraFrame:SetPoint("TOPLEFT", BuffFrame, "TOPLEFT", xOffset, -yOffset);
                    else
                        auraFrame:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", -xOffset, -yOffset);
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
                            auraFrame.ImportantGlow = auraFrame:CreateTexture(nil, "ARTWORK", nil, 1)
                            if borderFrame then
                                auraFrame.ImportantGlow:SetParent(borderFrame)
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -15, 16)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 15, -6)
                            else
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -34, 35)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 34, -36)
                            end
                            --auraFrame.ImportantGlow:SetDrawLayer("OVERLAY", 7)
                            auraFrame.ImportantGlow:SetTexture(BBF.squareGreenGlow)
                            auraFrame.ImportantGlow:SetDesaturated(true)
                        end
                        if borderFrame then
                            auraFrame.ImportantGlow:SetParent(borderFrame)
                        end
                        if auraColor then
                            auraFrame.ImportantGlow:SetVertexColor(auraColor[1], auraColor[2], auraColor[3], auraColor[4])
                        else
                            auraFrame.ImportantGlow:SetVertexColor(0, 1, 0)
                        end
                        auraFrame.ImportantGlow:Show()
                    else
                        auraFrame.isImportant = false
                        if auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow:Hide()
                        end
                    end
                else
                    hiddenAuras = hiddenAuras + 1
                    if not shouldKeepAurasVisible then
                        auraFrame:Hide()
                        auraFrame.isAuraHidden = true
                    end
                    auraFrame:ClearAllPoints()
                    if toggleIcon then
                        if BetterBlizzFramesDB.hiddenIconDirection == "BOTTOM" then
                            auraFrame:SetPoint("TOP", ToggleHiddenAurasButton, "TOP", 0, hiddenYOffset - 35)
                            hiddenYOffset = hiddenYOffset - auraSize - auraSpacingY + 10
                        elseif BetterBlizzFramesDB.hiddenIconDirection == "TOP" then
                            auraFrame:SetPoint("BOTTOM", ToggleHiddenAurasButton, "BOTTOM", 0, hiddenYOffset + 25)
                            hiddenYOffset = hiddenYOffset + auraSize + auraSpacingY - 10
                        elseif BetterBlizzFramesDB.hiddenIconDirection == "LEFT" then
                            auraFrame:SetPoint("RIGHT", ToggleHiddenAurasButton, "LEFT", hiddenXOffset + 30, -5)
                            hiddenXOffset = hiddenXOffset - auraSize - auraSpacingX
                        elseif BetterBlizzFramesDB.hiddenIconDirection == "RIGHT" then
                            auraFrame:SetPoint("LEFT", ToggleHiddenAurasButton, "RIGHT", hiddenXOffset - 30, -5)
                            hiddenXOffset = hiddenXOffset + auraSize + auraSpacingX
                        end
                    end
                end
            end
        end
    end
    UpdateHiddenAurasCount()
end

--local tooltip = CreateFrame("GameTooltip", "AuraTooltip", nil, "GameTooltipTemplate")
--tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
local DebuffFrame = BuffFrame
local function PersonalDebuffFrameFilterAndGrid(self)
    -- local maxAurasPerRow = DebuffFrame.AuraContainer.iconStride
    -- local auraSpacingX = DebuffFrame.AuraContainer.iconPadding - 7 + playerAuraSpacingX
    -- local auraSpacingY = DebuffFrame.AuraContainer.iconPadding + 8 + playerAuraSpacingY

    local maxAurasPerRow = maxPlayerAurasPerRow
    local auraSpacingX = playerAuraSpacingX--BuffFrame.AuraContainer.iconPadding - 7 + playerAuraSpacingX
    local auraSpacingY = 13 + playerAuraSpacingY--BuffFrame.AuraContainer.iconPadding + 8 + playerAuraSpacingY
    local auraSize = 32;      -- Set the size of each aura frame

    --local dotChecker = BetterBlizzFramesDB.debuffDotChecker
    local printAuraIds = printAuraSpellIds

    local currentRow = 1;
    local currentCol = 1;
    local xOffset = 0;
    local extraYOffset = 110
    local yOffset = extraYOffset;

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


        for i = 1, DEBUFF_ACTUAL_DISPLAY do
            local debuffName = "DebuffButton"..i
            local icon = debuffName.."Icon"
            local border = _G[debuffName.."Border"]
            local auraFrame = _G[debuffName]
            auraFrame.Icon = icon
            auraFrame.border = border
            if auraFrame and auraFrame:IsShown() then
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
                -- if MasquePlayerAuras and not auraFrame.added then
                --     MasquePlayerAuras:AddButton(auraFrame)
                --     auraFrame.added = true
                -- end
                --buffFrame.Icon = _G[icon]

                local spellName, icon, count, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitDebuff("player", i)
                auraFrame.spellId = spellId

                local auraData = { -- Manually create the aura data structure as needed
                    sourceUnit = sourceUnit,
                    canApplyAura = canApplyAura,
                    isStealable = isStealable,
                    dispelName = dispelName,
                    isHelpful = true,
                    isHarmful = false,
                    spellId = spellId,
                    expirationTime = expirationTime,
                    icon = icon,
                    name = spellName,
                    auraType = "Debuff",
                    duration = duration,
                }
                --local unit = self.unit
                -- if printAuraIds and not auraFrame.bbfHookAdded then
                --     auraFrame.bbfHookAdded = true
                --     auraFrame:HookScript("OnEnter", function()
                --         if printAuraIds then
                --             local currentAuraIndex = auraInfo.index
                --             local name, icon, count, dispelType, duration, expirationTime, source, 
                --             isStealable, nameplateShowPersonal, spellId, canApplyAura, 
                --             isBossDebuff, castByPlayer, nameplateShowAll, timeMod 
                --             = UnitAura("player", currentAuraIndex, 'HARMFUL');

                --             local auraData = {
                --                 name = name,
                --                 icon = icon,
                --                 count = count,
                --                 dispelType = dispelType,
                --                 duration = duration,
                --                 expirationTime = expirationTime,
                --                 sourceUnit = source,
                --                 isStealable = isStealable,
                --                 nameplateShowPersonal = nameplateShowPersonal,
                --                 spellId = spellId,
                --                 auraType = auraInfo.auraType,
                --             };

                --             if auraData and (not auraFrame.bbfPrinted or auraFrame.bbfLastPrintedAuraIndex ~= currentAuraIndex) then
                --                 local iconTexture = auraData.icon and "|T" .. auraData.icon .. ":16:16|t" or ""
                --                 print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconTexture .. " " .. (auraData.name or "Unknown") .. "  |A:worldquest-icon-engineering:14:14|a ID: " .. (auraData.spellId or "Unknown"))
                --                 auraFrame.bbfPrinted = true
                --                 auraFrame.bbfLastPrintedAuraIndex = currentAuraIndex
                --                 -- Cancel existing timer if any
                --                 if auraFrame.bbfTimer then
                --                     auraFrame.bbfTimer:Cancel()
                --                 end
                --                 -- Schedule the reset of bbfPrinted flag
                --                 auraFrame.bbfTimer = C_Timer.NewTimer(6, function()
                --                     auraFrame.bbfPrinted = false
                --                 end)
                --             end
                --         end
                --     end)
                -- end
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
                            auraFrame.duration:SetAlpha(0)
                        end
                    end

                    if spellId == 88611 then
                        if auraFrame.Cooldown then
                            auraFrame.Cooldown:SetCooldown(smokeBombCast, 5)
                        end
                        auraFrame.duration:Show()
                        auraFrame.duration:SetTextColor(1,1,1)
                        auraFrame.timeSinceLastUpdate = 0
                        auraFrame:SetScript("OnUpdate", UpdateAuraDuration)
                    end

                    auraFrame.spellId = auraData.spellId

                    SetupAuraFilterClicks(auraFrame)

                    auraFrame:Show();
                    auraFrame:ClearAllPoints();
                    auraFrame:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", -xOffset, -yOffset);
                    --print(auraFrame:GetSize())

                    -- Update column and row counters
                    currentCol = currentCol + 1;
                    if currentCol > maxAurasPerRow then
                        currentRow = currentRow + 1;
                        currentCol = 1;
                    end

                    -- Calculate the new offsets
                    xOffset = (currentCol - 1) * (auraSize + auraSpacingX);
                    yOffset = ((currentRow - 1) * (auraSize + auraSpacingY)) + extraYOffset

                    -- Important logic
                    if isImportant then
                        local borderFrame = BBF.auraBorders[auraFrame]
                        auraFrame.isImportant = true
                        if not auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow = auraFrame:CreateTexture(nil, "OVERLAY", nil, 1)
                            if borderFrame then
                                auraFrame.ImportantGlow:SetParent(borderFrame)
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -15, 16)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 15, -6)
                            else
                                auraFrame.ImportantGlow:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -34, 35)
                                auraFrame.ImportantGlow:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", 34, -36)
                            end
                            --auraFrame.ImportantGlow:SetDrawLayer("OVERLAY", 7)
                            auraFrame.ImportantGlow:SetTexture(BBF.squareGreenGlow)
                            auraFrame.ImportantGlow:SetDesaturated(true)
                        end
                        if borderFrame then
                            auraFrame.ImportantGlow:SetParent(borderFrame)
                        end
                        if auraColor then
                            auraFrame.ImportantGlow:SetVertexColor(auraColor[1], auraColor[2], auraColor[3], auraColor[4])
                        else
                            auraFrame.ImportantGlow:SetVertexColor(0, 1, 0)
                        end
                        auraFrame.ImportantGlow:Show()
                    else
                        auraFrame.isImportant = false
                        if auraFrame.ImportantGlow then
                            auraFrame.ImportantGlow:Hide()
                        end
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

local function ScaleBuffFrame()
    BuffFrame:SetScale(playerAuraBuffScale)
    if TemporaryEnchantFrame then
        TemporaryEnchantFrame:SetScale(playerAuraBuffScale)
    end
end



function BBF.RepositionBuffFrame()
    if not BetterBlizzFramesDB.repositionBuffFrame then return end
    playerAuraXOffset = BetterBlizzFramesDB.playerAuraXOffset
    playerAuraYOffset = BetterBlizzFramesDB.playerAuraYOffset

    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint("TOPRIGHT", MinimapCluster, "TOPLEFT", -10 + playerAuraXOffset, -13 + playerAuraYOffset)

    if not BBF.BuffFrameRepos then
        hooksecurefunc(BuffFrame, "SetPoint", function(self)
            if self.changing then return end
            self.changing = true
            BuffFrame:ClearAllPoints()
            BuffFrame:SetPoint("TOPRIGHT", MinimapCluster, "TOPLEFT", -10 + BetterBlizzFramesDB.playerAuraXOffset, -13 + BetterBlizzFramesDB.playerAuraYOffset)
            self.changing = false
        end)
        BBF.BuffFrameRepos = true
    end
end

local auraMsgSent = false
function BBF.RefreshAllAuraFrames()
    BBF.UpdateUserAuraSettings()
    ScaleBuffFrame()
    BBF.RepositionBuffFrame()
    if BetterBlizzFramesDB.playerAuraFiltering then
        if BetterBlizzFramesDB.enablePlayerBuffFiltering then
            PersonalBuffFrameFilterAndGrid(BuffFrame)
            --BuffFrame_Update()
        end
        if BetterBlizzFramesDB.enablePlayerDebuffFiltering then
            PersonalDebuffFrameFilterAndGrid(DebuffFrame)
        end
        --PersonalDebuffFrameFilterAndGrid(DebuffFrame)
        AdjustAuras(TargetFrame, "target")
        AdjustAuras(FocusFrame, "focus")

        if ToggleHiddenAurasButton then
            ToggleHiddenAurasButton:SetPoint("TOPLEFT", BuffFrame, "TOPRIGHT", 2 + BetterBlizzFramesDB.playerAuraSpacingX, 0)
        end
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
                frame.SkinnedIcon:SetTexture(tex)
            end)
            group:AddButton(skinWrapper, {
                Icon = frame.SkinnedIcon,
            })
        end
        if BetterBlizzFramesDB.playerCastBarShowIcon then
            MsqSkinIcon(CastingBarFrame, MasqueCastbars)
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



        -- addToMasque(CastingBarFrame.Icon, MasqueCastbars)
        -- addToMasque(TargetFrameSpellBar.Icon, MasqueCastbars)
        -- addToMasque(FocusFrameSpellBar.Icon, MasqueCastbars)

        -- CastingBarFrame.Icon
        -- TargetFrameSpellBar.Icon
        -- FocusFrameSpellBar.Icon

        function BBF.MasqueUnitFrames(self, buffGroup, debuffGroup)
            -- Handling Buffs
            for i = 1, MAX_TARGET_BUFFS do
                local buffName = self:GetName().."Buff"..i
                if _G[buffName] and _G[buffName]:IsShown() then
                    addToMasque(buffName, buffGroup)
                else
                    break
                end
            end

            -- Handling Debuffs
            for i = 1, 40 do
                local debuffName = self:GetName().."Debuff"..i
                if _G[debuffName] and _G[debuffName]:IsShown() then
                    addToMasque(debuffName, debuffGroup)
                else
                    break
                end
            end

            if not auraFilteringOn then
                buffGroup:ReSkin(true)
                debuffGroup:ReSkin(true)
            end
        end

        hooksecurefunc("TargetFrame_UpdateAuras", function(self)
            if self == TargetFrame then
                BBF.MasqueUnitFrames(self, MasqueTargetBuffs, MasqueTargetDebuffs)
            elseif self == FocusFrame then
                BBF.MasqueUnitFrames(self, MasqueFocusBuffs, MasqueFocusDebuffs)
            end
        end)



        -- function BBF.MasqueUnitFrames(self)
        --     for i = 1, MAX_TARGET_BUFFS do
        --         local buffName = self:GetName().."Buff"..i
        --         if _G[buffName] and _G[buffName]:IsShown() then
        --             addToMasque(buffName, MasqueUnitFrameAuras)
        --         else
        --             break
        --         end
        --     end
        --     for i = 1, 40 do
        --         local debuffName = self:GetName().."Debuff"..i
        --         if _G[debuffName] and _G[debuffName]:IsShown() then
        --             addToMasque(debuffName, MasqueUnitFrameAuras)
        --         else
        --             break
        --         end
        --     end
        --     MasqueUnitFrameAuras:ReSkin(true)
        -- end
        -- hooksecurefunc("TargetFrame_UpdateAuras", function(self)
        --     BBF.MasqueUnitFrames(self)
        -- end)





















        function BBF.MasquePlayerAuras()
            -- Player Buffs
            for i = 1, BUFF_ACTUAL_DISPLAY do
                local buffName = "BuffButton"..i
                if _G[buffName] then
                    addToMasque(buffName, MasquePlayerBuffs)
                end
            end
            for i = 1, 3 do
                local buffName = "TempEnchant"..i
                if _G[buffName] then
                    addToMasque(buffName, MasquePlayerBuffs)
                end
            end
            -- Player Debuffs
            for i = 1, DEBUFF_ACTUAL_DISPLAY do
                local debuffName = "DebuffButton"..i
                if _G[debuffName] then
                    addToMasque(debuffName, MasquePlayerDebuffs)
                end
            end
        end

        function BBF.MasquePlayerAurasSUI()
            -- Player Buffs
            for i = 1, BUFF_ACTUAL_DISPLAY do
                local buffName = "BuffButton"..i
                local duration = "BuffButton"..i.."Duration"
                if _G[buffName] then
                    addToMasque(buffName, MasquePlayerBuffs)
                end
                if _G[duration] then
                    _G[duration]:ClearAllPoints()
                    _G[duration]:SetPoint("BOTTOM", _G[buffName], "BOTTOM", 0, 0)
                end
            end
            -- Player Debuffs
            for i = 1, DEBUFF_ACTUAL_DISPLAY do
                local debuffName = "DebuffButton"..i
                local duration = "DebuffButton"..i.."Duration"
                if _G[debuffName] then
                    addToMasque(debuffName, MasquePlayerDebuffs)
                end
                if _G[duration] then
                    _G[duration]:ClearAllPoints()
                    _G[duration]:SetPoint("BOTTOM", _G[debuffName], "BOTTOM", 0, 0)
                end
            end
        end

        C_Timer.After(3, function()
            if ToggleHiddenAurasButton then
                addToMasque("ToggleHiddenAurasButton", MasquePlayerBuffs)
            end
        end)
        if C_AddOns.IsAddOnLoaded("SUI") then
            hooksecurefunc("BuffFrame_Update", BBF.MasquePlayerAurasSUI)
        else
            hooksecurefunc("BuffFrame_Update", BBF.MasquePlayerAuras)
        end

        -- function BBF.MasqueRaidFrames()
        --     local numGroupMembers = GetNumGroupMembers()
        --     local isInRaid = IsInRaid()
        --     local isInGroup = IsInGroup()

        --     if not isInGroup then
        --         numGroupMembers = 1
        --     end

        --     -- Iterate over raid frames if in a raid group
        --     if isInRaid then
        --         for groupIndex = 1, 8 do
        --             for memberIndex = 1, 5 do
        --                 local unitIndex = (groupIndex - 1) * 5 + memberIndex
        --                 if unitIndex <= numGroupMembers then
        --                     for buffIndex = 1, 6 do
        --                         addToMasque("CompactRaidGroup" .. groupIndex .. "Member" .. memberIndex .. "Buff" .. buffIndex, MasquePartyFrameAuras)
        --                         addToMasque("CompactRaidGroup" .. groupIndex .. "Member" .. memberIndex .. "Debuff" .. buffIndex, MasquePartyFrameAuras)
        --                     end
        --                 end
        --             end
        --         end
        --     else
        --         -- Iterate over party frames if in a party group
        --         for memberIndex = 1, numGroupMembers do
        --             for buffIndex = 1, 6 do
        --                 addToMasque("CompactPartyFrameMember" .. memberIndex .. "Buff" .. buffIndex, MasquePartyFrameAuras)
        --                 addToMasque("CompactPartyFrameMember" .. memberIndex .. "Debuff" .. buffIndex, MasquePartyFrameAuras)
        --                 addToMasque("CompactRaidFrame" .. memberIndex .. "Buff" .. buffIndex, MasquePartyFrameAuras)
        --                 addToMasque("CompactRaidFrame" .. memberIndex .. "Debuff" .. buffIndex, MasquePartyFrameAuras)
        --                 addToMasque("CompactRaidFrame" .. memberIndex .. "BigDebuffsRaid" .. buffIndex, MasquePartyFrameAuras)
        --                 addToMasque("CompactPartyFrameMember" .. memberIndex .. "BigDebuffsRaid" .. buffIndex, MasquePartyFrameAuras)
        --             end
        --         end
        --     end
        -- end
        -- BBF.MasqueRaidFrames()

        -- function BBF.MasquePartyFrames()
        --     for memberIndex = 1, 5 do
        --         for buffIndex = 1, 10 do
        --             addToMasque("PartyMemberFrame" .. memberIndex .. "Debuff" .. buffIndex, MasquePartyFrameAuras)
        --             addToMasque("PartyMemberBuffTooltipBuff" .. buffIndex, MasquePartyFrameAuras)
        --         end
        --     end
        -- end
        -- BBF.MasquePartyFrames()

        -- local eventFrame = CreateFrame("Frame")
        -- eventFrame:SetScript("OnEvent", BBF.MasqueRaidFrames)
        -- eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        -- C_Timer.After(1, function()
        --     BBF.MasqueRaidFrames()
        --     --BBF.MasquePartyFrames()
        -- end)

        -- hooksecurefunc("CompactUnitFrame_UpdateAuras", function()
        --     MasquePartyFrameAuras:ReSkin(true)
        -- end)
    end
end

function BBF.HookPlayerAndTargetAuras()
    ScaleBuffFrame()
    BBF.RepositionBuffFrame()

    --Hook Player BuffFrame
    if playerBuffFilterOn and not playerBuffsHooked then
        hooksecurefunc("BuffFrame_Update", PersonalBuffFrameFilterAndGrid)
        PersonalBuffFrameFilterAndGrid(BuffFrame)
        --BuffFrame_Update()
        playerBuffsHooked = true
    end

    --Hook Player DebuffFrame
    if playerDebuffFilterOn and not playerDebuffsHooked then
        hooksecurefunc("BuffFrame_Update", PersonalDebuffFrameFilterAndGrid)
        PersonalDebuffFrameFilterAndGrid(DebuffFrame)
        playerDebuffsHooked = true
    end

    --Hook Target & Focus Frame
    if auraFilteringOn and not targetAurasHooked then
        hooksecurefunc("TargetFrame_UpdateAuras", function(self) AdjustAuras(self, self.unit) end)
        --hooksecurefunc(FocusFrame, "UpdateAuras", function(self) AdjustAuras(self, "focus") end)
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

    if not smokeBombDetector then
        smokeBombDetector = CreateFrame("Frame")
        smokeBombDetector:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        smokeBombDetector:SetScript("OnEvent", SmokeBombCheck)
    end
end



local purgeListener = CreateFrame("Frame")
purgeListener:RegisterEvent("SPELLS_CHANGED")
purgeListener:SetScript("OnEvent", function()
    BBF.hasExtraPurge = IsSpellKnownOrOverridesKnown(110802)
end)