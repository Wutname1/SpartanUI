local spartan = LibStub('AceAddon-3.0'):GetAddon('SpartanUI')
local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)
local module = spartan:NewModule('Component_Minimap')
----------------------------------------------------------------------------------------------------
local BlizzButtons = {
	'MiniMapTracking',
	'MiniMapVoiceChatFrame',
	'MiniMapWorldMapButton',
	'QueueStatusMinimapButton',
	'MinimapZoomIn',
	'MinimapZoomOut',
	'MiniMapMailFrame',
	'MiniMapBattlefieldFrame',
	'GameTimeFrame',
	'FeedbackUIButton'
}
local BlizzUI = {
	'ActionBar',
	'BonusActionButton',
	'MainMenu',
	'ShapeshiftButton',
	'MultiBar',
	'KeyRingButton',
	'PlayerFrame',
	'TargetFrame',
	'PartyMemberFrame',
	'ChatFrame',
	'ExhaustionTick',
	'TargetofTargetFrame',
	'WorldFrame',
	'ActionButton',
	'CharacterMicroButton',
	'SpellbookMicroButton',
	'TalentMicroButton',
	'QuestLogMicroButton',
	'SocialsMicroButton',
	'LFGMicroButton',
	'HelpMicroButton',
	'CharacterBag',
	'PetFrame',
	'MinimapCluster',
	'MinimapBackdrop',
	'UIParent',
	'WorldFrame',
	'Minimap',
	'BuffButton',
	'BuffFrame',
	'TimeManagerClockButton',
	'CharacterFrame'
}
local BlizzParentStop = {'WorldFrame', 'Minimap', 'MinimapBackdrop', 'UIParent', 'MinimapCluster'}
local SkinProtect = {
	'TutorialFrameAlertButton',
	'MiniMapMailFrame',
	'MinimapBackdrop',
	'MiniMapVoiceChatFrame',
	'TimeManagerClockButton',
	'MinimapButtonFrameDragButton',
	'GameTimeFrame',
	'MiniMapTracking',
	'MiniMapVoiceChatFrame',
	'MiniMapWorldMapButton',
	'QueueStatusMinimapButton',
	'MinimapZoomIn',
	'MinimapZoomOut',
	'MiniMapMailFrame',
	'MiniMapBattlefieldFrame',
	'GameTimeFrame',
	'FeedbackUIButton'
}
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
		SUI.DB.MiniMap.MouseIsOver = true
	else
		SUI.DB.MiniMap.MouseIsOver = false
	end
	return SUI.DB.MiniMap.MouseIsOver
end

local IgnoreCheck = function(item)
	local DoNotIgnore = true
	if item:GetName() ~= nil then
		if string.match(item:GetName(), 'HandyNotes') then
			DoNotIgnore = false
		end
	end
	return DoNotIgnore
end

local MiniMapBtnScrape = function()
	-- Hook Minimap Icons
	for _, child in ipairs({Minimap:GetChildren()}) do
		if child.FadeIn == nil and IgnoreCheck(child) then
			module:SetupButton(child)
		end
	end
	if CensusButton ~= nil and CensusButton.FadeIn == nil then
		module:SetupButton(CensusButton)
	end
end

local PerformFullBtnUpdate = function()
	if LastUpdateStatus ~= IsMouseOver() then
		MiniMapBtnScrape()
		--update visibility
		module:updateButtons()
	end
end

local OnEnter = function()
	if SUI.DB.MiniMap.MouseIsOver then
		return
	end
	--don't use PerformFullBtnUpdate as we want to perform the actions in reverse. since any new unknown icons will already be shown.
	if LastUpdateStatus ~= IsMouseOver() then
		module:updateButtons()
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

