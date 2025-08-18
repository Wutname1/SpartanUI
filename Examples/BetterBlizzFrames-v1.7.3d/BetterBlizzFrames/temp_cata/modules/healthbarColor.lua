local UnitIsFriend = UnitIsFriend
local UnitIsEnemy = UnitIsEnemy
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass

local LSM = LibStub("LibSharedMedia-3.0")

local healthbarsHooked = nil
local classColorsOn
local colorPetAfterOwner

local function getUnitReaction(unit)
    if UnitIsFriend(unit, "player") then
        return "FRIENDLY"
    elseif UnitIsEnemy(unit, "player") then
        return "HOSTILE"
    else
        return "NEUTRAL"
    end
end

local OnSetPointHookScript = function(point, relativeTo, relativePoint, xOffset, yOffset)
    return function(frame, _, _, _, _, _, flag)
        if flag ~= "BBFHookSetPoint" then
            frame:ClearAllPoints()
            frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset, "BBFHookSetPoint")
        end
    end
end

function BBF.MoveRegion(frame, point, relativeTo, relativePoint, xOffset, yOffset)
    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset, "BBFHookSetPoint")

    if (not frame.BBFHookSetPoint) then
        hooksecurefunc(frame, "SetPoint", OnSetPointHookScript(point, relativeTo, relativePoint, xOffset, yOffset))
        frame.BBFHookSetPoint = true
    end
end

local OnShowHookScript = function()
    return function(frame)
        frame:Hide()
    end
end


local OnSetWidthHookScript = function()
    return function(frame)
        frame:SetWidth(value)
    end
end

function BBF.HideRegion(frame)
    frame:Hide()

    if not frame.BBFHookHide then
        hooksecurefunc(frame, "Show", OnShowHookScript())
        frame.BBFHookHide = true
    end
end

local OnSetWidthHookScript = function(width)
    return function(frame, width, flag)
        if flag ~= "BBFHookSetWidth" then
            frame:SetWidth(width, "BBFHookSetWidth")
        end
    end
end

function BBF.SetRegionWidth(frame, width)
    frame:SetWidth(width, "BBFHookSetWidth")

    if (not frame.BBFHookSetWidth) then
        hooksecurefunc(frame, "SetWidth", OnSetWidthHookScript(width))
        frame.BBFHookSetWidth = true
    end
end


local OnSetHeightHookScript = function(height)
    return function(frame, height, flag)
        if flag ~= "BBFHookSetHeight" then
            frame:SetWidth(height, "BBFHookSetHeight")
        end
    end
end

function BBF.SetRegionHeight(frame, height)
    frame:SetHeight(height, "BBFHookSetHeight")

    if (not frame.BBFHookSetWidth) then
        hooksecurefunc(frame, "SetHeight", OnSetHeightHookScript(height))
        frame.BBFHookSetHeight = true
    end
end


local OnSetSizeHookScript = function(width, height)
    return function(frame, width, height, flag)
        if flag ~= "BBFHookSetSize" then
            frame:SetSize(width, height, "BBFHookSetSize")
        end
    end
end

function BBF.SetRegionSize(frame, width, height)
    frame:SetSize(width, height, "BBFHookSetSize")

    if (not frame.BBFHookSetSize) then
        hooksecurefunc(frame, "SetSize", OnSetSizeHookScript(width, height))
        frame.BBFHookSetSize = true
    end
end



local npcColorCache = {}
local function GetBBPNameplateColor(unit)
    local guid = UnitGUID(unit)
    if not guid then return end

    local npcID = select(6, strsplit("-", guid))
    local npcName = UnitName(unit)
    local lowerCaseNpcName = npcName and strlower(npcName)

    -- First check cache by npcID
    if npcID and npcColorCache[npcID] ~= nil then
        return npcColorCache[npcID]
    end

    -- Fallback to cache by name
    if lowerCaseNpcName and npcColorCache[lowerCaseNpcName] ~= nil then
        return npcColorCache[lowerCaseNpcName]
    end

    local colorNpcList = BetterBlizzPlatesDB.colorNpcList
    local npcHealthbarColor = nil

    for _, npc in ipairs(colorNpcList) do
        if npc.id == tonumber(npcID) or (npc.name and strlower(npc.name) == lowerCaseNpcName) then
            if npc.entryColors then
                npcHealthbarColor = npc.entryColors.text
            else
                npc.entryColors = {}
            end
            break
        end
    end

    -- Cache both ID and name for future use
    if npcID then
        npcColorCache[npcID] = npcHealthbarColor
    end
    if lowerCaseNpcName then
        npcColorCache[lowerCaseNpcName] = npcHealthbarColor
    end

    return npcHealthbarColor
