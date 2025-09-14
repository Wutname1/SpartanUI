local SUI, L = SUI, SUI.L
local StatsTracker = SUI:GetModule('StatsTracker') ---@class StatsTracker

local displayFrames = {}
local MoveIt

---@class StatsTracker.DisplayFrame : Frame, BackdropTemplate
---@field stats table
---@field alwaysShownElements table
---@field mouseoverElements table
---@field mouseoverContainer Frame
---@field frameKey string
---@field isMouseOver boolean

---Create a progress bar
---@param parent Frame
---@param width number
---@param height number
---@return Frame progressBar
local function CreateProgressBar(parent, width, height)
	local bar = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
	bar:SetSize(width, height)

	-- Background
	bar:SetBackdrop(
		{
			bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
			edgeFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
			edgeSize = 1
		}
	)
	bar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
	bar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	-- Progress fill
	bar.fill = CreateFrame('Frame', nil, bar, 'BackdropTemplate')
	bar.fill:SetPoint('LEFT')
	bar.fill:SetHeight(height)
	bar.fill:SetBackdrop(
		{
			bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga'
		}
	)
	bar.fill:SetBackdropColor(0, 0.8, 0, 0.8)

	-- Update function
	bar.SetProgress = function(self, progress, color)
		progress = math.max(0, math.min(1, progress or 0))
		self.fill:SetWidth(width * progress)
		if color then
			self.fill:SetBackdropColor(unpack(color))
		end
	end

	return bar
end

---Create a stat element (text + optional progress bar)
---@param parent Frame
---@param statKey string
---@param index number
---@param isMouseover boolean
---@param frameConfig table Frame configuration for per-frame settings
---@return table statElement
local function CreateStatElement(parent, statKey, index, isMouseover, frameConfig)
	local element = {}
	element.statKey = statKey
	element.isMouseover = isMouseover or false

	-- Main container
	element.frame = CreateFrame('Frame', nil, parent)
	local elementWidth = StatsTracker.DB.elementWidth or 150
	element.frame:SetSize(elementWidth, 20)

	-- Text display
	element.text = element.frame:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(element.text, 10, 'StatsTracker')
	element.text:SetPoint('LEFT')
	element.text:SetJustifyH('LEFT')
	element.text:SetTextColor(1, 1, 1, 1)

	-- Progress bar (optional)
	if StatsTracker.DB.showProgressBars then
		local barWidth = math.max(50, elementWidth * 0.3)
		element.progressBar = CreateProgressBar(element.frame, barWidth, StatsTracker.DB.progressBarHeight)
		element.progressBar:SetPoint('RIGHT')
		element.text:SetPoint('LEFT')
		element.text:SetPoint('RIGHT', element.progressBar, 'LEFT', -5, 0)
	else
		element.text:SetPoint('LEFT')
		element.text:SetPoint('RIGHT')
	end

	-- Update function
	element.Update = function(self, stat)
		if not stat then
			self.frame:Hide()
			return
		end

		self.frame:Show()

		-- Use per-frame formatting if available
		local displayText = stat.displayValue or tostring(stat.value)
		if stat.rawDisplayValue and frameConfig then
			displayText = StatsTracker:FormatStatDisplayForFrame(statKey, stat.rawDisplayValue, frameConfig)
		end
		self.text:SetText(displayText)

		if stat.color then
			self.text:SetTextColor(unpack(stat.color))
		end

		if self.progressBar and stat.progress then
			self.progressBar:SetProgress(stat.progress, stat.color)
		end
	end

	-- Initially hide mouseover elements
	if isMouseover then
		element.frame:Hide()
	end

	return element
end

---Position elements based on grow direction
---@param elements table
---@param container Frame
---@param layout string
---@param spacing number
---@param growDirection string
local function PositionElements(elements, container, layout, spacing, growDirection)
	local visibleElements = {}

	-- Get visible elements in order
	for _, element in pairs(elements) do
		if element.frame:IsShown() then
			table.insert(visibleElements, element)
		end
	end

	if #visibleElements == 0 then
		return
	end

	-- Position elements based on layout and grow direction
	for i, element in ipairs(visibleElements) do
		element.frame:ClearAllPoints()

		if layout == 'horizontal' then
			if i == 1 then
				-- First element positioning based on grow direction
				if growDirection == 'left' then
					element.frame:SetPoint('RIGHT', container, 'RIGHT', -2, 0)
				else -- right (default)
					element.frame:SetPoint('LEFT', container, 'LEFT', 2, 0)
				end
			else
				-- Subsequent elements
				local prevElement = visibleElements[i - 1]
				if growDirection == 'left' then
					element.frame:SetPoint('RIGHT', prevElement.frame, 'LEFT', -spacing, 0)
				else -- right
					element.frame:SetPoint('LEFT', prevElement.frame, 'RIGHT', spacing, 0)
				end
			end
		else -- vertical
			if i == 1 then
				-- First element positioning based on grow direction
				if growDirection == 'down' then
					element.frame:SetPoint('TOP', container, 'TOP', 0, -2)
				else -- up (default)
					element.frame:SetPoint('BOTTOM', container, 'BOTTOM', 0, 2)
				end
			else
				-- Subsequent elements
				local prevElement = visibleElements[i - 1]
				if growDirection == 'down' then
					element.frame:SetPoint('TOP', prevElement.frame, 'BOTTOM', 0, -spacing)
				else -- up
					element.frame:SetPoint('BOTTOM', prevElement.frame, 'TOP', 0, spacing)
				end
			end
		end
	end
