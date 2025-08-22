---@diagnostic disable: duplicate-set-field
--[===[ File: Developer/PluginWizard.lua
LibsDataBar Interactive Plugin Development Wizard
Rapid plugin creation with guided interface
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- AceGUI for interactive interface
local AceGUI = LibStub('AceGUI-3.0', true)
if not AceGUI then
	LibsDataBar:DebugLog('error', 'PluginWizard requires AceGUI-3.0')
	return
end

---@class PluginWizard
---@field currentStep number Current wizard step
---@field pluginData table Plugin configuration data
---@field wizardFrame AceGUIFrame|nil Active wizard frame
local PluginWizard = {}

-- Initialize Plugin Wizard for LibsDataBar
LibsDataBar.wizard = LibsDataBar.wizard or setmetatable({
	currentStep = 1,
	pluginData = {},
	wizardFrame = nil,
}, { __index = PluginWizard })

-- Wizard steps configuration
local WIZARD_STEPS = {
	{
		id = 'basic',
		title = 'Basic Information',
		description = 'Enter basic plugin information',
		fields = {
			{ name = 'name', label = 'Plugin Name', type = 'editbox', required = true, placeholder = 'My Awesome Plugin' },
			{ name = 'description', label = 'Description', type = 'multilineeditbox', required = true, placeholder = 'Brief description of what your plugin does' },
			{ name = 'author', label = 'Author', type = 'editbox', required = true, placeholder = 'Your Name' },
			{ name = 'version', label = 'Version', type = 'editbox', required = true, default = '1.0.0', placeholder = '1.0.0' },
			{
				name = 'category',
				label = 'Category',
				type = 'dropdown',
				required = true,
				values = {
					['Information'] = 'Information',
					['System'] = 'System',
					['Social'] = 'Social',
					['Character'] = 'Character',
					['Game'] = 'Game',
					['Utility'] = 'Utility',
					['Custom'] = 'Custom',
				},
				default = 'Information',
			},
		},
	},
	{
		id = 'type',
		title = 'Plugin Type',
		description = 'Choose the type of plugin to create',
		fields = {
			{
				name = 'pluginType',
				label = 'Plugin Type',
				type = 'radio',
				required = true,
				values = {
					['native'] = { text = 'Native LibsDataBar Plugin', desc = 'Full-featured plugin with complete LibsDataBar integration' },
					['ldb'] = { text = 'LibDataBroker Plugin', desc = 'Compatible with all LDB display addons' },
				},
				default = 'native',
			},
		},
	},
	{
		id = 'features',
		title = 'Plugin Features',
		description = 'Select the features your plugin will have',
		fields = {
			{ name = 'hasIcon', label = 'Display Icon', type = 'checkbox', default = true },
			{ name = 'hasTooltip', label = 'Custom Tooltip', type = 'checkbox', default = true },
			{ name = 'hasClick', label = 'Click Handling', type = 'checkbox', default = true },
			{ name = 'hasConfig', label = 'Configuration Options', type = 'checkbox', default = true },
			{ name = 'hasTimer', label = 'Auto-Update Timer', type = 'checkbox', default = true },
			{ name = 'hasEvents', label = 'WoW Event Handling', type = 'checkbox', default = false },
		},
	},
	{
		id = 'customization',
		title = 'Customization',
		description = 'Customize your plugin',
		fields = {
			{
				name = 'iconPath',
				label = 'Icon Path',
				type = 'editbox',
				default = 'Interface\\Icons\\INV_Misc_QuestionMark',
				placeholder = 'Interface\\Icons\\INV_Misc_QuestionMark',
			},
			{ name = 'updateInterval', label = 'Update Interval (seconds)', type = 'slider', min = 0.1, max = 10, step = 0.1, default = 1.0 },
			{ name = 'defaultText', label = 'Default Display Text', type = 'editbox', default = 'Plugin Text', placeholder = 'Text to display' },
		},
	},
	{
		id = 'review',
		title = 'Review & Generate',
		description = 'Review your plugin configuration and generate code',
		fields = {},
	},
}

---Initialize the plugin wizard
function PluginWizard:Initialize()
	LibsDataBar:DebugLog('info', 'PluginWizard initialized')
end

---Show the plugin wizard
function PluginWizard:Show()
	if self.wizardFrame then
		self.wizardFrame:Hide()
		self.wizardFrame = nil
	end

	-- Reset wizard state
	self.currentStep = 1
	self.pluginData = {}

	-- Create main wizard frame
	self.wizardFrame = AceGUI:Create('Frame')
	self.wizardFrame:SetTitle('LibsDataBar Plugin Wizard')
	self.wizardFrame:SetStatusText('Step 1 of ' .. #WIZARD_STEPS)
	self.wizardFrame:SetLayout('Flow')
	self.wizardFrame:SetWidth(600)
	self.wizardFrame:SetHeight(500)

	-- Center the frame
	self.wizardFrame:SetCallback('OnClose', function(widget)
		self:Hide()
	end)

	-- Show first step
	self:ShowStep(1)
end

---Hide the plugin wizard
function PluginWizard:Hide()
	if self.wizardFrame then
		AceGUI:Release(self.wizardFrame)
		self.wizardFrame = nil
	end
end

---Show a specific wizard step
---@param stepNumber number The step to show
function PluginWizard:ShowStep(stepNumber)
	if not self.wizardFrame then return end

	local step = WIZARD_STEPS[stepNumber]
	if not step then return end

	self.currentStep = stepNumber

	-- Clear existing content
	self.wizardFrame:ReleaseChildren()

	-- Update status
	self.wizardFrame:SetStatusText('Step ' .. stepNumber .. ' of ' .. #WIZARD_STEPS .. ' - ' .. step.title)

	-- Create step header
	local header = AceGUI:Create('Heading')
	header:SetText(step.title)
	header:SetFullWidth(true)
	self.wizardFrame:AddChild(header)

	local description = AceGUI:Create('Label')
	description:SetText(step.description)
	description:SetFullWidth(true)
	self.wizardFrame:AddChild(description)

	-- Add spacing
	local spacer = AceGUI:Create('Label')
	spacer:SetText(' ')
	spacer:SetFullWidth(true)
	self.wizardFrame:AddChild(spacer)

	-- Create fields for this step
	if step.id == 'review' then
		self:ShowReviewStep()
	else
		self:CreateStepFields(step)
	end

	-- Create navigation buttons
	self:CreateNavigationButtons()
end

---Create fields for a wizard step
---@param step table Step configuration
function PluginWizard:CreateStepFields(step)
	for _, field in ipairs(step.fields) do
		local widget = self:CreateFieldWidget(field)
		if widget then self.wizardFrame:AddChild(widget) end
	end
end

---Create a widget for a field
---@param field table Field configuration
---@return AceGUIWidget|nil widget Created widget
function PluginWizard:CreateFieldWidget(field)
	local widget = nil

	if field.type == 'editbox' then
		widget = AceGUI:Create('EditBox')
		widget:SetLabel(field.label)
		widget:SetText(self.pluginData[field.name] or field.default or '')
		if field.placeholder then widget:SetLabel(field.label .. ' (' .. field.placeholder .. ')') end
		widget:SetCallback('OnTextChanged', function(w, event, text)
			self.pluginData[field.name] = text
		end)
	elseif field.type == 'multilineeditbox' then
		widget = AceGUI:Create('MultiLineEditBox')
		widget:SetLabel(field.label)
		widget:SetText(self.pluginData[field.name] or field.default or '')
		widget:SetNumLines(3)
		widget:SetCallback('OnTextChanged', function(w, event, text)
			self.pluginData[field.name] = text
		end)
	elseif field.type == 'dropdown' then
		widget = AceGUI:Create('Dropdown')
		widget:SetLabel(field.label)
		widget:SetList(field.values)
		widget:SetValue(self.pluginData[field.name] or field.default)
		widget:SetCallback('OnValueChanged', function(w, event, value)
			self.pluginData[field.name] = value
		end)
	elseif field.type == 'checkbox' then
		widget = AceGUI:Create('CheckBox')
		widget:SetLabel(field.label)
		widget:SetValue(self.pluginData[field.name] ~= nil and self.pluginData[field.name] or field.default)
		widget:SetCallback('OnValueChanged', function(w, event, value)
			self.pluginData[field.name] = value
		end)
	elseif field.type == 'radio' then
		local group = AceGUI:Create('SimpleGroup')
		group:SetLayout('Flow')
		group:SetFullWidth(true)

		local label = AceGUI:Create('Label')
		label:SetText(field.label)
		label:SetFullWidth(true)
		group:AddChild(label)

		for value, config in pairs(field.values) do
			local radio = AceGUI:Create('CheckBox')
			radio:SetType('radio')
			radio:SetLabel(config.text)
			radio:SetDescription(config.desc)
			radio:SetValue((self.pluginData[field.name] or field.default) == value)
			radio:SetCallback('OnValueChanged', function(w, event, checked)
				if checked then
					self.pluginData[field.name] = value
					-- Uncheck other radios
					for _, child in ipairs(group.children) do
						if child ~= radio and child.SetValue then child:SetValue(false) end
					end
				end
			end)
			group:AddChild(radio)
		end

		widget = group
	elseif field.type == 'slider' then
		widget = AceGUI:Create('Slider')
		widget:SetLabel(field.label)
		widget:SetSliderValues(field.min, field.max, field.step)
		widget:SetValue(self.pluginData[field.name] or field.default)
		widget:SetCallback('OnValueChanged', function(w, event, value)
			self.pluginData[field.name] = value
		end)
	end

	if widget then widget:SetFullWidth(true) end

	return widget
end

---Show the review step
function PluginWizard:ShowReviewStep()
	-- Generate plugin preview
	local config = self:BuildPluginConfig()

	-- Show configuration summary
	local summaryGroup = AceGUI:Create('SimpleGroup')
	summaryGroup:SetLayout('Flow')
	summaryGroup:SetFullWidth(true)

	local summaryLabel = AceGUI:Create('Label')
	summaryLabel:SetText('Plugin Configuration:')
	summaryLabel:SetFullWidth(true)
	summaryGroup:AddChild(summaryLabel)

	local summary = AceGUI:Create('MultiLineEditBox')
	summary:SetLabel('Configuration Summary')
	summary:SetText(self:GenerateConfigSummary(config))
	summary:SetNumLines(8)
	summary:DisableButton(true)
	summary:SetFullWidth(true)
	summaryGroup:AddChild(summary)

	self.wizardFrame:AddChild(summaryGroup)

	-- Generate button
	local generateGroup = AceGUI:Create('SimpleGroup')
	generateGroup:SetLayout('Flow')
	generateGroup:SetFullWidth(true)

	local generateBtn = AceGUI:Create('Button')
	generateBtn:SetText('Generate Plugin Code')
	generateBtn:SetWidth(200)
	generateBtn:SetCallback('OnClick', function()
		self:GeneratePlugin()
	end)
	generateGroup:AddChild(generateBtn)

	local saveBtn = AceGUI:Create('Button')
	saveBtn:SetText('Save Configuration')
	saveBtn:SetWidth(200)
	saveBtn:SetCallback('OnClick', function()
		self:SaveConfiguration()
	end)
	generateGroup:AddChild(saveBtn)

	self.wizardFrame:AddChild(generateGroup)
end

---Create navigation buttons
function PluginWizard:CreateNavigationButtons()
	local buttonGroup = AceGUI:Create('SimpleGroup')
	buttonGroup:SetLayout('Flow')
	buttonGroup:SetFullWidth(true)

	-- Previous button
	if self.currentStep > 1 then
		local prevBtn = AceGUI:Create('Button')
		prevBtn:SetText('Previous')
		prevBtn:SetWidth(100)
		prevBtn:SetCallback('OnClick', function()
			self:ShowStep(self.currentStep - 1)
		end)
		buttonGroup:AddChild(prevBtn)
	end

	-- Next/Finish button
	if self.currentStep < #WIZARD_STEPS then
		local nextBtn = AceGUI:Create('Button')
		nextBtn:SetText('Next')
		nextBtn:SetWidth(100)
		nextBtn:SetCallback('OnClick', function()
			if self:ValidateCurrentStep() then self:ShowStep(self.currentStep + 1) end
		end)
		buttonGroup:AddChild(nextBtn)
	end

	-- Cancel button
	local cancelBtn = AceGUI:Create('Button')
	cancelBtn:SetText('Cancel')
	cancelBtn:SetWidth(100)
	cancelBtn:SetCallback('OnClick', function()
		self:Hide()
	end)
	buttonGroup:AddChild(cancelBtn)

	self.wizardFrame:AddChild(buttonGroup)
end

---Validate current step data
---@return boolean isValid Whether the current step is valid
function PluginWizard:ValidateCurrentStep()
	local step = WIZARD_STEPS[self.currentStep]
	if not step then return false end

	local errors = {}

	for _, field in ipairs(step.fields) do
		if field.required then
			local value = self.pluginData[field.name]
			if not value or value == '' then table.insert(errors, field.label .. ' is required') end
		end
	end

	if #errors > 0 then
		local message = 'Please fix the following errors:\n' .. table.concat(errors, '\n')
		print('LibsDataBar Wizard: ' .. message)
		return false
	end

	return true
end

---Build plugin configuration from wizard data
---@return table config Plugin configuration
function PluginWizard:BuildPluginConfig()
	local config = {}

	-- Basic information
	config.name = self.pluginData.name or 'MyPlugin'
	config.description = self.pluginData.description or 'A LibsDataBar plugin'
	config.author = self.pluginData.author or 'Plugin Developer'
	config.version = self.pluginData.version or '1.0.0'
	config.category = self.pluginData.category or 'Information'

	-- Plugin type
	config.pluginType = self.pluginData.pluginType or 'native'

	-- Features
	config.hasIcon = self.pluginData.hasIcon
	config.hasTooltip = self.pluginData.hasTooltip
	config.hasClick = self.pluginData.hasClick
	config.hasConfig = self.pluginData.hasConfig
	config.hasTimer = self.pluginData.hasTimer
	config.hasEvents = self.pluginData.hasEvents

	-- Customization
	config.iconPath = self.pluginData.iconPath or 'Interface\\Icons\\INV_Misc_QuestionMark'
	config.updateInterval = self.pluginData.updateInterval or 1.0
	config.defaultText = self.pluginData.defaultText or 'Plugin Text'

	-- Generated fields
	config.className = config.name:gsub('%s', '') .. 'Plugin'
	config.id = 'LibsDataBar_' .. config.name:gsub('%s', '')
	config.variableName = config.name:lower():gsub('%s', '')

	return config
end

---Generate configuration summary
---@param config table Plugin configuration
---@return string summary Configuration summary text
function PluginWizard:GenerateConfigSummary(config)
	local lines = {
		'Plugin Name: ' .. config.name,
		'Type: ' .. (config.pluginType == 'native' and 'Native LibsDataBar' or 'LibDataBroker'),
		'Author: ' .. config.author,
		'Version: ' .. config.version,
		'Category: ' .. config.category,
		'',
		'Features:',
		'  Icon: ' .. (config.hasIcon and 'Yes' or 'No'),
		'  Tooltip: ' .. (config.hasTooltip and 'Yes' or 'No'),
		'  Click Handling: ' .. (config.hasClick and 'Yes' or 'No'),
		'  Configuration: ' .. (config.hasConfig and 'Yes' or 'No'),
		'  Auto-Update: ' .. (config.hasTimer and 'Yes' or 'No'),
		'  Event Handling: ' .. (config.hasEvents and 'Yes' or 'No'),
		'',
		'Settings:',
		'  Icon Path: ' .. config.iconPath,
		'  Update Interval: ' .. config.updateInterval .. 's',
		'  Default Text: ' .. config.defaultText,
	}

	return table.concat(lines, '\n')
end

---Generate the plugin code
function PluginWizard:GeneratePlugin()
	local config = self:BuildPluginConfig()

	-- Generate code using templates
	local code
	if config.pluginType == 'native' then
		code = LibsDataBar.templates:GenerateNativePlugin(config)
	else
		code = LibsDataBar.templates:GenerateLDBPlugin(config)
	end

	-- Show code in a window
	self:ShowGeneratedCode(code, config)
end

---Show generated plugin code
---@param code string Generated plugin code
---@param config table Plugin configuration
function PluginWizard:ShowGeneratedCode(code, config)
	local codeFrame = AceGUI:Create('Frame')
	codeFrame:SetTitle('Generated Plugin: ' .. config.name)
	codeFrame:SetLayout('Fill')
	codeFrame:SetWidth(800)
	codeFrame:SetHeight(600)

	local codeBox = AceGUI:Create('MultiLineEditBox')
	codeBox:SetLabel('Plugin Code (Copy this to your plugin file)')
	codeBox:SetText(code)
	codeBox:SetNumLines(25)
	codeBox:SetFullWidth(true)
	codeBox:SetFullHeight(true)
	codeFrame:AddChild(codeBox)

	-- Focus text for easy copying
	codeBox:SetFocus()
	codeBox:HighlightText()

	print('LibsDataBar: Plugin code generated! Copy the code from the window and save it as ' .. config.className .. '.lua')
end

---Save wizard configuration
function PluginWizard:SaveConfiguration()
	local config = self:BuildPluginConfig()
	-- This could save to SavedVariables for later use
	print('LibsDataBar: Configuration saved for plugin: ' .. config.name)
end

---Add slash command for wizard
SLASH_LIBSDATABAR_WIZARD1 = '/ldb-wizard'
SLASH_LIBSDATABAR_WIZARD2 = '/libsdatabar-wizard'
SlashCmdList['LIBSDATABAR_WIZARD'] = function(msg)
	LibsDataBar.wizard:Show()
end

-- Initialize when templates are available
if LibsDataBar.templates then
	LibsDataBar.wizard:Initialize()
else
	local frame = CreateFrame('Frame')
	frame:RegisterEvent('ADDON_LOADED')
	frame:SetScript('OnEvent', function(self, event, addonName)
		if LibsDataBar.templates then
			LibsDataBar.wizard:Initialize()
			self:UnregisterAllEvents()
		end
	end)
end

LibsDataBar:DebugLog('info', 'PluginWizard loaded successfully')
