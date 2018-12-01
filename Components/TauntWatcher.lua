local SUI = SUI
local module = SUI:NewModule('Component_TauntWatcher')
local L = SUI.L
module.DisplayName = 'Taunt watcher'
----------------------------------------------------------------------------------------------------


function module:OnInitialize()
	local Defaults = {
		FirstLaunch = true,
		debug = false
	}
	if not SUI.DB.TauntWatcher then
		SUI.DB.EnabledComponents.TauntWatcher = false
		SUI.DB.TauntWatcher = Defaults
	else
		SUI.DB.TauntWatcher = SUI:MergeData(SUI.DB.CombatLog, Defaults, false)
	end
end

function module:OnEnable()

end