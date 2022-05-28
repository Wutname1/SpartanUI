local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.AssistantIndicator = frame:CreateTexture(nil, 'BORDER')
end

UF.Elements:Register('AssistantIndicator', Build)
