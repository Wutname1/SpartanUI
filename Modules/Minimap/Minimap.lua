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
	size = {180, 180},
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
			size = {220, 220},
			color = {1, 1, 1, 1},
			BlendMode = 'ADD',
			alpha = 1
		},
		-- Zone Text
		ZoneText = {
			enabled = true,
			scale = 1,
			position = 'TOPLEFT,BorderTop,TOPLEFT,4,-4',
			color = {1, 0.82, 0, 1}
		},
		-- Coordinates
		coords = {
			enabled = true,
			scale = 1,
			size = {80, 12},
			position = 'BOTTOM,BorderTop,BOTTOM,-5,3',
			color = {1, 1, 1, 1},
			format = '%.1f, %.1f'
		},
		-- Zoom Buttons
		zoomButtons = {
			enabled = false,
			scale = 1
		},
		-- Clock
		clock = {
			enabled = true,
			position = 'BOTTOMRIGHT,BorderTop,BOTTOMRIGHT,-10,0',
			scale = 1,
			format = '%I:%M %p',
			color = {1, 1, 1, 1}
		},
		-- Tracking Icon
		tracking = {
			enabled = true,
			position = 'BOTTOMLEFT,BorderTop,BOTTOMLEFT,2,1',
			scale = 1
		},
		-- Calendar Button
		calendarButton = {
			enabled = true,
			position = 'TOPRIGHT,BorderTop,TOPRIGHT,2,2',
			scale = 1
		},
		-- Mail Icon
		mailIcon = {
			enabled = true,
			position = 'LEFT,Tracking,RIGHT,2,0',
			scale = 1
		},
		-- Instance Difficulty
		instanceDifficulty = {
			enabled = true,
			position = 'RIGHT,BorderTop,LEFT,2,0',
			scale = 0.8
		},
		-- Queue Status (LFG eye)
		queueStatus = {
			enabled = true,
			position = 'BOTTOMLEFT,Minimap,BOTTOMLEFT,-15,45',
			scale = 0.85
		},
		--Expansion Button
		expansionButton = {
			position = 'BOTTOMLEFT,Minimap,BOTTOMLEFT,0,0',
			scale = 0.6
		},
		-- Addon Buttons
		addonButtons = {
			style = 'mouseover' -- 'always', 'mouseover', or 'never'
		}
	}
}

---@class SUI.Style.Settings.IMinimap : SUI.Style.Settings.Minimap
local BaseSettingsClassic = {
	-- Top-level settings
	shape = 'circle',
	size = {140, 140},
	scaleWithArt = true,
	UnderVehicleUI = true,
	position = 'TOPRIGHT,UIParent,TOPRIGHT,-20,-20',
	rotate = false,
	-- Elements (flat structure for Classic)
	background = {
		enabled = true,
		BlendMode = 'ADD',
		alpha = 1
	},
	ZoneText = {
		enabled = true,
		scale = 1,
		position = 'TOP,Minimap,BOTTOM,0,-4',
		color = {1, 0.82, 0, 1}
	},
	coords = {
		enabled = true,
		scale = 1,
		size = {80, 12},
		position = 'TOP,Minimap,BOTTOM,0,-20',
		color = {1, 1, 1, 1},
		format = '%.1f, %.1f'
	},
	zoomButtons = {
		enabled = false,
		scale = 1
	},
	clock = {
		enabled = false,
		scale = 0.7,
		position = 'TOP,Minimap,BOTTOM,0,-36',
		format = '%I:%M %p',
		color = {1, 1, 1, 1}
	},
	tracking = {
		enabled = true,
		scale = 1
	},
	mailIcon = {
		enabled = true,
		scale = 1
	},
	instanceDifficulty = {
		enabled = true,
		scale = 0.8
	},
	queueStatus = {
		enabled = true,
		scale = 0.85
	},
	addonButtons = {
		style = 'mouseover' -- 'always', 'mouseover', or 'never'
	}
}

local function IsMouseOver()
	for _, MouseFocus in ipairs(GetMouseFoci()) do
		if
			MouseFocus and not MouseFocus:IsForbidden() and
				((MouseFocus:GetName() == 'Minimap') or (MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find('Mini[Mm]ap')))
		 then
			return true
		end
	end

	return false
end

