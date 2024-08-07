---@diagnostic disable: undefined-field
local SUI, L, MoveIt = _G.SUI, SUI.L, SUI.MoveIt
local module = SUI:NewModule('Minimap') ---@class SUI.Module.Minimap : SUI.Module
module.description = 'CORE: Skins, sizes, and positions the Minimap'
module.Core = true
----------------------------------------------------------------------------------------------------
module.Settings = nil ---@type SUI.Style.Settings.Minimap
local Registry = {}
local MinimapUpdater, VisibilityWatcher = CreateFrame('Frame'), CreateFrame('Frame')
---@class SUI.Minimap.Holder : FrameExpanded, SUI.MoveIt.MoverParent
local SUIMinimap = CreateFrame('Frame', 'SUI_Minimap')
local LastMouseStatus, MouseIsOver, IsMouseDown = nil, false, false
local IgnoredFrames = {}
local BaseSettings = {
	Movable = true,
	shape = 'circle',
	size = { 160, 160 },
	scaleWithArt = true,
	UnderVehicleUI = true,
	elements = {
		background = {
			enabled = true,
			BlendMode = 'ADD',
			alpha = 1,
		},
		ZoneText = {
			enabled = true,
			scale = 1,
			position = 'TOP,BorderTop,BOTTOM,0,-4',
			TextColor = { 1, 0.82, 0, 1 },
			ShadowColor = { 0, 0, 0, 1 },
		},
		coords = {
			enabled = true,
			scale = 1,
			size = { 80, 12 },
			TextColor = { 1, 1, 1, 1 },
			ShadowColor = { 0, 0, 0, 0 },
		},
		AddonCompartmentFrame = {
			enabled = true,
			scale = 1,
			position = 'TOPRIGHT,BorderTop,TOPRIGHT,0,0',
		},
		InstanceDifficulty = {
			enabled = true,
			scale = 0.8,
			position = 'RIGHT,BorderTop,LEFT,2,0',
		},
		Tracking = {
			enabled = true,
			scale = 1,
			position = 'BOTTOMLEFT,BorderTop,BOTTOMLEFT,2,1',
		},
		IndicatorFrame = {
			enabled = true,
			scale = 0.8,
			position = 'LEFT,Tracking,RIGHT,3,0',
		},
		GameTimeFrame = {
			enabled = true,
			scale = 1,
			position = 'BOTTOMRIGHT,BorderTop,BOTTOMRIGHT,2,0',
		},
		TimeManagerClockButton = {
			enabled = true,
			scale = 1,
			position = 'BOTTOMRIGHT,BorderTop,BOTTOMRIGHT,-10,0',
		},
	},
	BG = {
		enabled = true,
		BlendMode = 'ADD',
		alpha = 1,
	},
	ZoneText = {
		scale = 1,
		position = 'TOP,Minimap,BOTTOM,0,-4',
		TextColor = { 1, 0.82, 0, 1 },
		ShadowColor = { 0, 0, 0, 1 },
	},
	coords = {
		scale = 1,
		size = { 80, 12 },
		TextColor = { 1, 1, 1, 1 },
		ShadowColor = { 0, 0, 0, 0 },
	},
}

local IsMouseOver = function()
	for _, MouseFocus in ipairs(GetMouseFoci()) do
		if
			MouseFocus
			and not MouseFocus:IsForbidden()
			and ((MouseFocus:GetName() == 'Minimap') or (MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find('Mini[Mm]ap')))
		then
			MouseIsOver = true
			return true
		end
	end

	MouseIsOver = false
	return false
end

local isFrameIgnored = function(item)
	local ignored = { 'HybridMinimap', 'AAP-Classic', 'HandyNotes' }
	local WildcardIgnore = { 'Questie' }

	local name = item:GetName()
	if name ~= nil then
		if SUI:IsInTable(ignored, name) then return true end

		for _, v in ipairs(WildcardIgnore) do
			if string.match(name, v) then return true end
		end
	end
	return false
end

