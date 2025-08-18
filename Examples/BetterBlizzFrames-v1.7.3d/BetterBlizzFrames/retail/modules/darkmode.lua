local darkModeUi
local darkModeUiAura
local darkModeColor = 1
local auraFilteringOn
local minimapChanged =false

local hookedTotemBar
local hookedAuras

local function applySettings(frame, desaturate, colorValue, hook, hookShow)
    if frame then
        if desaturate ~= nil and frame.SetDesaturated then
            frame:SetDesaturated(desaturate)
        end

        if frame.SetVertexColor then
            frame:SetVertexColor(colorValue, colorValue, colorValue)
            if hook then
                if not frame.bbfHooked then
                    frame.bbfHooked = true

                    hooksecurefunc(frame, "SetVertexColor", function(self)
                        if self.changing or self:IsProtected() then return end
                        self.changing = true
                        self:SetDesaturated(desaturate)
                        self:SetVertexColor(colorValue, colorValue, colorValue)
                        self.changing = false
                    end)
                end
            end
            -- if hookShow then
            --     if not frame.bbfHookedShow then
            --         frame.bbfHookedShow = true
            --         --hooksecurefunc(UIWidgetPowerBarContainerFrame, "Show", function()
            --             UIWidgetPowerBarContainerFrame:HookScript("OnShow", function()
            --                 frame:SetDesaturated(desaturate)
            --                 frame:SetVertexColor(colorValue, colorValue, colorValue)
            --             end)

            --         --     print("showh")
            --         -- end)
            --     end
            -- end
        end
    end
end

function BBF.UpdateUserDarkModeSettings()
    darkModeUi = BetterBlizzFramesDB.darkModeUi
    darkModeUiAura = BetterBlizzFramesDB.darkModeUiAura
    hookedTotemBar = BetterBlizzFramesDB.hookedTotemBar
    darkModeColor = BetterBlizzFramesDB.darkModeColor
    auraFilteringOn = BetterBlizzFramesDB.playerAuraFiltering
end

local hooked = {}

function BBF.DarkModeUnitframeBorders()
    if BetterBlizzFramesDB.darkModeUiAura and BetterBlizzFramesDB.darkModeUi then
        if not hookedAuras then
            local function styleAuras(self)
                for frame, _ in self.auraPools:EnumerateActive() do
                    if not hooked[frame] then
                        local icon = frame.Icon
                        hooked[frame] = true

                        if not frame.border then
                            local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                            border:SetBackdrop({
                                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                                tileEdge = true,
                                edgeSize = 8.5,
                            })

                            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                            border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1.5, 1.5)
                            border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1.5, -2)
                            frame.border = border

                            border:SetBackdropBorderColor(darkModeColor, darkModeColor, darkModeColor)
                        end

                        if frame.Border then
                            frame.border:Hide()
                        else
                            if frame.Stealable and not frame.Stealable:IsShown() then
                                frame.border:Show()
                            end
                        end
                    else
                        if frame.Border then
                            frame.border:Hide()
                        else
                            --if frame.Stealable and not frame.Stealable:IsShown() then
                                frame.border:Show()
                            --end
                        end
                    end
                end
            end

            hooksecurefunc(TargetFrame, "UpdateAuras", styleAuras)
            hooksecurefunc(FocusFrame, "UpdateAuras", styleAuras)

            hookedAuras = true
        end
    end
end

local function UpdateUnitFrameDarkModeBorderColors(color)
    if not BetterBlizzFramesDB.darkModeColor then return end
    for frame, _ in pairs(hooked) do
        if frame.border then
            frame.border:SetBackdropBorderColor(color, color, color)
        end
    end
end

BBF.auraBorders = {}  -- BuffFrame aura borders for darkmode
local function createOrUpdateBorders(frame, colorValue, textureName, bypass)
    --if not twwrdy then return end
    if BetterBlizzFramesDB.enableMasque and C_AddOns.IsAddOnLoaded("Masque") then return end
    if (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeUiAura) or bypass then
        if not BBF.auraBorders[frame] then
            -- Create borders
            local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            if not bypass then
                border:SetBackdrop({
                    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                    tileEdge = true,
                    edgeSize = 8,
                })
            else
                border:SetBackdrop({
                    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                    tileEdge = true,
                    edgeSize = 10,
                })
            end

            local icon = frame.Icon or frame.icon
            if textureName then
                icon = frame[textureName]
            end
            if not icon then return end
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Adjust the icon

            if not bypass then
                border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1.5, 2)
                border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1.5, -1.5)
            else
                border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
                border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
            end
            border:SetBackdropBorderColor(colorValue, colorValue, colorValue)

            BBF.auraBorders[frame] = border -- Store the border
            if frame.ImportantGlow then
                frame.ImportantGlow:SetParent(border)
                frame.ImportantGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", -15, 16)
                frame.ImportantGlow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 15, -6)
            end
        else
            -- Update border colors
            local border = BBF.auraBorders[frame]
            if border then
                border:SetBackdropBorderColor(colorValue, colorValue, colorValue)
            end
        end
    else
        -- Remove custom borders if they exist and revert the icon
        if BBF.auraBorders[frame] then
            BBF.auraBorders[frame]:Hide()
            BBF.auraBorders[frame]:SetParent(nil) -- Unparent the border
            BBF.auraBorders[frame] = nil -- Remove the reference

            local icon = frame.Icon
            if textureName then
                icon = frame[textureName]
            end
            icon:SetTexCoord(0, 1, 0, 1) -- Revert the icon to the original state
        end
    end
