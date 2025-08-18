local UnitIsFriend = UnitIsFriend
local UnitIsEnemy = UnitIsEnemy
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitIsUnit = UnitIsUnit

local healthbarsHooked = nil
local classColorsOn
local colorPetAfterOwner
local skipPlayer
local retexturedBars
local rpNames

local OnSetVertexColorHookScript = function(r, g, b, a)
    return function(frame, red, green, blue, alpha, flag)
        if flag ~= "BBFHookSetVertexColor" then
            frame:SetVertexColor(r, g, b, a, "BBFHookSetVertexColor")
        end
    end
end

function BBF.SetVertexColor(frame, r, g, b, a)
    frame:SetVertexColor(r, g, b, a, "BBFHookSetVertexColor")

    if (not frame.BBFHookSetVertexColor) then
        hooksecurefunc(frame, "SetVertexColor", OnSetVertexColorHookScript(r, g, b, a))
        frame.BBFHookSetVertexColor = true
    end
end

local function getUnitReaction(unit)
    if UnitIsFriend(unit, "player") then
        return "FRIENDLY"
    elseif UnitIsEnemy(unit, "player") then
        return "HOSTILE"
    else
        return "NEUTRAL"
    end
end

local function GetRPNameColor(unit)
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
        if TRP3_API and rpNames then
            local r,g,b = GetRPNameColor(unit)
            if r then
                return {r = r, g = g, b = b}, false
            else
                local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
                if color then
                    return {r = color.r, g = color.g, b = color.b}, false
                end
            end
        else
            local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
            if color then
                return {r = color.r, g = color.g, b = color.b}, false
            end
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
    if not frame then return end
    if not frame.SetStatusBarDesaturated then return end
    if unit == "player" and skipPlayer then
        if retexturedBars then
            frame:SetStatusBarColor(0, 1, 0)
        end
        return
    end
    if classColorsOn then
        local color, isFriendly = getUnitColor(unit)
        if color then
            if isFriendly and not frame.bbfChangedTexture then
                frame:SetStatusBarDesaturated(false)
                frame:SetStatusBarColor(1, 1, 1)
            else
                frame:SetStatusBarDesaturated(true)
                frame:SetStatusBarColor(color.r, color.g, color.b)
            end
        end
    end
end

BBF.updateFrameColorToggleVer = updateFrameColorToggleVer

local function resetFrameColor(frame, unit)
    if frame.bbfChangedTexture then
        frame:SetStatusBarDesaturated(false)
        frame:SetStatusBarColor(1,1,1)
    else
        frame:SetStatusBarDesaturated(true)
        frame:SetStatusBarColor(0,1,0)
    end
end

local validUnits = {
    player = true,
    target = true,
    targettarget = true,
    focus = true,
    focustarget = true,
    pet = true,
    party1 = true,
    party2 = true,
    party3 = true,
    party4 = true,
}

local function UpdateHealthColor(frame, unit)
    if not validUnits[unit] then return end
    if unit == "player" and skipPlayer then
        if retexturedBars then
            frame:SetStatusBarColor(0, 1, 0)
        end
        return
    end
    local color, isFriendly = getUnitColor(unit)
    if color then
        if isFriendly and not frame.bbfChangedTexture then
            frame:SetStatusBarDesaturated(false)
            frame:SetStatusBarColor(1, 1, 1)
        else
            frame:SetStatusBarDesaturated(true)
            frame:SetStatusBarColor(color.r, color.g, color.b)
        end
    end
end

local function UpdateHealthColorCF(frame, unit)
    if unit == "player" and BetterBlizzFramesDB.classColorFramesSkipPlayer then return end
    local color, isFriendly = getUnitColor(unit)
    if color then
        --frame:SetStatusBarDesaturated(true)
        frame:SetStatusBarColor(color.r, color.g, color.b)
    end
end

function BBF.UpdateToTColor()
    updateFrameColorToggleVer(TargetFrameToT.HealthBar, "targettarget")
