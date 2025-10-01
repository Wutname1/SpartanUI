--[[-----------------------------------------------------------------------------
UnitFrame Preview Widget
Displays a visual preview of a UnitFrame configuration without modifying the actual frame.
Shows frame dimensions, elements, text samples, and styling.
-------------------------------------------------------------------------------]]
local Type, Version = "SUI_UnitFramePreview", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, ipairs, type, tostring = pairs, ipairs, type, tostring
local floor, max, min = math.floor, math.max, math.min

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

-- SUI APIs
local SUI = SUI
local UF = SUI.UF

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function GetClassColor()
	local _, class = UnitClass('player')
	if class then
		local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
		if color then
			return color.r, color.g, color.b
		end
	end
	return 1, 1, 1
end

local function GetPowerColor()
	local powerType, powerToken = UnitPowerType('player')
	local info = PowerBarColor[powerToken]
	if info then
		return info.r, info.g, info.b
	end
	return 0, 0.5, 1
end

local function DrawElement(parent, elementName, elementSettings, frameSettings)
	if not elementSettings.enabled then return nil end

	local element = CreateFrame('Frame', nil, parent)
	element:SetFrameLevel(parent:GetFrameLevel() + (elementSettings.FrameLevel or 1))

	local elementType = elementSettings.config and elementSettings.config.type or 'General'

	-- Determine element dimensions
	local width, height
	if elementType == 'StatusBar' then
		width = frameSettings.width
		height = elementSettings.height or 20
	elseif elementType == 'Indicator' or elementType == 'Text' then
		width = elementSettings.size or 16
		height = elementSettings.size or 16
	elseif elementType == 'Auras' then
		width = (elementSettings.size or 24) * (elementSettings.number or 5)
		height = elementSettings.size or 24
	else
		width = elementSettings.width or 20
		height = elementSettings.height or 20
	end

	element:SetSize(width, height)

	-- Position the element
	local pos = elementSettings.position
	if pos then
		local relativeTo = parent
		if pos.relativeTo and pos.relativeTo ~= 'Frame' and parent.elements[pos.relativeTo] then
			relativeTo = parent.elements[pos.relativeTo]
		end

		element:SetPoint(
			pos.anchor or 'CENTER',
			relativeTo,
			pos.relativePoint or pos.anchor or 'CENTER',
			pos.x or 0,
			pos.y or 0
		)
	else
		element:SetPoint('CENTER')
	end

	-- Create background/main texture
	if elementType == 'StatusBar' then
		local bar = element:CreateTexture(nil, 'ARTWORK')
		bar:SetAllPoints()
		bar:SetColorTexture(0.2, 0.2, 0.2, 0.5)

		-- Create the foreground bar
		local fg = element:CreateTexture(nil, 'OVERLAY')
		fg:SetPoint('TOPLEFT')
		fg:SetPoint('BOTTOMLEFT')
		fg:SetWidth(width * 0.75) -- Show 75% filled

		-- Set color based on element type
		if elementName == 'Health' then
			local r, g, b = GetClassColor()
			fg:SetColorTexture(r, g, b, 0.8)
		elseif elementName == 'Power' then
			local r, g, b = GetPowerColor()
			fg:SetColorTexture(r, g, b, 0.8)
		else
			fg:SetColorTexture(0.3, 0.8, 0.3, 0.8)
		end

		-- Add background if enabled
		if elementSettings.bg and elementSettings.bg.enabled then
			local bgTex = element:CreateTexture(nil, 'BACKGROUND')
			bgTex:SetAllPoints()
			if elementSettings.bg.useClassColor then
				local r, g, b = GetClassColor()
				local alpha = elementSettings.bg.classColorAlpha or 0.2
				bgTex:SetColorTexture(r, g, b, alpha)
			elseif elementSettings.bg.color then
				local c = elementSettings.bg.color
				bgTex:SetColorTexture(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0.5)
			else
				bgTex:SetColorTexture(0.1, 0.1, 0.1, 0.5)
			end
		end

		element.bar = bar
		element.fg = fg
	elseif elementType == 'Indicator' then
		local tex = element:CreateTexture(nil, 'OVERLAY')
		tex:SetAllPoints()
		tex:SetColorTexture(0.8, 0.8, 0.2, 0.7)
		element.texture = tex
	elseif elementType == 'Text' then
		local text = element:CreateFontString(nil, 'OVERLAY')
		text:SetAllPoints()
		text:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
		text:SetText(elementSettings.config and elementSettings.config.DisplayName or elementName)
		text:SetTextColor(1, 1, 1)
		text:SetJustifyH('CENTER')
		text:SetJustifyV('MIDDLE')
		element.text = text
	elseif elementType == 'Auras' then
		local auraSize = elementSettings.size or 24
		for i = 1, min(elementSettings.number or 5, 8) do
			local aura = CreateFrame('Frame', nil, element)
			aura:SetSize(auraSize, auraSize)
			aura:SetPoint('LEFT', (i - 1) * (auraSize + (elementSettings.spacing or 2)), 0)

			local tex = aura:CreateTexture(nil, 'BORDER')
			tex:SetAllPoints()
			tex:SetColorTexture(0.3, 0.3, 0.8, 0.5)

			local border = aura:CreateTexture(nil, 'ARTWORK')
			border:SetAllPoints()
			border:SetColorTexture(0.7, 0.7, 0.7, 1)
			border:SetPoint('TOPLEFT', 1, -1)
			border:SetPoint('BOTTOMRIGHT', -1, 1)
		end
	else
		-- Generic element
		local tex = element:CreateTexture(nil, 'ARTWORK')
		tex:SetAllPoints()
		tex:SetColorTexture(0.5, 0.5, 0.5, 0.5)
		element.texture = tex
	end

	return element
