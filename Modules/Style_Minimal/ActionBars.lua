local SUI = SUI
local Artwork_Core = SUI:GetModule('Artwork_Core')
local module = SUI:GetModule('Style_Minimal')
----------------------------------------------------------------------------------------------------

local plate

function module:SetupProfile()
	Artwork_Core:SetupProfile()
end

function module:CreateProfile()
	Artwork_Core:CreateProfile()
end

function module:InitActionBars()
	do -- create Top bar anchor
		plate = CreateFrame('Frame', 'Minimal_TopBarPlate', Minimal_AnchorFrame, 'Minimal_ActionBarsTemplate')
		plate:SetFrameStrata('BACKGROUND')
		plate:SetFrameLevel(1)
		plate:SetPoint('TOP', Minimal_AnchorFrame, 'TOP')
	end
end

function module:EnableActionBars()
end
