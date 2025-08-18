--[===[ File
    This file is NOT to be included in the TOC file!
    This is intended for IDE Intellisense.
--]===]

--[[ IDE
    This file is NOT to be included in the TOC file!
    This is intended to be used for IDE Intellisense.

    Tools used:
    Visual Studio Code - https://code.visualstudio.com/
    Other IDEs accept Lua Language Server, see if your prefered IDE will accept LLS

    Lua Language Server (LLS) - https://marketplace.visualstudio.com/items?itemName=sumneko.lua
        https://github.com/LuaLS/lua-language-server
    WoW API - LLS extension - https://marketplace.visualstudio.com/items?itemName=ketho.wow-api
        https://github.com/Ketho/vscode-wow-api

    This file is to remove errors and warnings thrown by the tools used.
    It declares variables and tables :
    - That are not readily available to the IDE
    - That are declared via indirection as the drop down lib is
    - When Lua 'best practice' parser is stricter than Lua is
    - When Titan is checking for an addon the user may or may not have loaded
    
    Titan may contain IDE annotations. 
    These are ---@<tag> to help the parser understand the intent of the code.

    Some Titan files may contain lines beginning with
---@diagnostic 
    These remove LLS errors where
    - Titan is handling Classic versions that use deprecated routines
    - Possibly the WoW extension is out of date or the Blizz documentation is wrong

    Note the diagnostic could be by line, file, or workspace / project.
--]]

-- Use Linux command below to get a rough line count of a Titan release.
-- find . -wholename "*.tga" -prune -o -wholename "*.code*" -prune -o -wholename "*.blp" -prune -o -wholename "*/libs/*" -prune -o -wholename "*/Artwork/*" -prune -o -print | xargs wc -l

--====== Frames from Titan Template XML
TitanPanelButtonTemplate = {}
TitanPanelTextTemplate = {}
TitanPanelIconTemplate = {}
TitanPanelComboTemplate = {}
TitanOptionsSliderTemplate = {}
TitanPanelTooltip = {}
TitanPanelBarButtonHiderTemplate = {}
TitanPanelBarButton = {}
Titan_Bar__Display_Template = {}

--====== Frames from Titan XML
TitanPanelTopAnchor = {}
TitanPanelBottomAnchor = {}

--====== Frames from Titan plugins created in XML or in Titan code
TitanPanelAmmoButton = {}

TitanRepairTooltip = {}

TitanPanelLocationButton = {}
TitanMapPlayerLocation = {}
TitanMapCursorLocation = {}

TitanPanelLootTypeFrame = {}
TitanPanelLootTypeButton = {}
TitanPanelLootTypeMainWindow = {}
TitanPanelLootTypeFrameClearButton = {}
TitanPanelLootTypeFrameAnnounceButton = {}
TitanPanelLootTypeFrameNotRolledButton = {}
TitanPanelLootTypeFrameRollButton = {}
TitanPanelLootTypeFramePassButton = {}
RollTrackerRollText = {}
TitanPanelLootTypeFrameStatusText = {}
TitanPanelLootTypeFrameHelperButton = {}
TitanPanelLootTypeMainWindowTitle = {}

TitanPanelPerfControlFrame = {}

TitanPanelMasterVolumeControlSlider = {}
TitanPanelAmbienceVolumeControlSlider = {}
TitanPanelDialogVolumeControlSlider = {}
TitanPanelSoundVolumeControlSlider = {}
TitanPanelMusicVolumeControlSlider = {}

TitanPanelXPButton = {}
TitanPanelXPButtonIcon = {}

--====== Libs that may exist or adjusting for libs
AceLibrary = {}
Tablet20Frame = {}
---@class AceAddon

AceHook = {}
-- @param obj string | function The object or frame to unhook from
-- @param method function The name of the method, function or script to unhook from.
function AceHook:IsHooked(obj, method)
    -- Ace does a parameter shift if obj is a string
    -- But the param does not reflect this...
end

--====== WoW localized globals
-- Should be handled by the WoW extension
ACCOUNT_QUEST_LABEL = "" -- 11.0.0 New Warbank - Hopefully WoW API extension will catch up soon
ACCOUNT_BANK_PANEL_TITLE = "" -- 11.0.0 New Warbank - Hopefully WoW API extension will catch up soon

--====== WoW frames
PetActionBarFrame = {}
StanceBarFrame = {}
PossessBarFrame = {}
MinimapBorderTop = {}
MinimapZoneTextButton = {}
MiniMapWorldMapButton = {}
VideoOptionsFrame = {}

---@class FrameSizeBorder

