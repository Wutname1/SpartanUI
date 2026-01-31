local SUI, L, print = SUI, SUI.L, SUI.print
---@class MoveIt : AceAddon, AceHook-3.0
local MoveIt = SUI:NewModule('MoveIt', 'AceHook-3.0') ---@type SUI.Module
MoveIt.description = 'CORE: Is the movement system for SpartanUI'
MoveIt.Core = true
SUI.MoveIt = MoveIt
local MoverList = {}
local colors = {
	bg = { 0.0588, 0.0588, 0, 0.85 },
	active = { 0.1, 0.1, 0.1, 0.7 },
	border = { 0.00, 0.00, 0.00, 1 },
	text = { 1, 1, 1, 1 },
	disabled = { 0.55, 0.55, 0.55, 1 },
}
local MoverWatcher = CreateFrame('Frame', nil, UIParent)
local MoveEnabled = false
local anchorPoints = {
	['TOPLEFT'] = 'TOP LEFT',
	['TOP'] = 'TOP',
	['TOPRIGHT'] = 'TOP RIGHT',
	['RIGHT'] = 'RIGHT',
	['CENTER'] = 'CENTER',
	['LEFT'] = 'LEFT',
	['BOTTOMLEFT'] = 'BOTTOM LEFT',
	['BOTTOM'] = 'BOTTOM',
	['BOTTOMRIGHT'] = 'BOTTOM RIGHT',
}
local dynamicAnchorPoints = {
	['UIParent'] = 'Blizzard UI',
	['SpartanUI'] = 'Spartan UI',
	['SUI_BottomAnchor'] = 'SpartanUI Bottom Anchor',
	['SUI_TopAnchor'] = 'SpartanUI Top Anchor',
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
		args = {},
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
						end,
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
						end,
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
						end,
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
							MoveIt.DB.movers[MoverName].MovedPoints = format('%s,%s,%s,%s,%s', point, (_G[val] or UIParent):GetName(), secondaryPoint, x, y)
						end,
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
						end,
					},
				},
			},
			ResetPosition = {
				name = L['Reset position'],
				type = 'execute',
				order = 3,
				func = function()
					MoveIt:Reset(MoverName, true)
				end,
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
						min = 0.01,
						max = 2,
						width = 'double',
						step = 0.01,
						get = function()
							return SUI:round(MoverFrame:GetScale(), 2)
						end,
						set = function(info, val)
							MoveIt.DB.movers[MoverName].AdjustedScale = val
							MoverFrame.parent:scale(val, false, true)
						end,
					},
					ResetScale = {
						name = L['Reset Scale'],
						type = 'execute',
						order = 2,
						func = function()
							MoverFrame.parent:scale()
							MoveIt.DB.movers[MoverName].AdjustedScale = nil
						end,
					},
				},
			},
		},
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
		if frame and MoveIt:IsMoved(name) and MoveIt.DB.movers[name] then
			-- Reset Position
			local point, anchor, secondaryPoint, x, y = strsplit(',', MoverList[name].defaultPoint)
			frame:ClearAllPoints()
			frame:SetPoint(point, anchor, secondaryPoint, x, y)

			if onlyPosition or not MoveIt.DB.movers[name].AdjustedScale then
				MoveIt.DB.movers[name].MovedPoints = nil
			else
				-- Reset the scale
				if MoveIt.DB.movers[name].AdjustedScale and not onlyPosition then
					frame:SetScale(frame.defaultScale or 1)
					frame.parent:SetScale(frame.defaultScale or 1)
					frame.ScaledText:Hide()
				end
				-- Clear element
				MoveIt.DB.movers[name] = nil
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

function MoveIt:UnlockAll()
	-- Skip if migration is in progress (wizard is applying changes)
	if MoveIt.WizardPage and MoveIt.WizardPage:IsMigrationInProgress() then
		if MoveIt.logger then
			MoveIt.logger.debug('UnlockAll: Suppressed during migration')
		end
		return
	end

	for _, v in pairs(MoverList) do
		v:Show()
	end
	MoveEnabled = true
	MoverWatcher:Show()
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

function MoveIt:LockAll()
	for _, v in pairs(MoverList) do
		v:Hide()
	end
	MoveEnabled = false
	MoverWatcher:Hide()
end

function MoveIt:MoveIt(name)
	if MoveEnabled and not name then
		MoveIt:LockAll()
	else
		if name then
			if type(name) == 'string' then
				local frame = MoverList[name]
				if not frame:IsVisible() then
					frame:Show()
				else
					frame:Hide()
				end
			else
				for _, v in pairs(name) do
					if MoverList[v] then
						local frame = MoverList[v]
						frame:Show()
					end
				end
			end
		else
			MoveIt:UnlockAll()
		end
	end
	MoverWatcher:EnableKeyboard(MoveEnabled)
