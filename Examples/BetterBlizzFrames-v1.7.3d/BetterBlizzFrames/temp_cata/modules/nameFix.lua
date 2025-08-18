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
local hidePlayerName
local hidePetName
local isAddonLoaded = C_AddOns.IsAddOnLoaded
local changeUnitFrameFont
local targetAndFocusArenaNamePartyOverride
local showLastNameNpc

function BBF.UpdateUserTargetSettings()
    hidePartyNames = BetterBlizzFramesDB.hidePartyNames
    hidePartyRoles = BetterBlizzFramesDB.hidePartyRoles
    removeRealmNames = BetterBlizzFramesDB.removeRealmNames
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
    classColorLevelText = BetterBlizzFramesDB.classColorLevelText and BetterBlizzFramesDB.classColorTargetNames
    hidePlayerName = BetterBlizzFramesDB.hidePlayerName
    hidePetName = BetterBlizzFramesDB.hidePetName
    changeUnitFrameFont = BetterBlizzFramesDB.changeUnitFrameFont
    targetAndFocusArenaNamePartyOverride = BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride
    showLastNameNpc = BetterBlizzFramesDB.showLastNameNpc
end

local validPartyUnits = {
    ["party1"] = true,
    ["party2"] = true,
    ["party3"] = true,
    ["party4"] = true,
    ["raid1"] =  true,
    ["raid2"] =  true,
    ["raid3"] =  true,
    ["raid4"] =  true,
}

local function GetSpecName(unitGUID)
    if Details then
        local specID = Details:GetSpecByGUID(unitGUID)
        return specID and (shortArenaSpecName and specIDToNameShort[specID] or specIDToName[specID])
    end
    return nil
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
    local unitGUID = UnitGUID(unit)
    local specName = GetSpecName(unitGUID)
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

local function PartyArenaName(frame)
    local unit = frame.displayedUnit
    if not validPartyUnits[unit] then return end
    if UnitIsUnit(unit, "player") then return end
    if not IsActiveBattlefieldArena() then return end
    SetArenaName(frame, unit, frame.name)
end

function BBF.PartyNameChange()
    if GetCVarBool("useCompactPartyFrames") then --EditModeManagerFrame:UseRaidStylePartyFrames()
        for i = 1, 3 do
            local memberFrame = _G["CompactPartyFrameMember" .. i]
            local raidMemberFrame = _G["CompactRaidFrame"..i]
            if memberFrame and memberFrame.displayedUnit then
                PartyArenaName(memberFrame)
            end
            if raidMemberFrame and raidMemberFrame.displayedUnit then
                PartyArenaName(raidMemberFrame)
            end
        end
    else
        for i = 1, 4 do
            local memberFrame = _G["PartyMemberFrame" .. i]
            if memberFrame and memberFrame.unit then
                PartyArenaName(memberFrame)
            end
        end
    end
end

local UpdatePartyNames = CreateFrame("Frame")
UpdatePartyNames:RegisterEvent("GROUP_ROSTER_UPDATE")
UpdatePartyNames:RegisterEvent("PLAYER_ENTERING_WORLD")
UpdatePartyNames:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
UpdatePartyNames:SetScript("OnEvent", function(self, event, ...)
    if partyArenaNames and IsActiveBattlefieldArena() then
        for delay = 0, 8 do
            C_Timer.After(delay, BBF.PartyNameChange)
        end
    end
end)


local function CompactPartyFrameNameChanges(frame)
    if not frame or not frame.unit then return end
    if frame.unit:find("nameplate") then return end
    if hidePartyNames then
        frame.name:SetText("")
        return
    end
    if partyArenaNames and IsActiveBattlefieldArena() then
        PartyArenaName(frame)
        return
    end
    if removeRealmNames then
        frame.name:SetText(GetNameWithoutRealm(frame))
    end
end

local function HideRoleIcon(frame)
    if not hidePartyRoles then return end
    if not frame.roleIcon then return end
    frame.roleIcon:SetAlpha(0)
end
hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", HideRoleIcon)
--hooksecurefunc("CompactUnitFrame_SetUnit", CompactPartyFrameNameChanges)
hooksecurefunc("CompactUnitFrame_UpdateName", CompactPartyFrameNameChanges)

local function PartyFrameNameChange(frame)
    if not frame or not frame.unit then return end
    frame.name:SetAlpha(0)
    if hidePartyNames then
        frame.bbfName:SetText("")
        return
    end
    if not changeUnitFrameFont then
        frame.bbfName:SetFont(frame.name:GetFont())
    end
    frame.bbfName:ClearAllPoints()
    frame.bbfName:SetPoint("LEFT", frame.name, "LEFT")
    frame.bbfName:SetWidth(frame.name:GetWidth())
    if partyArenaNames and IsActiveBattlefieldArena() then
        SetArenaName(frame, frame.unit, frame.bbfName)
        return
    end
    if removeRealmNames then
        frame.bbfName:SetText(GetNameWithoutRealm(frame))
    else
        frame.bbfName:SetText(frame.name:GetText())
    end
end

