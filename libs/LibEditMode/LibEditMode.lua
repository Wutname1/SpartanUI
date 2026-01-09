local MINOR = 12
local lib = LibStub:NewLibrary('LibEditMode', MINOR)
if not lib then
	-- this or a newer version is already loaded
	return
end

lib.internal = {} -- internal methods, do not use directly
local internal = lib.internal

lib.frameSelections = lib.frameSelections or {}
lib.frameCallbacks = lib.frameCallbacks or {}
lib.frameDefaults = lib.frameDefaults or {}
lib.frameSettings = lib.frameSettings or {}
lib.frameButtons = lib.frameButtons or {}

lib.anonCallbacksEnter = lib.anonCallbacksEnter or {}
lib.anonCallbacksExit = lib.anonCallbacksExit or {}
lib.anonCallbacksLayout = lib.anonCallbacksLayout or {}
lib.anonCallbacksCreate = lib.anonCallbacksCreate or {}
lib.anonCallbacksRename = lib.anonCallbacksRename or {}
lib.anonCallbacksDelete = lib.anonCallbacksDelete or {}

lib.systemSettings = lib.systemSettings or {}
lib.systemButtons = lib.systemButtons or {}

lib.layoutCache = lib.layoutCache or {}

local layoutNames = setmetatable({'Modern', 'Classic'}, {
	__index = function(t, key)
		if key > 2 then
			-- the first 2 indices are reserved for 'Modern' and 'Classic' layouts, and anything
			-- else are custom ones, although GetLayouts() doesn't return data for the 'Modern'
			-- and 'Classic' layouts, so we'll have to substract and check
			local layouts = lib.layoutCache
			if (key - 2) <= #layouts then
				return layouts[key - 2].layoutName
			end
		else
			-- also work for 'Modern' and 'Classic'
			rawget(t, key)
		end
	end
})

local function resetDialogs()
	if internal.dialog then
		internal.dialog:Hide()
	end

	if internal.extension then
		internal.extension:Hide()
	end
end

local function resetSelection()
	for frame, selection in next, lib.frameSelections do
		if selection.isSelected then
			frame:SetMovable(false)
		end

		if not lib.isEditing then
			selection:Hide()
			selection.isSelected = false
		else
			selection:ShowHighlighted()
		end
	end
end

local function onDragStart(self)
	if InCombatLockdown() then
		-- TODO: maybe add a warning?
		return
	end

	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self.parent:StartMoving()
end

local function normalizePosition(frame)
	-- ripped out of LibWindow-1.1, which is Public Domain
	local parent = frame:GetParent()
	if not parent then
		return
	end

	local scale = frame:GetScale()
	if not scale then
		return
	end

	local left = frame:GetLeft() * scale
	local top = frame:GetTop() * scale
	local right = frame:GetRight() * scale
	local bottom = frame:GetBottom() * scale

	local parentWidth, parentHeight = parent:GetSize()

	local x, y, point
	if left < (parentWidth - right) and left < math.abs((left + right) / 2 - parentWidth / 2) then
		x = left
		point = 'LEFT'
	elseif (parentWidth - right) < math.abs((left + right) / 2 - parentWidth / 2) then
		x = right - parentWidth
		point = 'RIGHT'
	else
		x = (left + right) / 2 - parentWidth / 2
		point = ''
	end

	if bottom < (parentHeight - top) and bottom < math.abs((bottom + top) / 2 - parentHeight / 2) then
		y = bottom
		point = 'BOTTOM' .. point
	elseif (parentHeight - top) < math.abs((bottom + top) / 2 - parentHeight / 2) then
		y = top - parentHeight
		point = 'TOP' .. point
	else
		y = (bottom + top) / 2 - parentHeight / 2
		point = '' .. point
	end

	if point == '' then
		point = 'CENTER'
	end

	return point, x / scale, y / scale
end

local function updatePosition(selection, xDelta, yDelta)
	if InCombatLockdown() then
		-- TODO: maybe add a warning?
		return
	end

	local parent = selection.parent
	local point, x, y = normalizePosition(parent)
	x, y = x + (xDelta or 0), y + (yDelta or 0)
	parent:ClearAllPoints()
	parent:SetPoint(point, x, y)

	internal:TriggerCallback(parent, point, x, y)

	if selection.isSelected then
		internal.dialog:Update(selection)
	end
