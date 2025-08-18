local LibStub = LibStub
local moduleName = "Played Time"
local L = LibStub("AceLocale-3.0"):GetLocale("CB_PlayedTime")
--local Module = LibStub:GetLibrary("LibDataBroker-1.1",true):GetDataObjectByName(addonName)
local Module = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar"):GetModule(moduleName)
local db
local tobedeleted

local aceoptions = {
  name = moduleName,
  handler = CB_PlayedTime,
	type='group',
	desc = moduleName,
	childGroups = "tab",
  args = {
		general = {
			inline = true,
			name = L["General"],
			type="group",
			order = 1,
			args={
        reset = {
					type = 'execute',
					order = 0,
          name = L["Reset"],
          desc = L["Reset time for all Characters"],
		      func = function()
						Module:Reset()
					end,
				},
			},
		},
    delete = {
      inline = true,
			name = L["Delete a Character"],
      type="group",
			order = 2,
      args={
        },
	   },
  },
}
local deleteOptions = aceoptions.args.delete.args

local function GetName(info)
  local name = info[#info]
  return name
end

local function DeleteName(info)
  local name = info[#info]
  Module:RemoveCharDeleteOption(name)
  Module:Delete(name)
end

function Module:AddCharDeleteOption(name)
  deleteOptions[name] = {
          type = 'execute',
          order = 0,
          name = GetName,
          desc = L["Delete this Character"],
          func = DeleteName,
    }
end

function Module:RemoveCharDeleteOption(name)
  deleteOptions[name] = nil
end

function Module:RegisterOptions(data)
  db = data
  local defaults = {
		profile = {
		}
	}
  for k, v in pairs(db) do
      self:AddCharDeleteOption(k)
  end


	LibStub("AceConfig-3.0"):RegisterOptionsTable(moduleName, aceoptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(moduleName, moduleName)
end

function Module:OpenOptions()
	LibStub("AceConfigDialog-3.0"):Open(moduleName)
end
