local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local module = SUI:NewModule('Handler_Events', 'AceEvent-3.0')
SUI.Event = module
local SUIEvents = {}

function module:SendEvent(EventName, ...)
	if not SUIEvents[EventName] then
		return
	end

	for k, v in pairs(SUIEvents[EventName]) do
		v(...)
	end
end

function module:RegisterEvent(EventName, callback)
	if not SUIEvents[EventName] then
		SUIEvents[EventName] = {}
	end

	SUIEvents[EventName][#SUIEvents[EventName] + 1] = callback
end