function module:ShapeChange(shape)
	Minimap:SetArchBlobRingScalar(0)
	Minimap:SetQuestBlobRingScalar(0)

	if shape == 'square' then
		Minimap:SetMaskTexture('Interface\\BUTTONS\\WHITE8X8')
		MiniMapTracking:ClearAllPoints()
		MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, 5)
	else
		Minimap:SetMaskTexture('Interface\\AddOns\\SpartanUI\\media\\map-circle-overlay')
		MiniMapTracking:ClearAllPoints()
		MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, -5)
	end

	local Style = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style)
	if Style.Settings.MiniMap.size then
		Minimap:SetSize(unpack(Style.Settings.MiniMap.size))
	end
	if Style.Settings.MiniMap.Anchor then
		Minimap:ClearAllPoints()
		Minimap:SetPoint(unpack(Style.Settings.MiniMap.Anchor))
	end

	Minimap.ZoneText:ClearAllPoints()
	if Style.Settings.MiniMap.TextLocation == 'TOP' then
		Minimap.ZoneText:SetPoint('BOTTOMLEFT', Minimap, 'TOPLEFT', 0, 4)
		Minimap.ZoneText:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT', 0, 4)
	else
		Minimap.ZoneText:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -4)
		Minimap.ZoneText:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -4)
	end

	Minimap.coords:ClearAllPoints()
	if
		(Style.Settings.MiniMap.coordsLocation == 'TOP' and Style.Settings.MiniMap.TextLocation == 'TOP') or
			(Style.Settings.MiniMap.coordsLocation == 'BOTTOM' and Style.Settings.MiniMap.TextLocation == 'BOTTOM')
	 then
		Minimap.coords:SetPoint('TOPLEFT', Minimap.ZoneText, 'BOTTOMLEFT', 0, -4)
		Minimap.coords:SetPoint('TOPRIGHT', Minimap.ZoneText, 'BOTTOMRIGHT', 0, -4)
	elseif Style.Settings.MiniMap.TextLocation == 'TOP' and Style.Settings.MiniMap.coordsLocation == 'BOTTOM' then
		Minimap.coords:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -4)
		Minimap.coords:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -4)
	elseif Style.Settings.MiniMap.TextLocation == 'BOTTOM' and Style.Settings.MiniMap.coordsLocation == 'TOP' then
		Minimap.coords:SetPoint('BOTTOMLEFT', Minimap, 'TOPLEFT', 0, 4)
		Minimap.coords:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT', 0, 4)
	end

	MinimapZoneText:SetShadowColor(0, 0, 0, 1)
	MinimapZoneText:SetShadowOffset(1, -1)
end

