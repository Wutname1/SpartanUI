local SUI = SUI
local StdUi = LibStub('StdUi'):NewInstance()
local module = SUI:NewModule('Component_MoveIt', 'AceEvent-3.0', 'AceHook-3.0')
local MoverList = {}
local colors = {
	bg = {0.0588, 0.0588, 0, .85},
	border = {0.00, 0.00, 0.00, 1},
	text = {1, 1, 1, 1},
	disabled = {0.55, 0.55, 0.55, 1}
}
local MoveEnabled = false
local coordFrame

local function GetPoints(obj)
	local point, anchor, secondaryPoint, x, y = obj:GetPoint()
	if not anchor then
		anchor = UIParent
	end

	return format('%s,%s,%s,%d,%d', point, anchor:GetName(), secondaryPoint, Round(x), Round(y))
end

function module:SaveMoverPosition(name)
	-- local mover = _G[name]
	-- local _, anchor = mover:GetPoint()
	-- mover.anchor = anchor:GetName()

	SUI.DB.MoveIt.movers[name].MovedPoints = GetPoints(mover)
end

function module:CalculateMoverPoints(mover)
	local screenWidth, screenHeight, screenCenter = UIParent:GetRight(), UIParent:GetTop(), UIParent:GetCenter()
	local x, y = mover:GetCenter()

	local LEFT = screenWidth / 3
	local RIGHT = screenWidth * 2 / 3
	local TOP = screenHeight / 2
	local point, nudgePoint, nudgeInversePoint

	if y >= TOP then
		point = 'TOP'
		InversePoint = 'BOTTOM'
		y = -(screenHeight - mover:GetTop())
	else
		point = 'BOTTOM'
		InversePoint = 'TOP'
		y = mover:GetBottom()
	end

	if x >= RIGHT then
		point = point .. 'RIGHT'
		InversePoint = 'LEFT'
		x = mover:GetRight() - screenWidth
	elseif x <= LEFT then
		point = point .. 'LEFT'
		InversePoint = 'RIGHT'
		x = mover:GetLeft()
	else
		x = x - screenCenter
	end

	--Update coordinates if nudged
	x = x
	y = y

	return x, y, point, InversePoint
end

function module:IsMoved(name)
	if not SUI.DB.MoveIt.movers[name] then
		return false
	end
	if SUI.DB.MoveIt.movers[name].MovedPoints then
		return true
	end
	return false
end

function module:Reset(name)
	if name == nil then
		for name in pairs(MoverList) do
			local f = _G[name]
			local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.MoveIt.movers[name].defaultPoint)
			f:ClearAllPoints()
			f:SetPoint(point, anchor, secondaryPoint, x, y)

			if SUI.DB.MoveIt.movers[name].MovedPoints then
				SUI.DB.MoveIt.movers[name].MovedPoints = nil
			end

			-- for key, value in pairs(MoverList[name]) do
			-- 	if key == 'postdrag' and type(value) == 'function' then
			-- 		value(f, E:GetScreenQuadrant(f))
			-- 	end
			-- end
		end
	else
		local f = _G['SUI_Mover_' .. name]
		local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.MoveIt.movers[name].defaultPoint)
		f:ClearAllPoints()
		f:SetPoint(point, anchor, secondaryPoint, x, y)

		if SUI.DB.MoveIt.movers[name].MovedPoints then
			SUI.DB.MoveIt.movers[name].MovedPoints = nil
		end
	end
end

function module:MoveIt(name)
	if MoveEnabled then
		for _, v in pairs(MoverList) do
			v:Hide()
		end
		MoveEnabled = false
	else
		if name then
			local frame = MoverList[name]
			frame:Show()
		else
			for _, v in pairs(MoverList) do
				v:Show()
			end
		end
		MoveEnabled = true
	end
end

function module:NudgeMover(x, y)
end

local isDragging = false

