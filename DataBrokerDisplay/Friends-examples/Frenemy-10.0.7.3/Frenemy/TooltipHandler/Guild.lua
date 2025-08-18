-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

local Icon = private.TooltipHandler.Icon
local MapHandler = private.MapHandler
local Player = private.TooltipHandler.Player
local PlayerLists = private.TooltipHandler.PlayerLists

local ColorPlayerLevel = private.TooltipHandler.Helpers.ColorPlayerLevel
local ColumnLabel = private.TooltipHandler.Helpers.ColumnLabel
local IsUnitGrouped = private.TooltipHandler.Helpers.IsUnitGrouped
local SectionTitle_OnMouseUp = private.TooltipHandler.CellScripts.SectionTitle_OnMouseUp
local ToggleColumnSortMethod = private.TooltipHandler.CellScripts.ToggleColumnSortMethod

local Dialog = LibStub("LibDialog-1.0")
local HereBeDragons = LibStub("HereBeDragons-2.0")

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------
-- Used to handle duplication between in-game and RealID friends.
local GuildMemberIndexByName = {}

-- ----------------------------------------------------------------------------
-- Column and ColSpan
-- ----------------------------------------------------------------------------
local GuildColumn = {
    Level = 1,
    Class = 2,
    ToonName = 3,
    Rank = 4,
    ZoneName = 5,
    PublicNote = 6,
    OfficerNote = 8,
}

local GuildColSpan = {
    Level = 1,
    Class = 1,
    ToonName = 1,
    Rank = 1,
    ZoneName = 1,
    PublicNote = 2,
    OfficerNote = 2,
}

-- ----------------------------------------------------------------------------
-- Data Compilation
-- ----------------------------------------------------------------------------
local function GenerateData()
    table.wipe(GuildMemberIndexByName)

    if not IsInGuild() then
        return
    end

    for index = 1, GetNumGuildMembers() do
        local fullToonName, rank, rankIndex, level, class, zoneName, note, officerNote, isOnline, awayStatus, _, _, _, isMobile =
            GetGuildRosterInfo(index)

        if isOnline or isMobile then
            local toonName, realmName = strsplit("-", fullToonName)

            local statusIcon
            if awayStatus == 0 then
                statusIcon = isOnline and Icon.Status.Online or Icon.Status.Mobile.Online
            elseif awayStatus == 1 then
                statusIcon = isOnline and Icon.Status.AFK or Icon.Status.Mobile.Away
            elseif awayStatus == 2 then
                statusIcon = isOnline and Icon.Status.DND or Icon.Status.Mobile.Busy
            end

            -- Don't rely on the zoneName from GetGuildRosterInfo - it can be slow, and the player should see their own zone change instantaneously if
            -- traveling with the tooltip showing.
            if isOnline and toonName == Player.Name then
                zoneName = MapHandler.Data.MapName
            end

            GuildMemberIndexByName[fullToonName] = index
            GuildMemberIndexByName[toonName] = index

            table.insert(
                PlayerLists.Guild,
                ---@type GuildMember
                {
                    Class = class,
                    FullToonName = fullToonName,
                    IsMobile = isMobile,
                    Level = level,
                    OfficerNote = officerNote ~= "" and officerNote or nil,
                    PublicNote = note ~= "" and note or nil,
                    Rank = rank,
                    RankIndex = rankIndex,
                    RealmName = realmName or Player.RealmName,
                    StatusIcon = statusIcon,
                    ToonName = toonName,
                    ZoneName = isMobile
                            and (isOnline and ("%s %s"):format(zoneName or UNKNOWN, PARENS_TEMPLATE:format(REMOTE_CHAT)) or REMOTE_CHAT)
                        or (zoneName or UNKNOWN),
                }
            )
        end
    end
end

