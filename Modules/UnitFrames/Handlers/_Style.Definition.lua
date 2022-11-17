---@class UFStyleSettings
---@field displayName string
---@field setup UFStyleSetupSettings
---@field positions? SUI.UnitFrame.FramePositions
---@field artwork? SUIUFArtworkSettings
local UFStyleSettings = {}

---@class UFStyleSetupSettings
---@field image string
---@field imageCoords? table
local UFStyleSetupSettings = {}

---@class SUIUFArtworkSettings
---@field top? oUFSpartanArtSettings
---@field bg? oUFSpartanArtSettings
---@field bottom? oUFSpartanArtSettings
---@field full? oUFSpartanArtSettings
local SUIUFArtworkSettings = {}

---@class oUFSpartanArtSettings
---@field path function|string
---@field TexCoord function|table
---@field heightScale? integer
---@field yScale? integer
---@field PVPAlpha? integer
---@field height? integer
---@field y? integer
---@field alpha? integer
---@field VertexColor? table
---@field position? oUFSpartanArtPositionTable
---@field scale? integer
local artSettings = {}

---@class oUFSpartanArtPositionTable
---@field anchor AnchorPoint
---@field x integer
---@field y integer
local oUFSpartanArtPositionTable = {}
