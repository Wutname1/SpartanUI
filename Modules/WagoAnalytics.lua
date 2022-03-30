local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local module = SUI:NewModule('Module_WagoAnalytics')
module.DisplayName = 'Wago Analytics'
module.description = L['Module handles Wago Analytics collection IF your update client supports it.']
SUI.Analytics = module
local print = SUI.print
----------------------------------------

function module:Set(moduleName, setting, value)
	if not module.DB.Enabled or SUI:IsModuleDisabled(module) then
		return
	end

	-- Find Module name
	if type(moduleName) == 'table' then
		moduleName = SUI:GetModuleName(moduleName)
		if not moduleName then
			return
		end
	end

	--Detect module type
	local name = moduleName .. '_' .. setting
	if moduleName ~= 'Core' then
		name = 'Module_' .. name
	end

	if module.DB.CollectedData[name] ~= tostring(value) then
		module.DB.CollectedData[name] = tostring(value)

		if type(value) == 'number' then
			SUI.WagoAnalytics:SetCounter(name, value)
		else
			SUI.WagoAnalytics:Switch(name, value)
		end
		setupOption(name)
	end
end

function setupOption(setting)
	if not SUI.opt.args.ModSetting or not SUI.opt.args.ModSetting.args.WagoAnalytics then
		return
	end

	SUI.opt.args.ModSetting.args.WagoAnalytics.args.SessionData.args[setting] = {
		name = setting,
		type = 'input',
		width = 'full'
	}
end

local function InitalCollection()
	-- Inital Analytics
	for _, submodule in pairs(SUI.orderedModules) do
		module:Set(submodule, 'Enabled', SUI:IsModuleEnabled(submodule))
	end

	module:Set('Core', 'Scale', SUI.DB.scale)
	module:Set('UnitFrames', 'Style', SUI:GetModule('Component_UnitFrames').DB.Style)
	module:Set('Artwork', 'Style', SUI.DB.Artwork.Style)
end

local function SetupPage()
	local PageData = {
		ID = 'WagoAnalytics',
		Name = 'Wago Analytics',
		RequireDisplay = module.DB.FirstLaunch,
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi

			--Container
			local WagoAnalytics = CreateFrame('Frame', nil)
			WagoAnalytics:SetParent(SUI_Win)
			WagoAnalytics:SetAllPoints(SUI_Win)

			if SUI:IsModuleDisabled('WagoAnalytics') then
				WagoAnalytics.lblDisabled = StdUi:Label(WagoAnalytics, 'Disabled', 20)
				WagoAnalytics.lblDisabled:SetPoint('CENTER', WagoAnalytics)
				-- Attaching
				SUI_Win.WagoAnalytics = WagoAnalytics
			else
				WagoAnalytics.lbl0 =
					StdUi:Label(
					WagoAnalytics,
					L[
						'SpartanUI has introduced Wago Analytics.\n\nWago Analytics is a service that allows us to collect anonymous data about your usage of the addon.\n\nWe use this data to improve the addon and to make it more user friendly.\n\nYou can disable this option if you do not want to share your data with us.'
					],
					nil,
					nil,
					500
				)

				WagoAnalytics.lbl1 =
					StdUi:Label(
					WagoAnalytics,
					L['Without using the Wago or WowUp client no data collected will be sent.'],
					15,
					nil,
					500
				)

				WagoAnalytics.lbl2 =
					StdUi:Label(
					WagoAnalytics,
					L['You can view all collected data in the SUI options under Modules -> Wago Analytics.'],
					nil,
					nil,
					500
				)

				window.Skip:SetText('No thanks')
				window.Next:SetText("I'm in")
				-- Positioning
				StdUi:GlueTop(WagoAnalytics.lbl0, SUI_Win, 0, -25)
				StdUi:GlueBelow(WagoAnalytics.lbl1, WagoAnalytics.lbl0, 0, -15)
				StdUi:GlueBelow(WagoAnalytics.lbl2, WagoAnalytics.lbl1, 0, -15)

				-- Attaching
				SUI_Win.WagoAnalytics = WagoAnalytics
			end
		end,
		Next = function()
			SUI:GetModule('SetupWizard').window.Skip:SetText('SKIP')
			SUI:GetModule('SetupWizard').window.Next:SetText('CONTINUE')
			module.DB.FirstLaunch = false
			InitalCollection()
		end,
		Skip = function()
			SUI:GetModule('SetupWizard').window.Skip:SetText('SKIP')
			SUI:GetModule('SetupWizard').window.Next:SetText('CONTINUE')
			SUI:DisableModule(module)
			module.DB.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end

local function BuildOptions()
	if SUI.opt.args.ModSetting.args.WagoAnalytics then
		SUI.opt.args.ModSetting.args.WagoAnalytics.disabled = false
		return
	end

	SUI.opt.args['ModSetting'].args['WagoAnalytics'] = {
		type = 'group',
		name = 'Wago Analytics',
		args = {
			Settings = {
				name = 'Settings',
				type = 'group',
				inline = true,
				order = 1,
				args = {
					Enabled = {
						name = L['Enabled'],
						type = 'toggle',
						order = .1,
						width = 'full',
						get = function(info)
							return module.DB[info[#info]]
						end,
						set = function(info, val)
							module.DB[info[#info]] = val
						end
					},
					['1'] = {
						name = L['Without using the Wago or WowUp client no data collected will be sent.'],
						type = 'description',
						fontSize = 'large',
						order = 2,
						width = 'full'
					},
					['2'] = {
						name = L[
							'This sends anonymous crash logs and telemetry from your game right to the developer, enabling me to improve the addon.'
						],
						type = 'description',
						fontSize = 'medium',
						order = 3,
						width = 'full'
					},
					['3'] = {
						name = L[
							'You can view all collected data below, note some additional data will/can be collected as settings within SUI are changed. That data will show up below as it is collected.'
						],
						type = 'description',
						fontSize = 'medium',
						order = 4,
						width = 'full'
					}
				}
			},
			SessionData = {
				name = L['Data collected this session'],
				type = 'group',
				inline = true,
				order = 2,
				get = function(info)
					return module.DB.CollectedData[info[#info]]
				end,
				set = function(info, value)
				end,
				args = {
					['1'] = {
						name = 'Class',
						type = 'input',
						width = 'full',
						get = function(info)
							return UnitClass('player')
						end,
						set = function(info, value)
						end
					}
				}
			},
			AllDataCollected = {
				name = L['All data collected'],
				type = 'input',
				width = 'full',
				multiline = 30,
				order = 3,
				get = function(info)
					return SUI:TableToLuaString(module.DB.CollectedData)
				end,
				set = function(info, value)
				end
			}
		}
	}
end

function module:OnInitialize()
	local defaults = {
		profile = {
			FirstLaunch = true,
			Enabled = true,
			CollectedData = {}
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('WagoAnalytics', defaults)
	module.DB = module.Database.profile
end

function module:OnEnable()
	if not SUI.IsRetail then
		SUI:DisableModule(module)
		return
	end
	--Module Setup
	SetupPage()
	BuildOptions()

	if not module.DB.Enabled or module.DB.FirstLaunch then
		return
	end

	InitalCollection()
end

function module:OnDisable()
	if SUI.opt.args.ModSetting.args.WagoAnalytics then
		SUI.opt.args.ModSetting.args.WagoAnalytics.disabled = true
	end
end
