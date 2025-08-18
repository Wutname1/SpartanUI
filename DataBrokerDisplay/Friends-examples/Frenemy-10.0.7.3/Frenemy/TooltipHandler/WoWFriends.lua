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
local ColorPlayerLevel = private.TooltipHandler.Helpers.ColorPlayerLevel
local ColumnLabel = private.TooltipHandler.Helpers.ColumnLabel
local IsUnitGrouped = private.TooltipHandler.Helpers.IsUnitGrouped
local SectionTitle_OnMouseUp = private.TooltipHandler.CellScripts.SectionTitle_OnMouseUp
local ToggleColumnSortMethod = private.TooltipHandler.CellScripts.ToggleColumnSortMethod

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnFolderName)

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------

-- Used to handle duplication between in-game and RealID friends.
local WoWFriendIndexByName = {}

-- ----------------------------------------------------------------------------
-- Column and ColSpan
-- ----------------------------------------------------------------------------
local WoWFriendsColumn = {
    Level = 1,
    Class = 2,
    PresenceName = 3,
    ToonName = 4,
    ZoneName = 5,
    RealmName = 6,
    Note = 7,
}

local WoWFriendsColSpan = {
    Level = 1,
    Class = 1,
    PresenceName = 1,
    ToonName = 1,
    ZoneName = 1,
    RealmName = 1,
    Note = 2,
}

-- ----------------------------------------------------------------------------
-- Data Compilation
-- ----------------------------------------------------------------------------
local function GenerateData()
    table.wipe(WoWFriendIndexByName)

    if People.Friends.Online == 0 then
        return
    end

    for friendIndex = 1, People.Friends.Online do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(friendIndex)
        local fullToonName = friendInfo.name
        local toonName, realmName = strsplit("-", fullToonName)
        local zoneName = friendInfo.area

        WoWFriendIndexByName[fullToonName] = friendIndex
        WoWFriendIndexByName[toonName] = friendIndex

        if not OnlineFriendsByName[toonName] then
            ---@type WoWFriend
            local friendData = {
                Class = friendInfo.className,
                FullToonName = fullToonName,
                IsLocalFriend = true,
                Level = friendInfo.level,
                Note = friendInfo.notes,
                RealmName = realmName or Player.RealmName,
                StatusIcon = friendInfo.afk and Icon.Status.AFK
                    or (friendInfo.dnd and Icon.Status.DND or Icon.Status.Online),
                ToonName = toonName,
                ZoneName = zoneName ~= "" and zoneName or UNKNOWN,
            }

            table.insert(PlayerLists.WoWFriends, friendData)
            OnlineFriendsByName[toonName] = friendData
        end
    end
end

-- ----------------------------------------------------------------------------
-- Cell Scripts
-- ----------------------------------------------------------------------------
local function WoWFriend_OnMouseUp(_, playerEntry, mouseButton)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "Master")

    local playerName = playerEntry.Realm == Player.RealmName and playerEntry.ToonName or playerEntry.FullToonName

    if mouseButton == "LeftButton" then
        if IsAltKeyDown() then
            C_PartyInfo.InviteUnit(playerName)
        elseif IsControlKeyDown() then
            FriendsFrame.NotesID = WoWFriendIndexByName[playerName]
            StaticPopup_Show("SET_FRIENDNOTE", playerName)
        else
            ChatFrame_SendTell(playerName)
        end
    elseif mouseButton == "RightButton" then
        private.TooltipHandler.Tooltip.Main:SetFrameStrata("DIALOG")
        CloseDropDownMenus()
        FriendsFrame_ShowDropdown(playerEntry.FullToonName, true, nil, nil, nil, true)
    end
end

