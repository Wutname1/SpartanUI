-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

local Icon = private.TooltipHandler.Icon
local OnlineFriendsByName = private.TooltipHandler.OnlineFriendsByName
local People = private.People
local Player = private.TooltipHandler.Player
local PlayerLists = private.TooltipHandler.PlayerLists

local BattleNetFriend_OnMouseUp = private.TooltipHandler.CellScripts.BattleNetFriend_OnMouseUp
local ColumnLabel = private.TooltipHandler.Helpers.ColumnLabel
local SectionTitle_OnMouseUp = private.TooltipHandler.CellScripts.SectionTitle_OnMouseUp
local ToggleColumnSortMethod = private.TooltipHandler.CellScripts.ToggleColumnSortMethod

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------
local BNET_CLIENT_MOBILE_CHAT = "BSAp"
local BattleNetClientIndex = {} ---@type Dictionary<integer>

do
    local BattleNetClientTokens = {
        -- ----------------------------------------------------------------------------
        -- Blizzard Games
        -- ----------------------------------------------------------------------------
        "RTRO", -- Blizzard Arcade Collection
        "OSI", -- Diablo II: Resurrected
        "D3", -- Diablo III
        "ANBS", -- Diablo Immortal
        "WTCG", -- Hearthstone
        "Hero", -- Heroes of the Storm
        "Pro", -- Overwatch
        "S1", -- StarCraft
        "S2", -- StarCraft II
        "W3", -- Warcraft III: Reforged
        "GRY", -- Warcraft Arclight Rumble
        "WoW", -- World of Warcraft
        -- ----------------------------------------------------------------------------
        -- Activision Games
        -- ----------------------------------------------------------------------------
        "VIPR", -- Call of Duty
        "ZEUS", -- Call of Duty: Black Ops Cold War
        "ODIN", -- Call of Duty: Modern Warfare
        "LAZR", -- Call of Duty: Modern Warfare II
        "FORE", -- Call of Duty: Vanguard
        "WLBY", -- Crash Bandicoot 4
        -- ----------------------------------------------------------------------------
        -- Non-Game Clients
        -- ----------------------------------------------------------------------------
        BNET_CLIENT_CLNT,
        BNET_CLIENT_APP,
        BNET_CLIENT_MOBILE_CHAT,
    }

    for index, value in ipairs(BattleNetClientTokens) do
        BattleNetClientIndex[value] = index
    end
end

local BattleNetNonGameClient = {
    [BNET_CLIENT_CLNT] = true,
    [BNET_CLIENT_APP] = true,
    [BNET_CLIENT_MOBILE_CHAT] = true,
}

-- Used to handle duplication between in-game and RealID friends.
local OnlineFriendsByPresenceName = {}

-- ----------------------------------------------------------------------------
-- Column and ColSpan
-- ----------------------------------------------------------------------------
local BattleNetColumn = {
    ClientIcon = 1,
    PresenceName = 2,
    ToonName = 4,
    GameText = 5,
    Note = 7,
}

local BattleNetColSpan = {
    ClientIcon = 1,
    PresenceName = 2,
    ToonName = 1,
    GameText = 2,
    Note = 2,
}