end

local isDragging = false

---@class SUI.MoveIt.MoverParent : Frame, SUI.MoveIt.parentMixin
local parentFrameTemp = {}

---@param parent SUI.MoveIt.MoverParent
---@param name string
---@param DisplayName? string
---@param postdrag? function
---@param groupName? string
---@param widgets? table Ace3-style widget definitions for the settings panel
---@return nil
function MoveIt:CreateMover(parent, name, DisplayName, postdrag, groupName, widgets)
	if SUI:IsModuleDisabled('MoveIt') then
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

	---@class SUI.MoveIt.Mover : Frame, BackdropTemplate
	local f = CreateFrame('Button', 'SUI_Mover_' .. name, UIParent, BackdropTemplateMixin and 'BackdropTemplate')
	f:SetClampedToScreen(true)
	f:RegisterForDrag('LeftButton', 'RightButton')
	f:EnableMouseWheel(true)
	f:SetMovable(true)
	f:SetSize(width, height)

	f:SetBackdrop({
		bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
		edgeFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
		edgeSize = 1,
	})
	f:SetBackdropColor(unpack(colors.bg))
	f:SetBackdropBorderColor(unpack(colors.border))

	f:Hide()
	f.parent = parent
	f.name = name
	f.DisplayName = DisplayName
	f.postdrag = postdrag
	f.defaultScale = (parent:GetScale() or 1)
	f.defaultPoint = GetPoints(parent)
	f.widgets = widgets -- Ace3-style widget definitions for settings panel

	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:SetFrameStrata('DIALOG')

	MoverList[name] = f

	-- Register frame with magnetism manager if available
	if MoveIt.MagnetismManager then
		MoveIt.MagnetismManager:RegisterFrame(f)
	end

	local nameText = f:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(nameText, 12, 'Mover')
	nameText:SetJustifyH('CENTER')
	nameText:SetPoint('CENTER')
	nameText:SetText(DisplayName or name)
	nameText:SetTextColor(unpack(colors.text))
	f:SetFontString(nameText)
	f.DisplayName = nameText

	local MovedText = f:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(MovedText, 8, 'Mover')
	MovedText:SetJustifyH('CENTER')
	MovedText:SetPoint('TOPRIGHT', nameText, 'BOTTOM', -2, -2)
	MovedText:SetText('(MOVED)')
	MovedText:SetTextColor(unpack(colors.text))
	MovedText:Hide()
	f.MovedText = MovedText

	local ScaledText = f:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(ScaledText, 8, 'Mover')
	ScaledText:SetJustifyH('CENTER')
	ScaledText:SetPoint('TOPLEFT', nameText, 'BOTTOM', 2, -2)
	ScaledText:SetText('(SCALED)')
	ScaledText:SetTextColor(unpack(colors.text))
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
		local savedPoints = GetPoints(f)
		MoveIt.DB.movers[name].MovedPoints = savedPoints
		f.MovedText:Show()

		if MoveIt.logger then
			MoveIt.logger.debug(('SaveMoverPosition %s: saved as %s'):format(name, savedPoints))
		end

		-- Debug: Hook SetPoint temporarily to catch unexpected repositioning
		if name == 'pet' and MoveIt.logger then
			local originalSetPoint = f.SetPoint
			f.SetPoint = function(self, ...)
				MoveIt.logger.debug(
					('HOOK: SetPoint called on %s after save: %s,%s,%s,%s,%s'):format(
						name,
						tostring(select(1, ...)),
						tostring(select(2, ...)),
						tostring(select(3, ...)),
						tostring(select(4, ...)),
						tostring(select(5, ...))
					)
				)
				MoveIt.logger.debug(('HOOK: Stack trace: %s'):format(debugstack(2, 3, 3)))
				return originalSetPoint(self, ...)
			end
			-- Remove hook after 5 seconds
			C_Timer.After(5, function()
				f.SetPoint = originalSetPoint
				if MoveIt.logger then
					MoveIt.logger.debug(('HOOK: Removed SetPoint hook from %s'):format(name))
				end
			end)
		end
	end

	local Scale = function(self, ammount)
		local Current = self:GetScale()
		local NewScale = Current + (ammount or 0)

		-- Simply apply scale - don't try to adjust position
		-- The frame scales from its anchor point (CENTER), so position stays stable
		self:SetScale(NewScale)
		self.parent:SetScale(NewScale)

		-- Save the user's scale adjustment to DB
		MoveIt.DB.movers[name].AdjustedScale = NewScale

		-- Only hide the indicator if user resets to default scale
		if NewScale == f.defaultScale then
			MoveIt.DB.movers[name].AdjustedScale = nil
			ScaledText:Hide()
		else
			ScaledText:Show()
		end
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

		isDragging = true

		-- Initialize magnetism for this drag session
		local MagnetismManager = MoveIt.MagnetismManager
		if MagnetismManager and MagnetismManager.enabled then
			MagnetismManager:BeginDragSession(self)
		end

		-- Create OnUpdate frame for continuous snap detection during drag
		if not self.dragUpdateFrame then
			self.dragUpdateFrame = CreateFrame('Frame')
		end
		self.dragUpdateFrame:SetScript('OnUpdate', function()
			if MagnetismManager and MagnetismManager.enabled then
				local snapInfo = MagnetismManager:CheckForSnaps(self)
				if snapInfo then
					MagnetismManager:ShowPreviewLines(snapInfo)
				else
					MagnetismManager:HidePreviewLines()
				end
			end

			-- Update settings panel position display during drag
			local SettingsPanel = MoveIt.SettingsPanel
			if SettingsPanel and SettingsPanel.nudgeWidget and SettingsPanel.nudgeWidget.UpdatePositionDisplay then
				SettingsPanel.nudgeWidget:UpdatePositionDisplay()
			end
		end)
	end

	local function OnDragStop(self)
		if InCombatLockdown() then
			print(ERR_NOT_IN_COMBAT)
			return
		end
		isDragging = false

		-- Stop OnUpdate for snap detection
		if self.dragUpdateFrame then
			self.dragUpdateFrame:SetScript('OnUpdate', nil)
		end

		-- Get position BEFORE StopMovingOrSizing changes it
		-- GetCenterOffset returns where the frame's center is relative to UIParent center
		local preStopX, preStopY = MoveIt.PositionCalculator:GetCenterOffset(self)

		if MoveIt.logger then
			local point, anchor, secondaryPoint, x, y = self:GetPoint()
			local anchorName = anchor and anchor:GetName() or 'nil'
			MoveIt.logger.debug(
				('OnDragStop %s: before StopMovingOrSizing anchor=%s,%s,%s,%.1f,%.1f centerOffset=%.1f,%.1f'):format(
					self.name or 'unknown',
					point or 'nil',
					anchorName,
					secondaryPoint or 'nil',
					x or 0,
					y or 0,
					preStopX or 0,
					preStopY or 0
				)
			)
		end

		self:StopMovingOrSizing()

		-- Apply final snap if within range (may anchor to another frame)
		local MagnetismManager = MoveIt.MagnetismManager
		local wasSnappedToFrame = false
		if MagnetismManager and MagnetismManager.enabled then
			wasSnappedToFrame = MagnetismManager:ApplyFinalSnap(self)
			MagnetismManager:EndDragSession()
		end

		-- If not snapped to another frame, normalize to CENTER anchor for consistency
		if not wasSnappedToFrame then
			-- Use the position from BEFORE StopMovingOrSizing
			if preStopX and preStopY then
				if MoveIt.logger then
					local moverScale = self:GetEffectiveScale()
					local parentScale = self.parent and self.parent:GetEffectiveScale() or 1
					local uiScale = UIParent:GetEffectiveScale()
					MoveIt.logger.debug(
						('OnDragStop %s: setting CENTER anchor to %.1f,%.1f (moverScale=%.3f parentScale=%.3f uiScale=%.3f)'):format(
							self.name or 'unknown',
							preStopX,
							preStopY,
							moverScale,
							parentScale,
							uiScale
						)
					)
				end
				self:ClearAllPoints()
				self:SetPoint('CENTER', UIParent, 'CENTER', preStopX, preStopY)

				-- Verify position after setting
				if MoveIt.logger then
					local point, anchor, secondaryPoint, x, y = self:GetPoint()
					local anchorName = anchor and anchor:GetName() or 'nil'
					MoveIt.logger.debug(('OnDragStop %s: after SetPoint verify=%s,%s,%s,%.1f,%.1f'):format(self.name or 'unknown', point or 'nil', anchorName, secondaryPoint or 'nil', x or 0, y or 0))
				end
			end
		end

		SaveMoverPosition()

		self:SetUserPlaced(false)

		-- Update settings panel position display after drag
		local SettingsPanel = MoveIt.SettingsPanel
		if SettingsPanel and SettingsPanel.nudgeWidget and SettingsPanel.nudgeWidget.UpdatePositionDisplay then
			SettingsPanel.nudgeWidget:UpdatePositionDisplay()
		end
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

			MoveIt.DB.movers[name].AdjustedScale = nil
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

	local DragMoving = false
	local function ParentMouseDown(self)
		if IsAltKeyDown() and MoveIt.DB.AltKey then
			OnDragStart(self.mover)
			DragMoving = true
		end
	end
	local function ParentMouseUp(self)
		if DragMoving then
			OnDragStop(self.mover)
		end
	end
	local function scale(self, scale, setDefault, forced)
		if setDefault then
			f.defaultScale = scale
		end

		-- If user has adjusted scale and we're not forcing, don't change anything
		if MoveIt.DB.movers[name].AdjustedScale and not forced then
			if MoveIt.logger then
				MoveIt.logger.debug(('scale() for %s: skipped due to AdjustedScale'):format(name))
			end
			return
		end

		-- IMPORTANT: If the frame has been MOVED, we should not change its scale
		-- because the saved coordinates were calculated at the current scale.
		-- Changing scale would make those coordinates represent a different position.
		if MoveIt.DB.movers[name].MovedPoints and not forced then
			if MoveIt.logger then
				MoveIt.logger.debug(('scale() for %s: skipped due to MovedPoints'):format(name))
			end
			return
		end

		f:SetScale(max((scale or f.defaultScale), 0.01))
		if f.OnScale then
			f.OnScale:SetScale(max((scale or f.defaultScale), 0.01))
		end
		parent:SetScale(max((scale or f.defaultScale), 0.01))

		-- Only show scaled indicator if user has actually adjusted the scale
		-- Not when themes or other internal systems change it programmatically
		if MoveIt.DB.movers[name].AdjustedScale then
			ScaledText:Show()
		else
			ScaledText:Hide()
		end

		local point, anchor, secondaryPoint, x, y = strsplit(',', f.defaultPoint)

		if MoveIt.DB.movers[name].MovedPoints then
			point, anchor, secondaryPoint, x, y = strsplit(',', MoveIt.DB.movers[name].MovedPoints)
		end

		-- Ensure x and y are numbers (strsplit returns strings)
		x = tonumber(x) or 0
		y = tonumber(y) or 0

		if MoveIt.logger then
			MoveIt.logger.debug(('scale() for %s: repositioning to %s,%s,%s,%.1f,%.1f'):format(name, point or 'nil', anchor or 'nil', secondaryPoint or 'nil', x, y))
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

		-- If the frame has been moved and we are not forcing the movement, exit
		if MoveIt.DB.movers[name].MovedPoints and not forced then
			return
		end

		-- Position frame
		f:ClearAllPoints()
		f:SetPoint(point, (anchor or UIParent), (secondaryPoint or point), (x or 0), (y or 0))

		-- Register frame relationships for magnetism (for non-unit-frame movers)
		-- Unit frames register their relationships separately after all movers are created
		if anchor and anchor ~= UIParent and self.mover and MoveIt.MagnetismManager then
			local anchorFrame = anchor
			if type(anchor) == 'string' then
				anchorFrame = _G[anchor]
			end

			if anchorFrame and anchorFrame.mover then
				MoveIt.MagnetismManager:RegisterFrameRelationship(self.mover, anchorFrame.mover)
			end
		end

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

	hooksecurefunc(parent, 'SetSize', SizeChanged)
	hooksecurefunc(parent, 'SetHeight', SizeChanged)
	hooksecurefunc(parent, 'SetWidth', SizeChanged)

	parent:HookScript('OnMouseDown', ParentMouseDown)
	parent:HookScript('OnMouseUp', ParentMouseUp)
	---@class SUI.MoveIt.parentMixin
	local parentMixin = {
		scale = scale,
		position = position,
		mover = f,
		dirtyWidth = 0,
		dirtyHeight = 0,
	}
	for k, v in pairs(parentMixin) do
		parent[k] = v
	end
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

