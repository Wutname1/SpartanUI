local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local module = SUI:NewModule('Handler_Options')

---------------------------------------------------------------------------
function module:InCombatLockdown()
	if InCombatLockdown() then
		SUI:Print('|cffff0000Unable to change setting in combat')
		return true
	end

	return false
end

function module:GetConfigWindow()
	local ConfigOpen = Lib.AceCD and Lib.AceCD.OpenFrames and Lib.AceCD.OpenFrames['SpartanUI']
	return ConfigOpen and ConfigOpen.frame
end

function module:OnInitialize()
	SUI.opt.args.General.args.style = {
		name = 'Art Style',
		type = 'group',
		order = 100,
		args = {
			description = {type = 'header', name = L['OverallStyle'], order = 1},
			OverallStyle = {
				name = '',
				type = 'group',
				inline = true,
				order = 10,
				args = {}
			},
			description2 = {type = 'header', name = 'Artwork Style', order = 19},
			Artwork = {
				type = 'group',
				name = L['Artwork'],
				inline = true,
				order = 20,
				args = {}
			},
			description3 = {type = 'header', name = 'Unitframe Style', order = 29}
		}
	}
	local Skins = {
		'Classic',
		'War',
		'Tribal',
		'Fel',
		'Digital',
		'Arcane',
		'Transparent',
		'Minimal'
	}

	-- Setup Buttons
	for _, skin in pairs(Skins) do
		-- Create overall skin button
		SUI.opt.args.General.args.style.args.OverallStyle.args[skin] = {
			name = skin,
			type = 'execute',
			image = function()
				return 'interface\\addons\\SpartanUI\\images\\setup\\Style_' .. skin, 120, 60
			end,
			func = function()
				SUI:GetModule('Component_Artwork'):SetActiveStyle(skin)
				SUI:GetModule('Component_UnitFrames'):SetActiveStyle(skin)
				SUI.opt.args.UnitFrames.args.BaseStyle.args[skin].func()
			end
		}
		-- Setup artwork button
		SUI.opt.args.General.args.style.args.Artwork.args[skin] = {
			name = skin,
			type = 'execute',
			image = function()
				return 'interface\\addons\\SpartanUI\\images\\setup\\Style_' .. skin, 120, 60
			end,
			func = function()
				SUI:GetModule('Component_Artwork'):SetActiveStyle(skin)
			end
		}
	end

	SUI.opt.args.Help = {
		name = 'Help',
		type = 'group',
		order = 900,
		args = {
			SUIActions = {
				name = 'SUI Core Reset',
				type = 'group',
				inline = true,
				order = 40,
				args = {
					ReRunSetupWizard = {
						name = L['Rerun setup wizard'],
						type = 'execute',
						order = .1,
						func = function()
							SUI:GetModule('SetupWizard'):SetupWizard()
						end
					},
					ResetProfileDB = {
						name = L['Reset profile'],
						type = 'execute',
						width = 'double',
						desc = 'Start fresh with a new SUI profile',
						order = .5,
						func = function()
							SUI.SpartanUIDB:ResetProfile()
							ReloadUI()
						end
					},
					ResetDB = {
						name = L['ResetDatabase'],
						type = 'execute',
						desc = 'New SUI profile did not work? This is your nucular option. Reset everything SpartanUI related.',
						order = 1,
						func = function()
							SUI.SpartanUIDB:ResetDB()
							ReloadUI()
						end
					}
				}
			},
			line1 = {name = '', type = 'header', order = 40},
			SUIModuleHelp = {
				name = 'SUI Module Resets',
				type = 'group',
				order = 45,
				inline = true,
				args = {
					ResetMovedFrames = {
						name = L['ResetMovableFrames'],
						type = 'execute',
						order = 3,
						func = function()
							SUI:GetModule('Component_MoveIt'):Reset()
						end
					}
				}
			},
			line1 = {name = '', type = 'header', order = 49},
			ver1 = {
				name = 'SUI ' .. L['Version'] .. ': ' .. SUI.Version,
				type = 'description',
				order = 50,
				fontSize = 'large'
			},
			ver2 = {
				name = 'SUI ' .. L['Build'] .. ': ' .. SUI.BuildNum,
				type = 'description',
				order = 51,
				fontSize = 'large'
			},
			ver3 = {
				name = L['Bartender4 version'] .. ': ' .. SUI.Bartender4Version,
				type = 'description',
				order = 53,
				fontSize = 'large'
			},
			line2 = {name = '', type = 'header', order = 99},
			navigationissues = {name = L['HaveQuestion'], type = 'description', order = 100, fontSize = 'large'},
			navigationissues2 = {
				name = '',
				type = 'input',
				order = 101,
				width = 'full',
				get = function(info)
					return 'https://discord.gg/Qc9TRBv'
				end,
				set = function(info, value)
				end
			},
			bugsandfeatures = {
				name = L['Bugs and Feature Requests'] .. ':',
				type = 'description',
				order = 200,
				fontSize = 'large'
			},
			bugsandfeatures2 = {
				name = '',
				type = 'input',
				order = 201,
				width = 'full',
				get = function(info)
					return 'http://bugs.spartanui.net/'
				end,
				set = function(info, value)
				end
			},
			line3 = {name = '', type = 'header', order = 500}

			-- description = {name=L["HelpStringDesc1"],type="description",order = 901,fontSize="large"},
			-- dataDump = {name=L["Export"],type="input",multiline=15,width="full",order=993,get = function(info) return module:enc(module:ExportData()) end},
		}
	}

	SUI.opt.args['General'].args['ver1'] = {
		name = 'SUI Version: ' .. SUI.Version,
		type = 'description',
		order = 50,
		fontSize = 'large'
	}
	SUI.opt.args['General'].args['ver2'] = {
		name = 'SUI Build: ' .. SUI.BuildNum,
		type = 'description',
		order = 51,
		fontSize = 'large'
	}
	SUI.opt.args['General'].args['ver3'] = {
		name = 'Bartender4 Version: ' .. SUI.Bartender4Version,
		type = 'description',
		order = 53,
		fontSize = 'large'
	}

	SUI.opt.args['General'].args['line2'] = {name = '', type = 'header', order = 99}
	SUI.opt.args['General'].args['navigationissues'] = {
		name = L['HaveQuestion'],
		type = 'description',
		order = 100,
		fontSize = 'medium'
	}
	SUI.opt.args['General'].args['navigationissues2'] = {
		name = '',
		type = 'input',
		order = 101,
		width = 'full',
		get = function(info)
			return 'https://discord.gg/Qc9TRBv'
		end,
		set = function(info, value)
		end
	}

	SUI.opt.args['General'].args['bugsandfeatures'] = {
		name = L['Bugs and Feature Requests'] .. ':',
		type = 'description',
		order = 200,
		fontSize = 'medium'
	}
	SUI.opt.args['General'].args['bugsandfeatures2'] = {
		name = '',
		type = 'input',
		order = 201,
		width = 'full',
		get = function(info)
			return 'http://bugs.spartanui.net/'
		end,
		set = function(info, value)
		end
	}

	SUI.opt.args['ModSetting'] = {
		name = L['Modules'],
		type = 'group',
		args = {
			Components = {
				name = 'Components',
				type = 'group',
				inline = true,
				args = {}
			}
		}
	}

	-- List Components
	for name, submodule in SUI:IterateModules() do
		if (string.match(name, 'Component_')) and not submodule.HideModule then
			local RealName = string.sub(name, 11)
			local Displayname = string.sub(name, 11)
			if submodule.DisplayName then
				Displayname = submodule.DisplayName
			end

			SUI.opt.args.ModSetting.args.Components.args[RealName] = {
				name = Displayname,
				type = 'toggle',
				disabled = submodule.Override or false,
				get = function(info)
					if submodule.Override then
						return false
					end
					return not SUI.DB.DisabledComponents[RealName]
				end,
				set = function(info, val)
					SUI.DB.DisabledComponents[RealName] = (not val)
					if submodule.OnDisable then
						if val then
							submodule:OnEnable()
						else
							submodule:OnDisable()
						end
					else
						SUI:reloadui()
					end
				end
			}
		end
	end

	SUI.opt.args.ModSetting.args['enabled'] = {
		name = L['Enabled modules'],
		type = 'group',
		order = .1,
		args = {
			Components = SUI.opt.args.ModSetting.args['Components']
		}
	}
