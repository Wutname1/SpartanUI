local SUI, L = SUI, SUI.L
local module = SUI:GetModule('Module_Artwork') ---@type SUI.Module.Artwork

function module:SetupOptions()
	if SUI.DB.Artwork.Style == '' then return end

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
				SUI:GetModule('Handler_BarSystems'):Refresh()
			end
		end,
		get = function(info)
			return SUI.DB.scale
		end,
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
		end,
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
				if SUI:GetModule('Style_' .. SUI.DB.Artwork.Style).SetupVehicleUI() ~= nil then SUI:GetModule('Style_' .. SUI.DB.Artwork.Style):SetupVehicleUI() end
			else
				if SUI:GetModule('Style_' .. SUI.DB.Artwork.Style).RemoveVehicleUI() ~= nil then SUI:GetModule('Style_' .. SUI.DB.Artwork.Style):RemoveVehicleUI() end
			end
		end,
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
		end,
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

					for _, v in ipairs({ 'Top', 'Bottom', 'Left', 'Right' }) do
						ArtworkOpts['Viewport'].args['viewportoffset' .. v].disabled = not SUI.DB.Artwork.Viewport.enabled
					end

					module:updateViewport()
				end,
			},
			viewportoffsets = { name = L['Offset'], order = 2, type = 'description', fontSize = 'large' },
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
				end,
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
				end,
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
				end,
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
				end,
			},
		},
	}
	for _, v in ipairs({ 'Top', 'Bottom', 'Left', 'Right' }) do
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
							return SUI.DB.Offset.Horizontal.Top
						end,
						set = function(info, val)
							SUI.DB.Offset.Horizontal.Top = val
							module:updateHorizontalOffset()
						end,
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
							return SUI.DB.Offset.Horizontal.Bottom
						end,
						set = function(info, val)
							SUI.DB.Offset.Horizontal.Bottom = val
							module:updateHorizontalOffset()
						end,
					},
				},
			},
		},
	}
	for i, v in ipairs({ 'Top', 'Bottom' }) do
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
						return SUI.DB.Offset[v]
					end,
					set = function(info, val)
						if InCombatLockdown() then
							SUI:Print(ERR_NOT_IN_COMBAT)
						else
							if SUI.DB.Offset[v .. 'Auto'] then
								SUI:Print(L['Offset is set AUTO'])
							else
								val = tonumber(val)
								SUI.DB.Offset[v] = val
								module:updateOffset()
							end
						end
					end,
				},
				offsetauto = {
					name = L['Auto Offset'],
					type = 'toggle',
					order = 3.1,
					get = function(info)
						return SUI.DB.Offset[v .. 'Auto']
					end,
					set = function(info, val)
						SUI.DB.Offset[v .. 'Auto'] = val
						module:updateOffset()
					end,
				},
			},
		}
	end

	ArtworkOpts.BarBG = {
		name = L['Bar backgrounds'],
		type = 'group',
		args = {},
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
					if module.BarBG[SUI.DB.Artwork.Style][key] then return false end
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
					end,
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
					end,
				},
			},
		}
	end

	for i, v in pairs({ '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Stance', 'MenuBar' }) do
		CreatOption(v)
	end
end
