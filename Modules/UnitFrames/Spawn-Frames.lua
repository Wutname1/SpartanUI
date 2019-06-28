local SUI = SUI
local PartyFrames = SUI.PartyFrames
----------------------------------------------------------------------------------------------------
local FramesList = {
	[1] = 'pet',
	[2] = 'target',
	[3] = 'targettarget',
	[4] = 'focus',
	[5] = 'focustarget',
	[6] = 'player'
}

function PlayerFrames:SUI_PlayerFrames_Classic()
	SUIUF:SetActiveStyle('SUI_PlayerFrames_Classic')

	for _, b in pairs(FramesList) do
		PlayerFrames[b] = SUIUF:Spawn(b, 'SUI_' .. b .. 'Frame')
		if b == 'player' then
			PlayerFrames:SetupExtras()
		end
	end

	PlayerFrames:PositionFrame_Classic()

	if SUI.DBMod.PlayerFrames.BossFrame.display == true then
		for i = 1, MAX_BOSS_FRAMES do
			PlayerFrames.boss[i] = SUIUF:Spawn('boss' .. i, 'SUI_Boss' .. i)
			if i == 1 then
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			else
				PlayerFrames.boss[i]:SetPoint('TOP', PlayerFrames.boss[i - 1], 'BOTTOM', 0, -10)
			end
		end
	end
	if SUI.DBMod.PlayerFrames.ArenaFrame.display == true then
		for i = 1, 3 do
			PlayerFrames.arena[i] = SUIUF:Spawn('arena' .. i, 'SUI_Arena' .. i)
			if i == 1 then
				PlayerFrames.arena[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				PlayerFrames.arena[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			else
				PlayerFrames.arena[i]:SetPoint('TOP', PlayerFrames.arena[i - 1], 'BOTTOM', 0, -10)
			end
		end
	end

	if SpartanUI then
		local unattached = false
		SpartanUI:HookScript(
			'OnHide',
			function(this, event)
				if UnitUsingVehicle('player') then
					SUI_FramesAnchor:SetParent(UIParent)
					unattached = true
				end
			end
		)

		SpartanUI:HookScript(
			'OnShow',
			function(this, event)
				if unattached then
					SUI_FramesAnchor:SetParent(SpartanUI)
					PlayerFrames:PositionFrame_Classic()
				end
			end
		)
	end
end

function PlayerFrames:PositionFrame_Classic(b)
	PlayerFrames.pet:SetParent(PlayerFrames.player)
	PlayerFrames.targettarget:SetParent(PlayerFrames.target)

	if (SUI_FramesAnchor:GetParent() == UIParent) then
		if b == 'player' or b == nil then
			PlayerFrames.player:SetPoint('BOTTOM', UIParent, 'BOTTOM', -220, 150)
		end
		if b == 'pet' or b == nil then
			PlayerFrames.pet:SetPoint('BOTTOMRIGHT', PlayerFrames.player, 'BOTTOMLEFT', -18, 12)
		end
		if b == 'target' or b == nil then
			PlayerFrames.target:SetPoint('LEFT', PlayerFrames.player, 'RIGHT', 100, 0)
		end

		if SUI.DBMod.PlayerFrames.targettarget.style == 'small' then
			if b == 'targettarget' or b == nil then
				PlayerFrames.targettarget:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'BOTTOMRIGHT', 8, -11)
			end
		else
			if b == 'targettarget' or b == nil then
				PlayerFrames.targettarget:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'BOTTOMRIGHT', 19, 15)
			end
		end

		for _, c in pairs(FramesList) do
			PlayerFrames[c]:SetScale(SUI.DB.scale)
		end
	else
		if b == 'player' or b == nil then
			PlayerFrames.player:SetPoint('BOTTOMRIGHT', SUI_FramesAnchor, 'TOP', -72, -3)
		end
		if b == 'pet' or b == nil then
			PlayerFrames.pet:SetPoint('BOTTOMRIGHT', PlayerFrames.player, 'BOTTOMLEFT', -18, 12)
		end
		if b == 'target' or b == nil then
			PlayerFrames.target:SetPoint('BOTTOMLEFT', SUI_FramesAnchor, 'TOP', 54, -3)
		end

		if SUI.DBMod.PlayerFrames.targettarget.style == 'small' then
			if b == 'targettarget' or b == nil then
				PlayerFrames.targettarget:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'BOTTOMRIGHT', -5, -15)
			end
		else
			if b == 'targettarget' or b == nil then
				PlayerFrames.targettarget:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'BOTTOMRIGHT', 7, 12)
			end
		end
	end

	if b == 'focus' or b == nil then
		PlayerFrames.focus:SetPoint('BOTTOMLEFT', PlayerFrames.target, 'TOP', 0, 30)
	end
	if b == 'focustarget' or b == nil then
		PlayerFrames.focustarget:SetPoint('BOTTOMLEFT', PlayerFrames.focus, 'BOTTOMRIGHT', -35, 0)
	end
