---@class SUI.Style.Settings.UnitFrames
---@field displayName? string
---@field setup? UFStyleSetupSettings
---@field positions? SUI.UF.FramePositions
---@field artwork? SUI.Style.Settings.UnitFrames.Art.Positions
local UFStyleSettings = {}

---@class UFStyleSetupSettings
---@field image string
---@field imageCoords? table
local UFStyleSetupSettings = {}

---@class SUI.Style.Settings.UnitFrames.Art.Positions
---@field top? SUI.Style.Settings.UnitFrames.Art.Settings
---@field bg? SUI.Style.Settings.UnitFrames.Art.Settings
---@field bottom? SUI.Style.Settings.UnitFrames.Art.Settings
---@field full? SUI.Style.Settings.UnitFrames.Art.Settings
local SUIUFArtworkSettings = {}

---@class SUI.Style.Settings.UnitFrames.Art.Settings
---@field perUnit? boolean
---@field UnitFrameCallback? function
---@field path? function|string
---@field TexCoord? function|table
---@field heightScale? integer
---@field yScale? integer
---@field PVPAlpha? integer
---@field height? integer
---@field y? integer
---@field alpha? integer
---@field VertexColor? table
---@field position? SUI.Style.Settings.UnitFrames.Art.PositionTable
---@field scale? integer
local artSettings = {}

---@class SUI.Style.Settings.UnitFrames.Art.PositionTable
---@field anchor FramePoint
---@field x integer
---@field y integer
local oUFSpartanArtPositionTable = {}
