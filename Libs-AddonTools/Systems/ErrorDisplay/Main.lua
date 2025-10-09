---@class LibATErrorDisplay
local ErrorDisplay = {}

-- Make globally accessible for other systems
_G.LibATErrorDisplay = ErrorDisplay

-- Initialize component placeholders
ErrorDisplay.Config = {}
ErrorDisplay.ErrorHandler = {}
ErrorDisplay.BugWindow = {}

local addonName = 'Libs-AddonTools'
local MinimapIconName = addonName .. 'ErrorDisplay'

-- Localization (will be enhanced later)
local L = {
	['SpartanUI Error'] = 'LibAT Error',
	['New error captured. Type /suierrors to view.'] = 'New error captured. Type /libat errors to view.',
	['BugGrabber is required for SpartanUI error handling.'] = 'BugGrabber is required for LibAT error handling.',
	['|cffffffffSpartan|cffe21f1fUI|r: All stored errors have been wiped.'] = '|cffffffffLibAT|r: All stored errors have been wiped.'
}

-- LibDBIcon for minimap button
local LDB = LibStub('LibDataBroker-1.1')
local icon = LibStub('LibDBIcon-1.0')
ErrorDisplay.icon = icon

-- Create LibDataBroker data object
local ldbObject =
	LDB:NewDataObject(
	MinimapIconName,
	{
		type = 'data source',
		text = '0',
		icon = 'Interface\\AddOns\\Libs-AddonTools\\Images\\old_error.png',
		OnClick = function(self, button)
			if button == 'RightButton' then
				-- Open settings
				if ErrorDisplay.settingsCategory then
					Settings.OpenToCategory(ErrorDisplay.settingsCategory.ID)
				end
			else
				if IsAltKeyDown() then
					ErrorDisplay.Reset()
				else
					ErrorDisplay.BugWindow:OpenErrorWindow()
				end
			end
		end,
		OnTooltipShow = function(tt)
			local errorsCurrent = ErrorDisplay.ErrorHandler:GetErrors(ErrorDisplay.ErrorHandler:GetCurrentSession())
			local errorsTotal = #ErrorDisplay.ErrorHandler:GetErrors()
			local totalCount, ignoredCount = ErrorDisplay.ErrorHandler:GetErrorCounts()
			local currentTotalCount, currentIgnoredCount = ErrorDisplay.ErrorHandler:GetErrorCounts(ErrorDisplay.ErrorHandler:GetCurrentSession())

			if #errorsCurrent == 0 then
				if errorsTotal ~= 0 then
					if ignoredCount > 0 then
						tt:AddLine(string.format('You have no new bugs, but you have %d saved bugs (%d ignored).', totalCount, ignoredCount))
					else
						tt:AddLine('You have no new bugs, but you have ' .. errorsTotal .. ' saved bugs.')
					end
				else
					if ignoredCount > 0 then
						tt:AddLine(string.format('You have no bugs, but %d are ignored.', ignoredCount))
					else
						tt:AddLine('You have no bugs, yay!')
					end
				end
			else
				tt:AddLine('|cffffffffLibAT|r error handler')
				local line = '%d. %s (x%d)'
				for i, err in next, errorsCurrent do
					tt:AddLine(line:format(i, ErrorDisplay.ErrorHandler:ColorText(err.message), err.counter), 0.5, 0.5, 0.5)
					if i > 8 then
						break
					end
				end
				if currentIgnoredCount > 0 then
					tt:AddLine(' ')
					tt:AddLine(string.format('|cff888888%d error(s) ignored in current session|r', currentIgnoredCount), 0.7, 0.7, 0.7)
				end
			end
			tt:AddLine(' ')
			tt:AddLine('|cffeda55fClick|r to open bug window.\n|cffeda55fAlt-Click|r to clear all saved errors.\n|cffeda55fRight-Click|r for options.', 0.2, 1, 0.2, 1)
		end
	}
)

ErrorDisplay.ldbObject = ldbObject

ErrorDisplay.Reset = function()
	if BugGrabber then
		BugGrabber:Reset()
	end
	ErrorDisplay.ErrorHandler:Reset()
	ErrorDisplay.BugWindow:Reset()
	ErrorDisplay:UpdateMinimapIcon()
end

ErrorDisplay.OnError = function()
	-- If the frame is shown, we need to update it.
	if (not InCombatLockdown() and ErrorDisplay.db.autoPopup) or (ErrorDisplay.BugWindow:IsShown()) then
		local errorsCurrent = ErrorDisplay.ErrorHandler:GetErrors(ErrorDisplay.ErrorHandler:GetCurrentSession())
		if errorsCurrent and #errorsCurrent > 0 then
			ErrorDisplay.BugWindow:OpenErrorWindow()
		end
	end

	ErrorDisplay:UpdateMinimapIcon()
