local function AdjustFramePoint(frame, xOffset, yOffset)
    if not frame._storedPoint then
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
        frame._storedPoint = point
        frame._storedRelativeTo = relativeTo
        frame._storedRelativePoint = relativePoint
        frame._storedXOfs = xOfs
        frame._storedYOfs = yOfs
    end
    frame:SetPoint(frame._storedPoint, frame._storedRelativeTo, frame._storedRelativePoint, frame._storedXOfs + (xOffset or 0), frame._storedYOfs + (yOffset or 0))
end

local function SetXYPoint(frame, xOffset, yOffset)
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    frame:SetPoint(point, relativeTo, relativePoint, xOffset or xOfs, yOffset or yOfs)
end

local class = select(2, UnitClass("player"))
local defaultTex = "Interface\\TargetingFrame\\UI-TargetingFrame"
local noLvlTex = "Interface\\TargetingFrame\\UI-FocusFrame-Large"
local flashTex = "Interface\\TargetingFrame\\UI-TargetingFrame-Flash"
local flashNoLvl = "Interface\\TargetingFrame\\UI-FocusFrame-Large-Flash"

local function MakeClassicFrame(frame)
    local db = BetterBlizzFramesDB
    local hideLvl = db.hideLevelText
    local alwaysHideLvl = hideLvl and db.hideLevelTextAlways
    local hideDragon = db.hideRareDragonTexture

    local ClassResourceFrames = {
        ROGUE      = RogueComboPointBarFrame,
        DRUID      = DruidComboPointBarFrame,
        WARLOCK    = WarlockPowerFrame,
        MAGE       = MageArcaneChargesFrame,
        MONK       = MonkHarmonyBarFrame,
        EVOKER     = EssencePlayerFrame,
        PALADIN    = PaladinPowerBarFrame,
        DEATHKNIGHT = RuneFrame,
    }
    local classFrame = ClassResourceFrames[class]

    if frame == TargetFrame or frame == FocusFrame then
        -- Frame
        local content = frame.TargetFrameContent
        local frameContainer = frame.TargetFrameContainer
        local contentMain = content.TargetFrameContentMain
        local contentContext = content.TargetFrameContentContextual

        -- Status
        local hpContainer = contentMain.HealthBarsContainer
        local manaBar = contentMain.ManaBar

        frame.ClassicFrame = CreateFrame("Frame")
        frame.ClassicFrame:SetParent(frame)
        frame.ClassicFrame:SetFrameStrata("HIGH")
        frame.ClassicFrame:SetAllPoints(frame)
        frame.ClassicFrame.Texture = frame.ClassicFrame:CreateTexture(nil, "OVERLAY")
        frame.ClassicFrame.Texture:SetParent(frame.ClassicFrame)
        frame.ClassicFrame.Texture:SetSize(232, 100)
        frame.ClassicFrame.Texture:SetTexCoord(0.09375, 1, 0, 0.78125)
        frame.ClassicFrame.Texture:SetPoint("TOPLEFT", 20, -8)

        frame.bbfName:SetParent(frame.ClassicFrame)
        frame.ClassicFrame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.ClassicFrame.Background:SetColorTexture(0,0,0,0.45)
        frame.ClassicFrame.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 3, 9)
        frame.ClassicFrame.Background:SetPoint("BOTTOMRIGHT", contentMain.ManaBar, "BOTTOMRIGHT", -7, 0)

        local function GetFrameColor()
            local r,g,b = frameContainer.FrameTexture:GetVertexColor()
            frame.ClassicFrame.Texture:SetVertexColor(r,g,b)
        end
        GetFrameColor()
        hooksecurefunc(frameContainer.FrameTexture, "SetVertexColor", GetFrameColor)

        hpContainer.LeftText:SetParent(frame.ClassicFrame)
        hpContainer.LeftText:ClearAllPoints()
        hpContainer.LeftText:SetPoint("LEFT", frame.ClassicFrame.Texture, "LEFT", 7, 2.8)
        hpContainer.RightText:SetParent(frame.ClassicFrame)
        hpContainer.RightText:ClearAllPoints()
        hpContainer.RightText:SetPoint("RIGHT", frame.ClassicFrame.Texture, "RIGHT", -108, 2.8)
        hpContainer.HealthBarText:SetParent(frame.ClassicFrame)
        hpContainer.HealthBarText:ClearAllPoints()
        hpContainer.HealthBarText:SetPoint("CENTER", frame.ClassicFrame.Texture, "LEFT", 66, 2.8)
        hpContainer.DeadText:SetParent(frame.ClassicFrame)
        hpContainer.DeadText:ClearAllPoints()
        hpContainer.DeadText:SetPoint("CENTER", frame.ClassicFrame.Texture, "LEFT", 66, 2.8)
        AdjustFramePoint(hpContainer.HealthBar.OverAbsorbGlow, -7)

        manaBar.LeftText:SetParent(frame.ClassicFrame)
        manaBar.LeftText:ClearAllPoints()
        manaBar.LeftText:SetPoint("LEFT", frame.ClassicFrame.Texture, "LEFT", 7, -8.5)
        manaBar.RightText:SetParent(frame.ClassicFrame)
        manaBar.RightText:ClearAllPoints()
        manaBar.RightText:SetPoint("RIGHT", frame.ClassicFrame.Texture, "RIGHT", -108, -8.5)
        manaBar.ManaBarText:SetParent(frame.ClassicFrame)
        manaBar.ManaBarText:ClearAllPoints()
        manaBar.ManaBarText:SetPoint("CENTER", frame.ClassicFrame.Texture, "LEFT", 66, -8.5)

        contentContext:SetParent(frame.ClassicFrame)
        contentContext.HighLevelTexture:ClearAllPoints()
        contentContext.HighLevelTexture:SetPoint("CENTER", frame, "BOTTOMRIGHT", -34, 25)
        contentContext.PetBattleIcon:ClearAllPoints()
        contentContext.PetBattleIcon:SetPoint("CENTER", frame, "BOTTOMRIGHT", -35, 25)
        contentContext.PrestigePortrait:ClearAllPoints()
        contentContext.PrestigePortrait:SetPoint("TOPRIGHT", 5, -17)
        contentContext.LeaderIcon:ClearAllPoints()
        contentContext.LeaderIcon:SetPoint("TOPRIGHT", -84, -13.5)
        contentContext.GuideIcon:ClearAllPoints()
        contentContext.GuideIcon:SetPoint("TOPRIGHT", -20, -14)
        contentContext.RaidTargetIcon:ClearAllPoints()
        contentContext.RaidTargetIcon:SetPoint("CENTER", frameContainer.Portrait, "TOP", 1.5, 1)

        AdjustFramePoint(frameContainer.Portrait, nil, -4)

        contentMain.LevelText:SetParent(frame.ClassicFrame)
        contentMain.LevelText:ClearAllPoints()
        contentMain.LevelText:SetPoint("CENTER", frame, "BOTTOMRIGHT", -34, 25.5)
        contentMain.ReputationColor:SetSize(119, 18)
        contentMain.ReputationColor:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
        contentMain.ReputationColor:ClearAllPoints()
        contentMain.ReputationColor:SetPoint("TOPRIGHT", -87, -31)

        -- if true then
        --     contentMain.ReputationColor:SetSize(121, 18)
        --     contentMain.ReputationColor:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health-Status")

        --     hooksecurefunc(contentMain.ReputationColor, "SetVertexColor", function(self)
        --         if self.changing then return end
        --         self.changing = true
        --         local r,g,b = self:GetVertexColor()
        --         if g == 1 then
        --             self:SetVertexColor(1,1,1)
        --             self:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health")
        --         else
        --             self:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Bar-Health-Status")
        --         end
        --         self.changing = false
        --     end)
        -- end

        frameContainer.Flash:SetDrawLayer("BACKGROUND")
        frameContainer.Flash:SetParent(db.hideCombatGlow and BBF.hiddenFrame or frame)
        frameContainer.Portrait:SetSize(62,62)
        frameContainer.Portrait:ClearAllPoints()
        frameContainer.Portrait:SetPoint("TOPRIGHT", -23, -22)
        frameContainer.PortraitMask:SetSize(61,61)
        frameContainer.PortraitMask:ClearAllPoints()
        frameContainer.PortraitMask:SetPoint("CENTER", frameContainer.Portrait, "CENTER", 0, 0)
        frameContainer.BossPortraitFrameTexture:SetAlpha(0)


        -- frameContainer.PlayerPortrait:SetSize(62, 62)
        -- frameContainer.PlayerPortrait:ClearAllPoints()
        -- frameContainer.PlayerPortrait:SetPoint("TOPLEFT", 25, -22)
        -- frameContainer.PlayerPortraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        -- frameContainer.PlayerPortraitMask:ClearAllPoints()
        -- frameContainer.PlayerPortraitMask:SetPoint("CENTER", frameContainer.PlayerPortrait, "CENTER", 0, 0)



        --------- these might need updates / different method
        local totFrame = frame.totFrame
        local totHpBar = totFrame.HealthBar
        local totManaBar = totFrame.ManaBar
        totFrame:SetFrameStrata("DIALOG")
        totHpBar:SetStatusBarColor(0, 1, 0)
        totHpBar:SetSize(47, 7)
        totHpBar:ClearAllPoints()
        totHpBar:SetPoint("TOPRIGHT", -29, -15)
        totHpBar:SetFrameLevel(1)
        totManaBar:SetSize(49, 7)
        totManaBar:ClearAllPoints()
        totManaBar:SetPoint("TOPRIGHT", -29, -23)
        totManaBar:SetFrameLevel(1)
        totFrame.Background = totFrame.HealthBar:CreateTexture(nil, "BACKGROUND")
        totFrame.Background:SetColorTexture(0,0,0,0.45)
        totFrame.Background:SetPoint("TOPLEFT", totFrame.HealthBar, "TOPLEFT", 1, -1)
        totFrame.Background:SetPoint("BOTTOMRIGHT", totFrame.manabar, "BOTTOMRIGHT", -1, 1)
        totFrame.FrameTexture:SetSize(93, 45)
        totFrame.FrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetofTargetFrame")
        totFrame.FrameTexture:SetTexCoord(0.015625, 0.7265625, 0, 0.703125)
        totFrame.FrameTexture:ClearAllPoints()
        totFrame.FrameTexture:SetPoint("TOPLEFT", 0, 0)
        totFrame.Portrait:SetSize(37, 37)
        totFrame.Portrait:ClearAllPoints()
        totFrame.Portrait:SetPoint("TOPLEFT", 4, -5)
        totFrame.HealthBar.DeadText:SetParent(totFrame)
        totFrame.HealthBar.DeadText:ClearAllPoints()
        totFrame.HealthBar.DeadText:SetPoint("LEFT", 48, 3)
        totFrame.HealthBar.UnconsciousText:SetParent(totFrame)
        totFrame.HealthBar.UnconsciousText:ClearAllPoints()
        totFrame.HealthBar.UnconsciousText:SetPoint("LEFT", 48, 3)

        local hideToTDebuffs = (frame.unit == "target" and db.hideTargetToTDebuffs) or (frame.unit == "focus" and db.hideFocusToTDebuffs)
        if not hideToTDebuffs then
            totFrame.lastUpdate = 0
            totFrame:HookScript("OnUpdate", function(self, elapsed)
                self.lastUpdate = self.lastUpdate + elapsed
                if self.lastUpdate >= 0.2 then
                    self.lastUpdate = 0
                    RefreshDebuffs(self, self.unit, nil, nil, true)
                end
            end)
            local debuffFrameName = totFrame:GetName().."Debuff"
            for i = 1, 4 do
                local debuffFrame = _G[debuffFrameName..i]
                debuffFrame:ClearAllPoints()
                if i == 1 then
                    debuffFrame:SetPoint("TOPLEFT", totFrame, "TOPRIGHT", -23, -8)
                elseif i == 2 then
                    debuffFrame:SetPoint("TOPLEFT", totFrame, "TOPRIGHT", -10, -8)
                elseif i== 3 then
                    debuffFrame:SetPoint("TOPLEFT", totFrame, "TOPRIGHT", -23, -21)
                elseif  i==4  then
                    debuffFrame:SetPoint("TOPLEFT", totFrame, "TOPRIGHT", -10, -21)
                end
            end
        end

        local function FrameAdjustments(frame, minus, normal)
            if minus then
                frame.FrameTexture:ClearAllPoints()
                frame.FrameTexture:SetPoint("TOPLEFT", 20, -4)
                frame.Flash:SetSize(256, 128)
                frame.Flash:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Minus-Flash")
                frame.Flash:SetTexCoord(0, 1, 0, 1)
                frame.Flash:ClearAllPoints()
                frame.Flash:SetPoint("TOPLEFT", -4, -4)
                contentMain.ReputationColor:Hide()
                contentMain.LevelText:SetAlpha(1)
            else
                frame.FrameTexture:ClearAllPoints()
                frame.FrameTexture:SetPoint("TOPLEFT", 20.5, -18)
                frame.Flash:SetSize(242, 93)
                frame.Flash:SetTexture(flashTex)
                frame.Flash:SetTexCoord(0, 0.9453125, 0, 0.181640625)
                frame.Flash:ClearAllPoints()
                frame.Flash:SetPoint("TOPLEFT", -4, -8)
                contentMain.LevelText:SetAlpha(1)
                if frame.unit == "target" then
                    contentMain.ReputationColor:SetShown(not BetterBlizzFramesDB.hideTargetReputationColor)
                elseif frame.unit == "focus" then
                    contentMain.ReputationColor:SetShown(not BetterBlizzFramesDB.hideFocusReputationColor)
                end
            end
        end

        local function ToggleNoLevelFrame(noLvl)
            if noLvl then
                frame.ClassicFrame.Texture:SetTexture(noLvlTex)
                frameContainer.Flash:SetTexture(flashNoLvl)
                frameContainer.Flash:SetTexCoord(0, 0.9553125, -0.01,0.733)
                contentMain.LevelText:SetAlpha(0)
            else
                frame.ClassicFrame.Texture:SetTexture(defaultTex)
                frameContainer.Flash:SetTexture(flashTex)
                frameContainer.Flash:SetTexCoord(0, 0.9453125, 0, 0.181640625)
                contentMain.LevelText:SetAlpha(1)
            end
        end

        hooksecurefunc(frame, "CheckClassification", function(self)
            local classification = UnitClassification(self.unit)

            -- Frame
            local content = self.TargetFrameContent
            local frameContainer = frameContainer
            local contentMain = content.TargetFrameContentMain
            -- Status
            local hpContainer = contentMain.HealthBarsContainer
            local manaBar = contentMain.ManaBar

            frame.ClassicFrame.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 3, 9)
            frameContainer.FrameTexture:SetAlpha(0)

            SetXYPoint(hpContainer.HealthBarMask, 1, -6)
            hpContainer.HealthBarMask:SetSize(125, 17)
            manaBar.ManaBarMask:SetWidth(253)
            SetXYPoint(manaBar.ManaBarMask, -59)

            frame.ClassicFrame.Texture:ClearAllPoints()
            frame.ClassicFrame.Texture:SetPoint("TOPLEFT", 20, -8)


            if ( classification == "rareelite" ) then
                FrameAdjustments(frameContainer)
                if hideDragon and alwaysHideLvl then
                    frame.ClassicFrame.Texture:SetTexture(noLvlTex)
                elseif hideDragon then
                    frame.ClassicFrame.Texture:SetTexture(defaultTex)
                else
                    frame.ClassicFrame.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite")
                end
            elseif ( classification == "worldboss" or classification == "elite" ) then
                FrameAdjustments(frameContainer)
                if hideDragon and alwaysHideLvl then
                    frame.ClassicFrame.Texture:SetTexture(noLvlTex)
                elseif hideDragon then
                    frame.ClassicFrame.Texture:SetTexture(defaultTex)
                else
                    frame.ClassicFrame.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
                end
            elseif ( classification == "rare" ) then
                FrameAdjustments(frameContainer)
                if hideDragon and alwaysHideLvl then
                    frame.ClassicFrame.Texture:SetTexture(noLvlTex)
                elseif hideDragon then
                    frame.ClassicFrame.Texture:SetTexture(defaultTex)
                else
                    frame.ClassicFrame.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare")
                end
            elseif ( classification == "minus" ) then
                FrameAdjustments(frameContainer, true)
                frame.ClassicFrame.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Minus")
                frame.ClassicFrame.Background:SetPoint("TOPLEFT", self.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar, "TOPLEFT", 3, -10)
            else
                FrameAdjustments(frameContainer)
                if frame.unit == "target" then
                    contentMain.ReputationColor:SetShown(not BetterBlizzFramesDB.hideTargetReputationColor)
                elseif frame.unit == "focus" then
                    contentMain.ReputationColor:SetShown(not BetterBlizzFramesDB.hideFocusReputationColor)
                end
                if alwaysHideLvl then
                    ToggleNoLevelFrame(true)
                elseif hideLvl then
                    if UnitLevel(frame.unit) == 80 then
                        ToggleNoLevelFrame(true)
                    else
                        ToggleNoLevelFrame(false)
                    end
                else
                    ToggleNoLevelFrame(false)
                end
            end
        end)

        hooksecurefunc(frame, "CheckFaction", function(self)
            if (self.showPVP) then
                local factionGroup = UnitFactionGroup(self.unit)
                if (factionGroup == "Alliance") then
                    contentContext.PvpIcon:ClearAllPoints()
                    contentContext.PvpIcon:SetPoint("TOPRIGHT", -4, -24)
                elseif (factionGroup == "Horde") then
                    contentContext.PvpIcon:ClearAllPoints()
                    contentContext.PvpIcon:SetPoint("TOPRIGHT", 3, -22)
                end
                contentContext.PrestigePortrait:ClearAllPoints()
                contentContext.PrestigePortrait:SetPoint("TOPRIGHT", 5, -17)
            end
        end)

    elseif frame == PlayerFrame then
        -- PlayerFrame
        -- Frame
        local content = frame.PlayerFrameContent
        local frameContainer = frame.PlayerFrameContainer
        local contentMain = content.PlayerFrameContentMain
        local contentContext = content.PlayerFrameContentContextual
        -- Status
        local hpContainer = contentMain.HealthBarsContainer
        local manaBar = contentMain.ManaBarArea.ManaBar

        frame.ClassicFrame = CreateFrame("Frame")
        frame.ClassicFrame:SetParent(frame)
        frame.ClassicFrame:SetFrameStrata("HIGH")
        frame.ClassicFrame:SetAllPoints(frame)
        frame.ClassicFrame.Texture = frame.ClassicFrame:CreateTexture(nil, "OVERLAY")
        frame.ClassicFrame.Texture:SetParent(frame.ClassicFrame)

        manaBar.FullPowerFrame:SetParent(frame.ClassicFrame)

        contentMain.HitIndicator.HitText:ClearAllPoints()
        contentMain.HitIndicator.HitText:SetPoint("CENTER", frameContainer.PlayerPortrait)
        contentMain.HitIndicator.HitText:SetScale(0.85)
        contentMain.HitIndicator:SetParent(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual)

        contentContext:SetParent(frame.ClassicFrame)
        contentContext.AttackIcon:ClearAllPoints()
        contentContext.AttackIcon:SetPoint("CENTER", -80, -23.5)
        contentContext.AttackIcon:SetSize(32, 31)
        contentContext.AttackIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        contentContext.AttackIcon:SetTexCoord(0.5, 1.0, 0, 0.484375)
        contentContext.AttackIcon:SetDrawLayer("OVERLAY")
        contentContext.PlayerPortraitCornerIcon:SetAtlas(nil)
        contentContext.PrestigePortrait:ClearAllPoints()
        contentContext.PrestigePortrait:SetPoint("TOPLEFT", -4, -17)
        contentContext.LeaderIcon:ClearAllPoints()
        contentContext.LeaderIcon:SetPoint("TOPLEFT", 86, -14)
        contentContext.RoleIcon:ClearAllPoints()
        contentContext.RoleIcon:SetPoint("TOPLEFT", 192, -34)

        --AdjustFramePoint(contentContext.GroupIndicator, nil, -3)

        frameContainer.PlayerPortrait:SetSize(62, 62)
        frameContainer.PlayerPortraitMask:SetSize(62, 62)
        frameContainer.PlayerPortraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frameContainer.PlayerPortraitMask:ClearAllPoints()
        frameContainer.PlayerPortraitMask:SetPoint("CENTER", frameContainer.PlayerPortrait, "CENTER", 0, 0)

        local a2,b2,c2,d2,e2 = PlayerFrameBottomManagedFramesContainer:GetPoint()

        frame.ClassicFrame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.ClassicFrame.Background:SetColorTexture(0,0,0,0.45)
        frame.ClassicFrame.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 0, 11)
        frame.ClassicFrame.Background:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", -3, 0)


        C_Timer.After(1, function()
            local bd = BigDebuffsplayerUnitFrame
            local oa = C_AddOns.IsAddOnLoaded("OmniAuras")
            if bd then
                if bd.mask then
                    bd.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                elseif bd.icon then
                    bd.mask = bd:CreateMaskTexture()
                    bd.mask:SetAllPoints(bd.icon)
                    bd.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                    bd.icon:AddMaskTexture(bd.mask)
                end
            end
            if oa then
                for _, child in ipairs({PlayerFrame.PlayerFrameContainer:GetChildren()}) do
                    if child:IsObjectType("Button") then
                        local mask = child.mask
                        if mask and mask.SetTexture then
                            mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                            break
                        end
                    end
                end
            end
        end)


        local function AdjustStatusBarText()
            hpContainer.LeftText:SetParent(frame.ClassicFrame)
            hpContainer.LeftText:ClearAllPoints()
            hpContainer.LeftText:SetPoint("LEFT", frame.ClassicFrame.Texture, "LEFT", 108, 2.8)
            hpContainer.RightText:SetParent(frame.ClassicFrame)
            hpContainer.RightText:ClearAllPoints()
            hpContainer.RightText:SetPoint("RIGHT", frame.ClassicFrame.Texture, "RIGHT", -7, 2.8)
            hpContainer.HealthBarText:SetParent(frame.ClassicFrame)
            hpContainer.HealthBarText:ClearAllPoints()
            hpContainer.HealthBarText:SetPoint("CENTER", frame.ClassicFrame.Texture, "CENTER", 52, 2.8)

            manaBar.LeftText:SetParent(frame.ClassicFrame)
            manaBar.LeftText:ClearAllPoints()
            manaBar.LeftText:SetPoint("LEFT", frame.ClassicFrame.Texture, "LEFT", 108, -8.5)
            manaBar.RightText:SetParent(frame.ClassicFrame)
            manaBar.RightText:ClearAllPoints()
            manaBar.RightText:SetPoint("RIGHT", frame.ClassicFrame.Texture, "RIGHT", -7, -8.5)
            manaBar.ManaBarText:SetParent(frame.ClassicFrame)
            manaBar.ManaBarText:ClearAllPoints()
            manaBar.ManaBarText:SetPoint("CENTER", frame.ClassicFrame.Texture, "CENTER", 52, -8.5)
        end

        AdjustFramePoint(hpContainer.HealthBar.OverAbsorbGlow,-3)

        if C_CVar.GetCVar("comboPointLocation") == "1" and ComboFrame then
            ComboFrame:SetParent(TargetFrame)
            ComboFrame:SetFrameStrata("HIGH")
            BBF.UpdateLegacyComboPosition()
        end

        local function UpdateLevelDetails()
            PlayerLevelText:SetParent(frame.ClassicFrame)
            PlayerLevelText:SetDrawLayer("OVERLAY", 7)
            PlayerLevelText:Show()
            PlayerLevelText:ClearAllPoints()
            PlayerLevelText:SetPoint("CENTER", -81, -24.5)
        end

        local function UpdateLevel()
            if not db.playerEliteFrame then
                if alwaysHideLvl then
                    PlayerLevelText:SetParent(BBF.hiddenFrame)
                    PlayerLevelText:ClearAllPoints()
                    PlayerLevelText:SetPoint("CENTER", -81, -24.5)
                elseif hideLvl then
                    if UnitLevel(frame.unit) == 80 then
                        PlayerLevelText:SetParent(BBF.hiddenFrame)
                        PlayerLevelText:ClearAllPoints()
                        PlayerLevelText:SetPoint("CENTER", -81, -24.5)
                    else
                        UpdateLevelDetails()
                    end
                else
                    UpdateLevelDetails()
                end
            else
                UpdateLevelDetails()
            end
        end
        hooksecurefunc("PlayerFrame_UpdateLevel", function()
            UpdateLevel()
        end)
        UpdateLevel()

        hooksecurefunc("PlayerFrame_UpdateRolesAssigned", function()
            contentContext.RoleIcon:ClearAllPoints()
            contentContext.RoleIcon:SetPoint("TOPLEFT", 192, -34)
            PlayerLevelText:SetShown(not UnitHasVehiclePlayerFrameUI("player"))
        end)

        if not db.hidePvpTimerText then
            hooksecurefunc("PlayerFrame_UpdatePvPStatus", function()
                contentContext.PvpTimerText:ClearAllPoints()
                contentContext.PvpTimerText:SetPoint("BOTTOMLEFT", 8, 8)
            end)
        end

        local function GetFrameColor()
            local r, g, b = frameContainer.FrameTexture:GetVertexColor()
            frame.ClassicFrame.Texture:SetVertexColor(r, g, b)

            if not db.darkModeUi then
                local soulShards = _G.WarlockPowerFrame
                if soulShards then
                    for _, v in pairs({soulShards:GetChildren()}) do
                        v.Background:SetVertexColor(
                            math.max(r - 0.35, 0),
                            math.max(g - 0.35, 0),
                            math.max(b - 0.35, 0)
                        )
                    end
                end
            end
        end

        GetFrameColor()
        hooksecurefunc(frameContainer.FrameTexture, "SetVertexColor", GetFrameColor)

        local DEFAULT_X, DEFAULT_Y = 29, 28.5
        local resourceFramePositions = {
            EVOKER = {x = 28, y = 31, scale = 1.05, specs = {[1473] = { x = 30, y = 24 }}},
            WARRIOR = { x = 28, y = 30 },
            ROGUE   = { x = 48, y = 38, scale = 0.85},
            MAGE = { x = 32, y = 32, scale = 0.95 },
            PALADIN = { scale = 0.91 },
            DEATHKNIGHT = { x = 35, y = 34, scale = 0.90 },
            DRUID = { x = 31, y = 30},
            MONK = { x = 29.5, y = 31, scale = 0.96 },
        }

        local function GetPlayerClassAndSpecPosition()
            local _, classToken = UnitClass("player")
            local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization())
            local position = resourceFramePositions[classToken]

            if position then
                if position.specs and specID and position.specs[specID] then
                    local specData = position.specs[specID]
                    local x = specData.x or DEFAULT_X
                    local y = specData.y or DEFAULT_Y
                    local scale = specData.scale
                    return x, y, scale
                end
                local x = position.x or DEFAULT_X
                local y = position.y or DEFAULT_Y
                local scale = position.scale or 1
                return x, y, scale
            end

            return DEFAULT_X, DEFAULT_Y, 1
        end

        local classConflicts = {
            ROGUE = db.moveResourceToTargetRogue,
            DRUID = db.moveResourceToTargetDruid,
            WARLOCK = db.moveResourceToTargetWarlock,
            MAGE = db.moveResourceToTargetMage,
            MONK = db.moveResourceToTargetMonk,
            EVOKER = db.moveResourceToTargetEvoker,
            PALADIN = db.moveResourceToTargetPaladin,
            DEATHKNIGHT = db.moveResourceToTargetDK,
        }

        local function UpdateResourcePosition(rogueCheck)
            if db.moveResource or (db.moveResourceToTarget and classConflicts[class]) then
                return
            end

            if not InCombatLockdown() then
                PlayerFrameBottomManagedFramesContainer:ClearAllPoints()
                local xOffset, yOffset, scale = GetPlayerClassAndSpecPosition()
                if rogueCheck then
                    local isRogueWith5Combos = UnitPowerMax("player", Enum.PowerType.ComboPoints) == 5
                    local isRogueWith6Combos = UnitPowerMax("player", Enum.PowerType.ComboPoints) == 6
                    if isRogueWith5Combos then
                        PlayerFrameBottomManagedFramesContainer:SetPoint(a2, b2, c2, 31.5, 35)
                        PlayerFrameBottomManagedFramesContainer:SetScale(0.95)
                    elseif isRogueWith6Combos then
                        PlayerFrameBottomManagedFramesContainer:SetPoint(a2, b2, c2, 46, 37)
                        PlayerFrameBottomManagedFramesContainer:SetScale(scale)
                    else
                        PlayerFrameBottomManagedFramesContainer:SetPoint(a2, b2, c2, xOffset, yOffset)
                        PlayerFrameBottomManagedFramesContainer:SetScale(scale)
                    end
                else
                    PlayerFrameBottomManagedFramesContainer:SetPoint(a2, b2, c2, xOffset, yOffset)
                    PlayerFrameBottomManagedFramesContainer:SetScale(scale)
                end
                PlayerFrameBottomManagedFramesContainer:SetFrameStrata("HIGH")
            else
                PlayerFrameBottomManagedFramesContainer.positionNeedsUpdate = true
                if not BBF.CombatWaiter then
                    BBF.CombatWaiter = CreateFrame("Frame")
                    BBF.CombatWaiter:SetScript("OnEvent", function(self)
                        if PlayerFrameBottomManagedFramesContainer.positionNeedsUpdate then
                            PlayerFrameBottomManagedFramesContainer.positionNeedsUpdate = false
                            UpdateResourcePosition()
                        end
                        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    end)
                end
                if not BBF.CombatWaiter:IsEventRegistered("PLAYER_REGEN_ENABLED") then
                    BBF.CombatWaiter:RegisterEvent("PLAYER_REGEN_ENABLED")
                end
            end
        end

        local isRogue = class == "ROGUE"
        if isRogue then
            local specWatcher = CreateFrame("Frame")
            specWatcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            specWatcher:RegisterEvent("TRAIT_CONFIG_UPDATED")
            specWatcher:SetScript("OnEvent", function(self, event, unit)
                local rogueCombos = UnitPowerMax("player", Enum.PowerType.ComboPoints)
                UpdateResourcePosition(rogueCombos)
            end)
        end

        local function PlayerEliteFrame()
            local playerElite = frame.ClassicFrame.Texture
            local mode = BetterBlizzFramesDB.playerEliteFrameMode
            -- Set Elite style according to value
            if mode == 1 then -- Rare (Silver)
                playerElite:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare")
                playerElite:SetDesaturated(true)
            elseif mode == 2 then -- Boss (Silver Winged)
                playerElite:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite")
                playerElite:SetDesaturated(true)
            elseif mode == 3 then -- Boss (Gold Winged)
                playerElite:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
                playerElite:SetDesaturated(false)
            else
                frame.ClassicFrame.Texture:SetTexture(defaultTex)
                frameContainer.FrameFlash:SetTexture(flashTex)
                frameContainer.FrameFlash:SetTexCoord(0.9453125, 0, 0, 0.181640625)
                contentMain.StatusTexture:SetTexture("Interface\\CharacterFrame\\UI-Player-Status")
            -- elseif mode == 4 then -- Only 3 available for classic
            --     db.playerEliteFrameMode = 3
            --     playerElite:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
            --     playerElite:SetDesaturated(false)
            end
        end

        local function ToggleNoLevelFrame(noLvl)
            if noLvl then
                frame.ClassicFrame.Texture:SetTexture(noLvlTex)
                frameContainer.FrameFlash:SetTexture(flashNoLvl)
                frameContainer.FrameFlash:SetTexCoord(0.9553125,0, -0.01,0.733)
                contentMain.StatusTexture:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\classic-statustexture-nolevel")
            else
                frame.ClassicFrame.Texture:SetTexture(defaultTex)
                frameContainer.FrameFlash:SetTexture(flashTex)
                frameContainer.FrameFlash:SetTexCoord(0.9453125, 0, 0, 0.181640625)
                contentMain.StatusTexture:SetTexture("Interface\\CharacterFrame\\UI-Player-Status")
            end
        end

        local function ToPlayerArt()
            UpdateResourcePosition(isRogue)

            AdjustFramePoint(hpContainer.HealthBarMask, 0, -11)
            hpContainer.HealthBarMask:SetSize(126, 17)

            manaBar.ManaBarMask:SetSize(126, 19)
            AdjustFramePoint(manaBar.ManaBarMask, 0, 2)

            frameContainer.FrameTexture:ClearAllPoints()
            frameContainer.FrameTexture:SetPoint("TOPLEFT", -19, 7)
            frameContainer.FrameTexture:SetAlpha(0)

            contentContext.RoleIcon:ClearAllPoints()
            contentContext.RoleIcon:SetPoint("TOPLEFT", 192, -34)

            contentContext.GroupIndicator:ClearAllPoints()
            contentContext.GroupIndicator:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -21, -33.5)
            PlayerFrameGroupIndicatorText:ClearAllPoints()
            PlayerFrameGroupIndicatorText:SetPoint("LEFT", contentContext.GroupIndicator.GroupIndicatorLeft, "LEFT", 20, 2.5)

            frame.ClassicFrame.Texture:SetSize(232, 100)
            if db.playerEliteFrame then
                PlayerEliteFrame()
                frameContainer.FrameFlash:SetTexture(flashTex)
                frameContainer.FrameFlash:SetTexCoord(0.9453125, 0, 0, 0.181640625)
                contentMain.StatusTexture:SetTexture("Interface\\CharacterFrame\\UI-Player-Status")
            else
                if alwaysHideLvl then
                    ToggleNoLevelFrame(true)
                elseif hideLvl then
                    if UnitLevel("player") == 80 then
                        ToggleNoLevelFrame(true)
                    else
                        ToggleNoLevelFrame(false)
                    end
                else
                    ToggleNoLevelFrame(false)
                end
            end
            frame.ClassicFrame.Texture:SetTexCoord(1, 0.09375, 0, 0.78125)
            frame.ClassicFrame.Texture:ClearAllPoints()
            frame.ClassicFrame.Texture:SetPoint("TOPLEFT", -19, -8)
            frame.ClassicFrame.Texture:SetDrawLayer("BORDER")

            frameContainer.AlternatePowerFrameTexture:ClearAllPoints()
            frameContainer.AlternatePowerFrameTexture:SetPoint("TOPLEFT", -19, -8)
            frameContainer.AlternatePowerFrameTexture:SetAlpha(0)

            frameContainer.FrameFlash:SetParent(db.hideCombatGlow and BBF.hiddenFrame or frame)
            frameContainer.FrameFlash:SetSize(242, 93)
            --frameContainer.FrameFlash:SetTexture(flashTex)
            --frameContainer.FrameFlash:SetTexCoord(0.9453125, 0, 0, 0.181640625)
            frameContainer.FrameFlash:ClearAllPoints()
            frameContainer.FrameFlash:SetPoint("TOPLEFT", -6, -8)
            frameContainer.FrameFlash:SetDrawLayer("BACKGROUND")

            contentMain.StatusTexture:SetSize(191, 77)
            contentMain.StatusTexture:SetTexCoord(0, 0.74609375, 0, 0.58125)
            contentMain.StatusTexture:ClearAllPoints()
            contentMain.StatusTexture:SetPoint("TOPLEFT", 17, -15)
            contentMain.StatusTexture:SetBlendMode("ADD")

            AdjustStatusBarText()

            frameContainer.PlayerPortrait:ClearAllPoints()
            frameContainer.PlayerPortrait:SetPoint("TOPLEFT", 26, -23)
            frame.ClassicFrame.Texture:Show()

            frame.ClassicFrame.Background:SetPoint("BOTTOMRIGHT", contentMain.HealthBarsContainer, "BOTTOMRIGHT", -2, -11)
        end

        hooksecurefunc("PlayerFrame_ToPlayerArt", function()
            ToPlayerArt()
        end)
        ToPlayerArt()

        local function ToVehicleArt()
            frameContainer.VehicleFrameTexture:ClearAllPoints()
            frameContainer.VehicleFrameTexture:SetPoint("TOPLEFT", -3, 1)
            frameContainer.VehicleFrameTexture:SetAlpha(0)

            frame.ClassicFrame.Texture:SetSize(240, 120)
            frame.ClassicFrame.Texture:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame")
            frame.ClassicFrame.Texture:ClearAllPoints()
            frame.ClassicFrame.Texture:SetPoint("TOPLEFT", -3, 1)
            frame.ClassicFrame.Texture:SetTexCoord(0, 1, 0, 1)

            hpContainer.HealthBarMask:SetSize(120, 32)

            frameContainer.FrameFlash:SetParent(frame)
            frameContainer.FrameFlash:SetSize(242, 93)
            frameContainer.FrameFlash:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame-Flash")
            frameContainer.FrameFlash:SetTexCoord(-0.02, 1, 0.07, 0.86)
            frameContainer.FrameFlash:ClearAllPoints()
            frameContainer.FrameFlash:SetPoint("TOPLEFT", -6, -4)
            frameContainer.FrameFlash:SetDrawLayer("BACKGROUND")

            contentContext.RoleIcon:ClearAllPoints()
            contentContext.RoleIcon:SetPoint("TOPLEFT", 186, -29)

            contentMain.StatusTexture:SetSize(242, 93)
            contentMain.StatusTexture:SetTexture("Interface\\Vehicles\\UI-Vehicle-Frame-Flash")
            contentMain.StatusTexture:SetTexCoord(-0.02, 1, 0.07, 0.86)
            contentMain.StatusTexture:ClearAllPoints()
            contentMain.StatusTexture:SetPoint("TOPLEFT", -6, -4)
            contentMain.StatusTexture:SetDrawLayer("BACKGROUND")

            hpContainer.LeftText:SetParent(frame.ClassicFrame)
            hpContainer.LeftText:ClearAllPoints()
            hpContainer.LeftText:SetPoint("LEFT", frame.ClassicFrame.Texture, "LEFT", 101, 3)
            hpContainer.RightText:SetParent(frame.ClassicFrame)
            hpContainer.RightText:ClearAllPoints()
            hpContainer.RightText:SetPoint("RIGHT", frame.ClassicFrame.Texture, "RIGHT", -38, 3)
            hpContainer.HealthBarText:SetParent(frame.ClassicFrame)
            hpContainer.HealthBarText:ClearAllPoints()
            hpContainer.HealthBarText:SetPoint("CENTER", frame.ClassicFrame.Texture, "CENTER", 34, 3)

            manaBar.LeftText:SetParent(frame.ClassicFrame)
            manaBar.LeftText:ClearAllPoints()
            manaBar.LeftText:SetPoint("LEFT", frame.ClassicFrame.Texture, "LEFT", 101, -9)
            manaBar.RightText:SetParent(frame.ClassicFrame)
            manaBar.RightText:ClearAllPoints()
            manaBar.RightText:SetPoint("RIGHT", frame.ClassicFrame.Texture, "RIGHT", -7, -9)
            manaBar.ManaBarText:SetParent(frame.ClassicFrame)
            manaBar.ManaBarText:ClearAllPoints()
            manaBar.ManaBarText:SetPoint("CENTER", frame.ClassicFrame.Texture, "CENTER", 52, -9)

            frameContainer.PlayerPortrait:ClearAllPoints()
            frameContainer.PlayerPortrait:SetPoint("TOPLEFT", 23, -17)

            frame.ClassicFrame.Background:SetPoint("BOTTOMRIGHT", contentMain.HealthBarsContainer, "BOTTOMRIGHT", -7, -12)
        end

        hooksecurefunc("PlayerFrame_ToVehicleArt", function(self)
            ToVehicleArt()
        end)

        hooksecurefunc(TotemFrame, "Update", function(self)
            for child in self.totemPool:EnumerateActive() do
                child.Border:SetSize(39, 39)
                child.Border:SetTexture("Interface\\CharacterFrame\\TotemBorder")
                child.Border:ClearAllPoints()
                child.Border:SetPoint("CENTER")
            end
        end)

        TotemFrame:SetScale(0.85)
        hooksecurefunc(TotemFrame, "SetPoint", function(self)
            if self.changing then return end
            if classFrame and classFrame:IsShown() then return end
            self.changing = true
            local a, b, c, d, e = self:GetPoint()
            self:ClearAllPoints()
            self:SetPoint(a, b, c, d, e - 5)
            self.changing = false
        end)

    elseif frame == PetFrame then
        PetFrame:SetSize(128, 53)
        PetPortrait:ClearAllPoints()
        PetPortrait:SetPoint("TOPLEFT", 7, -6)

        PetFrameTexture:SetSize(128, 64)
        PetFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-SmallTargetingFrame")
        PetFrameTexture:ClearAllPoints()
        PetFrameTexture:SetPoint("TOPLEFT", 1, -1)

        PetFrameFlash:SetSize(128, 67)
        PetFrameFlash:SetTexture("Interface\\TargetingFrame\\UI-PartyFrame-Flash")
        PetFrameFlash:SetPoint("TOPLEFT", -3, 12)
        PetFrameFlash:SetTexCoord(0, 1, 1, 0)
        PetFrameFlash:SetDrawLayer("BACKGROUND")

        PetFrameHealthBar:SetSize(69, 8)
        PetFrameHealthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        PetFrameHealthBar:SetStatusBarColor(0, 1, 0)
        PetFrameHealthBar:ClearAllPoints()
        PetFrameHealthBar:SetPoint("TOPLEFT", 47, -22)
        PetFrameHealthBar:SetFrameLevel(1)
        PetFrameHealthBarMask:Hide()

        PetFrameManaBar:SetSize(71, 8)
        PetFrameManaBar:ClearAllPoints()
        PetFrameManaBar:SetPoint("TOPLEFT", 45, -29)
        PetFrameManaBar:SetFrameLevel(1)
        PetFrameManaBarMask:Hide()

        PetFrameHealthBarText:SetParent(PetFrame)
        PetFrameHealthBarTextLeft:SetParent(PetFrame)
        PetFrameHealthBarTextRight:SetParent(PetFrame)
        PetFrameManaBarText:SetParent(PetFrame)
        PetFrameManaBarTextLeft:SetParent(PetFrame)
        PetFrameManaBarTextRight:SetParent(PetFrame)

        PetFrameHealthBarText:ClearAllPoints()
        PetFrameHealthBarText:SetPoint("CENTER", PetFrame, "TOPLEFT", 82, -26)
        PetFrameHealthBarTextLeft:ClearAllPoints()
        PetFrameHealthBarTextLeft:SetPoint("LEFT", PetFrame, "TOPLEFT", 46, -26)
        PetFrameHealthBarTextRight:ClearAllPoints()
        PetFrameHealthBarTextRight:SetPoint("RIGHT", PetFrame, "TOPLEFT", 113, -26)
        PetFrameManaBarText:ClearAllPoints()
        PetFrameManaBarText:SetPoint("CENTER", PetFrame, "TOPLEFT", 82, -35)
        PetFrameManaBarTextLeft:ClearAllPoints()
        PetFrameManaBarTextLeft:SetPoint("LEFT", PetFrame, "TOPLEFT", 46, -35)
        PetFrameManaBarTextRight:ClearAllPoints()
        PetFrameManaBarTextRight:SetPoint("RIGHT", PetFrame, "TOPLEFT", 113, -35)

        PetFrameOverAbsorbGlow:SetParent(PetFrame)
        PetFrameOverAbsorbGlow:SetDrawLayer("ARTWORK", 7)

        PetAttackModeTexture:SetSize(76, 64)
        PetAttackModeTexture:SetTexture("Interface\\TargetingFrame\\UI-Player-AttackStatus")
        PetAttackModeTexture:SetTexCoord(0.703125, 1, 0, 1)
        PetAttackModeTexture:ClearAllPoints()
        PetAttackModeTexture:SetPoint("TOPLEFT", 6, -9)

        PetHitIndicator:ClearAllPoints()
        PetHitIndicator:SetPoint("CENTER", PetFrame, "TOPLEFT", 28, -27)
    end
