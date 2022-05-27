local UF, L = SUI.UF, SUI.L

---@param frame table
---@param DB table
local function Build(frame, DB)
	-- 3D Portrait
	local Portrait3D = CreateFrame('PlayerModel', nil, frame)
	Portrait3D:SetSize(frame:GetHeight(), frame:GetHeight())
	Portrait3D:SetScale(DB.Scale)
	Portrait3D:SetFrameStrata('BACKGROUND')
	Portrait3D:SetFrameLevel(2)
	Portrait3D.PostUpdate = function(unit, event, shouldUpdate)
		if (frame:IsObjectType('PlayerModel')) then
			frame:SetAlpha(DB.alpha)

			local rotation = DB.rotation

			if frame:GetFacing() ~= (rotation / 57.29573671972358) then
				frame:SetFacing(rotation / 57.29573671972358) -- because 1 degree is equal 0,0174533 radian. Credit: Hndrxuprt
			end

			frame:SetCamDistanceScale(DB.camDistanceScale)
			frame:SetPosition(DB.xOffset, DB.xOffset, DB.yOffset)

			--Refresh model to fix incorrect display issues
			frame:ClearModel()
			frame:SetUnit(unit)
		end
	end
	frame.Portrait3D = Portrait3D

	-- 2D Portrait
	local Portrait2D = frame:CreateTexture(nil, 'OVERLAY')
	Portrait2D:SetSize(frame:GetHeight(), frame:GetHeight())
	Portrait2D:SetScale(DB.Scale)
	frame.Portrait2D = Portrait2D

	frame.Portrait = Portrait3D
end

---@param frame table
local function Update(frame)
	local DB = frame.Portrait.DB

	frame.Portrait3D:Hide()
	frame.Portrait2D:Hide()
	if DB.enabled then
		if DB.type == '3D' then
			frame.Portrait = frame.Portrait3D
			frame.Portrait3D:Show()
			if (frame.Portrait:IsObjectType('PlayerModel')) then
				frame.Portrait:SetAlpha(DB.alpha)

				local rotation = DB.rotation

				if frame.Portrait:GetFacing() ~= (rotation / 57.29573671972358) then
					frame.Portrait:SetFacing(rotation / 57.29573671972358) -- because 1 degree is equal 0,0174533 radian. Credit: Hndrxuprt
				end

				frame.Portrait:SetCamDistanceScale(DB.camDistanceScale)
				frame.Portrait:SetPosition(DB.xOffset, DB.xOffset, DB.yOffset)

				--Refresh model to fix incorrect display issues
				frame.Portrait:ClearModel()
				frame.Portrait:SetUnit(frame.unitOnCreate)
			end
		else
			frame.Portrait = frame.Portrait2D
			frame.Portrait2D:Show()
		end
		if DB.position == 'left' then
			frame.Portrait3D:SetPoint('RIGHT', frame, 'LEFT')
			frame.Portrait2D:SetPoint('RIGHT', frame, 'LEFT')
		else
			frame.Portrait3D:SetPoint('LEFT', frame, 'RIGHT')
			frame.Portrait2D:SetPoint('LEFT', frame, 'RIGHT')
		end
		frame:UpdateAllElements('OnUpdate')
	end
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	OptionSet.args.Portrait = {
		name = L['Portrait'],
		type = 'group',
		order = 3,
		inline = true,
		args = {
			enabled = {
				name = L['Enabled'],
				type = 'toggle',
				order = 10,
				get = function(info)
					return UF.CurrentSettings[unitName].elements.Portrait.enabled
				end,
				set = function(info, val)
					--Update memory
					UF.CurrentSettings[unitName].elements.Portrait.enabled = val
					--Update the DB
					UF.DB.UserSettings[UF.DB.Style][unitName].elements.Portrait.enabled = val
					--Update the screen
					if UF.Frames[unitName].Portrait then
						if val then
							UF.Frames[unitName]:EnableElement('Portrait')
							UF.Frames[unitName].Portrait:ForceUpdate()
						else
							UF.Frames[unitName]:DisableElement('Portrait')
						end
					else
						UF.Frames[unitName]:UpdateAll()
					end
				end
			},
			type = {
				name = L['Portrait type'],
				type = 'select',
				order = 20,
				values = {
					['3D'] = '3D',
					['2D'] = '2D'
				},
				get = function(info)
					return UF.CurrentSettings[unitName].elements.Portrait.type
				end,
				set = function(info, val)
					--Update memory
					UF.CurrentSettings[unitName].elements.Portrait.type = val
					--Update the DB
					UF.DB.UserSettings[UF.DB.Style][unitName].elements.Portrait.type = val
					--Update the screen
					UF.Frames[unitName]:ElementUpdate('Portrait')
				end
			},
			rotation = {
				name = L['Rotation'],
				type = 'range',
				min = -1,
				max = 1,
				step = .01,
				order = 21,
				get = function(info)
					return UF.CurrentSettings[unitName].elements.Portrait.rotation
				end,
				set = function(info, val)
					--Update memory
					UF.CurrentSettings[unitName].elements.Portrait.rotation = val
					--Update the DB
					UF.DB.UserSettings[UF.DB.Style][unitName].elements.Portrait.rotation = val
					--Update the screen
					UF.Frames[unitName]:ElementUpdate('Portrait')
				end
			},
			camDistanceScale = {
				name = L['Camera Distance Scale'],
				type = 'range',
				min = .01,
				max = 5,
				step = .1,
				order = 22,
				get = function(info)
					return UF.CurrentSettings[unitName].elements.Portrait.camDistanceScale
				end,
				set = function(info, val)
					--Update memory
					UF.CurrentSettings[unitName].elements.Portrait.camDistanceScale = val
					--Update the DB
					UF.DB.UserSettings[UF.DB.Style][unitName].elements.Portrait.camDistanceScale = val
					--Update the screen
					UF.Frames[unitName]:ElementUpdate('Portrait')
				end
			},
			position = {
				name = L['Position'],
				type = 'select',
				order = 30,
				values = {
					['left'] = L['Left'],
					['right'] = L['Right']
				},
				get = function(info)
					return UF.CurrentSettings[unitName].elements.Portrait.position
				end,
				set = function(info, val)
					--Update memory
					UF.CurrentSettings[unitName].elements.Portrait.position = val
					--Update the DB
					UF.DB.UserSettings[UF.DB.Style][unitName].elements.Portrait.position = val
					--Update the screen
					UF.Frames[unitName]:ElementUpdate('Portrait')
				end
			}
		}
	}
end

UF.Elements:Register('Portrait', Build, Update, Options)
