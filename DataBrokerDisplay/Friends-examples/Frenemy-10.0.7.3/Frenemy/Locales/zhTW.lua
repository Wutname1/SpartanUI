-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

---@type Localizations
local L = LibStub("AceLocale-3.0"):NewLocale(AddOnFolderName, "zhTW", false)

if not L then
    return
end

L["ALT_KEY"] = "Alt-"
L["COLLAPSE_SECTION"] = "摺疊"
L["COLUMN_LABEL_REALM"] = "伺服器"
L["CONTROL_KEY"] = "Ctrl-"
L["EXPAND_SECTION"] = "開展"
L["LEFT_CLICK"] = "左鍵點擊"
L["MINIMAP_ICON_DESC"] = "顯示介面在小地圖圖標。"
L["MOVE_SECTION_DOWN"] = "下移"
L["MOVE_SECTION_UP"] = "上移"
L["NOTES_ARRANGEMENT_COLUMN"] = "列"
L["NOTES_ARRANGEMENT_ROW"] = "行"
L["RIGHT_CLICK"] = "右鍵點擊"
L["SHIFT_KEY"] = "Shift-"
L["TOOLTIP_HIDEDELAY_DESC"] = "在滑鼠移動之後工具提示繼續顯示的時間。"
L["TOOLTIP_HIDEDELAY_LABEL"] = "工具提示隱藏延遲"
L["TOOLTIP_SCALE_LABEL"] = "工具提示縮放"

