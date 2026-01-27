---@class SUI
local SUI = SUI
local MoveIt = SUI.MoveIt

---@class SUI.MoveIt.BlizzardEditMode
local BlizzardEditMode = {}
MoveIt.BlizzardEditMode = BlizzardEditMode

-- Frames that have native EditMode support (from https://warcraft.wiki.gg/wiki/Edit_Mode)
-- We'll use LibEditModeOverride to add our settings to them
local NATIVE_EDITMODE_FRAMES = {
	-- Action Bars
	ActionBar = { systemID = 1 }, -- Enum.EditModeSystem.ActionBar
	-- Unit Frames (we replace these with oUF, but need to hook checkboxes)
	CastBar = { systemID = 2 },
	PlayerFrame = { systemID = 3 },
	TargetFrame = { systemID = 4 },
	FocusFrame = { systemID = 5 },
	PartyFrame = { systemID = 6 },
	RaidFrame = { systemID = 7 },
	BossFrame = { systemID = 8 },
	ArenaFrame = { systemID = 9 },
	-- UI Elements
	EncounterBar = { systemID = 10 },
	ExtraAbilities = { systemID = 11 }, -- ExtraActionButton, ZoneAbility
	AuraFrame = { systemID = 12 },
	TalkingHeadFrame = { systemID = 13 },
	VehicleLeaveButton = { systemID = 14 },
	HudTooltip = { systemID = 15 },
	ObjectiveTracker = { systemID = 16 },
	MicroMenu = { systemID = 17 },
	Bags = { systemID = 18 },
	StatusTrackingBar = { systemID = 19 }, -- XP/Rep/Honor bars
	Minimap = { systemID = 20 },
	-- Containers
	ArchaeologyBar = { systemID = 21 },
	QuestTimerFrame = { systemID = 22 },
	-- Note: Some frames were added in different patches
}

-- Frames that DON'T have EditMode support
-- These need custom movers
local NON_EDITMODE_FRAMES = {
	FramerateFrame = true,
	AlertFrame = true, -- GroupLootContainer and AlertFrame holder
	TopCenterContainer = true, -- UIWidgetTopCenterContainerFrame
	WidgetPowerBarContainer = true, -- UIWidgetPowerBarContainerFrame
	VehicleSeatIndicator = true, -- Has EditMode but not well supported
}

---Initialize Blizzard EditMode integration
function BlizzardEditMode:Initialize()
	-- Check if we're on Retail (EditMode only exists in Retail)
	if not EditModeManagerFrame then
		if MoveIt.logger then
			MoveIt.logger.info('EditMode not available (Classic/TBC/Wrath) - using custom movers for all Blizzard frames')
		end
		return
	end

	-- Check if LibEditModeOverride is available
	local LibEMO = LibStub and LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		if MoveIt.logger then
			MoveIt.logger.warning('LibEditModeOverride not found - falling back to custom movers for Blizzard frames')
		end
		return
	end

	if MoveIt.logger then
		MoveIt.logger.info('Initializing Blizzard EditMode integration with LibEditModeOverride')
	end

	-- Wait for EditMode to be ready
	if LibEMO:IsReady() then
		self:SetupBlizzardFrames(LibEMO)
		self:StartLayoutMonitoring()
	else
		-- Hook into ready event
		local frame = CreateFrame('Frame')
		frame:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED')
		frame:SetScript('OnEvent', function(self, event)
			if LibEMO:IsReady() then
				BlizzardEditMode:SetupBlizzardFrames(LibEMO)
				BlizzardEditMode:StartLayoutMonitoring()
				self:UnregisterAllEvents()
			end
		end)
	end
end

---Create or ensure the SpartanUI EditMode profile exists
---@param LibEMO table LibEditModeOverride instance
---@return boolean success True if profile is ready
function BlizzardEditMode:CreateSpartanUIProfile(LibEMO)
	local profileName = 'SpartanUI'

	-- Check if profile already exists
	if LibEMO:DoesLayoutExist(profileName) then
		if MoveIt.logger then
			MoveIt.logger.debug(('EditMode profile "%s" already exists'):format(profileName))
		end
		return true
	end

	-- Create character-level profile
	if MoveIt.logger then
		MoveIt.logger.info(('Creating EditMode profile "%s"'):format(profileName))
	end

	local success = pcall(function()
		LibEMO:AddLayout(Enum.EditModeLayoutType.Character, profileName)
		LibEMO:SetActiveLayout(profileName)
	end)

	if success then
		self:SafeApplyChanges()
	end

	if success then
		if MoveIt.logger then
			MoveIt.logger.info(('Successfully created EditMode profile "%s"'):format(profileName))
		end
		return true
	else
		if MoveIt.logger then
			MoveIt.logger.error(('Failed to create EditMode profile "%s"'):format(profileName))
		end
		return false
	end
end

---Ensure the SpartanUI profile is ready for use
---@param LibEMO table LibEditModeOverride instance
---@return boolean ready True if profile is ready
function BlizzardEditMode:EnsureProfileReady(LibEMO)
	if not LibEMO then
		return false
	end

	-- Check if EditMode is ready
	if not LibEMO:IsReady() then
		if MoveIt.logger then
			MoveIt.logger.warning('EnsureProfileReady: EditMode not ready yet')
		end
		return false
	end

	-- Load layouts first (required before any other LibEMO calls)
	if not LibEMO:AreLayoutsLoaded() then
		LibEMO:LoadLayouts()
	end

	-- Check current active layout
	local currentLayout = LibEMO:GetActiveLayout()

	-- If user is on a different profile, DO NOT switch them or modify that profile
	if currentLayout and currentLayout ~= 'SpartanUI' then
		if MoveIt.logger then
			MoveIt.logger.warning(('EnsureProfileReady: User is on "%s" profile - not switching to SpartanUI'):format(currentLayout))
		end
		return false
	end

	-- Create profile if it doesn't exist
	if not self:CreateSpartanUIProfile(LibEMO) then
		return false
	end

	-- Set as active if not already (only if no profile is active or we're creating it)
	if not currentLayout or currentLayout ~= 'SpartanUI' then
		if MoveIt.logger then
			MoveIt.logger.info(('Activating SpartanUI EditMode profile (was: %s)'):format(tostring(currentLayout)))
		end
		local success = pcall(function()
			LibEMO:SetActiveLayout('SpartanUI')
		end)
		if success then
			self:SafeApplyChanges(true) -- Suppress movers during activation
		end
		if not success then
			if MoveIt.logger then
				MoveIt.logger.error('Failed to activate SpartanUI EditMode profile')
			end
			return false
		end
	end

	return true
end

---Setup Blizzard frames with EditMode integration
---@param LibEMO table LibEditModeOverride instance
function BlizzardEditMode:SetupBlizzardFrames(LibEMO)
	LibEMO:LoadLayouts()

	-- Store LibEMO reference for later use
	self.LibEMO = LibEMO

	-- Just ensure profile exists, but DON'T activate it yet
	-- We'll activate/apply when frames actually need positioning
	local profileName = 'SpartanUI'
	if not LibEMO:DoesLayoutExist(profileName) then
		if MoveIt.logger then
			MoveIt.logger.info(('Creating EditMode profile "%s" (will not activate until needed)'):format(profileName))
		end
		local success = pcall(function()
			LibEMO:AddLayout(Enum.EditModeLayoutType.Character, profileName)
		end)
		if not success then
			if MoveIt.logger then
				MoveIt.logger.error(('Failed to create EditMode profile "%s"'):format(profileName))
			end
		end
	end

	if MoveIt.logger then
		MoveIt.logger.info('Blizzard EditMode integration complete')
	end
end

---Start monitoring for EditMode layout changes
function BlizzardEditMode:StartLayoutMonitoring()
	if not EditModeManagerFrame then
		return
	end

	-- Create monitoring frame if it doesn't exist
	if not self.layoutMonitorFrame then
		self.layoutMonitorFrame = CreateFrame('Frame')
	end

	-- Register for layout updates
	self.layoutMonitorFrame:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED')
	self.layoutMonitorFrame:SetScript('OnEvent', function(frame, event)
		BlizzardEditMode:OnLayoutChanged()
	end)

	if MoveIt.logger then
		MoveIt.logger.debug('Started monitoring EditMode layout changes')
	end
end

---Handle EditMode layout changes
function BlizzardEditMode:OnLayoutChanged()
	local LibEMO = self.LibEMO or LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO or not LibEMO:AreLayoutsLoaded() then
		return
	end

	-- Reload layouts to get current state
	LibEMO:LoadLayouts()

	local currentLayout = LibEMO:GetActiveLayout()

	-- Warn if user switched away from SpartanUI profile
	if currentLayout ~= 'SpartanUI' then
		if MoveIt.logger then
			MoveIt.logger.warning(('EditMode profile changed to "%s" - SpartanUI BlizzMovers will not apply to this profile'):format(tostring(currentLayout)))
		end
	else
		if MoveIt.logger then
			MoveIt.logger.info('EditMode profile is "SpartanUI" - BlizzMovers active')
		end
	end
end

---Check if a frame should use native EditMode
---@param frameName string The frame name
---@return boolean useNative True if frame has native EditMode support
function BlizzardEditMode:ShouldUseNativeEditMode(frameName)
	if not EditModeManagerFrame then
		return false -- EditMode not available
	end

	return NATIVE_EDITMODE_FRAMES[frameName] ~= nil
end

---Parse SpartanUI position CSV string into components
---@param csvString string Position in format 'POINT,AnchorFrame,RelativePoint,X,Y'
---@return string|nil point
---@return string|nil anchor
---@return string|nil relativePoint
---@return number|nil x
---@return number|nil y
function BlizzardEditMode:ParseSUIPosition(csvString)
	if not csvString or csvString == '' then
		if MoveIt.logger then
			MoveIt.logger.warning('ParseSUIPosition: Empty or nil position string')
		end
		return nil, nil, nil, nil, nil
	end

	local point, anchor, relativePoint, x, y = strsplit(',', csvString)

	if not point or not anchor or not relativePoint or not x or not y then
		if MoveIt.logger then
			MoveIt.logger.error(('ParseSUIPosition: Invalid format "%s" - expected POINT,Anchor,RelativePoint,X,Y'):format(csvString))
		end
		return nil, nil, nil, nil, nil
	end

	return point, anchor, relativePoint, tonumber(x), tonumber(y)
end

---Check if a frame has been moved from its default position by the user
---@param frame Frame The frame object
---@return boolean isCustomized True if user has moved the frame
function BlizzardEditMode:IsFramePositionCustomized(frame)
	if not frame or not frame.system then
		return false
	end

	-- Check Blizzard's EditMode data directly
	-- When a frame is moved, isInDefaultPosition is set to false
	if EditModeManagerFrame and EditModeManagerFrame.GetActiveLayoutInfo then
		local layoutInfo = EditModeManagerFrame:GetActiveLayoutInfo()
		if layoutInfo and layoutInfo.systems then
			for _, system in pairs(layoutInfo.systems) do
				if system.system == frame.system and system.systemIndex == frame.systemIndex then
					-- Check if isInDefaultPosition is explicitly false (user moved it)
					if system.isInDefaultPosition == false then
						if MoveIt.logger then
							MoveIt.logger.debug(('Frame system %d has been customized by user'):format(frame.system))
						end
						return true
					end
					return false
				end
			end
		end
	end

	return false
end

---Set frame position from database using LibEditModeOverride
---@param frameName string The frame identifier in BlizzMovers table
---@param frame Frame The actual frame object
---@return boolean success True if position was applied
function BlizzardEditMode:SetFramePositionFromDB(frameName, frame)
	if not frame then
		if MoveIt.logger then
			MoveIt.logger.warning(('SetFramePositionFromDB: Frame "%s" is nil'):format(frameName))
		end
		return false
	end

	local LibEMO = LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		return false
	end

	-- Check if user has already customized this frame's position
	if self:IsFramePositionCustomized(frame) then
		if MoveIt.logger then
			MoveIt.logger.info(('SetFramePositionFromDB: Skipping "%s" - user has customized position'):format(frameName))
		end
		return false
	end

	-- Get position from database
	local positionString = SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers[frameName]
	if not positionString then
		if MoveIt.logger then
			MoveIt.logger.warning(('SetFramePositionFromDB: No position found in DB for "%s"'):format(frameName))
		end
		return false
	end

	-- Parse position
	local point, anchorName, relativePoint, x, y = self:ParseSUIPosition(positionString)
	if not point then
		return false
	end

	-- Resolve anchor frame name to actual frame
	local anchorFrame = _G[anchorName] or UIParent
	if not anchorFrame then
		if MoveIt.logger then
			MoveIt.logger.warning(('SetFramePositionFromDB: Anchor frame "%s" not found, using UIParent'):format(anchorName))
		end
		anchorFrame = UIParent
	end

	-- Apply position via LibEditModeOverride
	local success = pcall(function()
		LibEMO:ReanchorFrame(frame, point, anchorFrame, relativePoint, x, y)
	end)

	if success then
		if MoveIt.logger then
			MoveIt.logger.debug(('SetFramePositionFromDB: Applied position for "%s": %s'):format(frameName, positionString))
		end
		return true
	else
		if MoveIt.logger then
			MoveIt.logger.error(('SetFramePositionFromDB: Failed to apply position for "%s"'):format(frameName))
		end
		return false
	end
end

---Apply all enabled BlizzMover positions via LibEditModeOverride
---@return number appliedCount Number of positions successfully applied
function BlizzardEditMode:ApplyAllBlizzMoverPositions()
	local LibEMO = LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		return 0
	end

	local appliedCount = 0

	-- Iterate through native EditMode frames
	for frameName, frameData in pairs(NATIVE_EDITMODE_FRAMES) do
		-- Check if this frame is enabled in BlizzMovers
		if SUI.DB.Artwork.BlizzMoverStates[frameName] and SUI.DB.Artwork.BlizzMoverStates[frameName].enabled then
			-- Get frame reference (special handling for some frames)
			local frame = _G[frameName]

			-- Try to get the frame and apply position
			if frame and self:SetFramePositionFromDB(frameName, frame) then
				appliedCount = appliedCount + 1
			end
		end
	end

	-- Apply all changes at once
	if appliedCount > 0 then
		if self:SafeApplyChanges() then
			if MoveIt.logger then
				MoveIt.logger.info(('Applied %d BlizzMover positions via EditMode'):format(appliedCount))
			end
		end
	end

	return appliedCount
end

---Generic function to apply frame position via EditMode
---@param frameName string The BlizzMover name (e.g., 'TalkingHead')
---@param frameGlobal string|function The global frame name or function that returns the frame
---@param loadAddon? string Optional addon to load before applying position
---@param onLoadEvent? string Event to wait for if addon needs loading (default: PLAYER_ENTERING_WORLD)
function BlizzardEditMode:ApplyFramePosition(frameName, frameGlobal, loadAddon, onLoadEvent)
	-- Ensure we have LibEMO
	local LibEMO = self.LibEMO or LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		if MoveIt.logger then
			MoveIt.logger.warning(('ApplyFramePosition: LibEditModeOverride not available for %s'):format(frameName))
		end
		return
	end

	-- Check if EditMode is ready
	if not LibEMO:IsReady() then
		-- Defer until EditMode is ready
		if MoveIt.logger then
			MoveIt.logger.debug(('ApplyFramePosition: Deferring %s until EditMode is ready'):format(frameName))
		end

		-- Store pending application
		if not self.pendingApplications then
			self.pendingApplications = {}
		end
		self.pendingApplications[frameName] = { frameGlobal = frameGlobal, loadAddon = loadAddon, onLoadEvent = onLoadEvent }

		-- Set up event handler if not already done
		if not self.editModeReadyFrame then
			self.editModeReadyFrame = CreateFrame('Frame')
			self.editModeReadyFrame:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED')
			self.editModeReadyFrame:SetScript('OnEvent', function(frame, event)
				if LibEMO:IsReady() then
					frame:UnregisterEvent(event)
					BlizzardEditMode:ProcessPendingApplications()
				end
			end)
		end
		return
	end

	-- Ensure SpartanUI profile exists and is active
	if not self:EnsureProfileReady(LibEMO) then
		if MoveIt.logger then
			MoveIt.logger.warning(('ApplyFramePosition: Failed to ensure profile ready for %s'):format(frameName))
		end
		return
	end

	local function ApplyPosition()
		-- Get frame reference
		local frame
		if type(frameGlobal) == 'function' then
			frame = frameGlobal()
		else
			frame = _G[frameGlobal]
		end

		if not frame then
			if MoveIt.logger then
				MoveIt.logger.warning(('ApplyFramePosition: Frame not found for %s'):format(frameName))
			end
			return
		end

		-- Apply position from database
		if self:SetFramePositionFromDB(frameName, frame) then
			-- Apply changes with mover suppression to prevent showing all movers
			if self:SafeApplyChanges(true) then -- true = suppress movers
				if MoveIt.logger then
					MoveIt.logger.info(('%s position applied via EditMode'):format(frameName))
				end
			end
		end
	end

	-- Check if addon needs to be loaded
	if loadAddon then
		if C_AddOns.IsAddOnLoaded(loadAddon) then
			ApplyPosition()
		else
			-- Load the addon and apply position
			if MoveIt.logger then
				MoveIt.logger.debug(('Loading %s addon for %s positioning'):format(loadAddon, frameName))
			end
			local frame = CreateFrame('Frame')
			frame:RegisterEvent(onLoadEvent or 'PLAYER_ENTERING_WORLD')
			frame:SetScript('OnEvent', function(self, event)
				self:UnregisterEvent(event)
				C_AddOns.LoadAddOn(loadAddon)
				ApplyPosition()
			end)
		end
	else
		ApplyPosition()
	end
end

---Process all pending frame position applications
function BlizzardEditMode:ProcessPendingApplications()
	if not self.pendingApplications then
		return
	end

	if MoveIt.logger then
		MoveIt.logger.info('EditMode ready - processing pending frame applications')
	end

	for frameName, data in pairs(self.pendingApplications) do
		if MoveIt.logger then
			MoveIt.logger.debug(('Processing pending application for %s'):format(frameName))
		end
		self:ApplyFramePosition(frameName, data.frameGlobal, data.loadAddon, data.onLoadEvent)
	end

	-- Clear pending applications
	self.pendingApplications = nil
end

---Apply TalkingHead position via EditMode
function BlizzardEditMode:ApplyTalkingHeadPosition()
	self:ApplyFramePosition('TalkingHead', 'TalkingHeadFrame', 'Blizzard_TalkingHeadUI')
end

---Apply ExtraAbilities position via EditMode (ExtraActionBar + ZoneAbility)
function BlizzardEditMode:ApplyExtraAbilitiesPosition()
	-- ExtraAbilities is system ID 11
	-- EditMode positions the ExtraAbilityContainer, which contains both ExtraActionBarFrame and ZoneAbilityFrame
	-- Try ExtraAbilityContainer first, fallback to ExtraActionBarFrame
	local frame = _G['ExtraAbilityContainer'] or _G['ExtraActionBarFrame']
	if frame then
		self:ApplyFramePosition('ExtraActionBar', function()
			return _G['ExtraAbilityContainer'] or _G['ExtraActionBarFrame']
		end)
	else
		if MoveIt.logger then
			MoveIt.logger.warning('ExtraAbilities: No suitable frame found (ExtraAbilityContainer or ExtraActionBarFrame)')
		end
	end
end

---Apply EncounterBar position via EditMode
function BlizzardEditMode:ApplyEncounterBarPosition()
	self:ApplyFramePosition('EncounterBar', 'EncounterBar')
end

---Apply VehicleLeaveButton position via EditMode
function BlizzardEditMode:ApplyVehicleLeaveButtonPosition()
	self:ApplyFramePosition('VehicleLeaveButton', 'MainMenuBarVehicleLeaveButton')
end

---Apply ArchaeologyBar position via EditMode
function BlizzardEditMode:ApplyArchaeologyBarPosition()
	self:ApplyFramePosition('ArchaeologyBar', 'ArcheologyDigsiteProgressBar')
end

---Restore a frame to Blizzard's default EditMode position
---@param frameName string The frame name
function BlizzardEditMode:RestoreBlizzardDefault(frameName)
	local LibEMO = LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		return
	end

	-- For now, we'll just log this - full implementation would require
	-- knowing Blizzard's default positions or resetting the EditMode system
	if MoveIt.logger then
		MoveIt.logger.info(('RestoreBlizzardDefault: Restoring "%s" to default (not yet fully implemented)'):format(frameName))
	end

	-- TODO: Implement actual restoration logic
	-- This might involve:
	-- 1. Getting the default layout
	-- 2. Copying its position for this frame
	-- 3. Or removing our custom position entirely
end

---Safely apply EditMode changes (combat-aware)
---@param suppressMovers? boolean If true, prevent showing MoveIt movers during apply
---@return boolean success True if changes were applied
function BlizzardEditMode:SafeApplyChanges(suppressMovers)
	if InCombatLockdown() then
		-- Queue for after combat
		if not self.eventFrame then
			self.eventFrame = CreateFrame('Frame')
		end
		self.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
		self.eventFrame:SetScript('OnEvent', function(frame, event)
			if event == 'PLAYER_REGEN_ENABLED' then
				BlizzardEditMode:PLAYER_REGEN_ENABLED()
			end
		end)
		self.pendingApply = true
		if MoveIt.logger then
			MoveIt.logger.warning('Deferring EditMode changes until after combat')
		end
		return false
	end

	local LibEMO = LibStub('LibEditModeOverride-1.0', true)
	if LibEMO then
		-- Suppress movers if requested
		if suppressMovers and MoveIt.CustomEditMode then
			MoveIt.CustomEditMode.suppressActivation = true
		end

		local success = pcall(function()
			LibEMO:ApplyChanges()
		end)

		-- Re-enable movers
		if suppressMovers and MoveIt.CustomEditMode then
			MoveIt.CustomEditMode.suppressActivation = false
		end

		if success then
			if MoveIt.logger then
				MoveIt.logger.debug('EditMode changes applied successfully')
			end
			return true
		else
			if MoveIt.logger then
				MoveIt.logger.error('Failed to apply EditMode changes')
			end
		end
	end
	return false
end

---Handle exiting combat to apply pending changes
function BlizzardEditMode:PLAYER_REGEN_ENABLED()
	if self.pendingApply then
		if MoveIt.logger then
			MoveIt.logger.info('Combat ended - applying pending EditMode changes')
		end
		self.pendingApply = false
		if self.eventFrame then
			self.eventFrame:UnregisterEvent('PLAYER_REGEN_ENABLED')
		end
		self:SafeApplyChanges()
	end
end

---Check if a frame needs a custom mover
---@param frameName string The frame name
---@return boolean needsCustom True if frame needs custom mover
function BlizzardEditMode:NeedsCustomMover(frameName)
	-- Frames that ALWAYS need custom movers
	if NON_EDITMODE_FRAMES[frameName] then
		return true
	end

	-- If EditMode not available (Classic/TBC/Wrath), always use custom
	if not EditModeManagerFrame then
		return true
	end

	-- Frames migrated to use LibEditModeOverride
	local migratedFrames = {
		TalkingHead = true,
		ExtraActionBar = true,
		ZoneAbility = true,
		EncounterBar = true,
		VehicleLeaveButton = true,
		ArchaeologyBar = true,
	}

	if migratedFrames[frameName] then
		return false -- Use native EditMode via LibEditModeOverride
	end

	-- All other frames need custom movers (until explicitly migrated)
	return true
end

if MoveIt.logger then
	MoveIt.logger.info('Blizzard EditMode module loaded')
end
