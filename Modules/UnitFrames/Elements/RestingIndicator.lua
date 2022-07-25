local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RestingIndicator = frame:CreateTexture(nil, 'ARTWORK')
end

---@type ElementSettings
local Settings = {
	size = 20
}

UF.Elements:Register('RestingIndicator', Build, nil, nil, Settings)