-- Check if Vehicle UI is actually active (not just in any vehicle)
local function IsVehicleUIActive()
	-- First check OverrideActionBar (most reliable)
	if OverrideActionBar and OverrideActionBar:IsVisible() then
		return true
	end

	-- Check if in vehicle AND has vehicle UI (excludes passengers, flight paths, etc)
	if UnitInVehicle('player') and UnitHasVehicleUI('player') then
		return true
	end

	-- Check possess bar (fallback for older content or edge cases)
	-- Note: PossessActionBar might not exist in all game versions
	if _G.PossessActionBar and _G.PossessActionBar:IsVisible() then
		return true
	end

	return false
end

-- Expose to module for options access
function module:IsVehicleUIActive()
	return IsVehicleUIActive()
end

-- Setup vehicle UI monitoring using the secure watcher frame
local function SetupVehicleUIMonitoring()
	-- Hook the watcher frame's visibility changes
	VehicleUIWatcher:HookScript(
		'OnHide',
		function()
			-- Vehicle UI is now active (frame is hidden when vehicle UI shows)
			if module.Settings and module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then
				module:SwitchMinimapPosition(true)
			end
		end
	)

	VehicleUIWatcher:HookScript(
		'OnShow',
		function()
			-- Vehicle UI is no longer active (frame is shown when vehicle UI hides)
			if module.Settings and module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then
				module:SwitchMinimapPosition(false)
			end
		end
	)
end

function module:Register(name, settings)
	Registry[name] = {settings = settings}
end

function module:UpdateSettings()
	module.Settings = nil
	-- Start with base settings (version-specific)
	---@type SUI.Style.Settings.IMinimap
	local baseSettings = SUI.IsRetail and BaseSettings or BaseSettingsClassic
	module.Settings = SUI:CopyData(baseSettings, {})

	-- Apply theme settings if available
	local currentStyle = module.styleOverride or SUI.DB.Artwork.Style
	if Registry[currentStyle] then
		module.Settings = SUI:MergeData(module.Settings, Registry[currentStyle].settings, true)
	end

	module.BaseOpt = SUI:CopyTable({}, module.Settings)
	-- Apply user custom settings
	if module.DB.customSettings[currentStyle] then
		SUI:MergeData(module.Settings, module.DB.customSettings[currentStyle], true)
	end

	-- Normalize settings structure for easier access
	-- Classic uses flat structure, Retail uses nested .elements
	if not SUI.IsRetail and module.Settings.elements then
		-- Convert retail structure to classic if needed
		for key, value in pairs(module.Settings.elements) do
			if not module.Settings[key] then module.Settings[key] = value end
		end
	end
end

