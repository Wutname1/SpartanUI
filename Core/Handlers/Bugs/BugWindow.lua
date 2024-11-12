---@class Lib.ErrorWindow
local addon = select(2, ...)

local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)

addon.BugWindow = {}

local window, currentErrorIndex, currentErrorList, currentSession
local countLabel, sessionLabel, textArea
local ActiveButton = nil
local categoryButtons = {}
addon.BugWindow.window = window

local function updateDisplay(forceRefresh)
	if not window then addon.BugWindow.Create() end

	if forceRefresh or not currentErrorIndex then currentErrorIndex = #currentErrorList end

	local err = currentErrorList[currentErrorIndex]
	if err then
		countLabel:SetText(string.format('%d/%d', currentErrorIndex, #currentErrorList))
		sessionLabel:SetText(string.format(L['Session: %d'], err.session))
		textArea:SetText(addon.ErrorHandler:FormatError(err))

		window.Buttons.Next:SetEnabled(currentErrorIndex < #currentErrorList)
		window.Buttons.Prev:SetEnabled(currentErrorIndex > 1)
		window.Buttons.CopyAll:SetEnabled(#currentErrorList > 1)
	else
		countLabel:SetText('0/0')
		sessionLabel:SetText(L['No errors'])
		textArea:SetText(L['You have no errors, yay!'])

		window.Buttons.Next:SetEnabled(false)
		window.Buttons.Prev:SetEnabled(false)
		window.Buttons.CopyAll:SetEnabled(false)
	end
end

---comment
---@param parent table|Frame
---@param text string
---@param id? number
---@return table|Button
local function createButton(parent, text, id)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(120, 25)
	if id then button:SetID(id) end

	button:SetNormalAtlas('auctionhouse-nav-button')
	button:SetHighlightAtlas('auctionhouse-nav-button-highlight')
	button:SetPushedAtlas('auctionhouse-nav-button-select')
	button:SetDisabledAtlas('UI-CastingBar-TextBox')

	local normalTexture = button:GetNormalTexture()
	normalTexture:SetTexCoord(0, 1, 0, 0.7)

	button.Text = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	button.Text:SetPoint('CENTER')
	button.Text:SetText(text)
	button.Text:SetTextColor(1, 1, 1, 1)

	button:HookScript('OnDisable', function(self)
		self.Text:SetTextColor(0.6, 0.6, 0.6, 0.6)
	end)

	button:HookScript('OnEnable', function(self)
		self.Text:SetTextColor(1, 1, 1, 1)
	end)

	return button
end

local function setActiveCategory(button)
	for _, btn in ipairs(categoryButtons) do
		btn:SetNormalAtlas('auctionhouse-nav-button')
		btn.Text:SetTextColor(0.6, 0.6, 0.6)
	end
	ActiveButton = button
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
	local button = createButton(parent, text, id)
	button.Text:SetTextColor(0.6, 0.6, 0.6)
	button:SetPoint(unpack(point))

	button:SetScript('OnClick', function(self)
		setActiveCategory(self)
	end)

	button:SetScript('OnEnter', function(self)
		self.Text:SetTextColor(1, 1, 1)
	end)

	button:SetScript('OnLeave', function(self)
		if button == ActiveButton then return end
		self.Text:SetTextColor(0.6, 0.6, 0.6)
	end)

	return button
end

local function filterErrors()
	local searchText = window.search:GetText():lower()
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
	window:SetFrameStrata('FULLSCREEN')
	window:SetFrameLevel(600)
	window:SetSize(850, 500)
	window:SetPoint('CENTER')
	window:SetMovable(true)
	window:SetResizable(true)
	window:EnableMouse(true)
	window:SetClampedToScreen(true)
	window:SetDontSavePosition(true)
	window.Buttons = {}

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

	local innerFrame = CreateFrame('Frame', nil, window)
	window.innerFrame = innerFrame
	innerFrame:SetPoint('TOPLEFT', 17, -95)
	innerFrame:SetPoint('BOTTOMRIGHT', -17, 50)

	-- Create category buttons
	local buttonNames = { L['All Errors'], L['Current Session'], L['Previous Session'] }
	for i, name in ipairs(buttonNames) do
		local point = { 'BOTTOMLEFT', innerFrame, 'TOPLEFT', 0 + (i - 1) * 125, 0 }
		local button = createCategoryButton(window, i, name, point)
		table.insert(categoryButtons, button)
	end

	-- Create ScrollFrame and ScrollChild
	local scrollFrame = CreateFrame('ScrollFrame', nil, innerFrame, 'UIPanelScrollFrameTemplate')
	scrollFrame:SetPoint('TOPLEFT', innerFrame, 'TOPLEFT', 4, -4)
	scrollFrame:SetPoint('BOTTOMRIGHT', innerFrame, 'BOTTOMRIGHT', -26, 4)

	innerFrame.bg = innerFrame:CreateTexture(nil, 'BACKGROUND')
	innerFrame.bg:SetAllPoints()
	innerFrame.bg:SetAtlas('weeklyrewards-background-reward-locked')
	innerFrame.bg:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	innerFrame.bg:SetVertexColor(0.6, 0.6, 0.6, 1)

	textArea = CreateFrame('EditBox', 'SUI_ErrorTextArea', scrollFrame)
	textArea:SetTextColor(0.5, 0.5, 0.5, 1)
	textArea:SetAutoFocus(false)
	textArea:SetMultiLine(true)
	textArea:SetFontObject(Game12Font)
	textArea:SetMaxLetters(99999)
	textArea:EnableMouse(true)
	textArea:SetScript('OnEscapePressed', textArea.ClearFocus)
	textArea:SetWidth(750)
	scrollFrame.textArea = textArea

	scrollFrame:SetScrollChild(textArea)
	window.scrollFrame = scrollFrame

	window.Buttons.Prev = createButton(window, L['< Previous'])
	-- window.Buttons.Prev:SetSize(100, 22)
	window.Buttons.Prev:SetPoint('BOTTOMLEFT', 16, 16)
	window.Buttons.Prev:SetScript('OnClick', function()
		if currentErrorIndex > 1 then
			currentErrorIndex = currentErrorIndex - 1
			updateDisplay()
		end
	end)

	window.Buttons.Next = createButton(window, L['Next >'])
	window.Buttons.Next:SetPoint('BOTTOMRIGHT', -16, 16)
	window.Buttons.Next:SetScript('OnClick', function()
		if currentErrorIndex < #currentErrorList then
			currentErrorIndex = currentErrorIndex + 1
			updateDisplay()
		end
	end)

	window.Buttons.CopyAll = createButton(window, L['Easy Copy All'])
	window.Buttons.CopyAll:SetPoint('BOTTOM', 0, 16)
	window.Buttons.CopyAll:SetScript('OnClick', function()
		local allErrors = ''
		for i, err in ipairs(currentErrorList) do
			allErrors = allErrors
				.. string.format('---------------------------------\n                  Error #%d\n---------------------------------\n\n%s\n\n', i, addon.ErrorHandler:FormatError(err))
		end
		textArea:SetText(allErrors)
		scrollFrame:UpdateScrollChildRect()
	end)

	local search = CreateFrame('EditBox', nil, window, 'SearchBoxTemplate')
	search:SetSize(200, 20)
	search:SetPoint('TOPRIGHT', -20, -70)
	search:SetAutoFocus(false)
	search:SetScript('OnEnterPressed', filterErrors)
	window.search = search

	local clearAllBtn = createButton(window, L['Clear all errors'])
	clearAllBtn:SetSize(120, 22)
	clearAllBtn:SetPoint('BOTTOMRIGHT', search, 'TOPRIGHT', 0, 5)
	clearAllBtn:SetScript('OnClick', function()
		addon.Reset()
	end)
	window.Buttons.ClearAll = clearAllBtn

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
		textArea:SetWidth(scrollFrame:GetWidth())
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

addon.BugWindow.Reset = function()
	-- Reset the UI
	currentErrorList = {}
	currentErrorIndex = nil
	updateDisplay(true)
end
