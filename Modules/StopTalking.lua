local SUI = SUI
if not SUI.IsRetail then
	return
end
local module = SUI:NewModule('Component_StopTalking')
local L = SUI.L
module.Displayname = L['Stop Talking']
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
	module.Database = SUI.SpartanUIDB:RegisterNamespace('StopTalking', defaults)
	module.DB = module.Database.profile
end

local function Options()
	SUI.opt.args['ModSetting'].args['StopTalking'] = {
		name = L['Stop Talking'],
		type = 'group',
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
		end,
		args = {
			persist = {
				name = L['Keep track of voice lines forever'],
				type = 'toggle',
				order = 1,
				width = 'full'
			},
			chatOutput = {
				name = L['Display heard voice lines in the chat.'],
				type = 'toggle',
				order = 2,
				width = 'full'
			}
		}
	}
end

function module:OnEnable()
	if SUI.DB.DisabledComponents.StopTalking then
		return
	end

	local function SetupRedirect(args)
		-- Copy the Blizzard function local
		local TalkingHeadFrame_PlayCurrent_Blizz = TalkingHeadFrame_PlayCurrent

		--Setup our catch function
		local NewPlayFunc = function()
			if SUI:IsModuleEnabled('StopTalking') then
				local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead =
					C_TalkingHead.GetCurrentLineInfo()
				if not vo then
					return
				end
				local persist = module.DB.persist
				if (module.DB.lines[vo] and persist) or (not persist and HeardLines[vo]) then
					-- Heard this before.
					if module.DB.chatOutput and name and text then
						SUI:Print(name)
						print(text)
					end

					return
				else
					-- New, flag it as heard.
					if persist then
						module.DB.lines[vo] = true
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
