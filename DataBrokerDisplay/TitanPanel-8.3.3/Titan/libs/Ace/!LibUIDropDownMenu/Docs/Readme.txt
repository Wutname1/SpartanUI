$Id: Readme.txt 64 2020-11-18 13:13:15Z arithmandar $

== About ==
Standard UIDropDownMenu global functions using protected frames and causing taints 
when used by third-party addons. But it is possible to avoid taints by using same 
functionality with that library.

== What is it ==
Library is standard code from Blizzard's files EasyMenu.lua, UIDropDownMenu.lua, 
UIDropDownMenu.xml and UIDropDownMenuTemplates.xml with frames, tables, variables 
and functions renamed to:
* constants : "L_" added at the start
* functions: "L_" added at the start

== How to use it (for addon developer) ==
=== Initial Preparation ===
Assuming your addon is using all the UIDropDownMenu functions from the WoW's 
built in function calls, then it is suggested that you have below preparation 
in your lua codes:
    local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

=== Function Call Replacement ===
Depends on which UIDropDownMenu's function calls you have used in your addon, 
you will need below similar replacement:

    UIDropDownMenu_Initialize => LibDD:UIDropDownMenu_Initialize
    UIDropDownMenu_CreateInfo => LibDD:UIDropDownMenu_CreateInfo
    UIDropDownMenu_AddButton => LibDD:UIDropDownMenu_AddButton

    UIDropDownMenu_AddSeparator => LibDD:UIDropDownMenu_AddSeparator
    UIDropDownMenu_AddSpace=> LibDD:UIDropDownMenu_AddSpace

    UIDropDownMenu_SetSelectedValue => LibDD:UIDropDownMenu_SetSelectedValue
    UIDropDownMenu_SetSelectedName=> LibDD:UIDropDownMenu_SetSelectedName

    UIDropDownMenu_SetSelectedID => LibDD:UIDropDownMenu_SetSelectedID
    UIDropDownMenu_SetWidth => LibDD:UIDropDownMenu_SetWidth

    CloseDropDownMenus => LibDD:CloseDropDownMenus

=== Creating new UIDropDownMenu ===
Traditionally you will either create a new frame in your lua codes or with 
XML by setting the frame to inherit from "UIDropDownMenuTemplate".

By using this library, you will need to create your menu from like below:
    local frame = LibDD:Create_UIDropDownMenu("MyDropDownMenu", parent_frame)

== Button Name ==
As you (the developers) might be aware that at some point you might need to 
manipulate the dropdowns by accessing the button names. For example, you have 
multiple levels of menus and you would like to hide or show some level's menu 
button. In that case, you need to make sure you also revise the button name 
used in your original codes when you are migrating to use LibUIDropDownMenu.

    "L_DropDownList"..i

Example:

	for i = 1, L_UIDROPDOWNMENU_MAXLEVELS, 1 do
		dropDownList = _G["L_DropDownList"..i];
		if ( i >= L_UIDROPDOWNMENU_MENU_LEVEL or frame ~= L_UIDROPDOWNMENU_OPEN_MENU ) then
			dropDownList.numButtons = 0;
			dropDownList.maxWidth = 0;
			for j=1, L_UIDROPDOWNMENU_MAXBUTTONS, 1 do
				button = _G["L_DropDownList"..i.."Button"..j];
				button:Hide();
			end
			dropDownList:Hide();
		end
	end

== Constants ==
* L_UIDROPDOWNMENU_MINBUTTONS
* L_UIDROPDOWNMENU_MAXBUTTONS
* L_UIDROPDOWNMENU_MAXLEVELS
* L_UIDROPDOWNMENU_BUTTON_HEIGHT
* L_UIDROPDOWNMENU_BORDER_HEIGHT
* L_UIDROPDOWNMENU_OPEN_MENU
* L_UIDROPDOWNMENU_INIT_MENU
* L_UIDROPDOWNMENU_MENU_LEVEL
* L_UIDROPDOWNMENU_MENU_VALUE
* L_UIDROPDOWNMENU_SHOW_TIME
* L_UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT
* L_OPEN_DROPDOWNMENUS

== Functions ==
* lib:EasyMenu
* lib:EasyMenu_Initialize

