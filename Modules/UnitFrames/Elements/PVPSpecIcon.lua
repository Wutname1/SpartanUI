local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local element = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame.raised)

	frame.PVPSpecIcon = element
end

---@param frame table
---@param DB? table
local function Update(frame, DB)
	local element = frame.PVPSpecIcon
	local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
---@param DB? table
local function Options(unitName, OptionSet, DB)
end

---@type SUI.UF.Elements.Settings
local Settings = {
	position = {
		anchor = 'RIGHT'
	},
	config = {
		NoBulkUpdate = false
	}
}

UF.Elements:Register('PVPSpecIcon', Build, Update, Options, Settings)
