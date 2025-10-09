---@class LibATErrorDisplay
local ErrorDisplay = _G.LibATErrorDisplay

-- Localization
local L = {
	['Session: %d'] = 'Session: %d',
	['No errors'] = 'No errors',
	['You have no errors, yay!'] = 'You have no errors, yay!',
	['All Sessions'] = 'All Sessions',
	['Current Session'] = 'Current Session',
	['Previous Session'] = 'Previous Session',
	['Ignored Errors'] = 'Ignored Errors',
	['< Previous'] = '< Previous',
	['Next >'] = 'Next >',
	['Easy Copy All'] = 'Easy Copy All',
	['Clear all errors'] = 'Clear all errors',
	['Clear Ignored'] = 'Clear Ignored',
	['Ignore'] = 'Ignore',
	['Unignore'] = 'Unignore'
}

ErrorDisplay.BugWindow = {}

local window, currentErrorIndex, currentErrorList, currentSession
local countLabel, sessionLabel, textArea
local ActiveButton = nil
local categoryButtons = {}
local setActiveCategory  -- Forward declaration
ErrorDisplay.BugWindow.window = window

-- Initialize currentErrorList as empty table
currentErrorList = {}

local function updateDisplay(forceRefresh)
	if not window then
		ErrorDisplay.BugWindow.Create()
	end

	-- Ensure currentErrorList is a table
	if not currentErrorList then
		currentErrorList = {}
	end

	if forceRefresh or not currentErrorIndex then
		currentErrorIndex = #currentErrorList
	end

	-- Make sure currentErrorIndex doesn't exceed the list length
	if currentErrorIndex > #currentErrorList then
		currentErrorIndex = #currentErrorList
	end

	-- Update Ignored Errors tab visibility
	local ignoredErrors = ErrorDisplay.ErrorHandler:GetIgnoredErrors()
	if categoryButtons[4] then
		if #ignoredErrors > 0 then
			categoryButtons[4]:Show()
		else
			categoryButtons[4]:Hide()
			-- If we're on the ignored errors tab and there are none, switch to current session
			if ActiveButton and ActiveButton:GetID() == 4 then
				setActiveCategory(categoryButtons[2])
				return
			end
		end
	end

	-- Get the current error to display
	local err = nil
	if #currentErrorList > 0 and currentErrorIndex > 0 then
		err = currentErrorList[currentErrorIndex]
	end

	if err then
		countLabel:SetText(string.format('%d/%d', currentErrorIndex, #currentErrorList))
		sessionLabel:SetText(string.format(L['Session: %d'], err.session))
		textArea:SetText(ErrorDisplay.ErrorHandler:FormatError(err))

		window.Buttons.Next:SetEnabled(currentErrorIndex < #currentErrorList)
		window.Buttons.Prev:SetEnabled(currentErrorIndex > 1)
		window.Buttons.CopyAll:SetEnabled(#currentErrorList > 1)
		window.Buttons.Ignore:SetEnabled(true)
		window.Buttons.ClearAll:SetEnabled(true)
	else
		-- No errors to display - clear everything
		countLabel:SetText('0/0')
		sessionLabel:SetText(L['No errors'])
		textArea:SetText(L['You have no errors, yay!'])

		window.Buttons.Next:SetEnabled(false)
		window.Buttons.Prev:SetEnabled(false)
		window.Buttons.CopyAll:SetEnabled(false)
		window.Buttons.Ignore:SetEnabled(false)
		window.Buttons.ClearAll:SetEnabled(false)
	end
end

---Create a button with the Error Display's signature texture stretching technique
---@param parent table|Frame
---@param text string
---@param id? number
---@return table|Button
local function createButton(parent, text, id)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(120, 25)
	if id then
		button:SetID(id)
	end

	-- The signature texture stretching technique that creates tab appearance
	button:SetNormalAtlas('auctionhouse-nav-button')
	button:SetHighlightAtlas('auctionhouse-nav-button-highlight')
	button:SetPushedAtlas('auctionhouse-nav-button-select')
	button:SetDisabledAtlas('UI-CastingBar-TextBox')

	-- This is the key technique: texture coordinate manipulation for tab effect
	local normalTexture = button:GetNormalTexture()
	normalTexture:SetTexCoord(0, 1, 0, 0.7) -- Crops bottom 30% to create tab appearance

	button.Text = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	button.Text:SetPoint('CENTER')
	button.Text:SetText(text)
	button.Text:SetTextColor(1, 1, 1, 1)

	button:HookScript(
		'OnDisable',
		function(self)
			self.Text:SetTextColor(0.6, 0.6, 0.6, 0.6)
		end
	)

	button:HookScript(
		'OnEnable',
		function(self)
			self.Text:SetTextColor(1, 1, 1, 1)
		end
	)

	return button
end

setActiveCategory = function(button)
	for _, btn in ipairs(categoryButtons) do
		btn:SetNormalAtlas('auctionhouse-nav-button')
		btn.Text:SetTextColor(0.6, 0.6, 0.6)
	end
	ActiveButton = button
	button:SetNormalAtlas('auctionhouse-nav-button-secondary-select')
	button.Text:SetTextColor(1, 1, 1)

	-- Always get a fresh error list for the selected category
	if button:GetID() == 1 then
		-- All Sessions - get all errors from all sessions
		currentErrorList = ErrorDisplay.ErrorHandler:GetAllErrorsFromAllSessions() or {}
	elseif button:GetID() == 2 then
		-- Current Session
		currentErrorList = ErrorDisplay.ErrorHandler:GetErrors(ErrorDisplay.ErrorHandler:GetCurrentSession()) or {}
	elseif button:GetID() == 3 then
		-- Previous Session
		local sessionList = ErrorDisplay.ErrorHandler:GetSessionList()
		local prevSession = sessionList[#sessionList - 1]
		-- Only get errors if previous session exists
		if prevSession then
			currentErrorList = ErrorDisplay.ErrorHandler:GetErrors(prevSession) or {}
		else
			-- No previous session, use empty list
			currentErrorList = {}
		end
	elseif button:GetID() == 4 then
		-- Ignored Errors
		currentErrorList = ErrorDisplay.ErrorHandler:GetIgnoredErrors() or {}
	end

	-- Update button text based on active tab
	if button:GetID() == 4 then
		-- On Ignored Errors tab
		window.Buttons.Ignore.Text:SetText(L['Unignore'])
		window.Buttons.ClearAll.Text:SetText(L['Clear Ignored'])
	else
		-- On other tabs
		window.Buttons.Ignore.Text:SetText(L['Ignore'])
		window.Buttons.ClearAll.Text:SetText(L['Clear all errors'])
	end

	updateDisplay(true)
end

local function createCategoryButton(parent, id, text, point)
	local button = createButton(parent, text, id)
	button.Text:SetTextColor(0.6, 0.6, 0.6)
	button:SetPoint(unpack(point))

	button:SetScript(
		'OnClick',
		function(self)
			setActiveCategory(self)
		end
	)

	button:SetScript(
		'OnEnter',
		function(self)
			self.Text:SetTextColor(1, 1, 1)
		end
	)

	button:SetScript(
		'OnLeave',
		function(self)
			if button == ActiveButton then
				return
			end
			self.Text:SetTextColor(0.6, 0.6, 0.6)
		end
	)

	return button
end

function ErrorDisplay.BugWindow.Create()
	window = CreateFrame('Frame', 'LibATErrorWindow', UIParent, 'ButtonFrameTemplate')
	local sessionNum = ErrorDisplay.ErrorHandler:GetCurrentSession()
	if SUI then
		window:SetTitle(string.format('|cffffffffSpartan|cffe21f1fUI|r Error Display - Session #%d', sessionNum))
	else
		window:SetTitle(string.format("|cffffffffLib's|r Error Display - Session #%d", sessionNum))
	end
	window.Inset:Hide()
	ButtonFrameTemplate_HidePortrait(window)
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
	window:SetScript(
		'OnMouseDown',
		function(self, button)
			if button == 'LeftButton' then
				self:StartMoving()
			end
		end
	)
	window:SetScript(
		'OnMouseUp',
		function(self, button)
			self:StopMovingOrSizing()
		end
	)

	countLabel = window:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	countLabel:SetPoint('TOPRIGHT', -35, 0)

	sessionLabel = window:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	sessionLabel:SetPoint('TOPLEFT', 5, -2)

	local innerFrame = CreateFrame('Frame', nil, window)
	window.innerFrame = innerFrame
	innerFrame:SetPoint('TOPLEFT', 15, -65)
	innerFrame:SetPoint('BOTTOMRIGHT', -25, 45)

	-- Create category buttons using the tab technique
	local buttonNames = {L['All Sessions'], L['Current Session'], L['Previous Session']}
	for i, name in ipairs(buttonNames) do
		local point = {'BOTTOMLEFT', innerFrame, 'TOPLEFT', 0 + (i - 1) * 120, 0}
		local button = createCategoryButton(window, i, name, point)
		table.insert(categoryButtons, button)
	end

	-- Create Ignored Errors tab (ID 4) - will be shown/hidden dynamically
	local ignoredButton = createCategoryButton(window, 4, L['Ignored Errors'], {'BOTTOMLEFT', innerFrame, 'TOPLEFT', 360, 0})
	table.insert(categoryButtons, ignoredButton)
	ignoredButton:Hide() -- Hidden by default

	-- Create ScrollFrame and ScrollChild
	local scrollFrame = CreateFrame('ScrollFrame', nil, innerFrame)
	scrollFrame:SetPoint('TOPLEFT', innerFrame, 'TOPLEFT')
	scrollFrame:SetPoint('BOTTOMRIGHT', innerFrame, 'BOTTOMRIGHT', -20)

	scrollFrame.bg = scrollFrame:CreateTexture(nil, 'BACKGROUND')
	scrollFrame.bg:SetAllPoints()
	scrollFrame.bg:SetAtlas('auctionhouse-background-index', true)

	scrollFrame.ScrollBar = CreateFrame('EventFrame', nil, scrollFrame, 'MinimalScrollBar')
	scrollFrame.ScrollBar:SetPoint('TOPLEFT', scrollFrame, 'TOPRIGHT', 6, 0)
	scrollFrame.ScrollBar:SetPoint('BOTTOMLEFT', scrollFrame, 'BOTTOMRIGHT', 6, 0)
	ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollFrame.ScrollBar)

	textArea = CreateFrame('EditBox', 'LibAT_ErrorTextArea', scrollFrame)
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

	-- Navigation buttons
	window.Buttons.Prev = createButton(window, L['< Previous'])
	window.Buttons.Prev:SetPoint('TOPLEFT', innerFrame, 'BOTTOMLEFT', 0, -7)
	window.Buttons.Prev:SetScript(
		'OnClick',
		function()
			if currentErrorIndex > 1 then
				currentErrorIndex = currentErrorIndex - 1
				updateDisplay()
			end
		end
	)

	window.Buttons.Next = createButton(window, L['Next >'])
	window.Buttons.Next:SetPoint('TOPRIGHT', innerFrame, 'BOTTOMRIGHT', 0, -7)
	window.Buttons.Next:SetScript(
		'OnClick',
		function()
			if currentErrorIndex < #currentErrorList then
				currentErrorIndex = currentErrorIndex + 1
				updateDisplay()
			end
		end
	)

	window.Buttons.CopyAll = createButton(window, L['Easy Copy All'])
	window.Buttons.CopyAll:SetPoint('TOP', innerFrame, 'BOTTOM', 0, -7)
	window.Buttons.CopyAll:SetScript(
		'OnClick',
		function()
			local allErrors = ''
			for i, err in ipairs(currentErrorList) do
				allErrors = allErrors .. string.format('---------------------------------\n                  Error #%d\n---------------------------------\n\n%s\n\n', i, ErrorDisplay.ErrorHandler:FormatError(err))
			end
			textArea:SetText(allErrors)
			scrollFrame:UpdateScrollChildRect()
		end
	)

	-- Clear button
	local clearAllBtn = createButton(window, L['Clear all errors'])
	clearAllBtn:SetSize(120, 22)
	clearAllBtn:SetPoint('BOTTOMRIGHT', innerFrame, 'TOPRIGHT', -2, 5)
	clearAllBtn:SetScript(
		'OnClick',
		function()
			if ActiveButton and ActiveButton:GetID() == 4 then
				-- On Ignored Errors tab - clear ignored list
				ErrorDisplay.ErrorHandler:ClearIgnoredErrors()
				print('|cffffffffLibAT|r: All ignored errors have been cleared.')
				-- Refresh display
				setActiveCategory(ActiveButton)
			else
				-- On other tabs - clear all errors
				ErrorDisplay.Reset()
			end
		end
	)
	window.Buttons.ClearAll = clearAllBtn

	-- Ignore button
	local ignoreBtn = createButton(window, L['Ignore'])
	ignoreBtn:SetSize(120, 22)
	ignoreBtn:SetPoint('BOTTOMRIGHT', clearAllBtn, 'BOTTOMLEFT', -5, 0)
	ignoreBtn:SetScript(
		'OnClick',
		function()
			-- Get the current error being displayed
			if currentErrorList and currentErrorIndex and currentErrorIndex > 0 and currentErrorIndex <= #currentErrorList then
				local err = currentErrorList[currentErrorIndex]
				if err then
					if ActiveButton and ActiveButton:GetID() == 4 then
						-- On Ignored Errors tab - unignore this error
						if ErrorDisplay.ErrorHandler:UnignoreError(err) then
							-- Remove from current list
							table.remove(currentErrorList, currentErrorIndex)

							-- Adjust index if needed
							if currentErrorIndex > #currentErrorList then
								currentErrorIndex = #currentErrorList
							end

							-- Refresh display
							updateDisplay(true)

							-- Show confirmation message
							print('|cffffffffLibAT|r: Error unignored. This error will now be shown.')
						end
					else
						-- On other tabs - ignore this error
						if ErrorDisplay.ErrorHandler:IgnoreError(err) then
							-- Remove from current list
							table.remove(currentErrorList, currentErrorIndex)

							-- Adjust index if needed
							if currentErrorIndex > #currentErrorList then
								currentErrorIndex = #currentErrorList
							end

							-- Refresh display
							updateDisplay(true)

							-- Show confirmation message
							print('|cffffffffLibAT|r: Error ignored. This error will no longer be shown.')
						end
					end
				end
			end
		end
	)
	window.Buttons.Ignore = ignoreBtn

	window.currentErrorList = currentErrorList
	window:Hide()

	-- Set Current Session (button 2) as the default active tab
	setActiveCategory(categoryButtons[2])
end

function ErrorDisplay.BugWindow:OpenErrorWindow()
	if not window then
		ErrorDisplay.BugWindow.Create()
	end

	if not window:IsShown() then
		-- Start with current session errors by default (button ID 2)
		setActiveCategory(categoryButtons[2])
		window:Show()
	else
		-- Refresh the current tab's error list
		if ActiveButton then
			setActiveCategory(ActiveButton)
		end
	end
end

function ErrorDisplay.BugWindow:CloseErrorWindow()
	if window then
		window:Hide()
	end
end

function ErrorDisplay.BugWindow:IsShown()
	return window and window:IsShown()
end

ErrorDisplay.BugWindow.Reset = function()
	currentErrorList = {}
	currentErrorIndex = nil
	updateDisplay(true)
end

-- Expose the updateDisplay function for external use
ErrorDisplay.BugWindow.updateDisplay = updateDisplay

return ErrorDisplay.BugWindow
