-- I did not know what a variable was when I started. I know a little bit more now and I am so sorry.

local addonVersion = "1.00" --too afraid to to touch for now
local addonUpdates = C_AddOns.GetAddOnMetadata("BetterBlizzFrames", "Version")
local sendUpdate = false
BBF.VersionNumber = addonUpdates
BBF.variablesLoaded = false
local isAddonLoaded = C_AddOns.IsAddOnLoaded

local defaultSettings = {
    version = addonVersion,
    updates = "empty",
    wasOnLoadingScreen = true,
    -- General
    removeRealmNames = true,
    centerNames = false,
    darkModeUi = false,
    darkModeActionBars = true,
    darkModeUiAura = true,
    darkModeCastbars = true,
    darkModeColor = 0.30,
    hideGroupIndicator = false,
    hideFocusCombatGlow = false,
    fixHealthbarText = true,
    targetToTScale = 1,
    focusToTScale = 1,
    targetToTXPos = 0,
    targetToTYPos = 0,
    focusToTXPos = 0,
    focusToTYPos = 0,
    targetToTAnchor = "BOTTOMRIGHT",
    focusToTAnchor = "BOTTOMRIGHT",
    targetToTCastbarAdjustment = true,
    focusToTCastbarAdjustment = true,
    playerReputationClassColor = true,
    enlargedAuraSize = 1.4,
    compactedAuraSize = 0.7,
    purgeableAuraSize = 1,
    onlyPandemicAuraMine = true,
    lossOfControlScale = 1,
    hidePetText = true,
    playerFrameScale = 1,
    targetFrameScale = 1,
    focusFrameScale = 1,
    playerFrameOCDZoom = true,
    repositionBuffFrame = true,
    customCode = "-- Enter custom code below here. Feel free to contact me @bodify",
    queueTimerID = 567458,
    queueTimerWarning = false,
    queueTimerAudio = true,
    queueTimerWarningTime = 6,
    --enableLoCFrame = true,
    raiseTargetCastbarStrata = true,

    --Target castbar
    playerCastbarIconXPos = 0,
    playerCastbarIconYPos = 0,
    targetCastbarIconXPos = 0,
    targetCastbarIconYPos = 0,
    focusCastbarIconXPos = 0,
    focusCastbarIconYPos = 0,
    targetEnlargeAuraEnemy = true,
    targetEnlargeAuraFriendly = true,
    focusEnlargeAuraEnemy = true,
    focusEnlargeAuraFriendly = true,

    -- Absorb Indicator
    absorbIndicatorScale = 1,
    playerAbsorbAnchor = "TOP",
    targetAbsorbAnchor = "TOP",
    playerAbsorbAmount = true,
    playerAbsorbIcon = true,
    targetAbsorbAmount = true,
    targetAbsorbIcon = true,
    focusAbsorbAmount = true,
    focusAbsorbIcon = true,
    playerAbsorbXPos = 0,
    playerAbsorbYPos = 0,
    targetAbsorbXPos = 0,
    targetAbsorbYPos = 0,
    --Combat Indicator
    combatIndicator = false,
    combatIndicatorShowSap = true,
    combatIndicatorShowSwords = true,
    playerCombatIndicator = true,
    targetCombatIndicator = true,
    focusCombatIndicator = true,
    combatIndicatorAnchor = "RIGHT",
    combatIndicatorScale = 1,
    combatIndicatorXPos = 0,
    combatIndicatorYPos = 0,
    --Race Indicator
    racialIndicator = false,
    targetRacialIndicator = true,
    focusRacialIndicator = true,
    racialIndicatorXPos = 0,
    racialIndicatorYPos = 0,
    racialIndicatorScale = 1,
    racialIndicatorOrc = true,
    racialIndicatorNelf = true,
    racialIndicatorHuman = true,
    racialIndicatorUndead = true,

    --Party castbars
    partyCastBarScale = 0.9,
    partyCastBarIconScale = 0.9,
    partyCastBarXPos = 0,
    partyCastBarYPos = 0,
    partyCastBarWidth = 137,
    partyCastBarHeight = 10,
    partyCastBarTimer = false,
    showPartyCastBarIcon = true,
    partyCastbarIconXPos = 0,
    partyCastbarIconYPos = 0,
    partyCastbarShowBorder = true,
    partyCastbarShowText = true,

    --Pet Castbar
    petCastbar = false,
    petCastBarScale = 0.92,
    petCastBarIconScale = 1,
    petCastBarXPos = 0,
    petCastBarYPos = 0,
    petCastBarWidth = 137,
    petCastBarHeight = 10,
    showPetCastBarIcon = true,
    showPetCastBarTimer = false,
    petCastBarShowText = true,
    petCastBarShowBorder = true,

    --Castbar edge highlight
    castBarInterruptHighlighterStartTime = 0.8,
    castBarInterruptHighlighterEndTime = 0.6,
    castBarInterruptHighlighterDontInterruptRGB = {1,0,0},
    castBarInterruptHighlighterInterruptRGB = {0,1,0},
    castBarNoInterruptColor = {1, 0, 0.01568627543747425},
    castBarDelayedInterruptColor = {1, 0.4784314036369324, 0.9568628072738647},

    --Target castbar
    targetCastBarScale = 1,
    targetCastBarIconScale = 1,
    targetCastBarXPos = 0,
    targetCastBarYPos = 0,
    targetCastBarWidth = 150,
    targetCastBarHeight = 11,
    targetCastBarTimer = false,
    targetToTAdjustmentOffsetY = 0,
    targetCastBarShowText = true,
    targetCastBarShowBorder = true,

    --Focus castbar
    focusCastBarScale = 1,
    focusCastBarIconScale = 1,
    focusCastBarXPos = 0,
    focusCastBarYPos = 0,
    focusCastBarWidth = 150,
    focusCastBarHeight = 11,
    focusCastBarTimer = false,
    focusToTAdjustmentOffsetY = 0,
    focusCastBarShowText = true,
    focusCastBarShowBorder = true,

    legacyComboXPos = -44,
    legacyComboYPos = -9,
    legacyComboScale = 1,

    --Player castbar
    playerCastBarXPos = 0,
    playerCastBarYPos = 0,
    playerCastBarScale = 1,
    playerCastBarIconScale = 1,
    playerCastBarWidth = 195,
    playerCastBarHeight = 13,
    playerCastBarTimer = false,
    playerCastBarTimerCenter = false,
    playerCastBarShowText = true,
    playerCastBarShowBorder = true,

    --Auras
    --playerAuraMaxBuffsPerRow = 10,
    --playerAuraMaxDebuffsPerRow = 10,
    customImportantAuraSorting = true,
    customLargeSmallAuraSorting = true,
    allowLargeAuraFirst = true,
    auraStackSize = 1,
    auraToggleIconTexture = 134430,
    enablePlayerBuffFiltering = true,
    enablePlayerDebuffFiltering = false,
    playerdeBuffFilterBlacklist = true,
    playerBuffFilterBlacklist = true,
    focusdeBuffFilterBlacklist = true,
    focusBuffFilterBlacklist = true,
    targetdeBuffFilterBlacklist = true,
    targetBuffFilterBlacklist = true,
    auraTypeGap = 4,
    maxPlayerAurasPerRow = 10,
    playerAuraBuffScale = 1,
    playerAuraSpacingX = 3,
    playerAuraSpacingY = 0,
    playerAuraXOffset = 0,
    playerAuraYOffset = 0,
    maxBuffFrameBuffs = 32,
    maxDebuffFrameDebuffs = 16,
    printAuraSpellIds = false,
    showHiddenAurasIcon = true,
    PlayerAuraFrameBuffEnable = true,
    PlayerAuraFramedeBuffEnable = true,
    targetAndFocusAuraScale = 1,
    targetAndFocusAuraOffsetX = 0,
    targetAndFocusAuraOffsetY = 0,
    targetAndFocusHorizontalGap = 3,
    targetAndFocusVerticalGap = 4,
    targetAndFocusAurasPerRow = 6,
    targetAndFocusSmallAuraScale = 1,
    purgeTextureColorRGB = {0.3686274588108063,0.9803922176361084,1,1,},
    hiddenIconDirection = "BOTTOM",

    frameAurasXPos = 0,
    frameAurasYPos = 0,
    frameAuraScale = 0,
    maxAurasOnFrame = 0,
    frameAuraRowAmount = 0,
    frameAuraWidthGap = 0,
    frameAuraHeightGap = 0,

    playerAuraFiltering = false,
    displayDispelGlowAlways = false,
    overShieldsUnitFrames = true,
    overShieldsCompactUnitFrames = true,
    playerAuraGlows = true,
    playerAuraImportantGlow = true,

    --Target buffs
    targetAuraGlows = true,
    targetEnlargeAura = true,
    targetCompactAura = true,
    targetAndFocusArenaNamePartyOverride = true,

    maxTargetBuffs = 32,
    maxTargetDebuffs = 16,
    targetBuffEnable = true,
    targetBuffFilterAll = true,
    targetBuffFilterWatchList = false,
    targetBuffFilterLessMinite = false,
    targetBuffFilterPurgeable = false,
    targetImportantAuraGlow = true,
    targetBuffFilterOnlyMe = false,
    --Target debuffs
    targetdeBuffEnable = true,
    targetdeBuffFilterAll = false,
    targetdeBuffFilterBlizzard = false,
    targetdeBuffFilterWatchList = false,
    targetdeBuffFilterLessMinite = false,
    targetdeBuffFilterOnlyMe = false,
    targetdeBuffPandemicGlow = true,

    --Focus buffs
    focusAuraGlows = true,
    focusEnlargeAura = true,
    focusCompactAura = true,

    focusBuffEnable = true,
    focusBuffFilterAll = true,
    focusBuffFilterWatchList = false,
    focusBuffFilterLessMinite = false,
    focusBuffFilterOnlyMe = false,
    focusBuffFilterPurgeable = false,
    focusImportantAuraGlow = true,
    --Focus debuffs
    focusdeBuffEnable = true,
    focusdeBuffFilterAll = false,
    focusdeBuffFilterBlizzard = false,
    focusdeBuffFilterWatchList = false,
    focusdeBuffFilterLessMinite = false,
    focusdeBuffFilterOnlyMe = false,
    focusdeBuffPandemicGlow = true,

    PlayerAuraFrameBuffFilterWatchList = false,
    PlayerAuraFramedeBuffFilterWatchList = false,

    -- Interrupt icon
    castBarInterruptIconScale = 1,
    castBarInterruptIconXPos = 0,
    castBarInterruptIconYPos = 0,
    castBarInterruptIconAnchor = "RIGHT",
    castBarInterruptIconTarget = true,
    castBarInterruptIconFocus = true,
    castBarInterruptIconShowActiveOnly = false,
    castBarInterruptIconDisplayCD = true,
    interruptIconBorder = true,
    unitFrameBgTextureColor = {0,0,0,0.5},

    auraWhitelist = {
        ["example aura :3 (delete me)"] = {name = "Example Aura :3 (delete me)"}
    },
    auraBlacklist = {},
}

local version = GetBuildInfo()
if version and version:match("^5") then
    BBF.isMoP = true
    -- C_Timer.After(5, function()
    --     DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames has not been fully updated for MoP Classic yet. |cff32f795Please report bugs with BugSack & BugGrabber so I can fix.|r")
    -- end)
end

local function InitializeSavedVariables()
    if not BetterBlizzFramesDB then
        BetterBlizzFramesDB = {}
    end

    -- Check the stored version against the current addon version
    if not BetterBlizzFramesDB.version or BetterBlizzFramesDB.version ~= addonVersion then
        BetterBlizzFramesDB.version = addonVersion  -- Update the version number in the database
    end

    for key, defaultValue in pairs(defaultSettings) do
        if BetterBlizzFramesDB[key] == nil then
            BetterBlizzFramesDB[key] = defaultValue
        end
    end
end

local function FetchAndSaveValuesOnFirstLogin()
    -- Check if already saved the first login values
    if BetterBlizzFramesDB.hasSaved then
        return
    end

    BetterBlizzFramesDB.hasCheckedUi = true
    BetterBlizzFramesDB.hasNotOpenedSettings = true

    C_Timer.After(5, function()
        if not C_AddOns.IsAddOnLoaded("SkillCapped") then
        DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames first run. Thank you for trying out my AddOn. Access settings with /bbf")
        end
        BetterBlizzFramesDB.hasSaved = true
    end)
end

