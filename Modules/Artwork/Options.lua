local SUI = SUI
local L = SUI.L
local module = SUI:GetModule('Component_Artwork')

function module:SetupOptions()
	if SUI.DBMod.Artwork.Style == '' then
		return
	end

	local Style = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style)
	SUI.opt.args['Artwork'].args['scale'] = {
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
				Style:updateScale()
				SUI:GetModule('Component_BarHandler'):Refresh()
			end
		end,
		get = function(info)
			return SUI.DB.scale
		end
	}

	SUI.opt.args['Artwork'].args['DefaultScales'] = {
		name = L['DefScales'],
		type = 'execute',
		order = 2,
		desc = L['DefScalesDesc'],
		func = function()
			if (SUI.DB.scale >= 0.92) or (SUI.DB.scale < 0.78) then
				SUI.opt.args.Artwork.args.scale.set(nil, 0.78)
			else
				SUI.opt.args.Artwork.args.scale.set(nil, 0.92)
			end
		end
	}

	SUI.opt.args['Artwork'].args['VehicleUI'] = {
		name = 'Use Blizzard Vehicle UI',
		type = 'toggle',
		order = 3,
		get = function(info)
			return SUI.DBMod.Artwork.VehicleUI
		end,
		set = function(info, val)
			if (InCombatLockdown()) then
				SUI:Print(ERR_NOT_IN_COMBAT)
				return
			end
			SUI.DBMod.Artwork.VehicleUI = val
			--Make sure bartender knows to do it, or not...
			if Bartender4 then
				Bartender4.db.profile.blizzardVehicle = val
				Bartender4:UpdateBlizzardVehicle()
			end

			if SUI.DBMod.Artwork.VehicleUI then
				if SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style).SetupVehicleUI() ~= nil then
					SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):SetupVehicleUI()
				end
			else
				if SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style).RemoveVehicleUI() ~= nil then
					SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):RemoveVehicleUI()
				end
			end
		end
	}

	SUI.opt.args['Artwork'].args['alpha'] = {
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
			module:updateAlpha()
		end
	}

	SUI.opt.args['Artwork'].args['Viewport'] = {
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
					return SUI.DBMod.Artwork.Viewport.enabled
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
					SUI.DBMod.Artwork.Viewport.enabled = val

					for _, v in ipairs({'Top', 'Bottom', 'Left', 'Right'}) do
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffset' .. v].disabled =
							(not SUI.DBMod.Artwork.Viewport.enabled)
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
					return SUI.DBMod.Artwork.Viewport.offset.top
				end,
				set = function(info, val)
					SUI.DBMod.Artwork.Viewport.offset.top = val
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
					return SUI.DBMod.Artwork.Viewport.offset.bottom
				end,
				set = function(info, val)
					SUI.DBMod.Artwork.Viewport.offset.bottom = val
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
					return SUI.DBMod.Artwork.Viewport.offset.left
				end,
				set = function(info, val)
					SUI.DBMod.Artwork.Viewport.offset.left = val
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
					return SUI.DBMod.Artwork.Viewport.offset.right
				end,
				set = function(info, val)
					SUI.DBMod.Artwork.Viewport.offset.right = val
					module:updateViewport()
				end
			}
		}
	}

	SUI.opt.args['Artwork'].args['Offset'] = {
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
					offset = {
						name = 'Horizontal offset',
						type = 'range',
						width = 'double',
						order = 3,
						min = -500,
						max = 500,
						step = .1,
						get = function(info)
							return SUI.DB.Offset.Horizontal
						end,
						set = function(info, val)
							SUI.DB.Offset.Horizontal = val
							module:updateHorizontalOffset()
						end
					}
				}
			}
		}
	}
	for i, v in ipairs({'Top', 'Bottom'}) do
		SUI.opt.args['Artwork'].args['Offset'].args[v] = {
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

	for _, v in ipairs({'Top', 'Bottom', 'Left', 'Right'}) do
		SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffset' .. v].disabled =
			(not SUI.DBMod.Artwork.Viewport.enabled)
	end
end
