local specIDToName = {
    -- Death Knight
    [250] = "Blood", [251] = "Frost", [252] = "Unholy",
    -- Demon Hunter
    [577] = "Havoc", [581] = "Vengeance",
    -- Druid
    [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Restoration",
    -- Evoker
    [1467] = "Devastation", [1468] = "Preservation", [1473] = "Augmentation",
    -- Hunter
    [253] = "Beast Mastery", [254] = "Marksmanship", [255] = "Survival",
    -- Mage
    [62] = "Arcane", [63] = "Fire", [64] = "Frost",
    -- Monk
    [268] = "Brewmaster", [270] = "Mistweaver", [269] = "Windwalker",
    -- Paladin
    [65] = "Holy", [66] = "Protection", [70] = "Retribution",
    -- Priest
    [256] = "Discipline", [257] = "Holy", [258] = "Shadow",
    -- Rogue
    [259] = "Assassination", [260] = "Outlaw", [261] = "Subtlety",
    -- Shaman
    [262] = "Elemental", [263] = "Enhancement", [264] = "Restoration",
    -- Warlock
    [265] = "Affliction", [266] = "Demonology", [267] = "Destruction",
    -- Warrior
    [71] = "Arms", [72] = "Fury", [73] = "Protection",
}

local specIDToNameShort = {
    -- Death Knight
    [250] = "Blood", [251] = "Frost", [252] = "Unholy",
    -- Demon Hunter
    [577] = "Havoc", [581] = "Vengeance",
    -- Druid
    [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Resto",
    -- Evoker
    [1467] = "Dev", [1468] = "Pres", [1473] = "Aug",
    -- Hunter
    [253] = "BM", [254] = "Marksman", [255] = "Survival",
    -- Mage
    [62] = "Arcane", [63] = "Fire", [64] = "Frost",
    -- Monk
    [268] = "Brewmaster", [270] = "Mistweaver", [269] = "Windwalker",
    -- Paladin
    [65] = "Holy", [66] = "Prot", [70] = "Ret",
    -- Priest
    [256] = "Disc", [257] = "Holy", [258] = "Shadow",
    -- Rogue
    [259] = "Assa", [260] = "Outlaw", [261] = "Sub",
    -- Shaman
    [262] = "Ele", [263] = "Enha", [264] = "Resto",
    -- Warlock
    [265] = "Aff", [266] = "Demo", [267] = "Destro",
    -- Warrior
    [71] = "Arms", [72] = "Fury", [73] = "Prot",
}

local hidePartyNames
local hidePartyRoles
local removeRealmNames
local classColorFrames
local classColorTargetNames
local showSpecName
local shortArenaSpecName
local showArenaID
local targetAndFocusArenaNames
local partyArenaNames
local hideTargetName
local hideFocusName
local hideTargetToTName
local hideFocusToTName
local classColorLevelText
local centerNames
local playerFrameOCD
local playerFrameOCDTextureBypass
local hidePlayerName
local hidePetName
local isAddonLoaded = C_AddOns.IsAddOnLoaded
local changeUnitFrameFont
local targetAndFocusArenaNamePartyOverride
local classicFramesMode
local rpNames
local rpNamesFirst
local rpNamesLast
local rpNamesColor
local showLastNameNpc

local function GetRPNameColor(unit)
    if not UnitExists(unit) then return end
    if not TRP3_API.globals.player_realm_id then return end
    local player = AddOn_TotalRP3 and AddOn_TotalRP3.Player and AddOn_TotalRP3.Player.CreateFromUnit(unit)
    if player then
        local color = player:GetCustomColorForDisplay()
        if color then
            local r, g, b = color:GetRGB()
            return r, g, b
        end
    end
end

local function SetRPName(name, unit)
    if not TRP3_API.globals.player_realm_id then return end
    local fullName = TRP3_API.r.name(unit) or ""
    local firstRpName, lastRpName = fullName:match("^(%S+)%s*(.*)$")

    if rpNamesFirst and rpNamesLast then
        name:SetText(fullName)
    elseif rpNamesFirst then
        name:SetText(firstRpName or fullName)
    elseif rpNamesLast then
        name:SetText(lastRpName ~= "" and lastRpName or fullName)
    else
        name:SetText(fullName)
    end
end

function BBF.UpdateUserTargetSettings()
    hidePartyNames = BetterBlizzFramesDB.hidePartyNames
    hidePartyRoles = BetterBlizzFramesDB.hidePartyRoles
    removeRealmNames = BetterBlizzFramesDB.removeRealmNames
    classColorFrames = BetterBlizzFramesDB.classColorFrames
    classColorTargetNames = BetterBlizzFramesDB.classColorTargetNames
    showSpecName = BetterBlizzFramesDB.showSpecName
    shortArenaSpecName = BetterBlizzFramesDB.shortArenaSpecName
    showArenaID = BetterBlizzFramesDB.showArenaID
    targetAndFocusArenaNames = BetterBlizzFramesDB.targetAndFocusArenaNames
    partyArenaNames = BetterBlizzFramesDB.partyArenaNames
    hideTargetName = BetterBlizzFramesDB.hideTargetName
    hideFocusName = BetterBlizzFramesDB.hideFocusName
    hideTargetToTName = BetterBlizzFramesDB.hideTargetToTName
    hideFocusToTName = BetterBlizzFramesDB.hideFocusToTName
    classColorLevelText = BetterBlizzFramesDB.classColorTargetNames and BetterBlizzFramesDB.classColorLevelText
    centerNames = BetterBlizzFramesDB.centerNames or BetterBlizzFramesDB.classicFrames
    classicFramesMode = BetterBlizzFramesDB.classicFrames
    playerFrameOCD = BetterBlizzFramesDB.playerFrameOCD and not BetterBlizzFramesDB.playerFrameOCDTextureBypass
    playerFrameOCDTextureBypass = BetterBlizzFramesDB.playerFrameOCDTextureBypass
    hidePlayerName = BetterBlizzFramesDB.hidePlayerName
    hidePetName = BetterBlizzFramesDB.hidePetName
    changeUnitFrameFont = BetterBlizzFramesDB.changeUnitFrameFont
    targetAndFocusArenaNamePartyOverride = BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride
    rpNames = BetterBlizzFramesDB.rpNames
    rpNamesFirst = BetterBlizzFramesDB.rpNamesFirst
    rpNamesLast = BetterBlizzFramesDB.rpNamesLast
    rpNamesColor = BetterBlizzFramesDB.rpNamesColor
    showLastNameNpc = BetterBlizzFramesDB.showLastNameNpc
end

local function CenterPlayerName()
    local healthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer
    local name = PlayerFrame.bbfName
    name:SetJustifyH("CENTER")
    name:SetJustifyV(PlayerName:GetJustifyV())
    name:ClearAllPoints()
    if playerFrameOCD and not classicFramesMode then
        name:SetPoint("TOP", healthBar, "TOP", 0, 14.5)
    else
        local xPos = classicFramesMode and 1.5 or true and -2 or 0
        local yPos = classicFramesMode and 7.5 or BetterBlizzFramesDB.symmetricPlayerFrame and 15 or 14.5
        name:SetPoint("TOP", healthBar, "TOP", xPos, yPos)
    end
end

local function CenterXName(fontObject, healthBar, ToT, pet)
    fontObject:ClearAllPoints()
    if not (classicFramesMode and ToT) then
        fontObject:SetJustifyH("CENTER")
    end
    local xPos = ToT and (classicFramesMode and 8 or -2) or (classicFramesMode and 0) or 2
    local yPos = ((pet and classicFramesMode) and 2 or pet and 2) or ToT and (classicFramesMode and -18 or 12) or (classicFramesMode and 6.3 or 14)
    fontObject:SetPoint(pet and "BOTTOM" or "TOP", healthBar, "TOP", xPos, yPos)
end



function BBF.SetCenteredNamesCaller()
    if isAddonLoaded("ClassicFrames") then
        return
    end
    BBF.UpdateUserTargetSettings()
    if not centerNames then return end
    CenterPlayerName()
    CenterXName(TargetFrame.bbfName, TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer)
    CenterXName(FocusFrame.bbfName, FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer)
    CenterXName(TargetFrameToT.bbfName, TargetFrame.totFrame.HealthBar, true)
    CenterXName(FocusFrameToT.bbfName, FocusFrame.totFrame.HealthBar, true)
    C_Timer.After(0, function() --idk why but this wont update unless delayed a frame
        CenterXName(PetFrame.bbfName, PetFrameHealthBar, true, true)
    end)
end

local function GetLocalizedSpecs()
    local specs = {}

    for classID = 1, GetNumClasses() do
        local _, class = GetClassInfo(classID)
        local classMale = LOCALIZED_CLASS_NAMES_MALE[class]
        local classFemale = LOCALIZED_CLASS_NAMES_FEMALE[class]

        for specIndex = 1, GetNumSpecializationsForClassID(classID) do
            local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)

            if classMale then
                specs[string.format("%s %s", specName, classMale)] = specID
            end
            if classFemale and classFemale ~= classMale then
                specs[string.format("%s %s", specName, classFemale)] = specID
            end
        end
    end

    return specs
end

-- Store all specs in a lookup table
local ALL_SPECS = GetLocalizedSpecs()

-- Caching Tables
BBA.SpecCache = {}
local SpecCache = BBA.SpecCache  -- Stores GUID -> specID
local GetUnitTooltip = C_TooltipInfo.GetUnit

-- Function to retrieve the specialization ID of a unit
local function GetSpecID(unit)
    -- Check if the unit is a player
    if not UnitIsPlayer(unit) then
        return nil
    end

    local guid = UnitGUID(unit)

    -- Return cached specID if already found
    if SpecCache[guid] then
        return SpecCache[guid]
    end

    -- Fetch tooltip data
    local tooltipData = GetUnitTooltip(unit)
    if not tooltipData or not tooltipData.guid or not tooltipData.lines then
        return nil
    end

    local tooltipGUID = tooltipData.guid

    -- Iterate through tooltip lines to find the spec name
    for _, line in ipairs(tooltipData.lines) do
        if line and line.type == Enum.TooltipDataLineType.None and line.leftText and line.leftText ~= "" then
            local specID = ALL_SPECS[line.leftText]
            if specID then
                SpecCache[tooltipGUID] = specID -- Cache result
                return specID
            end
        end
    end

    return nil -- Return nil if no spec ID was found
end
BBF.GetSpecID = GetSpecID

local HEALER_SPEC_IDS = {
    [105] = true,  -- Restoration Druid
    [264] = true,  -- Restoration Shaman
    [270] = true,  -- Mistweaver Monk
    [257] = true,  -- Holy Priest
    [65] = true,   -- Holy Paladin
    [256] = true,  -- Discipline Priest
    [1468] = true, -- Preservation Evoker
}

local function IsSpecHealer(unit)
    -- Check if the unit is a player first (avoid processing NPCs)
    if not UnitIsPlayer(unit) then
        return false
    end

    -- Use cached spec ID if available
    local specID = GetSpecID(unit)

    -- If no valid spec ID found, return false
    if not specID then
        return false
    end

    -- Check if spec is a healer (direct lookup)
    return HEALER_SPEC_IDS[specID] or false
end
BBF.IsSpecHealer = IsSpecHealer

local function GetSpecName(unit)
    local specID = GetSpecID(unit)
    return specID and (shortArenaSpecName and specIDToNameShort[specID] or specIDToName[specID]) or nil
end

function BBF.HealerPortrait()
    hooksecurefunc("UnitFramePortrait_Update", function(self)
        if self.unit ~= "player" then
            if IsSpecHealer(self.unit) then
                SetPortraitTexture(self.portrait, "player")
            end
        end
    end)
end

local function ShowLastNameOnlyNpc(frame, name)
    if not name then return end
    local creatureType = frame.unit and UnitCreatureType(frame.unit)
    if creatureType == "Totem" then
        -- Use first word (e.g., "Stoneclaw" from "Stoneclaw Totem")
        local firstWord = name:match("^[^%s%-]+")
        return firstWord
    else
        -- Use last word (e.g., "Guardian" from "Frostwolf Guardian")
        local lastWord = name:match("([^%s]+)$")
        return lastWord
    end
end

local function GetNameWithoutRealm(frame)
    local name = GetUnitName(frame.unit)
    if name then
        if showLastNameNpc and not UnitIsPlayer(frame.unit) then
            local lastName = ShowLastNameOnlyNpc(frame, name)
            return lastName
        else
            name = string.gsub(name, " %(%*%)$", "")
            return name
        end
    end
    return nil
end

local function SetArenaName(frame, unit, textObject)
    if UnitIsUnit(unit, "player") then return end
    local specName = GetSpecName(unit)
    local nameText
    local partyID = UnitIsUnit(unit, "party1") and " 1" or " 2"

    if specName then
        if showSpecName and showArenaID then
            nameText = specName .. partyID
        elseif showSpecName then
            nameText = specName
        elseif showArenaID then
            nameText = "Party" .. partyID
        end
    else
        nameText = showArenaID and "Party" .. partyID or removeRealmNames and GetNameWithoutRealm(frame)
    end

    if nameText then
        textObject:SetText(nameText)
    end
end

function BBF.PartyNameChange()
    if EditModeManagerFrame:UseRaidStylePartyFrames() then
        for i = 1, 3 do
            local memberFrame = _G["CompactPartyFrameMember" .. i]
            if memberFrame and memberFrame.displayedUnit then
                SetArenaName(memberFrame, memberFrame.displayedUnit, memberFrame.name)
            end
        end
    else
        for i = 1, 4 do
            local memberFrame = PartyFrame["MemberFrame" .. i]
            if memberFrame and memberFrame.unit then
                SetArenaName(memberFrame, memberFrame.unit, memberFrame.bbfName)
            end
        end
    end
end

local function IsInArena()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == "arena"
end

local UpdatePartyNames = CreateFrame("Frame")
UpdatePartyNames:RegisterEvent("PLAYER_ENTERING_WORLD")
UpdatePartyNames:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
UpdatePartyNames:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" then
        SpecCache = {}
        if IsInArena() then
            if not self:IsEventRegistered("GROUP_ROSTER_UPDATE") then
                self:RegisterEvent("GROUP_ROSTER_UPDATE")
            end
        else
            self:UnregisterEvent("GROUP_ROSTER_UPDATE")
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if partyArenaNames and IsInArena() then
            for delay = 0, 8 do
                C_Timer.After(delay, BBF.PartyNameChange)
            end
        end
    end
end)





