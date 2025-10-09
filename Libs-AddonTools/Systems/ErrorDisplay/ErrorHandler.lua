---@class LibATErrorDisplay
local ErrorDisplay = _G.LibATErrorDisplay

-- Localization
local L = {
	['BugGrabber is required for LibAT error handling.'] = 'BugGrabber is required for LibAT error handling.',
	['LibAT Error'] = 'LibAT Error',
	['New error captured. Type /libat errors to view.'] = 'New error captured. Type /libat errors to view.',
	['|cffffffffLibAT|r: All stored errors have been wiped.'] = '|cffffffffLibAT|r: All stored errors have been wiped.'
}

ErrorDisplay.ErrorHandler = {}

-- We no longer maintain our own error database
-- BugGrabber manages all errors, we just query it
local currentSession = nil

-- Generate a unique signature for an error based on its message and stack trace
-- This allows us to identify the same error across multiple occurrences
local function GetErrorSignature(err)
	if not err then
		return nil
	end

	-- Use message + first line of stack to create a unique signature
	-- This will match the same error even if it occurs multiple times
	local message = tostring(err.message or ''):gsub('%s+', ' '):trim()
	local stack = tostring(err.stack or '')

	-- Get the first meaningful line from the stack (the actual error location)
	local firstStackLine = stack:match('[^\n]+') or ''
	firstStackLine = firstStackLine:gsub('%s+', ' '):trim()

	-- Combine message and first stack line to create signature
	local signature = message .. '|' .. firstStackLine

	return signature
end

local function colorStack(ret)
	ret = tostring(ret) or ''

	-- Color string literals
	ret = ret:gsub('"([^"]+)"', '"|cffCE9178%1|r"')

	-- Color the file name (keeping the extension .lua in the same color)
	ret = ret:gsub('/([^/]+%.lua)', '/|cff4EC9B0%1|r')

	-- Color the full path, with non-important parts in light grey
	ret =
		ret:gsub(
		'(%[)(@?)([^%]]+)(%])',
		function(open, at, path, close)
			-- Color 'string' purple when it's the first word in the path
			local coloredPath = path:gsub('^(string%s)', '|cffC586C0%1|r')
			return '|r' .. open .. at .. '|r|cffCE9178' .. coloredPath:gsub('"', '|r"|r') .. '|r' .. close .. '|r'
		end
	)

	-- Color partial paths
	ret = ret:gsub('(<%.%.%.%S+/)', '|cffCE9178%1|r')

	-- Color line numbers
	ret = ret:gsub(':(%d+)', ':|cffD7BA7D%1|r')

	-- Color error messages (main error text)
	ret =
		ret:gsub(
		'([^:\n]+):([^\n]*)',
		function(prefix, message)
			if not prefix:match('[/\\]') and not prefix:match('^%d+$') then
				return '|cffFF5252' .. prefix .. ':' .. message .. '|r'
			else
				return '|cffCE9178' .. prefix .. ':|r|cffFF5252' .. message .. '|r'
			end
		end
	)

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
		['string'] = true
	}
	ret =
		ret:gsub(
		'%f[%w](%a+)%f[%W]',
		function(word)
			if keywords[word] then
				return '|cffC586C0' .. word .. '|r'
			elseif word == 'in' then
				return '|r' .. word .. '|r'
			end
			return word
		end
	)

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

function ErrorDisplay.ErrorHandler:Initialize()
	if not BugGrabber then
		print(L['BugGrabber is required for LibAT error handling.'])
		return
	end

	-- Use BugGrabber's session ID directly
	currentSession = BugGrabber:GetSessionId()
	print('LibAT Error Display: Using BugGrabber session #' .. currentSession)

	-- Register with BugGrabber to get notified of new errors
	BugGrabber.RegisterCallback(self, 'BugGrabber_BugGrabbed', 'OnBugGrabbed')

	-- Trigger display update if there are existing errors in current session
	local currentErrors = self:GetErrors(currentSession)
	if #currentErrors > 0 then
		ErrorDisplay:UpdateMinimapIcon()
	end
end

function ErrorDisplay.ErrorHandler:ColorText(text)
	text = colorLocals(text)
	text = colorStack(text)
	return text
end

