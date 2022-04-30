local _G, SUI = _G, SUI
local L = SUI.L
local module = SUI:GetModule('Component_Artwork')
local MoveIt = SUI.MoveIt

local function TalkingHead()
	local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.TalkingHead)
	local THUIHolder = CreateFrame('Frame', 'THUIHolder', SpartanUI)
	THUIHolder:SetPoint(point, anchor, secondaryPoint, x, y)
	THUIHolder:Hide()

	local SetupTalkingHead = function()
		--Prevent WoW from moving the frame around
		TalkingHeadFrame.ignoreFramePositionManager = true
		UIPARENT_MANAGED_FRAME_POSITIONS.TalkingHeadFrame = nil

		THUIHolder:SetSize(TalkingHeadFrame:GetSize())
		MoveIt:CreateMover(THUIHolder, 'THUIHolder', 'Talking Head Frame', nil, 'Blizzard UI')
		TalkingHeadFrame:HookScript(
			'OnShow',
			function()
				TalkingHeadFrame:ClearAllPoints()
				TalkingHeadFrame:SetPoint('CENTER', THUIHolder, 'CENTER', 0, 0)
			end
		)
	end

	if IsAddOnLoaded('Blizzard_TalkingHeadUI') then
		SetupTalkingHead()
	else
		--We want the mover to be available immediately, so we load it ourselves
		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_ENTERING_WORLD')
		f:SetScript(
			'OnEvent',
			function(frame, event)
				frame:UnregisterEvent(event)
				TalkingHead_LoadUI()
				SetupTalkingHead()
			end
		)
	end
end

local function AltPowerBar()
	if not IsAddOnLoaded('SimplePowerBar') then
		local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.AltPowerBar)
		local holder = CreateFrame('Frame', 'AltPowerBarHolder', UIParent)
		holder:SetPoint(point, anchor, secondaryPoint, x, y)
		holder:SetSize(256, 64)
		holder:Hide()

		_G['PlayerPowerBarAlt']:ClearAllPoints()
		_G['PlayerPowerBarAlt']:SetPoint('CENTER', holder, 'CENTER')
		_G['PlayerPowerBarAlt'].ignoreFramePositionManager = true

		hooksecurefunc(
			_G['PlayerPowerBarAlt'],
			'ClearAllPoints',
			function(bar)
				bar:SetPoint('CENTER', holder, 'CENTER')
			end
		)

		MoveIt:CreateMover(holder, 'AltPowerBarMover', 'Alternative Power', nil, 'Blizzard UI')
	end
end

local function WidgetPowerBarContainer()
	if not _G['UIWidgetPowerBarContainerFrame'] then
		return
	end
	local point, anchor, secondaryPoint, x, y =
		strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.WidgetPowerBarContainer)
	local holder = CreateFrame('Frame', 'WidgetPowerBarContainerHolder', UIParent)
	holder:SetPoint(point, anchor, secondaryPoint, x, y)
	holder:SetSize(256, 64)
	holder:Hide()

	_G['UIWidgetPowerBarContainerFrame']:ClearAllPoints()
	_G['UIWidgetPowerBarContainerFrame']:SetPoint('CENTER', holder, 'CENTER')
	_G['UIWidgetPowerBarContainerFrame'].ignoreFramePositionManager = true

	hooksecurefunc(
		_G['UIWidgetPowerBarContainerFrame'],
		'ClearAllPoints',
		function(bar)
			bar:SetPoint('CENTER', holder, 'CENTER')
		end
	)

	MoveIt:CreateMover(holder, 'WidgetPowerBarContainer', 'Power bar', nil, 'Blizzard UI')
end

local function AbilityBars()
	-- ZoneAbility
	local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.ZoneAbility)
	local ZoneAbilityHolder = CreateFrame('Frame', 'ZoneAbilityHolder', SpartanUI)
	ZoneAbilityHolder:SetSize(ZoneAbilityFrame:GetSize())
	ZoneAbilityHolder:SetPoint(point, anchor, secondaryPoint, x, y)
	ZoneAbilityHolder:Hide()
	MoveIt:CreateMover(ZoneAbilityHolder, 'ZoneAbility', 'Zone ability', nil, 'Blizzard UI')

	ExtraAbilityContainer:ClearAllPoints()
	ExtraAbilityContainer:SetPoint('CENTER', ZoneAbilityHolder)
	-- ExtraAbilityContainer.ignoreFramePositionManager = true

	-- Extra Action / Boss Bar
	point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.ZoneAbility)
	local ExtraActionHolder = CreateFrame('Frame', 'ExtraActionHolder', SpartanUI)
	ExtraActionHolder:SetSize(ExtraActionBarFrame:GetSize())
	ExtraActionHolder:SetPoint(point, anchor, secondaryPoint, x, y)
	ExtraActionHolder:Hide()
	MoveIt:CreateMover(ExtraActionHolder, 'ExtraAction', 'Boss Button', nil, 'Blizzard UI')

	ExtraActionBarFrame:ClearAllPoints()
	ExtraActionBarFrame:SetPoint('CENTER', ExtraActionHolder)
	ExtraActionBarFrame.ignoreFramePositionManager = true