local function CompactPartyFrameNameChanges(frame)
    if not frame or not frame.unit then return end
    if frame.unit:find("nameplate") then return end
    if partyArenaNames and IsActiveBattlefieldArena() then
        SetArenaName(frame, frame.unit, frame.name)
        return
    end
    if hidePartyNames then
        frame.name:SetText("")
        return
    end
    if TRP3_API and rpNames then

        SetRPName(frame.name, frame.unit)

        if rpNamesColor then
            local r,g,b = GetRPNameColor(frame.unit)
            if r then
                frame.name:SetTextColor(r, g, b)
                frame.name.recolored = true
                return
            elseif frame.name.recolored then
                frame.name:SetTextColor(1, 0.82, 0)
                frame.name.recolored = nil
            end
        end
    elseif removeRealmNames then
        frame.name:SetText(GetNameWithoutRealm(frame))
    end
end

local function HideRoleIcon(frame)
    if not hidePartyRoles then return end
    if not frame.roleIcon then return end
    frame.roleIcon:SetAlpha(0)
end
local function HideRoleIconDefault(frame)
    if not hidePartyRoles then return end
    frame.PartyMemberOverlay.RoleIcon:SetAlpha(0)
end
hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", HideRoleIcon)

--hooksecurefunc("CompactUnitFrame_SetUnit", CompactPartyFrameNameChanges)
hooksecurefunc("CompactUnitFrame_UpdateName", CompactPartyFrameNameChanges)

