local SUI, L = SUI, SUI.L
---@class SUI.Module.Artwork.StatusBars : SUI.Module
local module = SUI:NewModule('Artwork.StatusBars')
module.bars = {}
local DB ---@type SUI.StatusBars.DB

local Enums = {
	Bars = {
		None = -1,
		Reputation = 1,
		Honor = 2,
		Artifact = 3,
		Experience = 4,
		Azerite = 5,
	},
	TextDisplayMode = {
		OnMouseOver = 0,
		Always = 1,
		Never = 2,
	},
}

local BarLabels = {
	[Enums.Bars.Azerite] = 'Azerite',
	[Enums.Bars.Reputation] = 'Reputation',
	[Enums.Bars.Honor] = 'Honor',
	[Enums.Bars.Artifact] = 'Artifact',
	[Enums.Bars.Experience] = 'Experience',
}

---@class SUI.StatusBars.DB
local DBDefaults = {
	AllowRep = true,
	PriorityDirection = 'ltr',
	BarPriorities = {
		[Enums.Bars.Experience] = 0,
		[Enums.Bars.Reputation] = 1,
		[Enums.Bars.Honor] = 3,
		[Enums.Bars.Azerite] = 4,
		[Enums.Bars.Artifact] = 5,
	},
	bars = {
		['**'] = {
			ToolTip = 'hover',
			text = Enums.TextDisplayMode.OnMouseOver,
			alpha = 1,
		},
	},
}

---@class SUI.Style.Settings.StatusBars.Storage
---@field Left SUI.Style.Settings.StatusBars
---@field Right SUI.Style.Settings.StatusBars

---@class SUI.Style.Settings.StatusBars
---@field bgTexture? string
local StyleSettingsBase = {
	size = { 400, 15 },
	alpha = 1,
	MaxWidth = 0,
	texCords = { 0, 1, 0, 1 },
	tooltip = {
		texture = 'Interface\\Addons\\SpartanUI\\Images\\status-tooltip',
		textureCoords = { 0.103515625, 0.8984375, 0.1796875, 0.8203125 },
		size = { 300, 100 },
		textAreaSize = { 200, 60 },
		statusBarAnchor = 'TOP',
	},
	Position = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOM,-100,0',
}

local StyleSetting = {
	base = {
		Left = {
			Position = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOM,-100,0',
		},
		Right = {
			Position = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOM,100,0',
		},
	},
	skinsettings = {},
}
---Copy Base into left and right
for k, v in pairs(StyleSetting.base) do
	StyleSetting[k] = SUI:CopyData(v, StyleSettingsBase)
end

---@param ContainerKey string
---@return SUI.Style.Settings.StatusBars
local function GetStyleSettings(ContainerKey)
	if StyleSetting.skinsettings[SUI.DB.Artwork.Style] then
		return SUI:CopyData(StyleSetting.skinsettings[SUI.DB.Artwork.Style][ContainerKey], StyleSetting[ContainerKey])
	else
		return StyleSetting[ContainerKey]
	end
end

---@param style string
---@param settings SUI.Style.Settings.StatusBars.Storage
function module:RegisterStyle(style, settings)
	StyleSetting.skinsettings[style] = settings
end

function module:GetExperienceTooltipText()
	local currentXP = UnitXP('player')
	local maxXP = UnitXPMax('player')
	local restedXP = GetXPExhaustion() or 0
	local level = UnitLevel('player')
	local questLogXP = GetQuestLogRewardXP()

	GameTooltip:AddDoubleLine(L['Experience'], string.format('(Level %d)', level))
	GameTooltip:AddDoubleLine(L['Remaining:'], string.format('%s (%.2f%%)', SUI.Font:FormatNumber(maxXP - currentXP), ((maxXP - currentXP) / maxXP) * 100), 1, 1, 1)

	if currentXP then
		GameTooltip:AddLine(' ')
		GameTooltip:AddDoubleLine(L['XP'], string.format('%s / %s (%.2f%%)', SUI.Font:FormatNumber(currentXP), SUI.Font:FormatNumber(maxXP), (currentXP / maxXP) * 100), 1, 1, 1)
	end
	if questLogXP > 0 then GameTooltip:AddDoubleLine(L['Quest Log XP:'], string.format('Quest Log XP: %s (%.2f%%)', SUI.Font:FormatNumber(questLogXP), (questLogXP / maxXP) * 100), 1, 1, 1) end
	if restedXP > 0 then GameTooltip:AddDoubleLine(L['Rested:'], string.format('Rested: +%s (%.2f%%)', SUI.Font:FormatNumber(restedXP), (restedXP / maxXP) * 100), 1, 1, 1) end
