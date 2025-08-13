---@class SUI
local SUI = SUI
local L = SUI.L
local MoveIt = SUI.MoveIt
local module = SUI:NewModule('Minimap') ---@class SUI.Module.Minimap : SUI.Module
module.description = 'CORE: Skins, sizes, and positions the Minimap'
module.Core = true
----------------------------------------------------------------------------------------------------
module.Settings = nil ---@type SUI.Style.Settings.Minimap
module.styleOverride = nil ---@type string|nil
local Registry = {}
local MinimapUpdater = CreateFrame('Frame')

-- Create a secure vehicle UI watcher frame similar to oUF's PetBattleFrameHider
local VehicleUIWatcher = CreateFrame('Frame', 'SUI_Minimap_VehicleUIWatcher', UIParent, 'SecureHandlerStateTemplate')
VehicleUIWatcher:SetAllPoints()
VehicleUIWatcher:SetFrameStrata('LOW')
-- Register state driver to detect when vehicle UI is active (not just any vehicle)
RegisterStateDriver(VehicleUIWatcher, 'visibility', '[possessbar][overridebar][vehicleui] hide; show')

---@class SUI.Minimap.Holder : FrameExpanded, SUI.MoveIt.MoverParent
local SUIMinimap = CreateFrame('Frame', 'SUI_Minimap')

---@class SUI.Style.Settings.IMinimap : SUI.Style.Settings.Minimap
local BaseSettings = {
	-- Top-level settings
	shape = 'circle',
	size = { 180, 180 },
	scaleWithArt = true,
	UnderVehicleUI = true,
	useVehicleMover = true,
	position = 'TOPRIGHT,UIParent,TOPRIGHT,-20,-20',
	vehiclePosition = 'TOPRIGHT,UIParent,TOPRIGHT,-20,-20',
	rotate = false,

	-- Elements
	elements = {
		-- Background
		background = {
			enabled = true,
			texture = 'Interface\\AddOns\\SpartanUI\\images\\minimap\\round',
			size = { 220, 220 },
			color = { 1, 1, 1, 1 },
			BlendMode = 'ADD',
			alpha = 1,
		},

		-- Zone Text
		ZoneText = {
			enabled = true,
			scale = 1,
			position = 'TOPLEFT,BorderTop,TOPLEFT,4,-4',
			color = { 1, 0.82, 0, 1 },
		},

		-- Coordinates
		coords = {
			enabled = true,
			scale = 1,
			size = { 80, 12 },
			position = 'BOTTOM,BorderTop,BOTTOM,-5,3',
			color = { 1, 1, 1, 1 },
			format = '%.1f, %.1f',
		},

		-- Zoom Buttons
		zoomButtons = {
			enabled = false,
			scale = 1,
		},

		-- Clock
		clock = {
			enabled = true,
			position = 'BOTTOMRIGHT,BorderTop,BOTTOMRIGHT,-10,0',
			scale = 1,
			format = '%I:%M %p',
			color = { 1, 1, 1, 1 },
		},

		-- Tracking Icon
		tracking = {
			enabled = true,
			position = 'BOTTOMLEFT,BorderTop,BOTTOMLEFT,2,1',
			scale = 1,
		},

		-- Calendar Button
		calendarButton = {
			enabled = true,
			position = 'TOPRIGHT,BorderTop,TOPRIGHT,2,2',
			scale = 1,
		},

		-- Mail Icon
		mailIcon = {
			enabled = true,
			position = 'LEFT,Tracking,RIGHT,2,0',
			scale = 1,
		},

		-- Instance Difficulty
		instanceDifficulty = {
			enabled = true,
			position = 'RIGHT,BorderTop,LEFT,2,0',
			scale = 0.8,
		},

		-- Queue Status (LFG eye)
		queueStatus = {
			enabled = true,
			position = 'BOTTOMLEFT,Minimap,BOTTOMLEFT,-15,45',
			scale = 0.85,
		},

		--Expansion Button
		expansionButton = {
			position = 'BOTTOMLEFT,Minimap,BOTTOMLEFT,0,0',
			scale = 0.6,
		},

		-- Addon Buttons
		addonButtons = {
			style = 'mouseover', -- 'always', 'mouseover', or 'never'
		},
	},
}

local function IsMouseOver()
	for _, MouseFocus in ipairs(GetMouseFoci()) do
		if
			MouseFocus
			and not MouseFocus:IsForbidden()
			and ((MouseFocus:GetName() == 'Minimap') or (MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find('Mini[Mm]ap')))
		then
			return true
		end
	end

	return false
