-- :)

BetterBlizzFramesDB = BetterBlizzFramesDB or {}
BBF = BBF or {}
BBA = BBA or {}

local function CreateOverlayFrame(frame)
    frame.bbfOverlayFrame = CreateFrame("Frame", nil, frame)
    frame.bbfOverlayFrame:SetFrameStrata("DIALOG")
    frame.bbfOverlayFrame:SetSize(frame:GetSize())
    frame.bbfOverlayFrame:SetAllPoints(frame)

    hooksecurefunc(frame, "SetFrameStrata", function()
        frame.bbfOverlayFrame:SetFrameStrata("DIALOG")
    end)
end

CreateOverlayFrame(PlayerFrame)
CreateOverlayFrame(TargetFrame)
if FocusFrame then
    CreateOverlayFrame(FocusFrame)
end