local CataAbsorb = {}
CataAbsorb.spells = {
    [17] = true, -- Priest: Power Word: Shield
    [47753] = true, -- Priest: Divine Aegis
    [86273] = true, -- Paladin: Illuminated Healing
    [96263] = true, -- Paladin: Sacred Shield
    [62606] = true, -- Druid: Savage Defense
    [77535] = true, -- DK: Blood Shield
    [1463] = true, -- Mage: Mana Shield / Incanters Ward
    [11426] = true, -- Mage: Ice Barrier
    [98864] = true, -- Mage: Ice Barrier
    [55277] = true, -- Shaman: Totem Shield
    [116849] = true, -- Monk: Life Cocoon
    [115295] = true, -- Monk: Guard
    [114893] = true, -- Shaman: Stone Bulwark
    [123258] = true, -- Priest: Power Word: Shield
    [114214] = true, -- Angelic Bulwark
    [131623] = true, -- Twilight Ward (Magic)
    [48707] = true, -- Anti-Magic Shell
    [110570] = true, -- Anti-Magic Shell (Symbiosis)
    [114908] = true, -- Spirit Shell
}
CataAbsorb.playerName = UnitName("player")
CataAbsorb.unitFrames = {}
CataAbsorb.compactUnitFrames = {}

local function ComputeAbsorb(unit)
    local value = 0
    local maxAbsorbIcon = nil
    for index = 1, 40 do
        local name, icon, _, _, _, _, _, _, _, spellId, _, _, _, _, _, _, absorb = UnitAura(unit, index)
        if not name then break end
        if CataAbsorb.spells[spellId] and absorb then
            value = value + absorb
            maxAbsorbIcon = icon -- Always use the last matching icon
        end
    end
    return value, maxAbsorbIcon
end

local function RaiseStrataOnHpText(frame)
    local leftText = _G[frame.."HealthBarTextLeft"] or _G[frame].textureFrame.HealthBarTextLeft
    local rightText = _G[frame.."HealthBarTextRight"] or _G[frame].textureFrame.HealthBarTextRight
    local centerText = _G[frame.."HealthBarText"] or _G[frame].textureFrame.HealthBarText

    if leftText then
        leftText:SetDrawLayer("OVERLAY")
    end
    if rightText then
        rightText:SetDrawLayer("OVERLAY")
    end
    if centerText then
        centerText:SetDrawLayer("OVERLAY")
    end
end

