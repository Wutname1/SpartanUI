-- SpartanUI Custom Error Handler Minimap Icon
-- Uses LibAT's error handler backend with SUI's custom minimap icon

local addonName = select(1, ...)
local MinimapIconName = addonName .. 'ErrorDisplay'

-- Verify LibAT is available
if not LibAT or not LibAT.ErrorDisplay then
	error('Libs-AddonTools is required but not found')
	return
end

local LibATErrorDisplay = LibAT.ErrorDisplay
local BugGrabber = BugGrabber

local MinimapButton

local function InitializeMinimapButton()
	-- Create SUI's custom minimap icon
	MinimapButton = CreateFrame('Button', MinimapIconName, MinimapCluster)
	MinimapButton:SetSize(25, 25)
	MinimapButton:SetPoint('BOTTOM', Minimap, 'BOTTOM', 0, 2)
	MinimapButton:SetFrameLevel(500)
	MinimapButton:SetFrameStrata('MEDIUM')
	MinimapButton:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
	MinimapButton:SetHighlightTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
	MinimapButton:SetPushedTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')

	-- Tooltip using LibAT's error data
	MinimapButton:SetScript(
		'OnEnter',
		function(self)
			GameTooltip:SetOwner(self, 'TOP')

			local errorsCurrent = LibATErrorDisplay.ErrorHandler:GetErrors(BugGrabber:GetSessionId())
			local errorsTotal = #LibATErrorDisplay.ErrorHandler:GetErrors()

			if #errorsCurrent == 0 then
				if errorsTotal ~= 0 then
					GameTooltip:AddLine('You have no new bugs, but you have ' .. errorsTotal .. ' saved bugs.')
				else
					GameTooltip:AddLine('You have no bugs, yay!')
				end
			else
				GameTooltip:AddLine('|cffffffffSpartan|cffe21f1fUI|r error handler')
				local line = '%d. %s (x%d)'
				for i, err in next, errorsCurrent do
					GameTooltip:AddLine(line:format(i, LibATErrorDisplay.ErrorHandler:ColorText(err.message), err.counter), 0.5, 0.5, 0.5)
					if i > 8 then
						break
					end
				end
			end
			GameTooltip:AddLine(' ')
			GameTooltip:AddLine('|cffeda55fClick|r to open bug window.\n|cffeda55fAlt-Click|r to clear all saved errors.', 0.2, 1, 0.2, 1)
			GameTooltip:Show()
		end
	)

	MinimapButton:SetScript(
		'OnLeave',
		function()
			GameTooltip:Hide()
		end
	)

	-- Click handler - use LibAT's functions
	MinimapButton:RegisterForClicks('AnyUp')
	MinimapButton:SetScript(
		'OnClick',
		function(self, button)
			if IsAltKeyDown() then
				LibATErrorDisplay.Reset()
			else
				LibATErrorDisplay.BugWindow:OpenErrorWindow()
			end
		end
	)

	MinimapButton:Hide()
end

local function UpdateMinimapIcon()
	if not MinimapButton then
		return
	end

	local errorsCurrent = LibATErrorDisplay.ErrorHandler:GetErrors(BugGrabber:GetSessionId())
	local errorsTotal = #LibATErrorDisplay.ErrorHandler:GetErrors()

	if errorsTotal ~= 0 then
		MinimapButton:Show()
		-- Update texture based on new vs old errors
		if errorsCurrent and #errorsCurrent > 0 then
			MinimapButton:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\error.png')
			MinimapButton:SetHighlightTexture('Interface\\AddOns\\SpartanUI\\images\\error.png')
		else
			MinimapButton:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
			MinimapButton:SetHighlightTexture('Interface\\AddOns\\SpartanUI\\images\\old_error.png')
		end
	else
		MinimapButton:Hide()
	end
end

-- Hook into LibAT's error update to update our icon
local function OnAddonLoaded(self, event, loadedAddonName)
	if loadedAddonName ~= addonName then
		return
	end

	-- Initialize the minimap button
	InitializeMinimapButton()

	-- Update icon when BugGrabber captures an error
	if BugGrabber then
		BugGrabber.RegisterCallback(MinimapButton, 'BugGrabber_BugGrabbed', UpdateMinimapIcon)
	end

	-- Create slash command
	SLASH_SUIERRORS1 = '/suierrors'
	SlashCmdList['SUIERRORS'] = function(msg)
		if msg == 'config' or msg == 'options' then
			if LibATErrorDisplay.settingsCategory then
				Settings.OpenToCategory(LibATErrorDisplay.settingsCategory.ID)
			end
		else
			LibATErrorDisplay.BugWindow:OpenErrorWindow()
		end
	end

	-- Initial update
	UpdateMinimapIcon()

	self:UnregisterEvent('ADDON_LOADED')
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', OnAddonLoaded)

-- Expose global functions for compatibility
_G.SUIErrorDisplay = {
	OpenErrorWindow = function()
		LibATErrorDisplay.BugWindow:OpenErrorWindow()
	end,
	CloseErrorWindow = function()
		LibATErrorDisplay.BugWindow:CloseErrorWindow()
	end,
	Reset = function()
		LibATErrorDisplay.Reset()
	end,
	UpdateIcon = UpdateMinimapIcon
}
