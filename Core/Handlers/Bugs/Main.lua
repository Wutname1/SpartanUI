---@class Lib.ErrorWindow
local addon = select(2, ...)
local addonName = select(1, ...)
local MinimapIconName = addonName .. 'ErrorDisplay'

local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)

-- LibDBIcon for minimap button
local LDB = LibStub('LibDataBroker-1.1')
local icon = LibStub('LibDBIcon-1.0')
addon.icon = icon

local function InitializeMinimapButton()
	local SUIErrorLauncher = LDB:NewDataObject(addonName, {
		type = 'data source',
		text = '0',
		icon = 'Interface\\AddOns\\SpartanUI\\images\\MinimapError',
		OnClick = function(self, button)
			if IsAltKeyDown() then
				BugGrabber:Reset()
			elseif button == 'RightButton' then
				Settings.OpenToCategory(addon.settingsCategory.ID)
			else
				addon.BugWindow:OpenErrorWindow()
			end
		end,
		OnTooltipShow = function(tt)
			local hint = '|cffeda55fClick|r to open bug window with the last bug. |cffeda55fAlt-Click|r to clear all saved errors.'
			local line = '%d. %s (x%d)'
			local errs = addon.ErrorHandler:GetErrors(BugGrabber:GetSessionId())
			if #errs == 0 then
				tt:AddLine('You have no bugs, yay!')
			else
				tt:AddLine('SpartanUI error handler')
				for i, err in next, errs do
					tt:AddLine(line:format(i, addon.ErrorHandler:ColorText(err.message), err.counter), 0.5, 0.5, 0.5)
					if i > 8 then break end
				end
			end
			tt:AddLine(' ')
			tt:AddLine(hint, 0.2, 1, 0.2, 1)
		end,
	})

	icon:Register(MinimapIconName, SUIErrorLauncher, addon.Config.db.minimapIcon)
end

addon.onError = function()
	-- If the frame is shown, we need to update it.
	if (not InCombatLockdown() and addon.Config:Get('autoPopup')) or (addon.BugWindow:IsShown()) then addon.BugWindow:OpenErrorWindow() end

	addon:updatemapIcon()
end

local function OnAddonLoaded(self, event, loadedAddonName)
	if loadedAddonName ~= addonName then return end

	-- Initialize saved variables and options
	addon.Config:Initialize()

	-- Create the options panel
	addon.Config:CreatePanel()

	-- Initialize the error handler
	addon.ErrorHandler:Initialize()

	-- Initialize the minimap button
	InitializeMinimapButton()

	-- Create slash command
	SLASH_SUIERRORS1 = '/suierrors'
	SlashCmdList['SUIERRORS'] = function(msg)
		if msg == 'config' or msg == 'options' then
			if InterfaceOptionsFrame_OpenToCategory then
				InterfaceOptionsFrame_OpenToCategory(addonName)
				InterfaceOptionsFrame_OpenToCategory(addonName)
			else
				Settings.OpenToCategory(addon.settingsCategory.ID)
			end
		else
			addon.BugWindow:OpenErrorWindow()
		end
	end

	-- Hide default error frame
	ScriptErrorsFrame:Hide()
	ScriptErrorsFrame:HookScript('OnShow', function()
		ScriptErrorsFrame:Hide()
	end)

	self:UnregisterEvent('ADDON_LOADED')
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', OnAddonLoaded)

-- Expose global functions if needed
_G.SUIErrorDisplay = {
	OpenErrorWindow = function()
		addon.BugWindow:OpenErrorWindow()
	end,
	CloseErrorWindow = function()
		addon.BugWindow:CloseErrorWindow()
	end,
}

-- Add a function to update the minimap icon
function addon:updatemapIcon()
	if icon:GetMinimapButton(MinimapIconName) then icon:Refresh(addonName) end

	local count = #addon.ErrorHandler:GetErrors()
	if count ~= 0 then
		icon:Show(MinimapIconName)
	else
		icon:Hide(MinimapIconName)
	end
end
