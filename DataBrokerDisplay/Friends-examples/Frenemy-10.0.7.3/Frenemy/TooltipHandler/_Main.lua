-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

local Sorting = private.Sorting
local SortOrder = private.SortOrder

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnFolderName)

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------
-- Used to handle duplication between in-game and RealID friends.
local OnlineFriendsByName = {}

local PlayerData = {
    Faction = UnitFactionGroup("player"),
    Name = UnitName("player"),
    RealmName = GetRealmName(),
}

local PlayerLists = {
    BattleNetApp = {}, ---@type BattleNetFriend[]
    BattleNetGames = {}, ---@type BattleNetFriend[]
    Guild = {}, ---@type GuildMember[]
    WoWFriends = {}, ---@type WoWFriend[]
}

-- ----------------------------------------------------------------------------
-- Data Compilation
-- ----------------------------------------------------------------------------
---@param self TooltipHandler
local function GenerateData(self)
    for _, list in pairs(PlayerLists) do
        table.wipe(list)
    end

    table.wipe(OnlineFriendsByName)

    self.WoWFriends.GenerateData()
    self.BattleNet.GenerateData()
    self.Guild.GenerateData()

    for listName, list in pairs(PlayerLists) do
        local savedSortField = private.DB.Tooltip.Sorting[listName]

        table.sort(
            list,
            Sorting.Functions[listName .. Sorting.FieldNames[listName][savedSortField.Field] .. SortOrder.Name[savedSortField.Order]]
        )
    end
end

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
---@param level number
local function ColorPlayerLevel(level)
    if type(level) ~= "number" then
        return level
    end

    local color = GetRelativeDifficultyColor(UnitLevel("player"), level)

    return ("|cff%02x%02x%02x%d|r"):format(color.r * 255, color.g * 255, color.b * 255, level)
end

---@param label string
---@param data string
local function ColumnLabel(label, data)
    local sectionName, fieldName = strsplit(":", data)
    local DB = private.DB

    if DB.Tooltip.Sorting[sectionName].Field == Sorting.FieldIDs[sectionName][fieldName] then
        local Icon = private.TooltipHandler.Icon

        return (
            DB.Tooltip.Sorting[sectionName].Order == SortOrder.Enum.Ascending and Icon.Sort.Ascending
            or Icon.Sort.Descending
        ) .. label
    end

    return label
end

---@param name string The unit's name
local function IsUnitGrouped(name)
    return (GetNumSubgroupMembers() > 0 and UnitInParty(name)) or (GetNumGroupMembers() > 0 and UnitInRaid(name))
end

-- ----------------------------------------------------------------------------
-- SectionDropDown
-- ----------------------------------------------------------------------------
local SectionDropDown = CreateFrame("Frame", AddOnFolderName .. "SectionDropDown", UIParent, "UIDropDownMenuTemplate")
SectionDropDown.displayMode = "MENU"
SectionDropDown.info = {}
SectionDropDown.levelAdjust = 0

---@param currentPosition number
local function ChangeSectionOrder(self, currentPosition, direction)
    local sectionEntries = private.DB.Tooltip.SectionDisplayOrders
    local newPosition

    if direction == "up" then
        newPosition = currentPosition - 1
    elseif direction == "down" then
        newPosition = currentPosition + 1
    end

    if not newPosition then
        return
    end

    local evictedEntry = sectionEntries[newPosition]
    sectionEntries[newPosition] = sectionEntries[currentPosition]
    sectionEntries[currentPosition] = evictedEntry

    private.TooltipHandler:Render()
end

local function ToggleSectionVisibility(self, sectionName)
    local DB = private.DB

    DB.Tooltip.CollapsedSections[sectionName] = not DB.Tooltip.CollapsedSections[sectionName]

    private.TooltipHandler:Render()
end

