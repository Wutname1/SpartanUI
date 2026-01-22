local SUI, L = SUI, SUI.L
local StatsTracker = SUI:GetModule('StatsTracker') ---@class StatsTracker

-- Options management variables
StatsTracker.selectedFrame = 'main'
local buildStatsList

---Build dynamic stats management list for a frame
---@param frameKey string
buildStatsList = function(frameKey)
	if not frameKey or not StatsTracker.DB.frames[frameKey] then
		return
	end

	local frameConfig = StatsTracker.DB.frames[frameKey]
	local frameArgs = SUI.opt.args.StatsTracker.args.frames.args[frameKey].args.statsManagement.args

	-- Clear existing args
	table.wipe(frameArgs)

	-- Add dropdown for adding new stats
	local availableStats = {}
	local allStats = StatsTracker:GetAvailableStats()
	local currentStats = frameConfig.stats or {}

	for statKey, statName in pairs(allStats) do
		if StatsTracker.DB.enabledStats[statKey] then
			local alreadyAdded = false
			for _, existingStat in ipairs(currentStats) do
				if existingStat == statKey then
					alreadyAdded = true
					break
				end
			end
			if not alreadyAdded then
				availableStats[statKey] = statName
			end
		end
	end

	frameArgs.addStat = {
		name = L['Add Statistic'],
		desc = L['Select a statistic to add to this frame'],
		type = 'select',
		order = 1,
		values = availableStats,
		get = function()
			return ''
		end,
		set = function(_, val)
			if val and val ~= '' then
				table.insert(frameConfig.stats, val)
				if not frameConfig.statVisibility then
					frameConfig.statVisibility = {}
				end
				frameConfig.statVisibility[val] = 'always'
				StatsTracker:CreateDisplayFrames()
				buildStatsList(frameKey)
			end
		end,
	}

	-- Add dropdown for adding currencies
	local availableCurrencies = {}

	-- Ensure currencies are discovered before building dropdown
	StatsTracker:DiscoverCurrencies()

	if _G.DETECTED_CURRENCIES then
		for statKey, currencyData in pairs(_G.DETECTED_CURRENCIES) do
			-- Only show currencies not already added to this frame
			local alreadyAdded = false
			for _, existingStat in ipairs(currentStats) do
				if existingStat == statKey then
					alreadyAdded = true
					break
				end
			end
			if not alreadyAdded and currencyData and currencyData.name then
				local displayName = currencyData.name
				-- Add icon if available
				if currencyData.icon then
					displayName = '|T' .. currencyData.icon .. ':16:16:0:0|t ' .. currencyData.name
				end
				availableCurrencies[statKey] = displayName
			end
		end
	end

	-- If no currencies found, try again after a delay (API might not be ready)
	if not next(availableCurrencies) and UnitName('player') then
		C_Timer.After(1, function()
			StatsTracker:DiscoverCurrencies()
			if next(_G.DETECTED_CURRENCIES or {}) then
				-- Rebuild options if currencies were found
				StatsTracker:BuildFrameOptions()
			end
		end)
	end

	-- Only show currency dropdown if there are currencies available
	if next(availableCurrencies) then
		frameArgs.addCurrency = {
			name = L['Add Currency'],
			desc = L['Select a currency to add to this frame'],
			type = 'select',
			order = 3,
			values = availableCurrencies,
			get = function()
				return ''
			end,
			set = function(_, val)
				if val and val ~= '' then
					-- Enable the currency stat globally
					StatsTracker.DB.enabledStats[val] = true
					-- Add to frame
					table.insert(frameConfig.stats, val)
					if not frameConfig.statVisibility then
						frameConfig.statVisibility = {}
					end
					frameConfig.statVisibility[val] = 'always'
					StatsTracker:CreateDisplayFrames()
					buildStatsList(frameKey)
				end
			end,
		}
	end

	frameArgs.spacer1 = { type = 'header', order = 15, name = '' }

	-- List current stats with controls
	local order = 25
	for i, statKey in ipairs(currentStats) do
		if StatsTracker.DB.enabledStats[statKey] then
			local statName = allStats[statKey] or statKey
			local visibility = frameConfig.statVisibility[statKey] or 'always'

			frameArgs['stat_' .. statKey .. '_header'] = {
				name = statName,
				type = 'header',
				order = order,
			}
			order = order + 1

			frameArgs['stat_' .. statKey .. '_visibility'] = {
				name = L['Visibility'],
				desc = L['When to show this statistic'],
				type = 'select',
				order = order,
				width = 'half',
				values = {
					always = L['Always Shown'],
					mouseover = L['Show on Mouseover'],
				},
				get = function()
					return frameConfig.statVisibility[statKey] or 'always'
				end,
				set = function(_, val)
					frameConfig.statVisibility[statKey] = val
					StatsTracker:CreateDisplayFrames()
				end,
			}
			order = order + 1

			-- Add goal input for currencies
			if statKey:match('^currency_') then
				frameArgs['stat_' .. statKey .. '_goal'] = {
					name = L['Goal'],
					desc = L['Target amount for progress tracking (0 = no goal)'],
					type = 'input',
					order = order,
					width = 'half',
					get = function()
						local currentGoal = StatsTracker.DB.currencyGoals[statKey] or 0
						if currentGoal == 0 then
							-- Auto-suggest smart default based on current amount
							local currencyData = _G.DETECTED_CURRENCIES and _G.DETECTED_CURRENCIES[statKey]
							if currencyData and currencyData.quantity then
								local smartGoal = StatsTracker:CalculateSmartGoal(currencyData.quantity)
								return tostring(smartGoal)
							end
						end
						return tostring(currentGoal)
					end,
					set = function(_, val)
						local goal = tonumber(val) or 0
						StatsTracker.DB.currencyGoals[statKey] = goal
						StatsTracker:CreateDisplayFrames()
					end,
				}
				order = order + 1
			end

			frameArgs['stat_' .. statKey .. '_remove'] = {
				name = L['Remove'],
				desc = L['Remove this statistic from the frame'],
				type = 'execute',
				order = order,
				width = 'half',
				func = function()
					-- Remove from stats list
					for j = #frameConfig.stats, 1, -1 do
						if frameConfig.stats[j] == statKey then
							table.remove(frameConfig.stats, j)
						end
					end
					-- Remove from visibility settings
					if frameConfig.statVisibility then
						frameConfig.statVisibility[statKey] = nil
					end
					-- Remove currency goal if it's a currency
					if statKey:match('^currency_') then
						StatsTracker.DB.currencyGoals[statKey] = nil
					end
					StatsTracker:CreateDisplayFrames()
					buildStatsList(frameKey)
				end,
			}
			order = order + 1

			frameArgs['stat_' .. statKey .. '_spacer'] = {
				type = 'description',
				name = '',
				order = order,
			}
			order = order + 1
		end
	end
