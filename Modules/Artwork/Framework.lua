local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Component_Artwork')

function module:updateScale()
	--Set default scale based on if the user is using a widescreen.
	if (not SUI.DB.scale) then
		local Resolution = ''
		if select(4, GetBuildInfo()) >= 70000 then
			Resolution = GetCVar('gxWindowedResolution')
		else
			Resolution = GetCVar('gxResolution')
		end

		local width, height = string.match(Resolution, '(%d+).-(%d+)')
		if (tonumber(width) / tonumber(height) > 4 / 3) then
			SUI.DB.scale = 0.92
		else
			SUI.DB.scale = 0.78
		end
	end

	-- Call module scale update if defined.
	local style = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style)
	if style.updateScale then
		style:updateScale()
	end
end

function module:updateHorizontalOffset()
	-- Call module scale update if defined.
	local style = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style)
	if style.updateXOffset then
		style:updateXOffset()
	end
end

function module:updateAlpha()
	-- Call module scale update if defined.
	local style = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style)
	if style.updateAlpha then
		style:updateAlpha()
	end
end

function module:updateOffset()
	if InCombatLockdown() then
		return
	end

	local Top, Bottom = 0, 0
	local Tfubar, TChocolateBar, Ttitan = 0, 0, 0
	local Bfubar, BChocolateBar, Btitan = 0, 0, 0

	if SUI.DB.Offset.TopAuto or SUI.DB.Offset.BottomAuto then
		-- FuBar Offset
		for i = 1, 4 do
			if (_G['FuBarFrame' .. i] and _G['FuBarFrame' .. i]:IsVisible()) then
				local bar = _G['FuBarFrame' .. i]
				local point = bar:GetPoint(1)
				if point:find('TOP.*') then
					Tfubar = Tfubar + bar:GetHeight()
				end
				if point == 'BOTTOMLEFT' then
					Bfubar = Bfubar + bar:GetHeight()
				end
			end
		end

		-- Chocolate Bar Offset
		for i = 1, 100 do
			if (_G['ChocolateBar' .. i] and _G['ChocolateBar' .. i]:IsVisible()) then
				local bar = _G['ChocolateBar' .. i]
				local point = bar:GetPoint(1)
				if point:find('TOP.*') then
					TChocolateBar = TChocolateBar + bar:GetHeight()
				end
				if point == 'RIGHT' then
					BChocolateBar = BChocolateBar + bar:GetHeight()
				end
			end
		end

		-- Titan Bar
		for i, v in ipairs({'Bar2', 'Bar'}) do
			if (_G['Titan_Bar__Display_' .. v] and TitanPanelGetVar(v .. '_Show')) then
				local PanelScale = TitanPanelGetVar('Scale') or 1
				Ttitan = Ttitan + (PanelScale * _G['Titan_Bar__Display_' .. v]:GetHeight())
			end
		end
		for i, v in ipairs({'AuxBar2', 'AuxBar'}) do
			if (_G['Titan_Bar__Display_' .. v] and TitanPanelGetVar(v .. '_Show')) then
				local PanelScale = TitanPanelGetVar('Scale') or 1
				Btitan = Btitan + (PanelScale * _G['Titan_Bar__Display_' .. v]:GetHeight())
			end
		end

		-- Blizz Legion Order Hall
		if OrderHallCommandBar and OrderHallCommandBar:IsVisible() then
			Top = Top + OrderHallCommandBar:GetHeight()
		end

		-- Update DB if set to auto
		if SUI.DB.Offset.TopAuto then
			Top = max(Top + Tfubar + Ttitan + TChocolateBar, 0)
			SUI.DB.Offset.Top = Top
		end
		if SUI.DB.Offset.BottomAuto then
			Bottom = max(Bottom + Bfubar + Btitan + BChocolateBar, 0)
			SUI.DB.Offset.Bottom = Bottom
		end
	end

	-- Call module update if defined.
	local style = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style)
	if style.updateOffset then
		style:updateOffset(SUI.DB.Offset.Top, SUI.DB.Offset.Bottom)
	end

	SpartanUI:ClearAllPoints()
	SpartanUI:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', 0, (SUI.DB.Offset.Top * -1))
	SpartanUI:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 0, SUI.DB.Offset.Bottom)