-- Define the popup window
StaticPopupDialogs["BetterBlizzFrames_COMBAT_WARNING"] = {
    text = "Leave combat to adjust this setting.",
    button1 = "Okay",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["BBF_NEW_VERSION"] = {
    text = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames " .. "Cata Beta 0.0.8" .. ":\n\nTWO IMPORTANT CHANGES:\n\n1) I've reset TargetToT & FocusToT positions.\nYou will have to change them to your preferred locations again.\n\n2) I've also added scale settings for Player, Target and FocusFrame.\n\nIf you have scripts/other addons adjusting this make sure you set the same value in BBF or turn off the other things.\n\nSorry for the inconvenience.\nThis change was needed due to wrong initial values when making the Beta.\nIt wont happen again.",
    button1 = "OK",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function ResetBBF()
    BetterBlizzFramesDB = {}
    ReloadUI()
end

StaticPopupDialogs["CONFIRM_RESET_BETTERBLIZZFRAMESDB"] = {
    text = "Are you sure you want to reset all BetterBlizzFrames settings?\nThis action cannot be undone.",
    button1 = "Confirm",
    button2 = "Cancel",
    OnAccept = function()
        ResetBBF()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Update message
local function SendUpdateMessage()
    if sendUpdate then
        if not BetterBlizzFramesDB.scStart then
            C_Timer.After(7, function()
                --StaticPopup_Show("BBF_NEW_VERSION")

                --if BetterBlizzFramesDB.playerAuraFiltering then
                    DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames "..addonUpdates..":")
                    --DEFAULT_CHAT_FRAME:AddMessage("|A:QuestNormal:16:16|a New stuff:")
                    DEFAULT_CHAT_FRAME:AddMessage("|A:QuestNormal:16:16|a Important Note: Player CastingBar has had it's position moved up 9 pixels to match Blizzard's location for it. You might have to move it back down 9 pixels to fit your UI. Apologies for the inconvenience.")
                --end
                -- DEFAULT_CHAT_FRAME:AddMessage("   - Absorb Indicator + Overshields now working (Potentially).")
                -- -- DEFAULT_CHAT_FRAME:AddMessage("   - Sort Purgeable Auras setting (Buffs & Debuffs).")

                -- DEFAULT_CHAT_FRAME:AddMessage("|A:Professions-Crafting-Orders-Icon:16:16|a Bugfixes:")
                -- DEFAULT_CHAT_FRAME:AddMessage("   Castbar settings should now be better on Cata, might still need some tweaks.")
                -- DEFAULT_CHAT_FRAME:AddMessage("   +Many more... Keep bug reporting please.")
                -- -- DEFAULT_CHAT_FRAME:AddMessage("   Reverted all name logic to 1.3.8b version. It's old and not optimal but at least it doesn't taint(?). I will never touch this again until TWW >_>")
                -- --DEFAULT_CHAT_FRAME:AddMessage("   A lot of behind the scenes Name logic changed. Should now work better and be happier with other addons.")
            end)
        else
            BetterBlizzFramesDB.scStart = nil
        end
    end
end

local function NewsUpdateMessage()
    DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames news:")
    DEFAULT_CHAT_FRAME:AddMessage("|A:QuestNormal:16:16|a New Settings:")
    DEFAULT_CHAT_FRAME:AddMessage("   - Castbar Edge Highlighter now uses seconds instead of percentages.")
    DEFAULT_CHAT_FRAME:AddMessage("   - Added \"Hide Player Guide Flag\" setting.")

    DEFAULT_CHAT_FRAME:AddMessage("|A:Professions-Crafting-Orders-Icon:16:16|a Bugfixes:")
    DEFAULT_CHAT_FRAME:AddMessage("   Fixed Overshields for PlayerFrame/TargetFrame etc after Blizzard change.")
    DEFAULT_CHAT_FRAME:AddMessage("   A lot of behind the scenes Name logic changed. Should now work better and be happier with other addons.")

    DEFAULT_CHAT_FRAME:AddMessage("|A:GarrisonTroops-Health:16:16|a Patreon link: www.patreon.com/bodydev")
end

-- added minimap hider and auto hider

local function CheckForUpdate()
    if not BetterBlizzFramesDB.hasSaved then
        BetterBlizzFramesDB.updates = addonUpdates
        return
    end
    if not BetterBlizzFramesDB.updates or BetterBlizzFramesDB.updates ~= addonUpdates then
        SendUpdateMessage()
        BetterBlizzFramesDB.updates = addonUpdates
    end
end

local function LoadingScreenDetector(_, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_ENABLED" then
        BetterBlizzFramesDB.wasOnLoadingScreen = true

        BBF.MinimapHider()

    elseif event == "LOADING_SCREEN_DISABLED" or event == "PLAYER_LEAVING_WORLD" then
        if BetterBlizzFramesDB.playerFrameOCD then
            BBF.FixStupidBlizzPTRShit()
        end

        BBF.MinimapHider()

        C_Timer.After(2, function()
            BBF.ChangeCastbarSizes()
            BetterBlizzFramesDB.wasOnLoadingScreen = false
        end)
    end
end
local LoadingScreenFrame = CreateFrame("Frame")
LoadingScreenFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
LoadingScreenFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
LoadingScreenFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
LoadingScreenFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
LoadingScreenFrame:SetScript("OnEvent", LoadingScreenDetector)

-- Function to check combat and show popup if in combat
function BBF.checkCombatAndWarn()
    if InCombatLockdown() then
        if not BetterBlizzFramesDB.wasOnLoadingScreen then
            if IsActiveBattlefieldArena() then
                return true -- Player is in combat but don't show the popup during arena
            else
                StaticPopup_Show("BetterBlizzFrames_COMBAT_WARNING")
                return true -- Player is in combat and outside of arena, so show the pop-up
            end
        end
    end
    return false -- Player is not in combat
end

function BBF.GetOppositeAnchor(anchor)
    local opposites = {
        LEFT = "RIGHT",
        RIGHT = "LEFT",
        TOP = "BOTTOM",
        BOTTOM = "TOP",
        TOPLEFT = "BOTTOMRIGHT",
        TOPRIGHT = "BOTTOMLEFT",
        BOTTOMLEFT = "TOPRIGHT",
        BOTTOMRIGHT = "TOPLEFT",
    }
    return opposites[anchor] or "CENTER"
end

--------------------------------------
-- CLICKTHROUGH
--------------------------------------
function BBF.ClickthroughFrames()
	if not InCombatLockdown() then
        local shift = IsShiftKeyDown()
        if BetterBlizzFramesDB.playerFrameClickthrough then
            PlayerFrame:SetMouseClickEnabled(shift)
        end

        if BetterBlizzFramesDB.targetFrameClickthrough then
            TargetFrame:SetMouseClickEnabled(shift)
            TargetFrameToT:SetMouseClickEnabled(false)
        end

        if BetterBlizzFramesDB.focusFrameClickthrough then
            FocusFrame:SetMouseClickEnabled(shift)
            FocusFrameToT:SetMouseClickEnabled(false)
        end
	end
end

local function HookClassComboPoints()
    -- local db = BetterBlizzFramesDB
    -- local hideLvl = db.hideLevelText
    -- local alwaysHideLvl = hideLvl and db.hideLevelTextAlways
    -- if db.moveResourceToTarget then
    --     if db.moveResourceToTargetRogue then SetupClassComboPoints(RogueComboPointBarFrame, (alwaysHideLvl and db.classicFrames and roguePositionsHiddenLvlClassic) or (db.classicFrames and roguePositionsClassic) or roguePositions, "ROGUE", 0.5, -44, -2, true) end
    --     if db.moveResourceToTargetDruid then SetupClassComboPoints(DruidComboPointBarFrame, druidPositions, "DRUID", 0.55, -53, -2, true) end
    --     if db.moveResourceToTargetWarlock then SetupClassComboPoints(WarlockPowerFrame, warlockPositions, "WARLOCK", 0.6, -56, 1) end
    --     if db.moveResourceToTargetMage then SetupClassComboPoints(MageArcaneChargesFrame, magePositions, "MAGE", 0.7, -61, -4) end
    --     if db.moveResourceToTargetMonk then SetupClassComboPoints(MonkHarmonyBarFrame, monkPositions, "MONK", 0.5, -44, -2, true) end
    --     if db.moveResourceToTargetEvoker then SetupClassComboPoints(EssencePlayerFrame, evokerPositions, "EVOKER", 0.65, -50, 0.5, true) end
    --     if db.moveResourceToTargetPaladin then SetupClassComboPoints(PaladinPowerBarFrame, paladinPositions, "PALADIN", 0.75, -61, -8, true) end
    --     if db.moveResourceToTargetDK then SetupClassComboPoints(RuneFrame, dkPositions, "DEATHKNIGHT", 0.7, -50.5, 0.5, true) end

    --     hookedResourceFrames = true
    -- end
end

local function ScaleClassResource()
    local _, playerClass = UnitClass("player")
    local key = "classResource" .. playerClass .. "Scale"
    local scale = BetterBlizzFramesDB[key] or 1.0

    local resourceFrames = {
        WARLOCK = ShardBarFrame,
        ROGUE = RogueComboPointBarFrame,
        DRUID = EclipseBarFrame,
        PALADIN = PaladinPowerBar,
        DEATHKNIGHT = RuneFrame,
        PRIEST = PriestBarFrame,
        MONK = MonkHarmonyBar,
        --EVOKER = EssencePlayerFrame,
        --MAGE = MageArcaneChargesFrame,
    }

    for _, frame in pairs(resourceFrames) do
        if frame then
            frame:SetScale(scale)
        end
    end

end


function BBF.UpdateClassComboPoints()
    HookClassComboPoints()
    ScaleClassResource()
end



function BBF.ScaleUnitFrames()
    local db = BetterBlizzFramesDB
    PlayerFrame:SetScale(db.playerFrameScale)
    TargetFrame:SetScale(db.targetFrameScale)
    FocusFrame:SetScale(db.focusFrameScale)
end

-- Function to toggle test mode on and off
function BBF.ToggleLossOfControlTestMode()
    local LossOfControlFrameAlphaBg = BetterBlizzFramesDB.hideLossOfControlFrameBg and 0 or 0.6
    local LossOfControlFrameAlphaLines = BetterBlizzFramesDB.hideLossOfControlFrameLines and 0 or 1
    if not _G.FakeBBFLossOfControlFrame then
        -- Main Frame Creation
        local frame = CreateFrame("Frame", "FakeBBFLossOfControlFrame", UIParent, "BackdropTemplate")
        frame:SetSize(256, 58)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetFrameStrata("MEDIUM")
        frame:SetToplevel(true)
        frame:Hide()

        local iconOnlyMode = BetterBlizzFramesDB.lossOfControlIconOnly

        -- Red Lines Textures
        local redLineTop = frame:CreateTexture(nil, "BACKGROUND")
        redLineTop:SetTexture("Interface\\Cooldown\\Loc-RedLine")
        redLineTop:SetSize(iconOnlyMode and 70 or 236, 27)
        redLineTop:SetPoint("BOTTOM", frame, "TOP", 0, 0)
        frame.RedLineTop = redLineTop

        local redLineBottom = frame:CreateTexture(nil, "BACKGROUND")
        redLineBottom:SetTexture("Interface\\Cooldown\\Loc-RedLine")
        redLineBottom:SetSize(iconOnlyMode and 70 or 236, 27)
        redLineBottom:SetPoint("TOP", frame, "BOTTOM", 0, 0)
        redLineBottom:SetTexCoord(0, 1, 1, 0)
        frame.RedLineBottom = redLineBottom

        frame.blackBg = frame:CreateTexture(nil, "BACKGROUND")
        frame.blackBg:SetTexture("Interface\\Cooldown\\loc-shadowbg")
        frame.blackBg:SetPoint("TOPLEFT", frame.RedLineTop, "BOTTOMLEFT")
        frame.blackBg:SetPoint("BOTTOMRIGHT", frame.RedLineBottom, "TOPRIGHT")

        -- Icon Texture
        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(48, 48)
        icon:SetPoint("CENTER", frame, "CENTER", iconOnlyMode and 0 or -70, 0)
        icon:SetTexture(132298)
        frame.Icon = icon

        frame.Icon.Cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
        frame.Icon.Cooldown:SetAllPoints(frame.Icon)

        -- Ability Name FontString
        local abilityName = frame:CreateFontString(nil, "ARTWORK", "MovieSubtitleFont")
        abilityName:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, -4)
        abilityName:SetSize(0, 20)
        abilityName:SetText("Stunned")
        frame.AbilityName = abilityName

        -- Time Left Frame
        local timeLeft = CreateFrame("Frame", nil, frame)
        timeLeft:SetSize(200, 20)
        timeLeft:SetPoint("TOPLEFT", abilityName, "BOTTOMLEFT", 0, 0)
        frame.TimeLeft = timeLeft

        -- Number and Seconds Text
        local numberText = timeLeft:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
        numberText:SetText("5.5 seconds")
        numberText:SetPoint("LEFT", timeLeft, "LEFT", 0, -3)
        numberText:SetShadowOffset(2, -2)
        numberText:SetTextColor(1,1,1)
        timeLeft.NumberText = numberText

        frame.AbilityName:SetShown(not iconOnlyMode)
        frame.TimeLeft:SetShown(not iconOnlyMode)

        -- Stop Testing Button
        local stopButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        stopButton:SetSize(120, 30)
        stopButton:SetPoint("BOTTOM", redLineBottom, "BOTTOM", 0, -35)
        stopButton:SetText("Stop Testing")
        stopButton:SetScript("OnClick", function() frame:Hide() end)
        frame.StopButton = stopButton

        _G.FakeBBFLossOfControlFrame = frame
    end
    local iconOnlyMode = BetterBlizzFramesDB.lossOfControlIconOnly
    FakeBBFLossOfControlFrame:SetScale((BetterBlizzFramesDB.lossOfControlScale or 1) * 0.9)
    FakeBBFLossOfControlFrame.blackBg:SetAlpha(LossOfControlFrameAlphaBg)
    FakeBBFLossOfControlFrame.RedLineTop:SetAlpha(LossOfControlFrameAlphaLines)
    FakeBBFLossOfControlFrame.RedLineBottom:SetAlpha(LossOfControlFrameAlphaLines)
    FakeBBFLossOfControlFrame.AbilityName:SetShown(not iconOnlyMode)
    FakeBBFLossOfControlFrame.TimeLeft:SetShown(not iconOnlyMode)
    FakeBBFLossOfControlFrame.RedLineTop:SetWidth(iconOnlyMode and 70 or 236)
    FakeBBFLossOfControlFrame.RedLineBottom:SetWidth(iconOnlyMode and 70 or 236)
    FakeBBFLossOfControlFrame.Icon:SetPoint("CENTER", FakeBBFLossOfControlFrame, "CENTER", iconOnlyMode and 0 or -70, 0)
    if BetterBlizzFramesDB.showCooldownOnLoC or iconOnlyMode then
        FakeBBFLossOfControlFrame.Icon.Cooldown:SetCooldown(GetTime(), 20)
    else
        FakeBBFLossOfControlFrame.Icon.Cooldown:Clear()
    end
    FakeBBFLossOfControlFrame:Show()
end

function BBF.ChangeLossOfControlScale()
    if BBFLossOfControlParentFrame then
        BBFLossOfControlParentFrame:SetScale(BetterBlizzFramesDB.lossOfControlScale or 1)
        if FakeBBFLossOfControlFrame then
            FakeBBFLossOfControlFrame:SetScale((BetterBlizzFramesDB.lossOfControlScale or 1) * 0.9)
        end
    end
    if LossOfControlFrame then
        LossOfControlFrame:SetScale(BetterBlizzFramesDB.lossOfControlScale or 1)
    end
end

function BBF.ChangeTotemFrameScale()
    if BetterBlizzFramesDB.totemFrameScale and TotemFrame then
        TotemFrame:SetScale(BetterBlizzFramesDB.totemFrameScale)
    end
end

-- Warlock Alternate Power Clickthrough
local function DisableClickForWarlockPowerFrame()
    if WarlockPowerFrame then
        WarlockPowerFrame:SetMouseClickEnabled(false)
    end
end

-- Rogue Alternate Power Clickthrough
local function DisableClickForRogueComboPointBarFrame()
    if RogueComboPointBarFrame then
        RogueComboPointBarFrame:SetMouseClickEnabled(false)
    end
end

-- Druid Alternate Power Clickthrough
local function DisableClickForDruidComboPointBarFrame()
    if DruidComboPointBarFrame then
        DruidComboPointBarFrame:SetMouseClickEnabled(false)
    end
end

-- Paladin Alternate Power Clickthrough
local function DisableClickForPaladinPowerBarFrame()
    if PaladinPowerBarFrame then
        PaladinPowerBarFrame:SetMouseClickEnabled(false)
    end
end

-- Death Knight Alternate Power Clickthrough
local function DisableClickForRuneFrame()
    if RuneFrame then
        RuneFrame:SetMouseClickEnabled(false)
    end
end

-- Evoker Alternate Power Clickthrough
local function DisableClickForEssencePlayerFrame()
    if EssencePlayerFrame then
        EssencePlayerFrame:SetMouseClickEnabled(false)
    end
end

local function DisableClickForClassSpecificFrame()
    if not cataReady then return end
    local _, playerClass = UnitClass("player")
    if playerClass == "WARLOCK" and WarlockPowerFrame then
        hooksecurefunc(WarlockPowerBar, "UpdatePower", DisableClickForWarlockPowerFrame)
    elseif playerClass == "ROGUE" and RogueComboPointBarFrame then
        hooksecurefunc(RogueComboPointBarFrame, "UpdatePower", DisableClickForRogueComboPointBarFrame)
    elseif playerClass == "DRUID" and DruidComboPointBarFrame then
        hooksecurefunc(DruidComboPointBarFrame, "UpdatePower", DisableClickForDruidComboPointBarFrame)
    elseif playerClass == "PALADIN" and PaladinPowerBarFrame then
        hooksecurefunc(PaladinPowerBar, "UpdatePower", DisableClickForPaladinPowerBarFrame)
    elseif playerClass == "DEATHKNIGHT" and RuneFrame then
        hooksecurefunc(RuneFrame, "UpdateRunes", DisableClickForRuneFrame)
    elseif playerClass == "EVOKER" and EssencePlayerFrame then
        hooksecurefunc(EssencePlayerFrame, "UpdatePower", DisableClickForEssencePlayerFrame)
    end
end

local ClickthroughFrames = CreateFrame("frame")
ClickthroughFrames:SetScript("OnEvent", function()
    BBF.ClickthroughFrames()
end)
ClickthroughFrames:RegisterEvent("MODIFIER_STATE_CHANGED")



local resourceFrames = {
    WARLOCK = ShardBarFrame,
    ROGUE = RogueComboPointBarFrame,
    DRUID = EclipseBarFrame,
    PALADIN = PaladinPowerBar,
    DEATHKNIGHT = RuneFrame,
    PRIEST = PriestBarFrame,
    MONK = MonkHarmonyBar,
    --EVOKER = EssencePlayerFrame,
    --MAGE = MageArcaneChargesFrame,
}

local function DisableClickForResourceFrame(frame)
    if BBF.MovingResource then return end
    frame:SetMouseClickEnabled(false)
end


local function CheckForResourceConflicts()
    -- local db = BetterBlizzFramesDB
    -- local conflicts = {
    --     ROGUE = db.moveResourceToTargetRogue,
    --     DRUID = db.moveResourceToTargetDruid,
    --     WARLOCK = db.moveResourceToTargetWarlock,
    --     MAGE = db.moveResourceToTargetMage,
    --     MONK = db.moveResourceToTargetMonk,
    --     EVOKER = db.moveResourceToTargetEvoker,
    --     PALADIN = db.moveResourceToTargetPaladin,
    --     DEATHKNIGHT = db.moveResourceToTargetDK,
    -- }

    -- local _, class = UnitClass("player")
    -- if db.moveResourceToTarget and conflicts[class] then
    --     print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Disable \"Move Resource to TargetFrame\" for this class in order to move Resource normally.")
    --     return true
    -- end
    return false
end
function BBF.SetResourcePosition()
    if not BetterBlizzFramesDB.moveResource then return end
    if CheckForResourceConflicts() then return end

    local _, class = UnitClass("player")
    local frame = resourceFrames[class]
    if not frame then return end

    if not BetterBlizzFramesDB.moveResourceStackPos then
        BetterBlizzFramesDB.moveResourceStackPos = {}
    end

    local pos = BetterBlizzFramesDB.moveResourceStackPos[class]
    if pos then
        if not frame.ogPoint then
            local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
            frame.ogPoint = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
        end

        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)

        hooksecurefunc(frame, "SetPoint", function(self)
            if self.changing then return end
            self.changing = true
            local pos = BetterBlizzFramesDB.moveResourceStackPos[class]
            if pos then
                self:ClearAllPoints()
                self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
            else
                self:ClearAllPoints()
                self:SetPoint(frame.ogPoint.point, frame.ogPoint.relativeTo, frame.ogPoint.relativePoint, frame.ogPoint.xOfs, frame.ogPoint.yOfs)
            end
            self.changing = false
        end)
    end
