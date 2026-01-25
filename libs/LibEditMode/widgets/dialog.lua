local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

local CENTER = {
	point = 'CENTER',
	x = 0,
	y = 0,
}

local internal = lib.internal

-- replica of EditModeSystemSettingsDialog
local dialogMixin = {}
function dialogMixin:Update(selection)
	self.selection = selection

	self.Title:SetText(selection.system:GetSystemName())
	self:UpdateSettings()
	self:UpdateButtons()

	-- show and update layout
	self:Show()
	self:Layout()
end

function dialogMixin:UpdateSettings()
	internal.ReleaseAllPools()

	local settings, num = internal:GetFrameSettings(self.selection.parent)
	if num > 0 then
		for index, data in next, settings do
			local pool = internal:GetPool(data.kind)
			if pool then
				local setting = pool:Acquire(self.Settings)
				setting.layoutIndex = index
				setting:Setup(data)
				setting:Show()
			end
		end
	end

	self.Settings.ResetButton.layoutIndex = num + 1
	self.Settings.Divider.layoutIndex = num + 2
	self.Settings.ResetButton:SetEnabled(num > 0)
end

function dialogMixin:Reset()
	self.selection = nil
	self:ClearAllPoints()
	self:SetPoint('BOTTOMRIGHT', UIParent, -250, 250)
end

local function closeEnough(a, b)
	return math.abs(a - b) < 0.01
end

local function isDefaultPosition(parent)
	local point, _, _, x, y = parent:GetPoint()
	local default = lib:GetFrameDefaultPosition(parent)
	if not default then
		default = CopyTable(CENTER)
	end

	return point == default.point and closeEnough(x, default.x) and closeEnough(y, default.y)
end

function dialogMixin:UpdateButtons()
	local parent = self.selection.parent
	local buttons, num = internal:GetFrameButtons(parent)
	if num > 0 then
		for index, data in next, buttons do
			local button = internal:GetPool('button'):Acquire(self.Buttons)
			button.layoutIndex = index
			button:SetText(data.text)
			button:SetOnClickHandler(data.click)
			button:Show()
			button:SetEnabled(true) -- reset from pool
		end
	end

	local resetPosition = internal:GetPool('button'):Acquire(self.Buttons)
	resetPosition.layoutIndex = num + 1
	resetPosition:SetText(HUD_EDIT_MODE_RESET_POSITION)
	resetPosition:SetOnClickHandler(GenerateClosure(self.ResetPosition, self))
	resetPosition:Show()
	resetPosition:SetEnabled(not isDefaultPosition(parent))
	self.Buttons.ResetPositionButton = resetPosition
end

function dialogMixin:ResetSettings()
	local settings, num = internal:GetFrameSettings(self.selection.parent)
	if num > 0 then
		for _, data in next, settings do
			if data.set then
				data.set(lib:GetActiveLayoutName(), data.default, true)
			end
		end

		self:Update(self.selection)
	end
end

function dialogMixin:ResetPosition()
	if InCombatLockdown() then
		-- TODO: maybe add a warning?
		return
	end

	local parent = self.selection.parent
	local pos = lib:GetFrameDefaultPosition(parent)
	if not pos then
		pos = CopyTable(CENTER)
	end

	parent:ClearAllPoints()
	parent:SetPoint(pos.point, pos.x, pos.y)
	self.Buttons.ResetPositionButton:SetEnabled(false)

	internal:TriggerCallback(parent, pos.point, pos.x, pos.y)
end

local BIG_STEP = 10
local SMALL_STEP = 1

function dialogMixin:OnKeyDown(key)
	if InCombatLockdown() then
		return
	end

	if self.selection then
		self:SetPropagateKeyboardInput(false) -- protected

		if key == 'LEFT' then
			internal:MoveParent(self.selection, IsShiftKeyDown() and -BIG_STEP or -SMALL_STEP)
		elseif key == 'RIGHT' then
			internal:MoveParent(self.selection, IsShiftKeyDown() and BIG_STEP or SMALL_STEP)
		elseif key == 'UP' then
			internal:MoveParent(self.selection, 0, IsShiftKeyDown() and BIG_STEP or SMALL_STEP)
		elseif key == 'DOWN' then
			internal:MoveParent(self.selection, 0, IsShiftKeyDown() and -BIG_STEP or -SMALL_STEP)
		else
			self:SetPropagateKeyboardInput(true) -- protected
		end
	else
		self:SetPropagateKeyboardInput(true) -- protected
	end
end

function internal:CreateDialog()
	local dialog = Mixin(CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame'), dialogMixin)
	dialog:SetSize(300, 350)
	dialog:SetFrameStrata('DIALOG')
	dialog:SetFrameLevel(200)
	dialog:Hide()
	dialog.widthPadding = 40
	dialog.heightPadding = 40

	dialog:Reset()

	-- make draggable
	dialog:EnableMouse(true)
	dialog:SetMovable(true)
	dialog:SetClampedToScreen(true)
	dialog:SetDontSavePosition(true)
	dialog:RegisterForDrag('LeftButton')
	dialog:SetScript('OnDragStart', dialog.StartMoving)
	dialog:SetScript('OnDragStop', dialog.StopMovingOrSizing)
	dialog:SetScript('OnKeyDown', dialog.OnKeyDown)

	local dialogTitle = dialog:CreateFontString(nil, nil, 'GameFontHighlightLarge')
	dialogTitle:SetPoint('TOP', 0, -15)
	dialog.Title = dialogTitle

	local dialogBorder = CreateFrame('Frame', nil, dialog, 'DialogBorderTranslucentTemplate')
	dialogBorder.ignoreInLayout = true
	dialog.Border = dialogBorder

	local dialogClose = CreateFrame('Button', nil, dialog, 'UIPanelCloseButton')
	dialogClose:SetPoint('TOPRIGHT')
	dialogClose.ignoreInLayout = true
	dialogClose:HookScript('OnClick', function()
		dialog:Reset()
	end)
	dialog.Close = dialogClose

	local dialogSettings = CreateFrame('Frame', nil, dialog, 'VerticalLayoutFrame')
	dialogSettings:SetPoint('TOP', dialogTitle, 'BOTTOM', 0, -12)
	dialogSettings.spacing = 2
	dialog.Settings = dialogSettings

	local resetSettingsButton = CreateFrame('Button', nil, dialogSettings, 'EditModeSystemSettingsDialogButtonTemplate')
	resetSettingsButton:SetText(RESET_TO_DEFAULT)
	resetSettingsButton:SetOnClickHandler(GenerateClosure(dialog.ResetSettings, dialog))
	dialogSettings.ResetButton = resetSettingsButton

	local divider = dialogSettings:CreateTexture(nil, 'ARTWORK')
	divider:SetSize(330, 16)
	divider:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
	dialogSettings.Divider = divider

	local dialogButtons = CreateFrame('Frame', nil, dialog, 'VerticalLayoutFrame')
	dialogButtons:SetPoint('TOP', dialogSettings, 'BOTTOM', 0, -12)
	dialogButtons.spacing = 2
	dialog.Buttons = dialogButtons

	return dialog
end
