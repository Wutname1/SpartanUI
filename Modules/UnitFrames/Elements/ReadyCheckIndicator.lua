local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.ReadyCheckIndicator = frame:CreateTexture(nil, 'OVERLAY')
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.ReadyCheckIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.ReadyCheckIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('ReadyCheckIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.ReadyCheckIndicator
end

UF.Elements:Register('ReadyCheckIndicator', Build, nil, Options)