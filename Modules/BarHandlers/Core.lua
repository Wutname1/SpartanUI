local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Component_BarHandler')
module.BarSystems = {}
------------------------------------------------------------

function module:AddBarSystem(name, SetupCallBack, OnEnable, OnDisable)
    module.BarSystems[name] = {
        active = false,
        setup = SetupCallBack,
        enable = OnEnable,
        disable = OnDisable
    }
end

-- Hard code this for now.
function module:OnInitialize()
    module.BarSystems.Bartender4:setup()
end

function module:OnEnable()
    module.BarSystems.Bartender4:enable()
end