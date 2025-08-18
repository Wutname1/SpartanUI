function BBF.CombatIndicator(unitFrame, unit)
    if not BetterBlizzFramesDB.combatIndicator or not unitFrame then return end

    local settingsPrefix = unit --== "player" and "player" or "target"
    local combatIndicatorOn = BetterBlizzFramesDB[settingsPrefix .. "CombatIndicator"]
    if not combatIndicatorOn then return end

    local xPos = BetterBlizzFramesDB.combatIndicatorXPos - 20
    local yPos = BetterBlizzFramesDB.combatIndicatorYPos
    local mainAnchor = BetterBlizzFramesDB.combatIndicatorAnchor
    local reverseAnchor = BBF.GetOppositeAnchor(mainAnchor)
    local inCombat = UnitAffectingCombat(unit)
    local inInstance, instanceType = IsInInstance()
    local darkModeOn = BetterBlizzFramesDB.darkModeUi
    local vertexColor = darkModeOn and BetterBlizzFramesDB.darkModeColor or 1

    if not unitFrame.combatParent then
        unitFrame.combatParent = CreateFrame("Frame", nil, unitFrame, "BackdropTemplate")
        unitFrame.combatParent:SetSize(32, 32)
        unitFrame.combatParent:SetPoint("CENTER", unitFrame, "CENTER", xPos, yPos)
        unitFrame.combatParent:SetFrameStrata("HIGH")

        -- Create the combat indicator texture within the parent frame
        unitFrame.combatIndicator = unitFrame.combatParent:CreateTexture(nil, "OVERLAY")
        unitFrame.combatIndicator:SetSize(32, 32)
        unitFrame.combatIndicator:SetPoint("CENTER", unitFrame.combatParent, "CENTER")

        -- Create the border within the parent frame
        local border = CreateFrame("Frame", nil, unitFrame.combatParent, "BackdropTemplate")
        border:SetBackdrop({
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tileEdge = true,
            edgeSize = 8,
        })
        border:SetPoint("TOPLEFT", unitFrame.combatIndicator, "TOPLEFT", -1.5, 1.5)
        border:SetPoint("BOTTOMRIGHT", unitFrame.combatIndicator, "BOTTOMRIGHT", 1.5, -1.5)
        border:SetFrameLevel(unitFrame.combatParent:GetFrameLevel() + 1)
        unitFrame.combatIndicator.border = border
    end

    if darkModeOn then
        unitFrame.combatIndicator:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        unitFrame.combatIndicator.border:SetBackdropBorderColor(vertexColor, vertexColor, vertexColor)
        unitFrame.combatIndicator.border:SetAlpha(0)
    else
        unitFrame.combatIndicator:SetTexCoord(0, 1, 0, 1)
        unitFrame.combatIndicator.border:SetAlpha(0)
    end

    unitFrame.combatIndicator:ClearAllPoints()

    if unitFrame == PlayerFrame then
        xPos = xPos * -1 -- invert the xPos value for PlayerFrame
    end
    if mainAnchor == "LEFT" then
        if unitFrame == TargetFrame or unitFrame == FocusFrame then
            xPos = xPos + 38.5
            yPos = yPos - 6.5
        else
            xPos = xPos - 35
            yPos = yPos - 7
        end
    end

    if unitFrame == PlayerFrame then
        if mainAnchor == "TOP" or mainAnchor == "BOTTOM" then
            unitFrame.combatIndicator:SetPoint(reverseAnchor, unitFrame, mainAnchor, xPos - 3, yPos)
        else
            unitFrame.combatIndicator:SetPoint(mainAnchor, unitFrame, reverseAnchor, xPos - 3, yPos)
        end
    else
        unitFrame.combatIndicator:SetPoint(reverseAnchor, unitFrame, mainAnchor, xPos, yPos)
    end
    unitFrame.combatIndicator:SetScale(BetterBlizzFramesDB.combatIndicatorScale)



    -- Conditions to check before showing textures
    if BetterBlizzFramesDB.combatIndicatorArenaOnly and not (inInstance and instanceType == "arena") then
        unitFrame.combatIndicator:SetAlpha(0)
        return
    end

    if BetterBlizzFramesDB.combatIndicatorPlayersOnly and not UnitIsPlayer(unit) then
        unitFrame.combatIndicator:SetAlpha(0)
        return
    end

    -- Show or hide textures based on combat status
    if inCombat then
        if BetterBlizzFramesDB.combatIndicatorShowSwords then
            unitFrame.combatIndicator:SetTexture("Interface\\Icons\\ABILITY_DUALWIELD")
            unitFrame.combatIndicator:SetAlpha(1)
            if unitFrame.combatIndicator:IsVisible() and darkModeOn then
                unitFrame.combatIndicator.border:SetAlpha(1)
            end
        else
            unitFrame.combatIndicator:SetAlpha(0)
        end
    else
        if BetterBlizzFramesDB.combatIndicatorShowSap then
            unitFrame.combatIndicator:SetTexture("Interface\\Icons\\Ability_Sap")
            unitFrame.combatIndicator:SetAlpha(1)
            if unitFrame.combatIndicator:IsVisible() and darkModeOn then
                unitFrame.combatIndicator.border:SetAlpha(1)
            end
        else
            unitFrame.combatIndicator:SetAlpha(0)
        end
    end
