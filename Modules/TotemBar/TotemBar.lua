local SUI, L, print = SUI, SUI.L, SUI.print
---@class TotemBar : AceAddon, AceEvent-3.0, AceHook-3.0
local TotemBar = SUI:NewModule('TotemBar', 'AceEvent-3.0', 'AceHook-3.0') ---@type SUI.Module
TotemBar.description = 'Advanced totem tracking and management bar with timer support'
----------------------------------------------------------------------------------------------------

---@class TotemBar.Timer
---@field spellId number
---@field duration number
---@field startTime number
---@field endTime number
---@field category string
---@field metadata table

---@class TotemBar.ActionButton : Button, BackdropTemplate
---@field id string
---@field slotIndex number
---@field spellId number
---@field totemData table
---@field timer TotemBar.Timer
---@field cooldownFrame Cooldown
---@field icon Texture
---@field countText FontString
---@field keybindText FontString
---@field glowFrame Frame
---@field state TotemBar.ButtonState

---@class TotemBar.ButtonState
---@field enabled boolean
---@field usable boolean
---@field inRange boolean
---@field charges number
---@field cooldownRemaining number
---@field onGlobalCooldown boolean
---@field spellKnown boolean

local MoveIt
local activeTimers = {} ---@type table<number, TotemBar.Timer>
local totemButtons = {} ---@type table<number, TotemBar.ActionButton>
local barFrame
local updateFrame
local TOTEM_CATEGORIES = {
	[1] = 'Earth',
	[2] = 'Fire',
	[3] = 'Water',
	[4] = 'Air',
}

local BUTTON_SIZE = 36
local BUTTON_SPACING = 2
local MAX_BUTTONS = 4

---Button Template System
local ButtonTemplates = {
	---Default SpartanUI template
	['default'] = {
		name = 'Default',
		baseTemplate = 'SecureActionButtonTemplate, BackdropTemplate',
		size = { width = 36, height = 36 },
		textures = {
			normal = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
			pushed = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
			disabled = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
			highlight = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
		},
		fonts = {
			count = { family = 'SpartanUI', size = 10 },
			keybind = { family = 'SpartanUI', size = 8 },
			macro = { family = 'SpartanUI', size = 6 },
		},
		colors = {
			normal = { 1, 1, 1, 1 },
			usable = { 1, 1, 1, 1 },
			unusable = { 0.4, 0.4, 0.4, 1 },
			cooldown = { 1, 1, 1, 0.8 },
			outOfRange = { 1, 0.1, 0.1, 1 },
			background = { 0, 0, 0, 0.7 },
			border = { 0.3, 0.3, 0.3, 1 },
		},
		animations = {
			glow = {
				texture = 'Interface\\SpellActivationOverlay\\IconAlert',
				duration = 1.0,
				loop = true,
			},
			pulse = {
				fromScale = 1.0,
				toScale = 1.2,
				duration = 0.3,
				bounce = true,
			},
			flash = {
				fromAlpha = 1.0,
				toAlpha = 0.3,
				duration = 0.2,
				Repeat = true,
			},
		},
	},

	---Blizzard-style template
	['blizzard'] = {
		name = 'Blizzard Style',
		baseTemplate = 'ActionButtonTemplate',
		size = { width = 36, height = 36 },
		textures = {
			normal = 'Interface\\Buttons\\UI-Quickslot2',
			pushed = 'Interface\\Buttons\\UI-Quickslot-Depress',
			disabled = 'Interface\\Buttons\\UI-Quickslot2',
			highlight = 'Interface\\Buttons\\ButtonHilight-Square',
		},
		fonts = {
			count = { family = 'NumberFontNormal', size = 12 },
			keybind = { family = 'NumberFontNormalSmall', size = 10 },
			macro = { family = 'GameFontHighlightSmallOutline', size = 8 },
		},
		colors = {
			normal = { 1, 1, 1, 1 },
			usable = { 1, 1, 1, 1 },
			unusable = { 0.4, 0.4, 0.4, 1 },
			cooldown = { 1, 1, 1, 0.8 },
			outOfRange = { 0.8, 0.1, 0.1, 1 },
			background = { 1, 1, 1, 1 },
			border = { 1, 1, 1, 1 },
		},
	},

	---Minimalist template
	['minimal'] = {
		name = 'Minimal',
		baseTemplate = 'SecureActionButtonTemplate',
		size = { width = 32, height = 32 },
		textures = {
			normal = nil,
			pushed = nil,
			disabled = nil,
			highlight = 'Interface\\Buttons\\ButtonHilight-Square',
		},
		fonts = {
			count = { family = 'SpartanUI', size = 8 },
			keybind = { family = 'SpartanUI', size = 6 },
			macro = { family = 'SpartanUI', size = 5 },
		},
		colors = {
			normal = { 1, 1, 1, 1 },
			usable = { 1, 1, 1, 1 },
			unusable = { 0.5, 0.5, 0.5, 1 },
			cooldown = { 1, 1, 1, 0.6 },
			outOfRange = { 1, 0.3, 0.3, 1 },
			background = { 0, 0, 0, 0 },
			border = { 0, 0, 0, 0 },
		},
	},
}

---Button Theme Manager
local ButtonTheme = {
	currentTemplate = 'default',

	---Apply template to button
	---@param button TotemBar.ActionButton
	---@param templateName string
	ApplyTemplate = function(button, templateName)
		local template = ButtonTemplates[templateName or ButtonTheme.currentTemplate]
		if not template then template = ButtonTemplates['default'] end

		-- Apply size
		button:SetSize(template.size.width, template.size.height)

		-- Apply textures
		if template.textures.normal then button:SetNormalTexture(template.textures.normal) end
		if template.textures.pushed then button:SetPushedTexture(template.textures.pushed) end
		if template.textures.disabled then button:SetDisabledTexture(template.textures.disabled) end
		if template.textures.highlight then button:SetHighlightTexture(template.textures.highlight) end

		-- Apply backdrop if using default template
		if templateName == 'default' or not templateName then
			button:SetBackdrop({
				bgFile = template.textures.normal,
				edgeFile = template.textures.normal,
				edgeSize = 1,
			})
			button:SetBackdropColor(unpack(template.colors.background))
			button:SetBackdropBorderColor(unpack(template.colors.border))
		end

		-- Update fonts
		if button.countText then SUI.Font:Format(button.countText, template.fonts.count.size, template.fonts.count.family) end
		if button.keybindText then SUI.Font:Format(button.keybindText, template.fonts.keybind.size, template.fonts.keybind.family) end

		-- Store template reference
		button.template = templateName or ButtonTheme.currentTemplate
	end,

	---Set global template
	---@param templateName string
	SetGlobalTemplate = function(templateName)
		if ButtonTemplates[templateName] then
			ButtonTheme.currentTemplate = templateName

			-- Apply to all existing buttons
			for i = 1, MAX_BUTTONS do
				local button = totemButtons[i]
				if button then ButtonTheme.ApplyTemplate(button, templateName) end
			end
		end
	end,

	---Get available templates
	---@return table<string, table>
	GetAvailableTemplates = function()
		return ButtonTemplates
	end,

	---Register custom template
	---@param name string
	---@param template table
	RegisterTemplate = function(name, template)
		ButtonTemplates[name] = template
	end,
}

---Button Animation System
local AnimationSystem = {
	---Play glow animation on button
	---@param button TotemBar.ActionButton
	PlayGlow = function(button)
		if button.animations.glow then button.animations.glow:Stop() end

		-- Create glow texture if it doesn't exist
		if not button.glowTexture then
			button.glowTexture = button.glowFrame:CreateTexture(nil, 'OVERLAY')
			button.glowTexture:SetAllPoints(button)
			button.glowTexture:SetTexture('Interface\\SpellActivationOverlay\\IconAlert')
			button.glowTexture:SetBlendMode('ADD')
		end

		-- Create animation group
		button.animations.glow = button.glowTexture:CreateAnimationGroup()

		-- Alpha animation for glow effect
		local alpha = button.animations.glow:CreateAnimation('Alpha')
		alpha:SetFromAlpha(0)
		alpha:SetToAlpha(1)
		alpha:SetDuration(0.5)
		alpha:SetSmoothing('IN_OUT')

		local alpha2 = button.animations.glow:CreateAnimation('Alpha')
		alpha2:SetFromAlpha(1)
		alpha2:SetToAlpha(0)
		alpha2:SetDuration(0.5)
		alpha2:SetSmoothing('IN_OUT')
		alpha2:SetStartDelay(0.5)

		button.animations.glow:SetLooping('REPEAT')
		button.glowFrame:Show()
		button.animations.glow:Play()
	end,

	---Stop glow animation
	---@param button TotemBar.ActionButton
	StopGlow = function(button)
		if button.animations.glow then button.animations.glow:Stop() end
		button.glowFrame:Hide()
	end,

	---Play pulse animation
	---@param button TotemBar.ActionButton
	PlayPulse = function(button)
		if button.animations.pulse then button.animations.pulse:Stop() end

		-- Create pulse animation
		button.animations.pulse = button:CreateAnimationGroup()

		local scale = button.animations.pulse:CreateAnimation('Scale')
		scale:SetFromScale(1.0, 1.0)
		scale:SetToScale(1.2, 1.2)
		scale:SetDuration(0.3)
		scale:SetSmoothing('IN_OUT')

		local scale2 = button.animations.pulse:CreateAnimation('Scale')
		scale2:SetFromScale(1.2, 1.2)
		scale2:SetToScale(1.0, 1.0)
		scale2:SetDuration(0.3)
		scale2:SetSmoothing('IN_OUT')
		scale2:SetStartDelay(0.3)

		button.animations.pulse:Play()
	end,

	---Play flash animation
	---@param button TotemBar.ActionButton
	---@param color table?
	PlayFlash = function(button, color)
		if button.animations.flash then button.animations.flash:Stop() end

		color = color or { 1, 1, 1 }

		-- Create flash overlay if it doesn't exist
		if not button.flashTexture then
			button.flashTexture = button:CreateTexture(nil, 'OVERLAY')
			button.flashTexture:SetAllPoints(button.icon)
			button.flashTexture:SetColorTexture(color[1], color[2], color[3], 0)
		end

		-- Set flash color
		button.flashTexture:SetColorTexture(color[1], color[2], color[3], 0)

		-- Create flash animation
		button.animations.flash = button.flashTexture:CreateAnimationGroup()

		for i = 1, 3 do
			local alpha1 = button.animations.flash:CreateAnimation('Alpha')
			alpha1:SetFromAlpha(0)
			alpha1:SetToAlpha(0.8)
			alpha1:SetDuration(0.1)
			alpha1:SetStartDelay((i - 1) * 0.4)

			local alpha2 = button.animations.flash:CreateAnimation('Alpha')
			alpha2:SetFromAlpha(0.8)
			alpha2:SetToAlpha(0)
			alpha2:SetDuration(0.1)
			alpha2:SetStartDelay((i - 1) * 0.4 + 0.1)
		end

		button.animations.flash:Play()
	end,

	---Stop all animations on button
	---@param button TotemBar.ActionButton
	StopAllAnimations = function(button)
		for animType, anim in pairs(button.animations) do
			if anim then anim:Stop() end
		end
		button.glowFrame:Hide()
	end,

	---Check for animation triggers
	---@param button TotemBar.ActionButton
	CheckAnimationTriggers = function(button)
		if not button.spellId or button.spellId == 0 then return end

		-- Glow when spell is ready and was on cooldown
		if button.state.cooldownRemaining == 0 and button.state.usable then
			-- Only glow if it was previously on cooldown
			if button.lastCooldownRemaining and button.lastCooldownRemaining > 0 then
				AnimationSystem.PlayGlow(button)
				-- Auto-stop glow after 3 seconds
				C_Timer.After(3, function()
					AnimationSystem.StopGlow(button)
				end)
			end
		end

		-- Flash red when out of range
		if button.state.usable and not button.state.inRange then AnimationSystem.PlayFlash(button, { 1, 0.1, 0.1 }) end

		-- Store previous state for comparison
		button.lastCooldownRemaining = button.state.cooldownRemaining
	end,
}

---Timer Engine Core
local TimerEngine = {
	---Start a new timer
	---@param spellId number
	---@param duration number
	---@param category string
	---@param metadata? table
	---@return string timerId
	StartTimer = function(spellId, duration, category, metadata)
		local timerId = tostring(spellId)
		local currentTime = GetTime()

		activeTimers[timerId] = {
			spellId = spellId,
			duration = duration,
			startTime = currentTime,
			endTime = currentTime + duration,
			category = category,
			metadata = metadata or {},
		}

		return timerId
	end,

	---Update an existing timer
	---@param timerId string
	---@param newDuration number
	UpdateTimer = function(timerId, newDuration)
		if activeTimers[timerId] then
			local currentTime = GetTime()
			activeTimers[timerId].duration = newDuration
			activeTimers[timerId].endTime = currentTime + newDuration
		end
	end,

	---Remove a timer
	---@param timerId string
	RemoveTimer = function(timerId)
		activeTimers[timerId] = nil
	end,

	---Get timer by ID
	---@param timerId string
	---@return TotemBar.Timer?
	GetTimer = function(timerId)
		return activeTimers[timerId]
	end,

	---Get all active timers
	---@return table<string, TotemBar.Timer>
	GetAllTimers = function()
		return activeTimers
	end,

	---Update all timers (remove expired ones)
	UpdateAllTimers = function()
		local currentTime = GetTime()
		for timerId, timer in pairs(activeTimers) do
			if currentTime >= timer.endTime then activeTimers[timerId] = nil end
		end
	end,
}

---Event System for totem detection
local EventManager = {
	---Handle totem update events
	---@param event string
	---@param slot number?
	HandleTotemUpdate = function(event, slot)
		if event == 'PLAYER_TOTEM_UPDATE' then
			TotemBar:UpdateTotemSlot(slot)
		elseif event == 'PLAYER_ENTERING_WORLD' or event == 'PLAYER_LOGIN' then
			TotemBar:UpdateAllTotems()
		end
	end,
}

---ActionButton class for advanced button functionality
local ActionButton = {}
ActionButton.__index = ActionButton

---Create a new ActionButton instance
---@param index number
---@param parent Frame
---@return TotemBar.ActionButton
function ActionButton:New(index, parent)
	local button = CreateFrame('Button', 'SUI_TotemBar_Button' .. index, parent, 'SecureActionButtonTemplate, BackdropTemplate')
	setmetatable(button, ActionButton)

	-- Initialize button properties
	button.id = 'totem_' .. index
	button.slotIndex = index
	button.spellId = 0

	-- Initialize state
	button.state = {
		enabled = true,
		usable = false,
		inRange = true,
		charges = 0,
		cooldownRemaining = 0,
		onGlobalCooldown = false,
		spellKnown = false,
	}

	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetupVisuals()
	button:SetupEvents()
	button:SetupSecureAttributes()

	-- Apply default template
	ButtonTheme.ApplyTemplate(button)

	return button