local function PartyFrameNameChange(frame)
    if not frame or not frame.unit then return end
    frame.Name:SetAlpha(0)
    if hidePartyNames then
        frame.bbfName:SetText("")
        return
    end
    if not changeUnitFrameFont then
        frame.bbfName:SetFont(frame.Name:GetFont())
    end
    if partyArenaNames and IsActiveBattlefieldArena() then
        SetArenaName(frame, frame.unit, frame.bbfName)
        return
    end
    if TRP3_API and rpNames then

        SetRPName(frame.bbfName, frame.unit)

        if rpNamesColor then
            local r,g,b = GetRPNameColor(frame.unit)
            if r then
                frame.bbfName:SetTextColor(r, g, b)
                frame.bbfName.recolored = true
                return
            elseif frame.bbfName.recolored then
                frame.bbfName:SetTextColor(1, 0.82, 0)
                frame.bbfName.recolored = nil
            end
        end
    elseif removeRealmNames then
        frame.bbfName:SetText(GetNameWithoutRealm(frame))
    else
        frame.bbfName:SetText(frame.Name:GetText())
    end
end

if not EditModeManagerFrame:UseRaidStylePartyFrames() then
    local frames = {
        PartyFrame.MemberFrame1,
        PartyFrame.MemberFrame2,
        PartyFrame.MemberFrame3,
        PartyFrame.MemberFrame4,
    }

    for _, frame in ipairs(frames) do
        hooksecurefunc(frame.Name, "SetText", function(self)
            PartyFrameNameChange(frame)
        end)
        C_Timer.After(1, function()
            PartyFrameNameChange(frame)
        end)
    end
end






















































local function InitializeFontString(frame)
    -- Determine the original FontString based on available properties
    local name = frame.name or frame.Name
    if not name or not name:GetParent() then return end

    -- Create the new FontString on the specified frame with a fixed name "bbfName"
    frame.bbfName = name:GetParent():CreateFontString(nil, name:GetDrawLayer() or "OVERLAY", "GameFontNormal")

    -- Copy font settings
    local font, fontHeight, fontFlags = name:GetFont()
    frame.bbfName:SetFont(font, fontHeight, fontFlags)

    -- Copy alignment, color, shadow, and dimensions
    frame.bbfName:SetJustifyH(name:GetJustifyH())
    frame.bbfName:SetJustifyV(name:GetJustifyV())
    frame.bbfName:SetTextColor(name:GetTextColor())
    frame.bbfName:SetShadowColor(name:GetShadowColor())
    frame.bbfName:SetShadowOffset(name:GetShadowOffset())
    frame.bbfName:SetWidth(name:GetWidth())
    frame.bbfName:SetHeight(name:GetHeight())
    frame.bbfName:SetWordWrap(false)

    -- Copy position
    local point, relativeTo, relativePoint, xOffset, yOffset = name:GetPoint()
    if point then
        frame.bbfName:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    end

    -- Set initial text from the original FontString
    frame.bbfName:SetText(name:GetText())
    hooksecurefunc(name, "SetText", function()
        frame.bbfName:SetSize(name:GetSize())
    end)

    -- Hide original
    name:SetAlpha(0)
end

local frames = {
    PlayerFrame,
    TargetFrame,
    FocusFrame,
    TargetFrameToT,
    FocusFrameToT,
    PartyFrame.MemberFrame1,
    PartyFrame.MemberFrame2,
    PartyFrame.MemberFrame3,
    PartyFrame.MemberFrame4,
    PetFrame,
}

local function InitializeFontStringsForFrames()
    -- Initialize FontStrings for each frame in the list
    for _, frame in ipairs(frames) do
        InitializeFontString(frame)
    end
end

-- Run the function to initialize font strings on all specified frames
InitializeFontStringsForFrames()




local function UpdateFontStringPosition(frame)
    local name = frame.name or frame.Name
    if not name or not name:GetParent() then return end
    local point, relativeTo, relativePoint, xOffset, yOffset = name:GetPoint()
    if point then
        if not name.bbfSetPointHook then
            hooksecurefunc(name, "SetPoint", function()
                frame.bbfName:ClearAllPoints()
                frame.bbfName:SetPoint("CENTER", name, "CENTER", 0, 0)
            end)
            hooksecurefunc(frame.bbfName, "SetPoint", function(self)
                if self.changing then return end
                self.changing = true
                self:ClearAllPoints()
                self:SetPoint("CENTER", name, "CENTER", 0, 0)
                self:SetJustifyH(name:GetJustifyH())
                self.changing = false
            end)
            frame.bbfName:ClearAllPoints()
            frame.bbfName:SetPoint("CENTER", name, "CENTER", 0, 0)
            frame.bbfName:SetJustifyH(name:GetJustifyH())

            name.bbfSetPointHook = true
        end
    end
end

local function UpdateAllFontStringPositions()
    for _, frame in ipairs(frames) do
        UpdateFontStringPosition(frame)
    end
end

C_Timer.After(1, function()
    if C_AddOns.IsAddOnLoaded("EasyFrames") then
        UpdateAllFontStringPositions()
        -- local playerName = UnitName("player")
        -- local realmName = GetRealmName()
        -- local playerNameAndRealm = playerName .. " - " .. realmName
        -- local selectedProfile = EasyFramesDB["profileKeys"][playerNameAndRealm]
        -- if EasyFramesDB["profiles"][selectedProfile] then
        --     local useEFTextures = EasyFramesDB["profiles"][selectedProfile]["general"] and EasyFramesDB["profiles"][selectedProfile]["general"].useEFTextures
        --     if centerNames and useEFTextures == false then
        --         CenterPlayerName()
        --         CenterXName(TargetFrame.bbfName, TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer)
        --         CenterXName(FocusFrame.bbfName, FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer)
        --         CenterXName(TargetFrameToT.bbfName, TargetFrame.totFrame.HealthBar, true)
        --         CenterXName(FocusFrameToT.bbfName, FocusFrame.totFrame.HealthBar, true)
        --     end
        -- end
    end
end)





