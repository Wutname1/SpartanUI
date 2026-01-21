---@class SUI
local SUI = SUI
-- Access LibAT from global namespace (not LibStub)
local LibAT = _G.LibAT

---@class SUI.UI
---@field GlueTop fun(widget: Frame, parent: Frame, xOffset?: number, yOffset?: number, anchor?: 'LEFT'|'RIGHT'|nil)
---@field GlueBelow fun(widget: Frame, anchor: Frame, xOffset?: number, yOffset?: number, anchorPoint?: 'LEFT'|'RIGHT'|nil)
---@field GlueRight fun(widget: Frame, anchor: Frame, xOffset?: number, yOffset?: number)
---@field GlueLeft fun(widget: Frame, anchor: Frame, xOffset?: number, yOffset?: number)
---@field GlueBottom fun(widget: Frame, parent: Frame, xOffset?: number, yOffset?: number, anchor?: 'LEFT'|'RIGHT'|nil)
---@field GlueAcross fun(widget: Frame, parent: Frame, left?: number, top?: number, right?: number, bottom?: number)
SUI.UI = SUI.UI or {}

-- Expose LibAT.UI functions through SUI.UI
if LibAT and LibAT.UI then
	for k, v in pairs(LibAT.UI) do
		if type(v) == 'function' and not SUI.UI[k] then
			SUI.UI[k] = v
		end
	end
end

-- ============================================
-- Layout Helper Functions (StdUi:Glue* compatibility)
-- ============================================

--- Position widget at top of parent
---@param widget Frame The widget to position
---@param parent Frame The parent frame to anchor to
---@param xOffset? number X offset (default 0)
---@param yOffset? number Y offset (default 0)
---@param anchor? 'LEFT'|'RIGHT'|nil Anchor side (nil = CENTER)
function SUI.UI.GlueTop(widget, parent, xOffset, yOffset, anchor)
	widget:ClearAllPoints()
	local point = anchor == 'LEFT' and 'TOPLEFT' or (anchor == 'RIGHT' and 'TOPRIGHT' or 'TOP')
	widget:SetPoint(point, parent, point, xOffset or 0, yOffset or 0)
end

--- Position widget below another widget
---@param widget Frame The widget to position
---@param anchor Frame The frame to anchor below
---@param xOffset? number X offset (default 0)
---@param yOffset? number Y offset (default 0)
---@param anchorPoint? 'LEFT'|'RIGHT'|nil Anchor point (nil = CENTER)
function SUI.UI.GlueBelow(widget, anchor, xOffset, yOffset, anchorPoint)
	widget:ClearAllPoints()
	local point = anchorPoint == 'LEFT' and 'TOPLEFT' or (anchorPoint == 'RIGHT' and 'TOPRIGHT' or 'TOP')
	local relPoint = anchorPoint == 'LEFT' and 'BOTTOMLEFT' or (anchorPoint == 'RIGHT' and 'BOTTOMRIGHT' or 'BOTTOM')
	widget:SetPoint(point, anchor, relPoint, xOffset or 0, yOffset or 0)
end

--- Position widget above another widget
---@param widget Frame The widget to position
---@param anchor Frame The frame to anchor above
---@param xOffset? number X offset (default 0)
---@param yOffset? number Y offset (default 0)
---@param anchorPoint? 'LEFT'|'RIGHT'|nil Anchor point (nil = CENTER)
function SUI.UI.GlueAbove(widget, anchor, xOffset, yOffset, anchorPoint)
	widget:ClearAllPoints()
	local point = anchorPoint == 'LEFT' and 'BOTTOMLEFT' or (anchorPoint == 'RIGHT' and 'BOTTOMRIGHT' or 'BOTTOM')
	local relPoint = anchorPoint == 'LEFT' and 'TOPLEFT' or (anchorPoint == 'RIGHT' and 'TOPRIGHT' or 'TOP')
	widget:SetPoint(point, anchor, relPoint, xOffset or 0, yOffset or 0)
end

--- Position widget to the right of another widget
---@param widget Frame The widget to position
---@param anchor Frame The frame to anchor beside
---@param xOffset? number X offset (default 0)
---@param yOffset? number Y offset (default 0)
function SUI.UI.GlueRight(widget, anchor, xOffset, yOffset)
	widget:ClearAllPoints()
	widget:SetPoint('LEFT', anchor, 'RIGHT', xOffset or 0, yOffset or 0)
end

--- Position widget to the left of another widget
---@param widget Frame The widget to position
---@param anchor Frame The frame to anchor beside
---@param xOffset? number X offset (default 0)
---@param yOffset? number Y offset (default 0)
function SUI.UI.GlueLeft(widget, anchor, xOffset, yOffset)
	widget:ClearAllPoints()
	widget:SetPoint('RIGHT', anchor, 'LEFT', xOffset or 0, yOffset or 0)
end

--- Position widget at bottom of parent
---@param widget Frame The widget to position
---@param parent Frame The parent frame to anchor to
---@param xOffset? number X offset (default 0)
---@param yOffset? number Y offset (default 0)
---@param anchor? 'LEFT'|'RIGHT'|nil Anchor side (nil = CENTER)
function SUI.UI.GlueBottom(widget, parent, xOffset, yOffset, anchor)
	widget:ClearAllPoints()
	local point = anchor == 'LEFT' and 'BOTTOMLEFT' or (anchor == 'RIGHT' and 'BOTTOMRIGHT' or 'BOTTOM')
	widget:SetPoint(point, parent, point, xOffset or 0, yOffset or 0)
end

--- Fill widget across parent with optional insets
---@param widget Frame The widget to position
---@param parent Frame The parent frame to fill
---@param left? number Left inset (default 0)
---@param top? number Top inset (default 0, negative goes down)
---@param right? number Right inset (default 0, negative goes left)
---@param bottom? number Bottom inset (default 0)
function SUI.UI.GlueAcross(widget, parent, left, top, right, bottom)
	widget:ClearAllPoints()
	widget:SetPoint('TOPLEFT', parent, 'TOPLEFT', left or 0, top or 0)
	widget:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', right or 0, bottom or 0)
end

-- ============================================
-- Texture Helper (StdUi:Texture compatibility)
-- ============================================

--- Create a texture on a frame (replaces StdUi:Texture)
---@param parent Frame The parent frame
---@param width number Texture width
---@param height number Texture height
---@param texturePath string Path to the texture
---@param layer? string Draw layer (default 'ARTWORK')
---@return Texture texture The created texture
function SUI.UI.CreateTexture(parent, width, height, texturePath, layer)
	local texture = parent:CreateTexture(nil, layer or 'ARTWORK')
	texture:SetSize(width, height)
	if texturePath then
		texture:SetTexture(texturePath)
	end
	return texture
end

-- ============================================
-- Simple Dialog Helper (StdUi:Dialog compatibility)
-- ============================================

--- Show a simple dialog with title and message
---@param title string Dialog title
---@param message string Dialog message
---@param onAccept? function Callback when accepted
---@param onCancel? function Callback when cancelled
function SUI.UI.Dialog(title, message, onAccept, onCancel)
	-- Use StaticPopup system for simple dialogs
	local dialogName = 'SUI_DIALOG_' .. tostring(GetTime()):gsub('%.', '')

	StaticPopupDialogs[dialogName] = {
		text = message,
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = onAccept,
		OnCancel = onCancel,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3
	}

	StaticPopup_Show(dialogName)
end