function module:ModifyMinimapLayout()
	module:UpdateMinimapSize()
	module:UpdateMinimapShape()

	-- Modify basic Minimap properties (retail only)
	if Minimap.SetArchBlobRingScalar then
		Minimap:SetArchBlobRingScalar(0)
	end
	if Minimap.SetQuestBlobRingScalar then
		Minimap:SetQuestBlobRingScalar(0)
	end

	-- Modify MinimapCluster
	MinimapCluster:EnableMouse(false)

	-- Modify MinimapBackdrop
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetPoint('CENTER', Minimap, 'CENTER', -10, -24)
	MinimapBackdrop:SetFrameLevel(Minimap:GetFrameLevel())

	MinimapCompassTexture:Hide()

	-- BorderTop and ZoneTextButton positioning (retail only)
	if SUI.IsRetail then
		if MinimapCluster.BorderTop then
			MinimapCluster.BorderTop:ClearAllPoints()
			MinimapCluster.BorderTop:SetPoint('TOP', Minimap, 'BOTTOM', 0, -5)
			MinimapCluster.BorderTop:SetAlpha(0.8)
		end

		if MinimapCluster.ZoneTextButton and MinimapCluster.BorderTop then
			MinimapCluster.ZoneTextButton:ClearAllPoints()
			MinimapCluster.ZoneTextButton:SetPoint('TOPLEFT', MinimapCluster.BorderTop, 'TOPLEFT', 4, -4)
			MinimapCluster.ZoneTextButton:SetPoint('TOPRIGHT', MinimapCluster.BorderTop, 'TOPRIGHT', -15, -4)
		end
	else
		-- Classic-specific modifications
		-- Hide the toggle button
		if MinimapToggleButton then MinimapToggleButton:Hide() end

		-- Enable mousewheel zoom
		Minimap:EnableMouseWheel(true)
		Minimap:SetScript('OnMouseWheel', function(_, delta)
			if delta > 0 then
				Minimap_ZoomIn()
			else
				Minimap_ZoomOut()
			end
		end)

		-- Position Minimap inside SUIMinimap holder
		Minimap:ClearAllPoints()
		Minimap:SetPoint('TOPLEFT', SUIMinimap, 'TOPLEFT', 0, 0)

		-- Hide all border textures comprehensively
		if MinimapBorderTop then MinimapBorderTop:Hide() end
		if MinimapBorder then MinimapBorder:Hide() end
		if MinimapBackdrop then MinimapBackdrop:Hide() end

		-- Hide or show north tag based on settings
		if MinimapNorthTag then
			if module.Settings.rotate then
				MinimapNorthTag:Show()
			else
				MinimapNorthTag:Hide()
			end
		end

		-- Position GameTimeFrame if it exists
		if GameTimeFrame then
			GameTimeFrame:ClearAllPoints()
			GameTimeFrame:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 20, -16)
			GameTimeFrame:SetScale(0.7)
			GameTimeFrame:SetFrameLevel(122)
			GameTimeFrame:GetRegions():Hide()
		end

		-- Position MiniMapTracking
		if MiniMapTracking then
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, -5)
		end

		-- Position MiniMapInstanceDifficulty
		if MiniMapInstanceDifficulty then
			MiniMapInstanceDifficulty:ClearAllPoints()
			MiniMapInstanceDifficulty:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', 4, 22)
		end

		-- Position MiniMapWorldMapButton
		if MiniMapWorldMapButton then
			MiniMapWorldMapButton:ClearAllPoints()
			MiniMapWorldMapButton:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', -20, 12)
		end

		-- Position MiniMapMailFrame
		if MiniMapMailFrame then
			MiniMapMailFrame:ClearAllPoints()
			MiniMapMailFrame:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 21, -53)
		end

		-- Hide compass texture
		if MinimapCompassTexture then MinimapCompassTexture:Hide() end

		if MinimapCluster.BorderTop then MinimapCluster.BorderTop:Hide() end
	end

	-- Setup rotation if needed
	if MinimapCluster.SetRotateMinimap then
		if module.Settings.rotate then
			C_CVar.SetCVar('rotateMinimap', 1)
		end
	end
end

function module:UpdateMinimapSize()
	-- Set size of Minimap
	if module.Settings.size then
		Minimap:SetSize(unpack(module.Settings.size))
	end

	-- Set size of SUIMinimap (our holder)
	if SUI.IsRetail then
		-- Retail: Include BorderTop height
		local borderHeight = MinimapCluster.BorderTop and MinimapCluster.BorderTop:GetHeight() or 28
		SUIMinimap:SetSize(Minimap:GetWidth(), (Minimap:GetHeight() + borderHeight + 15))

		-- Set size of MinimapCluster BorderTop
		if MinimapCluster.BorderTop then
			MinimapCluster.BorderTop:SetWidth(Minimap:GetWidth() / 1.1)
			MinimapCluster.BorderTop:SetHeight(MinimapCluster.ZoneTextButton:GetHeight() * 2.8)
		end
	else
		-- Classic: Simpler calculation
		local extraHeight = 20
		-- Add space for coords if enabled
		if module.Settings.coords and module.Settings.coords.enabled then extraHeight = extraHeight + 15 end
		SUIMinimap:SetSize(Minimap:GetWidth(), Minimap:GetHeight() + extraHeight)
	end

	-- Update overlay texture positioning if it exists to prevent clipping
	if Minimap.overlay then
		Minimap.overlay:SetAllPoints(Minimap)
	end

	-- Force minimap to refresh and re-render after size changes
	-- We delay this slightly to ensure the size changes have taken effect
	C_Timer.After(
		0.1,
		function()
			module:UpdateMinimapShape()

			-- Force minimap refresh by triggering various update methods
			if Minimap.RefreshAll then
				Minimap:RefreshAll()
			end

			-- Force a zoom update to refresh the display
			local currentZoom = Minimap:GetZoom()
			if currentZoom > 0 then
				Minimap:SetZoom(currentZoom - 1)
				C_Timer.After(
					0.05,
					function()
						Minimap:SetZoom(currentZoom)
					end
				)
			end

			-- Trigger minimap update events if available
			if MinimapCluster.UpdateBlips then
				MinimapCluster:UpdateBlips()
			end

			-- Force texture coordinate refresh
			if GetCVar('rotateMinimap') == '1' then
				-- Temporarily toggle rotation to force refresh
				local rotate = module.Settings.rotate
				C_CVar.SetCVar('rotateMinimap', rotate and '0' or '1')
				C_Timer.After(
					0.05,
					function()
						C_CVar.SetCVar('rotateMinimap', rotate and '1' or '0')
					end
				)
			end
		end
	)
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
		if name then
			SUI:Error('Minimap', 'Position for ' .. name .. ' is bad. Please report this error along with an export of your minimap settings.')
		end
		return
	end
	local point, anchor, secondaryPoint, x, y = strsplit(',', position)
	if MinimapCluster[anchor] then
		anchor = MinimapCluster[anchor]
	elseif type(anchor) == 'string' and not _G[anchor] then
		-- Anchor region doesn't exist (Classic compatibility), fall back to Minimap
		anchor = Minimap
	end

	obj:ClearAllPoints()
	obj:SetPoint(point, anchor, secondaryPoint, x, y)