end

---Setup visual components
function ActionButton:SetupVisuals()
	-- Set up backdrop
	self:SetBackdrop({
		bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
		edgeFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
		edgeSize = 1,
	})
	self:SetBackdropColor(0, 0, 0, 0.7)
	self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	-- Create icon texture
	self.icon = self:CreateTexture(nil, 'ARTWORK')
	self.icon:SetAllPoints()
	self.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	-- Create cooldown frame
	self.cooldownFrame = CreateFrame('Cooldown', nil, self, 'CooldownFrameTemplate')
	self.cooldownFrame:SetAllPoints()
	self.cooldownFrame:SetDrawEdge(false)
	self.cooldownFrame:SetDrawSwipe(true)

	-- Create count text
	self.countText = self:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(self.countText, 10, 'TotemBar')
	self.countText:SetPoint('BOTTOMRIGHT', -2, 2)
	self.countText:SetTextColor(1, 1, 1, 1)

	-- Create keybind text
	self.keybindText = self:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(self.keybindText, 8, 'TotemBar')
	self.keybindText:SetPoint('TOPLEFT', 2, -2)
	self.keybindText:SetTextColor(0.6, 0.6, 0.6, 1)

	-- Create glow frame for animations
	self.glowFrame = CreateFrame('Frame', nil, self)
	self.glowFrame:SetAllPoints()
	self.glowFrame:SetFrameLevel(self:GetFrameLevel() + 1)
	self.glowFrame:Hide()

	-- Initialize animation groups
	self.animations = {
		glow = nil,
		pulse = nil,
		flash = nil,
	}

	-- Position button
	if self.slotIndex == 1 then
		self:SetPoint('LEFT', barFrame, 'LEFT', 0, 0)
	else
		self:SetPoint('LEFT', totemButtons[self.slotIndex - 1], 'RIGHT', BUTTON_SPACING, 0)
	end

	self:Hide()
end

---Setup event handlers
function ActionButton:SetupEvents()
	-- Tooltip handlers
	self:SetScript('OnEnter', function()
		self:OnEnter()
	end)

	self:SetScript('OnLeave', function()
		self:OnLeave()
	end)

	-- Click handlers
	self:SetScript('OnClick', function(_, button, down)
		self:OnClick(button, down)
	end)

	-- Drag handlers for spell assignment
	self:RegisterForDrag('LeftButton')
	self:SetScript('OnDragStart', function()
		self:OnDragStart()
	end)

	self:SetScript('OnReceiveDrag', function()
		self:OnReceiveDrag()
	end)
end

---Setup secure attributes
function ActionButton:SetupSecureAttributes()
	-- Set up secure attributes for right-click to destroy totem
	self:SetAttribute('type', 'destroytotem')
	self:SetAttribute('totem-slot', self.slotIndex)

	-- Enable mouse interactions
	self:EnableMouse(true)
	self:RegisterForClicks('AnyUp')

	-- Register for middle mouse button
	self:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp')
end

---Update button icon
function ActionButton:UpdateIcon()
	if self.spellId and self.spellId > 0 then
		local icon = GetSpellTexture(self.spellId)
		if icon then
			self.icon:SetTexture(icon)
			self.icon:SetDesaturated(not self.state.usable)
		end
	elseif self.totemData and self.totemData.icon then
		self.icon:SetTexture(self.totemData.icon)
		self.icon:SetDesaturated(false)
	else
		self.icon:SetTexture(nil)
	end
end

---Update cooldown display
function ActionButton:UpdateCooldown()
	if self.timer then
		local timeLeft = self.timer.endTime - GetTime()
		if timeLeft > 0 then
			self.state.cooldownRemaining = timeLeft
			if timeLeft < 60 then
				self.countText:SetText(string.format('%.1f', timeLeft))
			else
				self.countText:SetText(string.format('%d', math.ceil(timeLeft)))
			end
		else
			self.state.cooldownRemaining = 0
			self.countText:SetText('')
		end
	elseif self.spellId and self.spellId > 0 then
		local start, duration = GetSpellCooldown(self.spellId)
		if start and duration and duration > 0 then
			local timeLeft = (start + duration) - GetTime()
			if timeLeft > 0 then
				self.cooldownFrame:SetCooldown(start, duration)
				self.state.cooldownRemaining = timeLeft
			else
				self.cooldownFrame:Clear()
				self.state.cooldownRemaining = 0
			end
		else
			self.cooldownFrame:Clear()
			self.state.cooldownRemaining = 0
		end
	else
		self.cooldownFrame:Clear()
		self.state.cooldownRemaining = 0
		self.countText:SetText('')
	end
end

---Update spell usability
function ActionButton:UpdateUsability()
	if self.spellId and self.spellId > 0 then
		local usable, noMana = IsUsableSpell(self.spellId)
		self.state.usable = usable and not noMana
		self.state.spellKnown = C_SpellBook.IsSpellInSpellBook(self.spellId)

		-- Update visual state
		if self.state.usable then
			self.icon:SetVertexColor(1, 1, 1, 1)
		else
			self.icon:SetVertexColor(0.4, 0.4, 0.4, 1)
		end
	else
		self.state.usable = false
		self.state.spellKnown = false
	end
end

---Update keybind display
function ActionButton:UpdateKeybind()
	local keybind = KeybindManager.GetKeybind('BUTTON_' .. self.slotIndex)
	if keybind then
		-- Format keybind for display (make it shorter)
		local displayKey = keybind:gsub('SHIFT%-', 'S-'):gsub('CTRL%-', 'C-'):gsub('ALT%-', 'A-')
		self.keybindText:SetText(displayKey)
	else
		self.keybindText:SetText('')
	end
end

---Set spell for this button
---@param spellId number
function ActionButton:SetSpell(spellId)
	self.spellId = spellId
	if spellId and spellId > 0 then
		self:SetAttribute('type', 'spell')
		self:SetAttribute('spell', spellId)
		self:UpdateIcon()
		self:UpdateUsability()
		self:UpdateCooldown()
		self:Show()
	else
		self:ClearSpell()
	end
end

---Clear spell from button
function ActionButton:ClearSpell()
	self.spellId = 0
	self:SetAttribute('type', 'destroytotem')
	self:SetAttribute('spell', nil)
	self.icon:SetTexture(nil)
	self.countText:SetText('')
	self.cooldownFrame:Clear()

	-- Reset state
	self.state.usable = false
	self.state.spellKnown = false
	self.state.cooldownRemaining = 0
end

---Spell Casting System with Modifier Support
local SpellCaster = {
	---Cast spell with modifier key support
	---@param spellId number
	---@param button TotemBar.ActionButton
	---@param clickType string
	CastSpell = function(spellId, button, clickType)
		if not spellId or spellId == 0 then return end

		-- Check modifier keys
		local shift = IsShiftKeyDown()
		local ctrl = IsControlKeyDown()
		local alt = IsAltKeyDown()

		-- Handle different casting scenarios
		if shift and clickType == 'LeftButton' then
			-- Shift+Click: Cast on self
			if UnitExists('player') then CastSpell(spellId, 'player') end
		elseif ctrl and clickType == 'LeftButton' then
			-- Ctrl+Click: Show spell info
			SpellCaster.ShowSpellInfo(spellId)
		elseif alt and clickType == 'LeftButton' then
			-- Alt+Click: Cast on focus target
			if UnitExists('focus') then
				CastSpell(spellId, 'focus')
			else
				CastSpell(spellId)
			end
		elseif clickType == 'LeftButton' then
			-- Normal left click: Cast spell
			CastSpell(spellId)
		elseif clickType == 'RightButton' then
			-- Right click: Cancel cast or show context menu
			if UnitCastingInfo('player') or UnitChannelInfo('player') then
				SpellStopCasting()
			else
				SpellCaster.ShowContextMenu(spellId, button)
			end
		end
	end,

	---Show spell information
	---@param spellId number
	ShowSpellInfo = function(spellId)
		if not ChatEdit_GetActiveWindow() then ChatFrame_OpenChat('') end
		ChatEdit_InsertLink(GetSpellLink(spellId))
	end,

	---Show context menu for spell
	---@param spellId number
	---@param button TotemBar.ActionButton
	ShowContextMenu = function(spellId, button)
		local menu = {
			{
				text = GetSpellInfo(spellId),
				isTitle = true,
				notCheckable = true,
			},
			{
				text = 'Cast Spell',
				func = function()
					CastSpell(spellId)
				end,
				notCheckable = true,
			},
			{
				text = 'Cast on Self',
				func = function()
					CastSpell(spellId, 'player')
				end,
				notCheckable = true,
			},
			{
				text = 'Remove from Bar',
				func = function()
					button:ClearSpell()
				end,
				notCheckable = true,
			},
			{
				text = 'Spell Information',
				func = function()
					SpellCaster.ShowSpellInfo(spellId)
				end,
				notCheckable = true,
			},
		}

		-- Show dropdown menu
		EasyMenu(menu, CreateFrame('Frame', 'TotemBarContextMenu', UIParent, 'UIDropDownMenuTemplate'), 'cursor', 0, 0, 'MENU')
	end,

	---Validate target for spell
	---@param spellId number
	---@param unit string?
	---@return boolean
	ValidateTarget = function(spellId, unit)
		if not unit then unit = 'target' end

		-- Check if unit exists
		if not UnitExists(unit) then return false end

		-- Check if spell is in range
		if IsSpellInRange(spellId, unit) == 0 then return false end

		-- Additional validation can be added here
		return true
	end,

	---Handle targeting for spells
	---@param spellId number
	HandleTargeting = function(spellId)
		-- Get spell info to determine if it needs a target
		local spellName = GetSpellInfo(spellId)
		if not spellName then return end

		-- Check if current target is valid
		if UnitExists('target') and SpellCaster.ValidateTarget(spellId, 'target') then
			CastSpell(spellId, 'target')
		else
			-- Cast spell and let WoW handle targeting
			CastSpell(spellId)
		end
	end,
}

---Handle button click
---@param button string
---@param down boolean
function ActionButton:OnClick(button, down)
	if down then return end -- Only handle on button up

	if button == 'LeftButton' then
		if self.spellId and self.spellId > 0 then
			-- Cast assigned spell with modifier support
			if self.state.usable then SpellCaster.CastSpell(self.spellId, self, button) end
		elseif self.totemData then
			-- Handle totem destruction
			DestroyTotem(self.slotIndex)
		end
	elseif button == 'RightButton' then
		if self.spellId and self.spellId > 0 then
			-- Right-click on spell: show context menu or cancel cast
			SpellCaster.CastSpell(self.spellId, self, button)
		elseif self.totemData then
			-- Right-click on totem: destroy it
			DestroyTotem(self.slotIndex)
		end
	elseif button == 'MiddleButton' then
		-- Middle click: clear spell assignment
		if self.spellId and self.spellId > 0 then self:ClearSpell() end
	end
end

---Handle mouse enter
function ActionButton:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')

	if self.spellId and self.spellId > 0 then
		GameTooltip:SetSpell(self.spellId)
	elseif self.totemData then
		GameTooltip:SetTotem(self.totemData.slot)
	else
		GameTooltip:SetText('Empty Slot')
		GameTooltip:AddLine('Drag a spell here to assign it', 1, 1, 1)
	end

	GameTooltip:Show()
end

---Handle mouse leave
function ActionButton:OnLeave()
	GameTooltip:Hide()
end

---Handle drag start
function ActionButton:OnDragStart()
	DragDropManager.StartDrag(self, 'cursor')
end

---Handle receiving drag
function ActionButton:OnReceiveDrag()
	DragDropManager.EndDrag(self)
end

---Update all button components
function ActionButton:UpdateAll()
	self:UpdateIcon()
	self:UpdateCooldown()
	self:UpdateUsability()
	self:UpdateKeybind()
end

---Create a totem button using the new ActionButton class
---@param index number
---@return TotemBar.ActionButton
local function CreateTotemButton(index)
	return ActionButton:New(index, barFrame)
end

---Update a specific totem slot
---@param slot number
function TotemBar:UpdateTotemSlot(slot)
	if not slot or slot < 1 or slot > MAX_BUTTONS then return end

	local button = totemButtons[slot]
	if not button then return end

	local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)

	if haveTotem and name then
		-- Show and update button
		button:Show()
		button.icon:SetTexture(icon)
		button.totemData = {
			name = name,
			slot = slot,
			icon = icon,
			startTime = startTime,
			duration = duration,
		}

		-- Start timer
		if duration and duration > 0 then
			local timerId = TimerEngine.StartTimer(0, duration, TOTEM_CATEGORIES[slot], {
				slot = slot,
				name = name,
				icon = icon,
			})
			button.timer = TimerEngine.GetTimer(timerId)

			-- Set up cooldown
			button.cooldownFrame:SetCooldown(startTime, duration)
		else
			-- Permanent totem
			button.cooldownFrame:Clear()
			button.timer = nil
		end

		button.countText:SetText('')
	else
		-- Hide button
		button:Hide()
		button.totemData = nil
		button.timer = nil
		button.cooldownFrame:Clear()
		button.icon:SetTexture(nil)
		button.countText:SetText('')
	end

	TotemBar:UpdateBarVisibility()
end

---Update all totem slots
function TotemBar:UpdateAllTotems()
	for i = 1, MAX_BUTTONS do
		self:UpdateTotemSlot(i)
	end
end

---Update bar visibility based on active totems
function TotemBar:UpdateBarVisibility()
	local hasActiveTotems = false

	for i = 1, MAX_BUTTONS do
		if totemButtons[i] and totemButtons[i]:IsShown() then
			hasActiveTotems = true
			break
		end
	end

	if hasActiveTotems and self.DB.enabled then
		barFrame:Show()
	else
		if self.DB.hideWhenEmpty then
			barFrame:Hide()
		else
			barFrame:Show()
		end
	end
end

