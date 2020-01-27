local SUI, L, print = SUI, SUI.L, SUI.print
local module = SUI:NewModule('Component_Minimap')
local MoveIt, Settings
local UserSettings = SUI.DB.MiniMap
----------------------------------------------------------------------------------------------------
local ChangesTimer = nil
local MinimapUpdater = CreateFrame('Frame')
local SUI_MiniMapIcon
local IgnoredFrames = {}
local LastUpdateStatus = nil
local IsMouseDown = false

local IsMouseOver = function()
	local MouseFocus = GetMouseFocus()
	if
		MouseFocus and not MouseFocus:IsForbidden() and
			((MouseFocus:GetName() == 'Minimap') or
				(MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find('Mini[Mm]ap')))
	 then
		UserSettings.MouseIsOver = true
	else
		UserSettings.MouseIsOver = false
	end
	return UserSettings.MouseIsOver
end

local isFrameIgnored = function(item)
	if item:GetName() ~= nil then
		if string.match(item:GetName(), 'Questie') then
			return true
		elseif string.match(item:GetName(), 'AAP-Classic') then
			return true
		elseif string.match(item:GetName(), 'HandyNotes') then
			return true
		end
	end
	return false
end

local MiniMapBtnScrape = function()
	-- Hook Minimap Icons
	for _, child in ipairs({Minimap:GetChildren()}) do
		if child.FadeIn == nil and not isFrameIgnored(child) then
			module:SetupButton(child)
		end
	end
	if CensusButton ~= nil and CensusButton.FadeIn == nil then
		module:SetupButton(CensusButton)
	end
	if GameTimeFrame then
		module:SetupButton(GameTimeFrame)
	end
end

local PerformFullBtnUpdate = function()
	if LastUpdateStatus ~= IsMouseOver() then
		MiniMapBtnScrape()
		--update visibility
		module:update()
	end
end

local OnEnter = function()
	if UserSettings.MouseIsOver then
		return
	end
	--don't use PerformFullBtnUpdate as we want to perform the actions in reverse. since any new unknown icons will already be shown.
	if LastUpdateStatus ~= IsMouseOver() then
		module:update()
	end --update visibility
	MiniMapBtnScrape()
end

local OnLeave = function()
	local i = 1.5 -- Default wait time before updating button location

	if IsMouseDown then
		-- A mouse button was clicked on lets give some extra time incase the user is moving the button.
		IsMouseDown = false
		i = 10
	end

	-- Set a timer to check that the mouse actually left and we did not just mouse away for a second
	-- Overwrite if we are giving extra time
	if ChangesTimer == nil or i == 10 then
		ChangesTimer = C_Timer.After(i, PerformFullBtnUpdate)
	end
end

local OnMouseDown = function()
	IsMouseDown = true
end

local function UpdatePosition()
	-- Position map based on Artwork
	if SUI.DB.EnabledComponents.Artwork and Settings.position and not MoveIt:IsMoved('Minimap') then
		local point, anchor, secondaryPoint, x, y = strsplit(',', Settings.position)
		if Minimap.position then
			Minimap:position(point, anchor, secondaryPoint, x, y)
		else
			Minimap:ClearAllPoints()
			Minimap:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	end
end

