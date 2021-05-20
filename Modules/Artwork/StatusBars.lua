local SUI, L, print = SUI, SUI.L, SUI.print
local module = SUI:NewModule('Artwork_StatusBars')
module.bars = {}
local FACTION_BAR_COLORS = {
	[1] = {r = 1, g = 0.2, b = 0},
	[2] = {r = 0.8, g = 0.3, b = 0},
	[3] = {r = 0.8, g = 0.2, b = 0},
	[4] = {r = 1, g = 0.8, b = 0},
	[5] = {r = 0, g = 1, b = 0.1},
	[6] = {r = 0, g = 1, b = 0.2},
	[7] = {r = 0, g = 1, b = 0.3},
	[8] = {r = 0, g = 0.6, b = 0.1}
}
local COLORS = {
	Orange = {r = 1, g = 0.2, b = 0, a = .7},
	Yellow = {r = 1, g = 0.8, b = 0, a = .7},
	Green = {r = 0, g = 1, b = .1, a = .7},
	Blue = {r = 0, g = .1, b = 1, a = .7},
	Red = {r = 1, g = 0, b = .08, a = .7},
	Light_Blue = {r = 0, g = .5, b = 1, a = .7}
}

function module:OnEnable()
	--[[
        Example Settings
        Optional/Defaults are indicated with '--*'

    settings = {
        bars = {
            'Fel_StatusBar_Left'
        },
        Fel_StatusBar_Left = {
            bgImg = 'Interface//addons//myimage',
            texCords = {0,1,0,1}, --*
            size = {256, 36}, --*
            MaxWidth = 60, --If not defined Max width will be self:GetWidth() This is subtracted from the status bar width and is the size of the actual status bar.
            FontSize = 10, --*
            Grow = 'LEFT', --*
            GlowAnchor = 'RIGHT', --*
            GlowHeight = 20, --*

            bgTooltip = 'Interface\\Addons\\SpartanUI\\Classic\\Images\\status-tooltip', --*
            TooltipSize = {380, 100}, --*
            tooltipAnchor = 'top', --*
        }
    }
    ]]
	module.DB = SUI.DB.StatusBars
	--Create Status Bars
	if (SUI.IsClassic or SUI.IsBCC) and module.DB[2].display == 'honor' then
		module.DB[2].display = 'rep'
	end

	module:factory()
	module:BuildOptions()
end

local GetFactionDetails = function(name)
	if (not name) then
		return
	end
	local description = ' '
	for i = 1, GetNumFactions() do
		if name == GetFactionInfo(i) then
			description = select(2, GetFactionInfo(i))
		end
	end
	return description
end

local SetBarColor = function(self, side)
	local display = module.DB[side].display
	local color1 = module.DB[side].CustomColor
	local color2 = module.DB[side].CustomColor2
	local r, g, b, a

	if module.DB[side].AutoColor then
		if display == 'xp' then
			color1 = COLORS.Blue
			color2 = COLORS.Light_Blue
		elseif display == 'az' then
			color1 = COLORS.Orange
		elseif display == 'honor' then
			color1 = COLORS.Red
		elseif display == 'rep' then
			color1 = FACTION_BAR_COLORS[select(2, GetWatchedFactionInfo())] or FACTION_BAR_COLORS[7]
		end
	end
	r, g, b, a = color1.r, color1.g, color1.b, color1.a

	self.Fill:SetVertexColor(r, g, b, a)
	self.FillGlow:SetVertexColor(r, g, b, a)
	if display == 'xp' then
		r, g, b, a = color2.r, color2.g, color2.b, color2.a
		self.Lead:SetVertexColor(r, g, b, a)
		self.LeadGlow:SetVertexColor(r, g, b, (a + .1))
	end
end

