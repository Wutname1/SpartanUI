--[===[ File
This file contains the debug class to be used throughout Titan Panel and plugins.

This file is loaded first so NO other Titan routines are to be used.

The intent is a simple, flexible debug framework to enable:
- a consistent output
- enable / disable across an arbitrary scope - across addons; single addon; or partial addon
- enable / disable rather than comment out
--]===]

Titan_Debug = {}

local text_color = "1DA6C5" -- light blue
local head_color = "f2e699" -- yellow gold
local err_color = "ff2020"  -- red

local function Encode(color, text)
    -- Color the string using WoW encoding
    local res = ""
    local c = tostring(color)
    local t = tostring(text)
    if (c and t) then
        res = "|cff" .. c .. t .. "|r"
    else
        if (t) then
            res = tostring(t)
        else
            -- return blank string
        end
    end

    return res
end

local function Out_Error(plugin_id, topic_id, topic_text)
    local msg = ""
        .. Encode(err_color,
            date("%H:%M:%S")
            .. " <" .. tostring(plugin_id)
            .. ":" .. topic_id .. "> ")  -- yellow gold
        .. " " .. Encode(text_color, tostring(topic_text)
        )                                --

    _G["DEFAULT_CHAT_FRAME"]:AddMessage(msg)
end

local function Out_debug(plugin_id, topic_id, topic_text)
    local msg = ""
        .. Encode(head_color,
            date("%H:%M:%S")
            .. " <" .. tostring(plugin_id)
            .. ":" .. topic_id .. "> ")  -- yellow gold
        .. " " .. Encode(text_color, tostring(topic_text)
        )                                --

    _G["DEFAULT_CHAT_FRAME"]:AddMessage(msg)
end

---@class PluginDebugType
---@field plugin_id string Plugin / Addon name
---@field enabled boolean Whether this particular plugin debug is enabled
---@field topics table Index of topics (true / false)
---@field New function
---@field AddTopic function
---@field Out function
---@field EnableDebug function
---@field EnableTopic function

---API Return a disabled debug class with default topics. Each plugin is welcome to add more topics.
---@param id string
---@return PluginDebugType
--- debug_obj = Titan_Debug.New("Titan")
function Titan_Debug:New(id)
    local this = {}          -- new object
    setmetatable(this, self) -- create handle lookup; self == Titan_Debug
    self.__index = self

    -- Init object
    this.plugin_id = id
    this.enabled = false
    this.topics = {
        ["Events"] = false,
        ["Flow"] = false,
        ["Tooltip"] = false,
        ["Menu"] = false,
    }
    return this ---@type PluginDebugType
end

---Add a topic to the created debug class
---@param topic_id string
--- debug_obj.Add("Startup")
function Titan_Debug:AddTopic(topic_id)
    -- A bit harsh but do not override a topic
    if self.topics[topic_id] == nil then
        self.topics[topic_id] = false
    else
        Out_Error(self.plugin_id, self.topics[topic_id], " Attempt to override (" .. topic_id .. ")'")
    end
end

---Output a debug string under a topic id
---@param topic_id number
---@param str string
--- debug_info.Out(1, "OnEvent")
function Titan_Debug:Out(topic_id, str)
    if self.enabled == true then         -- debug enabled for this object
        if self.topics[topic_id] == true -- exists and was enabled
        then
            Out_debug(self.plugin_id, topic_id, str)
        else
            -- silent return
        end
    else
        -- silent return
    end
end

---@param action boolean
--- debug_info.EnableDebug(true)
function Titan_Debug:EnableDebug(action)
    if self.enabled ~= action then
        -- Inform dev of change
        local msg = (action == true and "Enabled" or "Disabled")
        Out_debug(self.plugin_id, "Events", msg)
    else
        -- silent
    end

    self.enabled = action
end

---Enable / disable debug the topic within this id
---@param id number
---@param action boolean
--- debug_info.EnableTopic(1, true)
--- debug_info.EnableTopic(1, false)
function Titan_Debug:EnableTopic(id, action)
    self.topics[id] = action
end

--[[
    local msg = "Debug Enable topic"
    .." "..tostring(self.plugin_id)
    .." "..tostring(id)
    .." > "..tostring(self.topics[id].enabled)
    _G["DEFAULT_CHAT_FRAME"]:AddMessage(msg)
    --]]