end
function BBF.ResetResourcePosition()
    local _, class = UnitClass("player")
    local frame = resourceFrames[class]
    if not frame or not frame.ogPoint then return end

    -- Reset frame to its original position
    frame:ClearAllPoints()
    frame:SetPoint(frame.ogPoint.point, frame.ogPoint.relativeTo, frame.ogPoint.relativePoint, frame.ogPoint.xOfs, frame.ogPoint.yOfs)
end
function BBF.EnableResourceMovement()
    if CheckForResourceConflicts() then return end

    local _, class = UnitClass("player")
    local frame = resourceFrames[class]
    if not frame then return end

    if BBF.MovingResource then return end

    -- Make the frame draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetMouseClickEnabled(true)

    if class == "MONK" then
        for i = 1, 5 do
            local orb = frame["lightEnergy"..i]
            if orb then
                orb:SetScript("OnMouseDown", function(self, button)
                    if button == "LeftButton" and IsControlKeyDown() then
                        frame:StartMoving()
                    end
                end)

                orb:SetScript("OnMouseUp", function(self)
                    frame:StopMovingOrSizing()

                    -- Ensure the database exists
                    if not BetterBlizzFramesDB.moveResourceStackPos then
                        BetterBlizzFramesDB.moveResourceStackPos = {}
                    end

                    -- Save class-specific position
                    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
                    BetterBlizzFramesDB.moveResourceStackPos[class] = {
                        point = point,
                        relativePoint = relativePoint,
                        xOfs = xOfs,
                        yOfs = yOfs
                    }
                end)
            end
        end
    end

    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and IsControlKeyDown() then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()

        -- Ensure the database exists
        if not BetterBlizzFramesDB.moveResourceStackPos then
            BetterBlizzFramesDB.moveResourceStackPos = {}
        end

        -- Save class-specific position
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        BetterBlizzFramesDB.moveResourceStackPos[class] = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)
    BBF.MovingResource = true
end


function BBF.ActionBarIconZoom()
    --local texCoords = BetterBlizzFramesDB.playerFrameOCDZoom and {0.06, 0.94, 0.06, 0.94} or {0, 1, 0, 1}
    local texCoords = (BetterBlizzFramesDB.playerFrameOCD and BetterBlizzFramesDB.playerFrameOCDZoom) and {0.04, 0.98, 0.04, 0.95} or {0, 1, 0, 1}
    local function applyTexCoord(frame)
        if frame and frame.SetTexCoord then
            frame:SetTexCoord(unpack(texCoords))
        end
    end
    for i = 1, 12 do
        local icons = {
            _G["ActionButton" .. i .. "Icon"],
            _G["MultiBarBottomLeftButton" .. i .. "Icon"],
            _G["MultiBarBottomRightButton" .. i .. "Icon"],
            _G["MultiBarRightButton" .. i .. "Icon"],
            _G["MultiBarLeftButton" .. i .. "Icon"],
            _G["MultiBar5Button" .. i .. "Icon"],
            _G["MultiBar6Button" .. i .. "Icon"],
            _G["MultiBar7Button" .. i .. "Icon"],
            _G["PetActionButton" .. i .. "Icon"],
            _G["StanceButton" .. i .. "Icon"]
        }
        for _, icon in ipairs(icons) do
            applyTexCoord(icon)
        end
    end
end


function BBF.MoveToTFrames()
    if not InCombatLockdown() then
        TargetFrameToT:ClearAllPoints()
        if BetterBlizzFramesDB.targetToTAnchor == "BOTTOMRIGHT" then
            --TargetFrameToT:SetPoint(BBF.GetOppositeAnchor(BetterBlizzFramesDB.targetToTAnchor),TargetFrame,BetterBlizzFramesDB.targetToTAnchor,BetterBlizzFramesDB.targetToTXPos - 108,BetterBlizzFramesDB.targetToTYPos + 10)
            TargetFrameToT:SetPoint(BetterBlizzFramesDB.targetToTAnchor,TargetFrame,BetterBlizzFramesDB.targetToTAnchor,BetterBlizzFramesDB.targetToTXPos - 35,BetterBlizzFramesDB.targetToTYPos - 10)
        else
            TargetFrameToT:SetPoint(BBF.GetOppositeAnchor(BetterBlizzFramesDB.targetToTAnchor),TargetFrame,BetterBlizzFramesDB.targetToTAnchor,BetterBlizzFramesDB.targetToTXPos,BetterBlizzFramesDB.targetToTYPos)
        end
        TargetFrameToT:SetScale(BetterBlizzFramesDB.targetToTScale)
        TargetFrameToT:SetFrameStrata("MEDIUM")
        --TargetFrameToT.SetPoint=function()end

        FocusFrameToT:ClearAllPoints()
        if BetterBlizzFramesDB.focusToTAnchor == "BOTTOMRIGHT" then
            --FocusFrameToT:SetPoint(BBF.GetOppositeAnchor(BetterBlizzFramesDB.focusToTAnchor),FocusFrame,BetterBlizzFramesDB.focusToTAnchor,BetterBlizzFramesDB.focusToTXPos - 108,BetterBlizzFramesDB.focusToTYPos + 10)
            FocusFrameToT:SetPoint(BetterBlizzFramesDB.focusToTAnchor,FocusFrame,BetterBlizzFramesDB.focusToTAnchor,BetterBlizzFramesDB.focusToTXPos - 35,BetterBlizzFramesDB.focusToTYPos - 10)
        else
            FocusFrameToT:SetPoint(BBF.GetOppositeAnchor(BetterBlizzFramesDB.focusToTAnchor),FocusFrame,BetterBlizzFramesDB.focusToTAnchor,BetterBlizzFramesDB.focusToTXPos,BetterBlizzFramesDB.focusToTYPos)
        end
        FocusFrameToT:SetScale(BetterBlizzFramesDB.focusToTScale)
        FocusFrameToT:SetFrameStrata("MEDIUM")
        --FocusFrameToT.SetPoint=function()end
    else
        C_Timer.After(1.5, function()
            BBF.MoveToTFrames()
        end)
    end
end


local legacyComboPowerTypes = {
    MONK = Enum.PowerType.Chi,
    PALADIN = Enum.PowerType.HolyPower,
    MAGE = Enum.PowerType.ArcaneCharges,
    WARLOCK = Enum.PowerType.SoulShards,
    DEATHKNIGHT = Enum.PowerType.Runes,
    EVOKER = Enum.PowerType.Essence,
}

local function GetLegacyComboStartIndex()
    local _, class = UnitClass("player") -- class will be "PALADIN", "MONK", etc.
    local classKey = class:sub(1, 1):upper() .. class:sub(2):lower() -- "Paladin"

    if BetterBlizzFramesDB["ignore" .. classKey .. "LegacyCombos"] then return nil end

    if class == "MONK" or class == "DEATHKNIGHT" or class == "EVOKER" then
        return 1
    end
    if class == "MAGE" then return 2 end
    return 2
end

function BBF.ClassColorLegacyCombos()
    if not BBP.isMoP then return end
    if not (BetterBlizzFramesDB.enableLegacyComboPointsMulticlass and BetterBlizzFramesDB.legacyMulticlassComboClassColor) then return end
    if not ComboFrame or not ComboFrame.ComboPoints then return end

    local startIndex = GetLegacyComboStartIndex()
    if not startIndex then return end

    local _, class = UnitClass("player")
    local powerType = legacyComboPowerTypes[class]
    if not powerType then return end

    local frame = ComboFrame
    local comboIndex = startIndex
    local maxPoints = UnitPowerMax("player", powerType)

    -- Shared baseline config (Monk-style)
    local baseConfig = {
        texture = "AncientMana",
        texCoord = {0, 1, 0, 1},
        size = {14, 14},
        pointOffset = {-1, 1.5},
        color = {1, 1, 1}, -- Monk green
    }

    -- Optional class-specific color overrides
    local classOverrides = {
        WARLOCK  = { color = {1, 0.388, 0.898} },
        PALADIN  = { color = {1, 0.961, 0} },
        MONK = { color = {0.341, 1, 0.612}},
        DEATHKNIGHT = {
            specs = {
                [251] = { color = {0.2, 0.8, 1} },   -- Frost
                [250] = { -- Blood
                color = {1, 0, 0.11},
                desaturated = true
                },
                [252] = { -- Unholy
                    color = {0.22, 1, 0.27},
                },
            }
        }
    }

    local specID = C_SpecializationInfo.GetSpecialization() and C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
    local config = {}

    -- Use class spec override if available
    local classConfig = classOverrides[class]
    if classConfig then
        if classConfig.specs and specID and classConfig.specs[specID] then
            config = classConfig.specs[specID]
        else
            config = classConfig
        end
    end

    -- Merge with baseline
    setmetatable(config, { __index = baseConfig })

    if class == "DEATHKNIGHT" then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        f:SetScript("OnEvent", function(_, _, unit)
            if unit == "player" then
                BBF.ClassColorLegacyCombos()
            end
        end)
    end

    for i = 1, maxPoints do
        local point = frame.ComboPoints[comboIndex]
        if point then
            point.Highlight:SetAtlas(config.texture)
            point.Highlight:SetTexCoord(unpack(config.texCoord))
            point.Highlight:SetSize(unpack(config.size))
            point.Highlight:SetPoint("TOPLEFT", point, "TOPLEFT", unpack(config.pointOffset))
            point.Highlight:SetVertexColor(unpack(config.color))
        end
        comboIndex = comboIndex + 1
    end
