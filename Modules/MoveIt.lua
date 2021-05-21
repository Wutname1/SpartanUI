local SUI, L, print = SUI, SUI.L, SUI.print
local StdUi = LibStub('StdUi'):NewInstance()
local MoveIt = SUI:NewModule('Component_MoveIt', 'AceEvent-3.0', 'AceHook-3.0')
MoveIt.description = 'CORE: Is the movement system for SpartanUI'
MoveIt.Core = true
local MoverList = {}
local colors = {
	bg = {0.0588, 0.0588, 0, .85},
	active = {.1, .1, .1, .7},
	border = {0.00, 0.00, 0.00, 1},
	text = {1, 1, 1, 1},
	disabled = {0.55, 0.55, 0.55, 1}
}
local MoverWatcher = CreateFrame('Frame', nil, UIParent)
local MoveEnabled = false
local coordFrame
local anchorPoints = {
	['TOPLEFT'] = 'TOP LEFT',
	['TOP'] = 'TOP',
	['TOPRIGHT'] = 'TOP RIGHT',
	['RIGHT'] = 'RIGHT',
	['CENTER'] = 'CENTER',
	['LEFT'] = 'LEFT',
	['BOTTOMLEFT'] = 'BOTTOM LEFT',
	['BOTTOM'] = 'BOTTOM',
	['BOTTOMRIGHT'] = 'BOTTOM RIGHT'
}
local dynamicAnchorPoints = {
	['UIParent'] = 'Blizzard UI',
	['SpartanUI'] = 'Spartan UI',
	['SUI_BottomAnchor'] = 'SpartanUI Bottom Anchor',
	['SUI_TopAnchor'] = 'SpartanUI Top Anchor'
}

local function GetPoints(obj)
	local point, anchor, secondaryPoint, x, y = obj:GetPoint()
	if not anchor then
		anchor = UIParent
	end

	return format('%s,%s,%s,%d,%d', point, anchor:GetName(), secondaryPoint, Round(x), Round(y))
end

local function CreateGroup(groupName)
	if SUI.opt.args.Movers.args[groupName] then
		return
	end

	SUI.opt.args.Movers.args[groupName] = {
		name = groupName,
		type = 'group',
		args = {}
	}
end