-- ----------------------------------------------------------------------------
-- Data Compilation
-- ----------------------------------------------------------------------------
local function GenerateData()
    table.wipe(OnlineFriendsByPresenceName)

    if People.BattleNet.Total == 0 then
        return
    end

    local ClientIconSize = 18

    for battleNetIndex = 1, People.BattleNet.Total do
        local friendInfo = C_BattleNet.GetFriendAccountInfo(battleNetIndex) or {}
        local accountName = friendInfo.accountName
        local bnetAccountID = friendInfo.bnetAccountID
        local messageText = friendInfo.customMessage
        local noteText = friendInfo.note

        local numToons = C_BattleNet.GetFriendNumGameAccounts(battleNetIndex)

        for toonIndex = 1, numToons do
            local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(battleNetIndex, toonIndex) or {}
            local clientProgram = gameAccountInfo.clientProgram
            local gameText = gameAccountInfo.richPresence
            local toonName = gameAccountInfo.characterName
            local characterName = BNet_GetValidatedCharacterName(toonName, friendInfo.battleTag, clientProgram)

            ---@type BattleNetFriend
            local bNetFriendData = {
                BroadcastText = (messageText and messageText ~= "") and ("%s%s%s (%s)|r"):format(
                    Icon.Broadcast,
                    FRIENDS_OTHER_NAME_COLOR_CODE,
                    messageText,
                    SecondsToTime(time() - friendInfo.customMessageTime, false, true, 1)
                ) or nil,
                Client = clientProgram,
                ClientIcon = CreateAtlasMarkup(
                    BNet_GetBattlenetClientAtlas(clientProgram),
                    ClientIconSize,
                    ClientIconSize
                ),
                ClientIndex = BattleNetClientIndex[clientProgram],
                GameText = gameText ~= "" and gameText or COMMUNITIES_PRESENCE_MOBILE_CHAT,
                Note = noteText ~= "" and noteText or nil,
                PresenceID = bnetAccountID,
                PresenceName = accountName or UNKNOWN,
                StatusIcon = gameAccountInfo.isGameAFK and Icon.Status.AFK
                    or (gameAccountInfo.isGameBusy and Icon.Status.DND or Icon.Status.Online),
                ToonName = characterName,
            }

            if clientProgram == BNET_CLIENT_WOW and gameAccountInfo.wowProjectID == WOW_PROJECT_ID then
                local existingFriend = OnlineFriendsByName[toonName]
                local realmName = gameAccountInfo.realmName

                if existingFriend and realmName == Player.RealmName then
                    for key, value in pairs(bNetFriendData) do
                        if not existingFriend[key] then
                            existingFriend[key] = value
                        end
                    end
                elseif not OnlineFriendsByPresenceName[bNetFriendData.PresenceName] then
                    local level = gameAccountInfo.characterLevel
                    local zoneName = gameAccountInfo.areaName

                    ---@type WoWFriend
                    local wowFriendData = {
                        BroadcastText = bNetFriendData.BroadcastText,
                        Class = gameAccountInfo.className,
                        FullToonName = nil,
                        IsLocalFriend = false,
                        Level = level and tonumber(level) or 0,
                        Note = bNetFriendData.Note,
                        PresenceID = bNetFriendData.PresenceID,
                        PresenceName = bNetFriendData.PresenceName,
                        RealmName = realmName or "",
                        StatusIcon = bNetFriendData.StatusIcon,
                        ToonName = bNetFriendData.ToonName,
                        ZoneName = zoneName ~= "" and zoneName or UNKNOWN,
                    }

                    table.insert(PlayerLists.WoWFriends, wowFriendData)
                    OnlineFriendsByPresenceName[bNetFriendData.PresenceName] = wowFriendData
                end
            elseif not OnlineFriendsByPresenceName[bNetFriendData.PresenceName] then
                if BattleNetNonGameClient[clientProgram] then
                    table.insert(PlayerLists.BattleNetApp, bNetFriendData)
                elseif gameAccountInfo.gameAccountID then
                    table.insert(PlayerLists.BattleNetGames, bNetFriendData)
                end

                OnlineFriendsByPresenceName[bNetFriendData.PresenceName] = bNetFriendData
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
---@param tooltip LibQTip.Tooltip
---@param playerList BattleNetFriend[]
---@param dataPrefix "BattleNetApp"|"BattleNetGames"
---@param headerLine number
---@param noteArrangement NotesArrangement
local function RenderBattleNetLines(tooltip, playerList, dataPrefix, headerLine, noteArrangement)
    -- ----------------------------------------------------------------------------
    -- Section Header
    -- ----------------------------------------------------------------------------
    tooltip:SetLineColor(headerLine, 0, 0, 0, 1)
    tooltip:SetCell(
        headerLine,
        BattleNetColumn.PresenceName,
        ColumnLabel(BATTLENET_FRIEND, dataPrefix .. ":PresenceName"),
        nil,
        nil,
        BattleNetColSpan.PresenceName
    )
    tooltip:SetCellScript(
        headerLine,
        BattleNetColumn.PresenceName,
        "OnMouseUp",
        ToggleColumnSortMethod,
        dataPrefix .. ":PresenceName"
    )

    tooltip:SetCell(
        headerLine,
        BattleNetColumn.ToonName,
        ColumnLabel(NAME, dataPrefix .. ":ToonName"),
        nil,
        nil,
        BattleNetColSpan.ToonName
    )
    tooltip:SetCellScript(
        headerLine,
        BattleNetColumn.ToonName,
        "OnMouseUp",
        ToggleColumnSortMethod,
        dataPrefix .. ":ToonName"
    )

    tooltip:SetCell(
        headerLine,
        BattleNetColumn.GameText,
        ColumnLabel(INFO, dataPrefix .. ":GameText"),
        nil,
        nil,
        BattleNetColSpan.GameText
    )
    tooltip:SetCellScript(
        headerLine,
        BattleNetColumn.GameText,
        "OnMouseUp",
        ToggleColumnSortMethod,
        dataPrefix .. ":GameText"
    )

    -- ----------------------------------------------------------------------------
    -- Section Body
    -- ----------------------------------------------------------------------------
    local hasNoteColumn = false

    tooltip:AddSeparator(1, 0.5, 0.5, 0.5)

    for index = 1, #playerList do
        local friend = playerList[index]
        local line = tooltip:AddLine()
        tooltip:SetCell(line, BattleNetColumn.ClientIcon, friend.ClientIcon, nil, nil, BattleNetColSpan.ClientIcon)
        tooltip:SetCell(
            line,
            BattleNetColumn.PresenceName,
            ("%s%s%s|r"):format(friend.StatusIcon, FRIENDS_BNET_NAME_COLOR_CODE, friend.PresenceName),
            nil,
            nil,
            BattleNetColSpan.PresenceName
        )
        tooltip:SetCell(
            line,
            BattleNetColumn.ToonName,
            ("%s%s|r"):format(FRIENDS_OTHER_NAME_COLOR_CODE, friend.ToonName),
            nil,
            nil,
            BattleNetColSpan.ToonName
        )
        tooltip:SetCell(line, BattleNetColumn.GameText, friend.GameText, nil, nil, BattleNetColSpan.GameText)

        tooltip:SetCellScript(line, BattleNetColumn.PresenceName, "OnMouseUp", BattleNetFriend_OnMouseUp, friend)

        if friend.Note then
            local noteText = FRIENDS_OTHER_NAME_COLOR_CODE .. friend.Note .. "|r"

            if noteArrangement == private.Preferences.Tooltip.NotesArrangement.Column then
                if not hasNoteColumn then
                    tooltip:SetCell(
                        headerLine,
                        BattleNetColumn.Note,
                        ColumnLabel(LABEL_NOTE, dataPrefix .. ":Note"),
                        nil,
                        nil,
                        BattleNetColSpan.Note
                    )
                    tooltip:SetCellScript(
                        headerLine,
                        BattleNetColumn.Note,
                        "OnMouseUp",
                        ToggleColumnSortMethod,
                        dataPrefix .. ":Note"
                    )

                    hasNoteColumn = true
                end
                tooltip:SetCell(line, BattleNetColumn.Note, noteText, nil, nil, BattleNetColSpan.Note)
            else
                tooltip:SetCell(
                    tooltip:AddLine(),
                    BattleNetColumn.ClientIcon,
                    Icon.Status.Note .. noteText,
                    "GameTooltipTextSmall",
                    nil,
                    0
                )
            end
        end

        if friend.BroadcastText then
            tooltip:SetCell(
                tooltip:AddLine(),
                BattleNetColumn.ClientIcon,
                friend.BroadcastText,
                "GameTooltipTextSmall",
                nil,
                0
            )
        end
    end

    tooltip:AddLine(" ")
