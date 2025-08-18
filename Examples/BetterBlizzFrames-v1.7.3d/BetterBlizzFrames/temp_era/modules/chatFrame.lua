local filterGladiusSpam
local filterTalentSpam
local filterSystemMessages
local filterEmoteSpam
local filterNpcArenaSpam
local filterMiscInfo

local filterGladiusSpamHooked = false
local filterTalentSpamHooked = false
local filterSystemMessagesHooked = false
local filterEmoteSpamHooked = false
local filterNpcArenaSpamHooked = false
local filterMiscInfoHooked = false

local gladiusSpam = {
    ["LOW HEALTH:"] = true, ["WENIG LEBEN:"] = true, ["NIEDRIGE GESUNDHEIT:"] = true, ["VIDA BAJA:"] = true,
    ["Entidad desconocida -"] = true,
    ["BIJOU UTILISE"] = true,
    ["Enemy spec:"] = true, ["Enemy Spec:"] = true, ["Especialización de enemigo:"] = true,
    ["- Mage"] = true, ["Magier"] = true,
    ["- Monk"] = true, ["- Mönch"] = true,
    ["- Warrior"] = true, ["Krieger"] = true,
    ["- Warlock"] = true, ["Hexenmeister"] = true,
    ["- Priest"] = true,
    ["- Shaman"] = true, ["Schamane"] = true,
    ["- Demon Hunter"] = true,
    ["- Paladin"] = true,
    ["- Death Knight"] = true, ["- Todesritter"] = true,
    ["- Druid"] = true,
    ["- Rogue"] = true,
    ["- Hunter"] = true,
}

local talentSpam = {
    ["You have learned a new"] = true,
    ["You have unlearned"] = true,
    ["Soulbound with "] = true,
}

local systemMessages = {
    ["Thirty seconds until the Arena"] = true,
    ["Fifteen seconds until the Arena"] = true,
    ["The Arena battle has begun!"] = true,
    ["Party converted to Raid"] = true,
    ["Raid Difficulty set to Normal"] = true,
    ["Legacy Raid Difficulty set to 10 Player."] = true,
    ["has joined the battle."] = true,
    ["has joined the instance group."] = true,
    ["has left the instance group."] = true,
    ["You have been removed from the group."] = true,
    ["Your group has been disbanded."] = true,
    ["You have joined the queue for Arena Skirmish"] = true,
    ["A role check has been initiated."] = true,
    ["You have been awarded"] = true,
    ["You are in both a party and an instance group."] = true,
    ["This is now a cross-faction"] = true,
    ["You aren't in a party"] = true,
    ["You are now queued in the Dungeon Finder."] = true,
    ["Dungeon Difficulty set to"] = true,
    ["Loot Specialization set to"] = true,
    ["SUSPENDED"] = true,
    ["YOU_CHANGED"] = true,
}

local miscInfo = {
    ["Your equipped items suffer a"] = true,
}

local emoteSpam = {
    ["yells at her team members."] = true,
    ["yells at his team members."] = true,
    ["makes some strange gestures."] = true,
    ["says something unintelligible."] = true,
}

-- Function to check if a message is spam based on user settings
local function isSpam(message, spamTable)
    for spamString, _ in pairs(spamTable) do
        if string.find(message, spamString) then
            return true
        end
    end
    return false
end

--CHAT_MSG_COMBAT_MISC_INFO
local function chatFilter(frame, event, message, sender, ...)
    -- Check and filter user-defined spam (applies to all channels)
--[[
    if BetterBlizzFramesDB.filterUserSpam and isSpam(message, BetterBlizzFramesDB.userDefinedSpam) then
        return true
    end
]]
    -- Channel-specific filtering
    if (event == "CHAT_MSG_INSTANCE_CHAT" or event == "CHAT_MSG_INSTANCE_CHAT_LEADER" or
        event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER") and
        filterGladiusSpam and isSpam(message, gladiusSpam) then
        return true
    elseif (event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_COMBAT_HONOR_GAIN" or
            event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" or event == "CHAT_MSG_CHANNEL_NOTICE" or
            event == "CHAT_MSG_CURRENCY") then
        if filterSystemMessages and isSpam(message, systemMessages) then
            return true
        end
        if filterTalentSpam and isSpam(message, talentSpam) then
            return true
        end
    elseif (event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE") and
           filterEmoteSpam and isSpam(message, emoteSpam) then
        return true
    elseif event == "CHAT_MSG_MONSTER_SAY" and filterNpcArenaSpam and IsActiveBattlefieldArena() then
        return true
    elseif event == "CHAT_MSG_COMBAT_MISC_INFO" and isSpam(message, miscInfo) then
        return true
    end

    return false
end

function BBF.ChatFilterCaller()
    -- Update settings
    filterGladiusSpam = BetterBlizzFramesDB.filterGladiusSpam
    filterTalentSpam = BetterBlizzFramesDB.filterTalentSpam
    filterSystemMessages = BetterBlizzFramesDB.filterSystemMessages
    filterEmoteSpam = BetterBlizzFramesDB.filterEmoteSpam
    filterNpcArenaSpam = BetterBlizzFramesDB.filterNpcArenaSpam
    filterMiscInfo = BetterBlizzFramesDB.filterMiscInfo

    -- Gladius Spam
    if filterGladiusSpam and not filterGladiusSpamHooked then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", chatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", chatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", chatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", chatFilter)
        filterGladiusSpamHooked = true
    end

    -- Talent Spam
    if filterTalentSpam and not filterTalentSpamHooked then
        if not filterSystemMessagesHooked then
            ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", chatFilter)
        end
        filterTalentSpamHooked = true
    end

    -- System Messages
    if filterSystemMessages and not filterSystemMessagesHooked then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_HONOR_GAIN", chatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", chatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", chatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CURRENCY", chatFilter)
        if not filterTalentSpamHooked then
            ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", chatFilter)
        end
        filterSystemMessagesHooked = true
    end

    if filterMiscInfo and not filterMiscInfoHooked then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_MISC_INFO", chatFilter)
        filterMiscInfoHooked = true
    end

    -- Emote Spam
    if filterEmoteSpam and not filterEmoteSpamHooked then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", chatFilter)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", chatFilter)
        filterEmoteSpamHooked = true
    end

    -- NPC Arena Spam
    if filterNpcArenaSpam and not filterNpcArenaSpamHooked then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", chatFilter)
        filterNpcArenaSpamHooked = true
    end
end