function module:ShapeChange(shape)
	if not SUI.DB.EnabledComponents.Minimap then
		return
	end

	if shape == 'square' then
		Minimap:SetMaskTexture('Interface\\BUTTONS\\WHITE8X8')
		if MiniMapTracking then
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, 5)
		end
	else
		Minimap:SetMaskTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\circle-overlay')
		if MiniMapTracking then
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, -5)
		end
	end

	if Settings.size then
		Minimap:SetSize(unpack(Settings.size))
	end

	Minimap.ZoneText:ClearAllPoints()
	if Settings.TextLocation == 'TOP' then
		Minimap.ZoneText:SetPoint('BOTTOMLEFT', Minimap, 'TOPLEFT', 0, 4)
		Minimap.ZoneText:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT', 0, 4)
	else
		Minimap.ZoneText:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -4)
		Minimap.ZoneText:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -4)
	end

	Minimap.coords:ClearAllPoints()
	if
		(Settings.coordsLocation == 'TOP' and Settings.TextLocation == 'TOP') or
			(Settings.coordsLocation == 'BOTTOM' and Settings.TextLocation == 'BOTTOM')
	 then
		Minimap.coords:SetPoint('TOPLEFT', Minimap.ZoneText, 'BOTTOMLEFT', 0, -4)
		Minimap.coords:SetPoint('TOPRIGHT', Minimap.ZoneText, 'BOTTOMRIGHT', 0, -4)
	elseif Settings.TextLocation == 'TOP' and Settings.coordsLocation == 'BOTTOM' then
		Minimap.coords:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -4)
		Minimap.coords:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -4)
	elseif Settings.TextLocation == 'BOTTOM' and Settings.coordsLocation == 'TOP' then
		Minimap.coords:SetPoint('BOTTOMLEFT', Minimap, 'TOPLEFT', 0, 4)
		Minimap.coords:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT', 0, 4)
	end

	MinimapZoneText:SetShadowColor(0, 0, 0, 1)
	MinimapZoneText:SetShadowOffset(1, -1)
end

function module:OnInitialize()
	MoveIt = SUI:GetModule('Component_MoveIt')
	StaticPopupDialogs['MiniMapNotice'] = {
		text = '|cff33ff99SpartanUI Notice|n|r|n Another addon has been found modifying the minimap. Do you give permisson for SpartanUI to move and possibly modify the minimap as your theme dictates? |n|n You can change this option in the settings should you change your mind.',
		button1 = 'Yes',
		button2 = 'No',
		OnAccept = function()
			UserSettings.ManualAllowPrompt = SUI.DB.Version
			UserSettings.ManualAllowUse = true
			ReloadUI()
		end,
		OnCancel = function()
			UserSettings.ManualAllowPrompt = SUI.DB.Version
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	Settings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].Minimap
end

