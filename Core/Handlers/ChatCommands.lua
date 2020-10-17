local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local module = SUI:NewModule('Handler_ChatCommands', 'AceTimer-3.0')
local SUIChatCommands = {}

local ResetDBWarning = false
function SUI:ChatCommand(input)
	if input == 'resetfulldb' then
		if ResetDBWarning then
			Bartender4.db:ResetDB()
			SUI.SpartanUIDB:ResetDB()
		else
			ResetDBWarning = true
			SUI:Print('|cffff0000Warning')
			SUI:Print(
				L[
					'This will reset the full SpartanUI & Bartender4 database. If you wish to continue perform the chat command again.'
				]
			)
		end
	elseif input == 'resetbartender' then
		SUI.opt.args['General'].args['Bartender'].args['ResetActionBars']:func()
	elseif input == 'resetdb' then
		if ResetDBWarning then
			SUI.SpartanUIDB:ResetDB()
		else
			ResetDBWarning = true
			SUI:Print('|cffff0000Warning')
			SUI:Print(L['This will reset the SpartanUI Database. If you wish to continue perform the chat command again.'])
		end
	elseif input == 'help' then
		SUI:suihelp()
	elseif input == 'version' then
		SUI:Print(L['Version'] .. ' ' .. GetAddOnMetadata('SpartanUI', 'Version'))
		SUI:Print(string.format('%s build %s', wowVersion, SUI.BuildNum))
		if SUI.Bartender4Version ~= 0 then
			SUI:Print(L['Bartender4 version'] .. ' ' .. SUI.Bartender4Version)
		end
	else
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
			Lib.AceCD:Open('SpartanUI')
		end
	end
end

function SUI:AddChatCommand(arg, func)
	SUIChatCommands[arg] = func
end