end



function BBF.CombatIndicatorCaller()
    BBF.CombatIndicator(TargetFrame, "target")
    BBF.CombatIndicator(FocusFrame, "focus")
    BBF.CombatIndicator(PlayerFrame, "player")
    local combatIndicators = {
        { frame = TargetFrame, setting = "targetCombatIndicator" },
        { frame = PlayerFrame, setting = "playerCombatIndicator" },
        { frame = FocusFrame, setting = "focusCombatIndicator" },
    }

    for _, data in pairs(combatIndicators) do
        local frame, setting = data.frame, data.setting
        if frame and frame.combatIndicator then
            if not BetterBlizzFramesDB[setting] or not BetterBlizzFramesDB.combatIndicator then
                frame.combatIndicator:SetAlpha(0)
                if frame.combatIndicator.border then
                    frame.combatIndicator.border:SetAlpha(0)
                end
            end
        end
    end
    --BBF:UpdateCombatBorder()
end



local raceIcons = {
    [2] = { -- Orc
        [2] = "raceicon-orc-male",
        [3] = "raceicon-orc-female",
    },
    [4] = { -- Night Elf
        [2] = "raceicon-nightelf-male",
        [3] = "raceicon-nightelf-female",
    },
    [5] = { -- Undead (Scourge)
        [2] = "raceicon-undead-male",
        [3] = "raceicon-undead-female",
    },
    [1] = { -- Human
        [2] = "raceicon-human-male",
        [3] = "raceicon-human-female",
    },
    [3] = { -- Dwarf
        [2] = "raceicon-dwarf-male",
        [3] = "raceicon-dwarf-female",
    },
    [34] = { -- Dark Iron Dwarf
        [2] = "raceicon-darkirondwarf-male",
        [3] = "raceicon-darkirondwarf-female",
    },
}

local raceSpellIcons = {
    [2] = "Interface\\Icons\\inv_helmet_23",              -- Orc
    [4] = "Interface\\Icons\\ability_ambush",             -- Night Elf
    [5] = "Interface\\Icons\\spell_shadow_raisedead",     -- Undead
    [1] = "Interface\\Icons\\spell_shadow_charm",         -- Human
    [3] = 136225,                                         -- Dwarf
    [34] = 1786406,                                       -- Dark Iron Dwarf
}

function BBF.RacialIndicator(unitFrame, unit)
    if not unitFrame or not BetterBlizzFramesDB.racialIndicator then return end

    local settingsPrefix = unit --== "player" and "player" or "target"
    local racialIndicatorOn = BetterBlizzFramesDB[settingsPrefix .. "RacialIndicator"]
    if not racialIndicatorOn then return end

    local xPos = BetterBlizzFramesDB.racialIndicatorXPos + 26
    local yPos = BetterBlizzFramesDB.racialIndicatorYPos + 20
    local scale = BetterBlizzFramesDB.racialIndicatorScale

    local showOrc = BetterBlizzFramesDB.racialIndicatorOrc
    local showNelf = BetterBlizzFramesDB.racialIndicatorNelf
    local showUndead = BetterBlizzFramesDB.racialIndicatorUndead
    local showHuman = BetterBlizzFramesDB.racialIndicatorHuman
    local showDwarf = BetterBlizzFramesDB.racialIndicatorDwarf
    local showDarkIronDwarf = BetterBlizzFramesDB.racialIndicatorDarkIronDwarf

    local darkModeOn = BetterBlizzFramesDB.darkModeUi
    local vertexColor = darkModeOn and BetterBlizzFramesDB.darkModeColor or 1
    local raceOverSpells = BetterBlizzFramesDB.racialIndicatorRaceIcons

    local _, _, raceID = UnitRace(unit)
    local unitSex = UnitSex(unit)

    -- Optional: simple booleans if needed for logic elsewhere
    local isOrc = raceID == 2
    local isNelf = raceID == 4
    local isUndead = raceID == 5
    local isHuman = raceID == 1
    local isDwarf = raceID == 3
    local isDarkIronDwarf = raceID == 34

    local raceIcon = (raceOverSpells and raceIcons[raceID] and raceIcons[raceID][unitSex or 2]) or raceSpellIcons[raceID]
    local shouldShow =
        (isOrc and showOrc) or
        (isNelf and showNelf) or
        (isUndead and showUndead) or
        (isHuman and showHuman) or
        (isDwarf and showDwarf) or
        (isDarkIronDwarf and showDarkIronDwarf)

    if not unitFrame.racialIndicator then
        unitFrame.racialIndicator = CreateFrame("Frame", nil, unitFrame, "BackdropTemplate")
        unitFrame.racialIndicator:SetSize(20, 20)
        unitFrame.racialIndicator:SetPoint("CENTER", unitFrame, "CENTER", 23, 21)
        unitFrame.racialIndicator:SetFrameStrata("HIGH")

        unitFrame.racialIndicator.icon = unitFrame.racialIndicator:CreateTexture(nil, "OVERLAY")
        unitFrame.racialIndicator.icon:SetAllPoints(unitFrame.racialIndicator)

        unitFrame.racialIndicator.mask = unitFrame.racialIndicator:CreateMaskTexture()
        unitFrame.racialIndicator.mask:SetTexture("Interface/Masks/CircleMaskScalable")
        unitFrame.racialIndicator.mask:SetSize(20, 20)
        unitFrame.racialIndicator.mask:SetPoint("CENTER", unitFrame.racialIndicator.icon)

        unitFrame.racialIndicator.icon:AddMaskTexture(unitFrame.racialIndicator.mask)

        unitFrame.racialIndicator.border = unitFrame.racialIndicator:CreateTexture(nil, "OVERLAY")
        unitFrame.racialIndicator.border:SetAtlas("ui-frame-genericplayerchoice-portrait-border")
        unitFrame.racialIndicator.border:SetAllPoints(unitFrame.racialIndicator)
        unitFrame.racialIndicator.border:SetDesaturated(true)