function MoveIt:RegisterExternalMover(mover, name)
	if not mover or not name then
		return
	end

	if not MoverList[name] then
		MoverList[name] = mover
		mover.name = name

		return true
	end
	return false
end

function MoveIt:CreateCustomMover(displayName, defaultPosition, config)
	-- Generate a unique name based on the display name
	local name = 'SUI_CustomMover_' .. displayName:gsub('%s+', '')

	-- Default configuration options
	local cfg = {
		width = 180,
		height = 180,
		colors = {
			bg = { 0.2, 0.0, 0.0, 0.85 }, -- Reddish background to distinguish from regular movers
			active = { 0.3, 0.1, 0.1, 0.7 },
			border = { 0.5, 0.0, 0.0, 1 },
			text = { 1, 1, 1, 1 },
		},
		onPositionChanged = nil, -- Callback function
		savePosition = nil, -- Function to handle position saving
		onHide = nil, -- Function called when mover is hidden
	}

	-- Override defaults with any provided config
	if config then
		for k, v in pairs(config) do
			cfg[k] = v
		end
	end

	-- Create the mover frame
	local mover = CreateFrame('Button', name, UIParent, BackdropTemplateMixin and 'BackdropTemplate')
	mover:SetClampedToScreen(true)
	mover:RegisterForDrag('LeftButton', 'RightButton')
	mover:EnableMouseWheel(true)
	mover:SetMovable(true)
	mover:SetSize(cfg.width, cfg.height)

	mover:SetBackdrop({
		bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
		edgeFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
		edgeSize = 1,
	})
	mover:SetBackdropColor(unpack(cfg.colors.bg))
	mover:SetBackdropBorderColor(unpack(cfg.colors.border))

	mover:Hide()
	mover.defaultPoint = defaultPosition
	mover.displayName = displayName
	mover.savedPosition = nil

	mover:SetFrameLevel(100)
	mover:SetFrameStrata('DIALOG')

	-- Create text elements
	local nameText = mover:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(nameText, 12, 'Mover')
	nameText:SetJustifyH('CENTER')
	nameText:SetPoint('CENTER')
	nameText:SetText(displayName)
	nameText:SetTextColor(unpack(cfg.colors.text))
	mover:SetFontString(nameText)
	mover.DisplayName = nameText

	local helpText = mover:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(helpText, 8, 'Mover')
	helpText:SetJustifyH('CENTER')
	helpText:SetPoint('BOTTOM', nameText, 'TOP', 0, 2)
	helpText:SetText(L['Drag to set position'])
	helpText:SetTextColor(unpack(cfg.colors.text))
	mover.HelpText = helpText

	-- Set initial position from saved settings
	local point, anchor, secondaryPoint, x, y = strsplit(',', defaultPosition)
	mover:ClearAllPoints()
	mover:SetPoint(point, _G[anchor], secondaryPoint, x, y)

	-- Script handlers for dragging
	local isDragging = false

	mover:SetScript('OnDragStart', function(self)
		if InCombatLockdown() then
			SUI:Print(ERR_NOT_IN_COMBAT)
			return
		end

		self:StartMoving()
		isDragging = true
	end)

	mover:SetScript('OnDragStop', function(self)
		if InCombatLockdown() then
			SUI:Print(ERR_NOT_IN_COMBAT)
			return
		end

		isDragging = false
		self:StopMovingOrSizing()

		-- Save the position
		local point, anchor, secondaryPoint, x, y = self:GetPoint()
		if not anchor then
			anchor = UIParent
		end

		local anchorName = anchor:GetName() or 'UIParent'
		self.savedPosition = format('%s,%s,%s,%d,%d', point, anchorName, secondaryPoint, Round(x), Round(y))

		-- Call custom save function if provided
		if cfg.savePosition then
			cfg.savePosition(self.savedPosition)
		end

		-- Callback for position change
		if cfg.onPositionChanged then
			cfg.onPositionChanged(self)
		end

		self:SetUserPlaced(false)
	end)

	mover:SetScript('OnEnter', function(self)
		if isDragging then
			return
		end
		self:SetBackdropColor(unpack(cfg.colors.active))
	end)

	mover:SetScript('OnLeave', function(self)
		if isDragging then
			return
		end
		self:SetBackdropColor(unpack(cfg.colors.bg))
	end)

	mover:SetScript('OnMouseDown', function(self, button)
		if InCombatLockdown() then
			SUI:Print(ERR_NOT_IN_COMBAT)
			return
		elseif IsAltKeyDown() then
			self:Hide()
			if cfg.onHide then
				cfg.onHide()
			end
			return
		end

		if button == 'RightButton' then
			-- Reset to default position
			local point, anchor, secondaryPoint, x, y = strsplit(',', self.defaultPoint)
			self:ClearAllPoints()
			self:SetPoint(point, _G[anchor], secondaryPoint, x, y)

			self.savedPosition = nil

			if cfg.savePosition then
				cfg.savePosition(self.defaultPoint)
			end

			SUI:Print(L['Position reset to default'])
		end
	end)

	mover:SetScript('OnMouseWheel', function(self, delta)
		if IsShiftKeyDown() then
			-- Vertical nudge
			local point, anchor, secondaryPoint, x, y = self:GetPoint()
			if not anchor then
				anchor = UIParent
			end

			y = y + delta

			self:ClearAllPoints()
			self:SetPoint(point, anchor, secondaryPoint, x, y)
		else
			-- Horizontal nudge
			local point, anchor, secondaryPoint, x, y = self:GetPoint()
			if not anchor then
				anchor = UIParent
			end

			x = x + delta

			self:ClearAllPoints()
			self:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	end)

	-- Add Escape key handling
	mover:SetScript('OnKeyDown', function(self, key)
		if key == 'ESCAPE' then
			self:Hide()
			if cfg.onHide then
				cfg.onHide()
			end
			return
		end
	end)
	mover:EnableKeyboard(true)

	-- Register with UISpecialFrames for Escape handling
	tinsert(UISpecialFrames, name)

	-- Register with MoveIt system
	MoverList[name] = mover

	return mover
