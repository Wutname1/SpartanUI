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
		[Enums.Bars.Azerite] = 0,
		[Enums.Bars.Reputation] = 1,
		[Enums.Bars.Honor] = 2,
		[Enums.Bars.Artifact] = 3,
		[Enums.Bars.Experience] = 4,
	},
	bars = {
		['**'] = {
			ToolTip = 'hover',
			text = Enums.TextDisplayMode.OnMouseOver,
			alpha = 1,
		},
	},
}

function module:OnInitialize()
	module.Database = SUI.SpartanUIDB:RegisterNamespace('StatusBars', { profile = DBDefaults })
	DB = module.Database.profile
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
	local StyleSetting = SUI.DB.Styles[SUI.DB.Artwork.Style].StatusBars[key]
	local barContainer = CreateFrame('Frame', 'SUI_StatusBar_' .. key, barManager, 'StatusTrackingBarContainerTemplate')

	barContainer:SetSize(unpack(StyleSetting.size))
	barContainer:SetFrameStrata('LOW')
	barContainer:SetFrameLevel(20)

	self:SetupBarContainerVisuals(barContainer, StyleSetting)
	self:SetupBarContainerPosition(barContainer, StyleSetting, index)

	return barContainer
end

function module:SetupBarContainerVisuals(barContainer, StyleSetting)
	barContainer.BarFrameTexture:Hide()

	-- Create background
	barContainer.bg = barContainer:CreateTexture(nil, 'BACKGROUND')
	barContainer.bg:SetTexture(StyleSetting.bgImg or '')
	barContainer.bg:SetAllPoints(barContainer)
	barContainer.bg:SetTexCoord(unpack(StyleSetting.texCords))

	-- Create overlay
	barContainer.overlay = barContainer:CreateTexture(nil, 'OVERLAY')
	barContainer.overlay:SetTexture(StyleSetting.bgImg)
	barContainer.overlay:SetAllPoints(barContainer.bg)
	barContainer.overlay:SetTexCoord(unpack(StyleSetting.texCords))

	barContainer.settings = StyleSetting
end

function module:SetupBarContainerPosition(barContainer, StyleSetting, index)
	local point, anchor, secondaryPoint, x, y = strsplit(',', StyleSetting.Position)
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

	local containerKey = index == 1 and 'Left' or 'Right'
	bar:HookScript('OnEnter', function()
		if DB.bars[containerKey].text == Enums.TextDisplayMode.OnMouseOver then bar.OverlayFrame.Text:Show() end
	end)
	bar:HookScript('OnLeave', function()
		if DB.bars[containerKey].text == Enums.TextDisplayMode.OnMouseOver then bar.OverlayFrame.Text:Hide() end
	end)
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