local function SetPartyFont(font, size, outline, size2)
    if outline == "NONE" then
        outline = nil
    end
    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember"..i]
        if frame then
            frame.name:SetFont(font, size, outline)
            frame.bbfSetFont = true
            if frame.statusText then
                frame.statusText:SetFont(font, size2, outline)
            end
        end
    end
    for i = 1, 5 do
        local frame = _G["CompactRaidFrame"..i]
        if frame then
            frame.name:SetFont(font, size, outline)
            frame.bbfSetFont = true
            if frame.statusText then
                frame.statusText:SetFont(font, size2, outline)
            end
        end
    end
    for group = 1, 8 do
        for member = 1, 5 do
            local raidFrame = _G["CompactRaidGroup" .. group .. "Member" .. member]
            if raidFrame then
                raidFrame.name:SetFont(font, size, outline)
                if raidFrame.statusText then
                    raidFrame.statusText:SetFont(font, size2, outline)
                end
            end
        end
    end
    for i = 1, 4 do
        local partyFrameMember = _G["PartyFrame"]["MemberFrame"..i]
        if partyFrameMember then
            partyFrameMember.bbfName:SetFont(font, size, outline)
        end
        local hbc = partyFrameMember.HealthBarContainer
        local mb = partyFrameMember.ManaBar
        if hbc.LeftText then
            hbc.LeftText:SetFont(font, size2, outline)
        end
        if hbc.RightText then
            hbc.RightText:SetFont(font, size2, outline)
        end
        if hbc.TextString then
            hbc.TextString:SetFont(font, size2, outline)
        end
        if mb.LeftText then
            mb.LeftText:SetFont(font, size2, outline)
        end 
        if mb.RightText then
            mb.RightText:SetFont(font, size2, outline)
        end
        if mb.TextString then
            mb.TextString:SetFont(font, size2, outline)
        end
    end
end


local function SetUnitFramesFont(font, size, outline)
    if outline == "NONE" then
        outline = nil
    end
    for _, frame in ipairs(frames) do
        local newSize = size
        if frame == PetFrame or frame == TargetFrameToT or frame == FocusFrameToT then
            if tonumber(size) >= 13 then
                newSize = size - 3
            elseif tonumber(size) <= 10 then
                newSize = size -1
            else
                newSize = size -2
            end
        end
        frame.bbfName:SetFont(font, newSize, outline)
        if frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain.LevelText then
            local _, lvlSize = frame.TargetFrameContent.TargetFrameContentMain.LevelText:GetFont()
            frame.TargetFrameContent.TargetFrameContentMain.LevelText:SetFont(font, lvlSize, outline)
            PlayerLevelText:SetFont(font, lvlSize, outline)
        end
        frame.bbfForcedFont = true
    end
end


local playerManaBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar
local playerHealthBar = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar

local petHealthBar = PetFrame.healthbar
local petManaBar = PetFrame.manabar

local targetManaBar = TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar
local targetHealthBar = TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar

local focusManaBar = FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar
local focusHealthBar = FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar

local altBar = AlternatePowerBar
local staggerBar = MonkStaggerBar

local statusTexts = {
    playerManaBar.LeftText,
    playerManaBar.RightText,
    playerManaBar.ManaBarText,
    --
    playerHealthBar.LeftText,
    playerHealthBar.RightText,
    playerHealthBar.TextString,
    --
    petHealthBar.LeftText,
    petHealthBar.RightText,
    petHealthBar.TextString,
    --
    petManaBar.LeftText,
    petManaBar.RightText,
    petManaBar.TextString,
    --
    targetManaBar.LeftText,
    targetManaBar.RightText,
    targetManaBar.ManaBarText,
    --
    targetHealthBar.LeftText,
    targetHealthBar.RightText,
    targetHealthBar.TextString,
    --
    focusManaBar.LeftText,
    focusManaBar.RightText,
    focusManaBar.ManaBarText,
    --
    focusHealthBar.LeftText,
    focusHealthBar.RightText,
    focusHealthBar.TextString,
    --
    altBar.LeftText,
    altBar.RightText,
    altBar.TextString,
    staggerBar.LeftText,
    staggerBar.RightText,
    staggerBar.TextString,
}

local petFrames = {
    [petHealthBar.LeftText] = true,
    [petHealthBar.RightText] = true,
    [petHealthBar.TextString] = true,
    [petManaBar.LeftText] = true,
    [petManaBar.RightText] = true,
    [petManaBar.TextString] = true
}

local function SetUnitFramesValuesFont(font, size, outline)
    if isAddonLoaded("ClassicFrames") and not BBF.classicFramesText then
        -- ClassicFrames unit frame text elements
        local classicTexts = {
            CfPlayerFrameHealthBar.LeftText, CfPlayerFrameHealthBar.RightText, CfPlayerFrameHealthBar.TextString,
            CfPlayerFrameManaBar.LeftText, CfPlayerFrameManaBar.RightText, CfPlayerFrameManaBar.TextString,
            CfTargetFrameHealthBar.LeftText, CfTargetFrameHealthBar.RightText, CfTargetFrameHealthBar.TextString,
            CfTargetFrameManaBar.LeftText, CfTargetFrameManaBar.RightText, CfTargetFrameManaBar.TextString,
            CfFocusFrameHealthBar.LeftText, CfFocusFrameHealthBar.RightText, CfFocusFrameHealthBar.TextString,
            CfFocusFrameManaBar.LeftText, CfFocusFrameManaBar.RightText, CfFocusFrameManaBar.TextString,
        }

        -- Append ClassicFrames elements to statusTexts
        for _, text in ipairs(classicTexts) do
            table.insert(statusTexts, text)
        end
        BBF.classicFramesText = true
    end
    for _, textObject in ipairs(statusTexts) do
        local ogFont, ogSize, ogOutline = textObject:GetFont()

        local newFont = font or ogFont
        local newSize = size or ogSize
        local newOutline = outline or ogOutline

        if petFrames[textObject] then
            if tonumber(newSize) >= 12 then
                if tonumber(newSize) > 13 then
                    newSize = newSize - 3
                else
                    newSize = newSize - 2
                end
            else
                newSize = newSize - 1
            end
        end

        if newOutline == "NONE" then
            newOutline = nil
        end

        textObject:SetFont(newFont, newSize, newOutline)
    end
end






