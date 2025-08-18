-- ----------------------------------------------------------------------------
-- AddOn Namespace
-- ----------------------------------------------------------------------------
local AddOnFolderName = ... ---@type string
local private = select(2, ...) ---@class PrivateNamespace

---@class LibTextDump.Interface
local debugger

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------
local DEBUGGER_WIDTH = 750
local DEBUGGER_HEIGHT = 800

-- ----------------------------------------------------------------------------
-- Methods
-- ----------------------------------------------------------------------------
function private.Debug(...)
    if not debugger then
        debugger = private.GetDebugger()
    end

    local message = string.format(...)
    debugger:AddLine(message, "%X")

    return message
end

function private.GetDebugger()
    if not debugger then
        debugger =
            LibStub("LibTextDump-1.0"):New(("%s Debug Output"):format(AddOnFolderName), DEBUGGER_WIDTH, DEBUGGER_HEIGHT)
    end

    return debugger
end
