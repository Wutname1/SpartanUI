local SUI, L = SUI, SUI.L
local module = SUI:NewModule('Handler_Font', 'AceTimer-3.0')

module.FontItems = {}
local FontFaces = {
	['SpartanUI'] = 'Cognosis',
	['Roboto'] = 'Roboto',
	['Roboto-Bold'] = 'Roboto Bold',
	['Myriad'] = 'Myriad',
	['SUI4'] = 'NotoSans',
	['SUI4cn'] = 'NotoSans (zhCN)',
	['FrizQuadrata'] = 'Friz Quadrata',
	['ArialNarrow'] = 'Arial Narrow',
	['Skurri'] = 'Skurri',
	['Morpheus'] = 'Morpheus'
}

function module:StoreFontItem(element, DefaultSize, Module)
	--Create tracking table if needed
	if not module.FontItems[Module] then
		module.FontItems[Module] = {Count = 0}
	end

	--Load next ID number
	local NewItemID = module.FontItems[Module].Count + 1

	--Store element and latest ID used
	module.FontItems[Module].Count = NewItemID
	module.FontItems[Module][NewItemID .. 'DefaultSize'] = DefaultSize
	module.FontItems[Module][NewItemID] = element
end

function SUI:comma_value(n)
	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)', '%1' .. SUI.DB.font.NumberSeperator):reverse()) .. right
end

function SUI:round(val, decimal)
	if (decimal) then
		return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	else
		return math.floor(val + 0.5)
	end
end

function SUI:GetFontFace(Module)
	if Module then
		if SUI.DB.font.Modules[Module].Face == 'SpartanUI' then
			return 'Interface\\AddOns\\SpartanUI\\fonts\\Cognosis.ttf'
		elseif SUI.DB.font.Modules[Module].Face == 'SUI4' then
			return 'Interface\\AddOns\\SpartanUI\\fonts\\NotoSans-Bold.ttf'
		elseif SUI.DB.font.Modules[Module].Face == 'Roboto' then
			return 'Interface\\AddOns\\SpartanUI\\fonts\\Roboto-Medium.ttf'
		elseif SUI.DB.font.Modules[Module].Face == 'Roboto-Bold' then
			return 'Interface\\AddOns\\SpartanUI\\fonts\\Roboto-Bold.ttf'
		elseif SUI.DB.font.Modules[Module].Face == 'Myriad' then
			return 'Interface\\AddOns\\SpartanUI\\fonts\\myriad.ttf'
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
	return 'Interface\\AddOns\\SpartanUI\\fonts\\Roboto-Bold.ttf'
end

local function FindID(element, Module)
	for i = 1, module.FontItems[Module].Count do
		if module.FontItems[Module][i] == element then
			return i
		end
	end
	return false
end

function SUI:UpdateDefaultSize(element, size, Module)
	--Update stored default
	local ID = FindID(element, Module)
	if ID then
		--Update the DB
		module.FontItems[Module][ID .. 'DefaultSize'] = size
		--Update the screen
		SUI:FormatFont(module.FontItems[Module][ID], size, Module, true)
	end
end

function SUI:FormatFont(element, size, Module, UpdateOnly)
	--If no module defined fall back to main settings
	if not element then
		return
	end
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
	if sizeFinal < 1 then
		sizeFinal = 1
	end

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
		for key, _ in pairs(module.FontItems) do
			SUI:FontRefresh(key)
		end
	else
		for i = 1, module.FontItems[Module].Count do
			SUI:FormatFont(module.FontItems[Module][i], module.FontItems[Module][i .. 'DefaultSize'], Module, true)
		end
	end
end

