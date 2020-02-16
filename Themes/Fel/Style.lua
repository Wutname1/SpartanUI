local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_Fel')
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	--Enable the in the Core options screen
	SUI.opt.args['General'].args['style'].args['OverallStyle'].args['Fel'].disabled = false
	SUI.opt.args['General'].args['style'].args['Artwork'].args['Fel'].disabled = false

	SUI.opt.args['General'].args['style'].args['OverallStyle'].args['Digital'].disabled = false
	--Init if needed
	if (SUI.DB.Artwork.Style == 'Fel') then
		module:Init()
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
end

function module:Init()
	module:SetupMenus()
	module:InitArtwork()
	InitRan = true
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Fel') then
		module:Disable()
	else
		if (not InitRan) then
			module:Init()
		end
		module:EnableArtwork()
	end
end

function module:OnDisable()
	SUI_Art_Fel:Hide()
end

function module:SetupMenus()
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