end

local function getUnitColor(unit)
    if not UnitExists(unit) then return end
    if UnitIsPlayer(unit) then
        local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
        if color then
            return {r = color.r, g = color.g, b = color.b}, false
        end
    elseif colorPetAfterOwner and UnitIsUnit(unit, "pet") then
        -- Check if the unit is the player's pet and the setting is enabled
        local _, playerClass = UnitClass("player")
        local color = RAID_CLASS_COLORS[playerClass]
        if color then
            return {r = color.r, g = color.g, b = color.b}, false
        end
    else
        if BetterBlizzPlatesDB and BetterBlizzPlatesDB.colorNPC then
            local npcHealthbarColor = GetBBPNameplateColor(unit)
            if npcHealthbarColor then
                return {r = npcHealthbarColor.r, g = npcHealthbarColor.g, b = npcHealthbarColor.b}, false
            else
                local reaction = getUnitReaction(unit)
                if reaction == "HOSTILE" then
                    if UnitIsTapDenied(unit) then
                        return {r = 0.9, g = 0.9, b = 0.9}, false
                    else
                        return {r = 1, g = 0, b = 0}, false
                    end
                elseif reaction == "NEUTRAL" then
                    if UnitIsTapDenied(unit) then
                        return {r = 0.9, g = 0.9, b = 0.9}, false
                    else
                        return {r = 1, g = 1, b = 0}, false
                    end
                elseif reaction == "FRIENDLY" then
                    return {r = 0, g = 1, b = 0}, true
                end
            end
        else
            local reaction = getUnitReaction(unit)

            if reaction == "HOSTILE" then
                if UnitIsTapDenied(unit) then
                    return {r = 0.9, g = 0.9, b = 0.9}, false
                else
                    return {r = 1, g = 0, b = 0}, false
                end
            elseif reaction == "NEUTRAL" then
                if UnitIsTapDenied(unit) then
                    return {r = 0.9, g = 0.9, b = 0.9}, false
                else
                    return {r = 1, g = 1, b = 0}, false
                end
            elseif reaction == "FRIENDLY" then
                return {r = 0, g = 1, b = 0}, true
            end
        end
    end
end
BBF.getUnitColor = getUnitColor

local function updateFrameColorToggleVer(frame, unit)
    if classColorsOn then
        if unit == "player" and BetterBlizzFramesDB.classColorFramesSkipPlayer then return end
        --local color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or getUnitColor(unit) --bad
        local color = getUnitColor(unit)
        if color then
            frame:SetStatusBarDesaturated(true)
            frame:SetStatusBarColor(color.r, color.g, color.b)
        end
    end
end

BBF.updateFrameColorToggleVer = updateFrameColorToggleVer

local function resetFrameColor(frame, unit)
    frame:SetStatusBarDesaturated(false)
    frame:SetStatusBarColor(0,1,0)
end

local function UpdateHealthColor(frame, unit)
    --local color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or getUnitColor(unit)
    if not frame then return end
    if unit == "player" and BetterBlizzFramesDB.classColorFramesSkipPlayer then return end
    local color = getUnitColor(unit)
    if color then
        frame:SetStatusBarDesaturated(true)
        frame:SetStatusBarColor(color.r, color.g, color.b)
    end
end

function BBF.UpdateToTColor()
    updateFrameColorToggleVer(TargetFrameToTHealthBar, "targettarget")
end

