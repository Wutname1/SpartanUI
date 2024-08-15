
---@class SUI.Style.Settings.Minimap
---@field shape? MapShape
---@field size? table
---@field scaleWithArt? boolean
---@field UnderVehicleUI? boolean
---@field position? string
---@field rotate? boolean
---@field elements? table

---@class SUI.Style.Settings.Minimap.elements
---@field background? SUI.Settings.Minimap.background
---@field ZoneText? SUI.Settings.Minimap.ZoneText
---@field coords? SUI.Settings.Minimap.coords
---@field border? SUI.Settings.Minimap.border
---@field zoomButtons? SUI.Settings.Minimap.zoomButtons
---@field clock? SUI.Settings.Minimap.clock
---@field tracking? SUI.Settings.Minimap.tracking
---@field calendarButton? SUI.Settings.Minimap.calendarButton
---@field mailIcon? SUI.Settings.Minimap.mailIcon
---@field instanceDifficulty? SUI.Settings.Minimap.instanceDifficulty
---@field queueStatus? SUI.Settings.Minimap.queueStatus
---@field northIndicator? SUI.Settings.Minimap.northIndicator
---@field addonButtons? SUI.Settings.Minimap.addonButtons

---@alias MapShape 'circle' | 'square'

---@class SUI.Settings.Minimap.coords
---@field enabled? boolean
---@field scale? number
---@field size? table
---@field position? string
---@field color? table
---@field format? string

---@class SUI.Settings.Minimap.background
---@field enabled? boolean
---@field texture? string
---@field size? table
---@field position? string
---@field color? table
---@field BlendMode? string
---@field alpha? number

---@class SUI.Settings.Minimap.ZoneText
---@field enabled? boolean
---@field scale? number
---@field position? string
---@field color? table

---@class SUI.Settings.Minimap.border
---@field enabled? boolean
---@field texture? string
---@field size? table
---@field position? string
---@field color? table
---@field BlendMode? string

---@class SUI.Settings.Minimap.zoomButtons
---@field enabled? boolean
---@field scale? number

---@class SUI.Settings.Minimap.clock
---@field enabled? boolean
---@field position? string
---@field scale? number
---@field format? string
---@field color? table

---@class SUI.Settings.Minimap.tracking
---@field enabled? boolean
---@field position? string
---@field scale? number

---@class SUI.Settings.Minimap.calendarButton
---@field enabled? boolean
---@field position? string
---@field scale? number

---@class SUI.Settings.Minimap.mailIcon
---@field enabled? boolean
---@field position? string
---@field scale? number

---@class SUI.Settings.Minimap.instanceDifficulty
---@field enabled? boolean
---@field position? string
---@field scale? number

---@class SUI.Settings.Minimap.queueStatus
---@field enabled? boolean
---@field position? string
---@field scale? number

---@class SUI.Settings.Minimap.northIndicator
---@field enabled? boolean
---@field texture? string
---@field size? table
---@field position? string

---@class SUI.Settings.Minimap.addonButtons
---@field style? string
