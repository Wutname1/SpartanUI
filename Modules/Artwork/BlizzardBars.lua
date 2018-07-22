local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Artwork_BlizzardBars')
module.bars = {}
module.DB = SUI.DBMod.BlizzardBars
local StyleSettings


function module:Initialize(Settings)
	StyleSettings = Settings

	--Create Bars
	module:factory()
	module:BuildOptions()
end

function module:SetupProfile(Settings)
end

function module:ResetMovedBars()
end

function module:SetupMovedBars()
end

function module:ResetDB()
end

function module:UseBlizzardVehicleUI(shouldUse)
end

function module:factory()
end

function module:CreateProfile(ProfileOverride)
end

function module:BuildOptions()
	-- Build Holder
	-- SUI.opt.args['Artwork'].args['ActionBars'] = {
	-- 	name = L['Action Bars'],
	-- 	type = 'group',
	-- 	args = {}
	-- }

end
