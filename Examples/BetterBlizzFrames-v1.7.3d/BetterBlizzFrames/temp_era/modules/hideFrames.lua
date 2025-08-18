local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()
BBF.hiddenFrame = hiddenFrame

--------------------------------------
-- Hide UI Frame Elements
--------------------------------------
local hookedRaidFrameManager = false
local hookedChatButtons = false
local changedResource = false
local originalResourceParent
local originalBossFrameParent
local bossFrameHooked
local originalStanceParent
local iconMouseOver = false -- flag to indicate if any LibDBIcon is currently moused over
local minimapButtonsHooked = false
local bagButtonsHooked = false
local keybindAlphaChanged = false
local PlayerStatusTextureParent

local changes = {}
local originalParents = {}

local function applyAlpha(frame, alpha)
    if frame then
        frame:SetAlpha(alpha)
    end
end

local OnSetVertexColorHookScript = function(r, g, b, a)
    return function(texture, red, green, blue, alpha, flag)
        if flag ~= "BBFHookSetVertexColor" then
            texture:SetVertexColor(r, g, b, a, "BBFHookSetVertexColor")
        end
    end
end

function BBF.SetTextureColor(texture, r, g, b, a)
    texture:SetVertexColor(r, g, b, a, "BBFHookSetVertexColor")

    if (not texture.BBFHookSetVertexColor) then
        hooksecurefunc(texture, "SetVertexColor", OnSetVertexColorHookScript(r, g, b, a))
        texture.BBFHookSetVertexColor = true
    end
end




local OnShowHookScript = function()
    return function(frame)
        frame:SetAlpha(0)
    end
end

function BBF.SetAlphaRegion(frame)
    frame:SetAlpha(0)

    if not frame.BBFHookHide then
        hooksecurefunc(frame, "Show", OnShowHookScript())
        frame.BBFHookHide = true
    end
end