---Create the main bar frame
local function CreateBarFrame()
	barFrame = CreateFrame('Frame', 'SUI_TotemBar', UIParent)
	barFrame:SetSize((BUTTON_SIZE * MAX_BUTTONS) + (BUTTON_SPACING * (MAX_BUTTONS - 1)), BUTTON_SIZE)
	barFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, -200)

	-- Create totem buttons
	for i = 1, MAX_BUTTONS do
		totemButtons[i] = CreateTotemButton(i)
	end

	-- Create update frame for timer updates
	updateFrame = CreateFrame('Frame')
	updateFrame:SetScript('OnUpdate', function()
		TimerEngine.UpdateAllTimers()

		-- Update all buttons using new ActionButton methods
		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button then
				button:UpdateCooldown()
				button:UpdateUsability()
				-- Only update keybinds periodically to avoid performance issues
				if math.random() < 0.01 then -- ~1% chance per frame
					button:UpdateKeybind()
				end
			end
		end
	end)

	barFrame:Hide()
end

---Apply layout settings
function TotemBar:ApplyLayout()
	if not barFrame then return end

	-- Get layout configuration from DB (backward compatibility)
	local layoutType = self.DB.layout.layoutType or self.DB.layout.orientation or 'horizontal'
	local layoutOptions = {
		spacing = self.DB.layout.spacing or 2,
		scale = self.DB.layout.scale or 1.0,
		padding = self.DB.layout.padding or 0,
		-- Grid-specific options
		columns = self.DB.layout.columns or 2,
		rows = self.DB.layout.rows or 2,
		fillDirection = self.DB.layout.fillDirection or 'horizontal',
		-- Circular/Arc-specific options
		radius = self.DB.layout.radius or 60,
		startAngle = self.DB.layout.startAngle or 0,
		endAngle = self.DB.layout.endAngle or 360,
		clockwise = self.DB.layout.clockwise ~= false,
		-- Cross-specific options
		centerButton = self.DB.layout.centerButton ~= false,
		-- General options
		reverse = self.DB.layout.reverse or false,
	}

	-- Apply using LayoutEngine
	LayoutEngine.ApplyLayout(layoutType, layoutOptions)

	-- Update mover
	if MoveIt then MoveIt:UpdateMover('TotemBar', barFrame) end
end

---Get totem buttons for external access
---@return table<number, TotemBar.ActionButton>
function TotemBar:GetTotemButtons()
	return totemButtons
end

function TotemBar:OnInitialize()
	---@class TotemBar.DB
	local defaults = {
		profile = {
			enabled = true,
			hideWhenEmpty = true,
			layout = {
				orientation = 'horizontal', -- 'horizontal' or 'vertical'
				spacing = 2,
				scale = 1.0,
			},
			appearance = {
				showBackground = true,
				backgroundColor = { 0, 0, 0, 0.7 },
				borderColor = { 0.3, 0.3, 0.3, 1 },
				showCooldownText = true,
			},
			behavior = {
				clickToDestroy = true,
				showTooltips = true,
			},
		},
	}

	TotemBar.Database = SUI.SpartanUIDB:RegisterNamespace('TotemBar', defaults)
	TotemBar.DB = TotemBar.Database.profile

	-- Get MoveIt reference
	MoveIt = SUI:GetModule('MoveIt')

	-- Build options
	self:Options()
end

function TotemBar:OnEnable()
	if SUI:IsModuleDisabled('TotemBar') then return end

	-- Check if current class has a module registered
	local playerClass = select(2, UnitClass('player'))
	local classModule = ClassRegistry.GetClassModule(playerClass)
	if not classModule then
		self:Disable()
		return
	end

	-- Create UI
	CreateBarFrame()

	-- Register events
	self:RegisterEvent('PLAYER_TOTEM_UPDATE', function(event, slot)
		EventManager.HandleTotemUpdate(event, slot)
	end)
	self:RegisterEvent('PLAYER_ENTERING_WORLD', function(event)
		EventManager.HandleTotemUpdate(event)
	end)
	self:RegisterEvent('PLAYER_LOGIN', function(event)
		EventManager.HandleTotemUpdate(event)
	end)

	-- Create mover
	if MoveIt then
		MoveIt:CreateMover(barFrame, 'TotemBar', 'Totem Bar', function()
			-- Post-drag callback
			TotemBar:ApplyLayout()
		end, 'Class Modules')
	end

	-- Initialize keybind system
	KeybindManager.Initialize()

	-- Initialize macro system
	MacroSystem.Initialize()

	-- Initialize drag drop system
	DragDropManager.Initialize()

	-- Initialize class system
	ClassRegistry.Initialize()

	-- Apply initial layout
	self:ApplyLayout()

	-- Initial totem check
	self:UpdateAllTotems()
end

function TotemBar:OnDisable()
	if barFrame then barFrame:Hide() end

	if updateFrame then updateFrame:SetScript('OnUpdate', nil) end

	self:UnregisterAllEvents()
end

---Keybinding Management System
local KeybindManager = {
	registeredKeybinds = {},
	dynamicKeybinds = {},

	---Register a keybind for the addon
	---@param name string
	---@param defaultKey string?
	---@param handler function
	---@param description string?
	RegisterKeybind = function(name, defaultKey, handler, description)
		local fullName = 'TOTEMBAR_' .. name

		-- Create binding in WoW's system
		if not _G['BINDING_NAME_' .. fullName] then _G['BINDING_NAME_' .. fullName] = description or name end

		-- Store our handler
		KeybindManager.registeredKeybinds[fullName] = {
			name = name,
			handler = handler,
			defaultKey = defaultKey,
			description = description,
		}

		-- Set default binding if provided
		if defaultKey then SetBinding(defaultKey, fullName) end

		return fullName
	end,

	---Unregister a keybind
	---@param name string
	UnregisterKeybind = function(name)
		local fullName = 'TOTEMBAR_' .. name

		-- Clear any existing bindings
		local key1, key2 = GetBindingKey(fullName)
		if key1 then SetBinding(key1) end
		if key2 then SetBinding(key2) end

		-- Remove from our registry
		KeybindManager.registeredKeybinds[fullName] = nil
		_G['BINDING_NAME_' .. fullName] = nil
	end,

	---Set a keybind dynamically
	---@param name string
	---@param key string
	---@return boolean success
	SetKeybind = function(name, key)
		local fullName = 'TOTEMBAR_' .. name

		if not KeybindManager.registeredKeybinds[fullName] then return false end

		-- Check for conflicts
		local existingAction = GetBindingAction(key)
		if existingAction and existingAction ~= fullName then
			-- Store conflict info for user decision
			return false, existingAction
		end

		-- Clear existing bindings for this action
		local oldKey1, oldKey2 = GetBindingKey(fullName)
		if oldKey1 then SetBinding(oldKey1) end
		if oldKey2 then SetBinding(oldKey2) end

		-- Set new binding
		SetBinding(key, fullName)
		SaveBindings(GetCurrentBindingSet())

		return true
	end,

	---Get current keybind for action
	---@param name string
	---@return string?
	GetKeybind = function(name)
		local fullName = 'TOTEMBAR_' .. name
		return GetBindingKey(fullName)
	end,

	---Create dynamic keybind for button
	---@param button TotemBar.ActionButton
	---@param key string?
	CreateDynamicKeybind = function(button, key)
		if not key then return end

		local bindingName = 'TOTEMBAR_BUTTON_' .. button.slotIndex

		-- Create click handler
		local clickHandler = function()
			if button.spellId and button.spellId > 0 then
				SpellCaster.CastSpell(button.spellId, button, 'LeftButton')
			elseif button.totemData then
				DestroyTotem(button.slotIndex)
			end
		end

		-- Register the binding
		KeybindManager.RegisterKeybind('BUTTON_' .. button.slotIndex, key, clickHandler, 'Totem Bar Button ' .. button.slotIndex)

		-- Store dynamic binding info
		KeybindManager.dynamicKeybinds[button.slotIndex] = {
			key = key,
			bindingName = bindingName,
		}

		-- Update button display
		button:UpdateKeybind()
	end,

	---Update button keybind display
	---@param button TotemBar.ActionButton
	---@param key string
	UpdateButtonKeybind = function(button, key)
		KeybindManager.CreateDynamicKeybind(button, key)
	end,

	---Clear button keybind
	---@param button TotemBar.ActionButton
	ClearButtonKeybind = function(button)
		local dynamicBind = KeybindManager.dynamicKeybinds[button.slotIndex]
		if dynamicBind then
			KeybindManager.UnregisterKeybind('BUTTON_' .. button.slotIndex)
			KeybindManager.dynamicKeybinds[button.slotIndex] = nil
			button:UpdateKeybind()
		end
	end,

	---Validate keybind string
	---@param key string
	---@return boolean valid
	---@return string? reason
	ValidateKeybind = function(key)
		if not key or key == '' then return false, 'Empty keybind' end

		-- Check for invalid characters
		if key:match('[<>]') then return false, 'Invalid characters in keybind' end

		-- Check for reserved keys
		local reserved = {
			'ESCAPE',
			'ENTER',
			'TAB',
			'SPACE',
		}

		for _, reservedKey in pairs(reserved) do
			if key:upper() == reservedKey then return false, 'Reserved key: ' .. reservedKey end
		end

		return true
	end,

	---Check for keybind conflicts
	---@param key string
	---@return boolean hasConflict
	---@return string? conflictAction
	CheckConflicts = function(key)
		local existingAction = GetBindingAction(key)
		if existingAction and not existingAction:match('^TOTEMBAR_') then return true, existingAction end
		return false
	end,

	---Get list of available keys (not bound to actions)
	---@return table<string>
	GetAvailableKeys = function()
		local available = {}
		local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
		local numbers = '1234567890'
		local modifiers = { '', 'SHIFT-', 'CTRL-', 'ALT-' }

		-- Check letter keys
		for i = 1, #alphabet do
			local letter = alphabet:sub(i, i)
			for _, mod in pairs(modifiers) do
				local key = mod .. letter
				if not GetBindingAction(key) then table.insert(available, key) end
			end
		end

		-- Check number keys
		for i = 1, #numbers do
			local number = numbers:sub(i, i)
			for _, mod in pairs(modifiers) do
				local key = mod .. number
				if not GetBindingAction(key) then table.insert(available, key) end
			end
		end

		-- Function keys
		for i = 1, 12 do
			local key = 'F' .. i
			for _, mod in pairs(modifiers) do
				local fullKey = mod .. key
				if not GetBindingAction(fullKey) then table.insert(available, fullKey) end
			end
		end

		return available
	end,

	---Get all registered TotemBar keybinds
	---@return table<string, table>
	GetRegisteredKeybinds = function()
		return KeybindManager.registeredKeybinds
	end,

	---Initialize keybind system
	Initialize = function()
		-- Register global keybinds
		KeybindManager.RegisterKeybind('TOGGLE_BAR', nil, function()
			TotemBar.DB.enabled = not TotemBar.DB.enabled
			TotemBar:UpdateBarVisibility()
		end, 'Toggle Totem Bar')

		KeybindManager.RegisterKeybind('DESTROY_ALL', nil, function()
			for i = 1, 4 do
				local haveTotem = GetTotemInfo(i)
				if haveTotem then DestroyTotem(i) end
			end
		end, 'Destroy All Totems')

		KeybindManager.RegisterKeybind('TEST_MODE', nil, function()
			TotemBar:ToggleTestMode()
		end, 'Toggle Test Mode')

		-- Register individual button keybinds
		for i = 1, 4 do
			KeybindManager.RegisterKeybind('BUTTON_' .. i, nil, function()
				local button = totemButtons[i]
				if button then
					if button.spellId and button.spellId > 0 then
						SpellCaster.CastSpell(button.spellId, button, 'LeftButton')
					elseif button.totemData then
						DestroyTotem(i)
					end
				end
			end, 'Totem Bar Button ' .. i)
		end
	end,

	---Save keybind profile
	---@param name string
	SaveKeybindProfile = function(name)
		local profile = {}

		for bindName, bindData in pairs(KeybindManager.registeredKeybinds) do
			local key = GetBindingKey(bindName)
			if key then profile[bindData.name] = key end
		end

		-- Store in database
		if not TotemBar.DB.keybindProfiles then TotemBar.DB.keybindProfiles = {} end
		TotemBar.DB.keybindProfiles[name] = profile

		return profile
	end,

	---Load keybind profile
	---@param name string
	---@return boolean success
	LoadKeybindProfile = function(name)
		if not TotemBar.DB.keybindProfiles or not TotemBar.DB.keybindProfiles[name] then return false end

		local profile = TotemBar.DB.keybindProfiles[name]

		-- Clear existing bindings
		for bindName in pairs(KeybindManager.registeredKeybinds) do
			local key1, key2 = GetBindingKey(bindName)
			if key1 then SetBinding(key1) end
			if key2 then SetBinding(key2) end
		end

		-- Apply profile bindings
		for actionName, key in pairs(profile) do
			local fullName = 'TOTEMBAR_' .. actionName
			if KeybindManager.registeredKeybinds[fullName] then SetBinding(key, fullName) end
		end

		SaveBindings(GetCurrentBindingSet())

		-- Update button displays
		for i = 1, 4 do
			local button = totemButtons[i]
			if button then button:UpdateKeybind() end
		end

		return true
	end,

	---Export keybinds as string
	---@return string
	ExportKeybinds = function()
		local export = {}

		for bindName, bindData in pairs(KeybindManager.registeredKeybinds) do
			local key = GetBindingKey(bindName)
			if key then export[bindData.name] = key end
		end

		return SUI:Serialize(export)
	end,

	---Import keybinds from string
	---@param importString string
	---@return boolean success
	ImportKeybinds = function(importString)
		local success, data = SUI:Deserialize(importString)
		if not success then return false end

		-- Validate data
		if type(data) ~= 'table' then return false end

		-- Apply bindings
		for actionName, key in pairs(data) do
			local fullName = 'TOTEMBAR_' .. actionName
			if KeybindManager.registeredKeybinds[fullName] then
				local valid, reason = KeybindManager.ValidateKeybind(key)
				if valid then SetBinding(key, fullName) end
			end
		end

		SaveBindings(GetCurrentBindingSet())

		-- Update displays
		for i = 1, 4 do
			local button = totemButtons[i]
			if button then button:UpdateKeybind() end
		end

		return true
	end,
}

-- Export timer engine for potential external use
TotemBar.TimerEngine = TimerEngine
TotemBar.EventManager = EventManager
TotemBar.KeybindManager = KeybindManager

