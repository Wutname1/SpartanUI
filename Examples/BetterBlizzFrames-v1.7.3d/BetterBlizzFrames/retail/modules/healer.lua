local function CreateHealerIndicator(frame)
    if frame.bbfHealerIndicator then return end

    frame.bbfHealerIndicator = frame.bbfOverlayFrame:CreateTexture(nil, "OVERLAY")
    frame.bbfHealerIndicator:SetAtlas("bags-icon-addslots")
    frame.bbfHealerIndicator:SetSize(13, 13)
    frame.bbfHealerIndicator:Hide()
end

local function UpdateHealerIndicator(frame, unit)
    if UnitExists(unit) and BBF.IsSpecHealer(unit) then
        frame.bbfHealerIndicator:Show()
    else
        frame.bbfHealerIndicator:Hide()
    end
end

local function UpdateHealerIndicatorOptions(frame)
    frame.bbfHealerIndicator:ClearAllPoints()
    frame.bbfHealerIndicator:SetPoint("CENTER", frame.TargetFrameContainer.Portrait, BetterBlizzFramesDB.healerIndicatorAnchor or "CENTER", (BetterBlizzFramesDB.healerIndicatorXPos or 0) + -35, (BetterBlizzFramesDB.healerIndicatorYPos or 0) + 15.7)
    frame.bbfHealerIndicator:SetScale(BetterBlizzFramesDB.healerIndicatorScale or 1)
end

function BBF.HealerIndicatorIcon()
    CreateHealerIndicator(TargetFrame)
    CreateHealerIndicator(FocusFrame)

    if not BBF.healerIndicatorEventFrame then
        BBF.healerIndicatorEventFrame = CreateFrame("Frame")
        BBF.healerIndicatorEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        BBF.healerIndicatorEventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
        BBF.healerIndicatorEventFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_TARGET_CHANGED" then
                UpdateHealerIndicator(TargetFrame, "target")
            elseif event == "PLAYER_FOCUS_CHANGED" then
                UpdateHealerIndicator(FocusFrame, "focus")
            end
        end)
    end

    UpdateHealerIndicatorOptions(TargetFrame)
    UpdateHealerIndicatorOptions(FocusFrame)

    -- Initial update
    UpdateHealerIndicator(TargetFrame, "target")
    UpdateHealerIndicator(FocusFrame, "focus")
end

function BBF.HealerIndicatorPortrait()
    if BBF.healerPortrait then return end
    hooksecurefunc("UnitFramePortrait_Update", function(self)
        local unit = self.unit
        if (unit == "target" or unit == "focus") and BBF.IsSpecHealer(unit) then
            self.portrait:SetAtlas("UI-LFG-RoleIcon-Healer")
            self.portrait:SetTexCoord(0.13,0.85,0.13,0.83)
            self.bbfHealerPortraitActive = true
        elseif self.bbfHealerPortraitActive then
            self.portrait:SetTexCoord(0,1,0,1)
            self.bbfHealerPortraitActive = nil
        end
    end)
    BBF.healerPortrait = true
end

function BBF.HealerIndicatorCaller()
    if not BetterBlizzFramesDB.healerIndicator then return end
    if BetterBlizzFramesDB.healerIndicatorIcon then
        BBF.HealerIndicatorIcon()
    end
    if BetterBlizzFramesDB.healerIndicatorPortrait then
        BBF.HealerIndicatorPortrait()
    end
end