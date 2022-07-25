---@class FramePositioning
---@field point AnchorPoint
---@field relativePoint AnchorPoint
---@field xOfs integer
---@field yOfs integer
local FramePositioning = {}

---@class UFrameSettings
---@field anchor FramePositioning
---@field elements table<string, ElementSettings>
---@field visibility UFrameVisibility
local UFrameSettings = {
	enabled = true,
	width = 180,
	scale = 1,
	moved = false,
	config = {
		IsGroup = false
	}
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
