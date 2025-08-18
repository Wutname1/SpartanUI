-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

---@type Localizations
local L = LibStub("AceLocale-3.0"):NewLocale(AddOnFolderName, "ptBR", false)

if not L then
    return
end

L["ALT_KEY"] = "Alt-"
L["COLLAPSE_SECTION"] = "Recolher"
L["COLUMN_LABEL_REALM"] = "Servidor"
L["CONTROL_KEY"] = "Ctrl-"
L["EXPAND_SECTION"] = "Expandir"
L["LEFT_CLICK"] = "Botão da Esquerda"
L["MINIMAP_ICON_DESC"] = "Mostrar interface como ícone no minimapa"
L["MOVE_SECTION_DOWN"] = "Desça"
L["MOVE_SECTION_UP"] = "Subir"
L["NOTES_ARRANGEMENT_COLUMN"] = "Coluna"
L["NOTES_ARRANGEMENT_ROW"] = "Linha"
L["RIGHT_CLICK"] = "Botão da Direita"
L["SHIFT_KEY"] = "Shift-"
L["TOOLTIP_HIDEDELAY_DESC"] = "Segundos que a tooltip continuará a ser mostrada depois que o mouse foi movido."
L["TOOLTIP_HIDEDELAY_LABEL"] = "Tempo para Esconder a Tooltip"
L["TOOLTIP_SCALE_LABEL"] = "Tamanho da Tooltip"

