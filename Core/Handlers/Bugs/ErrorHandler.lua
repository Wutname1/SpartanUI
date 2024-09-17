---@class Lib.ErrorWindow
local addon = select(2, ...)

local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)

addon.ErrorHandler = {}

local errorDB = {}
local sessionList = {}
local MAX_ERRORS = 1000
local currentSession = nil

local function colorStack(ret)
	ret = tostring(ret) or ''

	-- Color string literals
	ret = ret:gsub('"([^"]+)"', '"|cffCE9178%1|r"')

	-- Color the file name (keeping the extension .lua in the same color)
	ret = ret:gsub('/([^/]+%.lua)', '/|cff4EC9B0%1|r')

	-- Color the full path, with non-important parts in light grey
	ret = ret:gsub('(%[)(@?)([^%]]+)(%])', function(open, at, path, close)
		-- Color 'string' purple when it's the first word in the path
		local coloredPath = path:gsub('^(string%s)', '|cffC586C0%1|r')
		return '|r' .. open .. at .. '|r|cffCE9178' .. coloredPath:gsub('"', '|r"|r') .. '|r' .. close .. '|r'
	end)

	-- Color partial paths
	ret = ret:gsub('(<%.%.%.%S+/)', '|cffCE9178%1|r')

	-- Color line numbers
	ret = ret:gsub(':(%d+)', ':|cffD7BA7D%1|r')

	-- Color error messages (main error text)
	ret = ret:gsub('([^:\n]+):([^\n]*)', function(prefix, message)
		if not prefix:match('[/\\]') and not prefix:match('^%d+$') then
			return '|cffFF5252' .. prefix .. ':' .. message .. '|r'
		else
			return '|cffCE9178' .. prefix .. ':|r|cffFF5252' .. message .. '|r'
		end
	end)

	-- Color method names, function calls, and variables orange
	ret = ret:gsub("'([^']+)'", "|cffFFA500'%1'|r|r")
	ret = ret:gsub('`([^`]+)`', '|cffFFA500`%1`|r|r')
	ret = ret:gsub("`([^`]+)'", '|cffFFA500`%1`|r|r')
	ret = ret:gsub('(%([^)]+%))', '|cffFFA500%1|r|r')
	ret = ret:gsub('([%w_]+:[%w_]+)', '|cffFFA500%1|r')

	-- Color Lua keywords purple, 'in' grey
	local keywords = {
		['and'] = true,
		['break'] = true,
		['do'] = true,
		['else'] = true,
		['elseif'] = true,
		['end'] = true,
		['false'] = true,
		['for'] = true,
		['function'] = true,
		['if'] = true,
		['local'] = true,
		['nil'] = true,
		['not'] = true,
		['or'] = true,
		['repeat'] = true,
		['return'] = true,
		['then'] = true,
		['true'] = true,
		['until'] = true,
		['while'] = true,
		['boolean'] = true,
		['string'] = true,
	}
	ret = ret:gsub('%f[%w](%a+)%f[%W]', function(word)
		if keywords[word] then
			return '|cffC586C0' .. word .. '|r'
		elseif word == 'in' then
			return '|r' .. word .. '|r'
		end
		return word
	end)

	-- Color the error count at the start
	ret = ret:gsub('^(%d+x)', '|cffa6fd79%1|r')

	return ret
end

local function colorLocals(ret)
	ret = tostring(ret) or ''
	-- Remove temporary nil and table lines
	ret = ret:gsub('%(%*temporary%) = nil\n', '')
	ret = ret:gsub('%(%*temporary%) = <table> {.-}\n', '')

	ret = ret:gsub('[%.I][%.n][%.t][%.e][%.r]face\\', '')
	ret = ret:gsub('%.?%.?%.?\\?AddOns\\', '')
	ret = ret:gsub('|(%a)', '||%1'):gsub('|$', '||') -- Pipes

	-- File paths and line numbers
	ret = ret:gsub('> %@(.-):(%d+)', '> @|cff4EC9B0%1|r:|cffD7BA7D%2|r')

	-- Variable names
	ret = ret:gsub('(%s-)([%a_][%w_]*) = ', '%1|cff9CDCFE%2|r = ')

	-- Numbers
	ret = ret:gsub('= (%-?%d+%.?%d*)\n', '= |cffB5CEA8%1|r\n')

	-- nil, true, false
	ret = ret:gsub('= (nil)\n', '= |cff569CD6%1|r\n')
	ret = ret:gsub('= (true)\n', '= |cff569CD6%1|r\n')
	ret = ret:gsub('= (false)\n', '= |cff569CD6%1|r\n')

	-- Strings
	ret = ret:gsub('= (".-")\n', '= |cffCE9178%1|r\n')
	ret = ret:gsub("= ('.-')\n", '= |cffCE9178%1|r\n')

	-- Tables and functions
	ret = ret:gsub('= (<.->)', '= |cffDCDCAA%1|r')

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

function addon.ErrorHandler:ColorText(text)
	text = colorLocals(text)
	text = colorStack(text)
	return text
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
	local s = addon.ErrorHandler:ColorText(tostring(err.message) .. (err.stack and '\n' .. tostring(err.stack) or ''))
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
