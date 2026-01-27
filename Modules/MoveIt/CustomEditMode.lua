---@class SUI
local SUI = SUI
local MoveIt = SUI.MoveIt
local L = SUI.L

---@class SUI.MoveIt.CustomEditMode
local CustomEditMode = {}
MoveIt.CustomEditMode = CustomEditMode

-- State tracking
local isActive = false
local overlays = {} -- Map of moverName -> overlay frame
local selectedOverlay = nil
local isDragging = false

-- Colors
local COLORS = {
	overlay = { 0.2, 0.6, 1.0, 0.3 }, -- Blue with transparency
	overlayHover = { 0.2, 0.6, 1.0, 0.5 }, -- Brighter blue on hover
	overlaySelected = { 0.3, 1.0, 0.3, 0.5 }, -- Green when selected
	border = { 0.2, 0.6, 1.0, 0.8 }, -- Blue border
	borderHover = { 0.2, 0.6, 1.0, 1.0 }, -- Brighter on hover
	borderSelected = { 0.3, 1.0, 0.3, 1.0 }, -- Green border when selected
	text = { 1.0, 1.0, 1.0, 1.0 }, -- White text
	textShadow = { 0, 0, 0, 0.8 }, -- Text shadow
}

---Animate an overlay's fade in
---@param overlay Frame The overlay to animate
local function AnimateFadeIn(overlay)
	if not overlay.fadeAnimation then
		overlay.fadeAnimation = overlay:CreateAnimationGroup()
		local fade = overlay.fadeAnimation:CreateAnimation('Alpha')
		fade:SetFromAlpha(0)
		fade:SetToAlpha(1)
		fade:SetDuration(0.2)
		fade:SetSmoothing('IN')
	end
	overlay:SetAlpha(0)
	overlay.fadeAnimation:Play()
end

---Create a pulsing glow animation for selected overlays
---@param overlay Frame The overlay to add glow to
local function CreateGlowAnimation(overlay)
	if overlay.glowAnimation then
		return
	end

	overlay.glowAnimation = overlay:CreateAnimationGroup()
	overlay.glowAnimation:SetLooping('BOUNCE')

	local alpha = overlay.glowAnimation:CreateAnimation('Alpha')
	alpha:SetFromAlpha(0.5)
	alpha:SetToAlpha(1.0)
	alpha:SetDuration(0.8)
	alpha:SetSmoothing('IN_OUT')

	return overlay.glowAnimation
end

---Check if custom EditMode is active
---@return boolean
function CustomEditMode:IsActive()
	return isActive
end

