local StdUi = LibStub('StdUi'):NewInstance()
local IconName = 'SUIErrorIcon'
local addon = {}
local window
-- Frame state variables
local currentErrorIndex = nil -- Index of the error in the currentErrorList currently shown
local currentErrorList = nil -- List of all the errors currently navigated in the sack
local SessionID = nil -- Current session ID available in the sack
local currentErrorObject = nil
local BugGrabber = BugGrabber

-----------------------------------------------------------------------
-- Utility
--
local print = function(...)
	local tmp = {}
	local n = 1
	tmp[1] = '|cffffffffSpartan|cffe21f1fUI|r:'
	for i = 1, select('#', ...) do
		n = n + 1
		tmp[n] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage(table.concat(tmp, ' ', 1, n))
end

local msgsAllowedLastTime = GetTime()

local onError = function()
	-- If the frame is shown, we need to update it.
	-- if (addon.db.auto and not InCombatLockdown()) or (window and window:IsShown()) then
	if (not InCombatLockdown() and SUI and SUI.AutoOpenErrors) or (window and window:IsShown()) then
		addon:OpenErrWindow()
	elseif (SUI and not SUI.AutoOpenErrors) and (not InCombatLockdown()) then
	-- print('Error captured by error handler')
	end

	addon:updatemapIcon()
end

-----------------------------------------------------------------------
-- Event handling
--

local eventFrame = CreateFrame('Frame', nil, InterfaceOptionsFramePanelContainer)
eventFrame:SetScript(
	'OnEvent',
	function(self, event, loadedAddon)
		if loadedAddon ~= 'SpartanUI' then
			return
		end
		self:UnregisterEvent('ADDON_LOADED')

		local ac = LibStub('AceComm-3.0', true)
		if ac then
			ac:Embed(addon)
		end
		local as = LibStub('AceSerializer-3.0', true)
		if as then
			as:Embed(addon)
		end

		-- Make sure we grab any errors fired before we loaded.
		local session = addon:GetErrors(BugGrabber:GetSessionId())
		if #session > 0 then
			onError()
		end

		-- Set up our error event handler
		BugGrabber.RegisterCallback(addon, 'BugGrabber_BugGrabbed', onError)

		SlashCmdList.suierrors = function()
			addon:OpenErrWindow()
		end
		SLASH_suierrors1 = '/suierrors'

		ScriptErrorsFrame:Hide()
		ScriptErrorsFrame:HookScript(
			'OnShow',
			function()
				ScriptErrorsFrame:Hide()
			end
		)

		self:SetScript('OnEvent', nil)
	end
)
eventFrame:RegisterEvent('ADDON_LOADED')
addon.frame = eventFrame

-----------------------------------------------------------------------
-- API
--

local errors = {}
local errorFormat = '%dx %s'
local errorFormatLocals = '%dx %s\n\nLocals:\n%s'

function addon:UpdateDisplay()
	-- noop, hooked by displays
end