end

local function UpdatePreview(self)
	if self.updating then return end
	self.updating = true

	local frameName = self.frameName
	if not frameName then
		self.updating = nil
		return
	end

	local frameSettings = UF.CurrentSettings[frameName]
	if not frameSettings then
		self.updating = nil
		return
	end

	local preview = self.preview

	-- Clear existing elements
	if preview.elements then
		for _, element in pairs(preview.elements) do
			element:Hide()
			element:SetParent(nil)
		end
	end
	preview.elements = {}

	-- Update frame dimensions
	local scale = frameSettings.scale or 1
	local width = frameSettings.width or 180

	-- Calculate height based on elements
	local height = 0
	local elements = frameSettings.elements
	if elements then
		-- Find health and power bars to determine base height
		if elements.Health and elements.Health.enabled then
			height = height + (elements.Health.height or 20)
		end
		if elements.Power and elements.Power.enabled then
			height = height + (elements.Power.height or 15)
		end

		-- If no bars, use a default height
		if height == 0 then
			height = 40
		end
	else
		height = 40
	end

	preview:SetSize(width * scale, height * scale)

	-- Draw frame background
	local bg = preview.bg
	if frameSettings.frameBackground and frameSettings.frameBackground.enabled then
		bg:Show()
		local fbg = frameSettings.frameBackground
		if fbg.color then
			bg:SetColorTexture(fbg.color[1] or 0, fbg.color[2] or 0, fbg.color[3] or 0, fbg.color[4] or 0.5)
		else
			bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
		end
	else
		bg:SetColorTexture(0, 0, 0, 0.3)
	end

	-- Draw frame border
	preview.border:SetColorTexture(0.5, 0.5, 0.5, 1)

	-- Draw elements
	if elements then
		local elementOrder = {
			'Health', 'Power', 'Portrait', 'Name', 'StatusText',
			'Castbar', 'ClassPower', 'Buffs', 'Debuffs', 'Auras',
			'RaidTargetIndicator', 'LeaderIndicator', 'AssistantIndicator',
			'CombatIndicator', 'RestingIndicator', 'PvPIndicator'
		}

		for _, elementName in ipairs(elementOrder) do
			local elementSettings = elements[elementName]
			if elementSettings and elementSettings.enabled then
				local element = DrawElement(preview, elementName, elementSettings, frameSettings)
				if element then
					preview.elements[elementName] = element
				end
			end
		end
	end

	-- Update dimension label
	local dimensionText = string.format('%dx%d (Scale: %.2f)', width, height, scale)
	self.dimensionLabel:SetText(dimensionText)

	self.updating = nil
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	['OnAcquire'] = function(self)
		self:SetWidth(200)
		self:SetHeight(120)
		self.frameName = nil
		self.dimensionLabel:SetText('')
	end,

	['OnRelease'] = function(self)
		self.frameName = nil
		if self.preview.elements then
			for _, element in pairs(self.preview.elements) do
				element:Hide()
				element:SetParent(nil)
			end
			self.preview.elements = {}
		end
	end,

	['OnWidthSet'] = function(self, width)
		UpdatePreview(self)
	end,

	['OnHeightSet'] = function(self, height)
		UpdatePreview(self)
	end,

	['SetFrameName'] = function(self, frameName)
		self.frameName = frameName
		UpdatePreview(self)
	end,

	['Refresh'] = function(self)
		UpdatePreview(self)
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:Hide()

	-- Create container for the preview
	local container = CreateFrame('Frame', nil, frame)
	container:SetPoint('TOP', 0, -5)
	container:SetPoint('LEFT', 5, 0)
	container:SetPoint('RIGHT', -5, 0)
	container:SetHeight(80)

	-- Create the preview frame
	local preview = CreateFrame('Frame', nil, container)
	preview:SetPoint('CENTER')
	preview:SetSize(180, 40)

	-- Background
	local bg = preview:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.3)
	preview.bg = bg

	-- Border
	local border = CreateFrame('Frame', nil, preview, BackdropTemplateMixin and 'BackdropTemplate')
	border:SetAllPoints()
	border:SetBackdrop({
		edgeFile = 'Interface\\Buttons\\WHITE8X8',
		edgeSize = 1,
	})
	border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	preview.border = border

	preview.elements = {}

	-- Dimension label
	local dimensionLabel = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	dimensionLabel:SetPoint('BOTTOM', container, 'BOTTOM', 0, -15)
	dimensionLabel:SetText('')
	dimensionLabel:SetTextColor(0.7, 0.7, 0.7)

	-- Create widget
	local widget = {
		frame = frame,
		preview = preview,
		dimensionLabel = dimensionLabel,
		type = Type,
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