function BBF.UpdateFrames()
    classColorsOn = BetterBlizzFramesDB.classColorFrames
    colorPetAfterOwner = BetterBlizzFramesDB.colorPetAfterOwner
    if C_AddOns.IsAddOnLoaded("DragonflightUI") then
        if not BBF.dfuiHbWarning then
            BBF.dfuiHbWarning = true
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: DragonflightUI is loaded. BBF's \"Class Color Frames\" can potentially be in conflict with Dragonflight UI's settings.")
        end
    end
    if classColorsOn then
        BBF.HookHealthbarColors()
        if UnitExists("player") then updateFrameColorToggleVer(PlayerFrameHealthBar, "player") end
        if UnitExists("target") then updateFrameColorToggleVer(TargetFrameHealthBar, "target") end
        if UnitExists("focus") then updateFrameColorToggleVer(FocusFrameHealthBar, "focus") end
        if UnitExists("targettarget") then updateFrameColorToggleVer(TargetFrameToTHealthBar, "targettarget") end
        if UnitExists("focustarget") then updateFrameColorToggleVer(FocusFrameToTHealthBar, "focustarget") end
        if UnitExists("party1") then updateFrameColorToggleVer(PartyMemberFrame1HealthBar, "party1") end
        if UnitExists("party2") then updateFrameColorToggleVer(PartyMemberFrame2HealthBar, "party2") end
        if UnitExists("party3") then updateFrameColorToggleVer(PartyMemberFrame3HealthBar, "party3") end
        if UnitExists("party4") then updateFrameColorToggleVer(PartyMemberFrame4HealthBar, "party4") end
        BBF.HealthColorOn = true
    else
        if BBF.HealthColorOn then
            if UnitExists("player") then resetFrameColor(PlayerFrameHealthBar, "player") end
            if UnitExists("target") then resetFrameColor(TargetFrameHealthBar, "target") end
            if UnitExists("focus") then resetFrameColor(FocusFrameHealthBar, "focus") end
            if UnitExists("targettarget") then resetFrameColor(TargetFrameToTHealthBar, "targettarget") end
            if UnitExists("focustarget") then resetFrameColor(FocusFrameToTHealthBar, "focustarget") end
            if UnitExists("party1") then resetFrameColor(PartyMemberFrame1HealthBar, "party1") end
            if UnitExists("party2") then resetFrameColor(PartyMemberFrame2HealthBar, "party2") end
            if UnitExists("party3") then resetFrameColor(PartyMemberFrame3HealthBar, "party3") end
            if UnitExists("party4") then resetFrameColor(PartyMemberFrame4HealthBar, "party4") end
            BBF.HealthColorOn = nil
        end
    end
    if colorPetAfterOwner then
        if UnitExists("pet") then updateFrameColorToggleVer(PetFrameHealthBar, "pet") end
    end
end

function BBF.UpdateFrameColor(frame, unit)
    local color = getUnitColor(unit)
    if color then
        frame:SetStatusBarDesaturated(true)
        frame:SetStatusBarColor(color.r, color.g, color.b)
    end
end

function BBF.ClassColorReputation(frame, unit)
    local color = getUnitColor(unit)
    if color then
        frame:SetDesaturated(true)
        frame:SetVertexColor(color.r, color.g, color.b)
    end

    if not frame.bbfColorHook then
        hooksecurefunc(frame, "SetVertexColor", function(self)
            if self.changing then return end
            self.changing = true
            local color = getUnitColor(unit)
            if color then
                frame:SetDesaturated(true)
                frame:SetVertexColor(color.r, color.g, color.b)
            end
            self.changing = false
        end)
        frame.bbfColorHook = true
    end
end

function BBF.ClassColorReputationCaller()
    if BetterBlizzFramesDB.classColorTargetReputationTexture then
        BBF.ClassColorReputation(TargetFrameNameBackground, "target")
    end

    if BetterBlizzFramesDB.classColorFocusReputationTexture then
        BBF.ClassColorReputation(FocusFrameNameBackground, "focus")
    end
end

function BBF.ResetClassColorReputation(frame, unit)
    local color = getUnitColor(unit)
    if color then
        frame:SetDesaturated(false)
        frame:SetVertexColor(UnitSelectionColor(unit))
    end
end

function BBF.HookHealthbarColors()
    if not healthbarsHooked and classColorsOn then
--[[
        hooksecurefunc("UnitFrameHealthBar_RefreshUpdateEvent", function(self) --pet frames only?
            if self.unit then
                print(self:GetName())
                print(self.unit)
                --UpdateHealthColor(self, self.unit)
                --UpdateHealthColor(TargetFrameToTHealthBar, "targettarget")
                --UpdateHealthColor(FocusFrameToT.HealthBar, "focustarget")
            end
        end)
]]


        hooksecurefunc("UnitFrameHealthBar_Update", function(self, unit)
            if unit then
                UpdateHealthColor(self, unit)
                UpdateHealthColor(TargetFrameToTHealthBar, "targettarget")
                UpdateHealthColor(FocusFrameToTHealthBar, "focustarget")
            end
        end)


        hooksecurefunc("HealthBar_OnValueChanged", function(self)
            if self.unit then
                UpdateHealthColor(self, self.unit)
                UpdateHealthColor(TargetFrameToTHealthBar, "targettarget")
                UpdateHealthColor(FocusFrameToTHealthBar, "focustarget")
            end
        end)



        healthbarsHooked = true
    end
