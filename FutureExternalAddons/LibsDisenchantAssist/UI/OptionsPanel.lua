local LibsDisenchantAssist = _G.LibsDisenchantAssist

LibsDisenchantAssist.OptionsPanel = {}
local OptionsPanel = LibsDisenchantAssist.OptionsPanel

function OptionsPanel:Initialize()
	local panel = CreateFrame('Frame', 'LibsDisenchantAssistOptionsPanel', InterfaceOptionsFramePanelContainer)
	panel.name = "Lib's - Disenchant Assist"
	panel:Hide()

	panel:SetScript('OnShow', function()
		OptionsPanel:CreateOptions(panel)
		panel:SetScript('OnShow', nil)
	end)

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	elseif Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
		Settings.RegisterAddOnCategory(category)
	end
	self.panel = panel
end

function OptionsPanel:CreateOptions(panel)
	local title = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
	title:SetPoint('TOPLEFT', 16, -16)
	title:SetText("Lib's - Disenchant Assist")

	local subtitle = panel:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
	subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -8)
	subtitle:SetText('Smart disenchanting with advanced filtering options')

	local enabledCheck = CreateFrame('CheckButton', 'LibsDAOptionsEnabled', panel, 'InterfaceOptionsCheckButtonTemplate')
	enabledCheck:SetPoint('TOPLEFT', subtitle, 'BOTTOMLEFT', 0, -20)
	enabledCheck.Text:SetText('Enable Disenchant Assist')
	enabledCheck:SetScript('OnClick', function()
		LibsDisenchantAssist.DB.enabled = enabledCheck:GetChecked()
	end)

	local excludeTodayCheck = CreateFrame('CheckButton', 'LibsDAOptionsExcludeToday', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeTodayCheck:SetPoint('TOPLEFT', enabledCheck, 'BOTTOMLEFT', 0, -10)
	excludeTodayCheck.Text:SetText("Don't disenchant items gained today")
	excludeTodayCheck:SetScript('OnClick', function()
		LibsDisenchantAssist.DB.excludeToday = excludeTodayCheck:GetChecked()
	end)

	local excludeHigherIlvlCheck = CreateFrame('CheckButton', 'LibsDAOptionsExcludeHigher', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeHigherIlvlCheck:SetPoint('TOPLEFT', excludeTodayCheck, 'BOTTOMLEFT', 0, -10)
	excludeHigherIlvlCheck.Text:SetText("Don't disenchant gear with higher item level than equipped")
	excludeHigherIlvlCheck:SetScript('OnClick', function()
		LibsDisenchantAssist.DB.excludeHigherIlvl = excludeHigherIlvlCheck:GetChecked()
	end)

	local excludeGearSetsCheck = CreateFrame('CheckButton', 'LibsDAOptionsExcludeGearSets', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeGearSetsCheck:SetPoint('TOPLEFT', excludeHigherIlvlCheck, 'BOTTOMLEFT', 0, -10)
	excludeGearSetsCheck.Text:SetText("Don't disenchant gear in equipment sets")
	excludeGearSetsCheck:SetScript('OnClick', function()
		LibsDisenchantAssist.DB.excludeGearSets = excludeGearSetsCheck:GetChecked()
	end)

	local excludeWarboundCheck = CreateFrame('CheckButton', 'LibsDAOptionsExcludeWarbound', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeWarboundCheck:SetPoint('TOPLEFT', excludeGearSetsCheck, 'BOTTOMLEFT', 0, -10)
	excludeWarboundCheck.Text:SetText("Don't disenchant warbound gear")
	excludeWarboundCheck:SetScript('OnClick', function()
		LibsDisenchantAssist.DB.excludeWarbound = excludeWarboundCheck:GetChecked()
	end)

	local excludeBOECheck = CreateFrame('CheckButton', 'LibsDAOptionsExcludeBOE', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeBOECheck:SetPoint('TOPLEFT', excludeWarboundCheck, 'BOTTOMLEFT', 0, -10)
	excludeBOECheck.Text:SetText("Don't disenchant Bind on Equip gear")
	excludeBOECheck:SetScript('OnClick', function()
		LibsDisenchantAssist.DB.excludeBOE = excludeBOECheck:GetChecked()
	end)

	local confirmCheck = CreateFrame('CheckButton', 'LibsDAOptionsConfirm', panel, 'InterfaceOptionsCheckButtonTemplate')
	confirmCheck:SetPoint('TOPLEFT', excludeBOECheck, 'BOTTOMLEFT', 0, -10)
	confirmCheck.Text:SetText('Confirm before disenchanting')
	confirmCheck:SetScript('OnClick', function()
		LibsDisenchantAssist.DB.confirmDisenchant = confirmCheck:GetChecked()
	end)

	local minIlvlLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	minIlvlLabel:SetPoint('TOPLEFT', confirmCheck, 'BOTTOMLEFT', 0, -25)
	minIlvlLabel:SetText('Minimum Item Level:')

	local minIlvlSlider = CreateFrame('Slider', 'LibsDAOptionsMinIlvlSlider', panel, 'OptionsSliderTemplate')
	minIlvlSlider:SetPoint('TOPLEFT', minIlvlLabel, 'BOTTOMLEFT', 15, -10)
	minIlvlSlider:SetWidth(200)
	minIlvlSlider:SetMinMaxValues(1, 999)
	minIlvlSlider:SetValueStep(1)
	minIlvlSlider:SetScript('OnValueChanged', function(self, value)
		value = math.floor(value + 0.5)
		LibsDisenchantAssist.DB.minIlvl = value
		_G[self:GetName() .. 'Text']:SetText('Min iLvl: ' .. value)
	end)
	_G[minIlvlSlider:GetName() .. 'Low']:SetText('1')
	_G[minIlvlSlider:GetName() .. 'High']:SetText('999')
	_G[minIlvlSlider:GetName() .. 'Text']:SetText('Min iLvl')

	local maxIlvlLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	maxIlvlLabel:SetPoint('TOPLEFT', minIlvlSlider, 'BOTTOMLEFT', -15, -25)
	maxIlvlLabel:SetText('Maximum Item Level:')

	local maxIlvlSlider = CreateFrame('Slider', 'LibsDAOptionsMaxIlvlSlider', panel, 'OptionsSliderTemplate')
	maxIlvlSlider:SetPoint('TOPLEFT', maxIlvlLabel, 'BOTTOMLEFT', 15, -10)
	maxIlvlSlider:SetWidth(200)
	maxIlvlSlider:SetMinMaxValues(1, 999)
	maxIlvlSlider:SetValueStep(1)
	maxIlvlSlider:SetScript('OnValueChanged', function(self, value)
		value = math.floor(value + 0.5)
		LibsDisenchantAssist.DB.maxIlvl = value
		_G[self:GetName() .. 'Text']:SetText('Max iLvl: ' .. value)
	end)
	_G[maxIlvlSlider:GetName() .. 'Low']:SetText('1')
	_G[maxIlvlSlider:GetName() .. 'High']:SetText('999')
	_G[maxIlvlSlider:GetName() .. 'Text']:SetText('Max iLvl')

	local openWindowButton = CreateFrame('Button', 'LibsDAOptionsOpenWindow', panel, 'UIPanelButtonTemplate')
	openWindowButton:SetPoint('TOPLEFT', maxIlvlSlider, 'BOTTOMLEFT', -15, -40)
	openWindowButton:SetSize(150, 22)
	openWindowButton:SetText('Open Main Window')
	openWindowButton:SetScript('OnClick', function()
		if LibsDisenchantAssist.UI then LibsDisenchantAssist.UI:Show() end
	end)

	panel.refresh = function()
		OptionsPanel:RefreshOptions(panel)
	end

	OptionsPanel:RefreshOptions(panel)
end

function OptionsPanel:RefreshOptions(panel)
	if not LibsDisenchantAssist.DB then return end

	local options = LibsDisenchantAssist.DB

	_G['LibsDAOptionsEnabled']:SetChecked(options.enabled)
	_G['LibsDAOptionsExcludeToday']:SetChecked(options.excludeToday)
	_G['LibsDAOptionsExcludeHigher']:SetChecked(options.excludeHigherIlvl)
	_G['LibsDAOptionsExcludeGearSets']:SetChecked(options.excludeGearSets)
	_G['LibsDAOptionsExcludeWarbound']:SetChecked(options.excludeWarbound)
	_G['LibsDAOptionsExcludeBOE']:SetChecked(options.excludeBOE)
	_G['LibsDAOptionsConfirm']:SetChecked(options.confirmDisenchant)

	_G['LibsDAOptionsMinIlvlSlider']:SetValue(options.minIlvl)
	_G['LibsDAOptionsMaxIlvlSlider']:SetValue(options.maxIlvl)

	_G['LibsDAOptionsMinIlvlSliderText']:SetText('Min iLvl: ' .. options.minIlvl)
	_G['LibsDAOptionsMaxIlvlSliderText']:SetText('Max iLvl: ' .. options.maxIlvl)
end
