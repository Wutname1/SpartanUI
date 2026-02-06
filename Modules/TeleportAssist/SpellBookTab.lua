local SUI, L = SUI, SUI.L
---@type SUI.Module.TeleportAssist
local module = SUI:GetModule('TeleportAssist')
----------------------------------------------------------------------------------------------------

-- SpellBook side panel only applies to Classic clients (Retail uses WorldMapIntegration)
if SUI.IsRetail then
	return
end

local sidePanel = nil
local buttonPool = {}
local headerPool = {}
local initialized = false

---Initialize the SpellBook side panel for Classic clients
function module:InitSpellBookTab()
	if initialized then
		return
	end

	-- Wait for SpellBookFrame to exist
	if not SpellBookFrame then
		if module.logger then
			module.logger.warning('SpellBookFrame not available for side panel')
		end
		return
	end

	-- Create the side panel
	module:CreateSpellBookSidePanel()

	-- Hook SpellBookFrame show/hide
	SpellBookFrame:HookScript('OnShow', function()
		if sidePanel then
			sidePanel:Show()
			module:UpdateSidePanel()
		end
	end)

	SpellBookFrame:HookScript('OnHide', function()
		if sidePanel then
			sidePanel:Hide()
		end
	end)

	initialized = true

	if module.logger then
		module.logger.info('SpellBook side panel initialized for Classic client')
	end
end