end

function BBF.UpdateFrames()
    classColorsOn = BetterBlizzFramesDB.classColorFrames
    retexturedBars = BetterBlizzFramesDB.changeUnitFrameHealthbarTexture
    colorPetAfterOwner = BetterBlizzFramesDB.colorPetAfterOwner
    skipPlayer = BetterBlizzFramesDB.classColorFramesSkipPlayer
    rpNames = BetterBlizzFramesDB.rpNamesHealthbarColor
    if classColorsOn then
        BBF.HookHealthbarColors()
        if UnitExists("player") then updateFrameColorToggleVer(PlayerFrame.healthbar, "player") end
        if UnitExists("target") then updateFrameColorToggleVer(TargetFrame.healthbar, "target") end
        if UnitExists("focus") then updateFrameColorToggleVer(FocusFrame.healthbar, "focus") end
        if UnitExists("targettarget") then updateFrameColorToggleVer(TargetFrameToT.HealthBar, "targettarget") end
        if UnitExists("focustarget") then updateFrameColorToggleVer(FocusFrameToT.HealthBar, "focustarget") end
        if UnitExists("party1") then updateFrameColorToggleVer(PartyFrame.MemberFrame1.HealthBarContainer.HealthBar, "party1") end
        if UnitExists("party2") then updateFrameColorToggleVer(PartyFrame.MemberFrame2.HealthBarContainer.HealthBar, "party2") end
        if UnitExists("party3") then updateFrameColorToggleVer(PartyFrame.MemberFrame3.HealthBarContainer.HealthBar, "party3") end
        if UnitExists("party4") then updateFrameColorToggleVer(PartyFrame.MemberFrame4.HealthBarContainer.HealthBar, "party4") end
        BBF.HealthColorOn = true
    else
        if BBF.HealthColorOn then
            if UnitExists("player") then resetFrameColor(PlayerFrame.healthbar, "player") end
            if UnitExists("target") then resetFrameColor(TargetFrame.healthbar, "target") end
            if UnitExists("focus") then resetFrameColor(FocusFrame.healthbar, "focus") end
            if UnitExists("targettarget") then resetFrameColor(TargetFrameToT.HealthBar, "targettarget") end
            if UnitExists("focustarget") then resetFrameColor(FocusFrameToT.HealthBar, "focustarget") end
            if UnitExists("party1") then resetFrameColor(PartyFrame.MemberFrame1.HealthBarContainer.HealthBar, "party1") end
            if UnitExists("party2") then resetFrameColor(PartyFrame.MemberFrame2.HealthBarContainer.HealthBar, "party2") end
            if UnitExists("party3") then resetFrameColor(PartyFrame.MemberFrame3.HealthBarContainer.HealthBar, "party3") end
            if UnitExists("party4") then resetFrameColor(PartyFrame.MemberFrame4.HealthBarContainer.HealthBar, "party4") end
            BBF.HealthColorOn = nil
        end
    end
    if colorPetAfterOwner then
        if UnitExists("pet") then updateFrameColorToggleVer(PetFrame.healthbar, "pet") end
    end
end