end



function BBF.GenericLegacyComboSupport()
    if not BetterBlizzFramesDB.enableLegacyComboPointsMulticlass then return end
    if C_CVar.GetCVar("comboPointLocation") ~= "1" then return end
    if not ComboFrame or not ComboFrame.ComboPoints then return end
    local _, class = UnitClass("player")
    local supported = {
        MONK = true, DEATHKNIGHT = true, EVOKER = true,
        WARLOCK = true, PALADIN = true, MAGE = true,
    }
    if not supported[class] then return end

    local enabled = GetLegacyComboStartIndex()
    if not enabled then return end

    local lastComboPoints = 0

    local function ComboPointShineFadeIn(frame)
        local fadeInfo = {
            mode = "IN",
            timeToFade = COMBOFRAME_SHINE_FADE_IN,
            finishedFunc = ComboPointShineFadeOut,
            finishedArg1 = frame,
        }
        UIFrameFade(frame, fadeInfo)
    end

    local function ComboPointShineFadeOut(frame)
        UIFrameFadeOut(frame, COMBOFRAME_SHINE_FADE_OUT)
    end

    local showAlways = BetterBlizzFramesDB.alwaysShowLegacyComboPoints

    local arcaneChargeInstanceID
    local cachedArcaneCharges = 0
    local ARCANE_BLAST_SPELL_ID = 36032

    local returnEarly
    if class == "MAGE" then
        local function ScanInitialAuras()
            for i = 1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HARMFUL")
                if not aura then break end
                if aura.spellId == ARCANE_BLAST_SPELL_ID then
                    arcaneChargeInstanceID = aura.auraInstanceID
                    cachedArcaneCharges = aura.applications or 0
                    break
                end
            end
        end

        ScanInitialAuras()


        local frame = CreateFrame("Frame")
        local ARCANE_SPEC_ID = 62
        local function IsArcaneSpec()
            if BBF.isMoP then
                local specID = C_SpecializationInfo.GetSpecialization()
                return specID and C_SpecializationInfo.GetSpecializationInfo(specID) == ARCANE_SPEC_ID
            else
                if class == "MAGE" then
                    local spec1, _, _, _, pointsSpent1 = GetTalentTabInfo(1)
                    local spec2, _, _, _, pointsSpent2 = GetTalentTabInfo(2)
                    local spec3, _, _, _, pointsSpent3 = GetTalentTabInfo(3)
                    return pointsSpent1 > pointsSpent2 and pointsSpent1 > pointsSpent3
                end
                return false
            end
        end

        local function UpdateMageComboTracking()
            local isArcane = IsArcaneSpec()
            if isArcane then
                frame:RegisterUnitEvent("UNIT_AURA", "player")
                ScanInitialAuras()
                returnEarly = false
            else
                frame:UnregisterEvent("UNIT_AURA")
                ComboFrame:Hide()
                arcaneChargeInstanceID = nil
                cachedArcaneCharges = 0
                returnEarly = true
            end
        end

        frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        frame:SetScript("OnEvent", function(self, event, arg1, arg2)
            if event == "UNIT_AURA" then
                local updateInfo = arg2
                if not updateInfo then return end

                if updateInfo.addedAuras then
                    for _, aura in ipairs(updateInfo.addedAuras) do 
                        if aura.spellId == ARCANE_BLAST_SPELL_ID then
                            arcaneChargeInstanceID = aura.auraInstanceID
                            cachedArcaneCharges = aura.applications or 0
                        end
                    end
                end

                if updateInfo.updatedAuraInstanceIDs then
                    for _, auraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
                        local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
                        if aura and aura.spellId == ARCANE_BLAST_SPELL_ID then
                            arcaneChargeInstanceID = auraInstanceID
                            cachedArcaneCharges = aura.applications or 0
                        end
                    end
                end

                if updateInfo.removedAuraInstanceIDs then
                    for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
                        if arcaneChargeInstanceID == auraInstanceID then
                            cachedArcaneCharges = 0
                            arcaneChargeInstanceID = nil
                        end
                    end
                end
            elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
                UpdateMageComboTracking()
            end
        end)

        C_Timer.After(1, function()
            UpdateMageComboTracking()
        end)
    end


    local function UpdateGenericLegacyCombo()
        local powerType = legacyComboPowerTypes[class]
        if not powerType then return end
        if returnEarly then
            ComboFrame:Hide()
            return
        end
        local comboPoints
        if class == "MAGE" then
            comboPoints = cachedArcaneCharges
        else
            comboPoints = UnitPower("player", powerType)
        end

        local maxComboPoints = (class == "MAGE") and 4 or UnitPowerMax("player", powerType)

        local frame = ComboFrame
        ComboFrame:Show()
        ComboFrame:SetAlpha(1)
        local comboIndex = GetLegacyComboStartIndex()
        if not comboIndex then return end

        for i = 1, maxComboPoints do
            local point = frame.ComboPoints[comboIndex]
            if point then
                -- Always show the background
                point:Show()
                point:SetAlpha(1)

                -- Only show highlight when active or animating
                local isActive = i <= comboPoints
                point:SetShown(showAlways or isActive)

                if point.Highlight then
                    point.Highlight:SetAlpha(isActive and 1 or 0)
                end

                if isActive and i > lastComboPoints then
                    local highlight = point.Highlight
                    local shine = point.Shine

                    if highlight and shine then
                        local fadeInfo = {
                            mode = "IN",
                            timeToFade = COMBOFRAME_HIGHLIGHT_FADE_IN,
                            finishedFunc = ComboPointShineFadeIn,
                            finishedArg1 = shine,
                        }
                        UIFrameFade(highlight, fadeInfo)
                    end
                end

                comboIndex = comboIndex + 1
            end
        end

        if comboPoints == 0 and not showAlways then
            frame:Hide()
        else
            frame:SetAlpha(1)
            frame:Show()
        end

        UIFrameFadeRemoveFrame(frame)

        lastComboPoints = comboPoints
    end

    hooksecurefunc("ComboFrame_Update", UpdateGenericLegacyCombo)
end


function BBF.UpdateLegacyComboPosition()
    if not ComboFrame then return end
    local db = BetterBlizzFramesDB
    local x = db.legacyComboXPos
    local y = db.legacyComboYPos
    local scale = db.legacyComboScale

    local extraOffsetY = 0--not db.classicFrames and 2.5 or 0
    local extraOffsetX = 0--not db.classicFrames and -5 or 0

    ComboFrame:ClearAllPoints()
    ComboFrame:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", x+extraOffsetX, y+extraOffsetY)
    ComboFrame:SetScale(scale)
end

function BBF.FixLegacyComboPointsLocation()
    if BetterBlizzFramesDB.legacyCombosTurnedOff then
        C_CVar.SetCVar("comboPointLocation", "2")
        return
    end
    if BetterBlizzFramesDB.enableLegacyComboPoints then
        C_CVar.SetCVar("comboPointLocation", "1")
    elseif BetterBlizzFramesDB.comboPointLocation then
        C_CVar.SetCVar("comboPointLocation", BetterBlizzFramesDB.comboPointLocation)
    end
    if C_CVar.GetCVar("comboPointLocation") == "1" and ComboFrame and BetterBlizzFramesDB.enableLegacyComboPoints then
        ComboFrame:SetParent(TargetFrame)
        ComboFrame:SetFrameStrata("HIGH")
        BBF.UpdateLegacyComboPosition()
    end
end

function BBF.AlwaysShowLegacyComboPoints()
    if not BetterBlizzFramesDB.alwaysShowLegacyComboPoints then return end
    if BetterBlizzFramesDB.instantComboPoints then return end
    if BBF.AlwaysShowLegacyComboPoints then return end
    local _, class = UnitClass("player")
    if class ~= "ROGUE" and class ~= "DRUID" then return end
    local function UpdateLegacyComboFrame()
        local frame = ComboFrame
        local comboPoints = GetComboPoints("player", "target")
        local maxComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
        frame:Show()
        frame:SetAlpha(1)
        local comboIndex = frame.startComboPointIndex or 2
        for i = 1, maxComboPoints do
            local point = frame.ComboPoints[comboIndex]
            if point then
                point:Show()
                point:SetAlpha(1)
                point.Highlight:SetAlpha(i <= comboPoints and 1 or 0)
                point.Shine:SetAlpha(0)
                comboIndex = comboIndex + 1
            end
        end
    end
    if C_CVar.GetCVar("comboPointLocation") == "1" and ComboFrame then
        hooksecurefunc("ComboFrame_Update", UpdateLegacyComboFrame)
        UpdateLegacyComboFrame()
    end
    BBF.AlwaysShowLegacyComboPoints = true
end

function BBF.ApplyLegacyBlueCombos(isEnabled)
    if not ComboFrame or not ComboFrame.ComboPoints then return end

    local frame = ComboFrame
    local comboIndex = 1--frame.startComboPointIndex or 2
    local maxPoints = UnitPowerMax("player", Enum.PowerType.Chi)

    for i = 1, maxPoints do
        local point = frame.ComboPoints[comboIndex]
        if point then
            if isEnabled then
                point.Highlight:SetAtlas("AncientMana")
                point.Highlight:SetTexCoord(0, 1, 0, 1)
                point.Highlight:SetSize(14, 14)
                point.Highlight:SetPoint("TOPLEFT", point, "TOPLEFT", -1, 1.5)
                point.charged = true
            else
                point.Highlight:SetTexture(130973) -- original texture
                point.Highlight:SetTexCoord(0.375, 0.5625, 0, 1)
                point.Highlight:SetSize(8, 16)
                point.Highlight:SetPoint("TOPLEFT", point, "TOPLEFT", 2, 0)
                point.charged = false
            end
        end
        comboIndex = comboIndex + 1
    end
end

local function GetRogueAnticipationStacks()
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(114015)
    return aura and aura.applications or 0
end

function BBF.LegacyBlueCombos()
    if not BetterBlizzFramesDB.legacyBlueComboPoints then return end
    if C_CVar.GetCVar("comboPointLocation") ~= "1" then return end
    local _, class = UnitClass("player")
    if class == "ROGUE" then
        local function BlueLegacyComboRogue()
            local frame = ComboFrame
            if not frame or not frame.ComboPoints then return end

            local anticipationStacks = GetRogueAnticipationStacks()

            local comboIndex = frame.startComboPointIndex or 2

            for i = 1, 5 do
                local point = frame.ComboPoints[comboIndex]
                if point then
                    local isCharged = i <= anticipationStacks

                    if isCharged then
                        point.Highlight:SetAtlas("AncientMana")
                        point.Highlight:SetTexCoord(0, 1, 0, 1)
                        point.Highlight:SetSize(14, 14)
                        point.Highlight:SetPoint("TOPLEFT", point, "TOPLEFT", -1, 1.5)
                        point.charged = true
                    elseif point.charged then
                        point.Highlight:SetTexture(130973)
                        point.Highlight:SetTexCoord(0.375, 0.5625, 0, 1)
                        point.Highlight:SetSize(8, 16)
                        point.Highlight:SetPoint("TOPLEFT", point, "TOPLEFT", 2, 0)
                        point.charged = false
                    end

                    comboIndex = comboIndex + 1
                end
            end
        end
        if ComboFrame then hooksecurefunc("ComboFrame_Update", BlueLegacyComboRogue) end
    -- elseif class == "DRUID" then
    --     BBF.DruidBlueComboPoints()
    end
end