-- ----------------------------------------------------------------------------
-- WoW Friends
-- ----------------------------------------------------------------------------
---@param tooltip LibQTip.Tooltip
local function DisplaySectionWoWFriends(tooltip)
    if #PlayerLists.WoWFriends == 0 then
        return
    end

    local DB = private.DB
    local line = tooltip:AddLine()

    if DB.Tooltip.CollapsedSections.WoWFriends then
        tooltip:SetCell(
            line,
            1,
            ("%s%s%s"):format(Icon.Section.Disabled, FRIENDS, Icon.Section.Disabled),
            GameFontDisable,
            "CENTER",
            0
        )
        tooltip:SetCellScript(line, 1, "OnMouseUp", SectionTitle_OnMouseUp, "WoWFriends")

        return
    end

    tooltip:SetCell(
        line,
        1,
        ("%s%s%s"):format(Icon.Section.Enabled, FRIENDS, Icon.Section.Enabled),
        GameFontNormal,
        "CENTER",
        0
    )
    tooltip:SetCellScript(line, 1, "OnMouseUp", SectionTitle_OnMouseUp, "WoWFriends")

    tooltip:AddSeparator(1, 0.5, 0.5, 0.5)

    -- ----------------------------------------------------------------------------
    -- Section Header
    -- ----------------------------------------------------------------------------
    local headerLine = tooltip:AddLine()
    tooltip:SetLineColor(headerLine, 0, 0, 0, 1)
    tooltip:SetCell(
        headerLine,
        WoWFriendsColumn.Level,
        ColumnLabel(Icon.Column.Level, "WoWFriends:Level"),
        nil,
        nil,
        WoWFriendsColSpan.Level
    )
    tooltip:SetCellScript(headerLine, WoWFriendsColumn.Level, "OnMouseUp", ToggleColumnSortMethod, "WoWFriends:Level")

    tooltip:SetCell(
        headerLine,
        WoWFriendsColumn.Class,
        ColumnLabel(Icon.Column.Class, "WoWFriends:Class"),
        nil,
        nil,
        WoWFriendsColSpan.Class
    )
    tooltip:SetCellScript(headerLine, WoWFriendsColumn.Class, "OnMouseUp", ToggleColumnSortMethod, "WoWFriends:Class")

    tooltip:SetCell(
        headerLine,
        WoWFriendsColumn.PresenceName,
        ColumnLabel(BATTLENET_FRIEND, "WoWFriends:PresenceName"),
        nil,
        nil,
        WoWFriendsColSpan.PresenceName
    )
    tooltip:SetCellScript(
        headerLine,
        WoWFriendsColumn.PresenceName,
        "OnMouseUp",
        ToggleColumnSortMethod,
        "WoWFriends:PresenceName"
    )

    tooltip:SetCell(
        headerLine,
        WoWFriendsColumn.ToonName,
        ColumnLabel(NAME, "WoWFriends:ToonName"),
        nil,
        nil,
        WoWFriendsColSpan.ToonName
    )
    tooltip:SetCellScript(
        headerLine,
        WoWFriendsColumn.ToonName,
        "OnMouseUp",
        ToggleColumnSortMethod,
        "WoWFriends:ToonName"
    )

    tooltip:SetCell(
        headerLine,
        WoWFriendsColumn.ZoneName,
        ColumnLabel(ZONE, "WoWFriends:ZoneName"),
        nil,
        nil,
        WoWFriendsColSpan.ZoneName
    )
    tooltip:SetCellScript(
        headerLine,
        WoWFriendsColumn.ZoneName,
        "OnMouseUp",
        ToggleColumnSortMethod,
        "WoWFriends:ZoneName"
    )

    tooltip:SetCell(
        headerLine,
        WoWFriendsColumn.RealmName,
        ColumnLabel(L.COLUMN_LABEL_REALM, "WoWFriends:RealmName"),
        nil,
        nil,
        WoWFriendsColSpan.RealmName
    )
    tooltip:SetCellScript(
        headerLine,
        WoWFriendsColumn.RealmName,
        "OnMouseUp",
        ToggleColumnSortMethod,
        "WoWFriends:RealmName"
    )

    -- ----------------------------------------------------------------------------
    -- Section Body
    -- ----------------------------------------------------------------------------
    local addedNoteColumn

    tooltip:AddSeparator(1, 0.5, 0.5, 0.5)

    local classToken = private.TooltipHandler.Class.Token
    local tooltipIcon = private.TooltipHandler.Icon

    for index = 1, #PlayerLists.WoWFriends do
        local player = PlayerLists.WoWFriends[index]
        local groupIndicator = IsUnitGrouped(player.ToonName) and Icon.Player.Group or ""
        local presenceName = player.PresenceName
                and ("%s%s|r"):format(FRIENDS_BNET_NAME_COLOR_CODE, player.PresenceName)
            or NOT_APPLICABLE

        line = tooltip:AddLine()
        tooltip:SetCell(line, WoWFriendsColumn.Level, ColorPlayerLevel(player.Level), nil, nil, WoWFriendsColSpan.Level)
        tooltip:SetCell(
            line,
            WoWFriendsColumn.Class,
            tooltipIcon.Class[classToken.Female[player.Class] or classToken.Male[player.Class]],
            nil,
            nil,
            WoWFriendsColSpan.Class
        )
        tooltip:SetCell(
            line,
            WoWFriendsColumn.PresenceName,
            ("%s%s"):format(player.StatusIcon, presenceName),
            nil,
            nil,
            WoWFriendsColSpan.PresenceName
        )
        tooltip:SetCell(
            line,
            WoWFriendsColumn.ToonName,
            ("%s%s%s|r%s"):format(
                Icon.Player.Faction,
                private.TooltipHandler.Class.Color[player.Class] or FRIENDS_WOW_NAME_COLOR_CODE,
                player.ToonName,
                groupIndicator
            ),
            nil,
            nil,
            WoWFriendsColSpan.ToonName
        )
        tooltip:SetCell(
            line,
            WoWFriendsColumn.ZoneName,
            private.MapHandler:ColoredZoneName(player.ZoneName),
            nil,
            nil,
            WoWFriendsColSpan.ZoneName
        )
        tooltip:SetCell(line, WoWFriendsColumn.RealmName, player.RealmName, nil, nil, WoWFriendsColSpan.RealmName)

        if player.PresenceID then
            tooltip:SetCellScript(line, WoWFriendsColumn.PresenceName, "OnMouseUp", BattleNetFriend_OnMouseUp, player)
        end

        if player.IsLocalFriend then
            tooltip:SetCellScript(line, WoWFriendsColumn.ToonName, "OnMouseUp", WoWFriend_OnMouseUp, player)
        end

        if player.Note then
            local noteText = FRIENDS_OTHER_NAME_COLOR_CODE .. player.Note .. "|r"

            if DB.Tooltip.NotesArrangement.WoWFriends == private.Preferences.Tooltip.NotesArrangement.Column then
                if not addedNoteColumn then
                    tooltip:SetCell(
                        headerLine,
                        WoWFriendsColumn.Note,
                        ColumnLabel(LABEL_NOTE, "WoWFriends:Note"),
                        nil,
                        nil,
                        WoWFriendsColSpan.Note
                    )
                    tooltip:SetCellScript(
                        headerLine,
                        WoWFriendsColumn.Note,
                        "OnMouseUp",
                        ToggleColumnSortMethod,
                        "WoWFriends:Note"
                    )

                    addedNoteColumn = true
                end
                tooltip:SetCell(line, WoWFriendsColumn.Note, noteText, nil, nil, WoWFriendsColSpan.Note)
            else
                tooltip:SetCell(
                    tooltip:AddLine(),
                    WoWFriendsColumn.Level,
                    Icon.Status.Note .. noteText,
                    "GameTooltipTextSmall",
                    nil,
                    0
                )
            end
        end

        if player.BroadcastText then
            tooltip:SetCell(
                tooltip:AddLine(),
                WoWFriendsColumn.Level,
                player.BroadcastText,
                "GameTooltipTextSmall",
                nil,
                0
            )
        end
    end

    tooltip:AddLine(" ")
end

-- ----------------------------------------------------------------------------
-- TooltipHandler Augmentation
-- ----------------------------------------------------------------------------
---@class TooltipHandler.WoWFriends
private.TooltipHandler.WoWFriends = {
    DisplaySectionWoWFriends = DisplaySectionWoWFriends,
    GenerateData = GenerateData,
}

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------
---@class WoWFriend
---@field BroadcastText string? -- Only set when the WoW friend is also a BattleNet friend
---@field Class string?
---@field FullToonName string?
---@field IsLocalFriend boolean
---@field Level number
---@field Note string?
---@field PresenceID? number -- Only set when the WoW friend is also a BattleNet friend
---@field PresenceName? string -- Only set when the WoW friend is also a BattleNet friend
---@field RealmName string
---@field StatusIcon string
---@field ToonName string
---@field ZoneName string