end

function module:SetupBackground()
	if module.Settings.elements.background.enabled then
		if not SUIMinimap.BG then
			SUIMinimap.BG = SUIMinimap:CreateTexture(nil, 'BACKGROUND', nil, -8)
		end

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
	local zoomSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.zoomButtons or module.Settings.zoomButtons
	if not zoomSettings then return end

	-- Check for zoom buttons (different names in different versions)
	local zoomIn = Minimap.ZoomIn or MinimapZoomIn
	local zoomOut = Minimap.ZoomOut or MinimapZoomOut
	if not zoomIn or not zoomOut then return end

	if zoomSettings.enabled then
		zoomIn:Show()
		zoomOut:Show()
		zoomIn:SetScale(zoomSettings.scale or 1)
		zoomOut:SetScale(zoomSettings.scale or 1)
	else
		zoomIn:Hide()
		zoomOut:Hide()
	end
end

function module:SetupZoneText()
	local zoneSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.ZoneText or module.Settings.ZoneText
	if not zoneSettings then return end

	if not SUI.IsRetail then
		-- Classic: Create custom zone text display below minimap
		if zoneSettings.enabled then
			if not Minimap.ZoneText then
				Minimap.ZoneText = Minimap:CreateFontString(nil, 'OVERLAY')
				SUI.Font:Format(Minimap.ZoneText, 11, 'Minimap')
				Minimap.ZoneText:SetJustifyH('CENTER')
				Minimap.ZoneText:SetJustifyV('MIDDLE')
			end

			if zoneSettings.position then module:PositionItem(Minimap.ZoneText, zoneSettings.position) end

			local color = zoneSettings.color or zoneSettings.TextColor
			if color then Minimap.ZoneText:SetTextColor(unpack(color)) end
			Minimap.ZoneText:SetShadowColor(0, 0, 0, 1)
			Minimap.ZoneText:SetScale(zoneSettings.scale or 1)
			Minimap.ZoneText:Show()

			-- Hide default zone text button and use our custom one
			if MinimapZoneTextButton then
				MinimapZoneTextButton:SetAlpha(0)
				MinimapZoneTextButton:EnableMouse(false)
			end

			-- Update zone text immediately
			module:UpdateClassicZoneText()
		elseif Minimap.ZoneText then
			Minimap.ZoneText:Hide()
			-- Restore default zone text
			if MinimapZoneTextButton then
				MinimapZoneTextButton:SetAlpha(1)
				MinimapZoneTextButton:EnableMouse(true)
			end
		end
	else
		-- Retail: Use standard ZoneTextButton
		local zoneButton = MinimapCluster.ZoneTextButton
		if not zoneButton then return end

		if zoneSettings.enabled then
			if zoneSettings.position then module:PositionItem(zoneButton, zoneSettings.position) end

			if MinimapZoneText then
				local color = zoneSettings.color or zoneSettings.TextColor
				if color then MinimapZoneText:SetTextColor(unpack(color)) end
				MinimapZoneText:SetShadowColor(0, 0, 0, 1)
				SUI.Font:Format(MinimapZoneText, 10, 'Minimap')
				MinimapZoneText:SetJustifyH('CENTER')
			end

			zoneButton:SetScale(zoneSettings.scale or 1)
			zoneButton:Show()
		else
			zoneButton:Hide()
		end
	end
end

function module:UpdateClassicZoneText()
	if SUI.IsRetail or not Minimap.ZoneText or not Minimap.ZoneText:IsShown() then return end

	-- Get zone text and update our custom display
	local zoneText = GetMinimapZoneText()
	if zoneText then Minimap.ZoneText:SetText(zoneText) end
