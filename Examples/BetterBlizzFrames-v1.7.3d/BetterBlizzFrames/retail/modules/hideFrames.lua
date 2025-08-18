local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()
BBF.hiddenFrame = hiddenFrame

--------------------------------------
-- Hide UI Frame Elements
--------------------------------------
local hookedRaidFrameManager = false
local hookedChatButtons = false
local originalResourceParent
local originalBossFrameParent
local bossFrameHooked
local originalStanceParent
local iconMouseOver = false -- flag to indicate if any LibDBIcon is currently moused over
local minimapButtonsHooked = false
local bagButtonsHooked = false
local keybindAlphaChanged = false
local hiddenBar1 = true

local changes = {}

local function applyAlpha(frame, alpha)
    if frame then
        frame:SetAlpha(alpha)
    end
end

local function HideQualityIconFromBars(alpha)
    for i = 1, 12 do
        local buttons = {
            _G["ActionButton" .. i],
            _G["MultiBarBottomLeftButton" .. i],
            _G["MultiBarBottomRightButton" .. i],
            _G["MultiBarRightButton" .. i],
            _G["MultiBarLeftButton" .. i],
            _G["MultiBar5Button" .. i],
            _G["MultiBar6Button" .. i],
            _G["MultiBar7Button" .. i]
        }

        for _, button in ipairs(buttons) do
            if button and button.ProfessionQualityOverlayFrame then
                button.ProfessionQualityOverlayFrame:SetAlpha(alpha)
            end
        end
    end
end

