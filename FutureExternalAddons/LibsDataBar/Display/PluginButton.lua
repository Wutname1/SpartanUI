---@diagnostic disable: duplicate-set-field
--[===[ File: Display/PluginButton.lua
LibsDataBar PluginButton Framework
Visual display elements for plugin data with full interaction support
--]===]

-- Get the LibsDataBar addon
---@class LibsDataBar
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- Local references for performance
local _G = _G
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GetCursorPosition = GetCursorPosition
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local strfind, gsub = string.find, string.gsub

---@class PluginButton
---@field plugin Plugin Associated plugin object
---@field bar DataBar Parent bar
---@field frame Button WoW button frame
---@field text FontString Text display element
---@field icon Texture Icon display element
---@field background Texture Background element
---@field config table Button configuration
---@field tooltip GameTooltip Custom tooltip (optional)
---@field lastUpdate number Last update timestamp
---@field isHighlighted boolean Current highlight state
---@field animationGroup AnimationGroup Animation controller
---@field clickActions table Mouse click action handlers
local PluginButton = {}
PluginButton.__index = PluginButton

-- Default button configuration
local BUTTON_DEFAULTS = {
	width = 0, -- Auto-size based on content
	height = 20,
	padding = {
		left = 5,
		right = 5,
		top = 2,
		bottom = 2,
	},
	text = {
		font = 'Fonts\\FRIZQT__.TTF',
		size = 12,
		flags = 'OUTLINE',
		color = { 1, 1, 1, 1 }, -- White
		justifyH = 'CENTER',
		justifyV = 'MIDDLE',
	},
	icon = {
		size = 16,
		position = 'LEFT', -- LEFT, RIGHT, NONE
		spacing = 3,
	},
	background = {
		show = false,
		color = { 0, 0, 0, 0.5 },
		texture = 'Interface\\ChatFrame\\ChatFrameBackground',
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	},
	border = {
		show = false,
		color = { 1, 1, 1, 0.8 },
		texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
		size = 1,
	},
	highlight = {
		show = true,
		color = { 1, 1, 1, 0.2 },
		texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
	},
	animations = {
		enable = true,
		fadeIn = 0.2,
		fadeOut = 0.1,
		highlight = 0.1,
	},
	interactions = {
		enableClick = true,
		enableTooltip = true,
		enableDrag = false,
		enableRightClick = true,
		enableMouseWheel = false,
	},
}

---Create a new PluginButton instance
---@param plugin Plugin Plugin object to create button for
---@param bar DataBar Parent bar
---@param config? table Optional button configuration
---@return PluginButton button Created button instance
function PluginButton:Create(plugin, bar, config)
	if not plugin or not plugin.id then
		LibsDataBar:DebugLog('error', 'PluginButton:Create requires valid plugin with id')
		return nil
	end

	if not bar then
		LibsDataBar:DebugLog('error', 'PluginButton:Create requires valid parent bar')
		return nil
	end

	local button = setmetatable({}, PluginButton)

	button.plugin = plugin
	button.bar = bar
	button.config = self:MergeConfig(config or {}, BUTTON_DEFAULTS)
	button.lastUpdate = 0
	button.isHighlighted = false
	button.clickActions = {}

	-- Create the main button frame
	button:CreateFrame()

	-- Setup visual elements
	button:CreateBackground()
	button:CreateIcon()
	button:CreateText()
	button:CreateHighlight()
	button:CreateBorder()

	-- Setup animations
	button:CreateAnimations()

	-- Setup interaction handlers
	button:SetupInteractions()

	-- Apply initial configuration
	button:ApplyConfiguration()

	-- Initial update
	button:Update()

	LibsDataBar:DebugLog('info', 'PluginButton created for plugin: ' .. plugin.id)
	return button
end