end

function BBF.updateTotemBorders()
    local vertexColor = darkModeUi and BetterBlizzFramesDB.darkModeColor or 1
    for i = 1, TotemFrame:GetNumChildren() do
        local totemButton = select(i, TotemFrame:GetChildren())
        if totemButton and totemButton.Border then
            totemButton.Border:SetDesaturated(true)
            totemButton.Border:SetVertexColor(vertexColor, vertexColor, vertexColor) -- Set to dark color
        end
    end
end

function BBF.DarkmodeFrames(bypass)
    if not bypass and not BetterBlizzFramesDB.darkModeUi then return end

    BBF.AbsorbCaller()
    BBF.CombatIndicatorCaller()

    local desaturationValue = BetterBlizzFramesDB.darkModeUi and true or false
    local vertexColor = BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeColor or 1
    local darkerVertexColor = BetterBlizzFramesDB.darkModeUi and (vertexColor - 0.2) or 1
    local lighterVertexColor = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.3) or 1
    local druidComboPoint = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.2) or 1
    local druidComboPointActive = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.1) or 1
    local actionBarColor = BetterBlizzFramesDB.darkModeActionBars and (vertexColor + 0.15) or 1
    local comboColor = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.15) or 1
    local birdColor = BetterBlizzFramesDB.darkModeActionBars and (vertexColor + 0.25) or 1
    local rogueCombo = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.45) or 1
    local rogueComboActive = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.30) or 1
    local monkChi = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.10) or 1
    local castbarBorder = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.1) or 1
    local color25 = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.25) or 1

    local minimapColor = (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeMinimap) and BetterBlizzFramesDB.darkModeColor or 1
    local minimapSat = (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeMinimap) and true or false
    local tooltipColor = (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeGameTooltip) and BetterBlizzFramesDB.darkModeColor or 1
    local tooltipSat = (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeGameTooltip) and true or false

    local objectiveColor = (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeObjectiveFrame) and BetterBlizzFramesDB.darkModeColor or 1
    local objectiveSat  = (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeObjectiveFrame) and true or false

    local darkModeNpBBP = BetterBlizzPlatesDB and BetterBlizzPlatesDB.darkModeNameplateResource
    local darkModeNp = BetterBlizzFramesDB.darkModeNameplateResource and not darkModeNpBBP
    local darkModeNpSatVal = darkModeNp and desaturationValue or false

    if BetterBlizzFramesDB.darkModeColor == 0 then
        if BetterBlizzFramesDB.darkModeActionBars then
            actionBarColor = 0
            birdColor = 0.07
        end
        rogueCombo = 0.25
        rogueComboActive = 0.15
    end

    if ComboFrame then
        local legacyComboColor = color25
        if BetterBlizzFramesDB.legacyComboColor then
            legacyComboColor = legacyComboColor + BetterBlizzFramesDB.legacyComboColor
        end
        for i = 1, 9 do
            local point = _G["ComboPoint"..i]
            if point and point:GetNumRegions() then
                for j = 1, point:GetNumRegions() do
                    local region = select(j, point:GetRegions())
                    if region and region:IsObjectType("Texture") then
                        local layer = region:GetDrawLayer()
                        if layer == "BACKGROUND" then
                            --region:SetDesaturated(true)
                            region:SetVertexColor(legacyComboColor, legacyComboColor, legacyComboColor)
                        end
                    end
                end
            end
        end
    end

    UpdateUnitFrameDarkModeBorderColors(vertexColor)

    for key, region in pairs(GameTooltip.NineSlice) do
        if key ~= "Center" and type(region) == "table" and (region.SetDesaturated or region.SetVertexColor) then
            applySettings(region, tooltipSat, tooltipColor)
        end
    end
    if BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeGameTooltip and not BBF.hookedTip then
        GameTooltip:HookScript("OnShow", function()
            for key, region in pairs(GameTooltip.NineSlice) do
                if key == "Center" then
                    applySettings(region, tooltipSat, 0)
                end
            end
        end)
        BBF.hookedTip = true
    end

    local aceTooltip = AceConfigDialogTooltip
    if aceTooltip then
        for key, region in pairs(aceTooltip.NineSlice) do
            if key ~= "Center" and type(region) == "table" and (region.SetDesaturated or region.SetVertexColor) then
                applySettings(region, tooltipSat, tooltipColor)
            end
        end
    end

    local function RecolorVigor()
        for _, child in ipairs({UIWidgetPowerBarContainerFrame:GetChildren()}) do
            if child.DecorLeft and child.DecorLeft.GetAtlas then
                local atlasName = child.DecorLeft:GetAtlas()
                if atlasName == "dragonriding_vigor_decor" then
                    applySettings(child.DecorLeft, desaturationValue, druidComboPointActive, true, true)
                    applySettings(child.DecorRight, desaturationValue, druidComboPointActive, true, true)
                end
            end
            for _, grandchild in ipairs({child:GetChildren()}) do
                -- Check for textures with specific atlas names
                if grandchild.Frame and grandchild.Frame.GetAtlas then
                    local atlasName = grandchild.Frame:GetAtlas()
                    if atlasName == "dragonriding_vigor_frame" then
                        applySettings(grandchild.Frame, desaturationValue, druidComboPointActive, true, true)
                    end
                end
            end
        end
    end

    if BetterBlizzFramesDB.darkModeVigor then
        RecolorVigor()
        if not BBF.vigorRecolor then
            BBF.vigorRecolor = CreateFrame("Frame")
            BBF.vigorRecolor:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
            BBF.vigorRecolor:RegisterEvent("PLAYER_ENTERING_WORLD")
            BBF.vigorRecolor:SetScript("OnEvent", function()
                C_Timer.After(0, function()
                    RecolorVigor()
                end)
                C_Timer.After(0.05, function()
                    RecolorVigor()
                end)
            end)
        end
    end

    local function UpdateBorder(frame, colorValue)
        if BBF.auraBorders[frame] then
            if BetterBlizzFramesDB.darkModeUi then
                BBF.auraBorders[frame]:Show()
            else
                BBF.auraBorders[frame]:Hide()
            end
        end
    end

    -- Applying borders to BuffFrame
    if BuffFrame then
        for _, frame in pairs({_G.BuffFrame.AuraContainer:GetChildren()}) do
            createOrUpdateBorders(frame, vertexColor)
        end
    end



    if ToggleHiddenAurasButton then
        createOrUpdateBorders(ToggleHiddenAurasButton, vertexColor)
    end

    BBF.DarkModeUnitframeBorders()


    if BetterBlizzFramesDB.darkModeEliteTexture then
        local v = BetterBlizzFramesDB.darkModeColor + 0.25
        local d = BetterBlizzFramesDB.darkModeEliteTextureDesaturated or false
        applySettings(TargetFrame.TargetFrameContainer.BossPortraitFrameTexture, d, v)
        applySettings(FocusFrame.TargetFrameContainer.BossPortraitFrameTexture, d, v)
    end


    -- Applying settings based on BetterBlizzFramesDB.darkModeUi value
    applySettings(TargetFrame.TargetFrameContainer.FrameTexture, desaturationValue, vertexColor)
    applySettings(TargetFrame.TargetFrameContainer.FrameTextureBBF, desaturationValue, vertexColor)
    applySettings(FocusFrame.TargetFrameContainer.FrameTexture, desaturationValue, vertexColor)
    applySettings(TargetFrame.totFrame.FrameTexture, desaturationValue, vertexColor)
    applySettings(PetFrameTexture, desaturationValue, vertexColor)
    applySettings(FocusFrameToT.FrameTexture, desaturationValue, vertexColor)

    for i = 1, Minimap:GetNumChildren() do
        local child = select(i, Minimap:GetChildren())
        if not child then return end
        for j = 1, child:GetNumRegions() do
            local region = select(j, child:GetRegions())
            if region:IsObjectType("Texture") then
                local texturePath = region:GetTexture()
                if texturePath and string.find(texturePath, "136430") then
                    applySettings(region, minimapSat, minimapColor)
                end
            end
        end
    end


    applySettings(ObjectiveTrackerFrame.Header.Background, objectiveSat, objectiveColor)
    applySettings(CampaignQuestObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(QuestObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(ProfessionsRecipeTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(WorldQuestObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(BonusObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(MonthlyActivitiesObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(AchievementObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(AdventureObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(CampaignQuestObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(UIWidgetObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    applySettings(ScenarioObjectiveTracker.Header.Background, objectiveSat, objectiveColor)
    if WorldQuestTrackerQuestsHeader and WorldQuestTrackerQuestsHeader.Background then
        applySettings(WorldQuestTrackerQuestsHeader.Background, objectiveSat, objectiveColor)
    end









    --Minimap + and - zoom buttons
    local zoomOutButton = MinimapCluster.MinimapContainer.Minimap.ZoomOut
    local zoomInButton = MinimapCluster.MinimapContainer.Minimap.ZoomIn

    -- Desaturate all textures in ZoomOut button
    for i = 1, zoomOutButton:GetNumRegions() do
        local region = select(i, zoomOutButton:GetRegions())
        if region:IsObjectType("Texture") then
            applySettings(region, minimapSat, minimapColor)
        end
    end

    for i = 1, 8 do
        local frame = _G["CompactRaidGroup"..i.."BorderFrame"]
        if frame then
            for j = 1, frame:GetNumRegions() do
                local region = select(j, frame:GetRegions())
                if region:IsObjectType("Texture") then
                    applySettings(region, desaturationValue, vertexColor)
                end
            end
        end

        for j = 1,5 do
            local memberFrame = _G["CompactRaidGroup"..i.."Member"..j]
            if memberFrame then
                applySettings(memberFrame.horizDivider, desaturationValue, vertexColor)
                applySettings(memberFrame.horizTopBorder, desaturationValue, vertexColor)
                applySettings(memberFrame.horizBottomBorder, desaturationValue, vertexColor)
                applySettings(memberFrame.vertLeftBorder, desaturationValue, vertexColor)
                applySettings(memberFrame.vertRightBorder, desaturationValue, vertexColor)
            end
        end
    end

    local fixBackground = false
    if fixBackground then -- check for resets
        for i = 1, 8 do
            for j = 1,5 do
                local f = _G["CompactRaidGroup"..i.."Member"..j.."Background"]
                if f then
                    local _,_,top,bottom = f:GetTexCoord()
                    f:SetTexCoord(0.05, 0.95, top, bottom)
                end
            end
        end
    end

    local compactPartyBorder = CompactPartyFrameBorderFrame or CompactRaidFrameContainerBorderFrame
    if compactPartyBorder then
        for i = 1, compactPartyBorder:GetNumRegions() do
            local region = select(i, compactPartyBorder:GetRegions())
            if region:IsObjectType("Texture") then
                applySettings(region, desaturationValue, vertexColor)
            end
        end
        for i = 1, 40 do
            local frame = _G["CompactRaidFrame"..i]
            if frame then
                applySettings(frame.horizDivider, desaturationValue, vertexColor)
                applySettings(frame.horizTopBorder, desaturationValue, vertexColor)
                applySettings(frame.horizBottomBorder, desaturationValue, vertexColor)
                applySettings(frame.vertLeftBorder, desaturationValue, vertexColor)
                applySettings(frame.vertRightBorder, desaturationValue, vertexColor)
            end
            
        end
        for i = 1, 5 do
            local frame = _G["CompactPartyFrameMember"..i]
            if frame then
                applySettings(frame.horizDivider, desaturationValue, vertexColor)
                applySettings(frame.horizTopBorder, desaturationValue, vertexColor)
                applySettings(frame.horizBottomBorder, desaturationValue, vertexColor)
                applySettings(frame.vertLeftBorder, desaturationValue, vertexColor)
                applySettings(frame.vertRightBorder, desaturationValue, vertexColor)
            end
        end
    end

    -- Desaturate all textures in ZoomIn button
    for i = 1, zoomInButton:GetNumRegions() do
        local region = select(i, zoomInButton:GetRegions())
        if region:IsObjectType("Texture") then
            applySettings(region, minimapSat, minimapColor)
        end
    end

    if BetterBlizzFramesDB.darkModeUiAura then
        local BuffFrameButton = BuffFrame.CollapseAndExpandButton
        for i = 1, BuffFrameButton:GetNumRegions() do
            local region = select(i, BuffFrameButton:GetRegions())
            if region:IsObjectType("Texture") then
                applySettings(region, desaturationValue, 0.2)
            end
        end
    end

    applySettings(MinimapCompassTexture, minimapSat, minimapColor)

    for i = 1, ExpansionLandingPageMinimapButton:GetNumRegions() do
        local region = select(i, ExpansionLandingPageMinimapButton:GetRegions())
        if region:IsObjectType("Texture") then
            applySettings(region, minimapSat, minimapColor)
        end
    end

    --castbars
    if BetterBlizzFramesDB.darkModeCastbars then
        BBF.darkModeCastbars = true
        local skip = BetterBlizzFramesDB.classicCastbars
        applySettings(TargetFrame.spellbar.Border, desaturationValue, castbarBorder)
        --applySettings(TargetFrame.spellbar.BorderShield, desaturationValue, vertexColor)

        applySettings(FocusFrame.spellbar.Border, desaturationValue, castbarBorder)
        --applySettings(FocusFrame.spellbar.BorderShield, desaturationValue, vertexColor)
        if not skip then
            applySettings(FocusFrame.spellbar.Background, desaturationValue, lighterVertexColor)
            applySettings(TargetFrame.spellbar.Background, desaturationValue, lighterVertexColor)
        end
        if not BetterBlizzFramesDB.classicCastbarsPlayer then
            applySettings(PlayerCastingBarFrame.Background, desaturationValue, lighterVertexColor)
        end
        applySettings(PlayerCastingBarFrame.Border, desaturationValue, castbarBorder)
        --applySettings(PlayerCastingBarFrame.BorderShield, desaturationValue, vertexColor)
        
    elseif BBF.darkModeCastbars then
        applySettings(TargetFrame.spellbar.Border, false, 1)
        --applySettings(TargetFrame.spellbar.BorderShield, desaturationValue, vertexColor)
        applySettings(TargetFrame.spellbar.Background, false, 1)

        applySettings(FocusFrame.spellbar.Border, false, 1)
        --applySettings(FocusFrame.spellbar.BorderShield, desaturationValue, vertexColor)
        applySettings(FocusFrame.spellbar.Background, false, 1)

        applySettings(PlayerCastingBarFrame.Border, false, 1)
        --applySettings(PlayerCastingBarFrame.BorderShield, desaturationValue, vertexColor)
        applySettings(PlayerCastingBarFrame.Background, false, 1)
        BBF.darkModeCastbars = nil
    end




    applySettings(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon, desaturationValue, vertexColor)

    for _, v in pairs({
        PlayerFrame.PlayerFrameContainer.FrameTexture,
        PlayerFrame.PlayerFrameContainer.FrameTextureBBF,
        PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture,
        PlayerFrame.PlayerFrameContainer.VehicleFrameTexture,
        PartyFrame.MemberFrame1.Texture,
        PartyFrame.MemberFrame2.Texture,
        PartyFrame.MemberFrame3.Texture,
        PartyFrame.MemberFrame4.Texture,
        PaladinPowerBarFrame.Background,
        PaladinPowerBarFrame.ActiveTexture,
        PlayerFrameGroupIndicatorLeft,
        PlayerFrameGroupIndicatorRight,
        PlayerFrameGroupIndicatorMiddle
    }) do
        applySettings(v, desaturationValue, vertexColor)
    end
    for _, v in pairs({
        PlayerFrameAlternateManaBarLeftBorder,
        PlayerFrameAlternateManaBarRightBorder,
        PlayerFrameAlternateManaBarBorder,
    }) do
        applySettings(v, false, vertexColor)  -- Only applying vertex color, desaturation is kept false
    end

    if PlayerFrame.AltManaBarBBF then
        for _, v in pairs({
            PlayerFrame.AltManaBarBBF.Border,
            PlayerFrame.AltManaBarBBF.LeftBorder,
            PlayerFrame.AltManaBarBBF.RightBorder
        }) do
            applySettings(v, desaturationValue, darkerVertexColor)
        end
    end

    for _, v in pairs({
        AlternatePowerBar.Border,
        AlternatePowerBar.LeftBorder,
        AlternatePowerBar.RightBorder
    }) do
        applySettings(v, desaturationValue, darkerVertexColor)
    end

    local runes = _G.RuneFrame
    if runes then
        for i = 1, 6 do
            applySettings(runes["Rune" .. i].BG_Active, desaturationValue, vertexColor)
            applySettings(runes["Rune" .. i].BG_Inactive, desaturationValue, vertexColor)
        end
    end

    local nameplateRunes = _G.DeathKnightResourceOverlayFrame
    if nameplateRunes and not nameplateRunes:IsForbidden() and not darkModeNpBBP then
        local dkNpRunes = darkModeNp and vertexColor or 1
        for i = 1, 6 do
            applySettings(nameplateRunes["Rune" .. i].BG_Active, darkModeNpSatVal, dkNpRunes)
            applySettings(nameplateRunes["Rune" .. i].BG_Inactive, darkModeNpSatVal, dkNpRunes)
        end
    end

    local soulShards = _G.WarlockPowerFrame
    if soulShards then
        for _, v in pairs({soulShards:GetChildren()}) do
            applySettings(v.Background, desaturationValue, druidComboPointActive)
        end
    end

    local actionbarsplits = _G.MainMenuBar
    if actionbarsplits then
        for _, v in pairs({actionbarsplits:GetChildren()}) do
            applySettings(v.TopEdge, desaturationValue, actionBarColor)
            applySettings(v.BottomEdge, desaturationValue, actionBarColor)
            applySettings(v.Center, desaturationValue, actionBarColor)
        end
    end

    local soulShardsNameplate = _G.ClassNameplateBarWarlockFrame
    if soulShardsNameplate and not soulShardsNameplate:IsForbidden() and not darkModeNpBBP then
        local soulShardNp = darkModeNp and vertexColor or 1
        for _, v in pairs({soulShardsNameplate:GetChildren()}) do
            applySettings(v.Background, darkModeNpSatVal, soulShardNp)
        end
    end

    if select(2, UnitClass("player")) == "DRUID" then
        local function updateComboPointTextures()
            local druidComboPoints = _G.DruidComboPointBarFrame
            if druidComboPoints then
                for _, v in pairs({druidComboPoints:GetChildren()}) do
                    applySettings(v.BG_Inactive, desaturationValue, druidComboPoint, true)
                    applySettings(v.BG_Active, desaturationValue, druidComboPointActive, true)
                    if BetterBlizzFramesDB.druidOverstacks then
                        applySettings(v.ChargedFrameActive, desaturationValue, druidComboPointActive, true)
                    end
                end
            end
        end
        if GetShapeshiftFormID() == 1 then
            -- Already in cat form, run immediately
            updateComboPointTextures()
        else
            -- Not in cat form, wait for it
            if not BBF.CatFormWatcher then
                local f = CreateFrame("Frame")
                f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
                f:SetScript("OnEvent", function(self)
                    if GetShapeshiftFormID() == 1 then
                        updateComboPointTextures()
                        self:UnregisterAllEvents()
                        self:SetScript("OnEvent", nil)
                    end
                end)
                BBF.CatFormWatcher = f
            end
        end
    end

    if PlayerFrame.PlayerFrameContainer.PlayerElite then
        if BetterBlizzFramesDB.playerEliteFrameDarkmode then
            PlayerFrame.PlayerFrameContainer.PlayerElite:SetVertexColor(color25,color25,color25)
        else
            PlayerFrame.PlayerFrameContainer.PlayerElite:SetVertexColor(1,1,1)
        end
    end

    local druidComboPointsNameplate = _G.ClassNameplateBarFeralDruidFrame
    if druidComboPointsNameplate and not druidComboPointsNameplate:IsForbidden() and not darkModeNpBBP then
        local druidComboPointNp = darkModeNp and druidComboPoint or 1
        local druidComboPointActiveNp = darkModeNp and druidComboPointActive or 1
        for _, v in pairs({druidComboPointsNameplate:GetChildren()}) do
            applySettings(v.BG_Inactive, darkModeNpSatVal, druidComboPointNp)
            applySettings(v.BG_Active, darkModeNpSatVal, druidComboPointActiveNp)
        end
    end

    local mageArcaneCharges = _G.MageArcaneChargesFrame
    if mageArcaneCharges then
        for _, v in pairs({mageArcaneCharges:GetChildren()}) do
            applySettings(v.ArcaneBG, desaturationValue, comboColor)
            --applySettings(v.BG_Active, desaturationValue, druidComboPointActive)
        end
    end

    local mageArcaneChargesNameplate = _G.ClassNameplateBarMageFrame
    if mageArcaneChargesNameplate and not mageArcaneChargesNameplate:IsForbidden() and not darkModeNpBBP then
        local mageChargeNp = darkModeNp and comboColor or 1
        for _, v in pairs({mageArcaneChargesNameplate:GetChildren()}) do
            applySettings(v.ArcaneBG, darkModeNpSatVal, mageChargeNp)
            --applySettings(v.BG_Active, desaturationValue, druidComboPointActive)
        end
    end

    local monkChiPoints = _G.MonkHarmonyBarFrame
    if monkChiPoints then
        for _, v in pairs({monkChiPoints:GetChildren()}) do
            applySettings(v.Chi_BG, desaturationValue, monkChi)
            applySettings(v.Chi_BG_Active, desaturationValue, monkChi)
        end
    end

    local monkChiPointsNameplate = _G.ClassNameplateBarWindwalkerMonkFrame
    if monkChiPointsNameplate and not monkChiPointsNameplate:IsForbidden() and not darkModeNpBBP then
        local monkChiNp = darkModeNp and monkChi or 1
        for _, v in pairs({monkChiPointsNameplate:GetChildren()}) do
            applySettings(v.Chi_BG, darkModeNpSatVal, monkChiNp)
            applySettings(v.Chi_BG_Active, darkModeNpSatVal, monkChiNp)
        end
    end

    local rogueComboPoints = _G.RogueComboPointBarFrame
    if rogueComboPoints then
        for _, v in pairs({rogueComboPoints:GetChildren()}) do
            applySettings(v.BGInactive, desaturationValue, rogueCombo)
            applySettings(v.BGActive, desaturationValue, rogueComboActive)
        end
    end

    local rogueComboPointsNameplate = _G.ClassNameplateBarRogueFrame
    if rogueComboPointsNameplate and not rogueComboPointsNameplate:IsForbidden() and not darkModeNpBBP then
        local rogueComboNp = darkModeNp and rogueCombo or 1
        local rogueComboActiveNp = darkModeNp and rogueComboActive or 1
        for _, v in pairs({rogueComboPointsNameplate:GetChildren()}) do
            applySettings(v.BGInactive, darkModeNpSatVal, rogueComboNp)
            applySettings(v.BGActive, darkModeNpSatVal, rogueComboActiveNp)
        end
    end


    -- PaladinPowerBarFrame.Background,
    -- PaladinPowerBarFrame.ActiveTexture,


    local paladinHolyPowerNameplate = _G.ClassNameplateBarPaladinFrame
    if paladinHolyPowerNameplate and not paladinHolyPowerNameplate:IsForbidden() and not darkModeNpBBP then
        local palaPowerNp = darkModeNp and vertexColor or 1
        applySettings(ClassNameplateBarPaladinFrame.Background, darkModeNpSatVal, palaPowerNp)
        applySettings(ClassNameplateBarPaladinFrame.ActiveTexture, darkModeNpSatVal, palaPowerNp)
    end

    local evokerEssencePoints = _G.EssencePlayerFrame
    if evokerEssencePoints then
        for _, v in pairs({evokerEssencePoints:GetChildren()}) do
            if v.EssenceFillDone and v.EssenceFillDone.CircBG then
                applySettings(v.EssenceFillDone.CircBG, desaturationValue, monkChi)
            end
            if v.EssenceFilling and v.EssenceFilling.EssenceBG then
                applySettings(v.EssenceFilling.EssenceBG, desaturationValue, vertexColor)
            end
            if v.EssenceEmpty and v.EssenceEmpty.EssenceBG then
                applySettings(v.EssenceEmpty.EssenceBG, desaturationValue, vertexColor)
            end
            if v.EssenceFillDone and v.EssenceFillDone.CircBGActive then
                applySettings(v.EssenceFillDone.CircBGActive, desaturationValue, vertexColor)
            end
            if v.EssenceDepleting and v.EssenceDepleting.EssenceBG then
                applySettings(v.EssenceDepleting.EssenceBG, desaturationValue, vertexColor)
            end
            if v.EssenceDepleting and v.EssenceDepleting.CircBGActive then
                applySettings(v.EssenceDepleting.CircBGActive, desaturationValue, vertexColor)
            end
            if v.EssenceFillDone and v.EssenceFillDone.RimGlow then
                applySettings(v.EssenceFillDone.RimGlow, desaturationValue, monkChi)
            end
            if v.EssenceDepleting and v.EssenceDepleting.RimGlow then
                applySettings(v.EssenceDepleting.RimGlow, desaturationValue, monkChi)
            end
        end
    end

    local evokerEssencePointsNameplate = _G.ClassNameplateBarDracthyrFrame
    if evokerEssencePointsNameplate and not evokerEssencePointsNameplate:IsForbidden() and not darkModeNpBBP then
        local evokerColorOne = darkModeNp and monkChi or 1
        local evokerColorTwo = darkModeNp and vertexColor or 1
        for _, v in pairs({evokerEssencePointsNameplate:GetChildren()}) do
            if v.EssenceFillDone and v.EssenceFillDone.CircBG then
                applySettings(v.EssenceFillDone.CircBG, darkModeNpSatVal, evokerColorOne)
            end
            if v.EssenceFilling and v.EssenceFilling.EssenceBG then
                applySettings(v.EssenceFilling.EssenceBG, darkModeNpSatVal, evokerColorTwo)
            end
            if v.EssenceEmpty and v.EssenceEmpty.EssenceBG then
                applySettings(v.EssenceEmpty.EssenceBG, darkModeNpSatVal, evokerColorTwo)
            end
            if v.EssenceFillDone and v.EssenceFillDone.CircBGActive then
                applySettings(v.EssenceFillDone.CircBGActive, darkModeNpSatVal, evokerColorTwo)
            end
            if v.EssenceDepleting and v.EssenceDepleting.EssenceBG then
                applySettings(v.EssenceDepleting.EssenceBG, darkModeNpSatVal, evokerColorTwo)
            end
            if v.EssenceDepleting and v.EssenceDepleting.CircBGActive then
                applySettings(v.EssenceDepleting.CircBGActive, darkModeNpSatVal, evokerColorTwo)
            end
            if v.EssenceFillDone and v.EssenceFillDone.RimGlow then
                applySettings(v.EssenceFillDone.RimGlow, darkModeNpSatVal, evokerColorOne)
            end
            if v.EssenceDepleting and v.EssenceDepleting.RimGlow then
                applySettings(v.EssenceDepleting.RimGlow, darkModeNpSatVal, evokerColorOne)
            end
        end
    end

    -- Actionbars
    for i = 1, 12 do
        applySettings(_G["ActionButton" .. i .. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["MultiBarBottomLeftButton" .. i .. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["MultiBarBottomRightButton" ..i.. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["MultiBarRightButton" ..i.. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["MultiBarLeftButton" ..i.. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["MultiBar5Button" ..i.. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["MultiBar6Button" ..i.. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["MultiBar7Button" ..i.. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["PetActionButton" ..i.. "NormalTexture"], desaturationValue, actionBarColor, true)
        applySettings(_G["StanceButton" ..i.. "NormalTexture"], desaturationValue, actionBarColor, true)
    end

    applySettings(StatusTrackingBarManager.MainStatusTrackingBarContainer.BarFrameTexture, desaturationValue, actionBarColor)
    applySettings(StatusTrackingBarManager.SecondaryStatusTrackingBarContainer.BarFrameTexture, desaturationValue, actionBarColor)

    for _, v in pairs({
        MainMenuBar.BorderArt,
        ActionButton1.RightDivider,
        ActionButton2.RightDivider,
        ActionButton3.RightDivider,
        ActionButton4.RightDivider,
        ActionButton5.RightDivider,
        ActionButton6.RightDivider,
        ActionButton7.RightDivider,
        ActionButton8.RightDivider,
        ActionButton9.RightDivider,
        ActionButton10.RightDivider,
        ActionButton11.RightDivider,
    }) do
        applySettings(v, desaturationValue, actionBarColor, true)
    end

    for _, v in pairs({
        MainMenuBar.EndCaps.LeftEndCap,
        MainMenuBar.EndCaps.RightEndCap,
    }) do
        applySettings(v, desaturationValue, birdColor, true)
    end

    local BARTENDER4_NUM_MAX_BUTTONS = 180
    for i = 1, BARTENDER4_NUM_MAX_BUTTONS do
        local button = _G["BT4Button" .. i]
        if button then
            local normalTexture = button:GetNormalTexture()
            if normalTexture then
                applySettings(normalTexture, desaturationValue, actionBarColor)
            end
        end
    end

    if BlizzardArtTex0 then
        for i = 0, 3 do
            local texture = _G["BlizzardArtTex"..i]
            if texture then
                applySettings(texture, desaturationValue, actionBarColor)
            end
        end
    end

    local BARTENDER4_PET_BUTTONS = 10
    for i = 1, BARTENDER4_PET_BUTTONS do
        local button = _G["BT4PetButton" .. i]
        if button then
            local normalTexture = button:GetNormalTexture()
            if normalTexture then
                applySettings(normalTexture, desaturationValue, actionBarColor)
            end
        end
    end

    if BT4BarBlizzardArt and BT4BarBlizzardArt.nineSliceParent then
        for _, child in ipairs({BT4BarBlizzardArt.nineSliceParent:GetChildren()}) do
            applySettings(child, desaturationValue, actionBarColor)
            local DividerArt = child:GetChildren()
            applySettings(DividerArt, desaturationValue, actionBarColor)
        end
        --for _, child in ipairs({BT4BarBlizzardArt:GetChildren()}) do
            --applySettings(child, desaturationValue, lighterVertexColor)
        --end
    end

    -- Dominos actionbars
    local NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS
    local DOMINOS_NUM_MAX_BUTTONS = 14 * NUM_ACTIONBAR_BUTTONS
    local actionBars = {
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

    -- Loop through each bar and apply settings to its buttons
    for _, bar in ipairs(actionBars) do
        for i = 1, bar.count do
            local button = _G[bar.name .. i]
            if button then
                local normalTexture = button:GetNormalTexture()
                if normalTexture then
                    applySettings(normalTexture, desaturationValue, actionBarColor)
                end
            end
        end
    end

    for _, v in pairs({BlizzardArtLeftCap, BlizzardArtRightCap}) do
        if v then
            applySettings(v, desaturationValue, birdColor)
        end
    end

    if not hookedTotemBar and darkModeUi then
        hooksecurefunc(TotemFrame, "Update", function()
            BBF.updateTotemBorders()
        end)
        hookedTotemBar = true
    end

    BBF.DarkModeActive = true
end




function BBF.UpdateFilteredBuffsIcon()
    if BetterBlizzFramesDB.enableMasque then return end
    if BetterBlizzFramesDB.darkModeUi then
        local vertexColor = BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeColor or 1
        if ToggleHiddenAurasButton then
            createOrUpdateBorders(ToggleHiddenAurasButton, vertexColor)
        end
    end
end


local specChangeListener = CreateFrame("Frame")
specChangeListener:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
specChangeListener:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if BetterBlizzFramesDB.darkModeUi then
            local unitID = ...
            if unitID == "player" then
                local playerClass = select(2, UnitClass("player"))
                local vertexColor = BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeColor or 1
                local desaturationValue = BetterBlizzFramesDB.darkModeUi

                if playerClass == "ROGUE" then
                    local rogueCombo = vertexColor + 0.45
                    local rogueComboActive = vertexColor + 0.30
                    local rogueComboPoints = _G.RogueComboPointBarFrame
                    if BetterBlizzFramesDB.darkModeColor == 0 then
                        rogueCombo = 0.25
                        rogueComboActive = 0.15
                    end
                    if rogueComboPoints then
                        for _, v in pairs({rogueComboPoints:GetChildren()}) do
                            applySettings(v.BGInactive, desaturationValue, rogueCombo)
                            applySettings(v.BGActive, desaturationValue, rogueComboActive)
                        end
                    end
                elseif playerClass == "MONK" then
                    local monkChi = vertexColor + 0.10
                    local monkChiPoints = _G.MonkHarmonyBarFrame
                    if monkChiPoints then
                        for _, v in pairs({monkChiPoints:GetChildren()}) do
                            applySettings(v.Chi_BG, desaturationValue, monkChi)
                            applySettings(v.Chi_BG_Active, desaturationValue, monkChi)
                        end
                    end
                end
            end
        end
    end
end)

function BBF.CheckForAuraBorders()
    if BetterBlizzFramesDB.enableMasque then return end
    if not (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeUiAura) then
        local frames = {_G.BuffFrame.AuraContainer:GetChildren()}

        for _, frame in ipairs(frames) do
            local iconTexture
            for i = 1, frame:GetNumChildren() do
                local child = select(i, frame:GetChildren())

                local bottomEdgeTexture = child.BottomEdge
                if bottomEdgeTexture and bottomEdgeTexture:IsObjectType("Texture") then
                    local r, g, b, a = bottomEdgeTexture:GetVertexColor()
                    local borderColorValue = r

                    iconTexture = frame.Icon
                    if iconTexture and borderColorValue then
                        if ToggleHiddenAurasButton then
                            ToggleHiddenAurasButton.Icon:SetTexCoord(iconTexture:GetTexCoord())
                            createOrUpdateBorders(ToggleHiddenAurasButton, borderColorValue, nil, true)
                            return
                        end
                    end
                end
            end
        end
    end
end