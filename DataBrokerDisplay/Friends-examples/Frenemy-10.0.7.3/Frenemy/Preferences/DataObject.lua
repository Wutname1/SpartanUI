-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnFolderName)

-- ----------------------------------------------------------------------------
-- DataObject Options
-- ----------------------------------------------------------------------------
---@type table
local DataObjectOptions

local function GetOptions()
    if not DataObjectOptions then
        local DB = private.DB
        local LDBIcon = LibStub("LibDBIcon-1.0")

        DataObjectOptions = {
            order = 1,
            name = INFO,
            type = "group",
            args = {},
        }

        if LDBIcon then
            DataObjectOptions.args.miniMap = {
                order = 1,
                type = "toggle",
                name = MINIMAP_LABEL,
                desc = L.MINIMAP_ICON_DESC,
                get = function()
                    return not DB.DataObject.MinimapIcon.hide
                end,
                set = function(info, value)
                    DB.DataObject.MinimapIcon.hide = not DB.DataObject.MinimapIcon.hide
                    LDBIcon[DB.DataObject.MinimapIcon.hide and "Hide" or "Show"](LDBIcon, AddOnFolderName)
                end,
            }
        end
    end

    return DataObjectOptions
end

-- ----------------------------------------------------------------------------
-- Preferences Augmentation
-- ----------------------------------------------------------------------------
---@class Preferences.DataObject
private.Preferences.DataObject = {
    GetOptions = GetOptions,
}

private.Preferences.DefaultValues.global.DataObject = {
    MinimapIcon = {
        hide = false,
    },
}
