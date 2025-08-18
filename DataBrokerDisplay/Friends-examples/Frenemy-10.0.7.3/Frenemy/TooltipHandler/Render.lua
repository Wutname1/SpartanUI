-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnFolderName)
local LibQTip = LibStub("LibQTip-1.0")

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------
local MaxTooltipColumns = 10

local HelpTipDefinitions = {
    [DISPLAY] = {
        [L.LEFT_CLICK] = BINDING_NAME_TOGGLEFRIENDSTAB,
        [L.ALT_KEY .. L.LEFT_CLICK] = BINDING_NAME_TOGGLEGUILDTAB,
        [L.RIGHT_CLICK] = INTERFACE_OPTIONS,
    },
    [NAME] = {
        [L.LEFT_CLICK] = WHISPER,
        [L.RIGHT_CLICK] = ADVANCED_OPTIONS,
        [L.ALT_KEY .. L.LEFT_CLICK] = INVITE,
        [L.CONTROL_KEY .. L.LEFT_CLICK] = SET_NOTE,
        [L.CONTROL_KEY .. L.RIGHT_CLICK] = GUILD_OFFICER_NOTE,
    },
}

-- ----------------------------------------------------------------------------
-- Cell Scripts
-- ----------------------------------------------------------------------------
local function HideHelpTip()
    local handler = private.TooltipHandler

    if handler.Tooltip.Help then
        LibQTip:Release(handler.Tooltip.Help)
        handler.Tooltip.Help = nil
    end

    handler.Tooltip.Main:SetFrameStrata("TOOLTIP") -- This can be set to DIALOG by various functions.
end

local function ShowHelpTip(tooltipCell)
    local handler = private.TooltipHandler
    local helpTip = handler.Tooltip.Help

    if not helpTip then
        helpTip = LibQTip:Acquire(AddOnFolderName .. "HelpTip", 2)
        helpTip:SetAutoHideDelay(0.1, tooltipCell)
        helpTip:SetBackdropColor(0.05, 0.05, 0.05, 1)
        helpTip:SetScale(private.DB.Tooltip.Scale)
        helpTip:SmartAnchorTo(tooltipCell)
        helpTip:SetScript("OnLeave", function()
            LibQTip:Release(helpTip)
        end)
        helpTip:Clear()
        helpTip:SetCellMarginH(0)
        helpTip:SetCellMarginV(1)

        handler.Tooltip.Help = helpTip
    end

    local isInitialSection = true

    for entryType, data in pairs(HelpTipDefinitions) do
        if not isInitialSection then
            helpTip:AddLine(" ")
        end

        local line = helpTip:AddLine()

        helpTip:SetCell(line, 1, entryType, GameFontNormal, "CENTER", 0)
        helpTip:AddSeparator(1, 0.5, 0.5, 0.5)

        for keyStroke, description in pairs(data) do
            line = helpTip:AddLine()
            helpTip:SetCell(line, 1, keyStroke)
            helpTip:SetCell(line, 2, description)
        end

        isInitialSection = false
    end

    HideDropDownMenu(1)

    handler.Tooltip.Main:SetFrameStrata("DIALOG")
    helpTip:Show()
end

-- ----------------------------------------------------------------------------
-- Display rendering
-- ----------------------------------------------------------------------------
---@param self LibQTip.Tooltip
local function Tooltip_OnRelease(self)
    HideDropDownMenu(1)
    HideHelpTip()

    self:SetFrameStrata("TOOLTIP") -- This can be set to DIALOG by various functions.

    local handler = private.TooltipHandler
    handler.Tooltip.AnchorFrame = nil
    handler.Tooltip.Main = nil
end

local TitleFont = CreateFont("FrenemyTitleFont")
TitleFont:SetTextColor(0.510, 0.773, 1.0)
TitleFont:SetFontObject("QuestTitleFont")

local SectionDisplayFunction = {
    WoWFriends = private.TooltipHandler.WoWFriends.DisplaySectionWoWFriends,
    BattleNetGames = private.TooltipHandler.BattleNet.DisplaySectionBattleNetGames,
    BattleNetApp = private.TooltipHandler.BattleNet.DisplaySectionBattleNetApp,
    Guild = private.TooltipHandler.Guild.DisplaySectionGuild,
}

---@param self TooltipHandler
---@param anchorFrame? Frame Anchor frame for the tooltip display
function private.TooltipHandler:Render(anchorFrame)
    anchorFrame = anchorFrame or self.Tooltip.AnchorFrame

    if not anchorFrame then
        return
    end

    self.Tooltip.AnchorFrame = anchorFrame
    self:GenerateData()

    local DB = private.DB
    local tooltip = self.Tooltip.Main

    if not tooltip then
        tooltip = LibQTip:Acquire(AddOnFolderName, MaxTooltipColumns)
        self.Tooltip.Main = tooltip

        tooltip:SetAutoHideDelay(DB.Tooltip.HideDelay, anchorFrame)
        tooltip:SetBackdropColor(0.05, 0.05, 0.05, 1)
        tooltip:SetScale(DB.Tooltip.Scale)
        tooltip:SmartAnchorTo(anchorFrame)
        tooltip:SetHighlightTexture([[Interface\ClassTrainerFrame\TrainerTextures]])
        tooltip:SetHighlightTexCoord(0.00195313, 0.57421875, 0.75390625, 0.84570313)

        tooltip.OnRelease = Tooltip_OnRelease
    end

    tooltip:Clear()
    tooltip:SetCellMarginH(0)
    tooltip:SetCellMarginV(1)

    tooltip:SetCell(tooltip:AddLine(), 1, AddOnFolderName, TitleFont, "CENTER", 0)
    tooltip:AddSeparator(1, 0.510, 0.773, 1.0)

    local MOTD = self.Guild.MOTD
    MOTD.LineID = nil
    MOTD.Text = nil

    for index = 1, #DB.Tooltip.SectionDisplayOrders do
        SectionDisplayFunction[DB.Tooltip.SectionDisplayOrders[index]](tooltip)
    end

    tooltip:Show()

    -- This must be done after everything else has been added to the tooltip in order to have an accurate width.
    if MOTD.LineID and MOTD.Text then
        tooltip:SetCell(
            MOTD.LineID,
            1,
            ("%s%s|r"):format(GREEN_FONT_COLOR_CODE, MOTD.Text),
            nil,
            "LEFT",
            0,
            nil,
            0,
            0,
            tooltip:GetWidth() - 20
        )
    end

    tooltip:AddSeparator(1, 0.510, 0.773, 1.0)

    local line = tooltip:AddLine()
    tooltip:SetCell(line, MaxTooltipColumns, self.Icon.Help, nil, "RIGHT", 0)
    tooltip:SetCellScript(line, MaxTooltipColumns, "OnEnter", ShowHelpTip)
    tooltip:SetCellScript(line, MaxTooltipColumns, "OnLeave", HideHelpTip)
    tooltip:SetCellScript(line, MaxTooltipColumns, "OnMouseDown", HideHelpTip)

    tooltip:UpdateScrolling()
end
