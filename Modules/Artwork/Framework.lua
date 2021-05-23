local SUI, L = SUI, SUI.L
local module = SUI:NewModule('Component_Artwork', 'AceTimer-3.0', 'AceEvent-3.0')
module.ActiveStyle = {}
module.BarBG = {}
module.description = 'CORE: Provides the graphical looks of SUI'
module.Core = true
local styleArt
local petbattle = CreateFrame('FRAME')
-------------------------------------------------

local function SetupPage()
	local PageData = {
		ID = 'ArtworkCore',
		Name = 'SpartanUI style',
		SubTitle = 'Art Style',
		Desc1 = 'Please pick an art style from the options below.',
		Priority = true,
		RequireDisplay = (not SUI.DB.Artwork.SetupDone or false),
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
			local SetStyle = function(self)
				local NewStyle = StdUi:GetRadioGroupValue('SUIArtwork')
				if SUI.DB.Artwork.Style == NewStyle then
					return
				end

				SUI:SetActiveStyle(NewStyle)
			end

			for _, v in ipairs({'Classic', 'Fel', 'War', 'Transparent', 'Digital', 'Minimal', 'Arcane', 'Tribal'}) do
				local control = StdUi:HighlightButton(SUI_Win.Artwork, 120, 60, '')
				control:SetScript('OnClick', RadioButtons)
				control:SetNormalTexture('interface\\addons\\SpartanUI\\images\\setup\\Style_' .. v)

				control.radio = StdUi:Radio(SUI_Win.Artwork, v, 'SUIArtwork', 120, 20)
				control.radio:SetValue(v)
				control.radio:HookScript('OnClick', SetStyle)
				StdUi:GlueBelow(control.radio, control)

				SUI_Win.Artwork[v] = control
			end

			SUI_Win.Artwork.slider = StdUi:Slider(SUI_Win.Artwork, 340, 15, 50, false, 1, 100)
			StdUi:AddLabel(SUI_Win.Artwork, SUI_Win.Artwork.slider, 'UI Scale', 'LEFT')
			SUI_Win.Artwork.sliderText = StdUi:SimpleEditBox(SUI_Win.Artwork, 40, 15)
			SUI_Win.Artwork.sliderText:Disable()
			SUI_Win.Artwork.sliderButton = StdUi:Button(SUI_Win.Artwork, 40, 15, 'reset')
			-- Slider Actions
			SUI_Win.Artwork.slider:SetScript(
				'OnValueChanged',
				function(self)
					local calculate = SUI_Win.Artwork.slider:GetValue()
					if math.floor(calculate) ~= math.floor(calculate) then
						SUI_Win.Artwork.slider:SetValue(math.floor(calculate))
						return
					end

					local scale = math.floor(SUI_Win.Artwork.slider:GetValue()) / 100
					SUI_Win.Artwork.sliderText:SetText(scale)

					SUI.DB.scale = scale

					-- Update screen
					module:UpdateScale()

					if scale ~= 0.92 then
						SUI_Win.Artwork.sliderButton:Enable()
						SUI_Win.Artwork.sliderButton:Show()
					else
						SUI_Win.Artwork.sliderButton:Disable()
						SUI_Win.Artwork.sliderButton:Hide()
					end
				end
			)
			SUI_Win.Artwork.sliderButton:SetScript(
				'OnClick',
				function()
					SUI_Win.Artwork.slider:SetValue(92)
				end
			)
			SUI_Win.Artwork.slider:SetValue(SUI.DB.scale * 100)

			-- Position Slider elements
			StdUi:GlueTop(SUI_Win.Artwork.slider, SUI_Win.Artwork, 0, -30)
			StdUi:GlueRight(SUI_Win.Artwork.sliderText, SUI_Win.Artwork.slider, 0, 0)
			StdUi:GlueRight(SUI_Win.Artwork.sliderButton, SUI_Win.Artwork.sliderText, 0, 0)

			-- Position the 1st row
			StdUi:GlueTop(SUI_Win.Artwork.Fel, SUI_Win, 0, -80)
			StdUi:GlueLeft(SUI_Win.Artwork.Classic, SUI_Win.Artwork.Fel, -20, 0)
			StdUi:GlueRight(SUI_Win.Artwork.War, SUI_Win.Artwork.Fel, 20, 0)

			-- Position the 2nd row
			StdUi:GlueTop(SUI_Win.Artwork.Digital, SUI_Win.Artwork.Fel.radio, 0, -30)
			StdUi:GlueLeft(SUI_Win.Artwork.Transparent, SUI_Win.Artwork.Digital, -20, 0)
			StdUi:GlueRight(SUI_Win.Artwork.Minimal, SUI_Win.Artwork.Digital, 20, 0)

			-- Podition the 3rd row
			StdUi:GlueTop(SUI_Win.Artwork.Arcane, SUI_Win.Artwork.Digital.radio, 00, -30)
			StdUi:GlueLeft(SUI_Win.Artwork.Tribal, SUI_Win.Artwork.Arcane, -20, 0)

			-- Check Classic as default
			SUI_Win.Artwork.War.radio:SetChecked(true)
		end,
		Next = function()
			SUI.DB.Artwork.SetupDone = true
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end

local function StyleUpdate()
	module:UpdateScale()
	module:UpdateAlpha()
	module:updateOffset()
	module:updateHorizontalOffset()
	module:updateViewport()
	module:UpdateBarBG()
end

function module:SetActiveStyle(style)
	if style and style ~= SUI.DB.Artwork.Style then
		-- Cache the styles to swap
		local OldStyle = SUI:GetModule('Style_' .. SUI.DB.Artwork.Style)
		local NewStyle = SUI:GetModule('Style_' .. style)

		-- Update the DB
		SUI.DB.Artwork.Style = style

		-- Disable the current style and enable the one we want
		OldStyle:Disable()
		NewStyle:Enable()

		--Update bars
		SUI:GetModule('Component_BarHandler').Refresh()

		--Update minimap
		SUI:GetModule('Component_Minimap'):update(true)
	end

	-- Update style settings shortcut
	module.ActiveStyle = SUI.DB.Styles[SUI.DB.Artwork.Style]
	styleArt = _G['SUI_Art_' .. SUI.DB.Artwork.Style]

	--Send Custom change event
	SUI.Event:SendEvent('ARTWORK_STYLE_CHANGED')

	-- Update core elements based on new style
	StyleUpdate()
end

function module:UpdateScale()
	-- Set overall UI scale
	SpartanUI:SetScale(SUI.DB.scale)

	-- Call style scale update if defined.
	local style = SUI:GetModule('Style_' .. SUI.DB.Artwork.Style)
	if style.UpdateScale then
		style:UpdateScale()
	end
	if SUI:IsModuleEnabled('UnitFrames') then
		SUI:GetModule('Component_UnitFrames'):ScaleFrames(SUI.DB.scale)
	end

	-- Call Minimap scale update
	if SUI.DB.Styles[SUI.DB.Artwork.Style].Minimap.scaleWithArt then
		SUI:GetModule('Component_Minimap'):UpdateScale()
	end

	-- Update Bar scales
	SUI:GetModule('Component_BarHandler'):Refresh()
end

function module:UpdateAlpha()
	if styleArt then
		styleArt:SetAlpha(SUI.DB.alpha)
	end
	-- Call module scale update if defined.
	local style = SUI:GetModule('Style_' .. SUI.DB.Artwork.Style)
	if style.UpdateAlpha then
		style:UpdateAlpha()
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
			local bar = _G['FuBarFrame' .. i]
			if (bar and bar:IsVisible()) then
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
			local bar = _G['ChocolateBar' .. i]
			if (bar and bar:IsVisible()) then
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
		local TitanBars = {['Bar2'] = 'top', ['Bar'] = 'top', ['AuxBar2'] = 'bottom', ['AuxBar'] = 'bottom'}
		for k, v in pairs(TitanBars) do
			local bar = _G['Titan_Bar__Display_' .. k]
			if bar and bar:IsVisible() then
				if v == 'top' then
					Ttitan = Ttitan + ((TitanPanelGetVar('Scale') or 1) * bar:GetHeight())
				else
					Btitan = Btitan + ((TitanPanelGetVar('Scale') or 1) * bar:GetHeight())
				end
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
	local style = SUI:GetModule('Style_' .. SUI.DB.Artwork.Style)
	if style.updateOffset then
		style:updateOffset(SUI.DB.Offset.Top, SUI.DB.Offset.Bottom)
	end

	SpartanUI:ClearAllPoints()
	SpartanUI:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', 0, (SUI.DB.Offset.Top * -1))
	if SUI.DB.Offset.BottomAuto and _G['TitanPanelBottomAnchor'] then
		SpartanUI:SetPoint('BOTTOMLEFT', _G['TitanPanelBottomAnchor'], 'BOTTOMLEFT', 0, 0)
	else
		SpartanUI:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 0, SUI.DB.Offset.Bottom)
	end
