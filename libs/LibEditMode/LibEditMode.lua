local MINOR = 8
local lib = LibStub:NewLibrary('LibEditMode', MINOR)
if not lib then
	-- this or a newer version is already loaded
	return
end

lib.internal = {} -- internal methods, do not use directly
local internal = lib.internal

local layoutNames = setmetatable({'Modern', 'Classic'}, {
	__index = function(t, key)
		if key > 2 then
			-- the first 2 indices are reserved for 'Modern' and 'Classic' layouts, and anything
			-- else are custom ones, although GetLayouts() doesn't return data for the 'Modern'
			-- and 'Classic' layouts, so we'll have to substract and check
			local layouts = C_EditMode.GetLayouts().layouts
			if (key - 2) > #layouts then
				error('index is out of bounds')
			else
				return layouts[key - 2].layoutName
			end
		else
			-- also work for 'Modern' and 'Classic'
			rawget(t, key)
		end
	end
})

lib.frameSelections = lib.frameSelections or {}
lib.frameCallbacks = lib.frameCallbacks or {}
lib.frameDefaults = lib.frameDefaults or {}
lib.frameSettings = lib.frameSettings or {}
lib.frameButtons = lib.frameButtons or {}

lib.anonCallbacksEnter = lib.anonCallbacksEnter or {}
lib.anonCallbacksExit = lib.anonCallbacksExit or {}
lib.anonCallbacksLayout = lib.anonCallbacksLayout or {}

local function resetSelection()
	internal.dialog:Hide()

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

local function onDragStop(self)
	local parent = self.parent
	parent:StopMovingOrSizing()

	-- TODO: snap position to grid
	-- FrameXML/EditModeUtil.lua

	local point, x, y = normalizePosition(parent)
	parent:ClearAllPoints()
	parent:SetPoint(point, x, y)

	internal:TriggerCallback(parent, point, x, y)
end

local function onMouseDown(self) -- replacement for EditModeSystemMixin:SelectSystem()
	resetSelection()
	EditModeManagerFrame:ClearSelectedSystem() -- possible taint

	if not self.isSelected then
		self.parent:SetMovable(true)
		self:ShowSelected(true)
		internal.dialog:Update(self)
	end
end

local function onEditModeEnter()
	lib.isEditing = true

	resetSelection()

	for _, callback in next, lib.anonCallbacksEnter do
		securecallfunction(callback)
	end
end

local function onEditModeExit()
	lib.isEditing = false

	resetSelection()

	for _, callback in next, lib.anonCallbacksExit do
		securecallfunction(callback)
	end
end

local function onEditModeChanged(_, layoutInfo)
	local layoutName = layoutNames[layoutInfo.activeLayout]
	if layoutName ~= lib.activeLayoutName then
		lib.activeLayoutName = layoutName

		for _, callback in next, lib.anonCallbacksLayout do
			securecallfunction(callback, layoutName)
		end

		-- TODO: we should update the position of the button here, let the user not deal with that
	end
end

--[[ LibEditMode:AddFrame(_frame, callback, default_)
Register a frame to be controlled by the Edit Mode.

* `frame`: frame widget to be controlled
* `callback`: callback that triggers whenever the frame has been repositioned
* `default`: table containing the default position of the frame

The `default` table must contain the following entries:

* `point`: relative anchor point, e.g. `"CENTER"` _(string)_
* `x`: horizontal offset from the anchor point _(number)_
* `y`: vertical offset from the anchor point _(number)_
--]]
function lib:AddFrame(frame, callback, default)
	local selection = CreateFrame('Frame', nil, frame, 'EditModeSystemSelectionTemplate')
	selection:SetAllPoints()
	selection:SetScript('OnMouseDown', onMouseDown)
	selection:SetScript('OnDragStart', onDragStart)
	selection:SetScript('OnDragStop', onDragStop)
	selection.Label:SetText(frame.editModeName or frame:GetName())
	selection:Hide()

	lib.frameSelections[frame] = selection
	lib.frameCallbacks[frame] = callback
	lib.frameDefaults[frame] = default

	if not internal.dialog then
		internal.dialog = internal:CreateDialog()
		internal.dialog:HookScript('OnHide', function()
			resetSelection()
		end)

		-- listen for layout changes
		EventRegistry:RegisterFrameEventAndCallback('EDIT_MODE_LAYOUTS_UPDATED', onEditModeChanged)

		-- hook EditMode shown state, since QuickKeybindMode will hide/show EditMode
		EditModeManagerFrame:HookScript('OnShow', onEditModeEnter)
		EditModeManagerFrame:HookScript('OnHide', onEditModeExit)

		-- unselect our selections whenever a system is selected
		hooksecurefunc(EditModeManagerFrame, 'SelectSystem', function()
			resetSelection()
		end)
	end
end

