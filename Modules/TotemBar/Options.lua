local SUI, L = SUI, SUI.L
local TotemBar = SUI:GetModule('TotemBar')

function TotemBar:Options()
	SUI.opt.args.TotemBar = {
		name = L['Totem Bar'],
		type = 'group',
		order = 120,
		disabled = function()
			return SUI:IsModuleDisabled('TotemBar')
		end,
		args = {
			enable = {
				name = L['Enable'],
				type = 'toggle',
				order = 1,
				get = function()
					return TotemBar.DB.enabled
				end,
				set = function(_, val)
					TotemBar.DB.enabled = val
					TotemBar:UpdateBarVisibility()
				end,
			},
			hideWhenEmpty = {
				name = L['Hide when no totems'],
				desc = L['Hide the totem bar when no totems are active'],
				type = 'toggle',
				order = 2,
				get = function()
					return TotemBar.DB.hideWhenEmpty
				end,
				set = function(_, val)
					TotemBar.DB.hideWhenEmpty = val
					TotemBar:UpdateBarVisibility()
				end,
			},
			spacer1 = { type = 'header', order = 10, name = '' },
			
			-- Layout Settings
			layoutGroup = {
				name = L['Layout'],
				type = 'group',
				inline = true,
				order = 20,
				args = {
					orientation = {
						name = L['Orientation'],
						desc = L['Set the bar orientation'],
						type = 'select',
						order = 1,
						values = {
							horizontal = L['Horizontal'],
							vertical = L['Vertical'],
						},
						get = function()
							return TotemBar.DB.layout.orientation
						end,
						set = function(_, val)
							TotemBar.DB.layout.orientation = val
							TotemBar:ApplyLayout()
						end,
					},
					spacing = {
						name = L['Button Spacing'],
						desc = L['Space between totem buttons'],
						type = 'range',
						order = 2,
						min = 0,
						max = 20,
						step = 1,
						get = function()
							return TotemBar.DB.layout.spacing
						end,
						set = function(_, val)
							TotemBar.DB.layout.spacing = val
							TotemBar:ApplyLayout()
						end,
					},
					scale = {
						name = L['Scale'],
						desc = L['Scale of the totem bar'],
						type = 'range',
						order = 3,
						min = 0.5,
						max = 2.0,
						step = 0.1,
						get = function()
							return TotemBar.DB.layout.scale
						end,
						set = function(_, val)
							TotemBar.DB.layout.scale = val
							TotemBar:ApplyLayout()
						end,
					},
				},
			},
			
			spacer2 = { type = 'header', order = 30, name = '' },
			
			-- Appearance Settings
			appearanceGroup = {
				name = L['Appearance'],
				type = 'group',
				inline = true,
				order = 40,
				args = {
					showBackground = {
						name = L['Show Background'],
						desc = L['Show background on totem buttons'],
						type = 'toggle',
						order = 1,
						get = function()
							return TotemBar.DB.appearance.showBackground
						end,
						set = function(_, val)
							TotemBar.DB.appearance.showBackground = val
							TotemBar:UpdateButtonAppearance()
						end,
					},
					backgroundColor = {
						name = L['Background Color'],
						desc = L['Background color for totem buttons'],
						type = 'color',
						hasAlpha = true,
						order = 2,
						disabled = function()
							return not TotemBar.DB.appearance.showBackground
						end,
						get = function()
							local color = TotemBar.DB.appearance.backgroundColor
							return color[1], color[2], color[3], color[4]
						end,
						set = function(_, r, g, b, a)
							TotemBar.DB.appearance.backgroundColor = { r, g, b, a }
							TotemBar:UpdateButtonAppearance()
						end,
					},
					borderColor = {
						name = L['Border Color'],
						desc = L['Border color for totem buttons'],
						type = 'color',
						hasAlpha = true,
						order = 3,
						disabled = function()
							return not TotemBar.DB.appearance.showBackground
						end,
						get = function()
							local color = TotemBar.DB.appearance.borderColor
							return color[1], color[2], color[3], color[4]
						end,
						set = function(_, r, g, b, a)
							TotemBar.DB.appearance.borderColor = { r, g, b, a }
							TotemBar:UpdateButtonAppearance()
						end,
					},
					showCooldownText = {
						name = L['Show Cooldown Text'],
						desc = L['Show remaining time on totem buttons'],
						type = 'toggle',
						order = 4,
						get = function()
							return TotemBar.DB.appearance.showCooldownText
						end,
						set = function(_, val)
							TotemBar.DB.appearance.showCooldownText = val
							TotemBar:UpdateButtonAppearance()
						end,
					},
				},
			},
			
			spacer3 = { type = 'header', order = 50, name = '' },
			
			-- Behavior Settings
			behaviorGroup = {
				name = L['Behavior'],
				type = 'group',
				inline = true,
				order = 60,
				args = {
					clickToDestroy = {
						name = L['Right-click to Destroy'],
						desc = L['Right-click totem buttons to destroy totems'],
						type = 'toggle',
						order = 1,
						get = function()
							return TotemBar.DB.behavior.clickToDestroy
						end,
						set = function(_, val)
							TotemBar.DB.behavior.clickToDestroy = val
							TotemBar:UpdateButtonBehavior()
						end,
					},
					showTooltips = {
						name = L['Show Tooltips'],
						desc = L['Show tooltips when hovering over totem buttons'],
						type = 'toggle',
						order = 2,
						get = function()
							return TotemBar.DB.behavior.showTooltips
						end,
						set = function(_, val)
							TotemBar.DB.behavior.showTooltips = val
							TotemBar:UpdateButtonBehavior()
						end,
					},
				},
			},
			
			spacer4 = { type = 'header', order = 70, name = '' },
			
			-- Action Buttons
			actionsGroup = {
				name = L['Actions'],
				type = 'group',
				inline = true,
				order = 80,
				args = {
					testMode = {
						name = L['Test Mode'],
						desc = L['Toggle test mode to preview the bar with dummy totems'],
						type = 'execute',
						order = 1,
						func = function()
							TotemBar:ToggleTestMode()
						end,
					},
					refreshTotems = {
						name = L['Refresh Totems'],
						desc = L['Manually refresh all totem information'],
						type = 'execute',
						order = 2,
						func = function()
							TotemBar:UpdateAllTotems()
						end,
					},
				},
			},
		},
	}
