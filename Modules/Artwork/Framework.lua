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

function module:updateOffset()
	if InCombatLockdown() then
		return
	end

	local Top = 0
	local offset = 0
	local fubar, ChocolateBar, titan = 0, 0, 0

	if not SUI.DB.yoffsetAuto then
		offset = max(SUI.DB.yoffset, 0)
	else
		for i = 1, 4 do -- FuBar Offset
			if (_G['FuBarFrame' .. i] and _G['FuBarFrame' .. i]:IsVisible()) then
				local bar = _G['FuBarFrame' .. i]
				local point = bar:GetPoint(1)
				if point:find('TOP.*') then
					Top = Top + bar:GetHeight()
				end
				if point == 'BOTTOMLEFT' then
					fubar = fubar + bar:GetHeight()
				end
			end
		end

		for i = 1, 100 do -- Chocolate Bar Offset
			if (_G['ChocolateBar' .. i] and _G['ChocolateBar' .. i]:IsVisible()) then
				local bar = _G['ChocolateBar' .. i]
				local point = bar:GetPoint(1)
				if point:find('TOP.*') then
					Top = Top + bar:GetHeight()
				end
				if point == 'RIGHT' then
					ChocolateBar = ChocolateBar + bar:GetHeight()
				end
			end
		end

		local TitanTopBar = {[1] = 'Bar2', [2] = 'Bar'} -- Top 2 Bar names
		for i = 1, 2 do
			if (_G['Titan_Bar__Display_' .. TitanTopBar[i]] and TitanPanelGetVar(TitanTopBar[i] .. '_Show')) then
				local PanelScale = TitanPanelGetVar('Scale') or 1
				Top = Top + (PanelScale * _G['Titan_Bar__Display_' .. TitanTopBar[i]]:GetHeight())
			end
		end

		local TitanBarOrder = {[1] = 'AuxBar2', [2] = 'AuxBar'} -- Bottom 2 Bar names

		for i = 1, 2 do
			if (_G['Titan_Bar__Display_' .. TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i] .. '_Show')) then
				local PanelScale = TitanPanelGetVar('Scale') or 1
				titan = titan + (PanelScale * _G['Titan_Bar__Display_' .. TitanBarOrder[i]]:GetHeight())
			end
		end

		if OrderHallCommandBar and OrderHallCommandBar:IsVisible() then
			Top = Top + OrderHallCommandBar:GetHeight()
		end

		offset = max(fubar + titan + ChocolateBar, 0)
		SUI.DB.yoffset = offset
	end

	-- Call module scale update if defined.
	local style = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style)
	if style.updateOffset then
		style:updateOffset(Top, offset)
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

function module:ActionBarPlates(plate, excludelist)
	return
	-- local lib = LibStub('LibWindow-1.1', true)
	-- if not lib then
	-- 	return
	-- end
	-- function lib.RegisterConfig(frame, storage, names)
	-- 	if not lib.windowData[frame] then
	-- 		lib.windowData[frame] = {}
	-- 	end
	-- 	lib.windowData[frame].names = names
	-- 	lib.windowData[frame].storage = storage

	-- 	-- If no name return, helps avoid other addons that use the library
	-- 	if (frame:GetName() == nil) then
	-- 		return
	-- 	end

	-- 	-- Catch if Movedbars is not initalized
	-- 	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars == nil then
	-- 		SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
	-- 	end
	-- 	local excluded = false
	-- 	if excludelist then
	-- 		for _, key in ipairs(excludelist) do
	-- 			if frame:GetName():match(key) then
	-- 				excluded = true
	-- 			end
	-- 		end
	-- 	end

	-- 	-- If the name contains Bartender and we have not moved it set the parent to what is in sorage
	-- 	if
	-- 		(frame:GetName():match('BT4Bar') and not excluded) and
	-- 			not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[frame:GetName()]
	-- 	 then
	-- 		frame:SetParent(plate)
	-- 		frame:SetFrameStrata('LOW')
	-- 	else
	-- 		storage.parent = UIParent
	-- 	end
	-- end
