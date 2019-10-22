local StdUi = LibStub('StdUi'):NewInstance()
local addon = {}
local window

-- What state is the sack in?
local state = 'BugSackTabAll'

-- Frame state variables
local currentErrorIndex = nil -- Index of the error in the currentSackContents currently shown
local currentSackContents = nil -- List of all the errors currently navigated in the sack
local currentSackSession = nil -- Current session ID available in the sack
local currentErrorObject = nil

local tabs = nil

local countLabel, sessionLabel, textArea = nil, nil, nil
local nextButton, prevButton, sendButton = nil, nil, nil

local countFormat = '%d/%d'

-----------------------------------------------------------------------
-- Utility
--

local onError
do
	function onError()
		-- If the frame is shown, we need to update it.
		if (addon.db.auto and not InCombatLockdown()) or (BugSackFrame and BugSackFrame:IsShown()) then
			addon:OpenSack()
		end
	end
end

-----------------------------------------------------------------------
-- Event handling
--

do
	local eventFrame = CreateFrame('Frame', nil, InterfaceOptionsFramePanelContainer)
	eventFrame:SetScript(
		'OnEvent',
		function(self, event, loadedAddon)
			if loadedAddon ~= addonName then
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

			if type(SUI) == 'table' then
				if SUI and SUI.DBG then
				end
			end

			-- local sv = BugSackDB
			-- sv.profileKeys = nil
			-- sv.profiles = nil
			-- if type(sv.mute) ~= 'boolean' then
			-- 	sv.mute = false
			-- end
			-- if type(sv.auto) ~= 'boolean' then
			-- 	sv.auto = false
			-- end
			-- if type(sv.chatframe) ~= 'boolean' then
			-- 	sv.chatframe = false
			-- end
			-- if type(sv.soundMedia) ~= 'string' then
			-- 	sv.soundMedia = 'BugSack: Fatality'
			-- end
			-- if type(sv.fontSize) ~= 'string' then
			-- 	sv.fontSize = 'GameFontHighlight'
			-- end
			-- addon.db = sv

			-- Make sure we grab any errors fired before bugsack loaded.
			local session = addon:GetErrors(BugGrabber:GetSessionId())
			if #session > 0 then
				onError()
			end

			-- Set up our error event handler
			BugGrabber.RegisterCallback(addon, 'BugGrabber_BugGrabbed', onError)

			SlashCmdList.BugSack = function(msg)
				msg = msg:lower()
				if msg == 'show' then
					addon:OpenSack()
				else
					InterfaceOptionsFrame_OpenToCategory(addonName)
					InterfaceOptionsFrame_OpenToCategory(addonName)
				end
			end
			SLASH_BugSack1 = '/bugsack'

			self:SetScript('OnEvent', nil)
		end
	)
	eventFrame:RegisterEvent('ADDON_LOADED')
	addon.frame = eventFrame
end

-----------------------------------------------------------------------
-- API
--

function addon:UpdateDisplay()
	-- noop, hooked by displays
end

do
	local errors = {}
	function addon:GetErrors(sessionId)
		-- XXX I've never liked this function, maybe a BugGrabber redesign is in order,
		-- XXX where we have one subtable in the DB per session ID.
		if sessionId then
			wipe(errors)
			local db = BugGrabber:GetDB()
			for i, e in next, db do
				if sessionId == e.session then
					errors[#errors + 1] = e
				end
			end
			return errors
		else
			return BugGrabber:GetDB()
		end
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

local errorFormat = '%dx %s'
local errorFormatLocals = '%dx %s\n\nLocals:\n%s'

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

do
	addon.ColorStack = colorStack
	addon.ColorLocals = colorLocals
end
-- Updates the total bug count and so forth.
local lastState = nil
local function updateSackDisplay(forceRefresh)
	if state ~= lastState then
		forceRefresh = true
	end
	lastState = state

	if forceRefresh then
		currentErrorObject = nil
		currentErrorIndex = nil
	else
		currentErrorObject = currentSackContents and currentSackContents[currentErrorIndex]
	end

	if state == 'BugSackTabAll' then
		currentSackContents = addon:GetErrors()
		currentSackSession = BugGrabber:GetSessionId()
	elseif state == 'BugSackTabSession' then
		local s = BugGrabber:GetSessionId()
		currentSackContents = addon:GetErrors(s)
		currentSackSession = s
	elseif state == 'BugSackTabLast' then
		local s = BugGrabber:GetSessionId() - 1
		currentSackContents = addon:GetErrors(s)
		currentSackSession = s
	end

	local size = #currentSackContents
	local eo = nil

	if forceRefresh then
		-- We need to reset the currently shown error to the highest index
		eo = currentSackContents[size]
		currentErrorIndex = size
	else
		-- we need to adapt the currentErrorIndex index to the new error list
		for i, v in next, currentSackContents do
			if v == currentErrorObject then
				currentErrorIndex = i
				eo = v
				break
			end
		end
	end
	if not eo then
		eo = currentSackContents[currentErrorIndex]
	end
	if not eo then
		eo = currentSackContents[size]
	end
	if currentSackSession == -1 and eo then
		currentSackSession = eo.session
	end

	if size > 0 then
		countLabel:SetText(countFormat:format(currentErrorIndex, size))
		textArea:SetText(addon:FormatError(eo))

		if currentErrorIndex >= size then
			nextButton:Disable()
		else
			nextButton:Enable()
		end
		if currentErrorIndex <= 1 then
			prevButton:Disable()
		else
			prevButton:Enable()
		end
		if sendButton then
			sendButton:Enable()
		end
	else
		countLabel:SetText()
		if currentSackSession == BugGrabber:GetSessionId() then
			sessionLabel:SetText(('%s (%d)'):format(L['Today'], BugGrabber:GetSessionId()))
		else
			sessionLabel:SetText(('%d'):format(currentSackSession))
		end
		textArea:SetText(L['You have no bugs, yay!'])
		nextButton:Disable()
		prevButton:Disable()
		if sendButton then
			sendButton:Disable()
		end
	end

	for i, t in next, tabs do
		if state == t:GetName() then
			PanelTemplates_SelectTab(t)
		else
			PanelTemplates_DeselectTab(t)
		end
	end
end
hooksecurefunc(
	addon,
	'UpdateDisplay',
	function()
		if not window or not window:IsShown() then
			return
		end
		-- can't just hook it right in because it would pass |self| as forceRefresh
		updateSackDisplay(true)
	end
)

local createBugWindow = function()
	-- Create window
	window = StdUi:Window(nil, 480, 200)
	window:SetPoint('CENTER', 0, 0)
	window:SetFrameStrata('DIALOG')

	window.Title = StdUi:Texture(window, 156, 45, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	window.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	window.Title:SetPoint('TOP')
	window.Title:SetAlpha(.8)

	-- Create window Items
	window.editBox = StdUi:MultiLineBox(window, 450, 120, '')
	window.btnClose = StdUi:Button(window, 150, 20, 'CLOSE')

	-- Position
	StdUi:GlueTop(window.editBox.panel, window, 0, -50)
	window.btnClose:SetPoint('BOTTOM', window, 'BOTTOM', 0, 4)

	-- Actions
	window.btnClose:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Next action
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

function addon:Reset()
	BugGrabber:Reset()
	print(L['All stored bugs have been exterminated painfully.'])
end

function addon:OpenSack()
	if window and window:IsShown() then
		return
	end

	if window == nil then
		createBugWindow()
	end
	updateSackDisplay(true)
	window:Show()
end
