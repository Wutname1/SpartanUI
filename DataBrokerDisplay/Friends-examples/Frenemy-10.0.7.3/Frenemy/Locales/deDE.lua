-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

---@type Localizations
local L = LibStub("AceLocale-3.0"):NewLocale(AddOnFolderName, "deDE", false)

if not L then
    return
end

L["ALT_KEY"] = "Alt-"
L["COLLAPSE_SECTION"] = "Einklappen"
L["COLUMN_LABEL_REALM"] = "Realm"
L["CONTROL_KEY"] = "Strg-"
L["EXPAND_SECTION"] = "Erweitern"
L["LEFT_CLICK"] = "Linksklick"
L["MINIMAP_ICON_DESC"] = "Das Interface als Minikartensymbol anzeigen."
L["MOVE_SECTION_DOWN"] = "Nach Unten bewegen"
L["MOVE_SECTION_UP"] = "Nach Oben bewegen"
L["NOTES_ARRANGEMENT_COLUMN"] = "Spalte"
L["NOTES_ARRANGEMENT_ROW"] = "Reihe"
L["RIGHT_CLICK"] = "Rechtsklick"
L["SHIFT_KEY"] = "Shift-"
L["TOOLTIP_HIDEDELAY_DESC"] = "Zeit, wie lange der Tooltip angezeigt wird, nachdem die Maus bewegt wurde."
L["TOOLTIP_HIDEDELAY_LABEL"] = "Ausblendungsverzögerung des Tooltips"
L["TOOLTIP_SCALE_LABEL"] = "Tooltipskalierung"

