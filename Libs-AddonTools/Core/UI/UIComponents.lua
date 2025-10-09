---@class LibAT
local LibAT = LibAT

----------------------------------------------------------------------------------------------------
-- Button Components
----------------------------------------------------------------------------------------------------

---Create a standard styled button using UIPanelButtonTemplate
---@param parent Frame Parent frame
---@param width number Button width
---@param height number Button height
---@param text string Button text
---@return Frame button Standard WoW UI button
function LibAT.UI.CreateButton(parent, width, height, text)
	local button = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
	button:SetSize(width, height)
	button:SetText(text)
	return button
end

---Create a filter button styled like the AuctionHouse navigation buttons
---@param parent Frame Parent frame
---@param name? string Optional unique name for the button
---@return Frame button Filter button with textures
function LibAT.UI.CreateFilterButton(parent, name)
	local button = CreateFrame('Button', name, parent, 'TruncatedTooltipScriptTemplate')
	button:SetSize(150, 21)

	-- Create all texture layers as defined in the XML template
	-- BACKGROUND layer
	button.Lines = button:CreateTexture(nil, 'BACKGROUND')
	button.Lines:SetAtlas('auctionhouse-nav-button-tertiary-filterline', true)
	button.Lines:SetPoint('LEFT', button, 'LEFT', 18, 3)

	button.NormalTexture = button:CreateTexture(nil, 'BACKGROUND')

	-- BORDER layer
	button.HighlightTexture = button:CreateTexture(nil, 'BORDER')
	button.HighlightTexture:Hide()

	-- ARTWORK layer
	button.SelectedTexture = button:CreateTexture(nil, 'ARTWORK')
	button.SelectedTexture:Hide()

	-- Button text with shadow
	button.Text = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	button.Text:SetSize(0, 8)
	button.Text:SetPoint('LEFT', button, 'LEFT', 4, 0)
	button.Text:SetPoint('RIGHT', button, 'RIGHT', -4, 0)
	button.Text:SetJustifyH('LEFT')
	-- Add text shadow
	button.Text:SetShadowOffset(1, -1)
	button.Text:SetShadowColor(0, 0, 0)

	-- Set font objects
	button:SetNormalFontObject(GameFontNormalSmall)
	button:SetHighlightFontObject(GameFontHighlightSmall)

	return button
end

