local UF = SUI.UF

local function Build(frame, DB)
	local SUIpvpIndicator = function(self, event, unit)
		if (unit ~= self.unit) then
			return
		end

		local pvp = self.PvPIndicator
		if (pvp.PreUpdate) then
			pvp:PreUpdate()
		end

		local status
		local factionGroup = UnitFactionGroup(unit) or 'Neutral'
		local honorRewardInfo = false
		if SUI.IsRetail then
			honorRewardInfo = C_PvP.GetHonorRewardInfo(UnitHonorLevel(unit))
		end

		if (UnitIsPVPFreeForAll(unit)) then
			pvp:SetTexture('Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon')
			status = 'FFA'
		elseif (factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(unit)) then
			status = factionGroup
		end

		if (status) then
			pvp:Show()

			if (pvp.Badge and honorRewardInfo) then
				pvp:SetTexture(honorRewardInfo.badgeFileDataID)
				pvp:SetTexCoord(0, 1, 0, 1)

				if (pvp.shadow) then
					pvp.shadow:Hide()
				end
			else
				if (pvp.shadow) then
					pvp.shadow:Show()
				end
				if (status == 'FFA') then
					pvp:SetTexture('Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon')
				else
					pvp:SetTexture('Interface\\FriendsFrame\\PlusManz-' .. factionGroup)
					if (pvp.shadow) then
						pvp.shadow:SetTexture('Interface\\FriendsFrame\\PlusManz-' .. factionGroup)
					end
				end

				if (pvp.Badge) then
					pvp.Badge:Hide()
				end
			end
		else
			pvp:Hide()
			if (pvp.shadow) then
				pvp.shadow:Hide()
			end
		end

		if (pvp.PostUpdate) then
			return pvp:PostUpdate(status)
		end
	end
	frame.PvPIndicator = frame:CreateTexture(nil, 'ARTWORK')
	frame.PvPIndicator:SetSize(DB.size, DB.size)
	frame.PvPIndicator.ShadowBackup = frame:CreateTexture(nil, 'ARTWORK')
	frame.PvPIndicator.ShadowBackup:SetSize(DB.size, DB.size)

	local Badge = frame:CreateTexture(nil, 'BACKGROUND')
	Badge:SetSize(DB.size + 12, DB.size + 12)
	Badge:SetPoint('CENTER', frame.PvPIndicator, 'CENTER')

	frame.PvPIndicator.BadgeBackup = Badge
	frame.PvPIndicator.Badge = Badge
	frame.PvPIndicator.SizeChange = function()
		frame.PvPIndicator:SetSize(DB.size, DB.size)
		frame.PvPIndicator.BadgeBackup:SetSize(DB.size + 12, DB.size + 12)
		if frame.PvPIndicator.Badge then
			frame.PvPIndicator.Badge:SetSize(DB.size + 12, DB.size + 12)
		end
		frame.PvPIndicator.ShadowBackup:SetSize(DB.size + 12, DB.size + 12)
		if frame.PvPIndicator.Shadow then
			frame.PvPIndicator.Shadow:SetSize(DB.size + 12, DB.size + 12)
		end
	end
	frame.PvPIndicator.Override = SUIpvpIndicator
end

local function Update(frame)
	local DB = frame.PVPIndicator.DB

	for k, v in pairs({['Badge'] = 'BadgeBackup', ['Shadow'] = 'ShadowBackup'}) do
		-- If badge is true but does not exsist create from backup
		if DB[k] and frame.PvPIndicator[k] == nil then
			frame.PvPIndicator[k] = frame.PvPIndicator[v]
		elseif not DB[k] and frame.PvPIndicator[k] then
			-- If badge is false but exsists remove it
			frame.PvPIndicator[k]:Hide()
			frame.PvPIndicator[k] = nil
		end
	end
end

local function Options(unitName, OptionSet)
	-- Badge
	local i = 1
	for k, v in pairs({['Badge'] = 'BadgeBackup', ['Shadow'] = 'ShadowBackup'}) do
		SUI.opt.args.UnitFrames.args[unitName].args.indicators.args.PvPIndicator.args[k] = {
			name = (k == 'Badge' and 'Show honor badge') or 'Shadow',
			type = 'toggle',
			order = 70 + i,
			get = function(info)
				return UF.CurrentSettings[unitName].elements.PvPIndicator[k]
			end,
			set = function(info, val)
				--Update memory
				UF.CurrentSettings[unitName].elements.PvPIndicator[k] = val
				--Update the DB
				UF.DB.UserSettings[UF.DB.Style][unitName].elements.PvPIndicator[k] = val
				--Update the screen
				if val then
					UF.frames[unitName].PvPIndicator[k] = UF.frames[unitName].PvPIndicator[v]
				else
					UF.frames[unitName].PvPIndicator[k]:Hide()
					UF.frames[unitName].PvPIndicator[k] = nil
				end
				UF.frames[unitName].PvPIndicator:ForceUpdate('OnUpdate')
			end
		}
		i = i + 1
	end
end

UF.Elements:Register('PVPIndicator', Build, Update, Options)
