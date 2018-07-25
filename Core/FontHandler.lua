local SUI, L = SUI, SUI.L
local module = SUI:NewModule('Handler_Font', 'AceTimer-3.0')

local FontItems = {}
local FontFaces = {
	['SpartanUI'] = 'Cognosis',
	['Roboto'] = 'Roboto',
	['Roboto-Bold'] = 'Roboto Bold',
	['SUI4'] = 'NotoSans',
	['SUI4cn'] = 'NotoSans (zhCN)',
	['FrizQuadrata'] = 'Friz Quadrata',
	['ArialNarrow'] = 'Arial Narrow',
	['Skurri'] = 'Skurri',
	['Morpheus'] = 'Morpheus'
}

function module:StoreFontItem(element, DefaultSize, Module)
	--Create tracking table if needed
	if not FontItems[Module] then
		FontItems[Module] = {Count = 0}
	end

	--Load next ID number
	local NewItemID = FontItems[Module].Count + 1

	--Store element and latest ID used
	FontItems[Module].Count = NewItemID
	FontItems[Module][NewItemID .. 'DefaultSize'] = DefaultSize
	FontItems[Module][NewItemID] = element
end

function SUI:comma_value(n)
	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)', '%1' .. SUI.DB.font.NumberSeperator):reverse()) .. right
end

function SUI:FontSetup()
	for i = 5, 22 do
		local filename = _G['SUI_FontOutline' .. i]:GetFont()
		if filename ~= SUI:GetFontFace('Primary') then
			_G['SUI_FontOutline' .. i] = _G['SUI_FontOutline' .. i]:SetFont(SUI:GetFontFace('Primary'), i)
		end
		filename = _G['SUI_Font' .. i]:GetFont()
		if filename ~= SUI:GetFontFace('Primary') then
			_G['SUI_Font' .. i] = _G['SUI_Font' .. i]:SetFont(SUI:GetFontFace('Primary'), i)
		end
	end
end

function SUI:GetFontFace(Module)
	if Module then
		if SUI.DB.font.Modules[Module].Face == 'SpartanUI' then
			return 'Interface\\AddOns\\SpartanUI\\media\\font-cognosis.ttf'
		elseif SUI.DB.font.Modules[Module].Face == 'SUI4' then
			return 'Interface\\AddOns\\SpartanUI\\media\\NotoSans-Bold.ttf'
		elseif SUI.DB.font.Modules[Module].Face == 'Roboto' then
			return 'Interface\\AddOns\\SpartanUI\\media\\Roboto-Medium.ttf'
		elseif SUI.DB.font.Modules[Module].Face == 'Roboto-Bold' then
			return 'Interface\\AddOns\\SpartanUI\\media\\Roboto-Bold.ttf'
		elseif SUI.DB.font.Modules[Module].Face == 'FrizQuadrata' then
			return 'Fonts\\FRIZQT__.TTF'
		elseif SUI.DB.font.Modules[Module].Face == 'Arial' then
			return 'Fonts\\ARIAL.TTF'
		elseif SUI.DB.font.Modules[Module].Face == 'ArialNarrow' then
			return 'Fonts\\ARIALN.TTF'
		elseif SUI.DB.font.Modules[Module].Face == 'Skurri' then
			return 'Fonts\\skurri.TTF'
		elseif SUI.DB.font.Modules[Module].Face == 'Morpheus' then
			return 'Fonts\\MORPHEUS.TTF'
		elseif SUI.DB.font.Modules[Module].Face == 'Custom' and SUI.DB.font.Path ~= '' then
			return SUI.DB.font.Path
		end
	end

	--Failsafe, no module should be undefined as of 5.0
	return 'Interface\\AddOns\\SpartanUI\\media\\Roboto-Bold.ttf'
end

function SUI:FormatFont(element, size, Module, UpdateOnly)
	--If no module defined fall back to main settings
	if not Module then
		Module = 'Primary'
	end

	--Set Font Outline
	local flags, sizeFinal = ''
	if SUI.DB.font.Modules[Module].Type == 'monochrome' then
		flags = flags .. 'monochrome '
	elseif SUI.DB.font.Modules[Module].Type == 'thickoutline' then
		flags = flags .. 'thickoutline '
	elseif SUI.DB.font.Modules[Module].Type == 'outline' then
		element:SetShadowColor(0, 0, 0, .9)
		element:SetShadowOffset(1, -1)
	end

	--Set Size
	sizeFinal = size + SUI.DB.font.Modules[Module].Size

	--Create Font
	element:SetFont(SUI:GetFontFace(Module), sizeFinal, flags)

	--Store item for latter updating
	if not UpdateOnly then
		module:StoreFontItem(element, size, Module)
	end