-- ----------------------------------------------------------------------------
-- Dialogs
-- ----------------------------------------------------------------------------
Dialog:Register("FrenemySetGuildMOTD", {
    editboxes = {
        {
            on_enter_pressed = function(self)
                GuildSetMOTD(self:GetText())
                Dialog:Dismiss("FrenemySetGuildMOTD")
            end,
            on_escape_pressed = function(self)
                Dialog:Dismiss("FrenemySetGuildMOTD")
            end,
            on_show = function(self)
                self:SetText(GetGuildRosterMOTD())
            end,
            auto_focus = true,
            label = GREEN_FONT_COLOR_CODE .. GUILDCONTROL_OPTION9 .. "|r",
            max_letters = 128,
            text = GetGuildRosterMOTD(),
            width = 200,
        },
    },
    hide_on_escape = true,
    icon = [[Interface\Calendar\MeetingIcon]],
    on_show = function(self)
        self.text:SetFormattedText("%s%s|r", BATTLENET_FONT_COLOR_CODE, AddOnFolderName)
    end,
    show_while_dead = true,
    width = 400,
})

-- ----------------------------------------------------------------------------
-- Cell Scripts
-- ----------------------------------------------------------------------------
---@param button "LeftButton"|"RightButton"
local function GuildMember_OnMouseUp(_, playerEntry, button)
    if not IsAddOnLoaded("Blizzard_GuildUI") then
        LoadAddOn("Blizzard_GuildUI")
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "Master")

    local playerName = playerEntry.Realm == Player.RealmName and playerEntry.ToonName or playerEntry.FullToonName

    if button == "LeftButton" then
        if IsAltKeyDown() then
            C_PartyInfo.InviteUnit(playerName)
        elseif IsControlKeyDown() and CanEditPublicNote() then
            SetGuildRosterSelection(GuildMemberIndexByName[playerName])
            StaticPopup_Show("SET_GUILDPLAYERNOTE")
        else
            ChatFrame_SendTell(playerName)
        end
    elseif button == "RightButton" then
        if IsControlKeyDown() and C_GuildInfo.CanEditOfficerNote() then
            SetGuildRosterSelection(GuildMemberIndexByName[playerName])
            StaticPopup_Show("SET_GUILDOFFICERNOTE")
        else
            private.TooltipHandler.Tooltip.Main:SetFrameStrata("DIALOG")
            CloseDropDownMenus()
            GuildRoster_ShowMemberDropDown(playerName, true, playerEntry.IsMobile)
        end
    end
end

local function GuildMOTD_OnMouseUp()
    Dialog:Spawn("FrenemySetGuildMOTD")
end

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
local function PercentColorGradient(min, max)
    local red_low, green_low, blue_low = 1, 0.10, 0.10
    local red_mid, green_mid, blue_mid = 1, 1, 0
    local red_high, green_high, blue_high = 0.25, 0.75, 0.25
    local percentage = min / max

    if percentage >= 1 then
        return red_high, green_high, blue_high
    elseif percentage <= 0 then
        return red_low, green_low, blue_low
    end

    local integral, fractional = math.modf(percentage * 2)

    if integral == 1 then
        red_low, green_low, blue_low, red_mid, green_mid, blue_mid =
            red_mid, green_mid, blue_mid, red_high, green_high, blue_high
    end

    return red_low + (red_mid - red_low) * fractional,
        green_low + (green_mid - green_low) * fractional,
        blue_low + (blue_mid - blue_low) * fractional
end

