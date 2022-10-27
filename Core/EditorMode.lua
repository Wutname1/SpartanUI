local SUI = SUI
local module = SUI:NewModule('EditorMode')

local _G = _G
local tremove = tremove

local CheckTargetFrame = function()
	return SUI:IsModuleEnabled('Component_UnitFrames')
end
local CheckCastFrame = function()
	return SUI:IsModuleEnabled('Component_UnitFrames')
end
local CheckArenaFrame = function()
	return SUI:IsModuleEnabled('Component_UnitFrames')
end
local CheckPartyFrame = function()
	return SUI:IsModuleEnabled('Component_UnitFrames')
end
local CheckFocusFrame = function()
	return SUI:IsModuleEnabled('Component_UnitFrames')
end
local CheckRaidFrame = function()
	return SUI:IsModuleEnabled('Component_UnitFrames')
end
local CheckBossFrame = function()
	return SUI:IsModuleEnabled('Component_UnitFrames')
end

local IgnoreFrames = {
	MinimapCluster = function()
		return SUI:IsModuleEnabled('Component_Minimap')
	end,
	PartyFrame = CheckPartyFrame,
	FocusFrame = CheckFocusFrame,
	TargetFrame = CheckTargetFrame,
	PlayerCastingBarFrame = CheckCastFrame,
	ArenaEnemyFramesContainer = CheckArenaFrame,
	CompactRaidFrameContainer = CheckRaidFrame,
	BossTargetFrameContainer = CheckBossFrame,
	PlayerFrame = function()
		return SUI:IsModuleEnabled('Component_UnitFrames')
	end
}

function module:OnInitialize()
	local editMode = _G.EditModeManagerFrame

	-- remove the initial registers
	local registered = editMode.registeredSystemFrames
	for i = #registered, 1, -1 do
		local name = registered[i]:GetName()
		local ignore = IgnoreFrames[name]

		if ignore and ignore() then
			tremove(editMode.registeredSystemFrames, i)
		end
	end

	-- account settings will be tainted
	local mixin = editMode.AccountSettings
	local emptyFunc = function()
	end
	if CheckCastFrame() then
		mixin.RefreshCastBar = emptyFunc
	end
	if CheckBossFrame() then
		mixin.RefreshBossFrames = emptyFunc
	end
	if CheckRaidFrame() then
		mixin.RefreshRaidFrames = emptyFunc
	end
	if CheckArenaFrame() then
		mixin.RefreshArenaFrames = emptyFunc
	end
	if CheckPartyFrame() then
		mixin.RefreshPartyFrames = emptyFunc
	end
	if CheckTargetFrame() and CheckFocusFrame() then
		mixin.RefreshTargetAndFocus = emptyFunc
	end
end
