-- this is a functional example of how to use the library,
-- enabling movement of the experience/reputation tracking bars

-- StatusTrackingDB should be a global savedvariable

local function onPositionChanged(frame, layoutName, point, x, y)
	StatusTrackingDB[layoutName].point = point
	StatusTrackingDB[layoutName].x = x
	StatusTrackingDB[layoutName].y = y
end

local defaultPosition = {
	point = 'BOTTOM',
	x = 0,
	y = 0,
}

local LEM = LibStub('LibEditMode')
LEM:AddFrame(StatusTrackingBarManager, onPositionChanged, defaultPosition)

LEM:RegisterCallback('layout', function(layoutName)
	if not StatusTrackingDB then
		StatusTrackingDB = {}
	end
	if not StatusTrackingDB[layoutName] then
		StatusTrackingDB[layoutName] = CopyTable(defaultPosition)
	end

	StatusTrackingBarManager:ClearAllPoints()
	StatusTrackingBarManager:SetPoint(StatusTrackingDB[layoutName].point, StatusTrackingDB[layoutName].x, StatusTrackingDB[layoutName].y)
end)
