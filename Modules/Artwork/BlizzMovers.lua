local _G, SUI = _G, SUI
local module = SUI:GetModule('Artwork') ---@type SUI.Module.Artwork
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
---@param frame? Frame
---@return Frame
local function GenerateHolder(name, frame)
	local holder = CreateFrame('Frame', name .. 'Holder', UIParent)

	local dbEntry = SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers[name]
	if dbEntry then
		local point, anchor, secondaryPoint, x, y = strsplit(',', dbEntry)
		holder:SetPoint(point, anchor, secondaryPoint, x, y)
	elseif frame then
		local point, relativeTo, relativePoint, x, y = frame:GetPoint()
		holder:SetPoint(point, relativeTo, relativePoint, x, y)
	else
		-- Default position if neither DB entry nor frame is available
		holder:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	end

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
	-- Extra Action / Boss Bar
	local ExtraAbilityHolder = GenerateHolder('ExtraAbility')
	ExtraAbilityHolder:SetSize(256, 120)
	ExtraAbilityHolder:Show()

	-- Attach the frames to the holder
	AttachToHolder(ExtraAbilityContainer, ExtraAbilityHolder)

	-- Hook the SetPoint function to prevent the frame from moving
	hooksecurefunc(ExtraAbilityContainer, 'SetPoint', ResetPosition)

	-- Hook the SetParent function to prevent the frame from moving
	-- hooksecurefunc(ExtraAbilityContainer, 'SetParent', ResetParent)

	-- Create the movers
	MoveIt:CreateMover(ExtraAbilityHolder, 'ExtraAbility', 'Extra Abilities', nil, 'Blizzard UI')
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

local function TopCenterContainer()
	local holder = GenerateHolder('TopCenterContainer', _G['UIWidgetTopCenterContainerFrame'])
	AttachToHolder(_G['UIWidgetTopCenterContainerFrame'], holder)
	hooksecurefunc(_G['UIWidgetTopCenterContainerFrame'], 'SetPoint', ResetPosition)
	MoveIt:CreateMover(holder, 'TopCenterContainer', 'Top center container', nil, 'Blizzard UI')
	for _, widget in pairs(_G['UIWidgetTopCenterContainerFrame'].widgetFrames) do
		SUI.Skins.SkinWidgets(widget)
	end
	module:RegisterEvent('PLAYER_ENTERING_WORLD')
	module:RegisterEvent('UPDATE_ALL_UI_WIDGETS')
	-- module:RegisterEvent('UPDATE_UI_WIDGET')
end

function module:UPDATE_UI_WIDGET()
	module:UPDATE_ALL_UI_WIDGETS()
end

function module:UPDATE_ALL_UI_WIDGETS()
	for _, widget in pairs(_G['UIWidgetTopCenterContainerFrame'].widgetFrames) do
		SUI.Skins.SkinWidgets(widget)
	end
end

function module:PLAYER_ENTERING_WORLD()
	print('PLAYER_ENTERING_WORLD')
	module:UPDATE_ALL_UI_WIDGETS()
end

-- This is the main inpoint
function module.BlizzMovers()
	FramerateFrame()
	AbilityBars()
	AlertFrame()
	DurabilityFrame()
	TopCenterContainer()
	-- TalkingHead()
	VehicleLeaveButton()
	-- VehicleSeatIndicator()
	WidgetPowerBarContainer()
end