---Macro Integration System
local MacroSystem = {
	createdMacros = {},
	macroTemplates = {},

	---Initialize macro system with predefined templates
	Initialize = function()
		-- Predefined macro templates
		MacroSystem.macroTemplates = {
			totemSequence = {
				name = 'Totem Sequence',
				body = '/cast [mod:shift] {totem1}; [mod:ctrl] {totem2}; {totem3}',
				description = 'Cast different totems with modifier keys',
				variables = { 'totem1', 'totem2', 'totem3' },
			},
			smartCast = {
				name = 'Smart Cast',
				body = '/cast [target=mouseover,exists] {spell}; {spell}',
				description = 'Cast spell on mouseover target or current target',
				variables = { 'spell' },
			},
			conditional = {
				name = 'Conditional Cast',
				body = '/cast [combat] {combatSpell}; {normalSpell}',
				description = 'Different spells for combat vs non-combat',
				variables = { 'combatSpell', 'normalSpell' },
			},
			focus = {
				name = 'Focus Cast',
				body = '/cast [mod:shift,target=focus] {spell}; [mod:ctrl,target=player] {spell}; {spell}',
				description = 'Cast on focus (shift) or self (ctrl) or target',
				variables = { 'spell' },
			},
			stopcast = {
				name = 'Stop Cast',
				body = '/stopcasting\n/cast {spell}',
				description = 'Stop current cast then cast spell',
				variables = { 'spell' },
			},
		}
	end,

	---Create a macro with given parameters
	---@param name string
	---@param icon string?
	---@param body string
	---@return number? macroIndex
	CreateMacro = function(name, icon, body)
		-- Validate inputs
		if not name or name == '' then return nil end

		if not body or body == '' then return nil end

		-- Check if macro already exists
		local existingMacro = GetMacroIndexByName(name)
		if existingMacro and existingMacro > 0 then
			-- Update existing macro
			EditMacro(existingMacro, name, icon or 'INV_Misc_QuestionMark', body)
			return existingMacro
		else
			-- Create new macro
			local macroIndex = CreateMacro(name, icon or 'INV_Misc_QuestionMark', body, false)
			if macroIndex and macroIndex > 0 then
				MacroSystem.createdMacros[name] = {
					index = macroIndex,
					icon = icon,
					body = body,
					created = GetTime(),
				}
				return macroIndex
			end
		end

		return nil
	end,

	---Update an existing macro
	---@param name string
	---@param newBody string
	---@param newIcon string?
	---@return boolean success
	UpdateMacro = function(name, newBody, newIcon)
		local macroIndex = GetMacroIndexByName(name)
		if macroIndex and macroIndex > 0 then
			local macroData = MacroSystem.createdMacros[name]
			if macroData then
				macroData.body = newBody
				macroData.icon = newIcon or macroData.icon
			end

			EditMacro(macroIndex, name, newIcon or 'INV_Misc_QuestionMark', newBody)
			return true
		end
		return false
	end,

	---Delete a macro
	---@param name string
	---@return boolean success
	DeleteMacro = function(name)
		local macroIndex = GetMacroIndexByName(name)
		if macroIndex and macroIndex > 0 then
			DeleteMacro(macroIndex)
			MacroSystem.createdMacros[name] = nil
			return true
		end
		return false
	end,

	---Substitute variables in macro text
	---@param macroText string
	---@param variables table<string, string>
	---@return string
	SubstituteVariables = function(macroText, variables)
		local result = macroText

		-- Replace variables in {variable} format
		for varName, varValue in pairs(variables) do
			local pattern = '{' .. varName .. '}'
			result = result:gsub(pattern, varValue)
		end

		return result
	end,

	---Register a variable for macro substitution
	---@param name string
	---@param value string
	RegisterVariable = function(name, value)
		if not MacroSystem.registeredVariables then MacroSystem.registeredVariables = {} end
		MacroSystem.registeredVariables[name] = value
	end,

	---Get all registered variables
	---@return table<string, string>
	GetRegisteredVariables = function()
		return MacroSystem.registeredVariables or {}
	end,

	---Validate macro syntax
	---@param body string
	---@return boolean valid
	---@return string? error
	ValidateMacroSyntax = function(body)
		if not body or body == '' then return false, 'Empty macro body' end

		-- Check macro length
		if #body > 255 then return false, 'Macro too long (255 character limit)' end

		-- Check for invalid commands (basic validation)
		local lines = { strsplit('\n', body) }
		for _, line in pairs(lines) do
			local trimmed = line:gsub('^%s*', ''):gsub('%s*$', '')
			if trimmed ~= '' and not trimmed:match('^/') then return false, 'Invalid macro line: ' .. trimmed end
		end

		return true
	end,

	---Get list of available macro commands
	---@return table<string>
	GetMacroCommands = function()
		return {
			'/cast',
			'/castsequence',
			'/use',
			'/target',
			'/assist',
			'/focus',
			'/stopcasting',
			'/cancelaura',
			'/dismount',
			'/click',
			'/run',
			'/script',
			'/console',
			'/reload',
		}
	end,

	---Check if macro length is valid
	---@param body string
	---@return boolean valid
	CheckMacroLength = function(body)
		return #body <= 255
	end,

	---Create a conditional macro based on conditions and actions
	---@param conditions table<string, any>
	---@param actions table<string, string>
	---@return string macroBody
	CreateConditionalMacro = function(conditions, actions)
		local lines = {}

		-- Build conditional lines
		for condition, action in pairs(actions) do
			if condition == 'default' then
				-- Default action (no condition)
				table.insert(lines, '/cast ' .. action)
			else
				-- Conditional action
				table.insert(lines, '/cast [' .. condition .. '] ' .. action)
			end
		end

		return table.concat(lines, '; ')
	end,

	---Generate a rotation macro from spell list
	---@param spells table<string>
	---@param resetCondition string?
	---@return string macroBody
	GenerateRotationMacro = function(spells, resetCondition)
		if not spells or #spells == 0 then return '' end

		local spellList = table.concat(spells, ', ')
		local resetPart = resetCondition and (' reset=' .. resetCondition) or ''

		return '/castsequence' .. resetPart .. ' ' .. spellList
	end,

	---Create item use macro with conditions
	---@param item string
	---@param conditions string?
	---@return string macroBody
	CreateItemUseMacro = function(item, conditions)
		local conditionPart = conditions and ('[' .. conditions .. '] ') or ''
		return '/use ' .. conditionPart .. item
	end,

	---Get macro template by name
	---@param templateName string
	---@return table? template
	GetTemplate = function(templateName)
		return MacroSystem.macroTemplates[templateName]
	end,

	---Get all available templates
	---@return table<string, table>
	GetAllTemplates = function()
		return MacroSystem.macroTemplates
	end,

	---Register a custom template
	---@param name string
	---@param template table
	RegisterTemplate = function(name, template)
		MacroSystem.macroTemplates[name] = template
	end,

	---Create macro from template
	---@param templateName string
	---@param variables table<string, string>
	---@param macroName string
	---@param icon string?
	---@return number? macroIndex
	CreateFromTemplate = function(templateName, variables, macroName, icon)
		local template = MacroSystem.GetTemplate(templateName)
		if not template then return nil end

		-- Substitute variables in template
		local macroBody = MacroSystem.SubstituteVariables(template.body, variables)

		-- Validate the result
		local valid, error = MacroSystem.ValidateMacroSyntax(macroBody)
		if not valid then
			print('Macro validation failed: ' .. (error or 'Unknown error'))
			return nil
		end

		return MacroSystem.CreateMacro(macroName, icon, macroBody)
	end,

	---Get info about created macros
	---@return table<string, table>
	GetCreatedMacros = function()
		return MacroSystem.createdMacros
	end,

	---Clean up orphaned macros
	CleanupMacros = function()
		for name, macroData in pairs(MacroSystem.createdMacros) do
			local macroIndex = GetMacroIndexByName(name)
			if not macroIndex or macroIndex == 0 then
				-- Macro was deleted outside our system
				MacroSystem.createdMacros[name] = nil
			end
		end
	end,

	---Export macro as shareable string
	---@param name string
	---@return string? macroString
	ExportMacro = function(name)
		local macroData = MacroSystem.createdMacros[name]
		if not macroData then return nil end

		local exportData = {
			name = name,
			icon = macroData.icon,
			body = macroData.body,
			version = 1,
		}

		return SUI:Serialize(exportData)
	end,

	---Import macro from string
	---@param macroString string
	---@return boolean success
	---@return string? errorMessage
	ImportMacro = function(macroString)
		local success, data = SUI:Deserialize(macroString)
		if not success or not data then return false, 'Invalid macro data' end

		-- Validate imported data
		if not data.name or not data.body then return false, 'Missing required macro fields' end

		-- Validate macro syntax
		local valid, error = MacroSystem.ValidateMacroSyntax(data.body)
		if not valid then return false, 'Invalid macro syntax: ' .. (error or 'Unknown error') end

		-- Create the macro
		local macroIndex = MacroSystem.CreateMacro(data.name, data.icon, data.body)
		if macroIndex then
			return true
		else
			return false, 'Failed to create macro'
		end
	end,
}

TotemBar.MacroSystem = MacroSystem

