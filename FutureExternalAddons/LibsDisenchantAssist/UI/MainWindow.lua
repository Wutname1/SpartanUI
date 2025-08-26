---@class LibsDisenchantAssist
local LibsDisenchantAssist = _G.LibsDisenchantAssist

---@class UI
LibsDisenchantAssist.UI = {}
local UI = LibsDisenchantAssist.UI

UI.itemButtons = {}
UI.maxButtons = 20
UI.isOptionsVisible = false

-- SpartanUI-style button creation (based on bug system)
function UI:CreateSUIButton(parent, text, width, height)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(width or 120, height or 25)

	-- Use auction house button styling (SpartanUI standard)
	button:SetNormalAtlas('auctionhouse-nav-button')
	button:SetHighlightAtlas('auctionhouse-nav-button-highlight')
	button:SetPushedAtlas('auctionhouse-nav-button-select')
	button:SetDisabledAtlas('UI-CastingBar-TextBox')

	local normalTexture = button:GetNormalTexture()
	if normalTexture then normalTexture:SetTexCoord(0, 1, 0, 0.7) end

	-- Button text
	button.Text = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	button.Text:SetPoint('CENTER')
	button.Text:SetText(text)
	button.Text:SetTextColor(1, 1, 1, 1)

	-- Disabled state styling
	button:HookScript('OnDisable', function(self)
		self.Text:SetTextColor(0.6, 0.6, 0.6, 0.6)
	end)

	button:HookScript('OnEnable', function(self)
		self.Text:SetTextColor(1, 1, 1, 1)
	end)

	return button
end

function UI:CreateMainFrame()
	-- Use SpartanUI's SettingsFrameTemplate for consistent styling
	local frame = CreateFrame('Frame', 'LibsDisenchantAssistMainFrame', UIParent, 'SettingsFrameTemplate')
	frame:SetFrameStrata('FULLSCREEN')
	frame:SetFrameLevel(600)
	frame:SetSize(450, 600)
	frame:SetPoint('CENTER')
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	frame:SetClampedToScreen(true)
	frame:SetDontSavePosition(true)
	frame:Hide()

	-- Make draggable (SpartanUI style)
	frame:EnableMouse(true)
	frame:SetScript('OnMouseDown', function(self, button)
		if button == 'LeftButton' then self:StartMoving() end
	end)
	frame:SetScript('OnMouseUp', function(self, button)
		self:StopMovingOrSizing()
	end)

	self.frame = frame
	return frame
end

function UI:CreateTitleBar()
	local frame = self.frame

	-- Title text
	local title = frame:CreateFontString('LibsDisenchantAssistMainFrameTitle', 'ARTWORK', 'GameFontNormal')
	title:SetPoint('TOP', 0, -16)
	title:SetText("Lib's - Disenchant Assist")
	frame.Title = title

	-- Close button
	local closeButton = CreateFrame('Button', 'LibsDisenchantAssistMainFrameCloseButton', frame, 'UIPanelCloseButton')
	closeButton:SetPoint('TOPRIGHT', -5, -5)
	frame.CloseButton = closeButton
end

function UI:CreateControlButtons()
	local frame = self.frame

	-- Options button (SpartanUI AH style)
	local optionsButton = self:CreateSUIButton(frame, 'Options', 80, 25)
	optionsButton:SetPoint('TOPLEFT', 15, -45)
	optionsButton:SetScript('OnClick', function()
		self:ToggleOptions()
	end)
	frame.OptionsButton = optionsButton

	-- Disenchant button (SpartanUI AH style)
	local disenchantButton = self:CreateSUIButton(frame, 'Disenchant All', 100, 25)
	disenchantButton:SetPoint('TOPRIGHT', -15, -45)
	disenchantButton:SetScript('OnClick', function()
		LibsDisenchantAssist.DisenchantLogic:DisenchantAll()
	end)
	frame.DisenchantButton = disenchantButton

	-- Item count display
	local itemCount = frame:CreateFontString('LibsDisenchantAssistMainFrameItemCount', 'ARTWORK', 'GameFontHighlight')
	itemCount:SetPoint('TOP', 0, -75)
	itemCount:SetText('Items to disenchant: 0')
	itemCount:SetTextColor(1, 1, 1, 1)
	frame.ItemCount = itemCount