local function UpdateAbsorbIndicator(frame, unit)
    if not BetterBlizzFramesDB.absorbIndicator and not BetterBlizzFramesDB.absorbIndicatorTestMode then return end

    local settingsPrefix = unit
    local showAmount = BetterBlizzFramesDB[settingsPrefix .. "AbsorbAmount"]
    local showIcon = BetterBlizzFramesDB[settingsPrefix .. "AbsorbIcon"]
    local xPos = BetterBlizzFramesDB.playerAbsorbXPos
    local yPos = BetterBlizzFramesDB.playerAbsorbYPos
    local anchor = BetterBlizzFramesDB.playerAbsorbAnchor
    local reverseAnchor = BBF.GetOppositeAnchor(anchor)
    local darkModeOn = BetterBlizzFramesDB.darkModeUi
    local vertexColor = darkModeOn and BetterBlizzFramesDB.darkModeColor or 1
    local testMode = BetterBlizzFramesDB.absorbIndicatorTestMode
    local flipIconText = BetterBlizzFramesDB.absorbIndicatorFlipIconText

    if not frame.absorbParent then
        frame.absorbParent = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.absorbParent:SetSize(50, 50) -- Set this size to fit both icon and text
        frame.absorbParent:SetPoint("CENTER", frame, "CENTER", xPos, yPos) -- Position it according to your needs
        frame.absorbParent:SetFrameStrata("HIGH")

        frame.absorbIcon = frame.absorbParent:CreateTexture(nil, "OVERLAY")
        frame.absorbIcon:SetSize(20, 20)
        frame.absorbIcon:SetPoint("CENTER", frame.absorbParent, "CENTER") -- Position the icon inside the parent frame

        frame.absorbIndicator = frame.absorbParent:CreateFontString(nil, "OVERLAY")
        frame.absorbIndicator:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        frame.absorbIndicator:SetPoint("CENTER", frame.absorbParent, "CENTER") -- Position the text inside the parent frame
        frame.absorbIndicator:SetDrawLayer("OVERLAY", 7)
    end

    -- Ensure the border is attached to the absorbParent and appears above the icon
    if not frame.absorbIcon.border then
        local border = CreateFrame("Frame", nil, frame.absorbParent, "BackdropTemplate")
        border:SetBackdrop({
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tileEdge = true,
            edgeSize = 8,
        })

        border:SetPoint("TOPLEFT", frame.absorbIcon, "TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", frame.absorbIcon, "BOTTOMRIGHT", 2, -2)
        border:SetFrameLevel(frame.absorbParent:GetFrameLevel() + 1)  -- Ensure the border is above the icon
        frame.absorbIcon.border = border
    end

    if darkModeOn then
        frame.absorbIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        frame.absorbIcon.border:SetBackdropBorderColor(vertexColor, vertexColor, vertexColor)
        frame.absorbIcon.border:SetAlpha(0)
    else
        frame.absorbIcon:SetTexCoord(0, 1, 0, 1)
        frame.absorbIcon.border:SetAlpha(0)
    end

    frame.absorbIcon:ClearAllPoints()
    frame.absorbIndicator:ClearAllPoints()

    if frame == PlayerFrame then
        xPos = xPos * -1 -- invert the xPos value for PlayerFrame
    end

    if testMode then
        frame.absorbIcon:SetTexture("Interface\\Icons\\SPELL_HOLY_POWERWORDSHIELD")
        frame.absorbIcon:SetAlpha(1)
        frame.absorbIndicator:SetText("69k")
        frame.absorbIndicator:SetAlpha(1)
        if frame == PlayerFrame then
            if anchor == "LEFT" or anchor == "RIGHT" then
                frame.absorbIcon:SetPoint(anchor, frame, reverseAnchor, -45 + xPos, 2.5 + yPos)
            else
                frame.absorbIcon:SetPoint(reverseAnchor, frame, anchor, -5 + xPos, -21.5 + yPos)
            end
            if showIcon then
                if darkModeOn then
                    frame.absorbIcon.border:SetAlpha(1)
                else
                    frame.absorbIcon.border:SetAlpha(0)
                end
                if flipIconText then
                    frame.absorbIndicator:SetPoint("RIGHT", frame.absorbIcon, "LEFT", 0, 0)
                else
                    frame.absorbIndicator:SetPoint("LEFT", frame.absorbIcon, "RIGHT", 3, 0)
                end
            else
                frame.absorbIndicator:SetPoint("LEFT", frame.absorbIcon, "RIGHT", -23, 0)
            end
        else
            if anchor == "LEFT" or anchor =="RIGHT" then
                frame.absorbIcon:SetPoint(reverseAnchor, frame, anchor, -5 + xPos, 3 + yPos)
            else
                frame.absorbIcon:SetPoint(reverseAnchor, frame, anchor, 5 + xPos, -21 + yPos)
            end
            if showIcon then
                if darkModeOn then
                    frame.absorbIcon.border:SetAlpha(1)
                else
                    frame.absorbIcon.border:SetAlpha(0)
                end
                if flipIconText then
                    frame.absorbIndicator:SetPoint("LEFT", frame.absorbIcon, "RIGHT", 3, 0)
                else
                    frame.absorbIndicator:SetPoint("RIGHT", frame.absorbIcon, "LEFT", 0, 0)
                end
            else
                frame.absorbIndicator:SetPoint("RIGHT", frame.absorbIcon, "LEFT", 20, 0)
            end
        end
        return
    end

    if showAmount then
        if frame == PlayerFrame then
            if anchor == "LEFT" or anchor == "RIGHT" then
                frame.absorbIcon:SetPoint(anchor, frame, reverseAnchor, -45 + xPos, 2.5 + yPos)
            else
                frame.absorbIcon:SetPoint(reverseAnchor, frame, anchor, -5 + xPos, -21.5 + yPos)
            end
            if showIcon then
                if darkModeOn then
                    frame.absorbIcon.border:SetAlpha(1)
                else
                    frame.absorbIcon.border:SetAlpha(0)
                end
                if flipIconText then
                    frame.absorbIndicator:SetPoint("RIGHT", frame.absorbIcon, "LEFT", 0, 0)
                else
                    frame.absorbIndicator:SetPoint("LEFT", frame.absorbIcon, "RIGHT", 3, 0)
                end
            else
                frame.absorbIndicator:SetPoint("LEFT", frame.absorbIcon, "RIGHT", -23, 0)
            end
        else
            if anchor == "LEFT" or anchor =="RIGHT" then
                frame.absorbIcon:SetPoint(reverseAnchor, frame, anchor, -5 + xPos, 3 + yPos)
            else
                frame.absorbIcon:SetPoint(reverseAnchor, frame, anchor, 5 + xPos, -21 + yPos)
            end
            if showIcon then
                if darkModeOn then
                    frame.absorbIcon.border:SetAlpha(1)
                else
                    frame.absorbIcon.border:SetAlpha(0)
                end
                if flipIconText then
                    frame.absorbIndicator:SetPoint("LEFT", frame.absorbIcon, "RIGHT", 3, 0)
                else
                    frame.absorbIndicator:SetPoint("RIGHT", frame.absorbIcon, "LEFT", 0, 0)
                end
            else
                frame.absorbIndicator:SetPoint("RIGHT", frame.absorbIcon, "LEFT", 20, 0)
            end
        end

        frame.absorbIndicator:SetScale(BetterBlizzFramesDB.absorbIndicatorScale)
        frame.absorbIcon:SetScale(BetterBlizzFramesDB.absorbIndicatorScale)

        local totalAbsorb, auraIcon = ComputeAbsorb(unit)
        if totalAbsorb >= 100 then
            --local displayValue = math.floor(totalAbsorb / 1000) .. "k"
            local displayValue
            if totalAbsorb >= 1000 then
                displayValue = string.format("%.1fk", totalAbsorb / 1000)
            else
                displayValue = tostring(totalAbsorb)
            end
            frame.absorbIndicator:SetText(displayValue)
            frame.absorbIndicator:SetAlpha(1)

            if showIcon then
                if auraIcon then
                    frame.absorbIcon:SetTexture(auraIcon)
                    frame.absorbIcon:SetAlpha(1)
                    if frame.absorbIcon.border and darkModeOn then
                        frame.absorbIcon.border:SetAlpha(1)
                    end
                else
                    frame.absorbIcon:SetAlpha(0)
                    if frame.absorbIcon.border then
                        frame.absorbIcon.border:SetAlpha(0)
                    end
                end
            else
                frame.absorbIcon:SetAlpha(0)
                if frame.absorbIcon.border then
                    frame.absorbIcon.border:SetAlpha(0)
                end
            end
        else
            frame.absorbIndicator:SetAlpha(0)
            frame.absorbIcon:SetAlpha(0)
            if frame.absorbIcon.border then
                frame.absorbIcon.border:SetAlpha(0)
            end
        end
    else
        if frame.absorbIndicator then frame.absorbIndicator:SetAlpha(0) end
        if frame.absorbIcon then frame.absorbIcon:SetAlpha(0) end
        if frame.absorbIcon.border then
            frame.absorbIcon.border:SetAlpha(0)
        end
    end
