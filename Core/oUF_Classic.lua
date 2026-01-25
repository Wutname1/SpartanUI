---@diagnostic disable: missing-parameter
-- ============================================================================
-- oUF Classic-Specific Utilities
-- ============================================================================
-- This file contains Classic-only helper functions
-- All oUF element registrations are in Core/oUF_Plugins/ (loaded via TOC)
-- ============================================================================

-- Classic health calculation with RealMobHealth integration
local function getCurrentUnitHP(unitid)
	local aCurrentHP = 0
	local aMaxHP = 0
	if RealMobHealth and RealMobHealth.UnitHasHealthData(unitid) and RealMobHealth.GetUnitHealth then
		aCurrentHP, aMaxHP = RealMobHealth.GetUnitHealth(unitid)
	else
		aCurrentHP = UnitHealth(unitid) or 0
	end
	return aCurrentHP
end

local function getMaxUnitHP(unitid)
	local aCurrentHP = 0
	local aMaxHP = 0
	if RealMobHealth and RealMobHealth.UnitHasHealthData(unitid) and RealMobHealth.GetUnitHealth then
		aCurrentHP, aMaxHP = RealMobHealth.GetUnitHealth(unitid)
	else
		aMaxHP = UnitHealthMax(unitid) or 1
	end
	return aMaxHP
end

-- Export functions for use by tags
SUI.getCurrentUnitHP = getCurrentUnitHP
SUI.getMaxUnitHP = getMaxUnitHP
