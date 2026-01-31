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
-- Progress Overlay Frame
----------------------------------------------------------------------------------------------------

local overlay = nil ---@type Frame|nil
local anchorFrame = nil ---@type Frame|nil

---Create the progress overlay frame
---@return Frame
local function CreateOverlay()
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
	if not overlay then
		overlay = CreateOverlay()
	end

	if not module.DB or not module.DB.progressOverlay.enabled then
		overlay:Hide()
		return
	end

	-- Check if anchor frame is still valid and visible
	if not anchorFrame or not anchorFrame:IsVisible() then
		overlay:Hide()
		return
	end

	local progress = module:GetCurrentProgress()
	if not progress then
		overlay.text:SetText(L['No data available'])
		overlay:SetSize(150, 30)
		overlay:Show()
		return
	end

	-- Get user settings
	local format = module.DB.progressOverlay.format or 'detailed'
	local color = module.DB.progressOverlay.color or { r = 1, g = 0.82, b = 0 }

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

-- Known frame names to look for
local KNOWN_FRAME_NAMES = {
	'NeighborhoodInitiativeFrame',
	'HousingDashboardFrame',
	'NeighborhoodFrame',
	'HousingFrame',
}

---Find the endeavor progress bar frame
---@return Frame|nil
local function FindProgressBar()
	-- First try known frame names
	for _, frameName in ipairs(KNOWN_FRAME_NAMES) do
		local frame = _G[frameName]
		if frame and not frame:IsForbidden() then
			-- Search for progress bar within this frame
			local candidates = {}
			CollectProgressBarCandidates(frame, 1, 10, candidates)

			-- Prioritize StatusBar types
			for _, candidate in ipairs(candidates) do
				if candidate.type == 'StatusBar' and candidate.depth > 2 then
					return candidate.obj
				end
			end

			-- Fall back to any candidate with good depth
			for _, candidate in ipairs(candidates) do
				if candidate.depth > 3 then
					return candidate.obj
				end
			end
		end
	end

	return nil
end

---Hook the progress bar to show overlay when visible
local function HookProgressBar()
	if hooked then
		return true
	end

	local progressBar = FindProgressBar()
	if not progressBar then
		return false
	end

	anchorFrame = progressBar

	-- Hook OnShow/OnHide
	progressBar:HookScript('OnShow', function()
		UpdateOverlay()
	end)

	progressBar:HookScript('OnHide', function()
		HideOverlay()
	end)

	hooked = true

	-- If already visible, show now
	if progressBar:IsVisible() then
		UpdateOverlay()
	end

	return true
end

----------------------------------------------------------------------------------------------------
-- Module Integration
----------------------------------------------------------------------------------------------------

---Initialize the progress display system
function module:InitProgressDisplay()
	-- Try to hook immediately
	if not HookProgressBar() then
		-- Retry when housing UI might become available
		self:RegisterEvent('ADDON_LOADED', function(_, addonName)
			if addonName == 'Blizzard_HousingUI' or addonName == 'Blizzard_NeighborhoodFrame' or addonName == 'Blizzard_HousingDashboardUI' then
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
end

-- Note: InitProgressDisplay is called from the main HousingEndeavor.lua OnEnable
