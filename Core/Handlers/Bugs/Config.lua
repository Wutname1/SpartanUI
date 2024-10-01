---@class Lib.ErrorWindow
local addon = select(2, ...)
local addonName = select(1, ...)
local MinimapIconName = addonName .. 'ErrorDisplay'

local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)

addon.Config = {}

-- Default settings
local defaults = {
	autoPopup = false,
	chatframe = true,
	fontSize = 12,
	minimapIcon = { hide = false, minimapPos = 97.66349921766368 },
}

-- Initialize the saved variables
function addon.Config:Initialize()
	if not SUIErrorHandler then
		SUIErrorHandler = CopyTable(defaults)
	else
		for k, v in pairs(defaults) do
			if SUIErrorHandler[k] == nil then SUIErrorHandler[k] = v end
		end
	end
	self.db = SUIErrorHandler
end

-- Create the options panel
function addon.Config:CreatePanel()
	local panel = CreateFrame('Frame')
	panel.name = addonName

	local title = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
	title:SetPoint('TOPLEFT', 16, -16)
	title:SetText(addonName .. ' ' .. L['Options'])

	-- Auto Popup checkbox
	local autoPopup = CreateFrame('CheckButton', nil, panel, 'InterfaceOptionsCheckButtonTemplate')
	autoPopup:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -16)
	autoPopup.Text:SetText(L['Auto popup on errors'])
	autoPopup:SetChecked(self.db.autoPopup)
	autoPopup:SetScript('OnClick', function(self)
		addon.Config.db.autoPopup = self:GetChecked()
	end)

	-- Chat Frame Output checkbox
	local chatFrame = CreateFrame('CheckButton', nil, panel, 'InterfaceOptionsCheckButtonTemplate')
	chatFrame:SetPoint('TOPLEFT', autoPopup, 'BOTTOMLEFT', 0, -8)
	chatFrame.Text:SetText(L['Chat frame output'])
	chatFrame:SetChecked(self.db.chatframe)
	chatFrame:SetScript('OnClick', function(self)
		addon.Config.db.chatframe = self:GetChecked()
	end)

	-- Font Size slider
	local fontSizeSlider = CreateFrame('Slider', nil, panel, 'OptionsSliderTemplate')
	fontSizeSlider:SetPoint('TOPLEFT', chatFrame, 'BOTTOMLEFT', 0, -24)
	fontSizeSlider:SetMinMaxValues(8, 24)
	fontSizeSlider:SetValueStep(1)
	fontSizeSlider:SetObeyStepOnDrag(true)
	fontSizeSlider:SetWidth(200)
	fontSizeSlider.Low:SetText('8')
	fontSizeSlider.High:SetText('24')
	fontSizeSlider.Text:SetText(L['Font Size'])
	fontSizeSlider:SetValue(self.db.fontSize)
	fontSizeSlider:SetScript('OnValueChanged', function(self, value)
		value = math.floor(value + 0.5)
		addon.Config.db.fontSize = value
		-- fontSizeSlider.Text:SetText(L['Font Size'] .. ': ' .. value)
		addon.BugWindow:UpdateFontSize()
	end)

	-- Add a "Reset to Defaults" button
	local defaultsButton = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
	defaultsButton:SetText(L['Reset to Defaults'])
	defaultsButton:SetWidth(150)
	defaultsButton:SetPoint('TOPLEFT', fontSizeSlider, 'BOTTOMLEFT', 0, -16)
	defaultsButton:SetScript('OnClick', function()
		addon.Config:ResetToDefaults()
		autoPopup:SetChecked(self.db.autoPopup)
		chatFrame:SetChecked(self.db.chatframe)
		fontSizeSlider:SetValue(self.db.fontSize)
	end)

	local minimapIconCheckbox = CreateFrame('CheckButton', nil, panel, 'InterfaceOptionsCheckButtonTemplate')
	minimapIconCheckbox:SetPoint('TOPLEFT', defaultsButton, 'BOTTOMLEFT', 0, -16)
	minimapIconCheckbox.Text:SetText(L['Show Minimap Icon'])
	minimapIconCheckbox:SetChecked(not self.db.minimapIcon.hide)
	minimapIconCheckbox:SetScript('OnClick', function(self)
		addon.Config.db.minimapIcon.hide = not self:GetChecked()
		if addon.Config.db.minimapIcon.hide then
			addon.icon:Hide(MinimapIconName)
		else
			addon.icon:Show(MinimapIconName)
		end
	end)

	panel.okay = function()
		-- This method is called when the player clicks "Okay" in the Interface Options
	end

	panel.cancel = function()
		-- This method is called when the player clicks "Cancel" in the Interface Options
		-- Reset to the previous values
		self.db.autoPopup = autoPopup:GetChecked()
		self.db.chatframe = chatFrame:GetChecked()
		self.db.fontSize = fontSizeSlider:GetValue()
	end

	panel.refresh = function()
		-- This method is called when the panel is shown
		autoPopup:SetChecked(self.db.autoPopup)
		chatFrame:SetChecked(self.db.chatframe)
		fontSizeSlider:SetValue(self.db.fontSize)
	end

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	else
		local category, layout = Settings.RegisterCanvasLayoutCategory(panel, 'SpartanUI Bug Handler')
		Settings.RegisterAddOnCategory(category)
		addon.settingsCategory = category
	end
end

function addon.Config:ResetToDefaults()
	SUIErrorHandler = CopyTable(defaults)
	self.db = SUIErrorHandler
	addon.BugWindow:UpdateFontSize()
end

-- Get a specific option
function addon.Config:Get(key)
	return self.db[key]
end

-- Set a specific option
function addon.Config:Set(key, value)
	self.db[key] = value
	if key == 'fontSize' then addon.BugWindow:UpdateFontSize() end
end

-- Register slash command
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