function ErrorDisplay.ErrorHandler:OnBugGrabbed(callback, errorObject)
	-- Update current session in case it changed
	currentSession = BugGrabber:GetSessionId()

	-- Debug: Show that we're capturing a new error
	if ErrorDisplay.db.chatframe ~= false then
		print('LibAT: New error captured in session #' .. errorObject.session)
	end

	-- Trigger updates (BugGrabber already stored the error)
	if ErrorDisplay.OnError then
		ErrorDisplay.OnError()
	end

	-- Update the window if shown
	if ErrorDisplay.BugWindow.window and ErrorDisplay.BugWindow.window:IsShown() then
		ErrorDisplay.BugWindow:updateDisplay(true)
	end
end

-- Query BugGrabber's database directly (like BugSack does)
function ErrorDisplay.ErrorHandler:GetErrors(sessionId)
	if not BugGrabber then
		return {}
	end

	local db = BugGrabber:GetDB()
	if not sessionId then
		-- Return all errors, filtering out ignored ones
		local filteredErrors = {}
		local ignoredErrors = ErrorDisplay.db and ErrorDisplay.db.ignoredErrors or {}

		for _, err in ipairs(db) do
			local signature = GetErrorSignature(err)
			if not ignoredErrors[signature] then
				table.insert(filteredErrors, err)
			end
		end
		return filteredErrors
	end

	-- Filter by session ID and ignored errors
	local sessionErrors = {}
	local ignoredErrors = ErrorDisplay.db and ErrorDisplay.db.ignoredErrors or {}

	for _, err in ipairs(db) do
		if err.session == sessionId then
			local signature = GetErrorSignature(err)
			if not ignoredErrors[signature] then
				table.insert(sessionErrors, err)
			end
		end
	end
	return sessionErrors
end

-- Get counts of total and ignored errors for a session (or all sessions)
function ErrorDisplay.ErrorHandler:GetErrorCounts(sessionId)
	if not BugGrabber then
		return 0, 0
	end

	local db = BugGrabber:GetDB()
	local totalCount = 0
	local ignoredCount = 0
	local ignoredErrors = ErrorDisplay.db and ErrorDisplay.db.ignoredErrors or {}

	if not sessionId then
		-- Count all errors
		totalCount = #db
		for _, err in ipairs(db) do
			local signature = GetErrorSignature(err)
			if ignoredErrors[signature] then
				ignoredCount = ignoredCount + 1
			end
		end
	else
		-- Count errors for specific session
		for _, err in ipairs(db) do
			if err.session == sessionId then
				totalCount = totalCount + 1
				local signature = GetErrorSignature(err)
				if ignoredErrors[signature] then
					ignoredCount = ignoredCount + 1
				end
			end
		end
	end

	return totalCount, ignoredCount
end

function ErrorDisplay.ErrorHandler:GetCurrentSession()
	-- Always get the latest session from BugGrabber
	if BugGrabber then
		currentSession = BugGrabber:GetSessionId()
	end
	return currentSession
end

function ErrorDisplay.ErrorHandler:GetSessionList()
	if not BugGrabber then
		return {currentSession or 1}
	end

	-- Get all unique session IDs from BugGrabber's database
	local sessionsWithErrors = {}
	local db = BugGrabber:GetDB()

	for _, err in ipairs(db) do
		if err.session and not tContains(sessionsWithErrors, err.session) then
			table.insert(sessionsWithErrors, err.session)
		end
	end

	-- Ensure current session is included
	local current = self:GetCurrentSession()
	if current and not tContains(sessionsWithErrors, current) then
		table.insert(sessionsWithErrors, current)
	end

	-- Sort sessions
	table.sort(sessionsWithErrors)
	return sessionsWithErrors
end

function ErrorDisplay.ErrorHandler:GetSessionInfo(sessionId)
	-- Return basic session info
	-- We no longer track detailed session history, just session IDs from BugGrabber
	if sessionId == currentSession then
		return {
			id = sessionId,
			startTime = time(),
			gameTime = GetTime(),
			playerName = UnitName('player'),
			realmName = GetRealmName(),
			buildInfo = select(1, GetBuildInfo()),
			isCurrent = true
		}
	end

	return {
		id = sessionId,
		startTime = nil,
		gameTime = nil,
		playerName = UnitName('player') or 'Unknown',
		realmName = GetRealmName() or 'Unknown',
		buildInfo = select(1, GetBuildInfo()) or 'Unknown'
	}
end