local function AddToOptions(MoverName, DisplayName, groupName, MoverFrame)
	CreateGroup(groupName)
	SUI.opt.args.Movers.args[groupName].args[MoverName] = {
		name = DisplayName,
		type = 'group',
		inline = true,
		args = {
			position = {
				name = L['Position'],
				type = 'group',
				inline = true,
				order = 2,
				args = {
					x = {
						name = L['X Offset'],
						order = 1,
						type = 'input',
						dialogControl = 'NumberEditBox',
						get = function()
							return tostring(select(4, strsplit(',', GetPoints(MoverFrame))))
						end,
						set = function(info, val)
							--Fetch current position
							local point, anchor, secondaryPoint, _, y = strsplit(',', GetPoints(MoverFrame))
							-- Move the frame and update the DB
							MoverFrame.parent:position(point, anchor, secondaryPoint, tonumber(val), y, true)
							MoveIt.DB.movers[MoverName].MovedPoints = format('%s,%s,%s,%s,%s', point, anchor, secondaryPoint, val, y)
						end
					},
					y = {
						name = L['Y Offset'],
						order = 2,
						type = 'input',
						dialogControl = 'NumberEditBox',
						get = function()
							return tostring(select(5, strsplit(',', GetPoints(MoverFrame))))
						end,
						set = function(info, val)
							--Fetch current position
							local point, anchor, secondaryPoint, x, _ = strsplit(',', GetPoints(MoverFrame))
							-- Move the frame and update the DB
							MoverFrame.parent:position(point, anchor, secondaryPoint, x, tonumber(val), true)
							MoveIt.DB.movers[MoverName].MovedPoints = format('%s,%s,%s,%s,%s', point, anchor, secondaryPoint, x, val)
						end
					},
					MyAnchorPoint = {
						order = 3,
						name = L['Point'],
						type = 'select',
						values = anchorPoints,
						get = function()
							return tostring(select(1, strsplit(',', GetPoints(MoverFrame))))
						end,
						set = function(info, val)
							--Fetch current position
							local _, anchor, secondaryPoint, x, y = strsplit(',', GetPoints(MoverFrame))
							-- Move the frame and update the DB
							MoverFrame.parent:position(val, anchor, val, x, y, true)
							MoveIt.DB.movers[MoverName].MovedPoints = format('%s,%s,%s,%s,%s', val, anchor, secondaryPoint, x, y)
						end
					},
					AnchorTo = {
						order = 4,
						name = L['Anchor'],
						type = 'select',
						values = dynamicAnchorPoints,
						get = function()
							local anchor = tostring(select(2, strsplit(',', GetPoints(MoverFrame))))
							if not dynamicAnchorPoints[anchor] then
								dynamicAnchorPoints[anchor] = anchor
							end
							return anchor
						end,
						set = function(info, val)
							--Fetch current position
							local point, _, secondaryPoint, x, y = strsplit(',', GetPoints(MoverFrame))
							-- Move the frame and update the DB
							MoverFrame.parent:position(point, (_G[val] or UIParent), secondaryPoint, x, y, true)
							MoveIt.DB.movers[MoverName].MovedPoints =
								format('%s,%s,%s,%s,%s', point, (_G[val] or UIParent):GetName(), secondaryPoint, x, y)
						end
					},
					ItsAnchorPoint = {
						order = 5,
						name = L['Secondary point'],
						type = 'select',
						values = anchorPoints,
						get = function()
							return tostring(select(3, strsplit(',', GetPoints(MoverFrame))))
						end,
						set = function(info, val)
							--Fetch current position
							local point, anchor, _, x, y = strsplit(',', GetPoints(MoverFrame))
							-- Move the frame and update the DB
							MoverFrame.parent:position(point, anchor, val, x, y, true)
							MoveIt.DB.movers[MoverName].MovedPoints = format('%s,%s,%s,%s,%s', point, anchor, val, x, y)
						end
					}
				}
			},
			ResetPosition = {
				name = L['Reset position'],
				type = 'execute',
				order = 3,
				func = function()
					MoveIt:Reset(MoverName, true)
				end
			},
			scale = {
				name = '',
				type = 'group',
				inline = true,
				order = 4,
				args = {
					scale = {
						name = L['Scale'],
						type = 'range',
						order = 1,
						min = .01,
						max = 1,
						width = 'double',
						step = .01,
						get = function()
							return SUI:round(MoverFrame:GetScale(), 2)
						end,
						set = function(info, val)
							MoveIt.DB.movers[MoverName].AdjustedScale = val
							MoverFrame.parent:scale(val)
						end
					},
					ResetScale = {
						name = L['Reset Scale'],
						type = 'execute',
						order = 2,
						func = function()
							MoverFrame.parent:scale()
							MoveIt.DB.movers[MoverName].AdjustedScale = false
						end
					}
				}
			}
		}
	}
end

function MoveIt:CalculateMoverPoints(mover)
	local screenWidth, screenHeight, screenCenter = UIParent:GetRight(), UIParent:GetTop(), UIParent:GetCenter()
	local x, y = mover:GetCenter()

	local LEFT = screenWidth / 3
	local RIGHT = screenWidth * 2 / 3
	local TOP = screenHeight / 2
	local point, InversePoint

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
	if not MoveIt.DB.movers[name] then
		return false
	end
	if MoveIt.DB.movers[name].MovedPoints then
		return true
	end
	if MoveIt.DB.movers[name].AdjustedScale then
		return true
	end
	return false
end

