function BBF.DruidBlueComboPoints()
    if not BetterBlizzFramesDB.druidOverstacks and not BetterBlizzFramesDB.legacyBlueComboPoints then return end
    if BBF.druidBlueCombos then return end
    if select(2, UnitClass("player")) ~= "DRUID" then return end
    local druid = _G.DruidComboPointBarFrame

    local function CreateChargedPoints(comboPointFrame)
        if not comboPointFrame then return end
        if comboPointFrame.blueOverchargePoints then return end

        local comboPoints = {}
        local visibleComboPoints = 0

        -- Loop through the combo point children and gather visible ones
        for i = 1, comboPointFrame:GetNumChildren() do
            local child = select(i, comboPointFrame:GetChildren())

            -- Only consider shown combo points
            if child:IsShown() then
                visibleComboPoints = visibleComboPoints + 1
                table.insert(comboPoints, child)
            end
        end

        -- Sort the combo points by their layoutIndex
        table.sort(comboPoints, function(a, b)
            return (a.layoutIndex or 0) < (b.layoutIndex or 0)
        end)

        -- Apply textures to the first three combo points
        for i = 1, 3 do
            if comboPoints[i] then
                local comboPoint = comboPoints[i]
                comboPointFrame["ComboPoint"..i] = comboPoint

                -- Create the overlayActive texture and reference it as ChargedFrameActive
                local overlayActive = comboPoint:CreateTexture(nil, "OVERLAY")
                overlayActive:SetAtlas("UF-RogueCP-BG-Anima")
                overlayActive:SetSize(20, 20)
                overlayActive:SetPoint("CENTER", comboPoint, "CENTER")
                comboPoint.ChargedFrameActive = overlayActive

                -- Initially hide the active overlay
                overlayActive:Hide()
            end
        end

        -- Mark as overcharge points if all points are visible
        if visibleComboPoints == 5 then
            comboPointFrame.blueOverchargePoints = true
        end
    end

    CreateChargedPoints(druid)

    -- Function to handle updating combo points based on aura
    local function UpdateComboPoints(self, aura)
        if not self then return end
        if not aura then
            if self.overcharged then
                for i = 1, 3 do
                    local comboPoint = self["ComboPoint"..i]
                    if comboPoint then
                        -- Revert to default combo point and hide the overlay
                        comboPoint.Point_Icon:SetAtlas("UF-DruidCP-Icon")  -- Default Druid combo point
                        comboPoint.Point_Deplete:SetDesaturated(false)
                        comboPoint.Point_Deplete:SetVertexColor(1, 1, 1)
                        comboPoint.Smoke:SetDesaturated(false)
                        comboPoint.Smoke:SetVertexColor(1, 1, 1)
                        comboPoint.FB_Slash:SetDesaturated(false)
                        comboPoint.FB_Slash:SetVertexColor(1, 1, 1)

                        if comboPoint.ChargedFrameActive then
                            comboPoint.ChargedFrameActive:Hide()  -- Hide active overlay
                        end
                    end
                end
                self.overcharged = nil
            end
            return
        end

        for i = 1, 3 do
            local comboPoint = self["ComboPoint"..i]

            if comboPoint then
                if i <= aura.applications then  -- Show blue combo point and active overlay for stacks <= i
                    self.overcharged = true
                    comboPoint.Point_Icon:SetAtlas("UF-RogueCP-Icon-Blue") -- Blue combo point
                    comboPoint.Point_Deplete:SetDesaturated(true)
                    comboPoint.Point_Deplete:SetVertexColor(0, 0, 1)
                    comboPoint.Smoke:SetDesaturated(true)
                    comboPoint.Smoke:SetVertexColor(0, 0, 1)
                    comboPoint.FB_Slash:SetDesaturated(true)
                    comboPoint.FB_Slash:SetVertexColor(0, 0, 1)
                    comboPoint.ChargedFrameActive:Show()  -- Show active overlay
                else  -- Revert to default combo point and hide the overlay for stacks > i
                    comboPoint.Point_Icon:SetAtlas("UF-DruidCP-Icon")  -- Default Druid combo point
                    comboPoint.Point_Deplete:SetDesaturated(false)
                    comboPoint.Point_Deplete:SetVertexColor(1, 1, 1)
                    comboPoint.Smoke:SetDesaturated(false)
                    comboPoint.Smoke:SetVertexColor(1, 1, 1)
                    comboPoint.FB_Slash:SetDesaturated(false)
                    comboPoint.FB_Slash:SetVertexColor(1, 1, 1)
                    comboPoint.ChargedFrameActive:Hide()  -- Hide active overlay
                end
            end
        end
    end

    local function BlueLegacyDruidPoints(aura)
        local frame = ComboFrame
        if not frame or not frame.ComboPoints then return end
        local comboIndex = frame.startComboPointIndex or 2

        for i = 1, 3 do
            local point = frame.ComboPoints[comboIndex]
            if point then
                local isCharged = aura and i <= aura.applications

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

    -- Create a frame to listen to form changes
    local currentForm = GetShapeshiftFormID()
    if currentForm ~= 1 then
        local formWatch = CreateFrame("Frame")
        local function OnFormChanged()
            CreateChargedPoints(druid)
            if druid.blueOverchargePoints then
                formWatch:UnregisterAllEvents()
            end
        end
        formWatch:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        formWatch:SetScript("OnEvent", OnFormChanged)
    end

    druid.auraWatch = CreateFrame("Frame")
    if BetterBlizzFramesDB.legacyBlueComboPoints and C_CVar.GetCVar("comboPointLocation") == "1" and ComboFrame then
        druid.auraWatch:SetScript("OnEvent", function()
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(405189)
            UpdateComboPoints(druid, aura)
            BlueLegacyDruidPoints(aura)
        end)
    else
        druid.auraWatch:SetScript("OnEvent", function()
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(405189)
            UpdateComboPoints(druid, aura)
        end)
    end
    druid.auraWatch:RegisterUnitEvent("UNIT_AURA", "player")
    BBF.druidBlueCombos = true
