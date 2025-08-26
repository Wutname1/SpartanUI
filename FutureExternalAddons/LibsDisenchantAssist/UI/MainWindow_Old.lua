local LibsDisenchantAssist = _G.LibsDisenchantAssist

LibsDisenchantAssist.UI = {}
local UI = LibsDisenchantAssist.UI

UI.itemButtons = {}
UI.maxButtons = 20
UI.isOptionsVisible = false

function LibsDisenchantAssistMainFrame_OnLoad(self)
	self:RegisterForDrag('LeftButton')

	-- Set backdrop using BackdropMixin
	if BackdropTemplateMixin then
		Mixin(self, BackdropTemplateMixin)
		self:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileEdge = false,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 }
		})
	end

	self.Title = _G[self:GetName() .. 'Title']
	self.Title:SetText("Lib's - Disenchant Assist")

	self.CloseButton = _G[self:GetName() .. 'CloseButton']
	self.CloseButton:SetScript('OnClick', function()
		self:Hide()
	end)

	self.OptionsButton = _G[self:GetName() .. 'OptionsButton']
	self.OptionsButton.Text = _G[self.OptionsButton:GetName() .. 'Text']
	self.OptionsButton.Text:SetText('Options')
	self.OptionsButton:SetScript('OnClick', function()
		UI:ToggleOptions()
	end)

	self.DisenchantButton = _G[self:GetName() .. 'DisenchantButton']
	self.DisenchantButton.Text = _G[self.DisenchantButton:GetName() .. 'Text']
	self.DisenchantButton.Text:SetText('Disenchant All')
	self.DisenchantButton:SetScript('OnClick', function()
		LibsDisenchantAssist.DisenchantLogic:DisenchantAll()
	end)

	self.ItemCount = _G[self:GetName() .. 'ItemCount']
	self.ScrollFrame = _G[self:GetName() .. 'ScrollFrame']
	self.ItemList = _G[self:GetName() .. 'ScrollFrameItemList']

	self.OptionsPanel = _G[self:GetName() .. 'OptionsPanel']

	UI.frame = self
	
	UI:InitializeOptionsPanel(self)
	UI:CreateItemButtons()
end

function LibsDisenchantAssistMainFrame_OnShow(self)
	UI:RefreshItemList()
	UI:UpdateOptionsFromDB()
end

function UI:InitializeOptionsPanel(mainFrame)
	local panel = mainFrame.OptionsPanel
	
	-- Set options panel backdrop using BackdropMixin
	if BackdropTemplateMixin then
		Mixin(panel, BackdropTemplateMixin)
		panel:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileEdge = false,
			tileSize = 16,
			edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 }
		})
		panel:SetBackdropColor(0, 0, 0, 0.5)
	end

	local excludeTodayCheck = _G[panel:GetName() .. 'ExcludeTodayCheck']
	excludeTodayCheck.Text:SetText("Don't DE items gained today")
	excludeTodayCheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeToday = excludeTodayCheck:GetChecked()
		UI:RefreshItemList()
	end)

	local excludeHigherIlvlCheck = _G[panel:GetName() .. 'ExcludeHigherIlvlCheck']
	excludeHigherIlvlCheck.Text:SetText("Don't DE higher ilvl gear")
	excludeHigherIlvlCheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeHigherIlvl = excludeHigherIlvlCheck:GetChecked()
		UI:RefreshItemList()
	end)

	local excludeGearSetsCheck = _G[panel:GetName() .. 'ExcludeGearSetsCheck']
	excludeGearSetsCheck.Text:SetText("Don't DE gear in sets")
	excludeGearSetsCheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeGearSets = excludeGearSetsCheck:GetChecked()
		UI:RefreshItemList()
	end)

	local excludeWarboundCheck = _G[panel:GetName() .. 'ExcludeWarboundCheck']
	excludeWarboundCheck.Text:SetText("Don't DE warbound gear")
	excludeWarboundCheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeWarbound = excludeWarboundCheck:GetChecked()
		UI:RefreshItemList()
	end)

	local excludeBOECheck = _G[panel:GetName() .. 'ExcludeBOECheck']
	excludeBOECheck.Text:SetText("Don't DE BOE gear")
	excludeBOECheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeBOE = excludeBOECheck:GetChecked()
		UI:RefreshItemList()
	end)

	local minIlvlSlider = _G[panel:GetName() .. 'MinIlvlSlider']
	minIlvlSlider.Text:SetText('Min iLvl')
	minIlvlSlider:SetMinMaxValues(1, 999)
	minIlvlSlider:SetValueStep(1)
	minIlvlSlider:SetScript('OnValueChanged', function(self, value)
		value = math.floor(value + 0.5)
		LibsDisenchantAssistDB.options.minIlvl = value
		_G[self:GetName() .. 'Text']:SetText('Min iLvl: ' .. value)
		UI:RefreshItemList()
	end)

	local maxIlvlSlider = _G[panel:GetName() .. 'MaxIlvlSlider']
	maxIlvlSlider.Text:SetText('Max iLvl')
	maxIlvlSlider:SetMinMaxValues(1, 999)
	maxIlvlSlider:SetValueStep(1)
	maxIlvlSlider:SetScript('OnValueChanged', function(self, value)
		value = math.floor(value + 0.5)
		LibsDisenchantAssistDB.options.maxIlvl = value
		_G[self:GetName() .. 'Text']:SetText('Max iLvl: ' .. value)
		UI:RefreshItemList()
	end)

	panel.excludeTodayCheck = excludeTodayCheck
	panel.excludeHigherIlvlCheck = excludeHigherIlvlCheck
	panel.excludeGearSetsCheck = excludeGearSetsCheck
	panel.excludeWarboundCheck = excludeWarboundCheck
	panel.excludeBOECheck = excludeBOECheck
	panel.minIlvlSlider = minIlvlSlider
	panel.maxIlvlSlider = maxIlvlSlider
