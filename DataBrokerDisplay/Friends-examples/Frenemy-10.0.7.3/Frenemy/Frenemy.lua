-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

local DataObject = private.DataObject
local MapHandler = private.MapHandler
local TooltipHandler = private.TooltipHandler

---@class Frenemy: AceAddon, AceBucket-3.0, AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local Frenemy =
    LibStub("AceAddon-3.0"):NewAddon(AddOnFolderName, "AceBucket-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local HereBeDragons = LibStub("HereBeDragons-2.0")

-- ----------------------------------------------------------------------------
-- Events.
-- ----------------------------------------------------------------------------
---@param callbackName string Unused, but is passed from HereBeDragons so it must be handled in the parameter list.
---@param mapID number
function Frenemy:HandleZoneChange(callbackName, mapID)
    local needDisplayUpdate = MapHandler.Data.MapID ~= mapID
    MapHandler.Data.MapID = mapID

    if not MapHandler.Data.MapID or MapHandler.Data.MapID <= 0 then
        MapHandler.Data.MapName = UNKNOWN
        return
    end

    MapHandler.Data.MapName = HereBeDragons:GetLocalizedMap(mapID) or UNKNOWN

    local pvpType, _, factionName = GetZonePVPInfo()

    if pvpType == "hostile" or pvpType == "friendly" then
        pvpType = factionName
    elseif not pvpType or pvpType == "" then
        pvpType = "normal"
    end

    local zonePVPStatus = MapHandler.GetZonePVPStatus(pvpType)
    private.DB.ZoneData[MapHandler.Data.MapID] = zonePVPStatus

    MapHandler:SetRGBColor(MapHandler.Data.MapID, zonePVPStatus)

    if needDisplayUpdate then
        self:UpdateData()
    end
end

-- ----------------------------------------------------------------------------
-- Framework
-- ----------------------------------------------------------------------------
local function RequestUpdates()
    C_FriendList.ShowFriends()

    if IsInGuild() then
        C_GuildInfo.GuildRoster()
    end
end

local RequestUpdateInterval = 30

function Frenemy:OnEnable()
    self:RegisterBucketEvent({
        "BN_FRIEND_INFO_CHANGED",
        "FRIENDLIST_UPDATE",
        "GUILD_RANKS_UPDATE",
        "GUILD_ROSTER_UPDATE",
    }, 1, self.UpdateData)

    HereBeDragons.RegisterCallback(self, "PlayerZoneChanged", "HandleZoneChange")

    self:ScheduleRepeatingTimer(RequestUpdates, RequestUpdateInterval)

    RequestUpdates()
end

function Frenemy:OnInitialize()
    local DB = private.Preferences:InitializeDatabase()

    private.DB = DB

    local LDBIcon = LibStub("LibDBIcon-1.0")
    if LDBIcon then
        LDBIcon:Register(AddOnFolderName, DataObject, DB.DataObject.MinimapIcon)
    end

    private.Preferences:SetupOptions()

    self:RegisterChatCommand("frenemy", "ChatCommand")

    for zoneID, zonePVPStatus in pairs(DB.ZoneData) do
        MapHandler:SetRGBColor(zoneID, zonePVPStatus)
    end
end

do
    local UpdateDisplayThrottleIntervalSeconds = 5
    local lastUpdateTime = time()

    function Frenemy:UpdateData()
        private.UpdateStatistics()
        DataObject:UpdateDisplay()

        if TooltipHandler.Tooltip.Main and TooltipHandler.Tooltip.Main:IsShown() then
            local now = time()

            if now > lastUpdateTime + UpdateDisplayThrottleIntervalSeconds then
                lastUpdateTime = now

                TooltipHandler:Render(DataObject)
            end
        end
    end
end

do
    local SUBCOMMAND_FUNCS = {
        --[==[@debug@
        DEBUG = function()
            local debugger = private.GetDebugger()

            if debugger:Lines() == 0 then
                debugger:AddLine("Nothing to report.")
                debugger:Display()
                debugger:Clear()
                return
            end

            debugger:Display()
        end,
        --@end-debug@]==]
    }

    ---@param input string
    function Frenemy:ChatCommand(input)
        local subcommand, arguments = self:GetArgs(input, 2)

        if subcommand then
            local func = SUBCOMMAND_FUNCS[subcommand:upper()]

            if func then
                func(arguments or "")
            end
        else
            local settingsPanel = SettingsPanel

            if settingsPanel:IsVisible() then
                settingsPanel:Hide()
            else
                Settings.OpenToCategory(private.Preferences.OptionsFrame)
            end
        end
    end
end -- do-block
