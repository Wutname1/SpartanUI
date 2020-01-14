local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_War')
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	if (SUI.DBMod.Artwork.Style == 'War') then
		module:Init()
	end

	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.War = {
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_ActionBarAnchor,TOP,0,70',
		--
		['BT4BarStanceBar'] = 'TOP,SpartanUI,TOP,-309,0',
		['BT4BarPetBar'] = 'TOP,SpartanUI,TOP,-558,0',
		--
		['BT4BarMicroMenu'] = 'TOP,SpartanUI,TOP,369,0',
		['BT4BarBagBar'] = 'TOP,SpartanUI,TOP,680,0'
	}

	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.war = {
		name = 'War',
		top = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\UnitFrames',
			TexCoord = {0.541015625, 1, 0, 0.2109375},
			-- VertexColor = {0, 0, 0, .6},
			-- position = {Pos table},
			-- scale = 1,
			-- alpha = 1,
			height = 45,
			y = -15,
			PVPAlpha = .4
		},
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\UnitFrames',
			TexCoord = {0.572265625, 0.96875, 0.74609375, 1},
			-- VertexColor = {0, 0, 0, .6},
			-- position = {anchor = 'BOTTOM'},
			-- scale = 1,
			-- height = 0,
			-- alpha = 1,
			PVPAlpha = .4
		},
		bottom = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\UnitFrames',
			TexCoord = {0.541015625, 1, 0.2109375, 0.421875},
			-- VertexColor = {0, 0, 0, .6},
			-- position = {Pos table},
			-- scale = 1,
			height = 50,
			y = 40,
			-- alpha = 1,
			PVPAlpha = .4
		}
	}
	if UnitFactionGroup('player') == 'Alliance' then
		UnitFrames.Artwork.war.top.TexCoord = {0.03125, 0.458984375, 0, 0.2109375}
		UnitFrames.Artwork.war.bg.TexCoord = {0, 0.458984375, 0.74609375, 1}
		UnitFrames.Artwork.war.bottom.TexCoord = {0.03125, 0.458984375, 0.2109375, 0.421875}
	end
end

function module:Init()
	module:SetupMenus()
	module:InitArtwork()
	InitRan = true
end

function module:OnEnable()
	if (SUI.DBMod.Artwork.Style ~= 'War') then
		module:Disable()
	else
		if (Bartender4.db:GetCurrentProfile() ~= SUI.DB.Styles.War.BartenderProfile) and SUI.DBMod.Artwork.FirstLoad then
			Bartender4.db:SetProfile(SUI.DB.Styles.War.BartenderProfile)
		end
		if (not InitRan) then
			module:Init()
		end
		module:EnableArtwork()

		if (SUI.DBMod.Artwork.FirstLoad) then
			SUI.DBMod.Artwork.FirstLoad = false
		end -- We want to do this last
	end
end

function module:OnDisable()
	War_SpartanUI:Hide()
end

function module:SetupMenus()
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
					return SUI.DB.Styles.War.Artwork.Allenable
				end,
				set = function(info, val)
					for i = 1, 4 do
						SUI.DB.Styles.War.Artwork['bar' .. i].enable, SUI.DB.Styles.War.Artwork.Allenable = val, val
					end
					SUI.DB.Styles.War.Artwork.Stance.enable = val
					SUI.DB.Styles.War.Artwork.MenuBar.enable = val
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
					return SUI.DB.Styles.War.Artwork.Allalpha
				end,
				set = function(info, val)
					for i = 1, 4 do
						SUI.DB.Styles.War.Artwork['bar' .. i].alpha, SUI.DB.Styles.War.Artwork.Allalpha = val, val
					end
					SUI.DB.Styles.War.Artwork.Stance.alpha = val
					SUI.DB.Styles.War.Artwork.MenuBar.alpha = val
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
							return SUI.DB.Styles.War.Artwork.Stance.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.War.Artwork.Stance.enable == true then
								SUI.DB.Styles.War.Artwork.Stance.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar5enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.War.Artwork.Stance.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.War.Artwork.Stance.enable = val
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
							return SUI.DB.Styles.War.Artwork.MenuBar.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.War.Artwork.MenuBar.enable == true then
								SUI.DB.Styles.War.Artwork.MenuBar.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar6enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.War.Artwork.MenuBar.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.War.Artwork.MenuBar.enable = val
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
							return SUI.DB.Styles.War.Artwork.bar1.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.War.Artwork.bar1.enable == true then
								SUI.DB.Styles.War.Artwork.bar1.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar1enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.War.Artwork.bar1.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.War.Artwork.bar1.enable = val
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
							return SUI.DB.Styles.War.Artwork.bar2.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.War.Artwork.bar2.enable == true then
								SUI.DB.Styles.War.Artwork.bar2.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar2enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.War.Artwork.bar2.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.War.Artwork.bar2.enable = val
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
							return SUI.DB.Styles.War.Artwork.bar3.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.War.Artwork.bar3.enable == true then
								SUI.DB.Styles.War.Artwork.bar3.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar3enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.War.Artwork.bar3.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.War.Artwork.bar3.enable = val
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
							return SUI.DB.Styles.War.Artwork.bar4.alpha
						end,
						set = function(info, val)
							if SUI.DB.Styles.War.Artwork.bar4.enable == true then
								SUI.DB.Styles.War.Artwork.bar4.alpha = val
								module:updateAlpha()
							end
						end
					},
					bar4enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.Styles.War.Artwork.bar4.enable
						end,
						set = function(info, val)
							SUI.DB.Styles.War.Artwork.bar4.enable = val
							module:updateAlpha()
						end
					}
				}
			}
		}
	}
end
