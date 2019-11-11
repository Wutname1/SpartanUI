local SUI, L = SUI, SUI.L
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local module = SUI:NewModule('Options')

local LDBIcon = LibStub('LibDBIcon-1.0', true)

---------------------------------------------------------------------------
function module:ArtSetup()
	SUI.DBG.BartenderChangesActive = true
	SUI:GetModule('Component_Artwork'):SetupProfile()

	SUI.DBG.BartenderChangesActive = false
end

function module:InCombatLockdown()
	if InCombatLockdown() then
		SUI:Print('|cffff0000Unable to change setting in combat')
		return true
	end

	return false
end

function module:OnInitialize()
	SUI.opt.args.General.args.style = {
		name = L['StyleSettings'],
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
		'Fel',
		'Digital',
		'Arcane',
		'Transparent',
		'Minimal'
	}

	-- Setup Buttons
	for i, skin in pairs(Skins) do
		-- Create overall skin button
		SUI.opt.args.General.args.style.args.OverallStyle.args[skin] = {
			name = skin,
			type = 'execute',
			image = function()
				return 'interface\\addons\\SpartanUI\\images\\setup\\Style_' .. skin, 120, 60
			end,
			func = function()
				SUI.DBMod.Artwork.Style = skin
				-- Fel has a subtheme stil so deal with that.
				if skin == 'Fel' or skin == 'Digital' then
					SUI.DBMod.Artwork.Style = 'Fel'
					SUI.DB.Styles.Fel.SubTheme = skin
				end

				SUI.DB.Unitframes.Style = skin
				SUI.opt.args.UnitFrames.args.BaseStyle.args[skin].func()
				module:ArtSetup()
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
				SUI.DBMod.Artwork.Style = skin
				-- Fel has a subtheme stil so deal with that.
				if skin == 'Fel' or skin == 'Digital' then
					SUI.DBMod.Artwork.Style = 'Fel'
					SUI.DB.Styles.Fel.SubTheme = skin
				end

				module:ArtSetup()
			end
		}
	end

	SUI.opt.args['Help'] = {
		name = 'Help',
		type = 'group',
		order = 900,
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
				order = .5,
				func = function()
					SUI.SpartanUIDB:ResetProfile()
					ReloadUI()
				end
			},
			ResetDB = {
				name = L['ResetDatabase'],
				type = 'execute',
				order = 1,
				func = function()
					SUI.SpartanUIDB:ResetDB()
					ReloadUI()
				end
			},
			ResetMovedFrames = {
				name = L['ResetMovableFrames'],
				type = 'execute',
				order = 3,
				func = function()
					SUI:GetModule('Component_MoveIt'):Reset()
				end
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
			line3 = {name = '', type = 'header', order = 500},
			FAQ = {name = 'F.A.Q', type = 'description', order = 501, fontSize = 'large'},
			FAQQ1 = {name = 'How do I move _________', type = 'description', order = 510, fontSize = 'medium'},
			FAQQ1A1 = {
				name = '- Unit frames can be moved by holding alt down and draging.',
				type = 'description',
				order = 511,
				fontSize = 'small'
			},
			FAQQ1A2 = {
				name = '- If the skin allows it the minimap can be moved by holding alt and dragging.',
				type = 'description',
				order = 512,
				fontSize = 'small'
			},
			FAQQ2 = {
				name = 'Actionbars are appearing in the wrong place',
				type = 'description',
				order = 520,
				fontSize = 'medium'
			},
			FAQQ2A1 = {
				name = '- Most issues can be fixed by reseting the action bars above.',
				type = 'description',
				order = 521,
				fontSize = 'small'
			}

			-- description = {name=L["HelpStringDesc1"],type="description",order = 901,fontSize="large"},
			-- description = {name=L["HelpStringDesc2"],type="description",order = 902,fontSize="small"},
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
		if (string.match(name, 'Component_')) then
			local RealName = string.sub(name, 11)
			if SUI.DB.EnabledComponents == nil then
				SUI.DB.EnabledComponents = {}
			end
			if SUI.DB.EnabledComponents[RealName] == nil then
				SUI.DB.EnabledComponents[RealName] = true
			end

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
					return SUI.DB.EnabledComponents[RealName]
				end,
				set = function(info, val)
					SUI.DB.EnabledComponents[RealName] = val
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
end

function module:ExportData()
	--Get Character Data
	local CharData = {
		Region = GetCurrentRegion(),
		class = UnitClass('player'),
		Faction = UnitFactionGroup('player'),
		-- PlayerName = UnitName("player"),
		PlayerLevel = UnitLevel('player'),
		ActiveSpec = GetSpecializationInfo(GetSpecialization()),
		Zone = GetRealZoneText() .. ' - ' .. GetSubZoneText()
	}

	--Generate List of Addons
	local AddonsInstalled = {}

	for i = 1, GetNumAddOns() do
		local name, _, _, enabled = GetAddOnInfo(i)
		if enabled == true then
			AddonsInstalled[i] = name
		end
	end

	return '$SUI.' ..
		SUI.Version ..
			'-' ..
				SUI.CurseVersion ..
					'$C.' ..
						module:FlatenTable(CharData) ..
							'$Artwork.Style.' ..
								SUI.DBMod.Artwork.Style ..
									'$UnitFrames.Style.' ..
										SUI.DBMod.UnitFrames.Style .. '$Addons.' .. module:FlatenTable(AddonsInstalled) .. '..$END$..'
	-- .. "$DB." .. module:FlatenTable(SUI.DB)
	-- .. "$DBMod." .. module:FlatenTable(SUI.DBMod)
end

function module:FlatenTable(input)
	local returnval = ''
	for key, value in pairs(input) do
		if (type(value) == 'table') then
			returnval = returnval .. key .. '= {' .. module:FlatenTable(value) .. '},'
		elseif (type(value) ~= 'string') then
			returnval = returnval .. key .. '=' .. tostring(value) .. ','
		else
			returnval = returnval .. key .. '=' .. value .. ','
		end
	end
	return returnval
end

-- encoding
function module:enc(data)
	return ((data:gsub(
		'.',
		function(x)
			local r, b = '', x:byte()
			for i = 8, 1, -1 do
				r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
			end
			return r
		end
	) .. '0000'):gsub(
		'%d%d%d?%d?%d?%d?',
		function(x)
			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
			if (#x < 6) then
				return ''
			end
			local c = 0
			for i = 1, 6 do
				c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
			end
			return b:sub(c + 1, c + 1)
		end
	) .. ({'', '==', '='})[#data % 3 + 1])
end

-- decoding
function module:dec(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^' .. b .. '=]', '')
	return (data:gsub(
		'.',
		function(x)
			if (x == '=') then
				return ''
			end
			local r, f = '', (b:find(x) - 1)
			for i = 6, 1, -1 do
				r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
			end
			return r
		end
	):gsub(
		'%d%d%d?%d?%d?%d?%d?%d?',
		function(x)
			if (#x ~= 8) then
				return ''
			end
			local c = 0
			for i = 1, 8 do
				c = c + (x:sub(i, i) == '1' and 2 ^ (7 - i) or 0)
			end
			return string.char(c)
		end
	))
end
