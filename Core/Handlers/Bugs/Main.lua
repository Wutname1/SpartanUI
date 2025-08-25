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
	-- Create a Icon via standard wow frame
	local button = CreateFrame('Button', MinimapIconName, MinimapCluster)
	button:SetSize(25, 25)
	button:SetPoint('BOTTOM', Minimap, 'BOTTOM', 0, 2)
	button:SetFrameLevel(500)
	button:SetFrameStrata('MEDIUM')
	button:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
	button:SetHighlightTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
	button:SetPushedTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
	button:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'TOP')
		local errorsCurrent = addon.ErrorHandler:GetErrors(BugGrabber:GetSessionId())
		local errorsTotal = #addon.ErrorHandler:GetErrors()
		if #errorsCurrent == 0 then
			if errorsTotal ~= 0 then
				GameTooltip:AddLine('You no new bugs, but you have ' .. errorsTotal .. ' saved bugs.')
			else
				GameTooltip:AddLine('You have no bugs, yay!')
			end
		else
			GameTooltip:AddLine('|cffffffffSpartan|cffe21f1fUI|r error handler')
			local line = '%d. %s (x%d)'
			for i, err in next, errorsCurrent do
				GameTooltip:AddLine(line:format(i, addon.ErrorHandler:ColorText(err.message), err.counter), 0.5, 0.5, 0.5)
				if i > 8 then break end
			end
		end
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine('|cffeda55fClick|r to open bug window.\n|cffeda55fAlt-Click|r to clear all saved errors.', 0.2, 1, 0.2, 1)
		GameTooltip:Show()
	end)
	button:RegisterForClicks('AnyUp')
	button:SetScript('OnClick', function(self, button)
		if IsAltKeyDown() then
			addon.Reset()
		else
			addon.BugWindow:OpenErrorWindow()
		end
	end)
	button:Hide()
	addon.MinimapButton = button
end

addon.Reset = function()
	BugGrabber:Reset()
	addon.ErrorHandler:Reset()
	addon.BugWindow:Reset()
	addon:updatemapIcon()
end

addon.onError = function()
	-- If the frame is shown, we need to update it.
	if (not InCombatLockdown() and addon.Config:Get('autoPopup')) or (addon.BugWindow:IsShown()) then
		local errorsCurrent = addon.ErrorHandler:GetErrors(BugGrabber:GetSessionId())
		if errorsCurrent and #errorsCurrent > 0 then addon.BugWindow:OpenErrorWindow() end
	end

	addon:updatemapIcon()
end

local function OnAddonLoaded(self, event, loadedAddonName)
	if loadedAddonName ~= addonName then return end
	-- Initialize the minimap button
	InitializeMinimapButton()

	-- Initialize saved variables and options
	addon.Config:Initialize()

	-- Create the options panel
	addon.Config:CreatePanel()

	-- Initialize the error handler
	addon.ErrorHandler:Initialize()

	-- Create slash command
	SLASH_SUIERRORS1 = '/suierrors'
	SlashCmdList['SUIERRORS'] = function(msg)
		if msg == 'config' or msg == 'options' then
				Settings.OpenToCategory(addon.settingsCategory.ID)
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
	Reset = function()
		addon.Reset()
	end,
}

-- Add a function to update the minimap icon
function addon:updatemapIcon()
	local errorsCurrent = addon.ErrorHandler:GetErrors(BugGrabber:GetSessionId())
	local errorsTotal = #addon.ErrorHandler:GetErrors()
	if not addon.MinimapButton then InitializeMinimapButton() end
	if errorsTotal ~= 0 and addon.MinimapButton then
		addon.MinimapButton:Show()
		-- Update Texture
		if errorsCurrent and #errorsCurrent > 0 then
			addon.MinimapButton:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\error.png')
			addon.MinimapButton:SetHighlightTexture('Interface\\AddOns\\SpartanUI\\images\\error.png')
		else
			addon.MinimapButton:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
			addon.MinimapButton:SetHighlightTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
		end
	else
		addon.MinimapButton:Hide()
	end
end