function BBF.HideFrames()
    local db = BetterBlizzFramesDB
    if db.hasCheckedUi then
        if InCombatLockdown() then
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Combat detected while adjusting Hide settings. Reload might be required to see updates. Please leave combat.")
            return
        end
        local playerClass, englishClass = UnitClass("player")
        local classicFrames = C_AddOns.IsAddOnLoaded("ClassicFrames")
        --Hide group indicator on player unitframe
        local groupIndicatorAlpha = BetterBlizzFramesDB.hideGroupIndicator and 0 or 1
        PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.GroupIndicator:SetAlpha(groupIndicatorAlpha)
        -- PlayerFrameGroupIndicatorMiddle:SetAlpha(groupIndicatorAlpha)
        -- PlayerFrameGroupIndicatorText:SetAlpha(groupIndicatorAlpha)
        -- PlayerFrameGroupIndicatorLeft:SetAlpha(groupIndicatorAlpha)
        -- PlayerFrameGroupIndicatorRight:SetAlpha(groupIndicatorAlpha)

        if db.hideActionBarQualityIcon then
            HideQualityIconFromBars(0)
            changes.hideActionBarQualityIcon = true
        elseif changes.hideActionBarQualityIcon then
            HideQualityIconFromBars(1)
        end

        -- Hide target leader icon
        local targetLeaderIconAlpha = BetterBlizzFramesDB.hideTargetLeaderIcon and 0 or 1
        TargetFrame.TargetFrameContent.TargetFrameContentContextual.LeaderIcon:SetAlpha(targetLeaderIconAlpha)

        -- Hide focus leader icon
        local focusLeaderIconAlpha = BetterBlizzFramesDB.hideFocusLeaderIcon and 0 or 1
        FocusFrame.TargetFrameContent.TargetFrameContentContextual.LeaderIcon:SetAlpha(focusLeaderIconAlpha)

        -- Hide Player Leader Icon
        local playerLeaderIconAlpha = BetterBlizzFramesDB.hidePlayerLeaderIcon and 0 or 1
        PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.LeaderIcon:SetAlpha(playerLeaderIconAlpha)

        -- PvP Timer Text
        if BetterBlizzFramesDB.hidePvpTimerText then
            changes.hidePvpTimerText = true
            PlayerPVPTimerText:SetParent(hiddenFrame)
        elseif changes.hidePvpTimerText then
            changes.hidePvpTimerText = nil
            PlayerPVPTimerText:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
        end

        if db.hidePetHitIndicator then
            PetHitIndicator:SetParent(hiddenFrame)
        end

        if BetterBlizzFramesDB.hideBossFrames then
            if not originalBossFrameParent then
                originalBossFrameParent = BossTargetFrameContainer:GetParent()
            end
            BossTargetFrameContainer:SetParent(hiddenFrame)
            if not bossFrameHooked then
                hiddenFrame:RegisterEvent("ENCOUNTER_START")
                hiddenFrame:RegisterEvent("ENCOUNTER_END")
                hiddenFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
                hiddenFrame:SetScript("OnEvent", function()
                    if InCombatLockdown then return end
                    local inInstance, instanceType = IsInInstance()

                    if BetterBlizzFramesDB.hideBossFramesParty and inInstance and instanceType == "party" then
                        BossTargetFrameContainer:SetParent(hiddenFrame)
                    elseif BetterBlizzFramesDB.hideBossFramesRaid and inInstance and instanceType == "raid" then
                        BossTargetFrameContainer:SetParent(hiddenFrame)
                    else
                        BossTargetFrameContainer:SetParent(originalBossFrameParent)
                    end
                end)

                bossFrameHooked = true
            end
        elseif bossFrameHooked then
            BossTargetFrameContainer:SetParent(originalBossFrameParent)
        end

        -- Player Combat Icon
        local playerCombatIconAlpha = BetterBlizzFramesDB.hideCombatIcon and 0 or 1
        PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.AttackIcon:SetAlpha(playerCombatIconAlpha)

        -- Hide prestige (honor) icon on player unitframe
        --local prestigeBadgeAlpha = (BetterBlizzFramesDB.hidePrestigeBadge or BetterBlizzFramesDB.classicFrames) and 0 or 1
        local prestigeBadgeAlpha = BetterBlizzFramesDB.hidePrestigeBadge and 0 or 1
        PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PrestigeBadge:SetAlpha(prestigeBadgeAlpha)
        PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PrestigePortrait:SetAlpha(prestigeBadgeAlpha)
        TargetFrame.TargetFrameContent.TargetFrameContentContextual.PrestigeBadge:SetAlpha(prestigeBadgeAlpha)
        TargetFrame.TargetFrameContent.TargetFrameContentContextual.PrestigePortrait:SetAlpha(prestigeBadgeAlpha)
        FocusFrame.TargetFrameContent.TargetFrameContentContextual.PrestigeBadge:SetAlpha(prestigeBadgeAlpha)
        FocusFrame.TargetFrameContent.TargetFrameContentContextual.PrestigePortrait:SetAlpha(prestigeBadgeAlpha)

        -- Hide reputation color on target frame (color tint behind name)
        if BetterBlizzFramesDB.hideTargetReputationColor then
            changes.hideTargetReputationColor = true
            TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:Hide()
            if classicFrames and not TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor.bbfHooked then
                hooksecurefunc(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "SetVertexColor", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:SetVertexColor(0,0,0,0.45)
                    self.changing = false
                end)
                TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor.bbfHooked = true
            end
        elseif changes.hideTargetReputationColor then
            changes.hideTargetReputationColor = nil
            TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:Show()
        end

        if BetterBlizzFramesDB.hideFocusReputationColor then
            changes.hideFocusReputationColor = true
            FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:Hide()
            if classicFrames and not FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor.bbfCF then
                hooksecurefunc(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "SetVertexColor", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:SetVertexColor(0,0,0,0.45)
                    self.changing = false
                end)
                FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor.bbfCF = true
            end
        elseif changes.hideFocusReputationColor then
            changes.hideFocusReputationColor = nil
            FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:Show()
        end

        if BetterBlizzFramesDB.hideThreatOnFrame then
            TargetFrame.TargetFrameContent.TargetFrameContentContextual.NumericalThreat:SetAlpha(0)
            FocusFrame.TargetFrameContent.TargetFrameContentContextual.NumericalThreat:SetAlpha(0)
        end

        if BetterBlizzFramesDB.hideActionBar1 then
            if not MainMenuBar.bbfHidden then
                hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
                    if InCombatLockdown() then
                        if hiddenBar1 then
                            print("Could not show ActionBar1 due to combat. Please leave combat and re-open Edit Mode to show it.")
                        end
                        return
                    end
                    MainMenuBar:SetParent(UIParent)
                    hiddenBar1 = false
                end)
                hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
                    if InCombatLockdown() then
                        if not hiddenBar1 then
                            print("Could not hide ActionBar1 due to combat. Please leave combat and re-open Edit Mode to hide it.")
                        end
                        return
                    end
                    MainMenuBar:SetParent(BBF.hiddenFrame)
                    hiddenBar1 = true
                end)
                MainMenuBar:SetParent(BBF.hiddenFrame)
                MainMenuBar.bbfHidden = true
                hiddenBar1 = true
            end
        end

        -- Hide rest loop animation
        if BetterBlizzFramesDB.hidePlayerRestAnimation then
            changes.hidePlayerRestAnimation = true
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:SetParent(hiddenFrame)
            if classicFrames and not PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestIcon.bbfCF then
                hooksecurefunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestIcon, "Show", function(self)
                    self:Hide()
                end)
                hooksecurefunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestGlow, "Show", function(self)
                    self:Hide()
                end)
                PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestIcon.bbfCF = true
            end
        elseif changes.hidePlayerRestAnimation then
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
            changes.hidePlayerRestAnimation = nil
        end

        -- Hide rested glow on unit frame
        if BetterBlizzFramesDB.hidePlayerRestGlow then
            changes.hidePlayerRestGlow = true
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture:SetParent(hiddenFrame)
            if classicFrames and not PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.bbfCF then
                C_Timer.After(1, function()
                    for i = 1, PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual:GetNumRegions() do
                        local region = select(i, PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual:GetRegions())
                        if region:IsObjectType("Texture") and region:GetTexture() == 130935 then
                            region:SetParent(hiddenFrame)
                        end
                    end
                end)
                for i = 1, PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual:GetNumRegions() do
                    local region = select(i, PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual:GetRegions())
                    if region:IsObjectType("Texture") and region:GetTexture() == 130935 then
                        region:SetParent(hiddenFrame)
                    end
                end
                PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.bbfCF = true
            end
        elseif changes.hidePlayerRestGlow then
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.StatusTexture:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain)
            changes.hidePlayerRestGlow = nil
        end

        -- Hide corner icon
        if BetterBlizzFramesDB.hidePlayerCornerIcon then
            changes.hidePlayerCornerIcon = true
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon:SetParent(hiddenFrame)
        elseif changes.hidePlayerCornerIcon then
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
            changes.hidePlayerCornerIcon = nil
        end

        if BetterBlizzFramesDB.hideManaFeedback and not changes.hideManaFeedback then
            changes.hideManaFeedback = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.FeedbackFrame:GetParent()
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.FeedbackFrame:SetParent(hiddenFrame)
            if ClassNameplateManaBarFrame and ClassNameplateManaBarFrame.FeedbackFrame then
                ClassNameplateManaBarFrame.FeedbackFrame:Hide()
            end
        elseif changes.hideManaFeedback then
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.FeedbackFrame:SetParent(changes.hideManaFeedback)
            changes.hideManaFeedback = nil
        end

        if BetterBlizzFramesDB.hideFullPower and not changes.hideFullPower then
            changes.hideFullPower = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.FullPowerFrame:GetParent()
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.FullPowerFrame:SetParent(hiddenFrame)
            if ClassNameplateManaBarFrame and ClassNameplateManaBarFrame.FullPowerFrame then
                ClassNameplateManaBarFrame.FullPowerFrame:Hide()
            end
        elseif changes.hideFullPower then
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar.FullPowerFrame:SetParent(changes.hideFullPower)
            changes.hideFullPower = nil
        end

        -- Hide totem frame
        if BetterBlizzFramesDB.hideTotemFrame then
            local totemFrame = TotemFrame
            if totemFrame and not totemFrame.bbfHook then
                totemFrame:HookScript("OnShow", function()
                    totemFrame:Hide()
                end)
                totemFrame.bbfHook = true
                totemFrame:Hide()
            end
        end

        -- Hide combat glow on player frame
        if BetterBlizzFramesDB.hideCombatGlow then
            PlayerFrame.PlayerFrameContainer.FrameFlash:SetParent(hiddenFrame)
            TargetFrame.TargetFrameContainer.Flash:SetParent(hiddenFrame)
            FocusFrame.TargetFrameContainer.Flash:SetParent(hiddenFrame)
            PetFrameFlash:SetParent(hiddenFrame)
            PetAttackModeTexture:SetParent(hiddenFrame)
            changes.hideCombatGlow = true
        elseif changes.hideCombatGlow then
            PlayerFrame.PlayerFrameContainer.FrameFlash:SetParent(PlayerFrame.PlayerFrameContainer)
            TargetFrame.TargetFrameContainer.Flash:SetParent(TargetFrame.TargetFrameContainer)
            FocusFrame.TargetFrameContainer.Flash:SetParent(FocusFrame.TargetFrameContainer)
            PetFrameFlash:SetParent(PetFrame)
            PetAttackModeTexture:SetParent(PetFrame)
            changes.hideCombatGlow = nil
        end

        -- Hide Player level text
        if BetterBlizzFramesDB.hideLevelText then
            changes.hideLevelText = true
            if classicFrames and not BBF.classicFramesLevelHide then

                hooksecurefunc(PlayerFrame.PlayerFrameContainer.FrameTexture, "SetTexture", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-NoLevel")
                    self.changing = false
                end)
                hooksecurefunc(PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture, "SetTexture", function(self)
                    if self.changing then return end
                    self.changing = true
                    self:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-NoLevel")
                    self.changing = false
                end)
                hooksecurefunc(TargetFrame.TargetFrameContainer.FrameTexture, "SetTexture", function(self, texture)
                    if self.changing then return end
                    if texture == "Interface\\TargetingFrame\\UI-TargetingFrame" then
                        self.changing = true
                        self:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-NoLevel")
                        self.changing = false
                    end
                end)
                hooksecurefunc(FocusFrame.TargetFrameContainer.FrameTexture, "SetTexture", function(self, texture)
                    if self.changing then return end
                    if texture == "Interface\\TargetingFrame\\UI-TargetingFrame" then
                        self.changing = true
                        self:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-NoLevel")
                        self.changing = false
                    end
                end)

                BBF.classicFramesLevelHide = true
            end
            if BetterBlizzFramesDB.hideLevelTextAlways then
                PlayerLevelText:SetParent(hiddenFrame)
                TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetAlpha(0)
                FocusFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetAlpha(0)
                TargetFrame.TargetFrameContent.TargetFrameContentContextual.HighLevelTexture:SetAlpha(0)
                FocusFrame.TargetFrameContent.TargetFrameContentContextual.HighLevelTexture:SetAlpha(0)
            else
                if UnitLevel("player") == 80 then
                    PlayerLevelText:SetParent(hiddenFrame)
                    if classicFrames then
                        C_Timer.After(1, function()
                            PlayerLevelText:SetParent(hiddenFrame)
                        end)
                    end
                end
                if UnitLevel("target") == 80 then
                    --TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetParent(hiddenFrame)
                    TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetAlpha(0)
                end
                if UnitLevel("focus") == 80 then
                    --FocusFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetParent(hiddenFrame)
                    FocusFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetAlpha(0)
                end
            end
        elseif changes.hideLevelText then
            changes.hideLevelText = nil
            PlayerLevelText:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain)
            --TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetParent(TargetFrame.TargetFrameContent.TargetFrameContentMain)
            --FocusFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetParent(FocusFrame.TargetFrameContent.TargetFrameContentMain)
            TargetFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetAlpha(1)
            FocusFrame.TargetFrameContent.TargetFrameContentMain.LevelText:SetAlpha(1)
        end

        -- Hide "Party" text above party raid frames
        if BetterBlizzFramesDB.hidePartyFrameTitle then
            changes.hidePartyFrameTitle = true
            CompactPartyFrameTitle:Hide()
        elseif changes.hidePartyFrameTitle then
            changes.hidePartyFrameTitle = nil
            CompactPartyFrameTitle:Show()
        end

        -- Hide PvP Icon BetterBlizzFramesDB.hidePvpIcon
        if BetterBlizzFramesDB.hidePrestigeBadge then
            changes.hidePvpIcon = true
            TargetFrame.TargetFrameContent.TargetFrameContentContextual.PvpIcon:SetParent(hiddenFrame)
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PVPIcon:SetParent(hiddenFrame)
            FocusFrame.TargetFrameContent.TargetFrameContentContextual.PvpIcon:SetParent(hiddenFrame)
        elseif changes.hidePvpIcon then
            changes.hidePvpIcon = nil
            TargetFrame.TargetFrameContent.TargetFrameContentContextual.PvpIcon:SetParent(TargetFrame.TargetFrameContent.TargetFrameContentContextual)
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PVPIcon:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
            FocusFrame.TargetFrameContent.TargetFrameContentContextual.PvpIcon:SetParent(FocusFrame.TargetFrameContent.TargetFrameContentContextual)
        end

        -- Hide role icons
        if BetterBlizzFramesDB.hidePlayerRoleIcon then
            changes.hidePlayerRoleIcon = true
            --PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon:SetParent(hiddenFrame)
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon:SetAlpha(0)
        elseif changes.hidePlayerRoleIcon then
            changes.hidePlayerRoleIcon = nil
            --PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon:SetAlpha(1)
        end

        if BetterBlizzFramesDB.hidePlayerGuideIcon then
            changes.hidePlayerGuideIcon = true
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.GuideIcon:SetAlpha(0)
        elseif changes.hidePlayerGuideIcon then
            changes.hidePlayerGuideIcon = nil
            PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.GuideIcon:SetAlpha(1)
        end

        -- if BetterBlizzFramesDB.hidePartyMaxHpReduction then
        --     for i = 1, 5 do
        --         local frame = _G["CompactPartyFrameMember"..i.."TempMaxHealthLoss"]
        --         if frame then
        --             frame:SetAlpha(0)
        --         end
        --     end
        -- end

        -- if BetterBlizzFramesDB.hideTargetMaxHpReduction then
        --     TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.TempMaxHealthLoss:SetAlpha(0)
        -- end

        -- if BetterBlizzFramesDB.hideFocusMaxHpReduction then
        --     FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.TempMaxHealthLoss:SetAlpha(0)
        -- end

        -- if BetterBlizzFramesDB.hidePlayerMaxHpReduction then
        --     PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.PlayerFrameTempMaxHealthLoss:SetAlpha(0)
        --     PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.TempMaxHealthLossDivider:SetAlpha(0)
        -- end

        if BetterBlizzFramesDB.hideRaidFrameManager then
            CompactRaidFrameManager:SetAlpha(0)
            if not hookedRaidFrameManager then
                CompactRaidFrameManager:HookScript("OnEnter", function()
                    CompactRaidFrameManager:SetAlpha(1)
                end)
                CompactRaidFrameManager:HookScript("OnLeave", function()
                    C_Timer.After(1, function()
                        if CompactRaidFrameManager.collapsed then
                            CompactRaidFrameManager:SetAlpha(0)
                        end
                    end)
                end)
                hookedRaidFrameManager = true
            end
        end

        if BetterBlizzFramesDB.hideBagsBar then
            if not BagsBar.bbfHooked then
                BagsBar:Hide()
                hooksecurefunc(BagsBar, "Show", BagsBar.Hide)
                BagsBar.bbfHooked = true
            end
        end

        local function hideChatFrameTextures()
            for i = 1, NUM_CHAT_WINDOWS do
                local buttonFrame = _G["ChatFrame"..i.."ButtonFrame"]
                local topTexture = _G["ChatFrame"..i.."ButtonFrameTopTexture"]
                local topLeftTexture = _G["ChatFrame"..i.."ButtonFrameTopLeftTexture"]
                local topRightTexture = _G["ChatFrame"..i.."ButtonFrameTopRightTexture"]
                local bottomTexture = _G["ChatFrame"..i.."ButtonFrameBottomTexture"]
                local bottomLeftTexture = _G["ChatFrame"..i.."ButtonFrameBottomLeftTexture"]
                local bottomRightTexture = _G["ChatFrame"..i.."ButtonFrameBottomRightTexture"]
                local rightTexture = _G["ChatFrame"..i.."ButtonFrameRightTexture"]
                local leftTexture = _G["ChatFrame"..i.."ButtonFrameLeftTexture"]

                if buttonFrame then
                    if BetterBlizzFramesDB.hideChatButtons then
                        buttonFrame.Background:Hide()
                        topTexture:Hide()
                        topLeftTexture:Hide()
                        topRightTexture:Hide()
                        bottomTexture:Hide()
                        bottomLeftTexture:Hide()
                        bottomRightTexture:Hide()
                        rightTexture:Hide()
                        leftTexture:Hide()
                    else
                        buttonFrame.Background:Show()
                        topTexture:Show()
                        topLeftTexture:Show()
                        topRightTexture:Show()
                        bottomTexture:Show()
                        bottomLeftTexture:Show()
                        bottomRightTexture:Show()
                        rightTexture:Show()
                        leftTexture:Show()
                    end
                end
            end
        end

        if BetterBlizzFramesDB.hideHitIndicator then
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HitIndicator:SetAlpha(0)
            PetHitIndicator:SetParent(hiddenFrame)
        end

        if BetterBlizzFramesDB.hidePlayerPower then
            if WarlockPowerFrame and englishClass == "WARLOCK" then
                if BetterBlizzFramesDB.hidePlayerPowerNoWarlock then
                    if originalResourceParent then WarlockPowerFrame:SetParent(originalResourceParent) end
                else
                    if not originalResourceParent then originalResourceParent = WarlockPowerFrame:GetParent() end
                    WarlockPowerFrame:SetParent(hiddenFrame)
                end
            end
            if RogueComboPointBarFrame and englishClass == "ROGUE" then
                if BetterBlizzFramesDB.hidePlayerPowerNoRogue then
                    if originalResourceParent then RogueComboPointBarFrame:SetParent(originalResourceParent) end
                else
                    if not originalResourceParent then originalResourceParent = RogueComboPointBarFrame:GetParent() end
                    RogueComboPointBarFrame:SetParent(hiddenFrame)
                end
            end
            if DruidComboPointBarFrame and englishClass == "DRUID" then
                if BetterBlizzFramesDB.hidePlayerPowerNoDruid then
                    DruidComboPointBarFrame:SetAlpha(1)
                else
                    DruidComboPointBarFrame:SetAlpha(0)
                end
            end
            if PaladinPowerBarFrame and englishClass == "PALADIN" then
                if BetterBlizzFramesDB.hidePlayerPowerNoPaladin then
                    if originalResourceParent then PaladinPowerBarFrame:SetParent(originalResourceParent) end
                else
                    if not originalResourceParent then originalResourceParent = PaladinPowerBarFrame:GetParent() end
                    PaladinPowerBarFrame:SetParent(hiddenFrame)
                end
            end
            if RuneFrame and englishClass == "DEATHKNIGHT" then
                if BetterBlizzFramesDB.hidePlayerPowerNoDeathKnight then
                    if originalResourceParent then RuneFrame:SetParent(originalResourceParent) end
                else
                    if not originalResourceParent then originalResourceParent = RuneFrame:GetParent() end
                    RuneFrame:SetParent(hiddenFrame)
                end
            end
            if EssencePlayerFrame and englishClass == "EVOKER" then
                if BetterBlizzFramesDB.hidePlayerPowerNoEvoker then
                    if originalResourceParent then EssencePlayerFrame:SetParent(originalResourceParent) end
                else
                    if not originalResourceParent then originalResourceParent = EssencePlayerFrame:GetParent() end
                    EssencePlayerFrame:SetParent(hiddenFrame)
                end
            end
            if MonkHarmonyBarFrame and englishClass == "MONK" then
                if BetterBlizzFramesDB.hidePlayerPowerNoMonk then
                    if originalResourceParent then MonkHarmonyBarFrame:SetAlpha(originalResourceParent); MonkHarmonyBarFrame:EnableMouse(true) end
                else
                    if not originalResourceParent then originalResourceParent = MonkHarmonyBarFrame:GetAlpha() end
                    --MonkHarmonyBarFrame:SetParent(hiddenFrame)
                    MonkHarmonyBarFrame:SetAlpha(0)
                    MonkHarmonyBarFrame:EnableMouse(false)
                end
            end
            if MageArcaneChargesFrame and englishClass == "MAGE" then
                if BetterBlizzFramesDB.hidePlayerPowerNoMage then
                    MageArcaneChargesFrame:SetAlpha(1)
                else
                    MageArcaneChargesFrame:SetAlpha(0)
                end
            end
            changes.hidePlayerPower = true
        elseif originalResourceParent then
            if WarlockPowerFrame and englishClass == "WARLOCK" then WarlockPowerFrame:SetParent(originalResourceParent) end
            if RogueComboPointBarFrame and englishClass == "ROGUE" then RogueComboPointBarFrame:SetParent(originalResourceParent) end
            if DruidComboPointBarFrame and englishClass == "DRUID" then DruidComboPointBarFrame:SetAlpha(1) end
            if PaladinPowerBarFrame and englishClass == "PALADIN" then PaladinPowerBarFrame:SetParent(originalResourceParent) end
            if RuneFrame and englishClass == "DEATHKNIGHT" then RuneFrame:SetParent(originalResourceParent) end
            if EssencePlayerFrame and englishClass == "EVOKER" then EssencePlayerFrame:SetParent(originalResourceParent) end
            if MonkHarmonyBarFrame and englishClass == "MONK" then MonkHarmonyBarFrame:SetParent(originalResourceParent) end
            if MageArcaneChargesFrame and englishClass == "MAGE" then MageArcaneChargesFrame:SetAlpha(1) end
            changes.hidePlayerPower = nil
        end

        if BetterBlizzFramesDB.hideRaidFrameContainerBorder then
            local compactPartyBorder = CompactPartyFrameBorderFrame or CompactRaidFrameContainerBorderFrame
            if compactPartyBorder then
                changes.hideRaidFrameContainerBorder = compactPartyBorder:GetParent()
                compactPartyBorder:SetParent(BBF.hiddenFrame)
            end
            for i = 1, 8 do
                local frame = _G["CompactRaidGroup"..i.."BorderFrame"]
                if frame then
                    if not frame.ogParent then
                        frame.ogParent = frame:GetParent()
                    end
                    frame:SetParent(BBF.hiddenFrame)
                end
            end
        elseif changes.hideRaidFrameContainerBorder then
            local compactPartyBorder = CompactPartyFrameBorderFrame or CompactRaidFrameContainerBorderFrame
            compactPartyBorder:SetParent(changes.hideRaidFrameContainerBorder)
            changes.hideRaidFrameContainerBorder = nil
            for i = 1, 8 do
                local frame = _G["CompactRaidGroup"..i.."BorderFrame"]
                if frame then
                    if frame.ogParent then
                        frame:SetParent(frame.ogParent)
                        frame.ogParent = nil
                    end
                end
            end
        end

        if db.hideExpAndHonorBar then
            MainStatusTrackingBarContainer:SetParent(hiddenFrame)
            SecondaryStatusTrackingBarContainer:SetParent(hiddenFrame)
            if not BBF.hideExpAndHonorBar then
                CharacterFrame:HookScript("OnShow", function()
                    MainStatusTrackingBarContainer:SetParent(StatusTrackingBarManager)
                    SecondaryStatusTrackingBarContainer:SetParent(StatusTrackingBarManager)
                end)
                CharacterFrame:HookScript("OnHide", function()
                    MainStatusTrackingBarContainer:SetParent(hiddenFrame)
                    SecondaryStatusTrackingBarContainer:SetParent(hiddenFrame)
                end)
                BBF.hideExpAndHonorBar = true
            end
        end

        if BetterBlizzFramesDB.hideUnitFrameShadow then
            if not BetterBlizzFramesDB.classicFrames then
                if not BBF.hideUnitFrameShadow then
                    -- Player
                    if not BetterBlizzFramesDB.symmetricPlayerFrame then
                        local playerTex = PlayerFrame.PlayerFrameContainer.FrameTexture
                        playerTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOn-NoShadow")
                        hooksecurefunc(playerTex, "SetAtlas", function(self)
                            self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOn-NoShadow")
                        end)

                        local playerAltTex = PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture
                        playerAltTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOn-ClassResource-NoShadow")
                        hooksecurefunc(playerAltTex, "SetAtlas", function(self)
                            self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Player-PortraitOn-ClassResource-NoShadow")
                        end)
                    end

                    -- Target & Focus
                    local targetTex = TargetFrame.TargetFrameContainer.FrameTexture
                    targetTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Target-PortraitOn-NoShadow")
                    hooksecurefunc(targetTex, "SetAtlas", function(self, atlas)
                        if atlas == "UI-HUD-UnitFrame-Target-PortraitOn" then
                            self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Target-PortraitOn-NoShadow")
                        elseif atlas == "UI-HUD-UnitFrame-Target-MinusMob-PortraitOn" then
                            self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-NoShadow")
                        end
                    end)
                    local focusTex = FocusFrame.TargetFrameContainer.FrameTexture
                    focusTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Target-PortraitOn-NoShadow")
                    hooksecurefunc(focusTex, "SetAtlas", function(self, atlas)
                        if atlas == "UI-HUD-UnitFrame-Target-PortraitOn" then
                            self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Target-PortraitOn-NoShadow")
                        elseif atlas == "UI-HUD-UnitFrame-Target-MinusMob-PortraitOn" then
                            self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-NoShadow")
                        end
                    end)

                    -- ToT's
                    local totTex = TargetFrame.totFrame.FrameTexture
                    totTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-TargetofTarget-PortraitOn-NoShadow")
                    hooksecurefunc(totTex, "SetAtlas", function(self)
                        self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-TargetofTarget-PortraitOn-NoShadow")
                    end)
                    local totFocusTex = FocusFrame.totFrame.FrameTexture
                    totFocusTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-TargetofTarget-PortraitOn-NoShadow")
                    hooksecurefunc(totFocusTex, "SetAtlas", function(self)
                        self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-TargetofTarget-PortraitOn-NoShadow")
                    end)
                    --Pet
                    local petTex = PetFrameTexture
                    petTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-TargetofTarget-PortraitOn-NoShadow")
                    hooksecurefunc(petTex, "SetAtlas", function(self)
                        self:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-UnitFrame-TargetofTarget-PortraitOn-NoShadow")
                    end)

                    BBF.hideUnitFrameShadow = true
                end
            end
        end

        if BetterBlizzFramesDB.hideChatButtons then
            QuickJoinToastButton:SetAlpha(0)
            ChatFrameChannelButton:SetAlpha(0)
            ChatFrameMenuButton:SetAlpha(0)
            TextToSpeechButton:SetAlpha(0)
            hideChatFrameTextures()

            if not hookedChatButtons then
                QuickJoinToastButton:HookScript("OnEnter", function()
                    QuickJoinToastButton:SetAlpha(1)
                    ChatFrameChannelButton:SetAlpha(1)
                    ChatFrameMenuButton:SetAlpha(1)
                    TextToSpeechButton:SetAlpha(1)
                end)
                QuickJoinToastButton:HookScript("OnLeave", function()
                    C_Timer.After(1, function()
                        QuickJoinToastButton:SetAlpha(0)
                        ChatFrameChannelButton:SetAlpha(0)
                        ChatFrameMenuButton:SetAlpha(0)
                        TextToSpeechButton:SetAlpha(0)
                    end)
                end)
                ChatFrameChannelButton:HookScript("OnEnter", function()
                    QuickJoinToastButton:SetAlpha(1)
                    ChatFrameChannelButton:SetAlpha(1)
                    ChatFrameMenuButton:SetAlpha(1)
                    TextToSpeechButton:SetAlpha(1)
                end)
                ChatFrameChannelButton:HookScript("OnLeave", function()
                    C_Timer.After(1, function()
                        QuickJoinToastButton:SetAlpha(0)
                        ChatFrameChannelButton:SetAlpha(0)
                        ChatFrameMenuButton:SetAlpha(0)
                        TextToSpeechButton:SetAlpha(0)
                    end)
                end)
                ChatFrameMenuButton:HookScript("OnEnter", function()
                    QuickJoinToastButton:SetAlpha(1)
                    ChatFrameChannelButton:SetAlpha(1)
                    ChatFrameMenuButton:SetAlpha(1)
                    TextToSpeechButton:SetAlpha(1)
                end)
                ChatFrameMenuButton:HookScript("OnLeave", function()
                    C_Timer.After(1, function()
                        QuickJoinToastButton:SetAlpha(0)
                        ChatFrameChannelButton:SetAlpha(0)
                        ChatFrameMenuButton:SetAlpha(0)
                        TextToSpeechButton:SetAlpha(0)
                    end)
                end)
                TextToSpeechButton:HookScript("OnEnter", function()
                    QuickJoinToastButton:SetAlpha(1)
                    ChatFrameChannelButton:SetAlpha(1)
                    ChatFrameMenuButton:SetAlpha(1)
                    TextToSpeechButton:SetAlpha(1)
                end)
                TextToSpeechButton:HookScript("OnLeave", function()
                    C_Timer.After(1, function()
                        QuickJoinToastButton:SetAlpha(0)
                        ChatFrameChannelButton:SetAlpha(0)
                        ChatFrameMenuButton:SetAlpha(0)
                        TextToSpeechButton:SetAlpha(0)
                    end)
                end)
                hookedChatButtons = true
            end
        else
            QuickJoinToastButton:SetAlpha(1)
            ChatFrameChannelButton:SetAlpha(1)
            ChatFrameMenuButton:SetAlpha(1)
            TextToSpeechButton:SetAlpha(1)
            hideChatFrameTextures()
        end
        BBF.HidePartyInArena()
        if BetterBlizzFramesDB.hideTargetToTDebuffs then
            for i = 1, 4 do
                local targetToTDebuff = _G["TargetFrameToTDebuff" .. i]
                if targetToTDebuff then
                    targetToTDebuff:SetParent(hiddenFrame)
                end
            end
        end
        if BetterBlizzFramesDB.hideFocusToTDebuffs then
            for i = 1, 4 do
                local focusToTDebuff = _G["FocusFrameToTDebuff" .. i]
                if focusToTDebuff then
                    focusToTDebuff:SetParent(hiddenFrame)
                end
            end
        end

        if BetterBlizzFramesDB.hidePlayerHealthLossAnim then
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.PlayerFrameHealthBarAnimatedLoss:SetParent(hiddenFrame)
        end

        local LossOfControlFrameAlphaBg = BetterBlizzFramesDB.hideLossOfControlFrameBg and 0 or 0.6
        local LossOfControlFrameAlphaLines = BetterBlizzFramesDB.hideLossOfControlFrameLines and 0 or 1
        LossOfControlFrame.blackBg:SetAlpha(LossOfControlFrameAlphaBg)
        LossOfControlFrame.RedLineTop:SetAlpha(LossOfControlFrameAlphaLines)
        LossOfControlFrame.RedLineBottom:SetAlpha(LossOfControlFrameAlphaLines)

        -- action bar macro name hotkey hide
        local hotKeyAlpha = BetterBlizzFramesDB.hideActionBarHotKey and 0 or 1
        local macroNameAlpha = BetterBlizzFramesDB.hideActionBarMacroName and 0 or 1

        if BetterBlizzFramesDB.hideActionBarHotKey or BetterBlizzFramesDB.hideActionBarMacroName or keybindAlphaChanged then
            -- Blizzard buttons
            local blizzPrefixes = {
                "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
                "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
                "MultiBar6Button", "MultiBar7Button", "PetActionButton"
            }

            for _, prefix in ipairs(blizzPrefixes) do
                for i = 1, 12 do
                    applyAlpha(_G[prefix .. i .. "HotKey"], hotKeyAlpha)
                    applyAlpha(_G[prefix .. i .. "Name"], macroNameAlpha)
                end
            end

            -- Dominos buttons
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
                    applyAlpha(_G[bar.name .. i .. "HotKey"], hotKeyAlpha)
                    applyAlpha(_G[bar.name .. i .. "Name"], macroNameAlpha)
                end
            end

            keybindAlphaChanged = true
        end

        if BetterBlizzFramesDB.hideUiErrorFrame then
            if not BBF.hidingErrorFrame then
                --	Error message events
                local OrigErrHandler = UIErrorsFrame:GetScript('OnEvent')
                UIErrorsFrame:SetScript('OnEvent', function (self, event, id, err, ...)
                    if event == "UI_ERROR_MESSAGE" then
                        -- Hide error messages
                        if 	err == ERR_INV_FULL or
                            err == ERR_QUEST_LOG_FULL or
                            err == ERR_RAID_GROUP_ONLY	or
                            err == ERR_PARTY_LFG_BOOT_LIMIT or
                            err == ERR_PARTY_LFG_BOOT_DUNGEON_COMPLETE or
                            err == ERR_PARTY_LFG_BOOT_IN_COMBAT or
                            err == ERR_PARTY_LFG_BOOT_IN_PROGRESS or
                            err == ERR_PARTY_LFG_BOOT_LOOT_ROLLS or
                            err == ERR_PARTY_LFG_TELEPORT_IN_COMBAT or
                            err == ERR_PET_SPELL_DEAD or
                            err == ERR_PLAYER_DEAD or
                            err == SPELL_FAILED_TARGET_NO_POCKETS or
                            err == ERR_ALREADY_PICKPOCKETED or
                            err:find(format(ERR_PARTY_LFG_BOOT_NOT_ELIGIBLE_S, ".+")) then
                                return OrigErrHandler(self, event, id, err, ...)
                        end
                    elseif event == 'UI_INFO_MESSAGE'  then
                        -- Show information messages
                        return OrigErrHandler(self, event, id, err, ...)
                    end
                end)

                -- Hide ping system errors
                UIParent:UnregisterEvent("PING_SYSTEM_ERROR")
                BBF.hidingErrorFrame = true
            end
        end

        -- Hide ToT Frames
        local targetToTAlpha = BetterBlizzFramesDB.hideTargetToT and 0 or 1
        local focusToTAlpha = BetterBlizzFramesDB.hideFocusToT and 0 or 1
        TargetFrameToT:SetAlpha(targetToTAlpha)
        FocusFrameToT:SetAlpha(focusToTAlpha)

        -- Hide Rare Textures
        if BetterBlizzFramesDB.hideRareDragonTexture then
            TargetFrame.TargetFrameContainer.BossPortraitFrameTexture:SetAlpha(0)
            FocusFrame.TargetFrameContainer.BossPortraitFrameTexture:SetAlpha(0)
            changes.hideRareDragonTexture = true
        elseif changes.hideRareDragonTexture then
            TargetFrame.TargetFrameContainer.BossPortraitFrameTexture:SetAlpha(1)
            FocusFrame.TargetFrameContainer.BossPortraitFrameTexture:SetAlpha(1)
            changes.hideRareDragonTexture = nil
        end

        -- Hide Stance Bar
        if BetterBlizzFramesDB.hideStanceBar then
            for i = 1, 10 do
                local buttonName = "StanceButton" .. i
                local button = _G[buttonName]
                if button then
                    if not originalStanceParent then
                        originalStanceParent = button:GetParent()
                    end
                    button:SetParent(hiddenFrame)
                end
            end
        elseif originalStanceParent then
            for i = 1, 10 do
                local buttonName = "StanceButton" .. i
                local button = _G[buttonName]
                if button then
                    button:SetParent(originalStanceParent)
                end
            end
        end


        local function ToggleLibDBIconButtons(show)
            for i = 1, Minimap:GetNumChildren() do
                local child = select(i, Minimap:GetChildren())
                local childName = child:GetName() or ""
                if string.find(childName, "LibDBIcon") or childName == "ExpansionLandingPageMinimapButton" then
                    if show then
                        child:Show()
                        ExpansionLandingPageMinimapButton:Show()
                    else
                        child:Hide()
                        ExpansionLandingPageMinimapButton:Hide()
                    end
                end
            end
        end

        -- Hide all LibDBIcon buttons by default
        if BetterBlizzFramesDB.hideMinimapButtons and not minimapButtonsHooked then
            ToggleLibDBIconButtons(false)
            C_Timer.After(1, function()
                ToggleLibDBIconButtons(false)

                -- Set up the Minimap's OnEnter and OnLeave script handlers
                Minimap:HookScript("OnEnter", function()
                    iconMouseOver = true
                    ToggleLibDBIconButtons(true)
                end)

                Minimap:HookScript("OnLeave", function()
                    iconMouseOver = false
                    -- Delay hiding to check if we left the Minimap to another LibDBIcon or completely out
                    C_Timer.After(0.1, function() 
                        if not Minimap:IsMouseOver() and not iconMouseOver then
                            ToggleLibDBIconButtons(false)
                        end
                    end)
                end)

                ExpansionLandingPageMinimapButton:HookScript("OnEnter", function()
                    iconMouseOver = true
                    ToggleLibDBIconButtons(true)
                end)

                ExpansionLandingPageMinimapButton:HookScript("OnLeave", function()
                    iconMouseOver = false
                    -- Delay hiding to check if we left the Minimap to another LibDBIcon or completely out
                    C_Timer.After(0.1, function() 
                        if not Minimap:IsMouseOver() and not iconMouseOver then
                            ToggleLibDBIconButtons(false)
                        end
                    end)
                end)

                for i = 1, Minimap:GetNumChildren() do
                    local child = select(i, Minimap:GetChildren())
                    local childName = child:GetName() or ""
                    if string.find(childName, "LibDBIcon") or childName == "ExpansionLandingPageMinimapButton" then
                        child:HookScript("OnEnter", function()
                            iconMouseOver = true
                            ToggleLibDBIconButtons(true)
                        end)
                        child:HookScript("OnLeave", function()
                            iconMouseOver = false
                            -- Delay hiding to check if we left the icon to the Minimap or another icon
                            C_Timer.After(0.1, function()
                                if not Minimap:IsMouseOver() and not iconMouseOver then
                                    ToggleLibDBIconButtons(false)
                                end
                            end)
                        end)
                    end
                end
                minimapButtonsHooked = true
            end)
        end

        local aggroAlpha = BetterBlizzFramesDB.hidePartyAggroHighlight and 0 or 1

        for i = 1, 5 do
            local aggroHighlight = _G["CompactPartyFrameMember" .. i .. "AggroHighlight"]
            if aggroHighlight then
                -- Only adjust alpha if it differs from the desired state
                if aggroHighlight:GetAlpha() ~= aggroAlpha then
                    aggroHighlight:SetAlpha(aggroAlpha)
                end
            end
        end

        if BetterBlizzFramesDB.hidePetText then
            PetFrameHealthBarText:SetAlpha(0)
            PetFrameHealthBarText:Hide()
            PetFrameHealthBarTextLeft:SetAlpha(0)
            PetFrameHealthBarTextLeft:Hide()
            PetFrameHealthBarTextRight:SetAlpha(0)
            PetFrameHealthBarTextRight:Hide()

            PetFrameManaBarText:SetAlpha(0)
            PetFrameManaBarText:Hide()
            PetFrameManaBarTextLeft:SetAlpha(0)
            PetFrameManaBarTextLeft:Hide()
            PetFrameManaBarTextRight:SetAlpha(0)
            PetFrameManaBarTextRight:Hide()
        end
    end