end

function module:SetupCoords()
	local coordSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.coords or module.Settings.coords
	if not coordSettings then return end

	if coordSettings.enabled then
		if not Minimap.coords then Minimap.coords = Minimap:CreateFontString(nil, 'OVERLAY') end
		SUI.Font:Format(Minimap.coords, 10, 'Minimap')

		-- For Classic/TBC, if ZoneText exists, position relative to it instead of using the position string
		if not SUI.IsRetail and Minimap.ZoneText and Minimap.ZoneText:IsShown() then
			Minimap.coords:ClearAllPoints()
			Minimap.coords:SetPoint('TOP', Minimap.ZoneText, 'BOTTOM', 0, -4)
		elseif coordSettings.position then
			module:PositionItem(Minimap.coords, coordSettings.position)
		end

		local color = coordSettings.color or coordSettings.TextColor
		if color then Minimap.coords:SetTextColor(unpack(color)) end
		Minimap.coords:SetShadowColor(0, 0, 0, 1)
		Minimap.coords:SetScale(coordSettings.scale or 1)

		if coordSettings.size then Minimap.coords:SetSize(unpack(coordSettings.size)) end
		Minimap.coords:SetJustifyH('CENTER')
		Minimap.coords:Show()
		module:SetupCoordinatesUpdater()
	elseif Minimap.coords then
		Minimap.coords:Hide()
	end
end

function module:SetupCoordinatesUpdater()
	if self.coordsTimer then
		return
	end

	self.coordsTimer =
		self:ScheduleRepeatingTimer(
		function()
			local mapID = C_Map.GetBestMapForUnit('player')
			if not mapID then
				return
			end
			local pos = C_Map.GetPlayerMapPosition(mapID, 'player')
			if not pos then
				return
			end
			if pos.x and pos.y then
				local coordSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.coords or module.Settings.coords
				local format = coordSettings and coordSettings.format or '%.1f, %.1f'
				Minimap.coords:SetText(string.format(format, pos.x * 100, pos.y * 100))
			end
		end,
		0.5
	)
end

function module:SetupClock()
	local clockSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.clock or module.Settings.clock
	if not clockSettings or not clockSettings.enabled then
		if TimeManagerClockButton then TimeManagerClockButton:Hide() end
		if GameTimeFrame then GameTimeFrame:Hide() end
		return
	end

	if not GameTimeFrame then
		-- Retail: TimeManagerClockButton
		if not TimeManagerClockButton then C_AddOns.LoadAddOn('Blizzard_TimeManager') end
		if TimeManagerClockButton then
			TimeManagerClockButton:ClearAllPoints()
			if clockSettings.position then module:PositionItem(TimeManagerClockButton, clockSettings.position) end
			TimeManagerClockButton:SetScale(clockSettings.scale or 1)
			if TimeManagerClockTicker and clockSettings.color then
				TimeManagerClockTicker:SetTextColor(unpack(clockSettings.color))
				SUI.Font:Format(TimeManagerClockTicker, 10, 'Minimap')
			end
			TimeManagerClockButton:Show()
		end
	else
		-- Classic: GameTimeFrame is positioned in ModifyMinimapLayout
		-- Just ensure it's visible and scaled
		if GameTimeFrame then
			GameTimeFrame:SetScale(clockSettings.scale or 0.7)
			GameTimeFrame:Show()
		end
	end
end

function module:SetupMailIcon()
	local mailSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.mailIcon or module.Settings.mailIcon
	if not mailSettings then return end

	-- Get mail frame - different in Retail vs Classic
	local mailFrame
	if SUI.IsRetail then
		mailFrame = MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame
	else
		mailFrame = MiniMapMailFrame
	end

	if not mailFrame then return end

	if mailSettings.enabled then
		mailFrame:ClearAllPoints()
		if mailSettings.position then module:PositionItem(mailFrame, mailSettings.position) end
		mailFrame:SetScale(mailSettings.scale or 1)
		mailFrame:Show()
	else
		mailFrame:Hide()
	end
end