function module:OnInitialize()
	StaticPopupDialogs['MiniMapNotice'] = {
		text = '|cff33ff99SpartanUI Notice|n|r|n Another addon has been found modifying the minimap. Do you give permisson for SpartanUI to move and possibly modify the minimap as your theme dictates? |n|n You can change this option in the settings should you change your mind.',
		button1 = 'Yes',
		button2 = 'No',
		OnAccept = function()
			SUI.DB.MiniMap.ManualAllowPrompt = SUI.DB.Version
			SUI.DB.MiniMap.ManualAllowUse = true
			ReloadUI()
		end,
		OnCancel = function()
			SUI.DB.MiniMap.ManualAllowPrompt = SUI.DB.Version
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
end

function module:OnEnable()
	-- MiniMap Modification
	if
		(((not SUI.DB.MiniMap.AutoDetectAllowUse) and (not SUI.DB.MiniMap.ManualAllowUse)) and
			SUI.DB.MiniMap.ManualAllowPrompt ~= SUI.DB.Version)
	 then
		StaticPopup_Show('MiniMapNotice')
	end
	if not SUI.DB.EnabledComponents.Minimap then
		return
	end

	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].Movable.Minimap or (not spartan:GetModule('Artwork_Core', true)) then
		Minimap.mover = CreateFrame('Frame')
		Minimap.mover:SetSize(5, 5)
		Minimap.mover:SetAllPoints(Minimap)
		Minimap.mover.bg = Minimap.mover:CreateTexture(nil, 'BACKGROUND')
		Minimap.mover.bg:SetAllPoints(Minimap.mover)
		Minimap.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		Minimap.mover.bg:SetVertexColor(1, 1, 1, 0.8)
		Minimap.mover:EnableMouse(true)
		Minimap.mover:Hide()

		Minimap:HookScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' and IsAltKeyDown() then
					Minimap.mover:Show()
					if spartan:GetModule('Artwork_Core', true) then
						SUI.DB.Styles[SUI.DBMod.Artwork.Style].Movable.MinimapMoved = true
					else
						SUI.DB.MiniMap.Moved = true
					end
					Minimap:SetMovable(true)
					Minimap:StartMoving()
				end
			end
		)

		Minimap:HookScript(
			'OnMouseUp',
			function(self, button)
				Minimap.mover:Hide()
				Minimap:StopMovingOrSizing()
				if spartan:GetModule('Artwork_Core', true) then
					SUI.DB.Styles[SUI.DBMod.Artwork.Style].Movable.MinimapCords = {Minimap:GetPoint(Minimap:GetNumPoints())}
				else
					SUI.DB.MiniMap.Position = {Minimap:GetPoint(Minimap:GetNumPoints())}
				end
			end
		)

		if
			spartan:GetModule('Artwork_Core', true) and SUI.DB.Styles[SUI.DBMod.Artwork.Style].Movable.MinimapMoved and
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].Movable.Minimap and
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].Movable.MinimapCords ~= nil
		 then
			local a, _, c, d, e = unpack(SUI.DB.Styles[SUI.DBMod.Artwork.Style].Movable.MinimapCords) -- do this as the parent can get corrupted
			Minimap:ClearAllPoints()
			Minimap:SetPoint(a, UIParent, c, d, e)
		elseif SUI.DB.MiniMap.Position ~= nil then
			Minimap:ClearAllPoints()
			Minimap:SetPoint(unpack(SUI.DB.MiniMap.Position))
		end
	end

	module:ModifyMinimapLayout()

	--Look for existing buttons
	MiniMapBtnScrape()

	-- Fix CPU leak, use UpdateInterval
	Minimap:HookScript('OnEnter', OnEnter)
	Minimap:HookScript('OnLeave', OnLeave)

	Minimap:HookScript('OnMouseDown', OnMouseDown)

	--Initialize Buttons
	module:updateButtons()
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

	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].Minimap ~= nil then
		if SUI.DB.Styles[SUI.DBMod.Artwork.Style].Minimap.shape == 'square' then
			Minimap:SetMaskTexture('Interface\\BUTTONS\\WHITE8X8')

			Minimap:SetArchBlobRingScalar(0)
			Minimap:SetQuestBlobRingScalar(0)

			Minimap.overlay = Minimap:CreateTexture(nil, 'OVERLAY')
			Minimap.overlay:SetTexture('Interface\\AddOns\\SpartanUI\\Media\\map-square-overlay')
			Minimap.overlay:SetAllPoints(Minimap)
			Minimap.overlay:SetBlendMode('ADD')

			MinimapZoneTextButton:SetPoint('BOTTOMLEFT', Minimap, 'TOPLEFT', 0, 4)
			MinimapZoneTextButton:SetPoint('BOTTOMRIGHT', Minimap, 'TOPRIGHT', 0, 4)
			MinimapZoneText:SetShadowColor(0, 0, 0, 1)
			MinimapZoneText:SetShadowOffset(1, -1)

			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', 0, 0)
		else
			Minimap:SetMaskTexture('Interface\\AddOns\\SpartanUI\\media\\map-circle-overlay')

			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, -5)
		end
	end
	if not SUI.DB.MiniMap.northTag then
		MinimapNorthTag:Hide()
	else
		MinimapNorthTag:Show()
	end

	Minimap:ClearAllPoints()
	Minimap:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -30, -30)

	TimeManagerClockButton:GetRegions():Hide() -- Hide the border
	TimeManagerClockButton:SetBackdrop(nil)
	TimeManagerClockButton:ClearAllPoints()
	TimeManagerClockButton:SetPoint('TOP', Minimap, 'BOTTOM', 0, 20)
	TimeManagerClockButton:SetBackdropColor(0, 0, 0, 1)
	TimeManagerClockButton:SetBackdropBorderColor(0, 0, 0, 1)

	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetPoint('CENTER', Minimap, 'CENTER', -10, -24)

	MinimapBorderTop:Hide()
	MinimapBorder:Hide()

	MiniMapInstanceDifficulty:ClearAllPoints()
	MiniMapInstanceDifficulty:SetPoint('TOPLEFT', Minimap, 4, 22)
	GuildInstanceDifficulty:ClearAllPoints()
	GuildInstanceDifficulty:SetPoint('TOPLEFT', Minimap, 4, 22)

	GarrisonLandingPageMinimapButton:ClearAllPoints()
	GarrisonLandingPageMinimapButton:SetSize(35, 35)
	GarrisonLandingPageMinimapButton:SetPoint('RIGHT', Minimap, 18, -25)

	-- Do modifications to MiniMapWorldMapButton
	--	-- remove current textures
	MiniMapWorldMapButton:SetNormalTexture(nil)
	MiniMapWorldMapButton:SetPushedTexture(nil)
	MiniMapWorldMapButton:SetHighlightTexture(nil)
	--	-- Create new textures
	MiniMapWorldMapButton:SetNormalTexture('Interface\\AddOns\\SpartanUI\\media\\WorldMap-Icon.png')
	MiniMapWorldMapButton:SetPushedTexture('Interface\\AddOns\\SpartanUI\\media\\WorldMap-Icon-Pushed.png')
	MiniMapWorldMapButton:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
	MiniMapWorldMapButton:ClearAllPoints()
	MiniMapWorldMapButton:SetPoint('TOPRIGHT', Minimap, -20, 12)

	MiniMapMailFrame:ClearAllPoints()
	MiniMapMailFrame:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 21, -53)

	GameTimeFrame:ClearAllPoints()
	GameTimeFrame:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', 20, -16)

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

	module:MinimapCoords()
	MinimapZoneText:ClearAllPoints()
	MinimapZoneText:SetAllPoints(MinimapZoneTextButton)