end


local absorbHooked = false
function BBF.AbsorbCaller()
    --if not cataReady then return end

    UpdateAbsorbIndicator(PlayerFrame, "player")
    UpdateAbsorbIndicator(TargetFrame, "target")
    UpdateAbsorbIndicator(FocusFrame, "focus")
    if not BetterBlizzFramesDB.absorbIndicator and not BetterBlizzFramesDB.absorbIndicatorTestMode then
        if TargetFrame.absorbIcon and TargetFrame.absorbIcon.border then TargetFrame.absorbIcon.border:SetAlpha(0) end
        if TargetFrame.absorbIndicator then TargetFrame.absorbIndicator:SetAlpha(0) end
        if TargetFrame.absorbIcon then TargetFrame.absorbIcon:SetAlpha(0) end
        if PlayerFrame.absorbIndicator then PlayerFrame.absorbIndicator:SetAlpha(0) end
        if PlayerFrame.absorbIcon then PlayerFrame.absorbIcon:SetAlpha(0) end
        if PlayerFrame.absorbIcon and PlayerFrame.absorbIcon.border then PlayerFrame.absorbIcon.border:SetAlpha(0) end
        if FocusFrame.absorbIndicator then FocusFrame.absorbIndicator:SetAlpha(0) end
        if FocusFrame.absorbIcon then FocusFrame.absorbIcon:SetAlpha(0) end
        if FocusFrame.absorbIcon and FocusFrame.absorbIcon.border then FocusFrame.absorbIcon.border:SetAlpha(0) end
    end
    if not absorbHooked then
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        frame:RegisterEvent("UNIT_HEALTH")
        frame:RegisterEvent("UNIT_MAXHEALTH")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
        frame:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
                BBF.AbsorbCaller()
            elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
                local unit = ...
                if unit == "player" then
                    UpdateAbsorbIndicator(PlayerFrame, unit)
                elseif unit == "target" then
                    UpdateAbsorbIndicator(TargetFrame, unit)
                elseif unit == "focus" then
                    UpdateAbsorbIndicator(FocusFrame, unit)
                end
                -- UpdateAbsorbIndicator(PlayerFrame, unit)
                -- UpdateAbsorbIndicator(TargetFrame, unit)
                -- UpdateAbsorbIndicator(FocusFrame, unit)
            elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
                local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName = CombatLogGetCurrentEventInfo()
                if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" or subEvent == "SPELL_AURA_REMOVED" then
                    local spellId = select(12, CombatLogGetCurrentEventInfo())
                    if not CataAbsorb.spells[spellId] then return end
                    UpdateAbsorbIndicator(PlayerFrame, "player")
                    UpdateAbsorbIndicator(TargetFrame, "target")
                    UpdateAbsorbIndicator(FocusFrame, "focus")
                end
            elseif event == "PLAYER_TARGET_CHANGED" then
                UpdateAbsorbIndicator(TargetFrame, "target")
            elseif event == "PLAYER_FOCUS_CHANGED" then
                UpdateAbsorbIndicator(FocusFrame, "focus")
            end
        end)

        RaiseStrataOnHpText("PlayerFrame")
        RaiseStrataOnHpText("TargetFrame")
        RaiseStrataOnHpText("FocusFrame")

        absorbHooked = true
    end
