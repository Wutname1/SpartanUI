---@diagnostic disable: duplicate-set-field
--[===[ File: Display/Container.lua
LibsDataBar Container Class
Flexible, moveable containers that extend DataBar with advanced positioning
This is our competitive advantage - no other addon offers this flexibility
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Get DataBar base class
local DataBar = LibsDataBar.DataBar
if not DataBar then
	LibsDataBar:DebugLog('error', 'Container requires DataBar class')
	return
end

-- Local references for performance
local _G = _G
local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local UIParent = UIParent
local pairs, ipairs = pairs, ipairs
local math = math

---@class Container : DataBar
---@field containerType "floating"|"docked"|"anchored"
---@field dimensions table Container size constraints
---@field dragHandle Frame Drag handle for movement
---@field resizeHandle Frame Resize handle for sizing
---@field snapZones table Available snap positions
---@field isDragging boolean Currently being dragged
---@field isResizing boolean Currently being resized
---@field snapIndicator Frame Visual snap indicator
local Container = setmetatable({}, { __index = DataBar })
Container.__index = Container

-- Container registry for LibsDataBar
LibsDataBar.containers = LibsDataBar.containers or {}

---Create a new Container instance
---@param config table Container configuration
---@return Container? container Created Container instance
function Container:Create(config)
	if not config or not config.id then
		LibsDataBar:DebugLog('error', 'Container:Create requires config with id')
		return nil
	end

	-- Create base DataBar first
	local bar = DataBar:Create(config)
	if not bar then return nil end

	-- Convert to Container
	local container = setmetatable(bar, Container)

	-- Container-specific properties
	container.containerType = config.containerType or 'floating'
	container.dimensions = {
		minWidth = config.minWidth or 100,
		maxWidth = config.maxWidth or 800,
		minHeight = config.minHeight or 24,
		maxHeight = config.maxHeight or 200,
		aspectRatio = config.aspectRatio or nil,
		autoResize = config.autoResize ~= false,
	}

	container.isDragging = false
	container.isResizing = false

	-- Container-specific configuration defaults
	container:ApplyContainerDefaults()

	-- Create container-specific UI elements
	container:CreateDragHandle()
	container:CreateResizeHandle()
	container:CreateSnapIndicator()
	container:SetupSnapping()
	container:SetupContainerBehavior()

	-- Register with LibsDataBar containers
	LibsDataBar.containers[config.id] = container

	-- Fire container creation event
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_ContainerCreated', config.id, container) end

	LibsDataBar:DebugLog('info', 'Container created: ' .. config.id .. ' (' .. container.containerType .. ')')
	return container
end

---Apply container-specific configuration defaults
function Container:ApplyContainerDefaults()
	-- Override some DataBar defaults for containers
	self.config.behavior.resizable = self.config.behavior.resizable ~= false
	self.config.behavior.draggable = self.config.behavior.draggable ~= false
	self.config.behavior.locked = self.config.behavior.locked or false
	self.config.behavior.snapToEdges = self.config.behavior.snapToEdges ~= false
	self.config.behavior.snapToOthers = self.config.behavior.snapToOthers ~= false

	-- Container-specific sizing behavior
	if self.dimensions.autoResize then
		self.config.size.width = 0 -- Will auto-size to content
	end
end

---Create drag handle for moving the container
function Container:CreateDragHandle()
	if not self.config.behavior.draggable then return end

	-- Create invisible drag area covering the entire container
	self.dragHandle = CreateFrame('Frame', nil, self.frame)
	self.dragHandle:SetAllPoints(self.frame)
	self.dragHandle:EnableMouse(true)
	self.dragHandle:RegisterForDrag('LeftButton')
	self.dragHandle:SetFrameLevel(self.frame:GetFrameLevel() + 1)

	-- Visual indicator when dragging is possible (subtle highlight)
	local highlight = self.dragHandle:CreateTexture(nil, 'HIGHLIGHT')
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.1)
	highlight:Hide()

	-- Mouse events
	self.dragHandle:SetScript('OnEnter', function()
		if not self.config.behavior.locked then
			highlight:Show()
			GameTooltip:SetOwner(self.dragHandle, 'ANCHOR_CURSOR')
			GameTooltip:SetText('LibsDataBar Container\n|cFFFFFF00Drag to move|r\n|cFFFF8000Right-click for options|r')
			GameTooltip:Show()
		end
	end)

	self.dragHandle:SetScript('OnLeave', function()
		highlight:Hide()
		GameTooltip:Hide()
	end)

	self.dragHandle:SetScript('OnDragStart', function()
		if not self.config.behavior.locked then self:StartDrag() end
	end)

	self.dragHandle:SetScript('OnDragStop', function()
		self:StopDrag()
	end)

	-- Right-click for configuration
	self.dragHandle:SetScript('OnMouseUp', function(frame, button)
		if button == 'RightButton' then self:ShowContextMenu() end
	end)
end

---Create resize handle for adjusting container size
function Container:CreateResizeHandle()
	if not self.config.behavior.resizable then return end

	self.resizeHandle = CreateFrame('Frame', nil, self.frame)
	self.resizeHandle:SetSize(16, 16)
	self.resizeHandle:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', -2, 2)
	self.resizeHandle:SetFrameLevel(self.frame:GetFrameLevel() + 2)

	-- Visual resize indicator
	local texture = self.resizeHandle:CreateTexture(nil, 'OVERLAY')
	texture:SetAllPoints()
	texture:SetTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
	texture:SetAlpha(0.7)

	self.resizeHandle:EnableMouse(true)
	self.resizeHandle:RegisterForDrag('LeftButton')

	-- Cursor change on hover
	self.resizeHandle:SetScript('OnEnter', function()
		SetCursor('RESIZE_BOTTOMRIGHT_CURSOR')
	end)

	self.resizeHandle:SetScript('OnLeave', function()
		SetCursor(nil)
	end)

	self.resizeHandle:SetScript('OnDragStart', function()
		self:StartResize()
	end)

	self.resizeHandle:SetScript('OnDragStop', function()
		self:StopResize()
	end)
end

---Create visual snap indicator
function Container:CreateSnapIndicator()
	self.snapIndicator = CreateFrame('Frame', nil, UIParent)
	self.snapIndicator:SetFrameStrata('TOOLTIP')
	self.snapIndicator:Hide()

	local texture = self.snapIndicator:CreateTexture(nil, 'OVERLAY')
	texture:SetAllPoints()
	texture:SetColorTexture(0, 1, 0, 0.3) -- Semi-transparent green

	local border = CreateFrame('Frame', nil, self.snapIndicator, 'BackdropTemplate')
	border:SetAllPoints()
	border:SetBackdrop({
		edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
		edgeSize = 8,
	})
	border:SetBackdropBorderColor(0, 1, 0, 0.8)
end

---Setup snapping zones and behavior
function Container:SetupSnapping()
	self.snapZones = {}

	-- Screen edge snap zones
	if self.config.behavior.snapToEdges then
		local threshold = 25
		tinsert(self.snapZones, { type = 'screen', edge = 'top', threshold = threshold })
		tinsert(self.snapZones, { type = 'screen', edge = 'bottom', threshold = threshold })
		tinsert(self.snapZones, { type = 'screen', edge = 'left', threshold = threshold })
		tinsert(self.snapZones, { type = 'screen', edge = 'right', threshold = threshold })
	end

	-- Custom anchor points (common UI elements)
	local commonAnchors = {
		{ frame = 'ChatFrame1', threshold = 30, name = 'Chat Frame' },
		{ frame = 'Minimap', threshold = 30, name = 'Minimap' },
		{ frame = 'MainMenuBar', threshold = 30, name = 'Action Bar' },
	}

	for _, anchor in ipairs(commonAnchors) do
		local frame = _G[anchor.frame]
		if frame then tinsert(self.snapZones, {
			type = 'anchor',
			frame = frame,
			name = anchor.name,
			threshold = anchor.threshold,
		}) end
	end
end

---Setup container-specific behavior
function Container:SetupContainerBehavior()
	-- Auto-sizing behavior
	if self.dimensions.autoResize then
		-- Override layout update to handle auto-sizing
		local originalUpdateLayout = self.UpdateLayout
		self.UpdateLayout = function(self)
			originalUpdateLayout(self)
			self:AutoResize()
		end
	end

	-- Container type specific behavior
	if self.containerType == 'docked' then
		self:SetupDockedBehavior()
	elseif self.containerType == 'anchored' then
		self:SetupAnchoredBehavior()
	end
end

---Setup behavior for docked containers
function Container:SetupDockedBehavior()
	-- Docked containers snap to screen edges and resize to fit
	self.config.behavior.snapToEdges = true

	-- Register for screen resolution changes
	LibsDataBar.events:RegisterEvent('DISPLAY_SIZE_CHANGED', function()
		self:UpdateDockingPosition()
	end, { owner = self.id })
end

---Setup behavior for anchored containers
function Container:SetupAnchoredBehavior()
	-- Anchored containers follow their anchor point
	if self.config.anchorFrame then
		local anchorFrame = _G[self.config.anchorFrame]
		if anchorFrame then
			-- Update position when anchor frame moves
			anchorFrame:HookScript('OnShow', function()
				self:UpdatePosition()
			end)
			anchorFrame:HookScript('OnHide', function()
				self:UpdatePosition()
			end)
		end
	end
end

---Start dragging the container
function Container:StartDrag()
	if self.isDragging then return end

	self.isDragging = true
	self.frame:StartMoving()

	-- Show snap indicator
	if self.config.behavior.snapToEdges or self.config.behavior.snapToOthers then self:ShowSnapZones() end

	-- Start drag update timer
	self.dragUpdateTimer = C_Timer.NewTicker(0.05, function()
		self:UpdateDragSnapping()
	end)

	LibsDataBar:DebugLog('info', 'Started dragging container: ' .. self.id)
end

---Stop dragging the container
function Container:StopDrag()
	if not self.isDragging then return end

	self.isDragging = false
	self.frame:StopMovingOrSizing()

	-- Cancel drag timer
	if self.dragUpdateTimer then
		self.dragUpdateTimer:Cancel()
		self.dragUpdateTimer = nil
	end

	-- Hide snap indicators
	self:HideSnapZones()

	-- Apply final snap position
	local snapPosition = self:FindBestSnapPosition()
	if snapPosition then self:SnapToPosition(snapPosition) end

	-- Save position to configuration
	self:SavePosition()

	LibsDataBar:DebugLog('info', 'Stopped dragging container: ' .. self.id)
end

---Start resizing the container
function Container:StartResize()
	if self.isResizing then return end

	self.isResizing = true
	self.frame:StartSizing()

	-- Start resize update timer
	self.resizeUpdateTimer = C_Timer.NewTicker(0.05, function()
		self:UpdateResize()
	end)

	LibsDataBar:DebugLog('info', 'Started resizing container: ' .. self.id)
end

---Stop resizing the container
function Container:StopResize()
	if not self.isResizing then return end

	self.isResizing = false
	self.frame:StopMovingOrSizing()

	-- Cancel resize timer
	if self.resizeUpdateTimer then
		self.resizeUpdateTimer:Cancel()
		self.resizeUpdateTimer = nil
	end

	-- Update layout after resize
	self:UpdateLayout()

	-- Save size to configuration
	self:SaveSize()

	LibsDataBar:DebugLog('info', 'Stopped resizing container: ' .. self.id)
end

---Update during drag to show snap zones
function Container:UpdateDragSnapping()
	if not self.isDragging then return end

	local snapPosition = self:FindBestSnapPosition()
	if snapPosition then
		self:ShowSnapIndicator(snapPosition)
	else
		self.snapIndicator:Hide()
	end
end

---Update during resize to enforce constraints
function Container:UpdateResize()
	if not self.isResizing then return end

	local width = self.frame:GetWidth()
	local height = self.frame:GetHeight()

	-- Enforce minimum/maximum size constraints
	width = math.max(self.dimensions.minWidth, math.min(self.dimensions.maxWidth, width))
	height = math.max(self.dimensions.minHeight, math.min(self.dimensions.maxHeight, height))

	-- Enforce aspect ratio if specified
	if self.dimensions.aspectRatio then
		local currentRatio = width / height
		if math.abs(currentRatio - self.dimensions.aspectRatio) > 0.1 then
			if currentRatio > self.dimensions.aspectRatio then
				width = height * self.dimensions.aspectRatio
			else
				height = width / self.dimensions.aspectRatio
			end
		end
	end

	self.frame:SetSize(width, height)
end

---Find the best snap position for current cursor location
---@return table? snapPosition Best snap position or nil
function Container:FindBestSnapPosition()
	local cursorX, cursorY = GetCursorPosition()
	cursorX = cursorX / UIParent:GetEffectiveScale()
	cursorY = cursorY / UIParent:GetEffectiveScale()

	local bestSnap = nil
	local bestDistance = math.huge

	for _, zone in ipairs(self.snapZones) do
		local snapPos = self:CalculateSnapPosition(zone, cursorX, cursorY)
		if snapPos then
			local distance = math.sqrt((cursorX - snapPos.x) ^ 2 + (cursorY - snapPos.y) ^ 2)
			if distance < zone.threshold and distance < bestDistance then
				bestDistance = distance
				bestSnap = snapPos
				bestSnap.zone = zone
			end
		end
	end

	return bestSnap
end

---Calculate snap position for a specific zone
---@param zone table Snap zone definition
---@param cursorX number Cursor X position
---@param cursorY number Cursor Y position
---@return table? position Snap position or nil
function Container:CalculateSnapPosition(zone, cursorX, cursorY)
	if zone.type == 'screen' then
		if zone.edge == 'top' then
			return { x = cursorX, y = UIParent:GetHeight() - self.frame:GetHeight() }
		elseif zone.edge == 'bottom' then
			return { x = cursorX, y = 0 }
		elseif zone.edge == 'left' then
			return { x = 0, y = cursorY }
		elseif zone.edge == 'right' then
			return { x = UIParent:GetWidth() - self.frame:GetWidth(), y = cursorY }
		end
	elseif zone.type == 'anchor' and zone.frame then
		local frame = zone.frame
		local left = frame:GetLeft()
		local bottom = frame:GetBottom()
		local width = frame:GetWidth()
		local height = frame:GetHeight()

		if left and bottom then
			-- Snap to different sides of the anchor frame
			local positions = {
				{ x = left, y = bottom + height + 5 }, -- Above
				{ x = left, y = bottom - self.frame:GetHeight() - 5 }, -- Below
				{ x = left - self.frame:GetWidth() - 5, y = bottom }, -- Left
				{ x = left + width + 5, y = bottom }, -- Right
			}

			-- Find closest position
			local bestPos = nil
			local bestDist = math.huge
			for _, pos in ipairs(positions) do
				local dist = math.sqrt((cursorX - pos.x) ^ 2 + (cursorY - pos.y) ^ 2)
				if dist < bestDist then
					bestDist = dist
					bestPos = pos
				end
			end

			return bestPos
		end
	end

	return nil
end

---Show snap zones visually
function Container:ShowSnapZones()
	-- This would show visual indicators for all snap zones
	-- Implementation would create temporary visual frames
	LibsDataBar:DebugLog('info', 'Showing snap zones for container: ' .. self.id)
end

---Hide snap zones
function Container:HideSnapZones()
	if self.snapIndicator then self.snapIndicator:Hide() end
end

---Show snap indicator at specific position
---@param position table Position to show indicator
function Container:ShowSnapIndicator(position)
	if not position then return end

	self.snapIndicator:SetSize(self.frame:GetWidth(), self.frame:GetHeight())
	self.snapIndicator:ClearAllPoints()
	self.snapIndicator:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', position.x, position.y)
	self.snapIndicator:Show()
end

---Snap to a specific position
---@param position table Position to snap to
function Container:SnapToPosition(position)
	if not position then return end

	self.frame:ClearAllPoints()
	self.frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', position.x, position.y)

	if position.zone then LibsDataBar:DebugLog('info', 'Container ' .. self.id .. ' snapped to ' .. (position.zone.name or position.zone.type)) end
end

---Auto-resize container to fit content
function Container:AutoResize()
	if not self.dimensions.autoResize then return end

	local minWidth = self.dimensions.minWidth
	local maxWidth = self.dimensions.maxWidth

	-- Calculate required width based on plugins
	local requiredWidth = 0
	local padding = self.config.layout.padding or { left = 8, right = 8, top = 2, bottom = 2 }
	local spacing = self.config.layout.spacing or 4

	requiredWidth = requiredWidth + padding.left + padding.right

	local visiblePlugins = 0
	for _, button in pairs(self.plugins) do
		if button.frame and button.frame:IsShown() then
			requiredWidth = requiredWidth + button.frame:GetWidth()
			visiblePlugins = visiblePlugins + 1
		end
	end

	if visiblePlugins > 1 then requiredWidth = requiredWidth + (spacing * (visiblePlugins - 1)) end

	-- Apply constraints
	requiredWidth = math.max(minWidth, math.min(maxWidth, requiredWidth))

	if math.abs(self.frame:GetWidth() - requiredWidth) > 5 then
		self.frame:SetWidth(requiredWidth)
		self.config.size.width = requiredWidth
	end
end

---Save current position to configuration
function Container:SavePosition()
	local point, relativeTo, relativePoint, x, y = self.frame:GetPoint()
	self.config.anchor = {
		point = point,
		relativeTo = relativeTo and relativeTo:GetName() or 'UIParent',
		relativePoint = relativePoint,
		x = x,
		y = y,
	}

	-- Save to LibsDataBar config system
	LibsDataBar.config:SetConfig('bars.' .. self.id .. '.anchor', self.config.anchor)
end

---Save current size to configuration
function Container:SaveSize()
	self.config.size.width = self.frame:GetWidth()
	self.config.size.height = self.frame:GetHeight()

	-- Save to LibsDataBar config system
	LibsDataBar.config:SetConfig('bars.' .. self.id .. '.size', self.config.size)
end

---Update docked container position
function Container:UpdateDockingPosition()
	if self.containerType ~= 'docked' then return end

	-- Recalculate docked position based on screen size
	self:UpdatePosition()
end

---Override destroy to clean up container-specific resources
function Container:Destroy()
	-- Cancel any active timers
	if self.dragUpdateTimer then
		self.dragUpdateTimer:Cancel()
		self.dragUpdateTimer = nil
	end

	if self.resizeUpdateTimer then
		self.resizeUpdateTimer:Cancel()
		self.resizeUpdateTimer = nil
	end

	-- Clean up snap indicator
	if self.snapIndicator then
		self.snapIndicator:Hide()
		self.snapIndicator:SetParent(nil)
		self.snapIndicator = nil
	end

	-- Remove from containers registry
	LibsDataBar.containers[self.id] = nil

	-- Call parent destroy
	DataBar.Destroy(self)

	-- Fire container destruction event
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_ContainerDestroyed', self.id) end

	LibsDataBar:DebugLog('info', 'Container destroyed: ' .. self.id)
end

-- Export Container class
LibsDataBar.Container = Container
return Container