local function FontSetupWizard()
	local PageData, SetupWindow

	local fontlist = {
		'RobotoBold',
		'Roboto',
		'Cognosis',
		'NotoSans',
		'FrizQuadrata',
		'ArialNarrow'
	}
	local fontnames = {
		['RobotoBold'] = 'Roboto-Bold',
		['Roboto'] = 'Roboto',
		['Cognosis'] = 'SpartanUI',
		['NotoSans'] = 'SUI4',
		['FrizQuadrata'] = 'FrizQuadrata',
		['ArialNarrow'] = 'ArialNarrow'
	}

	PageData = {
		ID = 'FontSetup',
		name = L['Font style'],
		SubTitle = 'Font Style',
		RequireDisplay = (not SUI.DB.font.SetupDone),
		Display = function()
			local SUI_Win = SUI:GetModule('SetupWizard').window
			SUI_Win.FontFace = CreateFrame('Frame', nil)
			SUI_Win.FontFace:SetParent(SUI_Win.content)
			SUI_Win.FontFace:SetAllPoints(SUI_Win.content)

			local RadioButtons = function(self)
				for _, v in ipairs(fontlist) do
					SUI_Win.FontFace[v].radio:SetValue(false)
				end

				self.radio:SetValue(true)
			end

			local gui = LibStub('AceGUI-3.0')
			local control, radio

			--RobotoBold
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\images\\setup\\Setup-Fonts', 0, 0.421875, 0, 0.3125)
			control:SetImageSize(180, 60)
			control:SetPoint('TOPLEFT', SUI_Win.FontFace, 'TOPLEFT', 55, -55)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Roboto Bold')
			radio:SetUserData('value', 'Roboto-Bold')
			radio:SetUserData('text', 'Roboto-Bold')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.RobotoBold = control

			--Roboto
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\images\\setup\\Setup-Fonts', 0, 0.421875, 0.34375, 0.65625)
			control:SetImageSize(180, 60)
			control:SetPoint('LEFT', SUI_Win.FontFace.RobotoBold.frame, 'RIGHT', 80, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Roboto')
			radio:SetUserData('value', 'Roboto')
			radio:SetUserData('text', 'Roboto')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.Roboto = control

			--Cognosis
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\images\\setup\\Setup-Fonts', 0, 0.421875, 0.6875, 1)
			control:SetImageSize(180, 60)
			control:SetPoint('LEFT', SUI_Win.FontFace.Roboto.frame, 'RIGHT', 80, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Cognosis')
			radio:SetUserData('value', 'SpartanUI')
			radio:SetUserData('text', 'SpartanUI')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.Cognosis = control

			--NotoSans
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\images\\setup\\Setup-Fonts', 0.578125, 1, 0, 0.3125)
			control:SetImageSize(180, 60)
			control:SetPoint('TOP', SUI_Win.FontFace.RobotoBold.radio.frame, 'BOTTOM', 0, -20)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('NotoSans')
			radio:SetUserData('value', 'SUI4')
			radio:SetUserData('text', 'SUI4')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.NotoSans = control

			--FrizQuadrata
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\images\\setup\\Setup-Fonts', 0.578125, 1, 0.34375, 0.65625)
			control:SetImageSize(180, 60)
			control:SetPoint('LEFT', SUI_Win.FontFace.NotoSans.frame, 'RIGHT', 80, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Friz Quadrata')
			radio:SetUserData('value', 'FrizQuadrata')
			radio:SetUserData('text', 'FrizQuadrata')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.FrizQuadrata = control

			--ArialNarrow
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\images\\setup\\Setup-Fonts', 0.578125, 1, 0.6875, 1)
			control:SetImageSize(180, 60)
			control:SetPoint('LEFT', SUI_Win.FontFace.FrizQuadrata.frame, 'RIGHT', 80, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Arial Narrow')
			radio:SetUserData('value', 'ArialNarrow')
			radio:SetUserData('text', 'ArialNarrow')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.ArialNarrow = control

			SUI_Win.FontFace.RobotoBold.radio:SetValue(true)
		end,
		Next = function()
			local SUI_Win = SUI:GetModule('SetupWizard').window
			local fontface

			for _, v in ipairs(fontlist) do
				if SUI_Win.FontFace[v].radio:GetValue() then
					fontface = fontnames[v]
				end
			end

			if fontface then
				SUI.DB.font.Modules.Primary.Face = fontface
				SUI.DB.font.Modules.Core.Face = fontface
				SUI.DB.font.Modules.Player.Face = fontface
				SUI.DB.font.Modules.Party.Face = fontface
				SUI.DB.font.Modules.Raid.Face = fontface
			end
			SUI_Win.FontFace:Hide()
			SUI_Win.FontFace = nil
			SUI.DB.font.SetupDone = true
		end,
		Skip = function()
			local SUI_Win = SUI:GetModule('SetupWizard').window
			SUI_Win.FontFace:Hide()
			SUI_Win.FontFace = nil
			SUI.DB.font.SetupDone = true
		end
	}

	SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end

function module:OnEnable()
	FontSetupWizard()
	SUI.opt.args['General'].args['font'] = {
		name = L['Font'],
		type = 'group',
		order = 200,
		args = {
			a = {name = L['Global font settings'], type = 'header'},
			aa = {
				name = L['Large number seperator'],
				desc = L['This is used to split up large numbers example: 100,000'],
				type = 'select',
				values = {[''] = 'none', [','] = 'comma', ['.'] = 'period'},
				get = function()
					return SUI.DB.font.NumberSeperator
				end,
				set = function(_, val)
					SUI.DB.font.NumberSeperator = val
				end
			},
			b = {
				name = L['Font face'],
				type = 'select',
				values = FontFaces,
				get = function()
					return SUI.DB.font.Modules.Global.Face
				end,
				set = function(_, val)
					SUI.DB.font.Modules.Global.Face = val
				end
			},
			c = {
				name = L['Font style'],
				type = 'select',
				values = {
					['normal'] = L['Normal'],
					['monochrome'] = L['Monochrome'],
					['outline'] = L['Outline'],
					['thickoutline'] = L['Thick outline']
				},
				get = function()
					return SUI.DB.font.Modules.Global.Type
				end,
				set = function(_, val)
					SUI.DB.font.Modules.Global.Type = val
				end
			},
			d = {
				name = L['Adjust font size'],
				type = 'range',
				width = 'double',
				min = -3,
				max = 3,
				step = 1,
				get = function()
					return SUI.DB.font.Modules.Global.Size
				end,
				set = function(_, val)
					SUI.DB.font.Modules.Global.Size = val
				end
			},
			z = {
				name = L['Apply Global to all'],
				type = 'execute',
				width = 'double',
				func = function()
					for Module, _ in pairs(module.FontItems) do
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
	self:ScheduleTimer('BuildOptions', 2)
end

function module:BuildOptions()
	--We build the options based on the modules that are loaded and in use.
	for Module, _ in pairs(module.FontItems) do
		SUI.opt.args['General'].args['font'].args[Module] = {
			name = Module,
			type = 'group',
			args = {
				face = {
					name = L['Font face'],
					type = 'select',
					order = 1,
					values = FontFaces,
					get = function()
						return SUI.DB.font.Modules[Module].Face
					end,
					set = function(_, val)
						SUI.DB.font.Modules[Module].Face = val
						SUI:FontRefresh(Module)
					end
				},
				style = {
					name = L['Font style'],
					type = 'select',
					order = 2,
					values = {
						['normal'] = L['Normal'],
						['monochrome'] = L['Monochrome'],
						['outline'] = L['Outline'],
						['thickoutline'] = L['Thick outline']
					},
					get = function()
						return SUI.DB.font.Modules[Module].Type
					end,
					set = function(_, val)
						SUI.DB.font.Modules[Module].Type = val
						SUI:FontRefresh(Module)
					end
				},
				size = {
					name = L['Adjust font size'],
					type = 'range',
					order = 3,
					width = 'double',
					min = -15,
					max = 15,
					step = 1,
					get = function()
						return SUI.DB.font.Modules[Module].Size
					end,
					set = function(_, val)
						SUI.DB.font.Modules[Module].Size = val
						SUI:FontRefresh(Module)
					end
				}
			}
		}
	end
end
