-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

-- ----------------------------------------------------------------------------
-- Initialization
-- ----------------------------------------------------------------------------
local metaVersion = GetAddOnMetadata(AddOnFolderName, "Version")
local isDevelopmentVersion = false
local isAlphaVersion = false

--[==[@debug@
isDevelopmentVersion = true
--@end-debug@]==]

--[=[@alpha@
isAlphaVersion = true
--@end-alpha@]=]

local buildVersion = isDevelopmentVersion and "Development Version"
    or (isAlphaVersion and metaVersion .. "-Alpha")
    or metaVersion

-- ----------------------------------------------------------------------------
-- Preferences
-- ----------------------------------------------------------------------------
---@type table
local Options

---@class Preferences
---@field DataObject Preferences.DataObject
---@field Tooltip Preferences.Tooltip
---@field OptionsFrame Frame
local Preferences = {
    DefaultValues = {
        global = {
            ZoneData = {}, -- Populated during travel.
        },
    },
    GetOptions = function()
        if not Options then
            Options = {
                name = ("%s - %s"):format(AddOnFolderName, buildVersion),
                type = "group",
                childGroups = "tab",
                args = {
                    dataObject = private.Preferences.DataObject.GetOptions(),
                    tooltip = private.Preferences.Tooltip.GetOptions(),
                },
            }
        end

        return Options
    end,
    ---@param self Preferences
    InitializeDatabase = function(self)
        return LibStub("AceDB-3.0"):New(AddOnFolderName .. "DB", self.DefaultValues, true).global
    end,
    ---@param self Preferences
    SetupOptions = function(self)
        LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(AddOnFolderName, self.GetOptions)
        self.OptionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddOnFolderName)
    end,
}

private.Preferences = Preferences