end

-- Check if Vehicle UI is actually active (not just in any vehicle)
local function IsVehicleUIActive()
	-- First check OverrideActionBar (most reliable)
	if OverrideActionBar and OverrideActionBar:IsVisible() then return true end

	-- Check if in vehicle AND has vehicle UI (excludes passengers, flight paths, etc)
	if UnitInVehicle('player') and UnitHasVehicleUI('player') then return true end

	-- Check possess bar (fallback for older content or edge cases)
	-- Note: PossessActionBar might not exist in all game versions
	if _G.PossessActionBar and _G.PossessActionBar:IsVisible() then return true end

	return false
end

-- Expose to module for options access
function module:IsVehicleUIActive()
	return IsVehicleUIActive()
end

-- Setup vehicle UI monitoring using the secure watcher frame
local function SetupVehicleUIMonitoring()
	-- Hook the watcher frame's visibility changes
	VehicleUIWatcher:HookScript('OnHide', function()
		-- Vehicle UI is now active (frame is hidden when vehicle UI shows)
		if module.Settings and module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then module:SwitchMinimapPosition(true) end
	end)

	VehicleUIWatcher:HookScript('OnShow', function()
		-- Vehicle UI is no longer active (frame is shown when vehicle UI hides)
		if module.Settings and module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then module:SwitchMinimapPosition(false) end
	end)
end

function module:Register(name, settings)
	Registry[name] = { settings = settings }
end

function module:UpdateSettings()
	module.Settings = nil
	-- Start with base settings
	---@type SUI.Style.Settings.IMinimap
	module.Settings = SUI:CopyData(BaseSettings, {})

	-- Apply theme settings if available
	local currentStyle = module.styleOverride or SUI.DB.Artwork.Style
	if Registry[currentStyle] then module.Settings = SUI:MergeData(module.Settings, Registry[currentStyle].settings, true) end

	module.BaseOpt = SUI:CopyTable({}, module.Settings)
	-- Apply user custom settings
	if module.DB.customSettings[currentStyle] then SUI:MergeData(module.Settings, module.DB.customSettings[currentStyle], true) end
end

function module:ModifyMinimapLayout()
	module:UpdateMinimapSize()
	module:UpdateMinimapShape()

	-- Modify basic Minimap properties
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetQuestBlobRingScalar(0)

	-- Modify MinimapCluster
	MinimapCluster:EnableMouse(false)

	-- Modify MinimapBackdrop
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetPoint('CENTER', Minimap, 'CENTER', -10, -24)
	MinimapBackdrop:SetFrameLevel(Minimap:GetFrameLevel())

	MinimapCompassTexture:Hide()

	MinimapCluster.BorderTop:ClearAllPoints()
	MinimapCluster.BorderTop:SetPoint('TOP', Minimap, 'BOTTOM', 0, -5)
	MinimapCluster.BorderTop:SetAlpha(0.8)

	MinimapCluster.ZoneTextButton:ClearAllPoints()
	MinimapCluster.ZoneTextButton:SetPoint('TOPLEFT', MinimapCluster.BorderTop, 'TOPLEFT', 4, -4)
	MinimapCluster.ZoneTextButton:SetPoint('TOPRIGHT', MinimapCluster.BorderTop, 'TOPRIGHT', -15, -4)

	-- Setup rotation if needed
	if MinimapCluster.SetRotateMinimap then
		if module.Settings.rotate then C_CVar.SetCVar('rotateMinimap', 1) end
	end
end

function module:UpdateMinimapSize()
	-- Set size of Minimap
	if module.Settings.size then Minimap:SetSize(unpack(module.Settings.size)) end

	-- Set size of SUIMinimap (our holder)
	SUIMinimap:SetSize(Minimap:GetWidth(), (Minimap:GetHeight() + MinimapCluster.BorderTop:GetHeight() + 15))

	-- Set size of MinimapCluster BorderTop
	MinimapCluster.BorderTop:SetWidth(Minimap:GetWidth() / 1.1)
	MinimapCluster.BorderTop:SetHeight(MinimapCluster.ZoneTextButton:GetHeight() * 2.8)
end