function BBF.InstantComboPoints()
    if not BetterBlizzFramesDB.instantComboPoints then return end
    if BBF.InstantComboPointsActive then return end
    -- Call the function for each frame
    local _, class = UnitClass("player")

    local function UpdateRogueComboPoints(self)
        if not self or self:IsForbidden() then return end
        local comboPoints = UnitPower("player", self.powerType)
        local chargedPowerPoints = GetUnitChargedPowerPoints("player") or {}

        for i, point in ipairs(self.classResourceButtonTable) do
            local isFull = i <= comboPoints
            local isCharged = tContains(chargedPowerPoints, i)

            -- Stop all animations to enforce instant update
            for _, transitionAnim in ipairs(point.transitionAnims) do
                transitionAnim:Stop()
            end

            -- Directly set textures and visibility
            point.IconUncharged:SetAlpha(isFull and not isCharged and 1 or 0)
            point.IconCharged:SetAlpha(isFull and isCharged and 1 or 0)
            point.BGActive:SetAlpha(isFull and 1 or 0)
            point.BGInactive:SetAlpha(isFull and 0 or 1)
            point.FXUncharged:SetAlpha(isFull and not isCharged and 1 or 0)
            point.FXCharged:SetAlpha(isFull and isCharged and 1 or 0)

            -- ChargedFrame logic:
            if isCharged then
                if isFull then
                    point.ChargedFrameActive:SetAlpha(1)  -- Show Active only if both charged and filled
                    point.ChargedFrameInactive:SetAlpha(0) -- Hide Inactive since it's full
                else
                    point.ChargedFrameActive:SetAlpha(0)  -- Hide Active since no combo point is in it
                    point.ChargedFrameInactive:SetAlpha(1) -- Show Inactive since it's charged but empty
                end
            else
                -- If not charged, hide both charged frames
                point.ChargedFrameActive:SetAlpha(0)
                point.ChargedFrameInactive:SetAlpha(0)
            end
        end
    end

    local function UpdateLegacyComboFrame()
        local frame = ComboFrame
        if not frame or not frame.ComboPoints then return end

        local comboPoints = GetComboPoints("player", "target")
        local maxComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
        local showAlways = BetterBlizzFramesDB.alwaysShowLegacyComboPoints or false

        frame:SetAlpha(1)
        frame:Show()

        local comboIndex = frame.startComboPointIndex or 2

        for i = 1, maxComboPoints do
            local point = frame.ComboPoints[comboIndex]
            if point then
                UIFrameFadeRemoveFrame(point.Highlight)
                UIFrameFadeRemoveFrame(point.Shine)

                point:SetAlpha(1)
                point.Highlight:SetAlpha(i <= comboPoints and 1 or 0)
                point.Shine:SetAlpha(0)

                if showAlways then
                    point:Show()
                else
                    point:SetShown(i <= comboPoints)
                end

                comboIndex = comboIndex + 1
            end
        end

        if comboPoints == 0 and not showAlways then
            frame:Hide()
        end

        UIFrameFadeRemoveFrame(frame)
    end

    local function UpdateDruidComboPoints(self)
        if not self or self:IsForbidden() then return end
        local comboPoints = UnitPower("player", self.powerType)

        for i, point in ipairs(self.classResourceButtonTable) do
            local isFull = i <= comboPoints

            -- Stop animations for instant update
            if point.activateAnim then point.activateAnim:Stop() end
            if point.deactivateAnim then point.deactivateAnim:Stop() end

            -- Directly set textures and visibility
            point.Point_Icon:SetAlpha(isFull and 1 or 0)
            point.BG_Active:SetAlpha(isFull and 1 or 0)
            point.BG_Inactive:SetAlpha(isFull and 0 or 1)

            point.Point_Deplete:SetAlpha(0)
        end
    end

    local function UpdateMonkChi(self)
        if not self or self:IsForbidden() then return end
        local numChi = UnitPower("player", self.powerType)

        for i, point in ipairs(self.classResourceButtonTable) do
            local isFull = i <= numChi

            -- Stop animations for instant updates
            if point.activate then point.activate:Stop() end
            if point.deactivate then point.deactivate:Stop() end

            -- Directly update textures and visibility
            point.Chi_Icon:SetAlpha(isFull and 1 or 0)
            point.Chi_BG_Active:SetAlpha(isFull and 1 or 0)
            point.Chi_BG:SetAlpha(isFull and 0 or 1)

            point.Chi_Deplete:SetAlpha(0)
            point.FX_OuterGlow:SetAlpha(0)
            point.FB_Wind_FX:SetAlpha(0)
        end
    end

    local function UpdateArcaneCharges(self)
        if not self or self:IsForbidden() then return end
        local numCharges = UnitPower("player", self.powerType, true)

        for i, point in ipairs(self.classResourceButtonTable) do
            local isFull = i <= numCharges

            -- Stop animations for instant updates
            if point.activateAnim then point.activateAnim:Stop() end
            if point.deactivateAnim then point.deactivateAnim:Stop() end

            -- Directly update textures and visibility
            point.ArcaneIcon:SetAlpha(isFull and 1 or 0)
            point.ArcaneBG:SetAlpha(isFull and 1 or 0)
            point.Orb:SetAlpha(isFull and 0 or 1)

            point.ArcaneFlare:SetAlpha(0)
            point.ArcaneOuterFX:SetAlpha(0)
            point.ArcaneCircle:SetAlpha(0)
            point.ArcaneTriangle:SetAlpha(0)
            point.ArcaneSquare:SetAlpha(0)
            point.ArcaneDiamond:SetAlpha(0)
            point.FrameGlow:SetAlpha(0)
            point.FBArcaneFX:SetAlpha(0)
        end
    end

    local function UpdatePaladinHolyPower(self)
        if not self or self:IsForbidden() then return end
        local numHolyPower = UnitPower("player", Enum.PowerType.HolyPower)
        local maxHolyPower = UnitPowerMax("player", Enum.PowerType.HolyPower)

        for i = 1, maxHolyPower do
            local rune = self["rune"..i]
            if rune then
                -- Stop all animations
                if rune.activateAnim then rune.activateAnim:Stop() end
                if rune.readyAnim then rune.readyAnim:Stop() end
                if rune.readyLoopAnim then rune.readyLoopAnim:Stop() end
                if rune.depleteAnim then rune.depleteAnim:Stop() end

                -- Hide all FX
                if rune.FX then rune.FX:SetAlpha(0) end
                if rune.Blur then rune.Blur:SetAlpha(0) end
                if rune.Glow then rune.Glow:SetAlpha(0) end
                if rune.DepleteFlipbook then rune.DepleteFlipbook:SetAlpha(0) end

                -- Set active state
                if i <= numHolyPower then
                    if rune.ActiveTexture then rune.ActiveTexture:SetAlpha(1) end
                else
                    if rune.ActiveTexture then rune.ActiveTexture:SetAlpha(0) end
                end
            end
        end

        -- Stop main bar animations
        self.activateAnim:Stop()
        self.readyAnim:Stop()
        self.readyLoopAnim:Stop()
        self.depleteAnim:Stop()

        -- Update bar visuals
        self.ActiveTexture:SetAlpha(numHolyPower > 0 and 1 or 0)
        self.ThinGlow:SetAlpha(numHolyPower > 2 and 1 or 0)
        self.Glow:SetAlpha(numHolyPower == 5 and 1 or 0)
    end

    if BetterBlizzPlatesDB then
        BetterBlizzPlatesDB.instantComboPoints = true
    end
    local BBP = BetterBlizzPlatesDB

    if class == "MONK" then
        hooksecurefunc(MonkHarmonyBarFrame, "UpdatePower", UpdateMonkChi)
        if not BBP then hooksecurefunc(ClassNameplateBarWindwalkerMonkFrame, "UpdatePower", UpdateMonkChi) end
    elseif class == "ROGUE" then
        hooksecurefunc(RogueComboPointBarFrame, "UpdatePower", UpdateRogueComboPoints)
        if not BBP then hooksecurefunc(ClassNameplateBarRogueFrame, "UpdatePower", UpdateRogueComboPoints) end
        if C_CVar.GetCVar("comboPointLocation") == "1" and ComboFrame then hooksecurefunc("ComboFrame_Update", UpdateLegacyComboFrame) end
    elseif class == "DRUID" then
        hooksecurefunc(DruidComboPointBarFrame, "UpdatePower", UpdateDruidComboPoints)
        if not BBP then hooksecurefunc(ClassNameplateBarFeralDruidFrame, "UpdatePower", UpdateDruidComboPoints) end
        if C_CVar.GetCVar("comboPointLocation") == "1" and ComboFrame then hooksecurefunc("ComboFrame_Update", UpdateLegacyComboFrame) end
    -- elseif class == "MAGE" then
    --     hooksecurefunc(MageArcaneChargesFrame, "UpdatePower", UpdateArcaneCharges)
    --     if not BBP then hooksecurefunc(ClassNameplateBarMageFrame, "UpdatePower", UpdateArcaneCharges) end
    elseif class == "PALADIN" then
        hooksecurefunc(PaladinPowerBarFrame, "UpdatePower", UpdatePaladinHolyPower)
        if not BBP then hooksecurefunc(ClassNameplateBarPaladinFrame, "UpdatePower", UpdatePaladinHolyPower) end
    end
    BBF.InstantComboPointsActive = true
end



function BBF.ShowCooldownDuringCC()
    -- if not BetterBlizzFramesDB.fixActionBarCDs then return end
    -- if BBF.ShowCooldownDuringCCActive then return end
    -- local usingOmniCC = C_AddOns.IsAddOnLoaded("OmniCC")
    -- local alwaysHideCCDuration = BetterBlizzFramesDB.fixActionBarCDsAlwaysHideCD

    -- local OmniCCTextUpdater = CreateFrame("Frame")
    -- local trackedButtons = {}

    -- print("shits active")

    -- local function StopTracking(button)
    --     if trackedButtons[button] then
    --         trackedButtons[button] = nil
    --     end
    --     if not next(trackedButtons) then
    --         OmniCCTextUpdater:SetScript("OnUpdate", nil)
    --     end
    -- end

    -- local function TrackButton(button)
    --     if not trackedButtons[button] then
    --         trackedButtons[button] = true
    --         OmniCCTextUpdater:SetScript("OnUpdate", function()
    --             for button in pairs(trackedButtons) do
    --                 if button.chargeCooldown and button.chargeCooldown._occ_display then
    --                     local occText = button.chargeCooldown._occ_display.text
    --                     if occText and not occText:IsShown() then
    --                         occText:Show()
    --                     end
    --                 end
    --             end
    --         end)
    --     end
    -- end

    -- local function UpdateCooldown(self)
    --     if self.cooldown.currentCooldownType ~= 1 then return end
    --     if not self:IsVisible() or not self.action then return end

    --     local start, duration, enable, modRate = 0, 0
    --     local actionType, actionID = GetActionInfo(self.action)
    --     local locStart, locDuration = 0, 0
    --     local chargeInfo

    --     if (actionType == "spell" or actionType == "macro") and actionID then
    --         local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(spell)
    --         if currentCharges then
    --             chargeInfo = {}
    --             chargeInfo.currentCharges = currentCharges
    --             chargeInfo.maxCharges = maxCharges
    --             chargeInfo.cooldownStart = cooldownStart
    --             chargeInfo.cooldownDuration = cooldownDuration
    --             chargeInfo.chargeModRate = chargeModRate or 1
    --         end
    --         if chargeInfo and chargeInfo.currentCharges ~= chargeInfo.maxCharges then
    --             start, duration, modRate = chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration, chargeInfo.chargeModRate
    --         else
    --             locStart, locDuration = GetActionLossOfControlCooldown(actionID);
    --             start, duration, enable, modRate = GetSpellCooldown(actionID)
    --             if not start then
    --                 start, duration, enable, modRate = GetActionCooldown(self.action)
    --             end
    --         end
    --         if not modRate then
    --             modRate = 1
    --         end
    --     else
    --         local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(self.action)
    --         if charges then
    --             start, duration, modRate = chargeStart, chargeDuration, chargeModRate
    --         else
    --             start, duration, enable, modRate = GetActionCooldown(self.action)
    --         end

    --         locStart, locDuration = GetActionLossOfControlCooldown(self.action);
    --     end

    --     if duration == 0 then
    --         if alwaysHideCCDuration then
    --             self.cooldown:SetHideCountdownNumbers(true)
    --             self.cooldown:SetCooldown(0, 0)
    --         end
    --         return
    --     end

    --     if not chargeInfo then
    --         local now = GetTime()
    --         local cdRemaining = (start and duration and duration > 0) and ((start + duration) - now) or 0
    --         local locRemaining = (locStart and locDuration and locDuration > 0) and ((locStart + locDuration) - now) or 0
    --         if locRemaining <= cdRemaining then
    --             return
    --         end
    --     end

    --     self.cooldown:SetHideCountdownNumbers(false)
    --     self.cooldown:SetCooldown(start, duration, modRate)

    --     -- Ensure OmniCC properly shows the cooldown text
    --     if usingOmniCC then
    --         if self.cooldown._occ_display then
    --             local occText = self.cooldown._occ_display.text
    --             C_Timer.After(0, function()
    --                 occText:Show()
    --             end)
    --         end

    --         if self.chargeCooldown then
    --             self.chargeCooldown:SetHideCountdownNumbers(false)
    --             self.chargeCooldown:SetCooldown(start, duration, modRate)
    --             TrackButton(self)
    --             C_Timer.After(0.15, function()
    --                 StopTracking(self)
    --             end)
    --         end
    --     end
    -- end

    -- hooksecurefunc("ActionButton_UpdateCooldown", UpdateCooldown)
end



function BBF.RaiseTargetCastbarStratas()
    if not BetterBlizzFramesDB.raiseTargetCastbarStrata then return end
    TargetFrameSpellBar:SetFrameStrata("HIGH")
    TargetFrameSpellBar:SetFrameLevel(2000)
    FocusFrameSpellBar:SetFrameStrata("HIGH")
    FocusFrameSpellBar:SetFrameLevel(2000)
end


local LSM = LibStub("LibSharedMedia-3.0")
BBF.LSM = LSM
BBF.allLocales = LSM.LOCALE_BIT_western+LSM.LOCALE_BIT_ruRU+LSM.LOCALE_BIT_zhCN+LSM.LOCALE_BIT_zhTW+LSM.LOCALE_BIT_koKR
local texture = "Interface\\Addons\\BetterBlizzPlates\\media\\DragonflightTextureHD"
local manaTexture = "Interface\\Addons\\BetterBlizzPlates\\media\\DragonflightTextureHD"
local raidHpTexture = "Interface\\Addons\\BetterBlizzPlates\\media\\DragonflightTextureHD"
local raidManaTexture = "Interface\\Addons\\BetterBlizzPlates\\media\\DragonflightTextureHD"

local manaTextureUnits = {}

function BBF.UpdateCustomTextures()
    local db = BetterBlizzFramesDB
    texture = LSM:Fetch(LSM.MediaType.STATUSBAR, db.unitFrameHealthbarTexture)
    manaTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, db.unitFrameManabarTexture)
    raidHpTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, db.raidFrameHealthbarTexture)
    raidManaTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, db.raidFrameManabarTexture)

    BBF.HookTextures()
end