end

local function UpdateLevelTextVisibility(unitFrame, unit)
    if BetterBlizzFramesDB.hideLevelText and not BetterBlizzFramesDB.classicFrames then
        if BetterBlizzFramesDB.hideLevelTextAlways then
            unitFrame.LevelText:SetAlpha(0)
            return
        end
        if UnitLevel(unit) == 80 then
            unitFrame.LevelText:SetAlpha(0)
        else
            unitFrame.LevelText:SetAlpha(1)
        end
    end
end

local function OnTargetOrFocusChanged(event, ...)
    UpdateLevelTextVisibility(TargetFrame.TargetFrameContent.TargetFrameContentMain, "target")
    UpdateLevelTextVisibility(FocusFrame.TargetFrameContent.TargetFrameContentMain, "focus")
end

local TargetLevelHider = CreateFrame("Frame")
TargetLevelHider:SetScript("OnEvent", OnTargetOrFocusChanged)
TargetLevelHider:RegisterEvent("PLAYER_TARGET_CHANGED")
TargetLevelHider:RegisterEvent("PLAYER_FOCUS_CHANGED")

--------------------------------------
-- Hide Party Frames in Arena
--------------------------------------
local partyAlpha = 1
local partyFrameHider
function BBF.HidePartyInArena()
    if BetterBlizzFramesDB.hidePartyFramesInArena and not partyFrameHider then
        partyFrameHider = CreateFrame("Frame")

        partyFrameHider:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_ENTERING_BATTLEGROUND" and BetterBlizzFramesDB.hidePartyFramesInArena then
                partyAlpha = 0
            elseif event == "PLAYER_ENTERING_WORLD" and C_PvP.IsArena() == false then
                partyAlpha = 1
            end

            local frames = {
                "PartyFrame",
                "PartyMemberBuffTooltip",
            }

            for i = 1, 3 do
                table.insert(frames, "CompactPartyFrameMember" .. i .. "Background")
                table.insert(frames, "CompactPartyFrameMember" .. i .. "SelectionHighlight")
                table.insert(frames, "CompactPartyFrameMember" .. i .. "HorizDivider")
                table.insert(frames, "CompactPartyFrameMember" .. i .. "HorizTopBorder")
                table.insert(frames, "CompactPartyFrameMember" .. i .. "HorizBottomBorder")
                table.insert(frames, "CompactPartyFrameMember" .. i .. "VertLeftBorder")
                table.insert(frames, "CompactPartyFrameMember" .. i .. "VertRightBorder")

                table.insert(frames, "CompactPartyFramePet" .. i .. "Background")
                table.insert(frames, "CompactPartyFramePet" .. i .. "SelectionHighlight")
                table.insert(frames, "CompactPartyFramePet" .. i .. "HorizDivider")
                table.insert(frames, "CompactPartyFramePet" .. i .. "HorizTopBorder")
                table.insert(frames, "CompactPartyFramePet" .. i .. "HorizBottomBorder")
                table.insert(frames, "CompactPartyFramePet" .. i .. "VertLeftBorder")
                table.insert(frames, "CompactPartyFramePet" .. i .. "VertRightBorder")
            end

            for _, frame in ipairs(frames) do
                local frameObject = _G[frame]
                if frameObject then
                    frameObject:SetAlpha(partyAlpha)
                end
            end
        end)
        partyFrameHider:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
        partyFrameHider:RegisterEvent("PLAYER_ENTERING_WORLD")
        if not C_PvP.IsArena() == false then
            partyAlpha = 0
        end
    elseif BetterBlizzFramesDB.hidePartyFramesInArena and partyFrameHider then
        if not C_PvP.IsArena() == false then
            partyAlpha = 0
        else
            partyAlpha = 1
        end
    elseif not BetterBlizzFramesDB.hidePartyFramesInArena then
        if partyFrameHider then
            partyFrameHider:UnregisterEvent("PLAYER_ENTERING_BATTLEGROUND")
            partyFrameHider:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
        partyAlpha = 1
    end
