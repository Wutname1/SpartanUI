local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidTargetIndicator = frame:CreateTexture(nil, 'ARTWORK')
end

UF.Elements:Register('RaidTargetIndicator', Build)
