local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB) end

---@param frame table
---@param DB? table
local function Update(frame, DB)
	local element = frame.AuraWatch
	local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
---@param DB? table
local function Options(unitName, OptionSet, DB)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.AuraWatch[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.AuraWatch[option] = val
		--Update the screen
		UF.Unit:Get(unitName):ElementUpdate('AuraWatch')
	end
	--local DB = UF.CurrentSettings[unitName].elements.AuraWatch
end

local Settings = {
	config = {
		NoBulkUpdate = false,
	},
}

UF.Elements:Register('AuraWatch', Build, Update, Options, Settings)