function module:OnEnable()
	if ((not UserSettings.AutoDetectAllowUse) and UserSettings.ManualAllowPrompt ~= SUI.DB.Version) then
		StaticPopup_Show('MiniMapNotice')
	end
	if not SUI.DB.EnabledComponents.Minimap then
		return
	end
	Settings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].Minimap

	-- MiniMap Modification
	Minimap:SetFrameLevel(120)
	Minimap.Background = Minimap:CreateTexture(nil, 'BACKGROUND')
	if SUI.IsRetail then
		Minimap:SetArchBlobRingScalar(0)
		Minimap:SetQuestBlobRingScalar(0)
	end
	module:ModifyMinimapLayout()

	--Look for existing buttons
	MiniMapBtnScrape()

	Minimap:HookScript('OnEnter', OnEnter)
	Minimap:HookScript('OnLeave', OnLeave)
	Minimap:HookScript('OnMouseDown', OnMouseDown)

	--Initialize Buttons & Style settings
	module:update()

	-- Setup Updater script for button visibility updates
	MinimapUpdater:SetSize(1, 1)
	MinimapUpdater:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', -128, 128)
	MinimapUpdater:SetScript(
		'OnEvent',
		function()
			if not InCombatLockdown() then
				if ChangesTimer == nil then
					ChangesTimer = C_Timer.After(2, PerformFullBtnUpdate)
				end
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

	-- Position map based on Artwork
	UpdatePosition()

	-- Setup inital shape
	module:ShapeChange(Settings.shape)

	-- Make map movable
	MoveIt:CreateMover(Minimap, 'Minimap')

	-- If we didint move the minimap before making the mover make sure default is set.
	if MoveIt:IsMoved('Minimap') then
		Minimap.mover.defaultPoint = Settings.position
	end

	-- Construct options
	module:BuildOptions()
end

function module:ModifyMinimapLayout()
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript(
		'OnMouseWheel',
		function(self, delta)
			if (delta > 0) then
				Minimap_ZoomIn()
			else
				Minimap_ZoomOut()
			end
		end
	)

	if Settings.shape == 'square' then
		-- Set Map Mask
		function GetMinimapShape()
			return 'SQUARE'
		end

		Minimap:SetMaskTexture('Interface\\BUTTONS\\WHITE8X8')

		if SUI.IsRetail then
			Minimap:SetArchBlobRingScalar(0)
			Minimap:SetQuestBlobRingScalar(0)
		end

		Minimap.overlay = Minimap:CreateTexture(nil, 'OVERLAY')
		Minimap.overlay:SetTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\square-overlay')
		Minimap.overlay:SetAllPoints(Minimap)
		Minimap.overlay:SetBlendMode('ADD')

		MinimapZoneTextButton:SetPoint('BOTTOMLEFT', Minimap, 'TOPLEFT', 0, 4)
		MinimapZoneTextButton:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT', 0, 4)
		MinimapZoneText:SetShadowColor(0, 0, 0, 1)
		MinimapZoneText:SetShadowOffset(1, -1)

		if SUI.IsRetail then
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', 0, 0)
		end
	else
		Minimap:SetMaskTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\circle-overlay')

		if SUI.IsRetail then
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, -5)
		end
	end

	-- Retail Version stuff
	if SUI.IsRetail then
		TimeManagerClockButton:GetRegions():Hide() -- Hide the border
		TimeManagerClockButton:SetBackdrop(nil)
		TimeManagerClockButton:ClearAllPoints()
		TimeManagerClockButton:SetPoint('TOP', Minimap, 'BOTTOM', 0, 20)
		TimeManagerClockButton:SetBackdropColor(0, 0, 0, 1)
		TimeManagerClockButton:SetBackdropBorderColor(0, 0, 0, 1)

		MiniMapInstanceDifficulty:ClearAllPoints()
		MiniMapInstanceDifficulty:SetPoint('TOPLEFT', Minimap, 4, 22)

		GuildInstanceDifficulty:ClearAllPoints()
		GuildInstanceDifficulty:SetPoint('TOPLEFT', Minimap, 4, 22)

		GarrisonLandingPageMinimapButton:ClearAllPoints()
		GarrisonLandingPageMinimapButton:SetSize(35, 35)
		GarrisonLandingPageMinimapButton:SetPoint('RIGHT', Minimap, 18, -25)

		SUI_MiniMapIcon = CreateFrame('Button', 'SUI_MiniMapIcon', Minimap)
		SUI_MiniMapIcon:SetSize(1, 1)
		SUI_MiniMapIcon:SetScript(
			'OnEvent',
			function(self, event, ...)
				GarrisonLandingPageMinimapButton:Show()
				GarrisonLandingPageMinimapButton:SetAlpha(1)
			end
		)
		SUI_MiniMapIcon:RegisterEvent('GARRISON_MISSION_FINISHED')
		SUI_MiniMapIcon:RegisterEvent('GARRISON_INVASION_AVAILABLE')
		SUI_MiniMapIcon:RegisterEvent('SHIPMENT_UPDATE')
	end

	-- Attach Minimap Backdrop to the minimap it's self
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetPoint('CENTER', Minimap, 'CENTER', -10, -24)
	MinimapBackdrop:SetFrameLevel(Minimap:GetFrameLevel())

	-- Hide Blizzard Artwork
	MinimapBorderTop:Hide()
	MinimapBorder:Hide()
	if MinimapToggleButton then
		MinimapToggleButton:Hide()
	end
	if not UserSettings.northTag then
		MinimapNorthTag:Hide()
	else
		MinimapNorthTag:Show()
	end

	-- Do modifications to MiniMapWorldMapButton
	-- remove current textures
	MiniMapWorldMapButton:SetNormalTexture(nil)
	MiniMapWorldMapButton:SetPushedTexture(nil)
	MiniMapWorldMapButton:SetHighlightTexture(nil)
	-- Create new textures
	MiniMapWorldMapButton:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\WorldMap-Icon.png')
	MiniMapWorldMapButton:SetPushedTexture('Interface\\AddOns\\SpartanUI\\images\\WorldMap-Icon-Pushed.png')
	MiniMapWorldMapButton:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
	MiniMapWorldMapButton:ClearAllPoints()
	MiniMapWorldMapButton:SetPoint('TOPRIGHT', Minimap, -20, 12)

	MiniMapMailFrame:ClearAllPoints()
	MiniMapMailFrame:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 21, -53)

	if GameTimeFrame then
		GameTimeFrame:ClearAllPoints()
		GameTimeFrame:SetScale(.7)
		GameTimeFrame:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 20, -16)
		GameTimeFrame:SetFrameLevel(122)
	end

	module:MinimapCoords()
	MinimapZoneText:ClearAllPoints()
	MinimapZoneText:SetAllPoints(MinimapZoneTextButton)