end

function MoveIt:OnInitialize()
	---@class MoveItDB
	local defaults = {
		profile = {
			AltKey = false,
			tips = true,
			movers = {
				['**'] = {
					defaultPoint = false,
					MovedPoints = false,
				},
			},
			-- EditMode wizard tracking
			EditModeWizard = {
				SetupDone = false, -- Wizard/setup completed for this character?
				MigratedFromProfile = nil, -- Profile name we migrated from (if upgrade)
				MigrationOption = nil, -- 'apply_current' | 'copy_new'
			},
			-- EditMode management control
			EditModeControl = {
				Enabled = true, -- Allow MoveIt to manage EditMode profiles
				AutoSwitch = true, -- Auto-switch EditMode when SUI profile changes
				CurrentProfile = nil, -- Currently managed EditMode profile name
			},
		},
		global = {
			-- Account-wide EditMode preferences for multi-character sync
			EditModePreferences = {
				ApplyToAllCharacters = false, -- Auto-apply choices on other characters
				DefaultMigrationOption = nil, -- 'apply_current' | 'copy_new'
			},
		},
	}
	---@type MoveItDB
	MoveIt.Database = SUI.SpartanUIDB:RegisterNamespace('MoveIt', defaults)
	MoveIt.DB = MoveIt.Database.profile
	MoveIt.DBG = MoveIt.Database.global -- Global scope for account-wide settings

	-- Migrate old settings
	if SUI.DB.MoveIt then
		print('MoveIt DB Migration')
		MoveIt.DB = SUI:MergeData(MoveIt.DB, SUI.DB.MoveIt, true)
		SUI.DB.MoveIt = nil
	end

	--Build Options
	MoveIt:Options()

	if EditModeManagerFrame then
		EventRegistry:RegisterCallback('EditMode.Enter', function()
			self:UnlockAll()
		end)
		EventRegistry:RegisterCallback('EditMode.Exit', function()
			self:LockAll()
		end)
	end
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

	-- Register logger if LibAT is available
	local LibAT = _G.LibAT
	if LibAT and LibAT.Logger then
		MoveIt.logger = SUI.logger:RegisterCategory('MoveIt')
		MoveIt.logger.info('MoveIt system initialized')
	end

	-- Initialize Blizzard EditMode integration
	if MoveIt.BlizzardEditMode then
		MoveIt.BlizzardEditMode:Initialize()
	end

	-- Register for SUI profile change callbacks to sync EditMode profiles
	SUI.SpartanUIDB.RegisterCallback(MoveIt, 'OnProfileChanged', 'HandleProfileChange')
	SUI.SpartanUIDB.RegisterCallback(MoveIt, 'OnProfileCopied', 'HandleProfileChange')
	SUI.SpartanUIDB.RegisterCallback(MoveIt, 'OnProfileReset', 'HandleProfileChange')

	-- Register the EditMode wizard page now that DB is available
	if MoveIt.WizardPage and SUI.Setup then
		MoveIt.WizardPage:RegisterPage()
	end

	local ChatCommand = function(arg)
		if InCombatLockdown() then
			print(ERR_NOT_IN_COMBAT)
			return
		end

		if not arg then
			-- On Retail, open Blizzard's EditMode; on Classic, use legacy MoveIt
			if EditModeManagerFrame then
				ShowUIPanel(EditModeManagerFrame)
			else
				MoveIt:MoveIt()
			end
		else
			if MoverList[arg] then
				MoveIt:MoveIt(arg)
			elseif arg == 'reset' then
				print('Restting all frames...')
				MoveIt:Reset()
				return
			elseif arg == 'tips' then
				MoveIt.DB.tips = not MoveIt.DB.tips
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
	SUI:AddChatCommand('move', ChatCommand, "|cffffffffSpartan|cffe21f1fUI|r's movement system", {
		reset = 'Reset all moved objects',
		tips = 'Disable tips from being displayed in chat when movement system is activated',
	}, true)

	-- Register custom EditMode slash command
	SUI:AddChatCommand('edit', function()
		if MoveIt.CustomEditMode then
			MoveIt.CustomEditMode:Toggle()
		end
	end, 'Toggle custom EditMode', nil, true)

	local function OnKeyDown(self, key)
		if MoveEnabled and key == 'ESCAPE' then
			if InCombatLockdown() then
				self:SetPropagateKeyboardInput(true)
				return
			end
			self:SetPropagateKeyboardInput(false)
			MoveIt:LockAll()
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

