local SUI = SUI
local L = SUI.L
---@class SUI.Module.Minimap
local module = SUI.Minimap

local elementNaming = {
	['coords'] = 'Coordinates',
	['zoneText'] = 'Zone Text',
	['zoomButtons'] = 'Zoom Buttons',
	['mailIcon'] = 'Mail Icon',
	['instanceDifficulty'] = 'Instance Difficulty',
	['tracking'] = 'Tracking',
	['calendarButton'] = 'Calendar',
	['expansionButton'] = 'Expansion Button',
	['clock'] = 'Clock',
	['queueStatus'] = 'Queue Status',
	['addonButtons'] = 'Addon Buttons',
	['background'] = 'Background',
}

local function GetOption(info)
	local element = info[#info - 1]
	local option = info[#info]

	-- Handle both Retail (nested) and Classic (flat) structures
	local elementSettings = module.Settings.elements and module.Settings.elements[element] or module.Settings[element]
	if not elementSettings then
		return nil
	end

	local customSettings = module.DB.customSettings[SUI.DB.Artwork.Style]
	if customSettings then
		local customElement = customSettings.elements and customSettings.elements[element] or customSettings[element]
		if customElement and customElement[option] ~= nil then
			return customElement[option]
		end
	end

	return elementSettings[option]
end

local function SetOption(info, value)
	local element = info[#info - 1]
	local option = info[#info]

	-- Handle both Retail (nested) and Classic (flat) structures
	if module.Settings.elements then
		-- Retail structure
		module.Settings.elements[element][option] = value
		if not module.DB.customSettings[SUI.DB.Artwork.Style].elements then
			module.DB.customSettings[SUI.DB.Artwork.Style].elements = {}
		end
		if not module.DB.customSettings[SUI.DB.Artwork.Style].elements[element] then
			module.DB.customSettings[SUI.DB.Artwork.Style].elements[element] = {}
		end
		module.DB.customSettings[SUI.DB.Artwork.Style].elements[element][option] = value
	else
		-- Classic flat structure
		if module.Settings[element] then
			module.Settings[element][option] = value
		end
		if not module.DB.customSettings[SUI.DB.Artwork.Style][element] then
			module.DB.customSettings[SUI.DB.Artwork.Style][element] = {}
		end
		module.DB.customSettings[SUI.DB.Artwork.Style][element][option] = value
	end

	module:Update(true)
end

local function GetRelativeToValues()
	local values = {
		Minimap = L['Minimap'],
		MinimapCluster = L['Minimap Cluster'],
		UIParent = L['Screen'],
		BorderTop = L['Border Top'],
	}

	-- Add other Minimap elements (only if elements table exists)
	if module.Settings.elements then
		for elementName, elementSettings in pairs(module.Settings.elements) do
			if elementSettings.enabled then
				values[elementName] = L[elementName] or elementName
			end
		end
	end

	-- Add special cases
	local specialCases = {
		'Tracking',
		'Calendar',
		'Coordinates',
		'Clock',
		'ZoneText',
		'MailIcon',
		'InstanceDifficulty',
		'QueueStatus',
	}

	for _, case in ipairs(specialCases) do
		if not values[case] then
			values[case] = L[case] or case
		end
	end

	return values
end

local function GetPositionOption(info)
	local element = info[#info - 2]
	local positionPart = info[#info]

	-- Handle both Retail (nested) and Classic (flat) structures
	local elementSettings = module.Settings.elements and module.Settings.elements[element] or module.Settings[element]
	if not elementSettings then
		return nil
	end

	local positionString = elementSettings.position

	local customSettings = module.DB.customSettings[SUI.DB.Artwork.Style]
	if customSettings then
		local customElement = customSettings.elements and customSettings.elements[element] or customSettings[element]
		if customElement and customElement.position and type(customElement.position) == 'string' then
			positionString = customElement.position
		end
	end

	if not positionString then
		return nil
	end

	local point, relativeTo, relativePoint, x, y = strsplit(',', positionString)
	if positionPart == 'point' then
		return point
	elseif positionPart == 'relativeTo' then
		return relativeTo
	elseif positionPart == 'relativePoint' then
		return relativePoint
	elseif positionPart == 'x' then
		return tonumber(x)
	elseif positionPart == 'y' then
		return tonumber(y)
	end
end

local function SetPositionOption(info, value)
	local element = info[#info - 2]
	local positionPart = info[#info]

	-- Handle both Retail (nested) and Classic (flat) structures
	local elementSettings = module.Settings.elements and module.Settings.elements[element] or module.Settings[element]
	if not elementSettings then
		return
	end

	local positionString = elementSettings.position

	local customSettings = module.DB.customSettings[SUI.DB.Artwork.Style]
	if customSettings then
		local customElement = customSettings.elements and customSettings.elements[element] or customSettings[element]
		if customElement and type(customElement.position) == 'string' then
			positionString = customElement.position
		end
	end

	if not positionString then
		return
	end

	local point, relativeTo, relativePoint, x, y = strsplit(',', positionString)
	if positionPart == 'point' then
		point = value
	elseif positionPart == 'relativeTo' then
		relativeTo = value
	elseif positionPart == 'relativePoint' then
		relativePoint = value
	elseif positionPart == 'x' then
		x = value
	elseif positionPart == 'y' then
		y = value
	end

	local newPositionString = string.format('%s,%s,%s,%s,%s', point, relativeTo, relativePoint, x, y)

	if module.Settings.elements then
		-- Retail structure
		if not module.DB.customSettings[SUI.DB.Artwork.Style].elements then
			module.DB.customSettings[SUI.DB.Artwork.Style].elements = {}
		end
		if not module.DB.customSettings[SUI.DB.Artwork.Style].elements[element] then
			module.DB.customSettings[SUI.DB.Artwork.Style].elements[element] = {}
		end
		module.Settings.elements[element].position = newPositionString
		module.DB.customSettings[SUI.DB.Artwork.Style].elements[element].position = newPositionString
	else
		-- Classic flat structure
		if not module.DB.customSettings[SUI.DB.Artwork.Style][element] then
			module.DB.customSettings[SUI.DB.Artwork.Style][element] = {}
		end
		module.Settings[element].position = newPositionString
		module.DB.customSettings[SUI.DB.Artwork.Style][element].position = newPositionString
	end

	module:Update(true)
end

local anchorValues = {
	TOP = L['Top'],
	TOPLEFT = L['Top Left'],
	TOPRIGHT = L['Top Right'],
	BOTTOM = L['Bottom'],
	BOTTOMLEFT = L['Bottom Left'],
	BOTTOMRIGHT = L['Bottom Right'],
	LEFT = L['Left'],
	RIGHT = L['Right'],
	CENTER = L['Center'],
}

-- Options
function module:BuildOptions()
	local anchorPoints = {
		['TOPLEFT'] = 'TOP LEFT',
		['TOP'] = 'TOP',
		['TOPRIGHT'] = 'TOP RIGHT',
		['RIGHT'] = 'RIGHT',
		['CENTER'] = 'CENTER',
		['LEFT'] = 'LEFT',
		['BOTTOMLEFT'] = 'BOTTOM LEFT',
		['BOTTOM'] = 'BOTTOM',
		['BOTTOMRIGHT'] = 'BOTTOM RIGHT',
	}

	---@type AceConfig.OptionsTable
	local options = {
		type = 'group',
		name = L['Minimap'],
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		childGroups = 'tab',
		args = {
			general = {
				name = L['General'],
				type = 'group',
				order = 1,
				args = {
					shape = {
						name = L['Shape'],
						type = 'select',
						order = 1,
						values = {
							circle = L['Circle'],
							square = L['Square'],
						},
						get = function()
							return module.Settings.shape
						end,
						set = function(_, value)
							module.DB.customSettings[SUI.DB.Artwork.Style].shape = value
							module:Update(true)
						end,
					},
					size = {
						name = L['Size'],
						type = 'range',
						order = 2,
						min = 120,
						max = 300,
						step = 1,
						get = function()
							return module.Settings.size[1]
						end,
						set = function(_, value)
							module.DB.customSettings[SUI.DB.Artwork.Style].size = { value, value }
							module:Update(true)
						end,
					},
					scaleWithArt = {
						name = L['Scale with UI'],
						type = 'toggle',
						order = 3,
						get = function()
							return module.Settings.scaleWithArt
						end,
						set = function(_, value)
							module.DB.customSettings[SUI.DB.Artwork.Style].scaleWithArt = value
							module:Update(true)
						end,
					},
					rotate = {
						name = L['Rotate the minimap'],
						type = 'toggle',
						order = 3,
						get = function()
							return module.Settings.rotate
						end,
						set = function(_, value)
							module.DB.customSettings[SUI.DB.Artwork.Style].rotate = value
							module:Update(true)
						end,
					},
					resetElement = {
						name = L['Reset Element'],
						type = 'execute',
						order = 50,
						hidden = function()
							return not SUI.Options:hasChanges(module.DB.customSettings[SUI.DB.Artwork.Style], module.BaseOpt)
						end,
						func = function()
							-- Reset the element's settings to default
							module.DB.customSettings[SUI.DB.Artwork.Style] = nil

							-- Trigger a full update of the UnitFrames
							module:Update(true)
						end,
					},
					vehiclePosition = {
						name = L['Vehicle UI Position'],
						type = 'group',
						order = 25,
						inline = true,
						hidden = function()
							-- Only show vehicle options if the skin defines the minimap as being under Vehicle UI
							if not module.Settings then
								return true
							end -- Hide if settings not loaded
							return not module.Settings.UnderVehicleUI
						end,
						args = {
							skinInfo = {
								name = L['Skin Position Info'],
								desc = L['This skin positions the minimap under the Blizzard Vehicle UI. You can configure how the minimap behaves when in a vehicle.'],
								type = 'description',
								width = 'full',
								order = 0,
							},
							enable = {
								name = L['Configure Vehicle Position'],
								desc = L['Open the mover to set the minimap position when in a vehicle'],
								type = 'execute',
								order = 1,
								func = function()
									module:VehicleUIMoverShow()
								end,
							},
							reset = {
								name = L['Reset Position'],
								desc = L['Reset the vehicle minimap position to default'],
								type = 'execute',
								order = 2,
								func = function()
									module:ResetVehiclePosition()
								end,
							},
							useVehicleMover = {
								name = L['Use Vehicle Position'],
								desc = L['When enabled, the minimap will move to a different position when in a vehicle. When disabled, the minimap stays in its normal position.'],
								type = 'toggle',
								order = 3,
								get = function()
									if not module.Settings then
										return true
									end -- Default to true if settings not loaded
									return module.Settings.useVehicleMover ~= false -- Default to true if nil or true
								end,
								set = function(_, val)
									local currentStyle = SUI.DB.Artwork.Style
									if not module.DB.customSettings[currentStyle] then
										module.DB.customSettings[currentStyle] = {}
									end
									module.DB.customSettings[currentStyle].useVehicleMover = val

									-- Update runtime settings after saving to DB
									if module.Settings then
										module.Settings.useVehicleMover = val
									end

									-- Update will handle the vehicle monitoring setup/cleanup automatically
									module:Update(true)
								end,
							},
						},
					},
				},
			},
			elements = {
				name = L['Elements'],
				type = 'group',
				order = 2,
				childGroups = 'tree',
				args = {},
			},
		},
	}

	-- Build options for each element
	-- Only build element options if the elements table exists (Retail structure)
	if module.Settings.elements then
		for elementName, elementSettings in pairs(module.Settings.elements) do
			options.args.elements.args[elementName] = {
				name = L[elementNaming[elementName] or elementName],
				type = 'group',
				get = GetOption,
				set = SetOption,
				args = {
					resetElement = {
						name = L['Reset Element'],
						type = 'execute',
						order = 0,
						hidden = function()
							return not SUI.Options:hasChanges(module.DB.customSettings[SUI.DB.Artwork.Style].elements[elementName], module.BaseOpt.elements[elementName])
						end,
						func = function()
							if module.DB.customSettings[SUI.DB.Artwork.Style] then
								module.DB.customSettings[SUI.DB.Artwork.Style].elements[elementName] = nil
							end
							module:Update(true)
						end,
					},
					enabled = {
						name = L['Enabled'],
						type = 'toggle',
						order = 1,
						get = function()
							return module.Settings.elements[elementName].enabled
						end,
						set = SetOption,
					},
				},
			}
			if elementSettings.position then
				options.args.elements.args[elementName].args.position = {
					name = L['Position'],
					type = 'group',
					order = 2,
					inline = true,
					args = {
						point = {
							name = L['Anchor'],
							type = 'select',
							order = 1,
							values = anchorValues,
							get = GetPositionOption,
							set = SetPositionOption,
						},
						relativeTo = {
							name = L['Relative To'],
							type = 'select',
							order = 2,
							values = GetRelativeToValues,
							get = GetPositionOption,
							set = SetPositionOption,
						},
						relativePoint = {
							name = L['Relative Anchor'],
							type = 'select',
							order = 3,
							values = anchorValues,
							get = GetPositionOption,
							set = SetPositionOption,
						},
						x = {
							name = L['X Offset'],
							type = 'range',
							order = 4,
							min = -100,
							max = 100,
							step = 1,
							get = GetPositionOption,
							set = SetPositionOption,
						},
						y = {
							name = L['Y Offset'],
							type = 'range',
							order = 5,
							min = -100,
							max = 100,
							step = 1,
							get = GetPositionOption,
							set = SetPositionOption,
						},
					},
				}
			end

			if elementSettings.scale then
				options.args.elements.args[elementName].args.scale = {
					name = L['Scale'],
					type = 'range',
					order = 3,
					min = 0.1,
					max = 2,
					step = 0.05,
					get = function()
						return elementSettings.scale
					end,
					set = SetOption,
				}
			end

			if elementSettings.color then
				options.args.elements.args[elementName].args.color = {
					name = L['Color'],
					type = 'color',
					order = 3,
					get = function()
						return unpack(elementSettings.color)
					end,
					set = function(info, r, g, b, a)
						module.DB.customSettings[SUI.DB.Artwork.Style].elements[elementName].color[info[#info]] = { r, g, b, a }
					end,
				}
			end

			-- local order = 4
			-- for settingName, settingValue in pairs(elementSettings) do
			-- 	if not options.args.elements.args[elementName].args[settingName] then
			-- 		local optionType = type(settingValue)
			-- 		options.args.elements.args[elementName].args[settingName] = {
			-- 			name = L[settingName] or settingName,
			-- 			type = optionType == 'boolean' and 'toggle' or optionType == 'number' and 'range' or 'input',
			-- 			order = order,
			-- 			get = GetOption,
			-- 			set = SetOption,
			-- 		}

			-- 		if optionType == 'number' then
			-- 			options.args.elements.args[elementName].args[settingName].min = 0
			-- 			options.args.elements.args[elementName].args[settingName].max = 2
			-- 			options.args.elements.args[elementName].args[settingName].step = 0.01
			-- 		end

			-- 		order = order + 1
			-- 	end
			-- end

			if elementSettings.style then
				options.args.elements.args[elementName].args.enabled.hidden = true

				options.args.elements.args[elementName].args.style = {
					name = L['Style'],
					type = 'select',
					order = 4,
					values = {
						['always'] = L['Always'],
						['mouseover'] = L['Mouseover'],
						['never'] = L['Never'],
					},
				}
			end
		end
	end -- end of if module.Settings.elements then

	SUI.Options:AddOptions(options, 'Minimap')
end
