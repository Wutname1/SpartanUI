---@class SUI
local SUI = SUI
local L = SUI.L

-- Only available in Retail
if not SUI.IsRetail then
	return
end

---@class SUI.Module.HousingEndeavor
local module = SUI.HousingEndeavor

----------------------------------------------------------------------------------------------------
-- Task Tooltip Enhancement
----------------------------------------------------------------------------------------------------

local hookedTaskFrames = {} ---@type table<Frame, boolean>

---Add XP info to a tooltip
---@param tooltip GameTooltip
---@param taskID number
local function EnhanceTooltip(tooltip, taskID)
	if not module.DB or not module.DB.taskTooltips.enabled then
		return
	end

	local entry = module:GetTaskXP(taskID)
	if not entry then
		return
	end

	-- Check if we already added our line (prevent duplicates)
	for i = 1, tooltip:NumLines() do
		local line = _G[tooltip:GetName() .. 'TextLeft' .. i]
		if line and line:GetText() and line:GetText():find(L['Endeavor Contribution']) then
			return
		end
	end

	-- Add separator and XP info
	tooltip:AddLine(' ')
	tooltip:AddLine(string.format('|cffffd700%s:|r %.2f XP', L['Endeavor Contribution'], entry.amount), 1, 1, 1)
	tooltip:Show()
end

---Try to extract task ID from a frame
---@param frame Frame
---@return number|nil
local function GetTaskIDFromFrame(frame)
	-- Try various ways task ID might be stored on a frame
	if frame.taskID then
		return frame.taskID
	end

	if frame.GetID and frame:GetID() > 0 then
		return frame:GetID()
	end

	-- Try data stored on the frame
	if frame.data and frame.data.taskID then
		return frame.data.taskID
	end

	-- Try parent frame
	local parent = frame:GetParent()
	if parent then
		if parent.taskID then
			return parent.taskID
		end
		if parent.data and parent.data.taskID then
			return parent.data.taskID
		end
	end

	return nil
end

---Hook a task frame for tooltip enhancement
---@param frame Frame
local function HookTaskFrame(frame)
	if hookedTaskFrames[frame] then
		return
	end

	local ok, _ = pcall(function()
		frame:HookScript('OnEnter', function(self)
			if not module.DB or not module.DB.taskTooltips.enabled then
				return
			end

			local taskID = GetTaskIDFromFrame(self)
			if taskID then
				-- Wait a frame for the default tooltip to appear
				C_Timer.After(0.05, function()
					if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
						EnhanceTooltip(GameTooltip, taskID)
					end
				end)
			end
		end)
	end)

	if ok then
		hookedTaskFrames[frame] = true
	end
end

----------------------------------------------------------------------------------------------------
-- Frame Discovery
----------------------------------------------------------------------------------------------------

-- Known frame patterns for task lists
local TASK_FRAME_PATTERNS = {
	'Task',
	'Activity',
	'Endeavor',
	'Quest',
	'Objective',
}

---Check if a frame looks like a task entry
---@param frame Frame
---@return boolean
local function IsTaskFrame(frame)
	local name = frame:GetName() or ''
	local nameLower = name:lower()

	for _, pattern in ipairs(TASK_FRAME_PATTERNS) do
		if nameLower:find(pattern:lower()) then
			return true
		end
	end

	-- Check if it has task-like properties
	if frame.taskID or (frame.data and frame.data.taskID) then
		return true
	end

	return false
end

---Recursively search for task frames
---@param parent Frame
---@param depth number
---@param maxDepth number
local function FindAndHookTaskFrames(parent, depth, maxDepth)
	if depth > maxDepth then
		return
	end

	local children = { parent:GetChildren() }
	for _, child in ipairs(children) do
		if child and not child:IsForbidden() then
			if IsTaskFrame(child) then
				HookTaskFrame(child)
			end

			-- Recurse
			FindAndHookTaskFrames(child, depth + 1, maxDepth)
		end
	end
end

---Search for and hook task frames in known containers
local function HookTaskFrames()
	-- Known container frame names
	local containers = {
		'NeighborhoodInitiativeFrame',
		'HousingDashboardFrame',
		'EndeavorsFrame',
		'InitiativeTasksFrame',
	}

	for _, containerName in ipairs(containers) do
		local container = _G[containerName]
		if container and not container:IsForbidden() then
			pcall(function()
				FindAndHookTaskFrames(container, 1, 15)
			end)
		end
	end

	-- Also search for dynamically named task frames
	for name, frame in pairs(_G) do
		if type(frame) == 'table' and type(name) == 'string' then
			local nameLower = name:lower()
			if nameLower:find('task') and (nameLower:find('initiative') or nameLower:find('endeavor') or nameLower:find('neighborhood')) then
				local ok, isForbidden = pcall(function()
					return frame.IsForbidden and frame:IsForbidden()
				end)
				if ok and not isForbidden and frame.HookScript then
					HookTaskFrame(frame)
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
-- GameTooltip Hook (Fallback approach)
----------------------------------------------------------------------------------------------------

local tooltipHooked = false

---Hook GameTooltip for task items
local function HookGameTooltip()
	if tooltipHooked then
		return
	end

	-- Hook tooltip show
	GameTooltip:HookScript('OnTooltipSetDefaultAnchor', function(tooltip)
		if not module.DB or not module.DB.taskTooltips.enabled then
			return
		end

		-- Check if we have an owner with task info
		local owner = tooltip:GetOwner()
		if owner then
			local taskID = GetTaskIDFromFrame(owner)
			if taskID then
				C_Timer.After(0.1, function()
					if tooltip:IsShown() then
						EnhanceTooltip(tooltip, taskID)
					end
				end)
			end
		end
	end)

	tooltipHooked = true
end

----------------------------------------------------------------------------------------------------
-- Module Integration
----------------------------------------------------------------------------------------------------

---Initialize the task tooltip system
function module:InitTaskTooltips()
	-- Try to hook immediately
	HookTaskFrames()
	HookGameTooltip()

	-- Retry when housing UI might become available
	self:RegisterEvent('ADDON_LOADED', function(_, addonName)
		if addonName == 'Blizzard_HousingUI' or addonName == 'Blizzard_NeighborhoodFrame' then
			C_Timer.After(0.5, HookTaskFrames)
			C_Timer.After(2, HookTaskFrames)
		end
	end)

	-- Retry periodically as frames may be created dynamically
	C_Timer.After(5, HookTaskFrames)
	C_Timer.After(15, HookTaskFrames)

	-- Also hook when activity log updates (new tasks may appear)
	self:RegisterMessage('SUI_HOUSING_ENDEAVOR_CACHE_UPDATED', function()
		C_Timer.After(0.5, HookTaskFrames)
	end)
end

-- Note: InitTaskTooltips is called from the main HousingEndeavor.lua OnEnable