end

-- ----------------------------------------------------------------------------
-- BattleNet In-Game Friends
-- ----------------------------------------------------------------------------
---@param tooltip LibQTip.Tooltip
local function DisplaySectionBattleNetGames(tooltip)
    if #PlayerLists.BattleNetGames == 0 then
        return
    end

    local DB = private.DB
    local line = tooltip:AddLine()

    if DB.Tooltip.CollapsedSections.BattleNetGames then
        tooltip:SetCell(
            line,
            1,
            ("%s%s%s"):format(
                Icon.Section.Disabled,
                ("%s %s"):format(BATTLENET_OPTIONS_LABEL, PARENS_TEMPLATE:format(GAME)),
                Icon.Section.Disabled
            ),
            GameFontDisable,
            "CENTER",
            0
        )
        tooltip:SetCellScript(line, 1, "OnMouseUp", SectionTitle_OnMouseUp, "BattleNetGames")

        return
    end

    tooltip:SetCell(
        line,
        1,
        ("%s%s%s"):format(
            Icon.Section.Enabled,
            ("%s %s"):format(BATTLENET_OPTIONS_LABEL, PARENS_TEMPLATE:format(GAME)),
            Icon.Section.Enabled
        ),
        GameFontNormal,
        "CENTER",
        0
    )
    tooltip:SetCellScript(line, 1, "OnMouseUp", SectionTitle_OnMouseUp, "BattleNetGames")

    tooltip:AddSeparator(1, 0.5, 0.5, 0.5)

    line = tooltip:AddLine()
    tooltip:SetCell(line, BattleNetColumn.ClientIcon, ColumnLabel(Icon.Column.Game, "BattleNetGames:ClientIndex"))

    tooltip:SetCellScript(
        line,
        BattleNetColumn.ClientIcon,
        "OnMouseUp",
        ToggleColumnSortMethod,
        "BattleNetGames:ClientIndex"
    )

    RenderBattleNetLines(
        tooltip,
        PlayerLists.BattleNetGames,
        "BattleNetGames",
        line,
        DB.Tooltip.NotesArrangement.BattleNetGames
    )
