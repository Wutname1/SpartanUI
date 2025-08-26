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
		LibsDisenchantAssist.OptionsPanel:Initialize()
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

-- Register as LibDataBroker object for addon display systems
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
	local disenchantLDB = LDB:NewDataObject('LibsDisenchantAssist', {
		type = 'launcher',
		text = 'Disenchant Assist',
		icon = 'Interface\\Icons\\INV_Enchant_Disenchant',
		label = "Lib's - Disenchant Assist",

		OnClick = function(self, button)
			if button == 'LeftButton' then
				LibsDisenchantAssist.UI:Toggle()
			elseif button == 'RightButton' then
				LibsDisenchantAssist.UI:Show()
				if LibsDisenchantAssist.UI.isOptionsVisible == false then LibsDisenchantAssist.UI:ToggleOptions() end
			end
		end,

		OnTooltipShow = function(tooltip)
			if not tooltip then return end

			tooltip:AddLine("|cff00ff00Lib's - Disenchant Assist|r")
			tooltip:AddLine(' ')

			-- Show current stats
			local items = LibsDisenchantAssist.FilterSystem:GetDisenchantableItems()
			local count = #items

			if count > 0 then
				tooltip:AddLine(string.format('|cffFFFFFF%d items|r ready to disenchant', count))
			else
				tooltip:AddLine('|cff888888No items to disenchant|r')
			end

			tooltip:AddLine(' ')
			tooltip:AddLine('|cffFFFFFFLeft Click:|r |cff00ffffToggle main window|r')
			tooltip:AddLine('|cffFFFFFFRight Click:|r |cff00ffffShow options panel|r')
		end,

		-- Update method for refreshing display
		UpdateLDB = function(self)
			local items = LibsDisenchantAssist.FilterSystem:GetDisenchantableItems()
			local count = #items

			if count > 0 then
				self.text = string.format('DE: %d', count)
			else
				self.text = 'DE: 0'
			end
		end,
	})

	-- Store reference for updates
	LibsDisenchantAssist._ldbObject = disenchantLDB

	-- Setup LibDBIcon for minimap button if available
	local LibDBIcon = LibStub:GetLibrary('LibDBIcon-1.0', true)
	if LibDBIcon then LibDBIcon:Register('LibsDisenchantAssist', disenchantLDB, LibsDisenchantAssistCharDB.minimap) end

	LibsDisenchantAssist:Print('Registered with LibDataBroker system')
else
	LibsDisenchantAssist:Print('LibDataBroker not available - no minimap button')
end
