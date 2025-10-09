--[[
UnitFrame Preview Renderer
Renders embedded visual previews of unit frames in the options GUI.
Each element provides its own Preview method for accurate representation.
]]--
local _G, SUI = _G, SUI
local UF = SUI.UF

local PreviewRenderer = {}
local activePreview = nil
local currentFrameName = nil

-- Setup logging
local function log(message, level)
	SUI.Log(message, 'UnitFrames.Preview.Renderer', level or 'debug')
end

---Calculates the height of a frame based on enabled elements
---@param frameName UnitFrameName
---@param settings table
---@return number height
function PreviewRenderer:CalculateHeight(frameName, settings)
	local height = 0

	if settings.elements then
		-- Health and Power bars contribute to height
		if settings.elements.Health and settings.elements.Health.enabled then
			height = height + (settings.elements.Health.height or 20)
		end
		if settings.elements.Power and settings.elements.Power.enabled then
			height = height + (settings.elements.Power.height or 15)
		end
		if settings.elements.Castbar and settings.elements.Castbar.enabled then
			height = height + (settings.elements.Castbar.height or 20)
		end
	end

	-- Minimum height
	if height == 0 then
		height = 40
	end

	return height
end

---Renders the preview for a specific frame
---@param previewContainer frame Parent container to attach preview to
---@param frameName UnitFrameName
function PreviewRenderer:Render(previewContainer, frameName)
	log('Render called for frameName: ' .. tostring(frameName), 'info')

	if not frameName or not UF.CurrentSettings[frameName] then
		log('Invalid frameName or no settings: ' .. tostring(frameName), 'warning')
		return
	end

	log('Container: ' .. tostring(previewContainer) .. ', Type: ' .. type(previewContainer))

	-- Clear existing preview
	if activePreview then
		log('Clearing existing preview')
		activePreview:Hide()
		activePreview:SetParent(nil)
		activePreview = nil
	end

	local settings = UF.CurrentSettings[frameName]
	local width = settings.width or 180
	local scale = settings.scale or 1
	local height = self:CalculateHeight(frameName, settings)

	log(('Creating preview frame: width=%d, height=%d, scale=%.2f'):format(width, height, scale))

	-- Create preview frame
	local preview = CreateFrame('Frame', nil, previewContainer, BackdropTemplateMixin and 'BackdropTemplate')
	preview:SetSize(width * scale, height * scale)
	preview:SetPoint('CENTER', previewContainer)

	log('Preview frame created successfully')

	-- Scale down if too large to fit
	local maxWidth = 380
	if width * scale > maxWidth then
		local scaleFactor = maxWidth / (width * scale)
		preview:SetScale(scaleFactor)
	end

	-- Frame background and border
	preview:SetBackdrop({
		bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
		edgeFile = 'Interface\\Buttons\\WHITE8X8',
		tile = false,
		edgeSize = 2,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	preview:SetBackdropColor(0, 0, 0, 0.5)
	preview:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

	preview.elements = {}

	-- Render elements in proper order
	local elementOrder = {
		'Health', 'Power', 'Portrait', 'Name', 'StatusText',
		'Castbar', 'ClassPower', 'Runes', 'Totems',
		'Buffs', 'Debuffs', 'Auras',
		'RaidTargetIndicator', 'LeaderIndicator', 'AssistantIndicator',
		'CombatIndicator', 'RestingIndicator', 'PvPIndicator',
		'GroupRoleIndicator', 'RaidRoleIndicator', 'ReadyCheckIndicator',
		'SummonIndicator', 'ResurrectIndicator', 'PhaseIndicator'
	}

	local elementsRendered = 0
	for _, elementName in ipairs(elementOrder) do
		local elementSettings = settings.elements and settings.elements[elementName]
		local elementData = UF.Elements.List[elementName]

		if elementSettings and elementSettings.enabled and elementData then
			-- Check if should show in preview
			local showInPreview = elementSettings.showInPreview
			if showInPreview == nil then
				-- Use element's default
				showInPreview = elementData.ElementSettings and elementData.ElementSettings.showInPreview or false
			end

			log(('Element %s: enabled=%s, showInPreview=%s, hasPreview=%s'):format(
				elementName,
				tostring(elementSettings.enabled),
				tostring(showInPreview),
				tostring(elementData.Preview ~= nil)
			))

			if showInPreview and elementData.Preview then
				log(('Rendering element: %s'):format(elementName), 'info')
				local success, result = pcall(elementData.Preview, preview, elementSettings, frameName)
				if success then
					-- Preview function was called successfully
					-- Result is the height returned, elements are created on the preview frame
					elementsRendered = elementsRendered + 1
					log(('Element %s rendered successfully, returned height: %s'):format(elementName, tostring(result)))
				else
					log(('Error rendering element %s: %s'):format(elementName, tostring(result)), 'error')
				end
			end
		end
	end

	log(('Preview complete: %d elements rendered'):format(elementsRendered), 'info')

	activePreview = preview
	currentFrameName = frameName

	preview:Show()
	return preview
end

---Clears the current preview
function PreviewRenderer:Clear()
	if activePreview then
		-- Clean up elements if they exist (for backwards compatibility)
		if activePreview.elements then
			for _, element in pairs(activePreview.elements) do
				if type(element) == 'table' then
					if element.Hide then element:Hide() end
					if element.SetParent then element:SetParent(nil) end
				end
			end
		end

		-- Elements are children of the preview frame, they'll be cleaned up when frame is hidden
		activePreview:Hide()
		activePreview:SetParent(nil)
		activePreview = nil
	end
	currentFrameName = nil
end

---Refreshes the current preview if one is active
function PreviewRenderer:RefreshCurrent()
	if currentFrameName and activePreview then
		local container = activePreview:GetParent()
		if container then
			self:Render(container, currentFrameName)
		end
	end
end

---Gets the current preview frame name
---@return UnitFrameName|nil
function PreviewRenderer:GetCurrentFrameName()
	return currentFrameName
end

UF.PreviewRenderer = PreviewRenderer