function MoveIt:Reset(name, onlyPosition)
	if name == nil then
		for name, frame in pairs(MoverList) do
			MoveIt:Reset(name)
		end
		print('Moved frames reset!')
	else
		local frame = _G['SUI_Mover_' .. name]
		if frame and MoveIt:IsMoved(name) then
			-- Reset the scale
			if MoveIt.DB.movers[name].AdjustedScale and not onlyPosition then
				MoveIt.DB.movers[name].AdjustedScale = nil

				frame:SetScale(frame.defaultScale or 1)
				frame.parent:SetScale(frame.defaultScale or 1)
				frame.ScaledText:Hide()
			end

			-- Reset Position
			local point, anchor, secondaryPoint, x, y = strsplit(',', MoverList[name].defaultPoint)
			frame:ClearAllPoints()
			frame:SetPoint(point, anchor, secondaryPoint, x, y)

			if MoveIt.DB.movers[name].MovedPoints then
				MoveIt.DB.movers[name].MovedPoints = nil
			end

			-- Hide Moved Text
			frame.MovedText:Hide()
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
	-- This allows us to assign a new object to be used to assign the mover's size
	-- Removing this breaks the positioning of objects when the wow window is resized as it triggers the SizeChanged event.
	if mover.parent ~= obj then
		mover.updateObj = obj
	end

	local f = (obj or mover.updateObj or mover.parent)
	mover:SetSize(f:GetWidth(), f:GetHeight())
	if not doNotScale then
		mover:SetScale(f:GetScale())
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
			if type(name) == 'string' then
				local frame = MoverList[name]
				frame:Show()
			else
				for _, v in pairs(name) do
					if MoverList[v] then
						local frame = MoverList[v]
						frame:Show()
					end
				end
			end
		else
			for _, v in pairs(MoverList) do
				v:Show()
			end
			if MoveIt.DB.tips then
				print('When the movement system is enabled you can:')
				print('     Shift+Click a mover to temporarily hide it', true)
				print("     Alt+Click a mover to reset it's position", true)
				print("     Control+Click a mover to reset it's scale", true)
				print(' ', true)
				print('     Use the scroll wheel to move left and right 1 coord at a time', true)
				print('     Hold Shift + use the scroll wheel to move up and down 1 coord at a time', true)
				print('     Hold Alt + use the scroll wheel to scale the frame', true)
				print(' ', true)
				print('     Press ESCAPE to exit the movement system quickly.', true)
				print("Use the command '/sui move tips' to disable tips")
				print("Use the command '/sui move reset' to reset ALL moved items")
			end
		end
		MoveEnabled = true
		MoverWatcher:Show()
	end
	MoverWatcher:EnableKeyboard(MoveEnabled)
end

local isDragging = false

