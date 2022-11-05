---@class FramePositioning
---@field point AnchorPoint
---@field relativePoint AnchorPoint
---@field xOfs integer
---@field yOfs integer
local FramePositioning = {}

---@class UFrameSettings
---@field anchor FramePositioning
---@field elements table<string, SUI.UnitFrame.Element.Settings>
---@field visibility UFrameVisibility
---@field config UFrameConfig
local UFrameSettings = {
	enabled = true,
	width = 180,
	scale = 1,
	moved = false
}

---@class UFrameConfig
local config = {
	IsGroup = false,
	isChild = false
}

---@class UFrameVisibility
local visibility = {
	alphaDelay = 1,
	hideDelay = 3,
	showAlways = false,
	showInCombat = true,
	showWithTarget = false,
	showInRaid = false,
	showInParty = false
}

---@alias UnitFrameName
---|"player"
---|"target"
---|"targettarget"
---|"boss"
---|"raid"
---|"party"
---|"arena"
---|"pet"

---@class SUI.UnitFrame : frame, SUIElements
---@field unitOnCreate UnitFrameName
---@field elementList table<integer, SUI.UnitFrame.Elements>
---@field UpdateAll function
---@field ElementUpdate function
---@field mover frame
---@field config UFrameSettings
---@field frames? table<integer, SUI.UnitFrame>
---@field header? frame
local SUIUnitFrame = {}