---Handle SUI profile changes to sync EditMode profiles
---@param event string The callback event name
---@param database table The AceDB database object
---@param newProfile? string The new profile name (may be nil for some events)
function MoveIt:HandleProfileChange(event, database, newProfile)
	-- Update our DB reference since profile changed
	MoveIt.DB = MoveIt.Database.profile

	-- Delegate to BlizzardEditMode for EditMode profile sync
	if MoveIt.BlizzardEditMode and EditModeManagerFrame then
		-- Get the actual new profile name if not provided
		local profileName = newProfile or SUI.SpartanUIDB:GetCurrentProfile()
		MoveIt.BlizzardEditMode:OnSUIProfileChanged(event, database, profileName)
	end
end

function MoveIt:Options()
	SUI.opt.args.Movers = {
		name = L['Movers'],
		type = 'group',
		order = 800,
		disabled = function()
			return SUI:IsModuleDisabled(MoveIt)
		end,
		args = {
			MoveIt = {
				name = L['Toggle movers'],
				type = 'execute',
				order = 1,
				func = function()
					MoveIt:MoveIt()
				end,
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
				end,
			},
			ResetIt = {
				name = L['Reset moved frames'],
				type = 'execute',
				order = 3,
				func = function()
					MoveIt:Reset()
				end,
			},
			line1 = { name = '', type = 'header', order = 49 },
			line2 = {
				name = L['Movement can also be initated with the chat command:'],
				type = 'description',
				order = 50,
				fontSize = 'large',
			},
			line3 = { name = '/sui move', type = 'description', order = 51, fontSize = 'medium' },
			line22 = { name = '', type = 'header', order = 51.1 },
			line4 = {
				name = '',
				type = 'description',
				order = 52,
				fontSize = 'large',
			},
			line5 = {
				name = L['When the movement system is enabled you can:'],
				type = 'description',
				order = 53,
				fontSize = 'large',
			},
			line6 = { name = '- ' .. L['Alt+Click a mover to reset it'], type = 'description', order = 53.5, fontSize = 'medium' },
			line7 = {
				name = '- ' .. L['Shift+Click a mover to temporarily hide it'],
				type = 'description',
				order = 54,
				fontSize = 'medium',
			},
			line7a = {
				name = "- Control+Click a mover to reset it's scale",
				type = 'description',
				order = 54.2,
				fontSize = 'medium',
			},
			line7b = { name = '', type = 'description', order = 54.99, fontSize = 'medium' },
			line8 = {
				name = '- ' .. L['Use the scroll wheel to move left and right 1 coord at a time'],
				type = 'description',
				order = 55,
				fontSize = 'medium',
			},
			line9 = {
				name = '- ' .. L['Hold Shift + use the scroll wheel to move up and down 1 coord at a time'],
				type = 'description',
				order = 56,
				fontSize = 'medium',
			},
			line9a = {
				name = '- ' .. L['Hold Alt + use the scroll wheel to scale the frame'],
				type = 'description',
				order = 56.5,
				fontSize = 'medium',
			},
			line10 = {
				name = '- ' .. L['Press ESCAPE to exit the movement system quickly.'],
				type = 'description',
				order = 57,
				fontSize = 'medium',
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
				end,
			},
			-- EditMode Control Settings (Retail only)
			EditModeHeader = {
				name = 'EditMode Profile Management',
				type = 'header',
				order = 100,
				hidden = function()
					return not SUI.IsRetail or not EditModeManagerFrame
				end,
			},
			EditModeEnabled = {
				name = 'Allow SpartanUI to manage EditMode profiles',
				desc = 'When enabled, SpartanUI will create and manage EditMode profiles that match your SUI profile.',
				type = 'toggle',
				width = 'double',
				order = 101,
				hidden = function()
					return not SUI.IsRetail or not EditModeManagerFrame
				end,
				get = function(info)
					return MoveIt.DB.EditModeControl.Enabled
				end,
				set = function(info, val)
					MoveIt.DB.EditModeControl.Enabled = val
				end,
			},
			EditModeAutoSwitch = {
				name = 'Auto-switch EditMode profile when changing SUI profile',
				desc = 'When enabled, switching your SpartanUI profile will also switch your EditMode profile.',
				type = 'toggle',
				width = 'double',
				order = 102,
				hidden = function()
					return not SUI.IsRetail or not EditModeManagerFrame
				end,
				disabled = function()
					return not MoveIt.DB.EditModeControl.Enabled
				end,
				get = function(info)
					return MoveIt.DB.EditModeControl.AutoSwitch
				end,
				set = function(info, val)
					MoveIt.DB.EditModeControl.AutoSwitch = val
				end,
			},
			EditModeCurrentProfile = {
				name = function()
					local profileName = MoveIt.DB.EditModeControl.CurrentProfile or 'Not set'
					return 'Current EditMode Profile: |cFFFFFF00' .. profileName .. '|r'
				end,
				type = 'description',
				order = 103,
				fontSize = 'medium',
				hidden = function()
					return not SUI.IsRetail or not EditModeManagerFrame
				end,
			},
			EditModeReapplyDefaults = {
				name = 'Re-apply SUI Default Positions',
				desc = 'Re-apply SpartanUI default frame positions to the current EditMode profile.',
				type = 'execute',
				order = 104,
				hidden = function()
					return not SUI.IsRetail or not EditModeManagerFrame
				end,
				disabled = function()
					return not MoveIt.DB.EditModeControl.Enabled
				end,
				func = function()
					if MoveIt.BlizzardEditMode then
						MoveIt.BlizzardEditMode:ApplyDefaultPositions()
						MoveIt.BlizzardEditMode:SafeApplyChanges(true)
						if MoveIt.logger then
							MoveIt.logger.info('Re-applied SUI default positions to EditMode profile')
						end
					end
				end,
			},
		},
	}
