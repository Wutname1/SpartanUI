local SUI, L = SUI, SUI.L
local print, error = SUI.print, SUI.Error
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Fel')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local artFrame = CreateFrame('Frame', 'SUI_Art_Fel', SpartanUI)
module.Settings = {}
local CurScale
local petbattle = CreateFrame('Frame')
local StatusBarSettings = {
	bars = {
		'Fel_StatusBar_Left',
		'Fel_StatusBar_Right'
	},
	Fel_StatusBar_Left = {
		bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\status-plate-exp',
		size = {370, 20},
		TooltipSize = {400, 100},
		TooltipTextSize = {380, 90},
		texCords = {0.150390625, 1, 0, 1},
		GlowPoint = {x = -10},
		MaxWidth = 32,
		bgTooltip = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Fel-Box',
		texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
	},
	Fel_StatusBar_Right = {
		bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\status-plate-exp',
		Grow = 'RIGHT',
		size = {370, 20},
		TooltipSize = {400, 100},
		TooltipTextSize = {380, 90},
		texCords = {0.150390625, 1, 0, 1},
		GlowPoint = {x = 10},
		MaxWidth = 35,
		bgTooltip = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Fel-Box',
		texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
	}
}

----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	--Enable the in the Core options screen
	SUI.opt.args['General'].args['style'].args['OverallStyle'].args['Fel'].disabled = false
	SUI.opt.args['General'].args['style'].args['Artwork'].args['Fel'].disabled = false

	SUI.opt.args['General'].args['style'].args['OverallStyle'].args['Digital'].disabled = false
	--Init if needed
	if (SUI.DB.Artwork.Style == 'Fel') then
		module:Options()
		module:InitArtwork()
	end

	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Fel = {
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_ActionBarAnchor,TOP,0,80',
		--
		['BT4BarStanceBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-250,175',
		['BT4BarPetBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-590,175',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,320,175',
		['BT4BarBagBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,640,180'
	}

	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.Fel = {
		top = {
			-- path = 'Interface\\Scenarios\\LegionInvasion',
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\UnitFrames',
			TexCoord = {0.1796875, 0.736328125, 0, 0.099609375},
			heightScale = .25,
			yScale = -0.05,
			alpha = .8
		},
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\UnitFrames',
			TexCoord = {.02, .385, .45, .575},
			PVPAlpha = .4
		},
		bottom = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\UnitFrames',
			heightScale = .115,
			yScale = 0.0158,
			TexCoord = {0.1796875, 0.736328125, 0.197265625, 0.244140625},
			PVPAlpha = .8
		}
	}
	UnitFrames.Artwork.Digital = {
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Digital\\Fel-Box',
			TexCoord = {0.0234375, 0.9765625, 0.265625, 0.7734375},
			PVPAlpha = .4
		}
	}

	module:CreateArtwork()
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Fel') then
		module:Disable()
	else
		module:EnableArtwork()

		if SUI.DB.Styles.Fel.SubTheme == 'Digital' then
			artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Digital\\Base_Bar_Left')
			artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Digital\\Base_Bar_Right')
			local barBG = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Digital\\Fel-Box'
			for i = 1, 4 do
				_G['Fel_Bar' .. i .. 'BG']:SetTexture(barBG)
			end

			Fel_MenuBarBG:SetTexture(barBG)
			Fel_StanceBarBG:SetTexture(barBG)
		end
	end
end

function module:OnDisable()
	artFrame:Hide()
end

