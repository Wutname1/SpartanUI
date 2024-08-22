local addonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)

addon.ErrorHandler = {}

local errorDB = {}
local sessionList = {}
local MAX_ERRORS = 1000
local currentSession = nil

local function colorStack(ret)
	ret = tostring(ret) or ''
	ret = ret:gsub('[%.I][%.n][%.t][%.e][%.r]face\\', '')
	ret = ret:gsub('%.?%.?%.?\\?AddOns\\', '')
	ret = ret:gsub('|([^chHr])', '||%1'):gsub('|$', '||') -- Pipes
	ret = ret:gsub('<(.-)>', '|cffffea00<%1>|r') -- Things wrapped in <>
	ret = ret:gsub('%[(.-)%]', '|cffffea00[%1]|r') -- Things wrapped in []
	ret = ret:gsub('(["\'`])(.-)(["\'`])', '|cff8888ff%1%2%3|r') -- Quotes
	ret = ret:gsub(':(%d+)([%S\n])', ':|cff00ff00%1|r%2') -- Line numbers
	ret = ret:gsub('([^\\]+%.lua)', '|cffffffff%1|r') -- Lua files
	return ret
end

local function colorLocals(ret)
	ret = tostring(ret) or ''
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

function addon.ErrorHandler:Initialize()
	if not BugGrabber then
		print(L['BugGrabber is required for SpartanUI error handling.'])
		return
	end

	currentSession = BugGrabber:GetSessionId()
	table.insert(sessionList, currentSession)

	-- Register with BugGrabber
	BugGrabber.RegisterCallback(self, 'BugGrabber_BugGrabbed', 'OnBugGrabbed')

	-- Grab any errors that occurred before we loaded
	local existingErrors = BugGrabber:GetDB()
	for _, err in ipairs(existingErrors) do
		self:ProcessError(err)
	end
end

function addon.ErrorHandler:OnBugGrabbed(callback, errorObject)
	self:ProcessError(errorObject)
end

function addon.ErrorHandler:ProcessError(errorObject)
	local err = {
		message = errorObject.message,
		stack = errorObject.stack,
		locals = errorObject.locals,
		time = errorObject.time,
		session = errorObject.session,
		counter = 1,
	}

	-- Check for duplicate errors
	for i = #errorDB, 1, -1 do
		local oldErr = errorDB[i]
		if oldErr.message == err.message and oldErr.stack == err.stack then
			oldErr.counter = (oldErr.counter or 1) + 1
			return
		end
	end

	-- Add new error
	table.insert(errorDB, err)

	-- Trim old errors if necessary
	if #errorDB > MAX_ERRORS then table.remove(errorDB, 1) end

	-- Trigger the onError function from the main addon file
	if addon.onError then addon.onError() end
end

function addon.ErrorHandler:CaptureError(errorObject)
	local err = {
		message = errorObject.message,
		stack = errorObject.stack,
		locals = errorObject.locals,
		time = errorObject.time,
		session = currentSession,
		counter = 1,
	}

	-- Check for duplicate errors
	for i = #errorDB, 1, -1 do
		local oldErr = errorDB[i]
		if oldErr.message == err.message and oldErr.stack == err.stack then
			oldErr.counter = (oldErr.counter or 1) + 1
			return
		end
	end

	-- Add new error
	table.insert(errorDB, err)

	-- Trim old errors if necessary
	if #errorDB > MAX_ERRORS then table.remove(errorDB, 1) end

	-- Auto popup if enabled
	if addon.Config:Get('autoPopup') then addon.BugWindow:OpenErrorWindow() end

	-- Print to chat if enabled
	if addon.Config:Get('chatframe') then print('|cffff4411' .. L['SpartanUI Error'] .. ':|r ' .. L['New error captured. Type /suierrors to view.']) end
end

function addon.ErrorHandler:GetErrors(sessionId)
	if not sessionId then return errorDB end
	local sessionErrors = {}
	for _, err in ipairs(errorDB) do
		if err.session == sessionId then table.insert(sessionErrors, err) end
	end
	return sessionErrors
end

function addon.ErrorHandler:GetCurrentSession()
	return currentSession
end

function addon.ErrorHandler:GetSessionList()
	return sessionList
end

function addon.ErrorHandler:FormatError(err)
	local s = colorStack(tostring(err.message) .. (err.stack and '\n' .. tostring(err.stack) or ''))
	local l = colorLocals(tostring(err.locals))
	return string.format('%dx %s\n\nLocals:\n%s', err.counter or 1, s, l)
end

function addon.ErrorHandler:Reset()
	wipe(errorDB)
	wipe(sessionList)
	self:Initialize()
	print(L['All stored errors have been wiped.'])
end

return addon.ErrorHandler