local updateText = function(self)
	if GetRealmName() == 'arctium.io' then
		return
	end
	-- local FrameName = self:GetName()
	-- Reset graphics to avoid issues
	self.Fill:SetWidth(0.1)
	self.Lead:SetWidth(0.1)
	--Reset Text
	self.Text:SetText('')

	local side = self.i
	local valFill, valMax, valPercent
	local remaining = ''
	if (module.DB[side].display == 'xp') and GetMaxPlayerLevel('player') ~= UnitLevel('player') then
		local rested, now, goal = GetXPExhaustion() or 0, UnitXP('player'), UnitXPMax('player')
		if now ~= 0 then
			rested = (rested / goal) * self:GetWidth()

			if
				(rested + (now / goal) * (self:GetWidth() - (self.settings.MaxWidth - math.abs(self.settings.GlowPoint.x)))) >
					(self:GetWidth() - (self.settings.MaxWidth - math.abs(self.settings.GlowPoint.x)))
			 then
				rested =
					(self:GetWidth() - (self.settings.MaxWidth - math.abs(self.settings.GlowPoint.x))) -
					(now / goal) * (self:GetWidth() - (self.settings.MaxWidth - math.abs(self.settings.GlowPoint.x)))
			end

			if rested == 0 then
				rested = .001
			end
			self.Lead:SetWidth(rested)
		end
		valFill = now
		valMax = goal
		remaining = SUI:comma_value(goal - now)
		valPercent = (UnitXP('player') / UnitXPMax('player') * 100)
	elseif (module.DB[side].display == 'rep') then
		local _, name, _, low, high, current = 0, GetWatchedFactionInfo()
		local repLevelLow = (current - low)
		local repLevelHigh = (high - low)

		if repLevelHigh == 0 and name then
			valFill = 42000
			valMax = 42000
			valPercent = 100
		elseif name then
			valFill = repLevelLow
			valMax = repLevelHigh
			valPercent = (repLevelLow / repLevelHigh) * 100
		end
	elseif (module.DB[side].display == 'az') then
		if C_AzeriteItem.HasActiveAzeriteItem() then
			local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
			if (not azeriteItemLocation) then
				return
			end
			local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
			valMax = totalLevelXP - xp
			local ratio = (xp / totalLevelXP)
			valFill = xp
			valPercent = ratio * 100
		end
	elseif (module.DB[side].display == 'honor') then
		valFill = UnitHonor('player')
		valMax = UnitHonorMax('player')
		valPercent = ((valFill / valMax) * 100)
	end

	if type(valPercent) == 'number' then
		if valPercent ~= 0 and valPercent then
			local ratio = (valPercent / 100)
			if (ratio * self:GetWidth()) > self:GetWidth() then
				self.Fill:SetWidth(self:GetWidth())
			else
				self.Fill:SetWidth(ratio * (self:GetWidth() - (self.settings.MaxWidth - math.abs(self.settings.GlowPoint.x))))
			end
		end
		if module.DB[side].text and valFill and valMax then
			self.Text:SetFormattedText(
				'( %s / %s ) %d%% %s',
				SUI:comma_value(valFill),
				SUI:comma_value(valMax),
				valPercent,
				remaining or ''
			)
		end
	end

	SetBarColor(self, side)
end

local showXPTooltip = function(self)
	local xptip1 = string.gsub(EXHAUST_TOOLTIP1, '\n', ' ') -- %s %d%% of normal experience gained from monsters.
	local XP_LEVEL_TEMPLATE = '( %s / %s ) %d%% ' .. COMBAT_XP_GAIN -- use Global Strings and regex to make the level string work in any locale
	local xprest = TUTORIAL_TITLE26 .. ' (%d%%) -' -- Rested (%d%%) -
	local a = format('Level %s ', UnitLevel('player'))
	local b =
		format(
		XP_LEVEL_TEMPLATE,
		SUI:comma_value(UnitXP('player')),
		SUI:comma_value(UnitXPMax('player')),
		(UnitXP('player') / UnitXPMax('player') * 100)
	)
	self.tooltip.TextFrame.HeaderText:SetText(a .. b) -- Level 99 (9999 / 9999) 100% Experience
	local rested, text = GetXPExhaustion() or 0
	if (rested > 0) then
		text = format(xptip1, format(xprest, (rested / UnitXPMax('player')) * 100), 200)
		self.tooltip.TextFrame.MainText:SetText(text) -- Rested (15%) - 200% of normal experience gained from monsters.
	else
		self.tooltip.TextFrame.MainText:SetText(format(xptip1, EXHAUST_TOOLTIP2, 100)) -- You should rest at an Inn. 100% of normal experience gained from monsters.
	end
	self.tooltip:Show()
