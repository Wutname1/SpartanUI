local OptionsAppName = ...
local Bazooka = Bazooka
local Bar = Bazooka.Bar
local Plugin = Bazooka.Plugin
local Defaults = Bazooka.Defaults

local ACR = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(OptionsAppName)
local LibDualSpec = LibStub:GetLibrary("LibDualSpec-1.0", true)

local MinFontSize = 5
local MaxFontSize = 30
local MinIconSize = 5
local MaxIconSize = 40

local BulkEnabledPrefix = "bulk_"
local BulkSeparatorPrefix = "bulks_"
local BulkNamePrefix = "bulkn_"
local BEPLEN = strlen(BulkEnabledPrefix)
local BNPLEN = strlen(BulkNamePrefix)
local Huge = math.huge
local Settings = Settings

local _

local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local tonumber = tonumber
local strsub = strsub
local type = type
local ceil = math.ceil
local tostring = tostring
local tinsert = table.insert
local tsort = table.sort

local Gradients = {
  [""] = L["None"],
  ["HORIZONTAL"] = L["Horizontal"],
  ["VERTICAL"] = L["Vertical"],
}

local Gradients = {
  [""] = L["None"],
  ["HORIZONTAL"] = L["Horizontal"],
  ["VERTICAL"] = L["Vertical"],
}

local FontOutlines = {
  [""] = L["None"],
  ["OUTLINE"] = L["Normal"],
  ["THICKOUTLINE"] = L["Thick"],
}

local FrameStratas = {
  ["HIGH"] = L["High"],
  ["MEDIUM"] = L["Medium"],
  ["LOW"] = L["Low"],
  ["BACKGROUND"] = L["Background"],
}

local TextureTypes = {
  ["background"] = L["Background"],
  ["statusbar"] = L["Statusbar"],
}

local Alignments = {
  ["LEFT"] = L["Left"],
  ["RIGHT"] = L["Right"],
}

local BarNames = {
  [1] = Bazooka:getBarName(1),
}

local function bulkName(origName)
  return BulkNamePrefix .. tostring(origName)
end

local function origName(bulkName)
  return strsub(bulkName, BNPLEN + 1)
end

local function getColor(dbcolor)
  return dbcolor.r, dbcolor.g, dbcolor.b, dbcolor.a
end

local function setColor(dbcolor, r, g, b, a)
  dbcolor.r, dbcolor.g, dbcolor.b, dbcolor.a = r, g, b, a
end

function Bazooka:openConfigDialog(opts, optsAppName, ...)
  if optsAppName then
    ACD:SelectGroup(optsAppName, ...)
  end
  if Settings then
    -- FIXME: fix this when Settings can select sub-categories
    if opts and opts:IsVisible() then
      return
    end
    Settings.OpenToCategory(self.AppName)
  else
    InterfaceOptionsFrame_OpenToCategory(opts or self.opts)
  end
end