end

function BBF.DruidAlwaysShowCombos()
    if not BetterBlizzFramesDB.druidAlwaysShowCombos then return end
    if select(2, UnitClass("player")) ~= "DRUID" then return end
    if BBF.DruidAlwaysShowCombosActive then return end
    local frame = DruidComboPointBarFrame

    local function UpdateDruidComboPoints(self)
        if not self then return end
        local form = GetShapeshiftFormID()
        if form == 1 then return end

        local comboPoints = UnitPower("player", self.powerType)

        if comboPoints > 0 then
            self:Show()
        else
            self:Hide()
        end

        for i, point in ipairs(self.classResourceButtonTable) do
            local isFull = i <= comboPoints

            point.Point_Icon:SetAlpha(isFull and 1 or 0)
            point.BG_Active:SetAlpha(isFull and 1 or 0)
            point.BG_Inactive:SetAlpha(isFull and 0 or 1)
            point.Point_Deplete:SetAlpha(0)
        end
    end

    frame:HookScript("OnHide", function(self)
        if UnitPower("player", self.powerType) > 0 then
            self:Show()
        end
    end)

    local listener = CreateFrame("Frame")
    listener:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    listener:SetScript("OnEvent", function(_, _, _, powerType)
        if powerType == "COMBO_POINTS" then
            UpdateDruidComboPoints(frame)
        end
    end)
    BBF.DruidAlwaysShowCombosActive = true
end




local function FormatStatusBarNumber(value)
    local useSmart = BetterBlizzFramesDB.formatStatusBarText
    if useSmart then
        -- Blizzard smart formatting: 4.2 M
        if value >= 1000000 then
            return string.format("%.1f M", value / 1000000)
        elseif value >= 100000 then
            return string.format("%d K", math.floor(value / 1000))
        elseif value >= 10000 then
            return string.format("%.1f K", value / 1000)
        end
    else
        if value >= 1000 then
            return string.format("%d K", math.floor(value / 1000))
        else
            return tostring(value)
        end
    end
