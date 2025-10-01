--[[
UnitFrame Visual Preview System
Creates a visual preview of unit frame configurations that appears in the options GUI.
This is a standalone frame that shows what the frame will look like with current settings.
]]--
local _G, SUI = _G, SUI
local UF = SUI.UF

local FramePreview = {}
local previewFrame = nil
local currentFrameName = nil

-- Helper functions
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

---Creates the preview frame if it doesn't exist
function FramePreview:CreateFrame()
	if previewFrame then return previewFrame end

	-- Create the main container
	local frame = CreateFrame('Frame', 'SUI_UnitFramePreviewFrame', UIParent, BackdropTemplateMixin and 'BackdropTemplate')
	frame:SetSize(450, 200)
	frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 100)
	frame:SetFrameStrata('DIALOG')
	frame:SetFrameLevel(100)
	frame:Hide()

	-- Background
	frame:SetBackdrop({
		bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
		edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.8)

	-- Title
	local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
	title:SetPoint('TOP', 0, -12)
	title:SetText('Frame Preview')
	frame.title = title

	-- Preview container (where the actual frame preview will be rendered)
	local container = CreateFrame('Frame', nil, frame)
	container:SetPoint('TOP', title, 'BOTTOM', 0, -10)
	container:SetSize(420, 120)
	frame.container = container

	-- Close button
	local closeBtn = CreateFrame('Button', nil, frame, 'UIPanelCloseButton')
	closeBtn:SetPoint('TOPRIGHT', -5, -5)
	closeBtn:SetScript('OnClick', function()
		frame:Hide()
	end)

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag('LeftButton')
	frame:SetScript('OnDragStart', frame.StartMoving)
	frame:SetScript('OnDragStop', frame.StopMovingOrSizing)

	-- Info label
	local infoLabel = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	infoLabel:SetPoint('BOTTOM', 0, 10)
	infoLabel:SetText('')
	frame.infoLabel = infoLabel

	previewFrame = frame
	return frame
end

---Clears the preview container
function FramePreview:Clear()
	if not previewFrame or not previewFrame.container then return end

	local container = previewFrame.container
	if container.elements then
		for _, element in pairs(container.elements) do
			element:Hide()
			element:SetParent(nil)
		end
	end
	container.elements = {}

	if container.previewFrame then
		container.previewFrame:Hide()
		container.previewFrame:SetParent(nil)
		container.previewFrame = nil
	end
end

---Renders a single element on the preview
---@param parent frame
---@param elementName string
---@param elementSettings table
---@param frameSettings table
---@return frame|nil
function FramePreview:RenderElement(parent, elementName, elementSettings, frameSettings)
	if not elementSettings or not elementSettings.enabled then return nil end

	local element = CreateFrame('Frame', nil, parent)
	element:SetFrameLevel(parent:GetFrameLevel() + 1)

	local elementType = elementSettings.config and elementSettings.config.type or 'General'
	local width, height

	-- Calculate dimensions based on element type
	if elementType == 'StatusBar' then
		width = frameSettings.width
		height = elementSettings.height or 20
	elseif elementType == 'Indicator' or elementType == 'Text' then
		width = elementSettings.size or 16
		height = elementSettings.size or 16
	elseif elementType == 'Auras' then
		local auraSize = elementSettings.size or 24
		local numAuras = math.min(elementSettings.number or 5, 8)
		width = numAuras * (auraSize + (elementSettings.spacing or 2))
		height = auraSize
	else
		width = elementSettings.width or 20
		height = elementSettings.height or 20
	end

	element:SetSize(width, height)

	-- Position the element
	local pos = elementSettings.position
	if pos then
		local relativeTo = parent
		if pos.relativeTo and pos.relativeTo ~= 'Frame' and parent.elements and parent.elements[pos.relativeTo] then
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

	-- Render based on element type
	if elementType == 'StatusBar' then
		-- Create status bar with actual texture
		local bar = CreateFrame('StatusBar', nil, element)
		bar:SetAllPoints()
		bar:SetMinMaxValues(0, 100)
		bar:SetValue(75)

		-- Use actual texture if specified
		local texture = elementSettings.texture
		if texture then
			local LSM = LibStub('LibSharedMedia-3.0', true)
			if LSM then
				local texPath = LSM:Fetch('statusbar', texture)
				if texPath then
					bar:SetStatusBarTexture(texPath)
				end
			end
		end

		-- Set color based on element name
		if elementName == 'Health' then
			local r, g, b = GetClassColor()
			bar:SetStatusBarColor(r, g, b, 1)
		elseif elementName == 'Power' then
			local r, g, b = GetPowerColor()
			bar:SetStatusBarColor(r, g, b, 1)
		else
			bar:SetStatusBarColor(0.3, 0.8, 0.3, 1)
		end

		-- Background
		if elementSettings.bg and elementSettings.bg.enabled then
			local bg = bar:CreateTexture(nil, 'BACKGROUND')
			bg:SetAllPoints()
			if elementSettings.bg.useClassColor then
				local r, g, b = GetClassColor()
				local alpha = elementSettings.bg.classColorAlpha or 0.2
				bg:SetColorTexture(r, g, b, alpha)
			elseif elementSettings.bg.color then
				local c = elementSettings.bg.color
				bg:SetColorTexture(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0.5)
			else
				bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
			end
		end

		element.bar = bar
	elseif elementType == 'Indicator' then
		local tex = element:CreateTexture(nil, 'OVERLAY')
		tex:SetAllPoints()
		tex:SetColorTexture(1, 0.8, 0, 0.8)
		element.texture = tex
	elseif elementType == 'Text' then
		local text = element:CreateFontString(nil, 'OVERLAY')
		text:SetAllPoints()
		text:SetFont(STANDARD_TEXT_FONT, elementSettings.textSize or 12, 'OUTLINE')
		text:SetText(elementName)
		text:SetTextColor(1, 1, 1)
		text:SetJustifyH(elementSettings.SetJustifyH or 'CENTER')
		text:SetJustifyV(elementSettings.SetJustifyV or 'MIDDLE')
		element.text = text
	elseif elementType == 'Auras' then
		local auraSize = elementSettings.size or 24
		local numAuras = math.min(elementSettings.number or 5, 8)
		for i = 1, numAuras do
			local aura = CreateFrame('Frame', nil, element)
			aura:SetSize(auraSize, auraSize)
			aura:SetPoint('LEFT', (i - 1) * (auraSize + (elementSettings.spacing or 2)), 0)

			local icon = aura:CreateTexture(nil, 'ARTWORK')
			icon:SetAllPoints()
			icon:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')

			local border = aura:CreateTexture(nil, 'OVERLAY')
			border:SetAllPoints()
			border:SetAtlas('auctionhouse-itemicon-border')
			border:SetVertexColor(0.5, 0.5, 0.5, 1)
		end
	end

	return element
end

---Updates the preview for a specific frame
---@param frameName UnitFrameName
function FramePreview:Update(frameName)
	if not frameName or not UF.CurrentSettings[frameName] then return end

	currentFrameName = frameName
	local frame = self:CreateFrame()
	self:Clear()

	local settings = UF.CurrentSettings[frameName]
	local width = settings.width or 180
	local scale = settings.scale or 1
	local height = 0

	-- Calculate height based on elements
	if settings.elements then
		if settings.elements.Health and settings.elements.Health.enabled then
			height = height + (settings.elements.Health.height or 20)
		end
		if settings.elements.Power and settings.elements.Power.enabled then
			height = height + (settings.elements.Power.height or 15)
		end
	end
	if height == 0 then height = 40 end

	-- Create preview frame
	local previewBorder = CreateFrame('Frame', nil, frame.container, BackdropTemplateMixin and 'BackdropTemplate')
	previewBorder:SetSize(width * scale, height * scale)
	previewBorder:SetPoint('CENTER')
	previewBorder:SetScale(math.min(1, 400 / (width * scale))) -- Scale down if too large
	previewBorder:SetBackdrop({
		bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
		edgeFile = 'Interface\\Buttons\\WHITE8X8',
		tile = false,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	previewBorder:SetBackdropColor(0, 0, 0, 0.5)
	previewBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

	frame.container.previewFrame = previewBorder
	previewBorder.elements = {}

	-- Render elements
	local elementOrder = {
		'Health', 'Power', 'Portrait', 'Name', 'StatusText',
		'Castbar', 'ClassPower', 'Buffs', 'Debuffs', 'Auras',
		'RaidTargetIndicator', 'LeaderIndicator', 'CombatIndicator'
	}

	for _, elementName in ipairs(elementOrder) do
		if settings.elements and settings.elements[elementName] and settings.elements[elementName].enabled then
			local element = self:RenderElement(previewBorder, elementName, settings.elements[elementName], settings)
			if element then
				previewBorder.elements[elementName] = element
			end
		end
	end

	-- Draw anchor lines showing element relationships
	previewBorder.anchorLines = {}
	for elementName, element in pairs(previewBorder.elements) do
		local elementSettings = settings.elements[elementName]
		if elementSettings and elementSettings.position and elementSettings.position.relativeTo and elementSettings.position.relativeTo ~= 'Frame' then
			local relativeTo = previewBorder.elements[elementSettings.position.relativeTo]
			if relativeTo then
				-- Create line showing anchor relationship
				local line = previewBorder:CreateLine()
				line:SetColorTexture(0, 1, 1, 0.5)
				line:SetThickness(2)
				line:SetStartPoint('CENTER', element)
				line:SetEndPoint('CENTER', relativeTo)
				previewBorder.anchorLines[#previewBorder.anchorLines + 1] = line
			end
		end
	end

	-- Update info label
	frame.title:SetText(string.format('Preview: %s', frameName))
	frame.infoLabel:SetFormattedText('%dx%d (Scale: %.2f)', width, height, scale)

	frame:Show()
end

---Shows the preview for a frame
---@param frameName UnitFrameName
function FramePreview:Show(frameName)
	self:Update(frameName)
end

---Hides the preview
function FramePreview:Hide()
	if previewFrame then
		previewFrame:Hide()
	end
end

---Refreshes the current preview
function FramePreview:Refresh()
	if currentFrameName then
		self:Update(currentFrameName)
	end
end

UF.FramePreview = FramePreview
