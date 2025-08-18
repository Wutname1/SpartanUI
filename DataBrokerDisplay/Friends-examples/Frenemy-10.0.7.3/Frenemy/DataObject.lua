-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

local People = private.People
local TooltipHandler = private.TooltipHandler

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------
local FRIENDS_FRAME_TAB_TOGGLES = {
    FRIENDS = 1,
    WHO = 2,
    CHAT = 3,
    RAID = 4,
}

-- ----------------------------------------------------------------------------
-- DataObject
-- ----------------------------------------------------------------------------
---@class DataObject: LibDataBroker.DataDisplay
---@field UpdateDisplay fun(self: DataObject)
local DataObject = LibStub("LibDataBroker-1.1"):NewDataObject(AddOnFolderName, {
    icon = [[Interface\Calendar\MeetingIcon]],
    text = " ",
    type = "data source",
    OnClick = function(displayFrame, buttonName)
        if buttonName == "LeftButton" then
            if IsAltKeyDown() then
                ToggleGuildFrame()
            else
                ToggleFriendsFrame(FRIENDS_FRAME_TAB_TOGGLES.FRIENDS)
            end
        else
            local settingsPanel = SettingsPanel

            if settingsPanel:IsVisible() then
                settingsPanel:Hide()
            else
                Settings.OpenToCategory(private.Preferences.OptionsFrame)
            end
        end
    end,
    OnEnter = function(displayFrame)
        TooltipHandler:Render(displayFrame)
    end,
    OnLeave = function(displayFrame)
        -- Null operation: Some LDB displays get cranky if this method is missing.
    end,
})

private.DataObject = DataObject

function DataObject:UpdateDisplay()
    local text = ("%s: %s%d/%d|r"):format(
        FRIENDS,
        BATTLENET_FONT_COLOR_CODE,
        People.Friends.Online + People.BattleNet.Online,
        People.Friends.Total + People.BattleNet.Total
    )

    if not IsInGuild() then
        self.text = text

        return
    end

    self.text = ("%s %s: %s%d/%d|r"):format(
        text,
        GUILD,
        GREEN_FONT_COLOR_CODE,
        People.GuildMembers.Online,
        People.GuildMembers.Total
    )
end
