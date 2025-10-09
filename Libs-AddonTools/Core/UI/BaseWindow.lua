---@class LibAT
local LibAT = LibAT

----------------------------------------------------------------------------------------------------
-- Window Configuration
----------------------------------------------------------------------------------------------------

---@class WindowConfig
---@field name string Unique name for the window frame
---@field title string Window title text
---@field width number Window width (default 800)
---@field height number Window height (default 538)
---@field portrait? string Optional portrait texture path
---@field hidePortrait? boolean Hide the portrait (default true)

----------------------------------------------------------------------------------------------------
-- Base Window Creation
----------------------------------------------------------------------------------------------------

---Create a standardized base window with ButtonFrameTemplate
---@param config WindowConfig Window configuration
---@return Frame window The created window frame
function LibAT.UI.CreateWindow(config)
	-- Validate configuration
	if not config.name or config.name == '' then
		error('CreateWindow: config.name is required')
	end
	if not config.title or config.title == '' then
		error('CreateWindow: config.title is required')
	end

	-- Apply defaults
	config.width = config.width or 800
	config.height = config.height or 538
	config.hidePortrait = config.hidePortrait ~= false -- Default true

	-- Create main frame using ButtonFrameTemplate (AH window size: 800x538)
	local window = CreateFrame('Frame', config.name, UIParent, 'ButtonFrameTemplate')

	-- Hide portrait if requested
	if config.hidePortrait then
		ButtonFrameTemplate_HidePortrait(window)
	end

	window:SetSize(config.width, config.height)
	window:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	window:SetFrameStrata('HIGH')
	window:Hide()

	-- Make the window movable
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag('LeftButton')
	window:SetScript('OnDragStart', window.StartMoving)
	window:SetScript(
		'OnDragStop',
		function(self)
			self:StopMovingOrSizing()
		end
	)

	-- Set the portrait if provided (with safety checks)
	if config.portrait and window.portrait then
		if window.portrait.SetTexture then
			window.portrait:SetTexture(config.portrait)
		end
	end

	-- Set title
	window:SetTitle(config.title)

	-- Store configuration
	window.config = config

	return window
end

----------------------------------------------------------------------------------------------------
-- Window Layout Helpers
----------------------------------------------------------------------------------------------------

---Create a control frame positioned like AuctionHouse SearchBar
---@param window Frame The parent window
---@param yOffset? number Optional Y offset from top (default -33)
---@param height? number Optional height (default 28)
---@return Frame controlFrame The control frame
function LibAT.UI.CreateControlFrame(window, yOffset, height)
	yOffset = yOffset or -33
	height = height or 28

	local controlFrame = CreateFrame('Frame', nil, window)
	controlFrame:SetPoint('TOPLEFT', window, 'TOPLEFT', 2, yOffset)
	controlFrame:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -2, yOffset)
	controlFrame:SetHeight(height)

	return controlFrame
end

---Create a main content area positioned below control frame
---@param window Frame The parent window
---@param controlFrame Frame The control frame to anchor below
---@param yOffset? number Optional Y offset from control frame (default -4)
---@param bottomOffset? number Optional bottom offset (default 12)
---@return Frame contentFrame The main content frame
function LibAT.UI.CreateContentFrame(window, controlFrame, yOffset, bottomOffset)
	yOffset = yOffset or -4
	bottomOffset = bottomOffset or 12

	local contentFrame = CreateFrame('Frame', nil, window)
	contentFrame:SetPoint('TOPLEFT', controlFrame, 'BOTTOMLEFT', 0, yOffset)
	contentFrame:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -20, bottomOffset)

	return contentFrame
end