if not GetCVarBool("useCompactPartyFrames") then
    local frames = {
        PartyMemberFrame1,
        PartyMemberFrame2,
        PartyMemberFrame3,
        PartyMemberFrame4,
    }

    for _, frame in ipairs(frames) do
        hooksecurefunc(frame.name, "SetText", function(self)
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
    PartyMemberFrame1,
    PartyMemberFrame2,
    PartyMemberFrame3,
    PartyMemberFrame4,
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
                frame.bbfName:SetJustifyH(name:GetJustifyH())
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
    if C_AddOns.IsAddOnLoaded("DragonflightUI") or C_AddOns.IsAddOnLoaded("EasyFrames") then
        UpdateAllFontStringPositions()
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
        local partyFrameMember = _G["PartyMemberFrame"..i]
        if partyFrameMember then
            partyFrameMember.bbfName:SetFont(font, size, outline)
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
        --if frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain.LevelText then
            --frame.TargetFrameContent.TargetFrameContentMain.LevelText:SetFont(font, size, outline)
            local a,b = PlayerLevelText:GetFont()
            PlayerLevelText:SetFont(font, b, outline)
            FocusFrameTextureFrameLevelText:SetFont(font, b, outline)
            TargetFrameTextureFrameLevelText:SetFont(font, b, outline)
        --end
        frame.bbfForcedFont = true
    end
end


local playerManaBar = PlayerFrameManaBar
local playerHealthBar = PlayerFrameHealthBar

local petHealthBar = PetFrame.healthbar
local petManaBar = PetFrame.manabar

local targetManaBar = TargetFrameManaBar
local targetHealthBar = TargetFrameHealthBar

local focusManaBar = FocusFrameManaBar
local focusHealthBar = FocusFrameHealthBar

-- local altBar = AlternatePowerBar
-- local staggerBar = MonkStaggerBar

local statusTexts = {
    playerManaBar.LeftText,
    playerManaBar.RightText,
    playerManaBar.TextString,
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
    targetManaBar.TextString,
    --
    targetHealthBar.LeftText,
    targetHealthBar.RightText,
    targetHealthBar.TextString,
    --
    focusManaBar.LeftText,
    focusManaBar.RightText,
    focusManaBar.TextString,
    --
    focusHealthBar.LeftText,
    focusHealthBar.RightText,
    focusHealthBar.TextString,
    --
    -- altBar.LeftText,
    -- altBar.RightText,
    -- altBar.TextString,
    -- staggerBar.LeftText,
    -- staggerBar.RightText,
    -- staggerBar.TextString,
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
    for _, textObject in ipairs(statusTexts) do
                if not textObject then
            print("Nil statusText at index:", _)
                end
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
            MovieSubtitleFont
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
                --if raidFrame.bbfSetFont then return end
                raidFrame.name:SetFont(fontPath, fontSize, outline)
                if raidFrame.statusText then
                    raidFrame.statusText:SetFont(fontPath, fontSize2, outline)
                end
                ---raidFrame.bbfSetFont = true
            end
            local function SetRaidFramePetFont(raidFrame)
                --if raidFrame.bbfSetFont then return end
                raidFrame.name:SetFont(fontPath, fontSize, outline)
                if raidFrame.statusText then
                    raidFrame.statusText:SetFont(fontPath, fontSize2, outline)
                end
                ---raidFrame.bbfSetFont = true
            end
            hooksecurefunc("DefaultCompactUnitFrameSetup", SetRaidFrameFont)
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
    local unitGUID = UnitGUID(unit)
    local unitID = GetArenaUnitName(unit)
    local specName = GetSpecName(unitGUID)
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
hooksecurefunc("PlayerFrame_OnEvent", function()
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
        if removeRealmNames then
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

-- local function ClassColorLevelText(frame)
--     if not classColorLevelText then return end
--     ClassColorName(frame.TargetFrameContent.TargetFrameContentMain.LevelText, frame.unit)
-- end
-- hooksecurefunc(TargetFrame, "CheckLevel", ClassColorLevelText)
-- hooksecurefunc(FocusFrame, "CheckLevel", ClassColorLevelText)
hooksecurefunc("TargetFrame_CheckLevel", function()
    if not classColorLevelText then return end
    if UnitIsPlayer("target") then
        ClassColorName(TargetFrameTextureFrameLevelText, "target")
    end
    if UnitExists("focus") and UnitIsPlayer("focus") then
        ClassColorName(FocusFrameTextureFrameLevelText, "focus")
    end
end)
hooksecurefunc("PlayerFrame_OnEvent", function()
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
        FocusFrameTextureFrameLevelText:SetTextColor(classColor.r, classColor.g, classColor.b)
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
        if removeRealmNames then
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
        if removeRealmNames then
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

hooksecurefunc(TargetFrameToTTextureFrameName, "SetText", function()
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
        if removeRealmNames then
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

hooksecurefunc(FocusFrameToTTextureFrameName, "SetText", function()
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
    ResetTextColors()
    BBF.UpdateUserTargetSettings()
    BBF.PartyNameChange()

    PlayerFrameNameChanges(PlayerFrame)
    PetFrameNameChanges(PetFrame)
    TargetFrameNameChanges(TargetFrame)
    FocusFrameNameChanges(FocusFrame)
    TargetFrameToTNameChanges(TargetFrameToT)
    FocusFrameToTNameChanges(FocusFrameToT)

    if not GetCVarBool("useCompactPartyFrames") then
        local frames = {
            PartyMemberFrame1,
            PartyMemberFrame2,
            PartyMemberFrame2,
            PartyMemberFrame2,
        }

        for _, frame in ipairs(frames) do
            PartyFrameNameChange(frame)
        end
    end

    if classColorLevelText then
        ClassColorName(TargetFrameTextureFrameLevelText, "target")
        ClassColorName(FocusFrameTextureFrameLevelText, "focus")
        ClassColorName(PlayerLevelText, "player")
        BBF.colorLvl = true
    elseif BBF.colorLvl then
        PlayerLevelText:SetTextColor(1, 0.81960791349411, 0)
        TargetFrameTextureFrameLevelText:SetTextColor(1, 0.81960791349411, 0)
        FocusFrameTextureFrameLevelText:SetTextColor(1, 0.81960791349411, 0)
        BBF.colorLvl = nil
    end
end