end

---Create mouseover container
---@param parent Frame
---@param config table
---@return Frame
local function CreateMouseoverContainer(parent, config)
	local container = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
	container:SetSize(200, 100) -- Will be auto-sized

	-- Background (slightly different from main frame)
	if StatsTracker.DB.backgroundColor then
		container:SetBackdrop(
			{
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
				edgeFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
				edgeSize = 1
			}
		)
		local bg = StatsTracker.DB.backgroundColor
		container:SetBackdropColor(bg[1], bg[2], bg[3], (bg[4] or 0.7) * 0.9) -- Slightly more transparent
		local border = StatsTracker.DB.borderColor or {0.3, 0.3, 0.3, 1}
		container:SetBackdropBorderColor(unpack(border))
	end

	-- Position relative to main frame
	local position = config.mouseoverPosition or 'below'
	local spacing = config.mouseoverSpacing or 5

	container:ClearAllPoints()
	if position == 'above' then
		container:SetPoint('BOTTOM', parent, 'TOP', 0, spacing)
	elseif position == 'below' then
		container:SetPoint('TOP', parent, 'BOTTOM', 0, -spacing)
	elseif position == 'left' then
		container:SetPoint('RIGHT', parent, 'LEFT', -spacing, 0)
	elseif position == 'right' then
		container:SetPoint('LEFT', parent, 'RIGHT', spacing, 0)
	end

	container:Hide()
	return container
end

