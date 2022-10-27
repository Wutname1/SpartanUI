local SUI, L, MoveIt = SUI, SUI.L, SUI.MoveIt
local module = SUI:NewModule('Component_Minimap')
module.description = 'CORE: Skins, sizes, and positions the Minimap'
module.Core = true
----------------------------------------------------------------------------------------------------
module.Settings = nil
local Registry = {}
local MinimapUpdater, VisibilityWatcher = CreateFrame('Frame'), CreateFrame('Frame')
local SUIMinimap = CreateFrame('Frame', 'SUI_Minimap')
local LastMouseStatus, MouseIsOver, IsMouseDown = nil, false, false
local IgnoredFrames = {}
local BaseSettings = {
	Movable = true,
	shape = 'circle',
	size = {140, 140},
	scaleWithArt = true,
	UnderVehicleUI = true,
	BG = {
		enabled = true,
		BlendMode = 'ADD',
		alpha = 1
	},
	ZoneText = {
		size = {100, 12},
		scale = 1,
		position = 'TOP,Minimap,BOTTOM,0,-4',
		TextColor = {1, .82, 0, 1},
		ShadowColor = {0, 0, 0, 1}
	},
	coords = {
		scale = 1,
		size = {80, 12},
		position = 'TOP,MinimapZoneText,BOTTOM,0,-4',
		TextColor = {1, 1, 1, 1},
		ShadowColor = {0, 0, 0, 0}
	}
}

local IsMouseOver = function()
	local MouseFocus = GetMouseFocus()
	if
		MouseFocus and not MouseFocus:IsForbidden() and
			((MouseFocus:GetName() == 'Minimap') or
				(MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find('Mini[Mm]ap')))
	 then
		MouseIsOver = true
	else
		MouseIsOver = false
	end
	return MouseIsOver
end

local isFrameIgnored = function(item)
	local ignored = {'HybridMinimap', 'AAP-Classic', 'HandyNotes'}
	local WildcardIgnore = {'Questie'}

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
	if GameTimeFrame and not SUI.IsRetail then
		module:SetupButton(GameTimeFrame)
	end
end

local PerformFullBtnUpdate = function(forced)
	if LastMouseStatus ~= IsMouseOver() or forced then
		MiniMapBtnScrape()
		--update visibility
		module:update()
	end
end

local OnEnter = function()
	-- OnEnter fires repeatedly, so we need to check if we are already in the correct state
	if MouseIsOver then
		return
	end
	--don't use PerformFullBtnUpdate as we want to perform the actions in reverse. since any new unknown icons will already be shown.
	if LastMouseStatus ~= IsMouseOver() then
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
	if SUI:IsModuleEnabled('Minimap') and module.Settings.position and not MoveIt:IsMoved('Minimap') then
		local point, anchor, secondaryPoint, x, y = strsplit(',', module.Settings.position)
		if MinimapCluster.position then
			MinimapCluster:position(point, anchor, secondaryPoint, x, y, false, true)
		else
			MinimapCluster:ClearAllPoints()
			MinimapCluster:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	end
end

local function updateSettings()
	-- Refresh settings
	module.Settings = {}
	module.Settings = SUI:CopyData(BaseSettings, module.Settings)
	if Registry[SUI.DB.Artwork.Style] then
		module.Settings = SUI:CopyData(Registry[SUI.DB.Artwork.Style].settings, module.Settings)
	end
end

function module:ShapeChange(shape)
	if SUI.DB.DisabledComponents.Minimap then
		return
	end

	if module.Settings.size then
		Minimap:SetSize(unpack(module.Settings.size))
	end

	Minimap.ZoneText:ClearAllPoints()
	if module.Settings.TextLocation == 'TOP' then
		Minimap.ZoneText:SetPoint('BOTTOMLEFT', Minimap, 'TOPLEFT', 0, 4)
		Minimap.ZoneText:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT', 0, 4)
	else
		Minimap.ZoneText:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -4)
		Minimap.ZoneText:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -4)
	end

	if MinimapZoneTextButton then
		MinimapZoneText:SetShadowColor(0, 0, 0, 1)
		MinimapZoneText:SetShadowOffset(1, -1)
		MinimapZoneTextButton:SetFrameLevel(121)
	end

	if HybridMinimap then
		HybridMinimap.MapCanvas:SetUseMaskTexture(false)
		if shape == 'square' then
			HybridMinimap.CircleMask:SetTexture('Interface\\BUTTONS\\WHITE8X8')
		else
			HybridMinimap.CircleMask:SetTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\circle-overlay')
		end
		HybridMinimap.MapCanvas:SetUseMaskTexture(true)
	end

	if not SUI.IsRetail then
		MinimapCluster:SetSize(Minimap:GetWidth() * 1.2, Minimap:GetWidth() + 20 * 1.2)
	end
