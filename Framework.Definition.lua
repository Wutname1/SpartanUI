---@class FrameExpanded : Frame, BackdropTemplate, Button
---@field text ElementTextData
local a = {}

---@class SUI.Module : AceAddon, AceEvent-3.0, AceTimer-3.0, AceModule
---@field description string
---@field DisplayName string
---@field Override? boolean
---@field Core? boolean
local SUI_Module = {}

---@diagnostic disable: duplicate-doc-field
---@class FrameExpanded : Frame, BackdropTemplate, Button
local b = {}

---@class AceConfig.OptionsTable
---@field args? table
local c = {}

local function ContentOnClick(this, button)
end

--- Set the value to an item in the List.
--- @param value any
local function SetValue(self, value)
end

--- Set the list of values for the dropdown (key => value pairs)
--- @param list table
local function SetList(self, list)
end

--- Set the text displayed in the box.
---@param text string
local function SetText(self, text)
end

--- Set the text for the label.
---@param text string
local function SetLabel(self, text)
end

--- Add an item to the list.
---@param key any
---@param value any
local function AddItem(key, value)
end
local SetItemValue = AddItem -- Set the value of a item in the list. <<same as adding a new item>>

local function SetMultiselect(self, flag)
end -- Toggle multi-selecting. <<Dummy function to stay inline with the dropdown API>>

local function SetItemDisabled(self, key)
end -- Disable one item in the list. <<Dummy function to stay inline with the dropdown API>>

---@param disabled boolean
local function SetDisabled(self, disabled)
end

local function ToggleDrop(self)
end

local function ClearFocus(self)
end

---return string
local function GetValue(self)
end

---@return AceGUIWidgetLSM30_Font
local function Constructor()
	---@class AceGUIWidgetLSM30_Font : AceGUIWidget
	---@field dropButton Button
	local frame = {}
	---@class AceGUIWidgetLSM30_Font : AceGUIWidget
	---@field GetMultiselect function
	---@field GetValue function
	---@field OnAcquire function
	---@field OnRelease function
	local self = {}

	self.type = 'LSM30_Font'
	self.frame = frame
	frame.obj = self
	frame.dropButton.obj = self

	self.alignoffset = 31

	self.ClearFocus = ClearFocus
	self.SetText = SetText
	self.SetValue = SetValue
	self.GetValue = GetValue
	self.SetList = SetList
	self.SetLabel = SetLabel
	self.SetDisabled = SetDisabled
	self.AddItem = AddItem
	self.SetMultiselect = SetMultiselect
	self.SetItemValue = SetItemValue
	self.SetItemDisabled = SetItemDisabled
	self.ToggleDrop = ToggleDrop

	return self
end
