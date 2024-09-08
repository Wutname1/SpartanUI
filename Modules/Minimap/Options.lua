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
	return #module.DB.customSettings[SUI.DB.Artwork.Style].elements[element] ~= 0 and module.DB.customSettings[SUI.DB.Artwork.Style].elements[element][option]
		or module.Settings.elements[element][option]
end

local function SetOption(info, value)
	local element = info[#info - 1]
	local option = info[#info]
	module.Settings.elements[element][option] = value
	module.DB.customSettings[SUI.DB.Artwork.Style].elements[element][option] = value
	module:Update(true)
end

local function GetRelativeToValues()
	local values = {
		Minimap = L['Minimap'],
		MinimapCluster = L['Minimap Cluster'],
		UIParent = L['Screen'],
		BorderTop = L['Border Top'],
	}

	-- Add other Minimap elements
	for elementName, elementSettings in pairs(module.Settings.elements) do
		if elementSettings.enabled then values[elementName] = L[elementName] or elementName end
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
		if not values[case] then values[case] = L[case] or case end
	end

	return values
end

local function GetPositionOption(info)
	local element = info[#info - 2]
	local positionPart = info[#info]
	local positionString = module.Settings.elements[element].position

	if
		module.DB.customSettings[SUI.DB.Artwork.Style].elements[element]
		and module.DB.customSettings[SUI.DB.Artwork.Style].elements[element].position
		and type(module.DB.customSettings[SUI.DB.Artwork.Style].elements[element].position) == 'string'
	then
		positionString = module.DB.customSettings[SUI.DB.Artwork.Style].elements[element].position
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
	local positionString = module.Settings.elements[element].position
	if module.DB.customSettings[SUI.DB.Artwork.Style].elements[element] and type(module.DB.customSettings[SUI.DB.Artwork.Style].elements[element].position) == 'string' then
		positionString = module.DB.customSettings[SUI.DB.Artwork.Style].elements[element].position
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
	if not module.DB.customSettings[SUI.DB.Artwork.Style].elements[element] then module.DB.customSettings[SUI.DB.Artwork.Style].elements[element] = {} end
	module.Settings.elements[element].position = newPositionString
	module.DB.customSettings[SUI.DB.Artwork.Style].elements[element].position = newPositionString
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
						if module.DB.customSettings[SUI.DB.Artwork.Style] then module.DB.customSettings[SUI.DB.Artwork.Style].elements[elementName] = nil end
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

	SUI.Options:AddOptions(options, 'Minimap')
end
