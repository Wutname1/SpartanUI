local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Component_BarHandler')
module.BarSystems = {}
module.BarPosition = {
	BT4 = {
		default = {
			['BT4Bar1'] = 'CENTER,SUI_ActionBarPlate,CENTER,-510,36',
			['BT4Bar2'] = 'CENTER,SUI_ActionBarPlate,CENTER,-510,-8',
			['BT4Bar3'] = 'CENTER,SUI_ActionBarPlate,CENTER,108,36',
			['BT4Bar4'] = 'CENTER,SUI_ActionBarPlate,CENTER,108,-8',
			['BT4Bar5'] = 'LEFT,SUI_ActionBarPlate,LEFT,-135,36',
			['BT4Bar6'] = 'RIGHT,SUI_ActionBarPlate,RIGHT,3,36',
			['BT4Bar7'] = '',
			['BT4Bar8'] = '',
			['BT4Bar9'] = '',
			['BT4Bar10'] = '',
			['BT4BarBagBar'] = 'TOP,SUI_ActionBarPlate,TOP,503,2',
			['BT4BarExtraActionBar'] = 'TOP,SUI_ActionBarPlate,TOP,3,36',
			['BT4BarStanceBar'] = 'TOP,SUI_ActionBarPlate,TOP,-115,2',
			['BT4BarPetBar'] = 'TOP,SUI_ActionBarPlate,TOP,-32,240',
			['BT4BarMicroMenu'] = 'TOP,SUI_ActionBarPlate,TOP,114,4'
		}
	}
}

------------------------------------------------------------

function module:AddBarSystem(name, SetupCallBack, OnEnable, OnDisable, Unlocker, RefreshConfig)
	module.BarSystems[name] = {
		active = false,
		setup = SetupCallBack,
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
			BarSystem = 'Bartender4'
		}
	}
	module.database = SUI.SpartanUIDB:RegisterNamespace('BarHandler', defaults)
	module.DB = module.database.profile
	if not module.BarSystems[module.DB.BarSystem] then
		module.DB.BarSystem = 'Bartender4'
	end

	-- Create Plate
	local plate = CreateFrame('Frame', 'SUI_ActionBarPlate', SpartanUI, 'SUI_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetPoint('BOTTOM')

	-- Do Setup
	module.BarSystems[module.DB.BarSystem]:setup()
end

function module:OnEnable()
	module.BarSystems[module.DB.BarSystem]:enable()
end

function module:Refresh()
end

function module:MoveIt()
	if module.BarSystems[module.DB.BarSystem].move then
		module.BarSystems[module.DB.BarSystem]:move()
	end
end
