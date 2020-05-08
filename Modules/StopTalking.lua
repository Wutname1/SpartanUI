local SUI = SUI
if SUI.IsClassic then
	return
end
local module = SUI:NewModule('Component_StopTalking')
local L = SUI.L
module.DisplayName = 'Stop Talking'
module.description = 'Mutes the talking head frame once you have heard it.'
----------------------------------------------------------------------------------------------------
local HeardLines = {}

function module:OnInitialize()
	local defaults = {
		profile = {
			persist = true,
			chatOutput = true,
			lines = {}
		}
	}
	module.DB = SUI.SpartanUIDB:RegisterNamespace('StopTalking', defaults)
end

local function Options()
	SUI.opt.args['ModSetting'].args['StopTalking'] = {
		name = 'Stop Talking',
		type = 'group',
		get = function(info)
			return module.DB.profile[info[#info]]
		end,
		set = function(info, val)
			module.DB.profile[info[#info]] = val
		end,
		args = {
			persist = {
				name = 'Keep track of voice lines forever',
				type = 'toggle',
				order = 1,
				width = 'full'
			},
			chatOutput = {
				name = 'Display heard voice lines in the chat.',
				type = 'toggle',
				order = 2,
				width = 'full'
			}
		}
	}
end

function module:OnEnable()
	if not SUI.DB.EnabledComponents.StopTalking then
		return
	end

	local function SetupRedirect(args)
		-- Copy the Blizzard function local
		local TalkingHeadFrame_PlayCurrent_Blizz = TalkingHeadFrame_PlayCurrent

		--Setup our catch function
		local NewPlayFunc = function()
			if SUI.DB.EnabledComponents.StopTalking then
				local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead =
					C_TalkingHead.GetCurrentLineInfo()
				if not vo then
					return
				end
				local persist = module.DB.profile.persist
				if (module.DB.profile.lines[vo] and persist) or (not persist and HeardLines[vo]) then
					-- Heard this before.
					if module.DB.profile.chatOutput and name and text then
						SUI:Print(name)
						print(text)
					end

					return
				else
					-- New, flag it as heard.
					if persist then
						module.DB.profile.lines[vo] = true
					else
						HeardLines[vo] = true
					end
				end
			end

			--Run the archived blizzard function
			TalkingHeadFrame_PlayCurrent_Blizz()
		end

		-- Assign our catch function
		TalkingHeadFrame_PlayCurrent = NewPlayFunc
	end

	if IsAddOnLoaded('Blizzard_TalkingHeadUI') then
		SetupRedirect()
	else
		--We want the mover to be available immediately, so we load it ourselves
		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_ENTERING_WORLD')
		f:SetScript(
			'OnEvent',
			function(frame, event)
				frame:UnregisterEvent(event)
				_G.TalkingHead_LoadUI()
				SetupRedirect()
			end
		)
	end

	Options()
end
