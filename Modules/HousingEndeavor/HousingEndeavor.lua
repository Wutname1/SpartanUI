---@class SUI
local SUI = SUI
local L = SUI.L

---@class SUI.Module.HousingEndeavor : SUI.Module
local module = SUI:NewModule('HousingEndeavor')
module.description = 'Tracks Housing Endeavor progress (neighborhood contribution XP toward seasonal milestones)'

-- Only available in Retail
if not SUI.IsRetail then
	return
end

----------------------------------------------------------------------------------------------------
-- Module Data
----------------------------------------------------------------------------------------------------

---@class SUI.HousingEndeavor.TaskXPEntry
---@field name string Task name
---@field amount number XP amount
---@field completionTime number Time of completion

---@class SUI.HousingEndeavor.ProgressData
---@field currentXP number Current endeavor XP
---@field xpNeeded number XP needed for next milestone
---@field currentMilestone number Current milestone number (1-4)
---@field targetThreshold number XP threshold for current milestone
---@field milestones number[] Array of milestone thresholds
---@field percentage number Progress percentage toward current milestone
---@field title string Initiative title

-- Task XP cache
module.taskXPCache = {} ---@type table<number, SUI.HousingEndeavor.TaskXPEntry>
module.taskXPCacheTime = 0 ---@type number