---Merge configuration with defaults
---@param config table User configuration
---@param defaults table Default configuration
---@return table merged Merged configuration
function PluginButton:MergeConfig(config, defaults)
	local merged = {}

	-- Deep copy defaults
	for key, value in pairs(defaults) do
		if type(value) == 'table' then
			merged[key] = {}
			for subkey, subvalue in pairs(value) do
				merged[key][subkey] = subvalue
			end
		else
			merged[key] = value
		end
	end

	-- Apply user config overrides
	for key, value in pairs(config) do
		if type(value) == 'table' and merged[key] then
			for subkey, subvalue in pairs(value) do
				merged[key][subkey] = subvalue
			end
		else
			merged[key] = value
		end
	end

	return merged
end

---Create the main button frame
function PluginButton:CreateFrame()
	local frameName = 'LibsDataBar_Button_' .. self.plugin.id .. '_' .. (self.bar.id or 'unknown')
	self.frame = CreateFrame('Button', frameName, self.bar.frame)

	-- Set frame properties
	self.frame:SetFrameStrata('MEDIUM')
	self.frame:SetFrameLevel(2)

	-- Store reference to button object
	self.frame.button = self

	-- Register for clicks
	if self.config.interactions.enableClick then self.frame:RegisterForClicks('AnyUp') end
end

---Create background texture
function PluginButton:CreateBackground()
	if not self.config.background.show then return end

	self.background = self.frame:CreateTexture(nil, 'BACKGROUND')
	self.background:SetTexture(self.config.background.texture)
	self.background:SetVertexColor(unpack(self.config.background.color))

	-- Apply insets
	local insets = self.config.background.insets
	self.background:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', insets.left, -insets.top)
	self.background:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', -insets.right, insets.bottom)
end

---Create icon texture
function PluginButton:CreateIcon()
	if self.config.icon.position == 'NONE' then return end

	self.icon = self.frame:CreateTexture(nil, 'ARTWORK')
	self.icon:SetSize(self.config.icon.size, self.config.icon.size)

	-- Set icon from plugin using GetIcon() method or fallback to icon property
	self:UpdateIconTexture()

	-- Position will be set in UpdateLayout()
end

---Create text font string
function PluginButton:CreateText()
	self.text = self.frame:CreateFontString(nil, 'OVERLAY')

	local textConfig = self.config.text
	self.text:SetFont(textConfig.font, textConfig.size, textConfig.flags)
	self.text:SetTextColor(unpack(textConfig.color))
	self.text:SetJustifyH(textConfig.justifyH)
	self.text:SetJustifyV(textConfig.justifyV)

	-- Position will be set in UpdateLayout()
end

---Create highlight texture
function PluginButton:CreateHighlight()
	if not self.config.highlight.show then return end

	self.highlightTexture = self.frame:CreateTexture(nil, 'HIGHLIGHT')
	self.highlightTexture:SetTexture(self.config.highlight.texture)
	self.highlightTexture:SetVertexColor(unpack(self.config.highlight.color))
	self.highlightTexture:SetAllPoints(self.frame)
	self.highlightTexture:SetAlpha(0)
end

---Create border texture
function PluginButton:CreateBorder()
	if not self.config.border.show then return end

	self.border = self.frame:CreateTexture(nil, 'OVERLAY')
	self.border:SetTexture(self.config.border.texture)
	self.border:SetVertexColor(unpack(self.config.border.color))
	self.border:SetAllPoints(self.frame)
end

---Create animation groups
function PluginButton:CreateAnimations()
	if not self.config.animations.enable then return end

	self.animationGroup = self.frame:CreateAnimationGroup()

	-- Fade in animation
	self.fadeIn = self.animationGroup:CreateAnimation('Alpha')
	self.fadeIn:SetFromAlpha(0)
	self.fadeIn:SetToAlpha(1)
	self.fadeIn:SetDuration(self.config.animations.fadeIn)

	-- Fade out animation
	self.fadeOut = self.animationGroup:CreateAnimation('Alpha')
	self.fadeOut:SetFromAlpha(1)
	self.fadeOut:SetToAlpha(0)
	self.fadeOut:SetDuration(self.config.animations.fadeOut)

	-- Highlight animation
	if self.highlightTexture then
		self.highlightGroup = self.frame:CreateAnimationGroup()

		self.highlightFadeIn = self.highlightGroup:CreateAnimation('Alpha')
		self.highlightFadeIn:SetChildKey('highlightTexture')
		self.highlightFadeIn:SetFromAlpha(0)
		self.highlightFadeIn:SetToAlpha(1)
		self.highlightFadeIn:SetDuration(self.config.animations.highlight)

		self.highlightFadeOut = self.highlightGroup:CreateAnimation('Alpha')
		self.highlightFadeOut:SetChildKey('highlightTexture')
		self.highlightFadeOut:SetFromAlpha(1)
		self.highlightFadeOut:SetToAlpha(0)
		self.highlightFadeOut:SetDuration(self.config.animations.highlight)
	end