function BBF.UpdateFrameColor(frame, unit)
    local color, isFriendly = getUnitColor(unit)
    if color then
        if isFriendly and not frame.bbfChangedTexture then
            frame:SetStatusBarDesaturated(false)
            frame:SetStatusBarColor(1, 1, 1)
        else
            frame:SetStatusBarDesaturated(true)
            frame:SetStatusBarColor(color.r, color.g, color.b)
        end
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
        BBF.ClassColorReputation(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "target")
    end

    if BetterBlizzFramesDB.classColorFocusReputationTexture then
        BBF.ClassColorReputation(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "focus")
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
                --UpdateHealthColor(TargetFrameToT.HealthBar, "targettarget")
                --UpdateHealthColor(FocusFrameToT.HealthBar, "focustarget")
            end
        end)
]]
        local function HookCfSetStatusBarColor(frame, unit)
            if not frame.SetStatusBarColorHooked then
                hooksecurefunc(frame, "SetStatusBarColor", function(self, r, g, b, a)
                    if not frame.recoloring then
                        frame.recoloring = true
                        local color = getUnitColor(unit)
                        if color then
                            frame:SetStatusBarColor(color.r, color.g, color.b)
                        end
                        frame.recoloring = false
                    end
                end)
                local color = getUnitColor(unit)
                if color then
                    frame:SetStatusBarColor(color.r, color.g, color.b)
                end
                frame.SetStatusBarColorHooked = true
            end
        end

        if C_AddOns.IsAddOnLoaded("ClassicFrames") then
            hooksecurefunc("UnitFrameHealthBar_Update", function(self, unit)
                if unit then
                    UpdateHealthColorCF(TargetFrameToT.HealthBar, "targettarget")
                    UpdateHealthColorCF(FocusFrameToT.HealthBar, "focustarget")
                end
            end)
            if CfPlayerFrameHealthBar then
                if not BetterBlizzFramesDB.classColorFramesSkipPlayer then
                    HookCfSetStatusBarColor(CfPlayerFrameHealthBar, "player")
                end
                HookCfSetStatusBarColor(CfTargetFrameHealthBar, "target")
                HookCfSetStatusBarColor(CfFocusFrameHealthBar, "focus")
            else
                print("ClassicFrames healthbars not detected. Please report to dev @bodify")
            end
        else
            hooksecurefunc("UnitFrameHealthBar_Update", function(self, unit)
                if unit then
                    UpdateHealthColor(self, unit)
                    UpdateHealthColor(TargetFrameToT.HealthBar, "targettarget")
                    UpdateHealthColor(FocusFrameToT.HealthBar, "focustarget")
                end
            end)
        end

        if BetterBlizzFramesDB.rpNamesHealthbarColor and TRP3_API then
            local function UpdateHealthColorWithRPName(frame)
                if not frame or not frame.unit or frame.unit:find("nameplate") or frame:IsForbidden() then return end

                local r, g, b = GetRPNameColor(frame.unit)
                if r then
                    frame.healthBar:SetStatusBarColor(r, g, b)
                    frame.recolored = true
                elseif frame.recolored then
                    local color = RAID_CLASS_COLORS[select(2, UnitClass(frame.unit))]
                    if color then
                        frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
                    end
                    frame.recolored = nil
                end
            end

            hooksecurefunc("CompactUnitFrame_UpdateHealthColor", UpdateHealthColorWithRPName)

            -- Run once on existing party/raid frames
            local function ApplyRPColorsToPartyFrames()
                for i = 1, 4 do
                    local frame = _G["CompactPartyFrameMember" .. i]
                    if frame and frame:IsShown() then
                        UpdateHealthColorWithRPName(frame)
                    end
                end
            end

            ApplyRPColorsToPartyFrames()
        end

