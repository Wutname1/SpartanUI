---@class SUI.UF
local UF = SUI.UF

local Style = {}
local registry = {}

---@type SUI.Style.Settings.UnitFrames
local Defaults = {
	displayName = 'Default',
	positions = {},
	artwork = {},
	setup = {
		image = 'Interface\\AddOns\\SpartanUI\\Media\\Textures\\UI-StatusBar',
	},
}

---Register a style within the registry
---@param styleName string
---@param settings SUI.Style.Settings.UnitFrames
---@param update? function
function Style:Register(styleName, settings, update)
	registry[styleName] = {
		settings = SUI:CopyData(settings, Defaults),
		update = update,
	}

	if not registry[styleName].setup then
		registry[styleName].setup = {}
	end
end

---Activates a specified style, or will update the currently active style
---@param styleName? string
function Style:Change(styleName)
	if styleName then
		UF.DB.Style = styleName
	end
	if registry[styleName or UF.DB.Style].update then
		registry[styleName or UF.DB.Style].update()
	end
end

---Returns the ful list of registered styles
function Style:GetList()
	return registry
end

---Get config for the active style OR the specified styleName
---@param styleName? string
---@return SUI.Style.Settings.UnitFrames
function Style:Get(styleName)
	if styleName == 'war' then
		styleName = 'War'
	end

	return registry[styleName or UF.DB.Style].settings
end

Style.registry = registry
UF.Style = Style
