local _G, SUI = _G, SUI
local module = SUI:GetModule('Module_Artwork') ---@type SUI.Module.Artwork
local MoveIt = SUI.MoveIt
-- Helper functions
local ReparentAB = false
local ExtraAB = SUI:NewModule('ExtraAB') ---@type SUI.Module

---@param frame any
---@param anchor FramePoint
local function ResetPosition(frame, _, anchor)
	local holder = frame.SUIHolder
	if holder and anchor ~= holder then
		frame:ClearAllPoints()
		frame:SetPoint('CENTER' or frame.SUIHolderMountPoint, holder)
	end
end

local function ResetParent(frame, parent)
	if parent ~= BossButtonHolder and not ReparentAB then
		if InCombatLockdown() then
			ReparentAB = true
			ExtraAB:RegisterEvent('PLAYER_REGEN_ENABLED')
			return
		end

		ZoneAbilityFrame:SetParent(BossButtonHolder)
		ExtraActionBarFrame:SetParent(BossButtonHolder)
	end
end

ExtraAB.PLAYER_REGEN_ENABLED = function(self)
	ZoneAbilityFrame:SetParent(BossButtonHolder)
	ExtraActionBarFrame:SetParent(BossButtonHolder)
end

---@param name string
---@return Frame
local function GenerateHolder(name)
	local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers[name])
	local holder = CreateFrame('Frame', name .. 'Holder', UIParent)
	holder:SetPoint(point, anchor, secondaryPoint, x, y)

	if _G[name] then
		local width, height = _G[name]:GetSize()
		holder:SetSize(width, height)
	else
		holder:SetSize(256, 64)
	end

	holder:Hide()

	return holder
end

---@param frame Frame
---@param holder Frame
---@param pos? FramePoint
local function AttachToHolder(frame, holder, pos)
	frame:ClearAllPoints()
	frame:SetPoint(pos or 'CENTER', holder)
	frame.SUIHolder = holder
	frame.SUIHolderMountPoint = pos or 'CENTER'
end

-- Blizzard Movers
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
		TalkingHeadFrame:HookScript('OnShow', function()
			TalkingHeadFrame:ClearAllPoints()
			TalkingHeadFrame:SetPoint('CENTER', THUIHolder, 'CENTER', 0, 0)
		end)
	end
	if C_AddOns.IsAddOnLoaded('Blizzard_TalkingHeadUI') then
		SetupTalkingHead()
	else
		--We want the mover to be available immediately, so we load it ourselves
		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_ENTERING_WORLD')
		f:SetScript('OnEvent', function(frame, event)
			frame:UnregisterEvent(event)
			TalkingHead_LoadUI()
			SetupTalkingHead()
		end)
	end
end

local function AbilityBars()
	local ExtraAbilityContainer = _G['ExtraAbilityContainer']
	local ExtraActionBarFrame = _G['ExtraActionBarFrame']
	local ZoneAbilityFrame = _G['ZoneAbilityFrame']
	ExtraActionBarFrame.ignoreInLayout = true
	ZoneAbilityFrame.ignoreInLayout = true

	-- ZoneAbility
	-- local ZoneAbilityHolder = GenerateHolder('ZoneAbility')
	-- AttachToHolder(ZoneAbilityFrame, ZoneAbilityHolder)

	-- Extra Action / Boss Bar
	local BossButtonHolder = GenerateHolder('BossButton')
	BossButtonHolder:SetSize(100, 70)
	BossButtonHolder:Show()

	-- Attach the frames to the holder
	AttachToHolder(ZoneAbilityFrame, BossButtonHolder)
	AttachToHolder(ExtraActionBarFrame, BossButtonHolder)
	AttachToHolder(ExtraAbilityContainer, BossButtonHolder)

	-- Hook the SetPoint function to prevent the frame from moving
	hooksecurefunc(ZoneAbilityFrame, 'SetPoint', ResetPosition)
	hooksecurefunc(ExtraActionBarFrame, 'SetPoint', ResetPosition)
	hooksecurefunc(ExtraAbilityContainer, 'SetPoint', ResetPosition)

	-- Hook the SetParent function to prevent the frame from moving
	hooksecurefunc(ZoneAbilityFrame, 'SetParent', ResetParent)
	hooksecurefunc(ExtraActionBarFrame, 'SetParent', ResetParent)
	hooksecurefunc(ExtraAbilityContainer, 'SetParent', ResetParent)

	-- Create the movers
	-- MoveIt:CreateMover(ZoneAbilityHolder, 'ZoneAbility', 'Zone ability', nil, 'Blizzard UI')
	MoveIt:CreateMover(BossButtonHolder, 'BossButton', 'Extra action button', nil, 'Blizzard UI')
