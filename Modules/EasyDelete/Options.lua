local SUI, L = SUI, SUI.L
---@class SUI.Module.EasyDelete
local module = SUI:GetModule('EasyDelete')

function module:BuildOptions()
	---@type AceConfig.OptionsTable
	local OptionTable = {
		type = 'group',
		name = 'Easy Delete',
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		args = {
			description = {
				name = 'Removes the need to type DELETE when destroying items. The item link is displayed so you can verify what you are deleting before clicking confirm.',
				type = 'description',
				order = 1,
				fontSize = 'medium',
				width = 'full',
			},
		},
	}

	SUI.Options:AddOptions(OptionTable, 'EasyDelete')
end