-- ----------------------------------------------------------------------------
-- Guild
-- ----------------------------------------------------------------------------
---@param tooltip LibQTip.Tooltip
local function DisplaySectionGuild(tooltip)
    if #PlayerLists.Guild == 0 then
        return
    end

    local DB = private.DB
    local line = tooltip:AddLine()

    if DB.Tooltip.CollapsedSections.Guild then
        tooltip:SetCell(
            line,
            1,
            ("%s%s%s"):format(Icon.Section.Disabled, GetGuildInfo("player"), Icon.Section.Disabled),
            "GameFontDisable",
            "CENTER",
            0
        )
        tooltip:SetCellScript(line, 1, "OnMouseUp", SectionTitle_OnMouseUp, "Guild")

        return
    end

    tooltip:SetCell(
        line,
        1,
        ("%s%s%s"):format(Icon.Section.Enabled, GetGuildInfo("player"), Icon.Section.Enabled),
        "GameFontNormal",
        "CENTER",
        0
    )
    tooltip:SetCellScript(line, 1, "OnMouseUp", SectionTitle_OnMouseUp, "Guild")

    tooltip:AddSeparator(1, 0.5, 0.5, 0.5)

    -- ----------------------------------------------------------------------------
    -- Section Header
    -- ----------------------------------------------------------------------------
    local headerLine = tooltip:AddLine()
    tooltip:SetLineColor(headerLine, 0, 0, 0, 1)
    tooltip:SetCell(
        headerLine,
        GuildColumn.Level,
        ColumnLabel(Icon.Column.Level, "Guild:Level"),
        nil,
        nil,
        GuildColSpan.Level
    )
    tooltip:SetCellScript(headerLine, GuildColumn.Level, "OnMouseUp", ToggleColumnSortMethod, "Guild:Level")

    tooltip:SetCell(
        headerLine,
        GuildColumn.Class,
        ColumnLabel(Icon.Column.Class, "Guild:Class"),
        nil,
        nil,
        GuildColSpan.Class
    )
    tooltip:SetCellScript(headerLine, GuildColumn.Class, "OnMouseUp", ToggleColumnSortMethod, "Guild:Class")

    tooltip:SetCell(
        headerLine,
        GuildColumn.ToonName,
        ColumnLabel(NAME, "Guild:ToonName"),
        nil,
        nil,
        GuildColSpan.ToonName
    )
    tooltip:SetCellScript(headerLine, GuildColumn.ToonName, "OnMouseUp", ToggleColumnSortMethod, "Guild:ToonName")

    tooltip:SetCell(headerLine, GuildColumn.Rank, ColumnLabel(RANK, "Guild:RankIndex"), nil, nil, GuildColSpan.Rank)
    tooltip:SetCellScript(headerLine, GuildColumn.Rank, "OnMouseUp", ToggleColumnSortMethod, "Guild:RankIndex")

    tooltip:SetCell(
        headerLine,
        GuildColumn.ZoneName,
        ColumnLabel(ZONE, "Guild:ZoneName"),
        nil,
        nil,
        GuildColSpan.ZoneName
    )
    tooltip:SetCellScript(headerLine, GuildColumn.ZoneName, "OnMouseUp", ToggleColumnSortMethod, "Guild:ZoneName")

    -- ----------------------------------------------------------------------------
    -- Section Body
    -- ----------------------------------------------------------------------------
    local addedPublicNoteColumn
    local addedOfficerNoteColumn

    tooltip:AddSeparator(1, 0.5, 0.5, 0.5)

    local numGuildRanks = GuildControlGetNumRanks()

    local classToken = private.TooltipHandler.Class.Token
    local tooltipIcon = private.TooltipHandler.Icon

    for index = 1, #PlayerLists.Guild do
        local player = PlayerLists.Guild[index]

        line = tooltip:AddLine()
        tooltip:SetCell(line, GuildColumn.Level, ColorPlayerLevel(player.Level), nil, nil, GuildColSpan.Level)
        tooltip:SetCell(
            line,
            GuildColumn.Class,
            tooltipIcon.Class[classToken.Female[player.Class] or classToken.Male[player.Class]],
            nil,
            nil,
            GuildColSpan.Class
        )

        tooltip:SetCell(
            line,
            GuildColumn.ToonName,
            ("%s%s%s|r%s"):format(
                player.StatusIcon,
                private.TooltipHandler.Class.Color[player.Class] or "|cffffff",
                player.ToonName,
                IsUnitGrouped(player.ToonName) and Icon.Player.Group or ""
            ),
            nil,
            nil,
            GuildColSpan.ToonName
        )
        tooltip:SetCellScript(line, GuildColumn.ToonName, "OnMouseUp", GuildMember_OnMouseUp, player)

        -- The higher the rank index, the lower the priviledge; guild leader is rank 1.
        local r, g, b = PercentColorGradient(player.RankIndex, numGuildRanks)
        tooltip:SetCell(
            line,
            GuildColumn.Rank,
            ("|cff%02x%02x%02x%s|r"):format(r * 255, g * 255, b * 255, player.Rank),
            nil,
            nil,
            GuildColSpan.Rank
        )
        tooltip:SetCell(
            line,
            GuildColumn.ZoneName,
            MapHandler:ColoredZoneName(player.ZoneName),
            nil,
            nil,
            GuildColSpan.ZoneName
        )

        if player.PublicNote then
            local noteText = FRIENDS_OTHER_NAME_COLOR_CODE .. player.PublicNote .. "|r"

            if DB.Tooltip.NotesArrangement.Guild == private.Preferences.Tooltip.NotesArrangement.Column then
                if not addedPublicNoteColumn then
                    tooltip:SetCell(
                        headerLine,
                        GuildColumn.PublicNote,
                        ColumnLabel(NOTE, "Guild:PublicNote"),
                        nil,
                        nil,
                        GuildColSpan.PublicNote
                    )
                    tooltip:SetCellScript(
                        headerLine,
                        GuildColumn.PublicNote,
                        "OnMouseUp",
                        ToggleColumnSortMethod,
                        "Guild:PublicNote"
                    )

                    addedPublicNoteColumn = true
                end
                tooltip:SetCell(line, GuildColumn.PublicNote, noteText, nil, nil, GuildColSpan.PublicNote)
            else
                tooltip:SetCell(
                    tooltip:AddLine(),
                    GuildColumn.Level,
                    Icon.Status.Note .. noteText,
                    "GameTooltipTextSmall",
                    nil,
                    0
                )
            end
        end

        if player.OfficerNote then
            local noteText = ORANGE_FONT_COLOR_CODE .. player.OfficerNote .. "|r"

            if DB.Tooltip.NotesArrangement.GuildOfficer == private.Preferences.Tooltip.NotesArrangement.Column then
                if not addedOfficerNoteColumn then
                    tooltip:SetCell(
                        headerLine,
                        GuildColumn.OfficerNote,
                        ColumnLabel(GUILD_OFFICERNOTES_LABEL, "Guild:OfficerNote"),
                        nil,
                        nil,
                        GuildColSpan.OfficerNote
                    )
                    tooltip:SetCellScript(
                        headerLine,
                        GuildColumn.OfficerNote,
                        "OnMouseUp",
                        ToggleColumnSortMethod,
                        "Guild:OfficerNote"
                    )

                    addedOfficerNoteColumn = true
                end
                tooltip:SetCell(line, GuildColumn.OfficerNote, noteText, nil, nil, GuildColSpan.OfficerNote)
            else
                tooltip:SetCell(
                    tooltip:AddLine(),
                    GuildColumn.Level,
                    Icon.Status.Note .. noteText,
                    "GameTooltipTextSmall",
                    nil,
                    0
                )
            end
        end
    end

    local MOTD = private.TooltipHandler.Guild.MOTD
    MOTD.Text = GetGuildRosterMOTD()

    if not MOTD.Text or MOTD.Text == "" then
        tooltip:AddLine(" ")

        return
    end

    tooltip:AddLine(" ")

    local headerLineMOTD = tooltip:AddLine()
    tooltip:SetCell(headerLineMOTD, 1, GUILD_MOTD_TEMPLATE:gsub('"%%s"', ""), nil, "CENTER", 0)

    MOTD.LineID = tooltip:AddLine()

    if CanEditMOTD() then
        tooltip:SetCellScript(MOTD.LineID, 1, "OnMouseUp", GuildMOTD_OnMouseUp)
    end

    tooltip:AddLine(" ")
end

-- ----------------------------------------------------------------------------
-- TooltipHandler Augmentation
-- ----------------------------------------------------------------------------
---@class TooltipHandler.Guild
private.TooltipHandler.Guild = {
    DisplaySectionGuild = DisplaySectionGuild,
    GenerateData = GenerateData,
    MOTD = {
        LineID = nil, ---@type number|nil
        Text = nil, ---@type string|nil
    },
}

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------
---@class GuildMember
---@field Class string
---@field FullToonName string
---@field IsMobile boolean
---@field Level number
---@field OfficerNote string?
---@field PublicNote string?
---@field Rank string
---@field RankIndex number
---@field RealmName string
---@field StatusIcon string
---@field ToonName string
---@field ZoneName string