function BBF.HookAndDo(frame, methodName, callback)
    if not frame or not methodName or not callback then
        return
    end

    -- Ensure the callback is only hooked once
    if not frame.BBFHooks then
        frame.BBFHooks = {}
    end

    if not frame.BBFHooks[methodName] then
        frame.BBFHooks[methodName] = true

        -- Create a flag to prevent recursion
        local flag = "BBFHook"..methodName

        -- Hook the method safely
        hooksecurefunc(frame, methodName, function(self, ...)
            -- Extract arguments
            local args = {...}
            -- Check if the flag is set to prevent recursion
            if args[#args] ~= flag then
                -- Append the flag to the arguments
                table.insert(args, flag)
                -- Call the callback with the same arguments
                callback(self, unpack(args))
            end
        end)
    end
end









local function UpdateLevelTextVisibility(unitFrame, unit)
    if BetterBlizzFramesDB.hideLevelText then
        if BetterBlizzFramesDB.hideLevelTextAlways then
            unitFrame:SetAlpha(0)
            return
        end
        if UnitLevel(unit) == 85 then
            unitFrame:SetAlpha(0)
        else
            unitFrame:SetAlpha(1)
        end
    end
end

local function OnTargetOrFocusChanged(event, ...)
    UpdateLevelTextVisibility(TargetFrameTextureFrameLevelText, "target")
    --UpdateLevelTextVisibility(FocusFrameTextureFrameLevelText, "focus")
end

local function ChangeParent(element, hide)
    if hide then
        if not originalParents[element] then
            originalParents[element] = element:GetParent()
        end
        element:SetParent(hiddenFrame)
    else
        if originalParents[element] then
            element:SetParent(originalParents[element])
        end
    end
end

function BBF.HideFrames()
    -- if BetterBlizzFramesDB.hasCheckedUi then
        local playerClass, englishClass = UnitClass("player")
        -- --Hide group indicator on player unitframe
        local groupIndicatorAlpha = BetterBlizzFramesDB.hideGroupIndicator and 0 or 1
        -- PlayerFrameGroupIndicatorMiddle:SetAlpha(groupIndicatorAlpha)
        -- PlayerFrameGroupIndicatorText:SetAlpha(groupIndicatorAlpha)
        -- PlayerFrameGroupIndicatorLeft:SetAlpha(groupIndicatorAlpha)
        -- PlayerFrameGroupIndicatorRight:SetAlpha(groupIndicatorAlpha)
        PlayerFrameGroupIndicator:SetAlpha(groupIndicatorAlpha)

        -- Hide target leader icon
        local targetLeaderIconAlpha = BetterBlizzFramesDB.hideTargetLeaderIcon and 0 or 1
        TargetFrameTextureFrameLeaderIcon:SetAlpha(targetLeaderIconAlpha)

        -- Hide focus leader icon
        local focusLeaderIconAlpha = BetterBlizzFramesDB.hideTargetLeaderIcon and 0 or 1
        --FocusFrameTextureFrameLeaderIcon:SetAlpha(focusLeaderIconAlpha)

        -- Hide Player Leader Icon
        local playerLeaderIconAlpha = BetterBlizzFramesDB.hidePlayerLeaderIcon and 0 or 1
        PlayerLeaderIcon:SetAlpha(playerLeaderIconAlpha)

        -- PvP Timer Text
        if BetterBlizzFramesDB.hidePvpTimerText then
            --PlayerPVPTimerText:SetParent(hiddenFrame)
            PlayerPVPTimerText:SetAlpha(0)
            PlayerPVPTimerText:Hide()
        --else
            --PlayerPVPTimerText:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
        end

    --     if BetterBlizzFramesDB.hideBossFrames then
    --         if not originalBossFrameParent then
    --             originalBossFrameParent = BossTargetFrameContainer:GetParent()
    --         end
    --         BossTargetFrameContainer:SetParent(hiddenFrame)
    --         if not bossFrameHooked then
    --             hiddenFrame:RegisterEvent("ENCOUNTER_START")
    --             hiddenFrame:RegisterEvent("ENCOUNTER_END")
    --             hiddenFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    --             hiddenFrame:SetScript("OnEvent", function()
    --                 local inInstance, instanceType = IsInInstance()

    --                 if BetterBlizzFramesDB.hideBossFramesParty and inInstance and instanceType == "party" then
    --                     BossTargetFrameContainer:SetParent(hiddenFrame)
    --                 elseif BetterBlizzFramesDB.hideBossFramesRaid and inInstance and instanceType == "raid" then
    --                     BossTargetFrameContainer:SetParent(hiddenFrame)
    --                 else
    --                     BossTargetFrameContainer:SetParent(originalBossFrameParent)
    --                 end
    --             end)

    --             bossFrameHooked = true
    --         end
    --     else
    --         if bossFrameHooked then
    --             BossTargetFrameContainer:SetParent(originalBossFrameParent)
    --         end
    --     end

    --     -- Player Combat Icon
        local playerCombatIconAlpha = BetterBlizzFramesDB.hideCombatIcon and 0 or 1
        PlayerAttackIcon:SetAlpha(playerCombatIconAlpha)
        PlayerAttackBackground:SetAlpha(0)

    --     -- Hide prestige (honor) icon on player unitframe
    --     local prestigeBadgeAlpha = BetterBlizzFramesDB.hidePrestigeBadge and 0 or 1
    --     PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PrestigeBadge:SetAlpha(prestigeBadgeAlpha)
    --     PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PrestigePortrait:SetAlpha(prestigeBadgeAlpha)
    --     TargetFrame.TargetFrameContent.TargetFrameContentContextual.PrestigeBadge:SetAlpha(prestigeBadgeAlpha)
    --     TargetFrame.TargetFrameContent.TargetFrameContentContextual.PrestigePortrait:SetAlpha(prestigeBadgeAlpha)
    --     FocusFrame.TargetFrameContent.TargetFrameContentContextual.PrestigeBadge:SetAlpha(prestigeBadgeAlpha)
    --     FocusFrame.TargetFrameContent.TargetFrameContentContextual.PrestigePortrait:SetAlpha(prestigeBadgeAlpha)

        -- Hide reputation color on target frame (color tint behind name)
        if BetterBlizzFramesDB.hideTargetReputationColor then
            --BBF.SetAlphaRegion(TargetFrameNameBackground)
            BBF.SetTextureColor(TargetFrameNameBackground, 1, 1, 1, 0)
            --TargetFrameNameBackground:Hide()
            --TargetFrameBackground:SetHeight(42)
            -- BBF.HookAndDo(TargetFrameBackground, "SetHeight", function(frame)
            --     frame:SetHeight(42)
            -- end)
            BBF.HookAndDo(TargetFrameBackground, "SetSize", function(frame, width, height, flag)
                -- Custom behavior: Resize the frame
                frame:SetSize(119, 42, flag)
            end)
            TargetFrameBackground:SetSize(119, 42)
        else
            -- TargetFrameNameBackground:Show()
            -- TargetFrameBackground:SetHeight(25)
        end

        -- if BetterBlizzFramesDB.hideFocusReputationColor then
        --     --BBF.SetAlphaRegion(FocusFrameNameBackground)
        --     --BBF.SetTextureColor(FocusFrameNameBackground, 1, 1, 1, 0)
        --     --FocusFrameNameBackground:Hide()

        --     --FocusFrameBackground:SetHeight(42)
        --     --BBF.SetRegionHeight(FocusFrameBackground, 42)
        --     BBF.HookAndDo(FocusFrameBackground, "SetSize", function(frame, width, height, flag)
        --         -- Custom behavior: Resize the frame
        --         frame:SetSize(119, 42, flag)
        --     end)
        --     FocusFrameBackground:SetSize(119, 42)
        -- else
        --     -- FocusFrameNameBackground:Show()
        --     -- FocusFrameBackground:SetHeight(25)
        -- end

        -- -- Hide rest loop animation
        -- if BetterBlizzFramesDB.hidePlayerRestAnimation then
        --     if not originalParents.PlayerRestGlow then
        --         originalParents.PlayerRestGlow = PlayerRestGlow:GetParent()
        --         originalParents.PlayerRestIcon = PlayerRestIcon:GetParent()
        --     end
        --     PlayerRestGlow:SetParent(hiddenFrame)
        --     PlayerRestIcon:SetParent(hiddenFrame)
        -- else
        --     if originalParents.PlayerRestGlow then
        --         PlayerRestGlow:SetParent(originalParents.PlayerRestGlow)
        --         PlayerRestIcon:SetParent(originalParents.PlayerRestIcon)
        --     end
        -- end

        -- -- Hide rested glow on unit frame
        -- if BetterBlizzFramesDB.hidePlayerRestGlow then
        --     if not originalParents.PlayerStatusTexture then
        --         originalParents.PlayerStatusTexture = PlayerStatusTexture:GetParent()
        --     end
        --     PlayerStatusTexture:SetParent(hiddenFrame)
        -- else
        --     if originalParents.PlayerStatusTexture then
        --         PlayerStatusTexture:SetParent(originalParents.PlayerStatusTexture)
        --     end
        -- end

        --ChangeParent(PlayerRestGlow, BetterBlizzFramesDB.hidePlayerRestAnimation)

        --ChangeParent(PlayerRestIcon, BetterBlizzFramesDB.hidePlayerRestAnimation)
        if BetterBlizzFramesDB.hidePlayerRestAnimation then
            local OnShowHookScript = function()
                return function(frame)
                    if not InCombatLockdown() then
                        frame:Hide()
                        PlayerRestIcon:Hide()
                        PlayerRestGlow:Hide()
                    end
                end
            end
            PlayerRestIcon:Hide()
            PlayerStatusGlow:Hide(0)
            if not PlayerStatusGlow.BBFHookHide then
                hooksecurefunc(PlayerStatusGlow, "Show", OnShowHookScript())
                PlayerStatusGlow.BBFHookHide = true
            end
        end
        -- Hide or show rested glow on unit frame
        --ChangeParent(PlayerStatusTexture, BetterBlizzFramesDB.hidePlayerRestGlow)
        if BetterBlizzFramesDB.hidePlayerRestGlow then
            local OnShowHookScript = function()
                return function(frame)
                    if not InCombatLockdown() then
                        frame:Hide()
                    end
                end
            end
            PlayerStatusTexture:SetAlpha(0)
            if not PlayerStatusTexture.BBFHookHide then
                hooksecurefunc(PlayerStatusTexture, "Show", OnShowHookScript())
                PlayerStatusTexture.BBFHookHide = true
                PlayerStatusTexture:Hide()
            end
        end

    --     -- Hide corner icon
    --     if BetterBlizzFramesDB.hidePlayerCornerIcon then
    --         PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon:SetParent(hiddenFrame)
    --     else
    --         PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
    --     end

    --     -- Hide combat glow on player frame
        if BetterBlizzFramesDB.hideCombatGlow then
            PlayerStatusGlow:Hide()
            PlayerStatusTexture:Hide()
            local OnShowHookScript = function()
                return function(frame)
                    PlayerStatusGlow:Hide()
                    PlayerStatusTexture:Hide()
                    --TargetFrameFlash:Hide()
                    --FocusFrameFlash:Hide()
                end
            end

            -- if not TargetFrameFlash.BBFHookHide then
            --     hooksecurefunc(PlayerStatusGlow, "Show", OnShowHookScript())
            --     PlayerStatusGlow.BBFHookHide = true

            --     -- hooksecurefunc(TargetFrameFlash, "Show", OnShowHookScript())
            --     -- TargetFrameFlash.BBFHookHide = true

            --     --hooksecurefunc(FocusFrameFlash, "Show", OnShowHookScript())
            --     --FocusFrameFlash.BBFHookHide = true
            -- end
            --PetFrameFlash:SetParent(hiddenFrame)
            --PetAttackModeTexture:SetParent(hiddenFrame)
        end

    --     -- Hide Player level text
    UpdateLevelTextVisibility(TargetFrameTextureFrameLevelText, "target")
    --UpdateLevelTextVisibility(FocusFrameTextureFrameLevelText, "focus")
    UpdateLevelTextVisibility(PlayerLevelText, "player")


    if BetterBlizzFramesDB.hideLevelTextAlways and not BBF.classicFramesLevelHide then
        local targetTexture = BetterBlizzFramesDB.biggerHealthbars and "Interface\\Addons\\BetterBlizzFrames\\media\\UI-TargetingFrame-NoLevel" or "Interface\\TargetingFrame\\UI-TargetingFrame-NoLevel"
        PlayerFrameTexture:SetTexture(targetTexture)

        if not BetterBlizzFramesDB.biggerHealthbars then
            hooksecurefunc("TargetFrame_CheckClassification" , function(self)
                if self.changing then return end
                if self.borderTexture:GetTexture() == 137026 then
                    self.changing = true
                    self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-NoLevel")
                    self.changing = false
                end
            end)
        end

        BBF.classicFramesLevelHide = true
    end

        -- Hide "Party" text above party raid frames
        if BetterBlizzFramesDB.hidePartyFrameTitle then
            if CompactPartyFrameTitle then
                CompactPartyFrameTitle:Hide()
            end
        else
            if CompactPartyFrameTitle then
                CompactPartyFrameTitle:Show()
            end
        end

        -- Hide PvP Icon
        --ChangeParent(TargetFrameTextureFramePVPIcon, BetterBlizzFramesDB.hidePvpIcon)
        --ChangeParent(PlayerPVPIcon, BetterBlizzFramesDB.hidePvpIcon)
        --ChangeParent(FocusFrameTextureFramePVPIcon, BetterBlizzFramesDB.hidePvpIcon)
        if BetterBlizzFramesDB.hidePvpIcon then
            TargetFrameTextureFramePVPIcon:SetAlpha(0)
            TargetFrameTextureFramePVPIcon:Hide()
            PlayerPVPIcon:SetAlpha(0)
            PlayerPVPIcon:Hide()
            --FocusFrameTextureFramePVPIcon:SetAlpha(0)
            --FocusFrameTextureFramePVPIcon:Hide()
        end


    --     -- Hide role icons
    --     if BetterBlizzFramesDB.hidePlayerRoleIcon then
    --         --PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon:SetParent(hiddenFrame)
    --         PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon:SetAlpha(0)
    --     else
    --         --PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)
    --         PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon:SetAlpha(1)
    --     end

    --     if BetterBlizzFramesDB.hidePlayerGuideIcon then
    --         PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.GuideIcon:SetAlpha(0)
    --     else
    --         PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.GuideIcon:SetAlpha(1)
    --     end

        if BetterBlizzFramesDB.hideRaidFrameManager then
            CompactRaidFrameManager.container:SetIgnoreParentAlpha(true)
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
                    if originalResourceParent then MonkHarmonyBarFrame:SetParent(originalResourceParent) end
                else
                    if not originalResourceParent then originalResourceParent = MonkHarmonyBarFrame:GetParent() end
                    MonkHarmonyBarFrame:SetParent(hiddenFrame)
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

        local function SetChatButtonAlpha(alpha)
            FriendsMicroButton:SetAlpha(alpha)
            ChatFrameChannelButton:SetAlpha(alpha)
            ChatFrameMenuButton:SetAlpha(alpha)
            TextToSpeechButton:SetAlpha(alpha)
            ChatFrame1ButtonFrameUpButton:SetAlpha(alpha)
            ChatFrame1ButtonFrameDownButton:SetAlpha(alpha)
            ChatFrame1ButtonFrameBottomButton:SetAlpha(alpha)
        end

        local function HookChatButton(button)
            button:HookScript("OnEnter", function()
                SetChatButtonAlpha(1)
            end)
            button:HookScript("OnLeave", function()
                C_Timer.After(1, function()
                    if BetterBlizzFramesDB.hideChatButtons then
                        SetChatButtonAlpha(0)
                    end
                end)
            end)
        end

        if BetterBlizzFramesDB.hideChatButtons then
            SetChatButtonAlpha(0)

            if not hookedChatButtons then
                HookChatButton(FriendsMicroButton)
                HookChatButton(ChatFrameChannelButton)
                HookChatButton(ChatFrameMenuButton)
                HookChatButton(TextToSpeechButton)
                HookChatButton(ChatFrame1ButtonFrameUpButton)
                HookChatButton(ChatFrame1ButtonFrameDownButton)
                HookChatButton(ChatFrame1ButtonFrameBottomButton)


                hookedChatButtons = true
            end
        else
            SetChatButtonAlpha(1)
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
        -- if BetterBlizzFramesDB.hideFocusToTDebuffs then
        --     for i = 1, 4 do
        --         local focusToTDebuff = _G["FocusFrameToTDebuff" .. i]
        --         if focusToTDebuff then
        --             focusToTDebuff:SetParent(hiddenFrame)
        --         end
        --     end
        -- end

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
                --UIParent:UnregisterEvent("PING_SYSTEM_ERROR")
                BBF.hidingErrorFrame = true
            end
        end

        -- Hide ToT Frames
        local targetToTAlpha = BetterBlizzFramesDB.hideTargetToT and 0 or 1
        local focusToTAlpha = BetterBlizzFramesDB.hideFocusToT and 0 or 1
        TargetFrameToT:SetAlpha(targetToTAlpha)
        --FocusFrameToT:SetAlpha(focusToTAlpha)

        -- Hide MultiGroupFrame
        if BetterBlizzFramesDB.hideMultiGroupFrame then
            local multiGroupFrame
            for i = 1, PlayerFrame:GetNumChildren() do
                local child = select(i, PlayerFrame:GetChildren())
                if child:IsObjectType("Frame") and child.MultiGroupFrame then
                    multiGroupFrame = child.MultiGroupFrame
                    break
                end
            end

            if multiGroupFrame then
                multiGroupFrame:SetAlpha(0)
            end
        end

        -- Hide Stance Bar
        if BetterBlizzFramesDB.hideStanceBar then
            for i = 1, 10 do
                local buttonName = "StanceButton" .. i
                local button = _G[buttonName]
                if button then
                    ChangeParent(button, BetterBlizzFramesDB.hideStanceBar)
                end
            end
        else
            for i = 1, 10 do
                local buttonName = "StanceButton" .. i
                local button = _G[buttonName]
                if button then
                    ChangeParent(button, BetterBlizzFramesDB.hideStanceBar)
                end
            end
        end

        if BetterBlizzFramesDB.hideRaidFrameContainerBorder then
            local compactPartyBorder = CompactPartyFrameBorderFrame or CompactRaidFrameContainerBorderFrame
            if compactPartyBorder then
                changes.hideRaidFrameContainerBorder = compactPartyBorder:GetParent()
                compactPartyBorder:SetParent(BBF.hiddenFrame)
            end
        elseif changes.hideRaidFrameContainerBorder then
            local compactPartyBorder = CompactPartyFrameBorderFrame or CompactRaidFrameContainerBorderFrame
            compactPartyBorder:SetParent(changes.hideRaidFrameContainerBorder)
            changes.hideRaidFrameContainerBorder = nil
        end


        local function ToggleLibDBIconButtons(show)
            for i = 1, Minimap:GetNumChildren() do
                local child = select(i, Minimap:GetChildren())
                local childName = child:GetName() or ""
                if string.find(childName, "LibDBIcon") or childName == "ExpansionLandingPageMinimapButton" then
                    if show then
                        child:Show()
                        --ExpansionLandingPageMinimapButton:Show()
                        --MiniMapTrackingButton:Show()
                        MiniMapTracking:Show()
                        --MiniMapWorldMapButton:Show()
                    else
                        child:Hide()
                        --ExpansionLandingPageMinimapButton:Hide()
                        --MiniMapTrackingButton:Hide()
                        MiniMapTracking:Hide()
                        --MiniMapWorldMapButton:Hide()
                    end
                end
            end
        end

    --     -- Hide all LibDBIcon buttons by default
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

                -- ExpansionLandingPageMinimapButton:HookScript("OnEnter", function()
                --     iconMouseOver = true
                --     ToggleLibDBIconButtons(true)
                -- end)

                -- ExpansionLandingPageMinimapButton:HookScript("OnLeave", function()
                --     iconMouseOver = false
                --     -- Delay hiding to check if we left the Minimap to another LibDBIcon or completely out
                --     C_Timer.After(0.1, function() 
                --         if not Minimap:IsMouseOver() and not iconMouseOver then
                --             ToggleLibDBIconButtons(false)
                --         end
                --     end)
                -- end)

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

        local function adjustAggroHighlight(framePrefix, startIndex, endIndex)
            for i = startIndex, endIndex do
                local aggroHighlight = _G[framePrefix .. i .. "AggroHighlight"]
                if aggroHighlight then
                    -- Only adjust alpha if it differs from the desired state
                    if aggroHighlight:GetAlpha() ~= aggroAlpha then
                        aggroHighlight:SetAlpha(aggroAlpha)
                    end
                end
            end
        end

        adjustAggroHighlight("CompactRaidFrame", 1, 40)

        for group = 1, 8 do
            for member = 1, 5 do
                local aggroHighlight = _G["CompactRaidGroup" .. group .. "Member" .. member .. "AggroHighlight"]
                if aggroHighlight then
                    -- Only adjust alpha if it differs from the desired state
                    if aggroHighlight:GetAlpha() ~= aggroAlpha then
                        aggroHighlight:SetAlpha(aggroAlpha)
                    end
                end
            end
        end

        adjustAggroHighlight("CompactPartyFrameMember", 1, 5)

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