function module:SetupTracking()
	local trackingSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.tracking or module.Settings.tracking
	if not trackingSettings then return end

	-- Get tracking frame - different in Retail vs Classic
	local tracking
	if SUI.IsRetail then
		tracking = MinimapCluster.TrackingFrame or MinimapCluster.Tracking
	else
		tracking = MiniMapTracking
	end

	if not tracking then return end

	if trackingSettings.enabled then
		tracking:ClearAllPoints()
		if trackingSettings.position then module:PositionItem(tracking, trackingSettings.position) end
		tracking:SetScale(trackingSettings.scale or 1)

		-- Hide background if it exists (Retail)
		if tracking.Background then tracking.Background:Hide() end

		tracking:Show()
	else
		tracking:Hide()
	end
end

function module:SetupCalendarButton()
	if not SUI.IsRetail then return end -- Calendar button is Retail-only

	local calendarSettings = module.Settings.elements and module.Settings.elements.calendarButton
	if not calendarSettings then return end

	if calendarSettings.enabled and GameTimeFrame then
		GameTimeFrame:ClearAllPoints()
		if calendarSettings.position then module:PositionItem(GameTimeFrame, calendarSettings.position) end
		GameTimeFrame:SetScale(calendarSettings.scale or 1)
		GameTimeFrame:Show()
	elseif GameTimeFrame then
		GameTimeFrame:Hide()
	end
end

function module:SetupInstanceDifficulty()
	local difficultySettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.instanceDifficulty or module.Settings.instanceDifficulty
	if not difficultySettings then return end

	-- Get instance difficulty frame - different in Retail vs Classic
	local difficulty
	if SUI.IsRetail then
		difficulty = MinimapCluster.InstanceDifficulty
	else
		difficulty = MiniMapInstanceDifficulty
	end

	if not difficulty then return end

	if difficultySettings.enabled then
		difficulty:ClearAllPoints()
		if difficultySettings.position then module:PositionItem(difficulty, difficultySettings.position) end
		difficulty:SetScale(difficultySettings.scale or 0.8)
		difficulty:Show()
	else
		difficulty:Hide()
	end
end

function module:SetupQueueStatus()
	local queueSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.queueStatus or module.Settings.queueStatus
	if not queueSettings then return end

	-- Get queue/battlefield frame - different in Retail vs Classic
	local queueFrame
	if SUI.IsRetail then
		queueFrame = QueueStatusButton
	else
		queueFrame = MiniMapBattlefieldFrame
	end

	if not queueFrame then return end

	if queueSettings.enabled then
		queueFrame:ClearAllPoints()
		if queueSettings.position then module:PositionItem(queueFrame, queueSettings.position) end
		queueFrame:SetScale(queueSettings.scale or 0.85)
	end
end

function module:SetupExpansionButton()
	if not SUI.IsRetail then return end -- Expansion button is Retail-only
	if not ExpansionLandingPageMinimapButton then return end

	ExpansionLandingPageMinimapButton:SetScale(module.Settings.elements.expansionButton.scale)
	module:PositionItem(ExpansionLandingPageMinimapButton, module.Settings.elements.expansionButton.position)
	-- Note: Right-click functionality is now handled by the ExpandedExpansionButton module
	-- This keeps the default left-click behavior intact
end

local isFrameIgnored = function(item)
	local ignored = {'HybridMinimap', 'AAP-Classic', 'HandyNotes'}
	local WildcardIgnore = {'Questie', 'HandyNotes', 'TTMinimap'}
	if not item or not item.GetName then
		return false
	end

	local name = item:GetName()
	if name ~= nil then
		if SUI:IsInTable(ignored, name) then
			return true
		end

		for _, v in ipairs(WildcardIgnore) do
			if string.match(name, v) then
				return true
			end
		end
	end
	return false
end