--[[
        hooksecurefunc("HealthBar_OnValueChanged", function(self)
            if self.unit then
                UpdateHealthColor(self, self.unit)
                print(self:GetName())
                print(self.unit)
                --UpdateHealthColor(TargetFrameToT.HealthBar, "targettarget")
                --UpdateHealthColor(FocusFrameToT.HealthBar, "focustarget")
            end
        end)

]]

        healthbarsHooked = true
    elseif not healthbarsHooked and BetterBlizzFramesDB.rpNamesHealthbarColor and TRP3_API then
        retexturedBars = BetterBlizzFramesDB.changeUnitFrameHealthbarTexture
        local function UpdateHealthColorWithRPName(frame)
            if not frame or not frame.unit or frame.unit:find("nameplate") or frame:IsForbidden() then return end

            local r, g, b = GetRPNameColor(frame.unit)
            if r then
                frame.healthBar:SetStatusBarColor(r, g, b)
                frame.recolored = true
            elseif frame.recolored then
                local color = RAID_CLASS_COLORS[select(2, UnitClass(frame.unit))]
                if color then
                    frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
                end
                frame.recolored = nil
            end
        end

        hooksecurefunc("CompactUnitFrame_UpdateHealthColor", UpdateHealthColorWithRPName)

        -- Run once on existing party/raid frames
        local function ApplyRPColorsToPartyFrames()
            for i = 1, 4 do
                local frame = _G["CompactPartyFrameMember" .. i]
                if frame and frame:IsShown() then
                    UpdateHealthColorWithRPName(frame)
                end
            end
        end

        ApplyRPColorsToPartyFrames()

        local function getRPUnitColor(unit)
            local r,g,b = GetRPNameColor(unit)
            if r then
                return {r = r, g = g, b = b}
            end
        end

        local function UpdateRPHealthColor(frame, unit)
            if not validUnits[unit] then return end
            if UnitIsPlayer(unit) then
                local color = getRPUnitColor(unit)
                if color then
                    frame:SetStatusBarDesaturated(true)
                    frame:SetStatusBarColor(color.r, color.g, color.b)
                else
                    if retexturedBars then
                        frame:SetStatusBarDesaturated(true)
                        frame:SetStatusBarColor(0, 1, 0)
                    else
                        frame:SetStatusBarDesaturated(false)
                        frame:SetStatusBarColor(1, 1, 1)
                    end
                end
            else
                if retexturedBars then
                    frame:SetStatusBarDesaturated(true)
                    frame:SetStatusBarColor(0, 1, 0)
                else
                    frame:SetStatusBarDesaturated(false)
                    frame:SetStatusBarColor(1, 1, 1)
                end
            end
        end

        hooksecurefunc("UnitFrameHealthBar_Update", function(self, unit)
            if unit then
                UpdateRPHealthColor(self, unit)
                UpdateRPHealthColor(TargetFrameToT.HealthBar, "targettarget")
                UpdateRPHealthColor(FocusFrameToT.HealthBar, "focustarget")
            end
        end)

        UpdateRPHealthColor(PlayerFrame.healthbar, "player")
        if UnitExists("target") then
            UpdateRPHealthColor(TargetFrame.healthbar, "target")
        end
        if UnitExists("focus") then
            UpdateRPHealthColor(FocusFrame.healthbar, "focus")
        end
        C_Timer.After(1, function()
            UpdateRPHealthColor(PlayerFrame.healthbar, "player")
        end)

        healthbarsHooked = true
    end
end


function BBF.PlayerReputationColor()
    local frame = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
    if BetterBlizzFramesDB.playerReputationColor then
        if not frame.ReputationColor then
            frame.ReputationColor = frame:CreateTexture(nil, "OVERLAY")
            if BetterBlizzFramesDB.classicFrames then
                frame.ReputationColor:SetTexture(137017)
                frame.ReputationColor:SetSize(117, 18)
                frame.ReputationColor:SetTexCoord(1, 0, 0, 1)
                frame.ReputationColor:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -30)
            elseif C_AddOns.IsAddOnLoaded("ClassicFrames") then
                frame.ReputationColor:SetTexture(137017)
                frame.ReputationColor:SetSize(117, 19)
                frame.ReputationColor:SetTexCoord(1, 0, 0, 1)
                frame.ReputationColor:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -26, -26)
            else
                frame.ReputationColor:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Type")
                frame.ReputationColor:SetSize(136, 20)
                frame.ReputationColor:SetTexCoord(1, 0, 0, 1)
                frame.ReputationColor:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -21, -25)
            end
        else
            frame.ReputationColor:Show()
        end
        if BetterBlizzFramesDB.playerReputationClassColor then
            local color = getUnitColor("player")
            if color then
                frame.ReputationColor:SetDesaturated(true)
                frame.ReputationColor:SetVertexColor(color.r, color.g, color.b)
            end
        else
            frame.ReputationColor:SetDesaturated(false)
            frame.ReputationColor:SetVertexColor(UnitSelectionColor("player"))
        end
    else
        if frame.ReputationColor then
            frame.ReputationColor:Hide()
        end
    end
