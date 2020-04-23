local SUI = SUI
local L = SUI.L
local module = SUI:GetModule('Component_Artwork')

function module:SetupOptions()
	if SUI.DB.Artwork.Style == '' then
		return
	end

	local ArtworkOpts = SUI.opt.args.Artwork.args
	ArtworkOpts.scale = {
		name = L['ConfScale'],
		type = 'range',
		order = 1,
		width = 'double',
		desc = L['ConfScaleDesc'],
		min = 0,
		max = 1,
		set = function(info, val)
			if (InCombatLockdown()) then
				SUI:Print(ERR_NOT_IN_COMBAT)
			else
				SUI.DB.scale = val
				module:UpdateScale()
				SUI:GetModule('Component_BarHandler'):Refresh()
			end
		end,
		get = function(info)
			return SUI.DB.scale
		end
	}

	ArtworkOpts.DefaultScales = {
		name = L['DefScales'],
		type = 'execute',
		order = 2,
		desc = L['DefScalesDesc'],
		func = function()
			if (SUI.DB.scale >= 0.92) or (SUI.DB.scale < 0.78) then
				ArtworkOpts.scale.set(nil, 0.78)
			else
				ArtworkOpts.scale.set(nil, 0.92)
			end
		end
	}

	ArtworkOpts.VehicleUI = {
		name = 'Use Blizzard Vehicle UI',
		type = 'toggle',
		order = 3,
		get = function(info)
			return SUI.DB.Artwork.VehicleUI
		end,
		set = function(info, val)
			if (InCombatLockdown()) then
				SUI:Print(ERR_NOT_IN_COMBAT)
				return
			end
			SUI.DB.Artwork.VehicleUI = val
			--Make sure bartender knows to do it, or not...
			if Bartender4 then
				Bartender4.db.profile.blizzardVehicle = val
				Bartender4:UpdateBlizzardVehicle()
			end

			if SUI.DB.Artwork.VehicleUI then
				if SUI:GetModule('Style_' .. SUI.DB.Artwork.Style).SetupVehicleUI() ~= nil then
					SUI:GetModule('Style_' .. SUI.DB.Artwork.Style):SetupVehicleUI()
				end
			else
				if SUI:GetModule('Style_' .. SUI.DB.Artwork.Style).RemoveVehicleUI() ~= nil then
					SUI:GetModule('Style_' .. SUI.DB.Artwork.Style):RemoveVehicleUI()
				end
			end
		end
	}

	ArtworkOpts.alpha = {
		name = L['Transparency'],
		type = 'range',
		order = 4,
		width = 'full',
		min = 0,
		max = 100,
		step = 1,
		get = function(info)
			return (SUI.DB.alpha * 100)
		end,
		set = function(info, val)
			SUI.DB.alpha = (val / 100)
			module:UpdateAlpha()
		end
	}

	ArtworkOpts.Viewport = {
		name = 'Viewport',
		type = 'group',
		inline = true,
		order = 100,
		args = {
			Enabled = {
				name = 'Enabled',
				type = 'toggle',
				order = 1,
				desc = 'Allow SpartanUI To manage the viewport',
				get = function(info)
					return SUI.DB.Artwork.Viewport.enabled
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
						return
					end
					if (not val) then
						--Since we are disabling reset the viewport
						WorldFrame:ClearAllPoints()
						WorldFrame:SetPoint('TOPLEFT', 0, 0)
						WorldFrame:SetPoint('BOTTOMRIGHT', 0, 0)
					end
					SUI.DB.Artwork.Viewport.enabled = val

					for _, v in ipairs({'Top', 'Bottom', 'Left', 'Right'}) do
						ArtworkOpts['Viewport'].args['viewportoffset' .. v].disabled = (not SUI.DB.Artwork.Viewport.enabled)
					end

					module:updateViewport()
				end
			},
			viewportoffsets = {name = 'Offset', order = 2, type = 'description', fontSize = 'large'},
			viewportoffsetTop = {
				name = 'Top',
				type = 'range',
				order = 2.1,
				min = -50,
				max = 200,
				step = .1,
				get = function(info)
					return SUI.DB.Artwork.Viewport.offset.top
				end,
				set = function(info, val)
					SUI.DB.Artwork.Viewport.offset.top = val
					module:updateViewport()
				end
			},
			viewportoffsetBottom = {
				name = 'Bottom',
				type = 'range',
				order = 2.2,
				min = -50,
				max = 200,
				step = .1,
				get = function(info)
					return SUI.DB.Artwork.Viewport.offset.bottom
				end,
				set = function(info, val)
					SUI.DB.Artwork.Viewport.offset.bottom = val
					module:updateViewport()
				end
			},
			viewportoffsetLeft = {
				name = 'Left',
				type = 'range',
				order = 2.3,
				min = -50,
				max = 200,
				step = .1,
				get = function(info)
					return SUI.DB.Artwork.Viewport.offset.left
				end,
				set = function(info, val)
					SUI.DB.Artwork.Viewport.offset.left = val
					module:updateViewport()
				end
			},
			viewportoffsetRight = {
				name = 'Right',
				type = 'range',
				order = 2.4,
				min = -50,
				max = 200,
				step = .1,
				get = function(info)
					return SUI.DB.Artwork.Viewport.offset.right
				end,
				set = function(info, val)
					SUI.DB.Artwork.Viewport.offset.right = val
					module:updateViewport()
				end
			}
		}
	}
	for _, v in ipairs({'Top', 'Bottom', 'Left', 'Right'}) do
		ArtworkOpts.Viewport.args['viewportoffset' .. v].disabled = (not SUI.DB.Artwork.Viewport.enabled)
	end

	ArtworkOpts.Offset = {
		name = 'Offset',
		type = 'group',
		inline = true,
		order = 200,
		args = {
			Horizontal = {
				name = 'Horizontal',
				type = 'group',
				inline = true,
				order = 300,
				args = {
					Top = {
						name = 'Top offset',
						type = 'range',
						width = 'double',
						order = 3,
						min = -500,
						max = 500,
						step = .1,
						get = function(info)
							return SUI.DB.Offset.Horizontal.Top
						end,
						set = function(info, val)
							SUI.DB.Offset.Horizontal.Top = val
							module:updateHorizontalOffset()
						end
					},
					Bottom = {
						name = 'Bottom offset',
						type = 'range',
						width = 'double',
						order = 3,
						min = -500,
						max = 500,
						step = .1,
						get = function(info)
							return SUI.DB.Offset.Horizontal.Bottom
						end,
						set = function(info, val)
							SUI.DB.Offset.Horizontal.Bottom = val
							module:updateHorizontalOffset()
						end
					}
				}
			}
		}
	}
	for i, v in ipairs({'Top', 'Bottom'}) do
		ArtworkOpts.Offset.args[v] = {
			name = v,
			type = 'group',
			inline = true,
			order = (200 + i),
			args = {
				offset = {
					name = v .. ' offset',
					type = 'range',
					width = 'double',
					order = 3,
					min = 0,
					max = 200,
					step = .1,
					get = function(info)
						return SUI.DB.Offset[v]
					end,
					set = function(info, val)
						if (InCombatLockdown()) then
							SUI:Print(ERR_NOT_IN_COMBAT)
						else
							if SUI.DB.Offset[v .. 'Auto'] then
								SUI:Print(L['confOffsetAuto'])
							else
								val = tonumber(val)
								SUI.DB.Offset[v] = val
								module:updateOffset()
							end
						end
					end
				},
				offsetauto = {
					name = L['AutoOffset'],
					type = 'toggle',
					order = 3.1,
					get = function(info)
						return SUI.DB.Offset[v .. 'Auto']
					end,
					set = function(info, val)
						SUI.DB.Offset[v .. 'Auto'] = val
						module:updateOffset()
					end
				}
			}
		}
	end

	SUI.opt.args.Artwork.args.BarBG = {
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
					module:UpdateAlpha()
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
					module:UpdateAlpha()
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
								module:UpdateAlpha()
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
							module:UpdateAlpha()
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
								module:UpdateAlpha()
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
							module:UpdateAlpha()
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
								module:UpdateAlpha()
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
							module:UpdateAlpha()
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
								module:UpdateAlpha()
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
							module:UpdateAlpha()
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
								module:UpdateAlpha()
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
							module:UpdateAlpha()
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
								module:UpdateAlpha()
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
							module:UpdateAlpha()
						end
					}
				}
			}
		}
	}
end