end

function ErrorDisplay:Initialize()
	if not BugGrabber then
		print(L['BugGrabber is required for LibAT error handling.'])
		return
	end

	-- Check if BugSack or other display addon is present
	-- local name, _, _, enabled = C_AddOns.GetAddOnInfo('BugSack')
	-- if name and enabled then
	-- 	print('LibAT Error Display: BugSack detected, disabling to avoid conflicts.')
	-- 	return
	-- end

	-- Check for other common error display addons
	local conflictingAddons = {'!ImprovedErrorFrame', '!Swatter'}
	for _, addonName in ipairs(conflictingAddons) do
		local name, _, _, enabled = C_AddOns.GetAddOnInfo(addonName)
		if name and enabled then
			print('LibAT Error Display: ' .. addonName .. ' detected, disabling to avoid conflicts.')
			return
		end
	end

	-- Wait for all components to load
	if not self.Config or not self.Config.Initialize then
		C_Timer.After(
			0.1,
			function()
				self:Initialize()
			end
		)
		return
	end
	if not self.ErrorHandler or not self.ErrorHandler.Initialize then
		C_Timer.After(
			0.1,
			function()
				self:Initialize()
			end
		)
		return
	end
	if not self.BugWindow or not self.BugWindow.Create then
		C_Timer.After(
			0.1,
			function()
				self:Initialize()
			end
		)
		return
	end

	-- Initialize saved variables and options
	ErrorDisplay.Config:Initialize()

	-- Register with LibDBIcon for minimap button
	-- Ensure minimapIcon table exists in db
	if not ErrorDisplay.db.minimapIcon then
		ErrorDisplay.db.minimapIcon = {hide = false}
	end
	icon:Register(MinimapIconName, ldbObject, ErrorDisplay.db.minimapIcon)

	-- Create the options panel
	ErrorDisplay.Config:CreatePanel()

	-- Initialize the error handler
	ErrorDisplay.ErrorHandler:Initialize()

	-- Create slash command
	SLASH_LIBATERRORS1 = '/libaterrors'
	SlashCmdList['LIBATERRORS'] = function(msg)
		if msg == 'config' or msg == 'options' then
			if ErrorDisplay.settingsCategory then
				Settings.OpenToCategory(ErrorDisplay.settingsCategory.ID)
			end
		else
			ErrorDisplay.BugWindow:OpenErrorWindow()
		end
	end

	-- Hide default error frame
	if ScriptErrorsFrame then
		ScriptErrorsFrame:Hide()
		ScriptErrorsFrame:HookScript(
			'OnShow',
			function()
				ScriptErrorsFrame:Hide()
			end
		)
	end

	print('LibAT Error Display system initialized')
end

-- Expose global functions for external access
ErrorDisplay.OpenErrorWindow = function()
	ErrorDisplay.BugWindow:OpenErrorWindow()
end

ErrorDisplay.CloseErrorWindow = function()
	ErrorDisplay.BugWindow:CloseErrorWindow()
end

-- Add a function to update the minimap icon
function ErrorDisplay:UpdateMinimapIcon()
	local errorsCurrent = ErrorDisplay.ErrorHandler:GetErrors(ErrorDisplay.ErrorHandler:GetCurrentSession())
	local errorsTotal = #ErrorDisplay.ErrorHandler:GetErrors()

	-- Update LDB text with current session error count
	if ldbObject then
		ldbObject.text = tostring(#errorsCurrent)

		-- Update icon based on error state
		if errorsCurrent and #errorsCurrent > 0 then
			-- New errors in current session - use red icon
			ldbObject.icon = 'Interface\\AddOns\\Libs-AddonTools\\Images\\error.png'
		else
			-- No new errors - use gray icon
			ldbObject.icon = 'Interface\\AddOns\\Libs-AddonTools\\Images\\old_error.png'
		end
	end
end

-- Initialize when all dependencies are ready
local function InitializeErrorDisplay()
	-- Check for required dependencies
	if not BugGrabber then
		return false
	end

	if not LibStub or not LibStub('LibDataBroker-1.1', true) or not LibStub('LibDBIcon-1.0', true) then
		return false
	end

	ErrorDisplay:Initialize()
	return true
end

-- Try immediate initialization
if not InitializeErrorDisplay() then
	-- If not ready, wait for ADDON_LOADED event
	local frame = CreateFrame('Frame')
	frame:RegisterEvent('ADDON_LOADED')
	frame:SetScript(
		'OnEvent',
		function(self, event, addonName)
			if addonName == 'Libs-AddonTools' then
				if InitializeErrorDisplay() then
					self:UnregisterEvent('ADDON_LOADED')
				end
			end
		end
	)
end

return ErrorDisplay