end

function PlayerFrames:AddMover(frame, framename)
	if frame == nil then
		SUI:Err('PlayerFrames', SUI.DBMod.PlayerFrames.Style .. ' did not spawn ' .. framename)
	else
		frame.mover = CreateFrame('Frame')
		frame.mover:SetSize(20, 20)

		if framename == 'boss' then
			frame.mover:SetPoint('TOPLEFT', PlayerFrames.boss[1], 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', PlayerFrames.boss[MAX_BOSS_FRAMES], 'BOTTOMRIGHT')
		elseif framename == 'arena' then
			frame.mover:SetPoint('TOPLEFT', PlayerFrames.boss[1], 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', PlayerFrames.boss[MAX_BOSS_FRAMES], 'BOTTOMRIGHT')
		else
			frame.mover:SetPoint('TOPLEFT', frame, 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
		end

		frame.mover:EnableMouse(true)
		frame.mover:SetFrameStrata('LOW')

		frame:EnableMouse(enable)
		frame:SetScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' and IsAltKeyDown() then
					frame.mover:Show()
					SUI.DBMod.PlayerFrames[framename].moved = true
					frame:SetMovable(true)
					frame:StartMoving()
				end
			end
		)
		frame:SetScript(
			'OnMouseUp',
			function(self, button)
				frame.mover:Hide()
				frame:StopMovingOrSizing()
				local Anchors = {}
				Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = frame:GetPoint()
				Anchors.relativeTo = 'UIParent'
				for k, v in pairs(Anchors) do
					SUI.DBMod.PlayerFrames[framename].Anchors[k] = v
				end
			end
		)

		frame.mover.bg = frame.mover:CreateTexture(nil, 'BACKGROUND')
		frame.mover.bg:SetAllPoints(frame.mover)
		frame.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		frame.mover.bg:SetVertexColor(1, 1, 1, 0.5)

		frame.mover:SetScript(
			'OnEvent',
			function()
				PlayerFrames.locked = 1
				frame.mover:Hide()
			end
		)
		frame.mover:RegisterEvent('VARIABLES_LOADED')
		frame.mover:RegisterEvent('PLAYER_REGEN_DISABLED')
		frame.mover:Hide()

		--Set Position if moved
		if SUI.DBMod.PlayerFrames[framename].moved then
			frame:SetMovable(true)
			frame:SetUserPlaced(false)
			local Anchors = {}
			for k, v in pairs(SUI.DBMod.PlayerFrames[framename].Anchors) do
				Anchors[k] = v
			end
			frame:ClearAllPoints()
			frame:SetPoint(Anchors.point, UIParent, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		else
			frame:SetMovable(false)
		end
	end
end

function PlayerFrames:BossMoveScripts(frame)
	frame:EnableMouse(enable)
	frame:SetScript(
		'OnMouseDown',
		function(self, button)
			if button == 'LeftButton' and IsAltKeyDown() then
				PlayerFrames.boss[1].mover:Show()
				SUI.DBMod.PlayerFrames.boss.moved = true
				PlayerFrames.boss[1]:SetMovable(true)
				PlayerFrames.boss[1]:StartMoving()
			end
		end
	)
	frame:SetScript(
		'OnMouseUp',
		function(self, button)
			PlayerFrames.boss[1].mover:Hide()
			PlayerFrames.boss[1]:StopMovingOrSizing()
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs =
				PlayerFrames.boss[1]:GetPoint()
			for k, v in pairs(Anchors) do
				SUI.DBMod.PlayerFrames.boss.Anchors[k] = v
			end
		end
	)
end

function PlayerFrames:UpdateArenaFramePosition()
	if (InCombatLockdown()) then
		return
	end
	if SUI.DBMod.PlayerFrames.ArenaFrame.movement.moved then
		SUI_Arena1:SetPoint(
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.point,
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.relativeTo,
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.relativePoint,
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.xOffset,
			SUI.DBMod.PlayerFrames.ArenaFrame.movement.yOffset
		)
	else
		SUI_Arena1:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', -50, -490)
	end
end

function PlayerFrames:UpdateBossFramePosition()
	if (InCombatLockdown()) then
		return
	end
	if SUI.DBMod.PlayerFrames.BossFrame.movement.moved then
		SUI_Boss1:SetPoint(
			SUI.DBMod.PlayerFrames.BossFrame.movement.point,
			SUI.DBMod.PlayerFrames.BossFrame.movement.relativeTo,
			SUI.DBMod.PlayerFrames.BossFrame.movement.relativePoint,
			SUI.DBMod.PlayerFrames.BossFrame.movement.xOffset,
			SUI.DBMod.PlayerFrames.BossFrame.movement.yOffset
		)
	else
		SUI_Boss1:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', -50, -490)
	end
end

function PlayerFrames:ArenaMoveScripts(frame)
	frame:EnableMouse(enable)
	frame:SetScript(
		'OnMouseDown',
		function(self, button)
			if button == 'LeftButton' and IsAltKeyDown() then
				PlayerFrames.arena[1].mover:Show()
				DBMod.PlayerFrames.arena.moved = true
				PlayerFrames.arena[1]:SetMovable(true)
				PlayerFrames.arena[1]:StartMoving()
			end
		end
	)
	frame:SetScript(
		'OnMouseUp',
		function(self, button)
			PlayerFrames.arena[1].mover:Hide()
			PlayerFrames.arena[1]:StopMovingOrSizing()
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs =
				PlayerFrames.arena[1]:GetPoint()
			for k, v in pairs(Anchors) do
				DBMod.PlayerFrames.arena.Anchors[k] = v
			end
		end
	)
end

function PlayerFrames:OnEnable()
	PlayerFrames.boss = {}
	PlayerFrames.arena = {}
	if (SUI.DBMod.PlayerFrames.Style == 'Classic') then
		PlayerFrames:BuffOptions()
		PlayerFrames:SUI_PlayerFrames_Classic()
	else
		SUI:GetModule('Style_' .. SUI.DBMod.PlayerFrames.Style):PlayerFrames()
	end

	if SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Movable.PlayerFrames == true then
		for _, b in pairs(FramesList) do
			PlayerFrames:AddMover(PlayerFrames[b], b)
		end
		if SUI.DBMod.PlayerFrames.BossFrame.display then
			PlayerFrames:AddMover(PlayerFrames.boss[1], 'boss')
			for i = 2, MAX_BOSS_FRAMES do
				if PlayerFrames.boss[i] ~= nil then
					PlayerFrames:BossMoveScripts(PlayerFrames.boss[i])
				end
			end
		end
		-- if DBMod.PlayerFrames.ArenaFrame.display then
		PlayerFrames:AddMover(PlayerFrames.arena[1], 'arena')
		for i = 2, 6 do
			if PlayerFrames.arena[i] ~= nil then
				PlayerFrames:ArenaMoveScripts(PlayerFrames.arena[i])
			end
		end
	-- end
	end

	PlayerFrames:SetupStaticOptions()
	PlayerFrames:UpdatePosition()
end

function RaidFrames:OnEnable()
	if SUI.DBMod.RaidFrames.HideBlizzFrames and CompactRaidFrameContainer ~= nil then
		CompactRaidFrameContainer:UnregisterAllEvents()
		CompactRaidFrameContainer:Hide()

		local function hideRaid()
			CompactRaidFrameContainer:UnregisterAllEvents()
			if (InCombatLockdown()) then
				return
			end
			local shown = CompactRaidFrameManager_GetSetting('IsShown')
			if (shown and shown ~= '0') then
				CompactRaidFrameManager_SetSetting('IsShown', '0')
			end
		end

		hooksecurefunc(
			'CompactRaidFrameManager_UpdateShown',
			function()
				hideRaid()
			end
		)

		hideRaid()
		CompactRaidFrameContainer:HookScript('OnShow', hideRaid)
	end

	if (SUI.DBMod.RaidFrames.Style == 'theme') and (SUI.DBMod.Artwork.Style ~= 'Classic') then
		SUI.RaidFrames = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):RaidFrames()
	elseif (SUI.DBMod.RaidFrames.Style == 'Classic') or (SUI.DBMod.Artwork.Style == 'Classic') then
		SUI.RaidFrames = RaidFrames:Classic()
	elseif (SUI.DBMod.RaidFrames.Style == 'plain') then
		SUI.RaidFrames = RaidFrames:Plain()
	else
		SUI.RaidFrames = SUI:GetModule('Style_' .. SUI.DBMod.RaidFrames.Style):RaidFrames()
	end

	SUI.RaidFrames.mover = CreateFrame('Frame')
	SUI.RaidFrames.mover:SetSize(20, 20)
	SUI.RaidFrames.mover:SetPoint('TOPLEFT', SUI.RaidFrames, 'TOPLEFT')
	SUI.RaidFrames.mover:SetPoint('BOTTOMRIGHT', SUI.RaidFrames, 'BOTTOMRIGHT')
	SUI.RaidFrames.mover:EnableMouse(true)
	SUI.RaidFrames.mover:SetFrameStrata('LOW')

	SUI.RaidFrames:EnableMouse(enable)
	SUI.RaidFrames:SetScript(
		'OnMouseDown',
		function(self, button)
			if button == 'LeftButton' and IsAltKeyDown() then
				SUI.RaidFrames.mover:Show()
				SUI.DBMod.RaidFrames.moved = true
				SUI.RaidFrames:SetMovable(true)
				SUI.RaidFrames:StartMoving()
			end
		end
	)
	SUI.RaidFrames:SetScript(
		'OnMouseUp',
		function(self, button)
			SUI.RaidFrames.mover:Hide()
			SUI.RaidFrames:StopMovingOrSizing()
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = SUI.RaidFrames:GetPoint()
			for k, v in pairs(Anchors) do
				SUI.DBMod.RaidFrames.Anchors[k] = v
			end
		end
	)

	SUI.RaidFrames.mover.bg = SUI.RaidFrames.mover:CreateTexture(nil, 'BACKGROUND')
	SUI.RaidFrames.mover.bg:SetAllPoints(SUI.RaidFrames.mover)
	SUI.RaidFrames.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
	SUI.RaidFrames.mover.bg:SetVertexColor(1, 1, 1, 0.5)

	SUI.RaidFrames.mover:SetScript(
		'OnEvent',
		function()
			RaidFrames.locked = 1
			SUI.RaidFrames.mover:Hide()
		end
	)
	SUI.RaidFrames.mover:RegisterEvent('VARIABLES_LOADED')
	SUI.RaidFrames.mover:RegisterEvent('PLAYER_REGEN_DISABLED')
	SUI.RaidFrames.mover:Hide()

	local raidWatch = CreateFrame('Frame')
	raidWatch:RegisterEvent('GROUP_ROSTER_UPDATE')
	raidWatch:RegisterEvent('PLAYER_ENTERING_WORLD')

	raidWatch:SetScript(
		'OnEvent',
		function(self, event, ...)
			if (InCombatLockdown()) then
				self:RegisterEvent('PLAYER_REGEN_ENABLED')
			else
				self:UnregisterEvent('PLAYER_REGEN_ENABLED')
				RaidFrames:UpdateRaid(event)
			end
		end
	)
end

function PlayerFrames:BuffOptions()
	SUI.opt.args['PlayerFrames'].args['auras'] = {
		name = 'Buffs & Debuffs',
		type = 'group',
		order = 3,
		desc = 'Buff & Debuff display settings',
		args = {}
	}
	local Units = {[1] = 'player', [2] = 'pet', [3] = 'target', [4] = 'targettarget', [5] = 'focus', [6] = 'focustarget'}
	local values = {['bars'] = L['Bars'], ['icons'] = L['Icons'], ['both'] = L['Both'], ['disabled'] = L['Disabled']}

	for k, unit in pairs(Units) do
		SUI.opt.args['PlayerFrames'].args['auras'].args[unit] = {
			name = unit,
			type = 'group',
			order = k,
			disabled = true,
			args = {
				Notice = {type = 'description', order = .5, fontSize = 'medium', name = L['possiblereloadneeded']},
				Buffs = {
					name = 'Buffs',
					type = 'group',
					inline = true,
					order = 1,
					args = {
						Display = {
							name = L['Display mode'],
							type = 'select',
							order = 15,
							values = values,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Mode
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Mode = val
								SUI:reloadui()
							end
						},
						Number = {
							name = L['Number to show'],
							type = 'range',
							order = 20,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Number
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Number = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						},
						size = {
							name = L['Size'],
							type = 'range',
							order = 30,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.size
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.size = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						},
						spacing = {
							name = L['Spacing'],
							type = 'range',
							order = 40,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.spacing
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.spacing = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						},
						showType = {
							name = L['Show type'],
							type = 'toggle',
							order = 50,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.showType
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.showType = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						},
						onlyShowPlayer = {
							name = L['Only show players'],
							type = 'toggle',
							order = 60,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.onlyShowPlayer
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.onlyShowPlayer = val
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
									PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
								end
							end
						}
					}
				},
				Debuffs = {
					name = 'Debuffs',
					type = 'group',
					inline = true,
					order = 2,
					args = {
						Display = {
							name = L['Display mode'],
							type = 'select',
							order = 15,
							values = values,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Mode
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Mode = val
								SUI:reloadui()
							end
						},
						Number = {
							name = L['Number to show'],
							type = 'range',
							order = 20,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Number
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Number = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						},
						size = {
							name = L['Size'],
							type = 'range',
							order = 30,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.size
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.size = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						},
						spacing = {
							name = L['Spacing'],
							type = 'range',
							order = 40,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.spacing
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.spacing = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						},
						showType = {
							name = L['Show type'],
							type = 'toggle',
							order = 50,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.showType
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.showType = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						},
						onlyShowPlayer = {
							name = L['Only show players'],
							type = 'toggle',
							order = 60,
							get = function(info)
								return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.onlyShowPlayer
							end,
							set = function(info, val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.onlyShowPlayer = val
								if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
									PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
								end
							end
						}
					}
				}
			}
		}
	end
end

function RaidFrames:UpdateRaidPosition()
	RaidFrames.offset = SUI.DB.yoffset
	if SUI.DBMod.RaidFrames.moved then
		SUI.RaidFrames:SetMovable(true)
		SUI.RaidFrames:SetUserPlaced(false)
	else
		SUI.RaidFrames:SetMovable(false)
	end
	if not SUI.DBMod.RaidFrames.moved then
		SUI.RaidFrames:ClearAllPoints()
		if SUI:GetModule('PartyFrames', true) then
			SUI.RaidFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -140 - (RaidFrames.offset))
		else
			SUI.RaidFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -20 - (RaidFrames.offset))
		end
	else
		local Anchors = {}
		for k, v in pairs(SUI.DBMod.RaidFrames.Anchors) do
			Anchors[k] = v
		end
		SUI.RaidFrames:ClearAllPoints()
		SUI.RaidFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
end

function RaidFrames:UpdateRaid(event, ...)
	if SUI.RaidFrames == nil then
		return
	end

	if SUI.DBMod.RaidFrames.showRaid and IsInRaid() then
		SUI.RaidFrames:Show()
	elseif SUI.DBMod.RaidFrames.showParty and inParty then
		--Something keeps hiding it on us when solo so lets force it. Messy but oh well.
		SUI.RaidFrames.HideTmp = SUI.RaidFrames.Hide
		SUI.RaidFrames.Hide = SUI.RaidFrames.Show
		--Now Display
		SUI.RaidFrames:Show()
	elseif SUI.DBMod.RaidFrames.showSolo and not inParty and not IsInRaid() then
		--Something keeps hiding it on us when solo so lets force it. Messy but oh well.
		SUI.RaidFrames.HideTmp = SUI.RaidFrames.Hide
		SUI.RaidFrames.Hide = SUI.RaidFrames.Show
		--Now Display
		SUI.RaidFrames:Show()
	elseif SUI.RaidFrames:IsShown() then
		--Swap back hide function if needed
		if SUI.RaidFrames.HideTmp then
			SUI.RaidFrames.Hide = SUI.RaidFrames.HideTmp
		end

	-- SUI.RaidFrames:Hide()
	end

	RaidFrames:UpdateRaidPosition()

	SUI.RaidFrames:SetAttribute('showRaid', SUI.DBMod.RaidFrames.showRaid)
	SUI.RaidFrames:SetAttribute('showParty', SUI.DBMod.RaidFrames.showParty)
	SUI.RaidFrames:SetAttribute('showPlayer', SUI.DBMod.RaidFrames.showPlayer)
	SUI.RaidFrames:SetAttribute('showSolo', SUI.DBMod.RaidFrames.showSolo)

	SUI.RaidFrames:SetAttribute('groupBy', SUI.DBMod.RaidFrames.mode)
	SUI.RaidFrames:SetAttribute('maxColumns', SUI.DBMod.RaidFrames.maxColumns)
	SUI.RaidFrames:SetAttribute('unitsPerColumn', SUI.DBMod.RaidFrames.unitsPerColumn)
	SUI.RaidFrames:SetAttribute('columnSpacing', SUI.DBMod.RaidFrames.columnSpacing)

	SUI.RaidFrames:SetScale(SUI.DBMod.RaidFrames.scale)
end

function PartyFrames:UpdatePartyPosition()
	PartyFrames.offset = SUI.DB.yoffset
	if SUI.DBMod.PartyFrames.moved then
		SUI.PartyFrames:SetMovable(true)
		SUI.PartyFrames:SetUserPlaced(false)
	else
		SUI.PartyFrames:SetMovable(false)
	end
	-- User Moved the PartyFrame, so we shouldn't be moving it
	if not SUI.DBMod.PartyFrames.moved then
		SUI.PartyFrames:ClearAllPoints()
		-- SpartanUI_PlayerFrames are loaded
		if SUI:GetModule('PlayerFrames', true) then
			-- SpartanUI_PlayerFrames isn't loaded
			SUI.PartyFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -20 - (SUI.DB.BuffSettings.offset))
		else
			SUI.PartyFrames:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -140 - (SUI.DB.BuffSettings.offset))
		end
	else
		local Anchors = {}
		for k, v in pairs(SUI.DBMod.PartyFrames.Anchors) do
			Anchors[k] = v
		end
		SUI.PartyFrames:ClearAllPoints()
		SUI.PartyFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
