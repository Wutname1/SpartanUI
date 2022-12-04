---@class SUI
local SUI = SUI
local module = SUI:NewModule('Module_MiniTom') ---@type SUI.Module
module.DisplayName = 'MiniTom'
module.description = 'Enables /way command to set a waypoint on your map'

---@class MiniTomDB
local DBDefaults = {}

local function Options()
	---@type AceConfigOptionsTable
	local OptTable = {
		name = 'MiniTom',
		type = 'group',
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, value)
			module.DB[info[#info]] = value
		end,
		args = {}
	}

	SUI.Options:AddOptions(OptTable, 'MiniTom', nil)
end

function module:OnInitialize()
	module.Database = SUI.SpartanUIDB:RegisterNamespace('MiniTom', {profile = DBDefaults})
	---@type MiniTomDB
	module.DB = module.Database.profile
	if SUI:IsAddonEnabled('TomTom') then
		module.override = true
	end
end

function module:OnEnable()
	Options()
	if SUI:IsModuleDisabled(module) then
		return
	end

	function SetWaypoint(args)
		local x, y = strsplit(' ', args, 2)

		if (x == nil or x == '' or type(tonumber(x)) ~= 'number' or y == nil or y == '' or type(tonumber(y)) ~= 'number') then
			return
		end

		local mapID = C_Map.GetBestMapForUnit('player')
		if C_Map.CanSetUserWaypointOnMap(mapID) then
			local mapPoint = UiMapPoint.CreateFromCoordinates(mapID, tonumber(x) / 100, tonumber(y) / 100, 0)
			if mapPoint then
				C_Map.SetUserWaypoint(mapPoint)
				C_SuperTrack.SetSuperTrackedUserWaypoint(true)
				SUI:Print('Waypoint set')
			end
		else
			SUI:Print('Cannot set waypoint on this map')
		end
	end

	SlashCmdList.MiniTom = SetWaypoint
	SLASH_MiniTom1 = '/way'
end

function module:OnDisable()
end
