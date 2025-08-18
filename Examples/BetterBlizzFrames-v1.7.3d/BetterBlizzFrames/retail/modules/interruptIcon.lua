local interruptSpells = {
    1766,  -- Kick (Rogue)
    2139,  -- Counterspell (Mage)
    6552,  -- Pummel (Warrior)
    19647, -- Spell Lock (Warlock)
    47528, -- Mind Freeze (Death Knight)
    57994, -- Wind Shear (Shaman)
    --91802, -- Shambling Rush (Death Knight)
    96231, -- Rebuke (Paladin)
    106839,-- Skull Bash (Feral)
    115781,-- Optical Blast (Warlock)
    116705,-- Spear Hand Strike (Monk)
    132409,-- Spell Lock (Warlock)
    119910,-- Spell Lock (Warlock Pet)
    89766, -- Axe Toss (Warlock Pet)
    171138,-- Shadow Lock (Warlock)
    147362,-- Countershot (Hunter)
    183752,-- Disrupt (Demon Hunter)
    187707,-- Muzzle (Hunter)
    212619,-- Call Felhunter (Warlock)
    --231665,-- Avengers Shield (Paladin)
    351338,-- Quell (Evoker)
    --97547, -- Solar Beam
    --47482, -- Leap (DK Transform)
}

-- Local variable to store the known interrupt spell ID
local knownInterruptSpellID = nil

-- Function to find and return the interrupt spell the player knows
local function GetInterruptSpell()
    for _, spellID in ipairs(interruptSpells) do
        if IsSpellKnownOrOverridesKnown(spellID) or (UnitExists("pet") and IsSpellKnownOrOverridesKnown(spellID, true)) then
            knownInterruptSpellID = spellID
            return spellID
        end
    end
end

-- Recheck interrupt spells when lock resummons/sacrifices pet
local petSummonSpells = {
    [30146] = true,  -- Summon Demonic Tyrant (Demonology)
    [691]    = true,  -- Summon Felhunter (for Spell Lock)
    [108503] = true,  -- Grimoire of Sacrifice
}

