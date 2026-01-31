---@class SUI
local SUI = SUI
local L = SUI.L

-- Only available in Retail
if not SUI.IsRetail then
	return
end

---@class SUI.Module.HousingEndeavor
local module = SUI.HousingEndeavor

-- Debug: Check if module loaded
if module and module.logger then
	module.logger.debug('TaskTooltips.lua loading, module exists: ' .. tostring(module ~= nil))
end

----------------------------------------------------------------------------------------------------
-- Task Tooltip Enhancement
----------------------------------------------------------------------------------------------------

local tooltipHooked = false

---Build a lookup table of task names to XP amounts from API data
---@return table<string, number>
local function GetTaskNameToXPMap()
	local map = {}
	local info = module:GetInitiativeInfo()
	if info and info.tasks then
		for _, task in ipairs(info.tasks) do
			if task.taskName and task.progressContributionAmount then
				map[task.taskName] = task.progressContributionAmount
			end
		end
	end
	return map
end

---Check if tooltip already has our contribution line
---@param tooltip GameTooltip
---@return boolean
local function HasContributionLine(tooltip)
	local tooltipName = tooltip:GetName()
	if not tooltipName then
		return false
	end

	for i = 1, tooltip:NumLines() do
		local line = _G[tooltipName .. 'TextLeft' .. i]
		if line then
			local text = line:GetText()
			if text and text:find('Endeavor Contribution') then
				return true
			end
		end
	end
	return false
end

---Enhance tooltip with task XP if it contains a task name
---@param tooltip GameTooltip
local function EnhanceTaskTooltip(tooltip)
	if not module or not module.DB or not module.DB.taskTooltips or not module.DB.taskTooltips.enabled then
		return
	end

	if HasContributionLine(tooltip) then
		return
	end

	-- Get task name to XP mapping
	local taskMap = GetTaskNameToXPMap()
	if not next(taskMap) then
		return
	end

	local tooltipName = tooltip:GetName()
	if not tooltipName then
		return
	end

	-- Search tooltip lines for task name matches
	for i = 1, tooltip:NumLines() do
		local line = _G[tooltipName .. 'TextLeft' .. i]
		if line then
			local text = line:GetText()
			if text then
				-- Check against task names
				for taskName, xpAmount in pairs(taskMap) do
					if text == taskName or text:find(taskName, 1, true) then
						tooltip:AddLine(' ')
						tooltip:AddDoubleLine(L['Endeavor Contribution'] .. ':', string.format('%.1f XP', xpAmount), 1, 0.82, 0, 1, 1, 1)
						tooltip:Show()
						return
					end
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Module Integration
----------------------------------------------------------------------------------------------------

---Initialize the task tooltip system
function module:InitTaskTooltips()
	if tooltipHooked then
		if self.logger then
			self.logger.debug('TaskTooltips: Already hooked, skipping')
		end
		return
	end

	if self.logger then
		self.logger.debug('TaskTooltips: InitTaskTooltips called')
	end

	-- Use TooltipDataProcessor if available (modern WoW)
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
		if self.logger then
			self.logger.debug('TaskTooltips: Using TooltipDataProcessor')
		end
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
			EnhanceTaskTooltip(tooltip)
		end)

		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, function(tooltip)
			EnhanceTaskTooltip(tooltip)
		end)
	end

	-- Also hook GameTooltip OnShow as fallback
	if self.logger then
		self.logger.debug('TaskTooltips: Hooking GameTooltip OnShow')
	end
	GameTooltip:HookScript('OnShow', function(tooltip)
		C_Timer.After(0.05, function()
			if tooltip:IsShown() then
				EnhanceTaskTooltip(tooltip)
			end
		end)
	end)

	tooltipHooked = true

	if self.logger then
		self.logger.info('Task tooltips initialized')
	end
end

-- Note: InitTaskTooltips is called from the main HousingEndeavor.lua OnEnable
