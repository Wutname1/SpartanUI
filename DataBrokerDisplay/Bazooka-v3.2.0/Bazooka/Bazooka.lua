--[[
Name: Bazooka
Author(s): mitch0
Website: http://www.wowace.com/projects/bazooka/
Description: Bazooka is a FuBar like broker display
License: Public Domain
]]

local AppName, Bazooka = ...
local OptionsAppName = AppName .. "_Options"
local VERSION = AppName .. "-v3.2.0"

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)
local LibDualSpec = LibStub:GetLibrary("LibDualSpec-1.0", true)
local L = LibStub("AceLocale-3.0"):GetLocale(AppName)

-- internal vars

-- Remove all related ifs when the opacity setting for embedded icons gets fixed
local EnableOpacityWorkaround = false -- loaded from global options
-- Remove all related ifs when the setting for gradient background gets fixed
local EnableGradientWorkaround = true

local _ -- throwaway
local uiScale = 1.0 -- just to be safe...

local function makeColor(r, g, b, a)
  return { ["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a }
end

local function colorToHex(color)
  return ("%02x%02x%02x%02x"):format((color.a and color.a * 255 or 255), color.r*255, color.g*255, color.b*255)
end

local function getTexture(textureName, region, ...)
  if not region then
    return
  end
  if region.GetTexture and region:GetTexture() == textureName then
    return region
  end
  return getTexture(textureName, ...)
end

-- cached stuff

local _G = _G
local IsMainline = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
local IsAltKeyDown = _G.IsAltKeyDown
local IsShiftKeyDown = _G.IsShiftKeyDown
local IsModifierKeyDown = _G.IsModifierKeyDown
local GetCursorPosition = _G.GetCursorPosition
local GetAddOnInfo = _G.GetAddOnInfo or C_AddOns.GetAddOnInfo
local LoadAddOn = _G.LoadAddOn or C_AddOns.LoadAddOn
local GetScreenWidth = _G.GetScreenWidth
local GetScreenHeight = _G.GetScreenHeight
local UIParent = _G.UIParent
local CreateFrame = _G.CreateFrame
local InCombatLockdown = _G.InCombatLockdown
local tinsert = _G.tinsert
local tremove = _G.tremove
local tostring = _G.tostring
local tonumber = _G.tonumber
local print = _G.print
local pairs = _G.pairs
local type = _G.type
local unpack = _G.unpack
local wipe = _G.wipe
local math = _G.math
local GameTooltip = _G.GameTooltip
local IsInPetBattle = _G.C_PetBattles and _G.C_PetBattles.IsInBattle or function() return false end
local strtrim = _G.strtrim
local strsub = _G.strsub
local strlen = _G.strlen
local strsplit = _G.strsplit

-- hard-coded config stuff

local Defaults =  {
  bgTexture = "Blizzard Tooltip",
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
--  bgTexture = "Blizzard Dialog Background",
--  bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
--  edgeTexture = "Blizzard Tooltip",
--  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
  edgeTexture = "None",
  edgeFile = false,
  fontName = "Friz Quadrata TT",
  fontPath = GameFontNormal:GetFont(),
  minFrameWidth = 10,
  minFrameHeight = 10,
  maxFrameWidth = 2000,
  maxFrameHeight = 50,

  fadeOutDelay = 0.5,
  fadeOutDuration = 0.5,
  fadeInDuration = 0.25,
}

local BarDefaults = {
  hidden = false,
  marked = false,
  fadeInCombat = false,
  fadeOutOfCombat = false,
  disableMouseInCombat = true,
  disableMouseOutOfCombat = false,
  disableDuringPetBattle = true,
  fadeAlpha = 0.4,

  point = "TOP",
  relPoint = "TOP",
  x = 0,
  y = -50,

  tweakLeft = 0,
  tweakRight = 0,
  tweakTop = 0,
  tweakBottom = 0,

  leftMargin = 8,
  rightMargin = 8,
  leftSpacing = 8,
  rightSpacing = 8,
  centerSpacing = 16,
  iconTextSpacing = 2,

  font = Defaults.fontName,
  fontSize = 12,
  fontOutline = "",
  fontShadow = true,

  iconSize = 16,

  labelColor = makeColor(0.9, 0.9, 0.9),
  textColor = makeColor(1.0, 0.82, 0),
  suffixColor = makeColor(0, 0.82, 0),
  pluginOpacity = 1.0,

  attach = 'none',
  fitToContentWidth = false,

  strata = "MEDIUM",

  frameWidth = 256,
  frameHeight = 20,

  bgEnabled = true,
  bgTextureType = 'background',
  bgTexture = Defaults.bgTexture,
  bgBorderTexture = Defaults.edgeTexture,
  bgTile = false,
  bgTileSize = 32,
  bgEdgeSize = 16,
  bgColor = makeColor(0, 0, 0, 1.0),
  bgGradientColor = makeColor(0, 0, 0, 0),
  bgBorderColor = makeColor(0.8, 0.6, 0.0, 1.0),
}
local PluginDefaults = {
  enabled = false,
  bar = 1,
  area = 'left',
  pos = nil,
  hideTipOnClick = true,
  disableTooltip = false,
  disableTooltipInCombat = true,
  disableMouseInCombat = false,
  disableMouseOutOfCombat = false,
  forceHideTip = false,
  showIcon = true,
  showLabel = true,
  showTitle = true,
  showText = true,
  showValue = false,
  showSuffix = false,
  useLabelAsTitle = false,
  shrinkThreshold = 5,
  overrideTooltipScale = false,
  tooltipScale = 1.0,
  iconBorderClip = 0.07,
  alignment = "LEFT",
}

local Icon = [[Interface\AddOns\]] .. AppName .. [[\bzk_locked.tga]]
local UnlockedIcon = [[Interface\AddOns\]] .. AppName .. [[\bzk_unlocked.tga]]
local HighlightImage = [[Interface\AddOns\]] .. AppName .. [[\highlight.tga]]
local EmptyPluginWidth = 1
local NearSquared = 32 * 32
local MinDropPlaceHLDX = 3
local BzkDialogDisablePlugin = 'BAZOOKA_DISABLE_PLUGIN'
local MaxTweakPts = 5

Bazooka = LibStub("AceAddon-3.0"):NewAddon(Bazooka, AppName, "AceEvent-3.0")
_G.Bazooka = Bazooka
Bazooka:SetDefaultModuleState(false)

Bazooka.version = VERSION
Bazooka.AppName = AppName
Bazooka.Defaults = Defaults

Bazooka.draggedFrame = nil
Bazooka.bars = {}
Bazooka.attachedBars = {
  ['top'] = {},
  ['bottom'] = {},
}
Bazooka.plugins = {}
Bazooka.numBars = 0

Bazooka.AreaNames = {
  left = L["left"],
  cleft = L["cleft"],
  center = L["center"],
  cright = L["cright"],
  right = L["right"],
}

Bazooka.AttachNames = {
  top = L["top"],
  bottom = L["bottom"],
  none = L["none"],
}

-- Default DB stuff

local defaults = {
  global = {
    plugins = PluginDefaults,
    bars = BarDefaults,
    autoApply = true,
  },
  profile = {
    locked = false,
    adjustFrames = true,
    simpleTip = true,
    enableHL = true,
    disableDBIcon = true,
    numBars = 1,
    fadeOutDelay = Defaults.fadeOutDelay,
    fadeOutDuration = Defaults.fadeOutDuration,
    fadeInDuration = Defaults.fadeInDuration,

    bars = {
      ["**"] = BarDefaults,
      [1] = {
        attach = 'top',
      },
      [2] = {
        attach = 'bottom',
      },
    },
    plugins = {
      ["*"] = {
        ["**"] = PluginDefaults,
      },
      ["launcher"] = {
        ["**"] = {
          enabled = true,
          bar = 1,
          area = 'left',
          pos = nil,
          hideTipOnClick = true,
          disableTooltip = false,
          disableTooltipInCombat = true,
          disableMouseInCombat = false,
          disableMouseOutOfCombat = false,
          forceHideTip = false,
          showIcon = true,
          showLabel = false,
          showTitle = true,
          showText = false,
          shrinkThreshold = 0,
          overrideTooltipScale = false,
          tooltipScale = 1.0,
          iconBorderClip = 0.07,
        },
        [AppName] = {
          pos = 1,
        },
      },
      ["data source"] = {
        ["**"] = {
          enabled = true,
          bar = 1,
          area = 'right',
          pos = nil,
          hideTipOnClick = true,
          disableTooltip = false,
          disableTooltipInCombat = true,
          disableMouseInCombat = false,
          disableMouseOutOfCombat = false,
          forceHideTip = false,
          showIcon = true,
          showLabel = false,
          showTitle = false,
          showText = true,
          shrinkThreshold = PluginDefaults.shrinkThreshold,
          overrideTooltipScale = false,
          tooltipScale = 1.0,
          iconBorderClip = 0.07,
        },
      },
    },
  },
}

local function deepCopy(src)
  local res = {}
  for k, v in pairs(src) do
    if type(v) == 'table' then
      v = deepCopy(v)
    end
    res[k] = v
  end
  return res
end

local function setDeepCopyIndex(proto)
  proto.__index = function(t, k)
    local v = proto[k]
    if type(v) == 'table' then
      v = deepCopy(v)
    end
    t[k] = v
    return v
  end
end

local function updateUIScale()
  uiScale = UIParent:GetEffectiveScale()
end

local function getScaledCursorPosition()
  local x, y = GetCursorPosition()
  return x / uiScale, y / uiScale
end

local function distance2(x1, y1, x2, y2)
  return (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)
end

local function getDistance2Frame(x, y, frame)
  local left, bottom, width, height = frame:GetRect()
  local dx, dy = 0, 0
  if left > x then
    dx = left - x
  elseif x > left + width then
    dx = x - (left + width)
  end
  if bottom > y then
    dy = bottom - y
  elseif y > bottom + height then
    dy = y - (bottom + height)
  end
  return dx * dx + dy * dy
end

local function setupTooltip(owner, ttFrame, dx, dy)
  ttFrame = ttFrame or GameTooltip
  if not owner then
    return ttFrame
  end
  if ttFrame.SetOwner then
    ttFrame:SetOwner(owner, "ANCHOR_NONE")
  end
  if ttFrame.ClearLines then
    ttFrame:ClearLines()
  end
  ttFrame:ClearAllPoints()
  local cx, cy = owner:GetCenter()
  if cy < GetScreenHeight() / 2 then
    ttFrame:SetPoint("BOTTOM", owner, "TOP", dx, dy)
  else
    ttFrame:SetPoint("TOP", owner, "BOTTOM", dx, dy)
  end
  return ttFrame
end

local function stripColors(text)
  return tostring(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

---------------------------------

-- BEGIN Bar stuff

local function sumPluginsWidth(plugins)
  local w = 0
  for i = 1, #plugins do
    w = w + plugins[i].frame:GetWidth()
  end
  return w
end

local Bar = {
  id = nil,
  name = nil,
  db = nil,
  frame = nil,
  centerFrame = nil,
  allPlugins = {},
  plugins = {
    left = {},
    cleft = {},
    center = {},
    cright = {},
    right = {},
  },
  inset = 0,
  backdrop = nil,
  hl = nil,
  attach = nil,
  pos = nil,
}

setDeepCopyIndex(Bar)

Bar.OnEnter = function(frame)
  local self = frame.bzkBar or frame.bzkPlugin.bar
  self.isMouseInside = true
  if InCombatLockdown() then
    if self.db.fadeInCombat then
      self:fadeIn()
    end
  else
    if self.db.fadeOutOfCombat then
      self:fadeIn()
    end
  end
end

Bar.OnLeave = function(frame)
  local self = frame.bzkBar or frame.bzkPlugin.bar
  self.isMouseInside = false
  if InCombatLockdown() then
    if self.db.fadeInCombat then
      self:fadeOut()
    end
  else
    if self.db.fadeOutOfCombat then
      self:fadeOut()
    end
  end
end

Bar.OnDragStart = function(frame, button)
  if Bazooka.locked then
    return
  end
  if Bazooka.tipOwner then
    Bazooka.tipOwner:hideTip(true)
    Bazooka.tipOwner = nil
  end
  local self = frame.bzkBar
  updateUIScale()
  frame:SetAlpha(0.7)
  Bazooka.draggedFrame = frame
  if button == "LeftButton" then
    Bazooka:detachBar(self)
    Bazooka:updateAnchors()
    self.isMoving = true
    frame:StartMoving()
  else
    self.isMoving = nil
    if IsAltKeyDown() then
      frame:StartSizing(self:getSizingPoint(getScaledCursorPosition()))
    end
  end
end

Bar.OnDragStop = function(frame)
  if not Bazooka.draggedFrame then
    return
  end
  local self = frame.bzkBar
  Bazooka.draggedFrame = nil
  frame:StopMovingOrSizing()
  frame:SetAlpha(1.0)
  local attach, pos = self.db.attach, nil
  Bazooka:detachBar(self) -- double detach doesn't hurt (in case we move)
  if not Bazooka.locked then
    if self.isMoving then
      if IsAltKeyDown() then
        if attach == 'none' then
          attach = 'top'
        else
          attach = 'none'
        end
      end
      if attach == 'none' then
        self.db.point, _, self.db.relPoint, self.db.x, self.db.y = frame:GetPoint()
      else
        local cx, cy = frame:GetCenter()
        if cy < GetScreenHeight() / 2 then
          attach = 'bottom'
          cy = frame:GetBottom() or cy
          local bars = Bazooka.attachedBars[attach]
          for i = 1, #bars do
            local cb = bars[i]
            local cby = tonumber(cb.frame:GetBottom())
            if cy <= cby then
              pos = cb.db.pos
              break
            end
          end
        else
          attach = 'top'
          cy = frame:GetTop() or cy
          local bars = Bazooka.attachedBars[attach]
          for i = 1, #bars do
            local cb = bars[i]
            local cby = tonumber(cb.frame:GetTop())
            if cy >= cby then
              pos = cb.db.pos
              break
            end
          end
        end
      end
    else
      pos = self.db.pos
    end
    self.db.frameWidth = self.frame:GetWidth()
    self.db.frameHeight = self.frame:GetHeight()
  else
    attach, pos = self.db.attach, self.db.pos
  end
  self.isMoving = nil
  Bazooka:attachBar(self, attach, pos)
  Bazooka:updateAnchors()
  Bazooka:updateBarOptions()
end

Bar.OnMouseDown = function(frame, button, ...)
  if Bazooka.locked then
    return
  end
  local self = frame.bzkBar
  if button == 'RightButton' and not IsAltKeyDown() then
    Bazooka:openConfigDialog(Bazooka.barOpts, Bazooka:getSubAppName("bars"), self:getOptionsName())
  end
end


-- BEGIN EnableOpacityWorkaround
Bar.setAlphaByParts = function(frame, alpha)
  frame.bzkAlpha = alpha
  local self = frame.bzkBar
  if self.db.bgEnabled then
    if self.bgt then
      self:setGradientBg()
    else
      self.frame:SetBackdropColor(self.db.bgColor.r, self.db.bgColor.g, self.db.bgColor.b, self.db.bgColor.a * alpha)
    end
    self.frame:SetBackdropBorderColor(self.db.bgBorderColor.r, self.db.bgBorderColor.g, self.db.bgBorderColor.b, self.db.bgBorderColor.a * alpha)
  end
  for name, plugin in pairs(self.allPlugins) do
    plugin.frame:SetAlpha(plugin.frame:GetAlpha())
  end
end

Bar.getAlphaByParts = function(frame)
  return frame.bzkAlpha
end
-- END EnableOpacityWorkaround

-- BEGIN EnableGradientWorkaround
Bar.fixGradientOnSizeChanged = function(frame, w, h)
  local self = frame.bzkBar
  self:setGradientBg()
end
-- END EnableGradientWorkaround

Bar.initialOnUpdateFixFontMetricHack = function(frame)
  -- fix miscalculated font metrics
  local self = frame.bzkBar
  self:globalSettingsChanged()
  frame:SetScript("OnUpdate", nil)
end

function Bar:New(id, db)
  local bar = setmetatable({}, Bar)
  bar:enable(id, db)
  bar:applySettings()
  return bar
end

function Bar:getOptionsName()
  return "bar" .. self.id
end

function Bar:createFadeAnim()
  self.fadeAnimGrp = self.frame:CreateAnimationGroup()
  self.fadeAnim = self.fadeAnimGrp:CreateAnimation()
  self.fadeAnim.bzkBar = self
  self.fadeAnim:SetScript("OnUpdate", function(anim)
    if not anim:IsDelaying() then
      anim:GetRegionParent():SetAlpha(anim.startAlpha + (anim.change * anim:GetSmoothProgress()))
    end
  end)
  self.fadeAnim:SetScript("OnPlay", function(anim)
    anim.startAlpha = anim:GetRegionParent():GetAlpha()
  end)
  self.fadeAnim:SetScript("OnFinished", function(anim, requested)
    -- FIXME: schedule fadeOut if necessary
  end)
  self.fadeAnim.SetChange = function(anim, change)
    anim.change = change
  end
end

function Bar:setFullyHidden(flag)
  if flag then
    self.isFullyHidden = true
  elseif self.isFullyHidden then
    -- force text update on plugins, the updates were disabled
    self.isFullyHidden = nil
    for name, plugin in pairs(self.allPlugins) do
      if plugin.text then
        plugin:setText()
      end
    end
  end
end

local function calcFadeAnimDuration(change, fullChange, fullDuration)
  if fullChange < 0.05 and fullChange > -0.05 then
    return 0
  end
  return fullDuration * change / fullChange
end

function Bar:fadeIn(initAlpha)
  if self.fadeAnim then
    self.fadeAnimGrp:Stop()
  end
  if initAlpha then
    self.frame:SetAlpha(initAlpha)
  end
  self:setFullyHidden(false)
  local alpha = self.frame:GetAlpha()
  local change = 1.0 - alpha
  if change < 0.05 then
    self.frame:SetAlpha(1.0)
    return
  end
  local fullChange = 1.0 - self.db.fadeAlpha
  if alpha < self.db.fadeAlpha then
    fullChange = 1.0
  end
  local duration = calcFadeAnimDuration(change, fullChange, Bazooka.db.profile.fadeInDuration)
  if duration < 0.01 then
    self.frame:SetAlpha(1.0)
    return
  end
  if not self.fadeAnim then
    self:createFadeAnim()
  end
  self.fadeAnim:SetStartDelay(0)
  self.fadeAnim:SetDuration(duration)
  self.fadeAnim:SetChange(change)
  self.fadeAnimGrp:Play()
end

function Bar:fadeOut(delay, fadeAlpha, initAlpha)
  if self.fadeAnim then
    self.fadeAnimGrp:Stop()
  end
  if initAlpha then
    self.frame:SetAlpha(initAlpha)
  end
  fadeAlpha = fadeAlpha or self.db.fadeAlpha
  if fadeAlpha < 0.05 then
    fadeAlpha = 0
    self:setFullyHidden(true) -- this will disable text updates (see Plugin:setText() and Bar:fadeIn()), partial fix for ticket-37
  else
    self:setFullyHidden(false)
  end
  local alpha = self.frame:GetAlpha()
  local change = fadeAlpha - alpha
  if change < 0.05 and change > -0.05 then
    self.frame:SetAlpha(fadeAlpha)
    return
  end
  local fullChange, fullDuration
  if alpha < fadeAlpha then
    fullChange = fadeAlpha
    fullDuration = Bazooka.db.profile.fadeInDuration
  else
    fullChange = fadeAlpha - 1.0
    fullDuration = Bazooka.db.profile.fadeOutDuration
  end
  delay = delay or Bazooka.db.profile.fadeOutDelay
  local duration = calcFadeAnimDuration(change, fullChange, fullDuration)
  if duration < 0.01 then
    if delay < 0.01 then
      self.frame:SetAlpha(fadeAlpha)
      return
    end
    duration = 0.01 -- if duration is too small (maybe only if 0, but meh) the animation doesn't work properly
  end
  if not self.fadeAnim then
    self:createFadeAnim()
  end
  self.fadeAnim:SetStartDelay(delay)
  self.fadeAnim:SetDuration(duration)
  self.fadeAnim:SetChange(change)
  self.fadeAnimGrp:Play()
end

function Bar:enable(id, db)
  self.id = id
  self.name = Bazooka:getBarName(id)
  self.db = db
  if not self.frame then
    self.frame = CreateFrame("Frame", "BazookaBar_" .. id, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    self.frame.bzkBar = self
    self.frame:SetScript("OnUpdate", Bar.initialOnUpdateFixFontMetricHack)
    if EnableOpacityWorkaround then
      self.frame.bzkAlpha = self.frame:GetAlpha()
      self.frame.SetAlpha = Bar.setAlphaByParts
      self.frame.GetAlpha = Bar.getAlphaByParts
    end
    self.frame:EnableMouse(true)
    self.frame:SetClampedToScreen(false)
    self.frame:SetClampRectInsets(MaxTweakPts, -MaxTweakPts, -MaxTweakPts, MaxTweakPts)
    self.frame:RegisterForDrag("LeftButton", "RightButton")
    self.frame:SetScript("OnEnter", Bar.OnEnter)
    self.frame:SetScript("OnLeave", Bar.OnLeave)
    self.frame:SetScript("OnDragStart", Bar.OnDragStart)
    self.frame:SetScript("OnDragStop", Bar.OnDragStop)
    self.frame:SetScript("OnMouseDown", Bar.OnMouseDown)
    self.frame:SetMovable(true)
    self.frame:SetResizable(true)
    if self.frame.SetResizeBounds then
      self.frame:SetResizeBounds(Defaults.minFrameWidth, Defaults.minFrameHeight, Defaults.maxFrameWidth, Defaults.maxFrameHeight)
    else
      self.frame:SetMinResize(Defaults.minFrameWidth, Defaults.minFrameHeight)
      self.frame:SetMaxResize(Defaults.maxFrameWidth, Defaults.maxFrameHeight)
    end
    self.centerFrame = CreateFrame("Frame", nil, self.frame)
    self.centerFrame:EnableMouse(false)
    self.centerFrame:SetPoint("TOP", self.frame, "TOP", 0, 0)
    self.centerFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
  end
  self:updateCenterWidth()
  self.frame:Show()
end

function Bar:disable()
  if self.frame then
    self.frame:Hide()
  end
  for name, plugin in pairs(self.allPlugins) do
    plugin:disable()
  end
  wipe(self.allPlugins)
  for area, plugins in pairs(self.plugins) do
    wipe(plugins)
  end
end

function Bar:getTopBottom()
  if self.db.attach == 'top' then
    if self.parent then
      local top, bottom, pt, pb = self.parent:getTopBottom()
      local mt = pb + tonumber(self.db.tweakTop)
      local mb = mt - self.db.frameHeight
      return math.max(top, mt), math.min(bottom, mb), mt, mb
    else
      local mt = tonumber(self.db.tweakTop)
      local mb = mt - self.db.frameHeight
      return mt, mb, mt, mb
    end
  elseif self.db.attach == 'bottom' then
    if self.parent then
      local top, bottom, pt, pb = self.parent:getTopBottom()
      local mb = pt + tonumber(self.db.tweakBottom)
      local mt = mb + self.db.frameHeight
      return math.max(top, mt), math.min(bottom, mb), mt, mb
    else
      local mb = tonumber(self.db.tweakBottom)
      local mt = mb + self.db.frameHeight
      return mt, mb, mt, mb
    end
  end
end

function Bar:getAreaCoords(area)
  if area == 'left' then
    local left, bottom, width, height = self.frame:GetRect()
    return left, bottom + height / 2
  elseif area == 'cleft' then
    local left, bottom, width, height = self.centerFrame:GetRect()
    return left, bottom + height / 2
  elseif area == 'cright' then
    local left, bottom, width, height = self.centerFrame:GetRect()
    return left + width, bottom + height / 2
  elseif area == 'right' then
    local left, bottom, width, height = self.frame:GetRect()
    return left + width, bottom + height / 2
  else -- center
    local left, bottom, width, height = self.centerFrame:GetRect()
    return left + width / 2, bottom + height / 2
  end
end

function Bar:getDropPlace(x, y)
  local dstArea, dstPos
  local minDist = math.huge
  if self.db.hidden then
    return dstArea, dstPos, minDist
  end
  for area, plugins in pairs(self.plugins) do
    if #plugins == 0 then
      local dist = distance2(x, y, self:getAreaCoords(area))
      if dist < minDist then
        dstArea, dstPos, minDist = area, 1, dist
      end
    else
      for i = 1, #plugins do
        local pos, dist = plugins[i]:getDropPlace(x, y)
        if dist < minDist then
          dstArea, dstPos, minDist = area, pos, dist
        end
      end
    end
  end
  return dstArea, dstPos, minDist
end

function Bar:getSpacing(area)
  if area == 'left' then
    return self.db.leftSpacing
  elseif area == 'right' then
    return self.db.rightSpacing
  else
    return self.db.centerSpacing
  end
end

function Bar:getHighlightCenter(area, pos)
  local plugins = self.plugins[area]
  if #plugins == 0 then
    local x = self:getAreaCoords(area)
    return x
  end
  if pos < 0 then
    pos = -pos
    for i = 1, #plugins do
      local plugin = plugins[i]
      if pos <= plugin.db.pos then
        return plugin.frame:GetRight()
      end
    end
  else
    for i = 1, #plugins do
      local plugin = plugins[i]
      if pos <= plugin.db.pos then
        return plugin.frame:GetLeft()
      end
    end
  end
  return plugins[#plugins].frame:GetRight()
end

function Bar:highlight(area, pos)
  if not area then
    if self.hl then
      self.hl:Hide()
      self.lastHLArea, self.lastHLPos = nil
      local tt = setupTooltip()
      if tt:IsOwned(self.frame) then
        tt:Hide()
      end
      Bar.OnLeave(self.frame)
    end
    return
  end
  Bar.OnEnter(self.frame)
  if not self.hl then
    self.hlFrame = CreateFrame("Frame", "BazookaBarHLF_" .. self.id, self.frame)
    self.hlFrame:SetFrameLevel(self.frame:GetFrameLevel() + 5)
    self.hlFrame:EnableMouse(false)
    self.hlFrame:SetAllPoints()
    self.hl = self.hlFrame:CreateTexture("BazookaBarHL_" .. self.id, "OVERLAY")
    self.hl:SetTexture(HighlightImage)
  end
  local hlcx = self:getHighlightCenter(area, pos)
  local center = hlcx - self.frame:GetLeft()
  local dx = math.floor(self:getSpacing(area) / 2 + 0.5)
  if dx < MinDropPlaceHLDX then
    dx = MinDropPlaceHLDX
  end
  self.hl:ClearAllPoints()
  self.hl:SetPoint("TOP", self.frame, "TOP", 0, 0)
  self.hl:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
  self.hl:SetPoint("LEFT", self.frame, "LEFT", center - dx, 0)
  self.hl:SetPoint("RIGHT", self.frame, "LEFT", center + dx, 0)
  self.hl:Show()
  if area ~= self.lastHLArea or pos ~= self.lastHLPos then
    self.lastHLArea, self.lastHLPos = area, pos
    local dx = hlcx - self.frame:GetCenter()
    local tt = setupTooltip(self.frame, nil, dx, 0)
    tt:SetText(("%s - %s"):format(self.name, L[area]))
    tt:Show()
    tt:FadeOut()
  end
end

function Bar:detachPlugin(plugin)
  local plugins = self.plugins[plugin.area]
  local lp, rp, index
  for i = 1, #plugins do
    local p = plugins[i]
    if index then
      rp = p
      break
    end
    if p == plugin then
      index = i
    else
      lp = p
    end
  end
  if not index then
    return -- this should never happen
  end
  tremove(plugins, index)
  self.allPlugins[plugin.name] = nil
  plugin.frame:ClearAllPoints()
  self:setRightAttachPoint(lp, rp)
  self:setLeftAttachPoint(rp, lp)
  if plugin.area == 'center' then
    self:updateCenterWidth()
  end
  plugin.area = nil
  self:updateWidth()
end

function Bar:attachPlugin(plugin, area, pos)
  area = area or "left"
  plugin.bar = self
  plugin.area = area
  plugin.db.bar = self.id
  plugin.db.area = area
  local plugins = self.plugins[area]
  local lp, rp
  if not pos then
    local count = #self.plugins[area]
    if count > 0 then
      lp = plugins[count]
      plugin.db.pos = lp.db.pos + 1
    else
      plugin.db.pos = 1
    end
    tinsert(plugins, plugin)
  else
    if pos < 0 then
      pos = 1 - pos
    end
    plugin.db.pos = pos
    local rpi
    for i = 1, #plugins do
      local p = plugins[i]
      if pos <= p.db.pos then
        if not rp then
          rp = p
          rpi = i
        end
        if pos < p.db.pos then
          break
        end
        pos = pos + 1
        p.db.pos = pos
      elseif not rp then
        lp = p
      end
    end
    if rpi then
      tinsert(plugins, rpi, plugin)
    else
      tinsert(plugins, plugin)
    end
  end
  self.allPlugins[plugin.name] = plugin
  plugin.frame:SetParent(self.frame)
  self:setAttachPoints(lp, plugin, rp)
  plugin:globalSettingsChanged()
  if area == "center" then
    self:updateCenterWidth()
  end
end

function Bar:setLeftAttachPoint(plugin, lp)
  if not plugin then
    return
  end
  local area = plugin.area
  if area == "left" then
    if lp then
      plugin.frame:SetPoint("LEFT", lp.frame, "RIGHT", self.db.leftSpacing, 0)
    else
      plugin.frame:SetPoint("LEFT", self.frame, "LEFT", (self.inset + self.db.leftMargin), 0)
    end
  elseif area == "center" then
    if lp then
      plugin.frame:SetPoint("LEFT", lp.frame, "RIGHT", self.db.centerSpacing, 0)
    else
      plugin.frame:SetPoint("LEFT", self.centerFrame, "LEFT", self.db.centerSpacing, 0)
    end
  elseif area == "cright" then
    if lp then
      plugin.frame:SetPoint("LEFT", lp.frame, "RIGHT", self.db.centerSpacing, 0)
    else
      plugin.frame:SetPoint("LEFT", self.centerFrame, "RIGHT", 0, 0)
    end
  end
end

function Bar:setRightAttachPoint(plugin, rp)
  if not plugin then
    return
  end
  local area = plugin.area
  if area == "cleft" then
    if rp then
      plugin.frame:SetPoint("RIGHT", rp.frame, "LEFT", -self.db.centerSpacing, 0)
    else
      plugin.frame:SetPoint("RIGHT", self.centerFrame, "LEFT", 0, 0)
    end
  elseif area == "right" then
    if rp then
      plugin.frame:SetPoint("RIGHT", rp.frame, "LEFT", -self.db.rightSpacing, 0)
    else
      plugin.frame:SetPoint("RIGHT", self.frame, "RIGHT", -(self.inset + self.db.rightMargin), 0)
    end
  end
end

function Bar:setAttachPoints(lp, plugin, rp)
  plugin.frame:ClearAllPoints()
  plugin.frame:SetPoint("TOP", self.frame, "TOP")
  plugin.frame:SetPoint("BOTTOM", self.frame, "BOTTOM")
  self:setLeftAttachPoint(plugin, lp)
  self:setRightAttachPoint(plugin, rp)
  self:setRightAttachPoint(lp, plugin)
  self:setLeftAttachPoint(rp, plugin)
end

function Bar:updateLayout()
  for area, plugins in pairs(self.plugins) do
    for i = 1, #plugins do
      self:setAttachPoints(plugins[i - 1], plugins[i], plugins[i + 1])
    end
  end
  self:updateCenterWidth()
  self:updateWidth()
end

function Bar:updateCenterWidth()
  local cw = sumPluginsWidth(self.plugins.center)
  local numGaps = #self.plugins.center + 1
  cw = cw + (numGaps * self.db.centerSpacing)
  if cw <= 0 then
    cw = 1
  end
  self.centerFrame:SetWidth(cw)
end

local function numSideGaps(numPlugins)
  if numPlugins == 0 then
    return 0
  else
    return numPlugins - 1
  end
end

function Bar:updateWidth()
  if self.db.fitToContentWidth and self.db.attach == 'none' then
    local w = 2 * self.inset
    local numCenterPlugins = #self.plugins.cleft + #self.plugins.center + #self.plugins.cright
    if numCenterPlugins > 0 then
      local lw =
        sumPluginsWidth(self.plugins.left) + self.db.leftSpacing * numSideGaps(#self.plugins.left) + self.db.leftMargin +
        sumPluginsWidth(self.plugins.cleft) + self.db.centerSpacing * #self.plugins.cleft
      local rw =
        sumPluginsWidth(self.plugins.right) + self.db.rightSpacing * numSideGaps(#self.plugins.right) + self.db.rightMargin +
        sumPluginsWidth(self.plugins.cright) + self.db.centerSpacing * #self.plugins.cright
      if lw > rw then
        w = w + lw + lw + self.centerFrame:GetWidth()
      else
        w = w + rw + rw + self.centerFrame:GetWidth()
      end
    elseif #self.plugins.left > 0 then
      if #self.plugins.right > 0 then
        w = w +
          sumPluginsWidth(self.plugins.left) + self.db.leftSpacing * numSideGaps(#self.plugins.left) + self.db.leftMargin +
          sumPluginsWidth(self.plugins.right) + self.db.rightSpacing * numSideGaps(#self.plugins.right) + self.db.rightMargin +
          self.db.centerSpacing
      else
        w = w +
          sumPluginsWidth(self.plugins.left) + self.db.leftSpacing * numSideGaps(#self.plugins.left) + self.db.leftMargin +
          self.db.rightMargin
      end
    elseif #self.plugins.right > 0 then
      w = w +
        sumPluginsWidth(self.plugins.right) + self.db.rightSpacing * numSideGaps(#self.plugins.right) + self.db.rightMargin +
        self.db.leftMargin
    else
      w = self.db.frameWidth
    end
    if w < Defaults.minFrameWidth then
      w = Defaults.minFrameWidth
    end
    self.frame:SetWidth(w)
  end
end

function Bar:setId(id)
  if id == self.id then
    return
  end
  self.id = id
  self.name = Bazooka:getBarName(id)
  for name, plugin in pairs(self.allPlugins) do
    plugin.db.bar = id
  end
end

function Bar:toggleHidden(hiddenFlag)
  if hiddenFlag == nil then
    hiddenFlag = not self.db.hidden
  end
  if self.db.hidden == hiddenFlag then
    return
  end
  self.db.hidden = hiddenFlag
  if hiddenFlag then
    self:disableAndHide()
  else
    self:enableAndShow()
  end
end

function Bar:applySettings()
  if self.db.attach == 'none' then
    if self.db.frameWidth == 0 then
      self.db.frameWidth = GetScreenWidth() - self.db.tweakLeft + self.db.tweakRight
    end
    self.frame:SetWidth(self.db.frameWidth)
  end
  self.frame:SetHeight(self.db.frameHeight)
  self.frame:SetFrameStrata(self.db.strata)
  self:applyFontSettings()
  self:applyBGSettings()
  if self.db.hidden then
    self:disableAndHide(true)
  else
    self:enableAndShow(true)
  end
end

function Bar:getSizingPoint(x, y)
  if self.db.attach == 'top' then
    return "BOTTOM"
  elseif self.db.attach == 'bottom' then
    return "TOP"
  else -- none
    local left, bottom, width, height = self.frame:GetRect()
    -- lazy min()...
    local dl, dr, db, dt = x - left, left + width - x, y - bottom, bottom + height - y
    if dl <= width / 10 + 1 then
      return "LEFT"
    elseif dr <= width / 10 + 1 then
      return "RIGHT"
    elseif dt < db then
      return "TOP"
    else
      return "BOTTOM"
    end
  end
end

function Bar:toggleMouse(flag)
  if flag then
    self.frame:EnableMouse(true)
  else
    self.frame:EnableMouse(false)
    self.isMouseInside = false
  end
end

function Bar:setGradientBg()
  if self.bgt then
    if EnableOpacityWorkaround then
      local alpha = self.frame.bzkAlpha
      self.bgt:SetGradientAlpha(self.db.bgGradient, self.db.bgColor.r, self.db.bgColor.g, self.db.bgColor.b, self.db.bgColor.a * alpha, self.db.bgGradientColor.r, self.db.bgGradientColor.g, self.db.bgGradientColor.b, self.db.bgGradientColor.a * alpha)
    else
      self.bgt:SetGradientAlpha(self.db.bgGradient, self.db.bgColor.r, self.db.bgColor.g, self.db.bgColor.b, self.db.bgColor.a, self.db.bgGradientColor.r, self.db.bgGradientColor.g, self.db.bgGradientColor.b, self.db.bgGradientColor.a)
    end
  end
end

function Bar:applyBGSettings()
  if not self.db.bgEnabled then
    self.frame:SetBackdrop(nil)
    return
  end
  self.bg = self.bg or { insets = {} }
  local bg = self.bg
  if LSM then
    bg.bgFile = LSM:Fetch(self.db.bgTextureType, self.db.bgTexture, true)
    if not bg.bgFile then
      bg.bgFile = Defaults.bgFile
      LSM.RegisterCallback(self, "LibSharedMedia_Registered", "mediaUpdate")
    end
    if self.db.bgBorderTexture == 'None' then -- hack for beta green thing
      bg.edgeFile = false
    else
      bg.edgeFile = LSM:Fetch("border", self.db.bgBorderTexture, true)
      if not bg.edgeFile then
        bg.edgeFile = Defaults.edgeFile
        LSM.RegisterCallback(self, "LibSharedMedia_Registered", "mediaUpdate")
      end
    end
  else
    bg.bgFile = Defaults.bgFile
    bg.edgeFile = Defaults.edgeFile
  end
  bg.tile = self.db.bgTile
  bg.tileSize = self.db.bgTileSize
  bg.edgeSize = (bg.edgeFile and bg.edgeFile ~= [[Interface\None]]) and self.db.bgEdgeSize or 0
  if not self.db.bgInset then
    self.db.bgInset = Bazooka:getInsetForEdgeSize(self.db.bgEdgeSize)
  end
  local inset = math.min(bg.edgeSize, self.db.bgInset)
  if inset ~= self.inset then
    self.inset = inset
    self:updateLayout()
  end
  bg.insets.left = inset
  bg.insets.right = inset
  bg.insets.top = inset
  bg.insets.bottom = inset
  self.frame:SetBackdrop(bg)
  self.frame:SetBackdropColor(self.db.bgColor.r, self.db.bgColor.g, self.db.bgColor.b, self.db.bgColor.a)
  self.frame:SetBackdropBorderColor(self.db.bgBorderColor.r, self.db.bgBorderColor.g, self.db.bgBorderColor.b, self.db.bgBorderColor.a)
  if self.db.bgGradient and self.db.bgGradient ~= "" and self.db.bgGradientColor then
    self.bgt = getTexture(bg.bgFile, self.frame:GetRegions())
    self:setGradientBg()
    if EnableGradientWorkaround then
      self.frame:SetScript("OnSizeChanged", Bar.fixGradientOnSizeChanged)
    end
  else
    self.bgt = nil
    if EnableGradientWorkaround then
      self.frame:SetScript("OnSizeChanged", nil)
    end
  end
end

function Bar:applyFontSettings()
  if LSM then
    self.dbFontPath = LSM:Fetch("font", self.db.font, true)
    if not self.dbFontPath then
      LSM.RegisterCallback(self, "LibSharedMedia_Registered", "mediaUpdate")
      self.dbFontPath = Defaults.fontPath
      return
    end
  end
  self:globalSettingsChanged()
end

function Bar:mediaUpdate(event, mediaType, key)
  if mediaType == 'background' or mediaType == 'statusbar' then
    if key == self.db.bgTexture then
      self:applyBGSettings()
    end
  elseif mediaType == 'border' then
    if key == self.db.bgBorderTexture then
      self:applyBGSettings()
    end
  elseif mediaType == 'font' then
    if key == self.db.font then
      self:applyFontSettings()
    end
  end
end

function Bar:globalSettingsChanged()
  for name, plugin in pairs(self.allPlugins) do
    plugin:globalSettingsChanged()
  end
end

function Bar:attachTop(prevBar)
  if prevBar then
    self.frame:SetPoint("TOPLEFT", prevBar.frame, "BOTTOMLEFT", self.db.tweakLeft, self.db.tweakTop)
    self.frame:SetPoint("TOPRIGHT", prevBar.frame, "BOTTOMRIGHT", self.db.tweakRight, self.db.tweakTop)
  else
    self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.tweakLeft, self.db.tweakTop)
    self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", self.db.tweakRight, self.db.tweakTop)
  end
end

function Bar:attachBottom(prevBar)
  if prevBar then
    self.frame:SetPoint("BOTTOMLEFT", prevBar.frame, "TOPLEFT", self.db.tweakLeft, self.db.tweakBottom)
    self.frame:SetPoint("BOTTOMRIGHT", prevBar.frame, "TOPRIGHT", self.db.tweakRight, self.db.tweakBottom)
  else
    self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.tweakLeft, self.db.tweakBottom)
    self.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", self.db.tweakRight, self.db.tweakBottom)
  end
end

function Bar:enableAndShow(skipFadeAnim)
  if IsInPetBattle() and self.db.disableDuringPetBattle then
    self:disableAndHide(skipFadeAnim)
  elseif InCombatLockdown() then
    self:toggleMouse(not self.db.disableMouseInCombat)
    if self.db.fadeInCombat and not self.isMouseInside then
      self:fadeOut(0, nil, skipFadeAnim and self.db.fadeAlpha or nil)
    else
      self:fadeIn(skipFadeAnim and 1.0 or nil)
    end
    for name, plugin in pairs(self.allPlugins) do
      plugin:toggleMouse(not plugin.db.disableMouseInCombat)
    end
  else
    self:toggleMouse(not self.db.disableMouseOutOfCombat)
    if self.db.fadeOutOfCombat and not self.isMouseInside then
      self:fadeOut(0, nil, skipFadeAnim and self.db.fadeAlpha or nil)
    else
      self:fadeIn(skipFadeAnim and 1.0 or nil)
    end
    for name, plugin in pairs(self.allPlugins) do
      plugin:toggleMouse(not plugin.db.disableMouseOutOfCombat)
    end
  end
end

function Bar:disableAndHide(skipFadeAnim)
  self:toggleMouse(false)
  for name, plugin in pairs(self.allPlugins) do
    plugin:toggleMouse(false)
  end
  self:fadeOut(0, 0, skipFadeAnim and 0)
end

Bazooka.Bar = Bar

-- END Bar stuff

-- BEGIN Plugin stuff

local Plugin = {
  name = nil,
  dataobj = nil,
  db = nil,
  frame = nil,
  icon = nil,
  text = nil,
  label = nil,
  hl = nil,
  iconSize = BarDefaults.iconSize,
  iconTextSpacing = BarDefaults.iconTextSpacing,
  fontSize = BarDefaults.fontSize,
  labelColorHex = colorToHex(BarDefaults.labelColor),
  suffixColorHex = colorToHex(BarDefaults.suffixColor),
}

setDeepCopyIndex(Plugin)

Plugin.OnEnter = function(frame, ...)
  local self = frame.bzkPlugin
  self.bar.OnEnter(frame)
  if Bazooka.draggedFrame then
    return
  end
  if Bazooka.db.profile.enableHL then
    self:highlight(true)
  end
  self:showTip()
end

Plugin.OnLeave = function(frame, ...)
  local self = frame.bzkPlugin
  self.bar.OnLeave(frame)
  self:highlight(nil)
  self:hideTip()
end

Plugin.OnMouseDown = function(frame, ...)
  local self = frame.bzkPlugin
  if self.db.hideTipOnClick then
    self:hideTip(true)
  end
end

Plugin.OnMouseWheel = function(frame, ...)
  local self = frame.bzkPlugin
  if self.db.hideTipOnClick then
    self:hideTip(true)
  end
  if self.dataobj.OnMouseWheel then
    self.dataobj.OnMouseWheel(frame, ...)
  end
end

Plugin.OnClick = function(frame, ...)
  local self = frame.bzkPlugin
  if self.dataobj.OnClick then
    self.dataobj.OnClick(frame, ...)
  end
end

Plugin.OnDoubleClick = function(frame, ...)
  local self = frame.bzkPlugin
  if self.dataobj.OnDoubleClick then
    self.dataobj.OnDoubleClick(frame, ...)
  elseif self.dataobj.OnClick then
    self.dataobj.OnClick(frame, ...)
  end
end

Plugin.OnUpdate = function(frame)
  local x, y = getScaledCursorPosition()
  if x ~= Bazooka.lastX or y ~= Bazooka.lastY then
    Bazooka.lastX, Bazooka.lastY = x, y
    Bazooka:highlight(Bazooka:getDropPlace(x, y))
  end
end

Plugin.OnDragStart = function(frame)
  if Bazooka.locked then
    return
  end
  if Bazooka.tipOwner then
    Bazooka.tipOwner:hideTip(true)
    Bazooka.tipOwner = nil
  end
  local self = frame.bzkPlugin
  self:highlight(nil)
  self:detach()
  updateUIScale()
  frame:SetAlpha(0.7)
  Bazooka.draggedFrame, Bazooka.lastX, Bazooka.lastY = frame, nil, nil
  frame:StartMoving()
  frame:SetScript("OnUpdate", Plugin.OnUpdate)
end

Plugin.OnDragStop = function(frame)
  if not Bazooka.draggedFrame then
    return
  end
  local self = frame.bzkPlugin
  Bazooka.draggedFrame = nil
  frame:SetScript("OnUpdate", nil)
  frame:StopMovingOrSizing()
  frame:SetAlpha(1.0)
  Bazooka:highlight(nil)
  if Bazooka.locked then
    self:reattach()
    return
  end
  local bar, area, pos = Bazooka:getDropPlace(getScaledCursorPosition())
  if bar then
    bar:attachPlugin(self, area, pos)
    Bazooka:updatePluginOptions()
  else
    self:reattach()
    Bazooka:openStaticDialog(BzkDialogDisablePlugin, self, self:getTitle())
  end
end

-- BEGIN EnableOpacityWorkaround
Plugin.setAlphaByParts = function(frame, alpha)
  frame.bzkAlpha = alpha
  local self = frame.bzkPlugin
  if self.bar then
    alpha = alpha * self.bar.frame:GetAlpha()
  end
  if self.icon then
    self.icon:SetAlpha(alpha)
  end
  if self.text then
    self.text:SetAlpha(alpha)
  end
end

Plugin.getAlphaByParts = function(frame)
  return frame.bzkAlpha
end
-- END EnableOpacityWorkaround

function Plugin:New(name, dataobj, db)
  local plugin = setmetatable({}, Plugin)
  plugin.name = name
  plugin.dataobj = dataobj

  if dataobj.tocname then
    local addonName, addonTitle = GetAddOnInfo(dataobj.tocname or name)
    plugin.title = name .. '[' .. (addonTitle or addonName) .. ']'
  else
    plugin.title = name
  end
  plugin.db = db
  plugin:applySettings()
  return plugin
end

function Plugin:getTitle()
  if self.db.useLabelAsTitle and self.dataobj.label then
    local title = stripColors(self.dataobj.label)
    if title ~= "" then
      return title
    end
  end
  return self.title
end

function Plugin:setTipScale(tt)
  if self.db.overrideTooltipScale then
    self.origTipScale = tt:GetScale()
    tt:SetScale(self.db.tooltipScale)
  end
end

function Plugin:resetTipScale(tt)
  if self.origTipScale then
    tt:SetScale(self.origTipScale)
    self.origTipScale = nil
  end
end

function Plugin:showTip(modifierKey, modifierState)
  if Bazooka.checkForceHide then
    Bazooka.checkForceHide:forceHideFrames(UIParent:GetChildren())
    Bazooka.checkForceHide = nil
  end
  local origTipType = self.tipType
  if Bazooka.tipOwner then
    Bazooka.tipOwner:hideTip(true)
    Bazooka.tipOwner = nil
  end
  if self.db.disableTooltip or (self.db.disableTooltipInCombat and InCombatLockdown()) then
    return
  end
  if self.db.manualTooltip then
    if Bazooka.db.profile.manualTooltipToggle then
      if not IsModifierKeyDown() then
        return
      end
    else
      if not IsModifierKeyDown() and not origTipType then
        return
      end
    end
  end
  Bazooka.tipOwner = self
  if Bazooka.db.profile.simpleTip and IsAltKeyDown() and not modifierKey then
    self.tipType = 'simple'
    local tt = setupTooltip(self.frame)
    tt:SetText(self:getTitle())
    tt:Show()
    return
  end
  local dataobj = self.dataobj
  if dataobj.tooltip then
    self.tipType = 'tooltip'
    local tt = setupTooltip(self.frame, dataobj.tooltip)
    self:setTipScale(tt)
    tt:Show()
  elseif dataobj.OnEnter then
    self.tipType = 'OnEnter'
    GameTooltip:Hide()
    self:setTipScale(GameTooltip)
    dataobj.OnEnter(self.frame)
  elseif dataobj.OnTooltipShow then
    self.tipType = 'OnTooltipShow'
    local tt = setupTooltip(self.frame)
    self:setTipScale(tt)
    dataobj.OnTooltipShow(tt)
    tt:Show()
  elseif Bazooka.db.profile.simpleTip then
    self.tipType = 'simple'
    local tt = setupTooltip(self.frame)
    self:setTipScale(tt)
    tt:SetText(self:getTitle())
    tt:Show()
  end
end

function Plugin:toggleMouse(flag)
  self.frame:EnableMouse(flag)
  self.frame:EnableMouseWheel(flag)
end

-- hides frames that are not Bazooka's but are anchored to our frame
-- useage: plugin:forceHideFrames(UIParent:GetChildren())
function Plugin:forceHideFrames(frame, ...)
  if not frame then
    return
  end
  if not frame:IsForbidden() then
    if not frame.bzkPlugin then
      -- we assume that if the frame is anchored to us, it's _only_ anchored to us
      local _, relativeTo = frame:GetPoint()
      if relativeTo == self.frame then
        frame:Hide()
      end
    end
  end
  return self:forceHideFrames(...)
end

function Plugin:hideTip(force)
  if not Bazooka.tipOwner then
    return
  end
  Bazooka.tipOwner = nil
  if not self.tipType then
    return
  end
  if self.tipType == 'simple' then
    local tt = setupTooltip()
    tt:Hide()
    self:resetTipScale(tt)
  elseif self.tipType == 'OnTooltipShow' then
    if self.dataobj.OnLeave then
      self.dataobj.OnLeave(self.frame)
    end
    local tt = setupTooltip()
    tt:Hide()
    self:resetTipScale(tt)
  elseif self.tipType == 'OnEnter' then
    if self.dataobj.OnLeave then
      self.dataobj.OnLeave(self.frame)
    end
    self:resetTipScale(GameTooltip)
  elseif self.tipType == 'tooltip' then
    local tt = self.dataobj.tooltip
    tt:Hide()
    self:resetTipScale(tt)
  end
  self.tipType = nil
  if self.db.forceHideTip then
    if force then
      self:forceHideFrames(UIParent:GetChildren())
    else
      Bazooka.checkForceHide = self
    end
  end
end

function Plugin:getDropPlace(x, y)
  local left, bottom, width, height = self.frame:GetRect()
  local ld = distance2(x, y, left, bottom + height / 2)
  local rd = distance2(x, y, left + width, bottom + height / 2)
  if ld < rd then
    return self.db.pos, ld
  else
    return -self.db.pos, rd
  end
end

function Plugin:highlight(flag)
  if flag then
    if not self.hl then
      self.hl = self.frame:CreateTexture("BazookaHL_" .. self.name, "OVERLAY")
      self.hl:SetTexture(HighlightImage)
      self.hl:SetAllPoints()
    end
    self.frame:SetAlpha(1.0)
    self.hl:Show()
  else
    local bdb = self.bar and self.bar.db or BarDefaults
    self.frame:SetAlpha(bdb.pluginOpacity)
    if self.hl then
      self.hl:Hide()
    end
  end
end

function Plugin:globalSettingsChanged()
  local bdb = self.bar and self.bar.db or BarDefaults
  self.labelColorHex = colorToHex(bdb.labelColor)
  self.suffixColorHex = colorToHex(bdb.suffixColor)
  self.iconTextSpacing = bdb.iconTextSpacing
  self.iconSize = bdb.iconSize
  self.fontSize = bdb.fontSize
  if self.text then
    local dbFontPath = self.bar and self.bar.dbFontPath or bdb.fontPath
    local fontPath, fontSize, fontOutline = self.text:GetFont()
    fontOutline = fontOutline or ""
    if dbFontPath ~= fontPath or bdb.fontSize ~= fontSize or bdb.fontOutline ~= fontOutline then
      self.text:SetFont(dbFontPath, self.fontSize, bdb.fontOutline)
    end
    if bdb.fontShadow then
      self.text:SetShadowOffset(1, -1)
    else
      self.text:SetShadowOffset(0, 0)
    end
    self.text:SetTextColor(bdb.textColor.r, bdb.textColor.g, bdb.textColor.b, bdb.textColor.a)
    self:setText()
  end
  if self.icon then
    self.icon:SetWidth(self.iconSize)
    self.icon:SetHeight(self.iconSize)
  end
  self.frame:SetAlpha(bdb.pluginOpacity)
  self:updateLayout(true)
  if bdb.hidden then
    self:toggleMouse(false)
  elseif InCombatLockdown() then
    self:toggleMouse(not self.db.disableMouseInCombat)
  else
    self:toggleMouse(not self.db.disableMouseOutOfCombat)
  end
end

function Plugin:createIcon()
  self.icon = self.frame:CreateTexture("BazookaPluginIcon_" .. self.name, "ARTWORK")
  self.icon:ClearAllPoints()
  local iconSize = BarDefaults.iconSize
  self.icon:SetWidth(iconSize)
  self.icon:SetHeight(iconSize)
end

function Plugin:createText()
  self.text = self.frame:CreateFontString("BazookaPluginText_" .. self.name, "ARTWORK", "GameFontNormal")
  self.text:SetFont(Defaults.fontPath, BarDefaults.fontSize, BarDefaults.fontOutline)
  self.text:SetWordWrap(false)
end

function Plugin:updateLayout(forced)
  local align = self.db.alignment or "LEFT"
  if self.icon then
    self.icon:ClearAllPoints()
    self.icon:SetPoint(align, self.frame, align, 0, 0)
  end

  local w = 0
  if self.db.showText or self.db.showValue or self.db.showLabel then
    local tw = self.text:GetStringWidth()
    local iw = self.db.showIcon and self.icon:GetWidth() or 0
    if tw > 0 then
      if self.db.maxTextWidth and self.db.maxTextWidth < tw then
        tw = self.db.maxTextWidth
      end
      local offset = (iw > 0) and (iw + self.iconTextSpacing) or 0
      self.text:ClearAllPoints()
      if align == "LEFT" then
        self.text:SetPoint(align, self.frame, align, offset, 0)
      else
        self.text:SetPoint(align, self.frame, align, -offset, 0)
      end
      self.text:SetJustifyH(align)
      w = offset + tw
    elseif iw > 0 then
      w = iw
    else
      w = EmptyPluginWidth
    end
  elseif self.db.showIcon then
    local iw = self.icon:GetWidth()
    if iw > 0 then
      w = iw
    else
      w = EmptyPluginWidth
    end
  else
    w = EmptyPluginWidth
  end
  local ow = self.origWidth or self.frame:GetWidth()
  if forced or w > ow or w < ow - self.db.shrinkThreshold then
    self.origWidth = w
    self.frame:SetWidth(w)
    if self.bar then
      if self.area == 'center' then
        self.bar:updateCenterWidth()
      end
      self.bar:updateWidth()
    end
  end
end

function Plugin:enable()
  if not self.frame then
    self.frame = CreateFrame("Button", "BazookaPlugin_" .. self.name, UIParent)
    self.frame.bzkPlugin = self
    if EnableOpacityWorkaround then
      self.frame.bzkAlpha = self.frame:GetAlpha()
      self.frame.SetAlpha = Plugin.setAlphaByParts
      self.frame.GetAlpha = Plugin.getAlphaByParts
    end
    self.frame:RegisterForDrag("LeftButton")
    self.frame:RegisterForClicks("AnyUp")
    self.frame:SetMovable(true)
    self.frame:SetScript("OnEnter", Plugin.OnEnter)
    self.frame:SetScript("OnLeave", Plugin.OnLeave)
    self.frame:SetScript("OnClick", Plugin.OnClick)
    self.frame:SetScript("OnDoubleClick", Plugin.OnDoubleClick)
    self.frame:SetScript("OnMouseDown", Plugin.OnMouseDown)
    self.frame:SetScript("OnDragStart", Plugin.OnDragStart)
    self.frame:SetScript("OnDragStop", Plugin.OnDragStop)
    self.frame:SetScript("OnMouseWheel", Plugin.OnMouseWheel)
    if self.dataobj.OnReceiveDrag then
      self.frame:SetScript("OnReceiveDrag", self.dataobj.OnReceiveDrag)
    end
    self.frame:EnableMouse(true)
    self.frame:EnableMouseWheel(true)
  end
  self.frame:Show()
end

function Plugin:disable()
  if self.frame then
    self.frame:ClearAllPoints()
    self.frame:Hide()
    self.bar = nil
  end
  LDB.UnregisterAllCallbacks(self)
end

function Plugin:updateLDBCallback(attr, method, reg)
  local callback = ("LibDataBroker_AttributeChanged_%s_%s"):format(self.name, attr)
  if reg then
    LDB.RegisterCallback(self, callback, method)
  else
    LDB.UnregisterCallback(self, callback)
  end
end

function Plugin:updateLDBCallbacks()
  self:updateLDBCallback("icon", "setIcon", self.db.showIcon)
  self:updateLDBCallback("iconCoords", "setIconCoords", self.db.showIcon)
  self:updateLDBCallback("iconR", "setIconColor", self.db.showIcon)
  self:updateLDBCallback("iconG", "setIconColor", self.db.showIcon)
  self:updateLDBCallback("iconB", "setIconColor", self.db.showIcon)

  self:updateLDBCallback("label", "updateLabel", self.db.showLabel)
  self:updateLDBCallback("text", "setText", self.db.showText)
  self:updateLDBCallback("value", "setText", self.db.showValue)
  self:updateLDBCallback("suffix", "setText", self.db.showSuffix)
end

function Plugin:applySettings()
  if not self.db.enabled then
    self:detach()
    self:disable()
    return
  end
  self:enable()
  if self.db.showIcon then
    if not self.icon then
      self:createIcon()
    end
    self:setIcon()
    self:setIconColor()
    self:setIconCoords()
    self.icon:Show()
  elseif self.icon then
    self.icon:Hide()
  end
  if self.db.showText or self.db.showValue or self.db.showLabel then
    if not self.text then
      self:createText()
    end
    self.text:SetWidth(self.db.maxTextWidth or 0)
    if self.db.showLabel then
      self:updateLabel()
    else
      self:setText()
    end
    self.text:Show()
  elseif self.text then
    self.text:SetFormattedText("")
    self.text:Hide()
  end
  if not self.bar or self.bar.id ~= self.db.bar or self.area ~= self.db.area then
    self:detach()
    Bazooka:attachPlugin(self)
  end
  self:globalSettingsChanged()
  self:updateLabel()
  self:updateLayout(true)
  self:updateLDBCallbacks()
end

function Plugin:setIcon()
  if not self.db.showIcon then
    return
  end
  local dataobj = self.dataobj
  local icon = self.icon
  icon:SetTexture(dataobj.icon)
  if self.db.iconBorderClip > 0 and not dataobj.iconCoords then
    local tl, br = self.db.iconBorderClip, (1 - self.db.iconBorderClip)
    icon:SetTexCoord(tl, br, tl, br)
  end
end

function Plugin:setIconColor()
  if not self.db.showIcon then
    return
  end
  local dataobj = self.dataobj
  if dataobj.iconR then
    self.icon:SetVertexColor(dataobj.iconR, dataobj.iconG, dataobj.iconB)
  end
end

function Plugin:setIconCoords()
  if not self.db.showIcon then
    return
  end
  local dataobj = self.dataobj
  if dataobj.iconCoords then
    self.icon:SetTexCoord(unpack(dataobj.iconCoords))
  end
end

function Plugin:setText()
  if self.bar and self.bar.isFullyHidden then
    return
  end
  local dataobj = self.dataobj
  if self.db.showLabel and self.label then
    if self.db.showText and dataobj.text then
      if self.db.showValue and dataobj.value then
        if self.db.showSuffix and dataobj.suffix then
          if self.db.stripColors then
            self.text:SetFormattedText("|c%s%s:|r %s %s |c%s%s|r", self.labelColorHex, stripColors(self.label), stripColors(dataobj.text), stripColors(dataobj.value), self.suffixColorHex, stripColors(dataobj.suffix))
          else
            self.text:SetFormattedText("|c%s%s:|r %s %s |c%s%s|r", self.labelColorHex, self.label, dataobj.text, dataobj.value, self.suffixColorHex, dataobj.suffix)
          end
        else
          if self.db.stripColors then
            self.text:SetFormattedText("|c%s%s:|r %s %s", self.labelColorHex, stripColors(self.label), stripColors(dataobj.text), stripColors(dataobj.value))
          else
            self.text:SetFormattedText("|c%s%s:|r %s %s", self.labelColorHex, self.label, dataobj.text, dataobj.value)
          end
        end
      else
        if self.db.stripColors then
          self.text:SetFormattedText("|c%s%s:|r %s", self.labelColorHex, stripColors(self.label), stripColors(dataobj.text))
        else
          self.text:SetFormattedText("|c%s%s:|r %s", self.labelColorHex, self.label, dataobj.text)
        end
      end
    elseif self.db.showValue and dataobj.value then
      if self.db.showSuffix and dataobj.suffix then
        if self.db.stripColors then
          self.text:SetFormattedText("|c%s%s:|r %s |c%s%s|r", self.labelColorHex, stripColors(self.label), stripColors(dataobj.value), self.suffixColorHex, stripColors(dataobj.suffix))
        else
          self.text:SetFormattedText("|c%s%s:|r %s |c%s%s|r", self.labelColorHex, self.label, dataobj.value, self.suffixColorHex, dataobj.suffix)
        end
      else
        if self.db.stripColors then
          self.text:SetFormattedText("|c%s%s:|r %s", self.labelColorHex, stripColors(self.label), stripColors(dataobj.value))
        else
          self.text:SetFormattedText("|c%s%s:|r %s", self.labelColorHex, self.label, dataobj.value)
        end
      end
    else
      if self.db.stripColors then
        self.text:SetFormattedText("|c%s%s|r", self.labelColorHex, stripColors(self.label))
      else
        self.text:SetFormattedText("|c%s%s|r", self.labelColorHex, self.label)
      end
    end
    self:updateLayout()
  elseif self.db.showText and dataobj.text then
    if self.db.showValue and dataobj.value then
      if self.db.showSuffix and dataobj.suffix then
        if self.db.stripColors then
          self.text:SetFormattedText("%s %s |c%s%s|r", stripColors(dataobj.text), stripColors(dataobj.value), self.suffixColorHex, stripColors(dataobj.suffix))
        else
          self.text:SetFormattedText("%s %s |c%s%s|r", dataobj.text, dataobj.value, self.suffixColorHex, dataobj.suffix)
        end
      else
        if self.db.stripColors then
          self.text:SetFormattedText("%s %s", stripColors(dataobj.text), stripColors(dataobj.value))
        else
          self.text:SetFormattedText("%s %s", dataobj.text, dataobj.value)
        end
      end
    else
      if self.db.stripColors then
        self.text:SetFormattedText("%s", stripColors(dataobj.text))
      else
        self.text:SetFormattedText("%s", dataobj.text)
      end
    end
    self:updateLayout()
  elseif self.db.showValue and dataobj.value then
    if self.db.showSuffix and dataobj.suffix then
      if self.db.stripColors then
        self.text:SetFormattedText("%s |c%s%s|r", stripColors(dataobj.value), self.suffixColorHex, stripColors(dataobj.suffix))
      else
        self.text:SetFormattedText("%s |c%s%s|r", dataobj.value, self.suffixColorHex, dataobj.suffix)
      end
    else
      if self.db.stripColors then
        self.text:SetFormattedText("%s", stripColors(dataobj.value))
      else
        self.text:SetFormattedText("%s", dataobj.value)
      end
    end
    self:updateLayout()
  elseif self.text then
    self.text:SetFormattedText("")
    self:updateLayout()
  end
end

function Plugin:updateLabel()
  self.label = self.dataobj.label
  if not self.label and self.db.showTitle then
    self.label = self.title
  end
  self:setText()
end

function Plugin:reattach()
  if self.bar then
    self.bar:attachPlugin(self, self.db.area, self.db.pos)
  end
end

function Plugin:detach()
  if self.bar then
    self.bar:detachPlugin(self)
    if self.frame then
      self.frame:SetFrameStrata("HIGH")
    end
  end
end

Bazooka.Plugin = Plugin

-- END Plugin stuff

-- BEGIN AceAddon stuff

function Bazooka:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("BazookaDB", defaults, true)
  EnableOpacityWorkaround = self.db.global.enableOpacityWorkaround
  self:initAnchors()
  if LibDualSpec then
    LibDualSpec:EnhanceDatabase(self.db, AppName)
  end
  self:setupLDB()
  self.db.RegisterCallback(self, "OnProfileChanged", "profileChanged")
  self.db.RegisterCallback(self, "OnProfileCopied", "profileChanged")
  self.db.RegisterCallback(self, "OnProfileReset", "profileChanged")
  self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDisable")
  self:profileChanged()
  self:loadOptions()
  if IsMainline then
    hooksecurefunc("OrderHall_CheckCommandBar",
      function()
        if self.db.global.hideOrderHallCommandBar then
          if OrderHallCommandBar then
            OrderHallCommandBar:Hide()
          end
        end
      end
    )
  end
end

function Bazooka:OnEnable(first)
  self.enabled = true
  self:init()
  self:RegisterEvent("PLAYER_REGEN_DISABLED", "onEnteringCombat")
  self:RegisterEvent("PLAYER_REGEN_ENABLED", "onLeavingCombat")
  if IsMainline then
    self:RegisterEvent("PET_BATTLE_OPENING_START", "onPetBattleStart")
    self:RegisterEvent("PET_BATTLE_CLOSE", "onPetBattleEnd")
  end
  self:RegisterEvent("MODIFIER_STATE_CHANGED")
  LDB.RegisterCallback(self, "LibDataBroker_DataObjectCreated", "dataObjectCreated")
end

function Bazooka:OnDisable()
  self.enabled = false
  self:UnregisterAllEvents()
  LDB.UnregisterAllCallbacks(self)
  for i = 1, #self.bars do
    self.bars[i].frame:Hide()
  end
  for name, plugin in pairs(self.plugins) do
    plugin:disable()
  end
end

-- END AceAddon stuff

-- BEGIN handlers

function Bazooka:onEnteringCombat()
  self:lock()
  for i = 1, #self.bars do
    local bar = self.bars[i]
    if not bar.db.hidden then
      bar:toggleMouse(not bar.db.disableMouseInCombat)
      if bar.db.fadeInCombat and not bar.isMouseInside then
        bar:fadeOut(0)
      else
        bar:fadeIn()
      end
      for name, plugin in pairs(bar.allPlugins) do
        plugin:toggleMouse(not plugin.db.disableMouseInCombat)
      end
    end
  end
end

function Bazooka:onLeavingCombat()
  if not self.db.profile.locked then
    self:unlock()
  end
  for i = 1, #self.bars do
    local bar = self.bars[i]
    if not bar.db.hidden then
      bar:toggleMouse(not bar.db.disableMouseOutOfCombat)
      if bar.db.fadeOutOfCombat and not bar.isMouseInside then
        bar:fadeOut(0)
      else
        bar:fadeIn()
      end
      for name, plugin in pairs(bar.allPlugins) do
        plugin:toggleMouse(not plugin.db.disableMouseOutOfCombat)
      end
    end
  end
end

function Bazooka:onPetBattleStart()
  self:lock()
  for i = 1, #self.bars do
    local bar = self.bars[i]
    if not bar.db.hidden then
      if bar.db.disableDuringPetBattle then
        bar:disableAndHide()
      end
    end
  end
end

function Bazooka:onPetBattleEnd()
  for i = 1, #self.bars do
    local bar = self.bars[i]
    if not bar.db.hidden then
      bar:enableAndShow()
    end
  end
end

function Bazooka:MODIFIER_STATE_CHANGED(event, key, state)
  local tipOwner = Bazooka.tipOwner
  if tipOwner and (tipOwner.db.manualTooltip or Bazooka.db.profile.simpleTip) then
    tipOwner:showTip(key, state)
  end
end

function Bazooka:dataObjectCreated(event, name, dataobj)
  self:createPlugin(name, dataobj)
  self:updatePluginOptions()
end

function Bazooka:profileChanged()
  if not self.enabled then
    return
  end
  self:init()
end

-- END handlers

function Bazooka:initAnchors()
  self.topTop, self.topBottom = 1, 0
  if not self.TopAnchor then
    self.TopAnchor = CreateFrame("Frame", "Bazooka_TopAnchor", UIParent)
    self.TopAnchor:EnableMouse(false)
  end
  self:setTopAnchorPoints()

  self.bottomTop, self.bottomBottom = 0, -1
  if not self.BottomAnchor then
    self.BottomAnchor = CreateFrame("Frame", "Bazooka_BottomAnchor", UIParent)
    self.BottomAnchor:EnableMouse(false)
  end
  self:setBottomAnchorPoints()
end

function Bazooka:setTopAnchorPoints()
  self.TopAnchor:ClearAllPoints()
  self.TopAnchor:SetPoint("TOP", UIParent, "TOP", 0, self.topTop)
  self.TopAnchor:SetPoint("BOTTOM", UIParent, "TOP", 0, self.topBottom)
  self.TopAnchor:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
  self.TopAnchor:SetPoint("RIGHT", UIParent, "RIGHT", 0, 0)
end

function Bazooka:setBottomAnchorPoints()
  self.BottomAnchor:ClearAllPoints()
  self.BottomAnchor:SetPoint("TOP", UIParent, "BOTTOM", 0, self.bottomTop)
  self.BottomAnchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, self.bottomBottom)
  self.BottomAnchor:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
  self.BottomAnchor:SetPoint("RIGHT", UIParent, "RIGHT", 0, 0)
end

function Bazooka:getBarName(id)
  return L["Bar#%d"]:format(id)
end

function Bazooka:init()
  self.attachedBars.top = {}
  self.attachedBars.bottom = {}
  for i = 1, #self.bars do
    self.bars[i]:disable()
  end
  for name, plugin in pairs(self.plugins) do
    plugin:disable()
  end
  self.numBars = 0
  local numBars = self.db.profile.numBars
  if not numBars or numBars <= 0 then
    numBars = 1
  end
  for i = 1, numBars do
    self:createBar()
  end
  for name, dataobj in LDB:DataObjectIterator() do
    self:createPlugin(name, dataobj)
  end
  self:applySettings()
  self:updateMainOptions()
  self:updateBarOptions()
  self:updatePluginOptions()
  self:updateAnchors()
end

function Bazooka:createBar()
  self.numBars = self.numBars + 1
  if self.numBars > self.db.profile.numBars then
    self.db.profile.numBars = self.numBars
  end
  local id =  self.numBars
  local db = self.db.profile.bars[id]
  local bar = self.bars[id]
  if not db.pos then
    db.tweakTop, db.tweakBottom, db.tweakLeft, db.tweakRight = 0, 0, 0, 0
  end
  if bar then
    bar:enable(id, db)
    bar:applySettings()
  else
    bar = Bar:New(id, db)
    self.bars[bar.id] = bar
  end
  self:attachBar(bar, bar.db.attach, bar.db.pos)
  self:updateAnchors()
  return bar
end

local function insertBar(bars, pos, bar)
  local pb, nb, nbi
  for i = 1, #bars do
    local b = bars[i]
    if pos <= b.db.pos then
      if not nb then
        nb = b
        nbi = i
      end
      if pos < b.db.pos then
        break
      end
      pos = pos + 1
      b.db.pos = pos
    elseif not nb then
      pb = b
    end
  end
  if nbi then
    tinsert(bars, nbi, bar)
  else
    tinsert(bars, bar)
  end
  return pb, nb
end

function Bazooka:attachBarImpl(bar, attach, pos, attachFunc)
  local bars = self.attachedBars[attach]
  if not pos then
    if #bars > 0 then
      pos = bars[#bars].db.pos + 1
    else
      pos = 1
    end
  end
  local prevBar, nextBar = insertBar(bars, pos, bar)
  bar[attachFunc](bar, prevBar)
  if nextBar then
    nextBar[attachFunc](nextBar, bar)
  end
  return pos
end

function Bazooka:attachBar(bar, attach, pos)
  attach = attach or 'none'
  bar.db.attach = attach
  bar.frame:ClearAllPoints()
  if attach == 'top' then
    pos = self:attachBarImpl(bar, attach, pos, "attachTop")
  elseif attach == 'bottom' then
    pos = self:attachBarImpl(bar, attach, pos, "attachBottom")
  else
    pos = 0
    bar.frame:SetWidth(bar.db.frameWidth)
    bar.frame:SetHeight(bar.db.frameHeight)
    bar.frame:SetPoint(bar.db.point, UIParent, bar.db.relPoint, bar.db.x, bar.db.y)
  end
  bar.db.pos = pos
end

function Bazooka:detachBarImpl(bar, attach, attachFunc)
  local bars = self.attachedBars[attach]
  local prevBar
  for i = 1, #bars do
    local cb = bars[i]
    if cb == bar then
      tremove(bars, i)
      cb = bars[i]
      if cb then
        cb[attachFunc](cb, prevBar)
      end
      break
    end
    prevBar = cb
  end
end

function Bazooka:detachBar(bar)
  self:detachBarImpl(bar, 'top', "attachTop")
  self:detachBarImpl(bar, 'bottom', "attachBottom")
end

function Bazooka:removeBar(bar)
  if self.numBars <= 1 then
    return
  end
  self:detachBar(bar)
  for name, plugin in pairs(bar.allPlugins) do
    plugin.db.bar, plugin.db.area, plugin.db.pos = 1, 'left', nil
    Bazooka:disablePlugin(plugin)
  end
  bar:disable()
  self.numBars = self.numBars - 1
  self.db.profile.numBars = self.numBars
  for i = bar.id, self.numBars do
    self.db.profile.bars[i] = self.db.profile.bars[i + 1]
    self.bars[i] = self.bars[i + 1]
    self.bars[i]:setId(i)
  end
  self.db.profile.bars[self.numBars + 1] = nil
  -- hackish way to get back default overrides
  local t = self.db.profile.bars[self.numBars + 1]
  if defaults.profile.bars[self.numBars + 1] then
    for k, v in pairs(defaults.profile.bars[self.numBars + 1]) do
      t[k] = v
    end
  end

  self.bars[self.numBars + 1] = nil
  self:updateAnchors()
end

function Bazooka:disableDBIcon()
  if self.isDBIconDisabled then
    return
  end
  local DBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
  if DBIcon and DBIcon.DisableLibrary then
    DBIcon:DisableLibrary()
    self.isDBIconDisabled = true
  end
end

function Bazooka:enableDBIcon()
  if not self.isDBIconDisabled then
    return
  end
  local DBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
  if DBIcon and DBIcon.EnableLibrary then
    DBIcon:EnableLibrary()
    self.isDBIconDisabled = nil
  end
end

function Bazooka:createPlugin(name, dataobj)
  local pt = dataobj.type or (dataobj.text and "data source" or "launcher")
  local db = self.db.profile.plugins[pt][name]
  local plugin = self.plugins[name]
  if plugin then
    plugin.db = db
    plugin.dataobj = dataobj
    plugin:applySettings()
  else
    plugin = Plugin:New(name, dataobj, db)
    self.plugins[name] = plugin
  end
  if self.db.profile.disableDBIcon then
    self:disableDBIcon()
  end
  self:updatePluginOptions()
  return plugin
end

function Bazooka:disablePlugin(plugin)
  plugin.db.enabled = false
  plugin:applySettings()
end

function Bazooka:attachPlugin(plugin)
  local bar = self.bars[plugin.db.bar]
  if not bar then
    self.bars[1]:attachPlugin(plugin)
  else
    bar:attachPlugin(plugin, plugin.db.area, plugin.db.pos)
  end
end

function Bazooka:applySettings()
  if not self:IsEnabled() then
    self:OnDisable()
    return
  end
  self:toggleLocked(self.db.profile.locked == true)
  for i = 1, #self.bars do
    local bar = self.bars[i]
    if bar.db.hidden then
      bar:disableAndHide(true)
    end
  end
  if self.db.profile.disableDBIcon then
    self:disableDBIcon()
  else
    self:enableDBIcon()
  end
end

function Bazooka:getBarsTopBottom(bars)
  local barsTop, barsBottom, prevBar
  for i = 1, #bars do
    local bar = bars[i]
    bar.parent = prevBar
    local top, bottom = bar:getTopBottom()
    if not barsTop or barsTop < top then
      barsTop = top
    end
    if not barsBottom or barsBottom > bottom then
      barsBottom = bottom
    end
    prevBar = bar
  end
  return barsTop, barsBottom
end

function Bazooka:updateAnchors()
  local topTop, topBottom = self:getBarsTopBottom(self.attachedBars['top'])
  local bottomTop, bottomBottom = self:getBarsTopBottom(self.attachedBars['bottom'])
  if not topTop then
    topTop, topBottom = 1, 0
  end
  if not bottomTop then
    bottomTop, bottomBottom = 0, -1
  end
  if self.topTop ~= topTop or self.topBottom ~= topBottom then
    self.topTop, self.topBottom = topTop, topBottom
    self:setTopAnchorPoints()
  end
  if self.bottomTop ~= bottomTop or self.bottomBottom ~= bottomBottom then
    self.bottomTop, self.bottomBottom = bottomTop, bottomBottom
    self:setBottomAnchorPoints()
  end
end

function Bazooka:lock()
  self.locked = true
  for i = 1, #self.ldbs do
    self.ldbs[i].icon = Icon
  end
  self:closeStaticDialog(BzkDialogDisablePlugin)
end

function Bazooka:unlock()
  self.locked = false
  for i = 1, #self.ldbs do
    self.ldbs[i].icon = UnlockedIcon
  end
end

function Bazooka:toggleLocked(flag)
  if flag == nil then
    flag = not self.db.profile.locked
  end
  if flag ~= self.db.profile.locked then
    self:updateMainOptions()
  end
  self.db.profile.locked = flag
  if flag then
    self:lock()
  else
    self:unlock()
  end
end

local function extraLauncherName(idx)
  return Bazooka.AppName .. "_" .. idx
end

function Bazooka:setupLDB(forceEnableExtraLaunchers)
  self.ldbOnClick = self.ldbOnClick or function(frame, button)
      if IsShiftKeyDown() or button == "MiddleButton" then
        self:toggleLocked()
      elseif button == "LeftButton" then
        self:toggleBars()
      elseif button == "RightButton" then
        self:openConfigDialog()
      end
    end
  self.ldbOnTooltipShow = self.ldbOnTooltipShow or function(tt)
      tt:AddLine(self.AppName)
      tt:AddLine(L["|cffeda55fLeft Click|r to toggle marked bars"])
      tt:AddLine(L["|cffeda55fShift Click|r to lock/unlock frames"])
      tt:AddLine(L["|cffeda55fRight Click|r to open the configuration window"])
    end
  local ldbIcon = self.db.profile.locked and Icon or UnlockedIcon
  if not self.ldbs then
    self.ldbs = {}
    local ldb = {
      type = "launcher",
      icon = ldbIcon,
      OnClick = self.ldbOnClick,
      OnTooltipShow = self.ldbOnTooltipShow,
    }
    LDB:NewDataObject(self.AppName, ldb)
    self.ldbs[1] = ldb
  end
  if self.db.profile.extraLaunchers then
    for i = 2, self.db.profile.numBars do
      if not self.ldbs[i] then
        local ldb = {
          type = "launcher",
          icon = ldbIcon,
          OnClick = self.ldbOnClick,
          OnTooltipShow = self.ldbOnTooltipShow,
          bzkName = extraLauncherName(i),
        }
        local pdb = self.db.profile.plugins["launcher"][ldb.bzkName]
        if not pdb.pos then
          pdb.bar = i
          pdb.pos = 1
        end
        LDB:NewDataObject(ldb.bzkName, ldb)
        self.ldbs[i] = ldb
      elseif forceEnableExtraLaunchers then
        local plugin = self.plugins[self.ldbs[i].bzkName]
        if plugin then
          plugin.db.enabled = true
          plugin:applySettings()
        end
      end
    end
  else
    for i = 2, #self.ldbs do
      local ldb = self.ldbs[i]
      local plugin = self.plugins[ldb.bzkName]
      if plugin then
        self:disablePlugin(plugin)
      end
    end
  end
  self:updatePluginOptions()
end

function Bazooka:getDropPlace(x, y)
  local dstBar, dstArea, dstPos
  local minDist = math.huge
  for i = 1, #self.bars do
    local bar = self.bars[i]
    local area, pos, dist = bar:getDropPlace(x, y)
    if dist < minDist then
      dstBar, dstArea, dstPos, minDist = bar, area, pos, dist
    end
  end
  if minDist < NearSquared or getDistance2Frame(x, y, dstBar.frame) < NearSquared then
    return dstBar, dstArea, dstPos
  end
end

function Bazooka:highlight(bar, area, pos)
  if self.hlBar and self.hlBar ~= bar then
    self.hlBar:highlight(nil)
  end
  self.hlBar = bar
  if bar then
    bar:highlight(area, pos)
  end
end

function Bazooka:getInsetForEdgeSize(edgeSize)
  return math.floor(edgeSize / 4)
end

function Bazooka:toggleBar(hiddenFlag, barId, ...)
  if not barId then
    return
  end
  barId = tonumber(barId) or -1
  local bar = self.bars[barId]
  if bar then
    bar:toggleHidden(hiddenFlag)
  end
  self:toggleBar(hiddenFlag, ...)
end

function Bazooka:toggleBars(hiddenFlag, params)
  if not params then
    for i = 1, #self.bars do
      local bar = self.bars[i]
      if bar.db.marked then
        bar:toggleHidden(hiddenFlag)
      end
    end
  else
    self:toggleBar(hiddenFlag, strsplit(' ', params))
  end
end

function Bazooka:getSubAppName(name)
  return self.AppName .. '.' .. name
end

-- BEGIN LoD Options muckery

function Bazooka:loadOptions()
  self.optionsLoaded, self.optionsLoadError = LoadAddOn(OptionsAppName)
end

function Bazooka:openConfigDialog()
  -- this function will be overwritten by the Options module when loaded
  print(OptionsAppName .. " not loaded: " .. tostring(self.optionsLoadError))
  self.openConfigDialog = function() end
end

-- END LoD Options muckery

-- static dialog setup

function Bazooka:openStaticDialog(dialog, frameArg, textArg1, textArg2)
  local dialogFrame = StaticPopup_Show(dialog, textArg1, textArg2)
  if dialogFrame then
    dialogFrame.data = frameArg
  end
end

function Bazooka:closeStaticDialog(dialog)
  StaticPopup_Hide(dialog)
end

function Bazooka:profileCmd(profileName)
  profileName = strtrim(profileName or "")
  if profileName == "" then
    local curr = self.db:GetCurrentProfile()
    for i, p in ipairs(self.db:GetProfiles()) do
      if (p == curr) then
        print("|cFF33cc33" .. p .. "|r")
      else
        print(p)
      end
    end
  else
    for i, p in ipairs(self.db:GetProfiles()) do
      if (p == profileName) then
        self.db:SetProfile(profileName)
        return
      end
    end
    print("|cFFcc3333? " .. profileName .. "|r")
  end
end


StaticPopupDialogs[BzkDialogDisablePlugin] = {
  text = L["Disable %s plugin?"],
  button1 = _G.YES,
  button2 = _G.NO,
  OnAccept = function(frame)
    if not frame.data then
      return
    end
    Bazooka:disablePlugin(frame.data)
    Bazooka:updatePluginOptions()
  end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

-- Stubs for Bazooka_Options

function Bazooka:updateMainOptions()
end

function Bazooka:updateBarOptions()
end

function Bazooka:updatePluginOptions()
end

-- register slash command

SLASH_BAZOOKA1 = "/bazooka"
SlashCmdList["BAZOOKA"] = function(msg)
  msg = strtrim(msg or "")
  local cmd, params = strsplit(' ', msg, 2)
  if cmd == "locked" then
    Bazooka:toggleLocked()
  elseif cmd == "hidebars" then
    Bazooka:toggleBars(true, params)
  elseif cmd == "showbars" then
    Bazooka:toggleBars(false, params)
  elseif cmd == "togglebars" then
    Bazooka:toggleBars(nil, params)
  elseif cmd == "profile" then
    Bazooka:profileCmd(params)
  else
    Bazooka:openConfigDialog()
  end
end

-- CONFIGMODE

CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}
CONFIGMODE_CALLBACKS[AppName] = function(action)
  if action == "ON" then
     Bazooka:toggleLocked(false)
  elseif action == "OFF" then
     Bazooka:toggleLocked(true)
  end
end

-- Create our TopAnchor and BottomAnchor so that integrators can use them as soon as we are loaded
Bazooka:initAnchors()

--[[ Anchor test
local topFrame = CreateFrame("Frame")
topFrame:SetPoint("TOPLEFT", Bazooka.TopAnchor, "BOTTOMLEFT")
topFrame:SetPoint("TOPRIGHT", Bazooka.TopAnchor, "BOTTOMRIGHT")
topFrame:SetHeight(20)
local tft = topFrame:CreateTexture()
tft:SetAllPoints()
tft:SetTexture(.8, 0.2, 0.2, 0.5)

local bottomFrame = CreateFrame("Frame")
bottomFrame:SetPoint("BOTTOMLEFT", Bazooka.BottomAnchor, "TOPLEFT")
bottomFrame:SetPoint("BOTTOMRIGHT", Bazooka.BottomAnchor, "TOPRIGHT")
bottomFrame:SetHeight(20)
local bft = bottomFrame:CreateTexture()
bft:SetAllPoints()
bft:SetTexture(.8, 0.4, 0.2, 0.5)
--]]