end

local function FramerateFrame()
	local holder = GenerateHolder('FramerateFrame')
	holder:SetSize(64, 20)
	AttachToHolder(_G['FramerateFrame'], holder)
	MoveIt:CreateMover(holder, 'FramerateFrame', 'Framerate frame', nil, 'Blizzard UI')
end

local function AlertFrame()
	local holder = GenerateHolder('AlertFrame')

	AttachToHolder(_G['AlertFrame'], holder, 'BOTTOM')
	AttachToHolder(_G['GroupLootContainer'], holder, 'BOTTOM')

	hooksecurefunc(_G['AlertFrame'], 'SetPoint', ResetPosition)
	hooksecurefunc(_G['GroupLootContainer'], 'SetPoint', ResetPosition)

	MoveIt:CreateMover(holder, 'AlertHolder', 'Alert frame anchor', nil, 'Blizzard UI')
end

local function DurabilityFrame()
	local element = _G['DurabilityFrame']
	local holder = GenerateHolder('DurabilityFrame')

	element:ClearAllPoints()
	element:SetPoint('CENTER', holder, 'CENTER')
	element.SUIHolder = holder

	hooksecurefunc(element, 'SetPoint', ResetPosition)
	MoveIt:CreateMover(holder, 'DurabilityFrame', 'Durability Frame', nil, 'Blizzard UI')
end

local function VehicleLeaveButton()
	local function MoverCreate()
		local point, _, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.VehicleLeaveButton)
		local VehicleBtnHolder = CreateFrame('Frame', 'VehicleBtnHolder', SpartanUI)
		VehicleBtnHolder:SetSize(MainMenuBarVehicleLeaveButton:GetSize())
		VehicleBtnHolder:SetPoint(point, UIParent, secondaryPoint, x, y)
		MoveIt:CreateMover(VehicleBtnHolder, 'VehicleLeaveButton', 'Vehicle leave button', nil, 'Blizzard UI')

		MainMenuBarVehicleLeaveButton:ClearAllPoints()
		MainMenuBarVehicleLeaveButton:SetPoint('CENTER', VehicleBtnHolder, 'CENTER')
		hooksecurefunc(MainMenuBarVehicleLeaveButton, 'SetPoint', function(_, _, parent)
			if parent ~= VehicleBtnHolder then
				MainMenuBarVehicleLeaveButton:ClearAllPoints()
				MainMenuBarVehicleLeaveButton:SetParent(UIParent)
				MainMenuBarVehicleLeaveButton:SetPoint('CENTER', VehicleBtnHolder, 'CENTER')
			end
		end)
	end

	-- Delay this so unit frames have been generated
	module:ScheduleTimer(MoverCreate, 2)
end

local function VehicleSeatIndicator()
	local SeatIndicator = _G['VehicleSeatIndicator']

	local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.VehicleSeatIndicator)
	local VehicleSeatHolder = CreateFrame('Frame', 'VehicleSeatHolder', SpartanUI)
	VehicleSeatHolder:SetSize(SeatIndicator:GetSize())
	VehicleSeatHolder:SetPoint(point, anchor, secondaryPoint, x, y)
	VehicleSeatHolder:Hide()
	local function SetPosition(_, _, anchorPoint)
		if anchorPoint ~= VehicleSeatHolder then
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

local function WidgetPowerBarContainer()
	local holder = GenerateHolder('WidgetPowerBarContainer')

	if _G['UIWidgetPowerBarContainerFrame'] then
		AttachToHolder(_G['UIWidgetPowerBarContainerFrame'], holder)
		hooksecurefunc(_G['UIWidgetPowerBarContainerFrame'], 'SetPoint', ResetPosition)
	end

	if not C_AddOns.IsAddOnLoaded('SimplePowerBar') then
		AttachToHolder(_G['PlayerPowerBarAlt'], holder)
		hooksecurefunc(_G['PlayerPowerBarAlt'], 'SetPoint', ResetPosition)
	end

	MoveIt:CreateMover(holder, 'WidgetPowerBarContainer', 'Power bar', nil, 'Blizzard UI')
end

-- This is the main inpoint
function module.BlizzMovers()
	FramerateFrame()
	AbilityBars()
	AlertFrame()
	DurabilityFrame()
	-- TalkingHead()
	VehicleLeaveButton()
	VehicleSeatIndicator()
	WidgetPowerBarContainer()
end