function module:SetupAddonButtons()
	local function setupButtonFading(button)
		local name = button:GetName()
		if isFrameIgnored(name) then
			print('ignore me!' .. name)
		end
		if button.fadeInAnim then
			return
		end -- Already set up

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
		for _, child in ipairs({Minimap:GetChildren()}) do
			if child:IsObjectType('Button') and child.fadeInAnim then
				child.fadeInAnim:Stop()
				child.fadeOutAnim:Stop()
				child:SetAlpha(1)
			end
		end
	end

	local function hideAllButtons()
		for _, child in ipairs({Minimap:GetChildren()}) do
			if child:IsObjectType('Button') and child.fadeOutAnim then
				child.fadeInAnim:Stop()
				child.fadeOutAnim:Play()
			end
		end
	end

	-- Set up fading for existing buttons
	for _, child in ipairs({Minimap:GetChildren()}) do
		if child:IsObjectType('Button') then
			setupButtonFading(child)
			child:HookScript('OnEnter', showAllButtons)
			child:HookScript('OnLeave', hideAllButtons)
		end
	end

	-- Hook the Minimap to catch newly added buttons
	Minimap:HookScript(
		'OnEvent',
		function(self, event, ...)
			if event == 'ADDON_LOADED' then
				C_Timer.After(
					0.1,
					function()
						for _, child in ipairs({self:GetChildren()}) do
							if child:IsObjectType('Button') and not child.fadeInAnim and not isFrameIgnored(child) then
								setupButtonFading(child)
								child:HookScript('OnEnter', showAllButtons)
								child:HookScript('OnLeave', hideAllButtons)
							end
						end
					end
				)
			end
		end
	)
	Minimap:RegisterEvent('ADDON_LOADED')

	-- Hook the Minimap itself for mouse events
	Minimap:HookScript('OnEnter', showAllButtons)
	Minimap:HookScript('OnLeave', hideAllButtons)
end

function module:UpdateAddonButtons()
	local addonSettings = SUI.IsRetail and module.Settings.elements and module.Settings.elements.addonButtons or module.Settings.addonButtons
	if not addonSettings then return end

	local style = addonSettings.style or 'mouseover'
	if style == 'always' then
		for _, child in ipairs({Minimap:GetChildren()}) do
			if child:IsObjectType('Button') and not isFrameIgnored(child) then
				child:SetAlpha(1)
			end
		end
	elseif style == 'never' then
		for _, child in ipairs({Minimap:GetChildren()}) do
			if child:IsObjectType('Button') and not isFrameIgnored(child) then
				child:SetAlpha(0)
			end
		end
	else -- "mouseover"
		-- The showing/hiding is handled by the OnEnter/OnLeave scripts
		for _, child in ipairs({Minimap:GetChildren()}) do
			if child:IsObjectType('Button') and not isFrameIgnored(child) then
				child:SetAlpha(0) -- Start hidden
			end
		end
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
	Minimap:HookScript(
		'OnShow',
		function()
			SUIMinimap:Show()
		end
	)
	Minimap:HookScript(
		'OnHide',
		function()
			SUIMinimap:Hide()
		end
	)

	SUIMinimap:HookScript(
		'OnEnter',
		function()
			IsMouseOver()
		end
	)
	SUIMinimap:HookScript(
		'OnLeave',
		function()
			IsMouseOver()
		end
	)
end

function module:RegisterEvents()
	MinimapUpdater:SetScript(
		'OnEvent',
		function(self, event)
			if not InCombatLockdown() then
				module:ScheduleTimer(module.Update, 2, module, true)
			end

			-- Update zone text on zone changes for Classic
			if not SUI.IsRetail and (event == 'ZONE_CHANGED' or event == 'ZONE_CHANGED_INDOORS' or event == 'ZONE_CHANGED_NEW_AREA') then
				module:UpdateClassicZoneText()
			end
		end
	)
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
	if SUI:IsModuleDisabled('Minimap') then
		return
	end

	module:UpdateSettings()

	-- Apply settings to elements
	module:SetupBackground()
	module:SetupZoneText()
	module:SetupCoords()
	module:SetupClock()
	module:SetupMailIcon()
	module:SetupTracking()
	module:SetupInstanceDifficulty()
	module:SetupQueueStatus()
	module:UpdateAddonButtons()
	module:UpdateMinimapShape()
	module:UpdateMinimapSize()
	module:SetupZoomButtons()

	-- Classic-specific updates
	if not SUI.IsRetail then module:UpdateClassicZoneText() end

	-- Retail-only elements
	if SUI.IsRetail then
		module:SetupCalendarButton()
		module:SetupExpansionButton()

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
	-- MinimapContainer only exists in Retail, not Classic
	if MinimapCluster.MinimapContainer then
		MinimapCluster.MinimapContainer:ClearAllPoints()
		MinimapCluster.MinimapContainer:SetPoint('TOPLEFT', SUIMinimap, 'TOPLEFT', -30, 32)
	end
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
	if not SUI.IsRetail then return end -- Vehicle mover is Retail-only

	-- Create the vehicle mover with our new reusable function
	local borderHeight = 0
	if MinimapCluster.BorderTop then
		borderHeight = MinimapCluster.BorderTop:GetHeight()
	end

	VehicleMover =
		SUI.MoveIt:CreateCustomMover(
		'Vehicle Minimap Position',
		module.Settings.vehiclePosition,
		{
			width = Minimap:GetWidth(),
			height = (Minimap:GetHeight() + borderHeight + 15),
			savePosition = function(position)
				module.Settings.vehiclePosition = position

				-- Save to user settings
				local currentStyle = SUI.DB.Artwork.Style
				if not module.DB.customSettings[currentStyle] then
					module.DB.customSettings[currentStyle] = {}
				end
				module.DB.customSettings[currentStyle].vehiclePosition = position
			end
		}
	)

	VehicleMover.target = SUIMinimap

	-- Register for vehicle events
	module:RegisterEvent('UNIT_ENTERED_VEHICLE', 'OnVehicleChange')
	module:RegisterEvent('UNIT_EXITED_VEHICLE', 'OnVehicleChange')
	module:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckVehicleStatus')
	-- OnZone change
	module:RegisterEvent(
		'ZONE_CHANGED_NEW_AREA',
		function()
			module:ScheduleTimer(module.CheckOverrideActionBar, 0.2)
		end
	)

	-- Check if OverrideActionBar exists and is visible
	module:RegisterEvent('UPDATE_OVERRIDE_ACTIONBAR', 'CheckOverrideActionBar')
