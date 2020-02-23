local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Minimal')
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Minimal = {
		['BT4Bar1'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-1,90',
		['BT4Bar2'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-1,45',
		--
		['BT4Bar3'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,1,1',
		['BT4Bar4'] = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOMRIGHT,1,1',
		--
		['BT4Bar5'] = 'BOTTOMRIGHT,SUI_ActionBarAnchor,BOTTOM,-232,1',
		['BT4Bar6'] = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOM,260,1',
		--
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,0,130',
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,0,130',
		--
		['BT4BarStanceBar'] = 'TOP,SpartanUI,TOP,-309,0',
		['BT4BarPetBar'] = 'TOP,SpartanUI,TOP,-558,0',
		--
		['BT4BarMicroMenu'] = 'TOP,SpartanUI,TOP,369,0',
		['BT4BarBagBar'] = 'TOP,SpartanUI,TOP,680,0'
	}
	BarHandler.BarScale.BT4.Minimal = {
		['BT4Bar1'] = 0.78,
		['BT4Bar2'] = 0.78,
		['BT4Bar3'] = 0.78,
		['BT4Bar4'] = 0.78,
		['BT4Bar5'] = 0.78,
		['BT4Bar6'] = 0.7,
		['BT4Bar7'] = 0.7,
		['BT4Bar8'] = 0.78,
		['BT4Bar9'] = 0.78,
		['BT4Bar10'] = 0.78,
		['BT4BarBagBar'] = 0.6,
		['BT4BarExtraActionBar'] = 0.8,
		['BT4BarStanceBar'] = 0.6,
		['BT4BarPetBar'] = 0.6,
		['BT4BarMicroMenu'] = 0.6
	}

	--Init if needed
	if (SUI.DB.Artwork.Style == 'Minimal') then
		module:InitFramework()
	end
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Minimal') then
		module:Disable()
	else
		module:SetupMenus()

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
			BT4BarPetBar:position('TOPLEFT', module.Trays.left, 'TOPLEFT', 50, -2)
			BT4BarStanceBar:position('TOPRIGHT', module.Trays.left, 'TOPRIGHT', -50, -2)
			BT4BarMicroMenu:position('TOPLEFT', module.Trays.right, 'TOPLEFT', 50, -2)
			BT4BarBagBar:position('TOPRIGHT', module.Trays.right, 'TOPRIGHT', -100, -2)
		end

		module:SetColor()
	end
end

function module:TooltipLoc(self, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', SUI_Art_Minimal, 'BOTTOMRIGHT', -20, 20)
	end
end

function module:SetupMenus()
	SUI.opt.args['Artwork'].args['Art'] = {
		name = L['ArtworkOpt'],
		type = 'group',
		order = 10,
		args = {
			HideCenterGraphic = {
				name = L['Hide center graphic'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.Styles.Minimal.HideCenterGraphic
				end,
				set = function(info, val)
					SUI.DB.Styles.Minimal.HideCenterGraphic = val
					if SUI.DB.Styles.Minimal.HideCenterGraphic then
						SUI_Art_Minimal_Base1:Hide()
					else
						SUI_Art_Minimal_Base1:Show()
					end
				end
			},
			alpha = {
				name = L['ArtColor'],
				type = 'color',
				hasAlpha = true,
				order = 2,
				width = 'full',
				desc = L['TransparencyDesc'],
				get = function(info)
					return unpack(SUI.DB.Styles.Minimal.Color)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Minimal.Color = {r, b, g, a}
					module:SetColor()
				end
			}
		}
	}
end

function module:OnDisable()
	SUI_Art_Minimal:Hide()
end

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
		_G['SUI_Art_Minimal_Base' .. i]:SetVertexColor(r, b, g, a)
	end

	for _, v in pairs(module.Trays) do
		v.expanded.bg:SetVertexColor(r, b, g, a)
		v.collapsed.bgCollapsed:SetVertexColor(r, b, g, a)
	end
end

function module:InitFramework()
	SUI_FramesAnchor:SetFrameStrata('BACKGROUND')
	SUI_FramesAnchor:SetFrameLevel(1)
	SUI_FramesAnchor:ClearAllPoints()
	SUI_FramesAnchor:SetPoint('BOTTOMLEFT', 'SUI_Art_Minimal', 'BOTTOMLEFT', 0, 0)
	SUI_FramesAnchor:SetPoint('TOPRIGHT', 'SUI_Art_Minimal', 'BOTTOMRIGHT', 0, 150)

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
