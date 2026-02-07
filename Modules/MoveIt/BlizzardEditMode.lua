--@type SUI
local SUI = SUI
---@class MoveIt
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
		self:RegisterEditModeExitHandler()
		self:MonitorPartyRaidCheckboxes()
	else
		-- Hook into ready event
		local frame = CreateFrame('Frame')
		frame:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED')
		frame:SetScript('OnEvent', function(self, event)
			if LibEMO:IsReady() then
				BlizzardEditMode:SetupBlizzardFrames(LibEMO)
				BlizzardEditMode:StartLayoutMonitoring()
				BlizzardEditMode:RegisterEditModeExitHandler()
				BlizzardEditMode:MonitorPartyRaidCheckboxes()
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

	-- Ensure SpartanUI profile exists and is active
	self:EnsureProfileReady(LibEMO)

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

	-- Hook EditModePresetLayoutManager to override what Blizzard considers "default" positions
	self:HookDefaultPositions()
end

---Monitor and override Edit Mode party/raid checkbox changes
---Ensures Blizzard frames stay hidden even when Edit Mode tries to show them
function BlizzardEditMode:MonitorPartyRaidCheckboxes()
	if not EditModeManagerFrame then
		return
	end

	-- Hook the party/raid checkbox callbacks
	local accountSettings = EditModeManagerFrame.AccountSettings
	if not accountSettings then
		return
	end

	-- Completely replace SetPartyFramesShown to prevent protected function calls
	-- The original function calls TargetUnit() which is protected and causes taint
	accountSettings.SetPartyFramesShown = function(self, shown, isUserInput)
		-- Update the account setting if this was triggered by user input
		if isUserInput then
			EditModeManagerFrame:OnAccountSettingChanged(Enum.EditModeAccountSetting.ShowPartyFrames, shown)
		else
			-- Programmatic call - just update the checkbox state
			self.settingsCheckButtons.PartyFrames:SetControlChecked(shown)
		end

		-- Force hide Blizzard frames regardless of checkbox state
		-- Do NOT call RefreshPartyFrames or interact with Blizzard frames at all
		if MoveIt.logger then
			MoveIt.logger.debug('Edit Mode party checkbox toggled - SpartanUI frames control visibility')
		end
	end

	-- Completely replace SetRaidFramesShown to prevent protected function calls
	-- The original function tries to update CompactRaidFrameContainer which we've disabled
	accountSettings.SetRaidFramesShown = function(self, shown, isUserInput)
		-- Update the account setting if this was triggered by user input
		if isUserInput then
			EditModeManagerFrame:OnAccountSettingChanged(Enum.EditModeAccountSetting.ShowRaidFrames, shown)
		else
			-- Programmatic call - just update the checkbox state
			self.settingsCheckButtons.RaidFrames:SetControlChecked(shown)
		end

		-- Force hide Blizzard frames regardless of checkbox state
		-- Do NOT call RefreshRaidFrames or interact with Blizzard frames at all
		if MoveIt.logger then
			MoveIt.logger.debug('Edit Mode raid checkbox toggled - SpartanUI frames control visibility')
		end
	end

	-- Replace RefreshPartyFrames to prevent interaction with Blizzard frames
	accountSettings.RefreshPartyFrames = function(self)
		-- Do nothing - SpartanUI controls party frames
		if MoveIt.logger then
			MoveIt.logger.debug('RefreshPartyFrames called - no-op (SpartanUI controls party frames)')
		end
	end

	-- Replace RefreshRaidFrames to prevent interaction with Blizzard frames
	accountSettings.RefreshRaidFrames = function(self)
		-- Do nothing - SpartanUI controls raid frames
		if MoveIt.logger then
			MoveIt.logger.debug('RefreshRaidFrames called - no-op (SpartanUI controls raid frames)')
		end
	end

	-- Replace ResetPartyFrames to prevent interaction with Blizzard frames
	accountSettings.ResetPartyFrames = function(self)
		-- Do nothing - SpartanUI controls party frames
	end

	-- Replace ResetRaidFrames to prevent interaction with Blizzard frames
	accountSettings.ResetRaidFrames = function(self)
		-- Do nothing - SpartanUI controls raid frames
	end

	if MoveIt.logger then
		MoveIt.logger.info('Overrode Edit Mode party/raid frame functions to prevent Blizzard frame interaction')
	end
end

---Hook EditModePresetLayoutManager to override default positions
function BlizzardEditMode:HookDefaultPositions()
	if self.defaultPositionsHooked then
		return
	end

	-- Hook EditModePresetLayoutManager:GetDefaultSystemAnchorInfo to return SpartanUI positions
	if not (EditModePresetLayoutManager and EditModePresetLayoutManager.GetDefaultSystemAnchorInfo) then
		if MoveIt.logger then
			MoveIt.logger.warning('EditModePresetLayoutManager not found - cannot override default positions')
		end
		return
	end

	-- Store original function
	local originalGetDefaultAnchor = EditModePresetLayoutManager.GetDefaultSystemAnchorInfo

	EditModePresetLayoutManager.GetDefaultSystemAnchorInfo = function(self, systemID, systemIndex)
		-- Check if we're on SpartanUI profile
		local LibEMO = BlizzardEditMode.LibEMO or LibStub('LibEditModeOverride-1.0', true)
		if not (LibEMO and LibEMO:AreLayoutsLoaded()) then
			return originalGetDefaultAnchor(self, systemID, systemIndex)
		end

		local currentLayout = LibEMO:GetActiveLayout()
		if currentLayout ~= 'SpartanUI' then
			return originalGetDefaultAnchor(self, systemID, systemIndex)
		end

		-- Get frame name from system ID
		local frameName = BlizzardEditMode:GetFrameNameBySystemID(systemID)
		if not frameName then
			return originalGetDefaultAnchor(self, systemID, systemIndex)
		end

		-- Get SpartanUI's custom position
		local style = SUI.DB.Artwork and SUI.DB.Artwork.Style
		if not style or not SUI.DB.Styles[style] or not SUI.DB.Styles[style].BlizzMovers then
			return originalGetDefaultAnchor(self, systemID, systemIndex)
		end

		local positionString = SUI.DB.Styles[style].BlizzMovers[frameName]
		if not positionString then
			return originalGetDefaultAnchor(self, systemID, systemIndex)
		end

		-- Parse position
		local point, anchorName, relativePoint, x, y = BlizzardEditMode:ParseSUIPosition(positionString)
		if not point then
			return originalGetDefaultAnchor(self, systemID, systemIndex)
		end

		-- Return SpartanUI's custom anchor info instead of Blizzard's default
		local customAnchor = {
			point = point,
			relativeTo = anchorName or 'UIParent',
			relativePoint = relativePoint or point,
			offsetX = x or 0,
			offsetY = y or 0,
		}

		if MoveIt.logger then
			MoveIt.logger.info(
				('Returning SpartanUI default for %s: %s,%s,%s,%d,%d'):format(
					frameName,
					customAnchor.point,
					customAnchor.relativeTo,
					customAnchor.relativePoint,
					customAnchor.offsetX,
					customAnchor.offsetY
				)
			)
		end

		return customAnchor
	end

	self.defaultPositionsHooked = true

	if MoveIt.logger then
		MoveIt.logger.info('Hooked EditModePresetLayoutManager:GetDefaultSystemAnchorInfo to override default positions')
	end

	-- Also hook the reset button to force reapply after Blizzard's reset completes
	self:HookResetButton()
end

---Hook the reset button to reapply SpartanUI positions after reset
function BlizzardEditMode:HookResetButton()
	if not EditModeSystemSettingsDialog then
		return
	end

	-- Hook UpdateDialog to find and hook reset buttons
	hooksecurefunc(EditModeSystemSettingsDialog, 'UpdateDialog', function(dialog, system)
		if not system or not system.resetToDefaultPositionButton then
			return
		end

		-- Only hook once per button
		if system.resetToDefaultPositionButton.suiResetHooked then
			return
		end

		system.resetToDefaultPositionButton.suiResetHooked = true

		if MoveIt.logger then
			MoveIt.logger.debug(('Hooked reset button for system %d'):format(system.system))
		end

		-- Hook button click to reapply SpartanUI position
		system.resetToDefaultPositionButton:HookScript('OnClick', function()
			local systemID = system.system
			local frameName = BlizzardEditMode:GetFrameNameBySystemID(systemID)
			if not frameName then
				return
			end

			-- Get the frame
			local frame = nil
			if frameName == 'TalkingHead' then
				frame = TalkingHeadFrame
			elseif frameName == 'VehicleLeaveButton' then
				frame = VehicleLeaveButton
			elseif frameName == 'ExtraActionBar' then
				frame = ExtraActionBarFrame
			elseif frameName == 'EncounterBar' then
				frame = EncounterBar
			elseif frameName == 'ArchaeologyBar' then
				frame = ArcheologyDigsiteProgressBar
			end

			if not frame then
				return
			end

			if MoveIt.logger then
				MoveIt.logger.info(('Reset button clicked for system %d (%s)'):format(systemID, frameName))
			end

			-- Reapply immediately
			BlizzardEditMode:ReapplyFramePosition(frameName, frame, true)

			-- Also reapply after delay to ensure it sticks
			C_Timer.After(0.3, function()
				BlizzardEditMode:ReapplyFramePosition(frameName, frame, true)
			end)
		end)
	end)
end

---Get frame name from EditMode system ID
---@param systemID number The EditMode system ID
---@return string|nil frameName The frame name or nil
function BlizzardEditMode:GetFrameNameBySystemID(systemID)
	-- Map actual frame systemIDs to BlizzMover names
	-- Note: These systemIDs are discovered at runtime and may differ from documentation
	local systemMap = {
		[7] = 'TalkingHead', -- TalkingHeadFrame (actual systemID verified)
		[14] = 'VehicleLeaveButton', -- VehicleLeaveButton
		[11] = 'ExtraActionBar', -- ExtraAbilities (ExtraActionBar + ZoneAbility)
		[10] = 'EncounterBar', -- EncounterBar
		[21] = 'ArchaeologyBar', -- ArchaeologyBar
		-- TODO: Add more as we discover their actual systemIDs
		-- ExtraActionButton, ZoneAbilityFrame, etc.
	}
	return systemMap[systemID]
end

---Reapply SpartanUI position for a frame (used after reset to default)
---@param frameName string The frame name
---@param frame Frame The frame object
---@param skipApply? boolean If true, don't call SafeApplyChanges (for in-edit-mode adjustments)
function BlizzardEditMode:ReapplyFramePosition(frameName, frame, skipApply)
	if not frame then
		return
	end

	local LibEMO = self.LibEMO or LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		return
	end

	-- Get position from database
	local style = SUI.DB.Artwork and SUI.DB.Artwork.Style
	if not style or not SUI.DB.Styles[style] or not SUI.DB.Styles[style].BlizzMovers then
		return
	end

	local positionString = SUI.DB.Styles[style].BlizzMovers[frameName]
	if not positionString then
		return
	end

	-- Parse position
	local point, anchorName, relativePoint, x, y = self:ParseSUIPosition(positionString)
	if not point then
		return
	end

	-- Resolve anchor frame
	local anchorFrame = _G[anchorName] or UIParent

	-- Get the EditMode system for this frame
	local system = nil
	if frame.system and EditModeManagerFrame then
		for _, sys in pairs(EditModeManagerFrame.registeredSystemFrames) do
			if sys == frame then
				system = sys
				break
			end
		end
	end

	-- Apply position
	pcall(function()
		LibEMO:ReanchorFrame(frame, point, anchorFrame, relativePoint, x, y)

		-- Mark as NOT in default position so EditMode doesn't override our position
		if system and system.systemInfo then
			system.systemInfo.isInDefaultPosition = false

			-- Call ApplySystemAnchor to actually move the frame visually
			if system.ApplySystemAnchor then
				system:ApplySystemAnchor()
			end
		end
	end)

	-- Save position to layout
	if skipApply then
		-- We're in edit mode - save without exiting
		pcall(function()
			LibEMO:SaveOnly()
		end)
		if MoveIt.logger then
			MoveIt.logger.info(('%s position reapplied'):format(frameName))
		end
	else
		-- Apply changes with mover suppression
		self:SafeApplyChanges(true)
		if MoveIt.logger then
			MoveIt.logger.info(('%s position reapplied'):format(frameName))
		end
	end
end

---Handle EditMode layout changes
function BlizzardEditMode:OnLayoutChanged()
	local LibEMO = self.LibEMO or LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO or not LibEMO:AreLayoutsLoaded() then
		return
	end

	-- Skip during initial setup phase (before wizard has completed)
	-- This prevents false positive popups on login
	if not self.initialSetupComplete then
		return
	end

	-- Skip if migration is in progress (wizard is actively switching profiles)
	if MoveIt.WizardPage and MoveIt.WizardPage:IsMigrationInProgress() then
		if MoveIt.logger then
			MoveIt.logger.debug('OnLayoutChanged: Skipping - migration in progress')
		end
		return
	end

	-- Reload layouts to get current state
	LibEMO:LoadLayouts()

	local currentLayout = LibEMO:GetActiveLayout()
	local expectedProfile = MoveIt.DB.EditModeControl.CurrentProfile

	-- Check if user switched to a non-SpartanUI profile
	if not self:IsSpartanUILayout(currentLayout) then
		if MoveIt.logger then
			MoveIt.logger.warning(('EditMode profile changed to "%s" - not a SpartanUI profile'):format(tostring(currentLayout)))
		end

		-- If EditMode control is enabled and user switched away, mark for popup prompt
		if MoveIt.DB.EditModeControl.Enabled then
			self.pendingManualSwitchPrompt = currentLayout
		end
	else
		if MoveIt.logger then
			MoveIt.logger.info(('EditMode profile is "%s" - SpartanUI managed'):format(currentLayout))
		end
		self.pendingManualSwitchPrompt = nil
	end
end

---Show popup asking user if they want SpartanUI to manage their new profile
---Called after user exits EditMode when they switched to a non-SUI profile
function BlizzardEditMode:ShowManualSwitchPopup()
	if not self.pendingManualSwitchPrompt then
		return
	end

	local newProfile = self.pendingManualSwitchPrompt
	self.pendingManualSwitchPrompt = nil

	-- Don't show if control is already disabled
	if not MoveIt.DB.EditModeControl.Enabled then
		return
	end

	-- Create popup using LibAT.UI if available, otherwise use StaticPopup
	local LibAT = _G.LibAT
	if LibAT and LibAT.UI and LibAT.UI.CreateConfirmDialog then
		LibAT.UI.CreateConfirmDialog({
			title = 'SpartanUI - EditMode Profile',
			message = ('You changed to the EditMode profile "%s".\n\nWould you like SpartanUI to apply default frame positions to this profile?'):format(newProfile),
			confirmText = 'Yes, apply SUI defaults',
			cancelText = 'No, leave unchanged',
			onConfirm = function()
				-- Apply SUI defaults to this new profile
				self:ApplyDefaultPositions()
				self:SafeApplyChanges(true)
				MoveIt.DB.EditModeControl.CurrentProfile = newProfile
				if MoveIt.logger then
					MoveIt.logger.info(('Applied SUI defaults to profile "%s"'):format(newProfile))
				end
			end,
			onCancel = function()
				-- User doesn't want us to modify this profile
				-- Ask if they want to disable management entirely
				C_Timer.After(0.1, function()
					self:ShowDisableManagementPopup(newProfile)
				end)
			end,
		})
	else
		-- Fallback to StaticPopup
		StaticPopupDialogs['SUI_EDITMODE_MANUAL_SWITCH'] = {
			text = ('You changed to the EditMode profile "%s".\n\nWould you like SpartanUI to apply default frame positions to this profile?'):format(newProfile),
			button1 = 'Yes, apply defaults',
			button2 = 'No, leave unchanged',
			OnAccept = function()
				-- Apply SUI defaults to this new profile
				BlizzardEditMode:ApplyDefaultPositions()
				BlizzardEditMode:SafeApplyChanges(true)
				MoveIt.DB.EditModeControl.CurrentProfile = newProfile
				if MoveIt.logger then
					MoveIt.logger.info(('Applied SUI defaults to profile "%s"'):format(newProfile))
				end
			end,
			OnCancel = function()
				-- User doesn't want us to modify this profile
				-- Ask if they want to disable management entirely
				C_Timer.After(0.1, function()
					BlizzardEditMode:ShowDisableManagementPopup(newProfile)
				end)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = false,
			preferredIndex = 3,
		}
		StaticPopup_Show('SUI_EDITMODE_MANUAL_SWITCH')
	end
end

---Show popup asking if user wants to disable EditMode management
---Called when user declines to apply SUI defaults to their profile
---@param profileName string The profile they switched to
function BlizzardEditMode:ShowDisableManagementPopup(profileName)
	local LibAT = _G.LibAT
	if LibAT and LibAT.UI and LibAT.UI.CreateConfirmDialog then
		LibAT.UI.CreateConfirmDialog({
			title = 'SpartanUI - EditMode Management',
			message = 'Would you like SpartanUI to stop asking about EditMode profiles?\n\nYou can re-enable this in /sui > Movers.',
			confirmText = 'Yes, stop asking',
			cancelText = 'No, keep asking',
			onConfirm = function()
				MoveIt.DB.EditModeControl.Enabled = false
				if MoveIt.logger then
					MoveIt.logger.info('User disabled EditMode management')
				end
			end,
			onCancel = function()
				-- Keep management enabled, they just don't want defaults on this profile
				if MoveIt.logger then
					MoveIt.logger.info(('User declined defaults for "%s" but kept management enabled'):format(profileName))
				end
			end,
		})
	else
		-- Fallback to StaticPopup
		StaticPopupDialogs['SUI_EDITMODE_DISABLE_MANAGEMENT'] = {
			text = 'Would you like SpartanUI to stop asking about EditMode profiles?\n\nYou can re-enable this in /sui > Movers.',
			button1 = 'Yes, stop asking',
			button2 = 'No, keep asking',
			OnAccept = function()
				MoveIt.DB.EditModeControl.Enabled = false
				if MoveIt.logger then
					MoveIt.logger.info('User disabled EditMode management')
				end
			end,
			OnCancel = function()
				-- Keep management enabled
				if MoveIt.logger then
					MoveIt.logger.info(('User declined defaults for "%s" but kept management enabled'):format(profileName))
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show('SUI_EDITMODE_DISABLE_MANAGEMENT')
	end
end

---Register for EditMode exit event to show manual switch popup
function BlizzardEditMode:RegisterEditModeExitHandler()
	if self.editModeExitRegistered then
		return
	end

	if EditModeManagerFrame then
		EventRegistry:RegisterCallback('EditMode.Exit', function()
			-- Check if we need to show the manual switch popup
			if self.pendingManualSwitchPrompt then
				-- Delay slightly to let EditMode fully exit
				C_Timer.After(0.5, function()
					self:ShowManualSwitchPopup()
				end)
			end

			-- Re-hide Blizzard frames when exiting Edit Mode
			-- This ensures they stay hidden even if Edit Mode tried to show them
			if not InCombatLockdown() then
				pcall(function()
					if PartyFrame then
						PartyFrame:Hide()
						PartyFrame:SetAlpha(0)
					end
					if CompactPartyFrame then
						CompactPartyFrame:Hide()
						CompactPartyFrame:SetAlpha(0)
					end
					if CompactRaidFrameManager then
						CompactRaidFrameManager:Hide()
						CompactRaidFrameManager:SetAlpha(0)
					end
					if CompactRaidFrameContainer then
						CompactRaidFrameContainer:Hide()
						CompactRaidFrameContainer:SetAlpha(0)
					end
				end)

				if MoveIt.logger then
					MoveIt.logger.debug('Edit Mode exited - re-confirmed Blizzard frame hiding')
				end
			end
		end)
		self.editModeExitRegistered = true
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
		return nil, nil, nil, nil, nil
	end

	local point, anchor, relativePoint, x, y = strsplit(',', csvString)

	if not point or not anchor or not relativePoint or not x or not y then
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

	-- Ensure SpartanUI profile exists and is active
	if not self:EnsureProfileReady(LibEMO) then
		if MoveIt.logger then
			MoveIt.logger.warning(('SetFramePositionFromDB: SpartanUI profile not ready for "%s"'):format(frameName))
		end
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
	local style = SUI.DB.Artwork and SUI.DB.Artwork.Style
	if not style or not SUI.DB.Styles[style] or not SUI.DB.Styles[style].BlizzMovers then
		if MoveIt.logger then
			MoveIt.logger.warning(('SetFramePositionFromDB: Style or BlizzMovers not available for "%s"'):format(frameName))
		end
		return false
	end

	local positionString = SUI.DB.Styles[style].BlizzMovers[frameName]
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
		if SUI.DB.Artwork and SUI.DB.Artwork.BlizzMoverStates and SUI.DB.Artwork.BlizzMoverStates[frameName] and SUI.DB.Artwork.BlizzMoverStates[frameName].enabled then
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

-- ============================================================================
-- EditMode State Detection Functions
-- ============================================================================

-- Blizzard's preset layout names (not custom user profiles)
local PRESET_LAYOUTS = {
	['Modern'] = true,
	['Classic'] = true,
}

---Check if a layout name is a Blizzard preset (Modern/Classic)
---@param layoutName string The layout name to check
---@return boolean isPreset True if this is a preset layout
function BlizzardEditMode:IsPresetLayout(layoutName)
	return PRESET_LAYOUTS[layoutName] == true
end

---Check if a layout name is a SpartanUI managed profile
---@param layoutName string The layout name to check
---@return boolean isSpartanUI True if this is a SpartanUI profile
function BlizzardEditMode:IsSpartanUILayout(layoutName)
	if not layoutName then
		return false
	end
	-- Check for exact match "SpartanUI" or prefix "SpartanUI - "
	return layoutName == 'SpartanUI' or layoutName:find('^SpartanUI %- ') ~= nil
end

---@class SUI.MoveIt.EditModeState
---@field isEditModeAvailable boolean Is this Retail with EditMode?
---@field currentLayoutName string|nil Current active layout name
---@field isOnPresetLayout boolean Is user on Modern/Classic?
---@field isOnSpartanUILayout boolean Is user on a SpartanUI profile?
---@field spartanUILayoutExists boolean Does any SpartanUI profile exist?
---@field customizedFrames string[] List of frame names user has moved
---@field needsUpgradeWizard boolean Should show upgrade wizard page?

---Get comprehensive state about EditMode configuration
---@return SUI.MoveIt.EditModeState state The current EditMode state
function BlizzardEditMode:GetEditModeState()
	local state = {
		isEditModeAvailable = false,
		currentLayoutName = nil,
		isOnPresetLayout = false,
		isOnSpartanUILayout = false,
		spartanUILayoutExists = false,
		customizedFrames = {},
		needsUpgradeWizard = false,
	}

	-- Check if EditMode is available (Retail only)
	if not EditModeManagerFrame then
		return state
	end
	state.isEditModeAvailable = true

	-- Get LibEditModeOverride
	local LibEMO = self.LibEMO or LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		return state
	end

	-- Ensure layouts are loaded
	if not LibEMO:IsReady() then
		return state
	end

	if not LibEMO:AreLayoutsLoaded() then
		LibEMO:LoadLayouts()
	end

	-- Get current layout
	state.currentLayoutName = LibEMO:GetActiveLayout()

	-- Check layout type
	if state.currentLayoutName then
		state.isOnPresetLayout = self:IsPresetLayout(state.currentLayoutName)
		state.isOnSpartanUILayout = self:IsSpartanUILayout(state.currentLayoutName)
	end

	-- Check if any SpartanUI profile exists
	state.spartanUILayoutExists = LibEMO:DoesLayoutExist('SpartanUI')

	-- Get list of customized frames
	state.customizedFrames = self:GetCustomizedFrameNames()

	-- Determine if upgrade wizard is needed
	-- Needed when: user is on a custom profile (not preset, not SpartanUI)
	state.needsUpgradeWizard = state.isEditModeAvailable and not state.isOnPresetLayout and not state.isOnSpartanUILayout and state.currentLayoutName ~= nil

	return state
end

---Get list of frame names that user has customized (moved from default positions)
---@return string[] frameNames List of customized frame names
function BlizzardEditMode:GetCustomizedFrameNames()
	local customizedFrames = {}

	if not EditModeManagerFrame then
		return customizedFrames
	end

	-- Frames we manage via EditMode
	local managedFrames = {
		{ name = 'TalkingHead', frame = TalkingHeadFrame },
		{ name = 'VehicleLeaveButton', frame = MainMenuBarVehicleLeaveButton },
		{ name = 'ExtraActionBar', frame = ExtraAbilityContainer or ExtraActionBarFrame },
		{ name = 'EncounterBar', frame = EncounterBar },
		{ name = 'ArchaeologyBar', frame = ArcheologyDigsiteProgressBar },
	}

	for _, frameInfo in ipairs(managedFrames) do
		local frame = frameInfo.frame
		if frame and self:IsFramePositionCustomized(frame) then
			table.insert(customizedFrames, frameInfo.name)
		end
	end

	return customizedFrames
end

---Get the appropriate EditMode profile name for current SUI profile
---@return string profileName The matching EditMode profile name
function BlizzardEditMode:GetMatchingProfileName()
	local currentSUIProfile = SUI.SpartanUIDB:GetCurrentProfile()

	-- Default profile -> "SpartanUI"
	if currentSUIProfile == 'Default' then
		return 'SpartanUI'
	end

	-- Realm profile -> "SpartanUI - RealmName"
	if currentSUIProfile == SUI.SpartanUIDB.keys.realm then
		return 'SpartanUI - ' .. currentSUIProfile
	end

	-- Class profile -> "SpartanUI - ClassName"
	if currentSUIProfile == SUI.SpartanUIDB.keys.class then
		return 'SpartanUI - ' .. currentSUIProfile
	end

	-- Character profile (CharName - RealmName) -> "SpartanUI - CharName"
	local charKey = SUI.SpartanUIDB.keys.char
	if currentSUIProfile == charKey then
		-- Extract just the character name (before " - ")
		local charName = currentSUIProfile:match('^([^%-]+)')
		if charName then
			charName = charName:gsub('%s+$', '') -- Trim trailing spaces
			return 'SpartanUI - ' .. charName
		end
	end

	-- Custom profile name -> "SpartanUI - ProfileName"
	return 'SpartanUI - ' .. currentSUIProfile
end

---Get appropriate EditMode layout type based on SUI profile
---@return number layoutType Enum.EditModeLayoutType value
function BlizzardEditMode:DetermineLayoutType()
	local currentSUIProfile = SUI.SpartanUIDB:GetCurrentProfile()
	local charKey = SUI.SpartanUIDB.keys.char
	local realmKey = SUI.SpartanUIDB.keys.realm
	local classKey = SUI.SpartanUIDB.keys.class

	if MoveIt.logger then
		MoveIt.logger.debug(
			('DetermineLayoutType: currentSUIProfile="%s", charKey="%s", realmKey="%s", classKey="%s"'):format(tostring(currentSUIProfile), tostring(charKey), tostring(realmKey), tostring(classKey))
		)
	end

	-- Shared profiles use Account scope
	if currentSUIProfile == 'Default' or currentSUIProfile == realmKey or currentSUIProfile == classKey then
		if MoveIt.logger then
			MoveIt.logger.debug('DetermineLayoutType: Using Account scope (shared profile)')
		end
		return Enum.EditModeLayoutType.Account
	end

	-- Character-specific profile uses Character scope
	if currentSUIProfile == charKey then
		if MoveIt.logger then
			MoveIt.logger.debug('DetermineLayoutType: Using Character scope (character profile)')
		end
		return Enum.EditModeLayoutType.Character
	end

	-- Custom named profiles default to Character scope
	if MoveIt.logger then
		MoveIt.logger.debug('DetermineLayoutType: Using Character scope (custom named profile)')
	end
	return Enum.EditModeLayoutType.Character
end

---Create a new EditMode layout copying positions from the CURRENT active layout
---This differs from LibEMO:AddLayout which always copies from Modern
---@param layoutType number Enum.EditModeLayoutType (Account or Character)
---@param newLayoutName string Name for the new layout
---@param sourceLayoutName? string Optional: specific layout to copy from (defaults to current active)
---@return boolean success True if layout was created successfully
function BlizzardEditMode:CreateLayoutFromCurrent(layoutType, newLayoutName, sourceLayoutName)
	local LibEMO = self.LibEMO or LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		if MoveIt.logger then
			MoveIt.logger.error('CreateLayoutFromCurrent: LibEditModeOverride not available')
		end
		return false
	end

	if not LibEMO:IsReady() then
		if MoveIt.logger then
			MoveIt.logger.error('CreateLayoutFromCurrent: EditMode not ready')
		end
		return false
	end

	if not LibEMO:AreLayoutsLoaded() then
		LibEMO:LoadLayouts()
	end

	-- Check if layout already exists
	if LibEMO:DoesLayoutExist(newLayoutName) then
		if MoveIt.logger then
			MoveIt.logger.warning(('CreateLayoutFromCurrent: Layout "%s" already exists'):format(newLayoutName))
		end
		return false
	end

	-- Determine which layout to copy from
	-- Use provided sourceLayoutName, or get from LibEMO (more reliable than C_EditMode index)
	local targetLayoutName = sourceLayoutName or LibEMO:GetActiveLayout()

	if MoveIt.logger then
		MoveIt.logger.debug(('CreateLayoutFromCurrent: Will copy from layout "%s"'):format(tostring(targetLayoutName)))
	end

	-- Get current layout info
	local currentLayoutInfo = C_EditMode.GetLayouts()

	if MoveIt.logger then
		MoveIt.logger.debug(('CreateLayoutFromCurrent: C_EditMode reports activeLayout index = %d, layouts count = %d'):format(currentLayoutInfo.activeLayout, #currentLayoutInfo.layouts))
	end

	-- Find the source layout by NAME (not by activeLayout index which can be wrong)
	local currentLayout = nil
	local foundIndex = nil

	for i, layout in ipairs(currentLayoutInfo.layouts) do
		if layout.layoutName == targetLayoutName then
			currentLayout = layout
			foundIndex = i
			if MoveIt.logger then
				MoveIt.logger.debug(('CreateLayoutFromCurrent: Found source layout "%s" at index %d'):format(targetLayoutName, i))
			end
			break
		end
	end

	if not currentLayout then
		if MoveIt.logger then
			MoveIt.logger.error(('CreateLayoutFromCurrent: Could not find layout "%s"'):format(tostring(targetLayoutName)))
			-- Log available layouts for debugging
			for i, layout in ipairs(currentLayoutInfo.layouts) do
				MoveIt.logger.debug(('  Layout[%d]: name="%s", type=%d'):format(i, tostring(layout.layoutName), layout.layoutType or -1))
			end
		end
		return false
	end

	if MoveIt.logger then
		MoveIt.logger.debug(('CreateLayoutFromCurrent: Copying from layout "%s" (type=%d)'):format(tostring(currentLayout.layoutName), currentLayout.layoutType or -1))
	end

	-- Deep copy the current layout
	local newLayout = CopyTable(currentLayout)
	newLayout.layoutType = layoutType
	newLayout.layoutName = newLayoutName

	-- Insert new layout into the layouts table
	-- We need to work directly with C_EditMode API since LibEMO:AddLayout copies from Modern
	local success, errorMsg = pcall(function()
		-- Reload layouts to get fresh state
		LibEMO:LoadLayouts()

		-- Get layouts again and insert our new one
		local layoutInfo = C_EditMode.GetLayouts()

		-- Find insertion point based on layout type
		-- Account layouts go after presets but before character layouts
		-- Character layouts go at the end
		local insertIndex = #layoutInfo.layouts + 1
		for i, layout in ipairs(layoutInfo.layouts) do
			if layoutType == Enum.EditModeLayoutType.Account then
				-- Insert before first character layout
				if layout.layoutType == Enum.EditModeLayoutType.Character then
					insertIndex = i
					break
				end
			end
			-- For character layouts, just append at end (insertIndex already set)
		end

		if MoveIt.logger then
			MoveIt.logger.debug(('CreateLayoutFromCurrent: Inserting new layout at index %d'):format(insertIndex))
		end

		table.insert(layoutInfo.layouts, insertIndex, newLayout)
		layoutInfo.activeLayout = insertIndex

		-- Save the layouts
		C_EditMode.SaveLayouts(layoutInfo)
	end)

	if success then
		-- Reload LibEMO to pick up the new layout
		LibEMO:LoadLayouts()

		-- Now switch to the new layout using LibEMO (more reliable than C_EditMode)
		if LibEMO:DoesLayoutExist(newLayoutName) then
			LibEMO:SetActiveLayout(newLayoutName)
			if MoveIt.logger then
				MoveIt.logger.info(('CreateLayoutFromCurrent: Created and activated layout "%s"'):format(newLayoutName))
			end
		else
			if MoveIt.logger then
				MoveIt.logger.error(('CreateLayoutFromCurrent: Layout "%s" was not found after creation'):format(newLayoutName))
			end
			return false
		end
		return true
	else
		if MoveIt.logger then
			MoveIt.logger.error(('CreateLayoutFromCurrent: Failed to create layout "%s": %s'):format(newLayoutName, tostring(errorMsg)))
		end
		return false
	end
end

---Apply SUI default positions to the current EditMode profile
---Only applies to frames that SUI manages
function BlizzardEditMode:ApplyDefaultPositions()
	local LibEMO = self.LibEMO or LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO then
		if MoveIt.logger then
			MoveIt.logger.error('ApplyDefaultPositions: LibEditModeOverride not available')
		end
		return
	end

	if not LibEMO:CanEditActiveLayout() then
		if MoveIt.logger then
			MoveIt.logger.warning('ApplyDefaultPositions: Cannot edit active layout (may be a preset)')
		end
		return
	end

	-- Get current style's BlizzMover positions
	local style = SUI.DB.Artwork and SUI.DB.Artwork.Style
	if not style then
		if MoveIt.logger then
			MoveIt.logger.warning('ApplyDefaultPositions: No style defined in SUI.DB.Artwork.Style')
		end
		return
	end

	local blizzMovers = SUI.DB.Styles[style] and SUI.DB.Styles[style].BlizzMovers
	if not blizzMovers then
		if MoveIt.logger then
			MoveIt.logger.warning(('ApplyDefaultPositions: No BlizzMovers defined for style "%s"'):format(style))
		end
		return
	end

	-- Frames we manage and their global references
	local managedFrames = {
		{ name = 'TalkingHead', globalName = 'TalkingHeadFrame' },
		{ name = 'VehicleLeaveButton', globalName = 'MainMenuBarVehicleLeaveButton' },
		{ name = 'ExtraActionBar', globalName = 'ExtraAbilityContainer', fallback = 'ExtraActionBarFrame' },
		{ name = 'EncounterBar', globalName = 'EncounterBar' },
		{ name = 'ArchaeologyBar', globalName = 'ArcheologyDigsiteProgressBar' },
	}

	local appliedCount = 0

	for _, frameInfo in ipairs(managedFrames) do
		local positionString = blizzMovers[frameInfo.name]
		if positionString then
			local frame = _G[frameInfo.globalName] or (frameInfo.fallback and _G[frameInfo.fallback])

			if frame then
				local point, anchorName, relativePoint, x, y = self:ParseSUIPosition(positionString)
				if point then
					local anchorFrame = _G[anchorName] or UIParent

					local success = pcall(function()
						LibEMO:ReanchorFrame(frame, point, anchorFrame, relativePoint, x, y)
					end)

					if success then
						appliedCount = appliedCount + 1
						if MoveIt.logger then
							MoveIt.logger.debug(('ApplyDefaultPositions: Applied position for %s'):format(frameInfo.name))
						end
					end
				end
			end
		end
	end

	if appliedCount > 0 then
		if MoveIt.logger then
			MoveIt.logger.info(('ApplyDefaultPositions: Applied %d default positions'):format(appliedCount))
		end
	end
end

-- ============================================================================
-- SUI Profile Change Handling
-- ============================================================================

---Handle SUI profile change - sync EditMode profile
---@param event string The callback event name
---@param database table The AceDB database
---@param newProfile string The new profile name
function BlizzardEditMode:OnSUIProfileChanged(event, database, newProfile)
	-- Skip if EditMode control is disabled
	if not MoveIt.DB.EditModeControl.Enabled or not MoveIt.DB.EditModeControl.AutoSwitch then
		return
	end

	-- Skip if EditMode not available
	if not EditModeManagerFrame then
		return
	end

	local LibEMO = self.LibEMO or LibStub('LibEditModeOverride-1.0', true)
	if not LibEMO or not LibEMO:IsReady() then
		return
	end

	-- Check if user is switching to another character's profile (warn them)
	if MoveIt.WizardPage then
		local isUsingOtherProfile, otherCharName = MoveIt.WizardPage:IsUsingOtherCharacterProfile()
		if isUsingOtherProfile and otherCharName then
			MoveIt.WizardPage:ShowSharedProfileWarning(otherCharName)
		end
	end

	-- Get the matching EditMode profile name
	local matchingProfile = self:GetMatchingProfileName()

	if MoveIt.logger then
		MoveIt.logger.info(('OnSUIProfileChanged: SUI profile changed to "%s", matching EditMode profile: "%s"'):format(newProfile, matchingProfile))
	end

	-- Ensure layouts are loaded
	if not LibEMO:AreLayoutsLoaded() then
		LibEMO:LoadLayouts()
	end

	-- Check if matching EditMode profile exists
	if LibEMO:DoesLayoutExist(matchingProfile) then
		-- Profile exists, switch to it
		local currentLayout = LibEMO:GetActiveLayout()
		if currentLayout ~= matchingProfile then
			pcall(function()
				LibEMO:SetActiveLayout(matchingProfile)
				self:SafeApplyChanges(true)
			end)
			if MoveIt.logger then
				MoveIt.logger.info(('OnSUIProfileChanged: Switched to EditMode profile "%s"'):format(matchingProfile))
			end
		end
	else
		-- Profile doesn't exist, create it from current
		local layoutType = self:DetermineLayoutType()
		if self:CreateLayoutFromCurrent(layoutType, matchingProfile) then
			-- Apply SUI defaults on top
			self:ApplyDefaultPositions()
			self:SafeApplyChanges(true)
		end
	end

	-- Update stored current profile
	MoveIt.DB.EditModeControl.CurrentProfile = matchingProfile
end

if MoveIt.logger then
	MoveIt.logger.info('Blizzard EditMode module loaded')
end