local MiniMapBtnScrape = function()
	-- Hook Minimap Icons
	for _, child in ipairs({ Minimap:GetChildren() }) do
		if child.FadeIn == nil and not isFrameIgnored(child) then module:SetupButton(child) end
	end
	if CensusButton ~= nil and CensusButton.FadeIn == nil then module:SetupButton(CensusButton) end
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
	if MouseIsOver then return end
	--don't use PerformFullBtnUpdate as we want to perform the actions in reverse. since any new unknown icons will already be shown.
	if LastMouseStatus ~= IsMouseOver() then module:update() end --update visibility
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
	if module.Settings.position and not MoveIt:IsMoved('Minimap') then
		local point, anchor, secondaryPoint, x, y = strsplit(',', module.Settings.position)
		if SUIMinimap.position then
			SUIMinimap:position(point, anchor, secondaryPoint, x, y, false, true)
		else
			SUIMinimap:ClearAllPoints()
			SUIMinimap:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	end
	MinimapCluster.MinimapContainer:ClearAllPoints()
	MinimapCluster.MinimapContainer:SetPoint('TOPLEFT', SUIMinimap, 'TOPLEFT', -30, 32)
end

local function updateSettings()
	-- Refresh settings
	---@diagnostic disable-next-line: missing-fields
	module.Settings = {}
	module.Settings = SUI:CopyData(BaseSettings, module.Settings)
	if Registry[SUI.DB.Artwork.Style] then module.Settings = SUI:CopyData(Registry[SUI.DB.Artwork.Style].settings, module.Settings) end
end

function module:Register(name, settings)
	Registry[name] = { settings = settings }
end

function module:ShapeChange(shape)
	if SUI:IsModuleDisabled('Minimap') then return end

	if module.Settings.size then Minimap:SetSize(unpack(module.Settings.size)) end
	SUIMinimap:SetSize(Minimap:GetWidth(), (Minimap:GetHeight() + MinimapCluster.BorderTop:GetHeight() + 15))

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
end

function module:ModifyMinimapLayout()
	--Retail modifications
	MinimapCompassTexture:Hide()

	--TODO: Set the Point of MinimapCluster.BorderTop via settings
	MinimapCluster.BorderTop:ClearAllPoints()
	MinimapCluster.BorderTop:SetPoint('TOP', Minimap, 'BOTTOM', 0, -5)
	MinimapCluster.BorderTop:SetWidth(Minimap:GetWidth() / 1.3)
	MinimapCluster.BorderTop:SetHeight(MinimapCluster.ZoneTextButton:GetHeight() * 2.8)
	MinimapCluster.BorderTop:SetAlpha(0.8)

	MinimapCluster.ZoneTextButton:ClearAllPoints()
	MinimapCluster.ZoneTextButton:SetPoint('TOPLEFT', MinimapCluster.BorderTop, 'TOPLEFT', 4, -4)
	MinimapCluster.ZoneTextButton:SetPoint('TOPRIGHT', MinimapCluster.BorderTop, 'TOPRIGHT', -15, -4)
	SUI.Font:Format(MinimapZoneText, 10, 'Minimap')
	SUI.Font:Format(MinimapZoneText, 10, 'Minimap')
	MinimapZoneText:SetJustifyH('CENTER')
	SUI.Font:Format(TimeManagerClockTicker, 10, 'Minimap')
	SUI.Font:Format(Minimap.coords, 10, 'Minimap')

	local Tracking = MinimapCluster.TrackingFrame or MinimapCluster.Tracking

	Tracking:ClearAllPoints()
	Tracking:SetPoint('BOTTOMLEFT', MinimapCluster.BorderTop, 'BOTTOMLEFT', 2, 1)
	Tracking.Background:Hide()

	MinimapCluster.IndicatorFrame:ClearAllPoints()
	MinimapCluster.IndicatorFrame:SetScale(0.8)
	MinimapCluster.IndicatorFrame:SetPoint('LEFT', Tracking, 'RIGHT', 3)

	MinimapCluster.InstanceDifficulty:ClearAllPoints()
	MinimapCluster.InstanceDifficulty:SetScale(0.8)
	MinimapCluster.InstanceDifficulty:SetPoint('RIGHT', MinimapCluster.BorderTop, 'LEFT', 2)

	GameTimeFrame:ClearAllPoints()
	GameTimeFrame:SetPoint('BOTTOMRIGHT', MinimapCluster.BorderTop, 'BOTTOMRIGHT', 2, 0)

	AddonCompartmentFrame:ClearAllPoints()
	AddonCompartmentFrame:SetPoint('TOPRIGHT', MinimapCluster.BorderTop, 'TOPRIGHT', 0, 0)
	AddonCompartmentFrame:SetFrameLevel(4)

	TimeManagerClockButton:ClearAllPoints()
	TimeManagerClockButton:SetPoint('BOTTOMRIGHT', MinimapCluster.BorderTop, 'BOTTOMRIGHT', -10, 0)
	TimeManagerClockTicker:ClearAllPoints()
	TimeManagerClockTicker:SetAllPoints(TimeManagerClockButton)
	if MinimapCluster.SetRotateMinimap then
		if UserSettings.rotate then C_CVar.SetCVar('rotateMinimap', 1) end

		hooksecurefunc(MinimapCluster, 'SetRotateMinimap', function()
			if UserSettings.rotate then C_CVar.SetCVar('rotateMinimap', 1) end
		end)
	end

	--Shared modifications
	MinimapCluster:EnableMouse(false)
	Minimap.overlay = Minimap:CreateTexture(nil, 'OVERLAY')
	Minimap.overlay:SetTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\square-overlay')
	Minimap.overlay:SetAllPoints(Minimap)
	Minimap.overlay:SetBlendMode('ADD')
	function GetMinimapShape()
		return (module.Settings.shape == 'square') and 'SQUARE' or 'ROUND'
	end
	if module.Settings.shape == 'square' then
		Minimap:SetMaskTexture('Interface\\BUTTONS\\WHITE8X8')
		Minimap.overlay:Show()
	else
		Minimap:SetMaskTexture('Interface\\AddOns\\SpartanUI\\images\\minimap\\circle-overlay')
		Minimap.overlay:Hide()
	end
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetArchBlobRingAlpha(0)
	Minimap:SetQuestBlobRingScalar(0)
	Minimap:SetQuestBlobRingAlpha(0)
	-- Attach Minimap Backdrop to the minimap it's self
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetPoint('CENTER', Minimap, 'CENTER', -10, -24)
	MinimapBackdrop:SetFrameLevel(Minimap:GetFrameLevel())

	module:MinimapCoords()