function module:UpdateMinimapShape()
	-- Set Minimap shape
	Minimap:SetMaskTexture(module.Settings.shape == 'square' and 'Interface\\BUTTONS\\WHITE8X8' or 'Interface\\AddOns\\SpartanUI\\images\\minimap\\circle-overlay')

	-- Setup Minimap overlay
	if not Minimap.overlay then
		Minimap.overlay = Minimap:CreateTexture(nil, 'OVERLAY')
		Minimap.overlay:SetTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\square-overlay')
		Minimap.overlay:SetAllPoints(Minimap)
		Minimap.overlay:SetBlendMode('ADD')
	end
	Minimap.overlay:SetShown(module.Settings.shape == 'square')

	-- Setup GetMinimapShape function
	function GetMinimapShape()
		return module.Settings.shape == 'square' and 'SQUARE' or 'ROUND'
	end
end

function module:SetupElements()
	-- Modify the basic Minimap layout
	module:ModifyMinimapLayout()

	-- Setup background
	module:SetupBackground()

	-- Setup Zone Text
	module:SetupZoneText()

	-- Setup Coordinates
	module:SetupCoords()

	-- Setup Clock
	module:SetupClock()

	-- Setup Tracking Icon
	module:SetupTracking()

	-- Setup Calendar Button
	module:SetupCalendarButton()

	-- Setup Instance Difficulty
	module:SetupInstanceDifficulty()

	-- Setup Queue Status (LFG eye)
	module:SetupQueueStatus()

	-- Setup Mail Icon
	module:SetupMailIcon()

	-- Setup North Indicator
	module:SetupExpansionButton()

	-- Setup addon buttons
	module:SetupAddonButtons()

	-- Setup addon buttons
	module:SetupZoomButtons()
end

function module:PositionItem(obj, position)
	if type(position) == 'table' then
		local name = obj:GetName()
		if name then SUI:Error('Minimap', 'Position for ' .. name .. ' is bad. Please report this error along with an export of your minimap settings.') end
		return
	end
	local point, anchor, secondaryPoint, x, y = strsplit(',', position)
	if MinimapCluster[anchor] then anchor = MinimapCluster[anchor] end

	obj:ClearAllPoints()
	obj:SetPoint(point, anchor, secondaryPoint, x, y)
end

function module:SetupBackground()
	if module.Settings.elements.background.enabled then
		if not SUIMinimap.BG then SUIMinimap.BG = SUIMinimap:CreateTexture(nil, 'BACKGROUND', nil, -8) end

		SUIMinimap.BG:SetTexture(module.Settings.elements.background.texture)
		SUIMinimap.BG:SetSize(unpack(module.Settings.elements.background.size))
		if module.Settings.elements.background.position then
			module:PositionItem(SUIMinimap.BG, module.Settings.elements.background.position)
		else
			SUIMinimap.BG:ClearAllPoints()
			SUIMinimap.BG:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -30, 30)
			SUIMinimap.BG:SetPoint('BOTTOMRIGHT', Minimap, 'BOTTOMRIGHT', 30, -30)
		end

		SUIMinimap.BG:SetVertexColor(unpack(module.Settings.elements.background.color))
		SUIMinimap.BG:SetBlendMode(module.Settings.elements.background.BlendMode)
		SUIMinimap.BG:SetAlpha(module.Settings.elements.background.alpha)
		SUIMinimap.BG:Show()
	elseif SUIMinimap.BG then
		SUIMinimap.BG:Hide()
	end
end

function module:SetupZoomButtons()
	if not Minimap.ZoomIn then return end

	DISABLE_MAP_ZOOM = not module.Settings.elements.zoomButtons.enabled
	if module.Settings.elements.zoomButtons.enabled then
		Minimap.ZoomIn:Show()
		Minimap.ZoomOut:Show()
		Minimap.ZoomIn:SetScale(module.Settings.elements.zoomButtons.scale)
		Minimap.ZoomOut:SetScale(module.Settings.elements.zoomButtons.scale)
	else
		Minimap.ZoomIn:Hide()
		Minimap.ZoomOut:Hide()
	end
end

function module:SetupZoneText()
	---@diagnostic disable-next-line: undefined-field
	if not MinimapCluster.ZoneTextButton then return end

	if module.Settings.elements.ZoneText.enabled then
		module:PositionItem(MinimapCluster.ZoneTextButton, module.Settings.elements.ZoneText.position)
		MinimapZoneText:SetTextColor(unpack(module.Settings.elements.ZoneText.color))
		MinimapZoneText:SetShadowColor(0, 0, 0, 1)
		MinimapCluster.ZoneTextButton:SetScale(module.Settings.elements.ZoneText.scale)
		MinimapCluster.ZoneTextButton:Show()
		SUI.Font:Format(MinimapZoneText, 10, 'Minimap')
		MinimapZoneText:SetJustifyH('CENTER')
	elseif MinimapCluster.ZoneTextButton then
		MinimapCluster.ZoneTextButton:Hide()
	end