function module:Options()
	SUI.opt.args['Artwork'].args['Artwork'] = {
		name = 'Fel Options',
		type = 'group',
		order = 10,
		args = {
			MinimapEngulfed = {
				name = L['Douse the flames'],
				type = 'toggle',
				order = .1,
				desc = L['Is it getting hot in here?'],
				get = function(info)
					return (SUI.DB.Styles.Fel.Minimap.Engulfed ~= true or false)
				end,
				set = function(info, val)
					SUI.DB.Styles.Fel.Minimap.Engulfed = (val ~= true or false)
					module:MiniMapUpdate()
				end
			},
			alpha = {
				name = L['Transparency'],
				type = 'range',
				order = 1,
				width = 'full',
				min = 0,
				max = 100,
				step = 1,
				desc = L['TransparencyDesc'],
				get = function(info)
					return (SUI.DB.alpha * 100)
				end,
				set = function(info, val)
					SUI.DB.alpha = (val / 100)
					module:updateAlpha()
				end
			}
		}
	}

	SUI.opt.args['Artwork'].args['ActionBar'] = {
		name = 'Bar backgrounds',
		type = 'group',
		desc = L['ActionBarConfDesc'],
		args = {
			header1 = {name = '', type = 'header', order = 1.1},
			Allenable = {
				name = L['AllBarEnable'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.Styles.Fel.Artwork.Allenable
				end,
				set = function(info, val)
					for i = 1, 4 do
						SUI.DB.Styles.Fel.Artwork['bar' .. i].enable, SUI.DB.Styles.Fel.Artwork.Allenable = val, val
					end
					SUI.DB.Styles.Fel.Artwork.Stance.enable = val
					SUI.DB.Styles.Fel.Artwork.MenuBar.enable = val
					module:updateAlpha()
				end
			},
			Allalpha = {
				name = L['AllBarAlpha'],
				type = 'range',
				order = 2,
				width = 'double',
				min = 0,
				max = 100,
				step = 1,
				get = function(info)
					return SUI.DB.Styles.Fel.Artwork.Allalpha
				end,
				set = function(info, val)
					for i = 1, 4 do
						SUI.DB.Styles.Fel.Artwork['bar' .. i].alpha, SUI.DB.Styles.Fel.Artwork.Allalpha = val, val
					end
					SUI.DB.Styles.Fel.Artwork.Stance.alpha = val
					SUI.DB.Styles.Fel.Artwork.MenuBar.alpha = val
					module:updateAlpha()
				end
			},
			Stance = {
				name = L['Stance and Pet bar'],
				type = 'group',
				inline = true,
				order = 10,
				args = {
					bar5alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.Stance.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.Fel.Artwork.Stance.enable == true then
								SUI.DB.Styles.Fel.Artwork.Stance.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar5enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.Stance.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.Fel.Artwork.Stance.enable = val
							module:updateAlpha()
						end
					}
				}
			},
			MenuBar = {
				name = L['Bag and Menu bar'],
				type = 'group',
				inline = true,
				order = 20,
				args = {
					bar6alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.MenuBar.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.Fel.Artwork.MenuBar.enable == true then
								SUI.DB.Styles.Fel.Artwork.MenuBar.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar6enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.MenuBar.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.Fel.Artwork.MenuBar.enable = val
							module:updateAlpha()
						end
					}
				}
			},
			Bar1 = {
				name = L['Bar 1'],
				type = 'group',
				inline = true,
				order = 30,
				args = {
					bar1alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.bar1.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.Fel.Artwork.bar1.enable == true then
								SUI.DB.Styles.Fel.Artwork.bar1.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar1enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.bar1.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.Fel.Artwork.bar1.enable = val
							module:updateAlpha()
						end
					}
				}
			},
			Bar2 = {
				name = L['Bar 2'],
				type = 'group',
				inline = true,
				order = 40,
				args = {
					bar2alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.bar2.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.Fel.Artwork.bar2.enable == true then
								SUI.DB.Styles.Fel.Artwork.bar2.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar2enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.bar2.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.Fel.Artwork.bar2.enable = val
							module:updateAlpha()
						end
					}
				}
			},
			Bar3 = {
				name = L['Bar 3'],
				type = 'group',
				inline = true,
				order = 50,
				args = {
					bar3alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.bar3.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.Fel.Artwork.bar3.enable == true then
								SUI.DB.Styles.Fel.Artwork.bar3.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar3enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.bar3.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.Fel.Artwork.bar3.enable = val
							module:updateAlpha()
						end
					}
				}
			},
			Bar4 = {
				name = L['Bar 4'],
				type = 'group',
				inline = true,
				order = 60,
				args = {
					bar4alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.bar4.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.Fel.Artwork.bar4.enable == true then
								SUI.DB.Styles.Fel.Artwork.bar4.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar4enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.Fel.Artwork.bar4.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.Fel.Artwork.bar4.enable = val
							module:updateAlpha()
						end
					}
				}
			}
		}
	}
end

--	Module Calls
function module:TooltipLoc(_, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'SUI_Art_Fel', 'TOPRIGHT', 0, 10)
	end
end