end

function StatsTracker:Options()
	SUI.opt.args.StatsTracker = {
		name = L['Stats & Tracking'],
		type = 'group',
		order = 130,
		disabled = function()
			return SUI:IsModuleDisabled('StatsTracker')
		end,
		args = {
			enable = {
				name = L['Enable'],
				type = 'toggle',
				order = 1,
				get = function()
					return StatsTracker.DB.enabled
				end,
				set = function(_, val)
					StatsTracker.DB.enabled = val
					if val then
						StatsTracker:OnEnable()
					else
						StatsTracker:OnDisable()
					end
				end,
			},
			spacer1 = { type = 'header', order = 10, name = '' },
			-- General Settings
			generalGroup = {
				name = L['General Settings'],
				type = 'group',
				inline = true,
				order = 20,
				args = {
					updateInterval = {
						name = L['Update Interval'],
						desc = L['How often to update statistics (in seconds)'],
						type = 'range',
						order = 1,
						min = 0.1,
						max = 5.0,
						step = 0.1,
						get = function()
							return StatsTracker.DB.updateInterval
						end,
						set = function(_, val)
							StatsTracker.DB.updateInterval = val
							if StatsTracker:IsEnabled() then
								StatsTracker:OnDisable()
								StatsTracker:OnEnable()
							end
						end,
					},
					adaptiveColors = {
						name = L['Adaptive Colors'],
						desc = L['Automatically color stats based on their values (green=good, yellow=warning, red=bad)'],
						type = 'toggle',
						order = 2,
						get = function()
							return StatsTracker.DB.adaptiveColors
						end,
						set = function(_, val)
							StatsTracker.DB.adaptiveColors = val
						end,
					},
					textColor = {
						name = L['Text Color'],
						desc = L['Default text color when adaptive colors are disabled'],
						type = 'color',
						order = 3,
						disabled = function()
							return StatsTracker.DB.adaptiveColors
						end,
						get = function()
							local color = StatsTracker.DB.textColor
							return color[1], color[2], color[3]
						end,
						set = function(_, r, g, b)
							StatsTracker.DB.textColor = { r, g, b }
						end,
					},
				},
			},
			spacer2 = { type = 'header', order = 30, name = '' },
			-- Frame Management
			frameManagementGroup = {
				name = L['Frame Management'],
				type = 'group',
				inline = true,
				order = 40,
				args = {
					description = {
						name = L['Create and manage multiple display panels to show different sets of statistics in different locations'],
						type = 'description',
						order = 1,
						fontSize = 'medium',
					},
					createFrame = {
						name = L['Create New Frame'],
						desc = L['Enter a name for the new frame'],
						type = 'input',
						order = 2,
						get = function()
							return ''
						end,
						set = function(_, val)
							if val and val ~= '' and not StatsTracker.DB.frames[val] then
								StatsTracker.DB.frames[val] = {
									enabled = true,
									position = 'CENTER,UIParent,CENTER,0,0',
									width = 400,
									height = 25,
									scale = 1.0,
									stats = {},
									layout = 'horizontal',
									spacing = 10,
									growDirection = 'right',
									mouseoverPosition = 'below',
									mouseoverSpacing = 5,
									statVisibility = {},
								}
								StatsTracker:CreateDisplayFrames()
								StatsTracker:BuildFrameOptions()
							end
						end,
					},
					deleteFrame = {
						name = L['Delete Frame'],
						desc = L['Select a frame to delete'],
						type = 'select',
						order = 3,
						values = function()
							local frames = {}
							for frameKey, _ in pairs(StatsTracker.DB.frames) do
								if frameKey ~= 'main' then -- Don't allow deleting main frame
									frames[frameKey] = frameKey
								end
							end
							return frames
						end,
						get = function()
							return ''
						end,
						set = function(_, val)
							if val and val ~= '' and val ~= 'main' and StatsTracker.DB.frames[val] then
								StatsTracker.DB.frames[val] = nil
								StatsTracker:CreateDisplayFrames()
								StatsTracker:BuildFrameOptions()
							end
						end,
					},
				},
			},
			spacer5 = { type = 'header', order = 50, name = '' },
			-- Dynamic Frame Tabs will be added here
			frames = {
				name = L['Display Frames'],
				type = 'group',
				order = 60,
				childGroups = 'tab',
				args = {},
			},
			spacer6 = { type = 'header', order = 70, name = '' },
			-- Actions
			actionsGroup = {
				name = L['Actions'],
				type = 'group',
				inline = true,
				order = 80,
				args = {
					resetSession = {
						name = L['Reset Session Data'],
						desc = L['Reset session statistics (time, XP, kills, deaths, gold)'],
						type = 'execute',
						order = 1,
						func = function()
							StatsTracker:InitializeSession()
						end,
					},
					refreshFrames = {
						name = L['Refresh Display Frames'],
						desc = L['Recreate all display frames with current settings'],
						type = 'execute',
						order = 2,
						func = function()
							StatsTracker:CreateDisplayFrames()
						end,
					},
					moveFrames = {
						name = L['Move Frames'],
						desc = L['Open SpartanUI move system to reposition stat frames'],
						type = 'execute',
						order = 3,
						func = function()
							local MoveIt = SUI:GetModule('MoveIt')
							if MoveIt then
								MoveIt:MoveIt()
							end
						end,
					},
				},
			},
		},
	}

	-- Build frame options
	StatsTracker:BuildFrameOptions()
