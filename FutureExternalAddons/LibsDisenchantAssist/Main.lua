---@class LibsDisenchantAssist
local LibsDisenchantAssist = _G.LibsDisenchantAssist

local frame = CreateFrame('Frame')

frame:RegisterEvent('ADDON_LOADED')
frame:RegisterEvent('PLAYER_LOGIN')

frame:SetScript('OnEvent', function(self, event, addonName)
	if event == 'ADDON_LOADED' and addonName == 'LibsDisenchantAssist' then
		-- Initialize subsystems (Core is already initialized via AceAddon)
		LibsDisenchantAssist.ItemTracker:Initialize()
		LibsDisenchantAssist.DisenchantLogic:Initialize()

		-- Check if SpartanUI is available and register as a module
		if SUI and SUI.opt and SUI.opt.args and SUI.opt.args.Modules then
			-- Register options with SpartanUI instead of creating standalone panel
			LibsDisenchantAssist:RegisterSpartanUIModule()
		else
			-- Fallback to standalone options panel
			LibsDisenchantAssist.OptionsPanel:Initialize()
		end
	elseif event == 'PLAYER_LOGIN' then
		-- Do initial bag scan after player is fully logged in
		C_Timer.After(2, function()
			LibsDisenchantAssist.ItemTracker:ScanBagsForNewItems()
		end)
	end
end)

SLASH_LIBSDISENCHANTASSIST1 = '/libsde'
SLASH_LIBSDISENCHANTASSIST2 = '/disenchantassist'

SlashCmdList['LIBSDISENCHANTASSIST'] = function(msg)
	local command = string.lower(string.trim(msg or ''))

	if command == '' or command == 'show' then
		if LibsDisenchantAssist.UI then LibsDisenchantAssist.UI:Show() end
	elseif command == 'hide' then
		if LibsDisenchantAssist.UI then LibsDisenchantAssist.UI:Hide() end
	elseif command == 'toggle' then
		if LibsDisenchantAssist.UI then LibsDisenchantAssist.UI:Toggle() end
	elseif command == 'options' then
		if LibsDisenchantAssist.UI then
			LibsDisenchantAssist.UI:Show()
			if not LibsDisenchantAssist.UI.isOptionsVisible then LibsDisenchantAssist.UI:ToggleOptions() end
		end
	elseif command == 'scan' then
		LibsDisenchantAssist.ItemTracker:ScanBagsForNewItems()
		LibsDisenchantAssist:Print('Scanned bags for new items.')
	elseif command == 'stop' then
		LibsDisenchantAssist.DisenchantLogic:StopBatchDisenchant()
	elseif command == 'help' then
		LibsDisenchantAssist:Print('Commands:')
		LibsDisenchantAssist:Print('/libsde or /libsde show - Show the main window')
		LibsDisenchantAssist:Print('/libsde hide - Hide the main window')
		LibsDisenchantAssist:Print('/libsde toggle - Toggle the main window')
		LibsDisenchantAssist:Print('/libsde options - Show options panel')
		LibsDisenchantAssist:Print('/libsde scan - Scan bags for new items')
		LibsDisenchantAssist:Print('/libsde stop - Stop batch disenchanting')
		LibsDisenchantAssist:Print('/libsde help - Show this help')
	else
		LibsDisenchantAssist:Print('Unknown command: ' .. command .. ". Type '/libsde help' for commands.")
	end
end