local TargetLevelHider = CreateFrame("Frame")
TargetLevelHider:SetScript("OnEvent", OnTargetOrFocusChanged)
TargetLevelHider:RegisterEvent("PLAYER_TARGET_CHANGED")
TargetLevelHider:RegisterEvent("PLAYER_FOCUS_CHANGED")

--------------------------------------
-- Hide Party Frames in Arena
--------------------------------------
BBF.changeparent = ChangeParent
local partyAlpha = 1
local partyFrameHider
function BBF.HidePartyInArena()
    -- if BetterBlizzFramesDB.hidePartyFramesInArena and not partyFrameHider then
    --     partyFrameHider = CreateFrame("Frame")

    --     partyFrameHider:SetScript("OnEvent", function(self, event)
    --         -- if event == "PLAYER_ENTERING_BATTLEGROUND" and BetterBlizzFramesDB.hidePartyFramesInArena then
    --         --     partyAlpha = 0
    --         -- elseif event == "PLAYER_ENTERING_WORLD" and IsActiveBattlefieldArena() == false then
    --         --     partyAlpha = 1
    --         -- end
    --         local isInArena = IsActiveBattlefieldArena()
    --         ChangeParent(CompactRaidFrameContainer, isInArena)
    --         if CompactPartyFrame then
    --             ChangeParent(CompactPartyFrame, isInArena)
    --         end
    --         -- ChangeParent(CompactRaidFrame1Background, true)
    --         -- ChangeParent(CompactRaidFrame2Background, IsActiveBattlefieldArena())
    --         -- ChangeParent(CompactRaidFrame3Background, IsActiveBattlefieldArena())
    --         -- CompactRaidFrameContainer:SetParent()
    --         -- PartyFrame:SetAlpha(partyAlpha)
    --         -- PartyMemberBuffTooltip:SetAlpha(partyAlpha)
    --         -- CompactPartyFrameMember1Background:SetAlpha(partyAlpha)
    --         -- CompactPartyFrameMember2Background:SetAlpha(partyAlpha)
    --         -- CompactPartyFrameMember3Background:SetAlpha(partyAlpha)
    --         -- CompactPartyFrameMember1SelectionHighlight:SetAlpha(partyAlpha)
    --         -- CompactPartyFrameMember2SelectionHighlight:SetAlpha(partyAlpha)
    --         -- CompactPartyFrameMember3SelectionHighlight:SetAlpha(partyAlpha)
    --     end)
    --     partyFrameHider:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
    --     partyFrameHider:RegisterEvent("PLAYER_ENTERING_WORLD")
    --     -- if not IsActiveBattlefieldArena() == false then
    --     --     partyAlpha = 0
    --     -- end
    --     local isInArena = IsActiveBattlefieldArena()
    --     ChangeParent(CompactRaidFrameContainer, isInArena)
    --     if CompactPartyFrame then
    --         ChangeParent(CompactPartyFrame, isInArena)
    --     end
    --     -- ChangeParent(CompactRaidFrame1Background, true)
    --     -- ChangeParent(CompactRaidFrame2Background, IsActiveBattlefieldArena())
    --     -- ChangeParent(CompactRaidFrame3Background, IsActiveBattlefieldArena())
    -- elseif BetterBlizzFramesDB.hidePartyFramesInArena and partyFrameHider then
    --     -- if not IsActiveBattlefieldArena() == false then
    --     --     partyAlpha = 0
    --     -- else
    --     --     partyAlpha = 1
    --     -- end
    --     partyFrameHider:UnregisterAllEvents()
    --     partyFrameHider:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
    --     partyFrameHider:RegisterEvent("PLAYER_ENTERING_WORLD")
    --     ChangeParent(CompactRaidFrameContainer, IsActiveBattlefieldArena())
    --     if CompactPartyFrame then
    --         ChangeParent(CompactPartyFrame, IsActiveBattlefieldArena())
    --     end
    -- elseif not BetterBlizzFramesDB.hidePartyFramesInArena then
    --     if partyFrameHider then
    --         partyFrameHider:UnregisterEvent("PLAYER_ENTERING_BATTLEGROUND")
    --         partyFrameHider:UnregisterEvent("PLAYER_ENTERING_WORLD")
    --     end
    --     -- partyAlpha = 1
    --     ChangeParent(CompactRaidFrameContainer, false)
    --     if CompactPartyFrame then
    --         ChangeParent(CompactPartyFrame, false)
    --     end
    -- end