end

function module:MinimapCoords()
	if SUI:IsModuleDisabled('Minimap') then return end

	Minimap.ZoneText = Minimap:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(Minimap.ZoneText, 11, 'Minimap')
	SUI.Font:Format(MinimapZoneText, 11, 'Minimap')
	Minimap.ZoneText:SetJustifyH('CENTER')
	Minimap.ZoneText:SetJustifyV('MIDDLE')
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
	SUI.Font:Format(Minimap.coords, 10, 'Minimap')
	Minimap.coords:SetJustifyV('BOTTOM')
	Minimap.coords:SetPoint('BOTTOM', MinimapCluster.BorderTop, 'BOTTOM', 0, 3)
	Minimap.coords:SetShadowOffset(1, -1)

	local function UpdateCoords()
		--Get the Map we are on
		local mapID = C_Map.GetBestMapForUnit('player')
		if not mapID then return end
		-- Get the Cords we are at for said map
		-- C_Map.GetPlayerMapPosition has to be nil checked for as GetXY is defined if off the edge of the map
		-- Notibly this causes errors on the [The Stormwind Extraction] (BFA Horde start quest)
		local MapPos = C_Map.GetPlayerMapPosition(mapID, 'player')
		if not MapPos then return end
		local x, y = MapPos:GetXY()
		if (not x) or not y then return end
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
		FadeOut:SetStartDelay(0.5)
		btn.FadeOut:SetToFinalAlpha(true)

		--Hook into the buttons show and hide events to catch for the button being enabled/disabled
		btn:HookScript('OnHide', function(self, event, ...)
			if not UserSettings.SUIMapChangesActive then table.insert(IgnoredFrames, self:GetName()) end
		end)
		btn:HookScript('OnShow', function(self, event, ...)
			for i = 1, table.getn(IgnoredFrames) do
				if IgnoredFrames[i] == btn:GetName() then table.remove(IgnoredFrames, i) end
			end
		end)
	end
end

function module:UpdateScale()
	if Minimap.coords then module:update() end
	if module.Settings.scaleWithArt and SUI:IsAddonDisabled('SexyMap') then
		if SUIMinimap.scale then
			SUIMinimap:scale(SUI.DB.scale)
			MinimapCluster:SetScale(SUI.DB.scale)
		else
			SUIMinimap:SetScale(max(SUI.DB.scale, 0.01))
			MinimapCluster:SetScale(max(SUI.DB.scale, 0.01))
		end
	end