end

function BBF.PlayerReputationColor()
    if BetterBlizzFramesDB.biggerHealthbars then return end
    BBF.HookAndDo(PlayerFrameBackground, "SetSize", function(frame, width, height, flag)
        frame:SetSize(120, 41, flag)
    end)
    PlayerFrameBackground:SetSize(120, 41)
    if not BBF.reputationFrame then
        -- Create the new frame and texture
        local reputationFrame = CreateFrame("Frame", "PlayerReputationFrame", PlayerFrame)
        reputationFrame:SetFrameStrata("LOW")
        reputationFrame:SetSize(119, 19)
        reputationFrame:SetPoint("TOP", PlayerFrameBackground, "TOP")

        local reputationTexture = reputationFrame:CreateTexture(nil, "ARTWORK")
        reputationTexture:SetAllPoints(reputationFrame)
        reputationFrame.texture = reputationTexture

        BBF.reputationFrame = reputationFrame
        BBF.reputationTexture = reputationTexture
    end

    local reputationFrame = BBF.reputationFrame
    local reputationTexture = BBF.reputationTexture

    if BetterBlizzFramesDB.playerReputationColor and not BetterBlizzFramesDB.biggerHealthbars then
        reputationFrame:Show()
        if BetterBlizzFramesDB.playerReputationClassColor then
            local color = getUnitColor("player")
            if color then
                reputationFrame:SetSize(119, 19)
                reputationTexture:SetTexture(137017)
                reputationTexture:SetDesaturated(true)
                reputationTexture:SetVertexColor(color.r, color.g, color.b)
                reputationTexture:SetTexCoord(0, 1, 0, 1)
            end
        else
            reputationTexture:SetTexture(137017)
            reputationTexture:SetDesaturated(false)
            local r, g, b = UnitSelectionColor("player")
            reputationTexture:SetVertexColor(r, g, b)
            reputationTexture:SetTexCoord(0, 1, 0, 1)
        end
    else
        reputationFrame:Hide()
    end
end

