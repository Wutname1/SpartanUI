---@class SUI
local SUI = SUI
local MoveIt = SUI.MoveIt
local L = SUI.L

---@class SUI.MoveIt.CustomEditMode
local CustomEditMode = {}
MoveIt.CustomEditMode = CustomEditMode

-- State tracking
local isActive = false
local selectedOverlay = nil -- Currently selected mover
local isDragging = false

-- Colors - Colorblind-friendly palette (deuteranopia/protanopia safe)
local COLORS = {
	overlay = { 0.2, 0.6, 1.0, 0.5 }, -- Blue with constant alpha
	overlayHover = { 0.2, 0.6, 1.0, 0.5 }, -- Brighter blue on hover
	overlaySelected = { 1.0, 0.447, 0.0, 0.5 }, -- Orange #ff7200 when selected (colorblind-safe)
	overlayBright = { 1.0, 0.647, 0.361, 0.5 }, -- Bright orange #ffa55c for fade-in animation
	border = { 0.2, 0.6, 1.0, 1.0 }, -- Blue border with constant alpha
	borderHover = { 0.2, 0.6, 1.0, 1.0 }, -- Brighter on hover
	borderSelected = { 1.0, 0.447, 0.0, 1.0 }, -- Orange #ff7200 border when selected (colorblind-safe)
	borderBright = { 1.0, 0.647, 0.361, 1.0 }, -- Bright orange #ffa55c border for fade-in
	text = { 1.0, 1.0, 1.0, 1.0 }, -- White text
	textShadow = { 0, 0, 0, 0.8 }, -- Text shadow
}