function MoveIt:CreateMover(parent, name, DisplayName, postdrag, groupName)
	if SUI.DB.DisabledComponents.MoveIt then
		return
	end
	-- If for some reason the parent does not exist or we have already done this exit out
	if not parent or MoverList[name] then
		return
	end
	if DisplayName == nil then
		DisplayName = name
	end

	local point, anchor, secondaryPoint, x, y = strsplit(',', GetPoints(parent))

	--Use dirtyWidth / dirtyHeight to set initial size if possible
	local width = parent.dirtyWidth or parent:GetWidth()
	local height = parent.dirtyHeight or parent:GetHeight()

	local f = CreateFrame('Button', 'SUI_Mover_' .. name, UIParent, BackdropTemplateMixin and 'BackdropTemplate')
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
	f.DisplayName = DisplayName
	f.postdrag = postdrag
	f.defaultScale = (parent:GetScale() or 1)
	f.defaultPoint = GetPoints(parent)

	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:SetFrameStrata('DIALOG')

	MoverList[name] = f

	local nameText = f:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(nameText, 12, 'Mover')
	nameText:SetJustifyH('CENTER')
	nameText:SetPoint('CENTER')
	nameText:SetText(DisplayName or name)
	nameText:SetTextColor(unpack(colors.text))
	f:SetFontString(nameText)
	f.DisplayName = nameText

	local MovedText = f:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(MovedText, 8, 'Mover')
	MovedText:SetJustifyH('CENTER')
	MovedText:SetPoint('TOPRIGHT', nameText, 'BOTTOM', -2, -2)
	MovedText:SetText('(MOVED)')
	MovedText:SetTextColor(unpack(colors.text))
	-- f:SetFontString(MovedText)
	MovedText:Hide()
	f.MovedText = MovedText

	local ScaledText = f:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(ScaledText, 8, 'Mover')
	ScaledText:SetJustifyH('CENTER')
	ScaledText:SetPoint('TOPLEFT', nameText, 'BOTTOM', 2, -2)
	ScaledText:SetText('(SCALED)')
	ScaledText:SetTextColor(unpack(colors.text))
	-- f:SetFontString(ScaledText)
	ScaledText:Hide()
	f.ScaledText = ScaledText

	f:SetScale(MoveIt.DB.movers[name].AdjustedScale or parent:GetScale() or 1)
	if MoveIt.DB.movers[name].AdjustedScale then
		ScaledText:Show()
		parent:SetScale(MoveIt.DB.movers[name].AdjustedScale)
	end

	if MoveIt.DB.movers[name].MovedPoints then
		MovedText:Show()
		point, anchor, secondaryPoint, x, y = strsplit(',', MoveIt.DB.movers[name].MovedPoints)
	end
	f:ClearAllPoints()
	f:SetPoint(point, anchor, secondaryPoint, x, y)

	local function SaveMoverPosition()
		MoveIt.DB.movers[name].MovedPoints = GetPoints(f)
		f.MovedText:Show()

		-- Reset the frame so we dont anchor to nil after moving
		-- Without this the minimap cause LUA errors in a vehicle
		if f.parent.position then
			local point, anchor, secondaryPoint, x, y = strsplit(',', MoveIt.DB.movers[name].MovedPoints)
			f.parent:position(point, anchor, secondaryPoint, x, y, true)
		end
	end

	local Scale = function(self, ammount)
		local Current = self:GetScale()
		local NewScale = Current + (ammount or 0)

		self:SetScale(NewScale)
		self.parent:SetScale(NewScale)
		if scale == f.defaultScale then
			ScaledText:Hide()
		else
			ScaledText:Show()
		end

		MoveIt.DB.movers[name].AdjustedScale = NewScale
	end

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
		self:ClearAllPoints()
		self:SetPoint(point, anchor, secondaryPoint, x, y)
		SaveMoverPosition()
	end

	local function OnDragStart(self)
		if InCombatLockdown() then
			print(ERR_NOT_IN_COMBAT)
			return
		end

		self:StartMoving()

		coordFrame.child = self
		coordFrame:Show()
		isDragging = true
	end

	local function OnDragStop(self)
		if InCombatLockdown() then
			print(ERR_NOT_IN_COMBAT)
			return
		end
		isDragging = false
		-- if db.stickyFrames then
		-- 	Sticky:StopMoving(self)
		-- else
		self:StopMovingOrSizing()
		-- end

		SaveMoverPosition()
		-- MoveIt.DB.movers[name].MovedPoints = GetPoints(f)

		-- Reset the frame so we dont anchor to nil after moving
		-- Without this the minimap cause LUA errors in a vehicle
		-- if parent.position then
		-- 	local point, anchor, secondaryPoint, x, y = strsplit(',', MoveIt.DB.movers[name].MovedPoints)
		-- 	parent:position(point, anchor, secondaryPoint, x, y, true)
		-- end
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
		self:SetBackdropColor(unpack(colors.active))
		self.DisplayName:SetTextColor(1, 1, 1)
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
			if MoveIt.DB.tips then
				print("Tip use the chat command '/sui move reset' to reset everything quickly.")
			end
		elseif IsControlKeyDown() then -- Reset Scale to default
			self:SetScale(self.defaultScale)
			self.parent:SetScale(self.defaultScale)
			ScaledText:Hide()

			MoveIt.DB.movers[name].AdjustedScale = false
		elseif IsShiftKeyDown() then -- Allow hiding a mover temporarily
			self:Hide()
			print(self.name .. ' hidden temporarily.')
		end
	end

	local function OnLeave(self)
		if isDragging then
			return
		end
		self:SetBackdropColor(unpack(colors.bg))
	end

	local function OnShow(self)
		self:SetBackdropBorderColor(unpack(colors.bg))
	end

	local function OnMouseWheel(_, delta)
		if IsAltKeyDown() then
			f:Scale((delta / 100))
		elseif IsShiftKeyDown() then
			f:NudgeMover(nil, delta)
		else
			f:NudgeMover(delta)
		end
	end

	f.Scale = Scale
	f.NudgeMover = NudgeMover
	f:SetScript('OnDragStart', OnDragStart)
	f:SetScript('OnDragStop', OnDragStop)
	f:SetScript('OnEnter', OnEnter)
	f:SetScript('OnMouseDown', OnMouseDown)
	f:SetScript('OnLeave', OnLeave)
	f:SetScript('OnShow', OnShow)
	f:SetScript('OnMouseWheel', OnMouseWheel)

	local function ParentMouseDown(self)
		if IsAltKeyDown() and MoveIt.DB.AltKey then
			MoveIt:MoveIt(name)
			OnDragStart(self.mover)
		end
	end
	local function ParentMouseUp(self)
		if IsAltKeyDown() and MoveIt.DB.AltKey and MoveEnabled then
			MoveIt:MoveIt(name)
			OnDragStop(self.mover)
		end
	end
	local function scale(self, scale, setDefault, forced)
		if setDefault then
			f.defaultScale = scale
		end

		-- If the frame has been moved and we are not focing the movement exit
		if MoveIt.DB.movers[name].AdjustedScale and not forced then
			return
		end

		f:SetScale(max((scale or f.defaultScale), .01))
		if f.OnScale then
			f.OnScale:SetScale(max((scale or f.defaultScale), .01))
		end
		parent:SetScale(max((scale or f.defaultScale), .01))
		if scale == f.defaultScale then
			ScaledText:Hide()
		else
			ScaledText:Show()
		end

		local point, anchor, secondaryPoint, x, y = strsplit(',', f.defaultPoint)

		if MoveIt.DB.movers[name].MovedPoints then
			point, anchor, secondaryPoint, x, y = strsplit(',', MoveIt.DB.movers[name].MovedPoints)
		end
		f:ClearAllPoints()
		f:SetPoint(point, anchor, secondaryPoint, x, y)
	end
	local function position(self, point, anchor, secondaryPoint, x, y, forced, defaultPos)
		-- If Frame:position() was called just make sure we are anchored properly
		if not point then
			self:ClearAllPoints()
			self:SetPoint('TOPLEFT', self.mover, 0, 0)
			return
		end

		-- If the frame has been moved and we are not focing the movement exit
		if MoveIt.DB.movers[name].MovedPoints and not forced then
			return
		end

		-- Position frame
		f:ClearAllPoints()
		f:SetPoint(point, (anchor or UIParent), (secondaryPoint or point), (x or 0), (y or 0))

		if defaultPos then
			f.defaultPoint = GetPoints(f)
		end
	end
	local function SizeChanged(frame)
		if InCombatLockdown() then
			return
		end
		if frame.mover.updateObj then
			frame.mover:SetSize(frame.mover.updateObj:GetSize())
		else
			frame.mover:SetSize(frame:GetSize())
		end
	end

	parent:SetScript('OnSizeChanged', SizeChanged)
	parent:HookScript('OnMouseDown', ParentMouseDown)
	parent:HookScript('OnMouseUp', ParentMouseUp)
	parent.mover = f
	parent.scale = scale
	parent.position = position
	parent.isMoved = function()
		if MoveIt.DB.movers[name].MovedPoints then
			return true
		end
		return false
	end

	parent:ClearAllPoints()
	parent:SetPoint('TOPLEFT', f, 0, 0)

	AddToOptions(name, DisplayName, (groupName or 'General'), f)
