local SUI, L, print = SUI, SUI.L, SUI.print
local module = SUI:NewModule('Component_Minimap', 'AceTimer-3.0')
module.description = 'CORE: Skins, sizes, and positions the Minimap'
module.Core = true
local MoveIt, Settings
local UserSettings = SUI.DB.MiniMap
----------------------------------------------------------------------------------------------------
local MinimapUpdater, VisibilityWatcher = CreateFrame('Frame'), CreateFrame('Frame')
local SUIMinimap = CreateFrame('Frame', 'SUI_Minimap')
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
	local ignored = {'HybridMinimap', 'AAP-Classic', 'HandyNotes'}
	local WildcardIgnore = {'Questie'}

	local name = item:GetName()
	if name ~= nil then
		if SUI:isInTable(ignored, name) then
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

local PerformFullBtnUpdate = function(forced)
	if LastUpdateStatus ~= IsMouseOver() or forced then
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
	module:ScheduleTimer(PerformFullBtnUpdate, i)
end

local OnMouseDown = function()
	IsMouseDown = true
end

local function UpdatePosition()
	-- Position map based on Artwork
	if SUI:IsModuleEnabled('Minimap') and Settings.position and not MoveIt:IsMoved('Minimap') then
		local point, anchor, secondaryPoint, x, y = strsplit(',', Settings.position)
		if Minimap.position then
			Minimap:position(point, anchor, secondaryPoint, x, y, false, true)
		else
			Minimap:ClearAllPoints()
			Minimap:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	end
end

function module:ShapeChange(shape)
	if SUI.DB.DisabledComponents.Minimap then
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

	MinimapZoneText:SetShadowColor(0, 0, 0, 1)
	MinimapZoneText:SetShadowOffset(1, -1)
	MinimapZoneTextButton:SetFrameLevel(121)

	if HybridMinimap then
		HybridMinimap.MapCanvas:SetUseMaskTexture(false)
		if shape == 'square' then
			HybridMinimap.CircleMask:SetTexture('Interface\\BUTTONS\\WHITE8X8')
		else
			HybridMinimap.CircleMask:SetTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\circle-overlay')
		end
		HybridMinimap.MapCanvas:SetUseMaskTexture(true)
	end
end

