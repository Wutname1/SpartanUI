local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Component_BarHandler')
module.BarSystems = {}
module.BarPosition = {
	BT4 = {
		default = {
			['BT4Bar1'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-358,75',
			['BT4Bar2'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-358,24',
			['BT4Bar3'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,364,75',
			['BT4Bar4'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,364,24',
			['BT4Bar5'] = 'BOTTOMRIGHT,SUI_ActionBarAnchor,BOTTOMLEFT,30,0',
			['BT4Bar6'] = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOMRIGHT,-30,0',
			['BT4Bar7'] = '',
			['BT4Bar8'] = '',
			['BT4Bar9'] = '',
			['BT4Bar10'] = '',
			['BT4BarBagBar'] = 'TOP,SUI_ActionBarAnchor,TOP,503,2',
			['BT4BarExtraActionBar'] = 'TOP,SUI_ActionBarAnchor,TOP,3,36',
			['BT4BarStanceBar'] = 'TOP,SUI_ActionBarAnchor,TOP,-115,2',
			['BT4BarPetBar'] = 'TOP,SUI_ActionBarAnchor,TOP,-32,240',
			['BT4BarMicroMenu'] = 'TOP,SUI_ActionBarAnchor,TOP,114,4'
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
	local plate = CreateFrame('Frame', 'SUI_ActionBarAnchor', SpartanUI)
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetPoint('BOTTOM')
	plate:SetSize(1000, 140)

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
