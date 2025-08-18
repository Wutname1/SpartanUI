local hidingArenaFrames = nil

function BBF.HideArenaFrames()
    -- if hidingArenaFrames then return end
    -- hidingArenaFrames = true
    -- local ArenaAntiMalware = CreateFrame("Frame")
    -- ArenaAntiMalware:Hide()

    -- --Event list
    -- local events = {
    --     "PLAYER_ENTERING_WORLD",
    --     "ZONE_CHANGED_NEW_AREA",
    --     "ARENA_OPPONENT_UPDATE",
    --     --"ARENA_PREP_OPPONENT_SPECIALIZATIONS",
    --     --"PVP_MATCH_STATE_CHANGED"
    -- }

    -- -- Change parent and hide
    -- local function MalwareProtector()
    --     local instanceType = select(2, IsInInstance())
    --     if instanceType == "arena" then
    --         CompactArenaFrame:SetParent(ArenaAntiMalware)
    --         CompactArenaFrameTitle:SetParent(ArenaAntiMalware)
    --     end
    -- end

    -- -- Event handler function
    -- ArenaAntiMalware:SetScript("OnEvent", function(self, event, ...)
    --     MalwareProtector()
    --     C_Timer.After(0, MalwareProtector) --been instances of this god forsaken frame popping up so lets try to also do it one frame later
    -- end)

    -- -- Register the events
    -- for _, event in ipairs(events) do
    --     ArenaAntiMalware:RegisterEvent(event)
    -- end

    -- -- Shouldn't be needed, but you know what, fuck it
    -- CompactArenaFrame:SetScript("OnLoad", MalwareProtector)
    -- CompactArenaFrame:SetScript("OnShow", MalwareProtector)
    -- CompactArenaFrameTitle:SetScript("OnLoad", MalwareProtector)
    -- CompactArenaFrameTitle:SetScript("OnShow", MalwareProtector)

    -- if CompactArenaFrame or CompactArenaFrameTitle then
    --     MalwareProtector()
    -- end
end