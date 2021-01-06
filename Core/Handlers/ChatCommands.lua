local SUI, print = SUI, SUI.print
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
	SUI.opt.args.Help.args.ChatCommands.args[arg] = {
		name = (settings.commandDescription or ''),
		type = 'input',
		width = 'full',
		get = function(info)
			return '/sui ' .. arg
		end,
		set = function(info, val)
		end
	}
end

function SUI:AddChatCommand(arg, func, commandDescription, argumentDesciption, argOptional)
	if SUIChatCommands[arg] then
		SUI:Error(arg .. ' Chat command has already been added')
		return
	end

	-- Add the command in
	SUIChatCommands[arg] = func

	-- Setup the details table
	CommandDetails[arg] = {
		func = func,
		commandDescription = commandDescription,
		argumentDesciption = argumentDesciption,
		argOptional = (argOptional or true)
	}

	-- if OnEnable has ran add to options
	if enabled then
		AddToOptions(arg)
	end
end

function module:OnEnable()
	SUI.opt.args.Help.args.ChatCommands = {
		name = 'Chat commands',
		type = 'group',
		args = {}
	}
	for k, _ in pairs(CommandDetails) do
		AddToOptions(k)
	end
	enabled = true
end
