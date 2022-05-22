local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.LeaderIndicator = frame:CreateTexture(nil, 'BORDER')
	frame.LeaderIndicator.SingleSize = true
	frame.LeaderIndicator:Hide()
end

UF.Elements:Register('LeaderIndicator', Build)