end

function module:OnInitialize()
	if not SUI.DB.EnabledComponents.Artwork then
		return
	end

	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars == nil then
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
	end
	module:CheckMiniMap()
end

function module:FirstTime()
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
			SUI.DBG.BartenderChangesActive = true
			module:SetupProfile()

			--Reset Moved bars
			SUI.DBG.BartenderChangesActive = true
			if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars == nil then
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
			end
			local FrameList = {
				BT4Bar1,
				BT4Bar2,
				BT4Bar3,
				BT4Bar4,
				BT4Bar5,
				BT4Bar6,
				BT4BarBagBar,
				BT4BarExtraActionBar,
				BT4BarStanceBar,
				BT4BarPetBar,
				BT4BarMicroMenu
			}
			for _, v in ipairs(FrameList) do
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = false
			end
			SUI.DBG.BartenderChangesActive = false
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

	module:FirstTime()
	module:SetupOptions()

	local FrameList = {
		BT4Bar1,
		BT4Bar2,
		BT4Bar3,
		BT4Bar4,
		BT4Bar5,
		BT4Bar6,
		BT4Bar7,
		BT4Bar8,
		BT4Bar9,
		BT4Bar10,
		BT4BarBagBar,
		BT4BarExtraActionBar,
		BT4BarStanceBar,
		BT4BarPetBar,
		BT4BarMicroMenu
	}

	for _, v in ipairs(FrameList) do
		if v then
			v.SavePosition = function()
				if
					(not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] or v:GetParent():GetName() ~= 'UIParent') and
						not SUI.DBG.BartenderChangesActive
				 then
					SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = true
					LibStub('LibWindow-1.1').windowData[v].storage.parent = UIParent
					v:SetParent(UIParent)
				end

				LibStub('LibWindow-1.1').SavePosition(v)
			end
		end
	end
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

-- Bartender4 Items
function module:SetupProfile(ProfileOverride)
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo('Bartender4'))) then
		return
	end

	--Flag the SUI.DB that we are making changes
	SUI.DBG.BartenderChangesActive = true
	--Load the profile name the art style wants
	local ProfileName = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile
	--Check if we are overriding the art
	if ProfileOverride then
		ProfileName = ProfileOverride
	end

	--Load the BT settings used by the art style
	local BartenderSettings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderSettings

	--If this is set then we have already setup the bars once, and the user changed them
	if
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile and SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile ~= ProfileName and
			not ProfileOverride
	 then
		return
	end

	-- Set/Create our Profile
	Bartender4.db:SetProfile(ProfileName)

	--Load the Profile Data
	for k, v in LibStub('AceAddon-3.0'):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = SUI:MergeData(v.db.profile, BartenderSettings[k], true)
		end
	end
	SUI.DBG.BartenderChangesActive = false
end

function module:BartenderProfileCheck(Input, Report)
	if not Bartender4 then
		return
	end

	local profiles, r = Bartender4.db:GetProfiles(), false
	for _, v in pairs(profiles) do
		if v == Input then
			r = true
		end
	end
	if (Report) and (r ~= true) then
		SUI:Print(Input .. ' ' .. L['BartenderProfileCheckFail'])
	end
	return r
end

function module:CreateProfile()
	SUI.DBG.BartenderChangesActive = true
	local ProfileName = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile
	local BartenderSettings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderSettings
	--If this is set then we have already setup the bars once, and the user changed them
	if
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile and SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile ~= ProfileName
	 then
		return
	end

	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo('Bartender4'))) then
		return
	end

	-- Set/Create our Profile
	Bartender4.db:SetProfile(ProfileName)

	--Load the Profile Data
	for k, v in LibStub('AceAddon-3.0'):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = SUI:MergeData(v.db.profile, BartenderSettings[k], true)
		end
	end

	Bartender4:UpdateModuleConfigs()
	SUI.DBG.BartenderChangesActive = false
end
