local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Artwork_ActionBars')
module.bars = {}
module.DB = SUI.DBMod.ActionBars
local StyleSettings


function module:Initialize(Settings)
	StyleSettings = Settings

	--Create Bars
	module:factory()
	module:BuildOptions()
end

function module:factory()
end

function module:BuildOptions()
	-- Build Holder
	SUI.opt.args['Artwork'].args['ActionBars'] = {
		name = L['Action Bars'],
		type = 'group',
		args = {}
	}

end