--[[ LibEditMode:AddFrameSettings(_frame, settings_)
Register extra settings that will be displayed in a dialog attached to the frame in the Edit Mode.

* `frame`: frame widget already registered with [AddFrame](#libeditmodeaddframeframe-callback-default)
* `settings`: table containing [SettingObject](Types#settingobject) entries _(table, number indexed)_
--]]
function lib:AddFrameSettings(frame, settings)
	if not lib.frameSelections[frame] then
		error('frame must be registered')
	end

	lib.frameSettings[frame] = settings
end

--[[ LibEditMode:AddFrameSettingsButton(_frame, data_)
Register extra buttons that will be displayed in a dialog attached to the frame in the Edit Mode.

* `frame`: frame widget already registered with [AddFrame](#libeditmodeaddframeframe-callback-default)
* `data`: table containing [ButtonObject](Types#buttonobject) entries _(table, number indexed)_
--]]
function lib:AddFrameSettingsButton(frame, data)
	if not lib.frameButtons[frame] then
		lib.frameButtons[frame] = {}
	end

	table.insert(lib.frameButtons[frame], data)
end

--[[ LibEditMode:RegisterCallback(_event, callback_)
Register extra callbacks whenever an event within the Edit Mode triggers.

* `event`: event name _(string)_
* `callback`: function that will be triggered with the event _(function)_

Possible events:

* `enter`: triggered when the Edit Mode is entered
* `exit`: triggered when the Edit Mode is exited
* `layout`: triggered when the Edit Mode layout is changed (which also occurs at login)
    * signature:
        * `layoutName`: name of the new layout
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
	else
		error('invalid callback event "' .. event .. '"')
	end
end

--[[ LibEditMode:GetActiveLayoutName()
Returns the active Edit Mode layout name.

This will not return valid data until after the layout has been loaded from the server.  
Data will be available for the ["layout" callback](#libeditmoderegistercallbackevent-callback).
--]]
function lib:GetActiveLayoutName()
	return lib.activeLayoutName
end

--[[ LibEditMode:IsInEditMode()
Returns whether the Edit Mode is currently active.
--]]
function lib:IsInEditMode()
	return not not lib.isEditing
end

--[[ LibEditMode:GetFrameDefaultPosition(_frame_)
Returns the default position table registered with the frame.

* `frame`: registered frame to return positions for

Returns:

* `defaultPosition`: table registered with the frame in [AddFrame](#libeditmodeaddframeframe-callback-default) _(table)_
--]]
function lib:GetFrameDefaultPosition(frame)
	return lib.frameDefaults[frame]
end

function internal:TriggerCallback(frame, ...)
	if lib.frameCallbacks[frame] then
		securecallfunction(lib.frameCallbacks[frame], frame, lib.activeLayoutName, ...)
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

--[[ Types:header

## SettingObject

Table containing the following entries:

| key     | value                         | type                        | required |
|:--------|:------------------------------|:----------------------------|:---------|
| kind    | setting type                  | [SettingType](#settingtype) | yes      |
| name    | label for the setting         | string                      | yes      |
| default | default value for the setting | any                         | yes      |
| get     | getter for the current value  | function                    | yes      |
| set     | setter for the new value      | function                    | yes      |

- The getter passes `layoutName` as the sole argument and expects a value in return.  
- The setter passes (`layoutName`, `newValue`) and expects no returns.

Depending on the setting type there are additional required and optional entries:

### Dropdown

| key       | value                                                                                                                 | type     | required |
|:----------|:----------------------------------------------------------------------------------------------------------------------|:---------|:---------|
| values    | indexed table containing [DropdownOption](#dropdownoption)s                                                           | table    | no       |
| generator | [Dropdown `SetupMenu` "generator" (callback)](https://warcraft.wiki.gg/wiki/Patch_11.0.0/API_changes#New_menu_system) | function | no       |
| height    | max height of the menu                                                                                                | integer  | no       |

- Either `values` or `generator` is required, the former for simple menues and the latter for complex ones.
    - They are not exclusive, but `generator` takes precedence (e.g. `values` will be available but not used).
- `generator` signature is `(dropdown, rootDescription, settingObject)` - `settingObject` being the addition to the default arguments.
	- getters and setters are not handled using `generator`, and must be handled by the layout

### Slider

| key       | value                             | type     | required | default |
|:----------|:----------------------------------|:---------|:---------|:--------|
| minValue  | lower bound for the slider        | number   | no       | 0       |
| maxValue  | upper bound for the slider        | number   | no       | 1       |
| valueStep | step increment between each value | number   | no       | 1       |
| formatter | formatter for the display value   | function | no       |         |

- The formatter passes `value` as the sole argument and expects a number value in return.

## ButtonObject

Table containing the following entries:

| key   | value                           | type     | required |
|:------|:--------------------------------|----------|:---------|
| text  | text rendered on the button     | string   | yes      |
| click | callback when button is clicked | function | yes      |

## DropdownOption

Table containing the following entries:

| key     | value                                                              | type    | required |
|:--------|:-------------------------------------------------------------------|---------|:---------|
| text    | text rendered in the dropdown                                      | string  | yes      |
| isRadio | turns the dropdown entry into a Radio button, otherwise a Checkbox | boolean | no       |

## SettingType
Convenient shorthand for `Enum.EditModeSettingDisplayType`.

One of:
- `Dropdown`
- `Checkbox`
- `Slider`
--]]
lib.SettingType = CopyTable(Enum.EditModeSettingDisplayType)