end

local function AlertFrame()
	local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.AlertFrame)
	local AlertHolder = CreateFrame('Frame', 'AlertHolder', SpartanUI)
	AlertHolder:SetSize(250, 40)
	AlertHolder:SetPoint(point, anchor, secondaryPoint, x, y)
	AlertHolder:Hide()
	MoveIt:CreateMover(AlertHolder, 'AlertHolder', 'Alert frame anchor', nil, 'Blizzard UI')

	local Alertframe = _G['AlertFrame']
	local GroupLootContainer = _G['GroupLootContainer']

	Alertframe:ClearAllPoints()
	Alertframe:SetPoint('BOTTOM', AlertHolder)
	GroupLootContainer:ClearAllPoints()
	GroupLootContainer:SetPoint('BOTTOM', AlertHolder)
end

local function VehicleSeatIndicator()
	local SeatIndicator = _G['VehicleSeatIndicator']

	local point, anchor, secondaryPoint, x, y =
		strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.VehicleSeatIndicator)
	local VehicleSeatHolder = CreateFrame('Frame', 'VehicleSeatHolder', SpartanUI)
	VehicleSeatHolder:SetSize(SeatIndicator:GetSize())
	VehicleSeatHolder:SetPoint(point, anchor, secondaryPoint, x, y)
	VehicleSeatHolder:Hide()
	local function SetPosition(_, _, anchor)
		if anchor:GetName() == 'MinimapCluster' or anchor == MinimapCluster then
			SeatIndicator:ClearAllPoints()
			SeatIndicator:SetPoint('TOPLEFT', VehicleSeatHolder)
		end
	end
	MoveIt:CreateMover(VehicleSeatHolder, 'VehicleSeatIndicator', 'Vehicle seat anchor', nil, 'Blizzard UI')

	hooksecurefunc(SeatIndicator, 'SetPoint', SetPosition)
	SeatIndicator.PositionVehicleFrameHooked = true
	SeatIndicator:ClearAllPoints()
	SeatIndicator:SetPoint('TOPLEFT', VehicleSeatHolder)
end

local function VehicleLeaveButton()
	local function MoverCreate()
		-- if InCombatLockdown() then
		-- 	return
		-- end

		local point, anchor, secondaryPoint, x, y =
			strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.VehicleLeaveButton)
		local VehicleBtnHolder = CreateFrame('Frame', 'VehicleBtnHolder', SpartanUI)
		VehicleBtnHolder:SetSize(MainMenuBarVehicleLeaveButton:GetSize())
		VehicleBtnHolder:SetPoint(point, UIParent, secondaryPoint, x, y)
		MoveIt:CreateMover(VehicleBtnHolder, 'VehicleLeaveButton', 'Vehicle leave button', nil, 'Blizzard UI')

		MainMenuBarVehicleLeaveButton:ClearAllPoints()
		MainMenuBarVehicleLeaveButton:SetPoint('CENTER', VehicleBtnHolder, 'CENTER')
		hooksecurefunc(
			MainMenuBarVehicleLeaveButton,
			'SetPoint',
			function(_, _, parent)
				if parent ~= VehicleBtnHolder then
					MainMenuBarVehicleLeaveButton:ClearAllPoints()
					MainMenuBarVehicleLeaveButton:SetParent(UIParent)
					MainMenuBarVehicleLeaveButton:SetPoint('CENTER', VehicleBtnHolder, 'CENTER')
				end
			end
		)
	end

	-- Delay this so unit frames have been generated
	module:ScheduleTimer(MoverCreate, 2)
end

function module.BlizzMovers()
	if SUI.IsClassic then
		return
	end

	AlertFrame()
	VehicleLeaveButton()

	if SUI.IsRetail then
		VehicleSeatIndicator()
		TalkingHead()
		AltPowerBar()
		AbilityBars()
		WidgetPowerBarContainer()
	end
end