end

function module:update(FullUpdate)
	if SUI:IsModuleDisabled('Minimap') then return end
	updateSettings()

	-- UserSettings item visibility
	do
		if UserSettings.MapZoomButtons then
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

		if UserSettings.DisplayMapCords then
			Minimap.coords:Show()
		else
			Minimap.coords:Hide()
		end
	end

	-- Apply Style Settings
	do
		if module.Settings.BG.enabled then
			SUIMinimap.BG.Settings = module.Settings.BG or nil
			if SUIMinimap.BG then SUIMinimap.BG:ClearAllPoints() end

			if module.Settings.BG.size then SUIMinimap.BG:SetSize(unpack(module.Settings.BG.size)) end

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
				SUIMinimap.BG:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -30, 30)
				SUIMinimap.BG:SetPoint('BOTTOMRIGHT', Minimap, 'BOTTOMRIGHT', 30, -30)
			end

			SUIMinimap.BG:SetTexture(module.Settings.BG.texture)
			SUIMinimap.BG:SetAlpha(module.Settings.BG.alpha)
			SUIMinimap.BG:SetBlendMode(module.Settings.BG.BlendMode)

			SUIMinimap.BG:Show()
		else
			SUIMinimap.BG:Hide()
		end

		Minimap.ZoneText:SetSize(Minimap:GetWidth(), 12)
		Minimap.ZoneText:SetTextColor(unpack(module.Settings.ZoneText.TextColor))
		Minimap.ZoneText:SetShadowColor(unpack(module.Settings.ZoneText.ShadowColor))
		Minimap.ZoneText:SetScale(module.Settings.ZoneText.scale)

		Minimap.coords:SetSize(unpack(module.Settings.coords.size))
		Minimap.coords:SetTextColor(unpack(module.Settings.coords.TextColor))
		Minimap.coords:SetShadowColor(unpack(module.Settings.coords.ShadowColor))
		Minimap.coords:SetScale(module.Settings.coords.scale)

		-- If minimap default location is under the minimap setup scripts to move it
		if module.Settings.UnderVehicleUI and SUI.DB.Artwork.VehicleUI and not VisibilityWatcher.hooked and (not MoveIt:IsMoved('Minimap')) then
			local OnHide = function(args)
				if SUI:IsModuleEnabled('Minimap') and SUI.DB.Artwork.VehicleUI and not MoveIt:IsMoved('Minimap') and SUIMinimap.position then
					SUIMinimap:position('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
				end
			end
			local OnShow = function(args)
				if SUI:IsModuleEnabled('Minimap') and SUI.DB.Artwork.VehicleUI and not MoveIt:IsMoved('Minimap') then
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
		elseif (MoveIt:IsMoved('Minimap') or not SUI.DB.Artwork.VehicleUI) and VisibilityWatcher.hooked then
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

		for _, child in ipairs({ Minimap:GetChildren() }) do
			if child:GetName() ~= nil and not isFrameIgnored(child) then
				--catch buttons not playing nice.
				if child.FadeOut == nil then module:SetupButton(child, true) end

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

		for _, child in ipairs({ Minimap:GetChildren() }) do
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

function module:SetActiveStyle(style)
	if Registry[style] then module:update(true) end
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
		hideOnEscape = false,
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
		SUIMapChangesActive = false,
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Minimap', { profile = defaults })
	module.DB = module.Database.profile
	UserSettings = module.DB

	-- Check for Carbonite
	if NXTITLELOW then
		SUI:Print(NXTITLELOW .. ' is loaded ...Checking settings ...')
		if Nx.db.profile.MiniMap.Own == true then
			SUI:Print(NXTITLELOW .. ' is controlling the Minimap')
			SUI:Print('SpartanUI Will not modify or move the minimap unless Carbonite is a separate minimap')
			UserSettings.AutoDetectAllowUse = false
		end
	end

	-- Look for Sexymap or other MiniMap addons
	if SUI:IsAddonEnabled('SexyMap') then UserSettings.AutoDetectAllowUse = false end
end

function module:OnEnable()
	-- Construct options
	module:BuildOptions()
	if (not UserSettings.AutoDetectAllowUse) and not UserSettings.ManualAllowUse then StaticPopup_Show('MiniMapNotice') end
	if SUI:IsModuleDisabled('Minimap') then return end

	updateSettings()

	SUIMinimap:SetFrameStrata('BACKGROUND')
	SUIMinimap:SetFrameLevel(99)
	SUIMinimap:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 0)
	Minimap:HookScript('OnShow', function()
		SUIMinimap:Show()
	end)
	Minimap:HookScript('OnHide', function()
		SUIMinimap:Hide()
	end)

	SUIMinimap.BG = SUIMinimap:CreateTexture(nil, 'BACKGROUND', nil, -8)
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetQuestBlobRingScalar(0)
	module:ModifyMinimapLayout()

	--Look for existing buttons
	MiniMapBtnScrape()

	SUIMinimap:HookScript('OnEnter', OnEnter)
	SUIMinimap:HookScript('OnLeave', OnLeave)
	SUIMinimap:HookScript('OnMouseDown', OnMouseDown)

	-- Setup Updater script for button visibility updates
	MinimapUpdater:SetSize(1, 1)
	MinimapUpdater:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', -128, 128)
	MinimapUpdater:SetScript('OnEvent', function()
		if not InCombatLockdown() then module:ScheduleTimer(PerformFullBtnUpdate, 2, true) end
	end)
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
	MoveIt:CreateMover(SUIMinimap, 'Minimap')
	MinimapCluster.Selection:HookScript('OnShow', function()
		MinimapCluster.Selection:Hide()
	end)

	if ExpansionLandingPageMinimapButton then
		ExpansionLandingPageMinimapButton:HookScript('OnShow', function()
			ExpansionLandingPageMinimapButton:ClearAllPoints()
			ExpansionLandingPageMinimapButton:SetPoint('BOTTOMLEFT', Minimap, 'BOTTOMLEFT', -20, -20)
		end)
	end

	-- If we didint move the minimap before making the mover make sure default is set.
	if MoveIt:IsMoved('Minimap') then SUIMinimap.mover.defaultPoint = module.Settings.position end