end

function MoveIt:OnInitialize()
	local defaults = {
		profile = {
			AltKey = false,
			tips = true,
			movers = {
				['**'] = {
					defaultPoint = false,
					MovedPoints = false
				}
			}
		}
	}
	MoveIt.Database = SUI.SpartanUIDB:RegisterNamespace('MoveIt', defaults)
	MoveIt.DB = MoveIt.Database.profile

	-- Migrate old settings
	if SUI.DB.MoveIt then
		print('MoveIt DB Migration')
		MoveIt.DB = SUI:MergeData(MoveIt.DB, SUI.DB.MoveIt, true)
		SUI.DB.MoveIt = nil
	end

	--Build Options
	MoveIt:Options()

	-- Build Coord Frame
	coordFrame = StdUi:Window(nil, 480, 200)
	coordFrame:SetFrameStrata('DIALOG')

	coordFrame.Title = StdUi:Texture(coordFrame, 104, 30, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	coordFrame.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	coordFrame.Title:SetPoint('TOP')
	coordFrame.Title:SetAlpha(.8)
end

function MoveIt:CombatLockdown()
	if MoveEnabled then
		MoveIt:MoveIt()
		print('Disabling movement system while in combat')
	end
end

function MoveIt:OnEnable()
	if SUI:IsModuleDisabled('MoveIt') then
		return
	end

	local ChatCommand = function(arg)
		if InCombatLockdown() then
			print(ERR_NOT_IN_COMBAT)
			return
		end

		if (not arg) then
			MoveIt:MoveIt()
		else
			if MoverList[arg] then
				MoveIt:MoveIt(arg)
			elseif arg == 'reset' then
				print('Restting all frames...')
				MoveIt:Reset()
				return
			elseif arg == 'tips' then
				MoveIt.DB.tips = not (MoveIt.DB.tips)
				local mode = '|cffed2024off'
				if MoveIt.DB.tips then
					mode = '|cff69bd45on'
				end

				print('Tips turned ' .. mode)
			else
				print('Invalid move command!')
				return
			end
		end
	end
	SUI:AddChatCommand(
		'move',
		ChatCommand,
		"|cffffffffSpartan|cffe21f1fUI|r's movement system",
		{
			reset = 'Reset all moved objects',
			tips = 'Disable tips from being displayed in chat when movement system is activated'
		},
		nil,
		true
	)

	local function OnKeyDown(self, key)
		if MoveEnabled and key == 'ESCAPE' then
			if InCombatLockdown() then
				self:SetPropagateKeyboardInput(true)
				return
			end
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

	self:RegisterEvent('PLAYER_REGEN_DISABLED', 'CombatLockdown')
end

function MoveIt:Options()
	SUI.opt.args['Movers'] = {
		name = L['Movers'],
		type = 'group',
		order = 800,
		args = {
			MoveIt = {
				name = L['Toggle movers'],
				type = 'execute',
				order = 1,
				func = function()
					MoveIt:MoveIt()
				end
			},
			AltKey = {
				name = L['Allow Alt+Dragging to move frames'],
				type = 'toggle',
				width = 'double',
				order = 2,
				get = function(info)
					return MoveIt.DB.AltKey
				end,
				set = function(info, val)
					MoveIt.DB.AltKey = val
				end
			},
			ResetIt = {
				name = L['Reset moved frames'],
				type = 'execute',
				order = 3,
				func = function()
					MoveIt:Reset()
				end
			},
			line1 = {name = '', type = 'header', order = 49},
			line2 = {
				name = L['Movement can also be initated with the chat command:'],
				type = 'description',
				order = 50,
				fontSize = 'large'
			},
			line3 = {name = '/sui move', type = 'description', order = 51, fontSize = 'medium'},
			line22 = {name = '', type = 'header', order = 51.1},
			line4 = {
				name = '',
				type = 'description',
				order = 52,
				fontSize = 'large'
			},
			line5 = {
				name = L['When the movement system is enabled you can:'],
				type = 'description',
				order = 53,
				fontSize = 'large'
			},
			line6 = {name = '- ' .. L['Alt+Click a mover to reset it'], type = 'description', order = 53.5, fontSize = 'medium'},
			line7 = {
				name = '- ' .. L['Shift+Click a mover to temporarily hide it'],
				type = 'description',
				order = 54,
				fontSize = 'medium'
			},
			line7a = {
				name = "- Control+Click a mover to reset it's scale",
				type = 'description',
				order = 54.2,
				fontSize = 'medium'
			},
			line7b = {name = '', type = 'description', order = 54.99, fontSize = 'medium'},
			line8 = {
				name = '- ' .. L['Use the scroll wheel to move left and right 1 coord at a time'],
				type = 'description',
				order = 55,
				fontSize = 'medium'
			},
			line9 = {
				name = '- ' .. L['Hold Shift + use the scroll wheel to move up and down 1 coord at a time'],
				type = 'description',
				order = 56,
				fontSize = 'medium'
			},
			line9a = {
				name = '- ' .. L['Hold Alt + use the scroll wheel to scale the frame'],
				type = 'description',
				order = 56.5,
				fontSize = 'medium'
			},
			line10 = {
				name = '- ' .. L['Press ESCAPE to exit the movement system quickly.'],
				type = 'description',
				order = 57,
				fontSize = 'medium'
			},
			tips = {
				name = L['Display tips when using /sui move'],
				type = 'toggle',
				width = 'double',
				order = 70,
				get = function(info)
					return MoveIt.DB.tips
				end,
				set = function(info, val)
					MoveIt.DB.tips = val
				end
			}
		}
	}
end