end

function module:SetupCoords()
	if module.Settings.elements.coords.enabled then
		if not Minimap.coords then Minimap.coords = Minimap:CreateFontString(nil, 'OVERLAY') end
		SUI.Font:Format(Minimap.coords, 10, 'Minimap')
		module:PositionItem(Minimap.coords, module.Settings.elements.coords.position)
		Minimap.coords:SetTextColor(unpack(module.Settings.elements.coords.color))
		Minimap.coords:SetShadowColor(0, 0, 0, 1)
		Minimap.coords:SetScale(module.Settings.elements.coords.scale)
		Minimap.coords:SetSize(unpack(module.Settings.elements.coords.size))
		Minimap.coords:SetJustifyH('CENTER')
		Minimap.coords:Show()
		module:SetupCoordinatesUpdater()
	elseif Minimap.coords then
		Minimap.coords:Hide()
	end
end

function module:SetupCoordinatesUpdater()
	if self.coordsTimer then return end

	self.coordsTimer = self:ScheduleRepeatingTimer(function()
		local mapID = C_Map.GetBestMapForUnit('player')
		if not mapID then return end
		local pos = C_Map.GetPlayerMapPosition(mapID, 'player')
		if not pos then return end
		if pos.x and pos.y then Minimap.coords:SetText(string.format(module.Settings.elements.coords.format, pos.x * 100, pos.y * 100)) end
	end, 0.5)
end

function module:SetupClock()
	if module.Settings.elements.clock.enabled then
		if not TimeManagerClockButton then C_AddOns.LoadAddOn('Blizzard_TimeManager') end
		TimeManagerClockButton:ClearAllPoints()
		module:PositionItem(TimeManagerClockButton, module.Settings.elements.clock.position)
		TimeManagerClockButton:SetScale(module.Settings.elements.clock.scale)
		TimeManagerClockTicker:SetTextColor(unpack(module.Settings.elements.clock.color))
		SUI.Font:Format(TimeManagerClockTicker, 10, 'Minimap')
		TimeManagerClockButton:Show()
	elseif TimeManagerClockButton then
		TimeManagerClockButton:Hide()
	end
end

function module:SetupMailIcon()
	if module.Settings.elements.mailIcon.enabled then
		if MinimapCluster.IndicatorFrame.MailFrame then
			MinimapCluster.IndicatorFrame.MailFrame:ClearAllPoints()
			module:PositionItem(MinimapCluster.IndicatorFrame.MailFrame, module.Settings.elements.mailIcon.position)
			MinimapCluster.IndicatorFrame.MailFrame:SetScale(module.Settings.elements.mailIcon.scale)
		end
	end
end

function module:SetupTracking()
	if module.Settings.elements.tracking.enabled then
		local Tracking = MinimapCluster.TrackingFrame or MinimapCluster.Tracking
		Tracking:ClearAllPoints()
		module:PositionItem(Tracking, module.Settings.elements.tracking.position)
		Tracking:SetScale(module.Settings.elements.tracking.scale)
		Tracking.Background:Hide()
		Tracking:Show()
	elseif MinimapCluster.TrackingFrame then
		MinimapCluster.TrackingFrame:Hide()
	elseif MinimapCluster.Tracking then
		MinimapCluster.Tracking:Hide()
	end
end

function module:SetupCalendarButton()
	if module.Settings.elements.calendarButton.enabled and GameTimeFrame then
		GameTimeFrame:ClearAllPoints()
		module:PositionItem(GameTimeFrame, module.Settings.elements.calendarButton.position)
		GameTimeFrame:SetScale(module.Settings.elements.calendarButton.scale)
		GameTimeFrame:Show()
	elseif GameTimeFrame then
		GameTimeFrame:Hide()
	end
end

function module:SetupInstanceDifficulty()
	if module.Settings.elements.instanceDifficulty.enabled then
		MinimapCluster.InstanceDifficulty:ClearAllPoints()
		module:PositionItem(MinimapCluster.InstanceDifficulty, module.Settings.elements.instanceDifficulty.position)
		MinimapCluster.InstanceDifficulty:SetScale(module.Settings.elements.instanceDifficulty.scale)
		MinimapCluster.InstanceDifficulty:Show()
	else
		MinimapCluster.InstanceDifficulty:Hide()
	end
end

