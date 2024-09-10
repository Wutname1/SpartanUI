---@class FlexBar.Bar
local Bar = {}
FlexBar.Bar = Bar

-- Libraries
local LDB = LibStub('LibDataBroker-1.1')
local LSM = LibStub('LibSharedMedia-3.0')

-- Local variables
local DEFAULT_PLUGIN_WIDTH = 100

-- Bar object constructor
function Bar:New(name, settings)
	local bar = CreateFrame('Frame', 'FlexBar_' .. name, UIParent, BackdropTemplateMixin and 'BackdropTemplate')
	bar.name = name
	bar.settings = settings
	bar.plugins = {}

	-- Set up metatable
	setmetatable(bar, self)
	self.__index = self

	-- Initialize bar
	bar:SetupFrame()
	bar:SetupAreas()
	bar:SetupDragAndDrop()
	bar:UpdateAppearance()

	return bar
end

function Bar:SetupFrame()
	self:SetPoint(self.settings.position)
	self:SetSize(UIParent:GetWidth(), self.settings.height)
	self:EnableMouse(true)
	self:SetMovable(true)
	self:RegisterForDrag('LeftButton')
	self:SetScript('OnDragStart', self.OnDragStart)
	self:SetScript('OnDragStop', self.OnDragStop)
end

function Bar:SetupAreas()
	self.areas = {
		left = CreateFrame('Frame', nil, self),
		center = CreateFrame('Frame', nil, self),
		right = CreateFrame('Frame', nil, self),
	}

	self.areas.left:SetPoint('LEFT')
	self.areas.center:SetPoint('CENTER')
	self.areas.right:SetPoint('RIGHT')

	for _, area in pairs(self.areas) do
		area:SetHeight(self:GetHeight())
	end
end

function Bar:SetupDragAndDrop()
	self:SetScript('OnMouseDown', function(self, button)
		if button == 'LeftButton' and not self.settings.locked then self:StartMoving() end
	end)
	self:SetScript('OnMouseUp', function(self, button)
		if button == 'LeftButton' then
			self:StopMovingOrSizing()
			-- Save position
			local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
			self.settings.position = { point, 'UIParent', relativePoint, xOfs, yOfs }
		end
	end)
end

function Bar:UpdateAppearance()
	local backdrop = {
		bgFile = LSM:Fetch('statusbar', self.settings.texture),
		edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
		tile = false,
		tileSize = 32,
		edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 },
	}
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(self.settings.color.r, self.settings.color.g, self.settings.color.b, self.settings.color.a)
end

function Bar:AddPlugin(name, dataobj)
	local plugin = CreateFrame('Button', 'FlexBar_Plugin_' .. name, self)
	plugin.name = name
	plugin.dataobj = dataobj

	plugin:SetSize(DEFAULT_PLUGIN_WIDTH, self:GetHeight())
	plugin:SetScript('OnEnter', self.OnPluginEnter)
	plugin:SetScript('OnLeave', self.OnPluginLeave)
	plugin:SetScript('OnClick', self.OnPluginClick)
	plugin:RegisterForDrag('LeftButton')
	plugin:SetScript('OnDragStart', self.OnPluginDragStart)
	plugin:SetScript('OnDragStop', self.OnPluginDragStop)

	-- Create icon and text
	plugin.icon = plugin:CreateTexture(nil, 'ARTWORK')
	plugin.icon:SetSize(16, 16)
	plugin.icon:SetPoint('LEFT', plugin, 'LEFT', 2, 0)

	plugin.text = plugin:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	plugin.text:SetPoint('LEFT', plugin.icon, 'RIGHT', 2, 0)
	plugin.text:SetPoint('RIGHT', plugin, 'RIGHT', -2, 0)

	self:UpdatePluginDisplay(plugin)

	-- Add to appropriate area (for simplicity, adding all to left for now)
	plugin:SetParent(self.areas.left)
	table.insert(self.plugins, plugin)
	self:UpdatePluginLayout()

	return plugin
end

function Bar:UpdatePluginDisplay(plugin)
	local dataobj = plugin.dataobj

	if dataobj.icon then
		plugin.icon:SetTexture(dataobj.icon)
		plugin.icon:Show()
	else
		plugin.icon:Hide()
	end

	if dataobj.text then
		plugin.text:SetText(dataobj.text)
	elseif dataobj.label then
		plugin.text:SetText(dataobj.label)
	else
		plugin.text:SetText(plugin.name)
	end
end

function Bar:UpdatePluginLayout()
	local xOffset = 5
	for _, plugin in ipairs(self.plugins) do
		plugin:ClearAllPoints()
		plugin:SetPoint('LEFT', self.areas.left, 'LEFT', xOffset, 0)
		xOffset = xOffset + plugin:GetWidth() + 5
	end
	self.areas.left:SetWidth(xOffset)
end

function Bar:OnPluginEnter(plugin)
	GameTooltip:SetOwner(plugin, 'ANCHOR_TOPRIGHT')
	if plugin.dataobj.tooltip then
		plugin.dataobj.tooltip(GameTooltip)
	elseif plugin.dataobj.OnTooltipShow then
		plugin.dataobj.OnTooltipShow(GameTooltip)
	else
		GameTooltip:AddLine(plugin.name)
		if plugin.dataobj.text then GameTooltip:AddLine(plugin.dataobj.text) end
	end
	GameTooltip:Show()
end

function Bar:OnPluginLeave(plugin)
	GameTooltip:Hide()
end

function Bar:OnPluginClick(plugin, button)
	if plugin.dataobj.OnClick then plugin.dataobj.OnClick(plugin, button) end
end

function Bar:Lock()
	self.settings.locked = true
	self:EnableMouse(false)
end

function Bar:Unlock()
	self.settings.locked = false
	self:EnableMouse(true)
end

function Bar:OnPluginDragStart(plugin)
	if not self.settings.locked then
		plugin:StartMoving()
		plugin.isMoving = true
	end
end

function Bar:OnPluginDragStop(plugin)
	if plugin.isMoving then
		plugin:StopMovingOrSizing()
		plugin.isMoving = false
		self:UpdatePluginOrder(plugin)
	end
end

function Bar:UpdatePluginOrder(movedPlugin)
	local newOrder = {}
	for i, plugin in ipairs(self.plugins) do
		if plugin ~= movedPlugin then table.insert(newOrder, plugin) end
	end

	local insertIndex = 1
	for i, plugin in ipairs(newOrder) do
		if movedPlugin:GetLeft() < plugin:GetLeft() then break end
		insertIndex = i + 1
	end

	table.insert(newOrder, insertIndex, movedPlugin)
	self.plugins = newOrder
	self:UpdatePluginLayout()
end

return Bar
