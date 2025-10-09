--[[
UnitFrame Preview Injector
Hooks into AceConfigDialog to inject embedded preview frames into the options GUI.
]]
--
local _G, SUI = _G, SUI
local UF = SUI.UF
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

local PreviewInjector = {}
local injectedPreviews = {} -- Track which option pages have previews injected

-- Setup logging
local function log(message, level)
	SUI.Log(message, 'UnitFrames.Preview.Injector', level or 'debug')
end

---Extracts the frame name from an AceConfig path
---@param appName string
---@param path string[]
---@return UnitFrameName|nil
local function ExtractFrameNameFromPath(appName, path)
	-- Path structure: {"UnitFrames", "player"} or similar
	log(('ExtractFrameNameFromPath: appName=%s, path=%s'):format(tostring(appName), table.concat(path or {}, ', ')))

	-- SpartanUI uses 'SpartanUI' as the appName in AceConfigDialog
	if appName ~= 'SpartanUI' or not path or #path < 2 then
		log(('Path too short or wrong appName (expected SpartanUI, got %s, #path=%d)'):format(tostring(appName), path and #path or 0))
		return nil
	end
	if path[1] ~= 'UnitFrames' then
		log('Not a UnitFrames path (path[1]=' .. tostring(path[1]) .. ')')
		return nil
	end

	local frameName = path[2]
	log('Extracted frameName: ' .. tostring(frameName))

	-- Validate it's a real frame name
	if UF.CurrentSettings and UF.CurrentSettings[frameName] then
		log('Valid frame name confirmed: ' .. frameName, 'info')
		return frameName
	end

	log('Invalid frame name: ' .. tostring(frameName), 'warning')
	return nil
end

---Recursively searches for the preview widget in the widget tree
---@param widget table AceGUI widget
---@param depth number Current recursion depth for logging
---@return table|nil The preview widget
local function FindPreviewWidgetRecursive(widget, depth)
	if not widget then return nil end

	depth = depth or 0

	-- Check if this is our preview widget
	if widget.type == 'SUI_UnitFramePreview' then
		log('Found preview widget!', 'info')
		return widget
	end

	-- Recursively check children
	if widget.children then
		for _, child in ipairs(widget.children) do
			local found = FindPreviewWidgetRecursive(child, depth + 1)
			if found then return found end
		end
	end

	return nil
end

---Finds the preview widget in the options tree
---@param optionsFrame frame The AceConfigDialog frame
---@return table|nil The preview widget
local function FindPreviewWidget(optionsFrame)
	if not optionsFrame then
		log('No optionsFrame')
		return nil
	end

	-- Try different possible structures
	local rootWidget = optionsFrame.obj

	if not rootWidget then
		log('No obj field, trying optionsFrame directly')
		rootWidget = optionsFrame
	end

	log('Starting widget tree search...')

	-- Start recursive search from the root widget
	local widget = FindPreviewWidgetRecursive(rootWidget, 0)
	if not widget then
		log('Widget tree search complete, preview widget not found', 'warning')
	end
	return widget
end

---Injects preview into the current options page if applicable
---@param appName string
---@param path string[]
local function InjectPreview(appName, path)
	log('InjectPreview called', 'info')

	local frameName = ExtractFrameNameFromPath(appName, path)
	if not frameName then
		-- Not a unit frame page
		log('No frame name extracted')
		return
	end

	-- Schedule injection with delay to let widget tree build
	local function TryInject(attempt)
		attempt = attempt or 1
		log(('Injection attempt #%d for frame: %s'):format(attempt, frameName))

		-- Get the options frame
		local optionsFrame = AceConfigDialog.OpenFrames[appName]
		if not optionsFrame then
			log('No options frame found')
			if attempt < 5 then
				C_Timer.After(0.2, function() TryInject(attempt + 1) end)
			end
			return
		end

		-- Find the preview widget
		local previewWidget = FindPreviewWidget(optionsFrame)
		if not previewWidget then
			log(('Preview widget not found on attempt #%d'):format(attempt))
			if attempt < 5 then
				C_Timer.After(0.2, function() TryInject(attempt + 1) end)
			else
				log('Gave up after 5 attempts', 'error')
			end
			return
		end

		-- Call SetFrameName on the widget
		log('Found preview widget, calling SetFrameName', 'info')
		previewWidget:SetFrameName(frameName)
		injectedPreviews[frameName] = true
	end

	-- Start with a small delay
	C_Timer.After(0.1, function() TryInject(1) end)
end

---Hooks AceConfigDialog to inject previews
function PreviewInjector:Initialize()
	log('Initializing PreviewInjector', 'info')

	-- Hook SelectGroup to detect navigation
	hooksecurefunc(AceConfigDialog, 'SelectGroup', function(self, appName, ...)
		log('SelectGroup hook triggered for: ' .. tostring(appName))
		local path = { ... }
		InjectPreview(appName, path)
	end)

	-- Hook Open to inject on initial open
	hooksecurefunc(AceConfigDialog, 'Open', function(self, appName, ...)
		log('Open hook triggered for: ' .. tostring(appName))
		-- Give the GUI time to build
		C_Timer.After(0.1, function()
			-- Get current path from the dialog
			local dialog = AceConfigDialog.OpenFrames[appName]
			if dialog and dialog.obj and dialog.obj.status then
				local path = dialog.obj.status.groups and dialog.obj.status.groups.selected or {}
				log('Got path from opened dialog: ' .. table.concat(path or {}, ', '))
				InjectPreview(appName, path)
			else
				log('Could not get path from dialog')
			end
		end)
	end)

	log('PreviewInjector initialized successfully', 'info')
end

---Clears all injected previews
function PreviewInjector:ClearAll()
	log('Clearing all previews')
	if UF.PreviewRenderer then UF.PreviewRenderer:Clear() end
	wipe(injectedPreviews)
end

UF.PreviewInjector = PreviewInjector