end

function module:updateViewport()
	if not InCombatLockdown() and SUI.DBMod.Artwork.Viewport.enabled then
		WorldFrame:ClearAllPoints()
		WorldFrame:SetPoint(
			'TOPLEFT',
			UIParent,
			'TOPLEFT',
			SUI.DBMod.Artwork.Viewport.offset.left,
			(SUI.DBMod.Artwork.Viewport.offset.top * -1)
		)
		WorldFrame:SetPoint(
			'BOTTOMRIGHT',
			UIParent,
			'BOTTOMRIGHT',
			(SUI.DBMod.Artwork.Viewport.offset.right * -1),
			SUI.DBMod.Artwork.Viewport.offset.bottom
		)
	end
end

function module:isInTable(tab, frameName)
	for _, v in ipairs(tab) do
		if (strlower(v) == strlower(frameName)) then
			return true
		end
	end
	return false
end

function module:OnInitialize()
	if not SUI.DB.EnabledComponents.Artwork then
		return
	end

	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars == nil then
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
	end
	module:CheckMiniMap()

	-- Loop over the BlizzMovers and execute them
	module.BlizzMovers()
end

function module:SetupPage()
	local PageData = {
		ID = 'ArtworkCore',
		Name = 'SpartanUI style',
		SubTitle = 'Art Style',
		Desc1 = 'Please pick an art style from the options below.',
		RequireReload = true,
		Priority = true,
		Skipable = true,
		NoReloadOnSkip = true,
		RequireDisplay = (not SUI.DBMod.Artwork.SetupDone or false),
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi

			--Container
			SUI_Win.Artwork = CreateFrame('Frame', nil)
			SUI_Win.Artwork:SetParent(SUI_Win)
			SUI_Win.Artwork:SetAllPoints(SUI_Win)

			local RadioButtons = function(self)
				self.radio:Click()
			end

			local control

			--Classic
			control = StdUi:HighlightButton(SUI_Win.Artwork, 120, 60, '')
			control:SetScript('OnClick', RadioButtons)
			control:SetNormalTexture('interface\\addons\\SpartanUI\\Classic\\Images\\base-center')

			control.radio = StdUi:Radio(SUI_Win.Artwork, 'Classic', 'SUIArtwork', 120, 20)
			control.radio:SetValue('Classic')
			StdUi:GlueBelow(control.radio, control)

			SUI_Win.Artwork.Classic = control

			--Fel
			control = StdUi:HighlightButton(SUI_Win.Artwork, 120, 60, '')
			control:SetScript('OnClick', RadioButtons)
			control:SetNormalTexture('interface\\addons\\SpartanUI\\images\\setup\\Style_Fel')

			control.radio = StdUi:Radio(SUI_Win.Artwork, 'Fel', 'SUIArtwork', 120, 20)
			control.radio:SetValue('Fel')
			StdUi:GlueBelow(control.radio, control)

			SUI_Win.Artwork.Fel = control

			--War
			control = StdUi:HighlightButton(SUI_Win.Artwork, 120, 60, '')
			control:SetScript('OnClick', RadioButtons)
			control:SetNormalTexture('interface\\addons\\SpartanUI\\images\\setup\\Style_War')

			control.radio = StdUi:Radio(SUI_Win.Artwork, 'War', 'SUIArtwork', 120, 20)
			control.radio:SetValue('War')
			StdUi:GlueBelow(control.radio, control)

			SUI_Win.Artwork.War = control

			--Digital
			control = StdUi:HighlightButton(SUI_Win.Artwork, 120, 60, '')
			control:SetScript('OnClick', RadioButtons)
			control:SetNormalTexture('interface\\addons\\SpartanUI\\images\\setup\\Style_Digital')

			control.radio = StdUi:Radio(SUI_Win.Artwork, 'Digital', 'SUIArtwork', 120, 20)
			control.radio:SetValue('Digital')
			StdUi:GlueBelow(control.radio, control)

			SUI_Win.Artwork.Digital = control

			--Transparent
			control = StdUi:HighlightButton(SUI_Win.Artwork, 120, 60, '')
			control:SetScript('OnClick', RadioButtons)
			control:SetNormalTexture('interface\\addons\\SpartanUI\\images\\setup\\Style_Transparent')

			control.radio = StdUi:Radio(SUI_Win.Artwork, 'Transparent', 'SUIArtwork', 120, 20)
			control.radio:SetValue('Transparent')
			StdUi:GlueBelow(control.radio, control)

			SUI_Win.Artwork.Transparent = control

			--Minimal
			control = StdUi:HighlightButton(SUI_Win.Artwork, 120, 60, '')
			control:SetScript('OnClick', RadioButtons)
			control:SetNormalTexture('interface\\addons\\SpartanUI\\images\\setup\\Style_Minimal')

			control.radio = StdUi:Radio(SUI_Win.Artwork, 'Minimal', 'SUIArtwork', 120, 20)
			control.radio:SetValue('Minimal')
			StdUi:GlueBelow(control.radio, control)

			SUI_Win.Artwork.Minimal = control

			-- Position the Top row
			StdUi:GlueTop(SUI_Win.Artwork.Fel, SUI_Win, 0, -80)
			StdUi:GlueLeft(SUI_Win.Artwork.Classic, SUI_Win.Artwork.Fel, -20, 0)
			StdUi:GlueRight(SUI_Win.Artwork.War, SUI_Win.Artwork.Fel, 20, 0)

			-- Position the Bottom row
			StdUi:GlueTop(SUI_Win.Artwork.Digital, SUI_Win.Artwork.Fel.radio, 0, -30)
			StdUi:GlueLeft(SUI_Win.Artwork.Transparent, SUI_Win.Artwork.Digital, -20, 0)
			StdUi:GlueRight(SUI_Win.Artwork.Minimal, SUI_Win.Artwork.Digital, 20, 0)

			-- Check Classic as default
			if SUI_Win.Artwork.Classic then
				if not SUI.DBMod.Artwork.Style or SUI.DBMod.Artwork.Style == '' then
					SUI.DBMod.Artwork.Style = 'Classic'
				end
				if SUI_Win.Artwork[SUI.DBMod.Artwork.Style] and SUI_Win.Artwork[SUI.DBMod.Artwork.Style].radio then
					SUI_Win.Artwork[SUI.DBMod.Artwork.Style].radio:SetChecked(true)
				end
			else
				SUI_Win.Artwork.Classic.radio:SetChecked(true)
			end
		end,
		Next = function()
			local window = SUI:GetModule('SetupWizard').window
			local StdUi = window.StdUi
			SUI.DBMod.Artwork.SetupDone = true

			SUI.DBMod.Artwork.Style = StdUi:GetRadioGroupValue('SUIArtwork')

			SUI.DB.Unitframes.Style = SUI.DBMod.Artwork.Style
			SUI.DBMod.Artwork.FirstLoad = true
		end,
		Skip = function()
			SUI.DBMod.Artwork.SetupDone = true
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end

function module:OnEnable()
	if not SUI.DB.EnabledComponents.Artwork then
		return
	end

	module:SetupPage()
	module:updateOffset()
	module:updateViewport()
	module:SetupOptions()
end

function module:CheckMiniMap()
	-- Check for Carbonite dinking with the minimap.
	if (NXTITLELOW) then
		SUI:Print(NXTITLELOW .. ' is loaded ...Checking settings ...')
		if (Nx.db.profile.MiniMap.Own == true) then
			SUI:Print(NXTITLELOW .. ' is controlling the Minimap')
			SUI:Print('SpartanUI Will not modify or move the minimap unless Carbonite is a separate minimap')
			SUI.DB.MiniMap.AutoDetectAllowUse = false
		end
	end

	if select(4, GetAddOnInfo('SexyMap')) then
		SUI:Print(L['SexyMapLoaded'])
		SUI.DB.MiniMap.AutoDetectAllowUse = false
	end

	local _, relativeTo = MinimapCluster:GetPoint()
	if (relativeTo ~= UIParent) then
		SUI:Print('A unknown addon is controlling the Minimap')
		SUI:Print('SpartanUI Will not modify or move the minimap until the addon modifying the minimap is no longer enabled.')
		SUI.DB.MiniMap.AutoDetectAllowUse = false
	end
end