function ErrorDisplay.ErrorHandler:GetSessionsWithInfo()
	local sessions = self:GetSessionList()
	local sessionData = {}

	for _, sessionId in ipairs(sessions) do
		local info = self:GetSessionInfo(sessionId)
		local errorCount = #self:GetErrors(sessionId)

		table.insert(
			sessionData,
			{
				id = sessionId,
				info = info,
				errorCount = errorCount,
				isCurrent = sessionId == currentSession
			}
		)
	end

	return sessionData
end

function ErrorDisplay.ErrorHandler:FormatError(err)
	local s = ErrorDisplay.ErrorHandler:ColorText(tostring(err.message) .. (err.stack and '\n' .. tostring(err.stack) or ''))
	local l = colorLocals(tostring(err.locals))
	return string.format('%dx %s\n\nLocals:\n%s', err.counter or 1, s, l)
end

function ErrorDisplay.ErrorHandler:Reset()
	-- Reset BugGrabber's database (this is the source of truth)
	if BugGrabber then
		BugGrabber:Reset()
	end

	-- Update current session
	if BugGrabber then
		currentSession = BugGrabber:GetSessionId()
	end

	print(L['|cffffffffLibAT|r: All stored errors have been wiped.'])
end

-- Add an error to the ignored list
function ErrorDisplay.ErrorHandler:IgnoreError(err)
	if not err then
		return false
	end

	local signature = GetErrorSignature(err)
	if not signature then
		return false
	end

	-- Initialize ignored errors table if it doesn't exist
	if not ErrorDisplay.db.ignoredErrors then
		ErrorDisplay.db.ignoredErrors = {}
	end

	-- Add the error signature to ignored list
	ErrorDisplay.db.ignoredErrors[signature] = true

	-- Update display
	if ErrorDisplay.OnError then
		ErrorDisplay:UpdateMinimapIcon()
	end

	return true
end

-- Remove an error from the ignored list (unignore)
function ErrorDisplay.ErrorHandler:UnignoreError(err)
	if not err then
		return false
	end

	local signature = GetErrorSignature(err)
	if not signature then
		return false
	end

	-- Remove from ignored list
	if ErrorDisplay.db and ErrorDisplay.db.ignoredErrors then
		ErrorDisplay.db.ignoredErrors[signature] = nil
	end

	-- Update display
	if ErrorDisplay.OnError then
		ErrorDisplay:UpdateMinimapIcon()
	end

	return true
end

-- Get all ignored errors from BugGrabber's database
function ErrorDisplay.ErrorHandler:GetIgnoredErrors()
	if not BugGrabber then
		return {}
	end

	local db = BugGrabber:GetDB()
	local ignoredErrors = ErrorDisplay.db and ErrorDisplay.db.ignoredErrors or {}
	local ignoredList = {}

	for _, err in ipairs(db) do
		local signature = GetErrorSignature(err)
		if ignoredErrors[signature] then
			table.insert(ignoredList, err)
		end
	end

	return ignoredList
end

-- Get all errors from all sessions (unfiltered by session, but still filter ignored)
function ErrorDisplay.ErrorHandler:GetAllErrorsFromAllSessions()
	if not BugGrabber then
		return {}
	end

	local db = BugGrabber:GetDB()
	local allErrors = {}
	local ignoredErrors = ErrorDisplay.db and ErrorDisplay.db.ignoredErrors or {}

	-- Get all errors, filtering out ignored ones
	for _, err in ipairs(db) do
		local signature = GetErrorSignature(err)
		if not ignoredErrors[signature] then
			table.insert(allErrors, err)
		end
	end

	return allErrors
end

-- Check if an error is ignored
function ErrorDisplay.ErrorHandler:IsErrorIgnored(err)
	if not err then
		return false
	end

	local signature = GetErrorSignature(err)
	if not signature then
		return false
	end

	local ignoredErrors = ErrorDisplay.db and ErrorDisplay.db.ignoredErrors or {}
	return ignoredErrors[signature] == true
end

-- Clear all ignored errors
function ErrorDisplay.ErrorHandler:ClearIgnoredErrors()
	if ErrorDisplay.db then
		ErrorDisplay.db.ignoredErrors = {}

		-- Update display
		if ErrorDisplay.OnError then
			ErrorDisplay:UpdateMinimapIcon()
		end
	end
end

return ErrorDisplay.ErrorHandler
