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
	module.logger.debug('ProgressDisplay.lua loading, module exists: ' .. tostring(module ~= nil))
end

----------------------------------------------------------------------------------------------------
-- Progress Overlay Frame
----------------------------------------------------------------------------------------------------

local overlay = nil ---@type Frame|nil
local anchorFrame = nil ---@type Frame|nil

---Create the progress overlay frame
---@return Frame
local function CreateOverlay()
	if module and module.logger then
		module.logger.debug('ProgressDisplay: CreateOverlay called')
	end

	local frame = CreateFrame('Frame', 'SUI_HousingEndeavor_ProgressOverlay', UIParent, 'BackdropTemplate')
	frame:SetFrameStrata('HIGH')
	frame:SetFrameLevel(50)
	frame:SetClampedToScreen(true)
	frame:Hide()

	-- Backdrop styling (tooltip-like)
	frame:SetBackdrop({
		bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
		edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

	-- Text display
	frame.text = frame:CreateFontString(nil, 'OVERLAY')
	frame.text:SetPoint('CENTER', frame, 'CENTER', 0, 0)
	SUI.Font:Format(frame.text, 12, 'HousingEndeavor')
	frame.text:SetJustifyH('CENTER')

	return frame
end

---Update the overlay text and size
local function UpdateOverlay()
	if module and module.logger then
		module.logger.debug('ProgressDisplay: UpdateOverlay called')
	end

	if not overlay then
		overlay = CreateOverlay()
	end

	if not module or not module.DB or not module.DB.progressOverlay or not module.DB.progressOverlay.enabled then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: Disabled or no DB')
		end
		overlay:Hide()
		return
	end

	-- Check if anchor frame is still valid and visible
	if not anchorFrame or not anchorFrame:IsVisible() then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: No anchor frame or not visible')
		end
		overlay:Hide()
		return
	end

	local progress = module:GetCurrentProgress()
	if not progress then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: No progress data')
		end
		overlay.text:SetText(L['No data available'])
		overlay:SetSize(150, 30)
		overlay:Show()
		return
	end

	-- Get user settings
	local format = module.DB.progressOverlay.format or 'detailed'
	local color = module.DB.progressOverlay.color or { r = 1, g = 1, b = 1 }

	-- Format and set text
	local text = module:FormatProgressText(format, progress)
	overlay.text:SetTextColor(color.r, color.g, color.b)
	overlay.text:SetText(text)

	-- Auto-size frame to fit text
	local textWidth = overlay.text:GetStringWidth()
	local textHeight = overlay.text:GetStringHeight()
	overlay:SetSize(textWidth + 24, textHeight + 16)

	-- Anchor to the frame
	overlay:ClearAllPoints()
	overlay:SetPoint('BOTTOM', anchorFrame, 'TOP', 80, -5)
	overlay:Show()

	if module and module.logger then
		module.logger.debug('ProgressDisplay: Overlay shown with text: ' .. text)
	end
end

---Hide the overlay
local function HideOverlay()
	if overlay then
		overlay:Hide()
	end
end

----------------------------------------------------------------------------------------------------
-- Frame Hooking
----------------------------------------------------------------------------------------------------

local hooked = false

---Recursively collect frames that might be progress bars
---@param parent Frame
---@param depth number
---@param maxDepth number
---@param candidates table
local function CollectProgressBarCandidates(parent, depth, maxDepth, candidates)
	if depth > maxDepth then
		return
	end

	local children = { parent:GetChildren() }
	for _, child in ipairs(children) do
		if child and not child:IsForbidden() then
			local objType = child:GetObjectType()
			local name = child:GetName() or ''

			-- Check if this looks like a progress bar
			local isCandidate = false

			if objType == 'StatusBar' then
				isCandidate = true
			elseif objType == 'Frame' or objType == 'Slider' then
				-- Check for progress-related naming
				local nameLower = name:lower()
				if nameLower:find('progress') or nameLower:find('bar') or nameLower:find('xp') or nameLower:find('endeavor') then
					isCandidate = true
				end
			end

			if isCandidate then
				table.insert(candidates, {
					obj = child,
					depth = depth,
					type = objType,
					name = name,
				})
			end

			-- Recurse into children
			CollectProgressBarCandidates(child, depth + 1, maxDepth, candidates)
		end
	end
end

---Find the endeavor progress bar frame
---@return Frame|nil
local function FindProgressBar()
	if module and module.logger then
		module.logger.debug('ProgressDisplay: FindProgressBar called')
	end

	-- First try the specific path you mentioned
	local initiativesFrame = HousingDashboardFrame
		and HousingDashboardFrame.HouseInfoContent
		and HousingDashboardFrame.HouseInfoContent.ContentFrame
		and HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame
	if initiativesFrame and not initiativesFrame:IsForbidden() then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: Found InitiativesFrame directly')
		end
		-- Search for StatusBar within this frame
		local candidates = {}
		CollectProgressBarCandidates(initiativesFrame, 1, 5, candidates)

		for _, candidate in ipairs(candidates) do
			if module and module.logger then
				module.logger.debug('ProgressDisplay: Candidate: ' .. candidate.type .. ' depth=' .. candidate.depth .. ' name=' .. candidate.name)
			end
			if candidate.type == 'StatusBar' then
				if module and module.logger then
					module.logger.debug('ProgressDisplay: Found StatusBar in InitiativesFrame')
				end
				return candidate.obj
			end
		end

		-- If no StatusBar found, use the InitiativesFrame itself as anchor
		if module and module.logger then
			module.logger.debug('ProgressDisplay: No StatusBar found, using InitiativesFrame as anchor')
		end
		return initiativesFrame
	end

	-- Fallback: Try known frame names
	local KNOWN_FRAME_NAMES = {
		'HousingDashboardFrame',
		'NeighborhoodInitiativeFrame',
		'NeighborhoodFrame',
		'HousingFrame',
	}

	for _, frameName in ipairs(KNOWN_FRAME_NAMES) do
		local frame = _G[frameName]
		if frame and not frame:IsForbidden() then
			if module and module.logger then
				module.logger.debug('ProgressDisplay: Searching in ' .. frameName)
			end
			-- Search for progress bar within this frame
			local candidates = {}
			CollectProgressBarCandidates(frame, 1, 10, candidates)

			-- Prioritize StatusBar types
			for _, candidate in ipairs(candidates) do
				if candidate.type == 'StatusBar' and candidate.depth > 2 then
					if module and module.logger then
						module.logger.debug('ProgressDisplay: Found StatusBar at depth ' .. candidate.depth)
					end
					return candidate.obj
				end
			end

			-- Fall back to any candidate with good depth
			for _, candidate in ipairs(candidates) do
				if candidate.depth > 3 then
					if module and module.logger then
						module.logger.debug('ProgressDisplay: Using fallback candidate at depth ' .. candidate.depth)
					end
					return candidate.obj
				end
			end
		end
	end

	if module and module.logger then
		module.logger.debug('ProgressDisplay: No progress bar found')
	end
	return nil
end

---Hook the progress bar to show overlay when visible
local function HookProgressBar()
	if hooked then
		return true
	end

	if module and module.logger then
		module.logger.debug('ProgressDisplay: HookProgressBar called')
	end

	local progressBar = FindProgressBar()
	if not progressBar then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: No progress bar to hook')
		end
		return false
	end

	anchorFrame = progressBar

	if module and module.logger then
		module.logger.debug('ProgressDisplay: Hooking progress bar OnShow/OnHide')
	end

	-- Hook OnShow/OnHide
	progressBar:HookScript('OnShow', function()
		if module and module.logger then
			module.logger.debug('ProgressDisplay: OnShow triggered')
		end
		UpdateOverlay()
	end)

	progressBar:HookScript('OnHide', function()
		if module and module.logger then
			module.logger.debug('ProgressDisplay: OnHide triggered')
		end
		HideOverlay()
	end)

	hooked = true

	-- If already visible, show now
	if progressBar:IsVisible() then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: Progress bar already visible, updating overlay')
		end
		UpdateOverlay()
	end

	if module and module.logger then
		module.logger.info('ProgressDisplay: Successfully hooked progress bar')
	end

	return true
end

----------------------------------------------------------------------------------------------------
-- Module Integration
----------------------------------------------------------------------------------------------------

---Initialize the progress display system
function module:InitProgressDisplay()
	if self.logger then
		self.logger.debug('ProgressDisplay: InitProgressDisplay called')
	end

	-- TEST HOOKS: Try various events to find the fastest trigger
	-- Hook HousingDashboardFrame if it exists
	if HousingDashboardFrame then
		if self.logger then
			self.logger.debug('TEST: HousingDashboardFrame exists at init')
		end
		HousingDashboardFrame:HookScript('OnShow', function()
			if self.logger then
				self.logger.debug('TEST: HousingDashboardFrame OnShow fired')
			end
			C_Timer.After(0.1, HookProgressBar)
		end)
	end

	self:RegisterEvent('NEIGHBORHOOD_INITIATIVE_UPDATED', function()
		if self.logger then
			self.logger.debug('TEST: NEIGHBORHOOD_INITIATIVE_UPDATED event fired, hooked=' .. tostring(hooked))
		end
		-- Always try to update when this fires - it's our fastest trigger
		if not hooked then
			HookProgressBar()
		end
		-- Update overlay immediately since data changed
		UpdateOverlay()
	end)

	-- Try UIParent child added approach
	if self.logger then
		self.logger.debug('TEST: Setting up frame watch')
	end

	-- Watch for HousingDashboardFrame to appear
	local watchFrame = CreateFrame('Frame')
	watchFrame:RegisterEvent('ADDON_LOADED')
	watchFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
	watchFrame:SetScript('OnEvent', function(_, event, arg1)
		if self.logger then
			self.logger.debug('TEST: watchFrame event: ' .. event .. ' arg=' .. tostring(arg1))
		end

		if event == 'ADDON_LOADED' then
			if arg1 == 'Blizzard_HousingUI' or arg1 == 'Blizzard_HousingDashboardUI' then
				if self.logger then
					self.logger.debug('TEST: Housing addon loaded: ' .. arg1)
				end
				-- Try hooking after a short delay
				C_Timer.After(0.1, function()
					if HousingDashboardFrame then
						if self.logger then
							self.logger.debug('TEST: HousingDashboardFrame now exists after addon load')
						end
						if not hooked then
							HousingDashboardFrame:HookScript('OnShow', function()
								if self.logger then
									self.logger.debug('TEST: HousingDashboardFrame OnShow (post-addon-load hook)')
								end
								C_Timer.After(0.1, HookProgressBar)
							end)
							-- If already visible
							if HousingDashboardFrame:IsVisible() then
								if self.logger then
									self.logger.debug('TEST: HousingDashboardFrame already visible')
								end
								HookProgressBar()
							end
						end
					end
				end)
			end
		end
	end)

	-- Try to hook immediately
	if not HookProgressBar() then
		if self.logger then
			self.logger.debug('ProgressDisplay: Initial hook failed, setting up retries')
		end

		-- Retry when housing UI might become available
		self:RegisterEvent('ADDON_LOADED', function(_, addonName)
			if addonName == 'Blizzard_HousingUI' or addonName == 'Blizzard_NeighborhoodFrame' or addonName == 'Blizzard_HousingDashboardUI' then
				if self.logger then
					self.logger.debug('ProgressDisplay: ADDON_LOADED for ' .. addonName)
				end
				C_Timer.After(0.5, HookProgressBar)
			end
		end)

		-- Also retry a few times with delays
		C_Timer.After(3, HookProgressBar)
		C_Timer.After(10, HookProgressBar)
	end

	-- Register for settings changes
	self:RegisterMessage('SUI_HOUSING_ENDEAVOR_SETTINGS_CHANGED', UpdateOverlay)

	-- Register for data updates
	self:RegisterMessage('SUI_HOUSING_ENDEAVOR_UPDATED', UpdateOverlay)

	if self.logger then
		self.logger.info('ProgressDisplay: Initialization complete')
	end
end

-- Note: InitProgressDisplay is called from the main HousingEndeavor.lua OnEnable