end

local function AdjustAlternateBars()
    AlternatePowerBar:SetSize(104, 12)
    AlternatePowerBar:ClearAllPoints()
    AlternatePowerBar:SetPoint("BOTTOMLEFT", 95, 16)

    AlternatePowerBarText:SetPoint("CENTER", 2, -1)
    AlternatePowerBar.LeftText:SetPoint("LEFT", 0, -1)
    AlternatePowerBar.RightText:SetPoint("RIGHT", 0, -1)

    AlternatePowerBar.Background = AlternatePowerBar:CreateTexture(nil, "BACKGROUND")
    AlternatePowerBar.Background:SetAllPoints()
    AlternatePowerBar.Background:SetColorTexture(0, 0, 0, 0.5)

    AlternatePowerBar.Border = AlternatePowerBar:CreateTexture(nil, "OVERLAY")
    AlternatePowerBar.Border:SetSize(0, 16)
    AlternatePowerBar.Border:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
    AlternatePowerBar.Border:SetTexCoord(0.125, 0.250, 1, 0)
    AlternatePowerBar.Border:SetPoint("TOPLEFT", 4, 0)
    AlternatePowerBar.Border:SetPoint("TOPRIGHT", -4, 0)

    AlternatePowerBar.LeftBorder = AlternatePowerBar:CreateTexture(nil, "OVERLAY")
    AlternatePowerBar.LeftBorder:SetSize(16, 16)
    AlternatePowerBar.LeftBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
    AlternatePowerBar.LeftBorder:SetTexCoord(0, 0.125, 1, 0)
    AlternatePowerBar.LeftBorder:SetPoint("RIGHT", AlternatePowerBar.Border, "LEFT")

    AlternatePowerBar.RightBorder = AlternatePowerBar:CreateTexture(nil, "OVERLAY")
    AlternatePowerBar.RightBorder:SetSize(16, 16)
    AlternatePowerBar.RightBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
    AlternatePowerBar.RightBorder:SetTexCoord(0.125, 0, 1, 0)
    AlternatePowerBar.RightBorder:SetPoint("LEFT", AlternatePowerBar.Border, "RIGHT")

    if BetterBlizzFramesDB.changeUnitFrameManabarTexture then
        hooksecurefunc(AlternatePowerBar, "EvaluateUnit", function(self)
            self:SetStatusBarTexture(BBF.manaTexture)
            self:SetStatusBarColor(0, 0, 1)
            if self.PowerBarMask then
                self.PowerBarMask:Hide()
            end
        end)
    else
        AdjustFramePoint(AlternatePowerBar.PowerBarMask, nil, -1)
    end

    if class == "MONK" then
        MonkStaggerBar:SetSize(94, 12)
        MonkStaggerBar:ClearAllPoints()
        MonkStaggerBar:SetPoint("TOPLEFT", PlayerFrameAlternatePowerBarArea, "TOPLEFT", 101, -72)

        MonkStaggerBar.PowerBarMask:Hide()

        MonkStaggerBarText:SetPoint("CENTER", 1, -1)
        MonkStaggerBar.LeftText:SetPoint("LEFT", 0, -1)
        MonkStaggerBar.RightText:SetPoint("RIGHT", 0, -1)

        MonkStaggerBar.Background = MonkStaggerBar:CreateTexture(nil, "BACKGROUND")
        MonkStaggerBar.Background:SetSize(128, 16)
        MonkStaggerBar.Background:SetTexture("Interface\\PlayerFrame\\MonkManaBar")
        MonkStaggerBar.Background:SetTexCoord(0, 1, 0.5, 1)
        MonkStaggerBar.Background:SetPoint("TOPLEFT", -17, 0)

        MonkStaggerBar.Border = MonkStaggerBar:CreateTexture(nil, "OVERLAY")
        MonkStaggerBar.Border:SetSize(128, 16)
        MonkStaggerBar.Border:SetTexture("Interface\\PlayerFrame\\MonkManaBar")
        MonkStaggerBar.Border:SetTexCoord(0, 1, 0, 0.5)
        MonkStaggerBar.Border:SetPoint("TOPLEFT", -17, 0)

        hooksecurefunc(MonkStaggerBar, "EvaluateUnit", function(self)
            self:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            self:SetStatusBarColor(0, 0, 1)
        end)
    end

    -- if class == "DRUID" then
    --     C_Timer.After(1, function()
    --         BBF.CreateAltManaBar() --allow time for specID not to be nil cuz yea
    --     end)
    -- end


    if class == "EVOKER" then
        EvokerEbonMightBar:SetSize(104, 12)
        EvokerEbonMightBar:ClearAllPoints()
        EvokerEbonMightBar:SetPoint("BOTTOMLEFT", 95, 17)

        EvokerEbonMightBarText:SetPoint("CENTER", 1, -1)
        EvokerEbonMightBar.LeftText:SetPoint("LEFT", 0, -1)
        EvokerEbonMightBar.RightText:SetPoint("RIGHT", 0, -1)

        EvokerEbonMightBar.Background = EvokerEbonMightBar:CreateTexture(nil, "BACKGROUND")
        EvokerEbonMightBar.Background:SetAllPoints()
        EvokerEbonMightBar.Background:SetColorTexture(0, 0, 0, 0.5)

        EvokerEbonMightBar.Border = EvokerEbonMightBar:CreateTexture(nil, "OVERLAY")
        EvokerEbonMightBar.Border:SetSize(0, 16)
        EvokerEbonMightBar.Border:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        EvokerEbonMightBar.Border:SetTexCoord(0.125, 0.250, 1, 0)
        EvokerEbonMightBar.Border:SetPoint("TOPLEFT", 4, 0)
        EvokerEbonMightBar.Border:SetPoint("TOPRIGHT", -4, 0)

        EvokerEbonMightBar.LeftBorder = EvokerEbonMightBar:CreateTexture(nil, "OVERLAY")
        EvokerEbonMightBar.LeftBorder:SetSize(16, 16)
        EvokerEbonMightBar.LeftBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        EvokerEbonMightBar.LeftBorder:SetTexCoord(0, 0.125, 1, 0)
        EvokerEbonMightBar.LeftBorder:SetPoint("RIGHT", EvokerEbonMightBar.Border, "LEFT")

        EvokerEbonMightBar.RightBorder = EvokerEbonMightBar:CreateTexture(nil, "OVERLAY")
        EvokerEbonMightBar.RightBorder:SetSize(16, 16)
        EvokerEbonMightBar.RightBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        EvokerEbonMightBar.RightBorder:SetTexCoord(0.125, 0, 1, 0)
        EvokerEbonMightBar.RightBorder:SetPoint("LEFT", EvokerEbonMightBar.Border, "RIGHT")

        hooksecurefunc(EvokerEbonMightBar, "EvaluateUnit", function(self)
            self:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            self:SetStatusBarColor(1, 0.5, 0.25)

            if self.PowerBarMask then
                self.PowerBarMask:Hide()
            end
        end)
    end

    local classicFrameColorTargets = {
        AlternatePowerBar.Border,
        AlternatePowerBar.LeftBorder,
        AlternatePowerBar.RightBorder,
    }

    if class == "MONK" then
        tinsert(classicFrameColorTargets, MonkStaggerBar.Border)
    end

    if class == "EVOKER" then
        tinsert(classicFrameColorTargets, EvokerEbonMightBar.Border)
        tinsert(classicFrameColorTargets, EvokerEbonMightBar.LeftBorder)
        tinsert(classicFrameColorTargets, EvokerEbonMightBar.RightBorder)
    end

    local function GetFrameColor()
        local r, g, b = PlayerFrame.PlayerFrameContainer.FrameTexture:GetVertexColor()
        for _, frame in pairs(classicFrameColorTargets) do
            if frame then
                frame:SetVertexColor(r, g, b)
            end
        end
    end
    GetFrameColor()
    hooksecurefunc(PlayerFrame.PlayerFrameContainer.FrameTexture, "SetVertexColor", GetFrameColor)