---Create a left panel for navigation (styled like AuctionFrame's category list)
---@param parent Frame The parent frame
---@param width? number Optional width (default 155)
---@param xOffset? number Optional X offset from left (default 10)
---@param yOffset? number Optional Y offset from top (default 0)
---@param bottomOffset? number Optional bottom offset (default 20)
---@return Frame leftPanel The left navigation panel
function LibAT.UI.CreateLeftPanel(parent, width, xOffset, yOffset, bottomOffset)
	width = width or 155
	xOffset = xOffset or 10
	yOffset = yOffset or 0
	bottomOffset = bottomOffset or 20

	local leftPanel = CreateFrame('Frame', nil, parent)
	leftPanel:SetPoint('TOPLEFT', parent, 'TOPLEFT', xOffset, yOffset)
	leftPanel:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', xOffset, bottomOffset)
	leftPanel:SetWidth(width)
	leftPanel.layoutType = 'InsetFrameTemplate'

	-- Add AuctionHouse categories background
	leftPanel.Background = leftPanel:CreateTexture(nil, 'BACKGROUND')
	leftPanel.Background:SetAtlas('auctionhouse-background-summarylist', true)
	leftPanel.Background:SetAllPoints(leftPanel)

	-- Add nine slice border
	leftPanel.NineSlice = CreateFrame('Frame', nil, leftPanel, 'NineSlicePanelTemplate')
	leftPanel.NineSlice:SetAllPoints()

	return leftPanel
end

---Create a right panel for content (styled like AuctionFrame's item list)
---@param parent Frame The parent frame
---@param leftPanel Frame The left panel to anchor beside
---@param spacing? number Optional spacing between panels (default 20)
---@param rightOffset? number Optional right offset (default -10)
---@param yOffset? number Optional Y offset from top (default 0)
---@param bottomOffset? number Optional bottom offset (default 20)
---@return Frame rightPanel The right content panel
function LibAT.UI.CreateRightPanel(parent, leftPanel, spacing, rightOffset, yOffset, bottomOffset)
	spacing = spacing or 20
	rightOffset = rightOffset or -10
	yOffset = yOffset or 0
	bottomOffset = bottomOffset or 20

	local rightPanel = CreateFrame('Frame', nil, parent)
	rightPanel:SetPoint('TOPLEFT', leftPanel, 'TOPRIGHT', spacing, yOffset)
	rightPanel:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', rightOffset, bottomOffset)
	rightPanel.layoutType = 'InsetFrameTemplate'

	-- Add AuctionHouse index background
	rightPanel.Background = rightPanel:CreateTexture(nil, 'BACKGROUND')
	rightPanel.Background:SetAtlas('auctionhouse-background-index', true)
	rightPanel.Background:SetAllPoints(rightPanel)

	-- Add nine slice border
	rightPanel.NineSlice = CreateFrame('Frame', nil, rightPanel, 'NineSlicePanelTemplate')
	rightPanel.NineSlice:SetAllPoints()

	return rightPanel
end

---Create action buttons positioned in bottom right (like AH Cancel Auction button)
---@param window Frame The parent window
---@param buttons table Array of button configs: {text = "Button", width = 70, height = 22, onClick = function}
---@param spacing? number Optional spacing between buttons (default 5)
---@param bottomOffset? number Optional bottom offset (default 4)
---@param rightOffset? number Optional right offset (default -3)
---@return table buttons Array of created button frames
function LibAT.UI.CreateActionButtons(window, buttons, spacing, spacing, bottomOffset, rightOffset)
	spacing = spacing or 5
	bottomOffset = bottomOffset or 4
	rightOffset = rightOffset or -3

	local createdButtons = {}
	local previousButton = nil

	for i = #buttons, 1, -1 do -- Reverse order so rightmost button is first
		local buttonConfig = buttons[i]
		local button = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
		button:SetSize(buttonConfig.width or 70, buttonConfig.height or 22)
		button:SetText(buttonConfig.text or 'Button')

		if previousButton then
			button:SetPoint('RIGHT', previousButton, 'LEFT', -spacing, 0)
		else
			button:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', rightOffset, bottomOffset)
		end

		if buttonConfig.onClick then
			button:SetScript('OnClick', buttonConfig.onClick)
		end

		table.insert(createdButtons, 1, button) -- Insert at beginning to maintain order
		previousButton = button
	end

	return createdButtons
end

return LibAT.UI