local function SetActionBarFonts(font, size, kbSize, outline, kbOutline)
    -- Blizzard action bars
    local blizzButtons = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
        "MultiBar6Button", "MultiBar7Button", "PetActionButton"
    }

    for _, buttonPrefix in ipairs(blizzButtons) do
        for i = 1, 12 do
            local hotKeyText = _G[buttonPrefix .. i .. "HotKey"]
            if hotKeyText then
                local ogFont, ogSize, ogOutline = hotKeyText:GetFont()
                local finalOutline = kbOutline or (ogOutline ~= "NONE" and ogOutline) or nil
                hotKeyText:SetFont(font or ogFont, kbSize or ogSize, finalOutline)
            end

            local macroText = _G[buttonPrefix .. i .. "Name"]
            if macroText then
                local ogFont, ogSize, ogOutline = macroText:GetFont()
                local finalOutline = outline or (ogOutline ~= "NONE" and ogOutline) or nil
                macroText:SetFont(font or ogFont, size or ogSize, finalOutline)
            end
        end
    end

    -- Dominos action bars
    local NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12
    local DOMINOS_NUM_MAX_BUTTONS = 14 * NUM_ACTIONBAR_BUTTONS
    local dominosBars = {
        {name = "DominosActionButton", count = DOMINOS_NUM_MAX_BUTTONS},
        {name = "MultiBar5ActionButton", count = 12},
        {name = "MultiBar6ActionButton", count = 12},
        {name = "MultiBar7ActionButton", count = 12},
        {name = "MultiBarRightActionButton", count = 12},
        {name = "MultiBarLeftActionButton", count = 12},
        {name = "MultiBarBottomRightActionButton", count = 12},
        {name = "MultiBarBottomLeftActionButton", count = 12},
        {name = "DominosPetActionButton", count = 12},
        {name = "DominosStanceButton", count = 12},
    }

    for _, bar in ipairs(dominosBars) do
        for i = 1, bar.count do
            local hotKeyText = _G[bar.name .. i .. "HotKey"]
            if hotKeyText then
                local ogFont, ogSize, ogOutline = hotKeyText:GetFont()
                local finalOutline = kbOutline or (ogOutline ~= "NONE" and ogOutline) or nil
                hotKeyText:SetFont(font or ogFont, kbSize or ogSize, finalOutline)
            end

            local macroText = _G[bar.name .. i .. "Name"]
            if macroText then
                local ogFont, ogSize, ogOutline = macroText:GetFont()
                local finalOutline = outline or (ogOutline ~= "NONE" and ogOutline) or nil
                macroText:SetFont(font or ogFont, size or ogSize, finalOutline)
            end
        end
    end
end




local LSM = LibStub("LibSharedMedia-3.0")
local oldChatFont = nil

function BBF.SetCustomFonts()
    local db = BetterBlizzFramesDB

    if db.changeAllFontsIngame then
        local fontName = db.allIngameFont
        local fontPath = LSM:Fetch(LSM.MediaType.FONT, fontName)

        local ForcedFontSize = { 9, 9, 14, 14, 12, 64, 64 }
        local FontObjects = {
            SystemFont_NamePlateCastBar,
            SystemFont_NamePlateFixed,
            SystemFont_LargeNamePlateFixed,
            SystemFont_LargeNamePlate,
            SystemFont_NamePlate,
            SystemFont_World,
            SystemFont_World_ThickOutline,
            SystemFont_Outline_Small,
            SystemFont_Outline,
            SystemFont_InverseShadow_Small,
            SystemFont_Med2,
            SystemFont_Med3,
            SystemFont_Shadow_Med3,
            SystemFont_Huge1,
            SystemFont_Huge1_Outline,
            SystemFont_OutlineThick_Huge2,
            SystemFont_OutlineThick_Huge4,
            SystemFont_OutlineThick_WTF,
            NumberFont_GameNormal,
            NumberFont_Shadow_Small,
            NumberFont_OutlineThick_Mono_Small,
            NumberFont_Shadow_Med,
            NumberFont_Normal_Med,
            NumberFont_Outline_Med,
            NumberFont_Outline_Large,
            NumberFont_Outline_Huge,
            Fancy22Font,
            QuestFont_Huge,
            QuestFont_Outline_Huge,
            QuestFont_Super_Huge,
            QuestFont_Super_Huge_Outline,
            SplashHeaderFont,
            Game10Font_o1,
            Game11Font,
            Game12Font,
            Game13Font,
            Game13FontShadow,
            Game15Font,
            Game18Font,
            Game20Font,
            Game24Font,
            Game27Font,
            Game30Font,
            Game32Font,
            Game36Font,
            Game48Font,
            Game48FontShadow,
            Game60Font,
            Game72Font,
            Game11Font_o1,
            Game12Font_o1,
            Game13Font_o1,
            Game15Font_o1,
            QuestFont_Enormous,
            DestinyFontLarge,
            CoreAbilityFont,
            DestinyFontHuge,
            QuestFont_Shadow_Small,
            MailFont_Large,
            SpellFont_Small,
            InvoiceFont_Med,
            InvoiceFont_Small,
            Tooltip_Med,
            Tooltip_Small,
            AchievementFont_Small,
            ReputationDetailFont,
            FriendsFont_Normal,
            FriendsFont_Small,
            FriendsFont_Large,
            FriendsFont_UserText,
            GameFont_Gigantic,
            GameFontNormalMed3,
            ChatBubbleFont,
            Fancy16Font,
            Fancy18Font,
            Fancy20Font,
            Fancy24Font,
            Fancy27Font,
            Fancy30Font,
            Fancy32Font,
            Fancy48Font,
            SystemFont_Tiny2,
            SystemFont_Tiny,
            SystemFont_Shadow_Small,
            SystemFont_Small,
            SystemFont_Small2,
            SystemFont_Shadow_Small2,
            SystemFont_Shadow_Med1_Outline,
            SystemFont_Shadow_Med1,
            QuestFont_Large,
            SystemFont_Large,
            SystemFont_Shadow_Large_Outline,
            SystemFont_Shadow_Med2,
            SystemFont_Shadow_Large,
            SystemFont_Shadow_Large2,
            SystemFont_Shadow_Huge1,
            SystemFont_Huge2,
            SystemFont_Shadow_Huge2,
            SystemFont_Shadow_Huge3,
            SystemFont_Shadow_Outline_Huge3,
            SystemFont_Shadow_Outline_Huge2,
            SystemFont_Med1,
            SystemFont_WTF2,
            SystemFont_Outline_WTF2,
            GameTooltipHeader,
            System_IME,
            Number12Font_o1,
        }

        -- Backup function for the chat font
        local function BackupChatFont()
            if not oldChatFont then
                local chatFrame = _G["ChatFrame1"]
                local fontPath, fontSize, fontStyle = chatFrame:GetFont()
                oldChatFont = {fontPath, fontSize, fontStyle}
            end
        end

        -- Set function for the chat font
        local function SetChatFont()
            BackupChatFont() -- Ensure we backup before setting a new font
            for i = 1, NUM_CHAT_WINDOWS do
                local chatFrame = _G["ChatFrame" .. i]
                chatFrame:SetFont(fontPath, oldChatFont[2], oldChatFont[3])
            end
        end

        local function SetAllFonts()
            SetChatFont()
            for i, FontObject in pairs(FontObjects) do
                local _, size, style = FontObject:GetFont()
                FontObject:SetFont(fontPath, ForcedFontSize[i] or size, style)
            end

            for _, frame in ipairs(frames) do
                local _, size, style = frame.bbfName:GetFont()
                frame.bbfName:SetFont(fontPath, size, style)
            end
        end

        SetAllFonts()
    end

    if db.changePartyFrameFont then
        local fontName = db.partyFrameFont
        local fontPath = LSM:Fetch(LSM.MediaType.FONT, fontName)
        local fontSize = db.partyFrameFontSize or 10
        local fontSize2 = db.partyFrameStatusFontSize or 10
        local outline = db.partyFrameFontOutline or "THINOUTLINE"

        SetPartyFont(fontPath, fontSize, outline, fontSize2)

        if not BBF.hookedRaidFramesFont then
            local function SetRaidFrameFont(raidFrame)
                if raidFrame.bbfSetFont then return end
                raidFrame.name:SetFont(fontPath, fontSize, outline)
                if raidFrame.statusText then
                    raidFrame.statusText:SetFont(fontPath, fontSize2, outline)
                end
                raidFrame.bbfSetFont = true
            end
            hooksecurefunc("DefaultCompactUnitFrameSetup", SetRaidFrameFont)
            local function SetRaidFramePetFont(raidFrame)
                --if raidFrame.bbfSetFont then return end
                raidFrame.name:SetFont(fontPath, fontSize, outline)
                if raidFrame.statusText then
                    raidFrame.statusText:SetFont(fontPath, fontSize2, outline)
                end
                ---raidFrame.bbfSetFont = true
            end
            if C_CVar.GetCVar("raidOptionDisplayPets") == "1" or C_CVar.GetCVar("raidOptionDisplayMainTankAndAssist") == "1" then
                hooksecurefunc("DefaultCompactMiniFrameSetup", SetRaidFramePetFont)
                hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
                    if frame.unit and (frame.unit:match("raidpet") or frame.unit:match("target")) then
                        SetRaidFramePetFont(frame)
                    end
                end)
            end
            BBF.hookedRaidFramesFont = true
        end
    end

    if db.changeUnitFrameFont then
        local fontName = db.unitFrameFont
        local fontPath = LSM:Fetch(LSM.MediaType.FONT, fontName)
        local fontSize = db.unitFrameFontSize or 10
        local outline = db.unitFrameFontOutline or "THINOUTLINE"

        SetUnitFramesFont(fontPath, fontSize, outline)
    end

    if db.changeActionBarFont then
        local fontName = db.actionBarFont
        local fontPath = LSM:Fetch(LSM.MediaType.FONT, fontName)
        local fontSize = db.actionBarFontSize or 10
        local kbSize = db.actionBarKeyFontSize or 10
        local outline = db.actionBarFontOutline or "THINOUTLINE"
        local kbOutline = db.actionBarKeyFontOutline or "THINOUTLINE"

        SetActionBarFonts(fontPath, fontSize, kbSize, outline, kbOutline)
    end

    if db.changeUnitFrameValueFont then
        local fontName = db.unitFrameValueFont
        local fontPath = LSM:Fetch(LSM.MediaType.FONT, fontName)
        local fontSize = db.unitFrameValueFontSize or 10
        local outline = db.unitFrameValueFontOutline or "THINOUTLINE"

        SetUnitFramesValuesFont(fontPath, fontSize, outline)
    end