---Create the side panel frame anchored to the right of SpellBookFrame
function module:CreateSpellBookSidePanel()
	if sidePanel then
		return
	end

	-- Create main panel frame
	sidePanel = CreateFrame('Frame', 'SUI_SpellBookTeleportPanel', SpellBookFrame, 'BackdropTemplate')
	sidePanel:SetSize(200, SpellBookFrame:GetHeight())
	sidePanel:SetPoint('TOPLEFT', SpellBookFrame, 'TOPRIGHT', -2, 0)
	sidePanel:SetPoint('BOTTOMLEFT', SpellBookFrame, 'BOTTOMRIGHT', -2, 0)
	sidePanel:SetFrameStrata(SpellBookFrame:GetFrameStrata())
	sidePanel:SetFrameLevel(SpellBookFrame:GetFrameLevel() + 1)

	-- Background to match SpellBookFrame
	sidePanel:SetBackdrop({
		bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
		edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
		tile = true,
		tileSize = 32,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	sidePanel:SetBackdropColor(0, 0, 0, 0.9)

	-- Title
	sidePanel.Title = sidePanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	sidePanel.Title:SetPoint('TOP', sidePanel, 'TOP', 0, -12)
	sidePanel.Title:SetText('|cffffffffSpartan|cffe21f1fUI|r ' .. L['Teleports'])
	sidePanel.Title:SetTextColor(1, 0.82, 0)

	-- Divider line under title
	sidePanel.Divider = sidePanel:CreateTexture(nil, 'ARTWORK')
	sidePanel.Divider:SetTexture('Interface\\Common\\UI-Divider01-steep')
	sidePanel.Divider:SetSize(180, 16)
	sidePanel.Divider:SetPoint('TOP', sidePanel.Title, 'BOTTOM', 0, -2)

	-- Create scroll frame
	sidePanel.ScrollFrame = CreateFrame('ScrollFrame', 'SUI_SpellBookTeleportScrollFrame', sidePanel, 'UIPanelScrollFrameTemplate')
	sidePanel.ScrollFrame:SetPoint('TOPLEFT', sidePanel, 'TOPLEFT', 8, -38)
	sidePanel.ScrollFrame:SetPoint('BOTTOMRIGHT', sidePanel, 'BOTTOMRIGHT', -28, 8)

	-- Scroll child
	sidePanel.Content = CreateFrame('Frame', nil, sidePanel.ScrollFrame)
	sidePanel.Content:SetWidth(sidePanel.ScrollFrame:GetWidth())
	sidePanel.Content:SetHeight(1)
	sidePanel.ScrollFrame:SetScrollChild(sidePanel.Content)

	sidePanel:Hide()
end

---Get or create a teleport button for the side panel
---@param index number
---@return Button
local function GetButton(index)
	if buttonPool[index] then
		return buttonPool[index]
	end

	local buttonHeight = 28
	local iconSize = 22

	local button = CreateFrame('Button', 'SUI_SpellBookTPBtn_' .. index, sidePanel.Content, 'SecureActionButtonTemplate')
	button:SetSize(sidePanel.ScrollFrame:GetWidth(), buttonHeight)

	-- Background
	button.Background = button:CreateTexture(nil, 'BACKGROUND')
	button.Background:SetAllPoints()
	button.Background:SetColorTexture(0.1, 0.1, 0.1, 0.5)

	-- Highlight
	button.Highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	button.Highlight:SetAllPoints()
	button.Highlight:SetColorTexture(1, 1, 1, 0.15)
	button.Highlight:SetBlendMode('ADD')

	-- Icon
	button.Icon = button:CreateTexture(nil, 'ARTWORK')
	button.Icon:SetSize(iconSize, iconSize)
	button.Icon:SetPoint('LEFT', button, 'LEFT', 4, 0)

	-- Label
	button.Label = button:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
	button.Label:SetPoint('LEFT', button.Icon, 'RIGHT', 6, 0)
	button.Label:SetPoint('RIGHT', button, 'RIGHT', -4, 0)
	button.Label:SetJustifyH('LEFT')
	button.Label:SetWordWrap(false)

	-- Cooldown
	button.Cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	button.Cooldown:SetAllPoints(button.Icon)

	-- Favorite star
	button.FavoriteStar = button:CreateTexture(nil, 'OVERLAY')
	button.FavoriteStar:SetAtlas('PetJournal-FavoritesIcon', true)
	button.FavoriteStar:SetSize(12, 12)
	button.FavoriteStar:SetPoint('TOPLEFT', button.Icon, 'TOPLEFT', -2, 2)
	button.FavoriteStar:Hide()

	-- Click handlers
	button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

	button:SetScript('PreClick', function(self, mouseButton)
		if mouseButton == 'RightButton' then
			self:SetAttribute('type', nil)
		end
	end)

	button:SetScript('PostClick', function(self, mouseButton)
		local entry = self.entry
		if not entry then
			return
		end
		if mouseButton == 'RightButton' then
			module:ToggleFavorite(entry)
			-- Restore secure attribute
			if entry.available then
				if entry.type == 'spell' then
					self:SetAttribute('type', 'spell')
				elseif entry.type == 'toy' then
					self:SetAttribute('type', 'toy')
				elseif entry.type == 'item' then
					self:SetAttribute('type', 'item')
				end
			end
			module:UpdateSidePanel()
		end
	end)

	-- Tooltip
	button:SetScript('OnEnter', function(self)
		local entry = self.entry
		if not entry then
			return
		end
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		if entry.type == 'spell' then
			GameTooltip:SetSpellByID(entry.spellId or entry.id)
		elseif entry.type == 'toy' then
			GameTooltip:SetToyByItemID(entry.id)
		elseif entry.type == 'item' then
			GameTooltip:SetItemByID(entry.id)
		else
			GameTooltip:AddLine(entry.name, 1, 1, 1)
		end
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(L['Right-click to toggle favorite'], 0.5, 0.5, 0.5)
		if not entry.available then
			GameTooltip:AddLine(L['Not available'], 1, 0.2, 0.2)
		end
		GameTooltip:Show()
	end)

	button:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)

	buttonPool[index] = button
	return button
end

---Get or create a category header
---@param index number
---@return FontString
local function GetHeader(index)
	if headerPool[index] then
		return headerPool[index]
	end

	local header = sidePanel.Content:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	header:SetTextColor(1, 0.82, 0)
	header:SetJustifyH('LEFT')
	headerPool[index] = header
	return header
end

---Update the side panel content with available teleports
function module:UpdateSidePanel()
	if not sidePanel then
		return
	end

	-- Ensure content width matches scroll frame
	sidePanel.Content:SetWidth(sidePanel.ScrollFrame:GetWidth())

	-- Hide all existing buttons and headers
	for _, button in pairs(buttonPool) do
		button:Hide()
	end
	for _, header in pairs(headerPool) do
		header:Hide()
	end

	local buttonIndex = 1
	local headerIndex = 1
	local yOffset = 4
	local buttonHeight = 28
	local spacing = 2

	-- Add favorites first if enabled
	if module.CurrentSettings.showFavoritesFirst then
		local favorites = module:GetFavorites()
		if #favorites > 0 then
			local header = GetHeader(headerIndex)
			header:ClearAllPoints()
			header:SetPoint('TOPLEFT', sidePanel.Content, 'TOPLEFT', 4, -yOffset)
			header:SetText(L['Favorites'])
			header:Show()
			headerIndex = headerIndex + 1
			yOffset = yOffset + 18

			for _, entry in ipairs(favorites) do
				local button = GetButton(buttonIndex)
				button:SetSize(sidePanel.ScrollFrame:GetWidth(), buttonHeight)
				button:ClearAllPoints()
				button:SetPoint('TOPLEFT', sidePanel.Content, 'TOPLEFT', 0, -yOffset)
				module:SetupSidePanelButton(button, entry)
				buttonIndex = buttonIndex + 1
				yOffset = yOffset + buttonHeight + spacing
			end

			yOffset = yOffset + 6
		end
	end

	-- Add each expansion category
	for _, expansion in ipairs(module.EXPANSION_ORDER) do
		local entries = module.teleportsByCategory[expansion]
		if entries and #entries > 0 then
			-- Filter entries
			local visibleEntries = {}
			for _, entry in ipairs(entries) do
				local shouldShow = entry.available or not module.CurrentSettings.hideUnavailable
				-- Skip if shown in favorites already
				if shouldShow and module.CurrentSettings.showFavoritesFirst and module:IsFavorite(entry) then
					shouldShow = false
				end
				if shouldShow then
					table.insert(visibleEntries, entry)
				end
			end

			if #visibleEntries > 0 then
				-- Category header
				local header = GetHeader(headerIndex)
				header:ClearAllPoints()
				header:SetPoint('TOPLEFT', sidePanel.Content, 'TOPLEFT', 4, -yOffset)
				header:SetText(module.EXPANSION_NAMES[expansion] or expansion)
				header:Show()
				headerIndex = headerIndex + 1
				yOffset = yOffset + 18

				-- Buttons
				for _, entry in ipairs(visibleEntries) do
					local button = GetButton(buttonIndex)
					button:SetSize(sidePanel.ScrollFrame:GetWidth(), buttonHeight)
					button:ClearAllPoints()
					button:SetPoint('TOPLEFT', sidePanel.Content, 'TOPLEFT', 0, -yOffset)
					module:SetupSidePanelButton(button, entry)
					buttonIndex = buttonIndex + 1
					yOffset = yOffset + buttonHeight + spacing
				end

				yOffset = yOffset + 6
			end
		end
	end

	-- Update content height
	sidePanel.Content:SetHeight(math.max(yOffset + 20, sidePanel.ScrollFrame:GetHeight()))
end

---Set up a button for a teleport entry in the side panel
---@param button Button
---@param entry table
function module:SetupSidePanelButton(button, entry)
	button.entry = entry

	-- Get icon
	local iconTexture = entry.icon
	if not iconTexture then
		if entry.type == 'spell' then
			iconTexture = C_Spell.GetSpellTexture(entry.spellId or entry.id)
		elseif entry.type == 'toy' then
			local _, _, toyIcon = C_ToyBox.GetToyInfo(entry.id)
			iconTexture = toyIcon
		elseif entry.type == 'item' then
			iconTexture = C_Item.GetItemIconByID(entry.id)
		end
	end

	if type(iconTexture) == 'string' then
		button.Icon:SetAtlas(iconTexture)
	else
		button.Icon:SetTexture(iconTexture or 134400)
	end
	button.Icon:SetDesaturated(not entry.available)

	-- Set label
	local labelText = module:GetDisplayLabel(entry)
	if labelText then
		button.Label:SetText(labelText)
		button.Label:Show()
		if entry.available then
			button.Label:SetTextColor(1.0, 0.82, 0.0)
		else
			button.Label:SetTextColor(0.5, 0.5, 0.5)
		end
	else
		button.Label:SetText('')
		button.Label:Hide()
	end

	-- Favorite star
	if module:IsFavorite(entry) then
		button.FavoriteStar:Show()
	else
		button.FavoriteStar:Hide()
	end

	-- Set secure attributes
	if not InCombatLockdown() then
		if entry.available then
			if entry.type == 'spell' then
				button:SetAttribute('type', 'spell')
				button:SetAttribute('spell', entry.spellId or entry.id)
			elseif entry.type == 'toy' then
				button:SetAttribute('type', 'toy')
				button:SetAttribute('toy', entry.id)
			elseif entry.type == 'item' then
				button:SetAttribute('type', 'item')
				button:SetAttribute('item', 'item:' .. entry.id)
			else
				button:SetAttribute('type', nil)
			end
		else
			button:SetAttribute('type', nil)
		end
	end

	button:Show()
end
