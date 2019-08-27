local SUI, L = SUI, SUI.L
local addon = SUI:NewModule('SpinCam')
local SpinCamRunning = false
local userCameraYawMoveSpeed
local usercameraCustomViewSmoothing

function addon:OnInitialize()
	SUI.opt.args['ModSetting'].args['SpinCam'] = {
		name = L['Spin cam'],
		type = 'group',
		args = {
			enable = {
				name = L['Enable Spin when AFK'],
				type = 'toggle',
				order = 1,
				width = 'full',
				get = function(info)
					return SUI.DBMod.SpinCam.enable
				end,
				set = function(info, val)
					SUI.DBMod.SpinCam.enable = val
				end
			},
			speed = {
				name = L['Spin speed'],
				type = 'range',
				order = 5,
				width = 'full',
				min = 1,
				max = 230,
				step = 1,
				get = function(info)
					return SUI.DBMod.SpinCam.speed
				end,
				set = function(info, val)
					if SUI.DBMod.SpinCam.enable then
						SUI.DBMod.SpinCam.speed = val
					end
					if SpinCamRunning then
						addon:SpinToggle('update')
					end
				end
			},
			-- SUI.opt.args["SpinCam"].args["range"] = {name="Spin range",type="range",order=6,width="full",
			-- min=15,max=24,step=.1,
			-- get = function(info) return SUI.DBMod.SpinCam.range end,
			-- set = function(info,val) if SUI.DBMod.SpinCam.enable then SUI.DBMod.SpinCam.range = val; end if SpinCamRunning then addon:SpinToggle("update") end end
			-- }
			spin = {
				name = L['Toggle spin'],
				type = 'execute',
				order = 15,
				width = 'double',
				desc = L['SpinToggleDesc'],
				func = function(info, val)
					if SpinCamRunning then
						addon:SpinToggle('stop')
					else
						DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99SpinCam|r: ' .. L['SpinStopMSG'])
						addon:SpinToggle('start')
					end
				end
			}
		}
	}
end

function addon:OnEnable()
	userCameraYawMoveSpeed = tonumber(GetCVar('cameraYawMoveSpeed'))
	usercameraCustomViewSmoothing = tonumber(GetCVar('cameraCustomViewSmoothing'))

	local frame = CreateFrame('Frame')
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
	frame:RegisterEvent('PLAYER_ENTERING_WORLD')
	frame:SetScript(
		'OnEvent',
		function(self, event, ...)
			if event == 'CHAT_MSG_SYSTEM' then
				if (... == format(MARKED_AFK_MESSAGE, DEFAULT_AFK_MESSAGE)) and (SUI.DBMod.SpinCam.enable) then
					addon:SpinToggle('start')
				elseif (... == CLEARED_AFK) and (SpinCamRunning) then
					addon:SpinToggle('stop')
				end
			elseif event == 'PLAYER_LEAVING_WORLD' or event == 'PLAYER_ENTERING_WORLD' then
				addon:SpinToggle('stop')
			end
			if SUI.DBMod.SpinCam.speed == GetCVar('cameraYawMoveSpeed') and not SpinCamRunning then
				SetCVar('cameraYawMoveSpeed', userCameraYawMoveSpeed)
				SetCVar('cameraCustomViewSmoothing', usercameraCustomViewSmoothing)
			end
		end
	)
end

function addon:SpinToggle(action)
	if SpinCamRunning and action == 'stop' then
		SetView(4) -- restore saved position
		MoveViewRightStop()
		SetCVar('cameraYawMoveSpeed', userCameraYawMoveSpeed)
		SetCVar('cameraCustomViewSmoothing', usercameraCustomViewSmoothing)
		SpinCamRunning = false
	elseif action == 'update' then
		SetCVar('cameraYawMoveSpeed', SUI.DBMod.SpinCam.speed)
	elseif not SpinCamRunning and action == 'start' then
		--Update settings
		userCameraYawMoveSpeed = tonumber(GetCVar('cameraYawMoveSpeed'))
		usercameraCustomViewSmoothing = tonumber(GetCVar('cameraCustomViewSmoothing'))

		--Save camera position, activate new save slot
		SaveView(4) -- Save current settings as 4
		SetView(5) -- activate view 5 for spin cam

		--Start spin
		SetCVar('cameraYawMoveSpeed', SUI.DBMod.SpinCam.speed)
		MoveViewRightStart()
		SpinCamRunning = true
	end
end

SlashCmdList['SPINCAMTOGGLE'] = function(msg)
	if SpinCamRunning then
		addon:SpinToggle('stop')
	else
		DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99SpinCam|r: ' .. L['SpinStopMSG'])
		addon:SpinToggle('start')
	end
end
SLASH_SPINCAMTOGGLE1 = '/spin'