function module:SetupQueueStatus()
	if module.Settings.elements.queueStatus.enabled then
		QueueStatusButton:ClearAllPoints()
		module:PositionItem(QueueStatusButton, module.Settings.elements.queueStatus.position)
		QueueStatusButton:SetScale(module.Settings.elements.queueStatus.scale)
	end
end

function module:SetupExpansionButton()
	if not ExpansionLandingPageMinimapButton then return end

	ExpansionLandingPageMinimapButton:SetScale(module.Settings.elements.expansionButton.scale)
	module:PositionItem(ExpansionLandingPageMinimapButton, module.Settings.elements.expansionButton.position)
	-- Note: Right-click functionality is now handled by the ExpandedExpansionButton module
	-- This keeps the default left-click behavior intact
end

local isFrameIgnored = function(item)
	local ignored = { 'HybridMinimap', 'AAP-Classic', 'HandyNotes' }
	local WildcardIgnore = { 'Questie', 'HandyNotes', 'TTMinimap' }
	if not item or not item.GetName then return false end

	local name = item:GetName()
	if name ~= nil then
		if SUI:IsInTable(ignored, name) then return true end

		for _, v in ipairs(WildcardIgnore) do
			if string.match(name, v) then return true end
		end
	end
	return false
end

function module:SetupAddonButtons()
	local function setupButtonFading(button)
		local name = button:GetName()
		if isFrameIgnored(name) then print('ignore me!' .. name) end
		if button.fadeInAnim then return end -- Already set up

		button.fadeInAnim = button:CreateAnimationGroup()
		local fadeIn = button.fadeInAnim:CreateAnimation('Alpha')
		fadeIn:SetFromAlpha(0)
		fadeIn:SetToAlpha(1)
		fadeIn:SetDuration(0.2)
		button.fadeInAnim:SetToFinalAlpha(true)

		button.fadeOutAnim = button:CreateAnimationGroup()
		local fadeOut = button.fadeOutAnim:CreateAnimation('Alpha')
		fadeOut:SetFromAlpha(1)
		fadeOut:SetToAlpha(0)
		fadeOut:SetDuration(0.3)
		fadeOut:SetStartDelay(0.5)
		button.fadeOutAnim:SetToFinalAlpha(true)

		-- Initially hide the button
		button:SetAlpha(0)
	end

	local function showAllButtons()
		for _, child in ipairs({ Minimap:GetChildren() }) do
			if child:IsObjectType('Button') and child.fadeInAnim then
				child.fadeInAnim:Stop()
				child.fadeOutAnim:Stop()
				child:SetAlpha(1)
			end
		end
	end

	local function hideAllButtons()
		for _, child in ipairs({ Minimap:GetChildren() }) do
			if child:IsObjectType('Button') and child.fadeOutAnim then
				child.fadeInAnim:Stop()
				child.fadeOutAnim:Play()
			end
		end
	end

	-- Set up fading for existing buttons
	for _, child in ipairs({ Minimap:GetChildren() }) do
		if child:IsObjectType('Button') then
			setupButtonFading(child)
			child:HookScript('OnEnter', showAllButtons)
			child:HookScript('OnLeave', hideAllButtons)
		end
	end

	-- Hook the Minimap to catch newly added buttons
	Minimap:HookScript('OnEvent', function(self, event, ...)
		if event == 'ADDON_LOADED' then
			C_Timer.After(0.1, function()
				for _, child in ipairs({ self:GetChildren() }) do
					if child:IsObjectType('Button') and not child.fadeInAnim and not isFrameIgnored(child) then
						setupButtonFading(child)
						child:HookScript('OnEnter', showAllButtons)
						child:HookScript('OnLeave', hideAllButtons)
					end
				end
			end)
		end
	end)
	Minimap:RegisterEvent('ADDON_LOADED')

	-- Hook the Minimap itself for mouse events
	Minimap:HookScript('OnEnter', showAllButtons)
	Minimap:HookScript('OnLeave', hideAllButtons)
end

function module:UpdateAddonButtons()
	local style = module.Settings.elements.addonButtons.style
	if style == 'always' then
		for _, child in ipairs({ Minimap:GetChildren() }) do
			if child:IsObjectType('Button') and not isFrameIgnored(child) then child:SetAlpha(1) end
		end
	elseif style == 'never' then
		for _, child in ipairs({ Minimap:GetChildren() }) do
			if child:IsObjectType('Button') and not isFrameIgnored(child) then child:SetAlpha(0) end
		end
	else -- "mouseover"
		for _, child in ipairs({ Minimap:GetChildren() }) do
			if child:IsObjectType('Button') and not isFrameIgnored(child) then
				child:SetAlpha(0) -- Start hidden
			end
		end
		-- The showing/hiding is handled by the OnEnter/OnLeave scripts
	end