end

local showRepTooltip = function(self)
	local name, react, low, high, current = GetWatchedFactionInfo()
	local repLevelLow = (current - low)
	local repLevelHigh = (high - low)
	local percentage

	if name then
		local text = GetFactionDetails(name)
		if repLevelHigh == 0 then
			percentage = 100
		else
			percentage = (repLevelLow / repLevelHigh) * 100
		end
		self.tooltip.TextFrame.HeaderText:SetText(
			format(
				'%s ( %s / %s ) %d%% %s',
				name,
				SUI:comma_value(repLevelLow),
				SUI:comma_value(repLevelHigh),
				percentage,
				_G['FACTION_STANDING_LABEL' .. react]
			)
		)
		self.tooltip.TextFrame.MainText:SetText('|cffffd200' .. text .. '|r')
		self.tooltip:Show()
	else
		self.tooltip.TextFrame.HeaderText:SetText(REPUTATION)
		self.tooltip.TextFrame.MainText:SetText(REPUTATION_STANDING_DESCRIPTION)
	end
end

local showHonorTooltip = function(self)
	local honorLevel = UnitHonorLevel('player')
	local currentHonor = UnitHonor('player')
	local maxHonor = UnitHonorMax('player')

	self.tooltip.TextFrame.HeaderText:SetFormattedText(HONOR_LEVEL_LABEL, honorLevel)
	self.tooltip.TextFrame.MainText:SetFormattedText(
		'( %s / %s ) %d%%',
		SUI:comma_value(currentHonor),
		SUI:comma_value(maxHonor),
		((currentHonor / maxHonor) * 100)
	)

	self.tooltip:Show()
end

local showAzeriteTooltip = function(self)
	if C_AzeriteItem.HasActiveAzeriteItem() then
		local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
		if (not azeriteItemLocation) then
			return
		end
		local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation)
		local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
		local currentLevel = C_AzeriteItem.GetPowerLevel(azeriteItemLocation)
		local xpToNextLevel = totalLevelXP - xp
		local ratio = (xp / totalLevelXP)
		if currentLevel and xpToNextLevel then
			self.tooltip.TextFrame.HeaderText:SetText(
				AZERITE_POWER_TOOLTIP_TITLE:format(currentLevel, xpToNextLevel),
				HIGHLIGHT_FONT_COLOR:GetRGB()
			)
			if azeriteItem:GetItemName() then
				self.tooltip.TextFrame.MainText:SetText(AZERITE_POWER_TOOLTIP_BODY:format(azeriteItem:GetItemName()))
			end
		end
	end
	self.tooltip:Show()
end