-- Helper function to change the texture and retain the original draw layer
local function ApplyTextureChange(type, statusBar, parent)
    if not statusBar.GetStatusBarTexture then
        statusBar:SetTexture(texture)
        return
    end
    -- Get the original texture and draw layer
    local originalTexture = statusBar:GetStatusBarTexture()
    local originalLayer = originalTexture:GetDrawLayer()

    -- Change the texture
    statusBar:SetStatusBarTexture(type == "health" and texture or manaTexture)
    statusBar.bbfChangedTexture = true

    -- Restore the original draw layer
    originalTexture:SetDrawLayer(originalLayer)

    -- Hook SetStatusBarTexture to ensure the texture remains consistent
    if parent and type == "health" then
        if not parent.hookedHealthBarsTexture then
            -- hooksecurefunc(parent, "Update", function()
            --     statusBar:SetStatusBarTexture(texture)
            --     originalTexture:SetDrawLayer(originalLayer)
            -- end)
            parent.hookedHealthBarsTexture = true
        end
    elseif type == "mana" then
        -- Function to get the color of the unit's current power type and apply it
        local function SetUnitPowerColor(manabar, unit)
            -- Retrieve the unit's power type
            local _, powerToken = UnitPowerType(unit)
            -- Use the WoW PowerBarColor table to get the color
            local color = PowerBarColor[powerToken]
            if color then
                manabar:SetStatusBarColor(color.r, color.g, color.b)
            end
        end
        SetUnitPowerColor(statusBar, statusBar.unit)

        if not BBF.hookedManaBarsTexture then
            hooksecurefunc("UnitFrameManaBar_UpdateType", function(manabar)
                if not manaTextureUnits[manabar.unit] then return end
                manabar:SetStatusBarTexture(manaTexture)
                SetUnitPowerColor(manabar, manabar.unit)
            end)
            BBF.hookedManaBarsTexture = true
        end
    end
end

-- Main function to apply texture changes to raid frames and additional frames
function HookUnitFrameTextures()
    local db = BetterBlizzFramesDB
    -- Hook Player, Target & Focus Healthbars
    if db.changeUnitFrameHealthbarTexture then
        if true then
            ApplyTextureChange("health", PlayerFrameHealthBar)
            ApplyTextureChange("health", PetFrame.healthbar, PetFrame)
            ApplyTextureChange("health", TargetFrameHealthBar, TargetFrame)
            ApplyTextureChange("health", FocusFrameHealthBar, FocusFrame)

            if PlayerReputationFrame then
                ApplyTextureChange("health", PlayerReputationFrame.texture, PlayerFrame)
            end
            ApplyTextureChange("health", TargetFrameNameBackground, TargetFrame)
            if FocusFrameNameBackground then
                ApplyTextureChange("health", FocusFrameNameBackground, FocusFrame)
            end
        end

        -- Hook Target of targets Healthbars
        if true then
            ApplyTextureChange("health", TargetFrameToTHealthBar, TargetFrameToT)
            ApplyTextureChange("health", FocusFrameToTHealthBar, FocusFrameToT)
        end

        if not BetterBlizzFramesDB.classColorFrames then
            local healthbars = {
                PlayerFrameHealthBar,
                PetFrame.healthbar,
                TargetFrameHealthBar,
                FocusFrameHealthBar,
                TargetFrameToTHealthBar,
                FocusFrameToTHealthBar
            }

            for _, healthbar in ipairs(healthbars) do
                healthbar:SetStatusBarColor(0,1,0)
            end
        end
    end

    -- Hook Player, Target & Focus Manabars
    -- BetterBlizzFramesDB.textureSwapUnitFramesMana
    if db.changeUnitFrameManabarTexture then
        if true then
            manaTextureUnits["player"] = true
            manaTextureUnits["target"] = true
            manaTextureUnits["focus"] = true
            manaTextureUnits["pet"] = true
            ApplyTextureChange("mana", PlayerFrameManaBar)
            ApplyTextureChange("mana", PetFrame.manabar)
            ApplyTextureChange("mana", TargetFrameManaBar)
            ApplyTextureChange("mana", FocusFrameManaBar)
        end

        -- Hook Target of targets Manabars
        -- BetterBlizzFramesDB.textureSwapUnitFramesMana
        if true then
            manaTextureUnits["targettarget"] = true
            manaTextureUnits["focustarget"] = true
            ApplyTextureChange("mana", TargetFrameToTManaBar)
            ApplyTextureChange("mana", FocusFrameToTManaBar)
        end
    end
end


local function SetRaidFrameTextures(frame)
    --if not frame:IsShown() then return end
    local db = BetterBlizzFramesDB
    -- Retexture healthbars
    if db.changeRaidFrameHealthbarTexture then
        local originalTexture = frame.healthBar:GetStatusBarTexture()
        local originalLayer = originalTexture:GetDrawLayer()
        frame.healthBar:SetStatusBarTexture(raidHpTexture)
        originalTexture:SetDrawLayer(originalLayer)
    end

    -- Retexture manabars
    -- BetterBlizzFramesDB.textureSwapRaidFramesMana
    if db.changeRaidFrameManabarTexture then
        local originalTexture = frame.powerBar:GetStatusBarTexture()
        if not originalTexture then return end
        local originalLayer = originalTexture:GetDrawLayer()
        frame.powerBar:SetStatusBarTexture(raidManaTexture)
        originalTexture:SetDrawLayer(originalLayer)
    end
end

local function SetRaidFramePetTextures(frame)
    local db = BetterBlizzFramesDB
    -- Retexture healthbars
    if db.changeRaidFrameHealthbarTexture then
        local originalTexture = frame.healthBar:GetStatusBarTexture()
        local originalLayer = originalTexture:GetDrawLayer()
        frame.healthBar:SetStatusBarTexture(raidHpTexture)
        originalTexture:SetDrawLayer(originalLayer)
        frame.horizTopBorder:Hide()
        frame.horizBottomBorder:Hide()
        frame.vertLeftBorder:Hide()
        frame.vertRightBorder:Hide()
    end
end

local function HookRaidFrameTextures()
    hooksecurefunc("DefaultCompactUnitFrameSetup", SetRaidFrameTextures)
    if C_CVar.GetCVar("raidOptionDisplayPets") == "1" or C_CVar.GetCVar("raidOptionDisplayMainTankAndAssist") == "1" then
        hooksecurefunc("DefaultCompactMiniFrameSetup", SetRaidFramePetTextures)
        hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
            if frame.unit and (frame.unit:match("raidpet") or frame.unit:match("target")) then
                SetRaidFramePetTextures(frame)
            end
        end)
    end
end

function BBF.HookTextures()
    local db = BetterBlizzFramesDB
    -- Hook UnitFrames
    -- BetterBlizzFramesDB.textureSwapUnitFrames
    if db.changeUnitFrameHealthbarTexture or db.changeUnitFrameManabarTexture then
        HookUnitFrameTextures()
    end
    -- Hook Raidframes
    -- BetterBlizzFramesDB.textureSwapRaidFrames
    if db.changeRaidFrameHealthbarTexture or db.changeRaidFrameManabarTexture then
        if not BBF.HookRaidFrameTextures then
            HookRaidFrameTextures()
            BBF.HookRaidFrameTextures = true
        end

        for i = 1, 40 do
            local frame = _G["CompactPartyFrameMember"..i]
            if frame then
                SetRaidFrameTextures(frame)
            end
        end

        for i = 1, 40 do
            local frame = _G["CompactRaidFrame"..i]
            if frame then
                SetRaidFrameTextures(frame)
            end
        end

        for i = 1, 8 do
            for j = 1, 5 do
                local raidFrame = _G["CompactRaidGroup" .. i .. "Member" .. j]
                if raidFrame then
                    SetRaidFrameTextures(raidFrame)
                end
            end
        end

        C_Timer.After(1, function()
            for i = 1, 5 do
                local frame = _G["CompactPartyFramePet"..i]
                if frame then
                    SetRaidFrameTextures(frame)
                end
            end
        end)
    end

end












-- Local table to store the original settings
local originalSettings = {
    backedUp = false,
    positions = {},
    sizes = {},
    texCoords = {}
}

-- Function to back up current settings
local function backupSettings()
    if not originalSettings.backedUp then
        -- Back up positions
        originalSettings.positions = {
            MainMenuBarTexture3 = {MainMenuBarTexture3:GetPoint()},
            CharacterMicroButton = {CharacterMicroButton:GetPoint()},
            SpellbookMicroButton = {SpellbookMicroButton:GetPoint()},
            TalentMicroButton = {TalentMicroButton:GetPoint()},
            AchievementMicroButton = {AchievementMicroButton:GetPoint()},
            QuestLogMicroButton = {QuestLogMicroButton:GetPoint()},
            GuildMicroButton = {GuildMicroButton:GetPoint()},
            CollectionsMicroButton = {CollectionsMicroButton:GetPoint()},
            PVPMicroButton = {PVPMicroButton:GetPoint()},
            LFGMicroButton = {LFGMicroButton:GetPoint()},
            EJMicroButton = {EJMicroButton:GetPoint()},
            MainMenuMicroButton = {MainMenuMicroButton:GetPoint()},
            HelpMicroButton = {HelpMicroButton:GetPoint()},
            MainMenuBarBackpackButton = {MainMenuBarBackpackButton:GetPoint()},
            CharacterBag1Slot = {CharacterBag1Slot:GetPoint()},
            CharacterBag2Slot = {CharacterBag2Slot:GetPoint()},
            CharacterBag3Slot = {CharacterBag3Slot:GetPoint()},
            MainMenuExpBar = {MainMenuExpBar:GetPoint()},
            MainMenuXPBarTexture0 = {MainMenuXPBarTexture0:GetPoint()},
            MainMenuXPBarTexture1 = {MainMenuXPBarTexture1:GetPoint()},
            MainMenuXPBarTexture2 = {MainMenuXPBarTexture2:GetPoint()},
            MainMenuXPBarTexture3 = {MainMenuXPBarTexture3:GetPoint()},
            MainMenuBarRightEndCap = {MainMenuBarRightEndCap:GetPoint()},
            MainMenuMaxLevelBar0 = {MainMenuMaxLevelBar0:GetPoint()},
            MainMenuMaxLevelBar1 = {MainMenuMaxLevelBar1:GetPoint()},
            MainMenuMaxLevelBar2 = {MainMenuMaxLevelBar2:GetPoint()},
            MainMenuMaxLevelBar3 = {MainMenuMaxLevelBar3:GetPoint()},
            ReputationWatchBar = {ReputationWatchBar:GetPoint()},
            ReputationWatchBar_StatusBar_XPBarTexture0 = {ReputationWatchBar.StatusBar.XPBarTexture0:GetPoint()},
            ReputationWatchBar_StatusBar_XPBarTexture1 = {ReputationWatchBar.StatusBar.XPBarTexture1:GetPoint()},
            ReputationWatchBar_StatusBar_XPBarTexture2 = {ReputationWatchBar.StatusBar.XPBarTexture2:GetPoint()},
            ReputationWatchBar_StatusBar_XPBarTexture3 = {ReputationWatchBar.StatusBar.XPBarTexture3:GetPoint()}
        }

        -- Back up other sizes
        originalSettings.sizes = {
            MainMenuBarTexture3 = {MainMenuBarTexture3:GetSize()},
            MainMenuBarBackpackButton = {MainMenuBarBackpackButton:GetSize()},
            MainMenuBarBackpackButtonNormalTexture = {MainMenuBarBackpackButtonNormalTexture:GetSize()},
            MainMenuExpBar = {MainMenuExpBar:GetSize()},
            MainMenuXPBarTexture0 = {MainMenuXPBarTexture0:GetSize()},
            MainMenuXPBarTexture1 = {MainMenuXPBarTexture1:GetSize()},
            MainMenuXPBarTexture2 = {MainMenuXPBarTexture2:GetSize()},
            MainMenuXPBarTexture3 = {MainMenuXPBarTexture3:GetSize()},
            MainMenuMaxLevelBar0 = {MainMenuMaxLevelBar0:GetSize()},
            MainMenuMaxLevelBar1 = {MainMenuMaxLevelBar1:GetSize()},
            MainMenuMaxLevelBar2 = {MainMenuMaxLevelBar2:GetSize()},
            MainMenuMaxLevelBar3 = {MainMenuMaxLevelBar3:GetSize()},
            ReputationWatchBar = {ReputationWatchBar:GetSize()},
            ReputationWatchBar_StatusBar = {ReputationWatchBar.StatusBar:GetSize()}
        }

        -- Mark as backed up
        originalSettings.backedUp = true
    end
end

