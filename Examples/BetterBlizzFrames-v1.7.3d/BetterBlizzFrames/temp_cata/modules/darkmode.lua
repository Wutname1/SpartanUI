local darkModeUi
local darkModeUiAura
local darkModeColor = 1
local auraFilteringOn
local minimapChanged =false

local hookedTotemBar
local hookedAuras
local raidUpdates

local function applySettings(frame, desaturate, colorValue, hook)
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
                        self:SetVertexColor(colorValue, colorValue, colorValue, 1)
                        self.changing = false
                    end)
                end
            end
        end
    end
end

-- Hook function for SetVertexColor
local function OnSetVertexColorHookScript(r, g, b, a)
    return function(frame, _, _, _, _, flag)
        if flag ~= "BBFHookSetVertexColor" then
            frame:SetVertexColor(r, g, b, a, "BBFHookSetVertexColor")
        end
    end
end

-- Function to hook SetVertexColor and keep the color on updates
function BBF.HookVertexColor(frame, r, g, b, a)
    frame:SetVertexColor(r, g, b, a, "BBFHookSetVertexColor")

    if not frame.BBFHookSetVertexColor then
        hooksecurefunc(frame, "SetVertexColor", OnSetVertexColorHookScript(r, g, b, a))
        frame.BBFHookSetVertexColor = true
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

local function UpdateFrameAuras(pool)
    for frame, _ in pairs(pool.activeObjects) do
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

                -- Set the initial border color
                border:SetBackdropBorderColor(darkModeColor, darkModeColor, darkModeColor)
            end
            if frame.Border then
                frame.border:Hide()
            else
                frame.border:Show()
            end
        else
            if frame.Border then
                frame.border:Hide()
            else
                frame.border:Show()
            end
        end
    end
end

function BBF.DarkModeUnitframeBorders()
    -- if (BetterBlizzFramesDB.darkModeUiAura and BetterBlizzFramesDB.darkModeUi) then --and not BetterBlizzFramesDB.playerAuraFiltering) then
    --     if not hookedAuras then
    --         for poolKey, pool in pairs(TargetFrame.auraPools.pools) do
    --             hooksecurefunc(pool, "Acquire", UpdateFrameAuras)
    --             UpdateFrameAuras(pool)
    --         end

    --         for poolKey, pool in pairs(FocusFrame.auraPools.pools) do
    --             hooksecurefunc(pool, "Acquire", UpdateFrameAuras)
    --             UpdateFrameAuras(pool)
    --         end
    --         hookedAuras = true
    --     end
    -- end
end

BBF.auraBorders = {}  -- BuffFrame aura borders for darkmode
local function createOrUpdateBorders(frame, colorValue, textureName, bypass)
    if (darkModeUi and darkModeUiAura) or bypass then
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

            local icon = frame.Icon
            if textureName then
                icon = frame[textureName]
            end
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

local function DesaturateRegionsExcludingIcon(frame, iconTexture, color)
    if not frame then return end

    -- Desaturate all texture regions except the icon texture
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:IsObjectType("Texture") and region ~= iconTexture then
        region:SetDesaturated(true)
        region:SetVertexColor(color, color, color)
        end
    end

    -- Recurse into children
    for _, child in ipairs({ frame:GetChildren() }) do
        DesaturateRegionsExcludingIcon(child, iconTexture, color)
    end
end