end

local function UpdateNamePositionForClassic()
    if not isAddonLoaded("ClassicFrames") then return end

    for _, frame in ipairs(frames) do
        local name = frame.name or frame.Name
        if frame.bbfName and name then
            if not frame.bbfForcedFont then
                local font, fontHeight, fontFlags = name:GetFont()
                frame.bbfName:SetFont(font, fontHeight, fontFlags)
            end
            -- Copy alignment, color, shadow, and dimensions
            frame.bbfName:SetJustifyH(name:GetJustifyH())
            frame.bbfName:SetJustifyV(name:GetJustifyV())
            frame.bbfName:SetShadowColor(name:GetShadowColor())
            frame.bbfName:SetShadowOffset(name:GetShadowOffset())
            frame.bbfName:SetWidth(name:GetWidth())
            frame.bbfName:SetHeight(name:GetHeight())
            frame.bbfName:SetWordWrap(false)

            -- Copy position
            local point, relativeTo, relativePoint, xOffset, yOffset = name:GetPoint()
            if point then
                frame.bbfName:ClearAllPoints()
                frame.bbfName:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
            end
        end
    end
end
C_Timer.After(1, UpdateNamePositionForClassic)

local function ClassColorName(textObject, unit)
    local color = BBF.getUnitColor(unit)
    if color then
        textObject:SetTextColor(color.r, color.g, color.b)
    else
        textObject:SetTextColor( 1, 0.8196, 0)
    end
end

local unitToArenaName = {
    ["party1"] = "Party 1",
    ["party2"] = "Party 2",
    ["arena1"] = "Arena 1",
    ["arena2"] = "Arena 2",
    ["arena3"] = "Arena 3",
}

local function GetArenaUnitName(unit)
    for arenaUnit, arenaName in pairs(unitToArenaName) do
        if UnitIsUnit(unit, arenaUnit) then
            return arenaName
        end
    end
    return nil
end

local function SetArenaNameUnitFrame(frame, unit, textObject)
    local unitID = GetArenaUnitName(unit)
    local specName = GetSpecName(unit)
    local nameText

    -- Check if the unit is the player or a party member
    if UnitIsUnit(unit, "player") or not UnitIsPlayer(unit) then
        nameText = UnitName(unit) -- Show default target name
    elseif targetAndFocusArenaNamePartyOverride and unitID and string.match(unitID, "Party") then
        nameText = unitID -- Show "Party 1" or "Party 2"
    else
        -- Construct the nameText based on specName and unitID settings
        if specName then
            if showSpecName and showArenaID and unitID then
                local arenaNumber = string.match(unitID, "%d+")
                nameText = specName .. " " .. (arenaNumber or "")
            elseif showSpecName then
                nameText = specName
            elseif showArenaID and unitID then
                nameText = unitID
            end
        else
            nameText = (showArenaID and unitID) or (removeRealmNames and GetNameWithoutRealm(frame)) or UnitName(unit)
        end
    end

    -- Update the text object with the nameText if available
    if nameText then
        textObject:SetText(nameText)
        if classColorTargetNames then
            ClassColorName(frame.bbfName, unit)
        end
    end
end

local function PlayerFrameNameChanges(frame)
    frame.name:SetAlpha(0)
    if not frame.unit then return end
    local unit = frame.unit
    if hidePlayerName then
        frame.bbfName:SetText("")
        return
    end

    if not changeUnitFrameFont then
        frame.bbfName:SetFont(frame.name:GetFont())
    end

    if TRP3_API and rpNames then

        SetRPName(frame.bbfName, unit)

        if rpNamesColor then
            local r,g,b = GetRPNameColor(unit)
            if r then
                frame.bbfName:SetTextColor(r, g, b)
                frame.bbfName.recolored = true
                return
            elseif frame.bbfName.recolored then
                frame.bbfName:SetTextColor(1, 0.82, 0)
                frame.bbfName.recolored = nil
            end
        end
    else
        frame.bbfName:SetText(frame.name:GetText())
    end

    if classColorTargetNames then
        ClassColorName(frame.bbfName, unit)
    end
    if classColorLevelText then
        local _, class = UnitClass(unit)
        local classColor = RAID_CLASS_COLORS[class]
        PlayerLevelText:SetTextColor(classColor.r, classColor.g, classColor.b)
    end
end
C_Timer.After(1, function()
    PlayerFrameNameChanges(PlayerFrame)
end)