---Enter custom EditMode - show overlays for all movers
function CustomEditMode:Enter()
	if isActive then
		return
	end

	if MoveIt.logger then
		MoveIt.logger.info('Entering custom EditMode')
	end

	isActive = true

	-- Create overlays for all movers with staggered animation
	local delay = 0
	for name, mover in pairs(MoveIt.MoverList or {}) do
		if mover and mover.parent then
			C_Timer.After(delay, function()
				local overlay = self:CreateOverlay(name, mover)
				if overlay then
					AnimateFadeIn(overlay)
				end
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

---Exit custom EditMode - hide and clean up overlays
function CustomEditMode:Exit()
	if not isActive then
		return
	end

	if MoveIt.logger then
		MoveIt.logger.info('Exiting custom EditMode')
	end

	isActive = false
	selectedOverlay = nil

	-- Hide and clean up all overlays
	for name, overlay in pairs(overlays) do
		overlay:Hide()
		overlay:SetParent(nil)
		overlay:ClearAllPoints()
	end
	wipe(overlays)

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

---Create an overlay frame for a mover
---@param name string Mover name
---@param mover Frame The mover frame
---@return Frame|nil overlay The created overlay frame
function CustomEditMode:CreateOverlay(name, mover)
	if overlays[name] then
		overlays[name]:Show()
		return overlays[name]
	end

	local parent = mover.parent
	if not parent then
		return
	end

	-- Create overlay frame
	local overlay = CreateFrame('Frame', 'SUI_EditMode_Overlay_' .. name, UIParent, BackdropTemplateMixin and 'BackdropTemplate')
	overlay:SetFrameStrata('DIALOG')
	overlay:SetFrameLevel(parent:GetFrameLevel() + 10)

	-- Make it clickable and draggable
	overlay:EnableMouse(true)
	overlay:SetMovable(true)
	overlay:RegisterForDrag('LeftButton')

	-- Visual styling
	overlay:SetBackdrop({
		bgFile = 'Interface\\Buttons\\WHITE8X8',
		edgeFile = 'Interface\\Buttons\\WHITE8X8',
		edgeSize = 2,
	})
	overlay:SetBackdropColor(unpack(COLORS.overlay))
	overlay:SetBackdropBorderColor(unpack(COLORS.border))

	-- Position to match the parent frame
	overlay:SetAllPoints(parent)

	-- Name label
	local nameText = overlay:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
	nameText:SetPoint('TOP', overlay, 'TOP', 0, -10)
	nameText:SetText(mover.DisplayName or name)
	nameText:SetTextColor(unpack(COLORS.text))
	nameText:SetShadowColor(unpack(COLORS.textShadow))
	nameText:SetShadowOffset(2, -2)
	overlay.nameText = nameText

	-- Store references
	overlay.moverName = name
	overlay.mover = mover
	overlay.parent = parent

	-- Create glow animation
	CreateGlowAnimation(overlay)

	-- Mouse handlers with smooth transitions
	overlay:SetScript('OnEnter', function(self)
		if not isDragging then
			-- Smooth color transition
			UIFrameFadeOut(self, 0.1, self:GetAlpha(), 1.0)
			self:SetBackdropColor(unpack(COLORS.overlayHover))
			self:SetBackdropBorderColor(unpack(COLORS.borderHover))
		end
	end)

	overlay:SetScript('OnLeave', function(self)
		if self ~= selectedOverlay and not isDragging then
			self:SetBackdropColor(unpack(COLORS.overlay))
			self:SetBackdropBorderColor(unpack(COLORS.border))
		end
	end)

	overlay:SetScript('OnMouseDown', function(self, button)
		if button == 'LeftButton' then
			-- Select this overlay
			CustomEditMode:SelectOverlay(self)
		end
	end)

	overlay:SetScript('OnDragStart', function(self)
		CustomEditMode:StartDrag(self)
	end)

	overlay:SetScript('OnDragStop', function(self)
		CustomEditMode:StopDrag(self)
	end)

	overlays[name] = overlay
	overlay:Show()

	if MoveIt.logger then
		MoveIt.logger.debug(('Created overlay for %s'):format(name))
	end

	return overlay
end

---Select an overlay (highlight it)
---@param overlay Frame The overlay to select
function CustomEditMode:SelectOverlay(overlay)
	-- Deselect previous
	if selectedOverlay and selectedOverlay ~= overlay then
		selectedOverlay:SetBackdropColor(unpack(COLORS.overlay))
		selectedOverlay:SetBackdropBorderColor(unpack(COLORS.border))
		-- Stop glow animation
		if selectedOverlay.glowAnimation then
			selectedOverlay.glowAnimation:Stop()
		end
	end

	-- Select new
	selectedOverlay = overlay
	overlay:SetBackdropColor(unpack(COLORS.overlaySelected))
	overlay:SetBackdropBorderColor(unpack(COLORS.borderSelected))

	-- Start glow animation
	if overlay.glowAnimation then
		overlay.glowAnimation:Play()
	end

	if MoveIt.logger then
		MoveIt.logger.debug(('Selected overlay: %s'):format(overlay.moverName))
	end

	-- Show settings panel (Phase 3)
	if CustomEditMode.ShowSettingsPanel then
		CustomEditMode:ShowSettingsPanel(overlay)
	end
end

---Start dragging an overlay
---@param overlay Frame The overlay being dragged
function CustomEditMode:StartDrag(overlay)
	if InCombatLockdown() then
		SUI:Print(ERR_NOT_IN_COMBAT)
		return
	end

	isDragging = true
	local mover = overlay.mover

	-- Start moving the mover (not the overlay)
	mover:StartMoving()

	-- Show coordinate frame
	if MoveIt.coordFrame then
		MoveIt.coordFrame.child = mover
		MoveIt.coordFrame:Show()
	end

	if MoveIt.logger then
		MoveIt.logger.debug(('Start drag: %s'):format(overlay.moverName))
	end
end

---Stop dragging an overlay
---@param overlay Frame The overlay that was being dragged
function CustomEditMode:StopDrag(overlay)
	if InCombatLockdown() then
		return
	end

	isDragging = false
	local mover = overlay.mover
	local name = overlay.moverName

	-- Stop moving the mover
	mover:StopMovingOrSizing()

	-- Update overlay position to match parent
	overlay:ClearAllPoints()
	overlay:SetAllPoints(overlay.parent)

	-- Save position (Phase 2 will implement proper relative positioning)
	if MoveIt.SaveMoverPosition then
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
		MoveIt.logger.debug(('Stop drag: %s'):format(name))
	end
end

---Update overlay positions (call when frames resize or move)
function CustomEditMode:UpdateOverlays()
	for name, overlay in pairs(overlays) do
		if overlay.parent and overlay.parent:IsShown() then
			overlay:ClearAllPoints()
			overlay:SetAllPoints(overlay.parent)
		end
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
end

-- Create slash command
SUI:AddChatCommand('edit', function()
	CustomEditMode:Toggle()
end, 'Toggle custom EditMode')

if MoveIt.logger then
	MoveIt.logger.info('Custom EditMode system loaded')
end