end

function UI:CreateOptionsPanel()
	local frame = self.frame

	-- Options panel frame (dark SpartanUI styling)
	local panel = CreateFrame('Frame', 'LibsDisenchantAssistMainFrameOptionsPanel', frame)
	panel:SetSize(410, 120)
	panel:SetPoint('TOPLEFT', 20, -95)
	panel:Hide()

	-- Dark backdrop for SpartanUI consistency
	if BackdropTemplateMixin then
		Mixin(panel, BackdropTemplateMixin)
		panel:SetBackdrop({
			bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
			edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
			tile = true,
			tileEdge = false,
			tileSize = 16,
			edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		panel:SetBackdropColor(0.1, 0.1, 0.1, 0.9) -- Dark background
		panel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1) -- Dark border
	end

	frame.OptionsPanel = panel
	self:CreateOptionsPanelControls(panel)
end

function UI:CreateOptionsPanelControls(panel)
	-- Exclude today checkbox
	local excludeTodayCheck = CreateFrame('CheckButton', panel:GetName() .. 'ExcludeTodayCheck', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeTodayCheck:SetPoint('TOPLEFT', 10, -10)
	excludeTodayCheck.Text:SetText("Don't DE items gained today")
	excludeTodayCheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeToday = excludeTodayCheck:GetChecked()
		self:RefreshItemList()
	end)
	panel.excludeTodayCheck = excludeTodayCheck

	-- Exclude higher ilvl checkbox
	local excludeHigherIlvlCheck = CreateFrame('CheckButton', panel:GetName() .. 'ExcludeHigherIlvlCheck', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeHigherIlvlCheck:SetPoint('TOPLEFT', 10, -35)
	excludeHigherIlvlCheck.Text:SetText("Don't DE higher ilvl gear")
	excludeHigherIlvlCheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeHigherIlvl = excludeHigherIlvlCheck:GetChecked()
		self:RefreshItemList()
	end)
	panel.excludeHigherIlvlCheck = excludeHigherIlvlCheck

	-- Exclude gear sets checkbox
	local excludeGearSetsCheck = CreateFrame('CheckButton', panel:GetName() .. 'ExcludeGearSetsCheck', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeGearSetsCheck:SetPoint('TOPLEFT', 10, -60)
	excludeGearSetsCheck.Text:SetText("Don't DE gear in sets")
	excludeGearSetsCheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeGearSets = excludeGearSetsCheck:GetChecked()
		self:RefreshItemList()
	end)
	panel.excludeGearSetsCheck = excludeGearSetsCheck

	-- Exclude warbound checkbox
	local excludeWarboundCheck = CreateFrame('CheckButton', panel:GetName() .. 'ExcludeWarboundCheck', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeWarboundCheck:SetPoint('TOPLEFT', 210, -10)
	excludeWarboundCheck.Text:SetText("Don't DE warbound gear")
	excludeWarboundCheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeWarbound = excludeWarboundCheck:GetChecked()
		self:RefreshItemList()
	end)
	panel.excludeWarboundCheck = excludeWarboundCheck

	-- Exclude BOE checkbox
	local excludeBOECheck = CreateFrame('CheckButton', panel:GetName() .. 'ExcludeBOECheck', panel, 'InterfaceOptionsCheckButtonTemplate')
	excludeBOECheck:SetPoint('TOPLEFT', 210, -35)
	excludeBOECheck.Text:SetText("Don't DE BOE gear")
	excludeBOECheck:SetScript('OnClick', function()
		LibsDisenchantAssistDB.options.excludeBOE = excludeBOECheck:GetChecked()
		self:RefreshItemList()
	end)
	panel.excludeBOECheck = excludeBOECheck

	-- Min ilvl slider
	local minIlvlSlider = CreateFrame('Slider', panel:GetName() .. 'MinIlvlSlider', panel, 'OptionsSliderTemplate')
	minIlvlSlider:SetPoint('TOPLEFT', 20, -90)
	minIlvlSlider:SetSize(150, 17)
	minIlvlSlider:SetMinMaxValues(1, 999)
	minIlvlSlider:SetValueStep(1)
	minIlvlSlider:SetScript('OnValueChanged', function(self, value)
		value = math.floor(value + 0.5)
		LibsDisenchantAssistDB.options.minIlvl = value
		_G[self:GetName() .. 'Text']:SetText('Min iLvl: ' .. value)
		UI:RefreshItemList()
	end)
	_G[minIlvlSlider:GetName() .. 'Low']:SetText('1')
	_G[minIlvlSlider:GetName() .. 'High']:SetText('999')
	_G[minIlvlSlider:GetName() .. 'Text']:SetText('Min iLvl')
	panel.minIlvlSlider = minIlvlSlider

	-- Max ilvl slider
	local maxIlvlSlider = CreateFrame('Slider', panel:GetName() .. 'MaxIlvlSlider', panel, 'OptionsSliderTemplate')
	maxIlvlSlider:SetPoint('TOPLEFT', 220, -90)
	maxIlvlSlider:SetSize(150, 17)
	maxIlvlSlider:SetMinMaxValues(1, 999)
	maxIlvlSlider:SetValueStep(1)
	maxIlvlSlider:SetScript('OnValueChanged', function(self, value)
		value = math.floor(value + 0.5)
		LibsDisenchantAssistDB.options.maxIlvl = value
		_G[self:GetName() .. 'Text']:SetText('Max iLvl: ' .. value)
		UI:RefreshItemList()
	end)
	_G[maxIlvlSlider:GetName() .. 'Low']:SetText('1')
	_G[maxIlvlSlider:GetName() .. 'High']:SetText('999')
	_G[maxIlvlSlider:GetName() .. 'Text']:SetText('Max iLvl')
	panel.maxIlvlSlider = maxIlvlSlider
end

function UI:CreateScrollFrame()
	local frame = self.frame

	-- Scroll frame
	local scrollFrame = CreateFrame('ScrollFrame', 'LibsDisenchantAssistMainFrameScrollFrame', frame, 'UIPanelScrollFrameTemplate')
	scrollFrame:SetSize(400, 350)
	scrollFrame:SetPoint('TOPLEFT', 20, -225)
	frame.ScrollFrame = scrollFrame

	-- Item list container
	local itemList = CreateFrame('Frame', 'LibsDisenchantAssistMainFrameItemList', scrollFrame)
	itemList:SetSize(380, 1)
	scrollFrame:SetScrollChild(itemList)
	frame.ItemList = itemList
end

function UI:CreateItemButtons()
	if not self.frame or not self.frame.ItemList then return end

	for i = 1, self.maxButtons do
		local button = self:CreateItemButton(i)

		if i == 1 then
			button:SetPoint('TOPLEFT', 0, 0)
		else
			button:SetPoint('TOPLEFT', self.itemButtons[i - 1], 'BOTTOMLEFT', 0, -2)
		end

		button:Hide()
		self.itemButtons[i] = button
	end
end

function UI:CreateItemButton(index)
	local itemList = self.frame.ItemList
	local button = CreateFrame('Button', 'LibsDisenchantAssistItemButton' .. index, itemList)
	button:SetSize(380, 22) -- Slightly taller for better readability
	button:EnableMouse(true)

	-- Background texture with SpartanUI dark styling
	local background = button:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetColorTexture(0.15, 0.15, 0.15, 0.8) -- Darker background
	button.Background = background

	-- Highlight texture
	local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	highlight:SetAllPoints()
	highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5) -- Subtle highlight
	button:SetHighlightTexture(highlight)

	-- Item icon (slightly larger)
	local icon = button:CreateTexture(nil, 'ARTWORK')
	icon:SetSize(18, 18)
	icon:SetPoint('LEFT', 3, 0)
	button.Icon = icon

	-- Item name with better contrast
	local name = button:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	name:SetPoint('LEFT', icon, 'RIGHT', 6, 0)
	name:SetJustifyH('LEFT')
	name:SetTextColor(1, 1, 1, 1) -- White text for contrast
	button.Name = name

	-- Item level
	local ilvl = button:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	ilvl:SetPoint('RIGHT', -80, 0)
	ilvl:SetJustifyH('RIGHT')
	ilvl:SetTextColor(0.8, 0.8, 1, 1) -- Light blue for ilvl
	button.Ilvl = ilvl

	-- First seen date
	local date = button:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	date:SetPoint('RIGHT', -10, 0)
	date:SetJustifyH('RIGHT')
	date:SetTextColor(0.7, 0.7, 0.7, 1) -- Gray for date
	button.Date = date

	-- Tooltip
	button:SetScript('OnEnter', function(self)
		if self.item then
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
			GameTooltip:SetBagItem(self.item.bag, self.item.slot)
			GameTooltip:Show()
		end
	end)

	button:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)

	return button