end

--------------------------------------
-- Minimap Hider
--------------------------------------
local minimapStatusChanged

function BBF.MinimapHider()
    local MinimapGroup = Minimap and MinimapCluster
    local QueueStatusEye = QueueStatusButtonIcon
    local ObjectiveTracker = WatchFrame

    local _, instanceType = GetInstanceInfo()
    local inArena = instanceType == "arena"

    local hideMinimap = BetterBlizzFramesDB.hideMinimap
    local hideMinimapAuto = BetterBlizzFramesDB.hideMinimapAuto
    local hideQueueEye = BetterBlizzFramesDB.hideMinimapAutoQueueEye
    local hideObjectives = BetterBlizzFramesDB.hideObjectiveTracker

    local function handleVisibility()
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
        -- if hideQueueEye then
        --     if inArena then
        --         QueueStatusEye:Hide()
        --     else
        --         QueueStatusEye:Show()
        --     end
        -- end

        -- Handle ObjectiveTracker visibility
        -- if hideObjectives then
        --     if inArena then
        --         ObjectiveTracker:Hide()
        --     else
        --         ObjectiveTracker:Show()
        --     end
        -- end
    end

    if InCombatLockdown() then
        -- Check if the event is already registered
        if not BBF.MinimapHiderFrame then
            BBF.MinimapHiderFrame = CreateFrame("Frame")
        end

        if not BBF.MinimapHiderFrame:IsEventRegistered("PLAYER_REGEN_ENABLED") then
            BBF.MinimapHiderFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            BBF.MinimapHiderFrame:SetScript("OnEvent", function(self, event)
                if event == "PLAYER_REGEN_ENABLED" then
                    handleVisibility()
                    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                end
            end)
        end
    else
        handleVisibility()
    end
end