end

local function MakeClassicPartyFrame()
    for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
        local overlay = frame.PartyMemberOverlay
        local hpContainer = frame.HealthBarContainer
        local manaBar = frame.ManaBar

        frame.Texture:SetSize(136, 59)
        frame.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame")
        frame.Texture:SetTexCoord(1, 0.09375, 0, 0.78125)
        frame.Texture:ClearAllPoints()
        frame.Texture:SetPoint("TOPLEFT", -18, 2)
        frame.Texture:SetDrawLayer("ARTWORK", 7)
        frame.Texture:SetParent(hpContainer)

        frame.Flash:SetSize(143, 56)
        frame.Flash:SetTexture(flashTex)
        frame.Flash:SetTexCoord(0.9453125, 0, 0, 0.181640625)
        frame.Flash:ClearAllPoints()
        frame.Flash:SetPoint("TOPLEFT", -10.5, 2.5)

        overlay.Status:SetSize(143, 56)
        overlay.Status:SetTexture(flashTex)
        overlay.Status:SetTexCoord(0.9453125, 0, 0, 0.181640625)
        overlay.Status:ClearAllPoints()
        overlay.Status:SetPoint("TOPLEFT", -10.5, 2.5)


        overlay.LeaderIcon:SetSize(14,14)
        AdjustFramePoint(overlay.LeaderIcon, nil, -6)
        overlay.RoleIcon:ClearAllPoints()
        overlay.RoleIcon:SetPoint("BOTTOMLEFT", 8, 10)
        overlay.PVPIcon:SetParent(BBF.hiddenFrame)

        AdjustFramePoint(hpContainer.HealthBarMask, nil, -3)

        frame.Background = frame:CreateTexture(nil, "BACKGROUND")
        frame.Background:SetColorTexture(0,0,0,0.45)
        frame.Background:SetPoint("TOPLEFT", hpContainer.HealthBar, "TOPLEFT", 0, 7)
        frame.Background:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", 1, 3)

        frame.bbfName:ClearAllPoints()
        frame.bbfName:SetPoint("BOTTOM", hpContainer, "TOP", 0, -3)
        frame.bbfName:SetWidth(69)
        frame.bbfName:SetScale(0.85)
        frame.bbfName:SetJustifyH("CENTER")

        hpContainer.LeftText:SetScale(0.72)
        hpContainer.RightText:SetScale(0.72)
        hpContainer.CenterText:SetScale(0.72)
        manaBar.TextString:SetScale(0.72)
        manaBar.LeftText:SetScale(0.72)
        manaBar.RightText:SetScale(0.72)

        hpContainer.CenterText:ClearAllPoints()
        hpContainer.CenterText:SetPoint("CENTER", hpContainer, "CENTER", 2, -2)
        hpContainer.LeftText:ClearAllPoints()
        hpContainer.LeftText:SetPoint("LEFT", hpContainer, "LEFT", 0, -2)
        hpContainer.RightText:ClearAllPoints()
        hpContainer.RightText:SetPoint("RIGHT", hpContainer, "RIGHT", 0, -2)
        manaBar.TextString:ClearAllPoints()
        manaBar.TextString:SetPoint("CENTER", manaBar, "CENTER", 4.5, 1)
        manaBar.LeftText:ClearAllPoints()
        manaBar.LeftText:SetPoint("LEFT", manaBar, "LEFT", 6, 1)
        manaBar.RightText:ClearAllPoints()
        manaBar.RightText:SetPoint("RIGHT", manaBar, "RIGHT", 0, 1)

        hooksecurefunc(frame, "ToPlayerArt", function(self)
            self.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame")

            AdjustFramePoint(frame.HealthBarContainer.HealthBarMask, nil, -3)

            hpContainer.CenterText:ClearAllPoints()
            hpContainer.CenterText:SetPoint("CENTER", hpContainer, "CENTER", 2, -2)
            hpContainer.LeftText:ClearAllPoints()
            hpContainer.LeftText:SetPoint("LEFT", hpContainer, "LEFT", 0, -2)
            hpContainer.RightText:ClearAllPoints()
            hpContainer.RightText:SetPoint("RIGHT", hpContainer, "RIGHT", 0, -2)
            manaBar.TextString:ClearAllPoints()
            manaBar.TextString:SetPoint("CENTER", manaBar, "CENTER", 4.5, 1)
            manaBar.LeftText:ClearAllPoints()
            manaBar.LeftText:SetPoint("LEFT", manaBar, "LEFT", 6, 1)
            manaBar.RightText:ClearAllPoints()
            manaBar.RightText:SetPoint("RIGHT", manaBar, "RIGHT", 0, 1)

            frame.Flash:SetSize(143, 56)
            frame.Flash:SetTexture(flashTex)
            frame.Flash:SetTexCoord(0.9453125, 0, 0, 0.181640625)
            frame.Flash:ClearAllPoints()
            frame.Flash:SetPoint("TOPLEFT", -10.5, 2.5)

            overlay.Status:SetSize(143, 56)
            overlay.Status:SetTexture(flashTex)
            overlay.Status:SetTexCoord(0.9453125, 0, 0, 0.181640625)
            overlay.Status:ClearAllPoints()
            overlay.Status:SetPoint("TOPLEFT", -10.5, 2.5)
        end)
    end
end

function BBF.ClassicFrames()
    if not BetterBlizzFramesDB.classicFrames then return end
    MakeClassicFrame(TargetFrame)
    MakeClassicFrame(FocusFrame)
    MakeClassicFrame(PlayerFrame)
    MakeClassicFrame(PetFrame)

    MakeClassicPartyFrame()

    AdjustAlternateBars()
    C_Timer.After(1, function()
        if C_AddOns.IsAddOnLoaded("ClassicFrames") then
            C_AddOns.DisableAddOn("ClassicFrames")
        end
    end)
end