local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_Transparent')
----------------------------------------------------------------------------------------------------

local plate

function module:SetupProfile()
	Artwork_Core:SetupProfile()
end

function module:CreateProfile()
	Artwork_Core:CreateProfile()
end

function module:InitActionBars()
	--if (Bartender4.db:GetCurrentProfile() == SUI.DB.Styles.Transparent.BartenderProfile or not Artwork_Core:BartenderProfileCheck(SUI.DB.Styles.Transparent.BartenderProfile,true)) then
	Artwork_Core:ActionBarPlates('Transparent_ActionBarPlate')
	--end

	do -- create bar anchor
		plate = CreateFrame('Frame', 'Transparent_ActionBarPlate', Transparent_SpartanUI, 'Transparent_ActionBarsTemplate')
		plate:SetFrameStrata('BACKGROUND')
		plate:SetFrameLevel(1)
		plate:SetPoint('BOTTOM')
	end
end

function module:EnableActionBars()
	do -- modify strata / levels of backdrops
		for i = 1, 6 do
			_G['Transparent_Bar' .. i]:SetFrameStrata('BACKGROUND')
			_G['Transparent_Bar' .. i]:SetFrameLevel(3)
		end
		for i = 1, 2 do
			_G['Transparent_Popup' .. i]:SetFrameStrata('BACKGROUND')
			_G['Transparent_Popup' .. i]:SetFrameLevel(3)
		end
	end

	-- Do what Bartender isn't - Make the Bag buttons the same size
	do -- modify CharacterBag(0-3) Scale
		for i = 1, 4 do
			_G['CharacterBag' .. (i - 1) .. 'Slot']:SetScale(1.25)
		end
	end
end