end

local moveComboInForm = {
    [1] = true,
    [5] = true,
    -- [31] = true,
    -- [32] = true,
    -- [33] = true,
    -- [34] = true,
    -- [35] = true,
}

local function UpdateAltManaBar(updateCombos, cf)
    local bar = PlayerFrame.AltManaBarBBF
    if not bar then return end

    local form = GetShapeshiftFormID()
    local inNoManaForm = moveComboInForm[form]
    if inNoManaForm then
        local mana = UnitPower("player", Enum.PowerType.Mana)
        local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
        local percent = math.floor((mana / maxMana) * 100 + 0.5)

        bar:SetMinMaxValues(0, maxMana)
        bar:SetValue(mana)

        local display = GetCVar("statusTextDisplay")

        if display == "NONE" then
            bar.TextString:SetText("")
        elseif display == "NUMERIC" then
            bar.TextString:SetText(FormatStatusBarNumber(mana))
        elseif display == "PERCENT" then
            bar.TextString:SetText(percent .. "%")
        elseif display == "BOTH" and bar.LeftText and bar.RightText then
            bar.TextString:SetText("")
            bar.LeftText:SetText(percent .. "%")
            bar.RightText:SetText(FormatStatusBarNumber(mana))
        end

        bar:Show()
        if not cf then
            PlayerFrame.PlayerFrameContainer.FrameTexture:Hide()
            PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:Show()
        end
        if updateCombos then
            if not bar.originalComboPos then
                bar.originalComboPos = {}
                local pts = bar.originalComboPos
                pts.a, pts.b, pts.c, pts.d, pts.e = PlayerFrameBottomManagedFramesContainer:GetPoint()
            end
            local pts = bar.originalComboPos
            PlayerFrameBottomManagedFramesContainer:ClearAllPoints()
            PlayerFrameBottomManagedFramesContainer:SetPoint(pts.a, pts.b, pts.c, pts.d, pts.e-9)
        end
    elseif bar:IsShown() then
        C_Timer.After(0.2, function()
            if updateCombos then
                local pts = bar.originalComboPos
                if pts then
                    PlayerFrameBottomManagedFramesContainer:ClearAllPoints()
                    PlayerFrameBottomManagedFramesContainer:SetPoint(pts.a, pts.b, pts.c, pts.d, pts.e)
                end
            end
            if not cf and not AlternatePowerBar:IsShown() then
                PlayerFrame.PlayerFrameContainer.FrameTexture:Show()
                PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture:Hide()
            end
            bar:Hide()
        end)
    end
end