---Setup a filter button with proper styling (matches Blizzard's FilterButton_SetUp)
---@param button Frame The button to setup
---@param info table Button configuration table with type, name, selected, etc.
function LibAT.UI.SetupFilterButton(button, info)
	local normalText = button.Text
	local normalTexture = button.NormalTexture
	local line = button.Lines
	local btnWidth = 144
	local btnHeight = 20

	if info.type == 'category' then
		button:SetNormalFontObject(GameFontNormalSmall)
		button.NormalTexture:SetAtlas('auctionhouse-nav-button', false)
		button.NormalTexture:SetSize(btnWidth + 6, btnHeight + 11)
		button.NormalTexture:ClearAllPoints()
		button.NormalTexture:SetPoint('TOPLEFT', -2, 0)
		button.SelectedTexture:SetAtlas('auctionhouse-nav-button-select', false)
		button.SelectedTexture:SetSize(btnWidth + 2, btnHeight)
		button.SelectedTexture:ClearAllPoints()
		button.SelectedTexture:SetPoint('LEFT')
		button.HighlightTexture:SetAtlas('auctionhouse-nav-button-highlight', false)
		button.HighlightTexture:SetSize(btnWidth + 2, btnHeight)
		button.HighlightTexture:ClearAllPoints()
		button.HighlightTexture:SetPoint('LEFT')
		button.HighlightTexture:SetBlendMode('BLEND')
		button:SetText(info.name)
		normalText:ClearAllPoints()
		normalText:SetPoint('LEFT', button, 'LEFT', 8, 0)
		normalTexture:SetAlpha(1.0)
		line:Hide()
	elseif info.type == 'subCategory' then
		button:SetNormalFontObject(GameFontHighlightSmall)
		button.NormalTexture:SetAtlas('auctionhouse-nav-button-secondary', false)
		button.NormalTexture:SetSize(btnWidth + 3, btnHeight + 11)
		button.NormalTexture:ClearAllPoints()
		button.NormalTexture:SetPoint('TOPLEFT', 1, 0)
		button.SelectedTexture:SetAtlas('auctionhouse-nav-button-secondary-select', false)
		button.SelectedTexture:SetSize(btnWidth - 10, btnHeight)
		button.SelectedTexture:ClearAllPoints()
		button.SelectedTexture:SetPoint('TOPLEFT', 10, 0)
		button.HighlightTexture:SetAtlas('auctionhouse-nav-button-secondary-highlight', false)
		button.HighlightTexture:SetSize(btnWidth - 10, btnHeight)
		button.HighlightTexture:ClearAllPoints()
		button.HighlightTexture:SetPoint('TOPLEFT', 10, 0)
		button.HighlightTexture:SetBlendMode('BLEND')
		button:SetText(info.name or '')
		normalText:ClearAllPoints()
		normalText:SetPoint('LEFT', button, 'LEFT', 18, 0)
		normalTexture:SetAlpha(1.0)
		line:Hide()
	elseif info.type == 'subSubCategory' then
		button:SetNormalFontObject(GameFontHighlightSmall)
		button.NormalTexture:ClearAllPoints()
		button.NormalTexture:SetPoint('TOPLEFT', 10, 0)
		button.SelectedTexture:SetAtlas('auctionhouse-ui-row-select', false)
		button.SelectedTexture:SetSize(btnWidth - 20, btnHeight - 3)
		button.SelectedTexture:ClearAllPoints()
		button.SelectedTexture:SetPoint('TOPRIGHT', 0, -2)
		button.HighlightTexture:SetAtlas('auctionhouse-ui-row-highlight', false)
		button.HighlightTexture:SetSize(btnWidth - 20, btnHeight - 3)
		button.HighlightTexture:ClearAllPoints()
		button.HighlightTexture:SetPoint('TOPRIGHT', 0, -2)
		button.HighlightTexture:SetBlendMode('ADD')
		button:SetText(info.name)
		normalText:SetPoint('LEFT', button, 'LEFT', 26, 0)
		normalTexture:SetAlpha(0.0)
		line:Show()
	end
	button.type = info.type

	if info.type == 'category' then
		button.categoryIndex = info.categoryIndex
	elseif info.type == 'subCategory' then
		button.subCategoryIndex = info.subCategoryIndex
	elseif info.type == 'subSubCategory' then
		button.subSubCategoryIndex = info.subSubCategoryIndex
	end

	button.SelectedTexture:SetShown(info.selected)
end

---Create an icon button (like the settings gear)
---@param parent Frame Parent frame
---@param normalAtlas string Atlas name for normal state
---@param highlightAtlas string Atlas name for highlight state
---@param pushedAtlas string Atlas name for pushed state
---@param size? number Optional size (default 24)
---@return Frame button Icon button
function LibAT.UI.CreateIconButton(parent, normalAtlas, highlightAtlas, pushedAtlas, size)
	size = size or 24
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(size, size)

	-- Set up texture states
	button:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\empty')
	button:SetHighlightTexture('Interface\\AddOns\\SpartanUI\\images\\empty')
	button:SetPushedTexture('Interface\\AddOns\\SpartanUI\\images\\empty')

	-- Create texture layers using atlas
	button.NormalTexture = button:CreateTexture(nil, 'ARTWORK')
	button.NormalTexture:SetAtlas(normalAtlas)
	button.NormalTexture:SetAllPoints()

	button.HighlightTexture = button:CreateTexture(nil, 'HIGHLIGHT')
	button.HighlightTexture:SetAtlas(highlightAtlas)
	button.HighlightTexture:SetAllPoints()
	button.HighlightTexture:SetAlpha(0)

	button.PushedTexture = button:CreateTexture(nil, 'ARTWORK')
	button.PushedTexture:SetAtlas(pushedAtlas)
	button.PushedTexture:SetAllPoints()
	button.PushedTexture:SetAlpha(0)

	-- Set up hover and click effects
	button:SetScript(
		'OnEnter',
		function(self)
			self.HighlightTexture:SetAlpha(1)
		end
	)
	button:SetScript(
		'OnLeave',
		function(self)
			self.HighlightTexture:SetAlpha(0)
		end
	)
	button:SetScript(
		'OnMouseDown',
		function(self)
			self.PushedTexture:SetAlpha(1)
			self.NormalTexture:SetAlpha(0)
		end
	)
	button:SetScript(
		'OnMouseUp',
		function(self)
			self.PushedTexture:SetAlpha(0)
			self.NormalTexture:SetAlpha(1)
		end
	)

	return button
end

----------------------------------------------------------------------------------------------------
-- Input Components
----------------------------------------------------------------------------------------------------

---Create a search box using SearchBoxTemplate
---@param parent Frame Parent frame
---@param width number Search box width
---@param height? number Optional height (default 22)
---@return Frame searchBox Search box with clear button
function LibAT.UI.CreateSearchBox(parent, width, height)
	height = height or 22
	local searchBox = CreateFrame('EditBox', nil, parent, 'SearchBoxTemplate')
	searchBox:SetSize(width, height)
	searchBox:SetAutoFocus(false)
	return searchBox
end

---Create a standard EditBox
---@param parent Frame Parent frame
---@param width number EditBox width
---@param height number EditBox height
---@param multiline? boolean Optional multiline support (default false)
---@return EditBox editBox Standard edit box
function LibAT.UI.CreateEditBox(parent, width, height, multiline)
	local editBox = CreateFrame('EditBox', nil, parent)
	editBox:SetSize(width, height)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject('GameFontHighlight')

	if multiline then
		editBox:SetMultiLine(true)
	end

	return editBox
end

---Create a checkbox using UICheckButtonTemplate
---@param parent Frame Parent frame
---@param label? string Optional label text
---@return Frame checkbox Standard checkbox
function LibAT.UI.CreateCheckbox(parent, label)
	local checkbox = CreateFrame('CheckButton', nil, parent, 'UICheckButtonTemplate')
	checkbox:SetSize(18, 18)

	if label then
		local labelText = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
		labelText:SetText(label)
		labelText:SetPoint('LEFT', checkbox, 'RIGHT', 2, 0)
		labelText:SetTextColor(1, 1, 1)
		checkbox.Label = labelText
	end

	return checkbox
end

---Create a dropdown button using WowStyle1FilterDropdownTemplate
---@param parent Frame Parent frame
---@param text string Dropdown button text
---@param width? number Optional width (default 120)
---@param height? number Optional height (default 22)
---@return Frame dropdown Dropdown button
function LibAT.UI.CreateDropdown(parent, text, width, height)
	width = width or 120
	height = height or 22
	local dropdown = CreateFrame('DropdownButton', nil, parent, 'WowStyle1FilterDropdownTemplate')
	dropdown:SetSize(width, height)
	dropdown:SetText(text)
	return dropdown
end

----------------------------------------------------------------------------------------------------
-- Panel Components
----------------------------------------------------------------------------------------------------

---Create a panel with AuctionHouse styling and nine-slice border
---@param parent Frame Parent frame
---@param atlas string Atlas name for background (e.g., 'auctionhouse-background-summarylist')
---@return Frame panel Styled panel frame
function LibAT.UI.CreateStyledPanel(parent, atlas)
	local panel = CreateFrame('Frame', nil, parent)
	panel.layoutType = 'InsetFrameTemplate'

	-- Add AuctionHouse background
	panel.Background = panel:CreateTexture(nil, 'BACKGROUND')
	panel.Background:SetAtlas(atlas, true)
	panel.Background:SetAllPoints(panel)

	-- Add nine slice border
	panel.NineSlice = CreateFrame('Frame', nil, panel, 'NineSlicePanelTemplate')
	panel.NineSlice:SetAllPoints()

	return panel
end

---Create a scroll frame with MinimalScrollBar
---@param parent Frame Parent frame
---@return ScrollFrame scrollFrame Scroll frame with attached scrollbar
function LibAT.UI.CreateScrollFrame(parent)
	local scrollFrame = CreateFrame('ScrollFrame', nil, parent)

	-- Create minimal scrollbar
	scrollFrame.ScrollBar = CreateFrame('EventFrame', nil, scrollFrame, 'MinimalScrollBar')
	scrollFrame.ScrollBar:SetPoint('TOPLEFT', scrollFrame, 'TOPRIGHT', 2, 0)
	scrollFrame.ScrollBar:SetPoint('BOTTOMLEFT', scrollFrame, 'BOTTOMRIGHT', 2, 0)
	ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollFrame.ScrollBar)

	return scrollFrame