end

function module:MinimapCoords()
	MinimapZoneText:Hide()

	Minimap.ZoneText = Minimap:CreateFontString(nil, 'OVERLAY', 'SUI_Font10')
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

	Minimap.coords = Minimap:CreateFontString(nil, 'OVERLAY', 'SUI_Font9')
	Minimap.coords:SetSize(9, 12)
	Minimap.coords:SetJustifyH('TOP')
	Minimap.coords:SetPoint('TOPLEFT', Minimap.ZoneText, 'BOTTOMLEFT', 0, 0)
	Minimap.coords:SetPoint('TOPRIGHT', Minimap.ZoneText, 'BOTTOMRIGHT', 0, 0)
	Minimap.coords:SetShadowColor(0, 0, 0, 1)
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
		--Get the Cords we are at for said map
		local x, y = C_Map.GetPlayerMapPosition(mapID, 'player'):GetXY()
		if (not x) or (not y) then
			return
		end
		--Update label
		Minimap.ZoneText:SetText(GetMinimapZoneText())
		Minimap.coords:SetText(format('%.1f, %.1f', x * 100, y * 100))
	end
	UpdateCoords()
end

function module:SetupButton(btn, force)
	buttonName = btn:GetName()
	buttonType = btn:GetObjectType()

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
				if not SUI.DB.MiniMap.SUIMapChangesActive then
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

