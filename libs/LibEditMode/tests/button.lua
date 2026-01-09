-- this is a functional example of how to use the library,
-- enabling movement of a custom button

-- ButtonDB should be a global savedvariable

local button = CreateFrame('Frame', 'TestButton', UIParent)
button:SetSize(50, 50)
local texture = button:CreateTexture()
texture:SetAllPoints()
texture:SetColorTexture(1, 0, 0)

local function onPositionChanged(frame, layoutName, point, x, y)
	ButtonDB[layoutName].point = point
	ButtonDB[layoutName].x = x
	ButtonDB[layoutName].y = y
end

local defaultPosition = {
	point = 'CENTER',
	x = 300,
	y = 0,
}

local LEM = LibStub('LibEditMode')
LEM:AddFrame(button, onPositionChanged, defaultPosition)

LEM:RegisterCallback('layout', function(layoutName)
	if not ButtonDB then
		ButtonDB = {}
	end
	if not ButtonDB[layoutName] then
		ButtonDB[layoutName] = CopyTable(defaultPosition)
	end

	button:ClearAllPoints()
	button:SetPoint(ButtonDB[layoutName].point, ButtonDB[layoutName].x, ButtonDB[layoutName].y)
end)

LEM:AddFrameSettings(button, {
	{
		name = 'Hide in combat',
		kind = LEM.SettingType.Checkbox,
		default = true,
		get = function(layoutName)
			return ButtonDB[layoutName].combat
		end,
		set = function(layoutName, value)
			ButtonDB[layoutName].combat = value
		end,
	}
})

LEM:AddSystemSettings(Enum.EditModeSystem.ObjectiveTracker, {
    {
        name = "Example Setting 1",
        kind = LEM.SettingType.Checkbox,
        default = 1,
        get = function(layoutName)
            return true
        end,
        set = function(layoutName, value)
        	-- do something
        end,
    },
    {
        name = "Example Setting 2",
        kind = LEM.SettingType.Checkbox,
        default = 1,
        get = function(layoutName)
            return true
        end,
        set = function(layoutName, value)
            -- do something
        end,
    },
})