end

-- Add methods to update UI based on settings
function TotemBar:UpdateButtonAppearance()
	if not self.DB then return end
	
	-- Get buttons from main module
	local buttons = self.GetTotemButtons and self:GetTotemButtons() or {}
	
	for i = 1, 4 do
		local button = buttons[i]
		if button then
			if self.DB.appearance.showBackground then
				button:SetBackdropColor(unpack(self.DB.appearance.backgroundColor))
				button:SetBackdropBorderColor(unpack(self.DB.appearance.borderColor))
			else
				button:SetBackdropColor(0, 0, 0, 0)
				button:SetBackdropBorderColor(0, 0, 0, 0)
			end
			
			if self.DB.appearance.showCooldownText then
				button.countText:Show()
			else
				button.countText:Hide()
			end
		end
	end
end

function TotemBar:UpdateButtonBehavior()
	if not self.DB then return end
	
	-- Get buttons from main module
	local buttons = self.GetTotemButtons and self:GetTotemButtons() or {}
	
	for i = 1, 4 do
		local button = buttons[i]
		if button then
			if self.DB.behavior.clickToDestroy then
				button:SetAttribute('type', 'destroytotem')
				button:SetAttribute('totem-slot', i)
			else
				button:SetAttribute('type', nil)
				button:SetAttribute('totem-slot', nil)
			end
			
			-- Update tooltip behavior
			if self.DB.behavior.showTooltips then
				button:EnableMouse(true)
			else
				button:EnableMouse(self.DB.behavior.clickToDestroy)
			end
		end
	end
end

-- Test mode functionality
local testModeActive = false
local testTimers = {}

function TotemBar:ToggleTestMode()
	if testModeActive then
		self:DisableTestMode()
	else
		self:EnableTestMode()
	end
end

function TotemBar:EnableTestMode()
	testModeActive = true
	
	-- Get buttons from main module
	local buttons = self:GetTotemButtons()
	
	-- Mock totem data for testing
	local testTotems = {
		{ name = 'Searing Totem', icon = 'Interface\\Icons\\Spell_Fire_SearingTotem', duration = 60 },
		{ name = 'Healing Stream Totem', icon = 'Interface\\Icons\\INV_Spear_04', duration = 120 },
		{ name = 'Windfury Totem', icon = 'Interface\\Icons\\Spell_Nature_Windfury', duration = 300 },
		{ name = 'Earthbind Totem', icon = 'Interface\\Icons\\Spell_Nature_StrengthOfEarth', duration = 45 },
	}
	
	for i = 1, 4 do
		local button = buttons[i]
		local testData = testTotems[i]
		
		if button and testData then
			button:Show()
			button.icon:SetTexture(testData.icon)
			button.totemData = {
				name = testData.name,
				slot = i,
				icon = testData.icon,
				startTime = GetTime(),
				duration = testData.duration
			}
			
			-- Start test timer
			local timerId = 'test_' .. i
			testTimers[timerId] = {
				spellId = i,
				duration = testData.duration,
				startTime = GetTime(),
				endTime = GetTime() + testData.duration,
				category = 'Test'
			}
			button.timer = testTimers[timerId]
			
			-- Set up cooldown
			button.cooldownFrame:SetCooldown(GetTime(), testData.duration)
		end
	end
	
	self:UpdateBarVisibility()
	SUI:Print('TotemBar test mode enabled')
end

function TotemBar:DisableTestMode()
	testModeActive = false
	
	-- Get buttons from main module
	local buttons = self:GetTotemButtons()
	
	-- Clear test data
	for i = 1, 4 do
		local button = buttons[i]
		if button then
			button:Hide()
			button.totemData = nil
			button.timer = nil
			button.cooldownFrame:Clear()
			button.icon:SetTexture(nil)
			button.countText:SetText('')
		end
	end
	
	-- Clear test timers
	testTimers = {}
	
	-- Restore real totem data
	self:UpdateAllTotems()
	SUI:Print('TotemBar test mode disabled')
end

-- Initialize options when module loads - this will be called by the main module