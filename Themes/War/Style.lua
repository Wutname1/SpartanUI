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
	local Images = {
		Alliance = {
			bg = {
				Coords = {0, 0.458984375, 0.74609375, 1}
			},
			top = {
				Coords = {0.03125, 0.427734375, 0, 0.421875}
			},
			bottom = {
				Coords = {0.541015625, 1, 0, 0.421875}
			}
		},
		Horde = {
			bg = {
				Coords = {0.572265625, 0.96875, 0.74609375, 1}
			},
			top = {
				Coords = {0.541015625, 1, 0, 0.421875}
			},
			bottom = {
				Coords = {0.541015625, 1, 0, 0.421875}
			}
		}
	}
	local pathFunc = function(frame, position)
		local factionGroup = UnitFactionGroup(frame.unit) or 'Neutral'
		if factionGroup == 'Horde' or factionGroup == 'Alliance' then
			return 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\UnitFrames'
		end
		if position == 'bg' then
			return 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'
		end

		return false
	end
	local TexCoordFunc = function(frame, position)
		local factionGroup = UnitFactionGroup(frame.unit) or 'Neutral'

		if factionGroup == 'Horde' then
			-- Horde Graphics
			if position == 'top' then
				return {0.541015625, 1, 0, 0.1796875}
			elseif position == 'bg' then
				return {0.572265625, 0.96875, 0.74609375, 1}
			elseif position == 'bottom' then
				return {0.541015625, 1, 0.37109375, 0.421875}
			end
		elseif factionGroup == 'Alliance' then
			-- Alliance Graphics
			if position == 'top' then
				return {0.03125, 0.458984375, 0, 0.1796875}
			elseif position == 'bg' then
				return {0, 0.458984375, 0.74609375, 1}
			elseif position == 'bottom' then
				return {0.03125, 0.458984375, 0.37109375, 0.421875}
			end
		else
			return {1, 1, 1, 1}
		end
	end

	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.war = {
		name = 'War',
		top = {
			path = pathFunc,
			TexCoord = TexCoordFunc,
			heightScale = .225,
			yScale = -.0555,
			PVPAlpha = .6
		},
		bg = {
			path = pathFunc,
			TexCoord = TexCoordFunc,
			PVPAlpha = .7
		},
		bottom = {
			path = pathFunc,
			TexCoord = TexCoordFunc,
			heightScale = .0825,
			yScale = 0.0223,
			PVPAlpha = .7
			-- height = 40,
			-- y = 40,
			-- alpha = 1,
			-- VertexColor = {0, 0, 0, .6},
			-- position = {Pos table},
			-- scale = 1,
		}
	}
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
		if (not InitRan) then
			module:Init()
		end
		module:EnableArtwork()
	end
end

function module:OnDisable()
	UnregisterStateDriver(SUI_Art_War, 'visibility')
	SUI_Art_War:Hide()
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