function BBF.DarkmodeFrames(bypass)
    if not bypass and not BetterBlizzFramesDB.darkModeUi then return end

    --BBF.AbsorbCaller()
    BBF.CombatIndicatorCaller()

    local desaturationValue = BetterBlizzFramesDB.darkModeUi and true or false
    local vertexColor = BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeColor or 1
    local lighterVertexColor = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.3) or 1
    local druidComboPoint = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.2) or 1
    local druidComboPointActive = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.1) or 1
    local actionBarColor = BetterBlizzFramesDB.darkModeActionBars and (vertexColor + 0.25) or 1
    local birdColor = BetterBlizzFramesDB.darkModeActionBars and (vertexColor + 0.25) or 1
    local rogueCombo = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.45) or 1
    local rogueComboActive = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.30) or 1
    local monkChi = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.10) or 1
    local castbarBorder = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.1) or 1
    local color25 = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.25) or 1

    local minimapColor = (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeMinimap) and BetterBlizzFramesDB.darkModeColor or 1
    local minimapSat = (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeMinimap) and true or false

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

    for i = 1, 4 do
        local totem = _G["TotemFrameTotem" .. i]
        if totem and totem.icon and totem.icon.texture then
            DesaturateRegionsExcludingIcon(totem, totem.icon.texture, vertexColor)
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
    -- if BuffFrame then
    --     for _, frame in pairs({_G.BuffFrame.AuraContainer:GetChildren()}) do
    --         createOrUpdateBorders(frame, vertexColor)
    --     end
    -- end



    -- if ToggleHiddenAurasButton then
    --     createOrUpdateBorders(ToggleHiddenAurasButton, vertexColor)
    -- end

    BBF.DarkModeUnitframeBorders()




    -- Applying settings based on BetterBlizzFramesDB.darkModeUi value
    applySettings(TargetFrameTextureFrameTexture, desaturationValue, vertexColor)
    applySettings(FocusFrameTextureFrameTexture, desaturationValue, vertexColor)
    applySettings(TargetFrameToTTextureFrameTexture, desaturationValue, vertexColor)
    applySettings(PetFrameTexture, desaturationValue, vertexColor)
    applySettings(FocusFrameToTTextureFrameTexture, desaturationValue, vertexColor)

    if TimeManagerClockButton then
        -- Desaturate all textures in ZoomOut button
        for i = 1, TimeManagerClockButton:GetNumRegions() do
            local region = select(i, TimeManagerClockButton:GetRegions())
            if region:IsObjectType("Texture") and region:GetName() ~= "" then
                applySettings(region, minimapSat, minimapColor)
            end
        end
    end

    local function checkAndApplySettings(object, minimapSat, minimapColor)
        if object:IsObjectType("Texture") then
            local texturePath = object:GetTexture()
            if texturePath and string.find(texturePath, "136430") then
                applySettings(object, minimapSat, minimapColor)
            end
        end

        if object.GetNumChildren and object:GetNumChildren() > 0 then
            for i = 1, object:GetNumChildren() do
                local child = select(i, object:GetChildren())
                if not child then return end
                checkAndApplySettings(child, minimapSat, minimapColor)
            end
        end

        if object.GetNumChildren and object:GetNumRegions() > 0 then
            for j = 1, object:GetNumRegions() do
                local region = select(j, object:GetRegions())
                checkAndApplySettings(region, minimapSat, minimapColor)
            end
        end
    end

    for i = 1, MinimapBackdrop:GetNumChildren() do
        local child = select(i, MinimapBackdrop:GetChildren())
        if not child then return end
        checkAndApplySettings(child, minimapSat, minimapColor)
    end

    for i = 1, Minimap:GetNumChildren() do
        local child = select(i, Minimap:GetChildren())
        if not child then return end
        checkAndApplySettings(child, minimapSat, minimapColor)
    end

    for i = 1, TimeManagerClockButton:GetNumChildren() do
        local child = select(i, Minimap:GetChildren())
        for j = 1, child:GetNumRegions() do
            local region = select(j, child:GetRegions())
            if region:IsObjectType("Texture") then
                local texturePath = region:GetTexture()
                if texturePath and string.find(texturePath, "136430") then
                    applySettings(region, minimapSat, minimapColor)
                end
                applySettings(region, minimapSat, minimapColor)
            end
        end
    end


    --Minimap + and - zoom buttons
    local zoomOutButton = MinimapZoomOut
    local zoomInButton = MinimapZoomIn

    -- Desaturate all textures in ZoomOut button
    for i = 1, zoomOutButton:GetNumRegions() do
        local region = select(i, zoomOutButton:GetRegions())
        if region:IsObjectType("Texture") then
            applySettings(region, minimapSat, minimapColor)
        end
    end

    -- Desaturate all textures in ZoomIn button
    for i = 1, zoomInButton:GetNumRegions() do
        local region = select(i, zoomInButton:GetRegions())
        if region:IsObjectType("Texture") then
            applySettings(region, minimapSat, minimapColor)
        end
    end

    local compactPartyBorder = CompactPartyFrameBorderFrame or CompactRaidFrameContainerBorderFrame
    if compactPartyBorder then
        local function ColorCompactUnitFrameBorders(frame, bypass)
            if not frame then return end
            if not bypass and frame.bbfDarkmode then return end
            applySettings(frame.horizDivider, desaturationValue, vertexColor)
            applySettings(frame.horizTopBorder, desaturationValue, vertexColor)
            applySettings(frame.horizBottomBorder, desaturationValue, vertexColor)
            applySettings(frame.vertLeftBorder, desaturationValue, vertexColor)
            applySettings(frame.vertRightBorder, desaturationValue, vertexColor)
            frame.bbfDarkmode = true
        end

        for i = 1, compactPartyBorder:GetNumRegions() do
            local region = select(i, compactPartyBorder:GetRegions())
            if region:IsObjectType("Texture") then
                applySettings(region, desaturationValue, vertexColor)
            end
        end

        for i = 1, 40 do
            local frame = _G["CompactRaidFrame"..i]
            if frame then
                ColorCompactUnitFrameBorders(frame, true)
            end
        end

        if not raidUpdates then
            if C_CVar.GetCVar("raidOptionDisplayPets") == "1" or C_CVar.GetCVar("raidOptionDisplayMainTankAndAssist") == "1" then
                hooksecurefunc("DefaultCompactMiniFrameSetup", function(frame)
                    ColorCompactUnitFrameBorders(frame)
                end)
            end
            hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
                ColorCompactUnitFrameBorders(frame)
            end)
            raidUpdates = true
        end
    end


    -- if BetterBlizzFramesDB.darkModeUiAura then
    --     local BuffFrameButton = BuffFrame.CollapseAndExpandButton
    --     for i = 1, BuffFrameButton:GetNumRegions() do
    --         local region = select(i, BuffFrameButton:GetRegions())
    --         if region:IsObjectType("Texture") then
    --             applySettings(region, desaturationValue, 0.2)
    --         end
    --     end
    -- end

    applySettings(MinimapBorder, minimapSat, minimapColor)

    -- for i = 1, ExpansionLandingPageMinimapButton:GetNumRegions() do
    --     local region = select(i, ExpansionLandingPageMinimapButton:GetRegions())
    --     if region:IsObjectType("Texture") then
    --         applySettings(region, minimapSat, minimapColor)
    --     end
    -- end

    --castbars
    if BetterBlizzFramesDB.darkModeCastbars then
        applySettings(TargetFrame.spellbar.Border, desaturationValue, castbarBorder)
        --applySettings(TargetFrame.spellbar.BorderShield, desaturationValue, vertexColor)
        applySettings(TargetFrame.spellbar.Background, desaturationValue, lighterVertexColor)

        applySettings(FocusFrame.spellbar.Border, desaturationValue, castbarBorder)
        --applySettings(FocusFrame.spellbar.BorderShield, desaturationValue, vertexColor)
        applySettings(FocusFrame.spellbar.Background, desaturationValue, lighterVertexColor)

        applySettings(CastingBarFrame.Border, desaturationValue, castbarBorder)
        --applySettings(CastingBarFrame.BorderShield, desaturationValue, vertexColor)
        applySettings(CastingBarFrame.Background, desaturationValue, lighterVertexColor)
    else
        applySettings(TargetFrame.spellbar.Border, false, 1)
        --applySettings(TargetFrame.spellbar.BorderShield, desaturationValue, vertexColor)
        applySettings(TargetFrame.spellbar.Background, false, 1)

        applySettings(FocusFrame.spellbar.Border, false, 1)
        --applySettings(FocusFrame.spellbar.BorderShield, desaturationValue, vertexColor)
        applySettings(FocusFrame.spellbar.Background, false, 1)

        applySettings(CastingBarFrame.Border, false, 1)
        --applySettings(CastingBarFrame.BorderShield, desaturationValue, vertexColor)
        applySettings(CastingBarFrame.Background, false, 1)
    end



    --applySettings(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon, desaturationValue, vertexColor)

    for _, v in pairs({
        PlayerFrameTexture,
        --PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture,
        --PlayerFrame.PlayerFrameContainer.VehicleFrameTexture,
        -- PartyFrame.MemberFrame1.Texture,
        -- PartyFrame.MemberFrame2.Texture,
        -- PartyFrame.MemberFrame3.Texture,
        -- PartyFrame.MemberFrame4.Texture,
        --PaladinPowerBarFrame.Background,
        --PaladinPowerBarFrame.ActiveTexture,
    }) do
        applySettings(v, desaturationValue, vertexColor)
    end
    -- for _, v in pairs({
    --     PlayerFrameAlternateManaBarLeftBorder,
    --     PlayerFrameAlternateManaBarRightBorder,
    --     PlayerFrameAlternateManaBarBorder,
    -- }) do
    --     applySettings(v, false, vertexColor)  -- Only applying vertex color, desaturation is kept false
    -- end

    -- local runes = _G.RuneFrame
    -- if runes then
    --     for i = 1, 6 do
    --         applySettings(runes["Rune" .. i].BG_Active, desaturationValue, vertexColor)
    --         applySettings(runes["Rune" .. i].BG_Inactive, desaturationValue, vertexColor)
    --     end
    -- end

    -- local nameplateRunes = _G.DeathKnightResourceOverlayFrame
    -- if nameplateRunes and not nameplateRunes:IsForbidden() and not darkModeNpBBP then
    --     local dkNpRunes = darkModeNp and vertexColor or 1
    --     for i = 1, 6 do
    --         applySettings(nameplateRunes["Rune" .. i].BG_Active, darkModeNpSatVal, dkNpRunes)
    --         applySettings(nameplateRunes["Rune" .. i].BG_Inactive, darkModeNpSatVal, dkNpRunes)
    --     end
    -- end

    -- local soulShards = _G.WarlockPowerFrame
    -- if soulShards then
    --     for _, v in pairs({soulShards:GetChildren()}) do
    --         applySettings(v.Background, desaturationValue, vertexColor)
    --     end
    -- end

    -- local soulShardsNameplate = _G.ClassNameplateBarWarlockFrame
    -- if soulShardsNameplate and not soulShardsNameplate:IsForbidden() and not darkModeNpBBP then
    --     local soulShardNp = darkModeNp and vertexColor or 1
    --     for _, v in pairs({soulShardsNameplate:GetChildren()}) do
    --         applySettings(v.Background, darkModeNpSatVal, soulShardNp)
    --     end
    -- end

    -- local druidComboPoints = _G.DruidComboPointBarFrame
    -- if druidComboPoints then
    --     for _, v in pairs({druidComboPoints:GetChildren()}) do
    --         applySettings(v.BG_Inactive, desaturationValue, druidComboPoint)
    --         applySettings(v.BG_Active, desaturationValue, druidComboPointActive)
    --     end
    -- end

    -- local druidComboPointsNameplate = _G.ClassNameplateBarFeralDruidFrame
    -- if druidComboPointsNameplate and not druidComboPointsNameplate:IsForbidden() and not darkModeNpBBP then
    --     local druidComboPointNp = darkModeNp and druidComboPoint or 1
    --     local druidComboPointActiveNp = darkModeNp and druidComboPointActive or 1
    --     for _, v in pairs({druidComboPointsNameplate:GetChildren()}) do
    --         applySettings(v.BG_Inactive, darkModeNpSatVal, druidComboPointNp)
    --         applySettings(v.BG_Active, darkModeNpSatVal, druidComboPointActiveNp)
    --     end
    -- end

    -- local mageArcaneCharges = _G.MageArcaneChargesFrame
    -- if mageArcaneCharges then
    --     for _, v in pairs({mageArcaneCharges:GetChildren()}) do
    --         applySettings(v.ArcaneBG, desaturationValue, actionBarColor)
    --         --applySettings(v.BG_Active, desaturationValue, druidComboPointActive)
    --     end
    -- end

    -- local mageArcaneChargesNameplate = _G.ClassNameplateBarMageFrame
    -- if mageArcaneChargesNameplate and not mageArcaneChargesNameplate:IsForbidden() and not darkModeNpBBP then
    --     local mageChargeNp = darkModeNp and actionBarColor or 1
    --     for _, v in pairs({mageArcaneChargesNameplate:GetChildren()}) do
    --         applySettings(v.ArcaneBG, darkModeNpSatVal, mageChargeNp)
    --         --applySettings(v.BG_Active, desaturationValue, druidComboPointActive)
    --     end
    -- end

    -- local monkChiPoints = _G.MonkHarmonyBarFrame
    -- if monkChiPoints then
    --     for _, v in pairs({monkChiPoints:GetChildren()}) do
    --         applySettings(v.Chi_BG, desaturationValue, monkChi)
    --         applySettings(v.Chi_BG_Active, desaturationValue, monkChi)
    --     end
    -- end

    -- local monkChiPointsNameplate = _G.ClassNameplateBarWindwalkerMonkFrame
    -- if monkChiPointsNameplate and not monkChiPointsNameplate:IsForbidden() and not darkModeNpBBP then
    --     local monkChiNp = darkModeNp and monkChi or 1
    --     for _, v in pairs({monkChiPointsNameplate:GetChildren()}) do
    --         applySettings(v.Chi_BG, darkModeNpSatVal, monkChiNp)
    --         applySettings(v.Chi_BG_Active, darkModeNpSatVal, monkChiNp)
    --     end
    -- end

    -- local rogueComboPoints = _G.RogueComboPointBarFrame
    -- if rogueComboPoints then
    --     for _, v in pairs({rogueComboPoints:GetChildren()}) do
    --         applySettings(v.BGInactive, desaturationValue, rogueCombo)
    --         applySettings(v.BGActive, desaturationValue, rogueComboActive)
    --     end
    -- end

    -- local rogueComboPointsNameplate = _G.ClassNameplateBarRogueFrame
    -- if rogueComboPointsNameplate and not rogueComboPointsNameplate:IsForbidden() and not darkModeNpBBP then
    --     local rogueComboNp = darkModeNp and rogueCombo or 1
    --     local rogueComboActiveNp = darkModeNp and rogueComboActive or 1
    --     for _, v in pairs({rogueComboPointsNameplate:GetChildren()}) do
    --         applySettings(v.BGInactive, darkModeNpSatVal, rogueComboNp)
    --         applySettings(v.BGActive, darkModeNpSatVal, rogueComboActiveNp)
    --     end
    -- end


    -- -- PaladinPowerBarFrame.Background,
    -- -- PaladinPowerBarFrame.ActiveTexture,


    -- local paladinHolyPowerNameplate = _G.ClassNameplateBarPaladinFrame
    -- if paladinHolyPowerNameplate and not paladinHolyPowerNameplate:IsForbidden() and not darkModeNpBBP then
    --     local palaPowerNp = darkModeNp and vertexColor or 1
    --     applySettings(ClassNameplateBarPaladinFrame.Background, darkModeNpSatVal, palaPowerNp)
    --     applySettings(ClassNameplateBarPaladinFrame.ActiveTexture, darkModeNpSatVal, palaPowerNp)
    -- end

    -- local evokerEssencePoints = _G.EssencePlayerFrame
    -- if evokerEssencePoints then
    --     for _, v in pairs({evokerEssencePoints:GetChildren()}) do
    --         applySettings(v.EssenceFillDone.CircBG, desaturationValue, monkChi)
    --         applySettings(v.EssenceFilling.EssenceBG, desaturationValue, vertexColor)
    --         applySettings(v.EssenceEmpty.EssenceBG, desaturationValue, vertexColor)
    --         applySettings(v.EssenceFillDone.CircBGActive, desaturationValue, vertexColor)

    --         applySettings(v.EssenceDepleting.EssenceBG, desaturationValue, vertexColor)
    --         applySettings(v.EssenceDepleting.CircBGActive, desaturationValue, vertexColor)

    --         applySettings(v.EssenceFillDone.RimGlow, desaturationValue, monkChi)
    --         applySettings(v.EssenceDepleting.RimGlow, desaturationValue, monkChi)
    --     end
    -- end

    -- local evokerEssencePointsNameplate = _G.ClassNameplateBarDracthyrFrame
    -- if evokerEssencePointsNameplate and not evokerEssencePointsNameplate:IsForbidden() and not darkModeNpBBP then
    --     local evokerColorOne = darkModeNp and monkChi or 1
    --     local evokerColorTwo = darkModeNp and vertexColor or 1
    --     for _, v in pairs({evokerEssencePointsNameplate:GetChildren()}) do
    --         applySettings(v.EssenceFillDone.CircBG, darkModeNpSatVal, evokerColorOne)
    --         applySettings(v.EssenceFilling.EssenceBG, darkModeNpSatVal, evokerColorTwo)
    --         applySettings(v.EssenceEmpty.EssenceBG, darkModeNpSatVal, evokerColorTwo)
    --         applySettings(v.EssenceFillDone.CircBGActive, darkModeNpSatVal, evokerColorTwo)

    --         applySettings(v.EssenceDepleting.EssenceBG, darkModeNpSatVal, evokerColorTwo)
    --         applySettings(v.EssenceDepleting.CircBGActive, darkModeNpSatVal, evokerColorTwo)

    --         applySettings(v.EssenceFillDone.RimGlow, darkModeNpSatVal, evokerColorOne)
    --         applySettings(v.EssenceDepleting.RimGlow, darkModeNpSatVal, evokerColorOne)
    --     end
    -- end

    -- Actionbars
    for i = 1, 12 do
        local buttons = {
            _G["ActionButton" .. i .. "NormalTexture"],
            _G["MultiBarBottomLeftButton" .. i .. "NormalTexture"],
            _G["MultiBarBottomRightButton" .. i .. "NormalTexture"],
            _G["MultiBarRightButton" .. i .. "NormalTexture"],
            _G["MultiBarLeftButton" .. i .. "NormalTexture"],
            _G["MultiBar5Button" .. i .. "NormalTexture"],
            _G["MultiBar6Button" .. i .. "NormalTexture"],
            _G["MultiBar7Button" .. i .. "NormalTexture"],
            _G["PetActionButton" .. i .. "NormalTexture"],
            _G["StanceButton" .. i .. "NormalTexture"]
        }

        for _, button in ipairs(buttons) do
            applySettings(button, desaturationValue, actionBarColor)
            BBF.HookVertexColor(button, actionBarColor, actionBarColor, actionBarColor, 1)
        end
    end



    for i = 0, 3 do
        local buttons = {
            _G["CharacterBag"..i.."SlotNormalTexture"],
            _G["MainMenuBarTexture"..i],
            _G["MainMenuBarTextureExtender"],
            _G["MainMenuMaxLevelBar"..i],
            _G["ReputationWatchBar"].StatusBar["XPBarTexture"..i],
            _G["MainMenuXPBarTexture"..i],
            _G["SlidingActionBarTexture"..i]
        }
        for _, button in ipairs(buttons) do
            applySettings(button, desaturationValue, actionBarColor)
            BBF.HookVertexColor(button, actionBarColor, actionBarColor, actionBarColor, 1)
        end
    end

    applySettings(MainMenuBarBackpackButtonNormalTexture, desaturationValue, actionBarColor)
    BBF.HookVertexColor(MainMenuBarBackpackButtonNormalTexture, actionBarColor, actionBarColor, actionBarColor, 1)
    

    -- for _, v in pairs({
    --     MainMenuBar.BorderArt,
    --     ActionButton1.RightDivider,
    --     ActionButton2.RightDivider,
    --     ActionButton3.RightDivider,
    --     ActionButton4.RightDivider,
    --     ActionButton5.RightDivider,
    --     ActionButton6.RightDivider,
    --     ActionButton7.RightDivider,
    --     ActionButton8.RightDivider,
    --     ActionButton9.RightDivider,
    --     ActionButton10.RightDivider,
    --     ActionButton11.RightDivider,
    -- }) do
    --     applySettings(v, desaturationValue, actionBarColor)
    -- end

    for _, v in pairs({
        MainMenuBarLeftEndCap,
        MainMenuBarRightEndCap,
    }) do
        applySettings(v, desaturationValue, birdColor)
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

    if PriestBarFrame then
        for i = 1, PriestBarFrame:GetNumRegions() do
            local region = select(i, PriestBarFrame:GetRegions())
            if region and region:IsObjectType("Texture") then
                local tex = region:GetTexture()
                if tex == 593367 then
                    applySettings(region, desaturationValue, vertexColor)
                end
            end
        end
    end


    if MainMenuBarMaxLevelBar then
        for i = 0, 3 do
            local texture = _G["MainMenuMaxLevelBar"..i]
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
        {name = "StanceButton", count = 6},
    }

    -- Loop through each bar and apply settings to its buttons
    for _, bar in ipairs(actionBars) do
        for i = 1, bar.count do
            local button = _G[bar.name .. i]
            if button then
                local normalTexture = button:GetNormalTexture()
                if normalTexture then
                    applySettings(normalTexture, desaturationValue, actionBarColor, true)
                end
            end
        end
    end

    for _, v in pairs({BlizzardArtLeftCap, BlizzardArtRightCap}) do
        if v then
            applySettings(v, desaturationValue, birdColor)
        end
    end

    -- if not hookedTotemBar and darkModeUi then
    --     hooksecurefunc(TotemFrame, "Update", function()
    --         BBF.updateTotemBorders()
    --     end)
    --     hookedTotemBar = true
    -- end
