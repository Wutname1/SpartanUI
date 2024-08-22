local addonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)

addon.BugWindow = {}

local window, currentErrorIndex, currentErrorList, currentSession
local countLabel, sessionLabel, textArea, nextButton, prevButton, tabs
local searchBox, filterButton
local categoryButtons = {}

local function updateDisplay(forceRefresh)
	if not window then addon.BugWindow.Create() end

	if forceRefresh or not currentErrorIndex then currentErrorIndex = #currentErrorList end

	local err = currentErrorList[currentErrorIndex]
	if err then
		countLabel:SetText(string.format('%d/%d', currentErrorIndex, #currentErrorList))
		sessionLabel:SetText(string.format(L['Session: %d'], err.session))
		textArea:SetText(addon.ErrorHandler:FormatError(err))

		nextButton:SetEnabled(currentErrorIndex < #currentErrorList)
		prevButton:SetEnabled(currentErrorIndex > 1)
	else
		countLabel:SetText('0/0')
		sessionLabel:SetText(L['No errors'])
		textArea:SetText(L['You have no errors, yay!'])

		nextButton:SetEnabled(false)
		prevButton:SetEnabled(false)
	end
end

local function setActiveCategory(button)
	for _, btn in ipairs(categoryButtons) do
		btn:SetNormalAtlas('auctionhouse-nav-button')
		btn.Text:SetTextColor(0.6, 0.6, 0.6)
	end
	button:SetNormalAtlas('auctionhouse-nav-button-secondary-select')
	button.Text:SetTextColor(1, 1, 1)

	if button:GetID() == 1 then
		currentErrorList = addon.ErrorHandler:GetErrors()
	elseif button:GetID() == 2 then
		currentErrorList = addon.ErrorHandler:GetErrors(addon.ErrorHandler:GetCurrentSession())
	elseif button:GetID() == 3 then
		local sessionList = addon.ErrorHandler:GetSessionList()
		local prevSession = sessionList[#sessionList - 1]
		currentErrorList = addon.ErrorHandler:GetErrors(prevSession)
	end

	updateDisplay(true)
end

local function createCategoryButton(parent, id, text, point)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(120, 30)
	button:SetID(id)
	button:SetPoint(unpack(point))

	button:SetNormalAtlas('auctionhouse-nav-button')
	button:SetHighlightAtlas('auctionhouse-nav-button-highlight')

	button.Text = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	button.Text:SetPoint('CENTER')
	button.Text:SetText(text)
	button.Text:SetTextColor(0.6, 0.6, 0.6)

	button:SetScript('OnClick', function(self)
		setActiveCategory(self)
	end)

	button:SetScript('OnEnter', function(self)
		self.Text:SetTextColor(1, 1, 1)
	end)

	button:SetScript('OnLeave', function(self)
		self.Text:SetTextColor(0.6, 0.6, 0.6)
	end)

	return button
end

local function filterErrors()
	local searchText = searchBox:GetText():lower()
	if searchText == '' then
		currentErrorList = addon.ErrorHandler:GetErrors()
	else
		currentErrorList = {}
		for _, err in ipairs(addon.ErrorHandler:GetErrors()) do
			if err.message:lower():find(searchText) or err.stack:lower():find(searchText) or (err.locals and err.locals:lower():find(searchText)) then table.insert(currentErrorList, err) end
		end
	end
	updateDisplay(true)
end

function addon.BugWindow.Create()
	window = CreateFrame('Frame', 'SUIErrorWindow', UIParent, 'SettingsFrameTemplate')
	window:SetFrameStrata('DIALOG')
	window:SetSize(850, 500)
	window:SetPoint('CENTER')
	window:SetMovable(true)
	window:SetResizable(true)
	window:EnableMouse(true)
	window:SetClampedToScreen(true)
	window:SetDontSavePosition(true)

	-- Make window draggable
	window:SetScript('OnMouseDown', function(self, button)
		if button == 'LeftButton' then self:StartMoving() end
	end)
	window:SetScript('OnMouseUp', function(self, button)
		self:StopMovingOrSizing()
	end)

	local title = window:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
	title:SetPoint('TOPLEFT', 32, -27)
	title:SetText(L['SpartanUI Error Display'])

	countLabel = window:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	countLabel:SetPoint('TOPRIGHT', -15, -27)

	sessionLabel = window:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	sessionLabel:SetPoint('TOP', 0, -27)

	-- Create category buttons
	local buttonNames = { L['All Errors'], L['Current Session'], L['Previous Session'] }
	for i, name in ipairs(buttonNames) do
		local point = { 'TOPLEFT', window, 'TOPLEFT', 32 + (i - 1) * 125, -64 }
		local button = createCategoryButton(window, i, name, point)
		table.insert(categoryButtons, button)
	end

	local innerFrame = CreateFrame('Frame', nil, window)
	innerFrame:SetPoint('TOPLEFT', 17, -96)
	innerFrame:SetPoint('BOTTOMRIGHT', -17, 50)

	-- Create ScrollFrame and ScrollChild
	local scrollFrame = CreateFrame('ScrollFrame', nil, innerFrame, 'UIPanelScrollFrameTemplate')
	scrollFrame:SetPoint('TOPLEFT', innerFrame, 'TOPLEFT', 4, -4)
	scrollFrame:SetPoint('BOTTOMRIGHT', innerFrame, 'BOTTOMRIGHT', -26, 4)

	local scrollChild = CreateFrame('Frame')
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically

	textArea = scrollChild:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	textArea:SetPoint('TOPLEFT')
	textArea:SetPoint('TOPRIGHT')
	textArea:SetJustifyH('LEFT')
	textArea:SetJustifyV('TOP')
	textArea:SetText('')

	prevButton = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
	prevButton:SetSize(100, 22)
	prevButton:SetPoint('BOTTOMLEFT', 16, 16)
	prevButton:SetText(L['< Previous'])
	prevButton:SetScript('OnClick', function()
		if currentErrorIndex > 1 then
			currentErrorIndex = currentErrorIndex - 1
			updateDisplay()
		end
	end)

	nextButton = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
	nextButton:SetSize(100, 22)
	nextButton:SetPoint('BOTTOMRIGHT', -16, 16)
	nextButton:SetText(L['Next >'])
	nextButton:SetScript('OnClick', function()
		if currentErrorIndex < #currentErrorList then
			currentErrorIndex = currentErrorIndex + 1
			updateDisplay()
		end
	end)

	local copyAllButton = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
	copyAllButton:SetSize(120, 22)
	copyAllButton:SetPoint('BOTTOM', 0, 16)
	copyAllButton:SetText(L['Easy Copy All'])
	copyAllButton:SetScript('OnClick', function()
		local allErrors = ''
		for _, err in ipairs(currentErrorList) do
			allErrors = allErrors .. addon.ErrorHandler:FormatError(err) .. '\n\n---\n\n'
		end
		textArea:SetText(allErrors)
		scrollChild:SetHeight(textArea:GetStringHeight())
		scrollFrame:UpdateScrollChildRect()
	end)

	searchBox = CreateFrame('EditBox', nil, window, 'SearchBoxTemplate')
	searchBox:SetSize(200, 20)
	searchBox:SetPoint('TOPRIGHT', -32, -70)
	searchBox:SetAutoFocus(false)
	searchBox:SetScript('OnEnterPressed', filterErrors)

	filterButton = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
	filterButton:SetSize(60, 22)
	filterButton:SetPoint('RIGHT', searchBox, 'LEFT', -5, 0)
	filterButton:SetText(L['Filter'])
	filterButton:SetScript('OnClick', filterErrors)

	window.currentErrorList = currentErrorList
	window:Hide()

	-- Add resize functionality
	window:SetResizable(true)
	window:SetResizeBounds(600, 400)

	local sizer = CreateFrame('Button', nil, window)
	sizer:SetPoint('BOTTOMRIGHT', -6, 7)
	sizer:SetSize(16, 16)
	sizer:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
	sizer:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
	sizer:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
	sizer:SetScript('OnMouseDown', function(_, button)
		if button == 'LeftButton' then window:StartSizing('BOTTOMRIGHT') end
	end)
	sizer:SetScript('OnMouseUp', function()
		window:StopMovingOrSizing()
		scrollFrame:SetWidth(innerFrame:GetWidth() - 30)
		scrollChild:SetWidth(scrollFrame:GetWidth())
		textArea:SetWidth(scrollChild:GetWidth())
	end)

	-- Set the first button as active
	setActiveCategory(categoryButtons[1])
end

function addon.BugWindow:OpenErrorWindow()
	if not window then addon.BugWindow.Create() end

	if not window:IsShown() then
		currentErrorList = addon.ErrorHandler:GetErrors()
		currentSession = addon.ErrorHandler:GetCurrentSession()
		currentErrorIndex = #currentErrorList
		updateDisplay(true)
		window:Show()
	else
		updateDisplay()
	end
end

function addon.BugWindow:CloseErrorWindow()
	if window then window:Hide() end
end

function addon.BugWindow:UpdateFontSize()
	if textArea then
		textArea:SetFontObject(_G[addon.Config.fontSize] or GameFontHighlight)
		if window:IsShown() then updateDisplay(true) end
	end
end

function addon.BugWindow:IsShown()
	return window and window:IsShown()
end