end

local function CreateAbsorbBar(frame)
    if frame.absorbBar then return end -- Prevent duplicate elements

    -- Absorb Fill (Total Absorb)
    frame.absorbBar = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.absorbBar:SetTexture("Interface\\RaidFrame\\Shield-Fill")
    --frame.absorbBar:SetHorizTile(false)
    --frame.absorbBar:SetVertTile(false)
    frame.absorbBar:Hide()

    -- Absorb Overlay
    frame.absorbOverlay = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    frame.absorbOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true)
    frame.absorbOverlay:SetHorizTile(true)
    frame.absorbOverlay.tileSize = 32
    frame.absorbOverlay:SetAllPoints(frame.absorbBar)
    frame.absorbOverlay:Hide()

    -- Over Absorb Glow
    frame.absorbGlow = frame:CreateTexture(nil, "OVERLAY", nil, 3)
    frame.absorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
    frame.absorbGlow:SetBlendMode("ADD")
    frame.absorbGlow:SetWidth(8)
    frame.absorbGlow:SetAlpha(0.6)
    frame.absorbGlow:Hide()
    frame.absorbGlow:SetParent(frame.healthbar or frame.healthBar or frame.HealthBar)

    if not TargetFrameToT.adjustedLevel then
        PlayerFrameTexture:GetParent():SetFrameLevel(56)--5
        TargetFrameTextureFrame:SetFrameLevel(55)
        FocusFrameTextureFrame:SetFrameLevel(55)
        if not InCombatLockdown() then
            TargetFrameToT:SetFrameLevel(56)
        end
        TargetFrameToT.adjustedLevel = true
    end