---Update container size based on content
---@param container Frame
---@param elements table
---@param layout string
---@param spacing number
local function UpdateContainerSize(container, elements, layout, spacing)
	local visibleElements = {}
	for _, element in pairs(elements) do
		if element.frame:IsShown() then
			table.insert(visibleElements, element)
		end
	end

	if #visibleElements == 0 then
		container:Hide()
		return
	end

	container:Show()

	local elementWidth = StatsTracker.DB.elementWidth or 150

	if layout == 'horizontal' then
		local totalWidth = (#visibleElements * elementWidth) + ((#visibleElements - 1) * spacing) + 4
		container:SetSize(totalWidth, 20 + 4)
	else -- vertical
		local totalHeight = (#visibleElements * 20) + ((#visibleElements - 1) * spacing) + 4
		container:SetSize(elementWidth + 4, totalHeight)
	end
end

---Create a display frame with mouseover support
---@param frameKey string
---@return StatsTracker.DisplayFrame
function StatsTracker:CreateDisplayFrame(frameKey)
	local config = self.DB.frames[frameKey]
	if not config or not config.enabled then
		return
	end

	---@type StatsTracker.DisplayFrame
	local frame = CreateFrame('Frame', 'SUI_StatsTracker_' .. frameKey, UIParent, 'BackdropTemplate')
	frame.frameKey = frameKey
	frame.alwaysShownElements = {}
	frame.mouseoverElements = {}
	frame.isMouseOver = false

	-- Set initial size
	frame:SetSize(config.width or 200, config.height or 20)

	-- Background
	if StatsTracker.DB.backgroundColor then
		frame:SetBackdrop(
			{
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
				edgeFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
				edgeSize = 1
			}
		)
		frame:SetBackdropColor(unpack(StatsTracker.DB.backgroundColor))
		frame:SetBackdropBorderColor(unpack(StatsTracker.DB.borderColor or {0.3, 0.3, 0.3, 1}))
	end

	-- Parse position
	local point, anchor, secondaryPoint, x, y = strsplit(',', config.position)
	frame:SetPoint(point, _G[anchor] or UIParent, secondaryPoint, tonumber(x) or 0, tonumber(y) or 0)

	-- Set scale
	frame:SetScale(config.scale or 1.0)

	-- Create mouseover container
	frame.mouseoverContainer = CreateMouseoverContainer(frame, config)

	-- Create stat elements (separate always shown and mouseover)
	local statList = config.stats or {}
	local alwaysIndex = 1
	local mouseoverIndex = 1

	for _, statKey in ipairs(statList) do
		if self.DB.enabledStats[statKey] then
			local visibility = config.statVisibility[statKey] or 'always'

			if visibility == 'always' then
				local element = CreateStatElement(frame, statKey, alwaysIndex, false, config)
				frame.alwaysShownElements[statKey] = element
				alwaysIndex = alwaysIndex + 1
			else -- mouseover
				local element = CreateStatElement(frame.mouseoverContainer, statKey, mouseoverIndex, true, config)
				frame.mouseoverElements[statKey] = element
				mouseoverIndex = mouseoverIndex + 1
			end
		end
	end

	-- Position always shown elements
	PositionElements(frame.alwaysShownElements, frame, config.layout, config.spacing, config.growDirection)

	-- Position mouseover elements
	PositionElements(frame.mouseoverElements, frame.mouseoverContainer, config.layout, config.spacing, config.growDirection)

	-- Update function
	frame.Update = function(self)
		local currentStats = StatsTracker.GetCurrentStats()

		-- Update always shown elements
		for statKey, element in pairs(self.alwaysShownElements) do
			local stat = currentStats[statKey]
			element:Update(stat)
		end

		-- Update mouseover elements (even when hidden)
		for statKey, element in pairs(self.mouseoverElements) do
			local stat = currentStats[statKey]
			element:Update(stat)
		end

		-- Update container sizes
		self:UpdateSize()
		UpdateContainerSize(self.mouseoverContainer, self.mouseoverElements, config.layout, config.spacing)

		-- Re-position elements in case visibility changed
		PositionElements(self.alwaysShownElements, self, config.layout, config.spacing, config.growDirection)
		PositionElements(self.mouseoverElements, self.mouseoverContainer, config.layout, config.spacing, config.growDirection)
	end

	-- Size update function
	frame.UpdateSize = function(self)
		local config = StatsTracker.DB.frames[self.frameKey]
		local visibleElements = 0

		for _, element in pairs(self.alwaysShownElements) do
			if element.frame:IsShown() then
				visibleElements = visibleElements + 1
			end
		end

		local elementWidth = StatsTracker.DB.elementWidth or 150

		if config.layout == 'vertical' then
			local height = (visibleElements * 20) + (math.max(0, visibleElements - 1) * (config.spacing or 2)) + 4
			self:SetHeight(math.max(height, 20))
		else
			-- Horizontal layout
			local totalWidth = (visibleElements * elementWidth) + (math.max(0, visibleElements - 1) * (config.spacing or 5)) + 4
			if totalWidth > 0 then
				self:SetWidth(math.max(totalWidth, config.width or elementWidth))
			end
		end
	end

	-- Mouseover handling
	frame:SetScript(
		'OnEnter',
		function(self)
			self.isMouseOver = true
			if next(self.mouseoverElements) then
				self.mouseoverContainer:Show()
				-- Show all mouseover elements that have been updated with data
				for statKey, element in pairs(self.mouseoverElements) do
					local currentStats = StatsTracker.GetCurrentStats()
					if currentStats[statKey] then
						element.frame:Show()
					end
				end
				-- Update positioning
				UpdateContainerSize(self.mouseoverContainer, self.mouseoverElements, config.layout, config.spacing)
				PositionElements(self.mouseoverElements, self.mouseoverContainer, config.layout, config.spacing, config.growDirection)
			end
		end
	)

	frame:SetScript(
		'OnLeave',
		function(self)
			self.isMouseOver = false
			-- Delay hiding to prevent flickering when moving between frame and mouseover container
			C_Timer.After(
				0.1,
				function()
					if not self.isMouseOver and not self.mouseoverContainer.isMouseOver then
						self.mouseoverContainer:Hide()
						for _, element in pairs(self.mouseoverElements) do
							element.frame:Hide()
						end
					end
				end
			)
		end
	)

	-- Mouseover container handling
	frame.mouseoverContainer:SetScript(
		'OnEnter',
		function(self)
			self.isMouseOver = true
		end
	)

	frame.mouseoverContainer:SetScript(
		'OnLeave',
		function(self)
			self.isMouseOver = false
			C_Timer.After(
				0.1,
				function()
					if not frame.isMouseOver and not self.isMouseOver then
						self:Hide()
						for _, element in pairs(frame.mouseoverElements) do
							element.frame:Hide()
						end
					end
				end
			)
		end
	)

	-- Create mover if MoveIt is available
	if MoveIt then
		MoveIt:CreateMover(
			frame,
			'StatsTracker_' .. frameKey,
			'Stats: ' .. frameKey,
			function()
				-- Post-drag callback
				local point, anchor, secondaryPoint, x, y = frame:GetPoint()
				StatsTracker.DB.frames[frameKey].position = string.format('%s,%s,%s,%d,%d', point, anchor:GetName(), secondaryPoint, x, y)
			end,
			'Stats & Tracking'
		)
	end

	return frame
end

---Create all configured display frames
function StatsTracker:CreateDisplayFrames()
	-- Clear existing frames
	for _, frame in pairs(displayFrames) do
		if frame then
			frame:Hide()
			frame:SetParent(nil)
		end
	end
	displayFrames = {}

	-- Create new frames
	for frameKey, config in pairs(self.DB.frames) do
		if config.enabled then
			local frame = self:CreateDisplayFrame(frameKey)
			if frame then
				displayFrames[frameKey] = frame
			end
		end
	end
end

---Update all display frames
function StatsTracker:UpdateDisplayFrames()
	for _, frame in pairs(displayFrames) do
		if frame and frame.Update then
			frame:Update()
		end
	end
end

---Set stat visibility for a frame
---@param frameKey string
---@param statKey string
---@param visibility string 'always' or 'mouseover'
function StatsTracker:SetStatVisibility(frameKey, statKey, visibility)
	local config = self.DB.frames[frameKey]
	if not config then
		return
	end

	if not config.statVisibility then
		config.statVisibility = {}
	end

	config.statVisibility[statKey] = visibility

	-- Recreate the frame to apply changes
	self:CreateDisplayFrames()
end

---Toggle a stat on/off for a specific frame
---@param frameKey string
---@param statKey string
---@param enabled boolean
function StatsTracker:ToggleFrameStat(frameKey, statKey, enabled)
	local config = self.DB.frames[frameKey]
	if not config then
		return
	end

	local statList = config.stats or {}

	if enabled then
		-- Add stat if not present
		local found = false
		for _, stat in ipairs(statList) do
			if stat == statKey then
				found = true
				break
			end
		end
		if not found then
			table.insert(statList, statKey)
		end
	else
		-- Remove stat
		for i = #statList, 1, -1 do
			if statList[i] == statKey then
				table.remove(statList, i)
			end
		end
	end

	config.stats = statList

	-- Recreate the frame
	self:CreateDisplayFrames()
end

---Get available stat types
---@return table statTypes
function StatsTracker:GetAvailableStats()
	local stats = {
		-- Performance
		fps = L['FPS'],
		latency = L['Latency'],
		memory = L['Memory Usage'],
		-- Character
		bags = L['Bag Usage'],
		durability = L['Durability'],
		gold = L['Gold'],
		-- Session
		sessionTime = L['Session Time'],
		totalTime = L['Total Time'],
		-- Gameplay
		xp = L['Experience'],
		xpPerHour = L['XP per Hour'],
		recentXpRate = L['Recent XP Rate'],
		restedXP = L['Rested XP'],
		-- Combat
		kills = L['Kills'],
		deaths = L['Deaths'],
		kdr = L['K/D Ratio']
	}

	-- Add detected currencies
	if _G.DETECTED_CURRENCIES then
		for statKey, currencyData in pairs(_G.DETECTED_CURRENCIES) do
			stats[statKey] = currencyData.name
		end
	end

	return stats
end

-- Initialize display system when this file loads
StatsTracker.InitializeDisplay = function(self)
	MoveIt = SUI:GetModule('MoveIt')

	-- Create default frame if none exist
	if not next(self.DB.frames) then
		self.DB.frames.main = {
			enabled = true,
			position = 'TOP,UIParent,TOP,0,-50',
			width = 600,
			height = 25,
			scale = 1.0,
			stats = {'fps', 'latency', 'bags', 'durability', 'gold', 'sessionTime'},
			layout = 'vertical',
			spacing = 0,
			growDirection = 'down',
			mouseoverPosition = 'below',
			mouseoverSpacing = 0,
			statVisibility = {
				fps = 'always',
				latency = 'always',
				bags = 'always',
				durability = 'always',
				gold = 'always',
				sessionTime = 'always',
				memory = 'mouseover',
				xp = 'mouseover',
				xpPerHour = 'mouseover',
				kills = 'mouseover',
				deaths = 'mouseover'
			}
		}
	end
end