end

--------------------------------------
-- Minimap Hider
--------------------------------------
local minimapStatusChanged

function BBF.MinimapHider()
    local MinimapGroup = Minimap and MinimapCluster
    local QueueStatusEye = QueueStatusButtonIcon
    local ObjectiveTracker = ObjectiveTrackerFrame

    local _, instanceType = GetInstanceInfo()
    local inArena = instanceType == "arena"

    local hideMinimap = BetterBlizzFramesDB.hideMinimap
    local hideMinimapAuto = BetterBlizzFramesDB.hideMinimapAuto
    local hideQueueEye = BetterBlizzFramesDB.hideMinimapAutoQueueEye
    local hideObjectives = BetterBlizzFramesDB.hideObjectiveTracker

    -- Handle MinimapGroup visibility
    if hideMinimapAuto and inArena then
        MinimapGroup:Hide()
    elseif hideMinimapAuto and not inArena then
        MinimapGroup:Show()
    end

    if hideMinimap then
        MinimapGroup:Hide()
        minimapStatusChanged = true
    elseif minimapStatusChanged then
        MinimapGroup:Show()
    end

    -- Handle QueueStatusEye visibility
    if hideQueueEye then
        if inArena then
            QueueStatusEye:Hide()
        else
            QueueStatusEye:Show()
        end
    end

    -- Handle ObjectiveTracker visibility
    if hideObjectives then
        if not ObjectiveTracker.bbpHook then
            ObjectiveTrackerFrame:HookScript("OnShow", function()
                local _, instanceType = GetInstanceInfo()
                local inArena = instanceType == "arena"

                if inArena then
                    ObjectiveTrackerFrame:Hide()
                end
            end)
            ObjectiveTracker.bbpHook = true
        end
        if inArena then
            ObjectiveTracker:Hide()
        else
            ObjectiveTracker:Show()
        end
    end
