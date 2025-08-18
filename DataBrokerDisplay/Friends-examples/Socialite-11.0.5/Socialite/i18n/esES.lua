local
  ---@class string
  addonName,
  ---@class ns
  addon = ...

local locale = GetLocale()

if locale == "esES" then
  local L = {}

  -- @todo port localizations

  addon.L = L
end