end

function module:BuildOptions()
	local options = {
		type = 'group',
		name = L['Minimap'],
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		childGroups = 'tab',
		args = {
			NorthIndicator = {
				name = L['Show North Indicator'],
				type = 'toggle',
				order = 0.1,
				get = function(info)
					return UserSettings.northTag
				end,
				set = function(info, val)
					if InCombatLockdown() then
						SUI:Print(ERR_NOT_IN_COMBAT)
						return
					end
					UserSettings.northTag = val
					if val then
						MinimapNorthTag:Show()
					else
						MinimapNorthTag:Hide()
					end
				end,
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
				end,
			},
			minimapTimeIndicator = {
				name = L['Hide Time Indicator'],
				type = 'toggle',
				hidden = not SUI.IsClassic,
				order = 0.5,
				get = function(info)
					return UserSettings.MapTimeIndicator
				end,
				set = function(info, val)
					UserSettings.MapTimeIndicator = val
					module:update()
				end,
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
					['show'] = 'Always Show',
				},
				get = function(info)
					return UserSettings.OtherStyle
				end,
				set = function(info, val)
					UserSettings.OtherStyle = val
					module:update()
				end,
			},
			rotate = {
				order = 3,
				type = 'toggle',
				name = ROTATE_MINIMAP,
				desc = OPTION_TOOLTIP_ROTATE_MINIMAP,
				get = function()
					return UserSettings.rotate or false
				end,
				set = function(_, value)
					if value then
						C_CVar.SetCVar('rotateMinimap', 1)
					else
						C_CVar.SetCVar('rotateMinimap', 0)
					end
					UserSettings.rotate = value or nil
				end,
			},
			elements = {
				name = 'Elements',
				type = 'group',
				order = 4,
				childGroups = 'tree',
				args = {},
			},
		},
	}

	SUI.Options:AddOptions(options, 'Minimap')
end

---@class SUI.Style.Settings.Minimap
---@field BG? SUI.Settings.Minimap.background
---@field position? string
---@field shape? MapShape
---@field scaleWithArt? boolean
---@field size? table
---@field textLocation? string

---@alias MapShape 'SQUARE' | 'ROUND'

---@class SUI.Settings.Minimap.coords
---@field scale? number
---@field size? table
---@field TextColor? table
---@field ShadowColor? table

---@class SUI.Settings.Minimap.background
---@field enabled? boolean
---@field BlendMode? string
---@field alpha? number
---@field texture? string
---@field size? table
---@field position? string|table
