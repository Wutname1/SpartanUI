local UF = SUI.UF

local function ElementBuild(frame, DB)
	frame.ClassIcon = frame:CreateTexture(nil, 'BORDER')
	frame.ClassIcon.Sizeable = true
	frame.ClassIcon.shadow = frame:CreateTexture(nil, 'BACKGROUND')
	frame.ClassIcon.shadow:SetPoint('TOPLEFT', frame.ClassIcon, 'TOPLEFT', 2, -2)
	frame.ClassIcon.shadow:SetPoint('BOTTOMRIGHT', frame.ClassIcon, 'BOTTOMRIGHT', 2, -2)
	frame.ClassIcon.shadow:SetVertexColor(0, 0, 0, .9)

	function frame.ClassIcon:PostUpdate()
		if self.DB and self.DB.enabled then
			self:Show()
			self.shadow:Show()
		else
			self:Hide()
			self.shadow:Hide()
		end
	end
end

local function ElementUpdate(frame)
	local DB = frame.ClassIcon.DB

	local reaction = UnitReaction(frame.unit, 'player')
	if not reaction then
		return
	end

	if
		((reaction <= 2 and DB.VisibleOn == 'hostile') or (reaction >= 3 and DB.VisibleOn == 'friendly') or
			(UnitPlayerControlled(frame.unit) and DB.VisibleOn == 'PlayerControlled') or
			DB.VisibleOn == 'all') and
			DB.enabled
	 then
		frame.ClassIcon:Show()
		frame.ClassIcon.shadow:Show()
		frame.ClassIcon:SetSize(DB.size, DB.size)
		frame.ClassIcon:SetPoint(DB.position.anchor, frame, DB.position.anchor, DB.position.x, DB.position.y)
	else
		frame.ClassIcon:Hide()
		frame.ClassIcon.shadow:Hide()
	end
end

local function ElementOptions(unitName, OptionSet)
	if unitName == 'boss' then
		OptionSet.hidden = true
	end
end

UF.Elements:Register('ClassIcon', ElementBuild, ElementUpdate, ElementOptions)

do -- ClassIcon as an SUIUF module
	local function Update(self, event, unit)
		local icon = self.ClassIcon
		if (icon) then
			local _, class = UnitClass(self.unit)
			if not class then
				return
			end

			local path = 'Interface\\AddOns\\SpartanUI\\images\\flat_classicons\\' .. (string.lower(class))

			if class then
				-- local coords = ClassIconCoord[class or 'DEFAULT']
				-- icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
				icon:SetTexture(path)
				icon:Show()
				if icon.shadow then
					icon.shadow:SetTexture(path)
					icon.shadow:Show()
				end
			else
				icon:Hide()
				icon.shadow:Hide()
			end
			if (icon.PostUpdate) then
				return icon:PostUpdate()
			end
		end
	end

	local function ForceUpdate(element)
		return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
	end

	local function Enable(self)
		local icon = self.ClassIcon
		if (icon) then
			icon.__owner = self
			icon.ForceUpdate = ForceUpdate
			self:RegisterEvent('PLAYER_TARGET_CHANGED', Update, true)
			self:RegisterEvent('UNIT_PET', Update, true)
			if icon.shadow == nil then
				icon.shadow = self:CreateTexture(nil, 'BACKGROUND')
				icon.shadow:SetSize(icon:GetSize())
				icon.shadow:SetPoint('CENTER', icon, 'CENTER', 2, -2)
				icon.shadow:SetVertexColor(0, 0, 0, .9)
			end
			return true
		end
	end

	local function Disable(self)
		local icon = self.ClassIcon
		if (icon) then
			self:UnregisterEvent('PLAYER_TARGET_CHANGED', Update)
			self:UnregisterEvent('UNIT_PET', Update)
			self.ClassIcon:Hide()
			self.ClassIcon.shadow:Hide()
		end
	end

	SUIUF:AddElement('ClassIcon', Update, Enable, Disable)
end