---Spell Sequence Engine for advanced spell casting management
local SpellSequencer = {
	sequences = {},
	activeSequence = nil,

	---Sequence type definitions
	sequenceTypes = {
		linear = {
			description = 'Execute spells in order',
			resetCondition = 'on_complete',
			options = { loop = false, resetOnCombat = false },
		},
		priority = {
			description = 'Execute highest priority available spell',
			resetCondition = 'never',
			options = { priorities = {}, smartCooldown = true },
		},
		conditional = {
			description = 'Execute based on conditions',
			resetCondition = 'on_condition',
			options = { conditions = {}, fallback = nil },
		},
		rotation = {
			description = 'Spell rotation with smart cooldown management',
			resetCondition = 'manual',
			options = { respectCooldowns = true, skipUnavailable = true },
		},
	},

	---Create a new spell sequence
	---@param name string
	---@param spells table<number, string|number>
	---@param sequenceType string
	---@param options table?
	---@return boolean success
	CreateSequence = function(name, spells, sequenceType, options)
		if not name or not spells or #spells == 0 then return false end

		if not SpellSequencer.sequenceTypes[sequenceType] then sequenceType = 'linear' end

		options = options or {}
		local typeDefaults = SpellSequencer.sequenceTypes[sequenceType].options

		-- Merge options with defaults
		for key, defaultValue in pairs(typeDefaults) do
			if options[key] == nil then options[key] = defaultValue end
		end

		SpellSequencer.sequences[name] = {
			name = name,
			spells = spells,
			type = sequenceType,
			options = options,
			currentIndex = 1,
			lastCast = 0,
			created = GetTime(),
			enabled = true,
			statistics = {
				totalCasts = 0,
				successfulCasts = 0,
				lastUsed = 0,
			},
		}

		return true
	end,

	---Execute a spell sequence
	---@param name string
	---@return boolean success
	ExecuteSequence = function(name)
		local sequence = SpellSequencer.sequences[name]
		if not sequence or not sequence.enabled then return false end

		-- Set as active sequence
		SpellSequencer.activeSequence = name

		-- Execute based on sequence type
		if sequence.type == 'linear' then
			return SpellSequencer.ExecuteLinearSequence(sequence)
		elseif sequence.type == 'priority' then
			return SpellSequencer.ExecutePrioritySequence(sequence)
		elseif sequence.type == 'conditional' then
			return SpellSequencer.ExecuteConditionalSequence(sequence)
		elseif sequence.type == 'rotation' then
			return SpellSequencer.ExecuteRotationSequence(sequence)
		end

		return false
	end,

	---Execute linear sequence (spells in order)
	---@param sequence table
	---@return boolean success
	ExecuteLinearSequence = function(sequence)
		if sequence.currentIndex > #sequence.spells then
			if sequence.options.loop then
				sequence.currentIndex = 1
			else
				SpellSequencer.ResetSequence(sequence.name)
				return false
			end
		end

		local spellId = sequence.spells[sequence.currentIndex]
		local success = SpellSequencer.CastSpellFromSequence(spellId, sequence)

		if success then
			sequence.currentIndex = sequence.currentIndex + 1
			sequence.statistics.successfulCasts = sequence.statistics.successfulCasts + 1
		end

		sequence.statistics.totalCasts = sequence.statistics.totalCasts + 1
		sequence.statistics.lastUsed = GetTime()

		return success
	end,

	---Execute priority sequence (highest priority available spell)
	---@param sequence table
	---@return boolean success
	ExecutePrioritySequence = function(sequence)
		-- Sort spells by priority (if priorities defined)
		local sortedSpells = {}
		for i, spellId in ipairs(sequence.spells) do
			local priority = sequence.options.priorities[spellId] or i
			table.insert(sortedSpells, { spellId = spellId, priority = priority })
		end

		table.sort(sortedSpells, function(a, b)
			return a.priority < b.priority
		end)

		-- Try to cast highest priority available spell
		for _, spellData in ipairs(sortedSpells) do
			local spellId = spellData.spellId

			-- Check if spell is available
			if SpellSequencer.IsSpellAvailable(spellId, sequence.options.smartCooldown) then
				local success = SpellSequencer.CastSpellFromSequence(spellId, sequence)
				if success then
					sequence.statistics.successfulCasts = sequence.statistics.successfulCasts + 1
					sequence.statistics.totalCasts = sequence.statistics.totalCasts + 1
					sequence.statistics.lastUsed = GetTime()
					return true
				end
			end
		end

		sequence.statistics.totalCasts = sequence.statistics.totalCasts + 1
		return false
	end,

	---Execute conditional sequence (based on game state)
	---@param sequence table
	---@return boolean success
	ExecuteConditionalSequence = function(sequence)
		-- Evaluate conditions for each spell
		for i, spellId in ipairs(sequence.spells) do
			local condition = sequence.options.conditions[spellId]
			if condition and SpellSequencer.EvaluateCondition(condition) then
				local success = SpellSequencer.CastSpellFromSequence(spellId, sequence)
				if success then
					sequence.statistics.successfulCasts = sequence.statistics.successfulCasts + 1
					sequence.statistics.totalCasts = sequence.statistics.totalCasts + 1
					sequence.statistics.lastUsed = GetTime()
					return true
				end
			end
		end

		-- Try fallback spell if no conditions met
		if sequence.options.fallback then
			local success = SpellSequencer.CastSpellFromSequence(sequence.options.fallback, sequence)
			if success then sequence.statistics.successfulCasts = sequence.statistics.successfulCasts + 1 end
			sequence.statistics.totalCasts = sequence.statistics.totalCasts + 1
			sequence.statistics.lastUsed = GetTime()
			return success
		end

		sequence.statistics.totalCasts = sequence.statistics.totalCasts + 1
		return false
	end,

	---Execute rotation sequence (smart cooldown rotation)
	---@param sequence table
	---@return boolean success
	ExecuteRotationSequence = function(sequence)
		local startIndex = sequence.currentIndex

		-- Try each spell starting from current position
		for i = 1, #sequence.spells do
			local index = ((sequence.currentIndex - 1 + i - 1) % #sequence.spells) + 1
			local spellId = sequence.spells[index]

			if SpellSequencer.IsSpellAvailable(spellId, sequence.options.respectCooldowns) then
				local success = SpellSequencer.CastSpellFromSequence(spellId, sequence)
				if success then
					sequence.currentIndex = (index % #sequence.spells) + 1
					sequence.statistics.successfulCasts = sequence.statistics.successfulCasts + 1
					sequence.statistics.totalCasts = sequence.statistics.totalCasts + 1
					sequence.statistics.lastUsed = GetTime()
					return true
				elseif not sequence.options.skipUnavailable then
					-- If we don't skip unavailable spells, stop here
					break
				end
			end
		end

		sequence.statistics.totalCasts = sequence.statistics.totalCasts + 1
		return false
	end,

	---Cast spell from sequence with validation
	---@param spellId number|string
	---@param sequence table
	---@return boolean success
	CastSpellFromSequence = function(spellId, sequence)
		-- Convert spell name to ID if needed
		if type(spellId) == 'string' then
			local spellInfo = GetSpellInfo(spellId)
			if not spellInfo then return false end
			spellId = spellInfo
		end

		-- Validate spell
		if not C_SpellBook.IsSpellInSpellBook(spellId) then return false end

		local usable, noMana = IsUsableSpell(spellId)
		if not usable or noMana then return false end

		-- Cast the spell
		CastSpell(spellId)
		sequence.lastCast = GetTime()

		return true
	end,

	---Check if spell is available for casting
	---@param spellId number|string
	---@param respectCooldowns boolean
	---@return boolean available
	IsSpellAvailable = function(spellId, respectCooldowns)
		-- Convert spell name to ID if needed
		if type(spellId) == 'string' then
			local spellInfo = GetSpellInfo(spellId)
			if not spellInfo then return false end
			spellId = spellInfo
		end

		-- Check if spell is known
		if not C_SpellBook.IsSpellInSpellBook(spellId) then return false end

		-- Check usability
		local usable, noMana = IsUsableSpell(spellId)
		if not usable or noMana then return false end

		-- Check cooldown if requested
		if respectCooldowns then
			local start, duration = GetSpellCooldown(spellId)
			if start and duration and duration > 0 then
				local timeLeft = (start + duration) - GetTime()
				if timeLeft > 0 then return false end
			end
		end

		return true
	end,

	---Evaluate a condition string
	---@param condition string
	---@return boolean result
	EvaluateCondition = function(condition)
		-- Basic condition evaluation
		-- This could be expanded to support more complex conditions

		if condition == 'combat' then
			return UnitAffectingCombat('player')
		elseif condition == 'nocombat' then
			return not UnitAffectingCombat('player')
		elseif condition == 'mounted' then
			return IsMounted()
		elseif condition == 'notmounted' then
			return not IsMounted()
		elseif condition == 'ingroup' then
			return IsInGroup()
		elseif condition == 'notingroup' then
			return not IsInGroup()
		elseif condition == 'inraid' then
			return IsInRaid()
		elseif condition == 'notinraid' then
			return not IsInRaid()
		elseif condition:match('^health<(%d+)$') then
			local threshold = tonumber(condition:match('(%d+)'))
			return (UnitHealth('player') / UnitHealthMax('player')) * 100 < threshold
		elseif condition:match('^health>(%d+)$') then
			local threshold = tonumber(condition:match('(%d+)'))
			return (UnitHealth('player') / UnitHealthMax('player')) * 100 > threshold
		elseif condition:match('^mana<(%d+)$') then
			local threshold = tonumber(condition:match('(%d+)'))
			return (UnitPower('player') / UnitPowerMax('player')) * 100 < threshold
		elseif condition:match('^mana>(%d+)$') then
			local threshold = tonumber(condition:match('(%d+)'))
			return (UnitPower('player') / UnitPowerMax('player')) * 100 > threshold
		end

		-- Default to true for unknown conditions
		return true
	end,

	---Pause a sequence
	---@param name string
	PauseSequence = function(name)
		local sequence = SpellSequencer.sequences[name]
		if sequence then
			sequence.enabled = false
			if SpellSequencer.activeSequence == name then SpellSequencer.activeSequence = nil end
		end
	end,

	---Resume a sequence
	---@param name string
	ResumeSequence = function(name)
		local sequence = SpellSequencer.sequences[name]
		if sequence then sequence.enabled = true end
	end,

	---Reset a sequence to beginning
	---@param name string
	ResetSequence = function(name)
		local sequence = SpellSequencer.sequences[name]
		if sequence then
			sequence.currentIndex = 1
			sequence.lastCast = 0
		end
	end,

	---Delete a sequence
	---@param name string
	DeleteSequence = function(name)
		SpellSequencer.sequences[name] = nil
		if SpellSequencer.activeSequence == name then SpellSequencer.activeSequence = nil end
	end,

	---Get sequence status
	---@param name string
	---@return table? status
	GetSequenceStatus = function(name)
		local sequence = SpellSequencer.sequences[name]
		if not sequence then return nil end

		return {
			name = sequence.name,
			type = sequence.type,
			enabled = sequence.enabled,
			currentIndex = sequence.currentIndex,
			totalSpells = #sequence.spells,
			progress = sequence.currentIndex / #sequence.spells,
			statistics = sequence.statistics,
			nextSpell = sequence.spells[sequence.currentIndex],
		}
	end,

	---Get next spell in sequence
	---@param name string
	---@return number? spellId
	GetNextSpell = function(name)
		local sequence = SpellSequencer.sequences[name]
		if not sequence or not sequence.enabled then return nil end

		if sequence.type == 'linear' or sequence.type == 'rotation' then
			return sequence.spells[sequence.currentIndex]
		elseif sequence.type == 'priority' then
			-- Return highest priority available spell
			local sortedSpells = {}
			for i, spellId in ipairs(sequence.spells) do
				local priority = sequence.options.priorities[spellId] or i
				table.insert(sortedSpells, { spellId = spellId, priority = priority })
			end

			table.sort(sortedSpells, function(a, b)
				return a.priority < b.priority
			end)

			for _, spellData in ipairs(sortedSpells) do
				if SpellSequencer.IsSpellAvailable(spellData.spellId, true) then return spellData.spellId end
			end
		elseif sequence.type == 'conditional' then
			-- Return first spell with met condition
			for i, spellId in ipairs(sequence.spells) do
				local condition = sequence.options.conditions[spellId]
				if condition and SpellSequencer.EvaluateCondition(condition) then return spellId end
			end
			return sequence.options.fallback
		end

		return nil
	end,

	---Get sequence progress (0-1)
	---@param name string
	---@return number progress
	GetSequenceProgress = function(name)
		local sequence = SpellSequencer.sequences[name]
		if not sequence then return 0 end

		if sequence.type == 'linear' then
			return sequence.currentIndex / #sequence.spells
		elseif sequence.type == 'rotation' then
			return sequence.currentIndex / #sequence.spells
		else
			-- For priority and conditional, progress is based on last cast time
			local timeSinceLastCast = GetTime() - sequence.lastCast
			return math.min(timeSinceLastCast / 5, 1) -- 5 second cycle
		end
	end,

	---Create a smart sequence with AI-like behavior
	---@param name string
	---@param spells table<number, string|number>
	---@param intelligence table
	---@return boolean success
	CreateSmartSequence = function(name, spells, intelligence)
		intelligence = intelligence or {}

		-- Default intelligence settings
		local defaults = {
			adaptToCombat = true,
			learnFromFailures = true,
			optimizeForSituation = true,
			respectThreat = false,
			conserveMana = false,
		}

		for key, defaultValue in pairs(defaults) do
			if intelligence[key] == nil then intelligence[key] = defaultValue end
		end

		-- Create conditional sequence with smart logic
		local conditions = {}
		local priorities = {}

		for i, spellId in ipairs(spells) do
			-- Set default priority
			priorities[spellId] = i

			-- Add intelligent conditions based on spell type
			if intelligence.adaptToCombat then
				-- Different behavior in/out of combat
				if i <= #spells / 2 then
					conditions[spellId] = 'combat'
				else
					conditions[spellId] = 'nocombat'
				end
			end
		end

		return SpellSequencer.CreateSequence(name, spells, 'conditional', {
			conditions = conditions,
			priorities = priorities,
			intelligence = intelligence,
		})
	end,

	---Optimize sequence for rotation efficiency
	---@param name string
	OptimizeSequenceForRotation = function(name)
		local sequence = SpellSequencer.sequences[name]
		if not sequence then return false end

		-- Analyze spell cooldowns and reorder for efficiency
		local spellData = {}
		for i, spellId in ipairs(sequence.spells) do
			local start, duration = GetSpellCooldown(spellId)
			spellData[i] = {
				spellId = spellId,
				cooldown = duration or 0,
				index = i,
			}
		end

		-- Sort by cooldown (shortest first for more frequent use)
		table.sort(spellData, function(a, b)
			return a.cooldown < b.cooldown
		end)

		-- Rebuild spell list
		local optimizedSpells = {}
		for i, data in ipairs(spellData) do
			optimizedSpells[i] = data.spellId
		end

		sequence.spells = optimizedSpells
		return true
	end,

	---Add conditions to existing sequence
	---@param name string
	---@param newConditions table<number, string>
	AddSequenceConditions = function(name, newConditions)
		local sequence = SpellSequencer.sequences[name]
		if not sequence then return false end

		sequence.options.conditions = sequence.options.conditions or {}

		for spellId, condition in pairs(newConditions) do
			sequence.options.conditions[spellId] = condition
		end

		return true
	end,

	---Get all sequences
	---@return table<string, table>
	GetAllSequences = function()
		return SpellSequencer.sequences
	end,

	---Get currently active sequence
	---@return string? name
	GetActiveSequence = function()
		return SpellSequencer.activeSequence
	end,

	---Export sequence as shareable string
	---@param name string
	---@return string? sequenceString
	ExportSequence = function(name)
		local sequence = SpellSequencer.sequences[name]
		if not sequence then return nil end

		local exportData = {
			name = sequence.name,
			spells = sequence.spells,
			type = sequence.type,
			options = sequence.options,
			version = 1,
		}

		return SUI:Serialize(exportData)
	end,

	---Import sequence from string
	---@param sequenceString string
	---@return boolean success
	---@return string? errorMessage
	ImportSequence = function(sequenceString)
		local success, data = SUI:Deserialize(sequenceString)
		if not success or not data then return false, 'Invalid sequence data' end

		-- Validate imported data
		if not data.name or not data.spells or not data.type then return false, 'Missing required sequence fields' end

		-- Create the sequence
		local created = SpellSequencer.CreateSequence(data.name, data.spells, data.type, data.options)
		if created then
			return true
		else
			return false, 'Failed to create sequence'
		end
	end,
}

TotemBar.SpellSequencer = SpellSequencer

---Enhanced Drag & Drop System with visual feedback and validation
local DragDropManager = {
	dragState = {
		isDragging = false,
		dragType = nil,
		sourceButton = nil,
		dragData = nil,
		startTime = 0,
	},

	dropIndicators = {},
	highlightFrames = {},

	-- Drag types
	DRAG_SPELL = 'spell',
	DRAG_BUTTON = 'button',
	DRAG_MACRO = 'macro',
	DRAG_ITEM = 'item',
	DRAG_SEQUENCE = 'sequence',

	---Initialize drag drop system
	Initialize = function()
		-- Create drop indicators for each button
		for i = 1, MAX_BUTTONS do
			DragDropManager.CreateDropIndicator(i)
			DragDropManager.CreateHighlightFrame(i)
		end

		-- Create global drop indicator for bar
		DragDropManager.CreateBarDropIndicator()
	end,

	---Create drop indicator for a button slot
	---@param slotIndex number
	CreateDropIndicator = function(slotIndex)
		local button = totemButtons[slotIndex]
		if not button then return end

		local indicator = CreateFrame('Frame', 'TotemBar_DropIndicator_' .. slotIndex, button)
		indicator:SetAllPoints(button)
		indicator:SetFrameLevel(button:GetFrameLevel() + 10)
		indicator:Hide()

		-- Create indicator texture
		indicator.texture = indicator:CreateTexture(nil, 'OVERLAY')
		indicator.texture:SetAllPoints()
		indicator.texture:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')
		indicator.texture:SetColorTexture(0, 1, 0, 0.3) -- Green overlay

		-- Create border
		indicator.border = indicator:CreateTexture(nil, 'OVERLAY')
		indicator.border:SetAllPoints()
		indicator.border:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')
		indicator.border:SetColorTexture(0, 1, 0, 0.8)
		indicator.border:SetDrawLayer('OVERLAY', 1)

		-- Create animation for pulsing effect
		indicator.animGroup = indicator:CreateAnimationGroup()
		indicator.animGroup:SetLooping('BOUNCE')

		local alpha = indicator.animGroup:CreateAnimation('Alpha')
		alpha:SetFromAlpha(0.3)
		alpha:SetToAlpha(0.7)
		alpha:SetDuration(0.5)
		alpha:SetSmoothing('IN_OUT')

		DragDropManager.dropIndicators[slotIndex] = indicator
	end,

	---Create highlight frame for button
	---@param slotIndex number
	CreateHighlightFrame = function(slotIndex)
		local button = totemButtons[slotIndex]
		if not button then return end

		local highlight = CreateFrame('Frame', 'TotemBar_Highlight_' .. slotIndex, button)
		highlight:SetAllPoints(button)
		highlight:SetFrameLevel(button:GetFrameLevel() + 5)
		highlight:Hide()

		-- Valid drop highlight (green)
		highlight.valid = highlight:CreateTexture(nil, 'OVERLAY')
		highlight.valid:SetAllPoints()
		highlight.valid:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')
		highlight.valid:SetColorTexture(0, 1, 0, 0.4)

		-- Invalid drop highlight (red)
		highlight.invalid = highlight:CreateTexture(nil, 'OVERLAY')
		highlight.invalid:SetAllPoints()
		highlight.invalid:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')
		highlight.invalid:SetColorTexture(1, 0, 0, 0.4)

		DragDropManager.highlightFrames[slotIndex] = highlight
	end,

	---Create bar-level drop indicator
	CreateBarDropIndicator = function()
		local indicator = CreateFrame('Frame', 'TotemBar_BarDropIndicator', barFrame)
		indicator:SetAllPoints(barFrame)
		indicator:SetFrameLevel(barFrame:GetFrameLevel() + 15)
		indicator:Hide()

		-- Bar highlight
		indicator.texture = indicator:CreateTexture(nil, 'OVERLAY')
		indicator.texture:SetAllPoints()
		indicator.texture:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')
		indicator.texture:SetColorTexture(0, 0.5, 1, 0.2) -- Blue overlay

		-- Pulsing animation
		indicator.animGroup = indicator:CreateAnimationGroup()
		indicator.animGroup:SetLooping('BOUNCE')

		local alpha = indicator.animGroup:CreateAnimation('Alpha')
		alpha:SetFromAlpha(0.1)
		alpha:SetToAlpha(0.4)
		alpha:SetDuration(0.8)
		alpha:SetSmoothing('IN_OUT')

		DragDropManager.barDropIndicator = indicator
	end,

	---Start drag operation
	---@param button TotemBar.ActionButton
	---@param cursor string
	---@return boolean success
	StartDrag = function(button, cursor)
		-- Determine drag type and data
		local dragType, dragData = DragDropManager.GetDragInfo(button, cursor)
		if not dragType then return false end

		-- Set drag state
		DragDropManager.dragState = {
			isDragging = true,
			dragType = dragType,
			sourceButton = button,
			dragData = dragData,
			startTime = GetTime(),
		}

		-- Show appropriate visual feedback
		DragDropManager.UpdateDragFeedback()

		-- Register for drag events
		DragDropManager.RegisterDragEvents()

		return true
	end,

	---Update drag operation
	---@param x number
	---@param y number
	UpdateDrag = function(x, y)
		if not DragDropManager.dragState.isDragging then return end

		-- Find target under cursor
		local target = DragDropManager.GetTargetUnderCursor(x, y)

		-- Update visual feedback
		DragDropManager.UpdateDropHighlights(target)
	end,

	---End drag operation
	---@param targetButton TotemBar.ActionButton?
	---@return boolean success
	EndDrag = function(targetButton)
		if not DragDropManager.dragState.isDragging then return false end

		local success = false

		-- Validate and execute drop
		if targetButton and DragDropManager.ValidateDropTarget(DragDropManager.dragState.sourceButton, targetButton) then
			success = DragDropManager.ExecuteDrop(DragDropManager.dragState.sourceButton, targetButton)
		end

		-- Clean up drag state
		DragDropManager.CleanupDrag()

		return success
	end,

	---Cancel drag operation
	CancelDrag = function()
		if DragDropManager.dragState.isDragging then DragDropManager.CleanupDrag() end
	end,

	---Get drag information from button and cursor
	---@param button TotemBar.ActionButton
	---@param cursor string
	---@return string? dragType
	---@return table? dragData
	GetDragInfo = function(button, cursor)
		-- Check cursor first
		local cursorType, cursorData = GetCursorInfo()
		if cursorType then
			if cursorType == 'spell' then
				return DragDropManager.DRAG_SPELL, { spellId = cursorData }
			elseif cursorType == 'macro' then
				return DragDropManager.DRAG_MACRO, { macroId = cursorData }
			elseif cursorType == 'item' then
				return DragDropManager.DRAG_ITEM, { itemId = cursorData }
			end
		end

		-- Check button contents
		if button.spellId and button.spellId > 0 then
			return DragDropManager.DRAG_SPELL, { spellId = button.spellId }
		elseif button.totemData then
			return DragDropManager.DRAG_BUTTON, { buttonData = button.totemData }
		end

		return nil, nil
	end,

	---Get target button under cursor
	---@param x number
	---@param y number
	---@return TotemBar.ActionButton? target
	GetTargetUnderCursor = function(x, y)
		-- Check each button
		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button and button:IsVisible() then
				if DragDropManager.IsPointInFrame(button, x, y) then return button end
			end
		end

		return nil
	end,

	---Check if point is within frame
	---@param frame Frame
	---@param x number
	---@param y number
	---@return boolean
	IsPointInFrame = function(frame, x, y)
		local left = frame:GetLeft()
		local right = frame:GetRight()
		local top = frame:GetTop()
		local bottom = frame:GetBottom()

		return x >= left and x <= right and y >= bottom and y <= top
	end,

	---Validate drop target
	---@param source TotemBar.ActionButton
	---@param target TotemBar.ActionButton
	---@return boolean valid
	---@return string? reason
	ValidateDropTarget = function(source, target)
		if not source or not target then return false, 'Invalid source or target' end

		if source == target then return false, 'Cannot drop on self' end

		local dragType = DragDropManager.dragState.dragType
		local dragData = DragDropManager.dragState.dragData

		-- Validate based on drag type
		if dragType == DragDropManager.DRAG_SPELL then
			return DragDropManager.CanDropSpellOnButton(dragData.spellId, target)
		elseif dragType == DragDropManager.DRAG_MACRO then
			return DragDropManager.CanDropMacroOnButton(dragData.macroId, target)
		elseif dragType == DragDropManager.DRAG_ITEM then
			return DragDropManager.CanDropItemOnButton(dragData.itemId, target)
		elseif dragType == DragDropManager.DRAG_BUTTON then
			return true, nil -- Button swapping always allowed
		end

		return false, 'Unknown drag type'
	end,

	---Check if spell can be dropped on button
	---@param spellId number
	---@param button TotemBar.ActionButton
	---@return boolean valid
	---@return string? reason
	CanDropSpellOnButton = function(spellId, button)
		-- Check if spell exists
		local spellName = GetSpellInfo(spellId)
		if not spellName then return false, 'Spell not found' end

		-- Check if player knows the spell
		if not C_SpellBook.IsSpellInSpellBook(spellId) then return false, 'Spell not known' end

		-- Check class restrictions (for multi-class support)
		local playerClass = select(2, UnitClass('player'))
		if not DragDropManager.IsSpellValidForClass(spellId, playerClass) then return false, 'Spell not valid for class' end

		return true, nil
	end,

	---Check if macro can be dropped on button
	---@param macroId number
	---@param button TotemBar.ActionButton
	---@return boolean valid
	---@return string? reason
	CanDropMacroOnButton = function(macroId, button)
		local name, icon, body = GetMacroInfo(macroId)
		if not name then return false, 'Macro not found' end

		-- Validate macro syntax
		local valid, error = MacroSystem.ValidateMacroSyntax(body)
		if not valid then return false, 'Invalid macro: ' .. (error or 'Unknown error') end

		return true, nil
	end,

	---Check if item can be dropped on button
	---@param itemId number
	---@param button TotemBar.ActionButton
	---@return boolean valid
	---@return string? reason
	CanDropItemOnButton = function(itemId, button)
		local itemName = C_Item.GetItemInfo(itemId)
		if not itemName then return false, 'Item not found' end

		-- Check if item is usable
		local usable = C_Item.GetItemInfo(itemId)
		if not usable then return false, 'Item not usable' end

		return true, nil
	end,

	---Check if spell is valid for class
	---@param spellId number
	---@param class string
	---@return boolean valid
	IsSpellValidForClass = function(spellId, class)
		-- Basic validation - can be expanded with spell database
		-- For now, just check if player knows the spell
		return C_SpellBook.IsSpellInSpellBook(spellId)
	end,

	---Execute drop operation
	---@param source TotemBar.ActionButton
	---@param target TotemBar.ActionButton
	---@return boolean success
	ExecuteDrop = function(source, target)
		local dragType = DragDropManager.dragState.dragType
		local dragData = DragDropManager.dragState.dragData

		if dragType == DragDropManager.DRAG_SPELL then
			target:SetSpell(dragData.spellId)
			ClearCursor()
			return true
		elseif dragType == DragDropManager.DRAG_MACRO then
			-- Set macro on button (would need macro support in ActionButton)
			-- For now, just clear cursor
			ClearCursor()
			return true
		elseif dragType == DragDropManager.DRAG_ITEM then
			-- Set item on button (would need item support in ActionButton)
			ClearCursor()
			return true
		elseif dragType == DragDropManager.DRAG_BUTTON then
			-- Swap button contents
			DragDropManager.SwapButtons(source, target)
			return true
		end

		return false
	end,

	---Swap contents of two buttons
	---@param button1 TotemBar.ActionButton
	---@param button2 TotemBar.ActionButton
	SwapButtons = function(button1, button2)
		-- Store button1 data
		local spell1 = button1.spellId
		local totem1 = button1.totemData

		-- Copy button2 to button1
		if button2.spellId and button2.spellId > 0 then
			button1:SetSpell(button2.spellId)
		else
			button1:ClearSpell()
		end

		-- Copy button1 data to button2
		if spell1 and spell1 > 0 then
			button2:SetSpell(spell1)
		else
			button2:ClearSpell()
		end
	end,

	---Update drag feedback visuals
	UpdateDragFeedback = function()
		if not DragDropManager.dragState.isDragging then return end

		-- Show bar indicator for new spell assignment
		if DragDropManager.dragState.dragType == DragDropManager.DRAG_SPELL then DragDropManager.ShowBarDropIndicator() end
	end,

	---Update drop highlights on buttons
	---@param targetButton TotemBar.ActionButton?
	UpdateDropHighlights = function(targetButton)
		-- Clear all highlights first
		DragDropManager.ClearAllHighlights()

		if not targetButton then return end

		-- Validate drop
		local valid, reason = DragDropManager.ValidateDropTarget(DragDropManager.dragState.sourceButton, targetButton)

		-- Show appropriate highlight
		local highlight = DragDropManager.highlightFrames[targetButton.slotIndex]
		if highlight then
			if valid then
				highlight.valid:Show()
				highlight.invalid:Hide()
			else
				highlight.valid:Hide()
				highlight.invalid:Show()
			end
			highlight:Show()
		end

		-- Show tooltip with reason if invalid
		if not valid and reason then
			GameTooltip:SetOwner(targetButton, 'ANCHOR_CURSOR')
			GameTooltip:SetText('Invalid Drop')
			GameTooltip:AddLine(reason, 1, 0.5, 0.5)
			GameTooltip:Show()
		end
	end,

	---Show drop indicator for position
	---@param position number
	ShowDropIndicator = function(position)
		local indicator = DragDropManager.dropIndicators[position]
		if indicator then
			indicator:Show()
			indicator.animGroup:Play()
		end
	end,

	---Hide drop indicator
	---@param position number?
	HideDropIndicator = function(position)
		if position then
			local indicator = DragDropManager.dropIndicators[position]
			if indicator then
				indicator:Hide()
				indicator.animGroup:Stop()
			end
		else
			-- Hide all indicators
			for i = 1, MAX_BUTTONS do
				DragDropManager.HideDropIndicator(i)
			end
		end
	end,

	---Show bar drop indicator
	ShowBarDropIndicator = function()
		if DragDropManager.barDropIndicator then
			DragDropManager.barDropIndicator:Show()
			DragDropManager.barDropIndicator.animGroup:Play()
		end
	end,

	---Hide bar drop indicator
	HideBarDropIndicator = function()
		if DragDropManager.barDropIndicator then
			DragDropManager.barDropIndicator:Hide()
			DragDropManager.barDropIndicator.animGroup:Stop()
		end
	end,

	---Clear all highlights
	ClearAllHighlights = function()
		for i = 1, MAX_BUTTONS do
			local highlight = DragDropManager.highlightFrames[i]
			if highlight then highlight:Hide() end
		end
		GameTooltip:Hide()
	end,

	---Register drag events
	RegisterDragEvents = function()
		-- Hook into cursor update
		DragDropManager.dragUpdateFrame = CreateFrame('Frame')
		DragDropManager.dragUpdateFrame:SetScript('OnUpdate', function()
			if DragDropManager.dragState.isDragging then
				local x, y = GetCursorPosition()
				DragDropManager.UpdateDrag(x, y)
			end
		end)
	end,

	---Unregister drag events
	UnregisterDragEvents = function()
		if DragDropManager.dragUpdateFrame then
			DragDropManager.dragUpdateFrame:SetScript('OnUpdate', nil)
			DragDropManager.dragUpdateFrame = nil
		end
	end,

	---Clean up drag operation
	CleanupDrag = function()
		-- Reset drag state
		DragDropManager.dragState = {
			isDragging = false,
			dragType = nil,
			sourceButton = nil,
			dragData = nil,
			startTime = 0,
		}

		-- Hide all visual feedback
		DragDropManager.HideDropIndicator()
		DragDropManager.HideBarDropIndicator()
		DragDropManager.ClearAllHighlights()

		-- Unregister events
		DragDropManager.UnregisterDragEvents()
	end,

	---Get drag state
	---@return table dragState
	GetDragState = function()
		return DragDropManager.dragState
	end,

	---Check if currently dragging
	---@return boolean isDragging
	IsDragging = function()
		return DragDropManager.dragState.isDragging
	end,
}

TotemBar.DragDropManager = DragDropManager

---Advanced Layout Engine with support for multiple layout algorithms
local LayoutEngine = {
	currentLayout = 'horizontal',

	---Layout algorithms with their configurations
	layouts = {
		horizontal = {
			name = 'Horizontal',
			description = 'Buttons arranged left to right',
			direction = 'left-to-right',
			wrap = false,
			defaultSpacing = 2,
			defaultPadding = 0,
			supportedOptions = { 'spacing', 'padding', 'scale', 'reverse' },
		},
		vertical = {
			name = 'Vertical',
			description = 'Buttons arranged top to bottom',
			direction = 'top-to-bottom',
			wrap = false,
			defaultSpacing = 2,
			defaultPadding = 0,
			supportedOptions = { 'spacing', 'padding', 'scale', 'reverse' },
		},
		grid = {
			name = 'Grid',
			description = 'Buttons arranged in a grid pattern',
			direction = 'grid',
			wrap = true,
			defaultSpacing = 2,
			defaultPadding = 4,
			defaultColumns = 2,
			defaultRows = 2,
			supportedOptions = { 'columns', 'rows', 'spacing', 'padding', 'scale', 'fillDirection' },
		},
		circular = {
			name = 'Circular',
			description = 'Buttons arranged in a circle',
			direction = 'circular',
			wrap = false,
			defaultSpacing = 0,
			defaultPadding = 0,
			defaultRadius = 60,
			defaultStartAngle = 0,
			defaultEndAngle = 360,
			supportedOptions = { 'radius', 'startAngle', 'endAngle', 'clockwise', 'scale' },
		},
		arc = {
			name = 'Arc',
			description = 'Buttons arranged in an arc',
			direction = 'arc',
			wrap = false,
			defaultSpacing = 0,
			defaultPadding = 0,
			defaultRadius = 80,
			defaultStartAngle = -60,
			defaultEndAngle = 60,
			supportedOptions = { 'radius', 'startAngle', 'endAngle', 'scale' },
		},
		cross = {
			name = 'Cross',
			description = 'Buttons arranged in a cross/plus pattern',
			direction = 'cross',
			wrap = false,
			defaultSpacing = 2,
			defaultPadding = 0,
			supportedOptions = { 'spacing', 'scale', 'centerButton' },
		},
	},

	---Apply layout to buttons
	---@param layoutType string
	---@param options table?
	ApplyLayout = function(layoutType, options)
		layoutType = layoutType or LayoutEngine.currentLayout
		options = options or {}

		local layout = LayoutEngine.layouts[layoutType]
		if not layout then
			layoutType = 'horizontal'
			layout = LayoutEngine.layouts[layoutType]
		end

		-- Merge options with defaults
		local layoutOptions = LayoutEngine.GetLayoutOptions(layoutType, options)

		-- Store current layout
		LayoutEngine.currentLayout = layoutType

		-- Apply layout based on type
		if layoutType == 'horizontal' then
			LayoutEngine.ApplyHorizontalLayout(layoutOptions)
		elseif layoutType == 'vertical' then
			LayoutEngine.ApplyVerticalLayout(layoutOptions)
		elseif layoutType == 'grid' then
			LayoutEngine.ApplyGridLayout(layoutOptions)
		elseif layoutType == 'circular' then
			LayoutEngine.ApplyCircularLayout(layoutOptions)
		elseif layoutType == 'arc' then
			LayoutEngine.ApplyArcLayout(layoutOptions)
		elseif layoutType == 'cross' then
			LayoutEngine.ApplyCrossLayout(layoutOptions)
		end

		-- Update bar size and scale
		LayoutEngine.UpdateBarDimensions(layoutType, layoutOptions)

		-- Apply scale to all buttons
		if layoutOptions.scale and layoutOptions.scale ~= 1.0 then LayoutEngine.ApplyScale(layoutOptions.scale) end
	end,

	---Get layout options with defaults
	---@param layoutType string
	---@param userOptions table
	---@return table options
	GetLayoutOptions = function(layoutType, userOptions)
		local layout = LayoutEngine.layouts[layoutType]
		local options = {}

		-- Copy user options
		for key, value in pairs(userOptions) do
			options[key] = value
		end

		-- Apply defaults for missing options
		options.spacing = options.spacing or layout.defaultSpacing or 2
		options.padding = options.padding or layout.defaultPadding or 0
		options.scale = options.scale or 1.0

		-- Layout-specific defaults
		if layoutType == 'grid' then
			options.columns = options.columns or layout.defaultColumns or 2
			options.rows = options.rows or layout.defaultRows or 2
			options.fillDirection = options.fillDirection or 'horizontal'
		elseif layoutType == 'circular' then
			options.radius = options.radius or layout.defaultRadius or 60
			options.startAngle = options.startAngle or layout.defaultStartAngle or 0
			options.endAngle = options.endAngle or layout.defaultEndAngle or 360
			options.clockwise = options.clockwise ~= false -- Default true
		elseif layoutType == 'arc' then
			options.radius = options.radius or layout.defaultRadius or 80
			options.startAngle = options.startAngle or layout.defaultStartAngle or -60
			options.endAngle = options.endAngle or layout.defaultEndAngle or 60
		elseif layoutType == 'cross' then
			options.centerButton = options.centerButton ~= false -- Default true
		end

		return options
	end,

	---Apply horizontal layout
	---@param options table
	ApplyHorizontalLayout = function(options)
		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button then
				button:ClearAllPoints()

				if options.reverse then
					-- Right to left
					if i == 1 then
						button:SetPoint('RIGHT', barFrame, 'RIGHT', -options.padding, 0)
					else
						button:SetPoint('RIGHT', totemButtons[i - 1], 'LEFT', -options.spacing, 0)
					end
				else
					-- Left to right
					if i == 1 then
						button:SetPoint('LEFT', barFrame, 'LEFT', options.padding, 0)
					else
						button:SetPoint('LEFT', totemButtons[i - 1], 'RIGHT', options.spacing, 0)
					end
				end
			end
		end
	end,

	---Apply vertical layout
	---@param options table
	ApplyVerticalLayout = function(options)
		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button then
				button:ClearAllPoints()

				if options.reverse then
					-- Bottom to top
					if i == 1 then
						button:SetPoint('BOTTOM', barFrame, 'BOTTOM', 0, options.padding)
					else
						button:SetPoint('BOTTOM', totemButtons[i - 1], 'TOP', 0, options.spacing)
					end
				else
					-- Top to bottom
					if i == 1 then
						button:SetPoint('TOP', barFrame, 'TOP', 0, -options.padding)
					else
						button:SetPoint('TOP', totemButtons[i - 1], 'BOTTOM', 0, -options.spacing)
					end
				end
			end
		end
	end,

	---Apply grid layout
	---@param options table
	ApplyGridLayout = function(options)
		local cols = options.columns
		local rows = options.rows

		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button then
				button:ClearAllPoints()

				local col, row
				if options.fillDirection == 'vertical' then
					-- Fill columns first
					col = math.ceil(i / rows)
					row = ((i - 1) % rows) + 1
				else
					-- Fill rows first (default)
					row = math.ceil(i / cols)
					col = ((i - 1) % cols) + 1
				end

				-- Calculate position
				local x = (col - 1) * (BUTTON_SIZE + options.spacing) + options.padding
				local y = -((row - 1) * (BUTTON_SIZE + options.spacing) + options.padding)

				button:SetPoint('TOPLEFT', barFrame, 'TOPLEFT', x, y)
			end
		end
	end,

	---Apply circular layout
	---@param options table
	ApplyCircularLayout = function(options)
		local radius = options.radius
		local startAngle = math.rad(options.startAngle)
		local endAngle = math.rad(options.endAngle)
		local clockwise = options.clockwise

		-- Calculate angle step
		local totalAngle = endAngle - startAngle
		if totalAngle < 0 then totalAngle = totalAngle + math.pi * 2 end

		local angleStep = totalAngle / (MAX_BUTTONS - 1)
		if MAX_BUTTONS == 1 then angleStep = 0 end

		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button then
				button:ClearAllPoints()

				local angle = startAngle + (i - 1) * angleStep
				if not clockwise then angle = startAngle - (i - 1) * angleStep end

				local x = radius * math.cos(angle)
				local y = radius * math.sin(angle)

				button:SetPoint('CENTER', barFrame, 'CENTER', x, y)
			end
		end
	end,

	---Apply arc layout
	---@param options table
	ApplyArcLayout = function(options)
		local radius = options.radius
		local startAngle = math.rad(options.startAngle)
		local endAngle = math.rad(options.endAngle)

		-- Calculate angle step
		local totalAngle = endAngle - startAngle
		local angleStep = totalAngle / (MAX_BUTTONS - 1)
		if MAX_BUTTONS == 1 then angleStep = 0 end

		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button then
				button:ClearAllPoints()

				local angle = startAngle + (i - 1) * angleStep
				local x = radius * math.cos(angle)
				local y = radius * math.sin(angle)

				button:SetPoint('CENTER', barFrame, 'CENTER', x, y)
			end
		end
	end,

	---Apply cross layout
	---@param options table
	ApplyCrossLayout = function(options)
		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button then
				button:ClearAllPoints()

				if i == 1 and options.centerButton then
					-- Center button
					button:SetPoint('CENTER', barFrame, 'CENTER', 0, 0)
				else
					-- Calculate cross position
					local adjustedIndex = options.centerButton and (i - 1) or i
					local direction = ((adjustedIndex - 1) % 4) + 1
					local distance = BUTTON_SIZE + options.spacing

					if direction == 1 then -- Top
						button:SetPoint('CENTER', barFrame, 'CENTER', 0, distance)
					elseif direction == 2 then -- Right
						button:SetPoint('CENTER', barFrame, 'CENTER', distance, 0)
					elseif direction == 3 then -- Bottom
						button:SetPoint('CENTER', barFrame, 'CENTER', 0, -distance)
					elseif direction == 4 then -- Left
						button:SetPoint('CENTER', barFrame, 'CENTER', -distance, 0)
					end
				end
			end
		end
	end,

	---Update bar dimensions based on layout
	---@param layoutType string
	---@param options table
	UpdateBarDimensions = function(layoutType, options)
		local width, height = LayoutEngine.CalculateBarSize(layoutType, options)
		barFrame:SetSize(width, height)
	end,

	---Calculate bar size for layout
	---@param layoutType string
	---@param options table
	---@return number width
	---@return number height
	CalculateBarSize = function(layoutType, options)
		if layoutType == 'horizontal' then
			local width = (BUTTON_SIZE * MAX_BUTTONS) + (options.spacing * (MAX_BUTTONS - 1)) + (options.padding * 2)
			return width, BUTTON_SIZE + (options.padding * 2)
		elseif layoutType == 'vertical' then
			local height = (BUTTON_SIZE * MAX_BUTTONS) + (options.spacing * (MAX_BUTTONS - 1)) + (options.padding * 2)
			return BUTTON_SIZE + (options.padding * 2), height
		elseif layoutType == 'grid' then
			local cols = options.columns
			local rows = options.rows
			local width = (BUTTON_SIZE * cols) + (options.spacing * (cols - 1)) + (options.padding * 2)
			local height = (BUTTON_SIZE * rows) + (options.spacing * (rows - 1)) + (options.padding * 2)
			return width, height
		elseif layoutType == 'circular' or layoutType == 'arc' then
			local diameter = (options.radius * 2) + BUTTON_SIZE
			return diameter, diameter
		elseif layoutType == 'cross' then
			local dimension = (BUTTON_SIZE * 3) + (options.spacing * 2)
			return dimension, dimension
		end

		-- Default fallback
		return BUTTON_SIZE * MAX_BUTTONS, BUTTON_SIZE
	end,

	---Apply scale to all buttons
	---@param scale number
	ApplyScale = function(scale)
		for i = 1, MAX_BUTTONS do
			local button = totemButtons[i]
			if button then button:SetScale(scale) end
		end
	end,

	---Resize buttons to fit within maximum size
	---@param maxWidth number
	---@param maxHeight number
	ResizeButtonsToFit = function(maxWidth, maxHeight)
		local currentWidth, currentHeight = barFrame:GetSize()

		if currentWidth <= maxWidth and currentHeight <= maxHeight then
			return -- Already fits
		end

		-- Calculate scale factor needed
		local scaleX = maxWidth / currentWidth
		local scaleY = maxHeight / currentHeight
		local scale = math.min(scaleX, scaleY)

		-- Apply scale
		LayoutEngine.ApplyScale(scale)

		-- Update bar size
		barFrame:SetSize(currentWidth * scale, currentHeight * scale)
	end,

	---Get available layouts
	---@return table<string, table>
	GetAvailableLayouts = function()
		return LayoutEngine.layouts
	end,

	---Get current layout type
	---@return string layoutType
	GetCurrentLayout = function()
		return LayoutEngine.currentLayout
	end,

	---Save layout configuration
	---@param name string
	---@param layoutType string
	---@param options table
	SaveLayout = function(name, layoutType, options)
		if not TotemBar.DB.savedLayouts then TotemBar.DB.savedLayouts = {} end

		TotemBar.DB.savedLayouts[name] = {
			type = layoutType,
			options = options,
			created = GetTime(),
		}
	end,

	---Load layout configuration
	---@param name string
	---@return boolean success
	LoadLayout = function(name)
		if not TotemBar.DB.savedLayouts or not TotemBar.DB.savedLayouts[name] then return false end

		local layout = TotemBar.DB.savedLayouts[name]
		LayoutEngine.ApplyLayout(layout.type, layout.options)

		return true
	end,

	---Delete saved layout
	---@param name string
	DeleteSavedLayout = function(name)
		if TotemBar.DB.savedLayouts then TotemBar.DB.savedLayouts[name] = nil end
	end,

	---Get saved layouts
	---@return table<string, table>
	GetSavedLayouts = function()
		return TotemBar.DB.savedLayouts or {}
	end,

	---Create layout preset
	---@param presetName string
	CreateLayoutPreset = function(presetName)
		local presets = {
			compact = {
				type = 'horizontal',
				options = { spacing = 1, scale = 0.8 },
			},
			large = {
				type = 'horizontal',
				options = { spacing = 4, scale = 1.2 },
			},
			tower = {
				type = 'vertical',
				options = { spacing = 2, scale = 1.0 },
			},
			square = {
				type = 'grid',
				options = { columns = 2, rows = 2, spacing = 2 },
			},
			circle = {
				type = 'circular',
				options = { radius = 50 },
			},
			semicircle = {
				type = 'arc',
				options = { radius = 60, startAngle = -90, endAngle = 90 },
			},
			plus = {
				type = 'cross',
				options = { spacing = 3, centerButton = true },
			},
		}

		local preset = presets[presetName]
		if preset then
			LayoutEngine.ApplyLayout(preset.type, preset.options)
			return true
		end

		return false
	end,

	---Get layout presets
	---@return table<string, table>
	GetLayoutPresets = function()
		return {
			compact = { name = 'Compact Horizontal', description = 'Small horizontal bar' },
			large = { name = 'Large Horizontal', description = 'Large horizontal bar' },
			tower = { name = 'Vertical Tower', description = 'Vertical arrangement' },
			square = { name = 'Square Grid', description = '2x2 grid layout' },
			circle = { name = 'Circle', description = 'Circular arrangement' },
			semicircle = { name = 'Semicircle', description = 'Arc arrangement' },
			plus = { name = 'Plus Sign', description = 'Cross/plus arrangement' },
		}
	end,
}

TotemBar.LayoutEngine = LayoutEngine

---Multi-Class Support System with plugin framework
local ClassRegistry = {
	registeredClasses = {},
	loadedModules = {},
	currentClass = nil,

	---Class module interface template
	ClassModuleInterface = {
		-- Module identification
		name = 'BaseClass',
		supportedClasses = {},
		version = '1.0.0',
		description = 'Base class module',

		-- Lifecycle hooks
		OnLoad = function(self) end,
		OnEnable = function(self) end,
		OnDisable = function(self) end,
		OnPlayerLogin = function(self) end,
		OnSpecChanged = function(self, newSpec) end,

		-- Spell management
		GetAvailableSpells = function(self)
			return {}
		end,
		ValidateSpell = function(self, spellId)
			return true
		end,
		GetSpellCategories = function(self)
			return {}
		end,
		GetDefaultSpellAssignments = function(self)
			return {}
		end,

		-- Event handlers
		RegisterEvents = function(self) end,
		HandleEvent = function(self, event, ...) end,
		UnregisterEvents = function(self) end,

		-- Configuration
		GetDefaultSettings = function(self)
			return {}
		end,
		ValidateSettings = function(self, settings)
			return true
		end,
		GetOptionsTable = function(self)
			return {}
		end,

		-- Optional features
		SupportsFeature = function(self, featureName)
			return false
		end,
		GetCustomMenuItems = function(self)
			return {}
		end,
		GetCustomTooltipInfo = function(self, spellId)
			return nil
		end,

		-- Class-specific data
		spellDatabase = {},
		categoryMappings = {},
		defaultKeybinds = {},
	},

	---Register a class module
	---@param className string
	---@param module table
	---@return boolean success
	RegisterClass = function(className, module)
		-- Validate module interface
		if not ClassRegistry.ValidateClassModule(module) then return false end

		-- Store the module
		ClassRegistry.registeredClasses[className] = module

		-- Initialize module if player is this class
		local playerClass = select(2, UnitClass('player'))
		if playerClass == className then ClassRegistry.LoadClassModule(className) end

		return true
	end,

	---Unregister a class module
	---@param className string
	UnregisterClass = function(className)
		if ClassRegistry.loadedModules[className] then ClassRegistry.UnloadClassModule(className) end
		ClassRegistry.registeredClasses[className] = nil
	end,

	---Get class module
	---@param className string
	---@return table? module
	GetClassModule = function(className)
		return ClassRegistry.loadedModules[className] or ClassRegistry.registeredClasses[className]
	end,

	---Get all supported classes
	---@return table<string>
	GetSupportedClasses = function()
		local classes = {}
		for className in pairs(ClassRegistry.registeredClasses) do
			table.insert(classes, className)
		end
		return classes
	end,

	---Load and initialize class module
	---@param className string
	---@return boolean success
	LoadClassModule = function(className)
		local module = ClassRegistry.registeredClasses[className]
		if not module then return false end

		-- Check dependencies
		if not ClassRegistry.CheckDependencies(module) then return false end

		-- Create instance copy
		local instance = {}
		for key, value in pairs(module) do
			if type(value) == 'function' then
				instance[key] = value
			else
				instance[key] = CopyTable(value)
			end
		end

		-- Store loaded instance
		ClassRegistry.loadedModules[className] = instance
		ClassRegistry.currentClass = className

		-- Initialize module
		if instance.OnLoad then instance:OnLoad() end

		-- Register events
		if instance.RegisterEvents then instance:RegisterEvents() end

		-- Call OnEnable
		if instance.OnEnable then instance:OnEnable() end

		return true
	end,

	---Unload class module
	---@param className string
	UnloadClassModule = function(className)
		local module = ClassRegistry.loadedModules[className]
		if not module then return end

		-- Call OnDisable
		if module.OnDisable then module:OnDisable() end

		-- Unregister events
		if module.UnregisterEvents then module:UnregisterEvents() end

		-- Remove from loaded modules
		ClassRegistry.loadedModules[className] = nil

		if ClassRegistry.currentClass == className then ClassRegistry.currentClass = nil end
	end,

	---Reload class module
	---@param className string
	---@return boolean success
	ReloadClassModule = function(className)
		if ClassRegistry.loadedModules[className] then ClassRegistry.UnloadClassModule(className) end
		return ClassRegistry.LoadClassModule(className)
	end,

	---Validate class module interface
	---@param module table
	---@return boolean valid
	ValidateClassModule = function(module)
		-- Required fields
		local requiredFields = {
			'name',
			'supportedClasses',
			'version',
			'GetAvailableSpells',
			'ValidateSpell',
			'GetSpellCategories',
		}

		for _, field in pairs(requiredFields) do
			if not module[field] then return false end
		end

		-- Validate supported classes
		if type(module.supportedClasses) ~= 'table' or #module.supportedClasses == 0 then return false end

		return true
	end,

	---Check module dependencies
	---@param module table
	---@return boolean satisfied
	CheckDependencies = function(module)
		-- Basic dependency checking - can be expanded
		return true
	end,

	---Get current class module
	---@return table? module
	GetCurrentClassModule = function()
		return ClassRegistry.currentClass and ClassRegistry.loadedModules[ClassRegistry.currentClass]
	end,

	---Initialize class system
	Initialize = function()
		-- Register built-in class modules
		ClassRegistry.RegisterBuiltinClasses()

		-- Load module for current class
		local playerClass = select(2, UnitClass('player'))
		if ClassRegistry.registeredClasses[playerClass] then ClassRegistry.LoadClassModule(playerClass) end
	end,

	---Register built-in class modules
	RegisterBuiltinClasses = function()
		-- Shaman Module (Enhanced)
		ClassRegistry.RegisterClass('SHAMAN', ClassRegistry.CreateShamanModule())

		-- Hunter Module
		ClassRegistry.RegisterClass('HUNTER', ClassRegistry.CreateHunterModule())

		-- Death Knight Module
		ClassRegistry.RegisterClass('DEATHKNIGHT', ClassRegistry.CreateDeathKnightModule())

		-- Paladin Module
		ClassRegistry.RegisterClass('PALADIN', ClassRegistry.CreatePaladinModule())

		-- Warlock Module
		ClassRegistry.RegisterClass('WARLOCK', ClassRegistry.CreateWarlockModule())
	end,

	---Create Shaman module
	---@return table module
	CreateShamanModule = function()
		local module = CopyTable(ClassRegistry.ClassModuleInterface)

		module.name = 'Shaman Totem Module'
		module.supportedClasses = { 'SHAMAN' }
		module.version = '2.0.0'
		module.description = 'Advanced totem tracking and management for Shamans'

		module.spellCategories = {
			earth = { 'Earthbind Totem', 'Tremor Totem', 'Earth Elemental Totem', 'Stoneskin Totem' },
			fire = { 'Searing Totem', 'Fire Nova Totem', 'Fire Elemental Totem', 'Flametongue Totem' },
			water = { 'Healing Stream Totem', 'Mana Spring Totem', 'Cleansing Totem', 'Mana Tide Totem' },
			air = { 'Windfury Totem', 'Grace of Air Totem', 'Wrath of Air Totem', 'Tranquil Air Totem' },
		}

		module.categoryMappings = {
			[1] = 'earth',
			[2] = 'fire',
			[3] = 'water',
			[4] = 'air',
		}

		function module:GetAvailableSpells()
			local spells = {}
			for category, spellList in pairs(self.spellCategories) do
				for _, spellName in pairs(spellList) do
					local spellId = select(7, GetSpellInfo(spellName))
					if spellId and C_SpellBook.IsSpellInSpellBook(spellId) then table.insert(spells, { id = spellId, name = spellName, category = category }) end
				end
			end
			return spells
		end

		function module:ValidateSpell(spellId)
			return C_SpellBook.IsSpellInSpellBook(spellId) and GetSpellInfo(spellId) ~= nil
		end

		function module:GetSpellCategories()
			return { 'earth', 'fire', 'water', 'air' }
		end

		function module:GetDefaultSpellAssignments()
			return {
				{ spellName = 'Searing Totem', slot = 2 },
				{ spellName = 'Healing Stream Totem', slot = 3 },
				{ spellName = 'Windfury Totem', slot = 4 },
				{ spellName = 'Earthbind Totem', slot = 1 },
			}
		end

		function module:SupportsFeature(featureName)
			local supportedFeatures = {
				'totem_destruction',
				'totem_recall',
				'category_filtering',
				'auto_replacement',
				'totem_sets',
				'call_of_elements',
			}

			for _, feature in pairs(supportedFeatures) do
				if feature == featureName then return true end
			end
			return false
		end

		return module
	end,

	---Create Hunter module
	---@return table module
	CreateHunterModule = function()
		local module = CopyTable(ClassRegistry.ClassModuleInterface)

		module.name = 'Hunter Trap Module'
		module.supportedClasses = { 'HUNTER' }
		module.version = '1.0.0'
		module.description = 'Trap tracking and management for Hunters'

		module.spellCategories = {
			fire = { 'Explosive Trap', 'Immolation Trap' },
			frost = { 'Frost Trap', 'Freezing Trap' },
			nature = { 'Snake Trap' },
			arcane = { 'Arcane Trap' },
		}

		function module:GetAvailableSpells()
			local spells = {}
			for category, spellList in pairs(self.spellCategories) do
				for _, spellName in pairs(spellList) do
					local spellId = select(7, GetSpellInfo(spellName))
					if spellId and C_SpellBook.IsSpellInSpellBook(spellId) then table.insert(spells, { id = spellId, name = spellName, category = category }) end
				end
			end
			return spells
		end

		function module:GetSpellCategories()
			return { 'fire', 'frost', 'nature', 'arcane' }
		end

		function module:SupportsFeature(featureName)
			return featureName == 'trap_placement' or featureName == 'trap_timers'
		end

		return module
	end,

	---Create Death Knight module
	---@return table module
	CreateDeathKnightModule = function()
		local module = CopyTable(ClassRegistry.ClassModuleInterface)

		module.name = 'Death Knight Rune Module'
		module.supportedClasses = { 'DEATHKNIGHT' }
		module.version = '1.0.0'
		module.description = 'Rune tracking and death coil management for Death Knights'

		module.runeTypes = { 'blood', 'frost', 'unholy', 'death' }

		module.spellCategories = {
			blood = { 'Death Strike', 'Death Coil', 'Death Pact' },
			frost = { 'Icy Touch', 'Chains of Ice', 'Mind Freeze' },
			unholy = { 'Plague Strike', 'Death Grip', 'Corpse Explosion' },
			presences = { 'Blood Presence', 'Frost Presence', 'Unholy Presence' },
		}

		function module:GetAvailableSpells()
			local spells = {}
			for category, spellList in pairs(self.spellCategories) do
				for _, spellName in pairs(spellList) do
					local spellId = select(7, GetSpellInfo(spellName))
					if spellId and C_SpellBook.IsSpellInSpellBook(spellId) then table.insert(spells, { id = spellId, name = spellName, category = category }) end
				end
			end
			return spells
		end

		function module:GetSpellCategories()
			return { 'blood', 'frost', 'unholy', 'presences' }
		end

		function module:SupportsFeature(featureName)
			return featureName == 'rune_tracking' or featureName == 'presence_switching'
		end

		return module
	end,

	---Create Paladin module
	---@return table module
	CreatePaladinModule = function()
		local module = CopyTable(ClassRegistry.ClassModuleInterface)

		module.name = 'Paladin Aura Module'
		module.supportedClasses = { 'PALADIN' }
		module.version = '1.0.0'
		module.description = 'Aura and blessing management for Paladins'

		module.spellCategories = {
			auras = { 'Devotion Aura', 'Retribution Aura', 'Concentration Aura', 'Shadow Resistance Aura' },
			blessings = { 'Blessing of Might', 'Blessing of Wisdom', 'Blessing of Kings', 'Blessing of Light' },
			seals = { 'Seal of Light', 'Seal of Wisdom', 'Seal of Justice', 'Seal of Command' },
			judgements = { 'Judgement of Light', 'Judgement of Wisdom', 'Judgement of Justice' },
		}

		function module:GetAvailableSpells()
			local spells = {}
			for category, spellList in pairs(self.spellCategories) do
				for _, spellName in pairs(spellList) do
					local spellId = select(7, GetSpellInfo(spellName))
					if spellId and C_SpellBook.IsSpellInSpellBook(spellId) then table.insert(spells, { id = spellId, name = spellName, category = category }) end
				end
			end
			return spells
		end

		function module:GetSpellCategories()
			return { 'auras', 'blessings', 'seals', 'judgements' }
		end

		function module:SupportsFeature(featureName)
			return featureName == 'aura_tracking' or featureName == 'blessing_management'
		end

		return module
	end,

	---Create Warlock module
	---@return table module
	CreateWarlockModule = function()
		local module = CopyTable(ClassRegistry.ClassModuleInterface)

		module.name = 'Warlock Soul Module'
		module.supportedClasses = { 'WARLOCK' }
		module.version = '1.0.0'
		module.description = 'Soul shard and demon management for Warlocks'

		module.spellCategories = {
			destruction = { 'Shadow Bolt', 'Immolate', 'Conflagrate', 'Soul Fire' },
			affliction = { 'Curse of Agony', 'Corruption', 'Drain Life', 'Fear' },
			demonology = { 'Summon Imp', 'Summon Voidwalker', 'Summon Succubus', 'Summon Felhunter' },
			utility = { 'Create Soulstone', 'Create Healthstone', 'Banish', 'Detect Invisibility' },
		}

		function module:GetAvailableSpells()
			local spells = {}
			for category, spellList in pairs(self.spellCategories) do
				for _, spellName in pairs(spellList) do
					local spellId = select(7, GetSpellInfo(spellName))
					if spellId and C_SpellBook.IsSpellInSpellBook(spellId) then table.insert(spells, { id = spellId, name = spellName, category = category }) end
				end
			end
			return spells
		end

		function module:GetSpellCategories()
			return { 'destruction', 'affliction', 'demonology', 'utility' }
		end

		function module:SupportsFeature(featureName)
			return featureName == 'soul_shard_tracking' or featureName == 'demon_management'
		end

		return module
	end,
}

---Universal Spell Detection System
local SpellDetector = {
	detectionMethods = {
		'combat_log', -- Parse combat log events
		'aura_tracking', -- Monitor buff/debuff auras
		'cooldown_api', -- Use GetSpellCooldown API
		'spell_history', -- Track UNIT_SPELLCAST events
		'inventory_scan', -- Scan bag items (potions, etc.)
		'custom_trigger', -- User-defined detection
	},

	registeredSpells = {},
	activeDetectors = {},

	---Register spell for detection
	---@param spellDefinition table
	RegisterSpell = function(spellDefinition)
		SpellDetector.registeredSpells[spellDefinition.id] = spellDefinition
	end,

	---Update spell data
	---@param spellId number
	---@param data table
	UpdateSpellData = function(spellId, data)
		if SpellDetector.registeredSpells[spellId] then
			for key, value in pairs(data) do
				SpellDetector.registeredSpells[spellId][key] = value
			end
		end
	end,

	---Validate spell exists
	---@param spellId number
	---@return boolean exists
	ValidateSpellExists = function(spellId)
		return GetSpellInfo(spellId) ~= nil
	end,

	---Process combat log event
	---@param timestamp number
	---@param event string
	---@param args table
	ProcessCombatLogEvent = function(timestamp, event, args)
		-- Process combat log events for spell detection
		-- This would be expanded based on specific needs
	end,

	---Process aura change
	---@param unit string
	---@param aura table
	ProcessAuraChange = function(unit, aura)
		-- Track aura changes for spell effect detection
	end,

	---Process spell cast
	---@param unit string
	---@param spellId number
	ProcessSpellCast = function(unit, spellId)
		-- Track spell casts for timing and cooldown detection
	end,
}

TotemBar.ClassRegistry = ClassRegistry
TotemBar.SpellDetector = SpellDetector
