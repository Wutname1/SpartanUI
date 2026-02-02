local SUI, L = SUI, SUI.L
---@class SUI.Module.UICleanup
local module = SUI:GetModule('UICleanup')
----------------------------------------------------------------------------------------------------

local originalUIErrorsFrame_OnEvent

function module:InitializeErrorMessages()
	-- Store original handler
	originalUIErrorsFrame_OnEvent = UIErrorsFrame:GetScript('OnEvent')
end

function module:ApplyErrorMessageSettings()
	local DB = module:GetDB()

	if DB.hideErrorMessages then
		UIErrorsFrame:SetScript('OnEvent', function(self, event, msg, ...)
			-- Filter out red error messages but allow other messages
			if event == 'UI_ERROR_MESSAGE' then
				return -- Suppress error messages
			end
			-- Pass through other events
			if originalUIErrorsFrame_OnEvent then
				originalUIErrorsFrame_OnEvent(self, event, msg, ...)
			end
		end)
	else
		module:RestoreErrorMessages()
	end
end

function module:RestoreErrorMessages()
	if originalUIErrorsFrame_OnEvent then
		UIErrorsFrame:SetScript('OnEvent', originalUIErrorsFrame_OnEvent)
	end
end