end

function module:updateHorizontalOffset()
	SUI_BottomAnchor:ClearAllPoints()
	SUI_BottomAnchor:SetPoint('BOTTOM', SpartanUI, 'BOTTOM', SUI.DB.Offset.Horizontal.Bottom, 0)

	SUI_TopAnchor:ClearAllPoints()
	SUI_TopAnchor:SetPoint('TOP', SpartanUI, 'TOP', SUI.DB.Offset.Horizontal.Top, 0)

	-- Call module scale update if defined.
	local style = SUI:GetModule('Style_' .. SUI.DB.Artwork.Style)
	if style.updateXOffset then
		style:updateXOffset()
	end
end

function module:updateViewport()
	if not InCombatLockdown() and SUI.DB.Artwork.Viewport.enabled then
		WorldFrame:ClearAllPoints()
		WorldFrame:SetPoint(
			'TOPLEFT',
			UIParent,
			'TOPLEFT',
			SUI.DB.Artwork.Viewport.offset.left,
			(SUI.DB.Artwork.Viewport.offset.top * -1)
		)
		WorldFrame:SetPoint(
			'BOTTOMRIGHT',
			UIParent,
			'BOTTOMRIGHT',
			(SUI.DB.Artwork.Viewport.offset.right * -1),
			SUI.DB.Artwork.Viewport.offset.bottom
		)
	end