end

function UI:Initialize()
	self:CreateMainFrame()
	self:CreateTitleBar()
	self:CreateControlButtons()
	self:CreateOptionsPanel()
	self:CreateScrollFrame()
	self:CreateItemButtons()

	-- Set up frame scripts
	self.frame:SetScript('OnShow', function()
		self:RefreshItemList()
		self:UpdateOptionsFromDB()
	end)
end

function UI:ToggleOptions()
	self.isOptionsVisible = not self.isOptionsVisible

	if self.isOptionsVisible then
		self.frame.OptionsPanel:Show()
		self.frame:SetHeight(720)
		self.frame.ScrollFrame:SetPoint('TOPLEFT', 20, -345)
		self.frame.ScrollFrame:SetHeight(230)
	else
		self.frame.OptionsPanel:Hide()
		self.frame:SetHeight(600)
		self.frame.ScrollFrame:SetPoint('TOPLEFT', 20, -225)
		self.frame.ScrollFrame:SetHeight(350)
	end
end

function UI:UpdateOptionsFromDB()
	if not LibsDisenchantAssistDB then return end

	local options = LibsDisenchantAssistDB.options
	local panel = self.frame.OptionsPanel

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
	if not self.frame or not self.frame:IsVisible() then return end

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

			-- Alternating row colors for better readability (SpartanUI dark theme)
			if i % 2 == 0 then
				button.Background:SetColorTexture(0.2, 0.2, 0.2, 0.8)
			else
				button.Background:SetColorTexture(0.15, 0.15, 0.15, 0.8)
			end

			button:Show()
		else
			button:Hide()
			button.item = nil
		end
	end

	local totalHeight = math.max(#items * 24, 1) -- Updated for 22px button + 2px spacing
	self.frame.ItemList:SetHeight(totalHeight)

	self.frame.ItemCount:SetText('Items to disenchant: ' .. #items)

	if #items > self.maxButtons then
		self.frame.ScrollFrame:Show()
	else
		self.frame.ScrollFrame.ScrollBar:Hide()
	end
	
	-- Update LibDataBroker display
	if LibsDisenchantAssist._ldbObject and LibsDisenchantAssist._ldbObject.UpdateLDB then
		LibsDisenchantAssist._ldbObject:UpdateLDB()
	end
end

---Handle profile changes
function UI:OnProfileChanged()
	-- Refresh the display when profile changes
	if self.frame and self.frame:IsVisible() then
		self:RefreshItemList()
	end
end

---Show the main window
function UI:Show()
	if not self.frame then self:Initialize() end
	self.frame:Show()
end

---Hide the main window
function UI:Hide()
	if self.frame then self.frame:Hide() end
end

---Toggle main window visibility
function UI:Toggle()
	if self.frame and self.frame:IsVisible() then
		self:Hide()
	else
		self:Show()
	end
end