---Animate a mover's color transition from bright orange to darker orange
---@param mover Frame The mover to animate
local function AnimateFadeIn(mover)
	-- Start with bright orange color (#ffa55c)
	mover:SetBackdropColor(unpack(COLORS.overlayBright))
	mover:SetBackdropBorderColor(unpack(COLORS.borderBright))

	-- Smoothly interpolate RGB only (keep alpha constant)
	local elapsed = 0
	local duration = 0.5
	local startR, startG, startB = COLORS.overlayBright[1], COLORS.overlayBright[2], COLORS.overlayBright[3]
	local endR, endG, endB = COLORS.overlay[1], COLORS.overlay[2], COLORS.overlay[3]
	local alpha = COLORS.overlay[4] -- Keep alpha constant
	local startBorderR, startBorderG, startBorderB = COLORS.borderBright[1], COLORS.borderBright[2], COLORS.borderBright[3]
	local endBorderR, endBorderG, endBorderB = COLORS.border[1], COLORS.border[2], COLORS.border[3]
	local borderAlpha = COLORS.border[4] -- Keep alpha constant

	local frame = mover.colorAnimFrame or CreateFrame('Frame')
	mover.colorAnimFrame = frame
	frame:SetScript('OnUpdate', function(self, delta)
		elapsed = elapsed + delta
		if elapsed >= duration then
			-- Animation complete
			mover:SetBackdropColor(endR, endG, endB, alpha)
			mover:SetBackdropBorderColor(endBorderR, endBorderG, endBorderB, borderAlpha)
			self:SetScript('OnUpdate', nil)
			return
		end

		-- Linear interpolation of RGB only (alpha stays constant)
		local progress = elapsed / duration
		local r = startR + (endR - startR) * progress
		local g = startG + (endG - startG) * progress
		local b = startB + (endB - startB) * progress

		local borderR = startBorderR + (endBorderR - startBorderR) * progress
		local borderG = startBorderG + (endBorderG - startBorderG) * progress
		local borderB = startBorderB + (endBorderB - startBorderB) * progress

		mover:SetBackdropColor(r, g, b, alpha)
		mover:SetBackdropBorderColor(borderR, borderG, borderB, borderAlpha)
	end)
end

---Create a pulsing color animation for selected movers
---Alternates between darker orange (#ff7200) and brighter orange (#ffa55c)
---@param mover Frame The mover to add glow to
local function CreateGlowAnimation(mover)
	if mover.glowAnimation then
		return mover.glowAnimation
	end

	-- Use OnUpdate for smooth color pulsing between two orange shades
	local elapsed = 0
	local duration = 0.8
	local frame = CreateFrame('Frame')
	mover.glowAnimation = frame

	frame.playing = false
	frame.Play = function(self)
		if self.playing then
			return
		end
		self.playing = true
		elapsed = 0
		self:SetScript('OnUpdate', function(_, delta)
			elapsed = elapsed + delta
			local progress = (elapsed % duration) / duration

			-- Bounce between 0 and 1
			if (math.floor(elapsed / duration) % 2) == 1 then
				progress = 1 - progress
			end

			-- Interpolate between overlaySelected (#ff7200) and overlayBright (#ffa55c)
			local startR, startG, startB = COLORS.overlaySelected[1], COLORS.overlaySelected[2], COLORS.overlaySelected[3]
			local endR, endG, endB = COLORS.overlayBright[1], COLORS.overlayBright[2], COLORS.overlayBright[3]
			local alpha = COLORS.overlaySelected[4]

			local r = startR + (endR - startR) * progress
			local g = startG + (endG - startG) * progress
			local b = startB + (endB - startB) * progress

			mover:SetBackdropColor(r, g, b, alpha)

			-- Also pulse border
			local startBorderR, startBorderG, startBorderB = COLORS.borderSelected[1], COLORS.borderSelected[2], COLORS.borderSelected[3]
			local endBorderR, endBorderG, endBorderB = COLORS.borderBright[1], COLORS.borderBright[2], COLORS.borderBright[3]
			local borderAlpha = COLORS.borderSelected[4]

			local borderR = startBorderR + (endBorderR - startBorderR) * progress
			local borderG = startBorderG + (endBorderG - startBorderG) * progress
			local borderB = startBorderB + (endBorderB - startBorderB) * progress

			mover:SetBackdropBorderColor(borderR, borderG, borderB, borderAlpha)
		end)
	end

	frame.Stop = function(self)
		if not self.playing then
			return
		end
		self.playing = false
		self:SetScript('OnUpdate', nil)
		-- Note: Don't reset color here - let the caller decide what color to use
	end

	return frame
end

---Check if custom EditMode is active
---@return boolean
function CustomEditMode:IsActive()
	return isActive
end

---Enter custom EditMode - show and style movers
function CustomEditMode:Enter()
	if isActive then
		return
	end

	if MoveIt.logger then
		MoveIt.logger.info('Entering custom EditMode')
	end

	isActive = true

	-- Hide problematic movers that cause input capture
	local problematicMovers = { 'VehicleSeatIndicator', 'SUI_CustomMover_VehicleMinimapPosition' }
	for _, moverName in ipairs(problematicMovers) do
		local mover = MoveIt.MoverList[moverName]
		if mover then
			mover:Hide()
			if MoveIt.logger then
				MoveIt.logger.debug(('Hiding problematic mover: %s'):format(moverName))
			end
		end
	end

	-- Show and style existing movers with staggered animation
	local delay = 0
	for name, mover in pairs(MoveIt.MoverList or {}) do
		-- Skip movers that cause input capture issues
		local skipMover = (name == 'VehicleSeatIndicator' or name == 'SUI_CustomMover_VehicleMinimapPosition')

		if MoveIt.logger and skipMover then
			MoveIt.logger.debug(('Skipping problematic mover: %s'):format(name))
		end

		if not skipMover and mover and mover.parent then
			C_Timer.After(delay, function()
				self:StyleMover(name, mover)
				-- Disable keyboard on individual movers (MoverWatcher handles escape)
				mover:EnableKeyboard(false)
				mover:Show()
				AnimateFadeIn(mover)
			end)
			delay = delay + 0.02 -- 20ms stagger for smooth cascade effect
		end
	end

	-- Show coordinate frame if it exists
	if MoveIt.coordFrame then
		MoveIt.coordFrame:Show()
	end

	-- Fire callback
	if MoveIt.Callbacks and MoveIt.Callbacks.OnEditModeEnter then
		MoveIt.Callbacks.OnEditModeEnter()
	end
end

---Exit custom EditMode - hide movers and restore original styling
function CustomEditMode:Exit()
	if not isActive then
		return
	end

	if MoveIt.logger then
		MoveIt.logger.info('Exiting custom EditMode')
	end

	isActive = false
	selectedOverlay = nil

	-- Hide all movers and restore original styling
	for name, mover in pairs(MoveIt.MoverList or {}) do
		if mover then
			self:RestoreMoverStyle(mover)
			-- Re-enable keyboard on movers for normal move mode
			mover:EnableKeyboard(true)
			mover:Hide()
		end
	end

	-- Hide coordinate frame
	if MoveIt.coordFrame then
		MoveIt.coordFrame:Hide()
	end

	-- Fire callback
	if MoveIt.Callbacks and MoveIt.Callbacks.OnEditModeExit then
		MoveIt.Callbacks.OnEditModeExit()
	end
end

---Toggle custom EditMode on/off
function CustomEditMode:Toggle()
	if isActive then
		self:Exit()
	else
		self:Enter()
	end
end

---Style a mover for EditMode (change appearance to blue)
---@param name string Mover name
---@param mover Frame The mover frame
function CustomEditMode:StyleMover(name, mover)
	if not mover then
		return
	end

	-- Store original colors if not already stored
	if not mover.originalBackdropColor then
		local r, g, b, a = mover:GetBackdropColor()
		mover.originalBackdropColor = { r, g, b, a }
	end
	if not mover.originalBackdropBorderColor then
		local r, g, b, a = mover:GetBackdropBorderColor()
		mover.originalBackdropBorderColor = { r, g, b, a }
	end

	-- Apply blue EditMode colors
	mover:SetBackdropColor(unpack(COLORS.overlay))
	mover:SetBackdropBorderColor(unpack(COLORS.border))

	-- Create glow animation if it doesn't exist
	if not mover.glowAnimation then
		CreateGlowAnimation(mover)
	end

	-- Hook mouse events for selection and hover
	if not mover.editModeHooked then
		mover:HookScript('OnEnter', function(self)
			if not isDragging and CustomEditMode:IsActive() then
				self:SetBackdropColor(unpack(COLORS.overlayHover))
				self:SetBackdropBorderColor(unpack(COLORS.borderHover))
			end
		end)

		mover:HookScript('OnLeave', function(self)
			if self ~= selectedOverlay and not isDragging and CustomEditMode:IsActive() then
				self:SetBackdropColor(unpack(COLORS.overlay))
				self:SetBackdropBorderColor(unpack(COLORS.border))
			end
		end)

		mover:HookScript('OnMouseDown', function(self, button)
			if button == 'LeftButton' and CustomEditMode:IsActive() then
				CustomEditMode:SelectOverlay(self)
			end
		end)

		mover.editModeHooked = true
	end

	if MoveIt.logger then
		MoveIt.logger.debug(('Styled mover: %s'):format(name))
	end
end

---Restore a mover's original styling
---@param mover Frame The mover frame
function CustomEditMode:RestoreMoverStyle(mover)
	if not mover then
		return
	end

	-- Restore original colors
	if mover.originalBackdropColor then
		mover:SetBackdropColor(unpack(mover.originalBackdropColor))
	end
	if mover.originalBackdropBorderColor then
		mover:SetBackdropBorderColor(unpack(mover.originalBackdropBorderColor))
	end

	-- Stop glow animation
	if mover.glowAnimation then
		mover.glowAnimation:Stop()
	end
end

---Deselect the currently selected mover
function CustomEditMode:DeselectOverlay()
	if not selectedOverlay then
		return
	end

	-- Stop any running color animation
	if selectedOverlay.colorAnimFrame then
		selectedOverlay.colorAnimFrame:SetScript('OnUpdate', nil)
	end
	selectedOverlay:SetBackdropColor(unpack(COLORS.overlay))
	selectedOverlay:SetBackdropBorderColor(unpack(COLORS.border))
	-- Stop glow animation
	if selectedOverlay.glowAnimation then
		selectedOverlay.glowAnimation:Stop()
	end

	selectedOverlay = nil
end

---Select a mover (highlight it)
---@param mover Frame The mover to select
function CustomEditMode:SelectOverlay(mover)
	if not mover then
		return
	end

	-- Deselect any Blizzard EditMode selection first
	if EditModeManagerFrame and EditModeManagerFrame.ClearSelectedSystem then
		EditModeManagerFrame:ClearSelectedSystem()
	end

	-- Deselect previous SUI mover
	if selectedOverlay and selectedOverlay ~= mover then
		self:DeselectOverlay()
	end

	-- Select new
	selectedOverlay = mover
	-- Stop any running color animation on the new selection
	if mover.colorAnimFrame then
		mover.colorAnimFrame:SetScript('OnUpdate', nil)
	end
	mover:SetBackdropColor(unpack(COLORS.overlaySelected))
	mover:SetBackdropBorderColor(unpack(COLORS.borderSelected))

	-- Start glow animation
	if mover.glowAnimation then
		mover.glowAnimation:Play()
	end

	if MoveIt.logger then
		MoveIt.logger.debug(('Selected mover: %s'):format(mover.name or 'unknown'))
	end

	-- Show settings panel
	if CustomEditMode.ShowSettingsPanel then
		CustomEditMode:ShowSettingsPanel(mover)
	end
end

---Start dragging a mover
---@param mover Frame The mover being dragged
function CustomEditMode:StartDrag(mover)
	if InCombatLockdown() then
		SUI:Print(ERR_NOT_IN_COMBAT)
		return
	end

	isDragging = true

	-- Start moving the mover
	mover:StartMoving()

	-- Show coordinate frame
	if MoveIt.coordFrame then
		MoveIt.coordFrame.child = mover
		MoveIt.coordFrame:Show()
	end

	if MoveIt.logger then
		MoveIt.logger.debug(('Start drag: %s'):format(mover.name or 'unknown'))
	end
end

---Stop dragging a mover
---@param mover Frame The mover that was being dragged
function CustomEditMode:StopDrag(mover)
	if InCombatLockdown() then
		return
	end

	isDragging = false
	local name = mover.name

	-- Stop moving the mover
	mover:StopMovingOrSizing()

	-- Save position
	if MoveIt.SaveMoverPosition and name then
		MoveIt:SaveMoverPosition(name)
	end

	-- Hide coordinate frame
	if MoveIt.coordFrame then
		MoveIt.coordFrame.child = nil
		MoveIt.coordFrame:Hide()
	end

	-- Call postdrag callback if exists
	if mover.postdrag then
		mover.postdrag(mover)
	end

	if MoveIt.logger then
		MoveIt.logger.debug(('Stop drag: %s'):format(name or 'unknown'))
	end
end

-- Hook into Blizzard's EditMode button if it exists
if EditModeManagerFrame then
	-- Use Blizzard's EditMode button to toggle our custom system
	hooksecurefunc(EditModeManagerFrame, 'EnterEditMode', function()
		-- Don't use Blizzard's EditMode, use ours
		if not CustomEditMode:IsActive() then
			CustomEditMode:Enter()
		end
	end)

	hooksecurefunc(EditModeManagerFrame, 'ExitEditMode', function()
		if CustomEditMode:IsActive() then
			CustomEditMode:Exit()
		end
	end)

	-- Hook SelectSystem to deselect SUI movers when Blizzard selects something
	hooksecurefunc(EditModeManagerFrame, 'SelectSystem', function()
		if CustomEditMode:IsActive() then
			CustomEditMode:DeselectOverlay()
		end
	end)
end

-- Create slash command (register after MoveIt OnEnable)
-- This will be called from MoveIt.lua OnEnable function

if MoveIt.logger then
	MoveIt.logger.info('Custom EditMode system loaded')
end
