local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local module = SUI:NewModule('Component_AFKEffects')
module.DisplayName = L['AFK Effects']
module.description = 'Spin the camera around your character and apply some effects when AFK'
local print = SUI.print
----------------------------------------
local isAFK = false
local SpinCamRunning = false

----- Film Effects ----
local FilmEffectEvent = function(self, event, ...)
	for _, v in ipairs(EffectList) do
		if not module.db.profile.enable then
			Container[v]:Hide()
		elseif event == 'CHAT_MSG_SYSTEM' then
			if (... == format(MARKED_AFK_MESSAGE, DEFAULT_AFK_MESSAGE)) and (module.db.profile.Effects[v].afk) then
				Container[v]:Show()
			elseif (... == CLEARED_AFK) then
				Container[v]:Hide()
			end
		else
			if module.db.profile.Effects[v].always then
				Container[v]:Show()
			else
				Container[v]:Hide()
			end
		end
	end
end

----- Spin Cam ----
local function StopSpin()
	if not SpinCamRunning then
		return
	end

	MoveViewRightStop()
	SpinCamRunning = false
end

local function StartSpin()
	MoveViewRightStart(module.DB.SpinCam.speed)
	SpinCamRunning = true
end

----- Core ----

local function AFKToggle()
	if SUI:IsModuleDisabled('AFKEffects') or not module.DB.SpinCam.enabled then
		if SpinCamRunning then
			StopSpin()
		end
		return
	end
	if SpinCamRunning then
		StopSpin()
	else
		StartSpin()
	end
end

----- Base ----

local function Options()
	SUI.opt.args.ModSetting.args.AFKEffects = {
		name = L['AFK Effects'],
		type = 'group',
		get = function(info)
			return module.DB[info[#info]]
		end,
		args = {
			toggle = {
				name = L['Toggle Effects'],
				type = 'execute',
				order = 2,
				-- width = 'double',
				func = function(info, val)
					if not SpinCamRunning then
						DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99SpinCam|r: ' .. L['Spinning, to stop type /spin again'])
					end
					AFKToggle()
				end
			},
			SpinCam = {
				name = L['Spin cam'],
				type = 'group',
				inline = true,
				get = function(info)
					return module.DB.SpinCam.enabled
				end,
				set = function(info, val)
					module.DB.SpinCam.enabled = val
				end,
				args = {
					enabled = {
						name = L['Enabled'],
						type = 'toggle',
						order = 1,
						width = 'double'
					},
					speed = {
						name = L['Spin speed'],
						type = 'range',
						order = 3,
						width = 'full',
						min = 1,
						max = 100,
						step = 1,
						get = function(info)
							return (module.DB.SpinCam.speed * 100)
						end,
						set = function(info, val)
							module.DB.SpinCam.speed = (val / 100)
						end
					}
				}
			}
		}
	}
end

function module:OnInitialize()
	local defaults = {
		profile = {
			SpinCam = {
				enabled = true,
				speed = .08
			},
			FilmEffects = {
				enabled = true
			}
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('AFKEffects', defaults)
	module.DB = module.Database.profile
end

function module:OnEnable()
	Options()
	if SUI:IsModuleDisabled('AFKEffects') then
		return
	end

	local frame = CreateFrame('Frame')
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
	frame:RegisterEvent('PLAYER_ENTERING_WORLD')
	frame:SetScript(
		'OnEvent',
		function(self, event, ...)
			if event == 'CHAT_MSG_SYSTEM' then
				if (... == format(MARKED_AFK_MESSAGE, DEFAULT_AFK_MESSAGE)) then
					StartSpin()
				elseif (... == CLEARED_AFK) and (SpinCamRunning) then
					StopSpin()
				end
			elseif event == 'PLAYER_LEAVING_WORLD' or event == 'PLAYER_ENTERING_WORLD' then
				StopSpin()
			end
			-- This is to ensure that camera movement speed got reset, wow api "was" buggy at one point.
			if module.DB.SpinCam.speed == GetCVar('cameraYawMoveSpeed') and not SpinCamRunning then
				SetCVar('cameraYawMoveSpeed', userCameraYawMoveSpeed)
			end
		end
	)

	local ChatCommand = function(msg)
		if not SpinCamRunning then
			DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99SpinCam|r: ' .. L['Spinning, to stop type /spin again'])
		end
		AFKToggle()
	end
	SUI:AddChatCommand('spin', ChatCommand, 'Toggles the Spincam', nil, true)
end