local function InitializeSectionDropDown(self, level)
    if not level then
        return
    end

    local DB = private.DB
    local info = SectionDropDown.info
    table.wipe(info)

    if level == 1 then
        local sectionName = UIDROPDOWNMENU_MENU_VALUE

        info.arg1 = sectionName
        info.func = ToggleSectionVisibility
        info.notCheckable = true
        info.text = DB.Tooltip.CollapsedSections[sectionName] and L.EXPAND_SECTION or L.COLLAPSE_SECTION

        UIDropDownMenu_AddButton(info, level)

        local currentPosition

        for index = 1, #DB.Tooltip.SectionDisplayOrders do
            if DB.Tooltip.SectionDisplayOrders[index] == sectionName then
                currentPosition = index
                break
            end
        end

        if not currentPosition then
            return
        end

        info.arg1 = currentPosition
        info.func = ChangeSectionOrder

        if currentPosition ~= 1 then
            info.arg2 = "up"
            info.text = L.MOVE_SECTION_UP
            UIDropDownMenu_AddButton(info, level)
        end

        if currentPosition ~= #DB.Tooltip.SectionDisplayOrders then
            info.arg2 = "down"
            info.text = L.MOVE_SECTION_DOWN
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

SectionDropDown.initialize = InitializeSectionDropDown

-- ----------------------------------------------------------------------------
-- Cell Scripts
-- ----------------------------------------------------------------------------
local function BattleNetFriend_OnMouseUp(_, playerEntry, button)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "Master")

    if button == "LeftButton" then
        if IsAltKeyDown() and playerEntry.RealmName == PlayerData.RealmName then
            C_PartyInfo.InviteUnit(playerEntry.ToonName)
        elseif IsControlKeyDown() then
            FriendsFrame.NotesID = playerEntry.PresenceID
            StaticPopup_Show("SET_BNFRIENDNOTE", playerEntry.PresenceName)
        elseif not BNIsSelf(playerEntry.PresenceID) then
            ChatFrame_SendBNetTell(playerEntry.PresenceName)
        end
    elseif button == "RightButton" then
        private.TooltipHandler.Tooltip.Main:SetFrameStrata("DIALOG")
        CloseDropDownMenus()
        FriendsFrame_ShowBNDropdown(playerEntry.PresenceName, true, nil, nil, nil, true, playerEntry.PresenceID)
    end
end

local function SectionTitle_OnMouseUp(_, sectionName, mouseButton)
    if mouseButton == "RightButton" then
        private.TooltipHandler.Tooltip.Main:SetFrameStrata("DIALOG")
        CloseDropDownMenus()
        ToggleDropDownMenu(1, sectionName, SectionDropDown, "cursor")

        return
    end

    ToggleSectionVisibility(nil, sectionName)
end

local function ToggleColumnSortMethod(_, sortFieldData)
    local sectionName, fieldName = strsplit(":", sortFieldData)

    if not sectionName or not fieldName then
        return
    end

    local DB = private.DB
    local savedSortField = DB.Tooltip.Sorting[sectionName]
    local columnSortFieldID = Sorting.FieldIDs[sectionName][fieldName]

    if savedSortField.Field == columnSortFieldID then
        savedSortField.Order = savedSortField.Order == SortOrder.Enum.Ascending and SortOrder.Enum.Descending
            or SortOrder.Enum.Ascending
    else
        savedSortField = DB.Tooltip.Sorting[sectionName]
        savedSortField.Field = columnSortFieldID
        savedSortField.Order = SortOrder.Enum.Ascending
    end

    table.sort(
        PlayerLists[sectionName],
        Sorting.Functions[sectionName .. fieldName .. SortOrder.Name[savedSortField.Order]]
    )

    private.TooltipHandler:Render()
end

-- ----------------------------------------------------------------------------
-- Class Definitions
-- ----------------------------------------------------------------------------
local ClassData = {
    -- Dictionary of localizedName to class color
    Color = {},
    Token = {
        -- Dictionary of feminine localizedName to classToken
        Female = {},
        -- Dictionary of masculine localizedName to classToken
        Male = {},
    },
}

do
    ---@param localizedClassNames Dictionary<string>
    ---@param targetTokenList Dictionary<string>
    local function GenerateColorsAndTokens(localizedClassNames, targetTokenList)
        for classToken, localizedName in pairs(localizedClassNames) do
            local color = C_ClassColor.GetClassColor(classToken)

            if color then
                ClassData.Color[localizedName] = color:GenerateHexColorMarkup()
                targetTokenList[localizedName] = classToken
            end
        end
    end

    GenerateColorsAndTokens(LOCALIZED_CLASS_NAMES_FEMALE, ClassData.Token.Female)
    GenerateColorsAndTokens(LOCALIZED_CLASS_NAMES_MALE, ClassData.Token.Male)
end -- do-block

