local SUI, L = SUI, SUI.L
local module = SUI:NewModule('Handler_ChatCommands')
local SUIChatCommands, CommandDetails, enabled = {}, {}, false

function SUI:ChatCommand(input)
	if SUIChatCommands[input] then
		SUIChatCommands[input]()
	elseif string.find(input, ' ') then
		for i in string.gmatch(input, '%S+') do
			local arg, _ = string.gsub(input, i .. ' ', '')
			if SUIChatCommands[i] then
				SUIChatCommands[i](arg)
			end
		end
	else
		SUI:GetModule('Handler_Options'):ToggleOptions()
	end
end

local function AddToOptions(arg)
	local settings = CommandDetails[arg]

	if settings.arguments then
		if settings.arguments.required then
		else
			SUI.opt.args.Help.args.ChatCommands.args[arg] = {
				name = '',
				type = 'group',
				inline = true,
				args = {
					[arg] = {
						name = (settings.commandDescription or ''),
						type = 'input',
						width = 'full',
						order = 1,
						get = function()
							return '/sui ' .. arg
						end,
						set = function()
						end
					}
				}
			}
			local i = 2
			for k, v in pairs(settings.arguments) do
				if type(v) ~= 'boolean' then
					SUI.opt.args.Help.args.ChatCommands.args[arg].args[k] = {
						name = (v or ''),
						type = 'input',
						width = 'full',
						order = i,
						get = function()
							return '/sui ' .. arg .. ' ' .. k
						end,
						set = function()
						end
					}
					i = i + 1
				end
			end
		end
	else
		SUI.opt.args.Help.args.ChatCommands.args[arg] = {
			name = (settings.commandDescription or ''),
			type = 'input',
			width = 'full',
			get = function()
				return '/sui ' .. arg
			end,
			set = function()
			end
		}
	end
end

function SUI:AddChatCommand(arg, func, commandDescription, arguments, silent)
	if SUIChatCommands[arg] then
		if not silent then
			SUI:Error(arg .. ' Chat command has already been added')
		end

		return
	end

	-- Add the command in
	SUIChatCommands[arg] = func

	-- Setup the details table
	CommandDetails[arg] = {
		func = func,
		commandDescription = commandDescription,
		arguments = arguments
	}

	-- if OnEnable has ran add to options
	if enabled then
		AddToOptions(arg)
	end
end

function module:OnEnable()
	SUI.opt.args.Help.args.ChatCommands = {
		name = L['Chat commands'],
		type = 'group',
		args = {}
	}
	for k, _ in pairs(CommandDetails) do
		AddToOptions(k)
	end
	enabled = true
end