local function OnEvent(self, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not petSummonSpells[spellID] then return end
    end
    C_Timer.After(0.1, GetInterruptSpell)
end

local interruptSpellUpdate = CreateFrame("Frame")
if select(2, UnitClass("player")) == "WARLOCK" then
    interruptSpellUpdate:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end
interruptSpellUpdate:RegisterEvent("TRAIT_CONFIG_UPDATED")
interruptSpellUpdate:RegisterEvent("PLAYER_TALENT_UPDATE")
interruptSpellUpdate:SetScript("OnEvent", OnEvent)

-- Function to create an interrupt icon frame
local function CreateInterruptIconFrame(parentFrame)
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetSize(30, 30)
    frame:SetPoint("CENTER", parentFrame, BetterBlizzFramesDB.castBarInterruptIconAnchor, BetterBlizzFramesDB.castBarInterruptIconXPos+45, BetterBlizzFramesDB.castBarInterruptIconYPos-7)
    frame:SetScale(BetterBlizzFramesDB.castBarInterruptIconScale)

    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints()

    frame:SetAlpha(0)

    if BetterBlizzFramesDB.interruptIconBorder then
        frame.border = frame:CreateTexture(nil, "OVERLAY")
        frame.border:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-ActionBar-IconFrame-AddRow-Light")
        frame.border:SetSize(45, 45)
        frame.border:SetPoint("CENTER", frame, "CENTER", 2, -2)
        frame.border:SetDrawLayer("OVERLAY", 7)
    end

    return frame
end

-- Function to update the cooldown icon
local function UpdateInterruptIcon(frame)
    if not frame then return end
    if not knownInterruptSpellID then
        GetInterruptSpell()
    end

    if knownInterruptSpellID then
        local start, duration, enabled = BBF.TWWGetSpellCooldown(knownInterruptSpellID)
        local isOnCooldown = enabled and duration > 0
        local willBeReadyBeforeCastEnd = false

        if isOnCooldown then
            local castEndTime = select(5, UnitCastingInfo(frame.unit)) or select(5, UnitChannelInfo(frame.unit))
            if castEndTime and start + duration <= (castEndTime / 1000) then
                willBeReadyBeforeCastEnd = true
            end
        end

        if BetterBlizzFramesDB.interruptIconBorder then
            if isOnCooldown then
                if willBeReadyBeforeCastEnd then
                    frame.border:SetVertexColor(unpack(BetterBlizzFramesDB.castBarDelayedInterruptColor)) -- purple
                    local delay = (start + duration) - GetTime()
                    C_Timer.After(delay, function()
                        if UnitCastingInfo(frame.unit) or UnitChannelInfo(frame.unit) then
                            frame.border:SetVertexColor(0, 1, 0) -- green
                        end
                    end)
                else
                    frame.border:SetVertexColor(unpack(BetterBlizzFramesDB.castBarNoInterruptColor)) -- red
                end
            else
                frame.border:SetVertexColor(0, 1, 0) -- green
            end
        end

        local name, _, _, startTime, endTime, _, _, notInterruptible, spellId = UnitCastingInfo(frame.unit)
        if not name then
            name, _, _, startTime, endTime, _, notInterruptible, spellId = UnitChannelInfo(frame.unit)
        end

        if notInterruptible then
            frame:SetAlpha(0)
        else
            if enabled and (not BetterBlizzFramesDB.castBarInterruptIconShowActiveOnly or duration == 0) then
                frame.icon:SetTexture(C_Spell.GetSpellTexture(knownInterruptSpellID))
                frame.cooldown:SetCooldown(start, duration)
                frame:SetAlpha(1)
            else
                frame:SetAlpha(0)
            end
        end
    else
        frame:SetAlpha(0)
    end
end

-- Function to handle events for interrupt icon frames
local function OnEvent(self, event, unit)
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_AURA" then
        if unit == self.unit then
            self:SetAlpha(1)
            UpdateInterruptIcon(self)

            local spellID = GetInterruptSpell()
            if spellID then
                local start, duration, enabled = BBF.TWWGetSpellCooldown(spellID)
                if enabled and duration > 0 then
                    local castEndTime = select(5, UnitCastingInfo(unit)) or select(5, UnitChannelInfo(unit))
                    if castEndTime and start + duration <= (castEndTime / 1000) then
                        local delay = (start + duration) - GetTime()
                        if delay > 0 then
                            C_Timer.After(delay, function()
                                if UnitCastingInfo(unit) or UnitChannelInfo(unit) then
                                    UpdateInterruptIcon(self)
                                end
                            end)
                        else
                            if UnitCastingInfo(unit) or UnitChannelInfo(unit) then
                                UpdateInterruptIcon(self)
                            end
                        end
                    end
                end
            end
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        UpdateInterruptIcon(TargetFrameSpellBar.interruptIconFrame)
        UpdateInterruptIcon(FocusFrameSpellBar.interruptIconFrame)
    end
end

-- Function to initialize the interrupt icon frames
function BBF.ToggleCastbarInterruptIcon()
    -- Destroy existing frames if they exist
    if TargetFrameSpellBar.interruptIconFrame then
        TargetFrameSpellBar.interruptIconFrame:UnregisterAllEvents()
        TargetFrameSpellBar.interruptIconFrame:SetScript("OnEvent", nil)
        TargetFrameSpellBar.interruptIconFrame:SetAlpha(0)
        --TargetFrameSpellBar.interruptIconFrame = nil
    end
    if FocusFrameSpellBar.interruptIconFrame then
        FocusFrameSpellBar.interruptIconFrame:UnregisterAllEvents()
        FocusFrameSpellBar.interruptIconFrame:SetScript("OnEvent", nil)
        FocusFrameSpellBar.interruptIconFrame:SetAlpha(0)
        --FocusFrameSpellBar.interruptIconFrame = nil
    end

    if not BetterBlizzFramesDB.castBarInterruptIconEnabled then
        return
    end

    if BetterBlizzFramesDB.castBarInterruptIconTarget then
        TargetFrameSpellBar.interruptIconFrame = CreateInterruptIconFrame(TargetFrameSpellBar)
        TargetFrameSpellBar.interruptIconFrame.unit = "target"
        TargetFrameSpellBar.interruptIconFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
        TargetFrameSpellBar.interruptIconFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
        TargetFrameSpellBar.interruptIconFrame:RegisterUnitEvent("UNIT_AURA", "target")
        TargetFrameSpellBar.interruptIconFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        TargetFrameSpellBar.interruptIconFrame:SetScript("OnEvent", OnEvent)
    end

    if BetterBlizzFramesDB.castBarInterruptIconFocus then
        FocusFrameSpellBar.interruptIconFrame = CreateInterruptIconFrame(FocusFrameSpellBar)
        FocusFrameSpellBar.interruptIconFrame.unit = "focus"
        FocusFrameSpellBar.interruptIconFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
        FocusFrameSpellBar.interruptIconFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
        FocusFrameSpellBar.interruptIconFrame:RegisterUnitEvent("UNIT_AURA", "focus")
        FocusFrameSpellBar.interruptIconFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        FocusFrameSpellBar.interruptIconFrame:SetScript("OnEvent", OnEvent)
    end
end

-- Function to update settings
local function UpdateSettings()
    if not BetterBlizzFramesDB.castBarInterruptIconEnabled then
        if TargetFrameSpellBar.interruptIconFrame then
            TargetFrameSpellBar.interruptIconFrame:Hide()
        end
        if FocusFrameSpellBar.interruptIconFrame then
            FocusFrameSpellBar.interruptIconFrame:Hide()
        end
        return
    end

    if BetterBlizzFramesDB.castBarInterruptIconTarget and TargetFrameSpellBar.interruptIconFrame then
        local frame = TargetFrameSpellBar.interruptIconFrame
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", TargetFrameSpellBar, BetterBlizzFramesDB.castBarInterruptIconAnchor, BetterBlizzFramesDB.castBarInterruptIconXPos+45, BetterBlizzFramesDB.castBarInterruptIconYPos-7)
        frame:SetScale(BetterBlizzFramesDB.castBarInterruptIconScale)
        frame:Show()

        if BetterBlizzFramesDB.interruptIconBorder then
            if not frame.border then
                frame.border = frame:CreateTexture(nil, "OVERLAY")
                frame.border:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-ActionBar-IconFrame-AddRow-Light")
                frame.border:SetSize(45, 45)
                frame.border:SetPoint("CENTER", frame, "CENTER", 2, -2)
                frame.border:SetDrawLayer("OVERLAY", 7)
            end
            frame.border:SetAlpha(1)
        elseif frame.border then
            frame.border:SetAlpha(0)
        end
    else
        if TargetFrameSpellBar.interruptIconFrame then
            TargetFrameSpellBar.interruptIconFrame:Hide()
        end
    end
    if BetterBlizzFramesDB.castBarInterruptIconFocus and FocusFrameSpellBar.interruptIconFrame then
        local frame = FocusFrameSpellBar.interruptIconFrame
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", FocusFrameSpellBar, BetterBlizzFramesDB.castBarInterruptIconAnchor, BetterBlizzFramesDB.castBarInterruptIconXPos+45, BetterBlizzFramesDB.castBarInterruptIconYPos-7)
        frame:SetScale(BetterBlizzFramesDB.castBarInterruptIconScale)
        frame:Show()

        if BetterBlizzFramesDB.interruptIconBorder then
            if not frame.border then
                frame.border = frame:CreateTexture(nil, "OVERLAY")
                frame.border:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\UI-HUD-ActionBar-IconFrame-AddRow-Light")
                frame.border:SetSize(45, 45)
                frame.border:SetPoint("CENTER", frame, "CENTER", 2, -2)
                frame.border:SetDrawLayer("OVERLAY", 7)
            end
            frame.border:SetAlpha(1)
        elseif frame.border then
            frame.border:SetAlpha(0)
        end
    else
        if FocusFrameSpellBar.interruptIconFrame then
            FocusFrameSpellBar.interruptIconFrame:Hide()
        end
    end
end

-- Function to call when user changes settings
function BBF.UpdateInterruptIconSettings()
    UpdateSettings()
    if BetterBlizzFramesDB.castBarInterruptIconTarget and TargetFrameSpellBar.interruptIconFrame then
        UpdateInterruptIcon(TargetFrameSpellBar.interruptIconFrame)
    end
    if BetterBlizzFramesDB.castBarInterruptIconFocus and FocusFrameSpellBar.interruptIconFrame then
        UpdateInterruptIcon(FocusFrameSpellBar.interruptIconFrame)
    end
end