--[[
UnitFrame Preview Widget
Custom AceGUI widget for displaying UnitFrame previews in options.
]]
--
local Type, Version = 'SUI_UnitFramePreview', 1
local AceGUI = LibStub and LibStub('AceGUI-3.0', true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local SUI = SUI
local UF = SUI.UF

-- Logging - safe wrapper that checks if SUI.Log exists
local function log(message, level)
	if SUI and SUI.Log then
		SUI.Log(message, 'UnitFrames.Preview.Widget', level or 'debug')
	end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	['OnAcquire'] = function(self)
		log('Widget OnAcquire')
		self:SetHeight(140) -- Reduced from 200
		self:SetWidth(400)

		-- Get frameName from global
		local frameName = _G.SUI_PreviewFrameNames and _G.SUI_PreviewFrameNames.current
		if frameName then
			log('OnAcquire: Using stored frameName: ' .. frameName)
			self:SetFrameName(frameName)
		else
			log('OnAcquire: No frameName found, clearing preview')
			self:SetFrameName(nil)
		end
	end,

	['OnRelease'] = function(_)
		log('Widget OnRelease')
		-- Don't clear - just release. Let OnAcquire handle re-rendering
	end,

	-- Standard AceGUI methods that AceConfigDialog expects
	['SetText'] = function(_, text)
		-- AceConfigDialog calls this - we don't use it but need to provide it
		log('SetText called: ' .. tostring(text))
	end,

	['SetLabel'] = function(_, text)
		-- AceConfigDialog may call this too
		log('SetLabel called: ' .. tostring(text))
	end,

	['SetDisabled'] = function(self, disabled)
		-- Standard widget method
		self.disabled = disabled
	end,

	-- Our custom methods
	['SetFrameName'] = function(self, frameName)
		log('SetFrameName: ' .. tostring(frameName))
		self.frameName = frameName
		if frameName and UF.PreviewRenderer then
			-- Render preview into our container
			UF.PreviewRenderer:Render(self.container, frameName)
		elseif UF.PreviewRenderer then
			UF.PreviewRenderer:Clear()
		end
	end,

	['Refresh'] = function(self)
		log('Refresh called')
		if self.frameName and UF.PreviewRenderer then UF.PreviewRenderer:Render(self.container, self.frameName) end
	end,

	['Clear'] = function(self)
		log('Clear called')
		self.frameName = nil
		if UF.PreviewRenderer then UF.PreviewRenderer:Clear() end
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	log('Constructing widget', 'info')

	local frame = CreateFrame('Frame', nil, UIParent)
	frame:Hide()

	-- Container for preview frames
	local container = CreateFrame('Frame', nil, frame)
	container:SetAllPoints(frame)

	-- Create widget table
	local widget = {
		frame = frame,
		container = container,
		type = Type,
	}

	-- Add methods
	for method, func in pairs(methods) do
		widget[method] = func
	end

	log('Widget constructed successfully', 'info')
	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
log('Widget type registered: ' .. Type, 'info')
