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
-- Progress Display (on progress bar like EnhancedEndeavors)
----------------------------------------------------------------------------------------------------

local progressBar = nil ---@type StatusBar|nil
local progressText = nil ---@type FontString|nil
local contributionText = nil ---@type FontString|nil
local overlayFrame = nil ---@type Frame|nil

---Create the overlay frame with background (positioned on the progress bar)
---@param parent Frame
---@return Frame
local function CreateOverlayFrame(parent)
	local frame = CreateFrame('Frame', 'SUI_HousingEndeavor_ProgressOverlay', parent, 'BackdropTemplate')
	frame:SetAllPoints(parent)
	frame:SetFrameLevel(parent:GetFrameLevel() + 5)

	-- Backdrop styling with 30% alpha
	frame:SetBackdrop({
		bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
		edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.3)
	frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.5)

	return frame
end

---Create the progress text FontString (on the progress bar)
---@param parent Frame
---@return FontString
local function CreateProgressText(parent)
	local text = parent:CreateFontString('SUI_HousingEndeavor_ProgressText', 'OVERLAY')
	text:SetPoint('RIGHT', parent, 'RIGHT', -15, 0)
	text:SetFontObject(GameFontHighlight)
	text:SetJustifyH('RIGHT')
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	return text
end

---Create the contribution text FontString (above the progress bar)
---@param parent Frame
---@return FontString
local function CreateContributionText(parent)
	local text = parent:CreateFontString('SUI_HousingEndeavor_ContributionText', 'OVERLAY')
	text:SetPoint('BOTTOM', parent, 'TOP', 0, 3)
	text:SetFontObject(GameFontHighlight)
	text:SetJustifyH('CENTER')
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	return text
end

---Update the progress display
local function UpdateDisplay()
	if module and module.logger then
		module.logger.debug('ProgressDisplay: UpdateDisplay called')
	end

	if not progressBar then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: No progress bar')
		end
		return
	end

	if not module or not module.DB or not module.DB.progressOverlay or not module.DB.progressOverlay.enabled then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: Disabled or no DB')
		end
		if progressText then
			progressText:Hide()
		end
		if contributionText then
			contributionText:Hide()
		end
		if overlayFrame then
			overlayFrame:Hide()
		end
		return
	end

	-- Create elements if needed
	if not overlayFrame then
		overlayFrame = CreateOverlayFrame(progressBar)
	end
	if not progressText then
		progressText = CreateProgressText(progressBar)
	end
	if not contributionText then
		contributionText = CreateContributionText(progressBar)
	end

	-- Get initiative info (data should already be current when event fires)
	local info = module:GetInitiativeInfo()
	if not info then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: No initiative info')
		end
		progressText:SetText('...')
		contributionText:SetText('')
		overlayFrame:Show()
		progressText:Show()
		contributionText:Show()
		return
	end

	-- Get user settings
	local color = module.DB.progressOverlay.color or { r = 1, g = 1, b = 1 }

	-- Calculate progress values (like EnhancedEndeavors)
	local currentProgress = (info.currentProgress or 0) * 100
	local maxProgress = (info.progressRequired or 10) * 100
	local contribution = (info.playerTotalContribution or 0) * 100

	-- Clamp current to max
	if currentProgress >= maxProgress then
		currentProgress = maxProgress
	end

	-- Calculate percentages
	local percent = 0
	if maxProgress > 0 then
		percent = (currentProgress / maxProgress) * 100
	end

	local contributionPercent = 0
	if currentProgress > 0 then
		contributionPercent = (contribution / currentProgress) * 100
	end

	-- Format progress text: "(50.0%) 500/1,000"
	local progressStr
	if currentProgress >= maxProgress then
		progressStr = L['All milestones completed!'] or 'All milestones completed!'
	else
		progressStr = string.format('(%.1f%%) %s/%s', percent, BreakUpLargeNumbers(currentProgress), BreakUpLargeNumbers(maxProgress))
	end

	-- Format contribution text: "Your Contribution: 150 (3.0%)"
	local contributionStr = string.format('%s: %s (%.1f%%)', L['Your Contribution'] or 'Your Contribution', BreakUpLargeNumbers(contribution), contributionPercent)

	-- Apply text
	progressText:SetText(progressStr)
	progressText:SetTextColor(color.r, color.g, color.b)

	contributionText:SetText(contributionStr)
	contributionText:SetTextColor(color.r, color.g, color.b)

	-- Show elements
	overlayFrame:Show()
	progressText:Show()
	contributionText:Show()

	if module and module.logger then
		module.logger.debug('ProgressDisplay: Display updated - ' .. progressStr)
	end