end

function module:OnEnable()
	if not SUI:GetModule('Component_Artwork', true) then
		SUI.opt.args['General'].args['style'].args['OverallStyle'].disabled = true
	end

	SUI:AddChatCommand(
		'help',
		function()
			SUI.Lib.AceCD:Open('SpartanUI', 'Help')
		end
	)
end

function module:ConfigOpened(name)
	if name ~= 'SpartanUI' then
		return
	end

	local frame = module:GetConfigWindow()
	if frame and frame.leftHolder then
	-- E:Config_WindowOpened(frame)
	end
end

function module:ToggleOptions()
	if InCombatLockdown() then
		self:Print(ERR_NOT_IN_COMBAT)
		self.ShowOptionsUI = true
		return
	end

	local frame = module:GetConfigWindow()
	local mode = 'Open'
	if not frame then
		mode = 'Close'
	end

	local ACD = Lib.AceCD
	if ACD then
		if not ACD.OpenHookedSUI then
			hooksecurefunc(Lib.AceCD, 'Open', module.ConfigOpened)
			ACD.OpenHookedSUI = true
		end

		ACD[mode](ACD, 'SpartanUI')
	end

	if not frame then
		frame = module:GetConfigWindow()
	end

	if mode == 'Open' and frame then
		local ACR = E.Libs.AceConfigRegistry
		if ACR and not ACR.NotifyHookedElvUI then
			hooksecurefunc(E.Libs.AceConfigRegistry, 'NotifyChange', E.Config_UpdateLeftButtons)
			ACR.NotifyHookedElvUI = true
			E:Config_UpdateSize()
		end

		if not frame.bottomHolder then -- window was released or never opened
			frame:HookScript('OnHide', E.Config_WindowClosed)

			for i = 1, frame:GetNumChildren() do
				local child = select(i, frame:GetChildren())
				if child:IsObjectType('Button') and child:GetText() == _G.CLOSE then
					frame.originalClose = child
					child:Hide()
				elseif child:IsObjectType('Frame') or child:IsObjectType('Button') then
					if child:HasScript('OnMouseUp') then
						child:HookScript('OnMouseUp', E.Config_StopMoving)
					end
				end
			end

			local unskinned = not E.private.skins.ace3Enable
			if unskinned then
				for i = 1, frame:GetNumRegions() do
					local region = select(i, frame:GetRegions())
					if region:IsObjectType('Texture') and region:GetTexture() == 131080 then
						region:SetAlpha(0)
					end
				end
			end

			local bottom = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
			bottom:Point('BOTTOMLEFT', 2, 2)
			bottom:Point('BOTTOMRIGHT', -2, 2)
			bottom:Height(37)
			frame.bottomHolder = bottom

			local close = CreateFrame('Button', nil, frame, 'UIPanelCloseButton, BackdropTemplate')
			close:SetScript('OnClick', E.Config_CloseClicked)
			close:SetFrameLevel(1000)
			close:Point('TOPRIGHT', unskinned and -8 or 1, unskinned and -8 or 2)
			close:Size(32, 32)
			close.originalClose = frame.originalClose
			frame.closeButton = close

			local left = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
			left:Point('BOTTOMRIGHT', bottom, 'BOTTOMLEFT', 181, 0)
			left:Point('BOTTOMLEFT', bottom, 'TOPLEFT', 0, 1)
			left:Point('TOPLEFT', unskinned and 10 or 2, unskinned and -6 or -2)
			frame.leftHolder = left

			local top = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
			top.version = frame.obj.titletext
			top:Point('TOPRIGHT', frame, -2, 0)
			top:Point('TOPLEFT', left, 'TOPRIGHT', 1, 0)
			top:Height(24)
			frame.topHolder = top

			local LogoBottom = left:CreateTexture()
			LogoBottom:SetTexture(E.Media.Textures.LogoBottomSmall)
			LogoBottom:Point('CENTER', left, 'TOP', unskinned and 10 or 0, unskinned and -40 or -36)
			LogoBottom:Size(128, 64)
			left.LogoBottom = LogoBottom

			local LogoTop = left:CreateTexture()
			LogoTop:SetTexture(E.Media.Textures.LogoTopSmall)
			LogoTop:Point('CENTER', left, 'TOP', unskinned and 10 or 0, unskinned and -40 or -36)
			LogoTop:Size(128, 64)
			left.LogoTop = LogoTop

			local buttonsHolder = CreateFrame('Frame', nil, left)
			buttonsHolder:Point('BOTTOMLEFT', bottom, 'TOPLEFT', 0, 1)
			buttonsHolder:Point('TOPLEFT', left, 'TOPLEFT', 0, -70)
			buttonsHolder:Point('BOTTOMRIGHT')
			buttonsHolder:SetFrameLevel(5)
			buttonsHolder:SetClipsChildren(true)
			left.buttonsHolder = buttonsHolder

			local buttons = CreateFrame('Frame', nil, buttonsHolder, 'BackdropTemplate')
			buttons:Point('BOTTOMLEFT', bottom, 'TOPLEFT', 0, 1)
			buttons:Point('BOTTOMRIGHT')
			buttons:Point('TOPLEFT', 0, 0)
			left.buttons = buttons

			local slider = CreateFrame('Slider', nil, frame, 'BackdropTemplate')
			slider:SetThumbTexture(E.Media.Textures.White8x8)
			slider:SetScript('OnMouseWheel', ConfigSliderOnMouseWheel)
			slider:SetScript('OnValueChanged', ConfigSliderOnValueChanged)
			slider:SetOrientation('VERTICAL')
			slider:SetObeyStepOnDrag(true)
			slider:SetFrameLevel(4)
			slider:SetValueStep(1)
			slider:SetValue(0)
			slider:Width(192)
			slider:Point('BOTTOMLEFT', bottom, 'TOPLEFT', 0, 1)
			slider:Point('TOPLEFT', buttons, 'TOPLEFT', 0, 0)
			slider.buttons = buttons
			left.slider = slider

			local thumb = slider:GetThumbTexture()
			thumb:Point('LEFT', left, 'RIGHT', 2, 0)
			thumb:SetVertexColor(1, 1, 1, 0.5)
			thumb:Size(8, 12)
			left.slider.thumb = thumb

			if not unskinned then
				bottom:SetTemplate('Transparent')
				left:SetTemplate('Transparent')
				top:SetTemplate('Transparent')
				E.Skins:HandleCloseButton(close)
			end

			E:Config_CreateLeftButtons(frame, unskinned, E.Options.args)
			E:Config_CreateBottomButtons(frame, unskinned)
			E:Config_UpdateLeftScroller(frame)
			E:Config_WindowOpened(frame)
		end

		if ACD and pages then
			ACD:SelectGroup(E.name, unpack(pages))
		end
	end
end