end

function module:CreateMover()
	-- Ensure SUIMinimap has a size before creating the mover
	if SUIMinimap:GetWidth() == 0 or SUIMinimap:GetHeight() == 0 then
		SUI:Error('Minimap', 'SUIMinimap has no size. Mover creation aborted.')
		return
	end

	MoveIt:CreateMover(SUIMinimap, 'Minimap')
end

function module:SwitchMinimapPosition(inVehicle)
	if inVehicle then
		SUIMinimap:ClearAllPoints()
		SUIMinimap:SetPoint('TOPLEFT', SUI_CustomMover_VehicleMinimapPosition)
	else
		SUIMinimap:ClearAllPoints()
		SUIMinimap:SetPoint('TOPLEFT', SUI_Mover_Minimap)
	end
end

function module:SetupHooks()
	Minimap:HookScript('OnShow', function()
		SUIMinimap:Show()
	end)
	Minimap:HookScript('OnHide', function()
		SUIMinimap:Hide()
	end)

	SUIMinimap:HookScript('OnEnter', function()
		IsMouseOver()
	end)
	SUIMinimap:HookScript('OnLeave', function()
		IsMouseOver()
	end)
end

function module:RegisterEvents()
	MinimapUpdater:SetScript('OnEvent', function()
		if not InCombatLockdown() then module:ScheduleTimer(module.Update, 2, module, true) end
	end)
	MinimapUpdater:RegisterEvent('ADDON_LOADED')
	MinimapUpdater:RegisterEvent('ZONE_CHANGED')
	MinimapUpdater:RegisterEvent('ZONE_CHANGED_INDOORS')
	MinimapUpdater:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	MinimapUpdater:RegisterEvent('MINIMAP_UPDATE_TRACKING')
	MinimapUpdater:RegisterEvent('MINIMAP_PING')
	MinimapUpdater:RegisterEvent('PLAYER_REGEN_ENABLED')

	module:ScheduleRepeatingTimer(module.Update, 30, module, true)
end

function module:Update(fullUpdate)
	if SUI:IsModuleDisabled('Minimap') then return end

	module:UpdateSettings()

	-- Apply settings to elements
	module:SetupBackground()
	module:SetupZoneText()
	module:SetupCoords()
	module:SetupClock()
	module:SetupMailIcon()
	module:SetupTracking()
	module:SetupCalendarButton()
	module:SetupInstanceDifficulty()
	module:SetupQueueStatus()
	module:SetupExpansionButton()
	module:UpdateAddonButtons()
	module:UpdateMinimapShape()
	module:UpdateMinimapSize()

	-- Setup vehicle UI monitoring if conditions are met
	if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false and SUI.DB.Artwork.VehicleUI and (not MoveIt:IsMoved('Minimap')) then
		-- Initialize vehicle UI monitoring if not already done
		if not VehicleUIWatcher.monitoringSetup then
			SetupVehicleUIMonitoring()
			VehicleUIWatcher.monitoringSetup = true
		end

		-- Check current state and apply immediately if needed
		if not VehicleUIWatcher:IsVisible() then
			-- VehicleUIWatcher is hidden, meaning vehicle UI is active
			module:SwitchMinimapPosition(true)
		else
			-- VehicleUIWatcher is visible, meaning vehicle UI is not active
			module:SwitchMinimapPosition(false)
		end
	end

	if fullUpdate then
		module:UpdatePosition()
		module:UpdateScale()
	end
end

function module:SetActiveStyle(style)
	if Registry[style] then
		module.styleOverride = style

		module:UpdateSettings()
		module:Update(true)
	end
end

function module:UpdatePosition()
	if module.Settings.position and not MoveIt:IsMoved('Minimap') then
		local point, anchor, secondaryPoint, x, y = strsplit(',', module.Settings.position)
		if SUIMinimap.position then
			SUIMinimap:position(point, anchor, secondaryPoint, x, y, false, true)
		else
			SUIMinimap:ClearAllPoints()
			SUIMinimap:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	end

	-- Update MinimapCluster position relative to SUIMinimap
	MinimapCluster.MinimapContainer:ClearAllPoints()
	MinimapCluster.MinimapContainer:SetPoint('TOPLEFT', SUIMinimap, 'TOPLEFT', -30, 32)
	SUIMinimap.Registry = Registry