end

---Setup interaction handlers
function PluginButton:SetupInteractions()
	local interactions = self.config.interactions

	-- Mouse enter/leave for highlight and tooltip
	self.frame:SetScript('OnEnter', function(frame)
		self:OnEnter()
	end)

	self.frame:SetScript('OnLeave', function(frame)
		self:OnLeave()
	end)

	-- Click handling
	if interactions.enableClick then self.frame:SetScript('OnClick', function(frame, mouseButton, down)
		self:OnClick(mouseButton, down)
	end) end

	-- Mouse wheel handling
	if interactions.enableMouseWheel then
		self.frame:EnableMouseWheel(true)
		self.frame:SetScript('OnMouseWheel', function(frame, delta)
			self:OnMouseWheel(delta)
		end)
	end

	-- Drag handling
	if interactions.enableDrag then
		self.frame:RegisterForDrag('LeftButton')
		self.frame:SetScript('OnDragStart', function(frame)
			self:OnDragStart()
		end)
		self.frame:SetScript('OnDragStop', function(frame)
			self:OnDragStop()
		end)
	end
end

---Apply configuration to visual elements
function PluginButton:ApplyConfiguration()
	-- Apply frame size
	local width = self.config.width
	if width <= 0 then width = self:CalculateAutoWidth() end

	self.frame:SetSize(width, self.config.height)

	-- Update layout of internal elements
	self:UpdateLayout()
end

---Calculate automatic width based on content
---@return number width Calculated width
function PluginButton:CalculateAutoWidth()
	local width = self.config.padding.left + self.config.padding.right

	-- Add icon width if present and visible
	if self.icon and self.config.icon.position ~= 'NONE' and self.icon:IsShown() then width = width + self.config.icon.size + self.config.icon.spacing end

	-- Add text width if text is visible and has content
	if self.text and self.text:IsShown() and self.text:GetText() and self.text:GetText() ~= '' then
		local textWidth = self.text:GetStringWidth()
		width = width + textWidth
	end

	-- Ensure minimum width for icon-only buttons
	if width <= (self.config.padding.left + self.config.padding.right + 5) then
		width = self.config.padding.left + self.config.padding.right + (self.icon and self.icon:IsShown() and self.config.icon.size or 20)
	end

	return width
end

