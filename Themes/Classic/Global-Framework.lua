local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Artwork_Core')
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

function module:updateSpartanViewport() -- handles viewport offset based on settings
	if not InCombatLockdown() and SUI.DB.viewport and (SpartanUI_Base5:GetHeight() ~= 0) then
		WorldFrame:ClearAllPoints()
		WorldFrame:SetPoint(
			'TOPLEFT',
			UIParent,
			'TOPLEFT',
			SUI.DBMod.Artwork.Viewport.offset.left,
			SUI.DBMod.Artwork.Viewport.offset.top
		)
		if SpartanUI_Base5:IsVisible() then
			WorldFrame:SetPoint(
				'BOTTOMRIGHT',
				UIParent,
				'BOTTOMRIGHT',
				SUI.DBMod.Artwork.Viewport.offset.right,
				(SpartanUI_Base5:GetHeight() * SUI.DB.scale / SUI.DBMod.Artwork.Viewport.offset.bottom)
			)
		else
			WorldFrame:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', 0, 0)
		end
	end
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
		--module:updateMinimumScale();
		module:updateSpartanViewport()
		if (SUI.DB.scale ~= round(SpartanUI:GetScale())) then
			frame:SetScale(SUI.DB.scale)
		end
		if SUI.DB.scale <= .75 then
			SpartanUI_Base3:SetPoint('BOTTOMLEFT', SUI_AnchorFrame, 'TOPLEFT')
			SpartanUI_Base5:SetPoint('BOTTOMRIGHT', SUI_AnchorFrame, 'TOPRIGHT')
		else
			SpartanUI_Base3:ClearAllPoints()
			SpartanUI_Base5:ClearAllPoints()
			SpartanUI_Base3:SetPoint('RIGHT', SpartanUI_Base2, 'LEFT')
			SpartanUI_Base5:SetPoint('LEFT', SpartanUI_Base4, 'RIGHT')
		end
		local StatusBars = SUI:GetModule('Artwork_StatusBars')
		for _, key in ipairs(module.StatusBarSettings.bars) do
			StatusBars.bars[key]:SetScale(SUI.DB.scale)
		end
		CurScale = SUI.DB.scale
	end
end

function module:updateSpartanAlpha() -- scales SpartanUI based on setting or screen size
	if SUI.DB.alpha then
		SpartanUI_Base1:SetAlpha(SUI.DB.alpha)
		SpartanUI_Base2:SetAlpha(SUI.DB.alpha)
		SpartanUI_Base3:SetAlpha(SUI.DB.alpha)
		SpartanUI_Base4:SetAlpha(SUI.DB.alpha)
		SpartanUI_Base5:SetAlpha(SUI.DB.alpha)
		SUI_Popup1Mask:SetAlpha(SUI.DB.alpha)
		SUI_Popup2Mask:SetAlpha(SUI.DB.alpha)
	end
end

function module:updateSpartanOffset() -- handles SpartanUI offset based on setting or fubar / titan
	local fubar, ChocolateBar, titan, offset = 0, 0, 0

	if not SUI.DB.yoffsetAuto then
		offset = max(SUI.DB.yoffset, 1)
	else
		for i = 1, 4 do -- FuBar Offset
			if (_G['FuBarFrame' .. i] and _G['FuBarFrame' .. i]:IsVisible()) then
				local bar = _G['FuBarFrame' .. i]
				local point = bar:GetPoint(1)
				if point == 'BOTTOMLEFT' then
					fubar = fubar + bar:GetHeight()
				end
			end
		end
		for i = 1, 100 do -- Chocolate Bar Offset
			if (_G['ChocolateBar' .. i] and _G['ChocolateBar' .. i]:IsVisible()) then
				local bar = _G['ChocolateBar' .. i]
				local point = bar:GetPoint(1)
				--if point == "TOPLEFT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end--top bars
				if point == 'RIGHT' then
					ChocolateBar = ChocolateBar + bar:GetHeight()
				end
			-- bottom bars
			end
		end
		TitanBarOrder = {[1] = 'AuxBar2', [2] = 'AuxBar'} -- Bottom 2 Bar names
		for i = 1, 2 do -- Titan Bar Offset
			if (_G['Titan_Bar__Display_' .. TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i] .. '_Show')) then
				local PanelScale = TitanPanelGetVar('Scale') or 1
				local bar = _G['Titan_Bar__Display_' .. TitanBarOrder[i]]
				titan = titan + (PanelScale * bar:GetHeight())
			end
		end

		offset = max(fubar + titan + ChocolateBar, 1)
	end
	if (round(offset) ~= round(anchor:GetHeight())) then
		anchor:SetHeight(offset)
	end
	SUI.DB.yoffset = offset
end