function addon:GetErrors(sessionId)
	if sessionId then
		wipe(errors)
		local db = BugGrabber:GetDB(sessionId)
		for _, e in next, db do
			if sessionId == e.session then
				errors[#errors + 1] = e
			end
		end
		return errors
	else
		return BugGrabber:GetDB()
	end
end

local function colorStack(ret)
	ret = tostring(ret) or '' -- Yes, it gets called with nonstring from somewhere /mikk
	ret = ret:gsub('[%.I][%.n][%.t][%.e][%.r]face\\', '')
	ret = ret:gsub('%.?%.?%.?\\?AddOns\\', '')
	ret = ret:gsub('|([^chHr])', '||%1'):gsub('|$', '||') -- Pipes
	ret = ret:gsub('<(.-)>', '|cffffea00<%1>|r') -- Things wrapped in <>
	ret = ret:gsub('%[(.-)%]', '|cffffea00[%1]|r') -- Things wrapped in []
	ret = ret:gsub("([\"`'])(.-)([\"`'])", '|cff8888ff%1%2%3|r') -- Quotes
	ret = ret:gsub(':(%d+)([%S\n])', ':|cff00ff00%1|r%2') -- Line numbers
	ret = ret:gsub('([^\\]+%.lua)', '|cffffffff%1|r') -- Lua files
	return ret
end

local function colorLocals(ret)
	ret = tostring(ret) or '' -- Yes, it gets called with nonstring from somewhere /mikk
	ret = ret:gsub('[%.I][%.n][%.t][%.e][%.r]face\\', '')
	ret = ret:gsub('%.?%.?%.?\\?AddOns\\', '')
	ret = ret:gsub('|(%a)', '||%1'):gsub('|$', '||') -- Pipes
	ret = ret:gsub('> %@(.-):(%d+)', '> @|cffeda55f%1|r:|cff00ff00%2|r') -- Files/Line Numbers of locals
	ret = ret:gsub('(%s-)([%a_%(][%a_%d%*%)]+) = ', '%1|cffffff80%2|r = ') -- Table keys
	ret = ret:gsub('= (%-?[%d%p]+)\n', '= |cffff7fff%1|r\n') -- locals: number
	ret = ret:gsub('= nil\n', '= |cffff7f7fnil|r\n') -- locals: nil
	ret = ret:gsub('= true\n', '= |cffff9100true|r\n') -- locals: true
	ret = ret:gsub('= false\n', '= |cffff9100false|r\n') -- locals: false
	ret = ret:gsub('= <(.-)>', '= |cffffea00<%1>|r') -- Things wrapped in <>
	return ret
end

function addon:FormatError(err)
	if not err.locals then
		local s = colorStack(tostring(err.message) .. (err.stack and '\n' .. tostring(err.stack) or ''))
		local l = colorLocals(tostring(err.locals))
		return errorFormat:format(err.counter or -1, s, l)
	else
		local s = colorStack(tostring(err.message) .. (err.stack and '\n' .. tostring(err.stack) or ''))
		local l = colorLocals(tostring(err.locals))
		return errorFormatLocals:format(err.counter or -1, s, l)
	end
end

-- Updates the total bug count and so forth.
local function updateDisplay(forceRefresh)
	if not window then
		addon:updatemapIcon()
		return
	end

	if forceRefresh then
		currentErrorObject = nil
		currentErrorIndex = nil
	else
		currentErrorObject = currentErrorList and currentErrorList[currentErrorIndex]
	end

	SessionID = BugGrabber:GetSessionId()
	currentErrorList = addon:GetErrors(SessionID)

	local size = #currentErrorList
	local ErrObj = nil

	if forceRefresh then
		-- Reset currently shown error to the highest index
		ErrObj = currentErrorList[size]
		currentErrorIndex = size
	else
		-- Update currentErrorIndex index to the new error list
		for i, v in next, currentErrorList do
			if v == currentErrorObject then
				currentErrorIndex = i
				ErrObj = v
				break
			end
		end
	end
	if not ErrObj then
		ErrObj = currentErrorList[currentErrorIndex] or currentErrorList[size]
	end

	if SessionID == -1 and ErrObj then
		SessionID = ErrObj.session
	end

	if size > 0 then
		window.countLabel:SetText(('%d/%d'):format(currentErrorIndex, size))
		window.editBox:SetText(addon:FormatError(ErrObj))

		window.editBox.scrollFrame.scrollBar:SetValue(0)

		-- if ErrObj.session == BugGrabber:GetSessionId() then
		-- 	window.sessionLabel:SetText(('%s - |cff44ff44%d|r'):format('Today', ErrObj.session))
		-- else
		window.sessionLabel:SetText(('%s - |cff44ff44%d|r'):format(ErrObj.time, ErrObj.session))
		-- end

		if currentErrorIndex >= size then
			window.nextButton:Disable()
		else
			window.nextButton:Enable()
		end
		if currentErrorIndex <= 1 then
			window.prevButton:Disable()
		else
			window.prevButton:Enable()
		end
	else
		window.countLabel:SetText()
		window.sessionLabel:SetText(('%d'):format(SessionID))
		window.editBox:SetText('There are no bugs\n\nWhy are you looking at this?\n\nGo play the game or something.')
		window.nextButton:Disable()
		window.prevButton:Disable()
	end

	addon:updatemapIcon()
end

function addon:Reset()
	BugGrabber:Reset()
	updateDisplay()

	print('All stored bugs have been wiped.')
end

hooksecurefunc(
	addon,
	'UpdateDisplay',
	function()
		if not window or not window:IsShown() then
			return
		end
		-- can't just hook it right in because it would pass |self| as forceRefresh
		updateDisplay(true)
	end
)

local createBugWindow = function()
	-- Create window
	window = StdUi:Window(nil, 510, 400)
	window:SetPoint('CENTER', 0, 0)
	window:SetFrameStrata('DIALOG')

	window.Title = StdUi:Texture(window, 156, 45, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	window.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	window.Title:SetPoint('TOP')
	window.Title:SetAlpha(.8)

	-- Create window Items
	window.editBox = StdUi:MultiLineBox(window, 480, 320, '')

	window.SubTitle = StdUi:Label(window, 'Error handler', 10, nil, 100, 15)
	window.SubTitle:SetPoint('BOTTOM', window.Title, 'BOTTOMRIGHT', 0, -1)

	window.sessionLabel = StdUi:Label(window, '', 10, nil, 180, 20)

	window.countLabel = StdUi:Label(window, '', 12, nil, 80, 20)
	window.countLabel:SetJustifyH('CENTER')

	window.nextButton = StdUi:Button(window, 20, 20, '>')
	window.prevButton = StdUi:Button(window, 20, 20, '<')

	window.btnClose = StdUi:Button(window, 120, 20, 'CLOSE')
	window.AutoOpen = StdUi:Checkbox(window, 'Auto open on error', 200, 20)
	if SUI.AutoOpenErrors then
		window.AutoOpen:SetChecked(true)
	end

	-- Position
	window.editBox:SetPoint('TOP', window, 'TOP', 0, -50)
	window.btnClose:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -4, 4)
	window.AutoOpen:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', 4, 4)

	window.sessionLabel:SetPoint('TOPLEFT', window, 'TOPLEFT', 5, -5)
	window.countLabel:SetPoint('BOTTOM', window, 'BOTTOM', 0, 4)
	window.nextButton:SetPoint('LEFT', window.countLabel, 'RIGHT', 5, 0)
	window.prevButton:SetPoint('RIGHT', window.countLabel, 'LEFT', -5, 0)

	--Button Actions
	window.AutoOpen:HookScript(
		'OnClick',
		function()
			SUI.DBG.ErrorHandler.AutoOpenErrors = window.AutoOpen:GetValue()
			SUI.AutoOpenErrors = (SUI.DBG.ErrorHandler.AutoOpenErrors or false)
		end
	)
	window.prevButton:SetScript(
		'OnClick',
		function()
			currentErrorIndex = currentErrorIndex - 1
			updateDisplay()
		end
	)

	window.nextButton:SetScript(
		'OnClick',
		function()
			currentErrorIndex = currentErrorIndex + 1
			updateDisplay()
		end
	)

	window.btnClose:SetScript(
		'OnClick',
		function()
			window:Hide()
		end
	)

	window:Hide()

	window.font = window:CreateFontString(nil, nil, 'GameFontNormal')
	window.font:Hide()
	window:HookScript(
		'OnShow',
		function()
			window.editBox.scrollFrame:SetVerticalScroll((window.editBox.scrollFrame:GetVerticalScrollRange()) or 0)
		end
	)
end

function addon:OpenErrWindow()
	if window and window:IsShown() then
		updateDisplay()
		return
	end

	if window == nil then
		createBugWindow()
	end
	updateDisplay(true)
	window:Show()
end

local icon = LibStub('LibDBIcon-1.0', true)
local ldb = LibStub:GetLibrary('LibDataBroker-1.1', true)
if not icon or not ldb then
	return
end

local MapIcon =
	ldb:NewDataObject(
	IconName,
	{
		type = 'data source',
		text = '0',
		icon = 'Interface\\AddOns\\SpartanUI\\images\\Spartan-Helm',
		OnClick = function()
			if IsAltKeyDown() then
				addon:Reset()
			else
				addon:OpenErrWindow()
			end
		end,
		OnTooltipShow = function(tt)
			local hint =
				'|cffeda55fClick|r to open bug window with the last bug. |cffeda55fAlt-Click|r to clear all saved errors.'
			local line = '%d. %s (x%d)'
			local errs = addon:GetErrors(BugGrabber:GetSessionId())
			if #errs == 0 then
				tt:AddLine('You have no bugs, yay!')
			else
				tt:AddLine('SpartanUI error handler')
				for i, err in next, errs do
					tt:AddLine(line:format(i, colorStack(err.message), err.counter), .5, .5, .5)
					if i > 8 then
						break
					end
				end
			end
			tt:AddLine(' ')
			tt:AddLine(hint, 0.2, 1, 0.2, 1)
		end
	}
)

-- function MapIcon.UpdateCoord()
-- end

function addon:updatemapIcon()
	if icon:GetMinimapButton(name) then
		icon:Refresh(IconName)
	end

	local count = #addon:GetErrors(BugGrabber:GetSessionId())
	if count ~= 0 then
		icon:Show(IconName)
	else
		icon:Hide(IconName)
	end
end

_G.SUIErrorDisplay = addon

local f = CreateFrame('Frame')
f:SetScript(
	'OnEvent',
	function()
		if not SUIErrorHandler then
			SUIErrorHandler = {}
		end
		icon:Register(IconName, MapIcon, SUIErrorHandler)
		if #addon:GetErrors(BugGrabber:GetSessionId()) == 0 then
			icon:Hide(IconName)
		end
	end
)
f:RegisterEvent('PLAYER_LOGIN')