end

MoveIt.MoverWatcher = MoverWatcher
MoveIt.MoveEnabled = MoveEnabled
MoveIt.MoverList = MoverList

---Helper function to save a mover's position
---@param name string The mover name
function MoveIt:SaveMoverPosition(name)
	local mover = MoverList[name]
	if not mover or not self.PositionCalculator then
		return
	end

	local position = self.PositionCalculator:GetRelativePosition(mover)
	if position then
		self.PositionCalculator:SavePosition(name, position)
	end
end

---Create two debug test movers for snapping troubleshooting
---Call with: /run SUI.MoveIt:CreateDebugTestMovers()
function MoveIt:CreateDebugTestMovers()
	-- Remove existing test movers if they exist
	if MoverList['DebugTestMover1'] then
		MoverList['DebugTestMover1']:Hide()
		MoverList['DebugTestMover1'] = nil
	end
	if MoverList['DebugTestMover2'] then
		MoverList['DebugTestMover2']:Hide()
		MoverList['DebugTestMover2'] = nil
	end

	-- Create test mover parent frames (required for CreateMover)
	local parent1 = CreateFrame('Frame', 'SUI_DebugTestParent1', UIParent)
	parent1:SetSize(50, 50)
	parent1:SetPoint('CENTER', UIParent, 'CENTER', -100, 100)

	local parent2 = CreateFrame('Frame', 'SUI_DebugTestParent2', UIParent)
	parent2:SetSize(50, 50)
	parent2:SetPoint('CENTER', UIParent, 'CENTER', 100, 100)

	-- Initialize DB entries for the test movers
	if not MoveIt.DB.movers['DebugTestMover1'] then
		MoveIt.DB.movers['DebugTestMover1'] = { defaultPoint = false, MovedPoints = false }
	end
	if not MoveIt.DB.movers['DebugTestMover2'] then
		MoveIt.DB.movers['DebugTestMover2'] = { defaultPoint = false, MovedPoints = false }
	end

	-- Create the movers using standard CreateMover
	MoveIt:CreateMover(parent1, 'DebugTestMover1', 'Test Box 1', nil, 'Debug')
	MoveIt:CreateMover(parent2, 'DebugTestMover2', 'Test Box 2', nil, 'Debug')

	-- Show the test movers
	if MoverList['DebugTestMover1'] then
		MoverList['DebugTestMover1']:Show()
	end
	if MoverList['DebugTestMover2'] then
		MoverList['DebugTestMover2']:Show()
	end

	if MoveIt.logger then
		MoveIt.logger.info('Created 2 debug test movers (50x50)')
	end

	print('Debug test movers created. Use /sui move to see them.')
end

---Remove debug test movers
---Call with: /run SUI.MoveIt:RemoveDebugTestMovers()
function MoveIt:RemoveDebugTestMovers()
	if MoverList['DebugTestMover1'] then
		MoverList['DebugTestMover1']:Hide()
		MoverList['DebugTestMover1'] = nil
	end
	if MoverList['DebugTestMover2'] then
		MoverList['DebugTestMover2']:Hide()
		MoverList['DebugTestMover2'] = nil
	end
	if _G['SUI_DebugTestParent1'] then
		_G['SUI_DebugTestParent1']:Hide()
	end
	if _G['SUI_DebugTestParent2'] then
		_G['SUI_DebugTestParent2']:Hide()
	end
	print('Debug test movers removed.')
end
