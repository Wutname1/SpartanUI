local SUI, L = SUI, SUI.L
local module = SUI:GetModule('Artwork') ---@type SUI.Module.Artwork

function module:SetupOptions()
	if SUI.DB.Artwork.Style == '' then
		return
	end

	local ArtworkOpts = SUI.opt.args.Artwork.args
	ArtworkOpts.scale = {
		name = L['Configure Scale'],
		type = 'range',
		order = 1,
		width = 'double',
		desc = L['Sets a specific scale for SpartanUI'],
		min = 0,
		max = 1,
		set = function(info, val)
			if InCombatLockdown() then
				SUI:Print(ERR_NOT_IN_COMBAT)
			else
				SUI.DB.scale = val
				module:UpdateScale()
				SUI.Handlers.BarSystem:Refresh()
			end
		end,
		get = function(info)
			return SUI.DB.scale
		end
	}

	ArtworkOpts.DefaultScales = {
		name = L['Toggle Default Scales'],
		type = 'execute',
		order = 2,
		desc = L['Toggles between widescreen and standard scales'],
		func = function()
			if (SUI.DB.scale >= 0.92) or (SUI.DB.scale < 0.78) then
				ArtworkOpts.scale.set(nil, 0.78)
			else
				ArtworkOpts.scale.set(nil, 0.92)
			end
		end
	}

	ArtworkOpts.VehicleUI = {
		name = L['Use Blizzard Vehicle UI'],
		type = 'toggle',
		order = 3,
		get = function(info)
			return SUI.DB.Artwork.VehicleUI
		end,
		set = function(info, val)
			if InCombatLockdown() then
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
				if SUI:GetModule('Style.' .. SUI.DB.Artwork.Style).SetupVehicleUI() ~= nil then
					SUI:GetModule('Style.' .. SUI.DB.Artwork.Style):SetupVehicleUI()
				end
			else
				if SUI:GetModule('Style.' .. SUI.DB.Artwork.Style).RemoveVehicleUI() ~= nil then
					SUI:GetModule('Style.' .. SUI.DB.Artwork.Style):RemoveVehicleUI()
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
		name = L['Viewport'],
		type = 'group',
		inline = true,
		order = 100,
		args = {
			Enabled = {
				name = L['Enabled'],
				type = 'toggle',
				order = 1,
				desc = L['Allow SpartanUI To manage the viewport'],
				get = function(info)
					return SUI.DB.Artwork.Viewport.enabled
				end,
				set = function(info, val)
					if InCombatLockdown() then
						SUI:Print(ERR_NOT_IN_COMBAT)
						return
					end
					if not val then
						--Since we are disabling reset the viewport
						WorldFrame:ClearAllPoints()
						WorldFrame:SetPoint('TOPLEFT', 0, 0)
						WorldFrame:SetPoint('BOTTOMRIGHT', 0, 0)
					end
					SUI.DB.Artwork.Viewport.enabled = val

					for _, v in ipairs({'Top', 'Bottom', 'Left', 'Right'}) do
						ArtworkOpts['Viewport'].args['viewportoffset' .. v].disabled = not SUI.DB.Artwork.Viewport.enabled
					end

					module:updateViewport()
				end
			},
			viewportoffsets = {name = L['Offset'], order = 2, type = 'description', fontSize = 'large'},
			viewportoffsetTop = {
				name = L['Top'],
				type = 'range',
				order = 2.1,
				min = -50,
				max = 200,
				step = 0.1,
				get = function(info)
					return SUI.DB.Artwork.Viewport.offset.top
				end,
				set = function(info, val)
					SUI.DB.Artwork.Viewport.offset.top = val
					module:updateViewport()
				end
			},
			viewportoffsetBottom = {
				name = L['Bottom'],
				type = 'range',
				order = 2.2,
				min = -50,
				max = 200,
				step = 0.1,
				get = function(info)
					return SUI.DB.Artwork.Viewport.offset.bottom
				end,
				set = function(info, val)
					SUI.DB.Artwork.Viewport.offset.bottom = val
					module:updateViewport()
				end
			},
			viewportoffsetLeft = {
				name = L['Left'],
				type = 'range',
				order = 2.3,
				min = -50,
				max = 200,
				step = 0.1,
				get = function(info)
					return SUI.DB.Artwork.Viewport.offset.left
				end,
				set = function(info, val)
					SUI.DB.Artwork.Viewport.offset.left = val
					module:updateViewport()
				end
			},
			viewportoffsetRight = {
				name = L['Right'],
				type = 'range',
				order = 2.4,
				min = -50,
				max = 200,
				step = 0.1,
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
		ArtworkOpts.Viewport.args['viewportoffset' .. v].disabled = not SUI.DB.Artwork.Viewport.enabled
	end

	ArtworkOpts.Offset = {
		name = L['Offset'],
		type = 'group',
		inline = true,
		order = 200,
		args = {
			Horizontal = {
				name = L['Horizontal'],
				type = 'group',
				inline = true,
				order = 300,
				args = {
					Top = {
						name = L['Top offset'],
						type = 'range',
						width = 'double',
						order = 3,
						min = -500,
						max = 500,
						step = 0.1,
						get = function(info)
							return SUI.DB.Artwork.Offset.Horizontal.Top
						end,
						set = function(info, val)
							SUI.DB.Artwork.Offset.Horizontal.Top = val
							module:updateHorizontalOffset()
						end
					},
					Bottom = {
						name = L['Bottom offset'],
						type = 'range',
						width = 'double',
						order = 3,
						min = -500,
						max = 500,
						step = 0.1,
						get = function(info)
							return SUI.DB.Artwork.Offset.Horizontal.Bottom
						end,
						set = function(info, val)
							SUI.DB.Artwork.Offset.Horizontal.Bottom = val
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
					step = 0.1,
					get = function(info)
						return SUI.DB.Artwork.Offset[v]
					end,
					set = function(info, val)
						if InCombatLockdown() then
							SUI:Print(ERR_NOT_IN_COMBAT)
						else
							if SUI.DB.Artwork.Offset[v .. 'Auto'] then
								SUI:Print(L['Offset is set AUTO'])
							else
								val = tonumber(val)
								SUI.DB.Artwork.Offset[v] = val
								module:updateOffset()
							end
						end
					end
				},
				offsetauto = {
					name = L['Auto Offset'],
					type = 'toggle',
					order = 3.1,
					get = function(info)
						return SUI.DB.Artwork.Offset[v .. 'Auto']
					end,
					set = function(info, val)
						SUI.DB.Artwork.Offset[v .. 'Auto'] = val
						module:updateOffset()
					end
				}
			}
		}
	end

	ArtworkOpts.BarBG = {
		name = L['Bar backgrounds'],
		type = 'group',
		args = {}
	}
	local function CreatOption(key)
		local function updateOpt(opt, val)
			module.ActiveStyle.Artwork.barBG[key][opt] = val
			module:UpdateBarBG()
		end

		ArtworkOpts.BarBG.args[key] = {
			name = L['Bar'] .. ' ' .. key,
			type = 'group',
			inline = true,
			hidden = function(info)
				if module.BarBG[SUI.DB.Artwork.Style] then
					if module.BarBG[SUI.DB.Artwork.Style][key] then
						return false
					end
				end
				return true
			end,
			args = {
				enabled = {
					order = 1,
					name = L['Enabled'],
					type = 'toggle',
					get = function(info)
						return module.ActiveStyle.Artwork.barBG[key].enabled
					end,
					set = function(info, val)
						updateOpt('enabled', val)
					end
				},
				alpha = {
					order = 2,
					name = L['Alpha'],
					type = 'range',
					min = 0,
					max = 1,
					step = 0.01,
					width = 'double',
					get = function(info)
						return module.ActiveStyle.Artwork.barBG[key].alpha
					end,
					set = function(info, val)
						updateOpt('alpha', val)
					end
				},
				bgType = {
					order = 3,
					name = L['Background Type'],
					type = 'select',
					values = {
						['texture'] = L['Theme Texture'],
						['color'] = L['Solid Color'],
						['custom'] = L['Custom Texture']
					},
					get = function(info)
						return module.ActiveStyle.Artwork.barBG[key].bgType or 'texture'
					end,
					set = function(info, val)
						updateOpt('bgType', val)
					end
				},
				backgroundColor = {
					order = 4,
					name = L['Background Color'],
					type = 'color',
					hasAlpha = true,
					hidden = function(info)
						return module.ActiveStyle.Artwork.barBG[key].bgType ~= 'color' or module.ActiveStyle.Artwork.barBG[key].classColorBG
					end,
					get = function(info)
						local color = module.ActiveStyle.Artwork.barBG[key].backgroundColor or {0, 0, 0, 1}
						return color[1], color[2], color[3], color[4]
					end,
					set = function(info, r, g, b, a)
						updateOpt('backgroundColor', {r, g, b, a})
					end
				},
				customTexture = {
					order = 5,
					name = L['Custom Texture'],
					type = 'select',
					dialogControl = 'LSM30_Statusbar',
					values = AceGUIWidgetLSMlists.statusbar,
					hidden = function(info)
						return module.ActiveStyle.Artwork.barBG[key].bgType ~= 'custom'
					end,
					get = function(info)
						return module.ActiveStyle.Artwork.barBG[key].customTexture or 'Blizzard'
					end,
					set = function(info, val)
						updateOpt('customTexture', val)
					end
				},
				useSkinColors = {
					order = 6,
					name = L['Use Skin Colors'],
					type = 'toggle',
					desc = L['Let the current skin control texture colors. Uncheck to use custom colors.'],
					get = function(info)
						return module.ActiveStyle.Artwork.barBG[key].useSkinColors ~= false
					end,
					set = function(info, val)
						updateOpt('useSkinColors', val)
					end
				},
				textureColor = {
					order = 7,
					name = L['Texture Color/Tint'],
					type = 'color',
					hasAlpha = true,
					hidden = function(info)
						return module.ActiveStyle.Artwork.barBG[key].bgType == 'color' or module.ActiveStyle.Artwork.barBG[key].useSkinColors ~= false or module.ActiveStyle.Artwork.barBG[key].classColorBG
					end,
					get = function(info)
						local color = module.ActiveStyle.Artwork.barBG[key].textureColor or {1, 1, 1, 1}
						return color[1], color[2], color[3], color[4]
					end,
					set = function(info, r, g, b, a)
						updateOpt('textureColor', {r, g, b, a})
					end
				},
				resetToSkin = {
					order = 8,
					name = L['Reset to Skin Defaults'],
					type = 'execute',
					desc = L['Reset all customizations and use skin default settings'],
					func = function()
						-- Reset to skin defaults
						updateOpt('useSkinColors', true)
						updateOpt('textureColor', {1, 1, 1, 1})
						updateOpt('bgType', 'texture')
						updateOpt('backgroundColor', nil)
						updateOpt('customTexture', nil)
						-- Reset border options
						updateOpt('borderEnabled', false)
						updateOpt('borderColors', nil)
						updateOpt('borderSize', 1)
						updateOpt('borderSides', {top = true, bottom = true, left = true, right = true})
						-- Reset class color options
						updateOpt('classColorBG', false)
						updateOpt('classColorBorders', {})
					end
				},
				borderEnabled = {
					order = 9,
					name = L['Enable Border'],
					type = 'toggle',
					get = function(info)
						return module.ActiveStyle.Artwork.barBG[key].borderEnabled or false
					end,
					set = function(info, val)
						updateOpt('borderEnabled', val)
					end
				},
				borderColors = {
					order = 10,
					name = L['Border Colors'],
					type = 'group',
					inline = true,
					hidden = function(info)
						return not module.ActiveStyle.Artwork.barBG[key].borderEnabled
					end,
					args = {
						top = {
							order = 1,
							name = L['Top'],
							type = 'color',
							hasAlpha = true,
							width = 0.5,
							hidden = function(info)
								local classColors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
								return classColors.top
							end,
							get = function(info)
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								local color = colors.top or {1, 1, 1, 1}
								return color[1], color[2], color[3], color[4]
							end,
							set = function(info, r, g, b, a)
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								colors.top = {r, g, b, a}
								updateOpt('borderColors', colors)
							end
						},
						bottom = {
							order = 2,
							name = L['Bottom'],
							type = 'color',
							hasAlpha = true,
							width = 0.5,
							hidden = function(info)
								local classColors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
								return classColors.bottom
							end,
							get = function(info)
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								local color = colors.bottom or {1, 1, 1, 1}
								return color[1], color[2], color[3], color[4]
							end,
							set = function(info, r, g, b, a)
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								colors.bottom = {r, g, b, a}
								updateOpt('borderColors', colors)
							end
						},
						left = {
							order = 3,
							name = L['Left'],
							type = 'color',
							hasAlpha = true,
							width = 0.5,
							hidden = function(info)
								local classColors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
								return classColors.left
							end,
							get = function(info)
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								local color = colors.left or {1, 1, 1, 1}
								return color[1], color[2], color[3], color[4]
							end,
							set = function(info, r, g, b, a)
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								colors.left = {r, g, b, a}
								updateOpt('borderColors', colors)
							end
						},
						right = {
							order = 4,
							name = L['Right'],
							type = 'color',
							hasAlpha = true,
							width = 0.5,
							hidden = function(info)
								local classColors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
								return classColors.right
							end,
							get = function(info)
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								local color = colors.right or {1, 1, 1, 1}
								return color[1], color[2], color[3], color[4]
							end,
							set = function(info, r, g, b, a)
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								colors.right = {r, g, b, a}
								updateOpt('borderColors', colors)
							end
						},
						copyToAll = {
							order = 5,
							name = L['Copy Top Color to All Sides'],
							type = 'execute',
							func = function()
								local colors = module.ActiveStyle.Artwork.barBG[key].borderColors or {}
								local topColor = colors.top or {1, 1, 1, 1}
								colors.bottom = {topColor[1], topColor[2], topColor[3], topColor[4]}
								colors.left = {topColor[1], topColor[2], topColor[3], topColor[4]}
								colors.right = {topColor[1], topColor[2], topColor[3], topColor[4]}
								updateOpt('borderColors', colors)
							end
						}
					}
				},
				borderSize = {
					order = 11,
					name = L['Border Size'],
					type = 'range',
					min = 1,
					max = 10,
					step = 1,
					hidden = function(info)
						return not module.ActiveStyle.Artwork.barBG[key].borderEnabled
					end,
					get = function(info)
						return module.ActiveStyle.Artwork.barBG[key].borderSize or 1
					end,
					set = function(info, val)
						updateOpt('borderSize', val)
					end
				},
				classColorOptions = {
					order = 12,
					name = L['Class Color Options'],
					type = 'group',
					inline = true,
					args = {
						classColorBG = {
							order = 1,
							name = L['Use Class Color for Background'],
							type = 'toggle',
							get = function(info)
								return module.ActiveStyle.Artwork.barBG[key].classColorBG or false
							end,
							set = function(info, val)
								updateOpt('classColorBG', val)
							end
						},
						classColorBorders = {
							order = 2,
							name = L['Use Class Color for Borders'],
							type = 'group',
							inline = true,
							hidden = function(info)
								return not module.ActiveStyle.Artwork.barBG[key].borderEnabled
							end,
							args = {
								classColorBorderTop = {
									order = 1,
									name = L['Top'],
									type = 'toggle',
									width = 0.5,
									get = function(info)
										local colors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
										return colors.top or false
									end,
									set = function(info, val)
										local colors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
										colors.top = val
										updateOpt('classColorBorders', colors)
									end
								},
								classColorBorderBottom = {
									order = 2,
									name = L['Bottom'],
									type = 'toggle',
									width = 0.5,
									get = function(info)
										local colors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
										return colors.bottom or false
									end,
									set = function(info, val)
										local colors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
										colors.bottom = val
										updateOpt('classColorBorders', colors)
									end
								},
								classColorBorderLeft = {
									order = 3,
									name = L['Left'],
									type = 'toggle',
									width = 0.5,
									get = function(info)
										local colors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
										return colors.left or false
									end,
									set = function(info, val)
										local colors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
										colors.left = val
										updateOpt('classColorBorders', colors)
									end
								},
								classColorBorderRight = {
									order = 4,
									name = L['Right'],
									type = 'toggle',
									width = 0.5,
									get = function(info)
										local colors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
										return colors.right or false
									end,
									set = function(info, val)
										local colors = module.ActiveStyle.Artwork.barBG[key].classColorBorders or {}
										colors.right = val
										updateOpt('classColorBorders', colors)
									end
								}
							}
						}
					}
				},
				borderSides = {
					order = 13,
					name = L['Border Sides'],
					type = 'multiselect',
					hidden = function(info)
						return not module.ActiveStyle.Artwork.barBG[key].borderEnabled
					end,
					values = {
						top = L['Top'],
						bottom = L['Bottom'],
						left = L['Left'],
						right = L['Right']
					},
					get = function(info, side)
						local sides = module.ActiveStyle.Artwork.barBG[key].borderSides or {top = true, bottom = true, left = true, right = true}
						return sides[side]
					end,
					set = function(info, side, val)
						local sides = module.ActiveStyle.Artwork.barBG[key].borderSides or {top = true, bottom = true, left = true, right = true}
						sides[side] = val
						updateOpt('borderSides', sides)
					end
				}
			}
		}
	end

	for i, v in pairs({'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Stance', 'MenuBar'}) do
		CreatOption(v)
	end
end
