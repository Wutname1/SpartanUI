local SUI = SUI
local module = SUI:NewModule('Handler.Events') ---@type SUI.Module
SUI.Event = module
local SUIEvents = {}

function module:SendEvent(EventName, ...)
	if not SUIEvents[EventName] then return end

	for _, v in pairs(SUIEvents[EventName]) do
		v(...)
	end
end

function module:RegisterEvent(EventName, callback)
	if not SUIEvents[EventName] then SUIEvents[EventName] = {} end

	SUIEvents[EventName][#SUIEvents[EventName] + 1] = callback
end