---Update layout of internal elements
function PluginButton:UpdateLayout()
	local padding = self.config.padding
	local iconSize = self.config.icon.size
	local iconSpacing = self.config.icon.spacing
	local iconPosition = self.config.icon.position

	-- Calculate content area
	local contentLeft = padding.left
	local contentRight = -padding.right
	local contentTop = -padding.top
	local contentBottom = padding.bottom

	-- Position icon and text based on icon position and visibility
	if self.icon and iconPosition ~= 'NONE' and self.icon:IsShown() then
		if iconPosition == 'LEFT' then
			-- Icon on left, text on right
			self.icon:SetPoint('LEFT', self.frame, 'LEFT', contentLeft, 0)

			if self.text and self.text:IsShown() then
				self.text:SetPoint('LEFT', self.icon, 'RIGHT', iconSpacing, 0)
				self.text:SetPoint('RIGHT', self.frame, 'RIGHT', contentRight, 0)
				self.text:SetPoint('TOP', self.frame, 'TOP', 0, contentTop)
				self.text:SetPoint('BOTTOM', self.frame, 'BOTTOM', 0, contentBottom)
			end
		elseif iconPosition == 'RIGHT' then
			-- Text on left, icon on right
			self.icon:SetPoint('RIGHT', self.frame, 'RIGHT', contentRight, 0)

			if self.text and self.text:IsShown() then
				self.text:SetPoint('LEFT', self.frame, 'LEFT', contentLeft, 0)
				self.text:SetPoint('RIGHT', self.icon, 'LEFT', -iconSpacing, 0)
				self.text:SetPoint('TOP', self.frame, 'TOP', 0, contentTop)
				self.text:SetPoint('BOTTOM', self.frame, 'BOTTOM', 0, contentBottom)
			end
		end
	else
		-- No icon, center text
		if self.text and self.text:IsShown() then
			self.text:SetPoint('LEFT', self.frame, 'LEFT', contentLeft, 0)
			self.text:SetPoint('RIGHT', self.frame, 'RIGHT', contentRight, 0)
			self.text:SetPoint('TOP', self.frame, 'TOP', 0, contentTop)
			self.text:SetPoint('BOTTOM', self.frame, 'BOTTOM', 0, contentBottom)
		end
	end
end

---Update icon texture from plugin using proper method hierarchy
function PluginButton:UpdateIconTexture()
	if not self.icon then return end

	-- Check if icon display is disabled by configuration
	local showIcon = true
	if LibsDataBar.config and LibsDataBar.config.GetPluginConfig then
		showIcon = LibsDataBar.config:GetPluginConfig(self.plugin.id, 'showIcon')
		if showIcon == nil then showIcon = true end -- Default to true
	end

	-- If icon display is disabled, hide icon and return
	if not showIcon then
		self.icon:Hide()
		return
	end

	local iconPath = nil

	-- Handle LDB objects vs native plugins
	if self.plugin.type == 'ldb' and self.plugin.ldbObject then
		-- Direct LDB object access
		iconPath = self.plugin.ldbObject.icon
	else
		-- Native plugin - try GetIcon() method first
		if self.plugin.GetIcon and type(self.plugin.GetIcon) == 'function' then
			local success, result = pcall(self.plugin.GetIcon, self.plugin)
			if success and result then
				iconPath = result
			else
				if not success then LibsDataBar:DebugLog('error', 'Plugin ' .. self.plugin.id .. ' GetIcon error: ' .. tostring(result)) end
			end
		end

		-- Fallback to icon property if GetIcon() didn't work
		if not iconPath and self.plugin.icon then iconPath = self.plugin.icon end
	end

	-- Set the icon texture if we found one
	if iconPath then
		self.icon:SetTexture(iconPath)
		self.icon:Show()
	else
		-- Hide icon if no icon is available
		self.icon:Hide()
	end
end