function module:factory()
	for i, key in ipairs({'Left', 'Right'}) do
		local StyleSetting = SUI.DB.Styles[SUI.DB.Artwork.Style].StatusBars[key]

		--Status Bar
		local statusbar = CreateFrame('Frame', 'SUI_StatusBar_' .. key, _G['SUI_Art_' .. SUI.DB.Artwork.Style])
		statusbar:SetSize(unpack(StyleSetting.size))
		statusbar:SetFrameStrata('BACKGROUND')

		--Status Bar Images
		statusbar.bg = statusbar:CreateTexture(nil, 'BACKGROUND')
		statusbar.bg:SetTexture(StyleSetting.bgImg or '')
		statusbar.bg:SetAllPoints(statusbar)
		statusbar.bg:SetTexCoord(unpack(StyleSetting.texCords))

		statusbar.overlay = statusbar:CreateTexture(nil, 'OVERLAY')
		statusbar.overlay:SetTexture(StyleSetting.bgImg)
		statusbar.overlay:SetAllPoints(statusbar.bg)
		statusbar.overlay:SetTexCoord(unpack(StyleSetting.texCords))

		statusbar.Fill = statusbar:CreateTexture(nil, 'BORDER')
		statusbar.Fill:SetTexture(StyleSetting.GlowImage)
		statusbar.Fill:SetSize(.1, StyleSetting.GlowHeight)

		statusbar.Lead = statusbar:CreateTexture(nil, 'BORDER')
		statusbar.Lead:SetTexture(StyleSetting.GlowImage)
		statusbar.Lead:SetSize(.1, StyleSetting.GlowHeight)

		statusbar.FillGlow = statusbar:CreateTexture(nil, 'ARTWORK')
		statusbar.FillGlow:SetTexture(StyleSetting.GlowImage)
		statusbar.FillGlow:SetAllPoints(statusbar.Fill)

		statusbar.LeadGlow = statusbar:CreateTexture(nil, 'ARTWORK')
		statusbar.LeadGlow:SetTexture(StyleSetting.GlowImage)
		statusbar.LeadGlow:SetAllPoints(statusbar.Lead)

		if StyleSetting.Grow == 'LEFT' then
			statusbar.Fill:SetPoint('RIGHT', statusbar, 'RIGHT', StyleSetting.GlowPoint.x, StyleSetting.GlowPoint.y)
			statusbar.Lead:SetPoint('RIGHT', statusbar.Fill, 'LEFT', 0, 0)
		else
			statusbar.Fill:SetPoint('LEFT', statusbar, 'LEFT', StyleSetting.GlowPoint.x, StyleSetting.GlowPoint.y)
			statusbar.Lead:SetPoint('LEFT', statusbar.Fill, 'RIGHT', 0, 0)
		end

		--Status Bar Text
		statusbar.Text = statusbar:CreateFontString(nil, 'OVERLAY')
		--Only allow Style to override default font sizes
		local tmp = module.DB.default.FontSize
		if StyleSetting.FontSize and module.DB[i].FontSize == module.DB.default.FontSize then
			tmp = StyleSetting.FontSize
		end
		SUI:FormatFont(statusbar.Text, tmp)
		statusbar.Text:SetJustifyH('CENTER')
		statusbar.Text:SetJustifyV('MIDDLE')
		statusbar.Text:SetAllPoints(statusbar)
		statusbar.Text:SetTextColor(unpack(StyleSetting.TextColor))

		--Tooltip
		local tooltip = CreateFrame('Frame')
		tooltip:SetParent(statusbar)
		tooltip:SetFrameStrata('TOOLTIP')
		tooltip:SetSize(unpack(StyleSetting.TooltipSize))
		if StyleSetting.tooltipAnchor == 'TOP' then
			tooltip:SetPoint('BOTTOM', statusbar, 'TOP')
		else
			tooltip:SetPoint('TOP', statusbar, 'BOTTOM')
		end

		tooltip.bg = tooltip:CreateTexture(nil, 'BORDER')
		tooltip.bg:SetTexture(StyleSetting.bgTooltip)
		tooltip.bg:SetAllPoints(tooltip)
		tooltip.bg:SetTexCoord(unpack(StyleSetting.texCordsTooltip))

		local TextFrame = CreateFrame('Frame')
		TextFrame:SetFrameStrata('TOOLTIP')
		TextFrame:SetParent(tooltip)
		TextFrame:SetSize(unpack(StyleSetting.TooltipTextSize))
		TextFrame:SetPoint('CENTER', tooltip, 'CENTER')

		TextFrame.HeaderText = TextFrame:CreateFontString(nil, 'OVERLAY')
		SUI:FormatFont(TextFrame.HeaderText, 10)
		TextFrame.HeaderText:SetPoint('TOPLEFT', TextFrame)
		TextFrame.HeaderText:SetPoint('TOPRIGHT', TextFrame)
		TextFrame.HeaderText:SetHeight((0.18 * TextFrame:GetHeight()))

		TextFrame.MainText = TextFrame:CreateFontString(nil, 'OVERLAY')
		SUI:FormatFont(TextFrame.MainText, 8)
		TextFrame.MainText:SetPoint('TOPLEFT', TextFrame.HeaderText, 'BOTTOMLEFT', 0, -2)
		TextFrame.MainText:SetPoint('TOPRIGHT', TextFrame.HeaderText, 'BOTTOMRIGHT', 0, -2)
		TextFrame.MainText:SetHeight((0.82 * TextFrame:GetHeight()))

		TextFrame.MainText2 = TextFrame:CreateFontString(nil, 'OVERLAY')
		SUI:FormatFont(TextFrame.MainText2, 8)
		TextFrame.MainText2:SetPoint('TOPLEFT', TextFrame.MainText, 'BOTTOMLEFT', 0, -2)
		TextFrame.MainText2:SetPoint('TOPRIGHT', TextFrame.MainText, 'BOTTOMRIGHT', 0, -2)
		TextFrame.MainText2:SetHeight((0.82 * TextFrame:GetHeight()))

		TextFrame.HeaderText:SetJustifyH('LEFT')
		TextFrame.MainText:SetJustifyH('LEFT')
		TextFrame.MainText:SetJustifyV('TOP')

		--Assign to globals
		tooltip.TextFrame = TextFrame
		statusbar.tooltip = tooltip
		statusbar.settings = StyleSetting
		statusbar.i = i
		module.bars[key] = statusbar

		--Position
		local point, anchor, secondaryPoint, x, y = strsplit(',', StyleSetting.Position)
		statusbar:ClearAllPoints()
		statusbar:SetPoint(point, anchor, secondaryPoint, x, y)

		--Setup Actions
		statusbar:RegisterEvent('PLAYER_ENTERING_WORLD')
		statusbar:RegisterEvent('UNIT_INVENTORY_CHANGED')
		statusbar:RegisterEvent('PLAYER_ENTERING_WORLD')
		statusbar:RegisterEvent('PLAYER_XP_UPDATE')
		statusbar:RegisterEvent('PLAYER_LEVEL_UP')
		statusbar:RegisterEvent('PLAYER_ENTERING_WORLD')
		statusbar:RegisterEvent('UPDATE_FACTION')

		if SUI.IsRetail then
			statusbar:RegisterEvent('ARTIFACT_XP_UPDATE')
		end

		--Statusbar Update event
		statusbar:SetScript(
			'OnEvent',
			function(self)
				if module.DB[i].display ~= 'disabled' then
					self:Show()
					updateText(self)
				else
					self:Hide()
				end
			end
		)
		--Tooltip Display Events
		statusbar:SetScript(
			'OnEnter',
			function(self)
				if GetRealmName() == 'arctium.io' then
					return
				end
				if module.DB[i].display == 'rep' and module.DB[i].ToolTip == 'hover' then
					showRepTooltip(self, i)
				end
				if module.DB[i].display == 'xp' and module.DB[i].ToolTip == 'hover' then
					showXPTooltip(self, i)
				end
				if module.DB[i].display == 'az' and module.DB[i].ToolTip == 'hover' then
					showAzeriteTooltip(self, i)
				end
				if module.DB[i].display == 'honor' and module.DB[i].ToolTip == 'hover' then
					showHonorTooltip(self, i)
				end
			end
		)
		statusbar:SetScript(
			'OnMouseDown',
			function(self)
				if GetRealmName() == 'arctium.io' then
					return
				end
				if module.DB[i].display == 'rep' and module.DB[i].ToolTip == 'click' then
					showRepTooltip(self, i)
				end
				if module.DB[i].display == 'xp' and module.DB[i].ToolTip == 'click' then
					showXPTooltip(self, i)
				end
				if module.DB[i].display == 'az' and module.DB[i].ToolTip == 'click' then
					showAzeriteTooltip(self, i)
				end
				if module.DB[i].display == 'honor' and module.DB[i].ToolTip == 'click' then
					showHonorTooltip(self, i)
				end
			end
		)
		statusbar:SetScript(
			'OnLeave',
			function(self)
				self.tooltip:Hide()
			end
		)

		-- Hide with SpartanUI
		SpartanUI:HookScript(
			'OnHide',
			function()
				statusbar:Hide()
			end
		)
		SpartanUI:HookScript(
			'OnShow',
			function()
				statusbar:Show()
			end
		)

		--Hook the visibility of the tooltip to the text
		tooltip:HookScript(
			'OnHide',
			function(self)
				tooltip.TextFrame:Hide()
			end
		)
		tooltip:HookScript(
			'OnShow',
			function(self)
				tooltip.TextFrame:Show()
			end
		)
		--Hide the new tooltip
		tooltip:Hide()
	end

	SUI:RegisterMessage(
		'StatusBarUpdate',
		function()
			for i, key in ipairs({'Left', 'Right'}) do
				if module.DB[i].display ~= 'disabled' then
					module.bars[key]:Show()
					updateText(module.bars[key])
				else
					module.bars[key]:Hide()
				end
			end
		end
	)