function module:updateSpartanXOffset() -- handles SpartanUI offset based on setting or fubar / titan
	if not SUI.DB.xOffset then
		return 0
	end
	local offset = SUI.DB.xOffset
	if round(offset) <= -300 then
		SpartanUI_Base5:ClearAllPoints()
		SpartanUI_Base5:SetPoint('LEFT', SpartanUI_Base4, 'RIGHT')
		SpartanUI_Base5:SetPoint('BOTTOMRIGHT', SUI_AnchorFrame, 'TOPRIGHT')
	elseif round(offset) >= 300 then
		SpartanUI_Base3:ClearAllPoints()
		SpartanUI_Base3:SetPoint('RIGHT', SpartanUI_Base2, 'LEFT')
		SpartanUI_Base3:SetPoint('BOTTOMLEFT', SUI_AnchorFrame, 'TOPLEFT')
	end
	SpartanUI:SetPoint('LEFT', SUI_AnchorFrame, 'LEFT', offset, 0)

	SUI_FramesAnchor:ClearAllPoints()
	SUI_FramesAnchor:SetPoint('BOTTOMLEFT', SUI_AnchorFrame, 'BOTTOMLEFT', (offset / 2), 0)
	SUI_FramesAnchor:SetPoint('TOPRIGHT', SUI_AnchorFrame, 'TOPRIGHT', (offset / 2), 153)

	if (round(offset) ~= round(anchor:GetWidth())) then
		anchor:SetWidth(offset)
	end
	SUI.DB.xOffset = offset
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
		if _G['SpartanUI_Base' .. i] then
			_G['SpartanUI_Base' .. i]:SetVertexColor(r, b, g, a)
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
		SUI_FramesAnchor:SetParent(SpartanUI)
		SUI_FramesAnchor:ClearAllPoints()
		SUI_FramesAnchor:SetPoint('BOTTOMLEFT', 'SUI_AnchorFrame', 'TOPLEFT', 0, 0)
		SUI_FramesAnchor:SetPoint('TOPRIGHT', 'SUI_AnchorFrame', 'TOPRIGHT', 0, 153)

		Artwork_Core:MoveTalkingHeadUI()

		MainMenuBarVehicleLeaveButton:HookScript(
			'OnShow',
			function()
				MainMenuBarVehicleLeaveButton:ClearAllPoints()
				MainMenuBarVehicleLeaveButton:SetPoint('BOTTOM', SpartanUI, 'TOP', 0, 80)
			end
		)

		FramerateText:ClearAllPoints()
		FramerateText:SetPoint('BOTTOM', 'SpartanUI_Base1', 'TOP', 0, 0)

		MainMenuBar:Hide()
		hooksecurefunc(
			SpartanUI,
			'Hide',
			function()
				module:updateSpartanViewport()
			end
		)
		hooksecurefunc(
			SpartanUI,
			'Show',
			function()
				module:updateSpartanViewport()
			end
		)
		hooksecurefunc(
			'UpdateContainerFrameAnchors',
			function()
				-- fix bag offsets
				local frame2, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
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
					frame2 = getglobal(frameName)
					frame2:SetScale(containerScale)
					if (index == 1) then
						-- First bag
						frame2:SetPoint(
							'BOTTOMRIGHT',
							frame2:GetParent(),
							'BOTTOMRIGHT',
							-xOffset,
							(yOffset + (SUI.DB.yoffset or 1)) * (SUI.DB.scale or 1)
						)
					elseif (freeScreenHeight < frame2:GetHeight()) then
						-- Start a new column
						column = column + 1
						freeScreenHeight = screenHeight - yOffset
						frame2:SetPoint('BOTTOMRIGHT', frame2:GetParent(), 'BOTTOMRIGHT', -(column * CONTAINER_WIDTH) - xOffset, yOffset)
					else
						-- Anchor to the previous bag
						frame2:SetPoint('BOTTOMRIGHT', ContainerFrame1.bags[index - 1], 'TOPRIGHT', 0, CONTAINER_SPACING)
					end
					freeScreenHeight = freeScreenHeight - frame2:GetHeight() - VISIBLE_CONTAINER_SPACING
				end
			end
		)
	end
end

function module:TooltipLoc(self, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'SpartanUI', 'TOPRIGHT', 0, 10)
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		RegisterStateDriver(SpartanUI, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if not SUI.DBMod.Artwork.VehicleUI then
		UnregisterStateDriver(SpartanUI, 'visibility')
	end
end

function module:EnableFramework()
	anchor:SetFrameStrata('BACKGROUND')
	anchor:SetFrameLevel(1)
	frame:SetFrameStrata('BACKGROUND')
	frame:SetFrameLevel(1)

	-- hooksecurefunc("AchievementAlertFrame_ShowAlert",function() -- achivement alerts
	-- if (AchievementAlertFrame1) then AchievementAlertFrame1:SetPoint("BOTTOM",SpartanUI,"TOP",0,100); end
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
	module:updateSpartanOffset()
	module:updateSpartanXOffset()
	module:updateSpartanViewport()
	module:updateSpartanAlpha()

	-- Limit updates via interval
	anchor.UpdateInterval = 5 --Seconds
	anchor.TimeSinceLastUpdate = 0
	anchor:SetScript(
		'OnUpdate',
		function(self, ...)
			local elapsed = select(1, ...)
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
			if (self.TimeSinceLastUpdate > self.UpdateInterval) then
				if (InCombatLockdown()) then
					return
				end

				module:updateScale()
				module:updateSpartanOffset()
				module:updateSpartanXOffset()
				module:updateSpartanViewport()
				self.TimeSinceLastUpdate = 0
			end
		end
	)

	if SUI.DB.Styles.Classic.Color.Art then
		--Use a timer since we have to wait for everything to get loaded.
		C_Timer.After(
			1,
			function()
				module:SetColor()
			end
		)
	end
end
