local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RestingIndicator = frame:CreateTexture(nil, 'ARTWORK')
	frame.RestingIndicator.SingleSize = true
end

UF.Elements:Register('RestingIndicator', Build)