end

function module:OnInitialize()
	module.Database = SUI.SpartanUIDB:RegisterNamespace('StatusBars', { profile = DBDefaults })
	DB = module.Database.profile

	-- Migrate old settings
	if SUI.DB.StatusBars then
		-- Check if old bar was set to honor
		for i = 1, 2 do
			if SUI.DB.StatusBars and SUI.DB.StatusBars[i] and SUI.DB.StatusBars[i].display == 'honor' then SetCVar('showHonorAsExperience', 1) end
		end
		-- Remove old settings
		SUI.DB.StatusBars = nil
	end
end

function module:OnEnable()
	module:factory()
	module:BuildOptions()
end

function module:factory()
	local barManager = self:CreateBarManager()
	self:CreateBarContainers(barManager)
	barManager:OnLoad()
end

function module:UpdateBars()
	local barManager = _G['SUI_StatusBar_Manager']
	if barManager then
		-- Update the shown bars
		barManager:UpdateBarsShown()

		-- Update text visibility for both containers
		self:UpdateBarTextVisibility('Left')
		self:UpdateBarTextVisibility('Right')

		-- Update container alphas
		for _, key in ipairs({ 'Left', 'Right' }) do
			local barContainer = module.bars[key]
			if barContainer then barContainer:SetAlpha(DB.bars[key].alpha or 1) end
		end

		-- Refresh the options display
		self:RefreshBarPriorityOptions()
	end
end

function module:UpdateBarTextVisibility(containerKey)
	local barContainer = module.bars[containerKey]
	if not barContainer then return end

	local textMode = DB.bars[containerKey].text

	for _, bar in pairs(barContainer.bars) do
		if textMode == Enums.TextDisplayMode.Always then
			bar.OverlayFrame.Text:Show()
		else -- OnMouseOver
			bar.OverlayFrame.Text:Hide()
		end

		-- Update the bar's UpdateTextVisibility function
		bar.UpdateTextVisibility = function(self)
			local blizzMode = self:ShouldBarTextBeDisplayed()
			self.OverlayFrame.Text:SetShown(textMode == Enums.TextDisplayMode.Always and blizzMode)
		end
	end
end

function module:RefreshBarPriorityOptions()
	local options = SUI.opt.args['Artwork'].args['StatusBars'].args.BarPriorities.args
	for barIndex, priority in pairs(DB.BarPriorities) do
		local optionKey = BarLabels[barIndex]
		if options[optionKey] then options[optionKey].order = priority end
	end
end

