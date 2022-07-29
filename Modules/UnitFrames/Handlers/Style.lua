---@class SUI_UnitFrames : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0
local UF = SUI:GetModule('Component_UnitFrames')

local Style = {}

function Style:Register(styleName, settings, update)
end

function Style:Change(styleName)
end

---Get config for the active style OR the specified styleName
---@param styleName? string
function Style:Get(styleName)
	return Style[styleName].settings
end

UF.Style = Style