end

---Hide the display
local function HideDisplay()
	if progressText then
		progressText:Hide()
	end
	if contributionText then
		contributionText:Hide()
	end
	if overlayFrame then
		overlayFrame:Hide()
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
---@return StatusBar|nil
local function FindProgressBar()
	if module and module.logger then
		module.logger.debug('ProgressDisplay: FindProgressBar called')
	end

	-- First try the specific path
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
	end

	if module and module.logger then
		module.logger.debug('ProgressDisplay: No progress bar found')
	end
	return nil
end

---Hook the progress bar to show display when visible
local function HookProgressBar()
	if hooked then
		return true
	end

	if module and module.logger then
		module.logger.debug('ProgressDisplay: HookProgressBar called')
	end

	local bar = FindProgressBar()
	if not bar then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: No progress bar to hook')
		end
		return false
	end

	progressBar = bar

	if module and module.logger then
		module.logger.debug('ProgressDisplay: Hooking progress bar OnShow/OnHide')
	end

	-- Hook OnShow/OnHide
	bar:HookScript('OnShow', function()
		if module and module.logger then
			module.logger.debug('ProgressDisplay: OnShow triggered')
		end
		UpdateDisplay()
	end)

	bar:HookScript('OnHide', function()
		if module and module.logger then
			module.logger.debug('ProgressDisplay: OnHide triggered')
		end
		HideDisplay()
	end)

	hooked = true

	-- If already visible, show now
	if bar:IsVisible() then
		if module and module.logger then
			module.logger.debug('ProgressDisplay: Progress bar already visible, updating display')
		end
		UpdateDisplay()
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

	-- Hook HousingDashboardFrame if it exists
	if HousingDashboardFrame then
		if self.logger then
			self.logger.debug('ProgressDisplay: HousingDashboardFrame exists at init')
		end
		HousingDashboardFrame:HookScript('OnShow', function()
			if self.logger then
				self.logger.debug('ProgressDisplay: HousingDashboardFrame OnShow fired')
			end
			C_Timer.After(0.1, HookProgressBar)
		end)
	end

	-- Note: NEIGHBORHOOD_INITIATIVE_UPDATED is handled by main HousingEndeavor.lua
	-- which sends SUI_HOUSING_ENDEAVOR_UPDATED message that we listen for below

	-- Watch for HousingDashboardFrame to appear
	local watchFrame = CreateFrame('Frame')
	watchFrame:RegisterEvent('ADDON_LOADED')
	watchFrame:SetScript('OnEvent', function(_, event, arg1)
		if event == 'ADDON_LOADED' then
			if arg1 == 'Blizzard_HousingUI' or arg1 == 'Blizzard_HousingDashboard' then
				if self.logger then
					self.logger.debug('ProgressDisplay: Housing addon loaded: ' .. arg1)
				end
				C_Timer.After(0.1, function()
					if HousingDashboardFrame then
						if self.logger then
							self.logger.debug('ProgressDisplay: HousingDashboardFrame now exists after addon load')
						end
						if not hooked then
							HousingDashboardFrame:HookScript('OnShow', function()
								if self.logger then
									self.logger.debug('ProgressDisplay: HousingDashboardFrame OnShow (post-addon-load hook)')
								end
								C_Timer.After(0.1, HookProgressBar)
							end)
							if HousingDashboardFrame:IsVisible() then
								if self.logger then
									self.logger.debug('ProgressDisplay: HousingDashboardFrame already visible')
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

		-- Retry with delays
		C_Timer.After(3, HookProgressBar)
		C_Timer.After(10, HookProgressBar)
	end

	-- Note: Message handlers are registered centrally in HousingEndeavor.lua OnEnable
	-- to avoid multiple handlers overwriting each other

	if self.logger then
		self.logger.info('ProgressDisplay: Initialization complete')
	end
end

---Public update function called by centralized message handler
function module:UpdateProgressDisplay()
	if self.logger then
		self.logger.debug('ProgressDisplay: UpdateProgressDisplay called, progressBar=' .. tostring(progressBar ~= nil) .. ', visible=' .. tostring(progressBar and progressBar:IsVisible()))
	end
	if progressBar and progressBar:IsVisible() then
		C_Timer.After(0.3, UpdateDisplay)
	end
end

-- Note: InitProgressDisplay is called from the main HousingEndeavor.lua OnEnable