end

function module:MinimapCoords()
	if not SUI.DB.EnabledComponents.Minimap then
		return
	end
	MinimapZoneText:Hide()

	Minimap.ZoneText = Minimap:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(Minimap.ZoneText, 11, 'Minimap')
	SUI:FormatFont(MinimapZoneText, 11, 'Minimap')
	Minimap.ZoneText:SetSize(10, 12)
	Minimap.ZoneText:SetJustifyH('MIDDLE')
	Minimap.ZoneText:SetJustifyV('CENTER')
	Minimap.ZoneText:SetPoint('BOTTOMLEFT', Minimap, 'TOPLEFT', 0, 1)
	Minimap.ZoneText:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT', 0, 1)
	Minimap.ZoneText:SetShadowColor(0, 0, 0, 1)
	Minimap.ZoneText:SetShadowOffset(1, -1)

	MinimapZoneText:ClearAllPoints()
	MinimapZoneText:SetAllPoints(Minimap.ZoneText)
	MinimapZoneTextButton:ClearAllPoints()
	MinimapZoneTextButton:SetAllPoints(Minimap.ZoneText)

	Minimap.coords = Minimap:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(Minimap.coords, 9, 'Minimap')
	Minimap.coords:SetSize(9, 12)
	Minimap.coords:SetJustifyH('TOP')
	Minimap.coords:SetPoint('TOPLEFT', Minimap.ZoneText, 'BOTTOMLEFT', 0, 0)
	Minimap.coords:SetPoint('TOPRIGHT', Minimap.ZoneText, 'BOTTOMRIGHT', 0, 0)
	Minimap.coords:SetShadowOffset(1, -1)

	local Timer = C_Timer.After
	local function UpdateCoords()
		--New Timer
		Timer(0.2, UpdateCoords)
		--Get the Map we are on
		local mapID = C_Map.GetBestMapForUnit('player')
		if (not mapID) then
			return
		end
		-- Get the Cords we are at for said map
		-- C_Map.GetPlayerMapPosition has to be nil checked for as GetXY is defined if off the edge of the map
		-- Notibly this causes errors on the [The Stormwind Extraction] (BFA Horde start quest)
		local MapPos = C_Map.GetPlayerMapPosition(mapID, 'player')
		if (not MapPos) then
			return
		end
		local x, y = MapPos:GetXY()
		if (not x) or (not y) then
			return
		end
		--Update label
		-- Minimap.ZoneText:SetText(GetMinimapZoneText())
		Minimap.coords:SetText(format('%.1f, %.1f', x * 100, y * 100))
	end
	UpdateCoords()
end

function module:SetupButton(btn, force)
	--Avoid duplicates make sure it's not in the tracking table
	if btn.FadeIn == nil or force then
		-- Hook Mouse Events
		btn:HookScript('OnEnter', OnEnter)
		btn:HookScript('OnLeave', OnLeave)

		btn:HookScript('OnMouseDown', OnMouseDown)

		-- Add Fade in and out
		btn.FadeIn = btn:CreateAnimationGroup()
		local FadeIn = btn.FadeIn:CreateAnimation('Alpha')
		FadeIn:SetOrder(1)
		FadeIn:SetDuration(0.2)
		FadeIn:SetFromAlpha(0)
		FadeIn:SetToAlpha(1)
		btn.FadeIn:SetToFinalAlpha(true)

		btn.FadeOut = btn:CreateAnimationGroup()
		local FadeOut = btn.FadeOut:CreateAnimation('Alpha')
		FadeOut:SetOrder(1)
		FadeOut:SetDuration(0.3)
		FadeOut:SetFromAlpha(1)
		FadeOut:SetToAlpha(0)
		FadeOut:SetStartDelay(.5)
		btn.FadeOut:SetToFinalAlpha(true)

		--Hook into the buttons show and hide events to catch for the button being enabled/disabled
		btn:HookScript(
			'OnHide',
			function(self, event, ...)
				if not UserSettings.SUIMapChangesActive then
					table.insert(IgnoredFrames, self:GetName())
				end
			end
		)
		btn:HookScript(
			'OnShow',
			function(self, event, ...)
				for i = 1, table.getn(IgnoredFrames) do
					if IgnoredFrames[i] == btn:GetName() then
						table.remove(IgnoredFrames, i)
					end
				end
			end
		)
	end
