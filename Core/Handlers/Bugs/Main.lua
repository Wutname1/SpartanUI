local addonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)

-- LibDBIcon for minimap button
local LDB = LibStub('LibDataBroker-1.1')
local icon = LibStub('LibDBIcon-1.0')
addon.icon = icon

local function InitializeMinimapButton()
	local SUIErrorLauncher = LDB:NewDataObject(addonName, {
		type = 'launcher',
		icon = 'Interface\\AddOns\\' .. addonName .. '\\Media\\Icon',
		OnClick = function(self, button)
			if button == 'LeftButton' then
				addon.BugWindow:OpenErrorWindow()
			elseif button == 'RightButton' then
				if InterfaceOptionsFrame_OpenToCategory then
					InterfaceOptionsFrame_OpenToCategory(addonName)
					InterfaceOptionsFrame_OpenToCategory(addonName)
				else
					Settings.OpenToCategory(addon.settingsCategory.ID)
				end
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine(L['SpartanUI Error Display'])
			tooltip:AddLine(L['Left-click to open error window'])
			tooltip:AddLine(L['Right-click to open options'])
		end,
	})

	icon:Register(addonName, SUIErrorLauncher, addon.Config:Get('minimapIcon'))
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
	if icon:GetMinimapButton(addonName) then icon:Refresh(addonName) end

	local count = #addon.ErrorHandler:GetErrors()
	if count ~= 0 then
		icon:Show(addonName)
	else
		icon:Hide(addonName)
	end
end