end

function module:ModifyMinimapLayout()
	--Classic modifcations
	if not SUI.IsRetail then
		Minimap:EnableMouseWheel(true)
		Minimap:SetScript(
			'OnMouseWheel',
			function(_, delta)
				if (delta > 0) then
					Minimap_ZoomIn()
				else
					Minimap_ZoomOut()
				end
			end
		)
		if TimeManagerClockButton then
			TimeManagerClockButton:GetRegions():Hide()
			TimeManagerClockButton:ClearAllPoints()
			TimeManagerClockButton:SetPoint('BOTTOM', Minimap, 'BOTTOM', 0, -5)
		end

		if MiniMapInstanceDifficulty then
			MiniMapInstanceDifficulty:ClearAllPoints()
			MiniMapInstanceDifficulty:SetPoint('TOPLEFT', Minimap, 4, 22)
		end

		if MinimapBorderTop then
			MinimapBorderTop:Hide()
			MinimapBorder:Hide()
			if not UserSettings.northTag then
				MinimapNorthTag:Hide()
			else
				MinimapNorthTag:Show()
			end
		end

		if MiniMapWorldMapButton then
			MiniMapWorldMapButton:ClearAllPoints()
			MiniMapWorldMapButton:SetPoint('TOPRIGHT', Minimap, -20, 12)
		end

		if MiniMapMailFrame then
			MiniMapMailFrame:ClearAllPoints()
			MiniMapMailFrame:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 21, -53)
		end

		if MinimapZoneTextButton then
			MinimapZoneText:ClearAllPoints()
			MinimapZoneText:SetAllPoints(MinimapZoneTextButton)
		end

		MinimapCluster:SetSize(Minimap:GetWidth() * 1.2, Minimap:GetWidth() + 20 * 1.2)
	end

	--Retail modifications
	if MinimapCompassTexture then
		MinimapCompassTexture:Hide()
	end

	if MinimapCluster.BorderTop then
		MinimapCluster.BorderTop:ClearAllPoints()
		MinimapCluster.BorderTop:SetPoint('TOP', Minimap, 'BOTTOM', 0, -10)
		MinimapCluster.BorderTop:SetWidth(Minimap:GetWidth() / 1.4)
		MinimapCluster.BorderTop:SetHeight(MinimapCluster.ZoneTextButton:GetHeight() * 2.8)
		MinimapCluster.BorderTop:SetAlpha(.8)

		MinimapCluster.ZoneTextButton:ClearAllPoints()
		MinimapCluster.ZoneTextButton:SetPoint('TOPLEFT', MinimapCluster.BorderTop, 'TOPLEFT', 4, -4)
		MinimapCluster.ZoneTextButton:SetPoint('TOPRIGHT', MinimapCluster.BorderTop, 'TOPRIGHT', -4, -4)

		SUI:FormatFont(MinimapZoneText, 10, 'Minimap')
		MinimapZoneText:SetJustifyH('CENTER')

		TimeManagerClockButton:ClearAllPoints()
		TimeManagerClockButton:SetPoint('BOTTOMRIGHT', MinimapCluster.BorderTop, 'BOTTOMRIGHT', 2, 0)

		SUI:FormatFont(TimeManagerClockTicker, 10, 'Minimap')
		SUI:FormatFont(Minimap.coords, 10, 'Minimap')

		MinimapCluster.Tracking:ClearAllPoints()
		MinimapCluster.Tracking:SetPoint('BOTTOMLEFT', MinimapCluster.BorderTop, 'BOTTOMLEFT', 2, 2)
		MinimapCluster.Tracking.Background:Hide()

	--TODO: InstanceDifficulty position and scale
	end

	--Shared modifications
	Minimap.overlay = Minimap:CreateTexture(nil, 'OVERLAY')
	Minimap.overlay:SetTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\square-overlay')
	Minimap.overlay:SetAllPoints(Minimap)
	Minimap.overlay:SetBlendMode('ADD')

	if module.Settings.shape == 'square' then
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

		if MiniMapTracking then
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', 0, 0)
		end
	else
		Minimap:SetMaskTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\circle-overlay')

		Minimap.overlay:Hide()

		if MiniMapTracking then
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, -5)
		end
	end

	if GameTimeFrame and not SUI.IsRetail then
		GameTimeFrame:ClearAllPoints()
		GameTimeFrame:SetScale(.7)
		GameTimeFrame:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 20, -16)
		GameTimeFrame:SetFrameLevel(122)
	elseif GameTimeFrame and BT4BarMicroMenu and SUI.IsRetail then
		GameTimeFrame:ClearAllPoints()
		GameTimeFrame:SetPoint('TOPRIGHT', CharacterMicroButton, 'TOPLEFT', 2, 0)
		GameTimeFrame:SetWidth(CharacterMicroButton:GetWidth())
	end

	module:MinimapCoords()