-- Default milestone thresholds (fallback if API doesn't provide them)
local DEFAULT_MILESTONES = { 250, 500, 750, 1000 }

-- Text format options
module.TEXT_FORMATS = {
	detailed = 'detailed',
	simple = 'simple',
	percentage = 'percentage',
	short = 'short',
	minimal = 'minimal',
	nextfinal = 'nextfinal',
	progress = 'progress',
}

----------------------------------------------------------------------------------------------------
-- API Wrappers
----------------------------------------------------------------------------------------------------

---Check if the housing initiative system is available
---@return boolean
function module:IsInitiativeAvailable()
	if not C_NeighborhoodInitiative then
		return false
	end
	if not C_NeighborhoodInitiative.IsInitiativeEnabled then
		return false
	end

	local ok, result = pcall(C_NeighborhoodInitiative.IsInitiativeEnabled)
	return ok and result
end

---Get the current neighborhood initiative info
---@return table|nil initiativeInfo
function module:GetInitiativeInfo()
	if not C_NeighborhoodInitiative or not C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo then
		return nil
	end

	local ok, info = pcall(C_NeighborhoodInitiative.GetNeighborhoodInitiativeInfo)
	if ok and info then
		return info
	end
	return nil
end

---Request fresh initiative info from the server
function module:RequestInitiativeInfo()
	if C_NeighborhoodInitiative and C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo then
		pcall(C_NeighborhoodInitiative.RequestNeighborhoodInitiativeInfo)
	end
end

---Get the activity log info (contains task completion XP data)
---@return table|nil logInfo
function module:GetActivityLogInfo()
	if not C_NeighborhoodInitiative or not C_NeighborhoodInitiative.GetInitiativeActivityLogInfo then
		return nil
	end

	local ok, info = pcall(C_NeighborhoodInitiative.GetInitiativeActivityLogInfo)
	if ok and info then
		return info
	end
	return nil
end

---Request fresh activity log from the server
function module:RequestActivityLog()
	if C_NeighborhoodInitiative and C_NeighborhoodInitiative.RequestInitiativeActivityLog then
		pcall(C_NeighborhoodInitiative.RequestInitiativeActivityLog)
	end
end

----------------------------------------------------------------------------------------------------
-- Milestone & Progress Calculations
----------------------------------------------------------------------------------------------------

---Get milestone thresholds from API or return defaults
---@param initiativeInfo? table
---@return number[] milestones
function module:GetMilestoneThresholds(initiativeInfo)
	local info = initiativeInfo or self:GetInitiativeInfo()
	if not info then
		return DEFAULT_MILESTONES
	end

	-- Try to read milestones from API data
	if info.milestones and type(info.milestones) == 'table' then
		local thresholds = {}
		for i, milestone in ipairs(info.milestones) do
			-- Try different possible field names
			local threshold = milestone.requiredContributionAmount or milestone.progressRequired or milestone.threshold or milestone.amount
			if threshold then
				thresholds[i] = threshold
			end
		end
		if #thresholds > 0 then
			return thresholds
		end
	end

	return DEFAULT_MILESTONES
end

---Dump raw API data for debugging
---@return table|nil
function module:GetRawAPIData()
	local info = self:GetInitiativeInfo()
	return info
end

---Get current progress data
---@return SUI.HousingEndeavor.ProgressData|nil
function module:GetCurrentProgress()
	local info = self:GetInitiativeInfo()
	if not info then
		return nil
	end

	-- API uses currentProgress for neighborhood total XP
	local currentXP = info.currentProgress or 0

	-- Get milestones from API
	local milestones = self:GetMilestoneThresholds(info)
	local title = info.title or info.name or L['Housing Endeavor']

	-- Find current milestone and XP needed
	local xpNeeded = 0
	local currentMilestone = 1
	local targetThreshold = milestones[1]

	for i, threshold in ipairs(milestones) do
		if currentXP < threshold then
			xpNeeded = threshold - currentXP
			currentMilestone = i
			targetThreshold = threshold
			break
		elseif i == #milestones then
			-- All milestones completed
			currentMilestone = #milestones
			targetThreshold = milestones[#milestones]
			xpNeeded = 0
		end
	end

	-- Calculate percentage toward current milestone
	local percentage = 0
	if currentMilestone > 0 and targetThreshold > 0 then
		local previousThreshold = currentMilestone > 1 and milestones[currentMilestone - 1] or 0
		local xpFromPrevious = currentXP - previousThreshold
		local xpBetweenMilestones = targetThreshold - previousThreshold
		if xpBetweenMilestones > 0 then
			percentage = math.floor((xpFromPrevious / xpBetweenMilestones) * 1000) / 10
		end
	end

	---@type SUI.HousingEndeavor.ProgressData
	return {
		currentXP = currentXP,
		xpNeeded = xpNeeded,
		currentMilestone = currentMilestone,
		targetThreshold = targetThreshold,
		milestones = milestones,
		percentage = percentage,
		title = title,
	}
end

---Get XP needed to reach final milestone
---@return number
function module:GetXPToFinal()
	local progress = self:GetCurrentProgress()
	if not progress then
		return 0
	end

	local finalThreshold = progress.milestones[#progress.milestones] or 1000
	return math.max(0, finalThreshold - progress.currentXP)
end

----------------------------------------------------------------------------------------------------
-- Task XP Cache Management
----------------------------------------------------------------------------------------------------

-- Minimum time between cache rebuilds (seconds)
local CACHE_REBUILD_COOLDOWN = 10
local cacheRebuildPending = false

---Build the task XP cache from activity log (with cooldown to prevent spam)
function module:BuildTaskXPCache()
	-- Check cooldown to prevent excessive rebuilds
	local now = GetTime()
	if self.taskXPCacheTime > 0 and (now - self.taskXPCacheTime) < CACHE_REBUILD_COOLDOWN then
		-- Too soon, skip this rebuild
		return
	end

	-- Prevent multiple pending rebuilds
	if cacheRebuildPending then
		return
	end
	cacheRebuildPending = true

	self:RequestActivityLog()

	-- Delay reading the cache to allow for async data
	C_Timer.After(0.5, function()
		cacheRebuildPending = false

		local logInfo = self:GetActivityLogInfo()
		if not logInfo or not logInfo.taskActivity then
			return
		end

		local cache = {}

		for _, entry in ipairs(logInfo.taskActivity) do
			local taskID = entry.taskID or entry.id
			if taskID then
				local existingEntry = cache[taskID]
				local completionTime = entry.completionTime or entry.time or 0

				-- Keep the most recent completion
				if not existingEntry or (existingEntry.completionTime and completionTime > existingEntry.completionTime) then
					cache[taskID] = {
						name = entry.taskName or entry.name or L['Unknown Task'],
						amount = entry.xpAmount or entry.amount or entry.contribution or 0,
						completionTime = completionTime,
					}
				end
			end
		end

		self.taskXPCache = cache
		self.taskXPCacheTime = GetTime()

		-- Fire callback for UI updates
		self:SendMessage('SUI_HOUSING_ENDEAVOR_CACHE_UPDATED')
	end)
end

---Get XP for a specific task (from API data or cache)
---@param taskID number
---@return SUI.HousingEndeavor.TaskXPEntry|nil
function module:GetTaskXP(taskID)
	-- First check cache
	if self.taskXPCache[taskID] then
		return self.taskXPCache[taskID]
	end

	-- Try to get from current API data
	local info = self:GetInitiativeInfo()
	if info and info.tasks then
		for _, task in ipairs(info.tasks) do
			if task.ID == taskID then
				return {
					name = task.taskName or L['Unknown Task'],
					amount = task.progressContributionAmount or 0,
					completionTime = 0,
				}
			end
		end
	end

	return nil
end

---Clear the task XP cache
function module:ClearCache()
	self.taskXPCache = {}
	self.taskXPCacheTime = 0
end

----------------------------------------------------------------------------------------------------
-- Text Formatting
----------------------------------------------------------------------------------------------------

---Format progress text based on user preference
---@param format string Format type from TEXT_FORMATS
---@param progress? SUI.HousingEndeavor.ProgressData
---@return string
function module:FormatProgressText(format, progress)
	progress = progress or self:GetCurrentProgress()
	if not progress then
		return L['No data available']
	end

	local currentXP = progress.currentXP
	local xpNeeded = progress.xpNeeded
	local milestone = progress.currentMilestone
	local threshold = progress.targetThreshold
	local percentage = progress.percentage
	local finalXP = self:GetXPToFinal()

	-- All milestones completed
	if xpNeeded == 0 then
		return L['All milestones completed!']
	end

	if format == self.TEXT_FORMATS.detailed then
		-- "Milestone 2: 125.0 / 250.0 (125.0 XP needed)"
		return string.format(L['Milestone %d: %.1f / %.1f (%.1f XP needed)'], milestone, currentXP, threshold, xpNeeded)
	elseif format == self.TEXT_FORMATS.simple then
		-- "125.0 XP to Milestone 2"
		return string.format(L['%.1f XP to Milestone %d'], xpNeeded, milestone)
	elseif format == self.TEXT_FORMATS.percentage then
		-- "50.0% to M2 - 125.0 XP needed"
		return string.format(L['%.1f%% to M%d - %.1f XP needed'], percentage, milestone, xpNeeded)
	elseif format == self.TEXT_FORMATS.short then
		-- "To M2: 125.0 XP"
		return string.format(L['To M%d: %.1f XP'], milestone, xpNeeded)
	elseif format == self.TEXT_FORMATS.minimal then
		-- "125.0 XP"
		return string.format('%.1f XP', xpNeeded)
	elseif format == self.TEXT_FORMATS.nextfinal then
		-- "Next: 125.0 XP | Final: 875.0 XP"
		return string.format(L['Next: %.1f XP | Final: %.1f XP'], xpNeeded, finalXP)
	elseif format == self.TEXT_FORMATS.progress then
		-- "M2 Progress: 125.0/250.0 (50.0%)"
		return string.format(L['M%d Progress: %.1f/%.1f (%.1f%%)'], milestone, currentXP, threshold, percentage)
	end

	-- Default to simple format
	return string.format(L['%.1f XP to Milestone %d'], xpNeeded, milestone)
end

----------------------------------------------------------------------------------------------------
-- Event Handling
----------------------------------------------------------------------------------------------------

function module:OnEvent_NEIGHBORHOOD_INITIATIVE_UPDATED()
	-- Just send the update message, don't rebuild cache
	self:SendMessage('SUI_HOUSING_ENDEAVOR_UPDATED')
end

function module:OnEvent_INITIATIVE_ACTIVITY_LOG_UPDATED()
	-- Activity log changed, rebuild cache (cooldown protected)
	self:BuildTaskXPCache()
	self:SendMessage('SUI_HOUSING_ENDEAVOR_UPDATED')
end

function module:OnEvent_INITIATIVE_TASK_COMPLETED()
	-- Task completed, request fresh data and rebuild (cooldown protected)
	self:RequestActivityLog()
	self:BuildTaskXPCache()
	self:SendMessage('SUI_HOUSING_ENDEAVOR_UPDATED')
end

function module:OnEvent_PLAYER_ENTERING_WORLD()
	-- Only run once per session
	if self.initialLoadDone then
		return
	end
	self.initialLoadDone = true

	C_Timer.After(2, function()
		if self:IsInitiativeAvailable() then
			self:RequestInitiativeInfo()
			self:BuildTaskXPCache()
		end
	end)
end

----------------------------------------------------------------------------------------------------
-- Module Lifecycle
----------------------------------------------------------------------------------------------------

function module:OnInitialize()
	---@class SUI.HousingEndeavor.Database
	local defaults = {
		profile = {
			enabled = true,
			progressOverlay = {
				enabled = true,
				format = 'detailed',
				color = { r = 1, g = 1, b = 1 }, -- Default white
			},
			taskTooltips = {
				enabled = true,
			},
			dataBroker = {
				enabled = true,
				format = 'short',
			},
		},
	}

	module.Database = SUI.SpartanUIDB:RegisterNamespace('HousingEndeavor', defaults)
	module.DB = module.Database.profile ---@type SUI.HousingEndeavor.Database

	-- Register logger
	if LibAT and LibAT.Logger then
		module.logger = SUI.logger:RegisterCategory('HousingEndeavor')
	end
end

function module:OnEnable()
	if SUI:IsModuleDisabled('HousingEndeavor') then
		return
	end

	if not self:IsInitiativeAvailable() then
		if module.logger then
			module.logger.info('Housing Initiative system not available')
		end
		return
	end

	-- Register events
	self:RegisterEvent('NEIGHBORHOOD_INITIATIVE_UPDATED', 'OnEvent_NEIGHBORHOOD_INITIATIVE_UPDATED')
	self:RegisterEvent('INITIATIVE_ACTIVITY_LOG_UPDATED', 'OnEvent_INITIATIVE_ACTIVITY_LOG_UPDATED')
	self:RegisterEvent('INITIATIVE_TASK_COMPLETED', 'OnEvent_INITIATIVE_TASK_COMPLETED')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnEvent_PLAYER_ENTERING_WORLD')

	-- Initial data request (only once)
	self:RequestInitiativeInfo()
	self:BuildTaskXPCache()

	-- Build options
	self:BuildOptions()

	-- Initialize sub-systems (defined in other files)
	if self.InitProgressDisplay then
		self:InitProgressDisplay()
	end
	if self.InitTaskTooltips then
		self:InitTaskTooltips()
	end
	if self.InitDataBroker then
		self:InitDataBroker()
	end

	if module.logger then
		module.logger.info('Housing Endeavor module enabled')
	end
end

function module:OnDisable()
	self:UnregisterAllEvents()

	if module.logger then
		module.logger.info('Housing Endeavor module disabled')
	end
end

----------------------------------------------------------------------------------------------------
-- Expose module
----------------------------------------------------------------------------------------------------

SUI.HousingEndeavor = module