end

function UI:CreateItemButtons()
	for i = 1, self.maxButtons do
		local button = CreateFrame('Button', 'LibsDisenchantAssistItemButton' .. i, self.frame.ItemList, 'LibsDisenchantAssistItemButtonTemplate')

		button.Icon = _G[button:GetName() .. 'Icon']
		button.Name = _G[button:GetName() .. 'Name']
		button.Ilvl = _G[button:GetName() .. 'Ilvl']
		button.Date = _G[button:GetName() .. 'Date']
		button.Background = _G[button:GetName() .. 'Background']

		if i == 1 then
			button:SetPoint('TOPLEFT', 0, 0)
		else
			button:SetPoint('TOPLEFT', self.itemButtons[i - 1], 'BOTTOMLEFT', 0, -2)
		end

		button:Hide()
		self.itemButtons[i] = button
	end
end

function UI:ToggleOptions()
	self.isOptionsVisible = not self.isOptionsVisible

	if self.isOptionsVisible then
		UI.frame.OptionsPanel:Show()
		UI.frame:SetHeight(720)
		UI.frame.ScrollFrame:SetPoint('TOPLEFT', 20, -345)
		UI.frame.ScrollFrame:SetHeight(230)
	else
		UI.frame.OptionsPanel:Hide()
		UI.frame:SetHeight(600)
		UI.frame.ScrollFrame:SetPoint('TOPLEFT', 20, -225)
		UI.frame.ScrollFrame:SetHeight(350)
	end
end

function UI:UpdateOptionsFromDB()
	local options = LibsDisenchantAssistDB.options
	local panel = UI.frame.OptionsPanel

	panel.excludeTodayCheck:SetChecked(options.excludeToday)
	panel.excludeHigherIlvlCheck:SetChecked(options.excludeHigherIlvl)
	panel.excludeGearSetsCheck:SetChecked(options.excludeGearSets)
	panel.excludeWarboundCheck:SetChecked(options.excludeWarbound)
	panel.excludeBOECheck:SetChecked(options.excludeBOE)

	panel.minIlvlSlider:SetValue(options.minIlvl)
	panel.maxIlvlSlider:SetValue(options.maxIlvl)

	_G[panel.minIlvlSlider:GetName() .. 'Text']:SetText('Min iLvl: ' .. options.minIlvl)
	_G[panel.maxIlvlSlider:GetName() .. 'Text']:SetText('Max iLvl: ' .. options.maxIlvl)
end

function UI:RefreshItemList()
	if not UI.frame or not UI.frame:IsVisible() then return end

	local items = LibsDisenchantAssist.FilterSystem:GetDisenchantableItems()

	for i = 1, self.maxButtons do
		local button = self.itemButtons[i]
		if items[i] then
			local item = items[i]
			button.item = item

			local icon = C_Item.GetItemIconByID(item.itemID)
			button.Icon:SetTexture(icon)

			local r, g, b = C_Item.GetItemQualityColor(item.quality)
			button.Name:SetText(item.itemName)
			button.Name:SetTextColor(r, g, b)

			button.Ilvl:SetText('iLvl: ' .. item.itemLevel)
			button.Date:SetText(item.firstSeen)

			if i % 2 == 0 then
				button.Background:SetColorTexture(0.1, 0.1, 0.1, 0.5)
			else
				button.Background:SetColorTexture(0, 0, 0, 0.5)
			end

			button:Show()
		else
			button:Hide()
			button.item = nil
		end
	end

	local totalHeight = math.max(#items * 22, 1)
	UI.frame.ItemList:SetHeight(totalHeight)

	UI.frame.ItemCount:SetText('Items to disenchant: ' .. #items)

	if #items > self.maxButtons then
		UI.frame.ScrollFrame:Show()
	else
		UI.frame.ScrollFrame.ScrollBar:Hide()
	end
end

function LibsDisenchantAssistItemButton_OnEnter(self)
	if self.item then
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetBagItem(self.item.bag, self.item.slot)
		GameTooltip:Show()
	end
end

function UI:Show()
	if not UI.frame then return end
	UI.frame:Show()
end

function UI:Hide()
	if not UI.frame then return end
	UI.frame:Hide()
end

function UI:Toggle()
	if UI.frame and UI.frame:IsVisible() then
		UI:Hide()
	else
		UI:Show()
	end
end
