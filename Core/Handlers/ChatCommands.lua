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
	elseif input == 'setup' then
		SUI:GetModule('SetupWizard'):SetupWizard()
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

function SUI.Print(self, ...)
	local tmp = {}
	local n = 1
	tmp[1] = '|cffffffffSpartan|cffe21f1fUI|r:'
	for i = 1, select('#', ...) do
		n = n + 1
		tmp[n] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage(table.concat(tmp, ' ', 1, n))
end

function SUI.print(msg, doNotLabel)
	if doNotLabel then
		print(msg)
	else
		SUI:Print(msg)
	end
end

function SUI:Error(err, mod)
	SUI:Print('|cffff0000Error detected')
	if mod then
		SUI:Print("An error has occured in the Component '" .. mod .. "'")
	else
		SUI:Print('An error has occured')
	end
	SUI:Print('Details: ' .. (err or 'None provided'))
	SUI:Print('Please submit a bug at |cff3370FFhttp://bugs.spartanui.net/')
end
