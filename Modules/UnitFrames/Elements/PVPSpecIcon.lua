local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local element = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame.raised)

	frame.PVPSpecIcon = element
end

---@type SUI.UF.Elements.Settings
local Settings = {
	position = {
		anchor = 'RIGHT',
	},
	config = {
		NoBulkUpdate = false,
	},
}

UF.Elements:Register('PVPSpecIcon', Build, _, _, Settings)
