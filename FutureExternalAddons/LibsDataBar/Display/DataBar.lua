---@diagnostic disable: duplicate-set-field
--[===[ File: Display/DataBar.lua
LibsDataBar DataBar Class
Base display bar framework for plugin containers
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary("LibsDataBar-1.0")
if not LibsDataBar then return end

-- Local references for performance
local _G = _G
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime
local pairs, ipairs = pairs, ipairs
local tinsert, tremove = tinsert, tremove

---@class DataBar
---@field id string Unique bar identifier
---@field frame Frame WoW UI frame  
---@field plugins table<string, PluginButton> Plugin buttons
---@field config table Bar configuration
---@field layoutManager LayoutManager Layout calculation engine
---@field theme table Current theme settings
---@field updateTimer table Timer for updates
---@field dragFrame Frame Drag handling frame
local DataBar = {}
DataBar.__index = DataBar

-- DataBar registry for LibsDataBar
LibsDataBar.bars = LibsDataBar.bars or {}

---Create a new DataBar instance
---@param config table Bar configuration
---@return DataBar bar Created DataBar instance
function DataBar:Create(config)
    if not config or not config.id then
        LibsDataBar:DebugLog("error", "DataBar:Create requires config with id")
        return nil
    end
    
    -- Check if bar already exists
    if LibsDataBar.bars[config.id] then
        LibsDataBar:DebugLog("warning", "DataBar " .. config.id .. " already exists")
        return LibsDataBar.bars[config.id]
    end
    
    local bar = setmetatable({}, DataBar)
    
    bar.id = config.id
    bar.config = config
    bar.plugins = {}
    bar.pluginOrder = {}
    
    -- Apply configuration defaults
    bar:ApplyDefaults()
    
    -- Create main frame with backdrop template for modern WoW compatibility
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    bar.frame = CreateFrame("Frame", "LibsDataBar_" .. config.id, UIParent, template)
    
    -- Enable backdrop for older WoW versions
    if not BackdropTemplateMixin and bar.frame.SetBackdrop then
        -- Frame already has SetBackdrop, we're good
    elseif BackdropTemplateMixin and bar.frame.SetBackdrop then
        -- Modern WoW with BackdropTemplate
    else
        -- Fallback: create manual background texture
        LibsDataBar:DebugLog("warning", "No backdrop support detected, using manual texture background")
        bar.useManualBackground = true
    end
    
    bar.frame:SetFrameStrata(bar.config.behavior.strata)
    bar.frame:SetFrameLevel(bar.config.behavior.level)
    
    -- Set initial size and position
    bar:UpdateSize()
    bar:UpdatePosition()
    bar:UpdateAppearance()
    
    -- Apply current theme if ThemeManager is available
    if LibsDataBar.themes then
        LibsDataBar.themes:ApplyThemeToBar(bar)
    end
    
    -- Setup mouse handling
    bar:SetupMouseHandling()
    
    -- Setup update timer
    bar:SetupUpdateTimer()
    
    -- Register events
    bar:RegisterEvents()
    
    -- Register with LibsDataBar
    LibsDataBar.bars[config.id] = bar
    
    -- Fire creation event
    if LibsDataBar.callbacks then
        LibsDataBar.callbacks:Fire("LibsDataBar_BarCreated", config.id, bar)
    end
    
    LibsDataBar:DebugLog("info", "DataBar created: " .. config.id)
    return bar
end

---Apply default configuration values
function DataBar:ApplyDefaults()
    -- Get default bar config from LibsDataBar config system
    local defaults = LibsDataBar.config:GetConfig("bars.*") or {}
    
    -- Merge with provided config, giving priority to provided values
    for key, defaultValue in pairs(defaults) do
        if self.config[key] == nil then
            self.config[key] = defaultValue
        end
    end
    
    -- Ensure essential properties exist
    self.config.behavior = self.config.behavior or {}
    self.config.appearance = self.config.appearance or {}
    self.config.layout = self.config.layout or {}
    self.config.size = self.config.size or {}
    self.config.anchor = self.config.anchor or {}
    
    -- Set essential defaults
    self.config.behavior.strata = self.config.behavior.strata or "MEDIUM"
    self.config.behavior.level = self.config.behavior.level or 1
    self.config.behavior.autoHide = self.config.behavior.autoHide or false
    self.config.behavior.autoHideDelay = self.config.behavior.autoHideDelay or 2.0
    self.config.behavior.combatHide = self.config.behavior.combatHide or false
    
    self.config.layout.orientation = self.config.layout.orientation or "horizontal"
    self.config.layout.alignment = self.config.layout.alignment or "left"
    self.config.layout.spacing = self.config.layout.spacing or 4
    self.config.layout.padding = self.config.layout.padding or 2
    
    self.config.size.height = self.config.size.height or 24
    self.config.size.width = self.config.size.width or 0 -- Auto-size
    
    -- Position and anchor defaults
    self.config.position = self.config.position or "bottom"
    self.config.anchor.x = self.config.anchor.x or 0
    self.config.anchor.y = self.config.anchor.y or 0
    
    -- Set position-specific defaults
    if self.config.position == "top" then
        self.config.anchor.y = self.config.anchor.y or 0 -- Align to top edge
    elseif self.config.position == "bottom" then
        self.config.anchor.y = self.config.anchor.y or 0 -- Align to bottom edge
    elseif self.config.position == "left" then
        self.config.anchor.x = self.config.anchor.x or 0 -- Align to left edge
    elseif self.config.position == "right" then
        self.config.anchor.x = self.config.anchor.x or 0 -- Align to right edge
    end
    
    -- Button defaults
    self.config.button = self.config.button or {}
    self.config.button.height = self.config.button.height or (self.config.size.height - 4)
end

---Update bar size based on configuration
function DataBar:UpdateSize()
    local width = self.config.size.width or 0
    local height = self.config.size.height or 24
    local scale = self.config.size.scale or 1.0
    
    -- Auto-width: full screen width
    if width == 0 then
        width = UIParent:GetWidth()
    end
    
    self.frame:SetSize(width, height)
    self.frame:SetScale(scale)
    
    -- Fire size change event through API
    if LibsDataBar.API then
        LibsDataBar.API:NotifyPositionChange(self.id, "resize")
    end
end

---Update bar position based on configuration
function DataBar:UpdatePosition()
    local anchor = self.config.anchor
    local position = self.config.position
    
    self.frame:ClearAllPoints()
    
    if position == "top" then
        self.frame:SetPoint("TOP", UIParent, "TOP", anchor.x or 0, anchor.y or 0)
    elseif position == "top-center" then
        self.frame:SetPoint("TOP", UIParent, "TOP", 0, anchor.y or 0)
    elseif position == "top-left" then
        self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", anchor.x or 0, anchor.y or 0)
    elseif position == "top-right" then
        self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", anchor.x or 0, anchor.y or 0)
    elseif position == "bottom" then
        self.frame:SetPoint("BOTTOM", UIParent, "BOTTOM", anchor.x or 0, anchor.y or 0)
    elseif position == "bottom-center" then
        self.frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, anchor.y or 0)
    elseif position == "bottom-left" then
        self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", anchor.x or 0, anchor.y or 0)
    elseif position == "bottom-right" then
        self.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", anchor.x or 0, anchor.y or 0)
    elseif position == "left" then
        self.frame:SetPoint("LEFT", UIParent, "LEFT", anchor.x or 0, anchor.y or 0)
    elseif position == "left-center" then
        self.frame:SetPoint("LEFT", UIParent, "LEFT", anchor.x or 0, 0)
    elseif position == "right" then
        self.frame:SetPoint("RIGHT", UIParent, "RIGHT", anchor.x or 0, anchor.y or 0)
    elseif position == "right-center" then
        self.frame:SetPoint("RIGHT", UIParent, "RIGHT", anchor.x or 0, 0)
    elseif position == "center" then
        self.frame:SetPoint("CENTER", UIParent, "CENTER", anchor.x or 0, anchor.y or 0)
    else
        -- Custom positioning
        local point = anchor.point or "BOTTOM"
        local relativeTo = anchor.relativeTo or "UIParent"
        local relativePoint = anchor.relativePoint or "BOTTOM"
        local x = anchor.x or 0
        local y = anchor.y or 0
        
        self.frame:SetPoint(point, _G[relativeTo] or UIParent, relativePoint, x, y)
    end
    
    -- Apply strata and level for proper layering
    if self.config.behavior.strata then
        self.frame:SetFrameStrata(self.config.behavior.strata)
    end
    
    if self.config.behavior.level then
        self.frame:SetFrameLevel(self.config.behavior.level)
    end
    
    -- Fire position change event through API
    if LibsDataBar.API then
        LibsDataBar.API:NotifyPositionChange(self.id, "move")
    end
end

---Set bar position to top of screen
---@param x? number X offset (default: 0)
---@param y? number Y offset (default: 0)
function DataBar:SetPositionTop(x, y)
    self.config.position = "top"
    self.config.anchor.x = x or 0
    self.config.anchor.y = y or 0
    self:UpdatePosition()
end

---Set bar position to bottom of screen
---@param x? number X offset (default: 0)
---@param y? number Y offset (default: 0)
function DataBar:SetPositionBottom(x, y)
    self.config.position = "bottom"
    self.config.anchor.x = x or 0
    self.config.anchor.y = y or 0
    self:UpdatePosition()
end

---Set bar position to left side of screen
---@param x? number X offset (default: 0)
---@param y? number Y offset (default: 0)
function DataBar:SetPositionLeft(x, y)
    self.config.position = "left"
    self.config.anchor.x = x or 0
    self.config.anchor.y = y or 0
    self:UpdatePosition()
end

---Set bar position to right side of screen
---@param x? number X offset (default: 0)
---@param y? number Y offset (default: 0)
function DataBar:SetPositionRight(x, y)
    self.config.position = "right"
    self.config.anchor.x = x or 0
    self.config.anchor.y = y or 0
    self:UpdatePosition()
end

---Set custom bar position
---@param point string Anchor point
---@param relativeTo? string|Frame Relative frame (default: UIParent)
---@param relativePoint? string Relative anchor point (default: same as point)
---@param x? number X offset (default: 0)
---@param y? number Y offset (default: 0)
function DataBar:SetCustomPosition(point, relativeTo, relativePoint, x, y)
    self.config.position = "custom"
    self.config.anchor.point = point
    self.config.anchor.relativeTo = relativeTo or "UIParent"
    self.config.anchor.relativePoint = relativePoint or point
    self.config.anchor.x = x or 0
    self.config.anchor.y = y or 0
    self:UpdatePosition()
end

---Update bar appearance based on configuration
function DataBar:UpdateAppearance()
    local appearance = self.config.appearance
    
    if not appearance.background or not appearance.background.show then
        -- Hide background if not configured to show
        if self.frame.SetBackdrop then
            self.frame:SetBackdrop(nil)
        end
        if self.backgroundTexture then
            self.backgroundTexture:Hide()
        end
        if self.borderTexture then
            self.borderTexture:Hide()
        end
        return
    end
    
    local bg = appearance.background
    
    -- Use backdrop if available
    if self.frame.SetBackdrop and not self.useManualBackground then
        self.frame:SetBackdrop({
            bgFile = bg.texture or "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = appearance.border and appearance.border.texture,
            tile = false,
            tileSize = 0,
            edgeSize = appearance.border and appearance.border.size or 0,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        
        if bg.color then
            self.frame:SetBackdropColor(bg.color.r, bg.color.g, bg.color.b, bg.color.a)
        end
        
        if appearance.border and appearance.border.color then
            local bc = appearance.border.color
            self.frame:SetBackdropBorderColor(bc.r, bc.g, bc.b, bc.a)
        end
    else
        -- Use manual textures as fallback
        if not self.backgroundTexture then
            self.backgroundTexture = self.frame:CreateTexture(nil, "BACKGROUND")
        end
        
        self.backgroundTexture:SetTexture(bg.texture or "Interface\\Tooltips\\UI-Tooltip-Background")
        if bg.color then
            self.backgroundTexture:SetVertexColor(bg.color.r, bg.color.g, bg.color.b, bg.color.a)
        end
        self.backgroundTexture:SetAllPoints(self.frame)
        self.backgroundTexture:Show()
        
        -- Add border if configured
        if appearance.border and appearance.border.show then
            if not self.borderTexture then
                self.borderTexture = self.frame:CreateTexture(nil, "BORDER")
            end
            
            self.borderTexture:SetTexture(appearance.border.texture or "Interface\\Tooltips\\UI-Tooltip-Border")
            if appearance.border.color then
                local bc = appearance.border.color
                self.borderTexture:SetVertexColor(bc.r, bc.g, bc.b, bc.a)
            end
            self.borderTexture:SetAllPoints(self.frame)
            self.borderTexture:Show()
        end
    end
end

---Setup mouse event handling
function DataBar:SetupMouseHandling()
    self.frame:EnableMouse(true)
    
    -- Enable dragging
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetMovable(true)
    self.frame:SetClampedToScreen(true)
    
    -- Drag and drop handling
    self.frame:SetScript("OnDragStart", function(frame)
        if not InCombatLockdown() then
            self:StartDragging()
        end
    end)
    
    self.frame:SetScript("OnDragStop", function(frame)
        if not InCombatLockdown() then
            self:StopDragging()
        end
    end)
    
    -- Right-click for configuration
    self.frame:SetScript("OnMouseUp", function(frame, button)
        if button == "RightButton" then
            self:ShowContextMenu()
        end
    end)
    
    -- Auto-hide handling
    if self.config.behavior.autoHide then
        self.frame:SetScript("OnEnter", function()
            self:Show()
        end)
        
        self.frame:SetScript("OnLeave", function()
            self:StartAutoHideTimer()
        end)
    end
end

---Setup update timer for plugin updates
function DataBar:SetupUpdateTimer()
    -- Use C_Timer for efficient updates
    self.updateTimer = C_Timer.NewTicker(0.1, function()
        self:UpdatePlugins()
    end)
end

---Register necessary events
function DataBar:RegisterEvents()
    -- Register for UI scale changes
    LibsDataBar.events:RegisterEvent("UI_SCALE_CHANGED", function()
        self:UpdateSize()
        self:UpdatePosition()
        self:UpdateLayout()
    end, { owner = self.id })
    
    -- Register for combat state changes
    LibsDataBar.events:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        if self.config.behavior.combatHide then
            self:Hide()
        end
    end, { owner = self.id })
    
    LibsDataBar.events:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if self.config.behavior.combatHide then
            self:Show()
        end
    end, { owner = self.id })
end

---Add a plugin to this bar
---@param plugin table Plugin to add
---@return PluginButton? button Created plugin button or nil if failed
function DataBar:AddPlugin(plugin)
    if not plugin or not plugin.id then
        LibsDataBar:DebugLog("error", "DataBar:AddPlugin requires plugin with id")
        return nil
    end
    
    if self.plugins[plugin.id] then
        LibsDataBar:DebugLog("warning", "Plugin " .. plugin.id .. " already exists in bar " .. self.id)
        return self.plugins[plugin.id]
    end
    
    -- Create plugin button (will be implemented in PluginButton.lua)
    local button = self:CreatePluginButton(plugin)
    if not button then
        LibsDataBar:DebugLog("error", "Failed to create button for plugin " .. plugin.id)
        return nil
    end
    
    self.plugins[plugin.id] = button
    tinsert(self.pluginOrder, plugin.id)
    
    -- Apply current theme to the new button
    if LibsDataBar.themes and button then
        local currentTheme = LibsDataBar.themes:GetCurrentTheme()
        if currentTheme then
            LibsDataBar.themes:ApplyThemeToButton(button, currentTheme.button)
        end
    end
    
    -- Update layout
    self:UpdateLayout()
    
    -- Fire event
    if LibsDataBar.callbacks then
        LibsDataBar.callbacks:Fire("LibsDataBar_PluginAdded", self.id, plugin.id)
    end
    
    LibsDataBar:DebugLog("info", "Plugin added to bar: " .. plugin.id .. " -> " .. self.id)
    return button
end

---Remove a plugin from this bar
---@param pluginId string Plugin ID to remove
function DataBar:RemovePlugin(pluginId)
    local button = self.plugins[pluginId]
    if not button then
        return
    end
    
    -- Destroy button
    if button.frame then
        button.frame:Hide()
        button.frame:SetParent(nil)
        button.frame = nil
    end
    
    self.plugins[pluginId] = nil
    
    -- Remove from order list
    for i, id in ipairs(self.pluginOrder) do
        if id == pluginId then
            tremove(self.pluginOrder, i)
            break
        end
    end
    
    -- Update layout
    self:UpdateLayout()
    
    -- Fire event
    if LibsDataBar.callbacks then
        LibsDataBar.callbacks:Fire("LibsDataBar_PluginRemoved", self.id, pluginId)
    end
    
    LibsDataBar:DebugLog("info", "Plugin removed from bar: " .. pluginId .. " <- " .. self.id)
end

---Update layout of all plugins
function DataBar:UpdateLayout()
    if InCombatLockdown() then
        -- Queue update for after combat
        LibsDataBar:DebugLog("info", "Layout update queued for after combat: " .. self.id)
        return
    end
    
    local profiler = LibsDataBar.performance:StartProfiler("bar_layout_" .. self.id)
    
    local orientation = self.config.layout.orientation
    local alignment = self.config.layout.alignment
    local spacing = self.config.layout.spacing or 4
    local padding = self.config.layout.padding or {left=8, right=8, top=2, bottom=2}
    
    local currentX = padding.left
    local currentY = padding.top
    local maxHeight = 0
    
    -- Sort plugins by position
    local sortedPlugins = {}
    for _, pluginId in ipairs(self.pluginOrder) do
        local button = self.plugins[pluginId]
        if button and button.frame and button.frame:IsShown() then
            tinsert(sortedPlugins, button)
        end
    end
    
    -- Position plugins
    for i, button in ipairs(sortedPlugins) do
        button.frame:ClearAllPoints()
        
        if orientation == "horizontal" then
            button.frame:SetPoint("LEFT", self.frame, "LEFT", currentX, currentY)
            currentX = currentX + button.frame:GetWidth() + spacing
            maxHeight = math.max(maxHeight, button.frame:GetHeight())
        else
            button.frame:SetPoint("TOP", self.frame, "TOPLEFT", currentX, -currentY)
            currentY = currentY + button.frame:GetHeight() + spacing
        end
    end
    
    LibsDataBar.performance:StopProfiler("bar_layout_" .. self.id)
end

---Create a plugin button using the PluginButton framework
---@param plugin table Plugin object
---@return PluginButton? button Plugin button object
function DataBar:CreatePluginButton(plugin)
    if not LibsDataBar.PluginButton then
        LibsDataBar:DebugLog("error", "PluginButton framework not available")
        return nil
    end
    
    -- Get button configuration from bar config or plugin config
    local buttonConfig = {}
    
    -- Apply bar-level button defaults
    if self.config.button then
        for key, value in pairs(self.config.button) do
            buttonConfig[key] = value
        end
    end
    
    -- Apply plugin-specific button config if available
    if plugin.buttonConfig then
        for key, value in pairs(plugin.buttonConfig) do
            if type(value) == "table" and buttonConfig[key] then
                -- Merge table values
                for subkey, subvalue in pairs(value) do
                    buttonConfig[key][subkey] = subvalue
                end
            else
                buttonConfig[key] = value
            end
        end
    end
    
    -- Set height from bar configuration
    if self.config.size and self.config.size.height then
        buttonConfig.height = self.config.size.height - 4 -- Account for padding
    end
    
    -- Create the button using PluginButton framework
    local button = LibsDataBar.PluginButton:Create(plugin, self, buttonConfig)
    
    if button then
        LibsDataBar:DebugLog("debug", "Created PluginButton for plugin: " .. plugin.id)
    end
    
    return button
end

---Update all plugins in this bar
function DataBar:UpdatePlugins()
    for pluginId, button in pairs(self.plugins) do
        if button.plugin and button.plugin.OnUpdate then
            local profiler = LibsDataBar.performance:StartProfiler("plugin_update_" .. pluginId)
            button.plugin:OnUpdate(0.1) -- Fixed interval for now
            LibsDataBar.performance:StopProfiler("plugin_update_" .. pluginId)
        end
        
        -- Update button text if needed
        if button.plugin and button.plugin.GetText and button.frame and button.frame.SetText then
            local newText = button.plugin:GetText()
            if newText and button.frame:GetText() ~= newText then
                button.frame:SetText(newText)
            end
        end
    end
end

---Show the bar
function DataBar:Show()
    self.frame:Show()
    
    if LibsDataBar.callbacks then
        LibsDataBar.callbacks:Fire("LibsDataBar_BarShown", self.id)
    end
end

---Hide the bar
function DataBar:Hide()
    self.frame:Hide()
    
    if LibsDataBar.callbacks then
        LibsDataBar.callbacks:Fire("LibsDataBar_BarHidden", self.id)
    end
end

---Start auto-hide timer
function DataBar:StartAutoHideTimer()
    if not self.config.behavior.autoHide then return end
    
    if self.autoHideTimer then
        self.autoHideTimer:Cancel()
    end
    
    local delay = self.config.behavior.autoHideDelay or 2.0
    self.autoHideTimer = C_Timer.NewTimer(delay, function()
        self:Hide()
    end)
end

---Start dragging the bar
function DataBar:StartDragging()
    self.frame:StartMoving()
    self.isDragging = true
    
    -- Create visual feedback
    self:CreateDragIndicators()
    
    -- Fire drag start event
    if LibsDataBar.callbacks then
        LibsDataBar.callbacks:Fire("LibsDataBar_BarDragStart", self.id, self)
    end
    
    LibsDataBar:DebugLog("debug", "Started dragging bar: " .. self.id)
end

---Stop dragging the bar
function DataBar:StopDragging()
    self.frame:StopMovingOrSizing()
    self.isDragging = false
    
    -- Update position configuration
    local point, relativeTo, relativePoint, x, y = self.frame:GetPoint()
    self.config.anchor.point = point
    self.config.anchor.relativePoint = relativePoint  
    self.config.anchor.x = x
    self.config.anchor.y = y
    
    -- Determine new position based on location
    local newPosition = self:DeterminePositionFromLocation()
    if newPosition ~= self.config.position then
        self.config.position = newPosition
        LibsDataBar:DebugLog("info", "Bar " .. self.id .. " moved to: " .. newPosition)
    end
    
    -- Clean up visual feedback
    self:RemoveDragIndicators()
    
    -- Update all bar positions to prevent overlaps
    if LibsDataBar.UpdateBarPositions then
        LibsDataBar:UpdateBarPositions()
    end
    
    -- Fire drag stop event
    if LibsDataBar.callbacks then
        LibsDataBar.callbacks:Fire("LibsDataBar_BarDragStop", self.id, self, newPosition)
    end
    
    LibsDataBar:DebugLog("debug", "Stopped dragging bar: " .. self.id)
end

---Determine position based on current screen location
---@return string position Position (top, bottom, left, right)
function DataBar:DeterminePositionFromLocation()
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    
    local frameX = self.frame:GetLeft() + (self.frame:GetWidth() / 2)
    local frameY = self.frame:GetBottom() + (self.frame:GetHeight() / 2)
    
    -- Determine which edge is closest
    local distanceToBottom = frameY
    local distanceToTop = screenHeight - frameY
    local distanceToLeft = frameX
    local distanceToRight = screenWidth - frameX
    
    local minDistance = math.min(distanceToBottom, distanceToTop, distanceToLeft, distanceToRight)
    
    if minDistance == distanceToBottom then
        return "bottom"
    elseif minDistance == distanceToTop then
        return "top"
    elseif minDistance == distanceToLeft then
        return "left"
    else
        return "right"
    end
end

---Create visual indicators during dragging
function DataBar:CreateDragIndicators()
    -- Create snap zone indicators
    if not self.dragIndicators then
        self.dragIndicators = {}
        
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()
        
        -- Bottom indicator
        local bottomIndicator = CreateFrame("Frame", nil, UIParent)
        bottomIndicator:SetSize(screenWidth, 4)
        bottomIndicator:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
        bottomIndicator.texture = bottomIndicator:CreateTexture(nil, "OVERLAY")
        bottomIndicator.texture:SetAllPoints()
        bottomIndicator.texture:SetColorTexture(0, 1, 0, 0.5)
        bottomIndicator:Hide()
        self.dragIndicators.bottom = bottomIndicator
        
        -- Top indicator  
        local topIndicator = CreateFrame("Frame", nil, UIParent)
        topIndicator:SetSize(screenWidth, 4)
        topIndicator:SetPoint("TOP", UIParent, "TOP", 0, 0)
        topIndicator.texture = topIndicator:CreateTexture(nil, "OVERLAY")
        topIndicator.texture:SetAllPoints()
        topIndicator.texture:SetColorTexture(0, 1, 0, 0.5)
        topIndicator:Hide()
        self.dragIndicators.top = topIndicator
        
        -- Left indicator
        local leftIndicator = CreateFrame("Frame", nil, UIParent)
        leftIndicator:SetSize(4, screenHeight)
        leftIndicator:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
        leftIndicator.texture = leftIndicator:CreateTexture(nil, "OVERLAY")
        leftIndicator.texture:SetAllPoints()
        leftIndicator.texture:SetColorTexture(0, 1, 0, 0.5)
        leftIndicator:Hide()
        self.dragIndicators.left = leftIndicator
        
        -- Right indicator
        local rightIndicator = CreateFrame("Frame", nil, UIParent)
        rightIndicator:SetSize(4, screenHeight)
        rightIndicator:SetPoint("RIGHT", UIParent, "RIGHT", 0, 0)
        rightIndicator.texture = rightIndicator:CreateTexture(nil, "OVERLAY")
        rightIndicator.texture:SetAllPoints()
        rightIndicator.texture:SetColorTexture(0, 1, 0, 0.5)
        rightIndicator:Hide()
        self.dragIndicators.right = rightIndicator
    end
    
    -- Show all indicators
    for _, indicator in pairs(self.dragIndicators) do
        indicator:Show()
    end
end

---Remove visual indicators after dragging
function DataBar:RemoveDragIndicators()
    if self.dragIndicators then
        for _, indicator in pairs(self.dragIndicators) do
            indicator:Hide()
        end
    end
end

---Show context menu for bar configuration
function DataBar:ShowContextMenu()
    LibsDataBar:DebugLog("info", "Context menu for bar: " .. self.id .. " (coming in Phase 2)")
    -- This will be implemented in Phase 2 with proper menu system
end

---Destroy the bar and clean up resources
function DataBar:Destroy()
    -- Cancel timers
    if self.updateTimer then
        self.updateTimer:Cancel()
        self.updateTimer = nil
    end
    
    if self.autoHideTimer then
        self.autoHideTimer:Cancel()
        self.autoHideTimer = nil
    end
    
    -- Remove all plugins
    for pluginId in pairs(self.plugins) do
        self:RemovePlugin(pluginId)
    end
    
    -- Destroy frame
    if self.frame then
        self.frame:Hide()
        self.frame:SetParent(nil)
        self.frame = nil
    end
    
    -- Unregister from LibsDataBar
    LibsDataBar.bars[self.id] = nil
    
    -- Fire event
    if LibsDataBar.callbacks then
        LibsDataBar.callbacks:Fire("LibsDataBar_BarDestroyed", self.id)
    end
    
    LibsDataBar:DebugLog("info", "DataBar destroyed: " .. self.id)
end

-- Export DataBar class
LibsDataBar.DataBar = DataBar
return DataBar