local biggerHealthbarHooked
local frameTextureHooked
function BBF.BiggerHealthbars(frame, name)
    local texture = _G[frame.."Texture"] or _G[frame.."TextureFrameTexture"]
    local playerGlowTexture = _G["PlayerStatusTexture"]
    local healthbar = _G[frame.."HealthBar"]
    local manabar = _G[frame.."ManaBar"]
    local leftText = _G[frame.."HealthBarTextLeft"] or _G[frame].textureFrame.HealthBarTextLeft
    local leftTextMana = _G[frame].textureFrame and _G[frame].textureFrame.ManaBarTextLeft
    local rightText = _G[frame.."HealthBarTextRight"] or _G[frame].textureFrame.HealthBarTextRight
    local centerText = _G[frame.."HealthBarText"] or _G[frame].textureFrame.HealthBarText
    local nameBackground = _G[frame.."NameBackground"]
    local background = _G[frame.."Background"]
    local deadText = _G[frame.."TextureFrameDeadText"]

    local targetTexture = BetterBlizzFramesDB.hideLevelTextAlways and "Interface\\Addons\\BetterBlizzFrames\\media\\UI-TargetingFrame-NoLevel" or "Interface\\Addons\\BetterBlizzFrames\\media\\UI-TargetingFrame"
    -- Texture
    texture:SetTexture(targetTexture)
    playerGlowTexture:SetTexture("Interface\\Addons\\BetterBlizzFrames\\media\\UI-Player-Status")
    hooksecurefunc(playerGlowTexture, "SetTexture", 
        function(self, texture)
            if texture ~= "Interface\\Addons\\BetterBlizzFrames\\media\\UI-Player-Status" then
                self:SetTexture("Interface\\Addons\\BetterBlizzFrames\\media\\UI-Player-Status")
                playerGlowTexture:SetHeight(69)
            end
        end
    )
    playerGlowTexture:SetHeight(69)

    -- Healthbar
    local point, relativeTo, relativePoint, xOfs, yOfs = healthbar:GetPoint()
    local newYOffset = yOfs + 18
    BBF.MoveRegion(healthbar, point, relativeTo, relativePoint, xOfs, newYOffset)
    healthbar:SetHeight(29)
    if not BetterBlizzFramesDB.changeUnitFrameHealthbarTexture then
        healthbar:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, "Smooth"))
    end

    BBF.SetRegionWidth(manabar, 120)
    --BBF.SetRegionSize(manabar, 120, 12)

    if nameBackground then
        BBF.HideRegion(nameBackground)
        -- nameBackground:Hide()
        -- nameBackground:SetAlpha(0)
    end
    if background then
    -- background:SetHeight(41)
    -- background:SetWidth(120)
        -- BBF.SetRegionHeight(background, 41)
        -- BBF.SetRegionWidth(background, 120)
        BBF.HookAndDo(background, "SetSize", function(frame, width, height, flag)
            frame:SetSize(120, 42, flag)
        end)
        hooksecurefunc(background, "SetPoint", function(self, point, relativeTo, relativePoint, xOffset, yOffset)
            if yOffset and yOffset ~= 47 then return end
            if self.changing then return end
            self.changing = true
            self:SetPoint(point, relativeTo, relativePoint, xOffset, (yOffset or 0) - 12)
            self.changing = false
        end)

        -- BBF.HookAndDo(background, "SetWidth", function(frame, width, height, flag)
        --     frame:SetWidth(119, 42, flag)
        -- end)
        -- if not background.bbfHooked then
        --     hooksecurefunc("PlayerFrame_UpdateArt", function()
        --         background:SetWidth(120)
        --     end)
        --     background.bbfHooked = true
        -- end
        --BBF.SetRegionWidth(background, 120)
        --BBF.SetRegionSize(background, 120, 41)
    end

    if BetterBlizzFramesDB.biggerHealthbarsNameInside then
        if deadText then
            local point, relativeTo, relativePoint, xOfs, yOfs = deadText:GetPoint()
            local newYOffset = yOfs + 4
            BBF.MoveRegion(deadText, point, relativeTo, relativePoint, xOfs, newYOffset)
        end

        -- Name
        local point, relativeTo, relativePoint, xOfs, yOfs = name:GetPoint()
        local newYOffset = yOfs + 1
        BBF.MoveRegion(name, point, relativeTo, relativePoint, xOfs, newYOffset)


        -- Statustext
        if leftTextMana then
            local point, relativeTo, relativePoint, xOfs, yOfs = leftTextMana:GetPoint()
            local newXOffset = xOfs + 1
            BBF.MoveRegion(leftTextMana, point, relativeTo, relativePoint, newXOffset, yOfs)
        end
        local point, relativeTo, relativePoint, xOfs, yOfs = leftText:GetPoint()
        local newYOffset = yOfs + 4
        local newXOffset = xOfs + 1
        if not leftTextMana then
            BBF.MoveRegion(leftText, point, relativeTo, relativePoint, xOfs, newYOffset)
        else
            BBF.MoveRegion(leftText, point, relativeTo, relativePoint, newXOffset, newYOffset)
        end

        local point, relativeTo, relativePoint, xOfs, yOfs = rightText:GetPoint()
        local newYOffset = yOfs + 4
        BBF.MoveRegion(rightText, point, relativeTo, relativePoint, xOfs, newYOffset)

        local point, relativeTo, relativePoint, xOfs, yOfs = centerText:GetPoint()
        local newYOffset = yOfs + 4
        BBF.MoveRegion(centerText, point, relativeTo, relativePoint, xOfs, newYOffset)
    else
        if deadText then
            local point, relativeTo, relativePoint, xOfs, yOfs = deadText:GetPoint()
            local newYOffset = yOfs + 10
            BBF.MoveRegion(deadText, point, relativeTo, relativePoint, xOfs, newYOffset)
        end

        -- Name
        local point, relativeTo, relativePoint, xOfs, yOfs = name:GetPoint()
        local newYOffset = yOfs + 17
        BBF.MoveRegion(name, point, relativeTo, relativePoint, xOfs, newYOffset)


        -- Statustext
        if leftTextMana then
            local point, relativeTo, relativePoint, xOfs, yOfs = leftTextMana:GetPoint()
            local newXOffset = xOfs + 1
            BBF.MoveRegion(leftTextMana, point, relativeTo, relativePoint, newXOffset, yOfs)
        end
        local point, relativeTo, relativePoint, xOfs, yOfs = leftText:GetPoint()
        local newYOffset = yOfs + 9
        local newXOffset = xOfs + 1
        if not leftTextMana then
            BBF.MoveRegion(leftText, point, relativeTo, relativePoint, xOfs, newYOffset)
        else
            BBF.MoveRegion(leftText, point, relativeTo, relativePoint, newXOffset, newYOffset)
        end

        local point, relativeTo, relativePoint, xOfs, yOfs = rightText:GetPoint()
        local newYOffset = yOfs + 9
        BBF.MoveRegion(rightText, point, relativeTo, relativePoint, xOfs, newYOffset)

        local point, relativeTo, relativePoint, xOfs, yOfs = centerText:GetPoint()
        local newYOffset = yOfs + 9
        BBF.MoveRegion(centerText, point, relativeTo, relativePoint, xOfs, newYOffset)
    end

    if not frameTextureHooked then
        hooksecurefunc("TargetFrame_CheckClassification", function(frame)
            if not frame or not frame.unit then return end
            local classification = UnitClassification(frame.unit);
        
            if BetterBlizzFramesDB.biggerHealthbars then
                if (classification == "minus") then
                    -- frame.borderTexture:SetTexture(Media:Fetch("frames", "minus"));
                    -- frame.nameBackground:Hide();
                    -- frame.Background:SetHeight(31)
                    -- frame.manabar:Hide();
                    -- frame.manabar.TextString:Hide();
                    -- forceNormalTexture = true;
                    frame.borderTexture:SetTexture("Interface\\Addons\\BetterBlizzFrames\\media\\UI-TargetingFrame-Minus")
                elseif (classification == "worldboss" or classification == "elite") then
                    frame.borderTexture:SetTexture("Interface\\Addons\\BetterBlizzFrames\\media\\UI-TargetingFrame-Elite")
                elseif (classification == "rareelite") then
                    frame.borderTexture:SetTexture("Interface\\Addons\\BetterBlizzFrames\\media\\UI-TargetingFrame-Rare-Elite")
                elseif (classification == "rare") then
                    frame.borderTexture:SetTexture("Interface\\Addons\\BetterBlizzFrames\\media\\UI-TargetingFrame-Rare")
                else
                    frame.borderTexture:SetTexture(targetTexture)
                end
            end
        end)
        frameTextureHooked = true

        -- Hide LTP Name background
        for i = 1, PlayerFrame:GetNumChildren() do
            local child = select(i, PlayerFrame:GetChildren())
            if child and child:IsObjectType("Frame") and not child:GetName() then
                for j = 1, child:GetNumRegions() do
                    local region = select(j, child:GetRegions())
                    if region and region:IsObjectType("Texture") then
                        local texture = region:GetTexture()
                        if texture == 137017 then
                        region:SetTexture(nil)
                        end
                    end
                end
            end
        end
    end
