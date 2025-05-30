local SUI, L = SUI, SUI.L
---@class SUI.Theme.Minimal : SUI.Theme.StyleBase
local module = SUI:NewModule('Style.Minimal')
local Artwork_Core = SUI:GetModule('Artwork') ---@type SUI.Module.Artwork
local unpack = unpack
----------------------------------------------------------------------------------------------------

function module:OnInitialize()
	local BarHandler = SUI.Handlers.BarSystem
	BarHandler.BarPosition.BT4.Minimal = {
		['BT4Bar1'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-1,90',
		['BT4Bar2'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-1,45',
		--
		['BT4Bar3'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,1,1',
		['BT4Bar4'] = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOMRIGHT,1,1',
		--
		['BT4Bar5'] = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOM,-232,1',
		['BT4Bar6'] = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOM,260,1',
		--
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,0,130',
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,0,130',
		--
		['BT4BarStanceBar'] = 'TOP,SpartanUI,TOP,-301,0',
		['BT4BarPetBar'] = 'TOP,SpartanUI,TOP,-558,0',
		['MultiCastActionBarFrame'] = 'TOP,SpartanUI,TOP,-558,0',
		--
		['BT4BarMicroMenu'] = 'TOP,SpartanUI,TOP,322,0',
		['BT4BarBagBar'] = 'TOP,SpartanUI,TOP,595,0',
	}
	BarHandler.BarScale.BT4.Minimal = {
		['BT4Bar1'] = 0.78,
		['BT4Bar2'] = 0.78,
		['BT4Bar3'] = 0.78,
		['BT4Bar4'] = 0.78,
		['BT4Bar5'] = 0.78,
		['BT4Bar6'] = 0.7,
		['BT4Bar7'] = 0.7,
		['BT4Bar8'] = 0.78,
		['BT4Bar9'] = 0.78,
		['BT4Bar10'] = 0.78,
		['BT4BarBagBar'] = 0.6,
		['BT4BarExtraActionBar'] = 0.8,
		['BT4BarStanceBar'] = 0.6,
		['BT4BarPetBar'] = 0.6,
		['MultiCastActionBarFrame'] = 0.6,
		['BT4BarMicroMenu'] = 0.6,
	}

	local minimapSettings = {
		UnderVehicleUI = false,
		scaleWithArt = false,
		position = 'TOPRIGHT,SUI_Art_Minimal_Base3,TOPRIGHT,-10,-10',
		shape = 'square',
	}
	SUI.Minimap:Register('Minimal', minimapSettings)

	SUI.UF.Style:Register('Minimal', {})
end

function module:OnEnable()
	if SUI.DB.Artwork.Style ~= 'Minimal' then
		module:Disable()
	else
		module:Options()

		hooksecurefunc('UIParent_ManageFramePositions', function()
			if TutorialFrameAlertButton then
				TutorialFrameAlertButton:SetParent(Minimap)
				TutorialFrameAlertButton:ClearAllPoints()
				TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
			end
			if CastingBarFrame then
				CastingBarFrame:ClearAllPoints()
				CastingBarFrame:SetPoint('BOTTOM', SUI_Art_Minimal_Base1, 'TOP', 0, 90)
			end
		end)

		--Setup Sliding Trays
		module:SlidingTrays()
		if BT4BarBagBar and BT4BarPetBar.position then
			BT4BarPetBar:position('TOPLEFT', 'SlidingTray_left', 'TOPLEFT', 50, -2)
			BT4BarStanceBar:position('TOPRIGHT', 'SlidingTray_left', 'TOPRIGHT', -50, -2)
			BT4BarMicroMenu:position('TOPLEFT', 'SlidingTray_right', 'TOPLEFT', 50, -2)
			BT4BarBagBar:position('TOPRIGHT', 'SlidingTray_right', 'TOPRIGHT', -100, -2)
		end

		module:SetColor()

		-- Show or hide individual elements based on settings
		if SUI.DB.Styles.Minimal.HideCenterGraphic then
			SUI_Art_Minimal_Base1:Hide()
		else
			SUI_Art_Minimal_Base1:Show()
		end

		if SUI.DB.Styles.Minimal.HideTopLeft then
			SUI_Art_Minimal_Base2:Hide()
		else
			SUI_Art_Minimal_Base2:Show()
		end

		if SUI.DB.Styles.Minimal.HideTopRight then
			SUI_Art_Minimal_Base3:Hide()
		else
			SUI_Art_Minimal_Base3:Show()
		end

		if SUI.DB.Styles.Minimal.HideBottomLeft then
			SUI_Art_Minimal_Base4:Hide()
		else
			SUI_Art_Minimal_Base4:Show()
		end

		if SUI.DB.Styles.Minimal.HideBottomRight then
			SUI_Art_Minimal_Base5:Hide()
		else
			SUI_Art_Minimal_Base5:Show()
		end

		SUI_Art_Minimal:Show()
	end
end

function module:TooltipLoc(tooltip, parent)
	if parent == 'UIParent' then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', SUI_Art_Minimal, 'BOTTOMRIGHT', -20, 20)
	end
end

function module:Options()
	SUI.opt.args['Artwork'].args['Art'] = {
		name = L['Artwork Options'],
		type = 'group',
		order = 10,
		args = {
			HideCenterGraphic = {
				name = L['Hide center graphic'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.Styles.Minimal.HideCenterGraphic
				end,
				set = function(info, val)
					SUI.DB.Styles.Minimal.HideCenterGraphic = val
					if SUI.DB.Styles.Minimal.HideCenterGraphic then
						SUI_Art_Minimal_Base1:Hide()
					else
						SUI_Art_Minimal_Base1:Show()
					end
				end,
			},
			HideTopLeft = {
				name = L['Hide Top Left'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return SUI.DB.Styles.Minimal.HideTopLeft
				end,
				set = function(info, val)
					SUI.DB.Styles.Minimal.HideTopLeft = val
					if SUI.DB.Styles.Minimal.HideTopLeft then
						SUI_Art_Minimal_Base2:Hide()
					else
						SUI_Art_Minimal_Base2:Show()
					end
				end,
			},
			HideTopRight = {
				name = L['Hide Top Right'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DB.Styles.Minimal.HideTopRight
				end,
				set = function(info, val)
					SUI.DB.Styles.Minimal.HideTopRight = val
					if SUI.DB.Styles.Minimal.HideTopRight then
						SUI_Art_Minimal_Base3:Hide()
					else
						SUI_Art_Minimal_Base3:Show()
					end
				end,
			},
			HideBottomLeft = {
				name = L['Hide Bottom Left'],
				type = 'toggle',
				order = 4,
				get = function(info)
					return SUI.DB.Styles.Minimal.HideBottomLeft
				end,
				set = function(info, val)
					SUI.DB.Styles.Minimal.HideBottomLeft = val
					if SUI.DB.Styles.Minimal.HideBottomLeft then
						SUI_Art_Minimal_Base4:Hide()
					else
						SUI_Art_Minimal_Base4:Show()
					end
				end,
			},
			HideBottomRight = {
				name = L['Hide Bottom Right'],
				type = 'toggle',
				order = 5,
				get = function(info)
					return SUI.DB.Styles.Minimal.HideBottomRight
				end,
				set = function(info, val)
					SUI.DB.Styles.Minimal.HideBottomRight = val
					if SUI.DB.Styles.Minimal.HideBottomRight then
						SUI_Art_Minimal_Base5:Hide()
					else
						SUI_Art_Minimal_Base5:Show()
					end
				end,
			},
			alpha = {
				name = L['Artwork Color'],
				type = 'color',
				hasAlpha = true,
				order = 6,
				width = 'full',
				desc = L['XP and Rep Bars are known issues and need a redesign to look right'],
				get = function(info)
					return unpack(SUI.DB.Styles.Minimal.Color.Art)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Minimal.Color.Art = { r, b, g, a }
					module:SetColor()
				end,
			},
		},
	}
end

function module:OnDisable()
	SUI_Art_Minimal:Hide()
end

function module:SlidingTrays()
	local Settings = {
		bg = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Minimal\\Images\\base-center-top',
			TexCoord = { 0.076171875, 0.92578125, 0, 0.18359375 },
		},
		bgCollapsed = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Minimal\\Images\\base-center-top',
			TexCoord = { 0.076171875, 0.92578125, 1, 0.92578125 },
		},
		UpTex = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Minimal\\Images\\base-center-top',
			TexCoord = { 0.3675, 0.64, 0.235, 0.265 },
		},
		DownTex = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Minimal\\Images\\base-center-top',
			TexCoord = { 0.3675, 0.64, 0.265, 0.235 },
		},
	}

	Artwork_Core:SlidingTrays(Settings)
end

function module:SetColor()
	local r, b, g, a = unpack(SUI.DB.Styles.Minimal.Color.Art)

	for i = 1, 5 do
		if _G['SUI_Art_Minimal_Base' .. i] then _G['SUI_Art_Minimal_Base' .. i]:SetVertexColor(r, b, g, a) end
	end

	for _, v in pairs(Artwork_Core.Trays) do
		v.expanded.bg:SetVertexColor(r, b, g, a)
		v.collapsed.bg:SetVertexColor(r, b, g, a)
	end
end