function Bazooka:getOption(info)
  return self.db.profile[info[#info]]
end

function Bazooka:setOption(info, value)
  self.db.profile[info[#info]] = value
  self:applySettings()
end

-- BEGIN Bar stuff

local function createNewBar()
  local bar = Bazooka:createBar()
  Bazooka:updateBarOptions()
  Bazooka:setupLDB()
  Bazooka:openConfigDialog(Bazooka.barOpts, Bazooka:getSubAppName("bars"), bar:getOptionsName())
end

local function isTweakValid(info, value)
  return tonumber(value) ~= nil
end

local barOptionArgs = {
  attach = {
    type = 'select',
    name = L["Attach point"],
    values = Bazooka.AttachNames,
    order = 1,
  },
  strata = {
    type = 'select',
    name = L["Strata"],
    desc = L["Frame strata"],
    values = FrameStratas,
    order = 5,
  },
  hidden = {
    type = 'toggle',
    name = L["Hidden"],
    order = 6,
  },
  marked = {
    type = 'toggle',
    name = L["Marked"],
    desc = L["Marked bars can be toggled simultaneously by clicking the Bazooka icon or by the '/bazooka togglebars' slash command"],
    order = 7,
  },
  fadeInCombat =  {
    type = 'toggle',
    name = L["Fade in combat"],
    order = 10,
  },
  fadeOutOfCombat =  {
    type = 'toggle',
    name = L["Fade out of combat"],
    order = 20,
  },
  disableMouseInCombat = {
    type = 'toggle',
    name = L["Disable mouse in combat"],
    order = 30,
  },
  disableMouseOutOfCombat = {
    type = 'toggle',
    name = L["Disable mouse out of combat"],
    order = 40,
  },
  disableDuringPetBattle = {
    type = 'toggle',
    name = L["Disable during pet battle"],
    order = 45,
  },
  fadeAlpha = {
    type = 'range',
    name = L["Fade opacity"],
    min = 0,
    max = 1.0,
    isPercent = true,
    step = 0.01,
    width = 'full',
    order = 50,
  },
  frameWidth = {
    type = 'range',
    name = L["Width"],
    disabled = "isFrameWidthDisabled",
    min = Defaults.minFrameWidth,
    softMax = Defaults.maxFrameWidth,
    max = Huge,
    step = 1,
    order = 55,
  },
  frameHeight = {
    type = 'range',
    name = L["Height"],
    min = Defaults.minFrameHeight,
    softMax = Defaults.maxFrameHeight,
    max = Huge,
    step = 1,
    order = 56,
  },
  fitToContentWidth = {
    type = 'toggle',
    name = L["Fit to content width"],
    disabled = "isFrameWidthDisabled",
    order = 57,
    width = 'full',
  },

  leftMargin = {
    type = 'range',
    name = L["Left margin"],
    min = 0,
    softMax = 50,
    max = Huge,
    step = 1,
    order = 60,
  },
  rightMargin = {
    type = 'range',
    name = L["Right margin"],
    min = 0,
    softMax = 50,
    max = Huge,
    step = 1,
    order = 61,
  },
  leftSpacing = {
    type = 'range',
    name = L["Left spacing"],
    min = 0,
    softMax = 50,
    max = Huge,
    step = 1,
    order = 62,
  },
  rightSpacing = {
    type = 'range',
    name = L["Right spacing"],
    min = 0,
    softMax = 50,
    max = Huge,
    step = 1,
    order = 63,
  },
  centerSpacing = {
    type = 'range',
    name = L["Center spacing"],
    min = 0,
    softMax = 50,
    max = Huge,
    step = 1,
    order = 70,
  },
  iconTextSpacing = {
    type = 'range',
    name = L["Icon-text spacing"],
    min = 0,
    softMax = 20,
    max = Huge,
    step = 1,
    order = 80,
  },

  pluginStyleHeader = {
    type = 'header',
    name = L["Plugin display settings"],
    order = 89,
  },
  font = {
    type = "select", dialogControl = 'LSM30_Font',
    name = L["Font"],
    values = AceGUIWidgetLSMlists.font,
    order = 90,
  },
  fontSize = {
    type = 'range',
    name = L["Font size"],
    min = MinFontSize,
    softMax = MaxFontSize,
    max = Huge,
    step = 1,
    order = 100,
  },
  fontOutline = {
    type = 'select',
    name = L["Font outline"],
    values = FontOutlines,
    order = 110,
  },
  iconSize = {
    type = 'range',
    name = L["Icon size"],
    min = MinIconSize,
    softMax = MaxIconSize,
    max = Huge,
    step = 1,
    order = 120,
  },
  pluginOpacity = {
    type = 'range',
    name = L["Opacity"],
    order = 123,
    min = 0,
    max = 1.0,
    isPercent = true,
    step = 0.01,
  },
  fontShadow = {
    type = 'toggle',
    name = L['Font shadow'],
    order = 126,
  },

  labelColor = {
    type = 'color',
    name = L["Label color"],
    order = 130,
    get = "getColorOption",
    set = "setColorOption",
  },
  textColor = {
    type = 'color',
    name = L["Text color"],
    order = 140,
    get = "getColorOption",
    set = "setColorOption",
  },
  suffixColor = {
    type = 'color',
    name = L["Suffix color"],
    order = 150,
    get = "getColorOption",
    set = "setColorOption",
  },

  bgHeader = {
    type = 'header',
    name = L["Background settings"],
    order = 199,
  },
  bg = {
    type = 'group',
    name = "",
    disabled = "isBGDisabled",
    inline = true,
    order = 200,
    args = {
      bgEnabled = {
        type = 'toggle',
        order = 1,
        name = L["Enable background"],
        disabled = false,
      },
      sep_Enabled = {
        type = 'description',
        name = "",
        width = 'full',
        order = 2,
      },
      bgTextureType = {
        type = "select",
        order = 11,
        name = L["Texture type"],
        values = TextureTypes,
      },
      bgTexture_background = {
        type = "select", dialogControl = 'LSM30_Background',
        order = 12,
        name = L["Background texture"],
        values = AceGUIWidgetLSMlists.background,
        hidden = "isBGTextureBackgroundHidden",
      },
      bgTexture_statusbar = {
        type = "select", dialogControl = 'LSM30_Statusbar',
        order = 13,
        name = L["Background texture"],
        values = AceGUIWidgetLSMlists.statusbar,
        hidden = "isBGTextureStatusbarHidden",
      },
      bgTile = {
        type = "toggle",
        order = 14,
        name = L["Tile background"],
      },
      bgTileSize = {
        type = "range",
        order = 15,
        name = L["Background tile size"],
        desc = L["The size used to tile the background texture"],
        min = 16, max = 256, step = 1,
        disabled = "isTileSizeDisabled",
      },
      bgBorderTexture = {
        type = "select", dialogControl = 'LSM30_Border',
        order = 16,
        name = L["Border texture"],
        values = AceGUIWidgetLSMlists.border,
      },
      bgEdgeSize = {
        type = "range",
        order = 17,
        name = L["Border thickness"],
        min = 1, max = 64, step = 1,
      },
      bgInset = {
        type = "range",
        order = 18,
        name = L["Border inset"],
        min = 0, max = 32, step = 1,
      },
      bgColor = {
        type = "color",
        order = 19,
        name = L["Background color"],
        hasAlpha = true,
        get = "getColorOption",
        set = "setColorOption",
      },
      bgBorderColor = {
        type = "color",
        order = 20,
        name = L["Border color"],
        hasAlpha = true,
        get = "getColorOption",
        set = "setColorOption",
      },
      bgGradient = {
        type = "select",
        order = 30,
        name = L["Gradient"],
        values = Gradients,
      },
      bgGradientColor = {
        type = "color",
        order = 31,
        name = L["Gradient color"],
        hasAlpha = true,
        get = "getColorOption",
        set = "setColorOption",
      },
    },
  },
  tweaksHeader = {
    type = 'header',
    name = L["Tweak anchor positions"],
    order = 209,
  },
  tweakLeft = {
    type = 'input',
    name = L["Left"],
    validate = isTweakValid,
    disabled = "isTweakDisabled",
    order = 210,
  },
  tweakRight = {
    type = 'input',
    name = L["Right"],
    validate = isTweakValid,
    disabled = "isTweakDisabled",
    order = 211,
  },
  tweakTop = {
    type = 'input',
    name = L["Top"],
    validate = isTweakValid,
    disabled = "isTweakDisabled",
    order = 212,
  },
  tweakBottom = {
    type = 'input',
    name = L["Bottom"],
    validate = isTweakValid,
    disabled = "isTweakDisabled",
    order = 213,
  },
  removeBar = {
    type = 'execute',
    name = L["Remove bar"],
    confirm = function(info)
      return L["Remove %s?"]:format(info.handler.name)
    end,
    width = 'full',
    func = function(info)
      Bazooka:removeBar(info.handler)
      Bazooka:updateBarOptions()
      Bazooka:updatePluginOptions()
    end,
    disabled = function()
      return Bazooka.numBars <= 1
    end,
    order = 300,
  },
}

local barOptions = {
  type = 'group',
  childGroups = 'tab',
  inline = true,
  name = L["Bars"],
  get = "getOption",
  set = "setOption",
  order = 10,
  args = {
  },
}

local barSelectionArgs = {}

function Bar:isTweakDisabled(info)
  if self.db.attach == 'none' then
    return true
  elseif self.db.attach == 'top' then
    return info[#info] == 'tweakBottom'
  elseif self.db.attach == 'bottom' then
    return info[#info] == 'tweakTop'
  end
end

function Bar:isBGDisabled()
  return not self.db.bgEnabled
end

function Bar:isFrameWidthDisabled()
  return self.db.attach ~= 'none'
end

function Bar:isTileSizeDisabled()
  return not (self.db.bgEnabled and self.db.bgTile)
end

function Bar:isBGTextureStatusbarHidden()
  return self.db.bgTextureType ~= 'statusbar'
end

function Bar:isBGTextureBackgroundHidden()
  return self.db.bgTextureType ~= 'background'
end

local UpdateLayoutOptions = {
  leftMargin = true,
  rightMargin = true,
  leftSpacing = true,
  rightSpacing = true,
  centerSpacing = true,
  fitToContentWidth = true,
}

local AttachOptions = {
  attach = true,
  tweakLeft = true,
  tweakRight = true,
  tweakTop = true,
  tweakBottom = true,
}

local UpdateAnchorsOptions = {
  frameHeight = true,
}

function Bar:setOption(info, value)
  local name = info[#info]
  if name:find("tweak") == 1 then
    value = tonumber(value) or 0
  elseif name:find("bgTexture_") == 1 then
    name = "bgTexture"
  end
  if self.db[name] == value then
    return
  end
  local origAttach = self.db.attach
  if name == 'bgEdgeSize' then
    if self.db.bgInset and self.db.bgInset == Bazooka:getInsetForEdgeSize(self.db.bgEdgeSize) then
      self.db.bgInset = Bazooka:getInsetForEdgeSize(value)
    end
  end
  self.db[name] = value
  if AttachOptions[name] then
    if origAttach ~= self.db.attach then
      self.db.pos = nil
    end
    Bazooka:detachBar(self)
    Bazooka:attachBar(self, self.db.attach, self.db.pos)
    Bazooka:updateAnchors()
  elseif UpdateLayoutOptions[name] then
    self:updateLayout()
  else
    self:applySettings()
  end
  if UpdateAnchorsOptions[name] then
    Bazooka:updateAnchors()
  end
end

function Bar:getOption(info)
  local name = info[#info]
  if name:find("tweak") == 1 then
    return tostring(self.db[name] or 0)
  elseif name:find("bgTexture_") == 1 then
    name = "bgTexture"
  end
  return self.db[name]
end

function Bar:setColorOption(info, r, g, b, a)
  setColor(self.db[info[#info]], r, g, b, a)
  self:applySettings()
end

function Bar:getColorOption(info)
  return getColor(self.db[info[#info]])
end

function Bar:addOptions()
  if not self.opts then
    self.opts = {
      type = 'group',
      inline = false,
      handler = self,
      args = barOptionArgs,
    }
  end
  self.opts.order = self.id
  self.opts.name = self.name
end

local CreateNewBarFakeOptions = {
  type = 'group',
  inline = false,
  name = '+',
  order = -1,
  args = {
    createBar = {
      type = 'execute',
      name = L["Create new bar"],
      width = 'full',
      func = createNewBar,
      disabled = createNewBar,
    },
  },
}

function Bazooka:updateBarOptions()
  wipe(barOptions.args)
  wipe(barSelectionArgs)
  for i = 1, self.numBars do
    local bar = self.bars[i]
    bar:addOptions()
    barOptions.args[bar:getOptionsName()] = bar.opts
    BarNames[i] = bar.name
    barSelectionArgs[bulkName(i)] = {
      type = 'toggle',
      name = BarNames[i],
      order = i,
    }
  end
  barOptions.args['+'] = CreateNewBarFakeOptions
  ACR:NotifyChange(self:getSubAppName("bars"))
  ACR:NotifyChange(self:getSubAppName("bulk-config"))
end

-- END Bar stuff

-- BEGIN Plugin stuff

local pluginOptions = {
  type = 'group',
  -- childGroups = 'tree',
  childGroups = 'select',
  inline = true,
  name = L["Plugins"],
  get = "getOption",
  set = "setOption",
  order = 10,
  args = {
  },
}

local pluginOptionArgs = {
  enabled = {
    type = 'toggle',
--        width = 'full',
    name = L["Enabled"],
    order = 10,
  },
  useLabelAsTitle = {
    type = 'toggle',
    name = L["Use label as title"],
    order = 15,
  },
  alignment = {
    type = 'select',
    name = L["Alignment"],
    values = Alignments,
    order = 110,
  },
  showIcon = {
    type = 'toggle',
    name = L["Show icon"],
    disabled = "isDisabled",
    order = 120,
  },
  showLabel = {
    type = 'toggle',
    name = L["Show label"],
    disabled = "isDisabled",
    order = 130,
  },
  showTitle = {
    type = 'toggle',
    name = L["Show title"],
    order = 140,
    disabled = "isTitleDisabled",
  },
  showText = {
    type = 'toggle',
    name = L["Show text"],
    disabled = "isDisabled",
    order = 150,
  },
  showValue = {
    type = 'toggle',
    name = L["Show value"],
    desc = function(info)
      if info.handler.dataobj and info.handler.dataobj.value then
        return tostring(info.handler.dataobj.value)
      end
    end,
    disabled = "isDisabled",
    order = 151,
  },
  showSuffix = {
    type = 'toggle',
    name = L["Show suffix"],
    disabled = function(info)
      return not info.handler.db.enabled or not info.handler.db.showValue
    end,
    order = 152,
  },
  stripColors = {
    type = 'toggle',
    name = L["Strip colors"],
    disabled = "isDisabled",
    order = 153,
  },
  iconBorderClip = {
    type = 'range',
    name = L["Icon Border Clip"],
    min = 0.0,
    max = 0.1,
    step = 0.005,
    isPercent = true,
    order = 155,
  },
  maxTextWidth = {
    type = 'input',
    name = L["Max text width"],
    desc = function(info)
      if info.handler.text then
        return tostring(ceil(info.handler.text:GetStringWidth()))
      end
    end,
    disabled = "isDisabled",
    order = 160,
  },
  hideTipOnClick = {
    type = 'toggle',
    name = L["Hide tooltip on click"],
    disabled = "isDisabled",
    order = 190,
  },
  manualTooltip = {
    type = 'toggle',
    name = L["Manual tooltip"],
    desc = L["Show tooltip by pressing a modifier key"],
    disabled = "isDisabled",
    order = 195,
  },
  disableTooltip = {
    type = 'toggle',
    name = L["Disable tooltip"],
    disabled = "isDisabled",
    order = 200,
  },
  disableTooltipInCombat = {
    type = 'toggle',
    name = L["Disable tooltip in combat"],
    disabled = "isDisabled",
    order = 210,
  },
  disableMouseInCombat = {
    type = 'toggle',
    name = L["Disable mouse in combat"],
    disabled = "isDisabled",
    order = 220,
  },
  disableMouseOutOfCombat = {
    type = 'toggle',
    name = L["Disable mouse out of combat"],
    disabled = "isDisabled",
    order = 230,
  },
  forceHideTip = {
    type = 'toggle',
    name = L["Force Hide Tooltip"],
    desc = L["Force hiding the tooltip. It's a hack and might cause unwanted side-effects. Only enable if the plugin's tooltip doesn't behave as expected."],
    disabled = "isDisabled",
    order = 240,
  },
  overrideTooltipScale = {
    type = 'toggle',
    name = L["Override Tooltip Scale"],
    disabled = "isDisabled",
    order = 250,
  },
  tooltipScale = {
    type = 'range',
    name = L["Tooltip Scale"],
    disabled = function(info)
      return not info.handler.db.enabled or not info.handler.db.overrideTooltipScale
    end,
    min = 0.5,
    max = 2.0,
    step = 0.05,
    order = 251,
  },
  shrinkThreshold = {
    type = 'range',
    name = L["Shrink threshold"],
    disabled = "isDisabled",
    min = 0,
    softMax = 100,
    max = Huge,
    step = 1,
    order = 300,
  },
  bar = {
    type = 'select',
    name = L["Bar"],
    disabled = "isDisabled",
    values = BarNames,
    order = 310,
  },
  area = {
    type = 'select',
    name = L["Area"],
    disabled = "isDisabled",
    values = Bazooka.AreaNames,
    order = 320,
  },
}

local pluginSelectionArgs = {}

function Plugin:getColoredTitle()
  return ("|T%s:0|t %s%s"):format(
    self.dataobj.staticIcon or (self.dataobj.icon and not self.dataobj.iconCoords) and self.dataobj.icon or "",
    self.db.enabled and "" or "|cffed1100",
    self:getTitle()
  )
end

function Plugin:updateColoredTitle()
  local ct = self:getColoredTitle()
  self.opts.name = ct
  local selection = pluginSelectionArgs[bulkName(self.name)]
  if selection then
    selection.name = ct
  end
end

function Plugin:setOption(info, value)
  local name = info[#info]
  if name == 'maxTextWidth' then
    value = tonumber(value)
    if value and value <= 0 then
      value = nil
    end
  end
  self.db[name] = value
  self:applySettings()
  if name == 'enabled' or name == 'useLabelAsTitle' then
    self:updateColoredTitle()
    Bazooka:updatePluginOrder()
  end
end

function Plugin:getOption(info)
  local name = info[#info]
  local value = self.db[name]
  if name == 'maxTextWidth' and value then
    value = tostring(value)
  end
  return value
end

function Plugin:isDisabled()
  return not self.db.enabled
end

function Plugin:isTitleDisabled()
  return not (self.db.enabled and self.db.showLabel)
end

function Plugin:addOptions()
  if not self.opts then
    self.opts = {
      type = 'group',
      inline = false,
      handler = self,
      args = pluginOptionArgs,
    }
  end
  self:updateColoredTitle()
end

local sortedPlugins = {}

local function comparePluginsByTitle(p1, p2)
  return p1:getTitle() < p2:getTitle()
end

local function comparePluginsByTitleDisabledLast(p1, p2)
  if p1.db.enabled then
    return not p2.db.enabled or p1:getTitle() < p2:getTitle()
  else
    return not p2.db.enabled and p1:getTitle() < p2:getTitle()
  end
end

function Bazooka:sortPlugins()
  if self.db.global.sortDisabledLast then
    tsort(sortedPlugins, comparePluginsByTitleDisabledLast)
  else
    tsort(sortedPlugins, comparePluginsByTitle)
  end
  return sortedPlugins;
end

function Bazooka:updatePluginOrder()
  self:sortPlugins()
  for i = 1, #sortedPlugins do
    local plugin = sortedPlugins[i]
    plugin.opts.order = i
    pluginSelectionArgs[bulkName(plugin.name)].order = i
  end
end

function Bazooka:updatePluginOptions()
  wipe(pluginOptions.args)
  wipe(pluginSelectionArgs)
  wipe(sortedPlugins)
  for name, plugin in pairs(self.plugins) do
    tinsert(sortedPlugins, plugin)
  end
  if self.db.global.sortDisabledLast then
    tsort(sortedPlugins, comparePluginsByTitleDisabledLast)
  else
    tsort(sortedPlugins, comparePluginsByTitle)
  end

  for i = 1, #sortedPlugins do
    local plugin = sortedPlugins[i]
    plugin:addOptions()
    plugin.opts.order = i
    pluginOptions.args[plugin.name] = plugin.opts
    pluginSelectionArgs[bulkName(plugin.name)] = {
      type = 'toggle',
      name = plugin:getColoredTitle(),
      order = i,
    }
  end
  ACR:NotifyChange(self:getSubAppName("plugins"))
  ACR:NotifyChange(self:getSubAppName("bulk-config"))
end

-- END Plugin stuff

-- BEGIN Bulk config stuff

local BulkHandler = {}
BulkHandler.__index = BulkHandler

local function getOptParam(info, param)
  local options = info.options
  local res = options[param]
  for i = 1, #info do
    options = options.args[info[i]]
    res = options[param] or res
  end
  return res
end

function BulkHandler:setOption(info, value)
  self:getOptions()[info[#info]] = value
  if Bazooka.db.global.autoApply then
    self:autoApply(info, value)
  end
end

function BulkHandler:getOption(info)
  return self:getOptions()[info[#info]]
end

function BulkHandler:setColorOption(info, ...)
  setColor(self:getOption(info), ...)
  if Bazooka.db.global.autoApply then
    self:autoApply(info, ...)
  end
end

function BulkHandler:getColorOption(info)
  return getColor(self:getOption(info))
end

function BulkHandler:setMultiOption(info, sel, value)
  self:getOption(info)[sel] = value
  if Bazooka.db.global.autoApply then
    self:autoApply(info, sel, value)
  end
end

function BulkHandler:getMultiOption(info, sel)
  return self:getOption(info)[sel]
end

function BulkHandler:setSelection(info, value)
  local sel = origName(info[#info])
  self.selection[sel] = value
end

function BulkHandler:getSelection(info, sel)
  local sel = origName(info[#info])
  return self.selection[sel]
end

function BulkHandler:getSelectedOption(info)
  if Bazooka.db.global.autoApply then
    return nil
  end
  local name = strsub(info[#info], BEPLEN + 1)
  return self.selectedOptions[name] == true
end

function BulkHandler:setSelectedOption(info, value)
  local name = strsub(info[#info], BEPLEN + 1)
  if Bazooka.db.global.autoApply then
    local origName = info[#info]
    info[#info] = name
    local getter = getOptParam(info, 'get')
    if getter == "getMultiOption" then
      -- TODO
    else
      self:autoApply(info, self[getter](self, info))
    end
    info[#info] = origName
  else
    self.selectedOptions[name] = (value == true)
  end
end

function BulkHandler:isSettingDisabled(info)
  return not (Bazooka.db.global.autoApply or self.selectedOptions[info[#info]])
end

function BulkHandler:applyBulkSettingsTo(target)
  local options = self:getOptions()
  for k, v in pairs(self.selectedOptions) do
    if v then
      if type(options[k]) == 'table' then
        local src = options[k]
        local dst = target.db[k]
        wipe(dst)
        for kk, vv in pairs(src) do
          dst[kk] = vv
        end
      else
        target.db[k] = options[k]
      end
    end
  end
  target:applySettings()
end

function BulkHandler:isApplyDisabled(info)
  if Bazooka.db.global.autoApply then
    return true
  end
  for key, value in pairs(self.selection) do
    if value then
      for key, value in pairs(self.selectedOptions) do
        if value then
          return false
        end
      end
      break
    end
  end
  return true
end

function BulkHandler:clearSettings(info)
  wipe(self.selectedOptions)
end

function BulkHandler:clearSelection(info)
  wipe(self.selection)
end

--------------------------------------

local PluginBulkHandler = setmetatable({
  selection = {},
  selectedOptions = {},
}, BulkHandler)

function PluginBulkHandler:selectAll(info)
  for name, plugin in pairs(Bazooka.plugins) do
    self.selection[name] = true
  end
end

function PluginBulkHandler:getOptions()
  return Bazooka.db.global.plugins
end

function PluginBulkHandler:autoApply(info, ...)
  local setter = getOptParam(info, 'set')
  for name, selected in pairs(self.selection) do
    if selected then
      local plugin = Bazooka.plugins[name]
      if plugin then
        plugin[setter](plugin, info, ...)
      end
    end
  end
end

function PluginBulkHandler:applyBulkSettings(info)
  for name, selected in pairs(self.selection) do
    if selected then
      local plugin = Bazooka.plugins[name]
      if plugin then
        self:applyBulkSettingsTo(plugin)
        if self.selectedOptions['enabled'] then
          plugin:updateColoredTitle()
        end
      end
    end
  end
end

--------------------------------------

local BarBulkHandler = setmetatable({
  selection = {},
  selectedOptions = {},
}, BulkHandler)

function BarBulkHandler:selectAll(info)
  for _, bar in pairs(Bazooka.bars) do
    self.selection[tostring(bar.id)] = true
  end
end

function BarBulkHandler:getOptions()
  return Bazooka.db.global.bars
end

function BarBulkHandler:autoApply(info, ...)
  local setter = getOptParam(info, 'set')
  for id, selected in pairs(self.selection) do
    if selected then
      local bar = Bazooka.bars[tonumber(id)]
      if bar then
        local name = info[#info]
        if name:find("bgTexture_") == 1 then
          -- erm, it's a hack...
          local textureType = name:sub(("bgTexture_"):len() + 1)
          bar.db.bgTextureType = textureType
        end
        bar[setter](bar, info, ...)
      end
    end
  end
end

function BarBulkHandler:applyBulkSettings(info)
  for id, selected in pairs(self.selection) do
    if selected then
      local bar = Bazooka.bars[tonumber(id)]
      if bar then
        local origAttach = bar.db.attach
        self:applyBulkSettingsTo(bar)
        if origAttach ~= bar.db.attach then
          bar.db.pos = nil
        end
        Bazooka:detachBar(bar)
        Bazooka:attachBar(bar, bar.db.attach, bar.db.pos)
        bar:updateLayout()
      end
    end
  end
  Bazooka:updateAnchors()
end

--------------------------------------

local function isAutoApply()
  return Bazooka.db.global.autoApply
end

local bulkConfigOptions = {
  type = 'group',
  handler = BulkHandler,
  childGroups = 'tab',
  inline = true,
  name = L["Bulk Configuration"],
  get = "getOption",
  set = "setOption",
  order = 10,
  args = {
    autoApply = {
      type = 'toggle',
      name = L["Auto apply"],
      order = 5,
      set = function(info, value) Bazooka.db.global.autoApply = value end,
      get = function(info) return Bazooka.db.global.autoApply end,
    },
    bars = {
      type = 'group',
      handler = BarBulkHandler,
      name = L["Bars"],
      order = 10,
      args = {
        selectionBegin = {
          type = 'header',
          name = L["Selection"],
          order = 1,
        },
        selection = {
          type = 'group',
          name = "",
          inline = true,
          order = 2,
          get = "getSelection",
          set = "setSelection",
          args = barSelectionArgs,
        },
        selectAll = {
          type = 'execute',
          name = L["Select All"],
          func = "selectAll",
          order = 4,
        },
        clearSelection = {
          type = 'execute',
          name = L["Clear"],
          func = "clearSelection",
          order = 5,
        },
        settings = {
          type = 'header',
          name = L["Settings"],
          order = 6,
        },
        apply = {
          type = 'execute',
          name = L["Apply"],
          confirm = function() return L["Apply selected options to selected bars?"] end,
          func = "applyBulkSettings",
          disabled = "isApplyDisabled",
          hidden = isAutoApply,
          order = 9998,
        },
        clearSettings = {
          type = 'execute',
          name = L["Clear"],
          func = "clearSettings",
          hidden = isAutoApply,
          order = 9999,
        },
      },
    },
    plugins = {
      type = 'group',
      handler = PluginBulkHandler,
      name = L["Plugins"],
      order = 20,
      args = {
        selectionBegin = {
          type = 'header',
          name = L["Selection"],
          order = 1,
        },
        selection = {
          type = 'group',
          name = "",
          inline = true,
          order = 2,
          get = "getSelection",
          set = "setSelection",
          args = pluginSelectionArgs,
        },
        selectAll = {
          type = 'execute',
          name = L["Select All"],
          func = "selectAll",
          order = 4,
        },
        clearSelection = {
          type = 'execute',
          name = L["Clear"],
          func = "clearSelection",
          order = 5,
        },
        settings = {
          type = 'header',
          name = L["Settings"],
          order = 6,
        },
        apply = {
          type = 'execute',
          name = L["Apply"],
          confirm = function() return L["Apply selected options to selected plugins?"] end,
          func = "applyBulkSettings",
          disabled = "isApplyDisabled",
          hidden = isAutoApply,
          order = 9998,
        },
        clear = {
          type = 'execute',
          name = L["Clear"],
          func = "clearSettings",
          hidden = isAutoApply,
          order = 9999,
        },
      },
    },
  },
}

-- END Bulk config stuff

function Bazooka:updateMainOptions()
  ACR:NotifyChange(self.AppName)
end

do
  local skipTypes = {
    ["execute"] = true,
    ["description"] = true,
  }
  local function createBulkConfigOpts(src, dst)
    for key, value in pairs(src) do
      if not skipTypes[value.type] then
        local copy = {}
        dst[key] = copy
        for k, v in pairs(value) do
          copy[k] = v
        end
        copy.type = value.type
        if value.type == 'color' then
          copy.get = "getColorOption"
          copy.set = "setColorOption"
        elseif value.type == 'multiselect' then
          copy.get = "getMultiOption"
          copy.set = "setMultiOption"
        else
          copy.get = nil
          copy.set = nil
        end
        copy.order = value.order * 10
        copy.disabled = "isSettingDisabled"
        copy.width = nil
        copy.hidden = nil
        if value.type == 'group' then
          copy.args = {}
          createBulkConfigOpts(value.args, copy.args)
          copy.disabled = nil
        elseif value.type ~= 'header' then
          dst[BulkEnabledPrefix .. key] = {
            type = 'toggle',
            tristate = true,
            name = L["Apply"],
            get = "getSelectedOption",
            set = "setSelectedOption",
            arg = copy.set,
            order = value.order * 10 + 1,
          }
          dst[BulkSeparatorPrefix .. key] = {
            type = 'description',
            name = "",
            width = 'full',
            order = value.order * 10 + 2,
          }
        end
      end
    end
  end

  createBulkConfigOpts(barOptionArgs, bulkConfigOptions.args.bars.args)
  createBulkConfigOpts(pluginOptionArgs, bulkConfigOptions.args.plugins.args)

  local self = Bazooka

  local mainOptions = {
    type = 'group',
    childGroups = 'tab',
    inline = true,
    name = Bazooka.AppName,
    handler = Bazooka,
    get = "getOption",
    set = "setOption",
    order = 10,
    args = {
      locked = {
        type = 'toggle',
        name = L["Locked"],
        order = 10,
      },
      simpleTip = {
        type = 'toggle',
        name = L["Enable simple tooltips"],
        order = 20,
      },
      manualTooltipToggle = {
        type = 'toggle',
        name = L["Manual tooltip toggle mode"],
        desc = L["Set if you want to hide the plugin tooltip when releasing the modifier key in manual tooltip mode"],
        order = 25,
      },
      hideOrderHallCommandBar = {
        type = 'toggle',
        name = L["Hide Order Hall Command Bar"],
        order = 33,
        set = function(info, value)
          Bazooka.db.global.hideOrderHallCommandBar = value
        end,
        get = function(info)
          return Bazooka.db.global.hideOrderHallCommandBar
        end,
      },
      enableHL = {
        type = 'toggle',
        name = L["Enable highlight"],
        order = 40,
      },
      disableDBIcon = {
        type = 'toggle',
        name = L["Disable minimap icons"],
        order = 45,
      },
      sortDisabledLast = {
        type = 'toggle',
        name = L["Show disabled plugins last"],
        order = 47,
        set = function(info, value)
          Bazooka.db.global.sortDisabledLast = value
          Bazooka:updatePluginOrder()
        end,
        get = function(info) return Bazooka.db.global.sortDisabledLast end,
      },
      enableOpacityWorkaround = {
        type = 'toggle',
        name = L["Enable opacity workaround"],
        order = 48,
        set = function(info, value)
          Bazooka.db.global.enableOpacityWorkaround = value
        end,
        get = function(info) return Bazooka.db.global.enableOpacityWorkaround end,
      },
      extraLaunchers = {
        type = 'toggle',
        name = L["Extra launchers"],
        desc = L["Create a bazooka launcher for each bar"],
        set = function(info, value)
          Bazooka:setOption(info, value)
          Bazooka:setupLDB(value)
        end,
        order = 49,
      },
      fadeOutDelay = {
        type = 'range',
        width = 'full',
        name = L["Fade-out delay"],
        min = 0,
        softMax = 5,
        max = Huge,
        step = 0.1,
        order = 50,
      },
      fadeOutDuration = {
        type = 'range',
        width = 'full',
        name = L["Fade-out duration"],
        min = 0,
        softMax = 3,
        max = Huge,
        step = 0.05,
        order = 60,
      },
      fadeInDuration = {
        type = 'range',
        width = 'full',
        name = L["Fade-in duration"],
        min = 0,
        softMax = 3,
        max = Huge,
        step = 0.05,
        order = 70,
      },
      createBar = {
        type = 'execute',
        name = L["Create new bar"],
        width = 'full',
        func = createNewBar,
        order = 100,
      },
    },
  }

  local function registerSubOptions(name, opts)
    local appName = self:getSubAppName(name)
    ACR:RegisterOptionsTable(appName, opts)
    return ACD:AddToBlizOptions(appName, opts.name or name, self.AppName)
  end

  -- BEGIN

  ACR:RegisterOptionsTable(self.AppName, mainOptions)
  self.opts = ACD:AddToBlizOptions(self.AppName, self.AppName)
  self.barOpts = registerSubOptions('bars', barOptions)
  self.pluginOpts = registerSubOptions('plugins', pluginOptions)
  self.bulkConfigOpts = registerSubOptions('bulk-config', bulkConfigOptions)
  self:updateBarOptions()
  self:updatePluginOptions()
  local profiles =  AceDBOptions:GetOptionsTable(self.db)
  if LibDualSpec then
    LibDualSpec:EnhanceOptions(profiles, self.db)
  end
  self.profiles = registerSubOptions('profiles', profiles)
end

