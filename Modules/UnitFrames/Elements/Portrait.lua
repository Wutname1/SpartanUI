local UF = SUI.UF

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

local function UpdateSize(frame)
	if frame.Portrait3D then
		frame.Portrait3D:SetSize(frame.FrameHeight, frame.FrameHeight)
	end
	if frame.Portrait2D then
		frame.Portrait2D:SetSize(frame.FrameHeight, frame.FrameHeight)
	end
end

local function Options(unitName)
end

UF.Elements:Register('Portrait', Build, Update, Options, UpdateSize)