end


function BBF.FadeMicroMenu()
    if not BetterBlizzFramesDB.fadeMicroMenu then return end
    if not MicroMenu.bffHooked then
        local function FadeOutFrame(frame, duration)
            UIFrameFadeOut(frame, duration, 1, 0)
        end

        local function FadeInFrame(frame, duration)
            UIFrameFadeIn(frame, duration, 0, 1)
        end

        local fadeTimer = nil -- Holds the current fade-out timer
        local gracePeriod = 0.5 -- Grace period before fading out
        local isFadedIn = false -- Tracks whether elements are already faded in

        -- Fade helper for multiple frames
        local function FadeElements(fadeType, duration)
            local frames = {BagsBar, MicroMenu, MicroMenuContainer}
            for _, child in ipairs({MicroMenu:GetChildren()}) do
                table.insert(frames, child)
            end

            for _, frame in ipairs(frames) do
                local adjustedDuration = duration

                -- Make BagsBar fade out 0.2 seconds faster
                if frame == BagsBar and fadeType == "out" then
                    adjustedDuration = math.max(duration - 0.6, 0) -- Ensure non-negative duration
                end

                if EditModeManagerFrame:IsEditModeActive() then
                    FadeInFrame(frame, 0) -- Force full alpha if Edit Mode is active
                else
                    if fadeType == "in" then
                        FadeInFrame(frame, adjustedDuration)
                    elseif fadeType == "out" then
                        FadeOutFrame(frame, adjustedDuration)
                    end
                end
            end
        end

        -- Mouseover detection
        local function IsAnyMouseOver()
            if BagsBar:IsMouseOver() or MicroMenu:IsMouseOver() or MicroMenuContainer:IsMouseOver() then
                return true
            end
            for _, child in ipairs({BagsBar:GetChildren(), MicroMenu:GetChildren()}) do
                if child:IsMouseOver() then
                    return true
                end
            end
            return false
        end

        -- Show elements (fade in)
        local function ShowElements()
            if not isFadedIn and not EditModeManagerFrame:IsEditModeActive() then -- Only fade in if not already visible and Edit Mode inactive
                if fadeTimer then
                    fadeTimer:Cancel() -- Cancel any pending fade-out
                    fadeTimer = nil
                end
                FadeElements("in", 0.1) -- Smooth fade-in
                isFadedIn = true
            end
        end

        -- Hide elements (fade out with grace period)
        local function HideElements()
            if fadeTimer then
                fadeTimer:Cancel() -- Reset any existing timer
            end

            fadeTimer = C_Timer.NewTimer(gracePeriod, function()
                if not IsAnyMouseOver() and not EditModeManagerFrame:IsEditModeActive() then
                    FadeElements("out", 1.1) -- Smooth fade-out
                    isFadedIn = false -- Mark as faded out
                end
            end)
        end

        -- Reset alpha on Edit Mode toggle
        local function ResetAlphaOnEditMode()
            if EditModeManagerFrame:IsEditModeActive() then
                -- Force all frames to full alpha
                FadeElements("in", 0)
            else
                -- Fade out frames instantly if Edit Mode is closed
                FadeElements("out", 0)
                isFadedIn = false
            end
        end

        -- Initial state: start hidden if not in Edit Mode
        if not EditModeManagerFrame:IsEditModeActive() then
            FadeElements("out", 0) -- Instantly fade out all elements
            isFadedIn = false
        else
            FadeElements("in", 0) -- Full alpha when Edit Mode is active
        end

        -- Apply hooks only once
        if not BagsBar.scHooked then
            -- Hooks for BagsBar and its children
            BagsBar:HookScript("OnEnter", ShowElements)
            BagsBar:HookScript("OnLeave", HideElements)

            for _, child in ipairs({BagsBar:GetChildren()}) do
                child:HookScript("OnEnter", ShowElements)
                child:HookScript("OnLeave", HideElements)
            end

            BagsBar.scHooked = true
        end

        if not MicroMenu.scHooked then
            -- Hooks for MicroMenu, MicroMenuContainer, and its children
            MicroMenu:HookScript("OnEnter", ShowElements)
            MicroMenu:HookScript("OnLeave", HideElements)

            MicroMenuContainer:HookScript("OnEnter", ShowElements)
            MicroMenuContainer:HookScript("OnLeave", HideElements)

            for _, child in ipairs({MicroMenu:GetChildren()}) do
                child:HookScript("OnEnter", ShowElements)
                child:HookScript("OnLeave", HideElements)
            end

            -- Special case for QueueStatusButton if required
            QueueStatusButton:SetParent(UIParent)
            QueueStatusButton:SetFrameLevel(10)

            MicroMenu.scHooked = true
        end

        -- Hook into Edit Mode events to reset alpha
        hooksecurefunc(EditModeManagerFrame, "EnterEditMode", ResetAlphaOnEditMode)
        hooksecurefunc(EditModeManagerFrame, "ExitEditMode", ResetAlphaOnEditMode)

        -- Special case for QueueStatusButton if required
        if BetterBlizzFramesDB.fadeMicroMenuExceptQueue then
            QueueStatusButton:SetParent(UIParent)
            QueueStatusButton:SetFrameLevel(10)
        end

        MicroMenu.bffHooked = true
    end