end




function BBF.UpdateFilteredBuffsIcon()
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
                local vertexColor = BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeColor or 1
                local rogueCombo = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.45) or 1
                local rogueComboActive = BetterBlizzFramesDB.darkModeUi and (vertexColor + 0.30) or 1
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
            end
        end
    end
end)

function BBF.CheckForAuraBorders()
    if not (BetterBlizzFramesDB.darkModeUi and BetterBlizzFramesDB.darkModeUiAura) then
        -- Define the maximum number of buffs and debuffs (change these numbers as needed)
        local maxBuffs = 32
        local maxDebuffs = 16

        -- Loop through buffs
        for i = 1, maxBuffs do
            local buffFrame = _G["BuffButton" .. i]
            if buffFrame then
                local iconTexture = _G[buffFrame:GetName() .. "Icon"]
                if iconTexture then
                    local borderColorValue
                    for j = 1, buffFrame:GetNumChildren() do
                        local child = select(j, buffFrame:GetChildren())
                        local bottomEdgeTexture = child.BottomEdge
                        if bottomEdgeTexture and bottomEdgeTexture:IsObjectType("Texture") then
                            local r, g, b, a = bottomEdgeTexture:GetVertexColor()
                            borderColorValue = r
                            break
                        end
                    end
                    if borderColorValue then
                        if ToggleHiddenAurasButton then
                            ToggleHiddenAurasButton.Icon:SetTexCoord(iconTexture:GetTexCoord())
                            createOrUpdateBorders(ToggleHiddenAurasButton, borderColorValue, nil, true)
                            return
                        end
                    end
                end
            end
        end

        -- Loop through debuffs
        for i = 1, maxDebuffs do
            local debuffFrame = _G["DebuffButton" .. i]
            if debuffFrame then
                local iconTexture = _G[debuffFrame:GetName() .. "Icon"]
                if iconTexture then
                    local borderColorValue
                    for j = 1, debuffFrame:GetNumChildren() do
                        local child = select(j, debuffFrame:GetChildren())
                        local bottomEdgeTexture = child.BottomEdge
                        if bottomEdgeTexture and bottomEdgeTexture:IsObjectType("Texture") then
                            local r, g, b, a = bottomEdgeTexture:GetVertexColor()
                            borderColorValue = r
                            break
                        end
                    end
                    if borderColorValue then
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