end

-- ----------------------------------------------------------------------------
-- BattleNet Friends
-- ----------------------------------------------------------------------------
---@param tooltip LibQTip.Tooltip
local function DisplaySectionBattleNetApp(tooltip)
    if #PlayerLists.BattleNetApp == 0 then
        return
    end

    local DB = private.DB
    local line = tooltip:AddLine()

    if DB.Tooltip.CollapsedSections.BattleNetApp then
        tooltip:SetCell(
            line,
            1,
            ("%s%s%s"):format(Icon.Section.Disabled, BATTLENET_OPTIONS_LABEL, Icon.Section.Disabled),
            GameFontDisable,
            "CENTER",
            0
        )
        tooltip:SetCellScript(line, 1, "OnMouseUp", SectionTitle_OnMouseUp, "BattleNetApp")

        return
    end

    tooltip:SetCell(
        line,
        1,
        ("%s%s%s"):format(Icon.Section.Enabled, BATTLENET_OPTIONS_LABEL, Icon.Section.Enabled),
        GameFontNormal,
        "CENTER",
        0
    )
    tooltip:SetCellScript(line, 1, "OnMouseUp", SectionTitle_OnMouseUp, "BattleNetApp")

    tooltip:AddSeparator(1, 0.5, 0.5, 0.5)

    RenderBattleNetLines(
        tooltip,
        PlayerLists.BattleNetApp,
        "BattleNetApp",
        tooltip:AddLine(),
        DB.Tooltip.NotesArrangement.BattleNetApp
    )
end

-- ----------------------------------------------------------------------------
-- TooltipHandler Augmentation
-- ----------------------------------------------------------------------------
---@class TooltipHandler.BattleNet
private.TooltipHandler.BattleNet = {
    DisplaySectionBattleNetApp = DisplaySectionBattleNetApp,
    DisplaySectionBattleNetGames = DisplaySectionBattleNetGames,
    GenerateData = GenerateData,
}

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------
---@class BattleNetFriend
---@field BroadcastText string?
---@field Client string
---@field ClientIcon string
---@field ClientIndex integer
---@field GameText string
---@field Note? string
---@field PresenceID number
---@field PresenceName string
---@field StatusIcon string
---@field ToonName string
