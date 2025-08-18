-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

---@type Localizations
local L = LibStub("AceLocale-3.0"):NewLocale(AddOnFolderName, "ruRU", false)

if not L then
    return
end

L["ALT_KEY"] = "Alt-"
L["COLLAPSE_SECTION"] = "Свернуть"
L["COLUMN_LABEL_REALM"] = "Сервер"
L["CONTROL_KEY"] = "Ctrl- "
L["EXPAND_SECTION"] = "Развернуть"
L["LEFT_CLICK"] = "Левый клик"
L["MINIMAP_ICON_DESC"] = "Показать иконку у мини карты."
L["MOVE_SECTION_DOWN"] = "Сдвинуть вниз"
L["MOVE_SECTION_UP"] = "Сдвинуть вверх"
L["NOTES_ARRANGEMENT_COLUMN"] = "Колонки"
L["NOTES_ARRANGEMENT_ROW"] = "Полосы"
L["RIGHT_CLICK"] = "Правый клик"
L["SHIFT_KEY"] = "Shift-"
L["TOOLTIP_HIDEDELAY_DESC"] = "Сколько будет показываться подсказка после перемещения курсора (в секундах)."
L["TOOLTIP_HIDEDELAY_LABEL"] = "Задержка затухания подсказки"
L["TOOLTIP_SCALE_LABEL"] = "Масштаб подсказки"

