local SUI, L = SUI, SUI.L
local module = SUI:NewModule('Component_SpinCam')
module.description = 'Spin the camera around your character when AFK'
local print = SUI.print
local SpinCamRunning = false
local userCameraYawMoveSpeed
local usercameraCustomViewSmoothing

function module:OnInitialize()
	local defaults = {
		profile = {
			speed = 8,
			useView = 4,
			saveView = 5
		}
	}
	module.DB = SUI.SpartanUIDB:RegisterNamespace('SpinCam', defaults)
end

local function StopSpin()
	if not SpinCamRunning then
		return
	end

	SetView(module.DB.profile.saveView) -- restore saved position
	ResetView(module.DB.profile.saveView)
	ResetView(module.DB.profile.useView)
	MoveViewRightStop()
	SetCVar('cameraYawMoveSpeed', userCameraYawMoveSpeed)
	SpinCamRunning = false
end

local function StartSpin()
	--Save user settings
	userCameraYawMoveSpeed = tonumber(GetCVar('cameraYawMoveSpeed'))

	--Save camera position, activate new save slot
	SaveView(module.DB.profile.saveView) -- Save current settings as 4
	SetView(module.DB.profile.useView) -- activate view 5 for spin cam

	--Start spin
	SetCVar('cameraYawMoveSpeed', module.DB.profile.speed)
	MoveViewRightStart()
	SpinCamRunning = true
end

function module:SpinToggle()
	if not SUI.DB.EnabledComponents.SpinCam then
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

function module:OnEnable()
	module:Options()
	if not SUI.DB.EnabledComponents.SpinCam then
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
			if module.DB.profile.speed == GetCVar('cameraYawMoveSpeed') and not SpinCamRunning then
				SetCVar('cameraYawMoveSpeed', userCameraYawMoveSpeed)
			end
		end
	)
end

function module:Options()
	SUI.opt.args['ModSetting'].args['SpinCam'] = {
		name = L['Spin cam'],
		type = 'group',
		get = function(info)
			return module.DB.profile[info[#info]]
		end,
		args = {
			enable = {
				name = L['Enable Spin when AFK'],
				type = 'toggle',
				order = 1,
				width = 'double',
				get = function(info)
					return SUI.DB.EnabledComponents.SpinCam
				end,
				set = function(info, val)
					SUI.DB.EnabledComponents.SpinCam = val
				end
			},
			spin = {
				name = L['Toggle spin'],
				type = 'execute',
				order = 2,
				width = 'double',
				desc = L['SpinToggleDesc'],
				func = function(info, val)
					if not SpinCamRunning then
						DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99SpinCam|r: ' .. L['SpinStopMSG'])
					end
					module:SpinToggle()
				end
			},
			speed = {
				name = L['Spin speed'],
				type = 'range',
				order = 3,
				width = 'full',
				min = 1,
				max = 230,
				step = 1,
				set = function(info, val)
					module.DB.profile.speed = val
					if SpinCamRunning then
						SetCVar('cameraYawMoveSpeed', module.DB.profile.speed)
					end
				end
			},
			resetdesc = {
				name = 'The views used below will be reset to their defaults after SpinCam is done using them.',
				type = 'header',
				order = 4
			},
			useView = {
				name = 'View for spining',
				desc = 'Camera to use when spinning the camera',
				type = 'select',
				order = 5,
				values = {[2] = '2', [3] = '3', [4] = '4', [5] = '5'},
				set = function(info, val)
					if val == module.DB.profile.saveView then
						print('Unable to use the same view for both settings')
						return
					end
					module.DB.profile.useView = val
				end
			},
			saveView = {
				name = 'View to save camera position',
				desc = 'Camera to use save the cameras last position before spinning',
				type = 'select',
				order = 6,
				values = {[2] = '2', [3] = '3', [4] = '4', [5] = '5'},
				set = function(info, val)
					if val == module.DB.profile.useView then
						print('Unable to use the same view for both settings')
						return
					end
					module.DB.profile.saveView = val
				end
			}
		}
	}
end

SlashCmdList['SPINCAMTOGGLE'] = function(msg)
	if not SpinCamRunning then
		DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99SpinCam|r: ' .. L['SpinStopMSG'])
	end
	module:SpinToggle()
end
SLASH_SPINCAMTOGGLE1 = '/spin'