* lib:UIDropDownMenuDelegate_OnAttributeChanged
* lib:UIDropDownMenu_InitializeHelper
* lib:UIDropDownMenu_Initialize
* lib:UIDropDownMenu_SetInitializeFunction
* lib:UIDropDownMenu_RefreshDropDownSize
* lib:UIDropDownMenu_OnUpdate
* lib:UIDropDownMenu_StartCounting
* lib:UIDropDownMenu_StopCounting
* lib:UIDropDownMenu_CheckAddCustomFrame
* lib:UIDropDownMenu_CreateInfo
* lib:UIDropDownMenu_CreateFrames
* lib:UIDropDownMenu_AddSeparator
* lib:UIDropDownMenu_AddButton
* lib:UIDropDownMenu_AddSeparator
* lib:UIDropDownMenu_GetMaxButtonWidth
* lib:UIDropDownMenu_GetButtonWidth
* lib:UIDropDownMenu_Refresh
* lib:UIDropDownMenu_RefreshAll
* lib:UIDropDownMenu_RegisterCustomFrame
* lib:UIDropDownMenu_SetIconImage
* lib:UIDropDownMenu_SetSelectedName
* lib:UIDropDownMenu_SetSelectedValue
* lib:UIDropDownMenu_SetSelectedID
* lib:UIDropDownMenu_GetSelectedName
* lib:UIDropDownMenu_GetSelectedID
* lib:UIDropDownMenu_GetSelectedValue
* lib:UIDropDownMenuButton_OnClick
* lib:HideDropDownMenu
* lib:ToggleDropDownMenu
* lib:CloseDropDownMenus
* lib:UIDropDownMenu_OnHide
* lib:UIDropDownMenu_SetWidth
* lib:UIDropDownMenu_SetButtonWidth
* lib:UIDropDownMenu_SetText
* lib:UIDropDownMenu_GetText
* lib:UIDropDownMenu_ClearAll
* lib:UIDropDownMenu_JustifyText
* lib:UIDropDownMenu_SetAnchor
* lib:UIDropDownMenu_GetCurrentDropDown
* lib:UIDropDownMenuButton_GetChecked
* lib:UIDropDownMenuButton_GetName
* lib:UIDropDownMenuButton_OpenColorPicker
* lib:UIDropDownMenu_DisableButton
* lib:UIDropDownMenu_EnableButton
* lib:UIDropDownMenu_SetButtonText
* lib:UIDropDownMenu_SetButtonNotClickable
* lib:UIDropDownMenu_SetButtonClickable
* lib:UIDropDownMenu_DisableDropDown
* lib:UIDropDownMenu_EnableDropDown
* lib:UIDropDownMenu_IsEnabled
* lib:UIDropDownMenu_GetValue

== List of button attributes ==
* info.text = [STRING]  --  The text of the button
* info.value = [ANYTHING]  --  The value that L_UIDROPDOWNMENU_MENU_VALUE is set to when the button is clicked
* info.func = [function()]  --  The function that is called when you click the button
* info.checked = [nil, true, function]  --  Check the button if true or function returns true
* info.isNotRadio = [nil, true]  --  Check the button uses radial image if false check box image if true
* info.isTitle = [nil, true]  --  If it's a title the button is disabled and the font color is set to yellow
* info.disabled = [nil, true]  --  Disable the button and show an invisible button that still traps the mouseover event so menu doesn't time out
* info.tooltipWhileDisabled = [nil, 1] -- Show the tooltip, even when the button is disabled.
* info.hasArrow = [nil, true]  --  Show the expand arrow for multilevel menus
* info.hasColorSwatch = [nil, true]  --  Show color swatch or not, for color selection
* info.r = [1 - 255]  --  Red color value of the color swatch
* info.g = [1 - 255]  --  Green color value of the color swatch
* info.b = [1 - 255]  --  Blue color value of the color swatch
* info.colorCode = [STRING] -- "|cAARRGGBB" embedded hex value of the button text color. Only used when button is enabled
* info.swatchFunc = [function()]  --  Function called by the color picker on color change
* info.hasOpacity = [nil, 1]  --  Show the opacity slider on the colorpicker frame
* info.opacity = [0.0 - 1.0]  --  Percentatge of the opacity, 1.0 is fully shown, 0 is transparent
* info.opacityFunc = [function()]  --  Function called by the opacity slider when you change its value
* info.cancelFunc = [function(previousValues)] -- Function called by the colorpicker when you click the cancel button (it takes the previous values as its argument)
* info.notClickable = [nil, 1]  --  Disable the button and color the font white
* info.notCheckable = [nil, 1]  --  Shrink the size of the buttons and don't display a check box
* info.owner = [Frame]  --  Dropdown frame that "owns" the current dropdownlist
* info.keepShownOnClick = [nil, 1]  --  Don't hide the dropdownlist after a button is clicked
* info.tooltipTitle = [nil, STRING] -- Title of the tooltip shown on mouseover
* info.tooltipText = [nil, STRING] -- Text of the tooltip shown on mouseover
* info.tooltipOnButton = [nil, 1] -- Show the tooltip attached to the button instead of as a Newbie tooltip.
* info.justifyH = [nil, "CENTER"] -- Justify button text
* info.arg1 = [ANYTHING] -- This is the first argument used by info.func
* info.arg2 = [ANYTHING] -- This is the second argument used by info.func
* info.fontObject = [FONT] -- font object replacement for Normal and Highlight
* info.menuTable = [TABLE] -- This contains an array of info tables to be displayed as a child menu
* info.noClickSound = [nil, 1]  --  Set to 1 to suppress the sound when clicking the button. The sound only plays if .func is set.
* info.padding = [nil, NUMBER] -- Number of pixels to pad the text on the right side
* info.leftPadding = [nil, NUMBER] -- Number of pixels to pad the button on the left side
* info.minWidth = [nil, NUMBER] -- Minimum width for this line
* info.customFrame = frame -- Allows this button to be a completely custom frame, should inherit from L_UIDropDownCustomMenuEntryTemplate and override appropriate methods.