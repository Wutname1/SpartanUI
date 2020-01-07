local SUI = SUI
local StdUi = LibStub('StdUi'):NewInstance()
local MoveIt = SUI:NewModule('Component_MoveIt', 'AceEvent-3.0', 'AceHook-3.0')
local MoverList = {}
local colors = {
	bg = {0.0588, 0.0588, 0, .85},
	border = {0.00, 0.00, 0.00, 1},
	text = {1, 1, 1, 1},
	disabled = {0.55, 0.55, 0.55, 1}
}
local MoverWatcher = CreateFrame('Frame', nil, UIParent)
local MoveEnabled = false
local coordFrame

local function GetPoints(obj)
	local point, anchor, secondaryPoint, x, y = obj:GetPoint()
	if not anchor then
		anchor = UIParent
	end

	return format('%s,%s,%s,%d,%d', point, anchor:GetName(), secondaryPoint, Round(x), Round(y))
end

function MoveIt:SaveMoverPosition(name)
	-- local mover = _G[name]
	-- local _, anchor = mover:GetPoint()
	-- mover.anchor = anchor:GetName()

	SUI.DB.MoveIt.movers[name].MovedPoints = GetPoints(mover)
end

function MoveIt:CalculateMoverPoints(mover)
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

function MoveIt:IsMoved(name)
	if not SUI.DB.MoveIt.movers[name] then
		return false
	end
	if SUI.DB.MoveIt.movers[name].MovedPoints then
		return true
	end
	return false
end

function MoveIt:Reset(name)
	if name == nil then
		for name in pairs(MoverList) do
			local f = _G[name]
			if f then
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
		end
		SUI:Print('Moved frames reset!')
	else
		local f = _G['SUI_Mover_' .. name]
		if f then
			local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.MoveIt.movers[name].defaultPoint)
			f:ClearAllPoints()
			f:SetPoint(point, anchor, secondaryPoint, x, y)

			if SUI.DB.MoveIt.movers[name].MovedPoints then
				SUI.DB.MoveIt.movers[name].MovedPoints = nil
			end
		end
	end
end

function MoveIt:GetMover(name)
	return MoverList[name]
end

function MoveIt:UpdateMover(name, obj, doNotScale)
	local mover = MoverList[name]

	if not mover then
		return
	end

	mover:SetSize(obj:GetWidth(), obj:GetHeight())
	if not doNotScale then
		mover:SetScale(obj:GetScale())
	end
end

function MoveIt:MoveIt(name)
	if MoveEnabled then
		for _, v in pairs(MoverList) do
			v:Hide()
		end
		MoveEnabled = false
		MoverWatcher:Hide()
	else
		if name then
			if type(baseName) == 'string' then
				local frame = MoverList[name]
				frame:Show()
			else
				for _, v in pairs(tableName) do
					local frame = MoverList[v]
					frame:Show()
				end
			end
		else
			for _, v in pairs(MoverList) do
				v:Show()
			end
		end
		MoveEnabled = true
		MoverWatcher:Show()
	end
	MoverWatcher:EnableKeyboard(MoveEnabled)
end

local isDragging = false

function MoveIt:CreateMover(parent, name, text, setDefault)
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
	f:SetScale(parent:GetScale() or 1)

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

	local NudgeMover = function(self, nudgeX, nudgeY)
		local point, anchor, secondaryPoint, x, y = self:GetPoint()
		if not anchor then
			anchor = UIParent
		end
		x = Round(x)
		y = Round(y)

		-- Shift it.
		x = x + (nudgeX or 0)
		y = y + (nudgeY or 0)

		-- Save it.
		SUI.DB.MoveIt.movers[name].MovedPoints = format('%s,%s,%s,%d,%d', point, anchor:GetName(), secondaryPoint, x, y)
		self:ClearAllPoints()
		self:SetPoint(point, anchor, secondaryPoint, x, y)
	end

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

		-- MoveIt:SaveMoverPosition(name)
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
			MoveIt:Reset(name)
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
			f:NudgeMover(nil, delta)
		else
			f:NudgeMover(delta)
		end
	end

	f.NudgeMover = NudgeMover
	f:SetScript('OnDragStart', OnDragStart)
	-- f:SetScript('OnMouseUp', E.AssignFrameToNudge)
	f:SetScript('OnDragStop', OnDragStop)
	f:SetScript('OnEnter', OnEnter)
	f:SetScript('OnMouseDown', OnMouseDown)
	f:SetScript('OnLeave', OnLeave)
	f:SetScript('OnShow', OnShow)
	f:SetScript('OnMouseWheel', OnMouseWheel)

	local function ParentMouseDown(self)
		if IsAltKeyDown() and SUI.DB.MoveIt.AltKey then
			MoveIt:MoveIt(name)
			OnDragStart(self.mover)
		end
	end
	local function ParentMouseUp(self)
		if IsAltKeyDown() and SUI.DB.MoveIt.AltKey and MoveEnabled then
			MoveIt:MoveIt(name)
		end
	end

	parent:SetScript('OnSizeChanged', SizeChanged)
	parent:HookScript('OnMouseDown', ParentMouseDown)
	parent:HookScript('OnMouseUp', ParentMouseUp)
	parent.mover = f

	parent:ClearAllPoints()
	parent:SetPoint('TOPLEFT', f, 0, 0)
end