end

function module:BuildOptions()
	local StatusBars = {
		['xp'] = L['Experiance'],
		['rep'] = L['Reputation'],
		['honor'] = L['Honor'],
		['az'] = L['Azerite Bar'],
		['disabled'] = L['Disabled']
	}
	if (SUI.IsClassic or SUI.IsBCC) then
		StatusBars = {
			['xp'] = L['Experiance'],
			['rep'] = L['Reputation'],
			['disabled'] = L['Disabled']
		}
	end

	local ids = {
		[1] = 'one',
		[2] = 'two',
		[3] = 'three',
		[4] = 'four',
		[5] = 'five'
	}

	-- Build Holder
	SUI.opt.args['Artwork'].args['StatusBars'] = {
		name = L['Status bars'],
		type = 'group',
		args = {}
	}

	--Bar Display dropdowns
	for i, _ in ipairs({'Left', 'Right'}) do
		SUI.opt.args['Artwork'].args['StatusBars'].args[ids[i]] = {
			name = L['Status bar'] .. ' ' .. i,
			order = i,
			type = 'group',
			inline = true,
			args = {
				display = {
					name = L['Display mode'],
					type = 'select',
					order = 1,
					values = StatusBars,
					get = function(info)
						return module.DB[i].display
					end,
					set = function(info, val)
						module.DB[i].display = val
						SUI:SendMessage('StatusBarUpdate')
					end
				},
				text = {
					name = L['Display statusbar text'],
					type = 'toggle',
					order = 2,
					get = function(info)
						return module.DB[i].text
					end,
					set = function(info, val)
						module.DB[i].text = val
						SUI:SendMessage('StatusBarUpdate')
					end
				},
				TooltipDisplay = {
					name = L['Tooltip display mode'],
					type = 'select',
					order = 3,
					values = {
						['hover'] = L['On mouse over'],
						['click'] = L['On click'],
						['off'] = L['Disabled']
					},
					get = function(info)
						return module.DB[i].ToolTip
					end,
					set = function(info, val)
						module.DB[i].ToolTip = val
						SUI:SendMessage('StatusBarUpdate')
					end
				},
				CustomColor1 = {
					name = L['Primary custom color'],
					type = 'color',
					hasAlpha = true,
					order = 4,
					get = function(info)
						local colors = module.DB[i].CustomColor
						return colors.r, colors.g, colors.b, colors.a
					end,
					set = function(info, r, g, b, a)
						local colors = module.DB[i].CustomColor
						colors.r, colors.g, colors.b, colors.a = r, g, b, a
						SUI:SendMessage('StatusBarUpdate')
					end
				},
				CustomColor2 = {
					name = L['Secondary custom color'],
					type = 'color',
					hasAlpha = true,
					order = 4,
					get = function(info)
						local colors = module.DB[i].CustomColor2
						return colors.r, colors.g, colors.b, colors.a
					end,
					set = function(info, r, g, b, a)
						local colors = module.DB[i].CustomColor2
						colors.r, colors.g, colors.b, colors.a = r, g, b, a
						SUI:SendMessage('StatusBarUpdate')
					end
				},
				AutoColor = {
					name = L['Auto color'],
					type = 'toggle',
					order = 5,
					get = function(info)
						return module.DB[i].AutoColor
					end,
					set = function(info, val)
						module.DB[i].AutoColor = val
						SUI:SendMessage('StatusBarUpdate')
					end
				}
			}
		}
	end
end
