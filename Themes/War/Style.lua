local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_War')
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	--Enable the in the Core options screen
	SUI.opt.args['General'].args['style'].args['OverallStyle'].args['War'].disabled = false
	SUI.opt.args['General'].args['style'].args['Artwork'].args['War'].disabled = false
	--Init if needed
	if (SUI.DBMod.Artwork.Style == 'War') then
		module:Init()
	end
end

function module:Init()
	if (SUI.DBMod.Artwork.FirstLoad) then
		module:FirstLoad()
	end
	module:SetupMenus()
	module:InitArtwork()
	InitRan = true
end

function module:FirstLoad()
	--If our profile exists activate it.
	if
		((Bartender4.db:GetCurrentProfile() ~= SUI.DB.Styles.War.BartenderProfile) and
			Artwork_Core:BartenderProfileCheck(SUI.DB.Styles.War.BartenderProfile, true))
	 then
		Bartender4.db:SetProfile(SUI.DB.Styles.War.BartenderProfile)
	end
end

function module:OnEnable()
	if (SUI.DBMod.Artwork.Style ~= 'War') then
		module:Disable()
	else
		SUI.opt.args['Artwork'].args['Artwork'].name = 'War Options'

		if (Bartender4.db:GetCurrentProfile() ~= SUI.DB.Styles.War.BartenderProfile) and SUI.DBMod.Artwork.FirstLoad then
			Bartender4.db:SetProfile(SUI.DB.Styles.War.BartenderProfile)
		end
		if (not InitRan) then
			module:Init()
		end
		if (not Artwork_Core:BartenderProfileCheck(SUI.DB.Styles.War.BartenderProfile, true)) then
			module:CreateProfile()
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
	SUI.opt.args['Artwork'].args['Artwork'] = {
		name = 'War Options',
		type = 'group',
		order = 10,
		args = {
			MinimapEngulfed = {
				name = L['Douse the flames'],
				type = 'toggle',
				order = .1,
				desc = L['Is it getting hot in here?'],
				get = function(info)
					return (SUI.DB.Styles.War.Minimap.Engulfed ~= true or false)
				end,
				set = function(info, val)
					SUI.DB.Styles.War.Minimap.Engulfed = (val ~= true or false)
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
			},
			-- xOffset = {name = L["MoveSideways"],type = "range",width="full",order=2,
			-- desc = L["MoveSidewaysDesc"],
			-- min=-200,max=200,step=.1,
			-- get = function(info) return SUI.DB.xOffset/6.25 end,
			-- set = function(info,val) SUI.DB.xOffset = val*6.25; module:updateSpartanXOffset(); end,
			-- },
			offset = {
				name = L['ConfOffset'],
				type = 'range',
				width = 'normal',
				order = 3,
				desc = L['ConfOffsetDesc'],
				min = 0,
				max = 200,
				step = .1,
				get = function(info)
					return SUI.DB.yoffset
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
					else
						if SUI.DB.yoffsetAuto then
							SUI:Print(L['confOffsetAuto'])
						else
							val = tonumber(val)
							SUI.DB.yoffset = val
							module:updateOffset()
						end
					end
				end
			},
			offsetauto = {
				name = L['AutoOffset'],
				type = 'toggle',
				desc = L['AutoOffsetDesc'],
				order = 3.1,
				get = function(info)
					return SUI.DB.yoffsetAuto
				end,
				set = function(info, val)
					SUI.DB.yoffsetAuto = val
					module:updateOffset()
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
