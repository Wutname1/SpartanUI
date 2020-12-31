local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local SUIChatCommands = {}

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

function SUI:AddChatCommand(arg, func)
	SUIChatCommands[arg] = func
end