-- ----------------------------------------------------------------------------
-- Icon Definitions
-- ----------------------------------------------------------------------------
local ClassIcon = {}
do
    local textureFormat = [[|TInterface\TargetingFrame\UI-CLASSES-CIRCLES:0:0:0:0:256:256:%d:%d:%d:%d|t]]
    local textureSize = 256

    for index = 1, #CLASS_SORT_ORDER do
        local className = CLASS_SORT_ORDER[index]
        local left, right, top, bottom = unpack(CLASS_ICON_TCOORDS[className])
        ClassIcon[className] =
            textureFormat:format(left * textureSize, right * textureSize, top * textureSize, bottom * textureSize)
    end
end

---@param texturePath string
---@param iconSize? number
---@return string
local function CreateIcon(texturePath, iconSize)
    return ("|T%s:%d|t"):format(texturePath, iconSize or 0)
end

local FactionIconSize = 18

local FactionIcon = {
    Alliance = CreateIcon([[Interface\COMMON\icon-alliance]], FactionIconSize),
    Horde = CreateIcon([[Interface\COMMON\icon-horde]], FactionIconSize),
    Neutral = CreateIcon([[Interface\COMMON\Indicator-Gray]], FactionIconSize),
}

-- ----------------------------------------------------------------------------
-- TooltipHandler
-- ----------------------------------------------------------------------------
---@class TooltipHandler
---@field BattleNet TooltipHandler.BattleNet
---@field Guild TooltipHandler.Guild
---@field WoWFriends TooltipHandler.WoWFriends
---@field Render fun(self: TooltipHandler, anchorFrame?: Frame)
private.TooltipHandler = {
    GenerateData = GenerateData,
    CellScripts = {
        BattleNetFriend_OnMouseUp = BattleNetFriend_OnMouseUp,
        SectionTitle_OnMouseUp = SectionTitle_OnMouseUp,
        ToggleColumnSortMethod = ToggleColumnSortMethod,
    },
    Class = ClassData,
    Helpers = {
        ColorPlayerLevel = ColorPlayerLevel,
        ColumnLabel = ColumnLabel,
        IsUnitGrouped = IsUnitGrouped,
    },
    Icon = {
        Broadcast = CreateIcon([[Interface\FriendsFrame\BroadcastIcon]]),
        Class = ClassIcon,
        Column = {
            Class = CreateIcon([[Interface\GossipFrame\TrainerGossipIcon]]),
            Game = CreateIcon([[Interface\Buttons\UI-GroupLoot-Dice-Up]]),
            Level = CreateIcon([[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]]),
        },
        Help = CreateIcon([[Interface\COMMON\help-i]], 20),
        Faction = FactionIcon,
        Player = {
            Faction = FactionIcon[PlayerData.Faction] or FactionIcon.Neutral,
            Group = [[|TInterface\Scenarios\ScenarioIcon-Check:0|t]],
        },
        Section = {
            Disabled = CreateIcon([[Interface\COMMON\Indicator-Red]]),
            Enabled = CreateIcon([[Interface\COMMON\Indicator-Green]]),
        },
        Sort = {
            Ascending = CreateIcon([[Interface\Buttons\Arrow-Up-Up]]),
            Descending = CreateIcon([[Interface\Buttons\Arrow-Down-Up]]),
        },
        Status = {
            AFK = CreateIcon(FRIENDS_TEXTURE_AFK),
            DND = CreateIcon(FRIENDS_TEXTURE_DND),
            Mobile = {
                Away = CreateIcon([[Interface\ChatFrame\UI-ChatIcon-ArmoryChat-AwayMobile]]),
                Busy = CreateIcon([[Interface\ChatFrame\UI-ChatIcon-ArmoryChat-BusyMobile]]),
                Online = CreateIcon([[Interface\ChatFrame\UI-ChatIcon-ArmoryChat]]),
            },
            Note = CreateIcon(FRIENDS_TEXTURE_OFFLINE),
            Online = CreateIcon(FRIENDS_TEXTURE_ONLINE),
        },
    },
    OnlineFriendsByName = OnlineFriendsByName,
    Player = PlayerData,
    PlayerLists = PlayerLists,
    Tooltip = {
        AnchorFrame = nil, ---@type Frame|nil
        Help = nil, ---@type LibQTip.Tooltip|nil
        Main = nil, ---@type LibQTip.Tooltip|nil
    },
}
