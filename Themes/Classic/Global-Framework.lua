local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Classic')
local UnregisterStateDriver = _G.UnregisterStateDriver
----------------------------------------------------------------------------------------------------
local anchor, frame = SUI_AnchorFrame, SpartanUI

local round = function(num) -- rounds a number to 2 decimal places
	if num then
		return floor((num * 10 ^ 2) + 0.5) / (10 ^ 2)
	end
end

function module:updateColor()
end

function module:updateScale() -- scales SpartanUI based on setting or screen size
	if (not SUI.DB.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local Resolution = ''
		if select(4, GetBuildInfo()) >= 70000 then
			Resolution = GetCVar('gxWindowedResolution')
		else
			Resolution = GetCVar('gxResolution')
		end

		local width, height = string.match(Resolution, '(%d+).-(%d+)')
		if (tonumber(width) / tonumber(height) > 4 / 3) then
			SUI.DB.scale = 0.92
		else
			SUI.DB.scale = 0.78
		end
	end
	if SUI.DB.scale ~= CurScale then
		if (SUI.DB.scale ~= round(SpartanUI:GetScale())) then
			frame:SetScale(SUI.DB.scale)
		end
		if SUI.DB.scale <= .75 then
			SUI_Art_Classic_Base3:SetPoint('BOTTOMLEFT', SUI_AnchorFrame, 'TOPLEFT')
			SUI_Art_Classic_Base5:SetPoint('BOTTOMRIGHT', SUI_AnchorFrame, 'TOPRIGHT')
		else
			SUI_Art_Classic_Base3:ClearAllPoints()
			SUI_Art_Classic_Base5:ClearAllPoints()
			SUI_Art_Classic_Base3:SetPoint('RIGHT', SUI_Art_Classic_Base2, 'LEFT')
			SUI_Art_Classic_Base5:SetPoint('LEFT', SUI_Art_Classic_Base4, 'RIGHT')
		end
		CurScale = SUI.DB.scale
	end
end

function module:updateSpartanAlpha() -- scales SpartanUI based on setting or screen size
	if SUI.DB.alpha then
		SUI_Art_Classic_Base1:SetAlpha(SUI.DB.alpha)
		SUI_Art_Classic_Base2:SetAlpha(SUI.DB.alpha)
		SUI_Art_Classic_Base3:SetAlpha(SUI.DB.alpha)
		SUI_Art_Classic_Base4:SetAlpha(SUI.DB.alpha)
		SUI_Art_Classic_Base5:SetAlpha(SUI.DB.alpha)
		SUI_Popup1Mask:SetAlpha(SUI.DB.alpha)
		SUI_Popup2Mask:SetAlpha(SUI.DB.alpha)
	end
end

function module:updateSpartanXOffset() -- handles SpartanUI offset based on setting or fubar / titan
	if not SUI.DB.Offset.Horizontal then
		return 0
	end
	local offset = SUI.DB.Offset.Horizontal
	if round(offset) <= -300 then
		SUI_Art_Classic_Base5:ClearAllPoints()
		SUI_Art_Classic_Base5:SetPoint('LEFT', SUI_Art_Classic_Base4, 'RIGHT')
		SUI_Art_Classic_Base5:SetPoint('BOTTOMRIGHT', SUI_AnchorFrame, 'TOPRIGHT')
	elseif round(offset) >= 300 then
		SUI_Art_Classic_Base3:ClearAllPoints()
		SUI_Art_Classic_Base3:SetPoint('RIGHT', SUI_Art_Classic_Base2, 'LEFT')
		SUI_Art_Classic_Base3:SetPoint('BOTTOMLEFT', SUI_AnchorFrame, 'TOPLEFT')
	end
	SUI_Art_Classic:SetPoint('LEFT', SUI_AnchorFrame, 'LEFT', offset, 0)

	SUI_FramesAnchor:ClearAllPoints()
	SUI_FramesAnchor:SetPoint('BOTTOMLEFT', SUI_AnchorFrame, 'BOTTOMLEFT', (offset / 2), 0)
	SUI_FramesAnchor:SetPoint('TOPRIGHT', SUI_AnchorFrame, 'TOPRIGHT', (offset / 2), 153)

	if (round(offset) ~= round(anchor:GetWidth())) then
		anchor:SetWidth(offset)
	end
	SUI.DB.Offset.Horizontal = offset
end

----------------------------------------------------------------------------------------------------

function module:SetColor()
	local r, b, g, a
	if not SUI.DB.Styles.Classic.Color.Art then
		r, b, g, a = 1, 1, 1, 1
	else
		r, b, g, a = unpack(SUI.DB.Styles.Classic.Color.Art)
	end

	for i = 1, 6 do
		if _G['SUI_Art_Classic_Base' .. i] then
			_G['SUI_Art_Classic_Base' .. i]:SetVertexColor(r, b, g, a)
		end
		if _G['Bar' .. i .. 'BG'] then
			_G['Bar' .. i .. 'BG']:SetVertexColor(r, b, g, a)
		end
		if _G['Popup' .. i .. 'BG'] then
			_G['Popup' .. i .. 'BG']:SetVertexColor(r, b, g, a)
		end
		if _G['SUI_Popup' .. i .. 'MaskBG'] then
			_G['SUI_Popup' .. i .. 'MaskBG']:SetVertexColor(r, b, g, a)
		end
	end

	if _G['SUI_StatusBar_Left'] then
		_G['SUI_StatusBar_Left']:SetVertexColor(r, b, g, a)
	end
	if _G['SUI_StatusBar_Right'] then
		_G['SUI_StatusBar_Right']:SetVertexColor(r, b, g, a)
	end
end

function module:InitFramework()
	do -- default interface modifications
		SUI_FramesAnchor:SetFrameStrata('BACKGROUND')
		SUI_FramesAnchor:SetFrameLevel(1)
		SUI_FramesAnchor:ClearAllPoints()
		SUI_FramesAnchor:SetPoint('BOTTOMLEFT', 'SUI_AnchorFrame', 'TOPLEFT', 0, 0)
		SUI_FramesAnchor:SetPoint('TOPRIGHT', 'SUI_AnchorFrame', 'TOPRIGHT', 0, 153)

		FramerateText:ClearAllPoints()
		FramerateText:SetPoint('BOTTOM', 'SUI_Art_Classic_Base1', 'TOP', 0, 0)

		MainMenuBar:Hide()
		hooksecurefunc(
			SUI_Art_Classic,
			'Hide',
			function()
				Artwork_Core:updateViewport()
			end
		)
		hooksecurefunc(
			SUI_Art_Classic,
			'Show',
			function()
				Artwork_Core:updateViewport()
			end
		)
	end
end

function module:TooltipLoc(self, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'SUI_Art_Classic', 'TOPRIGHT', 0, 10)
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		RegisterStateDriver(SUI_Art_Classic, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if not SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_Classic, 'visibility')
	end
end

function module:EnableFramework()
	anchor:SetFrameStrata('BACKGROUND')
	anchor:SetFrameLevel(1)
	frame:SetFrameStrata('BACKGROUND')
	frame:SetFrameLevel(1)

	hooksecurefunc(
		'UIParent_ManageFramePositions',
		function()
			if TutorialFrameAlertButton then
				TutorialFrameAlertButton:SetParent(Minimap)
				TutorialFrameAlertButton:ClearAllPoints()
				TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
			end
			CastingBarFrame:ClearAllPoints()
			CastingBarFrame:SetPoint('BOTTOM', frame, 'TOP', 0, 90)
		end
	)

	module:SetupVehicleUI()
	module:updateScale()
	module:updateSpartanXOffset()
	module:updateSpartanAlpha()
	if SUI.DB.Styles.Classic.Color.Art then
		module:SetColor()
	end
end