function module:CreateMover(parent, name, text, setDefault)
	-- If for some reason the parent does not exist or we have already done this exit out
	if not parent or MoverList[name] then
		return
	end
	if text == nil then
		text = name
	end

	local point, anchor, secondaryPoint, x, y = strsplit(',', GetPoints(parent))

	--Use dirtyWidth / dirtyHeight to set initial size if possible
	local width = parent.dirtyWidth or parent:GetWidth()
	local height = parent.dirtyHeight or parent:GetHeight()

	local f = CreateFrame('Button', 'SUI_Mover_' .. name, UIParent)
	f:SetClampedToScreen(true)
	f:RegisterForDrag('LeftButton', 'RightButton')
	f:EnableMouseWheel(true)
	f:SetMovable(true)
	f:SetSize(width, height)

	f:SetBackdrop(
		{
			bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
			edgeFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
			edgeSize = 1
		}
	)
	f:SetBackdropColor(unpack(colors.bg))
	f:SetBackdropBorderColor(unpack(colors.border))

	f:Hide()
	f.parent = parent
	f.name = name
	f.postdrag = postdrag
	f.snapOffset = snapOffset or -2
	f.shouldDisable = shouldDisable
	f.configString = configString

	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:SetFrameStrata('DIALOG')

	MoverList[name] = f
	-- E.snapBars[#E.snapBars + 1] = f

	local fs = f:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(fs, 12, 'Mover')
	fs:SetJustifyH('CENTER')
	fs:SetPoint('CENTER')
	fs:SetText(text or name)
	fs:SetTextColor(unpack(colors.text))
	f:SetFontString(fs)
	f.text = fs

	if not SUI.DB.MoveIt.movers[name].defaultPoint or SUI.DB.MoveIt.movers[name].defaultPoint == '' or setDefault then
		SUI.DB.MoveIt.movers[name].defaultPoint = GetPoints(parent)
	end

	if SUI.DB.MoveIt.movers[name].MovedPoints then
		point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.MoveIt.movers[name].MovedPoints)
	end
	f:ClearAllPoints()
	f:SetPoint(point, anchor, secondaryPoint, x, y)

	local function OnDragStart(self)
		if InCombatLockdown() then
			SUI:Print(ERR_NOT_IN_COMBAT)
			return
		end

		self:StartMoving()

		coordFrame.child = self
		coordFrame:Show()
		isDragging = true
	end

	local function OnDragStop(self)
		if InCombatLockdown() then
			SUI:Print(ERR_NOT_IN_COMBAT)
			return
		end
		isDragging = false
		-- if db.stickyFrames then
		-- 	Sticky:StopMoving(self)
		-- else
		self:StopMovingOrSizing()
		-- end

		-- module:SaveMoverPosition(name)
		SUI.DB.MoveIt.movers[name].MovedPoints = GetPoints(self)
		-- if NudgeWindow then
		-- 	E:UpdateNudgeFrame(self, x, y)
		-- end

		coordFrame.child = nil
		coordFrame:Hide()

		self:SetUserPlaced(false)
	end

	local function OnEnter(self)
		if isDragging then
			return
		end
		self.text:SetTextColor(1, 1, 1)
	end

	local function OnMouseDown(self, button)
		if button == 'LeftButton' and not isDragging then
		-- if NudgeWindow:IsShown() then
		-- 	NudgeWindow:Hide()
		-- else
		-- 	NudgeWindow:Show()
		-- end
		end

		if IsAltKeyDown() then -- Reset anchor
			module:Reset(name)
		elseif IsShiftKeyDown() then -- Allow hiding a mover temporarily
			self:Hide()
		end
	end

	local function OnLeave(self)
		if isDragging then
			return
		end
	end

	local function OnShow(self)
		self:SetBackdropBorderColor(unpack(colors.bg))
	end

	local function OnMouseWheel(_, delta)
		if IsShiftKeyDown() then
			module:NudgeMover(delta)
		else
			module:NudgeMover(nil, delta)
		end
	end

	f:SetScript('OnDragStart', OnDragStart)
	-- f:SetScript('OnMouseUp', E.AssignFrameToNudge)
	f:SetScript('OnDragStop', OnDragStop)
	f:SetScript('OnEnter', OnEnter)
	f:SetScript('OnMouseDown', OnMouseDown)
	f:SetScript('OnLeave', OnLeave)
	f:SetScript('OnShow', OnShow)
	f:SetScript('OnMouseWheel', OnMouseWheel)

	parent:SetScript('OnSizeChanged', SizeChanged)
	parent.mover = f

	parent:ClearAllPoints()
	parent:SetPoint('TOPLEFT', f, 0, 0)
end

function module:OnInitialize()
	coordFrame = StdUi:Window(nil, '', 480, 200)
	coordFrame:SetFrameStrata('DIALOG')

	coordFrame.Title = StdUi:Texture(coordFrame, 104, 30, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	coordFrame.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	coordFrame.Title:SetPoint('TOP')
	coordFrame.Title:SetAlpha(.8)

	-- Create Movers
	--TalkingHeadUI
	if IsAddOnLoaded('Blizzard_TalkingHeadUI') then
		module:CreateMover(TalkingHeadFrame, 'TalkingHeadFrameMover', L['Talking Head Frame'])
	else
		--We want the mover to be available immediately, so we load it ourselves
		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_ENTERING_WORLD')
		f:SetScript(
			'OnEvent',
			function(frame, event)
				frame:UnregisterEvent(event)
				_G.TalkingHead_LoadUI()
				module:CreateMover(TalkingHeadFrame, 'TalkingHeadFrameMover', L['Talking Head Frame'])
			end
		)
	end
	--AltPowerBar
	if not IsAddOnLoaded('SimplePowerBar') then
		local holder = CreateFrame('Frame', 'AltPowerBarHolder', E.UIParent)
		holder:Point('TOP', UIParent, 'TOP', 0, -18)
		holder:Size(128, 50)

		_G.PlayerPowerBarAlt:ClearAllPoints()
		_G.PlayerPowerBarAlt:Point('CENTER', holder, 'CENTER')
		_G.PlayerPowerBarAlt:SetParent(holder)
		_G.PlayerPowerBarAlt.ignoreFramePositionManager = true

		local function Position(bar)
			bar:SetPoint('CENTER', AltPowerBarHolder, 'CENTER')
		end
		hooksecurefunc(_G.PlayerPowerBarAlt, 'ClearAllPoints', Position)

		module:CreateMover(holder, 'AltPowerBarMover', 'Alternative Power')
	end
	--
end

function module:OnEnable()
	local ChatCommand = function(arg)
		if InCombatLockdown() then
			SUI:Print(ERR_NOT_IN_COMBAT)
			return
		end

		if (not arg) then
			module:MoveIt()
		else
			if MoverList[arg] then
				module:MoveIt(arg)
			else
				SUI:Print('Invalid move command!')
			end
		end
	end
	SUI:AddChatCommand('move', ChatCommand)
end

function module:Options()
end
