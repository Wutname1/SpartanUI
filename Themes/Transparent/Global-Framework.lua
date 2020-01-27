local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_Transparent')
----------------------------------------------------------------------------------------------------
local frame = SUI_Art_Transparent

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
		if (SUI.DB.scale ~= SUI:round(SUI_Art_Transparent:GetScale())) then
			frame:SetScale(SUI.DB.scale)
		end
		if SUI.DB.scale <= .75 then
			SUI_Art_Transparent_Base3:SetPoint('BOTTOMLEFT', SpartanUI, 'BOTTOMLEFT')
			SUI_Art_Transparent_Base5:SetPoint('BOTTOMRIGHT', SpartanUI, 'BOTTOMRIGHT')
		else
			SUI_Art_Transparent_Base3:ClearAllPoints()
			SUI_Art_Transparent_Base5:ClearAllPoints()
			SUI_Art_Transparent_Base3:SetPoint('RIGHT', SUI_Art_Transparent_Base2, 'LEFT')
			SUI_Art_Transparent_Base5:SetPoint('LEFT', SUI_Art_Transparent_Base4, 'RIGHT')
		end
		local StatusBars = SUI:GetModule('Artwork_StatusBars')
		for _, key in ipairs(module.StatusBarSettings.bars) do
			StatusBars.bars[key]:SetScale(SUI.DB.scale)
		end

		CurScale = SUI.DB.scale
	end
end

function module:updateAlpha() -- scales SpartanUI based on setting or screen size
	if SUI.DB.alpha then
		SUI_Art_Transparent_Base1:SetAlpha(SUI.DB.alpha)
		SUI_Art_Transparent_Base2:SetAlpha(SUI.DB.alpha)
		SUI_Art_Transparent_Base3:SetAlpha(SUI.DB.alpha)
		SUI_Art_Transparent_Base4:SetAlpha(SUI.DB.alpha)
		SUI_Art_Transparent_Base5:SetAlpha(SUI.DB.alpha)
	end
end

----------------------------------------------------------------------------------------------------

function module:InitFramework()
	do -- default interface modifications
		SUI_FramesAnchor:SetFrameStrata('BACKGROUND')
		SUI_FramesAnchor:SetFrameLevel(1)
		SUI_FramesAnchor:ClearAllPoints()
		SUI_FramesAnchor:SetPoint('BOTTOMLEFT', 'SUI_Art_Transparent', 'TOPLEFT', 0, 0)
		SUI_FramesAnchor:SetPoint('TOPRIGHT', 'SUI_Art_Transparent', 'BOTTOMRIGHT', 0, 155)

		FramerateText:ClearAllPoints()
		FramerateText:SetPoint('BOTTOM', 'SUI_Art_Transparent_Base1', 'TOP', 0, 0)

		MainMenuBar:Hide()

		hooksecurefunc(
			'UpdateContainerFrameAnchors',
			function()
				-- fix bag offsets
				local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
				local screenWidth = GetScreenWidth()
				local containerScale = 1
				local leftLimit = 0
				if (BankFrame:IsShown()) then
					leftLimit = BankFrame:GetRight() - 25
				end
				while (containerScale > CONTAINER_SCALE) do
					screenHeight = GetScreenHeight() / containerScale
					-- Adjust the start anchor for bags depending on the multibars
					xOffset = 1 / containerScale
					yOffset = 155
					-- freeScreenHeight determines when to start a new column of bags
					freeScreenHeight = screenHeight - yOffset
					leftMostPoint = screenWidth - xOffset
					column = 1
					local frameHeight
					for _, frameName in ipairs(ContainerFrame1.bags) do
						frameHeight = getglobal(frameName):GetHeight()
						if (freeScreenHeight < frameHeight) then
							-- Start a new column
							column = column + 1
							leftMostPoint = screenWidth - (column * CONTAINER_WIDTH * containerScale) - xOffset
							freeScreenHeight = screenHeight - yOffset
						end
						freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
					end
					if (leftMostPoint < leftLimit) then
						containerScale = containerScale - 0.01
					else
						break
					end
				end
				if (containerScale < CONTAINER_SCALE) then
					containerScale = CONTAINER_SCALE
				end
				screenHeight = GetScreenHeight() / containerScale
				-- Adjust the start anchor for bags depending on the multibars
				xOffset = 1 / containerScale
				yOffset = 154
				-- freeScreenHeight determines when to start a new column of bags
				freeScreenHeight = screenHeight - yOffset
				column = 0
				for index, frameName in ipairs(ContainerFrame1.bags) do
					frame = getglobal(frameName)
					frame:SetScale(containerScale)
					if (index == 1) then
						-- First bag
						frame:SetPoint(
							'BOTTOMRIGHT',
							frame:GetParent(),
							'BOTTOMRIGHT',
							-xOffset,
							(yOffset + (SUI.DB.yoffset or 1)) * (SUI.DB.scale or 1)
						)
					elseif (freeScreenHeight < frame:GetHeight()) then
						-- Start a new column
						column = column + 1
						freeScreenHeight = screenHeight - yOffset
						frame:SetPoint('BOTTOMRIGHT', frame:GetParent(), 'BOTTOMRIGHT', -(column * CONTAINER_WIDTH) - xOffset, yOffset)
					else
						-- Anchor to the previous bag
						frame:SetPoint('BOTTOMRIGHT', ContainerFrame1.bags[index - 1], 'TOPRIGHT', 0, CONTAINER_SPACING)
					end
					freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
				end
			end
		)
	end
end

function module:TooltipLoc(self, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'SUI_Art_Transparent', 'TOPRIGHT', 0, 10)
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		RegisterStateDriver(SUI_Art_Transparent, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
		RegisterStateDriver(SpartanUI, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_Transparent, 'visibility')
		UnregisterStateDriver(SpartanUI, 'visibility')
	end
end

function module:SetColor()
	local r, b, g, a = unpack(SUI.DB.Styles.Transparent.Color.Art)
	for i = 1, 6 do
		if _G['SUI_Art_Transparent_Base' .. i] then
			_G['SUI_Art_Transparent_Base' .. i]:SetVertexColor(r, b, g, a)
		end
		if SUI.DB.ActionBars['bar' .. i].enable then
			_G['Transparent_Bar' .. i .. 'BG']:SetVertexColor(r, b, g, a)
		end
		if _G['Transparent_Popup' .. i .. 'BG'] then
			_G['Transparent_Popup' .. i .. 'BG']:SetVertexColor(r, b, g, a)
		end
	end
end

function module:EnableFramework()
	frame:SetFrameStrata('BACKGROUND')
	frame:SetFrameLevel(1)

	-- hooksecurefunc("AchievementAlertFrame_ShowAlert",function() -- achivement alerts
	-- if (AchievementAlertFrame1) then AchievementAlertFrame1:SetPoint("BOTTOM",SUI_Art_Transparent,"TOP",0,100); end
	-- end);
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

	module:SetupStatusBars()

	module:updateScale()
	module:updateAlpha()
	module:SetColor()
end