end




function BBF.HookFrameTextureColor()
    if BBF.FrameTextureColor then return end
    local classColorFrameTexture = BetterBlizzFramesDB.classColorFrameTexture
    local rpColor = BetterBlizzFramesDB.rpNamesFrameTextureColor
    if not classColorFrameTexture and not rpColor then return end

    local darkmode = BetterBlizzFramesDB.darkModeUi
    local darkmodeColor = BetterBlizzFramesDB.darkModeColor


    local function DesaturateAndColorTexture(texture, unit)
        if not UnitExists(unit) then return end

        local color = darkmode and darkmodeColor or 1
        local r, g, b = color, color, color
        local desaturate = darkmode and true or false
        local colored = false

        if UnitIsPlayer(unit) then
            if TRP3_API and rpColor then
                local rpR, rpG, rpB = GetRPNameColor(unit)
                if rpR then
                    r, g, b = rpR, rpG, rpB
                    desaturate = true
                    colored = true
                end
            end

            if not colored and classColorFrameTexture then
                local _, class = UnitClass(unit)
                local color = RAID_CLASS_COLORS[class]
                if color then
                    r, g, b = color.r, color.g, color.b
                    desaturate = true
                    colored = true
                end
            end
        end

        texture:SetDesaturated(desaturate)
        texture.changing = true
        texture:SetVertexColor(r, g, b)
        texture.changing = false
    end


    local function SetupFrame(frame, unit)
        if not frame then return end

        -- Assign unit and get texture
        local texture = frame.TargetFrameContainer and frame.TargetFrameContainer.FrameTexture
        or frame.PlayerFrameContainer and frame.PlayerFrameContainer.FrameTexture
        or frame.FrameTexture
        local altTexture = frame.TargetFrameContainer and frame.TargetFrameContainer.AlternatePowerFrameTexture
        or frame.PlayerFrameContainer and frame.PlayerFrameContainer.AlternatePowerFrameTexture
        or frame.AlternatePowerFrameTexture

        -- Hook SetVertexColor
        if not texture.bbfColorHook then
            hooksecurefunc(texture, "SetVertexColor", function(self)
                if self.changing then return end
                DesaturateAndColorTexture(self, unit)
            end)
            texture.bbfColorHook = true
        end

        if altTexture and not altTexture.bbfColorHook then
            hooksecurefunc(altTexture, "SetVertexColor", function(self)
                if self.changing then return end
                DesaturateAndColorTexture(self, unit)
            end)
            altTexture.bbfColorHook = true
        end

        DesaturateAndColorTexture(texture, unit)
        if altTexture then
            DesaturateAndColorTexture(altTexture, unit)
        end
    end

    -- Setup all frames
    SetupFrame(PlayerFrame, "player")
    SetupFrame(TargetFrame, "target")
    SetupFrame(FocusFrame, "focus")
    SetupFrame(TargetFrameToT, "targettarget")
    SetupFrame(FocusFrameToT, "focustarget")

    C_Timer.After(1, function()
        SetupFrame(PlayerFrame, "player")
    end)

    -- Event frame to watch for target/focus changes
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_FOCUS_CHANGED")
    f:RegisterUnitEvent("UNIT_TARGET", "target", "focus")
    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" then
            DesaturateAndColorTexture(TargetFrame.TargetFrameContainer.FrameTexture, "target")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            DesaturateAndColorTexture(FocusFrame.TargetFrameContainer.FrameTexture, "focus")
        end
        DesaturateAndColorTexture(TargetFrameToT.FrameTexture, "targettarget")
        DesaturateAndColorTexture(FocusFrameToT.FrameTexture, "focustarget")
    end)

    BBF.FrameTextureColor = true
end