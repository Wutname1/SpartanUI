local UF = SUI.UF

---@param frame table
---@param DB? table
local function Build(frame, DB)
	local TargetIndicator = CreateFrame('Frame', 'BACKGROUND', frame)
	TargetIndicator.bg1 = TargetIndicator:CreateTexture(nil, 'BACKGROUND')
	TargetIndicator.bg2 = TargetIndicator:CreateTexture(nil, 'BACKGROUND')
	TargetIndicator.bg1:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\nameplates\\DoubleArrow')
	TargetIndicator.bg2:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\nameplates\\DoubleArrow')
	TargetIndicator.bg1:SetPoint('RIGHT', frame, 'LEFT')
	TargetIndicator.bg2:SetPoint('LEFT', frame, 'RIGHT')
	TargetIndicator.bg2:SetTexCoord(1, 0, 1, 0)
	TargetIndicator.bg1:SetSize(10, frame:GetHeight())
	TargetIndicator.bg2:SetSize(10, frame:GetHeight())

	TargetIndicator.bg1:Hide()
	TargetIndicator.bg2:Hide()
	frame.TargetIndicator = TargetIndicator
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.TargetIndicator
	local DB = settings or element.DB
	if UnitIsUnit(frame.unit, 'target') and DB.ShowTarget then
		-- the frame is the new target
		element.bg1:Show()
		element.bg2:Show()
	elseif element.bg1:IsShown() then
		element.bg1:Hide()
		element.bg2:Hide()
	end
end

local Settings = {
	config = {
		NoBulkUpdate = false,
	},
}

UF.Elements:Register('TargetIndicator', Build, Update, _, Settings)