end

-- Show the vehicle minimap mover
function module:VehicleUIMoverShow()
	if InCombatLockdown() then
		return
	end

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
	if module.DB.customSettings[currentStyle] then
		module.DB.customSettings[currentStyle].vehiclePosition = nil
	end

	SUI:Print(L['Vehicle minimap position reset to default'])
end

-- Handle vehicle state changes
function module:OnVehicleChange(event, unit)
	if unit ~= 'player' then
		return
	end

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
		if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then
			module:SwitchMinimapPosition(true)
		end
	elseif event == 'UNIT_EXITED_VEHICLE' then
		-- Restore normal position
		if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then
			module:SwitchMinimapPosition(false)
		end
	end
end

-- Check vehicle status on login or reload
function module:CheckVehicleStatus()
	if not (module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false) then
		return
	end

	if IsVehicleUIActive() then
		module:SwitchMinimapPosition(true)
	else
		module:SwitchMinimapPosition(false)
	end
end

-- Check for OverrideActionBar visibility changes
function module:CheckOverrideActionBar()
	C_Timer.After(
		0.5,
		function()
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
						preferredIndex = 3
					}

					StaticPopup_Show('SUI_MINIMAP_VEHICLE_POSITION')
				end

				if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then
					module:SwitchMinimapPosition(true)
				end
			else
				if module.Settings.UnderVehicleUI and module.Settings.useVehicleMover ~= false then
					module:SwitchMinimapPosition(false)
				end
			end
		end
	)
end

function module:OnInitialize()
	---@class SUI.Minimap.Database
	local defaults = {
		enabled = true,
		style = 'Default',
		customSettings = {
			['**'] = {
				['**'] = {
					['**'] = {}
				}
			}
		},
		AutoDetectAllowUse = true,
		ManualAllowUse = false
	}

	module.Database = SUI.SpartanUIDB:RegisterNamespace('Minimap', {profile = defaults})
	module.DB = module.Database.profile ---@type SUI.Minimap.Database

	-- Initialize the settings
	module:UpdateSettings()

	-- Check for other addons modifying the minimap
	module:DetectMinimapAddons()

	if C_CVar.GetCVar('rotateMinimap') == '1' and not module.DB.customSettings[SUI.DB.Artwork.Style].rotate then
		module.DB.customSettings[SUI.DB.Artwork.Style].rotate = true
	end
end

function module:DetectMinimapAddons()
	local conflictingAddons = {
		['SexyMap'] = 'SexyMap',
		['Carbonite'] = NXTITLELOW
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

	if not module.DB.AutoDetectAllowUse and not module.DB.ManualAllowUse then
		StaticPopup_Show('MiniMapNotice')
	end
end

function module:OnEnable()
	if SUI:IsModuleDisabled('Minimap') then
		return
	end

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

	-- Retail-only features
	if SUI.IsRetail then
		module:InitializeVehicleMover()

		SUI:AddChatCommand(
			'vehicleminimap',
			function()
				if VehicleMover:IsShown() then
					module:VehicleUIMoverHide()
				else
					module:VehicleUIMoverShow()
				end
			end,
			L['Toggle vehicle minimap mover']
		)
	end

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
		SUI:SafeReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false
}

SUI.Minimap = module