end

---Create a scrollable text display (EditBox within ScrollFrame)
---@param parent Frame Parent frame
---@return Frame scrollFrame The scroll frame
---@return Frame editBox The edit box
function LibAT.UI.CreateScrollableTextDisplay(parent)
	local scrollFrame = LibAT.UI.CreateScrollFrame(parent)

	-- Create the text display area
	local editBox = CreateFrame('EditBox', nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject('GameFontHighlight')
	editBox:SetAutoFocus(false)
	editBox:EnableMouse(true)
	editBox:SetTextColor(1, 1, 1)
	editBox:SetScript(
		'OnTextChanged',
		function(self)
			ScrollingEdit_OnTextChanged(self, self:GetParent())
		end
	)
	editBox:SetScript(
		'OnCursorChanged',
		function(self, x, y, w, h)
			ScrollingEdit_OnCursorChanged(self, x, y - 10, w, h)
		end
	)

	scrollFrame:SetScrollChild(editBox)

	return scrollFrame, editBox
end

----------------------------------------------------------------------------------------------------
-- Text Components
----------------------------------------------------------------------------------------------------

---Create a font string label
---@param parent Frame Parent frame
---@param text string Label text
---@param fontObject? string Optional font object name (default 'GameFontNormalSmall')
---@return FontString label Font string
function LibAT.UI.CreateLabel(parent, text, fontObject)
	fontObject = fontObject or 'GameFontNormalSmall'
	local label = parent:CreateFontString(nil, 'OVERLAY', fontObject)
	label:SetText(text)
	return label
end

---Create a header label (gold colored)
---@param parent Frame Parent frame
---@param text string Header text
---@return FontString header Header font string
function LibAT.UI.CreateHeader(parent, text)
	local header = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	header:SetText(text)
	header:SetTextColor(1, 0.82, 0) -- Gold color
	return header
end

return UI