end

local function HookAllFrames()
    local function StoreCompactUnitFrame(frame, unit)
        if not frame or not unit then return end

        -- Ignore nameplates
        if unit:find("nameplate") then return end

        -- Store the frame with its unit
        CataAbsorb.compactUnitFrames[unit] = frame
    end

    local function StoreUnitFrame(frame, unit)
        if not frame or not unit then return end
        -- Store the frame with its unit
        CataAbsorb.unitFrames[unit] = frame
    end

    hooksecurefunc("CompactUnitFrame_SetUnit", function(frame, unit)
        local cufAbsorbEnabled = BetterBlizzFramesDB.overShieldsCompactUnitFrames
        if cufAbsorbEnabled then
            StoreCompactUnitFrame(frame, unit)
        end
    end)

    hooksecurefunc("UnitFrame_Update", function(frame, unit)
        local ufAbsorbEnabled = BetterBlizzFramesDB.overShieldsUnitFrames
        if ufAbsorbEnabled then
            StoreUnitFrame(frame, frame.unit)
        end
    end)
end

HookAllFrames()


local function UpdateAbsorbOnFrame(unit, frame, absorbValue)
    if not frame or not frame.unit or not UnitIsUnit(unit, frame.unit) then return end
    local healthBar = frame.healthBar or frame.HealthBar or frame.healthbar
    if not healthBar then return end

    local state = CataAbsorb.allstates[unit]
    CreateAbsorbBar(frame) -- Ensure elements exist

    if not (state and state.show) then
        -- Hide absorb visuals if no absorb is present
        frame.absorbGlow:Hide()
        frame.absorbOverlay:Hide()
        frame.absorbBar:Hide()
        return
    end

    local currentHealth, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
    if maxHealth <= 0 then return end

    -- **Use precomputed absorb value**
    local totalAbsorb = absorbValue or 0
    local missingHealth = maxHealth - currentHealth
    local totalWidth = healthBar:GetWidth()

    -- **Absorb Bar - stays within missing health space**
    local absorbWidth = math.min(totalAbsorb, missingHealth) / maxHealth * totalWidth
    local offset = currentHealth / maxHealth * totalWidth -- Where absorb starts

    if absorbWidth > 0 then
        frame.absorbBar:ClearAllPoints()
        frame.absorbBar:SetParent(healthBar)
        frame.absorbBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", offset, 0)
        frame.absorbBar:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", offset, 0)
        frame.absorbBar:SetWidth(absorbWidth)
        frame.absorbBar:Show()
    else
        frame.absorbBar:Hide()
    end

    -- **Absorb Overlay - always shows full absorb & moves backward if needed**
    frame.absorbOverlay:ClearAllPoints()
    frame.absorbOverlay:SetParent(healthBar)

    local overlayOffset = offset
    local overlayWidth = totalAbsorb / maxHealth * totalWidth

    if (currentHealth + totalAbsorb) > maxHealth then
        -- **Absorb exceeds max health → overlay moves backward onto health**
        local overAbsorb = (currentHealth + totalAbsorb) - maxHealth
        local overAbsorbWidth = overAbsorb / maxHealth * totalWidth

        overlayWidth = overlayWidth + overAbsorbWidth
        overlayOffset = offset - overAbsorbWidth
    end

    frame.absorbOverlay:SetPoint("TOPLEFT", healthBar, "TOPLEFT", math.max(overlayOffset, 0), 0)
    frame.absorbOverlay:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", math.max(overlayOffset, 0), 0)
    frame.absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
    frame.absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
    frame.absorbOverlay:SetWidth(math.min(overlayWidth, totalWidth)) -- Ensure it doesn't exceed total width
    frame.absorbOverlay:SetTexCoord(0, frame.absorbOverlay:GetWidth() / frame.absorbOverlay.tileSize, 0, 1)
    frame.absorbOverlay:Show()

    -- **Absorb Glow - attaches left when absorb exceeds max HP**
    frame.absorbGlow:ClearAllPoints()
    if (currentHealth + totalAbsorb) > maxHealth then
        -- Over-absorbing → Glow appears on the left side
        frame.absorbGlow:SetPoint("TOPLEFT", frame.absorbOverlay, "TOPLEFT", -4, 1)
        frame.absorbGlow:SetPoint("BOTTOMLEFT", frame.absorbOverlay, "BOTTOMLEFT", -4, -1)
    else
        -- Normal absorb → Glow on the right
        frame.absorbGlow:SetPoint("TOPRIGHT", frame.absorbOverlay, "TOPRIGHT", 6, 1)
        frame.absorbGlow:SetPoint("BOTTOMRIGHT", frame.absorbOverlay, "BOTTOMRIGHT", 6, -1)
        frame.absorbOverlay:SetPoint("TOPRIGHT", frame.absorbBar, "TOPRIGHT", 0, 0)
        frame.absorbOverlay:SetPoint("BOTTOMRIGHT", frame.absorbBar, "BOTTOMRIGHT", 0, 0)
    end
    frame.absorbBar:SetTexCoord(0, 1, 0, 1)
    frame.absorbGlow:Show()