function module:updateButtons()
	if (SUI.DB.MiniMap.MapZoomButtons) then
		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	else
		MinimapZoomIn:Show()
		MinimapZoomOut:Show()
	end

	SUI.DB.MiniMap.SUIMapChangesActive = true
	if not IsMouseOver() and (SUI.DB.MiniMap.OtherStyle == 'mouseover' or SUI.DB.MiniMap.OtherStyle == 'hide') then
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

		for _, child in ipairs({Minimap:GetChildren()}) do
			buttonName = child:GetName()

			--catch buttons not playing nice.
			if child.FadeOut == nil and IgnoreCheck(child) then
				module:SetupButton(child, true)
			end

			if
				buttonName and -- and buttonType == "Button"
					child.FadeOut ~= nil and
					(not spartan:isInTable(IgnoredFrames, buttonName)) and
					child:GetAlpha() == 1
			 then
				child.FadeIn:Stop()
				child.FadeOut:Stop()
				child.FadeOut:Play()
			elseif child.FadeIn == nil and IgnoreCheck(child) then
				--if they still fail print a error and continue with our lives.
				spartan.Err('Minimap', buttonName .. ' is not fading')
			end
		end
	elseif SUI.DB.MiniMap.OtherStyle ~= 'hide' then
		if CensusButton ~= nil and CensusButton:GetAlpha() == 0 then
			CensusButton.FadeIn:Stop()
			CensusButton.FadeOut:Stop()
			CensusButton.FadeIn:Play()
		end

		for _, child in ipairs({Minimap:GetChildren()}) do
			buttonName = child:GetName()
			-- buttonType = child:GetObjectType();

			if
				buttonName and child.FadeIn ~= nil and (not spartan:isInTable(IgnoredFrames, buttonName)) and child:GetAlpha() == 0
			 then
				child.FadeIn:Stop()
				child.FadeOut:Stop()

				child.FadeIn:Play()
			end
		end
	end
	LastUpdateStatus = IsMouseOver()
	SUI.DB.MiniMap.SUIMapChangesActive = false

	if SUI.DB.MiniMap.northTag then
		MinimapNorthTag:Show()
	else
		MinimapNorthTag:Hide()
	end
end

function module:BuildOptions()
	spartan.opt.args['ModSetting'].args['Minimap'] = {
		type = 'group',
		name = L['Minimap'],
		args = {
			NorthIndicator = {
				name = 'Show North Indicator',
				type = 'toggle',
				order = 0.1,
				get = function(info)
					return SUI.DB.MiniMap.northTag
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						spartan:Print(ERR_NOT_IN_COMBAT)
						return
					end
					SUI.DB.MiniMap.northTag = val
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
					return SUI.DB.MiniMap.MapZoomButtons
				end,
				set = function(info, val)
					SUI.DB.MiniMap.MapZoomButtons = val
					module:updateButtons()
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
					return SUI.DB.MiniMap.OtherStyle
				end,
				set = function(info, val)
					SUI.DB.MiniMap.OtherStyle = val
					module:updateButtons()
				end
			}
			-- minimapbuttons = {name = L["MinMapHidebtns"], type="toggle", width="full",
			-- get = function(info) return SUI.DB.MiniMap.MapButtons; end,
			-- set = function(info,val) SUI.DB.MiniMap.MapButtons = val;  end
			-- },
			-- BlizzStyle = {
			-- name="Blizzard Icons",
			-- type="select",
			-- style="dropdown",
			-- width="full",
			-- values = {
			-- ["hide"]	= "Always Hide",
			-- ["mouseover"]	= "Show on Mouse over",
			-- ["show"]	= "Always Show",
			-- },
			-- get = function(info) return SUI.DB.MiniMap.BlizzStyle; end,
			-- set = function(info,val) SUI.DB.MiniMap.BlizzStyle = val; end
			-- },
		}
	}
end

function module:HideOptions()
	spartan.opt.args['ModSetting'].args['Minimap'].disabled = true
end