end

function module:UpdateScale()
	if module.Settings.scaleWithArt and SUI:IsAddonDisabled('SexyMap') then
		local scale = max(SUI.DB.scale, 0.01)
		if SUIMinimap.scale then
			SUIMinimap:scale(scale)
			MinimapCluster:SetScale(scale)
		else
			SUIMinimap:SetScale(scale)
			MinimapCluster:SetScale(scale)
		end
	end
end

-- Create a vehicle UI mover frame
local VehicleMover

-- Initialize the vehicle mover
function module:InitializeVehicleMover()
	-- Create the vehicle mover with our new reusable function
	VehicleMover = SUI.MoveIt:CreateCustomMover('Vehicle Minimap Position', module.Settings.vehiclePosition, {
		width = Minimap:GetWidth(),
		height = (Minimap:GetHeight() + MinimapCluster.BorderTop:GetHeight() + 15),
		savePosition = function(position)
			module.Settings.vehiclePosition = position

			-- Save to user settings
			local currentStyle = SUI.DB.Artwork.Style
			if not module.DB.customSettings[currentStyle] then module.DB.customSettings[currentStyle] = {} end
			module.DB.customSettings[currentStyle].vehiclePosition = position
		end,
	})

	VehicleMover.target = SUIMinimap

	-- Register for vehicle events
	module:RegisterEvent('UNIT_ENTERED_VEHICLE', 'OnVehicleChange')
	module:RegisterEvent('UNIT_EXITED_VEHICLE', 'OnVehicleChange')
	module:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckVehicleStatus')
	-- OnZone change
	module:RegisterEvent('ZONE_CHANGED_NEW_AREA', function()
		module:ScheduleTimer(module.CheckOverrideActionBar, 0.2)
	end)

	-- Check if OverrideActionBar exists and is visible
	module:RegisterEvent('UPDATE_OVERRIDE_ACTIONBAR', 'CheckOverrideActionBar')
end

-- Show the vehicle minimap mover
function module:VehicleUIMoverShow()
	if InCombatLockdown() then return end

	VehicleMover:Show()

	-- Show a notification to the user
	SUI:Print(L["You can now position the minimap for when you're in a vehicle. Right-click to reset."])
end

-- Hide the vehicle minimap mover
function module:VehicleUIMoverHide()
	VehicleMover:Hide()
end

-- Reset vehicle position to default
function module:ResetVehiclePosition()
	local point, anchor, secondaryPoint, x, y = strsplit(',', module.BaseOpt.vehiclePosition)
	VehicleMover:ClearAllPoints()
	VehicleMover:SetPoint(point, _G[anchor], secondaryPoint, x, y)

	module.Settings.vehiclePosition = module.BaseOpt.vehiclePosition
	local currentStyle = SUI.DB.Artwork.Style
	if module.DB.customSettings[currentStyle] then module.DB.customSettings[currentStyle].vehiclePosition = nil end

	SUI:Print(L['Vehicle minimap position reset to default'])
end

-- Handle vehicle state changes
function module:OnVehicleChange(event, unit)
	if unit ~= 'player' then return end

	if event == 'UNIT_ENTERED_VEHICLE' then
		-- if not firstVehicleDetected and module.Settings.UnderVehicleUI then
		-- 	firstVehicleDetected = true

		-- 	-- Ask the user if they want to set the vehicle position
		-- 	StaticPopupDialogs['SUI_MINIMAP_VEHICLE_POSITION'] = {
		-- 		text = L['Would you like to set a custom position for your minimap when in a vehicle?'],
		-- 		button1 = L['Yes'],
		-- 		button2 = L['No'],
		-- 		OnAccept = function()
		-- 			module:VehicleUIMoverShow()
		-- 		end,
		-- 		timeout = 0,
		-- 		whileDead = true,
		-- 		hideOnEscape = true,
		-- 		preferredIndex = 3,
		-- 	}

		-- 	StaticPopup_Show('SUI_MINIMAP_VEHICLE_POSITION')
		-- end

		-- Apply the vehicle position
		if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then module:SwitchMinimapPosition(true) end
	elseif event == 'UNIT_EXITED_VEHICLE' then
		-- Restore normal position
		if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then module:SwitchMinimapPosition(false) end
	end
end

