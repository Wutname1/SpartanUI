local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_Minimal')
----------------------------------------------------------------------------------------------------
local anchor, frame = Minimal_AnchorFrame, Minimal_SpartanUI

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
		if (SUI.DB.scale ~= SUI:round(Minimal_SpartanUI:GetScale())) then
			frame:SetScale(SUI.DB.scale)
		end

		CurScale = SUI.DB.scale
	end
end

function module:updateOffset(Top, Bottom) -- handles SpartanUI offset based on setting or fubar / titan
	if SUI.DB.Styles.Minimal.HideCenterGraphic then
		Minimal_SpartanUI_Base1:Hide()
	else
		Minimal_SpartanUI_Base1:Show()
	end
end

function module:updateXOffset() -- handles SpartanUI offset based on setting or fubar / titan
	if not SUI.DB.Offset.Horizontal then
		return 0
	end
	local offset = SUI.DB.Offset.Horizontal
	if SUI:round(offset) <= -300 then
		Minimal_SpartanUI_Base5:ClearAllPoints()
		Minimal_SpartanUI_Base5:SetPoint('LEFT', Minimal_SpartanUI_Base4, 'RIGHT')
		Minimal_SpartanUI_Base5:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT')
	elseif SUI:round(offset) >= 300 then
		Minimal_SpartanUI_Base3:ClearAllPoints()
		Minimal_SpartanUI_Base3:SetPoint('RIGHT', Minimal_SpartanUI_Base2, 'LEFT')
		Minimal_SpartanUI_Base3:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT')
	end
	Minimal_SpartanUI:SetPoint('LEFT', Minimal_AnchorFrame, 'LEFT', offset, 0)
	if (SUI:round(offset) ~= SUI:round(anchor:GetWidth())) then
		anchor:SetWidth(offset)
	end
	SUI.DB.Offset.Horizontal = offset
end

----------------------------------------------------------------------------------------------------

function module:SlidingTrays()
	local Settings = {
		bg = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Minimal\\Images\\base-center-top',
			TexCoord = {.076171875, 0.92578125, 0, 0.18359375}
		},
		bgCollapsed = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Minimal\\Images\\base-center-top',
			TexCoord = {0.076171875, 0.92578125, 1, 0.92578125}
		},
		UpTex = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Minimal\\Images\\base-center-top',
			TexCoord = {0.3675, 0.64, 0.235, 0.265}
		},
		DownTex = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Minimal\\Images\\base-center-top',
			TexCoord = {0.3675, 0.64, 0.265, 0.235}
		}
	}

	module.Trays = Artwork_Core:SlidingTrays(Settings)
end

function module:SetColor()
	local r, b, g, a = unpack(SUI.DB.Styles.Minimal.Color)

	for i = 1, 5 do
		_G['Minimal_SpartanUI_Base' .. i]:SetVertexColor(r, b, g, a)
	end

	for _, v in pairs(module.Trays) do
		v.expanded.bg:SetVertexColor(r, b, g, a)
		v.collapsed.bgCollapsed:SetVertexColor(r, b, g, a)
	end
end

function module:InitFramework()
	do -- default interface modifications
		SUI_FramesAnchor:SetFrameStrata('BACKGROUND')
		SUI_FramesAnchor:SetFrameLevel(1)
		SUI_FramesAnchor:ClearAllPoints()
		SUI_FramesAnchor:SetPoint('BOTTOMLEFT', 'Minimal_AnchorFrame', 'BOTTOMLEFT', 0, 0)
		SUI_FramesAnchor:SetPoint('TOPRIGHT', 'Minimal_AnchorFrame', 'BOTTOMRIGHT', 0, 150)

		MainMenuBarVehicleLeaveButton:HookScript(
			'OnShow',
			function()
				MainMenuBarVehicleLeaveButton:ClearAllPoints()
				MainMenuBarVehicleLeaveButton:SetPoint('BOTTOM', Minimal_SpartanUI_Base1, 'TOP', 0, -100)
			end
		)

		FramerateText:ClearAllPoints()
		FramerateText:SetPoint('TOP', UIParent, 'TOP', 0, -20)

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
		tooltip:SetPoint('BOTTOMRIGHT', Minimal_SpartanUI, 'BOTTOMRIGHT', -20, 20)
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

	--Setup Sliding Trays
	module:SlidingTrays()
	if BT4BarBagBar and BT4BarPetBar.position then
		if not SUI.DB.Styles.War.MovedBars.BT4BarPetBar then
			BT4BarPetBar:position('TOPLEFT', module.Trays.left, 'TOPLEFT', 50, -2)
		end
		if not SUI.DB.Styles.War.MovedBars.BT4BarStanceBar then
			BT4BarStanceBar:position('TOPRIGHT', module.Trays.left, 'TOPRIGHT', -50, -2)
		end

		if not SUI.DB.Styles.War.MovedBars.BT4BarMicroMenu then
			BT4BarMicroMenu:position('TOPLEFT', module.Trays.right, 'TOPLEFT', 50, -2)
		end
		if not SUI.DB.Styles.War.MovedBars.BT4BarBagBar then
			BT4BarBagBar:position('TOPRIGHT', module.Trays.right, 'TOPRIGHT', -100, -2)
		end
	end

	module:SetColor()
	module:updateScale()
	module:updateXOffset()

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
				module:updateXOffset()
				self.TimeSinceLastUpdate = 0

				if SUI.DB.OpenOptions then
					SUI:ChatCommand()
					SUI.DB.OpenOptions = false
				end
			end
		end
	)
end