end

function BBF.MoveQueueStatusEye()
    if not BetterBlizzFramesDB.moveQueueStatusEye then return end
    if C_AddOns.IsAddOnLoaded("Bartender4") then
        DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames: This setting is disabled with Bartender4. You can already move it with Bartender4.")
        return
    end

    local button = QueueStatusButton
    if button.bbfHooked then return end
    QueueStatusButton:SetParent(UIParent)
    QueueStatusButton:SetFrameLevel(10)

    local function CalculateMicroMenuWidthWithoutQueue()
        if not MicroMenu then return 1 end
        if MicroMenu:GetParent() ~= MicroMenuContainer then return 1 end

        local isHorizontal = not MicroMenu or MicroMenu.isHorizontal;
        local width, height = 0, 0;

        local function AddFrameSize(frame, includeOffset)
            local scale = frame:GetScale()
            if isHorizontal then
                width = width + frame:GetWidth() * scale;
                if includeOffset then
                    local point, _, _, offsetX = frame:GetPoint(1)
                    width = width + math.abs(offsetX * scale);
                end
                height = math.max(height, frame:GetHeight() * scale);
            else
                width = math.max(width, frame:GetWidth() * scale);
                height = height + frame:GetHeight() * scale;
                if includeOffset then
                    local _, _, _, _, offsetY = frame:GetPoint(1)
                    height = height + math.abs(offsetY * scale);
                end
            end
        end
        AddFrameSize(MicroMenu);
        return math.max(width, 1)
    end

    hooksecurefunc(MicroMenuContainer, "SetSize", function(self)
        local width = CalculateMicroMenuWidthWithoutQueue();
	    self:SetWidth(width);
    end)

    -- Hook the SetPoint function to prevent automatic resets
    hooksecurefunc(button, "SetPoint", function(self, _, _, _, _, _)
        if self:IsProtected() or self.changing then return end
        self.changing = true
        self:ClearAllPoints()

        if BetterBlizzFramesDB.queueStatusButtonPosition then
            local pos = BetterBlizzFramesDB.queueStatusButtonPosition
            self:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
        else
            self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -180, -141)
        end

        self.changing = false
    end)

    button:HookScript("OnShow", function(self)
        if self:IsProtected() or self.changing then return end
        self.changing = true
        self:ClearAllPoints()

        if BetterBlizzFramesDB.queueStatusButtonPosition then
            local pos = BetterBlizzFramesDB.queueStatusButtonPosition
            self:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
        else
            self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -180, -141)
        end

        self.changing = false
    end)

    -- Enable dragging with Ctrl + Left Click
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")

    -- Start dragging when Ctrl + Left Click is held
    button:SetScript("OnDragStart", function(self)
        if IsControlKeyDown() then
            self:StartMoving()
        end
    end)

    -- Stop dragging and save position
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        -- Save the new position
        local point, _, relativePoint, xOffset, yOffset = self:GetPoint()
        BetterBlizzFramesDB.queueStatusButtonPosition = {point, nil, relativePoint, xOffset, yOffset}
    end)

    if BetterBlizzFramesDB.queueStatusButtonPosition then
        local pos = BetterBlizzFramesDB.queueStatusButtonPosition
        button:ClearAllPoints()
        button:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
    else
        button:ClearAllPoints()
        button:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -180, -141)
        local point, _, relativePoint, xOffset, yOffset = button:GetPoint()
        BetterBlizzFramesDB.queueStatusButtonPosition = {point, nil, relativePoint, xOffset, yOffset}
    end

    button:SetParent(UIParent)
    button:SetFrameStrata("HIGH")

    button.bbfHooked = true
