----------------------------------------------------
---- Overshields is a fork by Casper Storm of the abandoned DerangementShieldMeters addon by Derangement
---- with a tweak from me, Bodify, to get rid of a minor bug
----------------------------------------------------


-- function BBF.HookOverShields()
--     if BetterBlizzFramesDB.overShields then
--         BBF.HookOverShieldCompactUnitFrames()
--         BBF.HookOverShieldUnitFrames()
--     end
-- end

function BBF.HookOverShieldCompactUnitFrames()
    -- if not BetterBlizzFramesDB.overShieldsCompactUnitFrames or COMPACT_UNITFRAME_OVERSHIELD_HOOKED then
    --     return
    -- end

    -- hooksecurefunc("CompactUnitFrame_UpdateAll", BBF_CompactUnitFrame_UpdateAll)
    -- hooksecurefunc("CompactUnitFrame_UpdateHealPrediction", BBF_CompactUnitFrame_UpdateHealPrediction)

    -- COMPACT_UNITFRAME_OVERSHIELD_HOOKED = true
end

function BBF.HookOverShieldUnitFrames()
    -- if not BetterBlizzFramesDB.overShieldsUnitFrames or UNITFRAME_OVERSHIELD_HOOKED then
    --     return
    -- end


    -- hooksecurefunc("UnitFrame_Update", BBF_UnitFrame_Update)
    -- hooksecurefunc("UnitFrameHealPredictionBars_Update", BBF_UnitFrameHealPredictionBars_Update)

    -- C_Timer.After(3, function()
    --     BBF_UnitFrameHealPredictionBars_Update(PlayerFrame)
    --     BBF_UnitFrameHealPredictionBars_Update(TargetFrame)
    --     BBF_UnitFrameHealPredictionBars_Update(FocusFrame)
    -- end)


    -- local eventFrame = CreateFrame("Frame")
    -- eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    -- eventFrame:SetScript("OnEvent", OnTargetChanged)

    -- UNITFRAME_OVERSHIELD_HOOKED = true
end