end

function PartyFrames:OnEnable()
	local pf
	if (SUI.DBMod.PartyFrames.Style == 'theme') and (SUI.DBMod.Artwork.Style ~= 'Classic') then
		pf = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):PartyFrames()
	elseif (SUI.DBMod.PartyFrames.Style == 'Classic') then
		pf = PartyFrames:Classic()
	elseif (SUI.DBMod.PartyFrames.Style == 'plain') then
		pf = PartyFrames:Plain()
	else
		pf = SUI:GetModule('Style_' .. SUI.DBMod.PartyFrames.Style):PartyFrames()
	end

	if SUI.DB.Styles[SUI.DBMod.PartyFrames.Style].Movable.PartyFrames then
		pf.mover = CreateFrame('Frame')
		pf.mover:SetPoint('TOPLEFT', pf, 'TOPLEFT')
		pf.mover:SetPoint('BOTTOMRIGHT', pf, 'BOTTOMRIGHT')
		pf.mover:EnableMouse(true)
		pf.mover:SetFrameStrata('LOW')

		pf.mover.bg = pf.mover:CreateTexture(nil, 'BACKGROUND')
		pf.mover.bg:SetAllPoints(pf.mover)
		pf.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		pf.mover.bg:SetVertexColor(1, 1, 1, 0.5)

		pf.mover:SetScript(
			'OnEvent',
			function(self, event, ...)
				PartyFrames.locked = 1
				self:Hide()
			end
		)
		pf.mover:RegisterEvent('VARIABLES_LOADED')
		pf.mover:RegisterEvent('PLAYER_REGEN_DISABLED')
		pf.mover:Hide()
	end

	if SpartanUI then
		pf:SetParent('SpartanUI')
	else
		pf:SetParent(UIParent)
	end
	
	PartyMemberBackground.Show = function()
		return
	end
	PartyMemberBackground:Hide()

	SUI.PartyFrames = pf

	function PartyFrames:UpdateParty(event, ...)
		if InCombatLockdown() then
			return
		end
		local inParty = IsInGroup() -- ( numGroupMembers () > 0 )

		SUI.PartyFrames:SetAttribute('showParty', SUI.DBMod.PartyFrames.showParty)
		SUI.PartyFrames:SetAttribute('showPlayer', SUI.DBMod.PartyFrames.showPlayer)
		SUI.PartyFrames:SetAttribute('showSolo', SUI.DBMod.PartyFrames.showSolo)

		if SUI.DBMod.PartyFrames.showParty or SUI.DBMod.PartyFrames.showSolo then
			if IsInRaid() then
				if SUI.DBMod.PartyFrames.showPartyInRaid then
					SUI.PartyFrames:Show()
				else
					SUI.PartyFrames:Hide()
				end
			elseif inParty then
				SUI.PartyFrames:Show()
			elseif SUI.DBMod.PartyFrames.showSolo then
				SUI.PartyFrames:Show()
			elseif SUI.PartyFrames:IsShown() then
				SUI.PartyFrames:Hide()
			end
		else
			SUI.PartyFrames:Hide()
		end

		PartyFrames:UpdatePartyPosition()
		SUI.PartyFrames:SetScale(SUI.DBMod.PartyFrames.scale)
	end

	local partyWatch = CreateFrame('Frame')
	partyWatch:RegisterEvent('PLAYER_LOGIN')
	partyWatch:RegisterEvent('PLAYER_ENTERING_WORLD')
	partyWatch:RegisterEvent('RAID_ROSTER_UPDATE')
	partyWatch:RegisterEvent('PARTY_LEADER_CHANGED')
	--partyWatch:RegisterEvent('PARTY_MEMBERS_CHANGED');
	--partyWatch:RegisterEvent('PARTY_CONVERTED_TO_RAID');
	partyWatch:RegisterEvent('CVAR_UPDATE')
	partyWatch:RegisterEvent('PLAYER_REGEN_ENABLED')
	partyWatch:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	--partyWatch:RegisterEvent('FORCE_UPDATE');

	partyWatch:SetScript(
		'OnEvent',
		function(self, event, ...)
			if InCombatLockdown() then
				return
			end
			PartyFrames:UpdateParty(event)
		end
	)
end