end

local function onDragStop(self)
	if InCombatLockdown() then
		return
	end

	local parent = self.parent
	parent:StopMovingOrSizing()
	self:UnregisterEvent('PLAYER_REGEN_DISABLED')

	-- TODO: snap position to grid
	-- FrameXML/EditModeUtil.lua

	updatePosition(self)
end

local function onMouseDown(self) -- replacement for EditModeSystemMixin:SelectSystem()
	if InCombatLockdown() then
		-- TODO: maybe add a warning?
		return
	end

	resetDialogs()
	resetSelection()
	EditModeManagerFrame:ClearSelectedSystem() -- possible taint

	if not self.isSelected then
		self.parent:SetMovable(true)
		self:ShowSelected(true)

		if internal.dialog.selection ~= self then
			internal.dialog:Reset()
		end

		internal.dialog:Update(self)
	end
end

local function onEditModeEnter()
	lib.isEditing = true

	resetDialogs()
	resetSelection()

	for _, callback in next, lib.anonCallbacksEnter do
		securecallfunction(callback)
	end
end

local function onEditModeExit()
	lib.isEditing = false

	resetDialogs()
	resetSelection()

	for _, callback in next, lib.anonCallbacksExit do
		securecallfunction(callback)
	end
end

local function onEditModeChanged(_, layoutInfo)
	local activeLayout = layoutInfo.activeLayout
	if activeLayout ~= lib.activeLayout then
		lib.activeLayout = activeLayout

		-- update cache
		lib.layoutCache = C_EditMode.GetLayouts().layouts

		-- trigger callbacks
		for _, callback in next, lib.anonCallbacksLayout do
			securecallfunction(callback, layoutNames[activeLayout], activeLayout)
		end

		-- update dialog
		if internal.dialog and internal.dialog.selection then
			internal.dialog:Update(internal.dialog.selection)
		end

		-- TODO: we should update the position of the button here, let the user not deal with that
	end
end

local function onSpecChanged(_, unit)
	if unit ~= 'player' then
		return
	end

	onEditModeChanged(nil, C_EditMode.GetLayouts())
end

local function onEditModeLayoutChanged()
	local layouts = C_EditMode.GetLayouts().layouts

	for index = #layouts, 1, -1 do
		if lib.layoutCache[index] then
			local layout = layouts[index]
			if lib.layoutCache[index].layoutName ~= layout.layoutName then
				for _, callback in next, lib.anonCallbacksRename do
					securecallfunction(callback, lib.layoutCache[index].layoutName, layout.layoutName, index)
				end
			end

			table.remove(lib.layoutCache, index)
		else
			for _, callback in next, lib.anonCallbacksCreate do
				securecallfunction(callback, layouts[index].layoutName, index)
			end
		end
	end

	for _, layout in next, lib.layoutCache do
		for _, callback in next, lib.anonCallbacksDelete do
			securecallfunction(callback, layout.layoutName)
		end
	end

	lib.layoutCache = layouts
end

local isManagerHooked = false

local function hookManager()
	-- listen for layout changes
	EventRegistry:RegisterFrameEventAndCallback('EDIT_MODE_LAYOUTS_UPDATED', onEditModeChanged)
	EventRegistry:RegisterFrameEventAndCallback('PLAYER_SPECIALIZATION_CHANGED', onSpecChanged)
	EventRegistry:RegisterCallback('EditMode.SavedLayouts', onEditModeLayoutChanged)

	-- hook EditMode shown state, since QuickKeybindMode will hide/show EditMode
	EditModeManagerFrame:HookScript('OnShow', onEditModeEnter)
	EditModeManagerFrame:HookScript('OnHide', onEditModeExit)

	-- we don't want any custom frames dangling around
	EditModeSystemSettingsDialog:HookScript('OnHide', resetDialogs)

	-- unselect our selections whenever a system is selected and try to add an extension
	hooksecurefunc(EditModeManagerFrame, 'SelectSystem', function(_, systemFrame)
		resetDialogs()
		resetSelection()

		internal.dialog:Reset()

		local systemID = systemFrame.system
		if lib.systemSettings[systemID] or lib.systemButtons[systemID] then
			internal.extension:Update(systemID)
		end
	end)

	-- fetch layout info in case EDIT_MODE_LAYOUTS_UPDATED already fired
	if lib.layoutCache then
		onEditModeChanged(nil, C_EditMode.GetLayouts()) -- introduces a little latency
	end

	isManagerHooked = true