function module:CreateBarManager()
	local barManager = CreateFrame('Frame', 'SUI_StatusBar_Manager', SpartanUI)
	for k, v in pairs(StatusTrackingManagerMixin) do
		barManager[k] = v
	end

	barManager.UpdateBarsShown = function(self)
		local function onFinishedAnimating(barContainer)
			barContainer:UnsubscribeFromOnFinishedAnimating(self)
			self:UpdateBarsShown()
		end

		-- If any bar is animating then wait for that animation to end before updating shown bars
		for i, barContainer in ipairs(self.barContainers) do
			if barContainer:IsAnimating() then
				barContainer:SubscribeToOnFinishedAnimating(self, onFinishedAnimating)
				return
			end
		end

		-- Determine what bars should be shown
		local newBarIndicesToShow = {}
		for _, barIndex in pairs(Enums.Bars) do
			if (barIndex == Enums.Bars.Reputation and DB.AllowRep and self:CanShowBar(barIndex)) or (barIndex ~= Enums.Bars.Reputation and self:CanShowBar(barIndex)) then
				table.insert(newBarIndicesToShow, barIndex)
			end
		end

		-- Sort based on priority
		table.sort(newBarIndicesToShow, function(left, right)
			return self:GetBarPriority(left) < self:GetBarPriority(right)
		end)

		-- We can only show as many bars as we have containers for
		while #newBarIndicesToShow > #self.barContainers do
			table.remove(newBarIndicesToShow)
		end

		-- Assign the bar indices to the bar containers
		for i = 1, #self.barContainers do
			local barContainer = self.barContainers[i]
			local newBarIndex

			if #newBarIndicesToShow == 1 then
				-- Special case for single bar
				if DB.PriorityDirection == 'ltr' then
					newBarIndex = (i == 1) and newBarIndicesToShow[1] or Enums.Bars.None
				else
					newBarIndex = (i == #self.barContainers) and newBarIndicesToShow[1] or Enums.Bars.None
				end
			else
				if DB.PriorityDirection == 'ltr' then
					newBarIndex = newBarIndicesToShow[i] or Enums.Bars.None
				else
					newBarIndex = newBarIndicesToShow[#newBarIndicesToShow - i + 1] or Enums.Bars.None
				end
			end

			barContainer:SetShownBar(newBarIndex)
		end

		self.shownBarIndices = newBarIndicesToShow
	end

	barManager:SetScript('OnLoad', barManager.OnLoad)
	barManager:SetScript('OnEvent', barManager.OnEvent)

	barManager.GetBarPriority = function(self, barIndex)
		if not DB.BarPriorities then return 0 end -- Sometimes we get called before Initilize has been called. This is a safe guard.

		return DB.BarPriorities[barIndex] or 0
	end

	return barManager
end

function module:CreateBarContainers(barManager)
	for i, key in ipairs({ 'Left', 'Right' }) do
		local barContainer = self:CreateBarContainer(barManager, key, i)
		self:SetupBarContainerBehavior(barContainer, i)
		module.bars[key] = barContainer
	end
end

function module:CreateBarContainer(barManager, key, index)
	local barStyle = GetStyleSettings(key)
	local barContainer = CreateFrame('Frame', 'SUI_StatusBar_' .. key, barManager, 'StatusTrackingBarContainerTemplate')
	barContainer.barStyle = barStyle

	barContainer:SetSize(unpack(barStyle.size))
	barContainer:SetFrameStrata('LOW')
	barContainer:SetFrameLevel(20)

	-- Hide with SpartanUI
	SpartanUI:HookScript('OnHide', function()
		barContainer:Hide()
	end)
	SpartanUI:HookScript('OnShow', function()
		barContainer:Show()
	end)

	self:SetupBarContainerVisuals(barContainer, barStyle)
	self:SetupBarContainerPosition(barContainer, barStyle, index)

	return barContainer
end

function module:SetupBarContainerVisuals(barContainer, barStyle)
	barContainer.BarFrameTexture:Hide()
	-- Create background
	barContainer.bg = barContainer:CreateTexture(nil, 'BACKGROUND')
	barContainer.bg:SetTexture(barStyle.bgTexture or '')
	barContainer.bg:SetAllPoints(barContainer)
	barContainer.bg:SetTexCoord(unpack(barStyle.texCords))
	if barStyle.bgTexture then
		barContainer.bg:Show()
	else
		barContainer.bg:Hide()
	end

	-- Create overlay
	barContainer.overlay = barContainer:CreateTexture(nil, 'OVERLAY')
	barContainer.overlay:SetTexture(barStyle.bgTexture or '')
	barContainer.overlay:SetAllPoints(barContainer.bg)
	barContainer.overlay:SetTexCoord(unpack(barStyle.texCords))
	if barStyle.bgTexture then
		barContainer.overlay:Show()
	else
		barContainer.overlay:Hide()
	end

	barContainer.settings = barStyle
end

function module:SetupBarContainerPosition(barContainer, barStyle, index)
	local point, anchor, secondaryPoint, x, y = strsplit(',', barStyle.Position)
	barContainer:ClearAllPoints()
	barContainer:SetPoint(point, anchor, secondaryPoint, x, y)
	local containerKey = index == 1 and 'Left' or 'Right'
	barContainer:SetAlpha(DB.bars[containerKey].alpha or 1)
end

function module:SetupBarContainerBehavior(barContainer, index)
	local width, height = unpack(barContainer.settings.size)
	for _, bar in pairs(barContainer.bars) do
		self:SetupBar(bar, barContainer, width, height, index)
	end

	SpartanUI:HookScript('OnHide', function()
		barContainer:Hide()
	end)
	SpartanUI:HookScript('OnShow', function()
		barContainer:Show()
	end)
end

function module:SetupBar(bar, barContainer, width, height, index)
	bar:SetSize(width - 30, height - 5)
	bar.StatusBar:SetSize(width - 30, height - 5)
	bar:ClearAllPoints()
	bar:SetPoint('BOTTOM', barContainer, 'BOTTOM', 0, 0)
	bar:SetUsingParentLevel(false)
	bar:SetFrameLevel(barContainer:GetFrameLevel() - 5)

	self:SetupBarText(bar, barContainer.settings, index)

	bar:HookScript('OnEnter', function(self)
		local containerKey = index == 1 and 'Left' or 'Right'
		if DB.bars[containerKey].text == Enums.TextDisplayMode.OnMouseOver then bar.OverlayFrame.Text:Show() end

		-- Show custom tooltip
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
		if self.barIndex == Enums.Bars.Experience then module:GetExperienceTooltipText() end
		GameTooltip:Show()
	end)

	bar:HookScript('OnLeave', function(self)
		local containerKey = index == 1 and 'Left' or 'Right'
		if DB.bars[containerKey].text == Enums.TextDisplayMode.OnMouseOver then bar.OverlayFrame.Text:Hide() end

		-- Hide tooltip
		GameTooltip:Hide()
	end)
end

function module:SetActiveStyle(style)
	-- Update the style for each container (Left and Right)
	for _, key in ipairs({ 'Left', 'Right' }) do
		local barContainer = module.bars[key]
		if barContainer then
			local newStyle = GetStyleSettings(key)

			-- Update size
			barContainer:SetSize(unpack(newStyle.size))

			-- Update background
			if newStyle.bgTexture then
				barContainer.bg:SetTexture(newStyle.bgTexture)
				barContainer.bg:Show()
				if newStyle.texCords then
					barContainer.bg:SetTexCoord(unpack(newStyle.texCords))
				else
					barContainer.bg:SetTexCoord(0, 1, 0, 1)
				end
			else
				barContainer.bg:SetTexture('')
				barContainer.bg:Hide()
			end

			-- Update overlay
			if newStyle.bgTexture then
				barContainer.overlay:SetTexture(newStyle.bgTexture)
				barContainer.overlay:Show()
				if newStyle.texCords then
					barContainer.overlay:SetTexCoord(unpack(newStyle.texCords))
				else
					barContainer.overlay:SetTexCoord(0, 1, 0, 1)
				end
			else
				barContainer.overlay:SetTexture('')
				barContainer.overlay:Hide()
			end

			-- Update position
			local point, anchor, secondaryPoint, x, y = strsplit(',', newStyle.Position)
			barContainer:ClearAllPoints()
			barContainer:SetPoint(point, anchor, secondaryPoint, x, y)

			-- Update individual bars
			for _, bar in pairs(barContainer.bars) do
				bar:SetSize(newStyle.size[1] - 30, newStyle.size[2] - 5)
				bar.StatusBar:SetSize(newStyle.size[1] - 30, newStyle.size[2] - 5)

				-- Update text if needed
				self:SetupBarText(bar, newStyle, key == 'Left' and 1 or 2)
			end

			-- Store the new style settings
			barContainer.settings = newStyle
		end
	end

	-- Refresh the bars
	self:UpdateBars()
end

function module:SetupBarText(bar, StyleSetting, index)
	local containerKey = index == 1 and 'Left' or 'Right'
	local textMode = DB.bars[containerKey].text
	SUI.Font:Format(bar.OverlayFrame.Text, StyleSetting.Font or 10, 'StatusBars')
	bar.OverlayFrame.Text:SetShown(textMode == Enums.TextDisplayMode.Always)

	-- Update the bar's UpdateTextVisibility function
	bar.UpdateTextVisibility = function(self)
		local blizzMode = self:ShouldBarTextBeDisplayed()
		self.OverlayFrame.Text:SetShown(textMode == Enums.TextDisplayMode.Always and blizzMode)
	end
end

function module:BuildOptions()
	SUI.opt.args['Artwork'].args['StatusBars'] = {
		name = L['Status bars'],
		type = 'group',
		args = {
			IsWatchingHonorAsXP = {
				name = 'Enable Honor bar',
				type = 'toggle',
				order = 2,
				get = function()
					return GetCVarBool('showHonorAsExperience')
				end,
				set = function(_, value)
					SetCVar('showHonorAsExperience', value)
				end,
			},
			EnableReputation = {
				name = 'Enable Reputation',
				type = 'toggle',
				order = 3,
				get = function()
					return DB.AllowRep
				end,
				set = function(_, value)
					DB.AllowRep = value
					self:UpdateBars()
				end,
			},
			PriorityDirection = {
				name = 'Priority Direction',
				type = 'select',
				order = 4,
				values = {
					['ltr'] = 'Left to Right',
					['rtl'] = 'Right to Left',
				},
				get = function()
					return DB.PriorityDirection
				end,
				set = function(_, value)
					DB.PriorityDirection = value
					self:UpdateBars()
				end,
			},
			BarPriorities = self:CreateBarPrioritiesOptions(),
			Font = self:CreateFontOptions(),
			Left = self:CreateContainerOptions('Left', 110),
			Right = self:CreateContainerOptions('Right', 120),
		},
	}
end

function module:CreateContainerOptions(containerKey, order)
	return {
		name = containerKey .. ' Status Bar',
		type = 'group',
		inline = true,
		order = order,
		args = {
			text = {
				name = 'Text Display',
				type = 'select',
				order = 1,
				values = {
					[Enums.TextDisplayMode.OnMouseOver] = 'On Mouse Over',
					[Enums.TextDisplayMode.Always] = 'Always',
					[Enums.TextDisplayMode.Never] = 'Never',
				},
				get = function()
					return DB.bars[containerKey].text
				end,
				set = function(_, value)
					DB.bars[containerKey].text = value
					self:UpdateBars()
				end,
			},
			alpha = {
				name = 'Alpha',
				type = 'range',
				order = 2,
				min = 0,
				max = 1,
				step = 0.01,
				get = function()
					return DB.bars[containerKey].alpha
				end,
				set = function(_, value)
					DB.bars[containerKey].alpha = value
					self:UpdateBars()
				end,
			},
		},
	}
end

function module:CreateFontOptions()
	return {
		name = 'Font Settings',
		type = 'group',
		order = 100,
		inline = true,
		get = function(info)
			return SUI.Font.DB.Modules.StatusBars[info[#info]]
		end,
		set = function(info, val)
			SUI.Font.DB.Modules.StatusBars[info[#info]] = val
			SUI.Font:Refresh('StatusBars')
		end,
		args = {
			Face = {
				type = 'select',
				name = L['Font face'],
				order = 1,
				dialogControl = 'LSM30_Font',
				values = SUI.Lib.LSM:HashTable('font'),
			},
			Type = {
				name = L['Font style'],
				type = 'select',
				order = 2,
				values = {
					['normal'] = L['Normal'],
					['monochrome'] = L['Monochrome'],
					['outline'] = L['Outline'],
					['thickoutline'] = L['Thick outline'],
				},
			},
			Size = {
				name = L['Adjust font size'],
				type = 'range',
				order = 3,
				width = 'double',
				min = -15,
				max = 15,
				step = 1,
			},
		},
	}
end

function module:CreateBarPrioritiesOptions()
	local options = {
		name = 'Bar Priorities',
		type = 'group',
		order = 50,
		inline = true,
		args = {},
	}

	local function isBarAtTop(barIndex)
		return DB.BarPriorities[barIndex] == 0
	end

	local function isBarAtBottom(barIndex)
		local highest = 0
		for _, priority in pairs(DB.BarPriorities) do
			if priority > highest then highest = priority end
		end
		return DB.BarPriorities[barIndex] == highest
	end

	local function moveBar(barIndex, direction)
		local currentPriority = DB.BarPriorities[barIndex]
		local newPriority = currentPriority + (direction == 'up' and -1 or 1)

		for otherBarIndex, priority in pairs(DB.BarPriorities) do
			if priority == newPriority then
				DB.BarPriorities[otherBarIndex] = currentPriority
				DB.BarPriorities[barIndex] = newPriority
				break
			end
		end

		self:UpdateBars()
	end

	for i, v in pairs(DB.BarPriorities) do
		options.args[BarLabels[i]] = {
			name = '',
			type = 'group',
			order = v,
			args = {
				label = {
					type = 'description',
					width = 'double',
					fontSize = 'medium',
					order = 1,
					name = BarLabels[i],
				},
				up = {
					type = 'execute',
					name = 'Up',
					width = 'half',
					order = 2,
					disabled = function()
						return isBarAtTop(i)
					end,
					func = function()
						moveBar(i, 'up')
					end,
				},
				down = {
					type = 'execute',
					name = 'Down',
					width = 'half',
					order = 3,
					disabled = function()
						return isBarAtBottom(i)
					end,
					func = function()
						moveBar(i, 'down')
					end,
				},
			},
		}
	end

	return options
end
