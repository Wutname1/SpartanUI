---@meta
-- Type definitions for Libs-AddonTools ProfileManager
-- This file is not packaged - used for IDE support only

---@class LibsAddonTools
---@field ProfileManager LibsAddonTools.ProfileManager
LibsAddonTools = {}

---@class LibsAddonTools.ProfileManager
---@field RegisterAddon fun(self: LibsAddonTools.ProfileManager, addonName: string, aceDB: AceDB): LibsAddonTools.RegisteredAddon
---@field IsProfileManagerAvailable fun(self: LibsAddonTools.ProfileManager): boolean
---@field ShowWindow fun(self: LibsAddonTools.ProfileManager)
---@field HideWindow fun(self: LibsAddonTools.ProfileManager)
---@field ExportProfile fun(self: LibsAddonTools.ProfileManager, format?: string): string|nil
---@field ImportProfile fun(self: LibsAddonTools.ProfileManager, data: string): boolean
LibsAddonTools.ProfileManager = {}

---@class LibsAddonTools.RegisteredAddon
---@field addonName string
---@field aceDB AceDB
---@field ExportProfile fun(self: LibsAddonTools.RegisteredAddon, format?: string): string|nil
---@field ImportProfile fun(self: LibsAddonTools.RegisteredAddon, data: string): boolean
---@field GetProfiles fun(self: LibsAddonTools.RegisteredAddon): string[]
---@field CreateProfile fun(self: LibsAddonTools.RegisteredAddon, name: string): boolean
---@field DeleteProfile fun(self: LibsAddonTools.RegisteredAddon, name: string): boolean
---@field SwitchProfile fun(self: LibsAddonTools.RegisteredAddon, name: string): boolean

---@class AceDB
---@field profiles table<string, any>
---@field profile any
---@field global any
---@field SetProfile fun(self: AceDB, name: string)
---@field GetProfiles fun(self: AceDB): string[]
---@field NewProfile fun(self: AceDB, name: string, copyFrom?: string): boolean
---@field DeleteProfile fun(self: AceDB, name: string): boolean
---@field GetCurrentProfile fun(self: AceDB): string