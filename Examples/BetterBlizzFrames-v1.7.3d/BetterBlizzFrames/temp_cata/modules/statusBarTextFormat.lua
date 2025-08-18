
local function FormatText(value)
    if value >= 1000000000 then
        return string.format("%.1f B", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.1f M", value / 1000000)
    elseif value >= 100000 then
        return string.format("%d K", value / 1000)
    else
        return tostring(value)
    end
end

local function UpdateNumericText(bar, centerText)
    if not centerText then return end
    local value = bar:GetValue()
    local _, maxValue = bar:GetMinMaxValues()
    local formattedValue = FormatText(value)
    local formattedMaxValue = FormatText(maxValue)
    if formattedValue == "0" then
        centerText:SetText("")
        return
    end
    centerText:SetText(string.format("%s / %s", formattedValue, formattedMaxValue))
end

local function UpdateSingleText(bar, fontObj)
    if not fontObj then return end
    local value = bar:GetValue()
    if value == 0 then
        fontObj:SetText("")
        return
    end
    fontObj:SetText(FormatText(value))
end

function BBF.HookStatusBarText()
    if BBF.statusBarTextHookBBF then return end
    if not BetterBlizzFramesDB.formatStatusBarText then return end

    local statusTextSetting = C_CVar.GetCVar("statusTextDisplay")
    local singleDisplay = BetterBlizzFramesDB.singleValueStatusBarText

    local pMain = PlayerFrame
    local tMain = TargetFrame
    local fMain = FocusFrame

    local bars = {}

    local function AddBar(bar, centerText, rightText)
        table.insert(bars, {
            bar = bar,
            centerText = centerText,
            rightText = rightText
        })
    end

    -- Player and pet frames
    AddBar(pMain.healthbar,
           pMain.healthbar.TextString,
           pMain.healthbar.RightText)

    AddBar(pMain.ManaBar,
           pMain.ManaBar.TextString,
           pMain.ManaBar.RightText)

    AddBar(PlayerFrameAlternateManaBar,
           PlayerFrameAlternateManaBar.TextString,
           PlayerFrameAlternateManaBar.TextString)

    AddBar(PetFrame.healthbar,
           PetFrame.healthbar.TextString,
           PetFrame.healthbar.RightText)

    AddBar(PetFrame.manabar,
           PetFrame.manabar.TextString,
           PetFrame.manabar.RightText)

    -- Target and focus frames
    AddBar(tMain.healthbar,
           tMain.healthbar.TextString,
           tMain.healthbar.RightText)

    AddBar(tMain.PowerBar,
           tMain.PowerBar.TextString,
           tMain.PowerBar.RightText)

    AddBar(fMain.healthbar,
           fMain.healthbar.TextString,
           fMain.healthbar.RightText)

    AddBar(fMain.manabar,
           fMain.manabar.TextString,
           fMain.manabar.RightText)

    -- Default party frames (non-raid-style)
    if not GetCVarBool("useCompactPartyFrames") then
        for i = 1, 4 do
            local member = _G["PartyMemberFrame"..i]
            if member then
                local hpBar = member.healthbar
                local manaBar = member.ManaBar
                if hpBar and hpBar.TextString and hpBar.RightText then
                    AddBar(hpBar, hpBar.TextString, hpBar.RightText)
                end
                if manaBar and manaBar.TextString and manaBar.RightText then
                    AddBar(manaBar, manaBar.TextString, manaBar.RightText)
                end
            end
        end
    end

    -- Hook logic
    local barUpdateFuncs = {}
    for _, info in ipairs(bars) do
        local bar, centerText, rightText = info.bar, info.centerText, info.rightText

        if singleDisplay and statusTextSetting == "NUMERIC" then
            barUpdateFuncs[bar] = function() UpdateSingleText(bar, centerText) end
            UpdateSingleText(bar, centerText)
        elseif statusTextSetting == "BOTH" then
            barUpdateFuncs[bar] = function() UpdateSingleText(bar, rightText) end
            UpdateSingleText(bar, rightText)
        elseif statusTextSetting == "NUMERIC" or statusTextSetting == "NONE" then
            barUpdateFuncs[bar] = function() UpdateNumericText(bar, centerText) end
            UpdateNumericText(bar, centerText)
        end
    end
    hooksecurefunc("TextStatusBar_UpdateTextStringWithValues", function(self)
        local updateFunc = barUpdateFuncs[self]
        if updateFunc then
            updateFunc()
        end
    end)

    BBF.statusBarTextHookBBF = true
end