--====== WoW tables or routines
UIPARENT_MANAGED_FRAME_POSITIONS = {}
FCF_UpdateDockPosition = {}
TargetFrame_Update = {}
VideoOptionsFrameOkay_OnClick = {}

C_Bank = {} -- 11.0.0 New Warbank - Hopefully WoW API extension will catch up soon


--====== Convince IDE we know what we are doing
-- Lua allows table updates but the IDE complains about 'injecting' a field it does not know about.
-- Adding a function or variable to a frame in this case.

---@class Frame frame for a Titan template
---@field showTimer number time to close in seconds
---@field isCounting number | nil 1 or nil
---@field parent table | nil Anchor tooltip

---@class Button Plugin frame from a Titan template
---@field TitanLDBSetOwnerPosition function Anchor tooltip
---@field TitanLDBSetTooltip function Fill tooltip
---@field TitanLDBHandleScripts function Set frame scripts
---@field TitanLDBTextUpdate function Update plugin text
---@field TitanLDBIconUpdate function Update plugin icon
---@field TitanLDBCreateObject function Create plugin
---@field TitanCreatedBy string Only LDB ATM
---@field TitanType string Not used ATM
---@field TitanName string Used for LDB name / id
---@field TitanAction string Not used ATM
---@field bar_name string Used by auto hide built-in
---@field registry table Any Titan plugin (built-in; third party; or LDB)
---@field tooltipText string Titan text for the tool tip

---@class UIParent WoW frame
---@field GetScale function WoW region routine

---@class Button Plugin frame
---@field RequestTimePlayed table Override default - XP
---@field TIME_PLAYED_MSG table Override default - XP
---@field short_name string Placeholder for short bar name

-- Ace references
AceGUIWidgetLSMlists = {}

--====== Ace Drop down menu
L_UIDROPDOWNMENU_MENU_LEVEL = 1
L_UIDROPDOWNMENU_MENU_VALUE = 1

--====== WoW Drop down menu
UIDROPDOWNMENU_MENU_VALUE = 1

---@class LibUIDropDownMenu
---@field UIDropDownMenu_InitializeHelper function
---@field Create_UIDropDownMenu function
---@field UIDropDownMenu_Initialize function
---@field UIDropDownMenu_SetInitializeFunction function
---@field UIDropDownMenu_SetDisplayMode function
---@field UIDropDownMenu_RefreshDropDownSize function
---@field UIDropDownMenu_StartCounting function
---@field UIDropDownMenu_StopCounting function
---@field UIDropDownMenu_CreateInfo function
---@field UIDropDownMenu_CreateFrames function
---@field UIDropDownMenu_AddSeparator function
---@field UIDropDownMenu_AddSpace function
---@field UIDropDownMenu_AddButton function
---@field UIDropDownMenu_CheckAddCustomFrame function
---@field UIDropDownMenu_RegisterCustomFrame function
---@field UIDropDownMenu_GetMaxButtonWidth function
---@field UIDropDownMenu_GetButtonWidth function
---@field UIDropDownMenu_Refresh function
---@field UIDropDownMenu_RefreshAll function
---@field UIDropDownMenu_SetIconImage function
---@field UIDropDownMenu_SetSelectedName function
---@field UIDropDownMenu_SetSelectedValue function
---@field UIDropDownMenu_GetSelectedName function
---@field UIDropDownMenu_GetSelectedID function
---@field UIDropDownMenu_SetSelectedID function
---@field UIDropDownMenu_GetSelectedValue function
---@field HideDropDownMenu function
---@field ToggleDropDownMenu function
---@field CloseDropDownMenus function
---@field UIDropDownMenu_SetWidth function
---@field UIDropDownMenu_SetButtonWidth function
---@field UIDropDownMenu_SetText function
---@field UIDropDownMenu_GetText function
---@field UIDropDownMenu_ClearAll function
---@field UIDropDownMenu_JustifyText function
---@field UIDropDownMenu_SetAnchor function
---@field UIDropDownMenu_GetCurrentDropDown function
---@field UIDropDownMenuButton_GetChecked function
---@field UIDropDownMenuButton_GetName function
---@field UIDropDownMenuButton_OpenColorPicker function
---@field UIDropDownMenu_DisableButton function
---@field UIDropDownMenu_EnableButton function
---@field UIDropDownMenu_SetButtonText function
---@field UIDropDownMenu_SetButtonNotClickable function
---@field UIDropDownMenu_SetButtonClickable function
---@field UIDropDownMenu_DisableDropDown function
---@field UIDropDownMenu_EnableDropDown function
---@field UIDropDownMenu_IsEnabled function
---@field UIDropDownMenu_GetValue function
---@field OpenColorPicker function
---@field ColorPicker_GetPreviousValues function


--====== API routines