---Update button content and appearance
function PluginButton:Update()
	local now = GetTime()
	self.lastUpdate = now

	-- Update text from plugin - handle LDB vs native
	local newText = nil

	if self.plugin.type == 'ldb' and self.plugin.ldbObject then
		-- Direct LDB object access
		local ldb = self.plugin.ldbObject
		newText = ldb.text or ldb.label

		-- Handle suffix
		if newText and ldb.suffix then newText = newText .. ' ' .. ldb.suffix end

		if newText and newText ~= '' then
			self.text:SetText(newText)
			self.text:Show()
		else
			-- No text - check for icon-only
			if self.icon and self.icon:IsShown() then
				self.text:SetText('')
				self.text:Hide()
			else
				self.text:SetText(self.plugin.name or self.plugin.id or 'Unknown')
				self.text:Show()
			end
		end
	else
		-- Native plugin - use GetText method
		if self.plugin.GetText and type(self.plugin.GetText) == 'function' then
			local success, result = pcall(self.plugin.GetText, self.plugin)
			if success and result and result ~= '' then
				self.text:SetText(result)
				self.text:Show()
			elseif success and (not result or result == '') then
				-- Plugin intentionally provides no text (icon-only plugin)
				self.text:SetText('')
				self.text:Hide()
			else
				self.text:SetText('Error')
				self.text:Show()
				if not success then LibsDataBar:DebugLog('error', 'Plugin ' .. self.plugin.id .. ' GetText error: ' .. tostring(result)) end
			end
		else
			-- No GetText method - check if this is an icon-only plugin
			if self.icon and self.icon:IsShown() then
				self.text:SetText('')
				self.text:Hide()
			else
				-- Neither icon nor text available - show plugin name as fallback
				self.text:SetText(self.plugin.name or self.plugin.id or 'Unknown')
				self.text:Show()
			end
		end
	end

	-- Update icon from plugin if it changed
	if self.icon then self:UpdateIconTexture() end

	-- Auto-resize if needed
	if self.config.width <= 0 then
		local newWidth = self:CalculateAutoWidth()
		self.frame:SetWidth(newWidth)
		self:UpdateLayout()
	end

	-- Notify bar of update
	if self.bar and self.bar.OnPluginUpdated then self.bar:OnPluginUpdated(self) end
end

---Handle mouse enter event
function PluginButton:OnEnter()
	if InCombatLockdown() then return end

	self.isHighlighted = true

	-- Show highlight animation
	if self.highlightTexture and self.config.animations.enable then
		if self.highlightGroup then
			self.highlightGroup:Stop()
			self.highlightFadeIn:Play()
		else
			self.highlightTexture:SetAlpha(1)
		end
	end

	-- Show tooltip
	if self.config.interactions.enableTooltip then self:ShowTooltip() end

	-- Fire bar event
	if self.bar.callbacks then self.bar.callbacks:Fire('LibsDataBar_ButtonEnter', self.plugin.id, self) end
end

---Handle mouse leave event
function PluginButton:OnLeave()
	self.isHighlighted = false

	-- Hide highlight animation
	if self.highlightTexture and self.config.animations.enable then
		if self.highlightGroup then
			self.highlightGroup:Stop()
			self.highlightFadeOut:Play()
		else
			self.highlightTexture:SetAlpha(0)
		end
	end

	-- Hide tooltip
	if GameTooltip:GetOwner() == self.frame then GameTooltip:Hide() end

	-- Fire bar event
	if self.bar.callbacks then self.bar.callbacks:Fire('LibsDataBar_ButtonLeave', self.plugin.id, self) end
end

---Handle click events
---@param mouseButton string Mouse button that was clicked
---@param down boolean Whether button is down
function PluginButton:OnClick(mouseButton, down)
	if InCombatLockdown() or down then return end

	-- Call plugin click handler - handle LDB vs native
	if self.plugin.type == 'ldb' and self.plugin.ldbObject then
		-- Direct LDB object OnClick
		if self.plugin.ldbObject.OnClick and type(self.plugin.ldbObject.OnClick) == 'function' then
			local success, result = pcall(self.plugin.ldbObject.OnClick, nil, mouseButton)
			if not success then LibsDataBar:DebugLog('error', 'LDB Plugin ' .. self.plugin.id .. ' OnClick error: ' .. tostring(result)) end
		end
	else
		-- Native plugin OnClick
		if self.plugin.OnClick and type(self.plugin.OnClick) == 'function' then
			local success, result = pcall(self.plugin.OnClick, self.plugin, mouseButton)
			if not success then LibsDataBar:DebugLog('error', 'Plugin ' .. self.plugin.id .. ' OnClick error: ' .. tostring(result)) end
		end
	end

	-- Fire bar event
	if self.bar.callbacks then self.bar.callbacks:Fire('LibsDataBar_ButtonClick', self.plugin.id, mouseButton, self) end

	LibsDataBar:DebugLog('debug', 'Button clicked: ' .. self.plugin.id .. ' with ' .. mouseButton)
end