end

local validUnits = {
    ["player"] = true,
    ["target"] = true,
    ["focus"] = true,
}

-- Add party units (party1 to party5)
for i = 1, 5 do
    validUnits["party" .. i] = true
end

-- Add raid units (raid1 to raid40)
for i = 1, 40 do
    validUnits["raid" .. i] = true
end

function BBF.UpdateValidUnits()
    local ufEnabled = BetterBlizzFramesDB.overShieldsUnitFrames
    local cufEnabled = BetterBlizzFramesDB.overShieldsCompactUnitFrames

    -- Update standard unit frames
    if ufEnabled then
        CataAbsorb.unitFrames["player"] = PlayerFrame
        CataAbsorb.unitFrames["target"] = TargetFrame
        CataAbsorb.unitFrames["focus"] = FocusFrame
    else
        CataAbsorb.unitFrames["player"] = nil
        CataAbsorb.unitFrames["target"] = nil
        CataAbsorb.unitFrames["focus"] = nil
    end

    -- Update compact unit frames (raid)
    for i = 1, 40 do
        local unitID = "raid" .. i
        validUnits[unitID] = cufEnabled and true or nil

        -- if cufEnabled then
        --     CataAbsorb.compactUnitFrames[unitID] = _G["CompactRaidFrame" .. i] or nil
        -- else
        --     CataAbsorb.compactUnitFrames[unitID] = nil
        -- end
    end
end

local function UnitValid(unit)
    return unit and UnitExists(unit)-- and (unit == "player" or unit == "target" or unit == "focus" or UnitInParty(unit) or UnitInRaid(unit))
end

local function SetupState(allstates, unit, absorb)
    if absorb > 0 then
        local maxHealth = UnitHealthMax(unit)
        local health = UnitHealth(unit)
        local healthPercent = health / maxHealth
        local healthDeficitPercent = 1.0 - healthPercent
        local absorbPercent = absorb / maxHealth

        if healthPercent < 1.0 and absorbPercent > healthDeficitPercent then
            if absorbPercent < 2 * healthDeficitPercent then
                absorbPercent = healthDeficitPercent
            else
                absorbPercent = absorbPercent - healthDeficitPercent
            end
        end

        allstates[unit] = {
            unit = unit,
            name = unit,
            value = absorbPercent * 100,
            total = 100,
            show = true,
            changed = true,
            healthPercent = healthPercent,
        }
    else
        allstates[unit] = {
            show = false,
            changed = true,
        }
    end
end

local function ResetAll(allstates)
    for _, state in pairs(allstates) do
        state.show = false
        state.changed = true
    end
end