end

function module:MinimapCoords()
	if SUI.DB.DisabledComponents.Minimap then
		return
	end
	if not SUI.IsRetail then
		MinimapZoneText:Hide()
	end

	Minimap.ZoneText = Minimap:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(Minimap.ZoneText, 11, 'Minimap')
	SUI:FormatFont(MinimapZoneText, 11, 'Minimap')
	Minimap.ZoneText:SetJustifyH('MIDDLE')
	Minimap.ZoneText:SetJustifyV('CENTER')
	Minimap.ZoneText:SetPoint('TOP', Minimap, 'BOTTOM', 0, -1)
	Minimap.ZoneText:SetShadowColor(0, 0, 0, 1)
	Minimap.ZoneText:SetShadowOffset(1, -1)

	if MinimapZoneTextButton then
		MinimapZoneText:ClearAllPoints()
		MinimapZoneText:SetAllPoints(Minimap.ZoneText)

		MinimapZoneTextButton:ClearAllPoints()
		MinimapZoneTextButton:SetAllPoints(Minimap.ZoneText)
	end

	Minimap.coords = Minimap:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(Minimap.coords, 10, 'Minimap')
	Minimap.coords:SetJustifyH('TOP')
	Minimap.coords:SetPoint('TOP', Minimap.ZoneText, 'BOTTOM', 0, -1)
	Minimap.coords:SetShadowOffset(1, -1)

	local function UpdateCoords()
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
	module:ScheduleRepeatingTimer(UpdateCoords, 1)
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
	if module.Settings.scaleWithArt then
		if MinimapCluster.scale then
			MinimapCluster:scale(SUI.DB.scale)
		else
			MinimapCluster:SetScale(max(SUI.DB.scale, .01))
		end
	end
end

