local SUI = SUI
local module = SUI:NewModule('Component_MoveIt', 'AceEvent-3.0', 'AceHook-3.0')
local MoverList = {}
local colors = {
	bg = {0.0588, 0.0588, 0, .85},
	border = {0.00, 0.00, 0.00, 1},
	text = {1, 1, 1, 1},
	disabled = {0.55, 0.55, 0.55, 1}
}
local MoveEnabled = false

local function GetPoints(obj)
	local point, anchor, secondaryPoint, x, y = obj:GetPoint()
	if not anchor then
		anchor = UIParent
	end

	return format('%s,%s,%s,%d,%d', point, anchor:GetName(), secondaryPoint, Round(x), Round(y))
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

function module:IsMoved(arg)
	if not SUI.DB.MoveIt.movers[name] then
		return false
	end
	if SUI.DB.MoveIt.movers[name].MovedPoints then
		return true
	end
	return false
end

function module:Reset(arg)
	if arg == '' or arg == nil then
		for name in pairs(MoverList) do
			local f = _G[name]
			local point, anchor, secondaryPoint, x, y = split(',', MoverList[name].point)
			f:ClearAllPoints()
			f:Point(point, anchor, secondaryPoint, x, y)

			for key, value in pairs(MoverList[name]) do
				if key == 'postdrag' and type(value) == 'function' then
					value(f, E:GetScreenQuadrant(f))
				end
			end
		end
		self.db.movers = nil
	else
		for name in pairs(MoverList) do
			for key, value in pairs(MoverList[name]) do
				if key == 'text' then
					if arg == value then
						local f = _G[name]
						local point, anchor, secondaryPoint, x, y = split(',', MoverList[name].point)
						f:ClearAllPoints()
						f:Point(point, anchor, secondaryPoint, x, y)

						if self.db.movers then
							self.db.movers[name] = nil
						end

						if MoverList[name].postdrag ~= nil and type(MoverList[name].postdrag) == 'function' then
							MoverList[name].postdrag(f, E:GetScreenQuadrant(f))
						end
					end
				end
			end
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

function module:CreateMover(parent, name, text)
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
	f.textString = text
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

	if not SUI.DB.MoveIt.movers[name] then
		SUI.DB.MoveIt.movers[name] = {
			defaultPoint = GetPoints(parent)
		}
	end

	if SUI.DB.MoveIt.movers[name].MovedPoints then
		point, anchor, secondaryPoint, x, y = strsplit(',', GetPoints(parent))
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
			E:Print(ERR_NOT_IN_COMBAT)
			return
		end
		isDragging = false
		if E.db.general.stickyFrames then
			Sticky:StopMoving(self)
		else
			self:StopMovingOrSizing()
		end

		local x2, y2, point2 = module:CalculateMoverPoints(self)
		self:ClearAllPoints()
		local overridePoint
		if self.positionOverride then
			if self.positionOverride == 'BOTTOM' or self.positionOverride == 'TOP' then
				overridePoint = 'BOTTOM'
			else
				overridePoint = 'BOTTOMLEFT'
			end
		end

		self:Point(self.positionOverride or point2, UIParent, overridePoint and overridePoint or point2, x2, y2)
		if self.positionOverride then
			self.parent:ClearAllPoints()
			self.parent:Point(self.positionOverride, self, self.positionOverride)
		end

		E:SaveMoverPosition(name)

		-- if ElvUIMoverNudgeWindow then
		-- 	E:UpdateNudgeFrame(self, x, y)
		-- end

		coordFrame.child = nil
		coordFrame:Hide()

		if postdrag ~= nil and (type(postdrag) == 'function') then
			postdrag(self, E:GetScreenQuadrant(self))
		end

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
			if ElvUIMoverNudgeWindow:IsShown() then
				ElvUIMoverNudgeWindow:Hide()
			else
				ElvUIMoverNudgeWindow:Show()
			end
		elseif button == 'RightButton' then
			isDragging = false
			if E.db.general.stickyFrames then
				Sticky:StopMoving(self)
			else
				self:StopMovingOrSizing()
			end

			if IsAltKeyDown() and self.textString then -- Reset anchor
				E:ResetMovers(self.textString)
			elseif IsShiftKeyDown() then -- Allow hiding a mover temporarily
				self:Hide()
			end
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
	parent:SetPoint(point, f, 0, 0)

	if postdrag ~= nil and type(postdrag) == 'function' then
		f:RegisterEvent('PLAYER_ENTERING_WORLD')
		f:SetScript(
			'OnEvent',
			function(self)
				postdrag(f, E:GetScreenQuadrant(f))
				self:UnregisterAllEvents()
			end
		)
	end
end

function module:OnInitialize()
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
	-- SUI:AddChatCommand('moveit', ChatCommand)
end

function module:Options()
end