local function TargetFrameNameChanges(frame)
    frame.name:SetAlpha(0)
    if not frame.unit then return end
    local unit = frame.unit

    if not changeUnitFrameFont then
        frame.bbfName:SetFont(frame.name:GetFont())
    end

    if targetAndFocusArenaNames and IsActiveBattlefieldArena() then
        SetArenaNameUnitFrame(frame, unit, frame.bbfName)
    else
        if hideTargetName then
            frame.bbfName:SetText("")
            return
        end
        if TRP3_API and rpNames then

            SetRPName(frame.bbfName, unit)

            if rpNamesColor then
                local r,g,b = GetRPNameColor(unit)
                if r then
                    frame.bbfName:SetTextColor(r, g, b)
                    frame.bbfName.recolored = true
                    return
                elseif frame.bbfName.recolored then
                    frame.bbfName:SetTextColor(1, 0.82, 0)
                    frame.bbfName.recolored = nil
                end
            end
        elseif removeRealmNames then
            frame.bbfName:SetText(GetNameWithoutRealm(frame))
        elseif showLastNameNpc and not UnitIsPlayer(frame.unit) then
            frame.bbfName:SetText(ShowLastNameOnlyNpc(frame, frame.name:GetText()))
        else
            frame.bbfName:SetText(frame.name:GetText())
        end
        if classColorTargetNames then
            ClassColorName(frame.bbfName, unit)
        end
    end
end

hooksecurefunc(TargetFrame.name, "SetText", function(self)
    TargetFrameNameChanges(TargetFrame)
end)

local function ClassColorLevelText(frame)
    if not classColorLevelText then return end
    ClassColorName(frame.TargetFrameContent.TargetFrameContentMain.LevelText, frame.unit)
end
hooksecurefunc(TargetFrame, "CheckLevel", ClassColorLevelText)
hooksecurefunc(FocusFrame, "CheckLevel", ClassColorLevelText)
hooksecurefunc("PlayerFrame_UpdateLevel", function()
    if not classColorLevelText then return end
    ClassColorName(PlayerLevelText, "player")
end)




local function PetFrameNameChanges(frame)
    frame.name:SetAlpha(0)
    if not frame.unit then return end
    local unit = frame.unit

    if hidePetName then
        frame.bbfName:SetText("")
        return
    end
    if not changeUnitFrameFont then
        frame.bbfName:SetFont(frame.name:GetFont())
    end
    frame.bbfName:SetText(frame.name:GetText())
    if classColorTargetNames then
        ClassColorName(frame.bbfName, unit)
    end
end

hooksecurefunc(PetFrame.name, "SetText", function(self)
    PetFrameNameChanges(PetFrame)
end)







local function FocusFrameNameChanges(frame)
    frame.name:SetAlpha(0)
    if not frame.unit then return end
    local unit = frame.unit

    if classColorLevelText and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local classColor = RAID_CLASS_COLORS[class]
        frame.TargetFrameContent.TargetFrameContentMain.LevelText:SetTextColor(classColor.r, classColor.g, classColor.b)
    end

    if not changeUnitFrameFont then
        frame.bbfName:SetFont(frame.name:GetFont())
    end

    if targetAndFocusArenaNames and IsActiveBattlefieldArena() then
        SetArenaNameUnitFrame(frame, unit, frame.bbfName)
    else
        if hideFocusName then
            frame.bbfName:SetText("")
            return
        end
        if TRP3_API and rpNames then

            SetRPName(frame.bbfName, unit)

            if rpNamesColor then
                local r,g,b = GetRPNameColor(unit)
                if r then
                    frame.bbfName:SetTextColor(r, g, b)
                    frame.bbfName.recolored = true
                    return
                elseif frame.bbfName.recolored then
                    frame.bbfName:SetTextColor(1, 0.82, 0)
                    frame.bbfName.recolored = nil
                end
            end
        elseif removeRealmNames then
            frame.bbfName:SetText(GetNameWithoutRealm(frame))
        elseif showLastNameNpc and not UnitIsPlayer(frame.unit) then
            frame.bbfName:SetText(ShowLastNameOnlyNpc(frame, frame.name:GetText()))
        else
            frame.bbfName:SetText(frame.name:GetText())
        end
        if classColorTargetNames then
            ClassColorName(frame.bbfName, unit)
        end
    end
end

hooksecurefunc(FocusFrame.name, "SetText", function()
    FocusFrameNameChanges(FocusFrame)
end)








local function TargetFrameToTNameChanges(frame)
    frame.name:SetAlpha(0)
    if not frame.unit then return end
    local unit = frame.unit
    if not changeUnitFrameFont then
        frame.bbfName:SetFont(frame.name:GetFont())
    end
    if targetAndFocusArenaNames and IsActiveBattlefieldArena() then
        SetArenaNameUnitFrame(frame, unit, frame.bbfName)
    else
        if hideTargetToTName then
            frame.bbfName:SetText("")
            return
        end
        if TRP3_API and rpNames then

            SetRPName(frame.bbfName, unit)

            if rpNamesColor then
                local r,g,b = GetRPNameColor(unit)
                if r then
                    frame.bbfName:SetTextColor(r, g, b)
                    frame.bbfName.recolored = true
                    return
                elseif frame.bbfName.recolored then
                    frame.bbfName:SetTextColor(1, 0.82, 0)
                    frame.bbfName.recolored = nil
                end
            end
        elseif removeRealmNames then
            frame.bbfName:SetText(GetNameWithoutRealm(frame))
        elseif showLastNameNpc and not UnitIsPlayer(frame.unit) then
            frame.bbfName:SetText(ShowLastNameOnlyNpc(frame, frame.name:GetText()))
        else
            frame.bbfName:SetText(frame.name:GetText())
        end
        if classColorTargetNames then
            ClassColorName(frame.bbfName, unit)
        end
    end
end

hooksecurefunc(TargetFrame.totFrame.Name, "SetText", function()
    TargetFrameToTNameChanges(TargetFrameToT)
end)

local function FocusFrameToTNameChanges(frame)
    frame.name:SetAlpha(0)
    if not frame.unit then return end
    local unit = frame.unit
    if not changeUnitFrameFont then
        frame.bbfName:SetFont(frame.name:GetFont())
    end
    if targetAndFocusArenaNames and IsActiveBattlefieldArena() then
        SetArenaNameUnitFrame(frame, unit, frame.bbfName)
    else
        if hideFocusToTName then
            frame.bbfName:SetText("")
            return
        end
        if TRP3_API and rpNames then

            SetRPName(frame.bbfName, unit)

            if rpNamesColor then
                local r,g,b = GetRPNameColor(unit)
                if r then
                    frame.bbfName:SetTextColor(r, g, b)
                    frame.bbfName.recolored = true
                    return
                elseif frame.bbfName.recolored then
                    frame.bbfName:SetTextColor(1, 0.82, 0)
                    frame.bbfName.recolored = nil
                end
            end
        elseif removeRealmNames then
            frame.bbfName:SetText(GetNameWithoutRealm(frame))
        elseif showLastNameNpc and not UnitIsPlayer(frame.unit) then
            frame.bbfName:SetText(ShowLastNameOnlyNpc(frame, frame.name:GetText()))
        else
            frame.bbfName:SetText(frame.name:GetText())
        end
        if classColorTargetNames then
            ClassColorName(frame.bbfName, unit)
        end
    end
end

hooksecurefunc(FocusFrame.totFrame.Name, "SetText", function()
    FocusFrameToTNameChanges(FocusFrameToT)
end)