---Handle mouse wheel events
---@param delta number Scroll delta
function PluginButton:OnMouseWheel(delta)
	if InCombatLockdown() then return end

	-- Call plugin mouse wheel handler if available
	if self.plugin.OnMouseWheel and type(self.plugin.OnMouseWheel) == 'function' then
		local success, result = pcall(self.plugin.OnMouseWheel, self.plugin, delta)
		if not success then LibsDataBar:DebugLog('error', 'Plugin ' .. self.plugin.id .. ' OnMouseWheel error: ' .. tostring(result)) end
	end
end

---Handle drag start
function PluginButton:OnDragStart()
	if InCombatLockdown() then return end

	-- Start dragging the parent bar or button
	if self.bar and self.bar.frame then self.bar.frame:StartMoving() end
end

---Handle drag stop
function PluginButton:OnDragStop()
	if self.bar and self.bar.frame then self.bar.frame:StopMovingOrSizing() end
end

---Show tooltip for this button
function PluginButton:ShowTooltip()
	if not self.config.interactions.enableTooltip then return end

	GameTooltip:SetOwner(self.frame, 'ANCHOR_TOP')

	-- Use plugin's tooltip method - handle LDB vs native
	if self.plugin.type == 'ldb' and self.plugin.ldbObject then
		-- Direct LDB object OnTooltipShow
		if self.plugin.ldbObject.OnTooltipShow and type(self.plugin.ldbObject.OnTooltipShow) == 'function' then
			local success, result = pcall(self.plugin.ldbObject.OnTooltipShow, GameTooltip)
			if not success then
				GameTooltip:AddLine('Error loading LDB tooltip')
				LibsDataBar:DebugLog('error', 'LDB Plugin ' .. self.plugin.id .. ' OnTooltipShow error: ' .. tostring(result))
			end
		else
			-- Fallback LDB tooltip
			GameTooltip:SetText(self.plugin.name or self.plugin.id)
			if self.plugin.ldbObject.tooltiptext then GameTooltip:AddLine(self.plugin.ldbObject.tooltiptext, 1, 1, 1, true) end
		end
	elseif self.plugin.UpdateTooltip and type(self.plugin.UpdateTooltip) == 'function' then
		-- Native plugin UpdateTooltip
		local success, result = pcall(self.plugin.UpdateTooltip, self.plugin, GameTooltip)
		if not success then
			GameTooltip:AddLine('Error loading tooltip')
			LibsDataBar:DebugLog('error', 'Plugin ' .. self.plugin.id .. ' UpdateTooltip error: ' .. tostring(result))
		end
	else
		-- Fallback tooltip
		GameTooltip:AddLine(self.plugin.name or self.plugin.id)
		if self.plugin.description then GameTooltip:AddLine(self.plugin.description, 1, 1, 1, true) end
	end

	GameTooltip:Show()
end

---Hide this button with optional animation
function PluginButton:Hide()
	if self.config.animations.enable and self.fadeOut then
		self.fadeOut:Play()
		self.fadeOut:SetScript('OnFinished', function()
			self.frame:Hide()
		end)
	else
		self.frame:Hide()
	end
end

---Show this button with optional animation
function PluginButton:Show()
	self.frame:Show()

	if self.config.animations.enable and self.fadeIn then self.fadeIn:Play() end
end

---Clean up and destroy this button
function PluginButton:Destroy()
	-- Stop animations
	if self.animationGroup then self.animationGroup:Stop() end
	if self.highlightGroup then self.highlightGroup:Stop() end

	-- Hide tooltip if showing
	if GameTooltip:GetOwner() == self.frame then GameTooltip:Hide() end

	-- Clear references
	self.plugin = nil
	self.bar = nil

	-- Destroy frame
	if self.frame then
		self.frame:Hide()
		self.frame = nil
	end

	LibsDataBar:DebugLog('debug', 'PluginButton destroyed')
end

-- Make PluginButton available to LibsDataBar
LibsDataBar.PluginButton = PluginButton

-- Also make it available globally for backward compatibility
_G.LibsDataBar_PluginButton = PluginButton