local function RosterUpdated(allstates)
    for unit, state in pairs(allstates) do
        if not UnitValid(unit) then
            state.show = false
            state.changed = true
        end
    end
end

local function RefreshUnit(allstates, unit, absorbValue)
    if not UnitValid(unit) then return end

    -- Use the provided absorb value if available; otherwise, compute it
    local absorb = absorbValue or ComputeAbsorb(unit)
    SetupState(allstates, unit, absorb)

    local unitFrames = CataAbsorb.unitFrames
    local compactUnitFrames = CataAbsorb.compactUnitFrames
    local framesToUpdate = {}

    -- Always update the direct unit frame
    if unitFrames[unit] then
        table.insert(framesToUpdate, unitFrames[unit])
    end

    if compactUnitFrames[unit] then
        table.insert(framesToUpdate, compactUnitFrames[unit])
    end

    -- Iterate through the list and update all relevant frames
    for _, frame in ipairs(framesToUpdate) do
        if frame then
            UpdateAbsorbOnFrame(unit, frame, absorb)  -- Pass the cached absorb value
        end
    end
end

local relevantUnits = {}

local function UpdateRelevantUnits()
    relevantUnits = {}

    local function AddUnit(unit)
        local name = UnitName(unit)
        if name then
            relevantUnits[name] = relevantUnits[name] or {} -- Ensure it's a table
            table.insert(relevantUnits[name], unit)
        end
    end

    -- Add main units
    AddUnit("player")
    AddUnit("target")
    AddUnit("focus")

    -- Add party units (party1-4)
    for i = 1, 4 do
        if not UnitExists("party" .. i) then break end
        AddUnit("party" .. i)
    end

    -- Add raid units (raid1-40)
    for i = 1, 40 do
        if not UnitExists("raid" .. i) then break end
        AddUnit("raid" .. i)
    end
end

local auraEvents = {
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_AURA_REFRESH"] = true,
    ["SPELL_AURA_REMOVED"] = true,
    ["SPELL_ABSORBED"] = true,
}

local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ResetAll(CataAbsorb.allstates)
        UpdateRelevantUnits()
        RefreshUnit(CataAbsorb.allstates, "player")
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateRelevantUnits()
        RosterUpdated(CataAbsorb.allstates)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = select(1, ...)
        if validUnits[unit] then
            RefreshUnit(CataAbsorb.allstates, unit)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
        if not auraEvents[subEvent] then return end
        if destName then
            destName = Ambiguate(destName, "short")
            local units = relevantUnits[destName]  -- This is now a table containing multiple units
            if units then
                local computedAbsorbs = {}  -- Store absorb calculations to prevent duplicate calls
                for _, unit in ipairs(units) do
                    if not computedAbsorbs[unit] then
                        computedAbsorbs[unit] = ComputeAbsorb(unit)  -- Compute once per unit
                    end
                    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" or subEvent == "SPELL_AURA_REMOVED" then
                        local spellId = select(12, CombatLogGetCurrentEventInfo())
                        if not CataAbsorb.spells[spellId] then return end
                        RefreshUnit(CataAbsorb.allstates, unit, computedAbsorbs[unit])
                    elseif subEvent == "SPELL_ABSORBED" then
                        RefreshUnit(CataAbsorb.allstates, unit)
                    end
                end
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateRelevantUnits()
        RefreshUnit(CataAbsorb.allstates, "target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        UpdateRelevantUnits()
        RefreshUnit(CataAbsorb.allstates, "focus")
    end
end

local overshieldSetup = false
function BBF.HookOverShields()
    if BetterBlizzFramesDB.overShields and not overshieldSetup then
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
        -- frame:RegisterUnitEvent("UNIT_HEALTH", "player", "party", "raid", "focus", "target") --4max
        -- frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player", "party", "raid", "focus", "target")
        frame:RegisterEvent("UNIT_HEALTH")
        frame:RegisterEvent("UNIT_MAXHEALTH")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        frame:SetScript("OnEvent", OnEvent)

        overshieldSetup = true

        BBF.UpdateValidUnits()
    end
end

-- Initialize allstates
CataAbsorb.allstates = {}