end

-- QueueStatusButton:HookScript("OnShow", function(self)
--     if self:IsProtected() then return end
--     self:ClearAllPoints()
--     self:SetPoint("CENTER", Minimap, "BOTTOMLEFT", 29, 33)
--     self:SetParent(Minimap)
--     self:SetFrameStrata("HIGH")
-- end)

-- hooksecurefunc(QueueStatusButton, "SetPoint", function(self)
--     if self:IsProtected() or self.changing then return end
--     self.changing = true
--     self:ClearAllPoints()
--     self:SetPoint("CENTER", Minimap, "BOTTOMLEFT", 29, 33)
--     self:SetParent(Minimap)
--     self:SetFrameStrata("HIGH")
--     self.changing = false
-- end)

-- local combatControl = true
-- --------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------
-- function OnTooltipSetUnit( tooltip, data )
-- 	if combatControl and InCombatLockdown() and not C_PetBattles.IsInBattle() then
-- 		if data and data.guid then
-- 			local type, _, _, _, _, npcID = string.split( "-", data.guid )
-- 			if ( type ~= "Player" ) and ( type ~= "Vignette" ) then
-- 				npcID = tonumber( npcID )
-- 				local t = { 131616, 134064, 139573, 144605, 147834, 147876, 147861, 147774, 147775, 147780, 147784, 155909, 155910, 155911 }
-- 				for i = 1, #t do
-- 					if ( npcID == t[i] ) then
-- 						return
-- 					end
-- 				end
-- 			elseif ( type == "Player" ) then
-- 				local unit = select( 2, tooltip:GetUnit() )
-- 				if unit then
-- 					for i = 1, 40 do
-- 						local _, _, _, _, _, _, _, _, _, spellID = UnitAura( unit, i, "HARMFUL" )
-- 						if not spellID then
-- 							break
-- 						elseif ( spellID == 286105 ) then
-- 							return
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		GameTooltip:Hide()
-- 	end
-- end
-- TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)

-- CompactPartyFrameMember1SelectionHighlight:SetParent(hiddenFrame)
-- CompactPartyFrameMember2SelectionHighlight:SetParent(hiddenFrame)
-- CompactPartyFrameMember3SelectionHighlight:SetParent(hiddenFrame)