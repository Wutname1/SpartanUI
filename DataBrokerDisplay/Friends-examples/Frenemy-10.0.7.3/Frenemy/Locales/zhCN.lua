-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

---@type Localizations
local L = LibStub("AceLocale-3.0"):NewLocale(AddOnFolderName, "zhCN", false)

if not L then
    return
end

L["ALT_KEY"] = "Alt-"
L["COLUMN_LABEL_REALM"] = "服务器"
L["CONTROL_KEY"] = "Ctrl-"
L["LEFT_CLICK"] = "左键点击"
L["MINIMAP_ICON_DESC"] = "显示接口在小地图图标。"
L["NOTES_ARRANGEMENT_COLUMN"] = "行"
L["NOTES_ARRANGEMENT_ROW"] = "列"
L["RIGHT_CLICK"] = "右键点击"
L["SHIFT_KEY"] = "Shift-"
L["TOOLTIP_HIDEDELAY_DESC"] = "在鼠标移动之后工具提示继续显示的时间。"
L["TOOLTIP_HIDEDELAY_LABEL"] = "工具提示隐藏延迟"
L["TOOLTIP_SCALE_LABEL"] = "工具提示缩放"