function BBF.CreateAltManaBar()
    if PlayerFrame.AltManaBarBBF then return end -- already created
    if not BetterBlizzFramesDB.createAltManaBarDruid then return end
    local db = BetterBlizzFramesDB
    if db.useMiniPlayerFrame then return end
    local cf = db.classicFrames

    local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization())
    if specID ~= 105 then
        -- Set up a listener that creates the bar when spec becomes 105 (Restoration)
        if not BBF.AltManaSpecWatcher then
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            f:SetScript("OnEvent", function()
                local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization())
                if specID == 105 then
                    BBF.CreateAltManaBar()
                    f:UnregisterAllEvents()
                    f:SetScript("OnEvent", nil)
                    BBF.AltManaSpecWatcher = nil
                end
            end)
            BBF.AltManaSpecWatcher = f
        end
        return
    end

    local bar = CreateFrame("StatusBar", "AltManaBarBBF", PlayerFrame)
    if cf then
        bar:SetSize(104, 12)
        bar:SetPoint("BOTTOMLEFT", PlayerFrame, "BOTTOMLEFT", 95, 17)
    else
        bar:SetSize(124, 10)
        bar:SetPoint("BOTTOMLEFT", PlayerFrame, "BOTTOMLEFT", 85, 17.5)
    end
    if db.changeUnitFrameManabarTexture then
        bar:SetStatusBarTexture(BBF.manaTexture)
        bar:SetStatusBarColor(0, 0, 1)
    else
        bar:SetStatusBarTexture("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana")
        bar:SetStatusBarColor(1, 1, 1)
    end
    bar:SetMinMaxValues(0, 100)
    bar:Hide()

    bar.overlay = CreateFrame("Frame", nil, bar)
    bar.overlay:SetFrameStrata("DIALOG")

    if cf then
        bar.Background = bar:CreateTexture(nil, "BACKGROUND")
        bar.Background:SetAllPoints()
        bar.Background:SetColorTexture(0, 0, 0, 0.5)

        bar.Border = bar:CreateTexture(nil, "OVERLAY")
        bar.Border:SetSize(0, 16)
        bar.Border:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        bar.Border:SetTexCoord(0.125, 0.250, 1, 0)
        bar.Border:SetPoint("TOPLEFT", 4, 0)
        bar.Border:SetPoint("TOPRIGHT", -4, 0)

        bar.LeftBorder = bar:CreateTexture(nil, "OVERLAY")
        bar.LeftBorder:SetSize(16, 16)
        bar.LeftBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        bar.LeftBorder:SetTexCoord(0, 0.125, 1, 0)
        bar.LeftBorder:SetPoint("RIGHT", bar.Border, "LEFT")

        bar.RightBorder = bar:CreateTexture(nil, "OVERLAY")
        bar.RightBorder:SetSize(16, 16)
        bar.RightBorder:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
        bar.RightBorder:SetTexCoord(0.125, 0, 1, 0)
        bar.RightBorder:SetPoint("LEFT", bar.Border, "RIGHT")
    end

    local display = GetCVar("statusTextDisplay")

    -- Center text like ManaBarText
    local xtraOffset = cf and 0 or 0.5
    bar.TextString = bar.overlay:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    local f,s,o = AlternatePowerBar.TextString:GetFont()
    local a,b,c,d,e = AlternatePowerBar.TextString:GetPoint()
    bar.TextString:SetFont(f,s,o)
    bar.TextString:SetPoint(a,bar,c,d,e-xtraOffset)

    -- Left and Right (only created if BOTH is set)
    if display == "BOTH" then
        bar.LeftText = bar.overlay:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        local f,s,o = AlternatePowerBar.LeftText:GetFont()
        local a,b,c,d,e = AlternatePowerBar.LeftText:GetPoint()
        bar.LeftText:SetFont(f,s,o)
        bar.LeftText:SetPoint(a,bar,c,d,e-xtraOffset)

        bar.RightText = bar.overlay:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        local f,s,o = AlternatePowerBar.RightText:GetFont()
        local a,b,c,d,e = AlternatePowerBar.RightText:GetPoint()
        bar.RightText:SetFont(f,s,o)
        bar.RightText:SetPoint(a,bar,c,d,e-xtraOffset)
    end

    local updateCombos = not (
        (db.moveResource and db.moveResourceStackPos and db.moveResourceStackPos["DRUID"]) or
        (db.moveResourceToTarget and db.moveResourceToTargetDruid)
    )
    local f = CreateFrame("Frame")
    f:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    f:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, evt, unit, ptype)
        if evt == "UNIT_POWER_UPDATE" and ptype ~= "MANA" then return end
        UpdateAltManaBar(updateCombos, cf)
    end)

    if display == "NONE" then
        bar:EnableMouse(true)
        bar:SetScript("OnEnter", function(self)
            local mana = UnitPower("player", Enum.PowerType.Mana)
            local maxMana = UnitPowerMax("player", Enum.PowerType.Mana)
            self.TextString:SetText(BreakUpLargeNumbers(mana) .. " / " .. BreakUpLargeNumbers(maxMana))
        end)

        bar:SetScript("OnLeave", function(self)
            self.TextString:SetText("")
        end)
    end
    PlayerFrame.AltManaBarBBF = bar
    UpdateAltManaBar(updateCombos, cf)
end