local function ResetTextColors()
    -- Table of frames to process
    local frames = {
        PlayerFrame,
        PetFrame,
        TargetFrame,
        FocusFrame,
        TargetFrameToT,
        FocusFrameToT,
    }

    -- Iterate through each frame and reset the text color
    for _, frame in pairs(frames) do
        if frame and frame.name then
            frame.bbfName:SetTextColor(1, 0.8196, 0)
        end
    end
end


function BBF.AllNameChanges()
    BBF.UpdateUserTargetSettings()
    ResetTextColors()
    BBF.PartyNameChange()

    PlayerFrameNameChanges(PlayerFrame)
    PetFrameNameChanges(PetFrame)
    TargetFrameNameChanges(TargetFrame)
    FocusFrameNameChanges(FocusFrame)
    TargetFrameToTNameChanges(TargetFrameToT)
    FocusFrameToTNameChanges(FocusFrameToT)

    if not EditModeManagerFrame:UseRaidStylePartyFrames() then
        local frames = {
            PartyFrame.MemberFrame1,
            PartyFrame.MemberFrame2,
            PartyFrame.MemberFrame3,
            PartyFrame.MemberFrame4,
        }

        for _, frame in ipairs(frames) do
            PartyFrameNameChange(frame)
            HideRoleIconDefault(frame)
        end
    end

    if HealthBarColorDB then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local playerRealm = playerName .. " - " .. realmName
        local profileName = HealthBarColorDB["profileKeys"][playerRealm]
        if HealthBarColorDB["profiles"] and HealthBarColorDB["profiles"][profileName] and HealthBarColorDB["profiles"][profileName]["Font_player"] and HealthBarColorDB["profiles"][profileName]["Font_player"].enabled then
            local frames = {
                PlayerFrame,
                PetFrame,
                TargetFrame,
                FocusFrame,
                TargetFrameToT,
                FocusFrameToT,
            }

            -- Iterate through each frame and reset the text color
            for _, frame in pairs(frames) do
                if frame and frame.name then
                    local a,b,c = frame.name:GetFont()
                    frame.bbfName:SetFont(a,b,c)
                    local r, g, b, a = frame.name:GetTextColor()
                    frame.bbfName:SetTextColor(r,g,b,1)
                    if not frame.bbfhbcHook then
                        hooksecurefunc(frame.name, "SetFont", function(self)
                            local f,s,o = self:GetFont()
                            self:SetAlpha(0)
                            frame.bbfName:SetFont(f,s,o)
                        end)
                        hooksecurefunc(frame.name, "SetTextColor", function(self)
                            local r, g, b, a = self:GetTextColor()
                            frame.bbfName:SetTextColor(r,g,b,1)
                        end)
                        frame.bbfhbcHook = true
                    end
                end
            end
        end
    end
end

function BBF.FontColors()
    local db = BetterBlizzFramesDB
    if db.unitFrameFontColor then
        local color = db.unitFrameFontColorRGB
        local unitFrameFonts = {
            PlayerFrame,
            TargetFrame,
            TargetFrameToT,
            FocusFrame,
            FocusFrameToT,
        }
        for _, frame in ipairs(unitFrameFonts) do
            if frame.bbfName then
                frame.bbfName:SetVertexColor(unpack(color))
            end
        end
        if db.unitFrameFontColorLvl then
            PlayerLevelText:SetVertexColor(unpack(color))
            TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetVertexColor(unpack(BetterBlizzFramesDB.unitFrameFontColorRGB))
            FocusFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetVertexColor(unpack(color))
            if not BBF.UnitFrameFontColorHook then
                hooksecurefunc("PlayerFrame_UpdateLevel", function()
                    PlayerLevelText:SetVertexColor(unpack(color))
                end)
                hooksecurefunc(TargetFrame, "CheckLevel", function()
                    TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetVertexColor(unpack(BetterBlizzFramesDB.unitFrameFontColorRGB))
                end)
                hooksecurefunc(FocusFrame, "CheckLevel", function()
                    FocusFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetVertexColor(unpack(BetterBlizzFramesDB.unitFrameFontColorRGB))
                end)
                BBF.UnitFrameFontColorHook = true
            end
        end
    end

    if db.partyFrameFontColor then
        local color = db.partyFrameFontColorRGB
        local partyFrameFonts = {
            PartyFrame.MemberFrame1,
            PartyFrame.MemberFrame2,
            PartyFrame.MemberFrame3,
            PartyFrame.MemberFrame4,
            CompactPartyFrameMember1,
            CompactPartyFrameMember2,
            CompactPartyFrameMember3,
            CompactPartyFrameMember4,
            CompactPartyFrameMember5
        }
        for _, frame in ipairs(partyFrameFonts) do
            if frame.bbfName then
                frame.bbfName:SetVertexColor(unpack(color))
            elseif frame.name then
                frame.name:SetVertexColor(unpack(color))
            end
        end
    end

    if db.unitFrameValueFontColor then
        local color = db.unitFrameValueFontColorRGB
        local unitFrameValueFonts = {
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar,
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar,
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar,
            TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar,
            FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar,
            FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar,
            PartyFrame.MemberFrame1.HealthBarContainer.HealthBar,
            PartyFrame.MemberFrame2.HealthBarContainer.HealthBar,
            PartyFrame.MemberFrame3.HealthBarContainer.HealthBar,
            PartyFrame.MemberFrame4.HealthBarContainer.HealthBar,
            PartyFrame.MemberFrame1.ManaBar,
            PartyFrame.MemberFrame2.ManaBar,
            PartyFrame.MemberFrame3.ManaBar,
            PartyFrame.MemberFrame4.ManaBar,
        }
        for _, frame in ipairs(unitFrameValueFonts) do
            if frame.LeftText then frame.LeftText:SetVertexColor(unpack(color)) end
            if frame.RightText then frame.RightText:SetVertexColor(unpack(color)) end
            if frame.TextString then frame.TextString:SetVertexColor(unpack(color)) end
            if frame.CenterText then frame.CenterText:SetVertexColor(unpack(color)) end
            if frame.ManaBarText then frame.ManaBarText:SetVertexColor(unpack(color)) end
        end
    end

    if db.actionBarFontColor then
        local color = db.actionBarFontColorRGB
        local function isBlizzardWhite(r)
            return math.abs(r - 0.8) < 0.01
        end
        local function setColor(name)
            local frame = _G[name]
            if frame and frame.SetVertexColor then
                frame:SetVertexColor(unpack(color))
                if not frame.colorHook then
                    hooksecurefunc(frame, "SetVertexColor", function(self, r, g, b, a)
                        if frame.changing then return end
                        frame.changing = true
                        if isBlizzardWhite(r) then
                            frame:SetVertexColor(unpack(color))
                        end
                        frame.changing = false
                    end)
                    frame.colorHook = true
                end
            end
        end

        local prefixes = {
            "ActionButton",
            "MultiBarBottomLeftButton",
            "MultiBarBottomRightButton",
            "MultiBarRightButton",
            "MultiBarLeftButton",
            "MultiBar5Button",
            "MultiBar6Button",
            "MultiBar7Button",
            "PetActionButton"
        }

        local suffixes = { "HotKey", "Name", "Count" }

        for i = 1, 12 do
            for _, prefix in ipairs(prefixes) do
                for _, suffix in ipairs(suffixes) do
                    setColor(prefix .. i .. suffix)
                end
            end
        end
    end
end