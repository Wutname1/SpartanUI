local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Component_BarHandler')
module.DisplayName = 'Bar Handler'
module.description = 'CORE: Handles the SpartanUI Bartender4 intergration'
module.Core = true
module.BarSystems = {}
module.BarPosition = {
	BT4 = {
		default = {
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
	}
}
module.BarScale = {
	BT4 = {
		default = {
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
			['BT4BarMicroMenu'] = 0.6
		}
	}
}

------------------------------------------------------------

function module:AddBarSystem(name, OnInitialize, OnEnable, OnDisable, Unlocker, RefreshConfig)
	module.BarSystems[name] = {
		active = false,
		Initialize = OnInitialize,
		enable = OnEnable,
		disable = OnDisable,
		move = Unlocker,
		refresh = RefreshConfig
	}
end

-- Hard code this for now.
function module:OnInitialize()
	local defaults = {
		profile = {
			BarSystem = 'Bartender4',
			custom = {
				scale = {
					BT4 = {}
				}
			}
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('BarHandler', defaults)
	module.DB = module.Database.profile
	if not module.BarSystems[module.DB.BarSystem] then
		module.DB.BarSystem = 'Bartender4'
	end

	-- Do Setup
	module.BarSystems[module.DB.BarSystem]:Initialize()
end

function module:OnEnable()
	module.BarSystems[module.DB.BarSystem]:enable()
end

function module:Refresh()
	module.BarSystems[module.DB.BarSystem]:refresh()
end

function module:MoveIt()
	if module.BarSystems[module.DB.BarSystem].move then
		module.BarSystems[module.DB.BarSystem]:move()
	end
end