end

function module:update()
	if not SUI.DB.EnabledComponents.Minimap then
		return
	end
	-- Refresh settings
	Settings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].Minimap

	-- UserSettings item visibility
	do
		if (UserSettings.MapZoomButtons) then
			MinimapZoomIn:Hide()
			MinimapZoomOut:Hide()
		else
			MinimapZoomIn:Show()
			MinimapZoomOut:Show()
		end

		if UserSettings.northTag then
			MinimapNorthTag:Show()
		else
			MinimapNorthTag:Hide()
		end

		if UserSettings.DisplayZoneName then
			Minimap.ZoneText:Show()
			MinimapZoneTextButton:Show()
		else
			Minimap.ZoneText:Hide()
			MinimapZoneTextButton:Hide()
		end

		if SUI.IsClassic then
			if (UserSettings.MapTimeIndicator) then
				GameTimeFrame:Hide()
			else
				GameTimeFrame:Show()
			end
		end

		if UserSettings.DisplayMapCords then
			Minimap.coords:Show()
		else
			Minimap.coords:Hide()
		end
	end

	-- Apply Style Settings
	do
		if Settings.BG.enabled then
			if Minimap.Background then
				Minimap.Background:ClearAllPoints()
			end

			Minimap.Background:SetTexture(Settings.BG.texture)
			Minimap.Background:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -47, 47)
			Minimap.Background:SetPoint('BOTTOMRIGHT', Minimap, 'BOTTOMRIGHT', 47, -47)
			Minimap.Background:SetAlpha(Settings.BG.alpha)
			Minimap.Background:SetBlendMode(Settings.BG.BlendMode)

			Minimap.Background:Show()
		else
			Minimap.Background:Hide()
		end

		Minimap.coords:SetTextColor(unpack(Settings.coords.TextColor))
		Minimap.coords:SetShadowColor(unpack(Settings.coords.ShadowColor))
		Minimap.coords:SetScale(Settings.coords.scale)

		-- If minimap default location is under the minimap setup scripts to move it
		if Settings.UnderVehicleUI and SUI.DBMod.Artwork.VehicleUI then
			local OnHide = function(args)
				if SUI.DBMod.Artwork.VehicleUI and not MoveIt:IsMoved('Minimap') and Minimap.position then
					Minimap:position('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
				end
			end
			local OnShow = function(args)
				if SUI.DBMod.Artwork.VehicleUI and not MoveIt:IsMoved('Minimap') then
					-- Reset to skin position
					UpdatePosition()
				end
			end

			local VisibilityWatcher = CreateFrame('Frame')
			VisibilityWatcher:SetScript('OnHide', OnHide)
			VisibilityWatcher:SetScript('OnShow', OnShow)
			RegisterStateDriver(VisibilityWatcher, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
		end
	end

	-- Set SUIMapChangesActive so we dont enter a loop from button events
	UserSettings.SUIMapChangesActive = true
	if not IsMouseOver() and (UserSettings.OtherStyle == 'mouseover' or UserSettings.OtherStyle == 'hide') then
		--Fix for SUI.DBM making its icon even if its not needed
		if SUI.DBM ~= nil and SUI.DBM.Options ~= nil then
			if SUI.DBM.Options.ShowMinimapButton ~= nil and not SUI.DBM.Options.ShowMinimapButton then
				table.insert(IgnoredFrames, 'DBMMinimapButton')
			end
		end

		if CensusButton ~= nil and CensusButton:GetAlpha() == 1 then
			CensusButton.FadeIn:Stop()
			CensusButton.FadeOut:Stop()
			CensusButton.FadeOut:Play()
		end

		if GameTimeFrame ~= nil and GameTimeFrame:GetAlpha() == 1 then
			GameTimeFrame.FadeIn:Stop()
			GameTimeFrame.FadeOut:Stop()
			GameTimeFrame.FadeOut:Play()
		end

		for _, child in ipairs({Minimap:GetChildren()}) do
			if child:GetName() ~= nil then
				--catch buttons not playing nice.
				if child.FadeOut == nil and not isFrameIgnored(child) then
					module:SetupButton(child, true)
				end

				if child.FadeOut ~= nil and child:GetAlpha() == 1 and not isFrameIgnored(child) then
					child.FadeIn:Stop()
					child.FadeOut:Stop()
					child.FadeOut:Play()
				elseif child.FadeIn == nil and not isFrameIgnored(child) then
					--if they still fail print a error and continue with our lives.
					SUI.Err('Minimap', child:GetName() .. ' is not fading')
				end
			end
		end
	elseif UserSettings.OtherStyle ~= 'hide' then
		if CensusButton ~= nil and CensusButton:GetAlpha() == 0 then
			CensusButton.FadeIn:Stop()
			CensusButton.FadeOut:Stop()
			CensusButton.FadeIn:Play()
		end
		if GameTimeFrame ~= nil and GameTimeFrame:GetAlpha() == 0 then
			GameTimeFrame.FadeIn:Stop()
			GameTimeFrame.FadeOut:Stop()
			GameTimeFrame.FadeIn:Play()
		end

		for _, child in ipairs({Minimap:GetChildren()}) do
			if child:GetName() ~= nil and child.FadeIn ~= nil and not isFrameIgnored(child) and child:GetAlpha() == 0 then
				child.FadeIn:Stop()
				child.FadeOut:Stop()

				child.FadeIn:Play()
			end
		end
	end
	LastUpdateStatus = IsMouseOver()
	UserSettings.SUIMapChangesActive = false
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['Minimap'] = {
		type = 'group',
		name = L['Minimap'],
		args = {
			NorthIndicator = {
				name = 'Show North Indicator',
				type = 'toggle',
				order = 0.1,
				get = function(info)
					return UserSettings.northTag
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
						return
					end
					UserSettings.northTag = val
					if val then
						MinimapNorthTag:Show()
					else
						MinimapNorthTag:Hide()
					end
				end
			},
			minimapzoom = {
				name = L['MinMapHideZoom'],
				type = 'toggle',
				order = 0.5,
				get = function(info)
					return UserSettings.MapZoomButtons
				end,
				set = function(info, val)
					UserSettings.MapZoomButtons = val
					module:update()
				end
			},
			minimapTimeIndicator = {
				name = L['Hide Time Indicator'],
				type = 'toggle',
				hidden = (not SUI.IsClassic),
				order = 0.5,
				get = function(info)
					return UserSettings.MapTimeIndicator
				end,
				set = function(info, val)
					UserSettings.MapTimeIndicator = val
					module:update()
				end
			},
			OtherStyle = {
				name = 'Button display mode',
				order = 0.9,
				type = 'select',
				style = 'dropdown',
				width = 'double',
				values = {
					['hide'] = 'Always Hide',
					['mouseover'] = 'Show on Mouse over',
					['show'] = 'Always Show'
				},
				get = function(info)
					return UserSettings.OtherStyle
				end,
				set = function(info, val)
					UserSettings.OtherStyle = val
					module:update()
				end
			},
			DisplayZoneName = {
				name = L['Display zone name'],
				type = 'toggle',
				order = 0.5,
				get = function(info)
					return UserSettings.DisplayZoneName
				end,
				set = function(info, val)
					UserSettings.DisplayZoneName = val
					module:update()
				end
			},
			DisplayMapCords = {
				name = L['Display map cords'],
				type = 'toggle',
				order = 0.5,
				get = function(info)
					return UserSettings.DisplayMapCords
				end,
				set = function(info, val)
					UserSettings.DisplayMapCords = val
					module:update()
				end
			}
		}
	}
end
