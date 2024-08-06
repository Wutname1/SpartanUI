---@class SUI
local SUI = SUI
local L, Lib = SUI.L, SUI.Lib
---@class SUI.Handler.Options : SUI.Module
local module = SUI:NewModule('Handler.Options')
module.ShowOptionsUI = false
local unpack = unpack
local Options = {}
---------------------------------------------------------------------------
function module:GetConfigWindow()
	local ConfigOpen = Lib.AceCD and Lib.AceCD.OpenFrames and Lib.AceCD.OpenFrames['SpartanUI']
	return ConfigOpen and ConfigOpen.frame
end

function module:OnInitialize()
	SUI.opt.args.General.args = {
		ver1 = {
			name = 'SUI Version: ' .. SUI.Version,
			type = 'description',
			order = 50,
			fontSize = 'large',
		},
		ver2 = {
			name = 'SUI Build: ' .. SUI.BuildNum,
			type = 'description',
			order = 51,
			fontSize = 'large',
		},
		ver3 = {
			name = 'Bartender4 Version: ' .. SUI.Bartender4Version,
			type = 'description',
			order = 53,
			fontSize = 'large',
		},
		line2 = { name = '', type = 'header', order = 99 },
		navigationissues = {
			name = L['Have a Question?'],
			type = 'description',
			order = 100,
			fontSize = 'medium',
		},
		navigationissues2 = {
			name = '',
			type = 'input',
			order = 101,
			width = 'full',
			get = function(info)
				return 'https://discord.gg/Qc9TRBv'
			end,
			set = function(info, value) end,
		},
		bugsandfeatures = {
			name = L['Bugs & Feature Requests'] .. ':',
			type = 'description',
			order = 200,
			fontSize = 'medium',
		},
		bugsandfeatures2 = {
			name = '',
			type = 'input',
			order = 201,
			width = 'full',
			get = function(info)
				return 'http://bugs.spartanui.net/'
			end,
			set = function(info, value) end,
		},
		ErrorHandler = {
			name = L['Error handler'],
			type = 'group',
			inline = true,
			order = 300,
			get = function(info)
				return SUI.DBG.ErrorHandler[info[#info]]
			end,
			set = function(info, val)
				SUI.DBG.ErrorHandler[info[#info]] = val
				SUI.AutoOpenErrors = (SUI.DBG.ErrorHandler.AutoOpenErrors or false)
			end,
			args = {
				AutoOpenErrors = {
					name = L['Auto open on error'],
					desc = L['Automatically open the error report window when a bug occurs.'],
					type = 'toggle',
				},
			},
		},
		style = {
			name = L['Art Style'],
			type = 'group',
			order = 100,
			args = {
				description = { type = 'header', name = L['Overall Style'], order = 1 },
				OverallStyle = {
					name = '',
					type = 'group',
					inline = true,
					order = 10,
					args = {},
				},
				description2 = { type = 'header', name = L['Artwork Style'], order = 19 },
				Artwork = {
					type = 'group',
					name = L['Artwork'],
					inline = true,
					order = 20,
					args = {},
				},
				description3 = { type = 'header', name = L['Unitframe Style'], order = 29 },
			},
		},
	}

	local Skins = {
		'Classic',
		'War',
		'Tribal',
		'Fel',
		'Digital',
		'Arcane',
		'Transparent',
		'Minimal',
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
				SUI:SetActiveStyle(skin)
			end,
		}
		-- Setup artwork button
		SUI.opt.args.General.args.style.args.Artwork.args[skin] = {
			name = skin,
			type = 'execute',
			image = function()
				return 'interface\\addons\\SpartanUI\\images\\setup\\Style_' .. skin, 120, 60
			end,
			func = function()
				---@type SUI.Module.Artwork
				local artworkModule = SUI:GetModule('Artwork')
				artworkModule:SetActiveStyle(skin)
			end,
		}
	end

	SUI.opt.args.Help = {
		name = L['Help'],
		type = 'group',
		order = 900,
		args = {
			SUIActions = {
				name = L['SUI Core Reset'],
				type = 'group',
				inline = true,
				order = 40,
				args = {
					ReRunSetupWizard = {
						name = L['Rerun setup wizard'],
						type = 'execute',
						order = 0.1,
						func = function()
							SUI:GetModule('SetupWizard'):SetupWizard()
						end,
					},
					ResetProfileDB = {
						name = L['Reset profile'],
						type = 'execute',
						width = 'double',
						desc = L['Start fresh with a new SUI profile'],
						order = 0.5,
						func = function()
							SUI.SpartanUIDB:ResetProfile()
							ReloadUI()
						end,
					},
					ResetDB = {
						name = L['Reset Database'],
						type = 'execute',
						desc = L['New SUI profile did not work? This is your nucular option. Reset everything SpartanUI related.'],
						order = 1,
						func = function()
							SUI.SpartanUIDB:ResetDB()
							ReloadUI()
						end,
					},
				},
			},
			line1 = { name = '', type = 'header', order = 40 },
			SUIModuleHelp = {
				name = L['SUI module resets'],
				type = 'group',
				order = 45,
				inline = true,
				args = {
					ResetMovedFrames = {
						name = L['Reset movable frames'],
						type = 'execute',
						order = 3,
						func = function()
							SUI.MoveIt:Reset()
						end,
					},
				},
			},
			line2 = { name = '', type = 'header', order = 49 },
			ver1 = {
				name = 'SUI ' .. L['Version'] .. ': ' .. SUI.Version,
				type = 'description',
				order = 50,
				fontSize = 'large',
			},
			ver2 = {
				name = 'SUI ' .. L['Build'] .. ': ' .. SUI.BuildNum,
				type = 'description',
				order = 51,
				fontSize = 'large',
			},
			ver3 = {
				name = L['Bartender4 version'] .. ': ' .. SUI.Bartender4Version,
				type = 'description',
				order = 53,
				fontSize = 'large',
			},
			line3 = { name = '', type = 'header', order = 99 },
			navigationissues = { name = L['Have a Question?'], type = 'description', order = 100, fontSize = 'large' },
			navigationissues2 = {
				name = '',
				type = 'input',
				order = 101,
				width = 'full',
				get = function(info)
					return 'https://discord.gg/Qc9TRBv'
				end,
				set = function(info, value) end,
			},
			bugsandfeatures = {
				name = L['Bugs & Feature Requests'] .. ':',
				type = 'description',
				order = 200,
				fontSize = 'large',
			},
			bugsandfeatures2 = {
				name = '',
				type = 'input',
				order = 201,
				width = 'full',
				get = function(info)
					return 'http://bugs.spartanui.net/'
				end,
				set = function(info, value) end,
			},
			line4 = { name = '', type = 'header', order = 500 },
		},
	}

	SUI.opt.args.Modules = {
		name = L['Modules'],
		type = 'group',
		order = 4,
		args = {
			ModuleListing = {
				name = L['Enabled modules'],
				type = 'group',
				inline = true,
				args = {},
			},
		},
	}

	-- List Modules
	for name, submodule in SUI:IterateModules() do
		if not string.match(name, 'Handler.') and not string.match(name, 'Style.') and not submodule.HideModule then
			local Displayname = name
			if submodule.DisplayName then Displayname = submodule.DisplayName end

			SUI.opt.args.Modules.args.ModuleListing.args[name] = {
				name = Displayname,
				type = 'toggle',
				disabled = submodule.Override or false,
				get = function(info)
					if submodule.Override then return false end
					return SUI:IsModuleEnabled(name)
				end,
				set = function(info, val)
					if val then
						SUI:EnableModule(submodule)
					else
						SUI:DisableModule(submodule)
					end
				end,
			}
		end
	end

	SUI.opt.args.Modules.args.enabledModules = {
		name = L['Enabled modules'],
		type = 'group',
		order = 0.1,
		args = {
			Modules = SUI.opt.args.Modules.args.ModuleListing,
		},
	}
end

function module:OnEnable()
	if not SUI:GetModule('Artwork', true) then SUI.opt.args.General.args['style'].args['OverallStyle'].disabled = true end

	SUI:AddChatCommand('help', function()
		module:ToggleOptions({ 'Help' })
	end, 'Displays SUI Help screen')
end

function module:ConfigOpened(name)
	if name ~= 'SpartanUI' then return end

	local frame = module:GetConfigWindow()
	if frame and frame.bottomHolder then frame.bottomHolder:Show() end
end
function module:PLAYER_REGEN_ENABLED()
	module:ToggleOptions()
end

---@param pages? table
function module:ToggleOptions(pages)
	if InCombatLockdown() then
		SUI:Print(ERR_NOT_IN_COMBAT)
		module.ShowOptionsUI = true
		module:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end
	module:UnregisterEvent('PLAYER_REGEN_ENABLED')
	module.ShowOptionsUI = false

	local frame = module:GetConfigWindow()
	local mode = 'Open'
	if frame then mode = 'Close' end

	local ACD = Lib.AceCD
	if ACD then
		if not ACD.OpenHookedSUI then
			hooksecurefunc(Lib.AceCD, 'Open', module.ConfigOpened)
			ACD.OpenHookedSUI = true
		end

		ACD[mode](ACD, 'SpartanUI')
	end

	if not frame then frame = module:GetConfigWindow() end

	if mode == 'Open' and frame then
		if not frame.bottomHolder then -- window was released or never opened
			local bottom = CreateFrame('Frame', nil, frame, BackdropTemplateMixin and 'BackdropTemplate')
			bottom:SetPoint('BOTTOMLEFT', 2, 2)
			bottom:SetPoint('BOTTOMRIGHT', -2, 2)
			bottom:SetHeight(35)
			bottom:SetBackdropBorderColor(0, 0, 0, 0)
			frame.bottomHolder = bottom

			local ProfileHandler = SUI:GetModule('Handler.Profiles', true) ---@type SUI.Handler.Profiles
			if ProfileHandler then
				local Export = CreateFrame('Button', nil, bottom, 'UIPanelButtonTemplate')
				Export:SetSize(150, 20)
				Export:SetText('Export')
				Export:SetPoint('BOTTOM', 80, 10)
				Export:HookScript('OnClick', function()
					ProfileHandler:ExportUI()
					ACD:Close('SpartanUI')
				end)
				SUI.Skins.SkinObj('Button', Export, 'Light', 'Ace3')
				bottom.Export = Export

				local Import = CreateFrame('Button', nil, bottom, 'UIPanelButtonTemplate')
				Import:SetSize(150, 20)
				Import:SetText('Import')
				Import:SetPoint('BOTTOM', -80, 10)
				Import:HookScript('OnClick', function()
					ProfileHandler:ImportUI()
					ACD:Close('SpartanUI')
				end)
				SUI.Skins.SkinObj('Button', Import, 'Light', 'Ace3')
				bottom.Import = Import
			end

			if SUI:IsModuleEnabled('MoveIt') then
				local MoveIt = CreateFrame('Button', nil, bottom, 'UIPanelButtonTemplate')
				MoveIt:SetSize(150, 20)
				MoveIt:SetText(L['Toggle movers'])
				MoveIt:SetPoint('RIGHT', bottom.Import, 'LEFT', -25, 0)
				MoveIt:HookScript('OnClick', function()
					SUI.MoveIt:MoveIt()
				end)
				SUI.Skins.SkinObj('Button', MoveIt, 'Light', 'Ace3')
				bottom.MoveIt = MoveIt
			end

			local Logo = bottom:CreateTexture()
			Logo:SetTexture('Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
			Logo:SetPoint('LEFT', bottom, 'LEFT')
			Logo:SetSize(156, 45)
			Logo:SetScale(0.78)
			Logo:SetTexCoord(0, 0.611328125, 0, 0.6640625)
			bottom.Logo = Logo

			frame:HookScript('OnHide', function()
				if bottom then bottom:Hide() end
			end)
		end

		if ACD and pages then ACD:SelectGroup('SpartanUI', unpack(pages)) end
	end
end

---@alias OptionsType
---| "Module"
---| "Help"
---| "Root"
---| "General"

---@param OptionsTable AceConfig.OptionsTable
---@param name? string
---@param OptType? OptionsType Default is "Module"
function Options:AddOptions(OptionsTable, name, OptType)
	if OptType == nil or OptType == 'Module' then
		SUI.opt.args.Modules.args[name or tostring(#SUI.opt.args.Modules.args)] = OptionsTable
	elseif OptType == 'Root' then
		SUI.opt.args[name or tostring(#SUI.opt.args)] = OptionsTable
	elseif OptType ~= nil then
		SUI.opt.args[OptType].args[name or tostring(#SUI.opt.args[OptType].args)] = OptionsTable
	end
end

function Options:DisableOptions(name)
	SUI.opt.args.Modules.args[name or tostring(#SUI.opt.args.Modules.args)].disabled = not (SUI.opt.args.Modules.args[name or tostring(#SUI.opt.args.Modules.args)].disabled or false)
end

Options.ToggleOptions = module.ToggleOptions

SUI.Options = Options
