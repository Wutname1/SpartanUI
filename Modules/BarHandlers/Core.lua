local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Handler_BarSystems')
local DB = nil
module.DisplayName = 'Bar Handler'
module.description = 'CORE: Handles the SpartanUI Bartender4 intergration'
module.Core = true
module.Registry = {}
module.BarPosition = {
	BT4 = {
		default = {
			['BT4Bar1'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-451,100',
			['BT4Bar2'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-451,33',
			['BT4Bar3'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,451,100',
			['BT4Bar4'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,451,33',
			['BT4Bar5'] = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOMLEFT,-15,0',
			['BT4Bar6'] = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOMRIGHT,15,0',
			['BT4Bar7'] = '',
			['BT4Bar8'] = '',
			['BT4Bar9'] = '',
			['BT4Bar10'] = '',
			--
			['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,87',
			['BT4BarExtraActionBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,87',
			--
			['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-285,192',
			['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-661,191',
			--
			['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,340,191',
			['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,707,193',
			['BT4BarQueueStatus'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-107,132'
		}
	}
}
module.BarScale = {
	BT4 = {
		default = {
			['BT4Bar1'] = 0.62,
			['BT4Bar2'] = 0.62,
			['BT4Bar3'] = 0.62,
			['BT4Bar4'] = 0.62,
			['BT4Bar5'] = 0.62,
			['BT4Bar6'] = 0.62,
			['BT4Bar7'] = 0.62,
			['BT4Bar8'] = 0.62,
			['BT4Bar9'] = 0.62,
			['BT4Bar10'] = 0.62,
			['BT4BarBagBar'] = 0.6,
			['BT4BarZoneAbilityBar'] = 0.8,
			['BT4BarExtraActionBar'] = 0.8,
			['BT4BarStanceBar'] = 0.6,
			['BT4BarPetBar'] = 0.6,
			['MultiCastActionBarFrame'] = 0.6,
			['BT4BarMicroMenu'] = 0.7,
			['BT4BarQueueStatus'] = 0.58
		}
	}
}

if not SUI.IsRetail then
	module.BarPosition.BT4.default = {
		['BT4Bar1'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-364,78',
		['BT4Bar2'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-366,24',
		['BT4Bar3'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,364,78',
		['BT4Bar4'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,366,24',
		['BT4Bar5'] = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOMLEFT,-15,0',
		['BT4Bar6'] = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOMRIGHT,15,0',
		['BT4Bar7'] = '',
		['BT4Bar8'] = '',
		['BT4Bar9'] = '',
		['BT4Bar10'] = '',
		--
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,87',
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,87',
		--
		['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-285,192',
		['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-661,191',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,340,191',
		['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,707,193'
	}

	module.BarScale.BT4.default = {
		['BT4Bar1'] = 0.78,
		['BT4Bar2'] = 0.78,
		['BT4Bar3'] = 0.78,
		['BT4Bar4'] = 0.78,
		['BT4Bar5'] = 0.80,
		['BT4Bar6'] = 0.80,
		['BT4Bar7'] = 0.78,
		['BT4Bar8'] = 0.78,
		['BT4Bar9'] = 0.78,
		['BT4Bar10'] = 0.78,
		['BT4BarBagBar'] = 0.6,
		['BT4BarZoneAbilityBar'] = 0.8,
		['BT4BarExtraActionBar'] = 0.8,
		['BT4BarStanceBar'] = 0.6,
		['BT4BarPetBar'] = 0.6,
		['MultiCastActionBarFrame'] = 0.6,
		['BT4BarMicroMenu'] = 0.6
	}
end

------------------------------------------------------------

function module:AddBarSystem(name, OnInitialize, OnEnable, OnDisable, Unlocker, RefreshConfig)
	module.Registry[name] = {
		active = false,
		Initialize = OnInitialize,
		enable = OnEnable,
		disable = OnDisable,
		move = Unlocker,
		refresh = RefreshConfig
	}
end

local function Options()
	---@type AceConfigOptionsTable
	local OptTable = {
		name = 'Bar System',
		type = 'group',
		childGroups = 'tab',
		get = function(info)
			return DB[info[#info]]
		end,
		set = function(info, val)
			DB[info[#info]] = val
			SUI:reloadui()
		end,
		args = {
			ActiveSystem = {
				name = 'Active Bar System',
				type = 'select',
				order = 1,
				values = function()
					local t = {}
					for k, v in pairs(module.Registry) do
						t[k] = k
					end
					return t
				end,
				get = function()
					return DB.ActiveSystem
				end,
				set = function(_, val)
					DB.ActiveSystem = val
					SUI:reloadui()
				end
			}
		}
	}

	-- for name, settings in pairs(module.Registry) do
	-- 	OptTable.args.enabledState.args[name] = {
	-- 		name = name,
	-- 		type = 'toggle',
	-- 		order = 1
	-- 	}

	-- 	if settings.Config then
	-- 		local SettingsScreen = {
	-- 			name = name,
	-- 			type = 'group',
	-- 			args = {}
	-- 		}
	-- 		settings.Config(SettingsScreen)
	-- 		OptTable.args[name] = SettingsScreen
	-- 	end
	-- end

	SUI.Options:AddOptions(OptTable, 'Bar System', 'General')
end

-- Hard code this for now.
function module:OnInitialize()
	---@class SUI.BarHandler.DB
	local defaults = {
		ActiveSystem = 'Bartender4',
		custom = {
			scale = {
				BT4 = {}
			}
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('BarHandler', {profile = defaults})
	module.DB = module.Database.profile ---@type SUI.BarHandler.DB
	DB = module.DB

	if SUI.IsRetail and SUI:IsAddonDisabled('Bartender4') then
		DB.ActiveSystem = 'WoW'
	elseif SUI:IsAddonEnabled('Bartender4') and DB.ActiveSystem == 'WoW' then
		DB.ActiveSystem = 'Bartender4'
	end
	if not module.Registry[DB.ActiveSystem] then
		DB.ActiveSystem = 'Bartender4'
	end

	Options()

	-- Do Setup
	module.Registry[DB.ActiveSystem]:Initialize()
end

function module:OnEnable()
	module.Registry[DB.ActiveSystem]:enable()
end

function module:Refresh()
	module.Registry[DB.ActiveSystem]:refresh()
end

function module:MoveIt()
	if module.Registry[DB.ActiveSystem].move then
		module.Registry[DB.ActiveSystem]:move()
	end
end