end

function module:OnInitialize()
	if SUI.DB.DisabledComponents.Artwork then
		return
	end

	-- Setup options
	module:SetupOptions()

	-- Initalize style
	module:SetActiveStyle()

	-- Loop over the BlizzMovers and execute them
	module.BlizzMovers()
end

local function VehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		petbattle:HookScript(
			'OnHide',
			function()
				SUI_Art_War:Hide()
				if SUI:IsModuleEnabled('Minimap') and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
					Minimap:Hide()
				end
			end
		)
		petbattle:HookScript(
			'OnShow',
			function()
				SUI_Art_War:Show()
				if SUI:IsModuleEnabled('Minimap') and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
					Minimap:Show()
				end
			end
		)
		RegisterStateDriver(SpartanUI, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:OnEnable()
	if SUI.DB.DisabledComponents.Artwork then
		return
	end

	if SUI:GetModule('Component_BarHandler') then
		SUI:GetModule('Component_BarHandler').Refresh()
	end

	SetupPage()
	VehicleUI()
	StyleUpdate()
	module:RegisterEvent('ADDON_LOADED', StyleUpdate)
end

function module:UpdateBarBG()
	if not module.BarBG[SUI.DB.Artwork.Style] then
		return
	end
	local usersettings = module.ActiveStyle.Artwork.barBG
	for i, bgFrame in pairs(module.BarBG[SUI.DB.Artwork.Style]) do
		if usersettings[i] then
			if usersettings[i].enabled then
				bgFrame:Show()
				bgFrame.BG:Show()
				bgFrame.BG:SetAlpha((bgFrame.skinSettings.alpha or 1) * usersettings[i].alpha)
			else
				bgFrame:Hide()
				bgFrame.BG:Hide()
			end
		end
	end
end

function module:CreateBarBG(skinSettings, number, parent)
	local frame = CreateFrame('Frame', skinSettings.name .. '_Bar' .. number, (parent or UIParent))
	frame.skinSettings = skinSettings
	frame:SetFrameStrata('BACKGROUND')
	frame:SetSize((skinSettings.width or 400), (skinSettings.height or 32))
	frame.BG = frame:CreateTexture(skinSettings.name .. '_Bar' .. number .. 'BG', 'BACKGROUND')
	frame.BG:SetTexture(skinSettings.TexturePath)
	frame.BG:SetTexCoord(unpack(skinSettings.TexCoord or {0, 1, 0, 1}))
	frame.BG:SetAlpha(skinSettings.alpha or 1)
	if skinSettings.point then
		frame.BG:SetPoint(skinSettings.point)
	else
		frame.BG:SetAllPoints(frame)
	end

	if not module.BarBG[skinSettings.name] then
		module.BarBG[skinSettings.name] = {}
	end
	module.BarBG[skinSettings.name][tostring(number)] = frame

	module:UpdateBarBG()

	return frame
end