end

--[[ LibEditMode:AddFrame(_frame, callback, default_) ![](https://img.shields.io/badge/function-blue)
Register a frame to be controlled by the Edit Mode.

* `frame`: frame widget to be controlled
* `callback`: callback that triggers whenever the frame has been repositioned
* `default`: table containing the default position of the frame
* `name`: name of the system, if nil, the frame's name will be used

The `default` table must contain the following entries:

* `point`: relative anchor point, e.g. `"CENTER"` _(string)_
* `x`: horizontal offset from the anchor point _(number)_
* `y`: vertical offset from the anchor point _(number)_
--]]
function lib:AddFrame(frame, callback, default, name)
	local selection = CreateFrame('Frame', nil, frame, 'EditModeSystemSelectionTemplate')
	selection:SetAllPoints()
	selection:SetScript('OnMouseDown', onMouseDown)
	selection:SetScript('OnDragStart', onDragStart)
	selection:SetScript('OnDragStop', onDragStop)
	selection:SetScript('OnEvent', onDragStop)
	selection:Hide()

	-- as of 11.2 the template requires a system name to work correctly
	selection.system = {
		GetSystemName = function()
			return name or frame.editModeName or frame:GetName()
		end
	}

	lib.frameSelections[frame] = selection
	lib.frameCallbacks[frame] = callback
	lib.frameDefaults[frame] = default

	if not internal.dialog then
		internal.dialog = internal:CreateDialog()
		internal.dialog:HookScript('OnHide', function()
			resetSelection()
		end)

		if not isManagerHooked then
			hookManager()
		end
	end
end

--[[ LibEditMode:AddFrameSettings(_frame, settings_) ![](https://img.shields.io/badge/function-blue)
Register extra settings that will be displayed in a dialog attached to the frame in the Edit Mode.

* `frame`: frame widget already registered with [AddFrame](#libeditmodeaddframeframe-callback-default-)
* `settings`: table containing [SettingObject](Types#settingobject) entries _(table, number indexed)_
--]]
function lib:AddFrameSettings(frame, settings)
	if not lib.frameSelections[frame] then
		error('frame must be registered')
	end

	lib.frameSettings[frame] = settings
end

--[[ LibEditMode:EnableFrameSetting(_frame, settingName_) ![](https://img.shields.io/badge/function-blue)
Enables a setting on a frame.

* `frame`: frame widget already registered with [AddFrame](#libeditmodeaddframeframe-callback-default-)
* `settingName`: a setting already registered with [AddFrameSettings](#libeditmodeaddframesettingsframe-settings-)
--]]
function lib:EnableFrameSetting(frame, settingName)
	local settings = internal:GetFrameSettings(frame)
	if settings then
		for _, setting in next, settings do
			if setting.name == settingName then
				setting.disabled = false
				internal.dialog:Update(internal.dialog.selection)
				break
			end
		end
	end
end

--[[ LibEditMode:DisableFrameSetting(_frame, settingName_) ![](https://img.shields.io/badge/function-blue)
Disables a setting on a frame.

* `frame`: frame widget already registered with [AddFrame](#libeditmodeaddframeframe-callback-default-)
* `settingName`: a setting already registered with [AddFrameSettings](#libeditmodeaddframesettingsframe-settings-)
--]]
function lib:DisableFrameSetting(frame, settingName)
	local settings = internal:GetFrameSettings(frame)
	if settings then
		for _, setting in next, settings do
			if setting.name == settingName then
				setting.disabled = true
				internal.dialog:Update(internal.dialog.selection)
				break
			end
		end
	end
end

--[[ LibEditMode:AddFrameSettingsButton(_frame, data_) ![](https://img.shields.io/badge/function-blue)

> :warning: Deprecated. Please use [`LibEditMode:AddFrameSettingsButtons(frame, buttons)`](#libeditmodeaddframesettingsbuttonsframe-buttons-) instead.

Register extra button that will be displayed in a dialog attached to the frame in the Edit Mode.

* `frame`: frame widget already registered with [AddFrame](#libeditmodeaddframeframe-callback-default-)
* `data`: [ButtonObject](Types#buttonobject) _(table)_
--]]
function lib:AddFrameSettingsButton(frame, data)
	if not lib.frameButtons[frame] then
		lib.frameButtons[frame] = {}
	end

	table.insert(lib.frameButtons[frame], data)
end

--[[ LibEditMode:AddFrameSettingsButtons(_frame, buttons_) ![](https://img.shields.io/badge/function-blue)
Register extra buttons that will be displayed in a dialog attached to the frame in the Edit Mode.

* `frame`: frame widget already registered with [AddFrame](#libeditmodeaddframeframe-callback-default-)
* `buttons`: table containing [ButtonObject](Types#buttonobject) entries _(table, number indexed)_
--]]
function lib:AddFrameSettingsButtons(frame, buttons)
	if not lib.frameButtons[frame] then
		lib.frameButtons[frame] = {}
	end

	for _, button in next, buttons do
		table.insert(lib.frameButtons[frame], button)
	end
end

--[[ LibEditMode:RefreshFrameSettings(_frame_) ![](https://img.shields.io/badge/function-blue)
Refresh the dialog attached to the frame.
--]]
function lib:RefreshFrameSettings(frame)
	local selection = lib.frameSelections[frame]
	if selection and internal.dialog and internal.dialog.selection == selection and internal.dialog:IsVisible() then
		internal.dialog:Update(selection)
	end
end

--[[ LibEditMode:AddSystemSettings(_systemID, settings_) ![](https://img.shields.io/badge/function-blue)
Register extra settings for a Blizzard system, it will be displayed in an dialog attached to the system's dialog in the Edit Mode.

* `systemID`: the ID of a system registered with the Edit Mode. See `Enum.EditModeSystem`.
* `settings`: table containing [SettingObject](Types#settingobject) entries _(table, number indexed)_
--]]
function lib:AddSystemSettings(systemID, settings)
	if not lib.systemSettings[systemID] then
		lib.systemSettings[systemID] = {}
	end

	-- while not ideal allow multiple addons to add their settings
	for _, setting in next, settings do
		table.insert(lib.systemSettings[systemID], setting)
	end

	if not internal.extension then
		internal.extension = internal:CreateExtension()
	end

	if not isManagerHooked then
		hookManager()
	end
end

--[[ LibEditMode:EnableSystemSetting(_systemID, settingName_) ![](https://img.shields.io/badge/function-blue)
Enables a setting on a frame.

* `systemID`: the ID of a system registered with the Edit Mode. See `Enum.EditModeSystem`.
* `settingName`: a setting already registered with [AddSystemSettings](#libeditmodeaddsystemsettingssystemid-settings-)
--]]
function lib:EnableSystemSetting(systemID, settingName)
	local settings = internal:GetSystemSettings(systemID)
	if settings then
		for _, setting in next, settings do
			if setting.name == settingName then
				setting.disabled = false
				internal.extension:Update(internal.extension.systemID)
				break
			end
		end
	end
end

--[[ LibEditMode:DisableSystemSetting(_systemID, settingName_) ![](https://img.shields.io/badge/function-blue)
Disables a setting on a frame.

* `systemID`: the ID of a system registered with the Edit Mode. See `Enum.EditModeSystem`.
* `settingName`: a setting already registered with [AddSystemSettings](#libeditmodeaddsystemsettingssystemid-settings-)
--]]
function lib:DisableSystemSetting(systemID, settingName)
	local settings = internal:GetSystemSettings(systemID)
	if settings then
		for _, setting in next, settings do
			if setting.name == settingName then
				setting.disabled = true
				internal.extension:Update(internal.extension.systemID)
				break
			end
		end
	end
end

--[[ LibEditMode:AddSystemSettingsButtons(_systemID, buttons_) ![](https://img.shields.io/badge/function-blue)
Register extra buttons for a Blizzard system, it will be displayed in a dialog attached to the system's dialog in the Edit Mode.

* `systemID`: the ID of a system registered with the Edit Mode. See `Enum.EditModeSystem`.
* `buttons`: table containing [ButtonObject](Types#buttonobject) entries _(table, number indexed)_
--]]
function lib:AddSystemSettingsButtons(systemID, buttons)
	if not lib.systemButtons[systemID] then
		lib.systemButtons[systemID] = {}
	end

	for _, button in next, buttons do
		table.insert(lib.systemButtons[systemID], button)
	end

	if not internal.extension then
		internal.extension = internal:CreateExtension()
	end

	if not isManagerHooked then
		hookManager()
	end
end

--[[ LibEditMode:RegisterCallback(_event, callback_) ![](https://img.shields.io/badge/function-blue)
Register extra callbacks whenever an event within the Edit Mode triggers.

* `event`: event name _(string)_
* `callback`: function that will be triggered with the event _(function)_

Possible events:

* `enter`: triggered when the Edit Mode is entered
* `exit`: triggered when the Edit Mode is exited
* `layout`: triggered when the Edit Mode layout is changed (which also occurs at login)
    * signature:
        * `layoutName`: name of the layout
        * `layoutIndex`: index of the layout
* `create`: triggered when a Edit Mode layout has been created
    * signature:
        * `layoutName`: name of the new layout
        * `layoutIndex`: index of the layout
* `rename`: triggered when a Edit Mode layout has been renamed
    * signature:
        * `oldLayoutName`: name of the layout that got renamed
        * `newLayoutName`: new name of the layout
        * `layoutIndex`: index of the layout
* `delete`: triggered when a Edit Mode layout has been deleted
    * signature:
        *`layoutName`: name of the layout that got deleted
--]]
function lib:RegisterCallback(event, callback)
	assert(event and type(event) == 'string', 'event must be a string')
	assert(callback and type(callback) == 'function', 'callback must be a function')

	if event == 'enter' then
		table.insert(lib.anonCallbacksEnter, callback)
	elseif event == 'exit' then
		table.insert(lib.anonCallbacksExit, callback)
	elseif event == 'layout' then
		table.insert(lib.anonCallbacksLayout, callback)

		-- if there's none, then onEditModeChanged will take care of it
		if lib.activeLayout then
			securecallfunction(callback, layoutNames[lib.activeLayout], lib.activeLayout)
		end
	elseif event == 'create' then
		table.insert(lib.anonCallbacksCreate, callback)
	elseif event == 'rename' then
		table.insert(lib.anonCallbacksRename, callback)
	elseif event == 'delete' then
		table.insert(lib.anonCallbacksDelete, callback)
	else
		error('invalid callback event "' .. event .. '"')
	end
end

--[[ LibEditMode:GetActiveLayout() ![](https://img.shields.io/badge/function-blue)
Returns the active Edit Mode layout.

This will not return valid data until after the layout has been loaded from the server.  
Data will be available for the ["layout" callback](#libeditmoderegistercallbackevent-callback).
--]]
function lib:GetActiveLayout()
	return lib.activeLayout
end

--[[ LibEditMode:GetActiveLayoutName() ![](https://img.shields.io/badge/function-blue)
Returns the active Edit Mode layout name.

This will not return valid data until after the layout has been loaded from the server.  
Data will be available for the ["layout" callback](#libeditmoderegistercallbackevent-callback).
--]]
function lib:GetActiveLayoutName()
	return lib.activeLayout and layoutNames[lib.activeLayout]
end

--[[ LibEditMode:IsInEditMode() ![](https://img.shields.io/badge/function-blue)
Returns whether the Edit Mode is currently active.
--]]
function lib:IsInEditMode()
	return not not lib.isEditing
end

--[[ LibEditMode:GetFrameDefaultPosition(_frame_) ![](https://img.shields.io/badge/function-blue)
Returns the default position table registered with the frame.

* `frame`: registered frame to return positions for

Returns:

* `defaultPosition`: table registered with the frame in [AddFrame](#libeditmodeaddframeframe-callback-default-) _(table)_
--]]
function lib:GetFrameDefaultPosition(frame)
	return lib.frameDefaults[frame]
end

function internal:TriggerCallback(frame, ...)
	if lib.frameCallbacks[frame] then
		securecallfunction(lib.frameCallbacks[frame], frame, layoutNames[lib.activeLayout], ...)
	end
end

function internal:GetFrameSettings(frame)
	if lib.frameSettings[frame] then
		return lib.frameSettings[frame], #lib.frameSettings[frame]
	else
		return nil, 0
	end
end

function internal:GetFrameButtons(frame)
	if lib.frameButtons[frame] then
		return lib.frameButtons[frame], #lib.frameButtons[frame]
	else
		return nil, 0
	end
end

function internal:MoveParent(selection, x, y)
	updatePosition(selection, x, y)
end

function internal:GetSystemSettings(systemID)
	if lib.systemSettings[systemID] then
		return lib.systemSettings[systemID], #lib.systemSettings[systemID]
	else
		return nil, 0
	end
end

function internal:GetSystemSettingsButtons(systemID)
	if lib.systemButtons[systemID] then
		return lib.systemButtons[systemID], #lib.systemButtons[systemID]
	else
		return nil, 0
	end
end

--[[ Types:header

## SettingObject ![](https://img.shields.io/badge/object-teal)

Table containing the following entries:

| key      | value                                  | type                        | required |
|:---------|:---------------------------------------|:----------------------------|:---------|
| kind     | setting type                           | [SettingType](#settingtype) | yes      |
| name     | label for the setting                  | string                      | yes      |
| desc     | description for the setting            | string                      | no       |
| default  | default value for the setting          | any                         | yes      |
| get      | getter for the current value           | function                    | yes      |
| set      | setter for the new value               | function                    | yes      |
| disabled | whether the setting should be disabled | boolean                     | no       |

- The getter passes `layoutName` as the sole argument and expects a value in return.
- The setter passes (`layoutName`, `newValue`, `fromReset`) and expects no returns.
- The description is shown in a tooltip.

Depending on the setting type there are additional required and optional entries:

### Dropdown ![](https://img.shields.io/badge/object-teal)

| key       | value                                                                                                                 | type     | required |
|:----------|:----------------------------------------------------------------------------------------------------------------------|:---------|:---------|
| values    | indexed table containing [DropdownOption](#dropdownoption)s                                                           | table    | no       |
| multiple  | whether the dropdown should allow selecing multiple options                                                           | boolean  | no       |
| generator | [Dropdown `SetupMenu` "generator" (callback)](https://warcraft.wiki.gg/wiki/Patch_11.0.0/API_changes#New_menu_system) | function | no       |
| height    | max height of the menu                                                                                                | integer  | no       |

- Either `values` or `generator` is required, the former for simple menues and the latter for complex ones.
    - They are not exclusive, but `generator` takes precedence (e.g. `values` will be available but not used).
- `generator` signature is `(dropdown, rootDescription, settingObject)` - `settingObject` being the addition to the default arguments.
	- getters and setters are not handled using `generator`, and must be handled by the layout

## DropdownOption ![](https://img.shields.io/badge/object-teal)

Table containing the following entries:

| key     | value                                                              | type    | required |
|:--------|:-------------------------------------------------------------------|---------|:---------|
| text    | text rendered in the dropdown                                      | string  | yes      |
| value   | value the text represents, defaults to the text if not provided    | any     | no       |

### Slider ![](https://img.shields.io/badge/object-teal)

| key       | value                             | type     | required | default |
|:----------|:----------------------------------|:---------|:---------|:--------|
| minValue  | lower bound for the slider        | number   | no       | 0       |
| maxValue  | upper bound for the slider        | number   | no       | 1       |
| valueStep | step increment between each value | number   | no       | 1       |
| formatter | formatter for the display value   | function | no       |         |

- The formatter passes `value` as the sole argument and expects a number value in return.

### ColorPicker ![](https://img.shields.io/badge/object-teal)

| key        | value                            | type    | required | default |
|:-----------|:---------------------------------|:--------|:---------|:--------|
| hasOpacity | whether or not to enable opacity | boolean | no       | false   |

The `default` field and the getter expects a [ColorMixin](https://warcraft.wiki.gg/wiki/ColorMixin) object, and the setter will pass one as its value.  
Even if `hasOpacity` is set to `false` (which is the default value) the ColorMixin object will contain an alpha value, this is the default behavior of the ColorMixin.

## ButtonObject ![](https://img.shields.io/badge/object-teal)

Table containing the following entries:

| key   | value                           | type     | required |
|:------|:--------------------------------|----------|:---------|
| text  | text rendered on the button     | string   | yes      |
| click | callback when button is clicked | function | yes      |

## SettingType ![](https://img.shields.io/badge/object-teal)
Table containing available setting types.

One of:
- `Dropdown`
- `Checkbox`
- `Slider`
- `Divider`
- `ColorPicker`
--]]
lib.SettingType = CopyTable(Enum.EditModeSettingDisplayType)
lib.SettingType.ColorPicker = 10 -- leave some room for blizzard expansion