-- Function to restore original settings
local function restoreSettings()
    if originalSettings.backedUp then
        -- Restore positions
        MainMenuBarTexture3:SetPoint(unpack(originalSettings.positions.MainMenuBarTexture3))
        CharacterMicroButton:SetPoint(unpack(originalSettings.positions.CharacterMicroButton))
        SpellbookMicroButton:SetPoint(unpack(originalSettings.positions.SpellbookMicroButton))
        TalentMicroButton:SetPoint(unpack(originalSettings.positions.TalentMicroButton))
        AchievementMicroButton:SetPoint(unpack(originalSettings.positions.AchievementMicroButton))
        QuestLogMicroButton:SetPoint(unpack(originalSettings.positions.QuestLogMicroButton))
        GuildMicroButton:SetPoint(unpack(originalSettings.positions.GuildMicroButton))
        CollectionsMicroButton:SetPoint(unpack(originalSettings.positions.CollectionsMicroButton))
        PVPMicroButton:SetPoint(unpack(originalSettings.positions.PVPMicroButton))
        LFGMicroButton:SetPoint(unpack(originalSettings.positions.LFGMicroButton))
        EJMicroButton:SetPoint(unpack(originalSettings.positions.EJMicroButton))
        MainMenuMicroButton:SetPoint(unpack(originalSettings.positions.MainMenuMicroButton))
        HelpMicroButton:SetPoint(unpack(originalSettings.positions.HelpMicroButton))
        MainMenuBarBackpackButton:SetPoint(unpack(originalSettings.positions.MainMenuBarBackpackButton))
        CharacterBag1Slot:SetPoint(unpack(originalSettings.positions.CharacterBag1Slot))
        CharacterBag2Slot:SetPoint(unpack(originalSettings.positions.CharacterBag2Slot))
        CharacterBag3Slot:SetPoint(unpack(originalSettings.positions.CharacterBag3Slot))
        MainMenuExpBar:SetPoint(unpack(originalSettings.positions.MainMenuExpBar))
        MainMenuXPBarTexture0:SetPoint(unpack(originalSettings.positions.MainMenuXPBarTexture0))
        MainMenuXPBarTexture1:SetPoint(unpack(originalSettings.positions.MainMenuXPBarTexture1))
        MainMenuXPBarTexture2:SetPoint(unpack(originalSettings.positions.MainMenuXPBarTexture2))
        MainMenuXPBarTexture3:SetPoint(unpack(originalSettings.positions.MainMenuXPBarTexture3))
        MainMenuBarRightEndCap:SetPoint(unpack(originalSettings.positions.MainMenuBarRightEndCap))
        MainMenuMaxLevelBar0:SetPoint(unpack(originalSettings.positions.MainMenuMaxLevelBar0))
        MainMenuMaxLevelBar1:SetPoint(unpack(originalSettings.positions.MainMenuMaxLevelBar1))
        MainMenuMaxLevelBar2:SetPoint(unpack(originalSettings.positions.MainMenuMaxLevelBar2))
        MainMenuMaxLevelBar3:SetPoint(unpack(originalSettings.positions.MainMenuMaxLevelBar3))
        ReputationWatchBar:SetPoint(unpack(originalSettings.positions.ReputationWatchBar))
        ReputationWatchBar.StatusBar.XPBarTexture0:SetPoint(unpack(originalSettings.positions.ReputationWatchBar_StatusBar_XPBarTexture0))
        ReputationWatchBar.StatusBar.XPBarTexture1:SetPoint(unpack(originalSettings.positions.ReputationWatchBar_StatusBar_XPBarTexture1))
        ReputationWatchBar.StatusBar.XPBarTexture2:SetPoint(unpack(originalSettings.positions.ReputationWatchBar_StatusBar_XPBarTexture2))
        ReputationWatchBar.StatusBar.XPBarTexture3:SetPoint(unpack(originalSettings.positions.ReputationWatchBar_StatusBar_XPBarTexture3))

        -- Restore sizes and texCoords for character bags
        for i = 0, 3 do
            local border = _G["CharacterBag"..i.."SlotNormalTexture"]
            local icon = _G["CharacterBag"..i.."SlotIconTexture"]
            border:SetSize(64,64)
            icon:SetSize(30,30)
            icon:SetTexCoord(0,1,0,1)
        end

        -- Restore other sizes
        MainMenuBarTexture3:SetSize(unpack(originalSettings.sizes.MainMenuBarTexture3))
        MainMenuBarBackpackButton:SetSize(unpack(originalSettings.sizes.MainMenuBarBackpackButton))
        MainMenuBarBackpackButtonNormalTexture:SetSize(unpack(originalSettings.sizes.MainMenuBarBackpackButtonNormalTexture))
        MainMenuExpBar:SetSize(unpack(originalSettings.sizes.MainMenuExpBar))
        MainMenuXPBarTexture0:SetSize(unpack(originalSettings.sizes.MainMenuXPBarTexture0))
        MainMenuXPBarTexture1:SetSize(unpack(originalSettings.sizes.MainMenuXPBarTexture1))
        MainMenuXPBarTexture2:SetSize(unpack(originalSettings.sizes.MainMenuXPBarTexture2))
        MainMenuXPBarTexture3:SetSize(unpack(originalSettings.sizes.MainMenuXPBarTexture3))
        MainMenuMaxLevelBar0:SetSize(unpack(originalSettings.sizes.MainMenuMaxLevelBar0))
        MainMenuMaxLevelBar1:SetSize(unpack(originalSettings.sizes.MainMenuMaxLevelBar1))
        MainMenuMaxLevelBar2:SetSize(unpack(originalSettings.sizes.MainMenuMaxLevelBar2))
        MainMenuMaxLevelBar3:SetSize(unpack(originalSettings.sizes.MainMenuMaxLevelBar3))
        ReputationWatchBar:SetSize(unpack(originalSettings.sizes.ReputationWatchBar))
        ReputationWatchBar.StatusBar:SetSize(unpack(originalSettings.sizes.ReputationWatchBar_StatusBar))
    end
end

local function ChangeHotkeyWidth(width)
    local function changeWidth(frame, width)
        if not frame then return end
        frame:SetWidth(width)
    end
    for i = 1, 12 do
        changeWidth(_G["ActionButton" .. i .. "HotKey"], width)
        changeWidth(_G["MultiBarBottomLeftButton" .. i .. "HotKey"], width)
        changeWidth(_G["MultiBarBottomRightButton" ..i.. "HotKey"], width)
        changeWidth(_G["MultiBarRightButton" ..i.. "HotKey"], width)
        changeWidth(_G["MultiBarLeftButton" ..i.. "HotKey"], width)
        changeWidth(_G["MultiBar5Button" ..i.. "HotKey"], width)
        changeWidth(_G["MultiBar6Button" ..i.. "HotKey"], width)
        changeWidth(_G["MultiBar7Button" ..i.. "HotKey"], width)
        changeWidth(_G["PetActionButton" ..i.. "HotKey"], width)
    end
end

function BBF.FixStupidBlizzPTRShit()
    if BetterBlizzFramesDB.playerFrameOCD then
        if C_AddOns.IsAddOnLoaded("DragonflightUI") then
            if not BBF.dfuiOcdWarning then
                BBF.dfuiOcdWarning = true
                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: DragonflightUI is loaded, skipping \"OCD Tweaks\" to avoid conflict.")
            end
            return
        end
        if not originalSettings.backedUp then
            backupSettings()
        end

        BBF.ActionBarIconZoom()
        ChangeHotkeyWidth(32)

        if not BBF.hookedActionBarTextWidth then
            hooksecurefunc("ActionButton_UpdateHotkeys", function(self)
                if BBF.hotkeyCancel then return end
                self.HotKey:SetWidth(32)
            end)
            BBF.hookedActionBarTextWidth = true
        end
        BBF.hotkeyCancel = nil

        local a,b,c,d,e = TargetFrameToTPortrait:GetPoint()
        TargetFrameToTPortrait:SetPoint(a,b,c,3,-3)
        TargetFrameToTPortrait:SetSize(40,40)

        local a,b,c,d,e = FocusFrameToTPortrait:GetPoint()
        FocusFrameToTPortrait:SetPoint(a,b,c,5,-5)
        FocusFrameToTPortrait:SetSize(36,36)

        local a,b,c,d,e = PetFrameHealthBar:GetPoint()
        PetFrameHealthBar:SetPoint(a,b,c,46,e)
        local a,b,c,d,e = PetFrameManaBar:GetPoint()
        PetFrameManaBar:SetPoint(a,b,c,46,e)

        if not BetterBlizzFramesDB.biggerHealthbars then
            local a,b,c,d,e = TargetFrameNameBackground:GetPoint()
            TargetFrameNameBackground:SetPoint(a,b,c,-107,-23)
            TargetFrameNameBackground:SetHeight(18)
            local a,b,c,d,e = TargetFrameHealthBar:GetPoint()
            TargetFrameHealthBar:SetPoint(a,b,c,-107,e)
            local a,b,c,d,e = TargetFrameManaBar:GetPoint()
            TargetFrameManaBar:SetPoint(a,b,c,-107,e)

            local a,b,c,d,e = FocusFrameNameBackground:GetPoint()
            FocusFrameNameBackground:SetPoint(a,b,c,-107,-23)
            FocusFrameNameBackground:SetHeight(18)
            local a,b,c,d,e = FocusFrameHealthBar:GetPoint()
            FocusFrameHealthBar:SetPoint(a,b,c,-107,e)
            local a,b,c,d,e = FocusFrameManaBar:GetPoint()
            FocusFrameManaBar:SetPoint(a,b,c,-107,e)
        end

        if C_AddOns.IsAddOnLoaded("Bartender4") then return end
        if C_AddOns.IsAddOnLoaded("Dominos") then return end
        if BBF.isMoP then return end

        MainMenuBarTextureExtender:Hide()
        MainMenuBarTexture3:SetPoint("BOTTOM", MainMenuBarArtFrame, "BOTTOM", 371, 0)
        MainMenuBarTexture3:SetWidth(260)
        CharacterMicroButton:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", 550, 2)
        SpellbookMicroButton:SetPoint("BOTTOMLEFT", CharacterMicroButton, "BOTTOMRIGHT", -3.5, 0)
        TalentMicroButton:SetPoint("BOTTOMLEFT", SpellbookMicroButton, "BOTTOMRIGHT", -3.5, 0)
        AchievementMicroButton:SetPoint("BOTTOMLEFT", TalentMicroButton, "BOTTOMRIGHT", -3.5, 0)
        QuestLogMicroButton:SetPoint("BOTTOMLEFT", AchievementMicroButton, "BOTTOMRIGHT", -3.5, 0)
        GuildMicroButton:SetPoint("BOTTOMLEFT", QuestLogMicroButton, "BOTTOMRIGHT", -3.5, 0)
        CollectionsMicroButton:SetPoint("BOTTOMLEFT", GuildMicroButton, "BOTTOMRIGHT", -3.5, 0)
        PVPMicroButton:SetPoint("BOTTOMLEFT", CollectionsMicroButton, "BOTTOMRIGHT", -3.5, 0)
        LFGMicroButton:SetPoint("BOTTOMLEFT", PVPMicroButton, "BOTTOMRIGHT", -3.5, 0)
        EJMicroButton:SetPoint("BOTTOMLEFT", LFGMicroButton, "BOTTOMRIGHT", -3.5, 0)
        MainMenuMicroButton:SetPoint("BOTTOMLEFT", EJMicroButton, "BOTTOMRIGHT", -3.5, 0)
        HelpMicroButton:SetPoint("BOTTOMLEFT", MainMenuMicroButton, "BOTTOMRIGHT", -3.5, 0)

        MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", MainMenuBarArtFrame, "BOTTOMRIGHT", -25, 6)
        CharacterBag1Slot:SetPoint("RIGHT", CharacterBag0Slot, "LEFT", -2, 0)
        CharacterBag2Slot:SetPoint("RIGHT", CharacterBag1Slot, "LEFT", -2, 0)
        CharacterBag3Slot:SetPoint("RIGHT", CharacterBag2Slot, "LEFT", -2, 0)

        MainMenuBarBackpackButton:SetSize(32, 32)
        MainMenuBarBackpackButtonNormalTexture:SetSize(51, 52)
        for i = 0, 3 do
            local border = _G["CharacterBag" .. i .. "SlotNormalTexture"]
            local icon = _G["CharacterBag" .. i .. "SlotIconTexture"]
            icon:SetSize(32, 33)
            icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
            border:SetSize(52, 53)
        end

        MainMenuExpBar:SetWidth(1012)
        MainMenuExpBar:SetPoint("TOP", MainMenuBar, "TOP", -10, 0)
        MainMenuXPBarTexture0:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", -382, 3)
        MainMenuXPBarTexture0:SetWidth(255)
        MainMenuXPBarTexture1:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", -126, 3)
        MainMenuXPBarTexture1:SetWidth(255)
        MainMenuXPBarTexture2:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", 126, 3)
        MainMenuXPBarTexture2:SetWidth(255)
        MainMenuXPBarTexture3:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", 381, 3)
        MainMenuXPBarTexture3:SetWidth(255)
        MainMenuBarRightEndCap:SetPoint("BOTTOM", MainMenuBarArtFrame, "BOTTOM", 533, 0)

        MainMenuMaxLevelBar0:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", -382, 2)
        MainMenuMaxLevelBar0:SetWidth(255)
        MainMenuMaxLevelBar1:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", -126, 2)
        MainMenuMaxLevelBar1:SetWidth(255)
        MainMenuMaxLevelBar2:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", 126, 2)
        MainMenuMaxLevelBar2:SetWidth(255)
        MainMenuMaxLevelBar3:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", 381, 2)
        MainMenuMaxLevelBar3:SetWidth(254)

        ReputationWatchBar:SetWidth(1012)
        ReputationWatchBar.StatusBar:SetWidth(1015)
        ReputationWatchBar:SetPoint("TOP", MainMenuBar, "TOP", -13, 0)
        ReputationWatchBar.StatusBar.XPBarTexture0:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", -382, 3)
        ReputationWatchBar.StatusBar.XPBarTexture0:SetWidth(255)
        ReputationWatchBar.StatusBar.XPBarTexture1:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", -126, 3)
        ReputationWatchBar.StatusBar.XPBarTexture1:SetWidth(255)
        ReputationWatchBar.StatusBar.XPBarTexture2:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", 126, 3)
        ReputationWatchBar.StatusBar.XPBarTexture2:SetWidth(255)
        ReputationWatchBar.StatusBar.XPBarTexture3:SetPoint("BOTTOM", MainMenuExpBar, "BOTTOM", 381, 3)
        ReputationWatchBar.StatusBar.XPBarTexture3:SetWidth(255)
    else
        BBF.hotkeyCancel = true
        MainMenuBarTextureExtender:Show()
        ChangeHotkeyWidth(28)
        restoreSettings()
        BBF.ActionBarIconZoom()
    end
end

function BBF.ClassPortraits()
    hooksecurefunc("SetPortraitTexture", function(portrait, unit)
        if UnitIsPlayer(unit) then
            if BetterBlizzFramesDB.classPortraitsIgnoreSelf and portrait:GetParent():GetName() == "PlayerFrame" then return end
            local _, class = UnitClass(unit)

            local texture = "Interface\\TargetingFrame\\UI-Classes-Circles"
            local coords = CLASS_ICON_TCOORDS[class]

            if coords then
                portrait:SetTexture(texture)
                portrait:SetTexCoord(unpack(coords))
            end
        else
            portrait:SetTexCoord(0, 1, 0, 1)
        end
    end)
end

local function TurnTestModesOff()
    BetterBlizzFramesDB.absorbIndicatorTestMode = false
    BetterBlizzFramesDB.partyCastBarTestMode = false
    BetterBlizzFramesDB.petCastBarTestMode = false
end

local function executeCustomCode()
    if BetterBlizzFramesDB and BetterBlizzFramesDB.customCode then
        local func, errorMsg = loadstring(BetterBlizzFramesDB.customCode)
        if func then
            func() -- Execute the custom code
        else
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Error in custom code:", errorMsg)
        end
    end
end