end

--[[
    Refresh the font settings for the specified module.
    If no module is specified all modules will be updated
]]
function SUI:FontRefresh(Module)
	if not Module then
		for key, v in ipairs(SUI.DB.font.Modules) do
			SUI:FontRefesh(key)
		end
	else
		for i = 1, FontItems[Module].Count do
			SUI:FormatFont(FontItems[Module][i], FontItems[Module][i .. 'DefaultSize'], Module, true)
		end
	end
end

function module:OnEnable()
	SUI.opt.args['General'].args['font'] = {
		name = L['FontSizeStyle'],
		type = 'group',
		order = 200,
		args = {
			a = {name = L['Global font settings'], type = 'header'},
			aa = {
				name = L['Large number seperator'],
				desc = L['This is used to split up large numbers example: 100,000'],
				type = 'select',
				values = {[''] = '', [','] = ',', ['.'] = '.'},
				get = function(info)
					return SUI.DB.font.NumberSeperator
				end,
				set = function(info, val)
					SUI.DB.font.NumberSeperator = val
				end
			},
			b = {
				name = L['Font face'],
				type = 'select',
				values = FontFaces,
				get = function(info)
					return SUI.DB.font.Global.Face
				end,
				set = function(info, val)
					SUI.DB.font.Global.Face = val
				end
			},
			c = {
				name = L['Font style'],
				type = 'select',
				values = {
					['normal'] = L['normal'],
					['monochrome'] = L['monochrome'],
					['outline'] = L['outline'],
					['thickoutline'] = L['thickoutline']
				},
				get = function(info)
					return SUI.DB.font.Global.Type
				end,
				set = function(info, val)
					SUI.DB.font.Global.Type = val
				end
			},
			d = {
				name = L['Adjust font size'],
				type = 'range',
				width = 'double',
				min = -3,
				max = 3,
				step = 1,
				get = function(info)
					return SUI.DB.font.Global.Size
				end,
				set = function(info, val)
					SUI.DB.font.Global.Size = val
				end
			},
			z = {
				name = L['AplyGlobal'] .. ' ' .. L['AllSet'],
				type = 'execute',
				width = 'double',
				func = function()
                    for Module, v in ipairs(FontItems) do
                        SUI.DB.font.Modules[Module].Face = SUI.DB.font.Modules.Global.Face
                        SUI.DB.font.Modules[Module].Type = SUI.DB.font.Modules.Global.Type
                        SUI.DB.font.Modules[Module].Size = SUI.DB.font.Modules.Global.Size
                    end
					SUI:FontRefresh()
				end
			}
		}
	}

	--Setup the Options in 5 seconds giving modules time to populate.
	self:ScheduleTimer('BuildOptions', 5)
end

function module:BuildOptions()
	--We build the options based on the modules that are loaded and in use.
	for Module, v in ipairs(FontItems) do
		SUI.opt.args['General'].args['font'].args[Module] = {
			name = Module,
			type = 'group',
			args = {
				face = {
					name = L['Font face'],
					type = 'select',
					order = 1,
					values = FontFaces,
					get = function(info)
						return SUI.DB.font.Modules[Module].Face
					end,
					set = function(info, val)
						SUI.DB.font.Modules[Module].Face = val
						SUI:FontRefresh(Module)
					end
				},
				style = {
					name = L['Font style'],
					type = 'select',
					order = 2,
					values = {
						['normal'] = L['normal'],
						['monochrome'] = L['monochrome'],
						['outline'] = L['outline'],
						['thickoutline'] = L['thickoutline']
					},
					get = function(info)
						return SUI.DB.font.Modules[Module].Type
					end,
					set = function(info, val)
						SUI.DB.font.Modules[Module].Type = val
						SUI:FontRefresh(Module)
					end
				},
				size = {
					name = L['Adjust font size'],
					type = 'range',
					order = 3,
					width = 'full',
					min = -3,
					max = 3,
					step = 1,
					get = function(info)
						return SUI.DB.font.Modules[Module].Size
					end,
					set = function(info, val)
						SUI.DB.font.Modules[Module].Size = val
						SUI:FontRefresh(Module)
					end
				}
			}
		}
	end
end