--[[
        -- Create the border within the parent frame
        local border = CreateFrame("Frame", nil, unitFrame.racialIndicator, "BackdropTemplate")
        border:SetBackdrop({
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tileEdge = true,
            edgeSize = 8,
        })
        border:SetPoint("TOPLEFT", unitFrame.racialIndicator.icon, "TOPLEFT", -1.5, 1.5)
        border:SetPoint("BOTTOMRIGHT", unitFrame.racialIndicator.icon, "BOTTOMRIGHT", 1.5, -1.5)
        border:SetFrameLevel(unitFrame.racialIndicator:GetFrameLevel() + 1)
        unitFrame.racialIndicator.border = border

]]
    end

    unitFrame.racialIndicator:SetPoint("CENTER", unitFrame, "CENTER", xPos, yPos)
    unitFrame.racialIndicator:SetScale(scale)

    if darkModeOn then
        unitFrame.racialIndicator.border:SetVertexColor(vertexColor, vertexColor, vertexColor)
    else
        unitFrame.racialIndicator.border:SetVertexColor(1, 1, 0)
    end

    if raceIcon then
        if raceOverSpells then
            unitFrame.racialIndicator.icon:SetAtlas(raceIcon)
        else
            unitFrame.racialIndicator.icon:SetTexture(raceIcon)
        end
    end

    if shouldShow then
        unitFrame.racialIndicator:SetAlpha(1)
        --unitFrame.racialIndicator.border:SetAlpha(1)
    else
        unitFrame.racialIndicator:SetAlpha(0)
        --unitFrame.racialIndicator.border:SetAlpha(0)
    end
end

function BBF.RacialIndicatorCaller()
    BBF.RacialIndicator(TargetFrame, "target")
    BBF.RacialIndicator(FocusFrame, "focus")
    if not BetterBlizzFramesDB.racialIndicator then
        if TargetFrame.racialIndicator then TargetFrame.racialIndicator:SetAlpha(0) end
        if FocusFrame.racialIndicator then FocusFrame.racialIndicator:SetAlpha(0) end
    end
    if not BetterBlizzFramesDB.targetRacialIndicator then
        if TargetFrame.racialIndicator then TargetFrame.racialIndicator:SetAlpha(0) end
    end
    if not BetterBlizzFramesDB.focusRacialIndicator then
        if FocusFrame.racialIndicator then FocusFrame.racialIndicator:SetAlpha(0) end
    end
end



local unitFrameMap = {
    player = PlayerFrame,
    target = TargetFrame,
    focus = FocusFrame
}

local function updateIndicators(frame, unit)
    BBF.CombatIndicator(frame, unit)
    BBF.RacialIndicator(frame, unit)
end

local function UpdateCombatIndicator(self, event, unit)
    if event == "UNIT_FLAGS" then
        local frame = unitFrameMap[unit]
        if frame then
            --updateIndicators(frame, unit)
            BBF.CombatIndicator(frame, unit)
        end
    else
        for unit, frame in pairs(unitFrameMap) do
            updateIndicators(frame, unit)
        end
    end
end

local combatIndicatorFrame = CreateFrame("Frame")
combatIndicatorFrame:SetScript("OnEvent", UpdateCombatIndicator)
combatIndicatorFrame:RegisterUnitEvent("UNIT_FLAGS", "player", "target", "focus")
combatIndicatorFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
combatIndicatorFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
combatIndicatorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")