end

function BBF.HookBiggerHealthbars()
    if C_AddOns.IsAddOnLoaded("DragonflightUI") then
        if not BBF.DFUIUnsupported then
            print("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames: Bigger Healthbars is not supported with DragonflightUI")
            BBF.DFUIUnsupported = true
        end
        return
    end
    if BetterBlizzFramesDB.biggerHealthbars and not biggerHealthbarHooked then
        local playerName = PlayerFrame.bbfName or PlayerName
        local targetName = TargetFrame.bbfName or TargetFrameTextureFrameName
        local focusName = FocusFrame.bbfName or FocusFrameTextureFrameName
        BBF.BiggerHealthbars("PlayerFrame", playerName)
        BBF.BiggerHealthbars("TargetFrame", targetName)
        BBF.BiggerHealthbars("FocusFrame",focusName)

        -- BBF.BiggerHealthbars("PlayerFrame", PlayerName)
        -- BBF.BiggerHealthbars("TargetFrame", TargetFrameTextureFrameName)
        -- BBF.BiggerHealthbars("FocusFrame", FocusFrameTextureFrameName)

        biggerHealthbarHooked = true
    end
end

--TargetFrame.textureFrame.HealthBarTextRight

--PlayerFrameHealthBar   PlayerFrameHealthBarTextRight
--/run BBF.LargeUnitFrameHealthbars("PlayerFrame", PlayerName)

--PlayerName