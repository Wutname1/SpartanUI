local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Artwork_Core')

function Artwork_Core:SetupOptions()
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
				SUI.DB.scale = min(1, SUI:round(val))
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
			if (InCombatLockdown()) then
				SUI:Print(ERR_NOT_IN_COMBAT)
			else
				if (SUI.DB.scale >= 0.92) or (SUI.DB.scale < 0.78) then
					SUI.DB.scale = 0.78
				else
					SUI.DB.scale = 0.92
				end
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

	SUI.opt.args['Artwork'].args['Viewport'] = {
		name = 'Viewport',
		type = 'group',
		inline = true,
		args = {
			Enabled = {
				name = 'Enabled',
				type = 'toggle',
				order = 1,
				desc = 'Allow SpartanUI To manage the viewport',
				get = function(info)
					return SUI.DB.viewport
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
					SUI.DB.viewport = val
					if (not SUI.DB.viewport) then
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetTop'].disabled = true
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetBottom'].disabled = true
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetLeft'].disabled = true
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetRight'].disabled = true
					else
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetTop'].disabled = false
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetBottom'].disabled = false
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetLeft'].disabled = false
						SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetRight'].disabled = false
					end
				end
			},
			viewportoffsets = {name = 'Offset', order = 2, type = 'description', fontSize = 'large'},
			viewportoffsetTop = {
				name = 'Top',
				type = 'range',
				order = 2.1,
				min = -100,
				max = 100,
				step = .1,
				get = function(info)
					return SUI.DBMod.Artwork.Viewport.offset.top
				end,
				set = function(info, val)
					SUI.DBMod.Artwork.Viewport.offset.top = val
				end
			},
			viewportoffsetBottom = {
				name = 'Bottom',
				type = 'range',
				order = 2.2,
				min = -100,
				max = 100,
				step = .1,
				get = function(info)
					return SUI.DBMod.Artwork.Viewport.offset.bottom
				end,
				set = function(info, val)
					SUI.DBMod.Artwork.Viewport.offset.bottom = val
				end
			},
			viewportoffsetLeft = {
				name = 'Left',
				type = 'range',
				order = 2.3,
				min = -100,
				max = 100,
				step = .1,
				get = function(info)
					return SUI.DBMod.Artwork.Viewport.offset.left
				end,
				set = function(info, val)
					SUI.DBMod.Artwork.Viewport.offset.left = val
				end
			},
			viewportoffsetRight = {
				name = 'Right',
				type = 'range',
				order = 2.4,
				min = -100,
				max = 100,
				step = .1,
				get = function(info)
					return SUI.DBMod.Artwork.Viewport.offset.right
				end,
				set = function(info, val)
					SUI.DBMod.Artwork.Viewport.offset.right = val
				end
			}
		}
	}

	if (not SUI.DB.viewport) then
		SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetTop'].disabled = true
		SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetBottom'].disabled = true
		SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetLeft'].disabled = true
		SUI.opt.args['Artwork'].args['Viewport'].args['viewportoffsetRight'].disabled = true
	end
end