function module:BuffLoc(_, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		petbattle:HookScript(
			'OnHide',
			function()
				if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
					Minimap:Hide()
				end
				artFrame:Hide()
			end
		)
		petbattle:HookScript(
			'OnShow',
			function()
				if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
					Minimap:Show()
				end
				artFrame:Show()
			end
		)
		RegisterStateDriver(petbattle, 'visibility', '[petbattle] hide; show')
		RegisterStateDriver(SUI_Art_Fel, 'visibility', '[overridebar][vehicleui] hide; show')
		RegisterStateDriver(SpartanUI, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(petbattle, 'visibility')
		UnregisterStateDriver(SUI_Art_Fel, 'visibility')
		UnregisterStateDriver(SpartanUI, 'visibility')
	end
end

function module:CreateArtwork()
	plate = CreateFrame('Frame', 'Fel_ActionBarPlate', SpartanUI, 'Fel_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:ClearAllPoints()
	plate:SetAllPoints(SUI_ActionBarAnchor)

	--Setup the Bottom Artwork
	artFrame:SetFrameStrata('BACKGROUND')
	artFrame:SetFrameLevel(1)
	artFrame:SetPoint('BOTTOMLEFT')
	artFrame:SetPoint('TOPRIGHT', SpartanUI, 'BOTTOMRIGHT', 0, 153)

	artFrame.Left = artFrame:CreateTexture('SUI_Art_War_Left', 'BORDER')
	artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame, 'BOTTOM', 0, 0)
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Base_Bar_Left')
	-- artFrame.Left:SetScale(.75)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_War_Right', 'BORDER')
	artFrame.Right:SetPoint('BOTTOMLEFT', artFrame, 'BOTTOM')
	artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Base_Bar_Right')
	-- artFrame.Right:SetScale(.75)

	FramerateText:ClearAllPoints()
	FramerateText:SetPoint('TOPLEFT', SpartanUI, 'TOPLEFT', 10, -10)
end

function module:EnableArtwork()
	hooksecurefunc(
		'UIParent_ManageFramePositions',
		function()
			if TutorialFrameAlertButton then
				TutorialFrameAlertButton:SetParent(Minimap)
				TutorialFrameAlertButton:ClearAllPoints()
				TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
			end
			CastingBarFrame:ClearAllPoints()
			CastingBarFrame:SetPoint('BOTTOM', SUI_Art_Fel, 'TOP', 0, 90)
		end
	)

	module:SetupVehicleUI()

	if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
		module:MiniMap()
	end

	module:StatusBars()
end

function module:StatusBars()
	local StatusBars = SUI:GetModule('Artwork_StatusBars')
	StatusBars:Initalize(StatusBarSettings)

	-- Position the StatusBars
	StatusBars.bars.Fel_StatusBar_Left:SetPoint('BOTTOMRIGHT', SUI_Art_Fel, 'BOTTOM', -100, 0)
	StatusBars.bars.Fel_StatusBar_Right:SetPoint('BOTTOMLEFT', SUI_Art_Fel, 'BOTTOM', 100, 0)
end

-- Minimap
function module:MiniMapUpdate()
	if Minimap.BG then
		Minimap.BG:ClearAllPoints()
	end

	if SUI.DB.Styles.Fel.SubTheme == 'Digital' then
		Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Digital\\Minimap')
		Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', 5, -1)
		Minimap.BG:SetSize(256, 256)
		Minimap.BG:SetBlendMode('ADD')
	else
		if SUI.DB.Styles.Fel.Minimap.Engulfed then
			Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Minimap-Engulfed')
			Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', 7, 37)
			Minimap.BG:SetSize(330, 330)
			Minimap.BG:SetBlendMode('ADD')
		else
			Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Minimap-Calmed')
			Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', 5, -1)
			Minimap.BG:SetSize(256, 256)
			Minimap.BG:SetBlendMode('ADD')
		end
	end
end

function module:MiniMap()
	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints()
		Minimap.ZoneText:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -5)
		Minimap.ZoneText:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -5)
		Minimap.ZoneText:Hide()
		MinimapZoneText:Show()
	end

	Minimap.BG = Minimap:CreateTexture(nil, 'BACKGROUND')
	SUI:GetModule('Component_Minimap'):ShapeChange('circle')

	module:MiniMapUpdate()

	artFrame:HookScript(
		'OnHide',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
			SUI:GetModule('Component_Minimap'):ShapeChange('square')
		end
	)

	artFrame:HookScript(
		'OnShow',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('CENTER', SUI_Art_Fel, 'CENTER', 0, 54)
			SUI:GetModule('Component_Minimap'):ShapeChange('circle')
		end
	)
end
