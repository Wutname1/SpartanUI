local SUI, L = SUI, SUI.L
---@class SUI.Module.UICleanup
local module = SUI:GetModule('UICleanup')
----------------------------------------------------------------------------------------------------

local hiddenFrames = {}

function module:InitializeFrameHiding()
	-- Nothing special needed at init
end

local function HideFrame(frameName)
	local frame = _G[frameName]
	if frame then
		if not hiddenFrames[frameName] then
			hiddenFrames[frameName] = {
				wasShown = frame:IsShown(),
				originalShow = frame.Show,
			}
		end
		frame:Hide()
		frame.Show = function() end
	end
end

local function RestoreFrame(frameName)
	local frame = _G[frameName]
	if frame and hiddenFrames[frameName] then
		frame.Show = hiddenFrames[frameName].originalShow
		if hiddenFrames[frameName].wasShown then
			frame:Show()
		end
		hiddenFrames[frameName] = nil
	end
end

function module:ApplyFrameHidingSettings()
	local DB = module:GetDB()

	-- Zone Text
	if DB.hideZoneText then
		HideFrame('ZoneTextFrame')
		HideFrame('SubZoneTextFrame')
	else
		RestoreFrame('ZoneTextFrame')
		RestoreFrame('SubZoneTextFrame')
	end

	-- Alert Frames (achievement toasts, loot toasts, etc.)
	if DB.hideAlerts and AlertFrame then
		HideFrame('AlertFrame')
	else
		RestoreFrame('AlertFrame')
	end

	-- Boss Banner
	if DB.hideBossBanner and BossBanner then
		HideFrame('BossBanner')
	else
		RestoreFrame('BossBanner')
	end

	-- Event Toasts (level up, pet battle rewards, etc.)
	if DB.hideEventToasts and EventToastManagerFrame then
		HideFrame('EventToastManagerFrame')
	else
		RestoreFrame('EventToastManagerFrame')
	end
end

function module:RestoreFrameHiding()
	RestoreFrame('ZoneTextFrame')
	RestoreFrame('SubZoneTextFrame')
	RestoreFrame('AlertFrame')
	RestoreFrame('BossBanner')
	RestoreFrame('EventToastManagerFrame')
end