local function MoveTalkingHead()
	local SetupTalkingHead = function()
		--Prevent WoW from moving the frame around
		TalkingHeadFrame.ignoreFramePositionManager = true
		_G.UIPARENT_MANAGED_FRAME_POSITIONS.TalkingHeadFrame = nil

		THUIHolder:SetSize(TalkingHeadFrame:GetSize())
		MoveIt:CreateMover(THUIHolder, 'THUIHolder', 'Talking Head Frame', true)
		TalkingHeadFrame:HookScript(
			'OnShow',
			function()
				TalkingHeadFrame:ClearAllPoints()
				TalkingHeadFrame:SetPoint('CENTER', THUIHolder, 'CENTER', 0, 0)
			end
		)
	end
	local THUIHolder = CreateFrame('Frame', 'THUIHolder', UIParent)
	THUIHolder:SetPoint('TOP', UIParent, 'TOP', 0, -18)
	THUIHolder:Hide()
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
				_G.TalkingHead_LoadUI()
				SetupTalkingHead()
			end
		)
	end
end

local function MoveAltPowerBar()
	if not IsAddOnLoaded('SimplePowerBar') then
		local holder = CreateFrame('Frame', 'AltPowerBarHolder', UIParent)
		holder:SetPoint('TOP', UIParent, 'TOP', 0, -18)
		holder:SetSize(128, 50)
		holder:Hide()

		_G.PlayerPowerBarAlt:ClearAllPoints()
		_G.PlayerPowerBarAlt:SetPoint('CENTER', holder, 'CENTER')
		_G.PlayerPowerBarAlt:SetParent(holder)
		_G.PlayerPowerBarAlt.ignoreFramePositionManager = true

		hooksecurefunc(
			_G.PlayerPowerBarAlt,
			'ClearAllPoints',
			function(bar)
				bar:SetPoint('CENTER', AltPowerBarHolder, 'CENTER')
			end
		)

		MoveIt:CreateMover(holder, 'AltPowerBarMover', 'Alternative Power')
	end
end

function MoveIt:OnInitialize()
	coordFrame = StdUi:Window(nil, 480, 200)
	coordFrame:SetFrameStrata('DIALOG')

	coordFrame.Title = StdUi:Texture(coordFrame, 104, 30, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	coordFrame.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	coordFrame.Title:SetPoint('TOP')
	coordFrame.Title:SetAlpha(.8)

	-- Create Movers
	if SUI.IsRetail then
		MoveTalkingHead()
		MoveAltPowerBar()
	end
end

function MoveIt:OnEnable()
	local ChatCommand = function(arg)
		if InCombatLockdown() then
			SUI:Print(ERR_NOT_IN_COMBAT)
			return
		end

		if (not arg) then
			MoveIt:MoveIt()
		else
			if MoverList[arg] then
				MoveIt:MoveIt(arg)
			elseif arg == 'reset' then
				SUI:Print('Restting all frames...')
				MoveIt:Reset()
			else
				SUI:Print('Invalid move command!')
			end
		end
	end
	SUI:AddChatCommand('move', ChatCommand)

	local function OnKeyDown(self, key)
		if MoveEnabled and key == 'ESCAPE' then
			self:SetPropagateKeyboardInput(false)
			MoveIt:MoveIt()
		else
			self:SetPropagateKeyboardInput(true)
		end
	end

	MoverWatcher:Hide()
	MoverWatcher:SetFrameStrata('TOOLTIP')
	MoverWatcher:SetScript('OnKeyDown', OnKeyDown)
	MoverWatcher:SetScript('OnKeyDown', OnKeyDown)

	MoveIt:Options()
end

function MoveIt:Options()
	SUI.opt.args['Movers'] = {
		name = 'Movers',
		type = 'group',
		order = 800,
		args = {
			MoveIt = {
				name = 'Toggle movers',
				type = 'execute',
				order = 1,
				func = function()
					MoveIt:MoveIt()
				end
			},
			AltKey = {
				name = 'Allow Alt+Dragging to move',
				type = 'toggle',
				width = 'double',
				order = 2,
				get = function(info)
					return SUI.DB.MoveIt.AltKey
				end,
				set = function(info, val)
					SUI.DB.MoveIt.AltKey = val
				end
			},
			MoveIt = {
				name = 'Reset moved frames',
				type = 'execute',
				order = 3,
				func = function()
					MoveIt:Reset()
				end
			},
			line1 = {name = '', type = 'header', order = 49},
			line2 = {
				name = 'Movement can also be initated with the chat command:',
				type = 'description',
				order = 50,
				fontSize = 'large'
			},
			line3 = {name = '/sui move', type = 'description', order = 51, fontSize = 'medium'},
			line4 = {
				name = '',
				type = 'description',
				order = 52,
				fontSize = 'large'
			},
			line5 = {
				name = 'When the movement system is enabled you can:',
				type = 'description',
				order = 53,
				fontSize = 'large'
			},
			line6 = {name = '- Alt+Click a mover to reset it', type = 'description', order = 53.5, fontSize = 'medium'},
			line7 = {
				name = '- Shift+Click a mover to temporarily hide it',
				type = 'description',
				order = 54,
				fontSize = 'medium'
			},
			line8 = {
				name = '- Use the scroll wheel to move left and right 1 coord at a time',
				type = 'description',
				order = 55,
				fontSize = 'medium'
			},
			line9 = {
				name = '- Use the scroll wheel + Hold Shift to move up and down 1 coord at a time',
				type = 'description',
				order = 56,
				fontSize = 'medium'
			},
			line10 = {
				name = '- Press ESCAPE to exit the movement system quickly.',
				type = 'description',
				order = 57,
				fontSize = 'medium'
			}
		}
	}
end