-- Check vehicle status on login or reload
function module:CheckVehicleStatus()
	if not (module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false) then return end

	if IsVehicleUIActive() then
		module:SwitchMinimapPosition(true)
	else
		module:SwitchMinimapPosition(false)
	end
end

-- Check for OverrideActionBar visibility changes
function module:CheckOverrideActionBar()
	C_Timer.After(0.5, function()
		if IsVehicleUIActive() then
			if not module.Settings.firstVehicleDetected and module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then
				module.Settings.firstVehicleDetected = true
				module.DB.customSettings[SUI.DB.Artwork.Style].firstVehicleDetected = true

				StaticPopupDialogs['SUI_MINIMAP_VEHICLE_POSITION'] = {
					text = L['Would you like to set a custom position for your minimap when in a vehicle?'],
					button1 = L['Yes'],
					button2 = L['No'],
					OnAccept = function()
						module:VehicleUIMoverShow()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}

				StaticPopup_Show('SUI_MINIMAP_VEHICLE_POSITION')
			end

			if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then module:SwitchMinimapPosition(true) end
		else
			if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then module:SwitchMinimapPosition(false) end
		end
	end)
end

function module:OnInitialize()
	---@class SUI.Minimap.Database
	local defaults = {
		enabled = true,
		style = 'Default',
		customSettings = {
			['**'] = {
				['**'] = {
					['**'] = {},
				},
			},
		},
		AutoDetectAllowUse = true,
		ManualAllowUse = false,
	}

	module.Database = SUI.SpartanUIDB:RegisterNamespace('Minimap', { profile = defaults })
	module.DB = module.Database.profile ---@type SUI.Minimap.Database

	-- Initialize the settings
	module:UpdateSettings()

	-- Check for other addons modifying the minimap
	module:DetectMinimapAddons()

	if C_CVar.GetCVar('rotateMinimap') == '1' and not module.DB.customSettings[SUI.DB.Artwork.Style].rotate then module.DB.customSettings[SUI.DB.Artwork.Style].rotate = true end
end

function module:DetectMinimapAddons()
	local conflictingAddons = {
		['SexyMap'] = 'SexyMap',
		['Carbonite'] = NXTITLELOW,
		-- Add other known conflicting addons here
	}

	for addonName, addonTitle in pairs(conflictingAddons) do
		if SUI:IsAddonEnabled(addonName) then
			if addonName == 'Carbonite' then
				SUI:Print(addonTitle .. ' is loaded ...Checking settings ...')
				if Nx and Nx.db and Nx.db.profile and Nx.db.profile.MiniMap and Nx.db.profile.MiniMap.Own == true then
					SUI:Print(addonTitle .. ' is controlling the Minimap')
					SUI:Print('SpartanUI Will not modify or move the minimap unless Carbonite is a separate minimap')
					module.DB.AutoDetectAllowUse = false
				end
			else
				module.DB.AutoDetectAllowUse = false
				SUI:Print(addonTitle .. ' detected. SpartanUI will not modify the minimap.')
			end
		end
	end

	if not module.DB.AutoDetectAllowUse and not module.DB.ManualAllowUse then StaticPopup_Show('MiniMapNotice') end
end

function module:OnEnable()
	if SUI:IsModuleDisabled('Minimap') then return end

	-- Set up the SUIMinimap frame
	SUIMinimap:SetFrameStrata('BACKGROUND')
	SUIMinimap:SetFrameLevel(99)
	SUIMinimap:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 0)

	module:UpdateSettings()
	module:SetupElements()
	module:CreateMover()
	module:SetupHooks()
	module:RegisterEvents()

	-- Initialize Buttons & Style settings
	module:Update(true)

	module:InitializeVehicleMover()

	SUI:AddChatCommand('vehicleminimap', function()
		if VehicleMover:IsShown() then
			module:VehicleUIMoverHide()
		else
			module:VehicleUIMoverShow()
		end
	end, L['Toggle vehicle minimap mover'])

	-- Setup Options
	module:BuildOptions()
end

StaticPopupDialogs['MiniMapNotice'] = {
	text = '|cff33ff99SpartanUI Notice|n|r|n Another addon has been found modifying the minimap. Do you give permission for SpartanUI to move and possibly modify the minimap as your theme dictates? |n|n You can change this option in the settings should you change your mind.',
	button1 = 'Yes',
	button2 = 'No',
	OnAccept = function()
		module.DB.ManualAllowUse = true
		module:Enable()
	end,
	OnCancel = function()
		module.DB.ManualAllowUse = false
		SUI:DisableModule(module)
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
}

SUI.Minimap = module