function module:update(FullUpdate)
	if SUI.DB.DisabledComponents.Minimap then
		return
	end
	updateSettings()

	-- UserSettings item visibility
	do
		if (UserSettings.MapZoomButtons) then
			if Minimap.ZoomIn then
				Minimap.ZoomIn:Hide()
				Minimap.ZoomOut:Hide()
			elseif MinimapZoomIn then
				MinimapZoomIn:Hide()
				MinimapZoomOut:Hide()
			end
		else
			if Minimap.ZoomIn then
				Minimap.ZoomIn:Show()
				Minimap.ZoomOut:Show()
			elseif MinimapZoomIn then
				MinimapZoomIn:Show()
				MinimapZoomOut:Show()
			end
		end

		if MinimapZoomIn then
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
		end

		local point, anchor, secondaryPoint, x, y = strsplit(',', module.Settings.ZoneText.position)
		Minimap.ZoneText:ClearAllPoints()
		Minimap.ZoneText:SetPoint(point, anchor, secondaryPoint, x, y)

		if UserSettings.DisplayMapCords then
			-- Position coords
			local point, anchor, secondaryPoint, x, y = strsplit(',', module.Settings.coords.position)
			Minimap.coords:ClearAllPoints()
			Minimap.coords:SetPoint(point, anchor, secondaryPoint, x, y)

			Minimap.coords:Show()
		else
			Minimap.coords:Hide()
		end
	end

	-- Apply Style Settings
	do
		if module.Settings.BG.enabled then
			SUIMinimap.BG.Settings = module.Settings.BG or nil
			if SUIMinimap.BG then
				SUIMinimap.BG:ClearAllPoints()
			end

			if module.Settings.BG.size then
				SUIMinimap.BG:SetSize(unpack(module.Settings.BG.size))
			end

			if module.Settings.BG.position then
				if type(module.Settings.BG.position) == 'table' then
					for i, v in ipairs(module.Settings.BG.position) do
						local point, anchor, secondaryPoint, x, y = strsplit(',', v)
						SUIMinimap.BG:SetPoint(point, anchor, secondaryPoint, x, y)
					end
				else
					local point, anchor, secondaryPoint, x, y = strsplit(',', module.Settings.BG.position)
					SUIMinimap.BG:SetPoint(point, anchor, secondaryPoint, x, y)
				end
			else
				SUIMinimap.BG:SetPoint('TOPLEFT', SUIMinimap, 'TOPLEFT', -30, 30)
				SUIMinimap.BG:SetPoint('BOTTOMRIGHT', SUIMinimap, 'BOTTOMRIGHT', 30, -30)
			end

			SUIMinimap.BG:SetTexture(module.Settings.BG.texture)
			SUIMinimap.BG:SetAlpha(module.Settings.BG.alpha)
			SUIMinimap.BG:SetBlendMode(module.Settings.BG.BlendMode)

			SUIMinimap.BG:Show()
		else
			SUIMinimap.BG:Hide()
		end

		Minimap.ZoneText:SetSize(unpack(module.Settings.ZoneText.size))
		Minimap.ZoneText:SetTextColor(unpack(module.Settings.ZoneText.TextColor))
		Minimap.ZoneText:SetShadowColor(unpack(module.Settings.ZoneText.ShadowColor))
		Minimap.ZoneText:SetScale(module.Settings.ZoneText.scale)

		Minimap.coords:SetSize(unpack(module.Settings.coords.size))
		Minimap.coords:SetTextColor(unpack(module.Settings.coords.TextColor))
		Minimap.coords:SetShadowColor(unpack(module.Settings.coords.ShadowColor))
		Minimap.coords:SetScale(module.Settings.coords.scale)

		-- If minimap default location is under the minimap setup scripts to move it
		if
			module.Settings.UnderVehicleUI and SUI.DB.Artwork.VehicleUI and (not VisibilityWatcher.hooked) and
				(not MoveIt:IsMoved('Minimap'))
		 then
			local OnHide = function(args)
				if SUI.DB.Artwork.VehicleUI and not MoveIt:IsMoved('Minimap') and Minimap.position then
					MinimapCluster:position('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
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
		if CensusButton ~= nil and CensusButton:GetAlpha() == 1 then
			CensusButton.FadeIn:Stop()
			CensusButton.FadeOut:Stop()
			CensusButton.FadeOut:Play()
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
				--if they still fail print a error and continue with our name
				-- SUI.Error('Minimap', child:GetName() .. ' is not fading')
				end
			end
		end
	elseif UserSettings.OtherStyle ~= 'hide' then
		if CensusButton ~= nil and CensusButton:GetAlpha() == 0 then
			CensusButton.FadeIn:Stop()
			CensusButton.FadeOut:Stop()
			CensusButton.FadeIn:Play()
		end

		for _, child in ipairs({Minimap:GetChildren()}) do
			if child:GetName() ~= nil and child.FadeIn ~= nil and not isFrameIgnored(child) and child:GetAlpha() == 0 then
				child.FadeIn:Stop()
				child.FadeOut:Stop()

				child.FadeIn:Play()
			end
		end
	end
	LastMouseStatus = IsMouseOver()

	if FullUpdate then
		-- Position
		UpdatePosition()
		-- Update Scale
		module:UpdateScale()
		-- reload shape
		module:ShapeChange(module.Settings.shape)
	end

	UserSettings.SUIMapChangesActive = false
end

function module:Register(name, settings)
	Registry[name] = {settings = settings}
end

function module:OnInitialize()
	-- TODO: Convert this away from StaticPopup
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
	local defaults = {
		northTag = false,
		ManualAllowUse = false,
		ManualAllowPrompt = '',
		AutoDetectAllowUse = true,
		MapButtons = true,
		MapZoomButtons = true,
		MapTimeIndicator = false,
		DisplayMapCords = true,
		DisplayZoneName = true,
		Shape = 'square',
		BlizzStyle = 'mouseover',
		OtherStyle = 'mouseover',
		Moved = false,
		lockminimap = true,
		Position = nil,
		SUIMapChangesActive = false
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Minimap', {profile = defaults})
	module.DB = module.Database.profile
	UserSettings = module.DB

	-- Check for Carbonite
	if (NXTITLELOW) then
		SUI:Print(NXTITLELOW .. ' is loaded ...Checking settings ...')
		if (Nx.db.profile.MiniMap.Own == true) then
			SUI:Print(NXTITLELOW .. ' is controlling the Minimap')
			SUI:Print('SpartanUI Will not modify or move the minimap unless Carbonite is a separate minimap')
			UserSettings.AutoDetectAllowUse = false
		end
	end

	-- Look for Sexymap or other MiniMap addons
	if SUI:IsAddonEnabled('SexyMap') then
		UserSettings.AutoDetectAllowUse = false
	end
end

function module:OnEnable()
	if ((not UserSettings.AutoDetectAllowUse) and (not UserSettings.ManualAllowUse)) then
		print((not UserSettings.AutoDetectAllowUse))
		print(UserSettings.AutoDetectAllowUse)
		StaticPopup_Show('MiniMapNotice')
	end
	if SUI.DB.DisabledComponents.Minimap then
		return
	end
	updateSettings()

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

	--Look for existing buttons
	MiniMapBtnScrape()

	MinimapCluster:HookScript('OnEnter', OnEnter)
	MinimapCluster:HookScript('OnLeave', OnLeave)
	MinimapCluster:HookScript('OnMouseDown', OnMouseDown)

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
	MoveIt:CreateMover(MinimapCluster, 'Minimap')
	if SUI.IsRetail then
		MinimapCluster.Selection:HookScript(
			'OnShow',
			function()
				MinimapCluster.Selection:Hide()
			end
		)
		local function ResetPostion(_, _, anchor)
			if anchor == UIParent or not anchor.GetName then
				MinimapCluster:ClearAllPoints()
				MinimapCluster:SetPoint('TOPLEFT', SUI_Mover_Minimap)
			end
		end

		Minimap:ClearAllPoints()
		Minimap:SetPoint('TOP', MinimapCluster, 'TOP', 0, 0)

		if ExpansionLandingPageMinimapButton then
			ExpansionLandingPageMinimapButton:HookScript(
				'OnShow',
				function()
					ExpansionLandingPageMinimapButton:ClearAllPoints()
					ExpansionLandingPageMinimapButton:SetPoint('BOTTOMLEFT', Minimap, 'BOTTOMLEFT', -20, -20)
				end
			)
		end

		hooksecurefunc(MinimapCluster, 'SetPoint', ResetPostion)
		MinimapCluster:SetHeight(Minimap:GetHeight() + MinimapCluster.BorderTop:GetHeight() + 20)
	end

	-- If we didint move the minimap before making the mover make sure default is set.
	if MoveIt:IsMoved('Minimap') then
		MinimapCluster.mover.defaultPoint = module.Settings.position
	end

	-- Construct options
	module:BuildOptions()
end

function module:BuildOptions()
	SUI.opt.args['Modules'].args['Minimap'] = {
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