function BBF.AddBackgroundTextureToUnitFrames(frame, tot)
    if not BetterBlizzFramesDB.addUnitFrameBgTexture then
        if frame.bbfBgTexture then
            frame.bbfBgTexture:Hide()
        end
        return
    end

    local color = BetterBlizzFramesDB.unitFrameBgTextureColor
    if frame.bbfBgTexture then
        frame.bbfBgTexture:Show()
        frame.bbfBgTexture:SetColorTexture(unpack(color))
        return
    end
    local bgTex = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    bgTex:SetColorTexture(unpack(color))

    local topAnchor = frame.healthbar or frame.HealthBar or frame
    local bottomAnchor = frame.manabar or frame

    if tot then
        bgTex:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", -3, 0)
        bgTex:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", 0, 0)
    else
        bgTex:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", 0, 0)
        bgTex:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", 0, 0)
    end
    if frame.Background then
        frame.Background:Hide()
    end

    frame.bbfBgTexture = bgTex
end

function BBF.UnitFrameBackgroundTexture()
    BBF.AddBackgroundTextureToUnitFrames(PlayerFrame)
    BBF.AddBackgroundTextureToUnitFrames(TargetFrame)
    BBF.AddBackgroundTextureToUnitFrames(FocusFrame)

    BBF.AddBackgroundTextureToUnitFrames(TargetFrameToT, true)
    BBF.AddBackgroundTextureToUnitFrames(FocusFrameToT, true)
    BBF.AddBackgroundTextureToUnitFrames(PetFrame, true)
end

-- Event registration for PLAYER_LOGIN
local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_LOGIN")
--Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:SetScript("OnEvent", function(...)
    CheckForUpdate()
    --BBF.HideFrames()
    DisableClickForClassSpecificFrame()
    BBF.MoveToTFrames()
    BBF.HookHealthbarColors()
    BBF.UnitFrameBackgroundTexture()
    if BetterBlizzFramesDB.classPortraits then
        BBF.ClassPortraits()
    end
    BBF.ClassColorReputationCaller()
    BBF.SetupLoCFrame()
    BBF.EnableQueueTimer()
    BBF.LegacyBlueCombos()

    C_Timer.After(0, function()
        BBF.PlayerReputationColor()
        BBF.SetCustomFonts()
        BBF.UpdateCustomTextures()
    end)

    C_Timer.After(0.5, function()
        BBF.SetResourcePosition()
        ScaleClassResource()
    end)

    local function LoginVariablesLoaded()
        if BBF.variablesLoaded then
            -- add setings updates
            BBF.UpdateUserDarkModeSettings()
            BBF.ChatFilterCaller()

            BBF.HookOverShields()
            if BetterBlizzFramesDB.absorbIndicator then
                BBF.AbsorbCaller()
            end
            BBF.HookCastbarsForEvoker()
            BBF.StealthIndicator()
            BBF.CastbarRecolorWidgets()
            BBF.CastBarTimerCaller()
            BBF.ShowPlayerCastBarIcon()
            BBF.CombatIndicator(PlayerFrame, "player")
            if BetterBlizzFramesDB.hideArenaFrames then
                BBF.HideArenaFrames()
            end

            BBF.ScaleUnitFrames()
            BBF.MoveToTFrames()
            BBF.UpdateUserAuraSettings()
            --BBF.HookPlayerAndTargetAuras()a
            if BetterBlizzFramesDB.enableMasque then
                BBF.SetupMasqueSupport()
            end


            -- local hidePartyName = BetterBlizzFramesDB.hidePartyNames
            -- local hidePartyRole = BetterBlizzFramesDB.hidePartyRoles
            -- if hidePartyName or hidePartyRole then
            --     BBF.OnUpdateName()
            -- end

            if BetterBlizzFramesDB.playerFrameOCD then
                BBF.FixStupidBlizzPTRShit()
            end
            BBF.AllNameChanges()
            C_Timer.After(0.2, function()
                BBF.HideFrames()
            end)
            C_Timer.After(1, function()
                -- if BetterBlizzFramesDB.classColorTargetNames and BetterBlizzFramesDB.classColorLevelText then
                --     BBF.HookLevelText()
                -- end
                BBF.HookPlayerAndTargetAuras()
                if BetterBlizzFramesDB.playerFrameOCD then
                    BBF.FixStupidBlizzPTRShit()
                end
                if BetterBlizzFramesDB.classColorFrames then
                    BBF.UpdateFrames()
                end
                BBF.DarkmodeFrames()
                --BBF.ClassColorPlayerName()
                --BBF.CheckForAuraBorders() bodify cata
                -- if BetterBlizzFramesDB.useMiniFocusFrame then
                --     BBF.MiniFocusFrame()
                -- end
                if BetterBlizzFramesDB.biggerHealthbars then
                    BBF.HookBiggerHealthbars()
                end
                BBF.ToggleCastbarInterruptIcon()
                BBF.UpdateCastbars()
                BBF.ChangeCastbarSizes()
                BBF.HideFrames()
                BBF.ShowCooldownDuringCC()
                --BBF.HookUnitFrameName()
            end)
            if BetterBlizzFramesDB.partyCastbars or BetterBlizzFramesDB.petCastbar then
                BBF.CreateCastbars()
            end

        else
            C_Timer.After(1, function()
                LoginVariablesLoaded()
            end)
        end
    end
    LoginVariablesLoaded()

    if BetterBlizzFramesDB.reopenOptions then
        --InterfaceOptionsFrame_OpenToCategory(BetterBlizzFrames)
        Settings.OpenToCategory(BBF.category.ID)
        BetterBlizzFramesDB.reopenOptions = false
    end

    executeCustomCode()
end)

-- Slash command
SLASH_BBF1 = "/BBF"
SlashCmdList["BBF"] = function(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$") -- Capture the command and argument
    command = string.lower(command or "")

    if command == "news" then
        NewsUpdateMessage()
    elseif command == "whitelist" or command == "wl" then
        if arg and arg ~= "" then
            if tonumber(arg) then
                -- The argument is a number, treat it as a spell ID
                local spellId = tonumber(arg)
                local spellName, _, icon = BBF.TWWGetSpellInfo(spellId)
                if spellName then
                    local iconString = "|T" .. icon .. ":16:16:0:0|t" -- Format the icon for display
                    BBF.auraWhitelist(spellId)
                    print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconString .. " " .. spellName .. " (" .. spellId .. ") added to |cff00ff00whitelist|r.")
                else
                    print("Error: Invalid spell ID.")
                end
            else
                -- The argument is not a number, treat it as a spell name
                local spellName = arg
                BBF.auraWhitelist(spellName)
                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. spellName .. " was added to |cff00ff00whitelist|r.")
            end
        else
            print("Usage: /bbf whitelist <spellID or auraName>")
        end
    elseif command == "blacklist" or command == "bl" then
        if arg and arg ~= "" then
            if tonumber(arg) then
                -- The argument is a number, treat it as a spell ID
                local spellId = tonumber(arg)
                local spellName, _, icon = BBF.TWWGetSpellInfo(spellId)
                if spellName then
                    local iconString = "|T" .. icon .. ":16:16:0:0|t" -- Format the icon for display
                    BBF.auraBlacklist(spellId)
                    print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconString .. " " .. spellName .. " (" .. spellId .. ") added to |cffff0000blacklist|r.")
                else
                    print("Error: Invalid spell ID.")
                end
            else
                -- The argument is not a number, treat it as a spell name
                local spellName = arg
                BBF.auraBlacklist(spellName)
                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. spellName .. " was added to |cffff0000blacklist|r.")
            end
        else
            print("Usage: /bbf blacklist <spellID or auraName>")
        end
    elseif command == "ver" or command == "version" then
        DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames Version "..addonUpdates)
    elseif command == "dump" then
        local exportVersion = BetterBlizzFramesDB.exportVersion or "No export version registered"
        DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: "..exportVersion)
    elseif command == "profiles" then
        BBF.CreateIntroMessageWindow()
    else
        -- InterfaceOptionsFrame_OpenToCategory(BetterBlizzFrames)
        if not BBF.category then
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Settings disabled. Likely due to error. Please update your addon.")
            --BBF.InitializeOptions()
            --Settings.OpenToCategory(BBF.category.ID)
        else
            if not BetterBlizzFrames.guiLoaded then
                BBF.LoadGUI()
            else
                Settings.OpenToCategory(BBF.category.ID)
            end
        end
    end
end

local function MoveableSettingsPanel(talents)
    if C_AddOns.IsAddOnLoaded("BlizzMove") then return end
    if BetterBlizzFramesDB.dontMoveSettingsPanel then return end
    if not talents then
        local frame = SettingsPanel
        if frame and not frame:GetScript("OnDragStart") then
            frame:RegisterForDrag("LeftButton")
            frame:SetScript("OnDragStart", frame.StartMoving)
            frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
            frame:SetUserPlaced(false)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    else
        local talentFrame = PlayerTalentFrame
        if talentFrame and not talentFrame:GetScript("OnDragStart") then
            talentFrame:SetMovable(true)
            talentFrame:RegisterForDrag("LeftButton")
            talentFrame:SetScript("OnDragStart", talentFrame.StartMoving)
            talentFrame:SetScript("OnDragStop", talentFrame.StopMovingOrSizing)
        end
    end
end

-- Event registration for PLAYER_LOGIN
local First = CreateFrame("Frame")
First:RegisterEvent("ADDON_LOADED")
First:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName then
        if addonName == "BetterBlizzFrames" then
            BetterBlizzFramesDB.wasOnLoadingScreen = true

            if BetterBlizzFramesDB.hasSaved and not BetterBlizzFramesDB.mopUpdates then
                BetterBlizzFramesDB.legacyComboXPos = -44
                BetterBlizzFramesDB.legacyComboYPos = -9
                BetterBlizzFramesDB.legacyComboScale = 1
                BetterBlizzFramesDB.mopUpdates = true
                StaticPopupDialogs["BBF_MOP_UPDATE"] = {
                    text = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: \n\n|A:services-icon-warning:16:16|a CHANGES |A:services-icon-warning:16:16|a\n\nLots of Retail features from BBF have been brought over to MoP and Cata.\n\nDue to the large amount of changes things might have changed slightly.\nThere might also be some missed bugs.\n\nRead changelog for more info.",
                    button1 = "OK",
                    timeout = 0,
                    whileDead = true,
                }
                StaticPopup_Show("BBF_MOP_UPDATE")
            elseif not BetterBlizzFramesDB.hasSaved then
                BetterBlizzFramesDB.mopUpdates = true
            end

            InitializeSavedVariables()
            FetchAndSaveValuesOnFirstLogin()
            TurnTestModesOff()
            BBF.FixLegacyComboPointsLocation()
            BBF.AlwaysShowLegacyComboPoints()
            BBF.GenericLegacyComboSupport()
            BBF.ChangeTotemFrameScale()
            --TurnOnEnabledFeaturesOnLogin()
            BBF.RaiseTargetCastbarStratas()
            BBF.HookStatusBarText()

            C_Timer.After(1, function()
                MoveableSettingsPanel()
            end)

            if BetterBlizzFramesDB.partyCastbarHideBorder then
                BetterBlizzFramesDB.partyCastbarShowBorder = false
                BetterBlizzFramesDB.partyCastbarHideBorder = nil
            end

            if BetterBlizzFramesDB.hideLossOfControlFrameLines == nil then
                if BetterBlizzFramesDB.hideLossOfControlFrameBg then
                    BetterBlizzFramesDB.hideLossOfControlFrameLines = true
                end
            end

            if not BetterBlizzFramesDB.optimizedAuraLists then
                if BetterBlizzFramesDB.hasSaved then
                    BetterBlizzFramesDB.auraBackups = {}
                    BetterBlizzFramesDB.auraBackups.whitelist = BetterBlizzFramesDB.auraWhitelist
                    BetterBlizzFramesDB.auraBackups.blacklist = BetterBlizzFramesDB.auraBlacklist

                    local optimizedWhitelist = {}
                    for _, aura in ipairs(BetterBlizzFramesDB["auraWhitelist"]) do
                        local key = aura["id"] or string.lower(aura["name"])
                        local flags = aura["flags"] or {}
                        local entryColors = aura["entryColors"] or {}
                        local textColors = entryColors["text"] or {}

                        optimizedWhitelist[key] = {
                            name = aura["name"] or nil,
                            id = aura["id"] or nil,
                            important = flags["important"] or nil,
                            pandemic = flags["pandemic"] or nil,
                            enlarged = flags["enlarged"] or nil,
                            compacted = flags["compacted"] or nil,
                            color = {textColors["r"] or 0, textColors["g"] or 1, textColors["b"] or 0, textColors["a"] or 1}
                        }
                    end
                    BetterBlizzFramesDB.auraWhitelist = optimizedWhitelist

                    local optimizedBlacklist = {}
                    for _, aura in ipairs(BetterBlizzFramesDB["auraBlacklist"]) do
                        local key = aura["id"] or string.lower(aura["name"])

                        optimizedBlacklist[key] = {
                            name = aura["name"] or nil,
                            id = aura["id"] or nil,
                            showMine = aura["showMine"] or nil,
                        }
                    end
                    BetterBlizzFramesDB.auraBlacklist = optimizedBlacklist


                    BetterBlizzFramesDB.optimizedAuraLists = true
                else
                    BetterBlizzFramesDB.optimizedAuraLists = true
                end
            end

            BBF.InitializeOptions()
        elseif addonName == "Blizzard_TalentUI" and _G.PlayerTalentFrame then
            MoveableSettingsPanel(true)
        end
    end
end)

local function OnVariablesLoaded(self, event)
    if event == "VARIABLES_LOADED" then
        BBF.variablesLoaded = true
    end
end

-- Register the frame to listen for the "VARIABLES_LOADED" event
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:SetScript("OnEvent", OnVariablesLoaded)

local PlayerEnteringWorld = CreateFrame("frame")
PlayerEnteringWorld:SetScript("OnEvent", function()
    BBF.DarkmodeFrames()
    BBF.ClickthroughFrames()
    BBF.CheckForAuraBorders()
    BBF.RepositionBuffFrame()
    if BetterBlizzFramesDB.playerFrameOCD then
        ChangeHotkeyWidth(32)
    end
end)
PlayerEnteringWorld:RegisterEvent("PLAYER_ENTERING_WORLD")


if EclipseBarFramePowertext then
    hooksecurefunc(EclipseBarFramePowertext, "Hide", function(self)
        self:Show()
    end)
end