function module:OnInitialize()
	MoveIt = SUI:GetModule('Component_MoveIt')
	-- TOOD: Convert this away from StaticPopup
	StaticPopupDialogs['MiniMapNotice'] = {
		text = '|cff33ff99SpartanUI Notice|n|r|n Another addon has been found modifying the minimap. Do you give permisson for SpartanUI to move and possibly modify the minimap as your theme dictates? |n|n You can change this option in the settings should you change your mind.',
		button1 = 'Yes',
		button2 = 'No',
		OnAccept = function()
			UserSettings.ManualAllowUse = true
		end,
		OnCancel = function()
			UserSettings.ManualAllowUse = true
			SUI:DisableModule(module)
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	Settings = SUI.DB.Styles[SUI.DB.Artwork.Style].Minimap
	UserSettings = SUI.DB.MiniMap

	-- Check for Carbonite dinking with the minimap.
	if (NXTITLELOW) then
		SUI:Print(NXTITLELOW .. ' is loaded ...Checking settings ...')
		if (Nx.db.profile.MiniMap.Own == true) then
			SUI:Print(NXTITLELOW .. ' is controlling the Minimap')
			SUI:Print('SpartanUI Will not modify or move the minimap unless Carbonite is a separate minimap')
			UserSettings.AutoDetectAllowUse = false
		end
	end

	-- Look for Sexymap or other MiniMap addons
	if (select(2, MinimapCluster:GetPoint()) ~= UIParent) or select(4, GetAddOnInfo('SexyMap')) then
		UserSettings.AutoDetectAllowUse = false
	end
end

function module:OnEnable()
	if ((not UserSettings.AutoDetectAllowUse) and (not UserSettings.ManualAllowUse)) then
		StaticPopup_Show('MiniMapNotice')
	end
	if SUI.DB.DisabledComponents.Minimap then
		return
	end
	Settings = SUI.DB.Styles[SUI.DB.Artwork.Style].Minimap

	-- MiniMap Modification
	-- Minimap:SetFrameLevel(120)

	-- local frame = CreateFrame('Frame', skinSettings.name .. '_Bar' .. number, (parent or UIParent))
	SUIMinimap:SetFrameStrata('BACKGROUND')
	SUIMinimap:SetFrameLevel(99)
	SUIMinimap:SetAllPoints(Minimap)
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

	SUIMinimap.BG = SUIMinimap:CreateTexture(nil, 'BACKGROUND', nil, -8)
	-- Minimap.Background = Minimap:CreateTexture(nil, 'BACKGROUND', nil, -8)
	if SUI.IsRetail then
		Minimap:SetArchBlobRingScalar(0)
		Minimap:SetQuestBlobRingScalar(0)
	end
	module:ModifyMinimapLayout()

	-- if not HybridMinimap then
	-- 	local frame = CreateFrame('Frame')
	-- 	frame:SetScript(
	-- 		'OnEvent',
	-- 		function(self, event, addon)
	-- 			if addon == 'Blizzard_HybridMinimap' then
	-- 				self:UnregisterEvent(event)
	-- 				module:ShapeChange(Settings.shape)
	-- 				self:SetScript('OnEvent', nil)
	-- 			end
	-- 		end
	-- 	)
	-- 	frame:RegisterEvent('ADDON_LOADED')
	-- end

	--Look for existing buttons
	MiniMapBtnScrape()

	Minimap:HookScript('OnEnter', OnEnter)
	Minimap:HookScript('OnLeave', OnLeave)
	Minimap:HookScript('OnMouseDown', OnMouseDown)

	-- Setup Updater script for button visibility updates
	MinimapUpdater:SetSize(1, 1)
	MinimapUpdater:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', -128, 128)
	MinimapUpdater:SetScript(
		'OnEvent',
		function()
			if not InCombatLockdown() then
				module:ScheduleTimer(PerformFullBtnUpdate, 2, true)
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
	module:ScheduleRepeatingTimer(PerformFullBtnUpdate, 30, true)

	--Initialize Buttons & Style settings
	module:update(true)

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

	Minimap.overlay = Minimap:CreateTexture(nil, 'OVERLAY')
	Minimap.overlay:SetTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\square-overlay')
	Minimap.overlay:SetAllPoints(Minimap)
	Minimap.overlay:SetBlendMode('ADD')

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

		Minimap.overlay:Show()

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

		Minimap.overlay:Hide()

		if SUI.IsRetail then
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, -5)
		end
	end

	-- Retail Version stuff
	if SUI.IsRetail then
		TimeManagerClockButton:GetRegions():Hide() -- Hide the border
		TimeManagerClockButton:ClearAllPoints()
		TimeManagerClockButton:SetPoint('TOP', Minimap, 'BOTTOM', 0, 20)

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
	if SUI.DB.DisabledComponents.Minimap then
		return
	end
	MinimapZoneText:Hide()

	Minimap.ZoneText = Minimap:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(Minimap.ZoneText, 11, 'Minimap')
	SUI:FormatFont(MinimapZoneText, 11, 'Minimap')
	Minimap.ZoneText:SetJustifyH('MIDDLE')
	Minimap.ZoneText:SetJustifyV('CENTER')
	Minimap.ZoneText:SetPoint('TOP', Minimap, 'BOTTOM', 0, -1)
	Minimap.ZoneText:SetShadowColor(0, 0, 0, 1)
	Minimap.ZoneText:SetShadowOffset(1, -1)

	MinimapZoneText:ClearAllPoints()
	MinimapZoneText:SetAllPoints(Minimap.ZoneText)
	MinimapZoneTextButton:ClearAllPoints()
	MinimapZoneTextButton:SetAllPoints(Minimap.ZoneText)

	Minimap.coords = Minimap:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(Minimap.coords, 10, 'Minimap')
	Minimap.coords:SetJustifyH('TOP')
	Minimap.coords:SetPoint('TOP', Minimap.ZoneText, 'BOTTOM', 0, -1)
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

function module:UpdateScale()
	if Minimap.coords then
		module:update()
	end
	if Settings.scaleWithArt then
		if Minimap.scale then
			Minimap:scale(SUI.DB.scale)
		else
			Minimap:SetScale(max(SUI.DB.scale, .01))
		end
	end
end

function module:update(FullUpdate)
	if SUI.DB.DisabledComponents.Minimap then
		return
	end
	-- Refresh settings
	Settings = SUI.DB.Styles[SUI.DB.Artwork.Style].Minimap

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
			MinimapZoneText:Show()
			MinimapZoneTextButton:Show()
		else
			MinimapZoneText:Hide()
			MinimapZoneTextButton:Hide()
		end

		if SUI.IsClassic then
			if (UserSettings.MapTimeIndicator) then
				GameTimeFrame:Hide()
			else
				GameTimeFrame:Show()
			end
		end

		local point, anchor, secondaryPoint, x, y = strsplit(',', Settings.ZoneText.position)
		Minimap.ZoneText:ClearAllPoints()
		Minimap.ZoneText:SetPoint(point, anchor, secondaryPoint, x, y)

		if UserSettings.DisplayMapCords then
			-- Position coords
			local point, anchor, secondaryPoint, x, y = strsplit(',', Settings.coords.position)
			Minimap.coords:ClearAllPoints()
			Minimap.coords:SetPoint(point, anchor, secondaryPoint, x, y)

			Minimap.coords:Show()
		else
			Minimap.coords:Hide()
		end
		-- if HybridMinimap then
		-- 	HybridMinimap:Hide()
		-- end
	end

	-- Apply Style Settings
	do
		if Settings.BG.enabled then
			SUIMinimap.BG.Settings = Settings.BG or nil
			if SUIMinimap.BG then
				SUIMinimap.BG:ClearAllPoints()
			end

			if Settings.BG.size then
				SUIMinimap.BG:SetSize(unpack(Settings.BG.size))
			end

			if Settings.BG.position then
				if type(Settings.BG.position) == 'table' then
					for i, v in ipairs(Settings.BG.position) do
						local point, anchor, secondaryPoint, x, y = strsplit(',', v)
						SUIMinimap.BG:SetPoint(point, anchor, secondaryPoint, x, y)
					end
				else
					local point, anchor, secondaryPoint, x, y = strsplit(',', Settings.BG.position)
					SUIMinimap.BG:SetPoint(point, anchor, secondaryPoint, x, y)
				end
			else
				SUIMinimap.BG:SetPoint('TOPLEFT', SUIMinimap, 'TOPLEFT', -30, 30)
				SUIMinimap.BG:SetPoint('BOTTOMRIGHT', SUIMinimap, 'BOTTOMRIGHT', 30, -30)
			end

			SUIMinimap.BG:SetTexture(Settings.BG.texture)
			SUIMinimap.BG:SetAlpha(Settings.BG.alpha)
			SUIMinimap.BG:SetBlendMode(Settings.BG.BlendMode)

			SUIMinimap.BG:Show()
		else
			SUIMinimap.BG:Hide()
		end

		Minimap.ZoneText:SetSize(unpack(Settings.ZoneText.size))
		Minimap.ZoneText:SetTextColor(unpack(Settings.ZoneText.TextColor))
		Minimap.ZoneText:SetShadowColor(unpack(Settings.ZoneText.ShadowColor))
		Minimap.ZoneText:SetScale(Settings.ZoneText.scale)

		Minimap.coords:SetSize(unpack(Settings.coords.size))
		Minimap.coords:SetTextColor(unpack(Settings.coords.TextColor))
		Minimap.coords:SetShadowColor(unpack(Settings.coords.ShadowColor))
		Minimap.coords:SetScale(Settings.coords.scale)

		-- If minimap default location is under the minimap setup scripts to move it
		if
			Settings.UnderVehicleUI and SUI.DB.Artwork.VehicleUI and (not VisibilityWatcher.hooked) and
				(not MoveIt:IsMoved('Minimap'))
		 then
			local OnHide = function(args)
				if SUI.DB.Artwork.VehicleUI and not MoveIt:IsMoved('Minimap') and Minimap.position then
					Minimap:position('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
				end
			end
			local OnShow = function(args)
				if SUI.DB.Artwork.VehicleUI and not MoveIt:IsMoved('Minimap') then
					-- Reset to skin position
					UpdatePosition()
					-- Update Scale
					module:UpdateScale()
				end
			end

			VisibilityWatcher:SetScript('OnHide', OnHide)
			VisibilityWatcher:SetScript('OnShow', OnShow)
			RegisterStateDriver(VisibilityWatcher, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
			VisibilityWatcher.hooked = true
		elseif (MoveIt:IsMoved('Minimap') or (not SUI.DB.Artwork.VehicleUI)) and VisibilityWatcher.hooked then
			UnregisterStateDriver(VisibilityWatcher, 'visibility')
			VisibilityWatcher.hooked = false
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
			if child:GetName() ~= nil and not isFrameIgnored(child) then
				--catch buttons not playing nice.
				if child.FadeOut == nil then
					module:SetupButton(child, true)
				end

				if child.FadeOut ~= nil and child:GetAlpha() == 1 then
					child.FadeIn:Stop()
					child.FadeOut:Stop()
					child.FadeOut:Play()
				elseif child.FadeIn == nil then
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

	if FullUpdate then
		-- Position
		UpdatePosition()
		-- Update Scale
		module:UpdateScale()
		-- reload shape
		module:ShapeChange(Settings.shape)
	end

	UserSettings.SUIMapChangesActive = false
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['Minimap'] = {
		type = 'group',
		name = L['Minimap'],
		args = {
			NorthIndicator = {
				name = L['Show North Indicator'],
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
				name = L['Hide Zoom Buttons'],
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
				name = L['Button display mode'],
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
