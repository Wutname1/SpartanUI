local hidingArenaFrames
local changedParent

function BBF.HideArenaFrames()
    if hidingArenaFrames then return end
    hidingArenaFrames = true
    local ArenaAntiMalware = CreateFrame("Frame")
    ArenaAntiMalware:Hide()

    --Event list
    local events = {
        "PLAYER_ENTERING_WORLD",
        "ZONE_CHANGED_NEW_AREA",
        "ARENA_OPPONENT_UPDATE",
        --"ARENA_PREP_OPPONENT_SPECIALIZATIONS",
        --"PVP_MATCH_STATE_CHANGED"
    }

    -- Change parent and hide
    local function MalwareProtector()
        if InCombatLockdown() then return end
        local instanceType = select(2, IsInInstance())
        local prepFrame = _G["ArenaPrepFrames"]
        local enemyFrame = _G["ArenaEnemyFrames"]

        if instanceType == "arena" then
            if prepFrame then
                prepFrame:SetParent(ArenaAntiMalware)
                changedParent = true
            end
            if enemyFrame then
                enemyFrame:SetParent(ArenaAntiMalware)
                changedParent = true
            end
        else
            if changedParent then
                if prepFrame then
                    prepFrame:SetParent(UIParent)
                end
                if enemyFrame then
                    enemyFrame:SetParent(UIParent)
                end
            end
        end
    end


    -- Event handler function
    ArenaAntiMalware:SetScript("OnEvent", function(self, event, ...)
        MalwareProtector()
        C_Timer.After(0, MalwareProtector) --been instances of this god forsaken frame popping up so lets try to also do it one frame later
    end)

    -- Register the events
    for _, event in ipairs(events) do
        ArenaAntiMalware:RegisterEvent(event)
    end
    MalwareProtector()
end