end

-- Build dynamic frame tabs
function StatsTracker:BuildFrameOptions()
	local frameArgs = SUI.opt.args.StatsTracker.args.frames.args
	table.wipe(frameArgs)

	for frameKey, frameConfig in pairs(self.DB.frames) do
		frameArgs[frameKey] = {
			name = frameKey,
			type = 'group',
			order = frameKey == 'main' and 1 or 100,
			args = {
				enabled = {
					name = L['Enable Frame'],
					type = 'toggle',
					order = 1,
					get = function()
						return frameConfig.enabled
					end,
					set = function(_, val)
						frameConfig.enabled = val
						StatsTracker:CreateDisplayFrames()
					end,
				},
				displayGroup = {
					name = L['Display Settings'],
					type = 'group',
					inline = true,
					order = 5,
					args = {
						showLabels = {
							name = L['Show Labels'],
							desc = L['Show descriptive labels before stat values (e.g., "Bags: 73/152 (48%)")'],
							type = 'toggle',
							order = 1,
							get = function()
								return frameConfig.showLabels ~= nil and frameConfig.showLabels or StatsTracker.DB.showLabels
							end,
							set = function(_, val)
								frameConfig.showLabels = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
						showIcons = {
							name = L['Show Icons'],
							desc = L['Show icons before stat values'],
							type = 'toggle',
							order = 2,
							get = function()
								return frameConfig.showIcons ~= nil and frameConfig.showIcons or StatsTracker.DB.showIcons
							end,
							set = function(_, val)
								frameConfig.showIcons = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
						elementWidth = {
							name = L['Element Width'],
							desc = L['Width of each stat element in pixels'],
							type = 'range',
							order = 3,
							min = 100,
							max = 300,
							step = 10,
							get = function()
								return frameConfig.elementWidth or StatsTracker.DB.elementWidth
							end,
							set = function(_, val)
								frameConfig.elementWidth = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
						showProgressBars = {
							name = L['Show Progress Bars'],
							desc = L['Show visual progress bars for applicable stats'],
							type = 'toggle',
							order = 4,
							get = function()
								return frameConfig.showProgressBars ~= nil and frameConfig.showProgressBars or StatsTracker.DB.showProgressBars
							end,
							set = function(_, val)
								frameConfig.showProgressBars = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
						progressBarHeight = {
							name = L['Progress Bar Height'],
							desc = L['Height of progress bars in pixels'],
							type = 'range',
							order = 5,
							min = 2,
							max = 10,
							step = 1,
							disabled = function()
								local showBars = frameConfig.showProgressBars ~= nil and frameConfig.showProgressBars or StatsTracker.DB.showProgressBars
								return not showBars
							end,
							get = function()
								return frameConfig.progressBarHeight or StatsTracker.DB.progressBarHeight
							end,
							set = function(_, val)
								frameConfig.progressBarHeight = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
					},
				},
				settingsGroup = {
					name = L['Frame Settings'],
					type = 'group',
					inline = true,
					order = 10,
					args = {
						layout = {
							name = L['Layout'],
							type = 'select',
							order = 1,
							values = {
								horizontal = L['Horizontal'],
								vertical = L['Vertical'],
							},
							get = function()
								return frameConfig.layout or 'vertical'
							end,
							set = function(_, val)
								frameConfig.layout = val
								-- Auto-correct grow direction if it conflicts with new layout
								local currentDirection = frameConfig.growDirection
								if val == 'horizontal' and (currentDirection == 'up' or currentDirection == 'down') then
									frameConfig.growDirection = 'right'
								elseif val == 'vertical' and (currentDirection == 'left' or currentDirection == 'right') then
									frameConfig.growDirection = 'down'
								end
								StatsTracker:CreateDisplayFrames()
								-- Rebuild options to refresh the grow direction dropdown
								StatsTracker:BuildFrameOptions()
							end,
						},
						growDirection = {
							name = L['Grow Direction'],
							desc = L['Direction the tracker grows when adding elements'],
							type = 'select',
							order = 2,
							values = function()
								local layout = frameConfig.layout or 'vertical'
								if layout == 'horizontal' then
									return {
										right = L['Right'],
										left = L['Left'],
									}
								else -- vertical
									return {
										up = L['Up'],
										down = L['Down'],
									}
								end
							end,
							get = function()
								local layout = frameConfig.layout or 'vertical'
								local currentDirection = frameConfig.growDirection

								-- Auto-correct conflicting combinations
								if layout == 'horizontal' and (currentDirection == 'up' or currentDirection == 'down') then
									return 'right'
								elseif layout == 'vertical' and (currentDirection == 'left' or currentDirection == 'right') then
									return 'down'
								end

								return currentDirection or (layout == 'vertical' and 'down' or 'right')
							end,
							set = function(_, val)
								frameConfig.growDirection = val
								StatsTracker:CreateDisplayFrames()
								-- Rebuild options to refresh the grow direction dropdown
								StatsTracker:BuildFrameOptions()
							end,
						},
						spacing = {
							name = L['Element Spacing'],
							type = 'range',
							order = 3,
							min = 0,
							max = 20,
							step = 1,
							get = function()
								return frameConfig.spacing or 5
							end,
							set = function(_, val)
								frameConfig.spacing = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
						scale = {
							name = L['Scale'],
							type = 'range',
							order = 4,
							min = 0.5,
							max = 2.0,
							step = 0.1,
							get = function()
								return frameConfig.scale or 1.0
							end,
							set = function(_, val)
								frameConfig.scale = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
					},
				},
				mouseoverGroup = {
					name = L['Mouseover Settings'],
					type = 'group',
					inline = true,
					order = 20,
					args = {
						mouseoverPosition = {
							name = L['Mouseover Position'],
							desc = L['Where to show mouseover stats relative to the main frame'],
							type = 'select',
							order = 1,
							values = {
								above = L['Above'],
								below = L['Below'],
								left = L['Left'],
								right = L['Right'],
							},
							get = function()
								return frameConfig.mouseoverPosition or 'below'
							end,
							set = function(_, val)
								frameConfig.mouseoverPosition = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
						mouseoverSpacing = {
							name = L['Mouseover Spacing'],
							desc = L['Distance between main frame and mouseover stats'],
							type = 'range',
							order = 2,
							min = 0,
							max = 20,
							step = 1,
							get = function()
								return frameConfig.mouseoverSpacing or 5
							end,
							set = function(_, val)
								frameConfig.mouseoverSpacing = val
								StatsTracker:CreateDisplayFrames()
							end,
						},
					},
				},
				statsManagement = {
					name = L['Statistics Management'],
					type = 'group',
					inline = true,
					order = 30,
					args = {},
				},
			},
		}

		-- Build stats list for this frame
		buildStatsList(frameKey)
	end
end
