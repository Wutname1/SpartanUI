---@class SUI
local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Handler_ChatCommands') ---@type SUI.Module
local SUIChatCommands, CommandDetails, enabled = {}, {}, false

function SUI:ChatCommand(input)
	if SUIChatCommands[input] then
		SUIChatCommands[input]()
	elseif string.find(input, ' ') then
		for i in string.gmatch(input, '%S+') do
			local arg, _ = string.gsub(input, i .. ' ', '')
			if SUIChatCommands[i] then SUIChatCommands[i](arg) end
		end
	else
		SUI:GetModule('Handler_Options'):ToggleOptions()
	end
end

AddonCompartmentFrame:RegisterAddon({
	text = 'Spartan|cffe21f1fUI',
	icon = 'Interface\\AddOns\\SpartanUI\\images\\Spartan-Helm',
	registerForAnyClick = true,
	notCheckable = true,
	func = function(btn, arg1, arg2, checked, mouseButton)
		if IsShiftKeyDown() then
			SUI.MoveIt:MoveIt()
			return
		end
		-- if mouseButton == 'LeftButton' then
		-- elseif mouseButton == 'MiddleButton' then
		-- elseif mouseButton == 'RightButton' then
		-- end

		SUI:GetModule('Handler_Options'):ToggleOptions()
	end,
	funcOnEnter = function()
		-- GameTooltip:ClearLines()
		GameTooltip:SetOwner(AddonCompartmentFrame, 'ANCHOR_CURSOR_RIGHT')
		GameTooltip:AddDoubleLine('|TInterface/Addons/SpartanUI/images/Spartan-helm:20:20|t |cffffffffSpartan|cffe21f1fUI', '|cffffffff' .. (SUI.releaseType or '') .. tostring(SUI.Version))
		GameTooltip:AddLine(' ', 1, 1, 1)
		GameTooltip:AddLine('|cffeda55fLeft-Click|r to toggle the options window.', 1, 1, 1)
		GameTooltip:AddLine('|cffeda55fShift-Click|r to toggle the movement system.', 1, 1, 1)
		GameTooltip:Show()
	end,
})

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
						set = function() end,
					},
				},
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
						set = function() end,
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
			set = function() end,
		}
	end
end

---@param arg string the chat command to register
---@param func function the function that will be called when the command is used
---@param commandDescription string the description of the command
---@param arguments? table the arguments that the command takes
---@param silent? boolean if adding the command should error silently
function SUI:AddChatCommand(arg, func, commandDescription, arguments, silent)
	if SUIChatCommands[arg] then
		if not silent then SUI:Error(arg .. ' Chat command has already been added') end
		return
	end

	-- Add the command in
	SUIChatCommands[arg] = func

	-- Setup the details table
	CommandDetails[arg] = {
		func = func,
		commandDescription = commandDescription,
		arguments = arguments,
	}

	-- if OnEnable has ran add to options
	if enabled then AddToOptions(arg) end
end

function module:OnEnable()
	SUI.opt.args.Help.args.ChatCommands = {
		name = L['Chat commands'],
		type = 'group',
		args = {},
	}
	for k, _ in pairs(CommandDetails) do
		AddToOptions(k)
	end
	enabled = true
end
